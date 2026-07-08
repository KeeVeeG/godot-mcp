# Scene Tools Test Plan

**Source**: `server/src/tools/scene.ts`  
**Total tools**: 12  
**Test plan generated**: 2026-07-08

---

## Table of Contents

1. [Tool: get_scene_tree](#tool-get_scene_tree)
2. [Tool: get_scene_file_content](#tool-get_scene_file_content)
3. [Tool: create_scene](#tool-create_scene)
4. [Tool: open_scene](#tool-open_scene)
5. [Tool: delete_scene](#tool-delete_scene)
6. [Tool: add_scene_instance](#tool-add_scene_instance)
7. [Tool: play_scene](#tool-play_scene)
8. [Tool: stop_scene](#tool-stop_scene)
9. [Tool: save_scene](#tool-save_scene)
10. [Tool: get_loaded_scenes](#tool-get_loaded_scenes)
11. [Tool: set_main_scene](#tool-set_main_scene)
12. [Tool: get_main_scene](#tool-get_main_scene)

---

## Tool: get_scene_tree

**Tool name**: `get_scene_tree`  
**Description**: Get the node tree of the specified or currently open scene  
**Backend method**: `scene/get_tree`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `max_depth` | `z.number().int().positive()` | No | `15` | Maximum tree depth to serialize |

### Test Scenarios

#### Scenario 1: Happy path — no params (default max_depth)

**Description**: Call with no params to get tree of current open scene with default depth.  
**Params**:
```json
{}
```
**Expected result**: Returns the node tree of the currently open scene up to depth 15. Response should contain `content` array with text containing the scene tree structure (node names, types, hierarchy).  
**Notes**: Prerequisite: a scene must be open in the Godot editor. If no scene is open, expect an error.  
**Pay attention**: Verify that the tree contains correct node names and types. If the scene is empty, the tree should return with a single root node.

---

#### Scenario 2: Happy path — explicit max_depth

**Description**: Call with explicit max_depth to limit tree depth.  
**Params**:
```json
{
  "max_depth": 3
}
```
**Expected result**: Returns the node tree truncated to 3 levels of nesting. Deep nodes beyond level 3 should be omitted.  
**Notes**: Useful for large scenes. Verify that nodes at depth 4+ are absent from the result.  
**Pay attention**: Verify that the depth limit actually works — nodes deeper than 3 should not be present in the output.

---

#### Scenario 3: Edge case — max_depth = 1

**Description**: Only root node and its direct children should appear.  
**Params**:
```json
{
  "max_depth": 1
}
```
**Expected result**: Only the root node and its immediate children. No grandchildren or deeper.  
**Pay attention**: The root node and its direct children. Nested nodes should not be included.

---

#### Scenario 4: Edge case — invalid max_depth (zero)

**Description**: max_depth must be positive integer. Zero is invalid.  
**Params**:
```json
{
  "max_depth": 0
}
```
**Expected result**: Zod validation error (or Godot-side error). `z.number().int().positive()` rejects 0.  
**Pay attention**: Verify that the validation error is reported correctly and does not crash the server.

---

#### Scenario 5: Edge case — invalid max_depth (negative)

**Description**: Negative max_depth is invalid.  
**Params**:
```json
{
  "max_depth": -5
}
```
**Expected result**: Zod validation error.  
**Pay attention**: Same as zero — should return a validation error.

---

#### Scenario 6: Edge case — max_depth as float

**Description**: max_depth must be integer. Float should be rejected or coerced.  
**Params**:
```json
{
  "max_depth": 2.5
}
```
**Expected result**: Zod validation error (`z.number().int()` rejects non-integers).  
**Pay attention**: Verify that floating-point numbers are rejected.

---

## Tool: get_scene_file_content

**Tool name**: `get_scene_file_content`  
**Description**: Read the raw .tscn/.scn file content of a scene  
**Backend method**: `scene/get_file_content`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `ScenePath` (`z.string()`) | Yes | — | Scene file path (e.g. `res://scenes/main.tscn`) |

### Test Scenarios

#### Scenario 1: Happy path — valid .tscn file

**Description**: Read content of an existing .tscn scene file.  
**Params**:
```json
{
  "path": "res://scenes/main.tscn"
}
```
**Expected result**: Returns raw text content of the .tscn file. Should contain Godot scene file header (`[gd_scene]`), `[ext_resource]` sections, `[sub_resource]` sections, and `[node]` definitions.  
**Notes**: Prerequisite: the file must exist at the given path.  
**Pay attention**: Verify that the full text of the .tscn file is returned, not a structure description. The format should contain the `[gd_scene]` header.

---

#### Scenario 2: Happy path — valid .scn binary file

**Description**: Read content of a binary .scn scene file.  
**Params**:
```json
{
  "path": "res://scenes/binary_scene.scn"
}
```
**Expected result**: Returns content of the .scn file. Binary .scn may return base64-encoded or raw bytes depending on implementation.  
**Notes**: .scn is binary format — verify how the tool handles it.  
**Pay attention**: Binary .scn files may be processed differently than text .tscn files. Verify the response format.

---

#### Scenario 3: Error case — nonexistent path

**Description**: Path that doesn't exist in the project.  
**Params**:
```json
{
  "path": "res://scenes/nonexistent_scene.tscn"
}
```
**Expected result**: Error indicating file not found. Should include `isError: true` in the result.  
**Pay attention**: The error should be meaningful, not a crash. Verify the error message.

---

#### Scenario 4: Edge case — path without res:// prefix

**Description**: Path missing the `res://` prefix.  
**Params**:
```json
{
  "path": "scenes/main.tscn"
}
```
**Expected result**: Error (Godot expects `res://` prefix for project resources) or the tool normalizes the path.  
**Pay attention**: Behavior depends on implementation — it may either return an error or attempt to normalize the path.

---

#### Scenario 5: Edge case — empty string path

**Description**: Empty string as path.  
**Params**:
```json
{
  "path": ""
}
```
**Expected result**: Error — empty string is not a valid scene path.  
**Pay attention**: Verify that an empty string does not cause unexpected behavior.

---

## Tool: create_scene

**Tool name**: `create_scene`  
**Description**: Create a new empty scene with a specified root node type  
**Backend method**: `scene/create`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `ScenePath` (`z.string()`) | Yes | — | Path to save the scene (e.g. `res://scenes/new.tscn`) |
| `root_node_type` | `z.string()` | No | (Godot default, likely `Node`) | Root node type (e.g. `Node2D`, `Control`) |

### Test Scenarios

#### Scenario 1: Happy path — create scene with explicit root type

**Description**: Create a new scene with a specific root node type.  
**Params**:
```json
{
  "path": "res://scenes/test_scene.tscn",
  "root_node_type": "Node2D"
}
```
**Expected result**: Scene is created at the given path. File `res://scenes/test_scene.tscn` now exists on disk. The scene opens in the editor with a `Node2D` root.  
**Notes**: This is a mutating tool — it creates a file. The created scene should be opened in the editor after creation.  
**Pay attention**: Verify that the file is created on disk, the scene is open in the editor, and the root node has type Node2D. After the test — delete the created file.

---

#### Scenario 2: Happy path — create scene with default root type

**Description**: Create scene without specifying root node type (use Godot default).  
**Params**:
```json
{
  "path": "res://scenes/test_default_root.tscn"
}
```
**Expected result**: Scene is created with the default root node type (likely `Node`).  
**Pay attention**: Verify which node type is used by default. It should be `Node` per Godot conventions.

---

#### Scenario 3: Happy path — create scene with Control root

**Description**: Create a UI scene with `Control` as root.  
**Params**:
```json
{
  "path": "res://scenes/ui_test.tscn",
  "root_node_type": "Control"
}
```
**Expected result**: Scene created with `Control` root node.  
**Pay attention**: Verify that the Control scene is created correctly and can be used for UI.

---

#### Scenario 4: Error case — path to existing file (overwrite)

**Description**: Create scene at path that already exists.  
**Params**:
```json
{
  "path": "res://scenes/main.tscn",
  "root_node_type": "Node2D"
}
```
**Expected result**: Either overwrites the existing scene (with or without warning) or returns an error about file already existing. Behavior depends on implementation.  
**Pay attention**: It's important to determine whether the tool overwrites the existing file. If so — this can be dangerous. If not — there should be a clear error.

---

#### Scenario 5: Edge case — invalid root node type

**Description**: Non-existent node type.  
**Params**:
```json
{
  "path": "res://scenes/test_invalid.tscn",
  "root_node_type": "NonExistentNodeType123"
}
```
**Expected result**: Error from Godot indicating unknown node type.  
**Pay attention**: The error should be meaningful. Godot should return information about the unknown node type.

---

#### Scenario 6: Edge case — path with spaces

**Description**: Path containing spaces.  
**Params**:
```json
{
  "path": "res://scenes/my test scene.tscn",
  "root_node_type": "Node"
}
```
**Expected result**: Scene is created successfully. Godot handles spaces in filenames.  
**Pay attention**: Verify that spaces in the filename don't break the path. The file should be created correctly.

---

### Related Tools

- **Before**: Call `get_scene_file_content` after creation to verify file content.
- **After**: Call `open_scene` to open the created scene, `get_scene_tree` to inspect its structure, `delete_scene` to clean up after test.

---

## Tool: open_scene

**Tool name**: `open_scene`  
**Description**: Open a scene file in the editor  
**Backend method**: `scene/open`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `ScenePath` (`z.string()`) | Yes | — | Scene file path to open |

### Test Scenarios

#### Scenario 1: Happy path — open existing scene

**Description**: Open an existing scene file in the Godot editor.  
**Params**:
```json
{
  "path": "res://scenes/main.tscn"
}
```
**Expected result**: Scene is opened in the editor. Subsequent calls to `get_scene_tree` will return this scene's tree.  
**Notes**: Prerequisite: the scene file must exist.  
**Pay attention**: Verify that the scene actually opens in the editor. After calling `get_scene_tree`, it should return this scene's structure.

---

#### Scenario 2: Error case — nonexistent scene

**Description**: Try to open a scene that doesn't exist.  
**Params**:
```json
{
  "path": "res://scenes/nonexistent.tscn"
}
```
**Expected result**: Error indicating file not found.  
**Pay attention**: The error should be informative.

---

#### Scenario 3: Open scene created by create_scene

**Description**: Open a scene that was just created.  
**Params**:
```json
{
  "path": "res://scenes/test_scene.tscn"
}
```
**Expected result**: Scene opens in editor. This tests the create→open workflow.  
**Notes**: Requires `create_scene` to have been called first with this path.  
**Pay attention**: Integration test — first `create_scene`, then `open_scene`, then `get_scene_tree`.

---

### Related Tools

- **Before**: `create_scene` (if scene doesn't exist yet)
- **After**: `get_scene_tree` (to verify the opened scene), `save_scene` (if modifications were made)

---

## Tool: delete_scene

**Tool name**: `delete_scene`  
**Description**: Delete a scene file from the project  
**Backend method**: `scene/delete`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `ScenePath` (`z.string()`) | Yes | — | Scene file path to delete |
| `force` | `z.boolean()` | No | (false) | Force close and delete if scene is currently open |

### Test Scenarios

#### Scenario 1: Happy path — delete closed scene

**Description**: Delete a scene that is not currently open in the editor.  
**Params**:
```json
{
  "path": "res://scenes/test_scene.tscn"
}
```
**Expected result**: Scene file is deleted from disk. Call to `get_scene_file_content` with same path should now fail.  
**Notes**: Prerequisite: scene must exist but not be open. Use `create_scene` first, then open a different scene, then delete.  
**Pay attention**: Verify that the file is actually deleted from disk. A read attempt should return an error.

---

#### Scenario 2: Happy path — delete with force=true (open scene)

**Description**: Delete a scene that is currently open in the editor, using force flag.  
**Params**:
```json
{
  "path": "res://scenes/test_force_delete.tscn",
  "force": true
}
```
**Expected result**: Scene is force-closed and deleted even though it's open.  
**Notes**: Requires the scene to be currently open. Use `create_scene` → `open_scene` → `delete_scene(force=true)`.  
**Pay attention**: Verify that `force: true` correctly closes the open scene and deletes the file. Without `force`, it should return an error.

---

#### Scenario 3: Error case — delete currently open scene without force

**Description**: Try to delete a scene that's currently open without force flag.  
**Params**:
```json
{
  "path": "res://scenes/main.tscn"
}
```
**Expected result**: Error indicating the scene is currently open and cannot be deleted without `force: true`.  
**Notes**: Prerequisite: the scene must be open in the editor.  
**Pay attention**: Verify that without `force`, the tool does NOT delete the open scene and returns an error instead.

---

#### Scenario 4: Error case — delete nonexistent scene

**Description**: Try to delete a scene that doesn't exist.  
**Params**:
```json
{
  "path": "res://scenes/nonexistent.tscn"
}
```
**Expected result**: Error indicating file not found.  
**Pay attention**: The error should be meaningful.

---

### Related Tools

- **Before**: `create_scene` (to create a scene to delete), `open_scene` (for testing force-delete of open scene)
- **After**: `get_scene_file_content` (to verify deletion — should return error)

---

## Tool: add_scene_instance

**Tool name**: `add_scene_instance`  
**Description**: Add an instance of a scene as a child of a node in the current scene  
**Backend method**: `scene/add_instance`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `scene_path` | `ScenePath` (`z.string()`) | Yes | — | Path to the scene to instantiate |
| `parent_path` | `z.string()` | No | (scene root) | Parent node path, defaults to scene root |

### Test Scenarios

#### Scenario 1: Happy path — instance as child of root

**Description**: Instantiate a scene and add it as child of the current scene's root.  
**Params**:
```json
{
  "scene_path": "res://scenes/player.tscn"
}
```
**Expected result**: An instance of `player.tscn` is added as a child of the root node of the currently open scene. `get_scene_tree` should now show this new child.  
**Notes**: Prerequisites: (1) a scene must be open, (2) `res://scenes/player.tscn` must exist.  
**Pay attention**: Verify via `get_scene_tree` that the instance was added to the tree. The instance name should match the root node of the instantiated scene.

---

#### Scenario 2: Happy path — instance as child of specific node

**Description**: Instantiate a scene and add it as child of a specific node.  
**Params**:
```json
{
  "scene_path": "res://scenes/enemy.tscn",
  "parent_path": "Enemies"
}
```
**Expected result**: Instance is added as child of the `Enemies` node in the current scene.  
**Notes**: Prerequisites: current scene must have a node named `Enemies`. Use `node.ts:add_node` to create it first if needed.  
**Pay attention**: Verify that the instance appeared under the `Enemies` node, not under the root.

---

#### Scenario 3: Error case — nonexistent scene path

**Description**: Try to instantiate a scene that doesn't exist.  
**Params**:
```json
{
  "scene_path": "res://scenes/nonexistent.tscn"
}
```
**Expected result**: Error indicating scene file not found.  
**Pay attention**: The error should clearly indicate that the scene file was not found.

---

#### Scenario 4: Error case — nonexistent parent node

**Description**: Try to add instance under a node that doesn't exist.  
**Params**:
```json
{
  "scene_path": "res://scenes/player.tscn",
  "parent_path": "NonExistentParent"
}
```
**Expected result**: Error indicating parent node not found in the current scene.  
**Pay attention**: Verify that the error indicates the parent node is missing.

---

### Related Tools

- **Before**: `open_scene` (to open the scene that will receive the instance), `node.ts:add_node` (to create parent node if needed), `create_scene` (to create the scene to be instantiated)
- **After**: `get_scene_tree` (to verify instance was added), `save_scene` (to persist changes)

---

## Tool: play_scene

**Tool name**: `play_scene`  
**Description**: Start playing the current or specified scene. Required before using any runtime tools (get_game_*, capture_frames, etc.)  
**Backend method**: `scene/play`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `mode` | `z.enum(['main', 'current', 'custom'])` | No | — | Play mode: `'main'` (main scene), `'current'` (open scene), or `'custom'` (specified by scene_path) |
| `scene_path` | `z.string()` | No | — | Scene to play when mode is `'custom'` |

### Test Scenarios

#### Scenario 1: Happy path — play main scene (mode='main')

**Description**: Play the project's main scene.  
**Params**:
```json
{
  "mode": "main"
}
```
**Expected result**: The main scene starts playing in the Godot editor. Runtime tools become available.  
**Notes**: Prerequisite: a main scene must be set in the project.  
**Pay attention**: Verify that the game started (e.g., via `get_loaded_scenes` or runtime tools).

---

#### Scenario 2: Happy path — play current scene (mode='current')

**Description**: Play the scene currently open in the editor.  
**Params**:
```json
{
  "mode": "current"
}
```
**Expected result**: The currently open scene starts playing.  
**Notes**: Prerequisite: a scene must be open in the editor.  
**Pay attention**: Verify that the currently open scene is the one being launched.

---

#### Scenario 3: Happy path — play custom scene (mode='custom')

**Description**: Play a specific scene by path.  
**Params**:
```json
{
  "mode": "custom",
  "scene_path": "res://scenes/test_play.tscn"
}
```
**Expected result**: The specified scene starts playing.  
**Notes**: Prerequisite: the scene file must exist.  
**Pay attention**: Verify that `scene_path` is ignored if `mode` is not `'custom'`.

---

#### Scenario 4: Happy path — no params (default)

**Description**: Call with no params — should use default behavior.  
**Params**:
```json
{}
```
**Expected result**: Default behavior — likely plays the current scene or main scene.  
**Pay attention**: Determine what the default behavior is. Documentation says parameters are optional.

---

#### Scenario 5: Error case — custom mode without scene_path

**Description**: Play in custom mode but forget to specify scene_path.  
**Params**:
```json
{
  "mode": "custom"
}
```
**Expected result**: Error — `scene_path` is required when `mode` is `'custom'`.  
**Pay attention**: Verify that the tool doesn't crash but returns a clear error.

---

#### Scenario 6: Error case — invalid mode value

**Description**: Pass an invalid mode enum value.  
**Params**:
```json
{
  "mode": "fast"
}
```
**Expected result**: Zod validation error — `'fast'` is not in `['main', 'current', 'custom']`.  
**Pay attention**: Verify that Zod rejects invalid enum values.

---

#### Scenario 7: Error case — nonexistent custom scene

**Description**: Play in custom mode with nonexistent scene path.  
**Params**:
```json
{
  "mode": "custom",
  "scene_path": "res://scenes/nonexistent.tscn"
}
```
**Expected result**: Error indicating scene not found.  
**Pay attention**: The error should come from Godot, not be a crash.

---

### Related Tools

- **Before**: `set_main_scene` (to set main scene for mode='main'), `open_scene` (to open scene for mode='current'), `create_scene` (to create scene for mode='custom')
- **After**: `stop_scene` (to stop the game after testing), runtime tools (`get_game_*`, `capture_frames`, etc.) become available after play

---

## Tool: stop_scene

**Tool name**: `stop_scene`  
**Description**: Stop the currently playing scene  
**Backend method**: `scene/stop`

### Parameters

None (empty schema).

### Test Scenarios

#### Scenario 1: Happy path — stop playing scene

**Description**: Stop a currently running scene.  
**Params**:
```json
{}
```
**Expected result**: The scene stops playing. The editor returns to the editing state.  
**Notes**: Prerequisite: a scene must be currently playing (call `play_scene` first).  
**Pay attention**: Verify that the game is stopped. After the call, runtime tools should stop working or return an error.

---

#### Scenario 2: Error case — stop when nothing is playing

**Description**: Stop when no scene is currently playing.  
**Params**:
```json
{}
```
**Expected result**: Either a no-op (success with informational message) or an error indicating no scene is playing.  
**Pay attention**: Understand the behavior — whether this is an error or an acceptable state.

---

### Related Tools

- **Before**: `play_scene` (required — must have something playing to stop)
- **After**: `get_loaded_scenes` (to verify state after stopping)

---

## Tool: save_scene

**Tool name**: `save_scene`  
**Description**: Save the current scene or save it to a new path  
**Backend method**: `scene/save`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `z.string()` | No | (current scene) | Path of the scene to save (defaults to current) |

### Test Scenarios

#### Scenario 1: Happy path — save current scene

**Description**: Save the currently open scene.  
**Params**:
```json
{}
```
**Expected result**: The current scene is saved to its existing file path. All modifications are persisted.  
**Notes**: Prerequisite: a scene must be open with unsaved changes.  
**Pay attention**: Verify that changes are saved — re-read the file via `get_scene_file_content` and confirm the changes are present.

---

#### Scenario 2: Happy path — save to new path (save as)

**Description**: Save the current scene to a different path.  
**Params**:
```json
{
  "path": "res://scenes/saved_copy.tscn"
}
```
**Expected result**: The scene is saved to the new path. A new file is created at `res://scenes/saved_copy.tscn`.  
**Pay attention**: Verify that the new file is created and contains the correct content. The original file may remain unchanged or be updated — depends on implementation.

---

#### Scenario 3: Edge case — save nonexistent scene

**Description**: Try to save a scene that doesn't exist / isn't open.  
**Params**:
```json
{
  "path": "res://scenes/nonexistent.tscn"
}
```
**Expected result**: Error — cannot save a scene that isn't loaded.  
**Pay attention**: The error should be informative.

---

### Related Tools

- **Before**: `open_scene` or `create_scene` (to have a scene to save), `node.ts:add_node` (to make modifications before saving)
- **After**: `get_scene_file_content` (to verify saved content), `delete_scene` (cleanup)

---

## Tool: get_loaded_scenes

**Tool name**: `get_loaded_scenes`  
**Description**: Get a list of all currently loaded scenes in the editor  
**Backend method**: `scene/get_loaded`

### Parameters

None (empty schema).

### Test Scenarios

#### Scenario 1: Happy path — get loaded scenes

**Description**: List all scenes currently loaded in the editor.  
**Params**:
```json
{}
```
**Expected result**: Returns a list of loaded scene paths. If multiple scenes are open (tabs), all should appear.  
**Notes**: No prerequisites — this is a read-only query.  
**Pay attention**: The result should contain scene paths in `res://` format. If no scene is open — it should return an empty list or null.

---

#### Scenario 2: Verify after open_scene

**Description**: Get loaded scenes after opening a specific scene to verify it appears.  
**Params**:
```json
{}
```
**Expected result**: The path of the recently opened scene appears in the list.  
**Notes**: Call `open_scene` with a specific path first, then call this tool to verify.  
**Pay attention**: Verify that the recently opened scene is present in the list.

---

#### Scenario 3: Verify after delete_scene

**Description**: Get loaded scenes after deleting a scene to verify it's removed.  
**Params**:
```json
{}
```
**Expected result**: The deleted scene should no longer appear in the list (if it was force-closed).  
**Notes**: Call `delete_scene` with `force: true` first.  
**Pay attention**: Verify that the deleted scene has disappeared from the list.

---

### Related Tools

- **Before**: `open_scene` (to have scenes to list), `create_scene` (to add scenes)
- **After**: `open_scene`, `delete_scene` (to act on the listed scenes)

---

## Tool: set_main_scene

**Tool name**: `set_main_scene`  
**Description**: Set the project's main scene  
**Backend method**: `scene/set_main`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `ScenePath` (`z.string()`) | Yes | — | Scene file path to set as main scene |

### Test Scenarios

#### Scenario 1: Happy path — set existing scene as main

**Description**: Set an existing scene as the project's main scene.  
**Params**:
```json
{
  "path": "res://scenes/main.tscn"
}
```
**Expected result**: The specified scene becomes the project's main scene. Call `get_main_scene` to verify.  
**Notes**: Prerequisite: the scene file must exist.  
**Pay attention**: Verify via `get_main_scene` that the path has changed. Also verify that `project.godot` has been updated (run/run_main_scene).

---

#### Scenario 2: Error case — nonexistent scene

**Description**: Try to set a nonexistent scene as main.  
**Params**:
```json
{
  "path": "res://scenes/nonexistent.tscn"
}
```
**Expected result**: Error indicating scene file not found or not valid.  
**Pay attention**: Godot may either reject the request or set the path (even if the file doesn't exist). Verify the behavior.

---

#### Scenario 3: Edge case — set scene from subdirectory

**Description**: Set a scene from a nested directory as main.  
**Params**:
```json
{
  "path": "res://scenes/levels/level1.tscn"
}
```
**Expected result**: Scene from subdirectory becomes the main scene.  
**Pay attention**: Verify that paths with subdirectories are handled correctly.

---

### Related Tools

- **Before**: `create_scene` (to create the scene first), `get_main_scene` (to check current main scene)
- **After**: `get_main_scene` (to verify the change), `play_scene` with `mode: 'main'` (to test the main scene plays)

---

## Tool: get_main_scene

**Tool name**: `get_main_scene`  
**Description**: Get the project main scene path  
**Backend method**: `scene/get_main`

### Parameters

None (empty schema, note: `callGodot` is called with empty `{}`).

### Test Scenarios

#### Scenario 1: Happy path — get current main scene

**Description**: Get the current project's main scene path.  
**Params**:
```json
{}
```
**Expected result**: Returns the `res://` path of the project's main scene, or null/empty if no main scene is set.  
**Notes**: No prerequisites — read-only query.  
**Pay attention**: The path should be in `res://` format. If no main scene is set — check what is returned (null, empty string, or error).

---

#### Scenario 2: Verify after set_main_scene

**Description**: Get main scene after setting a new one to verify the change.  
**Params**:
```json
{}
```
**Expected result**: Returns the path that was just set via `set_main_scene`.  
**Notes**: Call `set_main_scene` first with a known path.  
**Pay attention**: Should exactly match the path passed to `set_main_scene`.

---

### Related Tools

- **Before**: `set_main_scene` (to change the main scene before querying)
- **After**: `play_scene` with `mode: 'main'` (to play the main scene)

---

## Integration Test Sequences

### Sequence 1: Full scene lifecycle

**Description**: Create, open, modify, save, and delete a scene.

**Steps**:
1. `create_scene` → `{ "path": "res://scenes/lifecycle_test.tscn", "root_node_type": "Node2D" }`
2. `open_scene` → `{ "path": "res://scenes/lifecycle_test.tscn" }`
3. `get_scene_tree` → `{}` — verify Node2D root
4. `save_scene` → `{}` — save current state
5. `get_scene_file_content` → `{ "path": "res://scenes/lifecycle_test.tscn" }` — verify file content
6. `delete_scene` → `{ "path": "res://scenes/lifecycle_test.tscn" }` — cleanup

**Expected**: All steps succeed. The scene is created, opened, verified, saved, and cleaned up.

---

### Sequence 2: Scene instantiation workflow

**Description**: Create a parent scene and a child scene, then instantiate the child into the parent.

**Steps**:
1. `create_scene` → `{ "path": "res://scenes/parent_test.tscn", "root_node_type": "Node2D" }`
2. `create_scene` → `{ "path": "res://scenes/child_test.tscn", "root_node_type": "Sprite2D" }`
3. `open_scene` → `{ "path": "res://scenes/parent_test.tscn" }`
4. `add_scene_instance` → `{ "scene_path": "res://scenes/child_test.tscn" }`
5. `get_scene_tree` → `{}` — verify child instance appears
6. `save_scene` → `{}`
7. `delete_scene` → `{ "path": "res://scenes/parent_test.tscn" }`
8. `delete_scene` → `{ "path": "res://scenes/child_test.tscn" }`

**Expected**: Child scene is instantiated under the parent scene's root.

---

### Sequence 3: Play/stop cycle

**Description**: Play a scene in different modes and stop it.

**Steps**:
1. `create_scene` → `{ "path": "res://scenes/play_test.tscn", "root_node_type": "Node" }`
2. `set_main_scene` → `{ "path": "res://scenes/play_test.tscn" }`
3. `play_scene` → `{ "mode": "main" }` — play main scene
4. `stop_scene` → `{}`
5. `open_scene` → `{ "path": "res://scenes/play_test.tscn" }`
6. `play_scene` → `{ "mode": "current" }` — play current scene
7. `stop_scene` → `{}`
8. `play_scene` → `{ "mode": "custom", "scene_path": "res://scenes/play_test.tscn" }` — play custom scene
9. `stop_scene` → `{}`
10. Cleanup: restore original main scene, delete test scene

**Expected**: All three play modes work. Each stop successfully ends the game.

---

### Sequence 4: Main scene management

**Description**: Get, set, and verify main scene.

**Steps**:
1. `get_main_scene` → `{}` — record current main scene
2. `create_scene` → `{ "path": "res://scenes/new_main_test.tscn", "root_node_type": "Node" }`
3. `set_main_scene` → `{ "path": "res://scenes/new_main_test.tscn" }`
4. `get_main_scene` → `{}` — verify it changed to new_main_test.tscn
5. `set_main_scene` → `{ "path": "<original_main_scene>" }` — restore original
6. `delete_scene` → `{ "path": "res://scenes/new_main_test.tscn" }`

**Expected**: Main scene is correctly updated and restored.

---

### Sequence 5: Multiple scenes loaded

**Description**: Open multiple scenes and verify get_loaded_scenes lists all.

**Steps**:
1. `create_scene` → `{ "path": "res://scenes/multi_1.tscn", "root_node_type": "Node" }`
2. `create_scene` → `{ "path": "res://scenes/multi_2.tscn", "root_node_type": "Node2D" }`
3. `create_scene` → `{ "path": "res://scenes/multi_3.tscn", "root_node_type": "Control" }`
4. `open_scene` → `{ "path": "res://scenes/multi_1.tscn" }`
5. `open_scene` → `{ "path": "res://scenes/multi_2.tscn" }`
6. `open_scene` → `{ "path": "res://scenes/multi_3.tscn" }`
7. `get_loaded_scenes` → `{}` — should list all three
8. Cleanup: delete all three scenes

**Expected**: All three scenes appear in the loaded scenes list.

---

## Notes for Test Executor

### Prerequisites for all tests

1. **Godot editor must be running** with the MCP plugin active and connected.
2. **A valid Godot project** must be open with a scenes directory.
3. **MCP server must be running** and connected to the Godot plugin.

### Cleanup discipline

- Every test that creates files must clean up after itself.
- Use `delete_scene` with `force: true` to clean up scenes that might still be open.
- Restore the original main scene if `set_main_scene` was used.

### Error handling verification

- For every error case, verify:
  1. The result has `isError: true` (or equivalent error indicator).
  2. The error message is descriptive (not a generic "tool failed").
  3. The Godot editor remains stable (no crash, no corrupted state).

### Parameter validation

- Zod schema validation happens at the MCP server level before the request reaches Godot.
- Invalid types (e.g., string where number expected) should fail at validation, not reach Godot.
- Godot-level errors (file not found, invalid node type) come back as tool results with error content.

### Cross-tool dependency graph

```
create_scene ──→ open_scene ──→ get_scene_tree
     │               │
     │               ├──→ add_scene_instance ──→ save_scene
     │               │
     │               └──→ play_scene ──→ stop_scene
     │
     └──→ delete_scene
     
get_main_scene ←──→ set_main_scene
     
get_loaded_scenes (read-only, no dependencies)

get_scene_file_content (read-only, needs existing file)
```