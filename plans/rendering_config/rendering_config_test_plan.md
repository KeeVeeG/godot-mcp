# Rendering Configuration Test Plan

> **Source file:** `server/src/tools/rendering_config.ts`  
> **Shared types:** `server/src/tools/shared-types.ts` (imports `z`, `Quality`, `Size2D`)  
> **Tools covered:** 9 (`get_rendering_settings`, `set_rendering_quality`, `set_renderer`, `set_anti_aliasing`, `set_shadow_quality`, `set_gi_quality`, `set_viewport_size`, `set_window_settings`, `get_rendering_info`)  
> **Generated:** 2026-07-08

---

## Schema Details

### Shared Imports

| Import | Zod Schema | Description |
|--------|-----------|-------------|
| `z` | Zod namespace | Used directly for `z.number()`, `z.enum(...)`, `z.boolean()` |
| `Quality` | `z.enum(['low', 'medium', 'high', 'ultra'])` | Quality preset level enum |
| `Size2D` | `z.tuple([z.number().int(), z.number().int()])` | 2-element tuple of integers representing `[width, height]` |

### Parameter Summary

| Tool | Param | Type | Required | Default | Enum/Choices | Notes |
|------|-------|------|----------|---------|--------------|-------|
| `get_rendering_settings` | *(none)* | — | — | — | — | Takes no input |
| `set_rendering_quality` | `quality` | `enum` | ✅ yes | — | `low`, `medium`, `high`, `ultra` | Quality preset level |
| `set_renderer` | `renderer` | `enum` | ✅ yes | — | `forward_plus`, `mobile`, `gl_compatibility` | Rendering backend |
| `set_anti_aliasing` | `msaa` | `enum` | no | — | `2x`, `4x`, `8x` | MSAA level (omit to disable) |
| | `fxaa` | `boolean` | no | — | `true`, `false` | Enable/disable FXAA |
| | `taa` | `boolean` | no | — | `true`, `false` | Enable/disable TAA |
| `set_shadow_quality` | `quality` | `enum` | ✅ yes | — | `low`, `medium`, `high`, `ultra` | Shadow quality level |
| `set_gi_quality` | `quality` | `enum` | ✅ yes | — | `low`, `medium`, `high`, `ultra` | GI quality level |
| `set_viewport_size` | `width` | `number` (int, positive) | ✅ yes | — | — | Viewport width in pixels |
| | `height` | `number` (int, positive) | ✅ yes | — | — | Viewport height in pixels |
| | `stretch_mode` | `enum` | no | — | `disabled`, `canvas_items`, `viewport` | Stretch mode |
| | `stretch_aspect` | `enum` | no | — | `ignore`, `keep`, `keep_width`, `keep_height`, `expand` | Stretch aspect ratio |
| `set_window_settings` | `size` | `tuple[int,int]` | no | — | — | Window size `[width, height]` |
| | `mode` | `enum` | no | — | `windowed`, `fullscreen`, `exclusive_fullscreen` | Window display mode |
| | `vsync` | `boolean` | no | — | `true`, `false` | Enable/disable vertical sync |
| `get_rendering_info` | *(none)* | — | — | — | — | Takes no input |

---

## Tool: get_rendering_settings

### Schema

```typescript
{
  description: 'Get all current rendering settings (renderer, quality, viewport, etc.)',
  inputSchema: {},
}
```

### Handler

```typescript
async () => callGodot(bridge, 'rendering_config/get_settings')
```

### Tool Behavior

Reads the current rendering configuration from the Godot project. Returns a comprehensive view of rendering settings including the active renderer type, quality presets, anti-aliasing configuration, shadow quality, GI quality, viewport dimensions and stretch settings, and window configuration. Takes no parameters — the empty `inputSchema: {}` means all extra fields are accepted but discarded by Zod.

### Test Scenarios

#### Scenario 1: Basic happy path — get current rendering settings
- **Description:** Call `get_rendering_settings` on a project with default rendering settings.
- **Params:** `{}`
- **Expected result:** Returns a JSON object containing rendering configuration data. Expected fields include the renderer type, quality levels, viewport size, and window settings. Response should have `content[0].type === 'text'` with a non-empty text value. `isError` should not be set or be `false`.
- **Notes:** The exact structure depends on what Godot returns via the bridge. At minimum it should not be an error.

#### Scenario 2: Call with unexpected extra params
- **Description:** Verify the tool ignores extraneous parameters since `inputSchema` is empty `{}`.
- **Params:** `{ "unexpected_param": true, "another_field": "hello" }`
- **Expected result:** Should succeed identically to Scenario 1. Extraneous params should be stripped by Zod (empty schema accepts and discards extra fields).
- **Notes:** Tests robustness against misconfigured clients.

#### Scenario 3: Call with no arguments at all
- **Description:** Call the tool with `undefined` (no params object at all).
- **Params:** *(omit params entirely)*
- **Expected result:** Should succeed — the empty schema should accept `undefined` input.
- **Notes:** Validates the handler handles a missing args object gracefully.

---

## Tool: set_rendering_quality

### Schema

```typescript
{
  description: 'Apply a rendering quality preset (sets multiple settings at once)',
  inputSchema: {
    quality: Quality,  // z.enum(['low', 'medium', 'high', 'ultra'])
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'rendering_config/set_quality', args as Record<string, unknown>)
```

### Tool Behavior

Applies a pre-defined rendering quality preset that adjusts multiple rendering settings simultaneously. The `quality` parameter is required and must be one of four values: `low`, `medium`, `high`, or `ultra`. Each preset configures things like texture quality, shadow resolution, anti-aliasing level, and post-processing effects at once. This is a convenience tool — the same result could be achieved by calling individual settings tools but at higher cost and risk of inconsistent configuration.

### Test Scenarios

#### Scenario 1: Happy path — set quality to `low`
- **Description:** Apply the `low` quality preset.
- **Params:** `{ "quality": "low" }`
- **Expected result:** The rendering quality is set to `low`. Returns success. Verify with `get_rendering_settings` that quality-related fields reflect low settings.
- **Notes:** Validates the `low` enum value. Typically reduces texture sizes, disables shadows, etc.

#### Scenario 2: Happy path — set quality to `medium`
- **Description:** Apply the `medium` quality preset.
- **Params:** `{ "quality": "medium" }`
- **Expected result:** The rendering quality is set to `medium`. Returns success.
- **Notes:** Validates the `medium` enum value. Balanced quality preset.

#### Scenario 3: Happy path — set quality to `high`
- **Description:** Apply the `high` quality preset.
- **Params:** `{ "quality": "high" }`
- **Expected result:** The rendering quality is set to `high`. Returns success.
- **Notes:** Validates the `high` enum value.

#### Scenario 4: Happy path — set quality to `ultra`
- **Description:** Apply the `ultra` quality preset (maximum visual fidelity).
- **Params:** `{ "quality": "ultra" }`
- **Expected result:** The rendering quality is set to `ultra`. Returns success.
- **Notes:** Validates the `ultra` enum value. Maximum quality preset — may be expensive on low-end hardware.

#### Scenario 5: Missing required param `quality`
- **Description:** Call `set_rendering_quality` without the `quality` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation should reject this. Expect an error about missing required parameter `quality`.
- **Notes:** `quality` is required with no default.

#### Scenario 6: Invalid enum value — non-existent quality level
- **Description:** Pass a quality value that is not in the enum.
- **Params:** `{ "quality": "maximum" }`
- **Expected result:** Zod validation should reject this. Expect an error about invalid enum value — e.g. "Invalid enum value. Expected 'low' | 'medium' | 'high' | 'ultra', received 'maximum'".
- **Notes:** Only the four defined values are accepted.

#### Scenario 7: Invalid enum value — `custom`
- **Description:** Pass `"custom"` which sounds plausible but is not a valid preset.
- **Params:** `{ "quality": "custom" }`
- **Expected result:** Zod validation should reject this. Expect an enum validation error.
- **Notes:** Even though "custom" might seem reasonable, it's not a recognized preset.

#### Scenario 8: Invalid enum value — empty string
- **Description:** Pass an empty string for `quality`.
- **Params:** `{ "quality": "" }`
- **Expected result:** Zod validation should reject this. Empty string is not a valid enum member. Expect an enum validation error.
- **Notes:** Edge case for empty input.

#### Scenario 9: Invalid enum value — case variation
- **Description:** Pass a valid value with different casing (`"LOW"`, `"Medium"`, `"Ultra"`).
- **Params:** `{ "quality": "LOW" }`
- **Expected result:** Zod validation should reject this. Enum matching is case-sensitive. Expect an enum validation error.
- **Notes:** `z.enum()` matches exactly — `"LOW"` ≠ `"low"`.

#### Scenario 10: Invalid type — number instead of string
- **Description:** Pass a numeric value for `quality`.
- **Params:** `{ "quality": 2 }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected string, received number".
- **Notes:** Zod's `z.enum()` expects strings.

#### Scenario 11: Invalid type — boolean instead of string
- **Description:** Pass a boolean for `quality`.
- **Params:** `{ "quality": false }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** `false` is not a valid enum member.

#### Scenario 12: Invalid type — null instead of string
- **Description:** Pass `null` for `quality`.
- **Params:** `{ "quality": null }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected string, received null".
- **Notes:** `null` is not a valid value for `z.enum()`.

#### Scenario 13: Invalid type — array instead of string
- **Description:** Pass an array for `quality`.
- **Params:** `{ "quality": ["high"] }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Arrays should not be accepted for an enum field.

#### Scenario 14: Extra unexpected params
- **Description:** Pass a valid `quality` with extra unknown parameters.
- **Params:** `{ "quality": "high", "target_fps": 60, "platform": "pc" }`
- **Expected result:** Should succeed with quality set to `high`. Extra fields should be stripped or ignored.
- **Notes:** Tests tolerance for superfluous fields from misconfigured clients.

---

## Tool: set_renderer

### Schema

```typescript
{
  description: 'Set the rendering method/renderer for the project',
  inputSchema: {
    renderer: z.enum(['forward_plus', 'mobile', 'gl_compatibility']).describe('Rendering backend to use'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'rendering_config/set_renderer', args as Record<string, unknown>)
```

### Tool Behavior

Switches the rendering backend used by the Godot project. Three options are available:
- **`forward_plus`**: Godot's modern clustered forward renderer (default for new 4.x projects). Supports advanced features like global illumination, volumetric fog, and clustered decals.
- **`mobile`**: Optimized forward renderer targeting mobile and low-end devices. Reduced feature set for better performance on constrained hardware.
- **`gl_compatibility`**: Legacy OpenGL ES 3.0 / WebGL 2.0 compatibility renderer. Maximum compatibility with older hardware but the most limited feature set.

The `renderer` parameter is required with no default. Changing the renderer may require a project restart to fully take effect.

### Test Scenarios

#### Scenario 1: Happy path — set renderer to `forward_plus`
- **Description:** Set the rendering backend to `forward_plus` (the modern default).
- **Params:** `{ "renderer": "forward_plus" }`
- **Expected result:** The renderer is set to `forward_plus`. Returns success. Verify with `get_rendering_settings` that the renderer field shows `forward_plus`.
- **Notes:** Validates the `forward_plus` enum value.

#### Scenario 2: Happy path — set renderer to `mobile`
- **Description:** Set the rendering backend to `mobile`.
- **Params:** `{ "renderer": "mobile" }`
- **Expected result:** The renderer is set to `mobile`. Returns success.
- **Notes:** Validates the `mobile` enum value. Designed for mobile/low-end devices.

#### Scenario 3: Happy path — set renderer to `gl_compatibility`
- **Description:** Set the rendering backend to `gl_compatibility`.
- **Params:** `{ "renderer": "gl_compatibility" }`
- **Expected result:** The renderer is set to `gl_compatibility`. Returns success.
- **Notes:** Validates the `gl_compatibility` enum value. The most compatible but least feature-rich option.

#### Scenario 4: Switch renderer back and forth
- **Description:** Set to `mobile`, then back to `forward_plus`, verifying each change.
- **Params:**
  - Step 1: `{ "renderer": "mobile" }`
  - Step 2: `{ "renderer": "forward_plus" }`
- **Expected result:** Both calls succeed. After Step 1, `get_rendering_settings` shows `mobile`. After Step 2, it shows `forward_plus`.
- **Notes:** Validates that switching renderers is idempotent and reversible.

#### Scenario 5: Missing required param `renderer`
- **Description:** Call `set_renderer` without the `renderer` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation should reject this. Expect an error about missing required parameter `renderer`.
- **Notes:** `renderer` is required with no default.

#### Scenario 6: Invalid enum value — `vulkan`
- **Description:** Pass `"vulkan"` — the name of a graphics API, not a Godot renderer backend.
- **Params:** `{ "renderer": "vulkan" }`
- **Expected result:** Zod validation should reject this. Expect an enum validation error.
- **Notes:** Godot's renderer backends are `forward_plus`, `mobile`, `gl_compatibility` — not individual graphics APIs.

#### Scenario 7: Invalid enum value — `urp` (Unity naming)
- **Description:** Pass `"urp"` — a Unity render pipeline name.
- **Params:** `{ "renderer": "urp" }`
- **Expected result:** Zod validation should reject this. Expect an enum validation error.
- **Notes:** Confusion with Unity's Universal Render Pipeline. Godot uses different naming.

#### Scenario 8: Invalid enum value — empty string
- **Description:** Pass an empty string for `renderer`.
- **Params:** `{ "renderer": "" }`
- **Expected result:** Zod validation should reject this. Expect an enum validation error.
- **Notes:** Edge case for empty input.

#### Scenario 9: Invalid enum value — `Forward_Plus` (wrong case)
- **Description:** Pass `"Forward_Plus"` with incorrect casing.
- **Params:** `{ "renderer": "Forward_Plus" }`
- **Expected result:** Zod validation should reject this. Enum matching is case-sensitive. Expect an enum validation error.
- **Notes:** `z.enum()` is case-sensitive. Only lowercase `forward_plus` is valid.

#### Scenario 10: Invalid type — number instead of string
- **Description:** Pass a numeric value for `renderer`.
- **Params:** `{ "renderer": 0 }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** The enum requires a string value.

#### Scenario 11: Invalid type — boolean instead of string
- **Description:** Pass a boolean for `renderer`.
- **Params:** `{ "renderer": true }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** `true` is not a valid enum member.

#### Scenario 12: Invalid type — null instead of string
- **Description:** Pass `null` for `renderer`.
- **Params:** `{ "renderer": null }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** `null` is not a valid value for `z.enum()`.

#### Scenario 13: Extra unexpected params
- **Description:** Pass a valid `renderer` with extra unknown parameters.
- **Params:** `{ "renderer": "forward_plus", "require_restart": true, "notify_user": false }`
- **Expected result:** Should succeed with renderer set to `forward_plus`. Extra fields should be stripped or ignored.
- **Notes:** Tests tolerance for superfluous fields.

---

## Tool: set_anti_aliasing

### Schema

```typescript
{
  description: 'Configure anti-aliasing settings (MSAA, FXAA, TAA)',
  inputSchema: {
    msaa: z.enum(['2x', '4x', '8x']).optional().describe('MSAA level (or omit to disable)'),
    fxaa: z.boolean().optional().describe('Enable/disable FXAA'),
    taa: z.boolean().optional().describe('Enable/disable TAA'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'rendering_config/set_anti_aliasing', args as Record<string, unknown>)
```

### Tool Behavior

Configures the anti-aliasing method(s) used by the renderer. All three parameters are optional — you can set any combination or none of them. Three anti-aliasing techniques are available:
- **MSAA** (`multisample anti-aliasing`): Hardware-based anti-aliasing. Available levels are `2x`, `4x`, and `8x`. Higher values produce smoother edges at greater performance cost. Omitting this parameter disables MSAA.
- **FXAA** (`fast approximate anti-aliasing`): A fast post-processing anti-aliasing filter. Boolean — `true` to enable, `false` to disable. Lightweight but can blur textures.
- **TAA** (`temporal anti-aliasing`): Uses data from previous frames to smooth edges. Boolean — `true` to enable, `false` to disable. Reduces shimmering but can cause ghosting.

These can be combined (e.g., MSAA + TAA) but some combinations may be redundant or unsupported on certain renderers.

### Test Scenarios

#### Scenario 1: Happy path — enable MSAA 4x only
- **Description:** Enable hardware MSAA at 4x. Other AA methods are left unchanged.
- **Params:** `{ "msaa": "4x" }`
- **Expected result:** MSAA is set to 4x. Returns success. Verify with `get_rendering_settings` that MSAA reflects `4x`. FXAA and TAA should remain at their previous values.
- **Notes:** Tests that a single optional param can be set while others are omitted.

#### Scenario 2: Happy path — enable MSAA 2x
- **Description:** Enable MSAA at the lowest hardware level.
- **Params:** `{ "msaa": "2x" }`
- **Expected result:** MSAA is set to 2x. Returns success.
- **Notes:** Boundary test — minimum MSAA level. Lightest GPU cost.

#### Scenario 3: Happy path — enable MSAA 8x
- **Description:** Enable MSAA at the highest level.
- **Params:** `{ "msaa": "8x" }`
- **Expected result:** MSAA is set to 8x. Returns success.
- **Notes:** Maximum MSAA level. Highest quality, highest cost.

#### Scenario 4: Happy path — enable FXAA only
- **Description:** Enable FXAA post-processing anti-aliasing.
- **Params:** `{ "fxaa": true }`
- **Expected result:** FXAA is enabled. Returns success.
- **Notes:** Tests standalone FXAA toggle.

#### Scenario 5: Happy path — disable FXAA
- **Description:** Disable FXAA explicitly.
- **Params:** `{ "fxaa": false }`
- **Expected result:** FXAA is disabled. Returns success.
- **Notes:** Tests the `false` value for the boolean parameter.

#### Scenario 6: Happy path — enable TAA only
- **Description:** Enable temporal anti-aliasing.
- **Params:** `{ "taa": true }`
- **Expected result:** TAA is enabled. Returns success.
- **Notes:** Tests standalone TAA toggle.

#### Scenario 7: Happy path — disable TAA
- **Description:** Disable TAA explicitly.
- **Params:** `{ "taa": false }`
- **Expected result:** TAA is disabled. Returns success.
- **Notes:** Tests the `false` value for the boolean parameter.

#### Scenario 8: Happy path — combine MSAA 4x + FXAA + TAA
- **Description:** Enable all three anti-aliasing methods simultaneously.
- **Params:** `{ "msaa": "4x", "fxaa": true, "taa": true }`
- **Expected result:** MSAA is set to 4x, FXAA is enabled, TAA is enabled. Returns success. Verify all three in `get_rendering_settings`.
- **Notes:** Tests that all three parameters can be set in one call. Godot may or may not support running all three simultaneously — the tool should forward them and let Godot handle compatibility.

#### Scenario 9: Happy path — call with no params (empty object)
- **Description:** Call `set_anti_aliasing` with an empty params object. All params are optional.
- **Params:** `{}`
- **Expected result:** Should succeed — the bridge call is made with an empty args object. No anti-aliasing settings should change.
- **Notes:** Since all params are optional, an empty call is valid. It's essentially a no-op.

#### Scenario 10: Happy path — disable MSAA by omitting it
- **Description:** Previously enabled MSAA 4x. Now call with only `fxaa` set — MSAA is not mentioned, which should leave it at its current value (not disable it).
- **Params:** `{ "fxaa": true }`
- **Expected result:** FXAA is enabled. MSAA should remain at its previously set value (not be disabled). Verifies that omitting a parameter does not reset it — it leaves it unchanged.
- **Notes:** Important behavioral test. Omitting `msaa` should NOT disable MSAA — it should leave it unchanged.

#### Scenario 11: Invalid MSAA value — non-existent level
- **Description:** Pass an MSAA level that is not in the enum.
- **Params:** `{ "msaa": "16x" }`
- **Expected result:** Zod validation should reject this. Expect an enum validation error — "Invalid enum value. Expected '2x' | '4x' | '8x', received '16x'".
- **Notes:** Godot 4.x only supports MSAA up to 8x. 16x is not a valid option.

#### Scenario 12: Invalid MSAA value — numeric string without `x`
- **Description:** Pass MSAA as a plain number string.
- **Params:** `{ "msaa": "4" }`
- **Expected result:** Zod validation should reject this. `"4"` is not in the enum `['2x', '4x', '8x']`. Expect an enum validation error.
- **Notes:** The enum requires the `x` suffix. `"4"` ≠ `"4x"`.

#### Scenario 13: Invalid MSAA value — integer number
- **Description:** Pass MSAA as a number instead of a string.
- **Params:** `{ "msaa": 4 }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected string, received number".
- **Notes:** Even though `4` corresponds to `"4x"`, the number type is not accepted.

#### Scenario 14: Invalid MSAA value — `"off"` string
- **Description:** Pass `"off"` — to disable MSAA, omit the parameter entirely.
- **Params:** `{ "msaa": "off" }`
- **Expected result:** Zod validation should reject this. `"off"` is not a valid enum member. Expect an enum validation error.
- **Notes:** To disable MSAA, omit the parameter. There is no `"off"` or `"none"` value.

#### Scenario 15: Invalid FXAA type — string instead of boolean
- **Description:** Pass a string `"enabled"` for the `fxaa` boolean parameter.
- **Params:** `{ "fxaa": "enabled" }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected boolean, received string".
- **Notes:** `z.boolean()` rejects string values, even truthy strings like `"true"`.

#### Scenario 16: Invalid FXAA type — number instead of boolean
- **Description:** Pass `1` for `fxaa`.
- **Params:** `{ "fxaa": 1 }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected boolean, received number". Zod's `z.boolean()` does not coerce `1`/`0` to `true`/`false`.
- **Notes:** Some JSON clients send `1`/`0` for booleans. Zod rejects these — must be literal `true`/`false`.

#### Scenario 17: Invalid TAA type — string instead of boolean
- **Description:** Pass `"true"` (string) for `taa`.
- **Params:** `{ "taa": "true" }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected boolean, received string".
- **Notes:** Even the string `"true"` is not coerced to boolean `true` by Zod.

#### Scenario 18: Invalid TAA type — null
- **Description:** Pass `null` for `taa`.
- **Params:** `{ "taa": null }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected boolean, received null".
- **Notes:** `null` is not a valid boolean. To leave TAA unchanged, omit the parameter entirely.

#### Scenario 19: Extra unexpected params
- **Description:** Pass valid AA settings with extra unknown parameters.
- **Params:** `{ "msaa": "8x", "fxaa": true, "taa": false, "ssaa": true, "quality_hint": "ultra" }`
- **Expected result:** Should succeed with MSAA 8x, FXAA enabled, TAA disabled. Extra fields (`ssaa`, `quality_hint`) should be stripped or ignored.
- **Notes:** Tests tolerance for misconfigured clients sending unsupported AA method names like `ssaa` (supersampling).

---

## Tool: set_shadow_quality

### Schema

```typescript
{
  description: 'Set shadow rendering quality preset',
  inputSchema: {
    quality: Quality.describe('Shadow quality level'),  // z.enum(['low', 'medium', 'high', 'ultra'])
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'rendering_config/set_shadow_quality', args as Record<string, unknown>)
```

### Tool Behavior

Sets the shadow rendering quality independently from the overall rendering quality. This controls shadow map resolution, shadow filtering quality, shadow draw distance, and the number of shadow-casting lights. The `quality` parameter uses the same `Quality` enum as `set_rendering_quality` (`low`, `medium`, `high`, `ultra`) but affects only shadows.

### Test Scenarios

#### Scenario 1: Happy path — set shadow quality to `low`
- **Description:** Set shadows to low quality (lowest resolution, fewest shadow-casting lights).
- **Params:** `{ "quality": "low" }`
- **Expected result:** Shadow quality is set to `low`. Returns success. Verify with `get_rendering_settings` that shadow-related fields reflect low quality.
- **Notes:** Validates the `low` value. Useful for performance-sensitive scenarios where shadows are expensive.

#### Scenario 2: Happy path — set shadow quality to `medium`
- **Description:** Set shadows to medium quality.
- **Params:** `{ "quality": "medium" }`
- **Expected result:** Shadow quality is set to `medium`. Returns success.
- **Notes:** Balanced shadow quality.

#### Scenario 3: Happy path — set shadow quality to `high`
- **Description:** Set shadows to high quality.
- **Params:** `{ "quality": "high" }`
- **Expected result:** Shadow quality is set to `high`. Returns success.
- **Notes:** Higher shadow resolution and more shadow-casting lights.

#### Scenario 4: Happy path — set shadow quality to `ultra`
- **Description:** Set shadows to ultra quality (maximum shadow fidelity).
- **Params:** `{ "quality": "ultra" }`
- **Expected result:** Shadow quality is set to `ultra`. Returns success.
- **Notes:** Maximum shadow quality. May be expensive on low-end hardware.

#### Scenario 5: Shadow quality independent of rendering quality
- **Description:** Set rendering quality to `low`, then set shadow quality to `ultra`. Verify they are independent.
- **Steps:**
  1. `set_rendering_quality` → `{ "quality": "low" }`
  2. `set_shadow_quality` → `{ "quality": "ultra" }`
  3. `get_rendering_settings` → `{}`
- **Expected result:** Step 3 should show overall rendering quality at `low` but shadow quality at `ultra`. The two settings are independent.
- **Notes:** Important behavioral test. Confirms shadow quality is not overridden by the global quality preset.

#### Scenario 6: Missing required param `quality`
- **Description:** Call `set_shadow_quality` without the `quality` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation should reject this. Expect an error about missing required parameter `quality`.
- **Notes:** `quality` is required with no default.

#### Scenario 7: Invalid enum value — non-existent level
- **Description:** Pass a quality level outside the valid enum.
- **Params:** `{ "quality": "epic" }`
- **Expected result:** Zod validation should reject this. Expect an enum validation error.
- **Notes:** Only `low`, `medium`, `high`, `ultra` are valid.

#### Scenario 8: Invalid enum value — empty string
- **Description:** Pass an empty string for `quality`.
- **Params:** `{ "quality": "" }`
- **Expected result:** Zod validation should reject this. Expect an enum validation error.
- **Notes:** Edge case for empty input.

#### Scenario 9: Invalid type — number instead of string
- **Description:** Pass a numeric value.
- **Params:** `{ "quality": 3 }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** `z.enum()` expects strings, not numbers.

#### Scenario 10: Invalid type — boolean instead of string
- **Description:** Pass a boolean for `quality`.
- **Params:** `{ "quality": true }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Booleans are not valid enum values.

#### Scenario 11: Invalid type — null instead of string
- **Description:** Pass `null` for `quality`.
- **Params:** `{ "quality": null }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** `null` is not a valid enum member.

#### Scenario 12: Extra unexpected params
- **Description:** Pass a valid `quality` with extra unknown parameters.
- **Params:** `{ "quality": "high", "shadow_distance": 100, "shadow_cascades": 4 }`
- **Expected result:** Should succeed with shadow quality set to `high`. Extra fields should be stripped or ignored.
- **Notes:** Tests tolerance for superfluous fields that might correspond to other shadow settings not exposed by this tool.

---

## Tool: set_gi_quality

### Schema

```typescript
{
  description: 'Set global illumination quality preset',
  inputSchema: {
    quality: Quality.describe('GI quality level'),  // z.enum(['low', 'medium', 'high', 'ultra'])
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'rendering_config/set_gi_quality', args as Record<string, unknown>)
```

### Tool Behavior

Sets the global illumination (GI) quality independently from the overall rendering quality. This controls the quality of indirect lighting calculations — light bounces, ambient occlusion quality, reflection probe resolution, and SDFGI or LightmapGI quality depending on the renderer. The `quality` parameter uses the `Quality` enum (`low`, `medium`, `high`, `ultra`). Higher GI quality produces more realistic lighting at the cost of GPU and CPU time.

### Test Scenarios

#### Scenario 1: Happy path — set GI quality to `low`
- **Description:** Set global illumination to low quality (fastest, least accurate).
- **Params:** `{ "quality": "low" }`
- **Expected result:** GI quality is set to `low`. Returns success. Verify with `get_rendering_settings` that GI-related fields reflect low quality.
- **Notes:** Validates the `low` value. Useful for performance-critical scenarios.

#### Scenario 2: Happy path — set GI quality to `medium`
- **Description:** Set global illumination to medium quality.
- **Params:** `{ "quality": "medium" }`
- **Expected result:** GI quality is set to `medium`. Returns success.
- **Notes:** Balanced GI quality.

#### Scenario 3: Happy path — set GI quality to `high`
- **Description:** Set global illumination to high quality.
- **Params:** `{ "quality": "high" }`
- **Expected result:** GI quality is set to `high`. Returns success.
- **Notes:** More accurate indirect lighting and reflections.

#### Scenario 4: Happy path — set GI quality to `ultra`
- **Description:** Set global illumination to ultra quality (maximum lighting fidelity).
- **Params:** `{ "quality": "ultra" }`
- **Expected result:** GI quality is set to `ultra`. Returns success.
- **Notes:** Maximum GI quality. Most realistic but most expensive.

#### Scenario 5: GI quality independent of rendering and shadow quality
- **Description:** Set rendering quality to `low`, shadow quality to `low`, then GI quality to `ultra`. Verify all three are independent.
- **Steps:**
  1. `set_rendering_quality` → `{ "quality": "low" }`
  2. `set_shadow_quality` → `{ "quality": "low" }`
  3. `set_gi_quality` → `{ "quality": "ultra" }`
  4. `get_rendering_settings` → `{}`
- **Expected result:** Step 4 should show overall quality at `low`, shadow quality at `low`, and GI quality at `ultra`. All three settings are independent quality axes.
- **Notes:** Confirms that the three quality presets (rendering, shadow, GI) operate independently.

#### Scenario 6: Missing required param `quality`
- **Description:** Call `set_gi_quality` without the `quality` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation should reject this. Expect an error about missing required parameter `quality`.
- **Notes:** `quality` is required with no default.

#### Scenario 7: Invalid enum value — `off`
- **Description:** Pass `"off"` — GI cannot be turned off via this tool, it can only be set to a quality level.
- **Params:** `{ "quality": "off" }`
- **Expected result:** Zod validation should reject this. `"off"` is not a valid enum member. Expect an enum validation error.
- **Notes:** There is no `off` value in the `Quality` enum.

#### Scenario 8: Invalid enum value — empty string
- **Description:** Pass an empty string for `quality`.
- **Params:** `{ "quality": "" }`
- **Expected result:** Zod validation should reject this. Expect an enum validation error.
- **Notes:** Edge case for empty input.

#### Scenario 9: Invalid type — number instead of string
- **Description:** Pass `1` for `quality`.
- **Params:** `{ "quality": 1 }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Quality must be a string enum value, not a numeric index.

#### Scenario 10: Invalid type — boolean instead of string
- **Description:** Pass a boolean.
- **Params:** `{ "quality": false }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Booleans are not valid.

#### Scenario 11: Invalid type — null instead of string
- **Description:** Pass `null`.
- **Params:** `{ "quality": null }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** `null` is not acceptable.

#### Scenario 12: Extra unexpected params
- **Description:** Pass a valid `quality` with extra parameters.
- **Params:** `{ "quality": "high", "gi_method": "sdfgi", "bounce_count": 4 }`
- **Expected result:** Should succeed with GI quality set to `high`. Extra fields should be stripped or ignored.
- **Notes:** Tests tolerance for fields that correspond to more granular GI settings.

---

## Tool: set_viewport_size

### Schema

```typescript
{
  description: 'Set the game viewport dimensions and stretch settings',
  inputSchema: {
    width: z.number().int().positive().describe('Viewport width in pixels'),
    height: z.number().int().positive().describe('Viewport height in pixels'),
    stretch_mode: z.enum(['disabled', 'canvas_items', 'viewport']).optional().describe('Stretch mode'),
    stretch_aspect: z.enum(['ignore', 'keep', 'keep_width', 'keep_height', 'expand']).optional().describe('Stretch aspect ratio behavior'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'rendering_config/set_viewport_size', args as Record<string, unknown>)
```

### Tool Behavior

Configures the game's viewport (base resolution) and how it stretches to fit the actual window/screen. Two required parameters (`width` and `height`, both positive integers) set the base resolution. Two optional parameters control stretch behavior:
- **`stretch_mode`** (optional): How the viewport is scaled. `disabled` — no stretching; `canvas_items` — 2D elements are stretched; `viewport` — the entire viewport is scaled.
- **`stretch_aspect`** (optional): How aspect ratio differences are handled. `ignore` — ignore aspect ratio, stretch to fill; `keep` — maintain aspect ratio, add letterbox bars; `keep_width` — keep width, expand/contract height; `keep_height` — keep height, expand/contract width; `expand` — expand viewport to fill while maintaining aspect ratio.

### Test Scenarios

#### Scenario 1: Happy path — set viewport to 1920×1080 (1080p)
- **Description:** Set the viewport to a standard 1080p resolution with only required params.
- **Params:** `{ "width": 1920, "height": 1080 }`
- **Expected result:** Viewport width is set to 1920, height to 1080. Returns success. Stretch settings should remain at their previous values. Verify with `get_rendering_settings`.
- **Notes:** Standard HD resolution. Only required params provided — stretch settings are unchanged.

#### Scenario 2: Happy path — set viewport to 1280×720 (720p)
- **Description:** Set the viewport to 720p resolution.
- **Params:** `{ "width": 1280, "height": 720 }`
- **Expected result:** Viewport is set to 1280×720. Returns success.
- **Notes:** Common resolution for lower-end targets.

#### Scenario 3: Happy path — set viewport to 3840×2160 (4K)
- **Description:** Set the viewport to 4K resolution.
- **Params:** `{ "width": 3840, "height": 2160 }`
- **Expected result:** Viewport is set to 3840×2160. Returns success.
- **Notes:** 4K UHD resolution. Tests large values.

#### Scenario 4: Happy path — set viewport with stretch_mode `disabled`
- **Description:** Set viewport to 320×180 with no stretching (pixel-perfect retro style).
- **Params:** `{ "width": 320, "height": 180, "stretch_mode": "disabled" }`
- **Expected result:** Viewport is set to 320×180 with stretch_mode `disabled`. Returns success.
- **Notes:** Pixel art / retro game resolution. `disabled` stretch mode means pixels are not scaled.

#### Scenario 5: Happy path — set viewport with stretch_mode `canvas_items`
- **Description:** Set viewport to 1920×1080 with canvas_items stretch mode.
- **Params:** `{ "width": 1920, "height": 1080, "stretch_mode": "canvas_items" }`
- **Expected result:** Viewport is set to 1920×1080 with stretch_mode `canvas_items`. Returns success.
- **Notes:** `canvas_items` stretch mode scales 2D elements to fit. 3D viewport is not affected.

#### Scenario 6: Happy path — set viewport with stretch_mode `viewport`
- **Description:** Set viewport to 1280×720 with viewport stretch mode.
- **Params:** `{ "width": 1280, "height": 720, "stretch_mode": "viewport" }`
- **Expected result:** Viewport is set to 1280×720 with stretch_mode `viewport`. Returns success.
- **Notes:** `viewport` stretches the entire viewport, including 3D content.

#### Scenario 7: Happy path — set viewport with stretch_aspect `ignore`
- **Description:** Set viewport to 1920×1080 with `ignore` aspect mode (stretches to fill regardless of ratio).
- **Params:** `{ "width": 1920, "height": 1080, "stretch_aspect": "ignore" }`
- **Expected result:** Viewport is set to 1920×1080 with stretch_aspect `ignore`. Returns success.
- **Notes:** Results in distorted/stretched rendering if the window aspect differs.

#### Scenario 8: Happy path — set viewport with stretch_aspect `keep`
- **Description:** Set viewport with `keep` aspect (letterboxing to maintain ratio).
- **Params:** `{ "width": 1920, "height": 1080, "stretch_aspect": "keep" }`
- **Expected result:** Viewport is set to 1920×1080 with stretch_aspect `keep`. Returns success.
- **Notes:** The most common aspect setting — adds black bars to maintain aspect ratio.

#### Scenario 9: Happy path — set viewport with stretch_aspect `keep_width`
- **Description:** Set viewport with `keep_width` — expands/contracts height.
- **Params:** `{ "width": 1920, "height": 1080, "stretch_aspect": "keep_width" }`
- **Expected result:** Viewport is set to 1920×1080 with stretch_aspect `keep_width`. Returns success.
- **Notes:** Width is maintained; height is adjusted to match aspect.

#### Scenario 10: Happy path — set viewport with stretch_aspect `keep_height`
- **Description:** Set viewport with `keep_height` — expands/contracts width.
- **Params:** `{ "width": 1920, "height": 1080, "stretch_aspect": "keep_height" }`
- **Expected result:** Viewport is set to 1920×1080 with stretch_aspect `keep_height`. Returns success.
- **Notes:** Height is maintained; width is adjusted to match aspect.

#### Scenario 11: Happy path — set viewport with stretch_aspect `expand`
- **Description:** Set viewport with `expand` — expands viewport to fill while maintaining aspect.
- **Params:** `{ "width": 1920, "height": 1080, "stretch_aspect": "expand" }`
- **Expected result:** Viewport is set to 1920×1080 with stretch_aspect `expand`. Returns success.
- **Notes:** Similar to `keep` but may expand the visible area rather than adding bars.

#### Scenario 12: Happy path — all params together
- **Description:** Set viewport with all four parameters simultaneously.
- **Params:** `{ "width": 1920, "height": 1080, "stretch_mode": "viewport", "stretch_aspect": "keep" }`
- **Expected result:** All four settings are applied. Returns success. Verify with `get_rendering_settings`.
- **Notes:** Validates that all parameters can be set in one call.

#### Scenario 13: Set only stretch settings without changing resolution
- **Description:** Change stretch_mode and stretch_aspect without specifying width/height. This should fail — width and height are required.
- **Params:** `{ "stretch_mode": "viewport", "stretch_aspect": "keep" }`
- **Expected result:** Zod validation should reject this. Expect errors about missing `width` and `height`.
- **Notes:** `width` and `height` are required. They cannot be omitted even if you only want to change stretch settings.

#### Scenario 14: Set viewport to a very small resolution (1×1)
- **Description:** Set the viewport to the minimum possible positive integer resolution.
- **Params:** `{ "width": 1, "height": 1 }`
- **Expected result:** Viewport is set to 1×1. Returns success — Zod accepts it (`positive()` means > 0). Godot may or may not handle a 1×1 viewport gracefully.
- **Notes:** Boundary test for `z.number().int().positive()`. The smallest value that satisfies `.positive()` is `1`.

#### Scenario 15: Set viewport to an excessively large resolution
- **Description:** Set viewport to 65536×65536 (very large).
- **Params:** `{ "width": 65536, "height": 65536 }`
- **Expected result:** Zod accepts it (no upper bound on `.positive()`). The tool forwards to Godot. Godot may clamp or reject. Observe the bridge response.
- **Notes:** Tests that no artificial upper bound exists in the Zod schema.

#### Scenario 16: Set viewport to a non-standard aspect ratio (ultrawide)
- **Description:** Set viewport to 2560×1080 (21:9 ultrawide).
- **Params:** `{ "width": 2560, "height": 1080 }`
- **Expected result:** Viewport is set to 2560×1080. Returns success.
- **Notes:** Validates non-16:9 aspect ratios.

#### Scenario 17: Set viewport to portrait orientation (1080×1920)
- **Description:** Set viewport to portrait mode resolution (mobile).
- **Params:** `{ "width": 1080, "height": 1920 }`
- **Expected result:** Viewport is set to 1080×1920. Returns success.
- **Notes:** Height larger than width — portrait orientation for mobile games.

#### Scenario 18: Missing required param `width`
- **Description:** Call `set_viewport_size` without the `width` parameter.
- **Params:** `{ "height": 1080 }`
- **Expected result:** Zod validation should reject this. Expect an error about missing required parameter `width`.
- **Notes:** `width` is required with no default.

#### Scenario 19: Missing required param `height`
- **Description:** Call `set_viewport_size` without the `height` parameter.
- **Params:** `{ "width": 1920 }`
- **Expected result:** Zod validation should reject this. Expect an error about missing required parameter `height`.
- **Notes:** `height` is required with no default.

#### Scenario 20: Both required params missing
- **Description:** Call `set_viewport_size` with an empty params object.
- **Params:** `{}`
- **Expected result:** Zod validation should reject this. Expect errors about missing both `width` and `height`.
- **Notes:** Both are required.

#### Scenario 21: Width is zero
- **Description:** Pass `width` of `0`.
- **Params:** `{ "width": 0, "height": 1080 }`
- **Expected result:** Zod validation should reject this. `.positive()` requires `> 0`. Expect a `too_small` error.
- **Notes:** Zero is not positive. Boundary test.

#### Scenario 22: Width is negative
- **Description:** Pass a negative `width`.
- **Params:** `{ "width": -1920, "height": 1080 }`
- **Expected result:** Zod validation should reject this. `.positive()` rejects negatives. Expect a `too_small` error.
- **Notes:** Negative dimensions are nonsensical.

#### Scenario 23: Height is zero
- **Description:** Pass `height` of `0`.
- **Params:** `{ "width": 1920, "height": 0 }`
- **Expected result:** Zod validation should reject this. Expect a `too_small` error for height.
- **Notes:** Same as width — zero is not positive.

#### Scenario 24: Width is a float instead of integer
- **Description:** Pass a floating-point value for `width`.
- **Params:** `{ "width": 1920.5, "height": 1080 }`
- **Expected result:** Zod validation should reject this. `.int()` rejects non-integer numbers. Expect an integer error.
- **Notes:** Viewport dimensions must be integer pixel values.

#### Scenario 25: Height is a float instead of integer
- **Description:** Pass `height` as `1080.0`. In JavaScript, `1080.0` is an integer via `Number.isInteger()`, so it should pass `.int()`.
- **Params:** `{ "width": 1920, "height": 1080.0 }`
- **Expected result:** Should succeed — `Number.isInteger(1080.0)` returns `true`. Height is treated as the integer `1080`.
- **Notes:** `1080.0` is functionally an integer in JS. Most JSON parsers serialize `1080.0` as `1080` anyway.

#### Scenario 26: Invalid width type — string
- **Description:** Pass a string for `width`.
- **Params:** `{ "width": "1920", "height": 1080 }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected number, received string".
- **Notes:** Numeric strings are not coerced to numbers by Zod.

#### Scenario 27: Invalid width type — boolean
- **Description:** Pass a boolean for `width`.
- **Params:** `{ "width": true, "height": 1080 }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Booleans are not numbers.

#### Scenario 28: Invalid stretch_mode — non-existent value
- **Description:** Pass an invalid stretch_mode.
- **Params:** `{ "width": 1920, "height": 1080, "stretch_mode": "scale" }`
- **Expected result:** Zod validation should reject this. Expect an enum validation error.
- **Notes:** Only `disabled`, `canvas_items`, `viewport` are valid.

#### Scenario 29: Invalid stretch_aspect — non-existent value
- **Description:** Pass an invalid stretch_aspect.
- **Params:** `{ "width": 1920, "height": 1080, "stretch_aspect": "fit" }`
- **Expected result:** Zod validation should reject this. Expect an enum validation error.
- **Notes:** Only `ignore`, `keep`, `keep_width`, `keep_height`, `expand` are valid.

#### Scenario 30: Invalid stretch_aspect — `keep_width` as boolean
- **Description:** Pass a boolean for stretch_aspect.
- **Params:** `{ "width": 1920, "height": 1080, "stretch_aspect": true }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Stretch_aspect is an enum (string), not a boolean toggle.

#### Scenario 31: Extra unexpected params
- **Description:** Pass valid viewport params with extra unknown fields.
- **Params:** `{ "width": 1920, "height": 1080, "stretch_mode": "viewport", "stretch_aspect": "keep", "target_fps": 60, "fullscreen": true }`
- **Expected result:** Should succeed with the viewport settings applied. Extra fields should be stripped or ignored.
- **Notes:** Tests tolerance for superfluous fields.

---

## Tool: set_window_settings

### Schema

```typescript
{
  description: 'Configure the application window size, mode, and vsync',
  inputSchema: {
    size: Size2D.optional().describe('Window size [width, height]'),  // z.tuple([z.number().int(), z.number().int()])
    mode: z.enum(['windowed', 'fullscreen', 'exclusive_fullscreen']).optional().describe('Window display mode'),
    vsync: z.boolean().optional().describe('Enable/disable vertical sync'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'rendering_config/set_window_settings', args as Record<string, unknown>)
```

### Tool Behavior

Configures the application window's appearance and behavior. All three parameters are optional — set only what you need to change. The parameters are:
- **`size`** (optional `Size2D`): A 2-element array `[width, height]` of integers specifying the window dimensions. This is a Zod tuple — both elements are integer numbers, validated by `z.tuple([z.number().int(), z.number().int()])`.
- **`mode`** (optional enum): The window display mode. `windowed` — standard window; `fullscreen` — borderless fullscreen window; `exclusive_fullscreen` — exclusive fullscreen mode (bypasses compositor for lowest latency).
- **`vsync`** (optional boolean): Enable or disable vertical synchronization. `true` limits frame rate to the display's refresh rate (reduces tearing); `false` allows unlimited frame rate (may cause tearing).

### Test Scenarios

#### Scenario 1: Happy path — set window mode to `windowed`
- **Description:** Set the window to windowed mode only.
- **Params:** `{ "mode": "windowed" }`
- **Expected result:** Window mode is set to `windowed`. Returns success. Size and vsync remain unchanged.
- **Notes:** Tests that a single optional param works when others are omitted.

#### Scenario 2: Happy path — set window mode to `fullscreen`
- **Description:** Set the window to borderless fullscreen mode.
- **Params:** `{ "mode": "fullscreen" }`
- **Expected result:** Window mode is set to `fullscreen`. Returns success.
- **Notes:** Borderless fullscreen — easier alt-tabbing, no mode switch.

#### Scenario 3: Happy path — set window mode to `exclusive_fullscreen`
- **Description:** Set the window to exclusive fullscreen mode.
- **Params:** `{ "mode": "exclusive_fullscreen" }`
- **Expected result:** Window mode is set to `exclusive_fullscreen`. Returns success.
- **Notes:** Exclusive fullscreen gives the game full GPU control. May cause flicker on alt-tab.

#### Scenario 4: Happy path — set window size to 1280×720
- **Description:** Set only the window size to 720p.
- **Params:** `{ "size": [1280, 720] }`
- **Expected result:** Window size is set to 1280×720. Returns success. Mode and vsync remain unchanged.
- **Notes:** Validates the `Size2D` tuple parameter. Must be an array of two integers.

#### Scenario 5: Happy path — set window size to 1920×1080
- **Description:** Set the window to 1080p size.
- **Params:** `{ "size": [1920, 1080] }`
- **Expected result:** Window size is set to 1920×1080. Returns success.
- **Notes:** Standard HD window size.

#### Scenario 6: Happy path — set window size to 3840×2160 (4K)
- **Description:** Set window size to 4K.
- **Params:** `{ "size": [3840, 2160] }`
- **Expected result:** Window size is set to 3840×2160. Returns success.
- **Notes:** Large window size. Godot may clamp to the display resolution.

#### Scenario 7: Happy path — enable vsync
- **Description:** Enable vertical sync.
- **Params:** `{ "vsync": true }`
- **Expected result:** Vsync is enabled. Returns success.
- **Notes:** Frame rate will be capped at the display refresh rate.

#### Scenario 8: Happy path — disable vsync
- **Description:** Disable vertical sync.
- **Params:** `{ "vsync": false }`
- **Expected result:** Vsync is disabled. Returns success.
- **Notes:** Frame rate will be uncapped (may cause screen tearing).

#### Scenario 9: Happy path — set all three parameters
- **Description:** Set window size, mode, and vsync in a single call.
- **Params:** `{ "size": [1920, 1080], "mode": "fullscreen", "vsync": true }`
- **Expected result:** Window size is 1920×1080, mode is fullscreen, vsync is enabled. Returns success. Verify all three with `get_rendering_settings`.
- **Notes:** Validates that all three optional parameters work together.

#### Scenario 10: Happy path — call with no params (empty object)
- **Description:** Call `set_window_settings` with an empty params object. All params are optional.
- **Params:** `{}`
- **Expected result:** Should succeed — the bridge call is made with an empty args object. No window settings should change.
- **Notes:** Since all params are optional, an empty call is valid. Essentially a no-op.

#### Scenario 11: Happy path — set window to portrait size (1080×1920)
- **Description:** Set window to portrait orientation for mobile testing.
- **Params:** `{ "size": [1080, 1920] }`
- **Expected result:** Window size is set to 1080×1920. Returns success.
- **Notes:** Portrait orientation for mobile game development.

#### Scenario 12: Happy path — set a tiny window (100×100)
- **Description:** Set window to a very small 100×100 size.
- **Params:** `{ "size": [100, 100] }`
- **Expected result:** Window size is set to 100×100. Godot may enforce a minimum window size. Observe the bridge response.
- **Notes:** `z.tuple()` with `.int()` has no `.min()` or `.positive()` constraint, so zero and negative values pass Zod. However, Godot may reject or clamp.

#### Scenario 13: Size2D with zero values
- **Description:** Pass `[0, 0]` for window size.
- **Params:** `{ "size": [0, 0] }`
- **Expected result:** Zod accepts it — `z.number().int()` has no minimum constraint. The tool forwards to Godot. Godot should reject or clamp zero-sized windows. Observe the bridge response.
- **Notes:** `Size2D` is defined as `z.tuple([z.number().int(), z.number().int()])` — no `.positive()` constraint. Zero passes Zod but is likely invalid at the engine level.

#### Scenario 14: Size2D with negative values
- **Description:** Pass `[-100, -100]` for window size.
- **Params:** `{ "size": [-100, -100] }`
- **Expected result:** Zod accepts it (no `.positive()` on tuple elements). The tool forwards to Godot. Godot should reject negative window dimensions.
- **Notes:** While Zod accepts negative integers, Godot should reject them.

#### Scenario 15: Size2D with float values
- **Description:** Pass floating-point values in the size array.
- **Params:** `{ "size": [1920.5, 1080.5] }`
- **Expected result:** Zod validation should reject this — `.int()` on both tuple elements rejects non-integer values. Expect an integer error.
- **Notes:** Window dimensions must be integers.

#### Scenario 16: Size2D with only one element
- **Description:** Pass a single-element array for `size`.
- **Params:** `{ "size": [1920] }`
- **Expected result:** Zod validation should reject this. `z.tuple([z.number().int(), z.number().int()])` requires exactly 2 elements. Expect a tuple length error.
- **Notes:** Tuples require exactly the specified number of elements.

#### Scenario 17: Size2D with three elements
- **Description:** Pass a 3-element array for `size`.
- **Params:** `{ "size": [1920, 1080, 60] }`
- **Expected result:** Zod validation should reject this. The tuple expects exactly 2 elements. Expect a tuple length error or the third element is stripped.
- **Notes:** Tuples have fixed length. Extra elements are rejected.

#### Scenario 18: Size2D as an object instead of array
- **Description:** Pass an object `{ "width": 1920, "height": 1080 }` instead of an array.
- **Params:** `{ "size": { "width": 1920, "height": 1080 } }`
- **Expected result:** Zod validation should reject this. `z.tuple()` expects an array, not an object. Expect a type error.
- **Notes:** The `Size2D` type is an array `[width, height]`, not an object with named keys.

#### Scenario 19: Size2D with string elements
- **Description:** Pass string values in the size array.
- **Params:** `{ "size": ["1920", "1080"] }`
- **Expected result:** Zod validation should reject this. Elements are `z.number().int()`, not strings. Expect type errors for both elements.
- **Notes:** Zod does not coerce string numbers to numbers in tuples.

#### Scenario 20: Size2D with boolean elements
- **Description:** Pass booleans in the size array.
- **Params:** `{ "size": [true, false] }`
- **Expected result:** Zod validation should reject this. Expect type errors.
- **Notes:** Boolean values are not valid integers.

#### Scenario 21: Invalid mode — non-existent value
- **Description:** Pass a window mode outside the enum.
- **Params:** `{ "mode": "maximized" }`
- **Expected result:** Zod validation should reject this. Expect an enum validation error.
- **Notes:** Only `windowed`, `fullscreen`, `exclusive_fullscreen` are valid.

#### Scenario 22: Invalid mode — `Fullscreen` (wrong case)
- **Description:** Pass `"Fullscreen"` with a capital F.
- **Params:** `{ "mode": "Fullscreen" }`
- **Expected result:** Zod validation should reject this. Enum matching is case-sensitive. Expect an enum validation error.
- **Notes:** `z.enum()` requires exact string match.

#### Scenario 23: Invalid mode — empty string
- **Description:** Pass an empty string for mode.
- **Params:** `{ "mode": "" }`
- **Expected result:** Zod validation should reject this. Expect an enum validation error.
- **Notes:** Edge case for empty input.

#### Scenario 24: Invalid mode type — number
- **Description:** Pass a number for `mode`.
- **Params:** `{ "mode": 0 }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Enum values are strings, not numeric indices.

#### Scenario 25: Invalid mode type — boolean
- **Description:** Pass a boolean for `mode`.
- **Params:** `{ "mode": true }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Booleans are not valid enum members.

#### Scenario 26: Invalid mode type — null
- **Description:** Pass `null` for `mode`.
- **Params:** `{ "mode": null }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** To leave mode unchanged, omit the parameter. Passing `null` is not equivalent to omission.

#### Scenario 27: Invalid vsync type — string
- **Description:** Pass a string `"on"` for vsync.
- **Params:** `{ "vsync": "on" }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected boolean, received string".
- **Notes:** `z.boolean()` rejects strings.

#### Scenario 28: Invalid vsync type — number
- **Description:** Pass `1` for vsync.
- **Params:** `{ "vsync": 1 }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected boolean, received number".
- **Notes:** Zod does not coerce `1`/`0` to `true`/`false`.

#### Scenario 29: Invalid vsync type — null
- **Description:** Pass `null` for vsync.
- **Params:** `{ "vsync": null }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Omit the parameter to leave unchanged, don't pass `null`.

#### Scenario 30: Extra unexpected params
- **Description:** Pass valid window settings with extra unknown parameters.
- **Params:** `{ "size": [1920, 1080], "mode": "windowed", "vsync": true, "resizable": true, "borderless": false, "always_on_top": false }`
- **Expected result:** Should succeed with the three valid params applied. Extra fields (`resizable`, `borderless`, `always_on_top`) should be stripped or ignored.
- **Notes:** Tests tolerance for fields that might correspond to other window features not exposed by this tool.

---

## Tool: get_rendering_info

### Schema

```typescript
{
  description: 'Get GPU info, VRAM usage, draw calls, and rendering statistics',
  inputSchema: {},
}
```

### Handler

```typescript
async () => callGodot(bridge, 'rendering_config/get_rendering_info')
```

### Tool Behavior

Queries real-time rendering statistics from the Godot engine. Returns information about the GPU hardware, VRAM usage, current draw call counts, and other rendering performance metrics. This is a read-only diagnostic tool useful for performance profiling. Takes no parameters — the empty `inputSchema: {}` means extra fields are accepted but discarded.

### Test Scenarios

#### Scenario 1: Basic happy path — get rendering info on default project
- **Description:** Call `get_rendering_info` on a project with an open scene (edit mode or play mode).
- **Params:** `{}`
- **Expected result:** Returns a JSON object containing GPU info (vendor, renderer string, version), VRAM usage statistics, draw call counts, and other rendering metrics. Response should have `content[0].type === 'text'` with a non-empty text value. `isError` should not be set or be `false`.
- **Notes:** The exact fields depend on Godot's `RenderingServer` and `Performance` singletons. At minimum, the response should include GPU vendor and renderer name.

#### Scenario 2: Get rendering info during gameplay (if a scene can be played)
- **Description:** Start playing a scene, then call `get_rendering_info` to get live statistics.
- **Steps:**
  1. Play a scene that has some 3D content (e.g., cubes with materials, lights).
  2. Call `get_rendering_info` → `{}`
- **Expected result:** Returns rendering statistics from the running game. Draw call count should be non-zero if the scene has visible geometry.
- **Notes:** Runtime rendering info may differ from editor mode — e.g., editor overlays add draw calls.

#### Scenario 3: Call twice in succession — verify stats change or stay consistent
- **Description:** Call `get_rendering_info` twice quickly and compare the results.
- **Params:** `{}` (twice)
- **Expected result:** Both calls succeed. Some fields (like GPU vendor) should be identical. Dynamic fields (like draw calls, VRAM usage) may differ slightly between calls.
- **Notes:** Tests that the tool is not stateful and can be called repeatedly without errors.

#### Scenario 4: Call with unexpected extra params
- **Description:** Verify the tool ignores extraneous parameters.
- **Params:** `{ "detailed": true, "format": "json", "include_textures": false }`
- **Expected result:** Should succeed identically to Scenario 1. Extraneous params should be stripped by Zod.
- **Notes:** Tests robustness against misconfigured clients.

#### Scenario 5: Call with no arguments at all
- **Description:** Call the tool with `undefined` (no params object at all).
- **Params:** *(omit params entirely)*
- **Expected result:** Should succeed — the empty schema should accept `undefined` input.
- **Notes:** Validates the handler handles a missing args object gracefully.

---

## Cross-Tool Integration Scenarios

These scenarios test interactions between multiple rendering config tools.

### Integration 1: Full rendering configuration cycle
- **Description:** Configure all rendering settings then read them back.
- **Steps:**
  1. `set_renderer` → `{ "renderer": "forward_plus" }`
  2. `set_rendering_quality` → `{ "quality": "high" }`
  3. `set_shadow_quality` → `{ "quality": "medium" }`
  4. `set_gi_quality` → `{ "quality": "high" }`
  5. `set_anti_aliasing` → `{ "msaa": "4x", "fxaa": false, "taa": true }`
  6. `set_viewport_size` → `{ "width": 1920, "height": 1080, "stretch_mode": "viewport", "stretch_aspect": "keep" }`
  7. `set_window_settings` → `{ "size": [1920, 1080], "mode": "windowed", "vsync": true }`
  8. `get_rendering_settings` → `{}`
- **Expected result:** Step 8 returns all settings reflecting the changes from steps 1–7. All calls succeed.
- **Notes:** Validates that all set operations persist and are readable.

### Integration 2: Independent quality axes
- **Description:** Set rendering quality to `low`, shadows to `ultra`, GI to `medium`. Verify all three are stored independently.
- **Steps:**
  1. `set_rendering_quality` → `{ "quality": "low" }`
  2. `set_shadow_quality` → `{ "quality": "ultra" }`
  3. `set_gi_quality` → `{ "quality": "medium" }`
  4. `get_rendering_settings` → `{}`
- **Expected result:** Step 4 shows rendering quality = `low`, shadow quality = `ultra`, GI quality = `medium`. The three quality settings are independent.
- **Notes:** Confirms that the quality presets operate on different rendering subsystems.

### Integration 3: Renderer switch affects quality presets
- **Description:** Switch renderer after setting quality presets. Verify presets persist (or are clamped) after renderer change.
- **Steps:**
  1. `set_renderer` → `{ "renderer": "forward_plus" }`
  2. `set_rendering_quality` → `{ "quality": "ultra" }`
  3. `set_renderer` → `{ "renderer": "gl_compatibility" }`
  4. `get_rendering_settings` → `{}`
- **Expected result:** Steps 1–3 succeed. Step 4 shows the renderer is `gl_compatibility`. The quality preset may be clamped or may show `ultra` — observe the Godot bridge response. Some quality settings may not apply to `gl_compatibility`.
- **Notes:** Tests behavior when switching to a renderer that may not support all quality settings.

### Integration 4: Viewport size and window size interaction
- **Description:** Set viewport to 1280×720 but window to 1920×1080 (different sizes). Verify both are stored correctly.
- **Steps:**
  1. `set_viewport_size` → `{ "width": 1280, "height": 720, "stretch_mode": "viewport", "stretch_aspect": "keep" }`
  2. `set_window_settings` → `{ "size": [1920, 1080] }`
  3. `get_rendering_settings` → `{}`
- **Expected result:** Step 3 shows viewport = 1280×720 (with stretch settings) and window = 1920×1080. The viewport is the internal rendering resolution; the window is the actual output window size.
- **Notes:** These are distinct concepts — viewport is the base resolution, window is the display size. The stretch settings determine how the viewport maps to the window.

### Integration 5: Anti-aliasing after renderer switch
- **Description:** Set anti-aliasing on one renderer, switch renderer, verify AA settings persist or adapt.
- **Steps:**
  1. `set_renderer` → `{ "renderer": "forward_plus" }`
  2. `set_anti_aliasing` → `{ "msaa": "8x", "fxaa": false, "taa": true }`
  3. `set_renderer` → `{ "renderer": "mobile" }`
  4. `get_rendering_settings` → `{}`
- **Expected result:** Steps 1–3 succeed. Step 4 shows the renderer is `mobile`. MSAA may be clamped (mobile may not support 8x), TAA may not be supported on mobile. Observe the Godot bridge response to see how settings are handled after renderer switch.
- **Notes:** Different renderers have different AA capabilities. The tool should forward settings regardless; Godot handles compatibility.

### Integration 6: Tool independence — get tools unaffected by invalid set calls
- **Description:** Attempt invalid calls to set tools, then verify get tools still work.
- **Steps:**
  1. `set_rendering_quality` → `{ "quality": "extreme" }` (invalid — expect Zod error)
  2. `set_renderer` → `{ "renderer": "dx12" }` (invalid — expect Zod error)
  3. `get_rendering_settings` → `{}` (should still succeed)
  4. `get_rendering_info` → `{}` (should still succeed)
- **Expected result:** Steps 1 and 2 fail with validation errors. Steps 3 and 4 succeed normally, returning current (unchanged) settings. Invalid calls do not corrupt the read path.
- **Notes:** Validates that failed writes don't affect subsequent reads.

### Integration 7: Sequential overwrite of each setting
- **Description:** Set each rendering setting to one value, then overwrite with a different value. Verify the second value takes effect.
- **Steps:**
  1. `set_rendering_quality` → `{ "quality": "low" }`
  2. `set_rendering_quality` → `{ "quality": "high" }`
  3. `set_shadow_quality` → `{ "quality": "high" }`
  4. `set_shadow_quality` → `{ "quality": "low" }`
  5. `set_gi_quality` → `{ "quality": "ultra" }`
  6. `set_gi_quality` → `{ "quality": "medium" }`
  7. `set_anti_aliasing` → `{ "msaa": "2x" }`
  8. `set_anti_aliasing` → `{ "msaa": "8x", "fxaa": true }`
  9. `set_viewport_size` → `{ "width": 1280, "height": 720 }`
  10. `set_viewport_size` → `{ "width": 1920, "height": 1080 }`
  11. `set_window_settings` → `{ "mode": "windowed" }`
  12. `set_window_settings` → `{ "mode": "fullscreen", "vsync": false }`
  13. `get_rendering_settings` → `{}`
- **Expected result:** Step 13 shows the final values from steps 2, 4, 6, 8, 10, and 12. The initial values from steps 1, 3, 5, 7, 9, and 11 are overwritten.
- **Notes:** Comprehensive test of overwrite behavior for all mutable settings.

---

## Notes for Test Executors

1. **Godot bridge required.** All tools in this file forward requests to the Godot editor via `callGodot(bridge, ...)`. The Godot editor with the MCP plugin must be running for success-path tests.

2. **Zod validation happens before the bridge call.** Any invalid params are caught by Zod and never reach Godot. When testing invalid-param scenarios, the error will come from the MCP server's Zod layer, not from Godot.

3. **Stateful tools.** `set_rendering_quality`, `set_renderer`, `set_anti_aliasing`, `set_shadow_quality`, `set_gi_quality`, `set_viewport_size`, and `set_window_settings` all modify project settings that persist across sessions. Consider resetting to defaults between test runs or documenting the initial state before each test.

4. **Renderer-dependent behavior.** Some rendering settings may behave differently depending on which renderer is active (`forward_plus`, `mobile`, `gl_compatibility`). For example, MSAA 8x may not be supported on the mobile renderer, and TAA may only work on forward_plus. Tests that set AA or quality presets should note the active renderer in their results.

5. **Parameter coercion.** Zod does NOT coerce types (e.g., `"high"` is a string, `2` is a number, `[1920, 1080]` is an array). All parameters must be the exact JavaScript types expected by the Zod schema. Strings are not coerced to numbers; strings are not coerced to booleans.

6. **Optional vs. required.** Parameters without `.optional()` are required and will cause validation failure if missing. Parameters with `.optional()` can be omitted and will be `undefined`. Tools where ALL parameters are optional (`set_anti_aliasing`, `set_window_settings`) can be called with an empty `{}` object — this is a valid no-op.

7. **Enum validation.** `z.enum()` matches exactly — case-sensitive, no partial matches. `"High"` will fail for `['low', 'medium', 'high', 'ultra']`.

8. **The `Quality` type.** Imported from `shared-types.ts` as `z.enum(['low', 'medium', 'high', 'ultra'])`. Used identically by `set_rendering_quality`, `set_shadow_quality`, and `set_gi_quality`. All three tools have the same parameter name (`quality`) and the same enum values, but operate on different rendering subsystems.

9. **The `Size2D` type.** Imported from `shared-types.ts` as `z.tuple([z.number().int(), z.number().int()])`. Note that there is no `.positive()` or `.min()` constraint — zero and negative integers pass Zod validation (they will likely be rejected by Godot). The tuple requires exactly 2 elements — fewer or more will fail validation.

10. **Integer validation.** `z.number().int()` uses `Number.isInteger()` internally. Values like `60.0` pass because `Number.isInteger(60.0) === true` in JavaScript. Values like `60.5` fail.

11. **Float vs. Integer.** `z.number()` (used for `Quality` enum — actually an enum of strings, not numbers) accepts both integers and floats. The enum itself validates string values. For `set_viewport_size` and `set_window_settings` size, `.int()` is applied to number parameters.

12. **Empty `inputSchema: {}`.** The `get_rendering_settings` and `get_rendering_info` tools have empty schemas. Zod's empty object schema accepts any input (including `undefined`) and strips all fields — this means these tools gracefully handle extra params without error.
