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

	# Pre-process: rewrite $NodePath / $"path" to edited_scene_root.get_node(...)
	expression = _rewrite_dollar_syntax(expression)

	# Pre-process: detect unsupported await keyword
	if _contains_await_keyword(expression):
		return {"error": "'await' is not supported in expression evaluation. For async operations, run the scene first and use context='game'."}

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
## Three-step fallback: EditorScript with capture → EditorScript void → RefCounted.
func _execute_in_editor(code: String) -> Variant:
	var is_multi: bool = _is_multistatement(code)

	# Step 1: For multi-statement code, try EditorScript with result capture.
	# This stores the last expression's value in _mcp_eval_result so it isn't discarded.
	if is_multi:
		var capture_src: String = _build_capture_script(code)
		if not capture_src.is_empty():
			var script: GDScript = GDScript.new()
			script.source_code = capture_src
			var err: Error = script.reload()
			if err == OK:
				var instance: Object = script.new()
				if instance.has_method("_run"):
					instance._run()
					var val: Variant = instance.get("_mcp_eval_result")
					if val != null:
						return val
					return "ok"

	# Step 2: EditorScript void wrapper (handles both single and multi-statement).
	var preamble: String = _build_editor_script_preamble(code)
	var script: GDScript = GDScript.new()
	script.source_code = "extends EditorScript\n\nfunc _run() -> void:\n\t%s%s" % [preamble, code.replace("\n", "\n\t")]
	var err: Error = script.reload()
	if err == OK:
		var instance: Object = script.new()
		if instance.has_method("_run"):
			instance._run()
			return "ok"
		return null

	# Step 3: RefCounted+return for value-returning single expressions.
	var s2: GDScript = GDScript.new()
	s2.source_code = "extends RefCounted\n\nfunc eval():\n\treturn %s" % code
	err = s2.reload()
	if err != OK:
		return {"error": "Failed to compile expression"}
	var inst2: Object = s2.new()
	if inst2.has_method("eval"):
		return inst2.eval()
	return null


## Helper: Check if code has multiple non-empty, non-comment lines.
func _is_multistatement(code: String) -> bool:
	var count: int = 0
	for line in code.split("\n"):
		var stripped: String = line.strip_edges()
		if stripped.length() > 0 and not stripped.begins_with("#"):
			count += 1
			if count > 1:
				return true
	return false


## Helper: Check if a GDScript line is a statement (not a capturable expression).
func _is_statement(line: String) -> bool:
	var t: String = line.strip_edges()
	if t.is_empty():
		return true
	# Keywords always followed by space/identifier/etc.
	var prefixes: PackedStringArray = [
		"var ", "const ", "for ", "while ", "if ", "elif ",
		"func ", "class ", "match ", "signal ", "enum ",
		"await ", "yield ", "@",
	]
	for p in prefixes:
		if t.begins_with(p):
			return true
	# Standalone keywords or keywords followed by colon
	if t == "pass" or t == "return" or t == "break" or t == "continue" or t == "else":
		return true
	if t.begins_with("else:"):
		return true
	# Keywords that can be standalone or followed by expression
	for kw in ["return", "break", "continue", "pass"]:
		if t.begins_with(kw) and t.length() > kw.length():
			var next: int = t[kw.length()]
			if next == 32 or next == 9: # space or tab
				return true
	# Comments
	if t.begins_with("#"):
		return true
	return false


## Helper: Build an EditorScript that captures the last expression's value.
## Returns empty string if the last line is a statement (can't capture).
func _build_capture_script(code: String) -> String:
	var lines: PackedStringArray = code.split("\n")
	var last_nonempty_idx: int = -1
	for i in range(lines.size() - 1, -1, -1):
		if lines[i].strip_edges().length() > 0:
			last_nonempty_idx = i
			break
	if last_nonempty_idx < 0:
		return ""

	var last_line_raw: String = lines[last_nonempty_idx]
	var last_line_stripped: String = last_line_raw.strip_edges()
	if _is_statement(last_line_stripped):
		return ""

	# Preserve leading whitespace of the original last line
	var leading_ws: String = ""
	for j in range(last_line_raw.length()):
		var cp: int = last_line_raw[j]
		if cp == 32 or cp == 9: # space or tab
			leading_ws += char(cp)
		else:
			break

	# Replace last line with capture assignment
	lines[last_nonempty_idx] = leading_ws + "_mcp_eval_result = " + last_line_stripped
	var modified_code: String = "\n".join(lines)

	var preamble: String = _build_editor_script_preamble(code)
	return "extends EditorScript\n\nvar _mcp_eval_result = null\n\nfunc _run() -> void:\n\t%s%s" % [preamble, modified_code.replace("\n", "\n\t")]


## Helper: Build preamble lines for EditorScript (e.g. edited_scene_root alias).
func _build_editor_script_preamble(code: String) -> String:
	var preamble: String = ""
	# Make edited_scene_root available in EditorScript context via get_scene()
	if "edited_scene_root" in code and not "var edited_scene_root" in code:
		preamble = "var edited_scene_root = get_scene()\n\t"
	return preamble


## Helper: Rewrite $NodePath / $"path" syntax to edited_scene_root.get_node(...).
func _rewrite_dollar_syntax(code: String) -> String:
	var result: String = code
	# $"path with spaces" pattern
	var regex_quoted: RegEx = RegEx.new()
	regex_quoted.compile('\\$"([^"]+)"')
	result = regex_quoted.sub(result, 'edited_scene_root.get_node("$1")', true)
	# $identifier/Path pattern (unquoted)
	var regex_unquoted: RegEx = RegEx.new()
	regex_unquoted.compile('\\$([A-Za-z_][A-Za-z0-9_/]*)')
	result = regex_unquoted.sub(result, 'edited_scene_root.get_node("$1")', true)
	return result


## Helper: Detect 'await' keyword usage (not supported in sync eval context).
func _contains_await_keyword(code: String) -> bool:
	for line in code.split("\n"):
		var stripped: String = line.strip_edges()
		if stripped.begins_with("#"):
			continue
		if stripped.begins_with("await ") or stripped.begins_with("await(") or stripped == "await":
			return true
		# Check for await after assignment or other operators
		var pos: int = stripped.find("await ")
		if pos > 0:
			var before: int = stripped[pos - 1]
			if before == 32 or before == 61 or before == 40 or before == 44 or before == 9:
				return true
	return false
