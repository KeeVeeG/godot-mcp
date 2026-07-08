# Gameplay Automation Test Plan

**Source file:** `server/src/tools/gameplay_automation.ts`
**Tools covered:** 7
**Prerequisites for runtime tests:** Game must be running (`godot_play_scene` called first)

---

## Tool: `godot_simulate_gameplay_scenario`

**Description:** Run a sequence of gameplay actions (input, wait, check) as an automated scenario.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `scenario` | `array` of objects | **Yes** | – | Ordered list of gameplay actions to execute |

**Scenario object fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `action` | `string` | **Yes** | – | Action type: `'input'`, `'wait'`, `'move'`, `'click'`, `'assert'` |
| `params` | `object` (record) | **Yes** | – | Parameters for the action (free-form key-value) |
| `wait` | `number` | No | – | Wait time in ms after this step |

**Handler:** Calls `callGodot(bridge, 'simulate_gameplay_scenario', args)`. Expected return: JSON result from Godot indicating success/failure per step.

### Test Scenarios

#### 1.1 Basic single "wait" action
- **Description:** Execute a scenario with a single `wait` action.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "scenario": [
      {
        "action": "wait",
        "params": { "duration": 500 }
      }
    ]
  }
  ```
- **Expected result:** Returns success. No error.

#### 1.2 Basic "input" action
- **Description:** Execute a scenario with a single `input` action simulating a key press.
- **Prerequisites:** Game running, `ui_accept` input action exists.
- **Params:**
  ```json
  {
    "scenario": [
      {
        "action": "input",
        "params": { "action_name": "ui_accept", "pressed": true }
      }
    ]
  }
  ```
- **Expected result:** Returns success. The `ui_accept` action is simulated.

#### 1.3 Basic "move" action
- **Description:** Execute a scenario with a single `move` action.
- **Prerequisites:** Game running, a navigable character exists.
- **Params:**
  ```json
  {
    "scenario": [
      {
        "action": "move",
        "params": { "character": "Player", "position": [5, 0, 10] }
      }
    ]
  }
  ```
- **Expected result:** Returns success. Character begins moving toward [5, 0, 10].

#### 1.4 Basic "click" action
- **Description:** Execute a scenario with a single `click` action simulating a mouse click.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "scenario": [
      {
        "action": "click",
        "params": { "position": [400, 300], "button": "left" }
      }
    ]
  }
  ```
- **Expected result:** Returns success. Left mouse click simulated at (400, 300).

#### 1.5 Basic "assert" action
- **Description:** Execute a scenario with a single `assert` action.
- **Prerequisites:** Game running, node exists with expected property.
- **Params:**
  ```json
  {
    "scenario": [
      {
        "action": "assert",
        "params": { "path": "Player", "property": "visible", "expected": true }
      }
    ]
  }
  ```
- **Expected result:** Returns success if assertion passes. Returns error if assertion fails.

#### 1.6 Scenario with `wait` post-step delay
- **Description:** Verify the optional `wait` field adds a delay after a step.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "scenario": [
      {
        "action": "wait",
        "params": { "duration": 100 },
        "wait": 1000
      },
      {
        "action": "assert",
        "params": { "path": "Player", "property": "position", "expected": [0, 0, 0] }
      }
    ]
  }
  ```
- **Expected result:** After the first step completes, there is a 1000ms delay before the second step executes. Returns final result.

#### 1.7 Multi-step scenario (all action types)
- **Description:** Execute a full scenario using all five action types in sequence.
- **Prerequisites:** Game running, Player node exists, `ui_accept` action exists.
- **Params:**
  ```json
  {
    "scenario": [
      {
        "action": "input",
        "params": { "action_name": "ui_accept", "pressed": true },
        "wait": 100
      },
      {
        "action": "wait",
        "params": { "duration": 500 }
      },
      {
        "action": "move",
        "params": { "character": "Player", "position": [0, 0, 0] }
      },
      {
        "action": "click",
        "params": { "position": [200, 150], "button": "left" },
        "wait": 200
      },
      {
        "action": "assert",
        "params": { "path": "Player", "property": "visible", "expected": true }
      }
    ]
  }
  ```
- **Expected result:** All steps execute in order. Returns success if assertion at the end passes.

#### 1.8 Missing required `scenario` parameter
- **Description:** Call without the `scenario` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error. Tool call rejected.

#### 1.9 Invalid `action` type
- **Description:** Use an unrecognized action type.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "scenario": [
      {
        "action": "invalid_action",
        "params": {}
      }
    ]
  }
  ```
- **Expected result:** Error from Godot indicating unknown action type, OR the string passes Zod validation (since `action` is just `z.string()`) and the Godot-side handler returns an error.

#### 1.10 Empty scenario array
- **Description:** Pass an empty scenario array.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "scenario": []
  }
  ```
- **Expected result:** May succeed with no steps executed, or Godot may return an error for empty scenario. Either is acceptable; no crash.

#### 1.11 Action without `params`
- **Description:** Omit the `params` field from an action object.
- **Prerequisites:** Game running.
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
- **Expected result:** Zod validation may allow this (params is a record, not explicitly required by Zod schema), but Godot handler likely errors on missing params. Either validation error or runtime error.

---

## Tool: `godot_record_gameplay`

**Description:** Record gameplay for a duration, capturing input events and/or game state.

**Parameters:**

| Parameter | Type | Required | Default | Constraints | Description |
|-----------|------|----------|---------|-------------|-------------|
| `duration` | `number` | No | `10` | `min: 1, max: 300` | Recording duration in seconds |
| `include_input` | `boolean` | No | `true` | – | Record input events |
| `include_state` | `boolean` | No | `false` | – | Record game state snapshots |

**Handler:** Calls `callGodot(bridge, 'record_gameplay', args)`. Expected return: path to the recording file or recording data.

### Test Scenarios

#### 2.1 Default parameters (minimum viable call)
- **Description:** Call with no parameters — uses all defaults.
- **Prerequisites:** Game running.
- **Params:** `{}`
- **Expected result:** Records for 10 seconds with input events captured. Returns success with recording data/path.

#### 2.2 Short duration (boundary: min value)
- **Description:** Record for the minimum allowed duration.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "duration": 1
  }
  ```
- **Expected result:** Records for 1 second. Returns success.

#### 2.3 Long duration (boundary: max value)
- **Description:** Record for the maximum allowed duration.
- **Prerequisites:** Game running. Note: this takes 300 seconds (5 minutes); may need to be skipped in CI or shortened.
- **Params:**
  ```json
  {
    "duration": 300
  }
  ```
- **Expected result:** Records for 300 seconds. Returns success. **Note:** Mark as `[SLOW]` — manual execution only.

#### 2.4 Medium duration with state recording
- **Description:** Record with state snapshots enabled.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "duration": 5,
    "include_input": true,
    "include_state": true
  }
  ```
- **Expected result:** Records 5 seconds with both input events and state snapshots. Returns success.

#### 2.5 Input only, no state
- **Description:** Explicitly set inputs on, state off.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "duration": 3,
    "include_input": true,
    "include_state": false
  }
  ```
- **Expected result:** Records 3 seconds with input only. Returns success.

#### 2.6 State only, no input
- **Description:** Record state snapshots without input events.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "duration": 5,
    "include_input": false,
    "include_state": true
  }
  ```
- **Expected result:** Records 5 seconds with state snapshots only. Returns success.

#### 2.7 Both disabled
- **Description:** Disable both input and state recording.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "duration": 2,
    "include_input": false,
    "include_state": false
  }
  ```
- **Expected result:** Records for 2 seconds but captures nothing. May return empty recording or warning. Should not crash.

#### 2.8 Duration below minimum
- **Description:** Set duration to 0 (below `min: 1`).
- **Params:**
  ```json
  {
    "duration": 0
  }
  ```
- **Expected result:** Zod validation error: `Number must be greater than or equal to 1`.

#### 2.9 Duration above maximum
- **Description:** Set duration to 301 (above `max: 300`).
- **Params:**
  ```json
  {
    "duration": 301
  }
  ```
- **Expected result:** Zod validation error: `Number must be less than or equal to 300`.

#### 2.10 Negative duration
- **Description:** Set duration to a negative number.
- **Params:**
  ```json
  {
    "duration": -5
  }
  ```
- **Expected result:** Zod validation error (negative number fails `min(1)`).

#### 2.11 Non-integer duration
- **Description:** Set duration to a floating point value like `3.5`.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "duration": 3.5
  }
  ```
- **Expected result:** Should accept (no `.int()` constraint on `duration`). Records for ~3.5 seconds.

---

## Tool: `godot_replay_gameplay`

**Description:** Replay a previously recorded gameplay session.

**Parameters:**

| Parameter | Type | Required | Default | Constraints | Description |
|-----------|------|----------|---------|-------------|-------------|
| `recording_path` | `string` | **Yes** | – | – | Path to the recording file |
| `speed` | `number` | No | `1.0` | `min: 0.1, max: 10` | Playback speed multiplier |

**Handler:** Calls `callGodot(bridge, 'replay_gameplay', args)`. Expected return: success/failure.

### Test Scenarios

#### 3.1 Happy path — default speed
- **Description:** Replay a recording at default speed.
- **Prerequisites:** Game running, a valid recording file exists at the given path.
- **Params:**
  ```json
  {
    "recording_path": "res://recordings/test_recording.json"
  }
  ```
- **Expected result:** Replays the recording at 1.0x speed. Returns success.

#### 3.2 Custom speed — minimum (0.1x)
- **Description:** Replay at the slowest allowed speed.
- **Prerequisites:** Game running, valid recording file exists.
- **Params:**
  ```json
  {
    "recording_path": "res://recordings/test_recording.json",
    "speed": 0.1
  }
  ```
- **Expected result:** Replays at 0.1x speed (10x slower). Returns success.

#### 3.3 Custom speed — maximum (10x)
- **Description:** Replay at the fastest allowed speed.
- **Prerequisites:** Game running, valid recording file exists.
- **Params:**
  ```json
  {
    "recording_path": "res://recordings/test_recording.json",
    "speed": 10
  }
  ```
- **Expected result:** Replays at 10x speed. Returns success.

#### 3.4 Custom speed — normal fast (2x)
- **Description:** Replay at 2x speed.
- **Prerequisites:** Game running, valid recording file exists.
- **Params:**
  ```json
  {
    "recording_path": "res://recordings/test_recording.json",
    "speed": 2.0
  }
  ```
- **Expected result:** Replays at 2x speed. Returns success.

#### 3.5 Missing required `recording_path`
- **Description:** Call without the required `recording_path` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error: `Required`.

#### 3.6 Non-existent recording file
- **Description:** Provide a path to a recording file that does not exist.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "recording_path": "res://recordings/nonexistent.json"
  }
  ```
- **Expected result:** Error from Godot: file not found or invalid recording.

#### 3.7 Speed below minimum
- **Description:** Set speed to 0.05 (below `min: 0.1`).
- **Params:**
  ```json
  {
    "recording_path": "res://recordings/test.json",
    "speed": 0.05
  }
  ```
- **Expected result:** Zod validation error: `Number must be greater than or equal to 0.1`.

#### 3.8 Speed above maximum
- **Description:** Set speed to 20 (above `max: 10`).
- **Params:**
  ```json
  {
    "recording_path": "res://recordings/test.json",
    "speed": 20
  }
  ```
- **Expected result:** Zod validation error: `Number must be less than or equal to 10`.

#### 3.9 Negative speed
- **Description:** Set speed to a negative value.
- **Params:**
  ```json
  {
    "recording_path": "res://recordings/test.json",
    "speed": -1
  }
  ```
- **Expected result:** Zod validation error (negative number fails `min(0.1)`).

#### 3.10 Zero speed
- **Description:** Set speed to 0.
- **Params:**
  ```json
  {
    "recording_path": "res://recordings/test.json",
    "speed": 0
  }
  ```
- **Expected result:** Zod validation error (0 < 0.1, fails `min(0.1)`).

---

## Tool: `godot_create_test_character`

**Description:** Create a test character in the scene at a specified position.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `scene_path` | `string` (ScenePath) | **Yes** | – | Path to the character scene to instantiate |
| `position` | `[number, number, number]` (Position3D) | No | – | World position [x, y, z] |

**Handler:** Calls `callGodot(bridge, 'create_test_character', args)`. Expected return: confirmation with the created node path or instance ID.

### Test Scenarios

#### 4.1 Happy path — with position
- **Description:** Create a test character at a specified position.
- **Prerequisites:** Game running or scene open; a valid `.tscn` character scene exists at the given path.
- **Params:**
  ```json
  {
    "scene_path": "res://scenes/characters/player.tscn",
    "position": [0, 0, 0]
  }
  ```
- **Expected result:** A test character is instantiated at world position [0, 0, 0]. Returns success with node reference.

#### 4.2 Happy path — without position
- **Description:** Create a test character without specifying a position (uses default).
- **Prerequisites:** Game running or scene open; valid character scene exists.
- **Params:**
  ```json
  {
    "scene_path": "res://scenes/characters/player.tscn"
  }
  ```
- **Expected result:** A test character is instantiated at the default/origin position. Returns success.

#### 4.3 Non-origin position
- **Description:** Create a test character at an arbitrary non-zero position.
- **Prerequisites:** Valid character scene exists.
- **Params:**
  ```json
  {
    "scene_path": "res://scenes/characters/enemy.tscn",
    "position": [100, 5, -50]
  }
  ```
- **Expected result:** Character instantiated at [100, 5, -50]. Returns success.

#### 4.4 Negative coordinates
- **Description:** Create a test character at a position with all negative coordinates.
- **Prerequisites:** Valid character scene exists.
- **Params:**
  ```json
  {
    "scene_path": "res://scenes/characters/npc.tscn",
    "position": [-10, -20, -30]
  }
  ```
- **Expected result:** Character instantiated at [-10, -20, -30]. Returns success.

#### 4.5 Large position values
- **Description:** Create a test character at a very large position.
- **Prerequisites:** Valid character scene exists.
- **Params:**
  ```json
  {
    "scene_path": "res://scenes/characters/player.tscn",
    "position": [999999, 999999, 999999]
  }
  ```
- **Expected result:** Character instantiated at the large position. May succeed or Godot may warn about far-from-origin placement. Tool itself should not reject.

#### 4.6 Missing required `scene_path`
- **Description:** Call without the required `scene_path`.
- **Params:** `{}`
- **Expected result:** Zod validation error: `Required`.

#### 4.7 Non-existent scene file
- **Description:** Provide a `scene_path` that does not exist.
- **Prerequisites:** Game running or scene open.
- **Params:**
  ```json
  {
    "scene_path": "res://scenes/nonexistent.tscn"
  }
  ```
- **Expected result:** Error from Godot: scene file not found.

#### 4.8 Invalid scene_path format
- **Description:** Provide a `scene_path` that is not a valid Godot path.
- **Params:**
  ```json
  {
    "scene_path": "not_a_valid_path"
  }
  ```
- **Expected result:** Zod passes (any string is valid ScenePath). Godot returns error about invalid path.

#### 4.9 Invalid `position` type — wrong array length (2 elements)
- **Description:** Provide a position array with only 2 elements instead of 3.
- **Params:**
  ```json
  {
    "scene_path": "res://scenes/characters/player.tscn",
    "position": [0, 0]
  }
  ```
- **Expected result:** Zod validation error: tuple expects exactly 3 elements.

#### 4.10 Invalid `position` type — non-number values
- **Description:** Provide a position with non-number values.
- **Params:**
  ```json
  {
    "scene_path": "res://scenes/characters/player.tscn",
    "position": ["x", "y", "z"]
  }
  ```
- **Expected result:** Zod validation error: expected number, received string.

---

## Tool: `godot_navigate_character`

**Description:** Move a character to a target position using direct movement or pathfinding.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `character_path` | `string` (NodePath) | **Yes** | – | Node path in the scene tree (e.g. `'Player'`) |
| `target` | `[number, number, number]` (Position3D) | **Yes** | – | Target position [x, y, z] |
| `method` | `enum: 'direct' \| 'pathfind'` | No | `'direct'` | Navigation method |

**Handler:** Calls `callGodot(bridge, 'navigate_character', args)`. Expected return: path or confirmation of movement.

### Test Scenarios

#### 5.1 Direct movement (default method)
- **Description:** Navigate a character using direct movement to a target position.
- **Prerequisites:** Game running, character node exists in scene tree.
- **Params:**
  ```json
  {
    "character_path": "Player",
    "target": [10, 0, 5]
  }
  ```
- **Expected result:** Character moves directly to [10, 0, 5]. Returns success.

#### 5.2 Pathfinding method
- **Description:** Navigate a character using pathfinding to a target position.
- **Prerequisites:** Game running, character node exists and has a NavigationAgent; a navigation mesh is baked.
- **Params:**
  ```json
  {
    "character_path": "Player",
    "target": [50, 0, 30],
    "method": "pathfind"
  }
  ```
- **Expected result:** Character navigates to [50, 0, 30] via the navigation mesh. Returns success or computed path.

#### 5.3 Explicit direct method
- **Description:** Explicitly set `method` to `'direct'`.
- **Prerequisites:** Game running, character exists.
- **Params:**
  ```json
  {
    "character_path": "Player",
    "target": [0, 0, 0],
    "method": "direct"
  }
  ```
- **Expected result:** Same behavior as scenario 5.1. Character moves directly.

#### 5.4 Explicit pathfind method
- **Description:** Explicitly set `method` to `'pathfind'`.
- **Prerequisites:** Game running, character with NavigationAgent, navmesh baked.
- **Params:**
  ```json
  {
    "character_path": "Enemy",
    "target": [-20, 0, -15],
    "method": "pathfind"
  }
  ```
- **Expected result:** Character pathfinds to [-20, 0, -15]. Returns success.

#### 5.5 Missing required `character_path`
- **Description:** Call without `character_path`.
- **Params:**
  ```json
  {
    "target": [10, 0, 5]
  }
  ```
- **Expected result:** Zod validation error: `Required`.

#### 5.6 Missing required `target`
- **Description:** Call without `target`.
- **Params:**
  ```json
  {
    "character_path": "Player"
  }
  ```
- **Expected result:** Zod validation error: `Required`.

#### 5.7 Invalid `method` value
- **Description:** Use a method not in the enum.
- **Params:**
  ```json
  {
    "character_path": "Player",
    "target": [10, 0, 5],
    "method": "teleport"
  }
  ```
- **Expected result:** Zod validation error: invalid enum value. Expected `'direct' | 'pathfind'`.

#### 5.8 Invalid `target` — wrong length
- **Description:** Provide a 2-element target array instead of 3.
- **Params:**
  ```json
  {
    "character_path": "Player",
    "target": [10, 0]
  }
  ```
- **Expected result:** Zod validation error: tuple expects exactly 3 elements.

#### 5.9 Non-existent character node
- **Description:** Navigate a character that does not exist in the scene.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "character_path": "NonExistentCharacter",
    "target": [0, 0, 0]
  }
  ```
- **Expected result:** Error from Godot: node not found.

#### 5.10 Pathfinding without navigation mesh
- **Description:** Use `method: 'pathfind'` when no navigation mesh is baked.
- **Prerequisites:** Game running, character exists but no navmesh.
- **Params:**
  ```json
  {
    "character_path": "Player",
    "target": [100, 0, 100],
    "method": "pathfind"
  }
  ```
- **Expected result:** Error from Godot: navigation failed or no navigation map available.

#### 5.11 Large target coordinates
- **Description:** Navigate to extremely large coordinates.
- **Prerequisites:** Game running, character exists.
- **Params:**
  ```json
  {
    "character_path": "Player",
    "target": [999999, 999999, 999999],
    "method": "direct"
  }
  ```
- **Expected result:** Tool succeeds in issuing the command. Godot may handle gracefully.

#### 5.12 Floating-point target coordinates
- **Description:** Navigate to a position with floating-point values.
- **Prerequisites:** Game running, character exists.
- **Params:**
  ```json
  {
    "character_path": "Player",
    "target": [10.5, 2.3, -7.8],
    "method": "direct"
  }
  ```
- **Expected result:** Character moves to [10.5, 2.3, -7.8]. Returns success.

---

## Tool: `godot_assert_game_state`

**Description:** Assert multiple game state conditions simultaneously.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `conditions` | `array` of objects | **Yes** | – | List of conditions that must all pass |

**Condition object fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `path` | `string` | **Yes** | – | Node path |
| `property` | `string` | **Yes** | – | Property name to check |
| `expected` | `unknown` | **Yes** | – | Expected value |
| `operator` | `string` | No | – | Comparison operator: `'=='`, `'!='`, `'>'`, `'<'`, `'>='`, `'<='`, `'contains'` |

**Handler:** Calls `callGodot(bridge, 'assert_game_state', args)`. Expected return: boolean result per condition. If any condition fails, the tool may return an error.

### Test Scenarios

#### 6.1 Single condition — default operator (==)
- **Description:** Assert a single property value on a node.
- **Prerequisites:** Game running, node exists with known property.
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
- **Expected result:** Returns success. Condition passes.

#### 6.2 Single condition — explicit `==` operator
- **Description:** Assert equality with the explicit `==` operator.
- **Prerequisites:** Game running, node exists.
- **Params:**
  ```json
  {
    "conditions": [
      {
        "path": "Player",
        "property": "position",
        "expected": [0, 0, 0],
        "operator": "=="
      }
    ]
  }
  ```
- **Expected result:** Returns success if position matches.

#### 6.3 `!=` operator
- **Description:** Assert that a property does NOT equal a given value.
- **Prerequisites:** Game running, node exists.
- **Params:**
  ```json
  {
    "conditions": [
      {
        "path": "Player",
        "property": "visible",
        "expected": false,
        "operator": "!="
      }
    ]
  }
  ```
- **Expected result:** Returns success if the player IS visible (true != false). Returns error if the player is invisible.

#### 6.4 `>` operator
- **Description:** Assert a numeric property is greater than a value.
- **Prerequisites:** Game running, node with numeric property.
- **Params:**
  ```json
  {
    "conditions": [
      {
        "path": "Player",
        "property": "health",
        "expected": 0,
        "operator": ">"
      }
    ]
  }
  ```
- **Expected result:** Returns success if health > 0.

#### 6.5 `<` operator
- **Description:** Assert a numeric property is less than a value.
- **Prerequisites:** Game running, node with numeric property.
- **Params:**
  ```json
  {
    "conditions": [
      {
        "path": "Player",
        "property": "speed",
        "expected": 100,
        "operator": "<"
      }
    ]
  }
  ```
- **Expected result:** Returns success if speed < 100.

#### 6.6 `>=` operator
- **Description:** Assert a numeric property is greater than or equal to a value.
- **Prerequisites:** Game running.
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
- **Expected result:** Returns success if score >= 10.

#### 6.7 `<=` operator
- **Description:** Assert a numeric property is less than or equal to a value.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "conditions": [
      {
        "path": "Player",
        "property": "ammo",
        "expected": 30,
        "operator": "<="
      }
    ]
  }
  ```
- **Expected result:** Returns success if ammo <= 30.

#### 6.8 `contains` operator
- **Description:** Assert a property contains a substring or element.
- **Prerequisites:** Game running, node with a string or array property.
- **Params:**
  ```json
  {
    "conditions": [
      {
        "path": "Player",
        "property": "name",
        "expected": "Player",
        "operator": "contains"
      }
    ]
  }
  ```
- **Expected result:** Returns success if the name contains "Player".

#### 6.9 Multiple conditions — all pass
- **Description:** Assert multiple conditions where all are expected to pass.
- **Prerequisites:** Game running, node exists with known properties.
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
        "property": "health",
        "expected": 0,
        "operator": ">"
      },
      {
        "path": "Player",
        "property": "name",
        "expected": "Player",
        "operator": "contains"
      }
    ]
  }
  ```
- **Expected result:** Returns success. All conditions pass.

#### 6.10 Multiple conditions — one fails
- **Description:** Assert multiple conditions where one is expected to fail.
- **Prerequisites:** Game running, Player node exists.
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
        "expected": 999999,
        "operator": "=="
      }
    ]
  }
  ```
- **Expected result:** Returns error indicating which condition failed (the health check). The visible check passes.

#### 6.11 Missing required `conditions`
- **Description:** Call without the `conditions` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error: `Required`.

#### 6.12 Empty conditions array
- **Description:** Pass an empty conditions array.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "conditions": []
  }
  ```
- **Expected result:** May return success (trivially all conditions pass) or an error. Should not crash.

#### 6.13 Condition missing `expected` field
- **Description:** Omit the required `expected` field from a condition.
- **Prerequisites:** Game running.
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
- **Expected result:** Zod validation error: `expected` is required (schema uses `z.unknown()` without `.optional()`, but `z.unknown()` accepts `undefined` — verify behavior; may pass validation and cause runtime error).

#### 6.14 Invalid operator string
- **Description:** Use an operator not listed in the description.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "conditions": [
      {
        "path": "Player",
        "property": "visible",
        "expected": true,
        "operator": "matches_regex"
      }
    ]
  }
  ```
- **Expected result:** Zod passes (operator is just `z.string().optional()`). Godot handler may reject with "unknown operator" error.

#### 6.15 Non-existent node path
- **Description:** Assert a condition on a node that does not exist.
- **Prerequisites:** Game running.
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
- **Expected result:** Error from Godot: node not found.

#### 6.16 Non-existent property
- **Description:** Assert a property that does not exist on the node.
- **Prerequisites:** Game running, node exists.
- **Params:**
  ```json
  {
    "conditions": [
      {
        "path": "Player",
        "property": "non_existent_property",
        "expected": true
      }
    ]
  }
  ```
- **Expected result:** Error from Godot: property not found on node.

---

## Tool: `godot_wait_for_game_event`

**Description:** Wait for a specific game event (signal, node creation, property change) with timeout.

**Parameters:**

| Parameter | Type | Required | Default | Constraints | Description |
|-----------|------|----------|---------|-------------|-------------|
| `event` | `string` | **Yes** | – | – | Event to wait for. Prefix format: `'signal:NodePath:SignalName'`, `'node:NodePath'`, or `'property:NodePath:PropName:ExpectedValue'` |
| `timeout` | `number` (int) | No | `5000` | `min: 1, max: 30000` | Timeout in milliseconds |

**Handler:** Calls `callGodot(bridge, 'wait_for_game_event', args)`. Expected return: event data on success, timeout error on failure.

### Test Scenarios

#### 7.1 Signal event — default timeout
- **Description:** Wait for a signal emission from a node.
- **Prerequisites:** Game running, node exists and emits the signal within timeout.
- **Params:**
  ```json
  {
    "event": "signal:Player:ready"
  }
  ```
- **Expected result:** Returns success when the signal fires. Includes signal data if any.

#### 7.2 Node event — wait for node creation
- **Description:** Wait for a specific node to appear in the scene tree.
- **Prerequisites:** Game running. The node will be created during gameplay (e.g., spawned enemy).
- **Params:**
  ```json
  {
    "event": "node:EnemySpawner/Enemy_1"
  }
  ```
- **Expected result:** Returns success when the node appears. Times out if the node never appears within 5000ms.

#### 7.3 Property event — wait for property change
- **Description:** Wait for a property to reach a specific value.
- **Prerequisites:** Game running, node exists, property will change to the expected value.
- **Params:**
  ```json
  {
    "event": "property:Player:health:0"
  }
  ```
- **Expected result:** Returns success when `health` equals `0`. Times out if it never reaches that value.

#### 7.4 Custom timeout — short
- **Description:** Wait for an event with a very short timeout.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "event": "signal:Player:custom_signal",
    "timeout": 100
  }
  ```
- **Expected result:** If the signal fires within 100ms, returns success. Otherwise, returns timeout error.

#### 7.5 Custom timeout — long (boundary: max)
- **Description:** Wait for an event with maximum timeout (30 seconds).
- **Prerequisites:** Game running, event will occur within 30 seconds.
- **Params:**
  ```json
  {
    "event": "signal:Player:delayed_signal",
    "timeout": 30000
  }
  ```
- **Expected result:** Waits up to 30 seconds. Returns success if event occurs; timeout error otherwise. **Note:** `[SLOW]`.

#### 7.6 Custom timeout — minimum boundary
- **Description:** Wait with minimum timeout (1ms).
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "event": "signal:Player:immediate_signal",
    "timeout": 1
  }
  ```
- **Expected result:** Almost certain to timeout unless the signal fires on the same frame. Returns timeout error.

#### 7.7 Timeout expiration
- **Description:** Wait for an event that never occurs within the timeout period.
- **Prerequisites:** Game running, no such event will fire.
- **Params:**
  ```json
  {
    "event": "signal:Player:never_emitted_signal",
    "timeout": 2000
  }
  ```
- **Expected result:** After 2000ms, returns timeout error.

#### 7.8 Missing required `event`
- **Description:** Call without the `event` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error: `Required`.

#### 7.9 Invalid event format — no prefix
- **Description:** Provide an event string without the required prefix format.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "event": "just_a_plain_string"
  }
  ```
- **Expected result:** Zod passes (any string is valid). Godot handler returns error about unrecognized event format.

#### 7.10 Invalid event format — unknown prefix
- **Description:** Use an unrecognized prefix.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "event": "animation:Player:walk:finished"
  }
  ```
- **Expected result:** Godot handler returns error: unknown event prefix `'animation'`.

#### 7.11 Signal event — malformed (too few parts)
- **Description:** Signal event with insufficient colon-separated parts.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "event": "signal:Player"
  }
  ```
- **Expected result:** Godot handler returns error: malformed signal event (needs `signal:NodePath:SignalName`).

#### 7.12 Timeout below minimum
- **Description:** Set timeout to 0 (below `min: 1`).
- **Params:**
  ```json
  {
    "event": "signal:Player:ready",
    "timeout": 0
  }
  ```
- **Expected result:** Zod validation error: `Number must be greater than or equal to 1`.

#### 7.13 Timeout above maximum
- **Description:** Set timeout to 30001 (above `max: 30000`).
- **Params:**
  ```json
  {
    "event": "signal:Player:ready",
    "timeout": 30001
  }
  ```
- **Expected result:** Zod validation error: `Number must be less than or equal to 30000`.

#### 7.14 Non-integer timeout
- **Description:** Set timeout to a float like `100.5`.
- **Params:**
  ```json
  {
    "event": "signal:Player:ready",
    "timeout": 100.5
  }
  ```
- **Expected result:** Zod validation error: expected integer (`.int()` constraint).

#### 7.15 Negative timeout
- **Description:** Set timeout to a negative value.
- **Params:**
  ```json
  {
    "event": "signal:Player:ready",
    "timeout": -500
  }
  ```
- **Expected result:** Zod validation error (negative fails `min(1)`).

#### 7.16 Property event — wait for any change (no expected value)
- **Description:** Use property format with only path and property, no expected value.
- **Prerequisites:** Game running.
- **Params:**
  ```json
  {
    "event": "property:Player:health"
  }
  ```
- **Expected result:** Godot handler may interpret this as "wait for any change to health" or return error for incomplete format. Verify behavior. The schema description shows `property:NodePath:PropName:ExpectedValue` with ExpectedValue appearing required.

---

## Summary

| # | Tool | Scenarios | Key Edge Cases |
|---|------|-----------|----------------|
| 1 | `godot_simulate_gameplay_scenario` | 11 | All 5 action types, no params, empty array, invalid action |
| 2 | `godot_record_gameplay` | 11 | Boundary durations (1, 300), both booleans false, float duration |
| 3 | `godot_replay_gameplay` | 10 | Boundary speeds (0.1, 10), missing recording_path, non-existent file |
| 4 | `godot_create_test_character` | 10 | With/without position, negative coords, wrong array length, non-number coords |
| 5 | `godot_navigate_character` | 12 | Both methods (direct, pathfind), no navmesh for pathfind, invalid method, float coords |
| 6 | `godot_assert_game_state` | 16 | All 7 operators, multi-condition (all pass / one fails), empty array, non-existent node/property |
| 7 | `godot_wait_for_game_event` | 16 | All 3 prefix formats, timeout boundaries (1, 30000), malformed formats, float timeout |
| **Total** | | **86** | |
