# Batch Tools — Test Plan

**Source file:** `server/src/tools/batch.ts`
**Godot endpoint prefix:** `batch/`
**Total tools:** 8

---

## Shared Types Reference

| Zod Schema | Type | Description |
|---|---|---|
| `NodeType` | `z.string()` | Node type name (e.g. `'Sprite2D'`, `'CharacterBody3D'`) |
| `ScriptPath` | `z.string()` | Script file path (e.g. `'res://scripts/player.gd'`) |
| `PropertyName` | `z.string()` | Property name (e.g. `'position'`, `'visible'`) |
| `PropertyValue` | `z.unknown()` | Any property value (string, number, bool, array, object) |

---

## Tool 1: `find_nodes_by_type`

**Description:** Find all nodes of a specific type in the scene.
**Godot endpoint:** `batch/find_by_type`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `type_name` | `string` | ✅ Yes | Node type name (e.g. `'Sprite2D'`, `'CharacterBody3D'`) |

### Behavior

Searches the currently open scene for all nodes matching the given class type. Returns a list of matching nodes with their paths.

### Test Scenarios

---

#### S-1.1: Happy path — find Sprite2D nodes

**Description:** Search for all `Sprite2D` nodes in a scene that contains at least two such nodes.

**Params:**
```json
{
  "type_name": "Sprite2D"
}
```

**Expected result:** An array of node paths (e.g., `["Player/Sprite2D", "Enemy/Sprite2D"]`) with count > 0.

**Notes:** Requires a scene with Sprite2D nodes to be open in the editor. The response format is a JSON object with a `nodes` array or flat array of node paths.

---

#### S-1.2: Happy path — find Node2D (base class)

**Description:** Search for `Node2D` — should match both `Node2D` and all its subclasses (`Sprite2D`, `CharacterBody2D`, etc.).

**Params:**
```json
{
  "type_name": "Node2D"
}
```

**Expected result:** Array of node paths including all 2D nodes regardless of specific subclass.

**Notes:** Verifies inheritance-aware matching.

---

#### S-1.3: Happy path — find Node (universal base)

**Description:** Search for `Node` — should match every node in the scene.

**Params:**
```json
{
  "type_name": "Node"
}
```

**Expected result:** Array containing every node in the scene tree.

**Notes:** Tests that the base class lookup works. Response size may be large for complex scenes.

---

#### S-1.4: Edge case — type that does not exist in the scene

**Description:** Search for a node type that is not present in the current scene.

**Params:**
```json
{
  "type_name": "GPUParticles3D"
}
```

**Expected result:** Empty array `[]` (not an error).

**Notes:** Should not throw an error — empty result is the correct behavior.

---

#### S-1.5: Edge case — invalid type name (non-existent Godot class)

**Description:** Search for a type name that does not correspond to any Godot class.

**Params:**
```json
{
  "type_name": "NonExistentClassXYZ"
}
```

**Expected result:** Either an error response with `isError: true` or an empty array `[]`. The tool should not crash.

**Notes:** Behavior depends on Godot-side validation — may reject with an error or return empty.

---

#### S-1.6: Edge case — empty string type_name

**Description:** Pass an empty string as the type name.

**Params:**
```json
{
  "type_name": ""
}
```

**Expected result:** Zod validation error on the server side (since `NodeType` is `z.string()` with `.describe()` but no `.min()` constraint) OR an error from Godot.

**Notes:** The Zod schema does not enforce non-empty, so the server passes it through. Godot side may reject or return empty results.

---

#### S-1.7: Edge case — missing required parameter

**Description:** Call the tool without providing `type_name`.

**Params:**
```json
{}
```

**Expected result:** Zod validation error — `type_name` is required in the schema (`inputSchema` has `type_name: NodeType` with no `.optional()`).

---

## Tool 2: `find_signal_connections`

**Description:** Find all signal connections in the scene.
**Godot endpoint:** `batch/find_connections`

### Parameters

None.

### Behavior

Scans the currently open scene and returns all signal connections: which nodes emit which signals to which target nodes and methods.

### Test Scenarios

---

#### S-2.1: Happy path — scene with signal connections

**Description:** Run in a scene that has at least one signal connection (e.g., Button's `pressed` connected to a method).

**Params:**
```json
{}
```

**Expected result:** Array of objects, each containing `source` (node path), `signal` (signal name), `target` (target node path), `method` (target method name).

**Notes:** The exact property names in the response depend on the Godot-side implementation.

---

#### S-2.2: Happy path — scene with no signal connections

**Description:** Run in a scene that has no signal connections (e.g., a fresh empty scene).

**Params:**
```json
{}
```

**Expected result:** Empty array `[]`.

**Notes:** Should not error — empty result is valid.

---

#### S-2.3: Happy path — scene with multi-signal node

**Description:** Run in a scene where one node has multiple signal connections.

**Params:**
```json
{}
```

**Expected result:** The node appears multiple times in the results, once per connection.

**Notes:** Verifies that all connections from a single node are reported.

---

#### S-2.4: Edge case — no scene open

**Description:** Call the tool when no scene is open in the editor.

**Params:**
```json
{}
```

**Expected result:** Error response (`isError: true`) or empty array, depending on Godot-side handling.

**Notes:** Should not crash the server.

---

## Tool 3: `batch_set_property`

**Description:** Set a property on all nodes of a given type.
**Godot endpoint:** `batch/set_property`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `type_name` | `string` | ✅ Yes | Node type name (e.g. `'Sprite2D'`) |
| `property` | `string` | ✅ Yes | Property name (e.g. `'visible'`) |
| `value` | `unknown` | ✅ Yes | New value for the property |

### Behavior

Finds all nodes of the given type in the current scene and sets the specified property to the given value on each. Returns a count of nodes modified (or an array of modified node paths).

### Test Scenarios

---

#### S-3.1: Happy path — hide all Sprite2D nodes

**Description:** Set `visible` to `false` on all Sprite2D nodes in the scene.

**Params:**
```json
{
  "type_name": "Sprite2D",
  "property": "visible",
  "value": false
}
```

**Expected result:** Success response with count of modified nodes > 0. All Sprite2D nodes should now be invisible.

**Notes:** Follow up with `find_nodes_by_type` + `get_node_properties` to verify the change took effect.

---

#### S-3.2: Happy path — set position on all Node2D nodes

**Description:** Set `position` to `[0, 0]` on all Node2D nodes.

**Params:**
```json
{
  "type_name": "Node2D",
  "property": "position",
  "value": [0, 0]
}
```

**Expected result:** Success. All Node2D nodes moved to origin.

---

#### S-3.3: Happy path — no matching nodes

**Description:** Set a property on a type that has no instances in the scene.

**Params:**
```json
{
  "type_name": "Camera3D",
  "property": "fov",
  "value": 90
}
```

**Expected result:** Success response with count = 0, or a message indicating no nodes were found/modified.

**Notes:** Should not error — zero modifications is valid.

---

#### S-3.4: Edge case — invalid property name

**Description:** Try to set a property that does not exist on the given node type.

**Params:**
```json
{
  "type_name": "Sprite2D",
  "property": "non_existent_prop",
  "value": 123
}
```

**Expected result:** Error from Godot (property does not exist).

---

#### S-3.5: Edge case — read-only property

**Description:** Try to set a read-only property.

**Params:**
```json
{
  "type_name": "Node2D",
  "property": "global_position",
  "value": [100, 200]
}
```

**Expected result:** Error from Godot (cannot set read-only property) or silent failure.

---

#### S-3.6: Edge case — type mismatch on value

**Description:** Pass a string value for a numeric property.

**Params:**
```json
{
  "type_name": "Sprite2D",
  "property": "position",
  "value": "not_a_vector"
}
```

**Expected result:** Error from Godot (type mismatch).

---

#### S-3.7: Edge case — missing required parameter

**Description:** Omit `value`.

**Params:**
```json
{
  "type_name": "Sprite2D",
  "property": "visible"
}
```

**Expected result:** Zod validation error — `value` is required.

---

## Tool 4: `find_node_references`

**Description:** Find all references to a node across scenes and scripts.
**Godot endpoint:** `batch/find_references`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `query` | `string` | ✅ Yes | Node path or name to search for |

### Behavior

Searches across all scenes and scripts in the project for references to a specific node. Returns where the node is referenced (scene files, script files, line numbers).

### Test Scenarios

---

#### S-4.1: Happy path — search for a node that is referenced

**Description:** Search for a node name that appears in multiple scenes and scripts.

**Params:**
```json
{
  "query": "Player"
}
```

**Expected result:** Array of references, each with scene/script path and optionally line number or node path.

**Notes:** Requires a project with scenes referencing a node named "Player".

---

#### S-4.2: Happy path — search for a node path with hierarchy

**Description:** Search using a full path like `Player/Sprite2D`.

**Params:**
```json
{
  "query": "Player/Sprite2D"
}
```

**Expected result:** References specific to that exact path.

---

#### S-4.3: Happy path — node not found

**Description:** Search for a node name that does not exist in any scene or script.

**Params:**
```json
{
  "query": "NonExistentNode_XYZ123"
}
```

**Expected result:** Empty array `[]`.

**Notes:** Should not error — no matches is valid.

---

#### S-4.4: Edge case — empty query

**Description:** Pass an empty string as the query.

**Params:**
```json
{
  "query": ""
}
```

**Expected result:** Error from Godot (invalid query) or empty results.

---

#### S-4.5: Edge case — special characters in query

**Description:** Search with characters that may need escaping (e.g., `$`, `%`, `.`).

**Params:**
```json
{
  "query": "%Player"
}
```

**Expected result:** Should handle gracefully — either find nodes with that name or return empty.

---

#### S-4.6: Edge case — missing required parameter

**Description:** Call without providing `query`.

**Params:**
```json
{}
```

**Expected result:** Zod validation error — `query` is required.

---

## Tool 5: `get_scene_dependencies`

**Description:** Get all dependencies of a scene file (scripts, resources, sub-scenes).
**Godot endpoint:** `batch/get_dependencies`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | `string` | ✅ Yes | Scene file path (e.g. `'res://scenes/main.tscn'`) |

### Behavior

Analyzes a scene file and returns all its dependencies: attached scripts, resources (textures, materials, etc.), and instantiated sub-scenes.

### Test Scenarios

---

#### S-5.1: Happy path — scene with multiple dependencies

**Description:** Get dependencies for a scene that has scripts, resources, and sub-scenes.

**Params:**
```json
{
  "path": "res://scenes/main.tscn"
}
```

**Expected result:** Object or array with categorized dependencies (e.g., `scripts: [...]`, `resources: [...]`, `sub_scenes: [...]`).

**Notes:** Requires a non-trivial scene to be in the project.

---

#### S-5.2: Happy path — empty scene (no dependencies)

**Description:** Get dependencies for an empty scene with just a root Node2D.

**Params:**
```json
{
  "path": "res://scenes/empty.tscn"
}
```

**Expected result:** Empty dependency lists or minimal result containing only engine-internal resources.

---

#### S-5.3: Happy path — scene with nested scene instances

**Description:** Get dependencies for a scene that instantiates other scenes (nested scene references).

**Params:**
```json
{
  "path": "res://scenes/parent_scene.tscn"
}
```

**Expected result:** The sub-scene paths appear in the dependencies.

---

#### S-5.4: Edge case — non-existent path

**Description:** Query a scene file that does not exist on disk.

**Params:**
```json
{
  "path": "res://scenes/non_existent.tscn"
}
```

**Expected result:** Error response (`isError: true`) with a "file not found" message.

---

#### S-5.5: Edge case — non-scene file path

**Description:** Query a path that points to a non-scene file (e.g., a script or resource).

**Params:**
```json
{
  "path": "res://scripts/player.gd"
}
```

**Expected result:** Error from Godot (not a scene file) or empty results.

---

#### S-5.6: Edge case — path without res:// prefix

**Description:** Use a relative path without the `res://` prefix.

**Params:**
```json
{
  "path": "scenes/main.tscn"
}
```

**Expected result:** Likely an error — Godot paths must use `res://` prefix.

---

#### S-5.7: Edge case — missing required parameter

**Description:** Call without `path`.

**Params:**
```json
{}
```

**Expected result:** Zod validation error — `path` is required.

---

## Tool 6: `cross_scene_set_property`

**Description:** Set a property on nodes of a given type across multiple scenes.
**Godot endpoint:** `batch/cross_scene_set`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `type_name` | `string` | ✅ Yes | — | Node type name (e.g. `'Sprite2D'`) |
| `property` | `string` | ✅ Yes | — | Property name (e.g. `'visible'`) |
| `value` | `unknown` | ✅ Yes | — | New value for the property |
| `confirm_no_undo` | `boolean` | ❌ No | `false` | Set to `true` to acknowledge this is destructive and cannot be undone |

### Behavior

Scans ALL scenes in the project (not just the currently open one), finds nodes of the given type, and sets the property on each. This is destructive — once applied, the changes are written to scene files and cannot be undone via the Godot undo system. The `confirm_no_undo` flag serves as a safety guard.

### Test Scenarios

---

#### S-6.1: Happy path — with confirmation

**Description:** Set a property across all scenes with `confirm_no_undo: true`.

**Params:**
```json
{
  "type_name": "Sprite2D",
  "property": "visible",
  "value": false,
  "confirm_no_undo": true
}
```

**Expected result:** Success response with count of modified nodes across all scenes. Scene files are saved with changes.

**Notes:** This is destructive. Use only in a test project.

---

#### S-6.2: Happy path — no matching nodes

**Description:** Run on a type that has no instances in any scene.

**Params:**
```json
{
  "type_name": "GPUParticles3D",
  "property": "emitting",
  "value": false,
  "confirm_no_undo": true
}
```

**Expected result:** Success with count = 0. No scenes modified.

---

#### S-6.3: Edge case — confirm_no_undo default (false)

**Description:** Call without providing `confirm_no_undo` — should use default `false`.

**Params:**
```json
{
  "type_name": "Sprite2D",
  "property": "visible",
  "value": true
}
```

**Expected result:** Either the operation is rejected with an error asking for confirmation, or it proceeds with a warning. The exact behavior depends on the Godot-side implementation.

**Notes:** The default is `false`, meaning the tool should NOT proceed destructively by default. The Godot side should check this flag.

---

#### S-6.4: Edge case — confirm_no_undo explicitly false

**Description:** Explicitly pass `confirm_no_undo: false`.

**Params:**
```json
{
  "type_name": "Sprite2D",
  "property": "visible",
  "value": true,
  "confirm_no_undo": false
}
```

**Expected result:** Should be rejected or require confirmation, same as S-6.3.

---

#### S-6.5: Edge case — missing required parameters

**Description:** Call without `type_name`.

**Params:**
```json
{
  "property": "visible",
  "value": true,
  "confirm_no_undo": true
}
```

**Expected result:** Zod validation error — `type_name` is required.

---

#### S-6.6: Edge case — missing required property

**Description:** Call without `property`.

**Params:**
```json
{
  "type_name": "Sprite2D",
  "value": true,
  "confirm_no_undo": true
}
```

**Expected result:** Zod validation error — `property` is required.

---

#### S-6.7: Edge case — non-boolean confirm_no_undo

**Description:** Pass a non-boolean value for `confirm_no_undo`.

**Params:**
```json
{
  "type_name": "Sprite2D",
  "property": "visible",
  "value": true,
  "confirm_no_undo": "yes"
}
```

**Expected result:** Zod validation error — `confirm_no_undo` is `z.boolean()`.

---

#### S-6.8: Edge case — invalid property name

**Description:** Try to set a non-existent property across scenes.

**Params:**
```json
{
  "type_name": "Sprite2D",
  "property": "non_existent_prop",
  "value": "test",
  "confirm_no_undo": true
}
```

**Expected result:** Error from Godot (property does not exist).

---

## Tool 7: `find_script_references`

**Description:** Find all scenes and nodes that use a specific script.
**Godot endpoint:** `batch/find_script_refs`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `script_path` | `string` | ✅ Yes | Script file path (e.g. `'res://scripts/player.gd'`) |

### Behavior

Searches all scenes in the project for nodes that have the specified script attached. Returns the scene paths and node paths where the script is used.

### Test Scenarios

---

#### S-7.1: Happy path — script used in multiple scenes

**Description:** Find all references to a script that is attached to nodes in multiple scenes.

**Params:**
```json
{
  "script_path": "res://scripts/player.gd"
}
```

**Expected result:** Array of results, each with scene path and node path(s) where the script is attached.

**Notes:** Requires a project with the script attached to nodes in at least one scene.

---

#### S-7.2: Happy path — script not used anywhere

**Description:** Search for a script that exists on disk but is not attached to any node.

**Params:**
```json
{
  "script_path": "res://scripts/unused_script.gd"
}
```

**Expected result:** Empty array `[]`.

**Notes:** Should not error — no usages is valid.

---

#### S-7.3: Edge case — non-existent script path

**Description:** Search for a script file that does not exist.

**Params:**
```json
{
  "script_path": "res://scripts/non_existent.gd"
}
```

**Expected result:** Error response (`isError: true`) — file not found.

---

#### S-7.4: Edge case — path without res:// prefix

**Description:** Use a path without the `res://` prefix.

**Params:**
```json
{
  "script_path": "scripts/player.gd"
}
```

**Expected result:** Likely an error — Godot expects `res://` paths.

---

#### S-7.5: Edge case — path to non-script file

**Description:** Pass a path to a scene file or resource instead of a script.

**Params:**
```json
{
  "script_path": "res://scenes/main.tscn"
}
```

**Expected result:** Error from Godot (not a script file) or empty results.

---

#### S-7.6: Edge case — missing required parameter

**Description:** Call without `script_path`.

**Params:**
```json
{}
```

**Expected result:** Zod validation error — `script_path` is required.

---

#### S-7.7: Edge case — empty string path

**Description:** Pass an empty string.

**Params:**
```json
{
  "script_path": ""
}
```

**Expected result:** Error from Godot (invalid path).

---

## Tool 8: `detect_circular_dependencies`

**Description:** Detect circular dependencies in the project (scripts, scenes, resources).
**Godot endpoint:** `batch/detect_circular`

### Parameters

None.

### Behavior

Analyzes the entire project for circular dependency chains: scene A depends on scene B which depends on scene A, or script A extends script B which extends script A, or resource A references resource B which references resource A.

### Test Scenarios

---

#### S-8.1: Happy path — project with no circular dependencies

**Description:** Run in a clean project with no circular dependencies.

**Params:**
```json
{}
```

**Expected result:** Empty array `[]` or a message indicating no circular dependencies found.

---

#### S-8.2: Happy path — project with circular scene dependencies

**Description:** Run in a project where scene A instantiates scene B, and scene B instantiates scene A.

**Params:**
```json
{}
```

**Expected result:** Array of circular dependency chains, each showing the cycle path (e.g., `["res://scenes/A.tscn", "res://scenes/B.tscn", "res://scenes/A.tscn"]`).

**Notes:** Requires setting up circular scene references. This may not be possible through normal Godot workflows (Godot prevents circular scene instancing at edit time), but pre-existing circular .tscn files could be manually crafted for testing.

---

#### S-8.3: Happy path — project with circular script inheritance

**Description:** Run in a project where script A extends script B and script B extends script A.

**Params:**
```json
{}
```

**Expected result:** Circular dependency detected in scripts.

**Notes:** Similar to S-8.2 — Godot normally prevents this, but manually crafted files could test the detection logic.

---

#### S-8.4: Edge case — empty project (no files)

**Description:** Run in a project with minimal or no files.

**Params:**
```json
{}
```

**Expected result:** Empty results — no dependencies to detect.

**Notes:** Should not error.

---

#### S-8.5: Edge case — project with only one scene

**Description:** Run in a project with a single scene and no scripts.

**Params:**
```json
{}
```

**Expected result:** Empty results — no circular dependencies possible with one file.

---

## Summary Matrix

| # | Tool | Params | Godot Endpoint | No-Param | Has Required | Has Optional |
|---|---|---|---|---|---|---|
| 1 | `find_nodes_by_type` | 1 | `batch/find_by_type` | ❌ | `type_name` | — |
| 2 | `find_signal_connections` | 0 | `batch/find_connections` | ✅ | — | — |
| 3 | `batch_set_property` | 3 | `batch/set_property` | ❌ | `type_name`, `property`, `value` | — |
| 4 | `find_node_references` | 1 | `batch/find_references` | ❌ | `query` | — |
| 5 | `get_scene_dependencies` | 1 | `batch/get_dependencies` | ❌ | `path` | — |
| 6 | `cross_scene_set_property` | 4 | `batch/cross_scene_set` | ❌ | `type_name`, `property`, `value` | `confirm_no_undo` |
| 7 | `find_script_references` | 1 | `batch/find_script_refs` | ❌ | `script_path` | — |
| 8 | `detect_circular_dependencies` | 0 | `batch/detect_circular` | ✅ | — | — |

## Test Execution Notes

1. **Godot editor must be running** with the MCP plugin active and connected for all tests.
2. **A test project should be prepared** with:
   - Multiple scenes containing various node types (`Sprite2D`, `Node2D`, `Control`, `Button`, etc.)
   - Signal connections between nodes (e.g., Button `pressed` signal)
   - Scripts attached to nodes across scenes
   - Scene dependencies (nested scene instances)
   - Resources referenced by scenes
3. **For destructive tests** (`cross_scene_set_property`), use a copy of the test project or be prepared to revert via version control.
4. **Zod validation errors** on the server side return MCP error responses before reaching Godot. Test both server-side and Godot-side error handling.
5. **Snapshot/visual tests** are not applicable to batch tools — they return JSON data.
6. **Naming convention for test identifiers**: `S-{tool_number}.{scenario_number}` (e.g., `S-1.1` for Tool 1, scenario 1).

---

*Generated from `server/src/tools/batch.ts` — 8 tools, 39 test scenarios.*
