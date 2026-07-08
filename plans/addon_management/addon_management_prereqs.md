# Prerequisites for Addon Management Test Plan

> **Source test plan:** `addon_management_test_plan.md`  
> **Source tool:** `server/src/tools/addon_management.ts`  
> **Tools covered:** `list_addons`, `install_addon`, `uninstall_addon`, `update_addon`, `configure_addon`  
> **Generated:** 2026-07-08

---

## Required Project State

- **Godot 4.x project** exists on disk with a valid `project.godot` file. The project must be open in the Godot editor.
- **godot_mcp addon is installed and active.** The addon lives at `res://addons/godot_mcp/` and must be enabled in **Project → Project Settings → Plugins**. The plugin registers the autoload `mcp_runtime` at `res://addons/godot_mcp/services/mcp_runtime.gd` in `project.godot`'s `[autoload]` section.
- **MCP server is running** (`node server/dist/index.js` or `npx -y @keeveeg/godot-mcp`) and connected to the Godot editor via WebSocket on one of ports 6505-6514. The Godot editor's **MCP** bottom panel shows "Connected" status.
- **`res://addons/` directory exists** and is writable. The addon management tools write into this directory.
- **Dedicated test project only.** Do NOT run these tests in a production project — `install_addon`, `uninstall_addon`, `update_addon`, and `configure_addon` all modify project state (files on disk, `project.godot` autoloads, plugin configs).
- **Project has no extra addons beyond `godot_mcp`** at the start of the test session. Tests in the `list_addons` scenario 1 expect only the MCP plugin in the list. After each test run, uninstall any addons that were installed to return to this clean state.

## Required External Dependencies

- **Network access to the Godot Asset Library** required for:
  - `install_addon` Scenarios 1-2 (install `godot-sqlite` from Asset Library, both default and explicit `source: "asset_lib"`)
  - `update_addon` Scenario 1 (update `godot-sqlite` to latest version)
  - Cross-Tool Scenario I (full lifecycle with `godot-sqlite`)
  - Cross-Tool Scenario II (`source: "asset_lib"` path for addon-a)
  - These scenarios will fail if the Asset Library is unreachable (firewall, proxy, offline).

- **Git installed and on system PATH** required for:
  - `install_addon` Scenario 3 (`source: "git"`, `url: "https://github.com/user/my-godot-plugin.git"`)
  - Cross-Tool Scenario II (`source: "git"` path for addon-b)
  - The test executor must provide a real, accessible Git repository URL containing a valid Godot addon (with `plugin.cfg` in the repo root). The URL `https://github.com/user/my-godot-plugin.git` is a placeholder — replace with a real repo before testing.

- **Local filesystem addon directory** required for:
  - `install_addon` Scenario 4 (`source: "local"`, `url: "C:/path/to/local/addon"`)
  - Cross-Tool Scenario II (`source: "local"` path for addon-c)
  - The path `"C:/path/to/local/addon"` is a placeholder on Windows; use a platform-appropriate absolute path pointing to a directory that contains:
    - A valid `plugin.cfg` file (with at least `[plugin]` section, `name` key)
    - The addon's GDScript and resource files
  - On Linux/macOS, use paths like `/tmp/test-addon/` or `/home/user/test-addon/`

## Required Pre-Installed Addons

For scenarios that operate on an already-installed addon, the following must be present BEFORE the scenario runs:

| Addon | Required For | Must Have | Notes |
|-------|-------------|-----------|-------|
| `godot_mcp` | **All scenarios** | Installed + active | The bridge plugin itself. Must appear in `list_addons` output. |
| `godot-sqlite` | `uninstall_addon` Scenario 1, `update_addon` Scenarios 1 & 3, `configure_addon` Scenarios 1-2, 5-6, 8-10, 13, Cross-Tool I & III | Installed via Asset Library | Install first using `install_addon({ "name": "godot-sqlite" })` or `install_addon({ "name": "godot-sqlite", "source": "asset_lib" })`. After installation, `res://addons/godot-sqlite/` must exist. |
| `<addon-at-latest-version>` | `update_addon` Scenario 3 | Installed + already at latest version | Any installed addon known to be at its latest available version. The tool should report "already up to date" rather than erroring. |
| `<installed-addon>` | Cross-Tool Scenario III | Installed | Any installed addon with configurable settings. `godot-sqlite` works if configured first. |

## Required Editor State

- **Godot editor is in Edit mode** (not Play mode). Play mode is not required for any addon management scenario.
- **No blocking dialogs** are open in the Godot editor (the plugin auto-dismisses most dialogs, but manual dialogs like "Save changes?" can block WebSocket responses).
- **`res://addons/` directory is writable** on the filesystem (not read-only, not in a protected location).
- **Godot Output log visible** for debugging: check **MCP** panel bottom dock for `[MCP]` messages during test execution.
- **No breakpoints set** on any GDScript files (not required, but avoids accidental pauses during long-running operations like Asset Library downloads).

## Required Settings/Config

- **`godot_mcp_config.json`** (optional, at project root): If present, ensure none of these tools are disabled:
  ```json
  {
    "enabled_tools": {
      "list_addons": true,
      "install_addon": true,
      "uninstall_addon": true,
      "update_addon": true,
      "configure_addon": true
    }
  }
  ```
  If the file does not exist, all tools are enabled by default.

- **No specific `project.godot` settings** are required beyond what the godot_mcp plugin registers automatically.

- **No specific input actions, collision layers, or autoloads** are needed beyond the `mcp_runtime` autoload that the plugin registers.

## Required Resources

No `.tres`, `.res`, textures, materials, shaders, or audio files are required for the addon management tests. These tools operate purely at the filesystem and plugin-registry level.

However, the **local addon directory** (used in `install_addon` Scenario 4) must contain at minimum:

```
<local-addon-path>/
  plugin.cfg          # Required: [plugin] section with name, author, version, description
  <addon-name>.gd     # Optional: main script (any GDScript file)
```

A minimal `plugin.cfg`:
```ini
[plugin]
name="Test Local Addon"
description="A minimal addon for testing local installation."
author="Test Suite"
version="1.0.0"
script="test_addon.gd"
```

A minimal `test_addon.gd`:
```gdscript
tool
extends EditorPlugin

func _enter_tree():
    print("[Test Local Addon] Loaded")
    pass

func _exit_tree():
    pass
```

---

## Setup Script

The following GDScript can be run via `execute_editor_script` to create the minimal local addon directory structure needed for Scenario 4. Note: this script only creates the *local* addon files outside the project — it does NOT install them. The `install_addon` tool installs them from the local path.

```gdscript
# EditorScript: Create a minimal local addon for install_addon testing
# Run this via godot_execute_editor_script, then copy the output to a temp directory.
# Or run it directly if you have filesystem write access.

extends EditorScript

func _run():
    # Create the local addon in the OS temp directory
    var dir = OS.get_user_data_dir().plus_file("../temp/test_local_addon")
    var d = Directory.new()

    if not d.dir_exists(dir):
        d.make_dir_recursive(dir)

    # plugin.cfg
    var cfg_path = dir.plus_file("plugin.cfg")
    var cfg = File.new()
    cfg.open(cfg_path, File.WRITE)
    cfg.store_string("""[plugin]
name="Test Local Addon"
description="A minimal addon for testing local installation."
author="Test Suite"
version="1.0.0"
script="test_addon.gd"
""")
    cfg.close()

    # test_addon.gd — minimal EditorPlugin
    var script_path = dir.plus_file("test_addon.gd")
    var script_file = File.new()
    script_file.open(script_path, File.WRITE)
    script_file.store_string("""tool
extends EditorPlugin

func _enter_tree():
    print("[Test Local Addon] Loaded")

func _exit_tree():
    pass
""")
    script_file.close()

    print("Local addon created at: ", dir)
    print("Use this path in install_addon: ", dir)
```

---

## Test Execution Order Dependencies

Several scenarios depend on prior scenarios having completed. Execute in this order:

```
Phase 1: Validation-only tests (no state changes)
  list_addon Scenarios 1-3
  install_addon Scenarios 5-15 (Zod validation)
  uninstall_addon Scenarios 2-5
  update_addon Scenarios 2, 4-5
  configure_addon Scenarios 3-13 (except those needing pre-installed addon)

Phase 2: Install godot-sqlite
  install_addon Scenario 1 or 2
  Verify: install_addon Scenario 15 (extra params)

Phase 3: Operate on installed addon
  configure_addon Scenarios 1-2, 5-6, 8-10, 13
  update_addon Scenarios 1, 3
  Cross-Tool III (idempotent configure)

Phase 4: Cross-tool integration (uses Phase 3 state + additional installs)
  Cross-Tool I (full lifecycle — ends with uninstall)
  Cross-Tool II (all source types — needs git URL and local path)

Phase 5: Uninstall remaining addons
  uninstall_addon Scenario 1 (remove godot-sqlite)
  uninstall_addon Scenario 6 (attempt to remove godot_mcp — document behavior)

Phase 6: Cleanup
  Verify list_addons shows only godot_mcp again
```

---

## Notes for Test Executors

1. **The MCP server does Zod validation; the Godot plugin does runtime validation.** Zod validation tests (Scenarios 5-15 of `install_addon`, Scenarios 3-5 of `uninstall_addon`, Scenarios 4-5 of `update_addon`, Scenarios 4-8, 11-12 of `configure_addon`) only require the MCP server to be running — they test parameter validation before the call reaches Godot. These can be tested without the Godot editor connected.

2. **The `url` parameter is semantically required for `source: "git"` and `source: "local"`** even though it is typed as `z.string().optional()` in the Zod schema. The Godot plugin enforces this at runtime. Scenarios 7-8 of `install_addon` test this boundary.

3. **Network-dependent scenarios** (`install_addon` Scenarios 1-2, `update_addon` Scenario 1) require internet access. If running in an offline CI environment, mock the Asset Library or skip these scenarios.

4. **Git-dependent scenarios** (`install_addon` Scenario 3, Cross-Tool II git branch) require Git to be installed (`git --version` must succeed) and the test repo URL must be accessible.

5. **Local `url` paths** (`install_addon` Scenario 4) must be absolute paths. On Windows, use `C:\...` or `D:\...`; on Linux/macOS, use `/home/...` or `/tmp/...`. Relative paths are not tested — behavior is undefined.
