# Prerequisites for tilemap_test_plan.md

## Required Project State

- A Godot 4.x project with the **Godot MCP plugin** active and connected to the MCP server.
- A single scene must be open at **`res://test_scenes/tilemap_test.tscn`** with a **`Node3D`** root node.
  - The root is `Node3D` because the plan covers both 2D TileMap tools (Tools 1–6) and 3D GridMap tools (Tools 7–11) in one scene.
  - TileMap nodes (inheriting `Node2D`) can be children of a `Node3D` root; GridMap nodes (inheriting `Node3D`) require a 3D ancestor.
- The project must use the **Forward+** or **Mobile** renderer (GridMap tools are 3D and need a 3D rendering backend).
- Directory `res://test_scenes/` must exist. Create via `godot_manage_asset(action="create_folder", path="res://test_scenes")` if absent.

## Required Scenes

### Primary test scene: `res://test_scenes/tilemap_test.tscn`

The scene must contain the following node hierarchy. All nodes are required BEFORE any test runs.

```
Node3D (scene root, named "TileMapTest")
├── TileMap [named: "TileMap"]                          # Primary TileMap for Tools 1–6 and IS-1
│   └── (tile_set assigned: res://test_scenes/tileset_basic.tres)
├── TileMap [named: "TileMap_NoTileSet"]                 # For test 5.2 (no TileSet assigned)
├── Sprite2D [named: "Sprite2D"]                         # For test 1.17 (set_cell on non-TileMap)
├── Node2D [named: "Node2D"]                             # For test 3.9 (get_cell on non-TileMap)
├── StaticBody2D [named: "StaticBody2D"]                 # For test 4.5 (clear on non-TileMap)
├── Area2D [named: "Area2D"]                             # For test 6.6 (get_used_cells on non-TileMap)
├── Level (Node3D) [named: "Level"]                      # Parent for nested path test 5.3
│   └── Layers (Node3D) [named: "Layers"]
│       └── Ground (Node3D) [named: "Ground"]
│           └── TileMap [named: "TileMap"]               # For test 5.3 (deep-path TileMap)
│               └── (tile_set assigned: res://test_scenes/tileset_basic.tres)
├── GridMap [named: "GridMap"]                           # Primary GridMap for Tools 7–11 and IS-2
│   └── (mesh_library assigned: res://test_scenes/meshlib_basic.res)
├── GridMap [named: "GridMap_NoMeshLib"]                 # For test 11.2 (no MeshLibrary assigned)
├── MeshInstance3D [named: "MeshInstance3D"]             # For test 7.14 (set_cell on non-GridMap)
├── Node3D [named: "Node3D"]                             # For test 8.8 (get_cell on non-GridMap)
├── Camera3D [named: "Camera3D"]                         # For test 9.4 (clear on non-GridMap)
├── CharacterBody3D [named: "CharacterBody3D"]           # For test 10.6 (get_used_cells on non-GridMap)
└── Sprite3D [named: "Sprite3D"]                         # For test 11.4 (get_info on non-GridMap)
```

### Node details

| Node path | Type | Needed by | Notes |
|-----------|------|-----------|-------|
| `.` (root) | `Node3D` | All tools | Scene root; must NOT be a TileMap or GridMap itself (test 1.16, 4.3). |
| `TileMap` | `TileMap` | Tools 1–6, IS-1 | Must have a TileSet assigned with at least source_id=0, atlas_coords [0,0], [1,0], [2,1]. |
| `TileMap_NoTileSet` | `TileMap` | Test 5.2 | Must have NO TileSet assigned. Used to test `tilemap_get_info` on a bare TileMap. |
| `Sprite2D` | `Sprite2D` | Test 1.17 | Must be a non-TileMap node. Used to verify `tilemap_set_cell` errors on wrong type. |
| `Node2D` | `Node2D` | Test 3.9 | Must be a non-TileMap node. Used to verify `tilemap_get_cell` errors on wrong type. |
| `StaticBody2D` | `StaticBody2D` | Test 4.5 | Must be a non-TileMap node. Used to verify `tilemap_clear` errors on wrong type. |
| `Area2D` | `Area2D` | Test 6.6 | Must be a non-TileMap node. Used to verify `tilemap_get_used_cells` errors on wrong type. |
| `Level/Layers/Ground/TileMap` | `TileMap` | Test 5.3 | Deeply nested TileMap (4 levels deep). Must have a TileSet assigned. Used to verify deep path resolution for `tilemap_get_info`. |
| `GridMap` | `GridMap` | Tools 7–11, IS-2 | Must have a MeshLibrary assigned with at least items 0–5 (simple meshes). Required for `gridmap_set_cell` with positive item IDs. |
| `GridMap_NoMeshLib` | `GridMap` | Test 11.2 | Must have NO MeshLibrary assigned. Used to test `gridmap_get_info` on a bare GridMap. |
| `MeshInstance3D` | `MeshInstance3D` | Test 7.14 | Must be a non-GridMap node. Used to verify `gridmap_set_cell` errors on wrong type. |
| `Node3D` | `Node3D` | Test 8.8 | Must be a non-GridMap node. Used to verify `gridmap_get_cell` errors on wrong type. |
| `Camera3D` | `Camera3D` | Test 9.4 | Must be a non-GridMap node. Used to verify `gridmap_clear` errors on wrong type. |
| `CharacterBody3D` | `CharacterBody3D` | Test 10.6 | Must be a non-GridMap node. Used to verify `gridmap_get_used_cells` errors on wrong type. |
| `Sprite3D` | `Sprite3D` | Test 11.4 | Must be a non-GridMap node. Used to verify `gridmap_get_info` errors on wrong type. |

## Required Resources

Resources must exist on disk BEFORE tests that reference them:

| Resource path | Type | Required by | Notes |
|---------------|------|-------------|-------|
| `res://test_scenes/tileset_basic.tres` | `TileSet` | Tools 1–6, IS-1 | Must contain at least one TileSetAtlasSource (source_id=0) with tiles at atlas coordinates [0,0], [1,0], and [2,1]. See creation details below. |
| `res://test_scenes/meshlib_basic.res` | `MeshLibrary` | Tools 7–10, IS-2 | Must contain at least items 0, 1, 2, 3, 4, 5 with valid Mesh resources (e.g., BoxMesh, SphereMesh). See creation details below. |

### Resource creation details

**`res://test_scenes/tileset_basic.tres`** — A `TileSet` resource with one `TileSetAtlasSource` (source_id=0). The atlas source requires a texture. The simplest approach:
1. Generate a small colored texture (e.g., 48×16 white PNG) via GDScript or MCP texture tools
2. Save it as `res://test_scenes/tile_atlas.png`
3. Create the TileSet, add a `TileSetAtlasSource` with that texture (tile size 16×16), providing a 3×1 grid of tiles at atlas coords [0,0], [1,0], [2,1]

**`res://test_scenes/meshlib_basic.res`** — A `MeshLibrary` resource with at least 6 items:
- Item 0: `BoxMesh` (size 1,1,1)
- Item 1: `SphereMesh` (radius 0.5)
- Item 2: `CylinderMesh` (radius 0.5, height 2)
- Item 3: `BoxMesh` (size 2,1,1) — for overwrite test 7.5
- Item 4: `CapsuleMesh` (radius 0.3, height 1.5)
- Item 5: `PrismMesh` (size 1,1,1)

Items 0, 1, 2 are required for IS-2 integration scenario (full lifecycle). Item 3 is needed for test 7.5 (overwrite). Item 999 is intentionally absent (test 7.6 boundary).

## Required Editor/Game State

- **Editor must be in edit mode** (not play mode). All TileMap and GridMap tools operate on the editor scene tree. No runtime tests exist in this plan.
- **No game running**. `godot_play_scene` must NOT be active.
- **The test scene (`res://test_scenes/tilemap_test.tscn`) must be the active/open scene** in the editor. Use `godot_open_scene` before running tests.
- **No editor dialogs blocking**. The scene must be fully loaded and editable.
- **Default editor layout** is sufficient. No specific layout, tool, or breakpoint required.

## Required Settings/Config

- No specific `project.godot` settings beyond defaults for a 3D project.
- No input actions are needed.
- No autoloads beyond the MCP plugin's built-in autoload (`mcp_runtime`) are needed.
- No custom collision layers are needed.
- No addons beyond `godot_mcp` are required.

## Test Execution Order

The prerequisites can be set up in this order using MCP tool calls:

| Step | Action | What it creates |
|------|--------|-----------------|
| 1 | `godot_manage_asset(action="create_folder", path="res://test_scenes")` | Ensure directory exists |
| 2 | `godot_create_scene(path="res://test_scenes/tilemap_test.tscn", root_node_type="Node3D")` | Base scene with Node3D root |
| 3 | `godot_add_node(parent_path="", type="TileMap", name="TileMap")` | Primary TileMap |
| 4 | `godot_add_node(parent_path="", type="TileMap", name="TileMap_NoTileSet")` | Bare TileMap for test 5.2 |
| 5 | `godot_add_node(parent_path="", type="Sprite2D", name="Sprite2D")` | Error-test target |
| 6 | `godot_add_node(parent_path="", type="Node2D", name="Node2D")` | Error-test target |
| 7 | `godot_add_node(parent_path="", type="StaticBody2D", name="StaticBody2D")` | Error-test target |
| 8 | `godot_add_node(parent_path="", type="Area2D", name="Area2D")` | Error-test target |
| 9 | `godot_add_node(parent_path="", type="Node3D", name="Level")` | Nested path parent |
| 10 | `godot_add_node(parent_path="Level", type="Node3D", name="Layers")` | Intermediate nesting |
| 11 | `godot_add_node(parent_path="Level/Layers", type="Node3D", name="Ground")` | Intermediate nesting |
| 12 | `godot_add_node(parent_path="Level/Layers/Ground", type="TileMap", name="TileMap")` | Deep-path TileMap for test 5.3 |
| 13 | `godot_add_node(parent_path="", type="GridMap", name="GridMap")` | Primary GridMap |
| 14 | `godot_add_node(parent_path="", type="GridMap", name="GridMap_NoMeshLib")` | Bare GridMap for test 11.2 |
| 15 | `godot_add_node(parent_path="", type="MeshInstance3D", name="MeshInstance3D")` | Error-test target |
| 16 | `godot_add_node(parent_path="", type="Node3D", name="Node3D")` | Error-test target |
| 17 | `godot_add_node(parent_path="", type="Camera3D", name="Camera3D")` | Error-test target |
| 18 | `godot_add_node(parent_path="", type="CharacterBody3D", name="CharacterBody3D")` | Error-test target |
| 19 | `godot_add_node(parent_path="", type="Sprite3D", name="Sprite3D")` | Error-test target |
| 20 | **Create TileSet resource** (see Setup Script below) | `res://test_scenes/tileset_basic.tres` |
| 21 | `godot_update_property(path="TileMap", property="tile_set", value="res://test_scenes/tileset_basic.tres")` | Assign TileSet to primary TileMap |
| 22 | `godot_update_property(path="Level/Layers/Ground/TileMap", property="tile_set", value="res://test_scenes/tileset_basic.tres")` | Assign TileSet to nested TileMap |
| 23 | **Create MeshLibrary resource** (see Setup Script below) | `res://test_scenes/meshlib_basic.res` |
| 24 | `godot_update_property(path="GridMap", property="mesh_library", value="res://test_scenes/meshlib_basic.res")` | Assign MeshLibrary to primary GridMap |
| 25 | `godot_save_scene()` | Persist the scene |

**Note about TileSet creation:** Godot MCP does not have a dedicated `create_tileset` tool. The TileSet and MeshLibrary resources must be created via `godot_execute_editor_script` (see Setup Script below) or manually in the Godot editor before running tests.

## Setup Script

Run the following editor script via `godot_execute_editor_script` to create the scene and all required resources in one pass. This is the recommended approach instead of manual step-by-step creation.

```gdscript
# Executed via godot_execute_editor_script — creates all prerequisites for tilemap tests.
# Run this BEFORE executing any tilemap or gridmap test scenario.

@tool
extends EditorScript

func _run() -> void:
	var editor: EditorInterface = get_editor_interface()
	var undo_redo: EditorUndoRedoManager = editor.get_undo_redo()

	# Ensure directory exists
	DirAccess.make_dir_recursive_absolute("res://test_scenes")

	# ============================================================
	# 1. Create the test scene with Node3D root
	# ============================================================
	var root: Node3D = Node3D.new()
	root.name = "TileMapTest"

	# ---- 2D / TileMap nodes ----

	# Primary TileMap (will get TileSet assigned after resource creation)
	var tilemap: TileMap = TileMap.new()
	tilemap.name = "TileMap"
	root.add_child(tilemap)
	tilemap.owner = root

	# Bare TileMap with no TileSet (for test 5.2)
	var tilemap_no_set: TileMap = TileMap.new()
	tilemap_no_set.name = "TileMap_NoTileSet"
	root.add_child(tilemap_no_set)
	tilemap_no_set.owner = root

	# Non-TileMap 2D nodes for error-path tests
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = "Sprite2D"
	root.add_child(sprite)
	sprite.owner = root

	var node2d: Node2D = Node2D.new()
	node2d.name = "Node2D"
	root.add_child(node2d)
	node2d.owner = root

	var static_body: StaticBody2D = StaticBody2D.new()
	static_body.name = "StaticBody2D"
	root.add_child(static_body)
	static_body.owner = root

	var area: Area2D = Area2D.new()
	area.name = "Area2D"
	root.add_child(area)
	area.owner = root

	# Deeply nested TileMap for test 5.3 (Level/Layers/Ground/TileMap)
	var level: Node3D = Node3D.new()
	level.name = "Level"
	root.add_child(level)
	level.owner = root

	var layers: Node3D = Node3D.new()
	layers.name = "Layers"
	level.add_child(layers)
	layers.owner = root

	var ground: Node3D = Node3D.new()
	ground.name = "Ground"
	layers.add_child(ground)
	ground.owner = root

	var deep_tilemap: TileMap = TileMap.new()
	deep_tilemap.name = "TileMap"
	ground.add_child(deep_tilemap)
	deep_tilemap.owner = root

	# ---- 3D / GridMap nodes ----

	# Primary GridMap (will get MeshLibrary assigned after resource creation)
	var gridmap: GridMap = GridMap.new()
	gridmap.name = "GridMap"
	root.add_child(gridmap)
	gridmap.owner = root

	# Bare GridMap with no MeshLibrary (for test 11.2)
	var gridmap_no_lib: GridMap = GridMap.new()
	gridmap_no_lib.name = "GridMap_NoMeshLib"
	root.add_child(gridmap_no_lib)
	gridmap_no_lib.owner = root

	# Non-GridMap 3D nodes for error-path tests
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	mesh_inst.name = "MeshInstance3D"
	mesh_inst.mesh = BoxMesh.new()
	root.add_child(mesh_inst)
	mesh_inst.owner = root

	var node3d: Node3D = Node3D.new()
	node3d.name = "Node3D"
	root.add_child(node3d)
	node3d.owner = root

	var cam: Camera3D = Camera3D.new()
	cam.name = "Camera3D"
	root.add_child(cam)
	cam.owner = root

	var char_body: CharacterBody3D = CharacterBody3D.new()
	char_body.name = "CharacterBody3D"
	root.add_child(char_body)
	char_body.owner = root

	var sprite3d: Sprite3D = Sprite3D.new()
	sprite3d.name = "Sprite3D"
	root.add_child(sprite3d)
	sprite3d.owner = root

	# ============================================================
	# 2. Create TileSet resource
	# ============================================================
	# Generate a simple 48x16 white atlas texture
	var atlas_img: Image = Image.create(48, 16, false, Image.FORMAT_RGBA8)
	atlas_img.fill(Color(0.8, 0.4, 0.2, 1.0))  # orange-brown base
	# Draw colored regions for each tile cell
	atlas_img.fill_rect(Rect2i(0, 0, 16, 16), Color(0.3, 0.8, 0.3, 1.0))   # cell 0,0 = green
	atlas_img.fill_rect(Rect2i(16, 0, 16, 16), Color(0.3, 0.3, 0.8, 1.0))  # cell 1,0 = blue
	atlas_img.fill_rect(Rect2i(32, 0, 16, 16), Color(0.8, 0.3, 0.3, 1.0))  # cell 2,0 = red
	var atlas_tex: ImageTexture = ImageTexture.create_from_image(atlas_img)
	ResourceSaver.save(atlas_tex, "res://test_scenes/tile_atlas.png")

	# Create TileSet and add an atlas source
	var tileset: TileSet = TileSet.new()
	var atlas_source: TileSetAtlasSource = TileSetAtlasSource.new()
	atlas_source.texture = atlas_tex
	atlas_source.texture_region_size = Vector2i(16, 16)
	# Create tiles at atlas coords (0,0), (1,0), (2,0)
	# TileSetAtlasSource auto-creates tiles for the entire texture based on region size.
	# For 48x16 texture with 16x16 regions, tiles are created at (0,0), (1,0), (2,0).
	# We also need atlas_coords (2,1) referenced by test 1.2 but tile size is 16x16 and
	# the texture is 16px tall — so coord (2,1) would be out of bounds unless we
	# expand the texture. To keep things simple, expand atlas to 48x32.
	atlas_img = Image.create(48, 32, false, Image.FORMAT_RGBA8)
	atlas_img.fill(Color(0.8, 0.4, 0.2, 1.0))
	atlas_img.fill_rect(Rect2i(0, 0, 16, 16), Color(0.3, 0.8, 0.3, 1.0))    # [0,0] green
	atlas_img.fill_rect(Rect2i(16, 0, 16, 16), Color(0.3, 0.3, 0.8, 1.0))   # [1,0] blue
	atlas_img.fill_rect(Rect2i(32, 0, 16, 16), Color(0.8, 0.3, 0.3, 1.0))   # [2,0] red
	atlas_img.fill_rect(Rect2i(0, 16, 16, 16), Color(0.8, 0.8, 0.3, 1.0))   # [0,1] yellow
	atlas_img.fill_rect(Rect2i(16, 16, 16, 16), Color(0.8, 0.3, 0.8, 1.0))  # [1,1] purple
	atlas_img.fill_rect(Rect2i(32, 16, 16, 16), Color(0.3, 0.8, 0.8, 1.0))  # [2,1] cyan
	atlas_tex = ImageTexture.create_from_image(atlas_img)
	ResourceSaver.save(atlas_tex, "res://test_scenes/tile_atlas.png")

	atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = atlas_tex
	atlas_source.texture_region_size = Vector2i(16, 16)
	# Create tiles explicitly for each atlas cell
	for ax in range(3):
		for ay in range(2):
			atlas_source.create_tile(Vector2i(ax, ay))
	var source_id: int = tileset.add_source(atlas_source)
	# source_id should be 0 (first source added)
	assert(source_id == 0, "Expected source_id=0, got " + str(source_id))
	ResourceSaver.save(tileset, "res://test_scenes/tileset_basic.tres")
	print("Created res://test_scenes/tileset_basic.tres with source_id=0, atlas tiles at [0,0] through [2,1]")

	# Assign TileSet to both TileMaps
	tilemap.tile_set = tileset
	deep_tilemap.tile_set = tileset

	# ============================================================
	# 3. Create MeshLibrary resource
	# ============================================================
	var meshlib: MeshLibrary = MeshLibrary.new()

	# Item 0: BoxMesh
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(1, 1, 1)
	meshlib.create_item(0)
	meshlib.set_item_mesh(0, box)
	meshlib.set_item_name(0, "Box")
	meshlib.set_item_preview(0, box)

	# Item 1: SphereMesh
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	meshlib.create_item(1)
	meshlib.set_item_mesh(1, sphere)
	meshlib.set_item_name(1, "Sphere")
	meshlib.set_item_preview(1, sphere)

	# Item 2: CylinderMesh
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 2.0
	meshlib.create_item(2)
	meshlib.set_item_mesh(2, cyl)
	meshlib.set_item_name(2, "Cylinder")
	meshlib.set_item_preview(2, cyl)

	# Item 3: BoxMesh variant (for overwrite test 7.5)
	var box2: BoxMesh = BoxMesh.new()
	box2.size = Vector3(2, 1, 1)
	meshlib.create_item(3)
	meshlib.set_item_mesh(3, box2)
	meshlib.set_item_name(3, "BoxWide")
	meshlib.set_item_preview(3, box2)

	# Item 4: CapsuleMesh
	var cap: CapsuleMesh = CapsuleMesh.new()
	cap.radius = 0.3
	cap.height = 1.5
	meshlib.create_item(4)
	meshlib.set_item_mesh(4, cap)
	meshlib.set_item_name(4, "Capsule")
	meshlib.set_item_preview(4, cap)

	# Item 5: PrismMesh
	var prism: PrismMesh = PrismMesh.new()
	prism.size = Vector3(1, 1, 1)
	meshlib.create_item(5)
	meshlib.set_item_mesh(5, prism)
	meshlib.set_item_name(5, "Prism")
	meshlib.set_item_preview(5, prism)

	ResourceSaver.save(meshlib, "res://test_scenes/meshlib_basic.res")
	print("Created res://test_scenes/meshlib_basic.res with items 0–5")

	# Assign MeshLibrary to primary GridMap
	gridmap.mesh_library = meshlib

	# ============================================================
	# 4. Save the scene
	# ============================================================
	var packed: PackedScene = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://test_scenes/tilemap_test.tscn")
	print("Created res://test_scenes/tilemap_test.tscn")

	# Clean up in-memory nodes
	root.queue_free()

	print("TileMap & GridMap test prerequisites complete!")
	print("")
	print("Summary:")
	print("  Scene:       res://test_scenes/tilemap_test.tscn")
	print("  TileSet:     res://test_scenes/tileset_basic.tres (source_id=0, 3×2 atlas)")
	print("  MeshLibrary: res://test_scenes/meshlib_basic.res (items 0–5)")
	print("  TileMaps:    'TileMap' (with TileSet), 'TileMap_NoTileSet' (bare),")
	print("               'Level/Layers/Ground/TileMap' (deep-path, with TileSet)")
	print("  GridMaps:    'GridMap' (with MeshLibrary), 'GridMap_NoMeshLib' (bare)")
```

> **Note:** The setup script uses GDScript `EditorScript`. It must be run via `godot_execute_editor_script`. It can also be approximated with a sequence of MCP tool calls (`godot_create_scene`, `godot_add_node`, `godot_update_property`), but resource creation (TileSet with atlas source, MeshLibrary with items) requires editor scripting since there are no dedicated MCP tools for these resource types.

## Test Execution Dependencies

Some scenarios mutate scene state (set cells, fill rects, clear). The test executor must be aware of these dependencies:

| Scenario | Side Effect | Mitigation |
|----------|------------|------------|
| `tilemap_set_cell` (Tool 1) | Sets individual cells on `TileMap` | Other read-back tests may depend on these cells. Run Tool 1 first, then Tool 3 (get_cell), then Tool 6 (get_used_cells). |
| `tilemap_fill_rect` (Tool 2) | Fills 100×100 area (10,000 cells on test 2.5) | Fills may overlap previously set cells. Reload scene before Tool 2. |
| `tilemap_clear` (Tool 4) | Clears all cells from `TileMap` | Destroys data set by previous tools. Reload scene after Tool 4. |
| `gridmap_set_cell` (Tool 7) | Sets items on `GridMap` | Reload scene before Tool 8 (get_cell) to ensure clean state. |
| `gridmap_clear` (Tool 9) | Clears all items from `GridMap` | Destroys data. Reload scene after Tool 9. |
| IS-1 (TileMap lifecycle) | Sets, fills, and clears cells | Self-contained. Reload scene before and after. |
| IS-2 (GridMap lifecycle) | Sets and clears items | Self-contained. Reload scene before and after. |

### Recommended strategy

For predictable results, reload the clean test scene before each tool batch:

1. `godot_open_scene(path="res://test_scenes/tilemap_test.tscn")`
2. Run all scenarios for one tool
3. **Reopen the clean scene** before moving to the next tool

This avoids cross-test contamination, especially from `tilemap_clear` (Tool 4), `tilemap_fill_rect` large fill (test 2.5), and `gridmap_clear` (Tool 9).

## Quick-Check Before Running

Run these sanity checks via MCP tool calls to confirm all prerequisites are met:

| Check | Godot Tool Call | Expected Result |
|-------|----------------|-----------------|
| MCP connected | Any tool call succeeds | No connection error |
| Scene exists | `godot_open_scene(path="res://test_scenes/tilemap_test.tscn")` | Scene opens without error |
| Root is Node3D | `godot_get_scene_tree(max_depth=1)` | Root is named "TileMapTest" of type `Node3D` |
| `TileMap` exists | `godot_get_node_properties(path="TileMap")` | Properties returned; `tile_set` is not null |
| `TileMap` has TileSet | `godot_get_node_properties(path="TileMap", properties=["tile_set"])` | `tile_set` references `res://test_scenes/tileset_basic.tres` |
| `TileMap_NoTileSet` has no TileSet | `godot_get_node_properties(path="TileMap_NoTileSet", properties=["tile_set"])` | `tile_set` is null/empty |
| `Sprite2D` exists | `godot_get_node_properties(path="Sprite2D")` | Properties returned |
| `Node2D` exists | `godot_get_node_properties(path="Node2D")` | Properties returned |
| `StaticBody2D` exists | `godot_get_node_properties(path="StaticBody2D")` | Properties returned |
| `Area2D` exists | `godot_get_node_properties(path="Area2D")` | Properties returned |
| Deep-path TileMap exists | `godot_get_node_properties(path="Level/Layers/Ground/TileMap")` | Properties returned; type is `TileMap` |
| `GridMap` exists | `godot_get_node_properties(path="GridMap")` | Properties returned; `mesh_library` is not null |
| `GridMap` has MeshLibrary | `godot_get_node_properties(path="GridMap", properties=["mesh_library"])` | `mesh_library` references `res://test_scenes/meshlib_basic.res` |
| `GridMap_NoMeshLib` has no MeshLibrary | `godot_get_node_properties(path="GridMap_NoMeshLib", properties=["mesh_library"])` | `mesh_library` is null/empty |
| `MeshInstance3D` exists | `godot_get_node_properties(path="MeshInstance3D")` | Properties returned |
| `Node3D` exists | `godot_get_node_properties(path="Node3D")` | Properties returned |
| `Camera3D` exists | `godot_get_node_properties(path="Camera3D")` | Properties returned |
| `CharacterBody3D` exists | `godot_get_node_properties(path="CharacterBody3D")` | Properties returned |
| `Sprite3D` exists | `godot_get_node_properties(path="Sprite3D")` | Properties returned |
| TileSet has source_id=0 | `godot_get_resource_properties(type="TileSet")` or `godot_tilemap_get_info(path="TileMap")` | Returns tile_set with at least 1 source, source_id=0 present |
| MeshLibrary has items 0-3 | `godot_gridmap_get_info(path="GridMap")` | Returns mesh_library with items 0 through 5 listed |
