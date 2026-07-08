# Prerequisites for Platform Export Tools — Test Plan

> Extracted from `platform_export_test_plan.md` (65 scenarios across 6 tools + cross-tool integration)

---

## Required Project State

- **Godot version**: 4.x (tested with 4.7)
- **Project type**: Any (2D or 3D) — no specific scene type required for export tools
- **Plugin active**: `addons/godot_mcp/` must be installed and enabled
- **Runtime autoload**: `mcp_runtime="res://addons/godot_mcp/services/mcp_runtime.gd"` registered in `[autoload]` section of `project.godot` (note: NOT prefixed with `*`)
- **MCP server connected**: Server running and WebSocket bridge established between Godot editor and Node.js MCP server
- **Export templates installed**: Godot export templates for the target Godot version must be installed for scenarios 1–12, 27, and 65 (actual exports). Without templates, `get_platform_export_templates` returns empty and `export_for_platform` will fail.

---

## Required Export Presets

Export presets must exist in the project for the following scenarios. Presets can either be pre-created manually or created during test setup via `create_platform_export_preset`.

### For `export_for_platform` (scenarios 1–12, 17)

| Scenario | Tool param | Required Preset Name | Alternative Setup |
|----------|-----------|---------------------|-------------------|
| 1 | `platform: "windows"` | `Windows Desktop` | `create_platform_export_preset({ platform: "Windows Desktop", name: "Windows Desktop" })` |
| 2 | `platform: "windows", debug: true` | `Windows Desktop` | Same as scenario 1 |
| 3 | `platform: "linux"` | `Linux` | `create_platform_export_preset({ platform: "Linux", name: "Linux" })` |
| 4 | `platform: "linux", debug: true` | `Linux` | Same as scenario 3 |
| 5 | `platform: "macos"` | `macOS` | `create_platform_export_preset({ platform: "macOS", name: "macOS" })` |
| 6 | `platform: "macos", debug: true` | `macOS` | Same as scenario 5 |
| 7 | `platform: "android"` | `Android` | `create_platform_export_preset({ platform: "Android", name: "Android" })` |
| 8 | `platform: "android", debug: true` | `Android` | Same as scenario 7 |
| 9 | `platform: "ios"` | `iOS` | `create_platform_export_preset({ platform: "iOS", name: "iOS" })` |
| 10 | `platform: "ios", debug: true` | `iOS` | Same as scenario 9 |
| 11 | `platform: "web"` | `Web` | `create_platform_export_preset({ platform: "Web", name: "Web" })` |
| 12 | `platform: "web", debug: true` | `Web` | Same as scenario 11 |
| 17 | `platform: "windows", debug: false` | `Windows Desktop` | Same as scenario 1 |

### For `validate_platform_export` (scenarios 18–23)

No export presets strictly required — validation works without presets (returns warnings). However, for **meaningful validation results**, corresponding presets should exist:

| Scenario | Platform param | Suggested Preset |
|----------|---------------|------------------|
| 18 | `"Windows Desktop"` | `Windows Desktop` |
| 19 | `"Linux"` | `Linux` |
| 20 | `"macOS"` | `macOS` |
| 21 | `"Android"` | `Android` |
| 22 | `"iOS"` | `iOS` |
| 23 | `"Web"` | `Web` |

### For `validate_export_for_platform` (scenarios 55–60, 64)

| Scenario | Platform param | Suggested Preset |
|----------|---------------|------------------|
| 55, 64 | `"Windows Desktop"` | `Windows Desktop` |
| 56 | `"Linux"` | `Linux` |
| 57 | `"macOS"` | `macOS` |
| 58 | `"Android"` | `Android` |
| 59 | `"iOS"` | `iOS` |
| 60 | `"Web"` | `Web` |

### For `create_platform_export_preset` duplicate-name test (scenario 39)

- A preset named **`Windows Desktop`** must already exist before the test runs. The test creates another preset with the same name and expects a duplicate-name error.

### For cross-tool scenario 66 (validate all six)

- Export presets for all six platforms (`Windows Desktop`, `Linux`, `macOS`, `Android`, `iOS`, `Web`) should exist for meaningful output. Without them, validation returns warnings rather than passing results.

---

## Required Exported Builds on Disk

For `run_exported_build` scenarios (42–47, 49–50, 53–54), exported executables must exist at the specified paths. Since export paths depend on the preset configuration, these paths are the **expected locations** after a successful export via the corresponding preset.

| Scenario | Required File | Platform | Notes |
|----------|--------------|----------|-------|
| 42, 43, 44, 47, 53 | `C:/builds/my_game.exe` | Windows | Must be a valid executable. Created by exporting with a Windows preset whose output path is `C:/builds/my_game.exe`. |
| 45 | `/home/user/builds/game.x86_64` | Linux | Linux binary. Requires Linux export. |
| 46 | `/Applications/MyGame.app` | macOS | macOS application bundle. Requires macOS export. |
| 49 | `C:/nonexistent/nothing.exe` | — | File must NOT exist (negative test). Ensure this path is absent. |
| 50 | `res://project.godot` | — | No setup needed — uses existing project file (non-executable test). |

---

## Required Scenes

No specific scene hierarchy is required for export tools. A minimal project with a single scene (e.g., `res://main.tscn`) is sufficient. Recommended:

```
res://main.tscn
  └── Node2D (root) — or Node3D, as appropriate
```

The project should at minimum have:
- A main scene set in `project.godot` (`application/run/main_scene`)
- No missing resource references that would cause export validation failures

---

## Required Resources

No specific `.tres`, `.res`, textures, materials, shaders, or audio files are required. Export tools operate at the project/preset level, not on individual resources.

However, for `validate_export_for_platform` to return a clean validation report:
- All scenes referenced by the project should have resolvable resource dependencies
- No broken resource references in any scene file

---

## Required Editor/Game State

| State | Required For | Value |
|-------|-------------|-------|
| Editor running | ALL scenarios | Godot editor open with project loaded |
| MCP plugin connected | ALL scenarios | WebSocket connection active on port 6505–6514 |
| Play mode | Scenarios using `run_exported_build` (42–47) | Play mode can be ON or OFF — `run_exported_build` spawns an external process, independent of editor play state |
| Scene loaded | None | Specific scene not required; any scene can be loaded |
| Tool selected | None | No specific editor tool needed |
| Breakpoints | None | No breakpoints required |
| Editor layout | None | Any layout works |

---

## Required Settings/Config

### Project Settings (`project.godot`)

| Setting Key | Value | Required For |
|-------------|-------|-------------|
| `application/run/main_scene` | `res://main.tscn` (or any valid scene) | All scenarios — project must have a main scene |
| `application/config/name` | Any non-empty string | Export presets use this as default name |

### Godot Editor Settings

| Setting | Value | Required For |
|---------|-------|-------------|
| Export templates | Installed for the current Godot version | Scenarios 1–12, 27, 65 |

### Input Actions

None required.

### Autoloads

| Autoload | Path | Required For |
|----------|------|-------------|
| `mcp_runtime` | `res://addons/godot_mcp/services/mcp_runtime.gd` | Runtime tools (not used by export tools directly, but required for the plugin to function fully) |

### Collision Layers / Physics / Rendering

None required.

### Tool Config (`godot_mcp_config.json`)

| Setting | Value | Required For |
|---------|-------|-------------|
| All export tools enabled | No exclusions for `export_for_platform`, `validate_platform_export`, `get_platform_export_templates`, `create_platform_export_preset`, `run_exported_build`, `validate_export_for_platform` | All scenarios |

If `godot_mcp_config.json` exists in the project root, ensure none of these tools are set to `false`.

---

## Required External State

### Export Templates (Godot Editor)

Export templates for the target Godot version must be downloaded and installed via the Godot Editor. This is a prerequisite of the Godot editor itself, not the MCP plugin.

- **How to check**: `get_platform_export_templates` returns a list of installed templates
- **How to install**: Godot Editor → Editor → Manage Export Templates → Download and Install
- **Minimum required**: Templates for the platforms being tested (at minimum `Windows Desktop` for most scenarios)

### Platform-Specific SDKs (for validation tools)

For `validate_export_for_platform` to pass without SDK-related errors:

| Platform | Required SDK | Notes |
|----------|-------------|-------|
| Android | Android SDK + OpenJDK | Set in Editor Settings → Export → Android |
| iOS | Xcode + Apple Developer account | Only relevant on macOS |
| Web | None (HTML5 is self-contained) | — |
| Windows/Linux/macOS | None (native export) | Templates handle this |

### Filesystem Permissions

- Write access to export output directories (e.g., `C:/builds/`, `/home/user/builds/`, `/Applications/`)
- For `run_exported_build`: ability to execute binaries at the specified paths

---

## Scenario-Specific Prerequisites Summary

| Scenario Range | Tool | Critical Prerequisites |
|----------------|------|----------------------|
| 1–12, 17 | `export_for_platform` | Export template installed, matching export preset exists for the target platform |
| 13–16 | `export_for_platform` (validation) | None — Zod validation only |
| 18–23 | `validate_platform_export` | Godot project exists (presets helpful but not required) |
| 24–26 | `validate_platform_export` (validation) | None |
| 27–28 | `get_platform_export_templates` | Godot editor running with plugin connected |
| 29–38, 40–41 | `create_platform_export_preset` | Godot project exists; for scenario 39, a preset named "Windows Desktop" must already exist |
| 39 | `create_platform_export_preset` (duplicate) | A preset named **`Windows Desktop`** must already exist |
| 42–44, 47, 53–54 | `run_exported_build` | `C:/builds/my_game.exe` must exist |
| 45 | `run_exported_build` (Linux) | `/home/user/builds/game.x86_64` must exist |
| 46 | `run_exported_build` (macOS) | `/Applications/MyGame.app` must exist |
| 48–52 | `run_exported_build` (validation) | None (Zod validation only) |
| 49 | `run_exported_build` (non-existent) | Ensure `C:/nonexistent/nothing.exe` does NOT exist |
| 55–60, 62–63 | `validate_export_for_platform` | Godot project exists (presets helpful) |
| 61 | `validate_export_for_platform` (validation) | None |
| 64 | `validate_export_for_platform` (comparative) | Both tools available; Windows Desktop preset exists |
| 65 | Cross-tool workflow | Windows export template installed; project capable of export |
| 66 | Cross-tool validate-all | All six platform presets created (for meaningful validation) |

---

## Setup Script

```gdscript
# EditorScript — run via godot_execute_editor_script or manually in Godot Script Editor
# Purpose: Create all export presets required by the platform export test plan.
# WARNING: This overwrites any existing presets with matching names.

@tool
extends EditorScript

func _run() -> void:
	var platforms = [
		"Windows Desktop",
		"Linux",
		"macOS",
		"Android",
		"iOS",
		"Web",
	]

	# Remove all existing export presets to start clean
	# Note: Godot 4.0+ API uses EditorExportPlatform
	var config = ConfigFile.new()
	config.load("res://export_presets.cfg")
	# Clear and rewrite
	config.clear()

	for platform_name in platforms:
		# Use Godot's export preset creation via editor interface
		# In GDScript, this requires EditorExportPlatform
		print("Would create preset for: ", platform_name)
		# Actual creation requires using EditorInterface singleton
		# EditorInterface.get_editor_settings() etc.

	print("Preset creation requires manual steps or using create_platform_export_preset tool.")
	print("See setup instructions below.")
```

### Practical Setup Instructions

Since `EditorScript` has limited access to export preset creation APIs, use the MCP tools themselves for setup:

**Phase 1: Create all presets** (via `create_platform_export_preset`)
```
# Run these sequentially:
create_platform_export_preset({ "platform": "Windows Desktop", "name": "Windows Desktop" })
create_platform_export_preset({ "platform": "Linux",          "name": "Linux" })
create_platform_export_preset({ "platform": "macOS",          "name": "macOS" })
create_platform_export_preset({ "platform": "Android",        "name": "Android" })
create_platform_export_preset({ "platform": "iOS",            "name": "iOS" })
create_platform_export_preset({ "platform": "Web",            "name": "Web" })
```

**Phase 2: Verify templates** (via `get_platform_export_templates`)
```
get_platform_export_templates({})
# If empty, install export templates via Godot Editor GUI:
# Editor → Manage Export Templates → Download and Install
```

**Phase 3: Create a test export** (to satisfy `run_exported_build` requirements)
```
# Configure Windows preset with known output path, then export:
create_platform_export_preset({
  "platform": "Windows Desktop",
  "name": "Windows Desktop",
  "settings": { "export_path": "C:/builds/my_game.exe" }
})
export_for_platform({ "platform": "windows", "debug": false })
```

**Phase 4: Verify project validates**
```
validate_export_for_platform({ "platform": "Windows Desktop" })
# Should return clean or warning-only results
```

---

## Notes

1. **Export templates are the #1 blocker**: Without them, `export_for_platform` (scenarios 1–12) and `get_platform_export_templates` (scenario 27) will fail. Templates are installed per-Godot-version via the editor GUI, not programmatically.

2. **Validation-only scenarios (13–16, 24–26, 36–38, 41, 48, 51–52, 61)**: These test Zod schema validation at the MCP server level and do NOT require a running Godot editor. They can be tested independently of the Godot plugin.

3. **Scenario 39 (duplicate preset name)**: This is the only scenario that requires prior state to be dirty. A preset named "Windows Desktop" must already exist for the duplicate-name error to trigger.

4. **`run_exported_build` is platform-dependent**: The paths in scenarios 42–47 assume specific OS environments (Windows for `C:/builds/`, Linux for `/home/user/`, macOS for `/Applications/`). Adjust paths based on the test environment.

5. **Cross-platform testing**: Scenarios 45 (Linux binary) and 46 (macOS app) cannot realistically be tested on a Windows machine without cross-compilation or pre-built binaries.

6. **Android/iOS prerequisites**: Even with export templates and presets, Android requires Android SDK + OpenJDK, and iOS requires macOS + Xcode + Apple Developer account. Validation tools (scenarios 21–22, 58–59) will report missing SDKs.
