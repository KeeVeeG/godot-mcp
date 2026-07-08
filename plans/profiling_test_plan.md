# Test Plan: profiling.ts

**File:** `server/src/tools/profiling.ts`
**Module:** Profiling — 2 tools for performance monitoring
**GDScript backend:** `addons/godot_mcp/commands/profiling_commands.gd`

---

## Prerequisites

Both tools require a **running Godot editor** with the MCP plugin active and connected via WebSocket.
Before running any test scenario, ensure:

1. Godot editor is open with a project loaded
2. MCP plugin is active (Project → Project Settings → Plugins → Godot MCP: Active)
3. MCP server is running and connected (check MCP tab in Godot bottom panel)
4. At least one scene is open in the editor

---

## Tool: `get_performance_monitors`

### Registration

```typescript
server.registerTool(
  'get_performance_monitors',
  {
    description: 'Get all performance monitor values (FPS, memory, physics, rendering, navigation)',
    inputSchema: {
      monitors: z.array(z.string()).optional()
        .describe('Filter to specific monitor names only (e.g. ["time/fps", "memory/static"]). Returns all monitors if omitted.'),
    },
  },
  async (args) => callGodot(bridge, 'profiling/monitors', args as Record<string, unknown>),
);
```

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `monitors` | `string[]` | No | Array of monitor names to filter. If omitted, returns all monitors. |

### Known Monitor Names (from GDScript backend)

**Time:**
- `time/fps`
- `time/physics_process_time`
- `time/process_time`
- `time/navigation_process_time`

**Memory:**
- `memory/static`
- `memory/static_max`

**Objects:**
- `object/object_count`
- `object/resource_count`
- `object/node_count`
- `object/orphan_node_count`

**Render:**
- `render/total_objects_in_frame`
- `render/total_primitives_in_frame`
- `render/total_draw_calls_in_frame`
- `render/video_mem_used`
- `render/texture_mem_used`
- `render/buffer_mem_used`

**Physics:**
- `physics/active_objects`
- `physics/collision_pairs`
- `physics/island_count`
- `physics_3d/active_objects`
- `physics_3d/collision_pairs`
- `physics_3d/island_count`

**Navigation:**
- `navigation/active_maps`

### Return Structure

On success, returns a JSON-RPC result wrapping:
```json
{
  "result": {
    "time/fps": <float>,
    "memory/static": <float>,
    ... // all monitors or filtered subset
  }
}
```

On unknown monitor name in filter:
```json
{
  "result": {
    "unknown_monitor_name": { "error": "Unknown monitor: unknown_monitor_name" }
  }
}
```

### Test Scenarios

#### Scenario 1: Happy path — no params, get all monitors

**Description:** Call `get_performance_monitors` with no arguments. Should return all available monitor values.

**Params:**
```json
{}
```

**Expected Result:**
- HTTP-level: MCP response with `isError` absent or `false`
- Response `content[0].text` is a JSON string containing `"result"` object
- The `result` object contains ALL known monitor keys: `time/fps`, `time/physics_process_time`, `time/process_time`, `time/navigation_process_time`, `memory/static`, `memory/static_max`, `object/object_count`, `object/resource_count`, `object/node_count`, `object/orphan_node_count`, `render/total_objects_in_frame`, `render/total_primitives_in_frame`, `render/total_draw_calls_in_frame`, `render/video_mem_used`, `render/texture_mem_used`, `render/buffer_mem_used`, `physics/active_objects`, `physics/collision_pairs`, `physics/island_count`, `physics_3d/active_objects`, `physics_3d/collision_pairs`, `physics_3d/island_count`, `navigation/active_maps`
- All values are numeric (float or int)
- `time/fps` is > 0 when editor is responsive

**Notes:** This is the baseline test. Verify the total count of keys matches 23 monitors listed above.

**What to pay attention to:** FPS values should be reasonable (> 0). Memory values (`memory/static`, `render/video_mem_used`) should be positive. `object/orphan_node_count` may be 0 in a clean project — that's normal.

---

#### Scenario 2: Filter to a single monitor

**Description:** Request only `time/fps` from the monitors.

**Params:**
```json
{
  "monitors": ["time/fps"]
}
```

**Expected Result:**
- Response contains `"result"` with exactly one key: `"time/fps"`
- No other monitor keys are present in the result
- Value is a positive number (float)

**Notes:** Verifies that the filter mechanism works for a single-item array.

**What to pay attention to:** The result should contain exactly one key. The FPS value should be > 0 when the editor is active.

---

#### Scenario 3: Filter to multiple monitors across categories

**Description:** Request a mix of monitors from different categories (time, memory, render, physics).

**Params:**
```json
{
  "monitors": ["time/fps", "memory/static", "render/total_draw_calls_in_frame", "physics_3d/active_objects"]
}
```

**Expected Result:**
- Response contains `"result"` with exactly 4 keys
- Each key maps to a numeric value
- No error entries in the result

**Notes:** Cross-category filtering should work identically to same-category filtering.

**What to pay attention to:** Verify that exactly 4 keys are returned with no extras. All values are numeric.

---

#### Scenario 4: Filter with unknown monitor name

**Description:** Request a monitor name that does not exist in the backend.

**Params:**
```json
{
  "monitors": ["nonexistent/monitor"]
}
```

**Expected Result:**
- Response is NOT an error (tool does not fail)
- Response `"result"` contains the key `"nonexistent/monitor"` with value `{"error": "Unknown monitor: nonexistent/monitor"}`
- No other keys in result

**Notes:** The GDScript backend gracefully handles unknown monitor names by returning an error object per name rather than failing the whole request.

**What to pay attention to:** The response should NOT be an error at the MCP level. The key for the unknown monitor should contain an object with an `error` field, not a number.

---

#### Scenario 5: Mix of valid and invalid monitor names

**Description:** Request some valid and some invalid monitor names simultaneously.

**Params:**
```json
{
  "monitors": ["time/fps", "invalid/name", "memory/static"]
}
```

**Expected Result:**
- Response contains `"result"` with 3 keys
- `"time/fps"` → numeric value
- `"memory/static"` → numeric value
- `"invalid/name"` → `{"error": "Unknown monitor: invalid/name"}`

**Notes:** The backend processes each name independently — valid ones return data, invalid ones return error objects.

**What to pay attention to:** Valid monitors should return numbers, invalid ones should return an error object. No single error should crash the entire request.

---

#### Scenario 6: Empty monitors array

**Description:** Pass an empty array for monitors — should behave the same as omitting the parameter.

**Params:**
```json
{
  "monitors": []
}
```

**Expected Result:**
- Response contains ALL monitors (same as Scenario 1)
- The GDScript backend checks `requested.size() > 0`, so an empty array falls through to the "return all" branch

**Notes:** Boundary condition — empty array should be treated as "no filter".

**What to pay attention to:** The result should be identical to scenario 1 (all monitors). Empty array ≠ `null`/absent parameter at the TypeScript level, but GDScript handles them the same way.

---

#### Scenario 7: Monitors array with non-string elements (invalid input)

**Description:** Pass non-string values in the monitors array to test input validation.

**Params:**
```json
{
  "monitors": [123, true, null]
}
```

**Expected Result:**
- Zod validation at the TypeScript layer: `z.array(z.string())` should reject non-string elements
- MCP returns a validation error before the request reaches Godot

**Notes:** This tests the Zod schema boundary. The GDScript backend casts elements with `as String`, but the TypeScript Zod schema should reject this upstream.

**What to pay attention to:** The error should occur at the TypeScript/Zod validation level, not on the Godot side. Verify that the response mentions schema validation.

---

## Tool: `get_editor_performance`

### Registration

```typescript
server.registerTool(
  'get_editor_performance',
  {
    description: 'Get editor performance snapshot (FPS, timing, memory usage, object counts, render stats, physics activity)',
    inputSchema: {},
  },
  async () => callGodot(bridge, 'profiling/editor_performance'),
);
```

### Parameters

None. This tool takes no parameters.

### Return Structure

On success, returns a structured performance summary:
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
      "static_mb": "<string>",
      "video_bytes": <float>,
      "video_mb": "<string>",
      "texture_bytes": <float>,
      "texture_mb": "<string>"
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

### Rating Logic (from GDScript)

| Context | FPS Range | Rating |
|---------|-----------|--------|
| Editor (not playing) | < 5 | `critical` |
| Editor (not playing) | 5–15 | `warning` |
| Editor (not playing) | ≥ 15 | `good` |
| Playing scene | < 30 | `critical` |
| Playing scene | 30–50 | `warning` |
| Playing scene | ≥ 50 | `good` |

### Test Scenarios

#### Scenario 1: Happy path — get editor performance snapshot

**Description:** Call `get_editor_performance` with no arguments while the editor is idle.

**Params:**
```json
{}
```

**Expected Result:**
- Response `content[0].text` is JSON containing `"result"` object
- `result.fps` is a positive number
- `result.rating` is one of `"good"`, `"warning"`, `"critical"`
- `result.timing` has `process_ms` and `physics_ms` (both numeric)
- `result.memory` has `static_bytes`, `static_mb`, `video_bytes`, `video_mb`, `texture_bytes`, `texture_mb`
- `result.memory.static_mb` and `video_mb` are strings formatted as `"X.Y"` (e.g. `"45.2"`)
- `result.objects` has `total`, `nodes`, `resources`, `orphan_nodes` (all non-negative integers)
- `result.render` has `draw_calls`, `objects_in_frame`, `primitives_in_frame` (all non-negative integers)
- `result.physics` has `active_2d` and `active_3d` (both non-negative integers)

**Notes:** This is the primary smoke test for the editor performance tool. No params are needed.

**What to pay attention to:**
- `rating` should match the logic: FPS ≥ 15 in editor → `"good"`, FPS 5–15 → `"warning"`, FPS < 5 → `"critical"`
- `_mb` fields are **strings**, not numbers (formatted via GDScript `"%.1f"`)
- `_bytes` fields are numbers (float)
- `orphan_nodes` may be 0 — that's normal
- All values should be ≥ 0 (except fps, which is > 0 when the editor is alive)

---

#### Scenario 2: Extra params are ignored

**Description:** Pass arbitrary extra parameters — the tool should ignore them since `inputSchema` is empty.

**Params:**
```json
{
  "foo": "bar",
  "monitors": ["time/fps"]
}
```

**Expected Result:**
- Tool still succeeds and returns the full editor performance snapshot
- The extra params do not affect the result

**Notes:** The GDScript `get_editor_performance` receives `params: Dictionary` but does not read any keys from it. It delegates to `get_performance_monitors(params)` internally but then ignores the raw monitors result, extracting only known keys.

**What to pay attention to:** The result should be identical to scenario 1. Extra parameters should not cause an error.

---

#### Scenario 3: Verify rating reflects actual FPS

**Description:** Cross-check that the `rating` field matches the `fps` value according to the rating table.

**Params:**
```json
{}
```

**Expected Result:**
- If `result.fps` ≥ 15 (editor mode) → `result.rating` must be `"good"`
- If `result.fps` is between 5 and 15 → `result.rating` must be `"warning"`
- If `result.fps` < 5 → `result.rating` must be `"critical"`
- (During gameplay: ≥ 50 → `"good"`, 30–50 → `"warning"`, < 30 → `"critical"`)

**Notes:** In a typical idle editor, FPS should be well above 15, so expect `"good"`. This test validates the rating computation logic.

**What to pay attention to:** Verify the rating matches the FPS. If the editor is idle, FPS is usually high and the rating is `"good"`. If a heavy scene is running, the rating may differ.

---

## Dependency & Sequencing Notes

### No Prerequisites Between These Tools

`get_performance_monitors` and `get_editor_performance` are **independent read-only tools**. They do not require any other tools to be called first. Neither tool modifies state.

### Internal Dependency

`get_editor_performance` internally calls `get_performance_monitors` (via the GDScript backend) to fetch raw data, then transforms it into a structured summary. However, this is an implementation detail — from the MCP client perspective, both tools are called independently.

### Useful Companion Tools for Context

While not strictly required, the following tools can provide useful context when profiling:

| Tool | File | When to use |
|------|------|-------------|
| `get_scene_tree` | `scene.ts` | To understand what nodes exist before interpreting object/node counts |
| `get_node_properties` | `node.ts` | To inspect specific nodes that might cause performance issues |
| `execute_editor_script` | `editor.ts` | To run custom profiling GDScript if built-in monitors are insufficient |

### Typical Profiling Workflow

1. **Baseline:** Call `get_editor_performance` with no scene playing → record baseline FPS and memory
2. **Play scene:** Start the game scene (via `play_scene` from `scene.ts`)
3. **During gameplay:** Call `get_performance_monitors` with specific filters (e.g. `["time/fps", "physics_3d/active_objects"]`) to monitor hotspots
4. **Snapshot:** Call `get_editor_performance` during gameplay to get rating and structured summary
5. **Stop scene:** Stop the game (via `stop_scene`)
6. **Compare:** Call `get_editor_performance` again and compare with baseline

---

## Cross-Tool Error Scenarios

#### Scenario: Godot editor not connected

**Description:** Call either tool when no Godot editor is connected to the MCP server.

**Params (for either tool):**
```json
{}
```

**Expected Result:**
- Response has `isError: true`
- Error message contains `"Godot editor is not connected"` (from `GodotBridge.sendRequest`)

**Notes:** This error comes from the TypeScript bridge layer, not from GDScript.

**What to pay attention to:** The error should be clear and contain `"Godot editor is not connected"`. There should be no unhandled exceptions or empty responses.

---

#### Scenario: Request timeout

**Description:** If the Godot editor becomes unresponsive (e.g., stuck in a long operation), the request should time out gracefully.

**Params (for either tool):**
```json
{}
```

**Expected Result:**
- Response has `isError: true`
- Error message contains `"timed out"` and references the timeout duration (`REQUEST_TIMEOUT_MS` from config)

**Notes:** This is hard to trigger in a controlled test. May occur if the editor is busy compiling shaders or loading a large scene.

**What to pay attention to:** The error message should contain `"timed out"`. The timeout is set in `config.ts` as `REQUEST_TIMEOUT_MS`.
