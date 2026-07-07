# Editor Config Tools — Test Plan

**Source file:** `server/src/tools/editor_config.ts`  
**Number of tools:** 8  
**Godot bridge commands:** `editor_config/get_settings`, `editor_config/set_theme`, `editor_config/set_layout`, `editor_config/set_font_size`, `editor_config/set_scale`, `editor_config/save_layout`, `editor_config/load_layout`, `editor_config/reset_layout`

---

## Tool 1: `get_editor_settings`

**Description:** Get all editor settings (theme, layout, font, scale, etc.)  
**Parameters:** None (empty `inputSchema`)  
**Handler:** `callGodot(bridge, 'editor_config/get_settings')`  
**Expected result:** Returns a JSON object containing all current editor configuration settings (theme name, active layout, font size, UI scale, saved layout names, etc.).

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 1 | Call with no arguments | `{}` | Valid JSON object with editor settings keys | Simplest invocation. Should always succeed in a connected editor. |
| 2 | Call with extra ignored arg | `{"ignored": true}` | Valid JSON object (extra arg ignored) | Zod ignores unknown keys since no schema is defined (`inputSchema: {}`). |
| 3 | Call after modifying settings | `{}` | Returns updated settings reflecting latest changes | Verify settings reflect prior mutations (e.g., after set_editor_theme). |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 4 | Call when editor is disconnected | `{}` | Error: "Godot editor is not connected" or timeout | Tests bridge availability resilience. |
| 5 | Call with `null` body | `null` | Valid JSON object (body ignored, no schema) | MCP SDK may coerce null to `{}`. Either is acceptable. |
| 6 | Call with large payload as extra arg | `{"extra": "<1MB string>"}` | Valid JSON object (extra arg ignored) | Schema validation is empty, so payload size should not affect Zod. MCP transport may have its own limits. |

---

## Tool 2: `set_editor_theme`

**Description:** Set the editor color theme  
**Handler:** `callGodot(bridge, 'editor_config/set_theme', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `theme` | `enum` | **Yes** | — | Editor theme preset. Valid values: `dark`, `light`, `amoled` |

### Happy Path — Each Enum Value

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 7 | Set theme to `dark` | `{"theme": "dark"}` | Success; editor theme switches to dark | Most common preset. |
| 8 | Set theme to `light` | `{"theme": "light"}` | Success; editor theme switches to light | Alternative preset. |
| 9 | Set theme to `amoled` | `{"theme": "amoled"}` | Success; editor theme switches to amoled (pure black) | OLED-optimized dark variant. |

### Happy Path — Idempotency & Round-Trip

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 10 | Set theme to same value twice | `{"theme": "dark"}` × 2 | Success both times | No error on re-setting the same value. |
| 11 | Cycle: dark → light → amoled → dark | Sequential calls | Each succeeds; theme cycles correctly | Verifies state persistence across all values. |
| 12 | Round-trip: set dark, then get_editor_settings | Set `dark`, then call `get_editor_settings` | Settings report theme is `dark` | Verify mutation is reflected in get_editor_settings output. |

### Enum Validation — Invalid Values

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 13 | Invalid enum: `"blue"` | `{"theme": "blue"}` | Zod validation error | Not a valid enum member. |
| 14 | Invalid enum: `"Dark"` (capitalized) | `{"theme": "Dark"}` | Zod validation error | Enum matching is case-sensitive. |
| 15 | Invalid enum: `"DAR K"` | `{"theme": "DAR K"}` | Zod validation error | Enum matching is exact. |
| 16 | Invalid enum: `"default"` | `{"theme": "default"}` | Zod validation error | `default` is not in the enum (it's for layout, not theme). |
| 17 | Invalid enum: `""` (empty string) | `{"theme": ""}` | Zod validation error | Empty string not in enum. |

### Type Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 18 | Missing required `theme` | `{}` | Zod validation error | `theme` is required, no default. |
| 19 | `theme` as number | `{"theme": 1}` | Zod validation error | Number not convertible to enum string. |
| 20 | `theme` as boolean | `{"theme": true}` | Zod validation error | Boolean not convertible to enum string. |
| 21 | `theme` as null | `{"theme": null}` | Zod validation error | Null not convertible to enum string. |
| 22 | `theme` as object | `{"theme": {"name": "dark"}}` | Zod validation error | Object not convertible to enum string. |
| 23 | `theme` as array | `{"theme": ["dark"]}` | Zod validation error | Array not convertible to enum string. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 24 | Call when editor disconnected | `{"theme": "dark"}` | Connection error | Standard disconnected behavior. |
| 25 | Extra unknown properties alongside valid theme | `{"theme": "dark", "unknown": 123}` | Success (unknown key ignored by Zod strictness) | Test resilience to extra keys. |

---

## Tool 3: `set_editor_layout`

**Description:** Switch the editor to a specific workspace layout  
**Handler:** `callGodot(bridge, 'editor_config/set_layout', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `layout` | `enum` | **Yes** | — | Editor layout preset to activate. Valid values: `default`, `2d`, `3d`, `script` |

### Happy Path — Each Enum Value

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 26 | Set layout to `default` | `{"layout": "default"}` | Success; editor switches to default workspace | Most common preset. |
| 27 | Set layout to `2d` | `{"layout": "2d"}` | Success; editor switches to 2D workspace | Optimized for 2D scene editing. |
| 28 | Set layout to `3d` | `{"layout": "3d"}` | Success; editor switches to 3D workspace | Optimized for 3D scene editing. |
| 29 | Set layout to `script` | `{"layout": "script"}` | Success; editor switches to script workspace | Optimized for code editing. |

### Happy Path — Idempotency & Round-Trip

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 30 | Set layout to same value twice | `{"layout": "default"}` × 2 | Success both times | No error on re-setting. |
| 31 | Cycle: default → 2d → 3d → script → default | Sequential calls | Each succeeds; layout cycles correctly | Verifies state across all 4 values. |
| 32 | Round-trip: set 3d, then get_editor_settings | Set `3d`, then call `get_editor_settings` | Settings report active layout is `3d` | Verify mutation reflected in readback. |

### Enum Validation — Invalid Values

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 33 | Invalid enum: `"4d"` | `{"layout": "4d"}` | Zod validation error | Not a valid enum member. |
| 34 | Invalid enum: `"Default"` (capitalized) | `{"layout": "Default"}` | Zod validation error | Case-sensitive enum. |
| 35 | Invalid enum: `"2D"` (uppercase D) | `{"layout": "2D"}` | Zod validation error | Case-sensitive enum. |
| 36 | Invalid enum: `"3 D"` (space) | `{"layout": "3 D"}` | Zod validation error | Exact match required. |
| 37 | Invalid enum: `"dark"` (confused with theme) | `{"layout": "dark"}` | Zod validation error | Layout enum has different values than theme enum. |
| 38 | Invalid enum: `"amoled"` (confused with theme) | `{"layout": "amoled"}` | Zod validation error | Layout enum has different values than theme enum. |
| 39 | Invalid enum: `""` (empty string) | `{"layout": ""}` | Zod validation error | Empty string not in enum. |

### Type Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 40 | Missing required `layout` | `{}` | Zod validation error | `layout` is required, no default. |
| 41 | `layout` as number | `{"layout": 2}` | Zod validation error | Number not convertible. |
| 42 | `layout` as boolean | `{"layout": false}` | Zod validation error | Boolean not convertible. |
| 43 | `layout` as null | `{"layout": null}` | Zod validation error | Null not convertible. |
| 44 | `layout` as object | `{"layout": {"name": "2d"}}` | Zod validation error | Object not convertible. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 45 | Call when editor disconnected | `{"layout": "2d"}` | Connection error | Standard disconnected behavior. |
| 46 | Extra unknown properties alongside valid layout | `{"layout": "3d", "extra": "value"}` | Success (unknown key ignored) | Test resilience to extra keys. |

---

## Tool 4: `set_font_size`

**Description:** Set the editor font size in pixels  
**Handler:** `callGodot(bridge, 'editor_config/set_font_size', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `size` | `number` (int) | **Yes** | — | Font size in pixels. Valid range: 8–48 inclusive. |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 47 | Set font size to typical value (14) | `{"size": 14}` | Success; editor font set to 14px | Common readable size. |
| 48 | Set font size to large value (24) | `{"size": 24}` | Success; editor font set to 24px | Large but within range. |
| 49 | Set font size to small value (10) | `{"size": 10}` | Success; editor font set to 10px | Small but readable. |

### Happy Path — Idempotency & Round-Trip

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 50 | Set to same size twice | `{"size": 14}` × 2 | Success both times | No error on re-setting. |
| 51 | Increment: 10 → 16 → 22 → 28 | Sequential calls | Each succeeds; font size updates | Verify sequential changes. |
| 52 | Round-trip: set 18, then get_editor_settings | Set `18`, then call `get_editor_settings` | Settings report font size is 18 | Verify readback. |

### Boundary Value Testing

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 53 | Minimum boundary: 8 | `{"size": 8}` | Success; editor font set to 8px | Lower bound of `.min(8)`. |
| 54 | Maximum boundary: 48 | `{"size": 48}` | Success; editor font set to 48px | Upper bound of `.max(48)`. |
| 55 | Below minimum: 7 | `{"size": 7}` | Zod validation error | `.min(8)` rejects values < 8. |
| 56 | Below minimum: 0 | `{"size": 0}` | Zod validation error | `.min(8)` rejects 0. |
| 57 | Below minimum: -1 | `{"size": -1}` | Zod validation error | `.min(8)` rejects negative. |
| 58 | Above maximum: 49 | `{"size": 49}` | Zod validation error | `.max(48)` rejects values > 48. |
| 59 | Above maximum: 100 | `{"size": 100}` | Zod validation error | `.max(48)` rejects large values. |
| 60 | Above maximum: 999 | `{"size": 999}` | Zod validation error | `.max(48)` rejects extreme values. |

### Integer Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 61 | Float value: 14.5 | `{"size": 14.5}` | Zod validation error | `.int()` rejects non-integers. |
| 62 | Float value: 8.0 | `{"size": 8.0}` | Zod validation error (JavaScript) | In JSON/JS, `8.0` serializes as `8` which is an integer. If literal `8.0` reaches Zod, behavior depends on parser. |
| 63 | Float value: 47.9 | `{"size": 47.9}` | Zod validation error | `.int()` rejects. |
| 64 | Float at boundary: 7.999 | `{"size": 7.999}` | Zod validation error (non-integer, also below min) | Fails on both `.int()` and `.min(8)`. |

### Type Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 65 | Missing required `size` | `{}` | Zod validation error | `size` is required. |
| 66 | `size` as string | `{"size": "14"}` | Zod validation error | String not coerced to number. |
| 67 | `size` as boolean | `{"size": true}` | Zod validation error | Boolean not coerced. |
| 68 | `size` as null | `{"size": null}` | Zod validation error | Null not accepted. |
| 69 | `size` as object | `{"size": {"value": 14}}` | Zod validation error | Object not accepted. |
| 70 | `size` as array | `{"size": [14]}` | Zod validation error | Array not accepted. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 71 | Call when editor disconnected | `{"size": 14}` | Connection error | Standard disconnected behavior. |
| 72 | Extra unknown properties | `{"size": 14, "unit": "px"}` | Success (unknown key ignored) | Test resilience. |

---

## Tool 5: `set_editor_scale`

**Description:** Set the editor UI scale factor  
**Handler:** `callGodot(bridge, 'editor_config/set_scale', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `scale` | `number` | **Yes** | — | UI scale factor (1.0 = 100%). Valid range: 0.5–3.0 inclusive. |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 73 | Set scale to default (1.0) | `{"scale": 1.0}` | Success; UI at 100% | Normal/default scale. |
| 74 | Set scale to 1.5 | `{"scale": 1.5}` | Success; UI at 150% | Scaling up. |
| 75 | Set scale to 0.75 | `{"scale": 0.75}` | Success; UI at 75% | Scaling down. |
| 76 | Set scale to 2.0 | `{"scale": 2.0}` | Success; UI at 200% | Popular HiDPI scaling. |

### Happy Path — Idempotency & Round-Trip

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 77 | Set to same scale twice | `{"scale": 1.25}` × 2 | Success both times | No error on re-setting. |
| 78 | Sequence: 0.5 → 1.0 → 2.0 → 3.0 | Sequential calls | Each succeeds; scale changes correctly | Full range traversal. |
| 79 | Round-trip: set 1.75, then get_editor_settings | Set `1.75`, then call `get_editor_settings` | Settings report scale is 1.75 | Verify readback. |

### Boundary Value Testing

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 80 | Minimum boundary: 0.5 | `{"scale": 0.5}` | Success; UI at 50% | Lower bound of `.min(0.5)`. |
| 81 | Maximum boundary: 3.0 | `{"scale": 3.0}` | Success; UI at 300% | Upper bound of `.max(3.0)`. |
| 82 | Below minimum: 0.49 | `{"scale": 0.49}` | Zod validation error | `.min(0.5)` rejects. |
| 83 | Below minimum: 0.0 | `{"scale": 0.0}` | Zod validation error | `.min(0.5)` rejects zero. |
| 84 | Below minimum: -0.5 | `{"scale": -0.5}` | Zod validation error | `.min(0.5)` rejects negative. |
| 85 | Above maximum: 3.01 | `{"scale": 3.01}` | Zod validation error | `.max(3.0)` rejects. |
| 86 | Above maximum: 5.0 | `{"scale": 5.0}` | Zod validation error | `.max(3.0)` rejects. |
| 87 | Above maximum: 10.0 | `{"scale": 10.0}` | Zod validation error | `.max(3.0)` rejects extreme. |

### Fractional Value Testing (scale does NOT have `.int()`)

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 88 | Fractional value: 1.333 | `{"scale": 1.333}` | Success; scale at 133.3% | Unlike `set_font_size`, `scale` accepts floats — no `.int()` constraint. |
| 89 | Fractional value: 0.501 | `{"scale": 0.501}` | Success (just above min) | Validates precision at lower bound. |
| 90 | Fractional value: 2.999 | `{"scale": 2.999}` | Success (just below max) | Validates precision at upper bound. |
| 91 | Many decimal places: 1.123456789 | `{"scale": 1.123456789}` | Success; Godot may round | No precision limit in Zod. Godot may truncate/round internally. |
| 92 | Scientific notation: `1e0` | `{"scale": 1e0}` | Success (parsed as 1.0) | JSON number `1e0` is valid and equals 1.0. |

### Type Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 93 | Missing required `scale` | `{}` | Zod validation error | `scale` is required. |
| 94 | `scale` as string | `{"scale": "1.5"}` | Zod validation error | String not coerced to number. |
| 95 | `scale` as boolean | `{"scale": true}` | Zod validation error | Boolean not coerced. |
| 96 | `scale` as null | `{"scale": null}` | Zod validation error | Null not accepted. |
| 97 | `scale` as object | `{"scale": {"value": 1.5}}` | Zod validation error | Object not accepted. |
| 98 | `scale` as array | `{"scale": [1.5]}` | Zod validation error | Array not accepted. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 99 | Call when editor disconnected | `{"scale": 1.5}` | Connection error | Standard disconnected behavior. |
| 100 | Extra unknown properties | `{"scale": 1.25, "method": "pixels"}` | Success (unknown key ignored) | Test resilience. |

### Comparison: `scale` vs `set_font_size` — Key Differences

| Aspect | `set_editor_scale` | `set_font_size` |
|--------|-------------------|-----------------|
| Type constraint | `z.number()` (float OK) | `z.number().int()` (integer only) |
| Range | 0.5–3.0 | 8–48 |
| Unit | Factor (1.0 = 100%) | Pixels |
| Affects | All UI elements proportionally | Font rendering only |

---

## Tool 6: `save_editor_layout`

**Description:** Save the current editor layout under a name  
**Handler:** `callGodot(bridge, 'editor_config/save_layout', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | `string` | **Yes** | — | Layout name to save as. Zod schema: `z.string()` (the `Name` shared type). |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 101 | Save with simple name | `{"name": "MyLayout"}` | Success; layout saved as "MyLayout" | Basic save operation. |
| 102 | Save with descriptive name | `{"name": "2D Editing Workspace"}` | Success; layout saved with spaces | Multi-word names should work. |
| 103 | Save with alphanumeric name | `{"name": "Layout_v2_2025"}` | Success; layout saved | Underscores and numbers. |
| 104 | Save with single character name | `{"name": "A"}` | Success (if Godot allows single-char) | Zod accepts any non-empty string. |

### Happy Path — Overwrite & Multiple Saves

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 105 | Save layout, change settings, save under different name | Save "A", change theme, save "B" | Both layouts saved; "A" retains original config | Multiple distinct layouts. |
| 106 | Overwrite existing layout name | Save "X", change settings, save "X" again | Success; "X" now has updated settings | Overwrite is allowed. |
| 107 | Save after reset_editor_layout | Reset, then save as "DefaultClone" | Success; layout saved with factory settings | Verify reset-then-save workflow. |

### Round-Trip Verification

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 108 | Save, change theme, load saved layout | Save "TestTheme", set dark theme, load "TestTheme" | Layout restores original theme | Verify save captures theme state. |
| 109 | Save, change font size, load saved layout | Save "TestFont", set size 24, load "TestFont" | Layout restores original font size | Verify save captures font size. |
| 110 | Save, change scale, load saved layout | Save "TestScale", set scale 2.0, load "TestScale" | Layout restores original scale | Verify save captures scale. |
| 111 | Save, change layout to 3d, load saved layout | Save in "default" layout, switch to "3d", load saved | Restores "default" layout workspace | Verify save captures workspace layout. |

### Type Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 112 | Missing required `name` | `{}` | Zod validation error | `name` is required. |
| 113 | `name` as number | `{"name": 123}` | Zod validation error | Number not accepted. |
| 114 | `name` as boolean | `{"name": true}` | Zod validation error | Boolean not accepted. |
| 115 | `name` as null | `{"name": null}` | Zod validation error | Null not accepted. |
| 116 | `name` as object | `{"name": {"label": "MyLayout"}}` | Zod validation error | Object not accepted. |
| 117 | `name` as array | `{"name": ["Layout1"]}` | Zod validation error | Array not accepted. |

### Edge Cases — Name Strings

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 118 | Empty string name | `{"name": ""}` | Passes Zod; Godot may reject or save as empty | `z.string()` does not enforce `.min(1)`. Godot behavior TBD. |
| 119 | Very long name (1000 chars) | `{"name": "A".repeat(1000)}` | Passes Zod; Godot may truncate or reject | No length limit in Zod. Filesystem/Godot may impose limits. |
| 120 | Name with special characters | `{"name": "Layout #1 @v2!"}` | Passes Zod; Godot may sanitize or reject | Special chars may cause filesystem issues. |
| 121 | Name with path separators | `{"name": "../../etc/passwd"}` | Passes Zod; Godot must sanitize | Path traversal attempt — Godot must not write outside config dir. |
| 122 | Unicode name | `{"name": "レイアウト"}` | Passes Zod; Godot should handle Unicode | CJK characters — verify Godot filesystem handling. |
| 123 | Name with leading/trailing whitespace | `{"name": "  MyLayout  "}` | Passes Zod (raw string); Godot may trim | Test whether Godot strips whitespace. |
| 124 | Name with newlines | `{"name": "Line1\nLine2"}` | Passes Zod; Godot likely rejects or sanitizes | Newlines in filenames are invalid on most OS. |

### Edge Cases — Runtime

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 125 | Call when editor disconnected | `{"name": "TestLayout"}` | Connection error | Standard disconnected behavior. |
| 126 | Save without having made any changes first | `{"name": "DefaultState"}` | Success; saves current (unchanged) state | Validates save works on pristine state. |
| 127 | Extra unknown properties | `{"name": "MyLayout", "description": "For 2D work"}` | Success (unknown key ignored) | Test resilience. |

---

## Tool 7: `load_editor_layout`

**Description:** Load a previously saved editor layout  
**Handler:** `callGodot(bridge, 'editor_config/load_layout', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | `string` | **Yes** | — | Layout name to load. Zod schema: `z.string()` (the `Name` shared type). |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 128 | Load a saved layout | `{"name": "MyLayout"}` | Success; editor settings restore to saved state | Requires prior `save_editor_layout`. |
| 129 | Load layout with spaces in name | `{"name": "2D Editing Workspace"}` | Success (if saved) | Multi-word names. |
| 130 | Load a layout, verify settings match | Load "TestTheme", then `get_editor_settings` | Settings match what was saved | Full round-trip verification. |

### Happy Path — Sequential Loads

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 131 | Load layout, then load another | Load "A", then load "B" | Each loads correctly; settings update accordingly | Switching between layouts. |
| 132 | Load a layout twice | Load "X" twice | Success both times | Idempotent load. |

### Error Cases — Non-Existent Layout

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 133 | Load non-existent layout name | `{"name": "NonExistentLayout"}` | Error from Godot: layout not found | Godot should return a meaningful error. |
| 134 | Load layout that was never saved | `{"name": "NeverCreated"}` | Error from Godot: layout not found | Same as above — verify error message clarity. |
| 135 | Load layout name with different case | Save "MyLayout", load "mylayout" | Error if Godot is case-sensitive; success if case-insensitive | Depends on Godot's layout storage (filesystem-based = case-sensitive on Linux). |
| 136 | Load after reset_editor_layout (layouts may be cleared) | Reset, then load "MyLayout" | Depends on whether reset clears saved layouts | Verify reset behavior — does it delete saved layouts? |

### Type Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 137 | Missing required `name` | `{}` | Zod validation error | `name` is required. |
| 138 | `name` as number | `{"name": 42}` | Zod validation error | Number not accepted. |
| 139 | `name` as boolean | `{"name": false}` | Zod validation error | Boolean not accepted. |
| 140 | `name` as null | `{"name": null}` | Zod validation error | Null not accepted. |
| 141 | `name` as object | `{"name": {}}` | Zod validation error | Object not accepted. |
| 142 | `name` as array | `{"name": ["Layout1"]}` | Zod validation error | Array not accepted. |

### Edge Cases — Name Strings

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 143 | Empty string name | `{"name": ""}` | Passes Zod; Godot likely returns not-found error | Empty string as layout name. |
| 144 | Very long name (1000 chars) | `{"name": "A".repeat(1000)}` | Passes Zod; Godot returns not-found unless such a layout exists | No length limit in Zod. |
| 145 | Name with path separators | `{"name": "../../etc/passwd"}` | Passes Zod; Godot must sanitize/not traverse | Path traversal attempt on load. |
| 146 | Unicode name | `{"name": "レイアウト"}` | Passes Zod; loads if saved with same Unicode name | CJK characters. |
| 147 | Name with leading/trailing whitespace | `{"name": "  MyLayout  "}` | Passes Zod; Godot may trim before lookup | Whitespace handling. |

### Edge Cases — Runtime

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 148 | Call when editor disconnected | `{"name": "MyLayout"}` | Connection error | Standard disconnected behavior. |
| 149 | Extra unknown properties | `{"name": "MyLayout", "version": 2}` | Success (unknown key ignored) | Test resilience. |

---

## Tool 8: `reset_editor_layout`

**Description:** Reset the editor layout to factory defaults  
**Parameters:** None (empty `inputSchema`)  
**Handler:** `callGodot(bridge, 'editor_config/reset_layout')`  
**Expected result:** Editor layout, theme, font size, scale, and workspace arrangement all revert to Godot's factory default values.

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 150 | Call with no arguments | `{}` | Success; editor resets to factory defaults | Simplest invocation. |
| 151 | Call with extra ignored arg | `{"ignored": "value"}` | Success; editor resets (extra arg ignored) | Schema is empty. |

### Happy Path — Verification

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 152 | Customize then reset, verify with get_editor_settings | Set dark theme, size 24, scale 2.0, layout 3d; then reset; then get_editor_settings | Settings show factory defaults (likely light theme, size ~14, scale 1.0, layout default) | Verify all settings return to defaults. |
| 153 | Save a layout, reset, verify saved layout still exists | Save "MyLayout", reset, try load "MyLayout" | Depends on reset behavior — does it clear saved layouts? | Document the discovered behavior. |
| 154 | Double reset | Call `reset_editor_layout` twice | Success both times | Idempotent — resetting defaults should be fine. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 155 | Call when editor disconnected | `{}` | Connection error | Standard disconnected behavior. |
| 156 | Call with `null` body | `null` | Success (body ignored) | MCP SDK may coerce null to `{}`. |
| 157 | Reset when already at defaults | `{}` (no prior customization) | Success (no-op) | Should not error. |

---

## Cross-Tool Interaction Scenarios

These scenarios test how multiple tools from this module interact with each other. They verify state consistency and sequential workflows.

| # | Scenario | Steps | Expected result | Notes |
|---|----------|-------|-----------------|-------|
| 158 | Full customization then reset | 1. `set_editor_theme` → `amoled`<br>2. `set_font_size` → 20<br>3. `set_editor_scale` → 2.0<br>4. `set_editor_layout` → `script`<br>5. `get_editor_settings` (verify changed)<br>6. `reset_editor_layout`<br>7. `get_editor_settings` (verify defaults) | Steps 1-4 succeed; step 5 shows custom values; step 6 succeeds; step 7 shows factory defaults | End-to-end customization + reset workflow. |
| 159 | Save → Customize → Load cycle | 1. `set_editor_theme` → `light`<br>2. `set_font_size` → 16<br>3. `save_editor_layout` → `"Baseline"`<br>4. `set_editor_theme` → `dark`<br>5. `set_font_size` → 32<br>6. `load_editor_layout` → `"Baseline"`<br>7. `get_editor_settings` | Steps 1-5 succeed; step 6 succeeds; step 7 shows theme=light, size=16 | Save/load preserves exact state. |
| 160 | Multiple layout library | 1. Configure layout A: dark, 14, 1.0, default → save as "DarkDefault"<br>2. Configure layout B: light, 18, 1.5, script → save as "LightScript"<br>3. Load "DarkDefault" → verify<br>4. Load "LightScript" → verify<br>5. Load "DarkDefault" → verify | Each load restores exact state from its save | Library of named layouts. |
| 161 | Reset deletes layouts? | 1. Save layout "TestSave"<br>2. `reset_editor_layout`<br>3. `load_editor_layout` → "TestSave" | If step 3 succeeds: reset does NOT delete layouts.<br>If step 3 fails: reset clears saved layouts | Important behavioral discovery. |
| 162 | Theme/scale/font interaction with layout load | 1. `set_editor_theme` → `amoled`<br>2. `set_editor_scale` → 2.5<br>3. `save_editor_layout` → "AmoBig"<br>4. `set_editor_theme` → `light` (change one)<br>5. `load_editor_layout` → "AmoBig"<br>6. `get_editor_settings` | Theme restored to amoled AND scale restored to 2.5 | Verify layout load restores ALL settings, not just layout type. |
| 163 | Concurrent tool calls (if supported) | Simultaneous `set_editor_theme`→`dark` + `set_font_size`→`20` | Depends on MCP concurrency model; both should succeed or one may queue | Document how Godot bridge handles concurrent mutations. |

---

## Godot Bridge Command Mapping

For debugging and troubleshooting, here is the exact mapping of MCP tool names to Godot bridge command strings:

| # | MCP Tool Name | Godot Bridge Command |
|---|---------------|---------------------|
| 1 | `get_editor_settings` | `editor_config/get_settings` |
| 2 | `set_editor_theme` | `editor_config/set_theme` |
| 3 | `set_editor_layout` | `editor_config/set_layout` |
| 4 | `set_font_size` | `editor_config/set_font_size` |
| 5 | `set_editor_scale` | `editor_config/set_scale` |
| 6 | `save_editor_layout` | `editor_config/save_layout` |
| 7 | `load_editor_layout` | `editor_config/load_layout` |
| 8 | `reset_editor_layout` | `editor_config/reset_layout` |

---

## Summary

| Metric | Value |
|--------|-------|
| Total tools | 8 |
| Total test scenarios | 163 |
| Happy path scenarios | ~50 |
| Enum validation scenarios | 31 |
| Boundary value scenarios | 20 |
| Type validation scenarios | 28 |
| Edge case scenarios | 24 |
| Cross-tool interaction scenarios | 6 |
| Godot bridge commands | 8 |
