# Profiling Tools — Test Plan

> **Source file:** `server/src/tools/profiling.ts`
> **Godot bridge endpoints:** `profiling/monitors`, `profiling/editor_performance`
> **Generated:** 2026-07-08

---

## Overview

This module contains 2 tools for reading Godot's built-in performance monitors. One tool accepts an optional filter parameter; the other accepts no parameters.

| # | Tool Name | Bridge Method | Params | Handler Pattern |
|---|-----------|--------------|--------|-----------------|
| 1 | `get_performance_monitors` | `profiling/monitors` | `monitors` (optional, string[]) | `(args) => callGodot(bridge, 'profiling/monitors', args)` |
| 2 | `get_editor_performance` | `profiling/editor_performance` | None | `() => callGodot(bridge, 'profiling/editor_performance')` |

### Shared Types Used

From `shared-types.ts`:
- **`z`** (Zod) — re-exported from `shared-types.ts` for schema construction. Used here via `z.array(z.string())` for the `monitors` parameter.

### Runtime State Dependencies

| State Requirement | Tools Affected |
|-------------------|---------------|
| Godot editor connected | Both tools |
| Project must be open | Both tools |
| Game may be running or not | Both tools (but game running yields more interesting data) |

---

## Tool: `get_performance_monitors`

**Description:** Get all performance monitor values (FPS, memory, physics, rendering, navigation)

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `monitors` | `string[]` | No | (omitted — returns all) | Filter to specific monitor names only (e.g. `["time/fps", "memory/static"]`). Returns all monitors if omitted. |

**Handler:**
```typescript
async (args) => callGodot(bridge, 'profiling/monitors', args as Record<string, unknown>)
```

**Notes:**
- The `monitors` parameter is an array of exact monitor name strings as used by Godot's `Performance` singleton (e.g. `Performance.get_monitor(Performance.TIME_FPS)` corresponds to the name `"time/fps"`).
- Known Godot 4.x monitor names include: `time/fps`, `time/process`, `time/physics_process`, `memory/static`, `memory/static_max`, `memory/stack`, `rendering/frame_time`, `physics/fps`, `physics/active_objects`, `navigation/active_maps`.
- When `monitors` is omitted, all available monitors are returned as a flat object keyed by monitor name.
- When `monitors` is supplied, only the requested monitor names are returned.

---

### Test Scenarios

#### Scenario 1: Happy path — no filter (return all monitors)
- **Description:** Call with no arguments on a connected Godot editor with a project open. Should return all available performance monitors as a key-value object.
- **Params:** `{}`
- **Expected result:** JSON object where keys are monitor name strings (e.g. `"time/fps"`, `"memory/static"`, `"rendering/frame_time"`) and values are numbers. Response must not be an error. At minimum, `"time/fps"` should be present.
- **Notes:** The exact set of keys depends on Godot version and renderer, but `time/fps` is universal.

#### Scenario 2: Happy path — filter to a single known monitor
- **Description:** Request only `time/fps`. Should return only that monitor.
- **Params:** `{ "monitors": ["time/fps"] }`
- **Expected result:** JSON object with exactly one key `"time/fps"` whose value is a number (typically 0–999, representing frames per second). Not an error.
- **Notes:** FPS value should be > 0 in a running project (both edit mode and play mode).

#### Scenario 3: Happy path — filter to multiple known monitors
- **Description:** Request `time/fps` and `memory/static` simultaneously.
- **Params:** `{ "monitors": ["time/fps", "memory/static"] }`
- **Expected result:** JSON object with exactly two keys: `"time/fps"` and `"memory/static"`. Both values must be numbers. `"time/fps"` > 0; `"memory/static"` >= 0. Not an error.
- **Notes:** Verifies the array filter works for multiple entries.

#### Scenario 4: Happy path — filter to `time/process`
- **Description:** Request the process time monitor specifically.
- **Params:** `{ "monitors": ["time/process"] }`
- **Expected result:** JSON object with key `"time/process"` set to a number (milliseconds per frame in process). Value >= 0. Not an error.
- **Notes:** Useful to verify this specific Godot monitor is accessible.

#### Scenario 5: Happy path — filter to `time/physics_process`
- **Description:** Request the physics process time monitor.
- **Params:** `{ "monitors": ["time/physics_process"] }`
- **Expected result:** JSON object with key `"time/physics_process"` set to a number. Value >= 0. Not an error.
- **Notes:** Physics process time may be 0 if no physics is active.

#### Scenario 6: Happy path — filter to `memory/static`
- **Description:** Request only the static memory monitor.
- **Params:** `{ "monitors": ["memory/static"] }`
- **Expected result:** JSON object with key `"memory/static"` set to a number (bytes of static memory). Value > 0. Not an error.
- **Notes:** Static memory should always be > 0 since the editor/project uses memory.

#### Scenario 7: Happy path — filter to `memory/static_max`
- **Description:** Request only the static memory max monitor.
- **Params:** `{ "monitors": ["memory/static_max"] }`
- **Expected result:** JSON object with key `"memory/static_max"` set to a number. Value >= `memory/static`. Not an error.
- **Notes:** `static_max` is typically >= `static` value.

#### Scenario 8: Happy path — filter to `rendering/frame_time`
- **Description:** Request the frame time render stat.
- **Params:** `{ "monitors": ["rendering/frame_time"] }`
- **Expected result:** JSON object with key `"rendering/frame_time"` set to a number (milliseconds). Value >= 0. Not an error.
- **Notes:** Frame time should be non-negative. Typically 0–1000 ms range.

#### Scenario 9: Happy path — filter to `physics/fps`
- **Description:** Request the physics FPS monitor.
- **Params:** `{ "monitors": ["physics/fps"] }`
- **Expected result:** JSON object with key `"physics/fps"` set to a number. Value >= 0. Not an error.
- **Notes:** Default physics FPS is typically 60, but may vary.

#### Scenario 10: Happy path — filter to `physics/active_objects`
- **Description:** Request active physics objects count.
- **Params:** `{ "monitors": ["physics/active_objects"] }`
- **Expected result:** JSON object with key `"physics/active_objects"` set to an integer. Value >= 0. Not an error.
- **Notes:** In a fresh scene without physics bodies, this may be 0.

#### Scenario 11: Happy path — filter to `navigation/active_maps`
- **Description:** Request active navigation maps count.
- **Params:** `{ "monitors": ["navigation/active_maps"] }`
- **Expected result:** JSON object with key `"navigation/active_maps"` set to an integer. Value >= 0. Not an error.
- **Notes:** In a fresh scene without navigation regions, this may be 0.

#### Scenario 12: Edge case — empty array filter
- **Description:** Pass an empty `monitors` array. The handler forwards this to Godot.
- **Params:** `{ "monitors": [] }`
- **Expected result:** Either returns an empty object `{}` (no monitors matched) OR the Godot plugin returns all monitors (treats empty as "no filter"). Either behavior is acceptable as long as it's not an error.
- **Notes:** The exact behavior depends on the Godot plugin implementation. If the plugin treats `[]` as "no filter", expect all monitors. If it filters to an empty set, expect `{}`.

#### Scenario 13: Edge case — unknown monitor name
- **Description:** Request a monitor name that does not exist in Godot.
- **Params:** `{ "monitors": ["nonexistent/monitor"] }`
- **Expected result:** Either returns an empty object `{}` with no keys (unknown monitor ignored) OR returns the key with a value of 0 or null. Should NOT be an error.
- **Notes:** Godot's `Performance.get_monitor()` returns 0 for unknown monitors in some versions. This is a resilience check.

#### Scenario 14: Edge case — mixed valid and invalid monitor names
- **Description:** Request one valid and one invalid monitor name.
- **Params:** `{ "monitors": ["time/fps", "invalid/xyz"] }`
- **Expected result:** Should contain `"time/fps"` with its normal value. The `"invalid/xyz"` key may be present (with 0) or absent. Not an error.
- **Notes:** Verifies partial filtering — valid monitors should not be blocked by invalid ones in the same request.

#### Scenario 15: Edge case — case sensitivity check
- **Description:** Use uppercase or mixed-case versions of known monitor names.
- **Params:** `{ "monitors": ["TIME/FPS", "Time/Fps"] }`
- **Expected result:** These are likely treated as different from `"time/fps"`. Expect either empty results or 0 values. Should NOT crash or error.
- **Notes:** Godot monitor names are case-sensitive lowercase. This verifies the plugin does not crash on unexpected casing.

#### Scenario 16: Edge case — monitors parameter is a string (not array)
- **Description:** Pass a plain string instead of an array for `monitors`.
- **Params:** `{ "monitors": "time/fps" }`
- **Expected result:** Error result with `isError: true`. Zod validation should reject because `z.array(z.string())` does not accept a bare string.
- **Notes:** The Zod schema enforces `array(string)`. A bare string is a type mismatch.

#### Scenario 17: Edge case — monitors parameter is a number
- **Description:** Pass a number where an array of strings is expected.
- **Params:** `{ "monitors": 42 }`
- **Expected result:** Error result with `isError: true`. Zod validation should reject the type mismatch.
- **Notes:** Type validation at the Zod layer.

#### Scenario 18: Edge case — monitors array contains non-string elements
- **Description:** Pass an array with mixed types, including a number.
- **Params:** `{ "monitors": ["time/fps", 123, true] }`
- **Expected result:** Error result with `isError: true`. Zod validation should reject because the array elements are not all strings.
- **Notes:** `z.array(z.string())` requires every element to be a string.

#### Scenario 19: Edge case — very large monitor name
- **Description:** Pass a single monitor name that is extremely long (e.g., 10,000 characters).
- **Params:** `{ "monitors": ["a".repeat(10000)] }`
- **Expected result:** Should not crash. Either returns the key with value 0 (unknown monitor) or an empty result. Not an error.
- **Notes:** Tests resilience against malformed input. The Godot plugin should handle arbitrary-length strings gracefully.

#### Scenario 20: Edge case — large number of monitor names
- **Description:** Pass an array with a very large number of monitor entries (e.g., 1000 entries, many duplicates).
- **Params:** `{ "monitors": Array(1000).fill("time/fps") }`
- **Expected result:** Should return `{ "time/fps": <number> }` — duplicates should be collapsed. Not an error. Response time should be reasonable (not timeout).
- **Notes:** Tests performance and deduplication behavior under load.

#### Scenario 21: Edge case — special characters in monitor name
- **Description:** Pass a monitor name containing special characters like null bytes or Unicode.
- **Params:** `{ "monitors": ["time/\u0000fps", "mémöry/stätïc"] }`
- **Expected result:** Should not crash. Either returns 0/empty for these keys or ignores them. Not an error.
- **Notes:** Tests input sanitization in the Godot plugin.

#### Scenario 22: Edge case — extra unknown parameters passed alongside `monitors`
- **Description:** Pass additional arbitrary keys alongside the `monitors` parameter.
- **Params:** `{ "monitors": ["time/fps"], "extra_field": "should_be_ignored" }`
- **Expected result:** Should still return `{ "time/fps": <number> }`. The `extra_field` should be ignored or forwarded harmlessly. Not an error.
- **Notes:** The handler passes `args as Record<string, unknown>` to `callGodot`, so extra fields are forwarded. The Godot plugin should ignore unknown keys.

#### Scenario 23: Godot editor not connected
- **Description:** Call when the bridge is disconnected (Godot editor not running).
- **Params:** `{}`
- **Expected result:** Error result with `isError: true`, containing a message like "Godot request failed: ..." or similar.
- **Notes:** Covered by the `callGodot` error handler in `server.ts`.

#### Scenario 24: Passive call — FPS value is numeric
- **Description:** Call `get_performance_monitors` and assert that the returned FPS is a finite number.
- **Params:** `{ "monitors": ["time/fps"] }`
- **Expected result:** `typeof result["time/fps"] === "number"` and `isFinite(result["time/fps"])`. Not NaN, not Infinity.
- **Notes:** Data integrity check — FPS should always be a finite number.

#### Scenario 25: Passive call — memory values are non-negative
- **Description:** Call with memory-related monitors and verify all values are >= 0.
- **Params:** `{ "monitors": ["memory/static", "memory/static_max"] }`
- **Expected result:** All returned numeric values are >= 0. Not an error.
- **Notes:** Memory cannot be negative; a negative value would indicate a bug.

---

## Tool: `get_editor_performance`

**Description:** Get editor performance snapshot (FPS, timing, memory usage, object counts, render stats, physics activity)

**Parameters:** None (empty schema `{}`).

**Handler:**
```typescript
async () => callGodot(bridge, 'profiling/editor_performance')
```

**Notes:**
- This tool takes absolutely no arguments. The handler signature is `async ()`, meaning even if you pass parameters, they are discarded before reaching `callGodot`.
- Expected return is a JSON object with editor-level performance metrics such as editor FPS, frame timing, object counts, memory, render stats, and physics activity.
- Unlike `get_performance_monitors`, this returns a curated snapshot specific to the editor process rather than raw `Performance` singleton values.

---

### Test Scenarios

#### Scenario 1: Happy path — call with no arguments
- **Description:** Call with an empty object on a connected Godot editor with a project open. Should return an editor performance snapshot.
- **Params:** `{}`
- **Expected result:** JSON object with editor performance data. Expected keys may include editor FPS, object counts, render statistics, and physics activity. Not an error.
- **Notes:** The exact key set is defined by the Godot plugin's `profiling/editor_performance` command handler.

#### Scenario 2: Verify FPS is present and numeric
- **Description:** The returned snapshot should include a frames-per-second metric.
- **Params:** `{}`
- **Expected result:** The response contains an FPS or frame-time field whose value is a positive or zero number. Not NaN, not Infinity.
- **Notes:** Editor FPS may be lower than game FPS since the editor itself consumes resources.

#### Scenario 3: Verify object counts are present
- **Description:** The snapshot should include counts of objects in the current scene.
- **Params:** `{}`
- **Expected result:** The response contains one or more object-count fields (e.g., `object_count`, `node_count`, `resource_count`). Values are non-negative integers.
- **Notes:** Even an empty scene should have object counts (e.g., root node counts as 1).

#### Scenario 4: Verify memory fields are present
- **Description:** The snapshot should include memory usage information.
- **Params:** `{}`
- **Expected result:** The response contains memory-related fields. Values are non-negative numbers (likely in bytes). Not an error.
- **Notes:** Memory usage should be > 0 for a running editor.

#### Scenario 5: Call with extra params — params discarded
- **Description:** Pass arbitrary parameters. Since the handler is `async ()`, all parameters are ignored and not forwarded to Godot.
- **Params:** `{ "monitors": ["time/fps"], "foo": "bar", "baz": 42 }`
- **Expected result:** Same output as Scenario 1. The extra params have no effect — they are discarded by the `async ()` handler.
- **Notes:** This differs from `get_performance_monitors` which uses `(args) =>`. Here, the handler takes zero arguments, so the params object is never read.

#### Scenario 6: Call with `monitors` array — ignored
- **Description:** Pass a `monitors` array, hoping to filter. It should be ignored.
- **Params:** `{ "monitors": ["time/fps"] }`
- **Expected result:** Returns the full editor performance snapshot, NOT a filtered subset. The `monitors` param has no effect on this tool.
- **Notes:** This is a common confusion point — `get_editor_performance` has no filter parameter.

#### Scenario 7: Godot editor not connected
- **Description:** Call when the bridge is disconnected (Godot editor not running).
- **Params:** `{}`
- **Expected result:** Error result with `isError: true`, containing a message like "Godot request failed: ...".
- **Notes:** Covered by the `callGodot` error handler in `server.ts`.

#### Scenario 8: Rapid consecutive calls
- **Description:** Call the tool twice in quick succession to verify no state corruption or memory growth.
- **Params:** `{}` (called twice)
- **Expected result:** Both calls return valid snapshots. The second call's values should be similar but not necessarily identical (FPS may fluctuate). Both should be non-error results.
- **Notes:** Verifies thread safety and idempotency of the read-only profiling endpoint.

#### Scenario 9: Data integrity — all numeric values are finite
- **Description:** After receiving the response, iterate over all values and verify that every numeric field is finite.
- **Params:** `{}`
- **Expected result:** Every value of type `number` in the response satisfies `Number.isFinite(value)`. No NaN, no Infinity.
- **Notes:** A general sanity check on the response data.
