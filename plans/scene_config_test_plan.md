# Test Plan: Scene Configuration Tools (`scene_config.ts`)

**Source**: `server/src/tools/scene_config.ts`
**GDScript backend**: `addons/godot_mcp/commands/scene_config_commands.gd`
**Tools count**: 6
**Registration function**: `registerSceneConfigTools(server, bridge)`
**Backend route prefix**: `scene_config/`

---

## Shared Type Definitions (from `shared-types.ts`)

| Schema | Type | Description |
|---|---|---|
| `NodePath` | `z.string()` | Node path in scene tree, e.g. `"Player"`, `"Player/Sprite2D"`. Use `""` for the scene root itself. Paths are relative to the currently open scene. |
| `OptionalScenePath` | `z.string().optional()` | Scene file path, e.g. `"res://scenes/main.tscn"`. Optional — defaults to current scene when omitted. |

---

## Dependency Graph & Execution Order

3 of 6 tools are **read-only** (no side effects). 3 tools **mutate** the scene and trigger undo/redo.

| Tool | Type | Prerequisites |
|---|---|---|
| `get_scene_inheritance` | Read-only | A scene must be open (or `scene_path` must point to an existing `.tscn` file) |
| `set_scene_unique_name` | **Mutates** | A scene must be open with a node at the given `node_path`. Before calling: `create_scene` → `add_node`. After calling: verify with `get_scene_tree` that the node has `unique_name_in_owner` set. |
| `get_scene_groups` | Read-only | A scene must be open (or `scene_path` must point to an existing `.tscn` file). Most useful after nodes have been added to groups via `set_scene_group`. |
| `set_scene_group` | **Mutates** | A scene must be open with a node at the given `node_path`. Before calling: `create_scene` → `add_node`. After calling: verify with `get_scene_groups`. |
| `get_scene_meta` | Read-only | A scene must be open (or `scene_path` must point to an existing `.tscn` file). Most useful after metadata has been set via `set_scene_meta`. |
| `set_scene_meta` | **Mutates** | A scene must be open. Only works on the **current** scene — passing a non-empty `scene_path` returns an error. After calling: verify with `get_scene_meta`. |

**Recommended setup sequence** (once, before all tests):

```
1. create_scene({ path: "res://test_scenes/scene_config_test.tscn", root_node_type: "Node2D" })
2. add_node({ parent_path: "", type: "Sprite2D", name: "Player" })
3. add_node({ parent_path: "Player", type: "Sprite2D", name: "Weapon" })
4. add_node({ parent_path: "", type: "Node", name: "EnemyManager" })
5. open_scene({ path: "res://test_scenes/scene_config_test.tscn" })
```

This creates a scene with:
- Root (Node2D)
  - `Player` (Sprite2D)
    - `Weapon` (Sprite2D)
  - `EnemyManager` (Node)

---

## Tool: `get_scene_inheritance`

**Description**: Get the scene inheritance chain (instantiated scenes, inherited scenes)
**Backend route**: `scene_config/get_inheritance`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `scene_path` | `string` | ❌ No | `""` (current scene) | Scene file path, e.g. `"res://scenes/main.tscn"`. Empty or omitted = current scene. |

### Test Scenarios

#### Scenario 1: Get inheritance for current scene (no params)

- **Description**: Call with no parameters to query the currently open scene's inheritance chain.
- **Params**:
  ```json
  {}
  ```
- **Expected result**: Success response (`isError` absent or `false`). Response contains:
  - `success: true`
  - `scene_path`: string — the path of the current scene (e.g. `"res://test_scenes/scene_config_test.tscn"`)
  - `inheritance_chain`: array — for a scene created from scratch (not inherited), should be a single-element array containing the scene's own path
  - `depth`: number — should be `1` for a non-inherited scene
- **Notes**: The GDScript implementation reads the `.tscn` file to find `inherits="res://..."` directives. A scene created via `create_scene` does not inherit from another scene.
- **What to pay attention to**: `inheritance_chain` should contain at least one element (the scene itself). `depth` should match the length of `inheritance_chain`. If `scene_path` in the response is empty — there is a problem with determining the current scene.

#### Scenario 2: Get inheritance for a specific scene path

- **Description**: Pass an explicit scene file path.
- **Params**:
  ```json
  { "scene_path": "res://test_scenes/scene_config_test.tscn" }
  ```
- **Expected result**: Success response. Same structure as Scenario 1. `scene_path` in result should match the input.
- **What to pay attention to**: The result should be identical to Scenario 1 if `scene_config_test.tscn` is the currently open scene.

#### Scenario 3: Non-existent scene path

- **Description**: Pass a path to a scene that does not exist.
- **Params**:
  ```json
  { "scene_path": "res://nonexistent/does_not_exist.tscn" }
  ```
- **Expected result**: Error response (`isError: true`). Message should indicate "Scene not found: res://nonexistent/does_not_exist.tscn".
- **What to pay attention to**: The error message should contain the specified path. There should be no crash or empty response.

#### Scenario 4: Scene inheritance chain (requires inherited scene)

- **Description**: Test with a scene that inherits from another scene. Requires creating a base scene first, then a derived scene.
- **Setup**:
  ```
  1. create_scene({ path: "res://test_scenes/base_scene.tscn", root_node_type: "Node2D" })
  2. save_scene({ path: "res://test_scenes/base_scene.tscn" })
  3. create_scene({ path: "res://test_scenes/derived_scene.tscn", root_node_type: "Node2D" })
     // In Godot editor: Scene → New Inherited Scene → select base_scene.tscn
     // OR use execute_editor_script to programmatically create an inherited scene
  ```
- **Params**:
  ```json
  { "scene_path": "res://test_scenes/derived_scene.tscn" }
  ```
- **Expected result**: Success response. `inheritance_chain` should contain `["res://test_scenes/derived_scene.tscn", "res://test_scenes/base_scene.tscn"]`. `depth` should be `2`.
- **Notes**: This scenario is harder to set up programmatically. May require using `execute_editor_script` to create the inheritance relationship. If the tool only reads `.tscn` files, the `inherits="..."` directive must be present in the file.
- **What to pay attention to**: The chain should go from descendant to ancestor. Verify that `depth` matches the array length. If Godot does not support programmatic creation of inherited scenes via MCP — this scenario may be skipped.

---

## Tool: `set_scene_unique_name`

**Description**: Toggle the unique name flag on a node (accessible as `%NodeName`)
**Backend route**: `scene_config/set_unique_name`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `node_path` | `string` (NodePath) | ✅ Yes | — | Node path within the scene (e.g. `"Player"`, `"Player/Weapon"`) |
| `unique` | `boolean` | ❌ No | `true` | `true` to enable unique name, `false` to disable |

### Test Scenarios

#### Scenario 1: Enable unique name on a node (default behavior)

- **Description**: Call with only `node_path`, relying on `unique` defaulting to `true`.
- **Params**:
  ```json
  { "node_path": "Player" }
  ```
- **Expected result**: Success response. Expected fields:
  - `success: true`
  - `node: "Player"`
  - `unique: true`
  - `message: "Unique name enabled"`
- **Notes**: The scene will be marked as unsaved after this operation. The node's `unique_name_in_owner` property is set to `true`.
- **What to pay attention to**: Verify that `unique` in the response is `true`. Ensure that the scene is marked as modified (unsaved). After this call, the node should be accessible as `%Player` in GDScript.

#### Scenario 2: Explicitly enable unique name

- **Description**: Explicitly pass `unique: true`.
- **Params**:
  ```json
  { "node_path": "Player", "unique": true }
  ```
- **Expected result**: Same as Scenario 1. Success with `unique: true`, `message: "Unique name enabled"`.
- **What to pay attention to**: The result should be identical to Scenario 1.

#### Scenario 3: Disable unique name

- **Description**: Disable the unique name flag on a node that previously had it enabled.
- **Setup**: First run Scenario 1 or 2 to enable unique name.
- **Params**:
  ```json
  { "node_path": "Player", "unique": false }
  ```
- **Expected result**: Success response:
  - `success: true`
  - `node: "Player"`
  - `unique: false`
  - `message: "Unique name disabled"`
- **What to pay attention to**: `message` should contain "disabled" (not "enabled"). Verify that the node is no longer accessible as `%Player`.

#### Scenario 4: Enable unique name on a nested node

- **Description**: Set unique name on a child node at a deeper path.
- **Params**:
  ```json
  { "node_path": "Player/Weapon", "unique": true }
  ```
- **Expected result**: Success response with `node: "Player/Weapon"`, `unique: true`.
- **What to pay attention to**: The path should be exactly `"Player/Weapon"`, not `"Weapon"`. Verify that it works with nested nodes.

#### Scenario 5: Empty node_path (error)

- **Description**: Pass an empty string for `node_path`.
- **Params**:
  ```json
  { "node_path": "" }
  ```
- **Expected result**: Error response. GDScript handler explicitly checks `node_path.is_empty()` and returns `{"success": false, "error": "Node path cannot be empty"}`.
- **What to pay attention to**: The error should contain "Node path cannot be empty". This is a GDScript-side check, not Zod validation.

#### Scenario 6: Non-existent node path (error)

- **Description**: Pass a path to a node that does not exist in the current scene.
- **Params**:
  ```json
  { "node_path": "NonExistentNode/Deep/Nested" }
  ```
- **Expected result**: Error response. GDScript handler uses `root.get_node_or_null(node_path)` and returns `{"success": false, "error": "Node not found: NonExistentNode/Deep/Nested"}`.
- **What to pay attention to**: The error message should contain the specified path. Verify that there is no crash when accessing a non-existent node.

#### Scenario 7: No scene open (error)

- **Description**: If no scene is open in the editor, calling this tool should fail.
- **Setup**: Close all scenes in the editor, or ensure no scene is active.
- **Params**:
  ```json
  { "node_path": "Player" }
  ```
- **Expected result**: Error response: `{"success": false, "error": "No scene open"}`.
- **Notes**: This is an environment-dependent scenario. May be skipped if the test environment always has a scene open.
- **What to pay attention to**: The error should clearly indicate that no scene is open.

---

## Tool: `get_scene_groups`

**Description**: Get all groups used in a scene and which nodes belong to each
**Backend route**: `scene_config/get_groups`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `scene_path` | `string` | ❌ No | `""` (current scene) | Scene file path. Empty or omitted = current scene. |

### Test Scenarios

#### Scenario 1: Get groups from current scene (empty scene, no groups)

- **Description**: Query groups on a freshly created scene with no groups assigned.
- **Params**:
  ```json
  {}
  ```
- **Expected result**: Success response:
  - `success: true`
  - `groups: []` — empty array since no nodes are in any groups
  - `group_count: 0`
- **What to pay attention to**: `groups` should be an empty array (not `null`, not `undefined`). `group_count` should be `0`.

#### Scenario 2: Get groups after adding nodes to groups

- **Description**: First add nodes to groups, then query.
- **Setup**:
  ```
  1. set_scene_group({ node_path: "Player", group: "player_team", add: true })
  2. set_scene_group({ node_path: "EnemyManager", group: "enemy_team", add: true })
  3. set_scene_group({ node_path: "Player", group: "persist", add: true })
  ```
- **Params**:
  ```json
  {}
  ```
- **Expected result**: Success response:
  - `success: true`
  - `groups`: array of objects, each with `name` and `nodes` fields. Should contain:
    - `{ name: "player_team", nodes: ["Player"] }`
    - `{ name: "enemy_team", nodes: ["EnemyManager"] }`
    - `{ name: "persist", nodes: ["Player"] }`
  - `group_count: 3`
- **Notes**: The GDScript implementation recursively collects groups from all nodes in the scene tree.
- **What to pay attention to**: Verify that each group contains a `name` field and a `nodes` field (array of node paths). Ensure that the `Player` node is present in two groups (`player_team` and `persist`). The order of groups may be arbitrary.

#### Scenario 3: Get groups from a specific scene file

- **Description**: Pass an explicit scene path.
- **Params**:
  ```json
  { "scene_path": "res://test_scenes/scene_config_test.tscn" }
  ```
- **Expected result**: Success response with the same structure as Scenario 2 (if groups were set on the current scene which is this file).
- **What to pay attention to**: If the scene is not the current one, GDScript loads it via `ResourceLoader.load()` and instantiate. The result should contain the same groups.

#### Scenario 4: Non-existent scene path (error)

- **Params**:
  ```json
  { "scene_path": "res://nonexistent/no_groups.tscn" }
  ```
- **Expected result**: Error response: `"Scene not found: res://nonexistent/no_groups.tscn"`.
- **What to pay attention to**: The error should contain the path.

#### Scenario 5: Get groups with nodes in nested paths

- **Description**: Add a child node to a group, then verify the group reports the full nested path.
- **Setup**:
  ```
  1. set_scene_group({ node_path: "Player/Weapon", group: "weapons", add: true })
  ```
- **Params**:
  ```json
  {}
  ```
- **Expected result**: Success response. `groups` should include `{ name: "weapons", nodes: ["Player/Weapon"] }`.
- **What to pay attention to**: The node path in the group should be the full path (`"Player/Weapon"`, not `"Weapon"`). This verifies that `_collect_groups` correctly constructs paths.

---

## Tool: `set_scene_group`

**Description**: Add or remove a node from a group
**Backend route**: `scene_config/set_group`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `node_path` | `string` (NodePath) | ✅ Yes | — | Node path within the current scene |
| `group` | `string` | ✅ Yes | — | Group name |
| `add` | `boolean` | ❌ No | `true` | `true` to add to group, `false` to remove |

### Test Scenarios

#### Scenario 1: Add a node to a group (default behavior)

- **Description**: Call with only `node_path` and `group`, relying on `add` defaulting to `true`.
- **Params**:
  ```json
  { "node_path": "Player", "group": "player_team" }
  ```
- **Expected result**: Success response:
  - `success: true`
  - `node: "Player"`
  - `group: "player_team"`
  - `action: "added"`
- **Notes**: The scene is marked as unsaved. The operation goes through undo/redo.
- **What to pay attention to**: `action` should be `"added"`, not `"add"`. Verify that the scene is marked as modified.

#### Scenario 2: Explicitly add a node to a group

- **Params**:
  ```json
  { "node_path": "EnemyManager", "group": "enemies", "add": true }
  ```
- **Expected result**: Same structure as Scenario 1, with `node: "EnemyManager"`, `group: "enemies"`, `action: "added"`.
- **What to pay attention to**: Identical to Scenario 1 in response structure.

#### Scenario 3: Remove a node from a group

- **Description**: First add a node to a group, then remove it.
- **Setup**: Run Scenario 1 first.
- **Params**:
  ```json
  { "node_path": "Player", "group": "player_team", "add": false }
  ```
- **Expected result**: Success response:
  - `success: true`
  - `node: "Player"`
  - `group: "player_team"`
  - `action: "removed"`
- **What to pay attention to**: `action` should be `"removed"`. Verify via `get_scene_groups` that the node was actually removed from the group.

#### Scenario 4: Add a nested node to a group

- **Params**:
  ```json
  { "node_path": "Player/Weapon", "group": "weapons" }
  ```
- **Expected result**: Success response with `node: "Player/Weapon"`, `group: "weapons"`, `action: "added"`.
- **What to pay attention to**: Verify that the node is accessible via the full path `"Player/Weapon"`.

#### Scenario 5: Empty node_path (error)

- **Params**:
  ```json
  { "node_path": "", "group": "test_group" }
  ```
- **Expected result**: Error response: `"Node path cannot be empty"`.
- **What to pay attention to**: GDScript checks `node_path.is_empty()` first.

#### Scenario 6: Empty group name (error)

- **Params**:
  ```json
  { "node_path": "Player", "group": "" }
  ```
- **Expected result**: Error response: `"Group name cannot be empty"`.
- **What to pay attention to**: GDScript checks `group.is_empty()`. Verify that the error is specifically about group, not about node_path.

#### Scenario 7: Non-existent node path (error)

- **Params**:
  ```json
  { "node_path": "Ghost", "group": "ghosts" }
  ```
- **Expected result**: Error response: `"Node not found: Ghost"`.
- **What to pay attention to**: The error should contain the node name.

#### Scenario 8: Remove from a group the node is not in

- **Description**: Try to remove a node from a group it was never added to.
- **Params**:
  ```json
  { "node_path": "Player", "group: "nonexistent_group", "add": false }
  ```
- **Expected result**: Godot's `remove_from_group` on a group the node doesn't belong to may either silently succeed or return an error. The tool should return a success response (Godot typically doesn't error on this).
- **Notes**: This tests edge behavior. The response should not crash.
- **What to pay attention to**: Verify that there is no crash. Godot typically does not throw an error when removing from a group that the node is not part of.

#### Scenario 9: No scene open (error)

- **Params**:
  ```json
  { "node_path": "Player", "group": "test" }
  ```
- **Expected result**: Error response: `"No scene open"`.
- **What to pay attention to**: Similar to `set_scene_unique_name` Scenario 7.

---

## Tool: `get_scene_meta`

**Description**: Get metadata stored on a scene's root node
**Backend route**: `scene_config/get_meta`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `scene_path` | `string` | ❌ No | `""` (current scene) | Scene file path. Empty or omitted = current scene. |

### Test Scenarios

#### Scenario 1: Get meta from current scene (no metadata set yet)

- **Description**: Query metadata on a freshly created scene.
- **Params**:
  ```json
  {}
  ```
- **Expected result**: Success response:
  - `success: true`
  - `scene_path`: string (current scene path)
  - `meta: []` — empty array if no metadata has been set
  - `count: 0`
- **What to pay attention to**: `meta` should be an array (not `null`). `count` should be `0`. Each array element (if any) should contain `key` and `value`.

#### Scenario 2: Get meta after setting metadata

- **Description**: First set some metadata, then query.
- **Setup**:
  ```
  1. set_scene_meta({ key: "author", value: "TestRunner" })
  2. set_scene_meta({ key: "version", value: 42 })
  3. set_scene_meta({ key: "is_tutorial", value: true })
  ```
- **Params**:
  ```json
  {}
  ```
- **Expected result**: Success response:
  - `success: true`
  - `meta`: array of `{ key, value }` objects. Should contain entries for `"author"`, `"version"`, and `"is_tutorial"`.
  - `count: 3`
- **Notes**: The GDScript implementation calls `MCPVariantCodec.serialize_value()` on each meta value, so the format may differ from raw Godot types.
- **What to pay attention to**: Verify that the `value` for `"author"` is the string `"TestRunner"`, for `"version"` is the number `42`, and for `"is_tutorial"` is `true`. Check the serialization format (may be wrapped in an object with a `type` field).

#### Scenario 3: Get meta from a specific scene file

- **Params**:
  ```json
  { "scene_path": "res://test_scenes/scene_config_test.tscn" }
  ```
- **Expected result**: Success response. If this is the current scene with metadata set, should return the same data as Scenario 2.
- **What to pay attention to**: If the scene is loaded as PackedScene and instantiate — metadata from the file should be accessible.

#### Scenario 4: Non-existent scene path (error)

- **Params**:
  ```json
  { "scene_path": "res://nonexistent/meta_test.tscn" }
  ```
- **Expected result**: Error response: `"Scene not found: res://nonexistent/meta_test.tscn"`.
- **What to pay attention to**: The error should contain the path.

#### Scenario 5: Get meta with complex values

- **Description**: Set metadata with complex types (array, dict), then query.
- **Setup**:
  ```
  1. set_scene_meta({ key: "spawn_points", value: [[0, 0], [100, 200], [300, 50]] })
  2. set_scene_meta({ key: "config", value: { "difficulty": "hard", "lives": 3 } })
  ```
- **Params**:
  ```json
  {}
  ```
- **Expected result**: Success response. `meta` should contain entries for `"spawn_points"` (array of arrays) and `"config"` (object).
- **What to pay attention to**: Verify that complex types (arrays, dictionaries) are serialized correctly. `MCPVariantCodec.serialize_value()` should handle nested structures.

---

## Tool: `set_scene_meta`

**Description**: Set metadata on the current scene's root node
**Backend route**: `scene_config/set_meta`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `scene_path` | `string` | ❌ No | `""` | Omit or pass empty string — only the current scene is supported. Any non-empty value returns an error. |
| `key` | `string` | ✅ Yes | — | Metadata key |
| `value` | `unknown` | ✅ Yes | — | Metadata value (string, number, bool, array, or dict) |

### Test Scenarios

#### Scenario 1: Set string metadata

- **Description**: Set a simple string value.
- **Params**:
  ```json
  { "key": "author", "value": "TestRunner" }
  ```
- **Expected result**: Success response:
  - `success: true`
  - `key: "author"`
  - `message: "Metadata set"`
- **Notes**: The scene is marked as unsaved. The operation goes through undo/redo.
- **What to pay attention to**: The response does not contain `value` — only confirmation. Verify via `get_scene_meta` that the value was actually set.

#### Scenario 2: Set numeric metadata

- **Params**:
  ```json
  { "key": "version", "value": 42 }
  ```
- **Expected result**: Success response with `key: "version"`, `message: "Metadata set"`.
- **What to pay attention to**: Verify that `get_scene_meta` returns the number `42`, not the string `"42"`.

#### Scenario 3: Set boolean metadata

- **Params**:
  ```json
  { "key": "is_tutorial", "value": true }
  ```
- **Expected result**: Success response with `key: "is_tutorial"`, `message: "Metadata set"`.
- **What to pay attention to**: Verify that `get_scene_meta` returns `true` (boolean).

#### Scenario 4: Set array metadata

- **Params**:
  ```json
  { "key": "tags", "value": ["level1", "easy", "forest"] }
  ```
- **Expected result**: Success response.
- **What to pay attention to**: Verify that the array is saved and read back correctly via `get_scene_meta`.

#### Scenario 5: Set dictionary/object metadata

- **Params**:
  ```json
  { "key": "settings", "value": { "difficulty": "hard", "lives": 3, "respawn": true } }
  ```
- **Expected result**: Success response.
- **What to pay attention to**: Verify that the nested object is serialized/deserialized correctly.

#### Scenario 6: Overwrite existing metadata

- **Description**: Set the same key twice with different values.
- **Setup**: First call `set_scene_meta({ key: "score", value: 100 })`.
- **Params**:
  ```json
  { "key": "score", "value": 999 }
  ```
- **Expected result**: Success response. The value should be overwritten.
- **Verify**: Call `get_scene_meta` — should return `value: 999` for key `"score"`, not `100`.
- **What to pay attention to**: Verify that the old value is completely replaced. Undo should restore the value `100`.

#### Scenario 7: Empty key (error)

- **Params**:
  ```json
  { "key": "", "value": "test" }
  ```
- **Expected result**: Error response: `"Key cannot be empty"`.
- **What to pay attention to**: GDScript checks `key.is_empty()` first, before checking `scene_path`.

#### Scenario 8: Non-empty scene_path (error)

- **Description**: Pass a non-empty `scene_path` — the GDScript handler explicitly rejects this.
- **Params**:
  ```json
  { "scene_path": "res://test_scenes/scene_config_test.tscn", "key": "test", "value": "test" }
  ```
- **Expected result**: Error response: `"Setting meta on non-current scenes is not supported (leave scene_path empty for current scene)"`.
- **What to pay attention to**: This is an implementation limitation — `set_scene_meta` only works with the current scene. The error should clearly state this.

#### Scenario 9: Missing required `key` parameter

- **Params**:
  ```json
  { "value": "test" }
  ```
- **Expected result**: MCP-level validation error — Zod schema requires `key`.
- **What to pay attention to**: Zod validation error, not a Godot request error.

#### Scenario 10: Missing required `value` parameter

- **Params**:
  ```json
  { "key": "test" }
  ```
- **Expected result**: MCP-level validation error — Zod schema requires `value`. However, `value` is `z.unknown()`, which accepts `undefined`. The GDScript handler uses `params.get("value")` which returns `null` for missing keys. This may succeed and set the metadata to `null`.
- **Notes**: This is an edge case. `z.unknown()` accepts any value including `undefined`. The behavior depends on how MCP SDK handles missing vs undefined.
- **What to pay attention to**: Check behavior: either Zod validation rejects it, or the value is set as `null`. Record the actual behavior.

#### Scenario 11: Null value

- **Params**:
  ```json
  { "key": "nullable_field", "value": null }
  ```
- **Expected result**: Likely success — `z.unknown()` accepts `null`. In Godot, `set_meta(key, null)` should work.
- **What to pay attention to**: Verify that `null` is saved and read back correctly. In Godot, `get_meta(key)` for `null` may behave unexpectedly.

#### Scenario 12: No scene open (error)

- **Params**:
  ```json
  { "key": "test", "value": "test" }
  ```
- **Expected result**: Error response: `"No scene open"`.
- **What to pay attention to**: GDScript checks `root == null` after checking `key.is_empty()`.

---

## Cross-Tool Verification Scenarios

These scenarios test interactions between multiple tools to validate consistency.

### Scenario A: set_scene_group → get_scene_groups roundtrip

1. `set_scene_group({ node_path: "Player", group: "heroes" })` — add to group
2. `set_scene_group({ node_path: "Player/Weapon", group: "weapons" })` — add nested node
3. `set_scene_group({ node_path: "EnemyManager", group: "heroes" })` — add second node to same group
4. `get_scene_groups({})` — query all groups
5. **Assert**: `groups` contains `{ name: "heroes", nodes: ["Player", "EnemyManager"] }` and `{ name: "weapons", nodes: ["Player/Weapon"] }`. `group_count` is `2`.

**What to pay attention to**: Verify that both nodes are present in the `"heroes"` group. The order of nodes in the `nodes` array may be arbitrary.

### Scenario B: set_scene_group add → remove → get_scene_groups

1. `set_scene_group({ node_path: "Player", group: "temp_group" })` — add
2. `get_scene_groups({})` — verify `"temp_group"` exists with `"Player"`
3. `set_scene_group({ node_path: "Player", group: "temp_group", add: false })` — remove
4. `get_scene_groups({})` — verify `"temp_group"` is gone (or has empty `nodes`)
5. **Assert**: After removal, `"temp_group"` should not appear in the groups list (or if it does, `"Player"` should not be in its `nodes`).

**What to pay attention to**: Verify that the group is removed from the list if it has no remaining nodes. If Godot leaves an empty group — record this behavior.

### Scenario C: set_scene_unique_name → get_scene_tree verification

1. `set_scene_unique_name({ node_path: "Player", unique: true })`
2. `get_scene_tree({})` — get full scene tree
3. **Assert**: The node `"Player"` in the tree output should have `unique_name_in_owner: true` (or equivalent flag).

**What to pay attention to**: Verify that `get_scene_tree` displays the unique name flag. If the flag is not displayed — you may need to use `get_node_properties({ path: "Player" })` to verify.

### Scenario D: set_scene_meta → get_scene_meta roundtrip with all types

1. `set_scene_meta({ key: "str_val", value: "hello" })`
2. `set_scene_meta({ key: "int_val", value: 42 })`
3. `set_scene_meta({ key: "float_val", value: 3.14 })`
4. `set_scene_meta({ key: "bool_val", value: false })`
5. `set_scene_meta({ key: "arr_val", value: [1, 2, 3] })`
6. `set_scene_meta({ key: "obj_val", value: { "a": 1, "b": [2, 3] } })`
7. `get_scene_meta({})`
8. **Assert**: All 6 entries present with correct types and values.

**What to pay attention to**: Special attention to `float_val` — Godot may store it as `float` or `double`. Verify that `bool_val` does not turn into `0`/`1`. Verify that `null` values are not lost.

### Scenario E: Undo/redo consistency for set_scene_group

1. `set_scene_group({ node_path: "Player", group: "undo_test" })` — add
2. `get_scene_groups({})` — verify `"undo_test"` exists
3. Trigger undo (via `execute_editor_script` or editor undo shortcut)
4. `get_scene_groups({})` — verify `"undo_test"` is gone
5. Trigger redo
6. `get_scene_groups({})` — verify `"undo_test"` is back with `"Player"`

**What to pay attention to**: Verify that undo/redo works correctly for groups. If MCP does not provide an undo tool — this scenario may be executed via `execute_editor_script`.

### Scenario F: Undo/redo consistency for set_scene_unique_name

1. `set_scene_unique_name({ node_path: "Player", unique: true })`
2. Trigger undo
3. `get_node_properties({ path: "Player" })` — verify `unique_name_in_owner` is `false`
4. Trigger redo
5. `get_node_properties({ path: "Player" })` — verify `unique_name_in_owner` is `true`

**What to pay attention to**: Similar to Scenario E, but for unique names.

### Scenario G: Undo/redo consistency for set_scene_meta

1. `set_scene_meta({ key: "undoable_key", value: "original" })`
2. `set_scene_meta({ key: "undoable_key", value: "changed" })`
3. `get_scene_meta({})` — verify value is `"changed"`
4. Trigger undo
5. `get_scene_meta({})` — verify value is `"original"`
6. Trigger undo again (removes the key entirely if it was newly created)
7. `get_scene_meta({})` — verify `"undoable_key"` is absent
8. Trigger redo twice
9. `get_scene_meta({})` — verify value is `"changed"`

**What to pay attention to**: Verify that undo restores the previous value, not deletes the key. If the key was created for the first time — the first undo should delete it.

---

## Full Workflow Scenario: Complete Scene Configuration

This scenario exercises all 6 tools in a logical sequence that mimics a real-world usage pattern.

```
Step 1: create_scene({ path: "res://test_scenes/workflow_test.tscn", root_node_type: "Node2D" })
Step 2: add_node({ parent_path: "", type: "CharacterBody3D", name: "Hero" })
Step 3: add_node({ parent_path: "Hero", type: "Sprite2D", name: "Sprite" })
Step 4: add_node({ parent_path: "", type: "Node", name: "GameManager" })

--- Scene structure: Root(Node2D) → Hero(CharacterBody3D) → Sprite(Sprite2D), GameManager(Node) ---

Step 5: get_scene_inheritance({})
        → Expect: { success: true, inheritance_chain: ["res://test_scenes/workflow_test.tscn"], depth: 1 }

Step 6: set_scene_unique_name({ node_path: "Hero", unique: true })
        → Expect: { success: true, node: "Hero", unique: true, message: "Unique name enabled" }

Step 7: set_scene_unique_name({ node_path: "GameManager", unique: true })
        → Expect: { success: true, node: "GameManager", unique: true }

Step 8: set_scene_group({ node_path: "Hero", group: "players" })
        → Expect: { success: true, node: "Hero", group: "players", action: "added" }

Step 9: set_scene_group({ node_path: "Hero", group: "physics_entities" })
        → Expect: { success: true, node: "Hero", group: "physics_entities", action: "added" }

Step 10: set_scene_group({ node_path: "GameManager", group: "systems" })
         → Expect: { success: true, node: "GameManager", group: "systems", action: "added" }

Step 11: get_scene_groups({})
         → Expect: 3 groups: "players" (Hero), "physics_entities" (Hero), "systems" (GameManager)

Step 12: set_scene_meta({ key: "level_name", value: "Forest" })
         → Expect: { success: true, key: "level_name", message: "Metadata set" }

Step 13: set_scene_meta({ key: "difficulty", value: 2 })
         → Expect: { success: true, key: "difficulty", message: "Metadata set" }

Step 14: get_scene_meta({})
         → Expect: 2 metadata entries: "level_name" = "Forest", "difficulty" = 2

Step 15: set_scene_group({ node_path: "Hero", group: "players", add: false })
         → Expect: { success: true, node: "Hero", group: "players", action: "removed" }

Step 16: set_scene_unique_name({ node_path: "Hero", unique: false })
         → Expect: { success: true, node: "Hero", unique: false, message: "Unique name disabled" }

Step 17: get_scene_groups({})
         → Expect: 2 groups: "physics_entities" (Hero), "systems" (GameManager)

Step 18: save_scene({}) — save to persist changes
```

**What to pay attention to**: Each step depends on the previous one. If any step fails — subsequent steps may give incorrect results. It is recommended to run this scenario sequentially and verify the result of each step.

---

## Cleanup

After all tests:

```
delete_scene({ path: "res://test_scenes/scene_config_test.tscn", force: true })
delete_scene({ path: "res://test_scenes/base_scene.tscn", force: true })        // if Scenario 4 of get_scene_inheritance was run
delete_scene({ path: "res://test_scenes/derived_scene.tscn", force: true })     // if Scenario 4 of get_scene_inheritance was run
delete_scene({ path: "res://test_scenes/workflow_test.tscn", force: true })     // if full workflow was run
```
