## Editor commands module - 9 tools.
## Handles errors, screenshots, editor script execution, and output.
@tool
class_name MCPEditorCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


## Router compatibility: returns callable map for MCPCommandRouter.
func get_commands() -> Dictionary:
	return {
		"editor/get_errors": func(params: Dictionary) -> Dictionary: return execute("get_editor_errors", params),
		"editor/get_screenshot": func(params: Dictionary) -> Dictionary: return execute("get_editor_screenshot", params),
		"editor/get_game_screenshot": _get_game_screenshot,
		"editor/execute_script": func(params: Dictionary) -> Dictionary: return execute("execute_editor_script", params),
		"editor/clear_output": func(params: Dictionary) -> Dictionary: return execute("clear_output", params),
		"editor/get_signals": func(params: Dictionary) -> Dictionary: return execute("get_signals", params),
		"editor/reload_plugin": func(params: Dictionary) -> Dictionary: return execute("reload_plugin", params),
		"editor/reload_project": func(params: Dictionary) -> Dictionary: return execute("reload_project", params),
		"editor/get_output_log": func(params: Dictionary) -> Dictionary: return execute("get_output_log", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_editor_errors": return _get_editor_errors(params)
		"get_editor_screenshot": return _get_editor_screenshot(params)
		"execute_editor_script": return _execute_editor_script(params)
		"clear_output": return _clear_output()
		"get_signals": return _get_signals(params)
		"reload_plugin": return _reload_plugin()
		"reload_project": return _reload_project()
		"get_output_log": return _get_output_log()
	return {"success": false, "error": "Unknown method: " + method}


## Get editor errors by validating scripts on all nodes in the current scene.
func _get_editor_errors(params: Dictionary) -> Dictionary:
	var errors: Array = []
	var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
	if root:
		_validate_scene_recursive(root, errors)
	return {"success": true, "errors": errors, "count": errors.size()}


func _validate_scene_recursive(node: Node, errors: Array) -> void:
	var scr: Script = node.get_script()
	if scr:
		if scr is GDScript:
			var gd: GDScript = scr as GDScript
			var err: Error = gd.reload(true)
			if err != OK:
				errors.append({
					"node": MCPCommandHelpers.get_node_path(node, _plugin),
					"script": scr.resource_path,
					"error": "Compilation error (code: %d)" % err,
				})
	for child: Node in node.get_children():
		_validate_scene_recursive(child, errors)


## Capture a screenshot of the editor viewport.
func _get_editor_screenshot(params: Dictionary) -> Dictionary:
	var save_path: String = params.get("path", "user://mcp_editor_screenshot.png")
	# Capture editor viewport using get_tree
	var viewport: Viewport = _plugin.get_tree().get_root()
	if viewport == null:
		return {"success": false, "error": "Failed to get editor viewport"}
	var img: Image = viewport.get_texture().get_image()
	if img == null:
		return {"success": false, "error": "Failed to capture editor viewport"}
	# Ensure parent directory exists before saving
	var dir: String = save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var err: Error = img.save_png(save_path)
	if err != OK:
		return {"success": false, "error": "Failed to save screenshot: %s" % error_string(err)}
	return {"success": true, "path": save_path, "width": img.get_width(), "height": img.get_height()}


## Capture a screenshot of the running game viewport.
## Game runs in a separate process — delegates to mcp_runtime.gd via file IPC.
## Uses async polling (await process_frame) instead of blocking OS.delay_msec.
func _get_game_screenshot(params: Dictionary) -> Dictionary:
	var save_path: String = params.get("path", "user://mcp_game_screenshot.png")
	if not _plugin.get_editor_interface().is_playing_scene():
		return {"success": false, "error": "Game is not running"}

	# Compute globalized user:// paths to ensure editor and game process agree
	# on the same absolute directory for IPC files.
	var user_base: String = ProjectSettings.globalize_path("user://")
	if not user_base.ends_with("/"):
		user_base += "/"
	const REQUEST_FILENAME: String = "mcp_runtime_request.json"
	const RESPONSE_FILENAME: String = "mcp_runtime_response.json"
	const READY_FILENAME: String = "mcp_runtime_ready"
	var REQUEST_PATH: String = user_base + REQUEST_FILENAME
	var RESPONSE_PATH: String = user_base + RESPONSE_FILENAME
	var READY_PATH: String = user_base + READY_FILENAME
	const IPC_TIMEOUT: float = 3.0

	# Wait for the runtime autoload to signal readiness.
	# Without this, requests sent immediately after play_scene() would
	# race against the game process initialization.
	#
	# DIAGNOSTIC: Log whether the main scene is configured — if
	# application/run/main_scene is empty, the Godot engine skips the
	# entire autoload instantiation block (main/main.cpp line 4494).
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene.is_empty():
		push_warning("[MCP Editor] WARNING: application/run/main_scene is empty — autoloads may not load! Set a main scene in Project Settings > Application > Run > Main Scene.")
	var ready_timeout: float = IPC_TIMEOUT
	var ready_start: float = Time.get_unix_time_from_system()
	print("[MCP Editor] Waiting for runtime ready at: %s (main_scene: '%s')" % [READY_PATH, main_scene])
	while Time.get_unix_time_from_system() - ready_start < ready_timeout:
		if FileAccess.file_exists(READY_PATH):
			print("[MCP Editor] Runtime ready file found after %.1fs" % (Time.get_unix_time_from_system() - ready_start))
			break
		if not _plugin.get_editor_interface().is_playing_scene():
			return {"success": false, "error": "Game stopped while waiting for runtime to initialize"}
		await _plugin.get_tree().process_frame
	if not FileAccess.file_exists(READY_PATH):
		var hint: String = " — check game output log for 'Failed to instantiate an autoload' or 'MCP Runtime _ready() ENTERED' messages"
		if main_scene.is_empty():
			hint += ". Main scene is not set — autoloads will NOT load!"
		return {"success": false, "error": "Runtime autoload not ready after %.1fs — game may still be initializing%s" % [ready_timeout, hint]}

	# Clean stale response files from previous requests
	if FileAccess.file_exists(RESPONSE_PATH):
		DirAccess.remove_absolute(RESPONSE_PATH)
	if FileAccess.file_exists(RESPONSE_PATH + ".tmp"):
		DirAccess.remove_absolute(RESPONSE_PATH + ".tmp")

	# Build request with correlation id
	var request_id: String = "mcp_screenshot_%d" % Time.get_unix_time_from_system()
	var request: Dictionary = {"method": "capture_screenshot", "params": {"path": save_path}, "request_id": request_id}
	var json_text: String = JSON.stringify(request)

	# Atomic write: .tmp first, then rename — prevents partial reads by runtime
	var tmp_path: String = REQUEST_PATH + ".tmp"
	var req_file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if req_file == null:
		return {"success": false, "error": "Failed to write runtime request to '%s'" % tmp_path}
	req_file.store_string(json_text)
	req_file.close()
	var rename_err: Error = DirAccess.rename_absolute(tmp_path, REQUEST_PATH)
	if rename_err != OK:
		return {"success": false, "error": "Failed to rename IPC request file: %s (code %d)" % [error_string(rename_err), rename_err]}

	# Poll for response with async yields (no blocking delay)
	print("[MCP Editor] Screenshot request written — req: %s, resp: %s" % [REQUEST_PATH, RESPONSE_PATH])
	var start: float = Time.get_unix_time_from_system()
	var last_log_elapsed: float = 0.0
	while Time.get_unix_time_from_system() - start < IPC_TIMEOUT:
		var elapsed: float = Time.get_unix_time_from_system() - start
		if elapsed - last_log_elapsed >= 5.0:
			last_log_elapsed = elapsed
			print("[MCP Editor] Waiting for screenshot response... (%.1fs, path: %s, exists: %s)" % [elapsed, RESPONSE_PATH, FileAccess.file_exists(RESPONSE_PATH)])
		if not _plugin.get_editor_interface().is_playing_scene():
			return {"success": false, "error": "Game stopped while waiting for screenshot"}
		if FileAccess.file_exists(RESPONSE_PATH):
			var resp_file := FileAccess.open(RESPONSE_PATH, FileAccess.READ)
			if resp_file:
				var resp_text: String = resp_file.get_as_text()
				resp_file.close()
				DirAccess.remove_absolute(RESPONSE_PATH)
				var json := JSON.new()
				var err := json.parse(resp_text)
				if err == OK and json.data is Dictionary:
					var resp: Dictionary = json.data as Dictionary
					var resp_id: String = resp.get("request_id", "")
					if not resp_id.is_empty() and resp_id != request_id:
						push_warning("[MCP Editor] Ignoring stale screenshot response (expected %s, got %s)" % [request_id, resp_id])
						continue
					if resp.has("result"):
						return resp["result"]
					return {"success": false, "error": str(resp.get("error", "Runtime error"))}
		await _plugin.get_tree().process_frame
	return {"success": false, "error": "Runtime screenshot timed out after %.1fs" % IPC_TIMEOUT}


## Execute arbitrary GDScript code in the editor context via EditorScript.
func _execute_editor_script(params: Dictionary) -> Dictionary:
	var code: String = params.get("code", "")
	if code.is_empty():
		return {"success": false, "error": "Code cannot be empty"}

	# Reject user-defined functions — they interact badly with the return-capture
	# wrapper that rewrites top-level `return` statements inside _run().
	for line: String in code.split("\n"):
		var trimmed: String = line.strip_edges()
		if trimmed.begins_with("func ") or trimmed.begins_with("static func "):
			return {"success": false, "error": "User-defined functions are not supported. Use inline code only."}

	# Normalize tabs to spaces to prevent "Mixed use of tabs and spaces"
	# compilation errors when user code uses tabs while the wrapper uses spaces.
	code = code.replace("\t", "    ")

	var script: GDScript = GDScript.new()
	var lines: PackedStringArray = code.split("\n")

	# Track whether user code contains a `return` statement so we can
	# distinguish "user returned null" from "no return statement".
	var has_return: bool = false

	# Wrap user code in a helper function for runtime-error isolation.
	# If user code crashes at runtime, _mcp_user_code() returns early
	# and _mcp_executed stays false, allowing us to detect runtime errors.
	#
	# CRITICAL: GDScript runtime errors (null access, array OOB, etc.) do NOT
	# propagate to the caller — the VM catches them internally, prints the error,
	# and returns a default value.  The caller (here: _run()) sees CALL_OK and
	# continues execution.  Therefore, _mcp_executed = true MUST be placed at the
	# END of _mcp_user_code() — NOT in _run() after the call.  If placed in
	# _run(), the flag is always set regardless of whether user code crashed.
	var wrapped_code: String = (
		"extends EditorScript\n\n"
		+ "var _mcp_return_value = null\n"
		+ "var _mcp_executed = false\n\n"
		+ "func _run() -> void:\n"
		+ "    _mcp_user_code()\n\n"
		+ "func _mcp_user_code() -> void:\n"
	)
	for line: String in lines:
		var trimmed: String = line.strip_edges()
		if trimmed == "return":
			# Bare return — valid in void function.
			# Do NOT set has_return = true: a bare return does not
			# produce a value, so the response should use "message",
			# not "result: null".
			# Set _mcp_executed BEFORE return so the sentinel is
			# reached — otherwise the early return skips the
			# completion marker at the end of the wrapper.
			wrapped_code += "    _mcp_executed = true\n"
			wrapped_code += "    return\n"
		elif trimmed.begins_with("return ") and trimmed.length() > 7:
			# Capture return value via class member, then return
			has_return = true
			wrapped_code += "    _mcp_return_value = " + trimmed.substr(7) + "\n"
			# Set _mcp_executed BEFORE return so the sentinel is
			# reached — otherwise the early return skips the
			# completion marker at the end of the wrapper.
			wrapped_code += "    _mcp_executed = true\n"
			wrapped_code += "    return\n"
		else:
			wrapped_code += "    " + line + "\n"
	# Signal completion: only reached if no runtime error occurred.
	# GDScript runtime errors cause this function to return early
	# (the VM handles the error internally), skipping this assignment.
	wrapped_code += "    _mcp_executed = true\n"
	script.source_code = wrapped_code

	var err: Error = script.reload(true)
	if err != OK:
		return {"success": false, "error": "Script compilation failed: %s" % error_string(err)}

	var editor_script: EditorScript = script.new() as EditorScript
	if editor_script == null:
		return {"success": false, "error": "Failed to create EditorScript instance"}
	editor_script._run()

	# Detect runtime errors: if _mcp_user_code() never completed,
	# _mcp_executed stays at its default (false).  This happens when
	# user code hits a runtime error (null access, invalid operation, etc.)
	# and GDScript halts execution inside the helper function.
	var executed: bool = editor_script.get("_mcp_executed") if editor_script.get("_mcp_executed") != null else false
	if not executed:
		return {"success": false, "error": "Script encountered a runtime error during execution. Check the editor output log for details."}

	var return_value: Variant = editor_script.get("_mcp_return_value")
	if has_return:
		return {"success": true, "result": return_value}
	return {"success": true, "message": "Editor script executed successfully"}


## Clear the editor output log.
##
## EditorLog::clear() is a C++ public method but is NOT exposed to GDScript
## (EditorLog is not registered with ClassDB), so has_method("clear") always
## returns false.  We cannot call it directly.
##
## The clear Button inside EditorLog triggers EditorLog::_clear_request() via
## its "pressed" signal.  However, the Button is buried inside a HBoxContainer
## toolbar, not a direct child of EditorLog.
##
## Instead, we find the RichTextLabel (which IS a built-in Godot class exposed
## to GDScript) inside EditorLog and call RichTextLabel.clear() on it directly.
## This clears the visible log display.  The internal messages buffer is NOT
## cleared, but since _get_output_log() reads from the RichTextLabel, the
## clearing is effective for our purposes.
##
## NOTE: The log FILE (user://logs/godot.log) is managed by RotatedFileLogger
## (a completely separate system from EditorLog).  EditorLog does NOT read
## from or write to it.  Attempting to delete/truncate the log file is both
## unnecessary and unreliable (the engine holds it locked for appending).
func _clear_output() -> Dictionary:
	var editor_log: Node = _find_editor_log()
	if editor_log:
		var rich_text: RichTextLabel = MCPCommandHelpers.find_node_by_class(editor_log, "RichTextLabel") as RichTextLabel
		if rich_text:
			rich_text.clear()
			return {"success": true, "message": "Output cleared"}
		# RichTextLabel not found — try the Button approach as fallback
		var button: Button = MCPCommandHelpers.find_node_by_class(editor_log, "Button") as Button
		if button:
			button.emit_signal("pressed")
			return {"success": true, "message": "Output cleared"}
	# EditorLog not found — use the Script-tab refresh fallback
	_plugin.get_editor_interface().set_main_screen_editor("Script")
	return {"success": true, "message": "Output clear requested (fallback method)"}


## Get all signals on a node with their current connections.
func _get_signals(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	if node_path.is_empty():
		return {"success": false, "error": "node_path is required"}
	var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"success": false, "error": "Node not found: %s" % node_path}

	var signals_data: Array = []
	var signal_list: Array = node.get_signal_list()
	for sig_info: Dictionary in signal_list:
		var sig_name: String = sig_info["name"] as String
		var connections: Array = node.get_signal_connection_list(sig_name)
		var conn_data: Array = []
		for conn: Dictionary in connections:
			# Filter: only show persistent connections (CONNECT_PERSIST = 2).
			# Editor-internal connections (flags=0 or editor-only flags) are
			# skipped to avoid noise from SceneTreeEditor bookkeeping connections.
			var flags: int = conn.get("flags", 0) as int
			if not (flags & 2):  # CONNECT_PERSIST
				continue
			var callable: Callable = conn["callable"] as Callable
			var target_obj: Object = callable.get_object()
			var target_desc: String = "(freed object)"
			if target_obj != null:
				target_desc = str(target_obj.get_path()) if target_obj is Node else str(target_obj)
			conn_data.append({
				"target": target_desc,
				"method": str(callable.get_method()),
			})
		signals_data.append({
			"name": sig_name,
			"args": sig_info.get("args", []),
			"connections": conn_data,
		})
	return {"success": true, "node": node_path, "signals": signals_data}


## Reload the MCP plugin by toggling it off and on.
func _reload_plugin() -> Dictionary:
	# Schedule reload for next frame so the response dict can be sent first.
	# Without call_deferred, set_plugin_enabled(false) tears down the plugin
	# (and its WebSocket) before the response reaches the client.
	var ei: EditorInterface = _plugin.get_editor_interface()
	ei.call_deferred("set_plugin_enabled", "godot_mcp", false)
	ei.call_deferred("set_plugin_enabled", "godot_mcp", true)
	return {"success": true, "message": "Plugin reloaded - connection will be re-established"}


## Rescan the project filesystem for changes.
func _reload_project() -> Dictionary:
	_plugin.safe_scan_filesystem()
	return {"success": true, "message": "Project filesystem rescanned"}


## Get the output log content from the editor's log panel.
func _get_output_log() -> Dictionary:
	# Primary: read from EditorLog RichTextLabel — always active, no config needed.
	# When the RichTextLabel is found, use it exclusively: this ensures that
	# after clear_output() clears the UI widget, get_output_log() does NOT
	# fall through to the log file (which may still hold stale content).
	var editor_log: Node = _find_editor_log()
	if editor_log:
		var rich_text: RichTextLabel = MCPCommandHelpers.find_node_by_class(editor_log, "RichTextLabel") as RichTextLabel
		if rich_text:
			var content: String = rich_text.get_parsed_text()
			# Return whatever the RichTextLabel has — even empty (cleared state).
			# The RichTextLabel is the canonical source when available; if it's
			# empty, the log IS empty (either never populated or was cleared).
			if not content.is_empty():
				if content.length() > 5000:
					content = content.substr(content.length() - 5000)
				return {"success": true, "content": content}
			return {"success": true, "content": "(Log is empty)"}
	
	# Fallback: read from log file (only when EditorLog is not available,
	# e.g. in unusual editor states or headless operation without UI).
	var log_dir: String = ProjectSettings.globalize_path("user://logs")
	var log_path: String = log_dir + "/godot.log"
	if FileAccess.file_exists(log_path):
		var file: FileAccess = FileAccess.open(log_path, FileAccess.READ)
		if file:
			var content: String = file.get_as_text()
			file.close()
			if not content.is_empty():
				if content.length() > 5000:
					content = content.substr(content.length() - 5000)
				return {"success": true, "content": content}
	
	return {"success": true, "content": "(No output log available)"}


## Helper: find the EditorLog node by traversing the editor UI tree.
## The editor tree has ~22,000 descendants — deep recursion would overflow
## GDScript's stack.  Uses Godot's built-in find_children() with class filter,
## which is internally optimized and avoids all recursion/timeout issues.
func _find_editor_log() -> Node:
	var base: Node = _plugin.get_editor_interface().get_base_control()
	if base == null:
		return null
	var found: Array[Node] = base.find_children("*", "EditorLog", true, false)
	if not found.is_empty():
		return found[0]
	return null



