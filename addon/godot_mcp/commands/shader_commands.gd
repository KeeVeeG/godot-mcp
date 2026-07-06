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
		"shader/set_param": set_shader_param,
		"shader/get_params": get_shader_params,
		"shader/list": list_shaders,
		"shader/validate": validate_shader,
		"shader/delete": _delete_shader,
	}


func _get_root() -> Node:
	return _plugin.get_editor_interface().get_edited_scene_root()


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

	var root: Node = _get_root()
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


## Set a shader parameter on a node's material.
func set_shader_param(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var param: String = params.get("param", "")
	var value: Variant = params.get("value")
	if node_path.is_empty() or param.is_empty():
		return {"error": "node_path and param are required"}

	var root: Node = _get_root()
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
	shader_mat.set_shader_parameter(param, parsed)
	return {"result": "Shader param '%s' set on %s" % [param, node_path]}


## Get shader parameters from a node's material.
func get_shader_params(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	if node_path.is_empty():
		return {"error": "node_path is required"}

	var root: Node = _get_root()
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
	var path: String = params.get("filter", params.get("path", "res://"))
	var shaders: Array = []
	_collect_shader_files(path, shaders)
	return {"result": {"shaders": shaders, "count": shaders.size()}}


## Validate a shader for compilation errors.
func validate_shader(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"success": false, "error": "Path is required"}
	if not FileAccess.file_exists(path):
		return {"success": false, "error": "Shader not found: %s" % path}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"success": false, "error": "Cannot read shader: %s" % path}
	var code: String = file.get_as_text()
	file.close()
	
	# Try to load the shader as a resource to check for compilation errors
	var shader: Resource = ResourceLoader.load(path)
	if shader == null:
		return {"success": false, "error": "Failed to load shader resource — may have compilation errors"}
	
	return {"success": true, "path": path, "valid": true, "lines": code.count("\n") + 1, "type": shader.get_class()}


## Helper: recursively collect shader files.
func _collect_shader_files(dir_path: String, results: Array) -> void:
	var global_path: String = ProjectSettings.globalize_path(dir_path) if dir_path.begins_with("res://") else dir_path
	var dir: DirAccess = DirAccess.open(global_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not file_name.begins_with("."):
			var full_path: String = dir_path.path_join(file_name)
			if dir.current_is_dir():
				if file_name != ".godot" and file_name != ".import":
					_collect_shader_files(full_path, results)
			elif file_name.ends_with(".gdshader") or file_name.ends_with(".shader"):
				results.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()


## Delete a shader file from the project.
func _delete_shader(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"success": false, "error": "Path is required"}
	if not FileAccess.file_exists(path):
		return {"success": false, "error": "Shader not found: %s" % path}
	
	# Check if shader is used by any ShaderMaterial in the current scene
	var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
	if root:
		var refs: Array = _find_shader_refs_in_scene(root, path, 0, 20)
		if not refs.is_empty():
			return {"success": false, "error": "Shader is used by nodes: %s. Remove references first." % str(refs)}
	
	# Convert res:// to global path for DirAccess
	var global_path: String = ProjectSettings.globalize_path(path)
	var err: Error = DirAccess.remove_absolute(global_path)
	if err != OK:
		return {"success": false, "error": "Failed to delete shader: %s" % error_string(err)}
	
	# Also delete .import file if exists
	var import_path: String = global_path + ".import"
	if FileAccess.file_exists(import_path):
		DirAccess.remove_absolute(import_path)
	
	# Also delete .uid file if exists
	var uid_path: String = global_path + ".uid"
	if FileAccess.file_exists(uid_path):
		DirAccess.remove_absolute(uid_path)
	
	_plugin.safe_scan_filesystem()
	return {"success": true, "deleted": path}


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
