# Prerequisites for Analysis Tools Test Plan

> **Source plan:** `server/src/test_plans/analysis_test_plan.md`
> **Tools covered:** `analyze_scene_complexity`, `analyze_signal_flow`, `find_unused_resources`, `get_project_statistics`

---

## Required Project State

- **Godot 4.x project** with the `godot_mcp` addon installed and active (plugin enabled in Project Settings → Plugins)
- **MCP WebSocket bridge** operational: MCP server running and connected to the Godot editor plugin
- **Godot editor not connected** state: for disconnect-error scenarios (Scenarios 4 in each tool), the MCP server must be running but the Godot editor must be closed (or bridge severed)
- For `get_project_statistics` Scenario 3: A **second project** — a brand-new, minimal Godot project created with template `"empty"`, containing only the default `project.godot` and the MCP addon (no user scenes, no user scripts, no user resources)

---

## Required Scenes

### Scene A: Moderately Complex Scene (for `analyze_scene_complexity` S1–S2, `analyze_signal_flow` S1, S3)
- **File path:** `res://test_scenes/complex_scene.tscn`
- **Root node:** `Node3D` named `"ComplexRoot"`
- **Hierarchy (minimum):**
  ```
  ComplexRoot (Node3D)
  ├── Camera3D (named "MainCamera")
  ├── DirectionalLight3D (named "Sun")
  ├── Player (CharacterBody3D)
  │   ├── MeshInstance3D (cube, with StandardMaterial3D assigned)
  │   ├── CollisionShape3D (box shape)
  │   └── AnimationPlayer (named "AnimationPlayer", with at least 1 animation clip)
  ├── Enemies (Node3D)
  │   ├── Enemy1 (CharacterBody3D)
  │   │   ├── MeshInstance3D (sphere)
  │   │   └── CollisionShape3D (sphere shape)
  │   └── Enemy2 (CharacterBody3D)
  │       ├── MeshInstance3D (sphere)
  │       └── CollisionShape3D (sphere shape)
  ├── WorldEnvironment (named "WorldEnvironment")
  └── UI (CanvasLayer)
      └── Control
          └── Button (named "StartButton")
  ```
- **Signal connections (minimum):**
  - `StartButton.pressed` → `Player` script method `_on_start_button_pressed()`
  - `Player` script must be attached at `res://test_scenes/player.gd`
- **Properties of note:**
  - Player has `collision_layer=1`, `collision_mask=1`
  - `StartButton` text: `"Start"`

### Scene B: Simple Static Scene (for `analyze_signal_flow` S2 — zero signal connections)
- **File path:** `res://test_scenes/static_scene.tscn`
- **Root node:** `Node2D` named `"StaticRoot"`
- **Hierarchy:**
  ```
  StaticRoot (Node2D)
  ├── Sprite2D (named "Background")
  ├── Sprite2D (named "Platform")
  └── Label (named "TitleLabel", text: "Static Scene")
  ```
- **No signal connections at all** — all nodes are purely static with no scripts or signal wiring.

### Scene C: Empty Scene (for `analyze_scene_complexity` S3 — no scene open)
- **No scene open in the editor.** The editor must have all scenes closed so no active scene exists.

---

## Required Resources

### For `find_unused_resources` Scenario 1 (unused resources exist)
The following orphaned files must exist in the project but must NOT be referenced by any scene or script:

| Resource | Path | Type |
|----------|------|------|
| Orphaned material | `res://test_resources/orphaned_material.tres` | `StandardMaterial3D` with `albedo_color = Color.RED` |
| Orphaned script | `res://test_resources/orphaned_script.gd` | GDScript `extends Node` with a single `func hello(): print("orphan")` |
| Orphaned texture | `res://test_resources/orphaned_icon.png` | Any PNG image (can be a 1x1 pixel placeholder) |
| Orphaned theme | `res://test_resources/orphaned_theme.tres` | `Theme` resource |
| Orphaned shader | `res://test_resources/orphaned_shader.gdshader` | `canvas_item` shader with trivial `void fragment() { COLOR = vec4(1.0); }` |

### For `find_unused_resources` Scenario 2 (zero unused resources)
- All resources in the project must be referenced by at least one scene or script.
- The project directory `res://test_resources/` must NOT exist (or must be empty if it does).
- This can be satisfied by using the empty project from `get_project_statistics` Scenario 3.

---

## Required Editor/Game State

- **Editor with scene open** (for all happy-path scenarios of `analyze_scene_complexity` and `analyze_signal_flow`): The editor must have a scene loaded and visible.
- **Editor with NO scene open** (for `analyze_scene_complexity` Scenario 3): All scenes closed, empty editor viewport.
- **Godot editor running + MCP connected** (for all happy-path scenarios and extra-params scenarios).
- **Godot editor NOT running / bridge disconnected** (for all "Godot editor not connected" scenarios):
  - Option A: Godot editor fully closed, MCP server still running
  - Option B: Godot editor running but MCP plugin not active / bridge intentionally severed

---

## Required Settings/Config

- **Project setting:** MCP addon must be registered in `project.godot`:
  ```ini
  [autoload]
  mcp_runtime="res://addons/godot_mcp/services/mcp_runtime.gd"
  ```
- **Plugin state:** `godot_mcp` plugin enabled in `project.godot`:
  ```ini
  [editor_plugins]
  enabled=PackedStringArray("res://addons/godot_mcp/plugin.cfg")
  ```
- **No specific input actions, collision layers, or custom project settings** are required by the analysis tools beyond the defaults.
- **No autoloads** other than the MCP runtime are required.

---

## Required Scripts

### `res://test_scenes/player.gd`
Must be attached to the `Player` node in Scene A to accept the `StartButton.pressed` signal.

```gdscript
extends CharacterBody3D

func _on_start_button_pressed() -> void:
	print("Start button pressed!")
```

---

## Setup Script (GDScript)

Use the following via `execute_editor_script` to create all prerequisites when running against a fresh project. Assumes the MCP addon is already installed and active.

```gdscript
# === analysis_prereqs_setup.gd ===
# Run this as an EditorScript via godot_execute_editor_script
# Creates all scenes, resources, and scripts needed for analysis test plan execution.

@tool
extends EditorScript

func _run() -> void:
	# ---------- Create directories ----------
	_ensure_dir("res://test_scenes")
	_ensure_dir("res://test_resources")

	# ---------- Create player script ----------
	var player_script := GDScript.new()
	player_script.source_code = """extends CharacterBody3D

func _on_start_button_pressed() -> void:
	print("Start button pressed!")
"""
	ResourceSaver.save(player_script, "res://test_scenes/player.gd")
	print("[OK] Created res://test_scenes/player.gd")

	# ---------- Scene A: complex_scene.tscn ----------
	var root_a := Node3D.new()
	root_a.name = "ComplexRoot"

	# Camera3D
	var cam := Camera3D.new()
	cam.name = "MainCamera"
	cam.position = Vector3(0, 2, 5)
	root_a.add_child(cam)
	cam.owner = root_a

	# DirectionalLight3D
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.position = Vector3(5, 10, 0)
	light.rotation_degrees = Vector3(-45, -30, 0)
	root_a.add_child(light)
	light.owner = root_a

	# Player (CharacterBody3D)
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.collision_layer = 1
	player.collision_mask = 1
	var player_script_res := load("res://test_scenes/player.gd")
	player.set_script(player_script_res)

	var player_mesh := MeshInstance3D.new()
	player_mesh.name = "MeshInstance3D"
	player_mesh.mesh = BoxMesh.new()
	var player_mat := StandardMaterial3D.new()
	player_mat.albedo_color = Color.BLUE
	player_mesh.set_surface_override_material(0, player_mat)
	player.add_child(player_mesh)
	player_mesh.owner = player

	var player_coll := CollisionShape3D.new()
	player_coll.name = "CollisionShape3D"
	player_coll.shape = BoxShape3D.new()
	player.add_child(player_coll)
	player_coll.owner = player

	var anim_player := AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	player.add_child(anim_player)
	anim_player.owner = player

	root_a.add_child(player)
	player.owner = root_a

	# Enemies container
	var enemies := Node3D.new()
	enemies.name = "Enemies"

	for i in range(1, 3):
		var enemy := CharacterBody3D.new()
		enemy.name = "Enemy%d" % i
		var enemy_mesh := MeshInstance3D.new()
		enemy_mesh.name = "MeshInstance3D"
		enemy_mesh.mesh = SphereMesh.new()
		var enemy_coll := CollisionShape3D.new()
		enemy_coll.name = "CollisionShape3D"
		enemy_coll.shape = SphereShape3D.new()
		enemy.add_child(enemy_mesh)
		enemy_mesh.owner = enemy
		enemy.add_child(enemy_coll)
		enemy_coll.owner = enemy
		enemies.add_child(enemy)
		enemy.owner = enemies

	root_a.add_child(enemies)
	enemies.owner = root_a

	# WorldEnvironment
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	root_a.add_child(world_env)
	world_env.owner = root_a

	# UI Layer
	var canvas := CanvasLayer.new()
	canvas.name = "UI"
	var ui_control := Control.new()
	ui_control.name = "Control"
	var btn := Button.new()
	btn.name = "StartButton"
	btn.text = "Start"
	ui_control.add_child(btn)
	btn.owner = ui_control
	canvas.add_child(ui_control)
	ui_control.owner = canvas
	root_a.add_child(canvas)
	canvas.owner = root_a

	var packed_a := PackedScene.new()
	packed_a.pack(root_a)
	ResourceSaver.save(packed_a, "res://test_scenes/complex_scene.tscn")
	print("[OK] Created res://test_scenes/complex_scene.tscn")

	# Connect StartButton.pressed -> Player._on_start_button_pressed
	# (must be done on the open scene; open it first, then connect)
	var editor := EditorInterface.new()

	# ---------- Scene B: static_scene.tscn (zero signals) ----------
	var root_b := Node2D.new()
	root_b.name = "StaticRoot"

	var bg := Sprite2D.new()
	bg.name = "Background"
	root_b.add_child(bg)
	bg.owner = root_b

	var platform := Sprite2D.new()
	platform.name = "Platform"
	root_b.add_child(platform)
	platform.owner = root_b

	var label := Label.new()
	label.name = "TitleLabel"
	label.text = "Static Scene"
	root_b.add_child(label)
	label.owner = root_b

	var packed_b := PackedScene.new()
	packed_b.pack(root_b)
	ResourceSaver.save(packed_b, "res://test_scenes/static_scene.tscn")
	print("[OK] Created res://test_scenes/static_scene.tscn")

	# ---------- Orphaned resources (not referenced by any scene) ----------
	var orphan_mat := StandardMaterial3D.new()
	orphan_mat.albedo_color = Color.RED
	ResourceSaver.save(orphan_mat, "res://test_resources/orphaned_material.tres")
	print("[OK] Created res://test_resources/orphaned_material.tres")

	var orphan_script := GDScript.new()
	orphan_script.source_code = """extends Node

func hello() -> void:
	print("orphan")
"""
	ResourceSaver.save(orphan_script, "res://test_resources/orphaned_script.gd")
	print("[OK] Created res://test_resources/orphaned_script.gd")

	var orphan_theme := Theme.new()
	ResourceSaver.save(orphan_theme, "res://test_resources/orphaned_theme.tres")
	print("[OK] Created res://test_resources/orphaned_theme.tres")

	# orphaned_texture: create a 1x1 PNG image programmatically
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color.WHITE)
	img.save_png("res://test_resources/orphaned_icon.png")
	print("[OK] Created res://test_resources/orphaned_icon.png")

	var orphan_shader := Shader.new()
	orphan_shader.code = """shader_type canvas_item;

void fragment() {
	COLOR = vec4(1.0);
}
"""
	ResourceSaver.save(orphan_shader, "res://test_resources/orphaned_shader.gdshader")
	print("[OK] Created res://test_resources/orphaned_shader.gdshader")

	# ---------- Connect signal on Scene A ----------
	open_scene_and_connect_signal()

	print("\n=== SETUP COMPLETE ===")

	# Refresh filesystem to pick up new files
	get_editor_interface().get_resource_filesystem().scan()


func _ensure_dir(path: String) -> void:
	var dir := DirAccess.open("res://")
	if not dir.dir_exists(path):
		dir.make_dir_recursive(path)


func open_scene_and_connect_signal() -> void:
	var ei := get_editor_interface()
	ei.open_scene_from_path("res://test_scenes/complex_scene.tscn")
	await ei.get_tree().process_frame

	# Find the button and player
	var scene_root := ei.get_edited_scene_root()
	if scene_root:
		var btn := scene_root.get_node("UI/Control/StartButton") as Button
		var player_node := scene_root.get_node("Player") as CharacterBody3D
		if btn and player_node and player_node.has_method("_on_start_button_pressed"):
			btn.pressed.connect(player_node._on_start_button_pressed)
			ei.mark_scene_as_unsaved()
			ei.save_scene()
			print("[OK] Connected StartButton.pressed -> Player._on_start_button_pressed")
		else:
			print("[WARN] Could not find button or player for signal connection")
```

> **Note:** The setup script above uses `await` which requires Godot 4.x `EditorScript`. If `await` is not supported in your Godot version (EditorScript runs synchronously in some versions), split the signal connection step into a separate script or use `godot_connect_signal` after opening the scene manually.

---

## Test Execution Order Dependencies

Some scenarios can share prerequisites or must be run in a specific sequence:

1. **Godot-connected scenarios** (all Scenario 1, 2, 3 of each tool) must run while Godot is connected.
2. **Godot-disconnected scenarios** (all Scenario 4) must run while Godot is NOT connected — or, if using the same session, these must run last since reconnecting mid-session may not be possible.
3. `find_unused_resources` Scenario 2 (zero unused resources) and `get_project_statistics` Scenario 3 (empty project) can share the same empty project.
4. `analyze_scene_complexity` Scenario 3 (no scene open) requires closing all scenes AFTER the other scene-dependent tests run.

### Recommended execution order:
```
Phase 1 (Godot connected, scene open):
  - analyze_scene_complexity S1, S2  → Scene A open
  - analyze_signal_flow S1, S3       → Scene A open
  - analyze_signal_flow S2           → Scene B open (then switch back to Scene A)
  - find_unused_resources S1, S3     → Scene A open (project has orphaned resources)

Phase 2 (Godot connected, no scene):
  - analyze_scene_complexity S3      → All scenes closed

Phase 3 (Godot connected, empty project):
  - get_project_statistics S3        → Switch to empty project
  - find_unused_resources S2         → Same empty project

Phase 4 (Godot connected, normal project):
  - get_project_statistics S1, S2    → Normal project (Scene A's project)

Phase 5 (Godot disconnected):
  - analyze_scene_complexity S4
  - analyze_signal_flow S4
  - find_unused_resources S4
  - get_project_statistics S4
```
