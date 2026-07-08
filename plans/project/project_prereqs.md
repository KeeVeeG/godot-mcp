# Prerequisites for Project Tools Test Plan

**Source plan:** `server/src/test_plans/project_test_plan.md`
**Generated:** 2026-07-08
**Phase:** 1.2 (runs after `project_creation_test_plan.md` Phase 1.1)

---

## Required Project State

- **Godot 4.x project** (tested with 4.7) — must exist on disk with a valid `project.godot` at the root. Created by Phase 1.1 or pre-created manually.
- **Godot MCP addon** installed and active at `addons/godot_mcp/` — the plugin must be connected to the MCP server via WebSocket for ALL tool calls to succeed.
- **Godot MCP server** (`server/dist/index.js`) running and WebSocket-connected to the Godot plugin on an auto-negotiated port (6505–6514).
- **`project.godot`** must exist at `res://project.godot` — required by `search_files` Scenario 3, `project_path_to_uid` Scenario 1, Cross-Scenario 2, Cross-Scenario 3.
- **`res://scenes/` directory** must exist — required by `get_filesystem_tree` Scenario 6 (subdirectory listing), `project_path_to_uid` Scenario 2 (scene file path to UID).
- **`res://scripts/` directory** must exist — required by `project_path_to_uid` Scenario 3 (script file path to UID).
- **At least one `.gd` file** must exist somewhere in the project — required by `get_filesystem_tree` Scenarios 2/3/7 (extension filters), `search_files` Scenario 2 (extension search), `project_path_to_uid` Scenario 3 (script UID lookup).
- **At least one `.tscn` scene file** must exist — required by `get_filesystem_tree` Scenario 3 (multi-filter), `project_path_to_uid` Scenario 2 (scene UID lookup), Cross-Scenario 3 (UID round-trip with filesystem).
- **At least one file with "player" in its filename** — required by `search_files` Scenario 1 (filename search). Expected examples: `res://scenes/player.tscn`, `res://scripts/player.gd`.
- **At least one deeply nested file** (depth > 3) — required by `get_filesystem_tree` Scenario 5 (max_depth=50). A file at depth 4+ validates deep recursion works.
- **Project must have a configured main scene** (optional but verified) — `get_project_info` Scenario 4 checks `main_scene` is a `res://` path or empty string. Either is valid; the test should handle both.
- **Project must have standard Godot settings** in `project.godot` — `application/config/name`, `application/config/version`, `display/window/size/viewport_width`, `application/config/use_custom_user_dir` must all be present with valid values. These are standard in any Godot 4.x project.

---

## Required Scenes

### 1. Any playable scene (`res://scenes/main.tscn` or equivalent)

Used by `project_path_to_uid` Scenario 2 and Cross-Scenario 3. The exact path is flexible — the test adapts to whatever scenes exist. Minimally, a scene file must exist at `res://scenes/` with a `.tscn` extension.

**Minimal scene content (just enough to be a valid .tscn):**
```
main (Node2D root)
```

No specific node hierarchy is required. A single root node is sufficient.

---

## Required Resources

### Project files (must exist on disk)

| Path | Purpose | Notes |
|------|---------|-------|
| `res://project.godot` | Configuration file | Exists in every Godot project. Used by `search_files` S3, `project_path_to_uid` S1, Cross-Scenario 2, Cross-Scenario 3 |
| `res://scenes/main.tscn` (or any `.tscn`) | Scene file | Used by `get_filesystem_tree` S3/S6, `project_path_to_uid` S2, Cross-Scenario 3 |
| `res://scripts/player.gd` (or any `.gd`) | Script file | Used by `get_filesystem_tree` S2/S3/S7, `search_files` S1/S2, `project_path_to_uid` S3, Cross-Scenario 3 |
| Files containing "player" in name | Search targets | Used by `search_files` S1. If `player.gd` or `player.tscn` exists, that suffices |

### Directories

| Path | Purpose |
|------|---------|
| `res://scenes/` | Directory listing tests, UID round-trip with scene files |
| `res://scripts/` | Directory listing tests, UID round-trip with script files |
| Nested directory (e.g., `res://addons/godot_mcp/services/`) | Deep recursion test (`get_filesystem_tree` S5, max_depth=50). The MCP addon itself provides deep nesting. |

### Settings that must exist in project.godot

| Setting Key | Expected Type | Used By |
|-------------|---------------|---------|
| `application/config/name` | `string` | `get_project_settings` S1/S2/S5/S6, `set_project_setting` S1/S5/S11/S12, Cross-Scenario 1 |
| `application/config/version` | `string` | `get_project_settings` S1/S2 |
| `display/window/size/viewport_width` | `int` | `get_project_settings` S1/S3, `set_project_setting` S2/S5/S10 |
| `application/config/use_custom_user_dir` | `bool` | `set_project_setting` S3/S4 |
| `input/` prefixed settings | various | `get_project_settings` S4 |

All of the above are standard Godot 4.x project settings and exist by default in any new project.

---

## Required Editor/Game State

| State | Required By | Notes |
|-------|-------------|-------|
| **Godot editor open** with project loaded | ALL tools | The MCP plugin must be connected. `get_project_info` S1 is the smoke test — if this fails, nothing works. |
| **Godot editor is NOT in play mode** | `get_project_info`, `get_filesystem_tree`, `search_files`, `get_project_settings`, `set_project_setting`, `uid_to_project_path`, `project_path_to_uid` (all scenarios) | All 7 project tools operate in editor mode. None require a running game. |
| **Standard editor layout** | All tools | No special layout needed. All tools work regardless of editor layout. |
| **No specific tool selected** | All tools | Project tools don't depend on the active editor tool. |

---

## Required Settings/Config

### Project Settings

- **`application/config/name`** must be set to a non-empty string (default: the project folder name)
- **`application/config/version`** must be set (default: `"1.0.0"`)
- **`application/config/use_custom_user_dir`** must exist (default: `false`)
- **`display/window/size/viewport_width`** must exist (default: `1152`)
- **`display/window/size/viewport_height`** must exist (default: `648`)
- **No custom input actions, collision layers, or autoloads** are required for these 7 tools. The default Godot project configuration is sufficient.

### Addons

- **godot_mcp** addon must be enabled in Project Settings → Plugins (required for ALL tool calls to reach Godot)

### MCP Server Config

- **No tools disabled** in `godot_mcp_config.json` — all 7 project tools must be enabled (they are enabled by default)
- `get_project_info`, `get_filesystem_tree`, `search_files`, `get_project_settings`, `set_project_setting`, `uid_to_project_path`, `project_path_to_uid` — all enabled

---

## Setup Script

Run this GDScript via `execute_editor_script` if the project was created but lacks the required files. This creates the minimal filesystem structure needed by the test plan.

```gdscript
# === Project Test Plan: Minimal Setup ===
# Creates the directories and stub files needed by project_test_plan.md scenarios.
# Assumes a Godot project already exists and the MCP addon is active.

# 1. Create directories
DirAccess.make_dir_recursive_absolute("res://scenes")
DirAccess.make_dir_recursive_absolute("res://scripts")

# 2. Create a minimal scene file at res://scenes/main.tscn
# (needed for get_filesystem_tree S3/S6, project_path_to_uid S2, Cross-Scenario 3)
var scene_root = Node2D.new()
scene_root.name = "main"
var packed_scene = PackedScene.new()
packed_scene.pack(scene_root)
ResourceSaver.save(packed_scene, "res://scenes/main.tscn")

# 3. Create a stub GDScript at res://scripts/player.gd
# (needed for get_filesystem_tree S2/S3/S7, search_files S1/S2, project_path_to_uid S3)
var player_gd = FileAccess.open("res://scripts/player.gd", FileAccess.WRITE)
player_gd.store_string("""extends Node2D

func _ready():
	pass
""")
player_gd.close()

# 4. Create a nested subdirectory with a file to test deep recursion
# (needed for get_filesystem_tree S5 — max_depth=50)
DirAccess.make_dir_recursive_absolute("res://scenes/levels/world1/zone1")
var deep_file = FileAccess.open("res://scenes/levels/world1/zone1/deep.gd", FileAccess.WRITE)
deep_file.store_string("""extends Node
""")
deep_file.close()

# 5. Refresh the project filesystem so Godot registers the new files
get_editor_interface().get_resource_filesystem().scan()
```

**Post-setup manual steps:**

1. **Verify the project saves properly** — run `get_project_info` and confirm it returns a valid response. If this fails, the MCP bridge is not connected.
2. **Verify `project.godot` has standard settings** — run `get_project_settings({ "filter": "application/config/" })` and confirm it returns `name` and `version` fields.
3. **Run `get_filesystem_tree({ "path": "res://", "max_depth": 1 })`** — confirm it lists `project.godot`, `scenes/`, and `scripts/` directories.
4. **Run `search_files({ "query": "player" })`** — confirm it finds `res://scripts/player.gd`.
5. **Run `project_path_to_uid({ "path": "res://project.godot" })`** — confirm it returns a valid `uid://...` string. Record this UID for `uid_to_project_path` Scenario 1.
6. **Record original values** for `application/config/name` and `display/window/size/viewport_width` — needed to restore state after `set_project_setting` mutating tests.

---

## Scenario-to-Prerequisite Mapping

### get_project_info

| Scenario | Prerequisites |
|----------|---------------|
| S1 (happy path) | Godot editor open with project loaded, MCP bridge connected |
| S2 (extra params) | Same as S1 |
| S3 (null/undefined args) | Same as S1 |
| S4 (non-empty fields) | Project must have a `name` (non-empty), `version` (non-empty), `engine_version` (looks like `"4.x"`), `main_scene` (a `res://` path or empty string) |

### get_filesystem_tree

| Scenario | Prerequisites |
|----------|---------------|
| S1 (root listing) | Project files exist: `project.godot` at root, directories `scenes/` and `scripts/` visible at `res://` |
| S2 (filter `.gd`) | At least one `.gd` file exists in the project |
| S3 (filter `.gd` + `.tscn`) | At least one `.gd` AND one `.tscn` file exist |
| S4 (max_depth=1) | Any project state — shallow listing always works |
| S5 (max_depth=50) | At least one file at depth 4+ (e.g., `addons/godot_mcp/services/mcp_runtime.gd` at depth 3+ or the nested file created by the setup script) |
| S6 (subdirectory) | `res://scenes/` directory must exist on disk |
| S7 (filters + depth) | `.gd` files must exist at depths 1–3 |
| S8 (missing path) | None (Zod validation test) |
| S9 (string max_depth) | None (Zod validation test) |
| S10 (max_depth ≤ 0) | None (Zod validation test) |
| S11 (max_depth negative) | None (Zod validation test) |
| S12 (float max_depth) | None (Zod validation test) |
| S13 (non-res:// path) | None — tests Godot's error handling for `"C:/some/path"` |
| S14 (non-existent dir) | `res://nonexistent_dir` must NOT exist |
| S15 (empty filters) | Any project state |
| S16 (dot-prefixed extensions) | Any project state — tests filter format edge case |

### search_files

| Scenario | Prerequisites |
|----------|---------------|
| S1 ("player") | At least one file with "player" in its name (e.g., `res://scripts/player.gd`, `res://scenes/player.tscn`) |
| S2 (".gd") | At least one `.gd` script file exists |
| S3 ("project.godot") | `res://project.godot` exists (always true in any Godot project) |
| S4 (no matches) | `"zzz_nonexistent_file_xyz"` must NOT appear in any filename |
| S5 (special chars) | None — tests robustness |
| S6 (empty string) | None — tests edge case |
| S7 (whitespace) | None — tests edge case |
| S8 (missing query) | None (Zod validation test) |
| S9 (number query) | None (Zod validation test) |
| S10 (object query) | None (Zod validation test) |

### get_project_settings

| Scenario | Prerequisites |
|----------|---------------|
| S1 (all settings) | Standard Godot project with all default settings in project.godot |
| S2 (application/ filter) | `application/config/name`, `application/config/version`, and other `application/` prefixed settings exist |
| S3 (display/ filter) | `display/window/size/viewport_width`, `display/window/size/viewport_height`, and other `display/` settings exist |
| S4 (input/ filter) | `input/` prefixed settings exist (e.g., default input map entries like `ui_accept`, `ui_cancel`) |
| S5 (no trailing slash) | Same as S2 — tests filter matching behavior |
| S6 (exact key filter) | `application/config/name` setting exists |
| S7 (no matches) | `nonexistent_prefix/` must NOT match any setting key |
| S8 (empty params) | Same as S1 |
| S9 (number filter) | None (Zod validation test) |
| S10 (uppercase filter) | Tests case sensitivity — no specific prerequisite |

### set_project_setting

| Scenario | Prerequisites |
|----------|---------------|
| S1 (string setting) | `application/config/name` setting exists. **CRITICAL: Record original value first** to restore after test. |
| S2 (numeric setting) | `display/window/size/viewport_width` setting exists. **Record original value first.** |
| S3 (boolean: true) | `application/config/use_custom_user_dir` setting exists. **Record original value first.** |
| S4 (boolean: false) | Same setting as S3. Restore original after test. |
| S5 (string-as-number) | `display/window/size/viewport_width` exists. Tests type coercion. |
| S6 (missing key) | None (Zod validation test) |
| S7 (missing value) | None (Zod validation test) |
| S8 (missing both) | None (Zod validation test) |
| S9 (non-existent key) | None — tests Godot's handling of unknown setting keys |
| S10 (wrong type) | `display/window/size/viewport_width` exists — pass non-numeric string |
| S11 (null value) | `application/config/name` exists — pass `null` as value |
| S12 (complex object) | `application/config/name` exists — pass nested object |
| S13 (empty key) | None — tests empty key handling |
| S14 (whitespace key) | None — tests whitespace key handling |

### uid_to_project_path

| Scenario | Prerequisites |
|----------|---------------|
| S1 (known UID → path) | A file with a known UID must exist. Use `project_path_to_uid({ "path": "res://project.godot" })` first to obtain a valid UID. |
| S2 (non-existent UID) | `"uid://nonexistent123456"` must NOT exist in the project |
| S3 (missing uid) | None (Zod validation test) |
| S4 (number uid) | None (Zod validation test) |
| S5 (empty UID) | None — tests Godot's handling of empty UIDs |
| S6 (no uid:// prefix) | None — tests format validation |
| S7 (special chars) | None — tests malformed input robustness |
| S8 (very long UID) | None — tests input size handling. Use `"uid://" + "a".repeat(500)` |

### project_path_to_uid

| Scenario | Prerequisites |
|----------|---------------|
| S1 (project.godot → UID) | `res://project.godot` must exist (always true) |
| S2 (scene → UID) | At least one `.tscn` scene file exists, e.g., `res://scenes/main.tscn` |
| S3 (script → UID) | At least one `.gd` script file exists, e.g., `res://scripts/player.gd` |
| S4 (round-trip) | `res://project.godot` exists. Step 1: path → UID. Step 2: UID → path. Step 3: compare paths. |
| S5 (missing path) | None (Zod validation test) |
| S6 (number path) | None (Zod validation test) |
| S7 (non-existent file) | `res://nonexistent/file.gd` must NOT exist |
| S8 (non-res:// path) | None — tests Godot's handling of `"C:/Users/somefile.gd"` |
| S9 (directory path) | `res://scenes/` directory must exist. Directories do not have UIDs. |
| S10 (empty path) | None — tests empty path handling |
| S11 (trailing slash) | `res://project.godot` exists — pass `"res://project.godot/"` with trailing slash |

### Cross-Tool Integration Scenarios

| Scenario | Prerequisites |
|----------|---------------|
| Cross-S1 (set → get → restore) | `application/config/name` setting exists. **Record original value.** Execute set → verify → restore. |
| Cross-S2 (search ↔ tree) | `res://project.godot` exists and is visible in both `search_files` and `get_filesystem_tree` results |
| Cross-S3 (UID round-trip + tree) | A `.gd` or `.tscn` file exists at depth ≤ 2 from root. Use `get_filesystem_tree` to pick one, convert path → UID → path, verify match. |

---

## State Restoration Protocol

The following settings are mutated by `set_project_setting` tests. Their original values MUST be recorded before any mutating test runs, and restored after:

| Setting Key | Record Before | Restore After |
|-------------|---------------|---------------|
| `application/config/name` | S1, Cross-S1 | S1, Cross-S1 |
| `display/window/size/viewport_width` | S2, S5 | S2, S5 |
| `application/config/use_custom_user_dir` | S3, S4 | S3, S4 |

**Record command (run once before any set_project_setting tests):**

```
get_project_settings({ "filter": "application/config/name" })
get_project_settings({ "filter": "display/window/size/viewport_width" })
get_project_settings({ "filter": "application/config/use_custom_user_dir" })
```

Store the returned values. After each mutating test, restore using:
```
set_project_setting({ "key": "<original_key>", "value": <original_value> })
```
