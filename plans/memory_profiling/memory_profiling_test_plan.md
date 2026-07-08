# Memory Profiling Tools — Test Plan

> **Source file:** `server/src/tools/memory_profiling.ts`
> **Godot bridge endpoints:** `get_memory_usage`, `track_object_creation`, `find_memory_leaks`, `get_object_count`, `force_garbage_collection`
> **Generated:** 2026-07-08

---

## Overview

All 5 tools in this module provide memory diagnostics and profiling capabilities. Two tools have parameters (`track_object_creation`, `get_object_count`) and three are parameterless (`get_memory_usage`, `find_memory_leaks`, `force_garbage_collection`).

| # | Tool Name | Bridge Method | Params | Handler Pattern |
|---|-----------|--------------|--------|-----------------|
| 1 | `get_memory_usage` | `get_memory_usage` | None | `() => callGodot(bridge, 'get_memory_usage')` |
| 2 | `track_object_creation` | `track_object_creation` | `class_name` (required), `duration` (optional, default 10) | `(args) => callGodot(bridge, 'track_object_creation', args)` |
| 3 | `find_memory_leaks` | `find_memory_leaks` | None | `() => callGodot(bridge, 'find_memory_leaks')` |
| 4 | `get_object_count` | `get_object_count` | `class_name` (optional) | `(args) => callGodot(bridge, 'get_object_count', args)` |
| 5 | `force_garbage_collection` | `force_garbage_collection` | None | `() => callGodot(bridge, 'force_garbage_collection')` |

### Shared Types Used

From `shared-types.ts`:
- **`NodeType`** = `z.string().describe("Node type name (e.g. 'Sprite2D', 'CharacterBody3D')")` — a non-empty string representing a Godot class/type name

### Runtime State Dependencies

| State Requirement | Tools Affected |
|-------------------|---------------|
| Godot editor connected | All 5 tools |
| Game may be running or not | `get_memory_usage`, `find_memory_leaks`, `get_object_count`, `force_garbage_collection` |
| Game should be running for meaningful tracking | `track_object_creation` |

---

## Tool: `get_memory_usage`

**Description:** Get detailed memory usage breakdown by category (static, video, textures, buffers, objects)

**Parameters:** None (empty schema).

**Handler:**
```typescript
async () => callGodot(bridge, 'get_memory_usage')
```

---

### Test Scenarios

#### Scenario 1: Happy path — call with empty params
- **Description:** Call with no arguments on a connected Godot editor with a project open. Should return a detailed memory breakdown.
- **Params:** `{}`
- **Expected result:** JSON object with memory usage categories (static, video, textures, buffers, objects, etc.). Each category should have a size value (likely in bytes or MB). Not an error.
- **Notes:** Expected keys may include `static`, `video`, `textures`, `buffers`, `objects`. Values must be non-negative numbers.

#### Scenario 2: Memory values are non-negative
- **Description:** Verify all memory category values are non-negative (sanity check). Memory usage cannot be negative.
- **Params:** `{}`
- **Expected result:** All numeric values in the response are >= 0. Any negative value is a bug.
- **Notes:** This is a data-integrity assertion on the response.

#### Scenario 3: Memory values sum consistently
- **Description:** The total memory should be > 0 for an open project and should logically be at least as large as any individual category.
- **Params:** `{}`
- **Expected result:** If a `total` or sum field is present, it should be >= each individual category. Not an error.
- **Notes:** Depends on how the Godot plugin aggregates memory data.

#### Scenario 4: Call with extra params — forwarded to Godot
- **Description:** Pass arbitrary extra properties. The handler passes no args, so extra params are completely unused.
- **Params:** `{ "category": "video" }`
- **Expected result:** Same output as Scenario 1. Extra params are ignored since the handler signature is `async ()`.
- **Notes:** The handler takes no arguments — `() => ...`. Extra params are discarded at the handler level, not forwarded. This differs from tools that use `(args) => callGodot(bridge, ..., args)`.

#### Scenario 5: Godot editor not connected
- **Description:** Call when the bridge is disconnected (Godot editor not running).
- **Params:** `{}`
- **Expected result:** Error result with `isError: true`, containing a message like "Godot request failed: ...".
- **Notes:** Covered by the `callGodot` error handler in `server.ts`.

---

## Tool: `track_object_creation`

**Description:** Track object creation for a specific class over a duration. Records a baseline count; poll `get_object_count` afterward to see changes.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `class_name` | `string` (NodeType) | ✅ | Godot class name to track (e.g. `'Node2D'`, `'RigidBody3D'`) |
| `duration` | `number` (min 1, max 60, default 10) | ❌ | Tracking duration in seconds (default: 10) |

**Handler:**
```typescript
async (args) => callGodot(bridge, 'track_object_creation', args as Record<string, unknown>)
```

---

### Test Scenarios

#### Scenario 1: Happy path — track with minimum params
- **Description:** Track object creation for a known Godot class with only the required `class_name`. Duration defaults to 10.
- **Params:** `{ "class_name": "Node2D" }`
- **Expected result:** Success response with baseline count and tracking confirmation. Returns after ~10 seconds (default duration).
- **Notes:** The tool takes ~10 seconds to complete. Should return a baseline object count for `Node2D`. Best run with the game active so objects may be created.

#### Scenario 2: Happy path — track with explicit duration
- **Description:** Track object creation with a custom duration.
- **Params:** `{ "class_name": "Node2D", "duration": 5 }`
- **Expected result:** Success response with baseline count. Returns after ~5 seconds.
- **Notes:** Verify the call returns roughly at the 5 second mark (not 10).

#### Scenario 3: Happy path — track a different class
- **Description:** Track a different Godot class type.
- **Params:** `{ "class_name": "RigidBody3D" }`
- **Expected result:** Success response with baseline count for `RigidBody3D`. No error.
- **Notes:** Should work for any valid Godot class name.

#### Scenario 4: Happy path — track with minimum duration (boundary)
- **Description:** Track with `duration: 1` — the minimum allowed value.
- **Params:** `{ "class_name": "Node2D", "duration": 1 }`
- **Expected result:** Success response. Returns after ~1 second.
- **Notes:** Tests the `min(1)` boundary. Should not be rejected by schema validation.

#### Scenario 5: Happy path — track with maximum duration (boundary)
- **Description:** Track with `duration: 60` — the maximum allowed value.
- **Params:** `{ "class_name": "Node2D", "duration": 60 }`
- **Expected result:** Success response. Returns after ~60 seconds.
- **Notes:** Tests the `max(60)` boundary. Use with caution — this is a long-running call. Should not be rejected by schema validation.

#### Scenario 6: Schema validation — duration = 0 (below minimum)
- **Description:** Call with duration 0, which violates `z.number().min(1)`.
- **Params:** `{ "class_name": "Node2D", "duration": 0 }`
- **Expected result:** Zod validation error. The call is rejected by the server before reaching Godot.
- **Notes:** Verifies the `min(1)` constraint.

#### Scenario 7: Schema validation — duration = negative
- **Description:** Call with a negative duration.
- **Params:** `{ "class_name": "Node2D", "duration": -5 }`
- **Expected result:** Zod validation error. Rejected by server.
- **Notes:** Also tests `min(1)`.

#### Scenario 8: Schema validation — duration = 61 (above maximum)
- **Description:** Call with duration 61, violating `z.number().max(60)`.
- **Params:** `{ "class_name": "Node2D", "duration": 61 }`
- **Expected result:** Zod validation error. Rejected by server.
- **Notes:** Verifies the `max(60)` constraint.

#### Scenario 9: Schema validation — duration is a float
- **Description:** Call with a floating-point duration. Note: the schema is `z.number()` without `.int()`, so floats should be accepted.
- **Params:** `{ "class_name": "Node2D", "duration": 5.5 }`
- **Expected result:** Should pass Zod validation (no `.int()` constraint on `duration`). The Godot plugin may round or truncate the value. Should not error at the server level.
- **Notes:** The schema does NOT restrict to integers. This is intentional — fractional-second tracking may be supported.

#### Scenario 10: Schema validation — missing required `class_name`
- **Description:** Call without the required `class_name` parameter.
- **Params:** `{ "duration": 5 }`
- **Expected result:** Zod validation error. Rejected by server.
- **Notes:** `class_name` has no `.optional()` — it is required.

#### Scenario 11: Schema validation — class_name is empty string
- **Description:** Call with an empty class name.
- **Params:** `{ "class_name": "" }`
- **Expected result:** May pass schema validation (empty string is a valid string) but should produce an error from Godot about invalid class name.
- **Notes:** Zod's `z.string()` accepts empty strings. The Godot plugin should reject it.

#### Scenario 12: Edge case — nonexistent class name
- **Description:** Call with a class name that does not exist in Godot.
- **Params:** `{ "class_name": "NonExistentClassXYZ" }`
- **Expected result:** Error from Godot (unknown class type). Not a server-side validation error.
- **Notes:** Server has no knowledge of valid Godot class names.

#### Scenario 13: Edge case — track built-in engine class
- **Description:** Track a built-in engine class like `Object` or `Resource`.
- **Params:** `{ "class_name": "Object" }`
- **Expected result:** Success response with baseline count for `Object`. Count will likely be very large since many things inherit from Object.
- **Notes:** Validates that base engine classes can be tracked.

#### Scenario 14: Edge case — extra unknown params
- **Description:** Pass an extra unknown parameter alongside valid params.
- **Params:** `{ "class_name": "Node2D", "duration": 5, "extra_field": "unexpected" }`
- **Expected result:** Should pass Zod validation (unknown keys are typically stripped or ignored by Zod when not in `.strict()` mode). The call should succeed like Scenario 2. Extra field may be forwarded to Godot or stripped.
- **Notes:** Zod's default mode (`z.object({...})`) strips unknown keys. The `extra_field` is silently removed before the handler receives args.

#### Scenario 15: Godot editor not connected
- **Description:** Call when the bridge is disconnected.
- **Params:** `{ "class_name": "Node2D", "duration": 5 }`
- **Expected result:** Error result with `isError: true`, containing a message like "Godot request failed: ...".
- **Notes:** Covered by the `callGodot` error handler.

---

## Tool: `find_memory_leaks`

**Description:** Analyze the scene tree and object graph to find potential memory leaks (orphan nodes, leaked resources)

**Parameters:** None (empty schema).

**Handler:**
```typescript
async () => callGodot(bridge, 'find_memory_leaks')
```

---

### Test Scenarios

#### Scenario 1: Happy path — call with empty params on open project
- **Description:** Call on a project with an open scene. Should return analysis results identifying potential leaks.
- **Params:** `{}`
- **Expected result:** JSON object or array listing potential memory leaks (orphan nodes, unreferenced resources, circular references). Not an error.
- **Notes:** Expected format may include node paths, resource paths, or descriptions of leak patterns. Empty list is a valid result (no leaks detected).

#### Scenario 2: Project with known orphan nodes
- **Description:** Call after programmatically creating orphan nodes (nodes not attached to the scene tree) via scripting. Should detect these as potential leaks.
- **Params:** `{}`
- **Expected result:** JSON response listing the orphan nodes. Leak count should be >= 1 if orphans exist.
- **Notes:** Setup: create orphan nodes via `execute_editor_script` or `execute_game_script` before calling this tool. Requires pre-existing leak scenario.

#### Scenario 3: Clean project with no leaks
- **Description:** Call on a clean, empty project with a single open scene.
- **Params:** `{}`
- **Expected result:** JSON response with zero leaks detected (e.g., empty array `[]` or object with count 0). Not an error.
- **Notes:** Validates the "nothing found" case.

#### Scenario 4: Call with extra params — ignored by handler
- **Description:** Pass arbitrary extra properties. The handler `async ()` takes no arguments.
- **Params:** `{ "deep_scan": true, "threshold": 100 }`
- **Expected result:** Same output as Scenario 1. Extra params are discarded by the handler.
- **Notes:** The handler signature is `async ()` — no args, unlike `(args) => callGodot(bridge, ..., args)` tools.

#### Scenario 5: Godot editor not connected
- **Description:** Call when the bridge is disconnected.
- **Params:** `{}`
- **Expected result:** Error result with `isError: true`, containing a message like "Godot request failed: ...".
- **Notes:** Covered by the `callGodot` error handler.

---

## Tool: `get_object_count`

**Description:** Get count of live objects, optionally filtered by class name

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `class_name` | `string` (NodeType) | ❌ | Filter by class name, or omit for total count |

**Handler:**
```typescript
async (args) => callGodot(bridge, 'get_object_count', args as Record<string, unknown>)
```

---

### Test Scenarios

#### Scenario 1: Happy path — get total object count (no filter)
- **Description:** Call with no arguments to get the total live object count across all classes.
- **Params:** `{}`
- **Expected result:** JSON object or value representing the total number of live objects. Should be a positive integer for any open project.
- **Notes:** The count should be > 0 for any project with an open scene. Typical values: hundreds to thousands.

#### Scenario 2: Happy path — filter by specific class name
- **Description:** Get object count filtered to a specific class.
- **Params:** `{ "class_name": "Node2D" }`
- **Expected result:** JSON with count of live `Node2D` objects. Should be >= 0. Should be <= the total count from Scenario 1.
- **Notes:** The filtered count must not exceed the unfiltered count.

#### Scenario 3: Happy path — filter by another class
- **Description:** Filter by a different class to verify consistent behavior.
- **Params:** `{ "class_name": "Resource" }`
- **Expected result:** JSON with count of live `Resource` objects. Should be >= 0.
- **Notes:** Resource counts may be high since many assets derive from Resource.

#### Scenario 4: Happy path — filter by engine base class
- **Description:** Filter by `Object` — the root class of almost all Godot types.
- **Params:** `{ "class_name": "Object" }`
- **Expected result:** JSON with a large count. Should approximately equal the unfiltered total (since most things inherit from Object).
- **Notes:** Validates base class filtering.

#### Scenario 5: Comparison consistency — filtered <= unfiltered
- **Description:** Call unfiltered, then filtered by class. The filtered count must be <= unfiltered.
- **Params (step 1):** `{}`
- **Params (step 2):** `{ "class_name": "Node2D" }`
- **Expected result:** `count_filtered <= count_unfiltered`. If violating, there is a logic bug.
- **Notes:** This is a cross-call sanity check.

#### Scenario 6: Filter by nonexistent class name
- **Description:** Filter by a class name that does not exist in Godot.
- **Params:** `{ "class_name": "FakeClassNotFound123" }`
- **Expected result:** May return 0 (no objects of this type) or an error from Godot. Should not crash.
- **Notes:** Server-side validation passes (any string is valid).

#### Scenario 7: Filter by empty string
- **Description:** Filter by empty class name.
- **Params:** `{ "class_name": "" }`
- **Expected result:** May be treated as "no filter" (total count) or produce an error from Godot. Should not crash.
- **Notes:** Empty string passes Zod validation since `class_name` is `NodeType.optional()` — `z.string().optional()`.

#### Scenario 8: Call with extra unknown params
- **Description:** Pass an extra unknown parameter alongside the filter.
- **Params:** `{ "class_name": "Node2D", "include_children": true }`
- **Expected result:** Should pass Zod validation. The `include_children` key may be stripped by Zod or forwarded to Godot. Should not error at the server level.
- **Notes:** Zod strips unknown keys by default. The handler receives `{ class_name: "Node2D" }`.

#### Scenario 9: Schema validation — class_name is not a string
- **Description:** Pass a non-string value for `class_name` (e.g., a number).
- **Params:** `{ "class_name": 42 }`
- **Expected result:** Zod validation error. Rejected by server.
- **Notes:** `NodeType` is `z.string()`. A number does not satisfy this.

#### Scenario 10: Schema validation — class_name is boolean
- **Description:** Pass a boolean for `class_name`.
- **Params:** `{ "class_name": true }`
- **Expected result:** Zod validation error. Rejected by server.
- **Notes:** Booleans are not strings in Zod's strict mode.

#### Scenario 11: Godot editor not connected
- **Description:** Call when the bridge is disconnected.
- **Params:** `{ "class_name": "Node2D" }`
- **Expected result:** Error result with `isError: true`, containing a message like "Godot request failed: ...".
- **Notes:** Covered by the `callGodot` error handler.

---

## Tool: `force_garbage_collection`

**Description:** Force garbage collection and report the amount of memory freed

**Parameters:** None (empty schema).

**Handler:**
```typescript
async () => callGodot(bridge, 'force_garbage_collection')
```

---

### Test Scenarios

#### Scenario 1: Happy path — call with empty params
- **Description:** Call on a connected Godot editor. Should trigger garbage collection and report results.
- **Params:** `{}`
- **Expected result:** JSON object with at minimum a field indicating how much memory was freed (e.g., `freed_bytes`, `freed_mb`, or similar). Not an error.
- **Notes:** The amount freed may be 0 if GC had nothing to collect. That is still a valid success response.

#### Scenario 2: GC after creating and releasing many objects
- **Description:** Create many temporary objects, release references, then force GC. Should report non-zero freed memory.
- **Params:** `{}`
- **Expected result:** JSON with freed memory > 0 (if setup was effective). Not an error.
- **Notes:** Setup: use `execute_editor_script` to create and then null out many temporary Resource or Node objects, then call this tool. This validates GC actually works.

#### Scenario 3: Two consecutive GC calls
- **Description:** Call `force_garbage_collection` twice in a row. The second call should report little or no freed memory (since first call cleaned everything).
- **Params (both calls):** `{}`
- **Expected result:** First call may report freed memory > 0. Second call reports freed memory = 0 or very small. Neither call should error.
- **Notes:** Validates that GC is genuinely collecting and the reporting is accurate.

#### Scenario 4: Call with extra params — ignored by handler
- **Description:** Pass arbitrary extra properties. The handler takes no arguments.
- **Params:** `{ "full_collect": true, "verbose": true }`
- **Expected result:** Same output as Scenario 1. Extra params are discarded by the `async ()` handler.
- **Notes:** Handler signature is `async ()` — no forwarding to Godot with extra params.

#### Scenario 5: Godot editor not connected
- **Description:** Call when the bridge is disconnected.
- **Params:** `{}`
- **Expected result:** Error result with `isError: true`, containing a message like "Godot request failed: ...".
- **Notes:** Covered by the `callGodot` error handler.

---

## Cross-Tool Integration Scenarios

These scenarios test interactions between multiple memory profiling tools.

### Integration Scenario 1: track → get_object_count → verify consistency
- **Description:** Call `track_object_creation` for a class, then immediately call `get_object_count` for the same class. The baseline from tracking and the current count should be consistent.
- **Steps:**
  1. `track_object_creation`: `{ "class_name": "Node2D", "duration": 3 }`
  2. `get_object_count`: `{ "class_name": "Node2D" }`
- **Expected result:** The baseline count from step 1 should be <= the count from step 2 (since objects may be created during/after tracking). Values should be within a reasonable range of each other.
- **Notes:** There may be a slight discrepancy due to timing.

### Integration Scenario 2: get_memory_usage → force_garbage_collection → get_memory_usage
- **Description:** Snapshot memory before GC, force GC, snapshot again. Memory usage after GC should be <= memory before GC.
- **Steps:**
  1. `get_memory_usage`: `{}`
  2. `force_garbage_collection`: `{}`
  3. `get_memory_usage`: `{}`
- **Expected result:** Memory (static or total) in step 3 should be <= step 1, or at minimum not significantly higher (within a few KB tolerance).
- **Notes:** Minor fluctuations are normal due to engine overhead. A drastic increase would be suspicious.

### Integration Scenario 3: find_memory_leaks → force_garbage_collection → find_memory_leaks
- **Description:** Check for leaks, force GC, check again. Leak count after GC should be <= leak count before GC.
- **Steps:**
  1. `find_memory_leaks`: `{}`
  2. `force_garbage_collection`: `{}`
  3. `find_memory_leaks`: `{}`
- **Expected result:** Leak count after GC (step 3) should be <= leak count before GC (step 1). GC should not increase leak count.
- **Notes:** If GC frees leaked objects, count goes down. If nothing was leaked, count stays at 0.

### Integration Scenario 4: get_memory_usage response contains all expected categories
- **Description:** Verify the response structure from `get_memory_usage` includes all documented categories.
- **Params:** `{}`
- **Expected result:** Response should include keys for at minimum: `static`, `video` (or `textures`). May also include `objects`, `buffers`. Each should be a JSON object or number.
- **Notes:** This is a schema validation on the response content, not just pass/fail.
