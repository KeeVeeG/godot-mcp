## Debug configuration commands module - 6 tools.
## Handles debug settings, remote debugging, profilers, and editor log.
class_name MCPDebugConfigCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


## Router compatibility: returns callable map for MCPCommandRouter.
func get_commands() -> Dictionary:
	return {
		"debug_config/get_settings": func(params: Dictionary) -> Dictionary: return execute("get_settings", params),
		"debug_config/set_remote_debug": func(params: Dictionary) -> Dictionary: return execute("set_remote_debug", params),
		"debug_config/set_profilers": func(params: Dictionary) -> Dictionary: return execute("set_profilers", params),
		"debug_config/set_error_handling": func(params: Dictionary) -> Dictionary: return execute("set_error_handling", params),
		"debug_config/get_log": func(params: Dictionary) -> Dictionary: return execute("get_log", params),
		"debug_config/clear_log": func(params: Dictionary) -> Dictionary: return execute("clear_log", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_settings": return _get_settings()
		"set_remote_debug": return _set_remote_debug(params)
		"set_profilers": return _set_profilers(params)
		"set_error_handling": return _set_error_handling(params)
		"get_log": return _get_log(params)
		"clear_log": return _clear_log()
	return {"success": false, "error": "Unknown method: " + method}


## Get all debug settings.
func _get_settings() -> Dictionary:
	var settings: Dictionary = {
		"remote_debug": {
			"enabled": EditorInterface.get_editor_settings().get_setting("network/debug/remote_host") != "127.0.0.1",
			"host": EditorInterface.get_editor_settings().get_setting("network/debug/remote_host"),
			"port": EditorInterface.get_editor_settings().get_setting("network/debug/remote_port"),
		},
		"profilers": {
			"max_functions": ProjectSettings.get_setting("debug/settings/profiler/max_functions", 16384),
			"max_timestamp_query_elements": ProjectSettings.get_setting("debug/settings/profiler/max_timestamp_query_elements", 256),
		},
		"error_handling": {
			"break_on_error": ProjectSettings.get_setting("debug/gdscript/warnings/enable", true),
			"break_on_warning": false,
		},
		"stdout": {
			"disable_stdout": ProjectSettings.get_setting("application/run/disable_stdout", false),
			"disable_stderr": ProjectSettings.get_setting("application/run/disable_stderr", false),
		},
		"logging": {
			"file_logging_enabled": ProjectSettings.get_setting("debug/file_logging/enable_file_logging", false),
			"log_path": ProjectSettings.get_setting("debug/file_logging/log_path", ""),
		},
	}
	return {"success": true, "settings": settings}


## Configure remote debugging.
func _set_remote_debug(params: Dictionary) -> Dictionary:
	var enabled: bool = params.get("enabled", true)
	var host: String = params.get("host", "127.0.0.1")
	var port: int = params.get("port", 6007)
	var editor_settings: EditorSettings = EditorInterface.get_editor_settings()
	if enabled:
		editor_settings.set_setting("network/debug/remote_host", host)
		editor_settings.set_setting("network/debug/remote_port", port)
	else:
		editor_settings.set_setting("network/debug/remote_host", "")
		# Don't set port when disabling — it's irrelevant when remote debug is off
	return {"success": true, "enabled": enabled, "host": host, "port": port}


## Enable/disable profilers.
## Profiler toggles (cpu/gpu/memory/network) are editor debugger UI controls
## and cannot be set via ProjectSettings. Only profiler limits are configurable.
func _set_profilers(params: Dictionary) -> Dictionary:
	var changed: Dictionary = {}
	var warnings: Array = []
	var has_savable: bool = false

	# Configurable profiler limits (actual ProjectSettings)
	if params.has("max_functions"):
		ProjectSettings.set_setting("debug/settings/profiler/max_functions", params["max_functions"] as int)
		changed["max_functions"] = params["max_functions"] as int
		has_savable = true
	if params.has("max_timestamp_query_elements"):
		ProjectSettings.set_setting("debug/settings/profiler/max_timestamp_query_elements", params["max_timestamp_query_elements"] as int)
		changed["max_timestamp_query_elements"] = params["max_timestamp_query_elements"] as int
		has_savable = true

	# UI-only toggles — report as warnings
	for toggle: String in ["cpu", "gpu", "memory", "network"]:
		if params.has(toggle):
			warnings.append("%s profiler toggle is controlled by the editor debugger panel, not ProjectSettings" % toggle)

	if changed.is_empty() and warnings.is_empty():
		return {"success": false, "error": "No profiler settings provided. Configurable: max_functions, max_timestamp_query_elements"}

	if has_savable:
		var err: Error = ProjectSettings.save()
		if err != OK:
			return {"success": false, "error": "Failed to save: %s" % error_string(err)}

	return {"success": true, "changed": changed, "warnings": warnings}


## Configure error handling behavior.
func _set_error_handling(params: Dictionary) -> Dictionary:
	var changed: Dictionary = {}
	if params.has("break_on_error"):
		var boe: bool = params["break_on_error"] as bool
		ProjectSettings.set_setting("debug/gdscript/warnings/enable", boe)
		changed["break_on_error"] = boe
	if params.has("break_on_warning"):
		var bow: bool = params["break_on_warning"] as bool
		changed["break_on_warning"] = bow
		changed["note"] = "Break on warning is controlled by the editor debugger"
	if changed.is_empty():
		return {"success": false, "error": "No error handling settings provided"}
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "changed": changed}


## Get editor log entries.
func _get_log(params: Dictionary) -> Dictionary:
	var filter: String = params.get("filter", "")
	var limit: int = params.get("limit", 50)
	# Try to read from the editor log file
	var log_path: String = ProjectSettings.get_setting("debug/file_logging/log_path", "user://logs/godot.log") as String
	var entries: Array = []
	if FileAccess.file_exists(log_path):
		var file: FileAccess = FileAccess.open(log_path, FileAccess.READ)
		if file:
			var lines: PackedStringArray = file.get_as_text().split("\n")
			file.close()
			# Process from end (most recent first)
			var count: int = 0
			for i: int in range(lines.size() - 1, -1, -1):
				if count >= limit:
					break
				var line: String = lines[i].strip_edges()
				if line.is_empty():
					continue
				var entry_type: String = "info"
				if line.find("ERROR") != -1 or line.find("error") != -1:
					entry_type = "error"
				elif line.find("WARNING") != -1 or line.find("warning") != -1:
					entry_type = "warning"
				if filter != "" and entry_type != filter:
					continue
				entries.append({"type": entry_type, "message": line})
				count += 1
			entries.reverse()
	return {"success": true, "entries": entries, "count": entries.size(), "log_path": log_path}


## Clear the editor output log.
func _clear_log() -> Dictionary:
	# Try to find and clear the editor log UI
	var base: Control = _plugin.get_editor_interface().get_base_control()
	var editor_log: Node = MCPCommandHelpers.find_node_by_class(base, "EditorLog")
	if editor_log and editor_log.has_method("clear"):
		editor_log.clear()
		return {"success": true, "message": "Editor log cleared"}
	# Fallback
	var log_path: String = ProjectSettings.get_setting("debug/file_logging/log_path", "") as String
	if log_path != "" and FileAccess.file_exists(log_path):
		var file: FileAccess = FileAccess.open(log_path, FileAccess.WRITE)
		if file:
			file.store_string("")
			file.close()
			return {"success": true, "message": "Log file cleared"}
	return {"success": true, "message": "Log clear requested"}



