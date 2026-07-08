# Test Plan: Rendering Configuration Tools

> Source: `server/src/tools/rendering_config.ts`  
> Godot handler: `addons/godot_mcp/commands/rendering_config_commands.gd`  
> All tools call `callGodot(bridge, 'rendering_config/<method>', args)` which forwards via WebSocket to the Godot editor plugin.

---

## Overview

The `rendering_config.ts` file registers **9 MCP tools** (tools #1–6, #8–10 in the source comments; tool #7 `set_post_processing` exists in the GDScript handler but is **not registered** on the TS side). All tools communicate with the Godot editor via `callGodot`, which sends a JSON-RPC request over WebSocket and returns a `ToolResult` with `content[].text` (JSON string) or `isError: true` on failure.

### Tool-to-Method mapping

| MCP Tool Name | Godot RPC Method | Params |
|---|---|---|
| `get_rendering_settings` | `rendering_config/get_settings` | none |
| `set_rendering_quality` | `rendering_config/set_quality` | `quality` |
| `set_renderer` | `rendering_config/set_renderer` | `renderer` |
| `set_anti_aliasing` | `rendering_config/set_anti_aliasing` | `msaa?`, `fxaa?`, `taa?` |
| `set_shadow_quality` | `rendering_config/set_shadow_quality` | `quality` |
| `set_gi_quality` | `rendering_config/set_gi_quality` | `quality` |
| `set_viewport_size` | `rendering_config/set_viewport_size` | `width`, `height`, `stretch_mode?`, `stretch_aspect?` |
| `set_window_settings` | `rendering_config/set_window_settings` | `size?`, `mode?`, `vsync?` |
| `get_rendering_info` | `rendering_config/get_rendering_info` | none |

---

## Tool: `get_rendering_settings`

### Schema

```json
{
  "description": "Get all current rendering settings (renderer, quality, viewport, etc.)",
  "inputSchema": {}
}
```

No parameters. Returns a dictionary with: `renderer`, `viewport` (`width`, `height`), `anti_aliasing` (`msaa`, `fxaa`, `taa`), `shadows` (`quality`, `positional_shadow_size`), `gi` (`mode`), `post_processing` (`glow_enabled`, `ssao_enabled`, `ssr_enabled`, `sdfgi_enabled`, `volumetric_fog_enabled`), `window` (`mode`, `vsync`).

### Test Scenarios

#### 1. Happy path — get all rendering settings

**Description:** Call `get_rendering_settings` with no params and verify the response contains all expected sections.

**Call:**
```json
{
  "tool": "get_rendering_settings",
  "params": {}
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"settings\": {\"renderer\": \"forward_plus\", \"viewport\": {\"width\": 1152, \"height\": 648}, \"anti_aliasing\": {...}, \"shadows\": {...}, \"gi\": {...}, \"post_processing\": {...}, \"window\": {...}}}"
  }]
}
```

**Assertions:**
- Response has `success: true`
- `settings.renderer` is a string (one of `forward_plus`, `mobile`, `gl_compatibility`)
- `settings.viewport.width` and `settings.viewport.height` are positive integers
- `settings.anti_aliasing` contains `msaa` (int), `fxaa` (int 0 or 1), `taa` (bool)
- `settings.shadows` contains `quality` (int) and `positional_shadow_size` (int)
- `settings.post_processing` contains all 5 boolean keys
- `settings.window` contains `mode` (int) and `vsync` (int)

**Notes:** This is a read-only tool. It should never fail unless the bridge is disconnected.

---

## Tool: `set_rendering_quality`

### Schema

```json
{
  "description": "Apply a rendering quality preset (sets multiple settings at once)",
  "inputSchema": {
    "quality": { "type": "string", "enum": ["low", "medium", "high", "ultra"] }
  }
}
```

**Required:** `quality` — one of `low`, `medium`, `high`, `ultra`.

This is a composite tool: it sets shadow sizes, MSAA, FXAA, and GI half-resolution all at once.

| Quality | Directional Shadow | Positional Shadow | MSAA | FXAA | GI Half Res |
|---|---|---|---|---|---|
| `low` | 1024 | 1024 | 0 | false | true |
| `medium` | 2048 | 2048 | 0 | true | true |
| `high` | 4096 | 4096 | 2 | true | true |
| `ultra` | 8192 | 8192 | 4 | true | false |

### Test Scenarios

#### 1. Happy path — set quality to "low"

**Call:**
```json
{
  "tool": "set_rendering_quality",
  "params": { "quality": "low" }
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"quality\": \"low\", \"message\": \"Rendering quality set to low\"}"
  }]
}
```

**Assertions:**
- `success` is `true`
- `quality` echoes back `"low"`
- Follow up with `get_rendering_settings` to verify: `shadows.quality == 1024`, `anti_aliasing.msaa == 0`, `anti_aliasing.fxaa == 0`, `gi.mode == true`

#### 2. Happy path — set quality to "ultra"

**Call:**
```json
{
  "tool": "set_rendering_quality",
  "params": { "quality": "ultra" }
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"quality\": \"ultra\", \"message\": \"Rendering quality set to ultra\"}"
  }]
}
```

**Assertions:**
- `success` is `true`
- Follow up with `get_rendering_settings`: `shadows.quality == 8192`, `anti_aliasing.msaa == 4`, `anti_aliasing.fxaa == 1`, `gi.mode == false`

#### 3. Edge case — missing `quality` param

**Call:**
```json
{
  "tool": "set_rendering_quality",
  "params": {}
}
```

**Expected result:** The GDScript handler defaults to `"medium"` (line 82: `params.get("quality", "medium")`). So this **succeeds** with `quality: "medium"`. The TS-side Zod schema requires `quality` (it is not `.optional()`), so the MCP SDK validation may reject this before it reaches Godot. Test both:
- If MCP SDK validates: expect error about missing required field
- If it reaches Godot: expect `success: true, quality: "medium"`

**Assertions:**
- Verify which path the error takes (SDK validation vs Godot default)

#### 4. Edge case — invalid quality value

**Call:**
```json
{
  "tool": "set_rendering_quality",
  "params": { "quality": "potato" }
}
```

**Expected result:** Zod enum validation should reject `"potato"` before reaching Godot. Expect an MCP validation error.

**Assertions:**
- `isError` is `true` or SDK returns validation error
- Error message mentions enum/valid values

#### 5. All 4 quality levels — sequential test

**Description:** Set each quality level in sequence, verify each changes settings correctly.

**Sequence:**
1. `set_rendering_quality` → `{ "quality": "low" }` → verify shadows=1024, msaa=0
2. `set_rendering_quality` → `{ "quality": "medium" }` → verify shadows=2048, msaa=0, fxaa=1
3. `set_rendering_quality` → `{ "quality": "high" }` → verify shadows=4096, msaa=2, fxaa=1
4. `set_rendering_quality` → `{ "quality": "ultra" }` → verify shadows=8192, msaa=4, gi.half_res=false

**Notes:** After each call, use `get_rendering_settings` to confirm the settings changed.

---

## Tool: `set_renderer`

### Schema

```json
{
  "description": "Set the rendering method/renderer for the project",
  "inputSchema": {
    "renderer": {
      "type": "string",
      "enum": ["forward_plus", "mobile", "gl_compatibility"],
      "description": "Rendering backend to use"
    }
  }
}
```

**Required:** `renderer` — one of `forward_plus`, `mobile`, `gl_compatibility`.

### Test Scenarios

#### 1. Happy path — set to "mobile"

**Call:**
```json
{
  "tool": "set_renderer",
  "params": { "renderer": "mobile" }
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"renderer\": \"mobile\", \"message\": \"Renderer set to mobile\"}"
  }]
}
```

**Assertions:**
- `success` is `true`
- `renderer` echoes `"mobile"`
- Follow up with `get_rendering_settings`: `settings.renderer == "mobile"`

#### 2. Happy path — set to "gl_compatibility"

**Call:**
```json
{
  "tool": "set_renderer",
  "params": { "renderer": "gl_compatibility" }
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"renderer\": \"gl_compatibility\", \"message\": \"Renderer set to gl_compatibility\"}"
  }]
}
```

**Assertions:**
- `success` is `true`, `renderer` echoes back

#### 3. Happy path — set to "forward_plus" (restore default)

**Call:**
```json
{
  "tool": "set_renderer",
  "params": { "renderer": "forward_plus" }
}
```

**Expected result:** `success: true, renderer: "forward_plus"`

#### 4. Edge case — missing `renderer` param

**Call:**
```json
{
  "tool": "set_renderer",
  "params": {}
}
```

**Expected result:** Zod requires `renderer` (not optional). Expect MCP SDK validation error. If it reaches Godot, GDScript defaults to `"forward_plus"`.

#### 5. Edge case — invalid renderer value

**Call:**
```json
{
  "tool": "set_renderer",
  "params": { "renderer": "vulkan_custom" }
}
```

**Expected result:** Zod enum validation rejects. If it somehow reaches Godot, GDScript also validates (line 120) and returns `success: false, error: "Invalid renderer: ..."`. Test both paths.

---

## Tool: `set_anti_aliasing`

### Schema

```json
{
  "description": "Configure anti-aliasing settings (MSAA, FXAA, TAA)",
  "inputSchema": {
    "msaa": { "type": "string", "enum": ["2x", "4x", "8x"], "optional": true, "description": "MSAA level (or omit to disable)" },
    "fxaa": { "type": "boolean", "optional": true, "description": "Enable/disable FXAA" },
    "taa": { "type": "boolean", "optional": true, "description": "Enable/disable TAA" }
  }
}
```

**All params optional**, but at least one must be provided (GDScript returns error if `changed.is_empty()`).

### Test Scenarios

#### 1. Happy path — set MSAA only

**Call:**
```json
{
  "tool": "set_anti_aliasing",
  "params": { "msaa": "4x" }
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"changed\": {\"msaa\": \"4x\"}}"
  }]
}
```

**Assertions:**
- `success` is `true`
- `changed` contains only `msaa: "4x"`
- Follow up with `get_rendering_settings`: `anti_aliasing.msaa == 2` (4x maps to internal value 2)

#### 2. Happy path — set FXAA + TAA

**Call:**
```json
{
  "tool": "set_anti_aliasing",
  "params": { "fxaa": true, "taa": true }
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"changed\": {\"fxaa\": true, \"taa\": true}}"
  }]
}
```

**Assertions:**
- `changed` has both `fxaa` and `taa`, no `msaa`
- Follow up: `anti_aliasing.fxaa == 1`, `anti_aliasing.taa == true`

#### 3. Happy path — all three at once

**Call:**
```json
{
  "tool": "set_anti_aliasing",
  "params": { "msaa": "8x", "fxaa": false, "taa": true }
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"changed\": {\"msaa\": \"8x\", \"fxaa\": false, \"taa\": true}}"
  }]
}
```

**Assertions:**
- All three keys in `changed`
- `anti_aliasing.msaa == 3` (8x → 3), `anti_aliasing.fxaa == 0`, `anti_aliasing.taa == true`

#### 4. Edge case — no params at all

**Call:**
```json
{
  "tool": "set_anti_aliasing",
  "params": {}
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": false, \"error\": \"No anti-aliasing settings provided\"}"
  }],
  "isError": true
}
```

**Assertions:**
- `success` is `false`
- Error message indicates no settings were provided

#### 5. Edge case — disable all AA (fxaa: false, taa: false, omit msaa)

**Call:**
```json
{
  "tool": "set_anti_aliasing",
  "params": { "fxaa": false, "taa": false }
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"changed\": {\"fxaa\": false, \"taa\": false}}"
  }]
}
```

**Assertions:**
- `success` is `true` (providing `false` values still counts as "changed")
- `anti_aliasing.fxaa == 0`, `anti_aliasing.taa == false`

#### 6. Edge case — invalid MSAA value

**Call:**
```json
{
  "tool": "set_anti_aliasing",
  "params": { "msaa": "16x" }
}
```

**Expected result:** Zod enum rejects `"16x"` (valid: `2x`, `4x`, `8x`). Expect MCP validation error.

---

## Tool: `set_shadow_quality`

### Schema

```json
{
  "description": "Set shadow rendering quality preset",
  "inputSchema": {
    "quality": { "type": "string", "enum": ["low", "medium", "high", "ultra"], "description": "Shadow quality level" }
  }
}
```

**Required:** `quality`.

Shadow size mapping:

| Quality | Directional Shadow | Positional Shadow |
|---|---|---|
| `low` | 1024 | 512 |
| `medium` | 2048 | 1024 |
| `high` | 4096 | 2048 |
| `ultra` | 8192 | 4096 |

### Test Scenarios

#### 1. Happy path — set to "high"

**Call:**
```json
{
  "tool": "set_shadow_quality",
  "params": { "quality": "high" }
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"quality\": \"high\", \"message\": \"Shadow quality set to high\"}"
  }]
}
```

**Assertions:**
- `success` is `true`
- Follow up with `get_rendering_settings`: `shadows.quality == 4096`, `shadows.positional_shadow_size == 2048`

#### 2. Happy path — set to "ultra"

**Call:**
```json
{
  "tool": "set_shadow_quality",
  "params": { "quality": "ultra" }
}
```

**Expected result:** `success: true, quality: "ultra"`. Verify `shadows.quality == 8192`, `shadows.positional_shadow_size == 4096`.

#### 3. Edge case — missing quality

**Call:**
```json
{
  "tool": "set_shadow_quality",
  "params": {}
}
```

**Expected result:** Zod requires `quality`. If it reaches Godot, defaults to `"medium"`.

#### 4. Edge case — invalid quality value

**Call:**
```json
{
  "tool": "set_shadow_quality",
  "params": { "quality": "extreme" }
}
```

**Expected result:** Zod enum validation rejects.

---

## Tool: `set_gi_quality`

### Schema

```json
{
  "description": "Set global illumination quality preset",
  "inputSchema": {
    "quality": { "type": "string", "enum": ["low", "medium", "high", "ultra"], "description": "GI quality level" }
  }
}
```

**Required:** `quality`.

GI half-resolution mapping:

| Quality | Half Resolution |
|---|---|
| `low` | true |
| `medium` | true |
| `high` | false |
| `ultra` | false |

### Test Scenarios

#### 1. Happy path — set to "high"

**Call:**
```json
{
  "tool": "set_gi_quality",
  "params": { "quality": "high" }
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"quality\": \"high\", \"half_resolution\": false}"
  }]
}
```

**Assertions:**
- `success` is `true`
- `half_resolution` is `false`
- Follow up with `get_rendering_settings`: `gi.mode == false`

#### 2. Happy path — set to "low"

**Call:**
```json
{
  "tool": "set_gi_quality",
  "params": { "quality": "low" }
}
```

**Expected result:** `success: true, quality: "low", half_resolution: true`. Verify `gi.mode == true`.

#### 3. Edge case — missing quality

**Call:**
```json
{
  "tool": "set_gi_quality",
  "params": {}
}
```

**Expected result:** Zod rejects or Godot defaults to `"medium"` (half_resolution = true).

#### 4. Edge case — invalid quality

**Call:**
```json
{
  "tool": "set_gi_quality",
  "params": { "quality": "max" }
}
```

**Expected result:** Zod enum validation rejects.

---

## Tool: `set_viewport_size`

### Schema

```json
{
  "description": "Set the game viewport dimensions and stretch settings",
  "inputSchema": {
    "width": { "type": "integer", "minimum": 1, "description": "Viewport width in pixels" },
    "height": { "type": "integer", "minimum": 1, "description": "Viewport height in pixels" },
    "stretch_mode": { "type": "string", "enum": ["disabled", "canvas_items", "viewport"], "optional": true },
    "stretch_aspect": { "type": "string", "enum": ["ignore", "keep", "keep_width", "keep_height", "expand"], "optional": true }
  }
}
```

**Required:** `width` (positive int), `height` (positive int).  
**Optional:** `stretch_mode`, `stretch_aspect`.

### Test Scenarios

#### 1. Happy path — set width/height only

**Call:**
```json
{
  "tool": "set_viewport_size",
  "params": { "width": 1920, "height": 1080 }
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"width\": 1920, \"height\": 1080, \"message\": \"Viewport size set\"}"
  }]
}
```

**Assertions:**
- `success` is `true`, dimensions echoed back
- Follow up with `get_rendering_settings`: `viewport.width == 1920`, `viewport.height == 1080`

#### 2. Happy path — with stretch mode and aspect

**Call:**
```json
{
  "tool": "set_viewport_size",
  "params": { "width": 1280, "height": 720, "stretch_mode": "canvas_items", "stretch_aspect": "keep" }
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"width\": 1280, \"height\": 720, \"message\": \"Viewport size set\"}"
  }]
}
```

**Assertions:**
- Success. Stretch settings are written to project settings (not returned in response).

#### 3. Happy path — minimal resolution

**Call:**
```json
{
  "tool": "set_viewport_size",
  "params": { "width": 1, "height": 1 }
}
```

**Expected result:** `success: true, width: 1, height: 1`

**Notes:** Boundary test — 1×1 viewport is technically valid (positive int).

#### 4. Edge case — missing width

**Call:**
```json
{
  "tool": "set_viewport_size",
  "params": { "height": 1080 }
}
```

**Expected result:** Zod requires `width`. Expect validation error.

#### 5. Edge case — zero width (invalid)

**Call:**
```json
{
  "tool": "set_viewport_size",
  "params": { "width": 0, "height": 1080 }
}
```

**Expected result:** Zod `.int().positive()` rejects 0. If it reaches Godot, GDScript also rejects (`width <= 0`). Expect error from either layer.

#### 6. Edge case — negative height

**Call:**
```json
{
  "tool": "set_viewport_size",
  "params": { "width": 1920, "height": -1 }
}
```

**Expected result:** Zod `.positive()` rejects -1.

#### 7. Edge case — non-integer width

**Call:**
```json
{
  "tool": "set_viewport_size",
  "params": { "width": 1920.5, "height": 1080 }
}
```

**Expected result:** Zod `.int()` rejects non-integer.

#### 8. Edge case — all stretch options

**Description:** Test each valid `stretch_mode` + `stretch_aspect` combination.

**Sequence:**
1. `{ "width": 1152, "height": 648, "stretch_mode": "disabled" }` → success
2. `{ "width": 1152, "height": 648, "stretch_mode": "canvas_items", "stretch_aspect": "expand" }` → success
3. `{ "width": 1152, "height": 648, "stretch_mode": "viewport", "stretch_aspect": "keep_width" }` → success

---

## Tool: `set_window_settings`

### Schema

```json
{
  "description": "Configure the application window size, mode, and vsync",
  "inputSchema": {
    "size": { "type": "array", "items": { "type": "integer" }, "minItems": 2, "maxItems": 2, "optional": true, "description": "Window size [width, height]" },
    "mode": { "type": "string", "enum": ["windowed", "fullscreen", "exclusive_fullscreen"], "optional": true },
    "vsync": { "type": "boolean", "optional": true }
  }
}
```

**All params optional**, but at least one must be provided (GDScript returns error if `changed.is_empty()`).

Window mode mapping (GDScript internal values):

| Mode String | Internal Value |
|---|---|
| `windowed` | 0 |
| `fullscreen` | 3 |
| `exclusive_fullscreen` | 4 |

### Test Scenarios

#### 1. Happy path — set window size only

**Call:**
```json
{
  "tool": "set_window_settings",
  "params": { "size": [1920, 1080] }
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"changed\": {\"size\": [1920, 1080]}}"
  }]
}
```

**Assertions:**
- `changed` contains `size` array
- Window width/height override written to project settings

#### 2. Happy path — set mode to fullscreen

**Call:**
```json
{
  "tool": "set_window_settings",
  "params": { "mode": "fullscreen" }
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"changed\": {\"mode\": \"fullscreen\"}}"
  }]
}
```

#### 3. Happy path — all three at once

**Call:**
```json
{
  "tool": "set_window_settings",
  "params": { "size": [1280, 720], "mode": "exclusive_fullscreen", "vsync": false }
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"changed\": {\"size\": [1280, 720], \"mode\": \"exclusive_fullscreen\", \"vsync\": false}}"
  }]
}
```

**Assertions:**
- All three keys present in `changed`
- Follow up with `get_rendering_settings`: `window.mode == 4`, `window.vsync == 0`

#### 4. Happy path — vsync toggle

**Call:**
```json
{
  "tool": "set_window_settings",
  "params": { "vsync": true }
}
```

**Expected result:** `success: true, changed: { "vsync": true }`. Verify `window.vsync == 1`.

#### 5. Edge case — no params

**Call:**
```json
{
  "tool": "set_window_settings",
  "params": {}
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": false, \"error\": \"No window settings provided\"}"
  }],
  "isError": true
}
```

#### 6. Edge case — invalid mode value

**Call:**
```json
{
  "tool": "set_window_settings",
  "params": { "mode": "borderless" }
}
```

**Expected result:** Zod enum validation rejects `"borderless"`.

#### 7. Edge case — size with wrong length

**Call:**
```json
{
  "tool": "set_window_settings",
  "params": { "size": [1920] }
}
```

**Expected result:** Zod `Size2D` (`.array().length(2)`) rejects single-element array.

#### 8. Edge case — size with extra elements

**Call:**
```json
{
  "tool": "set_window_settings",
  "params": { "size": [1920, 1080, 60] }
}
```

**Expected result:** Zod `.length(2)` rejects 3-element array.

---

## Tool: `get_rendering_info`

### Schema

```json
{
  "description": "Get GPU info, VRAM usage, draw calls, and rendering statistics",
  "inputSchema": {}
}
```

No parameters. Returns GPU adapter name, API version, vendor, and current rendering method.

### Test Scenarios

#### 1. Happy path — get rendering info

**Call:**
```json
{
  "tool": "get_rendering_info",
  "params": {}
}
```

**Expected result:**
```json
{
  "content": [{
    "type": "text",
    "text": "{\"success\": true, \"info\": {\"renderer_name\": \"NVIDIA GeForce ...\", \"renderer_api\": \"Vulkan 1.3...\", \"vendor\": \"NVIDIA\", \"rendering_method\": \"forward_plus\"}}"
  }]
}
```

**Assertions:**
- `success` is `true`
- `info.renderer_name` is a non-empty string
- `info.renderer_api` is a non-empty string
- `info.vendor` is a non-empty string
- `info.rendering_method` is one of `forward_plus`, `mobile`, `gl_compatibility`

**Notes:** Values are hardware-dependent. Do not assert exact strings — assert types and non-emptiness.

---

## Recommended Test Sequences

### Sequence 1: Full rendering configuration workflow

This sequence tests that settings persist and interact correctly across tools.

1. **`get_rendering_settings`** → record baseline
2. **`set_renderer`** → `{ "renderer": "mobile" }`
3. **`get_rendering_settings`** → verify `renderer == "mobile"`
4. **`set_rendering_quality`** → `{ "quality": "high" }`
5. **`get_rendering_settings`** → verify shadows/msaa/fxaa changed
6. **`set_shadow_quality`** → `{ "quality": "ultra" }` (overrides quality preset's shadow settings)
7. **`get_rendering_settings`** → verify `shadows.quality == 8192`
8. **`set_gi_quality`** → `{ "quality": "low" }`
9. **`set_viewport_size`** → `{ "width": 1920, "height": 1080, "stretch_mode": "canvas_items", "stretch_aspect": "keep" }`
10. **`set_window_settings`** → `{ "mode": "fullscreen", "vsync": false }`
11. **`set_anti_aliasing`** → `{ "msaa": "8x", "fxaa": true, "taa": true }`
12. **`get_rendering_settings`** → verify all changes applied
13. **`get_rendering_info`** → verify `rendering_method` reflects the renderer set in step 2

### Sequence 2: Quality preset → override → verify

Test that individual settings override composite presets.

1. **`set_rendering_quality`** → `{ "quality": "low" }` (sets msaa=0, fxaa=false, shadows=1024)
2. **`set_anti_aliasing`** → `{ "msaa": "4x", "fxaa": true }` (overrides AA from preset)
3. **`set_shadow_quality`** → `{ "quality": "ultra" }` (overrides shadows from preset)
4. **`get_rendering_settings`** → verify: msaa=2 (from 4x), fxaa=1, shadows=8192 (overridden)

### Sequence 3: Error recovery

Test that errors don't corrupt state.

1. **`set_rendering_quality`** → `{ "quality": "medium" }` (baseline)
2. **`set_viewport_size`** → `{ "width": 0, "height": 1080 }` → expect error
3. **`get_rendering_settings`** → verify viewport unchanged from before step 2
4. **`set_anti_aliasing`** → `{}` → expect error (no settings)
5. **`get_rendering_settings`** → verify anti-aliasing unchanged

---

## Notes on `set_post_processing` (missing from TS)

The GDScript handler (`rendering_config_commands.gd`) defines a `set_post_processing` method, but it is **not registered** in `rendering_config.ts`. The GDScript handler itself returns an error message:

```json
{
  "success": false,
  "error": "Bloom, SSAO, SSR, and volumetric fog are per-Environment resource settings, not project-level. Configure them on the Environment resource in your WorldEnvironment node."
}
```

This is intentional — the tool was intentionally excluded from the MCP registry because post-processing settings are per-Environment resource, not project-level settings. No test is needed for this.

---

## Cross-Tool Dependencies

| Tool | Depends On | Reason |
|---|---|---|
| All tools | Godot editor must be connected via WebSocket bridge | `callGodot` sends requests over WebSocket; if bridge is disconnected, all tools return `isError: true` |
| `set_rendering_quality` | (none) | Standalone composite tool |
| `set_anti_aliasing` | (none) | Standalone, but verify with `get_rendering_settings` |
| `set_shadow_quality` | (none) | May be overridden by `set_rendering_quality` if called after |
| `set_gi_quality` | (none) | May be overridden by `set_rendering_quality` if called after |
| `set_viewport_size` | (none) | Standalone |
| `set_window_settings` | (none) | Standalone |
| `get_rendering_info` | (none) | Read-only, always safe |

**Important ordering note:** `set_rendering_quality` is a composite that sets shadows, MSAA, FXAA, and GI at once. If you call `set_shadow_quality` after `set_rendering_quality`, the shadow settings will be overridden. If you call `set_rendering_quality` after `set_shadow_quality`, the quality preset will overwrite the individual shadow settings. This is expected behavior, not a bug.

---

## Error Handling

All tools follow the same error pattern via `callGodot`:

```typescript
// Success: { content: [{ type: "text", text: "<JSON string>" }] }
// Error:   { content: [{ type: "text", text: "Godot request failed: ..." }], isError: true }
```

The GDScript side returns `{ "success": false, "error": "..." }` for validation failures and `{ "success": true, ... }` for success. The TS side wraps this in a `ToolResult`.

**Bridge disconnection test:** If the Godot editor is not connected, all tools should return `isError: true` with a message about the bridge being disconnected. This should be tested separately as an infrastructure test.
