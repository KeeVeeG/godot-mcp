# Runtime Tools — Test Plan

**Source file:** `server/src/tools/runtime.ts`
**Shared types:** `server/src/tools/shared-types.ts`
**Number of tools:** 19
**Generated:** 2026-07-08

> ⚠️ **Prerequisite:** All tools require the game to be running. Use `play_scene` to start the game before executing any runtime tool.

---

## Type Reference

| Zod schema | Underlying type | Description |
|---|---|---|
| `NodePath` | `z.string()` | Node path in game tree, e.g. `'Player/Sprite2D'`, `''` for root |
| `ScriptPath` | `z.string()` | Script file path, e.g. `'res://scripts/enemy.gd'` |
| `Position3D` | `z.tuple([z.number(), z.number(), z.number()])` | 3D position as `[x, y, z]` |
| `PositiveNumber` | `z.number().positive()` | Positive number (> 0) |
| `Timeout` | `z.number().optional()` | Timeout in seconds (optional) |
| `GDScriptCode` | `z.string()` | GDScript code string to execute |
| `z.unknown()` | any | Any value — not validated beyond presence |

---

## Tool: `get_game_scene_tree`

**Description:** 🔴 Game must be running. Get the scene tree of the running game (runtime state)
**Handler:** `callGodot(bridge, 'runtime/get_scene_tree')`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| *(none)* | — | — | — | No parameters |

### Test Scenarios

#### Scenario 1: Happy path — get scene tree while game is running
- **Description:** Retrieve the full runtime scene tree hierarchy
- **Params:** `{}`
- **Expected result:** Success. Returns a JSON representation of the game's scene tree with all nodes, their types, and parent-child relationships.
- **Notes:** Game must be actively running.

#### Scenario 2: Happy path — verify result contains root node
- **Description:** Confirm the returned tree has a root node
- **Params:** `{}`
- **Expected result:** Success. Result includes a root-level node (typically the main scene's root).
- **Notes:** Run immediately after the scene starts.

#### Scenario 3: Happy path — scene with nested nodes
- **Description:** Call on a scene that has a deep hierarchy of nodes (grandchildren)
- **Params:** `{}`
- **Expected result:** Success. The tree shows the full depth of nested nodes.
- **Notes:** Pre-setup: Create a scene with at least 3 levels of nesting (Root → Child → Grandchild).

#### Scenario 4: Edge — call when game is NOT running
- **Description:** Invoke the tool when the editor is stopped (game not running)
- **Params:** `{}`
- **Expected result:** Error from Godot. Either connection refused or a specific error about the game not running.
- **Notes:** The tool description warns "🔴 Game must be running".

#### Scenario 5: Edge — call during scene transition
- **Description:** Invoke while the game is in the process of changing scenes
- **Params:** `{}`
- **Expected result:** May return the old scene tree, the new one, or an error depending on timing.
- **Notes:** This tests race-condition handling. Use `change_scene_to_packed` or similar in GDScript just before calling.

---

## Tool: `get_game_node_properties`

**Description:** 🔴 Game must be running. Get all properties of a node in the running game
**Handler:** `callGodot(bridge, 'runtime/get_node_properties', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path in the game tree |
| `properties` | `z.array(z.string())` | No | — | Specific property names to return (defaults to common properties) |

### Test Scenarios

#### Scenario 1: Happy path — get default properties of a node
- **Description:** Retrieve properties of a node without specifying property names
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success. Returns a subset of the node's common properties (e.g., `position`, `rotation`, `visible`, `name`).
- **Notes:** Verifies the default behavior when `properties` is omitted.

#### Scenario 2: Happy path — get specific named properties
- **Description:** Retrieve only specified property names from a node
- **Params:** `{ "path": "Player", "properties": ["position", "name", "visible"] }`
- **Expected result:** Success. Returns only the three requested properties with their values.

#### Scenario 3: Happy path — get single property
- **Description:** Retrieve exactly one property
- **Params:** `{ "path": "Player", "properties": ["position"] }`
- **Expected result:** Success. Returns only the `position` property.

#### Scenario 4: Happy path — root node (empty path)
- **Description:** Get properties of the scene root node using empty string
- **Params:** `{ "path": "" }`
- **Expected result:** Success. Returns properties of the root node.

#### Scenario 5: Happy path — nested node path
- **Description:** Get properties of a deeply nested node
- **Params:** `{ "path": "Player/Sprites/Body", "properties": ["position", "scale"] }`
- **Expected result:** Success. Returns the requested properties from the nested node.

#### Scenario 6: Edge — node does not exist
- **Description:** Call with a path to a node that does not exist
- **Params:** `{ "path": "NonExistentNode" }`
- **Expected result:** Error from Godot (node not found in game tree).

#### Scenario 7: Edge — missing required `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 8: Edge — property name that does not exist
- **Description:** Request a property name that the node does not have
- **Params:** `{ "path": "Player", "properties": ["nonexistent_property_xyz"] }`
- **Expected result:** Behavior depends on Godot. May omit the property, return null, or return an error.

#### Scenario 9: Edge — empty properties array
- **Description:** Pass an empty array for `properties`
- **Params:** `{ "path": "Player", "properties": [] }`
- **Expected result:** May return no properties or fall back to default behavior. Test to verify.

#### Scenario 10: Edge — duplicate property names in array
- **Description:** Request the same property name twice
- **Params:** `{ "path": "Player", "properties": ["position", "position"] }`
- **Expected result:** Success. The property appears once (or twice, depending on implementation). Test to verify deduplication.

---

## Tool: `set_game_node_property`

**Description:** 🔴 Game must be running. Set a property on a node in the running game
**Handler:** `callGodot(bridge, 'runtime/set_node_property', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path in the game tree |
| `property` | `z.string()` | **Yes** | — | Property name to set |
| `value` | `z.unknown()` | **Yes** | — | New value for the property |

### Test Scenarios

#### Scenario 1: Happy path — set a position (Vector3/array)
- **Description:** Move a node to a new position
- **Params:** `{ "path": "Player", "property": "position", "value": [10.0, 0.0, 5.0] }`
- **Expected result:** Success. The node's position is updated to `(10, 0, 5)`.
- **Notes:** Verify with `get_game_node_properties` afterward to confirm the change.

#### Scenario 2: Happy path — set a boolean property
- **Description:** Toggle visibility of a node
- **Params:** `{ "path": "Player", "property": "visible", "value": false }`
- **Expected result:** Success. The node becomes invisible in the running game.

#### Scenario 3: Happy path — set a float property
- **Description:** Change a numeric property
- **Params:** `{ "path": "Player", "property": "speed", "value": 500.0 }`
- **Expected result:** Success. The `speed` property is updated.
- **Notes:** Only works if the node's script has a `speed` export variable.

#### Scenario 4: Happy path — set a string property
- **Description:** Change the node's name at runtime
- **Params:** `{ "path": "Player", "property": "name", "value": "PlayerRenamed" }`
- **Expected result:** Success. The node is renamed in the running game tree.

#### Scenario 5: Happy path — set a color (array)
- **Description:** Set a Color property using an array
- **Params:** `{ "path": "Sprite2D", "property": "modulate", "value": [1.0, 0.0, 0.0, 1.0] }`
- **Expected result:** Success. The sprite's modulate color changes to red.

#### Scenario 6: Happy path — set property on root node (empty path)
- **Description:** Set a property on the scene root
- **Params:** `{ "path": "", "property": "name", "value": "NewRootName" }`
- **Expected result:** Success. The root node's name changes.

#### Scenario 7: Edge — node does not exist
- **Description:** Set a property on a non-existent node
- **Params:** `{ "path": "NonExistentNode", "property": "position", "value": [0, 0, 0] }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 8: Edge — property does not exist
- **Description:** Set a property name that does not exist on the node
- **Params:** `{ "path": "Player", "property": "nonexistent_prop", "value": 123 }`
- **Expected result:** Error from Godot (property not found on object).

#### Scenario 9: Edge — missing required `path`
- **Description:** Call without the `path` parameter
- **Params:** `{ "property": "visible", "value": false }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 10: Edge — missing required `property`
- **Description:** Call without the `property` parameter
- **Params:** `{ "path": "Player", "value": false }`
- **Expected result:** Zod validation error (property is required).

#### Scenario 11: Edge — type mismatch
- **Description:** Set a numeric property to a string value
- **Params:** `{ "path": "Player", "property": "speed", "value": "not_a_number" }`
- **Expected result:** Zod passes (value is `z.unknown()`). Godot may coerce, error, or silently fail. Test to verify.

#### Scenario 12: Edge — set value to null
- **Description:** Set a property to null
- **Params:** `{ "path": "Player", "property": "position", "value": null }`
- **Expected result:** Since `value` is `z.unknown()`, null passes validation. Godot behavior depends on property type — may reset to default, error, or crash.

#### Scenario 13: Edge — set read-only property
- **Description:** Attempt to modify a read-only property
- **Params:** `{ "path": "Player", "property": "ready", "value": false }`
- **Expected result:** Error from Godot (property is read-only or cannot be set).

---

## Tool: `execute_game_script`

**Description:** 🔴 Game must be running. Execute a GDScript snippet in the running game context
**Handler:** `callGodot(bridge, 'runtime/execute_script', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `code` | `GDScriptCode` (`z.string()`) | **Yes** | — | GDScript code to execute |

### Test Scenarios

#### Scenario 1: Happy path — simple expression
- **Description:** Execute a simple GDScript expression that returns a value
- **Params:** `{ "code": "return 2 + 2" }`
- **Expected result:** Success. Returns `4`.

#### Scenario 2: Happy path — access node in game tree
- **Description:** Get a property from a node in the running game
- **Params:** `{ "code": "var player = get_node(\"/root/Main/Player\"); return player.position" }`
- **Expected result:** Success. Returns the player's current position.
- **Notes:** Adjust the node path to match the actual scene structure.

#### Scenario 3: Happy path — print to console
- **Description:** Execute a script that prints output
- **Params:** `{ "code": "print(\"Hello from runtime script!\"); return \"done\"" }`
- **Expected result:** Success. Returns `"done"`. The message appears in Godot's output console.

#### Scenario 4: Happy path — multi-line script
- **Description:** Execute a script with multiple statements
- **Params:** `{ "code": "var a = 10\nvar b = 20\nvar c = a + b\nprint(\"Sum: \", c)\nreturn c" }`
- **Expected result:** Success. Returns `30`. Console shows "Sum: 30".

#### Scenario 5: Happy path — create and manipulate an object
- **Description:** Instantiate a node and modify it
- **Params:** `{ "code": "var label = Label.new()\nlabel.text = \"Test\"\nreturn label.text" }`
- **Expected result:** Success. Returns `"Test"`.

#### Scenario 6: Edge — invalid GDScript syntax
- **Description:** Execute code with syntax errors
- **Params:** `{ "code": "var x = ;" }`
- **Expected result:** Error from Godot (syntax error, compilation failure).

#### Scenario 7: Edge — runtime error (division by zero)
- **Description:** Execute code that causes a runtime error
- **Params:** `{ "code": "var a = 1\nvar b = 0\nreturn a / b" }`
- **Expected result:** Error from Godot (division by zero runtime error).

#### Scenario 8: Edge — missing required `code`
- **Description:** Call without the required `code` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (code is required).

#### Scenario 9: Edge — empty code string
- **Description:** Execute an empty script
- **Params:** `{ "code": "" }`
- **Expected result:** May return null/void or produce a compilation error. Test to verify.

#### Scenario 10: Edge — very long script
- **Description:** Execute a script with thousands of lines (or maximum practical)
- **Params:** `{ "code": "var s = 0\nfor i in range(1000):\n    s += i\nreturn s" }`
- **Expected result:** Success. Returns `499500`. Tests execution of longer code within any timeout limits.

#### Scenario 11: Edge — script that accesses restricted areas
- **Description:** Execute code that tries to access restricted or internal objects
- **Params:** `{ "code": "return OS.get_cmdline_args()" }`
- **Expected result:** May succeed or error depending on runtime permissions. Test to verify sandboxing.

#### Scenario 12: Edge — infinite loop (should timeout)
- **Description:** Execute a script with an infinite loop
- **Params:** `{ "code": "while true:\n    pass" }`
- **Expected result:** The tool should timeout or Godot should kill the script. Not expected to hang indefinitely.

---

## Tool: `capture_frames`

**Description:** 🔴 Game must be running. Capture frames from the running game viewport as PNG files
**Handler:** `callGodot(bridge, 'runtime/capture_frames', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `count` | `z.number().int().min(1).max(60)` | No | `1` | Number of frames to capture (default: 1) |
| `interval` | `z.number()` | No | — | Interval between captures in seconds |

### Test Scenarios

#### Scenario 1: Happy path — capture a single frame (default)
- **Description:** Capture one frame using all defaults
- **Params:** `{}`
- **Expected result:** Success. Returns the path to one captured PNG screenshot file.

#### Scenario 2: Happy path — capture single frame explicitly
- **Description:** Explicitly request one frame
- **Params:** `{ "count": 1 }`
- **Expected result:** Success. Returns path to one PNG file. Same as default.

#### Scenario 3: Happy path — capture multiple frames
- **Description:** Capture 5 frames at default (instant) interval
- **Params:** `{ "count": 5 }`
- **Expected result:** Success. Returns paths to 5 PNG files.

#### Scenario 4: Happy path — capture with interval
- **Description:** Capture 3 frames with a 0.5-second interval
- **Params:** `{ "count": 3, "interval": 0.5 }`
- **Expected result:** Success. Returns paths to 3 PNG files, captured 0.5s apart. Total call duration ~1 second.

#### Scenario 5: Happy path — capture with longer interval
- **Description:** Capture 2 frames with a 2-second interval
- **Params:** `{ "count": 2, "interval": 2.0 }`
- **Expected result:** Success. Returns 2 PNG files captured 2 seconds apart.

#### Scenario 6: Happy path — max count (60)
- **Description:** Capture the maximum allowed number of frames
- **Params:** `{ "count": 60 }`
- **Expected result:** Success. Returns paths to 60 PNG files.
- **Notes:** May take significant time and storage space.

#### Scenario 7: Edge — count exceeds max (61+)
- **Description:** Request more than 60 frames
- **Params:** `{ "count": 61 }`
- **Expected result:** Zod validation error (count must be ≤ 60).

#### Scenario 8: Edge — count is zero
- **Description:** Request zero frames
- **Params:** `{ "count": 0 }`
- **Expected result:** Zod validation error (count must be ≥ 1).

#### Scenario 9: Edge — count is negative
- **Description:** Request a negative frame count
- **Params:** `{ "count": -5 }`
- **Expected result:** Zod validation error (count must be ≥ 1).

#### Scenario 10: Edge — count is float (not integer)
- **Description:** Request a non-integer count
- **Params:** `{ "count": 3.5 }`
- **Expected result:** Zod validation error (count must be an integer).

#### Scenario 11: Edge — interval is zero
- **Description:** Set interval to 0
- **Params:** `{ "count": 3, "interval": 0 }`
- **Expected result:** `z.number()` validation passes. Godot may handle zero interval gracefully or error.

#### Scenario 12: Edge — interval is negative
- **Description:** Set a negative interval
- **Params:** `{ "count": 3, "interval": -0.5 }`
- **Expected result:** `z.number()` validation passes. Godot likely errors or treats as instant.

#### Scenario 13: Edge — game not running
- **Description:** Call when the game is stopped
- **Params:** `{}`
- **Expected result:** Error from Godot (game must be running).

---

## Tool: `monitor_properties`

**Description:** 🔴 Game must be running. Monitor specific properties on a game node for changes over time
**Handler:** `callGodot(bridge, 'runtime/monitor_properties', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path to monitor |
| `properties` | `z.array(z.string())` | **Yes** | — | Property names to monitor |
| `duration` | `Timeout` (`z.number().optional()`) | No | — | Monitoring duration in seconds |

### Test Scenarios

#### Scenario 1: Happy path — monitor position over time
- **Description:** Watch a moving node's position for a few seconds
- **Params:** `{ "path": "Player", "properties": ["position"], "duration": 3 }`
- **Expected result:** Success. Returns a timeline of position values sampled over 3 seconds.

#### Scenario 2: Happy path — monitor multiple properties
- **Description:** Monitor position, rotation, and velocity simultaneously
- **Params:** `{ "path": "Player", "properties": ["position", "rotation", "velocity"], "duration": 2 }`
- **Expected result:** Success. Returns timeline data for all three properties.

#### Scenario 3: Happy path — monitor without explicit duration
- **Description:** Omit the duration parameter (use Godot default)
- **Params:** `{ "path": "Player", "properties": ["position"] }`
- **Expected result:** Success. Monitors for the default duration (Godot-determined) and returns timeline data.

#### Scenario 4: Happy path — short duration
- **Description:** Monitor for a very short time
- **Params:** `{ "path": "Player", "properties": ["visible"], "duration": 0.1 }`
- **Expected result:** Success. Returns at least one data point.

#### Scenario 5: Edge — node does not exist
- **Description:** Monitor a non-existent node
- **Params:** `{ "path": "NonExistentNode", "properties": ["position"], "duration": 2 }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 6: Edge — property does not exist
- **Description:** Monitor a property name that the node does not have
- **Params:** `{ "path": "Player", "properties": ["nonexistent_prop"], "duration": 1 }`
- **Expected result:** Error or empty timeline for that property. Test to verify.

#### Scenario 7: Edge — missing required `path`
- **Description:** Call without `path`
- **Params:** `{ "properties": ["position"], "duration": 2 }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 8: Edge — missing required `properties`
- **Description:** Call without `properties`
- **Params:** `{ "path": "Player", "duration": 2 }`
- **Expected result:** Zod validation error (properties is required).

#### Scenario 9: Edge — empty properties array
- **Description:** Monitor with an empty properties list
- **Params:** `{ "path": "Player", "properties": [], "duration": 2 }`
- **Expected result:** May return no data, error, or success with empty timeline. Test to verify.

#### Scenario 10: Edge — duration zero or negative
- **Description:** Set duration to 0 or a negative value
- **Params:** `{ "path": "Player", "properties": ["position"], "duration": 0 }`
- **Expected result:** `Timeout` is `z.number().optional()` with no positive constraint, so 0 passes Zod. Godot behavior varies — may instantly return one sample or error.

#### Scenario 11: Edge — long duration (e.g., 300 seconds)
- **Description:** Monitor for a very long time
- **Params:** `{ "path": "Player", "properties": ["position"], "duration": 300 }`
- **Expected result:** The tool may timeout on the MCP side before Godot finishes. Test to verify timeout handling.

---

## Tool: `start_recording`

**Description:** 🔴 Game must be running. Start recording game state changes
**Handler:** `callGodot(bridge, 'runtime/start_recording')`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| *(none)* | — | — | — | No parameters |

### Test Scenarios

#### Scenario 1: Happy path — start recording
- **Description:** Begin recording game state changes
- **Params:** `{}`
- **Expected result:** Success. Returns confirmation that recording has started.

#### Scenario 2: Happy path — start → wait → stop
- **Description:** Start recording, let the game run for a few seconds, then stop
- **Params:** (Sequence — see Integration section)
- **Expected result:** `start_recording` returns success; subsequent `stop_recording` returns recorded data.

#### Scenario 3: Edge — start recording twice without stopping
- **Description:** Call `start_recording` again while already recording
- **Params:** `{}` (after already calling `start_recording` once)
- **Expected result:** Behavior depends on implementation. May restart recording, return an error, or be a no-op.

#### Scenario 4: Edge — call when game is NOT running
- **Description:** Invoke the tool while the editor is stopped
- **Params:** `{}`
- **Expected result:** Error from Godot (game must be running).

---

## Tool: `stop_recording`

**Description:** 🔴 Game must be running. Stop recording and return the recorded game state data
**Handler:** `callGodot(bridge, 'runtime/stop_recording')`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| *(none)* | — | — | — | No parameters |

### Test Scenarios

#### Scenario 1: Happy path — stop after recording
- **Description:** Stop recording after a `start_recording` call and several seconds of gameplay
- **Params:** `{}`
- **Expected result:** Success. Returns the recorded game state data (positions, events, etc.) as serialized data.

#### Scenario 2: Edge — stop without starting
- **Description:** Call `stop_recording` without first calling `start_recording`
- **Params:** `{}`
- **Expected result:** Error from Godot (no recording in progress) or returns empty data.

#### Scenario 3: Edge — stop twice in a row
- **Description:** Call `stop_recording` twice without an intervening `start_recording`
- **Params:** `{}` (after already stopping)
- **Expected result:** Error from Godot (no active recording).

#### Scenario 4: Edge — call when game is NOT running
- **Description:** Invoke while editor is stopped
- **Params:** `{}`
- **Expected result:** Error from Godot (game must be running).

---

## Tool: `replay_recording`

**Description:** 🔴 Game must be running. Replay a previously recorded game session
**Handler:** `callGodot(bridge, 'runtime/replay_recording', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `speed` | `PositiveNumber` (`z.number().positive()`) | No | `1.0` | Playback speed multiplier (default: 1.0) |

### Test Scenarios

#### Scenario 1: Happy path — replay at default speed
- **Description:** Replay a recording at normal speed
- **Params:** `{}`
- **Expected result:** Success. The recorded session replays at 1.0× speed.
- **Notes:** Requires a recording to have been made first (via `record_gameplay` or `start_recording`/`stop_recording`).

#### Scenario 2: Happy path — replay at 2× speed
- **Description:** Replay a recording at double speed
- **Params:** `{ "speed": 2.0 }`
- **Expected result:** Success. The recording replays at 2.0× speed.

#### Scenario 3: Happy path — replay at slow motion (0.5×)
- **Description:** Replay a recording at half speed
- **Params:** `{ "speed": 0.5 }`
- **Expected result:** Success. The recording replays at 0.5× speed.

#### Scenario 4: Happy path — replay at 10× speed
- **Description:** Replay a recording very fast
- **Params:** `{ "speed": 10.0 }`
- **Expected result:** Success. The recording replays at 10× speed.

#### Scenario 5: Edge — speed is zero
- **Description:** Replay at 0× speed (paused)
- **Params:** `{ "speed": 0 }`
- **Expected result:** Zod validation error (speed must be positive).

#### Scenario 6: Edge — speed is negative
- **Description:** Replay at negative speed (reverse)
- **Params:** `{ "speed": -1.0 }`
- **Expected result:** Zod validation error (speed must be positive).

#### Scenario 7: Edge — speed is non-numeric
- **Description:** Pass a string for speed
- **Params:** `{ "speed": "fast" }`
- **Expected result:** Zod validation error (speed must be a number).

#### Scenario 8: Edge — no recording available
- **Description:** Call replay without any prior recording
- **Params:** `{}`
- **Expected result:** Error from Godot (no recording data available to replay).

#### Scenario 9: Edge — call when game is NOT running
- **Description:** Invoke while editor is stopped
- **Params:** `{}`
- **Expected result:** Error from Godot (game must be running).

---

## Tool: `find_nodes_by_script`

**Description:** 🔴 Game must be running. Find all nodes in the game that use a specific script
**Handler:** `callGodot(bridge, 'runtime/find_by_script', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `script_path` | `ScriptPath` (`z.string()`) | **Yes** | — | Script file path to search for (e.g. `'res://scripts/enemy.gd'`) |

### Test Scenarios

#### Scenario 1: Happy path — find nodes using a known script
- **Description:** Search for all nodes that have a specific script attached
- **Params:** `{ "script_path": "res://scripts/player.gd" }`
- **Expected result:** Success. Returns an array of node paths that use the `player.gd` script.
- **Notes:** Requires at least one node in the scene to have `player.gd` attached.

#### Scenario 2: Happy path — script used by multiple nodes
- **Description:** Search for a script used by many nodes (e.g., enemy.gd on multiple enemies)
- **Params:** `{ "script_path": "res://scripts/enemy.gd" }`
- **Expected result:** Success. Returns all node paths where this script is attached.

#### Scenario 3: Happy path — script used by zero nodes
- **Description:** Search for a script that exists but is not attached to any node
- **Params:** `{ "script_path": "res://scripts/unused.gd" }`
- **Expected result:** Success. Returns an empty array (not an error).

#### Scenario 4: Edge — script file does not exist
- **Description:** Search for a script path that does not exist in the project
- **Params:** `{ "script_path": "res://scripts/nonexistent.gd" }`
- **Expected result:** Error from Godot (script file not found) or returns empty result.

#### Scenario 5: Edge — missing required `script_path`
- **Description:** Call without the `script_path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (script_path is required).

#### Scenario 6: Edge — empty script_path
- **Description:** Pass an empty string as the script path
- **Params:** `{ "script_path": "" }`
- **Expected result:** Error from Godot or empty result. Test to verify.

#### Scenario 7: Edge — non-GDScript file path
- **Description:** Pass a path to a non-script file (e.g., a scene or shader)
- **Params:** `{ "script_path": "res://scenes/main.tscn" }`
- **Expected result:** Error from Godot or empty result (not a valid script resource).

#### Scenario 8: Edge — path without `res://` prefix
- **Description:** Pass a relative or absolute file system path
- **Params:** `{ "script_path": "scripts/player.gd" }`
- **Expected result:** Error from Godot or unexpected behavior. Test to verify path validation.

#### Scenario 9: Edge — call when game is NOT running
- **Description:** Invoke while editor is stopped
- **Params:** `{ "script_path": "res://scripts/player.gd" }`
- **Expected result:** Error from Godot (game must be running).

---

## Tool: `get_autoload`

**Description:** 🔴 Game must be running. Get properties of an autoload singleton from the running game
**Handler:** `callGodot(bridge, 'runtime/get_autoload', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | `z.string()` | **Yes** | — | Autoload singleton name |

### Test Scenarios

#### Scenario 1: Happy path — get a known autoload's properties
- **Description:** Retrieve properties from a registered autoload singleton
- **Params:** `{ "name": "GameManager" }`
- **Expected result:** Success. Returns properties of the `GameManager` autoload.
- **Notes:** Requires an autoload named `GameManager` to exist.

#### Scenario 2: Happy path — get the MCP runtime autoload
- **Description:** Retrieve properties from the built-in `mcp_runtime` autoload
- **Params:** `{ "name": "mcp_runtime" }`
- **Expected result:** Success. Returns properties of the MCP runtime singleton.

#### Scenario 3: Edge — autoload name does not exist
- **Description:** Query an autoload name that is not registered
- **Params:** `{ "name": "NonExistentAutoload" }`
- **Expected result:** Error from Godot (autoload not found).

#### Scenario 4: Edge — missing required `name`
- **Description:** Call without the `name` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (name is required).

#### Scenario 5: Edge — empty name string
- **Description:** Pass an empty string as the autoload name
- **Params:** `{ "name": "" }`
- **Expected result:** Error from Godot (invalid autoload name).

#### Scenario 6: Edge — case sensitivity
- **Description:** Query an autoload with incorrect case
- **Params:** `{ "name": "gamemanager" }` (assuming actual autoload is `GameManager`)
- **Expected result:** Error from Godot (autoload not found — names are case-sensitive).

#### Scenario 7: Edge — call when game is NOT running
- **Description:** Invoke while editor is stopped
- **Params:** `{ "name": "GameManager" }`
- **Expected result:** Error from Godot (game must be running).

---

## Tool: `batch_get_properties`

**Description:** 🔴 Game must be running. Get multiple properties from multiple nodes in one call
**Handler:** `callGodot(bridge, 'runtime/batch_get_properties', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `paths` | `z.array(z.string())` | **Yes** | — | List of node paths to query |
| `properties` | `z.array(z.string())` | **Yes** | — | Property names to read from each node |

### Test Scenarios

#### Scenario 1: Happy path — get same properties from multiple nodes
- **Description:** Query `position` from several nodes at once
- **Params:** `{ "paths": ["Player", "Enemy1", "Enemy2"], "properties": ["position"] }`
- **Expected result:** Success. Returns position for each of the three nodes.

#### Scenario 2: Happy path — get multiple properties from one node
- **Description:** Query multiple properties from a single node
- **Params:** `{ "paths": ["Player"], "properties": ["position", "rotation", "visible", "name"] }`
- **Expected result:** Success. Returns all four properties for the Player node.

#### Scenario 3: Happy path — get different properties from multiple nodes
- **Description:** Query position from some nodes, speed from others (all nodes get same property set)
- **Params:** `{ "paths": ["Player", "Camera3D"], "properties": ["position", "name"] }`
- **Expected result:** Success. Returns position and name for both nodes.

#### Scenario 4: Happy path — large batch
- **Description:** Query many nodes and many properties in one call
- **Params:** `{ "paths": ["Player", "Enemy1", "Enemy2", "Enemy3", "Camera3D"], "properties": ["position", "rotation", "scale", "visible", "name"] }`
- **Expected result:** Success. Returns all requested data. Tests performance and any payload size limits.

#### Scenario 5: Edge — one node path does not exist
- **Description:** Include a non-existent node in the paths array
- **Params:** `{ "paths": ["Player", "NonExistentNode"], "properties": ["position"] }`
- **Expected result:** Depends on implementation. May return an error for the missing node, skip it, or fail the entire batch.

#### Scenario 6: Edge — one property name does not exist
- **Description:** Include a non-existent property in the properties array
- **Params:** `{ "paths": ["Player"], "properties": ["position", "nonexistent_prop"] }`
- **Expected result:** May omit the invalid property, return null, or error. Test to verify.

#### Scenario 7: Edge — missing required `paths`
- **Description:** Call without the `paths` parameter
- **Params:** `{ "properties": ["position"] }`
- **Expected result:** Zod validation error (paths is required).

#### Scenario 8: Edge — missing required `properties`
- **Description:** Call without the `properties` parameter
- **Params:** `{ "paths": ["Player"] }`
- **Expected result:** Zod validation error (properties is required).

#### Scenario 9: Edge — empty paths array
- **Description:** Pass an empty array for paths
- **Params:** `{ "paths": [], "properties": ["position"] }`
- **Expected result:** Zod passes (array with 0 items is valid). Should return empty results or an error.

#### Scenario 10: Edge — empty properties array
- **Description:** Pass an empty array for properties
- **Params:** `{ "paths": ["Player"], "properties": [] }`
- **Expected result:** May return nodes with no property data. Test to verify.

#### Scenario 11: Edge — duplicate paths
- **Description:** Include the same node path twice
- **Params:** `{ "paths": ["Player", "Player"], "properties": ["position"] }`
- **Expected result:** May return duplicate entries or deduplicate. Test to verify.

---

## Tool: `find_ui_elements`

**Description:** 🔴 Game must be running. Find UI elements in the running game by type, text, or name
**Handler:** `callGodot(bridge, 'runtime/find_ui_elements', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `filter` | `z.object({ type?, text? })` | No | — | Filter criteria for UI element search |
| `filter.type` | `z.string()` | No | — | Control type to filter by (e.g. `'Button'`, `'Label'`) |
| `filter.text` | `z.string()` | No | — | Text content to search for |

### Test Scenarios

#### Scenario 1: Happy path — find all UI elements (no filter)
- **Description:** List all UI elements in the running game
- **Params:** `{}`
- **Expected result:** Success. Returns an array of all UI Control nodes with their types and properties.

#### Scenario 2: Happy path — find all UI elements (empty filter object)
- **Description:** Pass an empty filter object
- **Params:** `{ "filter": {} }`
- **Expected result:** Success. Returns all UI elements (same as no filter).

#### Scenario 3: Happy path — filter by type: Button
- **Description:** Find only Button controls
- **Params:** `{ "filter": { "type": "Button" } }`
- **Expected result:** Success. Returns only nodes of type `Button` (and its subtypes).

#### Scenario 4: Happy path — filter by type: Label
- **Description:** Find only Label controls
- **Params:** `{ "filter": { "type": "Label" } }`
- **Expected result:** Success. Returns only nodes of type `Label`.

#### Scenario 5: Happy path — filter by type: Panel
- **Description:** Find only Panel controls
- **Params:** `{ "filter": { "type": "Panel" } }`
- **Expected result:** Success. Returns only nodes of type `Panel`.

#### Scenario 6: Happy path — filter by type: LineEdit
- **Description:** Find only LineEdit controls
- **Params:** `{ "filter": { "type": "LineEdit" } }`
- **Expected result:** Success. Returns only nodes of type `LineEdit`.

#### Scenario 7: Happy path — filter by text content
- **Description:** Find UI elements whose text contains a specific string
- **Params:** `{ "filter": { "text": "Start" } }`
- **Expected result:** Success. Returns UI elements whose text property contains "Start".

#### Scenario 8: Happy path — filter by both type AND text
- **Description:** Find only Buttons with the text "Start"
- **Params:** `{ "filter": { "type": "Button", "text": "Start" } }`
- **Expected result:** Success. Returns only Button nodes whose text is "Start".

#### Scenario 9: Happy path — filter by text, partial match
- **Description:** Find UI elements with partial text match
- **Params:** `{ "filter": { "text": "Play" } }`
- **Expected result:** Success. Returns elements containing "Play" (e.g., "Play Game", "Play Again").

#### Scenario 10: Edge — filter type that does not exist
- **Description:** Search for a Control type that is not in the scene
- **Params:** `{ "filter": { "type": "NonExistentControl" } }`
- **Expected result:** Success. Returns an empty array (not an error).

#### Scenario 11: Edge — filter text that matches nothing
- **Description:** Search for text that does not appear on any UI element
- **Params:** `{ "filter": { "text": "zzz_xyz_nonexistent_text" } }`
- **Expected result:** Success. Returns an empty array.

#### Scenario 12: Edge — filter.type is empty string
- **Description:** Pass an empty string for the type filter
- **Params:** `{ "filter": { "type": "" } }`
- **Expected result:** May match all types, match nothing, or error. Test to verify.

#### Scenario 13: Edge — filter.text is empty string
- **Description:** Pass an empty string for the text filter
- **Params:** `{ "filter": { "text": "" } }`
- **Expected result:** May match all elements (empty string is a substring of everything), match nothing, or error. Test to verify.

#### Scenario 14: Edge — deeply nested UI in containers
- **Description:** Find elements inside nested containers (VBoxContainer > HBoxContainer > Button)
- **Params:** `{ "filter": { "type": "Button" } }`
- **Expected result:** Success. Should find buttons regardless of nesting depth.

#### Scenario 15: Edge — call when game is NOT running
- **Description:** Invoke while editor is stopped
- **Params:** `{}`
- **Expected result:** Error from Godot (game must be running).

---

## Tool: `click_button_by_text`

**Description:** 🔴 Game must be running. Find and click a button by its text content
**Handler:** `callGodot(bridge, 'runtime/click_button', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `text` | `z.string()` | **Yes** | — | Button text to find and click |
| `timeout` | `Timeout` (`z.number().optional()`) | No | — | Timeout in seconds |

### Test Scenarios

#### Scenario 1: Happy path — click existing button by exact text
- **Description:** Find and click a button with known text
- **Params:** `{ "text": "Start Game" }`
- **Expected result:** Success. The "Start Game" button is found and clicked. The button's `pressed` signal fires.
- **Notes:** Requires a scene with a Button whose text is exactly "Start Game".

#### Scenario 2: Happy path — click button with special characters
- **Description:** Click a button whose text includes special characters
- **Params:** `{ "text": "Save & Exit" }`
- **Expected result:** Success. The button is found and clicked.

#### Scenario 3: Happy path — click with explicit timeout
- **Description:** Click a button that may take time to appear
- **Params:** `{ "text": "Load", "timeout": 10 }`
- **Expected result:** Success. The tool waits up to 10 seconds for the button to appear, then clicks it.

#### Scenario 4: Edge — button text not found
- **Description:** Search for button text that does not exist
- **Params:** `{ "text": "NonExistentButtonText_XYZ" }`
- **Expected result:** Error from Godot (button with specified text not found).

#### Scenario 5: Edge — missing required `text`
- **Description:** Call without the `text` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (text is required).

#### Scenario 6: Edge — empty text string
- **Description:** Pass an empty string for button text
- **Params:** `{ "text": "" }`
- **Expected result:** May match a button with empty text, or fail to find. Test to verify.

#### Scenario 7: Edge — multiple buttons with same text
- **Description:** Click when multiple buttons share the same text
- **Params:** `{ "text": "OK" }` (assuming multiple "OK" buttons exist)
- **Expected result:** May click the first match, all matches, or error. Test to verify.

#### Scenario 8: Edge — button is disabled/invisible
- **Description:** Attempt to click a button that is not visible or disabled
- **Params:** `{ "text": "Hidden Button" }`
- **Expected result:** May still find and click it, or fail. Test to verify behavior with hidden/disabled buttons.

#### Scenario 9: Edge — timeout triggers before button appears
- **Description:** Set a very short timeout such that the button may not be found in time
- **Params:** `{ "text": "Delayed Button", "timeout": 0.1 }`
- **Expected result:** If the button takes longer than 0.1s to appear, the tool should timeout and return an error.

#### Scenario 10: Edge — timeout is zero
- **Description:** Set timeout to 0
- **Params:** `{ "text": "Start", "timeout": 0 }`
- **Expected result:** Zod passes (optional number, no positive constraint). Godot may instantly fail if button not found, or error.

#### Scenario 11: Edge — timeout is negative
- **Description:** Set a negative timeout
- **Params:** `{ "text": "Start", "timeout": -5 }`
- **Expected result:** Zod passes (optional number). Godot likely errors or ignores.

#### Scenario 12: Edge — call when game is NOT running
- **Description:** Invoke while editor is stopped
- **Params:** `{ "text": "Start" }`
- **Expected result:** Error from Godot (game must be running).

---

## Tool: `wait_for_node`

**Description:** 🔴 Game must be running. Wait for a node to appear in the running game tree
**Handler:** `callGodot(bridge, 'runtime/wait_for_node', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path to wait for |
| `timeout` | `Timeout` with `.default(5.0)` | No | `5.0` | Timeout in seconds (default: 5.0) |

### Test Scenarios

#### Scenario 1: Happy path — node already exists
- **Description:** Wait for a node that is already in the tree
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success. Returns immediately since the node exists.

#### Scenario 2: Happy path — node appears after short delay
- **Description:** Wait for a node that is spawned after ~1 second
- **Params:** `{ "path": "SpawnedEnemy", "timeout": 10 }`
- **Expected result:** Success. Returns after the node appears.
- **Notes:** Requires a scene that spawns a node named `SpawnedEnemy` after a delay.

#### Scenario 3: Happy path — default timeout (5 seconds)
- **Description:** Wait with the implicit default timeout of 5 seconds
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success. Uses the default 5-second timeout.

#### Scenario 4: Edge — node never appears (timeout)
- **Description:** Wait for a node that never spawns
- **Params:** `{ "path": "NeverSpawned", "timeout": 2 }`
- **Expected result:** Error from Godot after 2 seconds (node did not appear within timeout).

#### Scenario 5: Edge — missing required `path`
- **Description:** Call without `path`
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 6: Edge — empty path string
- **Description:** Wait for a node with empty string as path
- **Params:** `{ "path": "" }`
- **Expected result:** May match the scene root instantly, or error on invalid path.

#### Scenario 7: Edge — very short timeout
- **Description:** Set timeout to a tiny value
- **Params:** `{ "path": "SlowNode", "timeout": 0.001 }`
- **Expected result:** Almost certainly times out, even if the node would appear soon. Returns timeout error quickly.

#### Scenario 8: Edge — timeout is zero
- **Description:** Set timeout to 0
- **Params:** `{ "path": "Player", "timeout": 0 }`
- **Expected result:** Since Zod doesn't enforce positive, 0 passes. May instantly timeout or fail.

#### Scenario 9: Edge — call when game is NOT running
- **Description:** Invoke while editor is stopped
- **Params:** `{ "path": "Player" }`
- **Expected result:** Error from Godot (game must be running).

---

## Tool: `find_nearby_nodes`

**Description:** 🔴 Game must be running. Find nodes within a radius of a world position
**Handler:** `callGodot(bridge, 'runtime/find_nearby', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `position` | `Position3D` (`z.tuple([number, number, number])`) | **Yes** | — | Position as `[x, y, z]` |
| `radius` | `PositiveNumber` (`z.number().positive()`) | **Yes** | — | Search radius |

### Test Scenarios

#### Scenario 1: Happy path — find nodes near origin
- **Description:** Find all nodes within a radius of position (0, 0, 0)
- **Params:** `{ "position": [0, 0, 0], "radius": 50 }`
- **Expected result:** Success. Returns nodes whose world position is within 50 units of the origin.

#### Scenario 2: Happy path — find nodes near a specific position
- **Description:** Find nodes near a known position (e.g., where the Player is)
- **Params:** `{ "position": [10.5, 0, -5.2], "radius": 10 }`
- **Expected result:** Success. Returns nodes within 10 units of (10.5, 0, -5.2).

#### Scenario 3: Happy path — radius large enough to include all nodes
- **Description:** Use a very large radius to capture all nodes
- **Params:** `{ "position": [0, 0, 0], "radius": 10000 }`
- **Expected result:** Success. Returns all nodes in the scene (or at least all with a world position).

#### Scenario 4: Happy path — radius so small nothing matches
- **Description:** Use a tiny radius that matches no nodes
- **Params:** `{ "position": [0, 0, 0], "radius": 0.001 }`
- **Expected result:** Success. Returns an empty array (no nodes within such a tiny radius).

#### Scenario 5: Edge — position with large coordinate values
- **Description:** Search at a very distant position
- **Params:** `{ "position": [999999, 999999, 999999], "radius": 10 }`
- **Expected result:** Success. Returns empty array (no nodes at that distant location).

#### Scenario 6: Edge — position with negative coordinates
- **Description:** Search at a negative position
- **Params:** `{ "position": [-100, -50, -200], "radius": 30 }`
- **Expected result:** Success. Returns nodes near that negative position.

#### Scenario 7: Edge — missing required `position`
- **Description:** Call without `position`
- **Params:** `{ "radius": 10 }`
- **Expected result:** Zod validation error (position is required).

#### Scenario 8: Edge — missing required `radius`
- **Description:** Call without `radius`
- **Params:** `{ "position": [0, 0, 0] }`
- **Expected result:** Zod validation error (radius is required).

#### Scenario 9: Edge — position with wrong number of elements (2D)
- **Description:** Pass a 2-element tuple instead of 3
- **Params:** `{ "position": [0, 0], "radius": 10 }`
- **Expected result:** Zod validation error (Position3D requires exactly 3 numbers: `[x, y, z]`).

#### Scenario 10: Edge — position with wrong number of elements (4D)
- **Description:** Pass a 4-element tuple
- **Params:** `{ "position": [0, 0, 0, 0], "radius": 10 }`
- **Expected result:** Zod validation error (Position3D requires exactly 3 numbers).

#### Scenario 11: Edge — position elements are not numbers
- **Description:** Pass strings in the position array
- **Params:** `{ "position": ["x", "y", "z"], "radius": 10 }`
- **Expected result:** Zod validation error (position elements must be numbers).

#### Scenario 12: Edge — radius is zero
- **Description:** Set radius to 0
- **Params:** `{ "position": [0, 0, 0], "radius": 0 }`
- **Expected result:** Zod validation error (radius must be positive).

#### Scenario 13: Edge — radius is negative
- **Description:** Set a negative radius
- **Params:** `{ "position": [0, 0, 0], "radius": -10 }`
- **Expected result:** Zod validation error (radius must be positive).

#### Scenario 14: Edge — radius is non-numeric
- **Description:** Pass a string for radius
- **Params:** `{ "position": [0, 0, 0], "radius": "large" }`
- **Expected result:** Zod validation error (radius must be a number).

#### Scenario 15: Edge — call when game is NOT running
- **Description:** Invoke while editor is stopped
- **Params:** `{ "position": [0, 0, 0], "radius": 10 }`
- **Expected result:** Error from Godot (game must be running).

---

## Tool: `navigate_to`

**Description:** 🔴 Game must be running. Navigate a node to a target position using pathfinding
**Handler:** `callGodot(bridge, 'runtime/navigate_to', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path to navigate (must have NavigationAgent3D) |
| `target` | `Position3D` (`z.tuple([number, number, number])`) | **Yes** | — | Target position `[x, y, z]` |

### Test Scenarios

#### Scenario 1: Happy path — navigate to a reachable target
- **Description:** Use pathfinding to move a node to a reachable location
- **Params:** `{ "path": "Player", "target": [20, 0, 15] }`
- **Expected result:** Success. The node begins pathfinding toward the target.
- **Notes:** Requires the node to have a `NavigationAgent3D` child and a baked navigation mesh in the scene.

#### Scenario 2: Happy path — navigate a short distance
- **Description:** Navigate to a nearby position
- **Params:** `{ "path": "Player", "target": [1, 0, 0] }`
- **Expected result:** Success. The node moves to the nearby target.

#### Scenario 3: Happy path — navigate to a far target
- **Description:** Navigate to a distant position requiring a long path
- **Params:** `{ "path": "Player", "target": [500, 0, 500] }`
- **Expected result:** Success. The node begins pathfinding; the path may be long but the call itself returns quickly (asynchronous navigation).

#### Scenario 4: Edge — node has no NavigationAgent3D
- **Description:** Attempt to navigate a node without a navigation agent
- **Params:** `{ "path": "Camera3D", "target": [10, 0, 10] }`
- **Expected result:** Error from Godot (node does not have a NavigationAgent3D).

#### Scenario 5: Edge — target is unreachable (no navmesh coverage)
- **Description:** Navigate to a position outside the navigation mesh
- **Params:** `{ "path": "Player", "target": [999, 0, 999] }`
- **Expected result:** May still succeed (call returns immediately) but the agent will fail to find a path at runtime. Test to verify error reporting.

#### Scenario 6: Edge — node does not exist
- **Description:** Navigate a non-existent node
- **Params:** `{ "path": "NonExistentNode", "target": [0, 0, 0] }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 7: Edge — missing required `path`
- **Description:** Call without `path`
- **Params:** `{ "target": [10, 0, 10] }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 8: Edge — missing required `target`
- **Description:** Call without `target`
- **Params:** `{ "path": "Player" }`
- **Expected result:** Zod validation error (target is required).

#### Scenario 9: Edge — target with wrong number of elements
- **Description:** Pass a 2-element target (should be 3 for Position3D)
- **Params:** `{ "path": "Player", "target": [10, 20] }`
- **Expected result:** Zod validation error (Position3D requires exactly 3 numbers).

#### Scenario 10: Edge — target elements are not numbers
- **Description:** Pass strings in the target array
- **Params:** `{ "path": "Player", "target": ["x", "y", "z"] }`
- **Expected result:** Zod validation error (target elements must be numbers).

#### Scenario 11: Edge — call when game is NOT running
- **Description:** Invoke while editor is stopped
- **Params:** `{ "path": "Player", "target": [0, 0, 0] }`
- **Expected result:** Error from Godot (game must be running).

---

## Tool: `move_to`

**Description:** 🔴 Game must be running. Directly move a node to a target position
**Handler:** `callGodot(bridge, 'runtime/move_to', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path to move |
| `target` | `Position3D` (`z.tuple([number, number, number])`) | **Yes** | — | Target position `[x, y, z]` |

### Test Scenarios

#### Scenario 1: Happy path — teleport a node to a new position
- **Description:** Instantly move a node by setting its position directly
- **Params:** `{ "path": "Player", "target": [50, 0, 30] }`
- **Expected result:** Success. The node is teleported to `(50, 0, 30)` immediately.
- **Notes:** Verify with `get_game_node_properties` afterward.

#### Scenario 2: Happy path — move to origin
- **Description:** Move a node back to the origin
- **Params:** `{ "path": "Player", "target": [0, 0, 0] }`
- **Expected result:** Success. Node's position is set to `(0, 0, 0)`.

#### Scenario 3: Happy path — move to negative coordinates
- **Description:** Move a node to negative space
- **Params:** `{ "path": "Player", "target": [-100, -50, -200] }`
- **Expected result:** Success. Node moves to the negative coordinates.

#### Scenario 4: Happy path — move to same position (no-op)
- **Description:** Move a node to its current position
- **Params:** `{ "path": "Player", "target": [50, 0, 30] }` (assuming Player is already at this position)
- **Expected result:** Success. No visible change; position is set to the same value.

#### Scenario 5: Edge — node does not exist
- **Description:** Move a non-existent node
- **Params:** `{ "path": "NonExistentNode", "target": [0, 0, 0] }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 6: Edge — missing required `path`
- **Description:** Call without `path`
- **Params:** `{ "target": [10, 0, 10] }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 7: Edge — missing required `target`
- **Description:** Call without `target`
- **Params:** `{ "path": "Player" }`
- **Expected result:** Zod validation error (target is required).

#### Scenario 8: Edge — target with 2 elements (Position3D expects 3)
- **Description:** Pass a 2D coordinate to a 3D tool
- **Params:** `{ "path": "Player", "target": [10, 20] }`
- **Expected result:** Zod validation error (Position3D requires exactly 3 numbers).

#### Scenario 9: Edge — target with non-numeric values
- **Description:** Pass strings in the target array
- **Params:** `{ "path": "Player", "target": ["a", "b", "c"] }`
- **Expected result:** Zod validation error (target elements must be numbers).

#### Scenario 10: Edge — call when game is NOT running
- **Description:** Invoke while editor is stopped
- **Params:** `{ "path": "Player", "target": [0, 0, 0] }`
- **Expected result:** Error from Godot (game must be running).

#### Scenario 11: Edge — move a static body
- **Description:** Attempt to move a node with a StaticBody3D (which shouldn't move)
- **Params:** `{ "path": "StaticBody3D", "target": [100, 0, 100] }`
- **Expected result:** The position may still be updated (since this is a direct position set, not physics). Test to verify if physics bodies resist the position change.

---

## Tool: `watch_signals`

**Description:** 🔴 Game must be running. Watch for signal emissions from a game node
**Handler:** `callGodot(bridge, 'runtime/watch_signals', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path to watch |
| `signals` | `z.array(z.string())` | **Yes** | — | Signal names to watch for |
| `duration` | `Timeout` (`z.number().optional()`) | No | — | How long to watch in seconds |

### Test Scenarios

#### Scenario 1: Happy path — watch a signal that fires once
- **Description:** Watch for a single signal emission
- **Params:** `{ "path": "Player", "signals": ["ready"], "duration": 3 }`
- **Expected result:** Success. Returns a log of the `ready` signal emission with timestamp and arguments (if any).
- **Notes:** The `ready` signal fires when the node enters the tree.

#### Scenario 2: Happy path — watch a signal that fires multiple times
- **Description:** Watch for repeated signal emissions
- **Params:** `{ "path": "Timer", "signals": ["timeout"], "duration": 5 }`
- **Expected result:** Success. Returns a log with multiple `timeout` signal emissions.
- **Notes:** Requires a Timer node that fires repeatedly.

#### Scenario 3: Happy path — watch multiple signals simultaneously
- **Description:** Watch for several different signals from the same node
- **Params:** `{ "path": "Player", "signals": ["body_entered", "body_exited", "area_entered"], "duration": 5 }`
- **Expected result:** Success. Returns a log containing emissions of any of the three watched signals.

#### Scenario 4: Happy path — signal never fires during duration
- **Description:** Watch a signal that does not trigger during the watch period
- **Params:** `{ "path": "Player", "signals": ["tree_exited"], "duration": 2 }`
- **Expected result:** Success. Returns an empty log (or log indicating no emissions).
- **Notes:** `tree_exited` won't fire unless the node is removed from the tree during the watch period.

#### Scenario 5: Happy path — without explicit duration
- **Description:** Omit the duration parameter
- **Params:** `{ "path": "Player", "signals": ["ready"] }`
- **Expected result:** Success. Watches for the default duration (Godot-determined) and returns the log.

#### Scenario 6: Edge — node does not exist
- **Description:** Watch signals on a non-existent node
- **Params:** `{ "path": "NonExistentNode", "signals": ["ready"], "duration": 2 }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 7: Edge — signal name does not exist on node
- **Description:** Watch a signal that the node type does not have
- **Params:** `{ "path": "Player", "signals": ["nonexistent_signal"], "duration": 2 }`
- **Expected result:** Error from Godot or empty log. Test to verify if Godot rejects unknown signal names.

#### Scenario 8: Edge — missing required `path`
- **Description:** Call without `path`
- **Params:** `{ "signals": ["ready"], "duration": 2 }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 9: Edge — missing required `signals`
- **Description:** Call without `signals`
- **Params:** `{ "path": "Player", "duration": 2 }`
- **Expected result:** Zod validation error (signals is required).

#### Scenario 10: Edge — empty signals array
- **Description:** Watch with an empty array of signal names
- **Params:** `{ "path": "Player", "signals": [], "duration": 2 }`
- **Expected result:** May return empty log immediately, or error. Test to verify.

#### Scenario 11: Edge — very short duration
- **Description:** Watch for an extremely short time
- **Params:** `{ "path": "Timer", "signals": ["timeout"], "duration": 0.01 }`
- **Expected result:** Success. Returns log of any signals that fired in that brief window (likely none).

#### Scenario 12: Edge — long duration
- **Description:** Watch for a very long time
- **Params:** `{ "path": "Player", "signals": ["ready"], "duration": 300 }`
- **Expected result:** The MCP-side timeout may fire before the duration completes. Test to verify timeout handling.

#### Scenario 13: Edge — call when game is NOT running
- **Description:** Invoke while editor is stopped
- **Params:** `{ "path": "Player", "signals": ["ready"] }`
- **Expected result:** Error from Godot (game must be running).

---

## Integration Test Scenarios

These scenarios chain multiple runtime tools together to verify end-to-end workflows.

### Integration 1: Scene tree → Node properties → Set property → Verify
1. `get_game_scene_tree` — confirm the scene is loaded and contains expected nodes
2. `get_game_node_properties` with `{ "path": "Player", "properties": ["position"] }` — read initial position
3. `set_game_node_property` with `{ "path": "Player", "property": "position", "value": [100, 0, 100] }` — move the player
4. `get_game_node_properties` with `{ "path": "Player", "properties": ["position"] }` — verify position changed to `(100, 0, 100)`
- **Expected result:** All steps succeed. Position changes from original → `(100, 0, 100)` after step 3.

### Integration 2: Find UI → Click button → Verify with script
1. `find_ui_elements` with `{ "filter": { "type": "Button" } }` — find all buttons
2. `click_button_by_text` with `{ "text": "Start Game" }` — click the start button
3. `execute_game_script` with code that checks a game state variable changed by the button — verify the click had the expected effect
- **Expected result:** Button click triggers game logic; script execution confirms state change.

### Integration 3: Record → Replay workflow
1. `start_recording` — begin recording
2. Wait ~3 seconds (simulate gameplay)
3. `stop_recording` — get the recorded data
4. `replay_recording` with `{ "speed": 2.0 }` — replay at double speed
- **Expected result:** Recording captures game state; replay plays back successfully.

### Integration 4: Watch signals → Trigger signal → Verify log
1. `watch_signals` with `{ "path": "Player", "signals": ["body_entered"], "duration": 10 }` — start watching
2. While watching, `set_game_node_property` or `move_to` to make the player collide with another body
3. When `watch_signals` returns, verify the log contains the `body_entered` emission
- **Expected result:** Signal log includes the triggered signal with correct arguments.

### Integration 5: Find nodes by script → Batch get properties → Execute script
1. `find_nodes_by_script` with `{ "script_path": "res://scripts/enemy.gd" }` — get all enemy nodes
2. `batch_get_properties` with enemy paths and `["health", "position"]` — read health and position of all enemies
3. `execute_game_script` to calculate which enemy is closest to player
- **Expected result:** Full pipeline from node discovery to data collection to computation works.

### Integration 6: Monitor properties → Move node → Verify timeline
1. `monitor_properties` with `{ "path": "Player", "properties": ["position"], "duration": 3 }` — start monitoring
2. Immediately after, `move_to` with `{ "path": "Player", "target": [50, 0, 50] }` — move the player
3. Wait for monitoring to complete
4. Verify the timeline shows the position transition from original → (50, 0, 50)
- **Expected result:** Timeline captures the position change caused by `move_to`.

### Integration 7: Wait for node → Find nearby → Navigate
1. `wait_for_node` with `{ "path": "GoalPoint" }` — wait for a goal marker to appear
2. `find_nearby_nodes` with goal's position — verify the area around the goal
3. `navigate_to` with player path and goal position — pathfind to the goal
- **Expected result:** Full navigation pipeline: wait → survey → pathfind.

---

## Summary

| # | Tool | Params | Required | Optional | Enum Values / Constraints |
|---|---|---|---|---|---|
| 1 | `get_game_scene_tree` | 0 | — | — | — |
| 2 | `get_game_node_properties` | 2 | `path` | `properties` | — |
| 3 | `set_game_node_property` | 3 | `path`, `property`, `value` | — | `value`: any |
| 4 | `execute_game_script` | 1 | `code` | — | — |
| 5 | `capture_frames` | 2 | — | `count`, `interval` | `count`: 1–60, integer |
| 6 | `monitor_properties` | 3 | `path`, `properties` | `duration` | — |
| 7 | `start_recording` | 0 | — | — | — |
| 8 | `stop_recording` | 0 | — | — | — |
| 9 | `replay_recording` | 1 | — | `speed` | `speed`: > 0 |
| 10 | `find_nodes_by_script` | 1 | `script_path` | — | — |
| 11 | `get_autoload` | 1 | `name` | — | — |
| 12 | `batch_get_properties` | 2 | `paths`, `properties` | — | — |
| 13 | `find_ui_elements` | 1 | — | `filter` | `filter.type`: any Control type; `filter.text`: any string |
| 14 | `click_button_by_text` | 2 | `text` | `timeout` | — |
| 15 | `wait_for_node` | 2 | `path` | `timeout` | `timeout`: default `5.0` |
| 16 | `find_nearby_nodes` | 2 | `position`, `radius` | — | `position`: `[x, y, z]` (3 numbers); `radius`: > 0 |
| 17 | `navigate_to` | 2 | `path`, `target` | — | `target`: `[x, y, z]` (3 numbers) |
| 18 | `move_to` | 2 | `path`, `target` | — | `target`: `[x, y, z]` (3 numbers) |
| 19 | `watch_signals` | 3 | `path`, `signals` | `duration` | — |

**Total scenarios:** 140+ covering all 19 tools with happy paths, edge cases, validation errors, and integration workflows.
