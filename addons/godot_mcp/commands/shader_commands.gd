## Shader commands module - 9 tools.
## Handles shader creation, editing, and material assignment.
class_name MCPShaderCommands
extends RefCounted

var _plugin: EditorPlugin
var _undo_helper: MCUndoHelper


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin
	if _plugin.has_method("get_undo_helper"):
		_undo_helper = _plugin.get_undo_helper()


func get_commands() -> Dictionary:
	return {
		"shader/create": create_shader,
		"shader/read": read_shader,
		"shader/edit": edit_shader,
		"shader/assign_material": assign_shader_material,
		"shader/unassign_material": unassign_material,
		"shader/set_param": set_shader_param,
		"shader/reset_param": reset_shader_param,
		"shader/get_params": get_shader_params,
		"shader/list": list_shaders,
		"shader/delete": _delete_shader,
	}


## Create a new shader file.
func create_shader(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var shader_type: String = params.get("shader_type", params.get("type", "canvas_item"))
	var content: String = params.get("content", "")
	if path.is_empty():
		return {"error": "Path is required"}
	if not path.ends_with(".gdshader"):
		path += ".gdshader"

	if content.is_empty():
		match shader_type:
			"canvas_item", "visual":
				content = "shader_type canvas_item;\n\nvoid fragment() {\n\tCOLOR = texture(TEXTURE, UV);\n}\n"
			"spatial":
				content = "shader_type spatial;\n\nvoid fragment() {\n\tALBEDO = vec3(1.0);\n}\n"
			"particles":
				content = "shader_type particles;\n\nvoid process() {\n\t// Particle shader\n}\n"
			"sky":
				content = "shader_type sky;\n\nvoid sky() {\n\tCOLOR = vec3(0.5, 0.7, 1.0);\n}\n"
			"fog":
				content = "shader_type fog;\n\nvoid fog() {\n\tDENSITY = 0.0;\n}\n"

	var shader: Shader = Shader.new()
	shader.code = content
	MCPCommandHelpers.ensure_dir(path.get_base_dir())
	var err: Error = ResourceSaver.save(shader, path)
	if err != OK:
		return {"error": "Cannot create shader: %s — %s" % [path, error_string(err)]}

	_plugin.safe_scan_filesystem()
	return {"result": {"path": path, "type": shader_type}}


## Read shader file content.
func read_shader(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	if not FileAccess.file_exists(path):
		return {"error": "Shader not found: %s" % path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "Cannot read shader: %s" % path}
	var content: String = file.get_as_text()
	file.close()
	return {"result": {"path": path, "content": content, "lines": content.count("\n") + 1}}


## Edit a shader file (find and replace).
func edit_shader(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var old_text: String = params.get("old_text", "")
	var new_text: String = params.get("new_text", "")
	if path.is_empty() or old_text.is_empty():
		return {"error": "path and old_text are required"}
	if not FileAccess.file_exists(path):
		return {"error": "Shader not found: %s" % path}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "Cannot read shader: %s" % path}
	var content: String = file.get_as_text()
	file.close()

	if content.find(old_text) == -1:
		return {"error": "old_text not found in shader"}

	var count: int = content.count(old_text)
	content = content.replace(old_text, new_text)

	file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"error": "Cannot write shader: %s" % path}
	file.store_string(content)
	file.close()
	return {"result": {"path": path, "replacements": count}}


## Assign a shader material to a node.
func assign_shader_material(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var shader_path: String = params.get("shader_path", "")
	if node_path.is_empty() or shader_path.is_empty():
		return {"error": "node_path and shader_path are required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var shader: Shader = ResourceLoader.load(shader_path) as Shader
	if shader == null:
		return {"error": "Shader not found: %s" % shader_path}

	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader

	if _undo_helper:
		if node is CanvasItem:
			_undo_helper.set_property_with_undo(node, "material", mat)
		elif node is Node3D:
			_undo_helper.set_property_with_undo(node, "material_override", mat)
		else:
			return {"error": "Node does not support materials: %s" % node.get_class()}
	else:
		if node is CanvasItem:
			(node as CanvasItem).material = mat
		elif node is Node3D:
			(node as Node3D).material_override = mat
	return {"result": "Shader material assigned to %s" % node_path}


## Remove shader material from a node (set material/material_override to null).
func unassign_material(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	if node_path.is_empty():
		return {"error": "node_path is required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	if _undo_helper:
		if node is CanvasItem:
			_undo_helper.set_property_with_undo(node, "material", null)
		elif node is Node3D:
			_undo_helper.set_property_with_undo(node, "material_override", null)
		else:
			return {"error": "Node does not support materials: %s" % node.get_class()}
	else:
		if node is CanvasItem:
			(node as CanvasItem).material = null
		elif node is Node3D:
			(node as Node3D).material_override = null
	return {"result": "Material removed from %s" % node_path}


## Set a shader parameter on a node's material.
func set_shader_param(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var param: String = params.get("param", "")
	if node_path.is_empty() or param.is_empty():
		return {"error": "node_path and param are required"}
	if not params.has("value"):
		return {"error": "value is required"}
	if MCPCommandHelpers.is_null(params.get("value")):
		return {"error": "value cannot be null — use reset_shader_param to reset to default"}

	var value: Variant = params.get("value")

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var mat: Material = null
	if node is CanvasItem:
		mat = (node as CanvasItem).material
	elif node is Node3D:
		mat = (node as Node3D).material_override
	if mat == null or not mat is ShaderMaterial:
		return {"error": "Node does not have a ShaderMaterial"}

	var shader_mat: ShaderMaterial = mat as ShaderMaterial
	# Parse value appropriately
	var parsed: Variant = value
	if value is String:
		parsed = MCPVariantCodec._auto_parse_string(value as String)
	# Store old value for undo
	var old_val: Variant = shader_mat.get_shader_parameter(param)
	if _undo_helper:
		var ur: EditorUndoRedoManager = _undo_helper.get_undo_redo_manager()
		ur.create_action("MCP: Set shader param '%s' on %s" % [param, node_path])
		ur.add_do_method(shader_mat, "set_shader_parameter", param, parsed)
		ur.add_undo_method(shader_mat, "set_shader_parameter", param, old_val)
		ur.commit_action()
	else:
		shader_mat.set_shader_parameter(param, parsed)
	return {"result": "Shader param '%s' set on %s" % [param, node_path]}


## Reset a shader parameter to its default value (remove the override).
func reset_shader_param(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var param: String = params.get("param", "")
	if node_path.is_empty() or param.is_empty():
		return {"error": "node_path and param are required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var mat: Material = null
	if node is CanvasItem:
		mat = (node as CanvasItem).material
	elif node is Node3D:
		mat = (node as Node3D).material_override
	if mat == null or not mat is ShaderMaterial:
		return {"error": "Node does not have a ShaderMaterial"}

	var shader_mat: ShaderMaterial = mat as ShaderMaterial
	var old_val: Variant = shader_mat.get_shader_parameter(param)

	if _undo_helper:
		var ur: EditorUndoRedoManager = _undo_helper.get_undo_redo_manager()
		ur.create_action("MCP: Reset shader param '%s' on %s" % [param, node_path])
		ur.add_do_method(shader_mat, "set_shader_parameter", param, null)
		ur.add_undo_method(shader_mat, "set_shader_parameter", param, old_val)
		ur.commit_action()
	else:
		shader_mat.set_shader_parameter(param, null)
	return {"result": "Shader param '%s' reset to default on %s" % [param, node_path]}


## Get shader parameters from a node's material.
func get_shader_params(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	if node_path.is_empty():
		return {"error": "node_path is required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var mat: Material = null
	if node is CanvasItem:
		mat = (node as CanvasItem).material
	elif node is Node3D:
		mat = (node as Node3D).material_override
	if mat == null or not mat is ShaderMaterial:
		return {"error": "Node does not have a ShaderMaterial"}

	var shader_mat: ShaderMaterial = mat as ShaderMaterial
	var shader: Shader = shader_mat.shader
	var result: Dictionary = {
		"node_path": node_path,
		"shader_path": shader.resource_path if shader else "",
		"parameters": {},
	}
	if shader:
		var param_list: Array = shader.get_shader_uniform_list()
		for p: Dictionary in param_list:
			var pname: String = p["name"] as String
			var val: Variant = shader_mat.get_shader_parameter(pname)
			result["parameters"][pname] = {
				"type": p.get("type", ""),
				"value": MCPVariantCodec.serialize_value(val),
			}
	return {"result": result}


## List all shader files in the project.
func list_shaders(params: Dictionary) -> Dictionary:
	var filter_str: String = params.get("filter", "")
	var path: String = params.get("path", "")
	if filter_str.is_empty() and not path.is_empty():
		filter_str = path
	if filter_str.is_empty():
		filter_str = "res://"
	var is_glob: bool = "*" in filter_str or "?" in filter_str
	var shaders: Array = []
	MCPCommandHelpers.walk_directory("res://", PackedStringArray(["gdshader", "shader"]),
		func(fp, _name):
			if filter_str == "res://" or (is_glob and fp.match(filter_str)) or (not is_glob and fp.contains(filter_str)):
				shaders.append(fp)
	)
	return {"result": {"shaders": shaders, "count": shaders.size()}}


## Delete a shader file from the project.
func _delete_shader(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	if not FileAccess.file_exists(path):
		return {"error": "Shader not found: %s" % path}
	
	# Check if shader is used by any ShaderMaterial in the current scene
	var force: bool = params.get("force", false)
	if not force:
		var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
		if root:
			var refs: Array = _find_shader_refs_in_scene(root, path, 0, 20)
			if not refs.is_empty():
				var ref_paths: PackedStringArray = []
				for r in refs:
					ref_paths.append(str(r))
				return {"error": "Shader is in use by %d node(s): %s. Use force=true to delete anyway." % [refs.size(), ", ".join(ref_paths)]}
	
	# Convert res:// to global path for DirAccess
	var global_path: String = ProjectSettings.globalize_path(path)
	var err: Error = DirAccess.remove_absolute(global_path)
	if err != OK:
		return {"error": "Failed to delete shader: %s" % error_string(err)}
	
	# Also delete .import file if exists
	var import_path: String = global_path + ".import"
	if FileAccess.file_exists(import_path):
		DirAccess.remove_absolute(import_path)
	
	# Also delete .uid file if exists
	var uid_path: String = global_path + ".uid"
	if FileAccess.file_exists(uid_path):
		DirAccess.remove_absolute(uid_path)
	
	_plugin.safe_scan_filesystem()
	return {"result": {"deleted": path}}


## Helper: find nodes that reference a specific shader path.



func _find_shader_refs_in_scene(node: Node, shader_path: String, depth: int = 0, max_depth: int = 20) -> Array:
	var result: Array = []
	if depth >= max_depth:
		return result

	# Check all properties for ShaderMaterial references
	for p: Dictionary in node.get_property_list():
		var usage: int = p["usage"] as int
		if usage & PROPERTY_USAGE_STORAGE == 0:
			continue
		var val: Variant = node.get(p["name"] as String)
		if val is ShaderMaterial:
			var shader: Shader = val.shader
			if shader and shader.resource_path == shader_path:
				result.append(node.get_path())
				break
	for child in node.get_children():
		result.append_array(_find_shader_refs_in_scene(child, shader_path, depth + 1, max_depth))
	return result



