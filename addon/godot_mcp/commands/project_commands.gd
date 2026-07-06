## Project commands module - 7 tools.
## Handles project info, filesystem, settings, and UID operations.
class_name MCPProjectCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


## Router compatibility: returns callable map for MCPCommandRouter.
func get_commands() -> Dictionary:
	return {
		"project/get_info": func(params: Dictionary) -> Dictionary: return execute("get_project_info", params),
		"project/get_filesystem_tree": func(params: Dictionary) -> Dictionary: return execute("get_filesystem_tree", params),
		"project/search_files": func(params: Dictionary) -> Dictionary: return execute("search_files", params),
		"project/get_settings": func(params: Dictionary) -> Dictionary: return execute("get_project_settings", params),
		"project/set_setting": func(params: Dictionary) -> Dictionary: return execute("set_project_setting", params),
		"project/uid_to_path": func(params: Dictionary) -> Dictionary: return execute("uid_to_project_path", params),
		"project/path_to_uid": func(params: Dictionary) -> Dictionary: return execute("project_path_to_uid", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_project_info": return _get_project_info()
		"get_filesystem_tree": return _get_filesystem_tree(params)
		"search_files": return _search_files(params)
		"get_project_settings": return _get_project_settings(params)
		"set_project_setting": return _set_project_setting(params)
		"uid_to_project_path": return _uid_to_project_path(params)
		"project_path_to_uid": return _project_path_to_uid(params)
	return {"success": false, "error": "Unknown method: " + method}


## Get project info: name, version, viewport, autoloads.
func _get_project_info() -> Dictionary:
	var config: ConfigFile = ConfigFile.new()
	config.load("res://project.godot")

	var info: Dictionary = {
		"name": ProjectSettings.get_setting("application/config/name", ""),
		"version": ProjectSettings.get_setting("application/config/version", ""),
		"description": ProjectSettings.get_setting("application/config/description", ""),
		"main_scene": ProjectSettings.get_setting("application/run/main_scene", ""),
		"project_path": ProjectSettings.globalize_path("res://"),
		"godot_version": Engine.get_version_info(),
	}

	# Viewport settings
	info["viewport"] = {
		"width": ProjectSettings.get_setting("display/window/size/viewport_width", 1152),
		"height": ProjectSettings.get_setting("display/window/size/viewport_height", 648),
		"stretch_mode": ProjectSettings.get_setting("display/window/stretch/mode", "disabled"),
		"stretch_aspect": ProjectSettings.get_setting("display/window/stretch/aspect", "ignore"),
	}

	# Autoloads — use property list to find all autoload entries
	var autoloads: Dictionary = {}
	var props: Array = ProjectSettings.get_property_list()
	for p: Dictionary in props:
		var prop_name: String = p.get("name", "")
		if prop_name.begins_with("autoload/"):
			var autoload_name: String = prop_name.trim_prefix("autoload/")
			var val: String = ProjectSettings.get_setting(prop_name, "") as String
			var parts: PackedStringArray = val.split("*")
			var autoload_path: String = parts[1] if parts.size() > 1 else parts[0]
			autoloads[autoload_name] = autoload_path
	info["autoloads"] = autoloads

	return {"success": true, "info": info}


## Get filesystem tree recursively.
func _get_filesystem_tree(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "res://")
	var filters: Array = params.get("filters", [])
	var max_depth: int = params.get("max_depth", 10)
	var tree: Dictionary = _build_file_tree(path, filters, 0, max_depth)
	return {"success": true, "tree": tree}


func _build_file_tree(path: String, filters: Array, depth: int, max_depth: int) -> Dictionary:
	var result: Dictionary = {
		"path": path,
		"name": path.get_file(),
		"type": "directory",
		"children": [],
	}
	if depth >= max_depth:
		return result

	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return result

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var full_path: String = path.path_join(file_name)
		if dir.current_is_dir():
			var child: Dictionary = _build_file_tree(full_path, filters, depth + 1, max_depth)
			result["children"].append(child)
		else:
			var ext: String = file_name.get_extension().to_lower()
			var passes_filter: bool = true
			if filters.size() > 0:
				passes_filter = false
				for f: Variant in filters:
					if ext == (f as String).to_lower():
						passes_filter = true
						break
			if passes_filter:
				result["children"].append({
					"path": full_path,
					"name": file_name,
					"type": "file",
					"extension": ext,
				})
		file_name = dir.get_next()
	dir.list_dir_end()
	return result


## Search files by name/content query.
func _search_files(params: Dictionary) -> Dictionary:
	var query: String = params.get("query", "").to_lower()
	if query.is_empty():
		return {"success": false, "error": "Query cannot be empty"}
	var results: Array = []
	_search_recursive("res://", query, results, 0, 8)
	return {"success": true, "matches": results, "count": results.size()}


func _search_recursive(path: String, query: String, results: Array, depth: int, max_depth: int) -> void:
	if depth >= max_depth:
		return
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var full_path: String = path.path_join(file_name)
		if dir.current_is_dir():
			if file_name.to_lower().find(query) != -1:
				results.append({"path": full_path, "type": "directory"})
			_search_recursive(full_path, query, results, depth + 1, max_depth)
		else:
			if file_name.to_lower().find(query) != -1:
				results.append({"path": full_path, "type": "file", "name": file_name})
		file_name = dir.get_next()
	dir.list_dir_end()


## Get all project settings, optionally filtered by prefix.
func _get_project_settings(params: Dictionary) -> Dictionary:
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
	return {"success": true, "settings": settings}


## Set a project setting and save.
func _set_project_setting(params: Dictionary) -> Dictionary:
	var key: String = params.get("key", "")
	var value: Variant = params.get("value")
	if key.is_empty():
		return {"success": false, "error": "Key cannot be empty"}
	ProjectSettings.set_setting(key, value)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save project settings: %s" % error_string(err)}
	return {"success": true, "message": "Setting '%s' saved" % key}


## Convert uid:// to res:// path.
func _uid_to_project_path(params: Dictionary) -> Dictionary:
	var uid_str: String = params.get("uid", "")
	if uid_str.is_empty():
		return {"success": false, "error": "UID cannot be empty"}
	var uid_value: int = -1
	if uid_str.begins_with("uid://"):
		var id_part: String = uid_str.substr(6)
		if id_part.is_empty() or not id_part.is_valid_int():
			return {"success": false, "error": "Malformed UID: %s" % uid_str}
		uid_value = id_part.to_int()
	else:
		if not uid_str.is_valid_int():
			return {"success": false, "error": "Malformed UID: %s" % uid_str}
		uid_value = uid_str.to_int()
	if uid_value < 0:
		return {"success": false, "error": "Invalid UID: %s" % uid_str}
	if not ResourceUID.has_id(uid_value):
		return {"success": false, "error": "UID not found: %s" % uid_str}
	var path: String = ResourceUID.get_id_path(uid_value)
	return {"success": true, "uid": uid_str, "path": path}


## Convert res:// path to uid://.
func _project_path_to_uid(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"success": false, "error": "Path cannot be empty"}
	var uid_value: int = ResourceLoader.get_resource_uid(path)
	if uid_value == -1:
		return {"success": false, "error": "No UID for path: %s" % path}
	var uid_str: String = "uid://%d" % uid_value
	return {"success": true, "path": path, "uid": uid_str}
