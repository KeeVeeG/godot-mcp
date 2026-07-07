# Memory Profiling Tools — Test Plan

**Source file:** `server/src/tools/memory_profiling.ts`  
**Number of tools:** 5  
**Godot bridge commands:** `get_memory_usage`, `track_object_creation`, `find_memory_leaks`, `get_object_count`, `force_garbage_collection`  
**Godot implementation:** `addon/godot_mcp/commands/memory_profiling_commands.gd`

---

## Known Class Names

The `class_name` parameter in `track_object_creation` and `get_object_count` accepts any string that passes Zod validation. The Godot implementation validates class existence via `ClassDB.class_exists()`. Any built-in Godot class name is valid (e.g. `Node2D`, `CharacterBody3D`, `RigidBody3D`, `Sprite2D`, `Node`). Unknown class names return error objects.

---

## Tool 1: `get_memory_usage`

**Description:** Get detailed memory usage breakdown by category (static, video, textures, buffers, objects)  
**Handler:** `callGodot(bridge, 'get_memory_usage')` (no args forwarded)  
**Parameters:** None (empty `inputSchema`)

**Expected result shape:**
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
    "orphan_warning": <boolean>,
    "orphan_message": "<string>"
  }
}
```

**Fields detail:**

| Field | Type | Description |
|-------|------|-------------|
| `result.total_bytes` | number | Sum of static + video memory |
| `result.total_mb` | string | Total memory formatted as "X.XX" MB |
| `result.categories.static.bytes` | number | Static memory bytes |
| `result.categories.static.mb` | string | Static memory formatted as "X.XX" MB |
| `result.categories.static.max_bytes` | number | Max static memory recorded |
| `result.categories.static.max_mb` | string | Max static memory formatted as "X.XX" MB |
| `result.categories.static.usage_pct` | string | Usage percentage formatted as "X.X%" |
| `result.categories.video.bytes` | number | Video memory bytes |
| `result.categories.video.mb` | string | Video memory formatted as "X.XX" MB |
| `result.categories.textures.bytes` | number | Texture memory bytes |
| `result.categories.textures.mb` | string | Texture memory formatted as "X.XX" MB |
| `result.categories.buffers.bytes` | number | Buffer memory bytes |
| `result.categories.buffers.mb` | string | Buffer memory formatted as "X.XX" MB |
| `result.objects.total` | int | Total live object count |
| `result.objects.resources` | int | Total resource count |
| `result.objects.nodes` | int | Total node count |
| `result.objects.orphan_nodes` | int | Orphan node count |
| `result.orphan_warning` | boolean | `true` if orphans > 0 AND engine is NOT in editor mode (editor orphans are normal) |
| `result.orphan_message` | string | Human-readable orphan status message |

**`orphan_message` variants:**
- No orphans: `"No orphan nodes detected"`
- Orphans in editor mode: `"Found N orphan nodes (normal in editor context)"`
- Orphans at runtime: `"Found N orphan nodes - potential memory leaks"`

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 1 | Call with no arguments | `{}` | Valid JSON with `result` containing `total_bytes`, `total_mb`, `categories` (static/video/textures/buffers), `objects` (total/resources/nodes/orphan_nodes), `orphan_warning`, `orphan_message` | Simplest invocation. All sections present. |
| 2 | Call with extra ignored arg | `{"extra": true}` | Valid JSON (extra arg ignored) | Zod ignores unknown keys since schema is `{}`. |
| 3 | Call multiple times | `{}` × 3 | Each call returns current snapshot | Values may differ between calls. Structure must be consistent. |
| 4 | Verify `total_bytes` equals `static.bytes + video.bytes` | `{}` | Assert `total_bytes` == `categories.static.bytes` + `categories.video.bytes` | Arithmetic consistency check. |
| 5 | Verify `total_mb` format | `{}` | `total_mb` is a string matching pattern `\d+\.\d{2}` | Two decimal places (%.2f format). |
| 6 | Verify all `mb` fields use 2-decimal format | `{}` | All `*_mb` fields match `\d+\.\d{2}` | Static, video, textures, buffers all use `%.2f`. |
| 7 | Verify `usage_pct` format | `{}` | `categories.static.usage_pct` matches `\d+\.\d%` | One decimal + percent sign (%.1f%%). |
| 8 | Verify `objects` sub-object has all 4 keys | `{}` | `objects` has `total`, `resources`, `nodes`, `orphan_nodes`, all integers | Object structure completeness. |
| 9 | Verify `categories` sub-object has all 4 keys | `{}` | `categories` has `static`, `video`, `textures`, `buffers` | Category structure completeness. |
| 10 | Verify `orphan_warning` is boolean | `{}` | `orphan_warning` is `true` or `false` | Type check. |
| 11 | Verify `orphan_message` is string | `{}` | `orphan_message` is a non-empty string | Type check. |

### Edge Cases — Bridge / Connectivity

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 12 | Editor disconnected | `{}` | Error: connection timeout or "Godot editor is not connected" | Standard disconnected behavior. |
| 13 | Call with `null` body | `null` | As-if `{}` (MCP SDK may coerce null) | Null body handling. |
| 14 | Rapid repeated calls (10×) | `{}` × 10 | All succeed; no race conditions | Stress test for concurrent access. |
| 15 | Call immediately after project load | `{}` | Valid JSON with low memory values | Fresh project state. |

### Edge Cases — Memory Value Boundaries

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 16 | `static.max_bytes` is 0 | `{}` (rare: Godot may report 0 if no max recorded) | `usage_pct` is `"0.0%"` or similar (division by max(0, 1.0) guard) | Godot guards against division by zero. |
| 17 | All memory values are zero | `{}` (empty scene) | Valid JSON with zeros and formatted `"0.00"` strings | Empty project. |
| 18 | `static.bytes` > `static.max_bytes` | `{}` (current usage exceeds historical max) | `usage_pct` > `"100.0%"` | Godot can report usage > max. |

---

## Tool 2: `track_object_creation`

**Description:** Track object creation for a specific class over a duration. Records a baseline count; poll `get_object_count` afterward to see changes.  
**Handler:** `callGodot(bridge, 'track_object_creation', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `class_name` | `string` | **Yes** | — | Godot class name to track (e.g. `'Node2D'`, `'RigidBody3D'`) |
| `duration` | `number` | No | `10` | Tracking duration in seconds. Min: `1`, Max: `60`. |

**Expected result shape:**
```json
{
  "result": {
    "success": true,
    "class_name": "<string>",
    "baseline_count": <int>,
    "duration": <number>,
    "tracking_start": <float>,
    "message": "<string>"
  }
}
```

**Or on error:**
```json
{
  "error": "class_name is required"
}
```
```json
{
  "error": "Unknown class: <class_name>"
}
```

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 19 | Track `Node2D` with default duration | `{"class_name": "Node2D"}` | `{"result": {"success": true, "class_name": "Node2D", "baseline_count": <int>, "duration": 10, ...}}` | Simplest valid invocation. Uses default duration=10. |
| 20 | Track `Node2D` with explicit duration | `{"class_name": "Node2D", "duration": 5}` | `{"result": {"success": true, "class_name": "Node2D", "baseline_count": <int>, "duration": 5, ...}}` | Custom duration. |
| 21 | Track `CharacterBody3D` | `{"class_name": "CharacterBody3D"}` | `{"result": {"success": true, "class_name": "CharacterBody3D", ...}}` | Different class. |
| 22 | Track `RigidBody3D` | `{"class_name": "RigidBody3D"}` | `{"result": {"success": true, "class_name": "RigidBody3D", ...}}` | Different class. |
| 23 | Track `Sprite2D` | `{"class_name": "Sprite2D"}` | `{"result": {"success": true, "class_name": "Sprite2D", ...}}` | 2D node class. |
| 24 | Track `Node` (base class) | `{"class_name": "Node"}` | `{"result": {"success": true, "class_name": "Node", ...}}` | Base class tracking — counts ALL nodes. |
| 25 | Track `Resource` | `{"class_name": "Resource"}` | `{"result": {"success": true, "class_name": "Resource", ...}}` | Resource class tracking. |
| 26 | Verify `baseline_count` is a valid integer | `{"class_name": "Node2D"}` | `baseline_count` ≥ 0, integer | Baseline should be non-negative. |
| 27 | Verify `tracking_start` is a valid Unix timestamp | `{"class_name": "Node2D"}` | `tracking_start` is a float near current time | Timestamp verification. |
| 28 | Verify `message` contains class_name, duration, and baseline_count | `{"class_name": "Node2D", "duration": 5}` | message includes "Node2D", "5", and baseline count value | Informative message. |
| 29 | Track with minimum duration (1s) | `{"class_name": "Node2D", "duration": 1}` | Success. `duration` = 1. | Boundary: minimum allowed duration. |
| 30 | Track with maximum duration (60s) | `{"class_name": "Node2D", "duration": 60}` | Success. `duration` = 60. | Boundary: maximum allowed duration. |
| 31 | Baseline count = 0 for absent class | `{"class_name": "Camera3D"}` (when no Camera3D in scene) | `{"result": {"success": true, "baseline_count": 0, ...}}` | Class exists in ClassDB but has 0 instances. |
| 32 | Cross-check: baseline matches `get_object_count` | 1. `track_object_creation({"class_name": "Node2D"})`<br>2. `get_object_count({"class_name": "Node2D"})` | `track_object_creation.baseline_count` == `get_object_count.count` | Consistency between tools. |

### Error Path — Invalid `class_name`

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 33 | Empty class name | `{"class_name": ""}` | `{"error": "class_name is required"}` | Godot validates empty string. |
| 34 | Unknown class name | `{"class_name": "NonExistentClass"}` | `{"error": "Unknown class: NonExistentClass"}` | Class not in ClassDB. |
| 35 | Class name with typo | `{"class_name": "Node2DD"}` | `{"error": "Unknown class: Node2DD"}` | Typo in class name. |
| 36 | Lowercase class name | `{"class_name": "node2d"}` | `{"error": "Unknown class: node2d"}` | Godot class names are case-sensitive. |
| 37 | Whitespace-only class name | `{"class_name": "   "}` | `{"error": "Unknown class:    "}` | Godot trims? Check behavior. Whitespace passes Zod. |
| 38 | Very long class name (1000 chars) | `{"class_name": "A".repeat(1000)}` | `{"error": "Unknown class: AAAA..."}` | Long string passes Zod; unknown to Godot. |
| 39 | Unicode class name | `{"class_name": "Узел"}` | `{"error": "Unknown class: Узел"}` | Unicode passes Zod; unknown to Godot. |
| 40 | Class name with special characters | `{"class_name": "Node; DROP TABLE"}` | `{"error": "Unknown class: Node; DROP TABLE"}` | SQL injection-like string; passes Zod, unknown to Godot. |

### Error Path — Invalid `duration`

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 41 | `duration` = 0 (below min) | `{"class_name": "Node2D", "duration": 0}` | Zod validation error | `z.number().min(1)` rejects 0. |
| 42 | `duration` = -1 (negative) | `{"class_name": "Node2D", "duration": -1}` | Zod validation error | `z.number().min(1)` rejects negative. |
| 43 | `duration` = 61 (above max) | `{"class_name": "Node2D", "duration": 61}` | Zod validation error | `z.number().max(60)` rejects 61. |
| 44 | `duration` = 999 (far above max) | `{"class_name": "Node2D", "duration": 999}` | Zod validation error | `z.number().max(60)` rejects large values. |
| 45 | `duration` = 0.5 (fractional below min) | `{"class_name": "Node2D", "duration": 0.5}` | Zod validation error | `min(1)` rejects fractions < 1. |
| 46 | `duration` = 1.5 (fractional, valid) | `{"class_name": "Node2D", "duration": 1.5}` | `{"result": {"success": true, "duration": 1.5, ...}}` | Fractional duration between 1-60 should pass Zod. |
| 47 | `duration` = 59.9 (fractional near max) | `{"class_name": "Node2D", "duration": 59.9}` | `{"result": {"success": true, "duration": 59.9, ...}}` | Fractional near upper boundary. |
| 48 | `duration` as string `"10"` | `{"class_name": "Node2D", "duration": "10"}` | Zod validation error | `z.number()` rejects string. |
| 49 | `duration` as boolean `true` | `{"class_name": "Node2D", "duration": true}` | Zod validation error | `z.number()` rejects boolean. |
| 50 | `duration` as object `{}` | `{"class_name": "Node2D", "duration": {}}` | Zod validation error | `z.number()` rejects object. |
| 51 | `duration` as null | `{"class_name": "Node2D", "duration": null}` | Zod validation error | `z.number().optional()` rejects null. |
| 52 | `duration` as array `[10]` | `{"class_name": "Node2D", "duration": [10]}` | Zod validation error | `z.number()` rejects array. |

### Error Path — Missing `class_name`

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 53 | `class_name` omitted entirely | `{}` | Zod validation error | Schema has `class_name: NodeType` (required, no optional). |
| 54 | `class_name` as null | `{"class_name": null}` | Zod validation error | `z.string()` rejects null. |
| 55 | `class_name` as number | `{"class_name": 42}` | Zod validation error | `z.string()` rejects number. |
| 56 | `class_name` as boolean | `{"class_name": false}` | Zod validation error | `z.string()` rejects boolean. |
| 57 | `class_name` as object | `{"class_name": {"name": "Node2D"}}` | Zod validation error | `z.string()` rejects object. |
| 58 | `class_name` as array | `{"class_name": ["Node2D"]}` | Zod validation error | `z.string()` rejects array. |

### Edge Cases — Bridge / Connectivity

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 59 | Editor disconnected | `{"class_name": "Node2D"}` | Error: connection timeout | Standard disconnected behavior. |
| 60 | Call twice in rapid succession | `{"class_name": "Node2D"}` × 2 | Both succeed; second overrides tracking state | Server allows re-tracking (overwrites `_tracked_class`). |
| 61 | Call with extra ignored params | `{"class_name": "Node2D", "extra": true, "extra2": "value"}` | Success (extra args ignored) | Zod drops unknown keys. |

---

## Tool 3: `find_memory_leaks`

**Description:** Analyze the scene tree and object graph to find potential memory leaks (orphan nodes, leaked resources)  
**Handler:** `callGodot(bridge, 'find_memory_leaks')` (no args forwarded)  
**Parameters:** None (empty `inputSchema`)

**Expected result shape:**
```json
{
  "result": {
    "issue_count": <int>,
    "issues": [
      {
        "severity": "warning" | "critical" | "info",
        "type": "<string>",
        "..."
      }
    ],
    "orphan_nodes": <int>,
    "resource_count": <int>,
    "static_memory_mb": "<string>",
    "video_memory_mb": "<string>",
    "clean": <boolean>,
    "message": "<string>"
  }
}
```

**Known issue types and their severity:**

| Issue Type | Severity | Trigger Condition | Fields |
|------------|----------|-------------------|--------|
| `orphan_nodes` | `warning` | `orphan_count > 0` | `count`, `message`, `suggestion` |
| `high_resource_count` | `warning` | `resource_count > 5000` | `count`, `message`, `suggestion` |
| `static_memory_near_limit` | `critical` | `static_mem > max_static_mem * 0.9` | `current_mb`, `max_mb`, `message`, `suggestion` |
| `high_video_memory` | `warning` | `video_mem > 512 MB` | `video_mb`, `message`, `suggestion` |
| `deep_nesting` | `info` | Node depth > 50 | `path`, `depth`, `message`, `suggestion` |
| `high_child_count` | `warning` | Child count > 200 | `path`, `child_count`, `message`, `suggestion` |

**`message` and `clean` variants:**
- Issues found: `"Found N potential issues"` and `clean: false`
- No issues: `"No memory issues detected"` and `clean: true`

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 62 | Call with no arguments | `{}` | Valid JSON with `result` containing `issue_count`, `issues` (array), `orphan_nodes`, `resource_count`, `static_memory_mb`, `video_memory_mb`, `clean`, `message` | Simplest invocation. |
| 63 | Clean project (no issues) | `{}` (fresh empty scene) | `{"result": {"issue_count": 0, "issues": [], "clean": true, "message": "No memory issues detected"}}` | No problems found. |
| 64 | Project with orphan nodes | `{}` (scene with orphan nodes) | `issues` contains entry with `type: "orphan_nodes"`, `severity: "warning"` | Orphan nodes trigger warning. |
| 65 | Project with high resource count | `{}` (> 5000 resources) | `issues` contains entry with `type: "high_resource_count"`, `severity: "warning"` | Resource threshold check. |
| 66 | Project near static memory limit | `{}` (static > 90% max) | `issues` contains entry with `type: "static_memory_near_limit"`, `severity: "critical"` | Critical memory condition. |
| 67 | Call with extra ignored arg | `{"ignored": true}` | Valid JSON (extra arg ignored) | Zod ignores unknown keys. |
| 68 | Call multiple times | `{}` × 3 | Consistent results (same snapshot) | Concurrent calls within same frame. |
| 69 | Verify all issue objects have required fields | `{}` | Each issue in `issues` has `severity`, `type`, `message`, `suggestion` | Structural completeness check. |
| 70 | Verify severity is one of: `"warning"`, `"critical"`, `"info"` | `{}` | All `severity` values in valid set | Enum validation. |
| 71 | Verify `clean` is true when `issue_count` = 0 | `{}` | `clean` == (`issue_count` == 0) | Logic consistency. |
| 72 | Verify `clean` is false when `issue_count` > 0 | `{}` (scene with issues) | `clean` == false | Inverse logic. |
| 73 | Verify `message` matches `issue_count` | `{}` | If issues > 0, message = "Found N potential issues"; else "No memory issues detected" | Message correctness. |
| 74 | Verify `static_memory_mb` format | `{}` | String like `"X.XX"` (%.2f format) | Format check. |
| 75 | Verify `video_memory_mb` format | `{}` | String like `"X.XX"` (%.2f format) | Format check. |
| 76 | Verify `orphan_nodes` matches `issue` count for orphan type | `{}` (scene with orphans) | `orphan_nodes` value == count in `orphan_nodes` issue | Data consistency. |

### Issue Type Scenarios — Individual Triggers

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 77 | Orphan nodes present | `{}` (create nodes without adding to tree) | Issue of type `orphan_nodes` with `severity: "warning"` and `count` field | Orphan detection. |
| 78 | High resource count trigger | `{}` (load 5001+ resources) | Issue of type `high_resource_count` with `severity: "warning"` | Resource count threshold (5000). |
| 79 | Resource count exactly at threshold (5000) | `{}` (5000 resources) | No `high_resource_count` issue (condition is `> 5000`, not `>=`) | Boundary: exactly at threshold does NOT trigger. |
| 80 | Resource count just above threshold (5001) | `{}` (5001 resources) | `high_resource_count` issue present | Boundary: threshold+1 triggers. |
| 81 | Static memory at 91% of max | `{}` (static > 0.9 * max) | Issue of type `static_memory_near_limit`, `severity: "critical"` | Proportional threshold (90%). |
| 82 | Static memory at exactly 90% of max | `{}` (static == 0.9 * max) | No `static_memory_near_limit` issue (strict `>` not `>=`) | Boundary: exactly at 90% does NOT trigger. |
| 83 | High video memory (> 512 MB) | `{}` (video > 536870912 bytes) | Issue of type `high_video_memory`, `severity: "warning"` | Video memory threshold (512 MB). |
| 84 | Video memory at exactly 512 MB | `{}` (video == 536870912 bytes) | No `high_video_memory` issue (strict `>`) | Boundary: exactly at 512MB does NOT trigger. |
| 85 | Node depth > 50 | `{}` (deeply nested node tree) | Issue of type `deep_nesting`, `severity: "info"` with `depth` field | Deep nesting detection. |
| 86 | Node depth exactly 50 | `{}` (node at depth 50) | No `deep_nesting` issue (condition `depth > 50`) | Boundary: depth 50 does NOT trigger. |
| 87 | Node depth = 51 | `{}` (node at depth 51) | `deep_nesting` issue present with `depth: 51` | Boundary: depth 51 triggers. |
| 88 | Child count > 200 | `{}` (node with 201+ children) | Issue of type `high_child_count`, `severity: "warning"` with `child_count` | High child count detection. |
| 89 | Child count exactly 200 | `{}` (node with 200 children) | No `high_child_count` issue (condition `> 200`) | Boundary: 200 children does NOT trigger. |
| 90 | Child count = 201 | `{}` (node with 201 children) | `high_child_count` issue present | Boundary: 201 children triggers. |

### Multiple Issue Types

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 91 | Multiple issues simultaneously | `{}` (scene with orphans + deep nesting) | `issues` array has multiple entries; `issue_count` > 1; `clean` = false | All issues reported. |
| 92 | All 6 issue types triggered | `{}` (engineered scenario) | `issues` has 6 entries; `issue_count` = 6 | Maximum issue count. |
| 93 | Issues sorted/ordered correctly | `{}` (multiple issues) | Order: orphan_nodes, high_resource_count, static_memory_near_limit, then tree-scan results | Issues are appended in fixed order. |

### Edge Cases — Bridge / Connectivity

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 94 | Editor disconnected | `{}` | Error: connection timeout | Standard disconnected behavior. |
| 95 | Rapid repeated calls (10×) | `{}` × 10 | All succeed — list may grow if tree-scan appends duplicates per call | Note: `find_memory_leaks` scans the tree each call; repeated calls may accumulate duplicate tree-scan issues. |
| 96 | No scene open in editor | `{}` | Still returns results (uses monitor data, which is always available); tree-scan section may be skipped if root is null | Handles null scene root gracefully. |
| 97 | Call with `null` body | `null` | Valid JSON (as-if `{}`, no schema) | Null body handling. |

---

## Tool 4: `get_object_count`

**Description:** Get count of live objects, optionally filtered by class name  
**Handler:** `callGodot(bridge, 'get_object_count', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `class_name` | `string` | No | — | Filter by class name, or omit for total count |

**Expected result shape — No filter (class_name omitted):**
```json
{
  "result": {
    "total_objects": <int>,
    "nodes": <int>,
    "resources": <int>
  }
}
```

**Expected result shape — With class_name:**
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

**Or on error:**
```json
{
  "error": "Unknown class: <class_name>"
}
```

### Happy Path — No Filter (Total Count)

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 98 | Call with no arguments | `{}` | `{"result": {"total_objects": <int>, "nodes": <int>, "resources": <int>}}` | Simplest invocation. Returns total + breakdown. |
| 99 | Call with `class_name` omitted | `{}` (or body without `class_name` key) | Same as #98 — total counts | `class_name` is optional. |
| 100 | Verify `total_objects` ≥ `nodes + resources` | `{}` | `total_objects` >= `nodes` + `resources` | Total includes non-node, non-resource objects. |
| 101 | Verify all returned values are non-negative integers | `{}` | `total_objects` ≥ 0, `nodes` ≥ 0, `resources` ≥ 0 | Sanity check. |
| 102 | Call multiple times | `{}` × 3 | Consistent structure; values may vary between calls | Multiple calls stability. |

### Happy Path — With class_name Filter

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 103 | Filter: `Node2D` | `{"class_name": "Node2D"}` | `{"result": {"class_name": "Node2D", "count": <int>, "total_objects": <int>, "nodes": <int>, "resources": <int>}}` | Specific class count. |
| 104 | Filter: `CharacterBody3D` | `{"class_name": "CharacterBody3D"}` | `{"result": {"class_name": "CharacterBody3D", "count": <int>, ...}}` | 3D physics body class. |
| 105 | Filter: `RigidBody3D` | `{"class_name": "RigidBody3D"}` | `{"result": {"class_name": "RigidBody3D", "count": <int>, ...}}` | 3D rigid body class. |
| 106 | Filter: `Sprite2D` | `{"class_name": "Sprite2D"}` | `{"result": {"class_name": "Sprite2D", "count": <int>, ...}}` | 2D sprite class. |
| 107 | Filter: `Node` (base class) | `{"class_name": "Node"}` | `{"result": {"class_name": "Node", "count": <int>, ...}}` | Base class — counts ALL nodes (every node `is_class("Node")`). `count` should equal `nodes` from unfiltered call. |
| 108 | Filter: `Camera3D` | `{"class_name": "Camera3D"}` | `{"result": {"class_name": "Camera3D", "count": <int>, ...}}` | 3D camera class. |
| 109 | Filter: `Control` (UI base) | `{"class_name": "Control"}` | `{"result": {"class_name": "Control", "count": <int>, ...}}` | UI base class. |
| 110 | Filter: `AudioStreamPlayer` | `{"class_name": "AudioStreamPlayer"}` | `{"result": {"class_name": "AudioStreamPlayer", "count": <int>, ...}}` | Audio class. |
| 111 | Filter: class with 0 instances | `{"class_name": "Path3D"}` (no Path3D in scene) | `{"result": {"class_name": "Path3D", "count": 0, ...}}` | Class exists but no instances. |
| 112 | Verify `count` is consistent with tree inspection | 1. `get_object_count({"class_name": "Node2D"})`<br>2. `find_nodes_by_type("Node2D")` and count | `count` == number of Node2D nodes in tree | Cross-tool consistency. |
| 113 | Verify `total_objects`, `nodes`, `resources` match unfiltered call | 1. `get_object_count({})`<br>2. `get_object_count({"class_name": "Node2D"})` | Both return same `total_objects`, `nodes`, `resources` | Filtered call still returns global counts. |
| 114 | Filter with extra ignored param | `{"class_name": "Node2D", "extra": true}` | Success (extra arg ignored) | Zod drops unknown keys. |
| 115 | Filter: empty string | `{"class_name": ""}` | Behaves like no filter — returns total counts | Empty string = no filter (Godot checks `cls_name.is_empty()`). |

### Error Path — Invalid class_name

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 116 | Unknown class name | `{"class_name": "NonExistentClass"}` | `{"error": "Unknown class: NonExistentClass"}` | Not in ClassDB. |
| 117 | Typo: `Node2DD` | `{"class_name": "Node2DD"}` | `{"error": "Unknown class: Node2DD"}` | Class name typo. |
| 118 | Lowercase: `node2d` | `{"class_name": "node2d"}` | `{"error": "Unknown class: node2d"}` | Case-sensitive. |
| 119 | Whitespace-only: `"   "` | `{"class_name": "   "}` | `{"error": "Unknown class:    "}` | Whitespace passes Zod; unknown to Godot. |

### Edge Cases — Type Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 120 | `class_name` as number | `{"class_name": 42}` | Zod validation error | `z.string().optional()` rejects number (optional string expects undefined or string). |
| 121 | `class_name` as boolean | `{"class_name": false}` | Zod validation error | `z.string().optional()` rejects boolean. |
| 122 | `class_name` as object | `{"class_name": {"name": "Node2D"}}` | Zod validation error | `z.string().optional()` rejects object. |
| 123 | `class_name` as array | `{"class_name": ["Node2D"]}` | Zod validation error | `z.string().optional()` rejects array. |
| 124 | `class_name` as null | `{"class_name": null}` | Zod validation error | `z.string().optional()` rejects null (null ≠ undefined). |
| 125 | Very long class name (10000 chars) | `{"class_name": "A".repeat(10000)}` | `{"error": "Unknown class: AAAA..."}` | Long string passes Zod; Godot rejects. |
| 126 | Unicode class name | `{"class_name": "Узел"}` | `{"error": "Unknown class: Узел"}` | Unicode passes Zod; Godot rejects. |

### Edge Cases — Bridge / Connectivity

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 127 | Editor disconnected | `{}` | Error: connection timeout | Standard disconnected behavior. |
| 128 | Rapid repeated calls (10×) | `{"class_name": "Node2D"}` × 10 | All succeed; no race conditions | Stress test. |
| 129 | Call immediately after project load | `{}` | Valid JSON with low counts | Fresh project state. |
| 130 | Count `Node` then compare to `nodes` in unfiltered | 1. `get_object_count({"class_name": "Node"})`<br>2. `get_object_count({})` | `count` from step 1 == `nodes` from step 2 | Every node is a `Node`. |

---

## Tool 5: `force_garbage_collection`

**Description:** Force garbage collection and report the amount of memory freed  
**Handler:** `callGodot(bridge, 'force_garbage_collection')` (no args forwarded)  
**Parameters:** None (empty `inputSchema`)

**LIMITATION (from Godot implementation):** Godot does not expose a manual GC trigger API. RefCounted objects are freed immediately when references drop. This function only forces a brief pause to allow deferred `queue_free()` calls to complete. Reported changes reflect natural memory fluctuations, not forced collection.

**Expected result shape:**
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

**Fields detail:**

| Field | Type | Description |
|-------|------|-------------|
| `memory_before_mb` | string | Static memory before GC attempt (%.2f MB) |
| `memory_after_mb` | string | Static memory after GC attempt (%.2f MB) |
| `freed_mb` | string | Calculated freed memory (%.2f MB), clamped to ≥ 0 |
| `freed_bytes` | float | Calculated freed bytes, clamped to ≥ 0 |
| `objects_before` | int | Live object count before |
| `objects_after` | int | Live object count after |
| `objects_freed` | int | Difference, clamped to ≥ 0 |
| `orphans_before` | int | Orphan node count before |
| `orphans_after` | int | Orphan node count after |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 131 | Call with no arguments | `{}` | Valid JSON with all 9 result fields | Simplest invocation. |
| 132 | Verify `freed_bytes` ≥ 0 | `{}` | `freed_bytes` >= 0 | Freed memory clamped to non-negative. |
| 133 | Verify `freed_mb` format | `{}` | `freed_mb` is a string like `"X.XX"` (%.2f) | Format check. |
| 134 | Verify `memory_before_mb` format | `{}` | `memory_before_mb` is a string like `"X.XX"` | Format check. |
| 135 | Verify `memory_after_mb` format | `{}` | `memory_after_mb` is a string like `"X.XX"` | Format check. |
| 136 | Verify `objects_freed` ≥ 0 | `{}` | `objects_freed` >= 0 | Object delta clamped to non-negative. |
| 137 | Verify consistency: `freed_bytes` ≈ `(memory_before - memory_after)` | `{}` | `freed_bytes` ≈ parseFloat(`memory_before_mb`)*1048576 - parseFloat(`memory_after_mb`)*1048576 | Arithmetic consistency (within floating-point precision). |
| 138 | Verify consistency: `objects_freed` == max(`objects_before - objects_after`, 0) | `{}` | `objects_freed` == max(`objects_before` - `objects_after`, 0) | Object delta logic. |
| 139 | Call multiple times in sequence | `{}` × 3 | All succeed; each call reports valid before/after values | Multiple calls. |
| 140 | Call with extra ignored arg | `{"extra": true}` | Valid JSON (extra arg ignored) | Zod ignores unknown keys. |
| 141 | Verify `objects_before` is non-negative integer | `{}` | `objects_before` >= 0 | Sanity check. |
| 142 | Verify `orphans_before` is non-negative integer | `{}` | `orphans_before` >= 0 | Sanity check. |
| 143 | Verify `orphans_after` is non-negative integer | `{}` | `orphans_after` >= 0 | Sanity check. |

### Known Limitation — No True GC in Godot

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 144 | Empty project, no deferred frees | `{}` | `freed_bytes` ≈ 0, `objects_freed` ≈ 0, all `mb` values near equal | Without deferred calls to flush, results are near-identical. |
| 145 | After creating then queue_free() nodes | 1. Add nodes<br>2. `queue_free()` them<br>3. `force_garbage_collection` | `objects_freed` may be > 0 if deferred frees completed | GC allows deferred queue_free() to execute. |
| 146 | Memory may increase, not decrease | `{}` (under memory-allocation load) | `memory_after_mb` >= `memory_before_mb` | `freed_bytes` clamps to 0. Memory can grow despite GC. |

### Edge Cases — Bridge / Connectivity

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 147 | Editor disconnected | `{}` | Error: connection timeout | Standard disconnected behavior. |
| 148 | Call with `null` body | `null` | Valid JSON (as-if `{}`) | Null body handling. |
| 149 | Rapid repeated calls (10×) | `{}` × 10 | All succeed; each call does 3× `OS.delay_msec(16)` = ~48ms per call | Stress test. Successive calls should not corrupt state. |
| 150 | Call when no scene is open | `{}` | Still succeeds (uses monitor data which is always available) | No scene dependency. |

---

## Integration / Cross-Tool Scenarios

### get_memory_usage ↔ get_object_count

| # | Scenario | Steps | Expected result | Notes |
|---|----------|-------|-----------------|-------|
| 151 | Cross-verify object counts | 1. `get_memory_usage`<br>2. `get_object_count({})` | `mem.objects.total` == `get_object_count.total_objects`<br>`mem.objects.nodes` == `get_object_count.nodes`<br>`mem.objects.resources` == `get_object_count.resources` | Same data, different tools. |

### get_memory_usage ↔ find_memory_leaks

| # | Scenario | Steps | Expected result | Notes |
|---|----------|-------|-----------------|-------|
| 152 | Cross-verify orphan count | 1. `get_memory_usage`<br>2. `find_memory_leaks` | `mem.objects.orphan_nodes` == `leaks.orphan_nodes` | Orphan counts consistent. |
| 153 | Cross-verify resource count | 1. `get_memory_usage`<br>2. `find_memory_leaks` | `mem.objects.resources` == `leaks.resource_count` | Resource counts consistent. |
| 154 | Cross-verify static memory | 1. `get_memory_usage`<br>2. `find_memory_leaks` | `mem.categories.static.mb` ≈ `leaks.static_memory_mb` | Static memory consistent (formatting differences possible). |
| 155 | Cross-verify video memory | 1. `get_memory_usage`<br>2. `find_memory_leaks` | `mem.categories.video.mb` == `leaks.video_memory_mb` | Video memory consistent. |

### track_object_creation ↔ get_object_count

| # | Scenario | Steps | Expected result | Notes |
|---|----------|-------|-----------------|-------|
| 156 | Baseline cross-check | 1. `track_object_creation({"class_name": "Node2D"})`<br>2. `get_object_count({"class_name": "Node2D"})` | `track.baseline_count` == `get_object_count.count` | Baseline should match current count. |
| 157 | Track then add node then re-check | 1. `track_object_creation({"class_name": "Camera3D"})`<br>2. `godot_add_node` (add Camera3D)<br>3. `get_object_count({"class_name": "Camera3D"})` | Step 3 count = baseline + 1 | Verify object creation tracking. |

### force_garbage_collection ↔ get_memory_usage

| # | Scenario | Steps | Expected result | Notes |
|---|----------|-------|-----------------|-------|
| 158 | Memory before/after GC | 1. `get_memory_usage` (baseline)<br>2. `force_garbage_collection`<br>3. `get_memory_usage` (after GC) | `gc.after_mb` ≈ step 3 `total_mb` | Memory values consistent between tools. |

### Lifecycle Scenarios

| # | Scenario | Steps | Expected result | Notes |
|---|----------|-------|-----------------|-------|
| 159 | Memory profiling round-trip: create → profile → delete → profile | 1. `get_memory_usage` (baseline)<br>2. `godot_add_node` (add 10 nodes)<br>3. `get_memory_usage` (after add)<br>4. `godot_delete_node` (delete all 10)<br>5. `get_memory_usage` (after delete)<br>6. `force_garbage_collection`<br>7. `get_memory_usage` (after GC) | Step 3: object count > baseline<br>Step 5: object count may still be > baseline (orphans)<br>Step 7: object count ≈ baseline (after GC flush) | Full memory lifecycle test. |
| 160 | Leak detection before/after node creation | 1. `find_memory_leaks` (baseline)<br>2. Create orphan nodes (dynamic creation outside tree)<br>3. `find_memory_leaks` (after leaks) | Step 3 shows orphan_nodes issue if step 2 created orphans | Orphan detection round-trip. |
| 161 | All 5 tools called in sequence (empty scene) | 1. `get_memory_usage`<br>2. `track_object_creation({"class_name": "Node2D"})`<br>3. `find_memory_leaks`<br>4. `get_object_count({})`<br>5. `get_object_count({"class_name": "Node2D"})`<br>6. `force_garbage_collection` | All succeed. No interference between tools. | Full module smoke test. |
| 162 | track → wait → force_gc → get_object_count pipeline | 1. `track_object_creation({"class_name": "Node2D", "duration": 5})`<br>2. Wait 5 seconds (manually or via script)<br>3. `force_garbage_collection`<br>4. `get_object_count({"class_name": "Node2D"})` | Step 4 shows current count; compare to step 1 baseline | Full tracking workflow. |

### Performance / Stress

| # | Scenario | Steps | Expected result | Notes |
|---|----------|-------|-----------------|-------|
| 163 | All 5 tools called 10× each in rapid succession | 50 total calls in a tight loop | All succeed; no timeouts, no race conditions, no memory corruption | Heavy stress test. |
| 164 | `find_memory_leaks` on large scene (1000+ nodes) | `{}` on a large scene | Returns within timeout; tree-scan completes | Performance with large tree. |
| 165 | `get_object_count` with class name containing >500 instances | `{"class_name": "Node2D"}` on scene with 500+ Node2D | Returns within timeout; count is accurate | Performance with large filtered count. |

---

## Summary: Parameter Coverage

| Tool | Parameter | Type | Required | Default | Zod Constraints | Godot Constraints |
|------|-----------|------|----------|---------|-----------------|-------------------|
| `get_memory_usage` | (none) | — | — | — | `{}` (empty schema) | Returns snapshot from `Performance.get_monitor()` |
| `track_object_creation` | `class_name` | `string` | **Yes** | — | `z.string()` (NodeType) | `ClassDB.class_exists()` check; rejects empty |
| `track_object_creation` | `duration` | `number` | No | `10` | `z.number().min(1).max(60)` | Floats accepted |
| `find_memory_leaks` | (none) | — | — | — | `{}` (empty schema) | Scans orphan count, resource count, static/video memory, scene tree (depth > 50, children > 200) |
| `get_object_count` | `class_name` | `string` | No | — | `z.string().optional()` (NodeType) | Empty → total counts; non-empty → `ClassDB.class_exists()` check |
| `force_garbage_collection` | (none) | — | — | — | `{}` (empty schema) | 3× `OS.delay_msec(16)` to flush deferred calls; snapshots before/after |

---

## Summary: Coverage Statistics

| Category | Count |
|----------|-------|
| **Total scenarios** | **165** |
| `get_memory_usage` scenarios | 18 (happy path + structure verification + edge cases + boundaries) |
| `track_object_creation` scenarios | 43 (happy path + class names + duration bounds + error paths + type validation) |
| `find_memory_leaks` scenarios | 36 (happy path + all 6 issue types + boundaries + multiple issues + connectivity) |
| `get_object_count` scenarios | 33 (happy path no-filter + with-filter + error paths + type validation) |
| `force_garbage_collection` scenarios | 19 (happy path + limitations + edge cases + connectivity) |
| Integration scenarios | 15 (cross-tool verification + lifecycle + stress) |
| Parameter coverage | 5/5 parameters (100%) — all params and no-param tools covered |
| Zod rejection scenarios | 19 (class_name type errors, duration type/boundary errors) |
| Godot error scenarios | 12 (unknown class, empty class, connectivity) |
| Bridge/connectivity scenarios | 5 (one per tool) |
| Boundary value scenarios | 20 (duration min/max, resource thresholds, depth thresholds, child count thresholds, memory thresholds) |
| Cross-tool consistency | 10 |

**Coverage:** Every tool, every parameter, every Zod constraint, every Godot error path, all 6 `find_memory_leaks` issue types with boundary conditions, all response structure keys, cross-tool data consistency checks, lifecycle round-trips, and stress tests. 100% parameter coverage.
