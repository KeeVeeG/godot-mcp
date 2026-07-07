## Shared helper functions for command modules.
## Replaces duplicate implementations across 8+ modules.
class_name MCPCommandHelpers
extends RefCounted


## Check if an object has a property by name.
static func has_property(obj: Object, prop: String) -> bool:
	for p: Dictionary in obj.get_property_list():
		if p["name"] as String == prop:
			return true
	return false


## Get the Variant type of a property. Returns TYPE_NIL if not found.
static func get_property_type(obj: Object, prop: String) -> int:
	for p: Dictionary in obj.get_property_list():
		if p["name"] as String == prop:
			return p["type"] as int
	return TYPE_NIL


## Ensure a directory exists, creating it recursively if needed.
static func ensure_dir(path: String) -> void:
	if path.is_empty() or DirAccess.dir_exists_absolute(path):
		return
	DirAccess.make_dir_recursive_absolute(path)


## Return the currently edited scene root node, or null.
static func get_scene_root(plugin: EditorPlugin) -> Node:
	if plugin == null:
		return null
	return plugin.get_editor_interface().get_edited_scene_root()

## Alias kept for backwards compatibility.
static func get_edited_scene_root(plugin: EditorPlugin) -> Node:
	return get_scene_root(plugin)

## Resolve a node path relative to the scene root.
## Empty or "." path returns the root itself.
static func resolve_node_path(plugin: EditorPlugin, path: String) -> Node:
	var root: Node = get_scene_root(plugin)
	if root == null:
		return null
	if path.is_empty() or path == ".":
		return root
	return root.get_node_or_null(path)


## Recursively count all child nodes.
static func count_nodes(node: Node) -> int:
	var count: int = 1
	for child in node.get_children():
		count += count_nodes(child)
	return count


## Recursively find first node of given class.
static func find_node_by_class(start: Node, class_name: String) -> Node:
	if start.get_class() == class_name:
		return start
	for child in start.get_children():
		var found := find_node_by_class(child, class_name)
		if found != null:
			return found
	return null


## Find audio bus index by name. Returns -1 if not found.
static func find_bus_index(bus_name: String) -> int:
	for i in AudioServer.get_bus_count():
		if AudioServer.get_bus_name(i) == bus_name:
			return i
	return -1


## Walk directory recursively, calling callback for each file matching extension.
## callback: func(path: String, file_name: String) -> void
static func walk_directory(dir_path: String, extensions: PackedStringArray, callback: Callable) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue
		var full_path := dir_path.path_join(file_name)
		if dir.current_is_dir():
			walk_directory(full_path, extensions, callback)
		else:
			for ext in extensions:
				if file_name.get_extension().to_lower() == ext.to_lower():
					callback.call(full_path, file_name)
					break
		file_name = dir.get_next()
	dir.list_dir_end()


## Compare actual vs expected with operator. Returns true/false.
static func compare_values(actual: Variant, expected: Variant, operator: String) -> bool:
	match operator:
		">":
			if actual is float or actual is int:
				return actual > float(expected)
		"<":
			if actual is float or actual is int:
				return actual < float(expected)
		">=":
			if actual is float or actual is int:
				return actual >= float(expected)
		"<=":
			if actual is float or actual is int:
				return actual <= float(expected)
		"==", _:
			var a_str: String = str(actual)
			var e_str: String = str(expected)
			return a_str == e_str
	return false


## Validate resource path. Blocks traversal, allows res://
static func validate_path(path: String) -> bool:
	if path.is_empty():
		return false
	# Allow res:// prefix before checking for //
	var check_path: String = path
	if check_path.begins_with("res://"):
		check_path = check_path.substr(6)
	if check_path.contains("//") or check_path.contains(".."):
		return false
	return true


## Recursively copy a directory.
static func copy_directory_recursive(source_path: String, target_path: String) -> int:
	var source_dir := DirAccess.open(source_path)
	if source_dir == null:
		return ERR_CANT_OPEN
	if not DirAccess.dir_exists_absolute(target_path):
		DirAccess.make_dir_recursive_absolute(target_path)
	var err: Error = OK
	source_dir.list_dir_begin()
	var file_name := source_dir.get_next()
	while not file_name.is_empty():
		if file_name == "." or file_name == "..":
			file_name = source_dir.get_next()
			continue
		if source_dir.current_is_dir():
			err = copy_directory_recursive(
				source_path.path_join(file_name),
				target_path.path_join(file_name)
			)
		else:
			err = DirAccess.copy_absolute(
				source_path.path_join(file_name),
				target_path.path_join(file_name)
			)
		if err != OK:
			source_dir.list_dir_end()
			return err
		file_name = source_dir.get_next()
	source_dir.list_dir_end()
	return OK
