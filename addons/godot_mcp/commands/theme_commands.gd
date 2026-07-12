## Theme commands module - 11 tools.
## Handles theme creation, deletion, colors, constants, fonts, and styleboxes.
@tool
class_name MCPThemeCommands
extends RefCounted

var _plugin: EditorPlugin
var _undo_helper: MCUndoHelper


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin
	if _plugin.has_method("get_undo_helper"):
		_undo_helper = _plugin.get_undo_helper()


## Validate that theme_type is a real Control-derived class.
func _is_valid_theme_type(type_name: String) -> bool:
	return ClassDB.class_exists(type_name) and ClassDB.is_parent_class(type_name, "Control")


## Check if a color name looks like a standard Godot theme color name.
## Non-ASCII names are likely to be silently dropped by Godot.
func _is_valid_theme_color_name(name_str: String) -> bool:
	# Standard Godot theme color names for common Control types
	var _known: PackedStringArray = [
		"font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
		"font_hover_pressed_color", "font_disabled_color", "font_outline_color",
		"font_placeholder_color", "font_selection_color",
		"icon_normal_color", "icon_hover_color", "icon_pressed_color",
		"icon_focus_color", "icon_disabled_color",
		"font_color_hover", "font_color_pressed",
		"title_color",
		"default_color",
		"read_only_color",
		"search_right_color", "search_mismatch_color",
		"caret_color", "selection_color", "background_color",
		"current_line_color", "word_highlighted_color",
		"line_number_color", "safe_line_number_color",
		"folded_code_region_color",
		"brace_mismatch_color",
		"bookmark_color", "breakpoint_color", "executing_line_color",
	]
	if name_str in _known:
		return true
	# Check if it's a reasonable ASCII snake_case identifier
	var regex: RegEx = RegEx.new()
	regex.compile("^[a-z][a-z0-9_]*$")
	return regex.search(name_str) != null


## Convert a Color to uppercase hex, omitting alpha when fully opaque.
func _color_to_hex(c: Color) -> String:
	if is_equal_approx(c.a, 1.0):
		return "#" + c.to_html(false).to_upper()
	else:
		return "#" + c.to_html(true).to_upper()


func get_commands() -> Dictionary:
	return {
		"theme/create": create_theme,
		"theme/delete": _delete_theme,
		"theme/set_color": set_theme_color,
		"theme/set_constant": set_theme_constant,
		"theme/set_font_size": set_theme_font_size,
		"theme/set_stylebox": set_theme_stylebox,
		"theme/get_info": get_theme_info,
		"theme/get_color": get_theme_color,
		"theme/get_constant": get_theme_constant,
		"theme/get_font_size": get_theme_font_size,
		"theme/get_stylebox": get_theme_stylebox,
	}


## Create a new theme resource.
func create_theme(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "res://theme.tres")
	if path.is_empty():
		return {"error": "Path cannot be empty"}
	if not path.begins_with("res://") and not path.begins_with("user://"):
		return {"error": "Path must start with 'res://' or 'user://' (e.g. 'res://assets/theme.tres')"}
	var theme: Theme = Theme.new()
	MCPCommandHelpers.ensure_dir(path.get_base_dir())
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
	var _delete_warning: String = ""
	var root: Node = MCPCommandHelpers.get_edited_scene_root(_plugin)
	if root:
		var refs: Array = _find_theme_refs_in_scene(root, path, 0, 20)
		if not refs.is_empty():
			_delete_warning = "Warning: Theme is currently referenced by nodes: %s. These nodes now have dangling theme references." % str(refs)
	
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
	var msg: String = str({"deleted": path})
	if not _delete_warning.is_empty():
		msg = str({"deleted": path, "warning": _delete_warning})
	return {"result": msg}


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
	if path.is_empty():
		return {"error": "path is required"}
	if theme_type.is_empty():
		return {"error": "theme_type is required"}
	if name_str.is_empty():
		return {"error": "name is required"}
	if not _is_valid_theme_type(theme_type):
		return {"error": "Invalid theme_type: '%s' is not a valid Control class" % theme_type}

	if color is String and not MCPVariantCodec.is_valid_color_string(color as String):
		return {"error": "Invalid color: '%s'" % color}

	var theme: Theme = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Theme
	if theme == null:
		return {"error": "Theme not found: %s" % path}

	# Non-standard color names (non-ASCII chars) are silently dropped by Godot — reject them
	if not _is_valid_theme_color_name(name_str):
		return {"error": "Invalid color name: '%s'. Use standard names like 'font_color', 'font_hover_color', etc. Non-standard names are silently rejected by Godot." % name_str}

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
	if path.is_empty():
		return {"error": "path is required"}
	if theme_type.is_empty():
		return {"error": "theme_type is required"}
	if name_str.is_empty():
		return {"error": "name is required"}
	if not _is_valid_theme_type(theme_type):
		return {"error": "Invalid theme_type: '%s' is not a valid Control class" % theme_type}

	var theme: Theme = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Theme
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
	if path.is_empty():
		return {"error": "path is required"}
	if theme_type.is_empty():
		return {"error": "theme_type is required"}
	if name_str.is_empty():
		return {"error": "name is required"}
	if not _is_valid_theme_type(theme_type):
		return {"error": "Invalid theme_type: '%s' is not a valid Control class" % theme_type}

	var theme: Theme = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Theme
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
	if path.is_empty():
		return {"error": "path is required"}
	if theme_type.is_empty():
		return {"error": "theme_type is required"}
	if name_str.is_empty():
		return {"error": "name is required"}
	if not _is_valid_theme_type(theme_type):
		return {"error": "Invalid theme_type: '%s' is not a valid Control class" % theme_type}

	var theme: Theme = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Theme
	if theme == null:
		return {"error": "Theme not found: %s" % path}

	# Read stylebox_type from top-level param (Defect #4), fall back to properties.type for backwards compat
	var style_type: String = params.get("stylebox_type", "")
	if style_type.is_empty():
		style_type = properties.get("type", "Flat")
	else:
		# Remove 'type' from properties to avoid treating it as an unknown property
		properties.erase("type")

	var stylebox: StyleBox = null
	var _style_warning: String = ""

	# Validate property names before applying (Defect #3)
	var _flat_valid_props: PackedStringArray = [
		"bg_color", "border_color",
		"border_width_left", "border_width_right", "border_width_top", "border_width_bottom",
		"corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right",
		"content_margin_left", "content_margin_top", "content_margin_right", "content_margin_bottom",
		"draw_center", "anti_aliasing",
		"shadow_size", "shadow_offset", "shadow_color",
		"expand_margin_left", "expand_margin_right", "expand_margin_top", "expand_margin_bottom",
		"aa_size", "aa_on",
	]
	var _line_valid_props: PackedStringArray = ["color", "thickness"]
	var _tex_valid_props: PackedStringArray = ["texture", "region_rect", "margin_left", "margin_right", "margin_top", "margin_bottom", "draw_center", "modulate_color"]
	var _empty_valid_props: PackedStringArray = []  # StyleBoxEmpty has no properties
	var _valid_props: PackedStringArray = _flat_valid_props
	match style_type:
		"Line": _valid_props = _line_valid_props
		"Empty": _valid_props = _empty_valid_props
		"Texture": _valid_props = _tex_valid_props
		_: _valid_props = _flat_valid_props

	var _invalid_keys: Array = []
	for key in properties.keys():
		if key != "type" and not key in _valid_props:
			_invalid_keys.append(key)
	if not _invalid_keys.is_empty():
		_style_warning = "Warning: unrecognized StyleBox property names ignored: %s" % str(_invalid_keys)

	match style_type:
		"Flat":
			var flat: StyleBoxFlat = StyleBoxFlat.new()
			if properties.has("bg_color"):
				var bg_str: String = properties["bg_color"] as String
				if not MCPVariantCodec.is_valid_color_string(bg_str):
					return {"error": "Invalid bg_color: '%s'" % bg_str}
				flat.bg_color = MCPVariantCodec._parse_color(properties["bg_color"])
			if properties.has("border_color"):
				var bc_str: String = properties["border_color"] as String
				if not MCPVariantCodec.is_valid_color_string(bc_str):
					return {"error": "Invalid border_color: '%s'" % bc_str}
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
			if properties.has("draw_center"):
				flat.draw_center = properties["draw_center"] as bool
			if properties.has("anti_aliasing"):
				flat.anti_aliasing = properties["anti_aliasing"] as bool
			if properties.has("shadow_size"):
				flat.shadow_size = properties["shadow_size"] as int
			if properties.has("shadow_offset"):
				var so_arr: Array = properties["shadow_offset"] as Array
				if so_arr and so_arr.size() >= 2:
					flat.shadow_offset = Vector2(so_arr[0] as float, so_arr[1] as float)
			if properties.has("shadow_color"):
				var sc_str: String = properties["shadow_color"] as String
				if not MCPVariantCodec.is_valid_color_string(sc_str):
					return {"error": "Invalid shadow_color: '%s'" % sc_str}
				flat.shadow_color = MCPVariantCodec._parse_color(properties["shadow_color"])
			if properties.has("expand_margin_left"):
				flat.expand_margin_left = properties["expand_margin_left"] as float
			if properties.has("expand_margin_top"):
				flat.expand_margin_top = properties["expand_margin_top"] as float
			if properties.has("expand_margin_right"):
				flat.expand_margin_right = properties["expand_margin_right"] as float
			if properties.has("expand_margin_bottom"):
				flat.expand_margin_bottom = properties["expand_margin_bottom"] as float
			if properties.has("aa_size"):
				flat.anti_aliasing_size = properties["aa_size"] as float
			stylebox = flat
		"Line":
			var line: StyleBoxLine = StyleBoxLine.new()
			if properties.has("color"):
				var clr_str: String = properties["color"] as String
				if not MCPVariantCodec.is_valid_color_string(clr_str):
					return {"error": "Invalid color: '%s'" % clr_str}
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
	var msg: String = "StyleBox '%s' (%s) set for '%s' in theme" % [name_str, style_type, theme_type]
	if not _style_warning.is_empty():
		msg += ". " + _style_warning
	return {"result": msg}


## Get info about a theme resource.
func get_theme_info(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}

	var theme: Theme = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Theme
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


## Get a specific color value from a theme.
func get_theme_color(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var theme_type: String = params.get("theme_type", "")
	var name_str: String = params.get("name", "")
	if path.is_empty():
		return {"error": "path is required"}
	if theme_type.is_empty():
		return {"error": "theme_type is required"}
	if name_str.is_empty():
		return {"error": "name is required"}
	if not _is_valid_theme_type(theme_type):
		return {"error": "Invalid theme_type: '%s' is not a valid Control class" % theme_type}

	var theme: Theme = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Theme
	if theme == null:
		return {"error": "Theme not found: %s" % path}

	if not theme.has_color(name_str, theme_type):
		return {"error": "Color '%s' not found for type '%s'" % [name_str, theme_type]}

	var color: Color = theme.get_color(name_str, theme_type)
	var hex: String
	if is_equal_approx(color.a, 1.0):
		hex = "#" + color.to_html(false).to_upper()
	else:
		hex = "#" + color.to_html(true).to_upper()
	return {"result": {"name": name_str, "theme_type": theme_type, "color": hex}}


## Get a specific constant value from a theme.
func get_theme_constant(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var theme_type: String = params.get("theme_type", "")
	var name_str: String = params.get("name", "")
	if path.is_empty():
		return {"error": "path is required"}
	if theme_type.is_empty():
		return {"error": "theme_type is required"}
	if name_str.is_empty():
		return {"error": "name is required"}
	if not _is_valid_theme_type(theme_type):
		return {"error": "Invalid theme_type: '%s' is not a valid Control class" % theme_type}

	var theme: Theme = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Theme
	if theme == null:
		return {"error": "Theme not found: %s" % path}

	if not theme.has_constant(name_str, theme_type):
		return {"error": "Constant '%s' not found for type '%s'" % [name_str, theme_type]}

	var value: int = theme.get_constant(name_str, theme_type)
	return {"result": {"name": name_str, "theme_type": theme_type, "value": value}}


## Get a specific font size value from a theme.
func get_theme_font_size(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var theme_type: String = params.get("theme_type", "")
	var name_str: String = params.get("name", "")
	if path.is_empty():
		return {"error": "path is required"}
	if theme_type.is_empty():
		return {"error": "theme_type is required"}
	if name_str.is_empty():
		return {"error": "name is required"}
	if not _is_valid_theme_type(theme_type):
		return {"error": "Invalid theme_type: '%s' is not a valid Control class" % theme_type}

	var theme: Theme = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Theme
	if theme == null:
		return {"error": "Theme not found: %s" % path}

	if not theme.has_font_size(name_str, theme_type):
		return {"error": "Font size '%s' not found for type '%s'" % [name_str, theme_type]}

	var size: int = theme.get_font_size(name_str, theme_type)
	return {"result": {"name": name_str, "theme_type": theme_type, "size": size}}


## Get a specific StyleBox from a theme.
func get_theme_stylebox(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var theme_type: String = params.get("theme_type", "")
	var name_str: String = params.get("name", "")
	if path.is_empty():
		return {"error": "path is required"}
	if theme_type.is_empty():
		return {"error": "theme_type is required"}
	if name_str.is_empty():
		return {"error": "name is required"}
	if not _is_valid_theme_type(theme_type):
		return {"error": "Invalid theme_type: '%s' is not a valid Control class" % theme_type}

	var theme: Theme = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Theme
	if theme == null:
		return {"error": "Theme not found: %s" % path}

	if not theme.has_stylebox(name_str, theme_type):
		return {"error": "StyleBox '%s' not found for type '%s'" % [name_str, theme_type]}

	var stylebox: StyleBox = theme.get_stylebox(name_str, theme_type)
	var props: Dictionary = {}

	if stylebox is StyleBoxFlat:
		var default_flat: StyleBoxFlat = StyleBoxFlat.new()
		props["type"] = "Flat"
		if stylebox.bg_color != default_flat.bg_color:
			props["bg_color"] = _color_to_hex(stylebox.bg_color)
		if stylebox.border_color != default_flat.border_color:
			props["border_color"] = _color_to_hex(stylebox.border_color)
		if stylebox.border_width_left != default_flat.border_width_left:
			props["border_width_left"] = stylebox.border_width_left
		if stylebox.border_width_right != default_flat.border_width_right:
			props["border_width_right"] = stylebox.border_width_right
		if stylebox.border_width_top != default_flat.border_width_top:
			props["border_width_top"] = stylebox.border_width_top
		if stylebox.border_width_bottom != default_flat.border_width_bottom:
			props["border_width_bottom"] = stylebox.border_width_bottom
		if stylebox.corner_radius_top_left != default_flat.corner_radius_top_left:
			props["corner_radius_top_left"] = stylebox.corner_radius_top_left
		if stylebox.corner_radius_top_right != default_flat.corner_radius_top_right:
			props["corner_radius_top_right"] = stylebox.corner_radius_top_right
		if stylebox.corner_radius_bottom_left != default_flat.corner_radius_bottom_left:
			props["corner_radius_bottom_left"] = stylebox.corner_radius_bottom_left
		if stylebox.corner_radius_bottom_right != default_flat.corner_radius_bottom_right:
			props["corner_radius_bottom_right"] = stylebox.corner_radius_bottom_right
		if stylebox.content_margin_left != default_flat.content_margin_left:
			props["content_margin_left"] = stylebox.content_margin_left
		if stylebox.content_margin_top != default_flat.content_margin_top:
			props["content_margin_top"] = stylebox.content_margin_top
		if stylebox.content_margin_right != default_flat.content_margin_right:
			props["content_margin_right"] = stylebox.content_margin_right
		if stylebox.content_margin_bottom != default_flat.content_margin_bottom:
			props["content_margin_bottom"] = stylebox.content_margin_bottom
		if stylebox.draw_center != default_flat.draw_center:
			props["draw_center"] = stylebox.draw_center
		if stylebox.anti_aliasing != default_flat.anti_aliasing:
			props["anti_aliasing"] = stylebox.anti_aliasing
		if stylebox.shadow_size != default_flat.shadow_size:
			props["shadow_size"] = stylebox.shadow_size
		if stylebox.shadow_offset != default_flat.shadow_offset:
			props["shadow_offset"] = [stylebox.shadow_offset.x, stylebox.shadow_offset.y]
		if not stylebox.shadow_color.is_equal_approx(default_flat.shadow_color):
			props["shadow_color"] = _color_to_hex(stylebox.shadow_color)
		if stylebox.expand_margin_left != default_flat.expand_margin_left:
			props["expand_margin_left"] = stylebox.expand_margin_left
		if stylebox.expand_margin_top != default_flat.expand_margin_top:
			props["expand_margin_top"] = stylebox.expand_margin_top
		if stylebox.expand_margin_right != default_flat.expand_margin_right:
			props["expand_margin_right"] = stylebox.expand_margin_right
		if stylebox.expand_margin_bottom != default_flat.expand_margin_bottom:
			props["expand_margin_bottom"] = stylebox.expand_margin_bottom
		if stylebox.anti_aliasing_size != default_flat.anti_aliasing_size:
			props["aa_size"] = stylebox.anti_aliasing_size
	elif stylebox is StyleBoxLine:
		props["type"] = "Line"
		props["color"] = _color_to_hex(stylebox.color)
		props["thickness"] = stylebox.thickness
	elif stylebox is StyleBoxEmpty:
		props["type"] = "Empty"
	elif stylebox is StyleBoxTexture:
		props["type"] = "Texture"
		if stylebox.texture:
			props["texture"] = stylebox.texture.resource_path
	else:
		props["type"] = "Unknown"

	return {"result": {"name": name_str, "theme_type": theme_type, "properties": props}}



