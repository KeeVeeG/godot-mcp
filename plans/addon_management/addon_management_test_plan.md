# Addon Management Test Plan

> **Source file:** `server/src/tools/addon_management.ts`  
> **Shared types:** `server/src/tools/shared-types.ts`  
> **Tools covered:** 5 (`list_addons`, `install_addon`, `uninstall_addon`, `update_addon`, `configure_addon`)  
> **Generated:** 2026-07-08

---

## Schema Details

### Shared Imports

| Import | Zod Schema | Description |
|--------|-----------|-------------|
| `Name` | `z.string()` | Generic name identifier |
| `Properties` | `z.record(z.unknown())` | Required properties dictionary (key-value pairs) |
| `z` | Zod namespace | Used directly for `z.enum(...)` |

### Parameter Summary

| Tool | Param | Type | Required | Default | Enum/Choices | Notes |
|------|-------|------|----------|---------|--------------|-------|
| `list_addons` | *(none)* | — | — | — | — | Takes no input |
| `install_addon` | `name` | `string` | ✅ yes | — | — | Addon name or identifier |
| | `source` | `enum` | no | `asset_lib` | `asset_lib`, `git`, `local` | Installation source |
| | `url` | `string` | no | — | — | Required for `git`/`local` sources |
| `uninstall_addon` | `name` | `string` | ✅ yes | — | — | Addon name to uninstall |
| `update_addon` | `name` | `string` | ✅ yes | — | — | Addon name to update |
| `configure_addon` | `name` | `string` | ✅ yes | — | — | Addon name to configure |
| | `settings` | `record<unknown>` | ✅ yes | — | — | Key-value pairs to set |

---

## Tool: list_addons

### Schema

```typescript
{
  description: 'List all installed addons/plugins with their versions and status',
  inputSchema: {},
}
```

### Handler

```typescript
async () => callGodot(bridge, 'list_addons')
```

### Tool Behavior
Lists all addons/plugins currently installed in the Godot project, including their version numbers and activation status. Takes no parameters.

### Test Scenarios

#### Scenario 1: Basic happy path — list addons on a fresh project
- **Description:** Call `list_addons` on a project with no additional addons beyond the MCP plugin itself.
- **Params:** `{}` (empty object or no params)
- **Expected result:** Returns a JSON array of addon objects. The MCP plugin (`godot_mcp`) should appear in the list. Each entry should include fields for name, version, and status.
- **Notes:** The exact response structure depends on the Godot bridge, but at minimum it should not error.

#### Scenario 2: Call with unexpected extra params
- **Description:** Verify the tool ignores extraneous parameters since `inputSchema` is empty.
- **Params:** `{ "foo": "bar", "baz": 123 }`
- **Expected result:** Should succeed identically to Scenario 1. The extraneous params should be ignored (Zod will strip them from an empty schema).
- **Notes:** Tests robustness against clients that may send extra fields.

#### Scenario 3: Call with no arguments object at all
- **Description:** Call the tool with an undefined/null args value.
- **Params:** `undefined` or `null`
- **Expected result:** Should succeed — the empty schema should accept any input.
- **Notes:** Validates the handler can handle a missing args object.

---

## Tool: install_addon

### Schema

```typescript
{
  description: 'Install an addon from the Asset Library, git repository, or local path',
  inputSchema: {
    name: Name.describe('Addon name or identifier'),
    source: z.enum(['asset_lib', 'git', 'local']).optional().default('asset_lib')
            .describe('Installation source (default: asset_lib)'),
    url: z.string().optional().describe('Git URL or local path (required for git/local sources)'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'install_addon', args as Record<string, unknown>)
```

### Tool Behavior
Installs an addon into the Godot project from one of three sources:
- **asset_lib** (default): Installs from the Godot Asset Library by name/identifier.
- **git**: Clones from a Git repository URL.
- **local**: Copies from a local filesystem path.

The `url` parameter is required for `git` and `local` sources.

### Test Scenarios

#### Scenario 1: Happy path — install from Asset Library (default source)
- **Description:** Install an addon by name from the Godot Asset Library using the default `source` value.
- **Params:** `{ "name": "godot-sqlite" }`
- **Expected result:** The addon is downloaded and installed into the project's `addons/` directory. Returns a success response with installation details.
- **Notes:** Requires network access to the Asset Library. The addon name must exist in the Asset Library.

#### Scenario 2: Happy path — install from Asset Library (explicit source)
- **Description:** Same as Scenario 1 but with `source` explicitly set to `asset_lib`.
- **Params:** `{ "name": "godot-sqlite", "source": "asset_lib" }`
- **Expected result:** Identical behavior to Scenario 1. The addon installs from the Asset Library.
- **Notes:** Validates that the explicit `source` parameter works the same as the default.

#### Scenario 3: Happy path — install from Git repository
- **Description:** Install an addon by cloning a Git repository.
- **Params:** `{ "name": "my-plugin", "source": "git", "url": "https://github.com/user/my-godot-plugin.git" }`
- **Expected result:** The repository is cloned into the project's `addons/` directory. Returns success.
- **Notes:** Requires the Git URL to be valid and accessible. The `url` parameter is semantically required for `git` source.

#### Scenario 4: Happy path — install from local path
- **Description:** Install an addon by copying from a local filesystem directory.
- **Params:** `{ "name": "local-plugin", "source": "local", "url": "C:/path/to/local/addon" }`
- **Expected result:** The local addon is copied into the project's `addons/` directory. Returns success.
- **Notes:** The `url` parameter is semantically required for `local` source. The local path must exist and contain valid addon files.

#### Scenario 5: Missing required parameter — name
- **Description:** Call `install_addon` without the required `name` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error. Should report that `name` is required.
- **Notes:** `name` is the only required field (no `.optional()`), so it must be present.

#### Scenario 6: Missing required parameter — name with source=git
- **Description:** Call with `source=git` but no `name`.
- **Params:** `{ "source": "git", "url": "https://github.com/user/repo.git" }`
- **Expected result:** Zod validation error — `name` is required regardless of source.
- **Notes:** Validates that `name` remains required even when other params are present.

#### Scenario 7: Missing url for git source
- **Description:** Call with `source=git` but no `url`. This is not caught by Zod (url is optional), but should be caught by the Godot side.
- **Params:** `{ "name": "my-plugin", "source": "git" }`
- **Expected result:** Either a Godot-side error about missing URL, or Zod validation passes and the Godot handler rejects it.
- **Notes:** `url` is typed as `z.string().optional()`, so the server will forward it. The Godot plugin should be the one to reject the missing URL.

#### Scenario 8: Missing url for local source
- **Description:** Call with `source=local` but no `url`.
- **Params:** `{ "name": "my-plugin", "source": "local" }`
- **Expected result:** Similar to Scenario 7 — may pass Zod but fail at the Godot level.
- **Notes:** Same behavior as git source regarding optional `url`.

#### Scenario 9: Invalid source enum value
- **Description:** Call with a `source` value not in the enum.
- **Params:** `{ "name": "test", "source": "marketplace" }`
- **Expected result:** Zod validation error. Should report that `source` must be one of `asset_lib`, `git`, or `local`.
- **Notes:** The enum is strict — only the three defined values are accepted.

#### Scenario 10: Invalid source type (non-string)
- **Description:** Call with `source` as a number instead of a string.
- **Params:** `{ "name": "test", "source": 123 }`
- **Expected result:** Zod validation error — expected string for enum.
- **Notes:** Type coercion is not expected since Zod is strict by default.

#### Scenario 11: URL as non-string
- **Description:** Call with `url` as a number instead of a string.
- **Params:** `{ "name": "test", "source": "git", "url": 42 }`
- **Expected result:** Zod validation error — expected string for `url`.
- **Notes:** Validates type checking on the optional `url` parameter.

#### Scenario 12: Empty string for name
- **Description:** Call with an empty string as the addon name.
- **Params:** `{ "name": "" }`
- **Expected result:** Zod validation passes (empty string is a valid string). The Godot handler may reject it.
- **Notes:** Tests boundary condition — Zod's `z.string()` accepts empty strings.

#### Scenario 13: Very long name string
- **Description:** Call with an extremely long addon name.
- **Params:** `{ "name": "a".repeat(1000) }`
- **Expected result:** Zod validation passes. The Godot handler may reject or handle the long name.
- **Notes:** Tests robustness against oversized input values.

#### Scenario 14: URL with special characters
- **Description:** Call with a URL containing spaces, quotes, or special characters.
- **Params:** `{ "name": "test", "source": "git", "url": "https://example.com/repo with spaces.git" }`
- **Expected result:** Zod validation passes (any string). The Godot handler may fail on the malformed URL.
- **Notes:** Tests input sanitization expectations.

#### Scenario 15: Install with extra unknown params
- **Description:** Call with additional unknown parameters.
- **Params:** `{ "name": "test-addon", "version": "1.0.0", "extra_field": true }`
- **Expected result:** Zod validation passes (extra fields are ignored by default). Should install normally.
- **Notes:** Validates that unknown fields don't break the call.

---

## Tool: uninstall_addon

### Schema

```typescript
{
  description: 'Uninstall an addon and remove its files',
  inputSchema: {
    name: Name.describe('Addon name to uninstall'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'uninstall_addon', args as Record<string, unknown>)
```

### Tool Behavior
Removes an installed addon from the Godot project, including its files from the `addons/` directory.

### Test Scenarios

#### Scenario 1: Happy path — uninstall an installed addon
- **Description:** Uninstall an addon that was previously installed (e.g., after `install_addon`).
- **Params:** `{ "name": "godot-sqlite" }`
- **Expected result:** The addon is removed from the project. Its files in `addons/` are deleted. Returns success.
- **Notes:** Must have the addon installed first. Test after Scenario 1 of `install_addon`.

#### Scenario 2: Uninstall a non-existent addon
- **Description:** Attempt to uninstall an addon that is not installed.
- **Params:** `{ "name": "non-existent-addon-xyz" }`
- **Expected result:** Godot-side error. Should report that the addon is not installed.
- **Notes:** Tests error handling for missing addons.

#### Scenario 3: Missing required parameter — name
- **Description:** Call without the `name` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `name` is required.
- **Notes:** `name` is the only field and it is required.

#### Scenario 4: Name with special characters
- **Description:** Call with a name containing special characters.
- **Params:** `{ "name": "../malicious/path" }`
- **Expected result:** Zod validation passes (any string). The Godot handler should sanitize or reject path traversal attempts.
- **Notes:** Security-related edge case — validates that path traversal is not possible.

#### Scenario 5: Name as non-string
- **Description:** Call with `name` as a number.
- **Params:** `{ "name": 42 }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** Type validation.

#### Scenario 6: Uninstall the MCP plugin itself
- **Description:** Attempt to uninstall `godot_mcp` — the plugin providing the bridge.
- **Params:** `{ "name": "godot_mcp" }`
- **Expected result:** Uncertain; the Godot handler may allow it (removing the bridge capability) or reject it (self-protection). Document the actual behavior.
- **Notes:** Interesting edge case — what happens when the bridge plugin tries to uninstall itself?

---

## Tool: update_addon

### Schema

```typescript
{
  description: 'Update an installed addon to its latest version',
  inputSchema: {
    name: Name.describe('Addon name to update'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'update_addon', args as Record<string, unknown>)
```

### Tool Behavior
Updates an installed addon to the latest available version. For Asset Library addons, this pulls the newest version. For git-based addons, this pulls the latest commits.

### Test Scenarios

#### Scenario 1: Happy path — update an installed addon
- **Description:** Update an addon that was previously installed and has a newer version available.
- **Params:** `{ "name": "godot-sqlite" }`
- **Expected result:** The addon is updated to the latest version. Returns success with update details.
- **Notes:** Use an addon with a known update available, or test that updating an already-current addon reports "already up to date".

#### Scenario 2: Update a non-existent addon
- **Description:** Attempt to update an addon that is not installed.
- **Params:** `{ "name": "non-existent-addon-xyz" }`
- **Expected result:** Godot-side error — addon not found or not installed.
- **Notes:** Tests error handling for unknown addons.

#### Scenario 3: Update an addon that is already at the latest version
- **Description:** Update an addon that is already current.
- **Params:** `{ "name": "<addon-at-latest-version>" }`
- **Expected result:** Should succeed and report that the addon is already up to date. Should not error.
- **Notes:** Validates idempotency of the update operation.

#### Scenario 4: Missing required parameter — name
- **Description:** Call without the `name` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `name` is required.
- **Notes:** Standard missing-required-param test.

#### Scenario 5: Name as empty string
- **Description:** Call with an empty string.
- **Params:** `{ "name": "" }`
- **Expected result:** Zod validation passes. Godot handler likely rejects.
- **Notes:** Boundary condition.

---

## Tool: configure_addon

### Schema

```typescript
{
  description: 'Update configuration settings for an installed addon',
  inputSchema: {
    name: Name.describe('Addon name to configure'),
    settings: Properties.describe('Configuration key-value pairs to set'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'configure_addon', args as Record<string, unknown>)
```

### Tool Behavior
Updates the configuration settings of an installed addon. The `settings` parameter is a required object containing arbitrary key-value pairs that map to the addon's configuration properties.

### Test Scenarios

#### Scenario 1: Happy path — configure a single setting
- **Description:** Set one configuration value on an installed addon.
- **Params:** `{ "name": "godot-sqlite", "settings": { "debug_mode": true } }`
- **Expected result:** The addon's `debug_mode` setting is updated to `true`. Returns success.
- **Notes:** Requires knowledge of the addon's valid configuration keys.

#### Scenario 2: Happy path — configure multiple settings
- **Description:** Set multiple configuration values at once.
- **Params:** `{ "name": "godot-sqlite", "settings": { "debug_mode": true, "log_level": "verbose", "max_connections": 10 } }`
- **Expected result:** All three settings are applied. Returns success.
- **Notes:** Validates that the tool accepts arbitrary key-value pairs.

#### Scenario 3: Configure a non-existent addon
- **Description:** Attempt to configure an addon that is not installed.
- **Params:** `{ "name": "non-existent-addon", "settings": { "foo": "bar" } }`
- **Expected result:** Godot-side error — addon not found.
- **Notes:** Error path test.

#### Scenario 4: Missing required parameter — name
- **Description:** Call without the `name` parameter.
- **Params:** `{ "settings": { "debug_mode": true } }`
- **Expected result:** Zod validation error — `name` is required.
- **Notes:** Validates the required field.

#### Scenario 5: Missing required parameter — settings
- **Description:** Call without the `settings` parameter.
- **Params:** `{ "name": "godot-sqlite" }`
- **Expected result:** Zod validation error — `settings` is required.
- **Notes:** `settings` is not optional — it must be present.

#### Scenario 6: Empty settings object
- **Description:** Call with an empty settings object.
- **Params:** `{ "name": "godot-sqlite", "settings": {} }`
- **Expected result:** Zod validation passes (empty record is valid). The Godot handler may accept it (no-op) or reject it.
- **Notes:** Tests the boundary case of an empty configuration update.

#### Scenario 7: Settings with non-object value
- **Description:** Call with `settings` as a string instead of an object.
- **Params:** `{ "name": "godot-sqlite", "settings": "invalid" }`
- **Expected result:** Zod validation error — `z.record(z.unknown())` expects an object.
- **Notes:** Type validation for the `settings` parameter.

#### Scenario 8: Settings with null value
- **Description:** Call with `settings` as `null`.
- **Params:** `{ "name": "godot-sqlite", "settings": null }`
- **Expected result:** Zod validation error — `z.record(z.unknown())` rejects `null`.
- **Notes:** Null is not a valid record.

#### Scenario 9: Settings with nested objects
- **Description:** Configure with deeply nested setting values.
- **Params:** `{ "name": "godot-sqlite", "settings": { "database": { "host": "localhost", "port": 5432, "options": { "ssl": true } } } }`
- **Expected result:** Zod validation passes (any unknown value is valid). The Godot handler may accept or reject nested configs depending on addon capabilities.
- **Notes:** Validates handling of complex/nested configuration structures.

#### Scenario 10: Settings with array values
- **Description:** Configure with array-type setting values.
- **Params:** `{ "name": "godot-sqlite", "settings": { "allowed_extensions": [".db", ".sqlite", ".sqlite3"], "ignored_tables": [] } }`
- **Expected result:** Zod validation passes. Behavior depends on the addon's configuration schema.
- **Notes:** Tests array values in settings.

#### Scenario 11: Name as non-string
- **Description:** Call with `name` as a boolean.
- **Params:** `{ "name": true, "settings": { "foo": "bar" } }`
- **Expected result:** Zod validation error — `name` must be a string.
- **Notes:** Type validation.

#### Scenario 12: Both parameters missing
- **Description:** Call with an empty object.
- **Params:** `{}`
- **Expected result:** Zod validation error — both `name` and `settings` are required.
- **Notes:** Tests the case where neither required param is present.

#### Scenario 13: Configure with numeric key in settings
- **Description:** Use a numeric key in the settings object.
- **Params:** `{ "name": "godot-sqlite", "settings": { 123: "value" } }`
- **Expected result:** Zod validation passes (numeric keys are coerced to strings in JSON, and `z.record` accepts string keys from JSON). The Godot handler may accept or reject.
- **Notes:** Tests handling of non-string object keys (JSON serialization converts them to strings).

---

## Cross-Tool Integration Scenarios

These scenarios test sequences of addon management operations together.

### Scenario I: Full lifecycle — install → configure → update → uninstall
- **Steps:**
  1. `install_addon({ "name": "godot-sqlite", "source": "asset_lib" })` → success
  2. `list_addons()` → should include `godot-sqlite`
  3. `configure_addon({ "name": "godot-sqlite", "settings": { "debug_mode": true } })` → success
  4. `update_addon({ "name": "godot-sqlite" })` → success or "already up to date"
  5. `uninstall_addon({ "name": "godot-sqlite" })` → success
  6. `list_addons()` → should no longer include `godot-sqlite`
- **Expected result:** Each step succeeds independently and in sequence. No state leakage between steps.

### Scenario II: Install from each source type
- **Steps:**
  1. `install_addon({ "name": "addon-a", "source": "asset_lib" })` → install from Asset Library
  2. `install_addon({ "name": "addon-b", "source": "git", "url": "https://github.com/user/repo.git" })` → install from Git
  3. `install_addon({ "name": "addon-c", "source": "local", "url": "/path/to/local/addon" })` → install from local
  4. `list_addons()` → should show all three addons
- **Expected result:** All three source types work. Each addon appears in the list.

### Scenario III: Idempotent configure → configure again
- **Steps:**
  1. `configure_addon({ "name": "<installed-addon>", "settings": { "key1": "value1" } })` → success
  2. `configure_addon({ "name": "<installed-addon>", "settings": { "key1": "value2" } })` → success (overwrites)
- **Expected result:** Both calls succeed. The second call overwrites the first setting.

---

## Notes for Test Executors

1. **Network dependency:** The `install_addon` tool with `source: "asset_lib"` requires network access to the Godot Asset Library. Tests should be run in an environment with internet access, or mocked if offline.

2. **Git dependency:** The `git` source requires Git to be installed and accessible on the system PATH.

3. **Local source:** The `local` source requires a valid addon directory to exist at the specified path before the test runs.

4. **Stateful tools:** `install_addon`, `uninstall_addon`, and `configure_addon` modify project state. Run tests in a dedicated test project, not in a production project.

5. **Cleanup:** After tests, uninstall any addons that were installed during testing to restore the project to its original state.

6. **Zod validation vs Godot validation:** The MCP server validates parameters at the schema level (Zod). The Godot plugin performs additional validation. Both layers should be tested — Zod errors are returned immediately, while Godot errors come back via the WebSocket bridge.

7. **`url` semantic requirement:** Although `url` is typed as optional in the Zod schema, it is semantically required for `source: "git"` and `source: "local"`. The Godot plugin is expected to enforce this requirement at runtime.
