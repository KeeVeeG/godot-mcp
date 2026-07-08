# Editor Tools — Test Plan

**Source file:** `server/src/tools/editor.ts`
**Generated:** 2026-07-08

---

## Shared Types Used

| Import | Type | Notes |
|--------|------|-------|
| `NodePath` | `z.string().describe('Node path in the scene tree...')` | Plain string; empty `''` = scene root, `'Player'` = root-level child, `'Player/Sprite2D'` = nested |
| `GDScriptCode` | `z.string().describe('GDScript code to execute')` | Plain string containing GDScript source |
| `z` | Zod namespace | Re-exported from `shared-types.ts` |

All 9 tools call `callGodot(bridge, '<endpoint>', args)` which delegates to the Godot editor plugin via WebSocket (`bridge.sendRequest`). Tools return `ToolResult` (JSON-stringified content). Error responses have `isError: true`. Timeout is 30 seconds by default.

---

## Tool: `get_editor_errors`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| *(none)* | — | — | No input parameters |

### Handler

Calls `callGodot(bridge, 'editor/get_errors')` — no args forwarded. Validates all GDScripts in the current scene tree and returns compilation errors.

### Test Scenarios

#### Scenario 1: Basic happy path — no errors in scene
- **Description:** Call on a scene with no script errors. Expect an empty errors list.
- **Params:** `{}`
- **Expected result:** Success. Returns a JSON object with an errors array (likely empty or near-empty). No `isError` flag.
- **Notes:** Read-only tool; does not mutate editor state. The exact response structure depends on Godot's `ScriptEditor` API.

#### Scenario 2: Scene with a script syntax error
- **Description:** Create a scene with a node that has a script containing a syntax error, then call `get_editor_errors`. Expect at least one error to be reported.
- **Params:** `{}`
- **Expected result:** Success. Returns a JSON object with an errors array containing at least one entry. Each entry should include source path, line number, and error message.
- **Notes:** Pre-requisite: a script with an error must be attached to a node in the current scene. After the test, remove or fix the broken script.

#### Scenario 3: Call twice in succession
- **Description:** Call `get_editor_errors` twice with no state change between calls. Expect identical results.
- **Params:** `{}` (both calls)
- **Expected result:** Both calls return the same errors list. Second call should match first call.
- **Notes:** Idempotency check. No side effects expected.

#### Scenario 4: Call with no arguments (empty object)
- **Description:** Invoke with an explicit empty object `{}`.
- **Params:** `{}`
- **Expected result:** Success (same as Scenario 1). No required params.

---

## Tool: `get_editor_screenshot`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `path` | `string` | No | Custom save path for the screenshot |

### Handler

Calls `callGodot(bridge, 'editor/get_screenshot', args)` with optional `path` forwarded. Returns a base64-encoded image of the Godot editor window.

### Test Scenarios

#### Scenario 1: Happy path — default path (no arguments)
- **Description:** Capture editor screenshot without specifying a path. Expect base64 image returned.
- **Params:** `{}`
- **Expected result:** Success. Returns a JSON object containing a base64-encoded image string. The response should include the path where the screenshot was saved (Godot default location).

#### Scenario 2: Happy path — custom save path
- **Description:** Capture editor screenshot with a custom file path.
- **Params:**
  ```json
  {
    "path": "res://screenshots/editor_test.png"
  }
  ```
- **Expected result:** Success. Screenshot saved to `res://screenshots/editor_test.png`. Returns base64 image and/or confirmation of the save path.
- **Notes:** The `screenshots` directory must exist, or the tool should create it.

#### Scenario 3: Custom path with subdirectory
- **Description:** Save screenshot to a nested path.
- **Params:**
  ```json
  {
    "path": "res://screenshots/editor/capture_001.png"
  }
  ```
- **Expected result:** Success. Screenshot saved at the specified nested path.

#### Scenario 4: Path with `.jpg` extension
- **Description:** Specify a `.jpg` path to test if the format is inferred from extension.
- **Params:**
  ```json
  {
    "path": "res://screenshots/editor_test.jpg"
  }
  ```
- **Expected result:** Success or graceful handling. The Godot editor screenshot API typically saves as PNG; if the extension is ignored/overridden, a PNG file may be saved regardless.
- **Notes:** Behavior depends on Godot's implementation. If it rejects non-PNG, expect an error with a clear message.

#### Scenario 5: Invalid path — non-res:// path
- **Description:** Provide a filesystem path outside the project.
- **Params:**
  ```json
  {
    "path": "/tmp/screenshot.png"
  }
  ```
- **Expected result:** Error. Returns `isError: true` with a message indicating the path must be within the project.
- **Notes:** Godot restricts file access to `res://` and `user://` paths. Absolute filesystem paths should be rejected.

#### Scenario 6: Path with trailing slash (directory)
- **Description:** Provide a path ending with `/` as if specifying a directory.
- **Params:**
  ```json
  {
    "path": "res://screenshots/"
  }
  ```
- **Expected result:** Error or auto-generated filename. The tool should either reject directory paths or auto-generate a filename within that directory.
- **Notes:** Edge case for path validation.

#### Scenario 7: Very long path (> 260 characters)
- **Description:** Provide a path with an extremely long filename (close to OS limits).
- **Params:**
  ```json
  {
    "path": "res://screenshots/aaaaaaaaa... (250+ chars) ...aaaa.png"
  }
  ```
- **Expected result:** Error. Should fail gracefully with a meaningful error message about path length.
- **Notes:** Windows has a 260-char path limit by default; other OSes may handle longer paths.

#### Scenario 8: Empty string path
- **Description:** Provide an empty string for path.
- **Params:**
  ```json
  {
    "path": ""
  }
  ```
- **Expected result:** Should behave like Scenario 1 (default path) or return an error about invalid path. The behavior depends on how Godot handles an empty path string.

---

## Tool: `get_game_screenshot`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `path` | `string` | No | Custom save path for the screenshot |

### Handler

Calls `callGodot(bridge, 'editor/get_game_screenshot', args)` with optional `path` forwarded. Returns a base64-encoded image of the running game viewport.

### Test Scenarios

#### Scenario 1: Happy path — game is running
- **Description:** Start the game (via play_scene), then capture a game screenshot without specifying a path.
- **Params:** `{}`
- **Expected result:** Success. Returns a JSON object with a base64-encoded image of the game viewport.
- **Notes:** Pre-requisite: game must be running (`play_scene`). If game is not running, this should return an error.

#### Scenario 2: Happy path — custom save path while game runs
- **Description:** Capture game screenshot with a custom file path while the game is running.
- **Params:**
  ```json
  {
    "path": "res://screenshots/game_test.png"
  }
  ```
- **Expected result:** Success. Screenshot saved to the specified path. Returns base64 image.

#### Scenario 3: Game NOT running — should error
- **Description:** Call `get_game_screenshot` while no scene is playing.
- **Params:** `{}`
- **Expected result:** Error. Returns `isError: true` with a message indicating the game is not running or the viewport is unavailable.
- **Notes:** Runtime tools require an active game session. The autoload `mcp_runtime.gd` must be present.

#### Scenario 4: Capture during scene transition
- **Description:** Call `get_game_screenshot` immediately after changing scenes (during a load/fade).
- **Params:** `{}`
- **Expected result:** Success (may return a black frame or loading screen). Should not crash or timeout.
- **Notes:** Stress-test for timing edge cases.

#### Scenario 5: Capture multiple screenshots in rapid succession
- **Description:** Call `get_game_screenshot` 5 times in quick succession.
- **Params:** `{}` (all calls)
- **Expected result:** All 5 calls succeed. Each returns a valid base64 image. No memory leaks or timeouts.
- **Notes:** Tests for resource leaks or race conditions.

#### Scenario 6: Invalid path — same edge cases as get_editor_screenshot
- **Description:** Same edge cases: non-res:// path, empty string, trailing slash, very long path.
- **Params:** Same as `get_editor_screenshot` Scenarios 5–8.
- **Expected result:** Same behavior as `get_editor_screenshot` for path validation.

---

## Tool: `execute_editor_script`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `code` | `string` (GDScriptCode) | **Yes** | GDScript code to execute in the editor context |

### Handler

Calls `callGodot(bridge, 'editor/execute_script', args)`. Runs the provided GDScript as an EditorScript in the Godot editor context. The script has access to the `EditorInterface` singleton and can manipulate the editor state.

### Test Scenarios

#### Scenario 1: Happy path — simple print statement
- **Description:** Execute a basic GDScript that prints a message.
- **Params:**
  ```json
  {
    "code": "print(\"Hello from editor script\")"
  }
  ```
- **Expected result:** Success. The output log should contain "Hello from editor script". The tool returns the script result (if any).
- **Notes:** This is the simplest valid script. Use `get_output_log` afterward to verify the print appeared.

#### Scenario 2: Happy path — script that returns a value
- **Description:** Execute a GDScript that computes and returns a value.
- **Params:**
  ```json
  {
    "code": "var result = 2 + 2; return result"
  }
  ```
- **Expected result:** Success. Returns the computed value (e.g., `4`).
- **Notes:** EditorScript runs in the editor context. The return value mechanism depends on the Godot MCP plugin's implementation.

#### Scenario 3: Happy path — access EditorInterface
- **Description:** Execute a script that accesses the editor's `EditorInterface` singleton.
- **Params:**
  ```json
  {
    "code": "var ei = EditorInterface; print(ei.get_edited_scene_root().name)"
  }
  ```
- **Expected result:** Success. Prints the name of the current scene's root node. No errors.
- **Notes:** Validates that the editor context is properly available.

#### Scenario 4: Happy path — access the current scene selection
- **Description:** Execute a script that reads the current editor selection.
- **Params:**
  ```json
  {
    "code": "var sel = EditorInterface.get_selection(); var nodes = sel.get_selected_nodes(); return nodes.size()"
  }
  ```
- **Expected result:** Success. Returns the number of selected nodes (e.g., `0` if nothing selected, `1` if one node selected).

#### Scenario 5: Happy path — multi-line script
- **Description:** Execute a multi-line GDScript with variables and control flow.
- **Params:**
  ```json
  {
    "code": "var total = 0\nfor i in range(10):\n    total += i\nreturn total"
  }
  ```
- **Expected result:** Success. Returns `45` (sum of 0–9).

#### Scenario 6: Happy path — script with a class definition
- **Description:** Execute a script that defines and uses an inner class.
- **Params:**
  ```json
  {
    "code": "class MyCalc:\n    func add(a, b):\n        return a + b\nvar calc = MyCalc.new()\nreturn calc.add(3, 7)"
  }
  ```
- **Expected result:** Success. Returns `10`.

#### Scenario 7: Empty code string
- **Description:** Pass an empty string for `code`.
- **Params:**
  ```json
  {
    "code": ""
  }
  ```
- **Expected result:** Error or success (no-op). The tool may reject empty code as invalid, or Godot may execute it as an empty script and return nothing.
- **Notes:** Edge case. If rejected, expect `isError: true` with a message about empty code.

#### Scenario 8: Missing required parameter
- **Description:** Call the tool without the `code` parameter.
- **Params:** `{}`
- **Expected result:** Error. Zod validation fails because `code` is required. Returns a validation error (before reaching Godot).
- **Notes:** This is caught at the MCP server layer by Zod, not by Godot.

#### Scenario 9: Invalid GDScript — syntax error
- **Description:** Execute a GDScript with a deliberate syntax error.
- **Params:**
  ```json
  {
    "code": "var x = ;"
  }
  ```
- **Expected result:** Error. Returns `isError: true` with a message describing the parse/syntax error, including line number.
- **Notes:** Godot's GDScript parser should report the specific error.

#### Scenario 10: Invalid GDScript — runtime error
- **Description:** Execute a GDScript that compiles but throws a runtime error.
- **Params:**
  ```json
  {
    "code": "var node = Node.new(); node.call(\"nonexistent_method\")"
  }
  ```
- **Expected result:** Error. Returns `isError: true` with a message about the runtime error (e.g., "Invalid call. Nonexistent function...").
- **Notes:** Validates that runtime errors are properly caught and reported.

#### Scenario 11: Very long script (> 10,000 characters)
- **Description:** Execute a very large GDScript (e.g., 10,000+ characters of valid code).
- **Params:**
  ```json
  {
    "code": "var x = 1\nvar x = 1\n... (5000 lines of no-ops) ..."
  }
  ```
- **Expected result:** Should succeed or fail gracefully. Must not crash the editor or cause a timeout.
- **Notes:** The tool may impose a code size limit. If so, expect a clear error message.

#### Scenario 12: Script with special characters / Unicode
- **Description:** Execute a script containing Unicode characters in strings and identifiers.
- **Params:**
  ```json
  {
    "code": "var 名前 = \"こんにちは\"\nprint(名前)\nreturn 名前"
  }
  ```
- **Expected result:** Success or clear error. If GDScript supports Unicode identifiers, returns the string. If not, expect a parse error.
- **Notes:** Godot 4.x GDScript has limited Unicode identifier support. Test for graceful handling.

#### Scenario 13: Script with infinite loop — timeout
- **Description:** Execute a script with an intentional infinite loop.
- **Params:**
  ```json
  {
    "code": "while true:\n    pass"
  }
  ```
- **Expected result:** Error. Should timeout (30s default) and return `isError: true` with a timeout message. Must not hang the MCP server.
- **Notes:** Critical for robustness. The Godot plugin or bridge should have a timeout mechanism.

---

## Tool: `clear_output`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| *(none)* | — | — | No input parameters |

### Handler

Calls `callGodot(bridge, 'editor/clear_output')` — no args forwarded. Clears the editor output log.

### Test Scenarios

#### Scenario 1: Happy path — clear after some output
- **Description:** First write something to the output log (via `execute_editor_script` with a `print`), verify output exists via `get_output_log`, then call `clear_output`, then verify output is cleared.
- **Params:** `{}`
- **Expected result:** Success. After the call, `get_output_log` should return empty or minimal output (logs generated after the clear).
- **Notes:** Requires sequential calls: `execute_editor_script` → `get_output_log` (confirm content) → `clear_output` → `get_output_log` (confirm cleared).

#### Scenario 2: Clear when already empty
- **Description:** Call `clear_output` when the output log is already empty.
- **Params:** `{}`
- **Expected result:** Success. No error. `get_output_log` should still be empty afterward.
- **Notes:** Idempotency check.

#### Scenario 3: Clear multiple times in succession
- **Description:** Call `clear_output` 3 times in a row.
- **Params:** `{}` (all calls)
- **Expected result:** All 3 calls succeed. No errors.
- **Notes:** Repeated calls should be harmless.

#### Scenario 4: Call with no arguments
- **Description:** Invoke with empty object `{}`.
- **Params:** `{}`
- **Expected result:** Success.

---

## Tool: `get_signals`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `node_path` | `string` (NodePath) | **Yes** | Node path to inspect |

### Handler

Calls `callGodot(bridge, 'editor/get_signals', args)`. Returns all signals defined on the specified node type and their current connections (source, target, method).

### Test Scenarios

#### Scenario 1: Happy path — inspect a root-level node
- **Description:** Call with a simple root-level node name (e.g., a node named "Player").
- **Params:**
  ```json
  {
    "node_path": "Player"
  }
  ```
- **Expected result:** Success. Returns a JSON object listing signals available on the node type (e.g., `ready`, `process`, custom signals) and any connections that exist. Each signal entry should include name, arguments, and connected targets.
- **Notes:** Pre-requisite: a scene is open with a node named "Player" at root level.

#### Scenario 2: Happy path — inspect a nested node
- **Description:** Call with a path to a nested child node.
- **Params:**
  ```json
  {
    "node_path": "Player/Sprite2D"
  }
  ```
- **Expected result:** Success. Returns signals and connections for the nested Sprite2D node.

#### Scenario 3: Happy path — inspect the scene root
- **Description:** Call with empty string to inspect the scene root node.
- **Params:**
  ```json
  {
    "node_path": ""
  }
  ```
- **Expected result:** Success. Returns signals and connections for the scene root node.

#### Scenario 4: Happy path — node with connected signals
- **Description:** Create a button node, connect its `pressed` signal to a method, then call `get_signals`.
- **Params:**
  ```json
  {
    "node_path": "MyButton"
  }
  ```
- **Expected result:** Success. Returns signals including `pressed`, and shows the connection (source: "MyButton", signal: "pressed", target: some node, method: some method).
- **Notes:** Pre-requisite: a button with a connected signal must exist in the scene.

#### Scenario 5: Missing required parameter
- **Description:** Call without `node_path`.
- **Params:** `{}`
- **Expected result:** Error. Zod validation fails. Returns a validation error message.

#### Scenario 6: Non-existent node path
- **Description:** Call with a node path that does not exist in the scene.
- **Params:**
  ```json
  {
    "node_path": "NonExistentNode"
  }
  ```
- **Expected result:** Error. Returns `isError: true` with a message like "Node not found: NonExistentNode".
- **Notes:** The Godot plugin should return a clear error for missing nodes.

#### Scenario 7: Path with invalid characters
- **Description:** Call with a path containing characters that are invalid in node names.
- **Params:**
  ```json
  {
    "node_path": "../illegal"
  }
  ```
- **Expected result:** Error. Returns `isError: true` with a message about invalid path or node not found.

#### Scenario 8: Very long node path
- **Description:** Call with a deeply nested path (e.g., 10+ levels deep).
- **Params:**
  ```json
  {
    "node_path": "A/B/C/D/E/F/G/H/I/J/K"
  }
  ```
- **Expected result:** Success or clear "node not found" error. Must not crash.
- **Notes:** Pre-requisite: the nested hierarchy must exist. If not, expect "Node not found".

#### Scenario 9: Node with custom signals
- **Description:** Inspect a node that has a script with custom signal definitions.
- **Params:**
  ```json
  {
    "node_path": "CustomSignalNode"
  }
  ```
- **Expected result:** Success. The returned signal list should include the custom signal(s) defined in the script.
- **Notes:** Pre-requisite: a node with a script defining `signal my_custom_signal(arg1, arg2)`.

---

## Tool: `reload_plugin`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| *(none)* | — | — | No input parameters |

### Handler

Calls `callGodot(bridge, 'editor/reload_plugin')` — no args forwarded. Triggers re-initialization of all editor plugins.

### Test Scenarios

#### Scenario 1: Happy path — reload plugins
- **Description:** Call `reload_plugin` and verify it completes without error.
- **Params:** `{}`
- **Expected result:** Success. Tool returns a success confirmation. The MCP plugin itself should reload and reconnect.
- **Notes:** This can be disruptive — the MCP plugin may briefly disconnect and reconnect. The test runner should account for a possible brief disconnection.
- **⚠️ CAUTION:** Since this reloads the MCP plugin itself, subsequent tool calls may fail temporarily while the plugin reconnects. Test this scenario in isolation.

#### Scenario 2: Call twice in succession
- **Description:** Call `reload_plugin` twice with a brief wait between calls.
- **Params:** `{}` (both calls)
- **Expected result:** First call succeeds. Second call succeeds after the plugin reconnects.
- **Notes:** Wait at least 2-3 seconds between calls for the plugin to reinitialize.

#### Scenario 3: Call when no plugins are loaded
- **Description:** This is difficult to test; Godot always has built-in plugins. Call normally.
- **Params:** `{}`
- **Expected result:** Success.

---

## Tool: `reload_project`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| *(none)* | — | — | No input parameters |

### Handler

Calls `callGodot(bridge, 'editor/reload_project')` — no args forwarded. Rescans the project filesystem for new or changed files.

### Test Scenarios

#### Scenario 1: Happy path — reload the project
- **Description:** Call `reload_project` and verify it completes without error.
- **Params:** `{}`
- **Expected result:** Success. The project filesystem is rescanned. Any newly added files (e.g., created externally) should become visible.
- **Notes:** Can be verified by creating a file outside Godot, calling `reload_project`, then checking the filesystem tree.

#### Scenario 2: Call twice in succession
- **Description:** Call `reload_project` twice rapidly.
- **Params:** `{}` (both calls)
- **Expected result:** Both calls succeed. No errors or warnings.
- **Notes:** Idempotency check.

#### Scenario 3: Reload during script editing
- **Description:** Open a script in the editor, make unsaved changes, then call `reload_project`.
- **Params:** `{}`
- **Expected result:** Success. The project reload should complete without interfering with unsaved script changes (Godot handles this gracefully).
- **Notes:** Godot should warn if there are unsaved changes, but the MCP bridge may auto-dismiss dialogs.

---

## Tool: `get_output_log`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| *(none)* | — | — | No input parameters |

### Handler

Calls `callGodot(bridge, 'editor/get_output_log')` — no args forwarded. Returns the current contents of the editor output log.

### Test Scenarios

#### Scenario 1: Happy path — read output log
- **Description:** Call after some activity has generated output (e.g., scene loaded, script executed).
- **Params:** `{}`
- **Expected result:** Success. Returns a JSON object with the output log content. The content should be a string or array of log entries.
- **Notes:** The exact format depends on the Godot plugin's serialization of the output log. May include timestamps, message types.

#### Scenario 2: Read immediately after `clear_output`
- **Description:** Call `clear_output`, then immediately call `get_output_log`.
- **Params:** `{}`
- **Expected result:** Success. Returns empty or minimal content (only logs generated after the clear).
- **Notes:** Tests that `clear_output` actually cleared the log.

#### Scenario 3: Read after generating error output
- **Description:** Execute a script that generates an error (e.g., `printerr("test error")`), then call `get_output_log`.
- **Params:** `{}`
- **Expected result:** Success. The output log should contain the error message "test error", possibly tagged as an error type.
- **Notes:** Pre-requisite: call `execute_editor_script` with `printerr("test error")` first.

#### Scenario 4: Read after generating multiple log types
- **Description:** Execute multiple scripts that generate `print`, `printerr`, and `push_warning` messages, then read the log.
- **Params:** `{}`
- **Expected result:** Success. All messages appear in the log, possibly with type indicators (info/warning/error).
- **Notes:** Validates that all Godot output channels are captured.

#### Scenario 5: Call with no arguments
- **Description:** Invoke with empty object `{}`.
- **Params:** `{}`
- **Expected result:** Success.

#### Scenario 6: Very large log — performance check
- **Description:** Generate a large volume of output (e.g., a loop printing 10,000 lines), then call `get_output_log`.
- **Params:** `{}`
- **Expected result:** Success. Should return the log content without timeout. If truncated, the response should indicate truncation.
- **Notes:** Tests for memory and timeout handling with large payloads.

---

## Cross-Tool Integration Scenarios

These scenarios test multiple editor tools working together in sequence.

### Scenario A: Edit → Execute → Read Log → Clear
1. `execute_editor_script` with `print("step 1")`
2. `execute_editor_script` with `print("step 2")`
3. `get_output_log` — verify both messages present
4. `clear_output`
5. `get_output_log` — verify cleared
- **Expected:** All steps succeed. Log contains messages then is empty.

### Scenario B: Get Signals → Execute Script → Get Signals
1. `get_signals` on a node — record initial state
2. `execute_editor_script` with code that connects a signal on that node
3. `get_signals` on the same node — verify the new connection appears
- **Expected:** Signal connections list should differ between step 1 and step 3.

### Scenario C: Screenshot Before/After Editor Script
1. `get_editor_screenshot` — capture initial state
2. `execute_editor_script` with code that modifies the editor UI (e.g., opens a dock)
3. `get_editor_screenshot` — capture modified state
- **Expected:** Both screenshots succeed. The two images should differ visually.

### Scenario D: Get Errors → Fix Script → Reload → Get Errors
1. `get_editor_errors` — note any existing errors
2. `execute_editor_script` with code that creates a temporary broken script
3. `get_editor_errors` — verify the new error appears
4. Fix or delete the broken script externally
5. `reload_project`
6. `get_editor_errors` — verify the error is gone
- **Expected:** Errors appear after step 3, disappear after step 6.

---

## Summary

| Tool | Params | Required | Writes State? |
|------|--------|----------|---------------|
| `get_editor_errors` | none | — | No |
| `get_editor_screenshot` | `path?` | — | No (writes file) |
| `get_game_screenshot` | `path?` | — | No (writes file) |
| `execute_editor_script` | `code` | Yes | Yes (mutates editor) |
| `clear_output` | none | — | Yes (clears log) |
| `get_signals` | `node_path` | Yes | No |
| `reload_plugin` | none | — | Yes (reloads plugins) |
| `reload_project` | none | — | Yes (rescans FS) |
| `get_output_log` | none | — | No |
