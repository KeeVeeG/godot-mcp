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


## Search files by name or content query.
## Set "search_content": true to search inside file contents (text files only).
func _search_files(params: Dictionary) -> Dictionary:
	var query: String = params.get("query", "").to_lower()
	if query.is_empty():
		return {"success": false, "error": "Query cannot be empty"}
	var search_content: bool = params.get("search_content", false)
	var max_content_results: int = params.get("max_results", 50)
	var results: Array = []
	# Support glob patterns (*, ?) by converting to regex
	var regex: RegEx = null
	if query.contains("*") or query.contains("?"):
		var regex_str: String = "^" + query.replace(".", "\\.").replace("*", ".*").replace("?", ".") + "$"
		regex = RegEx.new()
		regex.compile(regex_str)
	_search_recursive("res://", query, regex, results, 0, 8, search_content, max_content_results)
	return {"success": true, "matches": results, "count": results.size(), "search_content": search_content}


func _search_recursive(path: String, query: String, regex: RegEx, results: Array, depth: int, max_depth: int, search_content: bool = false, max_results: int = 50) -> void:
	if depth >= max_depth or results.size() >= max_results:
		return
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if results.size() >= max_results:
			break
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var full_path: String = path.path_join(file_name)
		if dir.current_is_dir():
			if regex:
				_search_recursive(full_path, query, regex, results, depth + 1, max_depth, search_content, max_results)
			else:
				if file_name.to_lower().find(query) != -1:
					results.append({"path": full_path, "type": "directory"})
				_search_recursive(full_path, query, regex, results, depth + 1, max_depth, search_content, max_results)
		else:
			var name_match: bool = false
			if regex:
				name_match = regex.search(file_name.to_lower()) != null
			else:
				name_match = file_name.to_lower().find(query) != -1
			var content_match: bool = false
			if search_content and not name_match:
				content_match = _file_content_matches(full_path, query)
			if name_match or content_match:
				var entry: Dictionary = {"path": full_path, "type": "file", "name": file_name}
				if content_match and not name_match:
					entry["match_type"] = "content"
				results.append(entry)
		file_name = dir.get_next()
	dir.list_dir_end()


## Helper: Check if a text file's content contains the query string.
func _file_content_matches(file_path: String, query: String) -> bool:
	var ext: String = file_path.get_extension().to_lower()
	# Only search text-based files
	if ext not in ["gd", "tscn", "tres", "cfg", "json", "txt", "md", "cs", "shader", "gdshader", "import"]:
		return false
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return false
	var content: String = file.get_as_text().to_lower()
	file.close()
	return content.find(query) != -1


## Get all project settings, optionally filtered by prefix.
## When no filter is provided, limits results to prevent oversized payloads.
func _get_project_settings(params: Dictionary) -> Dictionary:
	var filter_prefix: String = params.get("filter", "")
	var max_results: int = params.get("max_results", 200)
	var settings: Dictionary = {}
	var count: int = 0
	var truncated: bool = false
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
			count += 1
			if filter_prefix.is_empty() and count >= max_results:
				truncated = true
				break
	var result: Dictionary = {"success": true, "settings": settings}
	if truncated:
		result["truncated"] = true
		result["message"] = "Results limited to %d entries. Use 'filter' param to narrow results." % max_results
	return result


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
## Uses Godot's built-in ResourceUID.text_to_id() for proper decoding.
func _uid_to_project_path(params: Dictionary) -> Dictionary:
	var uid_str: String = params.get("uid", "")
	if uid_str.is_empty():
		return {"success": false, "error": "UID cannot be empty"}
	var uid_value: int = ResourceUID.text_to_id(uid_str)
	if uid_value == ResourceUID.INVALID_ID:
		return {"success": false, "error": "Malformed UID: %s" % uid_str}
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
