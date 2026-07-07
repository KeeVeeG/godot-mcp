# Debugging Tools — Test Plan

**Source file:** `server/src/tools/debugging.ts`  
**Number of tools:** 8  
**Godot bridge commands:** `set_breakpoint`, `remove_breakpoint`, `list_breakpoints`, `get_call_stack`, `evaluate_expression`, `step_over`, `step_into`, `continue_execution`

---

## Tool 1: `set_breakpoint`

**Description:** Set a breakpoint in a GDScript file at a specific line, optionally with a condition  
**Handler:** `callGodot(bridge, 'set_breakpoint', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `script_path` | `string` (ScriptPath) | **Yes** | — | Script file path (e.g. `'res://scripts/player.gd'`) |
| `line` | `number` (int, >= 1) | **Yes** | — | Line number to set breakpoint on |
| `condition` | `string` | No | — | Optional condition expression — breakpoint only triggers when true |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 1 | Set breakpoint on a valid script at a valid line | `{"script_path": "res://scripts/player.gd", "line": 10}` | Success; breakpoint set at line 10 | Simplest valid invocation. |
| 2 | Set breakpoint with a condition | `{"script_path": "res://scripts/player.gd", "line": 15, "condition": "health <= 0"}` | Success; conditional breakpoint set | Condition is a GDScript expression evaluated at runtime. |
| 3 | Set breakpoint on the first line of a script | `{"script_path": "res://scripts/player.gd", "line": 1}` | Success; breakpoint set at line 1 | Boundary: minimum valid line number. |
| 4 | Set breakpoints on multiple scripts (sequential calls) | Call tool twice with different `script_path` values | Both succeed; two breakpoints on two scripts | Verify multi-script breakpoint support. |
| 5 | Set multiple breakpoints on the same script (different lines) | Call tool twice: line 5 and line 20 on same script | Both succeed; two breakpoints on one script | Verify multiple breakpoints per file. |
| 6 | Set breakpoint with a complex condition expression | `{"script_path": "res://scripts/enemy.gd", "line": 42, "condition": "is_alive and distance_to_player < 100 and not is_stunned"}` | Success; complex conditional breakpoint set | GDScript expression with multiple operators. |
| 7 | Set breakpoint with empty string condition | `{"script_path": "res://scripts/player.gd", "line": 10, "condition": ""}` | Passes Zod (string not restricted); Godot may treat as no-condition or reject | Empty string is valid per Zod. Godot behavior TBD. |
| 8 | Set breakpoint with condition containing special characters | `{"script_path": "res://scripts/player.gd", "line": 5, "condition": "name == \"Player 1\""}` | Success if properly escaped; breakpoint set | String literals inside condition with escaped quotes. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 9 | Missing required `script_path` | `{"line": 10}` | Zod validation error | `script_path` has no `.optional()`. |
| 10 | Missing required `line` | `{"script_path": "res://scripts/player.gd"}` | Zod validation error | `line` has no `.optional()` or `.default()`. |
| 11 | `script_path` as a number | `{"script_path": 123, "line": 10}` | Zod validation error | `z.string()` rejects numbers. |
| 12 | `script_path` as a boolean | `{"script_path": true, "line": 10}` | Zod validation error | Type mismatch. |
| 13 | `line` as a string | `{"script_path": "res://scripts/player.gd", "line": "10"}` | Zod validation error | `z.number().int()` rejects strings. |
| 14 | `line` as a float (non-integer) | `{"script_path": "res://scripts/player.gd", "line": 10.5}` | Zod validation error | `.int()` constraint enforces integer. |
| 15 | `line` as zero | `{"script_path": "res://scripts/player.gd", "line": 0}` | Zod validation error | `.min(1)` disallows zero. |
| 16 | `line` as negative | `{"script_path": "res://scripts/player.gd", "line": -1}` | Zod validation error | `.min(1)` disallows negatives. |
| 17 | `line` as a very large number | `{"script_path": "res://scripts/player.gd", "line": 9999999}` | Passes Zod; Godot may reject (line beyond file length) | No `.max()` constraint. Godot should report error for invalid line. |
| 18 | `condition` as a number | `{"script_path": "res://scripts/player.gd", "line": 10, "condition": 42}` | Zod validation error | `z.string().optional()` rejects non-strings when provided. |
| 19 | `condition` as a boolean | `{"script_path": "res://scripts/player.gd", "line": 10, "condition": true}` | Zod validation error | Type mismatch for optional field. |
| 20 | Script file does not exist | `{"script_path": "res://scripts/nonexistent.gd", "line": 10}` | Passes Zod; Godot returns error (file not found) | Server forwards; Godot plugin handles the error. |
| 21 | Invalid script path format (not `res://`) | `{"script_path": "/absolute/path/script.gd", "line": 10}` | Passes Zod (just a string); Godot may reject | ScriptPath has no path format validation in Zod. |
| 22 | Relative script path | `{"script_path": "../other_project/script.gd", "line": 10}` | Passes Zod; Godot may reject | Non-standard path. |
| 23 | Call when editor is disconnected | `{"script_path": "res://scripts/player.gd", "line": 10}` | Connection error or timeout | Bridge unavailable. |
| 24 | Duplicate breakpoint (same script, same line, same condition) | Call with same params twice | First: success. Second: Godot may return success (idempotent) or error (already exists) | Behavior depends on Godot plugin implementation. |
| 25 | Set breakpoint with condition on a non-executable line (comment/blank) | `{"script_path": "res://scripts/player.gd", "line": 1, "condition": "true"}` (line 1 is `extends`) | Passes Zod; Godot may warn or silently move to next executable line | Line may not be debuggable. |

### Boolean / Null / Boundary

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 26 | `line` at minimum valid value (1) | `{"script_path": "res://scripts/player.gd", "line": 1}` | Success or Godot-line-error | Tests `.min(1)`. |
| 27 | `condition` explicitly set to `null` | `{"script_path": "res://scripts/player.gd", "line": 10, "condition": null}` | Zod strips `null` optional; treated as no condition | Zod `.optional()` behavior: `null` → field omitted. |
| 28 | Very long `script_path` string | `{"script_path": "<500+ character path>", "line": 10}` | Passes Zod; Godot likely rejects | No max length on ScriptPath. |
| 29 | Very long `condition` string | `{"script_path": "res://scripts/player.gd", "line": 10, "condition": "<10,000 char expression>"}` | Passes Zod; Godot may truncate or reject | No max length on condition. |

---

## Tool 2: `remove_breakpoint`

**Description:** Remove a breakpoint from a GDScript file at a specific line  
**Handler:** `callGodot(bridge, 'remove_breakpoint', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `script_path` | `string` (ScriptPath) | **Yes** | — | Script file path (e.g. `'res://scripts/player.gd'`) |
| `line` | `number` (int, >= 1) | **Yes** | — | Line number of the breakpoint to remove |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 30 | Remove an existing breakpoint | `{"script_path": "res://scripts/player.gd", "line": 10}` | Success; breakpoint removed | Requires breakpoint set first via `set_breakpoint`. |
| 31 | Remove breakpoint from a script that has multiple breakpoints | `{"script_path": "res://scripts/player.gd", "line": 20}` (after setting at lines 10 and 20) | Success; only line 20 removed, line 10 remains | Verify non-destructive removal of other breakpoints. |
| 32 | Remove the last breakpoint from a script | `{"script_path": "res://scripts/player.gd", "line": 10}` (remove the only remaining one) | Success; script now has zero breakpoints | Verify clean removal. |
| 33 | Remove breakpoint at line 1 | `{"script_path": "res://scripts/player.gd", "line": 1}` | Success if breakpoint exists there; otherwise error | Boundary: minimum line number. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 34 | Remove a breakpoint that does not exist | `{"script_path": "res://scripts/player.gd", "line": 99}` (no breakpoint there) | Godot returns error or no-op success | Behavior depends on plugin: error vs silent success. |
| 35 | Remove from a script that has never had breakpoints | `{"script_path": "res://scripts/player.gd", "line": 5}` | Godot returns error or no-op success | Clean script, no prior breakpoints. |
| 36 | Remove from a non-existent script file | `{"script_path": "res://scripts/nonexistent.gd", "line": 10}` | Passes Zod; Godot returns error (file not found) | Invalid file path. |
| 37 | Missing required `script_path` | `{"line": 10}` | Zod validation error | Required param missing. |
| 38 | Missing required `line` | `{"script_path": "res://scripts/player.gd"}` | Zod validation error | Required param missing. |
| 39 | `line` as zero | `{"script_path": "res://scripts/player.gd", "line": 0}` | Zod validation error | `.min(1)` rejects zero. |
| 40 | `line` as negative | `{"script_path": "res://scripts/player.gd", "line": -5}` | Zod validation error | `.min(1)` rejects negatives. |
| 41 | `line` as a float | `{"script_path": "res://scripts/player.gd", "line": 10.5}` | Zod validation error | `.int()` rejects floats. |
| 42 | `line` as a string | `{"script_path": "res://scripts/player.gd", "line": "10"}` | Zod validation error | Type mismatch. |
| 43 | `script_path` as a number | `{"script_path": 999, "line": 10}` | Zod validation error | Type mismatch. |
| 44 | Call when editor is disconnected | `{"script_path": "res://scripts/player.gd", "line": 10}` | Connection error or timeout | Bridge unavailable. |
| 45 | Remove breakpoint twice from same location | Call `remove_breakpoint` twice with same params | First: success. Second: error or no-op depending on plugin | Idempotency test. |
| 46 | Set, remove, re-set same breakpoint | `set_breakpoint` → `remove_breakpoint` → `set_breakpoint` | All three succeed | Full lifecycle test: create → remove → recreate. |
| 47 | Remove with extremely large line number | `{"script_path": "res://scripts/player.gd", "line": 2147483647}` | Passes Zod; Godot returns error (no breakpoint there) | Max int line. No `.max()` in Zod. |

---

## Tool 3: `list_breakpoints`

**Description:** List all active breakpoints across all scripts  
**Handler:** `callGodot(bridge, 'list_breakpoints')` (no args forwarded)

**Parameters:** None (empty `inputSchema`)

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 48 | Call with no breakpoints set | `{}` | Empty list or empty array | Idempotent — no breakpoints. |
| 49 | Call with one breakpoint set | `{}` (after `set_breakpoint`) | List containing 1 entry: `{"script_path": "...", "line": 10}` | Verifies single breakpoint visibility. |
| 50 | Call with multiple breakpoints across scripts | `{}` (after setting breakpoints on 2+ scripts) | List containing all entries, each with script_path, line, and optionally condition | Cross-script aggregation. |
| 51 | Call with multiple breakpoints on the same script | `{}` (after setting lines 5, 10, 15 on same script) | List containing 3 entries for that script | Multiple breakpoints per file. |
| 52 | Call with conditional breakpoints | `{}` (after setting one with condition) | Entry includes the condition string | Verify condition is returned. |
| 53 | Call after removing all breakpoints | `{}` (after remove last) | Empty list | State correctly reflects removals. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 54 | Call with extra ignored arguments | `{"ignored": true}` | Valid list (extra args ignored) | Zod ignores unknown keys (empty schema). |
| 55 | Call with `null` body | `null` | Valid list (likely empty or current state) | MCP SDK may coerce null to `{}`. |
| 56 | Call when editor is disconnected | `{}` | Connection error or timeout | Bridge unavailable. |
| 57 | Call twice in a row with no changes | `{}` (two sequential calls) | Identical lists both times | Idempotency — read-only tool. |
| 58 | List after setting breakpoint on non-existent script (if plugin allows it) | `{}` | List may or may not include invalid breakpoint | Depends on whether plugin validates at set time or stores blindly. |

---

## Tool 4: `get_call_stack`

**Description:** Get the current call stack with local variables when the game is paused at a breakpoint  
**Handler:** `callGodot(bridge, 'get_call_stack')` (no args forwarded)

**Parameters:** None (empty `inputSchema`)

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 59 | Call while paused at a breakpoint (game running, execution suspended) | `{}` | Call stack with frames, each containing: file, function name, line number, local variables | Core use case. Requires active game + breakpoint hit. |
| 60 | Call while paused at a breakpoint in a nested function | `{}` | Call stack with multiple frames: deepest frame first, then caller, then caller's caller, etc. | Tests multi-level call stacks. |
| 61 | Verify local variables in call stack frames | `{}` | Each frame includes local variable names and their runtime values | Requires inspecting actual content, not just presence. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 62 | Call when game is NOT running | `{}` | Godot returns error or empty result (no paused execution) | No execution context. |
| 63 | Call when game is running but NOT paused at a breakpoint | `{}` | Godot returns error or empty result | Execution is active, not suspended. |
| 64 | Call when game is stopped (after playing and stopping) | `{}` | Error or empty — no execution context | Editor mode, no game running. |
| 65 | Call with extra ignored arguments | `{"something": "extra"}` | Valid behavior (extra args ignored) | Zod ignores unknown keys. |
| 66 | Call when editor is disconnected | `{}` | Connection error or timeout | Bridge unavailable. |
| 67 | Call twice in a row at the same breakpoint | `{}` (two sequential calls) | Identical call stacks both times | Idempotency — read-only; no state change. |
| 68 | Call after `step_over` (still at next line) | `{}` | Call stack updated; line numbers advanced by 1, local variables may have changed | Verify stack updates after stepping. |
| 69 | Call after `continue_execution` (game running again) | `{}` | Error — no longer paused | Execution resumed, no call stack available. |

---

## Tool 5: `evaluate_expression`

**Description:** Evaluate a GDScript expression in the editor or running game context  
**Handler:** `callGodot(bridge, 'evaluate_expression', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `expression` | `string` (GDScriptCode) | **Yes** | — | GDScript expression to evaluate |
| `context` | `enum('editor', 'game')` | No | `'editor'` | Context to evaluate in (default: editor) |

**Enum values for `context`:** `'editor'`, `'game'`

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 70 | Evaluate simple expression in editor context (default) | `{"expression": "2 + 2"}` | Returns `4` | Simplest invocation. Context defaults to `'editor'`. |
| 71 | Evaluate expression explicitly in editor context | `{"expression": "2 + 2", "context": "editor"}` | Returns `4` | Explicit context matches default. |
| 72 | Evaluate expression in game context (game running) | `{"expression": "get_tree().get_node_count()", "context": "game"}` | Returns the current node count in the running game | Runtime introspection. Requires game running. |
| 73 | Evaluate variable access in game context (at breakpoint) | `{"expression": "health", "context": "game"}` | Returns current value of `health` | Requires game paused at a breakpoint where `health` is in scope. |
| 74 | Evaluate complex expression in editor context | `{"expression": "ProjectSettings.get_setting(\"application/config/name\")", "context": "editor"}` | Returns the project name | Editor API access. |
| 75 | Evaluate with just expression (no context — uses default) | `{"expression": "Vector2(1, 2).length()"}` | Returns `sqrt(5)` ≈ `2.236...` | Context defaults to `'editor'`. |

### Context Enum: `'game'`

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 76 | Evaluate in game context while game is running and paused at breakpoint | `{"expression": "position", "context": "game"}` | Returns current position of the node at the breakpoint | Core debugging workflow. |
| 77 | Evaluate in game context while game is running but NOT paused | `{"expression": "Engine.get_frames_drawn()", "context": "game"}` | Returns frame count (expression evaluated in running context) | Runtime evaluation without breakpoint. Depends on plugin support. |
| 78 | Evaluate in game context when game is NOT running | `{"expression": "2 + 2", "context": "game"}` | Godot returns error (no game context available) | Invalid context — no running game. |
| 79 | Evaluate method call in game context | `{"expression": "get_node(\"Player\").position", "context": "game"}` | Returns Player position or error if node not found | Scene tree access at runtime. |

### Context Enum: `'editor'`

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 80 | Evaluate editor-only API in editor context | `{"expression": "EditorInterface.get_editor_scale()", "context": "editor"}` | Returns current editor UI scale | EditorInterface only available in editor context. |
| 81 | Evaluate file system query in editor context | `{"expression": "DirAccess.dir_exists_absolute(\"res://scenes\")", "context": "editor"}` | Returns `true` or `false` | Editor-level file access. |
| 82 | Access current scene info in editor context | `{"expression": "EditorInterface.get_edited_scene_root().name", "context": "editor"}` | Returns root node name of currently edited scene | Requires an open scene. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 83 | Missing required `expression` | `{}` | Zod validation error | `GDScriptCode` has no `.optional()` or `.default()`. |
| 84 | Missing required `expression` with `context` only | `{"context": "editor"}` | Zod validation error | `expression` is required. |
| 85 | `expression` as a number | `{"expression": 123}` | Zod validation error | Type mismatch. |
| 86 | `expression` as a boolean | `{"expression": true}` | Zod validation error | Type mismatch. |
| 87 | Invalid enum value for `context` | `{"expression": "2 + 2", "context": "runtime"}` | Zod validation error | Only `'editor'` and `'game'` are valid. |
| 88 | `context` as uppercase `"EDITOR"` | `{"expression": "2 + 2", "context": "EDITOR"}` | Zod validation error | Enum is case-sensitive. |
| 89 | `context` as empty string | `{"expression": "2 + 2", "context": ""}` | Zod validation error | Empty string is not in enum. |
| 90 | `context` as a number | `{"expression": "2 + 2", "context": 0}` | Zod validation error | Type mismatch. |
| 91 | `context` as a boolean | `{"expression": "2 + 2", "context": false}` | Zod validation error | Type mismatch. |
| 92 | Evaluate expression with GDScript syntax error | `{"expression": "for i in range(10)"}` (statement, not expression) | Godot returns compilation error | GDScript requires expressions, not statements. |
| 93 | Evaluate expression referencing undefined variable | `{"expression": "undefined_var + 1", "context": "editor"}` | Godot returns error (undefined identifier) | Runtime evaluation error. |
| 94 | Evaluate expression that throws exception | `{"expression": "1 / 0", "context": "editor"}` | Godot returns error (division by zero) | Runtime error during evaluation. |
| 95 | Empty string expression | `{"expression": "", "context": "editor"}` | Passes Zod; Godot may return empty result or error | Empty expression behavior TBD. |
| 96 | Whitespace-only expression | `{"expression": "   ", "context": "editor"}` | Passes Zod; Godot may return empty or error | Zod just sees a non-empty string. |
| 97 | Very long expression | `{"expression": "<10,000 char GDScript expression>", "context": "editor"}` | Passes Zod; Godot may fail compilation or timeout | No max length constraint. |
| 98 | Call when editor is disconnected | `{"expression": "2 + 2"}` | Connection error or timeout | Bridge unavailable. |

---

## Tool 6: `step_over`

**Description:** Step over the current line when paused at a breakpoint  
**Handler:** `callGodot(bridge, 'step_over')` (no args forwarded)

**Parameters:** None (empty `inputSchema`)

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 99 | Step over a simple assignment line | `{}` (game paused at `var x = 5`) | Execution advances to next line; `x` now equals 5 | Core stepping workflow. Requires game running + paused. |
| 100 | Step over a function call (does NOT enter the function) | `{}` (game paused at `do_something()`) | Execution advances past the function call; function executed completely | Core "step over" behavior: over function calls. |
| 101 | Step over the last line of a function (returns to caller) | `{}` (game paused at `return` or last line of function) | Execution returns to the caller's next line | Boundary: end of function. |
| 102 | Step over multiple times in sequence | `{}` (call step_over repeatedly) | Execution advances line by line each time | Sequential stepping. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 103 | Call when game is NOT running | `{}` | Error — no execution to step in | No game context. |
| 104 | Call when game is running but NOT paused at a breakpoint | `{}` | Error — execution is active, cannot step | Stepping requires paused state. |
| 105 | Call when paused, but at the last executable line of the script (end of `_ready` / `_process`) | `{}` | Steps past end of function; execution continues if in main loop, or returns to caller | Behavior depends on context (main loop vs function call). |
| 106 | Call with extra ignored arguments | `{"action": "step"}` | Steps successfully (extra args ignored) | Zod ignores unknown keys. |
| 107 | Call when editor is disconnected | `{}` | Connection error or timeout | Bridge unavailable. |
| 108 | Call twice rapidly in sequence | `{}` (two calls in immediate succession) | Both should step if first completed; second may error if first hasn't finished | Race condition test. Depends on Godot plugin handling. |
| 109 | Call after game was stopped while paused | `{}` (stop game, then call step_over) | Error — game no longer running | Invalid state transition. |

---

## Tool 7: `step_into`

**Description:** Step into the current function call when paused at a breakpoint  
**Handler:** `callGodot(bridge, 'step_into')` (no args forwarded)

**Parameters:** None (empty `inputSchema`)

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 110 | Step into a function call | `{}` (game paused at `calculate_damage(enemy)`) | Execution enters `calculate_damage` function; paused at first line of the function | Core "step into" behavior. Requires game running + paused. |
| 111 | Step into a built-in function call | `{}` (game paused at `print("hello")`) | May skip past (no source to step into) or error | Built-in functions lack GDScript source. |
| 112 | Step into a method on another node | `{}` (game paused at `$Enemy.take_damage(10)`) | Enters `take_damage` in enemy script if it exists | Cross-script stepping. |
| 113 | Step into after step_over (at a function call) | `{}` (step_over past non-call line, then step_into at a call) | Enters the called function | Mixed stepping workflow. |
| 114 | Step into a nested call chain | `{}` (step_into `a()` which calls `b()` which calls `c()`) | Enters `a()`; subsequent step_into goes into `b()`, then `c()` | Deep call chain stepping. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 115 | Step into a non-function-call line (e.g., assignment) | `{}` (game paused at `x = 5`) | Behaves like step_over — advances to next line | `step_into` on non-call line is equivalent to `step_over`. |
| 116 | Call when game is NOT running | `{}` | Error — no execution to step into | No game context. |
| 117 | Call when game is running but NOT paused | `{}` | Error — cannot step into active execution | Stepping requires paused state. |
| 118 | Call when paused at a comment or blank line (breakpoint on non-executable) | `{}` | May step to next executable line or behave as step_over | Depends on how Godot handles non-executable breakpoints. |
| 119 | Call with extra ignored arguments | `{"depth": 1}` | Steps successfully (extra args ignored) | Zod ignores unknown keys. |
| 120 | Call when editor is disconnected | `{}` | Connection error or timeout | Bridge unavailable. |
| 121 | Call immediately after `step_into` (still at first line of entered function) | `{}` | Enters nested call or steps over, depending on current line | Sequential stepping into nested calls. |
| 122 | Call on a coroutine / `await` line | `{}` (game paused at `await get_tree().create_timer(1.0).timeout`) | Behavior depends on Godot debugger support for async stepping | Async debugging may or may not be supported. |
| 123 | Call after game was stopped while paused | `{}` (stop game, then call step_into) | Error — game no longer running | Invalid state transition. |

---

## Tool 8: `continue_execution`

**Description:** Continue execution when paused at a breakpoint  
**Handler:** `callGodot(bridge, 'continue_execution')` (no args forwarded)

**Parameters:** None (empty `inputSchema`)

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 124 | Continue from a breakpoint pause | `{}` (game paused at breakpoint) | Execution resumes; game continues running | Core debugging workflow. Requires game running + paused. |
| 125 | Continue, then hit next breakpoint | `{}` (game paused at breakpoint A; breakpoint B is later in execution) | Execution resumes from A, runs until it hits B, then pauses again | Multi-breakpoint flow. |
| 126 | Continue from a conditional breakpoint that was triggered | `{}` (game paused at conditional breakpoint where `health <= 0`) | Execution resumes normally | Conditional breakpoint already evaluated. |
| 127 | Continue after stepping (step_over then continue) | `{}` (after one or more step_over/step_into calls) | Execution resumes from current position | Mixed stepping and continue workflow. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 128 | Call when game is NOT running | `{}` | Error — no execution to continue | No game context. |
| 129 | Call when game is running but NOT paused (no breakpoint hit) | `{}` | Error or no-op — execution is already active | Nothing to continue. |
| 130 | Call twice in a row (first resumes, second has nothing to continue) | `{}` (two sequential calls) | First: resumes execution. Second: error or no-op | State changes after first call. |
| 131 | Call when paused at the last breakpoint; no more breakpoints after | `{}` | Execution resumes and continues until game stops or user intervenes | Runs to completion or next user stop. |
| 132 | Call with extra ignored arguments | `{"speed": "fast"}` | Continues successfully (extra args ignored) | Zod ignores unknown keys. |
| 133 | Call when editor is disconnected | `{}` | Connection error or timeout | Bridge unavailable. |
| 134 | Call rapidly after game stops (race condition) | `{}` (stop game, then immediately call continue_execution) | Error — game no longer running or race between stop and continue | Timing-dependent. Should return clean error, not crash. |
| 135 | Continue through an infinite loop (with breakpoint inside the loop) | `{}` (game paused at breakpoint inside `while true:`) | Loops and hits same breakpoint again (unless condition prevents re-trigger) | Loop behavior test. |
| 136 | Continue after `step_over` that stepped into an infinite loop | `{}` | Execution runs freely through the loop | Continue does not limit execution. |

---

## Cross-Tool Integration Scenarios

| # | Scenario | Steps | Expected result | Notes |
|---|----------|-------|-----------------|-------|
| 137 | Full debugging workflow: set → list → pause → call stack → step → continue | 1. `set_breakpoint` on line 10 2. `list_breakpoints` → confirm 1 entry 3. Run game → hits breakpoint 4. `get_call_stack` → see paused state 5. `step_over` → advance 1 line 6. `get_call_stack` → updated stack 7. `continue_execution` → resume | All tools work in sequence; state transitions correctly | End-to-end debugging workflow. |
| 138 | Conditional breakpoint lifecycle | 1. `set_breakpoint` with `condition: "x > 5"` 2. `list_breakpoints` → confirm condition stored 3. Run game → only pauses when `x > 5` 4. `evaluate_expression` → `"x"` returns current value 5. `continue_execution` | Condition works correctly; expression evaluation matches | Conditional debugging workflow. |
| 139 | Multiple breakpoints, selective removal | 1. `set_breakpoint` on script A line 10 2. `set_breakpoint` on script A line 20 3. `set_breakpoint` on script B line 5 4. `list_breakpoints` → 3 entries 5. `remove_breakpoint` on script A line 10 6. `list_breakpoints` → 2 entries (A:20, B:5) | Selective removal works; other breakpoints unaffected | Cross-script breakpoint management. |
| 140 | Expression evaluation in both contexts | 1. `evaluate_expression` with `context: "editor"` → returns editor result 2. Run game 3. Pause at breakpoint 4. `evaluate_expression` with `context: "game"` → returns runtime result | Both contexts work independently | Context switching test. |
| 141 | Step mix: over then into then continue | 1. Paused at `a(b())` 2. `step_into` → enters `a`, paused at `b()` call 3. `step_over` → `b()` executes, paused at next line in `a` 4. `continue_execution` → resumes fully | Mixed stepping commands chain correctly | Stepping strategy test. |
| 142 | Error recovery: attempt runtime tools without game running | 1. `get_call_stack` → error 2. `step_over` → error 3. `step_into` → error 4. `continue_execution` → error 5. `evaluate_expression` with `context: "game"` → error | All return clean errors, no crashes | Graceful degradation when game not running. |
| 143 | Breakpoint on every tool-accessible line in a script | 1. `set_breakpoint` on every executable line (1..N) 2. `list_breakpoints` → N entries 3. Run game 4. `continue_execution` after each hit → cycles through all breakpoints | All breakpoints fire; list stays accurate | High-density breakpoint test. |

---

## Summary

| Tool | Param count | Required params | Has enum | Has optional | No-param |
|------|-------------|-----------------|----------|--------------|----------|
| `set_breakpoint` | 3 | `script_path`, `line` | No | `condition` (string) | No |
| `remove_breakpoint` | 2 | `script_path`, `line` | No | No | No |
| `list_breakpoints` | 0 | — | No | — | Yes |
| `get_call_stack` | 0 | — | No | — | Yes |
| `evaluate_expression` | 2 | `expression` | `context`: `'editor'`, `'game'` | `context` (default `'editor'`) | No |
| `step_over` | 0 | — | No | — | Yes |
| `step_into` | 0 | — | No | — | Yes |
| `continue_execution` | 0 | — | No | — | Yes |

**Total scenarios:** 143
