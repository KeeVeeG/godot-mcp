## Runtime autoload for game-side IPC.
## This script is auto-injected as an autoload when the game starts.
## Handles file-based IPC requests from the editor plugin.
##
## NOTE: Do NOT add `class_name MCPRuntime` here — Godot forbids a class_name
## that matches an autoload singleton name in the same project.  The script
## is registered as an autoload via plugin.gd's _ensure_runtime_autoload().
extends Node

## Polling interval in seconds
const POLL_INTERVAL: float = 0.1

## Poll timer accumulator
var _poll_timer: float = 0.0

## IPC file paths — computed from ProjectSettings.globalize_path("user://") at runtime.
## NOT using raw `user://` constants to ensure the editor and game process resolve
## to the SAME absolute path (avoids divergence when application/config/name differs).
var _request_path: String = ""
var _response_path: String = ""

## Ready handshake file — written in _ready(), deleted in _exit_tree().
## The editor waits for this file before sending IPC requests,
## solving the race condition where is_playing_scene() returns true
## before the game process has finished initializing autoloads.
var _ready_path: String = ""

## Signal watchers: {node_path: {signal_name: [events]}}
var _signal_watchers: Dictionary = {}

## Connected watcher callables: {node_path: {signal_name: callable}} for cleanup
var _signal_watcher_callables: Dictionary = {}

## Generation counter per path — prevents old timer callbacks from
## erasing watcher data set up by a newer watch_signals call for the same path.
var _signal_watcher_gen: Dictionary = {}

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

## Timestamp when _ipc_busy was last set to true (ms since engine start).
## Used for safety timeout — force-reset if stuck for IP_BUSY_TIMEOUT seconds.
var _ipc_busy_since: float = 0.0

## Diagnostic counter — logs the first N _poll_ipc() calls to confirm
## the game process is actually polling for IPC requests.
var _poll_log_remaining: int = 20

## Maximum time _ipc_busy can remain true before force-reset (seconds).
const IPC_BUSY_TIMEOUT: float = 10.0

## Runtime methods that require async (await) processing.
## These methods must span multiple frames (timers, frame polling, etc.).
## All other methods are synchronous and handled without await.
const ASYNC_METHODS: Array[String] = [
	"capture_frames",
	"simulate_sequence",
	"click_button_by_text",
	"wait_for_node",
	"monitor_properties",
	"watch_signals",
]


func _ready() -> void:
	# DIAGNOSTIC: print immediately to confirm this autoload was instantiated.
	# If this message does NOT appear in the game output log, the autoload
	# was never loaded — check "Failed to instantiate an autoload" errors
	# and verify application/run/main_scene is set in Project Settings.
	print("[MCP Runtime] _ready() ENTERED — autoload instantiated successfully")
	
	# Resolve user:// to an absolute OS path so both editor and game process
	# agree on the IPC file locations (avoids project-name divergence).
	var base_dir: String = ProjectSettings.globalize_path("user://")
	if not base_dir.is_empty() and not base_dir.ends_with("/"):
		base_dir += "/"
	_request_path = base_dir + "mcp_runtime_request.json"
	_response_path = base_dir + "mcp_runtime_response.json"
	_ready_path = base_dir + "mcp_runtime_ready"

	print("[MCP Runtime] Loaded and ready for IPC")
	print("[MCP Runtime] IPC base dir: %s" % base_dir)
	print("[MCP Runtime] Request path: %s" % _request_path)
	print("[MCP Runtime] Response path: %s" % _response_path)
	print("[MCP Runtime] Ready file: %s" % _ready_path)

	# Signal to the editor that the runtime is ready to receive requests.
	# The editor waits for this file before sending IPC requests to avoid
	# timing out while the game process is still initializing.
	var ready_file := FileAccess.open(_ready_path, FileAccess.WRITE)
	if ready_file:
		ready_file.store_string(str(Time.get_unix_time_from_system()))
		ready_file.close()
		print("[MCP Runtime] Handshake file written successfully")
	else:
		push_warning("[MCP Runtime] Failed to write ready handshake file to: %s (error: %d)" % [_ready_path, FileAccess.get_open_error()])




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
	_signal_watcher_gen.clear()
	# Clean up ready handshake file so the editor doesn't see a stale signal
	if FileAccess.file_exists(_ready_path):
		DirAccess.remove_absolute(_ready_path)


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
	# Safety: force-reset _ipc_busy if a previous async coroutine crashed
	# and left the flag stuck true. Without this, _poll_ipc() becomes
	# permanently blind — the game never processes another request.
	if _ipc_busy:
		var stuck_sec: float = (Time.get_ticks_msec() / 1000.0) - _ipc_busy_since
		if stuck_sec > IPC_BUSY_TIMEOUT:
			push_warning("[MCP Runtime] _ipc_busy stuck for %.1fs — force resetting" % stuck_sec)
			_ipc_busy = false
		else:
			return

	# Diagnostic: log the first N polls to confirm the game is polling.
	if _poll_log_remaining > 0:
		_poll_log_remaining -= 1
		print("[MCP Runtime] _poll_ipc() — path: %s, exists: %s" % [_request_path, FileAccess.file_exists(_request_path)])

	if _request_path.is_empty():
		return

	if not FileAccess.file_exists(_request_path):
		return

	var file := FileAccess.open(_request_path, FileAccess.READ)
	if file == null:
		push_warning("[MCP Runtime] _poll_ipc: exists()=true but open()=null for: %s" % _request_path)
		return
	var json_text: String = file.get_as_text()
	file.close()

	# Delete the request file
	DirAccess.remove_absolute(_request_path)

	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_warning("[MCP Runtime] _poll_ipc: JSON parse failed (text: %s)" % json_text.substr(0, 200))
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

	print("[MCP Runtime] _poll_ipc: dispatching '%s' (id: %s)" % [method, request_id])

	var result: Dictionary
	if method in ASYNC_METHODS:
		# Async methods: use await, protect with busy flag and safety timeout.
		_ipc_busy = true
		_ipc_busy_since = Time.get_ticks_msec() / 1000.0
		result = await _handle_async_request(method, params)
		_ipc_busy = false
	else:
		# Sync methods: call a handler that has ZERO `await` in its body.
		# In GDScript, any function with `await` in its source becomes a
		# coroutine.  Calling a coroutine without `await` returns a
		# GDScriptFunctionState, NOT the Dictionary — silently breaking IPC.
		result = _handle_sync_request(method, params)

	# Echo request_id back for correlation
	if not request_id.is_empty():
		result["request_id"] = request_id

	if not _write_response(result):
		push_warning("[MCP Runtime] _poll_ipc: _write_response FAILED for '%s'" % method)


## Handle a synchronous runtime request.
## CRITICAL: This function MUST NOT contain `await` anywhere — not even in
## unreachable branches.  In GDScript, the mere presence of `await` in the
## function body makes it a coroutine.  Calling a coroutine without `await`
## returns GDScriptFunctionState instead of the actual Dictionary, which
## causes the IPC response to never be written → 30 s timeout on the editor.
func _handle_sync_request(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_game_scene_tree":
			return _get_game_scene_tree(params.get("max_depth", 10), params.get("max_nodes", 500))
		"get_game_node_properties":
			return _get_game_node_properties(params.get("path", ""), params.get("properties", []))
		"set_game_node_property":
			return _set_game_node_property(params.get("path", ""), params.get("property", ""), params.get("value"))
		"execute_game_script":
			return _execute_game_script(params.get("code", ""))
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
		"find_nearby_nodes":
			return _find_nearby_nodes(params.get("position", {}), params.get("radius", 100.0))
		"navigate_to":
			return _navigate_to(params.get("path", ""), params.get("target", {}))
		"move_to":
			return _move_to(params.get("path", ""), params.get("target", {}))
		"unwatch_signals":
			return _unwatch_signals(params.get("path", ""), params.get("signals", []))
		"delete_captured_frames":
			return _delete_captured_frames(params.get("paths", []))
		"stop_monitoring":
			return _stop_monitoring(params.get("path", ""))
		"batch_set_properties":
			return _batch_set_properties(params.get("nodes", []))
		"simulate_input":
			return _simulate_input(params)
		"get_monitor_results":
			return _get_monitor_results(params.get("monitor_id", 0))
		"capture_screenshot":
			return _capture_screenshot(params.get("path", "user://mcp_game_screenshot.png"))
		"ping":
			return {"result": "pong"}
		_:
			return {"error": "Unknown runtime method: %s" % method}


## Handle an async runtime request.  May use await for multi-frame operations.
func _handle_async_request(method: String, params: Dictionary) -> Dictionary:
	match method:
		"capture_frames":
			return await _capture_frames(params.get("count", 1), params.get("interval", 0.1))
		"click_button_by_text":
			return await _click_button_by_text(params.get("text", ""), params.get("timeout", 5.0))
		"wait_for_node":
			return await _wait_for_node(params.get("path", ""), params.get("timeout", 5.0))
		"simulate_sequence":
			return await _simulate_sequence(params)
		"monitor_properties":
			return await _monitor_properties(params.get("path", ""), params.get("properties", []), params.get("duration", 5.0))
		"watch_signals":
			return await _watch_signals(params.get("path", ""), params.get("signals", []), params.get("duration", 5.0))
		_:
			return {"error": "Unknown async runtime method: %s" % method}


## Write a response to the IPC file using atomic write-then-rename.
## Returns true on success.
func _write_response(data: Dictionary) -> bool:
	var json_text: String = JSON.stringify(data)
	var tmp_path: String = _response_path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_warning("[MCP Runtime] Failed to write response to: %s (error: %d)" % [tmp_path, FileAccess.get_open_error()])
		return false
	file.store_string(json_text)
	file.close()
	# Atomic rename: the editor will only see complete files.
	var rename_err: Error = DirAccess.rename_absolute(tmp_path, _response_path)
	if rename_err != OK:
		push_warning("[MCP Runtime] Response rename failed: %s -> %s (%s)" % [tmp_path, _response_path, error_string(rename_err)])
		return false
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


## Resolve a node path that may be relative (e.g. "Player") to an absolute Node.
## Uses recursive search from current_scene → root when the direct lookup fails.
func _resolve_node(path: String) -> Node:
	# "." and "" both mean "current scene root" — prevent get_node_or_null(".")
	# from returning the MCPRuntime autoload (the caller's `self`) instead of
	# the actual scene tree root.
	if path == "." or path == "":
		var scene: Node = get_tree().current_scene
		if scene != null:
			return scene
		return get_tree().root

	var node: Node = get_node_or_null(path)
	if node != null:
		return node

	# Try as a relative path from current scene root
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root

	# Try with current scene prefix
	var scene_prefix: String = str(scene_root.get_path())
	if not scene_prefix.ends_with("/"):
		scene_prefix += "/"
	node = get_node_or_null(scene_prefix + path)
	if node != null:
		return node

	# Fallback: recursive name-based search from root
	return _find_node_by_name(get_tree().root, path)


## Recursive name-based node search (last resort for relative paths).
func _find_node_by_name(root_node: Node, target_path: String) -> Node:
	# Split path for hierarchical relative paths like "Player/Camera3D"
	var parts: PackedStringArray = target_path.split("/", false)
	if parts.size() == 0:
		return null

	# Direct name match (single-level path)
	if parts.size() == 1:
		var target_name: String = parts[0]
		for child: Node in root_node.get_children():
			if child.name == target_name:
				return child
			var found: Node = _find_node_by_name(child, target_name)
			if found != null:
				return found
		return null

	# Multi-level path: find first part, then descend
	var first_name: String = parts[0]
	var remaining: String = "/".join(PackedStringArray(parts.slice(1)))
	for child: Node in root_node.get_children():
		if child.name == first_name:
			var found: Node = _find_node_by_name(child, remaining)
			if found != null:
				return found
	return null


## Get the game scene tree.
func _get_game_scene_tree(max_depth: int = 10, max_nodes: int = 500) -> Dictionary:
	var root: Node = get_tree().current_scene
	if root == null:
		root = get_tree().root
	return {"result": _serialize_node(root, 0, max_depth, max_nodes, [])}


## Get properties of a game node.
func _get_game_node_properties(path: String, filter_props: Array = []) -> Dictionary:
	var node: Node = _resolve_node(path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	var props: Dictionary = {}
	if filter_props.size() > 0:
		# Only return requested properties
		for prop_name: String in filter_props:
			if prop_name == "type":
				props["type"] = node.get_class()
			elif node.get(prop_name) != null or prop_name in ["position", "visible", "name"]:
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
		# Always include type as the node class
		props["type"] = node.get_class()
	return {"result": props}


## Set a property on a game node.
func _set_game_node_property(path: String, property: String, value: Variant) -> Dictionary:
	var node: Node = _resolve_node(path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	var prop_list: Array = node.get_property_list()
	for p: Dictionary in prop_list:
		if p["name"] as String == property:
			# Reject read-only properties (usage flags include PROPERTY_USAGE_READ_ONLY)
			var usage: int = p.get("usage", 0) as int
			if usage & PROPERTY_USAGE_READ_ONLY:
				return {"error": "Property '%s' on %s is read-only" % [property, path]}
			var parsed: Variant = MCPVariantCodec.parse_for_property(value, p["type"] as int)
			node.set(property, parsed)
			return {"result": "Property %s set successfully" % property}
	return {"error": "Property '%s' does not exist on node '%s'" % [property, path]}


## Execute GDScript code in game context.
func _execute_game_script(code: String) -> Dictionary:
	var source: String
	var trimmed: String = code.strip_edges()

	# If user provides their own _run() function, use it directly.
	# Otherwise, wrap the code inside a _run() template.
	if trimmed.begins_with("func _run"):
		source = "extends Node\n\n" + code
	else:
		source = "extends Node\n\nfunc _run(root: Node, scene: Node):\n"
		var lines: PackedStringArray = code.split("\n")

		# Auto-wrap with return if the code does not contain its own return statement.
		# Single-line expressions like "2 + 2" need a "return " prefix; multi-line scripts
		# that already contain "return" are left as-is.
		if lines.size() == 1 and not code.contains("return") and not code.contains("var "):
			# Don't auto-prepend 'return' for void-returning functions (print, push_warning, etc.).
			# 'return print(...)' is a GDScript compile error because print() returns void.
			if trimmed.begins_with("print(") or trimmed.begins_with("push_warning(") or trimmed.begins_with("push_error(") or trimmed.begins_with("assert("):
				source += "    " + lines[0] + "\n"
			else:
				source += "    return " + lines[0] + "\n"
		else:
			for line: String in lines:
				source += "    " + line + "\n"

	# Use absolute path via globalize_path — ResourceLoader.load() does NOT
	# support user:// paths in the game process and can hang indefinitely.
	var base_dir: String = ProjectSettings.globalize_path("user://")
	if not base_dir.ends_with("/"):
		base_dir += "/"
	var temp_path: String = base_dir + "_mcp_temp_script.gd"

	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return {"error": "Failed to write temp script file to %s (error: %d)" % [temp_path, FileAccess.get_open_error()]}
	file.store_string(source)
	file.close()

	var script: GDScript = ResourceLoader.load(temp_path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
	if script == null:
		DirAccess.remove_absolute(temp_path)
		return {"error": "Script compilation failed — ResourceLoader.load returned null for: %s" % temp_path}

	var temp_node: Node = Node.new()
	temp_node.set_script(script)
	add_child(temp_node)

	# Check that the compiled script exposes _run before calling
	if not temp_node.has_method("_run"):
		temp_node.queue_free()
		DirAccess.remove_absolute(temp_path)
		return {"error": "Script loaded but _run() method is not callable — possible parse/compilation error in the code. Raw source:\n%s" % source}

	# Detect how many arguments the user's _run() expects.
	# GDScript's call() with extra args fails silently on 0-arg functions,
	# returning an empty dict which produces no result/error in the response.
	var run_arg_count: int = 2  # default: root + scene
	var method_list: Array = temp_node.get_method_list()
	for m: Dictionary in method_list:
		if m.get("name", "") == "_run":
			run_arg_count = (m.get("args", []) as Array).size()
			break

	var result: Variant
	if run_arg_count == 0:
		result = temp_node.call("_run")
	elif run_arg_count == 1:
		result = temp_node.call("_run", get_tree().root)
	else:
		result = temp_node.call("_run", get_tree().root, get_tree().current_scene)
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


## Start monitoring properties over time and await the full duration.
## Returns collected data once monitoring completes.
func _monitor_properties(path: String, props: Array, duration: float) -> Dictionary:
	var node: Node = _resolve_node(path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	if props.is_empty():
		return {"error": "At least one property must be specified for monitoring"}
	if duration < 0.0:
		return {"error": "Duration must be non-negative (got %.1f)" % duration}
	var monitor_id: int = _next_monitor_id
	_next_monitor_id += 1
	_monitors[monitor_id] = {
		"path": path,
		"props": props,
		"data": [],
		"start_time": Time.get_unix_time_from_system(),
		"duration": duration,
	}
	# Wait for the full monitoring duration.  _update_monitors() collects
	# samples every frame in _process(), so all data has been gathered by
	# the time this timer fires.
	await get_tree().create_timer(duration).timeout
	if not _monitors.has(monitor_id):
		return {"error": "Monitor was cleaned up before results could be retrieved"}
	var monitor: Dictionary = _monitors[monitor_id]
	var data: Array = monitor["data"] as Array
	# Mark as completed instead of erasing — get_monitor_results needs it.
	# Auto-cleanup in _update_monitors() removes stale entries after 60s.
	monitor["completed"] = true
	monitor["completion_time"] = Time.get_unix_time_from_system()
	return {"result": {
		"monitor_id": monitor_id,
		"path": path,
		"properties": props,
		"data": data,
		"sample_count": data.size(),
	}}


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
		var node: Node = _resolve_node(monitor["path"] as String)
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
	if _recording:
		return {"error": "Already recording. Stop recording before starting a new one."}
	_recording = true
	_recorded_events.clear()
	_record_start_time = Time.get_unix_time_from_system()
	return {"result": "Recording started"}


## Stop recording input events.
func _stop_recording() -> Dictionary:
	if not _recording:
		return {"error": "Not currently recording. Start recording first."}
	_recording = false
	var events: Array = _recorded_events.duplicate()
	return {"result": {"events": events, "count": events.size()}}


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
	var node_script: Script = node.get_script()
	if node_script != null and node_script.resource_path == script_res.resource_path:
		found.append(str(node.get_path()))
	for child: Node in node.get_children():
		_find_nodes_recursive(child, script_res, found)


## Get autoload node info.
func _get_autoload(name: String) -> Dictionary:
	if name.is_empty():
		return {"error": "Autoload name is required (got empty string)"}
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
		var node: Node = _resolve_node(path_str)
		if node == null:
			results[path_str] = {"error": "Node not found"}
			continue
		var node_props: Dictionary = {}
		for prop_variant: Variant in properties:
			var prop_name: String = prop_variant as String
			if prop_name == "type":
				node_props["type"] = node.get_class()
			else:
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
			# Default to false — only Button and Label have meaningful text.
			# Without this, bare Control nodes (Container, Panel, etc.) would
			# always match a text filter because match_text stays true.
			match_text = false
			if ctrl is Button:
				match_text = (ctrl as Button).text.find(filter["text"] as String) != -1
			elif ctrl is Label:
				match_text = (ctrl as Label).text.find(filter["text"] as String) != -1
		var match_name: bool = true
		if filter.has("name"):
			var search_name: String = filter["name"] as String
			match_name = ctrl.name.find(search_name) != -1
		if match_type and match_text and match_name:
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
	if text.is_empty():
		return {"error": "Button text must not be empty"}
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
	if path.is_empty():
		return {"error": "Path must not be empty"}
	var start_time: float = Time.get_unix_time_from_system()
	while true:
		var node: Node = _resolve_node(path)
		if node != null:
			var elapsed: float = Time.get_unix_time_from_system() - start_time
			return {"result": {"found": true, "path": path, "time": elapsed}}
		if Time.get_unix_time_from_system() - start_time >= timeout:
			return {"result": {"found": false, "path": path, "timeout": true, "message": "Timed out after %.1f seconds" % timeout}}
		await get_tree().process_frame
	return {"error": "Node not found: %s" % path}


## Find nodes near a position.
## NOTE: 2D positions are converted to Vector3 (z=0) for uniform distance calculation.
## 2D, 3D, and Control (UI) nodes are included in results with distances in 3D space.
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
	elif node is Control:
		var ctrl: Control = node as Control
		var pos_3d: Vector3 = Vector3(ctrl.global_position.x, ctrl.global_position.y, 0.0)
		var dist: float = pos_3d.distance_to(center)
		if dist <= radius:
			found.append({
				"path": str(ctrl.get_path()),
				"name": str(ctrl.name),
				"type": ctrl.get_class(),
				"distance": dist,
			})
	for child: Node in node.get_children():
		_find_nearby_recursive(child, center, radius, found)


## Navigate a node to a target (for NavAgent-based nodes).
func _navigate_to(path: String, target: Variant) -> Dictionary:
	if path.is_empty():
		return {"error": "Path must not be empty"}
	var node: Node = _resolve_node(path)
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
	# Check for NavigationAgent on the node itself.
	# NavigationAgent2D.set_target_position() expects Vector2, while
	# NavigationAgent3D expects Vector3.  Passing Vector3 to a 2D agent
	# causes a silent GDScript type-mismatch crash.
	if node.has_method("set_target_position"):
		if node is NavigationAgent2D:
			(node as NavigationAgent2D).set_target_position(Vector2(target_pos.x, target_pos.y))
		else:
			node.set_target_position(target_pos)
		return {"result": "Navigation target set to (%f, %f, %f)" % [target_pos.x, target_pos.y, target_pos.z]}
	# Fallback: search immediate children for a NavigationAgent
	for child: Node in node.get_children():
		if child.has_method("set_target_position"):
			if child is NavigationAgent2D:
				(child as NavigationAgent2D).set_target_position(Vector2(target_pos.x, target_pos.y))
			else:
				child.set_target_position(target_pos)
			return {"result": "Navigation target set via child '%s' to (%f, %f, %f)" % [child.name, target_pos.x, target_pos.y, target_pos.z]}
	return {"error": "Node does not support navigation (no set_target_position method found on node or its children)"}


## Move a node to a position.
func _move_to(path: String, target: Variant) -> Dictionary:
	if path.is_empty():
		return {"error": "Path must not be empty"}
	var node: Node = _resolve_node(path)
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


## Watch signals on a node for the given duration and return all captured events.
## Uses cancel-aware generation counters so overlapping calls for the same path
## don't interfere with each other.
func _watch_signals(path: String, signals: Array, duration: float) -> Dictionary:
	var node: Node = _resolve_node(path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	if signals.is_empty():
		return {"error": "At least one signal must be specified to watch"}
	if duration < 0.0:
		return {"error": "Duration must be non-negative (got %.1f)" % duration}
	var canonical_path: String = str(node.get_path())
	print("[MCP Runtime] _watch_signals: registering watchers for path=%s (canonical=%s) signals=%s duration=%.1f" % [path, canonical_path, str(signals), duration])
	if not _signal_watchers.has(canonical_path):
		_signal_watchers[canonical_path] = {}
	if not _signal_watcher_callables.has(canonical_path):
		_signal_watcher_callables[canonical_path] = {}
	var connected: Array[String] = []
	for sig_variant: Variant in signals:
		var sig_name: String = sig_variant as String
		var sig_param_count: int = 0
		for s in node.get_signal_list():
			if s["name"] == sig_name:
				sig_param_count = (s["args"] as Array).size()
				break
		if not node.has_signal(sig_name):
			push_warning("[MCP Runtime] _watch_signals: signal '%s' not found on node '%s'" % [sig_name, canonical_path])
			continue
		# Only create watcher entry when signal actually exists on the node
		if not _signal_watchers[canonical_path].has(sig_name):
			_signal_watchers[canonical_path][sig_name] = []
		var callback: Callable = func(p0 = null, p1 = null, p2 = null, p3 = null, p4 = null, p5 = null, p6 = null, p7 = null, sn: String = sig_name, np: String = canonical_path) -> void:
			if _signal_watchers.has(np) and _signal_watchers[np].has(sn):
				var args: Array = []
				var all_args: Array = [p0, p1, p2, p3, p4, p5, p6, p7]
				for i in range(sig_param_count):
					args.append(all_args[i])
				_signal_watchers[np][sn].append({
					"time": Time.get_unix_time_from_system(),
					"args": MCPVariantCodec.serialize_value(args),
				})
		node.connect(sig_name, callback)
		_signal_watcher_callables[canonical_path][sig_name] = {"callable": callback, "node": node}
		connected.append(sig_name)
	if connected.is_empty():
		# Clean up empty dict entries we created above
		_signal_watcher_callables.erase(canonical_path)
		_signal_watchers.erase(canonical_path)
		return {"error": "None of the requested signals exist on node '%s'" % canonical_path}

	# Wait for the full duration
	await get_tree().create_timer(duration).timeout

	# Collect all captured data and clean up
	var result_data: Dictionary = {}
	if _signal_watchers.has(canonical_path):
		for sig_name: String in _signal_watchers[canonical_path]:
			result_data[sig_name] = _signal_watchers[canonical_path][sig_name].duplicate()
		_signal_watchers.erase(canonical_path)
	# Disconnect all tracked callables
	if _signal_watcher_callables.has(canonical_path):
		for sig_name: String in _signal_watcher_callables[canonical_path]:
			var entry: Dictionary = _signal_watcher_callables[canonical_path][sig_name]
			var n: Node = entry["node"] as Node
			var c: Callable = entry["callable"] as Callable
			if is_instance_valid(n) and n.has_signal(sig_name) and n.is_connected(sig_name, c):
				n.disconnect(sig_name, c)
		_signal_watcher_callables.erase(canonical_path)

	return {"result": {"path": path, "watched_signals": signals, "data": result_data, "duration": duration}}


## Stop watching signals on a node and return collected data.
## If signals array is empty/all, disconnects all watchers for the path.
## If specific signal names are provided, only those are disconnected.
func _unwatch_signals(path: String, signals: Array) -> Dictionary:
	# Resolve node to get canonical path — must match what _watch_signals stored.
	var node: Node = _resolve_node(path)
	if node == null:
		return {"error": "No active signal watchers for path: %s (node not found)" % path}
	var canonical_path: String = str(node.get_path())
	print("[MCP Runtime] _unwatch_signals: path=%s canonical=%s _signal_watchers.has=%s _signal_watcher_callables.has=%s keys=%s" % [path, canonical_path, _signal_watchers.has(canonical_path), _signal_watcher_callables.has(canonical_path), str(_signal_watchers.keys())])
	if not _signal_watchers.has(canonical_path) and not _signal_watcher_callables.has(canonical_path):
		return {"error": "No active signal watchers for path: %s (canonical: %s)" % [path, canonical_path]}

	var result_data: Dictionary = {}
	var signals_to_remove: Array = []
	if signals.is_empty():
		# Remove all signals for this path
		signals_to_remove = _signal_watchers[canonical_path].keys()
	else:
		signals_to_remove = signals

	for sig_name: String in signals_to_remove:
		if _signal_watcher_callables.has(canonical_path) and _signal_watcher_callables[canonical_path].has(sig_name):
			var entry: Dictionary = _signal_watcher_callables[canonical_path][sig_name]
			var n: Node = entry.get("node") as Node
			var c: Callable = entry.get("callable") as Callable
			if is_instance_valid(n) and n.has_signal(sig_name) and n.is_connected(sig_name, c):
				n.disconnect(sig_name, c)
			_signal_watcher_callables[canonical_path].erase(sig_name)
		# Collect any events captured so far
		if _signal_watchers[canonical_path].has(sig_name):
			result_data[sig_name] = _signal_watchers[canonical_path][sig_name].duplicate()
			_signal_watchers[canonical_path].erase(sig_name)

	# Clean up empty entries
	if _signal_watchers[canonical_path].is_empty():
		_signal_watchers.erase(canonical_path)
	if _signal_watcher_callables.has(canonical_path) and _signal_watcher_callables[canonical_path].is_empty():
		_signal_watcher_callables.erase(canonical_path)

	return {"result": {"path": path, "stopped_signals": signals_to_remove, "data": result_data}}


## Delete captured frame PNG files from disk.
## If paths array is empty, deletes all mcp_frame_*.png files in user://.
func _delete_captured_frames(paths: Array) -> Dictionary:
	var deleted: Array = []
	var errors: Array = []
	var base_dir: String = ProjectSettings.globalize_path("user://")
	if not base_dir.ends_with("/"):
		base_dir += "/"

	if paths.is_empty():
		# Delete all captured frames in user://
		var dir := DirAccess.open(base_dir)
		if dir == null:
			return {"error": "Failed to open user directory: %s (error: %d)" % [base_dir, DirAccess.get_open_error()]}
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while not file_name.is_empty():
			if file_name.begins_with("mcp_frame_") and file_name.ends_with(".png"):
				var full_path: String = base_dir + file_name
				var err: Error = DirAccess.remove_absolute(full_path)
				if err == OK:
					deleted.append(full_path)
				else:
					errors.append({"path": full_path, "error": error_string(err)})
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		for p: Variant in paths:
			var file_path: String = p as String
			if FileAccess.file_exists(file_path):
				var err: Error = DirAccess.remove_absolute(file_path)
				if err == OK:
					deleted.append(file_path)
				else:
					errors.append({"path": file_path, "error": error_string(err)})
			else:
				errors.append({"path": file_path, "error": "File not found"})

	var result_dict: Dictionary = {"deleted": deleted, "count": deleted.size()}
	if not errors.is_empty():
		result_dict["errors"] = errors
	return {"result": result_dict}


## Stop an active property monitoring session by path and return collected data.
func _stop_monitoring(path: String) -> Dictionary:
	var found_id: int = -1
	for monitor_id: int in _monitors:
		var m: Dictionary = _monitors[monitor_id]
		if m.get("path", "") as String == path and not m.get("completed", false):
			found_id = monitor_id
			break

	if found_id == -1:
		# Check if there's a completed monitor for this path
		for monitor_id: int in _monitors:
			var m: Dictionary = _monitors[monitor_id]
			if m.get("path", "") as String == path:
				return {"result": {"path": path, "data": m["data"], "sample_count": (m["data"] as Array).size(), "message": "Monitor already completed"}}
		return {"error": "No active monitor found for path: %s" % path}

	var monitor: Dictionary = _monitors[found_id]
	var now: float = Time.get_unix_time_from_system()
	# Do one last sample before stopping
	var node: Node = _resolve_node(path)
	if node != null:
		var elapsed: float = now - (monitor["start_time"] as float)
		var entry: Dictionary = {"time": elapsed}
		for prop: Variant in monitor["props"] as Array:
			var prop_name: String = prop as String
			entry[prop_name] = MCPVariantCodec.serialize_value(node.get(prop_name))
		(monitor["data"] as Array).append(entry)

	monitor["completed"] = true
	monitor["completion_time"] = now

	return {"result": {
		"path": path,
		"properties": monitor["props"],
		"data": monitor["data"],
		"sample_count": (monitor["data"] as Array).size(),
		"duration": monitor["duration"],
		"stopped_early": true,
	}}


## Batch set properties on multiple nodes.
## nodes: [{path: String, properties: {prop_name: value, ...}}, ...]
func _batch_set_properties(nodes: Array) -> Dictionary:
	if nodes.is_empty():
		return {"error": "Nodes array must not be empty"}

	var results: Array = []
	var success_count: int = 0
	var error_count: int = 0

	for item: Variant in nodes:
		if not item is Dictionary:
			error_count += 1
			results.append({"error": "Invalid node descriptor: expected object"})
			continue

		var node_desc: Dictionary = item as Dictionary
		var node_path: String = node_desc.get("path", "")
		var props: Dictionary = node_desc.get("properties", {})

		if node_path.is_empty():
			error_count += 1
			results.append({"error": "Node descriptor missing 'path' field"})
			continue

		if props.is_empty():
			error_count += 1
			results.append({"path": node_path, "error": "Node descriptor missing 'properties' field"})
			continue

		var node_results: Dictionary = {"path": node_path, "properties": {}}
		for prop_name: String in props:
			var prop_value: Variant = props[prop_name]
			var result: Dictionary = _set_game_node_property(node_path, prop_name, prop_value)
			if result.has("error"):
				node_results["properties"][prop_name] = result["error"]
				error_count += 1
			else:
				node_results["properties"][prop_name] = "ok"
				success_count += 1

		results.append(node_results)

	return {"result": {"results": results, "success_count": success_count, "error_count": error_count}}


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
## Accepts keycode as string ("Space", "KEY_ENTER") or integer keycode.
func _simulate_key_event(params: Dictionary) -> Dictionary:
	var raw_keycode: Variant = params.get("keycode", "")
	var keycode_str: String = ""
	var keycode: Key = KEY_NONE
	if raw_keycode is String:
		keycode_str = raw_keycode as String
		keycode = OS.find_keycode_from_string(keycode_str)
	elif raw_keycode is int:
		keycode = raw_keycode as Key
		keycode_str = str(keycode)
	elif raw_keycode is float:
		keycode = int(raw_keycode) as Key
		keycode_str = str(int(raw_keycode))
	else:
		return {"error": "Invalid keycode type: %s" % typeof(raw_keycode)}
	if keycode_str.is_empty() and keycode == KEY_NONE:
		return {"error": "Keycode is required"}
	
	# If numeric keycode was provided, search alias only if unrecognized
	if keycode == KEY_NONE and not keycode_str.is_empty():
		keycode = OS.find_keycode_from_string(keycode_str)
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
