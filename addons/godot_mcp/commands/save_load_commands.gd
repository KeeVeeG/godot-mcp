## Save/Load commands module - 5 tools.
## Provides game state save/load testing, save file management,
## and save state comparison for verifying save system integrity.
@tool
class_name MCPSaveLoadCommands
extends RefCounted

var _plugin: EditorPlugin

## Base directory for save files
const SAVE_DIR: String = "user://mcp_saves/"
## Save file extension
const SAVE_EXT: String = ".save"
## Metadata file extension
const META_EXT: String = ".meta.json"


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func get_commands() -> Dictionary:
	return {
		"save_game_state": save_game_state,
		"load_game_state": load_game_state,
		"list_save_files": list_save_files,
		"delete_save_file": delete_save_file,
		"compare_save_states": compare_save_states,
	}


## Ensure the save directory exists. Returns OK on success, error code on failure.
func _ensure_save_dir() -> Error:
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		return OK
	var err: Error = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if err != OK:
		return err
	# Verify it was actually created
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		return ERR_CANT_CREATE
	return OK


## Get the save file path for a slot.
func _save_path(slot: int) -> String:
	return SAVE_DIR + "slot_%02d%s" % [slot, SAVE_EXT]


## Get the metadata file path for a slot.
func _meta_path(slot: int) -> String:
	return SAVE_DIR + "slot_%02d%s" % [slot, META_EXT]


## Check if a real scene is open (not a null root or auto-created empty scene).
## Guard 0 (D4 workaround): plugin tracks logical close_scene() calls via
##   notify_scene_closed/notify_scene_opened because Godot 4 does NOT clear
##   get_edited_scene_root(), get_open_scenes(), scene_file_path, or
##   is_inside_tree() after close_scene().
## Guards 1-4: API-based fallback for cases where the user closes a scene
##   via the Godot UI instead of the MCP godot_close_scene tool.
func _is_scene_open(root: Node) -> bool:
	# Guard 0: logical state tracking (catches godot_close_scene calls).
	if _plugin.has_method("is_scene_logically_open") and not _plugin.is_scene_logically_open():
		return false
	# Guards 1-4: API-based fallback.
	if root == null:
		return false
	if root.scene_file_path.is_empty():
		return false
	if not root.is_inside_tree():
		return false
	var open_scenes: PackedStringArray = _plugin.get_editor_interface().get_open_scenes()
	for path in open_scenes:
		if not path.is_empty() and path == root.scene_file_path:
			return true
	return false


## Resolve the authoritative scene path for the currently edited scene.
## Uses get_open_scenes() (which reads EditedScene.path) as the primary source
## because EditorData::get_scene_path() can mutate Node.scene_file_path with
## stale data from a previously-edited tab (Godot engine side-effect).
func _resolve_scene_path(root: Node) -> String:
	var root_path: String = root.scene_file_path
	var open_scenes: PackedStringArray = _plugin.get_editor_interface().get_open_scenes()

	# Collect non-empty open scene paths
	var valid_paths: Array = []
	for path: String in open_scenes:
		if not path.is_empty():
			valid_paths.append(path)

	# If root's path matches an open scene, it's authoritative
	if not root_path.is_empty() and root_path in valid_paths:
		return root_path

	# Root path is empty or mismatched � use get_open_scenes() data
	if valid_paths.size() > 0:
		if not root_path.is_empty():
			push_warning("save_load: root.scene_file_path '%s' differs from open_scenes %s. Using open_scenes path." % [root_path, str(valid_paths)])
		return valid_paths[0]

	# No open saved scenes � fall back to root path (may be empty/"unknown")
	if not root_path.is_empty():
		push_warning("save_load: root.scene_file_path '%s' not found in open_scenes (empty). Using anyway." % root_path)
	return root_path


## Save the current game state to a numbered slot.
## Captures the scene tree structure, node properties, and optional metadata.
func save_game_state(params: Dictionary) -> Dictionary:
	var slot: int = params.get("slot", 0)
	var metadata: Dictionary = params.get("metadata", {})

	var dir_err: Error = _ensure_save_dir()
	if dir_err != OK:
		return {"error": "Failed to create save directory '%s': %s (code %d)" % [SAVE_DIR, error_string(dir_err), dir_err]}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if not _is_scene_open(root):
		return {"error": "No scene open to save"}

	# Build the save data structure
	var scene_path: String = _resolve_scene_path(root)
	var save_data: Dictionary = {
		"version": 1,
		"timestamp": Time.get_unix_time_from_system(),
		"timestamp_human": Time.get_datetime_string_from_system(),
		"scene_path": scene_path if not scene_path.is_empty() else "unknown",
		"metadata": metadata,
		"scene_tree": _serialize_node_tree(root),
	}

	# Write save file
	var save_file_path: String = _save_path(slot)
	var file: FileAccess = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file == null:
		var err_code: int = FileAccess.get_open_error()
		return {"error": "Failed to open save file '%s' for writing: %s (code %d)" % [save_file_path, error_string(err_code), err_code]}
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

	# Write metadata file separately for quick listing
	var meta_data: Dictionary = {
		"slot": slot,
		"timestamp": save_data["timestamp"],
		"timestamp_human": save_data["timestamp_human"],
		"scene_path": save_data["scene_path"],
		"file_size": FileAccess.get_file_as_bytes(save_file_path).size(),
		"metadata": metadata,
	}
	var meta_file: FileAccess = FileAccess.open(_meta_path(slot), FileAccess.WRITE)
	if meta_file != null:
		meta_file.store_string(JSON.stringify(meta_data, "\t"))
		meta_file.close()

	# NOTE: node_count relies on get_edited_scene_root().get_children().
	# In rare edge cases (engine timing after scene switches), the root may
	# temporarily retain children from a previous scene, inflating the count.
	# This does not affect save-file integrity � the serialized tree reflects
	# whatever nodes are present at save time.
	return {"result": {
		"success": true,
		"slot": slot,
		"path": save_file_path,
		"timestamp": save_data["timestamp_human"],
		"node_count": MCPCommandHelpers.count_nodes(root),
		"metadata": metadata,
		"message": "Game state saved to slot %d" % slot,
	}}


## Load a game state from a numbered slot.
## Restores the scene tree structure and node properties.
func load_game_state(params: Dictionary) -> Dictionary:
	var slot: int = params.get("slot", 0)

	var save_file_path: String = _save_path(slot)
	if not FileAccess.file_exists(save_file_path):
		return {"error": "No save file found in slot %d" % slot}

	var file: FileAccess = FileAccess.open(save_file_path, FileAccess.READ)
	if file == null:
		return {"error": "Failed to open save file: %s" % error_string(FileAccess.get_open_error())}
	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var err: Error = json.parse(json_text)
	if err != OK:
		return {"error": "Failed to parse save file: %s" % json.get_error_message()}

	var save_data: Dictionary = json.data as Dictionary
	if save_data == null:
		return {"error": "Invalid save file format"}

	var version: int = save_data.get("version", 0)
	if version < 1:
		return {"error": "Unsupported save file version: %d" % version}

	# Restore the scene tree
	var scene_tree_data: Dictionary = save_data.get("scene_tree", {})
	if scene_tree_data.is_empty():
		return {"error": "Save file contains no scene tree data"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if not _is_scene_open(root):
		return {"error": "No scene open to load into"}

	# Apply saved state to existing tree
	var restored_count: int = _restore_node_tree(root, scene_tree_data)

	return {"result": {
		"success": true,
		"slot": slot,
		"timestamp": save_data.get("timestamp_human", "unknown"),
		"scene_path": save_data.get("scene_path", "unknown"),
		"restored_nodes": restored_count,
		"metadata": save_data.get("metadata", {}),
		"message": "Game state loaded from slot %d (%d nodes restored)" % [slot, restored_count],
	}}


## List all save files with their metadata.
func list_save_files(_params: Dictionary) -> Dictionary:
	_ensure_save_dir()

	var saves: Array = []
	var dir: DirAccess = DirAccess.open(SAVE_DIR)
	if dir == null:
		return {"result": {"saves": [], "count": 0}}

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(META_EXT):
			var meta_path: String = SAVE_DIR + file_name
			var file: FileAccess = FileAccess.open(meta_path, FileAccess.READ)
			if file != null:
				var json_text: String = file.get_as_text()
				file.close()
				var json: JSON = JSON.new()
				if json.parse(json_text) == OK and json.data is Dictionary:
					saves.append(json.data)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Sort by slot number
	saves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("slot", 0) < b.get("slot", 0)
	)

	return {"result": {
		"count": saves.size(),
		"saves": saves,
	}}


## Delete a save file from a specific slot.
func delete_save_file(params: Dictionary) -> Dictionary:
	var slot: int = params.get("slot", 0)

	var save_file_path: String = _save_path(slot)
	var meta_file_path: String = _meta_path(slot)

	var save_exists: bool = FileAccess.file_exists(save_file_path)
	var meta_exists: bool = FileAccess.file_exists(meta_file_path)

	if not save_exists and not meta_exists:
		return {"result": {
			"success": true,
			"slot": slot,
			"deleted_files": [],
			"message": "Save slot %d was already empty" % slot,
		}}

	var deleted: Array = []
	if save_exists:
		DirAccess.remove_absolute(save_file_path)
		deleted.append(save_file_path)
	if meta_exists:
		DirAccess.remove_absolute(meta_file_path)
		deleted.append(meta_file_path)

	return {"result": {
		"success": true,
		"slot": slot,
		"deleted_files": deleted,
		"message": "Save slot %d deleted" % slot,
	}}


## Compare two save states and return a diff of their contents.
func compare_save_states(params: Dictionary) -> Dictionary:
	var slot_a: int = params.get("slot_a", 0)
	var slot_b: int = params.get("slot_b", 1)

	var data_a: Dictionary = _load_save_data(slot_a)
	if data_a.is_empty():
		return {"error": "No save file found in slot %d" % slot_a}

	var data_b: Dictionary = _load_save_data(slot_b)
	if data_b.is_empty():
		return {"error": "No save file found in slot %d" % slot_b}

	# Compare metadata
	var meta_diff: Dictionary = _diff_dictionaries(
		data_a.get("metadata", {}),
		data_b.get("metadata", {})
	)

	# Compare scene trees
	var tree_a: Dictionary = data_a.get("scene_tree", {})
	var tree_b: Dictionary = data_b.get("scene_tree", {})
	var tree_diff: Dictionary = _diff_node_trees(tree_a, tree_b)

	return {"result": {
		"slot_a": slot_a,
		"slot_b": slot_b,
		"timestamp_a": data_a.get("timestamp_human", "unknown"),
		"timestamp_b": data_b.get("timestamp_human", "unknown"),
		"metadata_diff": meta_diff,
		"scene_diff": tree_diff,
		"identical": meta_diff.is_empty() and tree_diff.get("identical", false),
	}}








## Helper: Serialize a node tree to a dictionary.
func _serialize_node_tree(node: Node) -> Dictionary:
	var data: Dictionary = {
		"name": node.name,
		"type": node.get_class(),
		"properties": {},
		"children": [],
	}

	# Serialize key properties
	var prop_list: Array = node.get_property_list()
	for prop_info: Dictionary in prop_list:
		var prop_name: String = prop_info["name"] as String
		var usage: int = prop_info["usage"] as int
		# Only serialize stored, editor-visible properties
		if (usage & PROPERTY_USAGE_STORAGE) != 0 and (usage & PROPERTY_USAGE_EDITOR) != 0:
			var value: Variant = node.get(prop_name)
			if value != null and _is_serializable(value):
				# Use MCPVariantCodec for consistent serialization of complex types
				data["properties"][prop_name] = MCPVariantCodec.serialize_value(value)

	# Recursively serialize children
	for child: Node in node.get_children():
		data["children"].append(_serialize_node_tree(child))

	return data


## Helper: Restore node properties from saved data with type verification.
func _restore_node_tree(node: Node, data: Dictionary) -> int:
	var count: int = 1

	var properties: Dictionary = data.get("properties", {})
	for prop_name: String in properties:
		if MCPCommandHelpers.has_property(node, prop_name):
			var prop_type: int = MCPCommandHelpers.get_property_type(node, prop_name)
			var value: Variant = MCPVariantCodec.parse_for_property(properties[prop_name], prop_type)
			node.set(prop_name, value)

	var children_data: Array = data.get("children", [])
	var existing_children: Array = node.get_children()
	for i: int in range(min(children_data.size(), existing_children.size())):
		var child_data: Dictionary = children_data[i] as Dictionary
		var child: Node = existing_children[i]
		if child.name == child_data.get("name", ""):
			count += _restore_node_tree(child, child_data)

	return count


## Helper: Check if a value is JSON-serializable.
func _is_serializable(value: Variant) -> bool:
	if value is bool or value is int or value is float or value is String:
		return true
	if value is Vector2 or value is Vector3 or value is Color:
		return true
	if value is Array or value is Dictionary:
		return true
	if value is Transform2D or value is Transform3D:
		return true
	return false





## Helper: Load save data from a slot.
func _load_save_data(slot: int) -> Dictionary:
	var path: String = _save_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json_text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(json_text) != OK:
		return {}
	return json.data as Dictionary if json.data is Dictionary else {}


## Helper: Diff two dictionaries, returning keys that differ.
func _diff_dictionaries(a: Dictionary, b: Dictionary) -> Dictionary:
	var diff: Dictionary = {}
	var all_keys: Dictionary = {}
	for k in a:
		all_keys[k] = true
	for k in b:
		all_keys[k] = true
	for k in all_keys:
		var key: String = str(k)
		var in_a: bool = a.has(key)
		var in_b: bool = b.has(key)
		if not in_a:
			diff[key] = {"status": "added_in_b", "value": b[key]}
		elif not in_b:
			diff[key] = {"status": "removed_from_a", "value": a[key]}
		elif str(a[key]) != str(b[key]):
			diff[key] = {"status": "changed", "value_a": a[key], "value_b": b[key]}
	return diff


## Helper: Diff two node trees recursively.
func _diff_node_trees(a: Dictionary, b: Dictionary) -> Dictionary:
	var differences: Array = []

	if a.get("name", "") != b.get("name", ""):
		differences.append({"type": "name_changed", "a": a.get("name"), "b": b.get("name")})
	if a.get("type", "") != b.get("type", ""):
		differences.append({"type": "type_changed", "a": a.get("type"), "b": b.get("type")})

	# Compare properties
	var props_a: Dictionary = a.get("properties", {})
	var props_b: Dictionary = b.get("properties", {})
	var prop_diff: Dictionary = _diff_dictionaries(props_a, props_b)
	if not prop_diff.is_empty():
		differences.append({"type": "properties_changed", "node": a.get("name", ""), "diff": prop_diff})

	# Compare children count
	var children_a: Array = a.get("children", [])
	var children_b: Array = b.get("children", [])
	if children_a.size() != children_b.size():
		differences.append({"type": "children_count_changed", "node": a.get("name", ""), "count_a": children_a.size(), "count_b": children_b.size()})

	# Recursively compare matching children
	for i: int in range(min(children_a.size(), children_b.size())):
		var child_diff: Dictionary = _diff_node_trees(children_a[i] as Dictionary, children_b[i] as Dictionary)
		if not child_diff.get("identical", true):
			differences.append_array(child_diff.get("differences", []))

	return {
		"identical": differences.is_empty(),
		"differences": differences,
	}
