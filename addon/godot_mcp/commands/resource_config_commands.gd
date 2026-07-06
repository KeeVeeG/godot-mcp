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


## Create a resource from template or default values.
func _create_from_template(params: Dictionary) -> Dictionary:
	var type: String = params.get("type", "")
	var template: String = params.get("template", "")
	var path: String = params.get("path", "")
	if type.is_empty():
		return {"error": "Type cannot be empty"}
	if path.is_empty():
		return {"error": "Path cannot be empty"}
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
				var parts: PackedStringArray = key.split("/")
				if parts.size() == 2:
					config.set_value(parts[0], parts[1], settings[key])
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
	for key: String in settings:
		var parts: PackedStringArray = key.split("/")
		if parts.size() == 2:
			config.set_value(parts[0], parts[1], settings[key])
	var err: Error = config.save(import_file)
	if err != OK:
		return {"error": "Failed to save import settings: %s" % error_string(err)}
	# Trigger reimport
	var fs: EditorFileSystem = _plugin.get_editor_interface().get_resource_filesystem()
	if fs:
		fs.reimport_files(PackedStringArray([path]))
	return {"result": {"path": path, "message": "Import settings updated and reimport triggered"}}


func _ensure_dir(path: String) -> void:
	MCPCommandHelpers.ensure_dir(path)
