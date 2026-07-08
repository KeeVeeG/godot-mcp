# Prerequisites for Node Config Tests

**Source plan:** `server/src/test_plans/node_config_test_plan.md`
**Tools covered:** 8 (`get_node_default_properties`, `set_node_preset`, `get_available_node_types`, `get_node_signals`, `get_node_methods`, `get_node_enums`, `get_node_constants`, `get_class_hierarchy`)
**Total scenarios:** 55

---

## Cross-Cutting Prerequisites (All Tests)

These must be true for **every** scenario in this test plan:

- **Godot editor running**: Godot 4.x editor process is running.
- **MCP plugin active**: The `godot_mcp` addon is installed and enabled (Project Settings > Plugins > Godot MCP > Active).
- **MCP server connected**: The Node.js MCP server (`server/dist/index.js`) is running and has established a WebSocket connection to the Godot plugin. The MCP panel in Godot's bottom dock shows "Connected".
- **No compilation errors in project**: `get_editor_errors` returns no errors that would block tool execution.
- **No modal dialogs blocking the editor**: The plugin can auto-dismiss gameplay dialogs, but editor-blocking dialogs (save prompts, crash reporters) will cause tool timeouts.

---

## Required Project State

| # | Requirement | Why | Affected Scenarios |
|---|---|---|---|
| P1 | Any Godot project (empty 2D/3D/UI template all work) | Most tools query built-in engine types by name — no project-specific assets needed. | All except those below |
| P2 | A **custom GDScript class registered as a global class named `Player`** | `get_node_default_properties` S4 tests querying defaults for a user-defined class. Without this, S4 will return a Godot-side error (which is documented as acceptable, but the "success" path requires it). | `get_node_default_properties` S4 |
| P3 | Project **must NOT** have a global class named `NonExistentNodeXYZ`, `TotallyFakeTypeXYZ`, `FakeNodeType999`, `InvalidNodeXYZ`, `NonExistentNodeABC`, `FakeNodeXYZ`, `TotallyMadeUp123` | Multiple error-path scenarios test that querying non-existent types returns a Godot-side error. | `get_node_default_properties` S5; `set_node_preset` S5; `get_node_signals` S8; `get_node_methods` S5; `get_node_enums` S4; `get_node_constants` S4; `get_class_hierarchy` S7 |

---

## Required Scenes

Exactly **one scene** must be open in the editor. This scene serves all path-based `get_node_signals` tests.

### Scene file: `res://scenes/test_node_config.tscn`

```
Node2D (root, name: "TestNodeConfigScene")
├── Node (name: "Player")             ← get_node_signals S3, S5
└── Node (name: "OtherNode")          ← filler for hierarchy depth
```

**Required node properties:**

| Node Path | Type | Properties |
|---|---|---|
| `""` (root) | `Node2D` | Default properties. Name can be anything — the scene root is referenced via empty string path `""`. |
| `"Player"` | `Node` | Name must be exactly `"Player"`. Class type can be `Node` (any type works; the tool resolves the class dynamically). |
| `"OtherNode"` | `Node` | Filler — just ensures the scene has depth. |

**Why this structure matters:**

| Scenario | What's tested | Requirement |
|---|---|---|
| `get_node_signals` S3 | Query signals by path `"Player"` | A node named `Player` must exist at the root level of the currently open scene. |
| `get_node_signals` S5 | Both `type` and `path` provided | Same `Player` node is used. The test observes whether `type` or `path` takes precedence. |
| `get_node_signals` S7 | Empty string path `""` resolves to scene root | A scene must be open so the empty-string-shortcut resolves to its root node (here `Node2D`). |
| `get_node_signals` S9 | Path to non-existent node `"NonExistentNode/Child123"` | A scene must be open, but the specific path must NOT exist. This scene satisfies that since no node with that name exists. |

---

## Required Resources

| # | Resource Path | Type | Content | Why | Affected Scenarios |
|---|---|---|---|---|---|
| R1 | `res://scripts/player.gd` | GDScript file | A script with `class_name Player extends Node` (or any base class). Must be registered as a global class so `ProjectSettings.get_global_class_list()` includes `Player`. | `get_node_default_properties` S4 — tests querying defaults for a user-defined class name. | `get_node_default_properties` S4 |

**`res://scripts/player.gd` minimal content:**

```gdscript
class_name Player
extends Node


func _ready() -> void:
    pass
```

This is the minimal GDScript needed to register `Player` as a global class name. The script itself does not need to be attached to any node.

---

## Required Editor/Game State

| # | State | Value | Why | Affected Scenarios |
|---|---|---|---|---|
| E1 | **Scene open in editor** | `res://scenes/test_node_config.tscn` must be the active/currently-open scene | Required for all `get_node_signals` path-based scenarios (S3, S5, S7, S9). | `get_node_signals` S3, S5, S7, S9 |
| E2 | **Play mode** | Play mode is **OFF** (editor is stopped) | None of the node config tools require play mode. All operate on editor-time type introspection, which does not need a running game. All tests can run in edit mode. | All (by being off) |
| E3 | **No breakpoints set** | No active breakpoints in any script | Breakpoints are irrelevant to node config tools. Ensure no leftover breakpoints from debugging sessions. | All (by being absent) |
| E4 | **No undos pending** | Undo stack can be in any state — node config tools are read-only except `set_node_preset`, which has separate test concerns. | `set_node_preset` S1-S2 modify editor state (they apply presets). After these tests, the project may have changed preset configurations. | `set_node_preset` S1, S2 |

---

## Required Settings/Config

| # | Setting Key | Value | Why |
|---|---|---|---|
| S1 | _(none)_ | — | None of the node config tools depend on project settings, input actions, autoloads (besides the plugin's own `mcp_runtime` autoload), collision layers, or any other `project.godot` configuration. |

**Note on autoloads:** The `mcp_runtime` autoload is installed by the plugin and is required for the MCP bridge to function in general. It is part of the cross-cutting prerequisites, not a test-specific setting. No additional autoloads are needed.

---

## External State

| # | Requirement | Why |
|---|---|---|
| X1 | No addons beyond `godot_mcp` are required | Node config tools only query the Godot engine's built-in type system. They do not depend on third-party addons. |
| X2 | No git repository required | The tools do not interact with version control. |
| X3 | No external packages required | All tested types (`Sprite2D`, `CharacterBody3D`, `Button`, `AnimationPlayer`, `BoxContainer`, `InputEventKey`, `BaseButton`, `Panel`, `Node`, `Resource`, `Object`, `Camera3D`, `CharacterBody2D`) are built into the Godot engine. |
| X4 | No network access required | All tools operate locally within the editor process. |

---

## Setup Script

Run this GDScript in the editor (via `execute_editor_script`) to create all prerequisites in one pass:

```gdscript
@tool
extends EditorScript

func _run() -> void:
    # 1. Create the test scene with the required hierarchy
    var root := Node2D.new()
    root.name = "TestNodeConfigScene"
    
    var player := Node.new()
    player.name = "Player"
    root.add_child(player)
    
    var other := Node.new()
    other.name = "OtherNode"
    root.add_child(other)
    
    # Pack into a scene and save
    var packed := PackedScene.new()
    packed.pack(root)
    ResourceSaver.save(packed, "res://scenes/test_node_config.tscn")
    
    # Free the temporary nodes
    root.free()
    
    print("[Prereqs] Created res://scenes/test_node_config.tscn")
    
    # 2. Create the Player global class script
    var script_code := """class_name Player
extends Node


func _ready() -> void:
    pass
"""
    var script_path := "res://scripts/player.gd"
    var file := FileAccess.open(script_path, FileAccess.WRITE)
    if file:
        file.store_string(script_code)
        file.close()
        print("[Prereqs] Created ", script_path)
    else:
        printerr("[Prereqs] Failed to create ", script_path)
    
    # 3. Ensure directories exist (FileAccess will fail if dir doesn't exist)
    DirAccess.make_dir_recursive_absolute("res://scenes")
    DirAccess.make_dir_recursive_absolute("res://scripts")
    
    # 4. Refresh the filesystem so Godot picks up the new files
    EditorInterface.get_resource_filesystem().scan()
    
    # 5. Open the test scene
    EditorInterface.open_scene_from_path("res://scenes/test_node_config.tscn")
    
    print("[Prereqs] Setup complete. Test scene is open.")
    player.free()
    other.free()
```

**Post-setup verification checklist:**

- [ ] `res://scenes/test_node_config.tscn` exists and is open in the editor
- [ ] Scene root is a `Node2D` named `TestNodeConfigScene`
- [ ] Root has a direct child `Node` named exactly `Player`
- [ ] `res://scripts/player.gd` exists with `class_name Player` and `extends Node`
- [ ] `Player` appears in the global class list (verify via `get_available_node_types` or `get_class_hierarchy("Player")` succeeding)
- [ ] No compilation errors (`get_editor_errors` returns `[]`)
- [ ] MCP panel shows "Connected"

---

## Scenario-to-Prerequisite Mapping

Quick reference for which scenario needs which prerequisite:

| Tool | Scenario | Prerequisites |
|---|---|---|
| `get_node_default_properties` | S1-S3, S5-S9 | Cross-cutting only |
| `get_node_default_properties` | S4 | Cross-cutting + **P2** (global class `Player`) + **R1** |
| `set_node_preset` | S1-S9 | Cross-cutting only |
| `get_available_node_types` | S1-S11 | Cross-cutting only |
| `get_node_signals` | S1, S2, S4, S6, S8, S10 | Cross-cutting only |
| `get_node_signals` | S3, S5 | Cross-cutting + **E1** (scene open) + node `Player` exists |
| `get_node_signals` | S7 | Cross-cutting + **E1** (scene open, root exists) |
| `get_node_signals` | S9 | Cross-cutting + **E1** (scene open, path absent) |
| `get_node_methods` | S1-S8 | Cross-cutting only |
| `get_node_enums` | S1-S6 | Cross-cutting only |
| `get_node_constants` | S1-S6 | Cross-cutting only |
| `get_class_hierarchy` | S1-S10 | Cross-cutting only |

---

## Minimal Setup (Quick Smoke Test)

If you only want to run the happy-path scenarios (20 scenarios) and skip the path-dependent `get_node_signals` scenarios, the only prerequisite is:

> A running Godot editor with the MCP plugin connected to an empty project.

For **full coverage** (all 55 scenarios), you additionally need:
1. A scene open with a `Player` node — the setup script above creates this.
2. A `Player` global class registered — the setup script above creates this.
