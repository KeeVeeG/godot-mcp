## MCP Debugger Plugin — EditorDebuggerPlugin subclass.
## Registered via EditorPlugin.add_debugger_plugin() in plugin.gd's _enter_tree().
## Manages debugger sessions, breakpoint sync, and async message capture
## for the debugging_commands module.
@tool
class_name MCPDebuggerPlugin
extends EditorDebuggerPlugin

## Reference to the debugging commands module (for callbacks)
var _debugging_commands: RefCounted = null

## Pending breakpoints — synced when a game session becomes active.
## {key: {path, line, condition, enabled}}
var _pending_breakpoints: Dictionary = {}

## Last call stack data (populated by _capture)
var last_call_stack: Array = []
var is_paused: bool = false

## Active session reference
var _active_session: EditorDebuggerSession = null

## Promise-like signal for async debugger responses (evaluate, stack dump)
signal evaluation_result(value: Variant)
signal stack_dump_received(frames: Array)

## Accumulated evaluation result (set by _capture, consumed by wait loop)
var _eval_result: Variant = null


## Called automatically by the engine when a new session is created.
## Sessions are created once at editor start and may be reactivated on game launch.
func _setup_session(session_id: int) -> void:
	var session := get_session(session_id)
	if session == null:
		return

	session.started.connect(_on_session_started.bind(session))
	session.stopped.connect(_on_session_stopped.bind(session))
	session.breaked.connect(_on_session_breaked.bind(session))
	session.continued.connect(_on_session_continued.bind(session))
	print("[MCP Debugger] Session %d setup complete" % session_id)


func _on_session_started(session: EditorDebuggerSession) -> void:
	print("[MCP Debugger] Session started — game connected, syncing breakpoints")
	_active_session = session
	_sync_pending_breakpoints(session)


func _on_session_stopped(session: EditorDebuggerSession) -> void:
	print("[MCP Debugger] Session stopped — game disconnected")
	if _active_session == session:
		_active_session = null
		is_paused = false
		last_call_stack.clear()


func _on_session_breaked(can_debug: bool, session: EditorDebuggerSession) -> void:
	print("[MCP Debugger] Breakpoint hit — can_debug=%s" % can_debug)
	if can_debug:
		is_paused = true
		# Auto-request stack dump so last_call_stack is populated
		session.send_message("get_stack_dump", [])
	else:
		# Auto-continue non-debuggable breaks to prevent IPC deadlock.
		# Dynamically-loaded scripts (e.g., execute_game_script temp scripts)
		# trigger can_debug=false breaks — resume immediately since nothing
		# can be inspected.
		session.send_message("continue", [])


func _on_session_continued(session: EditorDebuggerSession) -> void:
	print("[MCP Debugger] Execution continued")
	is_paused = false
	last_call_stack.clear()


## Sync stored breakpoints to a newly active session.
func _sync_pending_breakpoints(session: EditorDebuggerSession) -> void:
	if _pending_breakpoints.is_empty():
		return
	print("[MCP Debugger] Syncing %d pending breakpoints to session" % _pending_breakpoints.size())
	for key: String in _pending_breakpoints:
		var bp: Dictionary = _pending_breakpoints[key]
		session.set_breakpoint(bp.path, bp.line, bp.enabled)
	# Clear pending — they are now tracked by the engine
	_pending_breakpoints.clear()


## Queue a breakpoint to be synced when a session becomes active.
func queue_breakpoint(path: String, line: int, condition: String, enabled: bool = true) -> void:
	var key: String = "%s:%d" % [path, line]
	_pending_breakpoints[key] = {
		"path": path,
		"line": line,
		"condition": condition,
		"enabled": enabled,
	}
	# Also apply immediately if session is active
	if _active_session and _active_session.is_active():
		_active_session.set_breakpoint(path, line, enabled)


## Remove a queued breakpoint.
func unqueue_breakpoint(path: String, line: int) -> void:
	var key: String = "%s:%d" % [path, line]
	_pending_breakpoints.erase(key)
	if _active_session and _active_session.is_active():
		_active_session.set_breakpoint(path, line, false)


## Get the first active session, or null.
func get_active_session() -> EditorDebuggerSession:
	# Prefer cached active session
	if _active_session and _active_session.is_active():
		return _active_session
	# Fallback: scan all sessions
	for s in get_sessions():
		if s is EditorDebuggerSession and s.is_active():
			_active_session = s
			return s
	return null


## Capture messages from the game process.
## Handles stack_dump, stack_frame_vars, and custom MCP messages.
func _has_capture(prefix: String) -> bool:
	return prefix == "mcp" or prefix == "debugger"


func _capture(message: String, data: Array, session_id: int) -> bool:
	match message:
		"stack_dump":
			_handle_stack_dump(data)
			return true
		"stack_frame_vars":
			# Frame vars come as one summary + individual "stack_frame_var" messages
			# Store them for retrieval
			return true
		"mcp:eval_result":
			_eval_result = data[0]
			evaluation_result.emit(data[0])
			return true
		_:
			return false


## Parse a stack_dump response from the game debugger.
## Format: [frame_count * 3]  where each frame is [file, line, function]
func _handle_stack_dump(data: Array) -> void:
	last_call_stack.clear()
	if data.size() < 2:
		return
	# Godot sends total element count as first element
	var total_elements: int = data[0] as int
	var frame_count: int = total_elements / 3
	for i in range(frame_count):
		var idx: int = 1 + i * 3
		last_call_stack.append({
			"file": data[idx],
			"line": data[idx + 1],
			"function": data[idx + 2],
		})
	stack_dump_received.emit(last_call_stack)


## Send a stack frame variable request for a specific frame index.
func request_stack_frame_vars(frame: int, session_id: int = -1) -> void:
	var session: EditorDebuggerSession
	if session_id >= 0:
		session = get_session(session_id)
	else:
		session = get_active_session()
	if session and session.is_active():
		session.send_message("get_stack_frame_vars", [frame])


## Send an evaluate request to the running game (breakpoint required).
func request_evaluate(expression: String, frame: int = 0) -> void:
	_eval_result = null
	var session := get_active_session()
	if session and session.is_active() and session.is_breaked():
		session.send_message("evaluate", [expression, frame])
