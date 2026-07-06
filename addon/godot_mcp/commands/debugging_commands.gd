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
	# Skip when expression references edited_scene_root — Expression's base_obj can't resolve it.
	if not "edited_scene_root" in expression:
		var expr := Expression.new()
		var parse_err: Error = expr.parse(expression)
		if parse_err == OK:
			# Use EditorInterface as base so editor-specific members are accessible
			var base_obj: Object = EditorInterface.get_base_control()
			var result: Variant = expr.execute([], base_obj)
			if not expr.has_execute_failed():
				return {"result": {"expression": expression, "context": context, "value": result}}
			# Expression execution failed — fall through to GDScript

	# Fall back to GDScript (EditorScript with capture → void → RefCounted)
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
	var needs_preamble: bool = not _build_editor_script_preamble(code).is_empty()

	# Step 1: Try EditorScript with result capture.
	# This stores the last expression's value in _mcp_eval_result so it isn't discarded.
	# Activated for multi-statement code OR single-statement code needing a preamble
	# (e.g. edited_scene_root.name — single expression but needs preamble for resolution).
	if _is_multistatement(code) or needs_preamble:
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
					if val != "_MCP_NO_RESULT_":
						return val
					return "ok"

	# Step 2: EditorScript void wrapper (only for statements — lines that don't return values).
	# Single non-statement lines skip this step so Step 3 can capture their value.
	var lines: PackedStringArray = code.split("\n")
	var last_nonempty: String = ""
	for li in range(lines.size() - 1, -1, -1):
		if lines[li].strip_edges().length() > 0:
			last_nonempty = lines[li].strip_edges()
			break
	var skip_void: bool = not last_nonempty.is_empty() and not _is_statement(last_nonempty)
	if not skip_void:
		var preamble: String = _build_editor_script_preamble(code)
		var script: GDScript = GDScript.new()
		script.source_code = "extends EditorScript\n\nfunc _run() -> void:\n\t%s%s" % [preamble, _strip_and_indent(code)]
		var err: Error = script.reload()
		if err == OK:
			var instance: Object = script.new()
			if instance.has_method("_run"):
				instance._run()
				return "ok"
			return null

	# Step 3: RefCounted+return for value-returning single expressions.
	var preamble_3: String = _build_editor_script_preamble(code)
	var s2: GDScript = GDScript.new()
	if preamble_3.is_empty():
		s2.source_code = "extends RefCounted\n\nfunc eval():\n\treturn %s" % code
	else:
		s2.source_code = "extends RefCounted\n\nfunc eval():\n\t%sreturn %s" % [preamble_3, code]
	var err: Error = s2.reload()
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
		"await ", "yield ", "@", "assert ",
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
			# Handle return(value) without space — statement, not property access
			if next == 40: # open parenthesis
				return true
	# Comments
	if t.begins_with("#"):
		return true
	return false


## Helper: Build an EditorScript that captures the last expression's value.
## Returns empty string if the last line is a statement (can't capture).
## Uses sentinel "_MCP_NO_RESULT_" to distinguish null result from void.
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
	return "extends EditorScript\n\nvar _mcp_eval_result = \"_MCP_NO_RESULT_\"\n\nfunc _run() -> void:\n\t%s%s" % [preamble, _strip_and_indent(modified_code)]


## Helper: Build preamble lines for EditorScript (e.g. edited_scene_root alias).
## Checks for 'edited_scene_root' only in code portions (skips strings/comments).
func _build_editor_script_preamble(code: String) -> String:
	var in_tq: bool = false
	var in_bc: bool = false
	for line in code.split("\n"):
		var parsed: Dictionary = _find_code_segments(line, in_tq, in_bc)
		in_tq = parsed["in_tq"]
		in_bc = parsed["in_bc"]
		for seg in parsed["segments"]:
			var seg_start: int = seg[0]
			var seg_end: int = seg[1]
			var code_part: String = line.substr(seg_start, seg_end - seg_start)
			if "edited_scene_root" in code_part:
				# Already declared by caller?
				if not "var edited_scene_root" in code_part:
					return "var edited_scene_root = EditorInterface.get_edited_scene_root()\n\t"
	return ""


## Helper: Rewrite $NodePath / $"path" / $/absolute/path syntax to
## edited_scene_root.get_node(...). Skips $ inside string literals and comments.
func _rewrite_dollar_syntax(code: String) -> String:
	# $"path with spaces" pattern (quoted)
	var regex_quoted: RegEx = RegEx.new()
	regex_quoted.compile('\\$"([^"]+)"')
	# $identifier/Path and $/absolute/path patterns (unquoted)
	var regex_unquoted: RegEx = RegEx.new()
	regex_unquoted.compile('\\$([A-Za-z_/][A-Za-z0-9_/.]*)')

	var result_lines: PackedStringArray = []
	var in_tq: bool = false
	var in_bc: bool = false

	for line in code.split("\n"):
		var parsed: Dictionary = _find_code_segments(line, in_tq, in_bc)
		in_tq = parsed["in_tq"]
		in_bc = parsed["in_bc"]

		var new_line: String = ""
		var prev_end: int = 0
		for seg in parsed["segments"]:
			var seg_start: int = seg[0]
			var seg_end: int = seg[1]
			# Add non-code portion (strings, comments) as-is
			new_line += line.substr(prev_end, seg_start - prev_end)
			# Apply regex to code portion
			var code_part: String = line.substr(seg_start, seg_end - seg_start)
			code_part = regex_quoted.sub(code_part, 'edited_scene_root.get_node("$1")', true)
			code_part = regex_unquoted.sub(code_part, 'edited_scene_root.get_node("$1")', true)
			new_line += code_part
			prev_end = seg_end
		# Add remaining non-code portion
		new_line += line.substr(prev_end)
		result_lines.append(new_line)

	return "\n".join(result_lines)


## Helper: Detect 'await' keyword usage (not supported in sync eval context).
func _contains_await_keyword(code: String) -> bool:
	var in_triple_quote: bool = false
	var in_block_comment: bool = false
	for line in code.split("\n"):
		var i: int = 0
		var line_len: int = line.length()
		while i < line_len:
			if in_block_comment:
				if i + 1 < line_len and line[i] == 42 and line[i + 1] == 47:
					in_block_comment = false
					i += 2
					continue
				i += 1
				continue
			if in_triple_quote:
				if i + 2 < line_len and line[i] == 34 and line[i + 1] == 34 and line[i + 2] == 34:
					in_triple_quote = false
					i += 3
					continue
				i += 1
				continue
			if i + 1 < line_len and line[i] == 47 and line[i + 1] == 47:
				break
			if i + 1 < line_len and line[i] == 47 and line[i + 1] == 42:
				in_block_comment = true
				i += 2
				continue
			if i + 2 < line_len and line[i] == 34 and line[i + 1] == 34 and line[i + 2] == 34:
				in_triple_quote = true
				i += 3
				continue
			if line[i] == 34 or line[i] == 39:
				var q: int = line[i]
				i += 1
				while i < line_len:
					if line[i] == 92:
						i += 2
						continue
					if line[i] == q:
						i += 1
						break
					i += 1
				continue
			if line[i] == 35:
				break
			# Check for 'await' keyword at code position
			if i + 5 <= line_len and line.substr(i, 5) == "await":
				var after_ok: bool = (i + 5 >= line_len)
				if not after_ok:
					var next_ch: int = line[i + 5]
					after_ok = (next_ch == 32 or next_ch == 9 or next_ch == 40 or next_ch == 44 or next_ch == 61)
				if after_ok:
					var before_ok: bool = (i == 0)
					if not before_ok:
						var prev_ch: int = line[i - 1]
						before_ok = (prev_ch == 32 or prev_ch == 9 or prev_ch == 61 or prev_ch == 40 or prev_ch == 44)
					if before_ok:
						return true
			i += 1
	return false


## Helper: Find the end index of a string literal starting at line[pos].
## Returns the index after the closing quote, or line.length() if unterminated.
## pos must point at the opening quote character.
func _find_string_end(line: String, pos: int) -> int:
	var q: int = line[pos]
	var i: int = pos + 1
	var line_len: int = line.length()
	while i < line_len:
		if line[i] == 92: # backslash
			i += 2
			continue
		if line[i] == q:
			return i + 1
		i += 1
	return line_len


## Helper: Find code segment boundaries in a line, skipping strings and comments.
## Returns Dictionary with "segments" (Array of [start, end] pairs), "in_tq", "in_bc".
## GDScript passes bools by value, so state must be returned explicitly.
func _find_code_segments(line: String, in_tq: bool, in_bc: bool) -> Dictionary:
	var segments: Array = []
	var seg_start: int = -1
	var i: int = 0
	var line_len: int = line.length()

	while i < line_len:
		# Inside block comment - scan for closing */
		if in_bc:
			if i + 1 < line_len and line[i] == 42 and line[i + 1] == 47:
				in_bc = false
				i += 2
				if seg_start >= 0:
					segments.append([seg_start, i])
					seg_start = -1
				continue
			i += 1
			continue

		# Inside triple-quoted string - scan for closing """
		if in_tq:
			if i + 2 < line_len and line[i] == 34 and line[i + 1] == 34 and line[i + 2] == 34:
				in_tq = false
				i += 3
				if seg_start >= 0:
					segments.append([seg_start, i])
					seg_start = -1
				continue
			i += 1
			continue

		# Line comment //
		if i + 1 < line_len and line[i] == 47 and line[i + 1] == 47:
			if seg_start >= 0:
				segments.append([seg_start, i])
			return {"segments": segments, "in_tq": in_tq, "in_bc": in_bc}

		# Block comment start /*
		if i + 1 < line_len and line[i] == 47 and line[i + 1] == 42:
			in_bc = true
			if seg_start >= 0:
				segments.append([seg_start, i])
				seg_start = -1
			i += 2
			continue

		# Triple-quoted string """
		if i + 2 < line_len and line[i] == 34 and line[i + 1] == 34 and line[i + 2] == 34:
			in_tq = true
			if seg_start >= 0:
				segments.append([seg_start, i])
				seg_start = -1
			i += 3
			continue

		# Single/double-quoted string
		if line[i] == 34 or line[i] == 39:
			if seg_start >= 0:
				segments.append([seg_start, i])
				seg_start = -1
			i = _find_string_end(line, i)
			continue

		# Hash comment
		if line[i] == 35:
			if seg_start >= 0:
				segments.append([seg_start, i])
			return {"segments": segments, "in_tq": in_tq, "in_bc": in_bc}

		# Regular code character
		if seg_start < 0:
			seg_start = i
		i += 1

	if seg_start >= 0:
		segments.append([seg_start, line_len])
	return {"segments": segments, "in_tq": in_tq, "in_bc": in_bc}


## Helper: Normalize indentation — convert spaces/tabs to consistent tab-based indentation,
## preserving relative indentation levels. Adds one extra tab for the _run() body context.
func _strip_and_indent(code: String) -> String:
	var lines: PackedStringArray = code.split("\n")
	# First pass: determine minimum indentation (to strip common prefix)
	var min_indent: int = 999
	for line in lines:
		if line.strip_edges().is_empty():
			continue
		var leading: int = 0
		for ch in line:
			if ch == " ":
				leading += 1
			elif ch == "\t":
				leading += 4  # normalize tab to 4-space equivalent
			else:
				break
		min_indent = min(min_indent, leading)

	if min_indent == 999:
		min_indent = 0

	var indented: PackedStringArray = []
	for line in lines:
		var stripped: String = line.strip_edges()
		if stripped.is_empty():
			indented.append("")
			continue
		# Count leading whitespace and subtract common prefix
		var leading: int = 0
		for ch in line:
			if ch == " ":
				leading += 1
			elif ch == "\t":
				leading += 4
			else:
				break
		var relative: int = leading - min_indent
		# Convert to tabs (4-space = 1 tab), plus one for _run() body
		var tabs: int = relative / 4 + 1
		var prefix: String = ""
		for _t in range(tabs):
			prefix += "\t"
		indented.append(prefix + stripped)
	return "\n".join(indented)
