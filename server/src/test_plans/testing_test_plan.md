# Testing Tools — Test Plan

**Source file:** `server/src/tools/testing.ts`
**Shared types:** `server/src/tools/shared-types.ts`
**Number of tools:** 5
**Generated:** 2026-07-08

---

## Type Reference

| Zod schema | Underlying type | Description |
|---|---|---|
| `NodePath` | `z.string()` | Node path relative to current scene (e.g. `"Player"`, `"Player/Sprite2D"`, or `""` for root) |
| `PropertyName` | `z.string()` | Property name (e.g. `"position"`, `"visible"`) |
| `PropertyValue` | `z.unknown()` | Any serializable value |
| `z.enum(['add_node', 'delete_node', 'set_property', 'assert_node_state', 'connect_signal', 'wait'])` | enum string | Step type for scenario runner |
| `z.string()` | string | Generic string |
| `z.number().int()` | number (int) | Integer |
| `z.boolean()` | boolean | Boolean flag |
| `z.record(z.unknown())` | object | Key-value dictionary |

---

## Tool: `run_test_scenario`

**Description:** Run a multi-step test scenario against the running game
**Handler:** `callGodot(bridge, 'testing/run_scenario', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | string | No | `"Unnamed Scenario"` | Scenario name (default: "Unnamed Scenario") |
| `steps` | array of `{ type, params? }` | **Yes** | — | Ordered test steps |

**Step object structure:**

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `type` | enum: `'add_node'` \| `'delete_node'` \| `'set_property'` \| `'assert_node_state'` \| `'connect_signal'` \| `'wait'` | **Yes** | — | Step type |
| `params` | object (`z.record(z.unknown())`) | No | — | Parameters for this step |
| (catchall) | `z.unknown()` | No | — | Additional passthrough fields |

### Test Scenarios

#### Scenario 1: Happy path — basic multi-step scenario with name
- **Description:** Run a simple scenario with a name and several steps of different types. Game must be running.
- **Params:**
```json
{
  "name": "Basic Scenario",
  "steps": [
    { "type": "add_node", "params": { "parent_path": "", "type": "Sprite2D", "name": "TestSprite" } },
    { "type": "set_property", "params": { "path": "TestSprite", "property": "position", "value": [100, 200] } },
    { "type": "assert_node_state", "params": { "path": "TestSprite", "property": "visible", "expected": true } },
    { "type": "wait", "params": { "duration": 0.5 } },
    { "type": "delete_node", "params": { "path": "TestSprite" } }
  ]
}
```
- **Expected result:** Success. All steps execute in order. Sprite is created, positioned, asserted, a half-second wait occurs, then the sprite is deleted.

#### Scenario 2: Happy path — default name (no name param)
- **Description:** Run a scenario without specifying a name — should default to "Unnamed Scenario"
- **Params:**
```json
{
  "steps": [
    { "type": "add_node", "params": { "parent_path": "", "type": "Node2D", "name": "TestNode" } },
    { "type": "delete_node", "params": { "path": "TestNode" } }
  ]
}
```
- **Expected result:** Success. Scenario runs with the default name "Unnamed Scenario".

#### Scenario 3: Step type enum — `add_node`
- **Description:** Run a scenario with an `add_node` step
- **Params:**
```json
{
  "steps": [
    { "type": "add_node", "params": { "parent_path": "TestParent", "type": "Label", "name": "HelloLabel" } }
  ]
}
```
- **Expected result:** The step should create a Label node named "HelloLabel" under "TestParent". Requires a node named "TestParent" to exist in the running scene.

#### Scenario 4: Step type enum — `delete_node`
- **Description:** Run a scenario with a `delete_node` step
- **Params:**
```json
{
  "steps": [
    { "type": "add_node", "params": { "parent_path": "", "type": "Node2D", "name": "TempNode" } },
    { "type": "delete_node", "params": { "path": "TempNode" } }
  ]
}
```
- **Expected result:** Success. First creates TempNode, then deletes it.

#### Scenario 5: Step type enum — `set_property`
- **Description:** Run a scenario with a `set_property` step
- **Params:**
```json
{
  "steps": [
    { "type": "add_node", "params": { "parent_path": "", "type": "Sprite2D", "name": "PropSprite" } },
    { "type": "set_property", "params": { "path": "PropSprite", "property": "z_index", "value": 5 } }
  ]
}
```
- **Expected result:** Success. Sprite is created and its z_index is set to 5.

#### Scenario 6: Step type enum — `assert_node_state`
- **Description:** Run a scenario with an `assert_node_state` step
- **Params:**
```json
{
  "steps": [
    { "type": "add_node", "params": { "parent_path": "", "type": "Control", "name": "Ctrl" } },
    { "type": "assert_node_state", "params": { "path": "Ctrl", "property": "visible", "expected": true, "operator": "==" } }
  ]
}
```
- **Expected result:** Success. Node is created, then assert verifies it is visible. If assertion fails, the scenario should report failure.

#### Scenario 7: Step type enum — `connect_signal`
- **Description:** Run a scenario with a `connect_signal` step
- **Params:**
```json
{
  "steps": [
    { "type": "connect_signal", "params": { "source": "SomeNode", "signal": "pressed", "target": "OtherNode", "method": "_on_pressed" } }
  ]
}
```
- **Expected result:** The signal connection is established. Requires nodes "SomeNode" and "OtherNode" to exist, and the signal/method to be valid.

#### Scenario 8: Step type enum — `wait`
- **Description:** Run a scenario with a `wait` step for a specific duration
- **Params:**
```json
{
  "steps": [
    { "type": "add_node", "params": { "parent_path": "", "type": "Node2D", "name": "BeforeWait" } },
    { "type": "wait", "params": { "duration": 1.0 } },
    { "type": "add_node", "params": { "parent_path": "", "type": "Node2D", "name": "AfterWait" } }
  ]
}
```
- **Expected result:** Success. The wait step should pause execution for ~1 second before continuing.

#### Scenario 9: Edge — empty steps array
- **Description:** Run a scenario with an empty steps array
- **Params:**
```json
{
  "name": "EmptyScenario",
  "steps": []
}
```
- **Expected result:** Should succeed (no steps to execute is trivially successful). Test to verify Godot's behavior — may return success or a warning.

#### Scenario 10: Edge — missing required `steps` parameter
- **Description:** Call without the required `steps` parameter
- **Params:**
```json
{
  "name": "MissingSteps"
}
```
- **Expected result:** Zod validation error (steps is required).

#### Scenario 11: Edge — invalid step type
- **Description:** Use a step type not in the enum
- **Params:**
```json
{
  "steps": [
    { "type": "invalid_step_type", "params": {} }
  ]
}
```
- **Expected result:** Zod validation error. Type must be one of: add_node, delete_node, set_property, assert_node_state, connect_signal, wait.

#### Scenario 12: Edge — step without params (params is optional)
- **Description:** Run a scenario with a step that has no params field
- **Params:**
```json
{
  "steps": [
    { "type": "wait" }
  ]
}
```
- **Expected result:** Depends on Godot's handling. The wait step may default to 0s or error if no duration provided. Test to determine actual behavior.

#### Scenario 13: Edge — step with extra unknown fields
- **Description:** Include extra fields in a step (leverages `.catchall(z.unknown())`)
- **Params:**
```json
{
  "steps": [
    { "type": "wait", "params": { "duration": 0.1 }, "extra_field": "ignored_value", "another_extra": 42 }
  ]
}
```
- **Expected result:** Zod validation passes (catchall allows unknown fields). The extra fields should be silently ignored by the handler.

#### Scenario 14: Edge — step params as empty object
- **Description:** Provide an empty params object for each step type
- **Params:**
```json
{
  "steps": [
    { "type": "add_node", "params": {} },
    { "type": "delete_node", "params": {} },
    { "type": "set_property", "params": {} },
    { "type": "assert_node_state", "params": {} },
    { "type": "connect_signal", "params": {} },
    { "type": "wait", "params": {} }
  ]
}
```
- **Expected result:** Zod validation passes for all. Each step may fail at the Godot level due to missing required sub-params (e.g., add_node needs parent_path/type/name). Test each to verify Godot's error messages.

#### Scenario 15: Edge — game not running
- **Description:** Call run_test_scenario when the game is NOT running
- **Params:**
```json
{
  "steps": [
    { "type": "wait", "params": { "duration": 0.5 } }
  ]
}
```
- **Expected result:** Error from Godot (game must be running for runtime tools).

#### Scenario 16: Edge — very long scenario (many steps)
- **Description:** Run a scenario with a large number of steps (e.g., 50)
- **Params:** A JSON array of 50 wait steps, each with `{ "type": "wait", "params": { "duration": 0.01 } }`
- **Expected result:** Should succeed. Verify no timeout or truncation issues with large step arrays.

#### Scenario 17: Edge — name with special characters
- **Description:** Use a scenario name with special characters, spaces, and Unicode
- **Params:**
```json
{
  "name": "Test 🎮 Scenario — 第1幕",
  "steps": [
    { "type": "wait", "params": { "duration": 0.1 } }
  ]
}
```
- **Expected result:** Should succeed. Name is preserved with special characters intact.

#### Scenario 18: Edge — step with null params
- **Description:** Pass null as params (instead of object or omit)
- **Params:**
```json
{
  "steps": [
    { "type": "wait", "params": null }
  ]
}
```
- **Expected result:** Zod may reject (params is `z.record(z.unknown()).optional()` — null is not a valid record). Test to verify. If accepted, Godot may error on null params.

#### Scenario 19: Edge — steps as non-array
- **Description:** Pass a string or object instead of array for steps
- **Params:**
```json
{
  "steps": "not_an_array"
}
```
- **Expected result:** Zod validation error (expected array, got string).

#### Scenario 20: Edge — name as non-string
- **Description:** Pass a number or boolean for the name
- **Params:**
```json
{
  "name": 123,
  "steps": [{ "type": "wait", "params": { "duration": 0.1 } }]
}
```
- **Expected result:** Zod validation error (expected string, got number).

---

## Tool: `assert_node_state`

**Description:** Assert that a node property matches an expected value
**Handler:** `callGodot(bridge, 'testing/assert_state', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path in the running game |
| `property` | `PropertyName` (string) | **Yes** | — | Property name to check |
| `expected` | `PropertyValue` (unknown) | **Yes** | — | Expected value |
| `operator` | string | No | `"=="` | Comparison operator: `==`, `!=`, `>`, `<`, `>=`, `<=`, `contains` (default: `"=="`) |

### Test Scenarios

#### Scenario 1: Happy path — equality assertion (==) with default operator
- **Description:** Assert that a node's property equals the expected value using the default `==` operator. Game must be running.
- **Params:**
```json
{
  "path": "Player",
  "property": "visible",
  "expected": true
}
```
- **Expected result:** If Player.visible is true → assertion passes. If false → assertion fails with error.
- **Notes:** Requires a running game with a node named "Player" and the visible property.

#### Scenario 2: Happy path — equality assertion (==) explicit operator
- **Description:** Explicitly pass operator "==" (same as default)
- **Params:**
```json
{
  "path": "Player",
  "property": "visible",
  "expected": true,
  "operator": "=="
}
```
- **Expected result:** Same as Scenario 1. Explicit "==" behaves identically to default.

#### Scenario 3: Happy path — not-equal assertion (!=)
- **Description:** Assert that a property does NOT equal the expected value
- **Params:**
```json
{
  "path": "Player",
  "property": "visible",
  "expected": false,
  "operator": "!="
}
```
- **Expected result:** If Player.visible is true → assertion passes (true != false). If Player.visible is false → assertion fails.

#### Scenario 4: Happy path — greater-than assertion (>)
- **Description:** Assert that a numeric property is greater than expected
- **Params:**
```json
{
  "path": "Player",
  "property": "position.x",
  "expected": 0,
  "operator": ">"
}
```
- **Expected result:** If position.x > 0 → passes. If position.x <= 0 → fails.

#### Scenario 5: Happy path — less-than assertion (<)
- **Description:** Assert that a numeric property is less than expected
- **Params:**
```json
{
  "path": "Player",
  "property": "position.y",
  "expected": 500,
  "operator": "<"
}
```
- **Expected result:** If position.y < 500 → passes. If position.y >= 500 → fails.

#### Scenario 6: Happy path — greater-than-or-equal assertion (>=)
- **Description:** Assert that a numeric property is >= expected
- **Params:**
```json
{
  "path": "Player",
  "property": "scale.x",
  "expected": 1.0,
  "operator": ">="
}
```
- **Expected result:** If scale.x >= 1.0 → passes. If scale.x < 1.0 → fails.

#### Scenario 7: Happy path — less-than-or-equal assertion (<=)
- **Description:** Assert that a numeric property is <= expected
- **Params:**
```json
{
  "path": "Player",
  "property": "rotation",
  "expected": 3.14,
  "operator": "<="
}
```
- **Expected result:** If rotation <= 3.14 → passes. If rotation > 3.14 → fails.

#### Scenario 8: Happy path — contains assertion
- **Description:** Assert that a string property contains the expected substring
- **Params:**
```json
{
  "path": "Player",
  "property": "name",
  "expected": "Play",
  "operator": "contains"
}
```
- **Expected result:** If name contains "Play" → passes. If not → fails.

#### Scenario 9: Happy path — boolean expected value
- **Description:** Assert boolean false on a node property
- **Params:**
```json
{
  "path": "TestSprite",
  "property": "visible",
  "expected": false,
  "operator": "=="
}
```
- **Expected result:** If TestSprite.visible is false → passes.

#### Scenario 10: Happy path — expected as array (position, scale, etc.)
- **Description:** Assert a Vector2/Vector3 property matches an array value
- **Params:**
```json
{
  "path": "Player",
  "property": "position",
  "expected": [100, 200],
  "operator": "=="
}
```
- **Expected result:** If Player.position equals Vector2(100, 200) → passes. Note: depends on how Godot serializes/compares vector values.

#### Scenario 11: Happy path — expected as string number
- **Description:** Pass expected as a string representation of a number
- **Params:**
```json
{
  "path": "Player",
  "property": "z_index",
  "expected": 5,
  "operator": "=="
}
```
- **Expected result:** If z_index is 5 (number) → passes. If z_index is "5" (string) → depends on Godot's type coercion.

#### Scenario 12: Edge — missing required `path`
- **Description:** Call without the required `path` parameter
- **Params:**
```json
{
  "property": "visible",
  "expected": true
}
```
- **Expected result:** Zod validation error (path is required).

#### Scenario 13: Edge — missing required `property`
- **Description:** Call without the required `property` parameter
- **Params:**
```json
{
  "path": "Player",
  "expected": true
}
```
- **Expected result:** Zod validation error (property is required).

#### Scenario 14: Edge — missing required `expected` (undefined value)
- **Description:** Call without the `expected` parameter (but `expected` is required in schema since it uses `PropertyValue` which is `z.unknown()`)
- **Params:**
```json
{
  "path": "Player",
  "property": "visible"
}
```
- **Expected result:** Since `expected` is not `.optional()` in the schema and is not in `required`, this depends on Zod behavior with `z.unknown()`. If Zod requires it to be present, validation error. If omitted, Godot may error on missing expected value. Test to verify.

#### Scenario 15: Edge — invalid operator value
- **Description:** Pass an operator string not in the documented set
- **Params:**
```json
{
  "path": "Player",
  "property": "visible",
  "expected": true,
  "operator": "starts_with"
}
```
- **Expected result:** Zod validation passes (operator is `z.string()`, not an enum). The invalid operator should be caught by Godot and return an error (unknown operator).

#### Scenario 16: Edge — operator as empty string
- **Description:** Pass an empty string for operator
- **Params:**
```json
{
  "path": "Player",
  "property": "visible",
  "expected": true,
  "operator": ""
}
```
- **Expected result:** Zod passes (empty string is a valid string). Godot likely errors on empty operator.

#### Scenario 17: Edge — node path does not exist in running game
- **Description:** Assert on a node that is not in the game tree
- **Params:**
```json
{
  "path": "NonExistentNode",
  "property": "visible",
  "expected": true
}
```
- **Expected result:** Error from Godot (node not found in the running game).

#### Scenario 18: Edge — property does not exist on node
- **Description:** Assert a property that does not exist on the target node type
- **Params:**
```json
{
  "path": "Player",
  "property": "non_existent_prop",
  "expected": "anything"
}
```
- **Expected result:** Error from Godot (unknown property on node).

#### Scenario 19: Edge — path is empty string
- **Description:** Use empty string for path (scene root)
- **Params:**
```json
{
  "path": "",
  "property": "name",
  "expected": "root",
  "operator": "=="
}
```
- **Expected result:** If the root node's name matches → passes. Otherwise fails. Test to confirm empty string resolves to scene root.

#### Scenario 20: Edge — property as nested path (e.g., position:x)
- **Description:** Use a sub-property path like "position:x" instead of "position" with expected Vector2
- **Params:**
```json
{
  "path": "Player",
  "property": "position:x",
  "expected": 100,
  "operator": ">"
}
```
- **Expected result:** Depends on whether Godot supports sub-property access. If supported, compares position.x > 100. If not, errors.

#### Scenario 21: Edge — contains on non-string property
- **Description:** Use `contains` operator on a numeric property
- **Params:**
```json
{
  "path": "Player",
  "property": "z_index",
  "expected": 5,
  "operator": "contains"
}
```
- **Expected result:** Error from Godot (contains operator likely only works on string/array properties).

#### Scenario 22: Edge — game not running
- **Description:** Call assert_node_state when game is NOT running
- **Params:**
```json
{
  "path": "Player",
  "property": "visible",
  "expected": true
}
```
- **Expected result:** Error from Godot (game must be running for runtime assertion).

#### Scenario 23: Edge — operator case sensitivity
- **Description:** Pass operator in different casing: `"=="`, `"=="` (same), `">="`
- **Params:** Test both with valid operators and with uppercase variants like `"EQ"` or `"=="` (should work fine as-is)
- **Expected result:** Valid operators (==, !=, >, <, >=, <=, contains) should work. Case-sensitive variants (Eq, Contains) may fail depending on Godot implementation.

---

## Tool: `assert_screen_text`

**Description:** Assert that specific text appears on screen (OCR or UI element check)
**Handler:** `callGodot(bridge, 'testing/assert_screen_text', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `text` | string | **Yes** | — | Text that should appear on screen |
| `should_exist` | boolean | No | `true` | Whether text should be present (true) or absent (false) (default: true) |

### Test Scenarios

#### Scenario 1: Happy path — text should be present (default should_exist)
- **Description:** Assert that a specific text string appears on screen. Game must be running with UI/text visible.
- **Params:**
```json
{
  "text": "Hello World"
}
```
- **Expected result:** If "Hello World" is visible on screen → assertion passes. If not → fails.
- **Notes:** Requires a running game scene that renders the specified text (e.g., a Label with "Hello World").

#### Scenario 2: Happy path — text present with explicit should_exist=true
- **Description:** Explicitly set should_exist to true
- **Params:**
```json
{
  "text": "Start Game",
  "should_exist": true
}
```
- **Expected result:** Same as Scenario 1. Text "Start Game" must be visible.

#### Scenario 3: Happy path — text should NOT be present (should_exist=false)
- **Description:** Assert that a specific text is NOT on screen (useful for verifying cleanup/hiding)
- **Params:**
```json
{
  "text": "Error: Connection Failed",
  "should_exist": false
}
```
- **Expected result:** If "Error: Connection Failed" is NOT visible → assertion passes. If it IS visible → assertion fails.

#### Scenario 4: Happy path — empty string text
- **Description:** Assert that empty string appears on screen
- **Params:**
```json
{
  "text": ""
}
```
- **Expected result:** Depends on Godot's OCR/UI search. Empty string may match anything, nothing, or be rejected. Test to verify.

#### Scenario 5: Happy path — text with special characters
- **Description:** Assert text containing special characters (newlines, quotes, etc.)
- **Params:**
```json
{
  "text": "Player:\n  HP: 100/100"
}
```
- **Expected result:** If the exact multi-line text is present → passes. Newline handling depends on UI label rendering.

#### Scenario 6: Happy path — Unicode / non-ASCII text
- **Description:** Assert text with Unicode characters (CJK, emoji, accented)
- **Params:**
```json
{
  "text": "プレイヤー 🎮 — ¡Hola!"
}
```
- **Expected result:** If the Unicode text appears exactly as specified → passes. Test encoding preservation.

#### Scenario 7: Happy path — partial text match (substring)
- **Description:** Assert that a substring of a longer text is found
- **Params:**
```json
{
  "text": "HP: 100",
  "should_exist": true
}
```
- **Expected result:** If the label reads "Player HP: 100/100" → depends on whether Godot performs exact or substring matching. Test to determine matching semantics.

#### Scenario 8: Edge — missing required `text` parameter
- **Description:** Call without the required `text` parameter
- **Params:**
```json
{
  "should_exist": true
}
```
- **Expected result:** Zod validation error (text is required).

#### Scenario 9: Edge — should_exist as non-boolean
- **Description:** Pass a string or number for should_exist
- **Params:**
```json
{
  "text": "Hello",
  "should_exist": "true"
}
```
- **Expected result:** Zod validation error (expected boolean, got string).

#### Scenario 10: Edge — should_exist as number
- **Description:** Pass `should_exist: 1` (truthy number)
- **Params:**
```json
{
  "text": "Hello",
  "should_exist": 1
}
```
- **Expected result:** Zod validation error (expected boolean, got number).

#### Scenario 11: Edge — very long text
- **Description:** Assert a very long text string on screen
- **Params:**
```json
{
  "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam..."
}
```
- **Expected result:** Should succeed if the long text is present. Test for any truncation or performance issues with long strings.

#### Scenario 12: Edge — game not running
- **Description:** Call assert_screen_text when game is NOT running
- **Params:**
```json
{
  "text": "Hello"
}
```
- **Expected result:** Error from Godot (game must be running for screen text assertion).

#### Scenario 13: Edge — text with regex-like patterns
- **Description:** Assert text containing characters that could be interpreted as regex (`.*+?[]{}()`)
- **Params:**
```json
{
  "text": "Score: [100] (max)"
}
```
- **Expected result:** If Godot does exact text matching, the brackets and parentheses should be treated as literal characters. If regex matching, may behave unexpectedly. Test to verify matching mode.

#### Scenario 14: Edge — sensitive text (passwords, keys)
- **Description:** Assert that sensitive text does NOT appear on screen
- **Params:**
```json
{
  "text": "password123",
  "should_exist": false
}
```
- **Expected result:** If "password123" is not visible → passes. Useful for security regression tests.

#### Scenario 15: Edge — text with leading/trailing whitespace
- **Description:** Assert text with surrounding whitespace
- **Params:**
```json
{
  "text": "  Padded Text  "
}
```
- **Expected result:** Depends on whether Godot trims whitespace in UI labels. If the label has leading/trailing spaces, assertion should pass. If Godot strips whitespace, test will reveal this.

---

## Tool: `run_stress_test`

**Description:** Run a stress test on the game (spawn entities, measure performance)
**Handler:** `callGodot(bridge, 'testing/stress_test', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `type` | string | No | `"Node2D"` | Node type to spawn (default: Node2D) |
| `count` | integer | No | `100` | Number of entities to spawn (default: 100) |
| `parent_path` | string | No | — | Parent node path for spawned entities |
| `properties` | object (`z.record(z.unknown())`) | No | — | Properties to set on each spawned entity |

### Test Scenarios

#### Scenario 1: Happy path — default spawn (100 Node2D, no parent, no properties)
- **Description:** Run a stress test with all defaults. Game must be running.
- **Params:** `{}`
- **Expected result:** Success. 100 Node2D entities are spawned (likely at scene root). Returns a performance report with metrics (spawn time, FPS impact, etc.).

#### Scenario 2: Happy path — custom type
- **Description:** Spawn a different node type
- **Params:**
```json
{
  "type": "Sprite2D",
  "count": 50
}
```
- **Expected result:** Success. 50 Sprite2D entities are spawned. Performance report returned.

#### Scenario 3: Happy path — custom count
- **Description:** Spawn a specific number of entities
- **Params:**
```json
{
  "type": "Node3D",
  "count": 10
}
```
- **Expected result:** Success. 10 Node3D entities are spawned.

#### Scenario 4: Happy path — with parent_path
- **Description:** Spawn entities under a specific parent node
- **Params:**
```json
{
  "type": "Node2D",
  "count": 20,
  "parent_path": "StressTestContainer"
}
```
- **Expected result:** Success. 20 Node2D entities are spawned as children of "StressTestContainer". Requires a node named "StressTestContainer" in the running scene.

#### Scenario 5: Happy path — with parent_path as empty string (root)
- **Description:** Explicitly specify empty parent_path for scene root
- **Params:**
```json
{
  "count": 5,
  "parent_path": ""
}
```
- **Expected result:** Success. 5 entities spawned at the scene root.

#### Scenario 6: Happy path — with properties applied
- **Description:** Spawn entities with properties set on each
- **Params:**
```json
{
  "type": "Sprite2D",
  "count": 10,
  "properties": {
    "visible": false,
    "z_index": 10
  }
}
```
- **Expected result:** Success. 10 Sprite2D entities spawned, each with visible=false and z_index=10.

#### Scenario 7: Happy path — stress test with large count
- **Description:** Spawn a large number of entities to actually stress the engine
- **Params:**
```json
{
  "type": "Node2D",
  "count": 10000
}
```
- **Expected result:** Success (may take time). Performance report shows significant memory/CPU impact. Test for timeouts or crashes with extreme counts.

#### Scenario 8: Happy path — minimum count (1)
- **Description:** Spawn a single entity
- **Params:**
```json
{
  "count": 1
}
```
- **Expected result:** Success. 1 entity spawned. Performance report shows minimal impact.

#### Scenario 9: Happy path — count = 0
- **Description:** Spawn zero entities
- **Params:**
```json
{
  "count": 0
}
```
- **Expected result:** Success or no-op. 0 entities spawned. Performance report shows zero impact. Test to verify behavior.

#### Scenario 10: Edge — negative count
- **Description:** Pass a negative count value
- **Params:**
```json
{
  "count": -10
}
```
- **Expected result:** Zod validation passes (`z.number().int()` allows negative). Godot may reject negative count with an error, or treat it as 0. Test to verify.

#### Scenario 11: Edge — count as float (non-integer)
- **Description:** Pass a non-integer count value
- **Params:**
```json
{
  "count": 12.5
}
```
- **Expected result:** Zod validation error (`z.number().int()` rejects floats).

#### Scenario 12: Edge — count as string
- **Description:** Pass a string value for count
- **Params:**
```json
{
  "count": "100"
}
```
- **Expected result:** Zod validation error (expected number, got string).

#### Scenario 13: Edge — invalid node type
- **Description:** Pass a node type that does not exist
- **Params:**
```json
{
  "type": "InvalidNodeTypeXYZ",
  "count": 5
}
```
- **Expected result:** Error from Godot (unknown node type).

#### Scenario 14: Edge — non-existent parent_path
- **Description:** Spawn under a parent that does not exist
- **Params:**
```json
{
  "parent_path": "NonExistentParent"
}
```
- **Expected result:** Error from Godot (parent node not found).

#### Scenario 15: Edge — type as empty string
- **Description:** Pass empty string as node type
- **Params:**
```json
{
  "type": "",
  "count": 5
}
```
- **Expected result:** Error from Godot (invalid/unknown node type from empty string).

#### Scenario 16: Edge — properties with complex nested values
- **Description:** Pass deeply nested properties
- **Params:**
```json
{
  "count": 3,
  "properties": {
    "position": { "x": 100, "y": 200 },
    "metadata": { "key": "value", "nested": { "deep": true } }
  }
}
```
- **Expected result:** Depends on how Godot deserializes complex property values. May succeed for supported types (Vector2 from object) or error on unsupported nesting.

#### Scenario 17: Edge — game not running
- **Description:** Call run_stress_test when game is NOT running
- **Params:** `{}`
- **Expected result:** Error from Godot (game must be running for stress test).

#### Scenario 18: Edge — properties conflicting with node type
- **Description:** Set properties that don't apply to the specified node type
- **Params:**
```json
{
  "type": "Node2D",
  "count": 3,
  "properties": {
    "text": "This property does not exist on Node2D"
  }
}
```
- **Expected result:** Error from Godot (unknown property for Node2D), or silent ignore. Test to verify.

#### Scenario 19: Edge — type with path-like syntax (check for injection)
- **Description:** Pass a type name containing slashes or special path characters
- **Params:**
```json
{
  "type": "../../SomeClass",
  "count": 1
}
```
- **Expected result:** Error from Godot (invalid node type). Should not cause path traversal issues.

#### Scenario 20: Edge — very large properties object
- **Description:** Pass a properties object with many keys
- **Params:**
```json
{
  "count": 1,
  "properties": { "a": 1, "b": 2, "c": 3, "...": "..." }
}
```
(with 50+ properties)
- **Expected result:** May succeed but only valid properties are applied. Test for serialization/performance issues with large property objects.

---

## Tool: `get_test_report`

**Description:** Get aggregated results of all test runs in this session
**Handler:** `callGodot(bridge, 'testing/get_report')`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| — | — | — | — | No parameters |

### Test Scenarios

#### Scenario 1: Happy path — get report after running tests
- **Description:** Run one or more test scenarios (run_test_scenario, assert_node_state, etc.) and then call get_test_report to retrieve aggregated results.
- **Params:** `{}`
- **Expected result:** Success. Returns an aggregated report of all tests executed in the current session. Report should include pass/fail counts, scenario names, and any error details.
- **Notes:** Requires at least one test to have been run in the session beforehand.

#### Scenario 2: Happy path — get report with no prior tests
- **Description:** Call get_test_report when no tests have been run yet
- **Params:** `{}`
- **Expected result:** Success. Returns an empty or zero-count report (0 tests run, 0 passed, 0 failed).

#### Scenario 3: Happy path — get report after multiple scenarios
- **Description:** Run multiple test scenarios of different types, then get report
- **Params:** `{}`
- **Expected result:** Success. Report aggregates results from all run_test_scenario, assert_node_state, assert_screen_text, and run_stress_test calls in the session.

#### Scenario 4: Happy path — get report after failures
- **Description:** Run a scenario where an assertion fails, then get the report
- **Params:** `{}`
- **Expected result:** Success. Report includes both passed and failed tests, with failure details (which assertion failed, expected vs actual values).

#### Scenario 5: Edge — extra parameters passed
- **Description:** Call get_test_report with unexpected parameters
- **Params:**
```json
{
  "name": "SomeScenario",
  "irrelevant": true
}
```
- **Expected result:** Handler ignores args (`async () => callGodot(bridge, 'testing/get_report')`). Extra params are silently ignored. Report returns normally.

#### Scenario 6: Edge — game not running vs running
- **Description:** Call get_test_report when game is running vs when it is stopped
- **Params:** `{}`
- **Expected result:** Should succeed in both states. The report is session-scoped (editor-level), not runtime-scoped. Test to verify it works regardless of play state.

#### Scenario 7: Edge — session persistence
- **Description:** Run tests, get report, then stop and restart the game, and get report again
- **Params:** `{}`
- **Expected result:** The session report should persist across play/stop cycles (it's aggregated for the editor session, not the game session). Test to verify.

#### Scenario 8: Edge — report after stress test only
- **Description:** Run only a stress test (no assertions), then get report
- **Params:** `{}`
- **Expected result:** Success. Report should include the stress test results (spawn count, performance metrics) as part of the aggregated report.

#### Scenario 9: Edge — report structure and completeness
- **Description:** Examine the shape of the returned report
- **Params:** `{}`
- **Expected result:** Report should be a JSON object with keys like `total_tests`, `passed`, `failed`, `scenarios` (array of individual scenario results). Each scenario entry should include `name`, `status`, and `steps` or `details`. Verify the structure is well-formed and parseable.

---

## Integration Test Scenarios

These scenarios chain multiple testing tools together to verify end-to-end testing workflows.

### Integration 1: Full test cycle — Scenarios → Assertions → Report
1. Start the game (use `play_scene`)
2. `run_test_scenario` — create and verify nodes:
```json
{
  "name": "Integration Test 1",
  "steps": [
    { "type": "add_node", "params": { "parent_path": "", "type": "Node2D", "name": "IntegrationNode" } },
    { "type": "set_property", "params": { "path": "IntegrationNode", "property": "name", "value": "IntegrationNode" } },
    { "type": "assert_node_state", "params": { "path": "IntegrationNode", "property": "name", "expected": "IntegrationNode", "operator": "==" } },
    { "type": "delete_node", "params": { "path": "IntegrationNode" } }
  ]
}
```
3. `assert_node_state` — verify cleanup:
```json
{ "path": "IntegrationNode", "property": "name", "expected": "IntegrationNode", "operator": "==" }
```
(expected to fail since node was deleted)
4. `get_test_report` — verify aggregated results include both the scenario and the standalone assertion
5. Stop the game (use `stop_scene`)
- **Expected result:** Scenario passes (node created, asserted, then deleted). Standalone assertion fails (node no longer exists). Report shows 1 passed scenario, 1 failed assertion.

### Integration 2: Stress + Text + Assertion
1. Start the game with a scene that has visible UI text
2. `run_stress_test` — spawn entities with properties:
```json
{
  "type": "Node2D",
  "count": 50,
  "parent_path": "",
  "properties": { "visible": false, "z_index": -1 }
}
```
3. `assert_screen_text` — verify UI text is still visible after stress:
```json
{ "text": "Main Menu", "should_exist": true }
```
4. `assert_node_state` — check performance counters or entity count:
```json
{ "path": "", "property": "get_child_count", "expected": 50, "operator": ">=" }
```
5. `get_test_report`
6. Stop the game
- **Expected result:** Stress test spawns 50 invisible nodes. Screen text assertion passes (UI unaffected). Child count assertion passes. Report aggregates stress test metrics, text assertion, and node assertion.

### Integration 3: Run empty scenario → report empty
1. `run_test_scenario` with empty steps:
```json
{ "name": "Empty", "steps": [] }
```
2. `get_test_report`
- **Expected result:** Scenario succeeds trivially. Report shows 1 scenario with 0 steps.

### Integration 4: Multi-operator assertion chain
1. Start the game. Ensure a node "Player" exists with known properties.
2. Run assertions using every operator:
   - `==` on `visible` equals `true`
   - `!=` on `name` equals `"Enemy"`
   - `>` on `position.x` equals `-1`
   - `<` on `position.y` equals `1000`
   - `>=` on `position.x` equals `0`
   - `<=` on `position.y` equals `1000`
   - `contains` on `name` equals `"lay"` (matches "Player")
3. `get_test_report`
- **Expected result:** All 7 assertions should pass for valid values. Report shows 7 passed assertions. If any fail, verify expected values are correct for the actual game state.

### Integration 5: Should-exist false after hiding UI
1. Start the game with a UI element showing "Temporary Label"
2. `assert_screen_text` with `{ "text": "Temporary Label", "should_exist": true }` — expect pass
3. Use `run_test_scenario` to hide the UI element:
```json
{
  "name": "Hide UI",
  "steps": [
    { "type": "set_property", "params": { "path": "LabelNode", "property": "visible", "value": false } }
  ]
}
```
4. `assert_screen_text` with `{ "text": "Temporary Label", "should_exist": false }` — expect pass
5. `assert_screen_text` with `{ "text": "Temporary Label", "should_exist": true }` — expect fail
6. `get_test_report`
- **Expected result:** First assertion passes (text visible). After hiding, should_exist=false passes (text gone). should_exist=true fails (text hidden). Report captures all outcomes.

---

## Summary

| Tool | Params | Required | Optional | Enum Values |
|---|---|---|---|---|
| `run_test_scenario` | 2 | `steps` | `name` | step.type: add_node, delete_node, set_property, assert_node_state, connect_signal, wait |
| `assert_node_state` | 4 | `path`, `property`, `expected` | `operator` | operator: ==, !=, >, <, >=, <=, contains |
| `assert_screen_text` | 2 | `text` | `should_exist` | — |
| `run_stress_test` | 4 | — | `type`, `count`, `parent_path`, `properties` | — |
| `get_test_report` | 0 | — | — | — |

**Total scenarios:** 70+ covering all 5 tools with happy paths, all enum values, edge cases, and integration workflows.
