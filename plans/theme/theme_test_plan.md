# Theme Tools Test Plan

> **Source file:** `server/src/tools/theme.ts`  
> **Shared types:** `server/src/tools/shared-types.ts`  
> **Tools covered:** 7 (`create_theme`, `delete_theme`, `set_theme_color`, `set_theme_constant`, `set_theme_font_size`, `set_theme_stylebox`, `get_theme_info`)  
> **Generated:** 2026-07-08

---

## Prerequisites

Before running any test scenario in this plan, ensure:
1. The Godot editor is open with the MCP plugin active and connected.
2. The project has a `res://themes/` directory (create if missing).
3. A theme resource exists at `res://themes/test_theme.tres` for modification/inspection tests (create via `create_theme` as the first scenario).

**Setup sequence** (run once before all tests):
1. `create_theme` with `{ "path": "res://themes/test_theme.tres" }` — creates the base theme for subsequent tests.
2. Use `get_theme_info` to verify the theme exists and is empty (no overrides yet).

**TearDown** (run after all tests):
1. `delete_theme` with `{ "path": "res://themes/test_theme.tres" }` — removes the test theme.

---

## Schema Details

### Shared Imports

| Import | Zod Schema | Description |
|--------|-----------|-------------|
| `ResourcePath` | `z.string()` | Resource file path (e.g. `'res://assets/theme.tres'`) |
| `Properties` | `z.record(z.unknown())` | Required property key-value pairs (any keys, any values) |
| `z` | Zod namespace | Used directly for `z.string()`, `z.number().int()`, `z.number().int().positive()` |

### Parameter Summary

| Tool | Param | Type | Required | Default | Enum/Choices | Notes |
|------|-------|------|----------|---------|--------------|-------|
| `create_theme` | `path` | `string` | ✅ yes | — | — | File path (e.g. `'res://themes/dark.tres'`) |
| `delete_theme` | `path` | `string` | ✅ yes | — | — | Theme file path to delete |
| `set_theme_color` | `path` | `string` | ✅ yes | — | — | Theme resource path |
| | `theme_type` | `string` | ✅ yes | — | — | Control type (e.g. `'Button'`, `'Label'`, `'Panel'`) |
| | `name` | `string` | ✅ yes | — | — | Color name (e.g. `'font_color'`, `'font_hover_color'`) |
| | `color` | `string` | ✅ yes | — | — | Hex color (`'#FF0000'`) or named color (`'red'`) |
| `set_theme_constant` | `path` | `string` | ✅ yes | — | — | Theme resource path |
| | `theme_type` | `string` | ✅ yes | — | — | Control type |
| | `name` | `string` | ✅ yes | — | — | Constant name (e.g. `'hseparation'`, `'vseparation'`) |
| | `value` | `integer` | ✅ yes | — | — | Constant integer value |
| `set_theme_font_size` | `path` | `string` | ✅ yes | — | — | Theme resource path |
| | `theme_type` | `string` | ✅ yes | — | — | Control type |
| | `name` | `string` | ✅ yes | — | — | Size name (e.g. `'font_size'`) |
| | `size` | `positive integer` | ✅ yes | — | — | Font size in pixels (> 0) |
| `set_theme_stylebox` | `path` | `string` | ✅ yes | — | — | Theme resource path |
| | `theme_type` | `string` | ✅ yes | — | — | Control type |
| | `name` | `string` | ✅ yes | — | — | StyleBox name (e.g. `'normal'`, `'hover'`, `'pressed'`) |
| | `properties` | `record(unknown)` | ✅ yes | — | — | StyleBox properties (e.g. `bg_color`, `border_width`) |
| `get_theme_info` | `path` | `string` | ✅ yes | — | — | Theme resource path |

---

## Tool: create_theme

### Schema

```typescript
{
  description: 'Create a new Theme resource',
  inputSchema: {
    path: ResourcePath,  // z.string() — "Resource file path (e.g. 'res://assets/theme.tres')"
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'theme/create', args as Record<string, unknown>)
```

### Tool Behavior
Creates a new, empty `Theme` resource file (`.tres`) at the specified path. The resulting file contains a default Godot Theme with no overrides or custom styles. The tool writes to the project filesystem; the new file should appear in the Godot FileSystem dock. If a file already exists at the path, the behavior depends on Godot's resource creation logic (may overwrite or error).

### Test Scenarios

#### Scenario 1: Happy path — create a theme in a subdirectory
- **Description:** Create a new theme resource in `res://themes/` with default settings.
- **Params:** `{ "path": "res://themes/test_theme.tres" }`
- **Expected result:** Success. A new `.tres` file is created at the specified path. The theme is empty (no overrides). Response should indicate success, possibly returning the created resource path or metadata.
- **Notes:** This is the setup scenario for all subsequent tests. Verify the file appears in the FileSystem dock. Use `get_theme_info` afterward to confirm the theme exists and is empty.

#### Scenario 2: Happy path — create a theme at a deeper path
- **Description:** Create a theme in a nested directory to verify path resolution works for non-flat structures.
- **Params:** `{ "path": "res://themes/ui/main_menu_theme.tres" }`
- **Expected result:** Success. The directory hierarchy `res://themes/ui/` is created if needed, and the theme file is written.
- **Notes:** Tests path creation through multiple directory levels. Clean up afterward with `delete_theme`.

#### Scenario 3: Happy path — create a theme with a different name pattern
- **Description:** Create a theme with underscores and numbers in the filename.
- **Params:** `{ "path": "res://themes/my_custom_theme_v2.tres" }`
- **Expected result:** Success. The file is created normally. Filename conventions don't matter for resource files.
- **Notes:** Validates that non-trivial filenames work. Clean up afterward.

#### Scenario 4: Missing required param — no path
- **Description:** Call `create_theme` without the required `path` parameter.
- **Params:** `{}` (empty object)
- **Expected result:** Zod validation error. Should reject with a message indicating `path` is required.
- **Notes:** All params are required in this tool; Zod should catch this before the handler runs.

#### Scenario 5: Invalid path — no file extension
- **Description:** Call with a path that lacks the `.tres` extension.
- **Params:** `{ "path": "res://themes/no_extension" }`
- **Expected result:** Likely an error from Godot. The engine may auto-append `.tres` or reject the invalid path. Behavior is engine-dependent.
- **Notes:** Tests Godot-side path validation. Should not crash the editor.

#### Scenario 6: Invalid path — wrong extension
- **Description:** Call with a `.res` (binary resource) extension instead of `.tres`.
- **Params:** `{ "path": "res://themes/binary_theme.res" }`
- **Expected result:** Possible success (`.res` is also a valid resource extension) or error depending on how Godot handles Theme creation in binary mode. Most likely it creates a binary resource file that may not be a valid Theme.
- **Notes:** `.res` is a valid Godot resource extension but Themes are typically `.tres`. Test to see if Godot accepts this.

#### Scenario 7: Invalid path — absolute OS filesystem path
- **Description:** Try to create a theme using an absolute Windows/Linux filesystem path instead of `res://`.
- **Params:** `{ "path": "C:/Users/test/Desktop/my_theme.tres" }`
- **Expected result:** Error. Godot resources must use `res://` paths. The bridge should reject this.
- **Notes:** Tests that non-project paths are rejected.

#### Scenario 8: Invalid path — empty string
- **Description:** Call with an empty string as the path.
- **Params:** `{ "path": "" }`
- **Expected result:** Zod validation passes (empty string is still a string), but Godot should return an error for an invalid/incomplete path.
- **Notes:** Empty string is not a valid resource path but passes Zod validation.

#### Scenario 9: Invalid path — path to overwrite an existing scene
- **Description:** Try to create a theme at a path where a scene file already exists (different resource type).
- **Params:** `{ "path": "res://scenes/main.tscn" }`
- **Expected result:** Error or overwrite warning. Godot should warn about overwriting a different resource type, or the operation may fail. The existing scene should not be corrupted.
- **Notes:** Tests resource type collision. Do NOT use a critical scene file — use a disposable test scene if available.

#### Scenario 10: Path with trailing slash
- **Description:** Call with a path that ends with a slash (directory-style).
- **Params:** `{ "path": "res://themes/" }`
- **Expected result:** Error. A trailing slash suggests a directory, not a file. Godot should reject this.
- **Notes:** Boundary test for path format expectations.

---

## Tool: delete_theme

### Schema

```typescript
{
  description: 'Delete a theme resource file from the project',
  inputSchema: {
    path: z.string(),  // "Theme file path to delete (e.g. res://themes/my_theme.tres)"
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'theme/delete', args as Record<string, unknown>)
```

### Tool Behavior
Deletes a `.tres` theme resource file from the project filesystem. The file is permanently removed (moved to system trash or deleted outright, depending on engine/platform). After deletion, the file should no longer appear in the Godot FileSystem dock. If the file does not exist, the tool returns an error.

### Test Scenarios

#### Scenario 1: Happy path — delete an existing theme
- **Description:** Delete a theme resource file that was created earlier during setup.
- **Params:** `{ "path": "res://themes/test_theme.tres" }`
- **Expected result:** Success. The file is removed from the project. Subsequent attempts to read or get info on this path should fail. Response should confirm deletion.
- **Notes:** Run this as the last test in the suite (teardown). Must first create the theme via `create_theme`.

#### Scenario 2: Happy path — delete a theme in a subdirectory
- **Description:** Delete a theme created in a nested directory.
- **Params:** `{ "path": "res://themes/ui/main_menu_theme.tres" }`
- **Expected result:** Success. The file is removed. The parent directory may remain (if empty) or be cleaned up.
- **Notes:** Run after creating this theme in the `create_theme` scenarios.

#### Scenario 3: Missing required param — no path
- **Description:** Call `delete_theme` without the required `path` parameter.
- **Params:** `{}` (empty object)
- **Expected result:** Zod validation error. Should reject with a message indicating `path` is required.
- **Notes:** Basic schema validation.

#### Scenario 4: Invalid path — file does not exist
- **Description:** Try to delete a theme resource that does not exist.
- **Params:** `{ "path": "res://themes/nonexistent.tres" }`
- **Expected result:** Error from Godot bridge. Should return an error response indicating the file was not found. No files should be affected.
- **Notes:** Tests graceful handling of missing files.

#### Scenario 5: Invalid path — delete a non-theme resource
- **Description:** Try to delete a file that is not a theme (e.g. a scene or script).
- **Params:** `{ "path": "res://scripts/player.gd" }`
- **Expected result:** Possible success (the tool may delete any file regardless of type) or error if Godot validates the resource type. Most likely the file is deleted since the tool just performs a file delete operation.
- **Notes:** The tool description says "theme resource file" but the handler passes to `theme/delete` which may or may not validate the resource type. Test with a disposable file only.

#### Scenario 6: Invalid path — empty string
- **Description:** Call with an empty string as the path.
- **Params:** `{ "path": "" }`
- **Expected result:** Zod validation passes (empty string is a valid string), but Godot should return an error for an invalid path. No files should be deleted.
- **Notes:** Empty path is not valid but passes Zod.

#### Scenario 7: Delete a theme that is currently referenced by nodes
- **Description:** Delete a theme resource that is currently applied to UI elements in an open scene.
- **Params:** `{ "path": "res://themes/referenced_theme.tres" }`
- **Expected result:** The file is deleted from disk. Nodes referencing the theme may fall back to the default theme. Godot should handle this gracefully, possibly showing missing-resource warnings.
- **Notes:** Tests deletion while the resource is in use. Create the theme, apply it to a Button via `set_theme_color`, then delete it.

#### Scenario 8: Delete the same file twice
- **Description:** Call `delete_theme` on a path, then call it again on the same (now-deleted) path.
- **Params (call 1):** `{ "path": "res://themes/temp_delete_test.tres" }`  
- **Params (call 2):** `{ "path": "res://themes/temp_delete_test.tres" }`
- **Expected result:** First call succeeds and deletes the file. Second call returns an error because the file no longer exists.
- **Notes:** Idempotency test. Create a disposable theme first.

---

## Tool: set_theme_color

### Schema

```typescript
{
  description: 'Set a color in a theme for a specific control type',
  inputSchema: {
    path: ResourcePath,       // z.string() — "Theme resource path"
    theme_type: z.string(),   // "Control type (e.g. 'Button', 'Label', 'Panel')"
    name: z.string(),         // "Color name (e.g. 'font_color', 'font_hover_color')"
    color: z.string(),        // "Color value as hex (e.g. '#FF0000') or named color"
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'theme/set_color', args as Record<string, unknown>)
```

### Tool Behavior
Overrides a color property for a specific control type within a Theme resource. After setting, any control of `theme_type` using this theme will use the specified color for the named property. The theme file on disk is modified. Common `theme_type` values include `Button`, `Label`, `Panel`, `LineEdit`, `CheckBox`, `ProgressBar`, `Slider`, `ScrollBar`, `TextEdit`, `TabContainer`, etc. Common `name` values include `font_color`, `font_hover_color`, `font_pressed_color`, `font_focus_color`, `font_disabled_color`, `icon_normal_color`, etc.

### Test Scenarios

#### Scenario 1: Happy path — set font color for Button using hex
- **Description:** Set the `font_color` of `Button` controls to red using a hex color string.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_color", "color": "#FF0000" }`
- **Expected result:** Success. The theme override is written. Use `get_theme_info` afterward to verify that `Button.font_color` is set to `#FF0000`.
- **Notes:** Requires `test_theme.tres` to exist (created via `create_theme` scenario 1).

#### Scenario 2: Happy path — set hover color for Button using named color
- **Description:** Set `font_hover_color` for `Button` using a CSS named color.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_hover_color", "color": "blue" }`
- **Expected result:** Success. The named color is resolved to its RGB equivalent by Godot.
- **Notes:** Tests that named color strings are accepted alongside hex values.

#### Scenario 3: Happy path — set color with alpha hex
- **Description:** Set a color using an 8-digit hex with alpha channel.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_disabled_color", "color": "#FF0000AA" }`
- **Expected result:** Success. The alpha component is preserved. Verify via `get_theme_info`.
- **Notes:** Tests RGBA hex format (RRGGBBAA). Some engines use AARRGGBB — verify the correct format with Godot.

#### Scenario 4: Happy path — set color for Label control type
- **Description:** Set `font_color` for `Label` controls to verify different control types work.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Label", "name": "font_color", "color": "#00FF00" }`
- **Expected result:** Success. The override applies to `Label` type only, not `Button` (from previous scenarios).
- **Notes:** Tests that different `theme_type` values correctly scope the override.

#### Scenario 5: Happy path — set color for Panel control type
- **Description:** Set `font_color` for `Panel` controls.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Panel", "name": "font_color", "color": "#0000FF" }`
- **Expected result:** Success. Three different control types now have distinct color overrides in the theme.
- **Notes:** Validates that setting multiple control types does not interfere.

#### Scenario 6: Happy path — set a non-font color property
- **Description:** Set `icon_normal_color` for `Button` to verify non-font color names work.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "icon_normal_color", "color": "#FFFF00" }`
- **Expected result:** Success. The icon color override is stored.
- **Notes:** Tests a color property name that isn't font-related.

#### Scenario 7: Happy path — overwrite a previously set color
- **Description:** Overwrite a previously set `font_color` for `Button` with a new value.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_color", "color": "#FFFFFF" }`
- **Expected result:** Success. The new color `#FFFFFF` replaces the previous `#FF0000` (from Scenario 1). Verify via `get_theme_info`.
- **Notes:** Tests that set_theme_color is idempotent and can update existing overrides.

#### Scenario 8: Missing required param — no path
- **Description:** Call without the `path` parameter.
- **Params:** `{ "theme_type": "Button", "name": "font_color", "color": "#FF0000" }`
- **Expected result:** Zod validation error. `path` is required.
- **Notes:** All four params are required.

#### Scenario 9: Missing required param — no theme_type
- **Description:** Call without the `theme_type` parameter.
- **Params:** `{ "path": "res://themes/test_theme.tres", "name": "font_color", "color": "#FF0000" }`
- **Expected result:** Zod validation error. `theme_type` is required.
- **Notes:** —

#### Scenario 10: Missing required param — no name
- **Description:** Call without the `name` parameter.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "color": "#FF0000" }`
- **Expected result:** Zod validation error. `name` is required.
- **Notes:** —

#### Scenario 11: Missing required param — no color
- **Description:** Call without the `color` parameter.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_color" }`
- **Expected result:** Zod validation error. `color` is required.
- **Notes:** —

#### Scenario 12: Invalid color — malformed hex
- **Description:** Pass a hex color with invalid format (e.g., too many digits).
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_color", "color": "#FFGG00" }`
- **Expected result:** Possible error from Godot (`#FFGG00` has invalid hex digits 'GG') or the value may be silently accepted as a string. Zod only validates it is a string.
- **Notes:** Zod does not validate color format — it's just `z.string()`. Any validation happens in Godot.

#### Scenario 13: Invalid color — non-hex, non-named string
- **Description:** Pass a completely arbitrary string as the color.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_color", "color": "not_a_color" }`
- **Expected result:** Error from Godot or the color may be treated as an invalid/default color (likely black or transparent). Godot may warn about unrecognized color format.
- **Notes:** Tests Godot's color string parsing robustness.

#### Scenario 14: Invalid theme_type — empty string
- **Description:** Pass an empty string for `theme_type`.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "", "name": "font_color", "color": "#FF0000" }`
- **Expected result:** Likely error from Godot. Empty string is not a valid control type. May create an override on a default/root type or fail.
- **Notes:** Zod validates it's a string but not that it's a valid control type.

#### Scenario 15: Invalid theme_type — nonexistent control type
- **Description:** Pass a control type string that doesn't correspond to any real Godot control.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "NonExistentControl42", "name": "font_color", "color": "#FF0000" }`
- **Expected result:** Possibly accepted (Godot themes can have overrides for any string key) or rejected. The override would have no visual effect since no control matches. Verify via `get_theme_info`.
- **Notes:** Tests whether Godot validates control type names against its class registry.

#### Scenario 16: Invalid path — theme file does not exist
- **Description:** Try to set a color on a theme that has not been created yet.
- **Params:** `{ "path": "res://themes/nonexistent.tres", "theme_type": "Button", "name": "font_color", "color": "#FF0000" }`
- **Expected result:** Error from Godot bridge. Should return an error indicating the theme file was not found.
- **Notes:** The tool requires an existing theme to modify.

#### Scenario 17: Set color for a container control type
- **Description:** Set a color for `PanelContainer` or `VBoxContainer` — controls that inherit from Container.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "PanelContainer", "name": "font_color", "color": "#FF8800" }`
- **Expected result:** Success. Container types should work the same as basic controls.
- **Notes:** Tests that theme overrides work across the control hierarchy.

#### Scenario 18: Set color to transparent
- **Description:** Set a fully transparent color.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Label", "name": "font_color", "color": "#00000000" }`
- **Expected result:** Success. The color is stored with alpha=0 (fully transparent). This is a valid test of alpha handling.
- **Notes:** Tests that zero-alpha colors work correctly.

---

## Tool: set_theme_constant

### Schema

```typescript
{
  description: 'Set a constant value in a theme',
  inputSchema: {
    path: ResourcePath,                // z.string() — "Theme resource path"
    theme_type: z.string(),            // "Control type"
    name: z.string(),                  // "Constant name (e.g. 'hseparation', 'vseparation')"
    value: z.number().int(),           // "Constant integer value"
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'theme/set_constant', args as Record<string, unknown>)
```

### Tool Behavior
Sets an integer constant override for a specific control type within a Theme. Constants control spacing, sizing, and other numeric properties of UI controls. Common constants include `hseparation` (horizontal spacing), `vseparation` (vertical spacing), `margin_left`, `margin_right`, `margin_top`, `margin_bottom`, `check_vadjust`, `outline_size`, `separator`, `minimum_character_width`, etc. The `value` must be an integer (Zod enforces `.int()`).

### Test Scenarios

#### Scenario 1: Happy path — set horizontal separation for Button
- **Description:** Set `hseparation` for `Button` to a typical spacing value.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "hseparation", "value": 4 }`
- **Expected result:** Success. The constant override is written. Verify via `get_theme_info`.
- **Notes:** Requires `test_theme.tres` to exist.

#### Scenario 2: Happy path — set vertical separation for Button
- **Description:** Set `vseparation` for `Button` controls.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "vseparation", "value": 8 }`
- **Expected result:** Success. Both `hseparation` and `vseparation` overrides now exist for `Button`.
- **Notes:** —

#### Scenario 3: Happy path — set a large constant value
- **Description:** Set a constant to a large integer (e.g., 99999) to test boundary handling.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "margin_left", "value": 99999 }`
- **Expected result:** Success. The large value is stored. Godot may clamp it internally when rendering, but the raw value should be preserved.
- **Notes:** Tests large integer handling. No explicit maximum is defined in the schema.

#### Scenario 4: Happy path — set constant to zero
- **Description:** Set a constant to zero (minimum valid value).
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "outline_size", "value": 0 }`
- **Expected result:** Success. Zero is a valid integer constant. Should mean "no outline" or equivalent.
- **Notes:** Tests the lower boundary of the integer range.

#### Scenario 5: Happy path — set constant to a negative integer
- **Description:** Set a constant to a negative value.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "hseparation", "value": -5 }`
- **Expected result:** Likely success at the schema level (Zod only requires `.int()`). Godot may accept or reject negative spacing values depending on the specific constant. If accepted, verify via `get_theme_info`; if rejected, an error should be returned.
- **Notes:** Negative spacing could cause overlapping UI elements. Tests whether Godot validates constant semantics.

#### Scenario 6: Happy path — set constant for a non-Button control type
- **Description:** Set `hseparation` for `HBoxContainer`.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "HBoxContainer", "name": "hseparation", "value": 12 }`
- **Expected result:** Success. Constants work across all control types.
- **Notes:** —

#### Scenario 7: Happy path — overwrite a previously set constant
- **Description:** Change the value of an already-set constant.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "hseparation", "value": 16 }`
- **Expected result:** Success. The new value replaces the old one. Verify via `get_theme_info`.
- **Notes:** Tests idempotency of constant setting.

#### Scenario 8: Missing required param — no path
- **Description:** Call without the `path` parameter.
- **Params:** `{ "theme_type": "Button", "name": "hseparation", "value": 4 }`
- **Expected result:** Zod validation error. `path` is required.
- **Notes:** —

#### Scenario 9: Missing required param — no theme_type
- **Description:** Call without the `theme_type` parameter.
- **Params:** `{ "path": "res://themes/test_theme.tres", "name": "hseparation", "value": 4 }`
- **Expected result:** Zod validation error. `theme_type` is required.
- **Notes:** —

#### Scenario 10: Missing required param — no name
- **Description:** Call without the `name` parameter.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "value": 4 }`
- **Expected result:** Zod validation error. `name` is required.
- **Notes:** —

#### Scenario 11: Missing required param — no value
- **Description:** Call without the `value` parameter.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "hseparation" }`
- **Expected result:** Zod validation error. `value` is required.
- **Notes:** —

#### Scenario 12: Invalid value — float instead of integer
- **Description:** Pass a floating-point number where an integer is expected.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "hseparation", "value": 4.5 }`
- **Expected result:** Zod validation error. The schema requires `.int()`, so `4.5` should be rejected.
- **Notes:** Tests Zod's integer validation. Even `4.0` may be treated as a float in JSON; test with an explicit fractional value.

#### Scenario 13: Invalid value — string instead of integer
- **Description:** Pass a string where an integer is expected.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "hseparation", "value": "4" }`
- **Expected result:** Zod validation error. The schema requires `z.number().int()`, so the string `"4"` should be rejected (Zod does not coerce strings to numbers by default).
- **Notes:** Tests strict type checking.

#### Scenario 14: Invalid value — boolean instead of integer
- **Description:** Pass a boolean where an integer is expected.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "hseparation", "value": true }`
- **Expected result:** Zod validation error. Boolean is not a number.
- **Notes:** —

#### Scenario 15: Invalid value — null
- **Description:** Pass `null` for the value parameter.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "hseparation", "value": null }`
- **Expected result:** Zod validation error. `null` does not satisfy `z.number().int()`.
- **Notes:** —

#### Scenario 16: Invalid value — object
- **Description:** Pass an object where an integer is expected.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "hseparation", "value": { "x": 10 } }`
- **Expected result:** Zod validation error. Object is not a number.
- **Notes:** —

#### Scenario 17: Set constant on a nonexistent theme
- **Description:** Try to set a constant on a theme that does not exist.
- **Params:** `{ "path": "res://themes/ghost_theme.tres", "theme_type": "Button", "name": "hseparation", "value": 4 }`
- **Expected result:** Error from Godot bridge. Theme file not found.
- **Notes:** —

---

## Tool: set_theme_font_size

### Schema

```typescript
{
  description: 'Set a font size in a theme',
  inputSchema: {
    path: ResourcePath,                     // z.string() — "Theme resource path"
    theme_type: z.string(),                 // "Control type"
    name: z.string(),                       // "Size name (e.g. 'font_size')"
    size: z.number().int().positive(),      // "Font size in pixels"
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'theme/set_font_size', args as Record<string, unknown>)
```

### Tool Behavior
Sets a font size override for a specific control type in a Theme. The `size` value is in pixels and must be a positive integer (> 0, enforced by Zod's `.positive()`). Common `name` values include `font_size` (the primary font size), and potentially `normal_font_size`, `bold_font_size`, `italics_font_size`, etc. in custom themes. The `theme_type` specifies which control class the font size applies to.

### Test Scenarios

#### Scenario 1: Happy path — set font size for Button
- **Description:** Set `font_size` for `Button` to a standard 14px.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_size", "size": 14 }`
- **Expected result:** Success. The font size override is written. Verify via `get_theme_info`.
- **Notes:** Requires `test_theme.tres` to exist.

#### Scenario 2: Happy path — set font size for Label
- **Description:** Set `font_size` for `Label` to 16px.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Label", "name": "font_size", "size": 16 }`
- **Expected result:** Success. Different font sizes for different control types.
- **Notes:** —

#### Scenario 3: Happy path — minimum valid size (1px)
- **Description:** Set font size to the smallest allowed positive integer: 1.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_size", "size": 1 }`
- **Expected result:** Success. 1px font size is stored. Godot may render it as unreadably small, but the override should be accepted.
- **Notes:** Tests the lower boundary of the `.positive()` constraint.

#### Scenario 4: Happy path — large font size
- **Description:** Set font size to a very large value (e.g., 512px).
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_size", "size": 512 }`
- **Expected result:** Success. The large value is stored. Godot may clamp the rendered size, but the stored value should be as-provided.
- **Notes:** Tests large value handling. No explicit maximum in schema.

#### Scenario 5: Happy path — overwrite a previously set font size
- **Description:** Change the font size for `Button` from 14 to 20.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_size", "size": 20 }`
- **Expected result:** Success. The new value replaces the old one. Verify via `get_theme_info`.
- **Notes:** Tests idempotency.

#### Scenario 6: Happy path — set font size for Panel
- **Description:** Set `font_size` for `Panel` controls.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Panel", "name": "font_size", "size": 12 }`
- **Expected result:** Success. All three control types now have distinct font size overrides.
- **Notes:** —

#### Scenario 7: Missing required param — no path
- **Description:** Call without the `path` parameter.
- **Params:** `{ "theme_type": "Button", "name": "font_size", "size": 14 }`
- **Expected result:** Zod validation error. `path` is required.
- **Notes:** —

#### Scenario 8: Missing required param — no theme_type
- **Description:** Call without the `theme_type` parameter.
- **Params:** `{ "path": "res://themes/test_theme.tres", "name": "font_size", "size": 14 }`
- **Expected result:** Zod validation error. `theme_type` is required.
- **Notes:** —

#### Scenario 9: Missing required param — no name
- **Description:** Call without the `name` parameter.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "size": 14 }`
- **Expected result:** Zod validation error. `name` is required.
- **Notes:** —

#### Scenario 10: Missing required param — no size
- **Description:** Call without the `size` parameter.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_size" }`
- **Expected result:** Zod validation error. `size` is required.
- **Notes:** —

#### Scenario 11: Invalid size — zero
- **Description:** Pass 0 as the font size.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_size", "size": 0 }`
- **Expected result:** Zod validation error. The schema uses `.positive()` which requires > 0. Zero should be rejected.
- **Notes:** Tests the positive boundary.

#### Scenario 12: Invalid size — negative integer
- **Description:** Pass a negative font size.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_size", "size": -8 }`
- **Expected result:** Zod validation error. Negative numbers fail `.positive()`.
- **Notes:** —

#### Scenario 13: Invalid size — float
- **Description:** Pass a floating-point font size.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_size", "size": 14.5 }`
- **Expected result:** Zod validation error. The schema requires `.int()`, so `14.5` is rejected.
- **Notes:** —

#### Scenario 14: Invalid size — string
- **Description:** Pass a string where a number is expected.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_size", "size": "14" }`
- **Expected result:** Zod validation error. String is not a number (no coercion configured).
- **Notes:** —

#### Scenario 15: Invalid size — boolean
- **Description:** Pass a boolean for the size.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_size", "size": true }`
- **Expected result:** Zod validation error. Boolean is not a number.
- **Notes:** —

#### Scenario 16: Nonexistent theme
- **Description:** Try to set a font size on a theme that does not exist.
- **Params:** `{ "path": "res://themes/imaginary_theme.tres", "theme_type": "Button", "name": "font_size", "size": 14 }`
- **Expected result:** Error from Godot bridge. File not found.
- **Notes:** —

---

## Tool: set_theme_stylebox

### Schema

```typescript
{
  description: 'Set a StyleBox in a theme',
  inputSchema: {
    path: ResourcePath,           // z.string() — "Theme resource path"
    theme_type: z.string(),       // "Control type"
    name: z.string(),             // "StyleBox name (e.g. 'normal', 'hover', 'pressed')"
    properties: Properties,       // z.record(z.unknown()) — "StyleBox properties (e.g. bg_color, border_width)"
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'theme/set_stylebox', args as Record<string, unknown>)
```

### Tool Behavior
Creates or updates a `StyleBox` (typically `StyleBoxFlat`) override for a specific control type in a Theme. The `name` identifies which state/stylebox slot to modify (e.g. `normal`, `hover`, `pressed`, `focus`, `disabled`, `panel`, `grabber`, `slider`, `cursor`, `progress`, `selection`, `bg`, `custom`). The `properties` parameter is a dictionary of StyleBox configuration values. Common properties include `bg_color` (hex string), `border_width_left`, `border_width_right`, `border_width_top`, `border_width_bottom`, `border_color`, `corner_radius_top_left`, `corner_radius_top_right`, `corner_radius_bottom_left`, `corner_radius_bottom_right`, `shadow_size`, `shadow_color`, `content_margin_left`, `content_margin_right`, `content_margin_top`, `content_margin_bottom`, `expand_margin_left`, `expand_margin_right`, `expand_margin_top`, `expand_margin_bottom`, `draw_center`, `anti_aliased`, etc.

### Test Scenarios

#### Scenario 1: Happy path — set a basic StyleBox with bg_color
- **Description:** Create a `normal` StyleBox for `Button` with a background color.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "normal", "properties": { "bg_color": "#4444FF" } }`
- **Expected result:** Success. A StyleBoxFlat is created with the specified background color. Verify via `get_theme_info`.
- **Notes:** Requires `test_theme.tres` to exist.

#### Scenario 2: Happy path — set StyleBox with border and corner radius
- **Description:** Create a StyleBox with multiple properties: border width, border color, and rounded corners.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "normal", "properties": { "bg_color": "#222222", "border_width_left": 2, "border_width_right": 2, "border_width_top": 2, "border_width_bottom": 2, "border_color": "#FF0000", "corner_radius_top_left": 8, "corner_radius_top_right": 8, "corner_radius_bottom_left": 8, "corner_radius_bottom_right": 8 } }`
- **Expected result:** Success. All properties are stored and the StyleBox is configured with rounded corners and a red border.
- **Notes:** Tests that multiple properties can be set in one call.

#### Scenario 3: Happy path — set hover StyleBox
- **Description:** Create a `hover` state StyleBox for `Button`.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "hover", "properties": { "bg_color": "#6666FF" } }`
- **Expected result:** Success. The `hover` StyleBox is separate from `normal`. Both should appear in `get_theme_info`.
- **Notes:** Tests multiple stylebox states for the same control type.

#### Scenario 4: Happy path — set pressed StyleBox
- **Description:** Create a `pressed` state StyleBox for `Button`.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "pressed", "properties": { "bg_color": "#0000AA" } }`
- **Expected result:** Success. Three states (`normal`, `hover`, `pressed`) now have StyleBoxes.
- **Notes:** —

#### Scenario 5: Happy path — set focus StyleBox
- **Description:** Create a `focus` state StyleBox with a distinct border color.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "focus", "properties": { "bg_color": "#4444AA", "border_width_left": 2, "border_width_right": 2, "border_width_top": 2, "border_width_bottom": 2, "border_color": "#FFFF00" } }`
- **Expected result:** Success. The focus state has a yellow border to indicate keyboard focus.
- **Notes:** —

#### Scenario 6: Happy path — set disabled StyleBox
- **Description:** Create a `disabled` state StyleBox with a dimmed appearance.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "disabled", "properties": { "bg_color": "#888888" } }`
- **Expected result:** Success. All five major button states now have StyleBox overrides.
- **Notes:** —

#### Scenario 7: Happy path — set StyleBox for Panel control type
- **Description:** Create a `panel` StyleBox for `Panel` controls.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Panel", "name": "panel", "properties": { "bg_color": "#333333", "border_color": "#555555", "corner_radius_top_left": 4, "corner_radius_top_right": 4, "corner_radius_bottom_left": 4, "corner_radius_bottom_right": 4 } }`
- **Expected result:** Success. The `Panel` type now has a custom `panel` StyleBox.
- **Notes:** Tests non-Button control types.

#### Scenario 8: Happy path — set StyleBox with shadow properties
- **Description:** Create a StyleBox with shadow size and color.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "normal", "properties": { "bg_color": "#4444FF", "shadow_size": 4, "shadow_color": "#00000080" } }`
- **Expected result:** Success. The shadow properties are stored. The button should render with a shadow.
- **Notes:** Tests shadow-related properties.

#### Scenario 9: Happy path — set StyleBox with content margins
- **Description:** Create a StyleBox with internal content margins for text padding.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "normal", "properties": { "bg_color": "#4444FF", "content_margin_left": 16, "content_margin_right": 16, "content_margin_top": 8, "content_margin_bottom": 8 } }`
- **Expected result:** Success. Content margins create internal padding.
- **Notes:** —

#### Scenario 10: Happy path — set StyleBox with expand margins
- **Description:** Create a StyleBox with expand margins that push outside the control's bounding box.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "normal", "properties": { "bg_color": "#4444FF", "expand_margin_left": 2, "expand_margin_right": 2, "expand_margin_top": 2, "expand_margin_bottom": 2 } }`
- **Expected result:** Success. Expand margins are stored.
- **Notes:** —

#### Scenario 11: Happy path — set StyleBox with draw_center and anti_aliased flags
- **Description:** Create a StyleBox with boolean properties.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "normal", "properties": { "bg_color": "#4444FF", "draw_center": true, "anti_aliased": true } }`
- **Expected result:** Success. Boolean properties are accepted.
- **Notes:** Tests that boolean values in the properties record are handled correctly.

#### Scenario 12: Happy path — set StyleBox with empty properties
- **Description:** Create a StyleBox with an empty properties object.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "normal", "properties": {} }`
- **Expected result:** Possibly success (creates a default StyleBox with all defaults) or error if Godot requires at least one property. Verify the behavior.
- **Notes:** Boundary test: empty record is valid per `z.record(z.unknown())` but may be semantically meaningless.

#### Scenario 13: Missing required param — no path
- **Description:** Call without the `path` parameter.
- **Params:** `{ "theme_type": "Button", "name": "normal", "properties": { "bg_color": "#4444FF" } }`
- **Expected result:** Zod validation error. `path` is required.
- **Notes:** —

#### Scenario 14: Missing required param — no theme_type
- **Description:** Call without the `theme_type` parameter.
- **Params:** `{ "path": "res://themes/test_theme.tres", "name": "normal", "properties": { "bg_color": "#4444FF" } }`
- **Expected result:** Zod validation error. `theme_type` is required.
- **Notes:** —

#### Scenario 15: Missing required param — no name
- **Description:** Call without the `name` parameter.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "properties": { "bg_color": "#4444FF" } }`
- **Expected result:** Zod validation error. `name` is required.
- **Notes:** —

#### Scenario 16: Missing required param — no properties
- **Description:** Call without the `properties` parameter.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "normal" }`
- **Expected result:** Zod validation error. `properties` is required (no `.optional()` on the Properties schema used here).
- **Notes:** —

#### Scenario 17: Invalid properties — string instead of object
- **Description:** Pass a string where an object is expected for properties.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "normal", "properties": "bg_color: blue" }`
- **Expected result:** Zod validation error. `z.record(z.unknown())` requires an object.
- **Notes:** —

#### Scenario 18: Invalid properties — array instead of object
- **Description:** Pass an array where an object is expected for properties.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "normal", "properties": ["bg_color", "blue"] }`
- **Expected result:** Zod validation error. Array is not a record.
- **Notes:** —

#### Scenario 19: Invalid properties — null
- **Description:** Pass `null` for properties.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "normal", "properties": null }`
- **Expected result:** Zod validation error. `null` is not a record.
- **Notes:** —

#### Scenario 20: Invalid properties — number instead of object
- **Description:** Pass a number for properties.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "normal", "properties": 42 }`
- **Expected result:** Zod validation error. Number is not a record.
- **Notes:** —

#### Scenario 21: Nonexistent theme
- **Description:** Try to set a StyleBox on a theme that does not exist.
- **Params:** `{ "path": "res://themes/no_theme_here.tres", "theme_type": "Button", "name": "normal", "properties": { "bg_color": "#4444FF" } }`
- **Expected result:** Error from Godot bridge. File not found.
- **Notes:** —

#### Scenario 22: Set StyleBox for custom/non-standard state name
- **Description:** Set a StyleBox with a custom name that is not one of the common states (e.g. `custom_state`).
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "custom_state", "properties": { "bg_color": "#AA00AA" } }`
- **Expected result:** Likely accepted — themes can have arbitrary stylebox names. The override is stored but may not be used automatically by Godot unless referenced manually.
- **Notes:** Tests that the tool does not restrict `name` to a predefined enum.

#### Scenario 23: Set StyleBox with a property name that doesn't exist on StyleBoxFlat
- **Description:** Pass a property that is not a valid StyleBoxFlat property.
- **Params:** `{ "path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "normal", "properties": { "nonexistent_prop": 123, "also_fake": "hello" } }`
- **Expected result:** Possible warning or silent ignore from Godot. The invalid properties may be stored as custom data or rejected. Verify via `get_theme_info`.
- **Notes:** Tests Godot's validation of StyleBox property names.

---

## Tool: get_theme_info

### Schema

```typescript
{
  description: 'Get information about a theme including all its overrides',
  inputSchema: {
    path: ResourcePath,  // z.string() — "Theme resource path"
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'theme/get_info', args as Record<string, unknown>)
```

### Tool Behavior
Reads a Theme resource and returns detailed information about its contents: all overrides organized by control type, including colors, constants, font sizes, and styleboxes. This is the primary read/verification tool for theme operations. Returns a structured object describing the full state of the theme. The response should include sections for each control type that has overrides, listing the property name and value for each override.

### Test Scenarios

#### Scenario 1: Happy path — get info on an empty theme
- **Description:** Read a freshly created theme with no overrides.
- **Params:** `{ "path": "res://themes/test_theme.tres" }`
- **Expected result:** Success. Returns an object indicating the theme exists but has no overrides (or an empty override structure). The response should be valid JSON with the theme metadata.
- **Notes:** Run immediately after `create_theme` and before any `set_theme_*` calls.

#### Scenario 2: Happy path — get info on a theme with overrides
- **Description:** Read a theme after multiple `set_theme_color`, `set_theme_constant`, `set_theme_font_size`, and `set_theme_stylebox` calls have been made.
- **Params:** `{ "path": "res://themes/test_theme.tres" }`
- **Expected result:** Success. Returns a complete override tree with all previously-set values:
  - `Button` type with `font_color`, `font_hover_color`, `font_disabled_color`, `icon_normal_color`, `hseparation`, `vseparation`, `margin_left`, `outline_size`, `font_size`, and StyleBoxes for `normal`, `hover`, `pressed`, `focus`, `disabled`.
  - `Label` type with `font_color` and `font_size`.
  - `Panel` type with `font_color`, `font_size`, and `panel` StyleBox.
  - `HBoxContainer` type with `hseparation`.
  - `PanelContainer` type with `font_color`.
- **Notes:** This is the comprehensive verification scenario. Run after all `set_theme_*` happy-path scenarios.

#### Scenario 3: Happy path — get info validates color override values
- **Description:** Read theme and verify specific color values match what was set.
- **Params:** `{ "path": "res://themes/test_theme.tres" }`
- **Expected result:** `Button.font_color` should be `#FFFFFF` (after overwrite), `Button.font_hover_color` should be `blue`, `Label.font_color` should be `#00FF00` (after overwrite with transparent — verify it's `#00000000`).
- **Notes:** Spot-check specific overrides to ensure values roundtrip correctly.

#### Scenario 4: Happy path — get info validates constant override values
- **Description:** Verify constant values are preserved correctly.
- **Params:** `{ "path": "res://themes/test_theme.tres" }`
- **Expected result:** `Button.hseparation` should be `16` (after overwrite from `4`), `Button.vseparation` should be `8`, `Button.margin_left` should be `99999`, `HBoxContainer.hseparation` should be `12`.
- **Notes:** Ensure integer constants retain their exact values.

#### Scenario 5: Happy path — get info validates font size values
- **Description:** Verify font size overrides.
- **Params:** `{ "path": "res://themes/test_theme.tres" }`
- **Expected result:** `Button.font_size` should be `20` (after overwrite), `Label.font_size` should be `16`, `Panel.font_size` should be `12`.
- **Notes:** —

#### Scenario 6: Happy path — get info validates StyleBox structures
- **Description:** Verify StyleBox overrides include all set properties.
- **Params:** `{ "path": "res://themes/test_theme.tres" }`
- **Expected result:** `Button.normal` should contain `bg_color`, `shadow_size`, `shadow_color`, `content_margin_*`, `expand_margin_*`, `draw_center`, `anti_aliased` (from the cumulative overwrites). `Button.hover` should have `bg_color: #6666FF`. `Button.pressed` should have `bg_color: #0000AA`. `Button.focus` should have border properties. `Button.disabled` should have `bg_color: #888888`. `Panel.panel` should have border, corner radius, and bg_color.
- **Notes:** Comprehensive verification of all StyleBox state.

#### Scenario 7: Missing required param — no path
- **Description:** Call without the `path` parameter.
- **Params:** `{}` (empty object)
- **Expected result:** Zod validation error. `path` is required.
- **Notes:** —

#### Scenario 8: Invalid path — nonexistent theme
- **Description:** Try to get info on a theme that does not exist.
- **Params:** `{ "path": "res://themes/not_a_real_theme.tres" }`
- **Expected result:** Error from Godot bridge. Should return an error indicating the file was not found.
- **Notes:** —

#### Scenario 9: Invalid path — path to a non-theme resource
- **Description:** Try to get theme info from a file that is not a theme (e.g. a scene or script).
- **Params:** `{ "path": "res://scenes/main.tscn" }`
- **Expected result:** Error from Godot. The file is not a Theme resource. Should return a type mismatch error.
- **Notes:** Tests that Godot validates the resource type.

#### Scenario 10: Invalid path — empty string
- **Description:** Call with an empty string.
- **Params:** `{ "path": "" }`
- **Expected result:** Zod validation passes (empty string is a string), but Godot should return an error for an invalid path.
- **Notes:** —

#### Scenario 11: Get info on a default/built-in theme (if accessible)
- **Description:** Try to read a Godot built-in default theme if one is accessible via `res://`.
- **Params:** `{ "path": "res://default_theme.tres" }` (or known internal theme path)
- **Expected result:** If the path exists, returns the default theme structure. If not, returns a file-not-found error. Either outcome is acceptable — the test verifies graceful handling.
- **Notes:** Internal theme paths may vary by Godot version. Use `get_filesystem_tree` first to find a valid theme path if needed.

#### Scenario 12: Repeated calls — verify idempotency
- **Description:** Call `get_theme_info` twice with the same path and compare results.
- **Params (both calls):** `{ "path": "res://themes/test_theme.tres" }`
- **Expected result:** Both calls return identical results (no side effects, no state change between reads).
- **Notes:** Read-only tools should be fully idempotent.

#### Scenario 13: Get info with a path containing URL-encoded characters
- **Description:** Use a path with special characters that would be URL-encoded.
- **Params:** `{ "path": "res://themes/my theme (copy).tres" }`
- **Expected result:** If the file exists, it should be read successfully. The server should properly handle paths with spaces and parentheses.
- **Notes:** Tests path handling for filenames with special characters. Create the file first if needed.

---

## Integration Tests

These scenarios test interactions between multiple theme tools to verify end-to-end workflows.

### Integration Scenario 1: Full theme lifecycle
- **Description:** Create a theme, populate it with multiple override types, verify everything, then delete it.
- **Steps:**
  1. `create_theme` with `{ "path": "res://themes/integration_theme.tres" }` → expect success.
  2. `get_theme_info` with `{ "path": "res://themes/integration_theme.tres" }` → expect empty theme.
  3. `set_theme_color` with `{ "path": "res://themes/integration_theme.tres", "theme_type": "Button", "name": "font_color", "color": "#FF5722" }` → expect success.
  4. `set_theme_constant` with `{ "path": "res://themes/integration_theme.tres", "theme_type": "Button", "name": "hseparation", "value": 6 }` → expect success.
  5. `set_theme_font_size` with `{ "path": "res://themes/integration_theme.tres", "theme_type": "Button", "name": "font_size", "size": 18 }` → expect success.
  6. `set_theme_stylebox` with `{ "path": "res://themes/integration_theme.tres", "theme_type": "Button", "name": "normal", "properties": { "bg_color": "#333333", "corner_radius_top_left": 6, "corner_radius_top_right": 6 } }` → expect success.
  7. `get_theme_info` with `{ "path": "res://themes/integration_theme.tres" }` → expect all four override types present with correct values.
  8. `delete_theme` with `{ "path": "res://themes/integration_theme.tres" }` → expect success.
  9. `get_theme_info` with `{ "path": "res://themes/integration_theme.tres" }` → expect error (file not found).
- **Notes:** End-to-end test covering all 7 theme tools in a single workflow.

### Integration Scenario 2: Modify existing overrides across tool types
- **Description:** Set overrides, then modify them using different tools, verifying each change.
- **Steps:**
  1. Ensure `res://themes/test_theme.tres` exists.
  2. `set_theme_color` → `set_theme_constant` → `set_theme_font_size` for `Label` type.
  3. `get_theme_info` to capture baseline.
  4. Overwrite each Label override with new values using the same tools.
  5. `get_theme_info` to verify all values updated.
  6. `set_theme_stylebox` to add a `normal` StyleBox for `Label`.
  7. `get_theme_info` to verify the StyleBox coexists with the color/constant/font overrides.
- **Notes:** Tests that different override types do not interfere with each other.

### Integration Scenario 3: Cross-control-type isolation
- **Description:** Set the same property name on multiple control types and verify they are stored independently.
- **Steps:**
  1. `set_theme_color` for `Button.font_color` to `#FF0000`.
  2. `set_theme_color` for `Label.font_color` to `#00FF00`.
  3. `set_theme_color` for `Panel.font_color` to `#0000FF`.
  4. `get_theme_info` → verify all three values are distinct and scoped to their respective control types.
- **Notes:** Validates that overrides are properly namespaced by control type.

---

## Test Execution Notes

1. **Order matters:** Scenarios for `set_theme_*` tools depend on `create_theme` having already been run (Scenario 1 of `create_theme`). The `get_theme_info` verification scenarios depend on prior `set_theme_*` calls.

2. **Run the setup first:** Execute `create_theme` Scenario 1 before any other theme modification tests.

3. **Clean up at end:** Run `delete_theme` Scenario 1 as the final step to remove test artifacts.

4. **Isolation:** For destructive scenarios (e.g., deleting a referenced theme), create a separate disposable theme file (e.g., `res://themes/temp_delete_test.tres`).

5. **Godot version:** Some behaviors (especially color format parsing and property validation) may vary between Godot 4.x versions. Note the Godot version in test results.

6. **Console monitoring:** Check `read_console` after each tool call, especially for `set_theme_*` operations that push invalid values, as Godot may emit warnings to the output log without returning an error to the tool.

7. **FileSystem refresh:** After `create_theme` or `delete_theme`, the Godot FileSystem dock may need a moment to refresh. Use `reload_project` if file changes are not immediately visible.

8. **Theme file format:** `.tres` files are plain text. You can also verify theme contents by reading the raw file with `get_scene_file_content` or directly inspecting the file on disk.
