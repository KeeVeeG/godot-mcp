# Prerequisites for Rendering Configuration Test Plan

> **Source:** `server/src/tools/rendering_config.ts` (121 lines, 9 tools)  
> **Shared types:** `server/src/tools/shared-types.ts` (exports `Quality`, `Size2D`, `z`)  
> **Bridge endpoints:** `rendering_config/get_settings`, `rendering_config/set_quality`, `rendering_config/set_renderer`, `rendering_config/set_anti_aliasing`, `rendering_config/set_shadow_quality`, `rendering_config/set_gi_quality`, `rendering_config/set_viewport_size`, `rendering_config/set_window_settings`, `rendering_config/get_rendering_info`

---

## Required Project State

- **Godot 4.x project** (any valid project — tested on 4.7). No specific template is required — works with 2D, 3D, or empty templates.
- **godot_mcp addon installed and active** in the project's `addons/godot_mcp/` directory. The plugin must be enabled in **Project → Project Settings → Plugins**.
- **MCP server running** — either via `npx -y @keeveeg/godot-mcp` or `node server/dist/index.js` (local dev). Server must bind to a port in the 6505–6514 range.
- **WebSocket bridge connected** — the Godot editor must show the MCP panel in the bottom dock with a green "Connected" status. All success-path tests require this. The `callGodot(bridge, ...)` call in every handler forwards over this connection.
- **Project file (`project.godot`) is writable** — all `set_*` tools modify project settings that persist to disk.
- **Note on Zod-only tests (~60% of scenarios):** Scenarios that test invalid params (wrong enum values, wrong types, missing required fields) are caught by Zod validation in the MCP server layer and never reach Godot. These require only a running MCP server — the Godot editor bridge does NOT need to be connected for Zod validation tests.

## Required Scenes

### `res://scenes/test_3d_basic.tscn` (for `get_rendering_info` Scenario 2 only)

This scene is required exclusively for `get_rendering_info` Scenario 2 ("Get rendering info during gameplay"), which needs non-zero draw call counts to meaningfully test runtime rendering stats.

**Node hierarchy:**

```
Node3D (root, named "Test3DBasic")
├── DirectionalLight3D (named "Sun")
│   └── properties: shadow_enabled = true, energy = 1.0
├── Camera3D (named "Camera")
│   └── properties: position = (0, 2, 5), current = true
└── MeshInstance3D (named "Cube1")
    ├── mesh: BoxMesh (size = 1,1,1)
    ├── position: (0, 0, 0)
    └── material: StandardMaterial3D (albedo_color = #FF4444)
```

**Alternative:** The test plan also says "cubes with materials, lights" — at minimum one visible mesh with a material and one light source. A single `MeshInstance3D` with a `StandardMaterial3D` and a `DirectionalLight3D` is sufficient.

**Note:** This scene is only needed for one scenario (out of ~150 total scenarios). All other scenarios work with any open scene or no scene at all.

## Required Resources

- **None.** All 9 tools operate on project-level rendering settings (stored in `project.godot`) and GPU/driver introspection. No `.tres` files, textures, shaders, materials, audio files, or custom resources are needed. The tools read/write settings keys like `rendering/renderer/...` directly via the Godot Editor API.

## Required Editor/Game State

### For all success-path tests (bridge-dependent scenarios)
- **Godot editor must be open** with the MCP project loaded.
- **MCP plugin must show "Connected"** in the bottom-panel MCP tab.
- **Editor can be in edit mode** for all scenarios except one.

### For `get_rendering_info` Scenario 2 only
- **Game must be running** (play mode active) via `play_scene` with the 3D test scene (see Required Scenes above).
- Before calling `get_rendering_info` in play mode, the scene must have been launched and at least one frame rendered so draw call counters are populated.

### For all `get_rendering_info` scenarios (Scenarios 1, 3)
- **Editor can be in edit mode** — no play mode required. The Godot `RenderingServer` and `Performance` singletons are available in edit mode.

### Not needed
- **No specific editor layout** (default layout works).
- **No specific tool selected** in the editor.
- **No breakpoints** need to be set.
- **No autoloads** other than the `mcp_runtime` autoload (installed automatically by the plugin).

## Required Settings/Config

All tools have `inputSchema` that defines their Zod validation. No specific Godot project settings must be pre-configured — the `set_*` tools themselves create or modify settings. The test plan explicitly says: "Consider resetting to defaults between test runs or documenting the initial state before each test."

### Recommended initial project state for deterministic test runs
- **Renderer:** `forward_plus` (Godot 4.x default)
- **Rendering quality:** `medium` (or whatever the project default is — document it)
- **Shadow quality:** `medium` (or default)
- **GI quality:** `medium` (or default)
- **Anti-aliasing:** all disabled (MSAA not set, FXAA false, TAA false) — or document initial state
- **Viewport size:** 1920×1080 (or whatever default the project uses)
- **Window mode:** `windowed`
- **Vsync:** `true` (Godot default)

### `godot_mcp_config.json` (optional)
No tools from this test plan need to be explicitly enabled — they are enabled by default. If the project has tool-disabling config, ensure none of these 9 tools are disabled:

```json
{
  "enabled_tools": {}
}
```

### Environment variables
- `GODOT_MCP_DEBUG` (optional) — set to any value to enable debug logging in the MCP server. Useful for diagnosing bridge communication failures during test runs.

## External State

- **No addons required** beyond the `godot_mcp` plugin itself.
- **No external packages** (npm packages are part of the server, already installed).
- **No git repo** required.
- **No internet access** required — all tools are local.
- **No platform-specific requirements** — tests work on Windows, macOS, and Linux.

## Setup Script

This GDScript can be run via `execute_editor_script` or `godot_execute_editor_script` to create the 3D test scene needed for `get_rendering_info` Scenario 2. It creates a minimal 3D scene with a cube, material, camera, and directional light.

```gdscript
# EditorScript: Run once to create the 3D test scene for get_rendering_info Scenario 2.
# Creates res://scenes/test_3d_basic.tscn

@tool
extends EditorScript

func _run():
	# Create root node
	var root := Node3D.new()
	root.name = "Test3DBasic"

	# DirectionalLight3D
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.shadow_enabled = true
	light.light_energy = 1.0
	root.add_child(light)
	light.owner = root

	# Camera3D
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 2, 5)
	camera.current = true
	root.add_child(camera)
	camera.owner = root

	# MeshInstance3D with BoxMesh and StandardMaterial3D
	var cube := MeshInstance3D.new()
	cube.name = "Cube1"
	cube.position = Vector3(0, 0, 0)
	cube.mesh = BoxMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.267, 0.267)  # #FF4444
	cube.set_surface_override_material(0, mat)
	root.add_child(cube)
	cube.owner = root

	# Pack and save scene
	var packed := PackedScene.new()
	packed.pack(root)
	var path := "res://scenes/test_3d_basic.tscn"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	ResourceSaver.save(packed, path)
	root.free()
	print("[Setup] Created ", path)
```

### Alternative: Using Godot MCP tools to create the scene

The same scene can be constructed via MCP tool calls (no EditorScript needed):

1. `godot_create_scene` → `{ "path": "res://scenes/test_3d_basic.tscn", "root_node_type": "Node3D" }`
2. `godot_setup_lighting` → `{ "parent": "", "type": "directional", "properties": { "shadow_enabled": true } }`
3. `godot_setup_camera_3d` → `{ "path": "", "properties": { "position": [0, 2, 5], "make_current": true } }`
4. `godot_add_mesh_instance` → `{ "parent": "", "mesh_type": "cube", "properties": { "position": [0, 0, 0] } }`
5. `godot_set_material_3d` → `{ "path": "Cube1", "properties": { "albedo_color": [1.0, 0.267, 0.267] } }`
6. `godot_save_scene` → `{}`

---

## Scenario-to-Prerequisite Mapping

| Scenario Category | Count | Godot Bridge Needed? | Specific Prerequisites |
|---|---|---|---|
| `get_rendering_settings` S1–S3 | 3 | Yes (S1, S3) | Bridge connected, any project |
| `get_rendering_settings` S2 | 1 | No | Zod validation only |
| `set_rendering_quality` S1–S4, S14 | 5 | Yes | Bridge connected |
| `set_rendering_quality` S5–S13 | 9 | No | Zod validation only |
| `set_renderer` S1–S4, S13 | 5 | Yes | Bridge connected |
| `set_renderer` S5–S12 | 8 | No | Zod validation only |
| `set_anti_aliasing` S1–S10, S19 | 11 | Yes | Bridge connected |
| `set_anti_aliasing` S11–S18 | 8 | No | Zod validation only |
| `set_shadow_quality` S1–S5, S12 | 6 | Yes | Bridge connected |
| `set_shadow_quality` S6–S11 | 6 | No | Zod validation only |
| `set_gi_quality` S1–S5, S12 | 6 | Yes | Bridge connected |
| `set_gi_quality` S6–S11 | 6 | No | Zod validation only |
| `set_viewport_size` S1–S17, S31 | 18 | Yes | Bridge connected |
| `set_viewport_size` S18–S30 | 13 | No | Zod validation only |
| `set_window_settings` S1–S12, S30 | 13 | Yes (S13–S14 forwarded to Godot) | Bridge connected |
| `set_window_settings` S15–S29 | 15 | No (Zod) / S13–S14 reach Godot | Zod validation only (except S13–S14) |
| `get_rendering_info` S1, S3 | 2 | Yes | Bridge connected, any open scene |
| `get_rendering_info` S2 | 1 | Yes | Bridge + play mode + 3D scene |
| `get_rendering_info` S4–S5 | 2 | No (S5) / Yes (S4) | Zod only (S5); bridge for S4 |
| Cross-tool Integration 1–7 | 7 | Yes | Bridge connected |

**Total scenarios:** ~157  
**Zod-only (no Godot needed):** ~65  
**Bridge-dependent (Godot needed):** ~92  
**Play mode required:** 1 (get_rendering_info S2)
