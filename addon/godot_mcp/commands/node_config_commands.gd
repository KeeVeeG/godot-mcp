## Node introspection commands module - 8 tools.
## Handles node type metadata: properties, signals, methods, enums, constants, hierarchy.
class_name MCPNodeConfigCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


## Router compatibility: returns callable map for MCPCommandRouter.
func get_commands() -> Dictionary:
	return {
		"node_config/get_defaults": func(params: Dictionary) -> Dictionary: return execute("get_defaults", params),
		"node_config/set_preset": func(params: Dictionary) -> Dictionary: return execute("set_preset", params),
		"node_config/get_types": func(params: Dictionary) -> Dictionary: return execute("get_types", params),
		"node_config/get_signals": func(params: Dictionary) -> Dictionary: return execute("get_signals", params),
		"node_config/get_methods": func(params: Dictionary) -> Dictionary: return execute("get_methods", params),
		"node_config/get_enums": func(params: Dictionary) -> Dictionary: return execute("get_enums", params),
		"node_config/get_constants": func(params: Dictionary) -> Dictionary: return execute("get_constants", params),
		"node_config/get_hierarchy": func(params: Dictionary) -> Dictionary: return execute("get_hierarchy", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_defaults": return _get_defaults(params)
		"set_preset": return _set_preset(params)
		"get_types": return _get_types(params)
		"get_signals": return _get_signals(params)
		"get_methods": return _get_methods(params)
		"get_enums": return _get_enums(params)
		"get_constants": return _get_constants(params)
		"get_hierarchy": return _get_hierarchy(params)
	return {"success": false, "error": "Unknown method: " + method}


## Get default property values for a node type.
func _get_defaults(params: Dictionary) -> Dictionary:
	var type: String = params.get("type", "")
	if type.is_empty():
		return {"success": false, "error": "Type cannot be empty"}
	if not ClassDB.class_exists(type):
		return {"success": false, "error": "Unknown type: %s" % type}
	var instance: Object = ClassDB.instantiate(type)
	if instance == null:
		return {"success": false, "error": "Cannot instantiate: %s" % type}
	var defaults: Dictionary = {}
	for p: Dictionary in instance.get_property_list():
		var pname: String = p["name"] as String
		var usage: int = p["usage"] as int
		if usage & PROPERTY_USAGE_STORAGE == 0:
			continue
		if pname.begins_with("_") or pname.begins_with("resource_") or pname.begins_with("script"):
			continue
		var val: Variant = instance.get(pname)
		if val != null:
			defaults[pname] = MCPVariantCodec.serialize_value(val)
	if instance is Node:
		instance.queue_free()
	return {"success": true, "type": type, "defaults": defaults}


## Return configuration preset data for a node type (does not apply it).
func _set_preset(params: Dictionary) -> Dictionary:
	var type: String = params.get("type", "")
	var preset: String = params.get("preset", "")
	if type.is_empty() or preset.is_empty():
		return {"success": false, "error": "Type and preset are required"}
	# Check if the edited scene is open
	var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	# Define presets
	var preset_data: Dictionary = {}
	match preset:
		"platformer_body":
			if type == "CharacterBody2D":
				preset_data = {"motion_mode": 0, "up_direction": {"x": 0, "y": -1}, "floor_max_angle": 0.785398}
			elif type == "CharacterBody3D":
				preset_data = {"motion_mode": 0, "up_direction": {"x": 0, "y": 1, "z": 0}, "floor_max_angle": 0.785398}
		"top_down_camera":
			if type == "Camera2D":
				preset_data = {"position_smoothing_enabled": true, "position_smoothing_speed": 5.0, "drag_horizontal_enabled": true, "drag_vertical_enabled": true}
		"player_area":
			if type == "Area2D" or type == "Area3D":
				preset_data = {"monitoring": true, "monitorable": true}
		_:
			return {"success": false, "error": "Unknown preset: %s" % preset}
	if preset_data.is_empty():
		return {"success": false, "error": "Preset '%s' is not applicable to type '%s'" % [preset, type]}
	return {"success": true, "type": type, "preset": preset, "properties": preset_data, "message": "Preset data returned. This does not apply the preset; use update_property to apply each property to a node."}


## Get available node types, optionally filtered by category.
func _get_types(params: Dictionary) -> Dictionary:
	var category: String = params.get("category", "")
	var types: Array = []
	var all_classes: PackedStringArray = ClassDB.get_class_list()
	for cls: String in all_classes:
		if not ClassDB.is_parent_class(cls, "Node"):
			continue
		if category != "":
			var matches: bool = false
			match category:
				"2d":
					matches = ClassDB.is_parent_class(cls, "Node2D")
				"3d":
					matches = ClassDB.is_parent_class(cls, "Node3D")
				"ui":
					matches = ClassDB.is_parent_class(cls, "Control")
				"audio":
					matches = cls.begins_with("Audio") or ClassDB.is_parent_class(cls, "AudioStreamPlayer")
				"physics":
					matches = ClassDB.is_parent_class(cls, "CollisionObject2D") or ClassDB.is_parent_class(cls, "CollisionObject3D") or ClassDB.is_parent_class(cls, "PhysicsBody2D") or ClassDB.is_parent_class(cls, "PhysicsBody3D")
				"navigation":
					matches = cls.begins_with("Navigation") or ClassDB.is_parent_class(cls, "NavigationAgent2D") or ClassDB.is_parent_class(cls, "NavigationAgent3D")
			if not matches:
				continue
		types.append(cls)
	return {"success": true, "types": types, "count": types.size(), "category": category if category != "" else "all"}


## Get signals defined on a node type.
func _get_signals(params: Dictionary) -> Dictionary:
	var type: String = params.get("type", "")
	if type.is_empty():
		# Fallback: resolve from node instance path
		var node_path: String = params.get("path", "")
		if node_path.is_empty():
			return {"success": false, "error": "Either 'type' or 'path' is required"}
		var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, node_path)
		if node == null:
			return {"success": false, "error": "Node not found: %s" % node_path}
		type = node.get_class()
		var script_obj: Variant = node.get_script()
		if script_obj != null and script_obj is GDScript:
			var script: GDScript = script_obj as GDScript
			var cls: StringName = script.get_class_name()
			if cls != "" and ClassDB.class_exists(String(cls)):
				type = String(cls)
	if not ClassDB.class_exists(type):
		return {"success": false, "error": "Unknown type: %s" % type}
	var signals_list: Array = ClassDB.class_get_signal_list(type, false)
	var result: Array = []
	for sig: Dictionary in signals_list:
		var args: Array = []
		for arg: Dictionary in sig.get("args", []):
			args.append({
				"name": arg["name"],
				"type": type_string(arg["type"] as Variant.Type),
			})
		result.append({
			"name": sig["name"],
			"args": args,
		})
	return {"success": true, "type": type, "signals": result, "count": result.size()}


## Get methods defined on a node type.
func _get_methods(params: Dictionary) -> Dictionary:
	var type: String = params.get("type", "")
	if type.is_empty():
		return {"success": false, "error": "Type cannot be empty"}
	if not ClassDB.class_exists(type):
		return {"success": false, "error": "Unknown type: %s" % type}
	var methods_list: Array = ClassDB.class_get_method_list(type, false)
	var result: Array = []
	for m: Dictionary in methods_list:
		var method_name: String = m["name"] as String
		if method_name.begins_with("_"):
			continue  # Skip private methods
		var args: Array = []
		for arg: Dictionary in m.get("args", []):
			args.append({
				"name": arg["name"],
				"type": type_string(arg["type"] as Variant.Type),
			})
		result.append({
			"name": method_name,
			"args": args,
			"return_type": type_string(m.get("return", {}).get("type", TYPE_NIL) as Variant.Type),
		})
	return {"success": true, "type": type, "methods": result, "count": result.size()}


## Get enumerations defined on a node type.
func _get_enums(params: Dictionary) -> Dictionary:
	var type: String = params.get("type", "")
	if type.is_empty():
		return {"success": false, "error": "Type cannot be empty"}
	if not ClassDB.class_exists(type):
		return {"success": false, "error": "Unknown type: %s" % type}
	var enum_names: PackedStringArray = ClassDB.class_get_enum_list(type, false)
	var result: Array = []
	for enum_name: String in enum_names:
		var values: PackedStringArray = ClassDB.class_get_enum_constants(type, enum_name, false)
		var values_dict: Dictionary = {}
		for val_name: String in values:
			values_dict[val_name] = ClassDB.class_get_integer_constant(type, val_name)
		result.append({
			"name": enum_name,
			"values": values_dict,
		})
	return {"success": true, "type": type, "enums": result, "count": result.size()}


## Get constants defined on a node type.
func _get_constants(params: Dictionary) -> Dictionary:
	var type: String = params.get("type", "")
	if type.is_empty():
		return {"success": false, "error": "Type cannot be empty"}
	if not ClassDB.class_exists(type):
		return {"success": false, "error": "Unknown type: %s" % type}
	var constant_names: PackedStringArray = ClassDB.class_get_integer_constant_list(type, false)
	var constants: Dictionary = {}
	for const_name: String in constant_names:
		constants[const_name] = ClassDB.class_get_integer_constant(type, const_name)
	return {"success": true, "type": type, "constants": constants, "count": constants.size()}


## Get class inheritance hierarchy.
func _get_hierarchy(params: Dictionary) -> Dictionary:
	var type: String = params.get("type", "")
	if type.is_empty():
		return {"success": false, "error": "Type cannot be empty"}
	if not ClassDB.class_exists(type):
		return {"success": false, "error": "Unknown type: %s" % type}
	var chain: Array = []
	var current: String = type
	while current != "":
		chain.append(current)
		current = ClassDB.get_parent_class(current)
	return {"success": true, "type": type, "hierarchy": chain, "depth": chain.size()}
