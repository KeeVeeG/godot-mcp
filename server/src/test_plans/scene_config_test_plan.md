# Scene Config Tools — Test Plan

**Source file:** `server/src/tools/scene_config.ts`  
**Number of tools:** 6  
**Godot bridge commands:** `scene_config/get_inheritance`, `scene_config/set_unique_name`, `scene_config/get_groups`, `scene_config/set_group`, `scene_config/get_meta`, `scene_config/set_meta`

---

## Tool 1: `get_scene_inheritance`

**Description:** Get the scene inheritance chain (instantiated scenes, inherited scenes)  
**Handler:** `callGodot(bridge, 'scene_config/get_inheritance', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `scene_path` | `string` | No | — | Scene file path (empty for current scene) |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 1 | Get inheritance of current scene (no params) | `{}` | JSON object with inheritance chain for the currently open scene | Simplest invocation. Returns instantiated scenes and inherited scenes. |
| 2 | Get inheritance of current scene (empty string) | `{"scene_path": ""}` | Same as #1 — current scene inheritance chain | Empty string same as omission per Zod optional. |
| 3 | Get inheritance of a specific scene | `{"scene_path": "res://scenes/main.tscn"}` | JSON object with inheritance chain for main.tscn | Explicit scene path. |
| 4 | Scene with instantiated sub-scenes | `{"scene_path": "res://scenes/complex.tscn"}` | JSON showing instantiated children and their source scenes | Verify instantiated scenes appear in chain. |
| 5 | Scene with inherited scenes | `{"scene_path": "res://scenes/inherited.tscn"}` | JSON showing parent scene in inheritance list | Verify inherited-from scene is listed. |
| 6 | Get inheritance of deeply nested scene | `{"scene_path": "res://scenes/nested/deep/scene.tscn"}` | Valid JSON with chain | Paths with multiple directory levels. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 7 | Non-existent scene path | `{"scene_path": "res://nonexistent.tscn"}` | Godot error (file not found) | Invalid path handling. |
| 8 | Path without `res://` prefix | `{"scene_path": "scenes/main.tscn"}` | Godot error (not a valid resource path) | Malformed path. |
| 9 | Path to non-scene file (e.g., script) | `{"scene_path": "res://scripts/player.gd"}` | Godot error (not a scene file) | Wrong file type. |
| 10 | Path to directory | `{"scene_path": "res://scenes/"}` | Godot error (not a file) | Directory instead of file. |
| 11 | Call with extra ignored arg | `{"scene_path": "res://scenes/main.tscn", "extra": true}` | Valid JSON (extra key ignored) | Zod drops unknown keys. |
| 12 | Editor has no scene open | `{}` | Godot error or empty result | No current scene to query. |
| 13 | Editor disconnected | `{}` | Connection error (timeout or "not connected") | Standard disconnected behavior. |
| 14 | Scene with no inheritance (plain scene) | `{"scene_path": "res://scenes/plain.tscn"}` | Valid JSON; chain may be empty or show only self | Base case: no instantiated or inherited scenes. |

---

## Tool 2: `set_scene_unique_name`

**Description:** Toggle the unique name flag on a node (accessible as `%NodeName`)  
**Handler:** `callGodot(bridge, 'scene_config/set_unique_name', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `string` | **Yes** | — | Node path within the scene |
| `unique` | `boolean` | No | `true` | Enable (`true`) or disable (`false`) unique name |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 15 | Enable unique name on a root-level child | `{"node_path": "Player"}` | Success; Player node gets unique name flag (`%Player`) | Default `unique: true`. Simplest case. |
| 16 | Enable unique name on a nested child | `{"node_path": "Player/Sprite2D"}` | Success; Sprite2D gets unique name flag | Nested node path with `/`. |
| 17 | Enable unique name on scene root | `{"node_path": ""}` | Success (or Godot error if root cannot have unique name) | Empty string = scene root. Godot may allow/disallow this. |
| 18 | Disable unique name explicitly | `{"node_path": "Player", "unique": false}` | Success; unique name flag removed from Player | Explicit `unique: false`. |
| 19 | Enable unique name explicitly | `{"node_path": "Player", "unique": true}` | Success; unique name flag set on Player | Explicit `unique: true`. Same as default omission. |
| 20 | Toggle: disable an already-disabled unique name | `{"node_path": "Player", "unique": false}` | Success (idempotent) | Should not error when flag is already false. |
| 21 | Toggle: enable an already-enabled unique name | `{"node_path": "Player", "unique": true}` | Success (idempotent) | Should not error when flag is already true. |
| 22 | Toggle cycle: disable → enable → disable | Sequential calls with `"Player"` | Each call succeeds; flag toggles correctly | Full cycle. |
| 23 | Enable unique name on a node with spaces in name | `{"node_path": "My Player"}` | Success; `%My Player` unique name set | Node names can contain spaces. |

### Node Path Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 24 | Missing `node_path` | `{}` | Zod validation error | `node_path` is required (not optional). |
| 25 | Null `node_path` | `{"node_path": null}` | Zod validation error | Null is not a string. |
| 26 | Non-string `node_path` (number) | `{"node_path": 123}` | Zod validation error | Type mismatch. |
| 27 | Non-string `node_path` (boolean) | `{"node_path": true}` | Zod validation error | Type mismatch. |
| 28 | Non-string `node_path` (array) | `{"node_path": ["Player"]}` | Zod validation error | Type mismatch. |
| 29 | Non-existent node | `{"node_path": "NonExistentNode"}` | Godot error (node not found) | Node must exist in current scene. |
| 30 | Path with trailing slash | `{"node_path": "Player/"}` | Godot error | Malformed path — trailing slash may resolve as directory. |
| 31 | Path with leading slash | `{"node_path": "/Player"}` | Godot error (path "is relative to currently open scene") | Leading slash violates relative path convention. |
| 32 | Deeper nested path (3+ levels) | `{"node_path": "World/Terrain/Ground/Mesh"}` | Success; deepest node gets unique name | Deeply nested. |
| 33 | Extra unknown params | `{"node_path": "Player", "unique": true, "ignored": "yes"}` | Success (extra key ignored) | Zod drops unknown keys. |

### Boolean Type Validation (`unique`)

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 34 | Non-boolean `unique`: string | `{"node_path": "Player", "unique": "true"}` | Zod validation error | String `"true"` is not boolean `true`. |
| 35 | Non-boolean `unique`: number 1 | `{"node_path": "Player", "unique": 1}` | Zod validation error | Number is not boolean. |
| 36 | Non-boolean `unique`: number 0 | `{"node_path": "Player", "unique": 0}` | Zod validation error | Number is not boolean. |
| 37 | Non-boolean `unique`: object | `{"node_path": "Player", "unique": {}}` | Zod validation error | Object is not boolean. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 38 | Two nodes with same name, different parent | `{"node_path": "Enemy/Sprite2D"}` then `{"node_path": "Player/Sprite2D"}` | Both succeed independently | Unique name scope is per-node, not per-name globally. |
| 39 | Editor disconnected | `{"node_path": "Player"}` | Connection error | Standard disconnected behavior. |
| 40 | No scene open in editor | `{"node_path": "Player"}` | Godot error | No scene to operate on. |

---

## Tool 3: `get_scene_groups`

**Description:** Get all groups used in a scene and which nodes belong to each  
**Handler:** `callGodot(bridge, 'scene_config/get_groups', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `scene_path` | `string` | No | — | Scene file path (empty for current scene) |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 41 | Get groups of current scene (no params) | `{}` | JSON mapping group names → array of node paths | Simplest invocation. |
| 42 | Get groups of current scene (empty string) | `{"scene_path": ""}` | Same as #41 | Empty string same as omission. |
| 43 | Get groups of a specific scene | `{"scene_path": "res://scenes/main.tscn"}` | JSON mapping group names → array of node paths for main.tscn | Explicit scene path. |
| 44 | Scene with multiple groups | `{"scene_path": "res://scenes/groups.tscn"}` | JSON with multiple group keys, each listing nodes | Verify all groups appear. |
| 45 | Scene with nodes in multiple groups | `{"scene_path": "res://scenes/multi_group.tscn"}` | JSON showing same node under multiple group keys | Node can belong to several groups. |
| 46 | Scene with no groups | `{"scene_path": "res://scenes/empty.tscn"}` | Empty JSON object `{}` or empty array | Base case: no groups defined. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 47 | Non-existent scene path | `{"scene_path": "res://nonexistent.tscn"}` | Godot error (file not found) | Invalid path. |
| 48 | Path without `res://` prefix | `{"scene_path": "scenes/main.tscn"}` | Godot error | Malformed resource path. |
| 49 | Path to non-scene file (script) | `{"scene_path": "res://scripts/player.gd"}` | Godot error (not a scene) | Wrong file type. |
| 50 | Path to directory | `{"scene_path": "res://scenes/"}` | Godot error | Directory, not a file. |
| 51 | Call with extra ignored arg | `{"scene_path": "res://scenes/main.tscn", "foo": "bar"}` | Valid JSON (extra key ignored) | Zod drops unknowns. |
| 52 | Editor has no scene open | `{}` | Godot error or empty result | No scene to query. |
| 53 | Editor disconnected | `{}` | Connection error | Standard disconnected behavior. |
| 54 | Groups with special characters in name | `{"scene_path": "res://scenes/special.tscn"}` | JSON with group names containing spaces/underscores/dashes | Verify group names with special chars. |
| 55 | Deeply nested nodes in groups | `{"scene_path": "res://scenes/deep.tscn"}` | JSON showing full paths for nested nodes (e.g., `"Parent/Child/Grandchild"`) | Verify paths are fully qualified within scene. |

---

## Tool 4: `set_scene_group`

**Description:** Add or remove a node from a group  
**Handler:** `callGodot(bridge, 'scene_config/set_group', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `string` | **Yes** | — | Node path within the current scene |
| `group` | `string` | **Yes** | — | Group name |
| `add` | `boolean` | No | `true` | `true` to add to group, `false` to remove |

### Happy Path — Adding to Group

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 56 | Add node to group (minimal params) | `{"node_path": "Player", "group": "players"}` | Success; Player added to "players" group | Default `add: true`. |
| 57 | Add node to group explicitly | `{"node_path": "Player", "group": "players", "add": true}` | Success; Player added to "players" group | Explicit `add: true`. |
| 58 | Add nested node to group | `{"node_path": "Player/CollisionShape2D", "group": "colliders"}` | Success; nested node added to group | Nested node path. |
| 59 | Add scene root to group | `{"node_path": "", "group": "all_scenes"}` | Success or Godot error | Scene root can usually belong to groups. |
| 60 | Add node to group with space in name | `{"node_path": "Enemy", "group": "enemy units"}` | Success; group name with space | Group names can contain spaces. |
| 61 | Add node to group with underscore/dash | `{"node_path": "Enemy", "group": "enemy_units-v2"}` | Success | Group names with special chars. |
| 62 | Add same node to same group twice | `{"node_path": "Player", "group": "players"}` × 2 | Both succeed (idempotent) | Re-adding should not error. |
| 63 | Add different nodes to same group | `{"node_path": "Player", "group": "characters"}`, then `{"node_path": "Enemy", "group": "characters"}` | Both succeed; get_scene_groups shows both nodes | Multiple nodes in one group. |

### Happy Path — Removing from Group

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 64 | Remove node from group | `{"node_path": "Player", "group": "players", "add": false}` | Success; Player removed from "players" group | Explicit removal. |
| 65 | Remove nested node from group | `{"node_path": "Player/CollisionShape2D", "group": "colliders", "add": false}` | Success | Remove nested node. |
| 66 | Remove from group node is not in | `{"node_path": "Player", "group": "nonexistent_group", "add": false}` | Success (idempotent) or Godot warning | Removing from a group the node doesn't belong to. Should not error. |
| 67 | Remove from group twice | `{"node_path": "Player", "group": "players", "add": false}` × 2 | Both succeed (idempotent) | Double-remove should not error. |

### Required Parameter Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 68 | Missing `node_path` | `{"group": "players"}` | Zod validation error | `node_path` is required. |
| 69 | Missing `group` | `{"node_path": "Player"}` | Zod validation error | `group` is required. |
| 70 | Missing both required params | `{}` | Zod validation error | Both required. |
| 71 | Missing both, `add` only | `{"add": false}` | Zod validation error | Required params missing. |
| 72 | Null `node_path` | `{"node_path": null, "group": "players"}` | Zod validation error | Null is not string. |
| 73 | Null `group` | `{"node_path": "Player", "group": null}` | Zod validation error | Null is not string. |

### Type Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 74 | Non-string `node_path` (number) | `{"node_path": 123, "group": "players"}` | Zod validation error | Type mismatch. |
| 75 | Non-string `group` (number) | `{"node_path": "Player", "group": 123}` | Zod validation error | Type mismatch. |
| 76 | Non-boolean `add`: string | `{"node_path": "Player", "group": "players", "add": "true"}` | Zod validation error | String vs boolean. |
| 77 | Non-boolean `add`: number | `{"node_path": "Player", "group": "players", "add": 1}` | Zod validation error | Number vs boolean. |
| 78 | Empty string `node_path` | `{"node_path": "", "group": "players"}` | Passes Zod (valid string); Godot may treat as root | Empty string = scene root. Valid per NodePath schema. |
| 79 | Empty string `group` | `{"node_path": "Player", "group": ""}` | Passes Zod; Godot may reject empty group name | Empty group name may be invalid. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 80 | Non-existent node | `{"node_path": "NonExistent", "group": "players"}` | Godot error (node not found) | Node must exist in current scene. |
| 81 | Editor disconnected | `{"node_path": "Player", "group": "players"}` | Connection error | Standard disconnected behavior. |
| 82 | No scene open | `{"node_path": "Player", "group": "players"}` | Godot error | No scene to operate on. |
| 83 | Extra unknown params | `{"node_path": "Player", "group": "players", "add": true, "extra": "ignored"}` | Success (extra key ignored) | Zod drops unknown keys. |
| 84 | Very long group name | `{"node_path": "Player", "group": "a".repeat(256)}` | Success or Godot error | Tests length limits. |
| 85 | Group name with slashes | `{"node_path": "Player", "group": "group/with/slashes"}` | Success or Godot error | Slashes in group name may cause issues. |

### Boolean Toggle Flow

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 86 | Add → verify → remove → verify | 1. `{"node_path": "Player", "group": "test_group"}`<br>2. `get_scene_groups` → verify Player in test_group<br>3. `{"node_path": "Player", "group": "test_group", "add": false}`<br>4. `get_scene_groups` → verify Player NOT in test_group | All steps succeed; group membership toggles correctly | Integration with `get_scene_groups`. |
| 87 | Add → add (idempotent) → remove → remove (idempotent) | Sequential calls | All succeed; final state = removed | Idempotency chain. |

---

## Tool 5: `get_scene_meta`

**Description:** Get metadata stored on a scene's root node  
**Handler:** `callGodot(bridge, 'scene_config/get_meta', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `scene_path` | `string` | No | — | Scene file path (empty for current scene) |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 88 | Get meta of current scene (no params) | `{}` | JSON object with metadata key-value pairs for current scene | Simplest invocation. |
| 89 | Get meta of current scene (empty string) | `{"scene_path": ""}` | Same as #88 | Empty string same as omission. |
| 90 | Get meta of a specific scene | `{"scene_path": "res://scenes/main.tscn"}` | JSON object with metadata for main.tscn | Explicit scene path. |
| 91 | Scene with metadata set | `{"scene_path": "res://scenes/meta.tscn"}` | JSON with previously set metadata keys and values | Verify previously set metadata is returned. |
| 92 | Scene with no metadata | `{"scene_path": "res://scenes/empty.tscn"}` | Empty JSON object `{}` | Base case: no metadata. |
| 93 | Scene with multiple metadata entries | `{"scene_path": "res://scenes/rich.tscn"}` | JSON with multiple key-value pairs | Verify all entries returned. |

### Metadata Value Type Coverage

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 94 | Metadata: string value | After `set_scene_meta` with `"value": "hello"` | Key returns string `"hello"` | String metadata. |
| 95 | Metadata: number value | After `set_scene_meta` with `"value": 42` | Key returns number `42` | Numeric metadata. |
| 96 | Metadata: boolean value | After `set_scene_meta` with `"value": true` | Key returns boolean `true` | Boolean metadata. |
| 97 | Metadata: array value | After `set_scene_meta` with `"value": [1, 2, 3]` | Key returns array `[1, 2, 3]` | Array metadata. |
| 98 | Metadata: object/dict value | After `set_scene_meta` with `"value": {"nested": "data"}` | Key returns object `{"nested": "data"}` | Dict metadata. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 99 | Non-existent scene path | `{"scene_path": "res://nonexistent.tscn"}` | Godot error (file not found) | Invalid path. |
| 100 | Path without `res://` prefix | `{"scene_path": "scenes/main.tscn"}` | Godot error | Malformed resource path. |
| 101 | Path to non-scene file | `{"scene_path": "res://scripts/player.gd"}` | Godot error (not a scene) | Wrong file type. |
| 102 | Call with extra ignored arg | `{"scene_path": "res://scenes/main.tscn", "extra": true}` | Valid JSON (extra key ignored) | Zod drops unknown keys. |
| 103 | Editor has no scene open | `{}` | Godot error or empty result | No scene to query. |
| 104 | Editor disconnected | `{}` | Connection error | Standard disconnected behavior. |

---

## Tool 6: `set_scene_meta`

**Description:** Set metadata on the current scene's root node  
**Handler:** `callGodot(bridge, 'scene_config/set_meta', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `scene_path` | `string` | No | — | Omit or pass empty string — only the current scene is supported |
| `key` | `string` | **Yes** | — | Metadata key |
| `value` | `unknown` | **Yes** | — | Metadata value (string, number, bool, array, or dict) |

### Happy Path — By Value Type

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 105 | Set string metadata (minimal) | `{"key": "author", "value": "Jane"}` | Success; metadata `author` = `"Jane"` on current scene | Simplest case: string value. |
| 106 | Set number metadata | `{"key": "version", "value": 1}` | Success; metadata `version` = `1` | Integer value. |
| 107 | Set float metadata | `{"key": "scale", "value": 1.5}` | Success; metadata `scale` = `1.5` | Float value. |
| 108 | Set boolean metadata (true) | `{"key": "published", "value": true}` | Success; metadata `published` = `true` | Boolean `true`. |
| 109 | Set boolean metadata (false) | `{"key": "published", "value": false}` | Success; metadata `published` = `false` | Boolean `false`. |
| 110 | Set array metadata | `{"key": "tags", "value": ["action", "rpg"]}` | Success; metadata `tags` = `["action", "rpg"]` | Array of strings. |
| 111 | Set array of numbers metadata | `{"key": "bounds", "value": [0, 0, 100, 200]}` | Success; metadata `bounds` = `[0, 0, 100, 200]` | Array of numbers. |
| 112 | Set object/dict metadata | `{"key": "config", "value": {"theme": "dark", "volume": 0.8}}` | Success; metadata `config` = nested dict | Nested object value. |
| 113 | Set negative number metadata | `{"key": "offset", "value": -10}` | Success | Negative number. |
| 114 | Set null metadata | `{"key": "removed", "value": null}` | Success or Godot error | `z.unknown()` accepts null. Godot may or may not support null meta. |
| 115 | Set empty string value | `{"key": "description", "value": ""}` | Success; metadata `description` = `""` | Empty string value. |
| 116 | Set with explicit `scene_path` (empty string) | `{"key": "author", "value": "Jane", "scene_path": ""}` | Same as #105 | Explicit empty string path. |

### Metadata Key Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 117 | Key with spaces | `{"key": "my key", "value": 42}` | Success or Godot error | Spaces in metadata key. |
| 118 | Key with underscores | `{"key": "my_key", "value": 42}` | Success | Underscores in key. |
| 119 | Key with dots | `{"key": "my.key", "value": 42}` | Success or Godot error | Dots in key. |
| 120 | Key starting with number | `{"key": "1st_key", "value": 42}` | Success or Godot error | Numeric-prefixed key. |
| 121 | Very long key | `{"key": "a".repeat(256), "value": 42}` | Success or Godot error | Length boundary. |
| 122 | CamelCase key | `{"key": "myKeyName", "value": 42}` | Success | CamelCase convention. |
| 123 | Single-char key | `{"key": "a", "value": 42}` | Success | Minimum length key. |

### Required Parameter Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 124 | Missing `key` | `{"value": "hello"}` | Zod validation error | `key` is required. |
| 125 | Missing `value` | `{"key": "author"}` | Zod validation error | `value` is required. |
| 126 | Missing both required | `{}` | Zod validation error | Both required. |
| 127 | Missing both, `scene_path` only | `{"scene_path": ""}` | Zod validation error | Required params missing. |
| 128 | Null `key` | `{"key": null, "value": "hello"}` | Zod validation error | Null is not a valid string. |

### Type Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 129 | Non-string `key` (number) | `{"key": 123, "value": "hello"}` | Zod validation error | Key must be string. |
| 130 | Non-string `key` (boolean) | `{"key": true, "value": "hello"}` | Zod validation error | Key must be string. |
| 131 | Non-string `key` (array) | `{"key": ["a"], "value": "hello"}` | Zod validation error | Key must be string. |
| 132 | Non-string `key` (object) | `{"key": {}, "value": "hello"}` | Zod validation error | Key must be string. |

### Value Type Acceptance (all valid)

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 133 | `value` as string | `{"key": "test", "value": "string"}` | Success | String passes Zod. |
| 134 | `value` as number (int) | `{"key": "test", "value": 42}` | Success | Int passes Zod. |
| 135 | `value` as number (float) | `{"key": "test", "value": 3.14}` | Success | Float passes Zod. |
| 136 | `value` as boolean | `{"key": "test", "value": true}` | Success | Boolean passes Zod. |
| 137 | `value` as array | `{"key": "test", "value": [1,2,3]}` | Success | Array passes Zod. |
| 138 | `value` as object | `{"key": "test", "value": {"nested": true}}` | Success | Object passes Zod. |
| 139 | `value` as null | `{"key": "test", "value": null}` | Passes Zod (`z.unknown()`); Godot behavior TBD | Null passes Zod. |

### Overwrite / Update Behavior

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 140 | Overwrite existing metadata | 1. `{"key": "version", "value": 1}`<br>2. `{"key": "version", "value": 2}` | Step 2 succeeds; get_scene_meta shows version=2 | Overwrite same key. |
| 141 | Overwrite with different type | 1. `{"key": "data", "value": "text"}`<br>2. `{"key": "data", "value": 42}` | Step 2 succeeds; get_scene_meta shows data=42 | Type change on overwrite. |
| 142 | Set same key+value twice | `{"key": "author", "value": "Jane"}` × 2 | Both succeed (idempotent) | Re-setting same value should not error. |
| 143 | Clear and re-set | 1. Set `{"key": "x", "value": 1}`<br>2. Set `{"key": "x", "value": null}`<br>3. Set `{"key": "x", "value": 2}` | All succeed; final value is 2 | Null intermediate state. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 144 | Editor disconnected | `{"key": "author", "value": "Jane"}` | Connection error | Standard disconnected behavior. |
| 145 | No scene open | `{"key": "author", "value": "Jane"}` | Godot error | No scene to set metadata on. |
| 146 | Extra unknown params | `{"key": "author", "value": "Jane", "scene_path": "", "extra": "ignored"}` | Success (extra key ignored) | Zod drops unknown keys. |
| 147 | Very large array value | `{"key": "big_array", "value": ` + large_array + `}` | Success or Godot error | Tests size limits for values. |
| 148 | Deeply nested object value | `{"key": "deep", "value": {"a": {"b": {"c": {"d": "e"}}}}}` | Success | Deeply nested dict. |
| 149 | Empty array value | `{"key": "empty_list", "value": []}` | Success | Empty array. |
| 150 | Empty object value | `{"key": "empty_dict", "value": {}}` | Success | Empty object. |

---

## Integration / Cross-Tool Scenarios

| # | Scenario | Steps | Expected result | Notes |
|---|----------|-------|-----------------|-------|
| 151 | Set meta → get meta → verify | 1. `set_scene_meta({"key": "test_key", "value": "test_value"})`<br>2. `get_scene_meta({})` | Step 1 succeeds; Step 2 returns JSON with `test_key: "test_value"` | Basic meta round-trip. |
| 152 | Set meta (all types) → get meta → verify each | 1. Set string: `set_scene_meta({"key": "s", "value": "hello"})`<br>2. Set number: `set_scene_meta({"key": "n", "value": 42})`<br>3. Set bool: `set_scene_meta({"key": "b", "value": true})`<br>4. Set array: `set_scene_meta({"key": "a", "value": [1,2,3]})`<br>5. Set dict: `set_scene_meta({"key": "d", "value": {"k":"v"}})`<br>6. `get_scene_meta({})` | All 5 metadata entries present with correct types/values | Full type coverage round-trip. |
| 153 | Meta overwrite round-trip | 1. `set_scene_meta({"key": "count", "value": 0})`<br>2. `get_scene_meta({})` → verify count=0<br>3. `set_scene_meta({"key": "count", "value": 5})`<br>4. `get_scene_meta({})` → verify count=5 | Value updates correctly | Overwrite verification. |
| 154 | Group add → get groups → verify | 1. `set_scene_group({"node_path": "Player", "group": "characters"})`<br>2. `get_scene_groups({})` | Step 2 returns groups including "characters" with "Player" as member | Group round-trip. |
| 155 | Group add → remove → get groups → verify removed | 1. `set_scene_group({"node_path": "Player", "group": "temp"})`<br>2. `get_scene_groups({})` → verify Player in temp<br>3. `set_scene_group({"node_path": "Player", "group": "temp", "add": false})`<br>4. `get_scene_groups({})` → verify Player NOT in temp | Group add/remove cycle. |
| 156 | Unique name → verify via get_scene_groups (indirect) | 1. `set_scene_unique_name({"node_path": "Player"})`<br>2. `set_scene_group({"node_path": "%Player", "group": "unique_nodes"})`<br>3. `get_scene_groups({})` | Player accessible as `%Player` in group operations | Unique name enables `%` prefix access. |
| 157 | Full scene config workflow | 1. `get_scene_inheritance({})` — baseline<br>2. `get_scene_groups({})` — baseline<br>3. `get_scene_meta({})` — baseline<br>4. `set_scene_unique_name({"node_path": "MainUI"})`<br>5. `set_scene_group({"node_path": "MainUI", "group": "ui_elements"})`<br>6. `set_scene_meta({"key": "last_modified", "value": "2026-07-08"})`<br>7. `get_scene_groups({})` — verify MainUI in ui_elements<br>8. `get_scene_meta({})` — verify last_modified set<br>9. `get_scene_inheritance({})` — unchanged | All steps succeed; read-backs match mutations | Complete config workflow. |
| 158 | Unique name toggle off | 1. `set_scene_unique_name({"node_path": "Player"})` — enable<br>2. `set_scene_unique_name({"node_path": "Player", "unique": false})` — disable<br>3. `get_scene_groups({})` — normal access via "Player" (not "%Player") | Unique name toggles correctly | Toggle off verification. |
| 159 | Cross-tool: scene_path with inheritance and groups | 1. `get_scene_inheritance({"scene_path": "res://scenes/shared.tscn"})`<br>2. `get_scene_groups({"scene_path": "res://scenes/shared.tscn"})`<br>3. `get_scene_meta({"scene_path": "res://scenes/shared.tscn"})` | All return data for the same scene | All read tools work with explicit scene_path. |
| 160 | Mixed create and query current scene | 1. `set_scene_group({"node_path": "Node2D", "group": "test"})`<br>2. `set_scene_meta({"key": "test_meta", "value": "ok"})`<br>3. `get_scene_groups({})`<br>4. `get_scene_meta({})` | Groups and meta show current scene state | Current scene = default scope. |

---

## Summary: Parameter Coverage

| Tool | Parameter | Type | Required | Default | Enums/Constraints |
|------|-----------|------|----------|---------|-------------------|
| `get_scene_inheritance` | `scene_path` | string | No | — | Optional; empty = current scene |
| `set_scene_unique_name` | `node_path` | string | **Yes** | — | Node path within scene; "" for root |
| `set_scene_unique_name` | `unique` | boolean | No | `true` | — |
| `get_scene_groups` | `scene_path` | string | No | — | Optional; empty = current scene |
| `set_scene_group` | `node_path` | string | **Yes** | — | Node path within current scene |
| `set_scene_group` | `group` | string | **Yes** | — | Group name |
| `set_scene_group` | `add` | boolean | No | `true` | — |
| `get_scene_meta` | `scene_path` | string | No | — | Optional; empty = current scene |
| `set_scene_meta` | `scene_path` | string | No | — | Optional; only current scene supported |
| `set_scene_meta` | `key` | string | **Yes** | — | Metadata key |
| `set_scene_meta` | `value` | unknown | **Yes** | — | string, number, bool, array, or dict |

**Total scenarios:** 160  
**Coverage:** Every tool, every parameter, every default behavior, type validation, edge cases (missing params, null, empty strings, idempotency, disconnected, no scene), boolean toggle cycles, metadata value type coverage (string/number/boolean/array/object/null), overwrite/update behavior, integration round-trips across all 6 tools.
