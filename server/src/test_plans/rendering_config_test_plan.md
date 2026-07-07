# Rendering Config Tools — Test Plan

**Source file:** `server/src/tools/rendering_config.ts`  
**Number of tools:** 9  
**Godot bridge commands:** `rendering_config/get_settings`, `rendering_config/set_quality`, `rendering_config/set_renderer`, `rendering_config/set_anti_aliasing`, `rendering_config/set_shadow_quality`, `rendering_config/set_gi_quality`, `rendering_config/set_viewport_size`, `rendering_config/set_window_settings`, `rendering_config/get_rendering_info`

---

## Tool 1: `get_rendering_settings`

**Description:** Get all current rendering settings (renderer, quality, viewport, etc.)  
**Parameters:** None (empty `inputSchema`)  
**Handler:** `callGodot(bridge, 'rendering_config/get_settings')`  
**Expected result:** Returns a JSON object containing all current rendering configuration settings (renderer type, quality level, anti-aliasing state, shadow quality, GI quality, viewport dimensions, stretch settings, window settings, vsync state).

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 1 | Call with no arguments | `{}` | Valid JSON object with rendering settings keys | Simplest invocation. Should always succeed. |
| 2 | Call with extra ignored arg | `{"ignored": true}` | Valid JSON object (extra arg ignored) | Zod ignores unknown keys since no schema is defined. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 3 | Call when editor is disconnected | `{}` | Error: "Godot editor is not connected" or timeout | Tests bridge availability resilience. |
| 4 | Call with `null` body | `null` | Valid JSON object (body ignored, no schema) | MCP SDK may coerce null to `{}`. Either is acceptable. |

---

## Tool 2: `set_rendering_quality`

**Description:** Apply a rendering quality preset (sets multiple settings at once)  
**Handler:** `callGodot(bridge, 'rendering_config/set_quality', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `quality` | `Quality` enum | **Yes** | — | Quality preset level: `"low"`, `"medium"`, `"high"`, `"ultra"` |

The `Quality` type is defined in `shared-types.ts` as `z.enum(['low', 'medium', 'high', 'ultra'])`.

### Happy Path — Each Enum Value

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 5 | Set quality to `"low"` | `{"quality": "low"}` | Success; rendering quality set to low | Lowest quality preset. |
| 6 | Set quality to `"medium"` | `{"quality": "medium"}` | Success; rendering quality set to medium | Default/mid-range preset. |
| 7 | Set quality to `"high"` | `{"quality": "high"}` | Success; rendering quality set to high | High quality preset. |
| 8 | Set quality to `"ultra"` | `{"quality": "ultra"}` | Success; rendering quality set to ultra | Maximum quality preset. |

### Enum Value Transitions

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 9 | Transition: low → medium → high → ultra | Sequential calls | Each succeeds; quality increments | Verify state changes are applied in sequence. |
| 10 | Transition: ultra → low | `{"quality": "ultra"}` then `{"quality": "low"}` | Both succeed; quality downgrades | Large jump between extremes. |
| 11 | Re-set same value | `{"quality": "medium"}` × 2 | Both succeed (idempotent) | No error on re-setting same quality. |

### Enum Validation — Invalid Values

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 12 | Invalid enum: `"custom"` | `{"quality": "custom"}` | Zod validation error | Not in `['low', 'medium', 'high', 'ultra']`. |
| 13 | Invalid enum: empty string | `{"quality": ""}` | Zod validation error | Empty string not in enum. |
| 14 | Invalid enum: uppercase `"LOW"` | `{"quality": "LOW"}` | Zod validation error | Case-sensitive enum match. |
| 15 | Invalid enum: mixed case `"Medium"` | `{"quality": "Medium"}` | Zod validation error | Case-sensitive enum match. |
| 16 | Invalid enum: `"maximum"` | `{"quality": "maximum"}` | Zod validation error | Not in enum — "ultra" is the correct term. |
| 17 | Invalid type: number | `{"quality": 1}` | Zod validation error | Enum expects string, not number. |
| 18 | Invalid type: boolean | `{"quality": true}` | Zod validation error | Enum expects string, not boolean. |
| 19 | Invalid type: object | `{"quality": {}}` | Zod validation error | Enum expects string, not object. |
| 20 | Invalid type: array | `{"quality": ["low"]}` | Zod validation error | Enum expects string, not array. |

### Required Parameter Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 21 | Missing required `quality` | `{}` | Zod validation error | `quality` is required, not optional. |
| 22 | Extra unknown param with valid quality | `{"quality": "high", "unknown_key": 123}` | Success (unknown key ignored) | Zod ignores unknown keys. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 23 | Editor disconnected | `{"quality": "high"}` | Connection error | Standard disconnected behavior. |
| 24 | Set quality during gameplay (if runtime makes it special) | `{"quality": "low"}` | Should still succeed | Editor-setting tools generally work even when game is running. |

---

## Tool 3: `set_renderer`

**Description:** Set the rendering method/renderer for the project  
**Handler:** `callGodot(bridge, 'rendering_config/set_renderer', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `renderer` | `enum` | **Yes** | — | Rendering backend: `"forward_plus"`, `"mobile"`, `"gl_compatibility"` |

### Happy Path — Each Enum Value

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 25 | Set renderer to `"forward_plus"` | `{"renderer": "forward_plus"}` | Success; renderer set to Forward+ | Modern high-end renderer (Godot 4 default). |
| 26 | Set renderer to `"mobile"` | `{"renderer": "mobile"}` | Success; renderer set to Mobile | Optimized for mobile/VR devices. |
| 27 | Set renderer to `"gl_compatibility"` | `{"renderer": "gl_compatibility"}` | Success; renderer set to GL Compatibility | Legacy OpenGL renderer for older hardware. |

### Renderer Transitions

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 28 | Cycle all three: forward_plus → mobile → gl_compatibility | Sequential calls | Each succeeds | Full renderer cycle. |
| 29 | Reverse cycle: gl_compatibility → mobile → forward_plus | Sequential calls | Each succeeds | Reverse full cycle. |
| 30 | Re-set same renderer | `{"renderer": "forward_plus"}` × 2 | Both succeed (idempotent) | No error on re-setting same renderer. |

### Enum Validation — Invalid Values

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 31 | Invalid renderer: `"vulkan"` | `{"renderer": "vulkan"}` | Zod validation error | Not in enum — Godot uses "forward_plus" not "vulkan". |
| 32 | Invalid renderer: `"opengl"` | `{"renderer": "opengl"}` | Zod validation error | Not in enum — "gl_compatibility" is the correct name. |
| 33 | Invalid renderer: `"directx"` | `{"renderer": "directx"}` | Zod validation error | Not a Godot renderer name. |
| 34 | Invalid renderer: empty string | `{"renderer": ""}` | Zod validation error | Empty string not in enum. |
| 35 | Invalid renderer: uppercase | `{"renderer": "FORWARD_PLUS"}` | Zod validation error | Case-sensitive enum match. |
| 36 | Invalid renderer: `"Forward_Plus"` | `{"renderer": "Forward_Plus"}` | Zod validation error | Case-sensitive — PascalCase variant fails. |
| 37 | Invalid type: number | `{"renderer": 0}` | Zod validation error | Enum expects string. |
| 38 | Invalid type: boolean | `{"renderer": false}` | Zod validation error | Enum expects string. |

### Required Parameter Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 39 | Missing required `renderer` | `{}` | Zod validation error | `renderer` is required, not optional. |
| 40 | Extra unknown param with valid renderer | `{"renderer": "mobile", "comment": "test"}` | Success (unknown key ignored) | Zod ignores unknown keys. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 41 | Editor disconnected | `{"renderer": "forward_plus"}` | Connection error | Standard disconnected behavior. |
| 42 | Set renderer while project has unsaved changes | `{"renderer": "mobile"}` | Should succeed; Godot may require project reload | Renderer change often triggers a project reload dialog. |

---

## Tool 4: `set_anti_aliasing`

**Description:** Configure anti-aliasing settings (MSAA, FXAA, TAA)  
**Handler:** `callGodot(bridge, 'rendering_config/set_anti_aliasing', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `msaa` | `enum("2x" \| "4x" \| "8x")` | No | — | MSAA level (omit to disable) |
| `fxaa` | `boolean` | No | — | Enable/disable FXAA |
| `taa` | `boolean` | No | — | Enable/disable TAA |

All three parameters are optional. Calling with no parameters is a no-op.

### Happy Path — Single Parameter

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 43 | Enable MSAA 2x | `{"msaa": "2x"}` | Success; MSAA set to 2x | Lowest MSAA level. |
| 44 | Enable MSAA 4x | `{"msaa": "4x"}` | Success; MSAA set to 4x | Mid MSAA level. |
| 45 | Enable MSAA 8x | `{"msaa": "8x"}` | Success; MSAA set to 8x | Highest MSAA level. |
| 46 | Enable FXAA | `{"fxaa": true}` | Success; FXAA enabled | Post-process anti-aliasing. |
| 47 | Disable FXAA | `{"fxaa": false}` | Success; FXAA disabled | Core use case. |
| 48 | Enable TAA | `{"taa": true}` | Success; TAA enabled | Temporal anti-aliasing. |
| 49 | Disable TAA | `{"taa": false}` | Success; TAA disabled | Core use case. |

### Happy Path — Combinations

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 50 | MSAA 4x + FXAA | `{"msaa": "4x", "fxaa": true}` | Success; both set | Combined MSAA and FXAA. |
| 51 | MSAA 2x + TAA | `{"msaa": "2x", "taa": true}` | Success; both set | Combined MSAA and TAA. |
| 52 | MSAA 8x + FXAA + TAA | `{"msaa": "8x", "fxaa": true, "taa": true}` | Success; all three set | Maximum anti-aliasing configuration. |
| 53 | All disabled | `{"msaa": "2x", "fxaa": false, "taa": false}` — but MSAA has no "off" enum value | MSAA set to 2x, FXAA/TAA false | MSAA cannot be explicitly "off" via enum — omitting `msaa` is the only "off" path. |
| 54 | Only FXAA + TAA (no MSAA) | `{"fxaa": true, "taa": true}` | Success; FXAA and TAA enabled, MSAA unchanged | Omits `msaa` entirely. |
| 55 | No params (no-op) | `{}` | Success (nothing changed) | All params optional; empty call is valid. |

### MSAA Enum Values — Each

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 56 | MSAA `"2x"` (explicit) | `{"msaa": "2x"}` | Success | Minimum MSAA. |
| 57 | MSAA `"4x"` (explicit) | `{"msaa": "4x"}` | Success | Mid-range MSAA. |
| 58 | MSAA `"8x"` (explicit) | `{"msaa": "8x"}` | Success | Maximum MSAA. |

### MSAA Enum Validation — Invalid Values

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 59 | Invalid MSAA: `"1x"` | `{"msaa": "1x"}` | Zod validation error | Not in enum `['2x', '4x', '8x']`. |
| 60 | Invalid MSAA: `"16x"` | `{"msaa": "16x"}` | Zod validation error | Not in enum — Godot max is 8x. |
| 61 | Invalid MSAA: `"off"` | `{"msaa": "off"}` | Zod validation error | Not an enum value. Omit the param to disable. |
| 62 | Invalid MSAA: `""` (empty) | `{"msaa": ""}` | Zod validation error | Empty string not in enum. |
| 63 | Invalid MSAA: `"2X"` (uppercase) | `{"msaa": "2X"}` | Zod validation error | Case-sensitive enum match. |
| 64 | Invalid MSAA: number `4` | `{"msaa": 4}` | Zod validation error | Enum expects string, not number. |
| 65 | Invalid MSAA: boolean | `{"msaa": true}` | Zod validation error | Enum expects string. |

### Boolean Parameter Validation (`fxaa`, `taa`)

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 66 | fxaa as string `"true"` | `{"fxaa": "true"}` | Zod validation error | Boolean expected, not string. |
| 67 | fxaa as number `1` | `{"fxaa": 1}` | Zod validation error | Boolean expected, not number. |
| 68 | fxaa as number `0` | `{"fxaa": 0}` | Zod validation error | Boolean expected — 0 is falsy but not boolean. |
| 69 | taa as string `"false"` | `{"taa": "false"}` | Zod validation error | Boolean expected, not string. |
| 70 | taa as object `{}` | `{"taa": {}}` | Zod validation error | Boolean expected. |
| 71 | fxaa as `null` | `{"fxaa": null}` | Zod validation error (or treated as omission) | `null` is not `boolean`. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 72 | Re-set same MSAA | `{"msaa": "4x"}` × 2 | Both succeed (idempotent) | No error on re-setting. |
| 73 | Toggle FXAA: on → off → on | `{"fxaa": true}`, `{"fxaa": false}`, `{"fxaa": true}` | Each succeeds; state toggles | Verify boolean toggle persistence. |
| 74 | Toggle TAA: on → off → on | `{"taa": true}`, `{"taa": false}`, `{"taa": true}` | Each succeeds; state toggles | Verify boolean toggle persistence. |
| 75 | Editor disconnected | `{"msaa": "4x"}` | Connection error | Standard behavior. |
| 76 | Extra unknown param | `{"msaa": "8x", "taa": true, "extra": "value"}` | Success (extra ignored) | Zod ignores unknown keys. |

---

## Tool 5: `set_shadow_quality`

**Description:** Set shadow rendering quality preset  
**Handler:** `callGodot(bridge, 'rendering_config/set_shadow_quality', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `quality` | `Quality` enum | **Yes** | — | Shadow quality level: `"low"`, `"medium"`, `"high"`, `"ultra"` |

### Happy Path — Each Enum Value

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 77 | Set shadow quality to `"low"` | `{"quality": "low"}` | Success; shadow quality set to low | Lowest shadow quality. |
| 78 | Set shadow quality to `"medium"` | `{"quality": "medium"}` | Success; shadow quality set to medium | Default shadow quality. |
| 79 | Set shadow quality to `"high"` | `{"quality": "high"}` | Success; shadow quality set to high | High shadow quality. |
| 80 | Set shadow quality to `"ultra"` | `{"quality": "ultra"}` | Success; shadow quality set to ultra | Maximum shadow quality (most expensive). |

### Quality Transitions

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 81 | Step through all levels | `low` → `medium` → `high` → `ultra` | Each succeeds | Full quality spectrum. |
| 82 | Jump from ultra to low | `{"quality": "ultra"}` then `{"quality": "low"}` | Both succeed | Extreme jump. |
| 83 | Re-set same value | `{"quality": "high"}` × 2 | Both succeed (idempotent) | No error. |

### Enum Validation — Invalid Values

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 84 | Invalid quality: `"custom"` | `{"quality": "custom"}` | Zod validation error | Not in enum. |
| 85 | Invalid quality: empty string | `{"quality": ""}` | Zod validation error | Empty string not in enum. |
| 86 | Invalid quality: uppercase | `{"quality": "HIGH"}` | Zod validation error | Case-sensitive. |
| 87 | Invalid quality: number | `{"quality": 2}` | Zod validation error | Enum expects string. |
| 88 | Invalid quality: boolean | `{"quality": true}` | Zod validation error | Enum expects string. |

### Required Parameter Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 89 | Missing required `quality` | `{}` | Zod validation error | `quality` is required. |
| 90 | Extra unknown param | `{"quality": "medium", "shadow_type": "hard"}` | Success (extra ignored) | Zod ignores unknown keys. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 91 | Editor disconnected | `{"quality": "high"}` | Connection error | Standard behavior. |

---

## Tool 6: `set_gi_quality`

**Description:** Set global illumination quality preset  
**Handler:** `callGodot(bridge, 'rendering_config/set_gi_quality', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `quality` | `Quality` enum | **Yes** | — | GI quality level: `"low"`, `"medium"`, `"high"`, `"ultra"` |

### Happy Path — Each Enum Value

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 92 | Set GI quality to `"low"` | `{"quality": "low"}` | Success; GI quality set to low | Lowest GI quality. |
| 93 | Set GI quality to `"medium"` | `{"quality": "medium"}` | Success; GI quality set to medium | Default GI quality. |
| 94 | Set GI quality to `"high"` | `{"quality": "high"}` | Success; GI quality set to high | High GI quality. |
| 95 | Set GI quality to `"ultra"` | `{"quality": "ultra"}` | Success; GI quality set to ultra | Maximum GI quality (most expensive, highest fidelity). |

### Quality Transitions

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 96 | Step through all levels | `low` → `medium` → `high` → `ultra` | Each succeeds | Full GI quality spectrum. |
| 97 | Jump from ultra to low | `{"quality": "ultra"}` then `{"quality": "low"}` | Both succeed | Extreme jump. |
| 98 | Re-set same value | `{"quality": "medium"}` × 2 | Both succeed (idempotent) | No error. |

### Enum Validation — Invalid Values

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 99 | Invalid quality: `"maximum"` | `{"quality": "maximum"}` | Zod validation error | Not in enum. |
| 100 | Invalid quality: `""` | `{"quality": ""}` | Zod validation error | Empty string not in enum. |
| 101 | Invalid quality: `"High"` | `{"quality": "High"}` | Zod validation error | Case-sensitive. |
| 102 | Invalid quality: number | `{"quality": 0}` | Zod validation error | Enum expects string. |
| 103 | Invalid quality: boolean | `{"quality": false}` | Zod validation error | Enum expects string. |

### Required Parameter Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 104 | Missing required `quality` | `{}` | Zod validation error | `quality` is required. |
| 105 | Extra unknown param | `{"quality": "low", "gi_type": "voxel"}` | Success (extra ignored) | Zod ignores unknown keys. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 106 | Editor disconnected | `{"quality": "high"}` | Connection error | Standard behavior. |
| 107 | GI quality set on renderer that doesn't support GI (GL Compatibility) | `{"quality": "ultra"}` | May succeed but GI won't render on GL Compatibility | GL Compatibility lacks full GI support. |

---

## Tool 7: `set_viewport_size`

**Description:** Set the game viewport dimensions and stretch settings  
**Handler:** `callGodot(bridge, 'rendering_config/set_viewport_size', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `width` | `number` (int, positive) | **Yes** | — | Viewport width in pixels |
| `height` | `number` (int, positive) | **Yes** | — | Viewport height in pixels |
| `stretch_mode` | `enum` | No | — | Stretch mode: `"disabled"`, `"canvas_items"`, `"viewport"` |
| `stretch_aspect` | `enum` | No | — | Stretch aspect ratio: `"ignore"`, `"keep"`, `"keep_width"`, `"keep_height"`, `"expand"` |

### Happy Path — Dimensions Only

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 108 | Standard 1920×1080 | `{"width": 1920, "height": 1080}` | Success; viewport set to 1920×1080 | Standard Full HD. |
| 109 | 1280×720 (HD) | `{"width": 1280, "height": 720}` | Success; viewport set to 1280×720 | Common HD resolution. |
| 110 | 3840×2160 (4K) | `{"width": 3840, "height": 2160}` | Success; viewport set to 3840×2160 | 4K UHD. |
| 111 | Small resolution 320×240 | `{"width": 320, "height": 240}` | Success; viewport set to 320×240 | Retro/lo-fi resolution. |
| 112 | Minimum: 1×1 | `{"width": 1, "height": 1}` | Success; viewport set to 1×1 | `.int().positive()` allows 1; Godot may clamp to a practical minimum. |
| 113 | Square: 1080×1080 | `{"width": 1080, "height": 1080}` | Success | Square viewport. |
| 114 | Ultra-wide: 3440×1440 | `{"width": 3440, "height": 1440}` | Success | Ultra-wide aspect ratio. |

### Happy Path — Stretch Mode (Each Enum Value)

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 115 | Stretch mode `"disabled"` | `{"width": 1920, "height": 1080, "stretch_mode": "disabled"}` | Success; stretch disabled | No stretch applied. |
| 116 | Stretch mode `"canvas_items"` | `{"width": 1920, "height": 1080, "stretch_mode": "canvas_items"}` | Success; 2D stretch set | Stretches 2D canvas items. |
| 117 | Stretch mode `"viewport"` | `{"width": 1920, "height": 1080, "stretch_mode": "viewport"}` | Success; viewport stretch set | Stretches the entire viewport. |

### Happy Path — Stretch Aspect (Each Enum Value)

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 118 | Aspect `"ignore"` | `{"width": 1920, "height": 1080, "stretch_aspect": "ignore"}` | Success; aspect ignored | Stretches to fill, ignoring aspect ratio. |
| 119 | Aspect `"keep"` | `{"width": 1920, "height": 1080, "stretch_aspect": "keep"}` | Success; aspect kept | Preserves aspect, adds black bars. |
| 120 | Aspect `"keep_width"` | `{"width": 1920, "height": 1080, "stretch_aspect": "keep_width"}` | Success; keep based on width | Width-constrained aspect preservation. |
| 121 | Aspect `"keep_height"` | `{"width": 1920, "height": 1080, "stretch_aspect": "keep_height"}` | Success; keep based on height | Height-constrained aspect preservation. |
| 122 | Aspect `"expand"` | `{"width": 1920, "height": 1080, "stretch_aspect": "expand"}` | Success; expand | Expands to fill, may show more content. |

### Happy Path — Combined Stretch

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 123 | canvas_items + keep | `{"width": 1920, "height": 1080, "stretch_mode": "canvas_items", "stretch_aspect": "keep"}` | Success | Classic 2D pixel-art setup. |
| 124 | viewport + expand | `{"width": 1920, "height": 1080, "stretch_mode": "viewport", "stretch_aspect": "expand"}` | Success | 3D viewport fill mode. |
| 125 | disabled + keep (should work but keep is moot) | `{"width": 1920, "height": 1080, "stretch_mode": "disabled", "stretch_aspect": "keep"}` | Success; stretch disabled, aspect param may be ignored | `keep` aspect is meaningless when stretch is disabled. |

### Width/Height Validation — Positive Integer

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 126 | width = 0 | `{"width": 0, "height": 1080}` | Zod validation error | `.positive()` excludes 0. |
| 127 | width = -1 | `{"width": -1, "height": 1080}` | Zod validation error | `.positive()` excludes negatives. |
| 128 | height = 0 | `{"width": 1920, "height": 0}` | Zod validation error | `.positive()` excludes 0. |
| 129 | height = -1 | `{"width": 1920, "height": -1}` | Zod validation error | `.positive()` excludes negatives. |
| 130 | Both negative | `{"width": -100, "height": -100}` | Zod validation error | Both fail validation. |
| 131 | width as float `1920.5` | `{"width": 1920.5, "height": 1080}` | Zod validation error | `.int()` rejects non-integers. |
| 132 | height as float | `{"width": 1920, "height": 1080.5}` | Zod validation error | `.int()` rejects non-integers. |
| 133 | width as string `"1920"` | `{"width": "1920", "height": 1080}` | Zod validation error | String not accepted. |
| 134 | height as string | `{"width": 1920, "height": "1080"}` | Zod validation error | String not accepted. |
| 135 | width as boolean | `{"width": true, "height": 1080}` | Zod validation error | Boolean not accepted. |
| 136 | Large but valid (8192×8192) | `{"width": 8192, "height": 8192}` | Passes Zod; Godot may reject or cap | No `.max()` constraint — Godot enforces practical limits. |
| 137 | Zero-width (boundary) | `{"width": 0, "height": 1}` | Zod validation error | `.positive()` uses `> 0`, not `>= 0`. |

### Required Parameter Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 138 | Missing `width` | `{"height": 1080}` | Zod validation error | `width` is required. |
| 139 | Missing `height` | `{"width": 1920}` | Zod validation error | `height` is required. |
| 140 | Missing both | `{}` | Zod validation error | Both required params missing. |

### Stretch Mode Enum Validation — Invalid Values

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 141 | Invalid mode: `"scale"` | `{"width": 1920, "height": 1080, "stretch_mode": "scale"}` | Zod validation error | Not in enum. |
| 142 | Invalid mode: `""` | `{"width": 1920, "height": 1080, "stretch_mode": ""}` | Zod validation error | Empty string not in enum. |
| 143 | Invalid mode: `"CANVAS_ITEMS"` | `{"width": 1920, "height": 1080, "stretch_mode": "CANVAS_ITEMS"}` | Zod validation error | Case-sensitive. |
| 144 | Invalid mode: number | `{"width": 1920, "height": 1080, "stretch_mode": 1}` | Zod validation error | Enum expects string. |
| 145 | Invalid mode: boolean | `{"width": 1920, "height": 1080, "stretch_mode": false}` | Zod validation error | Enum expects string. |

### Stretch Aspect Enum Validation — Invalid Values

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 146 | Invalid aspect: `"fit"` | `{"width": 1920, "height": 1080, "stretch_aspect": "fit"}` | Zod validation error | Not in enum. |
| 147 | Invalid aspect: `""` | `{"width": 1920, "height": 1080, "stretch_aspect": ""}` | Zod validation error | Empty string not in enum. |
| 148 | Invalid aspect: `"KEEP"` | `{"width": 1920, "height": 1080, "stretch_aspect": "KEEP"}` | Zod validation error | Case-sensitive. |
| 149 | Invalid aspect: number | `{"width": 1920, "height": 1080, "stretch_aspect": 0}` | Zod validation error | Enum expects string. |
| 150 | Invalid aspect: boolean | `{"width": 1920, "height": 1080, "stretch_aspect": true}` | Zod validation error | Enum expects string. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 151 | Only set dimensions (no stretch) | `{"width": 1920, "height": 1080}` | Success; stretch settings unchanged | Omitting stretch params leaves current settings intact. |
| 152 | Only stretch_mode (no dimensions adjustment) | N/A | Not possible — width/height are required params | Cannot call without width/height. |
| 153 | Extra unknown param | `{"width": 1920, "height": 1080, "stretch_mode": "viewport", "unknown": "val"}` | Success (extra ignored) | Zod ignores unknown keys. |
| 154 | Editor disconnected | `{"width": 1920, "height": 1080}` | Connection error | Standard behavior. |
| 155 | Set same dimensions twice | `{"width": 1280, "height": 720}` × 2 | Both succeed (idempotent) | No error. |
| 156 | 0×0 viewport | `{"width": 0, "height": 0}` | Zod validation error | `.positive()` rejects 0. |

---

## Tool 8: `set_window_settings`

**Description:** Configure the application window size, mode, and vsync  
**Handler:** `callGodot(bridge, 'rendering_config/set_window_settings', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `size` | `Size2D` (`[number(int), number(int)]`) | No | — | Window size `[width, height]` |
| `mode` | `enum` | No | — | Window display mode: `"windowed"`, `"fullscreen"`, `"exclusive_fullscreen"` |
| `vsync` | `boolean` | No | — | Enable/disable vertical sync |

All three parameters are optional. Calling with no parameters is a no-op.

### Happy Path — Window Mode (Each Enum Value)

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 157 | Set mode to `"windowed"` | `{"mode": "windowed"}` | Success; window set to windowed mode | Standard windowed mode. |
| 158 | Set mode to `"fullscreen"` | `{"mode": "fullscreen"}` | Success; window set to fullscreen | Borderless fullscreen window. |
| 159 | Set mode to `"exclusive_fullscreen"` | `{"mode": "exclusive_fullscreen"}` | Success; exclusive fullscreen | Exclusive fullscreen with display control. |

### Happy Path — Window Size

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 160 | Set size to 1920×1080 | `{"size": [1920, 1080]}` | Success; window resized to 1920×1080 | Standard Full HD window. |
| 161 | Set size to 1280×720 | `{"size": [1280, 720]}` | Success; window resized to 1280×720 | Common HD. |
| 162 | Set size to 800×600 | `{"size": [800, 600]}` | Success; window resized to 800×600 | Legacy resolution. |
| 163 | Set size to 3840×2160 (4K) | `{"size": [3840, 2160]}` | Success; window resized to 4K | 4K resolution. |
| 164 | Minimum viable size (1×1) | `{"size": [1, 1]}` | Success; Godot may clamp to window manager minimum | `.int()` allows 1. |

### Happy Path — Vsync

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 165 | Enable vsync | `{"vsync": true}` | Success; vsync enabled | Vertical sync on. |
| 166 | Disable vsync | `{"vsync": false}` | Success; vsync disabled | Vertical sync off. |

### Happy Path — Combinations

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 167 | Fullscreen + vsync | `{"mode": "fullscreen", "vsync": true}` | Success; fullscreen with vsync | Common gaming config. |
| 168 | Windowed mode + custom size + vsync off | `{"mode": "windowed", "size": [1600, 900], "vsync": false}` | Success; windowed 1600×900, no vsync | Complete window config. |
| 169 | Exclusive fullscreen + size + vsync | `{"mode": "exclusive_fullscreen", "size": [1920, 1080], "vsync": true}` | Success; exclusive fullscreen at 1080p with vsync | Full config. |
| 170 | Only size (no mode/vsync) | `{"size": [1024, 768]}` | Success; window resized, mode unchanged | Single param. |
| 171 | Only vsync (toggle) | `{"vsync": false}` | Success; vsync disabled, window unchanged | Single boolean param. |
| 172 | No params (no-op) | `{}` | Success (nothing changed) | All params optional; empty call is valid. |

### Mode Enum Validation — Invalid Values

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 173 | Invalid mode: `"borderless"` | `{"mode": "borderless"}` | Zod validation error | Not in enum — Godot 4's borderless is "fullscreen". |
| 174 | Invalid mode: `""` | `{"mode": ""}` | Zod validation error | Empty string not in enum. |
| 175 | Invalid mode: `"FULLSCREEN"` | `{"mode": "FULLSCREEN"}` | Zod validation error | Case-sensitive. |
| 176 | Invalid mode: `"Exclusive_Fullscreen"` | `{"mode": "Exclusive_Fullscreen"}` | Zod validation error | Case-sensitive — enum values are all lowercase. |
| 177 | Invalid mode: number | `{"mode": 0}` | Zod validation error | Enum expects string. |
| 178 | Invalid mode: boolean | `{"mode": false}` | Zod validation error | Enum expects string. |

### Size Validation — Size2D Tuple

`Size2D = z.tuple([z.number().int(), z.number().int()])` — no `.positive()` constraint, so 0 and negatives pass Zod validation.

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 179 | Size with float values | `{"size": [1920.5, 1080.5]}` | Zod validation error | `.int()` rejects non-integers. |
| 180 | Size with negative width | `{"size": [-100, 300]}` | Passes Zod; Godot may reject or clamp | No `.positive()` constraint on Size2D. |
| 181 | Size with negative height | `{"size": [800, -600]}` | Passes Zod; Godot may reject or clamp | No `.positive()` constraint. |
| 182 | Size with zero width | `{"size": [0, 600]}` | Passes Zod; Godot may reject or clamp | `.int()` allows 0. |
| 183 | Size with zero height | `{"size": [800, 0]}` | Passes Zod; Godot may reject or clamp | `.int()` allows 0. |
| 184 | Size [0, 0] | `{"size": [0, 0]}` | Passes Zod; Godot will likely reject or clamp | Both dimensions zero. |
| 185 | Size as object | `{"size": {"width": 1920, "height": 1080}}` | Zod validation error | Tuple expected, not object. |
| 186 | Size as string | `{"size": "1920x1080"}` | Zod validation error | Tuple expected, not string. |
| 187 | Size with wrong arity (1 element) | `{"size": [1920]}` | Zod validation error | Tuple requires exactly 2 elements. |
| 188 | Size with wrong arity (3 elements) | `{"size": [1920, 1080, 60]}` | Zod validation error | Tuple requires exactly 2 elements. |
| 189 | Size with string elements | `{"size": ["1920", "1080"]}` | Zod validation error | `.int()` rejects strings. |
| 190 | Size with boolean elements | `{"size": [true, false]}` | Zod validation error | `.int()` rejects booleans. |
| 191 | Size with mixed types | `{"size": [1920, "1080"]}` | Zod validation error | Both elements must be int. |

### Vsync Boolean Validation

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 192 | vsync as string `"true"` | `{"vsync": "true"}` | Zod validation error | Boolean expected. |
| 193 | vsync as number `1` | `{"vsync": 1}` | Zod validation error | Boolean expected. |
| 194 | vsync as number `0` | `{"vsync": 0}` | Zod validation error | Boolean expected. |
| 195 | vsync as `null` | `{"vsync": null}` | Zod validation error | `null` is not `boolean`. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 196 | Toggle vsync: on → off → on | `{"vsync": true}`, `{"vsync": false}`, `{"vsync": true}` | Each succeeds; state toggles | Verify boolean toggle persistence. |
| 197 | Mode cycle: windowed → fullscreen → exclusive → windowed | Sequential calls | Each succeeds | Full mode cycle. |
| 198 | Re-set same mode | `{"mode": "windowed"}` × 2 | Both succeed (idempotent) | No error. |
| 199 | Editor disconnected | `{"mode": "fullscreen"}` | Connection error | Standard behavior. |
| 200 | Extra unknown param | `{"mode": "fullscreen", "vsync": true, "fps_limit": 60}` | Success (extra ignored) | Zod ignores unknown keys. |

---

## Tool 9: `get_rendering_info`

**Description:** Get GPU info, VRAM usage, draw calls, and rendering statistics  
**Parameters:** None (empty `inputSchema`)  
**Handler:** `callGodot(bridge, 'rendering_config/get_rendering_info')`  
**Expected result:** Returns a JSON object containing GPU information (vendor, renderer string), VRAM usage statistics, draw call counts, and other rendering performance data. This tool is read-only and should work in both editor and runtime.

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 201 | Call with no arguments | `{}` | Valid JSON object with GPU info, VRAM, draw calls, rendering stats | Simplest invocation. Should always succeed. |
| 202 | Call with extra ignored arg | `{"ignored": true}` | Valid JSON object (extra arg ignored) | Zod ignores unknown keys. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 203 | Call when editor is disconnected | `{}` | Error: "Godot editor is not connected" or timeout | Tests bridge availability resilience. |
| 204 | Call with `null` body | `null` | Valid JSON object (body ignored) | MCP SDK may coerce null to `{}`. |
| 205 | Call during gameplay | `{}` | Returns runtime rendering statistics | Should provide live rendering data during gameplay. |
| 206 | Call immediately after project load | `{}` | Valid JSON; stats may show low usage | Fresh project has minimal rendering load. |

---

## Integration / Cross-Tool Scenarios

| # | Scenario | Steps | Expected result | Notes |
|---|----------|-------|-----------------|-------|
| 207 | Full rendering config round-trip | 1. `get_rendering_settings` to read baseline<br>2. `set_rendering_quality({"quality": "ultra"})`<br>3. `set_renderer({"renderer": "forward_plus"})`<br>4. `set_anti_aliasing({"msaa": "8x", "taa": true})`<br>5. `set_shadow_quality({"quality": "high"})`<br>6. `set_gi_quality({"quality": "medium"})`<br>7. `set_viewport_size({"width": 1920, "height": 1080, "stretch_mode": "viewport", "stretch_aspect": "expand"})`<br>8. `get_rendering_settings` to verify changes | All steps succeed; final get shows updated values | Full rendering pipeline configuration workflow. |
| 208 | Quality preset cascade | 1. `set_rendering_quality({"quality": "low"})`<br>2. `set_shadow_quality({"quality": "low"})`<br>3. `set_gi_quality({"quality": "low"})`<br>4. `get_rendering_settings` | All succeed; settings reflect low preset across all quality axes | Minimum quality configuration for low-end hardware. |
| 209 | Quality preset cascade (ultra) | 1. `set_rendering_quality({"quality": "ultra"})`<br>2. `set_shadow_quality({"quality": "ultra"})`<br>3. `set_gi_quality({"quality": "ultra"})`<br>4. `set_anti_aliasing({"msaa": "8x", "fxaa": true, "taa": true})`<br>5. `get_rendering_settings` | All succeed; maximum quality | Ultra preset for high-end hardware. |
| 210 | Anti-aliasing toggle cycle with verification | 1. `set_anti_aliasing({"msaa": "2x", "fxaa": false, "taa": false})`<br>2. `get_rendering_settings` (verify)<br>3. `set_anti_aliasing({"msaa": "4x", "fxaa": true, "taa": false})`<br>4. `get_rendering_settings` (verify)<br>5. `set_anti_aliasing({"msaa": "8x", "fxaa": true, "taa": true})`<br>6. `get_rendering_settings` (verify) | All states correct after each step | Full AA configuration cycle. |
| 211 | Window + viewport coordination | 1. `set_window_settings({"mode": "windowed", "size": [1600, 900]})`<br>2. `set_viewport_size({"width": 1600, "height": 900, "stretch_mode": "canvas_items", "stretch_aspect": "keep"})`<br>3. `get_rendering_settings` (verify both) | Window and viewport sizes match; stretch active | Coordinated window+viewport setup for 2D game. |
| 212 | Renderer change with quality verification | 1. `set_renderer({"renderer": "gl_compatibility"})`<br>2. `get_rendering_settings` (verify renderer changed)<br>3. `set_renderer({"renderer": "forward_plus"})`<br>4. `get_rendering_settings` (verify renderer changed back) | Both transitions succeed; get reflects correct renderer | Renderer round-trip. |
| 213 | Renderer change + quality reset | 1. `set_renderer({"renderer": "mobile"})`<br>2. `set_rendering_quality({"quality": "low"})`<br>3. `get_rendering_info` and `get_rendering_settings` | Both succeed; renderer is mobile, quality is low | Renderer plus quality preset together. |
| 214 | Window mode cycle with vsync toggles | 1. `set_window_settings({"mode": "windowed", "vsync": false})`<br>2. `set_window_settings({"mode": "fullscreen", "vsync": true})`<br>3. `set_window_settings({"mode": "exclusive_fullscreen", "vsync": true})`<br>4. `set_window_settings({"mode": "windowed", "vsync": false})` | Each succeeds; state transitions correctly | Full window mode + vsync cycle. |
| 215 | Rendering info before and after quality changes | 1. `get_rendering_info` (baseline)<br>2. `set_rendering_quality({"quality": "ultra"})`<br>3. `get_rendering_info` (post-change)<br>4. `set_rendering_quality({"quality": "low"})`<br>5. `get_rendering_info` (post-downgrade) | Rendering info differs after quality changes (e.g., shadow map sizes, GI resolution) | Verify that quality presets actually change rendering behavior. |

---

## Summary: Parameter Coverage

| Tool | Parameter | Type | Required | Default | Enums / Constraints |
|------|-----------|------|----------|---------|---------------------|
| `get_rendering_settings` | (none) | — | — | — | — |
| `set_rendering_quality` | `quality` | `Quality` enum | **Yes** | — | `"low"`, `"medium"`, `"high"`, `"ultra"` |
| `set_renderer` | `renderer` | enum | **Yes** | — | `"forward_plus"`, `"mobile"`, `"gl_compatibility"` |
| `set_anti_aliasing` | `msaa` | enum | No | — | `"2x"`, `"4x"`, `"8x"` |
| `set_anti_aliasing` | `fxaa` | boolean | No | — | — |
| `set_anti_aliasing` | `taa` | boolean | No | — | — |
| `set_shadow_quality` | `quality` | `Quality` enum | **Yes** | — | `"low"`, `"medium"`, `"high"`, `"ultra"` |
| `set_gi_quality` | `quality` | `Quality` enum | **Yes** | — | `"low"`, `"medium"`, `"high"`, `"ultra"` |
| `set_viewport_size` | `width` | number (int, positive) | **Yes** | — | `.int().positive()` |
| `set_viewport_size` | `height` | number (int, positive) | **Yes** | — | `.int().positive()` |
| `set_viewport_size` | `stretch_mode` | enum | No | — | `"disabled"`, `"canvas_items"`, `"viewport"` |
| `set_viewport_size` | `stretch_aspect` | enum | No | — | `"ignore"`, `"keep"`, `"keep_width"`, `"keep_height"`, `"expand"` |
| `set_window_settings` | `size` | `Size2D` `[int, int]` | No | — | Tuple of 2 integers (no positive/negative constraint) |
| `set_window_settings` | `mode` | enum | No | — | `"windowed"`, `"fullscreen"`, `"exclusive_fullscreen"` |
| `set_window_settings` | `vsync` | boolean | No | — | — |
| `get_rendering_info` | (none) | — | — | — | — |

### Enum Value Coverage Checklist

| Enum | Values | Tools Using It | All Values Tested? |
|------|--------|---------------|---------------------|
| `Quality` | `low`, `medium`, `high`, `ultra` | `set_rendering_quality`, `set_shadow_quality`, `set_gi_quality` | ✅ All 4 values × 3 tools |
| Renderer | `forward_plus`, `mobile`, `gl_compatibility` | `set_renderer` | ✅ All 3 values |
| MSAA | `2x`, `4x`, `8x` | `set_anti_aliasing` | ✅ All 3 values |
| Stretch mode | `disabled`, `canvas_items`, `viewport` | `set_viewport_size` | ✅ All 3 values |
| Stretch aspect | `ignore`, `keep`, `keep_width`, `keep_height`, `expand` | `set_viewport_size` | ✅ All 5 values |
| Window mode | `windowed`, `fullscreen`, `exclusive_fullscreen` | `set_window_settings` | ✅ All 3 values |

**Total scenarios:** 215  
**Coverage:** Every tool, every parameter, every enum value, boundary values, type validation (string, number, boolean, tuple, enum), idempotency, missing required params, extra unknown params, disconnected editor, combinatorial combinations (booleans, enums), integration round-trips.
