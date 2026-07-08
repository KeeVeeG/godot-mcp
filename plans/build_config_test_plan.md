# Test Plan: build_config.ts — 8 Build Configuration Tools

> **Source**: `server/src/tools/build_config.ts`
> **GDScript handler**: `addons/godot_mcp/commands/build_config_commands.gd`
> **Bridge method prefix**: `build_config/`

## Overview

This module exposes 8 MCP tools for configuring Godot's build pipeline: build presets (debug/release/development), scripting backend (GDScript/C#), export resource filters, custom feature tags, debug/optimization flags, settings validation, and CLI export command generation. All tools call through `callGodot(bridge, method, args)` which forwards via WebSocket JSON-RPC 2.0 to the Godot editor plugin.

### Inter-Tool Dependencies

| Tool | Depends On | Reason |
|------|-----------|--------|
| `get_build_settings` | `set_build_configuration`, `set_scripting_backend`, `set_export_filter`, `set_custom_features`, `set_debug_options` | Verify that mutations are reflected in the read |
| `set_build_configuration` | `get_build_settings` | Verify current config before changing |
| `set_scripting_backend` | `get_build_settings` | Verify current backend before changing |
| `set_export_filter` | `get_build_settings` | Verify current filter before changing |
| `set_custom_features` | `get_build_settings` | Verify current features before changing |
| `set_debug_options` | `get_build_settings` | Verify current debug flags before changing |
| `validate_build_settings` | any mutation tool | Validate after changing settings to check for conflicts |
| `get_build_command` | `set_build_configuration`, `set_scripting_backend` | Build command depends on current config and backend |
| `get_build_command` | `list_export_presets` (from `export.ts`) | Platform names may correspond to export preset names |

### Recommended Execution Order

1. `get_build_settings` — baseline read
2. `set_build_configuration` — mutate build preset
3. `get_build_settings` — verify config changed
4. `set_scripting_backend` — mutate backend
5. `get_build_settings` — verify backend changed
6. `set_export_filter` — mutate export filter
7. `get_build_settings` — verify filter changed
8. `set_custom_features` — mutate feature tags
9. `get_build_settings` — verify features changed
10. `set_debug_options` — mutate debug flags
11. `get_build_settings` — verify debug flags changed
12. `validate_build_settings` — validate the current configuration
13. `get_build_command` — get CLI export command for a platform

### Related Tools from Other Modules

| External Tool | Module | Relationship |
|--------------|--------|-------------|
| `list_export_presets` | `export.ts` | Use to discover valid platform preset names before calling `get_build_command` |
| `export_project` | `export.ts` | Uses build settings configured here; call after `get_build_settings` confirms desired state |
| `validate_export` | `export.ts` | Complements `validate_build_settings` with resource-level validation |

---

## Tool: `get_build_settings`

**Description**: Get all build configuration settings (debug/release, scripting backend, features)

**Parameters**: None (`inputSchema: {}`)

**Bridge call**: `build_config/get_settings`

**Expected return structure**:
```json
{
  "success": true,
  "settings": {
    "configuration": "debug" | "release" | "development",
    "scripting_backend": "gdscript" | "csharp",
    "export_filter": "all_resources" | "selected_resources",
    "custom_features": ["feature1", "feature2"],
    "debug_options": {
      "debug_build": true,
      "release_debug": false,
      "optimize": false
    }
  }
}
```

### Test Scenarios

#### 1.1 — Happy path: retrieve all build settings

- **Description**: Call with no params, verify all setting groups are returned.
- **Params**: `{}`
- **Expected result**: `isError` is absent or `false`. Response contains `success: true` and `settings` object with keys `configuration`, `scripting_backend`, `export_filter`, `custom_features`, `debug_options`.
- **Notes**: This is the baseline read — all subsequent mutation tests depend on this working.
- **Attention**: Verify each sub-key is present. `debug_options` should be an object with `debug_build`, `release_debug`, `optimize`. `custom_features` should be an array (possibly empty). The exact default values depend on the Godot project state.

#### 1.2 — Verify defaults on fresh project

- **Description**: On a fresh/default Godot project, check that defaults match expected Godot values.
- **Params**: `{}`
- **Expected result**:
  - `configuration` = `"debug"`
  - `scripting_backend` = `"gdscript"`
  - `export_filter` = `"all_resources"`
  - `custom_features` = `[]` (empty array)
  - `debug_options.debug_build` = `true`
  - `debug_options.release_debug` = `false`
  - `debug_options.optimize` = `false`
- **Notes**: Defaults come from Godot's `ProjectSettings`. The GDScript handler reads from project settings or falls back to these values.
- **Attention**: If the project has been previously configured, values may differ. This test is most meaningful on a clean project or after running the restore-defaults workflow.

---

## Tool: `set_build_configuration`

**Description**: Set the build configuration preset

**Parameters**:

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `config` | `enum('debug', 'release', 'development')` | no | `'debug'` | Build configuration: debug = full symbols, release = optimized, development = release with debug |

**Bridge call**: `build_config/set_configuration`

**Handler logic**:
- Sets the build configuration preset in Godot project settings.
- `debug`: full debug symbols, no optimizations.
- `release`: optimized build, no debug symbols.
- `development`: release build with debug info included.
- Returns `{ success, configuration }`.

### Test Scenarios

#### 2.1 — Happy path: set to debug

- **Description**: Explicitly set the configuration to `debug`.
- **Params**: `{ "config": "debug" }`
- **Expected result**: `{ "success": true, "configuration": "debug" }`
- **Notes**: Verify via `get_build_settings` that `settings.configuration = "debug"`.
- **Attention**: This is the default value, so calling without params should produce the same result.

#### 2.2 — Happy path: set to release

- **Description**: Set the configuration to `release`.
- **Params**: `{ "config": "release" }`
- **Expected result**: `{ "success": true, "configuration": "release" }`
- **Notes**: Verify via `get_build_settings` that `settings.configuration = "release"`.
- **Attention**: The `release` preset enables optimizations and strips debug symbols. Subsequent `set_debug_options` calls may interact with this.

#### 2.3 — Happy path: set to development

- **Description**: Set the configuration to `development`.
- **Params**: `{ "config": "development" }`
- **Expected result**: `{ "success": true, "configuration": "development" }`
- **Notes**: Verify via `get_build_settings` that `settings.configuration = "development"`.
- **Attention**: `development` is a hybrid mode — it has release optimizations but retains debug info. This is useful for profiling release-like builds.

#### 2.4 — Happy path: call with no params (default)

- **Description**: Call with empty object — should apply the default `debug`.
- **Params**: `{}`
- **Expected result**: `{ "success": true, "configuration": "debug" }`
- **Notes**: Tests the `.default('debug')` behavior of the Zod schema.
- **Attention**: The Zod schema uses `.optional().default('debug')`, so empty params should resolve to `config: "debug"`.

#### 2.5 — Edge case: invalid enum value

- **Description**: Pass a configuration value not in the allowed set.
- **Params**: `{ "config": "profile" }`
- **Expected result**: MCP-level validation error. `config` is `z.enum(['debug', 'release', 'development'])`, so `"profile"` should be rejected by Zod.
- **Notes**: Tests enum constraint enforcement.

#### 2.6 — Edge case: config as number instead of string

- **Description**: Pass a numeric value for `config`.
- **Params**: `{ "config": 1 }`
- **Expected result**: MCP-level validation error. Zod enum expects a string.
- **Notes**: Tests type enforcement.

---

## Tool: `set_scripting_backend`

**Description**: Set the scripting backend for the project

**Parameters**:

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `backend` | `enum('gdscript', 'csharp')` | no | `'gdscript'` | Scripting language backend |

**Bridge call**: `build_config/set_scripting_backend`

**Handler logic**:
- Sets the scripting backend in Godot project settings.
- `gdscript`: Godot's built-in scripting language.
- `csharp`: C# via .NET (requires Godot .NET build).
- Returns `{ success, backend }`.

### Test Scenarios

#### 3.1 — Happy path: set to gdscript

- **Description**: Explicitly set the backend to `gdscript`.
- **Params**: `{ "backend": "gdscript" }`
- **Expected result**: `{ "success": true, "backend": "gdscript" }`
- **Notes**: Verify via `get_build_settings` that `settings.scripting_backend = "gdscript"`.
- **Attention**: This is the default value.

#### 3.2 — Happy path: set to csharp

- **Description**: Set the backend to `csharp`.
- **Params**: `{ "backend": "csharp" }`
- **Expected result**: `{ "success": true, "backend": "csharp" }`
- **Notes**: Verify via `get_build_settings` that `settings.scripting_backend = "csharp"`.
- **Attention**: Setting `csharp` only works if the Godot editor is a .NET build. On a standard (GDScript-only) Godot build, this may fail or have no effect. The GDScript handler may return an error or warning.

#### 3.3 — Happy path: call with no params (default)

- **Description**: Call with empty object — should apply the default `gdscript`.
- **Params**: `{}`
- **Expected result**: `{ "success": true, "backend": "gdscript" }`
- **Notes**: Tests the `.default('gdscript')` behavior.

#### 3.4 — Edge case: invalid enum value

- **Description**: Pass an unsupported backend.
- **Params**: `{ "backend": "python" }`
- **Expected result**: MCP-level validation error. `backend` is `z.enum(['gdscript', 'csharp'])`.
- **Notes**: Tests enum constraint.

#### 3.5 — Edge case: empty string

- **Description**: Pass an empty string for backend.
- **Params**: `{ "backend": "" }`
- **Expected result**: MCP-level validation error. Empty string is not in the enum.
- **Notes**: Tests that the enum rejects empty values.

---

## Tool: `set_export_filter`

**Description**: Set which resources to include in exports

**Parameters**:

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `filter` | `enum('all_resources', 'selected_resources')` | no | `'all_resources'` | Export filter mode |

**Bridge call**: `build_config/set_export_filter`

**Handler logic**:
- Sets the export resource filter in Godot project settings.
- `all_resources`: include all project resources in the export.
- `selected_resources`: include only explicitly selected resources.
- Returns `{ success, filter }`.

### Test Scenarios

#### 4.1 — Happy path: set to all_resources

- **Description**: Explicitly set the filter to `all_resources`.
- **Params**: `{ "filter": "all_resources" }`
- **Expected result**: `{ "success": true, "filter": "all_resources" }`
- **Notes**: Verify via `get_build_settings` that `settings.export_filter = "all_resources"`.
- **Attention**: This is the default value.

#### 4.2 — Happy path: set to selected_resources

- **Description**: Set the filter to `selected_resources`.
- **Params**: `{ "filter": "selected_resources" }`
- **Expected result**: `{ "success": true, "filter": "selected_resources" }`
- **Notes**: Verify via `get_build_settings` that `settings.export_filter = "selected_resources"`.
- **Attention**: When using `selected_resources`, the actual resource selection is configured elsewhere (likely in the export preset configuration or via `export.ts` tools). This tool only sets the filter mode.

#### 4.3 — Happy path: call with no params (default)

- **Description**: Call with empty object — should apply the default `all_resources`.
- **Params**: `{}`
- **Expected result**: `{ "success": true, "filter": "all_resources" }`
- **Notes**: Tests the `.default('all_resources')` behavior.

#### 4.4 — Edge case: invalid enum value

- **Description**: Pass an unsupported filter mode.
- **Params**: `{ "filter": "none" }`
- **Expected result**: MCP-level validation error. `filter` is `z.enum(['all_resources', 'selected_resources'])`.
- **Notes**: Tests enum constraint.

#### 4.5 — Edge case: boolean instead of string

- **Description**: Pass a boolean value for filter.
- **Params**: `{ "filter": true }`
- **Expected result**: MCP-level validation error. Zod enum expects a string.
- **Notes**: Tests type enforcement.

---

## Tool: `set_custom_features`

**Description**: Set custom feature tags for conditional compilation and export

**Parameters**:

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `features` | `array(string)` | no | `[]` | List of custom feature tags (e.g. `['demo', 'mobile', 'premium']`) |

**Bridge call**: `build_config/set_custom_features`

**Handler logic**:
- Sets custom feature tags in Godot project settings.
- Feature tags are used for conditional logic in scripts (`OS.has_feature("tag")`) and export filtering.
- Replaces the entire feature list (does not append).
- Returns `{ success, features }`.

### Test Scenarios

#### 5.1 — Happy path: set a single feature tag

- **Description**: Set a single custom feature tag.
- **Params**: `{ "features": ["demo"] }`
- **Expected result**: `{ "success": true, "features": ["demo"] }`
- **Notes**: Verify via `get_build_settings` that `settings.custom_features` contains `"demo"`.
- **Attention**: The array is replaced, not appended. Previous features are cleared.

#### 5.2 — Happy path: set multiple feature tags

- **Description**: Set multiple custom feature tags.
- **Params**: `{ "features": ["demo", "mobile", "premium"] }`
- **Expected result**: `{ "success": true, "features": ["demo", "mobile", "premium"] }`
- **Notes**: Verify via `get_build_settings` that all three tags are present.
- **Attention**: Order may or may not be preserved by the GDScript handler — test should not depend on order.

#### 5.3 — Happy path: clear all features (empty array)

- **Description**: Clear all custom features by passing an empty array.
- **Params**: `{ "features": [] }`
- **Expected result**: `{ "success": true, "features": [] }`
- **Notes**: Verify via `get_build_settings` that `settings.custom_features = []`.
- **Attention**: This is the default state. Useful as a cleanup step.

#### 5.4 — Happy path: call with no params (default)

- **Description**: Call with empty object — should apply the default empty array.
- **Params**: `{}`
- **Expected result**: `{ "success": true, "features": [] }`
- **Notes**: Tests the `.default([])` behavior.

#### 5.5 — Edge case: feature tags with special characters

- **Description**: Set feature tags containing special characters.
- **Params**: `{ "features": ["my-feature_v2", "beta.1", "debug_mode"] }`
- **Expected result**: `{ "success": true, "features": ["my-feature_v2", "beta.1", "debug_mode"] }`
- **Notes**: Godot feature tags are strings — verify that hyphens, underscores, dots are accepted.
- **Attention**: If the GDScript handler validates tag format (e.g., alphanumeric only), some of these may be rejected. Test to determine the actual behavior.

#### 5.6 — Edge case: duplicate feature tags

- **Description**: Pass duplicate tags in the array.
- **Params**: `{ "features": ["demo", "demo", "mobile"] }`
- **Expected result**: Likely `{ "success": true, "features": ["demo", "demo", "mobile"] }` (echoed as-is) or `{ "success": true, "features": ["demo", "mobile"] }` (deduplicated).
- **Notes**: Test whether the GDScript handler deduplicates. The Zod schema (`z.array(z.string())`) allows duplicates.
- **Attention**: If the handler does not deduplicate, `OS.has_feature("demo")` will still work correctly (it checks presence, not count). But the `get_build_settings` response should be checked.

#### 5.7 — Edge case: non-string elements in array

- **Description**: Pass non-string elements in the features array.
- **Params**: `{ "features": [123, true, null] }`
- **Expected result**: MCP-level validation error. `features` is `z.array(z.string())`, so non-string elements should be rejected.
- **Notes**: Tests array element type enforcement.

---

## Tool: `set_debug_options`

**Description**: Configure debug and optimization options

**Parameters**:

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `debug_build` | `boolean` | no | — | Enable debug build (includes symbols) |
| `release_debug` | `boolean` | no | — | Release build with debug info |
| `optimize` | `boolean` | no | — | Enable optimizations |

**Bridge call**: `build_config/set_debug_options`

**Handler logic**:
- Sets individual debug/optimization flags in Godot project settings.
- All three params are optional — only provided params are changed.
- If no params are provided, behavior depends on GDScript handler (may return error or no-op).
- Returns `{ success, debug_options }`.

### Test Scenarios

#### 6.1 — Happy path: enable debug_build only

- **Description**: Set only `debug_build` to true.
- **Params**: `{ "debug_build": true }`
- **Expected result**: `{ "success": true, "debug_options": { "debug_build": true, ... } }`
- **Notes**: Verify via `get_build_settings` that `settings.debug_options.debug_build = true`.
- **Attention**: The response should include the full `debug_options` object showing the current state of all three flags.

#### 6.2 — Happy path: enable optimize only

- **Description**: Set only `optimize` to true.
- **Params**: `{ "optimize": true }`
- **Expected result**: `{ "success": true, "debug_options": { "optimize": true, ... } }`
- **Notes**: Verify via `get_build_settings` that `settings.debug_options.optimize = true`.

#### 6.3 — Happy path: enable release_debug only

- **Description**: Set only `release_debug` to true.
- **Params**: `{ "release_debug": true }`
- **Expected result**: `{ "success": true, "debug_options": { "release_debug": true, ... } }`
- **Notes**: Verify via `get_build_settings` that `settings.debug_options.release_debug = true`.

#### 6.4 — Happy path: set all three flags together

- **Description**: Set all three debug options at once.
- **Params**: `{ "debug_build": false, "release_debug": true, "optimize": true }`
- **Expected result**: `{ "success": true, "debug_options": { "debug_build": false, "release_debug": true, "optimize": true } }`
- **Notes**: This configuration represents a development-like build (release with debug info and optimizations).
- **Attention**: Verify all three flags are reflected in `get_build_settings`.

#### 6.5 — Happy path: disable all optimizations

- **Description**: Set all flags to false.
- **Params**: `{ "debug_build": false, "release_debug": false, "optimize": false }`
- **Expected result**: `{ "success": true, "debug_options": { "debug_build": false, "release_debug": false, "optimize": false } }`
- **Notes**: This is the most stripped-down configuration.

#### 6.6 — Edge case: no params at all

- **Description**: Call with empty object — no debug options provided.
- **Params**: `{}`
- **Expected result**: Either a success no-op (if the handler treats missing params as "don't change") or an error message like "No debug options provided". The GDScript handler's behavior should be verified.
- **Notes**: All three params are `.optional()` in the Zod schema, so MCP validation passes. The GDScript handler determines the actual behavior.
- **Attention**: This is a potential ambiguity — does the handler require at least one param? Check the GDScript implementation.

#### 6.7 — Edge case: invalid type for debug_build (string instead of bool)

- **Description**: Pass a string value for `debug_build`.
- **Params**: `{ "debug_build": "yes" }`
- **Expected result**: MCP-level validation error. `debug_build` is `z.boolean()`, so a string should be rejected.
- **Notes**: Tests Zod boolean coercion boundaries.

#### 6.8 — Edge case: invalid type for optimize (number instead of bool)

- **Description**: Pass a number value for `optimize`.
- **Params**: `{ "optimize": 1 }`
- **Expected result**: MCP-level validation error. `optimize` is `z.boolean()`.
- **Notes**: Tests that `z.boolean()` does not coerce `1` to `true`.

---

## Tool: `validate_build_settings`

**Description**: Validate current build settings and return any errors or warnings

**Parameters**: None (`inputSchema: {}`)

**Bridge call**: `build_config/validate`

**Handler logic**:
- Reads the current build configuration and checks for inconsistencies or missing requirements.
- May check for: missing export templates, incompatible backend/config combinations, missing custom features referenced in scripts, etc.
- Returns `{ success, valid, errors: [], warnings: [] }`.

### Test Scenarios

#### 7.1 — Happy path: validate default settings

- **Description**: Call with no params on a project with default build settings.
- **Params**: `{}`
- **Expected result**: `{ "success": true, "valid": true, "errors": [], "warnings": [...] }`
- **Notes**: On a fresh project with default settings, validation should pass with no errors. Warnings may be present (e.g., "no export templates installed").
- **Attention**: `valid` should be `true` if there are no errors. Warnings alone should not make `valid` false.

#### 7.2 — Validate after setting release configuration

- **Description**: Set config to `release`, then validate.
- **Precondition**: Call `set_build_configuration` with `{ "config": "release" }` first.
- **Params**: `{}`
- **Expected result**: `{ "success": true, "valid": true, "errors": [], "warnings": [...] }`
- **Notes**: A release configuration with default GDScript backend should be valid.
- **Attention**: Warnings may include notes about export templates or optimization settings.

#### 7.3 — Validate after setting csharp backend (may warn)

- **Description**: Set backend to `csharp`, then validate.
- **Precondition**: Call `set_scripting_backend` with `{ "backend": "csharp" }` first.
- **Params**: `{}`
- **Expected result**: If running a non-.NET Godot build, expect `valid: false` with `errors` about .NET SDK not being available. If running a .NET build, expect `valid: true`.
- **Notes**: This tests the cross-tool interaction — `validate_build_settings` should detect incompatible backend choices.
- **Attention**: The exact error/warning messages depend on the Godot build type and installed SDK.

#### 7.4 — Validate after setting empty custom features

- **Description**: Set features to `[]`, then validate.
- **Precondition**: Call `set_custom_features` with `{ "features": [] }` first.
- **Params**: `{}`
- **Expected result**: `{ "success": true, "valid": true, "errors": [], "warnings": [...] }`
- **Notes**: Empty features should be valid.

#### 7.5 — Idempotency: validate twice

- **Description**: Call `validate_build_settings` twice in succession without changing anything.
- **Params**: `{}` (both calls)
- **Expected result**: Both calls return the same result. Second call should not error.
- **Notes**: Verifies that validation is read-only and idempotent.

---

## Tool: `get_build_command`

**Description**: Get the CLI command to export/build the project for a specific platform

**Parameters**:

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `platform` | `string` | **yes** | — | Target platform (e.g. `'windows'`, `'linux'`, `'web'`, `'android'`) |

**Bridge call**: `build_config/get_build_command`

**Handler logic**:
- Generates a Godot CLI export command for the specified platform.
- The command incorporates current build settings (config, backend, features, debug options).
- Returns `{ success, command, platform }` where `command` is the full CLI string.
- The generated command is typically: `godot --headless --export-release "preset_name" "output_path"` or similar.

### Test Scenarios

#### 8.1 — Happy path: get build command for Windows

- **Description**: Request the build command for Windows.
- **Params**: `{ "platform": "windows" }`
- **Expected result**: `{ "success": true, "command": "<godot_cli_export_command>", "platform": "windows" }`
- **Notes**: The `command` field should contain a valid Godot CLI export command string.
- **Attention**: Verify the command string contains the correct flags. If current config is `debug`, the command should include debug flags. If `release`, it should use `--export-release`. Check that the command references the correct platform preset.

#### 8.2 — Happy path: get build command for Linux

- **Description**: Request the build command for Linux.
- **Params**: `{ "platform": "linux" }`
- **Expected result**: `{ "success": true, "command": "<godot_cli_export_command>", "platform": "linux" }`
- **Notes**: Verify the platform name is reflected in the command.

#### 8.3 — Happy path: get build command for Web

- **Description**: Request the build command for web/HTML5.
- **Params**: `{ "platform": "web" }`
- **Expected result**: `{ "success": true, "command": "<godot_cli_export_command>", "platform": "web" }`
- **Notes**: Web exports use `--export-release` or `--export-debug` and produce `.html`/`.js`/`.wasm` files.
- **Attention**: The web platform name may be `"web"` or `"HTML5"` depending on Godot version. Test which format the handler expects.

#### 8.4 — Happy path: get build command for Android

- **Description**: Request the build command for Android.
- **Params**: `{ "platform": "android" }`
- **Expected result**: `{ "success": true, "command": "<godot_cli_export_command>", "platform": "android" }`
- **Notes**: Android exports may include additional flags for signing, APK/AAB format, etc.

#### 8.5 — Happy path: command reflects current build config

- **Description**: Set config to `release` first, then get build command.
- **Precondition**: Call `set_build_configuration` with `{ "config": "release" }`.
- **Params**: `{ "platform": "windows" }`
- **Expected result**: The `command` string should contain `--export-release` (not `--export-debug`).
- **Notes**: Tests that `get_build_command` reads the current build configuration.
- **Attention**: This is the key integration test — the command must reflect the actual project settings, not just the platform.

#### 8.6 — Happy path: command reflects debug config

- **Description**: Set config to `debug` first, then get build command.
- **Precondition**: Call `set_build_configuration` with `{ "config": "debug" }`.
- **Params**: `{ "platform": "linux" }`
- **Expected result**: The `command` string should contain `--export-debug`.
- **Notes**: Debug builds use the debug export flag.

#### 8.7 — Edge case: missing required `platform` param

- **Description**: Call without the required `platform` parameter.
- **Params**: `{}`
- **Expected result**: MCP-level validation error. `platform` is `z.string().describe(...)` with no `.optional()`, so it is required.
- **Notes**: Tests that required param validation works.

#### 8.8 — Edge case: unknown platform name

- **Description**: Pass a platform name that doesn't match any export preset.
- **Params**: `{ "platform": "nintendo_switch" }`
- **Expected result**: Either a GDScript-level error (`{ "success": false, "error": "No export preset found for platform 'nintendo_switch'" }`) or a command with a placeholder preset name.
- **Notes**: The handler likely maps platform names to export presets. An unrecognized platform should produce an error.
- **Attention**: Test the boundary between "platform is a free-form string" and "platform must match a known preset". The Zod schema allows any string — validation is on the GDScript side.

#### 8.9 — Edge case: empty string platform

- **Description**: Pass an empty string for platform.
- **Params**: `{ "platform": "" }`
- **Expected result**: Likely a GDScript-level error — empty platform name won't match any preset.
- **Notes**: The Zod schema accepts empty strings (no `.min(1)` constraint). The GDScript handler must handle this gracefully.
- **Attention**: This is a potential schema improvement — `platform` could use `z.string().min(1)`.

---

## Cross-Tool Workflow Scenarios

### W1 — Full build configuration workflow

**Steps**:
1. `get_build_settings` → record baseline
2. `set_build_configuration` with `{ "config": "release" }`
3. `set_scripting_backend` with `{ "backend": "gdscript" }`
4. `set_export_filter` with `{ "filter": "all_resources" }`
5. `set_custom_features` with `{ "features": ["premium", "steam"] }`
6. `set_debug_options` with `{ "debug_build": false, "release_debug": false, "optimize": true }`
7. `get_build_settings` → verify all changes reflected:
   - `configuration` = `"release"`
   - `scripting_backend` = `"gdscript"`
   - `export_filter` = `"all_resources"`
   - `custom_features` contains `"premium"` and `"steam"`
   - `debug_options.optimize` = `true`
8. `validate_build_settings` → verify no errors
9. `get_build_command` with `{ "platform": "windows" }` → verify command reflects release config

**Expected**: All mutations are reflected in reads. Validation passes. Build command is correct.

### W2 — Development config workflow

**Steps**:
1. `set_build_configuration` with `{ "config": "development" }`
2. `set_debug_options` with `{ "debug_build": false, "release_debug": true, "optimize": true }`
3. `set_custom_features` with `{ "features": ["beta"] }`
4. `get_build_settings` → verify configuration is `"development"`, features include `"beta"`, optimize is `true`
5. `validate_build_settings` → verify valid
6. `get_build_command` with `{ "platform": "linux" }` → verify command

**Expected**: Development-mode settings are applied and reflected in the build command.

### W3 — Platform-specific build command comparison

**Steps**:
1. `set_build_configuration` with `{ "config": "release" }`
2. `get_build_command` with `{ "platform": "windows" }` → record command
3. `get_build_command` with `{ "platform": "linux" }` → record command
4. `get_build_command` with `{ "platform": "web" }` → record command
5. `get_build_command` with `{ "platform": "android" }` → record command
6. Verify all commands are different (different platform presets) but share the same build config flags

**Expected**: Each platform produces a distinct command. All commands reflect the `release` configuration.

### W4 — Restore defaults after tests

**Steps**:
1. `set_build_configuration` with `{ "config": "debug" }`
2. `set_scripting_backend` with `{ "backend": "gdscript" }`
3. `set_export_filter` with `{ "filter": "all_resources" }`
4. `set_custom_features` with `{ "features": [] }`
5. `set_debug_options` with `{ "debug_build": true, "release_debug": false, "optimize": false }`
6. `get_build_settings` → verify all defaults restored

**Expected**: Settings return to Godot defaults. This should be run as cleanup after the test suite.

---

## Schema Validation Summary

| Tool | Required Params | Optional Params | Enum Constraints | Default Values |
|------|----------------|-----------------|-----------------|----------------|
| `get_build_settings` | — | — | — | — |
| `set_build_configuration` | — | `config` (enum) | `debug`, `release`, `development` | `debug` |
| `set_scripting_backend` | — | `backend` (enum) | `gdscript`, `csharp` | `gdscript` |
| `set_export_filter` | — | `filter` (enum) | `all_resources`, `selected_resources` | `all_resources` |
| `set_custom_features` | — | `features` (string[]) | — | `[]` |
| `set_debug_options` | — | `debug_build` (bool), `release_debug` (bool), `optimize` (bool) | — | — |
| `validate_build_settings` | — | — | — | — |
| `get_build_command` | `platform` (string) | — | — | — |

### Known Schema Gaps

1. **`get_build_command.platform`**: No `.min(1)` constraint — empty string is accepted by Zod but will fail at the GDScript handler level. Consider adding `z.string().min(1)`.
2. **`set_debug_options`**: All three params are optional. The handler behavior when NO params are provided is undefined — it may succeed as a no-op or return an error. This should be documented or enforced (at least one param required).
3. **`set_custom_features`**: No validation on individual feature tag format. Tags with spaces or special characters may cause issues in Godot's feature tag system.
4. **`set_build_configuration`**: The enum values (`debug`, `release`, `development`) are lowercase but Godot's internal representation may differ. Verify the GDScript handler maps these correctly.
5. **`set_scripting_backend`**: Setting `csharp` on a non-.NET Godot build may silently fail or produce an error. The schema allows it regardless of the Godot build type.
