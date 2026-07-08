## Project configuration commands module - 12 tools.
## Handles project settings, input map, and autoload management.
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
## Validates key existence and type before saving.
func _set_setting(params: Dictionary) -> Dictionary:
	var key: String = params.get("key", "")
	var value: Variant = params.get("value")
	if key.is_empty():
		return {"success": false, "error": "Key cannot be empty"}
	# Defect 2: Validate key exists in ProjectSettings registry
	if not ProjectSettings.has_setting(key):
		return {"success": false, "error": "Setting '%s' does not exist. Check the key spelling or list valid keys with get_all_project_settings." % key}
	# Defect 4/13: Handle null (or string "null") as reset-to-default using property_get_revert.
	# This preserves the key in ProjectSettings.props, so has_setting() still returns true.
	var is_null: bool = (value == null) or (value is String and (value as String) == "null")
	if is_null:
		if not ProjectSettings.property_can_revert(key):
			# Not a revertable setting — fall back to deletion (custom settings)
			ProjectSettings.set_setting(key, null)
			var err: Error = ProjectSettings.save()
			if err != OK:
				return {"success": false, "error": "Failed to save: %s" % error_string(err)}
			return {"success": true, "key": key, "message": "Setting '%s' removed" % key}
		var default_value: Variant = ProjectSettings.property_get_revert(key)
		ProjectSettings.set_setting(key, default_value)
		var err: Error = ProjectSettings.save()
		if err != OK:
			return {"success": false, "error": "Failed to save: %s" % error_string(err)}
		return {"success": true, "key": key, "message": "Setting '%s' reset to default" % key}
	# Resolve expected type for this setting
	var expected_type: int = TYPE_NIL
	for p: Dictionary in ProjectSettings.get_property_list():
		if p["name"] == key:
			expected_type = p["type"] as int
			break
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
func _get_all_settings(params: Dictionary) -> Dictionary:
	var filter_prefix: String = params.get("filter", "")
	var settings: Dictionary = {}
	var props: Array = ProjectSettings.get_property_list()
	for p: Dictionary in props:
		var name: String = p["name"] as String
		if name.begins_with("_"):
			continue
		if filter_prefix != "" and not name.begins_with(filter_prefix):
			continue
		var value: Variant = ProjectSettings.get_setting(name)
		if value != null:
			settings[name] = MCPVariantCodec.serialize_value(value)
	return {"success": true, "settings": settings, "count": settings.size()}


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
## When merge=false (default), erases all non-default actions first.
## When merge=true, only adds/updates the provided actions, preserving existing ones.
func _set_input_map(params: Dictionary) -> Dictionary:
	var actions: Dictionary = params.get("actions", {})
	var merge: bool = params.get("merge", false)
	# Only clear non-default actions when not merging
	if not merge:
		for action_name: String in InputMap.get_actions():
			if not action_name.begins_with("ui_"):
				InputMap.erase_action(action_name)
	# Add/update actions — supports both flat [events] and nested {deadzone, events} formats
	for action_name: String in actions:
		var action_data: Variant = actions[action_name]
		var event_list: Array
		if action_data is Dictionary and action_data.has("events"):
			# Nested format: {deadzone, events} — from get_input_map roundtrip
			event_list = action_data["events"]
		elif action_data is Array:
			# Flat format: [events]
			event_list = action_data
		else:
			continue
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		else:
			InputMap.action_erase_events(action_name)
		for event_data: Dictionary in event_list:
			var event: InputEvent = MCPVariantCodec.create_input_event(event_data)
			if event:
				InputMap.action_add_event(action_name, event)
	return {"success": true, "message": "Input map %s" % ("merged" if merge else "replaced")}


## Add a new input action with events.
func _add_input_action(params: Dictionary) -> Dictionary:
	var action: String = params.get("action", "")
	var deadzone: float = params.get("deadzone", 0.5)
	var events: Array = params.get("events", [])
	if action.is_empty():
		return {"success": false, "error": "Action name cannot be empty"}
	if InputMap.has_action(action):
		return {"success": false, "error": "Action already exists: %s" % action}
	InputMap.add_action(action, deadzone)
	for event_data: Dictionary in events:
		var event: InputEvent = MCPVariantCodec.create_input_event(event_data)
		if event:
			InputMap.action_add_event(action, event)
	return {"success": true, "action": action, "event_count": events.size()}


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

