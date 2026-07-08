# Prerequisites for Build Configuration Test Plan

> **Source plan:** `server/src/test_plans/build_config_test_plan.md`
> **Tools covered:** `get_build_settings`, `set_build_configuration`, `set_scripting_backend`, `set_export_filter`, `set_custom_features`, `set_debug_options`, `validate_build_settings`, `get_build_command`
> **Generated:** 2026-07-08

---

## Required Project State

- A Godot 4.x project must exist, be open in the Godot editor, and have the MCP plugin active and connected (WebSocket link established between server and Godot editor).
- The project must have default build configuration settings (a freshly created project with no build config mutations applied). Any project template (`empty`, `2D`, `3D`, `UI`) works since these tools operate on project-level settings, not scene content.
- The `mcp_runtime.gd` autoload must be registered in `project.godot` (the plugin registers this automatically when activated). Required for runtime tools but not strictly needed for build config tools — listed here for completeness since the plan references the runtime autoload.

## Required Scenes

No specific scene hierarchy is required. Build configuration tools operate on project-level settings (`project.godot`) and do not interact with scene nodes. The default empty scene (or any scene open in the editor) is sufficient.

However, to fully validate state persistence across tool calls, it is recommended that:
- At least one scene exists at `res://scenes/main.tscn` (or any path) and is set as the project's main scene via `godot_set_main_scene`. This ensures the editor is in a fully initialized state with a main scene configured — which some Godot build operations reference internally.

## Required Resources

No specific `.tres`/`.res` files, textures, materials, shaders, or audio files are required. Build configuration tools do not read or create resource files.

## Required Editor/Game State

- **Editor must be in Edit mode** (not in Play mode). No tools in this module require the game to be running.
- **MCP plugin must be connected** — all tools call `callGodot(bridge, ...)` which routes through the WebSocket connection. If the plugin is not connected, every tool returns `isError: true` with a connection error.
- **No specific editor layout**, tool selection, or breakpoints required.
- **No undo/redo state requirements** — build config tools mutate project settings which Godot may or may not track via undo. Tests should not depend on undo state.
- **Sequential test execution only** — tools in this module are mutating (they change project settings). Concurrent or parallel test execution against the same project will cause race conditions on shared project state.

## Required Settings/Config

All settings below exist with Godot's factory defaults on a fresh project. They are listed here so the tester can verify the baseline state before running tests and restore it after.

| Setting Key | Default Value | Affected Tool(s) | Notes |
|---|---|---|---|
| Build configuration preset | `debug` | `set_build_configuration`, `get_build_settings` | One of `debug`, `release`, `development` |
| Scripting backend | `gdscript` (GDScript) | `set_scripting_backend`, `get_build_settings` | One of `gdscript`, `csharp` |
| Export filter mode | `all_resources` | `set_export_filter`, `get_build_settings` | One of `all_resources`, `selected_resources` |
| Custom feature tags | `[]` (empty) | `set_custom_features`, `get_build_settings` | Array of string tags; empty by default |
| Debug build flag | Depends on preset | `set_debug_options`, `get_build_settings` | Boolean; typically `true` for `debug` preset |
| Release debug flag | Depends on preset | `set_debug_options`, `get_build_settings` | Boolean; typically `false` for `debug` preset |
| Optimize flag | Depends on preset | `set_debug_options`, `get_build_settings` | Boolean; typically `false` for `debug` preset |

### Export Presets (Strongly Recommended for `get_build_command`)

The `get_build_command` tool generates CLI export commands based on configured export presets. Without presets, the Godot bridge may return an error or an incomplete command string instead of a valid build command.

For **Scenarios 1–6 and 12** of `get_build_command` to return meaningful results, the project should have export presets configured for these platforms:

| Platform | Godot Export Preset Name | Required by Scenarios |
|---|---|---|
| `windows` | `Windows Desktop` | Scenario 1, 13 (CT1 step 8) |
| `linux` | `Linux/X11` | Scenario 2 |
| `web` | `Web` | Scenario 3 |
| `android` | `Android` | Scenario 4 |
| `macos` | `macOS` | Scenario 5 |
| `ios` | `iOS` | Scenario 6 |

**Scenario 12** specifically tests `"Windows Desktop"` (the display name with a space), which requires the Windows Desktop export preset to exist.

**Scenario 11** tests an unrecognized platform (`"freebsd"`) — no preset is needed for this; the bridge should gracefully error or return a best-effort result.

> **Note:** If export presets cannot be created (e.g., missing export templates), the tests should still run. However, `get_build_command` may return bridge errors for those platforms. The test plan notes this explicitly: *"The tool should still return a command string even if prerequisites are missing"* — so errors for missing presets are acceptable but should be distinguished from MCP-tool-level failures.

### Optional: Mono/.NET SDK

For `set_scripting_backend` **Scenario 2** (setting backend to `csharp`):
- The MCP tool itself should succeed regardless of Mono/.NET SDK presence (it only sets a project setting).
- However, if you want to verify that the C# backend is fully functional (compilation succeeds), a Mono or .NET SDK compatible with the installed Godot version must be available on the system.
- This is **NOT a hard prerequisite** — the test plan explicitly states: *"The tool itself should not error — it only sets the project setting."*

## Setup Script (optional)

The following GDScript can be executed via `godot_execute_editor_script` to create export presets for the commonly tested platforms. Run this once before executing the `get_build_command` scenarios if export presets do not already exist.

```gdscript
# Setup: Create export presets for build command tests
# Run via: godot_execute_editor_script with this code

var config = ConfigFile.new()
var err = config.load("res://export_presets.cfg")
if err != OK:
	# Create new config if none exists
	config = ConfigFile.new()

var section_count = 0

func ensure_preset(preset_name, platform_name, binary_format, exe_suffix):
	var section = "preset." + str(section_count)
	if not config.has_section(section):
		config.set_value(section, "name", preset_name)
		config.set_value(section, "platform", platform_name)
		config.set_value(section, "runnable", true)
		config.set_value(section, "dedicated_server", false)
		config.set_value(section, "custom_features", "")
		config.set_value(section, "export_filter", "all_resources")
		config.set_value(section, "include_filter", "")
		config.set_value(section, "exclude_filter", "")
		config.set_value(section, "export_path", "./build/" + platform_name + "/" + preset_name + exe_suffix)
		config.set_value(section, "encrypt_pck", false)
		config.set_value(section, "encrypt_directory", false)
		config.set_value(section, "script_encryption_key", "")
		section_count += 1

# Clear existing presets
for key in config.get_sections():
	if key.begins_with("preset."):
		config.erase_section(key)

section_count = 0

# Create presets for all platforms tested by get_build_command
ensure_preset("Windows Desktop", "Windows Desktop", 0, ".exe")
ensure_preset("Linux/X11", "Linux/X11", 0, ".x86_64")
ensure_preset("Web", "Web", 0, ".html")
ensure_preset("Android", "Android", 0, ".apk")
ensure_preset("macOS", "macOS", 0, ".zip")
ensure_preset("iOS", "iOS", 0, ".ipa")

config.set_value("preset." + str(section_count - 1), "count", section_count)
config.save("res://export_presets.cfg")
print("[Build Config Test Setup] Created " + str(section_count) + " export presets.")
```

> **Warning:** This setup script **clears existing export presets** before creating the test ones. If the project has production export presets, back up `export_presets.cfg` first or create the presets manually through Godot's **Project → Export** dialog.

### Alternative: Manual Export Preset Creation

Instead of the script, you can create presets manually in the Godot editor:
1. Open **Project → Export...**
2. Click **Add...** and select each platform listed in the table above
3. Accept default settings — only the preset name and platform matter for `get_build_command` tests
