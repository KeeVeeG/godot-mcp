# Debug Config Tools — Test Plan

**Source file:** `server/src/tools/debug_config.ts`  
**Number of tools:** 6  
**Godot bridge commands:** `debug_config/get_settings`, `debug_config/set_remote_debug`, `debug_config/set_profilers`, `debug_config/set_error_handling`, `debug_config/get_log`, `debug_config/clear_log`

---

## Tool 1: `get_debug_settings`

**Description:** Get all debug settings (remote debug, profilers, error handling, logging)  
**Parameters:** None (empty `inputSchema`)  
**Handler:** `callGodot(bridge, 'debug_config/get_settings')`  
**Expected result:** Returns a JSON object containing all current debug configuration settings (remote debug status, profiler limits, error handling flags, logging state).

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 1 | Call with no arguments | `{}` | Valid JSON object with debug settings keys | Simplest invocation. Should always succeed. |
| 2 | Call with extra ignored arg | `{"ignored": true}` | Valid JSON object (extra arg ignored) | Zod ignores unknown keys since no schema is defined. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 3 | Call when editor is disconnected | `{}` | Error: "Godot editor is not connected" or timeout | Tests bridge availability resilience. |
| 4 | Call with `null` body | `null` | Valid JSON object (body ignored, no schema) | MCP SDK may coerce null to `{}`. Either is acceptable. |

---

## Tool 2: `set_remote_debug`

**Description:** Configure remote debugging connection  
**Handler:** `callGodot(bridge, 'debug_config/set_remote_debug', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `enabled` | `boolean` | **Yes** | — | Enable/disable remote debugging |
| `host` | `string` | No | `"127.0.0.1"` | Debug host address |
| `port` | `number` (int) | No | `6007` | Debug port |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 5 | Enable remote debug with defaults | `{"enabled": true}` | Success; remote debug enabled on 127.0.0.1:6007 | Only required param. Host and port use defaults. |
| 6 | Disable remote debug | `{"enabled": false}` | Success; remote debug disabled | Core use case for turning off remote access. |
| 7 | Enable with custom host | `{"enabled": true, "host": "0.0.0.0"}` | Success; remote debug on 0.0.0.0:6007 | Tests that host is forwarded correctly. |
| 8 | Enable with custom port | `{"enabled": true, "port": 7000}` | Success; remote debug on 127.0.0.1:7000 | Tests that port is forwarded correctly. |
| 9 | Enable with both custom host and port | `{"enabled": true, "host": "192.168.1.100", "port": 9000}` | Success; remote debug on 192.168.1.100:9000 | Full custom config. |
| 10 | Disable with host/port (should ignore) | `{"enabled": false, "host": "10.0.0.1", "port": 1234}` | Success; remote debug disabled (host/port may be ignored) | When disabling, host/port may not matter. Tool should still succeed. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 11 | Missing required `enabled` | `{}` | Zod validation error | `enabled` is required, not optional. MCP should reject. |
| 12 | Non-boolean `enabled` (string) | `{"enabled": "yes"}` | Zod validation error | Boolean type check. |
| 13 | Non-boolean `enabled` (number) | `{"enabled": 1}` | Zod validation error | Boolean type check. |
| 14 | Non-integer port | `{"enabled": true, "port": 6007.5}` | Zod validation error | `.int()` constraint enforces integer. |
| 15 | Negative port | `{"enabled": true, "port": -1}` | Passes Zod (no `.min()` on port); Godot may reject | Zod validates it as an integer, but Godot may error on negative. |
| 16 | Port as string | `{"enabled": true, "port": "6007"}` | Zod validation error | `z.number().int()` rejects strings. |
| 17 | Host as number | `{"enabled": true, "host": 1234}` | Zod validation error | `z.string()` rejects numbers. |
| 18 | Extremely large port | `{"enabled": true, "port": 9999999}` | Passes Zod; Godot may cap or reject | Port is `number().int()` with no max. Godot may clamp to 65535. |
| 19 | Empty string host | `{"enabled": true, "host": ""}` | Passes Zod; Godot may reject or default | `z.string()` accepts empty. Godot behavior TBD. |
| 20 | Enable when already enabled | `{"enabled": true}` (call twice) | Success both times (idempotent) | Should not error on re-enabling. |
| 21 | Call when editor disconnected | `{"enabled": true}` | Connection error | Standard disconnected behavior. |

### Boolean Pair Testing

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 22 | Toggle: enable → disable → enable | Sequential calls | Each succeeds; state toggles correctly | Verify state persistence. |

---

## Tool 3: `set_profiler_settings`

**Description:** Configure profiler limits. Note: profiler on/off toggles (CPU, GPU, etc.) are controlled by the editor debugger panel during gameplay and cannot be set via ProjectSettings.  
**Handler:** `callGodot(bridge, 'debug_config/set_profilers', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `max_functions` | `number` (int) | No | — | Max functions tracked by script profiler (range: 16-512) |
| `max_timestamp_query_elements` | `number` (int) | No | — | Max timestamp query elements (default: 256) |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 23 | Set max_functions only | `{"max_functions": 100}` | Success; max_functions set to 100 | Single param set. |
| 24 | Set max_timestamp_query_elements only | `{"max_timestamp_query_elements": 512}` | Success; value set to 512 | Single param set. |
| 25 | Set both params | `{"max_functions": 200, "max_timestamp_query_elements": 128}` | Success; both values set | Both params set at once. |
| 26 | Call with no params | `{}` | Success (no-op: nothing to set) | Both params are optional; empty call should succeed without changes. |

### Boundary Value Testing — `max_functions`

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 27 | Lower boundary: 16 | `{"max_functions": 16}` | Success (if Godot enforces range) | Minimum documented value. |
| 28 | Upper boundary: 512 | `{"max_functions": 512}` | Success (if Godot enforces range) | Maximum documented value. |
| 29 | Below minimum: 0 | `{"max_functions": 0}` | Passes Zod; Godot may reject or clamp | No `.min()` in schema. Godot may enforce 16-512. |
| 30 | Above maximum: 1024 | `{"max_functions": 1024}` | Passes Zod; Godot may reject or clamp | No `.max()` in schema. Godot may enforce 16-512. |
| 31 | Negative value: -1 | `{"max_functions": -1}` | Passes Zod; Godot may reject | No `.min()` in schema. |
| 32 | Float value: 100.5 | `{"max_functions": 100.5}` | Zod validation error | `.int()` rejects non-integers. |
| 33 | String value: "100" | `{"max_functions": "100"}` | Zod validation error | Type mismatch. |

### Boundary Value Testing — `max_timestamp_query_elements`

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 34 | Value: 0 | `{"max_timestamp_query_elements": 0}` | Passes Zod; Godot may reject | No `.min()` constraint. |
| 35 | Large value: 10000 | `{"max_timestamp_query_elements": 10000}` | Passes Zod; Godot may cap | No `.max()` constraint. |
| 36 | Negative: -1 | `{"max_timestamp_query_elements": -1}` | Passes Zod; Godot may reject | No `.min()` constraint. |
| 37 | Float: 256.5 | `{"max_timestamp_query_elements": 256.5}` | Zod validation error | `.int()` rejects non-integers. |
| 38 | String: "256" | `{"max_timestamp_query_elements": "256"}` | Zod validation error | Type mismatch. |
| 39 | Sequential updates | `{"max_functions": 50}`, then `{"max_functions": 300}` | Both succeed; value changes | Verify updates are applied. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 40 | Editor disconnected | `{"max_functions": 100}` | Connection error | Standard disconnected behavior. |
| 41 | Extra unknown param | `{"max_functions": 100, "unknown_key": true}` | Success (unknown key ignored) | Zod ignores unknown keys. |

---

## Tool 4: `set_error_handling`

**Description:** Configure how the editor handles errors and warnings during gameplay  
**Handler:** `callGodot(bridge, 'debug_config/set_error_handling', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `break_on_error` | `boolean` | No | — | Break into debugger on error |
| `break_on_warning` | `boolean` | No | — | Break into debugger on warning |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 42 | Enable break on error | `{"break_on_error": true}` | Success; editor breaks on errors | Single boolean set. |
| 43 | Disable break on error | `{"break_on_error": false}` | Success; editor does not break on errors | Core use case. |
| 44 | Enable break on warning | `{"break_on_warning": true}` | Success; editor breaks on warnings | Single boolean set. |
| 45 | Disable break on warning | `{"break_on_warning": false}` | Success; editor does not break on warnings | Core use case. |
| 46 | Set both to true | `{"break_on_error": true, "break_on_warning": true}` | Success; both set to true | Full strict mode. |
| 47 | Set both to false | `{"break_on_error": false, "break_on_warning": false}` | Success; both disabled | Silent mode. |
| 48 | Mixed: error=true, warning=false | `{"break_on_error": true, "break_on_warning": false}` | Success | Break only on errors. |
| 49 | Mixed: error=false, warning=true | `{"break_on_error": false, "break_on_warning": true}` | Success | Break only on warnings. |
| 50 | Call with no params | `{}` | Success (no-op: nothing to set) | Both params optional; empty call should succeed. |

### Boolean Combinatorial Coverage

| # | Scenario | JSON params | Expected result |
|---|----------|-------------|-----------------|
| 51 | (true, true) → (false, false) | Sequential calls | Both transitions succeed |
| 52 | (false, false) → (true, false) → (true, true) | Sequential calls | Each step succeeds |
| 53 | (true, true) → (false, true) → (false, false) | Sequential calls | Each step succeeds |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 54 | Non-boolean: string | `{"break_on_error": "true"}` | Zod validation error | Type mismatch. |
| 55 | Non-boolean: number | `{"break_on_error": 1}` | Zod validation error | Type mismatch. |
| 56 | Non-boolean: object | `{"break_on_error": {}}` | Zod validation error | Type mismatch. |
| 57 | Re-set same value | `{"break_on_error": true}` × 2 | Both succeed (idempotent) | No error on re-setting same value. |
| 58 | Extra unknown param | `{"break_on_error": true, "foo": "bar"}` | Success (unknown key ignored) | Zod ignores unknown keys. |
| 59 | Editor disconnected | `{"break_on_error": true}` | Connection error | Standard behavior. |

---

## Tool 5: `get_editor_log`

**Description:** Get entries from the editor log, optionally filtered by type  
**Handler:** `callGodot(bridge, 'debug_config/get_log', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `filter` | `enum("error" \| "warning" \| "info")` | No | — | Filter by message type |
| `limit` | `number` (int, min:1, max:500) | No | `50` | Max entries to return |

### Happy Path — No Filter (all types)

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 60 | Get default (no params) | `{}` | Up to 50 entries of any type | Default limit is 50, all message types. |
| 61 | Get with custom limit | `{"limit": 10}` | Up to 10 entries of any type | Custom limit, all types. |
| 62 | Get with limit=1 | `{"limit": 1}` | At most 1 entry | Minimum allowed limit. |
| 63 | Get with limit=500 | `{"limit": 500}` | Up to 500 entries | Maximum allowed limit. |

### Happy Path — By Filter Enum

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 64 | Filter: `"error"` | `{"filter": "error"}` | Up to 50 error entries | Only errors returned. |
| 65 | Filter: `"warning"` | `{"filter": "warning"}` | Up to 50 warning entries | Only warnings returned. |
| 66 | Filter: `"info"` | `{"filter": "info"}` | Up to 50 info entries | Only info messages returned. |
| 67 | Filter `"error"` + limit 10 | `{"filter": "error", "limit": 10}` | Up to 10 error entries | Combined filter and limit. |
| 68 | Filter `"warning"` + limit 500 | `{"filter": "warning", "limit": 500}` | Up to 500 warning entries | Combined filter and max limit. |
| 69 | Filter `"info"` + limit 1 | `{"filter": "info", "limit": 1}` | At most 1 info entry | Combined filter and min limit. |

### Limit Boundary Testing

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 70 | limit = 0 | `{"limit": 0}` | Zod validation error | `.min(1)` rejects 0. |
| 71 | limit = -1 | `{"limit": -1}` | Zod validation error | `.min(1)` rejects negatives. |
| 72 | limit = 501 | `{"limit": 501}` | Zod validation error | `.max(500)` rejects 501. |
| 73 | limit = 500 (exact max) | `{"limit": 500}` | Up to 500 entries | Boundary: maximum allowed. |
| 74 | limit = 1 (exact min) | `{"limit": 1}` | At most 1 entry | Boundary: minimum allowed. |
| 75 | limit as float: 50.5 | `{"limit": 50.5}` | Zod validation error | `.int()` rejects non-integers. |
| 76 | limit as string: "50" | `{"limit": "50"}` | Zod validation error | Type mismatch. |

### Filter Enum Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 77 | Invalid filter: `"debug"` | `{"filter": "debug"}` | Zod validation error | Not in enum `["error", "warning", "info"]`. |
| 78 | Invalid filter: empty string | `{"filter": ""}` | Zod validation error | Empty string not in enum. |
| 79 | Invalid filter: uppercase `"ERROR"` | `{"filter": "ERROR"}` | Zod validation error | Case-sensitive enum match. |
| 80 | Invalid filter: random string | `{"filter": "xyz"}` | Zod validation error | Not in enum. |
| 81 | Invalid filter: number | `{"filter": 123}` | Zod validation error | Type mismatch with enum string. |
| 82 | Invalid filter: boolean | `{"filter": true}` | Zod validation error | Type mismatch. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 83 | Empty log (after clear) | `{}` | Empty array `[]` or `{"entries": []}` | Behavior after `clear_editor_log`. |
| 84 | Combined: filter + limit + unknown key | `{"filter": "error", "limit": 25, "extra": true}` | Up to 25 error entries (extra ignored) | Unknown keys dropped by Zod. |
| 85 | Editor disconnected | `{}` | Connection error | Standard behavior. |

---

## Tool 6: `clear_editor_log`

**Description:** Clear the editor output log  
**Parameters:** None (empty `inputSchema`)  
**Handler:** `callGodot(bridge, 'debug_config/clear_log')`  
**Expected result:** Success (log is emptied). Should be idempotent.

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 86 | Clear log (no params) | `{}` | Success; log is emptied | Simplest invocation. |
| 87 | Clear log — verify with `get_editor_log` | `{}` then `{}` on `get_editor_log` | `get_editor_log` returns empty after clear | Integration: clear then read. |
| 88 | Clear log twice | `{}` × 2 | Success both times (idempotent) | Clearing an already-empty log should not error. |
| 89 | Call with extra ignored arg | `{"ignore": "me"}` | Success (extra arg ignored) | No schema, unknown keys ignored. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 90 | Call when log already empty | `{}` | Success (idempotent) | Should not fail on empty log. |
| 91 | Editor disconnected | `{}` | Connection error | Standard behavior. |

---

## Integration / Cross-Tool Scenarios

| # | Scenario | Steps | Expected result | Notes |
|---|----------|-------|-----------------|-------|
| 92 | Full debug config round-trip | 1. `get_debug_settings` to read baseline<br>2. `set_remote_debug` with custom values<br>3. `set_profiler_settings` with new values<br>4. `set_error_handling` with new values<br>5. `get_debug_settings` to verify changes | All steps succeed; final get shows updated values | Full config workflow. |
| 93 | Log lifecycle | 1. `get_editor_log` (note count)<br>2. `clear_editor_log`<br>3. `get_editor_log` (should be empty)<br>4. After some editor activity, `get_editor_log` (should have entries again) | Log is emptied, then refills naturally | Log round-trip. |
| 94 | Remote debug toggle | 1. `set_remote_debug({"enabled": true})`<br>2. `get_debug_settings` (verify enabled)<br>3. `set_remote_debug({"enabled": false})`<br>4. `get_debug_settings` (verify disabled) | State reflects toggles correctly | Verify persistence through get. |
| 95 | Error handling toggle cycle | 1. `set_error_handling({"break_on_error": true, "break_on_warning": false})`<br>2. `get_debug_settings` (verify settings)<br>3. `set_error_handling({"break_on_error": false, "break_on_warning": true})`<br>4. `get_debug_settings` (verify settings)<br>5. `set_error_handling({"break_on_error": false, "break_on_warning": false})`<br>6. `get_debug_settings` (verify settings) | All states correct after each step | Full boolean cycle. |
| 96 | Profiler limits boundary test | 1. `set_profiler_settings({"max_functions": 16})`<br>2. `get_debug_settings` → verify<br>3. `set_profiler_settings({"max_functions": 512})`<br>4. `get_debug_settings` → verify<br>5. `set_profiler_settings({"max_timestamp_query_elements": 256})`<br>6. `get_debug_settings` → verify | All boundary values accepted | Verification of documented ranges. |

---

## Summary: Parameter Coverage

| Tool | Parameter | Type | Required | Default | Enums/COnstraints |
|------|-----------|------|----------|---------|-------------------|
| `get_debug_settings` | (none) | — | — | — | — |
| `set_remote_debug` | `enabled` | boolean | Yes | — | — |
| `set_remote_debug` | `host` | string | No | `"127.0.0.1"` | — |
| `set_remote_debug` | `port` | number (int) | No | `6007` | — |
| `set_profiler_settings` | `max_functions` | number (int) | No | — | Range 16-512 (documented) |
| `set_profiler_settings` | `max_timestamp_query_elements` | number (int) | No | — | Default 256 (documented) |
| `set_error_handling` | `break_on_error` | boolean | No | — | — |
| `set_error_handling` | `break_on_warning` | boolean | No | — | — |
| `get_editor_log` | `filter` | enum string | No | — | `"error"`, `"warning"`, `"info"` |
| `get_editor_log` | `limit` | number (int) | No | `50` | Min: 1, Max: 500 |
| `clear_editor_log` | (none) | — | — | — | — |

**Total scenarios:** 96  
**Coverage:** Every tool, every parameter, every enum value, boundary values, type validation, idempotency, combinatorial booleans, integration round-trips.
