# Runtime Tools — Test Plan

**Source file:** `server/src/tools/runtime.ts`  
**Precondition for ALL tools:** Game must be running (🔴). All tools in this module require an active game session unless otherwise noted in individual scenarios.

---

## 1. `get_game_scene_tree`

**Description:** Get the scene tree of the running game (runtime state).  
**Schema:** `{}` — no parameters.  
**Handler:** `callGodot(bridge, 'runtime/get_scene_tree')`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — get scene tree while game is running** | `{}` | Returns JSON with the runtime scene tree hierarchy (node names, types, parent-child relationships) | Verify tree matches what's visible in Godot's Remote scene dock |
| 2 | **Game not running** | `{}` | Error: game must be running / autoload not available | Confirms precondition guard |
| 3 | **Empty scene** | `{}` | Returns tree with only root node | Edge case: minimal scene |

---

## 2. `get_game_node_properties`

**Description:** Get all properties of a node in the running game.  
**Schema:**
- `path` (required) — `string` (NodePath) — Node path in the game tree
- `properties` (optional) — `string[]` — Specific property names to return (defaults to common properties)

**Handler:** `callGodot(bridge, 'runtime/get_node_properties', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — get all default properties of root node** | `{"path": ""}` | Returns JSON object with common properties (name, type, position, etc.) | Tests empty string → scene root |
| 2 | **Happy path — get properties of a named child node** | `{"path": "Player"}` | Returns JSON with Player node's properties | Tests single-level path |
| 3 | **Happy path — get properties of a nested node** | `{"path": "Player/Sprite2D"}` | Returns JSON with Sprite2D's properties | Tests multi-level path |
| 4 | **With specific property list** | `{"path": "Player", "properties": ["position", "rotation", "scale"]}` | Returns JSON with ONLY those 3 properties | Tests the optional `properties` filter |
| 5 | **With empty property list** | `{"path": "Player", "properties": []}` | Returns empty object or all properties (implementation-dependent) | Edge case |
| 6 | **Non-existent node** | `{"path": "NonExistentNode"}` | Error: node not found | Error handling |
| 7 | **Missing required param `path`** | `{}` | Schema validation error | Required param validation |
| 8 | **Invalid path type** | `{"path": 123}` | Schema validation error — expected string | Type validation |

---

## 3. `set_game_node_property`

**Description:** Set a property on a node in the running game.  
**Schema:**
- `path` (required) — `string` (NodePath) — Node path in the game tree
- `property` (required) — `string` — Property name to set
- `value` (required) — `unknown` — New value for the property

**Handler:** `callGodot(bridge, 'runtime/set_node_property', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — set a float property** | `{"path": "Player", "property": "position:x", "value": 100.0}` | Success (property updated in-game) | Numeric value |
| 2 | **Set a string property** | `{"path": "Player", "property": "name", "value": "NewName"}` | Success, node renamed in-game | String value |
| 3 | **Set a boolean property** | `{"path": "Player", "property": "visible", "value": false}` | Success, node hidden in-game | Boolean value |
| 4 | **Set a vector property** | `{"path": "Player", "property": "position", "value": [50.0, 100.0]}` | Success, node teleported | Array value |
| 5 | **Set on nested node** | `{"path": "Player/Camera3D", "property": "fov", "value": 90}` | Success, camera FOV changes | Nested path |
| 6 | **Set a non-writable property** | `{"path": "Player", "property": "read_only_flag", "value": true}` | Error from Godot: property is read-only | Error handling |
| 7 | **Non-existent node** | `{"path": "DoesNotExist", "property": "visible", "value": false}` | Error: node not found | Error handling |
| 8 | **Non-existent property** | `{"path": "Player", "property": "nonexistent_prop", "value": 1}` | Error: property does not exist | Error handling |
| 9 | **Missing required `path`** | `{"property": "visible", "value": false}` | Schema validation error | Required param |
| 10 | **Missing required `property`** | `{"path": "Player", "value": false}` | Schema validation error | Required param |
| 11 | **Set with null value** | `{"path": "Player", "property": "scale", "value": null}` | Behavior depends on property type — may error or set to default | Edge case |

---

## 4. `execute_game_script`

**Description:** Execute a GDScript snippet in the running game context.  
**Schema:**
- `code` (required) — `string` (GDScriptCode) — GDScript code to execute

**Handler:** `callGodot(bridge, 'runtime/execute_script', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — simple expression** | `{"code": "print(\"Hello from MCP\")"}` | Success; `"Hello from MCP"` appears in Godot output log | Basic GDScript |
| 2 | **Return a value** | `{"code": "return 2 + 2"}` | Returns `4` | Expression evaluation |
| 3 | **Access autoload** | `{"code": "return get_tree().current_scene.name"}` | Returns the current scene name | Autoload/engine API access |
| 4 | **Multi-line script** | `{"code": "var x = 10\nvar y = 20\nreturn x + y"}` | Returns `30` | Multi-line code |
| 5 | **Modify game state** | `{"code": "Engine.time_scale = 0.5"}` | Success; game runs at half speed | Side-effect verification |
| 6 | **Syntax error in GDScript** | `{"code": "var x = "}` | Error: parse error from GDScript | Error handling |
| 7 | **Runtime error** | `{"code": "var n = null\nreturn n.some_method()"}` | Error: null instance | Error handling |
| 8 | **Missing required `code`** | `{}` | Schema validation error | Required param |
| 9 | **Empty code string** | `{"code": ""}` | Implementation-dependent: may return null or error | Edge case |
| 10 | **Very long script** | `{"code": "<large GDScript ~10KB>"}` | Success or timeout | Boundary: large payload |

---

## 5. `capture_frames`

**Description:** Capture frames from the running game viewport as PNG files.  
**Schema:**
- `count` (optional) — `integer`, min 1, max 60, default 1 — Number of frames to capture
- `interval` (optional) — `number` — Interval between captures in seconds

**Handler:** `callGodot(bridge, 'runtime/capture_frames', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — capture single frame (default)** | `{}` | Returns path to 1 PNG file; file exists on disk | Default count=1 |
| 2 | **Capture multiple frames** | `{"count": 5}` | Returns paths to 5 PNG files | Multi-frame |
| 3 | **Capture with interval** | `{"count": 3, "interval": 0.5}` | Returns 3 paths; captures spaced ~0.5s apart | Interval timing |
| 4 | **Max frames (60)** | `{"count": 60}` | Returns 60 file paths | Boundary: upper limit |
| 5 | **Min frames (1)** | `{"count": 1}` | Returns 1 file path | Boundary: lower limit |
| 6 | **Count at boundary 0** | `{"count": 0}` | Schema validation error — count must be >= 1 | Boundary violation |
| 7 | **Count at boundary 61** | `{"count": 61}` | Schema validation error — count must be <= 60 | Boundary violation |
| 8 | **Negative count** | `{"count": -1}` | Schema validation error | Invalid value |
| 9 | **Non-integer count** | `{"count": 3.5}` | Schema validation error — must be integer | Type validation |
| 10 | **Negative interval** | `{"count": 2, "interval": -1.0}` | Implementation-dependent: may error or be treated as 0 | Edge case |
| 11 | **String count** | `{"count": "three"}` | Schema validation error — expected number | Type validation |

---

## 6. `monitor_properties`

**Description:** Monitor specific properties on a game node for changes over time.  
**Schema:**
- `path` (required) — `string` (NodePath) — Node path to monitor
- `properties` (required) — `string[]` — Property names to monitor
- `duration` (optional) — `number` (Timeout) — Monitoring duration in seconds

**Handler:** `callGodot(bridge, 'runtime/monitor_properties', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — monitor single property** | `{"path": "Player", "properties": ["position"]}` | Returns timeline data for position over default duration | Basic monitoring |
| 2 | **Monitor multiple properties** | `{"path": "Player", "properties": ["position", "rotation", "scale"]}` | Returns timeline for all 3 properties | Multiple props |
| 3 | **With explicit duration** | `{"path": "Player", "properties": ["position"], "duration": 3.0}` | Returns ~3 seconds of timeline data | Custom duration |
| 4 | **Zero duration** | `{"path": "Player", "properties": ["position"], "duration": 0}` | May return empty timeline or error | Boundary |
| 5 | **Negative duration** | `{"path": "Player", "properties": ["position"], "duration": -1}` | Implementation-dependent | Edge case |
| 6 | **Empty properties array** | `{"path": "Player", "properties": []}` | May return empty result or error | Edge case |
| 7 | **Non-existent node** | `{"path": "Ghost", "properties": ["position"]}` | Error: node not found | Error handling |
| 8 | **Missing required `path`** | `{"properties": ["position"]}` | Schema validation error | Required param |
| 9 | **Missing required `properties`** | `{"path": "Player"}` | Schema validation error | Required param |
| 10 | **Non-existent property** | `{"path": "Player", "properties": ["fake_prop"]}` | Error or empty data for that property | Error handling |

---

## 7. `start_recording`

**Description:** Start recording game state changes. Must call before any recording-dependent tools.  
**Schema:** `{}` — no parameters.  
**Handler:** `callGodot(bridge, 'runtime/start_recording')`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — start recording** | `{}` | Success confirmation; recording begins | Verify subsequent `stop_recording` returns data |
| 2 | **Start recording when already recording** | `{}` (call twice) | Second call: may restart recording or return "already recording" | Idempotency |
| 3 | **Game not running** | `{}` | Error: game must be running | Precondition guard |
| 4 | **Start → play game → stop** | `{}` (then interact, then stop_recording) | Recorded data contains the gameplay interactions | Integration: full record cycle |

---

## 8. `stop_recording`

**Description:** Stop recording and return the recorded game state data.  
**Schema:** `{}` — no parameters.  
**Handler:** `callGodot(bridge, 'runtime/stop_recording')`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — stop after recording** | `{}` (after `start_recording`) | Returns recorded game state data (JSON with timeline) | Normal flow |
| 2 | **Stop without starting** | `{}` (without prior `start_recording`) | Error or empty data: no recording active | Error handling |
| 3 | **Stop twice consecutively** | `{}` (twice) | Second call: error or empty — no active recording | Idempotency |
| 4 | **Stop after game stopped** | `{}` (game was stopped during recording) | Data up to stop point, or error | Edge case |

---

## 9. `replay_recording`

**Description:** Replay a previously recorded game session.  
**Schema:**
- `speed` (optional) — `number` (positive), default 1.0 — Playback speed multiplier

**Handler:** `callGodot(bridge, 'runtime/replay_recording', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — replay at default 1x speed** | `{}` | Recording replays at normal speed; success confirmation | Default speed=1.0 |
| 2 | **Replay at 2x speed** | `{"speed": 2.0}` | Recording replays twice as fast | Fast playback |
| 3 | **Replay at 0.5x (slow-mo)** | `{"speed": 0.5}` | Recording replays at half speed | Slow playback |
| 4 | **Replay at 5x speed** | `{"speed": 5.0}` | Recording replays 5x fast | High speed |
| 5 | **Replay at very small speed** | `{"speed": 0.1}` | Recording crawls (10x slower) | Boundary: near-zero |
| 6 | **Zero speed** | `{"speed": 0}` | Schema validation error — must be positive (> 0) | PositiveNumber constraint |
| 7 | **Negative speed** | `{"speed": -1.0}` | Schema validation error — must be positive (> 0) | PositiveNumber constraint |
| 8 | **String speed** | `{"speed": "fast"}` | Schema validation error — expected number | Type validation |
| 9 | **Replay with no recording** | `{}` (no prior record) | Error: no recording available | Error handling |

---

## 10. `find_nodes_by_script`

**Description:** Find all nodes in the game that use a specific script.  
**Schema:**
- `script_path` (required) — `string` (ScriptPath) — Script file path to search for (e.g. `'res://scripts/enemy.gd'`)

**Handler:** `callGodot(bridge, 'runtime/find_by_script', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — find nodes with a script** | `{"script_path": "res://scripts/player.gd"}` | Returns array of node paths that use this script | Typical usage |
| 2 | **Script path with no matches** | `{"script_path": "res://scripts/unused.gd"}` | Returns empty array `[]` | No matches |
| 3 | **Non-existent script path** | `{"script_path": "res://scripts/does_not_exist.gd"}` | Error or empty array | Error handling |
| 4 | **Invalid path format (absolute OS path)** | `{"script_path": "C:\\Users\\script.gd"}` | Error: invalid path (must be `res://` prefixed) | Path format validation |
| 5 | **Missing required `script_path`** | `{}` | Schema validation error | Required param |
| 6 | **Path without `res://` prefix** | `{"script_path": "scripts/player.gd"}` | May error, or Godot may resolve relative to project | Path format edge case |

---

## 11. `get_autoload`

**Description:** Get properties of an autoload singleton from the running game.  
**Schema:**
- `name` (required) — `string` — Autoload singleton name

**Handler:** `callGodot(bridge, 'runtime/get_autoload', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — get known autoload** | `{"name": "mcp_runtime"}` | Returns properties/metadata of the MCP runtime autoload | The MCP plugin's own autoload |
| 2 | **Get another registered autoload** | `{"name": "GameManager"}` | Returns properties of GameManager (if exists in project) | Depends on project autoloads |
| 3 | **Non-existent autoload** | `{"name": "NonExistentSingleton"}` | Error: autoload not found | Error handling |
| 4 | **Empty string name** | `{"name": ""}` | Error or empty result | Edge case |
| 5 | **Missing required `name`** | `{}` | Schema validation error | Required param |
| 6 | **Case sensitivity** | `{"name": "MCP_RUNTIME"}` vs `{"name": "mcp_runtime"}` | Depends on Godot: case-sensitive, likely error for wrong case | Case sensitivity |

---

## 12. `batch_get_properties`

**Description:** Get multiple properties from multiple nodes in one call.  
**Schema:**
- `paths` (required) — `string[]` — List of node paths to query
- `properties` (required) — `string[]` — Property names to read from each node

**Handler:** `callGodot(bridge, 'runtime/batch_get_properties', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — single node, single property** | `{"paths": ["Player"], "properties": ["position"]}` | Returns `{"Player": {"position": [...]}}` | Basic batch |
| 2 | **Multiple nodes, multiple properties** | `{"paths": ["Player", "Player/Camera3D"], "properties": ["position", "name"]}` | Returns properties for all node × property combinations | Multi-node batch |
| 3 | **Empty paths array** | `{"paths": [], "properties": ["position"]}` | Returns empty object `{}` | Edge case |
| 4 | **Empty properties array** | `{"paths": ["Player"], "properties": []}` | Returns empty per-node objects or all defaults | Edge case |
| 5 | **Non-existent node in paths** | `{"paths": ["Player", "Ghost"], "properties": ["position"]}` | Error for Ghost, or partial results with error | Partial failure |
| 6 | **Many nodes (e.g., 50)** | `{"paths": ["N1","N2",...50 nodes], "properties": ["name"]}` | Returns results for all 50 nodes | Scale boundary |
| 7 | **Missing `paths`** | `{"properties": ["position"]}` | Schema validation error | Required param |
| 8 | **Missing `properties`** | `{"paths": ["Player"]}` | Schema validation error | Required param |
| 9 | **Paths as non-array** | `{"paths": "Player", "properties": ["position"]}` | Schema validation error — expected array | Type validation |

---

## 13. `find_ui_elements`

**Description:** Find UI elements in the running game by type, text, or name.  
**Schema:**
- `filter` (optional) — `object` — Filter criteria:
  - `type` (optional) — `string` — Control type to filter by (e.g. `'Button'`, `'Label'`)
  - `text` (optional) — `string` — Text content to search for

**Handler:** `callGodot(bridge, 'runtime/find_ui_elements', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — no filter (find all)** | `{}` | Returns array of all UI elements in the running game | No filter = return all |
| 2 | **Filter by type: Button** | `{"filter": {"type": "Button"}}` | Returns only Button elements | Type filter |
| 3 | **Filter by type: Label** | `{"filter": {"type": "Label"}}` | Returns only Label elements | Type filter variant |
| 4 | **Filter by text** | `{"filter": {"text": "Start Game"}}` | Returns elements containing "Start Game" | Text filter |
| 5 | **Filter by type AND text** | `{"filter": {"type": "Button", "text": "Play"}}` | Returns only Buttons with text "Play" | Combined filter |
| 6 | **Empty filter object** | `{"filter": {}}` | Returns all UI elements (same as no filter) | Edge case |
| 7 | **Non-existent type** | `{"filter": {"type": "NonExistentControl"}}` | Returns empty array | No matches |
| 8 | **No matches for text** | `{"filter": {"text": "zzz_nonexistent_text_zzz"}}` | Returns empty array | No matches |
| 9 | **Filter with unsupported keys** | `{"filter": {"color": "red"}}` | Schema strips unknown keys; behaves like empty filter | Extra keys |
| 10 | **Filter as non-object** | `{"filter": "Button"}` | Schema validation error — expected object | Type validation |

---

## 14. `click_button_by_text`

**Description:** Find and click a button by its text content.  
**Schema:**
- `text` (required) — `string` — Button text to find and click
- `timeout` (optional) — `number` (Timeout) — Timeout in seconds

**Handler:** `callGodot(bridge, 'runtime/click_button', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — click existing button** | `{"text": "Play"}` | Success; the "Play" button receives a click event | UI interaction |
| 2 | **Click button with timeout** | `{"text": "Continue", "timeout": 5.0}` | Waits up to 5s for button to appear, then clicks | Timed wait |
| 3 | **Button text not found** | `{"text": "NonExistentButton"}` | Error: button with text not found (after default timeout) | Error handling |
| 4 | **Empty text string** | `{"text": ""}` | May match empty-text buttons (rare) or error | Edge case |
| 5 | **Zero timeout** | `{"text": "Play", "timeout": 0}` | Immediate check: error if button not present | Boundary |
| 6 | **Negative timeout** | `{"text": "Play", "timeout": -1}` | Implementation-dependent; may error or treat as 0 | Edge case |
| 7 | **Very long timeout** | `{"text": "Play", "timeout": 300}` | Waits up to 300s | Large timeout value |
| 8 | **Missing required `text`** | `{}` | Schema validation error | Required param |
| 9 | **Case-sensitive text match** | `{"text": "play"}` vs `{"text": "Play"}` | Depends on implementation: may be case-sensitive | Case sensitivity |

---

## 15. `wait_for_node`

**Description:** Wait for a node to appear in the running game tree.  
**Schema:**
- `path` (required) — `string` (NodePath) — Node path to wait for
- `timeout` (optional) — `number` (Timeout), default 5.0 — Timeout in seconds

**Handler:** `callGodot(bridge, 'runtime/wait_for_node', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — node already exists** | `{"path": "Player"}` | Returns immediately with success | Node present |
| 2 | **Wait for dynamically spawned node** | `{"path": "Enemy1", "timeout": 10.0}` | Waits; returns success once Enemy1 spawns (within 10s) | Dynamic detection |
| 3 | **Node never appears (timeout)** | `{"path": "WillNeverExist", "timeout": 2.0}` | Error after 2s: node not found within timeout | Timeout handling |
| 4 | **Default timeout (5s)** | `{"path": "WillNeverExist"}` | Error after ~5s | Default timeout behavior |
| 5 | **Wait for root node** | `{"path": ""}` | Returns immediately (root always exists) | Edge case: root |
| 6 | **Zero timeout** | `{"path": "Player", "timeout": 0}` | Immediate check; returns success or error | Boundary |
| 7 | **Negative timeout** | `{"path": "Player", "timeout": -5}` | Implementation-dependent | Edge case |
| 8 | **Missing required `path`** | `{}` | Schema validation error | Required param |
| 9 | **Nested path** | `{"path": "UI/MainMenu/PlayButton", "timeout": 3.0}` | Waits for deeply nested node | Multi-level path |
| 10 | **String timeout** | `{"path": "Player", "timeout": "five"}` | Schema validation error — expected number | Type validation |

---

## 16. `find_nearby_nodes`

**Description:** Find nodes within a radius of a world position.  
**Schema:**
- `position` (required) — `[number, number, number]` (Position3D) — Position as [x, y, z]
- `radius` (required) — `number` (positive, >0) — Search radius

**Handler:** `callGodot(bridge, 'runtime/find_nearby', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — find nodes near origin** | `{"position": [0, 0, 0], "radius": 10.0}` | Returns array of nodes within 10 units of origin | Basic proximity search |
| 2 | **Large radius (finds many nodes)** | `{"position": [0, 0, 0], "radius": 10000.0}` | Returns all nodes in the scene | Large radius |
| 3 | **Tiny radius (finds no nodes)** | `{"position": [99999, 99999, 99999], "radius": 0.1}` | Returns empty array (unless a node is at that exact far position) | No nearby nodes |
| 4 | **Zero radius** | `{"position": [0, 0, 0], "radius": 0}` | Schema validation error — radius must be positive (>0) | PositiveNumber constraint |
| 5 | **Negative radius** | `{"position": [0, 0, 0], "radius": -5}` | Schema validation error — must be positive | PositiveNumber constraint |
| 6 | **Position with varying values** | `{"position": [-50.5, 25.3, 100.7], "radius": 5.0}` | Returns nodes near that world point | Floating-point coords |
| 7 | **Missing required `position`** | `{"radius": 10.0}` | Schema validation error | Required param |
| 8 | **Missing required `radius`** | `{"position": [0, 0, 0]}` | Schema validation error | Required param |
| 9 | **Position with wrong length (2 elements)** | `{"position": [0, 0], "radius": 10.0}` | Schema validation error — expected array of exactly 3 numbers | Array length validation |
| 10 | **Position with wrong length (4 elements)** | `{"position": [0, 0, 0, 0], "radius": 10.0}` | Schema validation error — expected array of exactly 3 numbers | Array length validation |
| 11 | **String in position** | `{"position": ["zero", 0, 0], "radius": 10.0}` | Schema validation error — expected number | Type validation |

---

## 17. `navigate_to`

**Description:** Navigate a node to a target position using pathfinding. Node must have NavigationAgent3D.  
**Schema:**
- `path` (required) — `string` (NodePath) — Node path to navigate (must have NavigationAgent3D)
- `target` (required) — `[number, number, number]` (Position3D) — Target position [x, y, z]

**Handler:** `callGodot(bridge, 'runtime/navigate_to', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — navigate agent to target** | `{"path": "NPC_Guard", "target": [10, 0, 5]}` | NPC begins pathfinding toward [10, 0, 5]; success returned | Requires NavigationAgent3D on NPC_Guard |
| 2 | **Navigate to far target** | `{"path": "NPC_Guard", "target": [500, 0, 500]}` | NPC pathfinds toward distant target | Long path |
| 3 | **Navigate to current position** | `{"path": "NPC_Guard", "target": [Same as current position]}` | NPC stays put or completes instantly | Same position |
| 4 | **Node without NavigationAgent3D** | `{"path": "Player", "target": [10, 0, 5]}` | Error: node does not have NavigationAgent3D | Precondition |
| 5 | **Non-existent node** | `{"path": "Ghost", "target": [10, 0, 5]}` | Error: node not found | Error handling |
| 6 | **Unreachable target** | `{"path": "NPC_Guard", "target": [99999, 0, 99999]}` | Navigation fails: target unreachable (no navmesh there) | Error handling |
| 7 | **Missing required `path`** | `{"target": [10, 0, 5]}` | Schema validation error | Required param |
| 8 | **Missing required `target`** | `{"path": "NPC_Guard"}` | Schema validation error | Required param |
| 9 | **Target with wrong element count** | `{"path": "NPC_Guard", "target": [10, 0]}` | Schema validation error — expected 3 numbers | Tuple length |
| 10 | **String target values** | `{"path": "NPC_Guard", "target": ["ten", 0, 5]}` | Schema validation error — expected number | Type validation |
| 11 | **Empty node path** | `{"path": "", "target": [10, 0, 5]}` | Error: root node unlikely to have NavigationAgent3D | Edge case |

---

## 18. `move_to`

**Description:** Directly move a node to a target position (teleport, no pathfinding).  
**Schema:**
- `path` (required) — `string` (NodePath) — Node path to move
- `target` (required) — `[number, number, number]` (Position3D) — Target position [x, y, z]

**Handler:** `callGodot(bridge, 'runtime/move_to', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — teleport to target** | `{"path": "Player", "target": [100, 0, 50]}` | Success; Player node position becomes [100, 0, 50] | Direct teleport |
| 2 | **Move to current position** | `{"path": "Player", "target": [0, 0, 0]}` | Success (no visible change if already there) | No-op move |
| 3 | **Negative coordinates** | `{"path": "Player", "target": [-50, -10, -200]}` | Success; Player moves to negative space | Negative coords |
| 4 | **Large coordinate values** | `{"path": "Player", "target": [1000000, 500000, -300000]}` | Success (if within engine float range) | Large values |
| 5 | **Floating-point precision** | `{"path": "Player", "target": [1.123456789, 2.987654321, 3.555555555]}` | Success; position set to precise float value | Float precision |
| 6 | **Non-existent node** | `{"path": "Ghost", "target": [0, 0, 0]}` | Error: node not found | Error handling |
| 7 | **Missing required `path`** | `{"target": [10, 0, 5]}` | Schema validation error | Required param |
| 8 | **Missing required `target`** | `{"path": "Player"}` | Schema validation error | Required param |
| 9 | **Target with 2 elements** | `{"path": "Player", "target": [10, 0]}` | Schema validation error — expected 3 numbers | Tuple length |
| 10 | **Target with 4 elements** | `{"path": "Player", "target": [10, 0, 5, 99]}` | Schema validation error — expected 3 numbers | Tuple length |
| 11 | **Empty path** | `{"path": "", "target": [10, 0, 5]}` | Moves scene root (may have side effects) | Edge case: root |

---

## 19. `watch_signals`

**Description:** Watch for signal emissions from a game node.  
**Schema:**
- `path` (required) — `string` (NodePath) — Node path to watch
- `signals` (required) — `string[]` — Signal names to watch for
- `duration` (optional) — `number` (Timeout) — How long to watch in seconds

**Handler:** `callGodot(bridge, 'runtime/watch_signals', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — watch single signal** | `{"path": "Player", "signals": ["body_entered"], "duration": 2.0}` | Watches for 2s; returns log of signal emissions (if any) | Basic signal watch |
| 2 | **Watch multiple signals** | `{"path": "Player", "signals": ["body_entered", "body_exited"], "duration": 3.0}` | Watches both signals for 3s | Multi-signal |
| 3 | **Signal that fires during watch period** | `{"path": "Timer", "signals": ["timeout"], "duration": 5.0}` | Returns log showing timeout signal emissions | Active signal |
| 4 | **No signal fires during watch** | `{"path": "Player", "signals": ["body_entered"], "duration": 1.0}` | Returns empty signal log | No emissions |
| 5 | **Default duration (no explicit duration)** | `{"path": "Player", "signals": ["body_entered"]}` | Watches for default duration (implementation-defined) | Default behavior |
| 6 | **Zero duration** | `{"path": "Player", "signals": ["body_entered"], "duration": 0}` | Returns immediately with empty log | Boundary |
| 7 | **Negative duration** | `{"path": "Player", "signals": ["body_entered"], "duration": -2}` | Implementation-dependent | Edge case |
| 8 | **Empty signals array** | `{"path": "Player", "signals": [], "duration": 2.0}` | Returns empty log (nothing to watch) | Edge case |
| 9 | **Non-existent node** | `{"path": "Ghost", "signals": ["body_entered"], "duration": 2.0}` | Error: node not found | Error handling |
| 10 | **Non-existent signal name** | `{"path": "Player", "signals": ["fake_signal"], "duration": 2.0}` | Error or empty log (signal doesn't exist on node) | Error handling |
| 11 | **Missing required `path`** | `{"signals": ["body_entered"]}` | Schema validation error | Required param |
| 12 | **Missing required `signals`** | `{"path": "Player"}` | Schema validation error | Required param |
| 13 | **Signals as non-array** | `{"path": "Player", "signals": "body_entered"}` | Schema validation error — expected array | Type validation |

---

## Cross-Cutting Concerns

These scenarios apply across multiple tools:

| Concern | Tools Affected | Test Strategy |
|---------|---------------|---------------|
| **Game not running** | All (1–19) | Verify every tool returns a clear error when game is not running, not a cryptic timeout |
| **Autoload missing** | All (1–19) | If `mcp_runtime.gd` autoload is not registered, all tools should fail with a descriptive error |
| **Concurrent calls** | 3, 4, 17, 18 | Test calling `move_to` and `set_game_node_property` simultaneously on different nodes — should not crash |
| **Large payloads** | 1, 2, 5, 12 | Test scene tree with 1000+ nodes; test `batch_get_properties` with 200 paths; test `capture_frames` with count=60 |
| **Rapid sequential calls** | 3, 5, 14 | Call `click_button_by_text` 10x rapidly; call `set_game_node_property` 50x on same node — check for race conditions |
| **Recording lifecycle** | 7, 8, 9 | Full cycle: start → interact (move_to, set properties) → stop → replay → verify replay matches original |

---

## Shared Type Definitions (from `shared-types.ts`)

| Type | Definition | Used By |
|------|-----------|---------|
| `NodePath` | `z.string()` — Node path in scene tree | 2, 3, 6, 15, 17, 18, 19 |
| `ScriptPath` | `z.string()` — Script file path (`res://...`) | 10 |
| `Position3D` | `z.array(z.number()).length(3)` — [x, y, z] | 16, 17, 18 |
| `PositiveNumber` | `z.number().positive()` — Number > 0 | 9, 16 |
| `Timeout` | `z.number().optional()` — Optional timeout in seconds | 6, 14, 15, 19 |
| `GDScriptCode` | `z.string()` — GDScript code string | 4 |
