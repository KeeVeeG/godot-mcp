# Visual Testing Tools — Test Plan

**Source file:** `server/src/tools/visual_testing.ts`
**Total tools:** 6
**Generated:** 2026-07-08

---

## Shared Types Reference

| Type | Zod Definition | Description |
|------|---------------|-------------|
| `Name` | `z.string()` | Name identifier |
| `FilePath` | `z.string()` | File path (e.g. `res://path/to/file`) |

---

## Tool 1: `take_screenshot_with_context`

**Description:** Take a screenshot with scene context metadata (node tree, properties of specified nodes)

### Parameters

| Parameter | Type | Required | Default | Constraints | Description |
|-----------|------|----------|---------|-------------|-------------|
| `name` | `string` (Name) | **yes** | — | — | Name for this screenshot (used as filename, e.g. `"main_menu"`) |
| `include_nodes` | `string[]` | no | — | — | Node paths to include property data for (requires `include_props=true`) |
| `include_props` | `boolean` | no | `false` | — | Whether to include property snapshots for listed `include_nodes` |

### Test Scenarios

#### 1.1 — Happy Path: Basic Screenshot (minimal params)

**Description:** Capture a screenshot with only the required `name` parameter. No node data requested.

**JSON params:**
```json
{ "name": "basic_test" }
```

**Expected result:** Success. Screenshot saved with filename derived from `"basic_test"`. No property snapshots included.

**Notes:** This is the most minimal valid call.

---

#### 1.2 — Happy Path: Screenshot with Node Properties

**Description:** Capture a screenshot and include property snapshots for specific nodes.

**JSON params:**
```json
{
  "name": "debug_screen",
  "include_nodes": ["Player", "UI/HealthBar"],
  "include_props": true
}
```

**Expected result:** Success. Screenshot saved as `"debug_screen"`. Response includes property snapshots for `Player` and `UI/HealthBar` nodes.

**Notes:** Requires valid nodes at the specified paths in the current scene.

---

#### 1.3 — Happy Path: Screenshot with Multiple Nodes

**Description:** Capture a screenshot including property snapshots for a large set of nodes.

**JSON params:**
```json
{
  "name": "full_scene_snapshot",
  "include_nodes": ["Player", "Enemy1", "Enemy2", "Enemy3", "UI/HealthBar", "UI/ScoreLabel", "Camera2D"],
  "include_props": true
}
```

**Expected result:** Success. Property snapshots for all 7 listed nodes.

**Notes:** Tests multiple node path resolution.

---

#### 1.4 — Edge: include_nodes without include_props

**Description:** Provide `include_nodes` but leave `include_props` at its default (`false`).

**JSON params:**
```json
{
  "name": "nodes_without_props",
  "include_nodes": ["Player", "UI/HealthBar"],
  "include_props": false
}
```

**Expected result:** Success (screenshot captured). Node paths are listed but property snapshots are NOT included in response. OR the tool may return a warning/error that `include_props` must be `true` when `include_nodes` is provided.

**Notes:** Edge case for parameter dependency. The description says `include_nodes` "requires include_props=true" — the behavior when this precondition is violated should be observed.

---

#### 1.5 — Edge: include_nodes with include_props explicitly false

**Description:** Explicitly request node paths but deny property inclusion.

**JSON params:**
```json
{
  "name": "explicit_false",
  "include_nodes": ["Player"],
  "include_props": false
}
```

**Expected result:** Screenshot captured but no property data returned. May produce a warning.

---

#### 1.6 — Edge: Empty name string

**Description:** Provide an empty string for `name`.

**JSON params:**
```json
{ "name": "" }
```

**Expected result:** Should fail with a validation error (Name is required and should not be empty) or produce a screenshot with an empty/default filename.

**Notes:** Tests input validation on required string fields.

---

#### 1.7 — Edge: Very Long Name

**Description:** Provide a very long name string.

**JSON params:**
```json
{ "name": "A".repeat(256) }
```

**Expected result:** May succeed with truncated filename or fail if the Godot filesystem rejects long filenames.

**Notes:** Tests filesystem boundary behavior.

---

#### 1.8 — Edge: Name with Special Characters

**Description:** Provide a name containing characters that are invalid in filenames (e.g., `/`, `\`, `:`, `*`, `?`, `"`, `<`, `>`, `|`).

**JSON params:**
```json
{ "name": "test/screen:1*?" }
```

**Expected result:** Should either sanitize the name (replace invalid chars) or return an error.

**Notes:** Important for robustness if the name is used as a filename.

---

#### 1.9 — Edge: include_nodes with Non-Existent Node Paths

**Description:** Request property snapshots for node paths that don't exist in the current scene.

**JSON params:**
```json
{
  "name": "missing_nodes",
  "include_nodes": ["NonExistentNode", "/invalid/path"],
  "include_props": true
}
```

**Expected result:** Screenshot captured successfully. Non-existent node paths should return either `null` properties, an empty result, or an error per missing node.

**Notes:** Tests error handling for invalid node paths.

---

#### 1.10 — Edge: Empty include_nodes Array

**Description:** Provide an empty array for `include_nodes`.

**JSON params:**
```json
{
  "name": "empty_nodes",
  "include_nodes": [],
  "include_props": true
}
```

**Expected result:** Screenshot captured successfully. No property snapshots since no nodes were requested.

---

#### 1.11 — Edge: include_nodes with Duplicate Paths

**Description:** List the same node path multiple times.

**JSON params:**
```json
{
  "name": "duplicate_nodes",
  "include_nodes": ["Player", "Player", "Player"],
  "include_props": true
}
```

**Expected result:** Should succeed. Properties returned once or deduplicated. Should not crash.

---

#### 1.12 — Edge: include_props=true but no include_nodes

**Description:** Enable property snapshots but don't list any nodes.

**JSON params:**
```json
{
  "name": "props_no_nodes",
  "include_props": true
}
```

**Expected result:** Screenshot captured successfully. No property data returned (no nodes to snapshot).

---

#### 1.13 — Edge: Boolean coercion for include_props

**Description:** Pass a truthy/falsy non-boolean value for `include_props`.

**JSON params:**
```json
{ "name": "truthy_test", "include_props": 1 }
```
```json
{ "name": "falsy_test", "include_props": 0 }
```

**Expected result:** Likely fails Zod validation since `include_props` expects a boolean, not a number. Should return a validation error or coerce to boolean.

---

#### 1.14 — Edge: include_nodes with Scalar Instead of Array

**Description:** Pass a single string instead of an array for `include_nodes`.

**JSON params:**
```json
{
  "name": "scalar_nodes",
  "include_nodes": "Player",
  "include_props": true
}
```

**Expected result:** Should fail Zod validation since `include_nodes` expects `z.array(z.string())`.

---

## Tool 2: `compare_screenshots`

**Description:** Compare two screenshots pixel-by-pixel and return a diff result with mismatch percentage

### Parameters

| Parameter | Type | Required | Default | Constraints | Description |
|-----------|------|----------|---------|-------------|-------------|
| `baseline` | `string` (FilePath) | **yes** | — | — | Path to the baseline screenshot |
| `current` | `string` (FilePath) | **yes** | — | — | Path to the current screenshot |
| `threshold` | `number` | no | `0.01` | `0 ≤ threshold ≤ 1` | Pixel difference threshold (0-1). Default: 0.01 |

### Test Scenarios

#### 2.1 — Happy Path: Compare Identical Screenshots

**Description:** Compare a screenshot against itself (should be 0% difference).

**JSON params:**
```json
{
  "baseline": "res://screenshots/baseline.png",
  "current": "res://screenshots/baseline.png"
}
```

**Expected result:** Success. Mismatch percentage = 0%. Result indicates match (below default threshold of 0.01).

**Notes:** Uses default threshold (0.01).

---

#### 2.2 — Happy Path: Compare Different Screenshots

**Description:** Compare two genuinely different screenshots.

**JSON params:**
```json
{
  "baseline": "res://screenshots/menu_v1.png",
  "current": "res://screenshots/menu_v2.png"
}
```

**Expected result:** Success. Returns mismatch percentage and diff result. Whether it passes/fails depends on the mismatch percentage vs. the threshold.

---

#### 2.3 — Happy Path: Custom Threshold (permissive)

**Description:** Use a high threshold to accept larger differences.

**JSON params:**
```json
{
  "baseline": "res://screenshots/baseline.png",
  "current": "res://screenshots/current.png",
  "threshold": 0.5
}
```

**Expected result:** Success. More likely to return a "match" result since threshold is permissive (50%).

---

#### 2.4 — Happy Path: Custom Threshold (strict)

**Description:** Use a very strict threshold (0 — exact pixel match required).

**JSON params:**
```json
{
  "baseline": "res://screenshots/baseline.png",
  "current": "res://screenshots/current.png",
  "threshold": 0
}
```

**Expected result:** Success. Only returns "match" if every single pixel is identical.

**Notes:** Boundary value: minimum allowed threshold.

---

#### 2.5 — Enum/Boundary: threshold = 1

**Description:** Use the maximum allowed threshold (100% — always matches).

**JSON params:**
```json
{
  "baseline": "res://screenshots/baseline.png",
  "current": "res://screenshots/different.png",
  "threshold": 1
}
```

**Expected result:** Always returns "match" regardless of pixel differences.

**Notes:** Boundary value: maximum allowed threshold.

---

#### 2.6 — Edge: Missing baseline File

**Description:** Baseline path points to a non-existent file.

**JSON params:**
```json
{
  "baseline": "res://screenshots/nonexistent.png",
  "current": "res://screenshots/current.png"
}
```

**Expected result:** Error returned. Should not crash. Error message should indicate the baseline file was not found.

---

#### 2.7 — Edge: Missing Current File

**Description:** Current path points to a non-existent file.

**JSON params:**
```json
{
  "baseline": "res://screenshots/baseline.png",
  "current": "res://screenshots/nonexistent.png"
}
```

**Expected result:** Error returned. Should not crash. Error message should indicate the current file was not found.

---

#### 2.8 — Edge: Both Files Missing

**Description:** Neither file exists.

**JSON params:**
```json
{
  "baseline": "res://screenshots/nonexistent1.png",
  "current": "res://screenshots/nonexistent2.png"
}
```

**Expected result:** Error returned. Should report at least one missing file.

---

#### 2.9 — Edge: Images of Different Dimensions

**Description:** Compare images with different resolutions.

**JSON params:**
```json
{
  "baseline": "res://screenshots/1920x1080.png",
  "current": "res://screenshots/1280x720.png"
}
```

**Expected result:** Should return an error (cannot compare different dimensions) OR compute mismatch on the overlapping area. Behavior depends on implementation.

---

#### 2.10 — Edge: Invalid FilePath Format

**Description:** Provide a malformed path not matching `res://` convention.

**JSON params:**
```json
{
  "baseline": "not-a-valid-path",
  "current": "also/invalid"
}
```

**Expected result:** Error indicating invalid path format or file not found.

---

#### 2.11 — Edge: threshold Below Minimum

**Description:** Provide a threshold value below 0.

**JSON params:**
```json
{
  "baseline": "res://screenshots/baseline.png",
  "current": "res://screenshots/current.png",
  "threshold": -0.1
}
```

**Expected result:** Should fail Zod validation (`z.number().min(0)`). Validation error returned.

---

#### 2.12 — Edge: threshold Above Maximum

**Description:** Provide a threshold value above 1.

**JSON params:**
```json
{
  "baseline": "res://screenshots/baseline.png",
  "current": "res://screenshots/current.png",
  "threshold": 1.5
}
```

**Expected result:** Should fail Zod validation (`z.number().max(1)`). Validation error returned.

---

#### 2.13 — Edge: Very Small Threshold

**Description:** Use a threshold slightly above 0 to allow trivial differences.

**JSON params:**
```json
{
  "baseline": "res://screenshots/baseline.png",
  "current": "res://screenshots/current.png",
  "threshold": 0.0001
}
```

**Expected result:** Should accept the value (within [0,1] range). Extremely strict comparison.

---

#### 2.14 — Edge: Large Images

**Description:** Compare large-resolution images (e.g., 4K).

**JSON params:**
```json
{
  "baseline": "res://screenshots/4k_baseline.png",
  "current": "res://screenshots/4k_current.png"
}
```

**Expected result:** Should succeed. May take longer to compute pixel differences. Should not hit memory limits.

---

#### 2.15 — Edge: Empty FilePath Strings

**Description:** Provide empty strings for both paths.

**JSON params:**
```json
{
  "baseline": "",
  "current": ""
}
```

**Expected result:** Should fail with validation error because the paths are invalid/empty.

---

#### 2.16 — Edge: Non-Image File

**Description:** Provide paths to non-image files (e.g., `.gd` script files).

**JSON params:**
```json
{
  "baseline": "res://scripts/player.gd",
  "current": "res://scenes/main.tscn"
}
```

**Expected result:** Error indicating the files are not valid images or cannot be read as images.

---

#### 2.17 — Edge: threshold as String

**Description:** Pass threshold as a string that could be coerced.

**JSON params:**
```json
{
  "baseline": "res://screenshots/baseline.png",
  "current": "res://screenshots/current.png",
  "threshold": "0.05"
}
```

**Expected result:** Should fail Zod validation since threshold expects a number. OR silently coerced (depends on strictness).

---

## Tool 3: `assert_visual_match`

**Description:** Assert that a screenshot matches a baseline within a threshold — pass/fail result

### Parameters

| Parameter | Type | Required | Default | Constraints | Description |
|-----------|------|----------|---------|-------------|-------------|
| `name` | `string` (Name) | **yes** | — | — | Screenshot name to check — must match a name previously used with `take_screenshot_with_context` |
| `baseline` | `string` (FilePath) | **yes** | — | — | Path or name of the baseline screenshot (resolves against baselines directory if not a full path) |
| `threshold` | `number` | no | `0.01` | `0 ≤ threshold ≤ 1` | Acceptable difference threshold. Default: 0.01 |

### Test Scenarios

#### 3.1 — Happy Path: Match Against Previously Taken Screenshot

**Description:** Take a screenshot with `take_screenshot_with_context`, then assert it matches a known baseline.

**JSON params:**
```json
{
  "name": "main_menu",
  "baseline": "res://baselines/main_menu_baseline.png",
  "threshold": 0.01
}
```

**Expected result:** Pass/fail boolean result. If the screenshot named `"main_menu"` matches the baseline within 1%, passes. Otherwise fails with mismatch details.

**Notes:** Requires that `take_screenshot_with_context` was previously called with `name: "main_menu"`.

---

#### 3.2 — Happy Path: Strict Match (threshold=0)

**Description:** Require exact pixel-perfect match.

**JSON params:**
```json
{
  "name": "pixel_perfect",
  "baseline": "res://baselines/pixel_perfect_baseline.png",
  "threshold": 0
}
```

**Expected result:** Pass only if every pixel matches exactly.

---

#### 3.3 — Happy Path: Lenient Match (threshold=0.1)

**Description:** Allow 10% pixel difference.

**JSON params:**
```json
{
  "name": "lenient_check",
  "baseline": "res://baselines/lenient_baseline.png",
  "threshold": 0.1
}
```

**Expected result:** More likely to pass than default threshold. Up to 10% pixel difference tolerated.

---

#### 3.4 — Happy Path: Baseline Resolves Against Baselines Directory

**Description:** Provide a baseline name (not a full path) that resolves against the project's baselines directory.

**JSON params:**
```json
{
  "name": "gameplay_hud",
  "baseline": "hud_baseline"
}
```

**Expected result:** Should resolve `"hud_baseline"` against the baselines directory (e.g., `res://baselines/hud_baseline.png`). Pass/fail result returned.

**Notes:** The description says `baseline` "resolves against baselines directory if not a full path."

---

#### 3.5 — Edge: Screenshot Name Not Previously Taken

**Description:** Assert a match using a name that was never used in `take_screenshot_with_context`.

**JSON params:**
```json
{
  "name": "never_taken",
  "baseline": "res://baselines/some_baseline.png"
}
```

**Expected result:** Error indicating that no screenshot with the name `"never_taken"` exists.

---

#### 3.6 — Edge: Missing Baseline File

**Description:** The baseline file does not exist.

**JSON params:**
```json
{
  "name": "existing_screenshot",
  "baseline": "res://baselines/nonexistent_baseline.png"
}
```

**Expected result:** Error indicating baseline file not found.

---

#### 3.7 — Edge: threshold Below Minimum

**Description:** Provide a negative threshold.

**JSON params:**
```json
{
  "name": "valid_name",
  "baseline": "res://baselines/baseline.png",
  "threshold": -0.5
}
```

**Expected result:** Zod validation error (`min(0)` violated).

---

#### 3.8 — Edge: threshold Above Maximum

**Description:** Provide a threshold above 1.

**JSON params:**
```json
{
  "name": "valid_name",
  "baseline": "res://baselines/baseline.png",
  "threshold": 2.0
}
```

**Expected result:** Zod validation error (`max(1)` violated).

---

#### 3.9 — Edge: Empty Name

**Description:** Provide an empty string for `name`.

**JSON params:**
```json
{
  "name": "",
  "baseline": "res://baselines/baseline.png"
}
```

**Expected result:** May fail with validation error or "screenshot not found" error.

---

#### 3.10 — Edge: Empty Baseline

**Description:** Provide an empty string for `baseline`.

**JSON params:**
```json
{
  "name": "existing_screenshot",
  "baseline": ""
}
```

**Expected result:** Error indicating invalid baseline path.

---

#### 3.11 — Edge: Multiple Asserts with Same Name

**Description:** Call `assert_visual_match` twice with the same `name` but different baselines.

**JSON params:** (Call 1)
```json
{
  "name": "reusable_screenshot",
  "baseline": "res://baselines/baseline_a.png"
}
```
(Call 2)
```json
{
  "name": "reusable_screenshot",
  "baseline": "res://baselines/baseline_b.png"
}
```

**Expected result:** Both should execute independently. The same screenshot is compared against two different baselines.

---

#### 3.12 — Edge: baseline as Resolved Short Name vs Full Path

**Description:** Verify baseline resolution: provide `"my_baseline"` (should resolve to `res://baselines/my_baseline.png`) vs `"res://baselines/my_baseline.png"`.

**JSON params:**
```json
{ "name": "test1", "baseline": "my_baseline" }
```
```json
{ "name": "test1", "baseline": "res://baselines/my_baseline.png" }
```

**Expected result:** Both should resolve to the same file and produce identical results (assuming the file exists at `res://baselines/my_baseline.png`).

---

## Tool 4: `record_visual_regression`

**Description:** Record multiple frames over time for visual regression testing

### Parameters

| Parameter | Type | Required | Default | Constraints | Description |
|-----------|------|----------|---------|-------------|-------------|
| `test_name` | `string` (Name) | **yes** | — | — | Name for this recording session |
| `frames` | `number` (int) | no | `10` | `1 ≤ frames ≤ 100`, integer | Number of frames to capture |
| `interval` | `number` | no | `0.5` | `0.1 ≤ interval ≤ 10` | Seconds between captures |

### Test Scenarios

#### 4.1 — Happy Path: Default Recording

**Description:** Record with only the required `test_name` parameter.

**JSON params:**
```json
{ "test_name": "default_recording" }
```

**Expected result:** Success. Records 10 frames at 0.5-second intervals (total ~5 seconds). Frames saved.

---

#### 4.2 — Happy Path: Custom Frames and Interval

**Description:** Record a specific number of frames at a specific interval.

**JSON params:**
```json
{
  "test_name": "custom_params",
  "frames": 5,
  "interval": 0.2
}
```

**Expected result:** Success. Records 5 frames at 0.2-second intervals (total ~1 second).

---

#### 4.3 — Happy Path: Maximum Frames

**Description:** Record the maximum allowed number of frames.

**JSON params:**
```json
{
  "test_name": "max_frames",
  "frames": 100,
  "interval": 0.1
}
```

**Expected result:** Success. Records 100 frames at 0.1-second intervals (total ~10 seconds). Longest allowed recording.

**Notes:** Both parameters at their boundary values simultaneously.

---

#### 4.4 — Happy Path: Maximum Interval

**Description:** Record with the longest allowed interval between frames.

**JSON params:**
```json
{
  "test_name": "max_interval",
  "frames": 2,
  "interval": 10
}
```

**Expected result:** Success. Records 2 frames, 10 seconds apart (total ~20 seconds). Longest possible total recording time.

---

#### 4.5 — Boundary: frames at Minimum (1)

**Description:** Record exactly 1 frame.

**JSON params:**
```json
{
  "test_name": "single_frame",
  "frames": 1
}
```

**Expected result:** Success. Records 1 frame. Interval is irrelevant for single frame but should still accept the call.

---

#### 4.6 — Boundary: interval at Minimum (0.1)

**Description:** Record frames at the shortest allowed interval.

**JSON params:**
```json
{
  "test_name": "fast_recording",
  "frames": 10,
  "interval": 0.1
}
```

**Expected result:** Success. Records 10 frames with 0.1s between each.

---

#### 4.7 — Edge: frames Below Minimum

**Description:** Request 0 frames.

**JSON params:**
```json
{
  "test_name": "zero_frames",
  "frames": 0
}
```

**Expected result:** Zod validation error (`min(1)` violated).

---

#### 4.8 — Edge: frames Above Maximum

**Description:** Request more than 100 frames.

**JSON params:**
```json
{
  "test_name": "too_many_frames",
  "frames": 101
}
```

**Expected result:** Zod validation error (`max(100)` violated).

---

#### 4.9 — Edge: interval Below Minimum

**Description:** Request an interval below 0.1 seconds.

**JSON params:**
```json
{
  "test_name": "too_fast",
  "interval": 0.01
}
```

**Expected result:** Zod validation error (`min(0.1)` violated).

---

#### 4.10 — Edge: interval Above Maximum

**Description:** Request an interval above 10 seconds.

**JSON params:**
```json
{
  "test_name": "too_slow",
  "interval": 11
}
```

**Expected result:** Zod validation error (`max(10)` violated).

---

#### 4.11 — Edge: Non-Integer frames

**Description:** Pass a floating-point number for `frames` (which expects an integer).

**JSON params:**
```json
{
  "test_name": "float_frames",
  "frames": 5.5
}
```

**Expected result:** Zod validation error (`z.number().int()` constraint violated).

---

#### 4.12 — Edge: interval as Negative

**Description:** Pass a negative interval value.

**JSON params:**
```json
{
  "test_name": "negative_interval",
  "interval": -1
}
```

**Expected result:** Zod validation error (`min(0.1)` violated, also negative is invalid).

---

#### 4.13 — Edge: Very Large test_name

**Description:** Provide an extremely long test name.

**JSON params:**
```json
{ "test_name": "A".repeat(1000) }
```

**Expected result:** May succeed with truncated name or fail if the internal storage has name length limits.

---

#### 4.14 — Edge: Empty test_name

**Description:** Provide an empty test name.

**JSON params:**
```json
{ "test_name": "" }
```

**Expected result:** Should fail with validation error.

---

#### 4.15 — Edge: Concurrent Recordings

**Description:** Start a second recording while one is already in progress.

**JSON params:** (Call 1)
```json
{ "test_name": "recording_a", "frames": 10, "interval": 0.5 }
```
(Call 2, immediately after)
```json
{ "test_name": "recording_b", "frames": 5, "interval": 0.5 }
```

**Expected result:** Either: the second call cancels/overwrites the first, queues the second, or returns an error ("recording already in progress").

---

#### 4.16 — Edge: Same test_name Used Twice

**Description:** Record with the same name, then record again with the same name.

**JSON params:** (After recording completes)
```json
{ "test_name": "duplicate_name", "frames": 3, "interval": 0.5 }
```
(Again after first completes)
```json
{ "test_name": "duplicate_name", "frames": 5, "interval": 1 }
```

**Expected result:** Second recording should either overwrite the first or append. Should not crash.

---

#### 4.17 — Edge: Game Not Running During Record

**Description:** Call `record_visual_regression` when the game is not running.

**JSON params:**
```json
{ "test_name": "no_game_running" }
```

**Expected result:** Error indicating that the game must be running to record frames.

---

## Tool 5: `get_visual_diff_report`

**Description:** Get the aggregated visual regression report from all `assert_visual_match` calls in this session

### Parameters

**No parameters.**

### Test Scenarios

#### 5.1 — Happy Path: Report After Successful Asserts

**Description:** Run several `assert_visual_match` calls (some passing, some failing), then fetch the aggregated report.

**JSON params:**
```json
{}
```

**Expected result:** Returns an aggregated report containing:
- List of all assert_visual_match calls made in this session
- Pass/fail status for each
- Mismatch percentages
- Summary statistics (total asserts, passes, failures)

**Notes:** Requires prior `assert_visual_match` calls to have meaningful data.

---

#### 5.2 — Edge: No Asserts Made Yet

**Description:** Call `get_visual_diff_report` without any prior `assert_visual_match` calls.

**JSON params:**
```json
{}
```

**Expected result:** Should return an empty report or a report indicating 0 asserts were run. Should not error.

---

#### 5.3 — Edge: Report After Session Restart

**Description:** Call `get_visual_diff_report` after the Godot editor has been restarted (new session).

**JSON params:**
```json
{}
```

**Expected result:** Returns an empty/fresh report (no historical data from previous session).

---

#### 5.4 — Edge: Multiple Calls in Same Session

**Description:** Call `get_visual_diff_report` multiple times within the same session.

**JSON params:**
```json
{}
```

**Expected result:** Each call returns the same accumulated data. Report grows as more asserts are run between calls.

---

#### 5.5 — Edge: Report After Mixed Results

**Description:** Run asserts that produce a mix of passes, failures, and errors, then fetch the report.

**JSON params:** (After running varied assert calls)
```json
{}
```

**Expected result:** Report includes all asserts with their individual statuses. Summary correctly counts passes, failures, and errors.

---

#### 5.6 — Edge: Passing Extra Parameters

**Description:** Call `get_visual_diff_report` with unexpected parameters (the schema defines `{}`).

**JSON params:**
```json
{ "unexpected": "value" }
```

**Expected result:** Should either ignore extra parameters silently or fail with validation error (depends on Zod strictness). Most likely succeeds and ignores extras.

---

## Tool 6: `set_visual_baseline`

**Description:** Set or update a visual baseline for future comparisons

### Parameters

| Parameter | Type | Required | Default | Constraints | Description |
|-----------|------|----------|---------|-------------|-------------|
| `name` | `string` (Name) | **yes** | — | — | Baseline name identifier |
| `screenshot_path` | `string` (FilePath) | **yes** | — | — | Path to the screenshot to use as baseline |

### Test Scenarios

#### 6.1 — Happy Path: Create New Baseline

**Description:** Set a screenshot as a new baseline with a unique name.

**JSON params:**
```json
{
  "name": "main_menu_v1",
  "screenshot_path": "res://screenshots/main_menu_v1.png"
}
```

**Expected result:** Success. Baseline `"main_menu_v1"` is now registered/created, pointing to the specified screenshot. Future `assert_visual_match` calls can reference this baseline.

---

#### 6.2 — Happy Path: Update Existing Baseline

**Description:** Overwrite an existing baseline with a new screenshot.

**JSON params:** (After initial creation)
```json
{
  "name": "main_menu_v1",
  "screenshot_path": "res://screenshots/main_menu_v2.png"
}
```

**Expected result:** Success. The baseline `"main_menu_v1"` now points to `"main_menu_v2.png"` instead. Previous association is overwritten.

---

#### 6.3 — Happy Path: Baseline with Complex Name

**Description:** Use a name with underscores, hyphens, and numbers.

**JSON params:**
```json
{
  "name": "level_3_boss-fight_v2",
  "screenshot_path": "res://screenshots/boss_fight.png"
}
```

**Expected result:** Success. Baseline created with the complex name.

---

#### 6.4 — Happy Path: Path Using res:// Prefix

**Description:** Use a full `res://` path for the screenshot.

**JSON params:**
```json
{
  "name": "hud_baseline",
  "screenshot_path": "res://screenshots/hud_capture.png"
}
```

**Expected result:** Success. Baseline created with the full `res://` path.

---

#### 6.5 — Edge: Screenshot File Does Not Exist

**Description:** Set a baseline pointing to a non-existent screenshot file.

**JSON params:**
```json
{
  "name": "future_baseline",
  "screenshot_path": "res://screenshots/not_taken_yet.png"
}
```

**Expected result:** Behavior depends on implementation: either succeeds (lazy validation — file checked only at comparison time) or fails with "file not found" error.

---

#### 6.6 — Edge: Empty Name

**Description:** Provide an empty string for `name`.

**JSON params:**
```json
{
  "name": "",
  "screenshot_path": "res://screenshots/some.png"
}
```

**Expected result:** Should fail with validation error.

---

#### 6.7 — Edge: Empty screenshot_path

**Description:** Provide an empty string for `screenshot_path`.

**JSON params:**
```json
{
  "name": "valid_name",
  "screenshot_path": ""
}
```

**Expected result:** Should fail with validation error or "invalid path" error.

---

#### 6.8 — Edge: Both Parameters Empty

**Description:** Provide empty strings for both parameters.

**JSON params:**
```json
{
  "name": "",
  "screenshot_path": ""
}
```

**Expected result:** Validation failure.

---

#### 6.9 — Edge: Invalid FilePath Format

**Description:** Provide a path that doesn't match the expected format.

**JSON params:**
```json
{
  "name": "bad_path_baseline",
  "screenshot_path": "C:\\Users\\absolute\\path\\screenshot.png"
}
```

**Expected result:** May fail with "invalid path" error if Godot expects `res://` or `user://` paths.

---

#### 6.10 — Edge: Name with Special Characters

**Description:** Use a name containing special characters (spaces, symbols).

**JSON params:**
```json
{
  "name": "test baseline @#$%^&*()",
  "screenshot_path": "res://screenshots/test.png"
}
```

**Expected result:** May succeed or fail depending on whether the baseline storage tolerates special characters in names.

---

#### 6.11 — Edge: Very Long Name

**Description:** Use an extremely long baseline name.

**JSON params:**
```json
{
  "name": "A".repeat(500),
  "screenshot_path": "res://screenshots/test.png"
}
```

**Expected result:** May succeed with truncated name or fail if storage has limits.

---

#### 6.12 — Edge: Set Baseline Then Immediately Assert

**Description:** Set a baseline and immediately assert against it (in the same session).

**JSON params:** (Step 1)
```json
{
  "name": "quick_baseline",
  "screenshot_path": "res://screenshots/existing.png"
}
```
(Step 2: use `assert_visual_match`)
```json
{
  "name": "some_screenshot",
  "baseline": "quick_baseline",
  "threshold": 0.01
}
```

**Expected result:** Both steps succeed. The baseline registered in step 1 is immediately usable in step 2's assertion.

---

#### 6.13 — Edge: Set Baseline with Non-Image File

**Description:** Use a `.gd` script or `.tscn` scene file as the baseline screenshot.

**JSON params:**
```json
{
  "name": "not_an_image",
  "screenshot_path": "res://scripts/player.gd"
}
```

**Expected result:** May succeed on registration but fail later during comparison when the file can't be read as an image. Or may fail immediately if type checking is performed.

---

#### 6.14 — Edge: Multiple Baselines with Same screenshot_path

**Description:** Register two different baseline names pointing to the same screenshot file.

**JSON params:** (Call 1)
```json
{ "name": "baseline_a", "screenshot_path": "res://screenshots/shared.png" }
```
(Call 2)
```json
{ "name": "baseline_b", "screenshot_path": "res://screenshots/shared.png" }
```

**Expected result:** Both succeed. Two different baseline names reference the same underlying image file.

---

## Cross-Tool Workflow Scenarios

### WF-1: Full Visual Regression Pipeline

**Description:** End-to-end workflow: take screenshot → set baseline → record regression → assert matches → get report.

**Steps:**

1. **Take baseline screenshot:**
```json
{ "name": "gameplay_start", "include_nodes": ["Player"], "include_props": true }
```
2. **Set as baseline:**
```json
{ "name": "gameplay_start_baseline", "screenshot_path": "res://screenshots/gameplay_start.png" }
```
3. **Record visual regression:**
```json
{ "test_name": "gameplay_sequence", "frames": 20, "interval": 0.5 }
```
4. **Take current screenshot:**
```json
{ "name": "gameplay_current", "include_props": false }
```
5. **Compare screenshots:**
```json
{ "baseline": "res://screenshots/gameplay_start.png", "current": "res://screenshots/gameplay_current.png", "threshold": 0.05 }
```
6. **Assert visual match:**
```json
{ "name": "gameplay_current", "baseline": "gameplay_start_baseline", "threshold": 0.05 }
```
7. **Get report:**
```json
{}
```

**Expected result:** All steps succeed. Final report includes the assertion result.

---

### WF-2: Baseline Update Cycle

**Description:** Create baseline → assert (passes) → update baseline → assert again.

**Steps:**

1. `take_screenshot_with_context` — capture `"v1"`
2. `set_visual_baseline` — register as `"main_baseline"` pointing to `v1`
3. `assert_visual_match` — compare `"v1"` against `"main_baseline"` → should pass
4. `take_screenshot_with_context` — capture `"v2"` (changed UI)
5. `set_visual_baseline` — update `"main_baseline"` to point to `v2`
6. `assert_visual_match` — compare `"v2"` against `"main_baseline"` → should pass
7. `get_visual_diff_report` — report shows 2 asserts, both passing

**Expected result:** Baseline updates work correctly. Old baseline replaced.

---

### WF-3: Cross-Screenshot Comparison Without Assert

**Description:** Use `compare_screenshots` directly (not through `assert_visual_match`) and verify it does NOT appear in the diff report.

**Steps:**

1. `compare_screenshots` — compare two screenshots → returns mismatch %
2. `get_visual_diff_report` — fetch report

**Expected result:** The comparison result from step 1 does NOT appear in the report (only `assert_visual_match` calls are tracked in the session report).

---

## Summary: Parameter Coverage Matrix

| Tool | Required Params | Optional Params | Enum/Constrained | No-Param |
|------|----------------|-----------------|------------------|----------|
| `take_screenshot_with_context` | `name` | `include_nodes`, `include_props` | — | — |
| `compare_screenshots` | `baseline`, `current` | `threshold` | `threshold` [0..1] | — |
| `assert_visual_match` | `name`, `baseline` | `threshold` | `threshold` [0..1] | — |
| `record_visual_regression` | `test_name` | `frames`, `interval` | `frames` [1..100], `interval` [0.1..10] | — |
| `get_visual_diff_report` | — | — | — | ✓ |
| `set_visual_baseline` | `name`, `screenshot_path` | — | — | — |

### Test Count Summary

| Tool | Happy Path | Edge Cases | Total |
|------|-----------|------------|-------|
| `take_screenshot_with_context` | 3 | 11 | 14 |
| `compare_screenshots` | 4 | 13 | 17 |
| `assert_visual_match` | 4 | 8 | 12 |
| `record_visual_regression` | 5 | 12 | 17 |
| `get_visual_diff_report` | 1 | 5 | 6 |
| `set_visual_baseline` | 4 | 10 | 14 |
| **Cross-tool workflows** | **3** | — | **3** |
| **Grand Total** | | | **83** |
