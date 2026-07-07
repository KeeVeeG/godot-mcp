# Scene Tools — Test Plan

**Source file:** `server/src/tools/scene.ts`
**Shared types:** `server/src/tools/shared-types.ts`
**Number of tools:** 12
**Generated:** 2026-07-08

---

## Type Reference

| Zod schema | Underlying type | Description |
|---|---|---|
| `ScenePath` | `z.string()` | Scene file path (e.g. `'res://scenes/main.tscn'`) |
| `z.enum(['main', 'current', 'custom'])` | enum string | Play mode selection |
| `z.number().int().positive()` | number (int, >0) | Positive integer |
| `z.boolean()` | boolean | Boolean flag |
| `z.string()` | string | Generic string |

---

## Tool: `get_scene_tree`

**Description:** Get the node tree of the specified or currently open scene
**Handler:** `callGodot(bridge, 'scene/get_tree', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `max_depth` | positive integer | No | `15` | Maximum tree depth to serialize (default: 15) |

### Test Scenarios

#### Scenario 1: Happy path — default depth (no params)
- **Description:** Get the scene tree of the currently open scene with default max_depth of 15
- **Params:** `{}`
- **Expected result:** Success. Returns a JSON object representing the scene tree, truncated at depth 15.

#### Scenario 2: Happy path — custom max_depth shallow
- **Description:** Get scene tree with max_depth = 1 (only root and direct children)
- **Params:** `{ "max_depth": 1 }`
- **Expected result:** Success. Returns only the root node and its immediate children.

#### Scenario 3: Happy path — custom max_depth deep
- **Description:** Get scene tree with max_depth = 50
- **Params:** `{ "max_depth": 50 }`
- **Expected result:** Success. Returns the full scene tree up to depth 50.

#### Scenario 4: Edge — max_depth = 0
- **Description:** Call with max_depth = 0
- **Params:** `{ "max_depth": 0 }`
- **Expected result:** Zod validation error. `z.number().int().positive()` rejects 0 (must be > 0).

#### Scenario 5: Edge — max_depth negative
- **Description:** Call with a negative max_depth
- **Params:** `{ "max_depth": -5 }`
- **Expected result:** Zod validation error. `z.number().int().positive()` rejects negative numbers.

#### Scenario 6: Edge — max_depth as float
- **Description:** Call with a non-integer max_depth
- **Params:** `{ "max_depth": 3.7 }`
- **Expected result:** Zod validation error. `z.number().int()` rejects floats.

#### Scenario 7: Edge — max_depth as string
- **Description:** Call with a string value for max_depth
- **Params:** `{ "max_depth": "15" }`
- **Expected result:** Zod validation error. Expected number, got string.

#### Scenario 8: Edge — no scene open
- **Description:** Call when no scene is open in the editor
- **Params:** `{}`
- **Expected result:** Error from Godot (no open scene) or returns empty tree.

---

## Tool: `get_scene_file_content`

**Description:** Read the raw .tscn/.scn file content of a scene
**Handler:** `callGodot(bridge, 'scene/get_file_content', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `ScenePath` (string) | **Yes** | — | Scene file path (e.g. `'res://scenes/main.tscn'`) |

### Test Scenarios

#### Scenario 1: Happy path — read .tscn file
- **Description:** Read the raw text content of an existing .tscn scene file
- **Params:** `{ "path": "res://scenes/main.tscn" }`
- **Expected result:** Success. Returns the full raw text content of the .tscn file.
- **Notes:** Requires `res://scenes/main.tscn` to exist.

#### Scenario 2: Happy path — read .scn file
- **Description:** Read a binary .scn scene file (if any exist)
- **Params:** `{ "path": "res://scenes/some_scene.scn" }`
- **Expected result:** Success. Returns the binary content representation of the .scn file.

#### Scenario 3: Edge — file not found
- **Description:** Read a scene file that does not exist
- **Params:** `{ "path": "res://scenes/nonexistent.tscn" }`
- **Expected result:** Error from Godot (file not found).

#### Scenario 4: Edge — missing required param
- **Description:** Call without the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 5: Edge — empty path string
- **Description:** Call with an empty path string
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot (invalid path — empty string is not a valid file path).

#### Scenario 6: Edge — path to a non-scene file
- **Description:** Read a file that is not a scene (e.g., a .gd script)
- **Params:** `{ "path": "res://scripts/some_script.gd" }`
- **Expected result:** May still return file contents (reads any file), or Godot may reject non-.tscn/.scn paths.

#### Scenario 7: Edge — path with spaces or special characters
- **Description:** Read a scene file whose path contains spaces or special characters
- **Params:** `{ "path": "res://scenes/my scene.tscn" }`
- **Expected result:** Should succeed if the file exists; verify path encoding is correct.

---

## Tool: `create_scene`

**Description:** Create a new empty scene with a specified root node type
**Handler:** `callGodot(bridge, 'scene/create', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `ScenePath` (string) | **Yes** | — | Path to save the scene (e.g. `'res://scenes/new.tscn'`) |
| `root_node_type` | string | No | — | Root node type (e.g. `'Node2D'`, `'Control'`) |

### Test Scenarios

#### Scenario 1: Happy path — create scene with root_node_type
- **Description:** Create a new scene with a Node2D root
- **Params:** `{ "path": "res://scenes/test_create.tscn", "root_node_type": "Node2D" }`
- **Expected result:** Success. A new scene file is created at `res://scenes/test_create.tscn` with a Node2D root.

#### Scenario 2: Happy path — create scene with Control root
- **Description:** Create a new scene with a Control (UI) root
- **Params:** `{ "path": "res://scenes/test_create_ui.tscn", "root_node_type": "Control" }`
- **Expected result:** Success. A new scene file is created with a Control root node.

#### Scenario 3: Happy path — create scene with Node3D root
- **Description:** Create a new scene with a Node3D root (for 3D scenes)
- **Params:** `{ "path": "res://scenes/test_create_3d.tscn", "root_node_type": "Node3D" }`
- **Expected result:** Success. A new scene file is created with a Node3D root.

#### Scenario 4: Happy path — create scene without root_node_type
- **Description:** Create a scene specifying only the path (root_node_type is optional — note: it's `z.string().optional()`)
- **Params:** `{ "path": "res://scenes/test_create_default.tscn" }`
- **Expected result:** Behavior depends on Godot — may default to `Node` as root type, or error if a root type is required. Test to determine actual behavior.

#### Scenario 5: Edge — missing required param
- **Description:** Call without the required `path` parameter
- **Params:** `{ "root_node_type": "Node2D" }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 6: Edge — empty path
- **Description:** Call with an empty path string
- **Params:** `{ "path": "", "root_node_type": "Node2D" }`
- **Expected result:** Error from Godot (invalid path).

#### Scenario 7: Edge — overwrite existing scene
- **Description:** Create a scene at a path that already exists
- **Params:** `{ "path": "res://scenes/main.tscn", "root_node_type": "Node2D" }`
- **Expected result:** Behavior depends on Godot — may overwrite, reject with error, or prompt. Test to verify.

#### Scenario 8: Edge — invalid root_node_type
- **Description:** Pass a node type that does not exist
- **Params:** `{ "path": "res://scenes/test_bad_type.tscn", "root_node_type": "NonExistentNodeType" }`
- **Expected result:** Error from Godot (unknown node type).

#### Scenario 9: Edge — path without .tscn extension
- **Description:** Create a scene with a path lacking the .tscn extension
- **Params:** `{ "path": "res://scenes/test_no_ext", "root_node_type": "Node2D" }`
- **Expected result:** May fail depending on Godot. Godot typically requires `.tscn` or `.scn` extension for scenes.

#### Scenario 10: Edge — path in non-existent directory
- **Description:** Create a scene in a directory that does not exist
- **Params:** `{ "path": "res://scenes/new_dir/test_create.tscn", "root_node_type": "Node2D" }`
- **Expected result:** Error from Godot (directory does not exist), or Godot auto-creates directories.

#### Scenario 11: Edge — common root node types
- **Description:** Test with various common root node types
- **Params:** Each of: `"Node"`, `"CharacterBody2D"`, `"RigidBody3D"`, `"Panel"`, `"PanelContainer"`
- **Expected result:** Each should succeed with the respective root node type.

---

## Tool: `open_scene`

**Description:** Open a scene file in the editor
**Handler:** `callGodot(bridge, 'scene/open', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `ScenePath` (string) | **Yes** | — | Scene file path to open |

### Test Scenarios

#### Scenario 1: Happy path — open an existing scene
- **Description:** Open an existing .tscn file in the editor
- **Params:** `{ "path": "res://scenes/test_create.tscn" }`
- **Expected result:** Success. The scene is opened in the editor (becomes the currently active scene).
- **Notes:** Requires the scene created by `create_scene` first.

#### Scenario 2: Happy path — open the main scene
- **Description:** Open the project's main scene
- **Params:** `{ "path": "res://scenes/main.tscn" }`
- **Expected result:** Success. The main scene opens in the editor.

#### Scenario 3: Edge — file not found
- **Description:** Open a non-existent scene
- **Params:** `{ "path": "res://scenes/nonexistent.tscn" }`
- **Expected result:** Error from Godot (scene file not found).

#### Scenario 4: Edge — missing required param
- **Description:** Call without the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 5: Edge — empty path
- **Description:** Call with an empty path string
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot (invalid path).

#### Scenario 6: Edge — open unsaved scene (prompt to save)
- **Description:** Open a new scene while unsaved changes exist in the current scene
- **Params:** `{ "path": "res://scenes/test_create.tscn" }`
- **Expected result:** Godot may prompt to save changes. The MCP bridge should handle this (likely auto-save or bypass). Test to verify behavior.
- **Notes:** First modify the current scene (e.g., add a node) without saving.

#### Scenario 7: Edge — path is not a scene file
- **Description:** Open a non-scene file
- **Params:** `{ "path": "res://scripts/some_script.gd" }`
- **Expected result:** Error from Godot (not a scene file, or unexpected behavior).

---

## Tool: `delete_scene`

**Description:** Delete a scene file from the project
**Handler:** `callGodot(bridge, 'scene/delete', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `ScenePath` (string) | **Yes** | — | Scene file path to delete |
| `force` | boolean | No | — | Force close and delete if scene is currently open |

### Test Scenarios

#### Scenario 1: Happy path — delete a closed scene without force
- **Description:** Delete a scene file that is not currently open in the editor
- **Params:** `{ "path": "res://scenes/test_create_default.tscn" }`
- **Expected result:** Success. The scene file is deleted from the project.
- **Notes:** Ensure the scene is not currently open.

#### Scenario 2: Happy path — force delete an open scene
- **Description:** Force-delete a scene that is currently open in the editor
- **Params:** `{ "path": "res://scenes/test_create.tscn", "force": true }`
- **Expected result:** Success. Scene is closed and deleted despite being open.
- **Notes:** Open the scene with `open_scene` first, then force-delete.

#### Scenario 3: Edge — delete open scene without force
- **Description:** Attempt to delete a scene that is currently open without force flag
- **Params:** `{ "path": "res://scenes/test_create_3d.tscn", "force": false }`
- **Expected result:** Error from Godot (scene is currently open). Alternatively, may succeed if Godot allows it.
- **Notes:** Open the scene first, then try to delete without force.

#### Scenario 4: Edge — file not found
- **Description:** Delete a non-existent scene
- **Params:** `{ "path": "res://scenes/nonexistent.tscn" }`
- **Expected result:** Error from Godot (file not found).

#### Scenario 5: Edge — missing required param
- **Description:** Call without the required `path` parameter
- **Params:** `{ "force": true }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 6: Edge — empty path
- **Description:** Call with an empty path string
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot (invalid path).

#### Scenario 7: Edge — force as string instead of boolean
- **Description:** Call with a non-boolean `force` value
- **Params:** `{ "path": "res://scenes/test_create_ui.tscn", "force": "true" }`
- **Expected result:** Zod validation error (expected boolean, got string).

#### Scenario 8: Edge — delete a scene referenced by another scene
- **Description:** Delete a scene that is instantiated by another scene as a sub-scene
- **Params:** `{ "path": "res://scenes/referenced_scene.tscn" }`
- **Expected result:** May succeed with warning, or error. Depends on Godot's reference tracking.

#### Scenario 9: Edge — path to a non-.tscn file
- **Description:** Attempt to delete a file that is not a scene
- **Params:** `{ "path": "res://scripts/some_script.gd" }`
- **Expected result:** May succeed (deletes any file) or error (only scene files). Test to verify.

---

## Tool: `add_scene_instance`

**Description:** Add an instance of a scene as a child of a node in the current scene
**Handler:** `callGodot(bridge, 'scene/add_instance', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `scene_path` | `ScenePath` (string) | **Yes** | — | Path to the scene to instantiate |
| `parent_path` | string | No | — | Parent node path, defaults to scene root |

### Test Scenarios

#### Scenario 1: Happy path — add scene instance with explicit parent
- **Description:** Instantiate a scene as a child of a specific node
- **Params:** `{ "scene_path": "res://scenes/test_create_default.tscn", "parent_path": "SomeExistingNode" }`
- **Expected result:** Success. The scene is instantiated as a child of `SomeExistingNode`.
- **Notes:** Requires an open scene with a node named `SomeExistingNode`.

#### Scenario 2: Happy path — add scene instance to scene root (no parent_path)
- **Description:** Instantiate a scene without specifying a parent (defaults to root)
- **Params:** `{ "scene_path": "res://scenes/test_create_default.tscn" }`
- **Expected result:** Success. The scene is instantiated as a direct child of the scene root.

#### Scenario 3: Happy path — empty parent_path string
- **Description:** Instantiate with explicit empty parent_path (should behave like root)
- **Params:** `{ "scene_path": "res://scenes/test_create_default.tscn", "parent_path": "" }`
- **Expected result:** Success. The scene is instantiated at the scene root. Test to confirm empty string is treated as root.

#### Scenario 4: Edge — missing required param
- **Description:** Call without the required `scene_path`
- **Params:** `{ "parent_path": "SomeNode" }`
- **Expected result:** Zod validation error (scene_path is required).

#### Scenario 5: Edge — scene_path does not exist
- **Description:** Instantiate a non-existent scene
- **Params:** `{ "scene_path": "res://scenes/nonexistent.tscn" }`
- **Expected result:** Error from Godot (scene file not found).

#### Scenario 6: Edge — parent_path does not exist
- **Description:** Instantiate under a non-existent parent node
- **Params:** `{ "scene_path": "res://scenes/test_create_default.tscn", "parent_path": "NonExistentNode" }`
- **Expected result:** Error from Godot (parent node not found).

#### Scenario 7: Edge — empty scene_path
- **Description:** Call with empty scene_path string
- **Params:** `{ "scene_path": "" }`
- **Expected result:** Error from Godot (invalid path).

#### Scenario 8: Edge — nested parent_path
- **Description:** Instantiate under a deeply nested parent node
- **Params:** `{ "scene_path": "res://scenes/test_create_default.tscn", "parent_path": "Parent/Child/Grandchild" }`
- **Expected result:** Success if the full path exists; error otherwise.

#### Scenario 9: Edge — self-referential instantiation
- **Description:** Try to instantiate the currently open scene into itself
- **Params:** (Use the path of the currently open scene)
- **Expected result:** Error (circular dependency detected).

#### Scenario 10: Edge — instantiate a scene with spaces in path
- **Description:** Instantiate a scene where the path contains spaces
- **Params:** `{ "scene_path": "res://scenes/my test scene.tscn" }`
- **Expected result:** Should succeed if the file exists; verify path encoding is correct.

---

## Tool: `play_scene`

**Description:** Start playing the current or specified scene. Required before using any runtime tools (get_game_*, capture_frames, etc.)
**Handler:** `callGodot(bridge, 'scene/play', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `mode` | enum: `'main'` \| `'current'` \| `'custom'` | No | — | Play mode: `'main'` (main scene), `'current'` (open scene), or `'custom'` (specified by scene_path) |
| `scene_path` | string | No | — | Scene to play when mode is `'custom'` |

### Test Scenarios

#### Scenario 1: Happy path — play with mode 'main' (no scene_path)
- **Description:** Start playing the project's main scene (as configured in project settings)
- **Params:** `{ "mode": "main" }`
- **Expected result:** Success. The main scene begins playing. `get_game_scene_tree` should now return runtime data.
- **Notes:** Requires a main scene to be configured via `set_main_scene`.

#### Scenario 2: Happy path — play with mode 'current'
- **Description:** Start playing the currently open scene
- **Params:** `{ "mode": "current" }`
- **Expected result:** Success. The currently open scene begins playing.

#### Scenario 3: Happy path — play with mode 'custom' and scene_path
- **Description:** Play a specific scene specified by scene_path
- **Params:** `{ "mode": "custom", "scene_path": "res://scenes/test_create_3d.tscn" }`
- **Expected result:** Success. The specified scene begins playing.

#### Scenario 4: Happy path — play with no params (default behavior)
- **Description:** Call play_scene with no arguments at all
- **Params:** `{}`
- **Expected result:** Depends on Godot's default behavior. Since all params are optional, this should not fail validation. Godot may play the current scene or main scene.

#### Scenario 5: Edge — mode 'custom' without scene_path
- **Description:** Call with mode=custom but no scene_path specified
- **Params:** `{ "mode": "custom" }`
- **Expected result:** May error from Godot (mode 'custom' requires a scene_path). Test to verify.

#### Scenario 6: Edge — scene_path with mode 'main'
- **Description:** Call with mode=main and also provide scene_path (redundant parameter)
- **Params:** `{ "mode": "main", "scene_path": "res://scenes/test_create.tscn" }`
- **Expected result:** The scene_path may be ignored (main mode should use project main scene). Test to verify Godot's behavior.

#### Scenario 7: Edge — invalid mode value
- **Description:** Call with a mode string not in the enum
- **Params:** `{ "mode": "invalid_mode" }`
- **Expected result:** Zod validation error (mode must be 'main', 'current', or 'custom').

#### Scenario 8: Edge — non-existent scene_path with mode 'custom'
- **Description:** Play a custom scene that does not exist
- **Params:** `{ "mode": "custom", "scene_path": "res://scenes/nonexistent.tscn" }`
- **Expected result:** Error from Godot (scene file not found).

#### Scenario 9: Edge — already playing
- **Description:** Call play_scene while a scene is already playing
- **Params:** `{ "mode": "main" }`
- **Expected result:** Error from Godot (scene already playing), or Godot stops the current scene and restarts.

#### Scenario 10: Edge — scene_path with mode 'current'
- **Description:** Call with mode=current and also provide scene_path
- **Params:** `{ "mode": "current", "scene_path": "res://scenes/test_create.tscn" }`
- **Expected result:** The scene_path may be ignored (current mode should use the open scene). Test to verify.

---

## Tool: `stop_scene`

**Description:** Stop the currently playing scene
**Handler:** `callGodot(bridge, 'scene/stop')`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| — | — | — | — | No parameters |

### Test Scenarios

#### Scenario 1: Happy path — stop a running scene
- **Description:** Stop a scene that is currently playing
- **Params:** `{}`
- **Expected result:** Success. The running scene stops, editor returns to normal.
- **Notes:** Requires a scene to be playing (start via `play_scene` first).

#### Scenario 2: Edge — stop when no scene is playing
- **Description:** Call stop_scene when the editor is not playing any scene
- **Params:** `{}`
- **Expected result:** Should succeed silently (no-op), or possibly return an info message. Test to verify.

#### Scenario 3: Edge — extra parameters passed
- **Description:** Call stop_scene with unexpected extra parameters
- **Params:** `{ "mode": "main" }`
- **Expected result:** Since handler ignores args (`async () => callGodot(bridge, 'scene/stop')`), extra params are silently ignored. The tool should still work (stop the scene or no-op).

---

## Tool: `save_scene`

**Description:** Save the current scene or save it to a new path
**Handler:** `callGodot(bridge, 'scene/save', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | string | No | — | Path of the scene to save (defaults to current) |

### Test Scenarios

#### Scenario 1: Happy path — save current scene (no path)
- **Description:** Save the currently open scene (in-place)
- **Params:** `{}`
- **Expected result:** Success. The current scene is saved to its existing file path.

#### Scenario 2: Happy path — save to a new path (Save As)
- **Description:** Save the current scene to a new path (effectively "Save As")
- **Params:** `{ "path": "res://scenes/test_save_as.tscn" }`
- **Expected result:** Success. The scene is saved to the new path. The editor now references the new path.

#### Scenario 3: Happy path — save with explicit path matching current
- **Description:** Save the current scene explicitly specifying its own path
- **Params:** `{ "path": "res://scenes/test_create.tscn" }`
- **Expected result:** Success. Scene is saved to the same path (same as no-path behavior).
- **Notes:** Open `res://scenes/test_create.tscn` first.

#### Scenario 4: Edge — save to path that already exists (overwrite)
- **Description:** Save As to a path that already has a scene file
- **Params:** `{ "path": "res://scenes/existing_scene.tscn" }`
- **Expected result:** Godot may prompt for overwrite confirmation, overwrite silently, or error. Test to verify.

#### Scenario 5: Edge — save with empty path string
- **Description:** Call with empty string as path
- **Params:** `{ "path": "" }`
- **Expected result:** May be treated as "no path" (save current) or error (invalid path). Test to verify.

#### Scenario 6: Edge — no scene open
- **Description:** Call save_scene when no scene is open in the editor
- **Params:** `{}`
- **Expected result:** Error from Godot (no scene to save).

#### Scenario 7: Edge — save to non-.tscn extension
- **Description:** Save to a path without proper extension
- **Params:** `{ "path": "res://scenes/test_save_no_ext" }`
- **Expected result:** May succeed with auto-appended extension, or error. Test to verify.

#### Scenario 8: Edge — save with special characters in path
- **Description:** Save to a path containing spaces or Unicode
- **Params:** `{ "path": "res://scenes/my saved scene.tscn" }`
- **Expected result:** Should succeed. Verify path encoding works.

---

## Tool: `get_loaded_scenes`

**Description:** Get a list of all currently loaded scenes in the editor
**Handler:** `callGodot(bridge, 'scene/get_loaded')`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| — | — | — | — | No parameters |

### Test Scenarios

#### Scenario 1: Happy path — single scene loaded
- **Description:** Get the list of loaded scenes when one scene is open
- **Params:** `{}`
- **Expected result:** Success. Returns an array with one entry (the currently open scene) containing its path and metadata.

#### Scenario 2: Happy path — after adding scene instances
- **Description:** Get loaded scenes after using `add_scene_instance` (sub-scene may appear)
- **Params:** `{}`
- **Expected result:** Success. Returns the open scene. Sub-scenes may or may not appear as separately loaded depending on Godot's behavior.

#### Scenario 3: Edge — no scenes loaded
- **Description:** Call when no scenes are loaded (fresh editor start, all scenes closed)
- **Params:** `{}`
- **Expected result:** Success. Returns an empty array.

#### Scenario 4: Edge — extra parameters passed
- **Description:** Call with unexpected arguments
- **Params:** `{ "path": "res://scenes/main.tscn" }`
- **Expected result:** Handler ignores args (`async () => callGodot(bridge, 'scene/get_loaded')`). Extra params silently ignored, tool returns loaded scenes regardless.

---

## Tool: `set_main_scene`

**Description:** Set the project's main scene
**Handler:** `callGodot(bridge, 'scene/set_main', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `ScenePath` (string) | **Yes** | — | Scene file path to set as main scene |

### Test Scenarios

#### Scenario 1: Happy path — set an existing scene as main
- **Description:** Set the project's main scene to an existing .tscn file
- **Params:** `{ "path": "res://scenes/test_create.tscn" }`
- **Expected result:** Success. The project's main scene is updated. `get_main_scene` should now return this path.

#### Scenario 2: Edge — file not found
- **Description:** Set the main scene to a non-existent file
- **Params:** `{ "path": "res://scenes/nonexistent.tscn" }`
- **Expected result:** Error from Godot (file not found), or Godot may accept the path but fail when trying to play.

#### Scenario 3: Edge — missing required param
- **Description:** Call without the required `path`
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 4: Edge — empty path string
- **Description:** Set main scene to empty string
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot (invalid path), or possibly clears the main scene setting.

#### Scenario 5: Edge — path to non-.tscn file
- **Description:** Set a non-scene file as the main scene
- **Params:** `{ "path": "res://scripts/some_script.gd" }`
- **Expected result:** Error from Godot (not a scene file).

#### Scenario 6: Edge — set main scene back to original
- **Description:** After changing the main scene, set it back to the original
- **Params:** `{ "path": "res://scenes/main.tscn" }`
- **Expected result:** Success. The main scene is restored to its original value.

#### Scenario 7: Edge — path with spaces
- **Description:** Set main scene using a path with spaces
- **Params:** `{ "path": "res://scenes/my main scene.tscn" }`
- **Expected result:** Should succeed if the file exists.

---

## Tool: `get_main_scene`

**Description:** Get the project main scene path
**Handler:** `callGodot(bridge, 'scene/get_main', {})`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| — | — | — | — | No parameters |

### Test Scenarios

#### Scenario 1: Happy path — get main scene
- **Description:** Retrieve the current main scene path configured in project settings
- **Params:** `{}`
- **Expected result:** Success. Returns the path of the configured main scene (e.g., `"res://scenes/main.tscn"`).

#### Scenario 2: Happy path — after set_main_scene
- **Description:** Call get_main_scene after using set_main_scene to change it
- **Params:** `{}`
- **Expected result:** Success. Returns the newly set main scene path, confirming the change was applied.

#### Scenario 3: Edge — no main scene configured
- **Description:** Call when no main scene is set in the project
- **Params:** `{}`
- **Expected result:** Returns empty string, null, or an empty result depending on Godot's behavior.

#### Scenario 4: Edge — extra parameters passed
- **Description:** Call with unexpected arguments
- **Params:** `{ "path": "ignored" }`
- **Expected result:** Handler passes fixed `{}` to callGodot. Extra params silently ignored. Still returns the main scene path.

---

## Integration Test Scenarios

These scenarios chain multiple scene tools together to verify end-to-end workflows.

### Integration 1: Create → Open → Modify → Save → Delete workflow
1. `create_scene` with `path: "res://scenes/integration_test.tscn"`, `root_node_type: "Node2D"`
2. `open_scene` with `path: "res://scenes/integration_test.tscn"`
3. Add a node to the scene (using node tools)
4. `save_scene` (no params, in-place save)
5. `get_scene_file_content` — verify the scene file reflects the added node
6. `delete_scene` with `path: "res://scenes/integration_test.tscn"`
- **Expected result:** All steps succeed. Scene is created, opened, modified, saved, verified, and deleted cleanly.

### Integration 2: Set Main → Get Main → Play → Stop workflow
1. `set_main_scene` with `path: "res://scenes/test_create.tscn"`
2. `get_main_scene` — verify returns `"res://scenes/test_create.tscn"`
3. `play_scene` with `mode: "main"`
4. Verify the game is running (use runtime tools like `get_game_scene_tree`)
5. `stop_scene`
6. `get_main_scene` — verify unchanged
- **Expected result:** Full main scene lifecycle works end-to-end.

### Integration 3: Create → Save As → Open → Get Tree workflow
1. `create_scene` with `path: "res://scenes/workflow_a.tscn"`, `root_node_type: "Control"`
2. `save_scene` with `path: "res://scenes/workflow_b.tscn"` (Save As — note: save_scene works on the currently active scene, so this depends on create_scene behavior)
3. `open_scene` with `path: "res://scenes/workflow_b.tscn"`
4. `get_scene_tree` — verify Control root node is present
5. `get_scene_file_content` — verify raw content contains `[node type="Control"]`
- **Expected result:** Scene is created, saved to new path, opened, and verified.

### Integration 4: Add Instance → Get Tree → Get Loaded workflow
1. `create_scene` with `path: "res://scenes/sub_scene.tscn"`, `root_node_type: "Sprite2D"`
2. Open a parent scene (e.g., `res://scenes/test_create.tscn`)
3. `add_scene_instance` with `scene_path: "res://scenes/sub_scene.tscn"`, `parent_path: ""` (root)
4. `get_scene_tree` — verify the sub_scene instance appears as a child
5. `get_loaded_scenes` — verify the open scene is loaded
- **Expected result:** Scene instantiation works and is reflected in the tree and loaded list.

### Integration 5: Delete with force flow
1. `create_scene` with `path: "res://scenes/to_delete.tscn"`, `root_node_type: "Node"`
2. `open_scene` with `path: "res://scenes/to_delete.tscn"`
3. `delete_scene` with `path: "res://scenes/to_delete.tscn"`, `force: false` — expect error (scene is open)
4. `delete_scene` with `path: "res://scenes/to_delete.tscn"`, `force: true` — expect success
5. `open_scene` with `path: "res://scenes/to_delete.tscn"` — expect error (file deleted)
- **Expected result:** Confirms that force flag is required to delete an open scene, and that the file is truly removed.

### Integration 6: Play modes round-trip
1. Ensure a main scene is configured (`set_main_scene` if needed)
2. `play_scene` with `mode: "main"` — start playing
3. `stop_scene` — stop
4. Open a scene: `open_scene` with `path: "res://scenes/test_create.tscn"`
5. `play_scene` with `mode: "current"` — play the open scene
6. `stop_scene` — stop
7. `play_scene` with `mode: "custom"`, `scene_path: "res://scenes/test_create_3d.tscn"` — play a specific scene
8. `stop_scene` — stop
- **Expected result:** All three play modes work independently and can be stopped cleanly.

---

## Summary

| Tool | Params | Required | Optional | Enum Values |
|---|---|---|---|---|
| `get_scene_tree` | 1 | — | `max_depth` | — |
| `get_scene_file_content` | 1 | `path` | — | — |
| `create_scene` | 2 | `path` | `root_node_type` | — |
| `open_scene` | 1 | `path` | — | — |
| `delete_scene` | 2 | `path` | `force` | — |
| `add_scene_instance` | 2 | `scene_path` | `parent_path` | — |
| `play_scene` | 2 | — | `mode`, `scene_path` | `mode`: main, current, custom |
| `stop_scene` | 0 | — | — | — |
| `save_scene` | 1 | — | `path` | — |
| `get_loaded_scenes` | 0 | — | — | — |
| `set_main_scene` | 1 | `path` | — | — |
| `get_main_scene` | 0 | — | — | — |

**Total scenarios:** 70+ covering all 12 tools with happy paths, all enum values, edge cases, and integration workflows.
