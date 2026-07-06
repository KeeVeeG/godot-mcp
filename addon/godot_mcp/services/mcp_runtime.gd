## Runtime autoload for game-side IPC.
## This script is auto-injected as an autoload when the game starts.
## Handles file-based IPC requests from the editor plugin.
class_name MCPRuntime
extends Node

## Polling interval in seconds
const POLL_INTERVAL: float = 0.1

## Poll timer accumulator
var _poll_timer: float = 0.0

## Request/response file paths
const REQUEST_PATH: String = "user://mcp_runtime_request.json"
const RESPONSE_PATH: String = "user://mcp_runtime_response.json"

## Signal watchers: {node_path: {signal_name: [events]}}
var _signal_watchers: Dictionary = {}

## Connected watcher callables: {node_path: {signal_name: callable}} for cleanup
var _signal_watcher_callables: Dictionary = {}

## Active signal watcher cleanup timers — stored so they can be cancelled on exit
var _signal_watcher_timers: Array[SceneTreeTimer] = []

## Input recording state
var _recording: bool = false
var _recorded_events: Array = []
var _record_start_time: float = 0.0

## Replay state
var _replaying: bool = false

## Property monitors: {monitor_id: {path, props, data, start_time, duration}}
var _monitors: Dictionary = {}
var _next_monitor_id: int = 1

## IPC busy flag — prevents reentrant _poll_ipc calls during await
var _ipc_busy: bool = false


func _ready() -> void:
	print("[MCP Runtime] Loaded and ready for IPC")


func _exit_tree() -> void:
	# Cancel all pending signal watcher cleanup timers to avoid freed-memory access
	_signal_watcher_timers.clear()
	# Disconnect all tracked callables immediately
	for path: String in _signal_watcher_callables:
		if _signal_watcher_callables.has(path):
			for sig_name: String in _signal_watcher_callables[path]:
				var entry: Dictionary = _signal_watcher_callables[path][sig_name]
				var n: Node = entry["node"] as Node
				var c: Callable = entry["callable"] as Callable
				if is_instance_valid(n) and n.has_signal(sig_name) and n.is_connected(sig_name, c):
					n.disconnect(sig_name, c)
	_signal_watcher_callables.clear()
	_signal_watchers.clear()


func _process(delta: float) -> void:
	_poll_timer += delta
	if _poll_timer >= POLL_INTERVAL:
		_poll_timer = 0.0
		_poll_ipc()

	# Update monitors
	_update_monitors(delta)

	# Record input events if recording
	if _recording:
		_record_input_frame(delta)


## Poll for IPC requests from the editor.
func _poll_ipc() -> void:
	# Guard: prevent reentrant calls while awaiting a previous request
	if _ipc_busy:
		return
	if not FileAccess.file_exists(REQUEST_PATH):
		return
	var file := FileAccess.open(REQUEST_PATH, FileAccess.READ)
	if file == null:
		return
	var json_text: String = file.get_as_text()
	file.close()

	# Delete the request file
	DirAccess.remove_absolute(REQUEST_PATH)

	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		_write_response({"error": "Failed to parse request JSON"})
		return

	var request: Variant = json.data
	if not request is Dictionary:
		_write_response({"error": "Request must be a JSON object"})
		return

	var req_dict: Dictionary = request as Dictionary
	var method: String = req_dict.get("method", "")
	var params: Dictionary = req_dict.get("params", {})
	var request_id: String = req_dict.get("request_id", "")

	_ipc_busy = true
	var result: Dictionary = await _handle_request(method, params)
	_ipc_busy = false

	# Echo request_id back for correlation
	if not request_id.is_empty():
		result["request_id"] = request_id

	if not _write_response(result):
		push_warning("[MCP Runtime] Failed to write response for method: %s" % method)


## Handle a runtime request.
func _handle_request(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_game_scene_tree":
			return _get_game_scene_tree()
		"get_game_node_properties":
			return _get_game_node_properties(params.get("path", ""), params.get("properties", []))
		"set_game_node_property":
			return _set_game_node_property(params.get("path", ""), params.get("property", ""), params.get("value"))
		"execute_game_script":
			return _execute_game_script(params.get("code", ""))
		"capture_frames":
			return await _capture_frames(params.get("count", 1), params.get("interval", 0.1))
		"monitor_properties":
			return _monitor_properties(params.get("path", ""), params.get("properties", []), params.get("duration", 5.0))
		"start_recording":
			return _start_recording()
		"stop_recording":
			return _stop_recording()
		"replay_recording":
			return _replay_recording(params.get("speed", 1.0))
		"find_nodes_by_script":
			return _find_nodes_by_script(params.get("script_path", ""))
		"get_autoload":
			return _get_autoload(params.get("name", ""))
		"batch_get_properties":
			return _batch_get_properties(params.get("paths", []), params.get("properties", []))
		"find_ui_elements":
			return _find_ui_elements(params.get("filter", {}))
		"click_button_by_text":
			return await _click_button_by_text(params.get("text", ""), params.get("timeout", 5.0))
		"wait_for_node":
			return await _wait_for_node(params.get("path", ""), params.get("timeout", 5.0))
		"find_nearby_nodes":
			return _find_nearby_nodes(params.get("position", {}), params.get("radius", 100.0))
		"navigate_to":
			return _navigate_to(params.get("path", ""), params.get("target", ""))
		"move_to":
			return _move_to(params.get("path", ""), params.get("target", {}))
		"watch_signals":
			return _watch_signals(params.get("path", ""), params.get("signals", []), params.get("duration", 5.0))
		"simulate_input":
			return _simulate_input(params)
		"simulate_sequence":
			return await _simulate_sequence(params)
		"get_monitor_results":
			return _get_monitor_results(params.get("monitor_id", 0))
		"capture_screenshot":
			return _capture_screenshot(params.get("path", "user://mcp_game_screenshot.png"))
		"ping":
			return {"result": "pong"}
		_:
			return {"error": "Unknown runtime method: %s" % method}


## Write a response to the IPC file using atomic write-then-rename.
## Returns true on success.
func _write_response(data: Dictionary) -> bool:
	var json_text: String = JSON.stringify(data)
	var tmp_path: String = RESPONSE_PATH + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_warning("[MCP Runtime] Failed to write response file")
		return false
	file.store_string(json_text)
	file.close()
	# Atomic rename: the editor will only see complete files
	DirAccess.rename_absolute(tmp_path, RESPONSE_PATH)
	return true


## Serialize a node tree recursively.
func _serialize_node(node: Node, depth: int = 0, max_depth: int = 10, max_nodes: int = 500, node_count: Array = []) -> Dictionary:
	if node_count.size() > 0 and node_count[0] >= max_nodes:
		return {"name": node.name, "type": node.get_class(), "path": str(node.get_path()), "children": [], "truncated": true}
	if node_count.size() == 0:
		node_count.append(0)
	node_count[0] += 1

	var result: Dictionary = {
		"name": node.name,
		"type": node.get_class(),
		"path": str(node.get_path()),
		"children": [],
	}
	if node is Node2D:
		var n2d: Node2D = node as Node2D
		result["position"] = {"x": n2d.position.x, "y": n2d.position.y}
		result["visible"] = n2d.visible
	elif node is Node3D:
		var n3d: Node3D = node as Node3D
		var pos: Vector3 = n3d.position
		result["position"] = {"x": pos.x, "y": pos.y, "z": pos.z}
		result["visible"] = n3d.visible
	elif node is Control:
		var ctrl: Control = node as Control
		result["position"] = {"x": ctrl.position.x, "y": ctrl.position.y}
		result["size"] = {"x": ctrl.size.x, "y": ctrl.size.y}
		result["visible"] = ctrl.visible

	if depth < max_depth:
		for child: Node in node.get_children():
			if node_count[0] >= max_nodes:
				break
			result["children"].append(_serialize_node(child, depth + 1, max_depth, max_nodes, node_count))
	return result


## Get the game scene tree.
func _get_game_scene_tree() -> Dictionary:
	var root: Node = get_tree().current_scene
	if root == null:
		root = get_tree().root
	return {"result": _serialize_node(root)}


## Get properties of a game node.
func _get_game_node_properties(path: String, filter_props: Array = []) -> Dictionary:
	var node: Node = get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	var props: Dictionary = {}
	if filter_props.size() > 0:
		# Only return requested properties
		for prop_name: String in filter_props:
			if node.get(prop_name) != null or prop_name in ["position", "visible", "name", "type"]:
				props[prop_name] = MCPVariantCodec.serialize_value(node.get(prop_name))
	else:
		# Return common properties only (not ALL 300+ properties)
		var common_props: PackedStringArray = [
			"name", "position", "rotation", "scale", "visible", "modulate",
			"z_index", "process_mode", "global_position", "global_rotation",
		]
		for prop_name: String in common_props:
			if prop_name in node:
				props[prop_name] = MCPVariantCodec.serialize_value(node.get(prop_name))
	return {"result": props}


## Set a property on a game node.
func _set_game_node_property(path: String, property: String, value: Variant) -> Dictionary:
	var node: Node = get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	var prop_list: Array = node.get_property_list()
	for p: Dictionary in prop_list:
		if p["name"] as String == property:
			var parsed: Variant = MCPVariantCodec.parse_for_property(value, p["type"] as int)
			node.set(property, parsed)
			return {"result": "Property %s set successfully" % property}
	node.set(property, value)
	return {"result": "Property %s set (untyped)" % property}


## Execute GDScript code in game context.
func _execute_game_script(code: String) -> Dictionary:
	var source: String = "extends Node\n\nfunc _run(root: Node, scene: Node) -> Variant:\n"
	var lines: PackedStringArray = code.split("\n")
	for line: String in lines:
		source += "    " + line + "\n"

	# Write to temp file — GDScript compilation via ResourceLoader is reliable
	var temp_path: String = "user://_mcp_temp_script.gd"
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return {"error": "Failed to write temp script file"}
	file.store_string(source)
	file.close()

	var script: GDScript = ResourceLoader.load(temp_path) as GDScript
	if script == null:
		DirAccess.remove_absolute(temp_path)
		return {"error": "Script compilation failed: ResourceLoader.load returned null"}

	var temp_node: Node = Node.new()
	temp_node.set_script(script)
	add_child(temp_node)

	# Check that the compiled script exposes _run before calling
	if not temp_node.has_method("_run"):
		temp_node.queue_free()
		DirAccess.remove_absolute(temp_path)
		return {"error": "Script compiled but does not define a _run(root, scene) method"}

	var result: Variant = temp_node.call("_run", get_tree().root, get_tree().current_scene)
	temp_node.queue_free()

	# Clean up temp file
	DirAccess.remove_absolute(temp_path)

	if result == null:
		return {"result": null}
	return {"result": MCPVariantCodec.serialize_value(result)}


## Capture multiple frames as screenshots.
func _capture_frames(count: int, interval: float) -> Dictionary:
	var frames: Array = []
	for i: int in range(count):
		# Capture frame synchronously
		var image: Image = get_tree().root.get_texture().get_image()
		var path: String = "user://mcp_frame_%d_%d.png" % [Time.get_ticks_msec(), i]
		image.save_png(path)
		frames.append(path)
		if i < count - 1 and interval > 0.0:
			await get_tree().create_timer(interval).timeout
	return {"result": {"frames": frames, "count": frames.size()}}


## Capture a single screenshot from the game viewport.
func _capture_screenshot(path: String) -> Dictionary:
	var image: Image = get_tree().root.get_texture().get_image()
	if image == null:
		return {"result": {"success": false, "error": "Failed to capture viewport"}}
	image.save_png(path)
	return {"result": {"success": true, "path": path, "width": image.get_width(), "height": image.get_height()}}


## Start monitoring properties over time.
func _monitor_properties(path: String, props: Array, duration: float) -> Dictionary:
	var monitor_id: int = _next_monitor_id
	_next_monitor_id += 1
	_monitors[monitor_id] = {
		"path": path,
		"props": props,
		"data": [],
		"start_time": Time.get_unix_time_from_system(),
		"duration": duration,
	}
	return {"result": {"monitor_id": monitor_id, "message": "Monitoring started for %.1f seconds" % duration}}


## Update active monitors.
func _update_monitors(_delta: float) -> void:
	var now: float = Time.get_unix_time_from_system()
	var completed: Array = []
	for monitor_id: int in _monitors:
		var monitor: Dictionary = _monitors[monitor_id]
		var elapsed: float = now - monitor["start_time"] as float
		if elapsed >= monitor["duration"] as float:
			completed.append(monitor_id)
			continue
		var node: Node = get_node_or_null(monitor["path"] as String)
		if node == null:
			continue
		var entry: Dictionary = {"time": elapsed}
		for prop: Variant in monitor["props"] as Array:
			var prop_name: String = prop as String
			entry[prop_name] = MCPVariantCodec.serialize_value(node.get(prop_name))
		(monitor["data"] as Array).append(entry)

	for monitor_id: int in completed:
		# Mark as completed — results retrievable via get_monitor_results
		_monitors[monitor_id]["completed"] = true
		_monitors[monitor_id]["completion_time"] = now

	# Auto-cleanup completed monitors after 60 seconds
	var stale: Array = []
	for monitor_id: int in _monitors:
		var m: Dictionary = _monitors[monitor_id]
		if m.get("completed", false):
			var since_complete: float = now - (m.get("completion_time", now) as float)
			if since_complete > 60.0:
				stale.append(monitor_id)
	for monitor_id: int in stale:
		_monitors.erase(monitor_id)


## Get results for a completed monitor.
func _get_monitor_results(monitor_id: int) -> Dictionary:
	if not _monitors.has(monitor_id):
		return {"error": "Monitor not found: %d" % monitor_id}
	var monitor: Dictionary = _monitors[monitor_id]
	return {"result": {
		"monitor_id": monitor_id,
		"path": monitor["path"],
		"properties": monitor["props"],
		"data": monitor["data"],
		"sample_count": (monitor["data"] as Array).size(),
		"completed": monitor.get("completed", false),
	}}


## Start recording input events.
func _start_recording() -> Dictionary:
	_recording = true
	_recorded_events.clear()
	_record_start_time = Time.get_unix_time_from_system()
	return {"result": "Recording started"}


## Stop recording input events.
func _stop_recording() -> Dictionary:
	_recording = false
	return {"result": {"events": _recorded_events, "count": _recorded_events.size()}}


## Record input events for the current frame.
func _record_input_frame(_delta: float) -> void:
	var frame_events: Dictionary = {"time": Time.get_unix_time_from_system() - _record_start_time}
	var keys: Array = []
	for keycode in range(KEY_SPACE, KEY_Z + 1):
		if Input.is_key_pressed(keycode):
			keys.append(OS.get_keycode_string(keycode))
	if keys.size() > 0:
		frame_events["keys"] = keys
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	frame_events["mouse"] = {"x": mouse_pos.x, "y": mouse_pos.y}
	if keys.size() > 0 or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			frame_events["mouse_button"] = "left"
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			frame_events["mouse_button"] = "right"
		_recorded_events.append(frame_events)


## Replay recorded input events.
func _replay_recording(speed: float = 1.0) -> Dictionary:
	if _recorded_events.is_empty():
		return {"error": "No recorded events to replay"}
	_replaying = true
	var events: Array = _recorded_events.duplicate()
	# Start replay in a coroutine
	_do_replay(events, speed)
	return {"result": "Replaying %d events at %.1fx speed" % [events.size(), speed]}


func _do_replay(events: Array, speed: float = 1.0) -> void:
	var prev_time: float = 0.0
	for event: Variant in events:
		var ev: Dictionary = event as Dictionary
		var ev_time: float = ev.get("time", 0.0) as float
		var wait_time: float = (ev_time - prev_time) * (1.0 / speed)
		if wait_time > 0:
			await get_tree().create_timer(wait_time).timeout
		prev_time = ev_time
		# Simulate key events
		if ev.has("keys"):
			for key_str: Variant in ev["keys"] as Array:
				var key_name: String = key_str as String
				var keycode: int = OS.find_keycode_from_string(key_name)
				if keycode != 0:
					var press_ev: InputEventKey = InputEventKey.new()
					press_ev.keycode = keycode as Key
					press_ev.pressed = true
					Input.parse_input_event(press_ev)
		# Simulate mouse
		if ev.has("mouse"):
			var mouse_data: Dictionary = ev["mouse"] as Dictionary
			var move_ev: InputEventMouseMotion = InputEventMouseMotion.new()
			move_ev.position = Vector2(mouse_data["x"] as float, mouse_data["y"] as float)
			Input.parse_input_event(move_ev)
	_replaying = false


## Find nodes that use a specific script.
func _find_nodes_by_script(script_path: String) -> Dictionary:
	var found: Array = []
	var script_res: Resource = load(script_path)
	if script_res == null:
		return {"error": "Script not found: %s" % script_path}
	_find_nodes_recursive(get_tree().root, script_res, found)
	return {"result": found}


func _find_nodes_recursive(node: Node, script_res: Resource, found: Array) -> void:
	if node.get_script() == script_res:
		found.append(str(node.get_path()))
	for child: Node in node.get_children():
		_find_nodes_recursive(child, script_res, found)


## Get autoload node info.
func _get_autoload(name: String) -> Dictionary:
	var node: Node = get_node_or_null("/root/" + name)
	if node == null:
		# Try case-insensitive search among autoloads
		for child: Node in get_tree().root.get_children():
			if child.name.to_lower() == name.to_lower():
				node = child
				break
	if node == null:
		return {"error": "Autoload not found: %s" % name}
	var props: Dictionary = {}
	for p: Dictionary in node.get_property_list():
		var pname: String = p["name"] as String
		if not pname.begins_with("_"):
			props[pname] = MCPVariantCodec.serialize_value(node.get(pname))
	return {"result": {"name": name, "path": str(node.get_path()), "type": node.get_class(), "properties": props}}


## Batch get properties from multiple nodes.
func _batch_get_properties(paths: Array, properties: Array) -> Dictionary:
	var results: Dictionary = {}
	for path_variant: Variant in paths:
		var path_str: String = path_variant as String
		var node: Node = get_node_or_null(path_str)
		if node == null:
			results[path_str] = {"error": "Node not found"}
			continue
		var node_props: Dictionary = {}
		for prop_variant: Variant in properties:
			var prop_name: String = prop_variant as String
			node_props[prop_name] = MCPVariantCodec.serialize_value(node.get(prop_name))
		results[path_str] = node_props
	return {"result": results}


## Find UI elements matching a filter.
func _find_ui_elements(filter: Dictionary) -> Dictionary:
	var found: Array = []
	_find_ui_recursive(get_tree().root, filter, found)
	return {"result": found}


func _find_ui_recursive(node: Node, filter: Dictionary, found: Array) -> void:
	if node is Control:
		var ctrl: Control = node as Control
		var match_type: bool = true
		if filter.has("type"):
			match_type = ctrl.is_class(filter["type"] as String)
		var match_text: bool = true
		if filter.has("text"):
			if ctrl is Button:
				match_text = (ctrl as Button).text.find(filter["text"] as String) != -1
			elif ctrl is Label:
				match_text = (ctrl as Label).text.find(filter["text"] as String) != -1
		if match_type and match_text:
			found.append({
				"path": str(ctrl.get_path()),
				"type": ctrl.get_class(),
				"text": _get_node_text(ctrl),
				"visible": ctrl.visible,
				"position": {"x": ctrl.global_position.x, "y": ctrl.global_position.y},
			})
	for child: Node in node.get_children():
		_find_ui_recursive(child, filter, found)


func _get_node_text(node: Node) -> String:
	if node is Button:
		return (node as Button).text
	elif node is Label:
		return (node as Label).text
	elif node is LineEdit:
		return (node as LineEdit).text
	elif node is TextEdit:
		return (node as TextEdit).text
	return ""


## Click a button by its text content.
func _click_button_by_text(text: String, timeout: float) -> Dictionary:
	var start_time: float = Time.get_unix_time_from_system()
	while true:
		var buttons: Array = []
		_find_buttons_recursive(get_tree().root, text, buttons)
		if not buttons.is_empty():
			var btn: Button = buttons[0] as Button
			# Simulate realistic button press sequence
			btn.emit_signal("button_down")
			btn.emit_signal("pressed")
			btn.emit_signal("button_up")
			return {"result": "Clicked button '%s' at %s" % [text, str(btn.get_path())]}
		if Time.get_unix_time_from_system() - start_time >= timeout:
			return {"error": "No button found with text: %s (timed out after %.1f seconds)" % [text, timeout]}
		await get_tree().process_frame
	return {"error": "No button found with text: %s" % text}


func _find_buttons_recursive(node: Node, text: String, found: Array) -> void:
	if node is Button:
		var btn: Button = node as Button
		if btn.text.find(text) != -1 and btn.visible:
			found.append(btn)
	for child: Node in node.get_children():
		_find_buttons_recursive(child, text, found)


## Wait for a node to appear.
func _wait_for_node(path: String, timeout: float) -> Dictionary:
	var start_time: float = Time.get_unix_time_from_system()
	while true:
		var node: Node = get_node_or_null(path)
		if node != null:
			var elapsed: float = Time.get_unix_time_from_system() - start_time
			return {"result": {"found": true, "path": path, "time": elapsed}}
		if Time.get_unix_time_from_system() - start_time >= timeout:
			return {"result": {"found": false, "path": path, "timeout": true, "message": "Timed out after %.1f seconds" % timeout}}
		await get_tree().process_frame
	return {"error": "Node not found: %s" % path}


## Find nodes near a position.
## NOTE: 2D positions are converted to Vector3 (z=0) for uniform distance calculation.
## Both 2D and 3D nodes are included in results with distances in 3D space.
func _find_nearby_nodes(pos: Variant, radius: float) -> Dictionary:
	var center: Vector3
	if pos is Array:
		center = Vector3(pos[0] if pos.size() > 0 else 0.0, pos[1] if pos.size() > 1 else 0.0, pos[2] if pos.size() > 2 else 0.0)
	elif pos is Dictionary:
		center = Vector3(pos.get("x", 0.0) as float, pos.get("y", 0.0) as float, pos.get("z", 0.0) as float)
	else:
		center = Vector3.ZERO
	var found: Array = []
	_find_nearby_recursive(get_tree().root, center, radius, found)
	return {"result": found}


func _find_nearby_recursive(node: Node, center: Vector3, radius: float, found: Array) -> void:
	if node is Node3D:
		var n3d: Node3D = node as Node3D
		var dist: float = n3d.global_position.distance_to(center)
		if dist <= radius:
			found.append({
				"path": str(n3d.get_path()),
				"name": str(n3d.name),
				"type": n3d.get_class(),
				"distance": dist,
			})
	elif node is Node2D:
		var n2d: Node2D = node as Node2D
		var pos_3d: Vector3 = Vector3(n2d.global_position.x, n2d.global_position.y, 0.0)
		var dist: float = pos_3d.distance_to(center)
		if dist <= radius:
			found.append({
				"path": str(n2d.get_path()),
				"name": str(n2d.name),
				"type": n2d.get_class(),
				"distance": dist,
			})
	for child: Node in node.get_children():
		_find_nearby_recursive(child, center, radius, found)


## Navigate a node to a target (for NavAgent-based nodes).
func _navigate_to(path: String, target: Variant) -> Dictionary:
	var node: Node = get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	# Convert target to Vector3
	var target_pos: Vector3 = Vector3.ZERO
	if target is Array:
		target_pos = Vector3(target[0] if target.size() > 0 else 0.0, target[1] if target.size() > 1 else 0.0, target[2] if target.size() > 2 else 0.0)
	elif target is String:
		var target_node: Node = get_node_or_null(target)
		if target_node == null:
			return {"error": "Target not found: %s" % target}
		if target_node is Node3D:
			target_pos = (target_node as Node3D).global_position
		elif target_node is Node2D:
			var n2d_pos: Vector2 = (target_node as Node2D).global_position
			target_pos = Vector3(n2d_pos.x, n2d_pos.y, 0.0)
		else:
			return {"error": "Target node is not a Node2D or Node3D: %s" % target}
	elif target is Dictionary:
		target_pos = Vector3(target.get("x", 0.0) as float, target.get("y", 0.0) as float, target.get("z", 0.0) as float)
	# Check for NavigationAgent
	if node.has_method("set_target_position"):
		node.set_target_position(target_pos)
		return {"result": "Navigation target set to (%f, %f, %f)" % [target_pos.x, target_pos.y, target_pos.z]}
	return {"error": "Node does not support navigation (no set_target_position method)"}


## Move a node to a position.
func _move_to(path: String, target: Variant) -> Dictionary:
	var node: Node = get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	if node is Node3D:
		var target_pos: Vector3
		if target is Array:
			target_pos = Vector3(target[0] if target.size() > 0 else 0.0, target[1] if target.size() > 1 else 0.0, target[2] if target.size() > 2 else 0.0)
		elif target is Dictionary:
			target_pos = Vector3(target.get("x", 0.0) as float, target.get("y", 0.0) as float, target.get("z", 0.0) as float)
		else:
			return {"error": "Invalid target format"}
		(node as Node3D).global_position = target_pos
		return {"result": "Moved %s to (%f, %f, %f)" % [path, target_pos.x, target_pos.y, target_pos.z]}
	elif node is Node2D:
		var target_pos: Vector2
		if target is Array:
			target_pos = Vector2(target[0] if target.size() > 0 else 0.0, target[1] if target.size() > 1 else 0.0)
		elif target is Dictionary:
			target_pos = Vector2(target.get("x", 0.0) as float, target.get("y", 0.0) as float)
		else:
			return {"error": "Invalid target format"}
		(node as Node2D).global_position = target_pos
		return {"result": "Moved %s to (%f, %f)" % [path, target_pos.x, target_pos.y]}
	return {"error": "Node is not a Node2D or Node3D"}


## Watch signals on a node.
func _watch_signals(path: String, signals: Array, duration: float) -> Dictionary:
	var node: Node = get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	if not _signal_watchers.has(path):
		_signal_watchers[path] = {}
	if not _signal_watcher_callables.has(path):
		_signal_watcher_callables[path] = {}
	for sig_variant: Variant in signals:
		var sig_name: String = sig_variant as String
		if not _signal_watchers[path].has(sig_name):
			_signal_watchers[path][sig_name] = []
		var callback: Callable = func(args: Array, sn: String = sig_name, np: String = path) -> void:
			if _signal_watchers.has(np) and _signal_watchers[np].has(sn):
				_signal_watchers[np][sn].append({
					"time": Time.get_unix_time_from_system(),
					"args": MCPVariantCodec.serialize_value(args),
				})
		if node.has_signal(sig_name):
			node.connect(sig_name, callback)
			_signal_watcher_callables[path][sig_name] = {"callable": callback, "node": node}
	# Schedule cleanup with stored timer ref so it can be cancelled in _exit_tree
	var timer: SceneTreeTimer = get_tree().create_timer(duration)
	_signal_watcher_timers.append(timer)
	timer.timeout.connect(func() -> void:
		_signal_watcher_timers.erase(timer)
		if not is_instance_valid(self):
			return
		# Disconnect all tracked callables before erasing watcher data
		if _signal_watcher_callables.has(path):
			for sig_name: String in _signal_watcher_callables[path]:
				var entry: Dictionary = _signal_watcher_callables[path][sig_name]
				var n: Node = entry["node"] as Node
				var c: Callable = entry["callable"] as Callable
				if is_instance_valid(n) and n.has_signal(sig_name) and n.is_connected(sig_name, c):
					n.disconnect(sig_name, c)
			_signal_watcher_callables.erase(path)
		_signal_watchers.erase(path)
	)
	return {"result": "Watching signals %s on %s for %.1f seconds" % [str(signals), path, duration]}


## Simulate a single input event (key, mouse, or action) in the running game.
func _simulate_input(params: Dictionary) -> Dictionary:
	var input_type: String = params.get("type", "")
	
	match input_type:
		"key":
			return _simulate_key_event(params)
		"mouse_click":
			return _simulate_mouse_click(params)
		"mouse_move":
			return _simulate_mouse_move(params)
		"action":
			return _simulate_action_event(params)
		_:
			return {"error": "Unknown input type: %s" % input_type}


## Simulate a keyboard key press/release.
func _simulate_key_event(params: Dictionary) -> Dictionary:
	var keycode_str: String = params.get("keycode", "")
	if keycode_str.is_empty():
		return {"error": "Keycode is required"}
	
	var keycode: Key = OS.find_keycode_from_string(keycode_str)
	if keycode == KEY_NONE and keycode_str != "None":
		# Try common aliases
		match keycode_str.to_lower():
			"enter", "return": keycode = KEY_ENTER
			"space": keycode = KEY_SPACE
			"escape", "esc": keycode = KEY_ESCAPE
			"tab": keycode = KEY_TAB
			"backspace": keycode = KEY_BACKSPACE
			"delete", "del": keycode = KEY_DELETE
			"up": keycode = KEY_UP
			"down": keycode = KEY_DOWN
			"left": keycode = KEY_LEFT
			"right": keycode = KEY_RIGHT
			"shift": keycode = KEY_SHIFT
			"ctrl", "control": keycode = KEY_CTRL
			"alt": keycode = KEY_ALT
			_: return {"error": "Unknown key: %s" % keycode_str}
	
	var pressed: bool = params.get("pressed", true)
	var echo: bool = params.get("echo", false)
	
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)
	
	return {"result": "%s key %s" % ["Pressed" if pressed else "Released", keycode_str]}


## Simulate a mouse click.
func _simulate_mouse_click(params: Dictionary) -> Dictionary:
	var pos_array = params.get("position")
	var pos: Vector2
	if pos_array is Array and pos_array.size() >= 2:
		pos = Vector2(float(pos_array[0]), float(pos_array[1]))
	else:
		pos = Vector2.ZERO
	
	var button = params.get("button", MOUSE_BUTTON_LEFT)
	if button is String:
		match (button as String).to_lower():
			"left": button = MOUSE_BUTTON_LEFT
			"right": button = MOUSE_BUTTON_RIGHT
			"middle": button = MOUSE_BUTTON_MIDDLE
			_: button = MOUSE_BUTTON_LEFT
	
	var pressed: bool = params.get("pressed", true)
	
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = pos
	Input.parse_input_event(event)
	
	return {"result": "Mouse %s at (%.1f, %.1f)" % ["clicked" if pressed else "released", pos.x, pos.y]}


## Simulate mouse movement.
func _simulate_mouse_move(params: Dictionary) -> Dictionary:
	var pos_array = params.get("position")
	var pos: Vector2
	if pos_array is Array and pos_array.size() >= 2:
		pos = Vector2(float(pos_array[0]), float(pos_array[1]))
	else:
		return {"error": "Position is required for mouse move"}
	
	var is_relative: bool = params.get("is_relative", false)
	
	var event := InputEventMouseMotion.new()
	if is_relative:
		event.relative = pos
	else:
		event.position = pos
	Input.parse_input_event(event)
	
	return {"result": "Mouse moved to (%.1f, %.1f)" % [pos.x, pos.y]}


## Simulate an input action.
func _simulate_action_event(params: Dictionary) -> Dictionary:
	var action: String = params.get("action", "")
	if action.is_empty():
		return {"error": "Action name is required"}
	
	if not InputMap.has_action(action):
		return {"error": "Action '%s' not found in InputMap" % action}
	
	var pressed: bool = params.get("pressed", true)
	
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
	
	return {"result": "Action '%s' %s" % [action, "pressed" if pressed else "released"]}


## Simulate a sequence of input events with timing.
func _simulate_sequence(params: Dictionary) -> Dictionary:
	var events: Array = params.get("events", [])
	if events.is_empty():
		return {"error": "Events array is required"}
	
	for evt_dict in events:
		if not evt_dict is Dictionary:
			continue
		
		var evt_type: String = evt_dict.get("type", "")
		var evt_params: Dictionary = evt_dict.duplicate()
		evt_params["type"] = evt_type
		_simulate_input(evt_params)
		
		var delay_sec: float = float(evt_dict.get("delay", 0.0))
		if delay_sec > 0.0:
			await get_tree().create_timer(delay_sec).timeout
	
	return {"result": "Replayed %d input events" % events.size()}
