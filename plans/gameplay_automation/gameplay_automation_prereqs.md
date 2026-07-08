# Prerequisites for Gameplay Automation Test Plan

**Source plan:** `server/src/test_plans/gameplay_automation_test_plan.md`
**Source tool:** `server/src/tools/gameplay_automation.ts`
**Tools covered:** 7 (`simulate_gameplay_scenario`, `record_gameplay`, `replay_gameplay`, `create_test_character`, `navigate_character`, `assert_game_state`, `wait_for_game_event`)
**Generated:** 2026-07-08

---

## Required Project State

- **Godot 4.x project** (tested with 4.7) — **3D project** (all position parameters use `[x, y, z]` 3D coordinates; navigation uses 3D pathfinding)
- **Godot MCP addon** installed and active at `addons/godot_mcp/` (required for all tools)
- **`mcp_runtime.gd` autoload** registered in `project.godot` as `mcp_runtime="res://addons/godot_mcp/services/mcp_runtime.gd"` — required for ALL runtime tools (every scenario that says "Game running"). Must NOT use the editor-only `*` prefix variant — it must load at game start.
- **Main scene configured** — a playable 3D scene set as the project main scene (see "Required Scenes" below)
- **`res://scenes/characters/` directory** — must exist on disk for `create_test_character` happy-path scenarios
- **`res://recordings/` directory** — must exist on disk for `replay_gameplay` scenarios

---

## Required Scenes

### 1. Main playable test scene (`res://scenes/test_gameplay.tscn`)

Root node type: `Node3D`. This is the scene that gets played for all "Game running" scenarios. Contains:

```
test_gameplay (Node3D root)
├── Player (CharacterBody3D)                                 ← navigate S1-S3,S5,S9-S12; simulate S3,S5-S7; assert S1-S10,S16; wait_for_event S1,S3-S7,S11
│   ├── CollisionShape3D (BoxShape3D)                        ← so Player exists in physics world
│   ├── NavigationAgent3D                                    ← navigate S2,S4 (pathfind method)
│   └── MeshInstance3D (visible placeholder)                 ← so Player is visible in viewport
├── Enemy (CharacterBody3D)                                  ← navigate S4 (pathfind as "Enemy")
│   ├── CollisionShape3D
│   └── NavigationAgent3D                                    ← navigate S4
├── EnemySpawner (Node3D)                                    ← wait_for_event S2 (parent for spawned enemies)
├── NavigationRegion3D                                       ← navigate S2,S4 (pathfinding requires navmesh)
│   └── (baked NavigationMesh)                               ← must be baked; navigate S10 tests missing navmesh separately
├── Camera3D                                                 ← so the game viewport renders something
├── DirectionalLight3D                                       ← basic scene lighting
└── WorldEnvironment                                         ← basic environment
```

**Specific node configurations:**

- **`Player` (type `CharacterBody3D`):**
  - Must have a GDScript attached at `res://scripts/player_character.gd` that exports the following custom properties (all used by `assert_game_state`):
    - `@export var health: int = 100` — must be > 0 by default (assert S4: `health > 0`; assert S10: `health != 999999`; wait_for_event S3: wait for `health == 0`)
    - `@export var speed: float = 50.0` — must be < 100 by default (assert S5: `speed < 100`)
    - `@export var score: int = 0` — used by assert S6 (`score >= 10`)
    - `@export var ammo: int = 30` — used by assert S7 (`ammo <= 30`)
  - Must declare these custom signals (used by `wait_for_game_event`):
    - `signal custom_signal` — for wait_for_event S4 (short timeout test)
    - `signal delayed_signal` — for wait_for_event S5 (long timeout test, max 30s)
    - `signal immediate_signal` — for wait_for_event S6 (min timeout test, expected to timeout)
  - `ready` signal is built-in and fires automatically when the node enters the tree (wait_for_event S1)
  - Built-in `visible` property must be `true` at game start (assert S1, S3, S9, S10)
  - Built-in `name` property returns `"Player"` (assert S8: `name` contains `"Player"`)
  - Must be navigable — i.e., the `navigate_character` tool can move it (direct method requires the node to exist and accept position changes; pathfind method requires `NavigationAgent3D` child + baked navmesh)

- **`Enemy` (type `CharacterBody3D`):**
  - Must have a `NavigationAgent3D` child (for navigate S4 pathfind test)
  - Must be navigable via pathfinding (requires baked navmesh in the scene)

- **`EnemySpawner` (type `Node3D`):**
  - Must have a script attached at `res://scripts/enemy_spawner.gd` that spawns a child node named `Enemy_1` after a short delay on `_ready()` (for wait_for_event S2: `node:EnemySpawner/Enemy_1`)

- **`NavigationRegion3D`:**
  - Must have a `NavigationMesh` resource assigned and baked (covers enough area for Player and Enemy pathfinding)
  - navigate S10 tests the error case when no navmesh exists — run that scenario on a separate scene or before baking

### 2. Character scene files (for `create_test_character`)

These are separate `.tscn` files — NOT the same as nodes in the main test scene. The `create_test_character` tool instantiates them.

#### `res://scenes/characters/player.tscn`
- Root: `CharacterBody3D` (or `Node3D`)
- Minimal content: a `CollisionShape3D` and `MeshInstance3D` child (so the character is visible and has physics presence)
- Used by: create_test_character S1 (with position), S2 (without position), S5 (large position)

#### `res://scenes/characters/enemy.tscn`
- Root: `CharacterBody3D` (or `Node3D`)
- Minimal content: same as player but visually distinct (e.g., different mesh color)
- Used by: create_test_character S3 (non-origin position)

#### `res://scenes/characters/npc.tscn`
- Root: `CharacterBody3D` (or `Node3D`)
- Minimal content: same as player but visually distinct
- Used by: create_test_character S4 (negative coordinates)

---

## Required Resources

### Scripts

| Path | Purpose | Contents |
|------|---------|----------|
| `res://scripts/player_character.gd` | Attached to `Player` node in main scene | `extends CharacterBody3D` with `@export var health: int = 100`, `@export var speed: float = 50.0`, `@export var score: int = 0`, `@export var ammo: int = 30`; declares `signal custom_signal`, `signal delayed_signal`, `signal immediate_signal` |
| `res://scripts/enemy_spawner.gd` | Attached to `EnemySpawner` node | `extends Node3D` with `_ready()` that spawns a child `Node3D` named `Enemy_1` after a short delay (e.g., `await get_tree().create_timer(0.1).timeout` then `add_child`) |

### Recording files

| Path | Purpose |
|------|---------|
| `res://recordings/test_recording.json` | Valid gameplay recording file for `replay_gameplay` happy-path scenarios (S1–S4). Must be generated by a prior `record_gameplay` call. Minimum requirement: a recording with at least a few frames of input events or state snapshots that Godot can replay without error. |

### Directories

| Path | Purpose |
|------|---------|
| `res://scenes/characters/` | Contains the 3 character `.tscn` files for `create_test_character` |
| `res://recordings/` | Contains the test recording file for `replay_gameplay` |

### Other resources

- No specific `.tres`, textures, materials, shaders, or audio files are needed.
- The `ui_accept` input action is a **built-in Godot default** — it should already exist in any new project's InputMap. Verify it exists with `get_input_actions` before running tests.

---

## Required Editor/Game State

| State | Required By | Notes |
|-------|-------------|-------|
| **Game running** (via `play_scene`) | simulate S1–S7, S9–S11; record S1–S7, S11; replay S1–S4, S6; navigate S1–S4, S9–S12; assert S1–S10, S12, S14–S16; wait_for_event S1–S7, S9–S11, S16 | ALL runtime tools require an active game session with `mcp_runtime.gd` loaded. Validation-only scenarios (missing params, boundary checks) do NOT need the game running. |
| **Main test scene open in editor** | create_test_character S7 (non-existent scene test) | Only needed for error-case tests that expect "scene open but file not found" |
| **Scene loaded but no navmesh baked** | navigate S10 | This may require a separate scene or clearing the navmesh from the main scene. A dedicated scene `res://scenes/test_no_navmesh.tscn` with the same Player node but NO NavigationRegion3D would work. |

---

## Required Settings/Config

### Autoloads
- `mcp_runtime.gd` registered as autoload with path `res://addons/godot_mcp/services/mcp_runtime.gd` (NOT the editor-only `*` prefix — must load at runtime)

### Project Settings
- **Main scene:** Set to `res://scenes/test_gameplay.tscn`
- **Input Map:** The built-in `ui_accept` action must exist (default in all Godot projects — verify with `get_input_actions`; simulate S2 and S7 depend on it)
- **No custom collision layers, custom project settings, or rendering config changes** are required beyond the defaults

### Addons
- **godot_mcp** addon must be enabled in Project Settings → Plugins (required by all tools)

---

## Setup Script

Run this GDScript via `execute_editor_script` to create the test scene, character scenes, scripts, and recording in one shot. This script assumes a fresh 3D Godot project with the MCP addon already active.

```gdscript
# ============================================================
# Gameplay Automation Test Prerequisites Setup
# Creates all scenes, scripts, and resources needed to execute
# the 86 scenarios in gameplay_automation_test_plan.md
# ============================================================

# === 1. Create directories ===
DirAccess.make_dir_recursive_absolute("res://scenes/characters")
DirAccess.make_dir_recursive_absolute("res://scripts")
DirAccess.make_dir_recursive_absolute("res://recordings")

# === 2. Create player_character.gd ===
var player_script = FileAccess.open("res://scripts/player_character.gd", FileAccess.WRITE)
player_script.store_string("""extends CharacterBody3D

@export var health: int = 100
@export var speed: float = 50.0
@export var score: int = 0
@export var ammo: int = 30

signal custom_signal
signal delayed_signal
signal immediate_signal

func _ready():
	# Emit custom_signal shortly after ready for wait_for_game_event S4
	get_tree().create_timer(0.2).timeout.connect(_emit_custom_signal)
	# Emit delayed_signal after ~25s for wait_for_game_event S5 (within 30s timeout)
	get_tree().create_timer(25.0).timeout.connect(_emit_delayed_signal)
	# immediate_signal is NEVER auto-emitted — used for wait_for_game_event S6 (min timeout, expected to fail)

func _emit_custom_signal():
	custom_signal.emit()

func _emit_delayed_signal():
	delayed_signal.emit()
""")
player_script.close()

# === 3. Create enemy_spawner.gd ===
var spawner_script = FileAccess.open("res://scripts/enemy_spawner.gd", FileAccess.WRITE)
spawner_script.store_string("""extends Node3D

func _ready():
	# Spawn Enemy_1 after a short delay for wait_for_game_event S2
	await get_tree().create_timer(0.5).timeout
	var enemy = Node3D.new()
	enemy.name = "Enemy_1"
	add_child(enemy)
	print("[EnemySpawner] Spawned Enemy_1")
""")
spawner_script.close()

# === 4. Create the main test scene (res://scenes/test_gameplay.tscn) ===
var main_root = Node3D.new()
main_root.name = "test_gameplay"

# -- Camera3D --
var camera = Camera3D.new()
camera.name = "Camera3D"
camera.position = Vector3(0, 10, 15)
camera.look_at(Vector3(0, 0, 0))
camera.current = true
main_root.add_child(camera)
camera.owner = main_root

# -- DirectionalLight3D --
var light = DirectionalLight3D.new()
light.name = "DirectionalLight3D"
light.rotation_degrees = Vector3(-45, 30, 0)
main_root.add_child(light)
light.owner = main_root

# -- WorldEnvironment --
var world_env = WorldEnvironment.new()
world_env.name = "WorldEnvironment"
var env = Environment.new()
env.background_mode = Environment.BG_COLOR
env.background_color = Color(0.2, 0.2, 0.3)
world_env.environment = env
main_root.add_child(world_env)
world_env.owner = main_root

# -- Player (CharacterBody3D) --
var player = CharacterBody3D.new()
player.name = "Player"
player.position = Vector3(0, 1, 0)
# visible defaults to true, health=100, speed=50, score=0, ammo=30
main_root.add_child(player)
player.owner = main_root

# Player/CollisionShape3D
var player_col = CollisionShape3D.new()
player_col.name = "CollisionShape3D"
var player_box = BoxShape3D.new()
player_box.size = Vector3(1, 2, 1)
player_col.shape = player_box
player.add_child(player_col)
player_col.owner = main_root

# Player/MeshInstance3D
var player_mesh = MeshInstance3D.new()
player_mesh.name = "MeshInstance3D"
var player_box_mesh = BoxMesh.new()
player_box_mesh.size = Vector3(1, 2, 1)
player_mesh.mesh = player_box_mesh
player.add_child(player_mesh)
player_mesh.owner = main_root

# Player/NavigationAgent3D
var player_nav = NavigationAgent3D.new()
player_nav.name = "NavigationAgent3D"
player.add_child(player_nav)
player_nav.owner = main_root

# Attach player script
var player_script_res = load("res://scripts/player_character.gd")
player.set_script(player_script_res)

# -- Enemy (CharacterBody3D) --
var enemy = CharacterBody3D.new()
enemy.name = "Enemy"
enemy.position = Vector3(10, 1, 0)
main_root.add_child(enemy)
enemy.owner = main_root

# Enemy/CollisionShape3D
var enemy_col = CollisionShape3D.new()
enemy_col.name = "CollisionShape3D"
var enemy_box = BoxShape3D.new()
enemy_box.size = Vector3(1, 2, 1)
enemy_col.shape = enemy_box
enemy.add_child(enemy_col)
enemy_col.owner = main_root

# Enemy/MeshInstance3D
var enemy_mesh = MeshInstance3D.new()
enemy_mesh.name = "MeshInstance3D"
var enemy_box_mesh = BoxMesh.new()
enemy_box_mesh.size = Vector3(1, 2, 1)
enemy_mesh.mesh = enemy_box_mesh
enemy.add_child(enemy_mesh)
enemy_mesh.owner = main_root

# Enemy/NavigationAgent3D
var enemy_nav = NavigationAgent3D.new()
enemy_nav.name = "NavigationAgent3D"
enemy.add_child(enemy_nav)
enemy_nav.owner = main_root

# -- EnemySpawner --
var spawner = Node3D.new()
spawner.name = "EnemySpawner"
main_root.add_child(spawner)
spawner.owner = main_root
var spawner_script_res = load("res://scripts/enemy_spawner.gd")
spawner.set_script(spawner_script_res)

# -- NavigationRegion3D --
var nav_region = NavigationRegion3D.new()
nav_region.name = "NavigationRegion3D"
# Create a flat plane navmesh covering the test area
var nav_mesh = NavigationMesh.new()
nav_region.navigation_mesh = nav_mesh
main_root.add_child(nav_region)
nav_region.owner = main_root

# Save the main scene
var packed_main = PackedScene.new()
packed_main.pack(main_root)
ResourceSaver.save(packed_main, "res://scenes/test_gameplay.tscn")
print("[SETUP] Saved res://scenes/test_gameplay.tscn")

# === 5. Create character scene files (for create_test_character) ===

func make_character_scene(scene_name: String, color: Color) -> void:
	var char_root = CharacterBody3D.new()
	char_root.name = scene_name.replace(".tscn", "")

	var char_col = CollisionShape3D.new()
	char_col.name = "CollisionShape3D"
	var char_box = BoxShape3D.new()
	char_box.size = Vector3(1, 2, 1)
	char_col.shape = char_box
	char_root.add_child(char_col)
	char_col.owner = char_root

	var char_mesh = MeshInstance3D.new()
	char_mesh.name = "MeshInstance3D"
	var char_box_mesh = BoxMesh.new()
	char_box_mesh.size = Vector3(1, 2, 1)

	# Create a simple colored material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	char_box_mesh.material = mat
	char_mesh.mesh = char_box_mesh
	char_root.add_child(char_mesh)
	char_mesh.owner = char_root

	var packed = PackedScene.new()
	packed.pack(char_root)
	ResourceSaver.save(packed, "res://scenes/characters/" + scene_name)
	print("[SETUP] Saved res://scenes/characters/" + scene_name)

make_character_scene("player.tscn", Color.BLUE)
make_character_scene("enemy.tscn", Color.RED)
make_character_scene("npc.tscn", Color.GREEN)

# === 6. Create a dummy recording file for replay tests ===
# In practice, this should be generated by a prior record_gameplay call,
# but a minimal valid JSON file prevents file-not-found errors.
var recording_data = {
	"version": 1,
	"duration": 2.0,
	"inputs": [],
	"states": []
}
var rec_file = FileAccess.open("res://recordings/test_recording.json", FileAccess.WRITE)
rec_file.store_string(JSON.stringify(recording_data, "\t"))
rec_file.close()
print("[SETUP] Saved res://recordings/test_recording.json (dummy — replace with real recording before running replay tests)")

print("[SETUP] ============================================")
print("[SETUP] Gameplay automation prerequisites created!")
print("[SETUP] ============================================")
```

**Post-setup manual steps:**

1. Open `res://scenes/test_gameplay.tscn` in the editor
2. Select the `NavigationRegion3D` node and **bake the navigation mesh** (click "Bake NavigationMesh" in the 3D toolbar or call `godot_bake_navigation_mesh`)
3. Set `res://scenes/test_gameplay.tscn` as the project main scene **(Project → Project Settings → Application → Run → Main Scene)**
4. Verify the `mcp_runtime.gd` autoload is present in `project.godot` (should be auto-registered by the MCP addon — check the `[autoload]` section)
5. Generate a **real recording file** for `replay_gameplay` tests: play the scene, call `record_gameplay` with `{"duration": 5, "include_input": true, "include_state": true}`, and save the output as `res://recordings/test_recording.json` (overwriting the dummy file created by the setup script)
6. Verify `ui_accept` exists: call `get_input_actions` and check that `ui_accept` is listed in the input map
7. Run `godot_play_scene` once to confirm the scene starts without errors, then `godot_stop_scene`


## Scenario-to-Prerequisite Mapping

### godot_simulate_gameplay_scenario (11 scenarios)

| Scenario | Prerequisites |
|----------|---------------|
| 1.1 (wait) | Game running |
| 1.2 (input) | Game running + `ui_accept` input action exists in InputMap |
| 1.3 (move) | Game running + `Player` node exists in scene tree |
| 1.4 (click) | Game running |
| 1.5 (assert) | Game running + `Player` node with `visible` property |
| 1.6 (wait+delay) | Game running + `Player` node with known `position` |
| 1.7 (multi-step) | Game running + `Player` node + `ui_accept` action |
| 1.8 (missing scenario) | None (validation test) |
| 1.9 (invalid action) | Game running |
| 1.10 (empty array) | Game running |
| 1.11 (missing params) | Game running |

### godot_record_gameplay (11 scenarios)

| Scenario | Prerequisites |
|----------|---------------|
| 2.1 (defaults) | Game running |
| 2.2 (1s min) | Game running |
| 2.3 (300s max) | Game running; **[SLOW]** 5 min — manual only |
| 2.4 (state+input) | Game running |
| 2.5 (input only) | Game running |
| 2.6 (state only) | Game running |
| 2.7 (both off) | Game running |
| 2.8 (duration 0) | None (validation) |
| 2.9 (duration 301) | None (validation) |
| 2.10 (negative) | None (validation) |
| 2.11 (float 3.5) | Game running |

### godot_replay_gameplay (10 scenarios)

| Scenario | Prerequisites |
|----------|---------------|
| 3.1 (default speed) | Game running + `res://recordings/test_recording.json` exists and is a valid recording |
| 3.2 (0.1x speed) | Game running + valid recording file |
| 3.3 (10x speed) | Game running + valid recording file |
| 3.4 (2x speed) | Game running + valid recording file |
| 3.5 (missing path) | None (validation) |
| 3.6 (non-existent file) | Game running (error case) |
| 3.7 (speed 0.05) | None (validation) |
| 3.8 (speed 20) | None (validation) |
| 3.9 (negative speed) | None (validation) |
| 3.10 (zero speed) | None (validation) |

### godot_create_test_character (10 scenarios)

| Scenario | Prerequisites |
|----------|---------------|
| 4.1 (with position) | `res://scenes/characters/player.tscn` exists |
| 4.2 (no position) | `res://scenes/characters/player.tscn` exists |
| 4.3 (non-origin pos) | `res://scenes/characters/enemy.tscn` exists |
| 4.4 (negative coords) | `res://scenes/characters/npc.tscn` exists |
| 4.5 (large position) | `res://scenes/characters/player.tscn` exists |
| 4.6 (missing path) | None (validation) |
| 4.7 (non-existent scene) | Game running or scene open |
| 4.8 (invalid path fmt) | None (validation) |
| 4.9 (2-element pos) | None (validation) |
| 4.10 (non-number pos) | None (validation) |

### godot_navigate_character (12 scenarios)

| Scenario | Prerequisites |
|----------|---------------|
| 5.1 (direct default) | Game running + `Player` (CharacterBody3D) node exists |
| 5.2 (pathfind) | Game running + `Player` has `NavigationAgent3D` child + navmesh baked |
| 5.3 (explicit direct) | Game running + `Player` node exists |
| 5.4 (pathfind Enemy) | Game running + `Enemy` with `NavigationAgent3D` + navmesh baked |
| 5.5 (missing char_path) | None (validation) |
| 5.6 (missing target) | None (validation) |
| 5.7 (invalid method) | None (validation) |
| 5.8 (2-element target) | None (validation) |
| 5.9 (non-existent node) | Game running (error case) |
| 5.10 (pathfind, no navmesh) | Game running + `Player` exists + NO baked navmesh (separate scene or cleared navmesh) |
| 5.11 (large coords) | Game running + `Player` exists |
| 5.12 (float coords) | Game running + `Player` exists |

### godot_assert_game_state (16 scenarios)

| Scenario | Prerequisites |
|----------|---------------|
| 6.1 (default ==) | Game running + `Player` node with `visible` property = `true` |
| 6.2 (explicit ==) | Game running + `Player.position` at `[0, 0, 0]` (or whatever test expects) |
| 6.3 (!=) | Game running + `Player.visible` = `true` (so `visible != false` passes) |
| 6.4 (>) | Game running + `Player.health` > 0 (default: 100) |
| 6.5 (<) | Game running + `Player.speed` < 100 (default: 50.0) |
| 6.6 (>=) | Game running + `Player.score` to a value ≥ 10 before asserting |
| 6.7 (<=) | Game running + `Player.ammo` ≤ 30 (default: 30) |
| 6.8 (contains) | Game running + `Player.name` = `"Player"` (contains `"Player"`) |
| 6.9 (all pass) | Game running + `Player` with `visible=true`, `health>0`, `name` contains `"Player"` |
| 6.10 (one fails) | Game running + `Player` with `visible=true`, `health != 999999` (passes) |
| 6.11 (missing conditions) | None (validation) |
| 6.12 (empty array) | Game running |
| 6.13 (missing expected) | Game running (verify Zod behavior) |
| 6.14 (invalid operator) | Game running |
| 6.15 (non-existent node) | Game running (error case) |
| 6.16 (non-existent prop) | Game running + `Player` exists |

### godot_wait_for_game_event (16 scenarios)

| Scenario | Prerequisites |
|----------|---------------|
| 7.1 (signal default T/O) | Game running + `Player` node emits `ready` signal (fires automatically on enter_tree) |
| 7.2 (node creation) | Game running + `EnemySpawner` spawns `Enemy_1` within 5s default timeout |
| 7.3 (property change) | Game running + `Player.health` will reach `0` within timeout (script or gameplay must change it) |
| 7.4 (short timeout) | Game running + `Player.custom_signal` fires within ~200ms (script emits on 0.2s timer) |
| 7.5 (long timeout) | Game running + `Player.delayed_signal` fires within 30s (script emits on 25s timer) |
| 7.6 (min timeout) | Game running + `Player.immediate_signal` — expected to timeout (never auto-emitted) |
| 7.7 (timeout expire) | Game running + `Player` node exists but no `never_emitted_signal` |
| 7.8 (missing event) | None (validation) |
| 7.9 (no prefix) | Game running (error from Godot handler) |
| 7.10 (unknown prefix) | Game running (error from Godot handler) |
| 7.11 (too few parts) | Game running (error from Godot handler) |
| 7.12 (timeout 0) | None (validation) |
| 7.13 (timeout 30001) | None (validation) |
| 7.14 (float timeout) | None (validation) |
| 7.15 (negative timeout) | None (validation) |
| 7.16 (property no value) | Game running |

---

## Additional Notes

### Scenarios that require separate scene state
- **navigate S10** (pathfind without navmesh): This contradicts the main scene setup (which has a baked navmesh). Create a separate scene `res://scenes/test_no_navmesh.tscn` identical to the main scene but WITHOUT the `NavigationRegion3D` node. Switch to this scene for the no-navmesh error test.
- **assert S6** (`score >= 10`): The Player starts with `score = 0`. Before running this scenario, use `set_game_node_property` or `execute_game_script` to set `Player.score = 10` (or higher).
- **wait_for_event S3** (`health == 0`): Player starts with `health = 100`. Before running, use `set_game_node_property` or `execute_game_script` to set `Player.health = 0` during gameplay.
- **replay S1–S4** (valid recording): The dummy JSON created by the setup script has no real input/state data. Replace it with a real recording created by a prior `record_gameplay` call before running replay tests.

### Order of test execution
Run validation/boundary tests (missing params, invalid values) FIRST — they don't need the game running. Then start the game and run runtime scenarios. **[SLOW]** scenarios (record S3 with 300s duration, wait_for_event S5 with 30s timeout) should be run last or skipped in CI.

### Recording file format
The exact format of `test_recording.json` depends on Godot's `record_gameplay` implementation. The dummy file created by the setup script uses a minimal structure. Replace it with output from an actual `record_gameplay` call before running `replay_gameplay` tests.
