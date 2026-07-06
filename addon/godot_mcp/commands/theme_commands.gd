## Theme commands module - 7 tools.
## Handles theme creation, deletion, colors, constants, fonts, and styleboxes.
class_name MCPThemeCommands
extends RefCounted

var _plugin: EditorPlugin
var _undo_helper: MCUndoHelper


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin
	if _plugin.has_method("get_undo_helper"):
		_undo_helper = _plugin.get_undo_helper()


func get_commands() -> Dictionary:
	return {
		"theme/create": create_theme,
		"theme/delete": _delete_theme,
		"theme/set_color": set_theme_color,
		"theme/set_constant": set_theme_constant,
		"theme/set_font_size": set_theme_font_size,
		"theme/set_stylebox": set_theme_stylebox,
		"theme/get_info": get_theme_info,
	}


func _get_root() -> Node:
	return MCPCommandHelpers.get_edited_scene_root(_plugin)


## Create a new theme resource.
func create_theme(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "res://theme.tres")
	var theme: Theme = Theme.new()
	_ensure_dir(path.get_base_dir())
	var err: Error = ResourceSaver.save(theme, path)
	if err != OK:
		return {"error": "Failed to save theme: %s" % error_string(err)}
	_plugin.safe_scan_filesystem()
	return {"result": {"path": path}}


## Delete a theme resource file from the project.
func _delete_theme(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	if not FileAccess.file_exists(path):
		return {"error": "Theme not found: %s" % path}
	
	# Check if theme is used by any Control node in the current scene
	var root: Node = MCPCommandHelpers.get_edited_scene_root(_plugin)
	if root:
		var refs: Array = _find_theme_refs_in_scene(root, path, 0, 20)
		if not refs.is_empty():
			return {"error": "Theme is used by nodes: %s. Remove references first." % str(refs)}
	
	# Convert res:// to global path for DirAccess
	var global_path: String = ProjectSettings.globalize_path(path)
	var err: Error = DirAccess.remove_absolute(global_path)
	if err != OK:
		return {"error": "Failed to delete theme: %s" % error_string(err)}
	
	# Also delete .import file if exists
	var import_path: String = global_path + ".import"
	if FileAccess.file_exists(import_path):
		DirAccess.remove_absolute(import_path)
	
	# Also delete .uid file if exists
	var uid_path: String = global_path + ".uid"
	if FileAccess.file_exists(uid_path):
		DirAccess.remove_absolute(uid_path)
	
	_plugin.safe_scan_filesystem()
	return {"result": {"deleted": path}}


## Helper: find nodes that reference a specific theme path.
func _find_theme_refs_in_scene(node: Node, theme_path: String, depth: int = 0, max_depth: int = 20) -> Array:
	var result: Array = []
	if depth >= max_depth:
		return result
	if node is Control:
		var theme_res: Theme = node.theme
		if theme_res and theme_res.resource_path == theme_path:
			result.append(node.get_path())
	for child in node.get_children():
		result.append_array(_find_theme_refs_in_scene(child, theme_path, depth + 1, max_depth))
	return result


## Set a color in a theme.
func set_theme_color(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var theme_type: String = params.get("theme_type", "")
	var name_str: String = params.get("name", "")
	var color: Variant = params.get("color")
	if path.is_empty() or theme_type.is_empty() or name_str.is_empty():
		return {"error": "path, theme_type, and name are required"}

	var theme: Theme = ResourceLoader.load(path) as Theme
	if theme == null:
		return {"error": "Theme not found: %s" % path}

	var parsed_color: Color = MCPVariantCodec._parse_color(color)
	theme.set_color(name_str, theme_type, parsed_color)

	var err: Error = ResourceSaver.save(theme, path)
	if err != OK:
		return {"error": "Failed to save theme: %s" % error_string(err)}
	return {"result": "Color '%s' set for '%s' in theme" % [name_str, theme_type]}


## Set a constant in a theme.
func set_theme_constant(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var theme_type: String = params.get("theme_type", "")
	var name_str: String = params.get("name", "")
	var value: int = params.get("value", 0)
	if path.is_empty() or theme_type.is_empty() or name_str.is_empty():
		return {"error": "path, theme_type, and name are required"}

	var theme: Theme = ResourceLoader.load(path) as Theme
	if theme == null:
		return {"error": "Theme not found: %s" % path}

	theme.set_constant(name_str, theme_type, value)

	var err: Error = ResourceSaver.save(theme, path)
	if err != OK:
		return {"error": "Failed to save theme: %s" % error_string(err)}
	return {"result": "Constant '%s' set for '%s' in theme" % [name_str, theme_type]}


## Set a font size in a theme.
func set_theme_font_size(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var theme_type: String = params.get("theme_type", "")
	var name_str: String = params.get("name", "")
	var size: int = params.get("size", 16)
	if path.is_empty() or theme_type.is_empty() or name_str.is_empty():
		return {"error": "path, theme_type, and name are required"}

	var theme: Theme = ResourceLoader.load(path) as Theme
	if theme == null:
		return {"error": "Theme not found: %s" % path}

	theme.set_font_size(name_str, theme_type, size)

	var err: Error = ResourceSaver.save(theme, path)
	if err != OK:
		return {"error": "Failed to save theme: %s" % error_string(err)}
	return {"result": "Font size '%s' set to %d for '%s' in theme" % [name_str, size, theme_type]}


## Set a StyleBox in a theme.
func set_theme_stylebox(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var theme_type: String = params.get("theme_type", "")
	var name_str: String = params.get("name", "")
	var properties: Dictionary = params.get("properties", {})
	if path.is_empty() or theme_type.is_empty() or name_str.is_empty():
		return {"error": "path, theme_type, and name are required"}

	var theme: Theme = ResourceLoader.load(path) as Theme
	if theme == null:
		return {"error": "Theme not found: %s" % path}

	var style_type: String = properties.get("type", "Flat")
	var stylebox: StyleBox = null
	match style_type:
		"Flat":
			var flat: StyleBoxFlat = StyleBoxFlat.new()
			if properties.has("bg_color"):
				flat.bg_color = MCPVariantCodec._parse_color(properties["bg_color"])
			if properties.has("border_color"):
				flat.border_color = MCPVariantCodec._parse_color(properties["border_color"])
			if properties.has("border_width_left"):
				flat.border_width_left = properties["border_width_left"] as int
			if properties.has("border_width_right"):
				flat.border_width_right = properties["border_width_right"] as int
			if properties.has("border_width_top"):
				flat.border_width_top = properties["border_width_top"] as int
			if properties.has("border_width_bottom"):
				flat.border_width_bottom = properties["border_width_bottom"] as int
			if properties.has("corner_radius_top_left"):
				flat.corner_radius_top_left = properties["corner_radius_top_left"] as int
			if properties.has("corner_radius_top_right"):
				flat.corner_radius_top_right = properties["corner_radius_top_right"] as int
			if properties.has("corner_radius_bottom_left"):
				flat.corner_radius_bottom_left = properties["corner_radius_bottom_left"] as int
			if properties.has("corner_radius_bottom_right"):
				flat.corner_radius_bottom_right = properties["corner_radius_bottom_right"] as int
			if properties.has("content_margin_left"):
				flat.content_margin_left = properties["content_margin_left"] as float
			if properties.has("content_margin_top"):
				flat.content_margin_top = properties["content_margin_top"] as float
			if properties.has("content_margin_right"):
				flat.content_margin_right = properties["content_margin_right"] as float
			if properties.has("content_margin_bottom"):
				flat.content_margin_bottom = properties["content_margin_bottom"] as float
			stylebox = flat
		"Line":
			var line: StyleBoxLine = StyleBoxLine.new()
			if properties.has("color"):
				line.color = MCPVariantCodec._parse_color(properties["color"])
			if properties.has("thickness"):
				line.thickness = properties["thickness"] as int
			stylebox = line
		"Empty":
			var empty: StyleBoxEmpty = StyleBoxEmpty.new()
			stylebox = empty
		"Texture":
			var tex: StyleBoxTexture = StyleBoxTexture.new()
			if properties.has("texture"):
				var tex_path: String = properties["texture"] as String
				var tex_res: Texture2D = ResourceLoader.load(tex_path) as Texture2D
				if tex_res:
					tex.texture = tex_res
			stylebox = tex
		_:
			stylebox = StyleBoxFlat.new()

	theme.set_stylebox(name_str, theme_type, stylebox)

	var err: Error = ResourceSaver.save(theme, path)
	if err != OK:
		return {"error": "Failed to save theme: %s" % error_string(err)}
	return {"result": "StyleBox '%s' (%s) set for '%s' in theme" % [name_str, style_type, theme_type]}


## Get info about a theme resource.
func get_theme_info(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}

	var theme: Theme = ResourceLoader.load(path) as Theme
	if theme == null:
		return {"error": "Theme not found: %s" % path}

	var types: PackedStringArray = theme.get_type_list()
	var result: Dictionary = {"path": path, "types": []}
	for t: String in types:
		var type_info: Dictionary = {"name": t}
		var colors: PackedStringArray = theme.get_color_list(t)
		if colors.size() > 0:
			type_info["colors"] = Array(colors)
		var constants: PackedStringArray = theme.get_constant_list(t)
		if constants.size() > 0:
			type_info["constants"] = Array(constants)
		var fonts: PackedStringArray = theme.get_font_list(t)
		if fonts.size() > 0:
			type_info["fonts"] = Array(fonts)
		var font_sizes: PackedStringArray = theme.get_font_size_list(t)
		if font_sizes.size() > 0:
			type_info["font_sizes"] = Array(font_sizes)
		var styleboxes: PackedStringArray = theme.get_stylebox_list(t)
		if styleboxes.size() > 0:
			type_info["styleboxes"] = Array(styleboxes)
		result["types"].append(type_info)
	return {"result": result}


func _ensure_dir(path: String) -> void:
	MCPCommandHelpers.ensure_dir(path)
