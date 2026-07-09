# Test Plan: editor_config.ts — 9 Editor Configuration Tools

> **Source**: `server/src/tools/editor_config.ts`
> **Shared types**: `server/src/tools/shared-types.ts`
> **Bridge method prefix**: `editor_config/`
> **Bridge helper**: `callGodot(bridge, method, args)` from `server.ts`

## Overview

This module exposes 9 MCP tools for reading and modifying Godot editor appearance and layout settings. All mutation tools forward through `callGodot(bridge, 'editor_config/<action>', args)` to the Godot editor plugin via WebSocket. The `Name` type used by `save_editor_layout`, `load_editor_layout`, and `delete_editor_layout` is `z.string()` — a plain string with no additional constraints.

### Tool Inventory

| # | Tool Name | Parameters | Bridge Method |
|---|-----------|-----------|---------------|
| 1 | `get_editor_settings` | none | `editor_config/get_settings` |
| 2 | `set_editor_theme` | `theme` (enum) | `editor_config/set_theme` |
| 3 | `set_editor_layout` | `layout` (enum) | `editor_config/set_layout` |
| 4 | `set_font_size` | `size` (int 8–48) | `editor_config/set_font_size` |
| 5 | `set_editor_scale` | `scale` (number 0.5–3.0) | `editor_config/set_scale` |
| 6 | `save_editor_layout` | `name` (string) | `editor_config/save_layout` |
| 7 | `load_editor_layout` | `name` (string) | `editor_config/load_layout` |
| 8 | `reset_editor_layout` | none | `editor_config/reset_layout` |
| 9 | `delete_editor_layout` | `name` (string) | `editor_config/delete_layout` |

### Inter-Tool Dependencies

| Tool | Depends On | Reason |
|------|-----------|--------|
| `get_editor_settings` | `set_editor_theme`, `set_font_size`, `set_editor_scale` | Read after mutation to verify changes took effect |
| `set_editor_theme` | `get_editor_settings` | Verify current theme before changing |
| `set_editor_layout` | `get_editor_settings` | Verify current layout before switching |
| `set_font_size` | `get_editor_settings` | Verify current font size before changing |
| `set_editor_scale` | `get_editor_settings` | Verify current scale before changing |
| `save_editor_layout` | `set_editor_layout` | Arrange a specific layout state before saving |
| `load_editor_layout` | `save_editor_layout` | Must have a saved layout before loading it |
| `reset_editor_layout` | `save_editor_layout` or any layout mutation | Test that reset actually reverts changes |
| `delete_editor_layout` | `save_editor_layout` | Must have a saved layout before deleting it |

### Recommended Execution Order

1. `get_editor_settings` — baseline read of all current settings
2. `set_editor_theme` — change theme, then `get_editor_settings` to verify
3. `set_editor_layout` — switch layout, then `get_editor_settings` to verify
4. `set_font_size` — change font size, then `get_editor_settings` to verify
5. `set_editor_scale` — change scale, then `get_editor_settings` to verify
6. `set_editor_layout` (to `"script"`) — arrange state for save
7. `save_editor_layout` — save current layout under a test name
8. `load_editor_layout` — load the saved layout (verify it restores)
9. `reset_editor_layout` — reset to factory defaults, then `get_editor_settings` to verify
10. `load_editor_layout` — attempt to load after reset (may still work if saved)
11. `delete_editor_layout` — delete the saved layout, then `load_editor_layout` to verify it's gone

---

## Tool: `get_editor_settings`

**Description**: Get all editor settings (theme, layout, font, scale, etc.)

**Parameters**: None (`inputSchema: {}`)

**Bridge call**: `editor_config/get_settings`

**Expected return structure**:
```json
{
  "content": [{ "type": "text", "text": "<JSON string>" }]
}
```
The text content should be a JSON object containing editor settings — at minimum keys related to theme, layout, font size, and UI scale.

### Test Scenarios

#### 1.1 — Happy path: retrieve all editor settings

- **Description**: Call with no params, verify a non-error response with editor settings is returned.
- **Params**: `{}`
- **Expected result**: `isError` is absent or `false`. Response `content[0].text` is a JSON string containing an object with editor configuration keys (theme, layout, font size, scale, or equivalent).
- **Notes**: This is the baseline read — all subsequent mutation tests depend on this working.
- **Attention**: Verify the response is parseable JSON (not a raw error string). Check that at least one recognizable editor setting key is present. If the Godot editor is not connected, this will return an error — ensure the bridge is active.

#### 1.2 — Verify response structure after theme mutation

- **Description**: After calling `set_editor_theme` with `"light"`, call `get_editor_settings` and verify the theme field reflects the change.
- **Params**: `{}`
- **Expected result**: The settings object should show the theme as `"light"` (or equivalent field).
- **Notes**: Depends on scenario 2.1 having been executed first.
- **Attention**: Field name for theme may differ from the tool param name — the Godot plugin may return `"color_theme"`, `"theme"`, or another key. Inspect the actual response shape.

---

## Tool: `set_editor_theme`

**Description**: Set the editor color theme

**Parameters**:

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `theme` | `string` (enum) | **yes** | — | `"dark"`, `"light"`, `"amoled"` | Editor theme preset |

**Bridge call**: `editor_config/set_theme`

**Handler logic**: Forwards `{ theme }` to Godot plugin which applies the corresponding editor theme preset.

### Test Scenarios

#### 2.1 — Happy path: set theme to "dark"

- **Description**: Set theme to `"dark"`, verify success.
- **Params**: `{ "theme": "dark" }`
- **Expected result**: `isError` is absent or `false`. Response indicates success.
- **Notes**: This is the most common theme. Good baseline test.
- **Attention**: Verify the response confirms the theme was applied. Check if the response includes the new theme value or just a success indicator.

#### 2.2 — Set theme to "light"

- **Description**: Switch to light theme.
- **Params**: `{ "theme": "light" }`
- **Expected result**: `isError` is absent or `false`. Follow up with `get_editor_settings` to verify theme changed.
- **Notes**: Tests a second valid enum value.
- **Attention**: If the editor was already in light theme, the tool should still succeed (idempotent).

#### 2.3 — Set theme to "amoled"

- **Description**: Switch to AMOLED (pure black) theme.
- **Params**: `{ "theme": "amoled" }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: Tests the third enum value. AMOLED is less commonly used — verify it exists in the target Godot version.
- **Attention**: Some Godot versions may not have an AMOLED theme built in. If the plugin maps this to a custom theme, it may fail on vanilla Godot — check for error in that case.

#### 2.4 — Edge case: missing required `theme` parameter

- **Description**: Call with empty object, verify error.
- **Params**: `{}`
- **Expected result**: `isError` is `true` or the MCP SDK rejects the call before it reaches the handler (Zod validation error). Error message should indicate `theme` is required.
- **Notes**: This tests the MCP framework's input validation via Zod schema.
- **Attention**: The error may come from the MCP SDK layer (before the handler) or from the Godot plugin. Check which layer produces the validation error.

#### 2.5 — Edge case: invalid enum value for `theme`

- **Description**: Call with a value not in the enum.
- **Params**: `{ "theme": "neon" }`
- **Expected result**: `isError` is `true` or MCP SDK rejects. Error should indicate invalid enum value.
- **Notes**: Zod enum validation should catch this before it reaches the handler.
- **Attention**: Verify the error message is descriptive — it should list the allowed values.

#### 2.6 — Edge case: wrong type for `theme`

- **Description**: Pass a number instead of string.
- **Params**: `{ "theme": 123 }`
- **Expected result**: `isError` is `true`. Zod should reject because `theme` expects a string enum.
- **Notes**: Type coercion — Zod enums do not coerce by default.
- **Attention**: Some Zod configs may coerce numbers to strings. If `"123"` passes validation, the Godot plugin will likely reject it as an unknown theme.

---

## Tool: `set_editor_layout`

**Description**: Switch the editor to a specific workspace layout

**Parameters**:

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `layout` | `string` (enum) | **yes** | — | `"default"`, `"2d"`, `"3d"`, `"script"` | Editor layout preset to activate |

**Bridge call**: `editor_config/set_layout`

**Handler logic**: Forwards `{ layout }` to Godot plugin which switches the editor workspace to the named preset.

### Test Scenarios

#### 3.1 — Happy path: switch to "2d" layout

- **Description**: Switch to 2D workspace.
- **Params**: `{ "layout": "2d" }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: 2D layout is the most commonly used layout for 2D game development.
- **Attention**: Verify the editor actually switched — follow up with `get_editor_settings` if it reports current layout.

#### 3.2 — Switch to "3d" layout

- **Description**: Switch to 3D workspace.
- **Params**: `{ "layout": "3d" }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: Tests a second valid enum value.

#### 3.3 — Switch to "script" layout

- **Description**: Switch to script editor workspace.
- **Params**: `{ "layout": "script" }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: This layout emphasizes the script editor panel.

#### 3.4 — Switch to "default" layout

- **Description**: Switch back to default workspace.
- **Params**: `{ "layout": "default" }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: Tests the fourth enum value. Good for resetting after other layout tests.

#### 3.5 — Edge case: missing required `layout` parameter

- **Description**: Call with empty object.
- **Params**: `{}`
- **Expected result**: `isError` is `true` or MCP SDK rejects. Error indicates `layout` is required.
- **Notes**: Zod validation.

#### 3.6 — Edge case: invalid layout value

- **Description**: Pass an unsupported layout name.
- **Params**: `{ "layout": "animation" }`
- **Expected result**: `isError` is `true`. Zod enum rejects `"animation"` as it is not in `['default', '2d', '3d', 'script']`.
- **Notes**: Tests enum boundary.

---

## Tool: `set_font_size`

**Description**: Set the editor font size in pixels

**Parameters**:

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `size` | `number` (integer) | **yes** | — | min: `8`, max: `48` | Font size in pixels |

**Zod schema**: `z.number().int().min(8).max(48)`

**Bridge call**: `editor_config/set_font_size`

**Handler logic**: Forwards `{ size }` to Godot plugin which sets the editor font size.

### Test Scenarios

#### 4.1 — Happy path: set font size to 16

- **Description**: Set a standard font size.
- **Params**: `{ "size": 16 }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: 16px is a common default. Follow up with `get_editor_settings` to verify.
- **Attention**: Verify the response confirms the size was applied.

#### 4.2 — Set font size to minimum (8)

- **Description**: Set to the minimum allowed value.
- **Params**: `{ "size": 8 }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: Boundary test — minimum valid integer.

#### 4.3 — Set font size to maximum (48)

- **Description**: Set to the maximum allowed value.
- **Params**: `{ "size": 48 }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: Boundary test — maximum valid integer.

#### 4.4 — Set font size to a mid-range value (24)

- **Description**: Set to a mid-range value.
- **Params**: `{ "size": 24 }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: Verifies non-boundary integer works.

#### 4.5 — Edge case: font size below minimum (7)

- **Description**: Pass value below the min constraint.
- **Params**: `{ "size": 7 }`
- **Expected result**: `isError` is `true`. Zod `.min(8)` should reject.
- **Notes**: Tests lower boundary enforcement.

#### 4.6 — Edge case: font size above maximum (49)

- **Description**: Pass value above the max constraint.
- **Params**: `{ "size": 49 }`
- **Expected result**: `isError` is `true`. Zod `.max(48)` should reject.
- **Notes**: Tests upper boundary enforcement.

#### 4.7 — Edge case: floating point font size (14.5)

- **Description**: Pass a non-integer number.
- **Params**: `{ "size": 14.5 }`
- **Expected result**: `isError` is `true`. Zod `.int()` should reject.
- **Notes**: The schema requires an integer — floats must be rejected.

#### 4.8 — Edge case: negative font size

- **Description**: Pass a negative number.
- **Params**: `{ "size": -10 }`
- **Expected result**: `isError` is `true`. Zod `.min(8)` rejects negative values.
- **Notes**: Tests that negative values are caught.

#### 4.9 — Edge case: missing required `size` parameter

- **Description**: Call with empty object.
- **Params**: `{}`
- **Expected result**: `isError` is `true` or MCP SDK rejects.
- **Notes**: Zod validation.

#### 4.10 — Edge case: wrong type (string instead of number)

- **Description**: Pass a string value.
- **Params**: `{ "size": "sixteen" }`
- **Expected result**: `isError` is `true`. Zod `.number()` rejects strings without coercion.
- **Notes**: Type validation.

---

## Tool: `set_editor_scale`

**Description**: Set the editor UI scale factor

**Parameters**:

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `scale` | `number` | **yes** | — | min: `0.5`, max: `3.0` | UI scale factor (1.0 = 100%) |

**Zod schema**: `z.number().min(0.5).max(3.0)`

**Bridge call**: `editor_config/set_scale`

**Handler logic**: Forwards `{ scale }` to Godot plugin which sets the editor UI scale factor.

### Test Scenarios

#### 5.1 — Happy path: set scale to 1.0 (100%)

- **Description**: Set standard scale.
- **Params**: `{ "scale": 1.0 }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: 1.0 is the default/standard scale. Follow up with `get_editor_settings` to verify.

#### 5.2 — Set scale to 1.5 (150%)

- **Description**: Set a larger scale for HiDPI.
- **Params**: `{ "scale": 1.5 }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: Common value for 1440p or 4K displays.

#### 5.3 — Set scale to minimum (0.5)

- **Description**: Set to the minimum allowed value.
- **Params**: `{ "scale": 0.5 }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: Boundary test — minimum valid float. 50% scale makes the editor very small.

#### 5.4 — Set scale to maximum (3.0)

- **Description**: Set to the maximum allowed value.
- **Params**: `{ "scale": 3.0 }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: Boundary test — maximum valid float. 300% scale.

#### 5.5 — Set scale to 2.0 (200%)

- **Description**: Set to a round number in the upper range.
- **Params**: `{ "scale": 2.0 }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: Common HiDPI scale factor.

#### 5.6 — Edge case: scale below minimum (0.4)

- **Description**: Pass value below the min constraint.
- **Params**: `{ "scale": 0.4 }`
- **Expected result**: `isError` is `true`. Zod `.min(0.5)` should reject.
- **Notes**: Tests lower boundary enforcement.

#### 5.7 — Edge case: scale above maximum (3.5)

- **Description**: Pass value above the max constraint.
- **Params**: `{ "scale": 3.5 }`
- **Expected result**: `isError` is `true`. Zod `.max(3.0)` should reject.
- **Notes**: Tests upper boundary enforcement.

#### 5.8 — Edge case: scale of zero

- **Description**: Pass zero.
- **Params**: `{ "scale": 0 }`
- **Expected result**: `isError` is `true`. Zod `.min(0.5)` rejects.
- **Notes**: Zero scale would make the editor invisible.

#### 5.9 — Edge case: negative scale

- **Description**: Pass a negative number.
- **Params**: `{ "scale": -1.0 }`
- **Expected result**: `isError` is `true`. Zod `.min(0.5)` rejects.
- **Notes**: Negative scale is nonsensical.

#### 5.10 — Edge case: missing required `scale` parameter

- **Description**: Call with empty object.
- **Params**: `{}`
- **Expected result**: `isError` is `true` or MCP SDK rejects.
- **Notes**: Zod validation.

#### 5.11 — Edge case: wrong type (string)

- **Description**: Pass a string instead of number.
- **Params**: `{ "scale": "1.5" }`
- **Expected result**: `isError` is `true` (unless Zod coerces). If coerced, the tool may succeed — verify the Godot side handles string-to-number conversion.
- **Notes**: Zod `.number()` does not coerce by default, but some MCP integrations may enable coercion.

---

## Tool: `save_editor_layout`

**Description**: Save the current editor layout under a name

**Parameters**:

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `name` | `string` | **yes** | — | `Name` = `z.string()` (no additional constraints) | Layout name to save as |

**Zod schema**: `z.string()` (imported as `Name` from shared-types)

**Bridge call**: `editor_config/save_layout`

**Handler logic**: Forwards `{ name }` to Godot plugin which saves the current editor window layout (panel positions, sizes, which panels are open) under the given name.

### Test Scenarios

#### 6.1 — Happy path: save layout with a simple name

- **Description**: Save the current layout under a descriptive name.
- **Params**: `{ "name": "my_custom_layout" }`
- **Expected result**: `isError` is absent or `false`. Response confirms the layout was saved.
- **Notes**: Prerequisite: arrange the editor in a known state first (e.g., switch to `"script"` layout via `set_editor_layout`). Follow up with `load_editor_layout` to verify it can be restored.
- **Attention**: The Godot plugin may store layouts in EditorSettings or a project file. Verify where the layout is persisted.

#### 6.2 — Save layout with a different name

- **Description**: Save under a second name to test multiple saved layouts.
- **Params**: `{ "name": "debug_workspace" }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: Tests that multiple named layouts can coexist.

#### 6.3 — Save layout with special characters in name

- **Description**: Test name with spaces, hyphens, underscores.
- **Params**: `{ "name": "my-layout v2.0" }`
- **Expected result**: `isError` is absent or `false` (string has no constraints beyond being a string). If the Godot plugin has restrictions on layout names, it may return an error.
- **Notes**: The Zod schema is just `z.string()` — no character restrictions at the MCP layer. The Godot plugin may impose its own restrictions.
- **Attention**: If this fails, document the actual character restrictions enforced by the plugin.

#### 6.4 — Edge case: empty string name

- **Description**: Pass an empty string.
- **Params**: `{ "name": "" }`
- **Expected result**: Depends on the Godot plugin. Zod `z.string()` allows empty strings. The plugin may reject it with an error like "name cannot be empty".
- **Notes**: At the MCP validation layer this passes. The plugin is the boundary that should enforce non-empty names.
- **Attention**: If the plugin accepts empty strings, it may overwrite a default layout or create a nameless entry — verify behavior.

#### 6.5 — Edge case: missing required `name` parameter

- **Description**: Call with empty object.
- **Params**: `{}`
- **Expected result**: `isError` is `true` or MCP SDK rejects.
- **Notes**: Zod validation.

#### 6.6 — Edge case: overwrite existing layout name

- **Description**: Save to a name that was already saved.
- **Params**: `{ "name": "my_custom_layout" }` (after scenario 6.1)
- **Expected result**: `isError` is absent or `false`. The existing layout should be overwritten silently.
- **Notes**: This tests idempotency — saving to the same name twice should not error.
- **Attention**: Verify whether the plugin confirms overwrite or silently replaces.

---

## Tool: `load_editor_layout`

**Description**: Load a previously saved editor layout

**Parameters**:

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `name` | `string` | **yes** | — | `Name` = `z.string()` (no additional constraints) | Layout name to load |

**Zod schema**: `z.string()` (imported as `Name` from shared-types)

**Bridge call**: `editor_config/load_layout`

**Handler logic**: Forwards `{ name }` to Godot plugin which restores the editor layout previously saved under that name.

### Test Scenarios

#### 7.1 — Happy path: load a previously saved layout

- **Description**: Load the layout saved in scenario 6.1.
- **Params**: `{ "name": "my_custom_layout" }`
- **Expected result**: `isError` is absent or `false`. The editor layout changes to match the saved state.
- **Notes**: Prerequisite: `save_editor_layout` with `"my_custom_layout"` must have been called first.
- **Attention**: Verify the editor visually or via `get_editor_settings` that the layout was restored. Panel positions and open panels should match the saved state.

#### 7.2 — Load a different saved layout

- **Description**: Load the layout saved in scenario 6.2.
- **Params**: `{ "name": "debug_workspace" }`
- **Expected result**: `isError` is absent or `false`.
- **Notes**: Tests loading a second saved layout.

#### 7.3 — Edge case: load a non-existent layout name

- **Description**: Attempt to load a layout that was never saved.
- **Params**: `{ "name": "nonexistent_layout_12345" }`
- **Expected result**: `isError` is `true`. The Godot plugin should return an error indicating the layout was not found.
- **Notes**: This is a critical error-handling test. The MCP Zod layer allows the string, but the plugin must reject unknown layout names.
- **Attention**: Verify the error message is descriptive — it should mention the name that was not found.

#### 7.4 — Edge case: empty string name

- **Description**: Pass an empty string.
- **Params**: `{ "name": "" }`
- **Expected result**: `isError` is `true` (plugin should reject empty name). Zod allows it.
- **Notes**: Same as 6.4 — the plugin is the validation boundary.

#### 7.5 — Edge case: missing required `name` parameter

- **Description**: Call with empty object.
- **Params**: `{}`
- **Expected result**: `isError` is `true` or MCP SDK rejects.
- **Notes**: Zod validation.

#### 7.6 — Load layout after reset

- **Description**: After `reset_editor_layout`, attempt to load a previously saved layout.
- **Params**: `{ "name": "my_custom_layout" }`
- **Expected result**: `isError` is absent or `false` — saved layouts should persist across resets (reset affects the current layout, not saved presets).
- **Notes**: Tests that `reset_editor_layout` does not delete saved layout presets.
- **Attention**: If this fails, it means reset also clears saved layouts — document this behavior as a potential issue.

---

## Tool: `reset_editor_layout`

**Description**: Reset the editor layout to factory defaults

**Parameters**: None (`inputSchema: {}`)

**Bridge call**: `editor_config/reset_layout`

**Handler logic**: Calls Godot plugin with no arguments. The plugin resets all editor layout panels to their factory default positions and visibility.

### Test Scenarios

#### 8.1 — Happy path: reset layout to defaults

- **Description**: After modifying the layout (e.g., switching to `"script"` layout), reset to defaults.
- **Params**: `{}`
- **Expected result**: `isError` is absent or `false`. Response confirms reset.
- **Notes**: Prerequisite: first call `set_editor_layout` to change from default, then reset. Follow up with `get_editor_settings` to verify the layout is back to default.
- **Attention**: Verify the editor visually — all panels should return to their factory positions.

#### 8.2 — Reset when already at defaults

- **Description**: Call reset when the layout is already at factory defaults.
- **Params**: `{}`
- **Expected result**: `isError` is absent or `false`. Should be idempotent — no error even if already at defaults.
- **Notes**: Tests idempotency of reset.

#### 8.3 — Reset after saving a custom layout

- **Description**: Save a custom layout, then reset. Verify saved layout still exists.
- **Params**: `{}`
- **Expected result**: `isError` is absent or `false`. Follow up with `load_editor_layout` using the saved name — it should still work.
- **Notes**: This confirms reset does not delete saved presets. Depends on `save_editor_layout` having been called first.

---

## Tool: `delete_editor_layout`

**Description**: Delete a saved editor layout from disk

**Parameters**:

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `name` | `string` | **yes** | — | `Name` = `z.string()` (no additional constraints) | Layout name to delete |

**Zod schema**: `z.string()` (imported as `Name` from shared-types)

**Bridge call**: `editor_config/delete_layout`

**Handler logic**: Forwards `{ name }` to Godot plugin which removes the saved layout config file from `user://`.

### Test Scenarios

#### 9.1 — Happy path: delete a previously saved layout

- **Description**: Save a layout, then delete it.
- **Params**: `{ "name": "layout_to_delete" }`
- **Expected result**: `isError` is absent or `false`. Response confirms the layout was deleted.
- **Notes**: Prerequisite: `save_editor_layout` with `"layout_to_delete"` must have been called first. Follow up with `load_editor_layout` to verify the layout no longer exists.
- **Attention**: Verify the config file was actually removed from `user://`.

#### 9.2 — Verify deleted layout cannot be loaded

- **Description**: After deleting a layout, attempt to load it.
- **Params**: `{ "name": "layout_to_delete" }`
- **Expected result**: `isError` is `true`. The Godot plugin should return an error indicating the layout was not found.
- **Notes**: Depends on scenario 9.1 having been executed first. This confirms the delete actually removed the file.

#### 9.3 — Edge case: delete a non-existent layout name

- **Description**: Attempt to delete a layout that was never saved.
- **Params**: `{ "name": "nonexistent_layout_12345" }`
- **Expected result**: `isError` is `true`. The Godot plugin should return an error indicating the layout was not found.
- **Notes**: Tests error handling for missing layouts.

#### 9.4 — Edge case: empty string name

- **Description**: Pass an empty string.
- **Params**: `{ "name": "" }`
- **Expected result**: `isError` is `true` (plugin should reject empty name). Zod allows it.
- **Notes**: Same as 6.4 and 7.4 — the plugin is the validation boundary.

#### 9.5 — Edge case: missing required `name` parameter

- **Description**: Call with empty object.
- **Params**: `{}`
- **Expected result**: `isError` is `true` or MCP SDK rejects.
- **Notes**: Zod validation.

#### 9.6 — Delete does not affect other saved layouts

- **Description**: Save two layouts, delete one, verify the other still exists.
- **Params**: `{ "name": "layout_a" }` (after saving both `"layout_a"` and `"layout_b"`)
- **Expected result**: `isError` is absent or `false`. Follow up with `load_editor_layout` using `"layout_b"` — it should still work.
- **Notes**: Tests that delete is scoped to the named layout only.

#### 9.7 — Delete then re-save with same name

- **Description**: Delete a layout, then save a new layout with the same name.
- **Params**: `{ "name": "recycled_name" }` (delete), then `save_editor_layout` with `"recycled_name"`
- **Expected result**: Both operations succeed. The new layout should be loadable.
- **Notes**: Tests that delete fully cleans up the file so a fresh save works.

#### 9.8 — Double delete (idempotency)

- **Description**: Delete a layout, then attempt to delete it again.
- **Params**: `{ "name": "layout_to_delete" }` (after already deleting it)
- **Expected result**: `isError` is `true`. The second delete should fail with "Layout not found".
- **Notes**: Tests that delete is not idempotent — it errors on missing files rather than silently succeeding.

---

## Cross-Tool Integration Scenarios

### I.1 — Full round-trip: theme + layout + font + scale + save + load + reset

**Sequence**:
1. `get_editor_settings` → record baseline
2. `set_editor_theme` → `{ "theme": "amoled" }`
3. `set_editor_layout` → `{ "layout": "script" }`
4. `set_font_size` → `{ "size": 20 }`
5. `set_editor_scale` → `{ "scale": 1.25 }`
6. `get_editor_settings` → verify all 4 changes applied
7. `save_editor_layout` → `{ "name": "integration_test" }`
8. `set_editor_theme` → `{ "theme": "dark" }`
9. `set_editor_layout` → `{ "layout": "default" }`
10. `set_font_size` → `{ "size": 14 }`
11. `set_editor_scale` → `{ "scale": 1.0 }`
12. `get_editor_settings` → verify changed away from saved state
13. `load_editor_layout` → `{ "name": "integration_test" }`
14. `get_editor_settings` → verify restored to saved state (amoled, script, 20, 1.25)
15. `reset_editor_layout` → `{}`
16. `get_editor_settings` → verify back to factory defaults
17. `load_editor_layout` → `{ "name": "integration_test" }` → expect success (saved layouts persist across resets)
18. `delete_editor_layout` → `{ "name": "integration_test" }`
19. `load_editor_layout` → `{ "name": "integration_test" }` → expect error (layout deleted)
20. `get_editor_settings` → verify saved_layouts no longer contains "integration_test"

**Expected**: Every step succeeds (no `isError`) except step 19 which must fail. Steps 6 and 14 show the mutations took effect. Step 16 shows reset reverted everything. Step 18 confirms delete succeeds. Step 19 confirms the layout no longer exists.

**Attention**: Steps 14, 16, and 19 are the critical assertions. If the layout save/load does not persist theme/font/scale (only panel positions), document which settings are included in a "layout" and which are not.

### I.2 — Error isolation: one invalid call does not break subsequent valid calls

**Sequence**:
1. `set_editor_theme` → `{ "theme": "invalid_theme" }` → expect error
2. `set_editor_theme` → `{ "theme": "dark" }` → expect success
3. `set_font_size` → `{ "size": 999 }` → expect error
4. `set_font_size` → `{ "size": 16 }` → expect success

**Expected**: Steps 1 and 3 fail with `isError: true`. Steps 2 and 4 succeed. The bridge/server does not get into a broken state from prior errors.

### I.3 — Concurrent-safe: rapid successive mutations

**Sequence**:
1. `set_editor_theme` → `{ "theme": "light" }`
2. `set_editor_theme` → `{ "theme": "dark" }`
3. `set_editor_theme` → `{ "theme": "amoled" }`
4. `get_editor_settings` → verify final theme is `"amoled"`

**Expected**: All calls succeed. The final state reflects the last mutation (last-write-wins).

**Attention**: If the bridge serializes requests, this tests ordering. If it does not serialize, there may be race conditions — document if the final state is unpredictable.
