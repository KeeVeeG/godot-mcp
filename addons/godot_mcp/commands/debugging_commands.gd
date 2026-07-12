## Debugging commands module - 8 tools.
## Provides breakpoint management, call stack inspection, expression evaluation,
## and step-through debugging control.
##
## Architecture: Uses MCPDebuggerPlugin (EditorDebuggerPlugin subclass) for
## breakpoint sync, session management, and async debugger message capture.
## Registered via plugin.gd's add_debugger_plugin() in _enter_tree().
@tool
class_name MCPDebuggingCommands
extends RefCounted

var _plugin: EditorPlugin

## Reference to the MCPDebuggerPlugin (EditorDebuggerPlugin subclass)
## Set by plugin.gd after both are initialized.
var _mcp_debugger_plugin: MCPDebuggerPlugin = null

## Stored breakpoints: { "script_path:line": {path, line, condition} }
## These are local bookkeeping; actual breakpoint sync is handled by
## MCPDebuggerPlugin.queue_breakpoint() / session.set_breakpoint().
var _breakpoints: Dictionary = {}

## Godot singletons that Expression's base_obj (Control node) cannot resolve.
const _SINGLETON_NAMES: PackedStringArray = [
	"Engine", "OS", "Input", "DisplayServer", "ProjectSettings",
	"EditorInterface", "ClassDB", "ResourceLoader", "RenderingServer",
	"PhysicsServer2D", "PhysicsServer3D", "Time", "InputMap",
]


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func set_debugger_plugin(debugger_plugin: MCPDebuggerPlugin) -> void:
	_mcp_debugger_plugin = debugger_plugin
	print("[MCP DebugCmds] Debugger plugin wired")


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
	# Normalize: replace backslashes with forward slashes for Windows paths
	# and strip trailing whitespace.
	script_path = script_path.replace("\\", "/").strip_edges()
	var line: int = params.get("line", 0)
	var condition: String = params.get("condition", "")

	if script_path.is_empty():
		return {"error": "script_path is required"}
	if line < 1:
		return {"error": "line must be >= 1"}

	# Reject empty-string condition — use omit instead
	if "condition" in params and condition == "":
		return {"error": "condition must not be empty. Omit the parameter instead of passing an empty string."}

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

	# Store breakpoint locally
	var key: String = "%s:%d" % [script_path, line]
	var is_overwrite: bool = _breakpoints.has(key)
	_breakpoints[key] = {
		"path": script_path,
		"line": line,
		"condition": condition,
		"enabled": true,
	}

	# Sync to the debugger plugin (queues for session or applies immediately)
	if _mcp_debugger_plugin != null:
		_mcp_debugger_plugin.queue_breakpoint(script_path, line, condition, true)

	var overwrite_msg: String = " (overwritten)" if is_overwrite else ""
	return {"result": {
		"success": true,
		"path": script_path,
		"line": line,
		"condition": condition,
		"message": "Breakpoint set at %s:%d%s%s" % [script_path, line, " (conditional)" if condition != "" else "", overwrite_msg],
	}}


## Remove a breakpoint from a GDScript file at a specific line.
func remove_breakpoint(params: Dictionary) -> Dictionary:
	var script_path: String = params.get("script_path", "").replace("\\", "/").strip_edges()
	var line: int = params.get("line", 0)

	if script_path.is_empty():
		return {"error": "script_path is required"}
	if line < 1:
		return {"error": "line must be >= 1"}

	var key: String = "%s:%d" % [script_path, line]
	if not _breakpoints.has(key):
		return {"error": "No breakpoint at %s:%d" % [script_path, line]}

	_breakpoints.erase(key)

	# Remove from debugger plugin and active session
	if _mcp_debugger_plugin != null:
		_mcp_debugger_plugin.unqueue_breakpoint(script_path, line)

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
## The call stack is populated by MCPDebuggerPlugin._capture()
## when the game process responds to a stack_dump request.
## Get the current call stack when paused at a breakpoint.
## The built-in debugger handler automatically requests get_stack_dump when
## the game hits a breakpoint. The response populates last_call_stack via
## _on_editor_stack_dump() callback connected to ScriptEditorDebugger.stack_dump.
## We just return whatever was captured.
func get_call_stack(_params: Dictionary) -> Dictionary:
	if _mcp_debugger_plugin == null:
		return {"error": "Debugger plugin not available"}

	var session: EditorDebuggerSession = _mcp_debugger_plugin.get_active_session()
	if session == null:
		return {"error": "No active debug session. Start the game with debugging enabled."}

	if not session.is_active():
		return {"error": "Debug session is not active. Start the game."}

	# Request call stack from the running game (async message)
	session.send_message("get_stack_dump", [])
	# The response arrives asynchronously via MCPDebuggerPlugin._capture().
	# It populates mcp_debugger_plugin.last_call_stack.
	# Return last known state; caller should retry if empty.
	var frames: Array = _mcp_debugger_plugin.last_call_stack
	var paused: bool = _mcp_debugger_plugin.is_paused

	if frames.is_empty():
		return {"result": {
			"paused": paused,
			"frames": [],
			"message": "No call stack available yet. The debugger response is async — if the game is paused at a breakpoint, call again after a short delay.",
		}}

	return {"result": {
		"paused": paused,
		"frame_count": frames.size(),
		"frames": frames,
	}}


## Evaluate a GDScript expression in the specified context.
## - context="editor": Evaluates in the editor process (Expression class / EditorScript).
## - context="game": Evaluates in the running game via debugger session (requires game
##   to be paused at a breakpoint for access to stack frame variables).
func evaluate_expression(params: Dictionary) -> Dictionary:
	var expression: String = params.get("expression", "")
	var context: String = params.get("context", "editor")

	if expression.is_empty():
		return {"error": "expression is required"}

	# Game context: evaluate in the running game process
	if context == "game":
		return await _evaluate_in_game_context(expression)

	# Editor context (default)
	# Pre-process: rewrite $NodePath / $"path" to edited_scene_root.get_node(...)
	expression = _rewrite_dollar_syntax(expression)

	# Pre-process: detect unsupported await keyword
	if _contains_await_keyword(expression):
		return {"error": "'await' is not supported in expression evaluation. For async operations, run the scene first and use context='game'."}

	# Try Expression class first (handles void methods correctly)
	# Skip when expression references edited_scene_root — Expression's base_obj can't resolve it.
	# Also skip for singleton references (Engine, OS, Input, etc.) — Control nodes lack those.
	if not "edited_scene_root" in expression and not _references_singleton(expression):
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


## Evaluate expression in the running game context via the debugger session.
## Requires the game to be running AND paused at a breakpoint.
func _evaluate_in_game_context(expression: String) -> Dictionary:
	if _mcp_debugger_plugin == null:
		return {"error": "Debugger plugin not available"}

	var session: EditorDebuggerSession = _mcp_debugger_plugin.get_active_session()
	if session == null or not session.is_active():
		return {"error": "Game is not running. Start the scene first, then use context='game'."}

	if not session.is_breaked():
		return {"error": "Game is not paused at a breakpoint. Set a breakpoint and wait for it to trigger before using context='game' for expression evaluation."}

	# Send evaluate request via the debugger protocol
	session.send_message("evaluate", [expression, 0])

	# Wait for the async response via signal (with timeout)
	var start: float = Time.get_unix_time_from_system()
	const TIMEOUT: float = 5.0
	while _mcp_debugger_plugin._eval_result == null:
		if Time.get_unix_time_from_system() - start > TIMEOUT:
			return {"error": "Expression evaluation timed out (%.1fs)" % TIMEOUT}
		await _plugin.get_tree().process_frame

	var result: Variant = _mcp_debugger_plugin._eval_result
	_mcp_debugger_plugin._eval_result = null

	return {"result": {"expression": expression, "context": "game", "value": result}}


## Step over the current line when paused at a breakpoint.
func step_over(_params: Dictionary) -> Dictionary:
	if _mcp_debugger_plugin == null:
		return {"error": "Debugger plugin not available"}

	var session: EditorDebuggerSession = _mcp_debugger_plugin.get_active_session()
	if session == null or not session.is_active():
		return {"error": "No active debug session. Start the game with debugging enabled."}

	if not session.is_breaked():
		return {"error": "Cannot step over — game is not paused at a breakpoint"}

	session.send_message("next", [])

	return {"result": {
		"success": true,
		"action": "step_over",
		"message": "Stepping over current line",
	}}


## Step into the current function call when paused.
func step_into(_params: Dictionary) -> Dictionary:
	if _mcp_debugger_plugin == null:
		return {"error": "Debugger plugin not available"}

	var session: EditorDebuggerSession = _mcp_debugger_plugin.get_active_session()
	if session == null or not session.is_active():
		return {"error": "No active debug session. Start the game with debugging enabled."}

	if not session.is_breaked():
		return {"error": "Cannot step into — game is not paused at a breakpoint"}

	session.send_message("step", [])

	return {"result": {
		"success": true,
		"action": "step_into",
		"message": "Stepping into function call",
	}}


## Continue execution when paused at a breakpoint.
func continue_execution(_params: Dictionary) -> Dictionary:
	if _mcp_debugger_plugin == null:
		return {"error": "Debugger plugin not available"}

	var session: EditorDebuggerSession = _mcp_debugger_plugin.get_active_session()
	if session == null or not session.is_active():
		return {"error": "No active debug session. Start the game with debugging enabled."}

	if not session.is_breaked():
		return {"error": "Cannot continue — game is not paused at a breakpoint"}

	session.send_message("continue", [])

	return {"result": {
		"success": true,
		"action": "continue",
		"message": "Execution continued",
	}}


# ═══════════════════════════════════════════════════════════════════════
# Helpers — preserved from original implementations
# ═══════════════════════════════════════════════════════════════════════


## Helper: Check if expression references a Godot singleton as a bare word.
## Returns true for "Engine.get_frames_per_second()" but false for "node.engine_speed".
func _references_singleton(expr: String) -> bool:
	for name in _SINGLETON_NAMES:
		var idx: int = expr.find(name)
		while idx >= 0:
			# Must be a word start (not preceded by dot or identifier char)
			var before_ok: bool = (idx == 0)
			if not before_ok:
				var prev = expr[idx - 1]
				# prev is a String of length 1. Check if it's an identifier character.
				before_ok = not (
					prev == "." or prev == "_" or
					(prev >= "A" and prev <= "Z") or
					(prev >= "a" and prev <= "z") or
					(prev >= "0" and prev <= "9")
				)
			# Must be a word end (not followed by identifier char)
			var end_pos: int = idx + name.length()
			var after_ok: bool = (end_pos >= expr.length())
			if not after_ok:
				var next_ch = expr[end_pos]
				after_ok = not (
					next_ch == "_" or
					(next_ch >= "A" and next_ch <= "Z") or
					(next_ch >= "a" and next_ch <= "z") or
					(next_ch >= "0" and next_ch <= "9")
				)
			if before_ok and after_ok:
				return true
			idx = expr.find(name, idx + 1)
	return false


## Helper: Reload a GDScript with editor warnings suppressed.
## Saves and restores the original warning setting to avoid side effects.
func _reload_quiet(script: GDScript) -> Error:
	var setting_path: String = "debug/gdscript/warnings/enable"
	var orig_val: Variant = ProjectSettings.get_setting(setting_path)
	ProjectSettings.set_setting(setting_path, false)
	var err: Error = script.reload(true)
	ProjectSettings.set_setting(setting_path, orig_val)
	return err


## Helper: Execute a GDScript expression in the editor context.
## Three-step fallback: EditorScript with capture → EditorScript void → RefCounted.
func _execute_in_editor(code: String) -> Variant:
	var needs_preamble: bool = not _build_editor_script_preamble(code).is_empty()

	# Step 1: Try EditorScript with result capture.
	if _is_multistatement(code) or needs_preamble:
		var capture_src: String = _build_capture_script(code)
		if not capture_src.is_empty():
			var script: GDScript = GDScript.new()
			script.source_code = capture_src
			var err: Error = _reload_quiet(script)
			if err == OK:
				var instance: Object = script.new()
				if instance.has_method("_run"):
					instance._run()
					var val: Variant = instance.get("_mcp_eval_result")
					if val != "_MCP_NO_RESULT_":
						return val
					return "ok"

	# Step 2: EditorScript void wrapper
	var lines: PackedStringArray = code.split("\n")
	var last_nonempty: String = ""
	for li in range(lines.size() - 1, -1, -1):
		if lines[li].strip_edges().length() > 0:
			last_nonempty = lines[li].strip_edges()
			break
	var skip_void: bool = not _is_multistatement(code) and not last_nonempty.is_empty() and not _is_statement(last_nonempty)
	if not skip_void:
		var preamble: String = _build_editor_script_preamble(code)
		var script: GDScript = GDScript.new()
		script.source_code = "extends EditorScript\n\nfunc _run() -> void:\n\t%s%s" % [preamble, _strip_and_indent(code)]
		var err: Error = _reload_quiet(script)
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
	var err: Error = _reload_quiet(s2)
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
	var prefixes: PackedStringArray = [
		"var ", "const ", "for ", "while ", "if ", "elif ",
		"func ", "class ", "match ", "signal ", "enum ",
		"await ", "yield ", "@", "assert ",
	]
	for p in prefixes:
		if t.begins_with(p):
			return true
	if t == "pass" or t == "return" or t == "break" or t == "continue" or t == "else":
		return true
	if t.begins_with("else:"):
		return true
	for kw in ["return", "break", "continue", "pass", "assert"]:
		if t.begins_with(kw) and t.length() > kw.length():
			var next = t[kw.length()]
			if next == " " or next == "\t":
				return true
			if next == "(":
				return true
	if t.begins_with("#"):
		return true
	return false


## Helper: Build an EditorScript that captures the last expression's value.
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

	var leading_ws: String = ""
	for j in range(last_line_raw.length()):
		var ch = last_line_raw[j]
		if ch == " " or ch == "\t":
			leading_ws += ch
		else:
			break

	lines[last_nonempty_idx] = leading_ws + "_mcp_eval_result = " + last_line_stripped
	var modified_code: String = "\n".join(lines)

	var preamble: String = _build_editor_script_preamble(code)
	return "extends EditorScript\n\nvar _mcp_eval_result = \"_MCP_NO_RESULT_\"\n\nfunc _run() -> void:\n\t%s%s" % [preamble, _strip_and_indent(modified_code)]


## Helper: Build preamble lines for EditorScript (e.g. edited_scene_root alias).
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
				if not "var edited_scene_root" in code_part:
					return "var edited_scene_root = EditorInterface.get_edited_scene_root()\n\t"
	return ""


## Helper: Rewrite $NodePath / $"path" / $/absolute/path syntax to
## edited_scene_root.get_node(...). Skips $ inside string literals and comments.
func _rewrite_dollar_syntax(code: String) -> String:
	var regex_quoted: RegEx = RegEx.new()
	regex_quoted.compile('\\$"([^"]+)"')
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
			new_line += line.substr(prev_end, seg_start - prev_end)
			var code_part: String = line.substr(seg_start, seg_end - seg_start)
			code_part = regex_quoted.sub(code_part, 'edited_scene_root.get_node("$1")', true)
			code_part = regex_unquoted.sub(code_part, 'edited_scene_root.get_node("$1")', true)
			new_line += code_part
			prev_end = seg_end
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
				if i + 1 < line_len and line[i] == "*" and line[i + 1] == "/":
					in_block_comment = false
					i += 2
					continue
				i += 1
				continue
			if in_triple_quote:
				if i + 2 < line_len and line[i] == "\"" and line[i + 1] == "\"" and line[i + 2] == "\"":
					in_triple_quote = false
					i += 3
					continue
				i += 1
				continue
			if i + 1 < line_len and line[i] == "/" and line[i + 1] == "/":
				break
			if i + 1 < line_len and line[i] == "/" and line[i + 1] == "*":
				in_block_comment = true
				i += 2
				continue
			if i + 2 < line_len and line[i] == "\"" and line[i + 1] == "\"" and line[i + 2] == "\"":
				in_triple_quote = true
				i += 3
				continue
			if line[i] == "\"" or line[i] == "'":
				var q = line[i]
				i += 1
				while i < line_len:
					if line[i] == "\\":
						i += 2
						continue
					if line[i] == q:
						i += 1
						break
					i += 1
				continue
			if line[i] == "#":
				break
			if i + 5 <= line_len and line.substr(i, 5) == "await":
				var after_ok: bool = (i + 5 >= line_len)
				if not after_ok:
					var next_ch = line[i + 5]
					after_ok = (next_ch == " " or next_ch == "\t" or next_ch == "(" or next_ch == "," or next_ch == "=")
				if after_ok:
					var before_ok: bool = (i == 0)
					if not before_ok:
						var prev_ch = line[i - 1]
						before_ok = (prev_ch == " " or prev_ch == "\t" or prev_ch == "=" or prev_ch == "(" or prev_ch == ",")
					if before_ok:
						return true
			i += 1
	return false


## Helper: Find the end index of a string literal starting at line[pos].
func _find_string_end(line: String, pos: int) -> int:
	var q = line[pos]
	var i: int = pos + 1
	var line_len: int = line.length()
	while i < line_len:
		if line[i] == "\\":
			i += 2
			continue
		if line[i] == q:
			return i + 1
		i += 1
	return line_len


## Helper: Find code segment boundaries in a line, skipping strings and comments.
func _find_code_segments(line: String, in_tq: bool, in_bc: bool) -> Dictionary:
	var segments: Array = []
	var seg_start: int = -1
	var i: int = 0
	var line_len: int = line.length()

	while i < line_len:
		if in_tq:
			if i + 2 < line_len and line[i] == "\"" and line[i + 1] == "\"" and line[i + 2] == "\"":
				in_tq = false
				i += 3
				if seg_start >= 0:
					segments.append([seg_start, i])
					seg_start = -1
				continue
			i += 1
			continue

		if i + 2 < line_len and line[i] == "\"" and line[i + 1] == "\"" and line[i + 2] == "\"":
			in_tq = true
			if seg_start >= 0:
				segments.append([seg_start, i])
				seg_start = -1
			i += 3
			continue

		if line[i] == "\"" or line[i] == "'":
			if seg_start >= 0:
				segments.append([seg_start, i])
				seg_start = -1
			i = _find_string_end(line, i)
			continue

		if line[i] == "#":
			if seg_start >= 0:
				segments.append([seg_start, i])
			return {"segments": segments, "in_tq": in_tq, "in_bc": in_bc}

		if seg_start < 0:
			seg_start = i
		i += 1

	if seg_start >= 0:
		segments.append([seg_start, line_len])
	return {"segments": segments, "in_tq": in_tq, "in_bc": in_bc}


## Helper: Normalize indentation — convert spaces/tabs to consistent tab-based indentation.
func _strip_and_indent(code: String) -> String:
	var lines: PackedStringArray = code.split("\n")
	var min_indent: int = 999
	for line in lines:
		if line.strip_edges().is_empty():
			continue
		var leading: int = 0
		for ch in line:
			if ch == " ":
				leading += 1
			elif ch == "\t":
				leading += 4
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
		var leading: int = 0
		for ch in line:
			if ch == " ":
				leading += 1
			elif ch == "\t":
				leading += 4
			else:
				break
		var relative: int = leading - min_indent
		var tabs: int = relative / 4 + 1
		var prefix: String = ""
		for _t in range(tabs):
			prefix += "\t"
		indented.append(prefix + stripped)
	return "\n".join(indented)
