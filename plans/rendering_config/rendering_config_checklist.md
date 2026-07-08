# rendering_config — Test Execution Checklist
> See plan: [rendering_config_test_plan.md](./rendering_config_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: get_rendering_settings
- [ ] 1. Get current rendering settings (basic happy path)
- [ ] 2. Call with extra params (ignored by Zod)
- [ ] 3. Call with no args at all (undefined)

---

## Tool: set_rendering_quality
- [ ] 1. Set quality to `low`
- [ ] 2. Set quality to `medium`
- [ ] 3. Set quality to `high`
- [ ] 4. Set quality to `ultra`
- [ ] 5. Missing required param `quality`
- [ ] 6. Invalid enum — `maximum` (non-existent)
- [ ] 7. Invalid enum — `custom` (not a preset)
- [ ] 8. Invalid enum — empty string
- [ ] 9. Invalid enum — `LOW` (wrong case)
- [ ] 10. Invalid type — number `2` instead of string
- [ ] 11. Invalid type — boolean `false` instead of string
- [ ] 12. Invalid type — `null` instead of string
- [ ] 13. Invalid type — array `["high"]` instead of string
- [ ] 14. Extra unexpected params (stripped/ignored)

---

## Tool: set_renderer
- [ ] 1. Set renderer to `forward_plus`
- [ ] 2. Set renderer to `mobile`
- [ ] 3. Set renderer to `gl_compatibility`
- [ ] 4. Switch mobile → forward_plus and verify each
- [ ] 5. Missing required param `renderer`
- [ ] 6. Invalid enum — `vulkan` (graphics API, not backend)
- [ ] 7. Invalid enum — `urp` (Unity naming)
- [ ] 8. Invalid enum — empty string
- [ ] 9. Invalid enum — `Forward_Plus` (wrong case)
- [ ] 10. Invalid type — number `0` instead of string
- [ ] 11. Invalid type — boolean `true` instead of string
- [ ] 12. Invalid type — `null` instead of string
- [ ] 13. Extra unexpected params (stripped/ignored)

---

## Tool: set_anti_aliasing
- [ ] 1. Enable MSAA 4x only
- [ ] 2. Enable MSAA 2x (minimum level)
- [ ] 3. Enable MSAA 8x (maximum level)
- [ ] 4. Enable FXAA only
- [ ] 5. Disable FXAA explicitly
- [ ] 6. Enable TAA only
- [ ] 7. Disable TAA explicitly
- [ ] 8. Combine MSAA 4x + FXAA + TAA
- [ ] 9. Call with empty params (all optional, no-op)
- [ ] 10. Omit MSAA — verify it stays unchanged
- [ ] 11. Invalid MSAA — `16x` (non-existent level)
- [ ] 12. Invalid MSAA — `"4"` without `x` suffix
- [ ] 13. Invalid MSAA — integer `4` instead of string
- [ ] 14. Invalid MSAA — `"off"` (omit to disable)
- [ ] 15. Invalid FXAA — string `"enabled"` instead of bool
- [ ] 16. Invalid FXAA — number `1` instead of bool
- [ ] 17. Invalid TAA — string `"true"` instead of bool
- [ ] 18. Invalid TAA — `null` instead of bool
- [ ] 19. Extra unexpected params (stripped/ignored)

---

## Tool: set_shadow_quality
- [ ] 1. Set shadow quality to `low`
- [ ] 2. Set shadow quality to `medium`
- [ ] 3. Set shadow quality to `high`
- [ ] 4. Set shadow quality to `ultra`
- [ ] 5. Shadow quality independent of rendering quality
- [ ] 6. Missing required param `quality`
- [ ] 7. Invalid enum — `epic` (non-existent level)
- [ ] 8. Invalid enum — empty string
- [ ] 9. Invalid type — number `3` instead of string
- [ ] 10. Invalid type — boolean `true` instead of string
- [ ] 11. Invalid type — `null` instead of string
- [ ] 12. Extra unexpected params (stripped/ignored)

---

## Tool: set_gi_quality
- [ ] 1. Set GI quality to `low`
- [ ] 2. Set GI quality to `medium`
- [ ] 3. Set GI quality to `high`
- [ ] 4. Set GI quality to `ultra`
- [ ] 5. GI quality independent of rendering and shadow quality
- [ ] 6. Missing required param `quality`
- [ ] 7. Invalid enum — `off` (cannot disable GI)
- [ ] 8. Invalid enum — empty string
- [ ] 9. Invalid type — number `1` instead of string
- [ ] 10. Invalid type — boolean `false` instead of string
- [ ] 11. Invalid type — `null` instead of string
- [ ] 12. Extra unexpected params (stripped/ignored)

---

## Tool: set_viewport_size
- [ ] 1. Set viewport to 1920×1080 (1080p)
- [ ] 2. Set viewport to 1280×720 (720p)
- [ ] 3. Set viewport to 3840×2160 (4K)
- [ ] 4. Set viewport with stretch_mode `disabled`
- [ ] 5. Set viewport with stretch_mode `canvas_items`
- [ ] 6. Set viewport with stretch_mode `viewport`
- [ ] 7. Set viewport with stretch_aspect `ignore`
- [ ] 8. Set viewport with stretch_aspect `keep`
- [ ] 9. Set viewport with stretch_aspect `keep_width`
- [ ] 10. Set viewport with stretch_aspect `keep_height`
- [ ] 11. Set viewport with stretch_aspect `expand`
- [ ] 12. Set all four params together
- [ ] 13. Only stretch settings — fail (missing width/height)
- [ ] 14. Very small resolution 1×1 (boundary test)
- [ ] 15. Excessively large resolution 65536×65536
- [ ] 16. Non-standard ultrawide ratio 2560×1080
- [ ] 17. Portrait orientation 1080×1920
- [ ] 18. Missing required param `width`
- [ ] 19. Missing required param `height`
- [ ] 20. Both required params missing
- [ ] 21. Width is zero (not positive)
- [ ] 22. Width is negative
- [ ] 23. Height is zero (not positive)
- [ ] 24. Width is float 1920.5 instead of int
- [ ] 25. Height is 1080.0 (JS integer, passes)
- [ ] 26. Width as string `"1920"` instead of number
- [ ] 27. Width as boolean instead of number
- [ ] 28. Invalid stretch_mode — `scale`
- [ ] 29. Invalid stretch_aspect — `fit`
- [ ] 30. stretch_aspect as boolean instead of string
- [ ] 31. Extra unexpected params (stripped/ignored)

---

## Tool: set_window_settings
- [ ] 1. Set window mode to `windowed`
- [ ] 2. Set window mode to `fullscreen`
- [ ] 3. Set window mode to `exclusive_fullscreen`
- [ ] 4. Set window size to 1280×720
- [ ] 5. Set window size to 1920×1080
- [ ] 6. Set window size to 3840×2160 (4K)
- [ ] 7. Enable vsync
- [ ] 8. Disable vsync
- [ ] 9. Set all three params (size, mode, vsync)
- [ ] 10. Call with empty params (all optional, no-op)
- [ ] 11. Set window to portrait size 1080×1920
- [ ] 12. Set tiny window 100×100
- [ ] 13. Size2D with zero values [0, 0]
- [ ] 14. Size2D with negative values [-100, -100]
- [ ] 15. Size2D with float values — rejected
- [ ] 16. Size2D with only one element — rejected
- [ ] 17. Size2D with three elements — rejected
- [ ] 18. Size2D as object instead of array — rejected
- [ ] 19. Size2D with string elements — rejected
- [ ] 20. Size2D with boolean elements — rejected
- [ ] 21. Invalid mode — `maximized` (non-existent)
- [ ] 22. Invalid mode — `Fullscreen` (wrong case)
- [ ] 23. Invalid mode — empty string
- [ ] 24. Invalid mode type — number `0` instead of string
- [ ] 25. Invalid mode type — boolean instead of string
- [ ] 26. Invalid mode type — `null` instead of string
- [ ] 27. Invalid vsync — string `"on"` instead of bool
- [ ] 28. Invalid vsync — number `1` instead of bool
- [ ] 29. Invalid vsync — `null` instead of bool
- [ ] 30. Extra unexpected params (stripped/ignored)

---

## Tool: get_rendering_info
- [ ] 1. Get rendering info on default project
- [ ] 2. Get rendering info during gameplay
- [ ] 3. Call twice in succession — verify consistency
- [ ] 4. Call with extra params (ignored by Zod)
- [ ] 5. Call with no args at all (undefined)

---

## Cross-Tool Integration Scenarios
- [ ] 1. Full rendering configuration cycle (set all → read back)
- [ ] 2. Independent quality axes (render low, shadow ultra, GI medium)
- [ ] 3. Renderer switch affects quality presets (forward_plus → gl_compatibility)
- [ ] 4. Viewport size and window size interaction (different sizes)
- [ ] 5. Anti-aliasing after renderer switch (forward_plus → mobile)
- [ ] 6. Get tools unaffected by invalid set calls (read isolation)
- [ ] 7. Sequential overwrite of each setting (low→high, etc.)

