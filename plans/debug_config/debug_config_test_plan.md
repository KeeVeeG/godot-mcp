# Debug Configuration Tools — Test Plan

**Source file:** `server/src/tools/debug_config.ts`
**Generated:** 2026-07-08

---

## Shared Types Used

| Import | Type | Notes |
|--------|------|-------|
| `z` | Zod namespace | Re-exported from `shared-types.ts`. No named schema imports — all schemas are defined inline. |

All 6 tools call `callGodot(bridge, '<endpoint>', args)` which delegates to the Godot editor plugin via WebSocket. Tools return `ToolResult` (JSON stringified content). Error responses have `isError: true`.

---

## Tool: `get_debug_settings`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| *(none)* | — | — | No input parameters |

### Handler

Calls `callGodot(bridge, 'debug_config/get_settings')` — no args forwarded.

### Test Scenarios

#### Scenario 1: Basic happy path — read current debug settings
- **Description:** Call with no arguments; expect the current remote debug, profiler, and error handling settings returned as JSON.
- **Params:** `{}`
- **Expected result:** Success. Returns a JSON object containing keys related to remote debugging (enabled, host, port), profiler settings (max_functions, max_timestamp_query_elements), and error handling (break_on_error, break_on_warning).
- **Notes:** Read-only tool; verify it does not mutate any settings.

#### Scenario 2: Call with empty input object
- **Description:** Invoke with an explicit empty object `{}`.
- **Params:** `{}`
- **Expected result:** Success (same as Scenario 1). No required params; empty inputSchema means any input is ignored.

#### Scenario 3: Call with irrelevant extra keys
- **Description:** Pass an object with extra keys that are not in the schema.
- **Params:**
  ```json
  {
    "foo": "bar",
    "baz": 123
  }
  ```
- **Expected result:** Success. Extra keys are silently ignored by Zod (or stripped) since `inputSchema` is `{}`.

---

## Tool: `set_remote_debug`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `enabled` | `boolean` | **Yes** | Enable/disable remote debugging |
| `host` | `string` | No | Debug host address (default: `'127.0.0.1'`) |
| `port` | `number` (integer) | No | Debug port (default: `6007`) |

### Handler

Calls `callGodot(bridge, 'debug_config/set_remote_debug', args)`.

### Test Scenarios

#### Scenario 1: Happy path — enable with defaults
- **Description:** Enable remote debugging using only the required `enabled` param; host and port default to `127.0.0.1` and `6007`.
- **Params:**
  ```json
  {
    "enabled": true
  }
  ```
- **Expected result:** Success. Remote debugging enabled on default host/port. Verify via `get_debug_settings` that enabled=true, host='127.0.0.1', port=6007.

#### Scenario 2: Happy path — enable with custom host and port
- **Description:** Enable remote debugging with an explicit host and non-default port.
- **Params:**
  ```json
  {
    "enabled": true,
    "host": "192.168.1.100",
    "port": 9000
  }
  ```
- **Expected result:** Success. Remote debugging enabled on host='192.168.1.100', port=9000. Verify via `get_debug_settings`.

#### Scenario 3: Happy path — enable with custom host, default port
- **Description:** Enable with a custom host, omit port (should default to 6007).
- **Params:**
  ```json
  {
    "enabled": true,
    "host": "0.0.0.0"
  }
  ```
- **Expected result:** Success. Remote debugging enabled on host='0.0.0.0', port=6007 (default). Verify via `get_debug_settings`.

#### Scenario 4: Happy path — enable with custom port, default host
- **Description:** Enable with a custom port, omit host (should default to '127.0.0.1').
- **Params:**
  ```json
  {
    "enabled": true,
    "port": 9001
  }
  ```
- **Expected result:** Success. Remote debugging enabled on host='127.0.0.1', port=9001.

#### Scenario 5: Happy path — disable remote debugging
- **Description:** Disable remote debugging with `enabled: false`. Host and port might be ignored or stored for later.
- **Params:**
  ```json
  {
    "enabled": false
  }
  ```
- **Expected result:** Success. Remote debugging disabled. Verify via `get_debug_settings` that enabled=false.

#### Scenario 6: Happy path — disable with host/port still specified
- **Description:** Disable remote debugging but still provide host/port values.
- **Params:**
  ```json
  {
    "enabled": false,
    "host": "10.0.0.1",
    "port": 8080
  }
  ```
- **Expected result:** Success. Remote debugging disabled; host/port values may be stored but ignored while disabled. Document actual behavior.

#### Scenario 7: Happy path — localhost (IPv6)
- **Description:** Use the IPv6 loopback address `::1` as the host.
- **Params:**
  ```json
  {
    "enabled": true,
    "host": "::1"
  }
  ```
- **Expected result:** Success. Remote debugging on `::1`. Verify via `get_debug_settings`.
- **Notes:** Depends on Godot's networking support for IPv6.

#### Scenario 8: Happy path — hostname (FQDN)
- **Description:** Use a fully qualified domain name as the host.
- **Params:**
  ```json
  {
    "enabled": true,
    "host": "debug.example.com"
  }
  ```
- **Expected result:** Success. Host stored as string. No DNS resolution needed at configuration time.

#### Scenario 9: Happy path — non-default port range boundary (low)
- **Description:** Use the lowest possible port number (1).
- **Params:**
  ```json
  {
    "enabled": true,
    "port": 1
  }
  ```
- **Expected result:** May succeed or fail depending on OS. Ports below 1024 are privileged on most systems. Document actual behavior.

#### Scenario 10: Happy path — non-default port range boundary (high)
- **Description:** Use the highest valid port number (65535).
- **Params:**
  ```json
  {
    "enabled": true,
    "port": 65535
  }
  ```
- **Expected result:** Success. Port set to 65535. Verify via `get_debug_settings`.

#### Scenario 11: Edge case — missing required `enabled`
- **Description:** Call without the `enabled` parameter.
- **Params:** `{}`
- **Expected result:** Error (Zod validation failure). `enabled` is required (not `.optional()`).

#### Scenario 12: Edge case — `enabled` as non-boolean string
- **Description:** Pass `enabled` as a string `"true"`.
- **Params:**
  ```json
  {
    "enabled": "true"
  }
  ```
- **Expected result:** Error (Zod validation failure). `z.boolean()` rejects strings.

#### Scenario 13: Edge case — `enabled` as number
- **Description:** Pass `enabled` as a number (1).
- **Params:**
  ```json
  {
    "enabled": 1
  }
  ```
- **Expected result:** Error (Zod validation failure). `z.boolean()` rejects numbers.

#### Scenario 14: Edge case — `host` as number
- **Description:** Pass `host` as a number instead of a string.
- **Params:**
  ```json
  {
    "enabled": true,
    "host": 12345
  }
  ```
- **Expected result:** Error (Zod validation failure). `z.string()` rejects numbers.

#### Scenario 15: Edge case — `host` as empty string
- **Description:** Pass an empty string for `host`.
- **Params:**
  ```json
  {
    "enabled": true,
    "host": ""
  }
  ```
- **Expected result:** May succeed or fail. Godot might reject an empty host. Document actual behavior.

#### Scenario 16: Edge case — `port` as float
- **Description:** Pass `port` as a non-integer number.
- **Params:**
  ```json
  {
    "enabled": true,
    "port": 6007.5
  }
  ```
- **Expected result:** Error (Zod validation failure). `.int()` rejects floats.

#### Scenario 17: Edge case — `port` as string
- **Description:** Pass `port` as a string `"6007"`.
- **Params:**
  ```json
  {
    "enabled": true,
    "port": "6007"
  }
  ```
- **Expected result:** Error (Zod validation failure). `z.number()` rejects strings.

#### Scenario 18: Edge case — `port` as negative number
- **Description:** Pass a negative port number.
- **Params:**
  ```json
  {
    "enabled": true,
    "port": -1
  }
  ```
- **Expected result:** Zod passes this (no `.min(0)` in schema), but Godot should reject it. Document actual behavior — either Zod-level failure or Godot-level error.

#### Scenario 19: Edge case — `port` as zero
- **Description:** Pass port 0.
- **Params:**
  ```json
  {
    "enabled": true,
    "port": 0
  }
  ```
- **Expected result:** Zod passes this (no `.min(1)`), but Godot likely rejects port 0. Document actual behavior.

#### Scenario 20: Edge case — `port` exceeds max (65536)
- **Description:** Pass port 65536 (one above maximum valid TCP port).
- **Params:**
  ```json
  {
    "enabled": true,
    "port": 65536
  }
  ```
- **Expected result:** Zod passes this (no `.max(65535)` in schema), but Godot should reject it. Document actual behavior.

#### Scenario 21: Edge case — huge `port` value
- **Description:** Pass an extremely large port number.
- **Params:**
  ```json
  {
    "enabled": true,
    "port": 999999
  }
  ```
- **Expected result:** Zod passes this, Godot rejects. Document actual behavior.

---

## Tool: `set_profiler_settings`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `max_functions` | `number` (integer) | No | Max functions tracked by script profiler (range: 16-512) |
| `max_timestamp_query_elements` | `number` (integer) | No | Max timestamp query elements (default: 256) |

### Handler

Calls `callGodot(bridge, 'debug_config/set_profilers', args)`.

### Test Scenarios

#### Scenario 1: Happy path — set max_functions only
- **Description:** Set only `max_functions` to a valid value within the documented range.
- **Params:**
  ```json
  {
    "max_functions": 256
  }
  ```
- **Expected result:** Success. max_functions set to 256. Verify via `get_debug_settings`.

#### Scenario 2: Happy path — set max_timestamp_query_elements only
- **Description:** Set only `max_timestamp_query_elements`.
- **Params:**
  ```json
  {
    "max_timestamp_query_elements": 512
  }
  ```
- **Expected result:** Success. max_timestamp_query_elements set to 512. Verify via `get_debug_settings`.

#### Scenario 3: Happy path — set both fields
- **Description:** Set both `max_functions` and `max_timestamp_query_elements` simultaneously.
- **Params:**
  ```json
  {
    "max_functions": 128,
    "max_timestamp_query_elements": 256
  }
  ```
- **Expected result:** Success. Both values updated. Verify via `get_debug_settings`.

#### Scenario 4: Happy path — max_functions at documented minimum (16)
- **Description:** Set `max_functions` to 16 (documented minimum).
- **Params:**
  ```json
  {
    "max_functions": 16
  }
  ```
- **Expected result:** Success. max_functions set to 16. Verify via `get_debug_settings`.
- **Notes:** The schema has no `.min(16)` constraint — validation of the range is left to Godot. Document whether Zod passes this and Godot accepts it.

#### Scenario 5: Happy path — max_functions at documented maximum (512)
- **Description:** Set `max_functions` to 512 (documented maximum).
- **Params:**
  ```json
  {
    "max_functions": 512
  }
  ```
- **Expected result:** Success. max_functions set to 512.

#### Scenario 6: Happy path — call with no parameters at all (empty)
- **Description:** Call with an empty object. Both params are optional.
- **Params:** `{}`
- **Expected result:** Success (no-op). The call forwards to Godot with an empty args object; Godot should leave settings unchanged.
- **Notes:** This is a legitimate call — the user may intend to query defaults or trigger a no-op refresh.

#### Scenario 7: Edge case — max_functions below documented minimum
- **Description:** Set `max_functions` to 0 (below documented minimum of 16).
- **Params:**
  ```json
  {
    "max_functions": 0
  }
  ```
- **Expected result:** Zod passes this (no `.min()`), but Godot should clamp or reject. Document actual behavior.

#### Scenario 8: Edge case — max_functions above documented maximum
- **Description:** Set `max_functions` to 1024 (above documented maximum of 512).
- **Params:**
  ```json
  {
    "max_functions": 1024
  }
  ```
- **Expected result:** Zod passes, Godot may clamp to 512 or reject. Document actual behavior.

#### Scenario 9: Edge case — max_functions is negative
- **Description:** Set `max_functions` to a negative number.
- **Params:**
  ```json
  {
    "max_functions": -1
  }
  ```
- **Expected result:** Zod passes (no `.positive()`), Godot should reject. Document actual behavior.

#### Scenario 10: Edge case — max_functions as float
- **Description:** Set `max_functions` to a non-integer value.
- **Params:**
  ```json
  {
    "max_functions": 128.5
  }
  ```
- **Expected result:** Error (Zod validation failure). `.int()` rejects floats.

#### Scenario 11: Edge case — max_timestamp_query_elements as float
- **Description:** Set `max_timestamp_query_elements` to a non-integer value.
- **Params:**
  ```json
  {
    "max_timestamp_query_elements": 256.7
  }
  ```
- **Expected result:** Error (Zod validation failure). `.int()` rejects floats.

#### Scenario 12: Edge case — max_functions as string
- **Description:** Pass `max_functions` as a string.
- **Params:**
  ```json
  {
    "max_functions": "128"
  }
  ```
- **Expected result:** Error (Zod validation failure). `z.number()` rejects strings.

#### Scenario 13: Edge case — max_timestamp_query_elements as string
- **Description:** Pass `max_timestamp_query_elements` as a string.
- **Params:**
  ```json
  {
    "max_timestamp_query_elements": "256"
  }
  ```
- **Expected result:** Error (Zod validation failure).

#### Scenario 14: Edge case — max_timestamp_query_elements is zero
- **Description:** Set `max_timestamp_query_elements` to 0.
- **Params:**
  ```json
  {
    "max_timestamp_query_elements": 0
  }
  ```
- **Expected result:** Zod passes (no `.positive()`), but Godot likely rejects or clamps. Document actual behavior.

#### Scenario 15: Edge case — max_timestamp_query_elements is negative
- **Description:** Set `max_timestamp_query_elements` to -1.
- **Params:**
  ```json
  {
    "max_timestamp_query_elements": -1
  }
  ```
- **Expected result:** Zod passes, Godot should reject. Document actual behavior.

#### Scenario 16: Edge case — very large value for max_timestamp_query_elements
- **Description:** Pass an extremely large value (e.g., 999999).
- **Params:**
  ```json
  {
    "max_timestamp_query_elements": 999999
  }
  ```
- **Expected result:** Zod passes, Godot may clamp or reject. Document actual behavior.

#### Scenario 17: Edge case — irrelevant extra keys
- **Description:** Pass extra keys not defined in the schema.
- **Params:**
  ```json
  {
    "max_functions": 256,
    "cpu_profiler_enabled": true,
    "gpu_profiler_enabled": true
  }
  ```
- **Expected result:** Success. Extra keys are silently stripped; only recognized params are forwarded.
- **Notes:** This is important — the tool's description warns that "profiler on/off toggles (CPU, GPU, etc.) are controlled by the editor debugger panel during gameplay and cannot be set via ProjectSettings." Extra keys like `cpu_profiler_enabled` should be silently ignored rather than causing an error.

---

## Tool: `set_error_handling`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `break_on_error` | `boolean` | No | Break into debugger on error |
| `break_on_warning` | `boolean` | No | Break into debugger on warning |

### Handler

Calls `callGodot(bridge, 'debug_config/set_error_handling', args)`.

### Test Scenarios

#### Scenario 1: Happy path — set break_on_error only (true)
- **Description:** Enable breaking into debugger on errors.
- **Params:**
  ```json
  {
    "break_on_error": true
  }
  ```
- **Expected result:** Success. break_on_error set to true. Verify via `get_debug_settings`.

#### Scenario 2: Happy path — set break_on_error only (false)
- **Description:** Disable breaking into debugger on errors.
- **Params:**
  ```json
  {
    "break_on_error": false
  }
  ```
- **Expected result:** Success. break_on_error set to false.

#### Scenario 3: Happy path — set break_on_warning only (true)
- **Description:** Enable breaking into debugger on warnings.
- **Params:**
  ```json
  {
    "break_on_warning": true
  }
  ```
- **Expected result:** Success. break_on_warning set to true. Verify via `get_debug_settings`.

#### Scenario 4: Happy path — set break_on_warning only (false)
- **Description:** Disable breaking into debugger on warnings.
- **Params:**
  ```json
  {
    "break_on_warning": false
  }
  ```
- **Expected result:** Success. break_on_warning set to false.

#### Scenario 5: Happy path — set both flags simultaneously (both true)
- **Description:** Enable both error and warning breakpoints at the same time.
- **Params:**
  ```json
  {
    "break_on_error": true,
    "break_on_warning": true
  }
  ```
- **Expected result:** Success. Both flags set to true. Verify via `get_debug_settings`.

#### Scenario 6: Happy path — set both flags simultaneously (both false)
- **Description:** Disable both error and warning breakpoints.
- **Params:**
  ```json
  {
    "break_on_error": false,
    "break_on_warning": false
  }
  ```
- **Expected result:** Success. Both flags set to false.

#### Scenario 7: Happy path — set both flags with mixed values (error true, warning false)
- **Description:** Enable error breakpoints but disable warning breakpoints.
- **Params:**
  ```json
  {
    "break_on_error": true,
    "break_on_warning": false
  }
  ```
- **Expected result:** Success. break_on_error=true, break_on_warning=false.

#### Scenario 8: Happy path — call with no parameters at all (empty)
- **Description:** Call with an empty object. Both params are optional.
- **Params:** `{}`
- **Expected result:** Success (no-op). The call forwards to Godot; existing settings remain unchanged. Verify via `get_debug_settings`.

#### Scenario 9: Edge case — break_on_error as string "true"
- **Description:** Pass `break_on_error` as a string.
- **Params:**
  ```json
  {
    "break_on_error": "true"
  }
  ```
- **Expected result:** Error (Zod validation failure). `z.boolean()` rejects strings.

#### Scenario 10: Edge case — break_on_error as number 1
- **Description:** Pass `break_on_error` as the number 1.
- **Params:**
  ```json
  {
    "break_on_error": 1
  }
  ```
- **Expected result:** Error (Zod validation failure). `z.boolean()` rejects numbers.

#### Scenario 11: Edge case — break_on_warning as string "false"
- **Description:** Pass `break_on_warning` as a string.
- **Params:**
  ```json
  {
    "break_on_warning": "false"
  }
  ```
- **Expected result:** Error (Zod validation failure).

#### Scenario 12: Edge case — break_on_warning as number 0
- **Description:** Pass `break_on_warning` as the number 0.
- **Params:**
  ```json
  {
    "break_on_warning": 0
  }
  ```
- **Expected result:** Error (Zod validation failure).

#### Scenario 13: Edge case — irrelevant extra keys
- **Description:** Pass extra keys not in the schema.
- **Params:**
  ```json
  {
    "break_on_error": true,
    "editor_pause_on_error": true,
    "log_level": "verbose"
  }
  ```
- **Expected result:** Success. Extra keys silently stripped; only `break_on_error` is forwarded.

---

## Tool: `get_editor_log`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `filter` | `enum('error', 'warning', 'info')` | No | Filter by message type |
| `limit` | `number` (integer, 1–500) | No | Max entries to return (default: 50) |

### Handler

Calls `callGodot(bridge, 'debug_config/get_log', args)`.

### Test Scenarios

#### Scenario 1: Happy path — get log with no filter (default limit)
- **Description:** Retrieve the most recent 50 log entries without any filter.
- **Params:** `{}`
- **Expected result:** Success. Returns an array of log entries (up to 50). Each entry includes timestamp, type, and message text. Types may include 'error', 'warning', 'info', and possibly 'log' (unfiltered).

#### Scenario 2: Happy path — filter=error
- **Description:** Retrieve only error-level log entries.
- **Params:**
  ```json
  {
    "filter": "error"
  }
  ```
- **Expected result:** Success. Returns up to 50 entries, all of type 'error'.

#### Scenario 3: Happy path — filter=warning
- **Description:** Retrieve only warning-level log entries.
- **Params:**
  ```json
  {
    "filter": "warning"
  }
  ```
- **Expected result:** Success. Returns up to 50 entries, all of type 'warning'.

#### Scenario 4: Happy path — filter=info
- **Description:** Retrieve only info-level log entries.
- **Params:**
  ```json
  {
    "filter": "info"
  }
  ```
- **Expected result:** Success. Returns up to 50 entries, all of type 'info'.

#### Scenario 5: Happy path — custom limit (small)
- **Description:** Retrieve exactly 10 log entries.
- **Params:**
  ```json
  {
    "limit": 10
  }
  ```
- **Expected result:** Success. Returns at most 10 log entries.

#### Scenario 6: Happy path — custom limit (large)
- **Description:** Retrieve exactly 500 log entries (maximum).
- **Params:**
  ```json
  {
    "limit": 500
  }
  ```
- **Expected result:** Success. Returns at most 500 log entries.

#### Scenario 7: Happy path — filter + custom limit combined
- **Description:** Retrieve 5 error log entries.
- **Params:**
  ```json
  {
    "filter": "error",
    "limit": 5
  }
  ```
- **Expected result:** Success. Returns at most 5 entries, all of type 'error'.

#### Scenario 8: Happy path — limit=1 (minimum bound)
- **Description:** Retrieve exactly 1 log entry.
- **Params:**
  ```json
  {
    "limit": 1
  }
  ```
- **Expected result:** Success. Returns at most 1 log entry. Verify the entry count reflects the actual log state.

#### Scenario 9: Edge case — empty log (no entries)
- **Description:** Retrieve log after clearing it (call `clear_editor_log` first, then immediately call `get_editor_log`).
- **Params:** `{}`
- **Expected result:** Success. Returns an empty array `[]` or a result indicating no entries.
- **Notes:** Prerequisite: call `clear_editor_log` first, then wait briefly before calling `get_editor_log`.

#### Scenario 10: Edge case — invalid enum value for filter
- **Description:** Pass an invalid filter value not in the enum (e.g., "verbose").
- **Params:**
  ```json
  {
    "filter": "verbose"
  }
  ```
- **Expected result:** Error (Zod validation failure). `z.enum(['error', 'warning', 'info'])` rejects values not in the set.
- **Notes:** Note that there is no "log", "debug", or "all" option in the enum.

#### Scenario 11: Edge case — filter as empty string
- **Description:** Pass an empty string for filter.
- **Params:**
  ```json
  {
    "filter": ""
  }
  ```
- **Expected result:** Error (Zod validation failure). Empty string is not in the enum.

#### Scenario 12: Edge case — filter as number
- **Description:** Pass a number for filter.
- **Params:**
  ```json
  {
    "filter": 1
  }
  ```
- **Expected result:** Error (Zod validation failure).

#### Scenario 13: Edge case — limit below minimum (0)
- **Description:** Pass `limit: 0` (below the `.min(1)` constraint).
- **Params:**
  ```json
  {
    "limit": 0
  }
  ```
- **Expected result:** Error (Zod validation failure). `.min(1)` rejects 0.

#### Scenario 14: Edge case — limit as negative
- **Description:** Pass `limit: -5`.
- **Params:**
  ```json
  {
    "limit": -5
  }
  ```
- **Expected result:** Error (Zod validation failure). `.min(1)` rejects negatives.

#### Scenario 15: Edge case — limit above maximum (501)
- **Description:** Pass `limit: 501` (above the `.max(500)` constraint).
- **Params:**
  ```json
  {
    "limit": 501
  }
  ```
- **Expected result:** Error (Zod validation failure). `.max(500)` rejects values above 500.

#### Scenario 16: Edge case — limit as float
- **Description:** Pass `limit` as a non-integer (e.g., 25.5).
- **Params:**
  ```json
  {
    "limit": 25.5
  }
  ```
- **Expected result:** Error (Zod validation failure). `.int()` rejects floats.

#### Scenario 17: Edge case — limit as string
- **Description:** Pass `limit` as a string `"50"`.
- **Params:**
  ```json
  {
    "limit": "50"
  }
  ```
- **Expected result:** Error (Zod validation failure). `z.number()` rejects strings.

#### Scenario 18: Edge case — filter + limit as strings both
- **Description:** Pass both params as strings.
- **Params:**
  ```json
  {
    "filter": "error",
    "limit": "10"
  }
  ```
- **Expected result:** Error (Zod validation failure on `limit`). `filter` would pass if the string matches the enum, but `limit` is a string and fails.

---

## Tool: `clear_editor_log`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| *(none)* | — | — | No input parameters |

### Handler

Calls `callGodot(bridge, 'debug_config/clear_log')` — no args forwarded.

### Test Scenarios

#### Scenario 1: Basic happy path — clear the log
- **Description:** Call with no arguments to clear the editor output log.
- **Params:** `{}`
- **Expected result:** Success. The editor output log is cleared. Verify by calling `get_editor_log` immediately after — should return an empty or near-empty result.
- **Notes:** If new log entries are generated between the clear and the get, some entries may appear. This is expected behavior.

#### Scenario 2: Call with empty input object
- **Description:** Invoke with an explicit empty object `{}`.
- **Params:** `{}`
- **Expected result:** Success (same as Scenario 1). No required params.

#### Scenario 3: Clear an already-empty log
- **Description:** Clear the log twice in a row; second call on an already-cleared log.
- **Params:** `{}`
- **Expected result:** Success (idempotent). Clearing an already-empty log should not cause an error.

#### Scenario 4: Clear, then generate entries, then verify
- **Description:** Clear the log, then check that new entries accumulate after the clear.
- **Params:** For this scenario:
  1. Call `clear_editor_log` with `{}` — expect success.
  2. Call `get_editor_log` with `{}` — expect empty/minimal.
  3. Trigger an action that generates log output (e.g., a script with `print()`).
  4. Call `get_editor_log` — expect new entries to appear.
- **Expected result (step 1):** Success. **(step 2):** Empty. **(step 4):** New entries present, confirming clear was a point-in-time operation.

#### Scenario 5: Call with irrelevant extra keys
- **Description:** Pass extra keys not in the schema.
- **Params:**
  ```json
  {
    "all": true,
    "force": "yes"
  }
  ```
- **Expected result:** Success. Extra keys are silently ignored since `inputSchema` is `{}`.

---

## Cross-Tool Integration Scenarios

These scenarios test interactions between multiple debug_config tools.

### Integration 1: Full debug settings lifecycle
1. Call `get_debug_settings` — record baseline state.
2. Call `set_remote_debug` with `{ "enabled": true, "host": "127.0.0.1", "port": 6007 }` — enable remote debug.
3. Call `set_profiler_settings` with `{ "max_functions": 128, "max_timestamp_query_elements": 512 }` — configure profiler.
4. Call `set_error_handling` with `{ "break_on_error": true, "break_on_warning": false }` — configure error handling.
5. Call `get_debug_settings` — verify all three categories reflect the values set in steps 2-4.
6. Call `set_remote_debug` with `{ "enabled": false }` — disable remote debug.
7. Call `get_debug_settings` — verify remote debug is disabled, profiler and error handling settings unchanged.

### Integration 2: Log read + clear cycle
1. Call `get_editor_log` with `{}` — note current log count and contents.
2. Call `clear_editor_log` with `{}` — clear the log.
3. Call `get_editor_log` with `{}` — expect empty or minimal result.
4. Call `get_editor_log` with `{ "filter": "error", "limit": 1 }` — expect empty (no errors).
5. Trigger an intentional error (e.g., invalid script) to generate log entries.
6. Call `get_editor_log` with `{ "filter": "error", "limit": 10 }` — expect the newly generated error to appear.

### Integration 3: Profiler settings boundary sequence
1. Call `set_profiler_settings` with `{ "max_functions": 16 }` — documented minimum.
2. Call `get_debug_settings` — verify max_functions is 16.
3. Call `set_profiler_settings` with `{ "max_functions": 512 }` — documented maximum.
4. Call `get_debug_settings` — verify max_functions is 512.
5. Call `set_profiler_settings` with `{ "max_functions": 256 }` — mid-range.
6. Call `get_debug_settings` — verify max_functions is 256.

### Integration 4: Error handling toggle sequence
1. Call `set_error_handling` with `{ "break_on_error": false, "break_on_warning": false }` — both off.
2. Call `get_debug_settings` — verify both are false.
3. Call `set_error_handling` with `{ "break_on_error": true }` — only error on.
4. Call `get_debug_settings` — verify break_on_error is true, break_on_warning is still false (not reset).
5. Call `set_error_handling` with `{ "break_on_warning": true }` — only warning on.
6. Call `get_debug_settings` — verify break_on_warning is true, break_on_error is still true (not reset).
7. Call `set_error_handling` with `{}` — empty no-op.
8. Call `get_debug_settings` — verify both are still true (unchanged by no-op).

### Integration 5: Log filter enumeration
1. For each valid filter value in `["error", "warning", "info"]`:
   - Call `get_editor_log` with `{ "filter": "<value>" }`.
   - Expect success; all returned entries should match the filter type.
2. Call `get_editor_log` with `{}` (no filter).
   - Expect success; entries may include types beyond the three filter values (e.g., "log").
   - Document the full set of type values returned when unfiltered.

---

## Summary of All Tools

| # | Tool Name | Required Params | Optional Params | Godot Endpoint |
|---|-----------|----------------|-----------------|----------------|
| 1 | `get_debug_settings` | *(none)* | — | `debug_config/get_settings` |
| 2 | `set_remote_debug` | `enabled` | `host`, `port` | `debug_config/set_remote_debug` |
| 3 | `set_profiler_settings` | *(none)* | `max_functions`, `max_timestamp_query_elements` | `debug_config/set_profilers` |
| 4 | `set_error_handling` | *(none)* | `break_on_error`, `break_on_warning` | `debug_config/set_error_handling` |
| 5 | `get_editor_log` | *(none)* | `filter` (enum), `limit` (1-500) | `debug_config/get_log` |
| 6 | `clear_editor_log` | *(none)* | — | `debug_config/clear_log` |

**Total tools:** 6
**Total test scenarios:** 67 (47 happy paths + 38 edge cases + 5 integration scenarios; some scenarios test multiple sub-cases)

---

## Notes for Test Executors

1. **Prerequisites:** The Godot editor must be running with the MCP plugin connected. No specific project state is required for most tests, though `get_editor_log` tests benefit from having log entries to query.

2. **Godot-level validation:** Several edge cases note "Zod passes, but Godot may reject." This is because the Zod schemas in `debug_config.ts` are permissive (no `.min()` on port, no range constraints on profiler settings). The test executor should document whether Godot accepts, rejects, or clamps these boundary values.

3. **Idempotency:** Tools with no required params (`get_debug_settings`, `clear_editor_log`) and tools with all-optional params (`set_profiler_settings`, `set_error_handling`) should handle repeated calls gracefully.

4. **Schema strictness:** Zod's default behavior strips unrecognized keys. Tests that send extra parameters verify that the server does not crash or error on unexpected input — this is by design for forward compatibility.

5. **`get_editor_log` filter enum:** Only `'error'`, `'warning'`, and `'info'` are valid. The enum does not include `'log'`, `'debug'`, `'all'`, or `'verbose'`. Unfiltered calls may return entries of types not in the filter enum — verify and document this.

6. **Default values:** Where a default is specified (e.g., `host` defaults to `'127.0.0.1'`, `port` defaults to `6007`, `limit` defaults to `50`), verify via `get_debug_settings` or `get_editor_log` that the default is applied when the parameter is omitted.
