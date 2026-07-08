# Runtime Tools — Test Plan

> **Target file**: `server/src/tools/runtime.ts`
> **Total tools**: 19
> **Prerequisite**: 🔴 Godot game must be running (all tools). The MCP server must be connected to the Godot editor plugin.

---

## Test Infrastructure Notes

- All tools call `callGodot(bridge, 'runtime/<method>', args)` which sends a JSON-RPC 2.0 request to Godot via WebSocket.
- Two failure modes exist:
  - **Bridge-level**: `'Godot editor is not connected'` or `'Request ... timed out after Nms'` — returned as `{isError: true}`.
  - **Godot-level**: JSON-RPC error response — returned as `{isError: true}` with Godot's error message.
- All successful results return `{content: [{type: 'text', text: <JSON-string or string>}]}`.
- Tools marked with `🔴` require the game to be running. If the game is not running, Godot will return an error.

---

## Tool: `get_game_scene_tree`

**Description**: Get the scene tree of the running game (runtime state).

**Parameters**: None (`inputSchema: {}`).

**Godot method**: `runtime/get_scene_tree`

---

### Test Scenarios

#### Scenario 1.1 — Happy path: basic call
- **Description**: Call with no parameters while the game is running.
- **Params**: `{}`
- **Expected result**: Returns a JSON object representing the full runtime scene tree. Should include nodes with their types, names, and hierarchy.
- **Notes**: Verify the returned tree contains at least the root node. Check that the node structure is navigable (parent-child relationships). The exact shape depends on the running game.

#### Scenario 1.2 — Edge case: game NOT running
- **Description**: Call while no game is running (editor idle).
- **Params**: `{}`
- **Expected result**: `{isError: true}` with message indicating the game is not running (Godot-side error).
- **Notes**: This is the most common failure mode for all runtime tools. Verify the error message is descriptive.

---

## Tool: `get_game_node_properties`

**Description**: Get all properties of a node in the running game.

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` (NodePath) | ✅ | Node path in the game tree |
| `properties` | `string[]` | ❌ | Specific property names to return (defaults to common properties) |

**Godot method**: `runtime/get_node_properties`

---

### Test Scenarios

#### Scenario 2.1 — Happy path: get all properties of a known node
- **Description**: Get properties of a node that exists in the scene tree (first obtain node paths via `get_game_scene_tree`).
- **Prerequisites**: Call `get_game_scene_tree` first, pick a node from the result.
- **Params**: `{"path": "Player"}`
- **Expected result**: Object with node properties (type, name, position, scale, visible, etc.).
- **Notes**: Verify key Godot node properties are present: `name`, `type`, `position`, `visible`.

#### Scenario 2.2 — Happy path: get specific properties only
- **Description**: Request only a subset of properties.
- **Params**: `{"path": "Player", "properties": ["position", "visible", "name"]}`
- **Expected result**: Object containing only the requested properties. Extra properties should NOT be present.
- **Notes**: Check that `type` is NOT returned if not explicitly requested.

#### Scenario 2.3 — Edge case: number of requested properties
- **Description**: Request a single property; request a large list; request properties that match one of what Godot might return.
- **Params**:
  - `{"path": "Player", "properties": ["position"]}`
  - `{"path": "Player", "properties": ["type", "name", "position", "rotation", "scale", "visible", "process_mode", "process_priority", "owner", "multiplayer_authority"]}`
- **Expected result**: First call returns only `position`. Second returns all existing properties.
- **Notes**: For nonexistent property names, Godot may return them as `null` or omit them. Document the behavior.

#### Scenario 2.4 — Error: nonexistent node path
- **Description**: Request properties for a node that does not exist.
- **Params**: `{"path": "/DoesNotExistAtAll/NoSuchNode"}`
- **Expected result**: `{isError: true}` with message indicating the node was not found.
- **Notes**: Godot should reject with a specific "node not found" error, not a generic error.

#### Scenario 2.5 — Error: empty path & missing required param
- **Description**: Call without the required `path` parameter.
- **Params**: `{}`
- **Expected result**: Validation error from Zod/MCP — the call should be rejected before reaching Godot.
- **Notes**: MCP framework should return a schema validation error since `path` is required.

#### Scenario 2.6 — Edge case: empty string path
- **Description**: Pass an empty string as the path.
- **Params**: `{"path": ""}`
- **Expected result**: Behavior depends on Godot — may return scene root properties or error.
- **Notes**: Document whether Godot accepts empty string for the scene root.

---

## Tool: `set_game_node_property`

**Description**: Set a property on a node in the running game.

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` (NodePath) | ✅ | Node path in the game tree |
| `property` | `string` | ✅ | Property name to set |
| `value` | `unknown` | ✅ | New value for the property |

**Godot method**: `runtime/set_node_property`

---

### Test Scenarios

#### Scenario 3.1 — Happy path: set a scalar property
- **Description**: Set a node's `visible` property to `false`.
- **Prerequisites**: Identify a node via `get_game_scene_tree`.
- **Params**: `{"path": "Player", "property": "visible", "value": false}`
- **Expected result**: Success response (e.g., `{"success": true}` or similar).
- **Notes**: Verify the change by calling `get_game_node_properties` and checking `visible` is now `false`. Restore original value after test.

#### Scenario 3.2 — Happy path: set a vector property
- **Description**: Set a node's `position` to a new value.
- **Params**: `{"path": "Player", "property": "position", "value": [100, 200, 0]}`
- **Expected result**: Success.
- **Notes**: Verify via `get_game_node_properties` that position changed. For 2D nodes, Z component may be ignored. Restore after test.

#### Scenario 3.3 — Happy path: set a string property
- **Description**: Set a node's `name` property.
- **Params**: `{"path": "Player", "property": "name", "value": "PlayerRenamed"}`
- **Expected result**: Success. The node is now named `PlayerRenamed`.
- **Notes**: After this test, restore the name to its original value. Verify the scene tree reflects the name change via `get_game_scene_tree`.

#### Scenario 3.4 — Error: nonexistent property
- **Description**: Try to set a property that does not exist on the node.
- **Params**: `{"path": "Player", "property": "does_not_exist_xyz", "value": 42}`
- **Expected result**: `{isError: true}` with message about invalid property.
- **Notes**: Godot should return a specific error for unknown properties.

#### Scenario 3.5 — Error: read-only property
- **Description**: Try to set a read-only property (if any known in the game).
- **Params**: `{"path": "Player", "property": "type", "value": "Node2D"}`
- **Expected result**: `{isError: true}` — the property is read-only.
- **Notes**: `type` is typically read-only in Godot.

#### Scenario 3.6 — Error: invalid value type
- **Description**: Pass an incompatible value (e.g., string for a Vector2 property).
- **Params**: `{"path": "Player", "property": "position", "value": "not_a_vector"}`
- **Expected result**: `{isError: true}` with type-mismatch message.
- **Notes**: Godot's type system should reject this.

#### Scenario 3.7 — Error: missing required params
- **Description**: Call with each required field missing in turn.
- **Params**:
  - `{}` (missing path, property, value)
  - `{"path": "Player"}` (missing property, value)
  - `{"path": "Player", "property": "visible"}` (missing value)
- **Expected result**: Each call rejected at Zod/MCP level with validation error.
- **Notes**: MCP schema validation should catch all three cases.

---

## Tool: `execute_game_script`

**Description**: Execute a GDScript snippet in the running game context.

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `code` | `string` (GDScriptCode) | ✅ | GDScript code to execute |

**Godot method**: `runtime/execute_script`

---

### Test Scenarios

#### Scenario 4.1 — Happy path: simple expression
- **Description**: Execute a simple expression that returns a value.
- **Params**: `{"code": "2 + 2"}`
- **Expected result**: Returns `4`.
- **Notes**: Verify the result is exactly `4` (not a string `"4"`).

#### Scenario 4.2 — Happy path: access a node
- **Description**: Access a node from the scene tree.
- **Params**: `{"code": "get_node(\"/root/Player\").name if has_node(\"/root/Player\") else \"no player\""}`
- **Expected result**: Returns the player node name or `"no player"` if absent. Adapt path to actual game.
- **Notes**: Verify the script can interact with the scene tree.

#### Scenario 4.3 — Happy path: longer script with multiple statements
- **Description**: Execute a multi-line script that does computation and returns result.
- **Params**:
  ```json
  {"code": "var a = 10\nvar b = 20\nvar total = a + b\nreturn total"}
  ```
- **Expected result**: Returns `30`.
- **Notes**: Verify multi-line scripts execute correctly.

#### Scenario 4.4 — Happy path: script with print statement
- **Description**: Execute a script that prints to the Godot console.
- **Params**: `{"code": "print(\"Hello from MCP test!\")\nreturn \"done\""}`
- **Expected result**: Returns `"done"`. The print output should appear in Godot's Output panel.
- **Notes**: Side effect: Godot console output.

#### Scenario 4.5 — Error: syntax error
- **Description**: Execute GDScript with a syntax error.
- **Params**: `{"code": "2 +"}`
- **Expected result**: `{isError: true}` with a GDScript parse/syntax error message.
- **Notes**: Godot should return a meaningful error pointing to the syntax problem.

#### Scenario 4.6 — Error: runtime error
- **Description**: Execute GDScript that causes a runtime error.
- **Params**: `{"code": "var n = null\nn.name\nreturn \"never\""}`
- **Expected result**: `{isError: true}` with null-access error message.
- **Notes**: Verify the error is descriptive (e.g., "Invalid access to property 'name' on a null object").

#### Scenario 4.7 — Error: infinite loop protection (boundary)
- **Description**: Execute a script with a very long loop (if Godot has safeguards).
- **Params**: `{"code": "while true:\n\tpass"}`
- **Expected result**: Either the game hangs (bad), a timeout is returned, or Godot terminates the script.
- **Notes**: This is a safety test. If no protection exists, note that as a risk.

#### Scenario 4.8 — Error: missing required param
- **Description**: Call without `code`.
- **Params**: `{}`
- **Expected result**: MCP schema validation error.
- **Notes**: `code` is required.

---

## Tool: `capture_frames`

**Description**: Capture frames from the running game viewport as PNG files.

**Parameters**:
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `count` | `int` (1–60) | ❌ | 1 | Number of frames to capture |
| `interval` | `number` | ❌ | — | Interval between captures in seconds |

**Godot method**: `runtime/capture_frames`

---

### Test Scenarios

#### Scenario 5.1 — Happy path: single frame (defaults)
- **Description**: Capture one frame with all defaults.
- **Params**: `{}`
- **Expected result**: Success response with the file path(s) of captured frame(s).
- **Notes**: Verify the PNG file exists on disk and is a valid image.

#### Scenario 5.2 — Happy path: multiple frames
- **Description**: Capture 3 frames.
- **Params**: `{"count": 3}`
- **Expected result**: Success with paths to 3 PNG files.
- **Notes**: Verify all 3 files exist and are distinct images (not identical copies).

#### Scenario 5.3 — Happy path: multiple frames with interval
- **Description**: Capture frames with an explicit interval.
- **Params**: `{"count": 5, "interval": 0.1}`
- **Expected result**: Success with 5 captures. Total time approximately 0.4 seconds.
- **Notes**: If the game is dynamic, frames should differ.

#### Scenario 5.4 — Happy path: max frames
- **Description**: Capture the maximum allowed frames.
- **Params**: `{"count": 60}`
- **Expected result**: Success with 60 captures.
- **Notes**: This may take significant time. Verify no memory issues.

#### Scenario 5.5 — Boundary: count = 1 (minimum)
- **Description**: Explicitly request 1 frame.
- **Params**: `{"count": 1}`
- **Expected result**: Success with 1 frame.
- **Notes**: Should behave identically to default.

#### Scenario 5.6 — Error: count = 0
- **Description**: Request 0 frames.
- **Params**: `{"count": 0}`
- **Expected result**: Zod validation error — count must be ≥ 1.
- **Notes**: `count.min(1)` should reject this.

#### Scenario 5.7 — Error: count > 60
- **Description**: Request 61 frames.
- **Params**: `{"count": 61}`
- **Expected result**: Zod validation error — count must be ≤ 60.
- **Notes**: `count.max(60)` should reject this.

#### Scenario 5.8 — Error: negative or non-integer count
- **Description**: Pass non-integer or negative values.
- **Params**:
  - `{"count": -5}`
  - `{"count": 3.5}`
- **Expected result**: Zod validation errors.
- **Notes**: `.int().min(1)` rejects both.

#### Scenario 5.9 — Edge case: negative interval
- **Description**: Pass a negative interval.
- **Params**: `{"count": 3, "interval": -1.0}`
- **Expected result**: Depends on Zod — `interval` has no `.positive()` constraint. May be accepted by schema but rejected by Godot or cause unexpected behavior.
- **Notes**: Document actual behavior. Consider adding `.positive()` to the schema if needed.

---

## Tool: `monitor_properties`

**Description**: Monitor specific properties on a game node for changes over time.

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` (NodePath) | ✅ | Node path to monitor |
| `properties` | `string[]` | ✅ | Property names to monitor |
| `duration` | `number` (optional) | ❌ | Monitoring duration in seconds |

**Godot method**: `runtime/monitor_properties`

---

### Test Scenarios

#### Scenario 6.1 — Happy path: monitor a single property
- **Description**: Monitor one property of a known node.
- **Prerequisites**: Identify a node via `get_game_scene_tree`.
- **Params**: `{"path": "Player", "properties": ["position"]}`
- **Expected result**: Returns timeline data — likely an array of {timestamp, value} pairs or similar. Should include at least one data point.
- **Notes**: Verify the data structure. Without `duration`, Godot likely samples once or uses a default duration.

#### Scenario 6.2 — Happy path: monitor with duration
- **Description**: Monitor property with explicit duration.
- **Params**: `{"path": "Player", "properties": ["position"], "duration": 2.0}`
- **Expected result**: Timeline with multiple samples collected over ~2 seconds.
- **Notes**: Verify timestamps are monotonically increasing and span approximately 2 seconds.

#### Scenario 6.3 — Happy path: monitor multiple properties
- **Description**: Monitor several properties simultaneously.
- **Params**: `{"path": "Player", "properties": ["position", "rotation", "scale"]}`
- **Expected result**: Timeline data with values for all requested properties.
- **Notes**: Each property should have its own data series.

#### Scenario 6.4 — Error: nonexistent node
- **Description**: Monitor a node that does not exist.
- **Params**: `{"path": "/FakeNode", "properties": ["position"]}`
- **Expected result**: `{isError: true}` with "node not found" message.
- **Notes**: Standard missing-node error.

#### Scenario 6.5 — Error: nonexistent property
- **Description**: Monitor a property that does not exist on the node.
- **Params**: `{"path": "Player", "properties": ["non_existent_prop"]}`
- **Expected result**: May return null/empty values for the unknown property, or error. Document behavior.
- **Notes**: Godot may silently ignore unknown properties or error out.

#### Scenario 6.6 — Error: missing required params
- **Description**: Call without `path` or `properties`.
- **Params**:
  - `{}`
  - `{"path": "Player"}`
  - `{"properties": ["position"]}`
- **Expected result**: MCP schema validation errors.
- **Notes**: Both `path` and `properties` are required.

#### Scenario 6.7 — Edge case: zero or very short duration
- **Description**: Pass `duration: 0` or a very small value.
- **Params**: `{"path": "Player", "properties": ["position"], "duration": 0}`
- **Expected result**: Depends on Godot — may return a single sample, error, or empty result.
- **Notes**: Document actual behavior. `duration` is optional so zero is valid per schema.

---

## Tool: `start_recording`

**Description**: Start recording game state changes.

**Parameters**: None (`inputSchema: {}`).

**Godot method**: `runtime/start_recording`

**Dependencies**: Must be followed by `stop_recording` to get data. Pairs with `replay_recording`.

---

### Test Scenarios

#### Scenario 7.1 — Happy path: start recording
- **Description**: Call with no parameters while game is running.
- **Params**: `{}`
- **Expected result**: Success response indicating recording has started (e.g., `{"recording": true}` or similar).
- **Notes**: Verify no error. Then call `stop_recording` (Scenario 8.1) to verify recording captured data.

#### Scenario 7.2 — Edge case: start recording twice
- **Description**: Call `start_recording` when already recording.
- **Params**: `{}`
- **Expected result**: Depends on Godot — may return success (restarting/replacing), warning, or error.
- **Notes**: Document whether double-start is handled gracefully or errors out.

#### Scenario 7.3 — Error: game not running
- **Description**: Call while no game is running.
- **Params**: `{}`
- **Expected result**: `{isError: true}` — game not running.
- **Notes**: Standard game-not-running error.

---

## Tool: `stop_recording`

**Description**: Stop recording and return the recorded game state data.

**Parameters**: None (`inputSchema: {}`).

**Godot method**: `runtime/stop_recording`

**Dependencies**: Must be preceded by `start_recording`.

---

### Test Scenarios

#### Scenario 8.1 — Happy path: stop after recording
- **Description**: Call `start_recording`, wait a few seconds (let the game run), then call `stop_recording`.
- **Sequence**:
  1. `start_recording` → `{}`
  2. Wait ~2 seconds (game runs)
  3. `stop_recording` → `{}`
- **Expected result**: Returns structured recording data — likely a sequence of frames/states with timestamps.
- **Notes**: Verify data contains multiple snapshots over time. The recording should contain meaningful state changes.

#### Scenario 8.2 — Happy path: stop without start
- **Description**: Call `stop_recording` without a prior `start_recording`.
- **Params**: `{}`
- **Expected result**: Depends on Godot — may return empty recording, error, or success with zero-length data.
- **Notes**: Document whether calling stop without start returns an error or empty result.

---

## Tool: `replay_recording`

**Description**: Replay a previously recorded game session.

**Parameters**:
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `speed` | `number` (>0, optional) | ❌ | 1.0 | Playback speed multiplier |

**Godot method**: `runtime/replay_recording`

**Dependencies**: Must be preceded by `start_recording` → `stop_recording`.

---

### Test Scenarios

#### Scenario 9.1 — Happy path: replay at default speed
- **Description**: Record, then replay at normal speed.
- **Sequence**:
  1. `start_recording` → `{}`
  2. Wait ~3 seconds
  3. `stop_recording` → `{}`
  4. `replay_recording` → `{}`
- **Expected result**: Success. The game state should replay the recorded sequence.
- **Notes**: Visually observe that the game replays. Verify no errors.

#### Scenario 9.2 — Happy path: replay at 2x speed
- **Description**: Replay at double speed.
- **Params**: `{"speed": 2.0}`
- **Expected result**: Success. Playback occurs at double speed.
- **Notes**: Visually verify the replay is faster.

#### Scenario 9.3 — Happy path: replay at 0.5x speed (slow motion)
- **Description**: Replay at half speed.
- **Params**: `{"speed": 0.5}`
- **Expected result**: Success. Playback at half speed.
- **Notes**: PositiveNumber ensures speed > 0. Verify slow motion works.

#### Scenario 9.4 — Error: speed = 0
- **Description**: Try to replay at speed 0.
- **Params**: `{"speed": 0}`
- **Expected result**: Zod validation error — must be positive.
- **Notes**: `PositiveNumber` = `z.number().positive()` rejects 0.

#### Scenario 9.5 — Error: negative speed
- **Description**: Try negative speed.
- **Params**: `{"speed": -1.0}`
- **Expected result**: Zod validation error — must be positive.
- **Notes**: Negative values rejected by `.positive()`.

#### Scenario 9.6 — Error: replay without prior recording
- **Description**: Call `replay_recording` without having recorded anything.
- **Params**: `{}`
- **Expected result**: `{isError: true}` — no recording data available.
- **Notes**: Godot should report that no recording exists.

---

## Tool: `find_nodes_by_script`

**Description**: Find all nodes in the game that use a specific script.

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `script_path` | `string` (ScriptPath) | ✅ | Script file path (e.g. `'res://scripts/enemy.gd'`) |

**Godot method**: `runtime/find_by_script`

---

### Test Scenarios

#### Scenario 10.1 — Happy path: find nodes using a known script
- **Description**: Search for nodes using a script that exists in the running game.
- **Params**: `{"script_path": "res://scripts/player.gd"}`
- **Expected result**: Returns an array of node paths that use the script. May be empty if no nodes use it.
- **Notes**: Use a script path known to be in the project. Verify the returned paths are valid (exist in the scene tree).

#### Scenario 10.2 — Happy path: find nodes using a script with no instances
- **Description**: Search for a script that exists but is not attached to any node.
- **Params**: `{"script_path": "res://scripts/unused_helper.gd"}`
- **Expected result**: Returns an empty array `[]` or equivalent.
- **Notes**: Should not error — empty result is the correct behavior.

#### Scenario 10.3 — Error: nonexistent script file
- **Description**: Search for a script file that does not exist.
- **Params**: `{"script_path": "res://does_not_exist.gd"}`
- **Expected result**: `{isError: true}` — script file not found.
- **Notes**: Godot should reject nonexistent script paths.

#### Scenario 10.4 — Error: invalid path format
- **Description**: Pass a non-`res://` path.
- **Params**: `{"script_path": "/absolute/path/script.gd"}`
- **Expected result**: `{isError: true}` — invalid path format.
- **Notes**: Godot expects `res://` prefixed paths.

#### Scenario 10.5 — Error: missing required param
- **Description**: Call without `script_path`.
- **Params**: `{}`
- **Expected result**: MCP schema validation error.
- **Notes**: `script_path` is required.

---

## Tool: `get_autoload`

**Description**: Get properties of an autoload singleton from the running game.

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | `string` | ✅ | Autoload singleton name |

**Godot method**: `runtime/get_autoload`

---

### Test Scenarios

#### Scenario 11.1 — Happy path: get a known autoload
- **Description**: Get properties of a known autoload singleton (e.g., `mcp_runtime` if present, or `GameManager` if present).
- **Params**: `{"name": "mcp_runtime"}`
- **Expected result**: Object with the autoload's properties.
- **Notes**: Use an autoload name that is confirmed to exist in the project. Verify key properties are returned.

#### Scenario 11.2 — Happy path: get different autoload
- **Description**: Get properties of another autoload (if multiple exist).
- **Params**: `{"name": "GameManager"}`
- **Expected result**: Different set of properties matching that autoload.
- **Notes**: Adapt name to actual project autoloads.

#### Scenario 11.3 — Error: nonexistent autoload
- **Description**: Request an autoload name that does not exist.
- **Params**: `{"name": "DoesNotExistSingleton"}`
- **Expected result**: `{isError: true}` — autoload not found.
- **Notes**: Godot should provide a clear error.

#### Scenario 11.4 — Error: missing required param
- **Description**: Call without `name`.
- **Params**: `{}`
- **Expected result**: MCP schema validation error.
- **Notes**: `name` is required.

---

## Tool: `batch_get_properties`

**Description**: Get multiple properties from multiple nodes in one call.

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `paths` | `string[]` | ✅ | List of node paths to query |
| `properties` | `string[]` | ✅ | Property names to read from each node |

**Godot method**: `runtime/batch_get_properties`

---

### Test Scenarios

#### Scenario 12.1 — Happy path: batch read from multiple nodes
- **Description**: Get properties from 2+ nodes simultaneously.
- **Prerequisites**: Identify nodes via `get_game_scene_tree`.
- **Params**: `{"paths": ["Player", "Player/Sprite2D"], "properties": ["position", "visible"]}`
- **Expected result**: Object or array with per-node property results. Each path should have its own property dictionary.
- **Notes**: Verify results are keyed by node path. All requested properties should be present per node.

#### Scenario 12.2 — Happy path: single node, multiple properties
- **Description**: Read many properties from a single node.
- **Params**: `{"paths": ["Player"], "properties": ["type", "name", "position", "rotation", "scale", "visible", "process_mode"]}`
- **Expected result**: Single result object with all requested properties.
- **Notes**: Verify the result structure when only one path is given.

#### Scenario 12.3 — Happy path: multiple nodes, single property
- **Description**: Read one property from many nodes.
- **Params**: `{"paths": ["Player", "Enemy1", "Enemy2", "Camera2D"], "properties": ["position"]}`
- **Expected result**: Results for each node containing only `position`.
- **Notes**: Adapt paths to actual game nodes. This is useful for bulk reads.

#### Scenario 12.4 — Error: one bad path in batch
- **Description**: Include a nonexistent node in the paths array.
- **Params**: `{"paths": ["Player", "/FakeNode"], "properties": ["position"]}`
- **Expected result**: Depends on Godot — may fail entirely, or return results for valid paths with an error for the invalid one.
- **Notes**: Document whether batch operations are atomic (all-or-nothing) or partial.

#### Scenario 12.5 — Error: empty paths array
- **Description**: Pass an empty paths array.
- **Params**: `{"paths": [], "properties": ["position"]}`
- **Expected result**: May return empty result, or be rejected by Zod (depends on `.min(1)`).
- **Notes**: `z.array(z.string())` does not have `.min(1)`, so an empty array passes Zod. Document actual Godot behavior.

#### Scenario 12.6 — Error: missing required params
- **Description**: Call without `paths` or `properties`.
- **Params**:
  - `{}`
  - `{"paths": ["Player"]}`
  - `{"properties": ["position"]}`
- **Expected result**: MCP schema validation errors.
- **Notes**: Both fields are required.

---

## Tool: `find_ui_elements`

**Description**: Find UI elements in the running game by type, text, or name.

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `filter` | `object` (optional) | ❌ | Filter criteria |

`filter` object fields:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `string` | ❌ | Control type (e.g. `'Button'`, `'Label'`) |
| `text` | `string` | ❌ | Text content to search for |

**Godot method**: `runtime/find_ui_elements`

---

### Test Scenarios

#### Scenario 13.1 — Happy path: no filter (get all UI)
- **Description**: Call without filter to get all UI elements.
- **Params**: `{}`
- **Expected result**: Array of all UI elements in the game, each with type, text, and path information.
- **Notes**: Verify the structure includes `type`, `text`, and path for each element.

#### Scenario 13.2 — Happy path: filter by type
- **Description**: Find all Button elements.
- **Params**: `{"filter": {"type": "Button"}}`
- **Expected result**: Array containing only elements where `type` is `"Button"`.
- **Notes**: Verify no non-Button elements appear.

#### Scenario 13.3 — Happy path: filter by text
- **Description**: Find elements containing specific text.
- **Params**: `{"filter": {"text": "Start"}}`
- **Expected result**: Array of elements whose text matches or contains `"Start"`.
- **Notes**: Document whether matching is exact, substring, or case-sensitive.

#### Scenario 13.4 — Happy path: filter by both type and text
- **Description**: Find Button elements with specific text.
- **Params**: `{"filter": {"type": "Button", "text": "Play"}}`
- **Expected result**: Only Button elements whose text matches `"Play"`.
- **Notes**: Both filters should apply simultaneously (AND logic).

#### Scenario 13.5 — Happy path: filter for a type that exists but has no instances
- **Description**: Search for a Control type not present in the UI.
- **Params**: `{"filter": {"type": "ColorPickerButton"}}`
- **Expected result**: Empty array `[]`.
- **Notes**: Should not error on empty results.

#### Scenario 13.6 — Edge case: empty filter object
- **Description**: Pass an empty filter object.
- **Params**: `{"filter": {}}`
- **Expected result**: Same as no filter — returns all UI elements.
- **Notes**: Verify empty object is treated as "no filter".

#### Scenario 13.7 — Edge case: unknown field in filter
- **Description**: Pass an extra field not in schema.
- **Params**: `{"filter": {"type": "Button", "unknown_field": "test"}}`
- **Expected result**: Depends on Zod strictness — may strip unknown field and succeed, or reject.
- **Notes**: `z.object()` by default strips unknown keys. The call should succeed, ignoring `unknown_field`.

---

## Tool: `click_button_by_text`

**Description**: Find and click a button by its text content.

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `text` | `string` | ✅ | Button text to find and click |
| `timeout` | `number` (optional) | ❌ | Timeout in seconds |

**Godot method**: `runtime/click_button`

**Dependencies**: May need `find_ui_elements` first to identify available buttons.

---

### Test Scenarios

#### Scenario 14.1 — Happy path: click existing button
- **Description**: Click a button known to exist in the UI.
- **Prerequisites**: Use `find_ui_elements` to identify a clickable button.
- **Params**: `{"text": "Play"}`
- **Expected result**: Success. The button click is simulated.
- **Notes**: Verify the click has the expected side effect (e.g., scene transition, state change). Use `get_game_node_properties` or `get_game_scene_tree` to observe changes.

#### Scenario 14.2 — Happy path: click with timeout
- **Description**: Click a button with an explicit timeout.
- **Params**: `{"text": "Start", "timeout": 5.0}`
- **Expected result**: Success — button found and clicked within 5 seconds.
- **Notes**: If button appears after a delay, the tool should wait for it.

#### Scenario 14.3 — Error: button not found
- **Description**: Try to click a button that does not exist.
- **Params**: `{"text": "ButtonThatDoesNotExistXYZ"}`
- **Expected result**: `{isError: true}` — button not found.
- **Notes**: Without timeout, this should fail immediately or after a short default wait.

#### Scenario 14.4 — Error: timeout while waiting
- **Description**: Click a button that appears after the timeout expires.
- **Params**: `{"text": "DelayedButton", "timeout": 0.1}`
- **Expected result**: `{isError: true}` — timeout waiting for button.
- **Notes**: Only test if the game has a button that appears with a known delay.

#### Scenario 14.5 — Error: missing required param
- **Description**: Call without `text`.
- **Params**: `{}`
- **Expected result**: MCP schema validation error.
- **Notes**: `text` is required.

#### Scenario 14.6 — Edge case: button text with special characters
- **Description**: Click a button whose text contains special characters (quotes, newlines, Unicode).
- **Params**: `{"text": "Click \"Me\"!"}`
- **Expected result**: Success if such a button exists; otherwise not-found error.
- **Notes**: Verify that special characters in text are handled correctly (no escaping issues).

---

## Tool: `wait_for_node`

**Description**: Wait for a node to appear in the running game tree.

**Parameters**:
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (NodePath) | ✅ | — | Node path to wait for |
| `timeout` | `number` (optional) | ❌ | 5.0 | Timeout in seconds |

**Godot method**: `runtime/wait_for_node`

---

### Test Scenarios

#### Scenario 15.1 — Happy path: wait for existing node
- **Description**: Wait for a node that already exists.
- **Prerequisites**: Have a node in the scene.
- **Params**: `{"path": "Player"}`
- **Expected result**: Returns success immediately (node already present).
- **Notes**: Should return near-instantly.

#### Scenario 15.2 — Happy path: wait for node that appears later
- **Description**: Wait for a node that is dynamically created.
- **Prerequisites**: Need a mechanism to create a node after a delay (e.g., spawn an enemy).
- **Params**: `{"path": "EnemySpawned", "timeout": 10.0}`
- **Expected result**: Blocks until node appears, then returns success.
- **Notes**: Verify the elapsed time matches when the node actually appeared. If node appears at t=3s and timeout is 10s, return should happen around t=3s.

#### Scenario 15.3 — Happy path: custom timeout
- **Description**: Specify a very long timeout.
- **Params**: `{"path": "Player", "timeout": 60.0}`
- **Expected result**: Success (node already exists, returns immediately).
- **Notes**: Verify the call does not actually block for 60 seconds.

#### Scenario 15.4 — Error: node never appears (timeout)
- **Description**: Wait for a node that never appears.
- **Params**: `{"path": "/WillNeverExist", "timeout": 2.0}`
- **Expected result**: `{isError: true}` — timeout after ~2 seconds.
- **Notes**: Verify error message indicates timeout, not generic "not found". The elapsed time should be approximately the specified timeout.

#### Scenario 15.5 — Error: missing required param
- **Description**: Call without `path`.
- **Params**: `{}`
- **Expected result**: MCP schema validation error.
- **Notes**: `path` is required.

#### Scenario 15.6 — Edge case: zero timeout
- **Description**: Pass `timeout: 0`.
- **Params**: `{"path": "Player", "timeout": 0}`
- **Expected result**: May fail immediately or be treated as "no timeout". Document actual behavior.
- **Notes**: Schema allows 0 (Timeout has no `.positive()` or `.min()`). Godot behavior is unclear.

#### Scenario 15.7 — Edge case: negative timeout
- **Description**: Pass a negative timeout.
- **Params**: `{"path": "Player", "timeout": -5.0}`
- **Expected result**: May be accepted by schema but should error in Godot.
- **Notes**: Document actual behavior. Consider adding validation if accepted.

---

## Tool: `find_nearby_nodes`

**Description**: Find nodes within a radius of a world position.

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `position` | `number[3]` (Position3D) | ✅ | Center position [x, y, z] |
| `radius` | `number` (>0) | ✅ | Search radius |

**Godot method**: `runtime/find_nearby`

---

### Test Scenarios

#### Scenario 16.1 — Happy path: find nodes near known position
- **Description**: Search for nodes around a position where nodes are known to exist.
- **Prerequisites**: Know the position of some game nodes (e.g., from `get_game_node_properties`).
- **Params**: `{"position": [0, 0, 0], "radius": 100.0}`
- **Expected result**: Array of node paths within 100 units of [0, 0, 0].
- **Notes**: Verify returned nodes are all within the specified radius. If the player is at [0, 0, 0], it should be in the results.

#### Scenario 16.2 — Happy path: zero radius find
- **Description**: Search with radius of a small positive value.
- **Params**: `{"position": [100, 50, 0], "radius": 0.01}`
- **Expected result**: Only nodes exactly at that position (or within very small tolerance).
- **Notes**: PositiveNumber requires > 0. Verify exact-position matching.

#### Scenario 16.3 — Happy path: large radius (all nodes)
- **Description**: Search with very large radius.
- **Params**: `{"position": [0, 0, 0], "radius": 100000.0}`
- **Expected result**: All spatial nodes in the game.
- **Notes**: Verify no crash with extreme values.

#### Scenario 16.4 — Happy path: empty area
- **Description**: Search a position where no nodes exist.
- **Params**: `{"position": [99999, 99999, 99999], "radius": 1.0}`
- **Expected result**: Empty array `[]`.
- **Notes**: Should not error.

#### Scenario 16.5 — Error: invalid position array length
- **Description**: Pass position array with wrong dimensions.
- **Params**:
  - `{"position": [0, 0], "radius": 10.0}` (length 2)
  - `{"position": [0, 0, 0, 0], "radius": 10.0}` (length 4)
  - `{"position": [], "radius": 10.0}` (empty)
- **Expected result**: Zod validation error — Position3D requires exactly length 3.
- **Notes**: `Position3D = z.array(z.number()).length(3)` rejects wrong-length arrays.

#### Scenario 16.6 — Error: non-numeric position values
- **Description**: Pass non-number values in position array.
- **Params**: `{"position": [0, "ten", 0], "radius": 10.0}`
- **Expected result**: Zod validation error.
- **Notes**: `z.number()` rejects strings.

#### Scenario 16.7 — Error: zero or negative radius
- **Description**: Pass radius ≤ 0.
- **Params**:
  - `{"position": [0, 0, 0], "radius": 0}`
  - `{"position": [0, 0, 0], "radius": -10}`
- **Expected result**: Zod validation error — PositiveNumber rejects ≤ 0.
- **Notes**: `z.number().positive()` rejects both.

#### Scenario 16.8 — Error: missing required params
- **Description**: Call without `position` or `radius`.
- **Params**:
  - `{}`
  - `{"position": [0, 0, 0]}`
  - `{"radius": 10.0}`
- **Expected result**: MCP schema validation errors.
- **Notes**: Both fields are required.

---

## Tool: `navigate_to`

**Description**: Navigate a node to a target position using pathfinding.

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` (NodePath) | ✅ | Node path to navigate (must have NavigationAgent3D) |
| `target` | `number[3]` (Position3D) | ✅ | Target position [x, y, z] |

**Godot method**: `runtime/navigate_to`

---

### Test Scenarios

#### Scenario 17.1 — Happy path: navigate with NavigationAgent3D
- **Description**: Navigate a node that has a NavigationAgent3D child.
- **Prerequisites**: Need a node with NavigationAgent3D and a baked navigation mesh in the scene.
- **Params**: `{"path": "Player", "target": [50, 0, 50]}`
- **Expected result**: Success. The node begins moving toward the target along the navmesh.
- **Notes**: Verify the node actually moves (check position via `get_game_node_properties` after a short wait). The navigation should follow the navmesh, not a straight line.

#### Scenario 17.2 — Happy path: navigate to nearby position
- **Description**: Navigate a short distance.
- **Params**: `{"path": "Player", "target": [5, 0, 0]}`
- **Expected result**: Success. Node moves to nearby target.
- **Notes**: Verify quick arrival.

#### Scenario 17.3 — Error: node without NavigationAgent3D
- **Description**: Try to navigate a node that does not have NavigationAgent3D.
- **Params**: `{"path": "Camera2D", "target": [10, 0, 10]}`
- **Expected result**: `{isError: true}` — no NavigationAgent3D available.
- **Notes**: Godot should detect the missing navigation agent.

#### Scenario 17.4 — Error: nonexistent node
- **Description**: Navigate a node that does not exist.
- **Params**: `{"path": "/DoesNotExist", "target": [0, 0, 0]}`
- **Expected result**: `{isError: true}` — node not found.
- **Notes**: Standard node-not-found error.

#### Scenario 17.5 — Error: invalid target position
- **Description**: Pass an invalid target array.
- **Params**: `{"path": "Player", "target": [0, 0]}` (length 2)
- **Expected result**: Zod validation error — Position3D requires length 3.
- **Notes**: Schema validation catches this.

#### Scenario 17.6 — Happy path: unreachable target
- **Description**: Navigate to a position on a navmesh island not connected to the current position.
- **Params**: `{"path": "Player", "target": [99999, 0, 999999]}` (far away, unreachable)
- **Expected result**: Success or error depending on Godot implementation. May accept the request but never arrive. May error immediately.
- **Notes**: Document actual behavior — does Godot report unreachable targets?

---

## Tool: `move_to`

**Description**: Directly move a node to a target position.

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` (NodePath) | ✅ | Node path to move |
| `target` | `number[3]` (Position3D) | ✅ | Target position [x, y, z] |

**Godot method**: `runtime/move_to`

---

### Test Scenarios

#### Scenario 18.1 — Happy path: teleport a node
- **Description**: Directly move a node to a new position (instant teleport).
- **Prerequisites**: Identify a movable node.
- **Params**: `{"path": "Player", "target": [100, 200, 0]}`
- **Expected result**: Success. The node's position changes immediately to [100, 200, 0].
- **Notes**: Verify the position change via `get_game_node_properties`. Unlike `navigate_to`, this should be instantaneous (no pathfinding).

#### Scenario 18.2 — Happy path: move to same position
- **Description**: Move a node to its current position.
- **Params**: Get current position via `get_game_node_properties`, then call `move_to` with the same coordinates.
- **Expected result**: Success (no-op).
- **Notes**: Verify no error and position unchanged.

#### Scenario 18.3 — Happy path: move to negative coordinates
- **Description**: Move a node to a negative position.
- **Params**: `{"path": "Player", "target": [-100, -200, -50]}`
- **Expected result**: Success. Position set to negative values.
- **Notes**: Godot supports negative positions. Verify via property read.

#### Scenario 18.4 — Error: nonexistent node
- **Description**: Move a node that does not exist.
- **Params**: `{"path": "/FakeNode", "target": [0, 0, 0]}`
- **Expected result**: `{isError: true}` — node not found.
- **Notes**: Standard error.

#### Scenario 18.5 — Error: invalid target
- **Description**: Pass wrong dimension target.
- **Params**: `{"path": "Player", "target": [0]}`
- **Expected result**: Zod validation error — Position3D requires length 3.
- **Notes**: Schema level rejection.

#### Scenario 18.6 — Error: missing required params
- **Description**: Call without `path` or `target`.
- **Params**: `{}`, `{"path": "Player"}`, `{"target": [0, 0, 0]}`
- **Expected result**: MCP schema validation errors.
- **Notes**: Both required.

---

## Tool: `watch_signals`

**Description**: Watch for signal emissions from a game node.

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` (NodePath) | ✅ | Node path to watch |
| `signals` | `string[]` | ✅ | Signal names to watch for |
| `duration` | `number` (optional) | ❌ | How long to watch in seconds |

**Godot method**: `runtime/watch_signals`

---

### Test Scenarios

#### Scenario 19.1 — Happy path: watch a known signal
- **Description**: Watch for a signal on a known node.
- **Prerequisites**: Identify a node that emits signals (e.g., a Timer with `timeout`, or a Button with `pressed`).
- **Params**: `{"path": "SomeTimer", "signals": ["timeout"], "duration": 3.0}`
- **Expected result**: After ~3 seconds, returns an array of signal emissions with timestamps and arguments. If the timer fired during the watch period, its emissions are recorded.
- **Notes**: Verify the returned data includes signal name, timestamp, and arguments.

#### Scenario 19.2 — Happy path: watch multiple signals
- **Description**: Watch for multiple signals on the same node.
- **Params**: `{"path": "Player", "signals": ["ready", "process", "tree_entered"], "duration": 2.0}`
- **Expected result**: Data for each signal that fired during the window.
- **Notes**: Some signals fire once (`ready`), others repeatedly (`process`). Verify both types are recorded correctly.

#### Scenario 19.3 — Happy path: watch with no signals fired
- **Description**: Watch a node for a signal that never emits during the duration.
- **Params**: `{"path": "StaticBody", "signals": ["body_entered"], "duration": 1.0}`
- **Expected result**: Returns empty/success — no signals observed.
- **Notes**: Should not error. An empty result is valid.

#### Scenario 19.4 — Happy path: watch without explicit duration
- **Description**: Watch signals without specifying duration.
- **Params**: `{"path": "Player", "signals": ["process"]}`
- **Expected result**: Depends on Godot — may use a default duration, return a single sample, or block indefinitely.
- **Notes**: Document actual behavior when duration is omitted. If it blocks indefinitely, note this as a risk.

#### Scenario 19.5 — Error: nonexistent node
- **Description**: Watch a node that does not exist.
- **Params**: `{"path": "/FakeNode", "signals": ["ready"]}`
- **Expected result**: `{isError: true}` — node not found.
- **Notes**: Standard error.

#### Scenario 19.6 — Error: nonexistent signal
- **Description**: Watch for a signal that does not exist on the node.
- **Params**: `{"path": "Player", "signals": ["signal_that_does_not_exist"]}`
- **Expected result**: May error or silently ignore the unknown signal. Document behavior.
- **Notes**: Godot may warn about unknown signals.

#### Scenario 19.7 — Error: missing required params
- **Description**: Call without `path` or `signals`.
- **Params**:
  - `{}`
  - `{"path": "Player"}`
  - `{"signals": ["ready"]}`
- **Expected result**: MCP schema validation errors.
- **Notes**: Both required.

#### Scenario 19.8 — Edge case: zero or negative duration
- **Description**: Pass `duration: 0` or `duration: -1`.
- **Params**: `{"path": "Player", "signals": ["process"], "duration": 0}`
- **Expected result**: May return immediately (zero samples) or error.
- **Notes**: Document actual behavior.

#### Scenario 19.9 — Edge case: empty signals array
- **Description**: Pass an empty array for signals.
- **Params**: `{"path": "Player", "signals": [], "duration": 2.0}`
- **Expected result**: May return empty result or error.
- **Notes**: Document whether empty array passes Zod validation and what Godot does with it.

---

## Inter-Tool Dependency Sequences

These sequences test that multiple tools work together correctly.

---

### Sequence A: Record → Stop → Replay cycle

1. `start_recording` → `{}` → success
2. (Wait 3 seconds — game runs)
3. `stop_recording` → `{}` → returns recording data
4. `replay_recording` → `{"speed": 1.0}` → replay begins
5. `replay_recording` → `{"speed": 2.0}` → replay at double speed
   - **Expected**: Full cycle works without errors. Recording data from step 3 is usable by step 4.
   - **Note**: Verify that after replay, the game state is consistent (not corrupted).

---

### Sequence B: Scene tree → Properties → Modify → Verify

1. `get_game_scene_tree` → `{}` → get full tree
2. Pick a node from the result (e.g., `"Player"`)
3. `get_game_node_properties` → `{"path": "Player", "properties": ["position", "visible"]}` → get current state
4. `set_game_node_property` → `{"path": "Player", "property": "visible", "value": false}` → change property
5. `get_game_node_properties` → `{"path": "Player", "properties": ["visible"]}` → verify change
   - **Expected**: Step 5 shows `visible: false`.
6. `set_game_node_property` → `{"path": "Player", "property": "visible", "value": true}` → restore
   - **Expected**: Full read-modify-verify cycle works. Property changes are correctly relayed.

---

### Sequence C: Find → Inspect → Navigate

1. `get_game_scene_tree` → `{}` → identify nodes
2. `get_game_node_properties` → `{"path": "Player", "properties": ["position"]}` → get current position
3. `move_to` → `{"path": "Player", "target": [50, 0, 50]}` → teleport
4. `get_game_node_properties` → `{"path": "Player", "properties": ["position"]}` → verify new position
5. `navigate_to` → `{"path": "Player", "target": [0, 0, 0]}` → pathfind back
6. `wait_for_node` → `{"path": "Player", "timeout": 5.0}` → (already exists, returns immediately)
7. `get_game_node_properties` → `{"path": "Player", "properties": ["position"]}` → verify arrival
   - **Expected**: Movement tools change position. Navigation may take time; position may not be exact target.

---

### Sequence D: UI discovery → click → verify

1. `find_ui_elements` → `{"filter": {"type": "Button"}}` → get all buttons
2. Identify a button from the result (e.g., one with `text: "Play"`)
3. `click_button_by_text` → `{"text": "Play"}` → click the button
4. `get_game_scene_tree` → `{}` → check if scene changed
   - **Expected**: UI discovery finds clickable elements. Clicking triggers expected side effects.

---

### Sequence E: Watch signals while performing actions

1. `watch_signals` → `{"path": "Player", "signals": ["ready"], "duration": 2.0}` → start watching
   (Note: This blocks for 2 seconds; concurrently, other agents could interact)
2. Alternatively, use a short duration watch to capture recent signals.
   - **Expected**: Signal watching correctly captures emissions during the watch window.

---

### Sequence F: Batch read → individual verify

1. `batch_get_properties` → `{"paths": ["Player", "Camera2D", "Enemy1"], "properties": ["position", "visible"]}` → bulk read
2. `get_game_node_properties` → `{"path": "Player", "properties": ["position"]}` → individual read
   - **Expected**: Individual read results match the batch read results for the same node+property.
   - Adapt paths to actual game nodes.

---

## Error Handling — Cross-Cutting Concerns

These tests apply to ALL runtime tools.

### E.1 — Game not running
- **For every tool**: Call while the Godot editor is idle (no game running).
- **Expected**: Every tool returns `{isError: true}` with a descriptive message.
- **Verify**: No tool returns a success or hangs indefinitely.

### E.2 — Godot not connected
- **For every tool**: Call while the MCP server is running but Godot is not connected.
- **Expected**: Every tool returns `{isError: true}` with message `'Godot editor is not connected'`.
- **Verify**: The error is immediate (no timeout).

### E.3 — Timeout handling
- **For tools with timeout parameter (`click_button_by_text`, `wait_for_node`, `watch_signals`)**: Verify the timeout is honored.
- **For tools without timeout**: If Godot hangs (e.g., `execute_game_script` with infinite loop), the bridge-level `REQUEST_TIMEOUT_MS` should kick in.
- **Expected**: Long-running operations are terminated with a timeout error.

### E.4 — Concurrent calls
- **Description**: Call multiple runtime tools simultaneously (within MCP protocol limits).
- **Test**: Fire 3+ calls in parallel (e.g., `get_game_scene_tree`, `get_game_node_properties`, `capture_frames`).
- **Expected**: All calls complete successfully without interference. Results are correct for each.
- **Note**: WebSocket is sequential, but multiple pending requests should be handled correctly by the bridge.

### E.5 — Schema validation
- **For every tool**: Verify that Zod validation rejects invalid types BEFORE any Godot call is made.
- **Test method**: Send requests with wrong-typed parameters via MCP.
- **Expected**: MCP returns validation errors, not Godot errors.

---

## Summary

| # | Tool | Params | Required | Optional | Godot Method |
|---|------|--------|----------|----------|-------------|
| 1 | `get_game_scene_tree` | — | — | — | `runtime/get_scene_tree` |
| 2 | `get_game_node_properties` | 2 | `path` | `properties` | `runtime/get_node_properties` |
| 3 | `set_game_node_property` | 3 | `path`, `property`, `value` | — | `runtime/set_node_property` |
| 4 | `execute_game_script` | 1 | `code` | — | `runtime/execute_script` |
| 5 | `capture_frames` | 2 | — | `count`, `interval` | `runtime/capture_frames` |
| 6 | `monitor_properties` | 3 | `path`, `properties` | `duration` | `runtime/monitor_properties` |
| 7 | `start_recording` | — | — | — | `runtime/start_recording` |
| 8 | `stop_recording` | — | — | — | `runtime/stop_recording` |
| 9 | `replay_recording` | 1 | — | `speed` | `runtime/replay_recording` |
| 10 | `find_nodes_by_script` | 1 | `script_path` | — | `runtime/find_by_script` |
| 11 | `get_autoload` | 1 | `name` | — | `runtime/get_autoload` |
| 12 | `batch_get_properties` | 2 | `paths`, `properties` | — | `runtime/batch_get_properties` |
| 13 | `find_ui_elements` | 1 | — | `filter` | `runtime/find_ui_elements` |
| 14 | `click_button_by_text` | 2 | `text` | `timeout` | `runtime/click_button` |
| 15 | `wait_for_node` | 2 | `path` | `timeout` | `runtime/wait_for_node` |
| 16 | `find_nearby_nodes` | 2 | `position`, `radius` | — | `runtime/find_nearby` |
| 17 | `navigate_to` | 2 | `path`, `target` | — | `runtime/navigate_to` |
| 18 | `move_to` | 2 | `path`, `target` | — | `runtime/move_to` |
| 19 | `watch_signals` | 3 | `path`, `signals` | `duration` | `runtime/watch_signals` |

**Total scenarios**: ~85 individual scenarios + 6 dependency sequences + 5 cross-cutting error tests.
