## Audio commands module - 9 tools.
## Handles audio players, buses, and bus effects.
class_name MCPAudioCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func get_commands() -> Dictionary:
	return {
		"audio/add_player": add_audio_player,
		"audio/remove_player": _remove_audio_player,
		"audio/add_bus": add_audio_bus,
		"audio/remove_bus": remove_audio_bus,
		"audio/add_bus_effect": add_audio_bus_effect,
		"audio/remove_bus_effect": remove_audio_bus_effect,
		"audio/set_bus": set_audio_bus,
		"audio/get_bus_layout": get_audio_bus_layout,
		"audio/get_info": get_audio_info,
	}


## Add an AudioStreamPlayer, AudioStreamPlayer2D, or AudioStreamPlayer3D node.
func add_audio_player(params: Dictionary) -> Dictionary:
	var parent_path: String = params.get("parent", params.get("parent_path", ""))
	var player_type: String = params.get("player_type", params.get("type", "AudioStreamPlayer"))
	var node_name: String = params.get("name", player_type)
	var stream_path: String = params.get("stream_path", params.get("stream", ""))
	var properties: Dictionary = params.get("properties", {})

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var parent: Node = root
	if parent_path != "":
		parent = root.get_node_or_null(parent_path)
		if parent == null:
			return {"error": "Parent not found: %s" % parent_path}

	# Create the correct player type
	var player: Node = null
	match player_type:
		"AudioStreamPlayer":
			player = AudioStreamPlayer.new()
		"AudioStreamPlayer2D":
			player = AudioStreamPlayer2D.new()
		"AudioStreamPlayer3D":
			player = AudioStreamPlayer3D.new()
		_:
			return {"error": "Unknown audio player type: %s (use AudioStreamPlayer, AudioStreamPlayer2D, AudioStreamPlayer3D)" % player_type}

	player.name = node_name

	# Load and assign stream if provided
	if stream_path != "":
		var stream: Resource = load(stream_path)
		if stream == null:
			return {"error": "Could not load stream: %s" % stream_path}
		if stream is AudioStream:
			player.stream = stream
		else:
			return {"error": "Resource is not an AudioStream: %s" % stream_path}

	# Apply additional properties
	for prop: String in properties:
		if prop == "stream":
			continue
		if MCPCommandHelpers.has_property(player, prop):
			var expected_type: int = MCPCommandHelpers.get_property_type(player, prop)
			var val: Variant = MCPVariantCodec.parse_for_property(properties[prop], expected_type)
			player.set(prop, val)

	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Add audio player %s" % node_name)
	ur.add_do_method(parent, "add_child", player)
	ur.add_do_method(player, "set_owner", root)
	ur.add_undo_method(parent, "remove_child", player)
	ur.commit_action()

	return {"result": {"name": str(player.name), "path": MCPCommandHelpers.get_node_path(player, _plugin), "type": player_type}}


## Remove an audio player node from the scene.
func _remove_audio_player(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", params.get("path", ""))
	if node_path.is_empty():
		return {"error": "node_path is required"}
	
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	
	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	
	if node == root:
		return {"error": "Cannot remove scene root"}
	
	if not (node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D):
		return {"error": "Node is not an audio player: %s" % node.get_class()}
	
	var parent: Node = node.get_parent()
	if parent == null:
		return {"error": "Node has no parent"}
	
	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Remove audio player %s" % node_path)
	ur.add_do_method(parent, "remove_child", node)
	ur.add_undo_method(parent, "add_child", node)
	ur.add_do_method(node, "set_owner", null)
	ur.add_undo_method(node, "set_owner", root)
	ur.commit_action()
	
	return {"result": {"removed": node_path, "type": node.get_class()}}


## Add a new audio bus to the AudioServer.
func add_audio_bus(params: Dictionary) -> Dictionary:
	var bus_name: String = params.get("name", "")
	var at_index: int = params.get("index", -1)

	if bus_name.is_empty():
		return {"error": "Bus name is required"}

	# Check if bus already exists
	for i: int in range(AudioServer.bus_count):
		if AudioServer.get_bus_name(i) == bus_name:
			return {"error": "Bus already exists: %s" % bus_name}

	var bus_count_before: int = AudioServer.bus_count
	if at_index >= 0 and at_index < bus_count_before:
		AudioServer.add_bus(at_index)
		AudioServer.set_bus_name(at_index, bus_name)
		return {"result": {"name": bus_name, "index": at_index, "total_buses": AudioServer.bus_count}}
	else:
		AudioServer.add_bus()
		var new_index: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(new_index, bus_name)
		return {"result": {"name": bus_name, "index": new_index, "total_buses": AudioServer.bus_count}}


## Remove an audio bus by name.
func remove_audio_bus(params: Dictionary) -> Dictionary:
	var bus_name: String = params.get("name", params.get("bus_name", params.get("bus", "")))
	if bus_name.is_empty():
		return {"error": "Bus name is required"}

	if bus_name == "Master":
		return {"error": "Cannot remove the Master bus"}

	var bus_idx: int = MCPCommandHelpers.find_bus_index(bus_name)
	if bus_idx == -1:
		return {"error": "Bus not found: %s" % bus_name}

	var total_before: int = AudioServer.bus_count
	AudioServer.remove_bus(bus_idx)
	return {"result": {"removed": bus_name, "index": bus_idx, "total_buses": AudioServer.bus_count}}


## Add an effect to an audio bus.
func add_audio_bus_effect(params: Dictionary) -> Dictionary:
	var bus_name: String = params.get("bus_name", params.get("bus", ""))
	var effect_type: String = params.get("effect_type", "")
	var at_index: int = params.get("index", -1)
	var properties: Dictionary = params.get("properties", {})

	if bus_name.is_empty():
		return {"error": "Bus name is required"}
	if effect_type.is_empty():
		return {"error": "Effect type is required"}

	var bus_idx: int = MCPCommandHelpers.find_bus_index(bus_name)
	if bus_idx == -1:
		return {"error": "Bus not found: %s" % bus_name}

	# Create the audio effect
	var effect: AudioEffect = _create_audio_effect(effect_type)
	if effect == null:
		return {"error": "Unknown effect type: %s" % effect_type}

	# Apply properties
	for prop: String in properties:
		if MCPCommandHelpers.has_property(effect, prop):
			var expected_type: int = MCPCommandHelpers.get_property_type(effect, prop)
			var val: Variant = MCPVariantCodec.parse_for_property(properties[prop], expected_type)
			effect.set(prop, val)

	if at_index >= 0:
		AudioServer.add_bus_effect(bus_idx, effect, at_index)
	else:
		AudioServer.add_bus_effect(bus_idx, effect)

	var effect_count: int = AudioServer.get_bus_effect_count(bus_idx)
	return {"result": {"bus": bus_name, "effect_type": effect_type, "effect_index": effect_count - 1, "total_effects": effect_count}}


## Remove an effect from an audio bus by index.
func remove_audio_bus_effect(params: Dictionary) -> Dictionary:
	var bus_name: String = params.get("bus_name", params.get("bus", ""))
	if bus_name.is_empty():
		return {"error": "Bus name is required"}

	var bus_idx: int = MCPCommandHelpers.find_bus_index(bus_name)
	if bus_idx == -1:
		return {"error": "Bus not found: %s" % bus_name}

	var effect_index: int = params.get("effect_index", params.get("index", -1))
	if effect_index < 0:
		return {"error": "effect_index is required"}

	var effect_count: int = AudioServer.get_bus_effect_count(bus_idx)
	if effect_index >= effect_count:
		return {"error": "Effect index %d out of range (bus has %d effects)" % [effect_index, effect_count]}

	AudioServer.remove_bus_effect(bus_idx, effect_index)
	return {"result": {"bus": bus_name, "removed_effect_index": effect_index, "total_effects": AudioServer.get_bus_effect_count(bus_idx)}}


## Set bus properties: volume_db, solo, mute, bypass_effects.
func set_audio_bus(params: Dictionary) -> Dictionary:
	var bus_name: String = params.get("bus_name", params.get("bus", ""))
	if bus_name.is_empty():
		return {"error": "Bus name is required"}

	var bus_idx: int = MCPCommandHelpers.find_bus_index(bus_name)
	if bus_idx == -1:
		return {"error": "Bus not found: %s" % bus_name}

	var changed: Dictionary = {}

	# Support both flat params and nested "properties" dict from TS schema
	var props: Dictionary = params
	if params.has("properties") and params["properties"] is Dictionary:
		props = params["properties"] as Dictionary

	if props.has("volume_db"):
		var vol: float = props["volume_db"] as float
		AudioServer.set_bus_volume_db(bus_idx, vol)
		changed["volume_db"] = vol

	if props.has("solo"):
		var solo: bool = props["solo"] as bool
		AudioServer.set_bus_solo(bus_idx, solo)
		changed["solo"] = solo

	if props.has("mute"):
		var mute: bool = props["mute"] as bool
		AudioServer.set_bus_mute(bus_idx, mute)
		changed["mute"] = mute

	if props.has("bypass_effects"):
		var bypass: bool = props["bypass_effects"] as bool
		AudioServer.set_bus_bypass_effects(bus_idx, bypass)
		changed["bypass_effects"] = bypass

	if params.has("send"):
		var send_bus: String = params["send"] as String
		var send_idx: int = MCPCommandHelpers.find_bus_index(send_bus)
		if send_idx == -1:
			return {"error": "Send bus not found: %s" % send_bus}
		AudioServer.set_bus_send(bus_idx, send_bus)
		changed["send"] = send_bus

	if changed.is_empty():
		return {"error": "No valid properties provided (volume_db, solo, mute, bypass_effects, send)"}

	return {"result": {"bus": bus_name, "changed": changed}}


## Get the full audio bus layout with all buses and their effects.
func get_audio_bus_layout(_params: Dictionary) -> Dictionary:
	var buses: Array = MCPCommandHelpers.collect_bus_layout()
	return {"result": {"bus_count": buses.size(), "buses": buses}}


## Get audio configuration info for a specific audio node in the scene.
func get_audio_info(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var info: Dictionary = {
		"path": path,
		"type": node.get_class(),
	}

	if node is AudioStreamPlayer:
		var player: AudioStreamPlayer = node as AudioStreamPlayer
		info["stream"] = player.stream.resource_path if player.stream else ""
		info["volume_db"] = player.volume_db
		info["pitch_scale"] = player.pitch_scale
		info["playing"] = player.playing
		info["autoplay"] = player.autoplay
		info["bus"] = player.bus
		info["mix_target"] = player.mix_target
	elif node is AudioStreamPlayer2D:
		var player: AudioStreamPlayer2D = node as AudioStreamPlayer2D
		info["stream"] = player.stream.resource_path if player.stream else ""
		info["volume_db"] = player.volume_db
		info["pitch_scale"] = player.pitch_scale
		info["playing"] = player.playing
		info["autoplay"] = player.autoplay
		info["bus"] = player.bus
		info["max_distance"] = player.max_distance
		info["attenuation"] = player.attenuation
		info["position"] = {"x": player.position.x, "y": player.position.y}
	elif node is AudioStreamPlayer3D:
		var player: AudioStreamPlayer3D = node as AudioStreamPlayer3D
		info["stream"] = player.stream.resource_path if player.stream else ""
		info["volume_db"] = player.volume_db
		info["pitch_scale"] = player.pitch_scale
		info["playing"] = player.playing
		info["autoplay"] = player.autoplay
		info["bus"] = player.bus
		info["max_distance"] = player.max_distance
		info["attenuation_model"] = player.attenuation_model
		info["unit_size"] = player.unit_size
		var pos: Vector3 = player.position
		info["position"] = {"x": pos.x, "y": pos.y, "z": pos.z}
	else:
		return {"error": "Node is not an audio player: %s (%s)" % [path, node.get_class()]}

	return {"result": info}





## Helper: create an AudioEffect by type name.
func _create_audio_effect(effect_type: String) -> AudioEffect:
	match effect_type.to_lower():
		"audioeffectreverb", "reverb":
			return AudioEffectReverb.new()
		"audioeffectdelay", "delay":
			return AudioEffectDelay.new()
		"audioeffectchorus", "chorus":
			return AudioEffectChorus.new()
		"audioeffectcompressor", "compressor":
			return AudioEffectCompressor.new()
		"audioeffectlimiter", "limiter":
			return AudioEffectLimiter.new()
		"audioeffectdistortion", "distortion":
			return AudioEffectDistortion.new()
		"audioeffecteq6", "eq6":
			return AudioEffectEQ6.new()
		"audioeffecteq10", "eq10":
			return AudioEffectEQ10.new()
		"audioeffecteq21", "eq21":
			return AudioEffectEQ21.new()
		"audioeffectlowpassfilter", "lowpass":
			return AudioEffectLowPassFilter.new()
		"audioeffecthighpassfilter", "highpass":
			return AudioEffectHighPassFilter.new()
		"audioeffectbandpassfilter", "bandpass":
			return AudioEffectBandPassFilter.new()
		"audioeffectnotchfilter", "notch":
			return AudioEffectNotchFilter.new()
		"audioeffectpitchshift", "pitchshift":
			return AudioEffectPitchShift.new()
		"audioeffectspectrumanalyzer", "spectrum":
			return AudioEffectSpectrumAnalyzer.new()
		"audioeffectamplify", "amplify":
			return AudioEffectAmplify.new()
		"audioeffectstereoenhance", "stereo":
			return AudioEffectStereoEnhance.new()
		"audioeffectpanner", "panner":
			return AudioEffectPanner.new()
		_:
			if ClassDB.can_instantiate(effect_type):
				var obj: Object = ClassDB.instantiate(effect_type)
				if obj is AudioEffect:
					return obj as AudioEffect
			return null



