# Prerequisites for scene3d_test_plan.md

## Required Project State

- A Godot 4.x project with the Godot MCP plugin active and connected to the MCP server.
- A 3D scene must be open in the editor at **`res://test_scenes/scene3d_test.tscn`** with a **`Node3D`** root node.
- The project must use the **Forward+** or **Mobile** renderer (3D tools require 3D rendering backend).

## Required Scenes

### Primary test scene: `res://test_scenes/scene3d_test.tscn`

The scene must contain the following node hierarchy:

```
Node3D (scene root)
├── WorldEnvironment              # Required for setup_environment tests (4.1–4.6, 4.9, 4.10)
├── MeshInstance3D                # Required for set_material_3d tests (6.1, 6.3, 6.5, 6.8)
├── Camera3D                      # Required for set_material_3d error test (6.9 — non-mesh target)
├── Player                        # Node3D — parent for child tests
│   ├── Camera3D                  # Required for setup_camera_3d test (2.3 — existing camera config)
│   └── Model                     # MeshInstance3D — required for set_material_3d test (6.2 — PBR properties)
├── Lights                        # Node3D — parent for lighting child test
└── Level                         # Node3D — parent for nested tests
    ├── Floor1                    # Node3D — parent for GridMap child test (5.2)
    └── Props                     # Node3D
        └── Crate                 # Node3D
            └── Cube              # MeshInstance3D — required for set_material_3d deep-path test (6.4)
```

### Node details

| Node path | Type | Notes |
|-----------|------|-------|
| `.` (root) | `Node3D` | Scene root; anchors all 3D children. |
| `WorldEnvironment` | `WorldEnvironment` | Must exist BEFORE setup_environment tests run. Default environment is fine. |
| `MeshInstance3D` | `MeshInstance3D` | Must exist BEFORE set_material_3d tests run. Any mesh type is fine. |
| `Camera3D` | `Camera3D` | Required for error test 6.9 (non-MeshInstance3D target for set_material_3d). |
| `Player` | `Node3D` | Parent container. |
| `Player/Camera3D` | `Camera3D` | Required for test 2.3 (configure existing camera at path). |
| `Player/Model` | `MeshInstance3D` | Required for test 6.2 (metallic/roughness on nested mesh). |
| `Lights` | `Node3D` | Parent container for "Lights" child test (3.2). |
| `Level/Floor1` | `Node3D` | Parent container for GridMap child test (5.2). |
| `Level/Props/Crate/Cube` | `MeshInstance3D` | Required for test 6.4 (deeply nested path material). |

## Required Resources

Resources must exist on disk BEFORE the test that references them:

| Resource path | Type | Required by | Notes |
|---------------|------|-------------|-------|
| `res://materials/red.tres` | `Material` (any) | Test 1.8 | Must be a valid Material resource. Simplest: create a `StandardMaterial3D` with red albedo. |
| `res://assets/mesh_library.tres` | `MeshLibrary` | Test 5.3 | Must be a valid MeshLibrary resource. Can be empty/default. |
| `res://assets/tiles.tres` | `MeshLibrary` | Test 5.5 | Must be a valid MeshLibrary resource. Can be empty/default. |
| `res://shaders/toon.gdshader` | `Shader` (`canvas_item` or `spatial`) | Test 6.3 | Must be a valid `.gdshader` file. Simplest: a `spatial` shader with default `shader_type spatial;`. |

### Resource creation details

**`res://materials/red.tres`** — Created via `create_resource` with type `StandardMaterial3D` and `albedo_color: Color(1, 0, 0, 1)`.

**`res://assets/mesh_library.tres`** and **`res://assets/tiles.tres`** — Created via `create_resource` with type `MeshLibrary`. Both can be empty (default) MeshLibrary resources.

**`res://shaders/toon.gdshader`** — Created via `create_shader` with type `spatial` and minimal content:
```gdshader
shader_type spatial;
```

## Required Editor/Game State

- **Editor must be in edit mode** (not play mode). All scene3d tools operate on the editor scene tree, not the runtime tree.
- **No game running**. `play_scene` must NOT be active.
- **The test scene (`res://test_scenes/scene3d_test.tscn`) must be the active/open scene** in the editor. Use `open_scene` before running tests.
- **No editor dialogs blocking**. The scene must be fully loaded and editable.

## Required Settings/Config

- No specific `project.godot` settings are required beyond defaults for a 3D project.
- No input actions are needed.
- No autoloads beyond the MCP plugin's built-in autoload are needed.
- No custom collision layers are needed.
- No addons beyond `godot_mcp` are required.

## Test Execution Order

The test plan specifies this order to satisfy dependencies naturally:

| Step | Action | What it creates |
|------|--------|-----------------|
| 1 | `create_scene("res://test_scenes/scene3d_test.tscn", root="Node3D")` | Base 3D scene |
| 2 | `add_node(parent="", type="WorldEnvironment", name="WorldEnvironment")` | WorldEnvironment for env tests |
| 3 | `add_node(parent="", type="MeshInstance3D", name="MeshInstance3D")` | MeshInstance3D for material tests |
| 4 | `add_node(parent="", type="Camera3D", name="Camera3D")` | Camera3D for error test 6.9 |
| 5 | `add_node(parent="", type="Node3D", name="Player")` | Parent for Player subtree |
| 6 | `add_node(parent="Player", type="Camera3D", name="Camera3D")` | Existing camera for test 2.3 |
| 7 | `add_node(parent="Player", type="MeshInstance3D", name="Model")` | Mesh for test 6.2 |
| 8 | `add_node(parent="", type="Node3D", name="Lights")` | Parent for light test 3.2 |
| 9 | `add_node(parent="", type="Node3D", name="Level")` | Root of nested path |
| 10 | `add_node(parent="Level", type="Node3D", name="Floor1")` | GridMap parent 5.2 |
| 11 | `add_node(parent="Level", type="Node3D", name="Props")` | Intermediate container |
| 12 | `add_node(parent="Level/Props", type="Node3D", name="Crate")` | Intermediate container |
| 13 | `add_node(parent="Level/Props/Crate", type="MeshInstance3D", name="Cube")` | Mesh for test 6.4 |
| 14 | `create_resource(type="StandardMaterial3D", path="res://materials/red.tres", properties={albedo_color: Color(1,0,0,1)})` | Material for test 1.8 |
| 15 | `create_resource(type="MeshLibrary", path="res://assets/mesh_library.tres")` | MeshLibrary for test 5.3 |
| 16 | `create_resource(type="MeshLibrary", path="res://assets/tiles.tres")` | MeshLibrary for test 5.5 |
| 17 | `create_shader(path="res://shaders/toon.gdshader", type="spatial", content="shader_type spatial;")` | Shader for test 6.3 |

## Setup Script

```gdscript
# Executed via execute_editor_script — creates all prerequisites for scene3d tests.
# Run this BEFORE executing any scene3d test.

@tool
extends EditorScript

func _run() -> void:
	var root: Node
	
	# 1. Create or open the test scene
	var scene_path: String = "res://test_scenes/scene3d_test.tscn"
	if not FileAccess.file_exists(scene_path):
		DirAccess.make_dir_recursive_absolute("res://test_scenes")
		var packed: PackedScene = PackedScene.new()
		root = Node3D.new()
		root.name = "Scene3DTest"
		packed.pack(root)
		ResourceSaver.save(packed, scene_path)
		root.queue_free()
	
	var editor: EditorInterface = get_editor_interface()
	editor.open_scene_from_path(scene_path)
	
	# Wait a frame
	await get_tree().process_frame
	
	root = editor.get_edited_scene_root()
	if root == null:
		printerr("No scene open")
		return
	
	# Helper to add a node
	var undo_redo: EditorUndoRedoManager = editor.get_undo_redo()
	
	func add_child(parent: Node, p_type: String, p_name: String, p_instance = null) -> Node:
		var n: Node
		if p_instance != null:
			n = ClassDB.instantiate(p_type) if p_instance == null else p_instance
		n = ClassDB.instantiate(p_type)
		n.name = p_name
		undo_redo.create_action("Add " + p_name)
		undo_redo.add_do_method(parent, "add_child", n, true)
		undo_redo.add_do_property(n, "owner", root)
		undo_redo.add_undo_method(parent, "remove_child", n)
		undo_redo.commit_action()
		return n
	
	# 2. Add WorldEnvironment
	var we: WorldEnvironment = ClassDB.instantiate("WorldEnvironment")
	we.name = "WorldEnvironment"
	undo_redo.create_action("Add WorldEnvironment")
	undo_redo.add_do_method(root, "add_child", we, true)
	undo_redo.add_do_property(we, "owner", root)
	undo_redo.commit_action()
	
	# 3. Add MeshInstance3D at root
	var mi: MeshInstance3D = ClassDB.instantiate("MeshInstance3D")
	mi.name = "MeshInstance3D"
	mi.mesh = BoxMesh.new()
	undo_redo.create_action("Add MeshInstance3D")
	undo_redo.add_do_method(root, "add_child", mi, true)
	undo_redo.add_do_property(mi, "owner", root)
	undo_redo.commit_action()
	
	# 4. Add Camera3D at root (for error test 6.9)
	var cam: Camera3D = ClassDB.instantiate("Camera3D")
	cam.name = "Camera3D"
	undo_redo.create_action("Add Camera3D")
	undo_redo.add_do_method(root, "add_child", cam, true)
	undo_redo.add_do_property(cam, "owner", root)
	undo_redo.commit_action()
	
	# 5. Create Player subtree
	var player: Node3D = ClassDB.instantiate("Node3D")
	player.name = "Player"
	undo_redo.create_action("Add Player")
	undo_redo.add_do_method(root, "add_child", player, true)
	undo_redo.add_do_property(player, "owner", root)
	undo_redo.commit_action()
	
	var player_cam: Camera3D = ClassDB.instantiate("Camera3D")
	player_cam.name = "Camera3D"
	undo_redo.create_action("Add Player/Camera3D")
	undo_redo.add_do_method(player, "add_child", player_cam, true)
	undo_redo.add_do_property(player_cam, "owner", root)
	undo_redo.commit_action()
	
	var player_model: MeshInstance3D = ClassDB.instantiate("MeshInstance3D")
	player_model.name = "Model"
	player_model.mesh = BoxMesh.new()
	undo_redo.create_action("Add Player/Model")
	undo_redo.add_do_method(player, "add_child", player_model, true)
	undo_redo.add_do_property(player_model, "owner", root)
	undo_redo.commit_action()
	
	# 6. Create Lights container
	var lights: Node3D = ClassDB.instantiate("Node3D")
	lights.name = "Lights"
	undo_redo.create_action("Add Lights")
	undo_redo.add_do_method(root, "add_child", lights, true)
	undo_redo.add_do_property(lights, "owner", root)
	undo_redo.commit_action()
	
	# 7. Create Level/Floor1 subtree
	var level: Node3D = ClassDB.instantiate("Node3D")
	level.name = "Level"
	undo_redo.create_action("Add Level")
	undo_redo.add_do_method(root, "add_child", level, true)
	undo_redo.add_do_property(level, "owner", root)
	undo_redo.commit_action()
	
	var floor1: Node3D = ClassDB.instantiate("Node3D")
	floor1.name = "Floor1"
	undo_redo.create_action("Add Level/Floor1")
	undo_redo.add_do_method(level, "add_child", floor1, true)
	undo_redo.add_do_property(floor1, "owner", root)
	undo_redo.commit_action()
	
	var props: Node3D = ClassDB.instantiate("Node3D")
	props.name = "Props"
	undo_redo.create_action("Add Level/Props")
	undo_redo.add_do_method(level, "add_child", props, true)
	undo_redo.add_do_property(props, "owner", root)
	undo_redo.commit_action()
	
	var crate: Node3D = ClassDB.instantiate("Node3D")
	crate.name = "Crate"
	undo_redo.create_action("Add Level/Props/Crate")
	undo_redo.add_do_method(props, "add_child", crate, true)
	undo_redo.add_do_property(crate, "owner", root)
	undo_redo.commit_action()
	
	var cube: MeshInstance3D = ClassDB.instantiate("MeshInstance3D")
	cube.name = "Cube"
	cube.mesh = BoxMesh.new()
	undo_redo.create_action("Add Level/Props/Crate/Cube")
	undo_redo.add_do_method(crate, "add_child", cube, true)
	undo_redo.add_do_property(cube, "owner", root)
	undo_redo.commit_action()
	
	# 8. Create Material resource for test 1.8
	DirAccess.make_dir_recursive_absolute("res://materials")
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.0, 0.0, 1.0)
	ResourceSaver.save(mat, "res://materials/red.tres")
	
	# 9. Create MeshLibrary resources for tests 5.3 and 5.5
	DirAccess.make_dir_recursive_absolute("res://assets")
	var lib1: MeshLibrary = MeshLibrary.new()
	ResourceSaver.save(lib1, "res://assets/mesh_library.tres")
	
	var lib2: MeshLibrary = MeshLibrary.new()
	ResourceSaver.save(lib2, "res://assets/tiles.tres")
	
	# 10. Create shader for test 6.3
	DirAccess.make_dir_recursive_absolute("res://shaders")
	var shader_file: FileAccess = FileAccess.open("res://shaders/toon.gdshader", FileAccess.WRITE)
	shader_file.store_string("shader_type spatial;\n")
	shader_file.close()
	
	# 11. Save scene
	editor.save_scene()
	
	print("scene3d test prerequisites complete!")
```

> **Note:** The setup script is a GDScript `EditorScript`. It can also be constructed as a series of MCP tool calls using `create_scene`, `add_node`, `create_resource`, and `create_shader` — see the "Test Execution Order" table above for the MCP-equivalent call sequence.
