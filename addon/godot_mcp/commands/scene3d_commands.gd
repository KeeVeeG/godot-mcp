## 3D Scene commands module - 6 tools.
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
		"scene3d/setup_camera": setup_camera_3d,
		"scene3d/setup_lighting": setup_lighting,
		"scene3d/setup_environment": setup_environment,
		"scene3d/add_gridmap": add_gridmap,
		"scene3d/set_material": set_material_3d,
	}


func _get_root() -> Node:
	return _plugin.get_editor_interface().get_edited_scene_root()


func _get_node(path: String) -> Node:
	var root: Node = _get_root()
	if root == null:
		return null
	return root.get_node_or_null(path)


## Add a MeshInstance3D with a primitive mesh.
func add_mesh_instance(params: Dictionary) -> Dictionary:
	var parent_path: String = params.get("parent", params.get("parent_path", ""))
	var mesh_type: String = params.get("mesh_type", "cube")
	var properties: Dictionary = params.get("properties", {})

	var parent: Node = _get_root()
	if parent_path != "":
		parent = _get_node(parent_path)
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

	# Apply material
	if properties.has("material_path"):
		var mat: Material = ResourceLoader.load(properties["material_path"] as String) as Material
		if mat:
			mi.material_override = mat

	if _undo_helper:
		_undo_helper.add_node_with_undo(mi, parent)
	else:
		parent.add_child(mi)
		mi.set_owner(_get_root())

	return {"result": {"name": str(mi.name), "path": str(mi.get_path()), "mesh_type": mesh_type}}


## Setup Camera3D properties.
func setup_camera_3d(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var properties: Dictionary = params.get("properties", {})

	var root: Node = _get_root()
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
		var node: Node = _get_node(path)
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
	if properties.has("current"):
		cam.current = properties["current"] as bool
	if properties.has("position"):
		cam.position = MCPVariantCodec._parse_vector3(properties["position"])
	if properties.has("rotation"):
		cam.rotation = MCPVariantCodec._parse_vector3(properties["rotation"])

	return {"result": "Camera3D configured: %s" % path}


## Setup lighting (DirectionalLight3D, OmniLight3D, SpotLight3D).
func setup_lighting(params: Dictionary) -> Dictionary:
	var parent_path: String = params.get("parent", params.get("parent_path", ""))
	var light_type: String = params.get("light_type", params.get("type", "directional"))
	var properties: Dictionary = params.get("properties", {})

	var parent: Node = _get_root()
	if parent_path != "":
		parent = _get_node(parent_path)
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

	if _undo_helper:
		_undo_helper.add_node_with_undo(light, parent)
	else:
		parent.add_child(light)
		light.set_owner(_get_root())

	return {"result": {"name": str(light.name), "path": str(light.get_path()), "type": light_type}}


## Setup WorldEnvironment node with environment settings.
func setup_environment(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var properties: Dictionary = params.get("properties", {})

	# Find or create WorldEnvironment
	var root: Node = _get_root()
	if root == null:
		return {"error": "No scene open"}

	var env_node: WorldEnvironment = null
	if path != "":
		var node: Node = _get_node(path)
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
	return {"result": "Environment configured: %s" % str(env_node.get_path())}


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

	var parent: Node = _get_root()
	if parent_path != "":
		parent = _get_node(parent_path)
	if parent == null:
		return {"error": "Parent not found"}

	var gridmap: GridMap = GridMap.new()
	gridmap.name = properties.get("name", "GridMap")

	if properties.has("cell_size"):
		gridmap.cell_size = MCPVariantCodec._parse_vector3(properties["cell_size"])
	if properties.has("mesh_library"):
		var lib: MeshLibrary = ResourceLoader.load(properties["mesh_library"] as String) as MeshLibrary
		if lib:
			gridmap.mesh_library = lib

	if _undo_helper:
		_undo_helper.add_node_with_undo(gridmap, parent)
	else:
		parent.add_child(gridmap)
		gridmap.set_owner(_get_root())

	return {"result": {"name": str(gridmap.name), "path": str(gridmap.get_path())}}


## Set material on a 3D node.
func set_material_3d(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var properties: Dictionary = params.get("properties", {})
	if path.is_empty():
		return {"error": "Path is required"}

	var node: Node = _get_node(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var mat: Material = null
	if properties.has("material_path"):
		mat = ResourceLoader.load(properties["material_path"] as String) as Material
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
			sm.emission_color = MCPVariantCodec._parse_color(properties["emission_color"])
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
