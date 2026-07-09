## Physics commands module - 11 tools.
## Handles physics bodies, collision, layers, and raycasts.
class_name MCPPhysicsCommands
extends RefCounted

var _plugin: EditorPlugin
var _undo_helper: MCUndoHelper


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin
	if _plugin.has_method("get_undo_helper"):
		_undo_helper = _plugin.get_undo_helper()


func get_commands() -> Dictionary:
	return {
		"physics/setup_body": setup_physics_body,
		"physics/setup_collision": setup_collision,
		"physics/set_layers": set_physics_layers,
		"physics/get_layers": get_physics_layers,
		"physics/get_collision_info": get_collision_info,
		"physics/add_raycast": add_raycast,
		"physics/get_material": get_physics_material,
		"physics/set_material": set_physics_material,
		"physics/get_body": get_physics_body,
		"physics/remove_collision": remove_collision,
		"physics/remove_raycast": remove_raycast,
	}


## Setup physics properties on a body node.
func setup_physics_body(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var properties: Dictionary = params.get("properties", {})
	if path.is_empty():
		return {"error": "Path is required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	# Check if it's a physics body (direct type or via script inheritance)
	var is_physics: bool = node is RigidBody2D or node is RigidBody3D or node is CharacterBody2D or node is CharacterBody3D or node is StaticBody2D or node is StaticBody3D
	if not is_physics:
		# Fallback: check script base class for nodes with attached scripts
		var scr: Script = node.get_script()
		if scr:
			var base_type: String = scr.get_instance_base_type()
			is_physics = base_type == "RigidBody2D" or base_type == "RigidBody3D" or base_type == "CharacterBody2D" or base_type == "CharacterBody3D" or base_type == "StaticBody2D" or base_type == "StaticBody3D"
	if not is_physics:
		return {"error": "Node is not a physics body: %s" % node.get_class()}

	for prop: String in properties:
		if MCPCommandHelpers.has_property(node, prop):
			var val: Variant = MCPVariantCodec.parse_for_property(properties[prop], MCPCommandHelpers.get_property_type(node, prop))
			if _undo_helper:
				_undo_helper.set_property_with_undo(node, prop, val)
			else:
				node.set(prop, val)
	return {"result": "Physics body properties set on %s" % path}


## Setup a collision shape on a node.
func setup_collision(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var shape_type: String = params.get("shape_type", "rectangle")
	var properties: Dictionary = params.get("properties", {})
	if path.is_empty():
		return {"error": "Path is required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var shape: Shape2D = null
	var shape3d: Shape3D = null
	var col_node: Node = null
	match shape_type:
		"circle", "CircleShape2D":
			var cs: CircleShape2D = CircleShape2D.new()
			cs.radius = properties.get("radius", 10.0) as float
			shape = cs
		"rectangle", "RectangleShape2D":
			var rs: RectangleShape2D = RectangleShape2D.new()
			var sx: float = properties.get("width", 10.0) as float
			var sy: float = properties.get("height", 10.0) as float
			rs.size = Vector2(sx, sy)
			shape = rs
		"capsule", "CapsuleShape2D":
			var cs2: CapsuleShape2D = CapsuleShape2D.new()
			cs2.radius = properties.get("radius", 10.0) as float
			cs2.height = properties.get("height", 20.0) as float
			shape = cs2
		"box", "BoxShape3D":
			var bs: BoxShape3D = BoxShape3D.new()
			if properties.has("size"):
				bs.size = MCPVariantCodec._parse_vector3(properties["size"])
			else:
				bs.size = Vector3(
					properties.get("width", 1.0) as float,
					properties.get("height", 1.0) as float,
					properties.get("depth", 1.0) as float
				)
			shape3d = bs
		"sphere", "SphereShape3D":
			var ss: SphereShape3D = SphereShape3D.new()
			ss.radius = properties.get("radius", 0.5) as float
			shape3d = ss
		"capsule3d":
			var cs3: CapsuleShape3D = CapsuleShape3D.new()
			cs3.radius = properties.get("radius", 0.5) as float
			cs3.height = properties.get("height", 1.0) as float
			shape3d = cs3
		"convex", "ConvexPolygonShape2D":
			var cv: ConvexPolygonShape2D = ConvexPolygonShape2D.new()
			shape = cv
		"concave", "ConcavePolygonShape2D":
			var cc: ConcavePolygonShape2D = ConcavePolygonShape2D.new()
			shape = cc
		"polygon", "CollisionPolygon2D":
			var cp: CollisionPolygon2D = CollisionPolygon2D.new()
			shape = null  # CollisionPolygon2D is not a Shape2D, handled separately
			col_node = cp
			col_node.name = "CollisionPolygon"
			if _undo_helper:
				_undo_helper.add_node_with_undo(col_node, node)
				col_node.set_owner(MCPCommandHelpers.get_scene_root(_plugin))
			else:
				node.add_child(col_node)
				col_node.set_owner(MCPCommandHelpers.get_scene_root(_plugin))
			return {"result": {"shape_type": "polygon", "node": MCPCommandHelpers.get_node_path(col_node, _plugin)}}
		"cylinder", "CylinderShape3D":
			var cyl: CylinderShape3D = CylinderShape3D.new()
			cyl.radius = properties.get("radius", 0.5) as float
			cyl.height = properties.get("height", 2.0) as float
			shape3d = cyl

	# Create or find CollisionShape node — skip mismatched dimensions
	for child: Node in node.get_children():
		if child is CollisionShape2D or child is CollisionShape3D:
			# Only reuse if dimension matches the requested shape type
			if shape and child is CollisionShape2D:
				col_node = child
				break
			if shape3d and child is CollisionShape3D:
				col_node = child
				break
			# Mismatch — remove old node, will create new below
			if _undo_helper:
				_undo_helper.remove_node_with_undo(child)
			else:
				child.queue_free()
	if col_node == null:
		if shape:
			col_node = CollisionShape2D.new()
		else:
			col_node = CollisionShape3D.new()
		col_node.name = "CollisionShape"
		if _undo_helper:
			_undo_helper.add_node_with_undo(col_node, node)
		else:
			node.add_child(col_node)
			col_node.set_owner(MCPCommandHelpers.get_scene_root(_plugin))

	if col_node is CollisionShape2D and shape:
		(col_node as CollisionShape2D).shape = shape
	elif col_node is CollisionShape3D and shape3d:
		(col_node as CollisionShape3D).shape = shape3d

	return {"result": {"shape_type": shape_type, "node": MCPCommandHelpers.get_node_path(col_node, _plugin)}}


## Set physics collision layers and mask.
## Layer/mask values are layer NUMBERS (1-32), converted to bitmask internally.
func set_physics_layers(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var layer: int = params.get("layer", 0)
	var mask: int = params.get("mask", 0)
	if path.is_empty():
		return {"error": "Path is required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	if node is CollisionObject2D:
		var co: CollisionObject2D = node as CollisionObject2D
		if layer > 0 and layer <= 32:
			co.collision_layer = 1 << (layer - 1)
		if mask > 0 and mask <= 32:
			co.collision_mask = 1 << (mask - 1)
		# Report layer numbers (1-32), not raw bitmask values, for consistency with input
		var current_layers: Array[int] = _bitmask_to_layer_numbers(co.collision_layer)
		var current_masks: Array[int] = _bitmask_to_layer_numbers(co.collision_mask)
		var layer_str: String = ",".join(current_layers) if not current_layers.is_empty() else "none"
		var mask_str: String = ",".join(current_masks) if not current_masks.is_empty() else "none"
		return {"result": "Physics layers set on %s (layers=[%s], masks=[%s])" % [path, layer_str, mask_str]}
	elif node is CollisionObject3D:
		var co3: CollisionObject3D = node as CollisionObject3D
		if layer > 0 and layer <= 32:
			co3.collision_layer = 1 << (layer - 1)
		if mask > 0 and mask <= 32:
			co3.collision_mask = 1 << (mask - 1)
		var current_layers: Array[int] = _bitmask_to_layer_numbers(co3.collision_layer)
		var current_masks: Array[int] = _bitmask_to_layer_numbers(co3.collision_mask)
		var layer_str: String = ",".join(current_layers) if not current_layers.is_empty() else "none"
		var mask_str: String = ",".join(current_masks) if not current_masks.is_empty() else "none"
		return {"result": "Physics layers set on %s (layers=[%s], masks=[%s])" % [path, layer_str, mask_str]}
	else:
		return {"error": "Node is not a CollisionObject: %s" % node.get_class()}


## Convert a bitmask value to an array of layer numbers (1-based).
func _bitmask_to_layer_numbers(bitmask: int) -> Array[int]:
	var layers: Array[int] = []
	for i: int in range(32):
		if bitmask & (1 << i):
			layers.append(i + 1)
	return layers


## Get physics collision layers.
func get_physics_layers(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var result: Dictionary = {"path": path}
	if node is CollisionObject2D:
		var co: CollisionObject2D = node as CollisionObject2D
		result["collision_layer"] = _bitmask_to_layer_numbers(co.collision_layer)
		result["collision_mask"] = _bitmask_to_layer_numbers(co.collision_mask)
		result["collision_layer_bitmask"] = co.collision_layer
		result["collision_mask_bitmask"] = co.collision_mask
	elif node is CollisionObject3D:
		var co3: CollisionObject3D = node as CollisionObject3D
		result["collision_layer"] = _bitmask_to_layer_numbers(co3.collision_layer)
		result["collision_mask"] = _bitmask_to_layer_numbers(co3.collision_mask)
		result["collision_layer_bitmask"] = co3.collision_layer
		result["collision_mask_bitmask"] = co3.collision_mask
	else:
		return {"error": "Node is not a CollisionObject: %s" % node.get_class()}
	return {"result": result}


## Get collision info for a node.
func get_collision_info(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var result: Dictionary = {"path": path, "type": node.get_class()}
	var shapes: Array = []
	if node is CollisionObject2D:
		var co: CollisionObject2D = node as CollisionObject2D
		for i: int in range(co.get_child_count()):
			var child: Node = co.get_child(i)
			if child is CollisionShape2D:
				var cs: CollisionShape2D = child as CollisionShape2D
				shapes.append({
					"name": str(cs.name),
					"shape": cs.shape.get_class() if cs.shape else "null",
					"disabled": cs.disabled,
				})
	elif node is CollisionObject3D:
		var co3: CollisionObject3D = node as CollisionObject3D
		for i: int in range(co3.get_child_count()):
			var child: Node = co3.get_child(i)
			if child is CollisionShape3D:
				var cs3: CollisionShape3D = child as CollisionShape3D
				shapes.append({
					"name": str(cs3.name),
					"shape": cs3.shape.get_class() if cs3.shape else "null",
					"disabled": cs3.disabled,
				})
	result["shapes"] = shapes
	return {"result": result}


## Add a RayCast node to a body.
func add_raycast(params: Dictionary) -> Dictionary:
	var path: String = params.get("parent_path", params.get("path", ""))
	var properties: Dictionary = params.get("properties", {})

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var parent: Node = root
	if not path.is_empty():
		parent = root.get_node_or_null(path)
		if parent == null:
			return {"error": "Node not found: %s" % path}

	var is_2d: bool = parent is Node2D
	var is_3d: bool = parent is Node3D
	if not is_2d and not is_3d:
		return {"error": "Parent must be Node2D or Node3D, got: %s" % parent.get_class()}
	var raycast: Node = null
	if is_2d:
		var rc: RayCast2D = RayCast2D.new()
		var target: Dictionary = properties.get("target", {})
		rc.target_position = Vector2(target.get("x", 0.0) as float, target.get("y", 100.0) as float)
		if properties.has("collision_mask"):
			rc.collision_mask = properties["collision_mask"] as int
		raycast = rc
	else:
		var rc3: RayCast3D = RayCast3D.new()
		var target3: Dictionary = properties.get("target", {})
		rc3.target_position = Vector3(target3.get("x", 0.0) as float, target3.get("y", 0.0) as float, target3.get("z", -1.0) as float)
		if properties.has("collision_mask"):
			rc3.collision_mask = properties["collision_mask"] as int
		raycast = rc3
	raycast.name = properties.get("name", "RayCast")

	if _undo_helper:
		_undo_helper.add_node_with_undo(raycast, parent)
	else:
		parent.add_child(raycast)
		raycast.set_owner(MCPCommandHelpers.get_scene_root(_plugin))

	return {"result": {"name": str(raycast.name), "path": MCPCommandHelpers.get_node_path(raycast, _plugin), "is_2d": is_2d}}


## Get physics material properties from a node.
func get_physics_material(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	var mat: PhysicsMaterial = null
	if node is RigidBody2D:
		mat = (node as RigidBody2D).physics_material_override
	elif node is StaticBody2D:
		mat = (node as StaticBody2D).physics_material_override
	elif node is RigidBody3D:
		mat = (node as RigidBody3D).physics_material_override
	elif node is StaticBody3D:
		mat = (node as StaticBody3D).physics_material_override
	else:
		# Fallback: check script base class
		var scr: Script = node.get_script()
		if scr:
			var bt: String = scr.get_instance_base_type()
			if bt == "RigidBody2D" or bt == "StaticBody2D" or bt == "RigidBody3D" or bt == "StaticBody3D":
				mat = node.physics_material_override
			else:
				return {"error": "Node type '%s' does not support physics_material_override. Supported types: RigidBody2D, RigidBody3D, StaticBody2D, StaticBody3D." % node.get_class()}
		else:
			return {"error": "Node type '%s' does not support physics_material_override. Supported types: RigidBody2D, RigidBody3D, StaticBody2D, StaticBody3D." % node.get_class()}
	if mat == null:
		return {"result": {"path": path, "has_material": false}}
	return {"result": {
		"path": path,
		"has_material": true,
		"friction": mat.friction,
		"rough": mat.rough,
		"bounce": mat.bounce,
		"absorbent": mat.absorbent,
	}}


## Create and set a physics material on a node.
func set_physics_material(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	# Accept both nested properties dict and flat top-level params
	var properties: Dictionary = params.get("properties", {})
	if properties.is_empty():
		# Try reading flat params (friction, bounce, rough, absorbent)
		if params.has("friction"):
			properties["friction"] = params["friction"]
		if params.has("rough"):
			properties["rough"] = params["rough"]
		if params.has("bounce"):
			properties["bounce"] = params["bounce"]
		if params.has("absorbent"):
			properties["absorbent"] = params["absorbent"]
	if path.is_empty():
		return {"error": "Path is required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	var mat: PhysicsMaterial = PhysicsMaterial.new()
	if properties.has("friction"):
		mat.friction = properties["friction"] as float
	if properties.has("rough"):
		mat.rough = properties["rough"] as bool
	if properties.has("bounce"):
		mat.bounce = properties["bounce"] as float
	if properties.has("absorbent"):
		mat.absorbent = properties["absorbent"] as bool
	var material_set: bool = false
	if node is RigidBody2D or node is StaticBody2D:
		if _undo_helper:
			_undo_helper.set_property_with_undo(node, "physics_material_override", mat)
		else:
			node.physics_material_override = mat
		material_set = true
	elif node is RigidBody3D or node is StaticBody3D:
		if _undo_helper:
			_undo_helper.set_property_with_undo(node, "physics_material_override", mat)
		else:
			node.physics_material_override = mat
		material_set = true
	else:
		# Fallback: check script base class
		var scr: Script = node.get_script()
		if scr:
			var bt: String = scr.get_instance_base_type()
			if bt == "RigidBody2D" or bt == "StaticBody2D" or bt == "RigidBody3D" or bt == "StaticBody3D":
				if _undo_helper:
					_undo_helper.set_property_with_undo(node, "physics_material_override", mat)
				else:
					node.physics_material_override = mat
				material_set = true
	if not material_set:
		return {"error": "Node type '%s' does not support physics_material_override. Supported types: RigidBody2D, RigidBody3D, StaticBody2D, StaticBody3D." % node.get_class()}
	return {"result": {"path": path, "friction": mat.friction, "rough": mat.rough, "bounce": mat.bounce, "absorbent": mat.absorbent}}


## Get physics body properties from a node.
func get_physics_body(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	# Check if it's a physics body (direct type or via script inheritance)
	var is_physics: bool = node is RigidBody2D or node is RigidBody3D or node is CharacterBody2D or node is CharacterBody3D or node is StaticBody2D or node is StaticBody3D
	if not is_physics:
		var scr: Script = node.get_script()
		if scr:
			var base_type: String = scr.get_instance_base_type()
			is_physics = base_type == "RigidBody2D" or base_type == "RigidBody3D" or base_type == "CharacterBody2D" or base_type == "CharacterBody3D" or base_type == "StaticBody2D" or base_type == "StaticBody3D"
	if not is_physics:
		return {"error": "Node is not a physics body: %s" % node.get_class()}

	var result: Dictionary = {"path": path, "type": node.get_class()}
	var read_props: PackedStringArray = ["mass", "gravity_scale", "linear_damp", "angular_damp"]
	for prop: String in read_props:
		if MCPCommandHelpers.has_property(node, prop):
			result[prop] = node.get(prop)
		else:
			result[prop] = null
	return {"result": result}


## Remove collision shape(s) from a physics body.
func remove_collision(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var shape_name: String = params.get("name", "")
	if path.is_empty():
		return {"error": "Path is required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var removed: Array = []
	for i: int in range(node.get_child_count() - 1, -1, -1):
		var child: Node = node.get_child(i)
		if child is CollisionShape2D or child is CollisionShape3D or child is CollisionPolygon2D:
			if shape_name.is_empty() or str(child.name) == shape_name:
				removed.append(str(child.name))
				if _undo_helper:
					_undo_helper.remove_node_with_undo(child)
				else:
					node.remove_child(child)
					child.queue_free()
	if removed.is_empty():
		if shape_name.is_empty():
			return {"error": "No collision shapes found on %s" % path}
		else:
			return {"error": "Collision shape '%s' not found on %s" % [shape_name, path]}
	return {"result": {"path": path, "removed": removed}}


## Remove a RayCast node from a parent.
func remove_raycast(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var raycast_name: String = params.get("name", "")
	if path.is_empty():
		return {"error": "Path is required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var removed: Array = []
	for i: int in range(node.get_child_count() - 1, -1, -1):
		var child: Node = node.get_child(i)
		if child is RayCast2D or child is RayCast3D:
			if raycast_name.is_empty() or str(child.name) == raycast_name:
				removed.append(str(child.name))
				if _undo_helper:
					_undo_helper.remove_node_with_undo(child)
				else:
					node.remove_child(child)
					child.queue_free()
	if removed.is_empty():
		if raycast_name.is_empty():
			return {"error": "No RayCast nodes found on %s" % path}
		else:
			return {"error": "RayCast '%s' not found on %s" % [raycast_name, path]}
	return {"result": {"path": path, "removed": removed}}


