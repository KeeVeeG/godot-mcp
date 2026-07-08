# Prerequisites for node_test_plan.md

## Required Project State

- Godot 4.x editor is running with the `godot_mcp` plugin active and connected to the MCP server
- A project is open (any project type — 2D or 3D)
- A scene is open in the editor with at least a root node
- The test scene must exist on disk at `res://` (persistent scene recommended for test isolation)
- No play mode required — all tests run in editor mode

## Required Scenes

### Core test scene (must be open before any test)

```
Scene root: Node2D (named "Root")
├── Sprite2D (named "Player")
├── Sprite2D (named "Enemy")
└── Control (named "UI")
    ├── Button (named "StartButton")
    └── Label (named "StatusLabel")
```

**Exact node details:**

| Node Path       | Type     | Name          | Special Requirements |
|-----------------|----------|---------------|----------------------|
| (root)          | `Node2D` | `Root`        | —                    |
| `Player`        | `Sprite2D` | `Player`   | Belongs to group `"players"` |
| `Enemy`         | `Sprite2D` | `Enemy`    | Belongs to group `"enemies"` |
| `UI`            | `Control`  | `UI`       | —                    |
| `UI/StartButton`| `Button`   | `StartButton`| Has `pressed` signal (built into Button) |
| `UI/StatusLabel`| `Label`    | `StatusLabel`| —                    |

**Group assignments (pre-populated):**
- `Player` ∈ `["players"]`
- `Enemy` ∈ `["enemies"]`

### No other scenes required

All 17 tools and 3 end-to-end workflows operate within this single scene. Tests that add/modify/delete nodes should either clean up after themselves or start from a fresh copy of the scene.

## Required Resources

### Shader (optional — needed only for add_resource Scenario 2)

| Resource | Path | Required For |
|----------|------|-------------|
| GDScript shader | `res://shaders/outline.gdshader` | `add_resource` S2 — ShaderMaterial with shader path. If the file does not exist, this scenario will test error-handling behavior instead. |

### No other resources required

No `.tres`/`.res` files, textures, materials, audio files, or other assets are needed by any test scenario.

## Required Editor/Game State

- **Play mode:** OFF — all tests run in editor mode. No tests require the game to be running.
- **Editor layout:** default. No specific layout required.
- **Editor selection:** Tests for `get_editor_selection`, `select_nodes`, and `clear_editor_selection` manage selection state themselves. No pre-existing selection required.
- **Breakpoints:** None required.
- **Active scene:** The core test scene described above must be the currently open scene.

## Required Settings/Config

### Project settings
- **No specific project settings** are required. All tools operate with default values.

### Input actions
- **No custom input actions** required. The `connect_signal` / `disconnect_signal` tests use the built-in `pressed` signal on `Button`, not input-map actions.

### Autoloads
- **No custom autoloads** required. The MCP runtime autoload (`mcp_runtime`) is expected to be present for the plugin to function but is not directly tested by these node tools.

### Collision layers
- **No collision layers** required.

### Groups
- The groups `"players"` and `"enemies"` must exist (created implicitly by assigning `Player` and `Enemy` to them in the test data setup).
- An additional group `"empty_group"` should exist with no members (for `find_nodes_in_group` S2). This can be created by running `set_node_groups` with an empty array on any node that previously had a group.

## Test Order Dependencies

Some scenarios depend on prior test execution:

| Tool | Scenario | Depends On |
|------|----------|------------|
| `disconnect_signal` | S1 | `connect_signal` S1 must run first (creates the connection to disconnect) |
| `get_node_groups` | S2 | A new ungrouped node (`"NewNode"`) must be added to the scene first |
| `get_editor_selection` | S1 | `select_nodes` must select `"Player"` first |
| `get_editor_selection` | S2 | `clear_editor_selection` must be called first |
| `get_editor_selection` | S3 | `select_nodes` must select `["Player", "Enemy"]` first |
| `clear_editor_selection` | S1 | `select_nodes` must select `["Player", "Enemy"]` first |
| `find_nodes_in_group` | S2 | A group named `"empty_group"` must exist with zero members |

## Setup Script

This GDScript can be executed via `godot_execute_editor_script` to create the prerequisite scene from scratch:

```gdscript
@tool
extends EditorScript

func _run() -> void:
    # Create a new scene with Node2D root
    var root := Node2D.new()
    root.name = "Root"

    # Add Player sprite
    var player := Sprite2D.new()
    player.name = "Player"
    root.add_child(player)
    player.set_owner(root)

    # Add Enemy sprite
    var enemy := Sprite2D.new()
    enemy.name = "Enemy"
    root.add_child(enemy)
    enemy.set_owner(root)

    # Add UI Control
    var ui := Control.new()
    ui.name = "UI"
    root.add_child(ui)
    ui.set_owner(root)

    # Add StartButton
    var btn := Button.new()
    btn.name = "StartButton"
    ui.add_child(btn)
    btn.set_owner(root)

    # Add StatusLabel
    var lbl := Label.new()
    lbl.name = "StatusLabel"
    ui.add_child(lbl)
    lbl.set_owner(root)

    # Assign groups
    player.add_to_group("players")
    enemy.add_to_group("enemies")

    # Pack scene and save
    var packed := PackedScene.new()
    packed.pack(root)
    ResourceSaver.save(packed, "res://test_scenes/node_test_scene.tscn")
```

Alternatively, use the MCP tools sequentially:

```
1. godot_create_scene(path="res://test_scenes/node_test_scene.tscn", root_node_type="Node2D")
2. godot_rename_node(path="", new_name="Root")
3. godot_add_node(parent_path="", type="Sprite2D", name="Player")
4. godot_add_node(parent_path="", type="Sprite2D", name="Enemy")
5. godot_add_node(parent_path="", type="Control", name="UI")
6. godot_add_node(parent_path="UI", type="Button", name="StartButton")
7. godot_add_node(parent_path="UI", type="Label", name="StatusLabel")
8. godot_set_node_groups(path="Player", groups=["players"])
9. godot_set_node_groups(path="Enemy", groups=["enemies"])
10. godot_save_scene(path="res://test_scenes/node_test_scene.tscn")
```

## Quick-Start Checklist

Before running any tests, verify:

- [ ] Godot editor open with MCP plugin connected (check MCP panel in bottom dock)
- [ ] Open `res://test_scenes/node_test_scene.tscn` (or the core test scene)
- [ ] Scene tree matches: `Root` → `Player`, `Enemy`, `UI` → `StartButton`, `StatusLabel`
- [ ] `Player` belongs to group `"players"`
- [ ] `Enemy` belongs to group `"enemies"`
- [ ] Editor is in edit mode (not play mode)
- [ ] (Optional) `res://shaders/outline.gdshader` exists for `add_resource` S2
