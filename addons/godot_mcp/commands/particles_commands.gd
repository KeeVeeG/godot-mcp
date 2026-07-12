## Particles commands module - 12 tools.
## Handles GPU particle creation, materials, colors, presets, and deletion.
@tool
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
		"particles/get_material": get_particle_material,
		"particles/set_color_gradient": set_particle_color_gradient,
		"particles/get_color_gradient": get_particle_color_gradient,
		"particles/apply_preset": apply_particle_preset,
		"particles/get_info": get_particle_info,
		"particles/set_emission_shape": set_particle_emission_shape,
		"particles/get_emission_shape": get_particle_emission_shape,
		"particles/set_velocity_curve": set_particle_velocity_curve,
		"particles/get_velocity_curve": get_particle_velocity_curve,
	}


## Create a GPUParticles2D or GPUParticles3D node.
func create_particles(params: Dictionary) -> Dictionary:
	var parent_path: String = params.get("parent", "")
	var dimension: String = params.get("type", "")
	if dimension.is_empty():
		return {"error": "Missing required parameter: 'type' (must be '2d' or '3d')"}
	var properties: Dictionary = params.get("properties", {})

	var parent: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if parent_path != "":
		parent = MCPCommandHelpers.resolve_node_path(_plugin, parent_path)
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

	if properties.has("name"):
		node.name = str(properties["name"])

	if _undo_helper:
		_undo_helper.add_node_with_undo(node, parent)
	else:
		parent.add_child(node, true)
		node.set_owner(MCPCommandHelpers.get_scene_root(_plugin))

	var valid_keys: PackedStringArray = ["amount", "lifetime", "emitting", "speed_scale", "explosiveness", "randomness", "position", "name"]
	var unknown_keys: Array[String] = []
	for key: String in properties:
		if not key in valid_keys:
			unknown_keys.append(key)

	if not unknown_keys.is_empty():
		return {"result": {"name": str(node.name), "path": MCPCommandHelpers.get_node_path(node, _plugin), "dimension": dimension, "message": "Particle %s created at %s (unknown properties ignored: %s)" % [dimension, MCPCommandHelpers.get_node_path(node, _plugin), ", ".join(unknown_keys)]}}
	return {"result": {"name": str(node.name), "path": MCPCommandHelpers.get_node_path(node, _plugin), "dimension": dimension}}


## Set particle material properties.
func set_particle_material(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var properties: Dictionary = params.get("properties", {})
	if path.is_empty():
		return {"error": "Path is required"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
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

	# Validate all inputs first (prevent partial application)
	var col_to_set: Color = Color.WHITE
	if properties.has("color"):
		col_to_set = MCPVariantCodec._parse_color(properties["color"])
		if col_to_set == Color(-1, -1, -1, -1):
			return {"error": "Invalid color: %s — use hex format #RRGGBBAA" % str(properties["color"])}

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
		process_mat.color = col_to_set
	if properties.has("flatness"):
		process_mat.flatness = properties["flatness"] as float
	if properties.has("lifetime_randomness"):
		process_mat.lifetime_randomness = properties["lifetime_randomness"] as float
	if properties.has("damping_min"):
		process_mat.damping_min = properties["damping_min"] as float
	if properties.has("damping_max"):
		process_mat.damping_max = properties["damping_max"] as float
	if properties.has("angle_min"):
		process_mat.angle_min = properties["angle_min"] as float
	if properties.has("angle_max"):
		process_mat.angle_max = properties["angle_max"] as float
	if properties.has("orbit_velocity_min"):
		process_mat.orbit_velocity_min = properties["orbit_velocity_min"] as float
	if properties.has("orbit_velocity_max"):
		process_mat.orbit_velocity_max = properties["orbit_velocity_max"] as float
	if properties.has("radial_accel_min"):
		process_mat.radial_accel_min = properties["radial_accel_min"] as float
	if properties.has("radial_accel_max"):
		process_mat.radial_accel_max = properties["radial_accel_max"] as float
	if properties.has("tangential_accel_min"):
		process_mat.tangential_accel_min = properties["tangential_accel_min"] as float
	if properties.has("tangential_accel_max"):
		process_mat.tangential_accel_max = properties["tangential_accel_max"] as float

	var valid_keys: PackedStringArray = ["direction", "spread", "initial_velocity_min", "initial_velocity_max", "gravity", "scale_min", "scale_max", "color", "flatness", "lifetime_randomness", "damping_min", "damping_max", "angle_min", "angle_max", "orbit_velocity_min", "orbit_velocity_max", "radial_accel_min", "radial_accel_max", "tangential_accel_min", "tangential_accel_max"]
	var unknown_keys: Array[String] = []
	for key: String in properties:
		if not key in valid_keys:
			unknown_keys.append(key)

	if unknown_keys.size() > 0:
		return {"result": "Particle material updated on %s (unknown properties ignored: %s)" % [path, ", ".join(unknown_keys)]}

	return {"result": "Particle material updated on %s" % path}


## Read particle material properties.
func get_particle_material(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var process_mat: ParticleProcessMaterial = null
	if node is GPUParticles2D:
		process_mat = (node as GPUParticles2D).process_material as ParticleProcessMaterial
	elif node is GPUParticles3D:
		process_mat = (node as GPUParticles3D).process_material as ParticleProcessMaterial
	else:
		return {"error": "Node is not a particle emitter"}

	if process_mat == null:
		return {"error": "No process material set on %s" % path}

	var result: Dictionary = {
		"path": path,
		"direction": [process_mat.direction.x, process_mat.direction.y, process_mat.direction.z],
		"spread": process_mat.spread,
		"flatness": process_mat.flatness,
		"initial_velocity_min": process_mat.initial_velocity_min,
		"initial_velocity_max": process_mat.initial_velocity_max,
		"gravity": [process_mat.gravity.x, process_mat.gravity.y, process_mat.gravity.z],
		"scale_min": process_mat.scale_min,
		"scale_max": process_mat.scale_max,
		"color": "#%s" % process_mat.color.to_html(),
		"lifetime_randomness": process_mat.lifetime_randomness,
		"damping_min": process_mat.damping_min,
		"damping_max": process_mat.damping_max,
		"angle_min": process_mat.angle_min,
		"angle_max": process_mat.angle_max,
		"orbit_velocity_min": process_mat.orbit_velocity_min,
		"orbit_velocity_max": process_mat.orbit_velocity_max,
		"radial_accel_min": process_mat.radial_accel_min,
		"radial_accel_max": process_mat.radial_accel_max,
		"tangential_accel_min": process_mat.tangential_accel_min,
		"tangential_accel_max": process_mat.tangential_accel_max,
	}
	return {"result": result}


## Set a color gradient on particles.
func set_particle_color_gradient(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var gradient_raw: Variant = params.get("gradient", [])
	if path.is_empty():
		return {"error": "Path is required"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var points: Array = gradient_raw as Array if gradient_raw is Array else []
	if points.is_empty():
		return {"error": "Gradient array is empty — provide at least one color stop"}
	var grad: Gradient = Gradient.new()
	# Gradient.new() creates 2 default points (black@0, white@1).
	# Use set_offsets/set_colors (which resize the internal array) to replace defaults.
	var offsets: PackedFloat32Array = []
	var colors: PackedColorArray = []
	for p_variant: Variant in points:
		var p: Dictionary = p_variant as Dictionary
		offsets.append(p.get("offset", 0.0) as float)
		var col_val := MCPVariantCodec._parse_color(p.get("color", "#ffffffff"))
		if col_val == Color(-1, -1, -1, -1):
			return {"error": "Invalid color at offset %s: '%s' — use hex format #RRGGBBAA" % [p.get("offset", 0.0), str(p.get("color", ""))]}
		colors.append(col_val)
	grad.set_offsets(offsets)
	grad.set_colors(colors)

	var tex: GradientTexture1D = GradientTexture1D.new()
	tex.gradient = grad

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
		return {"error": "Node is not a particle emitter: %s" % node.get_class()}

	process_mat.color_ramp = tex
	return {"result": "Color gradient set on %s" % path}


## Read the color gradient from a particle system.
func get_particle_color_gradient(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var process_mat: ParticleProcessMaterial = null
	if node is GPUParticles2D:
		process_mat = (node as GPUParticles2D).process_material as ParticleProcessMaterial
	elif node is GPUParticles3D:
		process_mat = (node as GPUParticles3D).process_material as ParticleProcessMaterial
	else:
		return {"error": "Node is not a particle emitter"}

	if process_mat == null:
		return {"error": "No process material set on %s" % path}

	var color_ramp_tex: Texture2D = process_mat.color_ramp
	if color_ramp_tex == null:
		return {"error": "No color gradient set on %s" % path}

	var gradient: Gradient = null
	if color_ramp_tex is GradientTexture1D:
		gradient = (color_ramp_tex as GradientTexture1D).gradient
	if gradient == null:
		return {"error": "Color gradient is not a valid GradientTexture1D on %s" % path}

	var points: Array = []
	for i: int in range(gradient.get_point_count()):
		var point: Dictionary = {
			"offset": gradient.get_offset(i),
			"color": "#%s" % gradient.get_color(i).to_html(),
		}
		points.append(point)

	return {"result": {"path": path, "gradient": points}}


## Apply a particle preset (fire, smoke, sparks, rain, snow).
func apply_particle_preset(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var preset_name: String = params.get("preset", "")
	if preset_name.is_empty():
		return {"error": "Missing required parameter: 'preset'"}
	if path.is_empty():
		return {"error": "Path is required"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	if not (node is GPUParticles2D or node is GPUParticles3D):
		return {"error": "Node is not a particle emitter: %s" % node.get_class()}

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

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
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
		result["one_shot"] = gp.one_shot
		result["preprocess"] = gp.preprocess
		result["visibility_rect"] = [gp.visibility_rect.position.x, gp.visibility_rect.position.y, gp.visibility_rect.size.x, gp.visibility_rect.size.y]
		if gp.process_material:
			result["material_type"] = gp.process_material.get_class()
			_fill_material_info(result, gp.process_material as ParticleProcessMaterial)
		# draw_pass properties may not exist in all Godot 4.x versions — use safe get()
		var dp1 = gp.get("draw_pass_1")
		if dp1 != null:
			result["draw_pass_1"] = dp1.get_class()
		var dp2 = gp.get("draw_pass_2")
		if dp2 != null:
			result["draw_pass_2"] = dp2.get_class()
	elif node is GPUParticles3D:
		var gp3: GPUParticles3D = node as GPUParticles3D
		result["type"] = "GPUParticles3D"
		result["amount"] = gp3.amount
		result["lifetime"] = gp3.lifetime
		result["emitting"] = gp3.emitting
		result["speed_scale"] = gp3.speed_scale
		result["explosiveness"] = gp3.explosiveness
		result["randomness"] = gp3.randomness
		result["one_shot"] = gp3.one_shot
		result["preprocess"] = gp3.preprocess
		result["visibility_aabb"] = [gp3.visibility_aabb.position.x, gp3.visibility_aabb.position.y, gp3.visibility_aabb.position.z, gp3.visibility_aabb.size.x, gp3.visibility_aabb.size.y, gp3.visibility_aabb.size.z]
		if gp3.process_material:
			result["material_type"] = gp3.process_material.get_class()
			_fill_material_info(result, gp3.process_material as ParticleProcessMaterial)
		var dp1_3d = gp3.get("draw_pass_1")
		if dp1_3d != null:
			result["draw_pass_1"] = dp1_3d.get_class()
		var dp2_3d = gp3.get("draw_pass_2")
		if dp2_3d != null:
			result["draw_pass_2"] = dp2_3d.get_class()
	else:
		return {"error": "Node is not a particle emitter: %s" % node.get_class()}

	return {"result": result}


## Fill material sub-properties, emission shape, color gradient, and velocity curve into a result dict.
func _fill_material_info(result: Dictionary, mat: ParticleProcessMaterial) -> void:
	result["material"] = {
		"direction": [mat.direction.x, mat.direction.y, mat.direction.z],
		"spread": mat.spread,
		"flatness": mat.flatness,
		"initial_velocity_min": mat.initial_velocity_min,
		"initial_velocity_max": mat.initial_velocity_max,
		"gravity": [mat.gravity.x, mat.gravity.y, mat.gravity.z],
		"scale_min": mat.scale_min,
		"scale_max": mat.scale_max,
		"color": "#%s" % mat.color.to_html(),
		"lifetime_randomness": mat.lifetime_randomness,
		"damping_min": mat.damping_min,
		"damping_max": mat.damping_max,
		"angle_min": mat.angle_min,
		"angle_max": mat.angle_max,
		"orbit_velocity_min": mat.orbit_velocity_min,
		"orbit_velocity_max": mat.orbit_velocity_max,
		"radial_accel_min": mat.radial_accel_min,
		"radial_accel_max": mat.radial_accel_max,
		"tangential_accel_min": mat.tangential_accel_min,
		"tangential_accel_max": mat.tangential_accel_max,
	}

	# Emission shape
	match mat.emission_shape:
		ParticleProcessMaterial.EMISSION_SHAPE_POINT:
			result["emission_shape"] = {"shape": "point"}
		ParticleProcessMaterial.EMISSION_SHAPE_SPHERE:
			result["emission_shape"] = {"shape": "sphere", "radius": mat.emission_sphere_radius}
		ParticleProcessMaterial.EMISSION_SHAPE_BOX:
			var ext: Vector3 = mat.emission_box_extents
			result["emission_shape"] = {"shape": "box", "size": [ext.x, ext.y, ext.z]}
		ParticleProcessMaterial.EMISSION_SHAPE_RING:
			result["emission_shape"] = {
				"shape": "ring",
				"radius": mat.emission_ring_radius,
				"height": mat.emission_ring_height,
				"inner_radius": mat.emission_ring_inner_radius,
			}

	# Color gradient
	var color_ramp_tex: Texture2D = mat.color_ramp
	if color_ramp_tex != null and color_ramp_tex is GradientTexture1D:
		var grad: Gradient = (color_ramp_tex as GradientTexture1D).gradient
		if grad != null:
			var grad_points: Array = []
			for i: int in range(grad.get_point_count()):
				grad_points.append({
					"offset": grad.get_offset(i),
					"color": "#%s" % grad.get_color(i).to_html(),
				})
			if not grad_points.is_empty():
				result["color_gradient"] = grad_points

	# Velocity curve
	var curve_tex: Texture2D = mat.velocity_limit_curve
	if curve_tex != null and curve_tex is CurveTexture:
		var curve: Curve = (curve_tex as CurveTexture).curve
		if curve != null:
			var curve_points: Array = []
			for i: int in range(curve.get_point_count()):
				var pt: Vector2 = curve.get_point_position(i)
				curve_points.append({"offset": pt.x, "value": pt.y})
			if not curve_points.is_empty():
				result["velocity_curve"] = curve_points


## Set the emission shape on a particle system's process material.
func set_particle_emission_shape(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var shape_type: String = params.get("shape", "point")
	var properties: Dictionary = params.get("properties", {})
	var size_array: Array = params.get("size", []) as Array if params.get("size", null) is Array else []
	if path.is_empty():
		return {"error": "Path is required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
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
		return {"error": "Node is not a particle emitter: %s" % node.get_class()}
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
			elif size_array.size() >= 2:
				process_mat.emission_ring_height = size_array[1] as float
			if properties.has("inner_radius"):
				process_mat.emission_ring_inner_radius = properties["inner_radius"] as float
			elif size_array.size() >= 3:
				process_mat.emission_ring_inner_radius = size_array[2] as float
		_:
			return {"error": "Unknown emission shape: %s (available: point, sphere, box, ring)" % shape_type}
	return {"result": "Emission shape '%s' set on %s" % [shape_type, path]}


## Read the emission shape configuration from a particle system.
func get_particle_emission_shape(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	var process_mat: ParticleProcessMaterial = null
	if node is GPUParticles2D:
		process_mat = (node as GPUParticles2D).process_material as ParticleProcessMaterial
	elif node is GPUParticles3D:
		process_mat = (node as GPUParticles3D).process_material as ParticleProcessMaterial
	else:
		return {"error": "Node is not a particle emitter"}
	if process_mat == null:
		return {"error": "No process material set on %s" % path}

	var shape_name: String = "point"
	var shape_properties: Dictionary = {}
	match process_mat.emission_shape:
		ParticleProcessMaterial.EMISSION_SHAPE_POINT:
			shape_name = "point"
		ParticleProcessMaterial.EMISSION_SHAPE_SPHERE:
			shape_name = "sphere"
			shape_properties["radius"] = process_mat.emission_sphere_radius
		ParticleProcessMaterial.EMISSION_SHAPE_BOX:
			shape_name = "box"
			var ext: Vector3 = process_mat.emission_box_extents
			shape_properties["size"] = [ext.x, ext.y, ext.z]
		ParticleProcessMaterial.EMISSION_SHAPE_RING:
			shape_name = "ring"
			shape_properties["radius"] = process_mat.emission_ring_radius
			shape_properties["height"] = process_mat.emission_ring_height
			shape_properties["inner_radius"] = process_mat.emission_ring_inner_radius

	var result: Dictionary = {
		"path": path,
		"shape": shape_name,
	}
	if not shape_properties.is_empty():
		result["properties"] = shape_properties
	return {"result": result}


## Set a velocity curve on a particle system's process material.
func set_particle_velocity_curve(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var curve_data: Variant = params.get("curve", [])
	if path.is_empty():
		return {"error": "Path is required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
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
		return {"error": "Node is not a particle emitter: %s" % node.get_class()}
	var curve: Curve = Curve.new()
	var points: Array = curve_data as Array if curve_data is Array else []
	if points.is_empty():
		return {"error": "Curve array is empty — provide at least one velocity point"}
	# Collect and sort points by offset; also track min/max Y for curve bounds
	var sorted_points: Array = []
	var min_y: float = INF
	var max_y: float = -INF
	for pt: Variant in points:
		var pt_dict: Dictionary = pt as Dictionary
		var x: float = pt_dict.get("offset", pt_dict.get("x", 0.0)) as float
		var y: float = pt_dict.get("value", pt_dict.get("y", 0.0)) as float
		sorted_points.append({"x": x, "y": y})
		min_y = min(min_y, y)
		max_y = max(max_y, y)
	sorted_points.sort_custom(func(a, b): return a.x < b.x)
	var was_sorted: bool = true
	for i: int in range(points.size()):
		var orig: Dictionary = points[i] as Dictionary
		var orig_x: float = orig.get("offset", orig.get("x", 0.0)) as float
		if sorted_points[i].x != orig_x:
			was_sorted = false
			break
	# Expand curve bounds to fit the actual data before adding points
	# (Curve.add_point clamps Y to [min_value, max_value] range, default 0-1)
	curve.min_value = min(min_y, 0.0)
	curve.max_value = max(max_y, 1.0)
	for sp: Dictionary in sorted_points:
		curve.add_point(Vector2(sp.x, sp.y))
	# velocity_limit_curve expects CurveTexture (Ref<Texture2D>), not plain Curve
	var curve_tex: CurveTexture = CurveTexture.new()
	curve_tex.curve = curve
	process_mat.velocity_limit_curve = curve_tex
	if not was_sorted:
		return {"result": "Velocity curve set on %s (points were auto-sorted by offset)" % path}
	return {"result": "Velocity curve set on %s" % path}


## Read the velocity curve from a particle system.
func get_particle_velocity_curve(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	var process_mat: ParticleProcessMaterial = null
	if node is GPUParticles2D:
		process_mat = (node as GPUParticles2D).process_material as ParticleProcessMaterial
	elif node is GPUParticles3D:
		process_mat = (node as GPUParticles3D).process_material as ParticleProcessMaterial
	else:
		return {"error": "Node is not a particle emitter"}
	if process_mat == null:
		return {"error": "No process material set on %s" % path}

	var curve_tex: Texture2D = process_mat.velocity_limit_curve
	if curve_tex == null:
		return {"error": "No velocity curve set on %s" % path}

	var curve: Curve = null
	if curve_tex is CurveTexture:
		curve = (curve_tex as CurveTexture).curve
	if curve == null:
		return {"error": "Velocity curve is not a valid CurveTexture on %s" % path}

	var points: Array = []
	for i: int in range(curve.get_point_count()):
		var pt: Vector2 = curve.get_point_position(i)
		var point: Dictionary = {
			"offset": pt.x,
			"value": pt.y,
		}
		points.append(point)

	return {"result": {"path": path, "curve": points}}


## Delete a particle system node from the scene.
func _delete_particles(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "").strip_edges()
	if node_path.is_empty():
		return {"error": "node_path is required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	if node == root:
		return {"error": "Cannot delete scene root"}

	if not (node is GPUParticles2D or node is GPUParticles3D):
		return {"error": "Node is not a particle system: %s" % node.get_class()}

	var parent: Node = node.get_parent()
	if parent == null:
		return {"error": "Node has no parent"}

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

	return {"result": {"node_path": node_path, "type": node.get_class()}}
