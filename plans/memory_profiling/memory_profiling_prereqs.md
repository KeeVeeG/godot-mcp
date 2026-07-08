# Prerequisites for memory_profiling_test_plan.md

> Generated from analysis of all 5 tools: `get_memory_usage`, `track_object_creation`, `find_memory_leaks`, `get_object_count`, `force_garbage_collection` + 4 integration scenarios.
> Source: `server/src/tools/memory_profiling.ts`
> Bridge endpoints: `get_memory_usage`, `track_object_creation`, `find_memory_leaks`, `get_object_count`, `force_garbage_collection`

---

## Required Project State

- **Godot editor connected to MCP server**: The WebSocket bridge between the Node.js MCP server and the Godot editor plugin must be active (port 6505–6514, auto-negotiated). Required for ALL scenarios except the explicit "Godot editor not connected" negative tests.
- **A Godot 4.x project is open**: Any valid Godot project with a scene loaded in the editor. No specific template required — empty/default 2D or 3D project suffices for most scenarios.
- **At least one scene must be open in the editor**: Required for `get_memory_usage` (memory categories populated), `find_memory_leaks` (scene tree analysis), `get_object_count` (live object count > 0), and `force_garbage_collection`.
- **Game must be running (Play mode active)**: Required/recommended for:
  - `track_object_creation` all happy-path scenarios (objects may be created during tracking)
  - Integration Scenario 1 (track → get_object_count for meaningful counts)
  - `find_memory_leaks` Scenario 2 (orphan nodes created via `execute_game_script`)
  - `force_garbage_collection` Scenario 2 (create/release temporary objects via `execute_game_script`)
  - `force_garbage_collection` Scenario 3 (two consecutive GC calls for meaningful delta)
- **Game NOT running (editor mode only)**: Required for:
  - `find_memory_leaks` Scenario 3 (clean empty project validation)
  - `get_object_count` baseline scenarios (stable object counts)

## Required Scenes

- **Any open scene with at least one Node2D in the hierarchy** — needed for `get_object_count` filtered-by-class sanity checks and `track_object_creation` to have a known class to baseline against. A simple scene with a root Node2D and a few children is sufficient.
- **Clean empty scene** (single root Node2D with no children, no scripts attached) — needed for `find_memory_leaks` Scenario 3 ("zero leaks detected" verification).
- **Scene prepared for orphan-node leak detection** — needed for `find_memory_leaks` Scenario 2:
  - Must have an `execute_editor_script`/`execute_game_script` call that creates unparented nodes (e.g., `var n = Node.new(); n.name = "orphan_test"; # never added to tree`) BEFORE calling `find_memory_leaks`.
- **Scene prepared for GC stress test** — needed for `force_garbage_collection` Scenario 2:
  - Must have an `execute_editor_script`/`execute_game_script` call that creates many temporary objects (e.g., `for i in range(1000): Resource.new()`) then nulls references BEFORE calling `force_garbage_collection`.

## Required Resources

- **None**: All 5 memory profiling tools operate on live engine state (runtime memory, object graph, GC). No `.tres`, `.res`, texture, material, shader, or audio files need to exist on disk for these tests.
- **No scripts need to exist in the project**: Object counts and memory usage are reported from the engine internals regardless of project scripts. Even the `find_memory_leaks` analysis inspects the runtime object graph, not files on disk.

## Required Editor/Game State

- **Execute_editor_script tool must be enabled**: Required for setup scripts in:
  - `find_memory_leaks` Scenario 2 (creating orphan nodes)
  - `force_garbage_collection` Scenario 2 (creating/releasing temporary objects)
  - Verify `execute_editor_script` is not disabled in `godot_mcp_config.json` (`enabled_tools.execute_editor_script !== false`).
- **Execute_game_script tool must be enabled**: Alternative to `execute_editor_script` for running the setup scripts during play mode.
- **No specific editor layout, tool selection, or breakpoints required**: These tools are purely data-query operations; no visual editor state matters.
- **No specific editor theme, scale, or font settings required**.

## Required Settings/Config

- **No specific project settings required** (`project.godot` defaults are fine).
- **No input actions, autoloads, or collision layers need to be configured**.
- **No addons or external packages required** beyond the `godot_mcp` plugin itself (which must be active for the bridge to work).
- **`mcp_runtime` autoload must be registered**: The `res://addons/godot_mcp/services/mcp_runtime.gd` autoload must be present in `project.godot`'s `[autoload]` section with `enabled=true` and NOT using the `*` prefix. Verify with: `godot_get_autoloads` should include `mcp_runtime`.
- **No git repository, export presets, or platform configuration required**.
- **Config file check**: `godot_mcp_config.json` (if present in project root) must NOT set `"execute_editor_script": false` or `"execute_game_script": false`, as these are needed for scenario setup.

## Required Bridge/Connection State

| Connection State | Required By | Tool Count |
|------------------|-------------|------------|
| **Connected** (Godot editor running, bridge active) | All happy-path and integration scenarios | 30+ scenarios |
| **Disconnected** (Godot editor NOT running, or bridge severed) | Negative test scenarios only | 5 scenarios (`get_memory_usage` Sc5, `track_object_creation` Sc15, `find_memory_leaks` Sc5, `get_object_count` Sc11, `force_garbage_collection` Sc5) |

## Runtime State Matrix

| Scenario Group | Editor Connected | Project Open | Scene Open | Game Running | Pre-Setup Script |
|---------------|-----------------|--------------|------------|--------------|------------------|
| `get_memory_usage` happy path (Sc1–Sc4) | ✅ | ✅ | ✅ | ❌ (optional) | ❌ |
| `get_memory_usage` disconnected (Sc5) | ❌ | ❌ | ❌ | ❌ | ❌ |
| `track_object_creation` happy path (Sc1–Sc5, Sc9, Sc13–14) | ✅ | ✅ | ✅ | ✅ (recommended) | ❌ |
| `track_object_creation` schema validation (Sc6–Sc8, Sc10–Sc12) | ❌ (Zod rejects before bridge) | ❌ | ❌ | ❌ | ❌ |
| `track_object_creation` disconnected (Sc15) | ❌ | ❌ | ❌ | ❌ | ❌ |
| `find_memory_leaks` happy path (Sc1, Sc4) | ✅ | ✅ | ✅ | ❌ | ❌ |
| `find_memory_leaks` with orphans (Sc2) | ✅ | ✅ | ✅ | ✅ | ✅ (create orphan nodes) |
| `find_memory_leaks` clean project (Sc3) | ✅ | ✅ | ✅ (clean empty scene) | ❌ | ❌ |
| `find_memory_leaks` disconnected (Sc5) | ❌ | ❌ | ❌ | ❌ | ❌ |
| `get_object_count` all scenarios (Sc1–Sc8, Sc11) | ✅ | ✅ | ✅ | ❌ | ❌ |
| `get_object_count` schema validation (Sc9–Sc10) | ❌ (Zod rejects) | ❌ | ❌ | ❌ | ❌ |
| `force_garbage_collection` happy path (Sc1, Sc4) | ✅ | ✅ | ✅ | ❌ | ❌ |
| `force_garbage_collection` with created objects (Sc2) | ✅ | ✅ | ✅ | ✅ | ✅ (create & release many objects) |
| `force_garbage_collection` consecutive (Sc3) | ✅ | ✅ | ✅ | ✅ (optional) | ❌ |
| `force_garbage_collection` disconnected (Sc5) | ❌ | ❌ | ❌ | ❌ | ❌ |
| Integration 1 (track → count) | ✅ | ✅ | ✅ | ✅ | ❌ |
| Integration 2 (memory → GC → memory) | ✅ | ✅ | ✅ | ❌ | ❌ |
| Integration 3 (leaks → GC → leaks) | ✅ | ✅ | ✅ | ❌ | ❌ |
| Integration 4 (memory schema check) | ✅ | ✅ | ✅ | ❌ | ❌ |

## Setup Scripts

### Script A: Create orphan nodes for `find_memory_leaks` Scenario 2

```gdscript
# Run via execute_editor_script or execute_game_script BEFORE calling find_memory_leaks
# Creates unparented nodes that should be detected as potential memory leaks

var orphan1 = Node.new()
orphan1.name = "orphan_test_1"
# Intentionally NOT added to scene tree

var orphan2 = Node2D.new()
orphan2.name = "orphan_test_2"
# Intentionally NOT added to scene tree

var orphan3 = Resource.new()
# Resource created but never assigned to anything

print("Created 3 orphan objects for leak detection test")
return "Orphans created: orphan_test_1, orphan_test_2, and 1 Resource"
```

### Script B: Create and release temporary objects for `force_garbage_collection` Scenario 2

```gdscript
# Run via execute_editor_script or execute_game_script BEFORE calling force_garbage_collection
# Creates many temporary objects, then releases all references so GC has work to do

var temp_objects = []
for i in range(500):
	temp_objects.append(Node.new())
	temp_objects.append(Resource.new())

# Null out the array to release all references
temp_objects.clear()
temp_objects = []

print("Created and released 1000 temporary objects for GC stress test")
return "Released 1000 objects (500 Nodes + 500 Resources)"
```

### Script C: Create objects during game play for `track_object_creation` meaningful tracking

```gdscript
# Run via execute_game_script WHILE track_object_creation is running
# Creates several Node2D objects so tracking can detect new instances

for i in range(10):
	var n = Node2D.new()
	n.name = "tracked_node_" + str(i)
	get_tree().root.add_child(n)

print("Created 10 Node2D objects during tracking window")
return "10 Node2D objects added to scene tree"
```

---

## Test Execution Order Notes

1. **Negative tests first**: Run all "Godot editor not connected" scenarios (5 total) while the editor is closed. These are fast and independent.
2. **Schema validation tests second**: Run all Zod-rejection scenarios (7 total) — these don't require Godot at all and can be validated server-side.
3. **Happy-path no-setup third**: `get_memory_usage` Sc1–4, `get_object_count` Sc1–8, `force_garbage_collection` Sc1+Sc4, `find_memory_leaks` Sc1+Sc3–4, and all Integration scenarios except Integration 1. Run these with editor connected and any scene open.
4. **Pre-setup scenarios fourth**: Run `find_memory_leaks` Sc2 and `force_garbage_collection` Sc2 after executing setup scripts A and B.
5. **Game-running scenarios last**: `track_object_creation` Sc1–5+Sc9+Sc13–14 and Integration Scenario 1. Start the game, optionally run Script C during tracking for meaningful deltas.

## Quick Validation Checklist

Before running any test scenario, confirm:
- [ ] Godot editor is running (for connected scenarios)
- [ ] The MCP plugin shows "Connected" in the bottom dock
- [ ] At least one scene is open in the editor
- [ ] `execute_editor_script` is not disabled in config
- [ ] `mcp_runtime` autoload is registered and active
- [ ] For game-running scenarios: game is in play mode
- [ ] For disconnected scenarios: Godot editor is closed (or bridge manually severed)
- [ ] For schema validation scenarios: only the MCP server needs to be running (no Godot required)
