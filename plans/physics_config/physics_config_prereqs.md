# Prerequisites for physics_config_test_plan.md

> **Source plan:** `physics_config_test_plan.md`  
> **Tools covered:** `get_physics_settings`, `set_gravity`, `set_physics_fps`, `set_physics_engine`, `set_collision_layer_name`, `get_collision_layers`, `set_default_gravity`, `set_default_linear_damp` (8 tools)  
> **Generated:** 2026-07-08

---

## Required Project State

- **Godot 4.x project** (any type — 2D or 3D). All 8 tools operate on project-level physics settings (`ProjectSettings.set_setting` / `ProjectSettings.get_setting`), not on scene nodes. No specific scene content is required.
- **Godot MCP addon installed and active** (`addons/godot_mcp/` must be present in the project). The `mcp_runtime.gd` autoload is NOT required for these tests (all tools are editor-mode only).
- **Project must be savable** — every mutation tool calls `ProjectSettings.save()`. If the project.godot file is read-only or the filesystem is locked, success-path tests will fail.
- **Node.js MCP server running** (`server/dist/index.js`) and connected to the Godot editor via WebSocket (ports 6505-6514). All tools forward requests through `callGodot(bridge, ...)`.
- **Default project settings intact.** The success-path tests assume Godot's factory defaults:
  
  | Project Setting Key | Default Value | Type |
  |---|---|---|
  | `physics/2d/default_gravity_vector` | `(0, 1)` | Vector2 |
  | `physics/2d/default_gravity` | `980.0` | float |
  | `physics/3d/default_gravity_vector` | `(0, -9.8, 0)` | Vector3 |
  | `physics/3d/default_gravity` | `9.8` | float |
  | `physics/common/physics_ticks_per_second` | `60` | int |
  | `physics/2d/default_linear_damp` | `0.0` | float |
  | `physics/2d/default_angular_damp` | `1.0` | float |
  | `physics/3d/default_linear_damp` | `0.0` | float |
  | `physics/3d/default_angular_damp` | `0.0` | float |
  | `physics/2d/physics_engine` | `"DEFAULT"` | string |
  | `physics/3d/physics_engine` | `"DEFAULT"` | string |
  | `layer_names/3d_physics/layer_1` through `layer_32` | `""` (empty) | string |

  If any of these have been modified from defaults, the "happy path" scenarios may return unexpected values. **Recommendation:** start each test session from a fresh project or reset these settings before running the plan.

---

## Required Nodes in Scene

- **None.** All 8 tools in this plan operate on `ProjectSettings` — they read/write project-level configuration via the Godot Editor API. No scene, no nodes, no node hierarchy is needed. The editor can have NO scenes open and the tests will still pass.

---

## Required Resources

- **None.** No `.tres`, `.res`, textures, materials, shaders, audio files, or any other resource files are referenced or needed by these tools.

---

## Required Editor/Game State

- **Godot editor must be running** with the MCP plugin active and connected to the MCP server via WebSocket.
- **Play mode is NOT required.** All 8 tools are editor-mode only (they call `ProjectSettings.set_setting` / `ProjectSettings.get_setting`). The game does not need to be running.
- **No specific editor layout, tool selection, or breakpoints** are required.
- **No scenes need to be open.** The tools do not reference the scene tree.

---

## Required Settings/Config

- **Default project settings** as listed in the table above. All success-path scenarios expect Godot's factory defaults as the starting point.
- **No custom input actions, autoloads, or collision layer pre-configuration** required. The `get_collision_layers` tool reads `layer_names/3d_physics/layer_1` through `layer_32` — layers without custom names default to `"Layer N"` in the output.
- **`godot_mcp_config.json`** in the project root: none of these 8 tools are listed in the default disabled set, but verify that `set_collision_layer_name`, `set_physics_engine`, or any other tool in this plan is not disabled in the config.

---

## Required External State

- **No addons** beyond the Godot MCP addon itself are required.
- **Jolt Physics** is NOT required. The `set_physics_engine` → `"jolt"` scenario (S3) only tests Zod enum validation and forwarding — the test plan explicitly states: *"The test is for Zod validation, not Godot availability."* The bridge may return a runtime error if Jolt is not installed; either outcome is acceptable.
- **No git repository** initialization required.
- **No external files or network access** required.

---

## Known Implementation Details (Important for Test Expectations)

These are not prerequisites but critical facts from the GDScript bridge that affect what `get_physics_settings` returns vs. what the test plan expects:

1. **`set_gravity` normalizes the vector.** When you call `set_gravity({ x: 0, y: 980 })`, the bridge stores:
   - `physics/2d/default_gravity_vector = (0, 1)` (normalized)
   - `physics/2d/default_gravity = 980` (magnitude)
   - `physics/3d/default_gravity_vector = (0, 1, 0)` (normalized)
   - `physics/3d/default_gravity = 980` (magnitude)
   
   So `get_physics_settings` will return `gravity_2d.vector = {x:0, y:1}`, NOT `{x:0, y:980}`. The test plan's "verify with get_physics_settings" statements must account for this normalization.

2. **`set_physics_engine` only changes 3D engine.** The bridge sets `physics/3d/physics_engine` but NOT `physics/2d/physics_engine`. The 2D engine remains at `"DEFAULT"`.

3. **`set_collision_layer_name` only writes 3D layer names.** The bridge uses key `layer_names/3d_physics/layer_N`. 2D layer names (`layer_names/2d_physics/layer_N`) are NOT touched.

4. **`set_default_linear_damp` only changes 3D damping.** The bridge sets `physics/3d/default_linear_damp` but NOT `physics/2d/default_linear_damp`.

5. **`set_default_gravity` sets BOTH 2D and 3D** gravity magnitudes to the same value.

6. **Bridge rejects empty collision layer names.** The GDScript has `if name.is_empty(): return error`. So `set_collision_layer_name` Scenario 6 (empty string) will get a bridge-level error, not a Zod-level error. This differs from the test plan's assumption that "Godot may accept or reject."

7. **`set_gravity` zero-vector edge case.** Setting `{ x: 0, y: 0, z: 0 }` normalizes to `Vector3(0, 0, 0).normalized()` which in Godot returns `(0, 0, 0)` (not NaN). The magnitude is `0`. The test plan's Scenario 3 (zero gravity) should still work but the stored vector components will all be zero.

---

## Setup Script

The GDScript below can be run in the Godot editor (via `godot_execute_editor_script`) to reset all physics settings to factory defaults before a test run. Run this at the start of each test session to ensure a clean slate.

```gdscript
# Reset all physics configuration to Godot factory defaults.
# Run in the Godot editor before executing physics_config_test_plan.md.

@tool
extends EditorScript

func _run() -> void:
	# Reset gravity vectors and magnitudes
	ProjectSettings.set_setting("physics/2d/default_gravity_vector", Vector2(0, 1))
	ProjectSettings.set_setting("physics/2d/default_gravity", 980.0)
	ProjectSettings.set_setting("physics/3d/default_gravity_vector", Vector3(0, -9.8, 0))
	ProjectSettings.set_setting("physics/3d/default_gravity", 9.8)
	
	# Reset physics FPS
	ProjectSettings.set_setting("physics/common/physics_ticks_per_second", 60)
	
	# Reset damping
	ProjectSettings.set_setting("physics/2d/default_linear_damp", 0.0)
	ProjectSettings.set_setting("physics/2d/default_angular_damp", 1.0)
	ProjectSettings.set_setting("physics/3d/default_linear_damp", 0.0)
	ProjectSettings.set_setting("physics/3d/default_angular_damp", 0.0)
	
	# Reset physics engines
	ProjectSettings.set_setting("physics/2d/physics_engine", "DEFAULT")
	ProjectSettings.set_setting("physics/3d/physics_engine", "DEFAULT")
	
	# Reset collision layer names (all 32 layers to empty)
	for i in range(1, 33):
		ProjectSettings.set_setting("layer_names/3d_physics/layer_%d" % i, "")
	
	# Save all changes to project.godot
	var err: Error = ProjectSettings.save()
	if err != OK:
		printerr("Failed to save project settings: ", error_string(err))
	else:
		print("All physics settings reset to factory defaults.")
```

---

## Test Execution Order Notes

The test plan includes 86 individual scenarios across 8 tools plus 4 integration scenarios. For reliable results:

1. **Run the setup script** to reset all physics settings to defaults before starting.
2. **Run tools in the order they appear** in the test plan. Stateful tools (`set_gravity`, `set_physics_fps`, etc.) modify project settings that persist.
3. **Integration scenarios 1-4 should run last**, after all individual tool scenarios. They assume a known starting state and chain multiple tools.
4. **Re-run the setup script** between test plan executions to reset state.
5. **Invalid-param scenarios** (those expecting Zod errors) can run in any order since they never reach the bridge. They can be batched together.
