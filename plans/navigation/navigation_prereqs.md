# Prerequisites for Navigation Tools Test Plan

**Source plan:** `server/src/test_plans/navigation_test_plan.md`
**Tools covered:** 10 tools, 79 scenarios
**Source file under test:** `server/src/tools/navigation.ts`

---

## Required Project State

- Godot 4.x editor open and running (tested with 4.7)
- Godot MCP plugin installed and active (`addons/godot_mcp/` present, plugin enabled in Project Settings → Plugins)
- MCP server running and connected to the Godot editor via WebSocket (ports 6505–6514)
- A Godot project that supports both 2D and 3D nodes (either a 3D project or a 2D project — 3D nodes require `forward_plus` or `mobile` renderer, not `gl_compatibility`)
- No other scenes open that might interfere (clean state)

### Project Settings Required

- No specific project settings are required by this test plan beyond defaults
- No custom input actions, autoloads, or collision layers are required

---

## Required Scenes

### Scene A: Empty/Clean Scene (for creation tests)

Used by: `setup_navigation_region` S1–S3,S5–S6,S10; `setup_navigation_agent` S1–S3,S5–S6; `setup_navigation_link` S1–S3,S5–S6,S8

**State:** A scene with only a root node (any type: Node2D, Node3D, or Control). No child nodes.

**How to create:**
- `godot_create_scene(path="res://test_nav_empty.tscn", root_node_type="Node2D")`
- Then `godot_open_scene(path="res://test_nav_empty.tscn")`

---

### Scene B: Scene With Parent Container Nodes

Used by: `setup_navigation_region` S4; `setup_navigation_agent` S4; `setup_navigation_link` S4,S7

**State:** Contains two empty container nodes at root level:

```
Root (Node2D)
├── Level (Node2D)    — empty container, no components
└── Character (Node2D) — empty container, no components
```

**How to create:**
1. Open Scene A or an empty scene
2. `godot_add_node(parent_path="", type="Node2D", name="Level")`
3. `godot_add_node(parent_path="", type="Node2D", name="Character")`

---

### Scene C: Scene With Navigation Infrastructure (for read/modify/delete/pathfinding tests)

Used by: `bake_navigation_mesh` S1–S3; `set_navigation_layers` S1–S4,S6–S10; `get_navigation_info` S1–S2; `remove_navigation_region` S1–S2; `remove_navigation_agent` S1–S2; `remove_navigation_link` S1–S2; `find_navigation_path` S1–S7

**State:**

```
Root (Node2D)
├── NavRegion (NavigationRegion2D)
│   └── (NavigationPolygon — set via bake; see below)
├── UnbakedRegion (NavigationRegion2D)
│   └── (no NavigationPolygon — intentionally unbaked)
├── NavAgent (NavigationAgent2D)
├── NavLink (NavigationLink2D)
│   └── (start_position: [0,0], end_position: [10,0], bidirectional: true, enabled: true)
├── SomeSprite (Sprite2D)
├── Level (Node2D)
│   ├── NavRegion (NavigationRegion2D)
│   └── NavLink (NavigationLink2D)
└── Character (Node2D)
    └── NavAgent (NavigationAgent2D)
```

**How to create (sequential):**

```
# Step 1: Create root-level nodes
godot_add_node(parent_path="", type="NavigationRegion2D", name="NavRegion")
godot_add_node(parent_path="", type="NavigationRegion2D", name="UnbakedRegion")
godot_add_node(parent_path="", type="NavigationAgent2D", name="NavAgent")
godot_add_node(parent_path="", type="NavigationLink2D", name="NavLink")
godot_add_node(parent_path="", type="Sprite2D", name="SomeSprite")

# Step 2: Create parent containers
godot_add_node(parent_path="", type="Node2D", name="Level")
godot_add_node(parent_path="", type="Node2D", name="Character")

# Step 3: Create nested nodes (use parent_path)
# Note: setup_navigation_region, setup_navigation_agent, setup_navigation_link tools
# should be used for these, adding NavigationRegion2D to "Level" etc.
# But for prerequisites, we can also use godot_add_node:
godot_add_node(parent_path="Level", type="NavigationRegion2D", name="NavRegion")
godot_add_node(parent_path="Level", type="NavigationLink2D", name="NavLink")
godot_add_node(parent_path="Character", type="NavigationAgent2D", name="NavAgent")

# Step 4: Bake the main NavRegion for pathfinding tests
godot_bake_navigation_mesh(path="NavRegion", properties={
    "cell_size": 0.3,
    "cell_height": 0.2,
    "agent_radius": 0.5
})

# Step 5 (optional): For 3D pathfinding tests, also create:
# A 3D variant scene is needed — see Scene D below
```

---

### Scene D: 3D Scene With Navigation Infrastructure (for 3D-specific tests)

Used by: `setup_navigation_region` S3; `setup_navigation_agent` S3; `setup_navigation_link` S3; `find_navigation_path` S2,S5

**State:**

```
Root (Node3D)
├── NavRegion3D (NavigationRegion3D)
│   └── (NavigationMesh — baked, covering area around [0,0,0] to [10,5,10])
└── NavAgent3D (NavigationAgent3D)
```

**How to create:**
1. `godot_create_scene(path="res://test_nav_3d.tscn", root_node_type="Node3D")`
2. `godot_open_scene(path="res://test_nav_3d.tscn")`
3. Add a NavigationRegion3D and bake it with coverage over the test area

---

## Required Resources

- **None.** This test plan does not require any `.tres`, `.res`, texture, material, shader, or audio files. All test scenarios use default navigation nodes with no external resource dependencies.

---

## Required Editor/Game State

### For All Tests

- **Editor state:** Stopped (not in play mode). All tests run against the editor scene tree, not the runtime scene tree.
- **Editor layout:** Default or any layout — no specific layout required.

### For Creation Tests (Phase 1)

- Scene A (empty scene) must be open

### For Read/Modify/Delete Tests (Phase 2–4)

- Scene C must be open (contains all navigation nodes)

### For 3D-Specific Tests

- Scene D must be open

### For Pathfinding Tests (Phase 5)

- Scene C open for 2D pathfinding
- Scene D open for 3D pathfinding
- NavRegion(s) must have baked navigation meshes covering the test coordinate areas

---

## Required Navigation Mesh Coverage

These prerequisites apply to the pathfinding tests in `find_navigation_path`:

| Scenario | Dimension | Start | End | Coverage Needed |
|----------|-----------|-------|-----|-----------------|
| S1 | 2D | [0, 0] | [100, 100] | A 2D navmesh must cover a rectangular area that includes both (0,0) and (100,100). Use a large NavigationRegion2D (e.g., navigation polygon of at least 200×200 units) and bake it. |
| S2 | 3D | [0, 0, 0] | [10, 5, 10] | A 3D navmesh must cover the area from (0,0,0) to (10,5,10). Use a NavigationRegion3D with a large enough mesh and bake it. |
| S3 | 2D (auto) | [0, 0] | [50, 50] | 2D navmesh covering the area. |
| S4 | 2D | [-10, -10] | [10, 10] | 2D navmesh covering the area. |
| S5 | 3D | [0, 0, 0] | [5, 5, 5] | 3D navmesh covering the area. |
| S6 | 2D | [10, 10] | [10, 10] | 2D navmesh that includes the point (10,10). |
| S7 | 2D | [0, 0] | [9999, 9999] | 2D navmesh that covers (0,0) but does NOT cover (9999,9999) — tests unreachable destination. |

**Key insight:** A single large 2D NavigationRegion2D with a baked navmesh covering at least the bounding box ([-10,-10], [100,100]) satisfies Scenarios 1, 3, 4, 6, and 7. For Scenario 7, the point [9999, 9999] is intentionally outside the navmesh to test unreachable destinations.

For 3D, a single NavigationRegion3D with a baked navmesh covering the bounding box ([0,0,0], [10,5,10]) satisfies Scenarios 2 and 5.

---

## Node Property Prerequisites

### For `bake_navigation_mesh` S6 (wrong node type)

A node named `SomeSprite` of type `Sprite2D` must exist at the scene root. This is already part of Scene C.

### For `get_navigation_info` S2 (unbaked region)

A node named `UnbakedRegion` of type `NavigationRegion2D` must exist at scene root WITHOUT a baked navigation polygon. This is already part of Scene C.

### For `get_navigation_info` S5 (wrong node type)

A node named `Sprite2D` of type `Sprite2D` must exist at scene root. This is already part of Scene C.

### For `remove_navigation_region` S5, `remove_navigation_agent` S5, `remove_navigation_link` S5 (wrong node type)

All three require a node named `Sprite2D` of type `Sprite2D` at scene root. This is shared — a single `Sprite2D` node satisfies all three.

---

## Setup Script

The following GDScript can be executed via `godot_execute_editor_script` to create all prerequisites in one shot. Run this against an empty project.

```gdscript
# Prerequisite Setup Script for Navigation Tests
# Execute via: godot_execute_editor_script(code=this_script)

@tool
extends EditorScript

func _run() -> void:
	var root := get_scene()

	# --- Scene A: Empty/clean scene ---
	var scene_a := PackedScene.new()
	scene_a.pack(Node2D.new())
	ResourceSaver.save(scene_a, "res://test_nav_empty.tscn")

	# --- Scene C: Full navigation infrastructure (2D) ---
	var scene_c := PackedScene.new()
	var scene_c_root := Node2D.new()
	scene_c_root.name = "SceneC_Root"
	scene_c.pack(scene_c_root)

	# Create NavigationRegion2D (baked) — root level
	var nav_region := NavigationRegion2D.new()
	nav_region.name = "NavRegion"
	scene_c_root.add_child(nav_region)
	nav_region.owner = scene_c_root
	# Configure navigation polygon for baking
	var nav_poly := NavigationPolygon.new()
	# Create a large rectangular polygon covering [-50,-50] to [150,150]
	var outline := PackedVector2Array([
		Vector2(-50, -50),
		Vector2(150, -50),
		Vector2(150, 150),
		Vector2(-50, 150)
	])
	nav_poly.add_outline(outline)
	nav_poly.make_polygons_from_outlines()
	nav_region.navigation_polygon = nav_poly

	# Create unbaked NavigationRegion2D — root level
	var unbaked_region := NavigationRegion2D.new()
	unbaked_region.name = "UnbakedRegion"
	scene_c_root.add_child(unbaked_region)
	unbaked_region.owner = scene_c_root
	# Intentionally: no navigation_polygon set

	# Create NavigationAgent2D — root level
	var nav_agent := NavigationAgent2D.new()
	nav_agent.name = "NavAgent"
	scene_c_root.add_child(nav_agent)
	nav_agent.owner = scene_c_root

	# Create NavigationLink2D — root level
	var nav_link := NavigationLink2D.new()
	nav_link.name = "NavLink"
	nav_link.start_position = Vector2(0, 0)
	nav_link.end_position = Vector2(10, 0)
	nav_link.bidirectional = true
	nav_link.enabled = true
	scene_c_root.add_child(nav_link)
	nav_link.owner = scene_c_root

	# Create Sprite2D for wrong-type tests — root level
	var sprite := Sprite2D.new()
	sprite.name = "SomeSprite"
	scene_c_root.add_child(sprite)
	sprite.owner = scene_c_root

	# Create "Level" container
	var level := Node2D.new()
	level.name = "Level"
	scene_c_root.add_child(level)
	level.owner = scene_c_root

	# Create nested NavigationRegion2D under Level
	var level_nav_region := NavigationRegion2D.new()
	level_nav_region.name = "NavRegion"
	level.add_child(level_nav_region)
	level_nav_region.owner = scene_c_root

	# Create nested NavigationLink2D under Level
	var level_nav_link := NavigationLink2D.new()
	level_nav_link.name = "NavLink"
	level.add_child(level_nav_link)
	level_nav_link.owner = scene_c_root

	# Create "Character" container
	var character := Node2D.new()
	character.name = "Character"
	scene_c_root.add_child(character)
	character.owner = scene_c_root

	# Create nested NavigationAgent2D under Character
	var char_nav_agent := NavigationAgent2D.new()
	char_nav_agent.name = "NavAgent"
	character.add_child(char_nav_agent)
	char_nav_agent.owner = scene_c_root

	ResourceSaver.save(scene_c, "res://test_nav_scene_c.tscn")

	# Bake the main NavRegion
	nav_region.bake_navigation_polygon(false)

	# --- Scene D: 3D navigation infrastructure ---
	var scene_d := PackedScene.new()
	var scene_d_root := Node3D.new()
	scene_d_root.name = "SceneD_Root"
	scene_d.pack(scene_d_root)

	var nav_region_3d := NavigationRegion3D.new()
	nav_region_3d.name = "NavRegion3D"
	scene_d_root.add_child(nav_region_3d)
	nav_region_3d.owner = scene_d_root
	# Configure a 3D navmesh source geometry
	var nav_mesh := NavigationMesh.new()
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_max_slope = 45.0
	nav_mesh.agent_max_climb = 0.9
	# Add a source geometry mesh (a simple plane)
	var mesh_instance := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(20, 20)
	mesh_instance.mesh = plane_mesh
	mesh_instance.name = "NavMeshSource"
	nav_region_3d.add_child(mesh_instance)
	mesh_instance.owner = scene_d_root
	# Set the source geometry mode
	nav_region_3d.navigation_mesh = nav_mesh

	var nav_agent_3d := NavigationAgent3D.new()
	nav_agent_3d.name = "NavAgent3D"
	scene_d_root.add_child(nav_agent_3d)
	nav_agent_3d.owner = scene_d_root

	ResourceSaver.save(scene_d, "res://test_nav_3d.tscn")

	# Bake the 3D navmesh
	nav_region_3d.bake_navigation_mesh(false)

	print("Navigation test prerequisites created successfully.")
	print("  Scene A (empty): res://test_nav_empty.tscn")
	print("  Scene C (2D infra): res://test_nav_scene_c.tscn")
	print("  Scene D (3D infra): res://test_nav_3d.tscn")
```

---

## Dependency Graph: Test Execution Order

Tests must be run in this order to avoid state conflicts:

### Phase 1: Creation Tests (Scene A or empty scene)
```
setup_navigation_region S1-S3,S5-S6,S8-S10
setup_navigation_agent S1-S3,S5-S6,S8
setup_navigation_link S1-S3,S5-S6,S8
```
These can all run against Scene A (empty). Each creates nodes that are then available for later phases.

### Phase 2: Tests Requiring Parent Nodes (Scene A + parent nodes)
```
# First: create parent nodes (via godot tools or setup script)
# Then run:
setup_navigation_region S4    (needs "Level" node)
setup_navigation_agent S4     (needs "Character" node)
setup_navigation_link S4,S7   (needs "Level" node)
```

### Phase 3: Tests Requiring Navigation Nodes (Scene C)
```
# Scene C must be open. Tests can run in any order:
bake_navigation_mesh S1-S3    (needs NavRegion)
bake_navigation_mesh S5-S6    (non-existent/wrong-type tests)
set_navigation_layers S1-S4,S6-S10  (needs NavRegion)
get_navigation_info S1-S2     (needs NavRegion + UnbakedRegion)
get_navigation_info S5        (needs SomeSprite/Sprite2D)
```

### Phase 4: Removal Tests (Scene C)
```
# Must run AFTER all tests that depend on the nodes to be removed
remove_navigation_region S1-S2  (removes NavRegion, Level/NavRegion)
remove_navigation_agent S1-S2   (removes NavAgent, Character/NavAgent)
remove_navigation_link S1-S2    (removes NavLink, Level/NavLink)
remove_navigation_region S4-S6  (edge cases: non-existent, wrong type, scene root)
remove_navigation_agent S4-S5   (edge cases)
remove_navigation_link S4-S5    (edge cases)
```

### Phase 5: Validation-Only Tests (any scene, any time)
```
setup_navigation_region S7     (Zod: missing path)
setup_navigation_agent S7      (Zod: missing path)
bake_navigation_mesh S4        (Zod: missing path)
set_navigation_layers S5       (Zod: missing path)
get_navigation_info S3         (Zod: missing path)
find_navigation_path S8-S14    (Zod: various validation)
```
These tests never reach Godot — they are rejected by Zod validation on the MCP server side. They can run against any scene (even none).

### Phase 6: Pathfinding Tests (Scene C for 2D, Scene D for 3D)
```
find_navigation_path S1,S3,S4,S6,S7  (2D — needs Scene C with baked navmesh)
find_navigation_path S2,S5           (3D — needs Scene D with baked navmesh)
```
These need the navmeshes already baked. Scene C and D from the setup script include already-baked navmeshes.

---

## Summary: What You Need Before Running Tests

1. **Godot 4.x editor** with a project open and MCP plugin connected
2. **Three scene files** on disk (create with setup script above):
   - `res://test_nav_empty.tscn` — empty Node2D scene
   - `res://test_nav_scene_c.tscn` — full 2D navigation infrastructure
   - `res://test_nav_3d.tscn` — 3D navigation infrastructure (only needed for 3D pathfinding)
3. **No runtime state** — all tests run in editor mode (game stopped)
4. **No external resources** — no textures, materials, shaders, audio, or `.tres` files needed
