# Prerequisites for Profiling Test Plan

> **Source plan:** `server/src/test_plans/profiling_test_plan.md`
> **Covered tools:** `get_performance_monitors` (25 scenarios), `get_editor_performance` (9 scenarios)
> **Godot bridge endpoints:** `profiling/monitors`, `profiling/editor_performance`

---

## Required Project State

- A **Godot 4.x project** must be created and open in the Godot editor.
- The **Godot MCP addon** must be installed, enabled, and active (WebSocket connected).
- The **MCP server** (`server/dist/index.js` or `npx @keeveeg/godot-mcp`) must be running and bridged to the editor.
- The Godot plugin must implement these bridge endpoints:
  - `profiling/monitors` — returns `Performance` singleton monitor values keyed by name.
  - `profiling/editor_performance` — returns a curated editor-level performance snapshot.
- No specific project template (2D, 3D, or empty works). Any valid Godot 4.x project suffices.

| Scenario(s) | Connection Required |
|-------------|--------------------|
| All scenarios **except** those below | Godot editor **must be connected** |
| `get_performance_monitors` Scenario 23 | Godot editor **must NOT be connected** (simulate disconnection) |
| `get_editor_performance` Scenario 7 | Godot editor **must NOT be connected** (simulate disconnection) |

---

## Required Scenes

- **Any scene** (even an empty default scene with only a root node) is sufficient.
- The current open scene can be a brand-new empty scene created via `Scene → New Scene → 2D Scene` or `3D Scene`.
- No specific node hierarchy, named nodes, or component configurations are required for any scenario.
- **Implicit minimum**: A `Node` root exists (always true when a scene is open).

> **Note:** Scenarios 10 (`physics/active_objects`) and 11 (`navigation/active_maps`) assert values >= 0. In a fresh empty scene these will be 0, which is valid. Adding physics bodies or nav regions is unnecessary but yields more interesting non-zero data.

---

## Required Resources

- **None.** No `.tres`/`.res` files, textures, materials, shaders, audio files, or imported assets are required.
- The profiling tools read engine-internal counters only and never touch the project filesystem.

---

## Required Editor/Game State

| State | Requirement |
|-------|-------------|
| Play mode | **Not required.** Both tools work in edit mode. Running the game yields more interesting data (non-zero FPS, active physics, etc.) but is optional. |
| Editor layout | **Not required.** Any layout works. |
| Tool selected | **Not required.** Any active tool works. |
| Breakpoints | **Not required.** No breakpoints needed. |
| Editor idle/busy | Editor should be **idle** (not compiling scripts, not loading a large scene) to avoid timeouts. |

### Per-Scenario Editor State Notes

| Scenario | Special State |
|----------|---------------|
| `get_performance_monitors` Scenario 10 (`physics/active_objects`) | If test wants value > 0 (though plan only asserts >= 0), add any physics body to the scene (e.g., `StaticBody3D` + `CollisionShape3D`) |
| `get_performance_monitors` Scenario 11 (`navigation/active_maps`) | If test wants value > 0, add a `NavigationRegion3D` with a baked navmesh |
| `get_performance_monitors` Scenario 20 (1000-array stress) | Editor must be responsive; close heavy scenes to avoid compounding load |
| `get_editor_performance` Scenario 8 (rapid consecutive calls) | Editor should be stable; no heavy background operations in progress |

---

## Required Settings/Config

- **Godot MCP plugin** must be listed and **active** in `Project → Project Settings → Plugins`.
- The `mcp_runtime` autoload should be registered (handled by the plugin automatically):
  ```
  [autoload]
  mcp_runtime="res://addons/godot_mcp/services/mcp_runtime.gd"
  ```
  (Not strictly required for profiling tools since they use editor-only `Performance` singleton, but the plugin won't connect without it.)
- **No specific project settings**, input actions, collision layers, or feature flags are required.
- **No addons** beyond the MCP plugin itself are needed.
- **No git repository** initialization is needed.

---

## Disconnected-Scenario Prerequisites

For scenarios that test disconnected behavior (`get_performance_monitors#23`, `get_editor_performance#7`):

- Either **close the Godot editor** entirely, or
- **Disable the Godot MCP plugin** via `Project → Project Settings → Plugins → Godot MCP → Disable`, or
- **Stop the MCP server** process so the WebSocket bridge breaks.

The MCP tool call must be made **while** the bridge is in a disconnected state. The expected result is `isError: true` with a message like `"Godot request failed: ..."`.

---

## Setup Script

Since the profiling tools have **zero project-specific prerequisites**, the following script verifies the minimum viable state (but does not need to modify anything):

```gdscript
# setup_profiling_tests.gd
# Run this in the Godot editor's Script Editor to verify profiling test readiness.
# This does NOT set up anything — it only confirms the environment is in the expected state.

extends EditorScript

func _run() -> void:
	var errors := PackedStringArray()
	var warnings := PackedStringArray()
	
	# 1. Verify MCP plugin is installed
	var plugin := EditorInterface.get_editor_settings()
	if not FileAccess.file_exists("res://addons/godot_mcp/plugin.cfg"):
		errors.append("MCP addon not found at res://addons/godot_mcp/plugin.cfg")
	
	# 2. Verify bridge endpoints exist (best effort — these are in plugin code)
	if not FileAccess.file_exists("res://addons/godot_mcp/services/mcp_runtime.gd"):
		warnings.append("mcp_runtime.gd not found; profiling tools may still work (editor-only)")
	
	# 3. Verify Performance singleton is accessible
	var fps := Performance.get_monitor(Performance.TIME_FPS)
	if typeof(fps) != TYPE_FLOAT and typeof(fps) != TYPE_INT:
		errors.append("Performance.TIME_FPS returned non-numeric value: %s" % fps)
	
	# 4. Verify at least one scene is open
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		warnings.append("No scene is currently open. Tests will still work but object counts will be minimal.")
	
	# 5. Verify known monitors are accessible
	var known := ["time/fps", "time/process", "time/physics_process", "memory/static", "memory/static_max", "rendering/frame_time", "physics/fps", "physics/active_objects", "navigation/active_maps"]
	for name in known:
		# Godot 4.x: Performance.get_monitor() uses enum values, not strings.
		# This test just confirms the singleton itself works.
		pass  # Enum-based access is compile-time; string-based access depends on plugin implementation
	
	if errors.is_empty():
		print("[PASS] Profiling test prerequisites satisfied.")
	else:
		for err in errors:
			printerr("[FAIL] %s" % err)
	
	for warn in warnings:
		print("[WARN] %s" % warn)
```

### One-liner setup (if you need a fresh project)

```bash
# Create a minimal test project (requires Godot CLI)
# Godot doesn't have a CLI project creator for 4.x without --headless,
# so this is best done via the Godot Project Manager GUI.
#
# Steps:
#  1. Open Godot Project Manager
#  2. New Project → Empty → Name: "profiling_test" → Create
#  3. Project → Project Settings → Plugins → Godot MCP → Enable
#  4. Open any scene (or create a new empty Node3D scene)
#  5. Verify MCP panel shows "Connected"
```

---

## Summary Matrix

| Prerequisite Category | Required? | Details |
|-----------------------|-----------|---------|
| Specific Godot project template | **No** | Any project works |
| Specific scene with nodes | **No** | Empty scene suffices |
| Resources on disk (.tres, textures, etc.) | **No** | None needed |
| Game running (play mode) | **No** | Optional; yields richer data |
| Specific editor layout | **No** | Any layout works |
| Breakpoints set | **No** | None needed |
| Project settings customized | **No** | Defaults are fine |
| Input actions configured | **No** | None needed |
| Autoloads beyond mcp_runtime | **No** | Only plugin's own autoload |
| Collision layers named | **No** | Defaults are fine |
| Additional addons installed | **No** | Only godot_mcp itself |
| Git repository initialized | **No** | Not needed |
| **MCP plugin installed & connected** | **Yes** | Non-negotiable |
| **Bridge endpoints implemented** | **Yes** | `profiling/monitors`, `profiling/editor_performance` |
| **Godot 4.x editor running** | **Yes** | Performance singleton is Godot 4.x API |
| **For disconnect tests: editor NOT connected** | **Yes** | Only for scenarios #23 and #7 |
