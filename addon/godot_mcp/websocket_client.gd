## WebSocket client that connects to the MCP Node.js server.
## Extends Node so it can be added to the scene tree and receive _process.
class_name MCPWebSocketClient
extends Node

## Emitted when connected to the MCP server
signal connected(port: int)
## Emitted when disconnected from the MCP server
signal disconnected()
## Emitted when a raw JSON-RPC message is received
signal message_received(message: Dictionary)

## WebSocket peer
var _ws: WebSocketPeer = WebSocketPeer.new()

## Current connection state
var _is_connected: bool = false

## Port that we are currently connected to
var _connected_port: int = -1

## Whether we are currently scanning for a server
var _scanning: bool = false

## Pending requests keyed by id
var _pending_requests: Dictionary = {}

## Reconnect timer
var _reconnect_timer: float = 0.0

## Ping timer
var _ping_timer: float = 0.0

## Timestamp of last received message (for idle timeout detection)
var _last_received_time: float = 0.0

## Config reference
var _config: MCPConfig

## --- Non-blocking scan state machine ---
const SCAN_IDLE: int = 0
const SCAN_CONNECTING: int = 1
const SCAN_WAITING: int = 2
const SCAN_SETTLING: int = 3
var _scan_state: int = SCAN_IDLE
var _scan_ports: Array[int] = []
var _scan_port_index: int = 0
var _scan_test_ws: WebSocketPeer = null
var _scan_elapsed: float = 0.0
var _scan_found_port: int = -1
const SCAN_CONNECT_TIMEOUT: float = 0.5
const SCAN_SETTLE_DELAY: float = 0.2
var _scan_settle_timer: float = 0.0


func _ready() -> void:
	_config = MCPConfig.get_instance()


func _process(delta: float) -> void:
	if _scanning:
		_process_scan(delta)
		return

	if _is_connected:
		_ws.poll()
		var state: int = _ws.get_ready_state()

		if state == WebSocketPeer.STATE_CLOSING:
			# Wait for the close handshake
			pass
		elif state == WebSocketPeer.STATE_CLOSED:
			_handle_disconnect()

		# Read messages
		while _ws.get_available_packet_count() > 0:
			var packet: PackedByteArray = _ws.get_packet()
			var text: String = packet.get_string_from_utf8()
			_handle_message(text)

		# Ping/pong keepalive
		_ping_timer += delta
		if _ping_timer >= MCPConfig.PING_INTERVAL:
			_ping_timer = 0.0
			_send_ping()

		# Idle timeout — force disconnect if no message received
		var time_since_last: float = Time.get_unix_time_from_system() - _last_received_time
		if time_since_last > MCPConfig.IDLE_TIMEOUT:
			push_warning("[MCP] No message received in %.0fs — forcing disconnect" % MCPConfig.IDLE_TIMEOUT)
			_handle_disconnect()
			return

		# Check request timeouts
		var now: float = Time.get_unix_time_from_system()
		var timed_out_ids: Array = []
		for req_id: int in _pending_requests:
			var req: Dictionary = _pending_requests[req_id] as Dictionary
			if now - req["time"] as float > MCPConfig.REQUEST_TIMEOUT:
				timed_out_ids.append(req_id)
		for req_id: int in timed_out_ids:
			var req: Dictionary = _pending_requests[req_id] as Dictionary
			var deferred: Callable = req["callback"] as Callable
			_pending_requests.erase(req_id)
			deferred.call({"error": {"code": -1, "message": "Request timed out"}})
	else:
		# Auto-reconnect
		_reconnect_timer += delta
		if _reconnect_timer >= MCPConfig.RECONNECT_INTERVAL:
			_reconnect_timer = 0.0
			scan_for_server()


## Process the non-blocking scan state machine each frame.
func _process_scan(delta: float) -> void:
	match _scan_state:
		SCAN_CONNECTING:
			# Try to connect to the current port
			var port: int = _scan_ports[_scan_port_index]
			var url: String = "ws://localhost:%d" % port
			_scan_test_ws = WebSocketPeer.new()
			var err: Error = _scan_test_ws.connect_to_url(url)
			if err != OK:
				# Connection failed immediately, try next port
				_scan_test_ws.close()
				_scan_test_ws = null
				_scan_port_index += 1
				if _scan_port_index >= _scan_ports.size():
					_finish_scan(false)
				return
			_scan_elapsed = 0.0
			_scan_state = SCAN_WAITING

		SCAN_WAITING:
			_scan_elapsed += delta
			_scan_test_ws.poll()
			var state: int = _scan_test_ws.get_ready_state()
			if state == WebSocketPeer.STATE_OPEN:
				# Found a server — close test socket, enter settle delay
				_scan_found_port = _scan_ports[_scan_port_index]
				_scan_test_ws.close()
				_scan_test_ws = null
				_scan_settle_timer = SCAN_SETTLE_DELAY
				_scan_state = SCAN_SETTLING
			elif state == WebSocketPeer.STATE_CLOSED or _scan_elapsed >= SCAN_CONNECT_TIMEOUT:
				# Timed out or closed, try next port
				_scan_test_ws.close()
				_scan_test_ws = null
				_scan_port_index += 1
				if _scan_port_index >= _scan_ports.size():
					_finish_scan(false)
				else:
					_scan_state = SCAN_CONNECTING

		SCAN_SETTLING:
			# Non-blocking settle delay to let server process the close
			_scan_settle_timer -= delta
			if _scan_settle_timer <= 0.0:
				_connect_to_port(_scan_found_port)
				_scan_found_port = -1
				_finish_scan(true)


## Finish scanning and reset state.
func _finish_scan(found: bool) -> void:
	_scanning = false
	_scan_state = SCAN_IDLE
	_scan_test_ws = null
	if not found:
		pass  # No server found, will retry on next reconnect cycle


## Scan ports 6505-6514 for an active MCP server.
## Non-blocking: sets up state machine, returns immediately.
func scan_for_server() -> void:
	if _scanning:
		return
	_scanning = true
	_scan_ports = _config.get_port_range()
	_scan_port_index = 0
	_scan_elapsed = 0.0
	_scan_settle_timer = 0.0
	_scan_state = SCAN_CONNECTING


## Connect to a specific port.
func _connect_to_port(port: int) -> void:
	if _is_connected:
		_ws.close()
	_ws = WebSocketPeer.new()
	_ws.outbound_buffer_size = 8 * 1024 * 1024  # 8 MiB for large tool responses
	_ws.inbound_buffer_size = 4 * 1024 * 1024   # 4 MiB for large requests
	var url: String = "ws://localhost:%d" % port
	var err: Error = _ws.connect_to_url(url)
	if err != OK:
		push_warning("[MCP] Failed to connect to %s: %s" % [url, error_string(err)])
		return
	_connected_port = port
	_config.connected_port = port
	_is_connected = true
	_ping_timer = 0.0
	_reconnect_timer = 0.0
	_last_received_time = Time.get_unix_time_from_system()
	connected.emit(port)


## Handle disconnection.
func _handle_disconnect() -> void:
	_is_connected = false
	var old_port: int = _connected_port
	_connected_port = -1
	_config.connected_port = -1
	# Notify all pending request callers with a disconnect error
	for req_id: int in _pending_requests:
		var req: Dictionary = _pending_requests[req_id] as Dictionary
		var callback: Callable = req["callback"] as Callable
		callback.call({"error": {"code": -1, "message": "Disconnected from server"}})
	_pending_requests.clear()
	print("[MCP] Disconnected from port %d" % old_port)
	disconnected.emit()


## Disconnect from the server.
func disconnect_from_server() -> void:
	if _is_connected:
		_ws.close()
		_handle_disconnect()


## Handle an incoming message.
func _handle_message(text: String) -> void:
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("[MCP] Failed to parse message: " + json.get_error_message())
		return
	var message: Variant = json.data
	if not message is Dictionary:
		return
	var msg_dict: Dictionary = message as Dictionary
	_last_received_time = Time.get_unix_time_from_system()
	message_received.emit(msg_dict)

	# Check if it's a response to a pending request
	if msg_dict.has("id"):
		var msg_id: Variant = msg_dict["id"]
		if msg_id is int and _pending_requests.has(msg_id as int):
			var req: Dictionary = _pending_requests[msg_id as int] as Dictionary
			var callback: Callable = req["callback"] as Callable
			_pending_requests.erase(msg_id as int)
			callback.call(msg_dict)


## Send a JSON-RPC 2.0 response (with id, for request/reply pattern).
func send_response(id: Variant, result: Variant = null, error: Variant = null) -> void:
	if not _is_connected:
		return
	var message: Dictionary = {
		"jsonrpc": "2.0",
		"id": id,
	}
	if error != null:
		message["error"] = error
	else:
		message["result"] = result
	var json_text: String = JSON.stringify(message)
	_ws.send_text(json_text)


## Send a JSON-RPC 2.0 notification (no id, no response expected).
func send_notification(method_name: String, params: Dictionary = {}) -> void:
	if not _is_connected:
		return
	var message: Dictionary = {
		"jsonrpc": "2.0",
		"method": method_name,
		"params": params,
	}
	var json_text: String = JSON.stringify(message)
	_ws.send_text(json_text)


## Send a ping for keepalive.
func _send_ping() -> void:
	if not _is_connected:
		return
	_ws.send_text(JSON.stringify({"jsonrpc": "2.0", "method": "ping"}))


## Whether we are connected.
func is_server_connected() -> bool:
	return _is_connected


## Get the port we are connected to.
func get_connected_port() -> int:
	return _connected_port
