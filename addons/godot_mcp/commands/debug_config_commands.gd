## Debug configuration commands module - 6 tools.
## Handles debug settings, remote debugging, profilers, and editor log.
@tool
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


## Safely cast a value to int, returning an error if the value is not a valid integer.
## Returns: [true, int_value] on success, [false, error_message] on failure.
func _safe_int(value, param_name: String) -> Array:
	if value == null:
		return [false, "%s: expected integer, got null" % param_name]
	if typeof(value) == TYPE_INT:
		return [true, value]
	if typeof(value) == TYPE_FLOAT:
		if is_nan(value) or is_inf(value):
			return [false, "%s: value must be a finite integer, got %s" % [param_name, "NaN" if is_nan(value) else "INF"]]
		# Accept whole-number floats (common when JSON numbers cross the bridge)
		if value == floor(value):
			return [true, int(value)]
		return [false, "%s: expected integer, got float (%s)" % [param_name, value]]
	if typeof(value) == TYPE_BOOL:
		return [true, 1 if value else 0]
	if typeof(value) == TYPE_STRING:
		if value.is_valid_int():
			return [true, value.to_int()]
		return [false, "%s: expected integer, got string '%s'" % [param_name, value]]
	return [false, "%s: expected integer, got %s" % [param_name, type_string(typeof(value))]]

## Safely cast a value to bool, returning an error if the value is not a valid boolean.
## Returns: [true, bool_value] on success, [false, error_message] on failure.
func _safe_bool(value, param_name: String) -> Array:
	if value == null:
		return [false, "%s: expected boolean, got null" % param_name]
	if typeof(value) == TYPE_BOOL:
		return [true, value]
	if typeof(value) == TYPE_INT:
		return [true, value != 0]
	if typeof(value) == TYPE_FLOAT:
		if is_nan(value) or is_inf(value):
			return [false, "%s: value must be a finite boolean, got %s" % [param_name, "NaN" if is_nan(value) else "INF"]]
		return [true, value != 0.0]
	if typeof(value) == TYPE_STRING:
		var lower: String = value.to_lower()
		if lower == "true" or lower == "1":
			return [true, true]
		if lower == "false" or lower == "0":
			return [true, false]
		return [false, "%s: expected boolean, got string '%s'" % [param_name, value]]
	return [false, "%s: expected boolean, got %s" % [param_name, type_string(typeof(value))]]

## Get all debug settings.
func _get_settings() -> Dictionary:
	var remote_host: String = EditorInterface.get_editor_settings().get_setting("network/debug/remote_host")
	# enabled is derived from actual persisted host — empty string means disabled (restored to default)
	var remote_enabled: bool = not remote_host.is_empty() and remote_host != "127.0.0.1"

	var settings: Dictionary = {
		"remote_debug": {
			"enabled": remote_enabled,
			"host": remote_host,
			"port": EditorInterface.get_editor_settings().get_setting("network/debug/remote_port"),
		},
		"profilers": {
			"max_functions": int(ProjectSettings.get_setting("debug/settings/profiler/max_functions", 16384)),
			"max_timestamp_query_elements": int(ProjectSettings.get_setting("debug/settings/profiler/max_timestamp_query_elements", 256)),
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
		var result := {"success": true, "enabled": true, "host": host, "port": port}
		# get_settings() derives "enabled" from host != "" and host != "127.0.0.1".
		# When host is localhost, remote machines cannot connect — warn the caller.
		if host == "127.0.0.1":
			result["note"] = "Remote debug is only reachable from localhost. Use a non-localhost address for true remote access."
		return result
	else:
		# Restore factory defaults when disabling
		var default_host: String = "127.0.0.1"
		var default_port: int = 6007
		editor_settings.set_setting("network/debug/remote_host", default_host)
		editor_settings.set_setting("network/debug/remote_port", default_port)
		# Return actual persisted values, not the input echo
		return {"success": true, "enabled": false, "host": default_host, "port": default_port}


## Enable/disable profilers.
## Profiler toggles (cpu/gpu/memory/network) are editor debugger UI controls
## and cannot be set via ProjectSettings. Only profiler limits are configurable.
func _set_profilers(params: Dictionary) -> Dictionary:
	var changed: Dictionary = {}
	var warnings: Array = []
	var has_savable: bool = false

	# Configurable profiler limits with safe type validation
	if params.has("max_functions"):
		var result: Array = _safe_int(params["max_functions"], "max_functions")
		if result[0]:
			ProjectSettings.set_setting("debug/settings/profiler/max_functions", result[1])
			changed["max_functions"] = result[1]
			has_savable = true
		else:
			return {"success": false, "error": str(result[1])}
	if params.has("max_timestamp_query_elements"):
		var result: Array = _safe_int(params["max_timestamp_query_elements"], "max_timestamp_query_elements")
		if result[0]:
			ProjectSettings.set_setting("debug/settings/profiler/max_timestamp_query_elements", result[1])
			changed["max_timestamp_query_elements"] = result[1]
			has_savable = true
		else:
			return {"success": false, "error": str(result[1])}

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
## Note: Godot 4.x has no runtime "break on warning" mechanism.
## Warnings are compile-time only (IGNORE/WARN/ERROR levels) and controlled
## via debug/gdscript/warnings/<name> ProjectSettings keys.
## break_on_warning is accepted and echoed back but cannot be persisted.
func _set_error_handling(params: Dictionary) -> Dictionary:
	var changed: Dictionary = {}
	var has_persistable: bool = false
	if params.has("break_on_error"):
		var result: Array = _safe_bool(params["break_on_error"], "break_on_error")
		if result[0]:
			var boe: bool = result[1]
			ProjectSettings.set_setting("debug/gdscript/warnings/enable", boe)
			changed["break_on_error"] = boe
			has_persistable = true
		else:
			return {"success": false, "error": str(result[1])}
	if params.has("break_on_warning"):
		var result: Array = _safe_bool(params["break_on_warning"], "break_on_warning")
		if result[0]:
			changed["note"] = "break_on_warning=%s requested but NOT persisted — controlled by editor debugger" % result[1]
		else:
			return {"success": false, "error": str(result[1])}
	if changed.is_empty():
		return {"success": false, "error": "No error handling settings provided"}
	if has_persistable:
		var err: Error = ProjectSettings.save()
		if err != OK:
			return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "changed": changed}


## Get editor log entries.
func _get_log(params: Dictionary) -> Dictionary:
	var filter: String = params.get("filter", "")
	var limit: int = params.get("limit", 50)
	var entries: Array = []
	var lines: PackedStringArray
	var log_path: String = ProjectSettings.get_setting("debug/file_logging/log_path", "user://logs/godot.log") as String
	
	# Primary: read from EditorLog RichTextLabel — always active
	var base: Control = _plugin.get_editor_interface().get_base_control()
	var editor_log: Node = MCPCommandHelpers.find_node_by_class(base, "EditorLog")
	if editor_log:
		var rich_text: RichTextLabel = MCPCommandHelpers.find_node_by_class(editor_log, "RichTextLabel") as RichTextLabel
		if rich_text:
			var content: String = rich_text.get_parsed_text()
			if not content.is_empty():
				lines = content.split("\n")
	
	# Fallback: read from log file (may be empty if enable_file_logging is off)
	if lines.is_empty():
		if FileAccess.file_exists(log_path):
			var file: FileAccess = FileAccess.open(log_path, FileAccess.READ)
			if file:
				lines = file.get_as_text().split("\n")
				file.close()
	
	if not lines.is_empty():
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
	# Clear the editor log UI (internal buffer + display)
	var base: Control = _plugin.get_editor_interface().get_base_control()
	var editor_log: Node = MCPCommandHelpers.find_node_by_class(base, "EditorLog")
	if editor_log:
		# Clear EditorLog internal buffer first, then the RichTextLabel display.
		# EditorLog.clear() clears the internal log store but may not flush the RichTextLabel,
		# so we call rich_text.clear() afterward to ensure the display is empty.
		if editor_log.has_method("clear"):
			editor_log.clear()
		var rich_text: RichTextLabel = MCPCommandHelpers.find_node_by_class(editor_log, "RichTextLabel") as RichTextLabel
		if rich_text:
			rich_text.clear()
	# Also clear the log file on disk (same default path used by _get_log fallback)
	var log_path: String = ProjectSettings.get_setting("debug/file_logging/log_path", "user://logs/godot.log") as String
	if FileAccess.file_exists(log_path):
		var file: FileAccess = FileAccess.open(log_path, FileAccess.WRITE)
		if file:
			file.store_string("")
			file.close()
	return {"success": true, "message": "Editor log cleared"}



