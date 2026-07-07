# Project Tools — Test Plan

**Source file:** `server/src/tools/project.ts`
**Shared types:** `server/src/tools/shared-types.ts`
**Number of tools:** 7
**Generated:** 2026-07-08

---

## Type Reference

| Zod schema | Underlying type | Description |
|---|---|---|
| `ResourcePath` | `z.string()` | Resource file path (e.g. `'res://assets/theme.tres'`) |
| `SearchQuery` | `z.string()` | Search query string |
| `z.string()` | string | Generic string |
| `z.unknown()` | unknown | Any value (string, number, boolean, object, array, null) |
| `z.array(z.string())` | string[] | Array of strings |
| `z.number().int().positive()` | number (int, >0) | Positive integer |
| `z.number().int().positive().optional().default(10)` | number (int, >0) | Positive integer, defaults to 10 |
| `z.string().optional()` | string \| undefined | Optional string |

---

## Tool: `get_project_info`

**Description:** Get project metadata including name, version, engine version, and main scene
**Handler:** `callGodot(bridge, 'project/get_info', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| *(none)* | — | — | — | This tool accepts no parameters |

### Test Scenarios

#### Scenario 1: Happy path — get project info
- **Description:** Call with no parameters while a valid Godot project is open
- **Params:** `{}`
- **Expected result:** Success. Returns JSON object containing at minimum:
  - `name` (string): project name
  - `version` (string): project version from project.godot
  - `engine_version` (string): Godot engine version (e.g. "4.7")
  - `main_scene` (string): path to main scene or empty string

#### Scenario 2: Edge — extra parameters provided
- **Description:** Call with unexpected parameters
- **Params:** `{ "unexpected": "value" }`
- **Expected result:** Success (extra params are silently ignored by Zod since `inputSchema` is `{}`; `unknownKeys` behavior depends on Zod strictness, but the empty schema likely passes through any extra keys). Best practice: extra keys should be ignored.

#### Scenario 3: Edge — no Godot project running
- **Description:** Call when no Godot editor instance is connected (bridge disconnected)
- **Params:** `{}`
- **Expected result:** Error. Bridge connection timeout or "no connection" error from `callGodot`.

#### Scenario 4: Edge — project.godot missing
- **Description:** Call in a project where `project.godot` is corrupt or missing (simulated)
- **Params:** `{}`
- **Expected result:** Error from Godot plugin. Should return a meaningful error message about the missing/corrupt project file.

---

## Tool: `get_filesystem_tree`

**Description:** Get the project filesystem tree structure
**Handler:** `callGodot(bridge, 'project/get_filesystem_tree', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | string (ResourcePath) | **Yes** | — | Root path to list from (e.g. `'res://'`) |
| `filters` | string[] | No | `undefined` | Array of file extensions to filter (e.g. `['gd', 'tscn']`) |
| `max_depth` | positive integer | No | `10` | Maximum recursion depth (default: 10) |

### Test Scenarios

#### Scenario 1: Happy path — root with defaults
- **Description:** Get filesystem tree from project root with default max_depth
- **Params:** `{ "path": "res://" }`
- **Expected result:** Success. Returns JSON tree structure of the project directory, truncated at depth 10. Each node includes name, type (directory/file), and children array.

#### Scenario 2: Happy path — shallow depth
- **Description:** Get tree with max_depth = 1 (only root and direct children)
- **Params:** `{ "path": "res://", "max_depth": 1 }`
- **Expected result:** Success. Returns only the root directory listing without subdirectory contents.

#### Scenario 3: Happy path — deep depth
- **Description:** Get tree with max_depth = 50
- **Params:** `{ "path": "res://", "max_depth": 50 }`
- **Expected result:** Success. Returns the full project tree up to depth 50.

#### Scenario 4: Happy path — subdirectory
- **Description:** Get tree from a specific subdirectory
- **Params:** `{ "path": "res://scenes/" }`
- **Expected result:** Success. Returns tree starting from `res://scenes/`.

#### Scenario 5: Happy path — with filter, single extension
- **Description:** Get tree filtered to only `.gd` files
- **Params:** `{ "path": "res://", "filters": ["gd"] }`
- **Expected result:** Success. Returns tree containing only `.gd` files. Directories containing matching files are included; empty directories and non-matching files are excluded.

#### Scenario 6: Happy path — with filter, multiple extensions
- **Description:** Get tree filtered to `.gd` and `.tscn` files
- **Params:** `{ "path": "res://", "filters": ["gd", "tscn"] }`
- **Expected result:** Success. Returns tree containing only `.gd` and `.tscn` files.

#### Scenario 7: Happy path — with filter, no leading dot
- **Description:** Get tree filtered to `'gd'` (without leading dot)
- **Params:** `{ "path": "res://", "filters": ["gd"] }`
- **Expected result:** Success. Should behave identically to `['.gd']` if the plugin normalizes extensions, or may return no results if the plugin expects the dot. Both behaviors are valid; document the actual behavior.

#### Scenario 8: Happy path — with filter, with leading dot
- **Description:** Get tree filtered to `'.gd'` (with leading dot)
- **Params:** `{ "path": "res://", "filters": [".gd"] }`
- **Expected result:** Success. Should return `.gd` files. If plugin normalizes, this is identical to scenario 7.

#### Scenario 9: Happy path — empty filters array
- **Description:** Get tree with empty filters array
- **Params:** `{ "path": "res://", "filters": [] }`
- **Expected result:** Success. Should behave same as no filter (returns all files). Or may return no files. Document actual behavior.

#### Scenario 10: Edge — max_depth = 0
- **Description:** Call with max_depth = 0
- **Params:** `{ "path": "res://", "max_depth": 0 }`
- **Expected result:** Zod validation error. `z.number().int().positive()` rejects 0 (must be > 0).

#### Scenario 11: Edge — max_depth negative
- **Description:** Call with a negative max_depth
- **Params:** `{ "path": "res://", "max_depth": -5 }`
- **Expected result:** Zod validation error. `z.number().int().positive()` rejects negative numbers.

#### Scenario 12: Edge — max_depth as float
- **Description:** Call with a non-integer max_depth
- **Params:** `{ "path": "res://", "max_depth": 3.7 }`
- **Expected result:** Zod validation error. `z.number().int()` rejects floats.

#### Scenario 13: Edge — max_depth as string
- **Description:** Call with a string value for max_depth
- **Params:** `{ "path": "res://", "max_depth": "10" }`
- **Expected result:** Zod validation error. Expected number, got string.

#### Scenario 14: Edge — missing required path
- **Description:** Call without the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error. `path` is required.

#### Scenario 15: Edge — non-existent path
- **Description:** Call with a path that does not exist in the project
- **Params:** `{ "path": "res://nonexistent/" }`
- **Expected result:** Error from Godot. Should return a meaningful error message such as "Directory not found" or empty tree.

#### Scenario 16: Edge — path to a file instead of directory
- **Description:** Call with a path pointing to a file, not a directory
- **Params:** `{ "path": "res://project.godot" }`
- **Expected result:** Error or returns only the single file entry. Should not crash.

#### Scenario 17: Edge — path without res:// prefix
- **Description:** Call with a path missing the `res://` prefix
- **Params:** `{ "path": "scenes/" }`
- **Expected result:** Either error from Godot (invalid path) or coercion behavior. Document actual behavior.

#### Scenario 18: Edge — path with user:// prefix
- **Description:** Call with `user://` path instead of `res://`
- **Params:** `{ "path": "user://" }`
- **Expected result:** Error from Godot (user:// is for save data, not project filesystem tree). Should return meaningful error.

#### Scenario 19: Edge — very large project
- **Description:** Call on a project with thousands of files
- **Params:** `{ "path": "res://", "max_depth": 50 }`
- **Expected result:** Success. Returns large tree. May be slow or hit response size limits. Validate the response is valid JSON.

#### Scenario 20: Edge — max_depth extremely large
- **Description:** Call with an extremely large max_depth
- **Params:** `{ "path": "res://", "max_depth": 99999 }`
- **Expected result:** Success. Returns the full tree. Should not hang or crash due to the large number.

#### Scenario 21: Edge — path with trailing slash
- **Description:** Call with and without trailing slash — should behave consistently
- **Params:** `{ "path": "res://scenes" }` vs `{ "path": "res://scenes/" }`
- **Expected result:** Success for both. Both should return the same tree structure.

#### Scenario 22: Edge — filters with non-string elements
- **Description:** Call with non-string values in filters array
- **Params:** `{ "path": "res://", "filters": [123, true] }`
- **Expected result:** Zod validation error. `z.array(z.string())` rejects non-string array elements.

#### Scenario 23: Edge — filters as string instead of array
- **Description:** Call with a plain string instead of array
- **Params:** `{ "path": "res://", "filters": "gd" }`
- **Expected result:** Zod validation error. Expected array, got string.

---

## Tool: `search_files`

**Description:** Search for files in the project by name pattern or content
**Handler:** `callGodot(bridge, 'project/search_files', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `query` | string (SearchQuery) | **Yes** | — | Search query |

### Test Scenarios

#### Scenario 1: Happy path — search by filename
- **Description:** Search for files with a known filename pattern
- **Params:** `{ "query": "player" }`
- **Expected result:** Success. Returns array of file paths matching "player" in the filename (e.g. `res://scripts/player.gd`, `res://scenes/player.tscn`).

#### Scenario 2: Happy path — search by content
- **Description:** Search for files containing a specific string in their content
- **Params:** `{ "query": "extends Node" }`
- **Expected result:** Success. Returns array of file paths containing "extends Node" in their content. May include `.gd` and `.tscn` files.

#### Scenario 3: Happy path — search with no matches
- **Description:** Search for a term that does not exist anywhere in the project
- **Params:** `{ "query": "xyznonexistent12345" }`
- **Expected result:** Success. Returns empty array or empty results object.

#### Scenario 4: Edge — empty query string
- **Description:** Call with an empty string query
- **Params:** `{ "query": "" }`
- **Expected result:** Behavior depends on plugin implementation. May return all files, no files, or an error. Document actual behavior.

#### Scenario 5: Edge — missing required query
- **Description:** Call without the required `query` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error. `query` is required.

#### Scenario 6: Edge — query with special regex characters
- **Description:** Call with special regex characters that could cause pattern matching issues
- **Params:** `{ "query": "\\.[*+?^$(){|" }`
- **Expected result:** Should not crash. May return no results or escape special characters properly.

#### Scenario 7: Edge — query with Unicode characters
- **Description:** Search for files with Unicode/emoji content
- **Params:** `{ "query": "玩家" }`
- **Expected result:** Success. Should handle Unicode correctly. Returns matching files if any exist.

#### Scenario 8: Edge — query with very long string
- **Description:** Call with an extremely long query string (10KB+)
- **Params:** `{ "query": "<10KB of repeated text>" }`
- **Expected result:** Should not crash. May return no results or timeout. Validate graceful handling.

#### Scenario 9: Edge — query with only whitespace
- **Description:** Call with a query that is only spaces/tabs/newlines
- **Params:** `{ "query": "   " }`
- **Expected result:** Behavior depends on implementation. May return no results, all files, or an error. Document actual behavior.

#### Scenario 10: Edge — query as number instead of string
- **Description:** Call with a number value for query
- **Params:** `{ "query": 123 }`
- **Expected result:** Zod validation error. Expected string, got number.

---

## Tool: `get_project_settings`

**Description:** Get all project settings (project.godot values)
**Handler:** `callGodot(bridge, 'project/get_settings', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `filter` | string | No | `undefined` | Prefix filter for settings (e.g. `'application/'`) |

### Test Scenarios

#### Scenario 1: Happy path — no filter (all settings)
- **Description:** Get all project settings without any filter
- **Params:** `{}`
- **Expected result:** Success. Returns full JSON object of all project settings (from project.godot and defaults). Likely a large response.

#### Scenario 2: Happy path — filter by prefix: application
- **Description:** Get only settings under `application/` prefix
- **Params:** `{ "filter": "application/" }`
- **Expected result:** Success. Returns only settings with keys starting with `application/` (e.g. `application/config/name`, `application/config/version`).

#### Scenario 3: Happy path — filter by prefix: display
- **Description:** Get only settings under `display/` prefix
- **Params:** `{ "filter": "display/" }`
- **Expected result:** Success. Returns only settings with keys starting with `display/` (e.g. `display/window/size/viewport_width`).

#### Scenario 4: Happy path — filter by prefix: input
- **Description:** Get only settings under `input/` prefix
- **Params:** `{ "filter": "input/" }`
- **Expected result:** Success. Returns only input map settings.

#### Scenario 5: Happy path — filter by prefix: rendering
- **Description:** Get only settings under `rendering/` prefix
- **Params:** `{ "filter": "rendering/" }`
- **Expected result:** Success. Returns only rendering-related settings.

#### Scenario 6: Happy path — filter by prefix: physics
- **Description:** Get only settings under `physics/` prefix
- **Params:** `{ "filter": "physics/" }`
- **Expected result:** Success. Returns only physics-related settings.

#### Scenario 7: Happy path — filter by exact key
- **Description:** Filter with a full setting key (not just a prefix)
- **Params:** `{ "filter": "application/config/name" }`
- **Expected result:** Success. Returns only the single setting matching exactly, or all settings starting with that string (prefix match). Document actual behavior.

#### Scenario 8: Edge — filter with no matches
- **Description:** Filter with a prefix that does not match any setting
- **Params:** `{ "filter": "nonexistent/prefix/" }`
- **Expected result:** Success. Returns empty object `{}` or empty results.

#### Scenario 9: Edge — filter empty string
- **Description:** Call with empty string filter
- **Params:** `{ "filter": "" }`
- **Expected result:** May behave same as no filter (returns all settings) or return empty results. Document actual behavior.

#### Scenario 10: Edge — filter as number
- **Description:** Call with a number for the filter
- **Params:** `{ "filter": 42 }`
- **Expected result:** Zod validation error. Expected string, got number.

#### Scenario 11: Edge — filter with trailing slash vs without
- **Description:** Compare the behavior of `'display'` vs `'display/'` as filter
- **Params:** `{ "filter": "display" }` and `{ "filter": "display/" }`
- **Expected result:** Both should work. `'display'` might match `display/window/...` AND `display/window/...` (same). `'display/'` should match only sub-keys. Without the slash, might also match settings like `display_vsync` if any exist. Document the matching behavior.

#### Scenario 12: Edge — filter with leading slash
- **Description:** Call with a leading slash in the filter
- **Params:** `{ "filter": "/application" }`
- **Expected result:** May return no results due to leading slash mismatch, or may be normalized. Document actual behavior.

---

## Tool: `set_project_setting`

**Description:** Set a project setting value
**Handler:** `callGodot(bridge, 'project/set_setting', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `key` | string | **Yes** | — | Setting key (e.g. `'display/window/size/viewport_width'`) |
| `value` | unknown | **Yes** | — | New value for the setting (string, number, boolean, etc.) |

### Test Scenarios

#### Scenario 1: Happy path — set integer setting
- **Description:** Set a known integer-type project setting
- **Params:** `{ "key": "display/window/size/viewport_width", "value": 1280 }`
- **Expected result:** Success. The viewport width is changed to 1280. Should persist in memory (may or may not save to project.godot on disk).

#### Scenario 2: Happy path — set string setting
- **Description:** Set a known string-type project setting
- **Params:** `{ "key": "application/config/name", "value": "My Test Game" }`
- **Expected result:** Success. The project name is changed.

#### Scenario 3: Happy path — set boolean setting
- **Description:** Set a known boolean-type project setting
- **Params:** `{ "key": "application/run/low_processor_mode", "value": true }`
- **Expected result:** Success. The low processor mode setting is toggled on.

#### Scenario 4: Happy path — set float setting
- **Description:** Set a known float-type project setting
- **Params:** `{ "key": "audio/buses/default_volume_db", "value": -6.0 }`
- **Expected result:** Success. The default audio bus volume is set to -6 dB.

#### Scenario 5: Happy path — update a previously set value
- **Description:** Set a setting, then set it again to a new value
- **Params:** First: `{ "key": "display/window/size/viewport_width", "value": 1280 }` then: `{ "key": "display/window/size/viewport_width", "value": 1920 }`
- **Expected result:** Both succeed. The second call overwrites the first.

#### Scenario 6: Edge — non-existent key
- **Description:** Set a setting key that does not exist in Godot's known settings
- **Params:** `{ "key": "this/setting/does/not/exist", "value": 123 }`
- **Expected result:** Error from Godot. Unknown setting key — should return meaningful error.

#### Scenario 7: Edge — wrong type for known key (string for int)
- **Description:** Set a value of wrong type for a known setting
- **Params:** `{ "key": "display/window/size/viewport_width", "value": "not_a_number" }`
- **Expected result:** Error from Godot. Type mismatch — should return meaningful error about expected type.

#### Scenario 8: Edge — wrong type for known key (number for bool)
- **Description:** Set a numeric value for a boolean setting
- **Params:** `{ "key": "application/run/low_processor_mode", "value": 42 }`
- **Expected result:** Error from Godot. Type mismatch.

#### Scenario 9: Edge — empty key string
- **Description:** Call with empty string for key
- **Params:** `{ "key": "", "value": "test" }`
- **Expected result:** Error from Godot (invalid key) or Zod validation error if string minLength constraint exists. Since `z.string()` allows empty strings, passes Zod but Godot should reject.

#### Scenario 10: Edge — missing required key
- **Description:** Call without the required `key` parameter
- **Params:** `{ "value": 100 }`
- **Expected result:** Zod validation error. `key` is required.

#### Scenario 11: Edge — missing required value
- **Description:** Call without the required `value` parameter
- **Params:** `{ "key": "display/window/size/viewport_width" }`
- **Expected result:** Zod validation error. `value` is required.

#### Scenario 12: Edge — value is null
- **Description:** Set a setting to `null`
- **Params:** `{ "key": "display/window/size/viewport_width", "value": null }`
- **Expected result:** Error from Godot. Most settings cannot be null. Should return meaningful error.

#### Scenario 13: Edge — value is an object
- **Description:** Set a setting to a complex object
- **Params:** `{ "key": "application/config/name", "value": { "nested": "object" } }`
- **Expected result:** Error from Godot. Type mismatch — the setting key expects a string, not an object.

#### Scenario 14: Edge — value is an array
- **Description:** Set a setting to an array
- **Params:** `{ "key": "application/config/name", "value": ["array", "value"] }`
- **Expected result:** Error from Godot if the key expects a scalar. Some settings (like input actions) may accept arrays.

#### Scenario 15: Edge — key with leading slash
- **Description:** Call with a key that has a leading slash
- **Params:** `{ "key": "/display/window/size/viewport_width", "value": 1280 }`
- **Expected result:** Error from Godot (invalid key path format) or may be normalized. Document actual behavior.

#### Scenario 16: Edge — key with trailing slash
- **Description:** Call with a key that has a trailing slash
- **Params:** `{ "key": "display/window/size/viewport_width/", "value": 1280 }`
- **Expected result:** Error from Godot (invalid key path). Trailing slashes should not be valid.

#### Scenario 17: Edge — readonly setting
- **Description:** Attempt to set a read-only project setting
- **Params:** `{ "key": "application/config/engine_version", "value": "5.0" }`
- **Expected result:** Error from Godot. Read-only setting — meaningful error returned.

---

## Tool: `uid_to_project_path`

**Description:** Convert a Godot UID to a project file path
**Handler:** `callGodot(bridge, 'project/uid_to_path', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `uid` | string | **Yes** | — | The UID to look up (e.g. `'uid://abc123'`) |

### Test Scenarios

#### Scenario 1: Happy path — valid UID for existing file
- **Description:** Look up a UID that exists in the project
- **Params:** `{ "uid": "uid://<known_valid_uid>" }`
- **Expected result:** Success. Returns the `res://` file path for the given UID (e.g. `"res://scenes/main.tscn"`).

#### Scenario 2: Happy path — UID with different prefixes
- **Description:** Test UIDs with various format prefixes
- **Params:** `{ "uid": "uid://abc123def456" }`
- **Expected result:** Success if the UID exists. Returns the resolved file path.

#### Scenario 3: Edge — non-existent UID
- **Description:** Look up a UID that does not exist in the project
- **Params:** `{ "uid": "uid://nonexistent00000000000" }`
- **Expected result:** Error from Godot. Should return message like "UID not found" or empty string.

#### Scenario 4: Edge — empty string UID
- **Description:** Call with empty string
- **Params:** `{ "uid": "" }`
- **Expected result:** Error from Godot. Empty UID is not valid. Should return meaningful error.

#### Scenario 5: Edge — malformed UID (no uid:// prefix)
- **Description:** Call with a string that is not in UID format
- **Params:** `{ "uid": "abc123" }`
- **Expected result:** Error from Godot. Malformed UID — should return meaningful error about invalid format.

#### Scenario 6: Edge — UID with wrong scheme
- **Description:** Call with a wrongly formatted scheme
- **Params:** `{ "uid": "res://scenes/main.tscn" }`
- **Expected result:** Error from Godot. Not a UID format — should return meaningful error.

#### Scenario 7: Edge — missing required uid
- **Description:** Call without the required `uid` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error. `uid` is required.

#### Scenario 8: Edge — uid with special characters
- **Description:** Call with special characters in UID
- **Params:** `{ "uid": "uid://abc<script>alert(1)</script>" }`
- **Expected result:** Error from Godot (UID not found) or sanitization. Should not cause any XSS or security issues.

#### Scenario 9: Edge — uid with only whitespace
- **Description:** Call with a whitespace-only uid
- **Params:** `{ "uid": "   " }`
- **Expected result:** Error from Godot. Invalid UID format.

#### Scenario 10: Edge — uid as number instead of string
- **Description:** Call with a number for uid
- **Params:** `{ "uid": 12345 }`
- **Expected result:** Zod validation error. Expected string, got number.

---

## Tool: `project_path_to_uid`

**Description:** Convert a project file path to its UID
**Handler:** `callGodot(bridge, 'project/path_to_uid', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | string (ResourcePath) | **Yes** | — | The project path (e.g. `'res://scenes/main.tscn'`) |

### Test Scenarios

#### Scenario 1: Happy path — valid path to existing file
- **Description:** Convert a known file path to its UID
- **Params:** `{ "path": "res://scenes/<known_scene>.tscn" }`
- **Expected result:** Success. Returns the UID string (e.g. `"uid://abc123def456"`).

#### Scenario 2: Happy path — path to script file
- **Description:** Convert a script file path to its UID
- **Params:** `{ "path": "res://scripts/<known_script>.gd" }`
- **Expected result:** Success. Returns the UID for the script file.

#### Scenario 3: Happy path — path to resource file
- **Description:** Convert a resource file path to its UID
- **Params:** `{ "path": "res://assets/<known_resource>.tres" }`
- **Expected result:** Success. Returns the UID for the resource file (if UIDs are assigned to resources).

#### Scenario 4: Edge — non-existent path
- **Description:** Look up a path that does not exist
- **Params:** `{ "path": "res://nonexistent/file.tscn" }`
- **Expected result:** Error from Godot. File not found — should return meaningful error.

#### Scenario 5: Edge — empty string path
- **Description:** Call with empty string
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot. Empty path is invalid.

#### Scenario 6: Edge — path without res:// prefix
- **Description:** Call with a relative path missing the `res://` prefix
- **Params:** `{ "path": "scenes/main.tscn" }`
- **Expected result:** Error from Godot. Invalid path format — should return meaningful error.

#### Scenario 7: Edge — path with user:// prefix
- **Description:** Call with `user://` path
- **Params:** `{ "path": "user://save_data.json" }`
- **Expected result:** Error from Godot or returns no UID. `user://` paths may not have UIDs assigned.

#### Scenario 8: Edge — missing required path
- **Description:** Call without the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error. `path` is required.

#### Scenario 9: Edge — path to a directory
- **Description:** Call with a path to a directory instead of a file
- **Params:** `{ "path": "res://scenes/" }`
- **Expected result:** Error from Godot or returns no UID. Directories typically do not have UIDs.

#### Scenario 10: Edge — absolute filesystem path
- **Description:** Call with an absolute OS filesystem path instead of `res://` path
- **Params:** `{ "path": "C:\\Users\\user\\project\\scenes\\main.tscn" }`
- **Expected result:** Error from Godot. Not a valid `res://` path.

#### Scenario 11: Edge — path with special characters
- **Description:** Call with special characters in path
- **Params:** `{ "path": "res://scenes/<script>alert(1)</script>.tscn" }`
- **Expected result:** Error from Godot (file not found). Should not cause security issues.

#### Scenario 12: Edge — path with spaces
- **Description:** Call with a path containing spaces
- **Params:** `{ "path": "res://scenes/my scene.tscn" }`
- **Expected result:** Success if the file exists with spaces in name. Should handle URL-encoded or raw spaces correctly.

#### Scenario 13: Edge — path as number
- **Description:** Call with a number for path
- **Params:** `{ "path": 42 }`
- **Expected result:** Zod validation error. Expected string, got number.

#### Scenario 14: Edge — very long path
- **Description:** Call with an extremely long path string
- **Params:** `{ "path": "res://<very_long_path_10KB>" }`
- **Expected result:** Error from Godot or safe truncation. Should not crash.

---

## Cross-Tool Integration Scenarios

### Integration 1: UID round-trip
- **Description:** Convert a path to UID, then convert the UID back to path — should match
- **Steps:**
  1. `project_path_to_uid({ "path": "res://<known_file>.tscn" })` → get UID
  2. `uid_to_project_path({ "uid": "<uid_from_step_1>" })` → get path
- **Expected result:** The path returned in step 2 matches the original path from step 1.

### Integration 2: Settings read-back after set
- **Description:** Set a project setting, then read it back
- **Steps:**
  1. `set_project_setting({ "key": "application/config/name", "value": "TestName" })` → success
  2. `get_project_settings({ "filter": "application/config/name" })` → should include `"name": "TestName"`
- **Expected result:** The value read back matches the value set.

### Integration 3: Filesystem tree + search consistency
- **Description:** A file found via `search_files` should appear in `get_filesystem_tree` results
- **Steps:**
  1. `search_files({ "query": "<known_filename>" })` → get list of paths
  2. `get_filesystem_tree({ "path": "res://" })` → get full tree
- **Expected result:** Every path from step 1 exists at the expected location in the tree from step 2.

### Integration 4: Project info validates settings path
- **Description:** `get_project_info` returns the main scene path, and that path should be a valid file in the filesystem tree
- **Steps:**
  1. `get_project_info()` → get `main_scene` path
  2. `get_filesystem_tree({ "path": "res://" })` → verify the main_scene path exists
- **Expected result:** The main scene file exists in the filesystem tree (unless the main scene is not set).

---

## Security Considerations

| Risk | Tool(s) | Mitigation |
|---|---|---|
| Path traversal via `path` param | `get_filesystem_tree`, `project_path_to_uid` | Should reject `../` sequences; `res://` prefix is enforced by Godot |
| Key injection via `key` param | `set_project_setting` | Godot validates setting keys against known registry |
| Overly large response from tree | `get_filesystem_tree` | `max_depth` limits recursion; consider adding result size cap |
| Denial of service via deep recursion | `get_filesystem_tree` | `max_depth` default is 10; consider maximum cap on server side |
| Information disclosure via settings | `get_project_settings` | All project settings are already readable by project users; no risk |
| UID enumeration | `uid_to_project_path` | Returns only paths the user has access to; no additional risk |
