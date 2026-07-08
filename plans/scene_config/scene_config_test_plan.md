# Scene Config Tools — Test Plan

**Module:** `server/src/tools/scene_config.ts`
**Date:** 2026-07-08
**Total tools:** 6

---

## Prerequisites

Before executing any test scenario, ensure:

1. The Godot editor is open with the MCP plugin connected and a project loaded.
2. A scene is open in the editor. The scene should have at least:
   - A root node (any type, e.g. `Node2D` or `Node3D`)
   - A child node named `TestNode` (for `node_path`-based tools)
   - A child node named `AnotherNode` (for group operations spanning multiple nodes)
3. For `set_scene_group` tests, the nodes must NOT belong to any test groups beforehand (or the tester must clean up after each run).
4. The test runner can invoke tools via the MCP client and inspect the return value's `content[0].text` field (a JSON string).

---

## Tool: `get_scene_inheritance`

**Description:** Get the scene inheritance chain (instantiated scenes, inherited scenes)
**Handler:** `callGodot(bridge, 'scene_config/get_inheritance', args)`
**Type:** Read-only

### Parameters

| Parameter    | Type     | Required | Description                                      |
| ------------ | -------- | -------- | ------------------------------------------------ |
| `scene_path` | `string` | No       | Scene file path (`res://...`). Omit for current. |

`scene_path` uses `OptionalScenePath` = `z.string().optional()`.

### Test Scenarios

#### 1. Happy path — current scene (no params)
- **Description:** Call with no arguments; should return inheritance chain for the currently open scene.
- **Params:** `{}` (or omit `scene_path`)
- **Expected result:** JSON object describing the inheritance chain. For a standalone scene, returns an empty or single-element chain. For an inherited scene, returns the full parent chain.
- **Notes:** The exact structure depends on the Godot-side implementation. At minimum, `isError` should be `false`.

#### 2. Explicit current scene (empty string)
- **Description:** Call with `scene_path: ""` — should behave identically to omitting the parameter.
- **Params:** `{ "scene_path": "" }`
- **Expected result:** Same as scenario 1.

#### 3. Specific scene by path (res://)
- **Description:** Call with a valid `res://` path to a `.tscn` file that exists in the project.
- **Params:** `{ "scene_path": "res://scenes/main.tscn" }` (adjust to a real scene in the project)
- **Expected result:** JSON object with the inheritance chain for that scene.
- **Notes:** If `res://scenes/main.tscn` doesn't exist, pick any existing `.tscn` file via `get_filesystem_tree`.

#### 4. Non-existent scene path
- **Description:** Call with a path to a `.tscn` file that does not exist.
- **Params:** `{ "scene_path": "res://scenes/nonexistent.tscn" }`
- **Expected result:** Error response (`isError: true`) or an empty/null chain.

#### 5. Non-scene file path
- **Description:** Call with a path pointing to a non-scene file (e.g., a `.gd` script).
- **Params:** `{ "scene_path": "res://scripts/some_script.gd" }`
- **Expected result:** Error response (`isError: true`). Should not crash the server or editor.

#### 6. Invalid path format
- **Description:** Call with a malformed path string.
- **Params:** `{ "scene_path": "not/a/valid/path" }`
- **Expected result:** Error response. Server may reject it at the Zod level (string type mismatch won't happen since it's already a string, but Godot should fail to resolve it).

---

## Tool: `set_scene_unique_name`

**Description:** Toggle the unique name flag on a node (accessible as `%NodeName`)
**Handler:** `callGodot(bridge, 'scene_config/set_unique_name', args)`
**Type:** Mutating (affects scene state)

### Parameters

| Parameter   | Type      | Required | Default | Description                                          |
| ----------- | --------- | -------- | ------- | ---------------------------------------------------- |
| `node_path` | `string`  | **Yes**  | —       | Node path within the scene (e.g. `"Player"`, `"Player/Sprite2D"`, `""` for root). |
| `unique`    | `boolean` | No       | `true`  | Enable (`true`) or disable (`false`) the unique name flag. |

`node_path` uses `NodePath` = `z.string()` (required).
`unique` uses `z.boolean().optional().default(true)`.

### Test Scenarios

#### 1. Happy path — enable unique name on child node
- **Description:** Enable the unique name flag on a child node using the default `unique` value.
- **Params:** `{ "node_path": "TestNode" }`
- **Expected result:** Success. The node `TestNode` should now be accessible as `%TestNode`. Verify by checking `get_scene_tree` or calling `get_node("%TestNode")`.

#### 2. Happy path — enable unique name on scene root
- **Description:** Enable unique name on the scene root node.
- **Params:** `{ "node_path": "" }`
- **Expected result:** Success. Root node has unique name enabled.

#### 3. Happy path — enable unique name on nested node
- **Description:** Enable unique name on a deeply nested node.
- **Params:** `{ "node_path": "Parent/Child/Grandchild" }` (adjust to an actual nested node in the scene)
- **Expected result:** Success.

#### 4. Happy path — explicitly disable unique name (`unique: false`)
- **Description:** Disable the unique name flag on a node that previously had it enabled.
- **Params:** `{ "node_path": "TestNode", "unique": false }`
- **Expected result:** Success. The node should no longer be accessible via `%TestNode`.

#### 5. Missing required `node_path`
- **Description:** Call without the `node_path` parameter.
- **Params:** `{}`
- **Expected result:** Validation error from Zod. `isError: true`, message about missing required field `node_path`.

#### 6. Non-existent node path
- **Description:** Call with a node path that does not exist in the scene.
- **Params:** `{ "node_path": "NonExistentNode" }`
- **Expected result:** Error from Godot side. Should not crash.

#### 7. Edge case — `unique: true` explicitly (verify default is not overridden)
- **Description:** Explicitly pass `true` to confirm it matches default behavior.
- **Params:** `{ "node_path": "TestNode", "unique": true }`
- **Expected result:** Success; identical to scenario 1.

#### 8. Edge case — `unique` as string `"true"` or `"false"`
- **Description:** Pass `unique` as a string instead of boolean (type coercion test).
- **Params:** `{ "node_path": "TestNode", "unique": "true" }`
- **Expected result:** Zod validation error (expected `boolean`, received `string`). `isError: true`.

#### 9. Re-enable after disable (toggle test)
- **Description:** Run scenario 4 (disable), then re-run scenario 1 (enable default). Verify unique name is restored.
- **Params (step 1):** `{ "node_path": "TestNode", "unique": false }`
- **Params (step 2):** `{ "node_path": "TestNode" }` (defaults to `true`)
- **Expected result:** Step 2 succeeds and `%TestNode` is accessible again.

---

## Tool: `get_scene_groups`

**Description:** Get all groups used in a scene and which nodes belong to each
**Handler:** `callGodot(bridge, 'scene_config/get_groups', args)`
**Type:** Read-only

### Parameters

| Parameter    | Type     | Required | Description                                      |
| ------------ | -------- | -------- | ------------------------------------------------ |
| `scene_path` | `string` | No       | Scene file path. Omit for current scene.         |

`scene_path` uses `OptionalScenePath` = `z.string().optional()`.

### Test Scenarios

#### 1. Happy path — current scene (no params)
- **Description:** Call with no arguments; should return all groups in the currently open scene.
- **Params:** `{}`
- **Expected result:** JSON object mapping group names to arrays of node paths. For a fresh scene, may return an empty object `{}`.

#### 2. Happy path — scene with known groups
- **Description:** First use `set_scene_group` to add nodes to groups, then verify `get_scene_groups` lists them.
- **Params (setup):** `{ "node_path": "TestNode", "group": "test_group_a", "add": true }`
- **Params (test):** `{}`
- **Expected result:** The returned JSON should include `"test_group_a"` mapping to `["TestNode"]`.

#### 3. Specific scene by path
- **Description:** Query groups of a different scene by path.
- **Params:** `{ "scene_path": "res://scenes/main.tscn" }`
- **Expected result:** Groups for that scene. May be empty or populated depending on the scene.

#### 4. Non-existent scene path
- **Description:** Query groups for a scene that doesn't exist.
- **Params:** `{ "scene_path": "res://scenes/nonexistent.tscn" }`
- **Expected result:** Error response (`isError: true`).

#### 5. Non-scene file path
- **Description:** Pass a non-scene file as `scene_path`.
- **Params:** `{ "scene_path": "res://scripts/some_script.gd" }`
- **Expected result:** Error response.

---

## Tool: `set_scene_group`

**Description:** Add or remove a node from a group
**Handler:** `callGodot(bridge, 'scene_config/set_group', args)`
**Type:** Mutating

### Parameters

| Parameter   | Type      | Required | Default | Description                                             |
| ----------- | --------- | -------- | ------- | ------------------------------------------------------- |
| `node_path` | `string`  | **Yes**  | —       | Node path within the current scene.                     |
| `group`     | `string`  | **Yes**  | —       | Group name.                                             |
| `add`       | `boolean` | No       | `true`  | `true` to add to group, `false` to remove.              |

`node_path` uses `NodePath`.
`group` uses `z.string()`.
`add` uses `z.boolean().optional().default(true)`.

### Test Scenarios

#### 1. Happy path — add node to group (default `add: true`)
- **Description:** Add a node to a new group using default `add` value.
- **Params:** `{ "node_path": "TestNode", "group": "test_group_add_1" }`
- **Expected result:** Success. Verify with `get_scene_groups` or `get_node_groups("TestNode")`.

#### 2. Happy path — add node to group (explicit `add: true`)
- **Description:** Add a node to a group with explicit `add: true`.
- **Params:** `{ "node_path": "TestNode", "group": "test_group_add_2", "add": true }`
- **Expected result:** Success. Node belongs to `test_group_add_2`.

#### 3. Happy path — remove node from group (`add: false`)
- **Description:** Remove a node from a group it was previously added to.
- **Params (setup):** `{ "node_path": "TestNode", "group": "test_group_remove", "add": true }`
- **Params (test):** `{ "node_path": "TestNode", "group": "test_group_remove", "add": false }`
- **Expected result:** Success. Node no longer belongs to `test_group_remove`.

#### 4. Happy path — add scene root to group
- **Description:** Add the scene root node to a group.
- **Params:** `{ "node_path": "", "group": "root_group" }`
- **Expected result:** Success.

#### 5. Happy path — add nested node to group
- **Description:** Add a deeply nested node to a group.
- **Params:** `{ "node_path": "Parent/Child", "group": "nested_group" }`
- **Expected result:** Success.

#### 6. Happy path — add multiple nodes to same group
- **Description:** Add two different nodes to the same group and verify both appear.
- **Params (step 1):** `{ "node_path": "TestNode", "group": "shared_group" }`
- **Params (step 2):** `{ "node_path": "AnotherNode", "group": "shared_group" }`
- **Params (verify):** `get_scene_groups` — should show both nodes under `shared_group`.
- **Expected result:** Both calls succeed. Group contains both nodes.

#### 7. Missing required `node_path`
- **Description:** Call without `node_path`.
- **Params:** `{ "group": "test_group" }`
- **Expected result:** Zod validation error: missing required field `node_path`.

#### 8. Missing required `group`
- **Description:** Call without `group`.
- **Params:** `{ "node_path": "TestNode" }`
- **Expected result:** Zod validation error: missing required field `group`.

#### 9. Missing both required params
- **Description:** Call with no arguments.
- **Params:** `{}`
- **Expected result:** Zod validation error for both `node_path` and `group`.

#### 10. Non-existent node path
- **Description:** Add a non-existent node to a group.
- **Params:** `{ "node_path": "NonExistentNode", "group": "ghost_group" }`
- **Expected result:** Error from Godot. Should not crash.

#### 11. Empty group name
- **Description:** Add a node to a group with an empty string as group name.
- **Params:** `{ "node_path": "TestNode", "group": "" }`
- **Expected result:** Depends on Godot's handling. May succeed (creating an empty-named group) or return an error. Document actual behavior.

#### 12. Remove from group not joined
- **Description:** Attempt to remove a node from a group it never belonged to.
- **Params:** `{ "node_path": "TestNode", "group": "nonexistent_group", "add": false }`
- **Expected result:** Should succeed (no-op) or return a benign warning. Should not error.

#### 13. Idempotency — add to already-joined group
- **Description:** Add a node to a group it already belongs to.
- **Params (step 1):** `{ "node_path": "TestNode", "group": "idem_group" }`
- **Params (step 2):** `{ "node_path": "TestNode", "group": "idem_group", "add": true }`
- **Expected result:** Both succeed. Node appears once in the group.

#### 14. Edge case — `add` as string
- **Description:** Pass `add` as a string value.
- **Params:** `{ "node_path": "TestNode", "group": "test_group", "add": "true" }`
- **Expected result:** Zod validation error (expected boolean, got string).

#### 15. Edge case — very long group name
- **Description:** Use an extremely long group name.
- **Params:** `{ "node_path": "TestNode", "group": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }`
- **Expected result:** Should either succeed or return a graceful error. Should not crash.

---

## Tool: `get_scene_meta`

**Description:** Get metadata stored on a scene's root node
**Handler:** `callGodot(bridge, 'scene_config/get_meta', args)`
**Type:** Read-only

### Parameters

| Parameter    | Type     | Required | Description                              |
| ------------ | -------- | -------- | ---------------------------------------- |
| `scene_path` | `string` | No       | Scene file path. Omit for current scene. |

`scene_path` uses `OptionalScenePath` = `z.string().optional()`.

### Test Scenarios

#### 1. Happy path — current scene, no metadata set
- **Description:** Query metadata on a fresh scene that has no custom metadata.
- **Params:** `{}`
- **Expected result:** Returns an empty object `{}` or a list of Godot's default metadata keys. Should not error.

#### 2. Happy path — current scene with metadata set
- **Description:** First use `set_scene_meta` to store a value, then verify `get_scene_meta` retrieves it.
- **Params (setup):** `{ "key": "author", "value": "TestUser" }`
- **Params (test):** `{}`
- **Expected result:** The returned JSON should include `"author": "TestUser"`.

#### 3. Specific scene by path
- **Description:** Query metadata of a different scene.
- **Params:** `{ "scene_path": "res://scenes/main.tscn" }`
- **Expected result:** Metadata for that scene.

#### 4. Non-existent scene path
- **Description:** Query metadata for a non-existent scene.
- **Params:** `{ "scene_path": "res://scenes/nonexistent.tscn" }`
- **Expected result:** Error response (`isError: true`).

#### 5. Non-scene file path
- **Description:** Pass a non-scene file as `scene_path`.
- **Params:** `{ "scene_path": "res://scripts/some_script.gd" }`
- **Expected result:** Error response.

---

## Tool: `set_scene_meta`

**Description:** Set metadata on the current scene's root node
**Handler:** `callGodot(bridge, 'scene_config/set_meta', args)`
**Type:** Mutating

### Parameters

| Parameter    | Type      | Required | Description                                                            |
| ------------ | --------- | -------- | ---------------------------------------------------------------------- |
| `scene_path` | `string`  | No       | Scene file path. Omit or pass empty string — only current scene works. |
| `key`        | `string`  | **Yes**  | Metadata key name.                                                     |
| `value`      | `unknown` | **Yes**  | Metadata value (string, number, bool, array, or dict).                 |

`scene_path` uses `z.string().optional()` (raw Zod, not `OptionalScenePath` — note it has a different `.describe()`).
`key` uses `z.string()`.
`value` uses `z.unknown()`.

### Test Scenarios

#### 1. Happy path — set string metadata
- **Description:** Set a simple string metadata value.
- **Params:** `{ "key": "author", "value": "TestUser" }`
- **Expected result:** Success. Verify with `get_scene_meta` that `author` = `"TestUser"`.

#### 2. Happy path — set number metadata
- **Description:** Set a numeric metadata value (integer).
- **Params:** `{ "key": "version", "value": 42 }`
- **Expected result:** Success. Verify with `get_scene_meta` that `version` = `42`.

#### 3. Happy path — set boolean metadata
- **Description:** Set a boolean metadata value.
- **Params:** `{ "key": "is_published", "value": true }`
- **Expected result:** Success. Verify with `get_scene_meta`.

#### 4. Happy path — set array metadata
- **Description:** Set an array as metadata value.
- **Params:** `{ "key": "tags", "value": ["gameplay", "level1", "draft"] }`
- **Expected result:** Success. Verify with `get_scene_meta`.

#### 5. Happy path — set object/dict metadata
- **Description:** Set a nested object as metadata value.
- **Params:** `{ "key": "settings", "value": { "difficulty": "hard", "score_multiplier": 1.5, "enemies": 10 } }`
- **Expected result:** Success. Verify with `get_scene_meta`.

#### 6. Happy path — set float metadata
- **Description:** Set a floating-point number.
- **Params:** `{ "key": "spawn_rate", "value": 3.14159 }`
- **Expected result:** Success. Verify with `get_scene_meta`.

#### 7. Happy path — set null metadata
- **Description:** Set metadata value to `null`.
- **Params:** `{ "key": "nullable_field", "value": null }`
- **Expected result:** Success. Metadata key exists but value is null.

#### 8. Happy path — overwrite existing metadata
- **Description:** Update a previously set metadata value.
- **Params (step 1):** `{ "key": "overwrite_test", "value": "original_value" }`
- **Params (step 2):** `{ "key": "overwrite_test", "value": "updated_value" }`
- **Expected result:** Both succeed. Final value is `"updated_value"`.

#### 9. Happy path — set metadata with empty string key
- **Description:** Set metadata with an empty key name.
- **Params:** `{ "key": "", "value": "orphan_value" }`
- **Expected result:** May succeed (Godot allows empty metadata keys) or may error. Document actual behavior.

#### 10. Missing required `key`
- **Description:** Call without the `key` parameter.
- **Params:** `{ "value": "some_value" }`
- **Expected result:** Zod validation error: missing required field `key`.

#### 11. Missing required `value`
- **Description:** Call without the `value` parameter.
- **Params:** `{ "key": "test_key" }`
- **Expected result:** Since `value` is typed as `z.unknown()` and Zod treats `unknown` as required by default, this should trigger a validation error for missing `value`.

#### 12. Missing both required params
- **Description:** Call with no arguments.
- **Params:** `{}`
- **Expected result:** Zod validation error for both `key` and `value`.

#### 13. Set metadata with special characters in key
- **Description:** Use a key name with spaces and special characters.
- **Params:** `{ "key": "my key with spaces & symbols!", "value": "special_key_test" }`
- **Expected result:** Should succeed. Godot metadata keys support arbitrary strings.

#### 14. Set metadata with very long key
- **Description:** Use an extremely long key name.
- **Params:** `{ "key": "<256+ character string>", "value": "long_key_test" }`
- **Expected result:** Should succeed or return a graceful error.

#### 15. Set metadata with very large value
- **Description:** Use a large array or deeply nested object as value.
- **Params:** `{ "key": "big_data", "value": "<1000-element array or deeply nested object>" }`
- **Expected result:** Should succeed or return a graceful error. Should not crash the editor.

#### 16. Edge case — scene_path with non-current path
- **Description:** Attempt to set metadata on a different scene via `scene_path`.
- **Params:** `{ "scene_path": "res://scenes/main.tscn", "key": "external_meta", "value": "test" }`
- **Expected result:** According to the tool description, "only the current scene is supported." Either returns an error or uses `scene_path` silently. Document actual behavior.

---

## Cross-Tool Integration Tests

These test scenarios validate interactions between multiple tools.

### Scenario I: Add group, verify with get_scene_groups
1. Call `set_scene_group` with `{ "node_path": "TestNode", "group": "integration_group", "add": true }`
2. Call `set_scene_group` with `{ "node_path": "AnotherNode", "group": "integration_group", "add": true }`
3. Call `get_scene_groups` with `{}`
4. **Expected:** Response includes `"integration_group"` → `["TestNode", "AnotherNode"]` (order may vary).

### Scenario II: Set metadata, verify with get_scene_meta
1. Call `set_scene_meta` with `{ "key": "int_test_key", "value": { "nested": true, "count": 5 } }`
2. Call `get_scene_meta` with `{}`
3. **Expected:** Response includes `"int_test_key"` with value `{ "nested": true, "count": 5 }`.

### Scenario III: Unique name + group on same node
1. Call `set_scene_unique_name` with `{ "node_path": "TestNode", "unique": true }`
2. Call `set_scene_group` with `{ "node_path": "TestNode", "group": "unique_group_node" }`
3. Call `get_scene_groups` with `{}`
4. Call `get_scene_inheritance` with `{}`
5. **Expected:** All calls succeed. Node has unique name AND belongs to group. No interference between operations.

### Scenario IV: Full lifecycle — group remove then verify gone
1. Call `set_scene_group` with `{ "node_path": "TestNode", "group": "lifecycle_group", "add": true }`
2. Call `get_scene_groups` with `{}` → verify group exists
3. Call `set_scene_group` with `{ "node_path": "TestNode", "group": "lifecycle_group", "add": false }`
4. Call `get_scene_groups` with `{}` → verify group no longer contains `TestNode`
5. **Expected:** Step 2 shows the group; step 4 does not show `TestNode` under that group.

---

## Summary

| Tool                     | Type     | Params                                           | Scenarios |
| ------------------------ | -------- | ------------------------------------------------ | --------- |
| `get_scene_inheritance`  | Read     | `scene_path?`                                    | 6         |
| `set_scene_unique_name`  | Mutate   | `node_path*`, `unique?`                          | 9         |
| `get_scene_groups`       | Read     | `scene_path?`                                    | 5         |
| `set_scene_group`        | Mutate   | `node_path*`, `group*`, `add?`                   | 15        |
| `get_scene_meta`         | Read     | `scene_path?`                                    | 5         |
| `set_scene_meta`         | Mutate   | `scene_path?`, `key*`, `value*`                  | 16        |
| **Integration tests**    | Mixed    | Cross-tool interactions                          | 4         |

**Total scenarios: 60**

---

## Execution Notes

1. **Run read-only tests first.** Tools 1, 3, and 5 (`get_*`) do not modify scene state and can be run in any order.
2. **Isolate mutating tests.** Tools 2, 4, and 6 (`set_*`) should be run in a disposable or freshly-opened scene to avoid polluting project state. Alternatively, clean up after each test.
3. **Zod validation errors** occur server-side before any Godot communication. These should be fast and deterministic — no Godot connection required.
4. **Godot-side errors** depend on the editor state (scene open, node existence, etc.). Ensure prerequisites are met before running those scenarios.
5. For boolean parameter type-coercion tests (scenarios where a string is passed instead of boolean), confirm the Zod validation behavior. These should fail at the schema level.
