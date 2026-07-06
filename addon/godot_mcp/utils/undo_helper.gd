## UndoRedo helper wrapper for Godot editor mutations.
## All scene modifications should go through this helper
## to ensure proper undo/redo support.
class_name MCUndoHelper
extends RefCounted

## Reference to the EditorPlugin
var _plugin: EditorPlugin

## Reference to the EditorUndoRedoManager
var _undo_redo_manager: EditorUndoRedoManager


func _init(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_undo_redo_manager = plugin.get_undo_redo()


## Add a node to the scene tree with undo support.
func add_node_with_undo(node: Node, parent: Node) -> void:
	var ur: EditorUndoRedoManager = _undo_redo_manager
	ur.create_action("MCP: Add node %s" % node.name)
	ur.add_do_method(parent, "add_child", node)
	ur.add_do_method(node, "set_owner", _get_edited_scene_root())
	ur.add_undo_method(parent, "remove_child", node)
	ur.commit_action()


## Remove a node from the scene tree with undo support.
func remove_node_with_undo(node: Node) -> void:
	var parent: Node = node.get_parent()
	if parent == null:
		return
	var ur: EditorUndoRedoManager = _undo_redo_manager
	ur.create_action("MCP: Remove node %s" % node.name)
	ur.add_do_method(parent, "remove_child", node)
	ur.add_undo_method(parent, "add_child", node)
	ur.add_undo_method(node, "set_owner", _get_edited_scene_root())
	ur.commit_action()


## Set a property on a node with undo support.
func set_property_with_undo(obj: Object, property: StringName, value: Variant) -> void:
	var old_value: Variant = obj.get(property)
	var ur: EditorUndoRedoManager = _undo_redo_manager
	ur.create_action("MCP: Set %s.%s" % [obj, property])
	ur.add_do_property(obj, property, value)
	ur.add_undo_property(obj, property, old_value)
	ur.commit_action()


## Call a method on an object with undo support (forward and reverse).
func call_method_with_undo(obj: Object, method: StringName, do_args: Array = [], undo_method: StringName = &"", undo_args: Array = []) -> void:
	var ur: EditorUndoRedoManager = _undo_redo_manager
	ur.create_action("MCP: Call %s.%s" % [obj, method])
	ur.add_do_method(obj, method, do_args)
	if undo_method != StringName(""):
		ur.add_undo_method(obj, undo_method, undo_args)
	ur.commit_action()


## Get the currently edited scene root.
func _get_edited_scene_root() -> Node:
	return _plugin.get_editor_interface().get_edited_scene_root()


## Rename a node with undo support.
func rename_node_with_undo(node: Node, new_name: String) -> void:
	var old_name: String = node.name
	var ur: EditorUndoRedoManager = _undo_redo_manager
	ur.create_action("MCP: Rename node %s to %s" % [old_name, new_name])
	ur.add_do_property(node, "name", new_name)
	ur.add_undo_property(node, "name", old_name)
	ur.commit_action()


## Move a node to a new parent with undo support.
func move_node_with_undo(node: Node, new_parent: Node, index: int = -1) -> void:
	var old_parent: Node = node.get_parent()
	var old_index: int = node.get_index()
	var ur: EditorUndoRedoManager = _undo_redo_manager
	ur.create_action("MCP: Move node %s" % node.name)
	ur.add_do_method(old_parent, "remove_child", node)
	ur.add_do_method(new_parent, "add_child", node)
	if index >= 0:
		ur.add_do_method(new_parent, "move_child", node, index)
	ur.add_undo_method(new_parent, "remove_child", node)
	ur.add_undo_method(old_parent, "add_child", node)
	if old_index >= 0:
		ur.add_undo_method(old_parent, "move_child", node, old_index)
	ur.commit_action()


## Duplicate a node with undo support. Returns the new node.
func duplicate_node_with_undo(node: Node) -> Node:
	var parent: Node = node.get_parent()
	if parent == null:
		return null
	var dupe: Node = node.duplicate()
	if dupe == null:
		return null
	var ur: EditorUndoRedoManager = _undo_redo_manager
	ur.create_action("MCP: Duplicate node %s" % node.name)
	ur.add_do_method(parent, "add_child", dupe)
	ur.add_do_method(dupe, "set_owner", _get_edited_scene_root())
	ur.add_undo_method(parent, "remove_child", dupe)
	ur.commit_action()
	return dupe


## Batch set multiple properties with a single undo action.
func batch_set_properties(obj: Object, properties: Dictionary) -> void:
	var ur: EditorUndoRedoManager = _undo_redo_manager
	ur.create_action("MCP: Batch set properties on %s" % obj)
	for prop: StringName in properties:
		var old_val: Variant = obj.get(prop)
		var new_val: Variant = properties[prop]
		ur.add_do_property(obj, prop, new_val)
		ur.add_undo_property(obj, prop, old_val)
	ur.commit_action()


## Commit a pending action. Call this after using create_action + add_do_*
## methods directly on the EditorUndoRedoManager.
func commit_action(action_name: String) -> void:
	var ur: EditorUndoRedoManager = _undo_redo_manager
	ur.create_action(action_name)
	ur.commit_action()


## Get the underlying EditorUndoRedoManager for advanced usage.
func get_undo_redo_manager() -> EditorUndoRedoManager:
	return _undo_redo_manager
