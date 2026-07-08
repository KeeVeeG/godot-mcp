# Prerequisites for animation_test_plan.md

> **HOW TO USE:** All prerequisites below must exist BEFORE running the first test scenario.
> Tests are designed to run sequentially; later scenarios build on state created by earlier ones.
> This document only lists what must be pre-established — not what prior scenarios create.

---

## Required Project State

- **Godot project type:** 2D (a `Node2D`-rooted scene is sufficient; AnimationPlayer and Sprite2D both work in 2D and 3D, but `Sprite2D` requires a 2D context)
- **Godot version:** 4.x (tested with 4.7)
- **MCP plugin:** Installed and active (`addons/godot_mcp/` present, plugin enabled in Project Settings → Plugins)
- **MCP server:** Running and connected to the Godot editor (WebSocket established on ports 6505-6514)
- **Project path:** Standard `res://` prefixed project; no special project settings required beyond defaults
- **No main scene override needed:** Tests open a specific scene (see below)

---

## Required Scenes

### Scene: `res://test_scenes/animation_test.tscn`

A single scene must exist and be open in the editor. Root node type: `Node2D` (or `Node`).

```
Node2D (root, name: "AnimationTestRoot")
├── AnimationPlayer (name: "AnimationPlayer")
├── AnimationPlayer (name: "AnimPlayer")
├── Sprite2D (name: "Sprite2D")
├── AnimationTree (name: "EmptyTree")
├── AnimationTree (name: "BlendTreeRoot")
└── AnimationTree (name: "AnimationTree")
```

#### Node configurations:

| Node | Type | Name | Special Configuration | Needed By |
|------|------|------|-----------------------|-----------|
| root child 1 | `AnimationPlayer` | `AnimationPlayer` | Default properties. **Must have:** library `character_anims` created with animation `jump` (length=1.0, loop_mode=none) containing at least 1 track (track index 0, type=value). **Must have in default library:** animation `walk` (length=1.0, loop_mode=none) containing at least 1 track; animation `empty_anim` (length=1.0, loop_mode=none) with 0 tracks. | `list_animations` S1, `create_animation` all scenarios, `add_animation_track` all scenarios, `set_animation_keyframe` all scenarios, `get_animation_info` S1-S5, `remove_animation` S1-S5, `create_animation_tree` S2, `add_state_machine_state` S2 |
| root child 2 | `AnimationPlayer` | `AnimPlayer` | Default properties. **Must have ZERO animations and ZERO libraries.** (Clean slate for integration tests and empty-player tests.) | Integration 1 & 2, `get_animation_info` S6, `remove_animation` S6 |
| root child 3 | `Sprite2D` | `Sprite2D` | Default properties (no texture needed). | `list_animations` S5, `get_animation_tree_structure` S4, `set_tree_parameter` S10, `add_state_machine_state` S9 |
| root child 4 | `AnimationTree` | `EmptyTree` | Default root type (`AnimationNodeBlendTree`). No states, no parameters, no customization. `active = false`. | `get_animation_tree_structure` S2 |
| root child 5 | `AnimationTree` | `BlendTreeRoot` | Root type: `AnimationNodeBlendTree` (explicitly NOT a StateMachine). No states. `active = false`. | `add_state_machine_state` S10 |
| root child 6 | `AnimationTree` | `AnimationTree` | Root type: `AnimationNodeStateMachine`. No states initially. `active = false`. **NOT linked to any AnimationPlayer.** | `create_animation_tree` S8, `get_animation_tree_structure` S1, `set_tree_parameter` all scenarios, `add_state_machine_state` S1-S8, S11-S12 |

#### How to verify each node's configuration:

**`AnimationPlayer` (node 1) — the "rich" player:**
- `list_animations` should return: `["walk", "empty_anim"]` in default library; `["jump"]` in library `character_anims`
- `get_animation_info` on `"walk"` should show: length=1.0, loop_mode=none, tracks=[{type: "value", …}], at least 1 track
- `get_animation_info` on `"empty_anim"` should show: length=1.0, loop_mode=none, tracks=[]
- `get_animation_info` on `"jump"` with library=`"character_anims"` should show: length=1.0, loop_mode=none, tracks=[{type: "value", …}]

**`AnimPlayer` (node 2) — the "empty" player:**
- `list_animations` should return: `[]`
- Must have zero libraries beyond default

**`Sprite2D` (node 3):**
- `get_node_properties` should confirm type is `Sprite2D`
- Name must be exactly `Sprite2D` (case-sensitive match for path-based queries)

**`EmptyTree` (node 4):**
- `get_animation_tree_structure` should return: root_type=`AnimationNodeBlendTree`, no child nodes, no parameters
- `active = false`

**`BlendTreeRoot` (node 5):**
- `get_animation_tree_structure` should return: root_type=`AnimationNodeBlendTree`
- `add_state_machine_state` must fail because root is not a StateMachine

**`AnimationTree` (node 6):**
- `get_animation_tree_structure` should return: root_type=`AnimationNodeStateMachine`, no states
- `active = false`
- `anim_player` property is empty (no AnimationPlayer linked)

---

## Required Resources

No external resource files (.tres, .res, textures, materials, shaders, audio) are needed. All animation data is embedded in the scene's AnimationPlayer nodes.

---

## Required Editor/Game State

| Requirement | Details | Needed By |
|-------------|---------|-----------|
| **Scene open** | `res://test_scenes/animation_test.tscn` must be the active/open scene in the editor | All scenarios |
| **Play mode** | Editor must be STOPPED (not in play mode). No runtime tools are used. | All scenarios |
| **Editor layout** | Default layout is fine. No specific layout required. | All scenarios |
| **Selection** | No specific node selection needed; tools target nodes by path. | All scenarios |
| **Breakpoints** | None needed. No debugging tools are tested. | N/A |
| **Undo stack** | Clean (empty) undo stack preferred to avoid state confusion during sequential tests. | All mutation scenarios |

---

## Required Settings/Config

| Setting | Value | Needed By |
|---------|-------|-----------|
| **No special project settings** | All `project.godot` settings at defaults | All scenarios |
| **No custom input actions** | Default InputMap (ui_accept, ui_cancel, etc.) is fine — no animation tools depend on input | All scenarios |
| **No autoloads beyond MCP** | Only `mcp_runtime` autoload (installed by the MCP plugin) should be present | All scenarios |
| **No custom collision layers** | Default collision layers are fine | All scenarios |
| **No addons beyond MCP** | Only `godot_mcp` addon installed and active | All scenarios |

---

## External State

| Requirement | Details |
|-------------|---------|
| **MCP server connection** | The Node.js MCP server (`server/dist/index.js`) must be running and connected to the Godot editor via WebSocket |
| **No git repo required** | Git initialization is irrelevant for these tests |
| **No packages required** | No Unity Package Manager equivalent — Godot uses addons, and only `godot_mcp` is needed |

---

## Setup Script (GDScript)

Run this in the Godot editor (via `godot_execute_editor_script`) BEFORE any tests to create all prerequisites:

```gdscript
# Setup script for animation_test_plan.md prerequisites
# Run this ONCE via godot_execute_editor_script before executing test scenarios.
# Creates the scene at res://test_scenes/animation_test.tscn with all required nodes.

@tool
extends EditorScript

func _run() -> void:
    # --- Ensure directory exists ---
    var dir := DirAccess.open("res://")
    if not dir.dir_exists("res://test_scenes"):
        dir.make_dir("res://test_scenes")

    # --- Create new scene ---
    var root := Node2D.new()
    root.name = "AnimationTestRoot"

    # --- Node 1: AnimationPlayer (rich — has animations, tracks, library) ---
    var ap_rich := AnimationPlayer.new()
    ap_rich.name = "AnimationPlayer"
    root.add_child(ap_rich)
    ap_rich.owner = root

    # Create "walk" animation in default library (length=1.0, loop_mode=none)
    var walk_anim := Animation.new()
    walk_anim.length = 1.0
    walk_anim.loop_mode = Animation.LOOP_NONE
    walk_anim.add_track(Animation.TYPE_VALUE)
    walk_anim.track_set_path(0, ".:position:x")
    var walk_lib := AnimationLibrary.new()
    walk_lib.add_animation("walk", walk_anim)

    # Create "empty_anim" in default library (length=1.0, 0 tracks)
    var empty_anim := Animation.new()
    empty_anim.length = 1.0
    empty_anim.loop_mode = Animation.LOOP_NONE
    walk_lib.add_animation("empty_anim", empty_anim)

    ap_rich.add_animation_library("", walk_lib)

    # Create "character_anims" library with "jump" animation (has 1 track)
    var jump_anim := Animation.new()
    jump_anim.length = 1.0
    jump_anim.loop_mode = Animation.LOOP_NONE
    jump_anim.add_track(Animation.TYPE_VALUE)
    jump_anim.track_set_path(0, ".:position:y")
    var char_lib := AnimationLibrary.new()
    char_lib.add_animation("jump", jump_anim)
    ap_rich.add_animation_library("character_anims", char_lib)

    # --- Node 2: AnimationPlayer (empty — zero animations, zero libraries) ---
    var ap_empty := AnimationPlayer.new()
    ap_empty.name = "AnimPlayer"
    root.add_child(ap_empty)
    ap_empty.owner = root

    # --- Node 3: Sprite2D (for type-mismatch tests) ---
    var sprite := Sprite2D.new()
    sprite.name = "Sprite2D"
    root.add_child(sprite)
    sprite.owner = root

    # --- Node 4: AnimationTree (EmptyTree — default BlendTree root, no customization) ---
    var at_empty := AnimationTree.new()
    at_empty.name = "EmptyTree"
    at_empty.active = false
    root.add_child(at_empty)
    at_empty.owner = root

    # --- Node 5: AnimationTree (BlendTreeRoot — explicit BlendTree root, NOT StateMachine) ---
    var at_blend := AnimationTree.new()
    at_blend.name = "BlendTreeRoot"
    at_blend.active = false
    var blend_root := AnimationNodeBlendTree.new()
    at_blend.tree_root = blend_root
    root.add_child(at_blend)
    at_blend.owner = root

    # --- Node 6: AnimationTree (AnimationTree — StateMachine root for state tests) ---
    var at_sm := AnimationTree.new()
    at_sm.name = "AnimationTree"
    at_sm.active = false
    var sm_root := AnimationNodeStateMachine.new()
    at_sm.tree_root = sm_root
    root.add_child(at_sm)
    at_sm.owner = root

    # --- Pack and save scene ---
    var packed := PackedScene.new()
    packed.pack(root)
    var path := "res://test_scenes/animation_test.tscn"
    ResourceSaver.save(packed, path)

    # --- Open the scene in editor ---
    EditorInterface.open_scene_from_path(path)

    print("[Setup] Created animation test scene: ", path)
    print("[Setup] Nodes: ", root.get_child_count())
```

---

## Manual Verification Checklist

After running the setup script, verify with these checks:

1. **`godot_list_animations`** with `player_path="AnimationPlayer"` → returns `["empty_anim", "walk"]` (order may vary)
2. **`godot_list_animations`** with `player_path="AnimPlayer"` → returns `[]`
3. **`godot_get_animation_info`** with `player_path="AnimationPlayer"`, `animation="walk"` → shows length=1.0, 1 track
4. **`godot_get_animation_info`** with `player_path="AnimationPlayer"`, `animation="empty_anim"` → shows length=1.0, 0 tracks
5. **`godot_get_animation_info`** with `player_path="AnimationPlayer"`, `animation="jump"`, `library="character_anims"` → shows length=1.0, 1 track
6. **`godot_get_node_properties`** with `path="Sprite2D"` → confirms node type is `Sprite2D`
7. **`godot_get_animation_tree_structure`** with `path="EmptyTree"` → shows root type `AnimationNodeBlendTree`, no nodes
8. **`godot_get_animation_tree_structure`** with `path="BlendTreeRoot"` → shows root type `AnimationNodeBlendTree`
9. **`godot_get_animation_tree_structure`** with `path="AnimationTree"` → shows root type `AnimationNodeStateMachine`, no states
10. **`godot_get_scene_tree`** → confirms all 6 child nodes exist with correct names under the root

---

## Test Execution Order Notes

The test plan is designed for sequential execution. Key dependencies between scenarios:

- `add_animation_track` S1-S7 depend on `create_animation` S1 having created `"walk"`
- `set_animation_keyframe` S1-S13 depend on `add_animation_track` S1 having created track index 0
- `remove_animation` S5 depends on `remove_animation` S1 having already removed `"walk"`
- `create_animation` S12 depends on `create_animation` S1 having already created `"walk"`
- `get_animation_info` S1 depends on `create_animation` S1 having created `"walk"`
- `get_animation_info` S6 uses `AnimPlayer` (the empty player) — does NOT depend on prior scenarios
- `remove_animation` S6 uses `AnimPlayer` — does NOT depend on prior scenarios
- `add_state_machine_state` S4 depends on `add_state_machine_state` S1 having created `"idle"`

Integration tests use `AnimPlayer` (separate from `AnimationPlayer`) and should be run last or on a fresh scene state since they create and destroy `"test_anim"`.
