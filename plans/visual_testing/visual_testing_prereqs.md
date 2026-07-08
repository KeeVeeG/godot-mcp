# Prerequisites for Visual Testing Test Plan

**Source:** `server/src/test_plans/visual_testing_test_plan.md`
**Tools covered:** `take_screenshot_with_context`, `compare_screenshots`, `assert_visual_match`, `record_visual_regression`, `get_visual_diff_report`, `set_visual_baseline`
**Generated:** 2026-07-08

---

## Required Project State

- **Godot 4.x project** with the `godot-mcp` addon installed and active (plugin must be connected to the MCP server)
- **MCP runtime autoload** present: `mcp_runtime="res://addons/godot_mcp/services/mcp_runtime.gd"` registered in `project.godot` `[autoload]` section (required for `record_visual_regression` and any gameplay-based tests)
- **Project filesystem structure** with at minimum:
  - `res://screenshots/` directory (create if not present)
  - `res://baselines/` directory (create if not present)
  - `res://scripts/` directory (create if not present)
- **Git not required** for these tests

---

## Required Scenes

### Primary test scene (open and active in the editor)

A scene with the following node hierarchy. This scene is used by `take_screenshot_with_context` scenarios 3, 4, 8 and most `assert_visual_match` scenarios.

```
SceneRoot (Node2D)
├── Player (Node2D)
│   └── Sprite2D (Sprite2D)
├── UI (Control)
│   └── HealthBar (ProgressBar)
└── TitleLabel (Label)
```

**Specific requirements:**
- `Player` must be a `Node2D` with child `Sprite2D` (named exactly `Sprite2D`)
- `UI` must be a `Control` with child `HealthBar` (any Control-derived type, `ProgressBar` recommended)
- `TitleLabel` must be a `Label` (flat child of root, NOT nested under UI)
- The scene should have visible content (not an empty viewport) so screenshots are not blank/black

### Minimal scene (for basic validation tests)

A scene with any root node and no special content — used for `take_screenshot_with_context` scenarios 1, 2, 5, 6, 7 where specific nodes are not required.

---

## Required Resources (Screenshot/Image Files)

### For `compare_screenshots` tool

These files must exist on disk as valid PNG images:

| File path | Required for scenarios | Description |
|-----------|----------------------|-------------|
| `res://screenshots/baseline.png` | S1, S2, S3, S4, S5 | Reference screenshot (any size, any content) |
| `res://screenshots/identical.png` | S1 | Pixel-identical copy of `baseline.png` |
| `res://screenshots/completely_different.png` | S2 | Screenshot with different content (different scene/view) |
| `res://screenshots/similar.png` | S3 | Screenshot similar but not identical to `baseline.png` |
| `res://screenshots/black.png` | S5 | Completely black image (can be any pixel-different image) |
| `res://screenshots/real.png` | S10, S11 | Any valid PNG — used where the *other* file is missing |
| `res://screenshots/1920x1080.png` | S12 | Screenshot at exactly 1920×1080 resolution |
| `res://screenshots/1280x720.png` | S12 | Screenshot at exactly 1280×720 resolution |

**Important:** `res://screenshots/does_not_exist.png` must NOT exist (used in error-path scenarios 10, 11).

### For `set_visual_baseline` tool

These files must exist on disk as valid PNG images:

| File path | Required for scenarios | Description |
|-----------|----------------------|-------------|
| `res://screenshots/main_menu_v1.png` | S1 | Valid PNG screenshot |
| `res://screenshots/main_menu_v2.png` | S2 | Valid PNG screenshot (different from v1, for overwrite test) |
| `res://screenshots/level1.png` | S4 | Valid PNG screenshot |
| `res://baselines/combat_hud.png` | S3 | Valid PNG screenshot at baselines path |
| `res://screenshots/screen_a.png` | S11 (integration) | Valid PNG screenshot for multi-baseline test |
| `res://screenshots/screen_b.png` | S11 (integration) | Valid PNG screenshot for multi-baseline test |

**Important:** `res://screenshots/does_not_exist.png` must NOT exist (used in scenario 7).

### For `set_visual_baseline` scenario 8 (wrong extension)

| File path | Description |
|-----------|-------------|
| `res://scripts/player.gd` | Any valid GDScript file — intentionally NOT an image. Used to test that non-image files are rejected. |

### For `assert_visual_match` tool

These files must exist on disk as valid PNG images:

| File path | Required for scenarios | Description |
|-----------|----------------------|-------------|
| `res://baselines/main_menu_baseline.png` | S1 | Baseline for matching assertion |
| `res://baselines/different_baseline.png` | S2 | Baseline for non-matching assertion (different content from what `main_menu` screenshot captures) |
| `res://baselines/level_select_baseline.png` | S3 | Baseline for default threshold test |
| `res://baselines/exact.png` | S4 | Baseline for pixel-perfect (threshold=0) test |
| `res://baselines/loose.png` | S5 | Baseline for lenient (threshold=0.5) test |
| `res://baselines/img.png` | S10 | Any valid baseline (used where `name` is not previously captured) |
| `main_menu_baseline.png` (in baselines directory root) | S11 | Must exist in the configured baselines directory at its root (not under `res://` subpath) so the bare-filename resolution works |

**Important:** `res://baselines/does_not_exist.png` must NOT exist (used in scenario 12).

### For `get_visual_diff_report` scenarios

| File path | Required for scenarios | Description |
|-----------|----------------------|-------------|
| `res://baselines/test_menu.png` | S2 | Baseline for the passing assertion used in the report test |

---

## Required Editor/Game State

### Editor state

| Requirement | Required by | Notes |
|-------------|-------------|-------|
| **Scene open in editor** | All `take_screenshot_with_context` scenarios | The primary test scene (with Player, UI/HealthBar, TitleLabel) must be the active/open scene |
| **Game NOT running** | Most `take_screenshot_with_context`, `compare_screenshots`, `set_visual_baseline` validation scenarios | These operate on the editor viewport or static files |
| **Game running** | All `record_visual_regression` scenarios (S1–S15) | `record_visual_regression` captures frames from the running game viewport — the game must be playing |
| **Game running** | Integration 2 (`record_visual_regression` + assertions) | Same reason as above |
| **Game running** | `take_screenshot_with_context` when testing game-viewport capture | May be needed depending on whether the tool captures editor vs game viewport |
| **No prior `assert_visual_match` calls** | `get_visual_diff_report` S1 | To test the empty report case |
| **At least 1 prior `assert_visual_match` call** | `get_visual_diff_report` S2 | To test report with data |
| **At least 3 prior `assert_visual_match` calls (mix pass/fail)** | `get_visual_diff_report` S3 | To test multi-result aggregation |
| **All prior assertions failed** | `get_visual_diff_report` S4 | To test all-failure report |
| **Prior `take_screenshot_with_context(name="main_menu")` called** | `assert_visual_match` S1, S2, S11, S12 | The `assert_visual_match` tool searches for a screenshot taken earlier in the session by name |
| **Prior `take_screenshot_with_context(name="level_select")` called** | `assert_visual_match` S3 | Same reason |
| **Prior `take_screenshot_with_context(name="pixel_perfect_test")` called** | `assert_visual_match` S4 | Same reason |
| **Prior `take_screenshot_with_context(name="loose_test")` called** | `assert_visual_match` S5 | Same reason |
| **NO prior `take_screenshot_with_context(name="never_taken")` called** | `assert_visual_match` S10 | To test missing screenshot error |
| **Prior `take_screenshot_with_context(name="test_menu")` called** | `get_visual_diff_report` S2 | Needed for the assertion that feeds the report |
| **Prior `take_screenshot_with_context(name="title_screen_v1")` called** | Integration 1 | First step of full workflow |
| **Prior `take_screenshot_with_context(name="title_screen_v2")` called** | Integration 1 | Third step of full workflow |
| **Prior `take_screenshot_with_context(name="before")` called** | Integration 3 | First step of direct comparison workflow |
| **Prior `take_screenshot_with_context(name="after")` called** | Integration 3 | Second step of direct comparison workflow |

### Configured baselines directory

The `assert_visual_match` tool resolves bare filenames (like `"main_menu_baseline.png"`) against a configured baselines directory. For scenario S11 to pass, the baselines directory must be configured and contain the file `main_menu_baseline.png` at its root.

---

## Required Settings/Config

### Godot project settings

| Setting | Value | Required by | Notes |
|---------|-------|-------------|-------|
| `application/config/name` | Any project name | All scenarios | Must be a valid Godot project |
| `mcp_runtime` autoload | `res://addons/godot_mcp/services/mcp_runtime.gd` | `record_visual_regression`, gameplay tests | Required for runtime MCP operations |

### MCP server settings

| Setting | Value | Required by | Notes |
|---------|-------|-------------|-------|
| WebSocket connection | Active (ports 6505–6514) | All scenarios | Godot editor must be connected to MCP server |
| Plugin status | Active/enabled | All scenarios | `godot_mcp` plugin must be enabled in Project Settings → Plugins |

### MCP tool enable/disable config

All visual testing tools must be enabled in `godot_mcp_config.json` (they are enabled by default, so no action needed unless previously disabled):
- `take_screenshot_with_context`
- `compare_screenshots`
- `assert_visual_match`
- `record_visual_regression`
- `get_visual_diff_report`
- `set_visual_baseline`

### No special input actions, collision layers, or autoloads required

These tests do not depend on custom input mappings, physics configuration, or additional autoloads beyond the MCP runtime.

---

## Required Nodes in Scene (Summary)

| Node path | Type | Required by scenarios | Notes |
|-----------|------|----------------------|-------|
| `Player` | `Node2D` | `take_screenshot_with_context` S3, S4 | Must exist; used for property snapshot test |
| `Player/Sprite2D` | `Sprite2D` | `take_screenshot_with_context` S3 | Child of Player; used for property snapshot test |
| `UI/HealthBar` | `ProgressBar` (or any Control-derived) | `take_screenshot_with_context` S3 | Nested under UI; used for property snapshot test |
| `TitleLabel` | `Label` | Integration 1 | Used in full workflow integration test |
| `NonExistentNode` | *(must NOT exist)* | `take_screenshot_with_context` S8 | Used to test missing-node error handling |

---

## Setup Script

This GDScript can be run via `godot_execute_editor_script` to create the prerequisite scene, directories, and placeholder screenshots. Run this BEFORE executing any test scenarios.

```gdscript
extends EditorScript

func _run() -> void:
	var project_dir := "res://"

	# --- 1. Create directories ---
	var dirs := [
		"res://screenshots",
		"res://baselines",
		"res://scripts"
	]
	for d in dirs:
		var dir := DirAccess.open("res://")
		if not dir.dir_exists(d.replace("res://", "")):
			dir.make_dir(d.replace("res://", ""))

	# --- 2. Create a dummy player.gd script for set_visual_baseline S8 ---
	var script_path := "res://scripts/player.gd"
	if not FileAccess.file_exists(script_path):
		var f := FileAccess.open(script_path, FileAccess.WRITE)
		f.store_string("extends Node2D\n\nfunc _ready() -> void:\n\tpass\n")
		f.close()

	# --- 3. Create the primary test scene ---
	# Build: SceneRoot (Node2D) -> Player (Node2D) -> Sprite2D
	#                               -> UI (Control) -> HealthBar (ProgressBar)
	#                               -> TitleLabel (Label)

	var root := Node2D.new()
	root.name = "SceneRoot"

	var player := Node2D.new()
	player.name = "Player"

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	player.add_child(sprite)
	sprite.owner = player  # will be reassigned after root gets children

	var ui := Control.new()
	ui.name = "UI"

	var health_bar := ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.value = 75.0
	ui.add_child(health_bar)
	health_bar.owner = ui

	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Test Title"

	root.add_child(player)
	root.add_child(ui)
	root.add_child(title_label)

	# Set owners for packed scene serialization
	player.owner = root
	sprite.owner = root
	ui.owner = root
	health_bar.owner = root
	title_label.owner = root

	# --- 4. Pack and save the scene ---
	var packed := PackedScene.new()
	packed.pack(root)
	var scene_save_path := "res://scenes/visual_test_scene.tscn"
	ResourceSaver.save(packed, scene_save_path)

	# --- 5. Open the scene in the editor ---
	EditorInterface.open_scene_from_path(scene_save_path)

	# --- 6. Generate placeholder screenshot files ---
	# We create minimal valid PNGs using Image class.
	# baseline.png (64x64, red)
	_generate_placeholder_png("res://screenshots/baseline.png", Vector2i(64, 64), Color.RED)
	# identical.png (64x64, red — pixel-identical to baseline)
	_generate_placeholder_png("res://screenshots/identical.png", Vector2i(64, 64), Color.RED)
	# completely_different.png (64x64, blue)
	_generate_placeholder_png("res://screenshots/completely_different.png", Vector2i(64, 64), Color.BLUE)
	# similar.png (64x64, slightly different red — same size, different color)
	_generate_placeholder_png("res://screenshots/similar.png", Vector2i(64, 64), Color(0.9, 0.0, 0.0, 1.0))
	# black.png (64x64, black)
	_generate_placeholder_png("res://screenshots/black.png", Vector2i(64, 64), Color.BLACK)
	# real.png (64x64, green)
	_generate_placeholder_png("res://screenshots/real.png", Vector2i(64, 64), Color.GREEN)
	# 1920x1080.png
	_generate_placeholder_png("res://screenshots/1920x1080.png", Vector2i(1920, 1080), Color.RED)
	# 1280x720.png
	_generate_placeholder_png("res://screenshots/1280x720.png", Vector2i(1280, 720), Color.BLUE)

	# Placeholder screenshots for set_visual_baseline scenarios
	_generate_placeholder_png("res://screenshots/main_menu_v1.png", Vector2i(64, 64), Color.RED)
	_generate_placeholder_png("res://screenshots/main_menu_v2.png", Vector2i(64, 64), Color.BLUE)
	_generate_placeholder_png("res://screenshots/level1.png", Vector2i(64, 64), Color.GREEN)
	_generate_placeholder_png("res://screenshots/screen_a.png", Vector2i(64, 64), Color.YELLOW)
	_generate_placeholder_png("res://screenshots/screen_b.png", Vector2i(64, 64), Color.PURPLE)
	_generate_placeholder_png("res://baselines/combat_hud.png", Vector2i(64, 64), Color.ORANGE)

	# Baseline files for assert_visual_match scenarios
	_generate_placeholder_png("res://baselines/main_menu_baseline.png", Vector2i(64, 64), Color.RED)
	_generate_placeholder_png("res://baselines/different_baseline.png", Vector2i(64, 64), Color.BLUE)
	_generate_placeholder_png("res://baselines/level_select_baseline.png", Vector2i(64, 64), Color.GREEN)
	_generate_placeholder_png("res://baselines/exact.png", Vector2i(64, 64), Color.RED)
	_generate_placeholder_png("res://baselines/loose.png", Vector2i(64, 64), Color(0.5, 0.0, 0.0, 1.0))
	_generate_placeholder_png("res://baselines/img.png", Vector2i(64, 64), Color.WHITE)
	_generate_placeholder_png("res://baselines/test_menu.png", Vector2i(64, 64), Color.RED)

	# For S11: bare filename resolution test — create in the baselines directory root
	_generate_placeholder_png("res://baselines/main_menu_baseline.png", Vector2i(64, 64), Color.RED)
	# NOTE: The assert_visual_match S11 scenario uses baseline="main_menu_baseline.png" (bare name)
	# which gets resolved against the baselines directory. Since we already created
	# res://baselines/main_menu_baseline.png, ensure the tool's resolution logic
	# considers res://baselines/ as the baselines directory for bare name lookups.

	# Ensure does_not_exist files are NOT present
	_remove_if_exists("res://screenshots/does_not_exist.png")
	_remove_if_exists("res://baselines/does_not_exist.png")

	print("[Setup] Visual testing prerequisites created successfully.")
	print("[Setup] Scene: ", scene_save_path)
	print("[Setup] Refresh the filesystem if new files don't appear (Project → Reload Current Project)")


# --- Helper: generate a solid-color PNG ---
func _generate_placeholder_png(path: String, size: Vector2i, color: Color) -> void:
	if FileAccess.file_exists(path):
		print("[Setup] Skipping existing file: ", path)
		return

	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var err := img.save_png(path)
	if err == OK:
		print("[Setup] Created: ", path)
	else:
		printerr("[Setup] Failed to create: ", path, " (error: ", err, ")")


# --- Helper: remove a file if it exists ---
func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("[Setup] Removed: ", path)
	else:
		print("[Setup] Already absent: ", path)
```

### Post-setup manual steps

After running the setup script:

1. **Refresh the Godot project** — run **Project → Reload Current Project** to ensure the filesystem picks up new files.
2. **Verify the scene is open** — the script opens it automatically, but verify it appears correctly in the editor.
3. **Verify placeholder screenshots exist** — use `godot_get_filesystem_tree(path="res://screenshots")` and `godot_get_filesystem_tree(path="res://baselines")` to confirm all files were created.
4. **Configure the baselines directory** — if the MCP plugin has a configurable baselines directory setting, ensure it points to `res://baselines/` so that bare filename resolution works for `assert_visual_match` scenario S11.

---

## Test Execution Order Constraints

Some scenarios depend on sequential state. The recommended execution order:

1. **Phase 1 — No-state validation tests** (can run in any order)
   - `take_screenshot_with_context` S5, S6, S7 (empty/invalid name)
   - `compare_screenshots` S6, S7, S8, S9 (missing params, invalid thresholds)
   - `assert_visual_match` S6, S7, S8, S9 (missing params, invalid thresholds)
   - `record_visual_regression` S7–S13 (invalid frames/interval values)
   - `set_visual_baseline` S5, S6, S9, S10 (missing params, empty strings)

2. **Phase 2 — File-based tests** (require placeholder screenshots)
   - `compare_screenshots` S1–S5, S10–S12
   - `set_visual_baseline` S1–S4, S7, S8
   - `set_visual_baseline` S11 (multi-baseline)

3. **Phase 3 — take_screenshot_with_context tests** (require scene with nodes)
   - S1, S2, S3, S4, S8

4. **Phase 4 — assert_visual_match tests** (require prior take_screenshot_with_context calls)
   - First run `take_screenshot_with_context` for each unique name:
     - `name="main_menu"` (for S1, S2, S11, S12)
     - `name="level_select"` (for S3)
     - `name="pixel_perfect_test"` (for S4)
     - `name="loose_test"` (for S5)
     - `name="test_menu"` (for get_visual_diff_report S2)
   - Then run `assert_visual_match` S1–S5, S10–S12

5. **Phase 5 — get_visual_diff_report** (requires prior assertions)
   - Run S1 first (empty report)
   - Then run passing/failing assertions
   - Then run S2, S3, S4, S5, S6

6. **Phase 6 — Game-running tests** (start game first)
   - `record_visual_regression` S1–S6, S14, S15
   - Integration 2

7. **Phase 7 — Integration workflows**
   - Integration 1 (full visual regression workflow)
   - Integration 3 (direct screenshot comparison)
