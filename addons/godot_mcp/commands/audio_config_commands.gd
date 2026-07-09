## Audio configuration commands module - 9 tools.
## Handles audio bus layout, effects, driver, and render settings.
class_name MCPAudioConfigCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


## Router compatibility: returns callable map for MCPCommandRouter.
func get_commands() -> Dictionary:
	return {
		"audio_config/get_settings": func(params: Dictionary) -> Dictionary: return execute("get_settings", params),
		"audio_config/set_bus_layout": func(params: Dictionary) -> Dictionary: return execute("set_bus_layout", params),
		"audio_config/add_bus_config": func(params: Dictionary) -> Dictionary: return execute("add_bus_config", params),
		"audio_config/remove_bus": func(params: Dictionary) -> Dictionary: return execute("remove_bus", params),
		"audio_config/set_bus_volume": func(params: Dictionary) -> Dictionary: return execute("set_bus_volume", params),
		"audio_config/get_bus_effects": func(params: Dictionary) -> Dictionary: return execute("get_bus_effects", params),
		"audio_config/set_driver": func(params: Dictionary) -> Dictionary: return execute("set_driver", params),
		"audio_config/set_mix_rate": func(params: Dictionary) -> Dictionary: return execute("set_mix_rate", params),
		"audio_config/set_output_latency": func(params: Dictionary) -> Dictionary: return execute("set_output_latency", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_settings": return _get_settings()
		"set_bus_layout": return _set_bus_layout(params)
		"add_bus_config": return _add_bus(params)
		"remove_bus": return _remove_bus(params)
		"set_bus_volume": return _set_bus_volume(params)
		"get_bus_effects": return _get_bus_effects(params)
		"set_driver": return _set_driver(params)
		"set_mix_rate": return _set_mix_rate(params)
		"set_output_latency": return _set_output_latency(params)
	return {"success": false, "error": "Unknown method: " + method}


## Get all audio settings including driver info.
func _get_settings() -> Dictionary:
	var buses: Array = MCPCommandHelpers.collect_bus_layout()
	var settings: Dictionary = {
		"driver": AudioServer.get_driver_name(),
		"mix_rate": AudioServer.get_mix_rate(),
		"output_latency": AudioServer.get_output_latency(),
		"bus_count": AudioServer.bus_count,
		"buses": buses,
		"default_bus": ProjectSettings.get_setting("audio/buses/default_bus", "Master"),
	}
	return {"success": true, "settings": settings}


## Replace the entire bus layout.
func _set_bus_layout(params: Dictionary) -> Dictionary:
	var buses: Array = params.get("buses", [])
	if buses.is_empty():
		return {"success": false, "error": "Buses list cannot be empty"}
	# Remove all buses except Master
	while AudioServer.bus_count > 1:
		AudioServer.remove_bus(AudioServer.bus_count - 1)
	# Configure Master from first entry
	if buses.size() > 0:
		var master: Dictionary = buses[0] as Dictionary
		AudioServer.set_bus_name(0, master.get("name", "Master"))
		if master.has("volume_db") or master.has("volume"):
			var vol: float = master.get("volume_db", master.get("volume", 0.0)) as float
			AudioServer.set_bus_volume_db(0, vol)
		if master.has("solo"):
			AudioServer.set_bus_solo(0, master["solo"] as bool)
		if master.has("mute"):
			AudioServer.set_bus_mute(0, master["mute"] as bool)
	# Add remaining buses
	for i: int in range(1, buses.size()):
		var bus_data: Dictionary = buses[i] as Dictionary
		AudioServer.add_bus()
		var idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_data.get("name", "Bus%d" % idx))
		if bus_data.has("volume_db") or bus_data.has("volume"):
			var vol: float = bus_data.get("volume_db", bus_data.get("volume", 0.0)) as float
			AudioServer.set_bus_volume_db(idx, vol)
		if bus_data.has("solo"):
			AudioServer.set_bus_solo(idx, bus_data["solo"] as bool)
		if bus_data.has("mute"):
			AudioServer.set_bus_mute(idx, bus_data["mute"] as bool)
	return {"success": true, "bus_count": AudioServer.bus_count, "message": "Bus layout replaced"}


## Add a new audio bus.
func _add_bus(params: Dictionary) -> Dictionary:
	var bus_name: String = params.get("name", "")
	var at_index: int = params.get("index", -1)
	if bus_name.is_empty():
		return {"success": false, "error": "Bus name is required"}
	if at_index < -1:
		return {"success": false, "error": "Index must be -1 (append) or >= 0"}
	for i: int in range(AudioServer.bus_count):
		if AudioServer.get_bus_name(i) == bus_name:
			return {"success": false, "error": "Bus already exists: %s" % bus_name}
	if at_index >= 0 and at_index < AudioServer.bus_count:
		AudioServer.add_bus(at_index)
		AudioServer.set_bus_name(at_index, bus_name)
		return {"success": true, "name": bus_name, "index": at_index, "total": AudioServer.bus_count}
	AudioServer.add_bus()
	var new_idx: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(new_idx, bus_name)
	return {"success": true, "name": bus_name, "index": new_idx, "total": AudioServer.bus_count}


## Remove an audio bus by index.
func _remove_bus(params: Dictionary) -> Dictionary:
	var at_index: int = params.get("index", -1)
	if at_index < 1:
		return {"success": false, "error": "Cannot remove bus at index %d. Use index >= 1 (Master is at index 0)." % at_index}
	if at_index >= AudioServer.bus_count:
		return {"success": false, "error": "Index out of range: %d (bus count: %d)" % [at_index, AudioServer.bus_count]}
	var name: String = AudioServer.get_bus_name(at_index)
	AudioServer.remove_bus(at_index)
	return {"success": true, "removed": name, "index": at_index, "total": AudioServer.bus_count}


## Set the volume of a specific bus.
func _set_bus_volume(params: Dictionary) -> Dictionary:
	var bus_name: String = params.get("bus", "")
	var volume_db: float = params.get("volume_db", 0.0)
	if bus_name.is_empty():
		return {"success": false, "error": "Bus name is required"}
	var bus_idx: int = MCPCommandHelpers.find_bus_index(bus_name)
	if bus_idx == -1:
		return {"success": false, "error": "Bus not found: %s" % bus_name}
	AudioServer.set_bus_volume_db(bus_idx, volume_db)
	return {"success": true, "bus": bus_name, "volume_db": volume_db}


## Get effects on a specific bus.
func _get_bus_effects(params: Dictionary) -> Dictionary:
	var bus_name: String = params.get("bus", "")
	if bus_name.is_empty():
		return {"success": false, "error": "Bus name is required"}
	var bus_idx: int = MCPCommandHelpers.find_bus_index(bus_name)
	if bus_idx == -1:
		var available: Array = []
		for i: int in range(AudioServer.bus_count):
			available.append(AudioServer.get_bus_name(i))
		return {"success": false, "error": "Bus not found: %s. Available: %s" % [bus_name, ", ".join(available)]}
	var effects: Array = []
	var count: int = AudioServer.get_bus_effect_count(bus_idx)
	for i: int in range(count):
		var effect: AudioEffect = AudioServer.get_bus_effect(bus_idx, i)
		if effect != null:
			var props: Dictionary = {}
			for p: Dictionary in effect.get_property_list():
				var pname: String = p["name"] as String
				var usage: int = p["usage"] as int
				if usage & PROPERTY_USAGE_STORAGE == 0:
					continue
				if pname.begins_with("resource_") or pname.begins_with("script"):
					continue
				var val: Variant = effect.get(pname)
				if val != null:
					props[pname] = val
			effects.append({
				"index": i,
				"type": effect.get_class(),
				"enabled": AudioServer.is_bus_effect_enabled(bus_idx, i),
				"properties": props,
			})
	return {"success": true, "bus": bus_name, "effects": effects, "count": effects.size()}


## Set the audio driver name (takes effect on next restart).
func _set_driver(params: Dictionary) -> Dictionary:
	var driver_name: String = params.get("driver", "")
	if driver_name.is_empty():
		return {"success": false, "error": "Driver name is required"}
	ProjectSettings.set_setting("audio/driver/driver", driver_name)
	return {"success": true, "driver": driver_name, "message": "Driver set. Restart Godot for the change to take effect."}


## Set the audio mix rate (takes effect on next restart).
func _set_mix_rate(params: Dictionary) -> Dictionary:
	var mix_rate: int = params.get("mix_rate", 0)
	if mix_rate < 11025 or mix_rate > 192000:
		return {"success": false, "error": "Mix rate must be between 11025 and 192000 Hz"}
	ProjectSettings.set_setting("audio/driver/mix_rate", mix_rate)
	return {"success": true, "mix_rate": mix_rate, "message": "Mix rate set. Restart Godot for the change to take effect."}


## Set the audio output latency (takes effect on next restart).
func _set_output_latency(params: Dictionary) -> Dictionary:
	var latency: int = params.get("output_latency", 0)
	if latency < 1 or latency > 100:
		return {"success": false, "error": "Output latency must be between 1 and 100 ms"}
	ProjectSettings.set_setting("audio/driver/output_latency", latency)
	return {"success": true, "output_latency": latency, "message": "Latency set. Restart Godot for the change to take effect."}



