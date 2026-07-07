# Profiling Tools — Test Plan

**Source file:** `server/src/tools/profiling.ts`  
**Number of tools:** 2  
**Godot bridge commands:** `profiling/monitors`, `profiling/editor_performance`  
**Godot implementation:** `addon/godot_mcp/commands/profiling_commands.gd`

---

## Known Monitor Names (from Godot implementation)

All 23 valid monitor names for `get_performance_monitors`:

| Category | Monitor Key | Performance Constant |
|----------|-------------|---------------------|
| Time | `time/fps` | `TIME_FPS` |
| Time | `time/physics_process_time` | `TIME_PHYSICS_PROCESS` |
| Time | `time/process_time` | `TIME_PROCESS` |
| Time | `time/navigation_process_time` | `TIME_NAVIGATION_PROCESS` |
| Memory | `memory/static` | `MEMORY_STATIC` |
| Memory | `memory/static_max` | `MEMORY_STATIC_MAX` |
| Objects | `object/object_count` | `OBJECT_COUNT` |
| Objects | `object/resource_count` | `OBJECT_RESOURCE_COUNT` |
| Objects | `object/node_count` | `OBJECT_NODE_COUNT` |
| Objects | `object/orphan_node_count` | `OBJECT_ORPHAN_NODE_COUNT` |
| Render | `render/total_objects_in_frame` | `RENDER_TOTAL_OBJECTS_IN_FRAME` |
| Render | `render/total_primitives_in_frame` | `RENDER_TOTAL_PRIMITIVES_IN_FRAME` |
| Render | `render/total_draw_calls_in_frame` | `RENDER_TOTAL_DRAW_CALLS_IN_FRAME` |
| Render | `render/video_mem_used` | `RENDER_VIDEO_MEM_USED` |
| Render | `render/texture_mem_used` | `RENDER_TEXTURE_MEM_USED` |
| Render | `render/buffer_mem_used` | `RENDER_BUFFER_MEM_USED` |
| Physics 2D | `physics/active_objects` | `PHYSICS_2D_ACTIVE_OBJECTS` |
| Physics 2D | `physics/collision_pairs` | `PHYSICS_2D_COLLISION_PAIRS` |
| Physics 2D | `physics/island_count` | `PHYSICS_2D_ISLAND_COUNT` |
| Physics 3D | `physics_3d/active_objects` | `PHYSICS_3D_ACTIVE_OBJECTS` |
| Physics 3D | `physics_3d/collision_pairs` | `PHYSICS_3D_COLLISION_PAIRS` |
| Physics 3D | `physics_3d/island_count` | `PHYSICS_3D_ISLAND_COUNT` |
| Navigation | `navigation/active_maps` | `NAVIGATION_ACTIVE_MAPS` |

---

## Tool 1: `get_performance_monitors`

**Description:** Get all performance monitor values (FPS, memory, physics, rendering, navigation)  
**Handler:** `callGodot(bridge, 'profiling/monitors', args)`  

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `monitors` | `array(string)` | No | — | Filter to specific monitor names only (e.g. `["time/fps", "memory/static"]`). Returns all monitors if omitted. |

**Expected result shape (all monitors):**
```json
{
  "result": {
    "time/fps": <number>,
    "time/physics_process_time": <number>,
    "time/process_time": <number>,
    "time/navigation_process_time": <number>,
    "memory/static": <number>,
    "memory/static_max": <number>,
    "object/object_count": <number>,
    "object/resource_count": <number>,
    "object/node_count": <number>,
    "object/orphan_node_count": <number>,
    "render/total_objects_in_frame": <number>,
    "render/total_primitives_in_frame": <number>,
    "render/total_draw_calls_in_frame": <number>,
    "render/video_mem_used": <number>,
    "render/texture_mem_used": <number>,
    "render/buffer_mem_used": <number>,
    "physics/active_objects": <number>,
    "physics/collision_pairs": <number>,
    "physics/island_count": <number>,
    "physics_3d/active_objects": <number>,
    "physics_3d/collision_pairs": <number>,
    "physics_3d/island_count": <number>,
    "navigation/active_maps": <number>
  }
}
```

**Note:** Unknown monitor names return per-key error dicts: `{"error": "Unknown monitor: <name>"}`.

### Happy Path — No filter (return all)

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 1 | Call with no arguments | `{}` | JSON with `result` containing all 23 monitor keys | Simplest invocation. All monitors returned. |
| 2 | Call with `monitors` omitted entirely | `{}` (or body without `monitors` key) | JSON with `result` containing all 23 monitor keys | `monitors` is optional; absence = all. |
| 3 | Call with empty array | `{"monitors": []}` | JSON with `result` containing all 23 monitor keys | Godot treats empty array same as omitted (`requested.size() > 0` check). |

### Happy Path — Specific Monitor Filters

Each known monitor name is tested individually and in category groups.

#### Time Monitors

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 4 | Filter: `time/fps` | `{"monitors": ["time/fps"]}` | `{"result": {"time/fps": <number>}}` | Single time monitor. |
| 5 | Filter: `time/physics_process_time` | `{"monitors": ["time/physics_process_time"]}` | `{"result": {"time/physics_process_time": <number>}}` | Single time monitor. |
| 6 | Filter: `time/process_time` | `{"monitors": ["time/process_time"]}` | `{"result": {"time/process_time": <number>}}` | Single time monitor. |
| 7 | Filter: `time/navigation_process_time` | `{"monitors": ["time/navigation_process_time"]}` | `{"result": {"time/navigation_process_time": <number>}}` | Single time monitor. |
| 8 | Filter: all time monitors | `{"monitors": ["time/fps", "time/physics_process_time", "time/process_time", "time/navigation_process_time"]}` | `{"result": <4 time keys>}` | All time monitors at once. |

#### Memory Monitors

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 9 | Filter: `memory/static` | `{"monitors": ["memory/static"]}` | `{"result": {"memory/static": <number>}}` | Single memory monitor. |
| 10 | Filter: `memory/static_max` | `{"monitors": ["memory/static_max"]}` | `{"result": {"memory/static_max": <number>}}` | Single memory monitor. |
| 11 | Filter: both memory monitors | `{"monitors": ["memory/static", "memory/static_max"]}` | `{"result": <2 memory keys>}` | Both memory monitors. |

#### Object Monitors

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 12 | Filter: `object/object_count` | `{"monitors": ["object/object_count"]}` | `{"result": {"object/object_count": <number>}}` | Single object monitor. |
| 13 | Filter: `object/resource_count` | `{"monitors": ["object/resource_count"]}` | `{"result": {"object/resource_count": <number>}}` | Single object monitor. |
| 14 | Filter: `object/node_count` | `{"monitors": ["object/node_count"]}` | `{"result": {"object/node_count": <number>}}` | Single object monitor. |
| 15 | Filter: `object/orphan_node_count` | `{"monitors": ["object/orphan_node_count"]}` | `{"result": {"object/orphan_node_count": <number>}}` | Single object monitor. |
| 16 | Filter: all object monitors | `{"monitors": ["object/object_count", "object/resource_count", "object/node_count", "object/orphan_node_count"]}` | `{"result": <4 object keys>}` | All object monitors. |

#### Render Monitors

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 17 | Filter: `render/total_objects_in_frame` | `{"monitors": ["render/total_objects_in_frame"]}` | `{"result": {"render/total_objects_in_frame": <number>}}` | Single render monitor. |
| 18 | Filter: `render/total_primitives_in_frame` | `{"monitors": ["render/total_primitives_in_frame"]}` | `{"result": {"render/total_primitives_in_frame": <number>}}` | Single render monitor. |
| 19 | Filter: `render/total_draw_calls_in_frame` | `{"monitors": ["render/total_draw_calls_in_frame"]}` | `{"result": {"render/total_draw_calls_in_frame": <number>}}` | Single render monitor. |
| 20 | Filter: `render/video_mem_used` | `{"monitors": ["render/video_mem_used"]}` | `{"result": {"render/video_mem_used": <number>}}` | Single render monitor. |
| 21 | Filter: `render/texture_mem_used` | `{"monitors": ["render/texture_mem_used"]}` | `{"result": {"render/texture_mem_used": <number>}}` | Single render monitor. |
| 22 | Filter: `render/buffer_mem_used` | `{"monitors": ["render/buffer_mem_used"]}` | `{"result": {"render/buffer_mem_used": <number>}}` | Single render monitor. |
| 23 | Filter: all render monitors | `{"monitors": ["render/total_objects_in_frame", "render/total_primitives_in_frame", "render/total_draw_calls_in_frame", "render/video_mem_used", "render/texture_mem_used", "render/buffer_mem_used"]}` | `{"result": <6 render keys>}` | All render monitors. |

#### Physics 2D Monitors

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 24 | Filter: `physics/active_objects` | `{"monitors": ["physics/active_objects"]}` | `{"result": {"physics/active_objects": <number>}}` | Single physics 2D monitor. |
| 25 | Filter: `physics/collision_pairs` | `{"monitors": ["physics/collision_pairs"]}` | `{"result": {"physics/collision_pairs": <number>}}` | Single physics 2D monitor. |
| 26 | Filter: `physics/island_count` | `{"monitors": ["physics/island_count"]}` | `{"result": {"physics/island_count": <number>}}` | Single physics 2D monitor. |
| 27 | Filter: all 2D physics monitors | `{"monitors": ["physics/active_objects", "physics/collision_pairs", "physics/island_count"]}` | `{"result": <3 physics 2D keys>}` | All 2D physics monitors. |

#### Physics 3D Monitors

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 28 | Filter: `physics_3d/active_objects` | `{"monitors": ["physics_3d/active_objects"]}` | `{"result": {"physics_3d/active_objects": <number>}}` | Single physics 3D monitor. |
| 29 | Filter: `physics_3d/collision_pairs` | `{"monitors": ["physics_3d/collision_pairs"]}` | `{"result": {"physics_3d/collision_pairs": <number>}}` | Single physics 3D monitor. |
| 30 | Filter: `physics_3d/island_count` | `{"monitors": ["physics_3d/island_count"]}` | `{"result": {"physics_3d/island_count": <number>}}` | Single physics 3D monitor. |
| 31 | Filter: all 3D physics monitors | `{"monitors": ["physics_3d/active_objects", "physics_3d/collision_pairs", "physics_3d/island_count"]}` | `{"result": <3 physics 3D keys>}` | All 3D physics monitors. |

#### Navigation Monitors

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 32 | Filter: `navigation/active_maps` | `{"monitors": ["navigation/active_maps"]}` | `{"result": {"navigation/active_maps": <number>}}` | Single navigation monitor. |

#### Cross-Category

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 33 | Filter: multiple categories | `{"monitors": ["time/fps", "memory/static", "render/total_draw_calls_in_frame"]}` | `{"result": {"time/fps": ..., "memory/static": ..., "render/total_draw_calls_in_frame": ...}}` | Mix of time, memory, and render. |
| 34 | Filter: all 23 monitors explicitly | `{"monitors": ["time/fps", "time/physics_process_time", "time/process_time", "time/navigation_process_time", "memory/static", "memory/static_max", "object/object_count", "object/resource_count", "object/node_count", "object/orphan_node_count", "render/total_objects_in_frame", "render/total_primitives_in_frame", "render/total_draw_calls_in_frame", "render/video_mem_used", "render/texture_mem_used", "render/buffer_mem_used", "physics/active_objects", "physics/collision_pairs", "physics/island_count", "physics_3d/active_objects", "physics_3d/collision_pairs", "physics_3d/island_count", "navigation/active_maps"]}` | `{"result": <all 23 keys>}` | Explicitly requesting every known monitor should return all. |

### Error Path — Unknown Monitor Names

**Godot behavior:** Unknown monitor names get per-key error dicts `{"error": "Unknown monitor: <name>"}`. Zod passes any string; validation happens in Godot.

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 35 | Single unknown monitor | `{"monitors": ["nonexistent/monitor"]}` | `{"result": {"nonexistent/monitor": {"error": "Unknown monitor: nonexistent/monitor"}}}` | Per-key error, not overall failure. Tool still succeeds. |
| 36 | Typo: missing slash | `{"monitors": ["timefps"]}` | `{"result": {"timefps": {"error": "Unknown monitor: timefps"}}}` | Bad format; Godot can't match. |
| 37 | Typo: `tim/fps` | `{"monitors": ["tim/fps"]}` | `{"result": {"tim/fps": {"error": "Unknown monitor: tim/fps"}}}` | Near-miss typo. |
| 38 | Wrong casing: `Time/FPS` | `{"monitors": ["Time/FPS"]}` | `{"result": {"Time/FPS": {"error": "Unknown monitor: Time/FPS"}}}` | Godot key matching is case-sensitive. |
| 39 | Extra suffix: `time/fps_extra` | `{"monitors": ["time/fps_extra"]}` | `{"result": {"time/fps_extra": {"error": "Unknown monitor: time/fps_extra"}}}` | Suffix makes it unknown. |
| 40 | Missing prefix: `fps` | `{"monitors": ["fps"]}` | `{"result": {"fps": {"error": "Unknown monitor: fps"}}}` | No category prefix. |
| 41 | Mix of known and unknown | `{"monitors": ["time/fps", "invalid/monitor", "memory/static"]}` | `{"result": {"time/fps": <number>, "invalid/monitor": {"error": "Unknown monitor: invalid/monitor"}, "memory/static": <number>}}` | Known keys succeed, unknown get errors. Mixed result. |
| 42 | Empty string in array | `{"monitors": [""]}` | `{"result": {"": {"error": "Unknown monitor: "}}}` | Empty string passes Zod (it's a valid string) but Godot won't match. |
| 43 | Special characters: `../etc` | `{"monitors": ["../etc"]}` | `{"result": {"../etc": {"error": "Unknown monitor: ../etc"}}}` | Path traversal string passes Zod, unknown to Godot. |

### Edge Cases — Type Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 44 | `monitors` as string | `{"monitors": "time/fps"}` | Zod validation error | `z.array(z.string())` rejects non-array. |
| 45 | `monitors` as number | `{"monitors": 42}` | Zod validation error | Array type check. |
| 46 | `monitors` as boolean | `{"monitors": true}` | Zod validation error | Array type check. |
| 47 | `monitors` as object | `{"monitors": {"key": "value"}}` | Zod validation error | Array type check. |
| 48 | `monitors` as null | `{"monitors": null}` | Zod validation error | `z.array(z.string()).optional()` rejects null (only undefined is "optional"). |
| 49 | Array with non-string element (number) | `{"monitors": ["time/fps", 123]}` | Zod validation error | `z.string()` rejects numbers inside array. |
| 50 | Array with non-string element (boolean) | `{"monitors": ["time/fps", false]}` | Zod validation error | `z.string()` rejects booleans inside array. |
| 51 | Array with non-string element (null) | `{"monitors": ["time/fps", null]}` | Zod validation error | `z.string()` rejects null inside array. |
| 52 | Array with non-string element (object) | `{"monitors": [{"name": "time/fps"}]}` | Zod validation error | `z.string()` rejects objects inside array. |
| 53 | Nested array | `{"monitors": [["time/fps"]]}` | Zod validation error | `z.string()` rejects array elements inside array. |
| 54 | Duplicate monitor names | `{"monitors": ["time/fps", "time/fps", "time/fps"]}` | Passes Zod; Godot returns `{"result": {"time/fps": <number>}}` (last write wins) | Duplicates in array are valid strings. Godot behavior: hash map, so last duplicate key wins silently. |
| 55 | Extremely long monitor name | `{"monitors": ["a".repeat(10000)]}` | Passes Zod; Godot returns per-key error | String length not validated by Zod. Godot won't match super-long fake names. |
| 56 | Unicode monitor name | `{"monitors": ["тайм/fps"]}` | `{"result": {"тайм/fps": {"error": "Unknown monitor: тайм/fps"}}}` | Unicode strings pass Zod; unknown to Godot. |

### Edge Cases — Bridge / Connectivity

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 57 | Editor disconnected | `{}` | Error: connection timeout or "Godot editor is not connected" | Standard disconnected behavior. |
| 58 | Editor disconnected with filter | `{"monitors": ["time/fps"]}` | Error: connection timeout | Filter should not affect timeout behavior. |
| 59 | Rapid repeated calls | Call 10× rapidly | All succeed; no race conditions | Stress test for concurrent access. |
| 60 | Extra unknown param | `{"monitors": ["time/fps"], "extra": true}` | Success (extra param ignored) | Zod ignores unknown keys. |

---

## Tool 2: `get_editor_performance`

**Description:** Get editor performance snapshot (FPS, timing, memory usage, object counts, render stats, physics activity)  
**Handler:** `callGodot(bridge, 'profiling/editor_performance')` (no args forwarded)  
**Parameters:** None (empty `inputSchema`)

**Expected result shape:**
```json
{
  "result": {
    "fps": <float>,
    "rating": "good" | "warning" | "critical",
    "timing": {
      "process_ms": <float>,
      "physics_ms": <float>
    },
    "memory": {
      "static_bytes": <float>,
      "static_mb": <string>,
      "video_bytes": <float>,
      "video_mb": <string>,
      "texture_bytes": <float>,
      "texture_mb": <string>
    },
    "objects": {
      "total": <int>,
      "nodes": <int>,
      "resources": <int>,
      "orphan_nodes": <int>
    },
    "render": {
      "draw_calls": <int>,
      "objects_in_frame": <int>,
      "primitives_in_frame": <int>
    },
    "physics": {
      "active_2d": <int>,
      "active_3d": <int>
    }
  }
}
```

**Rating thresholds (from Godot implementation):**
- **Editor mode** (scene not playing): FPS < 5 → `"critical"`, FPS < 15 → `"warning"`, else `"good"`
- **Play mode** (scene playing): FPS < 30 → `"critical"`, FPS < 50 → `"warning"`, else `"good"`

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 61 | Call with no arguments | `{}` | Valid JSON with `result` containing fps, rating, timing, memory, objects, render, physics | Simplest invocation. All sections present. |
| 62 | Call with extra ignored arg | `{"ignored": true}` | Valid JSON (extra arg ignored) | Zod ignores unknown keys since no schema is defined. |
| 63 | Call multiple times | `{}` × 3 | Each call returns current snapshot | Values may differ between calls (real-time). Keys/structure must be consistent. |

### Rating Logic Verification — Editor Mode (not playing)

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 64 | Editor mode, FPS ≥ 15 | `{}` (editor idle) | `rating: "good"` | Normal editor conditions should be "good". |
| 65 | Editor mode, FPS < 5 | `{}` (under heavy load) | `rating: "critical"` | Very low editor FPS. |

**Note:** Testing intermediate thresholds (FPS 5–15 = `"warning"`) and play-mode thresholds requires precise FPS control and is best done as a semi-automated scenario with manual load injection.

### Play Mode Rating Logic

These scenarios require the game to be running (`godot_play_scene`).

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 66 | Play mode, FPS ≥ 50 | `{}` (light scene running) | `rating: "good"` | High-performance play mode. |
| 67 | Play mode, 30 ≤ FPS < 50 | `{}` (moderate scene) | `rating: "warning"` | Borderline play performance. |
| 68 | Play mode, FPS < 30 | `{}` (heavy scene) | `rating: "critical"` | Poor play performance. |

### Response Structure Verification

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 69 | Verify `timing` sub-object | `{}` | `result.timing` has `process_ms` (float) and `physics_ms` (float) | Timing keys always present. |
| 70 | Verify `memory` sub-object | `{}` | `result.memory` has `static_bytes` (float), `static_mb` (string), `video_bytes` (float), `video_mb` (string), `texture_bytes` (float), `texture_mb` (string) | Memory keys always present. `*_mb` values are strings with 1 decimal. |
| 71 | Verify `memory.*_mb` format | `{}` | `static_mb`, `video_mb`, `texture_mb` are strings like `"12.3"` | Godot formats with `"%.1f"`, so values are strings with one decimal place. |
| 72 | Verify `objects` sub-object | `{}` | `result.objects` has `total` (int), `nodes` (int), `resources` (int), `orphan_nodes` (int) | Object keys always present. |
| 73 | Verify `render` sub-object | `{}` | `result.render` has `draw_calls` (int), `objects_in_frame` (int), `primitives_in_frame` (int) | Render keys always present. |
| 74 | Verify `physics` sub-object | `{}` | `result.physics` has `active_2d` (int), `active_3d` (int) | Physics keys always present. |

### Edge Cases — Bridge / Connectivity

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 75 | Editor disconnected | `{}` | Error: connection timeout or "Godot editor is not connected" | Standard disconnected behavior. |
| 76 | Call with `null` body | `null` | Valid JSON (body ignored, no schema) | MCP SDK may coerce null to `{}`. Either is acceptable. |
| 77 | Rapid repeated calls | `{}` × 10 | All succeed; no race conditions | Stress test for concurrent access. |

---

## Integration / Cross-Tool Scenarios

| # | Scenario | Steps | Expected result | Notes |
|---|----------|-------|-----------------|-------|
| 78 | Cross-verify monitors ↔ editor_performance | 1. `get_performance_monitors` (all)<br>2. `get_editor_performance`<br>3. Assert `editor.fps` ≈ `monitors["time/fps"]` | Both return consistent FPS values | Values should be very close (same frame or close). |
| 79 | Cross-verify memory values | 1. `get_performance_monitors({"monitors": ["memory/static", "render/video_mem_used", "render/texture_mem_used"]})`<br>2. `get_editor_performance`<br>3. Compare `monitors["memory/static"]` vs `editor.memory.static_bytes`, `monitors["render/video_mem_used"]` vs `editor.memory.video_bytes` | Values match | Editor summary derives from same monitor data. |
| 80 | Cross-verify object counts | 1. `get_performance_monitors({"monitors": ["object/object_count", "object/node_count", "object/resource_count", "object/orphan_node_count"]})`<br>2. `get_editor_performance`<br>3. Compare counts | `monitors["object/object_count"]` = `editor.objects.total`, etc. | Object counts consistent between raw and summary. |
| 81 | Cross-verify render stats | 1. `get_performance_monitors({"monitors": ["render/total_draw_calls_in_frame", "render/total_objects_in_frame", "render/total_primitives_in_frame"]})`<br>2. `get_editor_performance`<br>3. Compare values | `monitors["render/total_draw_calls_in_frame"]` = `editor.render.draw_calls`, etc. | Render stats consistent. |
| 82 | Cross-verify physics | 1. `get_performance_monitors({"monitors": ["physics/active_objects", "physics_3d/active_objects"]})`<br>2. `get_editor_performance`<br>3. Compare | `monitors["physics/active_objects"]` = `editor.physics.active_2d`, `monitors["physics_3d/active_objects"]` = `editor.physics.active_3d` | Physics values consistent. |
| 83 | Filter subset then get all — compare | 1. `get_performance_monitors({"monitors": ["time/fps", "memory/static"]})`<br>2. `get_performance_monitors({})`<br>3. Assert filtered values match same keys in all-results | Filtered values match unfiltered for common keys | Consistency check. |
| 84 | Profiling before/after scene load | 1. `get_editor_performance` (baseline)<br>2. `godot_open_scene` (load a heavy scene)<br>3. `get_editor_performance` (post-load)<br>4. Compare values | Memory and object counts increase after loading scene | Real-world workflow: monitor scene impact. |
| 85 | Profiling before/after play mode | 1. `get_editor_performance` (editor mode)<br>2. `godot_play_scene` (start game)<br>3. `get_editor_performance` (play mode)<br>4. Check `rating` threshold logic differs | Rating uses different thresholds in play vs. editor | Rating logic cross-check. |
| 86 | Filtered monitors in play mode | 1. `godot_play_scene`<br>2. `get_performance_monitors({"monitors": ["time/fps", "physics/active_objects"]})`<br>3. `godot_stop_scene` | Valid FPS and physics values during gameplay | Filters work during runtime. |
| 87 | Editor performance round-trip: edit → measure → edit | 1. `get_editor_performance` (baseline)<br>2. `godot_add_node` (add a simple node)<br>3. `get_editor_performance` (post-edit)<br>4. `godot_delete_node` (remove it)<br>5. `get_editor_performance` (post-cleanup) | Object count increases then decreases; other metrics stable | Verify tool works after editor mutations. |
| 88 | All monitors via filter → editor_performance full match | 1. `get_performance_monitors({"monitors": [...all 23 names...]})`<br>2. `get_editor_performance`<br>3. Validate all cross-references | Every monitor value matches its editor_performance counterpart | Full exhaustive cross-check. |

---

## Summary: Parameter Coverage

| Tool | Parameter | Type | Required | Default | Enums / Constraints |
|------|-----------|------|----------|---------|---------------------|
| `get_performance_monitors` | `monitors` | `array(string)` | No | — | 23 known valid strings (see table above). Unknown names return per-key errors. Empty array = all. |
| `get_editor_performance` | (none) | — | — | — | Returns summary with `rating` string: `"good"`, `"warning"`, `"critical"` (editor vs. play mode thresholds differ). |

---

## Summary: Coverage Statistics

| Category | Count |
|----------|-------|
| **Total scenarios** | **88** |
| `get_performance_monitors` scenarios | 60 (all 23 monitors individually + groups + error paths + edge cases) |
| `get_editor_performance` scenarios | 17 (happy path + rating + structure + edge cases) |
| Integration scenarios | 11 (cross-verification, lifecycle, round-trips) |
| Known monitor names covered | 23/23 (100%) |
| Unknown/error monitor names | 9 |
| Type validation scenarios | 13 |
| Zod rejection scenarios | 11 |
| Bridge/connectivity scenarios | 4 |
| Rating threshold scenarios | 7 |

**Coverage:** Every tool, every parameter, every monitor name, every response sub-key, rating thresholds for both editor and play mode, per-key error behavior for unknown monitors, array type validation, cross-tool data consistency, and lifecycle round-trips.
