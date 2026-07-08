# Editor Configuration Test Plan

> **Source file:** `server/src/tools/editor_config.ts`  
> **Shared types:** `server/src/tools/shared-types.ts`  
> **Tools covered:** 8 (`get_editor_settings`, `set_editor_theme`, `set_editor_layout`, `set_font_size`, `set_editor_scale`, `save_editor_layout`, `load_editor_layout`, `reset_editor_layout`)  
> **Generated:** 2026-07-08

---

## Schema Details

### Shared Imports

| Import | Zod Schema | Description |
|--------|-----------|-------------|
| `Name` | `z.string()` | Generic name identifier (from `shared-types.ts`) |
| `z` | Zod namespace | Used directly for `z.enum(...)`, `z.number().int().min().max()` |

### Parameter Summary

| Tool | Param | Type | Required | Default | Enum/Choices | Notes |
|------|-------|------|----------|---------|--------------|-------|
| `get_editor_settings` | *(none)* | — | — | — | — | Takes no input |
| `set_editor_theme` | `theme` | `enum` | ✅ yes | — | `dark`, `light`, `amoled` | Editor theme preset |
| `set_editor_layout` | `layout` | `enum` | ✅ yes | — | `default`, `2d`, `3d`, `script` | Workspace layout preset |
| `set_font_size` | `size` | `number` (int) | ✅ yes | — | min: 8, max: 48 | Font size in pixels |
| `set_editor_scale` | `scale` | `number` | ✅ yes | — | min: 0.5, max: 3.0 | UI scale factor (1.0 = 100%) |
| `save_editor_layout` | `name` | `string` | ✅ yes | — | — | Layout name to save as |
| `load_editor_layout` | `name` | `string` | ✅ yes | — | — | Layout name to load |
| `reset_editor_layout` | *(none)* | — | — | — | — | Takes no input; resets to factory defaults |

---

## Tool: get_editor_settings

### Schema

```typescript
{
  description: 'Get all editor settings (theme, layout, font, scale, etc.)',
  inputSchema: {},
}
```

### Handler

```typescript
async () => callGodot(bridge, 'editor_config/get_settings')
```

### Tool Behavior
Reads and returns all current editor configuration settings from the Godot editor, including the active theme, layout, font size, UI scale, and other editor preferences. Takes no parameters. This is a pure read operation with no side effects.

### Test Scenarios

#### Scenario 1: Basic happy path — get editor settings
- **Description:** Call `get_editor_settings` on a running Godot editor with an open project.
- **Params:** `{}` (empty object)
- **Expected result:** Returns a JSON object containing current editor settings. Should include keys relevant to editor configuration (theme name, font size, UI scale, layout name, etc.). The response should not be an error.
- **Notes:** The exact shape depends on the Godot bridge implementation, but it should be a non-empty object.

#### Scenario 2: Call with no arguments object at all
- **Description:** Call the tool with `undefined` or `null` as the args value.
- **Params:** `undefined` or `null`
- **Expected result:** Should succeed — the empty schema (`{}`) accepts any input (Zod strips unknown keys from empty schemas). Returns the same result as Scenario 1.
- **Notes:** Validates that the handler works correctly when no args object is provided by the MCP client.

#### Scenario 3: Call with unexpected extra params
- **Description:** Verify the tool ignores extraneous parameters since `inputSchema` is an empty object.
- **Params:** `{ "garbage": true, "extra": "value" }`
- **Expected result:** Should succeed identically to Scenario 1. Zod strips unknown keys from an empty schema definition.
- **Notes:** Tests robustness against clients that may send extra fields.

#### Scenario 4: Idempotency — call twice in succession
- **Description:** Call `get_editor_settings` twice back-to-back and verify both calls return consistent results.
- **Steps:**
  1. `get_editor_settings()` → result A
  2. `get_editor_settings()` → result B
- **Expected result:** Results A and B should be identical (no changes occurred between calls).

---

## Tool: set_editor_theme

### Schema

```typescript
{
  description: 'Set the editor color theme',
  inputSchema: {
    theme: z.enum(['dark', 'light', 'amoled']).describe('Editor theme preset'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'editor_config/set_theme', args as Record<string, unknown>)
```

### Tool Behavior
Switches the Godot editor's color theme to one of three presets: `dark` (default dark theme), `light` (light theme), or `amoled` (dark theme optimized for AMOLED/OLED screens with true blacks). This is a mutating operation that changes the editor's appearance immediately.

### Test Scenarios

#### Scenario 1: Happy path — set theme to `dark`
- **Description:** Switch the editor theme to the dark preset.
- **Params:** `{ "theme": "dark" }`
- **Expected result:** Editor theme changes to dark mode. Returns a success confirmation.
- **Notes:** This is the default theme in Godot, so the visual change may be subtle if already dark.

#### Scenario 2: Happy path — set theme to `light`
- **Description:** Switch the editor theme to the light preset.
- **Params:** `{ "theme": "light" }`
- **Expected result:** Editor theme changes to light mode. Returns a success confirmation.
- **Notes:** This should produce a visible change from dark → light.

#### Scenario 3: Happy path — set theme to `amoled`
- **Description:** Switch the editor theme to the AMOLED preset.
- **Params:** `{ "theme": "amoled" }`
- **Expected result:** Editor theme changes to AMOLED dark mode (true black backgrounds). Returns a success confirmation.
- **Notes:** Requires Godot 4.2+. In earlier versions, this may fall back or error.

#### Scenario 4: Round-trip — cycle through all three themes
- **Description:** Set each theme in sequence and verify each call succeeds.
- **Steps:**
  1. `set_editor_theme({ "theme": "dark" })` → success
  2. `set_editor_theme({ "theme": "light" })` → success
  3. `set_editor_theme({ "theme": "amoled" })` → success
  4. `set_editor_theme({ "theme": "dark" })` → success (restore default)
- **Expected result:** All four calls succeed. After step 4, the editor theme is restored to dark.
- **Notes:** Tests that switching themes is idempotent and reversible.

#### Scenario 5: Missing required parameter — no `theme`
- **Description:** Call `set_editor_theme` without the required `theme` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error. Should report that `theme` is required.
- **Notes:** `theme` has no `.optional()`, so it is strictly required.

#### Scenario 6: Invalid enum value — `theme: "blue"`
- **Description:** Call with a `theme` value not in the enum.
- **Params:** `{ "theme": "blue" }`
- **Expected result:** Zod validation error. Should report that `theme` must be one of `dark`, `light`, or `amoled`.
- **Notes:** Only the three enum values are accepted. Any other string fails validation.

#### Scenario 7: Invalid enum value — empty string
- **Description:** Call with an empty string as the theme.
- **Params:** `{ "theme": "" }`
- **Expected result:** Zod validation error. Empty string is not in the enum.
- **Notes:** Even though `z.string()` would accept `""`, the `z.enum()` wrapper rejects it.

#### Scenario 8: Invalid type — `theme` as number
- **Description:** Call with a numeric value for `theme`.
- **Params:** `{ "theme": 123 }`
- **Expected result:** Zod validation error. Expected string, received number.
- **Notes:** Zod enforces type checking before enum checking.

#### Scenario 9: Idempotency — set same theme twice
- **Description:** Call `set_editor_theme` with `dark` twice in a row.
- **Steps:**
  1. `set_editor_theme({ "theme": "dark" })` → success
  2. `set_editor_theme({ "theme": "dark" })` → success
- **Expected result:** Both calls succeed. The editor theme remains dark. No error from setting the already-active theme.

---

## Tool: set_editor_layout

### Schema

```typescript
{
  description: 'Switch the editor to a specific workspace layout',
  inputSchema: {
    layout: z.enum(['default', '2d', '3d', 'script']).describe('Editor layout preset to activate'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'editor_config/set_layout', args as Record<string, unknown>)
```

### Tool Behavior
Switches the Godot editor's workspace layout to one of four presets: `default` (general-purpose layout), `2d` (optimized for 2D scene editing), `3d` (optimized for 3D scene editing), or `script` (optimized for script editing with maximized script editor). This rearranges dock positions and panel visibility.

### Test Scenarios

#### Scenario 1: Happy path — set layout to `default`
- **Description:** Switch the editor workspace to the default layout.
- **Params:** `{ "layout": "default" }`
- **Expected result:** Editor workspace rearranges to the default layout. Returns a success confirmation.
- **Notes:** This should restore the standard Godot editor arrangement.

#### Scenario 2: Happy path — set layout to `2d`
- **Description:** Switch the editor workspace to the 2D layout.
- **Params:** `{ "layout": "2d" }`
- **Expected result:** Editor workspace switches to 2D-optimized layout. Returns a success confirmation.
- **Notes:** The 2D viewport should become prominent.

#### Scenario 3: Happy path — set layout to `3d`
- **Description:** Switch the editor workspace to the 3D layout.
- **Params:** `{ "layout": "3d" }`
- **Expected result:** Editor workspace switches to 3D-optimized layout. Returns a success confirmation.
- **Notes:** The 3D viewport should become prominent.

#### Scenario 4: Happy path — set layout to `script`
- **Description:** Switch the editor workspace to the script layout.
- **Params:** `{ "layout": "script" }`
- **Expected result:** Editor workspace switches to script-optimized layout (maximized script editor). Returns a success confirmation.
- **Notes:** The script editor should take up most of the workspace.

#### Scenario 5: Round-trip — cycle through all four layouts
- **Description:** Set each layout in sequence and verify each call succeeds.
- **Steps:**
  1. `set_editor_layout({ "layout": "default" })` → success
  2. `set_editor_layout({ "layout": "2d" })` → success
  3. `set_editor_layout({ "layout": "3d" })` → success
  4. `set_editor_layout({ "layout": "script" })` → success
  5. `set_editor_layout({ "layout": "default" })` → success (restore)
- **Expected result:** All five calls succeed. After step 5, layout is back to default.

#### Scenario 6: Missing required parameter — no `layout`
- **Description:** Call `set_editor_layout` without the required `layout` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error. Should report that `layout` is required.

#### Scenario 7: Invalid enum value — `layout: "audio"`
- **Description:** Call with a `layout` value not in the enum.
- **Params:** `{ "layout": "audio" }`
- **Expected result:** Zod validation error. Should report that `layout` must be one of `default`, `2d`, `3d`, or `script`.
- **Notes:** Only the four defined workspace layouts are valid.

#### Scenario 8: Invalid enum value — empty string
- **Description:** Call with an empty string as the layout.
- **Params:** `{ "layout": "" }`
- **Expected result:** Zod validation error. Empty string is not in the enum.

#### Scenario 9: Invalid type — `layout` as boolean
- **Description:** Call with a boolean value for `layout`.
- **Params:** `{ "layout": true }`
- **Expected result:** Zod validation error. Expected string, received boolean.

---

## Tool: set_font_size

### Schema

```typescript
{
  description: 'Set the editor font size in pixels',
  inputSchema: {
    size: z.number().int().min(8).max(48).describe('Font size in pixels'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'editor_config/set_font_size', args as Record<string, unknown>)
```

### Tool Behavior
Sets the Godot editor's code font size (in pixels). The value must be an integer between 8 and 48 inclusive. This affects the script editor, output panel, and other text-displaying areas of the editor.

### Test Scenarios

#### Scenario 1: Happy path — set font size to 14 (typical default)
- **Description:** Set the editor font size to 14 pixels.
- **Params:** `{ "size": 14 }`
- **Expected result:** Editor font size changes to 14px. Returns a success confirmation.
- **Notes:** 14 is a common default in Godot.

#### Scenario 2: Happy path — set font size to minimum boundary (8)
- **Description:** Set the editor font size to the minimum allowed value.
- **Params:** `{ "size": 8 }`
- **Expected result:** Editor font size changes to 8px. Text should be very small but still readable. Returns success.
- **Notes:** Tests the lower boundary of the `min(8)` constraint.

#### Scenario 3: Happy path — set font size to maximum boundary (48)
- **Description:** Set the editor font size to the maximum allowed value.
- **Params:** `{ "size": 48 }`
- **Expected result:** Editor font size changes to 48px. Text should be very large. Returns success.
- **Notes:** Tests the upper boundary of the `max(48)` constraint.

#### Scenario 4: Happy path — set font size to 24 (common large size)
- **Description:** Set the editor font size to 24 pixels, a common choice for presentations or high-DPI screens.
- **Params:** `{ "size": 24 }`
- **Expected result:** Editor font size changes to 24px. Returns success.

#### Scenario 5: Edge case — font size below minimum (7)
- **Description:** Attempt to set font size to 7, which is below the minimum of 8.
- **Params:** `{ "size": 7 }`
- **Expected result:** Zod validation error. Should report that `size` must be >= 8.
- **Notes:** Bound is exclusive — 7 fails while 8 passes.

#### Scenario 6: Edge case — font size above maximum (49)
- **Description:** Attempt to set font size to 49, which is above the maximum of 48.
- **Params:** `{ "size": 49 }`
- **Expected result:** Zod validation error. Should report that `size` must be <= 48.
- **Notes:** Bound is exclusive — 49 fails while 48 passes.

#### Scenario 7: Edge case — font size of zero
- **Description:** Attempt to set font size to 0.
- **Params:** `{ "size": 0 }`
- **Expected result:** Zod validation error. `min(8)` rejects 0.
- **Notes:** Zero is far below the minimum, and would be nonsensical for a font size.

#### Scenario 8: Edge case — negative font size
- **Description:** Attempt to set font size to -5.
- **Params:** `{ "size": -5 }`
- **Expected result:** Zod validation error. `min(8)` rejects negative numbers.
- **Notes:** Negative font sizes are meaningless.

#### Scenario 9: Edge case — non-integer font size (13.5)
- **Description:** Attempt to set font size to a floating-point value.
- **Params:** `{ "size": 13.5 }`
- **Expected result:** Zod validation error. The `.int()` constraint rejects non-integer numbers.
- **Notes:** Font sizes must be whole pixels.

#### Scenario 10: Missing required parameter — no `size`
- **Description:** Call `set_font_size` without the `size` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error. Should report that `size` is required.

#### Scenario 11: Invalid type — `size` as string
- **Description:** Call with a string value for `size`.
- **Params:** `{ "size": "14" }`
- **Expected result:** Zod validation error. Expected number, received string.
- **Notes:** The string `"14"` is not coerced to a number by Zod's default behavior.

#### Scenario 12: Invalid type — `size` as boolean
- **Description:** Call with a boolean value for `size`.
- **Params:** `{ "size": true }`
- **Expected result:** Zod validation error. Expected number, received boolean.

---

## Tool: set_editor_scale

### Schema

```typescript
{
  description: 'Set the editor UI scale factor',
  inputSchema: {
    scale: z.number().min(0.5).max(3.0).describe('UI scale factor (1.0 = 100%)'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'editor_config/set_scale', args as Record<string, unknown>)
```

### Tool Behavior
Sets the Godot editor's UI scale factor. A value of 1.0 represents 100% (normal size). Values greater than 1.0 enlarge the UI; values less than 1.0 shrink it. The valid range is 0.5 (50%) to 3.0 (300%). Unlike `set_font_size`, this accepts floating-point values and scales the entire editor UI (panels, icons, etc.), not just text.

### Test Scenarios

#### Scenario 1: Happy path — set scale to 1.0 (100%, default)
- **Description:** Set the editor UI scale to the default 100%.
- **Params:** `{ "scale": 1.0 }`
- **Expected result:** Editor UI scale resets to 100%. Returns a success confirmation.
- **Notes:** This is the normal/default scale.

#### Scenario 2: Happy path — set scale to minimum boundary (0.5)
- **Description:** Set the editor UI scale to the minimum allowed value (50%).
- **Params:** `{ "scale": 0.5 }`
- **Expected result:** Editor UI shrinks to 50% scale. All UI elements (panels, icons, text) become half their normal size. Returns success.
- **Notes:** Tests the lower boundary of the `min(0.5)` constraint. Very small — may be hard to read.

#### Scenario 3: Happy path — set scale to maximum boundary (3.0)
- **Description:** Set the editor UI scale to the maximum allowed value (300%).
- **Params:** `{ "scale": 3.0 }`
- **Expected result:** Editor UI enlarges to 300% scale. All UI elements become triple their normal size. Returns success.
- **Notes:** Tests the upper boundary of the `max(3.0)` constraint. Very large — useful for high-DPI or accessibility.

#### Scenario 4: Happy path — set scale to 1.5 (150%)
- **Description:** Set the editor UI scale to 150%.
- **Params:** `{ "scale": 1.5 }`
- **Expected result:** Editor UI enlarges to 150%. Returns success.
- **Notes:** Common choice for high-DPI displays.

#### Scenario 5: Happy path — set scale to 0.75 (75%)
- **Description:** Set the editor UI scale to 75%.
- **Params:** `{ "scale": 0.75 }`
- **Expected result:** Editor UI shrinks to 75%. Returns success.
- **Notes:** Common choice for low-resolution displays to fit more content.

#### Scenario 6: Edge case — scale below minimum (0.49)
- **Description:** Attempt to set scale to 0.49, just below the minimum of 0.5.
- **Params:** `{ "scale": 0.49 }`
- **Expected result:** Zod validation error. Should report that `scale` must be >= 0.5.
- **Notes:** Tests the boundary precisely at one tick below minimum.

#### Scenario 7: Edge case — scale above maximum (3.01)
- **Description:** Attempt to set scale to 3.01, just above the maximum of 3.0.
- **Params:** `{ "scale": 3.01 }`
- **Expected result:** Zod validation error. Should report that `scale` must be <= 3.0.
- **Notes:** Tests the boundary precisely at one tick above maximum.

#### Scenario 8: Edge case — scale of zero
- **Description:** Attempt to set scale to 0.0.
- **Params:** `{ "scale": 0.0 }`
- **Expected result:** Zod validation error. `min(0.5)` rejects 0.
- **Notes:** A scale of zero would make the UI invisible, so it must be rejected.

#### Scenario 9: Edge case — negative scale
- **Description:** Attempt to set scale to -1.0.
- **Params:** `{ "scale": -1.0 }`
- **Expected result:** Zod validation error. `min(0.5)` rejects negative numbers.
- **Notes:** Negative scales are meaningless for UI scaling.

#### Scenario 10: Happy path — precise fractional scale (1.175)
- **Description:** Set the editor UI scale to a precise fractional value.
- **Params:** `{ "scale": 1.175 }`
- **Expected result:** Editor UI scales to 117.5%. Returns success.
- **Notes:** Since there is no `.int()` constraint, fractional values are accepted. This tests that arbitrary floats within bounds are valid.

#### Scenario 11: Missing required parameter — no `scale`
- **Description:** Call `set_editor_scale` without the `scale` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error. Should report that `scale` is required.

#### Scenario 12: Invalid type — `scale` as string
- **Description:** Call with a string value for `scale`.
- **Params:** `{ "scale": "1.5" }`
- **Expected result:** Zod validation error. Expected number, received string.

#### Scenario 13: Invalid type — `scale` as boolean
- **Description:** Call with a boolean value for `scale`.
- **Params:** `{ "scale": false }`
- **Expected result:** Zod validation error. Expected number, received boolean.

---

## Tool: save_editor_layout

### Schema

```typescript
{
  description: 'Save the current editor layout under a name',
  inputSchema: {
    name: Name.describe('Layout name to save as'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'editor_config/save_layout', args as Record<string, unknown>)
```

### Tool Behavior
Saves the current state of the Godot editor workspace (dock positions, panel sizes, visibility, etc.) under a given name. The saved layout can later be restored using `load_editor_layout`. The `name` parameter uses the `Name` shared type — a plain string identifier. Layout names should be valid as identifiers (no special filesystem characters).

### Test Scenarios

#### Scenario 1: Happy path — save layout with simple name
- **Description:** Save the current editor layout under a simple name.
- **Params:** `{ "name": "my-test-layout" }`
- **Expected result:** The current editor layout is saved under the name `my-test-layout`. Returns a success confirmation.
- **Notes:** After saving, the layout should appear in the Godot Editor → Editor Layout menu.

#### Scenario 2: Happy path — save layout with descriptive name
- **Description:** Save the current editor layout under a descriptive name.
- **Params:** `{ "name": "scripting-focus" }`
- **Expected result:** Layout saved as `scripting-focus`. Returns success.
- **Notes:** Useful for testing that names with hyphens and descriptive text work.

#### Scenario 3: Happy path — save layout, change layout, save another
- **Description:** Save two different layouts to test that multiple layouts can coexist.
- **Steps:**
  1. `set_editor_layout({ "layout": "2d" })` → success
  2. `save_editor_layout({ "name": "layout-2d" })` → success
  3. `set_editor_layout({ "layout": "script" })` → success
  4. `save_editor_layout({ "name": "layout-script" })` → success
- **Expected result:** Both layouts are saved independently. Each captures the state of the editor at the time it was saved.
- **Notes:** Validates that multiple named layouts can exist simultaneously.

#### Scenario 4: Edge case — overwrite existing layout name
- **Description:** Save a layout, change something, then save again under the same name.
- **Steps:**
  1. `save_editor_layout({ "name": "overwrite-test" })` → success
  2. `set_editor_layout({ "layout": "3d" })` → success
  3. `save_editor_layout({ "name": "overwrite-test" })` → success (overwrites)
- **Expected result:** Second save overwrites the first. No error should occur.
- **Notes:** This tests idempotency and overwrite behavior.

#### Scenario 5: Missing required parameter — no `name`
- **Description:** Call `save_editor_layout` without the `name` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error. Should report that `name` is required.

#### Scenario 6: Edge case — empty string name
- **Description:** Attempt to save a layout with an empty string as the name.
- **Params:** `{ "name": "" }`
- **Expected result:** Either Zod passes it (since `Name` is `z.string()` with no `.min(1)`) and Godot rejects it, or the Godot bridge returns an error about an invalid name.
- **Notes:** Zod does not enforce a minimum length on `Name`, so the validation happens in the Godot plugin layer.

#### Scenario 7: Edge case — very long name
- **Description:** Save a layout with a very long name string.
- **Params:** `{ "name": "this-is-an-extremely-long-layout-name-that-exceeds-typical-length-limits-for-godot-layout-names-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }`
- **Expected result:** Behavior depends on the Godot bridge — either the name is accepted (and truncated internally) or rejected with an error about length.
- **Notes:** Validates that the server does not crash or hang on unusually long input.

#### Scenario 8: Edge case — name with special characters
- **Description:** Save a layout with a name containing special characters.
- **Params:** `{ "name": "layout/with\\special:chars" }`
- **Expected result:** The Godot bridge may reject the name due to filesystem-invalid characters. The server should forward the error cleanly.
- **Notes:** Tests input sanitization at the Godot layer.

#### Scenario 9: Invalid type — `name` as number
- **Description:** Call with a numeric value for `name`.
- **Params:** `{ "name": 123 }`
- **Expected result:** Zod validation error. Expected string, received number.

---

## Tool: load_editor_layout

### Schema

```typescript
{
  description: 'Load a previously saved editor layout',
  inputSchema: {
    name: Name.describe('Layout name to load'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'editor_config/load_layout', args as Record<string, unknown>)
```

### Tool Behavior
Loads a previously saved editor workspace layout by name, restoring dock positions, panel sizes, and visibility to the state they were in when `save_editor_layout` was called. The layout must have been previously saved — loading a non-existent layout name should result in an error from the Godot bridge.

### Test Scenarios

#### Scenario 1: Happy path — load a previously saved layout
- **Description:** Save a layout, then load it back. This is the primary use case.
- **Steps:**
  1. `set_editor_layout({ "layout": "2d" })` → success
  2. `save_editor_layout({ "name": "load-test" })` → success
  3. `set_editor_layout({ "layout": "script" })` → success (change away)
  4. `load_editor_layout({ "name": "load-test" })` → success
- **Expected result:** After step 4, the editor layout should restore to the 2D layout that was saved in step 2, not the script layout set in step 3.
- **Notes:** This is the critical round-trip test: save → change → load → verify restoration.

#### Scenario 2: Happy path — load layout, make changes, load again
- **Description:** Load a layout, modify the editor, then reload the same layout to verify it resets.
- **Steps:**
  1. `save_editor_layout({ "name": "reset-test" })` → success
  2. `set_font_size({ "size": 24 })` → success (modify state)
  3. `set_editor_scale({ "scale": 2.0 })` → success (modify state)
  4. `load_editor_layout({ "name": "reset-test" })` → success
- **Expected result:** After step 4, the font size and UI scale should revert to their values at step 1.
- **Notes:** Validates that loading a layout restores all editor config state, not just dock positions.

#### Scenario 3: Edge case — load non-existent layout
- **Description:** Attempt to load a layout name that was never saved.
- **Params:** `{ "name": "this-layout-does-not-exist" }`
- **Expected result:** Godot bridge should return an error. The error message should indicate the layout was not found.
- **Notes:** The Zod validation passes (name is a valid string), but the Godot plugin should reject it.

#### Scenario 4: Missing required parameter — no `name`
- **Description:** Call `load_editor_layout` without the `name` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error. Should report that `name` is required.

#### Scenario 5: Edge case — empty string name
- **Description:** Attempt to load a layout with an empty string as the name.
- **Params:** `{ "name": "" }`
- **Expected result:** Either Zod passes it and Godot rejects it, or the Godot bridge returns a "layout not found" error.
- **Notes:** Same behavior as `save_editor_layout` with empty name.

#### Scenario 6: Invalid type — `name` as boolean
- **Description:** Call with a boolean value for `name`.
- **Params:** `{ "name": true }`
- **Expected result:** Zod validation error. Expected string, received boolean.

---

## Tool: reset_editor_layout

### Schema

```typescript
{
  description: 'Reset the editor layout to factory defaults',
  inputSchema: {},
}
```

### Handler

```typescript
async () => callGodot(bridge, 'editor_config/reset_layout')
```

### Tool Behavior
Resets the Godot editor's workspace layout to the factory default configuration. This undoes any custom dock arrangements, panel positions, or visibility changes. Note that this resets the *current active* layout to defaults — it does not delete saved named layouts. Takes no parameters.

### Test Scenarios

#### Scenario 1: Happy path — reset layout
- **Description:** Make some changes to the editor layout, then reset to defaults.
- **Steps:**
  1. `set_editor_layout({ "layout": "script" })` → success (change layout)
  2. `set_font_size({ "size": 24 })` → success (change font)
  3. `reset_editor_layout()` → success
- **Expected result:** Editor layout returns to factory defaults. Font size should reset to the default value. Returns a success confirmation.
- **Notes:** This is a destructive operation in terms of current layout state. Verify that the default layout is active afterward.

#### Scenario 2: Happy path — reset layout with no prior changes
- **Description:** Call `reset_editor_layout` on an editor that is already at default settings.
- **Params:** `{}`
- **Expected result:** Should succeed with no error. The editor remains at default settings.
- **Notes:** Tests idempotency — resetting an already-default layout should be a no-op or harmless.

#### Scenario 3: Edge case — reset layout after saving a named layout
- **Description:** Verify that resetting does not delete saved named layouts.
- **Steps:**
  1. `save_editor_layout({ "name": "before-reset" })` → success
  2. `reset_editor_layout()` → success
  3. `load_editor_layout({ "name": "before-reset" })` → success
- **Expected result:** Step 3 should succeed — the saved layout `before-reset` should still exist and load correctly.
- **Notes:** This confirms that `reset_editor_layout` resets only the active layout, not the saved layout store.

#### Scenario 4: Call with no arguments
- **Description:** Call `reset_editor_layout` with no args object at all.
- **Params:** `undefined` or `null`
- **Expected result:** Should succeed — the empty schema accepts any input.
- **Notes:** Validates the handler handles missing args gracefully.

#### Scenario 5: Call with unexpected extra params
- **Description:** Call with extraneous parameters to verify they are ignored.
- **Params:** `{ "unexpected": "param" }`
- **Expected result:** Should succeed identically to Scenario 1. Extraneous params are ignored.

---

## Integration / Cross-Tool Scenarios

### Scenario I: Full settings round-trip
- **Description:** Exercise all read/write tools in sequence to verify they work together without interference.
- **Steps:**
  1. `get_editor_settings()` → capture baseline settings
  2. `set_editor_theme({ "theme": "light" })` → success
  3. `set_editor_layout({ "layout": "2d" })` → success
  4. `set_font_size({ "size": 18 })` → success
  5. `set_editor_scale({ "scale": 1.25 })` → success
  6. `save_editor_layout({ "name": "integration-test" })` → success
  7. `get_editor_settings()` → capture modified settings
  8. `reset_editor_layout()` → success
  9. `get_editor_settings()` → capture reset settings
  10. `load_editor_layout({ "name": "integration-test" })` → success
  11. `get_editor_settings()` → capture restored settings
- **Expected result:**
  - Step 7 settings should reflect theme=light, layout=2d, font=18, scale=1.25
  - Step 9 settings should be back to defaults
  - Step 11 settings should match Step 7 (restored from saved layout)
- **Notes:** This is the most comprehensive test — it validates the entire editor_config module works as an integrated unit.

### Scenario II: Save → reset → load cycle
- **Description:** Verify that save/load survives a reset.
- **Steps:**
  1. `set_editor_theme({ "theme": "amoled" })` → success
  2. `save_editor_layout({ "name": "cycle-test" })` → success
  3. `reset_editor_layout()` → success
  4. `load_editor_layout({ "name": "cycle-test" })` → success
- **Expected result:** After step 4, the theme should be `amoled` (restored from the saved layout). The reset in step 3 should not have deleted the saved layout.
- **Notes:** Also validates that `save_editor_layout` captures the current theme setting.

### Scenario III: Multiple layout switching
- **Description:** Quickly switch between layouts to verify stability.
- **Steps:**
  1. `set_editor_layout({ "layout": "2d" })` → success
  2. `set_editor_layout({ "layout": "3d" })` → success
  3. `set_editor_layout({ "layout": "script" })` → success
  4. `set_editor_layout({ "layout": "default" })` → success
  5. Repeat steps 1-4 three times
- **Expected result:** All 12 calls succeed. No errors, no state corruption. The editor remains responsive.
- **Notes:** Stress-tests rapid layout switching. Each switch should be instantaneous.

---

## Notes for Test Executors

1. **Editor must be open:** All 8 tools interact with the Godot editor's configuration system. The Godot editor must be running with the MCP plugin active and connected.

2. **No project modification:** These tools only affect editor state (theme, layout, font, scale), not project files. Tests can be run on any open project without risk of data loss.

3. **Visual verification:** For `set_editor_theme`, `set_editor_layout`, `set_font_size`, and `set_editor_scale`, it's recommended to visually verify the change occurred (take a screenshot via `get_editor_screenshot` or manually confirm).

4. **Zod validation vs Godot validation:** The MCP server validates parameters at the schema level (Zod). The Godot plugin performs additional validation. Both layers should be tested. Zod errors are returned immediately without reaching Godot; Godot errors come back via the WebSocket bridge.

5. **Restore defaults after tests:** Run `reset_editor_layout()` at the end of each test session to restore the editor to its default state. This prevents test pollution for the next session.

6. **Font size boundaries:** The valid range for `set_font_size` is [8, 48] inclusive. Both 8 and 48 should work. Values 7 and 49 should fail at the Zod level.

7. **Scale boundaries:** The valid range for `set_editor_scale` is [0.5, 3.0] inclusive. Both 0.5 and 3.0 should work. Values 0.49 and 3.01 should fail at the Zod level.

8. **Layout name format:** The `Name` type from `shared-types.ts` is a plain `z.string()` with no constraints on length, format, or allowed characters. Godot may impose its own restrictions at runtime (e.g., rejecting names with filesystem-invalid characters like `/` or `\`). Test with simple alphanumeric names, names with hyphens/underscores, empty strings, and strings with special characters to validate both layers.

9. **AMOLED theme availability:** The `amoled` theme option was introduced in Godot 4.2. On older versions, the Godot plugin may return an error. Test with a Godot version that supports all three themes, or document version-specific behavior.

10. **Stateful sequence:** `save_editor_layout`/`load_editor_layout` tests depend on saved layouts existing. Ensure `save_editor_layout` completes before `load_editor_layout` is called for the same name. Always save before loading in a test sequence.

11. **Parameter naming convention:** All parameters are lower_snake_case: `theme`, `layout`, `size`, `scale`, `name`. The Godot bridge endpoints use the same naming convention: `editor_config/get_settings`, `editor_config/set_theme`, `editor_config/set_layout`, `editor_config/set_font_size`, `editor_config/set_scale`, `editor_config/save_layout`, `editor_config/load_layout`, `editor_config/reset_layout`.
