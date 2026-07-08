# Testing Tools Test Plan

**Source file:** `server/src/tools/testing.ts`
**Godot bridge method prefix:** `testing/`
**Shared schemas used:** `NodePath`, `PropertyName`, `PropertyValue` (from `shared-types.ts`)
**Handler pattern:** All tools call `callGodot(bridge, 'testing/<action>', args)`

---

## Shared Type Definitions

| Schema | Type | Constraints |
|--------|------|-------------|
| `NodePath` | `string` | Path in scene tree, e.g. `"Player/Sprite2D"`, `""` for scene root |
| `PropertyName` | `string` | Property name, e.g. `"position"`, `"visible"` |
| `PropertyValue` | `unknown` (any) | No constraints — any serializable value |

---

## Tool: `run_test_scenario`

**Handler:** `callGodot(bridge, 'testing/run_scenario', args)`
**Description:** Run a multi-step test scenario against the running game.

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | `string` | No | `"Unnamed Scenario"` | Scenario name |
| `steps` | `array<Step>` | **Yes** | — | Ordered test steps |

**Step object:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `enum: "add_node" \| "delete_node" \| "set_property" \| "assert_node_state" \| "connect_signal" \| "wait"` | **Yes** | Step type |
| `params` | `Record<string, unknown>` | No | Parameters for this step |

**Note:** Steps intentionally use `z.record(z.unknown())` for `params` (no strict per-step-type schema). Validation of step-specific params happens on the Godot side. The `catchall(z.unknown())` on the step object allows extra fields.

### Test Scenarios

#### Scenario 1: Happy path — minimal valid scenario
- **Description:** Run with only required steps array, using a single `wait` step (simplest valid step type)
- **Params:**
  ```json
  {
    "steps": [
      {
        "type": "wait",
        "params": { "ms": 100 }
      }
    ]
  }
  ```
- **Expected result:** Success response from Godot. Scenario runs and completes (name defaults to "Unnamed Scenario").
- **Notes:** Prerequisite: game must be running.

#### Scenario 2: Happy path — named scenario with multiple step types
- **Description:** Run a multi-step scenario with a custom name and multiple different step types
- **Params:**
  ```json
  {
    "name": "Player spawn test",
    "steps": [
      {
        "type": "add_node",
        "params": { "parent": "", "type": "Node2D", "name": "TestNode" }
      },
      {
        "type": "wait",
        "params": { "ms": 200 }
      },
      {
        "type": "assert_node_state",
        "params": { "path": "TestNode", "property": "name", "expected": "TestNode" }
      },
      {
        "type": "delete_node",
        "params": { "path": "TestNode" }
      }
    ]
  }
  ```
- **Expected result:** Success response. All steps execute sequentially and pass.
- **Notes:** Tests the full lifecycle: create → wait → assert → delete.

#### Scenario 3: Missing required parameter — omit `steps`
- **Description:** Call without the required `steps` array
- **Params:** `{ "name": "My Scenario" }`
- **Expected result:** Zod validation error — `steps` is required. The call does not reach the Godot bridge.
- **Notes:** Tests that `steps` is properly marked as required.

#### Scenario 4: Missing required parameter — empty object
- **Description:** Call with an empty object
- **Params:** `{}`
- **Expected result:** Zod validation error — `steps` is required.
- **Notes:** Ensures the tool cannot be called without any steps.

#### Scenario 5: Step type — `add_node`
- **Description:** Use a step with `type: "add_node"` — creates a node during the scenario
- **Params:**
  ```json
  {
    "name": "Add node test",
    "steps": [
      {
        "type": "add_node",
        "params": { "parent": "", "type": "Label", "name": "TestLabel" }
      },
      {
        "type": "delete_node",
        "params": { "path": "TestLabel" }
      }
    ]
  }
  ```
- **Expected result:** Success. Node is created and then deleted.
- **Notes:** Add step must specify `parent`, `type`, `name` in params (Godot-side validation).

#### Scenario 6: Step type — `delete_node`
- **Description:** Use a step with `type: "delete_node"` — deletes a node during the scenario
- **Params:**
  ```json
  {
    "steps": [
      {
        "type": "add_node",
        "params": { "parent": "", "type": "Sprite2D", "name": "ToDelete" }
      },
      {
        "type": "delete_node",
        "params": { "path": "ToDelete" }
      }
    ]
  }
  ```
- **Expected result:** Success. Node created then deleted.
- **Notes:** Delete step must specify `path` in params.

#### Scenario 7: Step type — `set_property`
- **Description:** Use a step with `type: "set_property"` — sets a property on a node
- **Params:**
  ```json
  {
    "steps": [
      {
        "type": "add_node",
        "params": { "parent": "", "type": "Node2D", "name": "PropNode" }
      },
      {
        "type": "set_property",
        "params": { "path": "PropNode", "property": "position", "value": [100, 200] }
      },
      {
        "type": "assert_node_state",
        "params": { "path": "PropNode", "property": "position", "expected": [100, 200] }
      }
    ]
  }
  ```
- **Expected result:** Success. Property is set and assertion confirms the value.

#### Scenario 8: Step type — `assert_node_state`
- **Description:** Use a step with `type: "assert_node_state"` — asserts a node property value
- **Params:**
  ```json
  {
    "steps": [
      {
        "type": "add_node",
        "params": { "parent": "", "type": "Node2D", "name": "CheckNode" }
      },
      {
        "type": "assert_node_state",
        "params": { "path": "CheckNode", "property": "name", "expected": "CheckNode" }
      }
    ]
  }
  ```
- **Expected result:** Success. Assertion passes (node name matches).
- **Notes:** If assertion fails, the scenario step fails.

#### Scenario 9: Step type — `connect_signal`
- **Description:** Use a step with `type: "connect_signal"` — connects a signal between nodes
- **Params:**
  ```json
  {
    "steps": [
      {
        "type": "add_node",
        "params": { "parent": "", "type": "Timer", "name": "TickTimer" }
      },
      {
        "type": "add_node",
        "params": { "parent": "", "type": "Node2D", "name": "Listener" }
      },
      {
        "type": "connect_signal",
        "params": { "source": "TickTimer", "signal": "timeout", "target": "Listener", "method": "_dummy" }
      }
    ]
  }
  ```
- **Expected result:** Success. Signal connection is established.
- **Notes:** Connect step must specify `source`, `signal`, `target`, `method` in params.

#### Scenario 10: Step type — `wait`
- **Description:** Use a step with `type: "wait"` — waits for a duration during the scenario
- **Params:**
  ```json
  {
    "steps": [
      {
        "type": "wait",
        "params": { "ms": 500 }
      }
    ]
  }
  ```
- **Expected result:** Success. Scenario pauses for ~500ms then completes.
- **Notes:** Wait step must specify `ms` (milliseconds) in params.

#### Scenario 11: Invalid step type
- **Description:** Use a step with a `type` value not in the enum
- **Params:**
  ```json
  {
    "steps": [
      {
        "type": "invalid_step_type",
        "params": {}
      }
    ]
  }
  ```
- **Expected result:** Zod validation error — `type` must be one of the allowed enum values. Does not reach Godot.
- **Notes:** Validates enum constraint on step `type`.

#### Scenario 12: Steps without params
- **Description:** Use a step that omits the `params` field entirely
- **Params:**
  ```json
  {
    "steps": [
      {
        "type": "wait"
      }
    ]
  }
  ```
- **Expected result:** Accepted by Zod (params is optional). Godot-side may error if the step type requires specific params (e.g., wait needs `ms`).
- **Notes:** Tests that `params` is truly optional at the schema level.

#### Scenario 13: Empty steps array
- **Description:** Provide an empty steps array
- **Params:**
  ```json
  {
    "steps": []
  }
  ```
- **Expected result:** Accepted by Zod (array type matches). Godot-side behavior depends on implementation — may succeed trivially or return error.
- **Notes:** Edge case — empty test scenario.

#### Scenario 14: Extra fields on step objects
- **Description:** Include extra/additional fields beyond `type` and `params`
- **Params:**
  ```json
  {
    "steps": [
      {
        "type": "wait",
        "params": { "ms": 100 },
        "description": "This field is not in the schema",
        "tags": ["extra"]
      }
    ]
  }
  ```
- **Expected result:** Accepted by Zod (due to `catchall(z.unknown())`). Extra fields are passed through to Godot.
- **Notes:** Validates `catchall` behavior on step objects.

#### Scenario 15: Steps is not an array
- **Description:** Pass `steps` as a string instead of an array
- **Params:** `{ "steps": "not-an-array" }`
- **Expected result:** Zod validation error — expected array, received string.

#### Scenario 16: Large scenario — many steps
- **Description:** Run a scenario with a large number of steps (e.g., 50 wait steps)
- **Params:**
  ```json
  {
    "name": "Stress test scenario",
    "steps": [
      {"type": "wait", "params": {"ms": 10}},
      {"type": "wait", "params": {"ms": 10}},
      ... (repeat 50 times)
    ]
  }
  ```
- **Expected result:** Success or graceful error from Godot. Should not crash the MCP server.
- **Notes:** Boundary test for step array size.

---

## Tool: `assert_node_state`

**Handler:** `callGodot(bridge, 'testing/assert_state', args)`
**Description:** Assert that a node property matches an expected value.

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `NodePath` (string) | **Yes** | — | Node path in the running game |
| `property` | `PropertyName` (string) | **Yes** | — | Property name to check |
| `expected` | `PropertyValue` (any) | **Yes** | — | Expected value |
| `operator` | `string` | No | `"=="` | Comparison operator: `==`, `!=`, `>`, `<`, `>=`, `<=`, `contains` |

### Test Scenarios

#### Scenario 1: Happy path — default operator (`==`)
- **Description:** Assert a node property equals an expected value using the default `==` operator
- **Params:**
  ```json
  {
    "path": "Player",
    "property": "name",
    "expected": "Player"
  }
  ```
- **Expected result:** Success response. Property `name` equals `"Player"`.
- **Notes:** Prerequisites: game must be running and a node named `Player` must exist at the root.

#### Scenario 2: Operator — `!=`
- **Description:** Assert a property is NOT equal to a value
- **Params:**
  ```json
  {
    "path": "Player",
    "property": "name",
    "expected": "Enemy",
    "operator": "!="
  }
  ```
- **Expected result:** Success. `"Player"` ≠ `"Enemy"`.

#### Scenario 3: Operator — `>`
- **Description:** Assert a numeric property is greater than a value
- **Params:**
  ```json
  {
    "path": "Player",
    "property": "position:x",
    "expected": 0,
    "operator": ">"
  }
  ```
- **Expected result:** Success if `position.x > 0`.

#### Scenario 4: Operator — `<`
- **Description:** Assert a numeric property is less than a value
- **Params:**
  ```json
  {
    "path": "Player",
    "property": "position:y",
    "expected": 1000,
    "operator": "<"
  }
  ```
- **Expected result:** Success if `position.y < 1000`.

#### Scenario 5: Operator — `>=`
- **Description:** Assert a property is greater than or equal to a value
- **Params:**
  ```json
  {
    "path": "Player",
    "property": "scale:x",
    "expected": 1.0,
    "operator": ">="
  }
  ```
- **Expected result:** Success if `scale.x >= 1.0`.

#### Scenario 6: Operator — `<=`
- **Description:** Assert a property is less than or equal to a value
- **Params:**
  ```json
  {
    "path": "Player",
    "property": "rotation",
    "expected": 3.14,
    "operator": "<="
  }
  ```
- **Expected result:** Success if `rotation <= 3.14`.

#### Scenario 7: Operator — `contains`
- **Description:** Assert a string property contains a substring
- **Params:**
  ```json
  {
    "path": "Player",
    "property": "name",
    "expected": "lay",
    "operator": "contains"
  }
  ```
- **Expected result:** Success if node name contains `"lay"` (e.g., `"Player"` matches).
- **Notes:** Useful for partial string matching on names, paths, etc.

#### Scenario 8: Operator — `contains` on non-string (edge case)
- **Description:** Attempt `contains` operator on a numeric property
- **Params:**
  ```json
  {
    "path": "Player",
    "property": "position:x",
    "expected": 10,
    "operator": "contains"
  }
  ```
- **Expected result:** Error from Godot or false assertion. `contains` is semantically for string/substring operations.
- **Notes:** Tests Godot-side handling of mismatched operator/property-types.

#### Scenario 9: Missing required — omit `path`
- **Description:** Omit the required `path` parameter
- **Params:**
  ```json
  {
    "property": "visible",
    "expected": true
  }
  ```
- **Expected result:** Zod validation error — `path` is required.

#### Scenario 10: Missing required — omit `property`
- **Description:** Omit the required `property` parameter
- **Params:**
  ```json
  {
    "path": "Player",
    "expected": "Player"
  }
  ```
- **Expected result:** Zod validation error — `property` is required.

#### Scenario 11: Missing required — omit `expected`
- **Description:** Omit the required `expected` parameter
- **Params:**
  ```json
  {
    "path": "Player",
    "property": "visible"
  }
  ```
- **Expected result:** Zod validation error — `expected` is required. Note: `PropertyValue` is `z.unknown()` so the field must be present — it cannot be `undefined` but the value itself is unconstrained.

#### Scenario 12: Non-existent node path
- **Description:** Assert on a node path that does not exist in the running game
- **Params:**
  ```json
  {
    "path": "GhostNode",
    "property": "name",
    "expected": "GhostNode"
  }
  ```
- **Expected result:** Error response from Godot indicating node not found.
- **Notes:** Tests Godot-side node resolution failure.

#### Scenario 13: Non-existent property name
- **Description:** Assert on a property that does not exist on the target node
- **Params:**
  ```json
  {
    "path": "Player",
    "property": "non_existent_property",
    "expected": "anything"
  }
  ```
- **Expected result:** Error from Godot — property does not exist on the node.

#### Scenario 14: Invalid operator string
- **Description:** Use an operator that is not in the expected set
- **Params:**
  ```json
  {
    "path": "Player",
    "property": "name",
    "expected": "Player",
    "operator": "==="
  }
  ```
- **Expected result:** Accepted by Zod (operator is just a string, not an enum). Godot-side should return an error for unsupported operator.
- **Notes:** The schema uses `z.string()`, not `z.enum()`, so any string passes Zod validation.

#### Scenario 15: Boolean expected value
- **Description:** Assert a boolean property (e.g., `visible`)
- **Params:**
  ```json
  {
    "path": "Player",
    "property": "visible",
    "expected": true
  }
  ```
- **Expected result:** Success if node is visible.

#### Scenario 16: Array expected value (position)
- **Description:** Assert a Vector2 property with an array value
- **Params:**
  ```json
  {
    "path": "Player",
    "property": "position",
    "expected": [100, 200]
  }
  ```
- **Expected result:** Success if `position == Vector2(100, 200)`.

#### Scenario 17: Assert with nested property path
- **Description:** Use a nested property path like `position:x`
- **Params:**
  ```json
  {
    "path": "Player/Sprite2D",
    "property": "scale:x",
    "expected": 2.0
  }
  ```
- **Expected result:** Success if the nested property matches.
- **Notes:** Tests that dotted property paths work (Godot sub-property access).

#### Scenario 18: `null` expected value
- **Description:** Assert a property equals `null`
- **Params:**
  ```json
  {
    "path": "Player",
    "property": "process_material",
    "expected": null
  }
  ```
- **Expected result:** Success if the property is `null`.
- **Notes:** `PropertyValue` is `z.unknown()` and accepts `null`.

#### Scenario 19: `expected` value of wrong type triggers assertion failure
- **Description:** Assert that a boolean property equals a string — intentional mismatch
- **Params:**
  ```json
  {
    "path": "Player",
    "property": "visible",
    "expected": "yes"
  }
  ```
- **Expected result:** Godot returns an assertion failure (not MCP error). `visible` is boolean, `"yes"` is string — mismatch.
- **Notes:** Tests that type mismatches are caught by Godot's comparison logic.

---

## Tool: `assert_screen_text`

**Handler:** `callGodot(bridge, 'testing/assert_screen_text', args)`
**Description:** Assert that specific text appears on screen (OCR or UI element check).

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `text` | `string` | **Yes** | — | Text that should appear on screen |
| `should_exist` | `boolean` | No | `true` | Whether text should be present (`true`) or absent (`false`) |

### Test Scenarios

#### Scenario 1: Happy path — text should exist (default)
- **Description:** Assert that specific text appears on screen, using default `should_exist: true`
- **Params:**
  ```json
  {
    "text": "Start Game"
  }
  ```
- **Expected result:** Success if the text `"Start Game"` appears on screen. Failure otherwise.
- **Notes:** Prerequisites: game must be running and displaying UI or rendered text.

#### Scenario 2: Happy path — text should exist (explicit)
- **Description:** Assert text appears with explicit `should_exist: true`
- **Params:**
  ```json
  {
    "text": "Game Over",
    "should_exist": true
  }
  ```
- **Expected result:** Success if `"Game Over"` is visible on screen.

#### Scenario 3: `should_exist: false` — text should NOT appear
- **Description:** Assert that text is absent from the screen
- **Params:**
  ```json
  {
    "text": "ERROR",
    "should_exist": false
  }
  ```
- **Expected result:** Success if `"ERROR"` is NOT found on screen. Failure if it is found.

#### Scenario 4: `should_exist: false` — text IS on screen (negative test)
- **Description:** Assert that visible text is absent — expects failure
- **Params:**
  ```json
  {
    "text": "Start Game",
    "should_exist": false
  }
  ```
- **Expected result:** Assertion failure if `"Start Game"` is actually on screen.
- **Notes:** Useful for verifying that elements have been hidden/removed during tests.

#### Scenario 5: Missing required — omit `text`
- **Description:** Omit the required `text` parameter
- **Params:** `{ "should_exist": true }`
- **Expected result:** Zod validation error — `text` is required.

#### Scenario 6: Missing required — empty object
- **Description:** Call with an empty object
- **Params:** `{}`
- **Expected result:** Zod validation error — `text` is required.

#### Scenario 7: Empty string text
- **Description:** Pass an empty string as `text`
- **Params:**
  ```json
  {
    "text": ""
  }
  ```
- **Expected result:** Accepted by Zod (string, but empty). Godot-side behavior depends — may match nothing, may error.
- **Notes:** Edge case — empty search string.

#### Scenario 8: Very long text string
- **Description:** Pass a very long text string for assertion
- **Params:**
  ```json
  {
    "text": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  }
  ```
- **Expected result:** Accepted by Zod. Godot-side may handle or error depending on OCR/text matching limits.
- **Notes:** Boundary test for text length.

#### Scenario 9: Text with special characters
- **Description:** Assert text containing special characters (newlines, tabs, etc.)
- **Params:**
  ```json
  {
    "text": "Line 1\nLine 2\tIndented"
  }
  ```
- **Expected result:** Success if the multi-line/escaped text appears exactly as specified.
- **Notes:** Tests special character handling in text matching.

#### Scenario 10: Text with non-ASCII / Unicode characters
- **Description:** Assert text containing Unicode characters (e.g., emoji, accented characters)
- **Params:**
  ```json
  {
    "text": "日本語텍스트"
  }
  ```
- **Expected result:** Success if the Unicode text is found on screen.
- **Notes:** Tests CJK and other Unicode character handling.

#### Scenario 11: `should_exist` is not a boolean
- **Description:** Pass a string value for `should_exist`
- **Params:**
  ```json
  {
    "text": "Start",
    "should_exist": "yes"
  }
  ```
- **Expected result:** Zod validation error — expected `boolean`, received `string`.

---

## Tool: `run_stress_test`

**Handler:** `callGodot(bridge, 'testing/stress_test', args)`
**Description:** Run a stress test on the game (spawn entities, measure performance).

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `type` | `string` | No | `"Node2D"` | Node type to spawn |
| `count` | `integer` | No | `100` | Number of entities to spawn |
| `parent_path` | `string` | No | — | Parent node path for spawned entities |
| `properties` | `Record<string, unknown>` | No | — | Properties to set on each spawned entity |

### Test Scenarios

#### Scenario 1: Happy path — default parameters
- **Description:** Run a stress test with no parameters — spawns 100 Node2D entities with no parent
- **Params:** `{}`
- **Expected result:** Success response with performance metrics. 100 `Node2D` entities spawned at scene root.
- **Notes:** Prerequisite: game must be running. All params have defaults, so empty call is valid.

#### Scenario 2: Custom node type
- **Description:** Run stress test spawning a different node type
- **Params:**
  ```json
  {
    "type": "Sprite2D"
  }
  ```
- **Expected result:** Success. 100 `Sprite2D` entities spawned.

#### Scenario 3: Custom node type — 3D node
- **Description:** Spawn 3D node types
- **Params:**
  ```json
  {
    "type": "MeshInstance3D"
  }
  ```
- **Expected result:** Success. 100 `MeshInstance3D` entities spawned.

#### Scenario 4: Custom count — low
- **Description:** Spawn a small number of entities
- **Params:**
  ```json
  {
    "count": 1
  }
  ```
- **Expected result:** Success. Exactly 1 entity spawned.

#### Scenario 5: Custom count — medium
- **Description:** Spawn 500 entities
- **Params:**
  ```json
  {
    "count": 500
  }
  ```
- **Expected result:** Success with performance metrics for 500 spawns.
- **Notes:** Tests moderate stress level.

#### Scenario 6: Custom count — high (boundary)
- **Description:** Spawn a large number of entities
- **Params:**
  ```json
  {
    "count": 10000
  }
  ```
- **Expected result:** Success or graceful degradation. Should not crash the server.
- **Notes:** Boundary/stress test for count parameter.

#### Scenario 7: Custom count — zero
- **Description:** Spawn zero entities
- **Params:**
  ```json
  {
    "count": 0
  }
  ```
- **Expected result:** Accepted by Zod (`int` allows 0). Godot-side may succeed trivially or error.
- **Notes:** Edge case — zero spawns.

#### Scenario 8: Custom count — negative (invalid)
- **Description:** Use a negative count
- **Params:**
  ```json
  {
    "count": -5
  }
  ```
- **Expected result:** Accepted by Zod (`z.number().int()` allows negative values since there's no `.min(0)` constraint). Godot-side may error.
- **Notes:** The schema does NOT enforce non-negative. This is a potential validation gap.

#### Scenario 9: Count is a float (invalid)
- **Description:** Use a non-integer count
- **Params:**
  ```json
  {
    "count": 10.5
  }
  ```
- **Expected result:** Zod validation error — `.int()` rejects non-integer numbers.

#### Scenario 10: Count is a string (invalid)
- **Description:** Pass `count` as a string
- **Params:**
  ```json
  {
    "count": "50"
  }
  ```
- **Expected result:** Zod validation error — expected `number`, received `string`.

#### Scenario 11: With `parent_path` — valid parent
- **Description:** Spawn entities under a specific parent node
- **Params:**
  ```json
  {
    "parent_path": "World/Entities",
    "count": 10
  }
  ```
- **Expected result:** Success. 10 entities spawned as children of `World/Entities`.
- **Notes:** Prerequisite: parent node must exist.

#### Scenario 12: With `parent_path` — non-existent parent
- **Description:** Spawn entities under a non-existent parent
- **Params:**
  ```json
  {
    "parent_path": "FakeParent"
  }
  ```
- **Expected result:** Error from Godot — parent node not found.

#### Scenario 13: With `properties` — set properties on spawned entities
- **Description:** Spawn entities with custom properties
- **Params:**
  ```json
  {
    "type": "Sprite2D",
    "count": 5,
    "properties": {
      "position": [100, 200],
      "scale": [2, 2],
      "visible": false
    }
  }
  ```
- **Expected result:** Success. 5 `Sprite2D` entities spawned, each with position `(100,200)`, scale `(2,2)`, and `visible: false`.
- **Notes:** Tests that properties are applied to each spawned entity.

#### Scenario 14: With all parameters combined
- **Description:** Use all parameters together
- **Params:**
  ```json
  {
    "type": "Node3D",
    "count": 50,
    "parent_path": "Root",
    "properties": {
      "position": [0, 0, 0],
      "name": "StressEntity"
    }
  }
  ```
- **Expected result:** Success. 50 `Node3D` entities spawned under `Root`, each with specified properties.

#### Scenario 15: `properties` is not an object
- **Description:** Pass a string for `properties`
- **Params:**
  ```json
  {
    "properties": "invalid"
  }
  ```
- **Expected result:** Zod validation error — expected `object` (record), received `string`.

#### Scenario 16: Very long `type` string
- **Description:** Pass an excessively long node type name
- **Params:**
  ```json
  {
    "type": "A".repeat(10000)
  }
  ```
- **Expected result:** Accepted by Zod (just a string). Godot-side should error — no such node type exists.
- **Notes:** Boundary test for string length.

#### Scenario 17: Non-existent node type
- **Description:** Use a node type string that is not a valid Godot class
- **Params:**
  ```json
  {
    "type": "FakeNodeTypeThatDoesNotExist"
  }
  ```
- **Expected result:** Error from Godot — unrecognized node type.

---

## Tool: `get_test_report`

**Handler:** `callGodot(bridge, 'testing/get_report', args)` (no args)
**Description:** Get aggregated results of all test runs in this session.

### Parameters

*None.* This tool has an empty `inputSchema: {}` and takes no parameters.

### Test Scenarios

#### Scenario 1: Happy path — get report after running tests
- **Description:** Call after running one or more test scenarios/assertions to get aggregated results
- **Params:** `{}`
- **Expected result:** JSON response containing aggregated test results: total tests run, passed, failed, maybe list of individual test outcomes.
- **Notes:** Prerequisites: game must be running and at least one test scenario or assertion must have been executed. If no tests have been run, the report should show zero/null results.

#### Scenario 2: Happy path — get report before any tests (empty report)
- **Description:** Call immediately when no tests have been executed yet
- **Params:** `{}`
- **Expected result:** JSON response showing zero tests run (empty or "no tests" response). Should not error.
- **Notes:** Validates behavior with no prior test activity.

#### Scenario 3: Get report after mixed results (passes and failures)
- **Description:** After running some passing and some failing assertions, get the aggregate report
- **Params:** `{}`
- **Expected result:** Report accurately reflects the count of passed and failed assertions.
- **Notes:** Prerequisite: run a mix of passing and failing `assert_node_state` calls first.

#### Scenario 4: Get report after `run_test_scenario` with multiple steps
- **Description:** After running a multi-step scenario, verify the report includes it
- **Params:** `{}`
- **Expected result:** Report includes the scenario name and its step-by-step results.

#### Scenario 5: Get report after stress test
- **Description:** After running `run_stress_test`, verify the report includes it
- **Params:** `{}`
- **Expected result:** Report includes stress test results (entity count, spawn time, performance metrics).

#### Scenario 6: Call with unexpected params (should be ignored or error)
- **Description:** Pass parameters even though the schema is empty
- **Params:** `{ "extra_param": "should_be_ignored" }`
- **Expected result:** Depends on server framework behavior. The schema is `{}` which typically means params are stripped/ignored. The call should still succeed.
- **Notes:** Tests that the empty `inputSchema` is respected.

#### Scenario 7: Multiple calls — report is cumulative
- **Description:** Call `get_test_report` twice in the same session — verify it's idempotent or cumulative
- **Params:** `{}`
- **Expected result:** Second call returns the same cumulative results (tests are session-scoped, not cleared by reading).
- **Notes:** Tests that reading the report does not clear state.

---
