## Analysis commands module - 4 tools.
## Provides scene complexity analysis, signal flow mapping,
## unused resource detection, and project statistics.
class_name MCPAnalysisCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func get_commands() -> Dictionary:
	return {
		"analysis/scene_complexity": analyze_scene_complexity,
		"analysis/signal_flow": analyze_signal_flow,
		"analysis/unused_resources": find_unused_resources,
		"analysis/statistics": get_project_statistics,
	}


## Analyze the current scene's complexity: node count, type breakdown,
## estimated draw calls, script count, and depth.
func analyze_scene_complexity(_params: Dictionary) -> Dictionary:
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var stats: Dictionary = {
		"total_nodes": 0,
		"max_depth": 0,
		"script_count": 0,
		"texture_count": 0,
		"mesh_count": 0,
		"light_count": 0,
		"physics_body_count": 0,
		"audio_player_count": 0,
		"particle_count": 0,
		"control_count": 0,
		"estimated_draw_calls": 0,
		"type_breakdown": {},
	}
	_analyze_node_recursive(root, 0, stats)

	# Estimate draw calls: each visual element roughly = 1 draw call
	stats["estimated_draw_calls"] = stats["texture_count"] + stats["mesh_count"] + stats["light_count"] + stats["particle_count"]

	return {"result": stats}


func _analyze_node_recursive(node: Node, depth: int, stats: Dictionary) -> void:
	stats["total_nodes"] = (stats["total_nodes"] as int) + 1
	if depth > (stats["max_depth"] as int):
		stats["max_depth"] = depth

	# Count by type
	var type_name: String = node.get_class()
	var breakdown: Dictionary = stats["type_breakdown"] as Dictionary
	breakdown[type_name] = (breakdown.get(type_name, 0) as int) + 1

	# Scripts
	if node.get_script() != null:
		stats["script_count"] = (stats["script_count"] as int) + 1

	# Textures (Sprite2D, TextureRect, etc.)
	if node is Sprite2D or node is TextureRect or node is Sprite3D:
		stats["texture_count"] = (stats["texture_count"] as int) + 1

	# Meshes
	if node is MeshInstance3D or node is MeshInstance2D:
		stats["mesh_count"] = (stats["mesh_count"] as int) + 1

	# Lights
	if node is Light3D or node is Light2D:
		stats["light_count"] = (stats["light_count"] as int) + 1

	# Physics bodies
	if node is PhysicsBody2D or node is PhysicsBody3D or node is StaticBody2D or node is StaticBody3D or node is RigidBody2D or node is RigidBody3D or node is CharacterBody2D or node is CharacterBody3D:
		stats["physics_body_count"] = (stats["physics_body_count"] as int) + 1

	# Audio
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		stats["audio_player_count"] = (stats["audio_player_count"] as int) + 1

	# Particles
	if node is GPUParticles2D or node is GPUParticles3D or node is CPUParticles2D or node is CPUParticles3D:
		stats["particle_count"] = (stats["particle_count"] as int) + 1

	# UI Controls
	if node is Control:
		stats["control_count"] = (stats["control_count"] as int) + 1

	for child: Node in node.get_children():
		_analyze_node_recursive(child, depth + 1, stats)


## Map all signal connections in the scene as a graph.
func analyze_signal_flow(_params: Dictionary) -> Dictionary:
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var nodes: Array = []
	var edges: Array = []
	var node_set: Dictionary = {}

	_analyze_signals_recursive(root, nodes, edges, node_set)

	var truncated: bool = nodes.size() >= 25 or edges.size() >= 50
	var result_dict: Dictionary = {
		"node_count": nodes.size(),
		"connection_count": edges.size(),
		"nodes": nodes,
		"connections": edges,
	}
	if truncated:
		result_dict["truncated"] = true
		result_dict["warning"] = "Results truncated at %d nodes / %d edges. Large scenes may have more connections." % [nodes.size(), edges.size()]

	return {"result": result_dict}


func _analyze_signals_recursive(node: Node, nodes: Array, edges: Array, node_set: Dictionary) -> void:
	# Limit to avoid WebSocket buffer overflow
	if nodes.size() >= 25 or edges.size() >= 50:
		return
	var node_path: String = str(node.get_path())
	if not node_set.has(node_path):
		node_set[node_path] = true
		nodes.append({
			"path": node_path,
			"name": str(node.name),
			"type": node.get_class(),
		})

	var signal_list: Array = node.get_signal_list()
	for sig_info: Dictionary in signal_list:
		if edges.size() >= 50:
			break
		var sig_name: String = sig_info["name"] as String
		var connections: Array = node.get_signal_connection_list(sig_name)
		for conn: Dictionary in connections:
			if edges.size() >= 50:
				break
			var callable: Callable = conn["callable"] as Callable
			var target: Object = callable.get_object()
			var target_path: String = ""
			var target_type: String = ""
			if target is Node:
				var target_node: Node = target as Node
				target_path = str(target_node.get_path())
				target_type = target_node.get_class()
				if not node_set.has(target_path):
					node_set[target_path] = true
					nodes.append({
						"path": target_path,
						"name": str(target_node.name),
						"type": target_type,
					})
			edges.append({
				"from": node_path,
				"signal": sig_name,
				"to": target_path,
				"method": str(callable.get_method()),
			})

	for child: Node in node.get_children():
		if nodes.size() >= 50 or edges.size() >= 100:
			return
		_analyze_signals_recursive(child, nodes, edges, node_set)


## Find resources that exist in the project but are not referenced
## by any .tscn or .gd file.
## Uses regex-based reference extraction (O(N+M)) instead of
## per-resource substring matching (O(N×M)).
func find_unused_resources(_params: Dictionary) -> Dictionary:
	var resource_files: Array = []
	MCPCommandHelpers.walk_directory("res://", PackedStringArray(["png", "jpg", "jpeg", "svg", "webp", "wav", "ogg", "mp3", "ttf", "otf", "obj", "fbx", "glb", "gltf", "material", "shader"]), func(path, _name): resource_files.append(ProjectSettings.localize_path(path)))

	# Collect all code files (.tscn, .gd, .tres) that might reference resources
	var code_files: Array = []
	MCPCommandHelpers.walk_directory("res://", PackedStringArray(["tscn"]), func(path, _name): code_files.append(path))
	MCPCommandHelpers.walk_directory("res://", PackedStringArray(["gd"]), func(path, _name): code_files.append(path))
	MCPCommandHelpers.walk_directory("res://", PackedStringArray(["tres"]), func(path, _name): code_files.append(path))

	# Single-pass: extract all res:// paths from all code files into a set
	var all_references: Dictionary = {}
	var regex: RegEx = RegEx.new()
	regex.compile("res://[a-zA-Z0-9_/.\\-]+")

	for file_path_variant: Variant in code_files:
		var file_path: String = file_path_variant as String
		var content: String = _read_file_content(file_path)
		if content.is_empty():
			continue
		var matches: Array[RegExMatch] = regex.search_all(content)
		for m: RegExMatch in matches:
			all_references[m.get_string()] = true

	var unused: Array = []
	for res_variant: Variant in resource_files:
		var res_path: String = res_variant as String
		if not all_references.has(res_path):
			unused.append(res_path)

	return {"result": {
		"total_resources": resource_files.size(),
		"unused_count": unused.size(),
		"unused_resources": unused,
	}}


## Get project-level statistics: file counts by type, total size, etc.
func get_project_statistics(_params: Dictionary) -> Dictionary:
	var stats: Dictionary = {
		"files_by_extension": {},
		"total_files": 0,
		"total_size_bytes": 0,
		"directories": 0,
	}
	_scan_project_dir("res://", stats)

	return {"result": stats}


func _scan_project_dir(dir_path: String, stats: Dictionary) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		var full_path: String = dir_path.path_join(file_name)
		if dir.current_is_dir():
			if not file_name.begins_with(".") and file_name != ".godot":
				stats["directories"] = (stats["directories"] as int) + 1
				_scan_project_dir(full_path, stats)
		else:
			stats["total_files"] = (stats["total_files"] as int) + 1
			var ext: String = file_name.get_extension().to_lower()
			if ext.is_empty():
				ext = "(no ext)"
			var by_ext: Dictionary = stats["files_by_extension"] as Dictionary
			by_ext[ext] = (by_ext.get(ext, 0) as int) + 1
			# Get file size via FileAccess (GDScript has no OS-level stat API)
			var file_size: int = 0
			var f: FileAccess = FileAccess.open(full_path, FileAccess.READ)
			if f != null:
				file_size = f.get_length()
				f.close()
			stats["total_size_bytes"] = (stats["total_size_bytes"] as int) + file_size
		file_name = dir.get_next()
	dir.list_dir_end()





## Helper: read file content.
func _read_file_content(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var content: String = file.get_as_text()
	file.close()
	return content
