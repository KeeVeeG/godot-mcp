## Smart variant codec for parsing and serializing Godot types.
## Handles Vector2, Vector3, Color, Rect2, Transform2D, Transform3D,
## Basis, Quaternion, Plane, AABB and more from string representations.
@tool
class_name MCPVariantCodec
extends RefCounted


## Parse a value with an optional type hint.
## Supports auto-detection from string formats.
static func parse_value(value: Variant, type_hint: String = "") -> Variant:
	if MCPCommandHelpers.is_null(value):
		return null

	# If a type hint is provided, try to parse according to it
	if type_hint != "":
		return _parse_with_hint(value, type_hint)

	# Auto-detect from string patterns
	if value is String:
		return _auto_parse_string(value as String)

	return value


## Parse with a specific type hint.
static func _parse_with_hint(value: Variant, type_hint: String) -> Variant:
	match type_hint:
		"Vector2":
			return _parse_vector2(value)
		"Vector2i":
			return _parse_vector2i(value)
		"Vector3":
			return _parse_vector3(value)
		"Vector3i":
			return _parse_vector3i(value)
		"Vector4":
			return _parse_vector4(value)
		"Vector4i":
			return _parse_vector4i(value)
		"Color":
			return _parse_color(value)
		"Rect2":
			return _parse_rect2(value)
		"Rect2i":
			return _parse_rect2i(value)
		"Transform2D":
			return _parse_transform2d(value)
		"Transform3D":
			return _parse_transform3d(value)
		"Basis":
			return _parse_basis(value)
		"Quaternion":
			return _parse_quaternion(value)
		"Plane":
			return _parse_plane(value)
		"AABB":
			return _parse_aabb(value)
		"int":
			return int(value)
		"float":
			return float(value)
		"bool":
			return bool(value)
		"String":
			return str(value)
		"StringName":
			return StringName(str(value))
		"NodePath":
			return NodePath(str(value))
		_:
			return value


## Auto-detect type from string content.
static func _auto_parse_string(s: String) -> Variant:
	# Check for color hex format
	if s.begins_with("#"):
		return _parse_color(s)

	# Check for constructor-style formats
	if s.begins_with("Vector2("):
		return _parse_vector2(s)
	if s.begins_with("Vector2i("):
		return _parse_vector2i(s)
	if s.begins_with("Vector3("):
		return _parse_vector3(s)
	if s.begins_with("Vector3i("):
		return _parse_vector3i(s)
	if s.begins_with("Vector4("):
		return _parse_vector4(s)
	if s.begins_with("Vector4i("):
		return _parse_vector4i(s)
	if s.begins_with("Color("):
		return _parse_color(s)
	if s.begins_with("Rect2(") or s.begins_with("Rect2i("):
		return _parse_rect2(s)
	if s.begins_with("Transform2D("):
		return _parse_transform2d(s)
	if s.begins_with("Transform3D("):
		return _parse_transform3d(s)
	if s.begins_with("Basis("):
		return _parse_basis(s)
	if s.begins_with("Quaternion("):
		return _parse_quaternion(s)
	if s.begins_with("Plane("):
		return _parse_plane(s)
	if s.begins_with("AABB(") or s.begins_with("Aabb("):
		return _parse_aabb(s)

	# Try as number
	if s.is_valid_int():
		return s.to_int()
	if s.is_valid_float():
		return s.to_float()

	# Boolean strings
	if s.to_lower() == "true":
		return true
	if s.to_lower() == "false":
		return false

	# Return as string
	return s


## Extract numeric values from a constructor string like "Vector2(1, 2)".
static func _extract_numbers(s: String) -> Array[float]:
	var numbers: Array[float] = []
	var start_paren: int = s.find("(")
	var end_paren: int = s.rfind(")")
	if start_paren == -1 or end_paren == -1:
		return numbers
	var inner: String = s.substr(start_paren + 1, end_paren - start_paren - 1)
	var parts: PackedStringArray = inner.split(",")
	for part: String in parts:
		var trimmed: String = part.strip_edges()
		if trimmed.is_valid_float():
			numbers.append(trimmed.to_float())
	return numbers


## Try to parse a string as a JSON object or array.
## Returns the parsed value if successful and the result is a Dictionary or Array,
## otherwise returns null (indicating the string is NOT a JSON container).
static func _try_parse_json_string(s: String) -> Variant:
	var trimmed: String = s.strip_edges()
	if not (trimmed.begins_with("{") or trimmed.begins_with("[")):
		return null
	var json := JSON.new()
	if json.parse(trimmed) != OK:
		return null
	var data: Variant = json.get_data()
	if data is Dictionary or data is Array:
		return data
	return null


static func _parse_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value as Vector2
	if value is String:
		var s: String = value as String
		# Try parsing as JSON first (handles double-serialized dicts {"x":2,"y":2})
		var as_json: Variant = _try_parse_json_string(s)
		if as_json != null:
			if as_json is Dictionary:
				var d: Dictionary = as_json as Dictionary
				return Vector2(d.get("x", 0.0) as float, d.get("y", 0.0) as float)
			if as_json is Array:
				var a: Array = as_json as Array
				if a.size() >= 2:
					return Vector2(a[0] as float, a[1] as float)
		# Fallback: parse constructor strings like "Vector2(1, 2)"
		var nums: Array[float] = _extract_numbers(s)
		if nums.size() >= 2:
			return Vector2(nums[0], nums[1])
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		var x: float = d.get("x", 0.0) as float
		var y: float = d.get("y", 0.0) as float
		return Vector2(x, y)
	var a: Array = _to_plain_array(value)
	if a.size() >= 2:
		return Vector2(a[0] as float, a[1] as float)
	return Vector2.ZERO


static func _parse_vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value as Vector2i
	if value is String:
		var s: String = value as String
		var as_json: Variant = _try_parse_json_string(s)
		if as_json != null:
			if as_json is Dictionary:
				var d: Dictionary = as_json as Dictionary
				return Vector2i(d.get("x", 0) as int, d.get("y", 0) as int)
			if as_json is Array:
				var a: Array = as_json as Array
				if a.size() >= 2:
					return Vector2i(a[0] as int, a[1] as int)
		var nums: Array[float] = _extract_numbers(s)
		if nums.size() >= 2:
			return Vector2i(int(nums[0]), int(nums[1]))
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		return Vector2i(d.get("x", 0) as int, d.get("y", 0) as int)
	if value is Array:
		var a: Array = value as Array
		if a.size() >= 2:
			return Vector2i(a[0] as int, a[1] as int)
	return Vector2i.ZERO


# Helper: convert packed array types (returned by JSON.parse_string()) to plain Array.
# Godot's JSON parser returns PackedInt32Array/PackedFloat32Array for numeric JSON arrays.
static func _to_plain_array(value: Variant) -> Array:
	if value is Array:
		return value
	if value is PackedInt32Array or value is PackedInt64Array or value is PackedFloat32Array or value is PackedFloat64Array:
		return Array(value)
	return []

static func _parse_vector3(value: Variant) -> Vector3:
	if value is Vector3:
		return value as Vector3
	if value is String:
		var s: String = value as String
		var as_json: Variant = _try_parse_json_string(s)
		if as_json != null:
			if as_json is Dictionary:
				var d: Dictionary = as_json as Dictionary
				return Vector3(d.get("x", 0.0) as float, d.get("y", 0.0) as float, d.get("z", 0.0) as float)
			if as_json is Array:
				var a: Array = as_json as Array
				if a.size() >= 3:
					return Vector3(a[0] as float, a[1] as float, a[2] as float)
		var nums: Array[float] = _extract_numbers(s)
		var count: int = nums.size()
		if count >= 2:
			return Vector3(nums[0], nums[1], nums[2] if count >= 3 else 0.0)
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		return Vector3(d.get("x", 0.0) as float, d.get("y", 0.0) as float, d.get("z", 0.0) as float)
	var a: Array = _to_plain_array(value)
	if a.size() >= 2:
		return Vector3(a[0] as float, a[1] as float, a[2] as float if a.size() >= 3 else 0.0)
	return Vector3.ZERO


static func _parse_vector3i(value: Variant) -> Vector3i:
	if value is Vector3i:
		return value as Vector3i
	if value is String:
		var s: String = value as String
		var as_json: Variant = _try_parse_json_string(s)
		if as_json != null:
			if as_json is Dictionary:
				var d: Dictionary = as_json as Dictionary
				return Vector3i(d.get("x", 0) as int, d.get("y", 0) as int, d.get("z", 0) as int)
			if as_json is Array:
				var a: Array = as_json as Array
				if a.size() >= 3:
					return Vector3i(a[0] as int, a[1] as int, a[2] as int)
		var nums: Array[float] = _extract_numbers(s)
		var count: int = nums.size()
		if count >= 2:
			return Vector3i(int(nums[0]), int(nums[1]), int(nums[2]) if count >= 3 else 0)
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		return Vector3i(d.get("x", 0) as int, d.get("y", 0) as int, d.get("z", 0) as int)
	var a: Array = _to_plain_array(value)
	if a.size() >= 2:
		return Vector3i(a[0] as int, a[1] as int, a[2] as int if a.size() >= 3 else 0)
	return Vector3i.ZERO


static func _parse_vector4(value: Variant) -> Vector4:
	if value is Vector4:
		return value as Vector4
	if value is String:
		var nums: Array[float] = _extract_numbers(value as String)
		if nums.size() >= 4:
			return Vector4(nums[0], nums[1], nums[2], nums[3])
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		return Vector4(d.get("x", 0.0) as float, d.get("y", 0.0) as float, d.get("z", 0.0) as float, d.get("w", 0.0) as float)
	if value is Array:
		var a: Array = value as Array
		if a.size() >= 4:
			return Vector4(a[0] as float, a[1] as float, a[2] as float, a[3] as float)
	return Vector4.ZERO


static func _parse_vector4i(value: Variant) -> Vector4i:
	if value is Vector4i:
		return value as Vector4i
	if value is String:
		var nums: Array[float] = _extract_numbers(value as String)
		if nums.size() >= 4:
			return Vector4i(int(nums[0]), int(nums[1]), int(nums[2]), int(nums[3]))
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		return Vector4i(d.get("x", 0) as int, d.get("y", 0) as int, d.get("z", 0) as int, d.get("w", 0) as int)
	if value is Array:
		var a: Array = value as Array
		if a.size() >= 4:
			return Vector4i(a[0] as int, a[1] as int, a[2] as int, a[3] as int)
	return Vector4i.ZERO


static func _parse_color(value: Variant) -> Color:
	if value is Color:
		return value as Color
	if value is String:
		var s: String = value as String
		# Try parsing as JSON first (handles double-serialized dicts {"r":1,"g":0,"b":0,"a":1})
		var as_json: Variant = _try_parse_json_string(s)
		if as_json != null:
			if as_json is Dictionary:
				var d: Dictionary = as_json as Dictionary
				return Color(d.get("r", 1.0) as float, d.get("g", 1.0) as float, d.get("b", 1.0) as float, d.get("a", 1.0) as float)
			if as_json is Array:
				var a: Array = as_json as Array
				if a.size() >= 4:
					return Color(a[0] as float, a[1] as float, a[2] as float, a[3] as float)
				elif a.size() >= 3:
					return Color(a[0] as float, a[1] as float, a[2] as float)
		# Hex format: #rrggbb or #rrggbbaa
		if s.begins_with("#"):
			if Color.html_is_valid(s):
				return Color.html(s)
			return Color(-1, -1, -1, -1)  # sentinel: invalid hex
		# Constructor format: Color(r, g, b) or Color(r, g, b, a)
		if s.begins_with("Color("):
			var nums: Array[float] = _extract_numbers(s)
			if nums.size() >= 4:
				return Color(nums[0], nums[1], nums[2], nums[3])
			elif nums.size() >= 3:
				return Color(nums[0], nums[1], nums[2])
		# Parenthesized format: (r, g, b, a) or (r, g, b)
		if s.begins_with("(") and s.ends_with(")"):
			var nums: Array[float] = _extract_numbers(s)
			if nums.size() >= 4:
				return Color(nums[0], nums[1], nums[2], nums[3])
			elif nums.size() >= 3:
				return Color(nums[0], nums[1], nums[2])
		# Named color — validate before parsing.
		# ENGINE BUG (Godot 4.7): Color.html() silently returns Color.BLACK
		# for any invalid string instead of reporting an error.
		if is_valid_color_string(s):
			return Color.from_string(s, Color.WHITE)
		return Color(-1, -1, -1, -1)  # sentinel: validation failure
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		return Color(d.get("r", 1.0) as float, d.get("g", 1.0) as float, d.get("b", 1.0) as float, d.get("a", 1.0) as float)
	if value is Array:
		var a: Array = value as Array
		if a.size() >= 4:
			return Color(a[0] as float, a[1] as float, a[2] as float, a[3] as float)
		elif a.size() >= 3:
			return Color(a[0] as float, a[1] as float, a[2] as float)
	return Color.WHITE


## Validate whether a string represents a valid Godot Color (hex or named).
## Uses Color.html_is_valid() for hex and Color.from_string() with sentinel for named colors.
static func is_valid_color_string(s: String) -> bool:
	var stripped: String = s.strip_edges()
	if stripped.is_empty():
		return false
	if Color.html_is_valid(stripped):
		return true
	# Named color: Color.from_string() returns the sentinel when neither hex nor named match
	const SENTINEL := Color(-1, -1, -1, -1)
	return Color.from_string(stripped, SENTINEL) != SENTINEL


static func _parse_rect2(value: Variant) -> Rect2:
	if value is Rect2:
		return value as Rect2
	if value is String:
		var nums: Array[float] = _extract_numbers(value as String)
		if nums.size() >= 4:
			return Rect2(nums[0], nums[1], nums[2], nums[3])
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		var pos: Vector2 = _parse_vector2(d.get("position", {"x": 0, "y": 0}))
		var size: Vector2 = _parse_vector2(d.get("size", {"x": 0, "y": 0}))
		return Rect2(pos, size)
	if value is Array:
		var a: Array = value as Array
		if a.size() >= 4:
			return Rect2(a[0] as float, a[1] as float, a[2] as float, a[3] as float)
	return Rect2()


static func _parse_rect2i(value: Variant) -> Rect2i:
	if value is Rect2i:
		return value as Rect2i
	if value is String:
		var nums: Array[float] = _extract_numbers(value as String)
		if nums.size() >= 4:
			return Rect2i(int(nums[0]), int(nums[1]), int(nums[2]), int(nums[3]))
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		var pos: Vector2i = _parse_vector2i(d.get("position", {"x": 0, "y": 0}))
		var sz: Vector2i = _parse_vector2i(d.get("size", {"x": 0, "y": 0}))
		return Rect2i(pos, sz)
	return Rect2i()


static func _parse_transform2d(value: Variant) -> Transform2D:
	if value is Transform2D:
		return value as Transform2D
	if value is String:
		var nums: Array[float] = _extract_numbers(value as String)
		if nums.size() >= 6:
			return Transform2D(Vector2(nums[0], nums[1]), Vector2(nums[2], nums[3]), Vector2(nums[4], nums[5]))
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		var x_axis: Vector2 = _parse_vector2(d.get("x", {"x": 1, "y": 0}))
		var y_axis: Vector2 = _parse_vector2(d.get("y", {"x": 0, "y": 1}))
		var origin: Vector2 = _parse_vector2(d.get("origin", {"x": 0, "y": 0}))
		return Transform2D(x_axis, y_axis, origin)
	return Transform2D.IDENTITY


static func _parse_transform3d(value: Variant) -> Transform3D:
	if value is Transform3D:
		return value as Transform3D
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		var basis: Basis = _parse_basis(d.get("basis", {}))
		var origin: Vector3 = _parse_vector3(d.get("origin", {}))
		return Transform3D(basis, origin)
	return Transform3D.IDENTITY


static func _parse_basis(value: Variant) -> Basis:
	if value is Basis:
		return value as Basis
	if value is String:
		var nums: Array[float] = _extract_numbers(value as String)
		if nums.size() >= 9:
			return Basis(
				Vector3(nums[0], nums[1], nums[2]),
				Vector3(nums[3], nums[4], nums[5]),
				Vector3(nums[6], nums[7], nums[8])
			)
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		var x: Vector3 = _parse_vector3(d.get("x", {"x": 1, "y": 0, "z": 0}))
		var y: Vector3 = _parse_vector3(d.get("y", {"x": 0, "y": 1, "z": 0}))
		var z: Vector3 = _parse_vector3(d.get("z", {"x": 0, "y": 0, "z": 1}))
		return Basis(x, y, z)
	return Basis.IDENTITY


static func _parse_quaternion(value: Variant) -> Quaternion:
	if value is Quaternion:
		return value as Quaternion
	if value is String:
		var nums: Array[float] = _extract_numbers(value as String)
		if nums.size() >= 4:
			return Quaternion(nums[0], nums[1], nums[2], nums[3])
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		return Quaternion(d.get("x", 0.0) as float, d.get("y", 0.0) as float, d.get("z", 0.0) as float, d.get("w", 1.0) as float)
	if value is Array:
		var a: Array = value as Array
		if a.size() >= 4:
			return Quaternion(a[0] as float, a[1] as float, a[2] as float, a[3] as float)
	return Quaternion.IDENTITY


static func _parse_plane(value: Variant) -> Plane:
	if value is Plane:
		return value as Plane
	if value is String:
		var nums: Array[float] = _extract_numbers(value as String)
		if nums.size() >= 4:
			# Plane(normal_x, normal_y, normal_z, d)
			return Plane(nums[0], nums[1], nums[2], nums[3])
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		var normal: Vector3 = _parse_vector3(d.get("normal", {"x": 0, "y": 1, "z": 0}))
		return Plane(normal, d.get("d", 0.0) as float)
	if value is Array:
		var a: Array = value as Array
		if a.size() >= 4:
			return Plane(a[0] as float, a[1] as float, a[2] as float, a[3] as float)
	return Plane()


static func _parse_aabb(value: Variant) -> AABB:
	if value is AABB:
		return value as AABB
	if value is String:
		var nums: Array[float] = _extract_numbers(value as String)
		if nums.size() >= 6:
			# AABB(pos_x, pos_y, pos_z, size_x, size_y, size_z)
			return AABB(Vector3(nums[0], nums[1], nums[2]), Vector3(nums[3], nums[4], nums[5]))
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		var pos: Vector3 = _parse_vector3(d.get("position", {}))
		var sz: Vector3 = _parse_vector3(d.get("size", {}))
		return AABB(pos, sz)
	if value is Array:
		var a: Array = value as Array
		if a.size() >= 6:
			return AABB(Vector3(a[0] as float, a[1] as float, a[2] as float), Vector3(a[3] as float, a[4] as float, a[5] as float))
	return AABB()


## Serialize a Variant to a JSON-friendly representation.
static func serialize_value(value: Variant) -> Variant:
	if MCPCommandHelpers.is_null(value):
		return null

	if value is Vector2:
		var v: Vector2 = value as Vector2
		return {"x": v.x, "y": v.y}
	elif value is Vector2i:
		var v: Vector2i = value as Vector2i
		return {"x": v.x, "y": v.y}
	elif value is Vector3:
		var v: Vector3 = value as Vector3
		return {"x": v.x, "y": v.y, "z": v.z}
	elif value is Vector3i:
		var v: Vector3i = value as Vector3i
		return {"x": v.x, "y": v.y, "z": v.z}
	elif value is Vector4:
		var v: Vector4 = value as Vector4
		return {"x": v.x, "y": v.y, "z": v.z, "w": v.w}
	elif value is Vector4i:
		var v: Vector4i = value as Vector4i
		return {"x": v.x, "y": v.y, "z": v.z, "w": v.w}
	elif value is Color:
		var c: Color = value as Color
		return {"r": c.r, "g": c.g, "b": c.b, "a": c.a, "hex": c.to_html()}
	elif value is Rect2:
		var r: Rect2 = value as Rect2
		return {"position": serialize_value(r.position), "size": serialize_value(r.size)}
	elif value is Rect2i:
		var r: Rect2i = value as Rect2i
		return {"position": serialize_value(r.position), "size": serialize_value(r.size)}
	elif value is Transform2D:
		var t: Transform2D = value as Transform2D
		return {
			"x": serialize_value(t.x),
			"y": serialize_value(t.y),
			"origin": serialize_value(t.origin),
		}
	elif value is Transform3D:
		var t: Transform3D = value as Transform3D
		return {
			"basis": serialize_value(t.basis),
			"origin": serialize_value(t.origin),
		}
	elif value is Basis:
		var b: Basis = value as Basis
		return {
			"x": serialize_value(b.x),
			"y": serialize_value(b.y),
			"z": serialize_value(b.z),
		}
	elif value is Quaternion:
		var q: Quaternion = value as Quaternion
		return {"x": q.x, "y": q.y, "z": q.z, "w": q.w}
	elif value is Plane:
		var p: Plane = value as Plane
		return {"normal": serialize_value(p.normal), "d": p.d}
	elif value is AABB:
		var bb: AABB = value as AABB
		return {"position": serialize_value(bb.position), "size": serialize_value(bb.size)}
	elif value is NodePath:
		return str(value)
	elif value is StringName:
		return str(value)
	elif value is RID:
		return str(value)
	elif value is Object:
		if value is Node:
			var node: Node = value as Node
			return {"type": "Node", "name": node.name, "path": str(node.get_path())}
		# Defect 12: Serialize InputEvent with full event data, not just Resource reference
		elif value is InputEvent:
			return serialize_input_event(value as InputEvent)
		elif value is Resource:
			var res: Resource = value as Resource
			var result: Dictionary = {"type": "Resource", "class": res.get_class()}
			if res.resource_path != "":
				result["path"] = res.resource_path
			# Include shape/material sub-properties for visibility
			if res is Shape3D or res is Shape2D or res is Material:
				var sub: Dictionary = {}
				for p in res.get_property_list():
					var pname: String = p["name"] as String
					var usage: int = p["usage"] as int
					if usage & PROPERTY_USAGE_STORAGE == 0:
						continue
					if pname.begins_with("_"):
						continue
					sub[pname] = serialize_value(res.get(pname))
				result["properties"] = sub
			return result
		return {"type": value.get_class()}
	elif value is Callable:
		return str(value)
	elif value is Signal:
		return str(value)
	elif value is Array:
		var a: Array = value as Array
		var result_arr: Array = []
		for item: Variant in a:
			result_arr.append(serialize_value(item))
		return result_arr
	elif value is Dictionary:
		var d: Dictionary = value as Dictionary
		var result_dict: Dictionary = {}
		for key: Variant in d:
			result_dict[serialize_value(key)] = serialize_value(d[key])
		return result_dict
	elif value is PackedByteArray:
		var packed: PackedByteArray = value as PackedByteArray
		return packed.hex_encode()
	elif value is PackedInt32Array:
		return Array(value as PackedInt32Array)
	elif value is PackedInt64Array:
		return Array(value as PackedInt64Array)
	elif value is PackedFloat32Array:
		return Array(value as PackedFloat32Array)
	elif value is PackedFloat64Array:
		return Array(value as PackedFloat64Array)
	elif value is PackedStringArray:
		return Array(value as PackedStringArray)
	elif value is PackedVector2Array:
		var arr: PackedVector2Array = value as PackedVector2Array
		var out: Array = []
		for v: Vector2 in arr:
			out.append({"x": v.x, "y": v.y})
		return out
	elif value is PackedVector3Array:
		var arr: PackedVector3Array = value as PackedVector3Array
		var out: Array = []
		for v: Vector3 in arr:
			out.append({"x": v.x, "y": v.y, "z": v.z})
		return out
	elif value is PackedColorArray:
		var arr: PackedColorArray = value as PackedColorArray
		var out: Array = []
		for c: Color in arr:
			out.append({"r": c.r, "g": c.g, "b": c.b, "a": c.a})
		return out
	else:
		return value


## Check if a value is numeric (int, float, or valid numeric string).
static func _is_numeric_value(v: Variant) -> bool:
	if v is float or v is int:
		return true
	if v is String:
		return (v as String).is_valid_float()
	return false


## Check if a value looks structurally valid for parsing as a vector type.
## Rejects dicts/arrays with non-numeric sub-values and unknown types.
static func _could_be_vector(value: Variant, component_names: Array[String], component_count: int) -> bool:
	if value is String:
		return true
	if value is Dictionary:
		var d: Dictionary = value as Dictionary
		for i: int in range(component_count):
			if not d.has(component_names[i]):
				return false
			if not _is_numeric_value(d[component_names[i]]):
				return false
		return true
	if value is Array:
		var a: Array = value as Array
		if a.size() < component_count:
			return false
		for i: int in range(component_count):
			if not _is_numeric_value(a[i]):
				return false
		return true
	return false


## Try to parse a value to match a property's expected type.
static func parse_for_property(value: Variant, expected_type: int) -> Variant:
	match expected_type:
		TYPE_NIL:
			return value
		TYPE_BOOL:
			if value is bool:
				return value
			if value is int:
				return value != 0
			if value is float:
				return value != 0.0
			if value is String:
				var bs: String = (value as String).to_lower()
				if bs == "true" or bs == "1":
					return true
				if bs == "false" or bs == "0":
					return false
				return null
			return null
		TYPE_INT:
			if value is int:
				return value
			if value is float:
				return int(value)
			if value is String:
				var s: String = value as String
				if s.is_valid_int():
					return s.to_int()
				return null
			return null
		TYPE_FLOAT:
			if value is float or value is int:
				return float(value)
			if value is String:
				var s: String = value as String
				if s.is_valid_float():
					return s.to_float()
				return null
			return null
		TYPE_STRING:
			return str(value)
		TYPE_VECTOR2:
			if value is Vector2:
				return value
			if value is Vector2i:
				return Vector2(value)
			if not (value is String or value is Dictionary or value is Array):
				return null
			if not _could_be_vector(value, ["x", "y"], 2):
				return null
			return _parse_vector2(value)
		TYPE_VECTOR2I:
			if value is Vector2i:
				return value
			if value is Vector2:
				return Vector2i(value as Vector2)
			if not (value is String or value is Dictionary or value is Array):
				return null
			if not _could_be_vector(value, ["x", "y"], 2):
				return null
			return _parse_vector2i(value)
		TYPE_RECT2:
			return _parse_rect2(value)
		TYPE_RECT2I:
			return _parse_rect2i(value)
		TYPE_VECTOR3:
			if value is Vector3:
				return value
			if value is Vector3i:
				return Vector3(value)
			if not (value is String or value is Dictionary or value is Array):
				return null
			if not _could_be_vector(value, ["x", "y", "z"], 3):
				return null
			return _parse_vector3(value)
		TYPE_VECTOR3I:
			if value is Vector3i:
				return value
			if value is Vector3:
				return Vector3i(value as Vector3)
			if not (value is String or value is Dictionary or value is Array):
				return null
			if not _could_be_vector(value, ["x", "y", "z"], 3):
				return null
			return _parse_vector3i(value)
		TYPE_TRANSFORM2D:
			return _parse_transform2d(value)
		TYPE_VECTOR4:
			if value is Vector4:
				return value
			if value is Vector4i:
				return Vector4(value)
			if not (value is String or value is Dictionary or value is Array):
				return null
			if not _could_be_vector(value, ["x", "y", "z", "w"], 4):
				return null
			return _parse_vector4(value)
		TYPE_VECTOR4I:
			if value is Vector4i:
				return value
			if value is Vector4:
				return Vector4i(value as Vector4)
			if not (value is String or value is Dictionary or value is Array):
				return null
			if not _could_be_vector(value, ["x", "y", "z", "w"], 4):
				return null
			return _parse_vector4i(value)
		TYPE_BASIS:
			return _parse_basis(value)
		TYPE_TRANSFORM3D:
			return _parse_transform3d(value)
		TYPE_QUATERNION:
			return _parse_quaternion(value)
		TYPE_PLANE:
			return _parse_plane(value)
		TYPE_AABB:
			return _parse_aabb(value)
		TYPE_COLOR:
			if value is Color:
				return value
			if not (value is String or value is Dictionary or value is Array):
				return null
			var col := _parse_color(value)
			if col == Color(-1, -1, -1, -1):
				return null  # Validation failed — invalid color string
			return col
		TYPE_NODE_PATH:
			return NodePath(str(value))
		TYPE_STRING_NAME:
			return StringName(str(value))
		TYPE_OBJECT:
			# Create resource from {type: "ResourceType", ...props} dict
			if value is Dictionary and value.has("type"):
				var res_type: String = value["type"]
				if ClassDB.class_exists(res_type):
					var res: Resource = ClassDB.instantiate(res_type) as Resource
					if res:
						for p in value:
							if p != "type" and p in res:
								res.set(p, parse_for_property(value[p], typeof(res.get(p))))
						return res
			# Load existing resource from {path: "res://file.tres"}
			if value is Dictionary and value.has("path"):
				var p: String = value["path"]
				if ResourceLoader.exists(p):
					return ResourceLoader.load(p)
			# Load resource from plain path string like "res://file.tres" or UID like "uid://..."
			if value is String:
				var s: String = value as String
				if ResourceLoader.exists(s):
					return ResourceLoader.load(s)
			return value
		_:
			return value


## Serialize an InputEvent to a dictionary for JSON transport.
static func serialize_input_event(event: InputEvent) -> Dictionary:
	var type_name: String = event.get_class()
	if event is InputEventKey:
		type_name = "key"
	elif event is InputEventMouseButton:
		type_name = "mouse_button"
	elif event is InputEventJoypadButton:
		type_name = "joypad_button"
	elif event is InputEventJoypadMotion:
		type_name = "joypad_motion"
	elif event is InputEventAction:
		type_name = "action"
	var d: Dictionary = {"type": type_name}
	if event is InputEventKey:
		d["keycode"] = event.keycode
		d["key_label"] = event.key_label
		d["physical_keycode"] = event.physical_keycode
		d["pressed"] = event.pressed
		if event.echo: d["echo"] = true
		if event.ctrl_pressed: d["ctrl"] = true
		if event.shift_pressed: d["shift"] = true
		if event.alt_pressed: d["alt"] = true
		if event.meta_pressed: d["meta"] = true
	elif event is InputEventMouseButton:
		d["button"] = event.button_index
		d["pressed"] = event.pressed
		if event.double_click: d["double_click"] = true
	elif event is InputEventJoypadButton:
		d["button"] = event.button_index
		d["pressed"] = event.pressed
		d["pressure"] = event.pressure
	elif event is InputEventJoypadMotion:
		d["axis"] = event.axis
		d["axis_value"] = event.axis_value
	return d


## Parse a mouse button index from a string name ("MOUSE_BUTTON_LEFT", "left", 1), integer, or float.
## Returns the integer button index, or 0 if unrecognized.
## Godot's MouseButton enum is 1-based: LEFT=1, RIGHT=2, MIDDLE=3, WHEEL_UP=4, WHEEL_DOWN=5,
## WHEEL_LEFT=6, WHEEL_RIGHT=7, XBUTTON1=8, XBUTTON2=9.
static func parse_mouse_button(button_val) -> int:
	if button_val is int or button_val is float:
		return int(button_val)
	if button_val is String:
		var s: String = button_val as String
		if s.is_valid_int():
			return s.to_int()
		var upper: String = s.to_upper()
		if upper.begins_with("MOUSE_BUTTON_"):
			upper = upper.trim_prefix("MOUSE_BUTTON_")
		match upper:
			"LEFT": return 1
			"RIGHT": return 2
			"MIDDLE": return 3
			"WHEEL_UP": return 4
			"WHEEL_DOWN": return 5
			"WHEEL_LEFT": return 6
			"WHEEL_RIGHT": return 7
			"XBUTTON1": return 8
			"XBUTTON2": return 9
			_:
				push_warning("MCP: unrecognized mouse button name: '%s'. Valid: MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_WHEEL_UP/DOWN/LEFT/RIGHT, MOUSE_BUTTON_XBUTTON1/2" % s)
				return 0
	return 0


## Parse a keycode from a string name ("KEY_SPACE", "Space", "32"), integer, or float.
## Returns the integer keycode, or 0 if unrecognized.
static func parse_keycode(keycode_val) -> int:
	if keycode_val is int or keycode_val is float:
		return int(keycode_val)
	if keycode_val is String:
		var s: String = keycode_val as String
		if s.is_valid_int():
			return s.to_int()
		var upper: String = s.to_upper()
		if upper.begins_with("KEY_"):
			upper = upper.trim_prefix("KEY_")
		var code: int = OS.find_keycode_from_string(upper)
		if code == 0 and "_" in upper:
			# Retry with spaces instead of underscores (for "KP_ENTER" → "Kp Enter")
			code = OS.find_keycode_from_string(upper.replace("_", " "))
		if code != 0:
			return code
		# Fallback common aliases not covered by find_keycode_from_string
		match upper:
			"ENTER", "RETURN": return KEY_ENTER
			"ESCAPE", "ESC": return KEY_ESCAPE
			"DELETE", "DEL": return KEY_DELETE
			"CTRL", "CONTROL": return KEY_CTRL
			# Numpad keys (OS.find_keycode_from_string may not resolve on non-English locales)
			"KP_ENTER": return KEY_KP_ENTER
			"KP_ADD": return KEY_KP_ADD
			"KP_SUBTRACT": return KEY_KP_SUBTRACT
			"KP_MULTIPLY": return KEY_KP_MULTIPLY
			"KP_DIVIDE": return KEY_KP_DIVIDE
			"KP_PERIOD": return KEY_KP_PERIOD
			"KP_0": return KEY_KP_0
			"KP_1": return KEY_KP_1
			"KP_2": return KEY_KP_2
			"KP_3": return KEY_KP_3
			"KP_4": return KEY_KP_4
			"KP_5": return KEY_KP_5
			"KP_6": return KEY_KP_6
			"KP_7": return KEY_KP_7
			"KP_8": return KEY_KP_8
			"KP_9": return KEY_KP_9
			_:
				if upper.length() == 1:
					return upper.unicode_at(0)
	return 0


## Create an InputEvent from a dictionary with type and event data.
static func create_input_event(event_data: Dictionary) -> InputEvent:
	var type: String = event_data.get("type", "")
	match type:
		"key":
			var ev := InputEventKey.new()
			ev.keycode = parse_keycode(event_data.get("keycode", 0)) as Key
			ev.physical_keycode = parse_keycode(event_data.get("physical_keycode", ev.keycode)) as Key
			ev.key_label = parse_keycode(event_data.get("key_label", 0)) as Key
			ev.echo = event_data.get("echo", false) as bool
			ev.pressed = event_data.get("pressed", false) as bool
			# Restore modifier flags from serialized data.
			# Accept both "ctrl" (serialized form) and "ctrl_pressed" (user-facing alias).
			ev.ctrl_pressed = event_data.get("ctrl_pressed", event_data.get("ctrl", false)) as bool
			ev.shift_pressed = event_data.get("shift_pressed", event_data.get("shift", false)) as bool
			ev.alt_pressed = event_data.get("alt_pressed", event_data.get("alt", false)) as bool
			ev.meta_pressed = event_data.get("meta_pressed", event_data.get("meta", false)) as bool
			return ev
		"mouse_button":
			var ev := InputEventMouseButton.new()
			# Accept both "button_index" (user-facing) and "button" (serialized form).
			# Use parse_mouse_button() to resolve string names like "MOUSE_BUTTON_LEFT" to integers.
			var raw_button: Variant = event_data.get("button_index", event_data.get("button", 1))
			ev.button_index = parse_mouse_button(raw_button) as MouseButton
			ev.pressed = event_data.get("pressed", false) as bool
			ev.double_click = event_data.get("double_click", false) as bool
			return ev
		"joypad_button":
			var ev := InputEventJoypadButton.new()
			# Accept both "button_index" (user-facing) and "button" (serialized form).
			ev.button_index = event_data.get("button_index", event_data.get("button", 0)) as JoyButton
			ev.pressed = event_data.get("pressed", false) as bool
			ev.pressure = event_data.get("pressure", 1.0) as float
			return ev
		"joypad_motion":
			var ev := InputEventJoypadMotion.new()
			ev.axis = event_data.get("axis", 0) as int
			ev.axis_value = event_data.get("axis_value", 0.0) as float
			return ev
	return null
