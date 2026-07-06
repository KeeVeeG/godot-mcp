## Resource commands module - 6 tools.
## Handles resource CRUD, previews, and autoloads.
class_name MCPResourceCommands
extends RefCounted

var _plugin: EditorPlugin
var _undo_helper: MCUndoHelper


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin
	if _plugin.has_method("get_undo_helper"):
		_undo_helper = _plugin.get_undo_helper()


func get_commands() -> Dictionary:
	return {
		"resource/read": read_resource,
		"resource/edit": edit_resource,
		"resource/create": create_resource,
		"resource/get_preview": get_resource_preview,
		"resource/add_autoload": add_autoload,
		"resource/remove_autoload": remove_autoload,
		"resource/duplicate": duplicate_resource,
		"resource/get_dependencies": get_resource_dependencies,
		"resource/list": list_resources,
		"resource/delete": delete_resource_file,
	}


## Read a .tres/.res resource's properties.
func read_resource(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	var path_err: String = _validate_path(path)
	if not path_err.is_empty():
		return {"error": path_err}
	if not FileAccess.file_exists(path):
		return {"error": "Resource not found: %s" % path}

	var res: Resource = ResourceLoader.load(path)
	if res == null:
		return {"error": "Failed to load resource: %s" % path}

	var props: Dictionary = {}
	for p: Dictionary in res.get_property_list():
		var pname: String = p["name"] as String
		var usage: int = p["usage"] as int
		if usage & PROPERTY_USAGE_STORAGE == 0:
			continue
		if pname.begins_with("resource_") or pname.begins_with("script"):
			continue
		var val: Variant = res.get(pname)
		if val != null:
			props[pname] = MCPVariantCodec.serialize_value(val)

	return {"result": {"path": path, "type": res.get_class(), "properties": props}}


## Edit properties on a resource.
func edit_resource(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var properties: Dictionary = params.get("properties", {})
	if path.is_empty():
		return {"error": "Path is required"}
	var res: Resource = ResourceLoader.load(path)
	if res == null:
		return {"error": "Resource not found: %s" % path}

	for prop: String in properties:
		var val: Variant = properties[prop]
		# Try to parse for the correct type
		for p: Dictionary in res.get_property_list():
			if p["name"] as String == prop:
				val = MCPVariantCodec.parse_for_property(val, p["type"] as int)
				break
		if _undo_helper:
			_undo_helper.set_property_with_undo(res, prop, val)
		else:
			res.set(prop, val)

	_ensure_dir(path.get_base_dir())
	var err: Error = ResourceSaver.save(res, path)
	if err != OK:
		return {"error": "Failed to save resource: %s" % error_string(err)}
	return {"result": "Resource updated: %s" % path}


## Create a new resource.
func create_resource(params: Dictionary) -> Dictionary:
	var type_name: String = params.get("resource_type", params.get("type", ""))
	var path: String = params.get("path", "")
	var properties: Dictionary = params.get("properties", {})
	if type_name.is_empty() or path.is_empty():
		return {"error": "type and path are required"}
	var path_err: String = _validate_path(path)
	if not path_err.is_empty():
		return {"error": path_err}

	var res: Resource = null
	match type_name:
		"StandardMaterial3D":
			res = StandardMaterial3D.new()
		"ShaderMaterial":
			res = ShaderMaterial.new()
		"Theme":
			res = Theme.new()
		"StyleBoxFlat":
			res = StyleBoxFlat.new()
		"Gradient":
			res = Gradient.new()
		"Curve":
			res = Curve.new()
		"AudioStreamMP3":
			res = AudioStreamMP3.new()
		"AudioStreamOggVorbis":
			res = AudioStreamOggVorbis.new()
		"TileSet":
			res = TileSet.new()
		"AnimationLibrary":
			res = AnimationLibrary.new()
		_:
			if ClassDB.can_instantiate(type_name):
				var obj: Object = ClassDB.instantiate(type_name)
				if obj is Resource:
					res = obj as Resource
	if res == null:
		return {"error": "Unknown resource type: %s" % type_name}

	for prop: String in properties:
		if _has_property(res, prop):
			res.set(prop, properties[prop])

	if not path.ends_with(".tres"):
		path += ".tres"
	_ensure_dir(path.get_base_dir())
	var err: Error = ResourceSaver.save(res, path)
	if err != OK:
		return {"error": "Failed to save resource: %s" % error_string(err)}
	_plugin.safe_scan_filesystem()
	return {"result": {"path": path, "type": type_name}}


## Get a resource preview/thumbnail.
func get_resource_preview(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	# Return resource info
	var res: Resource = ResourceLoader.load(path)
	if res == null:
		return {"error": "Resource not found: %s" % path}

	return {"result": {
		"path": path,
		"type": res.get_class(),
		"resource_path": res.resource_path,
	}}


## Add an autoload to the project.
func add_autoload(params: Dictionary) -> Dictionary:
	var name_str: String = params.get("name", "")
	var path: String = params.get("path", "")
	if name_str.is_empty() or path.is_empty():
		return {"error": "name and path are required"}
	if not FileAccess.file_exists(path):
		return {"error": "Script/scene not found: %s" % path}

	# Use the autoload name as the key (Godot standard format)
	# Strip existing * prefix to avoid double-prefixing
	if path.begins_with("*"):
		path = path.substr(1)
	var editor_only: bool = params.get("editor_only", false)
	var value: String = ("*" + path) if editor_only else path
	ProjectSettings.set_setting("autoload/" + name_str, value)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"error": "Failed to save project settings: %s" % error_string(err)}
	return {"result": "Autoload '%s' added" % name_str}


## Remove an autoload from the project.
func remove_autoload(params: Dictionary) -> Dictionary:
	var name_str: String = params.get("name", "")
	if name_str.is_empty():
		return {"error": "name is required"}

	# Find the autoload by name (Godot standard format: autoload/Name)
	var found_key: String = "autoload/" + name_str
	if not ProjectSettings.has_setting(found_key):
		return {"error": "Autoload not found: %s" % name_str}

	ProjectSettings.set_setting(found_key, null)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"error": "Failed to save project settings: %s" % error_string(err)}
	return {"result": "Autoload '%s' removed" % name_str}


## Duplicate a resource file to a new path.
func duplicate_resource(params: Dictionary) -> Dictionary:
	var source_path: String = params.get("source_path", params.get("path", ""))
	var new_path: String = params.get("dest_path", params.get("new_path", ""))
	if source_path.is_empty() or new_path.is_empty():
		return {"error": "source_path and new_path are required"}
	var path_err: String = _validate_path(source_path)
	if not path_err.is_empty():
		return {"error": "source: " + path_err}
	path_err = _validate_path(new_path)
	if not path_err.is_empty():
		return {"error": "dest: " + path_err}
	if not FileAccess.file_exists(source_path):
		return {"error": "Source resource not found: %s" % source_path}
	var res: Resource = ResourceLoader.load(source_path)
	if res == null:
		return {"error": "Failed to load resource: %s" % source_path}
	var dup: Resource = res.duplicate()
	if dup == null:
		return {"error": "Failed to duplicate resource"}
	_ensure_dir(new_path.get_base_dir())
	var err: Error = ResourceSaver.save(dup, new_path)
	if err != OK:
		return {"error": "Failed to save duplicate: %s" % error_string(err)}
	_plugin.safe_scan_filesystem()
	return {"result": {"source": source_path, "path": new_path}}


## Get dependencies of a resource file.
func get_resource_dependencies(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	if not FileAccess.file_exists(path):
		return {"error": "Resource not found: %s" % path}
	var deps: PackedStringArray = ResourceLoader.get_dependencies(path)
	var result: Array = []
	for dep: String in deps:
		var dep_path: String = dep
		if dep.contains("::"):
			dep_path = dep.substr(0, dep.find("::"))
		if dep.contains(":") and not dep.begins_with("res://"):
			var colon_pos: int = dep.find(":")
			dep_path = dep.substr(colon_pos + 1)
		if not dep_path.is_empty():
			result.append(dep_path)
	return {"result": {"path": path, "dependencies": result, "count": result.size()}}


## List resources of a specific type in the project.
func list_resources(params: Dictionary) -> Dictionary:
	var type_filter: String = params.get("type", "")
	var path: String = params.get("directory", params.get("path", "res://"))
	var files: Array = []
	_collect_resource_files(path, files)
	if not type_filter.is_empty():
		var filtered: Array = []
		for f: String in files:
			# Use ResourceLoader.get_resource_type() to check type without loading
			var res_type: String = ResourceLoader.get_resource_type(f)
			if res_type != "" and (res_type == type_filter or ClassDB.is_parent_class(res_type, type_filter)):
				filtered.append(f)
		files = filtered
	return {"result": {"resources": files, "count": files.size(), "type_filter": type_filter}}


## Helper: recursively collect resource files.
func _collect_resource_files(dir_path: String, results: Array) -> void:
	var global_path: String = ProjectSettings.globalize_path(dir_path) if dir_path.begins_with("res://") else dir_path
	var dir: DirAccess = DirAccess.open(global_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not file_name.begins_with("."):
			var full_path: String = dir_path.path_join(file_name)
			if dir.current_is_dir():
				if file_name != ".godot" and file_name != ".import":
					_collect_resource_files(full_path, results)
			elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
				results.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()


## Delete a resource file from the project.
func delete_resource_file(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"success": false, "error": "Path is required"}
	var path_err: String = _validate_path(path)
	if not path_err.is_empty():
		return {"success": false, "error": path_err}
	if not (path.ends_with(".tres") or path.ends_with(".res")):
		return {"success": false, "error": "Not a valid resource file. Only .tres and .res files can be deleted."}
	if not FileAccess.file_exists(path):
		return {"success": false, "error": "Resource not found: %s" % path}
	
	# Check if resource is used in the current scene
	var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
	if root:
		var refs: Array = _find_resource_refs_in_scene(root, path, 0, 20)
		if not refs.is_empty():
			return {"success": false, "error": "Resource is used by nodes: %s. Remove references first." % str(refs)}
	
	# Convert res:// to global path for DirAccess
	var global_path: String = ProjectSettings.globalize_path(path)
	var err: Error = DirAccess.remove_absolute(global_path)
	if err != OK:
		return {"success": false, "error": "Failed to delete resource: %s" % error_string(err)}
	
	# Also delete .import file if exists
	var import_path: String = global_path + ".import"
	if FileAccess.file_exists(import_path):
		DirAccess.remove_absolute(import_path)
	
	# Also delete .uid file if exists
	var uid_path: String = global_path + ".uid"
	if FileAccess.file_exists(uid_path):
		DirAccess.remove_absolute(uid_path)
	
	_plugin.safe_scan_filesystem()
	return {"success": true, "deleted": path}


## Helper: find nodes that reference a specific resource path.
func _find_resource_refs_in_scene(node: Node, resource_path: String, depth: int = 0, max_depth: int = 20) -> Array:
	var result: Array = []
	if depth >= max_depth:
		return result
	# Check all properties for resource references
	for p: Dictionary in node.get_property_list():
		var usage: int = p["usage"] as int
		if usage & PROPERTY_USAGE_STORAGE == 0:
			continue
		var val: Variant = node.get(p["name"] as String)
		if val is Resource and val.resource_path == resource_path:
			result.append(node.get_path())
			break
	for child in node.get_children():
		result.append_array(_find_resource_refs_in_scene(child, resource_path, depth + 1, max_depth))
	return result


func _has_property(obj: Object, prop: String) -> bool:
	for p: Dictionary in obj.get_property_list():
		if p["name"] as String == prop:
			return true
	return false


func _ensure_dir(path: String) -> void:
	if path.is_empty() or DirAccess.dir_exists_absolute(path):
		return
	DirAccess.make_dir_recursive_absolute(path)


## Validate path to prevent path traversal attacks.
## Returns empty string if valid, error message if invalid.
func _validate_path(path: String) -> String:
	if path.is_empty():
		return ""
	if path.contains(".."):
		return "Invalid path: path traversal ('..') not allowed"
	if path.contains("//") and not path.begins_with("res://"):
		return "Invalid path: double slash '//' not allowed"
	return ""
