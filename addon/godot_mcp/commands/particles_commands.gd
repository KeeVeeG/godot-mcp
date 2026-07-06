## Particles commands module - 8 tools.
## Handles GPU particle creation, materials, colors, presets, and deletion.
class_name MCPParticlesCommands
extends RefCounted

var _plugin: EditorPlugin
var _undo_helper: MCUndoHelper


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin
	if _plugin.has_method("get_undo_helper"):
		_undo_helper = _plugin.get_undo_helper()


func get_commands() -> Dictionary:
	return {
		"particles/create": create_particles,
		"particles/delete": _delete_particles,
		"particles/set_material": set_particle_material,
		"particles/set_color_gradient": set_particle_color_gradient,
		"particles/apply_preset": apply_particle_preset,
		"particles/get_info": get_particle_info,
		"particles/set_emission_shape": set_particle_emission_shape,
		"particles/set_velocity_curve": set_particle_velocity_curve,
	}


func _get_root() -> Node:
	return _plugin.get_editor_interface().get_edited_scene_root()


func _get_node(path: String) -> Node:
	var root: Node = _get_root()
	if root == null:
		return null
	return root.get_node_or_null(path)


## Create a GPUParticles2D or GPUParticles3D node.
func create_particles(params: Dictionary) -> Dictionary:
	var parent_path: String = params.get("parent", params.get("parent_path", ""))
	var dimension: String = params.get("type", params.get("dimension", "2d"))
	var properties: Dictionary = params.get("properties", {})

	var parent: Node = _get_root()
	if parent_path != "":
		parent = _get_node(parent_path)
	if parent == null:
		return {"error": "Parent not found"}

	var node: Node = null
	match dimension:
		"2d":
			var gp: GPUParticles2D = GPUParticles2D.new()
			gp.amount = properties.get("amount", 8) as int
			gp.lifetime = properties.get("lifetime", 1.0) as float
			gp.emitting = properties.get("emitting", true) as bool
			gp.speed_scale = properties.get("speed_scale", 1.0) as float
			gp.explosiveness = properties.get("explosiveness", 0.0) as float
			gp.randomness = properties.get("randomness", 0.0) as float
			if properties.has("position"):
				gp.position = MCPVariantCodec._parse_vector2(properties["position"])
			node = gp
		"3d":
			var gp3: GPUParticles3D = GPUParticles3D.new()
			gp3.amount = properties.get("amount", 8) as int
			gp3.lifetime = properties.get("lifetime", 1.0) as float
			gp3.emitting = properties.get("emitting", true) as bool
			gp3.speed_scale = properties.get("speed_scale", 1.0) as float
			gp3.explosiveness = properties.get("explosiveness", 0.0) as float
			gp3.randomness = properties.get("randomness", 0.0) as float
			if properties.has("position"):
				gp3.position = MCPVariantCodec._parse_vector3(properties["position"])
			node = gp3
		_:
			return {"error": "Invalid type: use '2d' or '3d'"}

	node.name = properties.get("name", "Particles_%s" % dimension)

	if _undo_helper:
		_undo_helper.add_node_with_undo(node, parent)
	else:
		parent.add_child(node)
		node.set_owner(_get_root())

	return {"result": {"name": str(node.name), "path": str(node.get_path()), "dimension": dimension}}


## Set particle material properties.
func set_particle_material(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var properties: Dictionary = params.get("properties", {})
	if path.is_empty():
		return {"error": "Path is required"}

	var node: Node = _get_node(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var process_mat: ParticleProcessMaterial = null
	if node is GPUParticles2D:
		process_mat = (node as GPUParticles2D).process_material as ParticleProcessMaterial
		if process_mat == null:
			process_mat = ParticleProcessMaterial.new()
			(node as GPUParticles2D).process_material = process_mat
	elif node is GPUParticles3D:
		process_mat = (node as GPUParticles3D).process_material as ParticleProcessMaterial
		if process_mat == null:
			process_mat = ParticleProcessMaterial.new()
			(node as GPUParticles3D).process_material = process_mat
	else:
		return {"error": "Node is not a particle emitter"}

	if properties.has("direction"):
		process_mat.direction = MCPVariantCodec._parse_vector3(properties["direction"])
	if properties.has("spread"):
		process_mat.spread = properties["spread"] as float
	if properties.has("initial_velocity_min"):
		process_mat.initial_velocity_min = properties["initial_velocity_min"] as float
	if properties.has("initial_velocity_max"):
		process_mat.initial_velocity_max = properties["initial_velocity_max"] as float
	if properties.has("gravity"):
		process_mat.gravity = MCPVariantCodec._parse_vector3(properties["gravity"])
	if properties.has("scale_min"):
		process_mat.scale_min = properties["scale_min"] as float
	if properties.has("scale_max"):
		process_mat.scale_max = properties["scale_max"] as float
	if properties.has("color"):
		process_mat.color = MCPVariantCodec._parse_color(properties["color"])

	return {"result": "Particle material updated on %s" % path}


## Set a color gradient on particles.
func set_particle_color_gradient(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var gradient_raw: Variant = params.get("gradient", [])
	if path.is_empty():
		return {"error": "Path is required"}

	var node: Node = _get_node(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var grad: Gradient = Gradient.new()
	var points: Array = gradient_raw as Array if gradient_raw is Array else []
	for p_variant: Variant in points:
		var p: Dictionary = p_variant as Dictionary
		var offset: float = p.get("offset", 0.0) as float
		var color: Color = MCPVariantCodec._parse_color(p.get("color", "#ffffff"))
		grad.add_point(offset, color)

	var tex: GradientTexture1D = GradientTexture1D.new()
	tex.gradient = grad

	var process_mat: ParticleProcessMaterial = null
	if node is GPUParticles2D:
		process_mat = (node as GPUParticles2D).process_material as ParticleProcessMaterial
	elif node is GPUParticles3D:
		process_mat = (node as GPUParticles3D).process_material as ParticleProcessMaterial
	if process_mat == null:
		return {"error": "Set process material first before applying color gradient"}

	process_mat.color_ramp = tex
	return {"result": "Color gradient set on %s" % path}


## Apply a particle preset (fire, smoke, sparks, rain, snow).
func apply_particle_preset(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var preset_name: String = params.get("preset", params.get("preset_name", "fire"))
	if path.is_empty():
		return {"error": "Path is required"}

	var node: Node = _get_node(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var process_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	var is_2d: bool = node is GPUParticles2D

	match preset_name:
		"fire":
			process_mat.direction = Vector3(0, -1, 0)
			process_mat.spread = 15.0
			process_mat.initial_velocity_min = 50.0
			process_mat.initial_velocity_max = 100.0
			process_mat.gravity = Vector3(0, -20, 0)
			process_mat.scale_min = 0.5
			process_mat.scale_max = 1.5
			process_mat.color = Color(1, 0.5, 0.1, 1)
			if node is GPUParticles2D:
				(node as GPUParticles2D).amount = 32
				(node as GPUParticles2D).lifetime = 0.8
			elif node is GPUParticles3D:
				(node as GPUParticles3D).amount = 32
				(node as GPUParticles3D).lifetime = 0.8
		"smoke":
			process_mat.direction = Vector3(0, -1, 0)
			process_mat.spread = 30.0
			process_mat.initial_velocity_min = 20.0
			process_mat.initial_velocity_max = 40.0
			process_mat.gravity = Vector3(0, -10, 0)
			process_mat.scale_min = 1.0
			process_mat.scale_max = 3.0
			process_mat.color = Color(0.3, 0.3, 0.3, 0.5)
			if node is GPUParticles2D:
				(node as GPUParticles2D).amount = 16
				(node as GPUParticles2D).lifetime = 2.0
			elif node is GPUParticles3D:
				(node as GPUParticles3D).amount = 16
				(node as GPUParticles3D).lifetime = 2.0
		"sparks":
			process_mat.direction = Vector3(0, -1, 0)
			process_mat.spread = 60.0
			process_mat.initial_velocity_min = 100.0
			process_mat.initial_velocity_max = 200.0
			process_mat.gravity = Vector3(0, -98, 0)
			process_mat.scale_min = 0.1
			process_mat.scale_max = 0.3
			process_mat.color = Color(1, 0.9, 0.3, 1)
			if node is GPUParticles2D:
				(node as GPUParticles2D).amount = 20
				(node as GPUParticles2D).lifetime = 0.5
				(node as GPUParticles2D).explosiveness = 0.9
			elif node is GPUParticles3D:
				(node as GPUParticles3D).amount = 20
				(node as GPUParticles3D).lifetime = 0.5
				(node as GPUParticles3D).explosiveness = 0.9
		"rain":
			process_mat.direction = Vector3(0, 1, 0)
			process_mat.spread = 5.0
			process_mat.initial_velocity_min = 200.0
			process_mat.initial_velocity_max = 300.0
			process_mat.gravity = Vector3(0, 98, 0)
			process_mat.scale_min = 0.05
			process_mat.scale_max = 0.1
			process_mat.color = Color(0.6, 0.7, 1.0, 0.6)
			if node is GPUParticles2D:
				(node as GPUParticles2D).amount = 100
				(node as GPUParticles2D).lifetime = 1.0
			elif node is GPUParticles3D:
				(node as GPUParticles3D).amount = 100
				(node as GPUParticles3D).lifetime = 1.0
		"snow":
			process_mat.direction = Vector3(0, 1, 0)
			process_mat.spread = 30.0
			process_mat.initial_velocity_min = 20.0
			process_mat.initial_velocity_max = 40.0
			process_mat.gravity = Vector3(0, 10, 0)
			process_mat.scale_min = 0.1
			process_mat.scale_max = 0.2
			process_mat.color = Color(1, 1, 1, 0.8)
			if node is GPUParticles2D:
				(node as GPUParticles2D).amount = 50
				(node as GPUParticles2D).lifetime = 3.0
			elif node is GPUParticles3D:
				(node as GPUParticles3D).amount = 50
				(node as GPUParticles3D).lifetime = 3.0
		_:
			return {"error": "Unknown preset: %s (available: fire, smoke, sparks, rain, snow)" % preset_name}

	if node is GPUParticles2D:
		(node as GPUParticles2D).process_material = process_mat
	elif node is GPUParticles3D:
		(node as GPUParticles3D).process_material = process_mat

	return {"result": "Preset '%s' applied to %s" % [preset_name, path]}


## Get particle info.
func get_particle_info(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}

	var node: Node = _get_node(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var result: Dictionary = {"path": path}
	if node is GPUParticles2D:
		var gp: GPUParticles2D = node as GPUParticles2D
		result["type"] = "GPUParticles2D"
		result["amount"] = gp.amount
		result["lifetime"] = gp.lifetime
		result["emitting"] = gp.emitting
		result["speed_scale"] = gp.speed_scale
		result["explosiveness"] = gp.explosiveness
		result["randomness"] = gp.randomness
		if gp.process_material:
			result["material_type"] = gp.process_material.get_class()
	elif node is GPUParticles3D:
		var gp3: GPUParticles3D = node as GPUParticles3D
		result["type"] = "GPUParticles3D"
		result["amount"] = gp3.amount
		result["lifetime"] = gp3.lifetime
		result["emitting"] = gp3.emitting
		result["speed_scale"] = gp3.speed_scale
		result["explosiveness"] = gp3.explosiveness
		result["randomness"] = gp3.randomness
		if gp3.process_material:
			result["material_type"] = gp3.process_material.get_class()
	else:
		return {"error": "Node is not a particle emitter: %s" % node.get_class()}

	return {"result": result}


## Set the emission shape on a particle system's process material.
func set_particle_emission_shape(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var shape_type: String = params.get("shape", "point")
	var properties: Dictionary = params.get("properties", {})
	var size_array: Array = params.get("size", []) as Array if params.get("size", null) is Array else []
	if path.is_empty():
		return {"error": "Path is required"}
	var node: Node = _get_node(path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	var process_mat: ParticleProcessMaterial = null
	if node is GPUParticles2D:
		process_mat = (node as GPUParticles2D).process_material as ParticleProcessMaterial
	elif node is GPUParticles3D:
		process_mat = (node as GPUParticles3D).process_material as ParticleProcessMaterial
	if process_mat == null:
		process_mat = ParticleProcessMaterial.new()
		if node is GPUParticles2D:
			(node as GPUParticles2D).process_material = process_mat
		elif node is GPUParticles3D:
			(node as GPUParticles3D).process_material = process_mat
	match shape_type:
		"point":
			process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
		"sphere":
			process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			if properties.has("radius"):
				process_mat.emission_sphere_radius = properties["radius"] as float
			elif not size_array.is_empty():
				process_mat.emission_sphere_radius = size_array[0] as float
		"box":
			process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			if properties.has("size"):
				process_mat.emission_box_extents = MCPVariantCodec._parse_vector3(properties["size"])
			elif not size_array.is_empty():
				process_mat.emission_box_extents = MCPVariantCodec._parse_vector3(size_array)
		"ring":
			process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			if properties.has("radius"):
				process_mat.emission_ring_radius = properties["radius"] as float
			elif not size_array.is_empty():
				process_mat.emission_ring_radius = size_array[0] as float
			if properties.has("height"):
				process_mat.emission_ring_height = properties["height"] as float
			if properties.has("inner_radius"):
				process_mat.emission_ring_inner_radius = properties["inner_radius"] as float
		_:
			return {"error": "Unknown emission shape: %s (available: point, sphere, box, ring)" % shape_type}
	return {"result": "Emission shape '%s' set on %s" % [shape_type, path]}


## Set a velocity curve on a particle system's process material.
func set_particle_velocity_curve(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var curve_data: Variant = params.get("curve", [])
	if path.is_empty():
		return {"error": "Path is required"}
	var node: Node = _get_node(path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	var process_mat: ParticleProcessMaterial = null
	if node is GPUParticles2D:
		process_mat = (node as GPUParticles2D).process_material as ParticleProcessMaterial
	elif node is GPUParticles3D:
		process_mat = (node as GPUParticles3D).process_material as ParticleProcessMaterial
	if process_mat == null:
		return {"error": "Set process material first before applying velocity curve"}
	var curve: Curve = Curve.new()
	var points: Array = curve_data as Array if curve_data is Array else []
	if points.is_empty():
		# Default curve: linear from 1.0 to 0.0
		curve.add_point(Vector2(0.0, 1.0))
		curve.add_point(Vector2(1.0, 0.0))
	else:
		for pt: Variant in points:
			var pt_dict: Dictionary = pt as Dictionary
			var x: float = pt_dict.get("offset", pt_dict.get("x", 0.0)) as float
			var y: float = pt_dict.get("value", pt_dict.get("y", 0.0)) as float
			curve.add_point(Vector2(x, y))
	# velocity_limit_curve expects CurveTexture (Ref<Texture2D>), not plain Curve
	var curve_tex: CurveTexture = CurveTexture.new()
	curve_tex.curve = curve
	process_mat.velocity_limit_curve = curve_tex
	return {"result": "Velocity curve set on %s" % path}


## Delete a particle system node from the scene.
func _delete_particles(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", params.get("path", ""))
	if node_path.is_empty():
		return {"success": false, "error": "node_path is required"}

	var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return {"success": false, "error": "No scene open"}

	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"success": false, "error": "Node not found: %s" % node_path}

	if node == root:
		return {"success": false, "error": "Cannot delete scene root"}

	if not (node is GPUParticles2D or node is GPUParticles3D):
		return {"success": false, "error": "Node is not a particle system: %s" % node.get_class()}

	var parent: Node = node.get_parent()
	if parent == null:
		return {"success": false, "error": "Node has no parent"}

	if _undo_helper:
		_undo_helper.remove_node_with_undo(node)
	else:
		var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
		ur.create_action("MCP: Delete particle system %s" % node_path)
		ur.add_do_method(parent, "remove_child", node)
		ur.add_undo_method(parent, "add_child", node)
		ur.add_do_method(node, "set_owner", null)
		ur.add_undo_method(node, "set_owner", root)
		ur.commit_action()

	return {"success": true, "deleted": node_path, "type": node.get_class()}
