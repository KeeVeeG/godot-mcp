# Editor Tools Test Plan

**Source**: `server/src/tools/editor.ts`
**GDScript backend**: `addons/godot_mcp/commands/editor_commands.gd`
**Total tools**: 9
**Test plan generated**: 2026-07-08

---

## Table of Contents

1. [Tool: get_editor_errors](#tool-get_editor_errors)
2. [Tool: get_editor_screenshot](#tool-get_editor_screenshot)
3. [Tool: get_game_screenshot](#tool-get_game_screenshot)
4. [Tool: execute_editor_script](#tool-execute_editor_script)
5. [Tool: clear_output](#tool-clear_output)
6. [Tool: get_signals](#tool-get_signals)
7. [Tool: reload_plugin](#tool-reload_plugin)
8. [Tool: reload_project](#tool-reload_project)
9. [Tool: get_output_log](#tool-get_output_log)

---

## Tool: get_editor_errors

**Tool name**: `get_editor_errors`
**Description**: Validate all GDScripts in the current scene tree and return compilation errors
**Backend method**: `editor/get_errors`

### Parameters

None. This tool takes no parameters.

### Handler Logic

Walks the entire scene tree of the currently open scene recursively. For each node that has a GDScript attached, it calls `gd.reload(true)` to force recompilation. If compilation fails (return code != OK), the error is collected with node path, script path, and error message. Returns all errors found.

### Test Scenarios

#### Scenario 1: Happy path — clean scene with no errors

**Description**: Call on a scene where all attached scripts compile without errors.
**Params**:
```json
{}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true`, `errors: []` (empty array), `count: 0`.
**Notes**: Prerequisite: a scene must be open in the editor. All scripts attached to nodes in the scene must be valid GDScript.
**Pay attention**: Ensure that `errors` is an empty array and `count` is 0. The response should not contain `isError: true`.

---

#### Scenario 2: Happy path — scene with compilation errors

**Description**: Call on a scene that has at least one node with a broken GDScript (e.g., syntax error).
**Params**:
```json
{}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true`, `errors` is a non-empty array, `count` > 0. Each error object should have fields: `node` (string path), `script` (string res:// path), `error` (string with "Compilation error (code: N)").
**Notes**: Prerequisite: create a scene with a node that has a script containing a deliberate syntax error (e.g., `if true` without colon).
**Pay attention**: Verify that each error object contains `node`, `script`, and `error` fields. The node path should be relative to the scene root. The script path starts with `res://`.

---

#### Scenario 3: Edge case — no scene open

**Description**: Call when no scene is currently open in the editor.
**Params**:
```json
{}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true`, `errors: []`, `count: 0`. When `root` is null on the GDScript side, it returns an empty error list rather than failing.
**Notes**: Close all scenes in the editor before calling. The tool does not error — it silently returns an empty list.
**Pay attention**: The tool does NOT return an error when there is no open scene — it returns an empty list. This may be unexpected behavior.

---

#### Scenario 4: Edge case — deeply nested scene tree

**Description**: Call on a scene with deeply nested nodes (5+ levels), each with scripts, some broken.
**Params**:
```json
{}
```
**Expected result**: All errors from all depths are collected. The recursive walk should find errors at any nesting level.
**Notes**: Create a scene structure like `Root > Level1 > Level2 > Level3 > Level4 > Level5` where some nodes have broken scripts.
**Pay attention**: Verify that the recursive walk actually finds errors at all nesting levels, not just the first two.

---

## Tool: get_editor_screenshot

**Tool name**: `get_editor_screenshot`
**Description**: Take a screenshot of the Godot editor window
**Backend method**: `editor/get_screenshot`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `z.string().optional()` | No | `"user://mcp_editor_screenshot.png"` | Custom save path for the screenshot |

### Handler Logic

Captures the editor viewport by calling `viewport.get_texture().get_image()` on the editor's root viewport, then saves as PNG to the specified path (or default `user://mcp_editor_screenshot.png`). Returns the save path, width, and height of the captured image.

### Test Scenarios

#### Scenario 1: Happy path — no params (default path)

**Description**: Take a screenshot of the editor with default save path.
**Params**:
```json
{}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true`, `path: "user://mcp_editor_screenshot.png"`, `width` and `height` as positive integers representing the editor viewport dimensions.
**Notes**: The editor must be open and have a visible viewport. The file is saved relative to Godot's `user://` directory.
**Pay attention**: Verify that `width` and `height` are positive numbers. The default path is `user://mcp_editor_screenshot.png`. The file should exist in the Godot filesystem after the call.

---

#### Scenario 2: Happy path — custom save path

**Description**: Take a screenshot and save it to a custom path.
**Params**:
```json
{
  "path": "user://custom_screenshot.png"
}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true`, `path: "user://custom_screenshot.png"`, `width` and `height` as positive integers.
**Notes**: Verify the file is saved at the custom path, not the default.
**Pay attention**: Ensure that the screenshot is saved at the specified path, not the default. Verify that the file was created.

---

#### Scenario 3: Edge case — path with special characters

**Description**: Save screenshot to a path containing spaces or special characters.
**Params**:
```json
{
  "path": "user://my screenshot (1).png"
}
```
**Expected result**: Either succeeds with `success: true` and the exact path returned, or fails gracefully with a meaningful error if the path is invalid.
**Notes**: Tests path handling robustness.
**Pay attention**: Verify the correctness of path handling with special characters. If Godot does not support such paths in filenames, there should be a clear error response.

---

## Tool: get_game_screenshot

**Tool name**: `get_game_screenshot`
**Description**: Take a screenshot of the running game viewport
**Backend method**: `editor/get_game_screenshot`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `z.string().optional()` | No | `"user://mcp_game_screenshot.png"` | Custom save path for the screenshot |

### Handler Logic

First checks if the game is currently running (`is_playing_scene()`). If not, returns an error. If running, writes a request JSON to `user://mcp_runtime_request.json` for the runtime autoload to pick up, then polls for `user://mcp_runtime_response.json` with a 3-second timeout. The runtime captures the game viewport image and saves it.

### Test Scenarios

#### Scenario 1: Happy path — game is running, default path

**Description**: Take a screenshot while a scene is playing.
**Params**:
```json
{}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true` and the screenshot details from the runtime.
**Notes**: Prerequisite: a scene must be playing in the editor (use `play_scene` tool first). The runtime autoload `mcp_runtime.gd` must be active.
**Pay attention**: The game must be running. Without this, scenario 3 will show the "Game is not running" error. Verify that the screenshot file was created.

---

#### Scenario 2: Happy path — custom save path

**Description**: Take a game screenshot with a custom save path while game is running.
**Params**:
```json
{
  "path": "user://game_test_capture.png"
}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true` and the custom path.
**Notes**: Game must be running.
**Pay attention**: Verify that the screenshot is saved at the specified custom path.

---

#### Scenario 3: Error — game is not running

**Description**: Attempt to take a game screenshot when no scene is playing.
**Params**:
```json
{}
```
**Expected result**: `content[0].text` contains a JSON object with `success: false` and `error: "Game is not running"`. The MCP result should have `isError: true`.
**Notes**: Ensure no scene is playing before calling.
**Pay attention**: A clear "Game is not running" error should be returned. Verify that `isError: true` is in the MCP response.

---

#### Scenario 4: Edge case — runtime timeout

**Description**: Game is running but the runtime autoload is not responding (e.g., removed or crashed).
**Params**:
```json
{}
```
**Expected result**: After 3 seconds of polling, returns `success: false` with `error: "Runtime screenshot timed out"`.
**Notes**: This is a hard-to-reproduce edge case. To test: remove `mcp_runtime.gd` from autoloads while the game is running, or corrupt the runtime script.
**Pay attention**: Timeout is 3 seconds. If the runtime does not respond, there should be a clear timeout error response, not a hang.

---

## Tool: execute_editor_script

**Tool name**: `execute_editor_script`
**Description**: Execute a GDScript snippet in the editor context (EditorScript)
**Backend method**: `editor/execute_script`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `code` | `z.string()` | **Yes** | — | GDScript code to execute |

### Handler Logic

Wraps the provided GDScript code into an `EditorScript` class (extends EditorScript, with a `_run()` method). If the code contains `return <expr>`, the expression is captured via a `_mcp_return_value` class member. The script is compiled (`reload(true)`), instantiated, and `_run()` is called. Returns the captured return value or a success message.

### Test Scenarios

#### Scenario 1: Happy path — simple expression with return value

**Description**: Execute a simple GDScript expression that returns a value.
**Params**:
```json
{
  "code": "return 2 + 2"
}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true` and `result: 4`.
**Notes**: The simplest valid EditorScript — a single return statement.
**Pay attention**: Verify that `result` contains exactly the number 4, not the string "4". The value is captured via `_mcp_return_value`.

---

#### Scenario 2: Happy path — code without return value

**Description**: Execute GDScript code that performs an action but returns nothing.
**Params**:
```json
{
  "code": "print('Hello from editor script')"
}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true` and `message: "Editor script executed successfully"`. No `result` field.
**Notes**: When no `return` statement is present, the tool returns a generic success message.
**Pay attention**: Ensure that the `result` field is absent and `message` is present. The code executed without errors.

---

#### Scenario 3: Happy path — multi-line code

**Description**: Execute multi-line GDScript code with variables and logic.
**Params**:
```json
{
  "code": "var x = 10\nvar y = 20\nreturn x + y"
}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true` and `result: 30`.
**Notes**: Tests that multi-line code is correctly wrapped with proper indentation.
**Pay attention**: Verify that newlines and indentation are handled correctly when wrapping in EditorScript. The result should be 30.

---

#### Scenario 4: Happy path — accessing editor API

**Description**: Execute code that accesses the editor API (e.g., getting the edited scene root).
**Params**:
```json
{
  "code": "return get_editor_interface().get_edited_scene_root().name"
}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true` and `result` is the name of the currently open scene's root node (string).
**Notes**: EditorScript has access to `get_editor_interface()`. This tests that the EditorScript context is properly initialized.
**Pay attention**: Verify that `result` is a string with the root node's name. If no scene is open, a null reference error may occur.

---

#### Scenario 5: Error — empty code

**Description**: Call with an empty string as code.
**Params**:
```json
{
  "code": ""
}
```
**Expected result**: `content[0].text` contains a JSON object with `success: false` and `error: "Code cannot be empty"`. MCP result should have `isError: true`.
**Notes**: The GDScript side explicitly checks for empty code before attempting compilation.
**Pay attention**: A clear "Code cannot be empty" error should be returned. Check `isError: true`.

---

#### Scenario 6: Error — syntax error in code

**Description**: Execute code with a GDScript syntax error.
**Params**:
```json
{
  "code": "if true\nprint('no indent')"
}
```
**Expected result**: `content[0].text` contains a JSON object with `success: false` and `error` containing "Script compilation failed" with the specific GDScript error.
**Notes**: The script `reload(true)` call will fail, and the tool returns the compilation error.
**Pay attention**: Verify that the GDScript compilation error is correctly propagated into the response. The message should contain error details.

---

#### Scenario 7: Edge case — code with bare return

**Description**: Execute code with a bare `return` statement (void return).
**Params**:
```json
{
  "code": "print('before')\nreturn\nprint('after')"
}
```
**Expected result**: `content[0].text` contains `success: true` with `message: "Editor script executed successfully"`. The bare `return` should cause early exit; `print('after')` should not execute.
**Notes**: Tests the special handling of bare `return` in the code wrapper.
**Pay attention**: Verify that the wrapper correctly handles `return` without a value. Code after return should not execute.

---

#### Scenario 8: Edge case — code with string containing "return"

**Description**: Execute code where "return" appears inside a string, not as a keyword.
**Params**:
```json
{
  "code": "var msg = 'return value'\nreturn msg"
}
```
**Expected result**: `content[0].text` contains `success: true` and `result: "return value"`.
**Notes**: The wrapper uses `begins_with("return ")` on trimmed lines, so a line starting with `var msg = 'return...'` should NOT be intercepted. Only lines that literally start with `return ` after trimming are captured.
**Pay attention**: Important edge case — the string contains the word "return", but it is not a return statement. Verify that the wrapper does not break and returns "return value".

---

## Tool: clear_output

**Tool name**: `clear_output`
**Description**: Clear the editor output log
**Backend method**: `editor/clear_output`

### Parameters

None. This tool takes no parameters.

### Handler Logic

Finds the `EditorLog` node in the editor UI tree by traversing from `base_control`. If found and it has a `clear()` method, calls it. If not found, falls back to switching the main screen editor to "Script" tab to trigger a UI refresh.

### Test Scenarios

#### Scenario 1: Happy path — clear output log

**Description**: Clear the editor output log when it contains messages.
**Params**:
```json
{}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true` and `message: "Output cleared"` (primary method) or `message: "Output clear requested (fallback method)"` (fallback).
**Notes**: Before calling, generate some output (e.g., run a scene that prints to console, or use `execute_editor_script` with `print()`).
**Pay attention**: Verify that the log is actually empty after the call. The two possible messages depend on whether EditorLog was found in the UI tree.

---

#### Scenario 2: Verify log is actually cleared via get_output_log

**Description**: Write output, clear it, then read back to confirm empty.
**Params**:
```json
{}
```
**Expected result**: After calling `clear_output`, a subsequent call to `get_output_log` should return reduced or empty content.
**Notes**: This is a workflow test combining two tools. Call sequence:
1. `execute_editor_script` with `print("test marker 12345")`
2. `clear_output`
3. `get_output_log` — the marker string should not appear (or the log should be significantly shorter)
**Pay attention**: This is an integration check. After clearing, the log content should be empty or noticeably reduced. The string "test marker 12345" should not be present.

---

## Tool: get_signals

**Tool name**: `get_signals`
**Description**: Get all signals and their connections for a node
**Backend method**: `editor/get_signals`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `node_path` | `z.string()` | **Yes** | — | Node path to inspect (relative to scene root, e.g. "Player/Sprite2D") |

### Handler Logic

Gets the edited scene root, then finds the node at the given path using `get_node_or_null()`. Iterates over all signals the node exposes (via `get_signal_list()`), and for each signal, gets its connections (via `get_signal_connection_list()`). Returns signal name, args, and for each connection: target object path and method name.

### Test Scenarios

#### Scenario 1: Happy path — node with connected signals

**Description**: Get signals for a node that has at least one signal connected.
**Params**:
```json
{
  "node_path": "Player"
}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true`, `node: "Player"`, `signals` is an array. Each signal object has `name` (string), `args` (array), `connections` (array of objects with `target` and `method`).
**Notes**: Prerequisite: a scene with a "Player" node that has at least one signal connected (e.g., `body_entered` connected to a handler method).
**Pay attention**: Verify the structure of each object in the `signals` array: there should be `name`, `args`, `connections`. Each connection should contain `target` (path to the receiving node) and `method` (method name).

---

#### Scenario 2: Happy path — node with no connected signals

**Description**: Get signals for a node that has signals defined but none connected.
**Params**:
```json
{
  "node_path": "BackgroundSprite"
}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true`, `node: "BackgroundSprite"`, `signals` is an array of signal objects where each has `connections: []` (empty).
**Notes**: Every Godot node has built-in signals (e.g., `tree_entered`, `ready`), but they may not be connected.
**Pay attention**: The `signals` array should not be empty (every node has built-in signals), but `connections` for each may be empty.

---

#### Scenario 3: Happy path — scene root node (empty string path)

**Description**: Get signals for the scene root using empty string as path.
**Params**:
```json
{
  "node_path": ""
}
```
**Expected result**: `content[0].text` contains `success: false` and `error: "node_path is required"`.
**Notes**: The GDScript side checks `node_path.is_empty()` and returns an error. Unlike some other tools, empty string is NOT treated as "scene root" here — it's explicitly rejected.
**Pay attention**: An empty string does NOT mean "scene root" for this tool — it is an error. Verify that `isError: true` is returned with the message "node_path is required".

---

#### Scenario 4: Error — node not found

**Description**: Request signals for a non-existent node path.
**Params**:
```json
{
  "node_path": "NonExistentNode/Child"
}
```
**Expected result**: `content[0].text` contains `success: false` and `error: "Node not found: NonExistentNode/Child"`.
**Notes**: The GDScript side uses `get_node_or_null()` which returns null for invalid paths.
**Pay attention**: Verify that the error contains the specified path. `isError: true` in the MCP response.

---

#### Scenario 5: Error — no scene open

**Description**: Request signals when no scene is open in the editor.
**Params**:
```json
{
  "node_path": "AnyNode"
}
```
**Expected result**: `content[0].text` contains `success: false` and `error: "No scene open"`.
**Notes**: Close all scenes before calling.
**Pay attention**: A separate error from "Node not found" — "No scene open". Verify that the scenario produces different errors for "no scene" and "node not found".

---

#### Scenario 6: Edge case — deeply nested node path

**Description**: Get signals for a deeply nested node.
**Params**:
```json
{
  "node_path": "Player/Weapon/ProjectileSpawn/Marker"
}
```
**Expected result**: `content[0].text` contains `success: true` with signals data for the deeply nested node, OR `success: false` with "Node not found" if the path doesn't exist.
**Notes**: Tests that the tool correctly resolves multi-level paths.
**Pay attention**: Verify that the tool correctly handles compound paths via `/`. If the node exists, signals should be retrieved.

---

## Tool: reload_plugin

**Tool name**: `reload_plugin`
**Description**: Reload editor plugins (triggers plugin re-initialization)
**Backend method**: `editor/reload_plugin`

### Parameters

None. This tool takes no parameters.

### Handler Logic

Uses `call_deferred` to toggle the "godot_mcp" plugin off and then on again. The deferred call is critical — without it, `set_plugin_enabled(false)` would tear down the WebSocket connection before the response reaches the MCP client. Returns immediately with a success message indicating the connection will be re-established.

### Test Scenarios

#### Scenario 1: Happy path — reload plugin

**Description**: Reload the MCP plugin.
**Params**:
```json
{}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true` and `message: "Plugin reloaded - connection will be re-established"`.
**Notes**: After this call, the WebSocket connection will briefly disconnect and reconnect. The MCP client should handle the temporary disconnection gracefully.
**Pay attention**: After the call, the WebSocket connection will be broken and re-established. The MCP client should correctly handle the brief disconnection. Verify that the response arrives BEFORE the disconnect (thanks to call_deferred).

---

#### Scenario 2: Verify plugin state after reload

**Description**: Reload the plugin and then verify it's still functional by calling another tool.
**Params**:
```json
{}
```
**Expected result**: After `reload_plugin` returns, a subsequent call to any other editor tool (e.g., `get_output_log`) should succeed, confirming the plugin re-initialized correctly.
**Notes**: This is an integration test. Call sequence:
1. `reload_plugin` — expect success
2. Wait a moment for reconnection
3. `get_output_log` — expect success (confirms plugin is alive again)
**Pay attention**: Integration check. After plugin reload, ensure the WebSocket reconnected and tools work again. A small delay between calls may be needed.

---

## Tool: reload_project

**Tool name**: `reload_project`
**Description**: Rescan the project filesystem for new or changed files
**Backend method**: `editor/reload_project`

### Parameters

None. This tool takes no parameters.

### Handler Logic

Calls `_plugin.safe_scan_filesystem()` which triggers Godot's filesystem scan. This picks up new files, deleted files, and modified files in the project directory.

### Test Scenarios

#### Scenario 1: Happy path — rescan after adding files

**Description**: Reload project filesystem after adding new files externally.
**Params**:
```json
{}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true` and `message: "Project filesystem rescanned"`.
**Notes**: Before calling, create a new file in the project directory (e.g., a new `.gd` file). After calling, the file should be visible via `get_filesystem_tree`.
**Pay attention**: Verify that after the call, new files become visible in the filesystem tree. The file should appear without needing to restart the editor.

---

#### Scenario 2: Verify new file is picked up

**Description**: Create a file, reload, then confirm it's visible.
**Params**:
```json
{}
```
**Expected result**: After `reload_project`, use a filesystem listing tool to confirm the new file appears.
**Notes**: Call sequence:
1. (External) Create `res://scripts/new_test_file.gd` on disk
2. `reload_project`
3. Use a filesystem tool (e.g., `search_files` or `get_filesystem_tree`) to verify `new_test_file.gd` is listed
**Pay attention**: This is an integration test. The file should appear in search/tree results after rescan.

---

## Tool: get_output_log

**Tool name**: `get_output_log`
**Description**: Get the contents of the editor output log
**Backend method**: `editor/get_output_log`

### Parameters

None. This tool takes no parameters.

### Handler Logic

First tries to read `user://logs/godot.log` from disk. If the file exists and is non-empty, returns its last 5000 characters (truncated from the start to avoid huge payloads). If the file approach fails, falls back to reading the `EditorLog`'s `RichTextLabel` child from the editor UI. If neither works, returns `"(No output log available)"`.

### Test Scenarios

#### Scenario 1: Happy path — log has content

**Description**: Get the output log when it contains messages.
**Params**:
```json
{}
```
**Expected result**: `content[0].text` contains a JSON object with `success: true` and `content` is a non-empty string with log text.
**Notes**: Before calling, generate some output (e.g., run a scene, or use `execute_editor_script` with `print("test output")`).
**Pay attention**: Verify that `content` is a non-empty string. The content should include recently output messages.

---

#### Scenario 2: Happy path — log after generating specific output

**Description**: Generate specific output, then read the log to confirm it's present.
**Params**:
```json
{}
```
**Expected result**: `content[0].text` contains `success: true` and `content` includes the string "MCP_TEST_MARKER_12345".
**Notes**: Call sequence:
1. `execute_editor_script` with `code: "print('MCP_TEST_MARKER_12345')"`
2. `get_output_log` — verify the marker appears in the content
**Pay attention**: Integration test. The string "MCP_TEST_MARKER_12345" should be present in the log. This confirms that print() from EditorScript writes to the log and get_output_log reads it.

---

#### Scenario 3: Edge case — very large log (truncation)

**Description**: Check behavior when the log file exceeds 5000 characters.
**Params**:
```json
{}
```
**Expected result**: `content[0].text` contains `success: true` and `content` is at most 5000 characters. The content should be the LAST 5000 characters of the log (tail), not the first.
**Notes**: Generate a large log by running a script that prints many lines, then call `get_output_log`.
**Pay attention**: Verify that the TAIL of the log is returned (last 5000 characters), not the beginning. If the log is smaller than 5000 characters, it is returned in full.

---

#### Scenario 4: Edge case — empty log / no log available

**Description**: Get the log when no log file exists and the editor log is empty.
**Params**:
```json
{}
```
**Expected result**: `content[0].text` contains `success: true` and `content: "(No output log available)"`.
**Notes**: This occurs in headless mode or when the log file was manually deleted. The tool always returns `success: true` even when there's nothing to show.
**Pay attention**: The tool does NOT return an error when there is no log — it returns `success: true` with placeholder text. This may be unexpected.

---

## Cross-Tool Workflow: Full Editor Validation

This section describes a complete workflow that chains multiple editor tools together to validate a development cycle.

### Workflow 1: Write → Validate → Fix Cycle

**Description**: Simulate the common developer workflow of writing a script, checking for errors, and verifying output.

**Steps**:

1. **Create a test script with a bug** using `execute_editor_script`:
   ```json
   { "code": "return 'Script created'" }
   ```

2. **Check for errors** using `get_editor_errors`:
   ```json
   {}
   ```
   Expected: errors list shows the broken script.

3. **Fix the script** using `execute_editor_script`:
   ```json
   { "code": "return 'Script fixed'" }
   ```

4. **Re-check for errors** using `get_editor_errors`:
   ```json
   {}
   ```
   Expected: `errors` is now empty, `count: 0`.

5. **Verify the output log** using `get_output_log`:
   ```json
   {}
   ```
   Expected: log contains any print output from the scripts.

---

### Workflow 2: Reload Cycle

**Description**: Reload plugin and project to ensure state consistency.

**Steps**:

1. **Add a new file to the project** (external or via `execute_editor_script`).

2. **Reload the project** using `reload_project`:
   ```json
   {}
   ```
   Expected: `success: true`.

3. **Verify the file is visible** via filesystem tools.

4. **Clear output** using `clear_output`:
   ```json
   {}
   ```
   Expected: `success: true`.

5. **Take a screenshot** using `get_editor_screenshot`:
   ```json
   {}
   ```
   Expected: screenshot captured, dimensions returned.

---

### Workflow 3: Signal Inspection

**Description**: Inspect node signals after setting up connections.

**Steps**:

1. **Create a node with signal connections** using `execute_editor_script`:
   ```json
   { "code": "# Assumes a node named 'Button' exists in the scene\nvar btn = get_editor_interface().get_edited_scene_root().get_node('Button')\nreturn btn.get_signal_list().size()" }
   ```

2. **Get signals** using `get_signals`:
   ```json
   { "node_path": "Button" }
   ```
   Expected: list of all signals on the Button node with their connections.

3. **Verify signal data structure**: each signal should have `name`, `args`, and `connections` fields.