## Input commands module - 8 tools.
## Handles keyboard, mouse, action simulation, and input mapping.
@tool
class_name MCPInputCommands
extends RefCounted

var _plugin: EditorPlugin

## Globalized runtime IPC request path (computed once in set_plugin).
var _runtime_request_path: String = ""


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin
	var user_base: String = ProjectSettings.globalize_path("user://")
	if not user_base.ends_with("/"):
		user_base += "/"
	_runtime_request_path = user_base + "mcp_runtime_request.json"


func get_commands() -> Dictionary:
	return {
		"input/simulate_key": simulate_key,
		"input/simulate_mouse_click": simulate_mouse_click,
		"input/simulate_mouse_move": simulate_mouse_move,
		"input/simulate_action": simulate_action,
		"input/simulate_sequence": simulate_sequence,
		"input/get_actions": get_input_actions,
		"input/set_action": set_input_action,
		"input/remove_action": remove_input_action,
	}


## Simulate a key press/release event.
func simulate_key(params: Dictionary) -> Dictionary:
	var key_str: String = params.get("keycode", params.get("key", ""))
	var pressed: bool = params.get("pressed", true)
	var echo: bool = params.get("echo", false)
	if key_str.is_empty():
		return {"error": "Key is required"}

	# Type check: keycode must be a string
	if not (key_str is String):
		return {"error": "Keycode must be a string, got %s" % typeof(key_str)}

	# Parse key name to keycode
	var keycode: int = _parse_keycode(key_str as String)
	if keycode == 0:
		return {"error": "Unknown key: %s" % key_str}

	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode as Key
	event.pressed = pressed
	event.echo = echo

	# Write to runtime IPC if game is running
	if _plugin.get_editor_interface().is_playing_scene():
		_write_runtime_command("simulate_input", {"type": "key", "keycode": keycode, "pressed": pressed, "echo": echo})
		return {"result": "Key event sent to game: %s (pressed=%s)" % [key_str, str(pressed)]}
	else:
		return {"result": "Key event created: %s (game not running, event not dispatched)" % key_str}


## Simulate a mouse click.
func simulate_mouse_click(params: Dictionary) -> Dictionary:
	var pos_raw: Variant = params.get("position", {})
	var button_raw: Variant = params.get("button", 1)
	var pressed: bool = params.get("pressed", true)

	# Convert string button names to int (MouseButton enum)
	var button: int = 1
	if button_raw is String:
		match button_raw as String:
			"left": button = 1
			"right": button = 2
			"middle": button = 3
			_: button = button_raw as int
	else:
		button = button_raw as int

	var pos: Vector2 = Vector2.ZERO
	if pos_raw is Array:
		var arr: Array = pos_raw as Array
		pos = Vector2(arr[0] as float, arr[1] as float) if arr.size() >= 2 else Vector2.ZERO
	elif pos_raw is Dictionary:
		var d: Dictionary = pos_raw as Dictionary
		pos = Vector2(d.get("x", 0.0) as float, d.get("y", 0.0) as float)

	if _plugin.get_editor_interface().is_playing_scene():
		_write_runtime_command("simulate_input", {
			"type": "mouse_click",
			"x": pos.x, "y": pos.y,
			"button": button,
			"pressed": pressed,
		})
		return {"result": "Mouse click sent to game at (%f, %f) button=%d" % [pos.x, pos.y, button]}
	return {"result": "Mouse click event created (game not running)"}


## Simulate mouse movement.
func simulate_mouse_move(params: Dictionary) -> Dictionary:
	var pos_raw: Variant = params.get("position", {})
	var rel_raw: Variant = params.get("relative", {})
	var is_relative: bool = params.get("is_relative", false)

	var pos: Vector2 = Vector2.ZERO
	if pos_raw is Array:
		var arr: Array = pos_raw as Array
		pos = Vector2(arr[0] as float, arr[1] as float) if arr.size() >= 2 else Vector2.ZERO
	elif pos_raw is Dictionary:
		var d: Dictionary = pos_raw as Dictionary
		pos = Vector2(d.get("x", 0.0) as float, d.get("y", 0.0) as float)

	var rel: Vector2 = Vector2.ZERO
	if rel_raw is Array:
		var arr2: Array = rel_raw as Array
		rel = Vector2(arr2[0] as float, arr2[1] as float) if arr2.size() >= 2 else Vector2.ZERO
	elif rel_raw is Dictionary:
		var d2: Dictionary = rel_raw as Dictionary
		rel = Vector2(d2.get("x", 0.0) as float, d2.get("y", 0.0) as float)
	elif rel_raw is bool and rel_raw:
		# If relative is boolean true, treat position as relative offset
		rel = pos
		is_relative = true

	if _plugin.get_editor_interface().is_playing_scene():
		_write_runtime_command("simulate_input", {
			"type": "mouse_move",
			"x": pos.x, "y": pos.y,
			"rel_x": rel.x, "rel_y": rel.y,
		})
		return {"result": "Mouse move sent to game"}
	return {"result": "Mouse move event created (game not running)"}


## Simulate an input action press/release.
func simulate_action(params: Dictionary) -> Dictionary:
	var action: String = params.get("action", "")
	var pressed: bool = params.get("pressed", true)
	if action.is_empty():
		return {"error": "Action name is required"}
	if not InputMap.has_action(action):
		return {"error": "Unknown input action: %s" % action}

	if _plugin.get_editor_interface().is_playing_scene():
		_write_runtime_command("simulate_input", {
			"type": "action",
			"action": action,
			"pressed": pressed,
		})
		return {"result": "Action '%s' sent to game (pressed=%s)" % [action, str(pressed)]}
	return {"result": "Action event created (game not running)"}


## Simulate a sequence of input events with frame delays.
func simulate_sequence(params: Dictionary) -> Dictionary:
	var steps: Array = params.get("events", params.get("steps", []))
	if steps.is_empty():
		return {"result": "Sequence of 0 steps (empty events array, no-op)"}

	if not _plugin.get_editor_interface().is_playing_scene():
		return {"result": "Sequence event created (game not running, sequence not dispatched)"}

	var commands: Array = []
	for step_variant: Variant in steps:
		var step: Dictionary = step_variant as Dictionary
		# Accept both delay_frames (frames) and delay (milliseconds)
		var delay_frames: int = step.get("delay_frames", step.get("delay", 1))
		# If delay is in milliseconds (from server), convert to frames (assume 60fps)
		if step.has("delay") and not step.has("delay_frames"):
			var delay_ms: int = step.get("delay", 1)
			delay_frames = max(1, delay_ms * 60 / 1000)
		commands.append({
			"type": step.get("type", ""),
			"delay_frames": delay_frames,
			"data": step,
		})
	_write_runtime_command("simulate_sequence", {"steps": commands})
	return {"result": "Sequence of %d steps sent to game" % steps.size()}


## Get all input actions defined in the InputMap.
## Returns ALL actions (built-in + custom) with their events and deadzones.
func get_input_actions(_params: Dictionary) -> Dictionary:
	var actions: Dictionary = {}
	for action_name: String in InputMap.get_actions():
		var events: Array = []
		for event: InputEvent in InputMap.action_get_events(action_name):
			events.append(MCPVariantCodec.serialize_input_event(event))
		actions[action_name] = {
			"deadzone": snapped(InputMap.action_get_deadzone(action_name), 0.0001),
			"events": events,
		}
	return {"result": {"actions": actions, "count": actions.size()}}


## Create or modify an input action.
## If the action exists, updates events in place (preserves running references).
## If it doesn't exist, creates a new action.
func set_input_action(params: Dictionary) -> Dictionary:
	var action: String = params.get("action", "")
	var events: Array = params.get("events", [])
	var deadzone: float = params.get("deadzone", 0.5)
	if action.is_empty():
		return {"error": "Action name is required"}

	if InputMap.has_action(action):
		# Update existing action in place — remove old events, add new ones
		# This preserves the action itself so references in running code remain valid
		# NOTE: .duplicate() is critical — action_get_events() returns a live
		# reference to the internal array, and action_erase_event() mutates it,
		# which would cause the iterator to skip events.
		var old_events: Array = InputMap.action_get_events(action).duplicate()
		for old_event: InputEvent in old_events:
			InputMap.action_erase_event(action, old_event)
		# Preserve existing deadzone if not explicitly provided
		if not params.has("deadzone"):
			deadzone = InputMap.action_get_deadzone(action)
		else:
			InputMap.action_set_deadzone(action, deadzone)
	else:
		InputMap.add_action(action, deadzone)

	for event_variant: Variant in events:
		var ev: Dictionary = event_variant as Dictionary
		var ev_type: String = ev.get("type", "")
		match ev_type:
			"key", "mouse_button", "joypad_button", "joypad_motion":
				var input_event: InputEvent = MCPVariantCodec.create_input_event(ev)
				if input_event:
					InputMap.action_add_event(action, input_event)

	# Save to project
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"error": "Failed to save project settings: %s" % error_string(err)}

	return {"result": "Input action '%s' set with %d events" % [action, events.size()]}


## Remove an input action from InputMap.
func remove_input_action(params: Dictionary) -> Dictionary:
	var action: String = params.get("action", "")
	if action.is_empty():
		return {"error": "Action name is required"}

	if not InputMap.has_action(action):
		return {"error": "Unknown input action: %s" % action}

	InputMap.erase_action(action)

	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"error": "Failed to save project settings: %s" % error_string(err)}

	return {"result": "Input action '%s' removed" % action}


## Write a command to the runtime IPC file using atomic write-then-rename
## to avoid partial-reads by the runtime autoload.
func _write_runtime_command(method: String, params: Dictionary) -> void:
	var data: Dictionary = {"method": method, "params": params}
	var json_text: String = JSON.stringify(data)
	var tmp_path: String = _runtime_request_path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file:
		file.store_string(json_text)
		file.close()
		DirAccess.rename_absolute(tmp_path, _runtime_request_path)


## Parse a key name to a keycode.
## Accepts: "Space", "KEY_SPACE", "32", "A"
func _parse_keycode(key_str: String) -> int:
	var upper: String = key_str.to_upper()
	# Strip KEY_ prefix if present (e.g., "KEY_SPACE" → "SPACE")
	if upper.begins_with("KEY_"):
		upper = upper.trim_prefix("KEY_")
	# Try numeric keycode
	if upper.is_valid_int():
		return upper.to_int()
	# Try direct name lookup
	var code: int = OS.find_keycode_from_string(upper)
	if code == 0 and "_" in upper:
		# Retry with spaces instead of underscores (for "KP_ENTER" → "Kp Enter")
		code = OS.find_keycode_from_string(upper.replace("_", " "))
	if code != 0:
		return code
	# Common aliases that OS.find_keycode_from_string may not resolve
	match upper:
		"SPACE":
			return KEY_SPACE
		"ENTER", "RETURN":
			return KEY_ENTER
		"ESCAPE", "ESC":
			return KEY_ESCAPE
		"TAB":
			return KEY_TAB
		"BACKSPACE":
			return KEY_BACKSPACE
		"DELETE", "DEL":
			return KEY_DELETE
		"UP":
			return KEY_UP
		"DOWN":
			return KEY_DOWN
		"LEFT":
			return KEY_LEFT
		"RIGHT":
			return KEY_RIGHT
		"SHIFT":
			return KEY_SHIFT
		"CTRL", "CONTROL":
			return KEY_CTRL
		"ALT":
			return KEY_ALT
		# Numpad keys (OS.find_keycode_from_string may not resolve on non-English locales)
		"KP_ENTER":
			return KEY_KP_ENTER
		"KP_ADD":
			return KEY_KP_ADD
		"KP_SUBTRACT":
			return KEY_KP_SUBTRACT
		"KP_MULTIPLY":
			return KEY_KP_MULTIPLY
		"KP_DIVIDE":
			return KEY_KP_DIVIDE
		"KP_PERIOD":
			return KEY_KP_PERIOD
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



