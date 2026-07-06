## Debugging commands module - 8 tools.
## Provides breakpoint management, call stack inspection, expression evaluation,
## and step-through debugging control.
class_name MCPDebuggingCommands
extends RefCounted

var _plugin: EditorPlugin

## Stored breakpoints: { "script_path:line": {path, line, condition} }
var _breakpoints: Dictionary = {}

## Debug session state
var _is_paused: bool = false
var _last_call_stack: Array = []
var _debugger_plugin: EditorDebuggerPlugin = null


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func get_commands() -> Dictionary:
	return {
		"set_breakpoint": set_breakpoint,
		"remove_breakpoint": remove_breakpoint,
		"list_breakpoints": list_breakpoints,
		"get_call_stack": get_call_stack,
		"evaluate_expression": evaluate_expression,
		"step_over": step_over,
		"step_into": step_into,
		"continue_execution": continue_execution,
	}


## Set a breakpoint in a GDScript file at a specific line.
## Optionally attach a condition expression.
func set_breakpoint(params: Dictionary) -> Dictionary:
	var script_path: String = params.get("script_path", "")
	var line: int = params.get("line", 0)
	var condition: String = params.get("condition", "")

	if script_path.is_empty():
		return {"error": "script_path is required"}
	if line < 1:
		return {"error": "line must be >= 1"}

	# Verify the script file exists
	var file_path: String = script_path
	if file_path.begins_with("res://"):
		file_path = ProjectSettings.globalize_path(file_path)
	if not FileAccess.file_exists(script_path):
		return {"error": "Script file not found: %s" % script_path}

	# Load the script resource to verify it's valid
	var script: Script = load(script_path) as Script
	if script == null:
		return {"error": "Failed to load script: %s" % script_path}

	# Check line is within script bounds
	var source_code: String = script.get_source_code()
	var line_count: int = source_code.split("\n").size()
	if line > line_count:
		return {"error": "Line %d exceeds script length (%d lines)" % [line, line_count]}

	# Store breakpoint
	var key: String = "%s:%d" % [script_path, line]
	_breakpoints[key] = {
		"path": script_path,
		"line": line,
		"condition": condition,
		"enabled": true,
	}

	# Use EditorDebuggerPlugin to set the breakpoint if debugger is available
	var debugger_plugin: EditorDebuggerPlugin = _get_debugger_plugin()
	if debugger_plugin != null:
		# Set breakpoint via the engine's debugger interface
		var session: EditorDebuggerSession = _get_active_session(debugger_plugin)
		if session != null:
			var msg: Array = [line, script_path, true]
			session.send_message("breakpoint", msg)

	return {"result": {
		"success": true,
		"path": script_path,
		"line": line,
		"condition": condition,
		"message": "Breakpoint set at %s:%d%s" % [script_path, line, " (conditional)" if condition != "" else ""],
	}}


## Remove a breakpoint from a GDScript file at a specific line.
func remove_breakpoint(params: Dictionary) -> Dictionary:
	var script_path: String = params.get("script_path", "")
	var line: int = params.get("line", 0)

	if script_path.is_empty():
		return {"error": "script_path is required"}
	if line < 1:
		return {"error": "line must be >= 1"}

	var key: String = "%s:%d" % [script_path, line]
	if not _breakpoints.has(key):
		return {"error": "No breakpoint at %s:%d" % [script_path, line]}

	_breakpoints.erase(key)

	# Remove via debugger
	var debugger_plugin: EditorDebuggerPlugin = _get_debugger_plugin()
	if debugger_plugin != null:
		var session: EditorDebuggerSession = _get_active_session(debugger_plugin)
		if session != null:
			var msg: Array = [line, script_path, false]
			session.send_message("breakpoint", msg)

	return {"result": {
		"success": true,
		"path": script_path,
		"line": line,
		"message": "Breakpoint removed from %s:%d" % [script_path, line],
	}}


## List all active breakpoints.
func list_breakpoints(_params: Dictionary) -> Dictionary:
	var bp_list: Array = []
	for key: String in _breakpoints:
		var bp: Dictionary = _breakpoints[key] as Dictionary
		bp_list.append({
			"path": bp["path"],
			"line": bp["line"],
			"condition": bp.get("condition", ""),
			"enabled": bp.get("enabled", true),
		})

	return {"result": {
		"count": bp_list.size(),
		"breakpoints": bp_list,
	}}


## Get the current call stack when paused at a breakpoint.
## Returns stack frames with local variables for each frame.
func get_call_stack(_params: Dictionary) -> Dictionary:
	var debugger_plugin: EditorDebuggerPlugin = _get_debugger_plugin()
	if debugger_plugin == null:
		return {"error": "Debugger plugin not available"}

	var session: EditorDebuggerSession = _get_active_session(debugger_plugin)
	if session == null:
		return {"error": "No active debug session. Start the game with debugging enabled."}

	# Request call stack from the running game
	session.send_message("get_stack_dump", [])
	# The response comes asynchronously; return last known state
	if _last_call_stack.is_empty():
		return {"result": {
			"paused": _is_paused,
			"frames": [],
			"message": "No call stack available. The game may not be paused at a breakpoint.",
		}}

	return {"result": {
		"paused": _is_paused,
		"frame_count": _last_call_stack.size(),
		"frames": _last_call_stack,
	}}


## Evaluate a GDScript expression in the specified context.
func evaluate_expression(params: Dictionary) -> Dictionary:
	var expression: String = params.get("expression", "")
	var context: String = params.get("context", "editor")

	if expression.is_empty():
		return {"error": "expression is required"}

	# Try Expression class first (handles void methods correctly)
	var expr := Expression.new()
	var parse_err: Error = expr.parse(expression)
	if parse_err == OK:
		# Pass editor root as base so engine singletons are accessible
		var base_obj: Object = Engine.get_main_loop() if Engine.get_main_loop() else _plugin.get_tree().root
		var result: Variant = expr.execute([], base_obj)
		if not expr.has_execute_failed():
			return {"result": {"expression": expression, "context": context, "value": result}}
		# Expression execution failed — fall through to GDScript

	# Fall back to GDScript (EditorScript for multi-statement, RefCounted for values)
	var result: Variant = _execute_in_editor(expression)
	return {"result": {"expression": expression, "context": context, "value": result}}


## Step over the current line when paused at a breakpoint.
func step_over(_params: Dictionary) -> Dictionary:
	var debugger_plugin: EditorDebuggerPlugin = _get_debugger_plugin()
	if debugger_plugin == null:
		return {"error": "Debugger plugin not available"}

	var session: EditorDebuggerSession = _get_active_session(debugger_plugin)
	if session == null:
		return {"error": "No active debug session"}

	session.send_message("next", [])
	_is_paused = false

	return {"result": {
		"success": true,
		"action": "step_over",
		"message": "Stepping over current line",
	}}


## Step into the current function call when paused.
func step_into(_params: Dictionary) -> Dictionary:
	var debugger_plugin: EditorDebuggerPlugin = _get_debugger_plugin()
	if debugger_plugin == null:
		return {"error": "Debugger plugin not available"}

	var session: EditorDebuggerSession = _get_active_session(debugger_plugin)
	if session == null:
		return {"error": "No active debug session"}

	session.send_message("step", [])
	_is_paused = false

	return {"result": {
		"success": true,
		"action": "step_into",
		"message": "Stepping into function call",
	}}


## Continue execution when paused at a breakpoint.
func continue_execution(_params: Dictionary) -> Dictionary:
	var debugger_plugin: EditorDebuggerPlugin = _get_debugger_plugin()
	if debugger_plugin == null:
		return {"error": "Debugger plugin not available"}

	var session: EditorDebuggerSession = _get_active_session(debugger_plugin)
	if session == null:
		return {"error": "No active debug session"}

	session.send_message("continue", [])
	_is_paused = false
	_last_call_stack.clear()

	return {"result": {
		"success": true,
		"action": "continue",
		"message": "Execution continued",
	}}


## Helper: Get the EditorDebuggerPlugin instance.
func _get_debugger_plugin() -> EditorDebuggerPlugin:
	if _plugin == null:
		return null
	if _debugger_plugin == null:
		# Access the debugger through the editor interface
		_debugger_plugin = EditorDebuggerPlugin.new()
		_plugin.add_debugger_plugin(_debugger_plugin)
	return _debugger_plugin


## Helper: Get the active debugger session.
func _get_active_session(debugger: EditorDebuggerPlugin) -> EditorDebuggerSession:
	if debugger == null:
		return null
	var sessions: Array = debugger.get_sessions()
	if sessions.is_empty():
		return null
	return sessions[0] as EditorDebuggerSession


## Helper: Execute a GDScript expression in the editor context.
func _execute_in_editor(code: String) -> Variant:
	# Wrap as EditorScript._run() for full editor API access (use this for void/multi-statement)
	var script: GDScript = GDScript.new()
	script.source_code = "extends EditorScript\n\nfunc _run() -> void:\n\t%s" % code.replace("\n", "\n\t")
	var err: Error = script.reload()
	if err != OK:
		# Fall back to RefCounted+return for value-returning expressions
		var s2: GDScript = GDScript.new()
		s2.source_code = "extends RefCounted\n\nfunc eval():\n\treturn %s" % code
		err = s2.reload()
		if err != OK:
			return {"error": "Failed to compile expression"}
		var inst2: Object = s2.new()
		if inst2.has_method("eval"):
			return inst2.eval()
		return null
	var instance: Object = script.new()
	if instance.has_method("_run"):
		instance._run()
		# Return success for void executions
		return "ok"
	return null
