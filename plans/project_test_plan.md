# Project Tools Test Plan

**Source**: `server/src/tools/project.ts`  
**Total tools**: 7  
**Test plan generated**: 2026-07-08

---

## Table of Contents

1. [Tool: get_project_info](#tool-get_project_info)
2. [Tool: get_filesystem_tree](#tool-get_filesystem_tree)
3. [Tool: search_files](#tool-search_files)
4. [Tool: get_project_settings](#tool-get_project_settings)
5. [Tool: set_project_setting](#tool-set_project_setting)
6. [Tool: uid_to_project_path](#tool-uid_to_project_path)
7. [Tool: project_path_to_uid](#tool-project_path_to_uid)

---

## Tool: get_project_info

**Tool name**: `get_project_info`  
**Description**: Get project metadata including name, version, engine version, and main scene  
**Backend method**: `project/get_info`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| *(none)* | — | — | — | Tool takes no parameters |

### Test Scenarios

#### Scenario 1: Happy path — get project info

**Description**: Call with no params to retrieve project metadata.  
**Params**:
```json
{}
```
**Expected result**: Returns a JSON object containing project metadata fields: `name` (string, from `application/config/name`), `version` (string), `engine_version` (string, e.g. "4.7"), `main_scene` (string, path like `res://scenes/main.tscn`). Response has `content` array with `type: "text"`.  
**Notes**: Prerequisite: Godot editor must be open with a project loaded and MCP plugin active. No parameters needed.  
**Pay attention**: Verify that all fields are present in the response and contain meaningful values. If `main_scene` is not configured in `project.godot`, the field may be an empty string or null — this is acceptable.

#### Scenario 2: Happy path — verify response structure

**Description**: Verify the MCP result envelope matches the standard format.  
**Params**:
```json
{}
```
**Expected result**: Response shape is `{ content: [{ type: "text", text: "..." }] }`. The `text` field contains a JSON-serialized string of the project info object.  
**Pay attention**: Ensure that the response is not marked as `isError`. Verify that `text` is valid JSON that can be parsed back into an object.

---

## Tool: get_filesystem_tree

**Tool name**: `get_filesystem_tree`  
**Description**: Get the project filesystem tree structure  
**Backend method**: `project/get_filesystem_tree`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `string` (ResourcePath) | **Yes** | — | Root path to list from (e.g. `'res://'`) |
| `filters` | `string[]` (optional) | No | `undefined` | Array of file extensions to filter (e.g. `['gd', 'tscn']`) |
| `max_depth` | `number` (int, positive) | No | `10` | Maximum recursion depth |

### Test Scenarios

#### Scenario 1: Happy path — list root with defaults

**Description**: List the entire project tree from `res://` with default depth.  
**Params**:
```json
{
  "path": "res://"
}
```
**Expected result**: Returns a tree structure with all files and directories in the project, up to depth 10. Each entry should have name, type (file/directory), and children (for directories).  
**Notes**: Typical Godot projects have `addons/`, `scenes/`, `scripts/`, `assets/` etc.  
**Pay attention**: Verify that the tree contains the standard project directories. The root element `res://` should not be empty.

#### Scenario 2: Happy path — filter by extension

**Description**: List only `.gd` and `.tscn` files.  
**Params**:
```json
{
  "path": "res://",
  "filters": ["gd", "tscn"]
}
```
**Expected result**: Returns tree containing only files with `.gd` and `.tscn` extensions. Directories are included if they contain matching files.  
**Pay attention**: Verify that files with other extensions (`.tres`, `.png`, `.import`) are absent from the result. Dots in extensions are not specified.

#### Scenario 3: Happy path — limit depth

**Description**: List tree with explicit max_depth = 1.  
**Params**:
```json
{
  "path": "res://",
  "max_depth": 1
}
```
**Expected result**: Only top-level entries under `res://` are returned. No subdirectory contents beyond depth 1.  
**Pay attention**: Verify that subdirectories (e.g. `res://addons/`) are present as entries but their contents are not expanded.

#### Scenario 4: Happy path — list subdirectory

**Description**: List a specific subdirectory instead of root.  
**Params**:
```json
{
  "path": "res://addons"
}
```
**Expected result**: Returns tree rooted at `res://addons/`, showing only addon subdirectories and their contents (up to default depth 10).  
**Pay attention**: Verify that `addons/godot_mcp/` is present in the tree if the plugin is installed.

#### Scenario 5: Edge case — missing required `path`

**Description**: Omit the required `path` parameter.  
**Params**:
```json
{
  "max_depth": 5
}
```
**Expected result**: Validation error — `path` is required. MCP server should return an error response.  
**Pay attention**: Verify that the error contains a mention of the required parameter `path`.

#### Scenario 6: Edge case — invalid path (not res://)

**Description**: Pass a path that doesn't start with `res://`.  
**Params**:
```json
{
  "path": "/home/user/project"
}
```
**Expected result**: Either a Godot-side error (invalid path format) or empty result.  
**Pay attention**: Godot expects `res://` paths. Absolute OS paths should be handled gracefully without crashing the server.

#### Scenario 7: Edge case — max_depth = 0

**Description**: Zero depth should return error (must be positive).  
**Params**:
```json
{
  "path": "res://",
  "max_depth": 0
}
```
**Expected result**: Zod validation error — `z.number().int().positive()` rejects 0.  
**Pay attention**: Verify that a validation error is returned rather than an empty result.

#### Scenario 8: Edge case — empty filters array

**Description**: Pass empty filters array — should behave like no filters.  
**Params**:
```json
{
  "path": "res://",
  "filters": []
}
```
**Expected result**: Returns all files (empty filter list = no filtering).  
**Pay attention**: Verify that an empty filters array does not break the logic and is equivalent to omitting the parameter.

---

## Tool: search_files

**Tool name**: `search_files`  
**Description**: Search for files in the project by name pattern or content  
**Backend method**: `project/search_files`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `query` | `string` (SearchQuery) | **Yes** | — | Search query string |

### Test Scenarios

#### Scenario 1: Happy path — search by filename

**Description**: Search for files matching a filename pattern.  
**Params**:
```json
{
  "query": "player"
}
```
**Expected result**: Returns list of files whose name or path contains "player" (e.g. `player.gd`, `player.tscn`, `PlayerSprite2D.tscn`).  
**Pay attention**: Verify that the search is case-insensitive (or document if it is case-sensitive). Results should contain file paths.

#### Scenario 2: Happy path — search by content

**Description**: Search for files containing specific text content.  
**Params**:
```json
{
  "query": "func _ready"
}
```
**Expected result**: Returns files containing the text `func _ready` — likely all GDScript files with `_ready()` function.  
**Pay attention**: Verify that content search works for GDScript files. The result may be large for a typical project.

#### Scenario 3: Happy path — search by extension

**Description**: Search for files by extension pattern.  
**Params**:
```json
{
  "query": ".tscn"
}
```
**Expected result**: Returns all `.tscn` scene files in the project.  
**Pay attention**: Verify that only `.tscn` files and their paths are returned.

#### Scenario 4: Edge case — missing required `query`

**Description**: Omit the required `query` parameter.  
**Params**:
```json
{}
```
**Expected result**: Validation error — `query` is required.  
**Pay attention**: Verify that the validation error is correctly returned.

#### Scenario 5: Edge case — empty query string

**Description**: Empty string as query — behavior depends on backend.  
**Params**:
```json
{
  "query": ""
}
```
**Expected result**: Either returns all files (match everything) or an error. Document actual behavior.  
**Pay attention**: Verify how an empty string is handled — whether it crashes the Godot-side handler.

#### Scenario 6: Edge case — special characters in query

**Description**: Query with regex-special characters.  
**Params**:
```json
{
  "query": "node[0].position"
}
```
**Expected result**: Search should treat the query as a literal string, not regex. Returns files containing that exact text, or an error if the backend uses regex.  
**Pay attention**: Verify that special characters `[`, `]`, `.` do not break the search. If the backend uses regex, it may return a regex syntax error.

---

## Tool: get_project_settings

**Tool name**: `get_project_settings`  
**Description**: Get all project settings (project.godot values)  
**Backend method**: `project/get_settings`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `filter` | `string` (optional) | No | `undefined` | Prefix filter for settings (e.g. `'application/'`) |

### Test Scenarios

#### Scenario 1: Happy path — get all settings

**Description**: Get all project settings without filter.  
**Params**:
```json
{}
```
**Expected result**: Returns all project settings from `project.godot` as a key-value object. Keys are Godot setting paths like `application/config/name`, `display/window/size/viewport_width`, etc.  
**Pay attention**: Verify that a full set of settings is returned. The object can be very large for a typical project.

#### Scenario 2: Happy path — filter by prefix

**Description**: Get only settings under `application/` prefix.  
**Params**:
```json
{
  "filter": "application/"
}
```
**Expected result**: Returns only settings whose key starts with `application/` (e.g. `application/config/name`, `application/config/version`, `application/run/main_scene`).  
**Pay attention**: Verify that all keys in the result start with `application/`. Settings from other sections (`display/`, `rendering/`) should not be included.

#### Scenario 3: Happy path — filter by specific section

**Description**: Filter by `display/window/` prefix.  
**Params**:
```json
{
  "filter": "display/window/"
}
```
**Expected result**: Returns only window-related settings like `display/window/size/viewport_width`, `display/window/size/viewport_height`, `display/window/stretch/mode`.  
**Pay attention**: Verify that the result contains only window settings, not other `display/` settings.

#### Scenario 4: Edge case — filter with no matches

**Description**: Filter by a prefix that doesn't exist.  
**Params**:
```json
{
  "filter": "nonexistent_section/"
}
```
**Expected result**: Returns empty object `{}` or empty array — no settings match.  
**Pay attention**: Verify that an empty result is not marked as an error (`isError` should not be `true`).

#### Scenario 5: Edge case — filter without trailing slash

**Description**: Filter without trailing slash — may or may not match.  
**Params**:
```json
{
  "filter": "application"
}
```
**Expected result**: Depends on backend implementation. May return settings starting with `application` (including `application/` prefix) or nothing if it does prefix matching with exact path segments. Document actual behavior.  
**Pay attention**: Verify the behavior — some implementations require a trailing `/` for correct filtering.

---

## Tool: set_project_setting

**Tool name**: `set_project_setting`  
**Description**: Set a project setting value  
**Backend method**: `project/set_setting`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `key` | `string` | **Yes** | — | Setting key (e.g. `'display/window/size/viewport_width'`) |
| `value` | `unknown` | **Yes** | — | New value for the setting (string, number, boolean, etc.) |

### Test Scenarios

#### Scenario 1: Happy path — set a string value

**Description**: Set the project name.  
**Params**:
```json
{
  "key": "application/config/name",
  "value": "My Test Game"
}
```
**Expected result**: Setting is updated successfully. Response confirms the change. The value persists in `project.godot`.  
**Notes**: Prerequisite: Godot editor must be open. The change goes through Godot's undo system.  
**Pay attention**: Verify that the setting was actually written — you can call `get_project_settings` with filter `application/` to verify. After the test, restore the original value.

#### Scenario 2: Happy path — set a numeric value

**Description**: Set viewport width to a numeric value.  
**Params**:
```json
{
  "key": "display/window/size/viewport_width",
  "value": 1920
}
```
**Expected result**: Setting updated. `viewport_width` is now 1920.  
**Pay attention**: Numeric values should be passed as numbers, not strings. Verify that `"1920"` (string) also works or is correctly converted.

#### Scenario 3: Happy path — set a boolean value

**Description**: Set a boolean setting.  
**Params**:
```json
{
  "key": "display/window/stretch/aspect",
  "value": "keep"
}
```
**Expected result**: Setting updated to the new value.  
**Pay attention**: Verify that the value is written correctly and is reflected when read again.

#### Scenario 4: Edge case — missing required `key`

**Description**: Omit the `key` parameter.  
**Params**:
```json
{
  "value": "test"
}
```
**Expected result**: Validation error — `key` is required.  
**Pay attention**: Verify that the validation error is correctly reported.

#### Scenario 5: Edge case — missing required `value`

**Description**: Omit the `value` parameter.  
**Params**:
```json
{
  "key": "application/config/name"
}
```
**Expected result**: Validation error — `value` is required.  
**Pay attention**: Verify that missing `value` is handled and does not write `undefined` or `null`.

#### Scenario 6: Edge case — invalid key (non-existent path)

**Description**: Set a setting key that doesn't correspond to any known Godot setting.  
**Params**:
```json
{
  "key": "custom/nonexistent/setting",
  "value": "test_value"
}
```
**Expected result**: Godot may accept it (custom settings are allowed) or may return an error. Document actual behavior.  
**Pay attention**: Godot allows creating custom settings. Verify whether a new setting is created or the backend rejects unknown keys.

#### Scenario 7: Edge case — set value to null

**Description**: Set a value to null to potentially reset/delete it.  
**Params**:
```json
{
  "key": "application/config/name",
  "value": null
}
```
**Expected result**: Behavior depends on Godot backend. May reset to default, delete the setting, or error.  
**Pay attention**: Verify how Godot handles null — whether it crashes the editor.

**Related tools**: 
- Use `get_project_settings` before to capture the original value
- Use `get_project_settings` after to verify the change was applied
- Always restore original values after testing to avoid polluting the project

---

## Tool: uid_to_project_path

**Tool name**: `uid_to_project_path`  
**Description**: Convert a Godot UID to a project file path  
**Backend method**: `project/uid_to_path`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `uid` | `string` | **Yes** | — | The UID to look up (e.g. `'uid://abc123'`) |

### Test Scenarios

#### Scenario 1: Happy path — convert known UID

**Description**: Convert a UID of a known project file.  
**Params**:
```json
{
  "uid": "uid://c5uab4k3u7qmr"
}
```
**Expected result**: Returns the corresponding project file path (e.g. `res://scenes/main.tscn`).  
**Notes**: The exact UID value depends on the test project. First use `project_path_to_uid` on a known file to get a valid UID, then test the reverse lookup.  
**Pay attention**: Verify that a correct `res://` path is returned. UIDs should be unique within the project.

#### Scenario 2: Edge case — non-existent UID

**Description**: Pass a UID that doesn't exist in the project.  
**Params**:
```json
{
  "uid": "uid://nonexistent123"
}
```
**Expected result**: Error response indicating UID not found, or null/empty result.  
**Pay attention**: Verify that a non-existent UID does not crash the backend and returns a meaningful error.

#### Scenario 3: Edge case — missing required `uid`

**Description**: Omit the `uid` parameter.  
**Params**:
```json
{}
```
**Expected result**: Validation error — `uid` is required.  
**Pay attention**: Verify the correctness of the error message.

#### Scenario 4: Edge case — malformed UID format

**Description**: Pass a UID string without the `uid://` prefix.  
**Params**:
```json
{
  "uid": "abc123"
}
```
**Expected result**: Error — UID should have `uid://` prefix. Or the backend may attempt lookup and fail.  
**Pay attention**: Verify how the absence of the `uid://` prefix is handled.

---

## Tool: project_path_to_uid

**Tool name**: `project_path_to_uid`  
**Description**: Convert a project file path to its UID  
**Backend method**: `project/path_to_uid`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `string` (ResourcePath) | **Yes** | — | The project path (e.g. `'res://scenes/main.tscn'`) |

### Test Scenarios

#### Scenario 1: Happy path — convert known file path

**Description**: Convert a known project file path to its UID.  
**Params**:
```json
{
  "path": "res://project.godot"
}
```
**Expected result**: Returns a UID string in the format `uid://...` (e.g. `uid://c5uab4k3u7qmr`).  
**Pay attention**: Verify that a string in the format `uid://...` is returned. UIDs should be stable across calls for the same file.

#### Scenario 2: Happy path — convert scene file

**Description**: Convert a scene file path to UID.  
**Params**:
```json
{
  "path": "res://scenes/main.tscn"
}
```
**Expected result**: Returns UID string.  
**Pay attention**: Verify that the UID format is correct (starts with `uid://`).

#### Scenario 3: Edge case — non-existent file path

**Description**: Pass a path to a file that doesn't exist.  
**Params**:
```json
{
  "path": "res://nonexistent/file.tscn"
}
```
**Expected result**: Error — file not found.  
**Pay attention**: Verify that a non-existent file returns an error rather than silently generating a fake UID.

#### Scenario 4: Edge case — missing required `path`

**Description**: Omit the `path` parameter.  
**Params**:
```json
{}
```
**Expected result**: Validation error — `path` is required.  
**Pay attention**: Verify the correctness of the validation.

#### Scenario 5: Edge case — path without res:// prefix

**Description**: Pass a path without the `res://` prefix.  
**Params**:
```json
{
  "path": "scenes/main.tscn"
}
```
**Expected result**: Error — Godot paths must start with `res://`.  
**Pay attention**: Verify that the backend rejects paths without `res://` and returns a meaningful error.

---

## Cross-Tool Dependencies and Sequences

### Round-trip UID conversion

To fully test UID tools, use them as a pair:

1. Call `project_path_to_uid` with a known path → get UID
2. Call `uid_to_project_path` with that UID → should return the original path
3. Assert the round-trip produces the original path

**Sequence**:
```json
// Step 1
{ "tool": "project_path_to_uid", "params": { "path": "res://project.godot" } }
// → save returned UID

// Step 2
{ "tool": "uid_to_project_path", "params": { "uid": "<saved_uid>" } }
// → expect "res://project.godot"
```

### Settings read-write verification

To test `set_project_setting`:

1. Call `get_project_settings` with filter to capture original value
2. Call `set_project_setting` to change the value
3. Call `get_project_settings` again to verify the change
4. Call `set_project_setting` to restore the original value

### Filesystem exploration workflow

A typical project exploration flow:

1. Call `get_project_info` to identify the project
2. Call `get_filesystem_tree` with `path: "res://"` to see the structure
3. Call `search_files` to find specific files by name or content
4. Call `project_path_to_uid` on interesting files to get their UIDs