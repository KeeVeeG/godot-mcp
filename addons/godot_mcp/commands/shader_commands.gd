## Shader commands module - 9 tools.
## Handles shader creation, editing, and material assignment.
@tool
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
		"shader/validate": validate_shader,
	}


## Create a new shader file.
func create_shader(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var shader_type: String = params.get("shader_type", params.get("type", "canvas_item"))
	var content: String = params.get("content", "")
	var overwrite: bool = params.get("overwrite", false)
	if path.is_empty():
		return {"error": "Path is required"}
	if not path.ends_with(".gdshader"):
		path += ".gdshader"

	if FileAccess.file_exists(path) and not overwrite:
		return {"error": "Shader already exists: %s. Use overwrite=true to replace." % path}

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
	var replace_all: bool = params.get("replace_all", false)
	if path.is_empty():
		return {"error": "path is required"}
	if old_text.is_empty():
		return {"error": "old_text must not be empty"}
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
	if count > 1 and not replace_all:
		return {"error": "Found %d matches for old_text — use replace_all=true to replace all, or provide more context for a unique match." % count}

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

	# D4 fix: Detect shader type / node type mismatch and warn
	var shader_code: String = shader.code.strip_edges()
	var is_spatial_shader: bool = shader_code.begins_with("shader_type spatial") or shader_code.begins_with("shader_type particles") or shader_code.begins_with("shader_type sky") or shader_code.begins_with("shader_type fog")
	var is_canvas_shader: bool = shader_code.begins_with("shader_type canvas_item") or shader_code.begins_with("shader_type visual")
	var mismatch_warning: String = ""
	if is_spatial_shader and node is CanvasItem:
		mismatch_warning = " (WARNING: spatial/3D shader assigned to 2D CanvasItem node — shader will not render correctly)"
	elif is_canvas_shader and node is Node3D:
		mismatch_warning = " (WARNING: canvas_item/2D shader assigned to 3D Node3D — shader will not render correctly)"

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

	var msg: String = "Shader material assigned to %s" % node_path
	if not mismatch_warning.is_empty():
		msg += mismatch_warning
	return {"result": msg}


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

	# Check if node actually has a ShaderMaterial before attempting removal
	var has_material: bool = false
	if node is CanvasItem:
		has_material = (node as CanvasItem).material != null and (node as CanvasItem).material is ShaderMaterial
	elif node is Node3D:
		has_material = (node as Node3D).material_override != null and (node as Node3D).material_override is ShaderMaterial
	else:
		return {"error": "Node does not support materials: %s" % node.get_class()}
	if not has_material:
		return {"error": "Node does not have a ShaderMaterial"}

	if _undo_helper:
		if node is CanvasItem:
			_undo_helper.set_property_with_undo(node, "material", null)
		elif node is Node3D:
			_undo_helper.set_property_with_undo(node, "material_override", null)
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
	
	# Verify the uniform exists on the shader.
	# Force-reload from disk (CACHE_MODE_IGNORE) to pick up file changes
	# after edit_shader — prevents stale uniform list from cached Shader.
	var shader: Shader = shader_mat.shader
	var uniform_type: int = -1
	if shader and not shader.resource_path.is_empty():
		# Save overrides before reload (same pattern as get_shader_params)
		var saved_overrides: Dictionary = {}
		var old_uniforms: Array = shader.get_shader_uniform_list()
		for u: Dictionary in old_uniforms:
			var pname: String = u["name"] as String
			saved_overrides[pname] = shader_mat.get_shader_parameter(pname)
		var fresh_shader: Shader = ResourceLoader.load(shader.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE) as Shader
		if fresh_shader:
			shader_mat.shader = fresh_shader
			shader = fresh_shader
			# Restore overrides for uniforms that still exist
			var fresh_uniforms: Array = shader.get_shader_uniform_list()
			for u: Dictionary in fresh_uniforms:
				var pname: String = u["name"] as String
				if saved_overrides.has(pname):
					shader_mat.set_shader_parameter(pname, saved_overrides[pname])
	if shader:
		var uniform_list: Array = shader.get_shader_uniform_list()
		# Fallback: if Godot returns no uniforms (shader compilation failed),
		# parse uniform declarations from shader file text (same as get_shader_params).
		if uniform_list.is_empty():
			uniform_list = _parse_uniforms_from_text(shader.resource_path)
		var found: bool = false
		for u: Dictionary in uniform_list:
			if u.get("name", "") == param:
				found = true
				uniform_type = u.get("type", -1) as int
				break
		if not found:
			return {"error": "Shader does not have uniform '%s'" % param}
	
	# Parse value with type validation
	var parsed: Variant = _parse_param_value(value, uniform_type, param)
	
	# Check if _parse_param_value returned an error
	if parsed is Dictionary and (parsed as Dictionary).has("error"):
		return parsed
	
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


## Parse and validate a shader parameter value against its expected type.
## Converts string/array/dict values to proper Godot types (Color, Vector4, etc.)
## and rejects type mismatches.
func _parse_param_value(value: Variant, uniform_type: int, param_name: String) -> Variant:
	# If value is already the correct Godot type, pass through
	if uniform_type < 0:
		# Unknown type — pass through after auto-parsing strings
		if value is String:
			return MCPVariantCodec._auto_parse_string(value as String)
		return value

	# Handle string values — try parse with type validation
	if value is String:
		var s: String = value as String
		match uniform_type:
			TYPE_FLOAT:
				if not s.is_valid_float():
					return {"error": "Type mismatch for uniform '%s': expected float, got string '%s'" % [param_name, s]}
				return s.to_float()
			TYPE_INT:
				if not s.is_valid_int():
					return {"error": "Type mismatch for uniform '%s': expected int, got string '%s'" % [param_name, s]}
				return s.to_int()
			TYPE_BOOL:
				var lower: String = s.to_lower()
				if lower == "true": return true
				if lower == "false": return false
				return {"error": "Type mismatch for uniform '%s': expected bool, got string '%s'" % [param_name, s]}
			TYPE_COLOR:
				var parsed_color: Variant = MCPVariantCodec._auto_parse_string(s)
				if parsed_color is Color:
					return parsed_color
				# Try JSON array: "[1.0, 0.0, 0.0, 1.0]" or JSON object: "{\"r\":1,\"g\":0,\"b\":0,\"a\":1}"
				var json_arr: Variant = JSON.parse_string(s)
				if json_arr is Array:
					var a: Array = json_arr as Array
					if a.size() == 3:
						return Color(a[0] as float, a[1] as float, a[2] as float)
					elif a.size() == 4:
						return Color(a[0] as float, a[1] as float, a[2] as float, a[3] as float)
				elif json_arr is Dictionary:
					return MCPVariantCodec._parse_color(json_arr)
				return {"error": "Type mismatch for uniform '%s': expected Color, got string '%s' which cannot be parsed as a color" % [param_name, s]}
			TYPE_VECTOR2, TYPE_VECTOR2I:
				var parsed_v2: Variant = MCPVariantCodec._auto_parse_string(s)
				if parsed_v2 is Vector2 or parsed_v2 is Vector2i:
					return parsed_v2
				var json_v2: Variant = JSON.parse_string(s)
				if json_v2 is Array:
					var a2: Array = json_v2 as Array
					if a2.size() == 2:
						return Vector2(a2[0] as float, a2[1] as float)
				elif json_v2 is Dictionary:
					return MCPVariantCodec._parse_vector2(json_v2)
				return {"error": "Type mismatch for uniform '%s': expected Vector2, got string '%s'" % [param_name, s]}
			TYPE_VECTOR3, TYPE_VECTOR3I:
				var parsed_v3: Variant = MCPVariantCodec._auto_parse_string(s)
				if parsed_v3 is Vector3 or parsed_v3 is Vector3i:
					return parsed_v3
				var json_v3: Variant = JSON.parse_string(s)
				if json_v3 is Array:
					var a3: Array = json_v3 as Array
					if a3.size() == 3:
						return Vector3(a3[0] as float, a3[1] as float, a3[2] as float)
				elif json_v3 is Dictionary:
					return MCPVariantCodec._parse_vector3(json_v3)
				return {"error": "Type mismatch for uniform '%s': expected Vector3, got string '%s'" % [param_name, s]}
			TYPE_VECTOR4, TYPE_VECTOR4I:
				var parsed_v4: Variant = MCPVariantCodec._auto_parse_string(s)
				if parsed_v4 is Vector4 or parsed_v4 is Vector4i or parsed_v4 is Color:
					return parsed_v4
				var json_v4: Variant = JSON.parse_string(s)
				if json_v4 is Array:
					var a4: Array = json_v4 as Array
					if a4.size() == 4:
						return Vector4(a4[0] as float, a4[1] as float, a4[2] as float, a4[3] as float)
				elif json_v4 is Dictionary:
					return MCPVariantCodec._parse_vector4(json_v4)
				return {"error": "Type mismatch for uniform '%s': expected Vector4, got string '%s'" % [param_name, s]}
		# For other types (sampler, texture, etc.), try auto-parse
		return MCPVariantCodec._auto_parse_string(s)

	# Validate type for non-string values
	var type_ok: bool = true
	match uniform_type:
		TYPE_FLOAT:
			if not (value is float or value is int):
				type_ok = false
		TYPE_INT:
			if not (value is int or value is float):
				type_ok = false
		TYPE_BOOL:
			if not value is bool:
				type_ok = false
		TYPE_VECTOR2, TYPE_VECTOR2I:
			if not (value is Vector2 or value is Vector2i or value is Array or value is Dictionary):
				type_ok = false
		TYPE_VECTOR3, TYPE_VECTOR3I:
			if not (value is Vector3 or value is Vector3i or value is Array or value is Dictionary):
				type_ok = false
		TYPE_VECTOR4, TYPE_VECTOR4I:
			if not (value is Vector4 or value is Vector4i or value is Array or value is Dictionary or value is Color):
				type_ok = false
		TYPE_COLOR:
			if not (value is Color or value is Array or value is Dictionary):
				type_ok = false
		TYPE_STRING, TYPE_STRING_NAME:
			if not value is String:
				type_ok = false

	if type_ok:
		# Convert arrays/dicts to proper Godot types
		match uniform_type:
			TYPE_COLOR:
				if value is Array:
					var a: Array = value as Array
					if a.size() == 3:
						return Color(a[0] as float, a[1] as float, a[2] as float)
					elif a.size() == 4:
						return Color(a[0] as float, a[1] as float, a[2] as float, a[3] as float)
				elif value is Dictionary:
					return MCPVariantCodec._parse_color(value)
			TYPE_VECTOR4:
				if value is Array:
					var a: Array = value as Array
					if a.size() == 4:
						return Vector4(a[0] as float, a[1] as float, a[2] as float, a[3] as float)
				elif value is Dictionary:
					return MCPVariantCodec._parse_vector4(value)
			TYPE_VECTOR3:
				if value is Array:
					var a: Array = value as Array
					if a.size() == 3:
						return Vector3(a[0] as float, a[1] as float, a[2] as float)
				elif value is Dictionary:
					return MCPVariantCodec._parse_vector3(value)
			TYPE_VECTOR2:
				if value is Array:
					var a: Array = value as Array
					if a.size() == 2:
						return Vector2(a[0] as float, a[1] as float)
				elif value is Dictionary:
					return MCPVariantCodec._parse_vector2(value)
		return value

	return {"error": "Type mismatch for uniform '%s': expected %s, got %s" % [param_name, type_string(uniform_type), typeof(value)]}


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

	# Save current parameter overrides BEFORE reloading the shader.
	# Reassigning shader_mat.shader = fresh_shader may clear user-set
	# parameter values, so we snapshot and restore them afterward.
	var saved_overrides: Dictionary = {}
	if shader:
		var old_uniforms: Array = shader.get_shader_uniform_list()
		for u: Dictionary in old_uniforms:
			var pname: String = u["name"] as String
			saved_overrides[pname] = shader_mat.get_shader_parameter(pname)

	# Force reload shader from disk to pick up file changes (new uniforms).
	# ShaderMaterial caches the compiled shader internally. By loading
	# a fresh copy (CACHE_MODE_IGNORE) and reassigning, we force Godot
	# to recompile and expose any new uniforms added to the .gdshader file.
	# NOTE: This is a best-effort approach. If the shader file has been
	# saved with syntax errors, the reload may result in a broken shader
	# that returns no uniforms. In that case, fix the shader and try again.
	var reloaded: bool = false
	if shader and not shader.resource_path.is_empty():
		var fresh_shader: Shader = ResourceLoader.load(shader.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE) as Shader
		if fresh_shader:
			shader_mat.shader = fresh_shader
			shader = fresh_shader
			reloaded = true

	# Restore previously-set parameter overrides (D1 fix).
	# Only restore overrides for uniforms that still exist in the reloaded shader.
	if reloaded and not saved_overrides.is_empty() and shader:
		var fresh_uniforms: Array = shader.get_shader_uniform_list()
		for u: Dictionary in fresh_uniforms:
			var pname: String = u["name"] as String
			if saved_overrides.has(pname):
				shader_mat.set_shader_parameter(pname, saved_overrides[pname])

	var result: Dictionary = {
		"node_path": node_path,
		"shader_path": shader.resource_path if shader else "",
		"parameters": {},
		"reloaded_from_disk": reloaded,
	}
	if shader:
		var param_list: Array = shader.get_shader_uniform_list()
		# Fallback: if Godot returns no uniforms (e.g. shader not compiled yet),
		# try parsing the shader file text for uniform declarations.
		if param_list.is_empty():
			param_list = _parse_uniforms_from_text(shader.resource_path)
		for p: Dictionary in param_list:
			var pname: String = p["name"] as String
			var val: Variant = shader_mat.get_shader_parameter(pname)
			# Fall back to shader-declared default if not explicitly set (Issue #3 fix).
			# ShaderMaterial.get_shader_parameter() returns null for unset uniforms;
			# RenderingServer.shader_get_parameter_default() reads the default
			# from the compiled shader (e.g. "uniform float brightness = 1.0" → 1.0).
			if val == null and shader:
				val = RenderingServer.shader_get_parameter_default(shader.get_rid(), pname)
			var utype = p.get("type", "")
			# Normalize legacy Array values to proper Godot types based on uniform type
			if val is Array:
				var a: Array = val as Array
				if utype is int and utype == TYPE_COLOR and a.size() >= 3:
					val = Color(a[0] as float, a[1] as float, a[2] as float, a[3] as float if a.size() >= 4 else 1.0)
				elif utype is int and (utype == TYPE_VECTOR4 or utype == TYPE_VECTOR4I) and a.size() >= 4:
					val = Vector4(a[0] as float, a[1] as float, a[2] as float, a[3] as float)
				elif utype is int and (utype == TYPE_VECTOR3 or utype == TYPE_VECTOR3I) and a.size() >= 3:
					val = Vector3(a[0] as float, a[1] as float, a[2] as float)
				elif utype is int and (utype == TYPE_VECTOR2 or utype == TYPE_VECTOR2I) and a.size() >= 2:
					val = Vector2(a[0] as float, a[1] as float)
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
	var ref_warning: String = ""
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root:
		var refs: Array = _find_shader_refs_in_scene(root, path, root, 0, 20)
		if not refs.is_empty():
			if not force:
				var ref_paths: PackedStringArray = []
				for r in refs:
					ref_paths.append(str(r))
				return {"error": "Shader is in use by %d node(s): %s. Use force=true to delete anyway." % [refs.size(), ", ".join(ref_paths)]}
			# force=true: warn about zombie references
			var ref_paths: PackedStringArray = []
			for r in refs:
				ref_paths.append(str(r))
			ref_warning = "Shader was referenced by %d node(s): %s. These materials now reference a missing shader." % [refs.size(), ", ".join(ref_paths)]
	
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
	var result_dict: Dictionary = {"deleted": path}
	if not ref_warning.is_empty():
		result_dict["warning"] = ref_warning
	return {"result": result_dict}


## Validate a shader file for compilation errors.
func validate_shader(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "path is required"}
	if not FileAccess.file_exists(path):
		return {"error": "Shader not found: %s" % path}
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "Cannot read shader: %s" % path}
	var content: String = file.get_as_text()
	file.close()
	
	var result: Dictionary = {"path": path, "valid": true, "line_count": content.count("\n") + 1, "warnings": []}
	
	# Basic validation: shader must start with shader_type declaration
	if not content.strip_edges().begins_with("shader_type"):
		result["valid"] = false
		result["error"] = "Missing shader_type declaration"
		return {"result": result}
	
	# Extract shader type from the declaration line
	var lines: PackedStringArray = content.split("\n")
	for line in lines:
		var stripped: String = line.strip_edges()
		if stripped.begins_with("shader_type"):
			result["type"] = stripped.trim_prefix("shader_type").strip_edges().trim_suffix(";").strip_edges()
			break
	
	# --- Best-effort syntax checks (D4) ---
	# These catch common issues that ResourceLoader.load() won't report.
	_basic_syntax_checks(content, result)
	
	# Try loading as Shader resource (CACHE_MODE_IGNORE to get fresh version)
	var shader: Shader = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Shader
	if shader == null:
		result["valid"] = false
		result["error"] = "Failed to load shader resource. Check Godot Output panel for compilation errors."
		return {"result": result}
	
	# Get uniforms as a rough compilation check
	var uniforms: Array = shader.get_shader_uniform_list()
	result["uniforms"] = []
	for u: Dictionary in uniforms:
		result["uniforms"].append({"name": u.get("name", ""), "type": str(u.get("type", ""))})
	
	result["message"] = "Shader passed basic syntax validation. NOTE: Godot 4.x does NOT expose ShaderLanguage (C++ internal class) to GDScript. Only text-level checks (brace matching, vec arg counts, semicolons) + ResourceLoader.load() are performed. Undeclared variables, type mismatches, and invalid built-in usage are NOT detected. This is a known Godot engine limitation — use the Shader Editor Output panel (which has direct C++ compiler access) for definitive validation. Heuristic: if a shader has declared uniforms but get_shader_uniform_list() returns empty, compilation likely failed."
	
	return {"result": result}


## Helper: find nodes that reference a specific shader path.



func _find_shader_refs_in_scene(node: Node, shader_path: String, scene_root: Node, depth: int = 0, max_depth: int = 20) -> Array:
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
				result.append(scene_root.get_path_to(node))
				break
	for child in node.get_children():
		result.append_array(_find_shader_refs_in_scene(child, shader_path, scene_root, depth + 1, max_depth))
	return result


## Best-effort syntax checks for validate_shader (D4).
## Catches common errors that ResourceLoader.load() won't report.
## NOTE: Godot 4 does NOT expose ShaderLanguage/ShaderCompiler to GDScript.
## Full compilation error detection requires a GDExtension wrapping those C++ classes.
## These text-based checks are best-effort only.
func _basic_syntax_checks(content: String, result: Dictionary) -> void:
	var lines: PackedStringArray = content.split("\n")
	var brace_depth: int = 0
	var line_num: int = 0
	var declared_vars: Array[String] = []  # Track declared identifiers
	
	# Regexes for common error patterns
	var vec_constructor_re: RegEx = RegEx.new()
	vec_constructor_re.compile("(vec[234]|ivec[234]|uvec[234]|bvec[234])\\s*\\(([^)]*)\\)")
	
	for line in lines:
		line_num += 1
		var stripped: String = line.strip_edges()
		# Skip comments and blank lines
		if stripped.begins_with("//") or stripped.is_empty():
			continue
		# Remove inline comments for analysis
		var inline_comment: int = stripped.find("//")
		if inline_comment != -1:
			stripped = stripped.substr(0, inline_comment).strip_edges()
		# Track brace depth
		for ch in line:
			if ch == "{": brace_depth += 1
			if ch == "}": brace_depth -= 1
		# Check uniform declarations end with semicolon
		if stripped.begins_with("uniform ") and not stripped.ends_with(";"):
			result["warnings"].append("Line %d: uniform declaration missing semicolon — '%s'" % [line_num, stripped])
		# Check for multi-line comments start/end
		if stripped.begins_with("/*") and not stripped.ends_with("*/"):
			result["warnings"].append("Line %d: multi-line comment block may not be closed" % line_num)
		# Validate vec/ivec/uvec/bvec constructor argument counts
		for m: RegExMatch in vec_constructor_re.search_all(stripped):
			var type_name: String = m.get_string(1)
			var args: String = m.get_string(2).strip_edges()
			var expected: int = int(type_name[type_name.length() - 1])  # '2', '3', or '4'
			# Count comma-separated arguments
			var arg_count: int = 1 if args.length() > 0 else 0
			for ch in args:
				if ch == ",":
					arg_count += 1
			if arg_count != expected:
				result["warnings"].append("Line %d: %s constructor expects %d arguments, got %d — '%s'" % [line_num, type_name, expected, arg_count, m.get_string(0)])
				result["valid"] = false
				if not result.has("error"):
					result["error"] = "Line %d: %s(%s) — wrong argument count (%d instead of %d)" % [line_num, type_name, args, arg_count, expected]
	
	if brace_depth != 0:
		result["warnings"].append("Brace mismatch: %s extra %s brace(s)" % [abs(brace_depth), "opening" if brace_depth > 0 else "closing"])
		result["valid"] = false
		if not result.has("error"):
			result["error"] = "Brace mismatch detected (%d unclosed)" % brace_depth


## Fallback: parse uniform declarations directly from shader file text.
## Used when get_shader_uniform_list() returns empty (shader not yet compiled).
func _parse_uniforms_from_text(path: String) -> Array:
	var result: Array = []
	if path.is_empty() or not FileAccess.file_exists(path):
		return result
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return result
	var content: String = file.get_as_text()
	file.close()

	# Normalize: collapse multi-line declarations to single lines
	var normalized: String = ""
	for ch in content:
		if ch == "\n" or ch == "\r":
			normalized += " "
		else:
			normalized += ch

	# Match patterns like: uniform <type> <name> [= <default>] [: hint] [;]
	# Examples:
	#   uniform float brightness = 1.0;
	#   uniform vec4 tint_color : source_color;
	#   uniform sampler2D main_texture : hint_albedo;
	var regex: RegEx = RegEx.new()
	regex.compile("uniform\\s+(\\w+)\\s+(\\w+)\\s*(?:=\\s*([^;:]+?))?\\s*(?::\\s*([^;]+?))?\\s*;")
	for m: RegExMatch in regex.search_all(normalized):
		var uniform_type: String = m.get_string(1)
		var uniform_name: String = m.get_string(2)
		result.append({
			"name": uniform_name,
			"type": uniform_type,
			"_parsed_from_text": true,
		})
	return result



