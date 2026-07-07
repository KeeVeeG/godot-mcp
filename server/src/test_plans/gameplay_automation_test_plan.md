# Gameplay Automation Tools — Test Plan

**Source file:** `server/src/tools/gameplay_automation.ts`
**Shared types:** `server/src/tools/shared-types.ts`
**Number of tools:** 7
**Generated:** 2026-07-08

---

## Type Reference

| Zod schema | Underlying type | Description |
|---|---|---|
| `ScenePath` | `z.string()` | Scene file path (e.g. `"res://scenes/main.tscn"`) |
| `NodePath` | `z.string()` | Node path in the scene tree (e.g. `"Player/Sprite2D"`). Use just the node name for root-level children (e.g. `"Player"`), or `""` for the scene root itself. Paths are relative to the currently open scene. |
| `Position3D` | `z.tuple([z.number(), z.number(), z.number()])` | 3D position as `[x, y, z]` |
| `Properties` | `z.record(z.unknown())` | Property key-value dictionary (required) |
| `z.enum(['direct', 'pathfind'])` | enum string | Navigation method |
| `z.array(...)` | array | Ordered list of items |
| `z.number()` | number | Floating-point number |
| `z.number().int()` | number (int) | Integer |
| `z.number().min(N).max(M)` | number | Bounded number |
| `z.boolean()` | boolean | Boolean flag |
| `z.string()` | string | Generic string |
| `z.unknown()` | unknown | Any serializable value |

### Behavior Notes

All 7 tools route through `callGodot(bridge, '<tool_name>', args)` which wraps `bridge.sendRequest(method, params)` with a 30-second timeout (`REQUEST_TIMEOUT_MS = 30_000`). Errors are formatted as `"Godot request failed: <message>"`.

Runtime tools (`simulate_gameplay_scenario`, `record_gameplay`, `replay_gameplay`, `create_test_character`, `navigate_character`, `assert_game_state`, `wait_for_game_event`) all require the Godot game to be running — they interact with `mcp_runtime.gd` autoload. If Godot is not connected, the bridge returns `"Godot editor is not connected"`.

---

## Tool: `simulate_gameplay_scenario`

**Description:** Run a sequence of gameplay actions (input, wait, move, click, assert) as an automated scenario
**Handler:** `callGodot(bridge, 'simulate_gameplay_scenario', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `scenario` | array of `{ action, params, wait? }` | **Yes** | — | Ordered list of gameplay actions to execute |

**Scenario item object structure:**

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `action` | string: `'input'` \| `'wait'` \| `'move'` \| `'click'` \| `'assert'` | **Yes** | — | Action type |
| `params` | object (`z.record(z.unknown())`) | **Yes** | — | Parameters for the action |
| `wait` | number (optional) | No | — | Wait time in ms after this step |

### Test Scenarios

#### Scenario 1: Happy path — full scenario with all action types and post-waits
- **Description:** Execute a complete scenario exercising every action type (`input`, `wait`, `move`, `click`, `assert`), each with `params` and post-step `wait` values. Game must be running.
- **Params:**
```json
{
  "scenario": [
    {
      "action": "input",
      "params": { "action": "ui_accept", "pressed": true },
      "wait": 200
    },
    {
      "action": "wait",
      "params": { "duration": 0.5 },
      "wait": 100
    },
    {
      "action": "move",
      "params": { "path": "Player", "target": [100, 0, 200] },
      "wait": 500
    },
    {
      "action": "click",
      "params": { "position": [400, 300], "button": "left" },
      "wait": 100
    },
    {
      "action": "assert",
      "params": { "path": "Player", "property": "position", "expected": [100, 0, 200] }
    }
  ]
}
```
- **Expected result:** Success. All 5 actions execute in order, each with its post-wait applied. The final assert verifies the player reached the target position.

#### Scenario 2: Happy path — minimal scenario (single action, no wait)
- **Description:** Execute a scenario with only one action and no optional `wait` field.
- **Params:**
```json
{
  "scenario": [
    {
      "action": "input",
      "params": { "action": "jump", "pressed": true }
    }
  ]
}
```
- **Expected result:** Success. The single `input` action is executed immediately with no post-wait.

#### Scenario 3: Happy path — scenario with only `wait` fields, no `params` details
- **Description:** A scenario where actions rely on minimal params. Each action must have `params` (required by `z.record(z.unknown())`), but the content may be empty.
- **Params:**
```json
{
  "scenario": [
    {
      "action": "wait",
      "params": { "duration": 0.25 },
      "wait": 50
    },
    {
      "action": "wait",
      "params": { "duration": 0.25 }
    }
  ]
}
```
- **Expected result:** Success. Both wait steps execute sequentially — first with a 50ms post-wait, second with none.

#### Scenario 4: Action type — `input`
- **Description:** Simulate pressing an InputMap action. Test with `pressed: true` then `pressed: false`.
- **Params:**
```json
{
  "scenario": [
    {
      "action": "input",
      "params": { "action": "move_right", "pressed": true },
      "wait": 300
    },
    {
      "action": "input",
      "params": { "action": "move_right", "pressed": false }
    }
  ]
}
```
- **Expected result:** Success. `move_right` is pressed, held for ~300ms, then released.

#### Scenario 5: Action type — `wait`
- **Description:** Insert timed pauses between other actions.
- **Params:**
```json
{
  "scenario": [
    {
      "action": "input",
      "params": { "action": "ui_accept", "pressed": true }
    },
    {
      "action": "wait",
      "params": { "duration": 2.0 }
    },
    {
      "action": "input",
      "params": { "action": "ui_cancel", "pressed": true }
    }
  ]
}
```
- **Expected result:** Success. `ui_accept` fires, 2-second pause, then `ui_cancel` fires.

#### Scenario 6: Action type — `move`
- **Description:** Move a character to a specific world position.
- **Params:**
```json
{
  "scenario": [
    {
      "action": "move",
      "params": { "path": "Player", "target": [-50, 0, 300] },
      "wait": 1000
    }
  ]
}
```
- **Expected result:** Success. The node at path `Player` moves (or attempts to move) to `[-50, 0, 300]`. Requires a node named "Player" in the running scene.

#### Scenario 7: Action type — `click`
- **Description:** Simulate a mouse click at a screen position.
- **Params:**
```json
{
  "scenario": [
    {
      "action": "click",
      "params": { "position": [640, 360], "button": "left" },
      "wait": 200
    },
    {
      "action": "click",
      "params": { "position": [100, 100], "button": "right" }
    }
  ]
}
```
- **Expected result:** Success. First click at (640, 360) with left button and 200ms post-wait, then right-click at (100, 100).

#### Scenario 8: Action type — `assert`
- **Description:** Assert a game state condition after a sequence of actions.
- **Params:**
```json
{
  "scenario": [
    {
      "action": "input",
      "params": { "action": "ui_accept", "pressed": true }
    },
    {
      "action": "assert",
      "params": { "path": "Player", "property": "visible", "expected": true }
    }
  ]
}
```
- **Expected result:** Success if the Player node is visible after pressing ui_accept. If the assert fails, the scenario should report the failure.

#### Scenario 9: Edge — empty scenario array
- **Description:** Call with an empty `scenario` array.
- **Params:**
```json
{
  "scenario": []
}
```
- **Expected result:** Should succeed trivially (no steps to execute is a valid no-op). Verify Godot's behavior — may return success or a warning.

#### Scenario 10: Edge — missing required `scenario` parameter
- **Description:** Call without the `scenario` parameter entirely.
- **Params:**
```json
{}
```
- **Expected result:** Zod validation error. `scenario` is required.

#### Scenario 11: Edge — missing required `action` field on a step
- **Description:** A step in the scenario has `params` and `wait` but no `action`.
- **Params:**
```json
{
  "scenario": [
    {
      "params": { "duration": 1.0 },
      "wait": 100
    }
  ]
}
```
- **Expected result:** Zod validation error. `action` is required on every step.

#### Scenario 12: Edge — missing required `params` field on a step
- **Description:** A step has `action` but no `params`.
- **Params:**
```json
{
  "scenario": [
    {
      "action": "wait"
    }
  ]
}
```
- **Expected result:** Zod validation error. `params` is required (`z.record(z.unknown())`) — an empty object `{}` is fine, but the field must be present.

#### Scenario 13: Edge — invalid action type string
- **Description:** Use an action type not in the described set (`input`, `wait`, `move`, `click`, `assert`).
- **Params:**
```json
{
  "scenario": [
    {
      "action": "teleport",
      "params": { "target": [0, 0, 0] }
    }
  ]
}
```
- **Expected result:** Zod validation succeeds at the MCP server level (action is `z.string()`, not `z.enum()`). The Godot runtime should reject the unknown action type with an error.

#### Scenario 14: Edge — `wait` field with zero milliseconds
- **Description:** Set the optional `wait` field to `0`.
- **Params:**
```json
{
  "scenario": [
    {
      "action": "input",
      "params": { "action": "jump", "pressed": true },
      "wait": 0
    },
    {
      "action": "input",
      "params": { "action": "jump", "pressed": false }
    }
  ]
}
```
- **Expected result:** Success. Post-wait of 0ms behaves as no wait (or negligible delay).

#### Scenario 15: Edge — `wait` field with negative value
- **Description:** Set the optional `wait` to a negative number.
- **Params:**
```json
{
  "scenario": [
    {
      "action": "wait",
      "params": { "duration": 1.0 },
      "wait": -500
    }
  ]
}
```
- **Expected result:** Zod validation succeeds (wait is a plain `z.number()` with no min constraint). Godot should handle gracefully — likely treat as 0 or error.

#### Scenario 16: Edge — extremely large scenario (many steps)
- **Description:** Run a scenario with a large number of steps (e.g., 100+ `wait` steps).
- **Params:**
```json
{
  "scenario": [
    { "action": "wait", "params": { "duration": 0.01 } },
    { "action": "wait", "params": { "duration": 0.01 } },
    "... (98 more identical steps)"
  ]
}
```
- **Expected result:** Success (all steps execute) or a reasonable timeout/truncation error. Tests the bridge's 30s timeout boundary.

#### Scenario 17: Edge — `params` with unexpected or malformed data
- **Description:** Provide `params` with keys that don't match what the runtime action handler expects.
- **Params:**
```json
{
  "scenario": [
    {
      "action": "move",
      "params": { "wrongKey": "someValue", "another": true }
    }
  ]
}
```
- **Expected result:** Zod validation passes (params is `z.record(z.unknown())`). Godot should either ignore unknown keys and fail gracefully, or return an error about missing required keys.

#### Scenario 18: Edge — Godot not connected
- **Description:** Call the tool when the Godot editor is not connected.
- **Params:** Any valid scenario.
- **Expected result:** Error: `"Godot request failed: Godot editor is not connected"`.

---

## Tool: `record_gameplay`

**Description:** Record gameplay for a duration, capturing input events and/or game state
**Handler:** `callGodot(bridge, 'record_gameplay', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `duration` | number, min: 1, max: 300 | No | `10` | Recording duration in seconds |
| `include_input` | boolean | No | `true` | Record input events |
| `include_state` | boolean | No | `false` | Record game state snapshots |

### Test Scenarios

#### Scenario 1: Happy path — record with all defaults
- **Description:** Start recording gameplay with no parameters — uses all defaults (10s duration, inputs on, state off). Game must be running.
- **Params:**
```json
{}
```
- **Expected result:** Success. Recording runs for 10 seconds capturing input events only. Returns path to the recording file and summary data.

#### Scenario 2: Happy path — record inputs only (explicit)
- **Description:** Record for 5 seconds with input capture enabled and state capture disabled.
- **Params:**
```json
{
  "duration": 5,
  "include_input": true,
  "include_state": false
}
```
- **Expected result:** Success. 5-second recording with only input events captured.

#### Scenario 3: Happy path — record game state only
- **Description:** Record for 3 seconds capturing game state snapshots but no input events.
- **Params:**
```json
{
  "duration": 3,
  "include_input": false,
  "include_state": true
}
```
- **Expected result:** Success. 3-second recording with state snapshots captured. Input events are not recorded.

#### Scenario 4: Happy path — record both inputs and state
- **Description:** Record for 15 seconds capturing both input events and game state snapshots.
- **Params:**
```json
{
  "duration": 15,
  "include_input": true,
  "include_state": true
}
```
- **Expected result:** Success. Full recording with both input and state data.

#### Scenario 5: Duration boundary — minimum (1 second)
- **Description:** Record for the minimum allowed duration.
- **Params:**
```json
{
  "duration": 1
}
```
- **Expected result:** Success. Recording runs for exactly 1 second.

#### Scenario 6: Duration boundary — maximum (300 seconds)
- **Description:** Record for the maximum allowed duration (5 minutes).
- **Params:**
```json
{
  "duration": 300
}
```
- **Expected result:** Success. Recording runs for the full 300 seconds. May approach the bridge's 30s timeout — verify if the recording request returns immediately (async) or blocks until completion.

#### Scenario 7: Duration boundary — value at 0 (below min)
- **Description:** Attempt to record with `duration: 0` (below the `min(1)` constraint).
- **Params:**
```json
{
  "duration": 0
}
```
- **Expected result:** Zod validation error. Duration must be >= 1.

#### Scenario 8: Duration boundary — value at 301 (above max)
- **Description:** Attempt to record with `duration: 301` (above the `max(300)` constraint).
- **Params:**
```json
{
  "duration": 301
}
```
- **Expected result:** Zod validation error. Duration must be <= 300.

#### Scenario 9: Duration boundary — negative value
- **Description:** Attempt to record with a negative duration.
- **Params:**
```json
{
  "duration": -5
}
```
- **Expected result:** Zod validation error. Duration must be >= 1.

#### Scenario 10: Duration boundary — fractional second
- **Description:** Record with a fractional duration (e.g., 2.5 seconds).
- **Params:**
```json
{
  "duration": 2.5
}
```
- **Expected result:** Zod validation succeeds (duration is `z.number()`, not `z.number().int()`). Godot may truncate to integer seconds or handle fractional. Test to verify behavior.

#### Scenario 11: Edge — include_state without include_input
- **Description:** Disable input recording but enable state recording.
- **Params:**
```json
{
  "include_input": false,
  "include_state": true
}
```
- **Expected result:** Success. State-only recording.

#### Scenario 12: Edge — both flags explicitly false
- **Description:** Disable both input and state recording.
- **Params:**
```json
{
  "include_input": false,
  "include_state": false
}
```
- **Expected result:** Godot may succeed (essentially an idle recording that captures nothing) or return a warning/error that at least one capture type should be enabled. Test to verify actual behavior.

#### Scenario 13: Edge — string instead of boolean for include_input
- **Description:** Pass a string `"true"` instead of boolean `true`.
- **Params:**
```json
{
  "include_input": "true"
}
```
- **Expected result:** Zod validation error. `include_input` must be boolean.

#### Scenario 14: Edge — string instead of number for duration
- **Description:** Pass a string `"10"` instead of number `10`.
- **Params:**
```json
{
  "duration": "10"
}
```
- **Expected result:** Zod validation error. `duration` must be number.

#### Scenario 15: Edge — Godot not connected
- **Description:** Call the tool without an active Godot connection.
- **Params:** Any valid recording params.
- **Expected result:** Error: `"Godot request failed: Godot editor is not connected"`.

---

## Tool: `replay_gameplay`

**Description:** Replay a previously recorded gameplay session
**Handler:** `callGodot(bridge, 'replay_gameplay', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `recording_path` | string | **Yes** | — | Path to the recording file |
| `speed` | number, min: 0.1, max: 10 | No | `1.0` | Playback speed multiplier |

### Test Scenarios

#### Scenario 1: Happy path — replay at default speed
- **Description:** Replay a recording file at normal speed (1.0x). Requires a valid recording file from `record_gameplay`.
- **Params:**
```json
{
  "recording_path": "user://recordings/session_001.json"
}
```
- **Expected result:** Success. The recording is replayed at 1.0x speed. Game state, inputs, or both are replayed as captured.

#### Scenario 2: Happy path — replay at half speed (0.5x)
- **Description:** Replay in slow motion.
- **Params:**
```json
{
  "recording_path": "user://recordings/session_001.json",
  "speed": 0.5
}
```
- **Expected result:** Success. Playback runs at half speed.

#### Scenario 3: Happy path — replay at fast speed (5x)
- **Description:** Replay at 5x speed for quick review.
- **Params:**
```json
{
  "recording_path": "user://recordings/session_001.json",
  "speed": 5.0
}
```
- **Expected result:** Success. Playback runs at 5x speed.

#### Scenario 4: Speed boundary — minimum (0.1)
- **Description:** Replay at the slowest allowed speed.
- **Params:**
```json
{
  "recording_path": "user://recordings/session_001.json",
  "speed": 0.1
}
```
- **Expected result:** Success. Very slow playback at 0.1x.

#### Scenario 5: Speed boundary — maximum (10.0)
- **Description:** Replay at the fastest allowed speed.
- **Params:**
```json
{
  "recording_path": "user://recordings/session_001.json",
  "speed": 10.0
}
```
- **Expected result:** Success. Very fast playback at 10x.

#### Scenario 6: Speed boundary — below min (0.05)
- **Description:** Attempt to replay at a speed below the `min(0.1)` limit.
- **Params:**
```json
{
  "recording_path": "user://recordings/session_001.json",
  "speed": 0.05
}
```
- **Expected result:** Zod validation error. Speed must be >= 0.1.

#### Scenario 7: Speed boundary — above max (15)
- **Description:** Attempt to replay at a speed above the `max(10)` limit.
- **Params:**
```json
{
  "recording_path": "user://recordings/session_001.json",
  "speed": 15
}
```
- **Expected result:** Zod validation error. Speed must be <= 10.

#### Scenario 8: Speed boundary — zero
- **Description:** Attempt to replay at speed 0.
- **Params:**
```json
{
  "recording_path": "user://recordings/session_001.json",
  "speed": 0
}
```
- **Expected result:** Zod validation error. Speed must be >= 0.1 (0 is below minimum).

#### Scenario 9: Speed boundary — negative
- **Description:** Attempt to replay at a negative speed.
- **Params:**
```json
{
  "recording_path": "user://recordings/session_001.json",
  "speed": -1
}
```
- **Expected result:** Zod validation error. Speed must be >= 0.1.

#### Scenario 10: Edge — missing required `recording_path`
- **Description:** Call without the required `recording_path` parameter.
- **Params:**
```json
{
  "speed": 2.0
}
```
- **Expected result:** Zod validation error. `recording_path` is required.

#### Scenario 11: Edge — empty recording_path string
- **Description:** Pass an empty string for `recording_path`.
- **Params:**
```json
{
  "recording_path": ""
}
```
- **Expected result:** Zod validation succeeds (empty strings are valid strings). Godot should return an error for invalid/missing file path.

#### Scenario 12: Edge — non-existent recording file
- **Description:** Point to a recording file that does not exist.
- **Params:**
```json
{
  "recording_path": "user://recordings/non_existent.json"
}
```
- **Expected result:** Error from Godot: file not found or cannot load recording.

#### Scenario 13: Edge — recording_path with absolute filesystem path
- **Description:** Use an absolute OS path instead of a Godot resource path.
- **Params:**
```json
{
  "recording_path": "C:\\Users\\user\\recordings\\session.json"
}
```
- **Expected result:** Godot may reject the path (expects `user://` or `res://` prefixed paths) or attempt to load it. Test to verify.

#### Scenario 14: Edge — recording_path with `res://` prefix
- **Description:** Use a project resource path for the recording.
- **Params:**
```json
{
  "recording_path": "res://recordings/test_recording.json"
}
```
- **Expected result:** Success if the recording exists at that location, error if not.

#### Scenario 15: Edge — Godot not connected
- **Description:** Call the tool when Godot is not connected.
- **Params:** Any valid replay params.
- **Expected result:** Error: `"Godot request failed: Godot editor is not connected"`.

---

## Tool: `create_test_character`

**Description:** Create a test character in the scene at a specified position
**Handler:** `callGodot(bridge, 'create_test_character', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `scene_path` | string (`ScenePath`) | **Yes** | — | Path to the character scene to instantiate |
| `position` | `[number, number, number]` (`Position3D`) | No | — | World position [x, y, z] |

### Test Scenarios

#### Scenario 1: Happy path — create character at specified position
- **Description:** Instantiate a character scene at a specific world position. Requires a valid `.tscn` file at the given scene_path and game must be running.
- **Params:**
```json
{
  "scene_path": "res://characters/player.tscn",
  "position": [0, 0, 0]
}
```
- **Expected result:** Success. A new instance of `player.tscn` is created at world origin.

#### Scenario 2: Happy path — create character with no position (uses default)
- **Description:** Omit the optional `position` parameter. The character should be placed at the scene's default position (likely origin or wherever Godot defaults).
- **Params:**
```json
{
  "scene_path": "res://characters/enemy.tscn"
}
```
- **Expected result:** Success. Character is instantiated at default position.

#### Scenario 3: Position value — large coordinates
- **Description:** Create a character at a very distant position.
- **Params:**
```json
{
  "scene_path": "res://characters/npc.tscn",
  "position": [999999, 999999, 999999]
}
```
- **Expected result:** Success. Character is placed at extreme coordinates. Validate the character appears at that position.

#### Scenario 4: Position value — negative coordinates
- **Description:** Create a character at negative world coordinates.
- **Params:**
```json
{
  "scene_path": "res://characters/enemy.tscn",
  "position": [-500, -200, -1000]
}
```
- **Expected result:** Success. Character is placed in negative coordinate space.

#### Scenario 5: Position value — floating-point values
- **Description:** Use fractional coordinates.
- **Params:**
```json
{
  "scene_path": "res://characters/npc.tscn",
  "position": [10.5, 0.25, -3.14159]
}
```
- **Expected result:** Success. Character is placed at exact floating-point position.

#### Scenario 6: Edge — missing required `scene_path`
- **Description:** Call without the required `scene_path`.
- **Params:**
```json
{
  "position": [0, 0, 0]
}
```
- **Expected result:** Zod validation error. `scene_path` is required.

#### Scenario 7: Edge — empty scene_path string
- **Description:** Pass an empty string for `scene_path`.
- **Params:**
```json
{
  "scene_path": ""
}
```
- **Expected result:** Zod validation succeeds (empty string is valid `z.string()`). Godot should return an error — cannot instantiate an empty/null path.

#### Scenario 8: Edge — non-existent scene file
- **Description:** Point to a `.tscn` file that does not exist.
- **Params:**
```json
{
  "scene_path": "res://characters/does_not_exist.tscn"
}
```
- **Expected result:** Error from Godot: scene file not found or resource loading failed.

#### Scenario 9: Edge — non-scene file as scene_path
- **Description:** Point to a file that exists but is not a scene (e.g., a `.gd` script, `.png` texture).
- **Params:**
```json
{
  "scene_path": "res://icon.png"
}
```
- **Expected result:** Error from Godot: resource is not a PackedScene, cannot instantiate.

#### Scenario 10: Edge — position with only 2 elements instead of 3
- **Description:** Pass `[x, y]` instead of `[x, y, z]`.
- **Params:**
```json
{
  "scene_path": "res://characters/player.tscn",
  "position": [100, 200]
}
```
- **Expected result:** Zod validation error. `Position3D` is `z.tuple([number, number, number])` — exactly 3 elements required.

#### Scenario 11: Edge — position with 4 elements
- **Description:** Pass `[x, y, z, w]`.
- **Params:**
```json
{
  "scene_path": "res://characters/player.tscn",
  "position": [100, 200, 300, 400]
}
```
- **Expected result:** Zod validation error. `Position3D` expects exactly 3 elements.

#### Scenario 12: Edge — position with non-number elements
- **Description:** Pass string values in the position array.
- **Params:**
```json
{
  "scene_path": "res://characters/player.tscn",
  "position": ["100", "200", "300"]
}
```
- **Expected result:** Zod validation error. All 3 elements must be numbers.

#### Scenario 13: Edge — position is not an array (object instead)
- **Description:** Pass position as `{ x: 100, y: 200, z: 300 }` instead of `[100, 200, 300]`.
- **Params:**
```json
{
  "scene_path": "res://characters/player.tscn",
  "position": { "x": 100, "y": 200, "z": 300 }
}
```
- **Expected result:** Zod validation error. `Position3D` expects a tuple (array), not an object.

#### Scenario 14: Edge — Godot not connected
- **Description:** Call the tool without an active Godot connection.
- **Params:** Any valid create_character params.
- **Expected result:** Error: `"Godot request failed: Godot editor is not connected"`.

---

## Tool: `navigate_character`

**Description:** Move a character to a target position using direct movement or pathfinding
**Handler:** `callGodot(bridge, 'navigate_character', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `character_path` | string (`NodePath`) | **Yes** | — | Node path in the scene tree (relative to current scene) |
| `target` | `[number, number, number]` (`Position3D`) | **Yes** | — | Target position [x, y, z] |
| `method` | enum: `'direct'` \| `'pathfind'` | No | `'direct'` | Navigation method |

### Test Scenarios

#### Scenario 1: Happy path — direct movement
- **Description:** Move a character directly to a target position without pathfinding. Requires a node at `character_path` to exist in the running scene.
- **Params:**
```json
{
  "character_path": "Player",
  "target": [100, 0, 200],
  "method": "direct"
}
```
- **Expected result:** Success. The character is teleported/moved directly to `[100, 0, 200]`.

#### Scenario 2: Happy path — pathfind movement
- **Description:** Navigate a character to a target using pathfinding (requires NavigationAgent on the character and a baked navigation mesh).
- **Params:**
```json
{
  "character_path": "Enemy",
  "target": [50, 0, -100],
  "method": "pathfind"
}
```
- **Expected result:** Success. The character navigates along a computed path to the target.

#### Scenario 3: Happy path — default method (direct)
- **Description:** Omit the `method` parameter to use the default `"direct"` method.
- **Params:**
```json
{
  "character_path": "NPC",
  "target": [0, 0, 0]
}
```
- **Expected result:** Success. Character moves directly (same as explicit `method: "direct"`).

#### Scenario 4: Method enum — `direct`
- **Description:** Explicitly use `direct` method. Move to a far-away position.
- **Params:**
```json
{
  "character_path": "Player",
  "target": [10000, 0, 10000],
  "method": "direct"
}
```
- **Expected result:** Success. Character is placed at the distant target directly.

#### Scenario 5: Method enum — `pathfind`
- **Description:** Explicitly use `pathfind` method. Move to a reachable target.
- **Params:**
```json
{
  "character_path": "Player",
  "target": [50, 0, 50],
  "method": "pathfind"
}
```
- **Expected result:** Success if a navigation mesh is baked and the target is reachable. Error if no navigation mesh exists.

#### Scenario 6: Edge — missing required `character_path`
- **Description:** Call without the required `character_path`.
- **Params:**
```json
{
  "target": [100, 200, 300]
}
```
- **Expected result:** Zod validation error. `character_path` is required.

#### Scenario 7: Edge — missing required `target`
- **Description:** Call without the required `target`.
- **Params:**
```json
{
  "character_path": "Player"
}
```
- **Expected result:** Zod validation error. `target` is required.

#### Scenario 8: Edge — non-existent character_path
- **Description:** Navigate a node that does not exist in the scene.
- **Params:**
```json
{
  "character_path": "NonExistentNode",
  "target": [0, 0, 0]
}
```
- **Expected result:** Error from Godot: node not found at path.

#### Scenario 9: Edge — empty character_path string
- **Description:** Pass an empty string. This targets the scene root.
- **Params:**
```json
{
  "character_path": "",
  "target": [0, 0, 0]
}
```
- **Expected result:** Godot tries to navigate the scene root. Likely an error since root nodes typically cannot be moved, or succeeds if the root has a suitable script.

#### Scenario 10: Edge — invalid method string (not in enum)
- **Description:** Pass a method string not in the `['direct', 'pathfind']` enum.
- **Params:**
```json
{
  "character_path": "Player",
  "target": [0, 0, 0],
  "method": "teleport"
}
```
- **Expected result:** Zod validation error. Method must be `'direct'` or `'pathfind'`.

#### Scenario 11: Edge — target with wrong number of elements
- **Description:** Pass target with 2 elements `[x, y]` instead of 3 `[x, y, z]`.
- **Params:**
```json
{
  "character_path": "Player",
  "target": [100, 200]
}
```
- **Expected result:** Zod validation error. `Position3D` requires exactly 3 elements.

#### Scenario 12: Edge — pathfind without navigation mesh
- **Description:** Call `pathfind` when no navigation mesh is baked.
- **Params:**
```json
{
  "character_path": "Player",
  "target": [100, 0, 100],
  "method": "pathfind"
}
```
- **Expected result:** Error from Godot: no navigation mesh available, or pathfinding failed.

#### Scenario 13: Edge — pathfind to unreachable target
- **Description:** Call `pathfind` to a position blocked by obstacles or outside the navmesh.
- **Params:**
```json
{
  "character_path": "Player",
  "target": [99999, -99999, 99999],
  "method": "pathfind"
}
```
- **Expected result:** Error from Godot: no path found or target unreachable.

#### Scenario 14: Edge — Godot not connected
- **Description:** Call without an active Godot connection.
- **Params:** Any valid navigate params.
- **Expected result:** Error: `"Godot request failed: Godot editor is not connected"`.

---

## Tool: `assert_game_state`

**Description:** Assert multiple game state conditions simultaneously
**Handler:** `callGodot(bridge, 'assert_game_state', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `conditions` | array of `{ path, property, expected, operator? }` | **Yes** | — | List of conditions that must all pass |

**Condition object structure:**

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | string | **Yes** | — | Node path |
| `property` | string | **Yes** | — | Property name to check |
| `expected` | unknown | **Yes** | — | Expected value |
| `operator` | string (optional) | No | — | Comparison operator: `==`, `!=`, `>`, `<`, `>=`, `<=`, `contains` |

### Test Scenarios

#### Scenario 1: Happy path — single condition, default operator (==)
- **Description:** Assert one property equals an expected value. Operator defaults to `==` when omitted. Game must be running.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "Player",
      "property": "visible",
      "expected": true
    }
  ]
}
```
- **Expected result:** Success if `Player.visible == true`. Failure if the property doesn't match.

#### Scenario 2: Happy path — multiple conditions, all pass
- **Description:** Assert several properties at once. All must pass for the tool to succeed.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "Player",
      "property": "visible",
      "expected": true,
      "operator": "=="
    },
    {
      "path": "Player",
      "property": "position",
      "expected": [0, 0, 0],
      "operator": "=="
    },
    {
      "path": "HUD/ScoreLabel",
      "property": "text",
      "expected": "Score: 0",
      "operator": "=="
    }
  ]
}
```
- **Expected result:** Success only if all 3 conditions pass. If any one fails, the tool reports which condition(s) failed.

#### Scenario 3: Happy path — all operator enum values: `!=`
- **Description:** Assert not-equal comparison.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "Player",
      "property": "health",
      "expected": 0,
      "operator": "!="
    }
  ]
}
```
- **Expected result:** Success if `Player.health != 0`.

#### Scenario 4: Operator — `>`
- **Description:** Assert greater-than comparison.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "Player",
      "property": "speed",
      "expected": 100,
      "operator": ">"
    }
  ]
}
```
- **Expected result:** Success if `Player.speed > 100`.

#### Scenario 5: Operator — `<`
- **Description:** Assert less-than comparison.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "Enemy",
      "property": "health",
      "expected": 50,
      "operator": "<"
    }
  ]
}
```
- **Expected result:** Success if `Enemy.health < 50`.

#### Scenario 6: Operator — `>=`
- **Description:** Assert greater-than-or-equal comparison.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "Player",
      "property": "score",
      "expected": 10,
      "operator": ">="
    }
  ]
}
```
- **Expected result:** Success if `Player.score >= 10`.

#### Scenario 7: Operator — `<=`
- **Description:** Assert less-than-or-equal comparison.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "Player",
      "property": "mana",
      "expected": 100,
      "operator": "<="
    }
  ]
}
```
- **Expected result:** Success if `Player.mana <= 100`.

#### Scenario 8: Operator — `contains`
- **Description:** Assert string/array contains a value.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "HUD/DebugLabel",
      "property": "text",
      "expected": "Level",
      "operator": "contains"
    }
  ]
}
```
- **Expected result:** Success if the text contains the substring "Level".

#### Scenario 9: Edge — empty conditions array
- **Description:** Call with an empty conditions array.
- **Params:**
```json
{
  "conditions": []
}
```
- **Expected result:** Should succeed trivially (no conditions to check means all pass). Verify Godot's behavior.

#### Scenario 10: Edge — missing required `conditions`
- **Description:** Call without the `conditions` parameter.
- **Params:**
```json
{}
```
- **Expected result:** Zod validation error. `conditions` is required.

#### Scenario 11: Edge — missing required `path` on a condition
- **Description:** Omit the `path` field from one condition.
- **Params:**
```json
{
  "conditions": [
    {
      "property": "visible",
      "expected": true
    }
  ]
}
```
- **Expected result:** Zod validation error. `path` is required on each condition.

#### Scenario 12: Edge — missing required `property` on a condition
- **Description:** Omit the `property` field from one condition.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "Player",
      "expected": true
    }
  ]
}
```
- **Expected result:** Zod validation error. `property` is required on each condition.

#### Scenario 13: Edge — missing required `expected` on a condition
- **Description:** Omit the `expected` field.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "Player",
      "property": "visible"
    }
  ]
}
```
- **Expected result:** Zod validation succeeds (`z.unknown()` means missing is allowed — but `expected` is a required field of the `z.object()`). Actually, `z.unknown().describe(...)` does NOT make it required — the object schema uses `z.object({ ... })` without `.partial()`, so all fields are required. Zod validation error: `expected` is required.

#### Scenario 14: Edge — invalid operator string
- **Description:** Use an operator not in the documented set.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "Player",
      "property": "health",
      "expected": 100,
      "operator": "equals"
    }
  ]
}
```
- **Expected result:** Zod validation succeeds (operator is `z.string().optional()`, not `z.enum()`). Godot should reject the unknown operator with an error.

#### Scenario 15: Edge — non-existent node path
- **Description:** Assert a condition against a node that does not exist.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "NonExistentNode",
      "property": "visible",
      "expected": true
    }
  ]
}
```
- **Expected result:** Error from Godot: node not found at path. The assertion fails.

#### Scenario 16: Edge — non-existent property
- **Description:** Assert a property that does not exist on the node.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "Player",
      "property": "non_existent_prop",
      "expected": 42
    }
  ]
}
```
- **Expected result:** Error from Godot: property not found on node.

#### Scenario 17: Edge — expected value of different type than property
- **Description:** Compare a boolean property against a string.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "Player",
      "property": "visible",
      "expected": "yes"
    }
  ]
}
```
- **Expected result:** The assertion should report failure (type mismatch) or Godot may coerce types. Test to verify behavior.

#### Scenario 18: Edge — operator omitted but implicit `==` inferred
- **Description:** Omit the `operator` field — should default to equality.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "Player",
      "property": "name",
      "expected": "Player"
    }
  ]
}
```
- **Expected result:** Success if the node's name equals "Player". Verifies that Godot defaults to `==` when operator is absent.

#### Scenario 19: Edge — single failed condition among many
- **Description:** One of several conditions fails. Verify the error message identifies which condition(s) failed.
- **Params:**
```json
{
  "conditions": [
    {
      "path": "Player",
      "property": "visible",
      "expected": true
    },
    {
      "path": "Player",
      "property": "health",
      "expected": 999,
      "operator": "=="
    },
    {
      "path": "Player",
      "property": "speed",
      "expected": 0,
      "operator": ">="
    }
  ]
}
```
- **Expected result:** Failure. The error should indicate that condition index 1 (`health == 999`) failed, while other conditions may have passed.

#### Scenario 20: Edge — Godot not connected
- **Description:** Call without an active Godot connection.
- **Params:** Any valid assert params.
- **Expected result:** Error: `"Godot request failed: Godot editor is not connected"`.

---

## Tool: `wait_for_game_event`

**Description:** Wait for a specific game event (signal, node creation, property change) with timeout
**Handler:** `callGodot(bridge, 'wait_for_game_event', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `event` | string | **Yes** | — | Event to wait for. Prefix format: `'signal:NodePath:SignalName'`, `'node:NodePath'`, or `'property:NodePath:PropName:ExpectedValue'` |
| `timeout` | number (int), min: 1, max: 30000 | No | `5000` | Timeout in milliseconds |

### Test Scenarios

#### Scenario 1: Happy path — wait for signal emission
- **Description:** Wait for a specific signal to be emitted from a node. Game must be running.
- **Params:**
```json
{
  "event": "signal:Player:health_changed",
  "timeout": 5000
}
```
- **Expected result:** Success when the `health_changed` signal is emitted from the `Player` node within 5000ms. Times out with an error if the signal never fires.

#### Scenario 2: Happy path — wait for node creation
- **Description:** Wait for a node to appear in the scene tree.
- **Params:**
```json
{
  "event": "node:EnemySpawner/Enemy_001",
  "timeout": 10000
}
```
- **Expected result:** Success when `Enemy_001` is created as a child of `EnemySpawner` within 10000ms.

#### Scenario 3: Happy path — wait for property change
- **Description:** Wait for a property on a node to reach a specific value.
- **Params:**
```json
{
  "event": "property:Player:health:0",
  "timeout": 3000
}
```
- **Expected result:** Success when `Player.health` equals `0` within 3000ms.

#### Scenario 4: Happy path — default timeout (5000ms)
- **Description:** Omit the `timeout` parameter, using the default of 5000ms.
- **Params:**
```json
{
  "event": "signal:Timer:timeout"
}
```
- **Expected result:** Success if the `timeout` signal fires within 5 seconds.

#### Scenario 5: Event format — signal prefix
- **Description:** Explicitly use `signal:` prefix format. Wait for a signal with a node path containing slashes.
- **Params:**
```json
{
  "event": "signal:UI/MainMenu/StartButton:pressed"
}
```
- **Expected result:** Success when `StartButton`'s `pressed` signal fires.

#### Scenario 6: Event format — node prefix
- **Description:** Explicitly use `node:` prefix format.
- **Params:**
```json
{
  "event": "node:Bullet",
  "timeout": 2000
}
```
- **Expected result:** Success when a node named `Bullet` appears at the scene root.

#### Scenario 7: Event format — property prefix
- **Description:** Explicitly use `property:` prefix format with a non-numeric expected value.
- **Params:**
```json
{
  "event": "property:GameState:phase:game_over",
  "timeout": 15000
}
```
- **Expected result:** Success when `GameState.phase` changes to `"game_over"`.

#### Scenario 8: Timeout boundary — minimum (1ms)
- **Description:** Set timeout to the minimum allowed value.
- **Params:**
```json
{
  "event": "signal:Player:jumped",
  "timeout": 1
}
```
- **Expected result:** Almost guaranteed to time out unless the signal fires in the same frame. Verifies that 1ms timeout is accepted.

#### Scenario 9: Timeout boundary — maximum (30000ms)
- **Description:** Set timeout to the maximum allowed value (30 seconds).
- **Params:**
```json
{
  "event": "signal:SlowEvent:finished",
  "timeout": 30000
}
```
- **Expected result:** Success if the signal fires within 30 seconds. Note: this approaches the bridge's own 30s timeout (REQUEST_TIMEOUT_MS). Test to verify interaction between the event timeout and bridge timeout.

#### Scenario 10: Timeout boundary — value 0 (below min)
- **Description:** Attempt a timeout of 0ms.
- **Params:**
```json
{
  "event": "signal:Player:jumped",
  "timeout": 0
}
```
- **Expected result:** Zod validation error. Timeout must be >= 1.

#### Scenario 11: Timeout boundary — value 30001 (above max)
- **Description:** Attempt a timeout of 30001ms.
- **Params:**
```json
{
  "event": "signal:Player:jumped",
  "timeout": 30001
}
```
- **Expected result:** Zod validation error. Timeout must be <= 30000.

#### Scenario 12: Timeout boundary — negative timeout
- **Description:** Attempt a negative timeout.
- **Params:**
```json
{
  "event": "signal:Player:jumped",
  "timeout": -500
}
```
- **Expected result:** Zod validation error. Timeout must be >= 1.

#### Scenario 13: Timeout boundary — fractional timeout (float instead of int)
- **Description:** Attempt a non-integer timeout (e.g., 500.5).
- **Params:**
```json
{
  "event": "signal:Player:jumped",
  "timeout": 500.5
}
```
- **Expected result:** Zod validation error. `timeout` is `z.number().int()` — only integer values allowed.

#### Scenario 14: Edge — missing required `event`
- **Description:** Call without the required `event` parameter.
- **Params:**
```json
{
  "timeout": 5000
}
```
- **Expected result:** Zod validation error. `event` is required.

#### Scenario 15: Edge — empty event string
- **Description:** Pass an empty string for `event`.
- **Params:**
```json
{
  "event": ""
}
```
- **Expected result:** Zod validation succeeds (empty string is valid). Godot should return an error: unknown event format or no prefix found.

#### Scenario 16: Edge — event without prefix
- **Description:** Pass an event string with no `signal:`, `node:`, or `property:` prefix.
- **Params:**
```json
{
  "event": "Player:jumped"
}
```
- **Expected result:** Error from Godot: unrecognized event format. The runtime should require one of the three recognized prefixes.

#### Scenario 17: Edge — malformed signal event (missing parts)
- **Description:** `signal:` prefix with too few colon-separated parts.
- **Params:**
```json
{
  "event": "signal:Player"
}
```
- **Expected result:** Error from Godot: malformed signal event format. Expected `signal:NodePath:SignalName`.

#### Scenario 18: Edge — malformed node event (extra colons)
- **Description:** `node:` prefix with extra colon-separated parts.
- **Params:**
```json
{
  "event": "node:Player:extra:parts"
}
```
- **Expected result:** Godot may interpret the full string `Player:extra:parts` as the node path, or reject it as malformed. Test to verify.

#### Scenario 19: Edge — malformed property event (missing parts)
- **Description:** `property:` prefix with only 2 colon-separated parts.
- **Params:**
```json
{
  "event": "property:Player:health"
}
```
- **Expected result:** Error from Godot: malformed property event format. Expected `property:NodePath:PropName:ExpectedValue`.

#### Scenario 20: Edge — mismatched prefix capitalization
- **Description:** Use `SIGNAL:`, `Signal:`, or `NODE:` (uppercase/mixed case) instead of lowercase prefixes.
- **Params:**
```json
{
  "event": "SIGNAL:Player:jumped"
}
```
- **Expected result:** Godot may reject the uppercase prefix as unrecognized (case-sensitive matching). Test to verify.

#### Scenario 21: Edge — waited event never occurs (timeout)
- **Description:** Wait for an event that will never fire.
- **Params:**
```json
{
  "event": "signal:NonExistentNode:impossible_signal",
  "timeout": 1000
}
```
- **Expected result:** Error from Godot: timeout after 1000ms. The error message should indicate that the event did not occur within the timeout.

#### Scenario 22: Edge — Godot not connected
- **Description:** Call without an active Godot connection.
- **Params:** Any valid event params.
- **Expected result:** Error: `"Godot request failed: Godot editor is not connected"`.

---

## Cross-Tool Integration Scenarios

### Integration 1: record → replay cycle
- **Description:** Record a gameplay session, then replay it. Verify the replay matches the original inputs.
- **Steps:**
  1. Call `record_gameplay` with `duration: 3, include_input: true, include_state: false`
  2. During the recording, perform some game actions (e.g., using `simulate_gameplay_scenario`)
  3. After recording completes, call `replay_gameplay` with the returned `recording_path` and `speed: 1.0`
- **Expected result:** The replay faithfully reproduces the recorded inputs.

### Integration 2: create character → navigate → assert → wait for event
- **Description:** Full gameplay automation flow: create a character, navigate it, assert its position, then wait for a signal.
- **Steps:**
  1. `create_test_character` at `[0, 0, 0]` using `res://characters/player.tscn`
  2. `navigate_character` to `[100, 0, 100]` using `method: "direct"`
  3. `assert_game_state` that `position == [100, 0, 100]`
  4. `wait_for_game_event` for `signal:Player:destination_reached`
- **Expected result:** All steps succeed in sequence. The character is created, moved, verified at the target, and the arrival signal is caught.

### Integration 3: simulate scenario → assert multiple states
- **Description:** Run a simulated gameplay scenario, then assert multiple game state conditions afterward.
- **Steps:**
  1. `simulate_gameplay_scenario` with actions: input → wait → move → click → assert
  2. `assert_game_state` with multiple conditions checking final game state
- **Expected result:** Both tools succeed. The scenario executes and the follow-up assertions validate the outcome.

### Integration 4: record while scenario runs
- **Description:** Record gameplay while a scenario is executing in parallel.
- **Steps:**
  1. Call `record_gameplay` with `duration: 10, include_input: true`
  2. Immediately call `simulate_gameplay_scenario` with a sequence of inputs
- **Expected result:** The recording captures the inputs from the simulated scenario. Depending on Godot's threading model, this may require the recording to be async (non-blocking).

---

## Error Handling — Universal Cases

These apply to ALL 7 tools:

| Error Condition | Expected Result |
|---|---|
| Godot editor not connected | `"Godot request failed: Godot editor is not connected"` |
| WebSocket request timeout (30s) | `"Request <tool_name> timed out after 30000ms"` (from bridge) |
| Zod validation failure (wrong type) | Zod error message returned by MCP server layer |
| Zod validation failure (missing required param) | Zod error message indicating which required parameter is missing |
| Godot runtime error during execution | `"Godot request failed: <Godot error message>"` |
| Bridge connection closed mid-request | `"Godot request failed: Connection closed"` (from bridge cleanup) |

---

## Summary

| # | Tool | Required Params | Optional Params (with defaults) | Enum Values |
|---|---|---|---|---|
| 1 | `simulate_gameplay_scenario` | `scenario` (array) | `wait` (per step, optional) | `action`: no enum (string); documented: `input`, `wait`, `move`, `click`, `assert` |
| 2 | `record_gameplay` | — (all optional) | `duration` (default: 10), `include_input` (default: true), `include_state` (default: false) | — |
| 3 | `replay_gameplay` | `recording_path` | `speed` (default: 1.0, min: 0.1, max: 10) | — |
| 4 | `create_test_character` | `scene_path` | `position` (3D tuple, optional) | — |
| 5 | `navigate_character` | `character_path`, `target` | `method` (default: `'direct'`) | `method`: `'direct'` \| `'pathfind'` |
| 6 | `assert_game_state` | `conditions` (array) | `operator` (per condition, optional) | `operator`: no enum (string); documented: `==`, `!=`, `>`, `<`, `>=`, `<=`, `contains` |
| 7 | `wait_for_game_event` | `event` | `timeout` (default: 5000, min: 1, max: 30000) | event prefix: `signal:`, `node:`, `property:` |

**Total test scenarios:** 107 (including integration and universal error cases)
