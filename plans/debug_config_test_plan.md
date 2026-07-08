# Test Plan: debug_config.ts — 6 Debug & Logging Tools

> **Source**: `server/src/tools/debug_config.ts`
> **GDScript handler**: `addons/godot_mcp/commands/debug_config_commands.gd`
> **Bridge method prefix**: `debug_config/`

## Overview

This module exposes 6 MCP tools for configuring Godot's debug, profiler, error-handling, and editor-log settings. All tools call through `callGodot(bridge, method, args)` which forwards via WebSocket to the Godot editor plugin.

### Inter-Tool Dependencies

| Tool | Depends On | Reason |
|------|-----------|--------|
| `set_remote_debug` | `get_debug_settings` | Verify current state before mutating |
| `set_profiler_settings` | `get_debug_settings` | Verify defaults before changing limits |
| `set_error_handling` | `get_debug_settings` | Verify current error handling state |
| `get_editor_log` | `clear_editor_log` | For deterministic filter tests, clear log first then generate known entries |
| `clear_editor_log` | (none) | Standalone |

### Recommended Execution Order

1. `get_debug_settings` — baseline read
2. `set_remote_debug` — mutate remote debug
3. `get_debug_settings` — verify remote debug changed
4. `set_profiler_settings` — mutate profiler limits
5. `get_debug_settings` — verify profiler limits changed
6. `set_error_handling` — mutate error handling
7. `get_debug_settings` — verify error handling changed
8. `clear_editor_log` — clear log for clean state
9. `get_editor_log` — read log (should be empty or minimal after clear)

---

## Tool: `get_debug_settings`

**Description**: Get all debug settings (remote debug, profilers, error handling, logging)

**Parameters**: None (`inputSchema: {}`)

**Bridge call**: `debug_config/get_settings`

**Expected return structure**:
```json
{
  "success": true,
  "settings": {
    "remote_debug": { "enabled": bool, "host": string, "port": int },
    "profilers": { "max_functions": int, "max_timestamp_query_elements": int },
    "error_handling": { "break_on_error": bool, "break_on_warning": bool },
    "stdout": { "disable_stdout": bool, "disable_stderr": bool },
    "logging": { "file_logging_enabled": bool, "log_path": string }
  }
}
```

### Test Scenarios

#### 1.1 — Happy path: retrieve all debug settings

- **Description**: Call with no params, verify all 5 setting groups are returned.
- **Params**: `{}`
- **Expected result**: `isError` is absent or `false`. Response contains `success: true` and `settings` object with keys `remote_debug`, `profilers`, `error_handling`, `stdout`, `logging`.
- **Notes**: This is the baseline read — all subsequent mutation tests depend on this working.
- **Attention**: Verify each sub-object has the expected keys. `remote_debug` should have `enabled`, `host`, `port`. `profilers` should have `max_functions`, `max_timestamp_query_elements`.

#### 1.2 — Verify default values on fresh project

- **Description**: On a fresh/default Godot project, check that defaults match expected values.
- **Params**: `{}`
- **Expected result**:
  - `remote_debug.host` = `"127.0.0.1"`, `remote_debug.port` = `6007`
  - `profilers.max_functions` = `16384` (Godot default), `max_timestamp_query_elements` = `256`
  - `logging.file_logging_enabled` = `false` (default)
- **Notes**: Defaults come from Godot's `ProjectSettings` and `EditorSettings`. The GDScript handler uses `.get_setting(key, fallback)` so these should always be populated.
- **Attention**: `remote_debug.enabled` is derived from `host != "127.0.0.1"` — on a fresh project this will be `false` since the default host IS `127.0.0.1`.

---

## Tool: `set_remote_debug`

**Description**: Configure remote debugging connection

**Parameters**:

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `enabled` | `boolean` | **yes** | — | Enable/disable remote debugging |
| `host` | `string` | no | `"127.0.0.1"` | Debug host address |
| `port` | `number` (int) | no | `6007` | Debug port |

**Bridge call**: `debug_config/set_remote_debug`

**Handler logic** (from GDScript):
- If `enabled=true`: sets `network/debug/remote_host` to `host` and `network/debug/remote_port` to `port` in EditorSettings.
- If `enabled=false`: sets host to `""` (empty string), does NOT touch port.
- Returns `{ success, enabled, host, port }`.

### Test Scenarios

#### 2.1 — Happy path: enable remote debug with defaults

- **Description**: Enable remote debug using only the required `enabled` param; host and port should default.
- **Params**: `{ "enabled": true }`
- **Expected result**: `{ "success": true, "enabled": true, "host": "127.0.0.1", "port": 6007 }`
- **Notes**: This sets the editor setting to `127.0.0.1:6007`.
- **Attention**: After this call, `get_debug_settings` should show `remote_debug.host = "127.0.0.1"`. But per the GDScript handler, `enabled` is derived from `host != "127.0.0.1"`, so `get_debug_settings` will report `enabled: false` even though we just "enabled" it with the default host. This is a quirk of the implementation — the `enabled` flag in the response is just an echo of the input, not a persisted state.

#### 2.2 — Enable remote debug with custom host and port

- **Description**: Enable remote debug with a specific host and port.
- **Params**: `{ "enabled": true, "host": "192.168.1.100", "port": 7007 }`
- **Expected result**: `{ "success": true, "enabled": true, "host": "192.168.1.100", "port": 7007 }`
- **Notes**: Verify via `get_debug_settings` that `remote_debug.host = "192.168.1.100"` and `remote_debug.port = 7007`.
- **Attention**: Since host is now `"192.168.1.100"` (not `"127.0.0.1"`), `get_debug_settings` will report `enabled: true`.

#### 2.3 — Disable remote debug

- **Description**: Disable remote debugging.
- **Params**: `{ "enabled": false }`
- **Expected result**: `{ "success": true, "enabled": false, "host": "127.0.0.1", "port": 6007 }`
- **Notes**: The handler sets host to `""` when disabling. The response echoes the input `host`/`port` defaults, but the actual editor setting is cleared.
- **Attention**: Verify via `get_debug_settings` that `remote_debug.host = ""`. The `enabled` derivation (`host != "127.0.0.1"`) will report `true` for empty string, which is another quirk — empty string != `"127.0.0.1"`. This means disabling doesn't cleanly map to the `get_debug_settings` enabled field.

#### 2.4 — Edge case: missing required `enabled` param

- **Description**: Call without the required `enabled` parameter.
- **Params**: `{ "host": "10.0.0.1", "port": 8080 }`
- **Expected result**: MCP-level validation error (Zod schema requires `enabled`). The tool should NOT reach Godot. Expect an error response indicating `enabled` is required.
- **Notes**: This tests MCP input validation, not the GDScript handler.
- **Attention**: The schema defines `enabled` as `z.boolean()` with no `.optional()`, so Zod should reject the call.

#### 2.5 — Edge case: invalid port type (string instead of int)

- **Description**: Pass a string value for `port`.
- **Params**: `{ "enabled": true, "port": "not_a_number" }`
- **Expected result**: MCP-level validation error. `port` is defined as `z.number().int()`, so a string should be rejected.
- **Notes**: Tests Zod coercion boundaries.
- **Attention**: Some Zod configs have `.coerce()` — verify this schema does NOT coerce.

#### 2.6 — Edge case: negative port number

- **Description**: Pass a negative port.
- **Params**: `{ "enabled": true, "port": -1 }`
- **Expected result**: The Zod schema allows it (no `.min()` constraint). The GDScript handler will accept it. The call will succeed at MCP level but the editor setting will be invalid.
- **Notes**: This is a potential improvement area — the schema lacks `.min(0)` or `.min(1)`.
- **Attention**: Document this as a gap: port should likely have `z.number().int().min(1).max(65535)`.

---

## Tool: `set_profiler_settings`

**Description**: Configure profiler limits. Note: profiler on/off toggles (CPU, GPU, etc.) are controlled by the editor debugger panel during gameplay and cannot be set via ProjectSettings.

**Parameters**:

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `max_functions` | `number` (int) | no | — | Max functions tracked by script profiler (range: 16-512) |
| `max_timestamp_query_elements` | `number` (int) | no | — | Max timestamp query elements (default: 256) |

**Bridge call**: `debug_config/set_profilers`

**Handler logic** (from GDScript):
- If `max_functions` is present: sets `debug/settings/profiler/max_functions` in ProjectSettings.
- If `max_timestamp_query_elements` is present: sets `debug/settings/profiler/max_timestamp_query_elements` in ProjectSettings.
- If neither is present AND no UI toggle keys (`cpu`, `gpu`, `memory`, `network`) are in params: returns error `"No profiler settings provided"`.
- If UI toggle keys are present: adds warnings that those are editor-only.
- Saves ProjectSettings if any setting was changed.
- Returns `{ success, changed, warnings }`.

### Test Scenarios

#### 3.1 — Happy path: set max_functions only

- **Description**: Set only `max_functions`.
- **Params**: `{ "max_functions": 256 }`
- **Expected result**: `{ "success": true, "changed": { "max_functions": 256 }, "warnings": [] }`
- **Notes**: Verify via `get_debug_settings` that `profilers.max_functions = 256`.
- **Attention**: The Zod schema description says "range: 16-512" but there's no `.min(16).max(512)` constraint in the schema. The GDScript handler also doesn't validate the range — it just casts to int and sets. So values outside 16-512 will be accepted.

#### 3.2 — Happy path: set both profiler limits

- **Description**: Set both `max_functions` and `max_timestamp_query_elements`.
- **Params**: `{ "max_functions": 512, "max_timestamp_query_elements": 1024 }`
- **Expected result**: `{ "success": true, "changed": { "max_functions": 512, "max_timestamp_query_elements": 1024 }, "warnings": [] }`
- **Notes**: Verify both values via `get_debug_settings`.
- **Attention**: Both values should be persisted in ProjectSettings.

#### 3.3 — Happy path: set max_timestamp_query_elements only

- **Description**: Set only `max_timestamp_query_elements`.
- **Params**: `{ "max_timestamp_query_elements": 128 }`
- **Expected result**: `{ "success": true, "changed": { "max_timestamp_query_elements": 128 }, "warnings": [] }`
- **Notes**: Verifies that each param works independently.

#### 3.4 — Edge case: no params at all

- **Description**: Call with empty object — no profiler settings provided.
- **Params**: `{}`
- **Expected result**: `{ "success": false, "error": "No profiler settings provided. Configurable: max_functions, max_timestamp_query_elements" }`
- **Notes**: The GDScript handler explicitly returns this error when `changed` and `warnings` are both empty.
- **Attention**: This is the only tool in this module that can return `success: false` with an error message for valid MCP input (i.e., the schema allows empty params but the handler rejects them).

#### 3.5 — Edge case: pass UI toggle keys (cpu, gpu)

- **Description**: Pass UI-only toggle keys that are not in the MCP schema but might be sent as extra params.
- **Params**: `{ "cpu": true, "gpu": true }`
- **Expected result**: MCP-level validation error — Zod strict mode should reject unknown keys. If the schema allows passthrough, the GDScript handler would return `{ "success": true, "changed": {}, "warnings": ["cpu profiler toggle is controlled by the editor debugger panel, not ProjectSettings", ...] }`.
- **Notes**: Test whether the MCP schema enforces strict key matching.
- **Attention**: The Zod schema only defines `max_functions` and `max_timestamp_query_elements`. Depending on whether `strict()` mode is used, extra keys may be stripped or rejected.

#### 3.6 — Edge case: max_functions as float

- **Description**: Pass a non-integer number for `max_functions`.
- **Params**: `{ "max_functions": 256.7 }`
- **Expected result**: MCP-level validation error. `max_functions` is `z.number().int()`, so a float should be rejected by Zod.
- **Notes**: Tests integer constraint enforcement.

---

## Tool: `set_error_handling`

**Description**: Configure how the editor handles errors and warnings during gameplay

**Parameters**:

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `break_on_error` | `boolean` | no | — | Break into debugger on error |
| `break_on_warning` | `boolean` | no | — | Break into debugger on warning |

**Bridge call**: `debug_config/set_error_handling`

**Handler logic** (from GDScript):
- If `break_on_error` is present: sets `debug/gdscript/warnings/enable` in ProjectSettings.
- If `break_on_warning` is present: records it in `changed` with a note `"Break on warning is controlled by the editor debugger"` — does NOT persist it.
- If neither is present: returns error `"No error handling settings provided"`.
- Saves ProjectSettings if any setting was changed.
- Returns `{ success, changed }`.

### Test Scenarios

#### 4.1 — Happy path: enable break_on_error

- **Description**: Set `break_on_error` to `true`.
- **Params**: `{ "break_on_error": true }`
- **Expected result**: `{ "success": true, "changed": { "break_on_error": true } }`
- **Notes**: Verify via `get_debug_settings` that `error_handling.break_on_error` reflects the change.
- **Attention**: The GDScript handler maps `break_on_error` to `debug/gdscript/warnings/enable` in ProjectSettings — the setting name is misleading (it's about GDScript warnings, not errors). The `get_debug_settings` handler reads this same key for `break_on_error`.

#### 4.2 — Happy path: disable break_on_error

- **Description**: Set `break_on_error` to `false`.
- **Params**: `{ "break_on_error": false }`
- **Expected result**: `{ "success": true, "changed": { "break_on_error": false } }`
- **Notes**: Verifies toggle works in both directions.

#### 4.3 — Happy path: set break_on_warning

- **Description**: Set `break_on_warning` — this is a no-op at the ProjectSettings level.
- **Params**: `{ "break_on_warning": true }`
- **Expected result**: `{ "success": true, "changed": { "break_on_warning": true, "note": "Break on warning is controlled by the editor debugger" } }`
- **Notes**: The handler records the value but does NOT persist it. The `note` field indicates this.
- **Attention**: This is effectively a no-op — the value is echoed back but not saved. Verify that `get_debug_settings` does NOT reflect this change (the handler hardcodes `break_on_warning: false`).

#### 4.4 — Happy path: set both flags together

- **Description**: Set both `break_on_error` and `break_on_warning`.
- **Params**: `{ "break_on_error": true, "break_on_warning": true }`
- **Expected result**: `{ "success": true, "changed": { "break_on_error": true, "break_on_warning": true, "note": "Break on warning is controlled by the editor debugger" } }`
- **Notes**: Only `break_on_error` is actually persisted.

#### 4.5 — Edge case: no params

- **Description**: Call with empty object.
- **Params**: `{}`
- **Expected result**: `{ "success": false, "error": "No error handling settings provided" }`
- **Notes**: Same pattern as `set_profiler_settings` — empty params are valid MCP input but rejected by the handler.

#### 4.6 — Edge case: invalid type for break_on_error (string instead of bool)

- **Description**: Pass a string for `break_on_error`.
- **Params**: `{ "break_on_error": "yes" }`
- **Expected result**: MCP-level validation error. `break_on_error` is `z.boolean()`, so a string should be rejected.
- **Notes**: Tests Zod boolean coercion boundaries.

---

## Tool: `get_editor_log`

**Description**: Get entries from the editor log, optionally filtered by type

**Parameters**:

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `filter` | `enum('error', 'warning', 'info')` | no | — | Filter by message type |
| `limit` | `number` (int, min 1, max 500) | no | `50` | Max entries to return |

**Bridge call**: `debug_config/get_log`

**Handler logic** (from GDScript):
- Reads the log file at `debug/file_logging/log_path` (default `user://logs/godot.log`).
- Processes lines from end (most recent first), up to `limit` entries.
- Classifies each line: contains `"ERROR"` or `"error"` → `error`, contains `"WARNING"` or `"warning"` → `warning`, else → `info`.
- If `filter` is set, skips entries that don't match the filter type.
- Returns `{ success, entries: [{ type, message }], count, log_path }`.

### Test Scenarios

#### 5.1 — Happy path: get log with default params

- **Description**: Call with no params — should return up to 50 entries.
- **Params**: `{}`
- **Expected result**: `{ "success": true, "entries": [...], "count": <int>, "log_path": "<path>" }`
- **Notes**: `count` should be ≤ 50. `entries` array items should each have `type` and `message`.
- **Attention**: If the log file doesn't exist or is empty, `entries` will be `[]` and `count` will be `0`. This is a valid result, not an error.

#### 5.2 — Happy path: filter by error type

- **Description**: Get only error entries.
- **Params**: `{ "filter": "error" }`
- **Expected result**: `{ "success": true, "entries": [...], "count": <int>, "log_path": "<path>" }`. Every entry in `entries` should have `type: "error"`.
- **Notes**: If no error entries exist, `entries` will be `[]`.
- **Attention**: The classification is string-based (`line.find("ERROR")` or `line.find("error")`). Lines containing the substring "error" anywhere (e.g., in a script path) will be classified as errors.

#### 5.3 — Happy path: filter by warning type

- **Description**: Get only warning entries.
- **Params**: `{ "filter": "warning" }`
- **Expected result**: All entries have `type: "warning"`.

#### 5.4 — Happy path: filter by info type

- **Description**: Get only info entries.
- **Params**: `{ "filter": "info" }`
- **Expected result**: All entries have `type: "info"`.

#### 5.5 — Happy path: custom limit

- **Description**: Request only 5 entries.
- **Params**: `{ "limit": 5 }`
- **Expected result**: `count` ≤ 5, `entries` length ≤ 5.

#### 5.6 — Happy path: filter + limit combined

- **Description**: Filter by error, limit to 3.
- **Params**: `{ "filter": "error", "limit": 3 }`
- **Expected result**: `count` ≤ 3, all entries have `type: "error"`.

#### 5.7 — Edge case: limit at minimum (1)

- **Description**: Request exactly 1 entry.
- **Params**: `{ "limit": 1 }`
- **Expected result**: `count` ≤ 1.

#### 5.8 — Edge case: limit at maximum (500)

- **Description**: Request up to 500 entries.
- **Params**: `{ "limit": 500 }`
- **Expected result**: `count` ≤ 500.

#### 5.9 — Edge case: limit below minimum (0)

- **Description**: Pass `limit: 0` which is below the schema minimum of 1.
- **Params**: `{ "limit": 0 }`
- **Expected result**: MCP-level validation error. `limit` is `z.number().int().min(1).max(500)`.
- **Notes**: Tests min boundary.

#### 5.10 — Edge case: limit above maximum (501)

- **Description**: Pass `limit: 501` which exceeds the schema maximum of 500.
- **Params**: `{ "limit": 501 }`
- **Expected result**: MCP-level validation error.
- **Notes**: Tests max boundary.

#### 5.11 — Edge case: invalid filter enum value

- **Description**: Pass an invalid filter value.
- **Params**: `{ "filter": "critical" }`
- **Expected result**: MCP-level validation error. `filter` is `z.enum(['error', 'warning', 'info'])`.
- **Notes**: Tests enum constraint.

#### 5.12 — Edge case: limit as float

- **Description**: Pass a non-integer limit.
- **Params**: `{ "limit": 10.5 }`
- **Expected result**: MCP-level validation error. `limit` is `z.number().int()`.
- **Notes**: Tests integer constraint.

---

## Tool: `clear_editor_log`

**Description**: Clear the editor output log

**Parameters**: None (`inputSchema: {}`)

**Bridge call**: `debug_config/clear_log`

**Handler logic** (from GDScript):
- Tries to find the `EditorLog` node in the editor UI and call `.clear()` on it.
- Fallback: if a log file path is configured and exists, truncates it to empty.
- Final fallback: returns success with message `"Log clear requested"`.
- Returns `{ success: true, message: string }`.

### Test Scenarios

#### 6.1 — Happy path: clear the log

- **Description**: Call with no params to clear the editor log.
- **Params**: `{}`
- **Expected result**: `{ "success": true, "message": "Editor log cleared" }` (or `"Log file cleared"` or `"Log clear requested"` depending on which path the handler takes).
- **Notes**: The exact `message` value depends on the editor state. All three are valid.
- **Attention**: Verify that after clearing, `get_editor_log` returns `count: 0` (or very few entries if the editor immediately writes new log lines).

#### 6.2 — Verification: log is empty after clear

- **Description**: Clear the log, then immediately read it back.
- **Precondition**: Call `clear_editor_log` first.
- **Params**: `{}`
- **Expected result**: `get_editor_log` returns `count: 0` or very small count (editor may write startup messages).
- **Notes**: This is a cross-tool verification scenario.
- **Attention**: There may be a race condition — the editor might write log lines between the clear and the read. Allow `count ≤ 2` as acceptable.

#### 6.3 — Idempotency: clear twice

- **Description**: Call `clear_editor_log` twice in succession.
- **Params**: `{}` (both calls)
- **Expected result**: Both calls return `success: true`. Second call should not error.
- **Notes**: Verifies idempotency — clearing an already-empty log should not fail.

---

## Cross-Tool Workflow Scenarios

### W1 — Full settings audit workflow

**Steps**:
1. `get_debug_settings` → record baseline
2. `set_remote_debug` with `{ "enabled": true, "host": "192.168.1.50", "port": 9999 }`
3. `set_profiler_settings` with `{ "max_functions": 100, "max_timestamp_query_elements": 500 }`
4. `set_error_handling` with `{ "break_on_error": false }`
5. `get_debug_settings` → verify all changes reflected:
   - `remote_debug.host` = `"192.168.1.50"`, `remote_debug.port` = `9999`
   - `profilers.max_functions` = `100`, `max_timestamp_query_elements` = `500`
   - `error_handling.break_on_error` = `false`

**Expected**: All mutations are reflected in the final read.

### W2 — Log clear + read workflow

**Steps**:
1. `clear_editor_log`
2. `get_editor_log` with `{ "limit": 10 }`
3. Verify `count` is 0 or very small

**Expected**: Log is empty or near-empty after clear.

### W3 — Restore defaults after tests

**Steps**:
1. `set_remote_debug` with `{ "enabled": false }`
2. `set_profiler_settings` with `{ "max_functions": 16384, "max_timestamp_query_elements": 256 }`
3. `set_error_handling` with `{ "break_on_error": true }`
4. `get_debug_settings` → verify defaults restored

**Expected**: Settings return to Godot defaults. This should be run as cleanup after the test suite.

---

## Schema Validation Summary

| Tool | Required Params | Optional Params | Enum Constraints | Numeric Constraints |
|------|----------------|-----------------|-----------------|-------------------|
| `get_debug_settings` | — | — | — | — |
| `set_remote_debug` | `enabled` (bool) | `host` (string), `port` (int) | — | port: no min/max in schema |
| `set_profiler_settings` | — | `max_functions` (int), `max_timestamp_query_elements` (int) | — | No range validation in schema (docs say 16-512 for max_functions) |
| `set_error_handling` | — | `break_on_error` (bool), `break_on_warning` (bool) | — | — |
| `get_editor_log` | — | `filter` (enum), `limit` (int) | `filter`: error, warning, info | `limit`: min 1, max 500 |
| `clear_editor_log` | — | — | — | — |

### Known Schema Gaps

1. **`set_remote_debug.port`**: No `.min(1).max(65535)` — negative and out-of-range ports are accepted.
2. **`set_profiler_settings.max_functions`**: Description says "range: 16-512" but schema has no `.min(16).max(512)` enforcement.
3. **`set_profiler_settings.max_timestamp_query_elements`**: No range validation at all.
