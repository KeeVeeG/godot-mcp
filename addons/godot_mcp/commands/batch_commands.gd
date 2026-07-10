## Batch commands module - 10 tools.
## Handles cross-scene queries, batch operations, and dependency analysis.
class_name MCPBatchCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func get_commands() -> Dictionary:
	return {
		"batch/find_by_type": find_nodes_by_type,
		"batch/find_connections": find_signal_connections,
		"batch/set_property": batch_set_property,
		"batch/find_references": find_node_references,
		"batch/get_dependencies": get_scene_dependencies,
		"batch/cross_scene_set": cross_scene_set_property,
		"batch/find_script_refs": find_script_references,
		"batch/detect_circular": detect_circular_dependencies,
		"batch/get_property": batch_get_property,
		"batch/cross_scene_get": cross_scene_get_property,
	}


## Recursively walk the scene tree and find all nodes matching a given type.
func find_nodes_by_type(params: Dictionary) -> Dictionary:
	var type_name: String = params.get("type_name", params.get("type", ""))
	var include_inactive: bool = params.get("include_inactive", false)

	if type_name.is_empty():
		return {"error": "Type is required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var results: Array = []
	_find_by_type_recursive(root, type_name, include_inactive, results)
	return {"result": {"type": type_name, "count": results.size(), "nodes": results}}


func _find_by_type_recursive(node: Node, type_name: String, include_inactive: bool, results: Array) -> void:
	if not include_inactive and node.has_method("is_visible_in_tree") and not node.is_visible_in_tree():
		for child: Node in node.get_children():
			_find_by_type_recursive(child, type_name, include_inactive, results)
		return
	if _node_matches_type(node, type_name):
		results.append({
			"path": MCPCommandHelpers.get_node_path(node, _plugin),
			"name": str(node.name),
			"type": node.get_class(),
		})
	for child: Node in node.get_children():
		_find_by_type_recursive(child, type_name, include_inactive, results)


## Find all signal connections in the scene tree.
## Combines two sources:
## 1. Runtime scan via get_signal_connection_list() — catches ALL active connections
##    (both persistent and non-persistent, including those created by godot_connect_signal).
## 2. SceneState scan — catches persistent connections saved in the .tscn file,
##    including those on nodes that may not be fully instantiated yet.
## Results are deduplicated by (source, signal, target, method).
func find_signal_connections(_params: Dictionary) -> Dictionary:
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var seen: Dictionary = {}
	var connections: Array = []

	# Source 1: Runtime scan — walks the instantiated scene tree and queries
	# each node's signal connections. This catches ALL live connections.
	_collect_runtime_connections(root, connections, seen)

	# Source 2: SceneState scan — reads persistent connections from the .tscn
	# file on disk. These may include connections on nodes not yet instantiated.
	var scene_path: String = root.scene_file_path
	if not scene_path.is_empty():
		var packed: PackedScene = load(scene_path) as PackedScene
		if packed != null:
			var state: SceneState = packed.get_state()
			_collect_state_connections(state, root, connections, seen)

	return {"result": {"count": connections.size(), "connections": connections}}


## Collect signal connections from a SceneState and add to connections array.
## Deduplicates by (source, signal, target, method) key against the seen dictionary.
func _collect_state_connections(state: SceneState, root: Node, connections: Array, seen: Dictionary) -> void:
	var count: int = state.get_connection_count()
	for i: int in range(count):
		var from_path: NodePath = state.get_connection_source(i)
		var signal_name: StringName = state.get_connection_signal(i)
		var to_path: NodePath = state.get_connection_target(i)
		var method_name: StringName = state.get_connection_method(i)
		var flags: int = state.get_connection_flags(i)

		# Resolve source node relative to the instantiated scene root for a user-friendly path
		var source_node: Node = root.get_node_or_null(from_path)
		var source_path: String = MCPCommandHelpers.get_node_path(source_node, _plugin) if source_node != null else str(from_path)

		# Resolve target node
		var target_node: Node = root.get_node_or_null(to_path)
		var target_path: String = MCPCommandHelpers.get_node_path(target_node, _plugin) if target_node != null else str(to_path)

		# Check if this connection will be saved (CONNECT_PERSIST flag).
		const CONNECT_PERSIST: int = 2
		var sig_str: String = str(signal_name)
		var method_str: String = str(method_name)

		# Deduplicate by (source, signal, target, method)
		var key: String = "%s|%s|%s|%s" % [source_path, sig_str, target_path, method_str]
		if seen.has(key):
			continue
		seen[key] = true

		connections.append({
			"source": source_path,
			"signal": sig_str,
			"target": target_path,
			"method": method_str,
			"flags": flags,
			"persistent": (flags & CONNECT_PERSIST) != 0,
		})


## Limits for signal connection scanning to prevent excessive processing.
## Increase these if you need to scan larger scenes.
const MAX_SIGNALS_PER_NODE: int = 500
const MAX_TOTAL_CONNECTIONS: int = 1000


## Collect signal connections from the live scene tree via get_signal_connection_list().
## Deduplicates by (source, signal, target, method) key against the seen dictionary.
## This catches ALL active connections including non-persistent ones created by scripts.
func _collect_runtime_connections(node: Node, connections: Array, seen: Dictionary) -> void:
	if connections.size() >= MAX_TOTAL_CONNECTIONS:
		return
	var signal_list: Array = node.get_signal_list()
	var signals_checked: int = 0
	for sig_info: Dictionary in signal_list:
		if connections.size() >= MAX_TOTAL_CONNECTIONS or signals_checked >= MAX_SIGNALS_PER_NODE:
			break
		signals_checked += 1
		var sig_name: String = sig_info["name"] as String
		var connected: Array = node.get_signal_connection_list(sig_name)
		for conn: Dictionary in connected:
			if connections.size() >= MAX_TOTAL_CONNECTIONS:
				break
			var callable: Callable = conn["callable"] as Callable
			var target: Object = callable.get_object()
			var target_path: String = ""
			var target_method: String = str(callable.get_method())
			# Skip editor-internal signal connections
			if sig_name.begins_with("__") or target_method.begins_with("__"):
				continue
			if target is Node:
				target_path = str((target as Node).get_path())
				# Skip connections to editor-internal nodes
				if target_path.begins_with("/root/@"):
					continue
			var source_path: String = MCPCommandHelpers.get_node_path(node, _plugin)

			# Deduplicate by (source, signal, target, method)
			var key: String = "%s|%s|%s|%s" % [source_path, sig_name, target_path, target_method]
			if seen.has(key):
				continue
			seen[key] = true

			connections.append({
				"source": source_path,
				"signal": sig_name,
				"target": target_path,
				"method": target_method,
			})
	for child: Node in node.get_children():
		if connections.size() >= MAX_TOTAL_CONNECTIONS:
			return
		_collect_runtime_connections(child, connections, seen)


## Find all signal connections in the scene tree.
func batch_set_property(params: Dictionary) -> Dictionary:
	var type_name: String = params.get("type_name", params.get("type", ""))
	var property: String = params.get("property", "")
	var value: Variant = params.get("value")

	if type_name.is_empty():
		return {"error": "Type is required"}
	if property.is_empty():
		return {"error": "Property is required"}
	if not params.has("value"):
		return {"error": "Value is required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	# Pre-validate: check if any nodes of this type exist and the property is valid
	var first_match: Node = _find_first_node_of_type(root, type_name)
	if first_match == null:
		return {"result": {"type": type_name, "property": property, "nodes_modified": 0}}
	if not MCPCommandHelpers.has_property(first_match, property):
		return {"error": "Property '%s' does not exist on %s" % [property, type_name]}

	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Batch set %s.%s" % [type_name, property])
	var count: int = 0
	count = _batch_set_recursive(root, type_name, property, value, count, ur)
	ur.commit_action()
	return {"result": {"type": type_name, "property": property, "nodes_modified": count}}


func _batch_set_recursive(node: Node, type_name: String, property: String, value: Variant, count: int, ur: EditorUndoRedoManager) -> int:
	if _node_matches_type(node, type_name):
		# Property existence already pre-validated in batch_set_property
		var expected_type: int = MCPCommandHelpers.get_property_type(node, property)
		var parsed: Variant = MCPVariantCodec.parse_for_property(value, expected_type)
		var old_val: Variant = node.get(property)
		ur.add_do_method(node, "set", property, parsed)
		ur.add_undo_property(node, property, old_val)
		count += 1
	for child: Node in node.get_children():
		count = _batch_set_recursive(child, type_name, property, value, count, ur)
	return count


## Read a property value from all nodes of a given type in the current scene.
func batch_get_property(params: Dictionary) -> Dictionary:
	var type_name: String = params.get("type_name", params.get("type", ""))
	var property: String = params.get("property", "")

	if type_name.is_empty():
		return {"error": "Type is required"}
	if property.is_empty():
		return {"error": "Property is required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	# Pre-validate: check if any nodes of this type exist and the property is valid
	var first_match: Node = _find_first_node_of_type(root, type_name)
	if first_match == null:
		return {"error": "No nodes of type '%s' found in scene" % type_name}
	if not MCPCommandHelpers.has_property(first_match, property):
		return {"error": "Property '%s' does not exist on %s" % [property, type_name]}

	var results: Array = []
	_batch_get_recursive(root, type_name, property, results)
	return {"result": {"type": type_name, "property": property, "count": results.size(), "nodes": results}}


func _batch_get_recursive(node: Node, type_name: String, property: String, results: Array) -> void:
	if _node_matches_type(node, type_name):
		var value: Variant = node.get(property)
		results.append({
			"path": MCPCommandHelpers.get_node_path(node, _plugin),
			"name": str(node.name),
			"type": node.get_class(),
			"value": value,
		})
	for child: Node in node.get_children():
		_batch_get_recursive(child, type_name, property, results)


## Helper: check if a node matches a given type name, case-insensitively.
## Uses Godot's built-in is_class() for the fast path, then falls back
## to walking the class hierarchy with lowercase comparison.
## This handles inputs like "sprite2d" matching nodes of type "Sprite2D".
func _node_matches_type(node: Node, type_name: String) -> bool:
	if node.is_class(type_name):
		return true
	# Case-insensitive fallback: walk the class hierarchy
	var lower: String = type_name.to_lower()
	var cls: String = node.get_class()
	while cls != "":
		if cls.to_lower() == lower:
			return true
		cls = ClassDB.get_parent_class(cls)
	return false


## Helper: find the first node of a given type in the scene tree.
func _find_first_node_of_type(node: Node, type_name: String) -> Node:
	if _node_matches_type(node, type_name):
		return node
	for child: Node in node.get_children():
		var found: Node = _find_first_node_of_type(child, type_name)
		if found != null:
			return found
	return null


## Search for references to a node name or path across project .tscn and .gd files.
func find_node_references(params: Dictionary) -> Dictionary:
	var search_term: String = params.get("query", params.get("search_term", ""))
	if search_term.is_empty():
		return {"error": "Search term is required"}

	var project_dir: String = ProjectSettings.globalize_path("res://")
	var results: Array = []
	var is_path_search: bool = search_term.contains("/")
	_search_files_recursive(project_dir, search_term, [".tscn", ".gd"], results, is_path_search)
	return {"result": {"search_term": search_term, "matches": results.size(), "files": results}}


## Parse a .tscn file to find all ext_resource dependencies.
func get_scene_dependencies(params: Dictionary) -> Dictionary:
	var scene_path: String = params.get("path", params.get("scene_path", ""))
	if scene_path.is_empty():
		return {"error": "Scene path is required"}

	var full_path: String = scene_path
	if not full_path.begins_with("res://"):
		full_path = "res://" + scene_path

	if not FileAccess.file_exists(full_path):
		return {"error": "Scene file not found: %s" % full_path}

	var file := FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		return {"error": "Cannot open file: %s" % full_path}
	var content: String = file.get_as_text()
	file.close()

	var dependencies: Array = []
	var lines: PackedStringArray = content.split("\n")
	for line: String in lines:
		var trimmed: String = line.strip_edges()
		if trimmed.begins_with("[ext_resource"):
			# Parse ext_resource line: [ext_resource type="..." uid="..." path="..." id="..."]
			var res_path: String = _extract_attr(trimmed, "path")
			var res_type: String = _extract_attr(trimmed, "type")
			var res_id: String = _extract_attr(trimmed, "id")
			dependencies.append({
				"path": res_path,
				"type": res_type,
				"id": res_id,
			})
		elif trimmed.begins_with("[sub_resource"):
			var sub_type: String = _extract_attr(trimmed, "type")
			var sub_id: String = _extract_attr(trimmed, "id")
			dependencies.append({
				"type": sub_type,
				"id": sub_id,
				"sub_resource": true,
			})

	return {"result": {"scene": scene_path, "dependency_count": dependencies.size(), "dependencies": dependencies}}


## Iterate all .tscn scenes in the project and set a property on all matching nodes.
## DESTRUCTIVE: This function modifies .tscn files on disk directly and CANNOT be undone
## via the editor undo system (Ctrl+Z). Changes are best-effort text-based edits that
## may corrupt complex scenes. Use batch/set_property for undoable in-editor changes.
## Requires "confirm_no_undo": true parameter to proceed.
func cross_scene_set_property(params: Dictionary) -> Dictionary:
	var type_name: String = params.get("type_name", params.get("type", ""))
	var property: String = params.get("property", "")
	var value: Variant = params.get("value")
	var confirm_no_undo: bool = params.get("confirm_no_undo", false)

	if type_name.is_empty():
		return {"error": "Type is required"}
	if property.is_empty():
		return {"error": "Property is required"}
	if not confirm_no_undo:
		return {"error": "This operation is DESTRUCTIVE and bypasses the undo system. Set \"confirm_no_undo\": true to acknowledge that these changes cannot be reversed via Ctrl+Z.", "hint": "Use batch/set_property for undoable in-scene changes."}

	var scene_files: Array = []
	MCPCommandHelpers.walk_directory("res://", PackedStringArray(["tscn"]), func(path, _name): scene_files.append(path))
	var modified_scenes: Array = []

	for scene_path_variant: Variant in scene_files:
		var scene_path: String = scene_path_variant as String
		var modified: bool = _modify_scene_file(scene_path, type_name, property, value)
		if modified:
			modified_scenes.append(scene_path)

	var result: Dictionary = {"type": type_name, "property": property, "scenes_modified": modified_scenes.size(), "scenes": modified_scenes}
	if modified_scenes.size() > 0:
		result["warning"] = "DESTRUCTIVE: These .tscn files were modified on disk directly. Changes CANNOT be undone via the editor undo system (Ctrl+Z). This is a best-effort text-based edit — complex scenes with sub-resources or inherited scenes may be corrupted. Use batch/set_property for undoable in-scene changes."
	return {"result": result}


## Read a property value from nodes of a given type across all .tscn files on disk.
## This is a read-only operation — no files are modified.
func cross_scene_get_property(params: Dictionary) -> Dictionary:
	var type_name: String = params.get("type_name", params.get("type", ""))
	var property: String = params.get("property", "")

	if type_name.is_empty():
		return {"error": "Type is required"}
	if property.is_empty():
		return {"error": "Property is required"}

	var scene_files: Array = []
	MCPCommandHelpers.walk_directory("res://", PackedStringArray(["tscn"]), func(path, _name): scene_files.append(path))
	var all_results: Array = []

	for scene_path_variant: Variant in scene_files:
		var scene_path: String = scene_path_variant as String
		var scene_results: Array = _read_scene_property_values(scene_path, type_name, property)
		if scene_results.size() > 0:
			all_results.append({
				"scene": scene_path,
				"nodes": scene_results,
			})

	return {"result": {"type": type_name, "property": property, "scenes_with_matches": all_results.size(), "scenes": all_results}}


## Search for script path references across the project.
func find_script_references(params: Dictionary) -> Dictionary:
	var script_path: String = params.get("script_path", "")
	if script_path.is_empty():
		return {"error": "Script path is required"}

	# Normalize to res:// path for file existence check
	var check_path: String = script_path
	if not check_path.begins_with("res://"):
		check_path = "res://" + script_path
	if not FileAccess.file_exists(check_path):
		return {"error": "Script not found: %s" % check_path, "isError": true}

	var results: Array = []
	_search_files_recursive(
		ProjectSettings.globalize_path("res://"),
		script_path,
		[".tscn", ".gd", ".tres", ".cfg"],
		results
	)
	return {"result": {"script_path": script_path, "references": results.size(), "files": results}}


## Detect circular dependencies among GDScript files in the project.
func detect_circular_dependencies(_params: Dictionary) -> Dictionary:
	var script_files: Array = []
	MCPCommandHelpers.walk_directory("res://", PackedStringArray(["gd"]), func(path, _name): script_files.append(path))
	var graph: Dictionary = {}  # path -> [dependency_paths]
	var errors: Array = []

	# Build dependency graph by parsing each script for preload/load calls
	for path_variant: Variant in script_files:
		var path: String = path_variant as String
		var deps: Array = _extract_script_dependencies(path)
		graph[path] = deps

	# DFS cycle detection
	var visited: Dictionary = {}  # path -> "white"|"gray"|"black"
	var cycles: Array = []
	for path: String in graph:
		visited[path] = "white"

	for path: String in graph:
		if visited[path] == "white":
			var stack: Array = []
			_dfs_cycle(graph, path, visited, stack, cycles)

	return {"result": {"scripts_analyzed": graph.size(), "cycles_found": cycles.size(), "cycles": cycles}}


## Performance monitor data for editor.
func _dfs_cycle(graph: Dictionary, node_path: String, visited: Dictionary, stack: Array, cycles: Array) -> void:
	visited[node_path] = "gray"
	stack.append(node_path)

	var deps: Array = graph.get(node_path, []) as Array
	for dep_variant: Variant in deps:
		var dep: String = dep_variant as String
		if not graph.has(dep):
			continue
		if visited.get(dep, "white") == "gray":
			# Found a cycle: extract it from the stack
			var cycle: Array = []
			var found_start: bool = false
			for s: String in stack:
				if s == dep:
					found_start = true
				if found_start:
					cycle.append(s)
			cycle.append(dep)
			cycles.append(cycle)
		elif visited.get(dep, "white") == "white":
			_dfs_cycle(graph, dep, visited, stack, cycles)

	stack.pop_back()
	visited[node_path] = "black"


## Helper: extract script dependencies (preload/load calls) from a GDScript file.
func _extract_script_dependencies(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var content: String = file.get_as_text()
	file.close()

	var deps: Array = []
	var regex: RegEx = RegEx.new()
	regex.compile("(?:preload|load)\\s*\\(\\s*[\"']([^\"']+)[\"']\\s*\\)")
	var matches: Array[RegExMatch] = regex.search_all(content)
	for m: RegExMatch in matches:
		var dep_path: String = m.get_string(1)
		if dep_path.ends_with(".gd"):
			deps.append(dep_path)
	return deps


## Helper: search files recursively for a text pattern.
## When is_path_search is true, .tscn files are searched using parent= + name= attribute matching.
func _search_files_recursive(dir_path: String, search_term: String, extensions: Array, results: Array, is_path_search: bool = false) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		var full_path: String = dir_path.path_join(file_name)
		if dir.current_is_dir():
			if not file_name.begins_with(".") and file_name != ".godot":
				_search_files_recursive(full_path, search_term, extensions, results, is_path_search)
		else:
			var ext: String = file_name.get_extension()
			if extensions.has("." + ext):
				var found: bool
				if is_path_search and ext == "tscn":
					found = _tscn_contains_node_path(full_path, search_term)
				else:
					found = _file_contains(full_path, search_term)
				if found:
					results.append({
						"path": ProjectSettings.localize_path(full_path),
						"file": file_name,
					})
		file_name = dir.get_next()
	dir.list_dir_end()


## Helper: check if a .tscn file contains a node matching the given path.
## Splits "Player/Sprites/MainSprite" into parent="Player/Sprites" + name="MainSprite"
## and matches against [node ...] header lines.
func _tscn_contains_node_path(file_path: String, node_path: String) -> bool:
	var last_slash: int = node_path.rfind("/")
	var node_name: String
	var parent_path: String
	if last_slash == -1:
		node_name = node_path
		parent_path = ""
	else:
		node_name = node_path.substr(last_slash + 1)
		parent_path = node_path.substr(0, last_slash)

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return false
	var content: String = file.get_as_text()
	file.close()

	for line: String in content.split("\n"):
		var trimmed: String = line.strip_edges()
		if not trimmed.begins_with("[node "):
			continue
		if trimmed.contains('name="' + node_name + '"'):
			if parent_path.is_empty():
				return true
			if trimmed.contains('parent="' + parent_path + '"'):
				return true

	# Also check for literal path in connection lines and other references
	return content.contains(node_path)


## Helper: check if a file contains a search term.
func _file_contains(file_path: String, term: String) -> bool:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return false
	var content: String = file.get_as_text()
	file.close()
	return content.find(term) != -1


## Helper: read property values from nodes of a given type in a .tscn file.
func _read_scene_property_values(scene_path: String, type_name: String, property: String) -> Array:
	if not FileAccess.file_exists(scene_path):
		return []
	var file := FileAccess.open(scene_path, FileAccess.READ)
	if file == null:
		return []
	var content: String = file.get_as_text()
	file.close()

	var results: Array = []
	var lines: PackedStringArray = content.split("\n")
	var in_matching_node: bool = false
	var current_type: String = ""
	var current_name: String = ""
	var current_parent: String = ""
	var prop_value: String = ""
	var prop_found: bool = false

	for line: String in lines:
		var trimmed: String = line.strip_edges()
		if trimmed.begins_with("[node"):
			# Save previous match
			if in_matching_node:
				results.append({
					"name": current_name,
					"parent": current_parent,
					"value": prop_value if prop_found else null,
					"has_property": prop_found,
				})
			in_matching_node = false
			prop_found = false
			prop_value = ""
			current_type = _extract_attr(trimmed, "type")
			current_name = _extract_attr(trimmed, "name")
			current_parent = _extract_attr(trimmed, "parent")
			if current_type == type_name or (current_type.is_empty() and type_name == "Node"):
				in_matching_node = true
		elif trimmed.begins_with("[") and not trimmed.begins_with("[node"):
			# Exiting node section
			if in_matching_node:
				results.append({
					"name": current_name,
					"parent": current_parent,
					"value": prop_value if prop_found else null,
					"has_property": prop_found,
				})
				in_matching_node = false
				prop_found = false

		if in_matching_node and trimmed.begins_with(property + " = "):
			prop_value = trimmed.substr((property + " = ").length())
			prop_found = true

	# Handle last node at end of file
	if in_matching_node:
		results.append({
			"name": current_name,
			"parent": current_parent,
			"value": prop_value if prop_found else null,
			"has_property": prop_found,
		})

	return results


## Helper: modify a .tscn file to set a property on matching nodes.
## Returns true if the file was modified.
func _modify_scene_file(scene_path: String, type_name: String, property: String, value: Variant) -> bool:
	if not FileAccess.file_exists(scene_path):
		return false
	var file := FileAccess.open(scene_path, FileAccess.READ)
	if file == null:
		return false
	var content: String = file.get_as_text()
	file.close()

	var lines: PackedStringArray = content.split("\n")
	var modified: bool = false
	var output: PackedStringArray = PackedStringArray()
	var in_matching_node: bool = false
	var prop_found_in_node: bool = false
	var current_type: String = ""

	for line: String in lines:
		var trimmed: String = line.strip_edges()
		if trimmed.begins_with("[node"):
			# Exiting previous node — insert property if it wasn't found
			if in_matching_node and not prop_found_in_node:
				output.append(property + " = " + _serialize_for_tscn(value))
				modified = true

			in_matching_node = false
			prop_found_in_node = false
			current_type = _extract_attr(trimmed, "type")
			if current_type == type_name or (current_type.is_empty() and type_name == "Node"):
				in_matching_node = true
		elif trimmed.begins_with("[") and not trimmed.begins_with("[node"):
			# Exiting node section — insert property if it wasn't found
			if in_matching_node and not prop_found_in_node:
				output.append(property + " = " + _serialize_for_tscn(value))
				modified = true
			in_matching_node = false
			prop_found_in_node = false

		if in_matching_node and trimmed.begins_with(property + " = "):
			# Replace the property value
			var serialized: String = _serialize_for_tscn(value)
			output.append(property + " = " + serialized)
			prop_found_in_node = true
			modified = true
			continue

		output.append(line)

	# Handle last node at end of file
	if in_matching_node and not prop_found_in_node:
		output.append(property + " = " + _serialize_for_tscn(value))
		modified = true

	if modified:
		var write_file := FileAccess.open(scene_path, FileAccess.WRITE)
		if write_file:
			write_file.store_string("\n".join(output))
			write_file.close()
	return modified


## Helper: extract an attribute value from a Godot scene file line.
func _extract_attr(line: String, attr_name: String) -> String:
	var search: String = attr_name + '="'
	var start: int = line.find(search)
	if start == -1:
		return ""
	start += search.length()
	var end: int = line.find('"', start)
	if end == -1:
		return ""
	return line.substr(start, end - start)


## Helper: serialize a value for .tscn format.
func _serialize_for_tscn(value: Variant) -> String:
	# If value is a String, try to parse it as a Variant constructor
	# (e.g., "Vector2(999, 888)") since JSON doesn't distinguish these types.
	if value is String:
		var s: String = value as String
		var paren: int = s.find("(")
		# Only attempt str_to_var for constructor-like strings (Type(name, ...))
		# where the prefix starts with an uppercase letter (Godot type names).
		if paren != -1 and s.ends_with(")") and s[0] >= "A" and s[0] <= "Z":
			var parsed: Variant = str_to_var(s)
			if parsed != null and typeof(parsed) != TYPE_STRING:
				value = parsed

	if value is bool:
		return "true" if value else "false"
	elif value is int:
		return str(value)
	elif value is float:
		return str(value)
	elif value is String:
		return '"' + (value as String).c_escape() + '"'
	elif value is Vector2:
		var v: Vector2 = value as Vector2
		return "Vector2(%s, %s)" % [str(v.x), str(v.y)]
	elif value is Vector3:
		var v: Vector3 = value as Vector3
		return "Vector3(%s, %s, %s)" % [str(v.x), str(v.y), str(v.z)]
	elif value is Color:
		var c: Color = value as Color
		return "Color(%s, %s, %s, %s)" % [str(c.r), str(c.g), str(c.b), str(c.a)]
	else:
		return str(value)



