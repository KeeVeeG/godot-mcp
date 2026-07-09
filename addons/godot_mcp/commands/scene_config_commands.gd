## Scene configuration commands module - 6 tools.
## Handles scene inheritance, unique names, groups, and metadata.
class_name MCPSceneConfigCommands
extends RefCounted

var _plugin: EditorPlugin
var _undo_helper: MCUndoHelper


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin
	if _plugin.has_method("get_undo_helper"):
		_undo_helper = _plugin.get_undo_helper()


## Router compatibility: returns callable map for MCPCommandRouter.
func get_commands() -> Dictionary:
	return {
		"scene_config/get_inheritance": func(params: Dictionary) -> Dictionary: return execute("get_inheritance", params),
		"scene_config/set_unique_name": func(params: Dictionary) -> Dictionary: return execute("set_unique_name", params),
		"scene_config/get_groups": func(params: Dictionary) -> Dictionary: return execute("get_groups", params),
		"scene_config/set_group": func(params: Dictionary) -> Dictionary: return execute("set_group", params),
		"scene_config/get_meta": func(params: Dictionary) -> Dictionary: return execute("get_meta", params),
		"scene_config/set_meta": func(params: Dictionary) -> Dictionary: return execute("set_meta", params),
		"scene_config/remove_meta": func(params: Dictionary) -> Dictionary: return execute("remove_meta", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_inheritance": return _get_inheritance(params)
		"set_unique_name": return _set_unique_name(params)
		"get_groups": return _get_groups(params)
		"set_group": return _set_group(params)
		"get_meta": return _get_meta(params)
		"set_meta": return _set_meta(params)
		"remove_meta": return _remove_meta(params)
	return {"success": false, "error": "Unknown method: " + method}


## Get scene inheritance chain.
func _get_inheritance(params: Dictionary) -> Dictionary:
	var scene_path: String = params.get("scene_path", "")
	if scene_path.is_empty():
		# Use current scene
		var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
		if root == null:
			return {"success": false, "error": "No scene open"}
		scene_path = root.scene_file_path
	if not FileAccess.file_exists(scene_path):
		return {"success": false, "error": "Scene not found: %s" % scene_path}
	# Parse the scene file to find inheritance
	var chain: Array = []
	var current_path: String = scene_path
	while current_path != "" and FileAccess.file_exists(current_path):
		chain.append(current_path)
		var file: FileAccess = FileAccess.open(current_path, FileAccess.READ)
		if file == null:
			break
		var content: String = file.get_as_text()
		file.close()
		# Look for inherits="res://..." in the scene file
		var inherits_pos: int = content.find("inherits=\"")
		if inherits_pos == -1:
			break
		var start_pos: int = inherits_pos + 10
		var end_pos: int = content.find("\"", start_pos)
		if end_pos == -1:
			break
		current_path = content.substr(start_pos, end_pos - start_pos)
		if chain.has(current_path):
			break  # Prevent infinite loops
	return {"success": true, "scene_path": scene_path, "inheritance_chain": chain, "depth": chain.size()}


## Toggle unique name on a node.
func _set_unique_name(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var unique: bool = params.get("unique", true)
	if node_path.is_empty():
		return {"success": false, "error": "Node path cannot be empty"}
	var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"success": false, "error": "Node not found: %s" % node_path}
	var old_unique: bool = node.unique_name_in_owner
	if _undo_helper:
		var ur: EditorUndoRedoManager = _undo_helper.get_undo_redo_manager()
		ur.create_action("MCP: Set unique name on %s" % node_path)
		ur.add_do_property(node, "unique_name_in_owner", unique)
		ur.add_undo_property(node, "unique_name_in_owner", old_unique)
		ur.commit_action()
	else:
		node.unique_name_in_owner = unique
	# Mark scene as modified
	_plugin.get_editor_interface().mark_scene_as_unsaved()
	return {"success": true, "node": node_path, "unique": unique, "message": "Unique name %s" % ("enabled" if unique else "disabled")}


## Get all groups in a scene.
func _get_groups(params: Dictionary) -> Dictionary:
	var scene_path: String = params.get("scene_path", "")
	var root: Node = null
	if scene_path.is_empty():
		root = _plugin.get_editor_interface().get_edited_scene_root()
	else:
		# Load scene to inspect
		if not FileAccess.file_exists(scene_path):
			return {"success": false, "error": "Scene not found: %s" % scene_path}
		var scene: PackedScene = ResourceLoader.load(scene_path) as PackedScene
		if scene == null:
			return {"success": false, "error": "Failed to load scene: %s" % scene_path}
		root = scene.instantiate()
	if root == null:
		return {"success": false, "error": "No scene available"}
	var groups_dict: Dictionary = {}
	if scene_path.is_empty():
		_collect_groups(root, groups_dict)
	else:
		# File-based: nodes are orphaned (not in scene tree), get_path() returns empty.
		# Reconstruct relative paths by walking the parent chain up to the root.
		_collect_groups_orphan(root, groups_dict, root)
	var groups: Array = []
	for group_name: String in groups_dict:
		groups.append({"name": group_name, "nodes": groups_dict[group_name]})
	if scene_path != "" and root != _plugin.get_editor_interface().get_edited_scene_root():
		root.queue_free()
	return {"success": true, "groups": groups, "group_count": groups.size()}


## Add or remove a node from a group.
func _set_group(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var group: String = params.get("group", "")
	var add: bool = params.get("add", true)
	if node_path.is_empty():
		return {"success": false, "error": "Node path cannot be empty"}
	if group.is_empty():
		return {"success": false, "error": "Group name cannot be empty"}
	var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"success": false, "error": "Node not found: %s" % node_path}
	if _undo_helper:
		var ur: EditorUndoRedoManager = _undo_helper.get_undo_redo_manager()
		ur.create_action("MCP: %s node %s %s group '%s'" % ["Add" if add else "Remove", node_path, "to" if add else "from", group])
		if add:
			ur.add_do_method(node, "add_to_group", group, true)
			ur.add_undo_method(node, "remove_from_group", group)
		else:
			ur.add_do_method(node, "remove_from_group", group)
			ur.add_undo_method(node, "add_to_group", group, true)
		ur.commit_action()
	else:
		if add:
			node.add_to_group(group, true)
		else:
			node.remove_from_group(group)
	_plugin.get_editor_interface().mark_scene_as_unsaved()
	return {"success": true, "node": node_path, "group": group, "action": "added" if add else "removed"}


## Get metadata on a scene's root node.
func _get_meta(params: Dictionary) -> Dictionary:
	var scene_path: String = params.get("scene_path", "")
	var root: Node = null
	if scene_path.is_empty():
		root = _plugin.get_editor_interface().get_edited_scene_root()
	else:
		if not FileAccess.file_exists(scene_path):
			return {"success": false, "error": "Scene not found: %s" % scene_path}
		var scene: PackedScene = ResourceLoader.load(scene_path) as PackedScene
		if scene == null:
			return {"success": false, "error": "Failed to load scene: %s" % scene_path}
		root = scene.instantiate()
	if root == null:
		return {"success": false, "error": "No scene available"}
	# Resolve scene_path from root if not provided
	if scene_path.is_empty():
		scene_path = root.scene_file_path
	var meta: Array = []
	for key: String in root.get_meta_list():
		meta.append({"key": key, "value": MCPVariantCodec.serialize_value(root.get_meta(key))})
	if scene_path != "" and root != _plugin.get_editor_interface().get_edited_scene_root():
		root.queue_free()
	return {"success": true, "scene_path": scene_path, "meta": meta, "count": meta.size()}


## Set metadata on the current scene's root node.
func _set_meta(params: Dictionary) -> Dictionary:
	var scene_path: String = params.get("scene_path", "")
	var key: String = params.get("key", "")
	var value: Variant = params.get("value")
	if key.is_empty():
		return {"success": false, "error": "Key cannot be empty"}
	if value == null:
		return {"success": false, "error": "Value cannot be null. Godot treats set_meta(key, null) as remove_meta(key). Use remove_scene_meta to delete a key, or provide a non-null value."}
	var root: Node = null
	if scene_path.is_empty():
		root = _plugin.get_editor_interface().get_edited_scene_root()
	else:
		return {"success": false, "error": "Setting meta on non-current scenes is not supported (leave scene_path empty for current scene)"}
	if root == null:
		return {"success": false, "error": "No scene open"}
	var old_val: Variant = root.get_meta(key, null) if root.has_meta(key) else null
	var had_meta: bool = root.has_meta(key)
	if _undo_helper:
		var ur: EditorUndoRedoManager = _undo_helper.get_undo_redo_manager()
		ur.create_action("MCP: Set meta '%s' on scene root" % key)
		ur.add_do_method(root, "set_meta", key, value)
		if had_meta:
			ur.add_undo_method(root, "set_meta", key, old_val)
		else:
			ur.add_undo_method(root, "remove_meta", key)
		ur.commit_action()
	else:
		root.set_meta(key, value)
	_plugin.get_editor_interface().mark_scene_as_unsaved()
	return {"success": true, "key": key, "message": "Metadata set"}


## Remove metadata from the current scene's root node.
func _remove_meta(params: Dictionary) -> Dictionary:
	var scene_path: String = params.get("scene_path", "")
	var key: String = params.get("key", "")
	if key.is_empty():
		return {"success": false, "error": "Key cannot be empty"}
	if not scene_path.is_empty():
		return {"success": false, "error": "Removing meta on non-current scenes is not supported (leave scene_path empty for current scene)"}
	var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	if not root.has_meta(key):
		return {"success": false, "error": "Metadata key not found: %s" % key}
	var old_val: Variant = root.get_meta(key)
	if _undo_helper:
		var ur: EditorUndoRedoManager = _undo_helper.get_undo_redo_manager()
		ur.create_action("MCP: Remove meta '%s' on scene root" % key)
		ur.add_do_method(root, "remove_meta", key)
		ur.add_undo_method(root, "set_meta", key, old_val)
		ur.commit_action()
	else:
		root.remove_meta(key)
	_plugin.get_editor_interface().mark_scene_as_unsaved()
	return {"success": true, "key": key, "message": "Metadata removed"}


## Recursive helper: collect groups from all nodes.
func _collect_groups(node: Node, groups: Dictionary) -> void:
	for group: String in node.get_groups():
		# Skip Godot-internal groups (prefixed with _)
		if group.begins_with("_"):
			continue
		if not groups.has(group):
			groups[group] = []
		groups[group].append(MCPCommandHelpers.get_node_path(node, _plugin))
	for child: Node in node.get_children():
		_collect_groups(child, groups)


## Collect groups from orphan nodes (instantiated from file, not in scene tree).
## Reconstructs relative paths by walking the parent chain up to `base_root`.
func _collect_groups_orphan(node: Node, groups: Dictionary, base_root: Node) -> void:
	for group: String in node.get_groups():
		if group.begins_with("_"):
			continue
		if not groups.has(group):
			groups[group] = []
		groups[group].append(_orphan_relative_path(node, base_root))
	for child: Node in node.get_children():
		_collect_groups_orphan(child, groups, base_root)


## Build a relative path for an orphan node by walking up to `base_root`.
## Returns "." for the root, "A/B/C" for nested nodes.
static func _orphan_relative_path(node: Node, base_root: Node) -> String:
	if node == base_root:
		return "."
	var parts: Array = []
	var n: Node = node
	while n != null and n != base_root:
		parts.push_front(str(n.name))
		n = n.get_parent()
	return "/".join(parts)
