# Prerequisites for Runtime Tools Test Plan

**Source plan:** `server/src/test_plans/runtime_test_plan.md`
**Tools covered:** 19 tools, 170+ scenarios
**Source file under test:** `server/src/tools/runtime.ts`

---

## Critical Global Prerequisite

**Every tool in this plan requires the game to be running (🔴).** All 19 tools operate only against the running game's scene tree. Tests that verify "game not running" error handling are the exception, not the rule — these require the game to be explicitly stopped.

---

## Required Project State

- Godot 4.x editor open and running (tested with 4.7)
- Godot MCP plugin installed and active (`addons/godot_mcp/` present, plugin enabled in Project Settings → Plugins)
- **MCP runtime autoload registered** in `project.godot`:
  ```ini
  [autoload]
  mcp_runtime="res://addons/godot_mcp/services/mcp_runtime.gd"
  ```
  ⚠️ Do NOT use `*` prefix — that makes it editor-only and it will NOT load in-game.
- MCP server running and connected to the Godot editor via WebSocket (ports 6505–6514)
- A **3D project** with `forward_plus` renderer (required by Camera3D, NavigationAgent3D, NavigationRegion3D, NPC_Guard nodes used by scenarios)

### Project Settings Required

- **GameManager autoload** (recommended, for `get_autoload` S2):
  ```ini
  [autoload]
  GameManager="res://scripts/game_manager.gd"
  ```
  This file must exist on disk. A minimal `extends Node` script suffices.

- No custom input actions, collision layers, or other non-default settings required beyond the autoload entries above.

---

## Required Scenes

### Scene A: Main Runtime Test Scene

Used by: ALL tools (1–19). This is the scene that must be open and playing when tests run.

**State:** A 3D scene containing all nodes listed below. The scene root is a Node3D.

```
Root (Node3D) — name: "RuntimeTestRoot"

├── Player (Area3D)                              ← get_game_node_properties S2–S5
│   │                                           ← set_game_node_property S1–S8
│   │                                           ← monitor_properties S1–S10
│   │                                           ← batch_get_properties S1–S5
│   │                                           ← watch_signals S1–S2,S4–S10,S12
│   │                                           ← move_to S1–S11
│   │                                           ← navigate_to S4 (no NavigationAgent3D)
│   │                                           ← find_nodes_by_script S1 (has player.gd)
│   ├── CollisionShape3D (SphereShape3D, radius=1.0)
│   ├── Sprite2D (name="Sprite2D")              ← get_game_node_properties S3
│   ├── Camera3D (name="Camera3D", current=true) ← set_game_node_property S5
│   │                                             ← batch_get_properties S2
│   └── MeshInstance3D (BoxMesh)                 ← visual reference for screenshot
│
├── NPC_Guard (CharacterBody3D)                  ← navigate_to S1–S3,S5–S6
│   │                                           ← has NavigationAgent3D
│   │   position: [0, 0, 0]
│   ├── CollisionShape3D (BoxShape3D)
│   ├── MeshInstance3D (CylinderMesh)           ← visual identification
│   └── NavAgent (NavigationAgent3D)            ← navigate_to S1–S3,S5
│       ├── target_desired_distance: 1.0
│       └── path_desired_distance: 0.5
│
├── NavRegion (NavigationRegion3D)              ← provides navmesh for navigate_to
│   │   baked navigation mesh covering area around
│   │   [−20, 0, −20] to [20, 5, 20]
│   └── NavMeshSource (MeshInstance3D)
│       └── PlaneMesh (size: 40×40)            ← source geometry for navmesh bake
│
├── Timer (Timer)                               ← watch_signals S3
│   ├── one_shot: false
│   ├── wait_time: 0.5
│   └── autostart: true                         ← fires timeout signal continuously
│
├── EnemySpawner (Node3D)                       ← spawns Enemy1 for wait_for_node S2
│   └── Enemy1 (Node3D, initially absent)      ← created dynamically at runtime
│       └── MeshInstance3D (SphereMesh)         ← visual
│
├── UI (Control)                                ← root of UI hierarchy
│   │   anchor preset: full_rect
│   ├── MainMenu (Panel)                        ← find_ui_elements S1
│   │   │   anchor preset: full_rect
│   │   ├── PlayButton (Button)                 ← click_button_by_text S1,S5,S7
│   │   │   ├── text: "Play"                     ← find_ui_elements S5
│   │   │   └── size: [200, 60]
│   │   ├── ContinueButton (Button)             ← click_button_by_text S2
│   │   │   └── text: "Continue"
│   │   ├── StartLabel (Label)                  ← find_ui_elements S3
│   │   │   └── text: "Start Game"              ← find_ui_elements S4
│   │   └── ConfigLabel (Label)                 ← find_ui_elements S3
│   │       └── text: "Options"
│   └── HUD (Control)                           ← additional UI element
│       └── ScoreLabel (Label)
│           └── text: "Score: 0"
│
├── N1 (Node3D)                                 ← batch_get_properties S6
├── N2 (Node3D)                                 ← (50 nodes: N1 through N50)
├── N3 (Node3D)                                 ← all with position spread across
│   ...                                          ← world to test large batch queries
├── N50 (Node3D)
│
├── NearbyNode_A (Node3D)                       ← find_nearby_nodes S1,S2
│   └── MeshInstance3D (SphereMesh)
│       └── position: [5, 0, 3]
│
├── NearbyNode_B (Node3D)                       ← find_nearby_nodes S1,S2
│   └── MeshInstance3D (SphereMesh)
│       └── position: [−3, 0, 7]
│
└── FarNode (Node3D)                            ← find_nearby_nodes S3 (outside radius)
    └── MeshInstance3D (SphereMesh)
        └── position: [200, 0, 200]
```

---

## Required Scripts on Disk

These GDScript files must exist in the project filesystem BEFORE running tests.

### `res://scripts/player.gd`

Used by: `find_nodes_by_script` S1 (happy path — must be attached to at least one node), S4–S6

```gdscript
extends Area3D

## Player script — attached to the Player node in the runtime test scene.
## Exists so that find_nodes_by_script can discover the Player node.

func _ready() -> void:
    pass
```

### `res://scripts/unused.gd`

Used by: `find_nodes_by_script` S2 (exists but NOT attached to any node → returns empty array)

```gdscript
extends Node

## Exists on disk but is intentionally NOT attached to any node in the scene.
## Used to verify that find_nodes_by_script returns [] when no node uses this script.
```

### `res://scripts/game_manager.gd`

Used by: `get_autoload` S2 (registered as `GameManager` autoload)

```gdscript
extends Node

## Minimal autoload script for testing get_autoload with a non-MCP autoload.
## Must be registered in project.godot as: GameManager="res://scripts/game_manager.gd"
```

### `res://scripts/does_not_exist.gd` — MUST NOT EXIST

Used by: `find_nodes_by_script` S3 (error: script not found)

---

## Required Node Properties (detailed)

### Player (Area3D)

| Property | Value | Used By |
|----------|-------|---------|
| `name` | `"Player"` | `set_game_node_property` S2 |
| `position` | `Vector3(0, 2, 0)` | `get_game_node_properties` S2,S4; `set_game_node_property` S4; `monitor_properties` S1–S5; `batch_get_properties` S1–S2; `find_nearby_nodes` S1; `move_to` S2 |
| `rotation` | `Vector3(0, 0, 0)` | `monitor_properties` S2 |
| `scale` | `Vector3(1, 1, 1)` | `monitor_properties` S2 |
| `visible` | `true` | `set_game_node_property` S3 |
| Script | `res://scripts/player.gd` | `find_nodes_by_script` S1 |

**Child nodes:**
- `CollisionShape3D` — shape: SphereShape3D (radius 1.0) — enables body_entered/exited signals
- `Sprite2D` (name: `"Sprite2D"`) — for path resolution tests
- `Camera3D` (name: `"Camera3D"`, current: `true`, fov: `70`) — for nested property tests

### NPC_Guard (CharacterBody3D)

| Property | Value | Used By |
|----------|-------|---------|
| `name` | `"NPC_Guard"` | `navigate_to` S1–S3,S5–S6 |
| `position` | `Vector3(0, 0, 0)` | Starting point for navigation |

**Child:** `NavigationAgent3D` (name: `"NavAgent"`) — REQUIRED for navigate_to. Properties:
- `target_desired_distance`: 1.0
- `path_desired_distance`: 0.5

### Timer (Timer)

| Property | Value | Used By |
|----------|-------|---------|
| `name` | `"Timer"` | `watch_signals` S3 |
| `one_shot` | `false` | Ensures continuous timeout firing |
| `wait_time` | `0.5` | 500ms between timeout signals |
| `autostart` | `true` | Starts emitting timeout signals immediately |

### NavRegion (NavigationRegion3D)

Required for `navigate_to` S1–S3,S5–S6. The navigation mesh must be **baked** and cover:
- A ground plane from approximately [−20, 0, −20] to [20, 0, 20]
- The point [10, 0, 5] (target for S1)
- The point [500, 0, 500] (target for S2 — long path)
- Does NOT cover [99999, 0, 99999] (S6 — unreachable target)

### UI Nodes

Exact text values matter for `click_button_by_text` and `find_ui_elements`:

| Node | Type | Text | Used By |
|------|------|------|---------|
| `PlayButton` | Button | `"Play"` | `click_button_by_text` S1,S5,S7,S9; `find_ui_elements` S5 |
| `ContinueButton` | Button | `"Continue"` | `click_button_by_text` S2 |
| `StartLabel` | Label | `"Start Game"` | `find_ui_elements` S4 |
| `ConfigLabel` | Label | `"Options"` | `find_ui_elements` S3 |
| `ScoreLabel` | Label | `"Score: 0"` | `find_ui_elements` S1 (all) |

**Nested path for `wait_for_node` S9:** `UI/MainMenu/PlayButton` must be the actual scene-tree path.

### Batch Test Nodes (N1–N50)

50 nodes numbered N1 through N50, all of type Node3D, placed at the scene root. Used by `batch_get_properties` S6. Each should have a `name` property equal to its identifier. Spread positions to avoid overlap (e.g., N1 at [1,0,0], N2 at [2,0,0], ... N50 at [50,0,0]).

### Nearby/Far Nodes

| Node | Position | Used By |
|------|----------|---------|
| `NearbyNode_A` | `[5, 0, 3]` | `find_nearby_nodes` S1,S2 |
| `NearbyNode_B` | `[−3, 0, 7]` | `find_nearby_nodes` S1,S2 |
| `FarNode` | `[200, 0, 200]` | `find_nearby_nodes` S3 |

---

## Required Resources

- **None.** This test plan does not require any `.tres`, `.res`, texture, material, shader, or audio files beyond what Godot creates as default. All node materials are defaults.

---

## Required Editor/Game State

### For ALL Happy-Path Tests (Tools 1–19)

- **Game must be running** (`godot_play_scene(mode="custom", scene_path="res://test_runtime_main.tscn")`)
- The MCP runtime autoload must be loaded (check Godot output for `[MCP Runtime] Loaded and ready for IPC`)

### For Error-Handling Tests (game-not-running checks)

- **Game must be explicitly stopped** (`godot_stop_scene()`)
- These tests verify every tool returns a clear error, not a cryptic timeout

### For Dynamic Spawn Tests

- `wait_for_node` S2: `Enemy1` must NOT exist at game start. The EnemySpawner script should create it after a short delay (e.g., 1 second). This tests dynamic node detection.

### For Recording Lifecycle Tests

- Full cycle: `start_recording` → interact (move_to, set_game_node_property) → `stop_recording` → `replay_recording` → verify replay
- The game should have at least 2–3 seconds of gameplay to produce meaningful recording data

---

## Setup Script

The following GDScript can be executed via `godot_execute_editor_script` to create all prerequisites in one shot. Run this against a 3D project.

```gdscript
# Prerequisite Setup Script for Runtime Tests
# Execute via: godot_execute_editor_script(code=this_script)
# Project must be a 3D project with forward_plus or mobile renderer.

@tool
extends EditorScript

func _run() -> void:
	# ──────────────────────────────────
	# Step 1: Create script files on disk
	# ──────────────────────────────────
	_create_script("res://scripts/player.gd", """extends Area3D

## Player script — attached to the Player node in the runtime test scene.

func _ready() -> void:
	pass
""")

	_create_script("res://scripts/unused.gd", """extends Node

## Exists on disk but intentionally NOT attached to any node.
## Used by find_nodes_by_script to verify empty-array return.
""")

	_create_script("res://scripts/game_manager.gd", """extends Node

## Minimal autoload for get_autoload S2 testing.
""")

	_create_script("res://scripts/enemy_spawner.gd", """extends Node3D

## Spawns Enemy1 after a short delay for wait_for_node S2 testing.

var _spawned := false

func _process(_delta: float) -> void:
	if _spawned:
		return
	await get_tree().create_timer(1.0).timeout
	var enemy := Node3D.new()
	enemy.name = "Enemy1"
	var mesh := MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.position = Vector3(10, 1, 0)
	enemy.add_child(mesh)
	add_child(enemy)
	_spawned = true
	print("[EnemySpawner] Enemy1 spawned at: ", enemy.get_path())
""")

	print("Scripts created: player.gd, unused.gd, game_manager.gd, enemy_spawner.gd")

	# ──────────────────────────────────
	# Step 2: Register GameManager autoload
	# ──────────────────────────────────
	# Note: mcp_runtime is registered automatically by the plugin.
	# This registers an additional autoload for get_autoload S2 testing.
	var autoloads := get_editor_interface().get_editor_settings().get_project_settings_dir()
	# Use ProjectSettings directly
	ProjectSettings.set_setting("autoload/GameManager", "res://scripts/game_manager.gd")
	print("GameManager autoload registered (may require restart to take effect in-game).")

	# ──────────────────────────────────
	# Step 3: Build the runtime test scene
	# ──────────────────────────────────
	var root := Node3D.new()
	root.name = "RuntimeTestRoot"

	# --- Player (Area3D) ---
	var player := Area3D.new()
	player.name = "Player"
	player.position = Vector3(0, 2, 0)
	var player_script := load("res://scripts/player.gd")
	player.set_script(player_script)
	root.add_child(player)
	player.owner = root

	# CollisionShape3D for body_entered/exited signals
	var player_col := CollisionShape3D.new()
	player_col.shape = SphereShape3D.new()
	player_col.shape.radius = 1.0
	player.add_child(player_col)
	player_col.owner = root

	# Sprite2D child (for get_game_node_properties S3 path resolution test)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	player.add_child(sprite)
	sprite.owner = root

	# Camera3D child
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera.fov = 70.0
	camera.position = Vector3(0, 0, 0)
	player.add_child(camera)
	camera.owner = root

	# Visual mesh for Player
	var player_mesh := MeshInstance3D.new()
	player_mesh.mesh = BoxMesh.new()
	player_mesh.mesh.size = Vector3(1, 1, 1)
	player.add_child(player_mesh)
	player_mesh.owner = root

	# --- NPC_Guard (CharacterBody3D + NavigationAgent3D) ---
	var npc := CharacterBody3D.new()
	npc.name = "NPC_Guard"
	npc.position = Vector3(0, 0, 0)
	root.add_child(npc)
	npc.owner = root

	var npc_col := CollisionShape3D.new()
	npc_col.shape = BoxShape3D.new()
	npc.add_child(npc_col)
	npc_col.owner = root

	var npc_mesh := MeshInstance3D.new()
	npc_mesh.mesh = CylinderMesh.new()
	npc_mesh.mesh.height = 2.0
	npc_mesh.mesh.top_radius = 0.4
	npc_mesh.mesh.bottom_radius = 0.4
	npc.add_child(npc_mesh)
	npc_mesh.owner = root

	var nav_agent := NavigationAgent3D.new()
	nav_agent.name = "NavAgent"
	nav_agent.target_desired_distance = 1.0
	nav_agent.path_desired_distance = 0.5
	npc.add_child(nav_agent)
	nav_agent.owner = root

	# --- NavigationRegion3D ---
	var nav_region := NavigationRegion3D.new()
	nav_region.name = "NavRegion"
	root.add_child(nav_region)
	nav_region.owner = root

	var nav_mesh_source := MeshInstance3D.new()
	nav_mesh_source.name = "NavMeshSource"
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(40, 40)
	nav_mesh_source.mesh = plane_mesh
	nav_region.add_child(nav_mesh_source)
	nav_mesh_source.owner = root

	var nav_mesh := NavigationMesh.new()
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_max_slope = 45.0
	nav_mesh.agent_max_climb = 0.9
	nav_region.navigation_mesh = nav_mesh

	# Bake navmesh
	nav_region.bake_navigation_mesh(false)
	print("NavigationRegion3D baked.")

	# --- Timer ---
	var timer := Timer.new()
	timer.name = "Timer"
	timer.one_shot = false
	timer.wait_time = 0.5
	timer.autostart = true
	root.add_child(timer)
	timer.owner = root

	# --- EnemySpawner ---
	var spawner := Node3D.new()
	spawner.name = "EnemySpawner"
	var spawner_script := load("res://scripts/enemy_spawner.gd")
	spawner.set_script(spawner_script)
	root.add_child(spawner)
	spawner.owner = root

	# --- UI Hierarchy ---
	var ui_root := Control.new()
	ui_root.name = "UI"
	ui_root.anchor_right = 1.0
	ui_root.anchor_bottom = 1.0
	root.add_child(ui_root)
	ui_root.owner = root

	var main_menu := Panel.new()
	main_menu.name = "MainMenu"
	main_menu.anchor_right = 1.0
	main_menu.anchor_bottom = 1.0
	ui_root.add_child(main_menu)
	main_menu.owner = root

	# PlayButton
	var play_btn := Button.new()
	play_btn.name = "PlayButton"
	play_btn.text = "Play"
	play_btn.size = Vector2(200, 60)
	play_btn.anchor_left = 0.5
	play_btn.anchor_right = 0.5
	play_btn.anchor_top = 0.4
	play_btn.anchor_bottom = 0.4
	play_btn.offset_left = -100
	play_btn.offset_right = 100
	play_btn.offset_top = -30
	play_btn.offset_bottom = 30
	main_menu.add_child(play_btn)
	play_btn.owner = root

	# ContinueButton
	var continue_btn := Button.new()
	continue_btn.name = "ContinueButton"
	continue_btn.text = "Continue"
	continue_btn.size = Vector2(200, 60)
	continue_btn.anchor_left = 0.5
	continue_btn.anchor_right = 0.5
	continue_btn.anchor_top = 0.5
	continue_btn.anchor_bottom = 0.5
	continue_btn.offset_left = -100
	continue_btn.offset_right = 100
	continue_btn.offset_top = -30
	continue_btn.offset_bottom = 30
	main_menu.add_child(continue_btn)
	continue_btn.owner = root

	# StartLabel
	var start_label := Label.new()
	start_label.name = "StartLabel"
	start_label.text = "Start Game"
	start_label.anchor_left = 0.5
	start_label.anchor_right = 0.5
	start_label.anchor_top = 0.2
	start_label.position = Vector2(-50, 0)
	main_menu.add_child(start_label)
	start_label.owner = root

	# ConfigLabel
	var config_label := Label.new()
	config_label.name = "ConfigLabel"
	config_label.text = "Options"
	config_label.anchor_left = 0.5
	config_label.anchor_right = 0.5
	config_label.anchor_top = 0.6
	config_label.position = Vector2(-30, 0)
	main_menu.add_child(config_label)
	config_label.owner = root

	# HUD with ScoreLabel
	var hud := Control.new()
	hud.name = "HUD"
	hud.anchor_right = 1.0
	hud.anchor_bottom = 1.0
	ui_root.add_child(hud)
	hud.owner = root

	var score_label := Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Score: 0"
	score_label.anchor_right = 1.0
	score_label.anchor_top = 0.0
	score_label.offset_top = 10
	hud.add_child(score_label)
	score_label.owner = root

	# --- Batch Test Nodes (N1–N50) ---
	for i in range(1, 51):
		var n := Node3D.new()
		n.name = "N%d" % i
		n.position = Vector3(float(i), 0, 0)
		root.add_child(n)
		n.owner = root

	# --- Nearby/Far nodes for find_nearby_nodes ---
	var near_a := Node3D.new()
	near_a.name = "NearbyNode_A"
	near_a.position = Vector3(5, 0, 3)
	var near_a_mesh := MeshInstance3D.new()
	near_a_mesh.mesh = SphereMesh.new()
	near_a.add_child(near_a_mesh)
	near_a_mesh.owner = root
	root.add_child(near_a)
	near_a.owner = root

	var near_b := Node3D.new()
	near_b.name = "NearbyNode_B"
	near_b.position = Vector3(-3, 0, 7)
	var near_b_mesh := MeshInstance3D.new()
	near_b_mesh.mesh = SphereMesh.new()
	near_b.add_child(near_b_mesh)
	near_b_mesh.owner = root
	root.add_child(near_b)
	near_b.owner = root

	var far_node := Node3D.new()
	far_node.name = "FarNode"
	far_node.position = Vector3(200, 0, 200)
	var far_mesh := MeshInstance3D.new()
	far_mesh.mesh = SphereMesh.new()
	far_node.add_child(far_mesh)
	far_mesh.owner = root
	root.add_child(far_node)
	far_node.owner = root

	# ──────────────────────────────────
	# Step 4: Pack and save the scene
	# ──────────────────────────────────
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		printerr("Failed to pack scene: error ", err)
		return

	var save_path := "res://test_runtime_main.tscn"
	err = ResourceSaver.save(packed, save_path)
	if err != OK:
		printerr("Failed to save scene: error ", err)
		return

	print("Runtime test prerequisites created successfully.")
	print("  Scene: ", save_path)
	print("  Scripts: res://scripts/player.gd, res://scripts/unused.gd, res://scripts/game_manager.gd, res://scripts/enemy_spawner.gd")
	print("  Autoload: GameManager → res://scripts/game_manager.gd (restart may be needed)")
	print("")
	print("  To run tests: godot_open_scene(path='res://test_runtime_main.tscn')")
	print("               then godot_play_scene(mode='current')")

# ──────────────────────────────────
# Helper: create a script file on disk
# ──────────────────────────────────
func _create_script(path: String, source: String) -> void:
	var dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(source)
		file.close()
	else:
		printerr("Failed to create script: ", path)
```

---

## Dependency Graph: Test Execution Order

### Phase 0: Prerequisite Setup (execute once)
1. Run the setup script above (or manually create all nodes/scenes/scripts)
2. Restart Godot to ensure GameManager autoload takes effect
3. Open `res://test_runtime_main.tscn`

### Phase 1: Game-Not-Running Error Tests (all tools)
```
All 19 tools: test with game STOPPED first, verify clear error messages.
Cannot proceed to Phase 2 until these pass — they validate precondition guards.
```
- `get_game_scene_tree` S2
- `capture_frames` (implicit — all tools must handle stopped game)
- Cross-cutting: "Game not running" for ALL tools

### Phase 2: Start Game, Run Read-Only Tools
```
godot_play_scene(mode="current")
```
- `get_game_scene_tree` S1,S3 (verify runtime tree)
- `get_game_node_properties` S1–S5,S8 (read properties)
- `batch_get_properties` S1–S6,S9 (batch reads)
- `find_nodes_by_script` S1–S2,S6 (script lookup, before any mutation)
- `get_autoload` S1–S2,S4,S6 (autoload inspection)
- `find_ui_elements` S1–S9 (UI element discovery)
- `find_nearby_nodes` S1–S3,S6,S9 (proximity search)
- `wait_for_node` S1,S5,S9 (node existence check)

### Phase 3: Property Mutation Tests
```
Game must still be running. Mutations validate state changes.
```
- `set_game_node_property` S1–S6,S11 (set properties, verify with get_game_node_properties)
- `move_to` S1–S5,S11 (teleport, verify position changed)

### Phase 4: Script Execution and Signal Watching
```
Game still running. These interact with the live engine.
```
- `execute_game_script` S1–S5,S9–S10 (run GDScript snippets)
- `watch_signals` S1–S5,S8,S10 (watch for signal emissions)
  - Run S3 while Timer is running to observe timeout signals
  - Run S1–S2 to verify signal watching infrastructure works

### Phase 5: UI Interaction Tests
```
Game still running. These click buttons and verify UI state.
```
- `click_button_by_text` S1–S2,S5,S7 (click "Play" and "Continue" buttons)
- `find_ui_elements` (re-run after clicks to verify state changes if applicable)

### Phase 6: Navigation and Movement
```
Game still running. Requires navmesh already baked from setup script.
```
- `navigate_to` S1–S3,S5–S6,S11 (pathfinding with NavigationAgent3D)
  - S1: navigate NPC_Guard to [10, 0, 5] (reachable)
  - S2: navigate to [500, 0, 500] (long path — may take time on navmesh)
  - S3: navigate to current position (no-op)
  - S4: attempt on Player (no NavigationAgent3D — error expected)
  - S5: non-existent node (error expected)
  - S6: unreachable target [99999, 0, 99999] (error expected)
  - S11: empty path (error expected)

### Phase 7: Recording Lifecycle
```
Full recording cycle. Game still running.
```
1. `start_recording` S1
2. Execute actions: `move_to` (a few teleports), `set_game_node_property` (a few changes)
3. `stop_recording` S1 (verify data returned)
4. `replay_recording` S1–S6,S9 (replay at various speeds)
5. `stop_recording` S2 (no active recording — error)
6. `start_recording` S2 (idempotency: start twice)

### Phase 8: Capture and Monitoring
```
Game still running.
```
- `capture_frames` S1–S5,S8 (capture 1–60 frames, verify PNG files on disk)
- `monitor_properties` S1–S5,S8,S10 (monitor Player position/rotation/scale)

### Phase 9: Schema Validation Tests (no game required)
```
These tests are rejected by Zod on the MCP server side before reaching Godot.
Can run with game stopped or running — they never reach the plugin.
```
- All `missing required param` tests across all 19 tools
- All `type validation` tests (string where number expected, etc.)
- All `boundary violation` tests (count=0, count=61, radius=0, speed=0, etc.)
- `get_game_node_properties` S7–S8
- `set_game_node_property` S9–S10
- `execute_game_script` S8
- `capture_frames` S6–S7,S9–S11
- `monitor_properties` S8–S9
- `start_recording` S3
- `stop_recording` S2–S4
- `replay_recording` S6–S8
- `find_nodes_by_script` S4–S5
- `get_autoload` S5
- `batch_get_properties` S7–S9
- `find_ui_elements` S10
- `click_button_by_text` S8
- `wait_for_node` S8,S10
- `find_nearby_nodes` S4–S5,S7–S8,S10–S11
- `navigate_to` S7–S10
- `move_to` S7–S10
- `watch_signals` S11–S13

### Phase 10: Cross-Cutting Stress Tests
```
Game still running.
```
- Large payloads: scene tree with 1000+ nodes, batch_get_properties with 200 paths, capture_frames count=60
- Rapid sequential calls: click_button_by_text 10x, set_game_node_property 50x
- Concurrent calls: move_to and set_game_node_property simultaneously
- Dynamic spawn: wait_for_node S2 (verify Enemy1 appears)

---

## Quick-Start Checklist

Before running ANY runtime test:

1. ✅ Godot 4.x editor open, MCP plugin active and connected
2. ✅ `mcp_runtime` autoload registered (`res://addons/godot_mcp/services/mcp_runtime.gd`)
3. ✅ `GameManager` autoload registered (`res://scripts/game_manager.gd`)
4. ✅ All 4 script files created on disk:
   - `res://scripts/player.gd`
   - `res://scripts/unused.gd`
   - `res://scripts/game_manager.gd`
   - `res://scripts/enemy_spawner.gd`
5. ✅ Runtime test scene saved: `res://test_runtime_main.tscn`
6. ✅ Navigation mesh baked (via setup script, covers ground plane)
7. ✅ MCP server running and connected to Godot

**To begin testing:**
```
godot_open_scene(path="res://test_runtime_main.tscn")
godot_play_scene(mode="current")
```

Verify the game is running:
```
godot_get_game_scene_tree()  → should return the full runtime tree
godot_get_autoload(name="mcp_runtime")  → should return autoload data
```
