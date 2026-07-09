# Addon Management Tools — Comprehensive Test Plan

> **Source file**: `server/src/tools/addon_management.ts`
> **Shared types**: `server/src/tools/shared-types.ts`
> **Bridge**: All tools call `callGodot(bridge, method, params)` which forwards via WebSocket JSON-RPC 2.0 to the Godot editor plugin.
> **Prerequisites**: Godot editor must be running with the MCP plugin active and connected.

---

## Common Notes

- All tools return `Promise<ToolResult>` where `ToolResult = { content: [{ type: 'text', text: string }], isError?: boolean }`.
- On success, `text` contains JSON-stringified Godot response data.
- On failure, `text` contains an error message prefixed with `Godot request failed:` and `isError` is `true`.
- The `Name` schema is `z.string()` — accepts any non-empty string; no length/format restriction.
- The `Properties` schema is `z.record(z.unknown())` — an arbitrary key-value object with string keys and any values.

---

## Related Tools (call order context)

| Tool | File | When to use |
|---|---|---|
| `reload_plugin` | `editor.ts` | After `install_addon` — reloads plugins so Godot picks up the newly installed addon |
| `list_addons` | `addon_management.ts` | Call before and after install/uninstall/update to verify state changes |
| `configure_addon` | `addon_management.ts` | Only after an addon is already installed |
| `get_addon_config` | `addon_management.ts` | After install or configure to read current addon configuration |

---

## Tool: `list_addons`

**Description**: List all installed addons/plugins with their versions and status.

**Input Schema**: `{}` — no parameters.

**Handler**: `async () => callGodot(bridge, 'list_addons')` — no params forwarded.

### Test Scenarios

#### Scenario 1: Happy path — list addons on a project with addons installed

**Description**: Basic call to verify the tool returns a list of addons with version and status info.

**Params**: `{}`

**Expected result**: Successful response (no `isError`). Response is a JSON array or object describing installed addons. Each addon entry should contain at minimum: name, version (or equivalent), and status (enabled/disabled).

**Notes**: Response shape depends on the Godot plugin implementation. Check that the response is valid JSON and contains identifiable addon entries.

**What to pay attention to**: Response must be valid parseable JSON. Each addon entry should have a `name` field and a status indicator. If no addons are installed, expect an empty array `[]` or equivalent.

---

#### Scenario 2: Project with no addons installed

**Description**: Call on a fresh/empty Godot project with no addons.

**Params**: `{}`

**Expected result**: Successful response with an empty list (empty array `[]` or object with no entries).

**Notes**: Should not error even if there are zero addons. The response must still be valid JSON.

**What to pay attention to**: Ensure no `isError: true` is returned for a valid "empty" state. The tool should gracefully handle zero addons.

---

#### Scenario 3: After installing a new addon

**Description**: Call `list_addons` immediately after `install_addon` to verify the addon appears in the list.

**Params**: `{}`

**Expected result**: The newly installed addon must appear in the list with a valid status (enabled or disabled).

**Pre-condition**: Call `install_addon` first (see install_addon Scenario 1).

**What to pay attention to**: The addon name from the install step should be present in the list. Version info should be populated. Status should indicate whether the addon is active.

---

## Tool: `install_addon`

**Description**: Install an addon from the Asset Library, git repository, or local path.

**Input Schema**:

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | `string` | **yes** | — | Addon name or identifier |
| `source` | `enum ['asset_lib', 'git', 'local']` | no | `'asset_lib'` | Installation source |
| `url` | `string` | no | — | Git URL or local path (required for `git`/`local` sources) |

**Handler**: `async (args) => callGodot(bridge, 'install_addon', args)` — forwards all args directly.

### Test Scenarios

#### Scenario 1: Install from Asset Library (default source)

**Description**: Install a known addon from the Godot Asset Library by name, using default source.

**Params**:
```json
{
  "name": "godot-mcp"
}
```

**Expected result**: Successful response indicating the addon was downloaded and installed. Response should contain installation confirmation and addon metadata.

**Notes**: `source` defaults to `'asset_lib'`. The `name` must be a valid identifier in the Asset Library. After this call, use `list_addons` to verify.

**What to pay attention to**: Verify the addon appears in the project's `addons/` directory after installation. Response should not contain `isError: true`.

---

#### Scenario 2: Install from Asset Library with explicit source

**Description**: Same as Scenario 1 but with `source` explicitly set.

**Params**:
```json
{
  "name": "godot-mcp",
  "source": "asset_lib"
}
```

**Expected result**: Same as Scenario 1 — successful installation.

**Notes**: Explicitly passing the default value should not change behavior.

**What to pay attention to**: Behavior must be identical to Scenario 1. No duplicate install or error.

---

#### Scenario 3: Install from git repository

**Description**: Install an addon from a git URL.

**Params**:
```json
{
  "name": "my-git-addon",
  "source": "git",
  "url": "https://github.com/user/godot-addon.git"
}
```

**Expected result**: Successful response indicating the addon was cloned and installed.

**Notes**: The `url` parameter is required when `source` is `'git'`. The URL must point to a valid Godot addon repository.

**What to pay attention to**: The URL must be a valid git repository. If the URL is invalid or unreachable, expect an error response with `isError: true`.

---

#### Scenario 4: Install from local path

**Description**: Install an addon from a local filesystem path.

**Params**:
```json
{
  "name": "my-local-addon",
  "source": "local",
  "url": "/path/to/addon"
}
```

**Expected result**: Successful response indicating the addon was copied/linked from the local path.

**Notes**: The `url` parameter is required when `source` is `'local'`. The path must exist and contain a valid Godot addon structure.

**What to pay attention to**: Path must be accessible to the Godot process. Use a path that exists on the machine running Godot.

---

#### Scenario 5: Missing required `name` parameter

**Description**: Call without the `name` parameter.

**Params**:
```json
{}
```

**Expected result**: Error response (`isError: true`). The MCP SDK validates the input schema before the handler runs, so this should fail at the schema validation level. The error message should indicate that `name` is required.

**Notes**: This tests schema enforcement. The `Name` schema is `z.string()` which requires a string value.

**What to pay attention to**: The error should clearly state that `name` is required. The handler should NOT be called.

---

#### Scenario 6: Empty string for `name`

**Description**: Call with an empty string as the name.

**Params**:
```json
{
  "name": ""
}
```

**Expected result**: Depends on Godot-side validation. The Zod schema (`z.string()`) accepts empty strings, so this will pass MCP validation. The Godot plugin may reject it with an error.

**Notes**: This tests whether empty-string names are handled gracefully. Some Zod schemas use `.min(1)` to reject empty strings, but `Name` does not.

**What to pay attention to**: If the Godot side returns an error for empty name, that is acceptable behavior. If it crashes or returns unexpected output, that is a bug.

---

#### Scenario 7: `source` = `'git'` without `url`

**Description**: Install from git but forget to provide the URL.

**Params**:
```json
{
  "name": "my-addon",
  "source": "git"
}
```

**Expected result**: The MCP SDK will NOT reject this (url is optional in the schema). The Godot plugin should return an error indicating that a URL is required for git installations.

**Notes**: The schema marks `url` as optional, but semantically it is required for git/local sources. This tests whether the Godot-side handler validates this constraint.

**What to pay attention to**: Expect `isError: true` with a message indicating the URL is missing. The addon should NOT be partially installed.

---

#### Scenario 8: Invalid `source` enum value

**Description**: Pass an unsupported source value.

**Params**:
```json
{
  "name": "my-addon",
  "source": "npm"
}
```

**Expected result**: MCP SDK schema validation error. The `z.enum(['asset_lib', 'git', 'local'])` will reject `'npm'` before the handler runs.

**Notes**: This tests enum enforcement at the schema level.

**What to pay attention to**: Error should mention invalid enum value. Handler should NOT be called.

---

#### Scenario 9: Invalid `url` format

**Description**: Provide a malformed URL.

**Params**:
```json
{
  "name": "my-addon",
  "source": "git",
  "url": "not-a-valid-url"
}
```

**Expected result**: The Zod schema accepts any string for `url` (no URL format validation). The Godot plugin should return an error when it tries to clone from an invalid URL.

**Notes**: This tests whether URL validation happens at the Godot side.

**What to pay attention to**: Expect `isError: true` with a message about invalid URL or failed clone. No partial install should occur.

---

#### Scenario 10: Non-existent local path

**Description**: Provide a local path that does not exist.

**Params**:
```json
{
  "name": "phantom-addon",
  "source": "local",
  "url": "/nonexistent/path/to/addon"
}
```

**Expected result**: Error response from the Godot side indicating the path does not exist.

**What to pay attention to**: Expect `isError: true`. The addon should not appear in `list_addons`.

---

## Tool: `uninstall_addon`

**Description**: Uninstall an addon and remove its files.

**Input Schema**:

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | `string` | **yes** | — | Addon name to uninstall |

**Handler**: `async (args) => callGodot(bridge, 'uninstall_addon', args)` — forwards `{ name }`.

### Test Scenarios

#### Scenario 1: Uninstall an existing addon

**Description**: Uninstall an addon that was previously installed.

**Params**:
```json
{
  "name": "godot-mcp"
}
```

**Expected result**: Successful response indicating the addon was removed. The addon's files should be deleted from the `addons/` directory.

**Pre-condition**: The addon must be installed first (see `install_addon` Scenario 1). After uninstall, call `list_addons` to verify the addon is gone.

**Notes**: This is a destructive operation. The addon files are permanently removed.

**What to pay attention to**: After this call, `list_addons` must NOT include the uninstalled addon. The `addons/<addon_name>/` directory should no longer exist. The `project.godot` plugin entry should be removed or disabled.

---

#### Scenario 2: Uninstall a non-existent addon

**Description**: Attempt to uninstall an addon that does not exist.

**Params**:
```json
{
  "name": "nonexistent-addon"
}
```

**Expected result**: Error response (`isError: true`) indicating the addon was not found.

**Notes**: The Godot plugin should handle this gracefully without crashing.

**What to pay attention to**: Expect `isError: true` with a clear "not found" message. No files should be deleted. No side effects on other addons.

---

#### Scenario 3: Missing required `name` parameter

**Description**: Call without the `name` parameter.

**Params**:
```json
{}
```

**Expected result**: MCP SDK schema validation error — `name` is required (uses `Name` which is `z.string()`).

**What to pay attention to**: Error should indicate missing `name` field. Handler should NOT be called.

---

#### Scenario 4: Uninstall with empty string name

**Description**: Pass an empty string as name.

**Params**:
```json
{
  "name": ""
}
```

**Expected result**: Depends on Godot-side validation. Zod accepts empty strings for `z.string()`. The Godot plugin should reject this with an error.

**What to pay attention to**: Expect either a schema error or a Godot-side "not found" / "invalid name" error. No files should be deleted.

---

## Tool: `update_addon`

**Description**: Update an installed addon to its latest version.

**Input Schema**:

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | `string` | **yes** | — | Addon name to update |

**Handler**: `async (args) => callGodot(bridge, 'update_addon', args)` — forwards `{ name }`.

### Test Scenarios

#### Scenario 1: Update an existing addon

**Description**: Update an addon that is already installed to its latest version.

**Params**:
```json
{
  "name": "godot-mcp"
}
```

**Expected result**: Successful response indicating the addon was updated. May include version info (old version → new version).

**Pre-condition**: The addon must be installed first.

**Notes**: If the addon is already at the latest version, the tool may return success with a "already up to date" message, or it may return an error — both are valid behaviors.

**What to pay attention to**: Response should indicate whether the version actually changed. Call `list_addons` before and after to compare versions. If the addon was already at the latest version, the response should clearly state that.

---

#### Scenario 2: Update a non-existent addon

**Description**: Attempt to update an addon that is not installed.

**Params**:
```json
{
  "name": "nonexistent-addon"
}
```

**Expected result**: Error response (`isError: true`) indicating the addon is not installed.

**What to pay attention to**: Expect `isError: true` with a "not found" or "not installed" message. No partial state changes should occur.

---

#### Scenario 3: Missing required `name` parameter

**Description**: Call without the `name` parameter.

**Params**:
```json
{}
```

**Expected result**: MCP SDK schema validation error — `name` is required.

**What to pay attention to**: Error should indicate missing `name` field. Handler should NOT be called.

---

## Tool: `configure_addon`

**Description**: Update configuration settings for an installed addon.

**Input Schema**:

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | `string` | **yes** | — | Addon name to configure |
| `settings` | `Record<string, unknown>` | **yes** | — | Configuration key-value pairs to set |

**Handler**: `async (args) => callGodot(bridge, 'configure_addon', args)` — forwards `{ name, settings }`.

### Test Scenarios

#### Scenario 1: Configure an existing addon with valid settings

**Description**: Update settings on an installed addon with known configuration keys.

**Params**:
```json
{
  "name": "godot-mcp",
  "settings": {
    "enabled": true,
    "port": 6505,
    "debug_mode": false
  }
}
```

**Expected result**: Successful response indicating settings were applied.

**Pre-condition**: The addon must be installed first.

**Notes**: The valid settings keys depend on the specific addon. `settings` is `z.record(z.unknown())` so any key-value pairs are accepted at the schema level.

**What to pay attention to**: Verify the settings actually took effect. If the addon exposes a way to read settings (e.g., via `project.godot` or a config file), check that the values were persisted. Invalid keys may be silently ignored or cause errors depending on the addon.

---

#### Scenario 2: Configure with a single setting

**Description**: Set just one configuration value.

**Params**:
```json
{
  "name": "godot-mcp",
  "settings": {
    "enabled": true
  }
}
```

**Expected result**: Successful response with the single setting applied.

**What to pay attention to**: Single-key updates should work. Other settings should remain unchanged.

---

#### Scenario 3: Configure a non-existent addon

**Description**: Attempt to configure an addon that is not installed.

**Params**:
```json
{
  "name": "nonexistent-addon",
  "settings": {
    "enabled": true
  }
}
```

**Expected result**: Error response (`isError: true`) indicating the addon was not found.

**What to pay attention to**: Expect `isError: true`. No configuration should be written to disk. No side effects on other addons.

---

#### Scenario 4: Missing required `name` parameter

**Description**: Call without the `name` parameter.

**Params**:
```json
{
  "settings": { "enabled": true }
}
```

**Expected result**: MCP SDK schema validation error — `name` is required.

**What to pay attention to**: Error should indicate missing `name`. Handler should NOT be called.

---

#### Scenario 5: Missing required `settings` parameter

**Description**: Call without the `settings` parameter.

**Params**:
```json
{
  "name": "godot-mcp"
}
```

**Expected result**: MCP SDK schema validation error — `settings` is required.

**What to pay attention to**: Error should indicate missing `settings`. Handler should NOT be called.

---

#### Scenario 6: Empty `settings` object

**Description**: Pass an empty object for settings.

**Params**:
```json
{
  "name": "godot-mcp",
  "settings": {}
}
```

**Expected result**: Depends on Godot-side behavior. The schema accepts it (`z.record(z.unknown())` allows empty objects). The Godot plugin may either succeed (no-op) or return an error indicating no settings were provided.

**What to pay attention to**: Both a no-op success and an error are valid. The key is that it should not crash or corrupt addon state.

---

#### Scenario 7: `settings` with nested object values

**Description**: Pass settings with nested JSON values.

**Params**:
```json
{
  "name": "godot-mcp",
  "settings": {
    "connection": {
      "host": "localhost",
      "port": 6505,
      "retry_policy": {
        "max_retries": 3,
        "backoff_ms": 1000
      }
    },
    "features": ["node_manipulation", "scene_editing"]
  }
}
```

**Expected result**: The schema accepts this (`z.record(z.unknown())` allows any value). The Godot plugin's behavior depends on whether it supports nested configuration.

**What to pay attention to**: If the addon only supports flat key-value settings, nested objects may be rejected or ignored. Check the response for any indication of unsupported structure.

---

#### Scenario 8: `settings` with non-string keys

**Description**: Pass settings with keys that are not typical config names.

**Params**:
```json
{
  "name": "godot-mcp",
  "settings": {
    "123": "numeric-key",
    "": "empty-key",
    "special!@#chars": "value"
  }
}
```

**Expected result**: The `z.record(z.unknown())` schema accepts any string keys. The Godot plugin may reject non-standard keys.

**What to pay attention to**: Check if the Godot side validates key names. Non-standard keys should either be ignored or return an error — they should not corrupt the addon configuration.

---

## Tool: `get_addon_config`

**Description**: Read the current configuration of an installed addon. Returns config.json contents, project settings, and plugin.cfg metadata.

**Input Schema**:

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | `string` | **yes** | — | Addon name to read config for |

**Handler**: `async (args) => callGodot(bridge, 'get_addon_config', args)` — forwards `{ name }`.

### Test Scenarios

#### Scenario 1: Read config of an addon with config.json

**Description**: Read the configuration of an addon that has a config.json file.

**Params**:
```json
{
  "name": "godot-mcp"
}
```

**Expected result**: Successful response containing:
- `config`: key-value pairs from the addon's config.json
- `project_settings`: project settings under `addons/<name>/` prefix
- `plugin_info`: metadata from plugin.cfg (name, description, author, version, script)
- `config_path`: absolute path to the config.json file

**Pre-condition**: The addon must be installed and have a config.json file.

**What to pay attention to**: The `config` object should match the contents of the addon's config.json. The `plugin_info` should contain version and author from plugin.cfg. The `config_path` should be a valid absolute path.

---

#### Scenario 2: Read config of an addon without config.json

**Description**: Read the configuration of an addon that does not have a config.json file.

**Params**:
```json
{
  "name": "simple-addon"
}
```

**Expected result**: Successful response where `config` is an empty object `{}` and `config_path` is an empty string `""`. The `project_settings` and `plugin_info` should still be populated if applicable.

**Notes**: Not all addons have a config.json. The tool should handle this gracefully without erroring.

**What to pay attention to**: No error should be returned. The `config` field should be `{}`, not null or undefined.

---

#### Scenario 3: Read config of an addon with project settings

**Description**: Read the configuration of an addon that has project settings stored in project.godot.

**Params**:
```json
{
  "name": "addon-with-settings"
}
```

**Expected result**: Successful response where `project_settings` contains key-value pairs from `project.godot` under the `addons/<name>/` prefix.

**Pre-condition**: The addon must be installed and have settings stored in project.godot (e.g., via `configure_addon`).

**What to pay attention to**: The `project_settings` keys should NOT include the `addons/<name>/` prefix — only the suffix keys should be present. Values should match what was configured.

---

#### Scenario 4: Read config of a non-existent addon

**Description**: Attempt to read the config of an addon that is not installed.

**Params**:
```json
{
  "name": "nonexistent-addon"
}
```

**Expected result**: Error response (`isError: true`) indicating the addon was not found.

**What to pay attention to**: Expect `isError: true` with a clear "not found" message. No partial data should be returned.

---

#### Scenario 5: Missing required `name` parameter

**Description**: Call without the `name` parameter.

**Params**:
```json
{}
```

**Expected result**: MCP SDK schema validation error — `name` is required.

**What to pay attention to**: Error should indicate missing `name` field. Handler should NOT be called.

---

#### Scenario 6: Empty string for `name`

**Description**: Pass an empty string as the name.

**Params**:
```json
{
  "name": ""
}
```

**Expected result**: Depends on Godot-side validation. Zod accepts empty strings for `z.string()`. The Godot plugin should reject this with an error.

**What to pay attention to**: Expect either a schema error or a Godot-side "not found" / "invalid name" error. No config data should be returned.

---

#### Scenario 7: Read config after configure_addon

**Description**: Call `get_addon_config` immediately after `configure_addon` to verify settings were persisted.

**Params**:
```json
{
  "name": "test-addon"
}
```

**Expected result**: The `project_settings` in the response should contain the settings that were just configured via `configure_addon`.

**Pre-condition**: Call `configure_addon` first with some settings.

**What to pay attention to**: The settings from `configure_addon` should be visible in `get_addon_config` response. This verifies that configure writes settings that can be read back.

---

## Sequenced Test Flows

### Flow 1: Full Install → Configure → Update → Uninstall Lifecycle

This flow tests the complete addon lifecycle in order.

```
Step 1: list_addons → note current state (baseline)
Step 2: install_addon { name: "test-addon", source: "asset_lib" }
Step 3: list_addons → verify "test-addon" appears
Step 4: configure_addon { name: "test-addon", settings: { "enabled": true } }
Step 5: update_addon { name: "test-addon" }
Step 6: list_addons → verify version/status changed
Step 7: uninstall_addon { name: "test-addon" }
Step 8: list_addons → verify "test-addon" is gone
```

**Expected**: All steps succeed. The addon is cleanly installed, configured, updated, and removed.

**What to pay attention to**: After step 8, the `addons/` directory should not contain `test-addon/`. The `project.godot` file should not reference the addon.

---

### Flow 2: Install from Git → Reload → Verify

This flow tests git-based installation with plugin reload.

```
Step 1: install_addon { name: "git-addon", source: "git", url: "https://github.com/user/addon.git" }
Step 2: reload_plugin (from editor.ts) → forces Godot to pick up the new addon
Step 3: list_addons → verify "git-addon" appears with correct status
```

**Expected**: The addon is installed from git and becomes visible after reload.

**What to pay attention to**: `reload_plugin` is from `editor.ts` and may be needed after installs to update Godot's internal plugin registry. Without it, the addon may not appear immediately.

---

### Flow 3: Error Recovery — Install fails, then succeeds

This flow tests that a failed install does not leave the system in a bad state.

```
Step 1: install_addon { name: "bad-addon", source: "git", url: "invalid-url" } → expect error
Step 2: list_addons → verify "bad-addon" does NOT appear
Step 3: install_addon { name: "good-addon", source: "asset_lib" } → expect success
Step 4: list_addons → verify "good-addon" appears
```

**Expected**: A failed install does not corrupt state. Subsequent installs still work.

**What to pay attention to**: No residual files from the failed install should exist. The `addons/` directory should be clean.

---

### Flow 4: Configure → Read Config → Verify Round-Trip

This flow tests that `configure_addon` writes settings that `get_addon_config` can read back.

```
Step 1: install_addon { name: "test-addon", source: "asset_lib" }
Step 2: configure_addon { name: "test-addon", settings: { "enabled": true, "port": 6505 } }
Step 3: get_addon_config { name: "test-addon" } → verify project_settings contains enabled=true, port=6505
Step 4: configure_addon { name: "test-addon", settings: { "port": 7000 } }
Step 5: get_addon_config { name: "test-addon" } → verify project_settings port changed to 7000, enabled still true
```

**Expected**: `get_addon_config` reflects all settings written by `configure_addon`. Partial updates do not erase existing settings.

**What to pay attention to**: After step 5, `project_settings` must contain both `enabled` and `port` keys. The `port` value must be `7000` (updated), and `enabled` must still be `true` (unchanged).

---

## Edge Cases Summary

| Case | Tool | Expected Behavior |
|---|---|---|
| Empty name `""` | all tools | Zod accepts it; Godot should reject with error |
| Non-existent addon | uninstall, update, configure, get_addon_config | `isError: true` with "not found" message |
| Missing required param | all tools | MCP SDK validation error before handler |
| Invalid enum value | install_addon (`source`) | Zod rejects with enum error |
| git source without URL | install_addon | Godot-side error (URL semantically required) |
| local source without URL | install_addon | Godot-side error (URL semantically required) |
| Empty settings `{}` | configure_addon | No-op success or Godot-side error |
| Nested settings values | configure_addon | Schema accepts; Godot behavior depends on addon |
| Non-string keys | configure_addon | Schema accepts; Godot behavior depends on addon |
| Addon already at latest version | update_addon | Success with "already up to date" or error |
| Double install of same addon | install_addon | Overwrite existing or error (depends on implementation) |
| Install then immediately uninstall | install_addon → uninstall_addon | Clean lifecycle, no residual files |
| Uninstall then configure same addon | uninstall_addon → configure_addon | configure should fail with "not found" |
| Addon without config.json | get_addon_config | Success with empty `config: {}` and empty `config_path: ""` |
| Addon with project settings | get_addon_config | `project_settings` contains keys without `addons/<name>/` prefix |