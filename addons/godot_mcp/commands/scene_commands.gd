## Scene commands module - 13 tools.
## Handles scene tree, file operations, play/stop, and instancing.
class_name MCPSceneCommands
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
		"scene/get_tree": func(params: Dictionary) -> Dictionary: return execute("get_scene_tree", params),
		"scene/get_file_content": func(params: Dictionary) -> Dictionary: return execute("get_scene_file_content", params),
		"scene/create": func(params: Dictionary) -> Dictionary: return execute("create_scene", params),
		"scene/open": func(params: Dictionary) -> Dictionary: return execute("open_scene", params),
		"scene/delete": func(params: Dictionary) -> Dictionary: return execute("delete_scene", params),
		"scene/add_instance": func(params: Dictionary) -> Dictionary: return execute("add_scene_instance", params),
		"scene/play": func(params: Dictionary) -> Dictionary: return execute("play_scene", params),
		"scene/stop": func(params: Dictionary) -> Dictionary: return execute("stop_scene", params),
		"scene/save": func(params: Dictionary) -> Dictionary: return execute("save_scene", params),
		"scene/get_loaded": func(params: Dictionary) -> Dictionary: return execute("get_loaded_scenes", params),
		"scene/set_main": func(params: Dictionary) -> Dictionary: return execute("set_main_scene", params),
		"scene/get_main": func(params: Dictionary) -> Dictionary: return execute("get_main_scene", params),
		"scene/close": func(params: Dictionary) -> Dictionary: return execute("close_scene", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_scene_tree": return _get_scene_tree(params)
		"get_scene_file_content": return _get_scene_file_content(params)
		"create_scene": return _create_scene(params)
		"open_scene": return _open_scene(params)
		"delete_scene": return _delete_scene(params)
		"add_scene_instance": return _add_scene_instance(params)
		"play_scene": return _play_scene(params)
		"stop_scene": return _stop_scene()
		"save_scene": return _save_scene(params)
		"get_loaded_scenes": return _get_loaded_scenes()
		"set_main_scene": return _set_main_scene(params)
		"get_main_scene": return _get_main_scene(params)
		"close_scene": return _close_scene()
	return {"error": "Unknown method: " + method}


## Get live scene hierarchy from the edited scene root.
func _get_scene_tree(params: Dictionary) -> Dictionary:
	var root: Node = MCPCommandHelpers.get_edited_scene_root(_plugin)
	if root == null:
		return {"result": {"tree": null, "message": "No scene open"}}
	var max_depth: int = params.get("max_depth", 15)
	var tree: Dictionary = _serialize_node(root, 0, max_depth)
	return {"result": {"tree": tree}}


func _serialize_node(node: Node, depth: int, max_depth: int) -> Dictionary:
	var result: Dictionary = {
		"name": str(node.name),
		"type": node.get_class(),
		"path": MCPCommandHelpers.get_node_path(node, _plugin),
		"unique_name_in_owner": node.unique_name_in_owner,
		"children": [],
	}
	if node is Node2D:
		var n2d: Node2D = node as Node2D
		result["position"] = {"x": n2d.position.x, "y": n2d.position.y}
		result["visible"] = n2d.visible
	elif node is Node3D:
		var n3d: Node3D = node as Node3D
		var pos: Vector3 = n3d.position
		result["position"] = {"x": pos.x, "y": pos.y, "z": pos.z}
		result["visible"] = n3d.visible
	elif node is Control:
		var ctrl: Control = node as Control
		result["position"] = {"x": ctrl.position.x, "y": ctrl.position.y}
		result["size"] = {"x": ctrl.size.x, "y": ctrl.size.y}
		result["visible"] = ctrl.visible

	# Add script info
	var scr: Script = node.get_script()
	if scr:
		result["script"] = scr.resource_path

	if depth < max_depth:
		for child: Node in node.get_children():
			result["children"].append(_serialize_node(child, depth + 1, max_depth))
	return result


## Get raw .tscn file content.
func _get_scene_file_content(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required — empty string is not a valid scene path"}
	if not FileAccess.file_exists(path):
		return {"error": "Scene file not found: %s" % path}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "Cannot read scene file: %s" % path}
	var content: String = file.get_as_text()
	file.close()
	return {"result": {"path": path, "content": content}}


## Create a new scene with a specified root type and save to disk.
func _create_scene(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var root_type: String = params.get("root_node_type", params.get("root_type", "Node"))
	if path.is_empty():
		return {"error": "Path is required"}

	# Check for overwrite
	var overwrite: bool = params.get("overwrite", false)
	if FileAccess.file_exists(path) and not overwrite:
		return {"error": "Scene file already exists: %s. Use overwrite=true to replace." % path}

	# Create the root node
	var root_node: Node = MCPNodeFactory.create_node(root_type)
	if root_node == null:
		return {"error": "Unknown node type: %s" % root_type}
	root_node.name = root_type

	# Pack it into a scene
	var scene: PackedScene = PackedScene.new()
	var err: Error = scene.pack(root_node)
	if err != OK:
		root_node.queue_free()
		return {"error": "Failed to pack scene: %s" % error_string(err)}
	root_node.queue_free()

	# Ensure parent directory exists
	MCPCommandHelpers.ensure_dir(path.get_base_dir())

	# Save to disk
	err = ResourceSaver.save(scene, path)
	if err != OK:
		return {"error": "Failed to save scene: %s" % error_string(err)}

	return {"result": {"path": path, "root_type": root_type}}


## Open a scene in the editor.
func _open_scene(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	if not FileAccess.file_exists(path):
		return {"error": "Scene file not found: %s" % path}
	_plugin.get_editor_interface().open_scene_from_path(path)
	# Verify the scene actually loaded.
	# open_scene_from_path silently drops the call if is_changing_scene() is true
	# (e.g. if a previous scene change is still in progress). Return an explicit
	# error so the client can retry instead of operating on a stale scene.
	var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return {"error": "Failed to open scene: no scene root loaded"}
	if root.scene_file_path != path:
		return {"error": "Failed to open scene: editor is showing '%s' instead of '%s'. A scene change may be in progress — close the current scene first." % [root.scene_file_path, path]}
	return {"result": {"message": "Scene opened: %s" % path}}


## Close the currently edited scene in the editor.
func _close_scene(_params: Dictionary = {}) -> Dictionary:
	_plugin.get_editor_interface().close_scene()
	return {"result": {"message": "Scene closed"}}


## Delete a scene file from disk.
func _delete_scene(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var force: bool = params.get("force", false)
	if path.is_empty():
		return {"error": "Path is required"}
	if not FileAccess.file_exists(path):
		return {"error": "Scene file not found: %s" % path}
	
	# Check if scene is currently open and close it if force=true
	var open_scenes: PackedStringArray = _plugin.get_editor_interface().get_open_scenes()
	if path in open_scenes:
		if not force:
			return {"error": "Scene is currently open. Use force=true to close and delete: %s" % path}
		# Close the scene by opening a different one
		var root: Node = MCPCommandHelpers.get_edited_scene_root(_plugin)
		if root != null and root.scene_file_path == path:
			_plugin.get_editor_interface().close_scene()
	
	var err: Error = DirAccess.remove_absolute(path)
	if err != OK:
		return {"error": "Failed to delete scene: %s" % error_string(err)}
	# Also delete .import file if exists
	var import_path: String = path + ".import"
	if FileAccess.file_exists(import_path):
		DirAccess.remove_absolute(import_path)
	_plugin.safe_scan_filesystem()
	return {"result": {"message": "Scene deleted: %s" % path}}


## Instance a scene into the current scene tree.
func _add_scene_instance(params: Dictionary) -> Dictionary:
	var path: String = params.get("scene_path", params.get("path", ""))
	var parent_path: String = params.get("parent_path", "")
	if path.is_empty():
		return {"error": "Scene path is required"}
	if not FileAccess.file_exists(path):
		return {"error": "Scene file not found: %s" % path}

	var scene_res: PackedScene = ResourceLoader.load(path) as PackedScene
	if scene_res == null:
		return {"error": "Failed to load scene: %s" % path}

	var instance: Node = scene_res.instantiate()
	if instance == null:
		return {"error": "Failed to instantiate scene"}

	var parent: Node = MCPCommandHelpers.get_edited_scene_root(_plugin)
	if parent == null:
		instance.queue_free()
		return {"error": "No scene open"}
	if parent_path != "":
		parent = MCPCommandHelpers.resolve_node_path(_plugin, parent_path)
		if parent == null:
			instance.queue_free()
			return {"error": "Parent node not found: %s" % parent_path}

	if _undo_helper:
		_undo_helper.add_node_with_undo(instance, parent)
	else:
		parent.add_child(instance)
		instance.set_owner(MCPCommandHelpers.get_edited_scene_root(_plugin))

	return {"result": {"path": path, "instance_name": str(instance.name), "parent": MCPCommandHelpers.get_node_path(parent, _plugin)}}


## Play the game scene (main, current, or custom).
func _play_scene(params: Dictionary) -> Dictionary:
	var mode: String = params.get("mode", "current")
	var scene_path: String = params.get("scene_path", "")
	match mode:
		"main":
			var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
			if main_scene.is_empty():
				return {"error": "No main scene configured. Set one with set_main_scene first."}
			if not FileAccess.file_exists(main_scene):
				return {"error": "Main scene file not found: %s" % main_scene}
			_plugin.get_editor_interface().play_main_scene()
		"current":
			_plugin.get_editor_interface().play_current_scene()
		"custom":
			if scene_path.is_empty():
				return {"error": "scene_path required for custom mode"}
			if not FileAccess.file_exists(scene_path):
				return {"error": "Scene file not found: %s" % scene_path}
			_plugin.get_editor_interface().play_custom_scene(scene_path)
		_:
			_plugin.get_editor_interface().play_current_scene()
	return {"result": {"message": "Playing scene (mode: %s)" % mode}}


## Stop the running scene.
func _stop_scene() -> Dictionary:
	_plugin.get_editor_interface().stop_playing_scene()
	return {"result": {"message": "Scene stopped"}}


## Save the current scene to disk (optionally to a new path).
func _save_scene(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var root: Node = MCPCommandHelpers.get_edited_scene_root(_plugin)
	if root == null:
		return {"error": "No scene to save"}
	if path.is_empty():
		path = root.scene_file_path
	if path.is_empty():
		return {"error": "No path specified and scene has no file path"}

	# Reject save-as if target path differs from original and not explicitly allowed
	var original_path: String = root.scene_file_path
	if original_path != "" and original_path != path and not params.get("save_as", false):
		return {"error": "Cannot save to a different path (%s). Scene was loaded from %s. Use save_as=true to save a copy." % [path, original_path]}

	var scene: PackedScene = PackedScene.new()
	var err: Error = scene.pack(root)
	if err != OK:
		return {"error": "Failed to pack scene: %s" % error_string(err)}
	err = ResourceSaver.save(scene, path)
	if err != OK:
		return {"error": "Failed to save scene: %s" % error_string(err)}
	return {"result": {"message": "Scene saved: %s" % path}}


## Get all currently loaded/open scenes in the editor.
func _get_loaded_scenes() -> Dictionary:
	var scenes: Array = []
	var open_scenes: PackedStringArray = _plugin.get_editor_interface().get_open_scenes()
	for scene_path: String in open_scenes:
		if scene_path.is_empty():
			continue
		scenes.append({"path": scene_path})
	# Also include the currently edited scene
	var root: Node = MCPCommandHelpers.get_edited_scene_root(_plugin)
	if root != null and root.scene_file_path != "":
		var current_path: String = root.scene_file_path
		var already_listed: bool = false
		for s: Dictionary in scenes:
			if s["path"] == current_path:
				already_listed = true
				break
		if not already_listed:
			scenes.append({"path": current_path, "active": true})
	return {"result": {"scenes": scenes, "count": scenes.size()}}


## Get the project's main scene path.
func _get_main_scene(_params: Dictionary) -> Dictionary:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	return {"result": {"path": main_scene}}


## Set the project's main scene.
func _set_main_scene(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	if not FileAccess.file_exists(path):
		return {"error": "Scene file not found: %s" % path}
	ProjectSettings.set_setting("application/run/main_scene", path)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"error": "Failed to save project settings: %s" % error_string(err)}
	return {"result": {"path": path, "message": "Main scene set to: %s" % path}}
