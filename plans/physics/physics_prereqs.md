# Prerequisites for Physics Tools Test Plan

**Source:** `server/src/test_plans/physics_test_plan.md`
**Total test scenarios:** 73+
**Total tools tested:** 8

---

## Required Project State

- Godot 4.x project with `addons/godot_mcp/` plugin installed and active
- MCP server connected to the Godot editor via WebSocket (bridge operational)
- Project type: **3D** — most tests use 3D vectors (`[1, 2, 3]`, `[0, -100, 0]`), 3D collision shapes (box, sphere, capsule, cylinder), and 3D node types (Camera3D)
- Note: `setup_collision` also supports 2D shapes (circle, rectangle, polygon). These may fail in a pure 3D scene context at Godot's level but pass Zod validation on the server side. For full coverage, a **separate 2D scene** is recommended for those enum-value tests.

---

## Required Scenes

### Primary Test Scene (3D) — `res://test_scenes/physics_test_3d.tscn`

This scene must be opened in the editor and contain the following node hierarchy:

```
Node3D (root, name: "PhysicsTestRoot")
├── Player (CharacterBody3D or RigidBody3D)
│   ├── Sprite2D (Sprite2D)                    ← nested node for path tests
│   └── Weapon (Node3D)                        ← nested parent for raycast tests
├── Floor (StaticBody3D)                        ← for physics material tests
│   ├── CollisionShape3D (box)
├── Ice (StaticBody3D)                          ← for friction boundary test
│   ├── CollisionShape3D (box)
├── Camera3D (Camera3D)                         ← for "node without collision" negative tests
├── Label (Label)                               ← for "node without physics body" negative tests
├── Sprite2D (Sprite2D)                         ← for "node without collision" negative tests
├── UI (Node3D)                                 ← parent for UI hierarchy
│   └── TitleLabel (Label)
└── Enemies (Node3D)                            ← container for enemy hierarchy
    └── Enemy1 (CharacterBody3D)                ← for nested path collision info test
        └── CollisionShape3D (sphere)
```

**Node configuration notes:**

| Node | Type | Required components | Notes |
|------|------|---------------------|-------|
| `Player` | CharacterBody3D or RigidBody3D | None by default (tests add body/collision/material) | Central test target — most scenarios reference `path: "Player"` |
| `Player/Sprite2D` | Sprite2D | None | Used for `setup_physics_body` Scenario 4 nested path test |
| `Player/Weapon` | Node3D | None | Used for `add_raycast` Scenario 7 nested parent path test |
| `Floor` | StaticBody3D | CollisionShape3D (box) | Used for `get_physics_material` Scenario 2 (body with no material) and `set_physics_material` Scenario 5 (all properties) |
| `Ice` | StaticBody3D | CollisionShape3D (box) | Used for `set_physics_material` Scenario 6 (friction = 0 boundary) |
| `Camera3D` | Camera3D | None | Used for `set_physics_layers` Scenario 18 (`get/set_physics_material` negative: node without collision) |
| `Label` | Label | None | Used for `get_collision_info` Scenario 5 (node without physics body) |
| `Sprite2D` | Sprite2D | None | Used for `get_physics_layers` Scenario 5 (node without collision) |
| `UI/TitleLabel` | Label | None | Used for `get_physics_material` Scenario 5 (node without collision object) |
| `Enemies/Enemy1` | CharacterBody3D or RigidBody3D | CollisionShape3D (sphere) | Used for `get_collision_info` Scenario 2 (nested node with physics body + collision) |

---

## Required Resources

None required on disk for Zod validation tests (they never reach Godot).

For tests that reach Godot and require existing configurations:
- **Physics material on some nodes**: `set_physics_material` and `get_physics_material` tools themselves create/assign materials, so pre-existing materials are only needed for `get_physics_material` Scenario 1 (reads back from node that has one).
- **Recommendation**: Run `set_physics_material` on `Player` with `friction=0.5, bounce=0.3` before running `get_physics_material` Scenario 1. The cross-tool workflow 1 does this naturally.

---

## Required Editor/Game State

| State | Required by | Notes |
|-------|------------|-------|
| Scene `res://test_scenes/physics_test_3d.tscn` open in editor | All scenarios that reach Godot | Tests operate on the currently open scene |
| Editor NOT in play mode | All scenarios | These are editor-mode tools (scene manipulation), not runtime tools |
| MCP bridge connected and responsive | All scenarios | Server ↔ Godot plugin WebSocket must be active |
| No unsaved changes or blocking dialogs in editor | All scenarios | May cause request timeouts |

---

## Required Settings / Config

| Setting / Config | Required by | Notes |
|-----------------|-------------|-------|
| Default project settings (no special overrides) | All scenarios | Project can use factory defaults |
| `addons/godot_mcp/` plugin enabled in Project Settings | All scenarios | Required for any Godot communication |
| (Optional) Collision layer names | `set_physics_layers` boundary tests | Not strictly required — layers 1-32 work with numeric IDs. Named layers are cosmetic. |

---

## Required External State

- Godot Editor must be running and have the MCP plugin connected
- No other tool operations should be running concurrently (sequential test execution expected)
- For 2D collision shape enum tests (circle, rectangle, polygon): a **separate 2D test scene** with a `Player` node of type `CharacterBody2D` or `RigidBody2D` would be ideal. These tests may fail at Godot's level in the 3D scene since 2D collision shapes cannot be added to 3D bodies.

---

## Setup Script

The following GDScript can be run via `godot_execute_editor_script` to create the primary test scene and all required nodes. Run this BEFORE executing any physics test scenarios.

```gdscript
# Physics Test Prerequisites Setup
# Creates res://test_scenes/physics_test_3d.tscn with all required nodes

extends EditorScript

func _run():
	# 1. Create root node
	var root = Node3D.new()
	root.set_name("PhysicsTestRoot")

	# 2. Create Player with children
	var player = CharacterBody3D.new()
	player.set_name("Player")
	root.add_child(player)
	player.set_owner(root)

	var player_sprite = Sprite2D.new()
	player_sprite.set_name("Sprite2D")
	player.add_child(player_sprite)
	player_sprite.set_owner(root)

	var weapon = Node3D.new()
	weapon.set_name("Weapon")
	player.add_child(weapon)
	weapon.set_owner(root)

	# 3. Create Floor with collision shape
	var floor = StaticBody3D.new()
	floor.set_name("Floor")
	root.add_child(floor)
	floor.set_owner(root)

	var floor_col = CollisionShape3D.new()
	floor_col.set_name("CollisionShape3D")
	floor.add_child(floor_col)
	floor_col.set_owner(root)
	var floor_box = BoxShape3D.new()
	floor_box.set_size(Vector3(10, 0.5, 10))
	floor_col.set_shape(floor_box)

	# 4. Create Ice with collision shape
	var ice = StaticBody3D.new()
	ice.set_name("Ice")
	root.add_child(ice)
	ice.set_owner(root)

	var ice_col = CollisionShape3D.new()
	ice_col.set_name("CollisionShape3D")
	ice.add_child(ice_col)
	ice_col.set_owner(root)
	var ice_box = BoxShape3D.new()
	ice_box.set_size(Vector3(10, 0.5, 10))
	ice_col.set_shape(ice_box)

	# 5. Create Camera3D
	var cam = Camera3D.new()
	cam.set_name("Camera3D")
	root.add_child(cam)
	cam.set_owner(root)

	# 6. Create standalone Label
	var label = Label.new()
	label.set_name("Label")
	root.add_child(label)
	label.set_owner(root)

	# 7. Create standalone Sprite2D
	var sprite = Sprite2D.new()
	sprite.set_name("Sprite2D")
	root.add_child(sprite)
	sprite.set_owner(root)

	# 8. Create UI container with TitleLabel
	var ui = Node3D.new()
	ui.set_name("UI")
	root.add_child(ui)
	ui.set_owner(root)

	var title_label = Label.new()
	title_label.set_name("TitleLabel")
	ui.add_child(title_label)
	title_label.set_owner(root)

	# 9. Create Enemies container with Enemy1
	var enemies = Node3D.new()
	enemies.set_name("Enemies")
	root.add_child(enemies)
	enemies.set_owner(root)

	var enemy1 = CharacterBody3D.new()
	enemy1.set_name("Enemy1")
	enemies.add_child(enemy1)
	enemy1.set_owner(root)

	var enemy_col = CollisionShape3D.new()
	enemy_col.set_name("CollisionShape3D")
	enemy1.add_child(enemy_col)
	enemy_col.set_owner(root)
	var enemy_sphere = SphereShape3D.new()
	enemy_sphere.set_radius(1.0)
	enemy_col.set_shape(enemy_sphere)

	# 10. Save scene to disk
	var dir = "res://test_scenes"
	DirAccess.make_dir_recursive_absolute(dir)

	var packed_scene = PackedScene.new()
	packed_scene.pack(root)
	ResourceSaver.save(packed_scene, dir + "/physics_test_3d.tscn")

	# 11. Open the scene in the editor
	EditorInterface.open_scene_from_path(dir + "/physics_test_3d.tscn")

	print("[Physics Prereqs] Test scene created: ", dir + "/physics_test_3d.tscn")
```

### Quick Setup Steps

1. Open Godot project with the MCP plugin active
2. Run the setup script above (or create the scene manually)
3. Verify the scene is open: `godot_get_scene_tree`
4. Verify key nodes exist: check `Player`, `Floor`, `Camera3D`, `Label`, `UI/TitleLabel`, `Enemies/Enemy1`
5. The scene is ready for all physics test scenarios

### Optional: 2D Test Scene

For full coverage of the 2D collision shape enum values (`circle`, `rectangle`, `polygon`), create a separate 2D scene:

```
Node2D (root)
└── Player (CharacterBody2D)
```

```gdscript
# 2D Physics Test Scene
extends EditorScript

func _run():
	var root = Node2D.new()
	root.set_name("PhysicsTest2DRoot")

	var player = CharacterBody2D.new()
	player.set_name("Player")
	root.add_child(player)
	player.set_owner(root)

	DirAccess.make_dir_recursive_absolute("res://test_scenes")
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://test_scenes/physics_test_2d.tscn")
```
```

---

## Test Execution Order Recommendations

To minimize manual setup between test runs, execute tests in this order:

### Phase 1: Zod Validation Tests (no Godot interaction)
These 32 scenarios test server-side parameter validation only. They can run with any scene loaded (or even no scene).

- `setup_physics_body`: Scenarios 5, 6, 7
- `setup_collision`: Scenarios 11, 12, 13, 14
- `set_physics_layers`: Scenarios 9, 10, 11, 12, 13, 14, 15, 16
- `get_physics_layers`: Scenario 3
- `get_collision_info`: Scenario 3
- `add_raycast`: Scenario 8
- `get_physics_material`: Scenarios 3, 4
- `set_physics_material`: Scenarios 9, 10, 11, 14, 15, 16

### Phase 2: Error Path Tests (need scene with nodes but no special config)
These test Godot error responses for missing nodes or incompatible node types. Run with the 3D test scene loaded.

- `setup_physics_body`: Scenario 8 (NonExistentNode)
- `setup_collision`: Scenario 15 (GhostNode)
- `set_physics_layers`: Scenarios 17 (FakeNode), 18 (Camera3D — no collision)
- `get_physics_layers`: Scenarios 4 (MissingNode), 5 (Sprite2D — no collision)
- `get_collision_info`: Scenarios 4 (GhostBody), 5 (Label — no physics body)
- `add_raycast`: Scenario 9 (NonExistentParent)
- `get_physics_material`: Scenario 5 (UI/TitleLabel — no collision)
- `set_physics_material`: Scenarios 17 (NowhereNode), 18 (Camera3D — no collision)

### Phase 3: Happy Path — Setup Operations (create state)
These tests CREATE physics bodies, collision shapes, and materials. They build the state needed for Phase 4 and 5.

**scenario order matters —** some depend on previous steps:

1. `setup_physics_body` Scenarios 1-4 (add body to Player, root, nested)
2. `setup_collision` Scenarios 1-10, 16 (add various shapes to Player)
3. `add_raycast` Scenarios 1-7, 10 (add raycasts)

> **Warning**: Running setup_physics_body multiple times on the same node may add duplicate bodies. Consider reloading the scene between batches or testing additively.

### Phase 4: Happy Path — Layer/Material Configuration
These tests configure layers and materials on nodes that now have physics bodies + collision shapes (from Phase 3 or pre-existing).

1. `set_physics_layers` Scenarios 1-8 (set layers/masks on Player)
2. `set_physics_material` Scenarios 1-8, 12, 13, 19, 20, 21 (set materials on Player, Floor, Ice)

### Phase 5: Happy Path — Read Operations (verify state)
These tests READ back the state created in Phases 3-4.

1. `get_physics_layers` Scenarios 1, 2 (read back layers)
2. `get_collision_info` Scenarios 1, 2, 6 (read back collision info)
3. `get_physics_material` Scenarios 1, 2, 6 (read back materials)

### Phase 6: Cross-Tool Workflows
Run after all individual tests pass, or as integration verification.

- **Workflow 1**: Full pipeline on `Player` (body → collision → layers → material → verify)
- **Workflow 2**: Raycast setup on empty scene root

---

## Node State Requirements for Each Scenario Group

| Scenario Group | Minimum Node State Needed |
|---------------|--------------------------|
| `setup_physics_body` happy path | `Player` exists in scene; `Player/Sprite2D` exists; scene root supports physics body |
| `setup_collision` happy path | `Player` exists (ideally already has a physics body from `setup_physics_body`) |
| `set_physics_layers` happy path | `Player` has a physics body + collision shape |
| `set_physics_layers` Scenario 18 | `Camera3D` exists in scene (without collision) |
| `get_physics_layers` Scenario 1 | `Player` has a physics body with collision shape |
| `get_physics_layers` Scenario 5 | `Sprite2D` exists and has NO collision |
| `get_collision_info` Scenario 1 | `Player` has a physics body + collision shape |
| `get_collision_info` Scenario 2 | `Enemies/Enemy1` has a physics body + collision shape |
| `get_collision_info` Scenario 5 | `Label` exists and has NO physics body |
| `add_raycast` happy path | `Player` exists; `Player/Weapon` exists |
| `get_physics_material` Scenario 1 | `Player` has a physics body with an **assigned** physics material |
| `get_physics_material` Scenario 2 | `Floor` has a physics body but **no** physics material assigned |
| `get_physics_material` Scenario 5 | `UI/TitleLabel` exists and has NO collision object |
| `set_physics_material` happy path | `Player`, `Floor`, `Ice` exist (ideally with collision shape) |
| `set_physics_material` Scenario 18 | `Camera3D` exists (without collision) |
