# Debugging Tools — Test Plan

> **Source file:** `server/src/tools/debugging.ts`
> **Godot bridge endpoints:** `set_breakpoint`, `remove_breakpoint`, `list_breakpoints`, `get_call_stack`, `evaluate_expression`, `step_over`, `step_into`, `continue_execution`
> **Generated:** 2026-07-08

---

## Overview

All 8 tools in this module provide interactive debugging capabilities. Four tools accept parameters (`set_breakpoint`, `remove_breakpoint`, `evaluate_expression`) and four are parameterless control tools that require the game to be paused at a breakpoint (`list_breakpoints`, `get_call_stack`, `step_over`, `step_into`, `continue_execution`).

| # | Tool Name | Bridge Method | Params | Handler Pattern |
|---|-----------|--------------|--------|-----------------|
| 1 | `set_breakpoint` | `set_breakpoint` | `script_path` (required), `line` (required), `condition` (optional) | `(args) => callGodot(bridge, 'set_breakpoint', args)` |
| 2 | `remove_breakpoint` | `remove_breakpoint` | `script_path` (required), `line` (required) | `(args) => callGodot(bridge, 'remove_breakpoint', args)` |
| 3 | `list_breakpoints` | `list_breakpoints` | None | `() => callGodot(bridge, 'list_breakpoints')` |
| 4 | `get_call_stack` | `get_call_stack` | None | `() => callGodot(bridge, 'get_call_stack')` |
| 5 | `evaluate_expression` | `evaluate_expression` | `expression` (required), `context` (optional, default `'editor'`) | `(args) => callGodot(bridge, 'evaluate_expression', args)` |
| 6 | `step_over` | `step_over` | None | `() => callGodot(bridge, 'step_over')` |
| 7 | `step_into` | `step_into` | None | `() => callGodot(bridge, 'step_into')` |
| 8 | `continue_execution` | `continue_execution` | None | `() => callGodot(bridge, 'continue_execution')` |

### Shared Types Used

From `shared-types.ts`:
- **`ScriptPath`** = `z.string().describe("Script file path (e.g. 'res://scripts/player.gd')")` — a non-empty string representing a GDScript path
- **`GDScriptCode`** = `z.string().describe('GDScript code to execute')` — any string of GDScript code
- These are just `z.string()` with descriptions — no additional constraints beyond being strings

### Runtime State Dependencies

Several tools require specific game state that must be set up before calling:

| State Requirement | Tools Affected |
|-------------------|---------------|
| Game running AND paused at breakpoint | `get_call_stack`, `step_over`, `step_into`, `continue_execution` |
| Game running (any state) | `evaluate_expression` (context=`'game'`) |
| Scene open or game running | `evaluate_expression` (context=`'editor'`) |
| Script file exists in project | `set_breakpoint`, `remove_breakpoint` |
| Breakpoints previously set | `list_breakpoints` |

---

## Tool: `set_breakpoint`

**Description:** Set a breakpoint in a GDScript file at a specific line, optionally with a condition

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `script_path` | `string` (ScriptPath) | ✅ | Script file path (e.g. `'res://scripts/player.gd'`) |
| `line` | `number` (int, ≥ 1) | ✅ | Line number to set breakpoint on |
| `condition` | `string` | ❌ | Optional condition expression — breakpoint only triggers when true |

**Handler:**
```typescript
async (args) => callGodot(bridge, 'set_breakpoint', args as Record<string, unknown>)
```

---

### Test Scenarios

#### Scenario 1: Happy path — set breakpoint with minimum params
- **Description:** Set a breakpoint on a valid script at a valid line number.
- **Params:** `{ "script_path": "res://scripts/player.gd", "line": 10 }`
- **Expected result:** Success response confirming breakpoint was set. No error.
- **Notes:** Requires `res://scripts/player.gd` to exist and have at least 10 lines. The target line should contain executable code to be meaningful.

#### Scenario 2: Happy path — set conditional breakpoint
- **Description:** Set a breakpoint with a GDScript condition expression. The breakpoint should only trigger when the condition evaluates to true.
- **Params:** `{ "script_path": "res://scripts/player.gd", "line": 42, "condition": "health <= 0" }`
- **Expected result:** Success response confirming conditional breakpoint was set.
- **Notes:** Test that the condition is actually stored by listing breakpoints afterward (`list_breakpoints`).

#### Scenario 3: Edge case — line = 1 (boundary)
- **Description:** Set a breakpoint on the first line of a script.
- **Params:** `{ "script_path": "res://scripts/player.gd", "line": 1 }`
- **Expected result:** Success or descriptive error if line 1 is not executable. Not a validation error from the server.
- **Notes:** The `min(1)` constraint means line 0 would fail server-side validation.

#### Scenario 4: Schema validation — line = 0 (below minimum)
- **Description:** Call with line 0, which violates `z.number().int().min(1)`.
- **Params:** `{ "script_path": "res://scripts/player.gd", "line": 0 }`
- **Expected result:** Zod validation error. The call is rejected by the server before reaching Godot.
- **Notes:** Verifies the `min(1)` constraint works.

#### Scenario 5: Schema validation — line = negative
- **Description:** Call with a negative line number.
- **Params:** `{ "script_path": "res://scripts/player.gd", "line": -5 }`
- **Expected result:** Zod validation error. Rejected by server.
- **Notes:** Also tests `min(1)`.

#### Scenario 6: Schema validation — line is not an integer
- **Description:** Call with a floating-point line number.
- **Params:** `{ "script_path": "res://scripts/player.gd", "line": 10.5 }`
- **Expected result:** Zod validation error (`.int()` constraint). Rejected by server.
- **Notes:** The schema requires `.int()`.

#### Scenario 7: Schema validation — missing required `script_path`
- **Description:** Call without the required `script_path` parameter.
- **Params:** `{ "line": 10 }`
- **Expected result:** Zod validation error. Rejected by server.
- **Notes:** `script_path` has no `.optional()` — it is required.

#### Scenario 8: Schema validation — missing required `line`
- **Description:** Call without the required `line` parameter.
- **Params:** `{ "script_path": "res://scripts/player.gd" }`
- **Expected result:** Zod validation error. Rejected by server.
- **Notes:** `line` is required.

#### Scenario 9: Edge case — empty string for `script_path`
- **Description:** Call with an empty script path.
- **Params:** `{ "script_path": "", "line": 1 }`
- **Expected result:** May pass schema validation (empty string is a valid string) but should produce an error from Godot about invalid/nonexistent path.
- **Notes:** Zod's `z.string()` accepts empty strings. The Godot plugin should reject it.

#### Scenario 10: Edge case — very large line number
- **Description:** Call with a line number far beyond the script length.
- **Params:** `{ "script_path": "res://scripts/player.gd", "line": 99999 }`
- **Expected result:** Error from Godot (line exceeds script length). No server-side validation error.
- **Notes:** Server has no knowledge of script length.

#### Scenario 11: Edge case — condition is empty string
- **Description:** Call with an empty condition string.
- **Params:** `{ "script_path": "res://scripts/player.gd", "line": 5, "condition": "" }`
- **Expected result:** May be treated as no condition (equivalent to omitting it) or may produce an error from Godot. Should not crash.
- **Notes:** Empty string passes Zod validation since `condition` is `z.string().optional()`.

#### Scenario 12: Edge case — script does not exist
- **Description:** Call with a path to a nonexistent script.
- **Params:** `{ "script_path": "res://scripts/nonexistent.gd", "line": 1 }`
- **Expected result:** Error from Godot (script not found).
- **Notes:** The server forwards the call; Godot generates the error.

#### Scenario 13: Godot editor not connected
- **Description:** Call when the bridge is disconnected (Godot editor not running).
- **Params:** `{ "script_path": "res://scripts/player.gd", "line": 1 }`
- **Expected result:** Error result with `isError: true`, containing a message like "Godot request failed: ...".
- **Notes:** Covered by the `callGodot` error handler.

---

## Tool: `remove_breakpoint`

**Description:** Remove a breakpoint from a GDScript file at a specific line

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `script_path` | `string` (ScriptPath) | ✅ | Script file path (e.g. `'res://scripts/player.gd'`) |
| `line` | `number` (int, ≥ 1) | ✅ | Line number of the breakpoint to remove |

**Handler:**
```typescript
async (args) => callGodot(bridge, 'remove_breakpoint', args as Record<string, unknown>)
```

---

### Test Scenarios

#### Scenario 1: Happy path — remove an existing breakpoint
- **Description:** Remove a breakpoint that was previously set via `set_breakpoint`.
- **Params:** `{ "script_path": "res://scripts/player.gd", "line": 10 }`
- **Expected result:** Success response confirming breakpoint was removed.
- **Notes:** Setup: first call `set_breakpoint` to create the breakpoint, then verify removal via `list_breakpoints`.

#### Scenario 2: Edge case — removing a breakpoint that does not exist
- **Description:** Try to remove a breakpoint at a line where no breakpoint was set.
- **Params:** `{ "script_path": "res://scripts/player.gd", "line": 99 }`
- **Expected result:** May succeed silently or return an error/message from Godot indicating no breakpoint at that line. Should not crash.
- **Notes:** Behavior depends on Godot's debugger implementation.

#### Scenario 3: Schema validation — line = 0
- **Description:** Call with line 0, violating `min(1)`.
- **Params:** `{ "script_path": "res://scripts/player.gd", "line": 0 }`
- **Expected result:** Zod validation error. Rejected by server.

#### Scenario 4: Schema validation — line = negative
- **Description:** Call with a negative line number.
- **Params:** `{ "script_path": "res://scripts/player.gd", "line": -1 }`
- **Expected result:** Zod validation error. Rejected by server.

#### Scenario 5: Schema validation — line is not an integer
- **Description:** Call with a floating-point line number.
- **Params:** `{ "script_path": "res://scripts/player.gd", "line": 10.5 }`
- **Expected result:** Zod validation error (`.int()` constraint). Rejected by server.

#### Scenario 6: Schema validation — missing `script_path`
- **Description:** Call without the required `script_path` parameter.
- **Params:** `{ "line": 10 }`
- **Expected result:** Zod validation error. Rejected by server.

#### Scenario 7: Schema validation — missing `line`
- **Description:** Call without the required `line` parameter.
- **Params:** `{ "script_path": "res://scripts/player.gd" }`
- **Expected result:** Zod validation error. Rejected by server.

#### Scenario 8: Edge case — empty string for `script_path`
- **Description:** Call with an empty script path.
- **Params:** `{ "script_path": "", "line": 1 }`
- **Expected result:** May pass schema validation but should produce an error from Godot about invalid/nonexistent path.
- **Notes:** Empty string passes `z.string()`. Godot should reject it.

#### Scenario 9: Godot editor not connected
- **Description:** Call when the bridge is disconnected.
- **Params:** `{ "script_path": "res://scripts/player.gd", "line": 1 }`
- **Expected result:** Error result with `isError: true`, containing a connection error message.

---

## Tool: `list_breakpoints`

**Description:** List all active breakpoints across all scripts

**Parameters:** None (`inputSchema: {}`)

**Handler:**
```typescript
async () => callGodot(bridge, 'list_breakpoints')
```

---

### Test Scenarios

#### Scenario 1: Happy path — list breakpoints after setting some
- **Description:** Set 2–3 breakpoints first, then list them. Should return all active breakpoints with their script paths, line numbers, and conditions.
- **Params:** `{}`
- **Expected result:** JSON array/object of breakpoints, each containing `script_path`, `line`, and optionally `condition`. Not an error.
- **Notes:** Setup: use `set_breakpoint` to create breakpoints before testing `list_breakpoints`.

#### Scenario 2: Happy path — list with no breakpoints set
- **Description:** Call in a clean state with no breakpoints.
- **Params:** `{}`
- **Expected result:** Empty array/object. Not an error.
- **Notes:** May need to remove all breakpoints first.

#### Scenario 3: Empty params — handler ignores params
- **Description:** The handler is `async () => callGodot(...)` (no args parameter). Extra params are not forwarded.
- **Params:** `{ "verbose": true }` or `{ "script_path": "res://scripts/test.gd" }`
- **Expected result:** Same as Scenario 1/2. Extra params are silently ignored by the handler.
- **Notes:** Unlike tools that use `(args) => callGodot(bridge, ..., args)`, this handler discards arguments entirely.

#### Scenario 4: Godot editor not connected
- **Description:** Call when the bridge is disconnected.
- **Params:** `{}`
- **Expected result:** Error result with `isError: true`, connection error message.

---

## Tool: `get_call_stack`

**Description:** Get the current call stack with local variables when the game is paused at a breakpoint

**Parameters:** None (`inputSchema: {}`)

**Handler:**
```typescript
async () => callGodot(bridge, 'get_call_stack')
```

---

### Test Scenarios

#### Scenario 1: Happy path — game paused at breakpoint
- **Description:** Run the game, hit a breakpoint, then call `get_call_stack`. Should return the stack frames with local variables.
- **Params:** `{}`
- **Expected result:** Array of stack frames, each containing function name, script path, line number, and local variable names/values. Not an error.
- **Notes:** Requires: (1) a breakpoint set at an executable line, (2) game running (`play_scene`), (3) execution reaches that line and pauses.

#### Scenario 2: Edge case — game not running
- **Description:** Call when the game is not running (editor idle).
- **Params:** `{}`
- **Expected result:** Error from Godot — "no debugger session active" or similar. Should not crash the server.
- **Notes:** The Godot plugin should return a descriptive error.

#### Scenario 3: Edge case — game running but not paused
- **Description:** Call while the game is running but not paused at any breakpoint.
- **Params:** `{}`
- **Expected result:** Error from Godot — "execution not paused" or similar. May return an empty stack.
- **Notes:** Behavior depends on Godot's debugger state reporting.

#### Scenario 4: Empty params — handler ignores params
- **Description:** The handler is `async () => callGodot(...)` (no args parameter). Extra params are not forwarded.
- **Params:** `{ "depth": 5 }`
- **Expected result:** Same as Scenario 1. Extra params are silently ignored.
- **Notes:** Handler discards arguments.

#### Scenario 5: Godot editor not connected
- **Description:** Call when the bridge is disconnected.
- **Params:** `{}`
- **Expected result:** Error result with `isError: true`, connection error message.

---

## Tool: `evaluate_expression`

**Description:** Evaluate a GDScript expression in the editor or running game context

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `expression` | `string` (GDScriptCode) | ✅ | — | GDScript expression to evaluate |
| `context` | `enum: 'editor' \| 'game'` | ❌ | `'editor'` | Context to evaluate in (default: editor) |

**Handler:**
```typescript
async (args) => callGodot(bridge, 'evaluate_expression', args as Record<string, unknown>)
```

---

### Test Scenarios

#### Scenario 1: Happy path — evaluate in editor context (default)
- **Description:** Evaluate a simple GDScript expression using the default context (`'editor'`).
- **Params:** `{ "expression": "1 + 2" }`
- **Expected result:** `3` — the evaluated result. Not an error.
- **Notes:** The `context` defaults to `'editor'` when not provided.

#### Scenario 2: Happy path — evaluate in editor context (explicit)
- **Description:** Same as Scenario 1 but explicitly pass `context: 'editor'`.
- **Params:** `{ "expression": "OS.get_name()", "context": "editor" }`
- **Expected result:** Returns the OS name string. Not an error.
- **Notes:** Explicitly tests that `'editor'` is a valid enum value.

#### Scenario 3: Happy path — evaluate in game context
- **Description:** Evaluate an expression in the running game context. Requires the game to be running.
- **Params:** `{ "expression": "get_tree().get_node_count()", "context": "game" }`
- **Expected result:** Integer representing the current node count in the game scene tree. Not an error.
- **Notes:** Requires game running (`play_scene`). The expression has access to game-scope variables and the scene tree.

#### Scenario 4: Game context — evaluate property of a game node
- **Description:** Read a node property during gameplay.
- **Params:** `{ "expression": "get_node('/root/Main/Player').position.x", "context": "game" }`
- **Expected result:** The x-coordinate of the Player node. Not an error.
- **Notes:** Tests that code context has access to the full scene tree API.

#### Scenario 5: Schema validation — missing `expression`
- **Description:** Call without the required `expression` parameter.
- **Params:** `{}` or `{ "context": "editor" }`
- **Expected result:** Zod validation error. Rejected by server.
- **Notes:** `expression` is required (no `.optional()`).

#### Scenario 6: Schema validation — invalid `context` value
- **Description:** Call with a context value not in the enum.
- **Params:** `{ "expression": "1 + 1", "context": "runtime" }`
- **Expected result:** Zod validation error — `'runtime'` is not in `['editor', 'game']`. Rejected by server.
- **Notes:** Verifies the `z.enum(['editor', 'game'])` constraint.

#### Scenario 7: Schema validation — `context` is wrong type
- **Description:** Call with a non-string context value.
- **Params:** `{ "expression": "1 + 1", "context": 123 }`
- **Expected result:** Zod validation error. Rejected by server.
- **Notes:** The enum requires a string.

#### Scenario 8: Edge case — empty expression string
- **Description:** Call with an empty expression.
- **Params:** `{ "expression": "" }`
- **Expected result:** May return `null`, an empty result, or an error from Godot depending on how it handles empty expressions. Should not crash.
- **Notes:** Empty string passes `z.string()`. Godot may or may not reject it.

#### Scenario 9: Edge case — expression with a syntax error
- **Description:** Evaluate GDScript code with a syntax error.
- **Params:** `{ "expression": "foo(" }`
- **Expected result:** Error from Godot containing parse/syntax error details. Not a server-level error.
- **Notes:** Tests error propagation from Godot's expression evaluator.

#### Scenario 10: Edge case — multi-line expression
- **Description:** Evaluate a multi-line GDScript expression (e.g., a block that declares a variable and returns it).
- **Params:** `{ "expression": "var x = 5\nreturn x * 2" }`
- **Expected result:** `10` or a parse error depending on how Godot evaluates multi-line expressions.
- **Notes:** Useful for testing expression evaluation limits.

#### Scenario 11: Game context — game not running
- **Description:** Call with `context: 'game'` when the game is not running.
- **Params:** `{ "expression": "get_node('/root/Main')", "context": "game" }`
- **Expected result:** Error from Godot — "no game session active" or similar.
- **Notes:** The Godot plugin should return a descriptive error, not crash.

#### Scenario 12: Godot editor not connected
- **Description:** Call when the bridge is disconnected.
- **Params:** `{ "expression": "1 + 1" }`
- **Expected result:** Error result with `isError: true`, connection error message.

---

## Tool: `step_over`

**Description:** Step over the current line when paused at a breakpoint

**Parameters:** None (`inputSchema: {}`)

**Handler:**
```typescript
async () => callGodot(bridge, 'step_over')
```

---

### Test Scenarios

#### Scenario 1: Happy path — step over while paused
- **Description:** Game is paused at a breakpoint. Call `step_over` to advance to the next line in the same function.
- **Params:** `{}`
- **Expected result:** Success response. After the call, the execution pointer should be at the next line in the same function.
- **Notes:** Requires: (1) breakpoint set, (2) game running, (3) execution paused at breakpoint. Must verify state changes by calling `get_call_stack` afterward to confirm the line number advanced.

#### Scenario 2: Edge case — stepping over a function call
- **Description:** Pause at a line that calls another function, then step over. The entire function call should execute without stepping into it.
- **Params:** `{}`
- **Expected result:** Execution advances past the function call to the next line in the caller. The called function runs completely but the debugger does not enter it.
- **Notes:** Distinct from `step_into`, which would enter the called function.

#### Scenario 3: Edge case — step over at the last line of a function
- **Description:** Pause at the last executable line of a function, then step over.
- **Params:** `{}`
- **Expected result:** Execution returns to the caller (function returns). The stack unwinds by one frame.
- **Notes:** May trigger Godot to move to the next invocation site.

#### Scenario 4: Edge case — game not running
- **Description:** Call when the game is not running.
- **Params:** `{}`
- **Expected result:** Error from Godot — "no debugger session active" or equivalent.
- **Notes:** Should not crash the server.

#### Scenario 5: Edge case — game running but not paused
- **Description:** Call while the game is running but not paused at any breakpoint.
- **Params:** `{}`
- **Expected result:** Error from Godot — "execution not paused" or similar.
- **Notes:** Stepping is only meaningful when paused.

#### Scenario 6: Godot editor not connected
- **Description:** Call when the bridge is disconnected.
- **Params:** `{}`
- **Expected result:** Error result with `isError: true`, connection error message.

---

## Tool: `step_into`

**Description:** Step into the current function call when paused at a breakpoint

**Parameters:** None (`inputSchema: {}`)

**Handler:**
```typescript
async () => callGodot(bridge, 'step_into')
```

---

### Test Scenarios

#### Scenario 1: Happy path — step into a function call
- **Description:** Game is paused at a line that calls a GDScript function. Call `step_into` to descend into the called function.
- **Params:** `{}`
- **Expected result:** Success. The execution pointer moves to the first executable line inside the called function. New stack frame appears (verifiable via `get_call_stack`).
- **Notes:** Requires a breakpoint at a line with a function call, game running and paused.

#### Scenario 2: Edge case — step into a non-function line
- **Description:** Pause at a line that does NOT contain a function call (e.g., an assignment). Then step into.
- **Params:** `{}`
- **Expected result:** Behaves like `step_over` — advances to the next line in the same function. Should not error.
- **Notes:** Godot's behavior: `step_into` on a non-call line is equivalent to `step_over`.

#### Scenario 3: Edge case — step into a built-in/engine method
- **Description:** Pause at a line calling a built-in method (e.g., `print()`, `add_child()`), then step into.
- **Params:** `{}`
- **Expected result:** Behaves like `step_over` — engine internals are not stepped into. Advances past the call.
- **Notes:** Godot typically does not allow stepping into engine C++ code through the script debugger.

#### Scenario 4: Edge case — game not running
- **Description:** Call when the game is not running.
- **Params:** `{}`
- **Expected result:** Error from Godot — "no debugger session active".
- **Notes:** Should not crash.

#### Scenario 5: Edge case — game running but not paused
- **Description:** Call while the game is running but not paused.
- **Params:** `{}`
- **Expected result:** Error from Godot — "execution not paused".
- **Notes:** Stepping requires paused state.

#### Scenario 6: Godot editor not connected
- **Description:** Call when the bridge is disconnected.
- **Params:** `{}`
- **Expected result:** Error result with `isError: true`, connection error message.

---

## Tool: `continue_execution`

**Description:** Continue execution when paused at a breakpoint

**Parameters:** None (`inputSchema: {}`)

**Handler:**
```typescript
async () => callGodot(bridge, 'continue_execution')
```

---

### Test Scenarios

#### Scenario 1: Happy path — continue execution from breakpoint
- **Description:** Game is paused at a breakpoint. Call `continue_execution` to resume normal execution.
- **Params:** `{}`
- **Expected result:** Success. The game resumes running. If no further breakpoints are hit, the game continues until stopped.
- **Notes:** Requires: (1) breakpoint set, (2) game running and paused at breakpoint. After calling, verify the game is running (e.g., via `get_game_scene_tree`).

#### Scenario 2: Happy path — continue to next breakpoint
- **Description:** Set multiple breakpoints. After hitting the first one, call `continue_execution`. The game should run until it hits the next breakpoint.
- **Params:** `{}`
- **Expected result:** Success. Game runs, hits next breakpoint, pauses again.
- **Notes:** Verifies that breakpoints remain active after `continue_execution`.

#### Scenario 3: Edge case — game not running
- **Description:** Call when the game is not running.
- **Params:** `{}`
- **Expected result:** Error from Godot — "no debugger session active" or success (no-op).
- **Notes:** Should not crash the server.

#### Scenario 4: Edge case — game running but not paused
- **Description:** Call while the game is running but not paused at any breakpoint.
- **Params:** `{}`
- **Expected result:** Likely a no-op or minor warning from Godot. May succeed silently.
- **Notes:** Continuing when already running should not cause an error.

#### Scenario 5: Edge case — continue after last breakpoint
- **Description:** Hit the only breakpoint, continue. Game runs to completion/normal execution.
- **Params:** `{}`
- **Expected result:** Success. Game continues without further pauses.
- **Notes:** Tests that `continue_execution` works correctly when no more breakpoints exist.

#### Scenario 6: Godot editor not connected
- **Description:** Call when the bridge is disconnected.
- **Params:** `{}`
- **Expected result:** Error result with `isError: true`, connection error message.

---

## Integration Sequence: Full Debugging Workflow

This end-to-end scenario tests the tools in sequence as they would be used in a real debugging session.

### Prerequisites
- A Godot project with `res://scripts/player.gd` containing at least 50 lines with executable code
- A scene that can be played and triggers the player script

### Steps

1. **Set breakpoint:** `set_breakpoint({ "script_path": "res://scripts/player.gd", "line": 10 })` → expect success
2. **Set conditional breakpoint:** `set_breakpoint({ "script_path": "res://scripts/player.gd", "line": 25, "condition": "speed > 100" })` → expect success
3. **List breakpoints:** `list_breakpoints({})` → expect 2 breakpoints returned with correct script paths, lines, and condition
4. **Run the game:** `play_scene({ "mode": "main" })` → game starts
5. **Wait for breakpoint hit:** (manual or via `wait_for_game_event`) → game pauses
6. **Get call stack:** `get_call_stack({})` → expect stack frames with line 10 or 25
7. **Evaluate expression:** `evaluate_expression({ "expression": "speed", "context": "game" })` → expect current speed value
8. **Step over:** `step_over({})` → expect execution advances one line
9. **Step into:** `step_into({})` → if at a function call, expect to enter the function
10. **Evaluate expression in editor:** `evaluate_expression({ "expression": "ProjectSettings.get_setting('application/config/name')" })` or with `"context": "editor"` → expect project name
11. **Continue execution:** `continue_execution({})` → game resumes
12. **Stop game:** `stop_scene({})` → game stops
13. **Remove breakpoint:** `remove_breakpoint({ "script_path": "res://scripts/player.gd", "line": 10 })` → expect success
14. **Verify removal:** `list_breakpoints({})` → expect only 1 breakpoint remaining (line 25)
15. **Remove remaining breakpoint:** `remove_breakpoint({ "script_path": "res://scripts/player.gd", "line": 25 })` → expect success
16. **Verify all removed:** `list_breakpoints({})` → expect empty list

---

## Parameter Type Reference

### `ScriptPath` (from shared-types.ts)
```typescript
z.string().describe("Script file path (e.g. 'res://scripts/player.gd')")
```
- Type: `string`
- No `min`/`max`/`regex` constraints
- Accepts any string including empty string
- Godot plugin validates actual file existence

### `GDScriptCode` (from shared-types.ts)
```typescript
z.string().describe('GDScript code to execute')
```
- Type: `string`
- No `min`/`max`/`regex` constraints
- Accepts any string including empty string
- Godot plugin validates parse-ability at evaluation time

### Line Number Constraints
- `z.number().int().min(1)` — must be an integer ≥ 1
- Rejects: negative numbers, zero, floats, non-numeric values
- Accepts: any positive integer (server-side; Godot may reject huge values)

### Context Enum
- `z.enum(['editor', 'game'])` — only these two literal strings
- Rejects: any other string, numbers, booleans, null, objects
- Default: `'editor'` (applied by Zod, so omitting `context` is valid)
