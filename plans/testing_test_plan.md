# Testing Tools Test Plan

**Source**: `server/src/tools/testing.ts`
**GDScript backend**: `addons/godot_mcp/commands/testing_commands.gd`
**Total tools**: 6
**Test plan generated**: 2026-07-08

---

## Table of Contents

1. [Tool: run_test_scenario](#tool-run_test_scenario)
2. [Tool: assert_node_state](#tool-assert_node_state)
3. [Tool: assert_screen_text](#tool-assert_screen_text)
4. [Tool: run_stress_test](#tool-run_stress_test)
5. [Tool: get_test_report](#tool-get_test_report)
6. [Tool: clear_test_report](#tool-clear_test_report)

---

## Shared Types Reference

| Type | Zod schema | Description |
|------|------------|-------------|
| `NodePath` | `z.string()` | Node path in scene tree, e.g. `"Player/Sprite2D"`. Empty string `""` for root. Relative to open scene. |
| `PropertyName` | `z.string()` | Property name, e.g. `"position"`, `"visible"` |
| `PropertyValue` | `z.unknown()` | Any property value (number, string, bool, Vector2, Color, etc.) |

---

## Prerequisites for All Tools

All 6 tools forward calls to the Godot editor via `callGodot(bridge, ...)`. This means:

1. **Godot editor must be running** with the MCP plugin active and connected via WebSocket.
2. **A scene must be open** in the editor — most tools call `MCPCommandHelpers.get_scene_root()` internally and return `{"error": "No scene open"}` if none is found.
3. **For runtime-dependent tools** (`assert_screen_text` checking UI nodes), the game should be **playing** so that runtime UI nodes (Labels, Buttons, etc.) are instantiated.
4. **For `run_test_scenario`** with `add_node` steps, the scene tree is modified via `EditorUndoRedoManager` — changes are undoable.

### Call Ordering / Dependencies

| Sequence | Tools | Rationale |
|----------|-------|-----------|
| Setup → Assert | `add_node` (from `node.ts`) → `assert_node_state` | Create nodes first, then assert their properties |
| Setup → Stress | `open_scene` (from `scene.ts`) → `run_stress_test` | Scene must be open to spawn entities |
| Assert → Report | `assert_node_state` / `run_test_scenario` → `get_test_report` | Report aggregates all prior assertions and scenario results in the session |
| Scenario → Report | `run_test_scenario` → `get_test_report` | Scenario results are appended to `_test_results` and appear in the report |
| Stress → Report | `run_stress_test` → `get_test_report` | Stress test data is stored in `_stress_test_data` and included in report under `"stress_test"` key |

**Important**: `_test_results` accumulates across the entire session. Calling `get_test_report` returns ALL results since the editor plugin was loaded. Use `clear_test_report` to reset accumulated results between test runs.

---

## Tool: run_test_scenario

**Tool name**: `run_test_scenario`
**Description**: Run a multi-step test scenario against the running game
**Backend method**: `testing/run_scenario`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | `z.string()` | No | `"Unnamed Scenario"` | Scenario name for reporting |
| `steps` | `z.array(object)` | **Yes** | — | Ordered test steps to execute |

#### Step object schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `z.enum([...])` | **Yes** | One of: `add_node`, `delete_node`, `set_property`, `assert_node_state`, `connect_signal`, `wait` |
| `params` | `z.record(z.unknown())` | No | Parameters for the step (see step types below) |

The step object also uses `.catchall(z.unknown())`, so additional fields are accepted but ignored by the backend.

#### Step types and their params

| Step `type` | `params` fields | Description |
|-------------|-----------------|-------------|
| `add_node` | `parent_path` (string), `type` (string, default `"Node"`), `name` (string, default = type name), `properties` (dict) | Adds a node to the scene tree via undo/redo |
| `delete_node` | `path` (string, **required**) | Deletes a node. Cannot delete root. |
| `set_property` | `path` (string, **required**), `property` (string, **required**), `value` (any) | Sets a property on an existing node via undo/redo |
| `assert_node_state` | `path` (string, **required**), `property` (string, **required**), `expected` (any), `operator` (string, default `"=="`) | Asserts property value. Operators: `==`, `!=`, `>`, `<`, `>=`, `<=`, `contains` |
| `connect_signal` | `source` (string, **required**), `signal` (string, **required**), `target` (string, **required**), `method` (string, **required**) | Connects a signal from source node to target node method |
| `wait` | `seconds` (float, default `1.0`) | Records a wait intent. In editor mode, does NOT actually wait — deferred to runtime. |

### Test Scenarios

#### Scenario 1: Happy path — minimal single-step scenario (add_node)

**Description**: Run a scenario with a single `add_node` step using minimal params.
**Params**:
```json
{
  "steps": [
    {
      "type": "add_node",
      "params": {
        "parent_path": "",
        "type": "Node2D",
        "name": "TestNode"
      }
    }
  ]
}
```
**Expected result**: Returns `content` with a JSON string containing `result.summary` with:
- `scenario`: `"Unnamed Scenario"` (default name)
- `total_steps`: `1`
- `passed`: `1`
- `failed`: `0`
- `duration_ms`: a positive number
- `steps`: array with 1 entry, `step[0].passed = true`, `step[0].result` = `"Added Node2D 'TestNode'"`

**Notes**: Prerequisite: a scene must be open. The node is added via undo/redo and can be undone. The added node should appear in the scene tree.
**What to check**: Verify that `passed` = 1 and `failed` = 0. The node should appear in the scene tree. The default scenario name is `"Unnamed Scenario"`.

---

#### Scenario 2: Happy path — multi-step scenario with name

**Description**: Run a multi-step scenario: add a node, set its property, then assert the property.
**Params**:
```json
{
  "name": "Player Setup Test",
  "steps": [
    {
      "type": "add_node",
      "params": {
        "parent_path": "",
        "type": "Sprite2D",
        "name": "Player"
      }
    },
    {
      "type": "set_property",
      "params": {
        "path": "Player",
        "property": "position",
        "value": [100, 200]
      }
    },
    {
      "type": "assert_node_state",
      "params": {
        "path": "Player",
        "property": "position",
        "expected": [100, 200],
        "operator": "=="
      }
    }
  ]
}
```
**Expected result**: `result.summary` with:
- `scenario`: `"Player Setup Test"`
- `total_steps`: `3`
- `passed`: `3`
- `failed`: `0`
- `steps[2].result.result.passed`: `true`

**Notes**: This tests the full add → set → assert pipeline. The `set_property` step converts the array `[100, 200]` to a `Vector2` via `MCPVariantCodec.parse_for_property`. The assert step then compares using `==`.
**What to check**: Verify that all 3 steps passed. Verify that `set_property` correctly converts the array to Vector2. Verify that assert returns `passed: true` with a message containing the path, property, and value.

---

#### Scenario 3: Happy path — scenario with connect_signal and wait

**Description**: Test signal connection and wait step types.
**Params**:
```json
{
  "name": "Signal Test",
  "steps": [
    {
      "type": "add_node",
      "params": {
        "parent_path": "",
        "type": "Button",
        "name": "MyButton"
      }
    },
    {
      "type": "add_node",
      "params": {
        "parent_path": "",
        "type": "Label",
        "name": "StatusLabel"
      }
    },
    {
      "type": "connect_signal",
      "params": {
        "source": "MyButton",
        "signal": "pressed",
        "target": "StatusLabel",
        "method": "set_text"
      }
    },
    {
      "type": "wait",
      "params": {
        "seconds": 0.5
      }
    }
  ]
}
```
**Expected result**: All 4 steps pass. `connect_signal` step result contains `"Connected MyButton.pressed -> StatusLabel.set_text"`. `wait` step result contains `"Wait step recorded (0.5s)"`.
**Notes**: Signal connection is done via undo/redo. The `wait` step does NOT actually pause — it only records the intent.
**What to check**: Verify that `connect_signal` correctly connects the signal. The `wait` step should not block execution — it only records the intent. The `wait` result should mention that execution is deferred to runtime.

---

#### Scenario 4: Scenario with delete_node step

**Description**: Add a node then delete it within the same scenario.
**Params**:
```json
{
  "name": "Cleanup Test",
  "steps": [
    {
      "type": "add_node",
      "params": {
        "parent_path": "",
        "type": "Node",
        "name": "TempNode"
      }
    },
    {
      "type": "delete_node",
      "params": {
        "path": "TempNode"
      }
    }
  ]
}
```
**Expected result**: Both steps pass. `steps[0].result` = `"Added Node 'TempNode'"`, `steps[1].result` = `"Deleted TempNode"`.
**Notes**: Verifies that add + delete within a single scenario works. After execution, `TempNode` should no longer exist in the scene tree.
**What to check**: Verify that the node was actually deleted from the scene tree after the scenario completed.

---

#### Scenario 5: Edge case — empty steps array

**Description**: Call with an empty `steps` array.
**Params**:
```json
{
  "steps": []
}
```
**Expected result**: Returns an error: `{"error": "Steps array is required"}`. The backend checks `steps.is_empty()` and returns this error.
**Notes**: This is a validation error from the GDScript backend, not from the TypeScript schema. The Zod schema allows an empty array, but the handler rejects it.
**What to check**: This is an important edge case — Zod validation passes (empty array is allowed), but the GDScript backend returns an error. Verify that the error is correctly propagated to the client.

---

#### Scenario 6: Edge case — unknown step type

**Description**: Pass a step with an unrecognized type.
**Params**:
```json
{
  "steps": [
    {
      "type": "fly_to_moon",
      "params": {}
    }
  ]
}
```
**Expected result**: **Zod validation error** — the `type` field uses `z.enum([...])` which only allows the 6 known values. The request should be rejected before reaching the Godot bridge. The error should indicate an invalid enum value.
**Notes**: The TypeScript schema is stricter than the GDScript backend here. The GDScript has a `_:` default case that returns `{"error": "Unknown step type: ..."}`, but the Zod enum prevents invalid types from ever reaching it.
**What to check**: Verify that the error comes from Zod validation, not from the GDScript backend. The error message should indicate an invalid enum value.

---

#### Scenario 7: Edge case — step missing required params

**Description**: A `delete_node` step with no `path` in params.
**Params**:
```json
{
  "steps": [
    {
      "type": "delete_node",
      "params": {}
    }
  ]
}
```
**Expected result**: The step executes but returns an error from the GDScript backend: `{"error": "Path required"}`. The step is marked as `passed: false` in the results, and `failed` count is incremented.
**Notes**: The GDScript `_step_delete_node` checks `path.is_empty()` and returns an error. The scenario continues processing remaining steps (no early abort).
**What to check**: Verify that the error is correctly reflected in the step result (`passed: false`) and in the summary statistics (`failed` is incremented). The scenario should not abort on the error step — remaining steps should still execute.

---

#### Scenario 8: Edge case — assert_node_state step that fails

**Description**: Assert a property value that doesn't match.
**Params**:
```json
{
  "name": "Failing Assert",
  "steps": [
    {
      "type": "add_node",
      "params": {
        "parent_path": "",
        "type": "Node2D",
        "name": "AssertTarget"
      }
    },
    {
      "type": "assert_node_state",
      "params": {
        "path": "AssertTarget",
        "property": "visible",
        "expected": false,
        "operator": "=="
      }
    }
  ]
}
```
**Expected result**: Step 0 passes (add_node). Step 1 fails because `visible` defaults to `true`, not `false`. Summary: `passed: 1`, `failed: 1`. Step 1 result should contain `"passed": false` with a message like `"Assertion FAILED: AssertTarget.visible actual=true == expected=false"`.
**Notes**: Tests that a failing assertion is correctly reported without aborting the scenario.
**What to check**: Verify that a failing assert does NOT abort scenario execution. Verify that the result contains information about the actual and expected values.

---

#### Scenario 9: Edge case — connect_signal with non-existent signal

**Description**: Try to connect a signal that doesn't exist on the source node.
**Params**:
```json
{
  "steps": [
    {
      "type": "add_node",
      "params": {
        "parent_path": "",
        "type": "Node",
        "name": "NoSignalNode"
      }
    },
    {
      "type": "connect_signal",
      "params": {
        "source": "NoSignalNode",
        "signal": "nonexistent_signal",
        "target": "NoSignalNode",
        "method": "some_method"
      }
    }
  ]
}
```
**Expected result**: Step 0 passes. Step 1 fails with error: `"Signal 'nonexistent_signal' not found on NoSignalNode"`. Summary: `passed: 1`, `failed: 1`.
**Notes**: The GDScript checks `source.has_signal(signal_name)` before attempting connection.
**What to check**: Verify that the error correctly describes the problem — indicates the signal name and source node.

---

## Tool: assert_node_state

**Tool name**: `assert_node_state`
**Description**: Assert that a node property matches an expected value
**Backend method**: `testing/assert_state`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `NodePath` (string) | **Yes** | — | Node path in the running game |
| `property` | `PropertyName` (string) | **Yes** | — | Property name to check (e.g. `"position"`, `"visible"`) |
| `expected` | `PropertyValue` (unknown) | **Yes** | — | Expected value to compare against |
| `operator` | `z.string()` | No | `"=="` | Comparison operator: `==`, `!=`, `>`, `<`, `>=`, `<=`, `contains` |

### Test Scenarios

#### Scenario 1: Happy path — assert equality (default operator)

**Description**: Assert that a node's `visible` property equals `true`.
**Params**:
```json
{
  "path": "Player",
  "property": "visible",
  "expected": true
}
```
**Expected result**: Returns `content` with JSON containing:
- `result.passed`: `true`
- `result.message`: string containing `"Assertion passed: Player visible == true"`

**Notes**: Prerequisite: a node named `"Player"` must exist in the current scene. The `operator` defaults to `"=="`.
**What to check**: Verify that the response contains `passed: true` and an informative message with the path, property, operator, and value.

---

#### Scenario 2: Happy path — assert with explicit operator (`!=`)

**Description**: Assert that a node's position is NOT at origin.
**Params**:
```json
{
  "path": "Player",
  "property": "position",
  "expected": [0, 0],
  "operator": "!="
}
```
**Expected result**: `result.passed`: `true` if Player's position is not `[0, 0]`. Message: `"Assertion passed: Player position != [0, 0]"`.
**Notes**: Uses the `!=` operator. The `expected` value `[0, 0]` is compared against the actual `Vector2` position. `MCPCommandHelpers.compare_values` handles type conversion.
**What to check**: Verify that the `!=` operator works correctly — returns `true` when values are NOT equal.

---

#### Scenario 3: Happy path — assert with `contains` operator

**Description**: Assert that a Label node's text contains a substring.
**Params**:
```json
{
  "path": "UI/ScoreLabel",
  "property": "text",
  "expected": "Score",
  "operator": "contains"
}
```
**Expected result**: `result.passed`: `true` if the Label's text contains `"Score"` as a substring.
**Notes**: Prerequisite: a Label node at path `"UI/ScoreLabel"` must exist with text containing `"Score"`. The `contains` operator uses string `find()` in GDScript.
**What to check**: Verify that `contains` works as a substring search, not an exact match. `"Score: 100"` should pass with `expected: "Score"`.

---

#### Scenario 4: Happy path — numeric comparison operators (`>`, `<`, `>=`, `<=`)

**Description**: Assert that a numeric property satisfies an inequality.
**Params**:
```json
{
  "path": "Player",
  "property": "position",
  "expected": [50, 0],
  "operator": ">="
}
```
**Expected result**: `result.passed`: `true` if Player's position.x >= 50. The comparison is done by `MCPCommandHelpers.compare_values`.
**Notes**: Numeric comparison on Vector2 may compare individual components or use magnitude — behavior depends on the GDScript `compare_values` implementation.
**What to check**: Clarify how `compare_values` compares Vector2 — by components or by vector magnitude. This affects the expected result for non-orthogonal positions.

---

#### Scenario 5: Edge case — node not found

**Description**: Assert on a node that doesn't exist.
**Params**:
```json
{
  "path": "NonExistentNode",
  "property": "visible",
  "expected": true
}
```
**Expected result**: Error: `"Node not found: NonExistentNode"`. The response should have `isError: true`.
**Notes**: The GDScript checks `root.get_node_or_null(path)` and returns error if null.
**What to check**: Verify that the error contains the node path that was not found. The response should be marked as an error (`isError: true`).

---

#### Scenario 6: Edge case — empty path

**Description**: Pass an empty string as path.
**Params**:
```json
{
  "path": "",
  "property": "visible",
  "expected": true
}
```
**Expected result**: Error: `"Path and property are required"`. The GDScript checks `path.is_empty()`.
**Notes**: Empty path is caught by the GDScript validation before attempting node lookup.
**What to check**: Verify that an empty path is handled correctly and does not lead to unexpected behavior (e.g., attempting to get the root node).

---

#### Scenario 7: Edge case — empty property name

**Description**: Pass an empty string as property.
**Params**:
```json
{
  "path": "Player",
  "property": "",
  "expected": true
}
```
**Expected result**: Error: `"Path and property are required"`.
**Notes**: Same validation as empty path — both are checked together.
**What to check**: Verify that an empty property name is also validated.

---

#### Scenario 8: Edge case — no scene open

**Description**: Call when no scene is open in the editor.
**Params**:
```json
{
  "path": "Player",
  "property": "visible",
  "expected": true
}
```
**Expected result**: Error: `"No scene open"`.
**Notes**: This requires closing all scenes in the editor before calling. The GDScript checks `MCPCommandHelpers.get_scene_root(_plugin)` returning null.
**What to check**: This state depends on the editor — make sure all scenes are closed before calling.

---

#### Scenario 9: Happy path — assert `expected` with complex value (Dictionary)

**Description**: Assert a property that returns a Dictionary.
**Params**:
```json
{
  "path": "Player",
  "property": "meta",
  "expected": {"health": 100},
  "operator": "=="
}
```
**Expected result**: `result.passed`: `true` if the node's `meta` property matches `{"health": 100}`. Comparison uses `MCPCommandHelpers.compare_values`.
**Notes**: Complex value comparison depends on the GDScript implementation of `compare_values`. May need to verify deep equality vs reference equality.
**What to check**: Verify how `compare_values` handles complex types (Dictionary, Array). Deep comparison or reference comparison?

---

## Tool: assert_screen_text

**Tool name**: `assert_screen_text`
**Description**: Assert that specific text appears on screen (OCR or UI element check)
**Backend method**: `testing/assert_screen_text`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `text` | `z.string()` | **Yes** | — | Text that should appear on screen |
| `should_exist` | `z.boolean()` | No | `true` | Whether text should be present (`true`) or absent (`false`) |

### How it works internally

The GDScript `_find_text_recursive` traverses the entire scene tree and checks text content of these node types:
- `Label` — checks `.text`
- `Button` — checks `.text`
- `RichTextLabel` — checks `.get_parsed_text()`
- `LineEdit` — checks `.text`
- `TextEdit` — checks `.text`

Uses `String.find(search_text) != -1` — **substring match**, not exact match.

### Test Scenarios

#### Scenario 1: Happy path — text exists on screen (default should_exist)

**Description**: Assert that text "Score" appears somewhere in the UI.
**Params**:
```json
{
  "text": "Score"
}
```
**Expected result**: `result.passed`: `true` if any Label/Button/RichTextLabel/LineEdit/TextEdit node contains "Score" as substring. Message: `"Screen text assertion passed: 'Score' found"`.
**Notes**: Prerequisite: the game must be running with a UI that contains a node with "Score" in its text. The `should_exist` defaults to `true`.
**What to check**: Verify that the search works as a substring search — `"Score: 100"` should be found when searching for `"Score"`. Verify that `found_count` > 0 in the results.

---

#### Scenario 2: Happy path — assert text does NOT exist

**Description**: Assert that "Error" text is NOT displayed.
**Params**:
```json
{
  "text": "Error",
  "should_exist": false
}
```
**Expected result**: `result.passed`: `true` if no UI node contains "Error" as substring. Message: `"Screen text assertion passed: 'Error' not found"`.
**Notes**: Tests the negative assertion path.
**What to check**: Verify that `should_exist: false` inverts the logic — assertion passes when the text is NOT found.

---

#### Scenario 3: Edge case — text not found (should_exist = true)

**Description**: Assert that "NonexistentText" exists when it doesn't.
**Params**:
```json
{
  "text": "NonexistentText",
  "should_exist": true
}
```
**Expected result**: `result.passed`: `false`. Message: `"Screen text assertion FAILED: 'NonexistentText' expected to exist but was not found"`.
**Notes**: Tests the failing assertion path.
**What to check**: Verify that the error message is informative — contains the expected text and indicates that the text was not found.

---

#### Scenario 4: Edge case — text found but should_exist = false

**Description**: Assert that "Score" is NOT on screen when it actually is.
**Params**:
```json
{
  "text": "Score",
  "should_exist": false
}
```
**Expected result**: `result.passed`: `false`. Message: `"Screen text assertion FAILED: 'Score' expected not to exist but was found"`.
**Notes**: Tests the case where the negative assertion fails because the text IS present.
**What to check**: Verify that the error message correctly describes the situation — text was found but was not expected.

---

#### Scenario 5: Edge case — empty text string

**Description**: Pass an empty string as text.
**Params**:
```json
{
  "text": ""
}
```
**Expected result**: Error: `"Text is required"`. The GDScript checks `expected_text.is_empty()`.
**Notes**: Empty text is caught by validation. The error message is slightly misleading ("required" vs "empty"), but it's the actual behavior.
**What to check**: Verify that an empty string is treated as a validation error, not as a search for an empty substring (which would match any text).

---

#### Scenario 6: Edge case — no scene open

**Description**: Call when no scene is open.
**Params**:
```json
{
  "text": "Hello"
}
```
**Expected result**: Error: `"No scene open"`.
**Notes**: Same as `assert_node_state` — requires a scene to be open.
**What to check**: Verify that behavior is consistent with `assert_node_state` when no scene is open.

---

#### Scenario 7: Happy path — partial substring match

**Description**: Search for a substring that partially matches a longer text.
**Params**:
```json
{
  "text": "Heal",
  "should_exist": true
}
```
**Expected result**: `result.passed`: `true` if any node contains "Health", "Heal", "Healing", etc. The search uses `find()`, so partial matches succeed.
**Notes**: This verifies that the search is substring-based, not exact-match.
**What to check**: Confirm that the search works as substring-based (`find`), not exact match (`==`). `"Heal"` should be found in the text `"Health: 100"`.

---

#### Scenario 8: Happy path — check RichTextLabel parsed text

**Description**: Assert text in a RichTextLabel (which may contain BBCode).
**Params**:
```json
{
  "text": "Welcome",
  "should_exist": true
}
```
**Expected result**: `result.passed`: `true` if a RichTextLabel contains "Welcome" in its **parsed** text (BBCode stripped). For example, `[b]Welcome[/b]` would match.
**Notes**: The GDScript uses `get_parsed_text()` for RichTextLabel, which strips BBCode tags.
**What to check**: Verify that BBCode tags are correctly stripped during search. `[b]Welcome[/b]` should be found when searching for `"Welcome"`.

---

## Tool: run_stress_test

**Tool name**: `run_stress_test`
**Description**: Run a stress test on the game (spawn entities, measure performance)
**Backend method**: `testing/stress_test`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `type` | `z.string()` | No | `"Node2D"` | Node type to spawn (any valid Godot node type) |
| `count` | `z.number().int()` | No | `100` | Number of entities to spawn |
| `parent_path` | `z.string()` | No | `""` (scene root) | Parent node path for spawned entities |
| `properties` | `z.record(z.unknown())` | No | `{}` | Properties to set on each spawned entity |

### How it works internally

1. Gets scene root via `MCPCommandHelpers.get_scene_root()`
2. If `parent_path` is non-empty, resolves parent node
3. Creates `count` nodes of `type` using `MCPNodeFactory.create_node()`
4. Names each node `"{type}_{index}"` (e.g. `"Node2D_0"`, `"Node2D_1"`)
5. Sets `properties` on each node (only if the property exists via `has_property`)
6. Measures creation time in microseconds
7. **Cleans up** — calls `queue_free()` on all created nodes
8. Returns timing metrics

### Test Scenarios

#### Scenario 1: Happy path — default params (100 Node2D nodes)

**Description**: Run stress test with all defaults.
**Params**:
```json
{}
```
**Expected result**: Returns `result` with:
- `type`: `"Node2D"`
- `nodes_spawned`: `100`
- `creation_time_ms`: a positive number (typically 10-500ms)
- `avg_time_per_node_ms`: `creation_time_ms / 100`
- `message`: string like `"Spawned 100 Node2D nodes in XX.XXms (nodes removed after test)."`

**Notes**: Prerequisite: a scene must be open. Nodes are spawned then immediately freed — the scene tree should be unchanged after the call.
**What to check**: Verify that `nodes_spawned` is exactly 100. Verify that `avg_time_per_node_ms` = `creation_time_ms / 100`. Verify that nodes do NOT remain in the scene after the test (cleanup via `queue_free`).

---

#### Scenario 2: Happy path — custom type and count

**Description**: Spawn 50 Sprite2D nodes.
**Params**:
```json
{
  "type": "Sprite2D",
  "count": 50
}
```
**Expected result**: `type`: `"Sprite2D"`, `nodes_spawned`: `50`, `avg_time_per_node_ms` calculated from 50 nodes.
**Notes**: Sprite2D is heavier than Node2D (has texture property), so timing may differ.
**What to check**: Compare Sprite2D creation time with Node2D. Sprite2D may be slower due to additional properties.

---

#### Scenario 3: Happy path — with properties

**Description**: Spawn nodes with initial properties set.
**Params**:
```json
{
  "type": "Node2D",
  "count": 10,
  "properties": {
    "position": [100, 200],
    "visible": false
  }
}
```
**Expected result**: `nodes_spawned`: `10`. Each spawned node should have had `position` and `visible` set (verified internally via `has_property`).
**Notes**: Properties are set only if `MCPCommandHelpers.has_property(node, prop)` returns true. Invalid properties are silently skipped.
**What to check**: Verify that `position` and `visible` are set correctly. Invalid properties should be ignored without errors.

---

#### Scenario 4: Happy path — with parent_path

**Description**: Spawn nodes under a specific parent node.
**Params**:
```json
{
  "type": "Node2D",
  "count": 5,
  "parent_path": "Enemies"
}
```
**Expected result**: `nodes_spawned`: `5`. Nodes are added as children of the `"Enemies"` node.
**Notes**: Prerequisite: a node named `"Enemies"` must exist in the scene. If not found, expect error `"Parent not found: Enemies"`.
**What to check**: Verify that nodes are actually added to the specified parent, not to the scene root.

---

#### Scenario 5: Edge case — count = 0

**Description**: Spawn zero nodes.
**Params**:
```json
{
  "count": 0
}
```
**Expected result**: `nodes_spawned`: `0`, `creation_time_ms`: approximately `0`, `avg_time_per_node_ms`: `0` (due to `max(count, 1)` division in GDScript).
**Notes**: The GDScript uses `max(count, 1)` for the average calculation to avoid division by zero.
**What to check**: Verify that `avg_time_per_node_ms` does not divide by zero — GDScript uses `max(count, 1)`. With `count = 0`, the average should be 0 or close to it.

---

#### Scenario 6: Edge case — count = 1

**Description**: Spawn a single node.
**Params**:
```json
{
  "count": 1
}
```
**Expected result**: `nodes_spawned`: `1`, `avg_time_per_node_ms` = `creation_time_ms`.
**Notes**: Boundary case — verifies single-node spawning works.
**What to check**: Verify that `avg_time_per_node_ms` is exactly equal to `creation_time_ms` when count=1.

---

#### Scenario 7: Edge case — invalid node type

**Description**: Try to spawn a non-existent node type.
**Params**:
```json
{
  "type": "FakeNodeType12345",
  "count": 5
}
```
**Expected result**: Error: `"Cannot instantiate type: FakeNodeType12345"`. `MCPNodeFactory.create_node()` returns null for unknown types.
**Notes**: The error occurs on the first node creation attempt. No nodes are spawned.
**What to check**: Verify that the error occurs before any nodes are created — no nodes should remain in the scene.

---

#### Scenario 8: Edge case — non-existent parent_path

**Description**: Specify a parent that doesn't exist.
**Params**:
```json
{
  "parent_path": "NonExistent/Path"
}
```
**Expected result**: Error: `"Parent not found: NonExistent/Path"`.
**Notes**: The GDScript checks parent existence before spawning any nodes.
**What to check**: Verify that the error occurs before spawning begins.

---

#### Scenario 9: Happy path — large count (1000 nodes)

**Description**: Spawn 1000 nodes to measure performance at scale.
**Params**:
```json
{
  "type": "Node2D",
  "count": 1000
}
```
**Expected result**: `nodes_spawned`: `1000`, `creation_time_ms`: a larger number (may be 100-2000ms depending on hardware).
**Notes**: This is a performance boundary test. The response should still complete within the WebSocket timeout (default 30s).
**What to check**: Verify that the request does not exceed the WebSocket timeout (30 seconds). Creation time may vary significantly depending on hardware.

---

## Tool: get_test_report

**Tool name**: `get_test_report`
**Description**: Get aggregated results of all test runs in this session
**Backend method**: `testing/get_report`

### Parameters

None — empty schema `{}`.

### How it works internally

Aggregates all entries from `_test_results` array (accumulated across the session from `run_test_scenario`, `assert_node_state`, and `assert_screen_text` calls) and `_stress_test_data` dictionary.

Returns:
- `total_tests`: count of all test entries
- `passed`: count where `passed == true`
- `failed`: count where `passed == false`
- `pass_rate`: percentage string like `"75.0%"`
- `stress_test`: last stress test data (or empty dict if none run)
- `failures`: array of all failed test entries
- `session_duration_ms`: time since first test scenario was run

### Test Scenarios

#### Scenario 1: Happy path — report after running assertions

**Description**: Run some assertions first, then get the report.
**Setup sequence**:
1. Call `assert_node_state` with `path: "Player", property: "visible", expected: true` (should pass)
2. Call `assert_node_state` with `path: "Player", property: "visible", expected: false` (should fail)
3. Call `get_test_report`

**Params**:
```json
{}
```
**Expected result**: `result` with:
- `total_tests`: `2`
- `passed`: `1`
- `failed`: `1`
- `pass_rate`: `"50.0%"`
- `failures`: array with 1 entry (the failed assertion)
- `session_duration_ms`: a positive number

**Notes**: The report reflects ALL assertions since the plugin was loaded, not just from the current tool call.
**What to check**: Verify that `pass_rate` is correctly calculated as a percentage. Verify that the `failures` array contains only failed assertions with full information (path, property, actual, expected, operator).

---

#### Scenario 2: Happy path — report with no prior tests (empty session)

**Description**: Call `get_test_report` without running any prior tests.
**Params**:
```json
{}
```
**Expected result**: `result` with:
- `total_tests`: `0`
- `passed`: `0`
- `failed`: `0`
- `pass_rate`: `"0.0%"` (due to `max(total, 1)` in division)
- `stress_test`: `{}` (empty dict)
- `failures`: `[]` (empty array)
- `session_duration_ms`: `0.0` (if `_test_session_start` is 0)

**Notes**: This tests the empty state. The pass_rate calculation uses `max(total, 1)` to avoid division by zero, resulting in `0.0%`.
**What to check**: Verify that an empty report does not cause errors. `pass_rate` with 0 tests should be `"0.0%"` (not NaN or division by zero). `session_duration_ms` should be 0 if no scenarios were run.

---

#### Scenario 3: Happy path — report after stress test

**Description**: Run a stress test, then get the report.
**Setup sequence**:
1. Call `run_stress_test` with `count: 10`
2. Call `get_test_report`

**Params**:
```json
{}
```
**Expected result**: `result.stress_test` should contain:
- `type`: `"Node2D"`
- `count`: `10`
- `creation_time_ms`: positive number
- `nodes_created`: `10`

The `total_tests` count should NOT include the stress test (stress tests don't append to `_test_results`).
**Notes**: Stress test data is stored separately in `_stress_test_data`, not in `_test_results`. So `total_tests` only counts assertions and scenario steps.
**What to check**: It is important to verify that stress tests do NOT increase `total_tests` — they are stored separately in `_stress_test_data`. The `stress_test` field in the report should contain the last stress test data.

---

#### Scenario 4: Happy path — report after run_test_scenario

**Description**: Run a scenario, then get the report.
**Setup sequence**:
1. Call `run_test_scenario` with a 2-step scenario (add_node + assert_node_state)
2. Call `get_test_report`

**Params**:
```json
{}
```
**Expected result**: `total_tests` should include both steps from the scenario (each step is appended to `_test_results`). `passed` and `failed` reflect the scenario results.
**Notes**: Each step in `run_test_scenario` is individually appended to `_test_results`. A 2-step scenario adds 2 entries to the report.
**What to check**: Verify that each scenario step is individually counted in `_test_results`. A two-step scenario should increase `total_tests` by 2.

---

#### Scenario 5: Happy path — report with mixed results

**Description**: Run multiple tools then check the aggregated report.
**Setup sequence**:
1. Call `assert_screen_text` with `text: "Hello", should_exist: true` (pass if UI has "Hello")
2. Call `assert_node_state` with `path: "Player", property: "visible", expected: false` (fail — visible is true by default)
3. Call `run_stress_test` with `count: 5`
4. Call `get_test_report`

**Params**:
```json
{}
```
**Expected result**: Report contains:
- `total_tests`: `2` (screen text + node state assertions; stress test NOT counted)
- `passed`: `1` (screen text if "Hello" exists)
- `failed`: `1` (node state assertion)
- `pass_rate`: `"50.0%"`
- `stress_test`: object with `count: 5`
- `failures`: array with 1 entry

**Notes**: Tests the full aggregation pipeline across different tool types.
**What to check**: Verify that the report correctly aggregates results from different tools. The stress test should not affect `total_tests`, but should be present in the `stress_test` field.

---

## Tool: clear_test_report

**Tool name**: `clear_test_report`
**Description**: Clear all accumulated test results and reset session state
**Backend method**: `testing/clear_report`

### Parameters

None — empty schema `{}`.

### How it works internally

Resets all testing session state:
1. Clears `_test_results` array (accumulated from `run_test_scenario`, `assert_node_state`, `assert_screen_text`)
2. Resets `_test_session_start` to `0.0`
3. Clears `_stress_test_data` dictionary

Returns the count of cleared test entries and whether stress data existed.

### Test Scenarios

#### Scenario 1: Happy path — clear after running assertions

**Description**: Run some assertions, then clear the report, then verify the report is empty.
**Setup sequence**:
1. Call `assert_node_state` with `path: "Player", property: "visible", expected: true`
2. Call `assert_node_state` with `path: "Player", property: "visible", expected: false`
3. Call `clear_test_report`
4. Call `get_test_report`

**Params**:
```json
{}
```
**Expected result**: `result` with:
- `cleared_tests`: `2`
- `cleared_stress_data`: `false`
- `message`: `"Cleared 2 test results and reset session state."`

The subsequent `get_test_report` call should return `total_tests: 0`, `passed: 0`, `failed: 0`.

**Notes**: Verifies that clearing resets the accumulator. After clearing, `get_test_report` should return an empty report.
**What to check**: Verify that `cleared_tests` matches the number of prior assertions. Verify that `get_test_report` after clearing returns zero counts.

---

#### Scenario 2: Happy path — clear after stress test

**Description**: Run a stress test, then clear the report.
**Setup sequence**:
1. Call `run_stress_test` with `count: 50`
2. Call `clear_test_report`

**Params**:
```json
{}
```
**Expected result**: `result` with:
- `cleared_tests`: `0` (stress tests don't append to `_test_results`)
- `cleared_stress_data`: `true`
- `message`: `"Cleared 0 test results and reset session state."`

**Notes**: Stress test data is stored separately in `_stress_test_data`. The `cleared_stress_data` field indicates whether stress data was present and cleared. `cleared_tests` only counts `_test_results` entries.
**What to check**: Verify that `cleared_tests` is 0 (stress tests are not in `_test_results`). Verify that `cleared_stress_data` is `true`. After clearing, `get_test_report` should return `stress_test: {}`.

---

#### Scenario 3: Happy path — clear on empty session (no prior tests)

**Description**: Call `clear_test_report` without running any prior tests.
**Params**:
```json
{}
```
**Expected result**: `result` with:
- `cleared_tests`: `0`
- `cleared_stress_data`: `false`
- `message`: `"Cleared 0 test results and reset session state."`

**Notes**: This tests the idempotent case — clearing when nothing exists should succeed without errors.
**What to check**: Verify that no errors are returned. The function should handle empty state gracefully.

---

#### Scenario 4: Happy path — clear then run new tests

**Description**: Run tests, clear, then run new tests and verify only new results appear.
**Setup sequence**:
1. Call `assert_node_state` with `path: "Player", property: "visible", expected: true` (pass)
2. Call `clear_test_report`
3. Call `assert_node_state` with `path: "Player", property: "visible", expected: false` (fail)
4. Call `get_test_report`

**Params**:
```json
{}
```
**Expected result**: Report after step 4:
- `total_tests`: `1` (only the post-clear assertion)
- `passed`: `0`
- `failed`: `1`
- `failures`: array with 1 entry (the post-clear assertion)

**Notes**: Verifies that clearing effectively creates a boundary between test runs. Only results from after the clear should appear in the report.
**What to check**: Verify that the report contains ONLY the post-clear assertion, not the pre-clear one. This is the primary use case for `clear_test_report` — isolating test runs.

---

## Cross-Tool Integration Scenarios

### Integration 1: Full test workflow

**Description**: Complete testing workflow — create scene, run assertions, stress test, get report.

**Sequence**:
1. `open_scene` (from `scene.ts`) — open a scene with UI elements
2. `play_scene` (from `scene.ts`) — start the game
3. `assert_screen_text` — verify UI text appears
4. `assert_node_state` — check runtime node properties
5. `run_stress_test` — measure performance
6. `stop_scene` (from `scene.ts`) — stop the game
7. `get_test_report` — get aggregated results

**Expected**: Report contains all assertions (steps 3-4), stress test data (step 5), and correct pass/fail counts.

### Integration 2: Scenario + standalone assertions

**Description**: Mix `run_test_scenario` with standalone `assert_node_state` calls.

**Sequence**:
1. `run_test_scenario` with 3 steps (2 pass, 1 fail)
2. `assert_node_state` (pass)
3. `get_test_report`

**Expected**: `total_tests` = 4 (3 from scenario + 1 standalone). `passed` = 3, `failed` = 1.

### Integration 3: Multiple stress tests

**Description**: Run multiple stress tests with different parameters.

**Sequence**:
1. `run_stress_test` with `type: "Node2D", count: 50`
2. `run_stress_test` with `type: "Sprite2D", count: 50`
3. `get_test_report`

**Expected**: `stress_test` in the report contains data from the **last** stress test (Sprite2D). Previous stress test data is overwritten. `total_tests` = 0 (stress tests don't append to `_test_results`).
**What to check**: Important — `_stress_test_data` is overwritten on each `run_stress_test` call. The report only contains data from the LAST stress test.

---

## Result Format Reference

All tools return the standard MCP tool result format:

```json
{
  "content": [
    {
      "type": "text",
      "text": "<JSON string with result>"
    }
  ],
  "isError": true  // only present on errors
}
```

The `text` field contains a JSON-stringified object. For successful calls, it's wrapped in `{"result": ...}`. For errors, it's `{"error": "..."}`.

### Parsing the result

```typescript
const response = await callTool("assert_node_state", { ... });
const payload = JSON.parse(response.content[0].text);

if (response.isError) {
  // payload is { error: "..." }
  console.error(payload.error);
} else {
  // payload is { result: { passed, message, ... } }
  console.log(payload.result.passed);
}
```

---

## Summary Statistics

| Tool | Scenarios | Happy Path | Edge Cases |
|------|-----------|------------|------------|
| `run_test_scenario` | 9 | 4 | 5 |
| `assert_node_state` | 9 | 4 | 5 |
| `assert_screen_text` | 8 | 4 | 4 |
| `run_stress_test` | 9 | 4 | 5 |
| `get_test_report` | 5 | 5 | 0 |
| `clear_test_report` | 4 | 4 | 0 |
| **Cross-tool integration** | 3 | 3 | 0 |
| **Total** | **47** | **28** | **19** |
