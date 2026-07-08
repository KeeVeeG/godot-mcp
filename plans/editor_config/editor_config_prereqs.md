# Prerequisites for Editor Configuration Test Plan

> **Source:** `server/src/test_plans/editor_config_test_plan.md`  
> **Tools covered:** `get_editor_settings`, `set_editor_theme`, `set_editor_layout`, `set_font_size`, `set_editor_scale`, `save_editor_layout`, `load_editor_layout`, `reset_editor_layout`  
> **Generated:** 2026-07-08

---

## Required Project State

- **Godot editor must be running** with any Godot project (4.x) open. An empty default project is sufficient — these tools only interact with editor configuration, not project files.
- **Godot version 4.2+** is required for full test coverage. The `amoled` theme option (`set_editor_theme` with `"amoled"`) was introduced in Godot 4.2. On older versions, `set_editor_theme` Scenario 3 (amoled) and Integration Scenario II (which uses amoled) will fail at the Godot bridge layer.
- **MCP Godot plugin must be active** (`addons/godot_mcp/` installed and enabled in Project → Project Settings → Plugins).
- **MCP server must be connected** to the Godot editor via WebSocket bridge. All 8 tools forward calls through the bridge. The following bridge endpoints must be available:
  - `editor_config/get_settings`
  - `editor_config/set_theme`
  - `editor_config/set_layout`
  - `editor_config/set_font_size`
  - `editor_config/set_scale`
  - `editor_config/save_layout`
  - `editor_config/load_layout`
  - `editor_config/reset_layout`
- **No saved layouts with conflicting names** should exist before test execution. The test plan uses these layout names and assumes they start absent or overwritable:
  - `my-test-layout`
  - `scripting-focus`
  - `layout-2d`
  - `layout-script`
  - `overwrite-test`
  - `load-test`
  - `reset-test`
  - `before-reset`
  - `integration-test`
  - `cycle-test`
- **Editor should start in a known baseline state** — ideally the factory-default layout with dark theme and default font size (typically 14px) and default UI scale (1.0). This ensures reproducible results for `get_editor_settings` idempotency checks (Scenario 4) and `reset_editor_layout` default-restoration checks (Scenario 2).

## Required Scenes

None. These tools operate on editor-level configuration and do not interact with scene content. Any open scene — or even an empty untitled scene — is acceptable.

## Required Nodes in Scene

None. No scene nodes are created, modified, deleted, or queried by any of the 8 tools in this test plan.

## Required Resources

None. These tools do not read or write `.tres`/`.res` files, textures, materials, shaders, or audio files.

## Required Editor/Game State

- **Play mode:** Not required. All tools interact with the editor in edit mode. Play mode is neither required nor affected.
- **Editor layout:** Should start at factory defaults (or a known state). Use `reset_editor_layout()` as setup step to establish a clean baseline before each test run.
- **Editor theme:** Should start at `dark` (the Godot default). This is important for `set_editor_theme` Scenario 1 (set to dark — idempotency test) and the round-trip test (Scenario 4, which expects to restore dark at the end).
- **Editor font size:** Should be at the Godot default (typically 14). This matters for `set_font_size` Scenario 1 (set to 14 — idempotency) and `reset_editor_layout` Scenario 2 (reset when already at defaults).
- **Editor UI scale:** Should be at 1.0 (100%). This matters for `set_editor_scale` Scenario 1 (set to 1.0 — idempotency) and `reset_editor_layout` Scenario 2.
- **No unsaved layout modifications:** The current editor layout should be in a "clean" state so that `save_editor_layout` captures a known configuration.
- **No breakpoints set:** Irrelevant to these tools, but standard practice for clean test state.

## Required Settings/Config

None specific. These tools test editor preferences, not `project.godot` settings. No project settings, input actions, autoloads, or collision layers need to be configured.

However, the `godot_mcp_config.json` (in the project root) **must not disable any of the 8 tools**. If a tool is disabled via `enabled_tools`, its tests will fail because the tool won't be reachable. The config file should either:
- Not exist (all tools enabled by default), or
- Exist but omit these tool names from the `enabled_tools` block, or
- Exist and explicitly set them to `true`.

## Required External State

- **No additional addons** beyond `godot_mcp` are required.
- **No external packages** (npm, Asset Library) are required beyond the MCP server and plugin.
- **Git repo:** Not required. No git operations are performed by these tools.
- **File system:** Writable access to the Godot editor's configuration directory (where layouts are persisted). On Windows this is typically `%APPDATA%\Godot\`, on macOS `~/Library/Application Support/Godot/`, on Linux `~/.local/share/godot/`.

## Setup Script

The following sequence should be run before executing the test plan to establish a clean, known baseline state. This script does not need to be a GDScript file — it is a sequence of MCP tool calls the test harness should issue.

```
# Phase 1: Verify connectivity
1. get_editor_settings()                    → Verify the editor is connected and responsive
                                            → Capture baseline settings for later comparison

# Phase 2: Reset to factory defaults
2. reset_editor_layout()                    → Restore default layout, theme, font, scale
3. set_editor_theme({ "theme": "dark" })    → Ensure theme is dark (factory default)
4. set_font_size({ "size": 14 })            → Ensure font size is 14 (typical default)
5. set_editor_scale({ "scale": 1.0 })       → Ensure UI scale is 100%

# Phase 3: Clean up any saved layouts from previous test runs
# (Delete layouts via Godot Editor → Editor Layout menu, or via the file system)
# Layout files on disk:
#   Windows: %APPDATA%\Godot\editor_layouts\<project-hash>\
#   macOS:   ~/Library/Application Support/Godot/editor_layouts/<project-hash>/
#   Linux:   ~/.local/share/godot/editor_layouts/<project-hash>/
# Remove any files named: my-test-layout, scripting-focus, layout-2d, layout-script,
#   overwrite-test, load-test, reset-test, before-reset, integration-test, cycle-test

# Phase 4: Verify baseline
6. get_editor_settings()                    → Should match baseline from step 1 (or be at defaults)
```

### Rationale for Each Setup Step

| Step | Why |
|------|-----|
| 1. `get_editor_settings()` | Confirms the bridge is alive. Provides a reference for the "already at defaults" idempotency tests. |
| 2. `reset_editor_layout()` | Guarantees a clean slate. All tools that modify state can assume known starting values. |
| 3. `set_editor_theme(dark)` | Ensures `set_editor_theme` Scenario 1 (set to dark) is a true idempotency test. Without this, if the editor starts in light mode, Scenario 1 changes state rather than being idempotent. |
| 4. `set_font_size(14)` | Ensures `set_font_size` Scenario 1 (set to 14) is idempotent. |
| 5. `set_editor_scale(1.0)` | Ensures `set_editor_scale` Scenario 1 (set to 1.0) is idempotent. |
| 6. `get_editor_settings()` | Sanity check that reset + explicit set produced a consistent baseline. |

## Per-Scenario Prerequisite Matrix

| Tool | Scenario | Specific Prerequisites Beyond Baseline |
|------|----------|---------------------------------------|
| `get_editor_settings` | 1–4 | None (baseline only) |
| `set_editor_theme` | 1–3 | None |
| `set_editor_theme` | 4 (round-trip) | None (self-contained: starts dark, cycles all 3, ends dark) |
| `set_editor_theme` | 5–9 (validation) | None (Zod errors never reach Godot) |
| `set_editor_layout` | 1–4 | None |
| `set_editor_layout` | 5 (round-trip) | None (self-contained: cycles all 4, ends default) |
| `set_editor_layout` | 6–9 (validation) | None (Zod errors never reach Godot) |
| `set_font_size` | 1–4 | None |
| `set_font_size` | 5–12 (validation) | None (Zod errors never reach Godot) |
| `set_editor_scale` | 1–5, 10 | None |
| `set_editor_scale` | 6–9, 11–13 (validation) | None (Zod errors never reach Godot) |
| `save_editor_layout` | 1–2 | None |
| `save_editor_layout` | 3 | None (self-contained: changes layout then saves) |
| `save_editor_layout` | 4 | None (self-contained: saves, changes, overwrites) |
| `save_editor_layout` | 5–9 (validation) | None (Zod or Godot-layer errors) |
| `load_editor_layout` | 1 | Layout `load-test` must be saved first (created by test step) |
| `load_editor_layout` | 2 | Layout `reset-test` must be saved first (created by test step) |
| `load_editor_layout` | 3 | None (tests loading non-existent name — must NOT exist) |
| `load_editor_layout` | 4–6 (validation) | None (Zod errors never reach Godot) |
| `reset_editor_layout` | 1–2 | None |
| `reset_editor_layout` | 3 | Layout `before-reset` must be saved first (created by test step) |
| `reset_editor_layout` | 4–5 | None |
| Integration I | All steps | None (self-contained: captures baseline, modifies, saves, resets, loads, captures) |
| Integration II | All steps | None (self-contained: sets theme, saves, resets, loads) |
| Integration III | All steps | None (self-contained: rapid layout switching) |

## Key Insight

This test plan has **minimal external prerequisites**. Almost all state dependencies are created within the test scenarios themselves (layouts are saved before they are loaded). The only true external prerequisites are:

1. Running Godot 4.2+ with MCP plugin connected
2. Clean baseline editor state (factory defaults)
3. No pre-existing saved layout name collisions
4. MCP bridge endpoints available
5. `godot_mcp_config.json` not disabling any of the 8 tools
