# Visual Testing — Test Plan

**Source file:** `server/src/tools/visual_testing.ts`  
**Shared types:** `server/src/tools/shared-types.ts`  
**Tools covered:** 6  
**Generated:** 2026-07-08

---

## Shared Type Definitions

| Symbol | Zod schema | Description |
|--------|-----------|-------------|
| `Name` | `z.string()` | Generic name identifier (required string) |
| `FilePath` | `z.string()` | File path e.g. `res://path/to/file` (required string) |

---

## Tool: `take_screenshot_with_context`

**Description:** Take a screenshot with scene context metadata (node tree, properties of specified nodes).

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | `string` (Name) | **Yes** | — | Screenshot name, used as filename (e.g. `"main_menu"`) |
| `include_nodes` | `string[]` | No | `undefined` | Node paths to include property data for (requires `include_props=true`) |
| `include_props` | `boolean` | No | `false` | Whether to include property snapshots for listed `include_nodes` |

### Test Scenarios

#### Scenario 1: Minimum required params (happy path)
- **Description:** Call with only the required `name` param — captures a screenshot with scene context but no property snapshots.
- **Params:** `{ "name": "main_menu" }`
- **Expected result:** Success. A screenshot is taken and saved. Return value includes screenshot path and scene tree metadata. No property data for individual nodes.

#### Scenario 2: With include_props=true but no include_nodes
- **Description:** Setting `include_props=true` without specifying nodes; should still succeed but no property data appended.
- **Params:** `{ "name": "gameplay_snapshot", "include_props": true }`
- **Expected result:** Success. Screenshot saved. No property snapshots included (since `include_nodes` is empty).

#### Scenario 3: With include_props=true and include_nodes (happy path — full context)
- **Description:** Capture a screenshot with property snapshots for specific nodes.
- **Params:** `{ "name": "level_1_full", "include_nodes": ["Player", "Player/Sprite2D", "UI/HealthBar"], "include_props": true }`
- **Expected result:** Success. Screenshot saved. Return includes `name` and property snapshots for the three listed node paths.

#### Scenario 4: include_nodes provided but include_props=false (default)
- **Description:** `include_nodes` is specified but `include_props` remains default `false`. This may be ignored or cause a warning; test behavior.
- **Params:** `{ "name": "nodes_no_props", "include_nodes": ["Player"] }`
- **Expected result:** Success. Screenshot saved. `include_nodes` is either silently ignored (no property data) or triggers a warning per the description. No error.

#### Scenario 5: Empty name string
- **Description:** Edge case: an empty string for `name`.
- **Params:** `{ "name": "" }`
- **Expected result:** Should error with a validation message (Name must be a non-empty string) or Godot-side error about invalid filename.

#### Scenario 6: Name with path-like characters
- **Description:** Edge case: `name` contains slashes or other filename-problematic characters.
- **Params:** `{ "name": "screenshots/level_1" }`
- **Expected result:** May or may not succeed depending on Godot's filename handling. If it fails, expect a Godot-side error about invalid filename.

#### Scenario 7: Missing required `name` param
- **Description:** Omit the required `name` parameter entirely.
- **Params:** `{}`
- **Expected result:** Validation error from Zod: `name` is required.

#### Scenario 8: include_nodes with non-existent node path
- **Description:** A node path in `include_nodes` that doesn't exist in the scene.
- **Params:** `{ "name": "bad_nodes", "include_nodes": ["NonExistentNode"], "include_props": true }`
- **Expected result:** Depends on Godot behavior — may silently skip missing nodes, return an error, or include empty/null property data for the missing path.

---

## Tool: `compare_screenshots`

**Description:** Compare two screenshots pixel-by-pixel and return a diff result with mismatch percentage.

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `baseline` | `string` (FilePath) | **Yes** | — | Path to the baseline screenshot |
| `current` | `string` (FilePath) | **Yes** | — | Path to the current screenshot |
| `threshold` | `number` (0–1) | No | `0.01` | Pixel difference threshold (0–1) |

### Test Scenarios

#### Scenario 1: Compare two identical screenshots (happy path — match)
- **Description:** Compare two screenshots known to be pixel-identical.
- **Params:** `{ "baseline": "res://screenshots/baseline.png", "current": "res://screenshots/identical.png", "threshold": 0.01 }`
- **Expected result:** Success. Returns `matched: true` and `mismatch_percentage` near 0 (≤ threshold).

#### Scenario 2: Compare two different screenshots (happy path — mismatch)
- **Description:** Compare two screenshots known to differ significantly.
- **Params:** `{ "baseline": "res://screenshots/baseline.png", "current": "res://screenshots/completely_different.png", "threshold": 0.01 }`
- **Expected result:** Success. Returns `matched: false` and `mismatch_percentage` > threshold.

#### Scenario 3: Default threshold (omit threshold param)
- **Description:** Omit the `threshold` param to use default 0.01.
- **Params:** `{ "baseline": "res://screenshots/baseline.png", "current": "res://screenshots/similar.png" }`
- **Expected result:** Success. Comparison uses default threshold of 0.01.

#### Scenario 4: threshold = 0 (strictest — every pixel must match)
- **Description:** Use threshold of 0 to require pixel-perfect match.
- **Params:** `{ "baseline": "res://screenshots/baseline.png", "current": "res://screenshots/baseline.png", "threshold": 0 }`
- **Expected result:** Success. Both files identical → `matched: true`. Any single pixel difference → `matched: false`.

#### Scenario 5: threshold = 1 (laxest — accept any difference)
- **Description:** Use threshold of 1.0, which should never reject a difference.
- **Params:** `{ "baseline": "res://screenshots/baseline.png", "current": "res://screenshots/black.png", "threshold": 1 }`
- **Expected result:** Success. `matched: true` regardless of pixel differences (threshold=1 means allow 100% mismatch).

#### Scenario 6: threshold = -0.1 (below valid range)
- **Description:** Pass a threshold below the `min(0)` constraint.
- **Params:** `{ "baseline": "res://screenshots/baseline.png", "current": "res://screenshots/other.png", "threshold": -0.1 }`
- **Expected result:** Zod validation error: threshold must be ≥ 0.

#### Scenario 7: threshold = 1.5 (above valid range)
- **Description:** Pass a threshold above the `max(1)` constraint.
- **Params:** `{ "baseline": "res://screenshots/baseline.png", "current": "res://screenshots/other.png", "threshold": 1.5 }`
- **Expected result:** Zod validation error: threshold must be ≤ 1.

#### Scenario 8: Missing required `baseline` param
- **Description:** Omit the `baseline` parameter.
- **Params:** `{ "current": "res://screenshots/img.png" }`
- **Expected result:** Zod validation error: `baseline` is required.

#### Scenario 9: Missing required `current` param
- **Description:** Omit the `current` parameter.
- **Params:** `{ "baseline": "res://screenshots/img.png" }`
- **Expected result:** Zod validation error: `current` is required.

#### Scenario 10: Baseline file does not exist
- **Description:** `baseline` path points to a non-existent file.
- **Params:** `{ "baseline": "res://screenshots/does_not_exist.png", "current": "res://screenshots/real.png" }`
- **Expected result:** Godot-side error about missing file / cannot read baseline.

#### Scenario 11: Current file does not exist
- **Description:** `current` path points to a non-existent file.
- **Params:** `{ "baseline": "res://screenshots/real.png", "current": "res://screenshots/does_not_exist.png" }`
- **Expected result:** Godot-side error about missing file / cannot read current screenshot.

#### Scenario 12: Different resolution screenshots
- **Description:** Compare screenshots of different dimensions.
- **Params:** `{ "baseline": "res://screenshots/1920x1080.png", "current": "res://screenshots/1280x720.png" }`
- **Expected result:** Should return an error (cannot compare images of different sizes) or return `matched: false` with high mismatch percentage.

---

## Tool: `assert_visual_match`

**Description:** Assert that a screenshot matches a baseline within a threshold — pass/fail result.

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | `string` (Name) | **Yes** | — | Screenshot name to check — must match a name previously used with `take_screenshot_with_context` |
| `baseline` | `string` (FilePath) | **Yes** | — | Path or name of the baseline screenshot (resolves against baselines directory if not a full path) |
| `threshold` | `number` (0–1) | No | `0.01` | Acceptable difference threshold (default: 0.01) |

### Test Scenarios

#### Scenario 1: Matching screenshot (happy path — pass)
- **Description:** Assert that a previously taken screenshot matches its baseline.
- **Params:** `{ "name": "main_menu", "baseline": "res://baselines/main_menu_baseline.png", "threshold": 0.01 }`
- **Expected result:** Success. Returns `passed: true` with low mismatch percentage.

#### Scenario 2: Non-matching screenshot (happy path — fail assertion)
- **Description:** Assert that a screenshot differs from its baseline.
- **Params:** `{ "name": "main_menu", "baseline": "res://baselines/different_baseline.png", "threshold": 0.01 }`
- **Expected result:** Returns `passed: false` with mismatch percentage above threshold. Not necessarily an error — it's a failed assertion, not a tool error.

#### Scenario 3: Default threshold (omit threshold)
- **Description:** Use the default threshold of 0.01.
- **Params:** `{ "name": "level_select", "baseline": "res://baselines/level_select_baseline.png" }`
- **Expected result:** Success. Comparison uses default threshold 0.01.

#### Scenario 4: threshold = 0 (strict pixel-perfect)
- **Description:** Assert pixel-perfect match.
- **Params:** `{ "name": "pixel_perfect_test", "baseline": "res://baselines/exact.png", "threshold": 0 }`
- **Expected result:** Success. Passes only if every pixel matches exactly.

#### Scenario 5: threshold = 0.5 (lenient)
- **Description:** Allow up to 50% pixel difference.
- **Params:** `{ "name": "loose_test", "baseline": "res://baselines/loose.png", "threshold": 0.5 }`
- **Expected result:** Success. Passes if ≤50% of pixels differ.

#### Scenario 6: threshold below 0
- **Description:** Invalid threshold value.
- **Params:** `{ "name": "bad_threshold", "baseline": "res://baselines/x.png", "threshold": -0.5 }`
- **Expected result:** Zod validation error: threshold must be ≥ 0.

#### Scenario 7: threshold above 1
- **Description:** Invalid threshold value.
- **Params:** `{ "name": "bad_threshold", "baseline": "res://baselines/x.png", "threshold": 2.0 }`
- **Expected result:** Zod validation error: threshold must be ≤ 1.

#### Scenario 8: Missing required `name` param
- **Description:** Omit the `name` parameter.
- **Params:** `{ "baseline": "res://baselines/img.png" }`
- **Expected result:** Zod validation error: `name` is required.

#### Scenario 9: Missing required `baseline` param
- **Description:** Omit the `baseline` parameter.
- **Params:** `{ "name": "some_screenshot" }`
- **Expected result:** Zod validation error: `baseline` is required.

#### Scenario 10: `name` not previously taken via take_screenshot_with_context
- **Description:** Use a `name` that was never used in a prior `take_screenshot_with_context` call.
- **Params:** `{ "name": "never_taken", "baseline": "res://baselines/img.png" }`
- **Expected result:** Godot-side error: no screenshot found with that name in the current session.

#### Scenario 11: Baseline resolves relative to baselines directory
- **Description:** Test the "resolves against baselines directory" behavior — provide a bare filename, not a full path.
- **Params:** `{ "name": "main_menu", "baseline": "main_menu_baseline.png" }`
- **Expected result:** Should resolve `main_menu_baseline.png` against the configured baselines directory and succeed if it exists there.

#### Scenario 12: Baseline file does not exist
- **Description:** The baseline path points to a file that doesn't exist.
- **Params:** `{ "name": "main_menu", "baseline": "res://baselines/does_not_exist.png" }`
- **Expected result:** Godot-side error about missing baseline file.

---

## Tool: `record_visual_regression`

**Description:** Record multiple frames over time for visual regression testing.

### Parameters

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `test_name` | `string` (Name) | **Yes** | — | — | Name for this recording session |
| `frames` | `integer` (int) | No | `10` | min=1, max=100 | Number of frames to capture |
| `interval` | `number` | No | `0.5` | min=0.1, max=10 | Seconds between captures |

### Test Scenarios

#### Scenario 1: Minimum required params (happy path — default frames & interval)
- **Description:** Call with only the required `test_name`. Uses default 10 frames at 0.5s intervals (5 seconds total).
- **Params:** `{ "test_name": "menu_transition" }`
- **Expected result:** Success. Returns list of 10 frame captures taken 0.5s apart. Each frame has a timestamp and path.

#### Scenario 2: Custom frames and interval (happy path — explicit values)
- **Description:** Explicitly set frames=5 and interval=1.0.
- **Params:** `{ "test_name": "quick_transition", "frames": 5, "interval": 1.0 }`
- **Expected result:** Success. Returns 5 frames captured 1.0s apart (total ~4s).

#### Scenario 3: frames = 1 (minimum boundary)
- **Description:** Capture exactly 1 frame — tests the minimum `frames` boundary.
- **Params:** `{ "test_name": "single_frame", "frames": 1 }`
- **Expected result:** Success. Returns a single frame capture.

#### Scenario 4: frames = 100 (maximum boundary)
- **Description:** Capture the maximum allowed number of frames.
- **Params:** `{ "test_name": "long_recording", "frames": 100, "interval": 0.1 }`
- **Expected result:** Success. Returns 100 frames at 0.1s intervals (total ~10s).

#### Scenario 5: interval = 0.1 (minimum boundary)
- **Description:** Fastest allowed capture rate.
- **Params:** `{ "test_name": "fast_capture", "frames": 10, "interval": 0.1 }`
- **Expected result:** Success. Frames captured at 0.1s intervals.

#### Scenario 6: interval = 10 (maximum boundary)
- **Description:** Slowest allowed capture rate.
- **Params:** `{ "test_name": "slow_capture", "frames": 2, "interval": 10 }`
- **Expected result:** Success. Two frames captured 10s apart (total 10s).

#### Scenario 7: frames = 0 (below minimum)
- **Description:** Invalid frames count — below `min(1)`.
- **Params:** `{ "test_name": "bad_frames", "frames": 0 }`
- **Expected result:** Zod validation error: frames must be ≥ 1.

#### Scenario 8: frames = 101 (above maximum)
- **Description:** Invalid frames count — above `max(100)`.
- **Params:** `{ "test_name": "too_many_frames", "frames": 101 }`
- **Expected result:** Zod validation error: frames must be ≤ 100.

#### Scenario 9: frames as float (not integer)
- **Description:** Pass a non-integer value for frames (violates `int()`).
- **Params:** `{ "test_name": "float_frames", "frames": 5.5 }`
- **Expected result:** Zod validation error: frames must be an integer.

#### Scenario 10: interval below 0.1
- **Description:** Interval below `min(0.1)`.
- **Params:** `{ "test_name": "too_fast", "frames": 5, "interval": 0.05 }`
- **Expected result:** Zod validation error: interval must be ≥ 0.1.

#### Scenario 11: interval above 10
- **Description:** Interval above `max(10)`.
- **Params:** `{ "test_name": "too_slow", "frames": 2, "interval": 15 }`
- **Expected result:** Zod validation error: interval must be ≤ 10.

#### Scenario 12: interval = 0 (edge — technically below min)
- **Description:** interval of 0 is below the min constraint.
- **Params:** `{ "test_name": "zero_interval", "frames": 2, "interval": 0 }`
- **Expected result:** Zod validation error: interval must be ≥ 0.1.

#### Scenario 13: Missing required `test_name` param
- **Description:** Omit `test_name`.
- **Params:** `{}`
- **Expected result:** Zod validation error: `test_name` is required.

#### Scenario 14: Empty test_name string
- **Description:** Edge case: empty string for `test_name`.
- **Params:** `{ "test_name": "" }`
- **Expected result:** May succeed or error depending on Godot's filename handling for empty names.

#### Scenario 15: Large frames × long interval (total long duration)
- **Description:** frames=100 × interval=10 = 1000s (~16.7 min). Tests whether the tool handles or rejects very long recordings.
- **Params:** `{ "test_name": "ultra_long", "frames": 100, "interval": 10 }`
- **Expected result:** Should either succeed (and take ~16.7 minutes) or return a timeout/time-limit error from Godot.

---

## Tool: `get_visual_diff_report`

**Description:** Get the aggregated visual regression report from all `assert_visual_match` calls in this session.

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| *(none)* | — | — | — | No parameters |

### Test Scenarios

#### Scenario 1: No assertions run yet (empty report)
- **Description:** Call `get_visual_diff_report` before any `assert_visual_match` calls have been made.
- **Params:** `{}`
- **Expected result:** Success. Returns an empty report or a report indicating zero assertions run. Possibly `{ "total": 0, "passed": 0, "failed": 0, "results": [] }`.

#### Scenario 2: After a single passing assertion (happy path)
- **Description:** Run one `assert_visual_match` that passes, then call `get_visual_diff_report`.
- **Setup:** Call `take_screenshot_with_context(name="test_menu")`, `assert_visual_match(name="test_menu", baseline="res://baselines/test_menu.png")`
- **Params:** `{}`
- **Expected result:** Success. Report shows: `total: 1, passed: 1, failed: 0`. Includes details for the single test.

#### Scenario 3: After multiple mixed assertions (happy path — multi-test report)
- **Description:** Run several assertions (mix of passes and failures), then get the aggregated report.
- **Setup:** Run 3 `assert_visual_match` calls — 2 pass, 1 fails.
- **Params:** `{}`
- **Expected result:** Success. Report shows: `total: 3, passed: 2, failed: 1`. Each individual result is listed with its name, baseline, threshold, mismatch percentage, and pass/fail status.

#### Scenario 4: After all failing assertions
- **Description:** All assertions in the session have failed.
- **Setup:** Run assertions that all fail.
- **Params:** `{}`
- **Expected result:** Success. Report shows: `total: N, passed: 0, failed: N`.

#### Scenario 5: Called with extra/unexpected params (robustness)
- **Description:** Call with a param that isn't in the schema (the handler ignores args anyway).
- **Params:** `{ "unexpected": "value" }`
- **Expected result:** Should succeed (extra params are silently ignored since the handler passes no args to `callGodot`). Returns the report as usual.

#### Scenario 6: Called twice in the same session
- **Description:** Verify that calling the report twice returns the same data (idempotent).
- **Params (both calls):** `{}`
- **Expected result:** Both calls return the same aggregated report — the report is read-only and doesn't reset.

---

## Tool: `set_visual_baseline`

**Description:** Set or update a visual baseline for future comparisons.

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | `string` (Name) | **Yes** | — | Baseline name identifier |
| `screenshot_path` | `string` (FilePath) | **Yes** | — | Path to the screenshot to use as baseline |

### Test Scenarios

#### Scenario 1: Set a new baseline (happy path)
- **Description:** Register a screenshot as a baseline with a new name.
- **Params:** `{ "name": "main_menu_v1", "screenshot_path": "res://screenshots/main_menu_v1.png" }`
- **Expected result:** Success. The baseline `main_menu_v1` is now registered and can be referenced in future `assert_visual_match` calls.

#### Scenario 2: Update an existing baseline (happy path — overwrite)
- **Description:** Overwrite a previously registered baseline with a new screenshot.
- **Params:** `{ "name": "main_menu_v1", "screenshot_path": "res://screenshots/main_menu_v2.png" }`
- **Expected result:** Success. The baseline `main_menu_v1` now points to the new screenshot.

#### Scenario 3: Set baseline with full path
- **Description:** Use a fully qualified `res://` path for the screenshot.
- **Params:** `{ "name": "combat_hud", "screenshot_path": "res://baselines/combat_hud.png" }`
- **Expected result:** Success. Baseline registered with the given path.

#### Scenario 4: Set baseline with non-standard characters in name
- **Description:** Use a name with spaces, dashes, or underscores.
- **Params:** `{ "name": "Level 1 - Main Menu", "screenshot_path": "res://screenshots/level1.png" }`
- **Expected result:** Likely succeeds (string validation doesn't restrict characters).

#### Scenario 5: Missing required `name` param
- **Description:** Omit `name`.
- **Params:** `{ "screenshot_path": "res://screenshots/img.png" }`
- **Expected result:** Zod validation error: `name` is required.

#### Scenario 6: Missing required `screenshot_path` param
- **Description:** Omit `screenshot_path`.
- **Params:** `{ "name": "my_baseline" }`
- **Expected result:** Zod validation error: `screenshot_path` is required.

#### Scenario 7: screenshot_path does not exist
- **Description:** The screenshot file at the given path doesn't exist.
- **Params:** `{ "name": "bad_baseline", "screenshot_path": "res://screenshots/does_not_exist.png" }`
- **Expected result:** Godot-side error: cannot read the screenshot file at the given path.

#### Scenario 8: screenshot_path with wrong extension
- **Description:** Path points to a non-image file (e.g., `.gd`, `.tscn`).
- **Params:** `{ "name": "wrong_type", "screenshot_path": "res://scripts/player.gd" }`
- **Expected result:** Godot-side error: file is not a valid image / cannot be used as a baseline.

#### Scenario 9: Empty name string
- **Description:** Edge case: empty string for name.
- **Params:** `{ "name": "", "screenshot_path": "res://screenshots/img.png" }`
- **Expected result:** May error (empty name invalid) or succeed depending on Godot-side handling.

#### Scenario 10: Empty screenshot_path
- **Description:** Edge case: empty string for screenshot_path.
- **Params:** `{ "name": "empty_path", "screenshot_path": "" }`
- **Expected result:** Godot-side error: invalid or empty file path.

#### Scenario 11: Multiple baselines set, then verify via assert_visual_match
- **Description:** End-to-end: set two baselines, then use `assert_visual_match` to verify they resolve correctly.
- **Setup:** Call `set_visual_baseline` twice with different names and paths, then call `assert_visual_match` referencing each.
- **Params (baseline 1):** `{ "name": "baseline_a", "screenshot_path": "res://screenshots/screen_a.png" }`
- **Params (baseline 2):** `{ "name": "baseline_b", "screenshot_path": "res://screenshots/screen_b.png" }`
- **Expected result:** Both baselines are set. `assert_visual_match` with `baseline: "baseline_a"` resolves to `screen_a.png`; `assert_visual_match` with `baseline: "baseline_b"` resolves to `screen_b.png`.

---

## Cross-Tool Integration Scenarios

### Integration 1: Full visual regression workflow
- **Description:** Execute the complete lifecycle: take screenshot → set baseline → take another screenshot → assert match → get report.
- **Steps:**
  1. `take_screenshot_with_context({ "name": "title_screen_v1" })` — capture initial state
  2. `set_visual_baseline({ "name": "title_baseline", "screenshot_path": "<path from step 1>" })` — register as baseline
  3. `take_screenshot_with_context({ "name": "title_screen_v2", "include_nodes": ["TitleLabel"], "include_props": true })` — capture new state with property data
  4. `assert_visual_match({ "name": "title_screen_v2", "baseline": "title_baseline", "threshold": 0.01 })` — compare
  5. `get_visual_diff_report({})` — get aggregated results
- **Expected result:** All steps succeed. Step 4 returns pass/fail. Step 5 returns a report with 1 test recorded.

### Integration 2: Record and compare multiple frames
- **Description:** Record a regression sequence, then set baselines from individual frames, and assert subsequent frames match.
- **Steps:**
  1. `record_visual_regression({ "test_name": "animation_test", "frames": 5, "interval": 0.5 })` — record 5 frames
  2. `set_visual_baseline({ "name": "anim_frame_1", "screenshot_path": "<path to frame 1>" })`
  3. `take_screenshot_with_context({ "name": "anim_check_1" })` — capture after animation plays
  4. `assert_visual_match({ "name": "anim_check_1", "baseline": "anim_frame_1", "threshold": 0.02 })`
  5. `get_visual_diff_report({})`
- **Expected result:** All steps succeed. The report includes the assertion result.

### Integration 3: Compare screenshots directly without baseline registration
- **Description:** Use `compare_screenshots` to do a direct pixel comparison without the baseline registry.
- **Steps:**
  1. `take_screenshot_with_context({ "name": "before" })` — returns path A
  2. `take_screenshot_with_context({ "name": "after" })` — returns path B
  3. `compare_screenshots({ "baseline": "<path A>", "current": "<path B>", "threshold": 0.05 })`
- **Expected result:** Steps 1-2 succeed. Step 3 returns `matched: true/false` with mismatch percentage.

---

## Parameter Validation Summary

| Tool | Required params | Zod constraints |
|------|----------------|-----------------|
| `take_screenshot_with_context` | `name` | — |
| `compare_screenshots` | `baseline`, `current` | `threshold`: min=0, max=1 |
| `assert_visual_match` | `name`, `baseline` | `threshold`: min=0, max=1 |
| `record_visual_regression` | `test_name` | `frames`: int, min=1, max=100; `interval`: min=0.1, max=10 |
| `get_visual_diff_report` | *(none)* | — |
| `set_visual_baseline` | `name`, `screenshot_path` | — |
