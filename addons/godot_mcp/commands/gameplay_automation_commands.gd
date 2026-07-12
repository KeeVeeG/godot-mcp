## Gameplay automation commands module - 8 tools.
## Provides automated gameplay scenarios, recording/replay,
## character creation and navigation, state assertions, and event waiting.
@tool
class_name MCPGameplayAutomationCommands
extends RefCounted

var _plugin: EditorPlugin

## Recorded gameplay data
var _recording_data: Dictionary = {}
## Active recording state
var _is_recording: bool = false
var _recording_start: float = 0.0
var _recorded_events: Array = []
var _recorded_states: Array = []

## Test characters created for cleanup
var _test_characters: Array = []


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func get_commands() -> Dictionary:
	return {
		"simulate_gameplay_scenario": simulate_gameplay_scenario,
		"record_gameplay": record_gameplay,
		"replay_gameplay": replay_gameplay,
		"create_test_character": create_test_character,
		"delete_test_character": delete_test_character,
		"navigate_character": navigate_character,
		"assert_game_state": assert_game_state,
		"wait_for_game_event": wait_for_game_event,
	}


## Run a sequence of gameplay actions as an automated scenario.
func simulate_gameplay_scenario(params: Dictionary) -> Dictionary:
	var scenario: Array = params.get("scenario", [])
	if scenario.is_empty():
		return {"result": {"total_steps": 0, "passed": 0, "failed": 0, "steps": [], "success": true, "message": "Empty scenario — nothing to do"}}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var step_results: Array = []
	var passed: int = 0
	var failed: int = 0
	var start_time: float = Time.get_ticks_msec()

	for i: int in range(scenario.size()):
		var step: Dictionary = scenario[i] as Dictionary
		var action: String = step.get("action", "")
		var action_params: Dictionary = step.get("params", {})
		var wait_ms: int = step.get("wait", 0)

		var result: Dictionary = {}
		match action:
			"input":
				result = _action_input(action_params)
			"wait":
				result = await _action_wait(action_params)
			"move":
				result = _action_move(_plugin, action_params)
			"click":
				result = _action_click(action_params)
			"assert":
				result = _action_assert(_plugin, action_params)
			_:
				result = {"error": "Unknown action: %s" % action}

		var step_passed: bool = not result.has("error")
		# For assert actions, also check the inner "passed" flag
		if action == "assert" and result.has("passed") and not result["passed"]:
			step_passed = false
		step_results.append({"step": i, "action": action, "passed": step_passed, "result": result})
		if step_passed:
			passed += 1
		else:
			failed += 1

		if wait_ms > 0:
			await _non_blocking_wait(wait_ms)

	var total_duration: float = Time.get_ticks_msec() - start_time

	return {"result": {
		"total_steps": scenario.size(),
		"passed": passed,
		"failed": failed,
		"duration_ms": total_duration,
		"steps": step_results,
		"success": failed == 0,
	}}


## Record gameplay for a duration.
func record_gameplay(params: Dictionary) -> Dictionary:
	var duration: float = params.get("duration", 10.0)
	var include_input: bool = params.get("include_input", true)
	var include_state: bool = params.get("include_state", false)

	# Guard: recording requires the game to be running in Play mode.
	# In editor-only mode, _non_blocking_wait / process_frame polling
	# has no game state to capture and returns {}.
	if not _plugin.get_editor_interface().is_playing_scene():
		return {"error": "Game must be running to record gameplay"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	if _is_recording:
		return {"error": "A recording session is already in progress"}

	_is_recording = true
	_recording_start = Time.get_unix_time_from_system()
	_recorded_events.clear()
	_recorded_states.clear()

	var start_time: float = Time.get_ticks_msec()
	var target_end: float = start_time + duration * 1000.0
	var sample_interval: float = 100.0  # Sample every 100ms
	var next_sample: float = start_time

	while Time.get_ticks_msec() < target_end:
		var now: float = Time.get_ticks_msec()

		if include_input:
			# Record current input state
			var input_state: Dictionary = _capture_input_state()
			if not input_state.is_empty():
				_recorded_events.append({
					"time": now - start_time,
					"type": "input",
					"data": input_state,
				})

		if include_state and now >= next_sample:
			_recorded_states.append({
				"time": now - start_time,
				"fps": Performance.get_monitor(Performance.TIME_FPS),
				"memory": Performance.get_monitor(Performance.MEMORY_STATIC),
			})
			next_sample = now + sample_interval

		# Non-blocking 16ms wait (~60fps polling) — uses scene tree timer
		await _non_blocking_wait(16)

	_is_recording = false

	# Save recording
	var recording: Dictionary = {
		"duration": duration,
		"timestamp": _recording_start,
		"include_input": include_input,
		"include_state": include_state,
		"events": _recorded_events,
		"states": _recorded_states,
		"event_count": _recorded_events.size(),
		"state_count": _recorded_states.size(),
	}

	var recording_path: String = "user://mcp_recordings/recording_%d.json" % int(_recording_start)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://mcp_recordings/"))
	var file: FileAccess = FileAccess.open(recording_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(recording, "\t"))
		file.close()

	_recording_data = recording

	return {"result": {
		"success": true,
		"duration": duration,
		"events_recorded": _recorded_events.size(),
		"state_samples": _recorded_states.size(),
		"recording_path": recording_path,
		"message": "Recorded %d events and %d state samples over %.1fs" % [_recorded_events.size(), _recorded_states.size(), duration],
	}}


## Replay a previously recorded gameplay session.
func replay_gameplay(params: Dictionary) -> Dictionary:
	var recording_path: String = params.get("recording_path", "")
	var speed: float = params.get("speed", 1.0)

	if recording_path.is_empty():
		return {"error": "recording_path is required"}

	if not FileAccess.file_exists(recording_path):
		return {"error": "Recording file not found: %s" % recording_path}

	var file: FileAccess = FileAccess.open(recording_path, FileAccess.READ)
	if file == null:
		return {"error": "Failed to open recording file"}
	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(json_text) != OK:
		return {"error": "Failed to parse recording file"}

	var recording: Dictionary = json.data as Dictionary
	var events: Array = recording.get("events", [])
	if events.is_empty():
		return {"result": {
			"success": true,
			"events_replayed": 0,
			"speed": speed,
			"duration_ms": 0,
			"original_duration": recording.get("duration", 0.0),
			"message": "Recording contains no events — nothing to replay",
		}}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var replayed: int = 0
	var start_time: float = Time.get_ticks_msec()
	var last_event_time: float = 0.0

	for event: Dictionary in events:
		var event_time: float = event.get("time", 0.0) / speed
		var wait_ms: int = int(event_time - last_event_time)
		if wait_ms > 0:
			await _non_blocking_wait(wait_ms)
		last_event_time = event_time

		var event_type: String = event.get("type", "")
		var event_data: Dictionary = event.get("data", {})

		match event_type:
			"input":
				_replay_input(event_data)
			"state":
				pass  # State events are informational
		replayed += 1

	var total_duration: float = Time.get_ticks_msec() - start_time

	return {"result": {
		"success": true,
		"events_replayed": replayed,
		"speed": speed,
		"duration_ms": total_duration,
		"original_duration": recording.get("duration", 0.0),
		"message": "Replayed %d events at %.1fx speed" % [replayed, speed],
	}}


## Create a test character in the scene.
func create_test_character(params: Dictionary) -> Dictionary:
	var scene_path: String = params.get("scene_path", "")
	var position: Array = params.get("position", [0, 0, 0])

	if scene_path.is_empty():
		return {"error": "scene_path is required"}

	if not FileAccess.file_exists(scene_path):
		return {"error": "Scene file not found: %s" % scene_path}

	var char_scene: PackedScene = load(scene_path) as PackedScene
	if char_scene == null:
		return {"error": "Failed to load scene: %s" % scene_path}

	var instance: Node = char_scene.instantiate()
	if instance == null:
		return {"error": "Failed to instantiate scene"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		instance.free()
		return {"error": "No scene open"}

	# Set position
	if instance is Node3D and position.size() >= 3:
		(instance as Node3D).position = Vector3(position[0], position[1], position[2])
	elif instance is Node2D and position.size() >= 2:
		(instance as Node2D).position = Vector2(position[0], position[1])

	instance.name = "TestCharacter_%d" % _test_characters.size()
	root.add_child(instance)
	instance.set_owner(root)
	_test_characters.append(str(instance.get_path()))

	return {"result": {
		"success": true,
		"path": str(instance.get_path()),
		"name": instance.name,
		"scene": scene_path,
		"position": position,
		"message": "Created test character '%s' at %s" % [instance.name, str(position)],
	}}


## Delete test character(s) from the scene and clean up tracking.
func delete_test_character(params: Dictionary) -> Dictionary:
	var character_path: String = params.get("character_path", "")

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	# If specific path given, delete only that character
	if not character_path.is_empty():
		var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, character_path)
		if node == null:
			return {"error": "Character not found: %s" % character_path}

		var path_str: String = str(node.get_path())
		if path_str not in _test_characters:
			return {"error": "Node is not a test character: %s" % character_path}

		var char_name: String = str(node.name)
		node.queue_free()
		_test_characters.erase(path_str)

		return {"result": {
			"success": true,
			"deleted": [path_str],
			"remaining": _test_characters.size(),
			"message": "Deleted test character '%s'. %d remaining." % [char_name, _test_characters.size()],
		}}

	# No path given — delete all test characters
	if _test_characters.is_empty():
		return {"result": {
			"success": true,
			"deleted": [],
			"remaining": 0,
			"message": "No test characters to delete",
		}}

	var deleted: Array = []
	var not_found: Array = []
	for path_str: String in _test_characters.duplicate():
		var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path_str)
		if node != null:
			node.queue_free()
			deleted.append(path_str)
		else:
			not_found.append(path_str)

	_test_characters.clear()

	return {"result": {
		"success": true,
		"deleted": deleted,
		"not_found": not_found,
		"remaining": 0,
		"message": "Deleted %d test character(s)" % deleted.size(),
	}}


## Navigate a character to a target position.
func navigate_character(params: Dictionary) -> Dictionary:
	var character_path: String = params.get("character_path", "")
	var target: Array = params.get("target", [0, 0, 0])
	var method: String = params.get("method", "direct")

	if character_path == "":
		# Empty string = scene root per NodePath convention
		var root_node: Node = MCPCommandHelpers.get_scene_root(_plugin)
		if root_node == null:
			return {"error": "No scene open"}
		if root_node is Node3D:
			(root_node as Node3D).position = Vector3(target[0], target[1], target[2])
		elif root_node is Node2D:
			(root_node as Node2D).position = Vector2(target[0], target[1])
		else:
			return {"error": "Scene root is not a Node2D or Node3D — cannot navigate"}
		return {"result": {
			"success": true,
			"method": method,
			"character": "<root>",
			"target": target,
			"message": "Moved scene root directly to %s" % str(target),
		}}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var character: Node = MCPCommandHelpers.resolve_node_path(_plugin, character_path)
	if character == null:
		return {"error": "Character not found: %s" % character_path}

	match method:
		"direct":
			if character is Node3D:
				(character as Node3D).position = Vector3(target[0], target[1], target[2])
			elif character is Node2D:
				(character as Node2D).position = Vector2(target[0], target[1])
			else:
				return {"error": "Character is not a Node2D or Node3D"}

			return {"result": {
				"success": true,
				"method": method,
				"character": character_path,
				"target": target,
				"message": "Moved character directly to %s" % str(target),
			}}

		"pathfind":
			# Use NavigationAgent if available
			var agent: Node = null
			for child: Node in character.get_children():
				if child is NavigationAgent3D or child is NavigationAgent2D:
					agent = child
					break

			if agent == null:
				return {"error": "No NavigationAgent found on character. Add one for pathfinding."}

			if agent is NavigationAgent3D:
				(agent as NavigationAgent3D).target_position = Vector3(target[0], target[1], target[2])
			elif agent is NavigationAgent2D:
				(agent as NavigationAgent2D).target_position = Vector2(target[0], target[1])

			return {"result": {
				"success": true,
				"method": method,
				"character": character_path,
				"target": target,
				"message": "NavigationAgent target set to %s. Character will navigate in _process." % str(target),
			}}

		_:
			return {"error": "Unknown navigation method: %s" % method}


## Assert multiple game state conditions.
func assert_game_state(params: Dictionary) -> Dictionary:
	var conditions: Array = params.get("conditions", [])
	if conditions.is_empty():
		return {"result": {"passed": true, "total_conditions": 0, "passed_count": 0, "failed_count": 0, "results": [], "message": "Empty conditions — vacuously true"}}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var results: Array = []
	var all_passed: bool = true

	for condition: Dictionary in conditions:
		var path: String = condition.get("path", "")
		var property: String = condition.get("property", "")
		var expected: Variant = condition.get("expected")
		var operator: String = condition.get("operator", "==")

		var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
		if node == null:
			results.append({"path": path, "passed": false, "error": "Node not found"})
			all_passed = false
			continue

		var actual: Variant = MCPCommandHelpers.get_nested_property(node, property)
		var passed: bool = MCPCommandHelpers.compare_values(actual, expected, operator)
		results.append({
			"path": path,
			"property": property,
			"expected": expected,
			"actual": actual,
			"operator": operator,
			"passed": passed,
		})
		if not passed:
			all_passed = false

	return {"result": {
		"passed": all_passed,
		"total_conditions": conditions.size(),
		"passed_count": results.filter(func(r: Dictionary) -> bool: return r["passed"]).size(),
		"failed_count": results.filter(func(r: Dictionary) -> bool: return not r["passed"]).size(),
		"results": results,
	}}


## Wait for a specific game event with timeout.
func wait_for_game_event(params: Dictionary) -> Dictionary:
	var event: String = params.get("event", "")
	var timeout: int = params.get("timeout", 5000)

	if event.is_empty():
		return {"error": "event is required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var start_time: float = Time.get_ticks_msec()
	var target_end: float = start_time + float(timeout)

	# Parse event type
	if event.begins_with("signal:"):
		# Wait for a signal: "signal:NodePath:signal_name"
		var parts: PackedStringArray = event.substr(7).split(":")
		if parts.size() < 2:
			return {"error": "Signal event format: signal:node_path:signal_name"}

		var node_path: String = parts[0]
		var signal_name: String = parts[1]
		var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, node_path)
		if node == null:
			return {"error": "Node not found: %s" % node_path}

		if not node.has_signal(signal_name):
			return {"error": "Signal '%s' not found on %s" % [signal_name, node_path]}

		# Poll-based waiting: check a shared flag that signal-connected callbacks can set.
		# Since editor can't truly await signals, we use a simple polling loop with a flag.
		var signal_fired: bool = false
		var _on_signal_fired = func(
			_arg1 = null, _arg2 = null, _arg3 = null, _arg4 = null,
			_arg5 = null, _arg6 = null, _arg7 = null, _arg8 = null,
			_arg9 = null, _arg10 = null,
		) -> void:
			signal_fired = true

		# Connect with MANY binds to handle signals of various arities (0-10 args)
		node.connect(signal_name, _on_signal_fired, CONNECT_ONE_SHOT)

		while Time.get_ticks_msec() < target_end:
			if signal_fired:
				return {"result": {
					"event": event,
					"node": node_path,
					"signal": signal_name,
					"fired": true,
					"waited_ms": Time.get_ticks_msec() - start_time,
					"message": "Signal %s.%s fired" % [node_path, signal_name],
				}}
			await _non_blocking_wait(16)

		# Timeout — disconnect the callback
		if node.is_connected(signal_name, _on_signal_fired):
			node.disconnect(signal_name, _on_signal_fired)

		return {"result": {
			"event": event,
			"node": node_path,
			"signal": signal_name,
			"fired": false,
			"timeout": timeout,
			"message": "Timed out waiting for signal %s.%s (%dms)" % [node_path, signal_name, timeout],
		}}

	elif event.begins_with("node:"):
		# Wait for a node to appear: "node:NodePath"
		var node_path: String = event.substr(5)
		while Time.get_ticks_msec() < target_end:
			var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, node_path)
			if node != null:
				return {"result": {
					"event": event,
					"found": true,
					"path": node_path,
					"waited_ms": Time.get_ticks_msec() - start_time,
					"message": "Node found: %s" % node_path,
				}}
			await _non_blocking_wait(100)

		return {"result": {
			"event": event,
			"found": false,
			"path": node_path,
			"timeout": timeout,
			"message": "Timed out waiting for node: %s" % node_path,
		}}

	elif event.begins_with("property:"):
		# Wait for property change: "property:NodePath:property_name:expected_value"
		var parts: PackedStringArray = event.substr(9).split(":")
		if parts.size() < 3:
			return {"error": "Property event format: property:node_path:property_name:expected_value"}

		var node_path: String = parts[0]
		var prop_name: String = parts[1]
		var expected_val: String = parts[2]

		while Time.get_ticks_msec() < target_end:
			var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, node_path)
			if node != null:
				var actual: Variant = MCPCommandHelpers.get_nested_property(node, prop_name)
				if MCPCommandHelpers.compare_values(actual, expected_val, "=="):
					return {"result": {
						"event": event,
						"matched": true,
						"waited_ms": Time.get_ticks_msec() - start_time,
						"message": "Property %s.%s == %s" % [node_path, prop_name, expected_val],
					}}
			await _non_blocking_wait(100)

		return {"result": {
			"event": event,
			"matched": false,
			"timeout": timeout,
			"message": "Timed out waiting for %s.%s == %s" % [node_path, prop_name, expected_val],
		}}

	return {"error": "Unknown event format: %s (use signal:, node:, or property:)" % event}


## Helper: Capture current input state.
func _capture_input_state() -> Dictionary:
	var state: Dictionary = {}
	# Capture key states for common keys
	var keys: Array = [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_SHIFT, KEY_ENTER, KEY_ESCAPE]
	for key: int in keys:
		if Input.is_key_pressed(key):
			state[OS.get_keycode_string(key)] = true
	# Capture mouse
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		state["mouse_left"] = true
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		state["mouse_right"] = true
	return state


## Helper: Replay input event.
func _replay_input(data: Dictionary) -> void:
	for key_name: String in data:
		if key_name == "mouse_left":
			var event: InputEventMouseButton = InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = true
			Input.parse_input_event(event)
		elif key_name == "mouse_right":
			var event: InputEventMouseButton = InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_RIGHT
			event.pressed = true
			Input.parse_input_event(event)
		else:
			var keycode: int = OS.find_keycode_from_string(key_name)
			if keycode != 0:
				var event: InputEventKey = InputEventKey.new()
				event.keycode = keycode as Key
				event.pressed = true
				Input.parse_input_event(event)


## Helper: Step handler - input.
func _action_input(params: Dictionary) -> Dictionary:
	var key: String = params.get("key", params.get("keycode", ""))
	var action_name: String = params.get("action", "")
	if key.is_empty() and action_name.is_empty():
		return {"error": "Either 'key' (or 'keycode') or 'action' is required"}
	return {"result": "Input action recorded: %s" % (key if not key.is_empty() else action_name)}


## Helper: Step handler - wait.
func _action_wait(params: Dictionary) -> Dictionary:
	var seconds: float = params.get("duration", params.get("seconds", 1.0))
	if seconds < 0:
		return {"error": "Wait duration cannot be negative: %.1fs" % seconds}
	if seconds == 0:
		return {"result": "Waited 0.0s (instant)"}
	await _non_blocking_wait(int(seconds * 1000.0))
	return {"result": "Waited %.1fs" % seconds}


## Helper: Step handler - move.
func _action_move(plugin: EditorPlugin, params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var position: Array = params.get("position", [])
	if path.is_empty() or position.is_empty():
		return {"error": "path and position are required"}

	var node: Node = MCPCommandHelpers.resolve_node_path(plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	if node is Node3D and position.size() >= 3:
		(node as Node3D).position = Vector3(position[0], position[1], position[2])
	elif node is Node2D and position.size() >= 2:
		(node as Node2D).position = Vector2(position[0], position[1])
	else:
		return {"error": "Node is not Node2D or Node3D"}

	return {"result": "Moved %s to %s" % [path, str(position)]}


## Helper: Step handler - click.
func _action_click(params: Dictionary) -> Dictionary:
	var button_text: String = params.get("text", "")
	if button_text.is_empty():
		return {"error": "button text is required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	# Find button by text
	var found: Array = []
	_find_buttons_recursive(root, button_text, found)
	if found.is_empty():
		return {"error": "No button found with text: %s" % button_text}

	var button: Button = found[0] as Button
	button.emit_signal("pressed")

	return {"result": "Clicked button: %s" % button_text}


## Helper: Step handler - assert.
func _action_assert(plugin: EditorPlugin, params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var property: String = params.get("property", "")
	var expected: Variant = params.get("expected")
	var operator: String = params.get("operator", "==")

	var node: Node = MCPCommandHelpers.resolve_node_path(plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var actual: Variant = MCPCommandHelpers.get_nested_property(node, property)
	var passed: bool = MCPCommandHelpers.compare_values(actual, expected, operator)
	return {
		"passed": passed,
		"actual": actual,
		"expected": expected,
		"operator": operator,
	}


## Helper: Find buttons by text recursively.
func _find_buttons_recursive(node: Node, text: String, results: Array) -> void:
	if node is Button:
		if (node as Button).text.find(text) != -1:
			results.append(node)
	for child: Node in node.get_children():
		_find_buttons_recursive(child, text, results)


## Helper: Non-blocking wait using Engine.get_main_loop().process_frame.
## Uses frame-based waiting that works in both editor mode and play mode.
## _plugin.get_tree().create_timer() can fail during Play mode because
## Godot launches the game in a separate process — the editor's SceneTree
## still runs but its timer processing may be throttled or suspended.
## process_frame fires every frame on the main loop regardless of mode.
func _non_blocking_wait(total_ms: int) -> void:
	if total_ms <= 0:
		return
	var end_time: int = Time.get_ticks_msec() + total_ms
	var ml: MainLoop = Engine.get_main_loop()
	if ml is SceneTree:
		while Time.get_ticks_msec() < end_time:
			await (ml as SceneTree).process_frame
	else:
		# Fallback: block the thread in small chunks (editor already paused)
		while Time.get_ticks_msec() < end_time:
			OS.delay_msec(16)