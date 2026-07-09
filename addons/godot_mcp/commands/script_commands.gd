## Script commands module - 10 tools.
## Handles script CRUD, validation, and search.
class_name MCPScriptCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


## Router compatibility: returns callable map for MCPCommandRouter.
func get_commands() -> Dictionary:
	return {
		"script/list": func(params: Dictionary) -> Dictionary: return execute("list_scripts", params),
		"script/read": func(params: Dictionary) -> Dictionary: return execute("read_script", params),
		"script/create": func(params: Dictionary) -> Dictionary: return execute("create_script", params),
		"script/delete": func(params: Dictionary) -> Dictionary: return execute("delete_script", params),
		"script/edit": func(params: Dictionary) -> Dictionary: return execute("edit_script", params),
		"script/attach": func(params: Dictionary) -> Dictionary: return execute("attach_script", params),
		"script/get_open": func(params: Dictionary) -> Dictionary: return execute("get_open_scripts", params),
		"script/validate": func(params: Dictionary) -> Dictionary: return execute("validate_script", params),
		"script/search_in_files": func(params: Dictionary) -> Dictionary: return execute("search_in_files", params),
		"script/detach": func(params: Dictionary) -> Dictionary: return execute("detach_script", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"list_scripts": return _list_scripts(params)
		"read_script": return _read_script(params)
		"create_script": return _create_script(params)
		"delete_script": return _delete_script(params)
		"edit_script": return _edit_script(params)
		"attach_script": return _attach_script(params)
		"get_open_scripts": return _get_open_scripts()
		"validate_script": return _validate_script(params)
		"search_in_files": return _search_in_files(params)
		"detach_script": return _detach_script(params)
	return {"error": "Unknown method: " + method}


## List all .gd scripts in the project with class info.
func _list_scripts(params: Dictionary) -> Dictionary:
	var max_depth: int = params.get("max_depth", 10)
	var results: Array = []
	MCPCommandHelpers.walk_directory("res://", PackedStringArray(["gd"]), func(path, name): results.append({"path": path, "name": name}))
	
	# Filter by directory depth: count "/" in path relative to res://
	if max_depth > 0:
		var filtered: Array = []
		for r in results:
			var rel: String = r["path"].trim_prefix("res://")
			if rel.count("/") <= max_depth:
				filtered.append(r)
		results = filtered
	
	return {"result": {"scripts": results, "count": results.size()}}


## Read a script file's content.
func _read_script(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	if not FileAccess.file_exists(path):
		return {"error": "Script not found: %s" % path}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "Cannot read script: %s" % path}
	var content: String = file.get_as_text()
	file.close()
	var line_count: int = content.count("\n") + 1
	return {"result": {"path": path, "content": content, "lines": line_count}}


## Create a new script file with optional template.
func _create_script(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var content: String = params.get("content", "")
	var base_class: String = params.get("base_class", "RefCounted")
	if path.is_empty():
		return {"error": "Path is required"}
	if not path.ends_with(".gd"):
		path += ".gd"

	# Ensure parent directory exists
	var dir_path: String = path.get_base_dir()
	MCPCommandHelpers.ensure_dir(dir_path)

	# Prepend extends line when content is provided without one
	var has_extends: bool = false
	if not content.is_empty():
		for line: String in content.split("\n"):
			if line.strip_edges().begins_with("extends "):
				has_extends = true
				break
	
	if not has_extends and base_class != "RefCounted":
		content = "extends %s\n%s" % [base_class, content]
	
	if content.is_empty():
		var lifecycle_method: String = "_ready"
		# Use _init() for non-Node classes (RefCounted, Resource, etc.)
		if base_class != "Node" and not ClassDB.is_parent_class(base_class, "Node"):
			lifecycle_method = "_init"
		content = "extends %s\n\nfunc %s() -> void:\n\tpass\n" % [base_class, lifecycle_method]

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"error": "Cannot create script: %s" % path}
	file.store_string(content)
	file.close()

	_plugin.safe_scan_filesystem()

	# Infer base_class from content
	var inferred_class: String = base_class
	var lines: PackedStringArray = content.split("\n")
	for line: String in lines:
		var stripped: String = line.strip_edges()
		if stripped.begins_with("extends "):
			var extends_name: String = stripped.trim_prefix("extends ").strip_edges()
			if not extends_name.is_empty():
				inferred_class = extends_name
			break
	return {"result": {"path": path, "base_class": inferred_class}}


## Delete a script file from the project.
func _delete_script(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	if not path.ends_with(".gd"):
		path += ".gd"
	if not FileAccess.file_exists(path):
		return {"error": "Script not found: %s" % path}
	
	# Check if script is currently open in the script editor
	var open_scripts: Array = _get_open_scripts().get("result", {}).get("open_scripts", [])
	for s: Dictionary in open_scripts:
		if s.get("path", "") == path:
			return {"error": "Script is currently open in the script editor. Close it first."}
	
	# Check if script is used by any autoload
	var props: Array = ProjectSettings.get_property_list()
	for p: Dictionary in props:
		var prop_name: String = p.get("name", "")
		if prop_name.begins_with("autoload/"):
			var autoload_name: String = prop_name.trim_prefix("autoload/")
			var autoload_path: String = ProjectSettings.get_setting(prop_name, "") as String
			if autoload_path.begins_with("*"):
				autoload_path = autoload_path.substr(1)
			if autoload_path == path:
				return {"error": "Script is used by autoload '%s'. Remove it first." % autoload_name}
	
	# Check if script is attached to any node in the current scene
	var force: bool = params.get("force", false)
	if not force:
		var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
		if root:
			var attached_nodes: Array = _find_nodes_with_script(root, path, 0, 20)
			if not attached_nodes.is_empty():
				var ref_paths: PackedStringArray = []
				for r in attached_nodes:
					ref_paths.append(str(r))
				return {"error": "Script is attached to %d node(s): %s. Use force=true to delete anyway." % [attached_nodes.size(), ", ".join(ref_paths)]}
	
	var err: Error = DirAccess.remove_absolute(path)
	if err != OK:
		return {"error": "Failed to delete script: %s" % error_string(err)}
	
	_plugin.safe_scan_filesystem()
	return {"result": {"path": path, "message": "Script deleted: %s" % path}}


## Helper: find nodes that use a specific script path.
func _find_nodes_with_script(node: Node, script_path: String, depth: int = 0, max_depth: int = 20) -> Array:
	var result: Array = []
	if depth >= max_depth:
		return result
	var scr = node.get_script()
	if scr and scr.resource_path == script_path:
		result.append(node.get_path())
	for child in node.get_children():
		result.append_array(_find_nodes_with_script(child, script_path, depth + 1, max_depth))
	return result


## Edit a script file using find-and-replace.
func _edit_script(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var old_text: String = params.get("old_text", "")
	var new_text: String = params.get("new_text", "")
	if path.is_empty() or old_text.is_empty():
		return {"error": "Path and old_text are required"}
	if not FileAccess.file_exists(path):
		return {"error": "Script not found: %s" % path}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "Cannot read script: %s" % path}
	var content: String = file.get_as_text()
	file.close()

	var idx: int = content.find(old_text)
	if idx == -1:
		return {"error": "old_text not found in script"}

	var occurrences: int = content.count(old_text)
	content = content.replace(old_text, new_text)

	file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"error": "Cannot write script: %s" % path}
	file.store_string(content)
	file.close()

	_plugin.safe_scan_filesystem()
	return {"result": {"path": path, "replacements": occurrences}}


## Attach a script to a node with UndoRedo support.
func _attach_script(params: Dictionary) -> Dictionary:
	var script_path: String = params.get("script_path", "")
	var node_path: String = params.get("node_path", "")
	if script_path.is_empty():
		return {"error": "script_path is required"}

	var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return {"error": "No scene open"}

	var node: Node
	if node_path.is_empty():
		node = root
	else:
		node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var script: GDScript = ResourceLoader.load(script_path) as GDScript
	if script == null:
		return {"error": "Cannot load script: %s" % script_path}

	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	var old_script: Script = node.get_script()
	ur.create_action("MCP: Attach script %s to %s" % [script_path, node_path])
	ur.add_do_property(node, "script", script)
	if old_script:
		ur.add_undo_property(node, "script", old_script)
	else:
		ur.add_undo_property(node, "script", null)
	ur.commit_action()

	return {"result": {"message": "Script %s attached to %s" % [script_path, node_path]}}


## Detach a script from a node with UndoRedo support (sets script = null).
func _detach_script(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")

	var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return {"error": "No scene open"}

	var node: Node
	if node_path.is_empty():
		node = root
	else:
		node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var old_script: Script = node.get_script()
	if old_script == null:
		return {"error": "Node has no script attached: %s" % node_path}

	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Detach script from %s" % node_path)
	ur.add_do_property(node, "script", null)
	ur.add_undo_property(node, "script", old_script)
	ur.commit_action()

	return {"result": {"message": "Script detached from %s" % node_path}}


## Get all open scripts in the script editor.
func _get_open_scripts() -> Dictionary:
	var editor: ScriptEditor = _plugin.get_editor_interface().get_script_editor()
	var open_scripts: Array = []
	var scripts: Array = editor.get_open_scripts()
	for scr: Script in scripts:
		open_scripts.append({
			"path": scr.resource_path,
			"class_name_str": scr.get_global_name() if scr is GDScript else "",
			"base_class": scr.get_instance_base_type(),
		})
	return {"result": {"open_scripts": open_scripts, "count": open_scripts.size()}}


## Validate a script by reloading it and checking for compilation errors.
## Uses the editor log to extract line/column/message since Script API doesn't expose them.
func _validate_script(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	if not FileAccess.file_exists(path):
		return {"error": "Script not found: %s" % path}

	var script: GDScript = ResourceLoader.load(path) as GDScript
	if script == null:
		return {"result": {"valid": false, "error": "Failed to load script"}}

	# Try reloading to check for errors
	var err: Error = script.reload()
	if err != OK:
		if err == ERR_ALREADY_IN_USE:
			return {"result": {"valid": true, "warning": "Script has live instances, cannot reload while in use"}}
		
		# Attempt to extract error details from the editor log
		var details: Dictionary = _parse_script_error_from_log(path)
		details["valid"] = false
		details["error_code"] = err
		details["error_name"] = error_string(err)
		details["path"] = path
		return {"result": details}

	return {"result": {"valid": true, "path": path, "base_class": script.get_instance_base_type()}}


## Helper: parse the most recent compilation error for a script from the EditorLog panel.
## File logging (enable_file_logging) is off by default and can't be enabled at runtime.
## EditorLog RichTextLabel is always active — plain text format: " ERROR: path:LINE - message"
func _parse_script_error_from_log(script_path: String) -> Dictionary:
	var result: Dictionary = {}
	
	# Access EditorLog RichTextLabel via editor UI tree
	var base: Node = _plugin.get_editor_interface().get_base_control()
	var log_node: Node = MCPCommandHelpers.find_node_by_class(base, "EditorLog")
	if log_node == null or log_node.get_child_count() == 0:
		result["message"] = "Compilation failed. EditorLog not accessible."
		return result
	
	# RichTextLabel is nested inside EditorLog (not always first child)
	var label: RichTextLabel = MCPCommandHelpers.find_node_by_class(log_node, "RichTextLabel") as RichTextLabel
	if label == null:
		result["message"] = "Compilation failed. Cannot read EditorLog."
		return result
	
	# get_parsed_text() walks item tree, strips BBCode — get_text() only returns set_text() data (empty when append_text() is used)
	var content: String = label.get_parsed_text()
	if content.is_empty():
		result["message"] = "Compilation failed. EditorLog is empty."
		return result
	
	# Search only the last ~4000 chars
	if content.length() > 4000:
		content = content.substr(content.length() - 4000)
	
	# EditorLog plain text format: " ERROR: path:LINE - message"
	# (thin space + ERROR: is stripped by strip_edges below)
	var re: RegEx = RegEx.new()
	re.compile("ERROR:\\s*" + MCPCommandHelpers.escape_regex(script_path) + ":(\\d+)\\s*-\\s*(.+)")
	
	var lines: PackedStringArray = content.split("\n")
	for i: int in range(lines.size() - 1, -1, -1):
		var match: RegExMatch = re.search(lines[i].strip_edges())
		if match:
			result["line"] = match.get_string(1).to_int()
			result["message"] = match.get_string(2).strip_edges()
			break
	
	if result.is_empty():
		result["message"] = "Compilation failed. Check Godot output console for details."
	
	return result


## Search for text across files matching a pattern.
func _search_in_files(params: Dictionary) -> Dictionary:
	var query: String = params.get("query", "")
	var file_pattern: String = params.get("file_pattern", "*.gd")
	if query.is_empty():
		return {"error": "Query cannot be empty"}

	var results: Array = []
	_search_text_recursive("res://", query, file_pattern, results, 0, 10)
	return {"result": {"matches": results, "count": results.size()}}


func _search_text_recursive(path: String, query: String, pattern: String, results: Array, depth: int, max_depth: int) -> void:
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
			_search_text_recursive(full_path, query, pattern, results, depth + 1, max_depth)
		else:
			if _matches_pattern(file_name, pattern):
				var file: FileAccess = FileAccess.open(full_path, FileAccess.READ)
				if file:
					var content: String = file.get_as_text()
					file.close()
					var lines: PackedStringArray = content.split("\n")
					for i: int in range(lines.size()):
						if lines[i].find(query) != -1:
							results.append({
								"path": full_path,
								"line": i + 1,
								"content": lines[i].strip_edges(),
							})
		file_name = dir.get_next()
	dir.list_dir_end()


## Helper: check if filename matches a glob-like pattern.
func _matches_pattern(file_name: String, pattern: String) -> bool:
	if pattern == "*":
		return true
	if pattern.begins_with("*"):
		var ext: String = pattern.substr(1)
		return file_name.ends_with(ext)
	return file_name == pattern

