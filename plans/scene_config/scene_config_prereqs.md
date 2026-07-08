# Prerequisites for Scene Config Tools Test Plan

> Derived from `scene_config_test_plan.md` — 60 scenarios across 6 tools + 4 integration tests.

---

## Required Project State

- Godot 4.x editor running with the MCP plugin **connected** (WebSocket bridge active)
- A Godot project loaded (any type — 2D or 3D)
- MCP server running and connected to the client (Zod validation errors are server-side; Godot-side errors require the bridge)
- **Test isolation**: Mutating tools (`set_scene_unique_name`, `set_scene_group`, `set_scene_meta`) assume a clean/disposable scene. Re-create or reset the scene before running these tests.
- A second scene file must exist on disk at `res://scenes/main.tscn` (used by `get_scene_inheritance` scenario 3, `get_scene_groups` scenario 3, `get_scene_meta` scenario 3, and `set_scene_meta` scenario 16)
- A GDScript file must exist at `res://scripts/some_script.gd` (used by `get_scene_inheritance` scenario 5, `get_scene_groups` scenario 5, `get_scene_meta` scenario 5)

---

## Required Scenes

### Scene A: Test Scene (the currently-open scene)

This is the primary scene used by most scenarios. It must be open in the editor when tests run.

**Root node:** `Node2D` or `Node3D` (either works; `Node2D` recommended for simplicity)

```
Root (Node2D or Node3D)
├── TestNode (Node)
├── AnotherNode (Node)
└── Parent (Node)
    └── Child (Node)
        └── Grandchild (Node)
```

| Node            | Type              | Purpose / Used By |
|-----------------|-------------------|-------------------|
| Root            | `Node2D`/`Node3D` | `set_scene_unique_name` scenario 2 (root path `""`), `set_scene_group` scenario 4 (`node_path: ""`), `set_scene_meta` and `get_scene_meta` (metadata lives on root) |
| `TestNode`      | `Node`            | Primary test target — used in nearly every `set_scene_unique_name`, `set_scene_group`, and integration scenario |
| `AnotherNode`   | `Node`            | `set_scene_group` scenario 6 (shared group with `TestNode`), Integration Scenario I |
| `Parent`        | `Node`            | Parent for nested tests |
| `Parent/Child`  | `Node`            | `set_scene_unique_name` scenario 3 (nested path), `set_scene_group` scenario 5 (nested path) |
| `Parent/Child/Grandchild` | `Node` | `set_scene_unique_name` scenario 3 (deeply nested path) |

**Initial state requirements:**
- **No nodes belong to any test groups** before execution. Specifically, groups named `test_group_a`, `test_group_add_1`, `test_group_add_2`, `test_group_remove`, `root_group`, `shared_group`, `ghost_group`, `idem_group`, `nested_group`, `lifecycle_group`, `integration_group`, `unique_group_node` must not exist on any node.
- **No custom metadata** exists on the scene root node. A fresh scene is ideal.
- `TestNode` does **NOT** have the unique name flag enabled (default state).

### Scene B: `res://scenes/main.tscn` (secondary scene)

Used for `scene_path`-based tests that target a different scene. Can be any valid `.tscn` file — even a minimal scene with a single `Node2D` root.

**Minimum content:**
```
Root (Node2D)
```

**Purpose:**
- `get_scene_inheritance` scenario 3: query inheritance via path
- `get_scene_groups` scenario 3: query groups via path
- `get_scene_meta` scenario 3: query metadata via path
- `set_scene_meta` scenario 16: attempt to set metadata on non-current scene (error expected)

---

## Required Resources

### Scene files on disk
| Path | Content | Purpose |
|------|---------|---------|
| `res://scenes/main.tscn` | Any valid scene (minimal `Node2D` root) | `scene_path` parameter tests |

### Script files on disk
| Path | Content | Purpose |
|------|---------|---------|
| `res://scripts/some_script.gd` | Any valid GDScript (e.g., `extends Node`) | Negative tests — passing a `.gd` path where a `.tscn` is expected |

### Other resources
- None required. No textures, materials, shaders, audio files, or `.tres`/`.res` files are needed for these tests.

---

## Required Editor/Game State

| State | Value | Purpose |
|-------|-------|---------|
| Scene open in editor | Scene A (see above) | All `node_path`-based and current-scene tests |
| Play mode | **Stopped** (not running) | All tools in this plan are editor-mode only |
| Editor layout | Any (not relevant) | No layout-specific requirements |
| Selected tool | Any (not relevant) | No tool-specific requirements |
| Breakpoints | None needed | No debugging tests |
| Undo stack | Not relevant (all tests read output, not undo state) | |

---

## Required Settings/Config

| Setting | Value | Purpose |
|---------|-------|---------|
| Project type | Any (2D or 3D) | No dimensional constraints |
| Main scene | Not required | Tests don't rely on the main scene |
| Autoloads | Default only (`mcp_runtime`) | No custom autoloads needed |
| Input actions | Default only | No input simulation in these tests |
| Collision layers | Default only | No physics in these tests |
| Addons | Only `godot_mcp` plugin | No third-party addons needed |
| Git repo | Not required | No git operations in these tests |
| platform/export settings | Default only | No export in these tests |

---

## Setup Script

Run this GDScript in the Godot editor (`godot_execute_editor_script`) to create all prerequisites. It:

1. Creates the test scene hierarchy (Scene A)
2. Saves it as the open scene
3. Creates a minimal secondary scene at `res://scenes/main.tscn` (Scene B)
4. Creates a dummy script at `res://scripts/some_script.gd`

```gdscript
# Setup script for scene_config tests
# Run via: godot_execute_editor_script with this code

# 1. Create directories if missing
var dir = DirAccess.open("res://")
if not dir.dir_exists("res://scenes"):
	dir.make_dir("res://scenes")
if not dir.dir_exists("res://scripts"):
	dir.make_dir("res://scripts")

# 2. Create Scene A: test scene with required hierarchy
var test_scene = PackedScene.new()
var root = Node2D.new()
root.name = "Root"

var test_node = Node.new()
test_node.name = "TestNode"
root.add_child(test_node)
test_node.set_owner(root)

var another_node = Node.new()
another_node.name = "AnotherNode"
root.add_child(another_node)
another_node.set_owner(root)

var parent = Node.new()
parent.name = "Parent"
root.add_child(parent)
parent.set_owner(root)

var child = Node.new()
child.name = "Child"
parent.add_child(child)
child.set_owner(parent)

var grandchild = Node.new()
grandchild.name = "Grandchild"
child.add_child(grandchild)
grandchild.set_owner(child)

var result = test_scene.pack(root)
if result != OK:
	printerr("Failed to pack test scene: ", result)
else:
	ResourceSaver.save(test_scene, "res://scenes/test_scene.tscn")
	print("Test scene saved to res://scenes/test_scene.tscn")

# 3. Create Scene B: minimal secondary scene at res://scenes/main.tscn
var second_scene = PackedScene.new()
var second_root = Node2D.new()
second_root.name = "MainScene"
var pack_result = second_scene.pack(second_root)
if pack_result != OK:
	printerr("Failed to pack main scene: ", pack_result)
else:
	ResourceSaver.save(second_scene, "res://scenes/main.tscn")
	print("Secondary scene saved to res://scenes/main.tscn")

# 4. Create dummy script at res://scripts/some_script.gd
var script_file = FileAccess.open("res://scripts/some_script.gd", FileAccess.WRITE)
if script_file:
	script_file.store_string("extends Node\n\nfunc _ready():\n\tpass\n")
	script_file.close()
	print("Dummy script saved to res://scripts/some_script.gd")
else:
	printerr("Failed to create script file")

# 5. Open the test scene
EditorInterface.open_scene_from_path("res://scenes/test_scene.tscn")
print("Setup complete. Test scene is now open in the editor.")
```

After running the setup script, the editor should have `res://scenes/test_scene.tscn` open with the full hierarchy.

---

## Quick Validation Checklist

Before running any tests, verify:

- [ ] MCP plugin shows **Connected** in the Godot MCP panel
- [ ] Test scene is open with: `Root` → `TestNode`, `AnotherNode`, `Parent/Child/Grandchild`
- [ ] `res://scenes/main.tscn` exists on disk (any content)
- [ ] `res://scripts/some_script.gd` exists on disk (any content)
- [ ] No test groups exist on any node (verify with `get_scene_groups`)
- [ ] Play mode is **stopped**
