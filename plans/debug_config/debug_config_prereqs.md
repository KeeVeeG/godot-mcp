# Prerequisites for Debug Configuration Tools Test Plan

**Source plan:** `server/src/test_plans/debug_config_test_plan.md`
**Generated:** 2026-07-08

All 6 tools in this plan use `callGodot(bridge, '<endpoint>', args)` — they are simple pass-throughs. The Zod schemas are validated server-side; all domain logic and state mutation happen in the Godot editor plugin (`addon/godot_mcp/commands/debug_config_commands.gd`).

---

## Required Project State

- **Godot project exists and is open in the editor.** Any project type (2D, 3D, empty) works — none of these tools require a specific scene or node hierarchy.
- **Godot editor is running** with the **MCP plugin active** (`addons/godot_mcp/` installed and enabled in Project Settings → Plugins).
- **MCP plugin WebSocket client is connected** to the Node.js MCP server bridge (port negotiated on 6505–6514).
- **`project.godot` exists and is writable.** The `set_profilers` and `set_error_handling` tools call `ProjectSettings.save()` — a read-only `project.godot` (e.g., version control lock) will cause failures in those test scenarios.
- **No specific scene needs to be open.** All tools operate on editor-level settings, project settings, or the editor log — none query scene tree nodes.
- **For `get_editor_log` tests:** The editor log file (`user://logs/godot.log` by default, or whatever `debug/file_logging/log_path` is set to) should exist. If the project has never generated log output, `get_editor_log` returns an empty array `[]` — this is valid but limits test coverage for non-empty scenarios.

---

## Required Scenes

None. All tools operate on editor-level state, not scene tree state.

---

## Required Resources

None. No `.tres`, `.res`, textures, materials, shaders, audio files, or any other project resources are needed.

---

## Required Editor/Game State

### Baseline state for all tests

| State | Requirement | Reason |
|-------|-------------|--------|
| Editor running | **Must** be open | All tools call `EditorInterface` APIs or access `ProjectSettings` |
| MCP plugin connected | **Must** be connected | WebSocket bridge must be active to forward calls |
| Play mode | **Not running** (stopped) | None of the tools require gameplay; `set_error_handling` configures *editor* debugger behavior during future gameplay, not current runtime |
| Scene loaded | Any or none | Not relevant |

### State for specific scenarios

| Scenario | Prerequisite |
|----------|--------------|
| `get_editor_log` Scenario 9 (empty log) | Call `clear_editor_log` immediately before this test. Wait ~100ms for the clear to propagate. |
| `clear_editor_log` Scenario 4 (generate entries after clear) | After step 2 of the scenario, run a script with `print("test log entry")` or trigger any action that emits output to the editor log. A simple approach: evaluate `print("integration_test_log_entry")` via `execute_editor_script`. |
| Integration 2 (step 5 — trigger intentional error) | Either: (a) create a temporary GDScript with a syntax error and attach it to a node, or (b) call `execute_editor_script` with `printerr("intentional test error")`. The error must appear in the editor log for subsequent `get_editor_log` filter tests to return non-empty results. |
| `set_remote_debug` — all scenarios | Editor must have permission to write to `EditorSettings`. These are stored in `editor_settings-4.tres` (or similar) in the editor's config directory. |
| `set_profilers` — all scenarios | `ProjectSettings.save()` must succeed. Verify `project.godot` is not read-only. |
| `set_error_handling` — all scenarios | Same as `set_profilers`. |

### Editor log content expectations

For `get_editor_log` tests that expect non-empty results (Scenarios 1–8, 10–18 positive cases), the editor log should ideally contain entries of type `error`, `warning`, and `info`. If the log is completely empty, the success path for these scenarios is still valid (returns `[]`) but the filter tests won't verify that filtering actually works.

**Recommended:** Seed the log before running `get_editor_log` tests:

```gdscript
# Execute via execute_editor_script to seed the log:
print("INFO: Pre-test info message")
push_warning("WARNING: Pre-test warning message")
printerr("ERROR: Pre-test error message")
```

---

## Required Settings/Config

None of these tools require specific project settings to be pre-configured — they read or write settings themselves. However, the following are relevant:

### Settings written by tools during tests

| Tool | Setting key | Source |
|------|------------|--------|
| `set_remote_debug` | `network/debug/remote_host` | `EditorSettings` |
| `set_remote_debug` | `network/debug/remote_port` | `EditorSettings` |
| `set_profilers` | `debug/settings/profiler/max_functions` | `ProjectSettings` → `project.godot` |
| `set_profilers` | `debug/settings/profiler/max_timestamp_query_elements` | `ProjectSettings` → `project.godot` |
| `set_error_handling` | `debug/gdscript/warnings/enable` | `ProjectSettings` → `project.godot` |

### Settings read by `get_debug_settings`

| Key | Source | Default |
|-----|--------|---------|
| `network/debug/remote_host` | `EditorSettings` | `""` |
| `network/debug/remote_port` | `EditorSettings` | — |
| `debug/settings/profiler/max_functions` | `ProjectSettings` | `16384` |
| `debug/settings/profiler/max_timestamp_query_elements` | `ProjectSettings` | `256` |
| `debug/gdscript/warnings/enable` | `ProjectSettings` | `true` |
| `application/run/disable_stdout` | `ProjectSettings` | `false` |
| `application/run/disable_stderr` | `ProjectSettings` | `false` |
| `debug/file_logging/enable_file_logging` | `ProjectSettings` | `false` |
| `debug/file_logging/log_path` | `ProjectSettings` | `""` |

### Settings read by `get_editor_log`

| Key | Source | Default |
|-----|--------|---------|
| `debug/file_logging/log_path` | `ProjectSettings` | `"user://logs/godot.log"` |

### Input actions

None required.

### Autoloads

None required.

### Collision layers

None required.

---

## External State

| Requirement | Needed for | Notes |
|-------------|------------|-------|
| MCP server (`node dist/index.js`) | All tests | Must be running and connected to the Godot editor plugin |
| File system access to `user://` | `get_editor_log`, `clear_editor_log` | The log file is at `user://logs/godot.log` (or custom path) |
| `EditorSettings` writable | `set_remote_debug` | Editor must not be in a read-only state |
| `project.godot` writable | `set_profilers`, `set_error_handling` | `ProjectSettings.save()` is called |
| No addons beyond MCP required | — | None of the tools depend on third-party addons |
| No git requirements | — | None |

---

## Test Execution Order Notes

1. **Test isolation for `set_*` tools:** Each `set_*` test mutates persistent state. To avoid test pollution:
   - Record baseline values via `get_debug_settings` at the start of the test suite.
   - After all tests, restore baseline values via the appropriate `set_*` tool.
   - Alternatively, run `set_*` tests that depend on state sequentially (not in parallel).

2. **`get_editor_log` / `clear_editor_log` interaction:** These tools are coupled. The `clear_editor_log` Scenario 4 and Integration 2 depend on generating new log entries after a clear. Schedule these after the standalone `get_editor_log` scenarios that expect non-empty logs.

3. **`get_editor_log` filter tests:** The filter tests (Scenarios 2–4) can only verify correctness if the log contains entries of each filter type. Run the log seeding script (see below) before these scenarios.

---

## Setup Script

Run this GDScript via `godot_execute_editor_script` before the test suite to ensure a known-good baseline:

```gdscript
extends EditorScript

func _run():
	# 1. Ensure editor log has content for get_editor_log tests
	print("MCP_TEST_INFO: Debug config test plan — info seed entry")
	push_warning("MCP_TEST_WARN: Debug config test plan — warning seed entry")
	printerr("MCP_TEST_ERR: Debug config test plan — error seed entry")
	
	# 2. Record baseline debug settings (the test executor should store these)
	var es = EditorInterface.get_editor_settings()
	var remote_host = es.get_setting("network/debug/remote_host")
	var remote_port = es.get_setting("network/debug/remote_port")
	var max_funcs = ProjectSettings.get_setting("debug/settings/profiler/max_functions", 16384)
	var max_ts = ProjectSettings.get_setting("debug/settings/profiler/max_timestamp_query_elements", 256)
	var boe = ProjectSettings.get_setting("debug/gdscript/warnings/enable", true)
	
	print("MCP_TEST_BASELINE: remote_host=" + str(remote_host))
	print("MCP_TEST_BASELINE: remote_port=" + str(remote_port))
	print("MCP_TEST_BASELINE: max_functions=" + str(max_funcs))
	print("MCP_TEST_BASELINE: max_timestamp_query_elements=" + str(max_ts))
	print("MCP_TEST_BASELINE: break_on_error=" + str(boe))
	
	# 3. Verify project.godot is writable
	var config = ConfigFile.new()
	var err = config.load("res://project.godot")
	if err != OK:
		printerr("MCP_TEST_WARN: project.godot not loadable — set_profilers/set_error_handling tests may fail")
	else:
		print("MCP_TEST_OK: project.godot is loadable")
```

### Teardown Script

Run after all tests to restore baseline settings:

```gdscript
extends EditorScript

func _run():
	# Restore settings from baseline (replace values with recorded baseline)
	# These should be called via the MCP tools, not directly:
	#   godot_set_remote_debug(enabled=<baseline>, host=<baseline_host>, port=<baseline_port>)
	#   godot_set_profiler_settings(max_functions=<baseline_max_funcs>, max_timestamp_query_elements=<baseline_max_ts>)
	#   godot_set_error_handling(break_on_error=<baseline_boe>)
	pass
```

---

## Summary

This test plan has minimal prerequisites compared to other plans — no scenes, no nodes, no resources, and no specific project type are needed. The only hard requirements are:

1. **Godot editor open with MCP plugin connected**
2. **Writable `project.godot`** (for `set_profilers` and `set_error_handling`)
3. **Writable `EditorSettings`** (for `set_remote_debug`)
4. **Seeded editor log** (for `get_editor_log` filter and non-empty tests)
5. **Baseline state recorded** (for restore after tests)
