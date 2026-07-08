# Prerequisites for scene_test_plan.md

## Required Project State

- Godot 4.x editor is running with the `godot_mcp` plugin active and connected to the MCP server
- A project is open (3D project recommended; most test scenes use `Node3D` roots)
- The directory `res://scenes/` exists (must be present or auto-created for `create_scene` tests)
- The directory `res://scripts/` exists (must contain at least `player.gd`)
- **No play mode required** for get_scene_tree, get_scene_file_content, create_scene, open_scene, delete_scene, add_scene_instance, save_scene, get_loaded_scenes, set_main_scene, get_main_scene
- **Play mode required** for play_scene, stop_scene (these start/stop runtime)

## Required Scenes

### Scene 1: Deeply nested scene (`res://scenes/deep_nest.tscn`)

**Purpose:** Tests `get_scene_tree` depth truncation at default (15), explicit (5, 1), and large (9999) values.

**Hierarchy (17 levels, each level is a `Node3D` child of the previous):**

```
DepthRoot (Node3D)
└── Level1 (Node3D)
    └── Level2 (Node3D)
        └── Level3 (Node3D)
            └── Level4 (Node3D)
                └── Level5 (Node3D)
                    └── Level6 (Node3D)
                        └── Level7 (Node3D)
                            └── Level8 (Node3D)
                                └── Level9 (Node3D)
                                    └── Level10 (Node3D)
                                        └── Level11 (Node3D)
                                            └── Level12 (Node3D)
                                                └── Level13 (Node3D)
                                                    └── Level14 (Node3D)
                                                        └── Level15 (Node3D)
                                                            └── Level16 (Node3D)
                                                                └── Level17 (Node3D)
```

| Node Path | Type | Name | Notes |
|-----------|------|------|-------|
| (root) | `Node3D` | `DepthRoot` | — |
| `DepthRoot` → child | `Node3D` | `Level1` | — |
| `Level1` → child | `Node3D` | `Level2` | — |
| `Level2` → child | `Node3D` | `Level3` | — |
| ... | `Node3D` | `Level4` through `Level17` | Each is child of the previous |
| `Level16` → child | `Node3D` | `Level17` | Deepest node; visible only at full depth |

**Why 17 levels:** Default `max_depth` is 15. `max_depth=5` tests shallow truncation. `max_depth=1` tests root-only. `max_depth=9999` tests full tree. 17 levels ensures `Level16` and `Level17` are beyond default depth.

---

### Scene 2: Main scene (`res://scenes/main.tscn`)

**Purpose:** Used by `get_scene_file_content` (S1), `open_scene` (S1), `create_scene` (S9 — overwrite test), `play_scene` (S1 — mode='main'), `set_main_scene` (S1), `get_main_scene` (S1).

```
Main (Node3D)
```

| Node Path | Type | Name | Notes |
|-----------|------|------|-------|
| (root) | `Node3D` | `Main` | Minimal scene — no child nodes required |

**Project setting:** This scene must be configured as the project's main scene (via `godot_set_main_scene` or Project Settings) for `play_scene` mode='main' and `get_main_scene` tests. If tests modify the main scene setting, the original value must be restored after the test run.

---

### Scene 3: Parent/instance host scene (`res://scenes/parent_instance.tscn`)

**Purpose:** Tests `add_scene_instance` with various parent paths — root (empty), named node ("Container"), and nested path ("UI/Panel/Container").

```
ParentRoot (Node3D)
├── Container (Node3D)
└── UI (Control)
    └── Panel (Panel)
        └── Container (Node3D)
```

| Node Path | Type | Name | Notes |
|-----------|------|------|-------|
| (root) | `Node3D` | `ParentRoot` | — |
| `ParentRoot/Container` | `Node3D` | `Container` | Used by `add_scene_instance` S2 (named parent) |
| `ParentRoot/UI` | `Control` | `UI` | Intermediate nesting |
| `ParentRoot/UI/Panel` | `Panel` | `Panel` | Intermediate nesting |
| `ParentRoot/UI/Panel/Container` | `Node3D` | `Container` | Used by `add_scene_instance` S3 (deeply nested parent) |

---

### Scene 4: Child scene for instancing (`res://scenes/child.tscn`)

**Purpose:** Used as the `scene_path` argument in all `add_scene_instance` tests. Must be a valid, self-contained scene that can be safely instanced.

```
ChildRoot (Node3D)
```

| Node Path | Type | Name | Notes |
|-----------|------|------|-------|
| (root) | `Node3D` | `ChildRoot` | Minimal scene — any root type works |

---

### Scene 5: Currently-open deletion target (`res://scenes/currently_open.tscn`)

**Purpose:** Used by `delete_scene` S6 (delete without force should fail) and S7 (delete with force=true should succeed).

```
CurrentlyOpenRoot (Node3D)
```

| Node Path | Type | Name | Notes |
|-----------|------|------|-------|
| (root) | `Node3D` | `CurrentlyOpenRoot` | Must be OPEN in the editor when `delete_scene` S6 and S7 are run |

**Precondition:** Before running `delete_scene` S6, this scene must be the active scene. The test opens it, then attempts to delete it without `force`, expecting an error. S7 retries with `force=true`.

---

### Scene 6: Test level scene (`res://scenes/test_level.tscn`)

**Purpose:** Used by `play_scene` S3 (mode='custom' with explicit scene_path).

```
TestLevel (Node3D)
```

| Node Path | Type | Name | Notes |
|-----------|------|------|-------|
| (root) | `Node3D` | `TestLevel` | Minimal scene — any root type works |

---

### Scene 7: Save-as overwrite target (`res://scenes/existing.tscn`)

**Purpose:** Used by `save_scene` S3 (Save As over an existing file to test overwrite behavior).

```
Existing (Node3D)
```

| Node Path | Type | Name | Notes |
|-----------|------|------|-------|
| (root) | `Node3D` | `Existing` | Must exist on disk before the test runs |

---

### Scene 8-10: Delete temp scenes (created dynamically, then deleted)

**Purpose:** Used by `delete_scene` S1, S2, S3 (happy path deletion tests). These are temporary files that exist only to be deleted.

| Scene Path | Root Node | Name | Notes |
|------------|-----------|------|-------|
| `res://scenes/to_delete.tscn` | `Node3D` | `ToDelete1` | Created before S1, deleted by S1 |
| `res://scenes/to_delete2.tscn` | `Node3D` | `ToDelete2` | Created before S2, deleted by S2 with `force=true` |
| `res://scenes/to_delete3.tscn` | `Node3D` | `ToDelete3` | Created before S3, deleted by S3 with `force=false` |

These can be created at test time via `godot_create_scene`. They do NOT need to exist before the test suite starts, but each must exist on disk before its corresponding `delete_scene` test runs.

---

### Scene 11: Self-reference scene for cyclic test (`res://scenes/current.tscn`)

**Purpose:** Used by `add_scene_instance` S8 (self-reference / cyclic instantiation error test). Must be OPEN in the editor so that its own `scene_path` matches.

```
CurrentRoot (Node3D)
```

| Node Path | Type | Name | Notes |
|-----------|------|------|-------|
| (root) | `Node3D` | `CurrentRoot` | Must be the currently open scene when S8 runs |

---

## Required Resources

### GDScript file

| Resource | Path | Required For | Notes |
|----------|------|-------------|-------|
| GDScript | `res://scripts/player.gd` | `get_scene_file_content` S8, `open_scene` S5, `add_scene_instance` S9, `set_main_scene` S4 | A basic GDScript file. Content is irrelevant — only its existence as a non-scene file matters. Minimal content: `extends Node` or any valid class. |

**Minimal `player.gd` content:**
```gdscript
extends Node
```

### Binary scene file (optional)

| Resource | Path | Required For | Notes |
|----------|------|-------------|-------|
| Binary scene | `res://scenes/legacy.scn` | `get_scene_file_content` S9 | Test says "Verify the tool can handle binary .scn files." If this file cannot be created, the test is skipped or adjusted to test that a missing .scn file returns an appropriate error. Creating a binary .scn requires saving a scene with `ResourceSaver` in binary mode. |

---

## Required Editor/Game State

### For get_scene_tree tests (S1-S8)
- **Play mode:** OFF
- **Active scene:** `res://scenes/deep_nest.tscn` open in the editor
- **Editor selection:** Any (not relevant)

### For get_scene_tree S9 (no scene open)
- **Active scene:** No scene open in the editor. May require closing all open scenes first.

### For get_scene_file_content tests (S1-S9)
- **Active scene:** Any (reads files from disk, does not depend on editor state)
- **File system:** All referenced files (`main.tscn`, `player.gd`, `legacy.scn`) must exist on disk

### For create_scene tests (S1-S11)
- **Active scene:** Any (creates new scenes without affecting current)
- **File system:** `res://scenes/` directory must exist. `res://scenes/main.tscn` must exist for S9 (overwrite test).

### For open_scene tests (S1-S6)
- **Active scene:** Any (the tool changes which scene is open)
- **File system:** `res://scenes/main.tscn` and `res://scripts/player.gd` must exist

### For delete_scene tests (S1-S8)
- **Active scene (S1-S5, S8):** Any (target scenes are not open)
- **Active scene (S6-S7):** `res://scenes/currently_open.tscn` must be the open scene
- **File system:** All temp deletion scenes must exist before their respective tests

### For add_scene_instance tests (S1-S9)
- **Active scene:** `res://scenes/parent_instance.tscn` (S1-S4, S7, S9) or `res://scenes/current.tscn` (S8)
- **File system:** `res://scenes/child.tscn` must exist for S1-S4, S7-S9

### For play_scene tests (S1-S10)
- **Play mode before tests:** OFF
- **Play mode after S1, S3, S9:** ON (scene running); must call `stop_scene` between tests
- **Project setting:** Main scene must be set to `res://scenes/main.tscn` for S1
- **Play mode between S9 and S10:** S9 tests "play when already playing", so scene must still be running. S10 tests "play with no main scene", so main scene must be unset first then `stop_scene` must be called.

### For stop_scene tests (S1-S2)
- **Play mode before S1:** ON (scene must be running — achieved by calling `play_scene` first)
- **Play mode before S2:** OFF (tests graceful no-op)

### For save_scene tests (S1-S6)
- **Active scene (S1-S5):** A scene must be open in the editor (any scene with a known path)
- **Active scene (S6):** No scene open
- **File system:** `res://scenes/existing.tscn` must exist for S3

### For get_loaded_scenes tests (S1-S3)
- **Active scene (S1):** One scene open in the editor
- **Active scene (S2):** Multiple scenes loaded additively (requires at least 2 scenes loaded simultaneously)
- **Active scene (S3):** No scenes loaded

### For set_main_scene tests (S1-S5)
- **Active scene:** Any
- **Project setting:** The main scene must be known before S1 runs so it can be restored after. `res://scenes/main.tscn` must exist for S1.

### For get_main_scene tests (S1-S2)
- **Active scene:** Any
- **Project setting (S1):** A main scene must be configured
- **Project setting (S2):** No main scene configured (may need to clear it before this test)

---

## Required Settings/Config

### Project settings
- **Main scene:** Must be set to `res://scenes/main.tscn` initially for `play_scene` S1 and `get_main_scene` S1. This will be changed during `set_main_scene` tests and must be restored after.
- **No other specific project settings** are required. All tools operate with default values.

### Input actions
- **No custom input actions** required. Scene tools do not interact with input.

### Autoloads
- **No custom autoloads** required beyond the standard `mcp_runtime` autoload that the MCP plugin registers automatically.

### Collision layers
- **No collision layers** required.

### Groups
- **No groups** required. Scene tools do not operate on groups.

---

## Test Order Dependencies

Some scenarios depend on prior test execution or state changes:

| Tool | Scenario | Depends On |
|------|----------|------------|
| `get_scene_tree` | S1-S8 | `res://scenes/deep_nest.tscn` must be the open scene |
| `get_scene_tree` | S9 | All scenes must be closed (run after all other `get_scene_tree` tests or in isolation) |
| `get_scene_file_content` | S1 | `res://scenes/main.tscn` must exist on disk |
| `get_scene_file_content` | S9 | `res://scenes/legacy.scn` should exist on disk (optional) |
| `create_scene` | S9 | `res://scenes/main.tscn` must already exist on disk |
| `open_scene` | S1 | `res://scenes/main.tscn` must exist on disk |
| `delete_scene` | S1-S3 | Respective temp scene files must be created before each test |
| `delete_scene` | S6 | `res://scenes/currently_open.tscn` must be open in editor |
| `delete_scene` | S7 | `res://scenes/currently_open.tscn` must be open in editor (recreate after S6 if S6 deleted it) |
| `add_scene_instance` | S1-S4, S7-S9 | `res://scenes/child.tscn` must exist |
| `add_scene_instance` | S1-S4, S7, S9 | `res://scenes/parent_instance.tscn` must be the open scene |
| `add_scene_instance` | S8 | `res://scenes/current.tscn` must be the open scene |
| `play_scene` | S1 | Main scene must be set (e.g., to `res://scenes/main.tscn`) |
| `play_scene` | S3 | `res://scenes/test_level.tscn` must exist |
| `play_scene` | S9 | A scene must already be running (achieved by running `play_scene` first without stopping) |
| `play_scene` | S10 | Main scene must NOT be set |
| `stop_scene` | S1 | A scene must be running (call `play_scene` first) |
| `save_scene` | S1-S3 | A scene must be open in the editor |
| `save_scene` | S3 | `res://scenes/existing.tscn` must exist on disk |
| `save_scene` | S6 | No scene must be open |
| `get_loaded_scenes` | S2 | Multiple scenes loaded additively |
| `set_main_scene` | S1 | `res://scenes/main.tscn` must exist; previous main scene must be saved and restored after |
| `get_main_scene` | S1 | A main scene must be configured |
| `get_main_scene` | S2 | No main scene configured (clear it before this test) |
| Cross-tool: Create → Play → Stop → Delete | All steps | Each step depends on the previous one completing successfully |

---

## Setup Script

This GDScript can be executed via `godot_execute_editor_script` to create all prerequisite scenes from scratch. **Run this BEFORE any scene tests.**

```gdscript
@tool
extends EditorScript

func _run() -> void:
    # Ensure directories exist
    DirAccess.make_dir_recursive_absolute("res://scenes")
    DirAccess.make_dir_recursive_absolute("res://scripts")

    # --- Scene 1: Deeply nested scene for get_scene_tree depth tests ---
    var deep_root := Node3D.new()
    deep_root.name = "DepthRoot"
    var current: Node3D = deep_root
    for i in range(1, 18):
        var child := Node3D.new()
        child.name = "Level" + str(i)
        current.add_child(child)
        child.set_owner(deep_root)
        current = child
    _save_scene(deep_root, "res://scenes/deep_nest.tscn")

    # --- Scene 2: Main scene ---
    var main_root := Node3D.new()
    main_root.name = "Main"
    _save_scene(main_root, "res://scenes/main.tscn")

    # --- Scene 3: Parent/instance host scene ---
    var parent_root := Node3D.new()
    parent_root.name = "ParentRoot"

    var container := Node3D.new()
    container.name = "Container"
    parent_root.add_child(container)
    container.set_owner(parent_root)

    var ui := Control.new()
    ui.name = "UI"
    parent_root.add_child(ui)
    ui.set_owner(parent_root)

    var panel := Panel.new()
    panel.name = "Panel"
    ui.add_child(panel)
    panel.set_owner(parent_root)

    var nested_container := Node3D.new()
    nested_container.name = "Container"
    panel.add_child(nested_container)
    nested_container.set_owner(parent_root)

    _save_scene(parent_root, "res://scenes/parent_instance.tscn")

    # --- Scene 4: Child scene for instancing ---
    var child_root := Node3D.new()
    child_root.name = "ChildRoot"
    _save_scene(child_root, "res://scenes/child.tscn")

    # --- Scene 5: Currently-open deletion target ---
    var open_root := Node3D.new()
    open_root.name = "CurrentlyOpenRoot"
    _save_scene(open_root, "res://scenes/currently_open.tscn")

    # --- Scene 6: Test level scene ---
    var level_root := Node3D.new()
    level_root.name = "TestLevel"
    _save_scene(level_root, "res://scenes/test_level.tscn")

    # --- Scene 7: Save-as overwrite target ---
    var exist_root := Node3D.new()
    exist_root.name = "Existing"
    _save_scene(exist_root, "res://scenes/existing.tscn")

    # --- Scene 11: Self-reference scene for cyclic test ---
    var current_root := Node3D.new()
    current_root.name = "CurrentRoot"
    _save_scene(current_root, "res://scenes/current.tscn")

    # --- Script file: player.gd ---
    var script_file := FileAccess.open("res://scripts/player.gd", FileAccess.WRITE)
    if script_file:
        script_file.store_string("extends Node\n")
        script_file.close()

    # --- Set main scene ---
    ProjectSettings.set_setting("application/run/main_scene", "res://scenes/main.tscn")
    ProjectSettings.save()

    print("Scene test prerequisites created successfully.")

func _save_scene(node: Node, path: String) -> void:
    var packed := PackedScene.new()
    packed.pack(node)
    ResourceSaver.save(packed, path, ResourceSaver.FLAG_BUNDLE_RESOURCES)
    print("  Created: ", path)
```

Alternatively, use the MCP tools sequentially (run from the AI client after connecting):

```
1. godot_execute_editor_script  (run the setup script above — single call to create everything)
```

Or manually step by step:

```
# Create directories
1. Create folder res://scenes/ (via godot_execute_editor_script or godot_create_scene)

# Create scenes
2. godot_create_scene(path="res://scenes/deep_nest.tscn", root_node_type="Node3D")
   → then add 17 children via script (too many for manual MCP calls; use EditorScript)

3. godot_create_scene(path="res://scenes/main.tscn", root_node_type="Node3D")
4. godot_create_scene(path="res://scenes/parent_instance.tscn", root_node_type="Node3D")
   → then add Container, UI/Panel/Container nodes

5. godot_create_scene(path="res://scenes/child.tscn", root_node_type="Node3D")
6. godot_create_scene(path="res://scenes/currently_open.tscn", root_node_type="Node3D")
7. godot_create_scene(path="res://scenes/test_level.tscn", root_node_type="Node3D")
8. godot_create_scene(path="res://scenes/existing.tscn", root_node_type="Node3D")
9. godot_create_scene(path="res://scenes/current.tscn", root_node_type="Node3D")

# Create script
10. godot_create_script(path="res://scripts/player.gd", content="extends Node")

# Set main scene
11. godot_set_main_scene(path="res://scenes/main.tscn")
```

## Quick-Start Checklist

Before running any tests, verify:

- [ ] Godot editor open with MCP plugin connected (check MCP panel in bottom dock)
- [ ] `res://scenes/deep_nest.tscn` exists with 17-level `Node3D` chain (`DepthRoot` → `Level1` → ... → `Level17`)
- [ ] `res://scenes/main.tscn` exists and is set as the project's main scene
- [ ] `res://scenes/parent_instance.tscn` exists with nodes: `Container`, `UI/Panel/Container`
- [ ] `res://scenes/child.tscn` exists (any valid scene for instancing)
- [ ] `res://scenes/currently_open.tscn` exists
- [ ] `res://scenes/test_level.tscn` exists
- [ ] `res://scenes/existing.tscn` exists
- [ ] `res://scenes/current.tscn` exists
- [ ] `res://scripts/player.gd` exists (any valid .gd file)
- [ ] (Optional) `res://scenes/legacy.scn` exists for .scn file test
- [ ] Editor is in edit mode (not play mode) before starting
- [ ] Note the current main scene path for restoration after `set_main_scene` tests
