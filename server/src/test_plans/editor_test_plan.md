# Editor Tools — Test Plan

**Source file:** `server/src/tools/editor.ts`  
**Number of tools:** 9  
**Godot bridge commands:** `editor/get_errors`, `editor/get_screenshot`, `editor/get_game_screenshot`, `editor/execute_script`, `editor/clear_output`, `editor/get_signals`, `editor/reload_plugin`, `editor/reload_project`, `editor/get_output_log`

---

## Tool 1: `get_editor_errors`

**Description:** Validate all GDScripts in the current scene tree and return compilation errors  
**Parameters:** None (empty `inputSchema`)  
**Handler:** `callGodot(bridge, 'editor/get_errors')`  
**Expected result:** Returns a JSON object (or array) containing compilation errors with file paths, line numbers, error messages, and optionally stack traces for all GDScripts in the currently open scene.

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 1 | Call with no arguments | `{}` | Valid JSON array/object of errors (may be empty if no errors exist) | Simplest invocation. Should always succeed. |
| 2 | Call after modifying a script to introduce a syntax error | `{}` | Error entries include `file`, `line`, `message` for each broken script | Validates that real errors are detected. |
| 3 | Call on a clean project with no script errors | `{}` | Empty array or success message (no errors) | Verify tool returns cleanly when there's nothing to report. |
| 4 | Call with extra ignored arg | `{"ignored": true}` | Same result as #1 (extra arg ignored) | Zod ignores unknown keys since no schema is defined. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 5 | Call when editor is disconnected | `{}` | Error: "Godot editor is not connected" or timeout | Tests bridge availability resilience. |
| 6 | Call with `null` body | `null` | Valid result (body ignored, no schema) | MCP SDK may coerce null to `{}`. Either is acceptable. |
| 7 | Call on a scene with nested inherited/instantiated scenes containing script errors | `{}` | Errors from all scripts in the full scene tree, including inherited scenes | Validates recursive validation across scene inheritance. |
| 8 | Call during gameplay (game running) | `{}` | Editor errors still returned (editor state independent of play mode) | Editor script validation should work regardless of play state. |
| 9 | Rapid repeated calls | `{}` (call 5x in quick succession) | Each call returns consistent results, no degradation | Tests for any caching or stale-state issues. |

---

## Tool 2: `get_editor_screenshot`

**Description:** Take a screenshot of the Godot editor window  
**Handler:** `callGodot(bridge, 'editor/get_screenshot', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` | No | — | Custom save path for the screenshot |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 10 | Call with no arguments | `{}` | Returns base64-encoded PNG image; screenshot saved to default location | Simplest invocation. Screenshot captured of editor window. |
| 11 | Call with custom path | `{"path": "C:/temp/editor_shot.png"}` | Returns base64-encoded PNG; file saved at specified path | Tests that custom path is respected. |
| 12 | Call with res:// path | `{"path": "res://screenshots/editor.png"}` | Success; file saved within project directory | Godot-style path. |
| 13 | Call with extra ignored arg | `{"path": "C:/temp/shot.png", "ignored": true}` | Same result as #11 (extra arg ignored) | Zod ignores unknown keys. |

### Path Parameter Variations

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 14 | Absolute Windows path | `{"path": "C:\\Users\\user\\Desktop\\editor.png"}` | Success; screenshot saved at absolute path | Backslash paths on Windows. |
| 15 | Relative path | `{"path": "editor_screenshot.png"}` | Success; saved relative to project directory or working directory | Behavior depends on Godot's path resolution. |
| 16 | Path with spaces | `{"path": "C:/My Documents/editor shot.png"}` | Success; screenshot saved with spaces in path | Path escaping. |
| 17 | Path without extension | `{"path": "C:/temp/editor_shot"}` | Success; Godot may auto-append `.png` or save as-is | Extension-omitted path. |
| 18 | Path with non-png extension (`.jpg`) | `{"path": "C:/temp/editor.jpg"}` | Success or Godot may override to `.png` | Behavior depends on Godot screenshot implementation. |
| 19 | Deeply nested non-existent directory | `{"path": "C:/temp/a/b/c/d/e/shot.png"}` | Success or error (depends on Godot's directory creation behavior) | Tests automatic directory creation. |
| 20 | Read-only directory | `{"path": "C:/Windows/System32/shot.png"}` | Error (permission denied) | Tests file system error handling. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 21 | Call when editor is disconnected | `{}` | Error: "Godot editor is not connected" or timeout | Tests bridge availability resilience. |
| 22 | Path as empty string | `{"path": ""}` | Uses default path (empty string → treated same as omitted) | Empty string path. |
| 23 | Very long path (>260 chars on Windows) | `{"path": "C:/temp/${'a'.repeat(250)}/shot.png"}` | May error on Windows (MAX_PATH limit); Linux/macOS may succeed | OS-specific path length limits. |
| 24 | Path with unicode characters | `{"path": "C:/temp/éditör_scréenshot.png"}` | Should succeed if file system supports unicode | Unicode path handling. |
| 25 | Non-string path (number) | `{"path": 12345}` | Zod validation error | `z.string()` rejects non-strings. |
| 26 | Non-string path (boolean) | `{"path": true}` | Zod validation error | `z.string()` rejects non-strings. |
| 27 | Non-string path (object) | `{"path": {"dir": "temp", "name": "shot.png"}}` | Zod validation error | `z.string()` rejects objects. |
| 28 | Call during gameplay | `{}` | Screenshot of editor window (may show game view embedded in editor) | Editor screenshot during play mode — should capture the full editor window including the running game viewport. |
| 29 | Call multiple times rapidly | `{}` (call 5x in quick succession) | Each returns a valid screenshot; files saved with distinct names (if auto-naming) | Tests for file overwrite issues or rate-limiting. |

---

## Tool 3: `get_game_screenshot`

**Description:** Take a screenshot of the running game viewport  
**Handler:** `callGodot(bridge, 'editor/get_game_screenshot', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` | No | — | Custom save path for the screenshot |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 30 | Call during gameplay (game running) | `{}` | Returns base64-encoded PNG of game viewport; saved to default location | Core use case — requires game to be running. |
| 31 | Call with custom path during gameplay | `{"path": "C:/temp/game_shot.png"}` | Returns base64 PNG; file saved at specified path | Game screenshot with custom path. |
| 32 | Call with res:// path during gameplay | `{"path": "res://screenshots/game.png"}` | Success; file saved within project | Godot-style path during gameplay. |

### Precondition: Game Must Be Running

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 33 | Call when game is NOT running | `{}` | Error: "Game is not running" or empty/black screenshot | Tool requires an active game session. Documented as "🔴 Game must be running." |
| 34 | Call immediately after game stops | `{}` | Error or empty result | Race condition after game stop. |
| 35 | Call before game starts, then start game, then call again | Sequence | First call errors, second succeeds | State transition test. |

### Path Parameter Variations

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 36 | Absolute Windows path | `{"path": "C:\\Users\\user\\Desktop\\game.png"}` | Success; screenshot saved | Backslash paths on Windows. |
| 37 | Relative path | `{"path": "game_screenshot.png"}` | Success; saved relative to project | Relative path during gameplay. |
| 38 | Path with spaces | `{"path": "C:/My Documents/game shot.png"}` | Success | Path escaping. |
| 39 | Path without extension | `{"path": "C:/temp/game_shot"}` | Godot may auto-append `.png` or save as-is | Extension-omitted path. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 40 | Call when editor is disconnected | `{}` | Error: "Godot editor is not connected" or timeout | Tests bridge availability. |
| 41 | Path as empty string | `{"path": ""}` | Uses default path | Empty string path during gameplay. |
| 42 | Read-only directory | `{"path": "C:/Windows/System32/game.png"}` | Error (permission denied) | File system error handling. |
| 43 | Non-string path (number) | `{"path": 12345}` | Zod validation error | Type check. |
| 44 | Non-string path (boolean) | `{"path": false}` | Zod validation error | Type check. |
| 45 | Non-string path (object) | `{"path": {"key": "val"}}` | Zod validation error | Type check. |
| 46 | Call multiple times rapidly during gameplay | `{}` (call 5x in quick succession) | Each returns a valid screenshot of the game viewport | Tests for performance impact or frame capture issues. |
| 47 | Very long path | `{"path": "C:/temp/${'a'.repeat(250)}/game.png"}` | May error on Windows (MAX_PATH); Linux/macOS may succeed | Path length limits. |
| 48 | Call with game paused | `{}` | Should succeed — captures the paused frame | Screenshot during game pause. |
| 49 | Screenshot dimensions match viewport size | `{}` | Image dimensions match configured game viewport | Validate screenshot resolution. |

### Cross-tool Comparison

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 50 | Compare `get_editor_screenshot` vs `get_game_screenshot` during gameplay | Call both in sequence | `get_editor_screenshot` shows full editor window with game viewport embedded; `get_game_screenshot` shows only the game viewport | Validates the two screenshot tools capture different things. |

---

## Tool 4: `execute_editor_script`

**Description:** Execute a GDScript snippet in the editor context (EditorScript)  
**Handler:** `callGodot(bridge, 'editor/execute_script', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `code` | `string` (GDScriptCode) | **Yes** | — | GDScript code to execute |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 51 | Execute a simple print statement | `{"code": "print('Hello from MCP')"}` | Success; "Hello from MCP" appears in output log | Simplest valid GDScript. |
| 52 | Execute code that queries the editor | `{"code": "var scenes = EditorInterface.get_open_scenes(); print(scenes.size())"}` | Returns number of open scenes | Editor API interaction. |
| 53 | Execute code that creates a node | `{"code": "var node = Node.new(); print(node.get_class())"}` | Returns "Node" | Object instantiation in editor context. |
| 54 | Execute multi-line code | `{"code": "for i in range(3):\n\tprint(i)"}` | Prints 0, 1, 2 | Multi-line GDScript. |
| 55 | Execute code that returns a value | `{"code": "return 42"}` | Returns 42 | Code with return statement. |
| 56 | Execute code accessing EditorInterface | `{"code": "return EditorInterface.get_editor_scale()"}` | Returns current editor UI scale (e.g., 1.0, 1.5) | Validates EditorInterface singleton is available. |

### GDScript Code Variations

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 57 | Empty code string | `{"code": ""}` | Success (no-op) or error (empty script) | Empty code — behavior depends on Godot. |
| 58 | Whitespace-only code | `{"code": "   \n\t\n  "}` | Success (no-op) or error | Whitespace-only code. |
| 59 | Very long code (>10KB) | `{"code": "print('${'a'.repeat(10000)}')"}` | Success or error (size limits) | Tests payload size handling. |
| 60 | Code with unicode characters | `{"code": "print('日本語テスト éàç')"}` | Success; unicode printed correctly | Unicode support in GDScript execution. |
| 61 | Code with special characters (quotes, backslashes) | `{"code": "print('She said \\\"hello\\\"')"}` | Success; properly escaped output | String escaping. |
| 62 | Code with `$` and `%` characters (GDScript node path syntax) | `{"code": "print($NodePath)"}` | Error (expected — no scene context in EditorScript) | GDScript syntax that needs scene context may fail. |
| 63 | Code with @tool annotation | `{"code": "print('already runs in editor')"}` | Success; @tool not needed for EditorScript | EditorScript always runs in editor. |
| 64 | Code with class_name declaration | `{"code": "class_name MyTemp\nprint(MyTemp)"}` | May succeed or error (class_name may conflict) | Class declaration in ad-hoc execution. |
| 65 | Code with `await` keyword | `{"code": "await get_tree().create_timer(1.0).timeout\nprint('done')"}` | May error (EditorScript may not support await) | Async code in editor context. |
| 66 | Code that accesses filesystem | `{"code": "var f = FileAccess.open('res://project.godot', FileAccess.READ)\nreturn f.get_as_text().length()"}` | Returns file size | File system access from editor context. |
| 67 | Script with syntax error | `{"code": "print(missing_var"}` | Error with parse error details (line, column) | GDScript syntax validation. |
| 68 | Script with runtime error | `{"code": "var n = null\nn.call('nonexistent')"}` | Error: "Invalid call" or null instance error | Runtime error handling. |
| 69 | Script with infinite loop | `{"code": "while true:\n\tpass"}` | Timeout or forced termination | Infinity guard (if any). |

### Parameter Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 70 | Missing required `code` | `{}` | Zod validation error | `code` is required. |
| 71 | `code` as number | `{"code": 123}` | Zod validation error | `z.string()` rejects non-strings. |
| 72 | `code` as boolean | `{"code": true}` | Zod validation error | Type check. |
| 73 | `code` as null | `{"code": null}` | Zod validation error or coerced to string | Null handling. |
| 74 | `code` as object | `{"code": {"script": "print(1)"}}` | Zod validation error | Type check. |
| 75 | `code` as array | `{"code": ["print(1)", "print(2)"]}` | Zod validation error | Type check. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 76 | Call when editor is disconnected | `{"code": "print('test')"}` | Error: "Godot editor is not connected" or timeout | Bridge availability. |
| 77 | Call during gameplay | `{"code": "print('test')"}` | Should succeed — EditorScript runs in editor context regardless of play mode | Editor execution independent of play mode. |
| 78 | Call with extra params | `{"code": "print('test')", "extra": "ignored"}` | Success (extra arg ignored) | Unknown keys are dropped by Zod. |
| 79 | Execute code that adds a node to the current scene | `{"code": "var s = EditorInterface.get_edited_scene_root()\nvar n = Node.new()\nn.name = 'MCP_Test'\ns.add_child(n)\nn.owner = s\nprint('added')"}` | Success; node appears in scene tree | Scene modification via EditorScript. |
| 80 | Execute code that modifies project settings | `{"code": "ProjectSettings.set_setting('application/config/name', 'Renamed')\nProjectSettings.save()"}` | Success; project name changed | Project settings mutation via EditorScript. Must be careful — could have side effects. |
| 81 | Execute code that calls EditorInterface.get_selection() | `{"code": "var sel = EditorInterface.get_selection()\nreturn sel.get_selected_nodes().size()"}` | Returns count of selected nodes | Editor selection query. |
| 82 | Multiple sequential executions | Call 10x with different code strings | Each executes independently, no interference | Stress test for repeated execution. |

---

## Tool 5: `clear_output`

**Description:** Clear the editor output log  
**Parameters:** None (empty `inputSchema`)  
**Handler:** `callGodot(bridge, 'editor/clear_output')`  
**Expected result:** Success confirmation. The editor output log panel is cleared of all previous entries.

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 83 | Call with no arguments | `{}` | Success; output log cleared | Simplest invocation. |
| 84 | Call after printing something to output log | `{}` (after executing `print` via `execute_editor_script`) | Success; previously printed content is gone | Validate actual clearing behavior. |
| 85 | Call on an already-empty output log | `{}` | Success (idempotent no-op) | Clearing an empty log should not error. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 86 | Call when editor is disconnected | `{}` | Error: "Godot editor is not connected" or timeout | Bridge availability. |
| 87 | Call with extra ignored arg | `{"clear": true}` | Success (extra arg ignored) | Unknown keys dropped by Zod. |
| 88 | Call with `null` body | `null` | Success (body ignored) | Null body handling. |
| 89 | Rapid repeated calls | `{}` (call 5x in quick succession) | Each succeeds; no errors from clearing an already-cleared log | Idempotency stress test. |
| 90 | Call during gameplay | `{}` | Success; output log cleared | Editor tool should work during gameplay. |
| 91 | Call, then verify with `get_output_log` | Sequence: `clear_output` → `get_output_log` | `get_output_log` returns empty or minimal content | Integration test between clear_output and get_output_log. |

---

## Tool 6: `get_signals`

**Description:** Get all signals and their connections for a node  
**Handler:** `callGodot(bridge, 'editor/get_signals', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `string` (NodePath) | **Yes** | — | Node path to inspect |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 92 | Get signals of a node with connected signals | `{"node_path": "Button"}` | JSON object/array listing all signals (e.g., `pressed`, `toggled`) with their connections (target node, method) | Core use case — inspect signal wiring. |
| 93 | Get signals of a node with NO connected signals | `{"node_path": "Sprite2D"}` | Lists available signals (e.g., `visibility_changed`, `item_rect_changed`) but shows empty connections | Node has signal definitions but no connections. |
| 94 | Get signals of the scene root | `{"node_path": ""}` | Lists all signals and connections for the scene root node | Empty string = scene root. |
| 95 | Get signals of a deeply nested node | `{"node_path": "Player/Weapon/Hitbox"}` | Signals for the nested node with any connections | Deep path resolution. |

### Node Path Variations

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 96 | Root-level child by name | `{"node_path": "Player"}` | Signals for Player node | Simple node name without slashes. |
| 97 | Nested path with single slash | `{"node_path": "Player/Camera2D"}` | Signals for Camera2D child of Player | Standard path format. |
| 98 | Deeply nested path | `{"node_path": "World/Level1/Enemies/EnemyA/Sprite"}` | Signals for the deeply nested node | Multi-level path. |
| 99 | Node name with special characters | `{"node_path": "@Sprite@2"}` | Success if node exists with that name | Godot allows `@` in node names. |
| 100 | Node name with spaces | `{"node_path": "My Button"}` | Success if node name contains spaces | Spaces in node names. |
| 101 | Node name with unicode | `{"node_path": "プレイヤー"}` | Success if node exists with japanese name | Unicode node names. |
| 102 | Non-existent node | `{"node_path": "NonExistentNode"}` | Error: "Node not found" or empty result | Missing node in scene. |
| 103 | Path to a node that doesn't exist in the middle | `{"node_path": "Player/NonExistent/Sprite"}` | Error: "Node not found" at NonExistent | Broken path. |
| 104 | Trailing slash | `{"node_path": "Player/"}` | Error (invalid path) or treated as "Player" | Trailing slash edge case. |
| 105 | Leading slash | `{"node_path": "/Player"}` | May error (Godot paths are relative) | Leading slash — paths are relative to current scene. |
| 106 | Path with `..` (parent reference) | `{"node_path": "Player/../Enemy"}` | May error or resolve to root-level Enemy | Relative path navigation. |
| 107 | Very long path | `{"node_path": "A/B/C/D/E/F/G/H/I/J/K/L/M/N/O/P/Q/R/S/T/U/V/W/X/Y/Z"}` | Error if path exceeds scene depth; success if all nodes exist | Deep path stress test. |

### Parameter Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 108 | Missing required `node_path` | `{}` | Zod validation error | `node_path` is required. |
| 109 | `node_path` as empty object | `{"node_path": {}}` | Zod validation error | `z.string()` rejects objects. |
| 110 | `node_path` as number | `{"node_path": 123}` | Zod validation error | Type check. |
| 111 | `node_path` as boolean | `{"node_path": false}` | Zod validation error | Type check. |
| 112 | `node_path` as null | `{"node_path": null}` | Zod validation error | Null handling. |
| 113 | Call with extra params | `{"node_path": "Player", "detail": true}` | Success (extra arg ignored) | Unknown keys dropped by Zod. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 114 | Call when editor is disconnected | `{"node_path": "Player"}` | Error: "Godot editor is not connected" or timeout | Bridge availability. |
| 115 | Call on a node with built-in signals (e.g., Timer) | `{"node_path": "Timer"}` | Lists `timeout` signal with connections (if any) | Built-in signal inspection. |
| 116 | Call on a node with custom signals (from attached script) | `{"node_path": "Player"}` (Player has attached script with `signal health_changed`) | Lists both built-in signals AND custom signals | Custom signal visibility. |
| 117 | Call during gameplay | `{"node_path": "Player"}` | Should return signals (editor tool, not runtime) | Editor inspection during gameplay. |
| 118 | Call on a node inside a sub-scene instance | `{"node_path": "EnemyContainer/Enemy"}` | Returns signals for the instanced node | Inherited scene node path. |
| 119 | Call multiple times on same node | `{"node_path": "Player"}` (call 5x) | Consistent results each time | No state mutation from read tool. |

---

## Tool 7: `reload_plugin`

**Description:** Reload editor plugins (triggers plugin re-initialization)  
**Parameters:** None (empty `inputSchema`)  
**Handler:** `callGodot(bridge, 'editor/reload_plugin')`  
**Expected result:** Success confirmation. All editor plugins are reloaded, triggering their re-initialization. The MCP plugin itself may briefly disconnect during reload.

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 120 | Call with no arguments | `{}` | Success; plugins reloaded | Simplest invocation. |
| 121 | Call, then verify MCP plugin is still connected | `{}` → wait → any tool call | Subsequence tools still work | Critical: MCP plugin must survive its own reload. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 122 | Call when editor is disconnected | `{}` | Error: "Godot editor is not connected" or timeout | Bridge availability. |
| 123 | Call with extra ignored arg | `{"plugin_name": "godot_mcp"}` | Success (extra arg ignored) | Unknown keys dropped by Zod. |
| 124 | Call with `null` body | `null` | Success or timeout (body ignored) | Null body handling. |
| 125 | Rapid repeated calls | `{}` (call 3x in quick succession) | First call triggers reload; subsequent calls may queue, error, or be idempotent | Stress test for rapid plugin reloads. |
| 126 | Call during gameplay | `{}` | May error, succeed, or cause game to stop (depends on Godot behavior) | Plugin reload during active gameplay is unusual. |
| 127 | Call when other tools are also being invoked | `{}` while parallel tool calls are in flight | Race condition — other tools may return errors during reload window | Concurrent access during reload. |
| 128 | Call, then immediately call another tool | `{}` → immediate tool call | Second tool may timeout or queue until reload completes | Tests post-reload recovery time. |

---

## Tool 8: `reload_project`

**Description:** Rescan the project filesystem for new or changed files  
**Parameters:** None (empty `inputSchema`)  
**Handler:** `callGodot(bridge, 'editor/reload_project')`  
**Expected result:** Success confirmation. The project filesystem is rescanned, picking up any new, modified, or deleted files that were added outside the editor.

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 129 | Call with no arguments | `{}` | Success; project filesystem rescanned | Simplest invocation. |
| 130 | Create a file externally, then call reload | `{}` after externally creating a script file | New file appears in filesystem tree after reload | Validates actual rescan behavior. |
| 131 | Delete a file externally, then call reload | `{}` after externally deleting a file | Deleted file removed from filesystem tree after reload | Validates deletion detection. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 132 | Call when editor is disconnected | `{}` | Error: "Godot editor is not connected" or timeout | Bridge availability. |
| 133 | Call with extra ignored arg | `{"force": true}` | Success (extra arg ignored) | Unknown keys dropped by Zod. |
| 134 | Call with `null` body | `null` | Success (body ignored) | Null body handling. |
| 135 | Rapid repeated calls | `{}` (call 5x in quick succession) | Each call succeeds; no errors from redundant rescans | Idempotency stress test. |
| 136 | Call during gameplay | `{}` | Should succeed (editor operation) | Project reload during gameplay — should not interrupt game. |
| 137 | Call on a very large project (>1000 files) | `{}` | Success; may take longer to complete | Large project performance. |
| 138 | Call while scripts are compiling | `{}` | May queue until compilation finishes or error | Concurrent compilation edge case. |
| 139 | Call, then verify filesystem with `get_filesystem_tree` | Sequence: `reload_project` → `get_filesystem_tree` | Filesystem tree reflects latest state | Integration test with filesystem tools. |

---

## Tool 9: `get_output_log`

**Description:** Get the contents of the editor output log  
**Parameters:** None (empty `inputSchema`)  
**Handler:** `callGodot(bridge, 'editor/get_output_log')`  
**Expected result:** Returns a string or JSON object containing the current contents of the editor output log panel.

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 140 | Call with no arguments | `{}` | Returns current output log content (string or structured) | Simplest invocation. |
| 141 | Call after printing something to output | `{}` (after `execute_editor_script` with `print` statement) | Output includes the printed text | Validates log content reflects recent prints. |
| 142 | Call on an empty/cleared log | `{}` (after `clear_output`) | Returns empty string or minimal content | Empty log state. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 143 | Call when editor is disconnected | `{}` | Error: "Godot editor is not connected" or timeout | Bridge availability. |
| 144 | Call with extra ignored arg | `{"limit": 50}` | Same result as #140 (extra arg ignored) | Unknown keys dropped by Zod. |
| 145 | Call with `null` body | `null` | Valid result (body ignored) | Null body handling. |
| 146 | Call on a log with many entries (>1000 lines) | `{}` | All entries returned (may be large payload) | Large log handling — check for truncation. |
| 147 | Call during gameplay | `{}` | Returns log including runtime messages | Output log during play mode should include game output. |
| 148 | Rapid repeated calls | `{}` (call 5x in quick succession) | Consistent results; no performance degradation | Read-only stress test. |

### Integration: clear_output + get_output_log Cycle

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 149 | Log → Clear → Verify empty → Print → Verify contains | Sequence of `get_output_log` → `clear_output` → `get_output_log` → `execute_editor_script` → `get_output_log` | Validates full log lifecycle: initial content, cleared state, new content after print | End-to-end integration test across 3 editor tools. |

---

## Cross-Tool Scenarios

These scenarios test interactions between multiple editor tools.

| # | Scenario | Steps | Expected result | Notes |
|---|----------|-------|-----------------|-------|
| 150 | Screenshot after script execution | 1. `execute_editor_script` to print text 2. `get_editor_screenshot` | Screenshot shows the output log with printed text | Visual verification of script output. |
| 151 | Full editor diagnostic workflow | 1. `get_editor_errors` 2. `get_output_log` 3. `clear_output` 4. `reload_project` | Each step succeeds; diagnostic workflow complete | Realistic debugging workflow. |
| 152 | Signal inspection pipeline | 1. `get_signals` on scene root 2. `get_signals` on child nodes 3. `get_editor_errors` to check script health | Complete scene signal analysis | Inspecting signal architecture. |
| 153 | Editor state snapshot | 1. `get_editor_screenshot` 2. `get_output_log` 3. `get_editor_errors` 4. `get_signals` on key nodes | Comprehensive editor state captured | Snapshot for debugging support requests. |
| 154 | All no-param tools sequence | 1. `get_editor_errors` 2. `clear_output` 3. `reload_plugin` 4. `reload_project` 5. `get_output_log` | All succeed; no unexpected interactions | All tools with empty inputSchema tested in sequence. |

---

## Summary

| # | Tool | Params | Bridge Command | Mutates? | Requires Game? |
|---|------|--------|----------------|----------|----------------|
| 1 | `get_editor_errors` | None | `editor/get_errors` | No | No |
| 2 | `get_editor_screenshot` | `path?` (string) | `editor/get_screenshot` | Yes (writes file) | No |
| 3 | `get_game_screenshot` | `path?` (string) | `editor/get_game_screenshot` | Yes (writes file) | **Yes** |
| 4 | `execute_editor_script` | `code` (string, required) | `editor/execute_script` | Yes (side effects) | No |
| 5 | `clear_output` | None | `editor/clear_output` | Yes (clears log) | No |
| 6 | `get_signals` | `node_path` (string, required) | `editor/get_signals` | No | No |
| 7 | `reload_plugin` | None | `editor/reload_plugin` | Yes (reloads plugins) | No |
| 8 | `reload_project` | None | `editor/reload_project` | Yes (rescans FS) | No |
| 9 | `get_output_log` | None | `editor/get_output_log` | No | No |

**Total scenarios:** 154
