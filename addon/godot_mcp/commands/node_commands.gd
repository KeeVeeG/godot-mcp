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
	return {"success": false, "error": "Unknown method: " + method}


## Add a node to the scene tree with UndoRedo support.
func _add_node(params: Dictionary) -> Dictionary:
	var parent_path: String = params.get("parent_path", "")
	var type_name: String = params.get("type", "Node")
	var node_name: String = params.get("name", type_name)
	var properties: Dictionary = params.get("properties", {})

	var parent: Node = _get_edited_scene_root()
	if parent == null:
		return {"success": false, "error": "No scene open"}
	if parent_path != "":
		parent = _resolve_node(parent_path, parent)
		if parent == null:
			return {"success": false, "error": "Parent not found: %s" % parent_path}

	# Create node
	var node: Node = _create_node_by_type(type_name)
	if node == null:
		return {"success": false, "error": "Unknown type: %s" % type_name}
	node.name = node_name

	# Apply properties before adding to tree (for position, etc.)
	for prop: String in properties:
		var value: Variant = properties[prop]
		if _has_property(node, prop):
			var expected_type: int = _get_property_type(node, prop)
			value = MCPVariantCodec.parse_for_property(value, expected_type)
			node.set(prop, value)

	if _undo_helper:
		_undo_helper.add_node_with_undo(node, parent)
	else:
		parent.add_child(node)
		node.set_owner(_get_edited_scene_root())

	return {"success": true, "name": str(node.name), "path": str(node.get_path()), "type": type_name}


## Delete a node from the scene tree with UndoRedo support.
func _delete_node(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var root: Node = _get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"success": false, "error": "Node not found: %s" % path}
	if node == root:
		return {"success": false, "error": "Cannot delete scene root"}

	if _undo_helper:
		_undo_helper.remove_node_with_undo(node)
	else:
		node.queue_free()
	return {"success": true, "message": "Node deleted: %s" % path}


## Duplicate a node with UndoRedo support.
func _duplicate_node(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var root: Node = _get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"success": false, "error": "Node not found: %s" % path}

	if _undo_helper:
		var dupe: Node = _undo_helper.duplicate_node_with_undo(node)
		if dupe:
			return {"success": true, "original": path, "duplicate": str(dupe.get_path()), "name": str(dupe.name)}
		return {"success": false, "error": "Duplication failed"}
	else:
		var dupe2: Node = node.duplicate()
		if dupe2 == null:
			return {"success": false, "error": "Duplication failed"}
		node.get_parent().add_child(dupe2)
		dupe2.set_owner(_get_edited_scene_root())
		return {"success": true, "original": path, "duplicate": str(dupe2.get_path()), "name": str(dupe2.name)}


## Move a node to a new parent with UndoRedo support.
func _move_node(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var new_parent_path: String = params.get("new_parent", "")
	var index: int = params.get("index", -1)
	var root: Node = _get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"success": false, "error": "Node not found: %s" % path}
	var new_parent: Node = _resolve_node(new_parent_path, root)
	if new_parent == null:
		return {"success": false, "error": "New parent not found: %s" % new_parent_path}

	if _undo_helper:
		_undo_helper.move_node_with_undo(node, new_parent, index)
	else:
		node.get_parent().remove_child(node)
		new_parent.add_child(node)
		if index >= 0:
			new_parent.move_child(node, index)
		node.set_owner(_get_edited_scene_root())

	var display_parent: String = new_parent_path
	if display_parent == "." or display_parent == "/":
		display_parent = "root (.)"
	return {"success": true, "message": "Node moved to %s" % display_parent}


## Update a property on a node with UndoRedo support.
## Uses MCPVariantCodec for type-aware parsing.
func _update_property(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var property: String = params.get("property", "")
	var value: Variant = params.get("value")
	if property.is_empty():
		return {"success": false, "error": "Property name is required"}
	var root: Node = _get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"success": false, "error": "Node not found: %s" % path}

	# Parse value for the expected type
	if _has_property(node, property):
		var expected_type: int = _get_property_type(node, property)
		value = MCPVariantCodec.parse_for_property(value, expected_type)

	if _undo_helper:
		_undo_helper.set_property_with_undo(node, property, value)
	else:
		node.set(property, value)
	return {"success": true, "message": "Property %s updated on %s" % [property, path]}


## Get all serialized properties of a node.
func _get_node_properties(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var root: Node = _get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"success": false, "error": "Node not found: %s" % path}

	var props: Dictionary = {}
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

	return {"success": true, "path": path, "type": node.get_class(), "properties": props}


## Create a resource and assign it to a node's appropriate property.
func _add_resource(params: Dictionary) -> Dictionary:
	var path: String = params.get("node_path", params.get("path", ""))
	var resource_type: String = params.get("resource_type", "")
	var properties: Dictionary = params.get("properties", {})
	if resource_type.is_empty():
		return {"success": false, "error": "Resource type is required"}

	var root: Node = _get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"success": false, "error": "Node not found: %s" % path}

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
		return {"success": false, "error": "Unknown resource type: %s" % resource_type}

	# Apply properties to the resource
	for prop: String in properties:
		if _has_property(res, prop):
			var val: Variant = MCPVariantCodec.parse_for_property(properties[prop], _get_property_type(res, prop))
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
	else:
		# Generic: try common property names
		var assigned: bool = false
		for try_prop: String in ["shape", "texture", "material", "material_override", "stream", "gradient", "curve"]:
			if _has_property(node, try_prop):
				if _undo_helper:
					_undo_helper.set_property_with_undo(node, try_prop, res)
				else:
					node.set(try_prop, res)
				assigned = true
				break
		if not assigned:
			return {"success": false, "error": "Cannot auto-assign %s to %s (no matching property)" % [resource_type, node.get_class()]}

	return {"success": true, "resource_type": resource_type, "node": path}


## Set anchor preset on a Control node.
func _set_anchor_preset(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var raw_preset = params.get("preset", 0)
	var preset: int = _resolve_preset(raw_preset)
	var root: Node = _get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"success": false, "error": "Node not found: %s" % path}
	if not node is Control:
		return {"success": false, "error": "Node is not a Control: %s" % path}

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
	return {"success": true, "message": "Anchor preset %d set on %s" % [preset, path]}


## Rename a node with UndoRedo support.
func _rename_node(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var new_name: String = params.get("new_name", "")
	if new_name.is_empty():
		return {"success": false, "error": "New name is required"}
	var root: Node = _get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"success": false, "error": "Node not found: %s" % path}

	if _undo_helper:
		_undo_helper.rename_node_with_undo(node, new_name)
	else:
		node.name = new_name
	return {"success": true, "old_path": path, "new_name": new_name, "new_path": str(node.get_path())}


## Connect a signal between two nodes with UndoRedo support.
func _connect_signal(params: Dictionary) -> Dictionary:
	var source_path: String = params.get("source", "")
	var signal_name: String = params.get("signal", "")
	var target_path: String = params.get("target", "")
	var method_name: String = params.get("method", "")
	if signal_name.is_empty() or method_name.is_empty():
		return {"success": false, "error": "Signal name and method name are required"}

	var root: Node = _get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	var source: Node = _resolve_node(source_path, root)
	if source == null:
		return {"success": false, "error": "Source not found: %s" % source_path}
	var target: Node = _resolve_node(target_path, root)
	if target == null:
		return {"success": false, "error": "Target not found: %s" % target_path}
	if not source.has_signal(signal_name):
		return {"success": false, "error": "Signal '%s' not found on %s" % [signal_name, source_path]}
	if not target.has_method(method_name):
		return {"success": false, "error": "Method '%s' not found on %s" % [method_name, target_path]}

	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Connect signal %s.%s -> %s.%s" % [source_path, signal_name, target_path, method_name])
	ur.add_do_method(source, "connect", signal_name, Callable(target, method_name))
	ur.add_undo_method(source, "disconnect", signal_name, Callable(target, method_name))
	ur.commit_action()

	return {"success": true, "message": "Connected %s.%s -> %s.%s" % [source_path, signal_name, target_path, method_name]}


## Disconnect a signal between two nodes with UndoRedo support.
func _disconnect_signal(params: Dictionary) -> Dictionary:
	var source_path: String = params.get("source", "")
	var signal_name: String = params.get("signal", "")
	var target_path: String = params.get("target", "")
	var method_name: String = params.get("method", "")
	if signal_name.is_empty() or method_name.is_empty():
		return {"success": false, "error": "Signal name and method name are required"}

	var root: Node = _get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	var source: Node = _resolve_node(source_path, root)
	if source == null:
		return {"success": false, "error": "Source not found: %s" % source_path}
	var target: Node = _resolve_node(target_path, root)
	if target == null:
		return {"success": false, "error": "Target not found: %s" % target_path}

	var callable: Callable = Callable(target, method_name)
	if not source.is_connected(signal_name, callable):
		return {"success": false, "error": "Signal not connected: %s.%s -> %s.%s" % [source_path, signal_name, target_path, method_name]}

	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Disconnect signal")
	ur.add_do_method(source, "disconnect", signal_name, callable)
	ur.add_undo_method(source, "connect", signal_name, callable)
	ur.commit_action()

	return {"success": true, "message": "Disconnected %s.%s -> %s.%s" % [source_path, signal_name, target_path, method_name]}


## Get groups a node belongs to.
func _get_node_groups(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var root: Node = _get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"success": false, "error": "Node not found: %s" % path}

	var groups: Array = node.get_groups()
	return {"success": true, "path": path, "groups": groups}


## Set groups on a node (replaces all existing groups).
func _set_node_groups(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var groups: Array = params.get("groups", [])
	var root: Node = _get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}
	var node: Node = _resolve_node(path, root)
	if node == null:
		return {"success": false, "error": "Node not found: %s" % path}

	# Remove from all current groups
	var current_groups: Array = node.get_groups()
	for g: String in current_groups:
		node.remove_from_group(g)

	# Add to new groups
	for g_variant: Variant in groups:
		var g: String = g_variant as String
		node.add_to_group(g, true)

	return {"success": true, "message": "Groups set on %s" % path, "groups": groups}


## Find all nodes belonging to a specific group.
func _find_nodes_in_group(params: Dictionary) -> Dictionary:
	var group: String = params.get("group", "")
	if group.is_empty():
		return {"success": false, "error": "Group name is required"}
	var root: Node = _get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}

	var nodes: Array = root.get_tree().get_nodes_in_group(group)
	var results: Array = []
	for n: Node in nodes:
		results.append({
			"path": str(n.get_path()),
			"name": str(n.name),
			"type": n.get_class(),
		})
	return {"success": true, "group": group, "count": results.size(), "nodes": results}


## Get the current editor selection.
func _get_editor_selection() -> Dictionary:
	var selection: EditorSelection = _plugin.get_editor_interface().get_selection()
	var selected: Array[Node] = selection.get_selected_nodes()
	var results: Array = []
	for node: Node in selected:
		results.append({
			"path": str(node.get_path()),
			"name": str(node.name),
			"type": node.get_class(),
		})
	return {"success": true, "count": results.size(), "nodes": results}


## Select specific nodes in the editor.
func _select_nodes(params: Dictionary) -> Dictionary:
	var paths: Array = params.get("paths", [])
	var root: Node = _get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}

	var selection: EditorSelection = _plugin.get_editor_interface().get_selection()
	selection.clear()
	for p_variant: Variant in paths:
		var p: String = p_variant as String
		var node: Node = _resolve_node(p, root)
		if node:
			selection.add_node(node)
	return {"success": true, "message": "Selected %d nodes" % paths.size()}


## Clear the editor selection.
func _clear_editor_selection() -> Dictionary:
	var selection: EditorSelection = _plugin.get_editor_interface().get_selection()
	selection.clear()
	return {"success": true, "message": "Selection cleared"}


## Helper: get edited scene root.
func _get_edited_scene_root() -> Node:
	if _plugin == null:
		return null
	return _plugin.get_editor_interface().get_edited_scene_root()


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
	return root.get_node_or_null(path)


## Helper: create node by type. Tries ClassDB fallback for unknown types.
func _create_node_by_type(type_name: String) -> Node:
	match type_name:
		"Node":
			return Node.new()
		"Node2D":
			return Node2D.new()
		"Node3D":
			return Node3D.new()
		"Control":
			return Control.new()
		"Sprite2D":
			return Sprite2D.new()
		"Sprite3D":
			return Sprite3D.new()
		"MeshInstance3D":
			return MeshInstance3D.new()
		"MeshInstance2D":
			return MeshInstance2D.new()
		"Camera2D":
			return Camera2D.new()
		"Camera3D":
			return Camera3D.new()
		"StaticBody2D":
			return StaticBody2D.new()
		"StaticBody3D":
			return StaticBody3D.new()
		"CharacterBody2D":
			return CharacterBody2D.new()
		"CharacterBody3D":
			return CharacterBody3D.new()
		"RigidBody2D":
			return RigidBody2D.new()
		"RigidBody3D":
			return RigidBody3D.new()
		"Area2D":
			return Area2D.new()
		"Area3D":
			return Area3D.new()
		"Label":
			return Label.new()
		"Button":
			return Button.new()
		"TextureRect":
			return TextureRect.new()
		"ColorRect":
			return ColorRect.new()
		"VBoxContainer":
			return VBoxContainer.new()
		"HBoxContainer":
			return HBoxContainer.new()
		"MarginContainer":
			return MarginContainer.new()
		"Panel":
			return Panel.new()
		"PanelContainer":
			return PanelContainer.new()
		"CollisionShape2D":
			return CollisionShape2D.new()
		"CollisionShape3D":
			return CollisionShape3D.new()
		"AnimationPlayer":
			return AnimationPlayer.new()
		"AnimationTree":
			return AnimationTree.new()
		"TileMap":
			return TileMap.new()
		"GPUParticles2D":
			return GPUParticles2D.new()
		"GPUParticles3D":
			return GPUParticles3D.new()
		"AudioStreamPlayer":
			return AudioStreamPlayer.new()
		"AudioStreamPlayer2D":
			return AudioStreamPlayer2D.new()
		"AudioStreamPlayer3D":
			return AudioStreamPlayer3D.new()
		"DirectionalLight3D":
			return DirectionalLight3D.new()
		"OmniLight3D":
			return OmniLight3D.new()
		"SpotLight3D":
			return SpotLight3D.new()
		"SubViewport":
			return SubViewport.new()
		"SubViewportContainer":
			return SubViewportContainer.new()
		"NavigationRegion2D":
			return NavigationRegion2D.new()
		"NavigationRegion3D":
			return NavigationRegion3D.new()
		"NavigationAgent2D":
			return NavigationAgent2D.new()
		"NavigationAgent3D":
			return NavigationAgent3D.new()
		"CSGBox3D":
			return CSGBox3D.new()
		"CSGSphere3D":
			return CSGSphere3D.new()
		"CSGCylinder3D":
			return CSGCylinder3D.new()
		_:
			if ClassDB.can_instantiate(type_name):
				var obj: Object = ClassDB.instantiate(type_name)
				if obj is Node:
					return obj as Node
			return null


## Helper: check if object has a property by name.
func _has_property(obj: Object, prop: String) -> bool:
	for p: Dictionary in obj.get_property_list():
		if p["name"] as String == prop:
			return true
	return false


## Helper: get the Variant type of a property.
func _get_property_type(obj: Object, prop: String) -> int:
	for p: Dictionary in obj.get_property_list():
		if p["name"] as String == prop:
			return p["type"] as int
	return TYPE_NIL


## Helper: resolve a preset value (string name or int) to Control.LayoutPreset int.
func _resolve_preset(raw) -> int:
	if raw is int:
		return raw
	if raw is float:
		return int(raw)
	if raw is String:
		var mapping: Dictionary = {
			"top_left": 0, "top_right": 1, "bottom_left": 2, "bottom_right": 3,
			"center_left": 4, "center_top": 5, "center_right": 6, "center_bottom": 7,
			"center": 8, "left_wide": 9, "top_wide": 10, "right_wide": 11,
			"bottom_wide": 12, "vcenter_wide": 13, "hcenter_wide": 14, "full_rect": 15,
		}
		var lower: String = raw.to_lower()
		if mapping.has(lower):
			return mapping[lower]
		# Try parsing as int string
		if raw.is_valid_int():
			return raw.to_int()
	return 0
