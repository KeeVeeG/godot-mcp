## 3D Scene commands module - 12 tools.
## Handles 3D meshes, cameras, lighting, environment, and materials.
class_name MCPScene3DCommands
extends RefCounted

var _plugin: EditorPlugin
var _undo_helper: MCUndoHelper


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin
	if _plugin.has_method("get_undo_helper"):
		_undo_helper = _plugin.get_undo_helper()


func get_commands() -> Dictionary:
	return {
		"scene3d/add_mesh": add_mesh_instance,
		"scene3d/get_mesh": get_mesh_instance,
		"scene3d/setup_camera": setup_camera_3d,
		"scene3d/get_camera": get_camera_3d,
		"scene3d/setup_lighting": setup_lighting,
		"scene3d/get_lighting": get_lighting,
		"scene3d/setup_environment": setup_environment,
		"scene3d/get_environment": get_environment,
		"scene3d/add_gridmap": add_gridmap,
		"scene3d/get_gridmap": get_gridmap,
		"scene3d/set_material": set_material_3d,
		"scene3d/get_material": get_material_3d,
	}


## Add a MeshInstance3D with a primitive mesh.
func add_mesh_instance(params: Dictionary) -> Dictionary:
	var parent_path: String = params.get("parent", params.get("parent_path", ""))
	var mesh_type: String = params.get("mesh_type", "cube")
	var properties: Dictionary = params.get("properties", {})

	var parent: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if parent_path != "":
		parent = MCPCommandHelpers.resolve_node_path(_plugin, parent_path)
	if parent == null:
		return {"error": "Parent not found"}

	var mesh: Mesh = null
	match mesh_type:
		"BoxMesh", "cube":
			var bm: BoxMesh = BoxMesh.new()
			if properties.has("size"):
				var s: Variant = properties["size"]
				if s is Dictionary:
					bm.size = Vector3((s as Dictionary).get("x", 1.0) as float, (s as Dictionary).get("y", 1.0) as float, (s as Dictionary).get("z", 1.0) as float)
				else:
					bm.size = MCPVariantCodec._parse_vector3(s)
			mesh = bm
		"SphereMesh", "sphere":
			var sm: SphereMesh = SphereMesh.new()
			sm.radius = properties.get("radius", 0.5) as float
			sm.height = properties.get("height", 1.0) as float
			mesh = sm
		"CylinderMesh", "cylinder":
			var cm: CylinderMesh = CylinderMesh.new()
			cm.top_radius = properties.get("top_radius", 0.5) as float
			cm.bottom_radius = properties.get("bottom_radius", 0.5) as float
			cm.height = properties.get("height", 1.0) as float
			mesh = cm
		"CapsuleMesh", "capsule":
			var cm2: CapsuleMesh = CapsuleMesh.new()
			cm2.radius = properties.get("radius", 0.5) as float
			cm2.height = properties.get("height", 1.0) as float
			mesh = cm2
		"PlaneMesh", "plane":
			var pm: PlaneMesh = PlaneMesh.new()
			var ps: Dictionary = properties.get("size", {})
			pm.size = Vector2(ps.get("x", 1.0) as float, ps.get("y", 1.0) as float)
			mesh = pm
		"TorusMesh", "torus":
			var tm: TorusMesh = TorusMesh.new()
			tm.inner_radius = properties.get("inner_radius", 0.25) as float
			tm.outer_radius = properties.get("outer_radius", 0.5) as float
			mesh = tm
		"PrismMesh", "prism":
			var prm: PrismMesh = PrismMesh.new()
			prm.left_to_right = properties.get("left_to_right", 0.5) as float
			prm.size = Vector3(properties.get("width", 1.0) as float, properties.get("height", 1.0) as float, properties.get("depth", 1.0) as float)
			mesh = prm
		_:
			mesh = BoxMesh.new()

	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = properties.get("name", mesh_type)

	# Apply position
	if properties.has("position"):
		mi.position = MCPVariantCodec._parse_vector3(properties["position"])
	if properties.has("scale"):
		mi.scale = MCPVariantCodec._parse_vector3(properties["scale"])

	# Apply material
	if properties.has("material_path"):
		var res: Resource = ResourceLoader.load(properties["material_path"] as String)
		var mat: Material = null
		if res is Shader:
			var sm: ShaderMaterial = ShaderMaterial.new()
			sm.shader = res as Shader
			mat = sm
		elif res is Material:
			mat = res as Material
		if mat:
			mi.material_override = mat

	if _undo_helper:
		_undo_helper.add_node_with_undo(mi, parent)
	else:
		parent.add_child(mi)
		mi.set_owner(MCPCommandHelpers.get_scene_root(_plugin))

	return {"result": {"name": str(mi.name), "path": MCPCommandHelpers.get_node_path(mi, _plugin), "mesh_type": mesh_type}}


## Get MeshInstance3D properties.
func get_mesh_instance(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required (node path to MeshInstance3D)"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	if not node is MeshInstance3D:
		return {"error": "Node is not a MeshInstance3D: %s" % path}

	var mi: MeshInstance3D = node as MeshInstance3D
	var mesh: Mesh = mi.mesh
	var result: Dictionary = {
		"path": MCPCommandHelpers.get_node_path(mi, _plugin),
		"name": mi.name,
		"position": {"x": mi.position.x, "y": mi.position.y, "z": mi.position.z},
		"scale": {"x": mi.scale.x, "y": mi.scale.y, "z": mi.scale.z},
	}
	if mesh:
		result["mesh_class"] = mesh.get_class()
		if mesh is BoxMesh:
			result["size"] = {"x": (mesh as BoxMesh).size.x, "y": (mesh as BoxMesh).size.y, "z": (mesh as BoxMesh).size.z}
		elif mesh is SphereMesh:
			result["radius"] = (mesh as SphereMesh).radius
			result["height"] = (mesh as SphereMesh).height
		elif mesh is CylinderMesh:
			result["top_radius"] = (mesh as CylinderMesh).top_radius
			result["bottom_radius"] = (mesh as CylinderMesh).bottom_radius
			result["height"] = (mesh as CylinderMesh).height
		elif mesh is CapsuleMesh:
			result["radius"] = (mesh as CapsuleMesh).radius
			result["height"] = (mesh as CapsuleMesh).height
		elif mesh is PlaneMesh:
			var pm: PlaneMesh = mesh as PlaneMesh
			result["size"] = {"x": pm.size.x, "y": pm.size.y}
		elif mesh is TorusMesh:
			result["inner_radius"] = (mesh as TorusMesh).inner_radius
			result["outer_radius"] = (mesh as TorusMesh).outer_radius
		elif mesh is PrismMesh:
			var prm: PrismMesh = mesh as PrismMesh
			result["size"] = {"x": prm.size.x, "y": prm.size.y, "z": prm.size.z}
			result["left_to_right"] = prm.left_to_right
	if mi.material_override:
		result["material_class"] = mi.material_override.get_class()
	return {"result": result}


## Setup Camera3D properties.
func setup_camera_3d(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var properties: Dictionary = params.get("properties", {})

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	# If path is empty, create a new Camera3D under root
	var cam: Camera3D = null
	if path.is_empty():
		cam = Camera3D.new()
		cam.name = properties.get("name", "Camera3D")
		if _undo_helper:
			_undo_helper.add_node_with_undo(cam, root)
		else:
			root.add_child(cam)
			cam.set_owner(root)
	else:
		var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
		if node == null:
			return {"error": "Node not found: %s" % path}
		if not node is Camera3D:
			return {"error": "Node is not a Camera3D: %s" % path}
		cam = node as Camera3D

	if properties.has("fov"):
		cam.fov = properties["fov"] as float
	if properties.has("near"):
		cam.near = properties["near"] as float
	if properties.has("far"):
		cam.far = properties["far"] as float
	if properties.has("projection"):
		cam.projection = properties["projection"] as int
	if properties.has("current") or properties.has("make_current"):
		cam.current = properties.get("current", properties.get("make_current", false)) as bool
	if properties.has("position"):
		cam.position = MCPVariantCodec._parse_vector3(properties["position"])
	if properties.has("look_at"):
		cam.look_at_from_position(cam.position, MCPVariantCodec._parse_vector3(properties["look_at"]))
	if properties.has("rotation"):
		cam.rotation = MCPVariantCodec._parse_vector3(properties["rotation"])

	return {"result": "Camera3D configured: %s" % path}


## Get Camera3D properties.
func get_camera_3d(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required (node path to Camera3D)"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	if not node is Camera3D:
		return {"error": "Node is not a Camera3D: %s" % path}

	var cam: Camera3D = node as Camera3D
	return {"result": {
		"path": MCPCommandHelpers.get_node_path(cam, _plugin),
		"name": cam.name,
		"fov": cam.fov,
		"near": cam.near,
		"far": cam.far,
		"projection": cam.projection,
		"current": cam.current,
		"position": {"x": cam.position.x, "y": cam.position.y, "z": cam.position.z},
		"rotation": {"x": cam.rotation.x, "y": cam.rotation.y, "z": cam.rotation.z},
	}}


## Setup lighting (DirectionalLight3D, OmniLight3D, SpotLight3D).
func setup_lighting(params: Dictionary) -> Dictionary:
	var parent_path: String = params.get("parent", params.get("parent_path", ""))
	var light_type: String = params.get("light_type", params.get("type", "directional"))
	var properties: Dictionary = params.get("properties", {})

	var parent: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if parent_path != "":
		parent = MCPCommandHelpers.resolve_node_path(_plugin, parent_path)
	if parent == null:
		return {"error": "Parent not found"}

	var light: Light3D = null
	match light_type:
		"DirectionalLight3D", "directional":
			light = DirectionalLight3D.new()
		"OmniLight3D", "omni":
			light = OmniLight3D.new()
			if properties.has("omni_range"):
				(light as OmniLight3D).omni_range = properties["omni_range"] as float
		"SpotLight3D", "spot":
			light = SpotLight3D.new()
			if properties.has("spot_angle"):
				(light as SpotLight3D).spot_angle = properties["spot_angle"] as float
			if properties.has("spot_range"):
				(light as SpotLight3D).spot_range = properties["spot_range"] as float
		_:
			light = DirectionalLight3D.new()

	light.name = properties.get("name", light_type)
	light.light_color = MCPVariantCodec._parse_color(properties.get("color", "#ffffff"))
	light.light_energy = properties.get("energy", 1.0) as float
	if properties.has("position"):
		light.position = MCPVariantCodec._parse_vector3(properties["position"])
	if properties.has("rotation"):
		light.rotation = MCPVariantCodec._parse_vector3(properties["rotation"])
	if properties.has("shadow_enabled"):
		light.shadow_enabled = properties["shadow_enabled"] as bool

	if _undo_helper:
		_undo_helper.add_node_with_undo(light, parent)
	else:
		parent.add_child(light)
		light.set_owner(MCPCommandHelpers.get_scene_root(_plugin))

	return {"result": {"name": str(light.name), "path": MCPCommandHelpers.get_node_path(light, _plugin), "type": light_type}}


## Get Light3D properties.
func get_lighting(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required (node path to Light3D)"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	if not node is Light3D:
		return {"error": "Node is not a Light3D: %s" % path}

	var light: Light3D = node as Light3D
	var result: Dictionary = {
		"path": MCPCommandHelpers.get_node_path(light, _plugin),
		"name": light.name,
		"type": light.get_class(),
		"color": {"r": light.light_color.r, "g": light.light_color.g, "b": light.light_color.b, "a": light.light_color.a},
		"energy": light.light_energy,
		"shadow_enabled": light.shadow_enabled,
		"position": {"x": light.position.x, "y": light.position.y, "z": light.position.z},
		"rotation": {"x": light.rotation.x, "y": light.rotation.y, "z": light.rotation.z},
	}
	if light is OmniLight3D:
		result["omni_range"] = (light as OmniLight3D).omni_range
	if light is SpotLight3D:
		var spot: SpotLight3D = light as SpotLight3D
		result["spot_angle"] = spot.spot_angle
		result["spot_range"] = spot.spot_range
	return {"result": result}


## Setup WorldEnvironment node with environment settings.
func setup_environment(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var properties: Dictionary = params.get("properties", {})

	# Find or create WorldEnvironment
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var env_node: WorldEnvironment = null
	if path != "":
		var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
		if node is WorldEnvironment:
			env_node = node as WorldEnvironment
		elif node is Camera3D:
			# Create environment on camera
			var cam: Camera3D = node as Camera3D
			if cam.environment == null:
				cam.environment = Environment.new()
			var cam_env: Environment = cam.environment
			_apply_environment_props(cam_env, properties)
			return {"result": "Environment set on camera: %s" % path}
		elif node == null:
			return {"error": "Node not found: %s" % path}
		else:
			return {"error": "Node is not a WorldEnvironment or Camera3D: %s (type: %s)" % [path, node.get_class()]}
	else:
		# Find existing or create new
		for child: Node in root.get_children():
			if child is WorldEnvironment:
				env_node = child as WorldEnvironment
				break
		if env_node == null:
			env_node = WorldEnvironment.new()
			env_node.name = "WorldEnvironment"
			if _undo_helper:
				_undo_helper.add_node_with_undo(env_node, root)
			else:
				root.add_child(env_node)
				env_node.set_owner(root)

	if env_node.environment == null:
		env_node.environment = Environment.new()
	_apply_environment_props(env_node.environment, properties)
	return {"result": "Environment configured: %s" % MCPCommandHelpers.get_node_path(env_node, _plugin)}


## Get WorldEnvironment settings.
func get_environment(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var env_node: WorldEnvironment = null
	if path != "":
		var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
		if node is WorldEnvironment:
			env_node = node as WorldEnvironment
		elif node is Camera3D:
			var cam: Camera3D = node as Camera3D
			if cam.environment == null:
				return {"error": "Camera has no environment assigned"}
			return {"result": _env_to_dict(cam.environment, MCPCommandHelpers.get_node_path(node, _plugin))}
		else:
			return {"error": "Node not found or not a WorldEnvironment/Camera3D: %s" % path}
	else:
		for child: Node in root.get_children():
			if child is WorldEnvironment:
				env_node = child as WorldEnvironment
				break

	if env_node == null:
		return {"error": "No WorldEnvironment node found in scene"}
	if env_node.environment == null:
		return {"error": "WorldEnvironment has no Environment resource assigned"}
	return {"result": _env_to_dict(env_node.environment, MCPCommandHelpers.get_node_path(env_node, _plugin))}


func _env_to_dict(env: Environment, node_path: String) -> Dictionary:
	return {
		"path": node_path,
		"background_mode": env.background_mode,
		"ambient_light_color": {"r": env.ambient_light_color.r, "g": env.ambient_light_color.g, "b": env.ambient_light_color.b, "a": env.ambient_light_color.a},
		"ambient_light_energy": env.ambient_light_energy,
		"tonemap_mode": env.tonemap_mode,
		"ssao_enabled": env.ssao_enabled,
		"glow_enabled": env.glow_enabled,
		"fog_enabled": env.fog_enabled,
		"fog_color": {"r": env.fog_light_color.r, "g": env.fog_light_color.g, "b": env.fog_light_color.b, "a": env.fog_light_color.a},
		"fog_density": env.fog_density,
		"volumetric_fog_enabled": env.volumetric_fog_enabled,
	}


func _apply_environment_props(env: Environment, props: Dictionary) -> void:
	if props.has("background_mode"):
		env.background_mode = props["background_mode"] as int
	if props.has("ambient_light_color"):
		env.ambient_light_color = MCPVariantCodec._parse_color(props["ambient_light_color"])
	if props.has("ambient_light_energy"):
		env.ambient_light_energy = props["ambient_light_energy"] as float
	if props.has("tonemap_mode"):
		env.tonemap_mode = props["tonemap_mode"] as int
	if props.has("ssao_enabled"):
		env.ssao_enabled = props["ssao_enabled"] as bool
	if props.has("glow_enabled"):
		env.glow_enabled = props["glow_enabled"] as bool
	if props.has("fog_enabled"):
		env.fog_enabled = props["fog_enabled"] as bool
	if props.has("fog_color"):
		env.fog_light_color = MCPVariantCodec._parse_color(props["fog_color"])
	if props.has("fog_density"):
		env.fog_density = props["fog_density"] as float
	if props.has("volumetric_fog_enabled"):
		env.volumetric_fog_enabled = props["volumetric_fog_enabled"] as bool
	if props.has("sky"):
		var sky: Sky = ResourceLoader.load(props["sky"] as String) as Sky
		if sky:
			env.sky = sky


## Add a GridMap node.
func add_gridmap(params: Dictionary) -> Dictionary:
	var parent_path: String = params.get("parent", params.get("parent_path", ""))
	var properties: Dictionary = params.get("properties", {})

	var parent: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if parent_path != "":
		parent = MCPCommandHelpers.resolve_node_path(_plugin, parent_path)
	if parent == null:
		return {"error": "Parent not found"}

	var gridmap: GridMap = GridMap.new()
	gridmap.name = properties.get("name", "GridMap")

	if properties.has("cell_size"):
		gridmap.cell_size = MCPVariantCodec._parse_vector3(properties["cell_size"])
	if properties.has("mesh_library_path") or properties.has("mesh_library"):
		var mesh_lib_path: String = properties.get("mesh_library_path", properties.get("mesh_library", "")) as String
		var lib: MeshLibrary = ResourceLoader.load(mesh_lib_path) as MeshLibrary
		if lib:
			gridmap.mesh_library = lib
		else:
			return {"error": "MeshLibrary not found or invalid: %s" % mesh_lib_path}

	if _undo_helper:
		_undo_helper.add_node_with_undo(gridmap, parent)
	else:
		parent.add_child(gridmap)
		gridmap.set_owner(MCPCommandHelpers.get_scene_root(_plugin))

	return {"result": {"name": str(gridmap.name), "path": MCPCommandHelpers.get_node_path(gridmap, _plugin)}}


## Get GridMap node properties.
func get_gridmap(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required (node path to GridMap)"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	if not node is GridMap:
		return {"error": "Node is not a GridMap: %s" % path}

	var gm: GridMap = node as GridMap
	var result: Dictionary = {
		"path": MCPCommandHelpers.get_node_path(gm, _plugin),
		"name": gm.name,
		"cell_size": {"x": gm.cell_size.x, "y": gm.cell_size.y, "z": gm.cell_size.z},
	}
	if gm.mesh_library:
		result["mesh_library"] = gm.mesh_library.resource_path
	return {"result": result}


## Set material on a 3D node.
func set_material_3d(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var properties: Dictionary = params.get("properties", {})
	if path.is_empty():
		return {"error": "Path is required"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var mat: Material = null
	var mat_path: String = properties.get("material_path", properties.get("shader_path", "")) as String
	if mat_path != "":
		var res: Resource = ResourceLoader.load(mat_path)
		if res == null:
			return {"error": "Resource not found: %s" % mat_path}
		if res is Shader:
			# .gdshader files load as Shader, not Material — wrap in ShaderMaterial
			var sm: ShaderMaterial = ShaderMaterial.new()
			sm.shader = res as Shader
			mat = sm
		elif res is Material:
			mat = res as Material
		else:
			return {"error": "Resource is not a Material or Shader: %s (type: %s)" % [mat_path, res.get_class()]}
	else:
		var sm: StandardMaterial3D = StandardMaterial3D.new()
		if properties.has("albedo_color"):
			sm.albedo_color = MCPVariantCodec._parse_color(properties["albedo_color"])
		if properties.has("metallic"):
			sm.metallic = properties["metallic"] as float
		if properties.has("roughness"):
			sm.roughness = properties["roughness"] as float
		if properties.has("emission_enabled"):
			sm.emission_enabled = properties["emission_enabled"] as bool
		if properties.has("emission_color"):
			sm.emission = MCPVariantCodec._parse_color(properties["emission_color"])
		if properties.has("emission_energy_multiplier"):
			sm.emission_energy_multiplier = properties["emission_energy_multiplier"] as float
		mat = sm

	if node is MeshInstance3D:
		if _undo_helper:
			_undo_helper.set_property_with_undo(node, "material_override", mat)
		else:
			(node as MeshInstance3D).material_override = mat
	elif node is VisualInstance3D:
		if _undo_helper:
			_undo_helper.set_property_with_undo(node, "material_override", mat)
		else:
			(node as VisualInstance3D).material_override = mat
	else:
		return {"error": "Node does not support materials: %s" % node.get_class()}

	return {"result": "Material set on %s" % path}


## Get material properties from a 3D node.
func get_material_3d(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required (node path to MeshInstance3D/VisualInstance3D)"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var mat: Material = null
	if node is MeshInstance3D:
		mat = (node as MeshInstance3D).material_override
	elif node is VisualInstance3D:
		mat = (node as VisualInstance3D).material_override
	else:
		return {"error": "Node does not support materials: %s" % node.get_class()}

	if mat == null:
		return {"error": "Node has no material override assigned"}

	var result: Dictionary = {
		"path": MCPCommandHelpers.get_node_path(node, _plugin),
		"material_class": mat.get_class(),
	}
	if mat is StandardMaterial3D:
		var sm: StandardMaterial3D = mat as StandardMaterial3D
		result["albedo_color"] = {"r": sm.albedo_color.r, "g": sm.albedo_color.g, "b": sm.albedo_color.b, "a": sm.albedo_color.a}
		result["metallic"] = sm.metallic
		result["roughness"] = sm.roughness
		result["emission_enabled"] = sm.emission_enabled
		result["emission"] = {"r": sm.emission.r, "g": sm.emission.g, "b": sm.emission.b, "a": sm.emission.a}
		result["emission_energy_multiplier"] = sm.emission_energy_multiplier
	return {"result": result}
