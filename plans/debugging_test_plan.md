# Debugging Tools — Comprehensive Test Plan

> **Source file**: `server/src/tools/debugging.ts`
> **Shared types**: `server/src/tools/shared-types.ts` — `ScriptPath` (z.string), `GDScriptCode` (z.string)
> **Bridge call**: All tools delegate to `callGodot(bridge, '<method>', args)` which sends a JSON-RPC request to the Godot editor plugin via WebSocket.
> **Prerequisites**: Godot editor is open, MCP plugin is active, a scene with at least one GDScript is loaded.

---

## General Setup / Teardown

Before running the debugging test suite, ensure the following:

1. **Create a test script** at `res://scripts/test_debug.gd` with known content (e.g. a function with multiple lines and a loop).
2. **Create/open a test scene** that uses this script (e.g. `res://scenes/test_debug.tscn`).
3. **Run the game** so that runtime breakpoints can be hit.
4. After all tests, **remove all breakpoints** via `remove_breakpoint` or by restarting the editor to leave a clean state.

### Recommended test script (`res://scripts/test_debug.gd`)

```gdscript
extends Node

var counter := 0

func _ready():
    counter = 1          # line 5
    var x = add(2, 3)    # line 6
    counter = x           # line 7

func add(a: int, b: int) -> int:
    var result = a + b   # line 10
    return result         # line 11

func loop_test():
    for i in range(5):   # line 14
        counter += i     # line 15
    return counter        # line 16
```

---

## Tool: `set_breakpoint`

**Description**: Set a breakpoint in a GDScript file at a specific line, optionally with a condition.

**Parameters**:

| Name | Type | Required | Default | Constraints | Description |
|---|---|---|---|---|---|
| `script_path` | `string` (ScriptPath) | **yes** | — | Must be a valid `res://` path | Script file path (e.g. `res://scripts/player.gd`) |
| `line` | `number` (int) | **yes** | — | `min(1)` | Line number to set breakpoint on |
| `condition` | `string` | no | `undefined` | — | Optional condition expression — breakpoint only triggers when true |

**Handler**: `callGodot(bridge, 'set_breakpoint', { script_path, line, condition? })`

**Expected return**: JSON result from Godot confirming the breakpoint was set (typically includes script path, line, and condition if any).

### Test Scenarios

#### Scenario 1: Set a basic breakpoint with minimum required params

- **Description**: Set a breakpoint on a known line of an existing script without a condition.
- **Params**:
  ```json
  {
    "script_path": "res://scripts/test_debug.gd",
    "line": 5
  }
  ```
- **Expected result**: Success response confirming breakpoint set at `res://scripts/test_debug.gd:5`. No condition attached.
- **Notes**: This is the happy-path baseline. Verify the response includes the exact script_path and line number.
- **What to pay attention to**: Ensure that the response contains a confirmation with the specified path and line. Verify that `isError` is not set.

#### Scenario 2: Set a breakpoint with a condition expression

- **Description**: Set a conditional breakpoint that only triggers when a variable meets a condition.
- **Params**:
  ```json
  {
    "script_path": "res://scripts/test_debug.gd",
    "line": 15,
    "condition": "counter > 3"
  }
  ```
- **Expected result**: Success response confirming breakpoint set at line 15 with condition `counter > 3`.
- **Notes**: Conditional breakpoints are essential for debugging loops. The condition is a GDScript expression evaluated at runtime.
- **What to pay attention to**: The response should contain the condition field with the passed value. Ensure that Godot correctly parses the expression.

#### Scenario 3: Set a breakpoint on line 1 (boundary — first line)

- **Description**: Test the minimum allowed line number (min=1).
- **Params**:
  ```json
  {
    "script_path": "res://scripts/test_debug.gd",
    "line": 1
  }
  ```
- **Expected result**: Success response confirming breakpoint set at line 1.
- **Notes**: Boundary test for the `min(1)` constraint.
- **What to pay attention to**: Line 1 is the boundary. Ensure that validation does not reject the value.

#### Scenario 4: Set a breakpoint with an empty string condition

- **Description**: Edge case — condition is an empty string rather than omitted.
- **Params**:
  ```json
  {
    "script_path": "res://scripts/test_debug.gd",
    "line": 7,
    "condition": ""
  }
  ```
- **Expected result**: Either success (treated as no condition) or a clear error about invalid condition.
- **Notes**: Tests how the Godot side handles an empty condition string vs. no condition at all.
- **What to pay attention to**: Behavior should be predictable — either an empty string is treated as "no condition", or an error is returned. There should be no crash.

#### Scenario 5: Invalid — missing required `script_path`

- **Description**: Call without the required `script_path` parameter.
- **Params**:
  ```json
  {
    "line": 5
  }
  ```
- **Expected result**: Validation error — `script_path` is required. The call should not reach Godot.
- **Notes**: MCP SDK Zod schema validation should reject this before the handler runs.
- **What to pay attention to**: The error should be clear and indicate the missing `script_path` parameter.

#### Scenario 6: Invalid — missing required `line`

- **Description**: Call without the required `line` parameter.
- **Params**:
  ```json
  {
    "script_path": "res://scripts/test_debug.gd"
  }
  ```
- **Expected result**: Validation error — `line` is required.
- **Notes**: Same as above — Zod validation should catch this.
- **What to pay attention to**: The error should indicate the missing `line` parameter.

#### Scenario 7: Invalid — line number is 0 (below minimum)

- **Description**: Test the `min(1)` constraint with line=0.
- **Params**:
  ```json
  {
    "script_path": "res://scripts/test_debug.gd",
    "line": 0
  }
  ```
- **Expected result**: Validation error — `line` must be >= 1.
- **Notes**: Zod `min(1)` should reject this at the schema level.
- **What to pay attention to**: Zod validation error, not an internal Godot error.

#### Scenario 8: Invalid — line number is negative

- **Description**: Test with a negative line number.
- **Params**:
  ```json
  {
    "script_path": "res://scripts/test_debug.gd",
    "line": -5
  }
  ```
- **Expected result**: Validation error — `line` must be >= 1.
- **Notes**: Zod `min(1)` should reject this.
- **What to pay attention to**: Negative values should be rejected at the schema level.

#### Scenario 9: Invalid — line is not an integer (float)

- **Description**: Test the `int()` constraint with a float value.
- **Params**:
  ```json
  {
    "script_path": "res://scripts/test_debug.gd",
    "line": 5.5
  }
  ```
- **Expected result**: Validation error — `line` must be an integer.
- **Notes**: Zod `.int()` should reject non-integer numbers.
- **What to pay attention to**: Fractional numbers should be rejected by the Zod validator.

#### Scenario 10: Edge case — non-existent script path

- **Description**: Set a breakpoint on a script that doesn't exist.
- **Params**:
  ```json
  {
    "script_path": "res://scripts/nonexistent.gd",
    "line": 5
  }
  ```
- **Expected result**: Error from Godot — script not found. The response should have `isError: true` or contain an error message.
- **Notes**: Schema validation passes (it's a valid string), but Godot cannot find the file.
- **What to pay attention to**: The error should be correctly proxied through `callGodot`. Ensure that this is not a server crash, but a clear message.

#### Scenario 11: Edge case — line exceeds script length

- **Description**: Set a breakpoint on a line number that doesn't exist in the script.
- **Params**:
  ```json
  {
    "script_path": "res://scripts/test_debug.gd",
    "line": 9999
  }
  ```
- **Expected result**: Either an error from Godot (line out of range) or a warning. Behavior may vary.
- **Notes**: Godot may accept this silently and the breakpoint just never triggers, or it may reject it.
- **What to pay attention to**: Check how Godot handles non-existent lines — error, warning, or silent acceptance.

---

## Tool: `remove_breakpoint`

**Description**: Remove a breakpoint from a GDScript file at a specific line.

**Parameters**:

| Name | Type | Required | Default | Constraints | Description |
|---|---|---|---|---|---|
| `script_path` | `string` (ScriptPath) | **yes** | — | Must be a valid `res://` path | Script file path |
| `line` | `number` (int) | **yes** | — | `min(1)` | Line number of the breakpoint to remove |

**Handler**: `callGodot(bridge, 'remove_breakpoint', { script_path, line })`

**Expected return**: JSON result confirming the breakpoint was removed.

### Test Scenarios

#### Scenario 1: Remove an existing breakpoint

- **Description**: Set a breakpoint first (via `set_breakpoint`), then remove it.
- **Setup**: Call `set_breakpoint` with `{ "script_path": "res://scripts/test_debug.gd", "line": 5 }`.
- **Params**:
  ```json
  {
    "script_path": "res://scripts/test_debug.gd",
    "line": 5
  }
  ```
- **Expected result**: Success response confirming breakpoint removed. Subsequent `list_breakpoints` should not include this breakpoint.
- **Notes**: This is the happy-path. Depends on `set_breakpoint` working correctly.
- **What to pay attention to**: Ensure that after removal, `list_breakpoints` does indeed not contain the removed breakpoint.

#### Scenario 2: Remove a conditional breakpoint

- **Description**: Set a conditional breakpoint, then remove it.
- **Setup**: Call `set_breakpoint` with `{ "script_path": "res://scripts/test_debug.gd", "line": 15, "condition": "counter > 3" }`.
- **Params**:
  ```json
  {
    "script_path": "res://scripts/test_debug.gd",
    "line": 15
  }
  ```
- **Expected result**: Success — the conditional breakpoint is removed.
- **Notes**: Removing a breakpoint should not require specifying the condition; line + script_path is sufficient.
- **What to pay attention to**: The condition should not affect removal — removal by line should work the same for conditional and unconditional breakpoints.

#### Scenario 3: Remove a breakpoint that doesn't exist

- **Description**: Attempt to remove a breakpoint from a line that has no breakpoint.
- **Params**:
  ```json
  {
    "script_path": "res://scripts/test_debug.gd",
    "line": 3
  }
  ```
- **Expected result**: Either a soft success (no-op) or an error indicating no breakpoint at that line.
- **Notes**: Tests idempotency. Behavior depends on Godot implementation.
- **What to pay attention to**: Verify whether the operation is idempotent (no error on repeated removal) or Godot returns an error. Both variants are acceptable, but the behavior should be predictable.

#### Scenario 4: Invalid — missing required `script_path`

- **Description**: Call without `script_path`.
- **Params**:
  ```json
  {
    "line": 5
  }
  ```
- **Expected result**: Validation error — `script_path` is required.
- **What to pay attention to**: Zod validation error.

#### Scenario 5: Invalid — missing required `line`

- **Description**: Call without `line`.
- **Params**:
  ```json
  {
    "script_path": "res://scripts/test_debug.gd"
  }
  ```
- **Expected result**: Validation error — `line` is required.
- **What to pay attention to**: Zod validation error.

#### Scenario 6: Invalid — line is 0 (below minimum)

- **Description**: Test `min(1)` boundary.
- **Params**:
  ```json
  {
    "script_path": "res://scripts/test_debug.gd",
    "line": 0
  }
  ```
- **Expected result**: Validation error — `line` must be >= 1.
- **What to pay attention to**: Zod schema rejection.

---

## Tool: `list_breakpoints`

**Description**: List all active breakpoints across all scripts.

**Parameters**: None (`inputSchema: {}`).

**Handler**: `callGodot(bridge, 'list_breakpoints')`

**Expected return**: JSON array or object listing all currently active breakpoints with script paths, line numbers, and conditions (if any).

### Test Scenarios

#### Scenario 1: List breakpoints when none exist

- **Description**: Ensure no breakpoints are set, then list.
- **Setup**: Remove all breakpoints first (or start fresh).
- **Params**: `{}` (no params)
- **Expected result**: Empty list/array — no breakpoints active.
- **Notes**: Baseline test.
- **What to pay attention to**: The response should be an empty list (not null, not undefined). Check the response format.

#### Scenario 2: List breakpoints after setting one

- **Description**: Set a breakpoint, then list.
- **Setup**: Call `set_breakpoint` with `{ "script_path": "res://scripts/test_debug.gd", "line": 5 }`.
- **Params**: `{}`
- **Expected result**: List contains exactly one entry: `{ script_path: "res://scripts/test_debug.gd", line: 5 }`.
- **Notes**: Verify the exact format of the returned breakpoint data.
- **What to pay attention to**: Verify that the response format includes `script_path` and `line`. If Godot returns a condition — verify it too.

#### Scenario 3: List breakpoints after setting multiple

- **Description**: Set breakpoints on multiple lines across one or more scripts, then list.
- **Setup**: Call `set_breakpoint` three times:
  1. `{ "script_path": "res://scripts/test_debug.gd", "line": 5 }`
  2. `{ "script_path": "res://scripts/test_debug.gd", "line": 10, "condition": "a > 0" }`
  3. Another script if available, or `{ "script_path": "res://scripts/test_debug.gd", "line": 15 }`
- **Params**: `{}`
- **Expected result**: List contains all 3 breakpoints with correct details.
- **Notes**: Verifies that `list_breakpoints` reports across all scripts and includes conditions.
- **What to pay attention to**: All three breakpoints should be present. The conditional breakpoint should contain a condition field.

#### Scenario 4: List after removing a breakpoint

- **Description**: Set two breakpoints, remove one, then list.
- **Setup**:
  1. `set_breakpoint` at line 5
  2. `set_breakpoint` at line 10
  3. `remove_breakpoint` at line 5
- **Params**: `{}`
- **Expected result**: List contains only the breakpoint at line 10.
- **What to pay attention to**: Ensure that the removed breakpoint is indeed absent from the list.

---

## Tool: `get_call_stack`

**Description**: Get the current call stack with local variables when the game is paused at a breakpoint.

**Parameters**: None (`inputSchema: {}`).

**Handler**: `callGodot(bridge, 'get_call_stack')`

**Expected return**: JSON structure containing the call stack frames, each with function name, script path, line number, and local variables.

### Test Scenarios

#### Scenario 1: Get call stack when game is paused at a breakpoint

- **Description**: Set a breakpoint, run the game, wait for it to hit the breakpoint, then get the call stack.
- **Setup**:
  1. `set_breakpoint` at `res://scripts/test_debug.gd:5` (inside `_ready`)
  2. Run the game (via `run_scene` or editor play)
  3. Wait for the game to pause at the breakpoint
- **Params**: `{}`
- **Expected result**: Non-empty call stack with at least one frame. The top frame should show:
  - Script: `res://scripts/test_debug.gd`
  - Function: `_ready`
  - Line: 5
  - Local variables (e.g. `counter`)
- **Notes**: This test depends on the game actually hitting the breakpoint. May need a small delay or polling.
- **What to pay attention to**: Verify that the stack contains the function name, script path, line number, and local variables. Ensure that variable values are correct (counter = 0 at the time of stopping at line 5).

#### Scenario 2: Get call stack when game is NOT paused

- **Description**: Call `get_call_stack` when the game is running normally (not paused at a breakpoint).
- **Setup**: Game is running but no breakpoint is hit.
- **Params**: `{}`
- **Expected result**: Either an empty call stack or an error indicating the game is not paused.
- **Notes**: Tests the error/edge case when there's nothing to inspect.
- **What to pay attention to**: Verify that the tool does not crash but returns a meaningful response (empty stack or error message).

#### Scenario 3: Get call stack when game is not running

- **Description**: Call `get_call_stack` when no game session is active.
- **Setup**: Game is stopped.
- **Params**: `{}`
- **Expected result**: Error — no active game session or not paused at a breakpoint.
- **What to pay attention to**: The error should be clear and indicate the cause (no active session).

---

## Tool: `evaluate_expression`

**Description**: Evaluate a GDScript expression in the editor or running game context.

**Parameters**:

| Name | Type | Required | Default | Constraints | Description |
|---|---|---|---|---|---|
| `expression` | `string` (GDScriptCode) | **yes** | — | — | GDScript expression to evaluate |
| `context` | `string` (enum) | no | `"editor"` | `"editor"` or `"game"` | Context to evaluate in |

**Handler**: `callGodot(bridge, 'evaluate_expression', { expression, context? })`

**Expected return**: JSON result containing the evaluated expression's return value.

### Test Scenarios

#### Scenario 1: Evaluate a simple expression in editor context

- **Description**: Evaluate a basic GDScript expression in the editor.
- **Params**:
  ```json
  {
    "expression": "2 + 2"
  }
  ```
- **Expected result**: Result containing the value `4`.
- **Notes**: Simplest happy path. Context defaults to `"editor"`.
- **What to pay attention to**: Verify that the returned value is the numeric value 4, not a string. Ensure that the default context "editor" is applied.

#### Scenario 2: Evaluate expression with explicit editor context

- **Description**: Same as Scenario 1 but with explicit `context`.
- **Params**:
  ```json
  {
    "expression": "2 + 2",
    "context": "editor"
  }
  ```
- **Expected result**: Same as Scenario 1 — value `4`.
- **Notes**: Verifies that explicit "editor" context works the same as default.
- **What to pay attention to**: The result should be identical to the scenario without specifying context.

#### Scenario 3: Evaluate expression in game context

- **Description**: Evaluate an expression that accesses a game object when the game is running.
- **Setup**: Game is running with `test_debug.gd` attached to a node.
- **Params**:
  ```json
  {
    "expression": "counter",
    "context": "game"
  }
  ```
- **Expected result**: The current value of `counter` variable in the running game.
- **Notes**: Requires the game to be running. The expression accesses a variable on the current script's instance.
- **What to pay attention to**: The value should correspond to the current game state. If the game is not running — an error is expected.

#### Scenario 4: Evaluate a string expression

- **Description**: Evaluate an expression that returns a string.
- **Params**:
  ```json
  {
    "expression": "\"hello\" + \" world\""
  }
  ```
- **Expected result**: Result containing `"hello world"`.
- **What to pay attention to**: Strings should be correctly concatenated and returned.

#### Scenario 5: Evaluate an invalid expression

- **Description**: Evaluate a syntactically invalid GDScript expression.
- **Params**:
  ```json
  {
    "expression": "func broken(",
    "context": "editor"
  }
  ```
- **Expected result**: Error from Godot — syntax error in expression. Response should have error indication.
- **Notes**: Tests error handling for bad GDScript code.
- **What to pay attention to**: The error should contain information about the syntax issue. It should not be a server crash.

#### Scenario 6: Evaluate a complex expression with function call

- **Description**: Evaluate an expression calling a built-in function.
- **Params**:
  ```json
  {
    "expression": "Vector2(1, 2).length()",
    "context": "editor"
  }
  ```
- **Expected result**: Result containing approximately `2.236` (sqrt(5)).
- **Notes**: Tests that complex GDScript expressions with constructors and method calls work.
- **What to pay attention to**: Verify the precision of calculations and the correctness of method calls.

#### Scenario 7: Invalid — missing required `expression`

- **Description**: Call without the `expression` parameter.
- **Params**:
  ```json
  {
    "context": "editor"
  }
  ```
- **Expected result**: Validation error — `expression` is required.
- **What to pay attention to**: Zod validation error.

#### Scenario 8: Edge case — empty string expression

- **Description**: Evaluate an empty string.
- **Params**:
  ```json
  {
    "expression": ""
  }
  ```
- **Expected result**: Either an error (empty expression) or a neutral result (null/undefined).
- **Notes**: Tests boundary behavior with empty input.
- **What to pay attention to**: Check how Godot handles an empty expression.

#### Scenario 9: Invalid context value

- **Description**: Pass an invalid context enum value.
- **Params**:
  ```json
  {
    "expression": "1 + 1",
    "context": "runtime"
  }
  ```
- **Expected result**: Validation error — `context` must be one of `"editor"` or `"game"`.
- **Notes**: Zod `z.enum(['editor', 'game'])` should reject `"runtime"`.
- **What to pay attention to**: The error should list the valid enum values.

---

## Tool: `step_over`

**Description**: Step over the current line when paused at a breakpoint.

**Parameters**: None (`inputSchema: {}`).

**Handler**: `callGodot(bridge, 'step_over')`

**Expected return**: JSON result confirming the step-over action, possibly with the new current line.

### Test Scenarios

#### Scenario 1: Step over when paused at a breakpoint

- **Description**: Game is paused at a breakpoint; step over the current line.
- **Setup**:
  1. `set_breakpoint` at `res://scripts/test_debug.gd:5`
  2. Run the game and wait for it to pause
- **Params**: `{}`
- **Expected result**: Success response. The execution advances to the next line (line 6). A subsequent `get_call_stack` should show line 6.
- **Notes**: After stepping, the game should still be paused (not running freely).
- **What to pay attention to**: Verify that the current line number changed to the next one. The game should remain in a paused state.

#### Scenario 2: Step over when NOT paused

- **Description**: Call `step_over` when the game is running normally (not paused).
- **Setup**: Game is running, no breakpoint hit.
- **Params**: `{}`
- **Expected result**: Error — game is not paused at a breakpoint.
- **What to pay attention to**: The error should be clear and not crash the server.

#### Scenario 3: Step over when game is not running

- **Description**: Call `step_over` with no active game session.
- **Params**: `{}`
- **Expected result**: Error — no active debugging session.
- **What to pay attention to**: Verify the correctness of the error message.

---

## Tool: `step_into`

**Description**: Step into the current function call when paused at a breakpoint.

**Parameters**: None (`inputSchema: {}`).

**Handler**: `callGodot(bridge, 'step_into')`

**Expected return**: JSON result confirming the step-into action, possibly with the new current location.

### Test Scenarios

#### Scenario 1: Step into a function call

- **Description**: Pause at a line that calls a function, then step into it.
- **Setup**:
  1. `set_breakpoint` at `res://scripts/test_debug.gd:6` (line: `var x = add(2, 3)`)
  2. Run the game and wait for it to pause at line 6
- **Params**: `{}`
- **Expected result**: Success response. The execution should move into the `add` function (line 10: `var result = a + b`). A subsequent `get_call_stack` should show `add` as the current function with `a = 2`, `b = 3`.
- **Notes**: This is the primary use case for `step_into` — following execution into a called function.
- **What to pay attention to**: Verify that the current function changed to `add`, and local variables `a` and `b` have values 2 and 3 respectively. The call stack should contain two frames: `add` and `_ready`.

#### Scenario 2: Step into when NOT paused

- **Description**: Call `step_into` when the game is running normally.
- **Setup**: Game is running, no breakpoint hit.
- **Params**: `{}`
- **Expected result**: Error — game is not paused at a breakpoint.
- **What to pay attention to**: The error should be clear.

#### Scenario 3: Step into when game is not running

- **Description**: Call `step_into` with no active game session.
- **Params**: `{}`
- **Expected result**: Error — no active debugging session.
- **What to pay attention to**: Verify the correctness of the error message.

---

## Tool: `continue_execution`

**Description**: Continue execution when paused at a breakpoint.

**Parameters**: None (`inputSchema: {}`).

**Handler**: `callGodot(bridge, 'continue_execution')`

**Expected return**: JSON result confirming execution has resumed.

### Test Scenarios

#### Scenario 1: Continue from a breakpoint

- **Description**: Game is paused at a breakpoint; resume execution.
- **Setup**:
  1. `set_breakpoint` at `res://scripts/test_debug.gd:5`
  2. Run the game and wait for it to pause
- **Params**: `{}`
- **Expected result**: Success response confirming execution resumed. The game should now be running (not paused).
- **Notes**: After continuing, `get_call_stack` should return an error or empty result (game is no longer paused).
- **What to pay attention to**: Verify that the game actually continues execution. Calling `get_call_stack` after this should show that the game is not paused.

#### Scenario 2: Continue when another breakpoint is set further down

- **Description**: Continue from breakpoint at line 5, but another breakpoint exists at line 7.
- **Setup**:
  1. `set_breakpoint` at line 5
  2. `set_breakpoint` at line 7
  3. Run the game, wait for pause at line 5
  4. Call `continue_execution`
- **Params**: `{}`
- **Expected result**: Execution resumes and immediately pauses again at line 7. `get_call_stack` should show line 7.
- **Notes**: Tests that `continue_execution` respects other breakpoints in the execution path.
- **What to pay attention to**: The game should stop at line 7, not continue execution to the end. Verify via `get_call_stack`.

#### Scenario 3: Continue when NOT paused

- **Description**: Call `continue_execution` when the game is running normally.
- **Setup**: Game is running, no breakpoint hit.
- **Params**: `{}`
- **Expected result**: Either a no-op success or an error indicating the game is not paused.
- **What to pay attention to**: Verify idempotency — repeated calls should not crash.

#### Scenario 4: Continue when game is not running

- **Description**: Call `continue_execution` with no active game session.
- **Params**: `{}`
- **Expected result**: Error — no active debugging session.
- **What to pay attention to**: Verify the correctness of the error message.

---

## Integration / Workflow Scenarios

These scenarios test multiple tools together in realistic debugging workflows.

### Workflow 1: Full breakpoint-hit-inspect-step-continue cycle

**Description**: Simulate a complete debugging session.

**Steps**:

1. **`set_breakpoint`** — Set breakpoint at `res://scripts/test_debug.gd:6`
   ```json
   { "script_path": "res://scripts/test_debug.gd", "line": 6 }
   ```
2. **Run the game** (via `run_scene` tool from `scene.ts` or editor play button)
3. **Wait** for the game to pause at line 6 (may need polling or delay)
4. **`get_call_stack`** — Inspect the call stack
   - Expect: frame at `_ready`, line 6, local variables visible
5. **`evaluate_expression`** — Check the value of `counter`
   ```json
   { "expression": "counter", "context": "game" }
   ```
   - Expect: `counter` = 1 (set on line 5)
6. **`step_over`** — Advance to line 7
   - Expect: success, now at line 7
7. **`evaluate_expression`** — Check the value of `x`
   ```json
   { "expression": "x", "context": "game" }
   ```
   - Expect: `x` = 5 (result of `add(2, 3)`)
8. **`continue_execution`** — Resume the game
   - Expect: success, game running
9. **`list_breakpoints`** — Verify breakpoint still exists
   - Expect: breakpoint at line 6 listed

**Notes**: This is the most important integration test — it exercises 6 of the 8 tools in sequence.

**What to pay attention to**: Each step depends on the previous one. If step 3 does not work (the game does not stop), all subsequent steps will fail. Ensure that the order is followed and states are correctly passed between calls.

### Workflow 2: Conditional breakpoint workflow

**Description**: Test conditional breakpoints in a loop.

**Steps**:

1. **`set_breakpoint`** at line 15 with condition `"i >= 3"`
   ```json
   { "script_path": "res://scripts/test_debug.gd", "line": 15, "condition": "i >= 3" }
   ```
2. **Call `loop_test()`** via `evaluate_expression`:
   ```json
   { "expression": "loop_test()", "context": "game" }
   ```
3. **Wait** for the game to pause (condition met when `i = 3`)
4. **`get_call_stack`** — Verify paused at line 15, `i` = 3
5. **`evaluate_expression`** — Check `i` and `counter`:
   ```json
   { "expression": "i", "context": "game" }
   ```
   - Expect: 3
6. **`continue_execution`** — Should pause again at `i = 4` (condition still true)
7. **`remove_breakpoint`** — Clean up
   ```json
   { "script_path": "res://scripts/test_debug.gd", "line": 15 }
   ```

**Notes**: This tests that conditional breakpoints correctly evaluate GDScript expressions at runtime and only pause when the condition is true.

**What to pay attention to**: The condition `"i >= 3"` should trigger at i=3, not at i=0,1,2. Verify that the breakpoint does not trigger prematurely.

### Workflow 3: Step-into and step-over chain

**Description**: Step into a function, then step through it line by line.

**Steps**:

1. **`set_breakpoint`** at line 6 (`var x = add(2, 3)`)
2. Run the game, wait for pause
3. **`step_into`** — Should enter `add()` at line 10
4. **`get_call_stack`** — Verify: function `add`, line 10, `a=2, b=3`
5. **`step_over`** — Advance to line 11 (`return result`)
6. **`evaluate_expression`** — Check `result`:
   ```json
   { "expression": "result", "context": "game" }
   ```
   - Expect: 5
7. **`step_over`** — Should return to `_ready` at line 7
8. **`get_call_stack`** — Verify back in `_ready`, line 7
9. **`continue_execution`** — Resume

**Notes**: Tests the combination of `step_into` and `step_over` across function boundaries.

**What to pay attention to**: After `step_into`, the stack should contain two frames. After returning from the function, the stack should return to one frame. Verify that local variables are correctly displayed in each frame.

---

## Edge Cases & Error Handling Summary

| Scenario | Tool(s) | Expected behavior |
|---|---|---|
| All required params missing | Any with required params | Zod validation error before handler runs |
| Invalid enum value for `context` | `evaluate_expression` | Zod enum rejection |
| Line = 0 or negative | `set_breakpoint`, `remove_breakpoint` | Zod `min(1)` rejection |
| Line = float (e.g. 5.5) | `set_breakpoint`, `remove_breakpoint` | Zod `int()` rejection |
| Non-existent script path | `set_breakpoint`, `remove_breakpoint` | Godot error (script not found) |
| Line exceeds script length | `set_breakpoint` | Godot error or silent acceptance |
| Empty expression string | `evaluate_expression` | Godot error or neutral result |
| Tools called when game is not running | `get_call_stack`, `step_over`, `step_into`, `continue_execution` | Error — no active session |
| Tools called when game is running but not paused | `get_call_stack`, `step_over`, `step_into` | Error — not paused |
| `continue_execution` when not paused | `continue_execution` | No-op or error |
| `remove_breakpoint` for non-existent breakpoint | `remove_breakpoint` | No-op or error |
| Duplicate `set_breakpoint` on same line | `set_breakpoint` | Idempotent or error |
| `list_breakpoints` with no breakpoints | `list_breakpoints` | Empty list |
| Invalid GDScript syntax in expression | `evaluate_expression` | Syntax error from Godot |
| Invalid GDScript syntax in condition | `set_breakpoint` | Error from Godot or accepted (validated at runtime) |

---

## Dependency Graph

```
set_breakpoint ──┐
                  ├──> list_breakpoints (verify state)
remove_breakpoint┘
        │
        ▼
   [run game] ──────> get_call_stack
        │                  │
        │                  ▼
        │           evaluate_expression
        │                  │
        │                  ▼
        ├──> step_over ──> get_call_stack (verify new position)
        ├──> step_into ──> get_call_stack (verify entered function)
        └──> continue_execution ──> get_call_stack (verify resumed)
```

**Key dependencies**:
- `set_breakpoint` must be called before `remove_breakpoint` for a deterministic test.
- `list_breakpoints` should be called after `set_breakpoint` and `remove_breakpoint` to verify state.
- `get_call_stack`, `step_over`, `step_into`, and `evaluate_expression` with `context: "game"` require the game to be running AND paused at a breakpoint.
- `continue_execution` requires the game to be paused.
- `evaluate_expression` with `context: "editor"` works without a running game.

**Related tools from other files** (needed for full workflow testing):
- `run_scene` (from `scene.ts`) — to start the game
- `stop_scene` (from `scene.ts`) — to stop the game between tests
- `execute_editor_script` (from `editor.ts`) — alternative way to trigger code execution
