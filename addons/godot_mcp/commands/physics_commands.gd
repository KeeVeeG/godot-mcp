## Physics commands module - 11 tools.
## Handles physics bodies, collision, layers, and raycasts.
@tool
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

	var applied: Array[String] = []
	var skipped: Array[String] = []
	for prop: String in properties:
		if MCPCommandHelpers.has_property(node, prop):
			var prop_type: int = MCPCommandHelpers.get_property_type(node, prop)
			var val: Variant = MCPVariantCodec.parse_for_property(properties[prop], prop_type)
			# Validate type compatibility: reject if parse_for_property returned the input unchanged
			# and the types are incompatible (e.g., string passed for a float property).
			if typeof(val) != prop_type and prop_type != TYPE_NIL:
				# Check if it's a reasonable coercion (e.g., int→float)
				var ok_coercion: bool = (typeof(val) == TYPE_INT and prop_type == TYPE_FLOAT) or (typeof(val) == TYPE_FLOAT and prop_type == TYPE_INT)
				if not ok_coercion:
					return {"error": "Property '%s' on '%s' expects type %s, but received type %s (value: %s)" % [prop, node.get_class(), type_string(prop_type), type_string(typeof(val)), str(properties[prop])]}
			# Range validation for physics body properties.
			var is_rigid: bool = node is RigidBody2D or node is RigidBody3D
			if is_rigid:
				match prop:
					"mass":
						if typeof(val) == TYPE_FLOAT or typeof(val) == TYPE_INT:
							if float(val) <= 0.0:
								return {"error": "Property 'mass' must be > 0 (got %s). Mass <= 0 causes division by zero in physics engine." % str(val)}
					"linear_damp":
						if typeof(val) == TYPE_FLOAT or typeof(val) == TYPE_INT:
							if float(val) < 0.0:
								return {"error": "Property 'linear_damp' must be >= 0 (got %s). Negative damping is unstable." % str(val)}
					"angular_damp":
						if typeof(val) == TYPE_FLOAT or typeof(val) == TYPE_INT:
							if float(val) < 0.0:
								return {"error": "Property 'angular_damp' must be >= 0 (got %s). Negative damping is unstable." % str(val)}
			if _undo_helper:
				_undo_helper.set_property_with_undo(node, prop, val)
			else:
				node.set(prop, val)
			applied.append(prop)
		else:
			skipped.append(prop)
	if not skipped.is_empty():
		return {"result": "Physics body properties set on %s. Applied: [%s]. Skipped (not found on %s): [%s]" % [path, ", ".join(applied), node.get_class(), ", ".join(skipped)]}
	return {"result": "Physics body properties set on %s" % path}


## Shape types that are exclusively 2D (no 3D equivalent).
const _SHAPE_TYPES_2D_ONLY: Array[String] = ["circle", "rectangle", "polygon"]

## Shape types that are exclusively 3D (no 2D equivalent).
const _SHAPE_TYPES_3D_ONLY: Array[String] = ["box", "sphere", "cylinder"]

## Shape type → CollisionShape class name for dimension mismatch error messages.
const _SHAPE_TYPE_LABELS: Dictionary = {
	"circle": "CircleShape2D / CollisionShape2D",
	"rectangle": "RectangleShape2D / CollisionShape2D",
	"capsule": "CapsuleShape2D / CollisionShape2D or CapsuleShape3D / CollisionShape3D (auto-detected)",
	"box": "BoxShape3D / CollisionShape3D",
	"sphere": "SphereShape3D / CollisionShape3D",
	"cylinder": "CylinderShape3D / CollisionShape3D",
	"convex": "ConvexPolygonShape2D / CollisionShape2D or ConvexPolygonShape3D / CollisionShape3D (auto-detected)",
	"concave": "ConcavePolygonShape2D / CollisionShape2D or ConcavePolygonShape3D / CollisionShape3D (auto-detected)",
	"polygon": "CollisionPolygon2D",
}


## Setup a collision shape on a node.
## Auto-detects 2D/3D dimension from the parent node and maps shape types accordingly.
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

	# Validate that the node is a physics body (CollisionObject2D/3D).
	var is_collision_2d: bool = node is CollisionObject2D
	var is_collision_3d: bool = node is CollisionObject3D
	if not is_collision_2d and not is_collision_3d:
		return {"error": "Node '%s' (type: %s) is not a CollisionObject — cannot add collision shape. Use a physics body (RigidBody2D/3D, StaticBody2D/3D, CharacterBody2D/3D, Area2D/3D)." % [path, node.get_class()]}

	# Auto-detect dimension from the node.
	var is_2d: bool = is_collision_2d

	# Check for dimension mismatch: 2D-only shapes on 3D bodies, and vice versa.
	if is_2d and shape_type in _SHAPE_TYPES_3D_ONLY:
		return {"error": "Shape type '%s' (%s) is 3D-only, but node '%s' (type: %s) is 2D. Use a 2D shape type instead: circle, rectangle, capsule, convex, concave, polygon." % [shape_type, _SHAPE_TYPE_LABELS.get(shape_type, shape_type), path, node.get_class()]}
	if not is_2d and shape_type in _SHAPE_TYPES_2D_ONLY:
		return {"error": "Shape type '%s' (%s) is 2D-only, but node '%s' (type: %s) is 3D. Use a 3D shape type instead: box, sphere, capsule, cylinder, convex, concave." % [shape_type, _SHAPE_TYPE_LABELS.get(shape_type, shape_type), path, node.get_class()]}

	var shape: Shape2D = null
	var shape3d: Shape3D = null
	var col_node: Node = null

	# Build the appropriate shape based on type AND dimension.
	match shape_type:
		"circle":
			var cs: CircleShape2D = CircleShape2D.new()
			cs.radius = properties.get("radius", 10.0) as float
			shape = cs
		"rectangle":
			var rs: RectangleShape2D = RectangleShape2D.new()
			var sx: float = properties.get("width", 10.0) as float
			var sy: float = properties.get("height", 10.0) as float
			rs.size = Vector2(sx, sy)
			shape = rs
		"capsule":
			if is_2d:
				var cs2: CapsuleShape2D = CapsuleShape2D.new()
				cs2.radius = properties.get("radius", 10.0) as float
				cs2.height = properties.get("height", 20.0) as float
				shape = cs2
			else:
				var cs3: CapsuleShape3D = CapsuleShape3D.new()
				cs3.radius = properties.get("radius", 0.5) as float
				cs3.height = properties.get("height", 1.0) as float
				shape3d = cs3
		"box":
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
		"sphere":
			var ss: SphereShape3D = SphereShape3D.new()
			ss.radius = properties.get("radius", 0.5) as float
			shape3d = ss
		"cylinder":
			var cyl: CylinderShape3D = CylinderShape3D.new()
			cyl.radius = properties.get("radius", 0.5) as float
			cyl.height = properties.get("height", 2.0) as float
			shape3d = cyl
		"convex":
			if is_2d:
				var cv2: ConvexPolygonShape2D = ConvexPolygonShape2D.new()
				if properties.has("points"):
					var pts2: PackedVector2Array = []
					for v in (properties["points"] as Array):
						if v is Array and (v as Array).size() >= 2:
							pts2.append(Vector2(float((v as Array)[0]), float((v as Array)[1])))
					if not pts2.is_empty():
						cv2.points = pts2
				shape = cv2
			else:
				var cv3: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
				if properties.has("points"):
					cv3.points = _parse_vector3_array(properties["points"])
				shape3d = cv3
		"concave":
			if is_2d:
				var cc2: ConcavePolygonShape2D = ConcavePolygonShape2D.new()
				if properties.has("segments"):
					var segs: PackedVector2Array = []
					for v in (properties["segments"] as Array):
						if v is Array and (v as Array).size() >= 2:
							segs.append(Vector2(float((v as Array)[0]), float((v as Array)[1])))
					if not segs.is_empty():
						cc2.segments = segs
				shape = cc2
			else:
				var cc3: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
				if properties.has("faces"):
					cc3.set_faces(_parse_vector3_array(properties["faces"]))
				if properties.has("backface_collision"):
					cc3.backface_collision = properties["backface_collision"] as bool
				shape3d = cc3
		"polygon":
			var cp: CollisionPolygon2D = CollisionPolygon2D.new()
			col_node = cp
			col_node.name = _generate_unique_collision_name(node, "CollisionPolygon")
			if _undo_helper:
				_undo_helper.add_node_with_undo(col_node, node)
				col_node.set_owner(MCPCommandHelpers.get_scene_root(_plugin))
			else:
				node.add_child(col_node)
				col_node.set_owner(MCPCommandHelpers.get_scene_root(_plugin))
			if properties.has("polygon"):
				var verts: Array = properties.get("polygon", []) as Array
				if not verts.is_empty():
					var poly: PackedVector2Array = []
					for v in verts:
						if v is Array and (v as Array).size() >= 2:
							poly.append(Vector2(float((v as Array)[0]), float((v as Array)[1])))
					if not poly.is_empty():
						(cp as CollisionPolygon2D).polygon = poly
			return {"result": {"shape_type": "polygon", "node": MCPCommandHelpers.get_node_path(col_node, _plugin)}}

	# ALWAYS create a new collision shape node with a unique name.
	# Never reuse existing shapes — each call must produce a distinct CollisionShape
	# so that multiple collision shapes can coexist on the same body.
	var base_name: String = "CollisionShape"
	if is_2d:
		col_node = CollisionShape2D.new()
	else:
		col_node = CollisionShape3D.new()
	col_node.name = _generate_unique_collision_name(node, base_name)
	if _undo_helper:
		_undo_helper.add_node_with_undo(col_node, node)
	else:
		node.add_child(col_node)
		col_node.set_owner(MCPCommandHelpers.get_scene_root(_plugin))

	# Assign the shape resource.
	if col_node is CollisionShape2D and shape:
		(col_node as CollisionShape2D).shape = shape
	elif col_node is CollisionShape3D and shape3d:
		(col_node as CollisionShape3D).shape = shape3d

	return {"result": {"shape_type": shape_type, "node": MCPCommandHelpers.get_node_path(col_node, _plugin)}}


## Generate a unique name for a collision shape child node.
## Checks existing children named "CollisionShape", "CollisionShape2", etc. and picks the next.
func _generate_unique_collision_name(parent: Node, base_name: String) -> String:
	var children: Array[Node] = parent.get_children()
	var max_index: int = 0
	var base_lower: String = base_name.to_lower()
	for child in children:
		var cname: String = str(child.name).to_lower()
		if cname == base_lower:
			max_index = max(max_index, 1)
		elif cname.begins_with(base_lower):
			# Try to extract a numeric suffix like "CollisionShape2" → 2
			var suffix: String = cname.trim_prefix(base_lower)
			if suffix.is_valid_int():
				max_index = max(max_index, suffix.to_int())
	if max_index == 0:
		return base_name
	return base_name + str(max_index + 1)


## Parse a PackedVector3Array from a JSON-array-of-arrays (via MCP bridge).
static func _parse_vector3_array(arr: Variant) -> PackedVector3Array:
	var result: PackedVector3Array = []
	if arr is Array:
		for v in (arr as Array):
			if v is Array and (v as Array).size() >= 3:
				result.append(Vector3(float((v as Array)[0]), float((v as Array)[1]), float((v as Array)[2])))
	return result


## Convert a layer/mask param (int, float, or Array[int]) to a combined bitmask.
## Returns 0 if the param is absent/invalid (caller should preserve existing value).
func _params_to_bitmask(val: Variant) -> int:
	if val is int:
		if val > 0 and val <= 32:
			return 1 << (val - 1)
		return 0
	if val is float:
		var n: int = int(val)
		if n > 0 and n <= 32:
			return 1 << (n - 1)
		return 0
	if val is Array:
		var bitmask: int = 0
		for v in (val as Array):
			if v is int:
				var n: int = v as int
				if n > 0 and n <= 32:
					bitmask |= 1 << (n - 1)
			elif v is float:
				var n: int = int(v)
				if n > 0 and n <= 32:
					bitmask |= 1 << (n - 1)
		return bitmask
	return 0


## Set physics collision layers and mask.
## Layer/mask values can be a single layer NUMBER (1-32) or an ARRAY of numbers.
func set_physics_layers(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var layer_val: Variant = params.get("layer", 0)
	var mask_val: Variant = params.get("mask", 0)
	if path.is_empty():
		return {"error": "Path is required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var new_layer_bitmask: int = _params_to_bitmask(layer_val)
	var new_mask_bitmask: int = _params_to_bitmask(mask_val)

	if node is CollisionObject2D:
		var co: CollisionObject2D = node as CollisionObject2D
		if new_layer_bitmask != 0:
			co.collision_layer = new_layer_bitmask
		if new_mask_bitmask != 0:
			co.collision_mask = new_mask_bitmask
		# Report layer numbers (1-32), not raw bitmask values, for consistency with input
		var current_layers: Array[int] = _bitmask_to_layer_numbers(co.collision_layer)
		var current_masks: Array[int] = _bitmask_to_layer_numbers(co.collision_mask)
		var layer_str: String = ",".join(current_layers) if not current_layers.is_empty() else "none"
		var mask_str: String = ",".join(current_masks) if not current_masks.is_empty() else "none"
		return {"result": "Physics layers set on %s (layers=[%s], masks=[%s])" % [path, layer_str, mask_str]}
	elif node is CollisionObject3D:
		var co3: CollisionObject3D = node as CollisionObject3D
		if new_layer_bitmask != 0:
			co3.collision_layer = new_layer_bitmask
		if new_mask_bitmask != 0:
			co3.collision_mask = new_mask_bitmask
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
			elif child is CollisionPolygon2D:
				var cp: CollisionPolygon2D = child as CollisionPolygon2D
				shapes.append({
					"name": str(cp.name),
					"shape": "CollisionPolygon2D",
					"disabled": cp.disabled,
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
	else:
		return {"error": "Node '%s' (type: %s) is not a CollisionObject — no collision info available. Use a physics body (RigidBody2D/3D, StaticBody2D/3D, CharacterBody2D/3D, Area2D/3D)." % [path, node.get_class()]}
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

	# Set name again after add_child to ensure it sticks (undo system may reset it).
	raycast.name = properties.get("name", "RayCast")

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
## Reuses existing material if present; only creates a new one if none exists.
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
	# No-op: return early if no material properties were provided.
	if properties.is_empty() and not params.has("friction") and not params.has("rough") and not params.has("bounce") and not params.has("absorbent"):
		return {"error": "No material properties provided. Specify at least one of: friction, bounce, rough, absorbent."}
	if path.is_empty():
		return {"error": "Path is required"}
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	# Try to get the node's existing physics_material_override first.
	var existing_mat: PhysicsMaterial = null
	if node is RigidBody2D or node is StaticBody2D:
		existing_mat = node.physics_material_override
	elif node is RigidBody3D or node is StaticBody3D:
		existing_mat = node.physics_material_override
	else:
		# Fallback: check script base class
		var scr: Script = node.get_script()
		if scr:
			var bt: String = scr.get_instance_base_type()
			if bt == "RigidBody2D" or bt == "StaticBody2D" or bt == "RigidBody3D" or bt == "StaticBody3D":
				existing_mat = node.physics_material_override
			else:
				return {"error": "Node type '%s' does not support physics_material_override. Supported types: RigidBody2D, RigidBody3D, StaticBody2D, StaticBody3D." % node.get_class()}
		else:
			return {"error": "Node type '%s' does not support physics_material_override. Supported types: RigidBody2D, RigidBody3D, StaticBody2D, StaticBody3D." % node.get_class()}

	# Reuse existing material or create a new one.
	var mat: PhysicsMaterial = existing_mat if existing_mat else PhysicsMaterial.new()

	# Update only the properties that were explicitly provided.
	if properties.has("friction"):
		mat.friction = properties["friction"] as float
	if properties.has("rough"):
		mat.rough = properties["rough"] as bool
	if properties.has("bounce"):
		mat.bounce = properties["bounce"] as float
	if properties.has("absorbent"):
		mat.absorbent = properties["absorbent"] as bool

	# Only set the override if it changed (new material or first assignment).
	if existing_mat == null or existing_mat != mat:
		if _undo_helper:
			_undo_helper.set_property_with_undo(node, "physics_material_override", mat)
		else:
			node.physics_material_override = mat

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
	var is_char_body: bool = node is CharacterBody2D or node is CharacterBody3D
	var read_props: PackedStringArray = ["mass", "gravity_scale", "linear_damp", "angular_damp"]
	for prop: String in read_props:
		if MCPCommandHelpers.has_property(node, prop):
			result[prop] = node.get(prop)
		else:
			result[prop] = null
	if is_char_body:
		result["_note"] = "%s does not have mass, gravity_scale, linear_damp, angular_damp. These are only available on RigidBody2D/3D." % node.get_class()
	var is_static: bool = node is StaticBody2D or node is StaticBody3D
	if is_static:
		result["_note"] = "%s does not have mass, gravity_scale, linear_damp, angular_damp. These are only available on RigidBody2D/3D." % node.get_class()
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


