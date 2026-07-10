## Editor commands module - 9 tools.
## Handles errors, screenshots, editor script execution, and output.
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
	const IPC_TIMEOUT: float = 30.0

	# Wait for the runtime autoload to signal readiness.
	# Without this, requests sent immediately after play_scene() would
	# race against the game process initialization.
	var ready_timeout: float = IPC_TIMEOUT
	var ready_start: float = Time.get_unix_time_from_system()
	print("[MCP Editor] Waiting for runtime ready at: %s" % READY_PATH)
	while Time.get_unix_time_from_system() - ready_start < ready_timeout:
		if FileAccess.file_exists(READY_PATH):
			break
		if not _plugin.get_editor_interface().is_playing_scene():
			return {"success": false, "error": "Game stopped while waiting for runtime to initialize"}
		await _plugin.get_tree().process_frame
	if not FileAccess.file_exists(READY_PATH):
		return {"success": false, "error": "Runtime autoload not ready after %.1fs — game may still be initializing" % ready_timeout}

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

	var script: GDScript = GDScript.new()
	# Use a class member to capture return values from user code
	var lines: PackedStringArray = code.split("\n")
	var wrapped_code: String = "extends EditorScript\n\nvar _mcp_return_value = null\n\nfunc _run() -> void:\n"
	for line: String in lines:
		var trimmed: String = line.strip_edges()
		if trimmed == "return":
			# Bare return — valid in void function
			wrapped_code += "    return\n"
		elif trimmed.begins_with("return ") and trimmed.length() > 7:
			# Capture return value via class member, then return
			wrapped_code += "    _mcp_return_value = " + trimmed.substr(7) + "\n"
			wrapped_code += "    return\n"
		else:
			wrapped_code += "    " + line + "\n"
	script.source_code = wrapped_code

	var err: Error = script.reload(true)
	if err != OK:
		return {"success": false, "error": "Script compilation failed: %s" % error_string(err)}

	var editor_script: EditorScript = script.new() as EditorScript
	if editor_script == null:
		return {"success": false, "error": "Failed to create EditorScript instance"}
	editor_script._run()

	# Read captured return value if any code returned a value
	var return_value: Variant = editor_script.get("_mcp_return_value")
	if return_value != null:
		return {"success": true, "result": return_value}
	return {"success": true, "message": "Editor script executed successfully"}


## Clear the output panel.
func _clear_output() -> Dictionary:
	var editor_log: Node = _find_editor_log()
	if editor_log and editor_log.has_method("clear"):
		editor_log.clear()
		return {"success": true, "message": "Output cleared"}
	# Fallback: switch to script tab to trigger UI refresh
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
	# Primary: read from EditorLog RichTextLabel — always active, no config needed
	var editor_log: Node = _find_editor_log()
	if editor_log:
		var rich_text: RichTextLabel = MCPCommandHelpers.find_node_by_class(editor_log, "RichTextLabel") as RichTextLabel
		if rich_text:
			var content: String = rich_text.get_parsed_text()
			if not content.is_empty():
				return {"success": true, "content": content}
	
	# Fallback: read from log file (may be empty if enable_file_logging is off)
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
func _find_editor_log() -> Node:
	var base: Node = _plugin.get_editor_interface().get_base_control()
	return MCPCommandHelpers.find_node_by_class(base, "EditorLog")



