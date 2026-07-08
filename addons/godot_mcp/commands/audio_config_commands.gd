## Audio configuration commands module - 6 tools.
## Handles audio bus layout, effects, and settings.
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
		if master.has("volume"):
			AudioServer.set_bus_volume_db(0, master["volume"] as float)
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
		if bus_data.has("volume"):
			AudioServer.set_bus_volume_db(idx, bus_data["volume"] as float)
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
		return {"success": false, "error": "Cannot remove Master bus (index 0). Use index >= 1."}
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



