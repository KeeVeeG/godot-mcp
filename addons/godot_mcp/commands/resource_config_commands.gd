## Resource configuration commands module - 6 tools.
## Handles resource type introspection, creation, and import settings.
class_name MCPResourceConfigCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


## Router compatibility: returns callable map for MCPCommandRouter.
func get_commands() -> Dictionary:
	return {
		"resource_config/get_types": func(params: Dictionary) -> Dictionary: return execute("get_types", params),
		"resource_config/get_properties": func(params: Dictionary) -> Dictionary: return execute("get_properties", params),
		"resource_config/create_from_template": func(params: Dictionary) -> Dictionary: return execute("create_from_template", params),
		"resource_config/import": func(params: Dictionary) -> Dictionary: return execute("import", params),
		"resource_config/get_resource_import_settings": func(params: Dictionary) -> Dictionary: return execute("get_resource_import_settings", params),
		"resource_config/set_resource_import_settings": func(params: Dictionary) -> Dictionary: return execute("set_resource_import_settings", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_types": return _get_types()
		"get_properties": return _get_properties(params)
		"create_from_template": return _create_from_template(params)
		"import": return _import(params)
		"get_resource_import_settings": return _get_import_settings(params)
		"set_resource_import_settings": return _set_import_settings(params)
	return {"error": "Unknown method: " + method}


## Get all registered resource types.
func _get_types() -> Dictionary:
	var types: Array = []
	var all_classes: PackedStringArray = ClassDB.get_class_list()
	for cls: String in all_classes:
		if ClassDB.is_parent_class(cls, "Resource"):
			types.append(cls)
	types.sort()
	return {"result": {"types": types, "count": types.size()}}


## Get serializable properties for a resource type.
func _get_properties(params: Dictionary) -> Dictionary:
	var type: String = params.get("type", "")
	if type.is_empty():
		return {"error": "Type cannot be empty"}
	if not ClassDB.class_exists(type):
		return {"error": "Unknown type: %s" % type}
	# Theme override data is stored in private HashMaps, not exposed via get_property_list().
	# get_property_list() only returns 3 default properties (default_base_scale,
	# default_font, default_font_size). Use a dedicated handler.
	if type == "Theme":
		return _get_theme_properties()
	var instance: Object = ClassDB.instantiate(type)
	if instance == null:
		return {"error": "Cannot instantiate: %s" % type}
	var properties: Array = []
	for p: Dictionary in instance.get_property_list():
		var pname: String = p["name"] as String
		var usage: int = p["usage"] as int
		if usage & PROPERTY_USAGE_STORAGE == 0:
			continue
		if pname.begins_with("resource_") or pname.begins_with("script"):
			continue
		properties.append({
			"name": pname,
			"type": type_string(p["type"] as Variant.Type),
			"hint": p.get("hint", 0),
			"hint_string": p.get("hint_string", ""),
		})
	if instance is Resource:
		pass  # Resources don't need queue_free
	return {"result": {"type": type, "properties": properties, "count": properties.size()}}


## Extract Theme override data (colors, constants, fonts, font sizes,
## styleboxes, icons per control type). Theme stores overrides in private
## HashMaps that get_property_list() does not expose.
func _get_theme_properties() -> Dictionary:
	var theme: Theme = Theme.new()
	var result: Dictionary = {
		"type": "Theme",
		"defaults": {
			"default_base_scale": theme.default_base_scale,
			"default_font": theme.default_font.resource_path if theme.default_font else null,
			"default_font_size": theme.default_font_size,
		},
		"overrides": {},
		"type_variations": {},
	}
	for type_name: String in theme.get_type_list():
		var type_data: Dictionary = {}

		# Colors
		var colors: Dictionary = {}
		for item_name: String in theme.get_color_list(type_name):
			colors[item_name] = theme.get_color(item_name, type_name).to_html(true)
		if not colors.is_empty():
			type_data["colors"] = colors

		# Constants
		var constants: Dictionary = {}
		for item_name: String in theme.get_constant_list(type_name):
			constants[item_name] = theme.get_constant(item_name, type_name)
		if not constants.is_empty():
			type_data["constants"] = constants

		# Fonts
		var fonts: Dictionary = {}
		for item_name: String in theme.get_font_list(type_name):
			var f: Font = theme.get_font(item_name, type_name)
			fonts[item_name] = f.resource_path if f else null
		if not fonts.is_empty():
			type_data["fonts"] = fonts

		# Font sizes
		var font_sizes: Dictionary = {}
		for item_name: String in theme.get_font_size_list(type_name):
			font_sizes[item_name] = theme.get_font_size(item_name, type_name)
		if not font_sizes.is_empty():
			type_data["font_sizes"] = font_sizes

		# StyleBoxes — serialize key properties
		var styleboxes: Dictionary = {}
		for item_name: String in theme.get_stylebox_list(type_name):
			var sb: StyleBox = theme.get_stylebox(item_name, type_name)
			styleboxes[item_name] = _serialize_stylebox(sb)
		if not styleboxes.is_empty():
			type_data["styleboxes"] = styleboxes

		# Icons
		var icons: Dictionary = {}
		for item_name: String in theme.get_icon_list(type_name):
			var tex: Texture2D = theme.get_icon(item_name, type_name)
			icons[item_name] = tex.resource_path if tex else null
		if not icons.is_empty():
			type_data["icons"] = icons

		result["overrides"][type_name] = type_data

		# Type variations (custom types that extend a base type)
		var base: StringName = theme.get_type_variation_base(type_name)
		if base != StringName():
			result["type_variations"][type_name] = String(base)

	return {"result": result}


## Serialize a StyleBox to a dictionary of key properties.
## StyleBoxFlat exposes bg_color, border widths, corner radii, etc.
## Other StyleBox types just report their class name.
func _serialize_stylebox(sb: StyleBox) -> Dictionary:
	if sb == null:
		return {"type": "null"}
	var data: Dictionary = {"type": sb.get_class()}
	if sb is StyleBoxFlat:
		data["bg_color"] = sb.bg_color.to_html(true)
		data["border_width_left"] = sb.border_width_left
		data["border_width_right"] = sb.border_width_right
		data["border_width_top"] = sb.border_width_top
		data["border_width_bottom"] = sb.border_width_bottom
		data["corner_radius_top_left"] = sb.corner_radius_top_left
		data["corner_radius_top_right"] = sb.corner_radius_top_right
		data["corner_radius_bottom_left"] = sb.corner_radius_bottom_left
		data["corner_radius_bottom_right"] = sb.corner_radius_bottom_right
		data["content_margin_left"] = sb.content_margin_left
		data["content_margin_right"] = sb.content_margin_right
		data["content_margin_top"] = sb.content_margin_top
		data["content_margin_bottom"] = sb.content_margin_bottom
	return data


## Create a resource from template or default values.
func _create_from_template(params: Dictionary) -> Dictionary:
	var type: String = params.get("type", "")
	var template: String = params.get("template", "")
	var path: String = params.get("path", "")
	if type.is_empty():
		return {"error": "Type cannot be empty"}
	if path.is_empty():
		return {"error": "Path cannot be empty"}
	if not path.begins_with("res://") and not path.begins_with("user://"):
		return {"error": "Path must start with 'res://' or 'user://', got: %s" % path}
	if not ClassDB.class_exists(type):
		return {"error": "Unknown type: %s" % type}
	var res: Resource = null
	if template != "" and FileAccess.file_exists(template):
		var template_res: Resource = ResourceLoader.load(template)
		if template_res:
			res = template_res.duplicate()
	if res == null:
		res = ClassDB.instantiate(type) as Resource
	if res == null:
		return {"error": "Failed to create resource of type: %s" % type}
	MCPCommandHelpers.ensure_dir(path.get_base_dir())
	var err: Error = ResourceSaver.save(res, path)
	if err != OK:
		return {"error": "Failed to save resource: %s" % error_string(err)}
	return {"result": {"type": type, "path": path, "message": "Resource created"}}


## Import a file as a resource.
func _import(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var settings: Dictionary = params.get("settings", {})
	if path.is_empty():
		return {"error": "Path cannot be empty"}
	if not FileAccess.file_exists(path):
		return {"error": "File not found: %s" % path}
	# Apply settings to .import file if provided
	if not settings.is_empty():
		var import_file: String = path + ".import"
		if FileAccess.file_exists(import_file):
			var config: ConfigFile = ConfigFile.new()
			config.load(import_file)
			for key: String in settings:
				var option_key: String = key
				if key.begins_with("params/"):
					option_key = key.substr(7)  # strip params/ prefix
				config.set_value("params", option_key, settings[key])
			config.save(import_file)
	# Trigger reimport via EditorFileSystem
	var fs: EditorFileSystem = _plugin.get_editor_interface().get_resource_filesystem()
	if fs:
		fs.reimport_files(PackedStringArray([path]))
	return {"result": {"path": path, "message": "Resource import triggered"}}


## Get import settings for a resource file.
func _get_import_settings(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path cannot be empty"}
	var import_file: String = path + ".import"
	if not FileAccess.file_exists(import_file):
		return {"error": "No .import file found for: %s" % path}
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(import_file)
	if err != OK:
		return {"error": "Failed to load import file: %s" % error_string(err)}
	var settings: Dictionary = {}
	for section: String in config.get_sections():
		for key: String in config.get_section_keys(section):
			settings["%s/%s" % [section, key]] = config.get_value(section, key)
	return {"result": {"path": path, "settings": settings}}


## Set import settings for a resource file and reimport.
func _set_import_settings(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var settings: Dictionary = params.get("settings", {})
	if path.is_empty():
		return {"error": "Path cannot be empty"}
	var import_file: String = path + ".import"
	if not FileAccess.file_exists(import_file):
		return {"error": "No .import file found for: %s" % path}
	var config: ConfigFile = ConfigFile.new()
	config.load(import_file)

	# Collect existing params for type validation
	var existing_params: Dictionary = {}
	if config.has_section("params"):
		for key: String in config.get_section_keys("params"):
			existing_params[key] = config.get_value("params", key)

	var warnings: Array = []
	for key: String in settings:
		var section: String = "params"
		var option_key: String = key
		# Strip params/ prefix for round-trip compatibility with _get_import_settings
		if key.begins_with("params/"):
			option_key = key.substr(7)  # remove "params/"
		# Type validation: compare with existing value if key is known
		if existing_params.has(option_key):
			var expected_type: int = typeof(existing_params[option_key])
			if typeof(settings[key]) != expected_type:
				warnings.append("Type mismatch for '%s': expected %s, got %s" % [
					option_key, type_string(expected_type), type_string(typeof(settings[key]))
				])
		else:
			# Key not in existing .import — may be unknown/typo
			warnings.append("Unknown option '%s' — not found in existing import settings, may be ignored" % option_key)

		config.set_value(section, option_key, settings[key])
	var err: Error = config.save(import_file)
	if err != OK:
		return {"error": "Failed to save import settings: %s" % error_string(err)}
	# Trigger reimport
	var fs: EditorFileSystem = _plugin.get_editor_interface().get_resource_filesystem()
	if fs:
		fs.reimport_files(PackedStringArray([path]))
	# Verify: read back to confirm what was actually applied
	var verify_result: Dictionary = _get_import_settings({"path": path})
	var applied: Dictionary = {}
	if verify_result.has("result"):
		applied = verify_result["result"].get("settings", {})
	var result: Dictionary = {"path": path, "message": "Import settings updated and reimport triggered"}
	if not warnings.is_empty():
		result["warnings"] = warnings
	result["applied"] = applied
	return {"result": result}



