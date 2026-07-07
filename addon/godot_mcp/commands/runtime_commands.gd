## Runtime commands module - 19 tools.
## Handles game runtime inspection via file-based IPC.
class_name MCPRuntimeCommands
extends RefCounted

var _plugin: EditorPlugin

const REQUEST_PATH: String = "user://mcp_runtime_request.json"
const RESPONSE_PATH: String = "user://mcp_runtime_response.json"
const IPC_TIMEOUT: float = 30.0
var _next_request_id: int = 1

## Task queue for serialized IPC — prevents concurrent file overwrite
var _ipc_queue: Array[Dictionary] = []
var _ipc_processing: bool = false
var _ipc_results: Dictionary = {}  # int -> Dictionary
var _task_counter: int = 0
var _dead_tasks: Array[int] = []


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func get_commands() -> Dictionary:
	return {
		"runtime/get_scene_tree": get_game_scene_tree,
		"runtime/get_node_properties": get_game_node_properties,
		"runtime/set_node_property": set_game_node_property,
		"runtime/execute_script": execute_game_script,
		"runtime/capture_frames": capture_frames,
		"runtime/monitor_properties": monitor_properties,
		"runtime/start_recording": start_recording,
		"runtime/stop_recording": stop_recording,
		"runtime/replay_recording": replay_recording,
		"runtime/find_by_script": find_nodes_by_script,
		"runtime/get_autoload": get_autoload,
		"runtime/batch_get_properties": batch_get_properties,
		"runtime/find_ui_elements": find_ui_elements,
		"runtime/click_button": click_button_by_text,
		"runtime/wait_for_node": wait_for_node,
		"runtime/find_nearby": find_nearby_nodes,
		"runtime/navigate_to": navigate_to,
		"runtime/move_to": move_to,
		"runtime/watch_signals": watch_signals,
	}


## Check if the game is running.
func _ensure_game_running() -> bool:
	return _plugin.get_editor_interface().is_playing_scene()


## Send a request to the runtime via IPC and wait for response.
## Uses task queue with per-task IDs to route results to correct caller.
func _ipc_request(method: String, params: Dictionary = {}) -> Dictionary:
	if not _ensure_game_running():
		return {"error": "Game is not running. Start the scene before using runtime commands."}

	_task_counter += 1
	var task_id := _task_counter
	_ipc_queue.append({"id": task_id, "method": method, "params": params})

	if not _ipc_processing:
		_process_ipc_queue()

	return await _wait_for_ipc_result(task_id)


## Wait for our specific task result (with timeout).
## Marks task as dead on timeout to prevent memory leak in _ipc_results.
func _wait_for_ipc_result(task_id: int) -> Dictionary:
	var start: float = Time.get_unix_time_from_system()
	while Time.get_unix_time_from_system() - start < IPC_TIMEOUT:
		if _ipc_results.has(task_id):
			var result: Dictionary = _ipc_results[task_id]
			_ipc_results.erase(task_id)
			return result
		await _plugin.get_tree().process_frame
	_dead_tasks.append(task_id)
	return {"error": "IPC request timed out (%.1fs)" % IPC_TIMEOUT}


## Process all queued IPC requests sequentially.
## Wrapped in try/catch to prevent _ipc_processing from getting stuck on errors.
func _process_ipc_queue() -> void:
	if _ipc_processing:
		return
	_ipc_processing = true
	while not _ipc_queue.is_empty():
		var task: Dictionary = _ipc_queue.pop_front()
		# Skip tasks whose callers already timed out
		if _dead_tasks.has(task["id"]):
			continue
		var result: Dictionary = {}
		if not _ensure_game_running():
			result = {"error": "Game stopped during IPC processing"}
		else:
			result = await _do_ipc_request(task["method"], task["params"])
		if not _dead_tasks.has(task["id"]):
			_ipc_results[task["id"]] = result
		if not _ipc_queue.is_empty() and not _dead_tasks.has(task["id"]):
			await _plugin.get_tree().create_timer(0.15).timeout
	_ipc_processing = false


## Perform a single IPC request (write file, poll for response).
func _do_ipc_request(method: String, params: Dictionary = {}) -> Dictionary:
	if not _ensure_game_running():
		return {"error": "Game is not running. Start the scene before using runtime commands."}

	# Clean stale response files from previous requests
	if FileAccess.file_exists(RESPONSE_PATH):
		DirAccess.remove_absolute(RESPONSE_PATH)
	if FileAccess.file_exists(RESPONSE_PATH + ".tmp"):
		DirAccess.remove_absolute(RESPONSE_PATH + ".tmp")

	var request_id: String = "mcp_%d" % _next_request_id
	_next_request_id += 1

	var request: Dictionary = {"method": method, "params": params, "request_id": request_id}
	var json_text: String = JSON.stringify(request)
	var tmp_path: String = REQUEST_PATH + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return {"error": "Failed to write IPC request"}
	file.store_string(json_text)
	file.close()
	DirAccess.rename_absolute(tmp_path, REQUEST_PATH)

	var start: float = Time.get_unix_time_from_system()
	while Time.get_unix_time_from_system() - start < IPC_TIMEOUT:
		if not _ensure_game_running():
			return {"error": "Game stopped while waiting for runtime response"}
		if FileAccess.file_exists(RESPONSE_PATH):
			var resp_file := FileAccess.open(RESPONSE_PATH, FileAccess.READ)
			if resp_file:
				var resp_text: String = resp_file.get_as_text()
				resp_file.close()
				DirAccess.remove_absolute(RESPONSE_PATH)
				var json := JSON.new()
				var err := json.parse(resp_text)
				if err == OK and json.data is Dictionary:
					var resp_data: Dictionary = json.data as Dictionary
					var resp_id: String = resp_data.get("request_id", "")
					if not resp_id.is_empty() and resp_id != request_id:
						push_warning("[MCP Runtime] Ignoring stale response (expected %s, got %s)" % [request_id, resp_id])
						continue
					return resp_data
				return {"error": "Failed to parse IPC response"}
		await _plugin.get_tree().process_frame
	return {"error": "IPC request timed out (%.1fs). Hint: add a longer delay between runtime tool calls to allow pending requests to complete." % IPC_TIMEOUT}


## Get the game scene tree.
func get_game_scene_tree(params: Dictionary) -> Dictionary:
	return await _ipc_request("get_game_scene_tree", params)


## Get game node properties.
func get_game_node_properties(params: Dictionary) -> Dictionary:
	return await _ipc_request("get_game_node_properties", params)


## Set a game node property.
func set_game_node_property(params: Dictionary) -> Dictionary:
	return await _ipc_request("set_game_node_property", params)


## Execute GDScript code in the game context.
func execute_game_script(params: Dictionary) -> Dictionary:
	return await _ipc_request("execute_game_script", params)


## Capture multiple frames from the game.
func capture_frames(params: Dictionary) -> Dictionary:
	return await _ipc_request("capture_frames", params)


## Monitor properties over time.
func monitor_properties(params: Dictionary) -> Dictionary:
	return await _ipc_request("monitor_properties", params)


## Start recording input.
func start_recording(params: Dictionary) -> Dictionary:
	return await _ipc_request("start_recording", params)


## Stop recording input.
func stop_recording(params: Dictionary) -> Dictionary:
	return await _ipc_request("stop_recording", params)


## Replay recorded input.
func replay_recording(params: Dictionary) -> Dictionary:
	return await _ipc_request("replay_recording", params)


## Find nodes by script path.
func find_nodes_by_script(params: Dictionary) -> Dictionary:
	return await _ipc_request("find_nodes_by_script", params)


## Get autoload node info.
func get_autoload(params: Dictionary) -> Dictionary:
	return await _ipc_request("get_autoload", params)


## Batch get properties from multiple nodes.
func batch_get_properties(params: Dictionary) -> Dictionary:
	return await _ipc_request("batch_get_properties", params)


## Find UI elements matching a filter.
func find_ui_elements(params: Dictionary) -> Dictionary:
	return await _ipc_request("find_ui_elements", params)


## Click a button by its text.
func click_button_by_text(params: Dictionary) -> Dictionary:
	return await _ipc_request("click_button_by_text", params)


## Wait for a node to appear.
func wait_for_node(params: Dictionary) -> Dictionary:
	return await _ipc_request("wait_for_node", params)


## Find nodes near a position.
func find_nearby_nodes(params: Dictionary) -> Dictionary:
	return await _ipc_request("find_nearby_nodes", params)


## Navigate a node to a target.
func navigate_to(params: Dictionary) -> Dictionary:
	return await _ipc_request("navigate_to", params)


## Move a node to a position.
func move_to(params: Dictionary) -> Dictionary:
	return await _ipc_request("move_to", params)


## Watch signals on a node.
func watch_signals(params: Dictionary) -> Dictionary:
	return await _ipc_request("watch_signals", params)
