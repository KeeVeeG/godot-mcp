# Prerequisites for Export Test Plan

**Source plan:** `server/src/test_plans/export_test_plan.md`
**Generated:** 2026-07-08
**Source tool file:** `server/src/tools/export.ts`
**Source Godot commands:** `test_project/addons/godot_mcp/commands/export_commands.gd`

---

## Required Project State

- **Godot 4.x project** (tested with 4.7) — any project type (2D is sufficient). The existing `test_project/` directory is the canonical test project.
- **Godot MCP addon** installed and active at `addons/godot_mcp/` (required for all 7 tools)
- **MCP server running and connected** — the Node.js server (`server/dist/index.js`) must have an active WebSocket connection to the Godot editor plugin. All 76 scenarios require this.
- **`res://export_presets.cfg`** must be writable. This file is the central data store for all 7 export tools.
  - The existing `test_project/export_presets.cfg` already contains one preset: `"Windows Desktop"` at index 0.
  - Tests that create/delete presets will mutate this file. **Back up the file before running the test suite.**
  - After all tests complete, restore the original `export_presets.cfg` (or re-run the setup script).
- **Writable filesystem paths** for `export_project` output path tests:
  - `C:/Builds/MyGame/` (Scenario 6: `output_path="C:/Builds/MyGame/export"`)
  - `C:/Builds/MyGame/debug_export` (Scenario 7: combined test)
  - `C:/Builds/My Game (v1.0)/` (Scenario 17: special characters)
  - On non-Windows systems, equivalent paths must exist and be writable.
  - **Note:** The actual `export_project` tool builds a godot CLI command string — it does NOT write files to disk. The output_path tests primarily validate parameter round-tripping, not actual filesystem writes.

---

## Required Scenes

### 1. Main scene (`res://_verify_scene.tscn`)

The existing test project already has a main scene configured in `project.godot`:
```
application/run/main_scene="res://_verify_scene.tscn"
```

This scene is used by `validate_export` (all scenarios) which checks that:
- The main scene path is set in project settings
- The main scene file exists on disk

**For `validate_export` Scenario 2** (validate after deleting a referenced resource):
- The scene `res://_verify_scene.tscn` must have at least one referenced resource (e.g., a script, a texture, or an instanced sub-scene) that can be temporarily deleted to create a broken reference.
- Alternative: create a new scene that references a temporary resource, set it as main scene, then delete the resource before validating.

---

## Required Resources

### Files

| Path | Purpose | Notes |
|------|---------|-------|
| `res://export_presets.cfg` | Central config file read/written by all 7 export tools | Must exist before tests run. The existing file has one preset: `"Windows Desktop"` at index 0 with `runnable=true`. |
| `res://_verify_scene.tscn` | Main scene referenced in `project.godot` | Must exist on disk. Used by `validate_export` to check main scene availability. |
| `res://project.godot` | Project configuration | Must have `application/config/name` set (currently `"TestProject"`) and `application/run/main_scene` set (currently `"res://_verify_scene.tscn"`). Used by `get_export_info` and `validate_export`. |

### Directories

No specific directories beyond the project root are needed. The `export_project` tool does not actually write files — it builds and returns a CLI command string.

### Other Resources

- **No specific textures, materials, shaders, audio files, or .tres/.res files** are needed for the 7 export tools. All tools operate on `export_presets.cfg` and project settings.
- For `validate_export` Scenario 2 (broken reference test), a temporary resource file (any `.gd` script or `.tscn` scene) must be created and referenced, then deleted. This is a dynamic prerequisite — create it as part of the test scenario itself, not before the suite.

---

## Required Editor/Game State

| State | Required By | Notes |
|-------|-------------|-------|
| **Godot editor open and connected to MCP server** | All 76 scenarios | The WebSocket bridge must be active. All tools forward requests to the Godot editor plugin. |
| **Project loaded in editor** | All scenarios | The `test_project/` must be the active project. `export_presets.cfg` is read from `res://` which resolves to the project root. |
| **No specific scene must be open** | — | None of the export tools interact with the scene tree. Any scene (or no scene) can be open. |
| **Play mode irrelevant** | — | All 7 export tools work exclusively with project configuration files. Game can be running or stopped — it makes no difference. |
| **No specific editor layout or tool selection** | — | Export tools don't depend on editor UI state. |
| **No breakpoints needed** | — | No debugging scenarios for export tools. |

---

## Required Settings/Config

### Project Settings (`project.godot`)

| Setting Key | Current Value in test_project | Required By | Notes |
|-------------|-------------------------------|-------------|-------|
| `application/config/name` | `"TestProject"` | `get_export_info` (all), `validate_export` (all) | Must be non-empty. `validate_export` issues a warning if empty. |
| `application/config/version` | `"1.0.0"` | `get_export_info` (all) | Any value is fine. |
| `application/run/main_scene` | `"res://_verify_scene.tscn"` | `validate_export` (all) | Must point to an existing scene file. `validate_export` issues an error if the file doesn't exist. |
| `display/window/size/viewport_width` | `1920` | `get_export_info` (all) | Any integer value. |
| `display/window/size/viewport_height` | `1080` | `get_export_info` (all) | Any integer value. |
| `rendering/renderer/rendering_method` | *(set in project)* | `get_export_info` (all) | Any value. |

### Export Presets (`export_presets.cfg`)

The existing `test_project/export_presets.cfg` contains:

```ini
[preset.0]
name="Windows Desktop"
platform="Windows Desktop"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.0.options]
custom_template/debug=""
custom_template/release=""
debug/export_console_wrapper=1
binary_format/embed_pck=false
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
```

This single preset is sufficient for all `list_export_presets`, `export_project`, and `get_export_info` scenarios that reference `"Windows Desktop"`. Scenarios that need additional presets (e.g., cross-tool Scenario II with 5 platforms) will create them at runtime via `create_export_preset`.

### Autoloads

- No specific autoloads are required for export tools. The `mcp_runtime.gd` autoload (configured in test_project as `*res://addons/godot_mcp/services/mcp_runtime.gd`) is irrelevant — export tools only need the editor plugin, not the runtime autoload.

### Input Actions / Collision Layers

- None needed. Export tools don't interact with input or physics.

### External State

- No addons beyond `godot_mcp` itself are required.
- No git repository initialization needed.
- No external packages or dependencies.
- No platform SDKs needed (Android SDK, Xcode, etc.) — the MCP tools don't invoke actual exports; they build CLI command strings.

---

## Scenario-Specific Prerequisites Matrix

Each scenario below lists ONLY the prerequisites beyond the baseline (Godot project + MCP server connected).

### list_export_presets

| Scenario | Additional Prerequisites |
|----------|------------------------|
| S1 (fresh project) | `export_presets.cfg` exists (may be empty or contain defaults). The existing test_project has one preset. |
| S2 (after create) | **Must run after** `create_export_preset` succeeds. The newly created preset must appear in the list. |
| S3 (extra params) | Nothing beyond baseline. |
| S4 (null/undefined args) | Nothing beyond baseline. |

### export_project

| Scenario | Additional Prerequisites |
|----------|------------------------|
| S1 (defaults) | Preset `"Windows Desktop"` must exist in `export_presets.cfg`. ✅ Already present. |
| S2 (debug=true) | Same preset. |
| S3 (debug=false explicit) | Same preset. |
| S4 (pack_only=true) | Same preset. |
| S5 (pack_only=false explicit) | Same preset. |
| S6 (custom output_path) | Same preset + writable path `C:/Builds/MyGame/`. |
| S7 (all params) | Same preset + writable path `C:/Builds/MyGame/debug_export`. |
| S8 (missing preset) | Nothing beyond baseline. Zod rejects before Godot. |
| S9 (missing preset + other params) | Nothing beyond baseline. Zod rejects before Godot. |
| S10 (nonexistent preset) | `export_presets.cfg` must exist. No preset named `"NonExistentPlatform"` must exist. ✅ Satisfied. |
| S11 (empty string preset) | `export_presets.cfg` must exist. Godot handler rejects empty name. ✅ |
| S12 (preset as number) | Nothing beyond baseline. Zod rejects. |
| S13 (debug as string) | Nothing beyond baseline. Zod rejects. |
| S14 (pack_only as number) | Nothing beyond baseline. Zod rejects. |
| S15 (output_path as bool) | Nothing beyond baseline. Zod rejects. |
| S16 (empty output_path) | Preset `"Windows Desktop"` must exist. Godot handler receives empty string. |
| S17 (special chars in path) | Preset `"Windows Desktop"` must exist. |
| S18 (debug + pack_only both true) | Preset `"Windows Desktop"` must exist. |
| S19 (extra unknown params) | Preset `"Windows Desktop"` must exist. |
| S20 (very long preset name) | `export_presets.cfg` must exist. No preset with a 5000-char name should exist. |

### get_export_info

| Scenario | Additional Prerequisites |
|----------|------------------------|
| S1 (fresh project) | `export_presets.cfg` must exist (tool checks for it). Project settings must have `application/config/name` and `application/run/main_scene` set. ✅ |
| S2 (after creating preset) | **Must run after** `create_export_preset`. The `preset_count` in response should reflect the new preset. |
| S3 (extra params) | Nothing beyond baseline. |

### validate_export

| Scenario | Additional Prerequisites |
|----------|------------------------|
| S1 (clean project) | `export_presets.cfg` must exist. Main scene must exist at configured path. App name must be set. ✅ |
| S2 (broken reference) | **Setup step required:** Create a resource (e.g., `res://temp_ref.gd`), reference it from a scene, set that scene as main, then delete `temp_ref.gd`. Validate should report the missing file. |
| S3 (after creating preset) | **Must run after** `create_export_preset`. Validate should run without new errors. |
| S4 (extra params) | Nothing beyond baseline. Zod strips extra params. |
| S5 (null/undefined args) | Nothing beyond baseline. |

### get_export_templates

| Scenario | Additional Prerequisites |
|----------|------------------------|
| S1 (templates installed) | `export_presets.cfg` must exist with at least one preset. ✅ Has one. Tool reads presets from config file (not actual Godot export templates). |
| S2 (no templates) | `export_presets.cfg` may be missing. In that case, tool returns "No export_presets.cfg found". |
| S3 (extra params) | Nothing beyond baseline. |

### create_export_preset

| Scenario | Additional Prerequisites |
|----------|------------------------|
| S1 (Windows Desktop) | `export_presets.cfg` must be writable. No preset named `"Windows Desktop"` must exist (the existing preset IS named "Windows Desktop" — this will trigger the duplicate error unless deleted first). **Either:** delete the existing preset first, **or:** use a different name. |
| S2 (Linux) | Same writability requirement. |
| S3 (macOS) | Same writability requirement. |
| S4 (Android) | Same writability requirement. |
| S5 (iOS) | Same writability requirement. |
| S6 (Web) | Same writability requirement. |
| S7 (custom name) | Same writability requirement. |
| S8 (missing name) | Nothing beyond baseline. Zod rejects. |
| S9 (missing platform) | Nothing beyond baseline. Zod rejects. |
| S10 (both missing) | Nothing beyond baseline. Zod rejects. |
| S11 (unknown platform) | `export_presets.cfg` must be writable. Godot handler accepts any platform string; the tool doesn't validate platform against known values. |
| S12 (empty name) | `export_presets.cfg` must be writable. Godot handler rejects empty name with error. |
| S13 (empty platform) | `export_presets.cfg` must be writable. Godot handler rejects empty platform. |
| S14 (duplicate name) | **Must run S1 first** to create a preset, then run identical call again. Second call should get "already exists" error. |
| S15 (name as number) | Nothing beyond baseline. Zod rejects. |
| S16 (platform as bool) | Nothing beyond baseline. Zod rejects. |
| S17 (whitespace in platform) | `export_presets.cfg` must be writable. |
| S18 (special chars in name) | `export_presets.cfg` must be writable. |
| S19 (very long name) | `export_presets.cfg` must be writable. |
| S20 (extra unknown params) | `export_presets.cfg` must be writable. |

### delete_export_preset

| Scenario | Additional Prerequisites |
|----------|------------------------|
| S1 (delete existing) | A preset named `"Windows Desktop"` must exist. ✅ Already present. After delete, `export_presets.cfg` must be restored or the preset recreated for subsequent scenarios. |
| S2 (delete nonexistent) | No preset named `"NonExistentPreset"` must exist. ✅ Satisfied. |
| S3 (delete last preset) | **Must run after** `create_export_preset` creates a single preset, and all other presets have been removed. `export_presets.cfg` with exactly one preset. |
| S4 (delete custom-named) | **Must run after** `create_export_preset` with custom name like `"My Custom Build"`. |
| S5 (delete twice) | A preset must exist. First delete succeeds, second fails. |
| S6 (missing name) | Nothing beyond baseline. Zod rejects. |
| S7 (empty name) | `export_presets.cfg` must exist. Godot handler won't find preset with empty name. |
| S8 (name as number) | Nothing beyond baseline. Zod rejects. |
| S9 (name as bool) | Nothing beyond baseline. Zod rejects. |
| S10 (path traversal) | `export_presets.cfg` must exist. |
| S11 (special chars) | `export_presets.cfg` must exist. |
| S12 (extra params) | A preset named `"Windows Desktop"` must exist. |

### Cross-Tool Integration Scenarios

| Scenario | Additional Prerequisites |
|----------|------------------------|
| I (full lifecycle) | Clean `export_presets.cfg` state. Each step builds on the previous. Start by reading initial presets, create "TestPreset", verify, export, validate, delete, verify deleted. |
| II (all platforms) | Clean `export_presets.cfg` state. Create 5 presets sequentially: Win, Lin, Mac, Droid, Web. All 5 must have unique names. |
| III (validation cycle) | Clean `export_presets.cfg` and project in valid state. Create "CyclePreset", validate, attempt export, validate again, cleanup. |
| IV (duplicate detection) | Clean state. Create "DuplicateTest", then attempt duplicate with same name (same platform and different platform). |
| V (export without templates) | Check existing templates via `get_export_templates`, create "NoTemplateTest" for Web platform, attempt pack export, cleanup. |

---

## Important Implementation Notes

1. **`export_project` does NOT perform actual exports.** The Godot-side handler (`export_commands.gd`) builds a `godot --headless --export-release ...` CLI command string and returns it. It does not invoke the export. This means:
   - No export templates actually need to be installed for any `export_project` test to pass.
   - No files are written to `output_path` — the path is just included in the command string.
   - The "export may take several seconds" note in the test plan does not apply — it's instantaneous.

2. **`get_export_templates` reads presets, not actual templates.** Despite its name, the implementation reads `export_presets.cfg` entries, not Godot's installed export templates. The test plan's Scenario 2 about "fresh installation with no templates" maps to "no `export_presets.cfg` file."

3. **`validate_export` checks three things:** (a) `export_presets.cfg` exists and is parseable, (b) main scene is set and file exists, (c) application name is set. It does NOT check for missing resources within scenes (despite the tool description saying so). Scenario 2 (broken reference) tests what the tool description promises but the implementation may not deliver — document the actual behavior.

4. **The existing `export_presets.cfg` already has a preset named `"Windows Desktop"`.** This is both helpful (for `export_project` scenarios) and problematic (for `create_export_preset` Scenario 1, which will fail with "already exists"). Either:
   - Delete the existing preset before running the test suite, then recreate it at the end.
   - Rename the existing preset to a different name during test setup.
   - Modify `create_export_preset` Scenario 1 to use a different name (e.g., `"Windows Desktop Test"`).

5. **No Zod schema-level platform validation.** The `create_export_preset` tool accepts any string for `platform`. The Godot handler also accepts any string (it writes it to the config file verbatim). Invalid platforms like `"PlayStation 5"` will succeed at both the MCP and Godot handler levels.

---

## Setup Script

This script prepares the test project for all export tool tests. Run it once before the test suite.

```gdscript
# export_setup.gd — Run via execute_editor_script or manually in the Godot editor
# Prepares test_project/ for export test plan execution

extends EditorScript

func _run() -> void:
    var cfg_path := "res://export_presets.cfg"
    var config := ConfigFile.new()

    # 1. Ensure export_presets.cfg exists with exactly one preset: "Windows Desktop"
    #    (If the file exists, verify/restore it. If missing, create it.)
    if FileAccess.file_exists(cfg_path):
        var err := config.load(cfg_path)
        if err != OK:
            printerr("Failed to load %s: %s" % [cfg_path, error_string(err)])
            return

        # Check if "Windows Desktop" preset exists
        var found_windows := false
        var preset_idx := 0
        while config.has_section("preset.%d" % preset_idx):
            var name: String = config.get_value("preset.%d" % preset_idx, "name", "")
            if name == "Windows Desktop":
                found_windows = true
                break
            preset_idx += 1

        if not found_windows:
            # Add the standard Windows Desktop preset
            var next_idx := 0
            while config.has_section("preset.%d" % next_idx):
                next_idx += 1
            var section := "preset.%d" % next_idx
            config.set_value(section, "name", "Windows Desktop")
            config.set_value(section, "platform", "Windows Desktop")
            config.set_value(section, "runnable", true)
            config.set_value(section, "export_path", "build/")
            config.set_value(section, "custom_features", "")
            config.set_value(section, "include_filter", "")
            config.set_value(section, "exclude_filter", "")
            config.set_value(section, "export_filter", "all_resources")
            config.set_value(section, "dedicated_server", false)
            config.set_value(section, "encrypt_pck", false)
            config.set_value(section, "encrypt_directory", false)
            var opts := "%s.options" % section
            config.set_value(opts, "custom_template/debug", "")
            config.set_value(opts, "custom_template/release", "")
            config.set_value(opts, "debug/export_console_wrapper", 1)
            config.set_value(opts, "binary_format/embed_pck", false)
            config.set_value(opts, "texture_format/s3tc_bptc", true)
            config.set_value(opts, "texture_format/etc2_astc", false)
    else:
        # Create a fresh export_presets.cfg
        config.set_value("preset.0", "name", "Windows Desktop")
        config.set_value("preset.0", "platform", "Windows Desktop")
        config.set_value("preset.0", "runnable", true)
        config.set_value("preset.0", "export_path", "build/")
        config.set_value("preset.0", "custom_features", "")
        config.set_value("preset.0", "include_filter", "")
        config.set_value("preset.0", "exclude_filter", "")
        config.set_value("preset.0", "export_filter", "all_resources")
        config.set_value("preset.0", "dedicated_server", false)
        config.set_value("preset.0", "encrypt_pck", false)
        config.set_value("preset.0", "encrypt_directory", false)
        config.set_value("preset.0.options", "custom_template/debug", "")
        config.set_value("preset.0.options", "custom_template/release", "")
        config.set_value("preset.0.options", "debug/export_console_wrapper", 1)
        config.set_value("preset.0.options", "binary_format/embed_pck", false)
        config.set_value("preset.0.options", "texture_format/s3tc_bptc", true)
        config.set_value("preset.0.options", "texture_format/etc2_astc", false)

    var save_err := config.save(cfg_path)
    if save_err != OK:
        printerr("Failed to save %s: %s" % [cfg_path, error_string(save_err)])
        return

    # 2. Verify main scene exists
    var main_scene := "res://_verify_scene.tscn"
    if not FileAccess.file_exists(main_scene):
        printerr("Main scene missing: %s — create it before running tests" % main_scene)
        return

    # 3. Verify project settings
    var app_name: String = ProjectSettings.get_setting("application/config/name", "")
    if app_name.is_empty():
        ProjectSettings.set_setting("application/config/name", "TestProject")
        ProjectSettings.save()

    var main: String = ProjectSettings.get_setting("application/run/main_scene", "")
    if main != main_scene:
        ProjectSettings.set_setting("application/run/main_scene", main_scene)
        ProjectSettings.save()

    # 4. Create writable output directories (for export_project output_path tests)
    #    Note: These are for the test scenarios that pass custom output paths.
    #    The tool doesn't actually write files, but the paths should be syntactically valid.
    var test_dirs := [
        "C:/Builds/MyGame",
        "C:/Builds/MyGame/debug_export",
    ]
    for dir_path in test_dirs:
        if not DirAccess.dir_exists_absolute(dir_path):
            DirAccess.make_dir_recursive_absolute(dir_path)

    print("Export test prerequisites ready.")
    print("  - export_presets.cfg: OK (1 preset: Windows Desktop)")
    print("  - Main scene: OK (%s)" % main_scene)
    print("  - App name: %s" % app_name if not app_name.is_empty() else "TestProject (set)")
    print("  - Output dirs: %s" % str(test_dirs))

```

---

## Teardown / Restoration

After all tests complete, restore the original project state:

1. **Restore `export_presets.cfg`** — either via `git checkout test_project/export_presets.cfg` or by re-running the setup script.
2. **Verify no leftover presets** — `list_export_presets` should show only the original `"Windows Desktop"` preset.
3. **Clean up test output directories** — remove `C:/Builds/MyGame/` if test artifacts were created there.
4. **Verify main scene is intact** — `res://_verify_scene.tscn` should still exist and be the configured main scene.
