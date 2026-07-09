# Test Plan: Gameplay Automation Tools

**File:** `server/src/tools/gameplay_automation.ts`
**Total Tools:** 8
**Generated:** 2026-07-08
**Prerequisites:** Godot editor with MCP plugin active, game must be running for runtime tools

---

## Overview

This module provides 8 tools for automated gameplay testing. All tools delegate to `callGodot(bridge, methodName, args)`, which sends JSON-RPC requests over WebSocket to the Godot editor plugin. Tests verify schema validation on the MCP server side and correct parameter forwarding to Godot.

### Shared Type Definitions (from `shared-types.ts`)

| Type | Schema | Validation |
|------|--------|------------|
| `ScenePath` | `z.string()` | Required string, e.g. `"res://scenes/main.tscn"` |
| `NodePath` | `z.string()` | Required string, e.g. `"Player/Sprite2D"` or `""` for root |
| `Position3D` | `z.array(z.number()).length(3)` | Exactly 3 numbers: `[x, y, z]` |
| `Properties` | `z.record(z.unknown())` | Required `Record<string, unknown>` key-value pairs |

---

## Tool: `simulate_gameplay_scenario`

**Description:** Run a sequence of gameplay actions (input, wait, check) as an automated scenario.
**Godot Method:** `simulate_gameplay_scenario`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `scenario` | `Array<{action: string, params: Record<string,unknown>, wait?: number}>` | ✅ | — | Ordered list of gameplay actions |

Each element in `scenario`:
- `action` (string, required): Action type — `'input'`, `'wait'`, `'move'`, `'click'`, `'assert'`
- `params` (Record<string,unknown>, required): Parameters for the action (schema: `Properties`)
- `wait` (number, optional): Wait time in ms after this step

### Test Scenarios

#### Scenario 1: Single input action (happy path, minimum params)

**Description:** Execute a scenario with a single key input action.

```json
{
  "scenario": [
    {
      "action": "input",
      "params": { "keycode": "KEY_SPACE", "pressed": true }
    }
  ]
}
```

**Expected Result:**
- `callGodot` is invoked with method `"simulate_gameplay_scenario"`
- Args forwarded as `{ scenario: [{ action: "input", params: { keycode: "KEY_SPACE", pressed: true } }] }`
- Returns `ToolResult` with `content[{type:"text", text: <godot_response>}]`
- No `isError` flag set

**Notes:** Validates minimum viable scenario — one step, no wait.

---

#### Scenario 2: Multi-step scenario with waits (happy path, full params)

**Description:** Execute a sequence mixing input, wait, move, and assert actions with inter-step delays.

```json
{
  "scenario": [
    {
      "action": "input",
      "params": { "keycode": "KEY_RIGHT", "pressed": true },
      "wait": 500
    },
    {
      "action": "wait",
      "params": { "duration": 1000 }
    },
    {
      "action": "move",
      "params": { "path": "Player", "position": [10, 0, 0] }
    },
    {
      "action": "assert",
      "params": { "path": "Player", "property": "position", "expected": [10, 0, 0] }
    }
  ]
}
```

**Expected Result:**
- All 4 actions forwarded to Godot in order
- `wait` fields (500) attached to the first step
- Response from Godot returned as text content

**Notes:** Tests that nested `params` objects of varying shapes are all forwarded correctly.

---

#### Scenario 3: Empty scenario array (edge case)

**Description:** Provide an empty scenario array — should still be valid per Zod schema (no `.min(1)`).

```json
{
  "scenario": []
}
```

**Expected Result:**
- Schema validation passes (empty array is valid `z.array(...)`)
- `callGodot` invoked with `{ scenario: [] }`
- Godot's response depends on its handler (likely success with no-op)

**Notes:** Verify the Godot side handles an empty action list gracefully without panic/error.

---

#### Scenario 4: Missing required `action` field in scenario item (validation failure)

**Description:** Scenario item missing the `action` property.

```json
{
  "scenario": [
    {
      "params": { "keycode": "KEY_SPACE" }
    }
  ]
}
```

**Expected Result:**
- Zod validation should fail because `action` is required (no `.optional()`)
- Tool returns error result with `isError: true`
- Error message references missing `action` field

**Notes:** The `action` field in the nested object has no `.optional()`, so Zod should reject this.

---

#### Scenario 5: Scenario item with missing `params` (validation failure)

**Description:** Scenario item missing the required `params` field.

```json
{
  "scenario": [
    {
      "action": "input"
    }
  ]
}
```

**Expected Result:**
- Zod validation should fail — `params` is typed as `Properties` which is `z.record(z.unknown())` (required)
- Error result with `isError: true`

**Notes:** `Properties` is NOT optional. This verifies that the schema enforces `params` presence.

---

#### Scenario 6: Scenario with all action types and empty params

**Description:** Test each action type string with minimal/empty params.

```json
{
  "scenario": [
    { "action": "input", "params": {} },
    { "action": "wait", "params": {} },
    { "action": "move", "params": {} },
    { "action": "click", "params": {} },
    { "action": "assert", "params": {} }
  ]
}
```

**Expected Result:**
- Schema validation passes (all fields present, empty objects are valid `Record<string,unknown>`)
- All 5 steps forwarded to Godot
- Godot handler decides how to interpret empty params per action type

**Notes:** Tests that schema doesn't validate action-specific params — that's Godot's job.

---

### Related Tools

| Relationship | Tool | Purpose |
|--------------|------|---------|
| **Before** | `set_input_action` (input.ts) | Ensure input actions like `move_right` exist in InputMap before referencing them in scenarios |
| **Before** | `create_test_character` (this file) | Create the character that scenario actions will target |
| **After** | `assert_game_state` (this file) | Verify game state after scenario execution |
| **After** | `get_test_report` (testing.ts) | Aggregate results if scenario was part of a test suite |

---

## Tool: `record_gameplay`

**Description:** Record gameplay for a duration, capturing input events and/or game state.
**Godot Method:** `record_gameplay`

### Parameters

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `duration` | `number` | ❌ | `10` | `min(1)`, `max(300)` | Recording duration in seconds |
| `include_input` | `boolean` | ❌ | `true` | — | Record input events |
| `include_state` | `boolean` | ❌ | `false` | — | Record game state snapshots |

### Test Scenarios

#### Scenario 1: Default parameters (no args, all defaults)

**Description:** Call with no parameters — should use all defaults.

```json
{}
```

**Expected Result:**
- `callGodot` invoked with `{}` (empty args)
- Godot receives defaults: `duration=10`, `include_input=true`, `include_state=false`
- Returns recording data/path

**Notes:** Since all params are optional with defaults, this should succeed without any args.

---

#### Scenario 2: Full explicit parameters

**Description:** Record for 30 seconds, capturing both input and state.

```json
{
  "duration": 30,
  "include_input": true,
  "include_state": true
}
```

**Expected Result:**
- `callGodot` invoked with `{ duration: 30, include_input: true, include_state: true }`
- Recording captures both input events and state snapshots
- Returns recording data including both event types

**Notes:** Tests combination of all three parameters at non-default values.

---

#### Scenario 3: Minimum duration boundary

**Description:** Record for exactly 1 second (minimum allowed).

```json
{
  "duration": 1,
  "include_input": false,
  "include_state": true
}
```

**Expected Result:**
- `callGodot` invoked with `{ duration: 1, include_input: false, include_state: true }`
- Recording lasts exactly 1 second
- Only state snapshots captured (no input)

**Notes:** Tests `.min(1)` boundary — `duration=0` would fail, `duration=1` should pass.

---

#### Scenario 4: Maximum duration boundary

**Description:** Record for exactly 300 seconds (maximum allowed).

```json
{
  "duration": 300
}
```

**Expected Result:**
- `callGodot` invoked with `{ duration: 300 }`
- Longest possible recording session

**Notes:** Tests `.max(300)` boundary — `duration=301` would fail.

---

#### Scenario 5: Duration below minimum (validation failure)

**Description:** Attempt to record for 0 seconds.

```json
{
  "duration": 0
}
```

**Expected Result:**
- Zod validation fails — `.min(1)` rejects `0`
- Error result with `isError: true`

**Notes:** Boundary test — ensures schema enforces minimum.

---

#### Scenario 6: Duration above maximum (validation failure)

**Description:** Attempt to record for 600 seconds.

```json
{
  "duration": 600
}
```

**Expected Result:**
- Zod validation fails — `.max(300)` rejects `600`
- Error result with `isError: true`

---

#### Scenario 7: Negative duration (validation failure)

```json
{
  "duration": -5
}
```

**Expected Result:**
- Zod validation fails — `.min(1)` rejects negative numbers
- Error result with `isError: true`

---

### Related Tools

| Relationship | Tool | Purpose |
|--------------|------|---------|
| **Before** | `create_test_character` (this file) | Set up game state to record |
| **Before** | `simulate_gameplay_scenario` (this file) | Run actions to be captured |
| **After** | `replay_gameplay` (this file) | Replay the recorded session using the returned `recording_path` |

---

## Tool: `replay_gameplay`

**Description:** Replay a previously recorded gameplay session.
**Godot Method:** `replay_gameplay`

### Parameters

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `recording_path` | `string` | ✅ | — | — | Path to the recording file |
| `speed` | `number` | ❌ | `1.0` | `min(0.1)`, `max(10)` | Playback speed multiplier |

### Test Scenarios

#### Scenario 1: Replay with minimum required params

**Description:** Replay a recording using only the required `recording_path`.

```json
{
  "recording_path": "res://recordings/session_001.rec"
}
```

**Expected Result:**
- `callGodot` invoked with `{ recording_path: "res://recordings/session_001.rec" }`
- Default speed `1.0` applied by Godot
- Returns success/failure based on file existence

**Notes:** Tests minimum required params. The recording must exist (created by prior `record_gameplay` call).

---

#### Scenario 2: Replay at 2x speed

**Description:** Fast replay at double speed.

```json
{
  "recording_path": "res://recordings/session_001.rec",
  "speed": 2.0
}
```

**Expected Result:**
- `callGodot` invoked with `{ recording_path: "res://recordings/session_001.rec", speed: 2.0 }`
- Replay completes in roughly half the time

---

#### Scenario 3: Replay at minimum speed (0.1x — slow motion)

```json
{
  "recording_path": "res://recordings/session_001.rec",
  "speed": 0.1
}
```

**Expected Result:**
- `callGodot` invoked with `{ recording_path: "res://recordings/session_001.rec", speed: 0.1 }`
- Very slow playback

**Notes:** Tests `.min(0.1)` boundary.

---

#### Scenario 4: Replay at maximum speed (10x)

```json
{
  "recording_path": "res://recordings/session_001.rec",
  "speed": 10
}
```

**Expected Result:**
- `callGodot` invoked with `{ recording_path: "res://recordings/session_001.rec", speed: 10 }`
- Maximum speed playback

**Notes:** Tests `.max(10)` boundary.

---

#### Scenario 5: Missing required `recording_path` (validation failure)

```json
{
  "speed": 1.5
}
```

**Expected Result:**
- Zod validation fails — `recording_path` is required
- Error result with `isError: true`

---

#### Scenario 6: Speed below minimum (validation failure)

```json
{
  "recording_path": "res://recordings/session_001.rec",
  "speed": 0.05
}
```

**Expected Result:**
- Zod validation fails — `.min(0.1)` rejects `0.05`
- Error result with `isError: true`

---

#### Scenario 7: Speed above maximum (validation failure)

```json
{
  "recording_path": "res://recordings/session_001.rec",
  "speed": 15
}
```

**Expected Result:**
- Zod validation fails — `.max(10)` rejects `15`
- Error result with `isError: true`

---

### Required Call Sequence

⚠️ **This tool requires a recording to exist.** Execute this sequence before testing:

1. Call `record_gameplay` → returns recording data/path
2. Use the returned path as `recording_path` in `replay_gameplay`

### Related Tools

| Relationship | Tool | Purpose |
|--------------|------|---------|
| **Before (REQUIRED)** | `record_gameplay` (this file) | Create the recording file to replay |
| **Before** | `create_test_character` (this file) | Set up initial game state before recording |
| **After** | `assert_game_state` (this file) | Verify game state matches after replay |

---

## Tool: `create_test_character`

**Description:** Create a test character in the scene at a specified position.
**Godot Method:** `create_test_character`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `scene_path` | `string` (ScenePath) | ✅ | — | Path to the character scene to instantiate |
| `position` | `[number, number, number]` (Position3D) | ❌ | — | World position `[x, y, z]` |

### Test Scenarios

#### Scenario 1: Create character at default position (no position specified)

**Description:** Instantiate a character scene without specifying position.

```json
{
  "scene_path": "res://characters/player.tscn"
}
```

**Expected Result:**
- `callGodot` invoked with `{ scene_path: "res://characters/player.tscn" }`
- Character created at Godot's default origin `(0, 0, 0)` or scene's embedded position
- Returns some reference (node path or instance ID)

**Notes:** `position` is `.optional()`, so omitting it is valid. Godot decides the default position.

---

#### Scenario 2: Create character at specific position

**Description:** Instantiate a character at explicit world coordinates.

```json
{
  "scene_path": "res://characters/enemy.tscn",
  "position": [10.5, 0, -5.0]
}
```

**Expected Result:**
- `callGodot` invoked with `{ scene_path: "res://characters/enemy.tscn", position: [10.5, 0, -5.0] }`
- Character placed at `(10.5, 0, -5.0)` in world space
- Returns node path or success confirmation

---

#### Scenario 3: Create character at origin

```json
{
  "scene_path": "res://characters/npc.tscn",
  "position": [0, 0, 0]
}
```

**Expected Result:**
- Character created at world origin
- Validates that zero-coordinates are accepted (not filtered out)

---

#### Scenario 4: Missing required `scene_path` (validation failure)

```json
{
  "position": [5, 0, 0]
}
```

**Expected Result:**
- Zod validation fails — `scene_path` is required
- Error result with `isError: true`

---

#### Scenario 5: Invalid position — wrong array length (validation failure)

```json
{
  "scene_path": "res://characters/player.tscn",
  "position": [1, 2]
}
```

**Expected Result:**
- Zod validation fails — `Position3D` requires exactly 3 elements (`.length(3)`)
- Error result with `isError: true`

**Notes:** `Position3D = z.array(z.number()).length(3)` — a 2-element array is rejected.

---

#### Scenario 6: Invalid position — non-numeric array (validation failure)

```json
{
  "scene_path": "res://characters/player.tscn",
  "position": ["x", "y", "z"]
}
```

**Expected Result:**
- Zod validation fails — `z.array(z.number())` rejects string elements
- Error result with `isError: true`

---

### Related Tools

| Relationship | Tool | Purpose |
|--------------|------|---------|
| **Before** | `create_scene` (scene.ts) | Create the target scene if it doesn't exist |
| **After** | `navigate_character` (this file) | Move the created character |
| **After** | `assert_game_state` (this file) | Verify character properties after creation |
| **After** | `delete_test_character` (this file) | Clean up the created character |
| **After** | `simulate_gameplay_scenario` (this file) | Run gameplay actions against the character |

---

## Tool: `delete_test_character`

**Description:** Delete test character(s) from the scene and clean up the internal tracking array. Can target a specific character by path or delete all tracked test characters.
**Godot Method:** `delete_test_character`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `character_path` | `string` (NodePath) | ❌ | `""` | Node path to a specific test character. If omitted, all test characters are deleted. |

### Test Scenarios

#### Scenario 1: Delete a specific test character by path (happy path)

**Description:** Create a test character, then delete it by its returned path.

```json
{
  "character_path": "/root/Main/TestCharacter_0"
}
```

**Expected Result:**
- `callGodot` invoked with `{ character_path: "/root/Main/TestCharacter_0" }`
- Character removed from scene tree via `queue_free()`
- Path removed from internal `_test_characters` array
- Returns `deleted` array with the path, `remaining` count

**Notes:** Requires a test character to already exist (created by `create_test_character`).

---

#### Scenario 2: Delete all test characters (no path specified)

**Description:** Omit `character_path` to delete all tracked test characters at once.

```json
{}
```

**Expected Result:**
- `callGodot` invoked with `{}` (empty args)
- All test characters in `_test_characters` are removed from scene tree
- `_test_characters` array is cleared
- Returns `deleted` array with all paths, `remaining: 0`

**Notes:** If no test characters exist, returns success with empty `deleted` array and message "No test characters to delete".

---

#### Scenario 3: Delete specific character that does not exist (validation failure)

**Description:** Provide a path to a node that does not exist in the scene.

```json
{
  "character_path": "/root/Main/NonExistentCharacter"
}
```

**Expected Result:**
- `callGodot` invoked with the path
- Godot handler returns error: `"Character not found: /root/Main/NonExistentCharacter"`
- Error result with `isError: true`

---

#### Scenario 4: Delete a node that is not a test character (validation failure)

**Description:** Provide a path to a real node that was NOT created by `create_test_character`.

```json
{
  "character_path": "/root/Main/Player"
}
```

**Expected Result:**
- Node exists but is not in `_test_characters`
- Godot handler returns error: `"Node is not a test character: /root/Main/Player"`
- Error result with `isError: true`

---

#### Scenario 5: Delete all when some characters were already removed (edge case)

**Description:** Test characters exist in `_test_characters` but some nodes were already freed externally.

```json
{}
```

**Expected Result:**
- Godot handler iterates `_test_characters`
- Nodes that still exist are freed; missing nodes are reported in `not_found` array
- Returns `deleted` (paths actually freed) and `not_found` (paths whose nodes were gone)
- `_test_characters` is cleared regardless

**Notes:** Tests graceful handling of stale references.

---

#### Scenario 6: Empty string character_path (same as delete all)

```json
{
  "character_path": ""
}
```

**Expected Result:**
- Empty string is treated the same as omitting the parameter
- All test characters are deleted
- Returns success with full cleanup

---

### Required Call Sequence

⚠️ **Test characters must exist before deletion.** Execute:

1. Call `create_test_character` → character created and tracked in `_test_characters`
2. Use the returned path as `character_path` in `delete_test_character`

### Related Tools

| Relationship | Tool | Purpose |
|--------------|------|---------|
| **Before (REQUIRED)** | `create_test_character` (this file) | Create the test character to delete |
| **Before** | `assert_game_state` (this file) | Verify character exists before deletion |
| **After** | `assert_game_state` (this file) | Verify character is gone after deletion |

---

## Tool: `navigate_character`

**Description:** Move a character to a target position using direct movement or pathfinding.
**Godot Method:** `navigate_character`

### Parameters

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `character_path` | `string` (NodePath) | ✅ | — | — | Node path to the character |
| `target` | `[number, number, number]` (Position3D) | ✅ | — | Exactly 3 numbers | Target position `[x, y, z]` |
| `method` | `string` (enum) | ❌ | `"direct"` | `'direct'` or `'pathfind'` | Navigation method |

### Test Scenarios

#### Scenario 1: Direct movement (default method)

**Description:** Move a character directly to a target position.

```json
{
  "character_path": "Player",
  "target": [10, 0, 5]
}
```

**Expected Result:**
- `callGodot` invoked with `{ character_path: "Player", target: [10, 0, 5] }`
- Default method `"direct"` applied
- Character moves to `(10, 0, 5)`
- Returns success or movement data

---

#### Scenario 2: Pathfinding navigation (explicit method)

**Description:** Navigate using pathfinding (requires NavigationAgent).

```json
{
  "character_path": "Enemies/Goblin",
  "target": [50, 0, -30],
  "method": "pathfind"
}
```

**Expected Result:**
- `callGodot` invoked with `{ character_path: "Enemies/Goblin", target: [50, 0, -30], method: "pathfind" }`
- Godot uses NavigationAgent3D for pathfinding
- Returns path or success

**Notes:** `method` is `z.enum(['direct', 'pathfind'])` — only these two values are valid.

---

#### Scenario 3: Move to negative coordinates

```json
{
  "character_path": "Player",
  "target": [-100, 0, -200],
  "method": "direct"
}
```

**Expected Result:**
- Negative coordinates accepted (no schema restriction on sign)
- Character moves to negative world position

---

#### Scenario 4: Missing required `character_path` (validation failure)

```json
{
  "target": [10, 0, 0]
}
```

**Expected Result:**
- Zod validation fails — `character_path` is required (uses `NodePath` which is `z.string()`, no `.optional()`)
- Error result with `isError: true`

---

#### Scenario 5: Missing required `target` (validation failure)

```json
{
  "character_path": "Player"
}
```

**Expected Result:**
- Zod validation fails — `target` is required (no `.optional()`)
- Error result with `isError: true`

---

#### Scenario 6: Invalid method enum value (validation failure)

```json
{
  "character_path": "Player",
  "target": [10, 0, 0],
  "method": "teleport"
}
```

**Expected Result:**
- Zod validation fails — `z.enum(['direct', 'pathfind'])` rejects `"teleport"`
- Error result with `isError: true`

**Notes:** Tests that `method` is a strict enum, not an open string.

---

#### Scenario 7: Empty string character_path (boundary)

```json
{
  "character_path": "",
  "target": [0, 0, 0]
}
```

**Expected Result:**
- Schema validation passes — empty string is valid for `NodePath` (represents scene root per description)
- Behavior depends on Godot's handler logic for root-level navigation

**Notes:** Per `NodePath` description: `""` refers to the scene root itself.

---

### Required Call Sequence

⚠️ **Character must exist before navigating.** Execute:

1. Call `create_test_character` → character node created in scene
2. Use the returned/existing node path as `character_path` in `navigate_character`

### Related Tools

| Relationship | Tool | Purpose |
|--------------|------|---------|
| **Before (REQUIRED)** | `create_test_character` (this file) | Create the character to navigate |
| **Before** | `get_game_node_properties` (runtime.ts) | Verify character's current position before navigation |
| **After** | `assert_game_state` (this file) | Verify character reached the target position |
| **After** | `wait_for_game_event` (this file) | Wait for navigation-complete signal |

---

## Tool: `assert_game_state`

**Description:** Assert multiple game state conditions simultaneously.
**Godot Method:** `assert_game_state`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `conditions` | `Array<{path: string, property: string, expected: unknown, operator?: string}>` | ✅ | List of conditions that must all pass |

Each element in `conditions`:
- `path` (string, required): Node path
- `property` (string, required): Property name to check
- `expected` (unknown, required): Expected value
- `operator` (string, optional): Comparison operator — `==`, `!=`, `>`, `<`, `>=`, `<=`, `contains`

### Test Scenarios

#### Scenario 1: Single condition — equality check (happy path)

**Description:** Assert a single node property equals an expected value.

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

**Expected Result:**
- `callGodot` invoked with conditions array containing one item
- Default operator is `==` (per Godot handler)
- Returns pass/fail result

**Notes:** `operator` is optional — Godot's handler should default to `==`.

---

#### Scenario 2: Multiple conditions — different operators

**Description:** Assert multiple properties with various comparison operators.

```json
{
  "conditions": [
    {
      "path": "Player",
      "property": "position",
      "expected": [10, 0, 5],
      "operator": "=="
    },
    {
      "path": "Player",
      "property": "health",
      "expected": 50,
      "operator": ">="
    },
    {
      "path": "Enemies/Goblin",
      "property": "visible",
      "expected": false,
      "operator": "=="
    }
  ]
}
```

**Expected Result:**
- All 3 conditions forwarded to Godot
- Each evaluated with its specified operator
- Returns aggregate pass/fail

---

#### Scenario 3: String comparison with `contains` operator

```json
{
  "conditions": [
    {
      "path": "UI/Label",
      "property": "text",
      "expected": "Game Over",
      "operator": "contains"
    }
  ]
}
```

**Expected Result:**
- `contains` operator checks if the string property contains the expected substring
- Returns pass/fail

---

#### Scenario 4: Numeric comparison operators (`>`, `<`, `<=`)

```json
{
  "conditions": [
    {
      "path": "Player",
      "property": "health",
      "expected": 0,
      "operator": ">"
    },
    {
      "path": "Player",
      "property": "speed",
      "expected": 100,
      "operator": "<="
    },
    {
      "path": "Game",
      "property": "score",
      "expected": 500,
      "operator": ">="
    }
  ]
}
```

**Expected Result:**
- Each condition evaluated with its operator
- Aggregated result

---

#### Scenario 5: Empty conditions array (edge case)

```json
{
  "conditions": []
}
```

**Expected Result:**
- Schema validation passes (empty array is valid `z.array(...)`)
- `callGodot` invoked with `{ conditions: [] }`
- Godot returns success (vacuously true — no conditions to fail)

**Notes:** Semantically, zero conditions should always pass.

---

#### Scenario 6: Missing required `property` in condition item (validation failure)

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

**Expected Result:**
- Zod validation fails — `property` is required (no `.optional()`)
- Error result with `isError: true`

---

#### Scenario 7: Missing required `path` in condition item (validation failure)

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

**Expected Result:**
- Zod validation fails — `path` is required
- Error result with `isError: true`

---

#### Scenario 8: Null and complex expected values

**Description:** Test that `expected` accepts any type (`z.unknown()`).

```json
{
  "conditions": [
    {
      "path": "Player",
      "property": "script",
      "expected": null,
      "operator": "=="
    },
    {
      "path": "Player",
      "property": "position",
      "expected": { "x": 10, "y": 0, "z": 5 },
      "operator": "=="
    }
  ]
}
```

**Expected Result:**
- Schema validation passes — `expected` is `z.unknown()` so any value is valid
- Forwarded to Godot for comparison

**Notes:** Tests that complex objects and null are accepted for `expected`.

---

### Related Tools

| Relationship | Tool | Purpose |
|--------------|------|---------|
| **Before** | `create_test_character` (this file) | Set up game state to assert against |
| **Before** | `navigate_character` (this file) | Move characters before asserting position |
| **Before** | `simulate_gameplay_scenario` (this file) | Run actions before asserting results |
| **Related** | `assert_node_state` (testing.ts) | Single-condition alternative to this multi-condition tool |

---

## Tool: `wait_for_game_event`

**Description:** Wait for a specific game event (signal, node creation, property change) with timeout.
**Godot Method:** `wait_for_game_event`

### Parameters

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `event` | `string` | ✅ | — | — | Event to wait for (prefix format) |
| `timeout` | `number` (integer) | ❌ | `5000` | `min(1)`, `max(30000)` | Timeout in milliseconds |

**Event format prefixes:**
- `signal:NodePath:SignalName` — wait for a signal emission
- `node:NodePath` — wait for a node to appear
- `property:NodePath:PropName:ExpectedValue` — wait for a property to reach a value

### Test Scenarios

#### Scenario 1: Wait for a signal (happy path)

**Description:** Wait for the `body_entered` signal on a specific node.

```json
{
  "event": "signal:Area2D:body_entered"
}
```

**Expected Result:**
- `callGodot` invoked with `{ event: "signal:Area2D:body_entered" }`
- Default timeout `5000`ms applied
- Returns success when signal fires, or timeout error

---

#### Scenario 2: Wait for node creation with custom timeout

```json
{
  "event": "node:Enemy/Bullet",
  "timeout": 10000
}
```

**Expected Result:**
- `callGodot` invoked with `{ event: "node:Enemy/Bullet", timeout: 10000 }`
- Waits up to 10 seconds for the node to appear
- Returns success or timeout error

---

#### Scenario 3: Wait for property change

```json
{
  "event": "property:Player:health:0",
  "timeout": 3000
}
```

**Expected Result:**
- `callGodot` invoked with `{ event: "property:Player:health:0", timeout: 3000 }`
- Waits until `Player.health == 0` or 3-second timeout
- Returns success or timeout

---

#### Scenario 4: Minimum timeout boundary (1ms)

```json
{
  "event": "signal:Player:movement_finished",
  "timeout": 1
}
```

**Expected Result:**
- Schema validation passes — `.min(1)` allows `1`
- Extremely short timeout — likely times out immediately
- Returns timeout error from Godot

**Notes:** Tests `.min(1)` boundary. Practically useless but schema-valid.

---

#### Scenario 5: Maximum timeout boundary (30000ms = 30 seconds)

```json
{
  "event": "signal:Game:level_completed",
  "timeout": 30000
}
```

**Expected Result:**
- Schema validation passes — `.max(30000)` allows `30000`
- Longest possible wait

---

#### Scenario 6: Timeout at maximum + 1 (validation failure)

```json
{
  "event": "signal:Player:damaged",
  "timeout": 30001
}
```

**Expected Result:**
- Zod validation fails — `.max(30000)` rejects `30001`
- Error result with `isError: true`

---

#### Scenario 7: Zero timeout (validation failure)

```json
{
  "event": "signal:Player:damaged",
  "timeout": 0
}
```

**Expected Result:**
- Zod validation fails — `.min(1)` rejects `0`
- Error result with `isError: true`

---

#### Scenario 8: Non-integer timeout (validation failure)

```json
{
  "event": "signal:Player:damaged",
  "timeout": 500.5
}
```

**Expected Result:**
- Zod validation fails — `.int()` rejects non-integer `500.5`
- Error result with `isError: true`

**Notes:** The schema uses `.int()` — fractional milliseconds are rejected.

---

#### Scenario 9: Missing required `event` (validation failure)

```json
{
  "timeout": 5000
}
```

**Expected Result:**
- Zod validation fails — `event` is required
- Error result with `isError: true`

---

### Required Call Sequence

⚠️ **Depends on game state.** Typical sequences:

**Waiting for a signal after navigation:**
1. `create_test_character` → character exists
2. `navigate_character` → starts movement
3. `wait_for_game_event` with `"signal:Player:movement_finished"` → wait for arrival

**Waiting for node creation during gameplay:**
1. `simulate_gameplay_scenario` → triggers gameplay that spawns nodes
2. `wait_for_game_event` with `"node:Enemies/Boss"` → wait for boss spawn

**Waiting for property change after damage:**
1. `simulate_gameplay_scenario` with attack actions
2. `wait_for_game_event` with `"property:Enemy:health:0"` → wait for enemy death

### Related Tools

| Relationship | Tool | Purpose |
|--------------|------|---------|
| **Before** | `create_test_character` (this file) | Ensure nodes exist that emit signals |
| **Before** | `navigate_character` (this file) | Trigger movement whose completion signal to wait for |
| **Before** | `simulate_gameplay_scenario` (this file) | Trigger events that cause the waited-for event |
| **After** | `assert_game_state` (this file) | Verify state after the event occurred |
| **Related** | `watch_signals` (runtime.ts) | Alternative that watches multiple signals for a duration |
| **Related** | `wait_for_node` (runtime.ts) | Simpler tool that only waits for node appearance |

---

## Cross-Tool Integration Test Sequences

### Sequence 1: Full Gameplay Test Lifecycle

A complete automated test from character creation to assertion:

```
Step 1: create_test_character
  → { scene_path: "res://characters/player.tscn", position: [0, 0, 0] }
  → Creates player at origin

Step 2: simulate_gameplay_scenario
  → { scenario: [
      { action: "input", params: { action: "move_right", pressed: true }, wait: 1000 },
      { action: "input", params: { action: "move_right", pressed: false } }
    ] }
  → Moves player right for 1 second

Step 3: wait_for_game_event
  → { event: "property:Player:position.x:10", timeout: 5000 }
  → Waits until player's X position reaches 10

Step 4: assert_game_state
  → { conditions: [
      { path: "Player", property: "position", expected: [10, 0, 0], operator: ">=" },
      { path: "Player", property": "visible", expected: true }
    ] }
  → Validates final state

Step 5: delete_test_character
  → { character_path: "TestCharacter_0" }
  → Cleans up the test character
```

### Sequence 2: Record and Replay Verification

Test that recorded gameplay can be replayed identically:

```
Step 1: create_test_character
  → { scene_path: "res://characters/player.tscn" }

Step 2: record_gameplay
  → { duration: 10, include_input: true, include_state: true }
  → Returns recording_path

Step 3: replay_gameplay
  → { recording_path: "<from step 2>", speed: 1.0 }
  → Replays exactly

Step 4: assert_game_state
  → { conditions: [{ path: "Player", property: "position", expected: <same as recording end>, operator: "==" }] }
  → Validates replay matches recording
```

### Sequence 3: Pathfinding Navigation with Event Wait

```
Step 1: create_test_character
  → { scene_path: "res://characters/npc.tscn", position: [0, 0, 0] }

Step 2: navigate_character
  → { character_path: "NPC", target: [100, 0, 50], method: "pathfind" }

Step 3: wait_for_game_event
  → { event: "signal:NAVIGATION_AGENT_3D:target_reached", timeout: 15000 }

Step 4: assert_game_state
  → { conditions: [
      { path: "NPC", property: "position", expected: [100, 0, 50], operator: "==" }
    ] }
```

---

## Schema Validation Summary

| Tool | Required Params | Optional Params with Defaults | Enum Constraints | Numeric Bounds |
|------|----------------|-------------------------------|------------------|----------------|
| `simulate_gameplay_scenario` | `scenario` (array) | — | — | — |
| `record_gameplay` | — | `duration` (10), `include_input` (true), `include_state` (false) | — | `duration`: 1–300 |
| `replay_gameplay` | `recording_path` | `speed` (1.0) | — | `speed`: 0.1–10 |
| `create_test_character` | `scene_path` | `position` | — | — |
| `delete_test_character` | — | `character_path` | — | — |
| `navigate_character` | `character_path`, `target` | `method` ("direct") | `method`: direct, pathfind | — |
| `assert_game_state` | `conditions` (array) | — | — | — |
| `wait_for_game_event` | `event` | `timeout` (5000) | — | `timeout`: 1–30000, integer |

---

## Notes for Test Execution Agents

1. **All tools require Godot editor connection.** If `callGodot` fails with "Godot editor is not connected", the bridge is down — this is infrastructure failure, not a tool bug.

2. **Runtime tools require game to be running.** Most tools in this file operate on the running game, not the editor scene. Ensure `Game > Play` is active in Godot before executing tests.

3. **Error format:** Failed calls return `{ content: [{ type: "text", text: "..." }], isError: true }`. Successful calls return `{ content: [{ type: "text", text: "..." }] }` without `isError`.

4. **Parameter forwarding:** All tools pass args directly to `callGodot` via `args as Record<string, unknown>`. The MCP server does NOT modify or filter params — what you send is what Godot receives.

5. **Schema validation happens before `callGodot`.** Invalid params (wrong types, missing required, out-of-range) are caught by Zod and never reach Godot. Test both the validation layer and the Godot integration layer.

6. **For `simulate_gameplay_scenario`:** The `params` field is `Record<string, unknown>` — it accepts ANY object shape. The action-specific validation happens in Godot's GDScript handler, not in the MCP server.

7. **For `assert_game_state`:** The `expected` field is `z.unknown()` — ANY value type is accepted. Comparison logic (including `contains` for strings) is implemented in Godot.

8. **For `wait_for_game_event`:** The `event` string is NOT validated by the MCP server for correct prefix format. Invalid formats like `"invalid_event"` will be caught by Godot's handler, not by Zod.
