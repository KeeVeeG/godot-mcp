# Project Tools Test Plan

> **Source file:** `server/src/tools/project.ts`  
> **Shared types:** `server/src/tools/shared-types.ts`  
> **Tools covered:** 7 (`get_project_info`, `get_filesystem_tree`, `search_files`, `get_project_settings`, `set_project_setting`, `uid_to_project_path`, `project_path_to_uid`)  
> **Generated:** 2026-07-08

---

## Schema Details

### Shared Imports

| Import | Zod Schema | Description |
|--------|-----------|-------------|
| `ResourcePath` | `z.string()` | Resource file path (e.g. `'res://assets/theme.tres'`) |
| `SearchQuery` | `z.string()` | Search query string |
| `z` | Zod namespace | Used directly for `z.string()`, `z.number()`, `z.array()`, `z.unknown()` |

### Parameter Summary

| Tool | Param | Type | Required | Default | Enum/Choices | Notes |
|------|-------|------|----------|---------|--------------|-------|
| `get_project_info` | *(none)* | — | — | — | — | Takes no input |
| `get_filesystem_tree` | `path` | `string` | ✅ yes | — | — | Root path, e.g. `res://` |
| | `filters` | `string[]` | no | — | — | File extensions, e.g. `["gd", "tscn"]` |
| | `max_depth` | `number` (int, positive) | no | `10` | — | Max recursion depth |
| `search_files` | `query` | `string` | ✅ yes | — | — | Name pattern or content query |
| `get_project_settings` | `filter` | `string` | no | — | — | Prefix filter, e.g. `"application/"` |
| `set_project_setting` | `key` | `string` | ✅ yes | — | — | Setting key path |
| | `value` | `unknown` | ✅ yes | — | — | Any JSON-serializable value |
| `uid_to_project_path` | `uid` | `string` | ✅ yes | — | — | UID, e.g. `"uid://abc123"` |
| `project_path_to_uid` | `path` | `string` | ✅ yes | — | — | Project path, e.g. `"res://scenes/main.tscn"` |

---

## Tool: get_project_info

### Schema

```typescript
{
  description: 'Get project metadata including name, version, engine version, and main scene',
  inputSchema: {},
}
```

### Handler

```typescript
async () => callGodot(bridge, 'project/get_info')
```

### Tool Behavior
Queries the Godot project for basic metadata: project name, version string, Godot engine version, and the configured main scene path. Takes no input parameters and is purely read-only.

### Test Scenarios

#### Scenario 1: Basic happy path — get project info
- **Description:** Call `get_project_info` on an open project to retrieve metadata.
- **Params:** `{}` (empty object)
- **Expected result:** Returns a JSON object with at minimum `name`, `version`, `engine_version`, and `main_scene` fields. Values should reflect the actual project.
- **Notes:** This is the simplest smoke test for the project tools category. If this fails, the Godot bridge is likely not connected.

#### Scenario 2: Call with unexpected extra params
- **Description:** Verify the tool ignores extraneous parameters since `inputSchema` is empty.
- **Params:** `{ "foo": "bar", "extra": 42 }`
- **Expected result:** Should succeed identically to Scenario 1. Zod strips unknown keys from an empty schema.
- **Notes:** Tests robustness against clients that may send extra fields.

#### Scenario 3: Call with null/undefined args
- **Description:** Call the tool with no arguments object at all.
- **Params:** `undefined` (or omit entirely)
- **Expected result:** Should succeed. The empty schema accepts any input including undefined.
- **Notes:** Validates the handler can handle a missing args object.

#### Scenario 4: Verify returned fields are non-empty
- **Description:** Check that each expected metadata field contains a meaningful value.
- **Params:** `{}`
- **Expected result:** `name` should be a non-empty string, `version` should be a non-empty string, `engine_version` should look like `"4.x"`, `main_scene` should be a `res://` path or empty string.
- **Notes:** If `main_scene` is empty, the project has no main scene configured — that's valid but worth noting.

---

## Tool: get_filesystem_tree

### Schema

```typescript
{
  description: 'Get the project filesystem tree structure',
  inputSchema: {
    path: ResourcePath.describe("Root path to list from (e.g. 'res://')"),
    filters: z.array(z.string()).optional().describe(
      "Array of file extensions to filter (e.g. ['gd', 'tscn'])"
    ),
    max_depth: z.number().int().positive().optional().default(10).describe(
      'Maximum recursion depth (default: 10)'
    ),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'project/get_filesystem_tree', args as Record<string, unknown>)
```

### Tool Behavior
Recursively lists the project's filesystem starting from a given root path. Supports filtering by file extension and limiting recursion depth. Returns a tree structure (array of entries with name, type, path, and optional children).

### Test Scenarios

#### Scenario 1: Happy path — list root with defaults
- **Description:** Get the filesystem tree from the project root with default max_depth (10).
- **Params:** `{ "path": "res://" }`
- **Expected result:** Returns a tree structure of files and directories under `res://`. Should include common directories like `scenes/`, `scripts/`, and the `project.godot` file at the root level. Array entries should have `name`, `type` (`"file"` or `"dir"`), and `path` fields.
- **Notes:** This is the primary filesystem browsing tool. The result should be well-structured JSON.

#### Scenario 2: Happy path — list with extension filters
- **Description:** List only `.gd` (script) files from the root.
- **Params:** `{ "path": "res://", "filters": ["gd"] }`
- **Expected result:** Returns only entries with `.gd` extension. Directories should still appear (they contain the filtered files). No `.tscn`, `.tres`, or other file types should appear as leaf entries.
- **Notes:** Filters apply to file extensions only; directories are not filtered.

#### Scenario 3: Happy path — list with multiple extension filters
- **Description:** List both `.gd` and `.tscn` files from root.
- **Params:** `{ "path": "res://", "filters": ["gd", "tscn"] }`
- **Expected result:** Returns entries with `.gd` and `.tscn` extensions only. No `.tres`, `.png`, or other file types.
- **Notes:** Validates that multiple filters work together (OR logic).

#### Scenario 4: Happy path — shallow depth (max_depth=1)
- **Description:** List only the top-level entries, no recursion.
- **Params:** `{ "path": "res://", "max_depth": 1 }`
- **Expected result:** Returns only direct children of `res://`. Directory entries should NOT have `children` populated (or children should be empty). Total depth of any entry should be 1.
- **Notes:** Tests the recursion depth limit. Depth 1 means only immediate children.

#### Scenario 5: Happy path — deep recursion (max_depth=50)
- **Description:** List filesystem with a high depth limit.
- **Params:** `{ "path": "res://", "max_depth": 50 }`
- **Expected result:** Returns the full tree recursively (up to 50 levels). Should include deeply nested files.
- **Notes:** Tests that the positive integer constraint works for large values. Should not cause performance issues on typical projects.

#### Scenario 6: Happy path — list a subdirectory
- **Description:** List the tree starting from a specific subdirectory.
- **Params:** `{ "path": "res://scenes" }`
- **Expected result:** Returns tree entries rooted at `res://scenes/`. Only files and directories within `scenes/` should appear.
- **Notes:** The path must exist. If no `scenes/` directory exists in the project, this will error.

#### Scenario 7: Happy path — filters with max_depth combination
- **Description:** List `.gd` files only, with depth of 3.
- **Params:** `{ "path": "res://", "filters": ["gd"], "max_depth": 3 }`
- **Expected result:** Returns only `.gd` files at depths 1–3 from the root.
- **Notes:** Tests that both optional params work together correctly.

#### Scenario 8: Missing required parameter — path
- **Description:** Call without the required `path` parameter.
- **Params:** `{}` or `{ "max_depth": 5 }`
- **Expected result:** Zod validation error. Should report that `path` is required.
- **Notes:** `path` is the only required field.

#### Scenario 9: Invalid type — max_depth as string
- **Description:** Pass a string for `max_depth` instead of a number.
- **Params:** `{ "path": "res://", "max_depth": "five" }`
- **Expected result:** Zod validation error. Should report expected number, received string.
- **Notes:** `max_depth` is typed as `z.number().int().positive()`.

#### Scenario 10: Invalid value — max_depth ≤ 0
- **Description:** Pass a non-positive integer for `max_depth`.
- **Params:** `{ "path": "res://", "max_depth": 0 }`
- **Expected result:** Zod validation error. `z.number().positive()` rejects 0 and negative numbers.
- **Notes:** Validates the `positive()` constraint.

#### Scenario 11: Invalid value — max_depth negative
- **Description:** Pass a negative integer for `max_depth`.
- **Params:** `{ "path": "res://", "max_depth": -1 }`
- **Expected result:** Zod validation error. Negative numbers are not positive.
- **Notes:** Validates the `positive()` constraint.

#### Scenario 12: Invalid value — max_depth as float
- **Description:** Pass a non-integer number for `max_depth`.
- **Params:** `{ "path": "res://", "max_depth": 2.5 }`
- **Expected result:** Zod validation error. `z.number().int()` rejects non-integer numbers.
- **Notes:** Validates the `int()` constraint.

#### Scenario 13: Invalid path — non-res:// prefix
- **Description:** Pass a path that does not start with `res://`.
- **Params:** `{ "path": "C:/some/path" }`
- **Expected result:** The tool may forward the request; expected behavior is a Godot-side error about invalid resource path, or an empty result.
- **Notes:** The server does not validate path format beyond the string type. The Godot plugin should reject invalid paths.

#### Scenario 14: Invalid path — non-existent directory
- **Description:** Pass a path to a directory that does not exist.
- **Params:** `{ "path": "res://nonexistent_dir" }`
- **Expected result:** Godot-side error indicating the path does not exist, or an empty tree.
- **Notes:** Tests error handling for missing directories.

#### Scenario 15: Empty filters array
- **Description:** Pass an empty array for `filters`.
- **Params:** `{ "path": "res://", "filters": [] }`
- **Expected result:** Should behave identically to not passing `filters` at all — returns all files unfiltered.
- **Notes:** An empty filter array should mean "no filtering."

#### Scenario 16: Filters with invalid extension format
- **Description:** Pass file extensions with leading dots.
- **Params:** `{ "path": "res://", "filters": [".gd", ".tscn"] }`
- **Expected result:** Depends on Godot implementation. Either no files match (strict matching) or the dots are stripped. Most likely no files will match since extensions in Godot are stored without dots.
- **Notes:** Tests whether the Godot plugin handles dot-prefixed extensions gracefully.

---

## Tool: search_files

### Schema

```typescript
{
  description: 'Search for files in the project by name pattern or content',
  inputSchema: {
    query: SearchQuery,
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'project/search_files', args as Record<string, unknown>)
```

### Tool Behavior
Performs a search across the project filesystem for files matching a name pattern or containing specific content. The `query` parameter is a free-text search string that the Godot plugin interprets (likely as a filename substring match or a content grep depending on implementation).

### Test Scenarios

#### Scenario 1: Happy path — search by filename
- **Description:** Search for files with a common filename pattern.
- **Params:** `{ "query": "player" }`
- **Expected result:** Returns a list of file paths in the project whose names contain "player" (e.g., `res://scenes/player.tscn`, `res://scripts/player.gd`). Result should be an array of matching file paths or file objects.
- **Notes:** The exact matching behavior depends on the Godot plugin implementation. Result format should be consistent with other project tools.

#### Scenario 2: Happy path — search by file extension
- **Description:** Search for files with a specific extension.
- **Params:** `{ "query": ".gd" }`
- **Expected result:** Returns all `.gd` script files in the project. Should be a superset of `get_filesystem_tree` with `filters: ["gd"]`.
- **Notes:** The query string can be used for extension-based search.

#### Scenario 3: Happy path — search by full filename
- **Description:** Search for a specific known file.
- **Params:** `{ "query": "project.godot" }`
- **Expected result:** Should return a result containing `res://project.godot` (or the full path to it).
- **Notes:** Tests exact-match capability. Every Godot project has a `project.godot` file at the root.

#### Scenario 4: Happy path — search with no matches
- **Description:** Search for a string that does not exist in any filename.
- **Params:** `{ "query": "zzz_nonexistent_file_xyz" }`
- **Expected result:** Returns an empty array or a response indicating no matches found. Should NOT error.
- **Notes:** Validates that the tool handles zero results gracefully.

#### Scenario 5: Happy path — search with special characters
- **Description:** Search using a query with special regex characters to test whether it is treated as literal.
- **Params:** `{ "query": "test*" }`
- **Expected result:** Depends on implementation — either literal match for files containing "test*" in the name, or a pattern match. Should not crash.
- **Notes:** Tests robustness against special characters. If the Godot plugin uses regex, `*` would be a wildcard.

#### Scenario 6: Happy path — search with empty string
- **Description:** Search with an empty query string.
- **Params:** `{ "query": "" }`
- **Expected result:** Depends on implementation. Either returns ALL files in the project, or returns an empty result set. Should not error.
- **Notes:** An empty string is a valid Zod string. The Godot plugin decides the behavior.

#### Scenario 7: Happy path — search with whitespace-only query
- **Description:** Search with a query containing only whitespace.
- **Params:** `{ "query": "   " }`
- **Expected result:** Depends on implementation. Likely returns an empty result set or all files. Should not error.
- **Notes:** Tests whitespace handling.

#### Scenario 8: Missing required parameter — query
- **Description:** Call `search_files` without the required `query` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error. Should report that `query` is required.
- **Notes:** `SearchQuery` is not optional — it is required.

#### Scenario 9: Invalid type — query as number
- **Description:** Pass a number instead of a string for `query`.
- **Params:** `{ "query": 12345 }`
- **Expected result:** Zod validation error. Should report expected string, received number.
- **Notes:** `SearchQuery` is `z.string()`, so non-string values are rejected.

#### Scenario 10: Invalid type — query as object
- **Description:** Pass an object for `query`.
- **Params:** `{ "query": { "pattern": "player" } }`
- **Expected result:** Zod validation error. Should report expected string, received object.
- **Notes:** Tests that complex types are rejected for a simple string parameter.

---

## Tool: get_project_settings

### Schema

```typescript
{
  description: 'Get all project settings (project.godot values)',
  inputSchema: {
    filter: z.string().optional().describe(
      "Prefix filter for settings (e.g. 'application/')"
    ),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'project/get_settings', args as Record<string, unknown>)
```

### Tool Behavior
Reads the project's settings from `project.godot`. Without a filter, returns ALL project settings. With an optional `filter` prefix, only settings whose keys start with that prefix are returned.

### Test Scenarios

#### Scenario 1: Happy path — get all settings (no filter)
- **Description:** Retrieve all project settings without any filter.
- **Params:** `{}`
- **Expected result:** Returns a large JSON object containing all project settings as key-value pairs. Should include well-known keys like `application/config/name`, `application/config/version`, `display/window/size/viewport_width`, etc.
- **Notes:** This may return a very large object. The response should still be well-formed JSON.

#### Scenario 2: Happy path — filter by application prefix
- **Description:** Retrieve only application-related settings.
- **Params:** `{ "filter": "application/" }`
- **Expected result:** Returns only settings whose keys start with `application/`. Should include `application/config/name`, `application/config/version`, etc. Should NOT include `display/` or `input/` settings.
- **Notes:** Tests prefix filtering. The trailing slash is part of the filter string.

#### Scenario 3: Happy path — filter by display prefix
- **Description:** Retrieve only display/window settings.
- **Params:** `{ "filter": "display/" }`
- **Expected result:** Returns only settings under `display/`. Should include viewport dimensions, window size, stretch settings. Should NOT include `application/` or `input/` settings.
- **Notes:** Validates that different prefix filters return disjoint result sets.

#### Scenario 4: Happy path — filter by input prefix
- **Description:** Retrieve only input-related settings.
- **Params:** `{ "filter": "input/" }`
- **Expected result:** Returns settings under `input/` prefix (e.g., input map entries, deadzone settings).
- **Notes:** Tests yet another prefix category.

#### Scenario 5: Happy path — filter with no trailing slash
- **Description:** Filter without a trailing slash in the prefix.
- **Params:** `{ "filter": "application" }`
- **Expected result:** Depends on the Godot implementation. Either matches `application/` settings (prefix match), or matches nothing (exact prefix). Should not error.
- **Notes:** Tests whether the filter requires a trailing slash for proper matching. The description example uses `'application/'`.

#### Scenario 6: Happy path — filter matching exactly one setting
- **Description:** Use a very specific filter that matches a single setting key.
- **Params:** `{ "filter": "application/config/name" }`
- **Expected result:** Returns a single entry with the project name. Only settings starting with `application/config/name` — typically just `application/config/name` itself.
- **Notes:** Tests narrow filtering. May also match `application/config/name_localized` if it exists.

#### Scenario 7: Happy path — filter with no matches
- **Description:** Use a filter prefix that doesn't match any setting.
- **Params:** `{ "filter": "nonexistent_prefix/" }`
- **Expected result:** Returns an empty object `{}` or empty array. Should NOT error.
- **Notes:** Validates that the tool handles zero-match scenarios gracefully.

#### Scenario 8: Happy path — call with empty object (no params)
- **Description:** Call with an explicit empty object (same as Scenario 1).
- **Params:** `{}`
- **Expected result:** Should succeed and return all settings. Identical to Scenario 1.
- **Notes:** Redundant with Scenario 1 — included for completeness of parameter variations.

#### Scenario 9: Invalid type — filter as number
- **Description:** Pass a number for the `filter` parameter.
- **Params:** `{ "filter": 42 }`
- **Expected result:** Zod validation error. Should report expected string, received number.
- **Notes:** `filter` is `z.string().optional()`.

#### Scenario 10: Happy path — filter with uppercase characters
- **Description:** Use uppercase in the filter string (Godot settings are lowercase by convention).
- **Params:** `{ "filter": "APPLICATION/" }`
- **Expected result:** Likely returns an empty result since Godot setting keys are lowercase. Should not error.
- **Notes:** Tests case sensitivity of the filter. Godot setting keys are case-sensitive.

---

## Tool: set_project_setting

### Schema

```typescript
{
  description: 'Set a project setting value',
  inputSchema: {
    key: z.string().describe(
      "Setting key (e.g. 'display/window/size/viewport_width')"
    ),
    value: z.unknown().describe(
      'New value for the setting (string, number, boolean, etc.)'
    ),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'project/set_setting', args as Record<string, unknown>)
```

### Tool Behavior
Sets a single project setting by its full key path to a new value. The value can be any JSON-serializable type (string, number, boolean, array, object) depending on what the setting expects. The change is written to `project.godot`.

### Test Scenarios

#### Scenario 1: Happy path — set a string setting
- **Description:** Change the project name via the application config setting.
- **Params:** `{ "key": "application/config/name", "value": "TestProject" }`
- **Expected result:** Returns success. Calling `get_project_settings` with `filter: "application/config/name"` afterwards should show the updated value.
- **Notes:** This is a benign setting change. The project name is a string.

#### Scenario 2: Happy path — set a numeric setting
- **Description:** Change a viewport dimension.
- **Params:** `{ "key": "display/window/size/viewport_width", "value": 1280 }`
- **Expected result:** Returns success. The viewport width setting should be updated to 1280.
- **Notes:** Tests setting an integer value. Should be able to `set_project_setting` + `get_project_settings` to verify.

#### Scenario 3: Happy path — set a boolean setting
- **Description:** Change a boolean project setting.
- **Params:** `{ "key": "application/config/use_custom_user_dir", "value": true }`
- **Expected result:** Returns success. The boolean setting should be updated.
- **Notes:** Tests boolean value handling. Both `true` and `false` should work.

#### Scenario 4: Happy path — set boolean to false
- **Description:** Set a boolean setting to `false`.
- **Params:** `{ "key": "application/config/use_custom_user_dir", "value": false }`
- **Expected result:** Returns success.
- **Notes:** Explicitly tests `false` to ensure it's not coerced to truthy.

#### Scenario 5: Happy path — set a string number (as string)
- **Description:** Pass a numeric-looking value as a string.
- **Params:** `{ "key": "display/window/size/viewport_width", "value": "1280" }`
- **Expected result:** Depends on Godot implementation. Either coerces the string to a number (success) or rejects the type mismatch (error). Should not crash the server.
- **Notes:** Tests type coercion behavior. `z.unknown()` accepts any value; the Godot plugin decides validity.

#### Scenario 6: Missing required parameter — key
- **Description:** Call without the required `key` parameter.
- **Params:** `{ "value": "some_value" }`
- **Expected result:** Zod validation error. Should report that `key` is required.
- **Notes:** `key` is required (`z.string()` without `.optional()`).

#### Scenario 7: Missing required parameter — value
- **Description:** Call without the required `value` parameter.
- **Params:** `{ "key": "application/config/name" }`
- **Expected result:** Zod validation error. Should report that `value` is required.
- **Notes:** `value` is required (`z.unknown()` without `.optional()`).

#### Scenario 8: Missing both required parameters
- **Description:** Call with empty object.
- **Params:** `{}`
- **Expected result:** Zod validation error for both missing `key` and `value`.
- **Notes:** Both are required, so both should be reported.

#### Scenario 9: Invalid key — non-existent setting path
- **Description:** Try to set a setting key that does not exist.
- **Params:** `{ "key": "nonexistent/setting/path", "value": "test" }`
- **Expected result:** Godot-side error about unknown setting, or the setting is created as a custom setting. Should not crash.
- **Notes:** Some Godot versions allow creating custom settings, others reject unknown keys.

#### Scenario 10: Invalid value type — wrong type for setting
- **Description:** Pass a string where a number is expected.
- **Params:** `{ "key": "display/window/size/viewport_width", "value": "not_a_number" }`
- **Expected result:** Zod passes (value is `unknown`). Godot plugin should reject the type mismatch. Should not crash the server.
- **Notes:** The server defers type checking to the Godot plugin.

#### Scenario 11: Value as null
- **Description:** Pass `null` as the value.
- **Params:** `{ "key": "application/config/name", "value": null }`
- **Expected result:** Depends on Godot. Either sets the value to null (if supported), rejects null, or resets to default. Should not crash.
- **Notes:** `z.unknown()` accepts `null`.

#### Scenario 12: Value as complex object
- **Description:** Pass a nested object as the value.
- **Params:** `{ "key": "application/config/name", "value": { "nested": { "deep": "value" } } }`
- **Expected result:** Godot-side error — project setting values are typically scalar (string, number, bool) or simple arrays. Should not crash the server.
- **Notes:** Tests that complex values are either handled or rejected cleanly.

#### Scenario 13: Empty key string
- **Description:** Pass an empty string as the key.
- **Params:** `{ "key": "", "value": "test" }`
- **Expected result:** Godot-side error — empty key is invalid. Should not crash.
- **Notes:** `z.string()` accepts empty strings. The Godot plugin should reject it.

#### Scenario 14: Key with only whitespace
- **Description:** Pass a whitespace-only string as the key.
- **Params:** `{ "key": "   ", "value": "test" }`
- **Expected result:** Godot-side error — invalid key. Should not crash.
- **Notes:** Tests whitespace handling in keys.

---

## Tool: uid_to_project_path

### Schema

```typescript
{
  description: 'Convert a Godot UID to a project file path',
  inputSchema: {
    uid: z.string().describe("The UID to look up (e.g. 'uid://abc123')"),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'project/uid_to_path', args as Record<string, unknown>)
```

### Tool Behavior
Converts a Godot resource UID (e.g., `uid://abc123def456`) to its corresponding project file path (e.g., `res://scenes/main.tscn`). UIDs are unique identifiers for resources in Godot 4.x.

### Test Scenarios

#### Scenario 1: Happy path — convert a known UID to path
- **Description:** Convert a valid, existing UID to its file path. First use `get_filesystem_tree` or `project_path_to_uid` to obtain a known UID, then test `uid_to_project_path` with it.
- **Params:** `{ "uid": "<known-uid-from-project>" }`
- **Expected result:** Returns the `res://` path corresponding to the given UID. The path should be a valid project file path.
- **Notes:** Requires at least one file in the project with a known UID. Use `project_path_to_uid` to get a UID first, then test this tool with it.

#### Scenario 2: Happy path — convert a non-existent UID
- **Description:** Try to convert a UID that does not exist in the project.
- **Params:** `{ "uid": "uid://nonexistent123456" }`
- **Expected result:** Godot-side error indicating UID not found, or an empty/null result. Should not crash the server.
- **Notes:** Tests error handling for invalid UIDs.

#### Scenario 3: Missing required parameter — uid
- **Description:** Call without the required `uid` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error. Should report that `uid` is required.
- **Notes:** `uid` is `z.string()` without `.optional()`.

#### Scenario 4: Invalid type — uid as number
- **Description:** Pass a number instead of a string for `uid`.
- **Params:** `{ "uid": 12345 }`
- **Expected result:** Zod validation error. Should report expected string, received number.
- **Notes:** `uid` must be a string.

#### Scenario 5: Invalid format — empty UID string
- **Description:** Pass an empty string as the UID.
- **Params:** `{ "uid": "" }`
- **Expected result:** Godot-side error — empty UID is invalid. Should not crash.
- **Notes:** `z.string()` accepts empty strings; the Godot plugin should handle it.

#### Scenario 6: Invalid format — UID without uid:// prefix
- **Description:** Pass a string that looks like a UID but lacks the `uid://` prefix.
- **Params:** `{ "uid": "abc123def456" }`
- **Expected result:** Godot-side error — invalid UID format. Should not crash.
- **Notes:** Godot UIDs always start with `uid://`. The plugin should validate format.

#### Scenario 7: Happy path — UID with special characters
- **Description:** Pass a UID-like string with special characters.
- **Params:** `{ "uid": "uid://test with spaces" }`
- **Expected result:** Godot-side error — invalid UID format (spaces not allowed). Should not crash.
- **Notes:** Tests robustness against malformed input.

#### Scenario 8: Very long UID string
- **Description:** Pass an extremely long string as the UID.
- **Params:** `{ "uid": "uid://" + "a".repeat(500) }`
- **Expected result:** Godot-side error. Should not crash the server or cause a timeout.
- **Notes:** Tests that the system handles unreasonably large inputs without hanging.

---

## Tool: project_path_to_uid

### Schema

```typescript
{
  description: 'Convert a project file path to its UID',
  inputSchema: {
    path: ResourcePath.describe(
      "The project path (e.g. 'res://scenes/main.tscn')"
    ),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'project/path_to_uid', args as Record<string, unknown>)
```

### Tool Behavior
Converts a project file path (e.g., `res://scenes/main.tscn`) to its Godot resource UID (e.g., `uid://abc123def456`). This is the inverse of `uid_to_project_path`.

### Test Scenarios

#### Scenario 1: Happy path — convert a known file path to UID
- **Description:** Convert a file that is known to exist in the project (e.g., `project.godot`).
- **Params:** `{ "path": "res://project.godot" }`
- **Expected result:** Returns the UID for `project.godot` in the format `uid://...`. The UID should be a string starting with `uid://`.
- **Notes:** `project.godot` exists in every project, making this a reliable test case.

#### Scenario 2: Happy path — convert a scene file path to UID
- **Description:** Convert a scene file to its UID (requires at least one scene in the project).
- **Params:** `{ "path": "res://scenes/main.tscn" }` (or any known scene path)
- **Expected result:** Returns the UID for the scene file.
- **Notes:** The path must point to an existing file.

#### Scenario 3: Happy path — convert a script file path to UID
- **Description:** Convert a GDScript file to its UID.
- **Params:** `{ "path": "res://scripts/player.gd" }` (or any known script path)
- **Expected result:** Returns the UID for the script file.
- **Notes:** Tests UID resolution for script files.

#### Scenario 4: Happy path — round-trip UID ↔ path conversion
- **Description:** Convert a path to UID, then convert that UID back to a path. Verify they match.
- **Params:** Step 1: `project_path_to_uid({ "path": "res://project.godot" })` → get UID. Step 2: `uid_to_project_path({ "uid": "<result>" })` → get path.
- **Expected result:** The path returned by Step 2 should equal `res://project.godot`.
- **Notes:** This is an end-to-end test of both UID conversion tools working together.

#### Scenario 5: Missing required parameter — path
- **Description:** Call without the required `path` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error. Should report that `path` is required.
- **Notes:** `path` uses `ResourcePath` which is `z.string()` without `.optional()`.

#### Scenario 6: Invalid type — path as number
- **Description:** Pass a number instead of a string for `path`.
- **Params:** `{ "path": 12345 }`
- **Expected result:** Zod validation error. Should report expected string, received number.
- **Notes:** `ResourcePath` is `z.string()`.

#### Scenario 7: Non-existent file path
- **Description:** Pass a path to a file that does not exist in the project.
- **Params:** `{ "path": "res://nonexistent/file.gd" }`
- **Expected result:** Godot-side error — file not found. Should not crash the server.
- **Notes:** Tests error handling for missing files.

#### Scenario 8: Invalid path — not a res:// path
- **Description:** Pass an absolute filesystem path not starting with `res://`.
- **Params:** `{ "path": "C:/Users/somefile.gd" }`
- **Expected result:** Godot-side error — invalid resource path. Should not crash.
- **Notes:** Godot requires `res://` prefix for project paths.

#### Scenario 9: Invalid path — path to a directory instead of a file
- **Description:** Pass a path to a directory rather than a file.
- **Params:** `{ "path": "res://scenes" }` (if the scenes directory exists)
- **Expected result:** Godot-side error — directories do not have UIDs. Should not crash.
- **Notes:** UIDs are assigned to individual resource files, not directories.

#### Scenario 10: Empty string path
- **Description:** Pass an empty string as the path.
- **Params:** `{ "path": "" }`
- **Expected result:** Godot-side error — empty path is invalid. Should not crash.
- **Notes:** `z.string()` accepts empty strings.

#### Scenario 11: Path with trailing slash
- **Description:** Pass a file path with an unexpected trailing slash.
- **Params:** `{ "path": "res://project.godot/" }`
- **Expected result:** Godot-side error — paths with trailing slashes are treated as directories. Should not crash.
- **Notes:** Tests path format edge cases.

---

## Cross-Tool Integration Scenarios

These scenarios test interactions between multiple project tools.

#### Cross-Scenario 1: Set a setting and verify via get_settings
- **Description:** Use `set_project_setting` to change a value, then `get_project_settings` with the appropriate filter to confirm the change.
- **Steps:**
  1. `get_project_settings({ "filter": "application/config/name" })` — record original value.
  2. `set_project_setting({ "key": "application/config/name", "value": "TestVerifyProject" })` — change it.
  3. `get_project_settings({ "filter": "application/config/name" })` — verify new value is `"TestVerifyProject"`.
  4. `set_project_setting({ "key": "application/config/name", "value": "<original>" })` — restore original value.
- **Expected result:** Step 3 should return the updated value. Step 4 should restore the original.
- **Notes:** Tests that set and get are consistent. Always restore the original value.

#### Cross-Scenario 2: Filesystem tree + file search consistency
- **Description:** Verify that files returned by `search_files` also appear in `get_filesystem_tree`.
- **Steps:**
  1. `search_files({ "query": "project.godot" })` — should return `res://project.godot`.
  2. `get_filesystem_tree({ "path": "res://", "max_depth": 1 })` — should contain `project.godot` in the root listing.
- **Expected result:** The file found by `search_files` should also be visible in the filesystem tree.
- **Notes:** Validates consistency between browsing and searching.

#### Cross-Scenario 3: UID round-trip with filesystem tree
- **Description:** Pick a file from the filesystem tree, get its UID, then convert back.
- **Steps:**
  1. `get_filesystem_tree({ "path": "res://", "max_depth": 2 })` — pick any `.gd` or `.tscn` file path.
  2. `project_path_to_uid({ "path": "<chosen-file>" })` — get its UID.
  3. `uid_to_project_path({ "uid": "<result-uid>" })` — convert back.
- **Expected result:** The path from Step 3 should match the path from Step 1.
- **Notes:** End-to-end UID workflow from filesystem browsing.

---

## Edge Case Summary

| Edge Case | Tool(s) Affected | Description |
|-----------|------------------|-------------|
| Empty object params | `get_project_info`, `get_project_settings` | Tools with no required params should handle `{}` or undefined |
| Missing required params | `get_filesystem_tree`, `search_files`, `set_project_setting`, `uid_to_project_path`, `project_path_to_uid` | Zod must reject calls missing required fields |
| Wrong param type | All tools | Zod should reject numbers where strings are expected, etc. |
| Non-existent paths/UIDs | `get_filesystem_tree`, `uid_to_project_path`, `project_path_to_uid` | Godot should return errors without crashing |
| Empty strings | `search_files`, `set_project_setting`, `uid_to_project_path`, `project_path_to_uid` | Tools should handle empty string inputs gracefully |
| Very large values | `set_project_setting`, `get_filesystem_tree` | Large values or deep recursion should not cause timeouts |
| Special characters | `search_files`, `set_project_setting` | Queries and keys with special chars should not break parsing |
| Unicode in values | `set_project_setting`, `search_files` | Non-ASCII characters should be preserved |
| Null values | `set_project_setting` | Setting a value to `null` should be handled |
| Boolean false | `set_project_setting` | `false` should not be coerced to truthy |
| Filter prefix variations | `get_project_settings` | With/without trailing slash, case sensitivity |
| UID format variations | `uid_to_project_path` | With/without `uid://` prefix, whitespace, special chars |
| Path format variations | `get_filesystem_tree`, `project_path_to_uid` | Non-`res://` prefix, trailing slashes, directories |
| Round-trip consistency | `uid_to_project_path`, `project_path_to_uid` | Converting path→UID→path should return original path |
