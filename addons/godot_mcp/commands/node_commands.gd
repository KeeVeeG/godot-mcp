## Node commands module - 17 tools.
## Handles node CRUD, properties, signals, groups, and selection.
class_name MCPNodeCommands
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
		"node/add": func(params: Dictionary) -> Dictionary: return execute("add_node", params),
		"node/delete": func(params: Dictionary) -> Dictionary: return execute("delete_node", params),
		"node/duplicate": func(params: Dictionary) -> Dictionary: return execute("duplicate_node", params),
		"node/move": func(params: Dictionary) -> Dictionary: return execute("move_node", params),
		"node/update_property": func(params: Dictionary) -> Dictionary: return execute("update_property", params),
		"node/get_properties": func(params: Dictionary) -> Dictionary: return execute("get_node_properties", params),
		"node/add_resource": func(params: Dictionary) -> Dictionary: return execute("add_resource", params),
		"node/set_anchor_preset": func(params: Dictionary) -> Dictionary: return execute("set_anchor_preset", params),
		"node/rename": func(params: Dictionary) -> Dictionary: return execute("rename_node", params),
		"node/connect_signal": func(params: Dictionary) -> Dictionary: return execute("connect_signal", params),
		"node/disconnect_signal": func(params: Dictionary) -> Dictionary: return execute("disconnect_signal", params),
		"node/get_groups": func(params: Dictionary) -> Dictionary: return execute("get_node_groups", params),
		"node/set_groups": func(params: Dictionary) -> Dictionary: return execute("set_node_groups", params),
		"node/find_in_group": func(params: Dictionary) -> Dictionary: return execute("find_nodes_in_group", params),
		"node/get_selection": func(params: Dictionary) -> Dictionary: return execute("get_editor_selection", params),
		"node/select": func(params: Dictionary) -> Dictionary: return execute("select_nodes", params),
		"node/clear_selection": func(params: Dictionary) -> Dictionary: return execute("clear_editor_selection", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"add_node": return _add_node(params)
		"delete_node": return _delete_node(params)
		"duplicate_node": return _duplicate_node(params)
		"move_node": return _move_node(params)
		"update_property": return _update_property(params)
		"get_node_properties": return _get_node_properties(params)
		"add_resource": return _add_resource(params)
		"set_anchor_preset": return _set_anchor_preset(params)
		"rename_node": return _rename_node(params)
		"connect_signal": return _connect_signal(params)
		"disconnect_signal": return _disconnect_signal(params)
		"get_node_groups": return _get_node_groups(params)
		"set_node_groups": return _set_node_groups(params)
		"find_nodes_in_group": return _find_nodes_in_group(params)
		"get_editor_selection": return _get_editor_selection()
		"select_nodes": return _select_nodes(params)
		"clear_editor_selection": return _clear_editor_selection()
	return {"error": "Unknown method: " + method}


## Add a node to the scene tree with UndoRedo support.
func _add_node(params: Dictionary) -> Dictionary:
	var parent_path: String = params.get("parent_path", "")
	var type_name: String = params.get("type", "Node")
	var node_name: String = params.get("name", type_name)
	var properties: Dictionary = params.get("properties", {})

	var parent: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if parent == null:
		return {"error": "No scene open"}
	if parent_path != "":
		parent = _resolve_node(parent_path, parent)
		if parent == null:
			return {"error": "Parent not found: %s" % parent_path}

	# Create node
	var node: Node = _create_node_by_type(type_name)
	if node == null:
		return {"error": "Unknown type: %s" % type_name}
	node.name = node_name

	# Apply properties before adding to tree (for position, etc.)
	for prop: String in properties:
		var value: Variant = properties[prop]
		if MCPCommandHelpers.has_property(node, prop):
			var expected_type: int = MCPCommandHelpers.get_property_type(node, prop)
			value = MCPVariantCodec.parse_for_property(value, expected_type)
			node.set(prop, value)

	if _undo_helper:
		_undo_helper.add_node_with_undo(node, parent)
	else:
		parent.add_child(node)
		node.set_owner(MCPCommandHelpers.get_scene_root(_plugin))

	return {"result": {"name": str(node.name), "path": MCPCommandHelpers.get_node_path(node, _plugin), "type": type_name}}


## Delete a node from the scene tree with UndoRedo support.
func _delete_node(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"error": "Node not found: %s" % path}
	if node == root:
		return {"error": "Cannot delete scene root"}

	if _undo_helper:
		_undo_helper.remove_node_with_undo(node)
	else:
		node.queue_free()
	return {"result": {"message": "Node deleted: %s" % path}}


## Duplicate a node with UndoRedo support.
func _duplicate_node(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"error": "Node not found: %s" % path}
	if node == root:
		return {"error": "Cannot duplicate scene root"}

	if _undo_helper:
		var dupe: Node = _undo_helper.duplicate_node_with_undo(node)
		if dupe:
			return {"result": {"original": path, "duplicate": MCPCommandHelpers.get_node_path(dupe, _plugin), "name": str(dupe.name)}}
		return {"error": "Duplication failed: %s" % path}
	else:
		var dupe2: Node = node.duplicate()
		if dupe2 == null:
			return {"error": "Duplication failed"}
		node.get_parent().add_child(dupe2)
		dupe2.set_owner(MCPCommandHelpers.get_scene_root(_plugin))
		return {"result": {"original": path, "duplicate": MCPCommandHelpers.get_node_path(dupe2, _plugin), "name": str(dupe2.name)}}


## Move a node to a new parent with UndoRedo support.
func _move_node(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var new_parent_path: String = params.get("new_parent", "")
	var index: int = params.get("index", -1)
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"error": "Node not found: %s" % path}
	var new_parent: Node = _resolve_node(new_parent_path, root)
	if new_parent == null:
		return {"error": "New parent not found: %s" % new_parent_path}

	if _undo_helper:
		_undo_helper.move_node_with_undo(node, new_parent, index)
	else:
		node.get_parent().remove_child(node)
		new_parent.add_child(node)
		if index >= 0:
			new_parent.move_child(node, index)
		node.set_owner(MCPCommandHelpers.get_scene_root(_plugin))

	var display_parent: String = new_parent_path
	if display_parent == "" or display_parent == "." or display_parent == "/":
		display_parent = "root"
	return {"result": {"message": "Node moved to %s" % display_parent}}


## Update a property on a node with UndoRedo support.
## Uses MCPVariantCodec for type-aware parsing.
func _update_property(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var property: String = params.get("property", "")
	var value: Variant = params.get("value")
	if property.is_empty():
		return {"error": "Property name is required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"error": "Node not found: %s" % path}

	# Validate property exists and is settable
	if not MCPCommandHelpers.has_property(node, property):
		return {"error": "Property '%s' not found on %s (type: %s)" % [property, node.name, node.get_class()]}

	# Get expected type and validate value compatibility
	var expected_type: int = MCPCommandHelpers.get_property_type(node, property)

	# Reject type mismatches: string→number that can't parse
	if value is String:
		var s: String = value as String
		match expected_type:
			TYPE_INT:
				if not s.is_valid_int():
					return {"error": "Type mismatch for '%s': expected int, got string '%s'" % [property, s]}
			TYPE_FLOAT:
				if not s.is_valid_float() and not s.is_valid_int():
					return {"error": "Type mismatch for '%s': expected float, got string '%s'" % [property, s]}

	value = MCPVariantCodec.parse_for_property(value, expected_type)

	if _undo_helper:
		_undo_helper.set_property_with_undo(node, property, value)
	else:
		node.set(property, value)
	return {"result": {"message": "Property %s updated on %s" % [property, path]}}


## Get serialized properties of a node.
## Optional "properties" param filters to only requested property names.
func _get_node_properties(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var filter_props: Array = params.get("properties", [])
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var props: Dictionary = {}

	if filter_props.size() > 0:
		# Return only requested properties
		for prop_name_variant: Variant in filter_props:
			var prop_name: String = prop_name_variant as String
			if MCPCommandHelpers.has_property(node, prop_name):
				props[prop_name] = MCPVariantCodec.serialize_value(node.get(prop_name))
			else:
				props[prop_name] = null
	else:
		# Return all stored/editor-visible properties
		var prop_list: Array = node.get_property_list()
		for p: Dictionary in prop_list:
			var pname: String = p["name"] as String
			var usage: int = p["usage"] as int
			# Skip internal properties (not stored or editable)
			if usage & PROPERTY_USAGE_STORAGE == 0 and usage & PROPERTY_USAGE_EDITOR == 0:
				continue
			if pname.begins_with("_") and not pname.begins_with("__"):
				continue
			var val: Variant = node.get(pname)
			props[pname] = MCPVariantCodec.serialize_value(val)

	return {"result": {"path": path, "type": node.get_class(), "properties": props}}


## Create a resource and assign it to a node's appropriate property.
func _add_resource(params: Dictionary) -> Dictionary:
	var path: String = params.get("node_path", params.get("path", ""))
	var resource_type: String = params.get("resource_type", "")
	var properties: Dictionary = params.get("properties", {})
	if resource_type.is_empty():
		return {"error": "Resource type is required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"error": "Node not found: %s" % path}

	# Create resource by type
	var res: Resource = null
	match resource_type:
		"CircleShape2D":
			res = CircleShape2D.new()
		"RectangleShape2D":
			res = RectangleShape2D.new()
		"CapsuleShape2D":
			res = CapsuleShape2D.new()
		"SegmentShape2D":
			res = SegmentShape2D.new()
		"BoxShape3D":
			res = BoxShape3D.new()
		"SphereShape3D":
			res = SphereShape3D.new()
		"CapsuleShape3D":
			res = CapsuleShape3D.new()
		"CylinderShape3D":
			res = CylinderShape3D.new()
		"ConvexPolygonShape3D":
			res = ConvexPolygonShape3D.new()
		"ConcavePolygonShape3D":
			res = ConcavePolygonShape3D.new()
		"StandardMaterial3D":
			res = StandardMaterial3D.new()
		"ShaderMaterial":
			res = ShaderMaterial.new()
		"Gradient":
			res = Gradient.new()
		"Curve":
			res = Curve.new()
		_:
			if ClassDB.can_instantiate(resource_type):
				var obj: Object = ClassDB.instantiate(resource_type)
				if obj is Resource:
					res = obj as Resource
	if res == null:
		return {"error": "Unknown resource type: %s" % resource_type}

	# Apply properties to the resource
	for prop: String in properties:
		if MCPCommandHelpers.has_property(res, prop):
			var val: Variant = MCPVariantCodec.parse_for_property(properties[prop], MCPCommandHelpers.get_property_type(res, prop))
			res.set(prop, val)

	# Try to assign to the node's primary resource slot
	if node is CollisionShape2D and res is Shape2D:
		if _undo_helper:
			_undo_helper.set_property_with_undo(node, "shape", res)
		else:
			(node as CollisionShape2D).shape = res as Shape2D
	elif node is CollisionShape3D and res is Shape3D:
		if _undo_helper:
			_undo_helper.set_property_with_undo(node, "shape", res)
		else:
			(node as CollisionShape3D).shape = res as Shape3D
	elif node is Sprite2D and res is Texture2D:
		if _undo_helper:
			_undo_helper.set_property_with_undo(node, "texture", res)
		else:
			(node as Sprite2D).texture = res as Texture2D
	elif node is MeshInstance3D and res is Material:
		if _undo_helper:
			_undo_helper.set_property_with_undo(node, "material_override", res)
		else:
			(node as MeshInstance3D).material_override = res
	elif node is VisualInstance3D and res is Material:
		if _undo_helper:
			_undo_helper.set_property_with_undo(node, "material_override", res)
		else:
			(node as VisualInstance3D).material_override = res
	else:
		# Generic: try common property names
		var assigned: bool = false
		for try_prop: String in ["shape", "texture", "material", "material_override", "stream", "gradient", "curve"]:
			if MCPCommandHelpers.has_property(node, try_prop):
				if _undo_helper:
					_undo_helper.set_property_with_undo(node, try_prop, res)
				else:
					node.set(try_prop, res)
				assigned = true
				break
		if not assigned:
			return {"error": "Cannot auto-assign %s to %s (no matching property)" % [resource_type, node.get_class()]}

	return {"result": {"resource_type": resource_type, "node": path}}


## Set anchor preset on a Control node.
func _set_anchor_preset(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var raw_preset = params.get("preset", 0)
	var preset: int = _resolve_preset(raw_preset)
	if preset == -1:
		return {"error": "Invalid anchor preset: '%s'. Valid presets (0-15): top_left, top_right, bottom_left, bottom_right, center_left, center_top, center_right, center_bottom, center, left_wide, top_wide, right_wide, bottom_wide, vcenter_wide, hcenter_wide, full_rect" % str(raw_preset)}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"error": "Node not found: %s" % path}
	if not node is Control:
		return {"error": "Node is not a Control: %s" % path}

	var ctrl: Control = node as Control
	var preset_enum: Control.LayoutPreset = preset as Control.LayoutPreset
	if _undo_helper:
		var old_left: float = ctrl.anchor_left
		var old_top: float = ctrl.anchor_top
		var old_right: float = ctrl.anchor_right
		var old_bottom: float = ctrl.anchor_bottom
		var old_offset_left: float = ctrl.offset_left
		var old_offset_top: float = ctrl.offset_top
		var old_offset_right: float = ctrl.offset_right
		var old_offset_bottom: float = ctrl.offset_bottom
		var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
		ur.create_action("MCP: Set anchor preset")
		ur.add_do_method(ctrl, "set_anchors_preset", preset_enum)
		ur.add_undo_property(ctrl, "anchor_left", old_left)
		ur.add_undo_property(ctrl, "anchor_top", old_top)
		ur.add_undo_property(ctrl, "anchor_right", old_right)
		ur.add_undo_property(ctrl, "anchor_bottom", old_bottom)
		ur.add_undo_property(ctrl, "offset_left", old_offset_left)
		ur.add_undo_property(ctrl, "offset_top", old_offset_top)
		ur.add_undo_property(ctrl, "offset_right", old_offset_right)
		ur.add_undo_property(ctrl, "offset_bottom", old_offset_bottom)
		ur.commit_action()
	else:
		ctrl.set_anchors_preset(preset_enum)
	return {"result": {"message": "Anchor preset %d set on %s" % [preset, path]}}


## Rename a node with UndoRedo support.
func _rename_node(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var new_name: String = params.get("new_name", "")
	if new_name.is_empty():
		return {"error": "New name is required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"error": "Node not found: %s" % path}

	if _undo_helper:
		_undo_helper.rename_node_with_undo(node, new_name)
	else:
		node.name = new_name
	return {"result": {"old_path": path, "new_name": new_name, "new_path": MCPCommandHelpers.get_node_path(node, _plugin)}}


## Connect a signal between two nodes with UndoRedo support.
func _connect_signal(params: Dictionary) -> Dictionary:
	var source_path: String = params.get("source", "")
	var signal_name: String = params.get("signal", "")
	var target_path: String = params.get("target", "")
	var method_name: String = params.get("method", "")
	if signal_name.is_empty() or method_name.is_empty():
		return {"error": "Signal name and method name are required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var source: Node = _resolve_node(source_path, root)
	if source == null:
		return {"error": "Source not found: %s" % source_path}
	var target: Node = _resolve_node(target_path, root)
	if target == null:
		return {"error": "Target not found: %s" % target_path}
	if not source.has_signal(signal_name):
		return {"error": "Signal '%s' not found on %s" % [signal_name, source_path]}
	if not target.has_method(method_name):
		return {"error": "Method '%s' not found on %s" % [method_name, target_path]}

	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Connect signal %s.%s -> %s.%s" % [source_path, signal_name, target_path, method_name])
	ur.add_do_method(source, "connect", signal_name, Callable(target, method_name))
	ur.add_undo_method(source, "disconnect", signal_name, Callable(target, method_name))
	ur.commit_action()

	return {"result": {"message": "Connected %s.%s -> %s.%s" % [source_path, signal_name, target_path, method_name]}}


## Disconnect a signal between two nodes with UndoRedo support.
func _disconnect_signal(params: Dictionary) -> Dictionary:
	var source_path: String = params.get("source", "")
	var signal_name: String = params.get("signal", "")
	var target_path: String = params.get("target", "")
	var method_name: String = params.get("method", "")
	if signal_name.is_empty() or method_name.is_empty():
		return {"error": "Signal name and method name are required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var source: Node = _resolve_node(source_path, root)
	if source == null:
		return {"error": "Source not found: %s" % source_path}
	var target: Node = _resolve_node(target_path, root)
	if target == null:
		return {"error": "Target not found: %s" % target_path}

	var callable: Callable = Callable(target, method_name)
	if not source.is_connected(signal_name, callable):
		return {"error": "Signal not connected: %s.%s -> %s.%s" % [source_path, signal_name, target_path, method_name]}

	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Disconnect signal")
	ur.add_do_method(source, "disconnect", signal_name, callable)
	ur.add_undo_method(source, "connect", signal_name, callable)
	ur.commit_action()

	return {"result": {"message": "Disconnected %s.%s -> %s.%s" % [source_path, signal_name, target_path, method_name]}}


## Get groups a node belongs to.
func _get_node_groups(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var groups: Array = node.get_groups()
	return {"result": {"path": path, "groups": groups}}


## Set groups on a node (replaces user-added groups, preserves engine-managed ones).
func _set_node_groups(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var groups: Array = params.get("groups", [])
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"error": "Node not found: %s" % path}

	# Remove only user-added groups (preserve engine-managed ones starting with "__")
	var current_groups: Array = node.get_groups()
	for g: String in current_groups:
		if not g.begins_with("__"):
			node.remove_from_group(g)

	# Add to new groups
	for g_variant: Variant in groups:
		var g: String = g_variant as String
		node.add_to_group(g, true)

	return {"result": {"message": "Groups set on %s" % path, "groups": groups}}


## Find all nodes belonging to a specific group.
func _find_nodes_in_group(params: Dictionary) -> Dictionary:
	var group: String = params.get("group", "")
	if group.is_empty():
		return {"error": "Group name is required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var nodes: Array = root.get_tree().get_nodes_in_group(group)
	var results: Array = []
	for n: Node in nodes:
		results.append({
			"path": MCPCommandHelpers.get_node_path(n, _plugin),
			"name": str(n.name),
			"type": n.get_class(),
		})
	return {"result": {"group": group, "count": results.size(), "nodes": results}}


## Get the current editor selection.
func _get_editor_selection() -> Dictionary:
	var selection: EditorSelection = _plugin.get_editor_interface().get_selection()
	var selected: Array[Node] = selection.get_selected_nodes()
	var results: Array = []
	for node: Node in selected:
		results.append({
			"path": MCPCommandHelpers.get_node_path(node, _plugin),
			"name": str(node.name),
			"type": node.get_class(),
		})
	return {"result": {"count": results.size(), "nodes": results}}


## Select specific nodes in the editor.
func _select_nodes(params: Dictionary) -> Dictionary:
	var paths: Array = params.get("paths", [])
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var selection: EditorSelection = _plugin.get_editor_interface().get_selection()
	selection.clear()
	var selected_count: int = 0
	var not_found: Array = []
	for p_variant: Variant in paths:
		var p: String = p_variant as String
		var node: Node = _resolve_node(p, root)
		if node:
			selection.add_node(node)
			selected_count += 1
		else:
			not_found.append(p)
	var result: Dictionary = {"result": {"message": "Selected %d of %d nodes" % [selected_count, paths.size()], "selected": selected_count}}
	if not_found.size() > 0:
		result["result"]["not_found"] = not_found
		result["result"]["warning"] = "%d path(s) not found: %s" % [not_found.size(), ", ".join(not_found)]
	return result


## Clear the editor selection.
func _clear_editor_selection() -> Dictionary:
	var selection: EditorSelection = _plugin.get_editor_interface().get_selection()
	selection.clear()
	return {"result": {"message": "Selection cleared"}}


## Helper: resolve a path string to a Node in the edited scene.
## - "" or "." → the scene root node
## - Bare name matching root's name → the scene root node
## - Otherwise → root.get_node_or_null(path) for children/descendants
func _resolve_node(path: String, root: Node) -> Node:
	if path.is_empty() or path == ".":
		return root
	# Bare name (no slashes) that matches the root's own name
	if not path.contains("/") and root.name == path:
		return root
	# Strip editor-internal prefix if present (e.g., /root/@EditorNode@123/.../SceneRoot/Node)
	if path.begins_with("/root/@"):
		var root_path: String = str(root.get_path())
		var idx: int = path.find(root_path)
		if idx != -1:
			path = path.substr(idx + root_path.length() + 1)
	return root.get_node_or_null(path)


## Helper: create node by type. Uses shared MCPNodeFactory.
func _create_node_by_type(type_name: String) -> Node:
	return MCPNodeFactory.create_node(type_name)





## Helper: resolve a preset value (string name or int) to Control.LayoutPreset int.
## Returns -1 if the preset is invalid — caller must return an error.
func _resolve_preset(raw) -> int:
	if raw is int:
		if raw >= 0 and raw <= 15:
			return raw
		return -1
	if raw is float:
		var as_int: int = int(raw)
		if as_int >= 0 and as_int <= 15:
			return as_int
		return -1
	if raw is String:
		var lower: String = raw.to_lower()
		var enum_map: Dictionary = {
			"top_left": Control.PRESET_TOP_LEFT,
			"top_right": Control.PRESET_TOP_RIGHT,
			"bottom_left": Control.PRESET_BOTTOM_LEFT,
			"bottom_right": Control.PRESET_BOTTOM_RIGHT,
			"center_left": Control.PRESET_CENTER_LEFT,
			"center_top": Control.PRESET_CENTER_TOP,
			"center_right": Control.PRESET_CENTER_RIGHT,
			"center_bottom": Control.PRESET_CENTER_BOTTOM,
			"center": Control.PRESET_CENTER,
			"left_wide": Control.PRESET_LEFT_WIDE,
			"top_wide": Control.PRESET_TOP_WIDE,
			"right_wide": Control.PRESET_RIGHT_WIDE,
			"bottom_wide": Control.PRESET_BOTTOM_WIDE,
			"vcenter_wide": Control.PRESET_VCENTER_WIDE,
			"hcenter_wide": Control.PRESET_HCENTER_WIDE,
			"full_rect": Control.PRESET_FULL_RECT,
		}
		if enum_map.has(lower):
			return enum_map[lower]
		# Try parsing as int string
		if raw.is_valid_int():
			var as_int: int = raw.to_int()
			if as_int >= 0 and as_int <= 15:
				return as_int
		return -1
	return -1
