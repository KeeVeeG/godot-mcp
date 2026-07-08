# Test Plan: batch.ts — Batch Tools

**File:** `server/src/tools/batch.ts`
**Module:** `registerBatchTools` — 8 tools for batch operations and cross-scene analysis
**Shared types:** `NodeType` (z.string), `ScriptPath` (z.string), `PropertyName` (z.string), `PropertyValue` (z.unknown), `z`

All tools call `callGodot(bridge, <method>, args)` which forwards to Godot via WebSocket. Responses are JSON-serialized text. Error responses have `isError: true`.

---

## Prerequisites for All Tests

- Godot editor open with a test project loaded
- MCP plugin active and WebSocket bridge connected
- Test project contains:
  - Multiple scenes with various node types (Sprite2D, Node2D, CharacterBody3D, Label, etc.)
  - At least one scene with signal connections
  - Scripts attached to nodes
  - At least one scene that depends on another (sub-scene instantiation)

---

## Tool: find_nodes_by_type

**Description:** Find all nodes of a specific type in the scene
**Godot endpoint:** `batch/find_by_type`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `type_name` | string (`NodeType`) | **Yes** | Node type name (e.g. 'Sprite2D', 'CharacterBody3D') |

### Test Scenarios

#### 1. Find nodes of a common type (happy path)

**Description:** Search for Sprite2D nodes in the current scene.

```json
{
  "type_name": "Sprite2D"
}
```

**Expected result:**
- `isError` is `false` or absent
- Response contains a list/array of node paths or node info objects
- Each entry references a node of type `Sprite2D` or a subtype
- If there are no Sprite2D nodes in the scene — empty array/list (not an error)

**Notes:** This is the baseline test. Open a scene known to have Sprite2D nodes before calling.

#### 2. Find nodes of a rare/absent type

**Description:** Search for a type that likely does not exist in the scene.

```json
{
  "type_name": "VehicleBody3D"
}
```

**Expected result:**
- `isError` is `false` or absent
- Returns empty list/array (not an error)
- Verify no crash or exception thrown

**Notes:** Validates graceful handling of "no results" case.

#### 3. Find with empty string type_name

**Description:** Edge case — empty string for type_name.

```json
{
  "type_name": ""
}
```

**Expected result:**
- Either returns an error (`isError: true`) with a descriptive message, OR returns empty results
- Should NOT crash the server or Godot plugin

**Notes:** Tests boundary validation on the type_name field.

#### 4. Find with non-existent type name (typo)

**Description:** Pass a type name that does not exist in Godot.

```json
{
  "type_name": "Sprite2DNonExistent"
}
```

**Expected result:**
- Either returns empty results or a clear error message
- No crash

---

## Tool: find_signal_connections

**Description:** Find all signal connections in the scene
**Godot endpoint:** `batch/find_connections`

### Parameters

None. Empty schema `{}`.

### Test Scenarios

#### 1. Find connections in a scene with signals (happy path)

**Description:** Call with no params on a scene that has signal connections set up.

```json
{}
```

**Expected result:**
- `isError` is `false` or absent
- Returns a list of signal connections, each containing:
  - Source node path
  - Signal name
  - Target node path
  - Method name (connected callable)
- At least one connection present if scene has wired signals

**Notes:** Before calling, ensure the open scene has at least one `signal.connect(...)` or editor-wired connection. Verify the structure of returned connection objects.

#### 2. Find connections in a scene with no signals

**Description:** Call on a scene with zero signal connections.

```json
{}
```

**Expected result:**
- `isError` is `false` or absent
- Returns empty list/array
- No error raised

**Notes:** Open a bare scene (e.g., just a root Node2D with no children or signals) before calling.

#### 3. Extra parameters are ignored

**Description:** Pass unexpected extra parameters.

```json
{
  "unexpected_param": "value"
}
```

**Expected result:**
- Tool should still work normally (extra params ignored)
- Returns same result as scenario 1 or 2

**Notes:** Validates that the empty schema does not break on extra input.

---

## Tool: batch_set_property

**Description:** Set a property on all nodes of a given type
**Godot endpoint:** `batch/set_property`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `type_name` | string (`NodeType`) | **Yes** | Node type name to target |
| `property` | string (`PropertyName`) | **Yes** | Property name (e.g. 'position', 'visible') |
| `value` | any (`PropertyValue`) | **Yes** | New value for the property |

### Test Scenarios

#### 1. Set `visible` to `false` on all Sprite2D nodes (happy path)

**Description:** Hide all Sprite2D nodes in the scene.

```json
{
  "type_name": "Sprite2D",
  "property": "visible",
  "value": false
}
```

**Expected result:**
- `isError` is `false` or absent
- Response indicates how many nodes were affected (or success confirmation)
- Verify by calling `find_nodes_by_type` with `type_name: "Sprite2D"` and checking each node's `visible` property
- Godot's undo system should record this action

**Notes:** This is a destructive operation. Verify undo works (Ctrl+Z in Godot should revert). Check that ALL Sprite2D nodes (not just one) were modified.

#### 2. Set `modulate` (color property) on all Label nodes

**Description:** Change modulate color on all Label nodes.

```json
{
  "type_name": "Label",
  "property": "modulate",
  "value": { "r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0 }
}
```

**Expected result:**
- `isError` is `false` or absent
- All Label nodes in the scene have their modulate set to red
- In Godot, Color is passed as an object {r, g, b, a}

**Notes:** Test that complex value types (Color objects) are handled correctly.

#### 3. Set property on a type with zero instances

**Description:** Try to set a property when no nodes of that type exist.

```json
{
  "type_name": "VehicleBody3D",
  "property": "mass",
  "value": 100
}
```

**Expected result:**
- `isError` is `false` or absent
- Returns success with 0 affected nodes, OR returns an informational message
- No crash

#### 4. Missing required parameter `property`

**Description:** Omit the `property` field.

```json
{
  "type_name": "Sprite2D",
  "value": true
}
```

**Expected result:**
- MCP layer should reject with a validation error (Zod schema requires `property`)
- `isError: true` with message about missing required field

#### 5. Missing required parameter `value`

**Description:** Omit the `value` field.

```json
{
  "type_name": "Sprite2D",
  "property": "visible"
}
```

**Expected result:**
- MCP layer should reject with validation error
- `isError: true`

#### 6. Set a non-existent property

**Description:** Try to set a property that doesn't exist on the target type.

```json
{
  "type_name": "Sprite2D",
  "property": "nonexistent_prop_xyz",
  "value": 42
}
```

**Expected result:**
- Either returns an error from Godot side, OR silently ignores
- `isError` may be `true` with descriptive message
- No crash

---

## Tool: find_node_references

**Description:** Find all references to a node across scenes and scripts
**Godot endpoint:** `batch/find_references`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `query` | string | **Yes** | Node path or name to search for |

### Test Scenarios

#### 1. Search for a known node path (happy path)

**Description:** Find all references to a node that is used in multiple places.

```json
{
  "query": "Player"
}
```

**Expected result:**
- `isError` is `false` or absent
- Returns list of references: scenes that contain the node, scripts that reference it, signal connections involving it
- At least one result if "Player" exists in the project

**Notes:** The `query` can be a node name or a path like "Player/Sprite2D". Test both forms.

#### 2. Search for a node path with slashes

**Description:** Search for a nested node.

```json
{
  "query": "Player/Sprite2D"
}
```

**Expected result:**
- Returns references specific to the nested node path
- May include scripts that `$Player/Sprite2D` or `get_node("Player/Sprite2D")`

#### 3. Search for a non-existent node

**Description:** Search for a node that doesn't exist anywhere.

```json
{
  "query": "ThisNodeDoesNotExistAnywhere"
}
```

**Expected result:**
- `isError` is `false` or absent
- Returns empty list/array
- No crash

#### 4. Empty query string

**Description:** Pass empty string.

```json
{
  "query": ""
}
```

**Expected result:**
- Either returns error or empty results
- Should not return ALL nodes as a result of empty query

---

## Tool: get_scene_dependencies

**Description:** Get all dependencies of a scene file (scripts, resources, sub-scenes)
**Godot endpoint:** `batch/get_dependencies`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | string | **Yes** | Scene file path |

### Test Scenarios

#### 1. Get dependencies of a scene with multiple deps (happy path)

**Description:** Query dependencies of a scene known to have scripts, resources, and/or sub-scenes.

```json
{
  "path": "res://scenes/main.tscn"
}
```

**Expected result:**
- `isError` is `false` or absent
- Returns dependency list containing:
  - Script files (`.gd`)
  - Resource files (`.tres`, `.res`, textures, materials)
  - Sub-scene references (`.tscn` files instantiated as children)
- Each dependency has its path and possibly its type

**Notes:** Replace `res://scenes/main.tscn` with an actual scene path from the test project. Verify the list matches what Godot's "Dependencies" dialog shows.

#### 2. Get dependencies of a minimal scene

**Description:** A scene with no scripts or external resources.

```json
{
  "path": "res://scenes/empty.tscn"
}
```

**Expected result:**
- Returns empty or minimal dependency list (may include built-in resources)
- No error

#### 3. Non-existent scene path

**Description:** Pass a path that doesn't exist.

```json
{
  "path": "res://scenes/DOES_NOT_EXIST.tscn"
}
```

**Expected result:**
- `isError: true` with descriptive error message (e.g., "Scene not found")
- No crash

#### 4. Invalid path format (no res:// prefix)

**Description:** Pass a path without the `res://` prefix.

```json
{
  "path": "scenes/main.tscn"
}
```

**Expected result:**
- Either Godot normalizes the path, or returns an error
- No crash

---

## Tool: cross_scene_set_property

**Description:** Set a property on nodes of a given type across multiple scenes
**Godot endpoint:** `batch/cross_scene_set`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `type_name` | string (`NodeType`) | **Yes** | Node type name to target |
| `property` | string (`PropertyName`) | **Yes** | Property name to set |
| `value` | any (`PropertyValue`) | **Yes** | New value |
| `confirm_no_undo` | boolean (optional, default `false`) | No | Acknowledges this is destructive and cannot be undone |

### Test Scenarios

#### 1. Set property across scenes with confirmation (happy path)

**Description:** Set `visible = false` on all Sprite2D nodes across all scenes in the project.

```json
{
  "type_name": "Sprite2D",
  "property": "visible",
  "value": false,
  "confirm_no_undo": true
}
```

**Expected result:**
- `isError` is `false` or absent
- Response indicates which scenes were modified and how many nodes per scene
- Multiple scene files on disk are changed
- This is a cross-scene file operation — unlike `batch_set_property` which works on the open scene only

**Notes:** **CRITICAL**: This modifies multiple scene files on disk. Use a test project copy. After the call, verify each affected scene file was actually changed by opening it and checking the property.

#### 2. Set property WITHOUT confirmation (should be rejected)

**Description:** Try to set without `confirm_no_undo: true`.

```json
{
  "type_name": "Sprite2D",
  "property": "visible",
  "value": false
}
```

**Expected result:**
- `confirm_no_undo` defaults to `false`
- The tool should **reject** this call or return an error message stating that confirmation is required
- No scene files are modified

**Notes:** This is a safety mechanism. The tool MUST NOT execute without explicit confirmation because cross-scene changes cannot be undone.

#### 3. Missing required parameters

**Description:** Omit `type_name`.

```json
{
  "property": "visible",
  "value": false,
  "confirm_no_undo": true
}
```

**Expected result:**
- MCP validation error from Zod (type_name is required)

#### 4. Set a numeric property across scenes

**Description:** Set `z_index` on all Node2D-derived types across scenes.

```json
{
  "type_name": "Node2D",
  "property": "z_index",
  "value": 10,
  "confirm_no_undo": true
}
```

**Expected result:**
- All Node2D (and subclass) nodes across all scenes get z_index = 10
- Report lists affected scenes and node counts

**Notes:** Node2D subtypes (Sprite2D, AnimatedSprite2D, etc.) should also be affected if Godot's type matching includes inheritance.

#### 5. Target a type with zero instances across all scenes

**Description:** Set property on a type that doesn't appear anywhere.

```json
{
  "type_name": "VehicleBody3D",
  "property": "mass",
  "value": 500,
  "confirm_no_undo": true
}
```

**Expected result:**
- `isError` is `false`
- Reports 0 affected scenes / 0 nodes
- No files modified

---

## Tool: find_script_references

**Description:** Find all scenes and nodes that use a specific script
**Godot endpoint:** `batch/find_script_refs`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `script_path` | string (`ScriptPath`) | **Yes** | Script file path (e.g. 'res://scripts/player.gd') |

### Test Scenarios

#### 1. Find references to a widely-used script (happy path)

**Description:** Find all scenes/nodes using a script that's attached to multiple nodes.

```json
{
  "script_path": "res://scripts/player.gd"
}
```

**Expected result:**
- `isError` is `false` or absent
- Returns list of scenes and nodes that have this script attached
- Each entry includes the scene path and node path
- If the script is used in 3 scenes, returns 3+ entries

**Notes:** Replace with an actual script path from the test project. Verify by manually checking Godot's "References" or by opening each listed scene.

#### 2. Find references to a script used nowhere

**Description:** An orphan script that is not attached to any node.

```json
{
  "script_path": "res://scripts/unused_orphan.gd"
}
```

**Expected result:**
- `isError` is `false` or absent
- Returns empty list
- No error

#### 3. Non-existent script path

**Description:** A script file that doesn't exist.

```json
{
  "script_path": "res://scripts/DOES_NOT_EXIST.gd"
}
```

**Expected result:**
- `isError: true` with descriptive error
- No crash

#### 4. Script path without res:// prefix

**Description:** Invalid path format.

```json
{
  "script_path": "scripts/player.gd"
}
```

**Expected result:**
- Either Godot normalizes and finds it, or returns an error
- No crash

---

## Tool: detect_circular_dependencies

**Description:** Detect circular dependencies in the project (scripts, scenes, resources)
**Godot endpoint:** `batch/detect_circular`

### Parameters

None. Empty schema `{}`. Takes no arguments at all — the handler doesn't even pass `args`.

### Test Scenarios

#### 1. Run on a project with no circular dependencies (happy path)

**Description:** Call on a well-structured project with no circular references.

```json
{}
```

**Expected result:**
- `isError` is `false` or absent
- Returns empty list of cycles, or a message stating "No circular dependencies found"
- Execution completes in reasonable time (< 10s for small projects)

#### 2. Run on a project WITH circular dependencies

**Description:** Set up two scripts that reference each other (script A extends/preloads script B, and B extends/preloads A), then call.

```json
{}
```

**Expected result:**
- Returns list of detected cycles
- Each cycle entry shows the chain of dependencies (e.g., `A.gd -> B.gd -> A.gd`)
- `isError` is `false` (detecting cycles is not an error, it's the expected output)

**Notes:** To set up this test, create two scripts:
  - `res://scripts/cycle_a.gd`: contains `const B = preload("res://scripts/cycle_b.gd")`
  - `res://scripts/cycle_b.gd`: contains `const A = preload("res://scripts/cycle_a.gd")`
  Then call this tool.

#### 3. Run on an empty project

**Description:** Minimal project with no custom scripts or scenes.

```json
{}
```

**Expected result:**
- Returns empty result set
- No error

---

## Cross-Tool Dependencies and Sequences

Some tools have natural dependencies on each other. The following sequences should be tested:

### Sequence 1: Find → Set → Verify

**Purpose:** Find all nodes of a type, set a property, then verify the change.

1. Call `find_nodes_by_type` with `{ "type_name": "Sprite2D" }` → note the returned node list
2. Call `batch_set_property` with `{ "type_name": "Sprite2D", "property": "visible", "value": false }`
3. Call `find_nodes_by_type` again → verify the nodes still appear (they exist, just hidden)
4. Read individual node properties via other tools to confirm `visible = false`

### Sequence 2: Find Script Refs → Cross-Scene Set

**Purpose:** Find all scenes using a script, then modify a property across those scenes.

1. Call `find_script_references` with `{ "script_path": "res://scripts/enemy.gd" }` → get list of scenes
2. Call `cross_scene_set_property` with `{ "type_name": "Enemy", "property": "speed", "value": 200, "confirm_no_undo": true }`
3. Open each affected scene and verify the property changed

### Sequence 3: Get Dependencies → Detect Circular

**Purpose:** Understand project structure before checking for cycles.

1. Call `get_scene_dependencies` on several scenes to build a dependency map
2. Call `detect_circular_dependencies` to find cycles
3. Cross-reference: verify the detected cycles align with the dependency chains from step 1

### Sequence 4: Find References → Batch Set (scoped)

**Purpose:** Find where a node is referenced, then batch-set on that type.

1. Call `find_node_references` with `{ "query": "Player" }` → understand impact
2. Call `batch_set_property` to modify all nodes of that type
3. Call `find_node_references` again → verify references are still valid (no broken refs)

---

## Notes on Testing Methodology

1. **Undo verification:** For `batch_set_property`, verify that Godot's undo (Ctrl+Z) reverts all changes made in a single batch call.

2. **Cross-scene safety:** `cross_scene_set_property` with `confirm_no_undo: false` MUST be rejected. This is a critical safety gate — cross-scene file modifications cannot be undone through Godot's undo system.

3. **Performance:** `detect_circular_dependencies` scans the entire project. For large projects (500+ files), monitor execution time. A timeout would indicate the tool needs optimization.

4. **Type inheritance:** When testing `batch_set_property` with `type_name: "Node2D"`, verify whether Godot's implementation matches only exact `Node2D` nodes or also subclasses (Sprite2D, AnimatedSprite2D, etc.). This is an implementation detail that affects expected results.

5. **MCP validation layer:** Tests for missing required parameters (scenarios like "missing property" or "missing value") test the Zod schema validation in the MCP SDK, not the Godot plugin. These should fail before any message reaches Godot.

6. **Bridge errors:** If the Godot bridge is disconnected, ALL tools should return `isError: true` with a connection error message. Test this by disconnecting the plugin and calling any tool.
