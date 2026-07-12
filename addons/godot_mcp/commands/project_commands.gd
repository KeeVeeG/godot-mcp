## Project commands module - 8 tools.
## Handles project info, filesystem, settings, and UID operations.
@tool
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
		"project/remove_setting": func(params: Dictionary) -> Dictionary: return execute("remove_project_setting", params),
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
		"remove_project_setting": return _remove_project_setting(params)
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
	if not path.begins_with("res://") and not path.begins_with("user://"):
		return {"success": false, "error": "Path must start with 'res://' or 'user://', got: " + path}
	if not DirAccess.dir_exists_absolute(path):
		return {"success": false, "error": "Directory not found: " + path}
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
					var filter_ext: String = (f as String).to_lower().lstrip(".")
					if ext == filter_ext:
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
## Supports glob patterns (*, ?) for filename search. Content search reads inside text files.
func _search_files(params: Dictionary) -> Dictionary:
	var query: String = params.get("query", "").to_lower()
	if query.is_empty():
		return {"success": false, "error": "Query cannot be empty"}
	var search_content: bool = params.get("search_content", true)
	var max_results: int = params.get("max_results", 50)
	var results: Array = []
	# Support glob patterns (*, ?) by converting to regex
	var regex: RegEx = null
	if query.contains("*") or query.contains("?"):
		var regex_str: String = "^" + query.replace(".", "\\.").replace("*", ".*").replace("?", ".") + "$"
		regex = RegEx.new()
		regex.compile(regex_str)
	_search_recursive("res://", query, regex, results, 0, 8, search_content, max_results)
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
					results.append({"path": full_path, "type": "directory", "match_type": "name"})
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
				var entry: Dictionary = {"path": full_path, "type": "file", "name": file_name, "match_type": "name" if name_match else "content"}
				results.append(entry)
		file_name = dir.get_next()
	dir.list_dir_end()


## Helper: Check if a text file's content contains the query string.
func _file_content_matches(file_path: String, query: String) -> bool:
	var ext: String = file_path.get_extension().to_lower()
	# Only search text-based files (avoid large binaries)
	if ext not in ["gd", "tscn", "tres", "res", "cfg", "json", "txt", "md", "cs", "shader", "gdshader", "import", "theme", "etf", "resource", "editor", "godot", "rml", "svg", "html", "xml", "css", "ini", "toml", "yaml", "yml"]:
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
	if filter_prefix.contains("*") or filter_prefix.contains("?"):
		return {"success": false, "error": "Wildcards (*, ?) are not supported in filter. Use an exact prefix (e.g. 'application/')."}
	var max_results: int = params.get("max_results", 0)
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
			if max_results > 0 and count >= max_results:
				truncated = true
				break
	var result: Dictionary = {"success": true, "settings": settings}
	if truncated:
		result["truncated"] = true
		result["message"] = "Results limited to %d entries. Use 'filter' param to narrow results." % max_results
	return result


## Set a project setting and save.
## Null values are rejected — use remove_project_setting to delete a setting.
## For registered settings, validates value type against the expected Godot type.
## Custom settings (not in property_list) are allowed with any type.
func _set_project_setting(params: Dictionary) -> Dictionary:
	var key: String = params.get("key", "")
	if key.is_empty():
		return {"success": false, "error": "Key cannot be empty"}
	if not params.has("value"):
		return {"success": false, "error": "Missing required parameter: 'value'"}
	var value: Variant = params.get("value", null)
	if MCPCommandHelpers.is_null(value):
		return {"success": false, "error": "value cannot be null. Use remove_project_setting to delete a setting."}

	# Validate type for registered settings — prevents silent string-to-number mismatches
	var expected_type: int = TYPE_NIL
	for p: Dictionary in ProjectSettings.get_property_list():
		if p["name"] == key:
			expected_type = p["type"] as int
			break
	if expected_type != TYPE_NIL:
		# Coerce String values (from JSON bridge serialization) to expected type
		if typeof(value) == TYPE_STRING:
			var str_val: String = value as String
			match expected_type:
				TYPE_INT:
					if str_val.is_valid_int():
						value = str_val.to_int()
				TYPE_FLOAT:
					if str_val.is_valid_float():
						value = str_val.to_float()
				TYPE_BOOL:
					var lower: String = str_val.to_lower()
					if lower == "true" or lower == "1":
						value = true
					elif lower == "false" or lower == "0":
						value = false

		# Coerce JSON float to int when setting expects int (JSON has no integer type)
		if expected_type == TYPE_INT and typeof(value) == TYPE_FLOAT:
			var f: float = value as float
			if f == floor(f):
				value = int(f)
			else:
				return {"success": false, "error": "Type mismatch for '%s': expected int, but got float %s (has fractional part). Use integer values for this setting." % [key, str(f)]}
		# Validate type matches
		elif expected_type == TYPE_BOOL and (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT):
			# Allow 0/1 as boolean
			value = bool(value)
		elif typeof(value) != expected_type:
			return {"success": false, "error": "Type mismatch for '%s': expected %s, got %s" % [key, _type_name(expected_type), _type_name(typeof(value))]}

	ProjectSettings.set_setting(key, value)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save project settings: %s" % error_string(err)}
	return {"success": true, "message": "Setting '%s' saved" % key}


## Remove a project setting from project.godot.
## Use this instead of passing null to set_project_setting.
func _remove_project_setting(params: Dictionary) -> Dictionary:
	var key: String = params.get("key", "")
	if key.is_empty():
		return {"success": false, "error": "key is required"}
	if not ProjectSettings.has_setting(key):
		return {"success": false, "error": "Setting not found: %s" % key}
	
	# Distinguish built-in vs custom by whether there's a default to revert to.
	# property_can_revert() is unreliable — it returns true for custom settings too.
	# property_get_revert() returns null for custom settings, non-null for built-in.
	var default_value: Variant = ProjectSettings.property_get_revert(key)
	if default_value != null:
		# Built-in setting: revert to engine default
		ProjectSettings.set_setting(key, default_value)
		var err: Error = ProjectSettings.save()
		if err != OK:
			return {"success": false, "error": "Failed to save: %s" % error_string(err)}
		return {"success": true, "key": key, "message": "Setting '%s' reverted to default" % key}
	
	# Custom/user-added setting: fully delete the override
	ProjectSettings.set_setting(key, null)
	var err2: Error = ProjectSettings.save()
	if err2 != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err2)}
	return {"success": true, "key": key, "message": "Setting '%s' removed" % key}


## Convert uid:// to res:// path.
## Uses ResourceUID.uid_to_path() static convenience method.
func _uid_to_project_path(params: Dictionary) -> Dictionary:
	var uid_str: String = params.get("uid", "")
	if uid_str.is_empty():
		return {"success": false, "error": "UID cannot be empty"}
	if not uid_str.to_lower().begins_with("uid://"):
		return {"success": false, "error": "Malformed UID: %s. UID must start with 'uid://' prefix." % uid_str}
	var path: String = ResourceUID.uid_to_path(uid_str)
	if path.is_empty() or path == uid_str:
		return {"success": false, "error": "UID not found: %s. Ensure the resource file exists in the project." % uid_str}
	return {"success": true, "uid": uid_str, "path": path}


## Convert res:// path to uid://.
## Uses ResourceUID.path_to_uid() static convenience method.
func _project_path_to_uid(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"success": false, "error": "Path cannot be empty"}
	if not path.begins_with("res://"):
		return {"success": false, "error": "Path must start with 'res://', got: '%s'. Use resource paths like 'res://scenes/main.tscn'" % path}
	# Special case: project.godot is a config file, not a resource — it has no UID
	if path == "res://project.godot":
		return {"success": false, "error": "project.godot is a configuration file, not a resource — it has no UID"}
	var uid_str: String = ResourceUID.path_to_uid(path)
	if uid_str == path:
		# path_to_uid returns the original path when no UID is found
		return {"success": false, "error": "No UID for path: %s. The file may not be indexed — ensure it exists in the project and the editor has scanned it." % path}
	return {"success": true, "path": path, "uid": uid_str}


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
