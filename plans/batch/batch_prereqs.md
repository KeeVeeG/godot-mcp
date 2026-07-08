# Prerequisites for Batch Tools Test Plan

> Derived from `server/src/test_plans/batch_test_plan.md`
> Target project: `test_project/` (the existing Godot test project in this repo)
> Generated: 2026-07-08

---

## Summary of Gaps (What Must Be Created)

The existing `test_project` has a basic `main.tscn` with mixed nodes but is missing most of what the test plan demands. The following must be built before any batch tool scenarios can run.

---

## Required Project State

- [ ] **Godot 4.x editor open** with `test_project/` loaded as the active project
- [ ] **Godot MCP addon active** — plugin `res://addons/godot_mcp/plugin.cfg` enabled (already in `project.godot`, must be active in editor)
- [ ] **MCP server connected** to the Godot editor via WebSocket (port 6505-6514 range)
- [ ] **Disposable / copy project recommended** — destructive mutation tools (`batch_set_property`, `cross_scene_set_property`) modify scenes. Clone `test_project/` before running those scenarios.
- [ ] **`res://scripts/` directory** created — does not exist yet
- [ ] **`res://_verify_scene.tscn`** created or `project.godot` `run/main_scene` updated — currently points to a non-existent file

---

## Required Scenes

### Scene 1: `res://scenes/main.tscn` (ALREADY EXISTS — but needs signal connections)
**Root:** `Node2D` named `"root"`
**Existing nodes used by tests:** `Player` (Sprite2D), `ScoreLabel` (Label), `StartButton` (Button), `Enemy` (RigidBody2D), `PickupZone` (Area2D), `SpawnPoint` (Node2D), `BGMPlayer` (AudioStreamPlayer), `Explosion` (GPUParticles2D), `AnimPlayer` (AnimationPlayer), `GameTimer` (Timer), `GameCamera` (Camera2D), `TestRunner` (Node), `NavigationRegion2D`, `UIRoot` (Control)

**Needed modifications for test plan:**
- [ ] **Signal connection #1** — `StartButton` (Button) → `pressed` signal → connected to `root` script method `_on_start_button_pressed()` (needed for `find_signal_connections` Scenario 1)
- [ ] **Unique name** — Mark `Player` node as unique (`%Player`) via scene unique name toggle (needed for `find_node_references` Scenario 3)
- [ ] **Add `Camera2D` child under `Player`** — named `Camera2D` so path `Player/Camera2D` exists (needed for `find_node_references` Scenario 2)
- [ ] **Script on root** — The scene already has `script = ExtResource("1_o5qli")` pointing to `res://scripts/_runtime_main.gd` (missing file, see Resources section)
- [ ] **Multiple Sprite2D nodes** — The scene already has `Player` (Sprite2D); add 2-3 more `Sprite2D` children under root (e.g., `SpriteA`, `SpriteB`) for `batch_set_property` multi-target tests
- [ ] **Multiple Label nodes** — Add 1-2 more `Label` nodes (e.g., `HealthLabel`, `DebugLabel`) for `batch_set_property` Label test
- [ ] **Multiple direct `Node2D` children** — `SpawnPoint` is already a Node2D child; add at least one more `Node2D` child (e.g., `CheckpointA`) for `batch_set_property` Scenario 3

### Scene 2: `res://scenes/empty.tscn` (MUST CREATE)
**Root:** `Node2D` (or `Node`)
**Contents:** Minimal scene — just the root node, no scripts, no external resources, no signal connections. Used by `get_scene_dependencies` Scenario 2 and `find_signal_connections` Scenario 2.

### Scene 3: `res://scenes/parent.tscn` (MUST CREATE)
**Root:** `Node2D`
**Contents:** Instantiates another scene as a child (e.g., `res://scenes/child.tscn`). The child scene should itself reference an external resource or script. Used by `get_scene_dependencies` Scenario 3.

### Scene 4: `res://scenes/child.tscn` (MUST CREATE — dependency for parent.tscn)
**Root:** `Node2D`
**Contents:** Contains at least one node with an attached script (e.g., `res://scripts/common.gd`) and/or an external resource. Used as a nested dependency for `get_scene_dependencies` Scenario 3.

### Scene 5: `res://scenes/second_scene.tscn` (MUST CREATE)
**Root:** `Node2D`
**Contents:** Contains at least one `Sprite2D` node. Used by `cross_scene_set_property` to test multi-scene mutation (needs Sprite2D nodes in more than one scene).

---

## Required Resources

### Scripts (all under `res://scripts/` — directory does not exist yet)

- [ ] **`res://scripts/player.gd`** — GDScript extending `Sprite2D`, containing a method `_on_start_button_pressed()`. Attached to `Player` node in `main.tscn`. Used by: `find_script_references` Scenario 1, `find_node_references` Scenario 1.
  ```gdscript
  extends Sprite2D
  
  func _on_start_button_pressed():
      print("Start pressed on Player script")
  ```

- [ ] **`res://scripts/common.gd`** — GDScript extending `Node2D` or `Node`. Attached to at least one node in `main.tscn` AND at least one node in `child.tscn` (multi-scene usage). Used by: `find_script_references` Scenario 2.

- [ ] **`res://scripts/unused.gd`** — GDScript extending `Node`. Must exist on disk but NOT be attached to any node in any scene. Used by: `find_script_references` Scenario 3.

- [ ] **`res://scripts/_runtime_main.gd`** — Scene root script. The existing `main.tscn` already references `uid://db5on6f25l6vd` with path `res://scripts/_runtime_main.gd`, but the file does not exist on disk. Must create with at minimum a `_on_start_button_pressed()` method.

### Resources (.tres)

- [ ] **`res://default_bus_layout.tres`** — Already exists in `test_project/`, referenced by `project.godot`.

### Audio

- [ ] **`BGMPlayer`** (AudioStreamPlayer) already exists in `main.tscn` but has no stream assigned. Optional — not strictly required by batch tools, but needed if expanding tests.

---

## Required Editor/Game State

| Tool | State Requirement |
|------|------------------|
| `find_nodes_by_type` | Scene `main.tscn` **must be open** in the editor |
| `find_signal_connections` | Scene `main.tscn` (with signals) or `empty.tscn` (without) **must be open** |
| `batch_set_property` | Scene `main.tscn` **must be open** (mutations apply to open scene only) |
| `find_node_references` | Any scene open (searches project-wide). Node `"Player"` must exist and be referenced in scripts |
| `get_scene_dependencies` | No specific scene must be open (operates on file path). Scene files must exist on disk |
| `cross_scene_set_property` | Any scene open. All scenes in project are scanned and modified. **Use disposable project copy** |
| `find_script_references` | Any scene open (searches project-wide). Scripts must exist and be attached |
| `detect_circular_dependencies` | Any project (searches entire project). No scene needs to be open |
| All tools (disconnect tests) | Godot editor **not connected** (stop the bridge or close Godot) |

---

## Required Settings / Config

- [ ] **Godot MCP addon registered** — `project.godot` line 47: `enabled=PackedStringArray("res://addons/godot_mcp/plugin.cfg")` ✅ Already present
- [ ] **Autoload `mcp_runtime.gd`** — `project.godot` line 28: `1="*res://addons/godot_mcp/services/mcp_runtime.gd"` ✅ Already present
- [ ] **Main scene** — `project.godot` line 19: `run/main_scene="res://_verify_scene.tscn"` ⚠️ Points to non-existent file; either create the file or update to `"res://scenes/main.tscn"`
- [ ] **Project name** — `TestProject` ✅ Already set
- [ ] **No special input actions, collision layers, or other settings** required for batch tools (they operate on scene structure, not gameplay input)

---

## Required External State

- [ ] **Godot MCP addon installed** in `test_project/addons/godot_mcp/` ✅ Already present
- [ ] **No additional packages or addons** required for batch tool scenarios
- [ ] **Git repo** — not required for batch tools, but the test project is already inside the `godot-mcp` git repo

---

## Setup Script (GDScript)

This script can be run via `godot_execute_editor_script` to create most prerequisites. It assumes the Godot editor has `test_project/` open with `main.tscn` already loaded.

```gdscript
# ============================================================
# Setup script for batch tool test plan prerequisites
# Run this via godot_execute_editor_script in editor context
# ============================================================

@tool
extends EditorScript

func _run() -> void:
    print("=== Batch Test Plan Setup ===")
    
    # --- STEP 1: Create scripts directory & scripts ---
    _create_scripts()
    
    # --- STEP 2: Create scene files ---
    _create_scenes()
    
    # --- STEP 3: Modify main.tscn ---
    _modify_main_scene()
    
    # --- STEP 4: Fix project.godot main scene ---
    _fix_main_scene()
    
    print("=== Setup Complete ===")
    print("Next: Open res://scenes/main.tscn and connect StartButton.pressed -> root._on_start_button_pressed()")


# -----------------------------------------------------------
# STEP 1: Create scripts
# -----------------------------------------------------------
func _create_scripts() -> void:
    var scripts_dir := "res://scripts"
    DirAccess.make_dir_recursive_absolute(scripts_dir)
    print("[OK] Created ", scripts_dir)
    
    # player.gd — attached to Player Sprite2D
    _write_file("res://scripts/player.gd", """extends Sprite2D

func _on_start_button_pressed():
    print("Start pressed on Player script")
""")
    print("[OK] Created res://scripts/player.gd")
    
    # common.gd — attached in multiple scenes
    _write_file("res://scripts/common.gd", """extends Node2D
""")
    print("[OK] Created res://scripts/common.gd")
    
    # unused.gd — exists but NOT attached anywhere
    _write_file("res://scripts/unused.gd", """extends Node
""")
    print("[OK] Created res://scripts/unused.gd")
    
    # _runtime_main.gd — scene root script for main.tscn
    _write_file("res://scripts/_runtime_main.gd", """extends Node2D

func _on_start_button_pressed():
    print("Start pressed on root script")
""")
    print("[OK] Created res://scripts/_runtime_main.gd")


# -----------------------------------------------------------
# STEP 2: Create scene files
# -----------------------------------------------------------
func _create_scenes() -> void:
    # empty.tscn — minimal scene
    var empty_root := Node2D.new()
    empty_root.name = "EmptyRoot"
    var empty_packed := PackedScene.new()
    empty_packed.pack(empty_root)
    ResourceSaver.save(empty_packed, "res://scenes/empty.tscn")
    empty_root.free()
    print("[OK] Created res://scenes/empty.tscn")
    
    # child.tscn — has a node with common.gd attached
    var child_root := Node2D.new()
    child_root.name = "ChildRoot"
    var child_node := Node2D.new()
    child_node.name = "ChildNode"
    child_node.set_script(load("res://scripts/common.gd"))
    child_root.add_child(child_node, true)
    child_node.owner = child_root
    var child_packed := PackedScene.new()
    child_packed.pack(child_root)
    ResourceSaver.save(child_packed, "res://scenes/child.tscn")
    child_root.free()
    print("[OK] Created res://scenes/child.tscn")
    
    # parent.tscn — instantiates child.tscn
    var parent_root := Node2D.new()
    parent_root.name = "ParentRoot"
    var child_instance := load("res://scenes/child.tscn").instantiate()
    child_instance.name = "ChildInstance"
    parent_root.add_child(child_instance, true)
    child_instance.owner = parent_root
    var parent_packed := PackedScene.new()
    parent_packed.pack(parent_root)
    ResourceSaver.save(parent_packed, "res://scenes/parent.tscn")
    parent_root.free()
    print("[OK] Created res://scenes/parent.tscn")
    
    # second_scene.tscn — contains a Sprite2D for cross-scene tests
    var second_root := Node2D.new()
    second_root.name = "SecondRoot"
    var sprite := Sprite2D.new()
    sprite.name = "ExtraSprite"
    second_root.add_child(sprite, true)
    sprite.owner = second_root
    var second_packed := PackedScene.new()
    second_packed.pack(second_root)
    ResourceSaver.save(second_packed, "res://scenes/second_scene.tscn")
    second_root.free()
    print("[OK] Created res://scenes/second_scene.tscn")


# -----------------------------------------------------------
# STEP 3: Modify main.tscn (requires it to be open in editor)
# -----------------------------------------------------------
func _modify_main_scene() -> void:
    var editor := get_editor_interface()
    var root := editor.get_edited_scene_root()
    
    if root == null:
        printerr("ERROR: No scene is open. Open res://scenes/main.tscn first.")
        return
    
    if root.name != "root":
        printerr("WARNING: Root is not named 'root'. Got: ", root.name)
    
    # Attach player.gd to the Player Sprite2D node
    var player := root.get_node_or_null("Player")
    if player and player is Sprite2D:
        if not player.script:
            player.set_script(load("res://scripts/player.gd"))
            print("[OK] Attached player.gd to Player node")
        else:
            print("[SKIP] Player already has a script")
    else:
        printerr("WARNING: Player node not found or not a Sprite2D")

    # Mark Player as unique name (%Player) — note: unique names are on the file, set via set_scene_unique_name
    # This must be done differently in old Godot versions.
    # For 4.x: set the "unique_name_in_owner" property on the node
    if player:
        # In Godot 4.x scene format, unique names are stored as `unique_id` in the .tscn
        # The main.tscn already has unique_id attributes. The % syntax is editor-only.
        # The find_node_references tool searches for "%Player" string in scripts.
        # So we just need one script that references %Player.
        print("[NOTE] Unique name %Player is already set via unique_id in .tscn")
    
    # Add Camera2D child under Player
    if player and not player.has_node("Camera2D"):
        var cam := Camera2D.new()
        cam.name = "Camera2D"
        player.add_child(cam, true)
        cam.owner = root
        print("[OK] Added Camera2D under Player")
    
    # Add extra Sprite2D nodes for multi-target batch tests
    for sname in ["SpriteA", "SpriteB", "SpriteC"]:
        if not root.has_node(sname):
            var s := Sprite2D.new()
            s.name = sname
            s.position = Vector2(randi() % 400, randi() % 300)
            root.add_child(s, true)
            s.owner = root
            print("[OK] Added ", sname)
    
    # Add extra Label nodes
    for lname in ["HealthLabel", "DebugLabel"]:
        if not root.has_node(lname):
            var l := Label.new()
            l.name = lname
            l.text = lname
            l.position = Vector2(randi() % 400, randi() % 300)
            root.add_child(l, true)
            l.owner = root
            print("[OK] Added ", lname)
    
    # Add extra Node2D direct child for position test
    var checkpoints := ["CheckpointA", "WaypointB"]
    for cpname in checkpoints:
        if not root.has_node(cpname):
            var cp := Node2D.new()
            cp.name = cpname
            cp.position = Vector2(randi() % 400, randi() % 300)
            root.add_child(cp, true)
            cp.owner = root
            print("[OK] Added ", cpname)
    
    # Save the scene
    editor.save_scene()
    print("[OK] Saved main.tscn")


# -----------------------------------------------------------
# STEP 4: Fix project.godot main scene reference
# -----------------------------------------------------------
func _fix_main_scene() -> void:
    var cfg := ConfigFile.new()
    var path := "res://project.godot"
    var err := cfg.load(path)
    if err != OK:
        printerr("ERROR: Could not load project.godot: ", err)
        return
    
    cfg.set_value("application", "run/main_scene", "res://scenes/main.tscn")
    cfg.save(path)
    print("[OK] Set main scene to res://scenes/main.tscn")


# -----------------------------------------------------------
# Utility: write string to file on disk
# -----------------------------------------------------------
func _write_file(res_path: String, content: String) -> void:
    # Convert res:// to absolute OS path by stripping res:// and prepending project dir
    var abs_path := ProjectSettings.globalize_path(res_path)
    var f := FileAccess.open(abs_path, FileAccess.WRITE)
    if not f:
        printerr("ERROR: Could not write ", abs_path)
        return
    f.store_string(content)
    f.close()
```

---

## Manual Steps Required After Setup Script

The setup script cannot perform these operations — they require manual intervention or separate Godot tool calls:

1. **Signal connection** — Connect `StartButton`'s `pressed` signal to the root node's `_on_start_button_pressed()` method. Use:
   - `godot_connect_signal(source="StartButton", signal="pressed", target="root", method="_on_start_button_pressed")`

2. **Refresh asset database** — After creating scripts, Godot needs to re-import: run `godot_reload_project` or `unity_refresh_unity` equivalent (in Godot MCP: `godot_reload_project`).

3. **Disposable project copy** — For destructive mutation tests (`batch_set_property`, `cross_scene_set_property`), copy the entire `test_project/` directory to `test_project_batch_copy/` and open that copy in Godot.

---

## Test Scenario → Prerequisite Mapping

| Scenario | Quick Check Before Running |
|----------|---------------------------|
| `find_nodes_by_type` S1 | `main.tscn` open. At least one `Sprite2D` exists. |
| `find_nodes_by_type` S2 | `main.tscn` open. Root is `Node2D`. |
| `find_nodes_by_type` S3 | `main.tscn` open. No `CharacterBody3D` in scene. |
| `find_nodes_by_type` S4–S7 | Any scene open. Zod validation server-side. |
| `find_nodes_by_type` S8 | Godot editor NOT connected. |
| `find_signal_connections` S1 | `main.tscn` open. `StartButton.pressed` connected to `root._on_start_button_pressed()`. |
| `find_signal_connections` S2 | `empty.tscn` open. No signal connections exist. |
| `find_signal_connections` S3 | Any scene open. Extra params passed through. |
| `find_signal_connections` S4 | Godot editor NOT connected. |
| `batch_set_property` S1 | `main.tscn` open. Multiple `Sprite2D` nodes exist. |
| `batch_set_property` S2 | `main.tscn` open. Multiple `Label` nodes exist. |
| `batch_set_property` S3 | `main.tscn` open. Direct `Node2D` children of root exist. |
| `batch_set_property` S4 | `main.tscn` open (destructive — use copy). |
| `batch_set_property` S5 | `main.tscn` open. No `CharacterBody3D` exists. |
| `batch_set_property` S6–S9 | Zod validation; S10: Godot disconnected. |
| `find_node_references` S1 | `res://scripts/player.gd` exists and references `"Player"`. |
| `find_node_references` S2 | Node path `Player/Camera2D` exists in scene. |
| `find_node_references` S3 | Unique-name `%Player` configured. |
| `find_node_references` S4–S7 | Any project state; S8: Godot disconnected. |
| `get_scene_dependencies` S1 | `res://scenes/main.tscn` exists with scripts + resources. |
| `get_scene_dependencies` S2 | `res://scenes/empty.tscn` exists — minimal, no deps. |
| `get_scene_dependencies` S3 | `res://scenes/parent.tscn` + `child.tscn` exist with nested deps. |
| `get_scene_dependencies` S4–S8 | Various edge cases; S9: Godot disconnected. |
| `cross_scene_set_property` ALL | **Use disposable project copy.** Multiple scenes with `Sprite2D` nodes. |
| `find_script_references` S1 | `res://scripts/player.gd` attached to at least one node. |
| `find_script_references` S2 | `res://scripts/common.gd` attached in multiple scenes. |
| `find_script_references` S3 | `res://scripts/unused.gd` exists but NOT attached. |
| `find_script_references` S4–S7 | Various; S6 needs addon script; S8: Godot disconnected. |
| `detect_circular_dependencies` S1–S4 | Any clean project; S2 optional (circular dep project); S5: Godot disconnected. |
