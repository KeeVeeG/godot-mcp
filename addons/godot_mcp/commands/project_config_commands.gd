## Project configuration commands module - 12 tools.
## Handles project settings, input map, and autoload management.
@tool
class_name MCPProjectConfigCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


## Router compatibility: returns callable map for MCPCommandRouter.
func get_commands() -> Dictionary:
	return {
		"project_config/get_setting": func(params: Dictionary) -> Dictionary: return execute("get_setting", params),
		"project_config/set_setting_config": func(params: Dictionary) -> Dictionary: return execute("set_setting_config", params),
		"project_config/get_all_settings": func(params: Dictionary) -> Dictionary: return execute("get_all_settings", params),
		"project_config/reset_setting": func(params: Dictionary) -> Dictionary: return execute("reset_setting", params),
		"project_config/get_input_map": func(params: Dictionary) -> Dictionary: return execute("get_input_map", params),
		"project_config/set_input_map": func(params: Dictionary) -> Dictionary: return execute("set_input_map", params),
		"project_config/add_input_action": func(params: Dictionary) -> Dictionary: return execute("add_input_action", params),
		"project_config/remove_input_action": func(params: Dictionary) -> Dictionary: return execute("remove_input_action", params),
		"project_config/get_autoloads": func(params: Dictionary) -> Dictionary: return execute("get_autoloads", params),
		"project_config/add_autoload_config": func(params: Dictionary) -> Dictionary: return execute("add_autoload_config", params),
		"project_config/remove_autoload_config": func(params: Dictionary) -> Dictionary: return execute("remove_autoload_config", params),
		"project_config/reorder_autoloads": func(params: Dictionary) -> Dictionary: return execute("reorder_autoloads", params),
		"project_config/remove_setting": func(params: Dictionary) -> Dictionary: return execute("remove_setting", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_setting": return _get_setting(params)
		"set_setting_config": return _set_setting(params)
		"get_all_settings": return _get_all_settings(params)
		"reset_setting": return _reset_setting(params)
		"get_input_map": return _get_input_map()
		"set_input_map": return _set_input_map(params)
		"add_input_action": return _add_input_action(params)
		"remove_input_action": return _remove_input_action(params)
		"get_autoloads": return _get_autoloads()
		"add_autoload_config": return _add_autoload(params)
		"remove_autoload_config": return _remove_autoload(params)
		"reorder_autoloads": return _reorder_autoloads(params)
		"remove_setting": return _remove_setting(params)
	return {"success": false, "error": "Unknown method: " + method}


## Get a single project setting value.
func _get_setting(params: Dictionary) -> Dictionary:
	var key: String = params.get("key", "")
	if key.is_empty():
		return {"success": false, "error": "Key cannot be empty"}
	if not ProjectSettings.has_setting(key):
		return {"success": false, "error": "Setting not found: %s" % key}
	var value: Variant = ProjectSettings.get_setting(key)
	return {"success": true, "key": key, "value": MCPVariantCodec.serialize_value(value)}


## Set a project setting and save.
## For registered settings, validates value type against the expected Godot type.
## Custom settings (not in property_list) are allowed with any type.
func _set_setting(params: Dictionary) -> Dictionary:
	var key: String = params.get("key", "")
	var value: Variant = params.get("value")
	if key.is_empty():
		return {"success": false, "error": "Key cannot be empty"}
	# Reject null — use remove_project_setting to delete a setting instead.
	var is_null: bool = MCPCommandHelpers.is_null(value)
	if is_null:
		return {"success": false, "error": "value cannot be null. Use remove_project_config_setting to delete a setting."}
	# Resolve expected type for this setting
	var expected_type: int = TYPE_NIL
	for p: Dictionary in ProjectSettings.get_property_list():
		if p["name"] == key:
			expected_type = p["type"] as int
			break
	# Coerce String values (from JSON bridge serialization) to expected type
	if typeof(value) == TYPE_STRING:
		var str_val: String = value as String
		match expected_type:
			TYPE_INT:
				if str_val.is_valid_int():
					value = str_val.to_int()
			TYPE_FLOAT:
				if str_val.is_valid_float():
					value = str_val.to_float()
			TYPE_BOOL:
				var lower: String = str_val.to_lower()
				if lower == "true" or lower == "1":
					value = true
				elif lower == "false" or lower == "0":
					value = false

	# Defect 14: Coerce JSON float to int when setting expects int (JSON has no integer type)
	if expected_type == TYPE_INT and typeof(value) == TYPE_FLOAT:
		var f: float = value as float
		if f == floor(f):
			value = int(f)
		else:
			return {"success": false, "error": "Type mismatch for '%s': expected int, but got float %s (has fractional part). Use .0-free values for integer settings." % [key, str(f)]}
	# Defect 3: Validate value type matches the setting's expected type
	if expected_type != TYPE_NIL and typeof(value) != expected_type:
		return {"success": false, "error": "Type mismatch for '%s': expected %s, got %s" % [key, _type_name(expected_type), _type_name(typeof(value))]}
	ProjectSettings.set_setting(key, value)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "key": key, "message": "Setting '%s' saved" % key}


## Get all project settings, optionally filtered by prefix.
## Uses path-segment matching: "input/" matches "input/ui_accept" but NOT "input_devices/pointing/..."
## When max_results > 0, limits results and sets truncated=true.
func _get_all_settings(params: Dictionary) -> Dictionary:
	var filter_prefix: String = params.get("filter", "")
	var max_results: int = params.get("max_results", 0)
	var settings: Dictionary = {}
	var count: int = 0
	var truncated: bool = false
	var props: Array = ProjectSettings.get_property_list()
	# Normalize filter to path-segment form: strip trailing "/" then require "/" after the bare name.
	# E.g. filter "input/" → bare "input" → matches keys equal to "input" or starting with "input/"
	# This prevents "input/" from matching "input_devices/" keys.
	var bare_filter: String = filter_prefix.rstrip("/")
	var filter_is_path: bool = filter_prefix.ends_with("/")
	for p: Dictionary in props:
		var name: String = p["name"] as String
		if name.begins_with("_"):
			continue
		if filter_prefix == "":
			pass  # No filter — include all
		elif filter_is_path:
			# Path-segment matching: key must exactly equal bare_filter OR start with bare_filter + "/"
			if name != bare_filter and not name.begins_with(bare_filter + "/"):
				continue
		elif not name.begins_with(filter_prefix):
			continue
		var value: Variant = ProjectSettings.get_setting(name)
		if value != null:
			settings[name] = MCPVariantCodec.serialize_value(value)
			count += 1
			if max_results > 0 and count >= max_results:
				truncated = true
				break
	var result: Dictionary = {"success": true, "settings": settings, "count": settings.size()}
	if truncated:
		result["truncated"] = true
		result["message"] = "Results limited to %d entries. Use 'max_results' param to increase, or 'filter' to narrow results." % max_results
	return result


## Reset a project setting to its built-in default value.
## Uses property_get_revert to restore the default without deleting the key.
## This allows get_project_setting to still return the value, and double reset is a no-op.
func _reset_setting(params: Dictionary) -> Dictionary:
	var key: String = params.get("key", "")
	if key.is_empty():
		return {"success": false, "error": "Key cannot be empty"}
	if not ProjectSettings.has_setting(key):
		return {"success": false, "error": "Setting not found: %s" % key}
	if not ProjectSettings.property_can_revert(key):
		return {"success": false, "error": "Setting '%s' cannot be reverted" % key}
	# Get the built-in default value and set to it (matching Godot editor's reset behavior)
	var default_value: Variant = ProjectSettings.property_get_revert(key)
	ProjectSettings.set_setting(key, default_value)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "key": key, "message": "Setting '%s' reset to default" % key}


## Remove a project setting from project.godot.
## For built-in settings (those with defaults), reverts to default instead of destroying.
## For custom/user-added settings, fully deletes the override.
func _remove_setting(params: Dictionary) -> Dictionary:
	var key: String = params.get("key", "")
	if key.is_empty():
		return {"success": false, "error": "Key cannot be empty"}
	if not ProjectSettings.has_setting(key):
		return {"success": false, "error": "Setting not found: %s" % key}
	# Determine if built-in: property_get_revert returns non-nil for built-in, nil for custom
	# property_can_revert() returns true for both, and property_list includes both — neither reliable alone
	var revert_val: Variant = ProjectSettings.property_get_revert(key)
	var is_builtin: bool = typeof(revert_val) != TYPE_NIL
	if is_builtin:
		# Built-in setting: revert to default to avoid permanently destroying the property
		var default_value: Variant = ProjectSettings.property_get_revert(key)
		ProjectSettings.set_setting(key, default_value)
	else:
		# Custom/user-added setting: safe to fully delete the override
		ProjectSettings.set_setting(key, null)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "key": key, "message": ("Setting '%s' reverted to default" if is_builtin else "Setting '%s' removed") % key}


## Get all input actions with their mapped events.
func _get_input_map() -> Dictionary:
	var actions: Dictionary = {}
	for action_name: String in InputMap.get_actions():
		var events: Array = []
		for event: InputEvent in InputMap.action_get_events(action_name):
			events.append(MCPVariantCodec.serialize_input_event(event))
		actions[action_name] = {
			"deadzone": snapped(InputMap.action_get_deadzone(action_name), 0.0001),
			"events": events,
		}
	return {"success": true, "actions": actions}


## Replace or merge the input map.
## When merge=false (default), erases ALL existing actions first (full replacement).
## When merge=true, only adds/updates the provided actions, preserving existing ones.
func _set_input_map(params: Dictionary) -> Dictionary:
	var actions: Dictionary = params.get("actions", {})
	# merge can arrive as bool or string through JSON bridge; coerce robustly
	var merge_raw = params.get("merge", false)
	var merge: bool
	match typeof(merge_raw):
		TYPE_BOOL: merge = merge_raw
		TYPE_STRING: merge = (merge_raw as String).to_lower() == "true"
		TYPE_INT: merge = (merge_raw as int) != 0
		_: merge = false
	# Full replacement: erase all existing actions before adding new ones
	if not merge:
		for action_name: String in InputMap.get_actions():
			InputMap.erase_action(action_name)
	# Add/update actions — supports both flat [events] and nested {deadzone, events} formats
	var total_skipped: int = 0
	for action_name: String in actions:
		var action_data: Variant = actions[action_name]
		var event_list: Array
		var deadzone: float = 0.5
		if action_data is Dictionary and action_data.has("events"):
			# Nested format: {deadzone, events} — from get_input_map roundtrip
			event_list = action_data["events"]
			deadzone = float(action_data.get("deadzone", 0.5))
		elif action_data is Array:
			# Flat format: [events]
			event_list = action_data
		else:
			continue
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, deadzone)
		else:
			InputMap.action_erase_events(action_name)
			InputMap.action_set_deadzone(action_name, deadzone)
		var skipped: int = 0
		for event_data: Dictionary in event_list:
			var event: InputEvent = MCPVariantCodec.create_input_event(event_data)
			if event:
				InputMap.action_add_event(action_name, event)
			else:
				skipped += 1
				push_warning("MCP set_input_map: skipped invalid event for action '%s': %s" % [action_name, str(event_data)])
		if skipped > 0:
			push_warning("MCP set_input_map: %d event(s) skipped for action '%s' — check event type ('key', 'mouse_button', 'joypad_button', 'joypad_motion') and required fields" % [skipped, action_name])
		total_skipped += skipped
	var result: Dictionary = {"success": true, "message": "Input map %s" % ("merged" if merge else "replaced")}
	if total_skipped > 0:
		result["warnings"] = "%d event(s) skipped across all actions. Valid types: key, mouse_button, joypad_button, joypad_motion." % total_skipped
	return result


## Add a new input action with events.
func _add_input_action(params: Dictionary) -> Dictionary:
	var action: String = params.get("action", "").strip_edges()
	var deadzone: float = params.get("deadzone", 0.5)
	var events: Array = params.get("events", [])
	if action.is_empty():
		return {"success": false, "error": "Action name cannot be empty"}
	if InputMap.has_action(action):
		return {"success": false, "error": "Action already exists: %s" % action}
	InputMap.add_action(action, deadzone)
	var skipped: int = 0
	for event_data: Dictionary in events:
		var event: InputEvent = MCPVariantCodec.create_input_event(event_data)
		if event:
			InputMap.action_add_event(action, event)
		else:
			skipped += 1
			push_warning("MCP add_input_action: skipped invalid event for action '%s': %s" % [action, str(event_data)])
	var result: Dictionary = {"success": true, "action": action, "event_count": events.size() - skipped}
	if skipped > 0:
		push_warning("MCP add_input_action: %d event(s) skipped for action '%s' — check event type ('key', 'mouse_button', 'joypad_button', 'joypad_motion') and required fields" % [skipped, action])
		result["warnings"] = "%d event(s) skipped. Valid types: key, mouse_button, joypad_button, joypad_motion." % skipped
	return result


## Remove an input action.
func _remove_input_action(params: Dictionary) -> Dictionary:
	var action: String = params.get("action", "")
	if action.is_empty():
		return {"success": false, "error": "Action name cannot be empty"}
	if not InputMap.has_action(action):
		return {"success": false, "error": "Action not found: %s" % action}
	InputMap.erase_action(action)
	return {"success": true, "action": action, "message": "Action removed"}


## Get all autoload singletons.
func _get_autoloads() -> Dictionary:
	var autoloads: Array = []
	var props: Array = ProjectSettings.get_property_list()
	for p: Dictionary in props:
		var prop_name: String = p["name"] as String
		if not prop_name.begins_with("autoload/"):
			continue
		var autoload_name: String = prop_name.substr("autoload/".length())
		var val: String = ProjectSettings.get_setting(prop_name, "") as String
		var enabled: bool = val.begins_with("*")
		var path: String = val.substr(1) if enabled else val
		autoloads.append({
			"name": autoload_name,
			"path": path,
			"enabled": enabled,
		})
	return {"success": true, "autoloads": autoloads}


## Add an autoload singleton.
func _add_autoload(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")
	var path: String = params.get("path", "")
	var enabled: bool = params.get("enabled", true)
	if name.is_empty():
		return {"success": false, "error": "Name cannot be empty"}
	if path.is_empty():
		return {"success": false, "error": "Path cannot be empty"}
	if not path.begins_with("res://"):
		return {"success": false, "error": "Path must start with 'res://', got: '%s'" % path}
	# Defect 9: Validate the script/scene file exists before adding the autoload
	if not FileAccess.file_exists(path):
		return {"success": false, "error": "File not found: %s. Ensure the script or scene exists at this path." % path}
	var key: String = "autoload/%s" % name
	if ProjectSettings.has_setting(key):
		return {"success": false, "error": "Autoload already exists: %s" % name}
	var prefix: String = "*" if enabled else ""
	ProjectSettings.set_setting(key, prefix + path)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "name": name, "path": path}


## Remove an autoload singleton.
func _remove_autoload(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")
	if name.is_empty():
		return {"success": false, "error": "Name cannot be empty"}
	var key: String = "autoload/%s" % name
	if not ProjectSettings.has_setting(key):
		return {"success": false, "error": "Autoload not found: %s" % name}
	ProjectSettings.set_setting(key, null)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "name": name, "message": "Autoload removed"}


## Reorder autoloads by specifying the new order.
## Saves a backup before modifying to prevent data loss on failure.
func _reorder_autoloads(params: Dictionary) -> Dictionary:
	var order: Array = params.get("order", [])
	if order.is_empty():
		return {"success": false, "error": "Order list cannot be empty"}
	# Collect current autoload data
	var autoload_data: Dictionary = {}
	var props: Array = ProjectSettings.get_property_list()
	for p: Dictionary in props:
		var prop_name: String = p["name"] as String
		if not prop_name.begins_with("autoload/"):
			continue
		var autoload_name: String = prop_name.substr("autoload/".length())
		autoload_data[autoload_name] = ProjectSettings.get_setting(prop_name)
	if autoload_data.is_empty():
		return {"success": false, "error": "No autoloads configured"}
	# Defect 11: Validate that all names in the order list exist
	var unknown: Array = []
	for name: Variant in order:
		var name_str: String = name as String
		if not autoload_data.has(name_str):
			unknown.append(name_str)
	if not unknown.is_empty():
		return {"success": false, "error": "Unknown autoload(s): %s. Available: %s" % [",".join(unknown), ",".join(autoload_data.keys())]}
	# Defect 10: Require the full list — all autoloads must be in the order
	if order.size() != autoload_data.size():
		var missing: Array = []
		for name: String in autoload_data:
			var found: bool = false
			for ordered: Variant in order:
				if (ordered as String) == name:
					found = true
					break
			if not found:
				missing.append(name)
		return {"success": false, "error": "Incomplete order: missing %s. Must include all %d autoloads." % [",".join(missing), autoload_data.size()]}
	# Save backup to temp file for crash recovery
	var backup_path: String = "user://mcp_autoload_backup.json"
	var backup_file: FileAccess = FileAccess.open(backup_path, FileAccess.WRITE)
	if backup_file != null:
		backup_file.store_string(JSON.stringify(autoload_data, "\t"))
		backup_file.close()
	# Clear all autoloads
	for autoload_name: String in autoload_data:
		ProjectSettings.set_setting("autoload/%s" % autoload_name, null)
	# Re-add in new order
	for name: Variant in order:
		var name_str: String = name as String
		ProjectSettings.set_setting("autoload/%s" % name_str, autoload_data[name_str])
	var err: Error = ProjectSettings.save()
	if err != OK:
		# Restore from backup on failure
		for autoload_name: String in autoload_data:
			ProjectSettings.set_setting("autoload/%s" % autoload_name, autoload_data[autoload_name])
		ProjectSettings.save()
		DirAccess.remove_absolute(backup_path)
		return {"success": false, "error": "Failed to save autoloads: %s" % error_string(err)}
	# Remove backup on success
	DirAccess.remove_absolute(backup_path)
	return {"success": true, "order": order, "message": "Autoloads reordered"}


## Helper: convert Variant.Type int to human-readable name.
func _type_name(t: int) -> String:
	match t:
		TYPE_NIL: return "null"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_VECTOR2: return "Vector2"
		TYPE_VECTOR3: return "Vector3"
		TYPE_COLOR: return "Color"
		TYPE_OBJECT: return "Object"
		TYPE_DICTIONARY: return "Dictionary"
		TYPE_ARRAY: return "Array"
	return "type_%d" % t

