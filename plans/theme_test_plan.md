# Theme Tools Test Plan

> **Source**: `server/src/tools/theme.ts` (11 tools)
> **Shared types**: `server/src/tools/shared-types.ts`
> **Bridge call**: `callGodot(bridge, 'theme/<action>', args)` — forwards to Godot via WebSocket, returns `ToolResult { content: [{ type: 'text', text }] }`

---

## Table of Contents

1. [create_theme](#tool-create_theme)
2. [delete_theme](#tool-delete_theme)
3. [set_theme_color](#tool-set_theme_color)
4. [set_theme_constant](#tool-set_theme_constant)
5. [set_theme_font_size](#tool-set_theme_font_size)
6. [set_theme_stylebox](#tool-set_theme_stylebox)
7. [get_theme_info](#tool-get_theme_info)
8. [get_theme_color](#tool-get_theme_color)
9. [get_theme_constant](#tool-get_theme_constant)
10. [get_theme_font_size](#tool-get_theme_font_size)
11. [get_theme_stylebox](#tool-get_theme_stylebox)

---

## Recommended Test Execution Order

Theme tools have dependencies on the theme resource existing. Execute in this order for a clean integration flow:

```
 1. create_theme          — create a theme resource file
 2. get_theme_info        — verify empty theme was created
 3. set_theme_color       — add a color override
 4. set_theme_constant    — add a constant override
 5. set_theme_font_size   — add a font size override
 6. set_theme_stylebox    — add a stylebox override
 7. get_theme_info        — verify all overrides were applied
 8. get_theme_color       — read back the color value
 9. get_theme_constant    — read back the constant value
10. get_theme_font_size   — read back the font size value
11. get_theme_stylebox    — read back the stylebox value
12. delete_theme          — cleanup
13. get_theme_info        — confirm theme is gone (expect error)
```

**Prerequisites**:
- A Godot project must be open with the MCP plugin active
- The Godot editor must be connected via WebSocket bridge
- For `set_theme_*` tools: a theme resource must already exist (create it with `create_theme` first)

**Cleanup**: Always `delete_theme` after testing to avoid leaving test artifacts in the project.

---

## Tool: `create_theme`

**Description**: Create a new Theme resource
**Godot method**: `theme/create`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (ResourcePath) | **yes** | — | File path to save the theme (e.g. `res://themes/dark.tres`) |

### Test Scenarios

#### Scenario 1: Create theme with valid res:// path (happy path)

**Description**: Create a new theme at a standard resource path with `.tres` extension.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres"
}
```

**Expected result**: Success. Response should NOT contain `isError: true`. A theme file is created at `res://themes/test_theme.tres`. Verify via `get_theme_info` that the theme exists and has no overrides (empty theme).

**Notes**: The simplest valid call. After this, you can use the path for all `set_theme_*` operations.

---

#### Scenario 2: Create theme with nested directory path

**Description**: Create a theme in a deeply nested directory structure. Godot should create intermediate directories if they don't exist.

**Call**:
```json
{
  "path": "res://themes/ui/dark/modern_theme.tres"
}
```

**Expected result**: Success. Theme file created at the nested path. Verify with `get_theme_info`.

**Notes**: If the Godot-side handler doesn't create directories, this will fail. Document actual behavior — some Godot resource creation methods require the directory to already exist.

---

#### Scenario 3: Missing required `path` parameter

**Description**: Call without the required `path` field.

**Call**:
```json
{}
```

**Expected result**: Error. The MCP SDK should reject this at the Zod schema validation level before reaching Godot. Response should contain `isError: true` with a message about missing `path`.

**Notes**: Tests Zod schema enforcement on the TypeScript side. The `ResourcePath` schema is `z.string()` which is required (not optional).

---

#### Scenario 4: Empty string path

**Description**: Pass an empty string as the path.

**Call**:
```json
{
  "path": ""
}
```

**Expected result**: Error. The Zod schema (`z.string()`) accepts empty strings at the TypeScript level, so the request will reach Godot. The Godot side should reject an empty path as invalid. Response should contain `isError: true`.

**Notes**: Boundary condition. If this succeeds, it's a bug — an empty path cannot be a valid resource location. Document the exact error message.

---

#### Scenario 5: Path without `.tres` extension

**Description**: Provide a path without the standard Godot resource extension.

**Call**:
```json
{
  "path": "res://themes/test_no_ext"
}
```

**Expected result**: Likely succeeds on the TypeScript side (ResourcePath is `z.string()`). The Godot side may auto-append `.tres` or may create the file as-is. Document actual behavior.

**Notes**: Edge case to document. If Godot auto-appends the extension, subsequent calls referencing `res://themes/test_no_ext` (without `.tres`) may fail. If it doesn't, the file may not be loadable by Godot later.

---

#### Scenario 6: Path with special characters

**Description**: Test theme creation with spaces and special characters in the path.

**Call**:
```json
{
  "path": "res://themes/my theme (v2).tres"
}
```

**Expected result**: Depends on Godot's path handling. Godot may accept or reject paths with spaces/parentheses. Document actual behavior.

**Notes**: If this fails, the error should indicate the path is invalid. This tests robustness of path handling.

---

## Tool: `delete_theme`

**Description**: Delete a theme resource file from the project
**Godot method**: `theme/delete`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (z.string()) | **yes** | — | Theme file path to delete (e.g. `res://themes/my_theme.tres`) |

### Test Scenarios

#### Scenario 1: Delete an existing theme (happy path)

**Description**: Create a theme first, then delete it. This is a two-step flow.

**Prerequisites**: Run `create_theme` with `{"path": "res://themes/to_delete.tres"}` first.

**Call**:
```json
{
  "path": "res://themes/to_delete.tres"
}
```

**Expected result**: Success. The theme file is removed from the project. Response should NOT contain `isError: true`.

**Notes**: After deletion, calling `get_theme_info` with the same path should return an error (file not found).

---

#### Scenario 2: Delete a non-existent theme

**Description**: Attempt to delete a theme that was never created.

**Call**:
```json
{
  "path": "res://themes/does_not_exist.tres"
}
```

**Expected result**: Error. Response should contain `isError: true` with a message indicating the file was not found.

**Notes**: Tests error handling for missing resources. The Godot side should handle this gracefully rather than crashing.

---

#### Scenario 3: Delete a theme that is referenced by UI nodes

**Description**: Create a theme, assign it to a Control node, then try to delete the theme.

**Prerequisites**:
1. `create_theme` with `{"path": "res://themes/in_use.tres"}`
2. Create a scene and add a Control-type node (e.g. `Button`)
3. Assign the theme to the node via `set_node_property` (property: `theme`)

**Call**:
```json
{
  "path": "res://themes/in_use.tres"
}
```

**Expected result**: Likely succeeds (Godot usually allows deleting resources even when referenced — the references become invalid). But may warn or fail depending on Godot version. Document actual behavior.

**Notes**: Important edge case. If the theme is deleted while in use, nodes referencing it may show default styling or errors. Verify the Godot-side behavior.

---

#### Scenario 4: Missing required `path` parameter

**Description**: Call without the required `path` field.

**Call**:
```json
{}
```

**Expected result**: Error. Zod schema validation rejects the request. Response should contain `isError: true`.

---

## Tool: `set_theme_color`

**Description**: Set a color in a theme for a specific control type
**Godot method**: `theme/set_color`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (ResourcePath) | **yes** | — | Theme resource path |
| `theme_type` | `string` (z.string()) | **yes** | — | Control type (e.g. `Button`, `Label`, `Panel`) |
| `name` | `string` (z.string()) | **yes** | — | Color name (e.g. `font_color`, `font_hover_color`) |
| `color` | `string` (z.string()) | **yes** | — | Color value as hex (e.g. `#FF0000`) or named color |

### Test Scenarios

#### Scenario 1: Set font_color on Button (happy path)

**Description**: Set a standard color property on a common control type.

**Prerequisites**: Theme must exist at the given path (use `create_theme` first).

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "font_color",
  "color": "#FF0000"
}
```

**Expected result**: Success. The color override is applied. Verify via `get_theme_info` that the theme now has a `font_color` for `Button`.

**Notes**: After this call, use `get_theme_info` to confirm the color was stored correctly.

---

#### Scenario 2: Set font_color with Godot named color

**Description**: Use a Godot built-in named color instead of hex.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Label",
  "name": "font_color",
  "color": "red"
}
```

**Expected result**: Success if Godot resolves named colors. Failure if the Godot-side handler only accepts hex. Document actual behavior.

**Notes**: Godot supports named colors like `red`, `blue`, `green`, `white`, `black`, etc. in its Color constructor. Verify whether the handler parses these.

---

#### Scenario 3: Set color with 8-digit hex (with alpha)

**Description**: Test hex color with alpha channel.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Panel",
  "name": "bg_color",
  "color": "#FF000080"
}
```

**Expected result**: Success if the Godot-side handler supports RGBA hex. Document whether 8-digit hex (with alpha) is accepted alongside 6-digit hex.

**Notes**: Godot's `Color()` constructor supports `#RRGGBBAA` format. Verify the handler passes it through correctly.

---

#### Scenario 4: Set multiple color types on same control

**Description**: Apply several color overrides to the same control type.

**Call** (sequential):
```json
{"path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_color", "color": "#FFFFFF"}
{"path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_hover_color", "color": "#FFFF00"}
{"path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_pressed_color", "color": "#FF0000"}
{"path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_focus_color", "color": "#00FF00"}
```

**Expected result**: All four succeed. Verify via `get_theme_info` that all four color overrides exist under `Button`.

**Notes**: Tests that multiple overrides accumulate correctly rather than overwriting each other.

---

#### Scenario 5: Missing required parameter (one at a time)

**Description**: Omit each required parameter individually to verify schema validation.

**Call** (each separately):
```json
{"theme_type": "Button", "name": "font_color", "color": "#FF0000"}
{"path": "res://themes/test_theme.tres", "name": "font_color", "color": "#FF0000"}
{"path": "res://themes/test_theme.tres", "theme_type": "Button", "color": "#FF0000"}
{"path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "font_color"}
```

**Expected result**: All four should return `isError: true` with a message about the missing field. The MCP SDK validates the schema before forwarding to Godot.

**Notes**: Tests that all four parameters are enforced as required by Zod validation.

---

#### Scenario 6: Theme file does not exist

**Description**: Try to set a color on a non-existent theme.

**Call**:
```json
{
  "path": "res://themes/nonexistent.tres",
  "theme_type": "Button",
  "name": "font_color",
  "color": "#FF0000"
}
```

**Expected result**: Error. The Godot side should fail because the theme resource file doesn't exist. Response should contain `isError: true`.

**Notes**: The TypeScript side accepts any string as path — only the Godot side can detect the missing file.

---

#### Scenario 7: Empty string values for parameters

**Description**: Pass empty strings for non-path parameters.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "",
  "name": "",
  "color": ""
}
```

**Expected result**: May pass TypeScript validation (all are `z.string()` which allows empty). Godot side should reject empty `theme_type` or `name` as invalid. Document actual behavior for each field.

**Notes**: Boundary test. An empty `theme_type` doesn't map to any Godot class. An empty `color` can't be parsed as a color.

---

## Tool: `set_theme_constant`

**Description**: Set a constant value in a theme
**Godot method**: `theme/set_constant`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (ResourcePath) | **yes** | — | Theme resource path |
| `theme_type` | `string` (z.string()) | **yes** | — | Control type |
| `name` | `string` (z.string()) | **yes** | — | Constant name (e.g. `hseparation`, `vseparation`) |
| `value` | `number` (z.number().int()) | **yes** | — | Constant integer value |

### Test Scenarios

#### Scenario 1: Set hseparation on Button (happy path)

**Description**: Set a standard spacing constant on a common control type.

**Prerequisites**: Theme must exist (use `create_theme` first).

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "hseparation",
  "value": 10
}
```

**Expected result**: Success. The constant override is applied. Verify via `get_theme_info`.

**Notes**: `hseparation` controls horizontal spacing in Button controls. Value of 10 pixels is a reasonable default.

---

#### Scenario 2: Set negative constant value

**Description**: Test that negative integers are accepted for constants.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "hseparation",
  "value": -5
}
```

**Expected result**: Success (Zod `z.number().int()` allows negative numbers). The Godot side should accept it since some constants can legitimately be negative.

**Notes**: Edge case. If negative values are invalid for certain constants, the Godot side should reject them. Document behavior.

---

#### Scenario 3: Set zero constant value

**Description**: Test zero as a constant value.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Label",
  "name": "line_spacing",
  "value": 0
}
```

**Expected result**: Success. Zero is a valid integer. The constant override is applied.

**Notes**: Zero is a common value for disabling spacing/separation.

---

#### Scenario 4: Float value (should be rejected)

**Description**: Pass a floating-point number instead of an integer.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "hseparation",
  "value": 10.5
}
```

**Expected result**: Error. Zod `z.number().int()` should reject non-integer values. Response should contain `isError: true` with a message about the value not being an integer.

**Notes**: Tests the `.int()` constraint on the `value` field.

---

#### Scenario 5: Large constant value

**Description**: Test with a very large integer.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Panel",
  "name": "hseparation",
  "value": 999999
}
```

**Expected result**: Success if Godot accepts it. Very large values may cause visual glitches but shouldn't crash. Document behavior.

**Notes**: Boundary test for extreme values.

---

#### Scenario 6: Missing required parameter (one at a time)

**Description**: Omit each required parameter individually.

**Call** (each separately):
```json
{"theme_type": "Button", "name": "hseparation", "value": 10}
{"path": "res://themes/test_theme.tres", "name": "hseparation", "value": 10}
{"path": "res://themes/test_theme.tres", "theme_type": "Button", "value": 10}
{"path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "hseparation"}
```

**Expected result**: All four should return `isError: true` with a message about the missing field.

---

## Tool: `set_theme_font_size`

**Description**: Set a font size in a theme
**Godot method**: `theme/set_font_size`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (ResourcePath) | **yes** | — | Theme resource path |
| `theme_type` | `string` (z.string()) | **yes** | — | Control type |
| `name` | `string` (z.string()) | **yes** | — | Size name (e.g. `font_size`) |
| `size` | `number` (z.number().int().positive()) | **yes** | — | Font size in pixels |

### Test Scenarios

#### Scenario 1: Set font_size on Label (happy path)

**Description**: Set a standard font size on a common control type.

**Prerequisites**: Theme must exist (use `create_theme` first).

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Label",
  "name": "font_size",
  "size": 16
}
```

**Expected result**: Success. The font size override is applied. Verify via `get_theme_info`.

**Notes**: 16px is a standard font size. After this, use `get_theme_info` to confirm the value.

---

#### Scenario 2: Set large font size

**Description**: Set a large font size for headings.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Label",
  "name": "font_size",
  "size": 48
}
```

**Expected result**: Success. The font size is stored. Valid for heading-style labels.

---

#### Scenario 3: Zero font size (should be rejected)

**Description**: Pass zero as the font size.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Label",
  "name": "font_size",
  "size": 0
}
```

**Expected result**: Error. Zod `z.number().int().positive()` rejects zero (positive means > 0). Response should contain `isError: true`.

**Notes**: Tests the `.positive()` constraint. Zero is not a valid font size.

---

#### Scenario 4: Negative font size (should be rejected)

**Description**: Pass a negative number as the font size.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Label",
  "name": "font_size",
  "size": -12
}
```

**Expected result**: Error. Zod `z.number().int().positive()` rejects negative numbers. Response should contain `isError: true`.

**Notes**: Tests the `.positive()` constraint. Negative font sizes are invalid.

---

#### Scenario 5: Float font size (should be rejected)

**Description**: Pass a floating-point number as the font size.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Label",
  "name": "font_size",
  "size": 14.5
}
```

**Expected result**: Error. Zod `z.number().int().positive()` rejects non-integers. Response should contain `isError: true`.

**Notes**: Font sizes in Godot are integers. This tests the `.int()` constraint.

---

#### Scenario 6: Font size of 1 (minimum valid)

**Description**: Test the minimum positive integer value.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Label",
  "name": "font_size",
  "size": 1
}
```

**Expected result**: Success. 1 is the smallest positive integer. The override is applied.

**Notes**: Boundary test for the minimum valid value.

---

#### Scenario 7: Missing required parameter (one at a time)

**Description**: Omit each required parameter individually.

**Call** (each separately):
```json
{"theme_type": "Label", "name": "font_size", "size": 16}
{"path": "res://themes/test_theme.tres", "name": "font_size", "size": 16}
{"path": "res://themes/test_theme.tres", "theme_type": "Label", "size": 16}
{"path": "res://themes/test_theme.tres", "theme_type": "Label", "name": "font_size"}
```

**Expected result**: All four should return `isError: true` with a message about the missing field.

---

## Tool: `set_theme_stylebox`

**Description**: Set a StyleBox in a theme
**Godot method**: `theme/set_stylebox`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (ResourcePath) | **yes** | — | Theme resource path |
| `theme_type` | `string` (z.string()) | **yes** | — | Control type |
| `name` | `string` (z.string()) | **yes** | — | StyleBox name (e.g. `normal`, `hover`, `pressed`) |
| `properties` | `Record<string, unknown>` (Properties) | **yes** | — | StyleBox properties (e.g. `bg_color`, `border_width`) |

### Test Scenarios

#### Scenario 1: Set a StyleBoxFlat with bg_color (happy path)

**Description**: Create a flat stylebox with a background color for the `normal` state of a Button.

**Prerequisites**: Theme must exist (use `create_theme` first).

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "normal",
  "properties": {
    "bg_color": "#333333",
    "border_color": "#FFFFFF",
    "border_width_left": 2,
    "border_width_right": 2,
    "border_width_top": 2,
    "border_width_bottom": 2,
    "corner_radius_top_left": 4,
    "corner_radius_top_right": 4,
    "corner_radius_bottom_left": 4,
    "corner_radius_bottom_right": 4
  }
}
```

**Expected result**: Success. A StyleBoxFlat override is applied to the `normal` state of `Button`. Verify via `get_theme_info`.

**Notes**: This is a comprehensive StyleBoxFlat example with border and corner radius properties. The Godot side should create a `StyleBoxFlat` resource and apply these properties.

---

#### Scenario 2: Set hover state stylebox

**Description**: Create a hover state stylebox with different colors.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "hover",
  "properties": {
    "bg_color": "#444444",
    "border_color": "#FFFF00"
  }
}
```

**Expected result**: Success. A hover stylebox is added alongside the normal stylebox. Both should coexist.

**Notes**: Tests that multiple stylebox states can be set independently.

---

#### Scenario 3: Set pressed state stylebox

**Description**: Create a pressed state stylebox.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "pressed",
  "properties": {
    "bg_color": "#222222"
  }
}
```

**Expected result**: Success. The pressed stylebox is applied.

---

#### Scenario 4: StyleBox with empty properties

**Description**: Pass an empty object for properties. This should create a default StyleBox with no customizations.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Panel",
  "name": "panel",
  "properties": {}
}
}
```

**Expected result**: Likely succeeds, creating a StyleBox with Godot defaults. Document whether empty properties are accepted or rejected.

**Notes**: Edge case. An empty properties object means "use all defaults" for the StyleBox.

---

#### Scenario 5: StyleBox with numeric values for margins

**Description**: Set content margins using numeric values.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "normal",
  "properties": {
    "content_margin_left": 10,
    "content_margin_right": 10,
    "content_margin_top": 5,
    "content_margin_bottom": 5,
    "bg_color": "#555555"
  }
}
```

**Expected result**: Success. Content margins and background color are applied.

**Notes**: Tests that numeric property values (not just colors) are handled correctly.

---

#### Scenario 6: Missing required parameter (one at a time)

**Description**: Omit each required parameter individually.

**Call** (each separately):
```json
{"theme_type": "Button", "name": "normal", "properties": {"bg_color": "#333"}}
{"path": "res://themes/test_theme.tres", "name": "normal", "properties": {"bg_color": "#333"}}
{"path": "res://themes/test_theme.tres", "theme_type": "Button", "properties": {"bg_color": "#333"}}
{"path": "res://themes/test_theme.tres", "theme_type": "Button", "name": "normal"}
```

**Expected result**: All four should return `isError: true` with a message about the missing field.

**Notes**: The `properties` field uses `z.record(z.unknown())` which is required (not optional). Missing it should fail validation.

---

#### Scenario 7: StyleBox with invalid color value

**Description**: Pass an unparseable color string.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "normal",
  "properties": {
    "bg_color": "not_a_color"
  }
}
```

**Expected result**: May pass TypeScript validation (Properties is `z.record(z.unknown())`). The Godot side should fail to parse the color. Document actual behavior — does it error or silently ignore invalid colors?

**Notes**: Important edge case for error handling. The TypeScript side doesn't validate color format — only the Godot side can.

---

## Tool: `get_theme_info`

**Description**: Get information about a theme including all its overrides
**Godot method**: `theme/get_info`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (ResourcePath) | **yes** | — | Theme resource path |

### Test Scenarios

#### Scenario 1: Get info for a newly created empty theme (happy path)

**Description**: Create a theme and immediately query its info. Should return an empty theme with no overrides.

**Prerequisites**: Run `create_theme` with `{"path": "res://themes/test_info.tres"}` first.

**Call**:
```json
{
  "path": "res://themes/test_info.tres"
}
```

**Expected result**: Success. Response should be a JSON/text representation of the theme. Should contain theme metadata (type, path) and indicate no color/constant/font_size/stylebox overrides (empty collections).

**Notes**: This is the baseline. Compare this response with subsequent `get_theme_info` calls after adding overrides.

---

#### Scenario 2: Get info for a theme with multiple overrides

**Description**: After setting color, constant, font_size, and stylebox overrides, query the full theme info.

**Prerequisites** (sequential):
1. `create_theme` with `{"path": "res://themes/test_info_full.tres"}`
2. `set_theme_color` with `{"path": "res://themes/test_info_full.tres", "theme_type": "Button", "name": "font_color", "color": "#FF0000"}`
3. `set_theme_constant` with `{"path": "res://themes/test_info_full.tres", "theme_type": "Button", "name": "hseparation", "value": 10}`
4. `set_theme_font_size` with `{"path": "res://themes/test_info_full.tres", "theme_type": "Button", "name": "font_size", "size": 16}`
5. `set_theme_stylebox` with `{"path": "res://themes/test_info_full.tres", "theme_type": "Button", "name": "normal", "properties": {"bg_color": "#333333"}}`

**Call**:
```json
{
  "path": "res://themes/test_info_full.tres"
}
```

**Expected result**: Success. Response should include ALL four overrides:
- Color: `Button/font_color = #FF0000`
- Constant: `Button/hseparation = 10`
- Font size: `Button/font_size = 16`
- StyleBox: `Button/normal` with `bg_color = #333333`

**Notes**: This is the most important validation scenario — it confirms that all `set_theme_*` operations persist correctly and are queryable.

---

#### Scenario 3: Get info for a non-existent theme

**Description**: Query a theme that doesn't exist.

**Call**:
```json
{
  "path": "res://themes/does_not_exist.tres"
}
```

**Expected result**: Error. Response should contain `isError: true` with a message about the file not being found.

**Notes**: Tests error handling for missing resources.

---

#### Scenario 4: Get info for a theme with overrides on multiple control types

**Description**: Set overrides on different control types and verify all are reported.

**Prerequisites** (sequential):
1. `create_theme` with `{"path": "res://themes/test_multi_type.tres"}`
2. `set_theme_color` with `{"path": "res://themes/test_multi_type.tres", "theme_type": "Button", "name": "font_color", "color": "#FF0000"}`
3. `set_theme_color` with `{"path": "res://themes/test_multi_type.tres", "theme_type": "Label", "name": "font_color", "color": "#00FF00"}`
4. `set_theme_color` with `{"path": "res://themes/test_multi_type.tres", "theme_type": "Panel", "name": "bg_color", "color": "#0000FF"}`

**Call**:
```json
{
  "path": "res://themes/test_multi_type.tres"
}
```

**Expected result**: Success. Response should list overrides for all three control types: `Button`, `Label`, and `Panel`, each with their respective colors.

**Notes**: Verifies that the theme correctly tracks overrides across different control types.

---

#### Scenario 5: Missing required `path` parameter

**Description**: Call without the required `path` field.

**Call**:
```json
{}
```

**Expected result**: Error. Zod schema validation rejects the request. Response should contain `isError: true`.

---

## Tool: `get_theme_color`

**Description**: Get a specific color value from a theme
**Godot method**: `theme/get_color`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (ResourcePath) | **yes** | — | Theme resource path |
| `theme_type` | `string` (z.string()) | **yes** | — | Control type (e.g. `Button`, `Label`, `Panel`) |
| `name` | `string` (z.string()) | **yes** | — | Color name (e.g. `font_color`, `font_hover_color`) |

### Test Scenarios

#### Scenario 1: Get an existing color (happy path)

**Description**: Set a color first, then read it back and verify the value matches.

**Prerequisites**: Theme must exist and have a color override set.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "font_color"
}
```

**Expected result**: Success. Response should contain the color value as a hex string (e.g. `"#FF0000"`). The value must match what was set with `set_theme_color`.

**Notes**: This is the primary read-back validation. After setting a color with `set_theme_color`, use `get_theme_color` to confirm the value persisted correctly.

---

#### Scenario 2: Get a color that does not exist

**Description**: Query a color name that was never set on the given theme type.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "nonexistent_color"
}
```

**Expected result**: Error. Response should contain `isError: true` with a message indicating the color was not found for the given type.

**Notes**: Tests that the tool correctly reports missing overrides rather than returning a default or crashing.

---

#### Scenario 3: Get a color from a non-existent theme

**Description**: Query a color from a theme file that doesn't exist.

**Call**:
```json
{
  "path": "res://themes/does_not_exist.tres",
  "theme_type": "Button",
  "name": "font_color"
}
```

**Expected result**: Error. Response should contain `isError: true` with a message about the theme file not being found.

---

#### Scenario 4: Get a color from an invalid theme_type

**Description**: Query a color using a theme_type that is not a valid Control class.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "NotARealClass",
  "name": "font_color"
}
```

**Expected result**: Error. Response should contain `isError: true` with a message about the invalid theme_type.

---

#### Scenario 5: Missing required parameter (one at a time)

**Description**: Omit each required parameter individually to verify error handling.

**Call** (each separately):
```json
{"theme_type": "Button", "name": "font_color"}
{"path": "res://themes/test_theme.tres", "name": "font_color"}
{"path": "res://themes/test_theme.tres", "theme_type": "Button"}
```

**Expected result**: All three should return `isError: true` with a message about the missing field.

---

## Tool: `get_theme_constant`

**Description**: Get a specific constant value from a theme
**Godot method**: `theme/get_constant`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (ResourcePath) | **yes** | — | Theme resource path |
| `theme_type` | `string` (z.string()) | **yes** | — | Control type |
| `name` | `string` (z.string()) | **yes** | — | Constant name (e.g. `hseparation`, `vseparation`) |

### Test Scenarios

#### Scenario 1: Get an existing constant (happy path)

**Description**: Set a constant first, then read it back and verify the value matches.

**Prerequisites**: Theme must exist and have a constant override set.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "hseparation"
}
```

**Expected result**: Success. Response should contain the integer value. The value must match what was set with `set_theme_constant`.

**Notes**: This is the primary read-back validation. After setting a constant with `set_theme_constant`, use `get_theme_constant` to confirm the value persisted correctly.

---

#### Scenario 2: Get a constant that does not exist

**Description**: Query a constant name that was never set on the given theme type.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "nonexistent_constant"
}
```

**Expected result**: Error. Response should contain `isError: true` with a message indicating the constant was not found for the given type.

---

#### Scenario 3: Get a constant from a non-existent theme

**Description**: Query a constant from a theme file that doesn't exist.

**Call**:
```json
{
  "path": "res://themes/does_not_exist.tres",
  "theme_type": "Button",
  "name": "hseparation"
}
```

**Expected result**: Error. Response should contain `isError: true` with a message about the theme file not being found.

---

#### Scenario 4: Get a constant from an invalid theme_type

**Description**: Query a constant using a theme_type that is not a valid Control class.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "NotARealClass",
  "name": "hseparation"
}
```

**Expected result**: Error. Response should contain `isError: true` with a message about the invalid theme_type.

---

#### Scenario 5: Missing required parameter (one at a time)

**Description**: Omit each required parameter individually.

**Call** (each separately):
```json
{"theme_type": "Button", "name": "hseparation"}
{"path": "res://themes/test_theme.tres", "name": "hseparation"}
{"path": "res://themes/test_theme.tres", "theme_type": "Button"}
```

**Expected result**: All three should return `isError: true` with a message about the missing field.

---

## Tool: `get_theme_font_size`

**Description**: Get a specific font size value from a theme
**Godot method**: `theme/get_font_size`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (ResourcePath) | **yes** | — | Theme resource path |
| `theme_type` | `string` (z.string()) | **yes** | — | Control type |
| `name` | `string` (z.string()) | **yes** | — | Size name (e.g. `font_size`) |

### Test Scenarios

#### Scenario 1: Get an existing font size (happy path)

**Description**: Set a font size first, then read it back and verify the value matches.

**Prerequisites**: Theme must exist and have a font size override set.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Label",
  "name": "font_size"
}
```

**Expected result**: Success. Response should contain the integer size value. The value must match what was set with `set_theme_font_size`.

**Notes**: This is the primary read-back validation. After setting a font size with `set_theme_font_size`, use `get_theme_font_size` to confirm the value persisted correctly.

---

#### Scenario 2: Get a font size that does not exist

**Description**: Query a font size name that was never set on the given theme type.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Label",
  "name": "nonexistent_size"
}
```

**Expected result**: Error. Response should contain `isError: true` with a message indicating the font size was not found for the given type.

---

#### Scenario 3: Get a font size from a non-existent theme

**Description**: Query a font size from a theme file that doesn't exist.

**Call**:
```json
{
  "path": "res://themes/does_not_exist.tres",
  "theme_type": "Label",
  "name": "font_size"
}
```

**Expected result**: Error. Response should contain `isError: true` with a message about the theme file not being found.

---

#### Scenario 4: Get a font size from an invalid theme_type

**Description**: Query a font size using a theme_type that is not a valid Control class.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "NotARealClass",
  "name": "font_size"
}
```

**Expected result**: Error. Response should contain `isError: true` with a message about the invalid theme_type.

---

#### Scenario 5: Missing required parameter (one at a time)

**Description**: Omit each required parameter individually.

**Call** (each separately):
```json
{"theme_type": "Label", "name": "font_size"}
{"path": "res://themes/test_theme.tres", "name": "font_size"}
{"path": "res://themes/test_theme.tres", "theme_type": "Label"}
```

**Expected result**: All three should return `isError: true` with a message about the missing field.

---

## Tool: `get_theme_stylebox`

**Description**: Get a specific StyleBox and its properties from a theme
**Godot method**: `theme/get_stylebox`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (ResourcePath) | **yes** | — | Theme resource path |
| `theme_type` | `string` (z.string()) | **yes** | — | Control type |
| `name` | `string` (z.string()) | **yes** | — | StyleBox name (e.g. `normal`, `hover`, `pressed`) |

### Test Scenarios

#### Scenario 1: Get an existing StyleBoxFlat (happy path)

**Description**: Set a StyleBoxFlat first, then read it back and verify all properties match.

**Prerequisites**: Theme must exist and have a StyleBoxFlat override set.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "normal"
}
```

**Expected result**: Success. Response should contain a `properties` dictionary with `type: "Flat"` and all StyleBoxFlat properties (bg_color, border_color, border widths, corner radii, content margins). Values must match what was set with `set_theme_stylebox`.

**Notes**: This is the most comprehensive read-back test. The response includes the full StyleBox property set, not just the type.

---

#### Scenario 2: Get a StyleBoxLine

**Description**: Set a StyleBoxLine first, then read it back.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "focus"
}
```

**Expected result**: Success. Response should contain `type: "Line"` with `color` and `thickness` properties.

---

#### Scenario 3: Get a StyleBoxEmpty

**Description**: Set a StyleBoxEmpty first, then read it back.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Panel",
  "name": "empty"
}
```

**Expected result**: Success. Response should contain `type: "Empty"` with no additional properties.

---

#### Scenario 4: Get a stylebox that does not exist

**Description**: Query a stylebox name that was never set on the given theme type.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "Button",
  "name": "nonexistent_style"
}
```

**Expected result**: Error. Response should contain `isError: true` with a message indicating the stylebox was not found for the given type.

---

#### Scenario 5: Get a stylebox from a non-existent theme

**Description**: Query a stylebox from a theme file that doesn't exist.

**Call**:
```json
{
  "path": "res://themes/does_not_exist.tres",
  "theme_type": "Button",
  "name": "normal"
}
```

**Expected result**: Error. Response should contain `isError: true` with a message about the theme file not being found.

---

#### Scenario 6: Get a stylebox from an invalid theme_type

**Description**: Query a stylebox using a theme_type that is not a valid Control class.

**Call**:
```json
{
  "path": "res://themes/test_theme.tres",
  "theme_type": "NotARealClass",
  "name": "normal"
}
```

**Expected result**: Error. Response should contain `isError: true` with a message about the invalid theme_type.

---

#### Scenario 7: Missing required parameter (one at a time)

**Description**: Omit each required parameter individually.

**Call** (each separately):
```json
{"theme_type": "Button", "name": "normal"}
{"path": "res://themes/test_theme.tres", "name": "normal"}
{"path": "res://themes/test_theme.tres", "theme_type": "Button"}
```

**Expected result**: All three should return `isError: true` with a message about the missing field.

---

## Cross-Tool Integration Test: Full Theme Lifecycle

**Description**: End-to-end test that exercises all 11 tools in sequence.

### Step-by-step flow:

```json
// Step 1: Create theme
{"tool": "create_theme", "params": {"path": "res://themes/integration_test.tres"}}

// Step 2: Verify empty theme
{"tool": "get_theme_info", "params": {"path": "res://themes/integration_test.tres"}}
// Expected: Empty theme, no overrides

// Step 3: Add color override
{"tool": "set_theme_color", "params": {"path": "res://themes/integration_test.tres", "theme_type": "Button", "name": "font_color", "color": "#FFFFFF"}}

// Step 4: Add constant override
{"tool": "set_theme_constant", "params": {"path": "res://themes/integration_test.tres", "theme_type": "Button", "name": "hseparation", "value": 8}}

// Step 5: Add font size override
{"tool": "set_theme_font_size", "params": {"path": "res://themes/integration_test.tres", "theme_type": "Button", "name": "font_size", "size": 20}}

// Step 6: Add stylebox override
{"tool": "set_theme_stylebox", "params": {"path": "res://themes/integration_test.tres", "theme_type": "Button", "name": "normal", "properties": {"bg_color": "#2A2A2A", "corner_radius_top_left": 6, "corner_radius_top_right": 6, "corner_radius_bottom_left": 6, "corner_radius_bottom_right": 6}}}

// Step 7: Verify all overrides
{"tool": "get_theme_info", "params": {"path": "res://themes/integration_test.tres"}}
// Expected: Theme with Button having font_color=#FFFFFF, hseparation=8, font_size=20, and StyleBox normal with bg_color=#2A2A2A + corner radii

// Step 8: Read back individual values
{"tool": "get_theme_color", "params": {"path": "res://themes/integration_test.tres", "theme_type": "Button", "name": "font_color"}}
// Expected: {"color": "#FFFFFF"}

{"tool": "get_theme_constant", "params": {"path": "res://themes/integration_test.tres", "theme_type": "Button", "name": "hseparation"}}
// Expected: {"value": 8}

{"tool": "get_theme_font_size", "params": {"path": "res://themes/integration_test.tres", "theme_type": "Button", "name": "font_size"}}
// Expected: {"size": 20}

{"tool": "get_theme_stylebox", "params": {"path": "res://themes/integration_test.tres", "theme_type": "Button", "name": "normal"}}
// Expected: {"type": "Flat", "bg_color": "#2A2A2A", ...}

// Step 9: Delete theme
{"tool": "delete_theme", "params": {"path": "res://themes/integration_test.tres"}}

// Step 10: Confirm deletion
{"tool": "get_theme_info", "params": {"path": "res://themes/integration_test.tres"}}
// Expected: Error — file not found
```

### Validation checklist:
- [ ] `create_theme` returns success
- [ ] `get_theme_info` on empty theme shows no overrides
- [ ] Each `set_theme_*` returns success
- [ ] `get_theme_info` after all sets shows all 4 overrides correctly
- [ ] `get_theme_color` returns the correct hex color value
- [ ] `get_theme_constant` returns the correct integer value
- [ ] `get_theme_font_size` returns the correct integer size
- [ ] `get_theme_stylebox` returns the correct StyleBox type and properties
- [ ] `delete_theme` returns success
- [ ] `get_theme_info` after delete returns error

---

## Summary: Parameter Type Matrix

| Tool | `path` | `theme_type` | `name` | `color` | `value` | `size` | `properties` |
|------|--------|-------------|--------|---------|---------|--------|-------------|
| `create_theme` | `ResourcePath` ✅ required | — | — | — | — | — | — |
| `delete_theme` | `z.string()` ✅ required | — | — | — | — | — | — |
| `set_theme_color` | `ResourcePath` ✅ required | `z.string()` ✅ required | `z.string()` ✅ required | `z.string()` ✅ required | — | — | — |
| `set_theme_constant` | `ResourcePath` ✅ required | `z.string()` ✅ required | `z.string()` ✅ required | — | `z.number().int()` ✅ required | — | — |
| `set_theme_font_size` | `ResourcePath` ✅ required | `z.string()` ✅ required | `z.string()` ✅ required | — | — | `z.number().int().positive()` ✅ required | — |
| `set_theme_stylebox` | `ResourcePath` ✅ required | `z.string()` ✅ required | `z.string()` ✅ required | — | — | — | `z.record(z.unknown())` ✅ required |
| `get_theme_info` | `ResourcePath` ✅ required | — | — | — | — | — | — |
| `get_theme_color` | `ResourcePath` ✅ required | `z.string()` ✅ required | `z.string()` ✅ required | — | — | — | — |
| `get_theme_constant` | `ResourcePath` ✅ required | `z.string()` ✅ required | `z.string()` ✅ required | — | — | — | — |
| `get_theme_font_size` | `ResourcePath` ✅ required | `z.string()` ✅ required | `z.string()` ✅ required | — | — | — | — |
| `get_theme_stylebox` | `ResourcePath` ✅ required | `z.string()` ✅ required | `z.string()` ✅ required | — | — | — | — |

### Schema validation notes:
- All parameters across all 11 tools are **required** — there are no optional parameters
- `ResourcePath` is `z.string().describe(...)` — accepts any string including empty
- `z.string()` — accepts any string including empty
- `z.number().int()` — rejects floats, accepts negative and zero
- `z.number().int().positive()` — rejects floats, zero, and negative numbers (must be > 0)
- `z.record(z.unknown())` — accepts any object with string keys and any values

### Key observations for test executors:
1. **No TypeScript-side path validation**: `ResourcePath` and `z.string()` accept any string. Invalid paths only fail on the Godot side.
2. **No color format validation on TS side**: `color` is just `z.string()`. Only Godot can validate color format.
3. **`value` has strict int validation**: `z.number().int()` will reject `10.5` at the TypeScript level.
4. **`size` has strict positive int validation**: `z.number().int().positive()` rejects `0`, `-1`, and `14.5` at the TypeScript level.
5. **`properties` accepts anything**: `z.record(z.unknown())` allows any JSON object. Validation of property keys/values happens only on the Godot side.
6. **All tools forward via `callGodot`**: Every tool calls `callGodot(bridge, 'theme/<action>', args)` which returns `{ content: [{ type: 'text', text }] }`. Errors from Godot are wrapped in `createErrorResult`.
