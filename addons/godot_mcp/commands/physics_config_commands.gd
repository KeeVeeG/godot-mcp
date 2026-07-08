## Physics configuration commands module - 8 tools.
## Handles physics engine settings, gravity, FPS, layers, and damping.
class_name MCPPhysicsConfigCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


## Router compatibility: returns callable map for MCPCommandRouter.
func get_commands() -> Dictionary:
	return {
		"physics_config/get_settings": func(params: Dictionary) -> Dictionary: return execute("get_settings", params),
		"physics_config/set_gravity": func(params: Dictionary) -> Dictionary: return execute("set_gravity", params),
		"physics_config/set_fps": func(params: Dictionary) -> Dictionary: return execute("set_fps", params),
		"physics_config/set_engine": func(params: Dictionary) -> Dictionary: return execute("set_engine", params),
		"physics_config/set_layer_name": func(params: Dictionary) -> Dictionary: return execute("set_layer_name", params),
		"physics_config/get_layers": func(params: Dictionary) -> Dictionary: return execute("get_layers", params),
		"physics_config/set_default_gravity": func(params: Dictionary) -> Dictionary: return execute("set_default_gravity", params),
		"physics_config/set_default_linear_damp": func(params: Dictionary) -> Dictionary: return execute("set_default_linear_damp", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_settings": return _get_settings()
		"set_gravity": return _set_gravity(params)
		"set_fps": return _set_fps(params)
		"set_engine": return _set_engine(params)
		"set_layer_name": return _set_layer_name(params)
		"get_layers": return _get_layers()
		"set_default_gravity": return _set_default_gravity(params)
		"set_default_linear_damp": return _set_default_linear_damp(params)
	return {"success": false, "error": "Unknown method: " + method}


## Get all physics settings.
func _get_settings() -> Dictionary:
	var gravity_2d: Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector", Vector2(0, 1)) as Vector2
	var gravity_2d_val: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	var gravity_3d: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector", Vector3(0, -9.8, 0)) as Vector3
	var gravity_3d_val: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	var settings: Dictionary = {
		"physics_fps": ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60),
		"gravity_2d": {
			"vector": {"x": gravity_2d.x, "y": gravity_2d.y},
			"magnitude": gravity_2d_val,
		},
		"gravity_3d": {
			"vector": {"x": gravity_3d.x, "y": gravity_3d.y, "z": gravity_3d.z},
			"magnitude": gravity_3d_val,
		},
		"default_linear_damp_2d": ProjectSettings.get_setting("physics/2d/default_linear_damp", 0.0),
		"default_angular_damp_2d": ProjectSettings.get_setting("physics/2d/default_angular_damp", 1.0),
		"default_linear_damp_3d": ProjectSettings.get_setting("physics/3d/default_linear_damp", 0.0),
		"default_angular_damp_3d": ProjectSettings.get_setting("physics/3d/default_angular_damp", 0.0),
		"physics_engine_2d": ProjectSettings.get_setting("physics/2d/physics_engine", "DEFAULT"),
		"physics_engine_3d": ProjectSettings.get_setting("physics/3d/physics_engine", "DEFAULT"),
		"collision_layers": _get_layer_names_internal(),
	}
	return {"success": true, "settings": settings}


## Set the gravity vector.
func _set_gravity(params: Dictionary) -> Dictionary:
	var x: float = params.get("x", 0.0)
	var y: float = params.get("y", 9.8)
	var z: float = params.get("z", 0.0)
	# Set 2D gravity (vector and magnitude)
	ProjectSettings.set_setting("physics/2d/default_gravity_vector", Vector2(x, y).normalized())
	ProjectSettings.set_setting("physics/2d/default_gravity", Vector2(x, y).length())
	# Set 3D gravity (vector and magnitude)
	var vec3: Vector3 = Vector3(x, y, z)
	ProjectSettings.set_setting("physics/3d/default_gravity_vector", vec3.normalized())
	ProjectSettings.set_setting("physics/3d/default_gravity", vec3.length())
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "gravity": {"x": x, "y": y, "z": z}}


## Set physics FPS.
func _set_fps(params: Dictionary) -> Dictionary:
	var fps: int = params.get("fps", 60)
	if fps < 1 or fps > 240:
		return {"success": false, "error": "FPS must be between 1 and 240"}
	ProjectSettings.set_setting("physics/common/physics_ticks_per_second", fps)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "fps": fps, "message": "Physics FPS set to %d" % fps}


## Set physics engine.
func _set_engine(params: Dictionary) -> Dictionary:
	var engine: String = params.get("engine", "default")
	var engine_map: Dictionary = {
		"default": "DEFAULT",
		"godot_physics": "GodotPhysics3D",
		"jolt": "Jolt Physics",
	}
	if not engine_map.has(engine):
		return {"success": false, "error": "Unknown engine: %s (use: default, godot_physics, jolt)" % engine}
	var engine_name: String = engine_map[engine] as String
	ProjectSettings.set_setting("physics/3d/physics_engine", engine_name)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "engine": engine, "message": "Physics engine set to %s" % engine_name}


## Set a collision layer name.
func _set_layer_name(params: Dictionary) -> Dictionary:
	var layer: int = params.get("layer", 0)
	var name: String = params.get("name", "")
	if layer < 1 or layer > 32:
		return {"success": false, "error": "Layer must be between 1 and 32"}
	if name.is_empty():
		return {"success": false, "error": "Name cannot be empty"}
	var key: String = "layer_names/3d_physics/layer_%d" % layer
	ProjectSettings.set_setting(key, name)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "layer": layer, "name": name}


## Get all collision layer names.
func _get_layers() -> Dictionary:
	var layers: Dictionary = _get_layer_names_internal()
	return {"success": true, "layers": layers}


## Set default gravity magnitude.
func _set_default_gravity(params: Dictionary) -> Dictionary:
	var value: float = params.get("value", 9.8)
	ProjectSettings.set_setting("physics/2d/default_gravity", value)
	ProjectSettings.set_setting("physics/3d/default_gravity", value)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "value": value, "message": "Default gravity set to %f" % value}


## Set default linear damping.
func _set_default_linear_damp(params: Dictionary) -> Dictionary:
	var value: float = params.get("value", 0.1)
	ProjectSettings.set_setting("physics/3d/default_linear_damp", value)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "value": value, "message": "Default linear damp set to %f" % value}


## Internal helper: get layer names dictionary.
func _get_layer_names_internal() -> Dictionary:
	var layers: Dictionary = {}
	for i: int in range(1, 33):
		var key: String = "layer_names/3d_physics/layer_%d" % i
		var name: String = ProjectSettings.get_setting(key, "") as String
		if name.is_empty():
			name = "Layer %d" % i
		layers["%d" % i] = name
	return layers
