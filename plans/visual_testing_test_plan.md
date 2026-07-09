# Visual Testing Tools — Test Plan

> **File**: `server/src/tools/visual_testing.ts`
> **Tools count**: 10
> **All tools delegate to Godot via `callGodot(bridge, toolName, args)` — results depend on Godot editor state.**

---

## Prerequisites for All Tests

- Godot editor is running with MCP plugin active and connected
- A scene is open in the editor
- The `mcp_runtime.gd` autoload is registered (required for runtime screenshots)
- The `baselines/` directory exists in the Godot project (for `set_visual_baseline`)

---

## Tool 1: `take_screenshot_with_context`

**Description**: Take a screenshot with scene context metadata (node tree, properties of specified nodes).

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | `string` | **yes** | — | Name for this screenshot (used as filename, e.g. `"main_menu"`) |
| `include_nodes` | `string[]` | no | — | Node paths to include property data for (requires `include_props=true`) |
| `include_props` | `boolean` | no | `false` | Whether to include property snapshots for listed `include_nodes` |

### Test Scenarios

#### Scenario 1.1 — Happy path: minimal required params

**Description**: Take a screenshot with only the required `name` parameter. No property snapshots.

**Call**:
```json
{
  "name": "main_menu"
}
```

**Expected result**: Returns a JSON object containing:
- `screenshot_path` (string) — path where the screenshot was saved, e.g. `"res://screenshots/main_menu.png"`
- `scene_tree` (object/array) — current scene tree structure
- `timestamp` or metadata about when the capture was taken

**Notes**: This is the simplest valid call. Verifies the tool can capture a screenshot and scene tree without any optional features.

**What to pay attention to**: Verify that the screenshot path is valid and contains the passed name. The scene tree should contain at least the root node of the current scene.

---

#### Scenario 1.2 — With `include_nodes` and `include_props=true`

**Description**: Take a screenshot and include property snapshots for specific nodes.

**Call**:
```json
{
  "name": "player_state",
  "include_nodes": ["Player", "Player/Sprite2D", "Camera2D"],
  "include_props": true
}
```

**Expected result**: Returns screenshot data PLUS property snapshots for each specified node (e.g. `position`, `visible`, `modulate`, etc.).

**Notes**: Requires that the open scene actually contains nodes named `Player`, `Player/Sprite2D`, and `Camera2D`. If a node path doesn't exist, Godot may return an error or skip it.

**What to pay attention to**: Each node's properties should contain current values (position, visible, etc.). If a node is not found — there should be an error or warning, not an empty result.

---

#### Scenario 1.3 — With `include_nodes` but `include_props=false` (default)

**Description**: Provide `include_nodes` but leave `include_props` at default `false`. Property data should NOT be included.

**Call**:
```json
{
  "name": "no_props",
  "include_nodes": ["Player"],
  "include_props": false
}
```

**Expected result**: Screenshot and scene tree returned, but NO property snapshots for the listed nodes (since `include_props` is `false`).

**Notes**: Verifies that `include_props=false` correctly suppresses property data even when `include_nodes` is provided.

**What to pay attention to**: The result should NOT contain any node property data, despite the presence of `include_nodes`. This verifies the correctness of the "opt-in" logic for properties.

---

#### Scenario 1.4 — Empty `name` (edge case)

**Description**: Pass an empty string as `name`. Schema allows it (no `.min(1)` on Name), but behavior may vary.

**Call**:
```json
{
  "name": ""
}
```

**Expected result**: Either succeeds with an empty-name filename or returns an error. Determine actual Godot-side behavior.

**Notes**: `Name` schema is `z.string()` with no min length. Godot file system may reject empty filenames. This is an edge case to document.

**What to pay attention to**: Verify that the tool does not crash. Either a valid file with a default name should be created, or a clear validation error should be returned.

---

## Tool 2: `compare_screenshots`

**Description**: Compare two screenshots pixel-by-pixel and return a diff result with mismatch percentage.

### Parameters

| Name | Type | Required | Default | Constraints | Description |
|---|---|---|---|---|---|
| `baseline` | `string` | **yes** | — | — | Path to the baseline screenshot |
| `current` | `string` | **yes** | — | — | Path to the current screenshot |
| `threshold` | `number` | no | `0.01` | `0–1` | Pixel difference threshold |

### Test Scenarios

#### Scenario 2.1 — Happy path: compare two identical screenshots

**Description**: Compare a screenshot against itself. Mismatch should be 0%.

**Prerequisites**: A screenshot must exist at a known path (use `take_screenshot_with_context` first).

**Call**:
```json
{
  "baseline": "res://screenshots/main_menu.png",
  "current": "res://screenshots/main_menu.png"
}
```

**Expected result**:
- `match` (boolean): `true`
- `mismatch_percentage` (number): `0` or very close to `0`
- Possibly `diff_image_path` pointing to a visual diff

**Notes**: Same file compared to itself — should always pass. Verifies the comparison engine works.

**What to pay attention to**: mismatch_percentage should be exactly 0 or extremely close to 0 (compression artifacts are possible with jpg). The diff file may be absent or empty.

---

#### Scenario 2.2 — Compare two different screenshots

**Description**: Compare two visually different screenshots. Mismatch should exceed the threshold.

**Prerequisites**: Two different screenshots must exist (e.g. different scenes or different states).

**Call**:
```json
{
  "baseline": "res://screenshots/main_menu.png",
  "current": "res://screenshots/gameplay.png"
}
```

**Expected result**:
- `match` (boolean): `false`
- `mismatch_percentage` (number): significantly > `0.01`
- Possibly a diff image highlighting the differences

**Notes**: These screenshots must be visually distinct (different scenes). If they're from the same scene at different times, mismatch may be very small.

**What to pay attention to**: mismatch_percentage should be substantially greater than 0. The diff image should clearly show the differences.

---

#### Scenario 2.3 — Custom threshold: tight vs. loose

**Description**: Compare two screenshots with a very strict threshold (`0.001`) and a very loose threshold (`0.5`).

**Call (strict)**:
```json
{
  "baseline": "res://screenshots/state_a.png",
  "current": "res://screenshots/state_b.png",
  "threshold": 0.001
}
```

**Call (loose)**:
```json
{
  "baseline": "res://screenshots/state_a.png",
  "current": "res://screenshots/state_b.png",
  "threshold": 0.5
}
```

**Expected result**: Same mismatch percentage for both calls, but `match` result differs depending on whether mismatch < threshold.

**Notes**: Verifies threshold logic. With `threshold: 0.5`, almost any comparison should pass. With `threshold: 0.001`, even tiny differences fail.

**What to pay attention to**: Verify that `match` correctly depends on `mismatch_percentage < threshold`, not on a fixed value.

---

#### Scenario 2.4 — Non-existent file path (edge case)

**Description**: Pass a path that doesn't exist.

**Call**:
```json
{
  "baseline": "res://screenshots/nonexistent.png",
  "current": "res://screenshots/also_nonexistent.png"
}
```

**Expected result**: Error — file not found. Should return an `isError` result or throw.

**Notes**: Tests error handling for missing files.

**What to pay attention to**: The error should be clear and contain the path to the non-existent file. There should be no unhandled exceptions.

---

#### Scenario 2.5 — Threshold boundary values (edge case)

**Description**: Test threshold at exact boundaries: `0` and `1`.

**Call (threshold=0)**:
```json
{
  "baseline": "res://screenshots/a.png",
  "current": "res://screenshots/b.png",
  "threshold": 0
}
```

**Call (threshold=1)**:
```json
{
  "baseline": "res://screenshots/a.png",
  "current": "res://screenshots/b.png",
  "threshold": 1
}
```

**Expected result**: `threshold=0` — only perfect matches pass. `threshold=1` — everything passes.

**Notes**: Schema allows `0` and `1` (inclusive `.min(0).max(1)`). Verifies boundary handling.

**What to pay attention to**: `threshold=1` should always give `match: true`. `threshold=0` should give `match: true` only for a perfect match.

---

## Tool 3: `assert_visual_match`

**Description**: Assert that a screenshot matches a baseline within a threshold — pass/fail result.

### Parameters

| Name | Type | Required | Default | Constraints | Description |
|---|---|---|---|---|---|
| `name` | `string` | **yes** | — | — | Screenshot name to check — must match a name previously used with `take_screenshot_with_context` |
| `baseline` | `string` | **yes** | — | — | Path or name of the baseline screenshot (resolves against baselines directory if not a full path) |
| `threshold` | `number` | no | `0.01` | `0–1` | Acceptable difference threshold |

### Test Scenarios

#### Scenario 3.1 — Happy path: screenshot matches baseline

**Description**: Take a screenshot, set it as baseline, then assert match.

**Prerequisites**:
1. Call `take_screenshot_with_context` with `name: "login_screen"`
2. Call `set_visual_baseline` with `name: "login_screen"`, `screenshot_path: "res://screenshots/login_screen.png"`

**Call**:
```json
{
  "name": "login_screen",
  "baseline": "res://screenshots/login_screen.png",
  "threshold": 0.01
}
```

**Expected result**:
- `pass` (boolean): `true`
- `mismatch_percentage` (number): ≤ `0.01`
- Possibly `details` with comparison info

**Notes**: This is the core visual regression flow: capture → baseline → assert.

**What to pay attention to**: Verify that the result contains an explicit pass/fail. mismatch_percentage should be ≤ threshold.

---

#### Scenario 3.2 — Screenshot does NOT match baseline

**Description**: Assert a screenshot against a different baseline.

**Call**:
```json
{
  "name": "login_screen",
  "baseline": "res://screenshots/main_menu.png",
  "threshold": 0.01
}
```

**Expected result**:
- `pass` (boolean): `false`
- `mismatch_percentage` (number): > `0.01`

**Notes**: The screenshot `login_screen` was captured but compared against a different scene's baseline.

**What to pay attention to**: The result should clearly indicate `pass: false` and show how large the mismatch is.

---

#### Scenario 3.3 — Name references a screenshot that was never taken (edge case)

**Description**: Use a `name` that was never passed to `take_screenshot_with_context`.

**Call**:
```json
{
  "name": "never_captured",
  "baseline": "res://screenshots/main_menu.png",
  "threshold": 0.01
}
```

**Expected result**: Error — screenshot not found for the given name. The tool description says the name "must match a name previously used with `take_screenshot_with_context`".

**Notes**: Tests the dependency on prior `take_screenshot_with_context` calls.

**What to pay attention to**: The error should be informative — indicating that a screenshot with this name was not found.

---

#### Scenario 3.4 — Baseline file does not exist (edge case)

**Description**: Reference a baseline file that doesn't exist on disk.

**Call**:
```json
{
  "name": "login_screen",
  "baseline": "res://baselines/nonexistent_baseline.png",
  "threshold": 0.01
}
```

**Expected result**: Error — baseline file not found.

**What to pay attention to**: The error should indicate the missing path. There should be no unhandled exceptions.

---

## Tool 4: `record_visual_regression`

**Description**: Record multiple frames over time for visual regression testing.

### Parameters

| Name | Type | Required | Default | Constraints | Description |
|---|---|---|---|---|---|
| `test_name` | `string` | **yes** | — | — | Name for this recording session |
| `frames` | `integer` | no | `10` | `1–100` | Number of frames to capture |
| `interval` | `number` | no | `0.5` | `0.1–10` | Seconds between captures |

### Test Scenarios

#### Scenario 4.1 — Happy path: default params

**Description**: Record with only the required `test_name`. Uses defaults: 10 frames at 0.5s intervals.

**Call**:
```json
{
  "test_name": "player_walk_cycle"
}
```

**Expected result**:
- `recording_id` or `test_name` identifier
- `frames_captured` (number): `10`
- List of frame paths or frame data
- Possibly `duration` (should be ~5 seconds = 10 frames × 0.5s)

**Notes**: Default recording takes ~5 seconds. The game should be running and visually active for meaningful frames.

**What to pay attention to**: The number of captured frames should be exactly 10. Recording duration ~5 seconds. Frames should have unique paths/identifiers.

---

#### Scenario 4.2 — Custom frames and interval

**Description**: Record 3 frames at 1-second intervals (total ~3 seconds).

**Call**:
```json
{
  "test_name": "menu_transition",
  "frames": 3,
  "interval": 1.0
}
```

**Expected result**: 3 frames captured over ~3 seconds.

**What to pay attention to**: Verify that the interval between frames corresponds to ~1 second. Verify that frames are saved with unique names (possibly with a frame number suffix).

---

#### Scenario 4.3 — Boundary: minimum values

**Description**: Record 1 frame at 0.1s interval (absolute minimum).

**Call**:
```json
{
  "test_name": "single_frame",
  "frames": 1,
  "interval": 0.1
}
```

**Expected result**: Exactly 1 frame captured. Duration ~0.1s.

**What to pay attention to**: There should be exactly 1 frame. Verify that minimum values do not cause errors.

---

#### Scenario 4.4 — Boundary: maximum values

**Description**: Record 100 frames at 10s interval (maximum — total ~1000 seconds = ~16.7 minutes).

**Call**:
```json
{
  "test_name": "long_session",
  "frames": 100,
  "interval": 10
}
```

**Expected result**: 100 frames captured over ~1000 seconds.

**Notes**: This is an extremely long recording. In practice, this would timeout. Use this to test whether the tool handles max values gracefully. May need to reduce for actual testing (e.g. `frames: 50, interval: 5`).

**What to pay attention to**: Verify that the tool does not crash on boundary values. If a timeout occurs — verify that the error is clear.

---

#### Scenario 4.5 — Out-of-range: `frames=0` (edge case)

**Description**: Pass `frames=0`, which is below the minimum of 1.

**Call**:
```json
{
  "test_name": "zero_frames",
  "frames": 0,
  "interval": 0.5
}
```

**Expected result**: Validation error — `frames` must be ≥ 1.

**What to pay attention to**: The error should contain constraint information (min: 1). Zod should reject this at the schema level.

---

#### Scenario 4.6 — Out-of-range: `frames=101` (edge case)

**Description**: Pass `frames=101`, which exceeds the maximum of 100.

**Call**:
```json
{
  "test_name": "too_many_frames",
  "frames": 101,
  "interval": 0.5
}
```

**Expected result**: Validation error — `frames` must be ≤ 100.

**What to pay attention to**: The error should contain constraint information (max: 100).

---

## Tool 5: `get_visual_diff_report`

**Description**: Get the aggregated visual regression report from all `assert_visual_match` calls in this session.

### Parameters

None. This tool takes no parameters.

### Test Scenarios

#### Scenario 5.1 — Happy path: report after multiple assertions

**Description**: Perform several `assert_visual_match` calls, then get the aggregated report.

**Prerequisites**:
1. Take 3 screenshots: `"menu"`, `"gameplay"`, `"hud"`
2. Set baselines for each
3. Call `assert_visual_match` for each (some passing, some failing)
4. Then call `get_visual_diff_report`

**Call**:
```json
{}
```

**Expected result**:
- `total_assertions` (number): `3`
- `passed` (number): count of passing assertions
- `failed` (number): count of failing assertions
- `details` (array): per-assertion results with name, mismatch_percentage, pass/fail

**Notes**: The value of this tool is in aggregation — it should summarize ALL prior `assert_visual_match` calls in the session.

**What to pay attention to**: The number of assertions in the report should exactly match the number of `assert_visual_match` calls. passed + failed = total_assertions. Each detail should contain the screenshot name and result.

---

#### Scenario 5.2 — Report with no prior assertions (edge case)

**Description**: Call `get_visual_diff_report` without any prior `assert_visual_match` calls.

**Call**:
```json
{}
```

**Expected result**: Either an empty report (`total_assertions: 0`) or a message indicating no assertions have been made.

**Notes**: Should not crash or return an error — empty state is valid.

**What to pay attention to**: There should be no error. The report should be empty or zero.

---

#### Scenario 5.3 — Report after session reset / new session

**Description**: Verify that the report only includes assertions from the current session, not previous ones.

**Call**:
```json
{}
```

**Expected result**: Report contains only assertions made since the session started (or since the last reset, if applicable).

**Notes**: This tests session isolation. If the report accumulates across sessions, that's a bug.

**What to pay attention to**: The report should not contain data from previous sessions. If Godot was not restarted, verify whether the aggregator is reset.

---

## Tool 6: `set_visual_baseline`

**Description**: Set or update a visual baseline for future comparisons.

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | `string` | **yes** | — | Baseline name identifier |
| `screenshot_path` | `string` | **yes** | — | Path to the screenshot to use as baseline |

### Test Scenarios

#### Scenario 6.1 — Happy path: set a new baseline

**Description**: Set a baseline from an existing screenshot.

**Prerequisites**: A screenshot must exist (e.g. from `take_screenshot_with_context`).

**Call**:
```json
{
  "name": "main_menu_v1",
  "screenshot_path": "res://screenshots/main_menu.png"
}
```

**Expected result**:
- `success` (boolean): `true`
- `baseline_name` (string): `"main_menu_v1"`
- Possibly `baseline_path` showing where the baseline was stored

**Notes**: After this call, `assert_visual_match` should be able to use `"main_menu_v1"` or the path as a baseline reference.

**What to pay attention to**: Verify that the baseline is actually saved — after set_visual_baseline, call assert_visual_match with this baseline and verify that the comparison works.

---

#### Scenario 6.2 — Update an existing baseline

**Description**: Set a baseline, then overwrite it with a different screenshot.

**Call (first)**:
```json
{
  "name": "login_screen",
  "screenshot_path": "res://screenshots/login_v1.png"
}
```

**Call (overwrite)**:
```json
{
  "name": "login_screen",
  "screenshot_path": "res://screenshots/login_v2.png"
}
```

**Expected result**: Second call succeeds and overwrites the baseline. Subsequent `assert_visual_match` calls against `"login_screen"` should use `login_v2.png`.

**Notes**: Tests that baselines can be updated (versioning).

**What to pay attention to**: After overwriting the baseline, assert_visual_match should compare with the new screenshot. Verify that there is no "baseline already exists" error.

---

#### Scenario 6.3 — Screenshot path does not exist (edge case)

**Description**: Set a baseline referencing a non-existent file.

**Call**:
```json
{
  "name": "broken_baseline",
  "screenshot_path": "res://screenshots/does_not_exist.png"
}
```

**Expected result**: Error — source file not found. The tool should validate that the screenshot exists before setting it as baseline.

**What to pay attention to**: The error should be informative. A "broken" baseline should not be created that would later cause problems with assert_visual_match.

---

#### Scenario 6.4 — Empty name (edge case)

**Description**: Pass an empty string as `name`.

**Call**:
```json
{
  "name": "",
  "screenshot_path": "res://screenshots/main_menu.png"
}
```

**Expected result**: Either validation error or succeeds with empty-name baseline. Determine actual behavior.

**Notes**: Same edge case as Scenario 1.4 — `Name` schema has no `.min(1)`.

**What to pay attention to**: Verify that a baseline with an empty name is not created, which would later be impossible to find or would overwrite other baselines.

---

## Tool 7: `delete_screenshot`

**Description**: Delete a captured screenshot and its context metadata from `user://mcp_visual_tests/`.

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | `string` | **yes** | — | Name of the screenshot to delete (must match a name used with `take_screenshot_with_context`) |

### Test Scenarios

#### Scenario 7.1 — Happy path: delete an existing screenshot

**Description**: Capture a screenshot, then delete it.

**Prerequisites**: Call `take_screenshot_with_context` with `name: "temp_capture"`.

**Call**:
```json
{
  "name": "temp_capture"
}
```

**Expected result**:
- `success` (boolean): `true`
- `name` (string): `"temp_capture"`
- `deleted_files` (array): list of deleted file paths (screenshot PNG and context JSON)
- `message` (string): confirmation message

**Notes**: After deletion, the screenshot file and its context JSON should no longer exist on disk.

**What to pay attention to**: Verify that both `temp_capture.png` and `temp_capture_context.json` are removed. Calling `assert_visual_match` with this name afterward should fail.

---

#### Scenario 7.2 — Delete a non-existent screenshot (edge case)

**Description**: Attempt to delete a screenshot that was never captured.

**Call**:
```json
{
  "name": "never_existed"
}
```

**Expected result**: Error — screenshot not found. The error should clearly indicate that no screenshot with that name exists.

**Notes**: Tests error handling for missing files.

**What to pay attention to**: The error message should contain the screenshot name. No files should be modified.

---

#### Scenario 7.3 — Empty name (edge case)

**Description**: Pass an empty string as `name`.

**Call**:
```json
{
  "name": ""
}
```

**Expected result**: Error — `name is required`.

**What to pay attention to**: The tool should validate the parameter and return a clear error, not attempt to delete a file with an empty name.

---

## Tool 8: `delete_visual_recording`

**Description**: Delete a visual recording session and all its captured frames from `user://mcp_visual_tests/recordings/`.

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `test_name` | `string` | **yes** | — | Name of the recording to delete (must match a `test_name` used with `record_visual_regression`) |

### Test Scenarios

#### Scenario 8.1 — Happy path: delete an existing recording

**Description**: Record frames, then delete the recording.

**Prerequisites**: Call `record_visual_regression` with `test_name: "temp_recording"`, `frames: 3`.

**Call**:
```json
{
  "test_name": "temp_recording"
}
```

**Expected result**:
- `success` (boolean): `true`
- `test_name` (string): `"temp_recording"`
- `deleted_frames` (number): `3`
- `message` (string): confirmation message

**Notes**: After deletion, the entire recording directory should be removed, including all frame PNGs and the manifest JSON.

**What to pay attention to**: Verify that `user://mcp_visual_tests/recordings/temp_recording/` no longer exists. The in-memory `_recordings` dictionary should also be cleared.

---

#### Scenario 8.2 — Delete a non-existent recording (edge case)

**Description**: Attempt to delete a recording that was never created.

**Call**:
```json
{
  "test_name": "nonexistent_recording"
}
```

**Expected result**: Error — recording not found.

**What to pay attention to**: The error should clearly indicate the missing recording name.

---

#### Scenario 8.3 — Empty test_name (edge case)

**Description**: Pass an empty string as `test_name`.

**Call**:
```json
{
  "test_name": ""
}
```

**Expected result**: Error — `test_name is required`.

---

## Tool 9: `clear_visual_diff_report`

**Description**: Clear all accumulated visual test results (assertions) and in-memory recordings. Resets the session state for `get_visual_diff_report`.

### Parameters

None. This tool takes no parameters.

### Test Scenarios

#### Scenario 9.1 — Happy path: clear after multiple assertions

**Description**: Perform several `assert_visual_match` calls, then clear the report.

**Prerequisites**:
1. Take 2 screenshots and set baselines
2. Call `assert_visual_match` for each
3. Then call `clear_visual_diff_report`

**Call**:
```json
{}
```

**Expected result**:
- `success` (boolean): `true`
- `cleared_assertions` (number): `2`
- `cleared_recordings` (number): count of in-memory recordings (may be `0` if none were recorded)
- `message` (string): confirmation with counts

**Notes**: After clearing, `get_visual_diff_report` should return an empty report (`total_assertions: 0`).

**What to pay attention to**: Verify that `get_visual_diff_report` returns zero assertions after clearing. The `_test_results` array and `_recordings` dictionary should be empty.

---

#### Scenario 9.2 — Clear with no prior assertions (edge case)

**Description**: Call `clear_visual_diff_report` without any prior assertions or recordings.

**Call**:
```json
{}
```

**Expected result**:
- `success` (boolean): `true`
- `cleared_assertions` (number): `0`
- `cleared_recordings` (number): `0`

**Notes**: Should not crash or return an error — clearing an empty state is valid.

**What to pay attention to**: No error should be returned. The counts should be zero.

---

#### Scenario 9.3 — Verify report resets correctly

**Description**: Perform assertions, clear, then perform new assertions and check the report.

**Call**:
```json
{}
```

**Steps**:
1. Assert 2 screenshots (both pass)
2. Call `clear_visual_diff_report`
3. Assert 1 new screenshot (fails)
4. Call `get_visual_diff_report`

**Expected result**: Report should show only the 1 new assertion (failed), not the 2 old ones.

**What to pay attention to**: The report should not contain stale data from before the clear.

---

## Tool 10: `list_visual_baselines`

**Description**: List all saved visual baseline screenshots in `user://mcp_visual_tests/baselines/`.

### Parameters

None. This tool takes no parameters.

### Test Scenarios

#### Scenario 10.1 — Happy path: list after setting baselines

**Description**: Set 2 baselines, then list them.

**Prerequisites**:
1. Take 2 screenshots
2. Call `set_visual_baseline` for each

**Call**:
```json
{}
```

**Expected result**:
- `baselines` (array): list of baseline objects, each with `name`, `path`, `file_size`
- `count` (number): `2`
- `baselines_dir` (string): path to the baselines directory

**Notes**: Each baseline entry should have the name (without extension), the virtual path, and the file size in bytes.

**What to pay attention to**: The count should match the number of `set_visual_baseline` calls. The `name` field should be the filename without `.png`.

---

#### Scenario 10.2 — List with no baselines (edge case)

**Description**: Call `list_visual_baselines` when no baselines have been set.

**Call**:
```json
{}
```

**Expected result**:
- `baselines` (array): empty array `[]`
- `count` (number): `0`
- `baselines_dir` (string): path to the baselines directory

**Notes**: Should not crash or return an error — empty state is valid.

**What to pay attention to**: The result should contain an empty array, not null. No error should be returned.

---

#### Scenario 10.3 — Verify baselines are listed after overwrite

**Description**: Set a baseline, overwrite it, then list.

**Call**:
```json
{}
```

**Steps**:
1. Set baseline `"hero"` from screenshot A
2. Set baseline `"hero"` from screenshot B (overwrite)
3. Call `list_visual_baselines`

**Expected result**: Only one entry for `"hero"` — the overwritten version.

**What to pay attention to**: No duplicate entries. The count should be `1`, not `2`.

---

## Recommended Test Execution Order

Some tools depend on the state created by others. The recommended sequence:

```
1. take_screenshot_with_context  →  creates screenshot files
2. set_visual_baseline           →  uses screenshot files as baselines
3. list_visual_baselines         →  verify baselines were saved
4. assert_visual_match           →  compares screenshots against baselines
5. compare_screenshots           →  direct file-to-file comparison (independent)
6. record_visual_regression      →  captures frames over time (independent)
7. get_visual_diff_report        →  aggregates results from step 4
8. clear_visual_diff_report      →  resets session state
9. delete_screenshot             →  cleanup screenshots
10. delete_visual_recording      →  cleanup recordings
```

### Full Integration Flow

```json
// Step 1: Capture screenshots
{ "tool": "take_screenshot_with_context", "args": { "name": "menu", "include_nodes": ["MenuRoot"], "include_props": true } }

// Step 2: Set baselines
{ "tool": "set_visual_baseline", "args": { "name": "menu", "screenshot_path": "res://screenshots/menu.png" } }

// Step 3: List baselines to verify
{ "tool": "list_visual_baselines", "args": {} }

// Step 4: Make changes to the scene, then re-capture
{ "tool": "take_screenshot_with_context", "args": { "name": "menu_after_changes" } }

// Step 5: Assert match
{ "tool": "assert_visual_match", "args": { "name": "menu_after_changes", "baseline": "res://screenshots/menu.png", "threshold": 0.02 } }

// Step 6: Get aggregated report
{ "tool": "get_visual_diff_report", "args": {} }

// Step 7: Record frames over time
{ "tool": "record_visual_regression", "args": { "test_name": "menu_animation", "frames": 5, "interval": 0.5 } }

// Step 8: Clear the report for a new test cycle
{ "tool": "clear_visual_diff_report", "args": {} }

// Step 9: Cleanup screenshots and recordings
{ "tool": "delete_screenshot", "args": { "name": "menu" } }
{ "tool": "delete_screenshot", "args": { "name": "menu_after_changes" } }
{ "tool": "delete_visual_recording", "args": { "test_name": "menu_animation" } }
```

---

## Error Handling Matrix

| Scenario | Expected behavior |
|---|---|
| Missing required param (`name`, `baseline`, etc.) | Zod validation error before call reaches Godot |
| Non-existent file path | Godot-side error, returned as `isError` result |
| Empty string for `name` | Schema allows it; behavior depends on Godot |
| `threshold` outside `0–1` | Zod validation error (`.min(0).max(1)`) |
| `frames` outside `1–100` | Zod validation error (`.int().min(1).max(100)`) |
| `interval` outside `0.1–10` | Zod validation error (`.min(0.1).max(10)`) |
| Godot not connected | `callGodot` returns connection error |
| Game not running (for screenshot tools) | Godot-side error about viewport unavailable |
