# Prerequisites for Platform-Specific Test Plan

> **Source plan:** `server/src/test_plans/platform_specific_test_plan.md`
> **Tools covered:** `get_platform_settings`, `configure_ios`, `configure_android`, `configure_web`, `get_platform_capabilities`, `validate_platform_build`
> **Scope:** These tools operate on project-level configuration (`project.godot` and `export_presets.cfg`). No scenes, nodes, resources, or game-state prerequisites are needed.

---

## Required Project State

- **Godot 4.x project** (tested with 4.7) — a clean, dedicated test project is strongly recommended to avoid polluting real project settings.
- **MCP plugin installed and active** — the `addons/godot_mcp/` directory must be present in the project. The plugin must be enabled in **Project → Project Settings → Plugins**.
- **MCP autoload registered** — `project.godot` must contain `mcp_runtime="res://addons/godot_mcp/services/mcp_runtime.gd"` under `[autoload]`. Some tools (`get_platform_capabilities`, `validate_platform_build`) may query runtime information even in editor context.
- **MCP WebSocket connected** — the Godot editor must be running with the MCP panel showing a connected state. The Node.js server must have bound to a port in the 6505-6514 range and the Godot plugin must have discovered and connected to it.
- **Project must be saved to disk** — `project.godot` must exist at the project root. All `configure_*` tools write to project-level settings files (`project.godot` and/or `export_presets.cfg`), so an unsaved/new project will fail.
- **Writable project directory** — the project directory and its files (`project.godot`, `export_presets.cfg`) must be writable by the Godot process. Platform configuration changes are persisted to disk.
- **Fresh/clean state for reproducibility** — the test plan (Note #13) recommends either:
  - A fresh test project for each test run, OR
  - Resetting platform settings to original values after tests (record baseline with `get_platform_settings` before any `configure_*` calls).

## Required Scenes

**None.** No scenes need to be created or opened. None of the 6 tools under test interact with nodes, scene trees, or `.tscn` files. The editor can have an empty/unsaved scene open.

## Required Resources

**None.** No textures, materials, shaders, audio files, `.tres`/`.res` resources, or any asset files are required.

## Required Editor/Game State

- **Editor must be in Edit mode** (not Play mode). Platform configuration tools modify project settings, which is an editor-mode operation.
- **No specific editor layout required** — the default layout is sufficient.
- **No breakpoints required** — none of the tools involve GDScript debugging.
- **No specific tool selected** — the tools interact with project settings, not the editor viewport.
- **Editor must not be busy** (compiling scripts, loading large scenes, showing modal dialogs). The WebSocket bridge has a default 30s timeout.
- **Asset database must be refreshed** — if the project was just created or files were modified externally, run a `refresh_unity` equivalent (Godot's filesystem rescan) or restart the editor.

## Required Settings/Config

### Godot Project Settings (in `project.godot`)

These exist by default in any Godot project but must be confirmed present:

| Setting Key | Required By | Notes |
|---|---|---|
| `application/config/name` | All tools | Project must have a name (defaults to directory name) |
| `application/config/description` | All tools | Optional but expected by Godot |
| `editor_plugins/enabled` | All tools | Must include `"res://addons/godot_mcp/plugin.cfg"` |

### Export Presets (`export_presets.cfg`)

The `configure_*` tools modify platform-specific export presets. The tool handler behavior regarding pre-existing presets must be determined empirically:

| Platform | Expected Behavior | Fallback If No Preset Exists |
|---|---|---|
| `ios` | `configure_ios` writes to iOS export preset | Handler may auto-create preset, return error, or be a no-op |
| `android` | `configure_android` writes to Android export preset | Handler may auto-create preset, return error, or be a no-op |
| `web` | `configure_web` writes to Web/HTML5 export preset | Handler may auto-create preset, return error, or be a no-op |

**Recommendation:** Before running tests, determine whether the Godot handler auto-creates export presets or requires them to pre-exist. If pre-existence is required, create minimal presets using:

```
godot_create_export_preset({ name: "iOS", platform: "ios" })
godot_create_export_preset({ name: "Android", platform: "android" })
godot_create_export_preset({ name: "HTML5", platform: "web" })
```

Or create them manually in Godot: **Project → Export → Add... → [platform]**

### Export Templates (for `validate_platform_build`)

`validate_platform_build` checks project readiness for building a specific platform. Results vary by installed tooling:

| Platform | What Validation Checks | Typical Result If Missing |
|---|---|---|
| `windows` | Export template, icon | May warn about missing template (not blocking) |
| `linux` | Export template, icon | May warn about missing template |
| `macos` | Export template, icon, code-sign config | May warn about cross-compilation on non-macOS hosts |
| `ios` | Export template, bundle ID, team ID, provisioning | Likely warns about missing template, SDK, or signing config |
| `android` | Export template, SDK path, NDK path, package name, keystore | Likely warns about missing SDK/NDK or templates |
| `web` | Export template, threading headers (COOP/COEP), PWA config | May warn about missing template or server config |

**Note:** Export templates are NOT required to run these tests. `validate_platform_build` returns warnings, not blocking errors. Tests should verify the tool executes successfully and returns a report, regardless of template availability.

### External SDKs (for `validate_platform_build`)

Not required for test execution, but affect validation output:

| Platform | Required SDK | Where to Configure |
|---|---|---|
| `android` | Android SDK + NDK | Godot Editor Settings → Export → Android |
| `ios` | Xcode + Apple Developer account | macOS only; cross-compilation not supported |

### Input Actions

**None.** These tools do not read or write InputMap entries.

### Autoloads

Only `mcp_runtime` (added by the MCP plugin). No additional autoloads required.

### Collision Layers

**None.** These tools do not interact with physics or collision systems.

## Required External State

- **MCP server running** — the Node.js MCP server (`server/dist/index.js` or `npx @keeveeg/godot-mcp`) must be running and listening on a port in 6505-6514.
- **Godot editor running** — with the test project open and the MCP plugin active.
- **WebSocket connection established** — verify by checking the **MCP** panel in Godot's bottom dock shows "Connected".
- **No other Godot instances** — having multiple Godot editors connected to the same MCP server may cause routing ambiguity. Use a single Godot instance for testing.
- **No other MCP server instances** — ensure no stale `node` processes from previous test runs are occupying ports 6505-6514. Kill with `pkill -f "godot-mcp"` (Linux/macOS) or Task Manager (Windows).

---

## Setup Script

```gdscript
# Execute in Godot Editor context (EditorScript) to prepare project for testing.
# This script does NOT create export presets — run it first, then check the MCP
# handler behavior to determine if presets auto-create or must pre-exist.

# Save baseline platform settings for all platforms before any configure_* calls.
# This enables restoration after tests complete.

extends EditorScript

func _run():
    print("=== Platform-Specific Test Prerequisites Check ===")
    print()

    # 1. Verify MCP plugin is active
    var plugin = EditorPlugin.new()  # heuristic check
    var config = ConfigFile.new()
    var err = config.load("res://project.godot")
    if err != OK:
        printerr("ERROR: project.godot not found or unreadable")
        return

    if config.has_section_key("editor_plugins", "enabled"):
        var plugins = config.get_value("editor_plugins", "enabled")
        var mcp_enabled = false
        for p in plugins:
            if "godot_mcp" in str(p):
                mcp_enabled = true
                break
        if mcp_enabled:
            print("[PASS] MCP plugin is enabled")
        else:
            printerr("[FAIL] MCP plugin is NOT enabled — enable in Project Settings → Plugins")
    else:
        printerr("[WARN] No editor_plugins section in project.godot")

    # 2. Verify project has a name
    var project_name = ProjectSettings.get_setting("application/config/name", "")
    if project_name != "":
        print("[PASS] Project name: ", project_name)
    else:
        printerr("[WARN] Project has no name set — will use directory name")

    # 3. Check export presets
    var export_cfg = ConfigFile.new()
    var export_err = export_cfg.load("res://export_presets.cfg")
    if export_err == OK:
        var sections = export_cfg.get_sections()
        print("[PASS] export_presets.cfg found with ", sections.size(), " sections")
        for s in sections:
            print("  Section: ", s)
    else:
        print("[WARN] No export_presets.cfg found — configure_* tools may auto-create presets or fail")

    # 4. Record baseline settings for restoration
    print()
    print("=== Recording Baseline Platform Settings ===")
    print("Use get_platform_settings tool for each platform to capture baseline.")
    print("  get_platform_settings({ platform: 'windows' })")
    print("  get_platform_settings({ platform: 'linux' })")
    print("  get_platform_settings({ platform: 'macos' })")
    print("  get_platform_settings({ platform: 'ios' })")
    print("  get_platform_settings({ platform: 'android' })")
    print("  get_platform_settings({ platform: 'web' })")

    print()
    print("=== Prerequisites Check Complete ===")
```

---

## Test Execution Order Considerations

1. **Run read-only tools first** — `get_platform_settings` and `get_platform_capabilities` for all platforms before any `configure_*` calls. This captures baseline state.

2. **Run `configure_*` happy paths before edge cases** — configure valid settings first to verify the handler works, then test edge cases (empty strings, invalid types, etc.).

3. **Run cross-tool integration tests last** — Scenarios I-V involve configure → get settings → validate → get capabilities chains. These depend on settings persisting from prior calls.

4. **Interleave `validate_platform_build` with `configure_*`** — validate before and after configuration to verify the validation report reflects changes (Scenarios 7-9 in `validate_platform_build`).

5. **Restore baseline after tests** — use the recorded baseline settings to reset platform configuration. If using a fresh project per run, skip restoration.

---

## Summary

| Category | Prerequisite Count |
|---|---|
| Godot project | 1 (clean 4.x project) |
| Scenes | 0 |
| Resources | 0 |
| Nodes in scene | 0 |
| Editor state | Edit mode, MCP connected |
| Settings/modifications | Export presets (may be auto-created) |
| External SDKs | None required (results vary) |

**Bottom line:** These 6 tools are purely project-configuration tools. The only hard prerequisite is a Godot 4.x project with the MCP plugin active and WebSocket-connected. No scenes, nodes, resources, or game-state setup is needed.
