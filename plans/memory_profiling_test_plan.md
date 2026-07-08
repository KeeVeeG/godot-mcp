# Test Plan: memory_profiling.ts

**File:** `server/src/tools/memory_profiling.ts`
**Module:** Memory Profiling — 5 tools for memory analysis and leak detection
**GDScript backend:** `addons/godot_mcp/commands/memory_profiling_commands.gd`

---

## Prerequisites

All tools require a **running Godot editor** with the MCP plugin active and connected via WebSocket.
Before running any test scenario, ensure:

1. Godot editor is open with a project loaded
2. MCP plugin is active (Project → Project Settings → Plugins → Godot MCP: Active)
3. MCP server is running and connected (check MCP tab in Godot bottom panel)
4. At least one scene is open in the editor (required for `find_memory_leaks` and `get_object_count` with class filter)

---

## Tool: `get_memory_usage`

### Registration

```typescript
server.registerTool(
  'get_memory_usage',
  {
    description: 'Get detailed memory usage breakdown by category (static, video, textures, buffers, objects)',
    inputSchema: {},
  },
  async () => callGodot(bridge, 'get_memory_usage'),
);
```

### Parameters

None. This tool takes no parameters.

### Return Structure

On success, returns:
```json
{
  "result": {
    "total_bytes": <float>,
    "total_mb": "<string>",
    "categories": {
      "static": {
        "bytes": <float>,
        "mb": "<string>",
        "max_bytes": <float>,
        "max_mb": "<string>",
        "usage_pct": "<string>"
      },
      "video": {
        "bytes": <float>,
        "mb": "<string>"
      },
      "textures": {
        "bytes": <float>,
        "mb": "<string>"
      },
      "buffers": {
        "bytes": <float>,
        "mb": "<string>"
      }
    },
    "objects": {
      "total": <int>,
      "resources": <int>,
      "nodes": <int>,
      "orphan_nodes": <int>
    },
    "orphan_warning": <bool>,
    "orphan_message": "<string>"
  }
}
```

### Test Scenarios

#### Scenario 1: Happy path — get memory usage with no params

**Description:** Call `get_memory_usage` with no arguments. Should return full memory breakdown.

**Params:**
```json
{}
```

**Expected Result:**
- Response `content[0].text` is JSON containing `"result"` object
- `result.total_bytes` is a non-negative number (float)
- `result.total_mb` is a string formatted as `"X.XX"` (e.g. `"45.23"`)
- `result.categories.static` has `bytes`, `mb`, `max_bytes`, `max_mb`, `usage_pct`
- `result.categories.static.usage_pct` is a string like `"12.3%"`
- `result.categories.video` has `bytes` and `mb`
- `result.categories.textures` has `bytes` and `mb`
- `result.categories.buffers` has `bytes` and `mb`
- `result.objects` has `total`, `resources`, `nodes`, `orphan_nodes` (all non-negative integers)
- `result.orphan_warning` is a boolean
- `result.orphan_message` is a non-empty string

**Notes:** This is the primary smoke test. All `_mb` fields are strings (GDScript formats with `"%.2f"`), all `bytes` fields are floats.

**What to check:**
- `_mb` fields are **strings**, not numbers
- `usage_pct` is a string ending with `%`
- `total_bytes` should be ≈ `static.bytes + video.bytes`
- `orphan_warning` = `true` only if `orphan_nodes > 0` and we are NOT in the editor (orphan nodes are normal in the editor)
- `orphan_message` depends on context: in the editor it says "normal in editor context", otherwise "potential memory leaks"

---

#### Scenario 2: Extra params are ignored

**Description:** Pass arbitrary extra parameters — the tool should ignore them since `inputSchema` is empty.

**Params:**
```json
{
  "foo": "bar",
  "detailed": true
}
```

**Expected Result:**
- Tool still succeeds and returns the full memory usage breakdown
- The extra params do not affect the result
- Response is identical in structure to Scenario 1

**Notes:** The GDScript `get_memory_usage` receives `_params: Dictionary` (underscore = unused). Extra params are silently ignored.

**What to check:** The result should be identical to scenario 1. Extra parameters should not cause an error.

---

## Tool: `track_object_creation`

### Registration

```typescript
server.registerTool(
  'track_object_creation',
  {
    description: 'Track object creation for a specific class over a duration. Records a baseline count; poll get_object_count afterward to see changes.',
    inputSchema: {
      class_name: NodeType.describe("Godot class name to track (e.g. 'Node2D', 'RigidBody3D')"),
      duration: z.number().min(1).max(60).optional().default(10).describe('Tracking duration in seconds (default: 10)'),
    },
  },
  async (args) => callGodot(bridge, 'track_object_creation', args as Record<string, unknown>),
);
```

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `class_name` | `string` (NodeType) | **Yes** | — | Godot class name to track (e.g. `'Node2D'`, `'RigidBody3D'`) |
| `duration` | `number` (1–60) | No | `10` | Tracking duration in seconds |

### Return Structure

On success:
```json
{
  "result": {
    "success": true,
    "class_name": "<string>",
    "baseline_count": <int>,
    "duration": <float>,
    "tracking_start": <float>,
    "message": "<string>"
  }
}
```

On error (missing/invalid class_name):
```json
{
  "error": "class_name is required"
}
```
or
```json
{
  "error": "Unknown class: <className>"
}
```

### Test Scenarios

#### Scenario 1: Happy path — track Node2D with default duration

**Description:** Call `track_object_creation` with only the required `class_name` parameter. Duration defaults to 10.

**Params:**
```json
{
  "class_name": "Node2D"
}
```

**Expected Result:**
- Response contains `"result"` with `success: true`
- `result.class_name` is `"Node2D"`
- `result.baseline_count` is a non-negative integer (count of Node2D instances in the current scene tree)
- `result.duration` is `10` (default)
- `result.tracking_start` is a positive float (Unix timestamp)
- `result.message` is a string containing `"Tracking Node2D objects for 10.0s"` and the baseline count

**Notes:** The tool records a baseline snapshot. To detect changes, you must later call `get_object_count` with the same class name.

**What to check:**
- `baseline_count` is computed recursively across the scene tree — in an empty scene it may be 0
- `tracking_start` is a Unix timestamp (a large number, > 1700000000)
- `message` contains an instruction to call `get_object_count` after the duration

---

#### Scenario 2: Track with explicit duration

**Description:** Specify a custom duration of 30 seconds.

**Params:**
```json
{
  "class_name": "RigidBody3D",
  "duration": 30
}
```

**Expected Result:**
- Response contains `"result"` with `success: true`
- `result.class_name` is `"RigidBody3D"`
- `result.duration` is `30`
- `result.message` contains `"30.0s"`

**Notes:** Validates that the custom duration is accepted and reflected in the response.

**What to check:** The `duration` in the response should exactly match the provided value. If the scene has no RigidBody3D, `baseline_count` will be 0 — this is normal.

---

#### Scenario 3: Track with minimum duration (boundary)

**Description:** Use the minimum allowed duration of 1 second.

**Params:**
```json
{
  "class_name": "Sprite2D",
  "duration": 1
}
```

**Expected Result:**
- Response contains `"result"` with `success: true`
- `result.duration` is `1`

**Notes:** Boundary test for the `min(1)` constraint.

**What to check:** Verify that `duration` = 1 is accepted without errors.

---

#### Scenario 4: Track with maximum duration (boundary)

**Description:** Use the maximum allowed duration of 60 seconds.

**Params:**
```json
{
  "class_name": "Node",
  "duration": 60
}
```

**Expected Result:**
- Response contains `"result"` with `success: true`
- `result.duration` is `60`

**Notes:** Boundary test for the `max(60)` constraint.

**What to check:** Verify that `duration` = 60 is accepted without errors.

---

#### Scenario 5: Missing required class_name (invalid input)

**Description:** Call without the required `class_name` parameter.

**Params:**
```json
{}
```

**Expected Result:**
- Response has `isError: true` OR the `result` contains an `error` field
- The GDScript backend returns `{"error": "class_name is required"}` when `class_name` is empty
- However, since `class_name` uses `NodeType` (which is `z.string()` without `.min(1)`), the Zod schema may allow an empty string to pass through to GDScript, which then returns the error

**Notes:** Tests the boundary between Zod validation and GDScript validation. `NodeType` is `z.string().describe(...)` — it does NOT have `.min(1)`, so an empty string passes Zod but fails in GDScript.

**What to check:** Verify the error is returned correctly. If Zod passes an empty string, the error comes from GDScript: `"class_name is required"`.

---

#### Scenario 6: Unknown class name (invalid input)

**Description:** Pass a class name that does not exist in Godot's ClassDB.

**Params:**
```json
{
  "class_name": "NonExistentClassName12345"
}
```

**Expected Result:**
- GDScript returns `{"error": "Unknown class: NonExistentClassName12345"}`
- Response indicates an error

**Notes:** The GDScript backend checks `ClassDB.class_exists()` and returns an error for unknown classes.

**What to check:** The error should contain the queried class name. There should be no crash or unhandled exception.

---

#### Scenario 7: Duration below minimum (invalid input)

**Description:** Pass a duration value below the minimum of 1.

**Params:**
```json
{
  "class_name": "Node2D",
  "duration": 0
}
```

**Expected Result:**
- Zod validation rejects the input because `z.number().min(1)` fails
- MCP returns a validation error before the request reaches Godot

**Notes:** Tests Zod schema boundary enforcement.

**What to check:** The error should occur at the Zod validation level in TypeScript, not on the Godot side.

---

#### Scenario 8: Duration above maximum (invalid input)

**Description:** Pass a duration value above the maximum of 60.

**Params:**
```json
{
  "class_name": "Node2D",
  "duration": 120
}
```

**Expected Result:**
- Zod validation rejects the input because `z.number().max(60)` fails
- MCP returns a validation error before the request reaches Godot

**Notes:** Tests Zod schema boundary enforcement.

**What to check:** The error should occur at the Zod validation level in TypeScript.

---

## Tool: `find_memory_leaks`

### Registration

```typescript
server.registerTool(
  'find_memory_leaks',
  {
    description: 'Analyze the scene tree and object graph to find potential memory leaks (orphan nodes, leaked resources)',
    inputSchema: {},
  },
  async () => callGodot(bridge, 'find_memory_leaks'),
);
```

### Parameters

None. This tool takes no parameters.

### Return Structure

On success:
```json
{
  "result": {
    "issue_count": <int>,
    "issues": [
      {
        "severity": "warning" | "critical" | "info",
        "type": "<string>",
        "count": <int>,
        "message": "<string>",
        "suggestion": "<string>"
      }
    ],
    "orphan_nodes": <int>,
    "resource_count": <int>,
    "static_memory_mb": "<string>",
    "video_memory_mb": "<string>",
    "clean": <bool>,
    "message": "<string>"
  }
}
```

### Issue Types Detected

| Type | Severity | Trigger Condition |
|------|----------|-------------------|
| `orphan_nodes` | `warning` | `orphan_count > 0` |
| `high_resource_count` | `warning` | `resource_count > 5000` |
| `static_memory_near_limit` | `critical` | `static_memory > static_max * 0.9` |
| `deep_nesting` | `info` | Node depth > 50 in scene tree |
| `high_child_count` | `warning` | Node has > 200 children |
| `high_video_memory` | `warning` | `video_memory > 512 MB` |

### Test Scenarios

#### Scenario 1: Happy path — analyze a clean project

**Description:** Call `find_memory_leaks` on a project with a simple scene (few nodes, no orphans).

**Params:**
```json
{}
```

**Expected Result:**
- Response contains `"result"` object
- `result.issue_count` is a non-negative integer
- `result.issues` is an array (may be empty for a clean project)
- `result.orphan_nodes` is a non-negative integer
- `result.resource_count` is a non-negative integer
- `result.static_memory_mb` is a string like `"45.23"`
- `result.video_memory_mb` is a string like `"12.50"`
- `result.clean` is `true` if `issues` is empty, `false` otherwise
- `result.message` is `"No memory issues detected"` if clean, otherwise `"Found N potential issues"`

**Notes:** In a clean editor project, `clean` should be `true` and `issue_count` should be `0`. Orphan nodes in editor context are normal and should NOT be flagged (the GDScript only flags them unconditionally, but the `orphan_message` in `get_memory_usage` differentiates editor vs runtime).

**What to check:**
- `_mb` fields are strings
- `clean` and `issue_count` should be consistent
- Each element in `issues` should contain `severity`, `type`, `message`, `suggestion`
- In a clean project `issues` may be an empty array

---

#### Scenario 2: Extra params are ignored

**Description:** Pass arbitrary extra parameters.

**Params:**
```json
{
  "deep_scan": true,
  "threshold": 100
}
```

**Expected Result:**
- Tool still succeeds and returns the full leak analysis
- Extra params are silently ignored
- Response structure is identical to Scenario 1

**Notes:** The GDScript `find_memory_leaks` receives `_params: Dictionary` (unused).

**What to check:** The result should be identical to scenario 1.

---

#### Scenario 3: Verify issue structure when issues exist

**Description:** If the project has orphan nodes or a deep scene tree, verify the structure of returned issues.

**Params:**
```json
{}
```

**Expected Result (when issues exist):**
- Each issue in `result.issues` has:
  - `severity`: one of `"info"`, `"warning"`, `"critical"`
  - `type`: one of `"orphan_nodes"`, `"high_resource_count"`, `"static_memory_near_limit"`, `"deep_nesting"`, `"high_child_count"`, `"high_video_memory"`
  - `message`: non-empty string describing the issue
  - `suggestion`: non-empty string with remediation advice
- Type-specific fields:
  - `orphan_nodes`: has `count` (int)
  - `high_resource_count`: has `count` (int)
  - `static_memory_near_limit`: has `current_mb` and `max_mb` (strings)
  - `deep_nesting`: has `path` (string) and `depth` (int)
  - `high_child_count`: has `path` (string) and `child_count` (int)
  - `high_video_memory`: has `video_mb` (string)

**Notes:** This scenario is conditional — it only produces meaningful assertions if the project actually has issues. For a clean project, `issues` will be empty.

**What to check:** Verify that each issue type has the expected fields. `severity` should be a valid enum value.

---

## Tool: `get_object_count`

### Registration

```typescript
server.registerTool(
  'get_object_count',
  {
    description: 'Get count of live objects, optionally filtered by class name',
    inputSchema: {
      class_name: NodeType.optional().describe('Filter by class name, or omit for total count'),
    },
  },
  async (args) => callGodot(bridge, 'get_object_count', args as Record<string, unknown>),
);
```

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `class_name` | `string` (NodeType) | No | Filter by class name. Omit for total count. |

### Return Structure

Without class filter:
```json
{
  "result": {
    "total_objects": <int>,
    "nodes": <int>,
    "resources": <int>
  }
}
```

With class filter:
```json
{
  "result": {
    "class_name": "<string>",
    "count": <int>,
    "total_objects": <int>,
    "nodes": <int>,
    "resources": <int>
  }
}
```

On error (unknown class):
```json
{
  "error": "Unknown class: <className>"
}
```

### Test Scenarios

#### Scenario 1: Happy path — get total object count (no filter)

**Description:** Call `get_object_count` without `class_name` to get aggregate counts.

**Params:**
```json
{}
```

**Expected Result:**
- Response contains `"result"` with `total_objects`, `nodes`, `resources`
- All three values are non-negative integers
- `total_objects` >= `nodes` + `resources` (total includes other object types)

**Notes:** This is the baseline — no class filtering. All values come from `Performance.get_monitor()`.

**What to check:**
- `total_objects` is the total number of live objects (including nodes, resources, and others)
- `nodes` is only nodes
- `resources` is only resources
- All values are ≥ 0

---

#### Scenario 2: Filter by a common class — Node2D

**Description:** Get count of `Node2D` instances in the scene tree.

**Params:**
```json
{
  "class_name": "Node2D"
}
```

**Expected Result:**
- Response contains `"result"` with `class_name`, `count`, `total_objects`, `nodes`, `resources`
- `result.class_name` is `"Node2D"`
- `result.count` is a non-negative integer (0 if no Node2D in scene)
- `result.total_objects`, `nodes`, `resources` are non-negative integers

**Notes:** The `count` field is computed by recursively walking the scene tree and checking `node.is_class()`. If the scene has no Node2D nodes, count will be 0.

**What to check:** `count` is computed recursively across the scene tree. If the scene contains no Node2D, the result will be 0 — this is not an error.

---

#### Scenario 3: Filter by a deeply inherited class

**Description:** Filter by `Node` — should match ALL nodes in the tree (since every node inherits from Node).

**Params:**
```json
{
  "class_name": "Node"
}
```

**Expected Result:**
- `result.count` should equal `result.nodes` (since every node is a `Node`)
- `result.count` > 0 if the scene has any nodes

**Notes:** Validates that `is_class()` works correctly for base classes. Every node in Godot inherits from `Node`, so `count` should match the total node count.

**What to check:** The `count` for `Node` should match `nodes` from the aggregate data. This validates the correctness of the recursive traversal.

---

#### Scenario 4: Filter by unknown class name (invalid input)

**Description:** Pass a class name that does not exist in Godot's ClassDB.

**Params:**
```json
{
  "class_name": "FakeClassName99999"
}
```

**Expected Result:**
- GDScript returns `{"error": "Unknown class: FakeClassName99999"}`
- Response indicates an error

**Notes:** The GDScript backend checks `ClassDB.class_exists()` before counting.

**What to check:** The error should contain the queried class name. There should be no crash.

---

#### Scenario 5: Filter by class with zero instances

**Description:** Filter by a valid class that has no instances in the current scene (e.g. `VehicleBody3D` in a 2D project).

**Params:**
```json
{
  "class_name": "VehicleBody3D"
}
```

**Expected Result:**
- Response contains `"result"` (not an error)
- `result.class_name` is `"VehicleBody3D"`
- `result.count` is `0`
- `result.total_objects`, `nodes`, `resources` are still populated with aggregate counts

**Notes:** A valid class with zero instances is NOT an error. The tool should return count=0 gracefully.

**What to check:** A zero count for a valid class is NOT an error. The response should contain `result`, not `error`.

---

#### Scenario 6: Call after `track_object_creation` (workflow test)

**Description:** After calling `track_object_creation` for `Sprite2D`, call `get_object_count` with the same class to see the current count.

**Setup:** First call `track_object_creation` with `{"class_name": "Sprite2D"}`.

**Params:**
```json
{
  "class_name": "Sprite2D"
}
```

**Expected Result:**
- `result.count` should be >= `baseline_count` from the `track_object_creation` response (assuming no nodes were deleted)
- `result.class_name` is `"Sprite2D"`

**Notes:** This is the recommended workflow per the tool description: track → wait → count.

**What to check:** Count should be >= baseline_count (if nodes were not deleted). This validates the `track_object_creation` → `get_object_count` pipeline.

---

## Tool: `force_garbage_collection`

### Registration

```typescript
server.registerTool(
  'force_garbage_collection',
  {
    description: 'Force garbage collection and report the amount of memory freed',
    inputSchema: {},
  },
  async () => callGodot(bridge, 'force_garbage_collection'),
);
```

### Parameters

None. This tool takes no parameters.

### Return Structure

On success:
```json
{
  "result": {
    "memory_before_mb": "<string>",
    "memory_after_mb": "<string>",
    "freed_mb": "<string>",
    "freed_bytes": <float>,
    "objects_before": <int>,
    "objects_after": <int>,
    "objects_freed": <int>,
    "orphans_before": <int>,
    "orphans_after": <int>
  }
}
```

### Known Limitation

Godot 4.x does not expose a manual GC trigger API from GDScript. This tool forces a brief pause (3 × 16ms ticks) to allow deferred `queue_free()` calls to complete. Reported changes reflect natural memory fluctuations, not forced collection.

### Test Scenarios

#### Scenario 1: Happy path — force GC and check result structure

**Description:** Call `force_garbage_collection` with no arguments.

**Params:**
```json
{}
```

**Expected Result:**
- Response contains `"result"` object
- `result.memory_before_mb` is a string like `"45.23"`
- `result.memory_after_mb` is a string like `"45.23"`
- `result.freed_mb` is a string like `"0.00"` (likely 0 in editor context)
- `result.freed_bytes` is a non-negative float
- `result.objects_before` is a non-negative integer
- `result.objects_after` is a non-negative integer
- `result.objects_freed` is a non-negative integer
- `result.orphans_before` is a non-negative integer
- `result.orphans_after` is a non-negative integer

**Notes:** In a typical editor session with no pending `queue_free()` calls, `freed_mb` will be `"0.00"` and `objects_freed` will be `0`. This is expected behavior, not an error.

**What to check:**
- `_mb` fields are strings
- `freed_bytes` and `objects_freed` use `max(..., 0)` — always ≥ 0
- `memory_before_mb` ≈ `memory_after_mb` in most cases (no real GC in Godot)
- `objects_before` may be > or < `objects_after` due to natural fluctuations

---

#### Scenario 2: Extra params are ignored

**Description:** Pass arbitrary extra parameters.

**Params:**
```json
{
  "force": true,
  "aggressive": true
}
```

**Expected Result:**
- Tool still succeeds
- Extra params are silently ignored
- Response structure is identical to Scenario 1

**Notes:** The GDScript `force_garbage_collection` receives `_params: Dictionary` (unused).

**What to check:** The result should be identical to scenario 1.

---

#### Scenario 3: Call GC twice in succession (idempotency)

**Description:** Call `force_garbage_collection` twice in a row. The second call should show similar or identical results.

**Params (both calls):**
```json
{}
```

**Expected Result:**
- First call returns a valid result (Scenario 1)
- Second call also returns a valid result
- `freed_mb` on the second call is approximately `"0.00"` (nothing new to free)
- `memory_after_mb` on the second call ≈ `memory_before_mb` on the first call (memory is stable)

**Notes:** Validates that repeated GC calls don't cause memory regressions or errors.

**What to check:** A repeated call should not free additional memory (unless new `queue_free()` calls were made). Verify `memory_after_mb` is stable between calls.

---

## Dependency & Sequencing Notes

### Tools Requiring Other Tools First

| Tool | Prerequisite | Reason |
|------|-------------|--------|
| `get_object_count` (with class filter, Scenario 6) | `track_object_creation` | To verify that the count matches or exceeds the recorded baseline |
| `find_memory_leaks` | Scene with nodes open | The tool walks the scene tree; an empty/null scene root limits analysis |

### No Prerequisites (Independent Tools)

- `get_memory_usage` — standalone, reads Performance monitors
- `track_object_creation` — standalone, records baseline
- `force_garbage_collection` — standalone, reads before/after snapshots
- `get_object_count` (without class filter) — standalone, reads Performance monitors

### Recommended Workflow: Memory Leak Investigation

1. **Baseline:** Call `get_memory_usage` → record `total_bytes`, `objects.total`
2. **Track:** Call `track_object_creation` with `{"class_name": "Sprite2D", "duration": 30}` → record `baseline_count`
3. **Wait:** Wait for 30 seconds (or perform actions that might create/leak objects)
4. **Count:** Call `get_object_count` with `{"class_name": "Sprite2D"}` → compare `count` with `baseline_count`
5. **Analyze:** Call `find_memory_leaks` → review `issues` array
6. **Cleanup:** Call `force_garbage_collection` → check `freed_mb` and `objects_freed`
7. **Re-check:** Call `get_memory_usage` again → compare with step 1 baseline

### Typical Pairing with Profiling Tools

| Memory Tool | Profiling Tool | When to use |
|-------------|---------------|-------------|
| `get_memory_usage` | `get_performance_monitors` (from `profiling.ts`) | `get_performance_monitors` provides raw `memory/static` and `memory/static_max`; `get_memory_usage` provides a structured breakdown with categories and percentages |
| `get_object_count` | `get_performance_monitors` with `["object/object_count", "object/node_count"]` | Both return object counts but via different paths — `get_performance_monitors` uses raw Performance monitors, `get_object_count` adds optional class filtering |
| `find_memory_leaks` | `get_editor_performance` (from `profiling.ts`) | `get_editor_performance` gives a quick snapshot with rating; `find_memory_leaks` does deep analysis of the scene tree |

---

## Cross-Tool Error Scenarios

#### Scenario: Godot editor not connected

**Description:** Call any of the 5 tools when no Godot editor is connected to the MCP server.

**Params (for any tool):**
```json
{}
```

**Expected Result:**
- Response has `isError: true`
- Error message contains `"Godot editor is not connected"` (from `GodotBridge.sendRequest`)

**Notes:** This error comes from the TypeScript bridge layer, not from GDScript.

**What to check:** The error should be clear and contain `"Godot editor is not connected"`. There should be no unhandled exceptions or empty responses.

---

#### Scenario: Request timeout

**Description:** If the Godot editor becomes unresponsive, the request should time out gracefully.

**Params (for any tool):**
```json
{}
```

**Expected Result:**
- Response has `isError: true`
- Error message contains `"timed out"` and references the timeout duration

**Notes:** Hard to trigger in a controlled test. May occur if the editor is busy compiling or loading a large scene.

**What to check:** The error message should contain `"timed out"`.
