## Node introspection commands module - 8 tools.
## Handles node type metadata: properties, signals, methods, enums, constants, hierarchy.
class_name MCPNodeConfigCommands
extends RefCounted

var _plugin: EditorPlugin
var _undo_helper: MCUndoHelper


# Global enums that are not accessible via ClassDB (they are registered
# through CoreConstants, not as classes). Godot has no runtime GDScript API
# to enumerate global enums, so we hardcode the most commonly used ones.
const GLOBAL_ENUMS: Dictionary = {
	"Key": {
		"KEY_NONE": 0, "KEY_SPECIAL": 4194304, "KEY_ESCAPE": 4194305,
		"KEY_TAB": 4194306, "KEY_BACKTAB": 4194307, "KEY_BACKSPACE": 4194308,
		"KEY_ENTER": 4194309, "KEY_KP_ENTER": 4194310, "KEY_INSERT": 4194311,
		"KEY_DELETE": 4194312, "KEY_PAUSE": 4194313, "KEY_PRINT": 4194314,
		"KEY_SYSREQ": 4194315, "KEY_CLEAR": 4194316, "KEY_HOME": 4194317,
		"KEY_END": 4194318, "KEY_LEFT": 4194319, "KEY_UP": 4194320,
		"KEY_RIGHT": 4194321, "KEY_DOWN": 4194322, "KEY_PAGEUP": 4194323,
		"KEY_PAGEDOWN": 4194324, "KEY_SHIFT": 4194325, "KEY_CTRL": 4194326,
		"KEY_META": 4194327, "KEY_ALT": 4194328, "KEY_CAPSLOCK": 4194329,
		"KEY_NUMLOCK": 4194330, "KEY_SCROLLLOCK": 4194331,
		"KEY_F1": 4194332, "KEY_F2": 4194333, "KEY_F3": 4194334,
		"KEY_F4": 4194335, "KEY_F5": 4194336, "KEY_F6": 4194337,
		"KEY_F7": 4194338, "KEY_F8": 4194339, "KEY_F9": 4194340,
		"KEY_F10": 4194341, "KEY_F11": 4194342, "KEY_F12": 4194343,
		"KEY_F13": 4194344, "KEY_F14": 4194345, "KEY_F15": 4194346,
		"KEY_F16": 4194347, "KEY_F17": 4194348, "KEY_F18": 4194349,
		"KEY_F19": 4194350, "KEY_F20": 4194351, "KEY_F21": 4194352,
		"KEY_F22": 4194353, "KEY_F23": 4194354, "KEY_F24": 4194355,
		"KEY_F25": 4194356, "KEY_F26": 4194357, "KEY_F27": 4194358,
		"KEY_F28": 4194359, "KEY_F29": 4194360, "KEY_F30": 4194361,
		"KEY_F31": 4194362, "KEY_F32": 4194363, "KEY_F33": 4194364,
		"KEY_F34": 4194365, "KEY_F35": 4194366,
		"KEY_KP_MULTIPLY": 4194433, "KEY_KP_DIVIDE": 4194434,
		"KEY_KP_SUBTRACT": 4194435, "KEY_KP_PERIOD": 4194436,
		"KEY_KP_ADD": 4194437, "KEY_KP_0": 4194438, "KEY_KP_1": 4194439,
		"KEY_KP_2": 4194440, "KEY_KP_3": 4194441, "KEY_KP_4": 4194442,
		"KEY_KP_5": 4194443, "KEY_KP_6": 4194444, "KEY_KP_7": 4194445,
		"KEY_KP_8": 4194446, "KEY_KP_9": 4194447,
		"KEY_MENU": 4194370, "KEY_HYPER": 4194371, "KEY_HELP": 4194373,
		"KEY_BACK": 4194376, "KEY_FORWARD": 4194377, "KEY_STOP": 4194378,
		"KEY_REFRESH": 4194379, "KEY_VOLUMEDOWN": 4194380,
		"KEY_VOLUMEMUTE": 4194381, "KEY_VOLUMEUP": 4194382,
		"KEY_MEDIAPLAY": 4194388, "KEY_MEDIASTOP": 4194389,
		"KEY_MEDIAPREVIOUS": 4194390, "KEY_MEDIANEXT": 4194391,
		"KEY_MEDIARECORD": 4194392, "KEY_HOMEPAGE": 4194393,
		"KEY_FAVORITES": 4194394, "KEY_SEARCH": 4194395,
		"KEY_STANDBY": 4194396, "KEY_OPENURL": 4194397,
		"KEY_LAUNCHMAIL": 4194398, "KEY_LAUNCHMEDIA": 4194399,
		"KEY_LAUNCH0": 4194400, "KEY_LAUNCH1": 4194401,
		"KEY_LAUNCH2": 4194402, "KEY_LAUNCH3": 4194403,
		"KEY_LAUNCH4": 4194404, "KEY_LAUNCH5": 4194405,
		"KEY_LAUNCH6": 4194406, "KEY_LAUNCH7": 4194407,
		"KEY_LAUNCH8": 4194408, "KEY_LAUNCH9": 4194409,
		"KEY_UNKNOWN": 33554431,
		"KEY_SPACE": 32, "KEY_EXCLAM": 33, "KEY_QUOTEDBL": 34,
		"KEY_NUMBERSIGN": 35, "KEY_DOLLAR": 36, "KEY_PERCENT": 37,
		"KEY_AMPERSAND": 38, "KEY_APOSTROPHE": 39, "KEY_PARENLEFT": 40,
		"KEY_PARENRIGHT": 41, "KEY_ASTERISK": 42, "KEY_PLUS": 43,
		"KEY_COMMA": 44, "KEY_MINUS": 45, "KEY_PERIOD": 46, "KEY_SLASH": 47,
		"KEY_0": 48, "KEY_1": 49, "KEY_2": 50, "KEY_3": 51, "KEY_4": 52,
		"KEY_5": 53, "KEY_6": 54, "KEY_7": 55, "KEY_8": 56, "KEY_9": 57,
		"KEY_COLON": 58, "KEY_SEMICOLON": 59, "KEY_LESS": 60,
		"KEY_EQUAL": 61, "KEY_GREATER": 62, "KEY_QUESTION": 63,
		"KEY_AT": 64, "KEY_A": 65, "KEY_B": 66, "KEY_C": 67, "KEY_D": 68,
		"KEY_E": 69, "KEY_F": 70, "KEY_G": 71, "KEY_H": 72, "KEY_I": 73,
		"KEY_J": 74, "KEY_K": 75, "KEY_L": 76, "KEY_M": 77, "KEY_N": 78,
		"KEY_O": 79, "KEY_P": 80, "KEY_Q": 81, "KEY_R": 82, "KEY_S": 83,
		"KEY_T": 84, "KEY_U": 85, "KEY_V": 86, "KEY_W": 87, "KEY_X": 88,
		"KEY_Y": 89, "KEY_Z": 90,
		"KEY_BRACKETLEFT": 91, "KEY_BACKSLASH": 92, "KEY_BRACKETRIGHT": 93,
		"KEY_ASCIICIRCUM": 94, "KEY_UNDERSCORE": 95, "KEY_QUOTELEFT": 96,
		"KEY_BRACELEFT": 123, "KEY_BAR": 124, "KEY_BRACERIGHT": 125,
		"KEY_ASCIITILDE": 126, "KEY_YEN": 165, "KEY_SECTION": 167,
	},
	"Error": {
		"OK": 0, "FAILED": 1, "ERR_UNAVAILABLE": 2,
		"ERR_UNCONFIGURED": 3, "ERR_UNAUTHORIZED": 4,
		"ERR_PARAMETER_RANGE_ERROR": 5, "ERR_OUT_OF_MEMORY": 6,
		"ERR_FILE_NOT_FOUND": 7, "ERR_FILE_BAD_DRIVE": 8,
		"ERR_FILE_BAD_PATH": 9, "ERR_FILE_NO_PERMISSION": 10,
		"ERR_FILE_ALREADY_IN_USE": 11, "ERR_FILE_CANT_OPEN": 12,
		"ERR_FILE_CANT_WRITE": 13, "ERR_FILE_CANT_READ": 14,
		"ERR_FILE_UNRECOGNIZED": 15, "ERR_FILE_CORRUPT": 16,
		"ERR_FILE_MISSING_DEPENDENCIES": 17, "ERR_FILE_EOF": 18,
		"ERR_CANT_OPEN": 19, "ERR_CANT_CREATE": 20, "ERR_QUERY_FAILED": 21,
		"ERR_ALREADY_IN_USE": 22, "ERR_LOCKED": 23, "ERR_TIMEOUT": 24,
		"ERR_CANT_CONNECT": 25, "ERR_CANT_RESOLVE": 26,
		"ERR_CONNECTION_ERROR": 27, "ERR_CANT_ACQUIRE_RESOURCE": 28,
		"ERR_CANT_FORK": 29, "ERR_INVALID_DATA": 30,
		"ERR_INVALID_PARAMETER": 31, "ERR_ALREADY_EXISTS": 32,
		"ERR_DOES_NOT_EXIST": 33, "ERR_DATABASE_CANT_READ": 34,
		"ERR_DATABASE_CANT_WRITE": 35, "ERR_COMPILATION_FAILED": 36,
		"ERR_METHOD_NOT_FOUND": 37, "ERR_LINK_FAILED": 38,
		"ERR_SCRIPT_FAILED": 39, "ERR_CYCLIC_LINK": 40,
		"ERR_INVALID_DECLARATION": 41, "ERR_DUPLICATE_SYMBOL": 42,
		"ERR_PARSE_ERROR": 43, "ERR_BUSY": 44, "ERR_SKIP": 45,
		"ERR_HELP": 46, "ERR_BUG": 47, "ERR_PRINTER_ON_FIRE": 48,
	},
	"MouseButton": {
		"MOUSE_BUTTON_NONE": 0, "MOUSE_BUTTON_LEFT": 1,
		"MOUSE_BUTTON_RIGHT": 2, "MOUSE_BUTTON_MIDDLE": 3,
		"MOUSE_BUTTON_WHEEL_UP": 4, "MOUSE_BUTTON_WHEEL_DOWN": 5,
		"MOUSE_BUTTON_WHEEL_LEFT": 6, "MOUSE_BUTTON_WHEEL_RIGHT": 7,
		"MOUSE_BUTTON_XBUTTON1": 8, "MOUSE_BUTTON_XBUTTON2": 9,
	},
	"JoyButton": {
		"JOY_BUTTON_INVALID": -1, "JOY_BUTTON_A": 0, "JOY_BUTTON_B": 1,
		"JOY_BUTTON_X": 2, "JOY_BUTTON_Y": 3, "JOY_BUTTON_BACK": 4,
		"JOY_BUTTON_GUIDE": 5, "JOY_BUTTON_START": 6,
		"JOY_BUTTON_LEFT_STICK": 7, "JOY_BUTTON_RIGHT_STICK": 8,
		"JOY_BUTTON_LEFT_SHOULDER": 9, "JOY_BUTTON_RIGHT_SHOULDER": 10,
		"JOY_BUTTON_DPAD_UP": 11, "JOY_BUTTON_DPAD_DOWN": 12,
		"JOY_BUTTON_DPAD_LEFT": 13, "JOY_BUTTON_DPAD_RIGHT": 14,
		"JOY_BUTTON_MISC1": 15, "JOY_BUTTON_PADDLE1": 16,
		"JOY_BUTTON_PADDLE2": 17, "JOY_BUTTON_PADDLE3": 18,
		"JOY_BUTTON_PADDLE4": 19, "JOY_BUTTON_TOUCHPAD": 20,
		"JOY_BUTTON_SDL_MAX": 21,
	},
	"PropertyHint": {
		"PROPERTY_HINT_NONE": 0, "PROPERTY_HINT_RANGE": 1,
		"PROPERTY_HINT_ENUM": 2, "PROPERTY_HINT_ENUM_SUGGESTION": 3,
		"PROPERTY_HINT_EXP_EASING": 4, "PROPERTY_HINT_LINK": 5,
		"PROPERTY_HINT_FLAGS": 6, "PROPERTY_HINT_LAYERS_2D_RENDER": 7,
		"PROPERTY_HINT_LAYERS_2D_PHYSICS": 8,
		"PROPERTY_HINT_LAYERS_2D_NAVIGATION": 9,
		"PROPERTY_HINT_LAYERS_3D_RENDER": 10,
		"PROPERTY_HINT_LAYERS_3D_PHYSICS": 11,
		"PROPERTY_HINT_LAYERS_3D_NAVIGATION": 12, "PROPERTY_HINT_FILE": 13,
		"PROPERTY_HINT_DIR": 14, "PROPERTY_HINT_GLOBAL_FILE": 15,
		"PROPERTY_HINT_GLOBAL_DIR": 16,
		"PROPERTY_HINT_RESOURCE_TYPE": 17, "PROPERTY_HINT_MULTILINE_TEXT": 18,
		"PROPERTY_HINT_EXPRESSION": 19, "PROPERTY_HINT_PLACEHOLDER_TEXT": 20,
		"PROPERTY_HINT_COLOR_NO_ALPHA": 21, "PROPERTY_HINT_OBJECT_ID": 22,
		"PROPERTY_HINT_TYPE_STRING": 23, "PROPERTY_HINT_NODE_PATH_TO_EDITED_NODE": 24,
		"PROPERTY_HINT_OBJECT_TOO_BIG": 25, "PROPERTY_HINT_NODE_PATH_VALID_TYPES": 26,
		"PROPERTY_HINT_SAVE_FILE": 27, "PROPERTY_HINT_GLOBAL_SAVE_FILE": 28,
		"PROPERTY_HINT_INT_IS_OBJECTID": 29, "PROPERTY_HINT_INT_IS_POINTER": 30,
		"PROPERTY_HINT_ARRAY_TYPE": 31,
		"PROPERTY_HINT_LOCALE_ID": 32, "PROPERTY_HINT_LOCALIZABLE_STRING": 33,
		"PROPERTY_HINT_NODE_TYPE": 34, "PROPERTY_HINT_HIDE_QUATERNION_EDIT": 35,
		"PROPERTY_HINT_PASSWORD": 36, "PROPERTY_HINT_LAYERS_AVOIDANCE": 37,
		"PROPERTY_HINT_MAX": 38,
	},
	"PropertyUsageFlags": {
		"PROPERTY_USAGE_NONE": 0, "PROPERTY_USAGE_STORAGE": 2,
		"PROPERTY_USAGE_EDITOR": 4, "PROPERTY_USAGE_INTERNAL": 8,
		"PROPERTY_USAGE_CHECKABLE": 16, "PROPERTY_USAGE_CHECKED": 32,
		"PROPERTY_USAGE_GROUP": 64, "PROPERTY_USAGE_CATEGORY": 128,
		"PROPERTY_USAGE_SUBGROUP": 256, "PROPERTY_USAGE_CLASS_IS_BITFIELD": 512,
		"PROPERTY_USAGE_NO_INSTANCE_STATE": 1024,
		"PROPERTY_USAGE_RESTART_IF_CHANGED": 2048,
		"PROPERTY_USAGE_SCRIPT_VARIABLE": 4096, "PROPERTY_USAGE_STORE_IF_NULL": 8192,
		"PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED": 16384,
		"PROPERTY_USAGE_SCRIPT_DEFAULT_VALUE": 32768,
		"PROPERTY_USAGE_CLASS_IS_ENUM": 65536,
		"PROPERTY_USAGE_NIL_IS_VARIANT": 131072, "PROPERTY_USAGE_ARRAY": 262144,
		"PROPERTY_USAGE_ALWAYS_DUPLICATE": 524288,
		"PROPERTY_USAGE_NEVER_DUPLICATE": 1048576,
		"PROPERTY_USAGE_HIGH_END_GFX": 2097152,
		"PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT": 4194304,
		"PROPERTY_USAGE_RESOURCE_NOT_PERSISTENT": 8388608,
		"PROPERTY_USAGE_KEYING_INCREMENTS": 16777216,
		"PROPERTY_USAGE_DEFERRED_SET_RESOURCE": 33554432,
		"PROPERTY_USAGE_EDITOR_INSTANTIATE_OBJECT": 67108864,
		"PROPERTY_USAGE_EDITOR_BASIC_SETTING": 134217728,
		"PROPERTY_USAGE_READ_ONLY": 268435456,
		"PROPERTY_USAGE_SECRET": 536870912, "PROPERTY_USAGE_DEFAULT": 6,
		"PROPERTY_USAGE_NO_EDITOR": 2,
	},
	"MethodFlags": {
		"METHOD_FLAG_NORMAL": 1, "METHOD_FLAG_EDITOR": 2,
		"METHOD_FLAG_CONST": 4, "METHOD_FLAG_VIRTUAL": 8,
		"METHOD_FLAG_VARARG": 16, "METHOD_FLAG_STATIC": 32,
		"METHOD_FLAG_OBJECT_CORE": 64, "METHOD_FLAGS_DEFAULT": 1,
	},
	"Variant.Type": {
		"TYPE_NIL": 0, "TYPE_BOOL": 1, "TYPE_INT": 2, "TYPE_FLOAT": 3,
		"TYPE_STRING": 4, "TYPE_VECTOR2": 5, "TYPE_VECTOR2I": 6,
		"TYPE_RECT2": 7, "TYPE_RECT2I": 8, "TYPE_VECTOR3": 9,
		"TYPE_VECTOR3I": 10, "TYPE_TRANSFORM2D": 11, "TYPE_VECTOR4": 12,
		"TYPE_VECTOR4I": 13, "TYPE_PLANE": 14, "TYPE_QUATERNION": 15,
		"TYPE_AABB": 16, "TYPE_BASIS": 17, "TYPE_TRANSFORM3D": 18,
		"TYPE_PROJECTION": 19, "TYPE_COLOR": 20, "TYPE_STRING_NAME": 21,
		"TYPE_NODE_PATH": 22, "TYPE_RID": 23, "TYPE_OBJECT": 24,
		"TYPE_CALLABLE": 25, "TYPE_SIGNAL": 26, "TYPE_DICTIONARY": 27,
		"TYPE_ARRAY": 28, "TYPE_PACKED_BYTE_ARRAY": 29,
		"TYPE_PACKED_INT32_ARRAY": 30, "TYPE_PACKED_INT64_ARRAY": 31,
		"TYPE_PACKED_FLOAT32_ARRAY": 32, "TYPE_PACKED_FLOAT64_ARRAY": 33,
		"TYPE_PACKED_STRING_ARRAY": 34, "TYPE_PACKED_VECTOR2_ARRAY": 35,
		"TYPE_PACKED_VECTOR3_ARRAY": 36, "TYPE_PACKED_COLOR_ARRAY": 37,
		"TYPE_PACKED_VECTOR4_ARRAY": 38, "TYPE_MAX": 39,
	},
	"Side": {
		"SIDE_LEFT": 0, "SIDE_TOP": 1, "SIDE_RIGHT": 2, "SIDE_BOTTOM": 3,
	},
	"Corner": {
		"CORNER_TOP_LEFT": 0, "CORNER_TOP_RIGHT": 1,
		"CORNER_BOTTOM_RIGHT": 2, "CORNER_BOTTOM_LEFT": 3,
	},
	"Orientation": {
		"HORIZONTAL": 0, "VERTICAL": 1,
	},
	"ClockDirection": {
		"CLOCKWISE": 0, "COUNTERCLOCKWISE": 1,
	},
	"HorizontalAlignment": {
		"HORIZONTAL_ALIGNMENT_LEFT": 0, "HORIZONTAL_ALIGNMENT_CENTER": 1,
		"HORIZONTAL_ALIGNMENT_RIGHT": 2, "HORIZONTAL_ALIGNMENT_FILL": 3,
	},
	"VerticalAlignment": {
		"VERTICAL_ALIGNMENT_TOP": 0, "VERTICAL_ALIGNMENT_CENTER": 1,
		"VERTICAL_ALIGNMENT_BOTTOM": 2, "VERTICAL_ALIGNMENT_FILL": 3,
	},
	"EulerOrder": {
		"EULER_ORDER_XYZ": 0, "EULER_ORDER_XZY": 1,
		"EULER_ORDER_YXZ": 2, "EULER_ORDER_YZX": 3,
		"EULER_ORDER_ZXY": 4, "EULER_ORDER_ZYX": 5,
	},
}


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin
	if _plugin.has_method("get_undo_helper"):
		_undo_helper = _plugin.get_undo_helper()


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
		defaults[pname] = MCPVariantCodec.serialize_value(val)
	if instance is Node:
		instance.queue_free()
	return {"success": true, "type": type, "defaults": defaults}


## Apply a configuration preset to a node in the scene.
func _set_preset(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var preset: String = params.get("preset", "")
	if path.is_empty() or preset.is_empty():
		return {"success": false, "error": "Path and preset are required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"success": false, "error": "No scene open"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"success": false, "error": "Node not found: %s" % path}
	var type: String = node.get_class()
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
			elif type == "Camera3D":
				preset_data = {"projection": 1, "size": 10.0, "rotation_degrees": {"x": -90, "y": 0, "z": 0}}
		"player_area":
			if type == "Area2D" or type == "Area3D":
				preset_data = {"monitoring": true, "monitorable": true}
		_:
			return {"success": false, "error": "Unknown preset: %s" % preset}
	if preset_data.is_empty():
		return {"success": false, "error": "Preset '%s' is not applicable to type '%s'" % [preset, type]}
	# Apply each property with UndoRedo support
	for prop: String in preset_data:
		var value: Variant = preset_data[prop]
		if MCPCommandHelpers.has_property(node, prop):
			var expected_type: int = MCPCommandHelpers.get_property_type(node, prop)
			value = MCPVariantCodec.parse_for_property(value, expected_type)
		if _undo_helper:
			_undo_helper.set_property_with_undo(node, prop, value)
		else:
			node.set(prop, value)
	return {"success": true, "type": type, "preset": preset, "path": path, "message": "Preset '%s' applied to %s" % [preset, path]}


## Get available node types, optionally filtered by category.
func _get_types(params: Dictionary) -> Dictionary:
	var category: String = params.get("category", "")
	var types: Array = []
	var all_classes: PackedStringArray = ClassDB.get_class_list()
	for cls: String in all_classes:
		if not ClassDB.is_parent_class(cls, "Node"):
			continue
		# Filter out editor-only classes (EditorPlugins, editor dialogs, etc.)
		var api_type: int = ClassDB.class_get_api_type(cls)
		if api_type == ClassDB.APIType.API_EDITOR or api_type == ClassDB.APIType.API_EDITOR_EXTENSION:
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


## Get constants defined on a node type or global enum.
func _get_constants(params: Dictionary) -> Dictionary:
	var type: String = params.get("type", "")
	if type.is_empty():
		return {"success": false, "error": "Type cannot be empty"}
	# Global enums (Key, Error, MouseButton, etc.) are not classes, so
	# ClassDB.class_exists() returns false. Check our hardcoded lookup first.
	if GLOBAL_ENUMS.has(type):
		return {"success": true, "type": type, "constants": GLOBAL_ENUMS[type], "count": GLOBAL_ENUMS[type].size()}
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
