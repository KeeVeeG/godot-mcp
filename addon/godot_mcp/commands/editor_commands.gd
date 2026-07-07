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
		"editor/get_game_screenshot": func(params: Dictionary) -> Dictionary: return execute("get_game_screenshot", params),
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
		"get_game_screenshot": return _get_game_screenshot(params)
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
			var err: Error = gd.reload()
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
func _get_game_screenshot(params: Dictionary) -> Dictionary:
	var save_path: String = params.get("path", "user://mcp_game_screenshot.png")
	if not _plugin.get_editor_interface().is_playing_scene():
		return {"success": false, "error": "Game is not running"}
	# Game runs in a separate process — delegate to mcp_runtime.gd via file IPC
	var request: Dictionary = {"method": "capture_screenshot", "params": {"path": save_path}}
	var req_file := FileAccess.open("user://mcp_runtime_request.json", FileAccess.WRITE)
	if req_file == null:
		return {"success": false, "error": "Failed to write runtime request"}
	req_file.store_string(JSON.stringify(request))
	req_file.close()
	# Wait for response
	var start: float = Time.get_unix_time_from_system()
	const TIMEOUT: float = 3.0
	while Time.get_unix_time_from_system() - start < TIMEOUT:
		if FileAccess.file_exists("user://mcp_runtime_response.json"):
			var resp_file := FileAccess.open("user://mcp_runtime_response.json", FileAccess.READ)
			if resp_file:
				var resp_text: String = resp_file.get_as_text()
				resp_file.close()
				DirAccess.remove_absolute("user://mcp_runtime_response.json")
				var json := JSON.new()
				var err := json.parse(resp_text)
				if err == OK and json.data is Dictionary:
					var resp: Dictionary = json.data as Dictionary
					if resp.has("result"):
						return resp["result"]
					return {"success": false, "error": str(resp.get("error", "Runtime error"))}
		OS.delay_msec(10)
	return {"success": false, "error": "Runtime screenshot timed out"}


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
	# Try file-based approach first — works in headless/test mode and is more reliable
	var log_dir: String = ProjectSettings.globalize_path("user://logs")
	var log_path: String = log_dir + "/godot.log"
	if FileAccess.file_exists(log_path):
		var file: FileAccess = FileAccess.open(log_path, FileAccess.READ)
		if file:
			var content: String = file.get_as_text()
			file.close()
			if not content.is_empty():
				# Return last 5000 chars to avoid huge payloads
				if content.length() > 5000:
					content = content.substr(content.length() - 5000)
				return {"success": true, "content": content}
	
	# Fallback: try reading from the EditorLog RichTextLabel in the UI
	var editor_log: Node = _find_editor_log()
	if editor_log:
		var rich_text: RichTextLabel = null
		for child: Node in editor_log.get_children():
			if child is RichTextLabel:
				rich_text = child as RichTextLabel
				break
		if rich_text and not rich_text.get_parsed_text().is_empty():
			return {"success": true, "content": rich_text.get_parsed_text()}
	
	return {"success": true, "content": "(No output log available)"}


## Helper: find the EditorLog node by traversing the editor UI tree.
func _find_editor_log() -> Node:
	var base: Node = _plugin.get_editor_interface().get_base_control()
	return MCPCommandHelpers.find_node_by_class(base, "EditorLog")



