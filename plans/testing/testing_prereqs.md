# Prerequisites for Testing Tools Test Plan

**Source test plan:** `server/src/test_plans/testing_test_plan.md`
**Source code:** `server/src/tools/testing.ts`
**Covered tools:** `run_test_scenario`, `assert_node_state`, `assert_screen_text`, `run_stress_test`, `get_test_report`

---

## Overview

The testing tools operate in two modes:

1. **Zod validation only** — scenarios that only test TypeScript/Zod schema validation on the MCP server side. These do NOT require Godot or a running game — the call is rejected before reaching the Godot bridge.
2. **Runtime** — scenarios that reach the Godot bridge and interact with a running game. These REQUIRE `mcp_runtime` autoload active and the game running.

### Zod-only scenarios (no runtime prerequisites)

These scenarios test schema validation and can be run against the MCP server alone (no Godot needed):

| Tool | Scenario # | What it tests |
|------|-----------|---------------|
| `run_test_scenario` | 3 | Missing required `steps` (param given but no steps) |
| `run_test_scenario` | 4 | Missing required `steps` (empty object) |
| `run_test_scenario` | 11 | Invalid step `type` not in enum |
| `run_test_scenario` | 15 | `steps` passed as string instead of array |
| `assert_node_state` | 9 | Missing required `path` |
| `assert_node_state` | 10 | Missing required `property` |
| `assert_node_state` | 11 | Missing required `expected` |
| `assert_node_state` | 14 | Invalid `operator` string (accepted by Zod, Godot-side error) |
| `assert_screen_text` | 5 | Missing required `text` (params given) |
| `assert_screen_text` | 6 | Missing required `text` (empty object) |
| `assert_screen_text` | 11 | `should_exist` is not a boolean |
| `run_stress_test` | 9 | `count` is a float (`.int()` rejects) |
| `run_stress_test` | 10 | `count` is a string |
| `run_stress_test` | 15 | `properties` is not an object |

---

## Required Project State

- **Godot version:** 4.x (tested with 4.7)
- **Project type:** 2D project recommended (simplest setup for Node2D-centric tests; 3D also works but requires 3D-specific nodes)
- **MCP plugin:** `addons/godot_mcp/` installed and **Active** in Project Settings → Plugins
- **MCP server:** Running and connected to the Godot editor via WebSocket
- **Autoload:** `mcp_runtime` must be registered in `project.godot`:
  ```ini
  [autoload]
  mcp_runtime="res://addons/godot_mcp/services/mcp_runtime.gd"
  ```
  > The path must NOT have a `*` prefix (which restricts to editor-only mode).
- **Main scene:** Must be configured in Project Settings (`application/run/main_scene`). The main scene is used when calling `play_scene` with `mode="main"`.

---

## Required Scenes

### Main scene (`res://scenes/testing_main.tscn`)

The running game scene must contain the following node hierarchy. All runtime scenarios assume this scene is loaded and the game is actively running.

```
Node2D (root, named "Game")
├── Player (Node2D)
│   ├── Sprite2D (Sprite2D)
│   └── CollisionShape2D (CollisionShape2D) [optional]
├── World (Node2D)
│   └── Entities (Node2D)
├── Root (Node2D)
└── UI (CanvasLayer)
    └── Label (Label, text="Start Game")
```

**Node details and rationale:**

| Node | Type | Rationale (scenario references) |
|------|------|--------------------------------|
| `Player` | `Node2D` | `assert_node_state` scenarios 1–8, 12–13, 15–19 reference `path: "Player"`. Must be at scene root. Must have `position`, `rotation`, `scale`, `visible`, `name`, `process_material` properties. |
| `Player/Sprite2D` | `Sprite2D` | `assert_node_state` scenario 17 references `path: "Player/Sprite2D"` for nested property `scale:x`. Must be a direct child of `Player`. |
| `World/Entities` | `Node2D` → `Node2D` | `run_stress_test` scenario 11 references `parent_path: "World/Entities"`. Must exist as a nested path. |
| `Root` | `Node2D` | `run_stress_test` scenario 14 references `parent_path: "Root"`. Must be at scene root. |
| `UI/Label` | `CanvasLayer` → `Label` | Required by `assert_screen_text` scenarios. Label must display text that can be detected on-screen. |

### Player node property requirements

The `Player` node must have these specific property values for `assert_node_state` comparison operator scenarios to pass:

| Property | Required value | Scenario |
|----------|---------------|----------|
| `name` | `"Player"` | Scenarios 1, 2, 7 |
| `position` (Vector2) | `(100, 200)` or any values where `x > 0` and `y < 1000` | Scenarios 3 (`position:x > 0`), 4 (`position:y < 1000`), 16 |
| `scale` (Vector2) | scale.x must be `>= 1.0` | Scenario 5 (`scale:x >= 1.0`) |
| `rotation` | `<= 3.14` | Scenario 6 (`rotation <= 3.14`) |
| `visible` | `true` | Scenario 15 (Boolean check) |
| `process_material` | `null` | Scenario 18 (null check) |

**Recommended initial `Player` node properties:**
```gdscript
position = Vector2(100, 200)   # satisfies x>0, y<1000
scale = Vector2(1.0, 1.0)       # satisfies scale.x >= 1.0
rotation = 0.0                  # satisfies <= 3.14
visible = true
process_material = null         # default for Node2D
```

### Player/Sprite2D child node properties

| Property | Required value | Scenario |
|----------|---------------|----------|
| `scale:x` | `2.0` | Scenario 17 (nested property assertion) |

---

## Required Resources

No external `.tres`/`.res` files, textures, materials, shaders, or audio files are required by any testing tool scenario. All scenarios operate on nodes created dynamically during the test or on the pre-existing scene hierarchy.

---

## Required Editor/Game State

### Game must be running

**All runtime scenarios** require the game to be actively running (play mode). The MCP server forwards runtime tool calls to `mcp_runtime` autoload, which only exists during gameplay.

Use `play_scene` with mode `"main"` (or `"custom"` with the testing scene path) before executing runtime tests.

### Per-tool runtime state requirements

| Tool | Required state |
|------|---------------|
| `run_test_scenario` (runtime scenarios) | Game running. Scenarios create and delete their own nodes — no pre-existing nodes required beyond the scene root and the `Listener` node for scenario 9 signal connection test. |
| `assert_node_state` | Game running. `Player` node and `Player/Sprite2D` child must exist. |
| `assert_screen_text` | Game running. UI text must be rendered on screen (a `Label` with text `"Start Game"` for positive tests; `"Game Over"` for scenario 2; anything for the negative/edge-case tests). |
| `run_stress_test` | Game running. Parent nodes `World/Entities` and `Root` must exist if testing those scenarios. Default scenarios (no `parent_path`) require nothing beyond the scene root. |
| `get_test_report` | Game running. At least one prior test must have been executed (for scenarios 1, 3–5). Scenario 2 (empty report) needs game running but no prior tests. |

### Note on `run_test_scenario` scenario 9 (connect_signal)

Scenario 9 connects `Timer.timeout` → `Listener._dummy`. The `Listener` node is created dynamically within the scenario as a `Node2D`. In Godot 4, `Object.connect()` does **not** validate method existence at connect time — validation happens at signal emission. Since the `Timer` is never started, the signal never fires and no error occurs. No script or method needs to be attached to `Listener`.

---

## Required Settings/Config

### Project settings (`project.godot`)

| Setting key | Required value | Purpose |
|-------------|---------------|---------|
| `application/run/main_scene` | `"res://scenes/testing_main.tscn"` | So `play_scene(mode="main")` loads the correct scene |

### Input actions

None required. No testing tool scenario references input actions or the InputMap.

### Collision layers

None required. No testing tool scenario references collision layers.

### Autoloads

| Name | Path | Required for |
|------|------|-------------|
| `mcp_runtime` | `res://addons/godot_mcp/services/mcp_runtime.gd` | All runtime scenarios (handles `testing/*` bridge calls during gameplay) |

### Addons / Packages

None required beyond the core `godot_mcp` plugin itself.

### Git repo

Not required. No scenario depends on version control state.

---

## Setup Script

The following GDScript can be executed in the Godot editor (via `execute_editor_script`) to create the testing scene and all required nodes. Alternatively, the scene can be built manually.

```gdscript
# Setup script for testing tools prerequisites
# Execute this in the Godot editor to create the testing scene.
# Run via: execute_editor_script(code=<this script>)

@tool
extends EditorScript

func _run() -> void:
	# 1. Create the scene
	var root := Node2D.new()
	root.name = "Game"

	# 2. Create Player node with required properties
	var player := Node2D.new()
	player.name = "Player"
	player.position = Vector2(100, 200)
	player.scale = Vector2(1.0, 1.0)
	player.rotation = 0.0
	player.visible = true
	root.add_child(player)
	player.set_owner(root)

	# 2a. Player/Sprite2D child for nested property test
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.scale = Vector2(2.0, 2.0)
	player.add_child(sprite)
	sprite.set_owner(root)

	# 3. World/Entities for stress test parent_path
	var world := Node2D.new()
	world.name = "World"
	root.add_child(world)
	world.set_owner(root)

	var entities := Node2D.new()
	entities.name = "Entities"
	world.add_child(entities)
	entities.set_owner(root)

	# 4. Root for stress test combined params test
	var stress_root := Node2D.new()
	stress_root.name = "Root"
	root.add_child(stress_root)
	stress_root.set_owner(root)

	# 5. UI with Label for assert_screen_text tests
	var canvas := CanvasLayer.new()
	canvas.name = "UI"
	root.add_child(canvas)
	canvas.set_owner(root)

	var label := Label.new()
	label.name = "Label"
	label.text = "Start Game"
	label.position = Vector2(20, 20)
	canvas.add_child(label)
	label.set_owner(root)

	# 6. Pack and save the scene
	var packed := PackedScene.new()
	packed.pack(root)

	var dir := "res://scenes"
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)

	ResourceSaver.save(packed, dir + "/testing_main.tscn")

	# 7. Set as main scene
	ProjectSettings.set_setting("application/run/main_scene", dir + "/testing_main.tscn")
	ProjectSettings.save()

	print("[Testing Prereqs] Scene created: ", dir + "/testing_main.tscn")
	print("[Testing Prereqs] Main scene set.")
	print("[Testing Prereqs] Ready for test execution.")
```

---

## Summary: Quick-start checklist

Before executing runtime test scenarios:

1. [ ] Godot 4.x editor is open with the target project
2. [ ] MCP plugin is **Active** (Project Settings → Plugins)
3. [ ] MCP server is running and connected (MCP tab shows "Connected")
4. [ ] `mcp_runtime` autoload is registered in `project.godot`
5. [ ] Main scene exists at `res://scenes/testing_main.tscn` with the node hierarchy described above
6. [ ] Project setting `application/run/main_scene` points to `res://scenes/testing_main.tscn`
7. [ ] Game is running (call `play_scene(mode="main")` or `play_scene(mode="custom", scene_path="res://scenes/testing_main.tscn")`)
8. [ ] Optionally verify: `get_game_scene_tree` shows the expected hierarchy
