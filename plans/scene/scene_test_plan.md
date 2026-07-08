# Scene Tools Test Plan

**Source file:** `server/src/tools/scene.ts`
**Shared types:** `server/src/tools/shared-types.ts`
**Tools covered:** 12 (get_scene_tree, get_scene_file_content, create_scene, open_scene, delete_scene, add_scene_instance, play_scene, stop_scene, save_scene, get_loaded_scenes, set_main_scene, get_main_scene)

---

## Tool: get_scene_tree

**Description:** Get the node tree of the specified or currently open scene.

**Handler:** `callGodot(bridge, 'scene/get_tree', args)`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `max_depth` | `number` (int, positive) | No | `15` | Maximum tree depth to serialize |

### Schema constraints
- `max_depth`: Must be a positive integer (> 0). Uses `z.number().int().positive()`. Optional with default 15.

### Test Scenarios

#### 1. Happy path — default depth
- **Description:** Call with no parameters. Should return the scene tree limited to default depth 15.
- **Params:** `{}`
- **Expected result:** Success. Returns JSON with the scene tree. Nodes beyond depth 15 are not included.

#### 2. Happy path — explicit depth 5
- **Description:** Call with `max_depth=5`. Should return tree truncated at depth 5.
- **Params:** `{ "max_depth": 5 }`
- **Expected result:** Success. Tree truncated at depth 5.

#### 3. Happy path — explicit depth 1
- **Description:** Call with `max_depth=1`. Should return only the root node.
- **Params:** `{ "max_depth": 1 }`
- **Expected result:** Success. Only root node in tree.

#### 4. Happy path — large depth
- **Description:** Call with a very large `max_depth=9999`. Should return full tree.
- **Params:** `{ "max_depth": 9999 }`
- **Expected result:** Success. Full unfiltered tree.

#### 5. Edge case — max_depth = 0
- **Description:** Zero is not positive. Zod validation should reject.
- **Params:** `{ "max_depth": 0 }`
- **Expected result:** Validation error. `max_depth` must be > 0.

#### 6. Edge case — negative max_depth
- **Description:** Negative value should fail validation.
- **Params:** `{ "max_depth": -1 }`
- **Expected result:** Validation error. `max_depth` must be positive.

#### 7. Edge case — non-integer max_depth
- **Description:** Float value should fail `.int()` validation.
- **Params:** `{ "max_depth": 3.5 }`
- **Expected result:** Validation error. `max_depth` must be an integer.

#### 8. Edge case — string max_depth
- **Description:** String instead of number should fail type validation.
- **Params:** `{ "max_depth": "five" }`
- **Expected result:** Validation error. Expected number, received string.

#### 9. Edge case — no scene open
- **Description:** Call when no scene is loaded in the editor.
- **Params:** `{}`
- **Expected result:** May return error from Godot or empty/null tree. Behavior depends on Godot plugin.
- **Notes:** Test this scenario specifically to confirm expected behavior.

---

## Tool: get_scene_file_content

**Description:** Read the raw .tscn/.scn file content of a scene.

**Handler:** `callGodot(bridge, 'scene/get_file_content', args)`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (ScenePath) | **Yes** | — | Scene file path (e.g. `res://scenes/main.tscn`) |

### Schema constraints
- `path`: Uses `ScenePath` — a `z.string()` with description "Scene file path (e.g. 'res://scenes/main.tscn')". No `.url()` or `.startsWith()` constraint at schema level.

### Test Scenarios

#### 1. Happy path — read a valid scene
- **Description:** Read the content of an existing .tscn file.
- **Params:** `{ "path": "res://scenes/main.tscn" }`
- **Expected result:** Success. Returns the raw text contents of the .tscn file.

#### 2. Edge case — missing path parameter
- **Description:** Call without the required `path` parameter.
- **Params:** `{}`
- **Expected result:** Validation error. `path` is required.

#### 3. Edge case — null path
- **Description:** Pass null as path.
- **Params:** `{ "path": null }`
- **Expected result:** Validation error. Expected string, received null.

#### 4. Edge case — empty string path
- **Description:** Pass empty string.
- **Params:** `{ "path": "" }`
- **Expected result:** Godot error. Empty path is not a valid file path.

#### 5. Edge case — non-existent file
- **Description:** Path to a file that does not exist.
- **Params:** `{ "path": "res://scenes/nonexistent_xyz.tscn" }`
- **Expected result:** Godot error. File not found.

#### 6. Edge case — path without res:// prefix
- **Description:** Path not using the res:// scheme.
- **Params:** `{ "path": "scenes/main.tscn" }`
- **Expected result:** May fail. Godot typically requires `res://` for project paths.
- **Notes:** Whether this works depends on how the Godot plugin resolves the path.

#### 7. Edge case — absolute filesystem path
- **Description:** Using a filesystem path instead of res:// path.
- **Params:** `{ "path": "C:/Users/foo/scenes/main.tscn" }`
- **Expected result:** May fail. Godot `res://` paths are expected.

#### 8. Edge case — path to a non-scene file
- **Description:** Point to a .gd script file instead of .tscn.
- **Params:** `{ "path": "res://scripts/player.gd" }`
- **Expected result:** Likely error or unexpected content. The tool expects scene files.

#### 9. Edge case — path with .scn extension
- **Description:** Read a binary .scn scene file.
- **Params:** `{ "path": "res://scenes/legacy.scn" }`
- **Expected result:** Should return binary content (may not be human-readable). Tool description says it reads `.tscn/.scn`.
- **Notes:** Verify the tool can handle binary .scn files.

---

## Tool: create_scene

**Description:** Create a new empty scene with a specified root node type.

**Handler:** `callGodot(bridge, 'scene/create', args)`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (ScenePath) | **Yes** | — | Path to save the scene (e.g. `res://scenes/new.tscn`) |
| `root_node_type` | `string` | No | — | Root node type (e.g. `Node2D`, `Control`) |

### Test Scenarios

#### 1. Happy path — create scene with path only (default root)
- **Description:** Create a scene specifying only a path. Should use default root node type.
- **Params:** `{ "path": "res://scenes/test_empty.tscn" }`
- **Expected result:** Success. Scene created. Root node type is the Godot default (likely `Node`).

#### 2. Happy path — create 2D scene
- **Description:** Create a scene with `Node2D` root.
- **Params:** `{ "path": "res://scenes/test_2d.tscn", "root_node_type": "Node2D" }`
- **Expected result:** Success. New scene with `Node2D` root.

#### 3. Happy path — create UI scene
- **Description:** Create a scene with `Control` root.
- **Params:** `{ "path": "res://scenes/test_ui.tscn", "root_node_type": "Control" }`
- **Expected result:** Success. New scene with `Control` root.

#### 4. Happy path — create 3D scene
- **Description:** Create a scene with `Node3D` root.
- **Params:** `{ "path": "res://scenes/test_3d.tscn", "root_node_type": "Node3D" }`
- **Expected result:** Success. New scene with `Node3D` root.

#### 5. Edge case — missing path
- **Description:** Call without the required path.
- **Params:** `{ "root_node_type": "Node2D" }`
- **Expected result:** Validation error. `path` is required.

#### 6. Edge case — empty string path
- **Description:** Pass empty string as path.
- **Params:** `{ "path": "" }`
- **Expected result:** Godot error. Cannot create scene at empty path.

#### 7. Edge case — invalid path (no extension)
- **Description:** Path without .tscn extension.
- **Params:** `{ "path": "res://scenes/my_scene" }`
- **Expected result:** May succeed or fail. Godot may auto-append .tscn or reject it.
- **Notes:** Verify behavior with the Godot plugin.

#### 8. Edge case — invalid root_node_type
- **Description:** Pass a non-existent node type.
- **Params:** `{ "path": "res://scenes/test_bad.tscn", "root_node_type": "NonExistentTypeXYZ" }`
- **Expected result:** Godot error. Unknown node type.

#### 9. Edge case — overwrite existing scene
- **Description:** Create at a path where a scene already exists.
- **Params:** `{ "path": "res://scenes/main.tscn" }` (assuming main.tscn exists)
- **Expected result:** May fail or overwrite silently. Behavior depends on plugin.
- **Notes:** Document whether the tool overwrites or rejects existing files.

#### 10. Edge case — path with special characters
- **Description:** Path with spaces and non-alphanumeric characters.
- **Params:** `{ "path": "res://scenes/test scene (copy).tscn" }`
- **Expected result:** Should succeed. Godot supports spaces in filenames.

#### 11. Edge case — nested directory path
- **Description:** Path in a deeply nested directory that doesn't exist.
- **Params:** `{ "path": "res://scenes/foo/bar/baz/new_scene.tscn" }`
- **Expected result:** Should succeed if Godot plugin creates intermediate directories. May fail otherwise.
- **Notes:** Verify whether intermediate directories are auto-created.

---

## Tool: open_scene

**Description:** Open a scene file in the editor.

**Handler:** `callGodot(bridge, 'scene/open', args)`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (ScenePath) | **Yes** | — | Scene file path to open |

### Test Scenarios

#### 1. Happy path — open existing scene
- **Description:** Open a valid, existing scene file.
- **Params:** `{ "path": "res://scenes/main.tscn" }`
- **Expected result:** Success. Target scene becomes the active scene in the editor.

#### 2. Edge case — missing path
- **Description:** Call without the required path.
- **Params:** `{}`
- **Expected result:** Validation error. `path` is required.

#### 3. Edge case — empty string path
- **Description:** Pass empty string.
- **Params:** `{ "path": "" }`
- **Expected result:** Godot error. Cannot open scene at empty path.

#### 4. Edge case — non-existent file
- **Description:** Path to a file that does not exist.
- **Params:** `{ "path": "res://scenes/does_not_exist.tscn" }`
- **Expected result:** Godot error. File not found or cannot open scene.

#### 5. Edge case — path to non-scene file
- **Description:** Try to open a .gd script file as a scene.
- **Params:** `{ "path": "res://scripts/player.gd" }`
- **Expected result:** Godot error. Not a valid scene file.

#### 6. Edge case — path without res:// prefix
- **Description:** Using a relative path.
- **Params:** `{ "path": "scenes/main.tscn" }`
- **Expected result:** May fail. Should verify if relative paths are resolved.

---

## Tool: delete_scene

**Description:** Delete a scene file from the project.

**Handler:** `callGodot(bridge, 'scene/delete', args)`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (ScenePath) | **Yes** | — | Scene file path to delete |
| `force` | `boolean` | No | — | Force close and delete if scene is currently open |

### Test Scenarios

#### 1. Happy path — delete without force
- **Description:** Delete a non-open scene file.
- **Params:** `{ "path": "res://scenes/to_delete.tscn" }`
- **Expected result:** Success. Scene file removed from disk.
- **Preconditions:** Create a temporary scene file for this test.

#### 2. Happy path — delete with force=true
- **Description:** Delete with force flag explicitly true.
- **Params:** `{ "path": "res://scenes/to_delete2.tscn", "force": true }`
- **Expected result:** Success. Scene file deleted even if open.
- **Preconditions:** Create a temporary scene file.

#### 3. Happy path — delete with force=false
- **Description:** Delete with force flag explicitly false.
- **Params:** `{ "path": "res://scenes/to_delete3.tscn", "force": false }`
- **Expected result:** Success. Scene deleted since it is not open.

#### 4. Edge case — missing path
- **Description:** Call without the required path.
- **Params:** `{}`
- **Expected result:** Validation error. `path` is required.

#### 5. Edge case — non-existent file
- **Description:** Try to delete a file that doesn't exist.
- **Params:** `{ "path": "res://scenes/never_existed.tscn" }`
- **Expected result:** Godot error. File not found.

#### 6. Edge case — delete open scene without force
- **Description:** Delete the currently open scene without force flag.
- **Params:** `{ "path": "res://scenes/currently_open.tscn" }`
- **Expected result:** Godot error. Cannot delete open scene. Requires force.
- **Preconditions:** Ensure the target scene is open in the editor.

#### 7. Edge case — delete open scene with force=true
- **Description:** Delete the currently open scene with force=true.
- **Params:** `{ "path": "res://scenes/currently_open.tscn", "force": true }`
- **Expected result:** Success. Scene is closed then deleted.
- **Preconditions:** Ensure the target scene is open in the editor.

#### 8. Edge case — force as non-boolean
- **Description:** Pass a string for the force parameter.
- **Params:** `{ "path": "res://scenes/test.tscn", "force": "yes" }`
- **Expected result:** Validation error. Expected boolean, received string.

---

## Tool: add_scene_instance

**Description:** Add an instance of a scene as a child of a node in the current scene.

**Handler:** `callGodot(bridge, 'scene/add_instance', args)`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `scene_path` | `string` (ScenePath) | **Yes** | — | Path to the scene to instantiate |
| `parent_path` | `string` | No | (scene root) | Parent node path, defaults to scene root |

### Test Scenarios

#### 1. Happy path — instance at root (default parent)
- **Description:** Add a scene instance with no parent_path specified. Should add to scene root.
- **Params:** `{ "scene_path": "res://scenes/child.tscn" }`
- **Expected result:** Success. Scene instance added as child of scene root.
- **Preconditions:** Current scene is open; child.tscn exists.

#### 2. Happy path — instance under named parent
- **Description:** Add a scene instance as child of a specific node.
- **Params:** `{ "scene_path": "res://scenes/child.tscn", "parent_path": "Container" }`
- **Expected result:** Success. Instance added under the "Container" node.
- **Preconditions:** A node named "Container" exists in current scene.

#### 3. Happy path — instance under nested parent
- **Description:** Add a scene instance under a deeply nested node.
- **Params:** `{ "scene_path": "res://scenes/child.tscn", "parent_path": "UI/Panel/Container" }`
- **Expected result:** Success. Instance added under the nested path.
- **Preconditions:** The full parent path exists.

#### 4. Happy path — empty parent_path (explicit root)
- **Description:** Explicitly set parent_path to empty string for scene root.
- **Params:** `{ "scene_path": "res://scenes/child.tscn", "parent_path": "" }`
- **Expected result:** Success. Instance added to scene root (same as no parent_path).

#### 5. Edge case — missing scene_path
- **Description:** Call without the required scene_path.
- **Params:** `{ "parent_path": "Root" }`
- **Expected result:** Validation error. `scene_path` is required.

#### 6. Edge case — non-existent scene file
- **Description:** Try to instantiate a scene that doesn't exist.
- **Params:** `{ "scene_path": "res://scenes/missing.tscn" }`
- **Expected result:** Godot error. Scene file not found.

#### 7. Edge case — non-existent parent node
- **Description:** Parent path points to a node that doesn't exist.
- **Params:** `{ "scene_path": "res://scenes/child.tscn", "parent_path": "NonExistentNode" }`
- **Expected result:** Godot error. Parent node not found.

#### 8. Edge case — self-reference (instance own scene)
- **Description:** Try to instantiate the currently open scene inside itself.
- **Params:** `{ "scene_path": "res://scenes/current.tscn" }` (when current.tscn is the open scene)
- **Expected result:** Godot error. Cyclic instantiation not allowed.

#### 9. Edge case — scene_path is not a scene file
- **Description:** Pass a .gd script path instead of .tscn.
- **Params:** `{ "scene_path": "res://scripts/player.gd" }`
- **Expected result:** Godot error. Not a valid PackedScene resource.

---

## Tool: play_scene

**Description:** Start playing the current or specified scene. Required before using any runtime tools.

**Handler:** `callGodot(bridge, 'scene/play', args)`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `mode` | `enum: 'main' \| 'current' \| 'custom'` | No | (none) | Play mode |
| `scene_path` | `string` | No | — | Scene to play when mode is 'custom' |

### Schema constraints
- `mode`: `z.enum(['main', 'current', 'custom'])`. Optional.
- `scene_path`: Optional string. Only relevant when `mode` is `'custom'`.

### Test Scenarios

#### 1. Happy path — play main scene (mode='main')
- **Description:** Play the project's main scene.
- **Params:** `{ "mode": "main" }`
- **Expected result:** Success. Main scene starts playing.
- **Preconditions:** A main scene must be set in project settings.

#### 2. Happy path — play current scene (mode='current')
- **Description:** Play the currently open scene.
- **Params:** `{ "mode": "current" }`
- **Expected result:** Success. Currently open scene starts playing.

#### 3. Happy path — play custom scene (mode='custom')
- **Description:** Play a specific scene by path.
- **Params:** `{ "mode": "custom", "scene_path": "res://scenes/test_level.tscn" }`
- **Expected result:** Success. Specified scene starts playing.
- **Preconditions:** test_level.tscn exists.

#### 4. Happy path — no params (default behavior)
- **Description:** Call play_scene with no parameters.
- **Params:** `{}`
- **Expected result:** Success. Should use default play mode (likely 'main' or 'current' depending on plugin).

#### 5. Edge case — mode='custom' without scene_path
- **Description:** Use custom mode but omit the scene path.
- **Params:** `{ "mode": "custom" }`
- **Expected result:** Godot error. Custom mode requires a scene path.
- **Notes:** Schema does not enforce mutual requirement — this is caught at runtime.

#### 6. Edge case — scene_path without mode='custom'
- **Description:** Provide scene_path but use mode='main'.
- **Params:** `{ "mode": "main", "scene_path": "res://scenes/other.tscn" }`
- **Expected result:** May be ignored (plays main scene) or error. Behavior depends on plugin.
- **Notes:** The scene_path should be irrelevant when mode is not 'custom'.

#### 7. Edge case — invalid mode value
- **Description:** Pass a value not in the enum.
- **Params:** `{ "mode": "invalid_mode" }`
- **Expected result:** Validation error. `mode` must be one of: 'main', 'current', 'custom'.

#### 8. Edge case — non-existent custom scene
- **Description:** Custom mode with a scene path that doesn't exist.
- **Params:** `{ "mode": "custom", "scene_path": "res://scenes/nonexistent.tscn" }`
- **Expected result:** Godot error. Scene file not found.

#### 9. Edge case — play when already playing
- **Description:** Call play_scene while a scene is already running.
- **Params:** `{ "mode": "main" }`
- **Expected result:** May error or restart. Behavior should be documented.

#### 10. Edge case — play with no main scene set (mode='main')
- **Description:** Use mode='main' when project has no main scene configured.
- **Params:** `{ "mode": "main" }`
- **Expected result:** Godot error. No main scene defined.

---

## Tool: stop_scene

**Description:** Stop the currently playing scene.

**Handler:** `callGodot(bridge, 'scene/stop')` (no args)

### Parameters

*None.* This tool takes no parameters.

### Test Scenarios

#### 1. Happy path — stop running scene
- **Description:** Stop a scene that is currently playing.
- **Params:** `{}`
- **Expected result:** Success. Scene stops, editor returns to edit mode.
- **Preconditions:** A scene must be running (call play_scene first).

#### 2. Edge case — stop when not playing
- **Description:** Call stop_scene when nothing is playing.
- **Params:** `{}`
- **Expected result:** Should succeed gracefully (no-op) or return a harmless warning.
- **Notes:** Confirm expected behavior — should not crash.

#### 3. Edge case — extraneous params ignored
- **Description:** Pass unexpected parameters (tool has no inputSchema).
- **Params:** `{ "foo": "bar" }`
- **Expected result:** May be silently ignored or cause a validation warning. Since inputSchema is `{}`, extra params might be ignored.

---

## Tool: save_scene

**Description:** Save the current scene or save it to a new path.

**Handler:** `callGodot(bridge, 'scene/save', args)`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` | No | (current scene) | Path of the scene to save (defaults to current) |

### Test Scenarios

#### 1. Happy path — save current scene (no params)
- **Description:** Save the currently open scene without specifying a path.
- **Params:** `{}`
- **Expected result:** Success. Current scene is saved to its existing path.
- **Preconditions:** A scene must be open and have unsaved changes (or be saveable).

#### 2. Happy path — save as new path (Save As)
- **Description:** Save the current scene to a new file path.
- **Params:** `{ "path": "res://scenes/saved_copy.tscn" }`
- **Expected result:** Success. Scene saved to new path.
- **Preconditions:** Scene is open in editor.

#### 3. Happy path — save as overwriting existing
- **Description:** Save as a path that already has a file.
- **Params:** `{ "path": "res://scenes/existing.tscn" }`
- **Expected result:** Should succeed (overwrite) or warn. Behavior depends on plugin.

#### 4. Edge case — empty string path
- **Description:** Pass empty string as path.
- **Params:** `{ "path": "" }`
- **Expected result:** Godot error. Cannot save to empty path.

#### 5. Edge case — invalid path format
- **Description:** Path without extension or invalid characters.
- **Params:** `{ "path": "not-a-valid-path!!!" }`
- **Expected result:** Godot error. Invalid path.

#### 6. Edge case — no scene open
- **Description:** Call save when no scene is loaded.
- **Params:** `{}`
- **Expected result:** Godot error. No scene to save.

---

## Tool: get_loaded_scenes

**Description:** Get a list of all currently loaded scenes in the editor.

**Handler:** `callGodot(bridge, 'scene/get_loaded')` (no args)

### Parameters

*None.* This tool takes no parameters.

### Test Scenarios

#### 1. Happy path — single scene loaded
- **Description:** Get list of loaded scenes when one scene is open.
- **Params:** `{}`
- **Expected result:** Success. Returns an array with one scene entry.

#### 2. Happy path — multiple scenes loaded (additive)
- **Description:** Get list of loaded scenes when multiple scenes are loaded additively.
- **Params:** `{}`
- **Expected result:** Success. Returns an array with multiple scene entries.
- **Preconditions:** Load multiple scenes additively.

#### 3. Edge case — no scenes loaded
- **Description:** Call when no scene is open in the editor.
- **Params:** `{}`
- **Expected result:** Should return an empty array or null.
- **Notes:** Document the exact return format when no scenes are loaded.

---

## Tool: set_main_scene

**Description:** Set the project's main scene.

**Handler:** `callGodot(bridge, 'scene/set_main', args)`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (ScenePath) | **Yes** | — | Scene file path to set as main scene |

### Test Scenarios

#### 1. Happy path — set main scene
- **Description:** Set the project's main scene to a valid existing scene.
- **Params:** `{ "path": "res://scenes/main.tscn" }`
- **Expected result:** Success. Project's main scene is updated.
- **Preconditions:** The scene file must exist. Save and note the previous main scene for cleanup.

#### 2. Edge case — missing path
- **Description:** Call without the required path.
- **Params:** `{}`
- **Expected result:** Validation error. `path` is required.

#### 3. Edge case — non-existent scene
- **Description:** Set main scene to a file that doesn't exist.
- **Params:** `{ "path": "res://scenes/not_a_real_scene.tscn" }`
- **Expected result:** Godot error. Scene file not found.

#### 4. Edge case — path to non-scene file
- **Description:** Try to set a .gd script as main scene.
- **Params:** `{ "path": "res://scripts/player.gd" }`
- **Expected result:** Godot error. Not a valid scene file.

#### 5. Edge case — empty string path
- **Description:** Pass empty string.
- **Params:** `{ "path": "" }`
- **Expected result:** Godot error. Cannot set main scene to empty path.

---

## Tool: get_main_scene

**Description:** Get the project main scene path.

**Handler:** `callGodot(bridge, 'scene/get_main', {})`

### Parameters

*None.* This tool takes no parameters.

### Test Scenarios

#### 1. Happy path — main scene is set
- **Description:** Call when a main scene is configured in the project.
- **Params:** `{}`
- **Expected result:** Success. Returns the path of the main scene (e.g. `"res://scenes/main.tscn"`).

#### 2. Edge case — no main scene set
- **Description:** Call when the project has no main scene configured.
- **Params:** `{}`
- **Expected result:** Should return null, empty string, or an error message.
- **Notes:** Document the expected return value when no main scene is set.

---

## Cross-tool Integration Scenarios

### Scenario: Create → Open → Edit → Save → Play → Stop workflow
1. `create_scene` with path and root_node_type to make a new scene
2. `open_scene` to open it (if not automatically opened)
3. `save_scene` with a new path (Save As)
4. `set_main_scene` to set it as main
5. `get_main_scene` to verify it was set
6. `play_scene` with mode='main' to run it
7. `stop_scene` to stop
8. `delete_scene` with force=true to clean up

### Scenario: Scene instance and tree inspection
1. `create_scene` to make a child scene
2. `open_scene` the parent scene
3. `add_scene_instance` to instance the child scene
4. `get_scene_tree` to verify the instance appears in the tree
5. `get_scene_file_content` on the parent scene to verify serialization

---

## Summary of All Parameters by Required/Optional

### Required Parameters
| Tool | Parameter | Type |
|------|-----------|------|
| `get_scene_file_content` | `path` | `string` (ScenePath) |
| `create_scene` | `path` | `string` (ScenePath) |
| `open_scene` | `path` | `string` (ScenePath) |
| `delete_scene` | `path` | `string` (ScenePath) |
| `add_scene_instance` | `scene_path` | `string` (ScenePath) |
| `set_main_scene` | `path` | `string` (ScenePath) |

### Optional Parameters
| Tool | Parameter | Type | Default | Constraints |
|------|-----------|------|---------|-------------|
| `get_scene_tree` | `max_depth` | `number` (int) | `15` | `> 0`, integer |
| `create_scene` | `root_node_type` | `string` | — | Any valid Godot node type |
| `delete_scene` | `force` | `boolean` | — | `true` or `false` |
| `add_scene_instance` | `parent_path` | `string` | scene root | Valid node path in current scene |
| `play_scene` | `mode` | `enum` | — | `'main'`, `'current'`, `'custom'` |
| `play_scene` | `scene_path` | `string` | — | Required when `mode='custom'` |
| `save_scene` | `path` | `string` | current scene | Valid file path |

### No-Parameter Tools
- `stop_scene` — no input schema
- `get_loaded_scenes` — no input schema
- `get_main_scene` — no input schema
