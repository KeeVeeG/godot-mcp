# Build Configuration Test Plan

> **Source file:** `server/src/tools/build_config.ts`  
> **Shared types:** `server/src/tools/shared-types.ts`  
> **Tools covered:** 8 (`get_build_settings`, `set_build_configuration`, `set_scripting_backend`, `set_export_filter`, `set_custom_features`, `set_debug_options`, `validate_build_settings`, `get_build_command`)  
> **Generated:** 2026-07-08

---

## Schema Details

### Shared Imports

| Import | Zod Schema | Description |
|--------|-----------|-------------|
| `z` | Zod namespace | Used directly for `z.enum(...)`, `z.string()`, `z.boolean()`, `z.array(...)` |

### Parameter Summary

| Tool | Param | Type | Required | Default | Enum/Choices | Notes |
|------|-------|------|----------|---------|--------------|-------|
| `get_build_settings` | *(none)* | — | — | — | — | Takes no input |
| `set_build_configuration` | `config` | `enum` | no | `debug` | `debug`, `release`, `development` | Build configuration preset |
| `set_scripting_backend` | `backend` | `enum` | no | `gdscript` | `gdscript`, `csharp` | Scripting language backend |
| `set_export_filter` | `filter` | `enum` | no | `all_resources` | `all_resources`, `selected_resources` | Export resource filter mode |
| `set_custom_features` | `features` | `string[]` | no | `[]` | — | Custom feature tags, each element is a string |
| `set_debug_options` | `debug_build` | `boolean` | no | — | — | Enable debug build (includes symbols) |
| | `release_debug` | `boolean` | no | — | — | Release build with debug info |
| | `optimize` | `boolean` | no | — | — | Enable optimizations |
| `validate_build_settings` | *(none)* | — | — | — | — | Takes no input |
| `get_build_command` | `platform` | `string` | ✅ yes | — | — | Target platform name (e.g. 'windows', 'linux', 'web', 'android') |

---

## Tool: get_build_settings

### Schema

```typescript
{
  description: 'Get all build configuration settings (debug/release, scripting backend, features)',
  inputSchema: {},
}
```

### Handler

```typescript
async () => callGodot(bridge, 'build_config/get_settings')
```

### Tool Behavior

Reads the current build configuration from the Godot project. Returns all build-related settings including the active build configuration preset (debug/release/development), scripting backend (GDScript/C#), export filter mode, custom feature tags, and debug/optimization flags. Takes no parameters.

### Test Scenarios

#### Scenario 1: Basic happy path — get current build settings
- **Description:** Call `get_build_settings` on a project with default build settings.
- **Params:** `{}`
- **Expected result:** Returns a JSON object containing build configuration data. Expected fields include the configuration preset, scripting backend, export filter, custom features, and debug options. Response should have `content[0].type === 'text'` with a non-empty text value. `isError` should not be set or be `false`.
- **Notes:** The exact structure depends on what Godot returns via the bridge. At minimum it should not be an error.

#### Scenario 2: Call with unexpected extra params
- **Description:** Verify the tool ignores extraneous parameters since `inputSchema` is empty `{}`.
- **Params:** `{ "unexpected_param": true, "another": "value" }`
- **Expected result:** Should succeed identically to Scenario 1. Extraneous params should be stripped by Zod (empty schema accepts and discards extra fields).
- **Notes:** Tests robustness against misconfigured clients.

#### Scenario 3: Call with no arguments at all
- **Description:** Call the tool with `undefined` (no params object at all).
- **Params:** *(omit params entirely)*
- **Expected result:** Should succeed — the empty schema should accept `undefined` input.
- **Notes:** Validates the handler handles a missing args object gracefully.

---

## Tool: set_build_configuration

### Schema

```typescript
{
  description: 'Set the build configuration preset',
  inputSchema: {
    config: z
      .enum(['debug', 'release', 'development'])
      .optional()
      .default('debug')
      .describe('Build configuration (debug: full symbols, release: optimized, development: release with debug) (default: debug)'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'build_config/set_configuration', args as Record<string, unknown>)
```

### Tool Behavior

Sets the active build configuration preset for the project. Three presets are available:
- **`debug`**: Full debug symbols, no optimization. Used for development and debugging.
- **`release`**: Optimized build, no debug symbols. Used for final shipping builds.
- **`development`**: Release build with debug info included. A middle ground — optimized but debuggable.

The `config` parameter is optional and defaults to `debug`.

### Test Scenarios

#### Scenario 1: Happy path — set configuration to `debug` (default)
- **Description:** Call `set_build_configuration` with no params, using the default `debug` value.
- **Params:** `{}`
- **Expected result:** The build configuration is set to `debug`. Returns a success response from the Godot bridge. Follow up with `get_build_settings` to confirm the config preset is `debug`.
- **Notes:** Since the default is `debug`, this should be a no-op on a fresh project.

#### Scenario 2: Set configuration to `release`
- **Description:** Explicitly set the build configuration to the `release` preset.
- **Params:** `{ "config": "release" }`
- **Expected result:** The build configuration is set to `release`. Returns success. Verify with `get_build_settings` that the configuration reflects `release`.
- **Notes:** Validates that the `release` enum value is accepted and forwarded correctly.

#### Scenario 3: Set configuration to `development`
- **Description:** Set the build configuration to the `development` preset.
- **Params:** `{ "config": "development" }`
- **Expected result:** The build configuration is set to `development`. Returns success. Verify with `get_build_settings`.
- **Notes:** Validates that `development` enum value is accepted.

#### Scenario 4: Invalid enum value — non-existent config option
- **Description:** Pass a config value that is not in the enum.
- **Params:** `{ "config": "production" }`
- **Expected result:** Zod validation should reject this input. The tool should return an error (validation failure) before even reaching the Godot bridge. Expect an error about invalid enum value — e.g. "enum" with received "production".
- **Notes:** Tests input validation at the Zod schema level. `production` is not one of `debug`, `release`, `development`.

#### Scenario 5: Invalid type — number instead of string
- **Description:** Pass a number value for `config` instead of a string.
- **Params:** `{ "config": 1 }`
- **Expected result:** Zod validation should reject this. Expect a type error — e.g. "Expected string, received number".
- **Notes:** Zod's `z.enum()` expects strings. Passing a number should fail validation.

#### Scenario 6: Invalid type — boolean instead of string
- **Description:** Pass a boolean value for `config`.
- **Params:** `{ "config": true }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Even though `true` is truthy, it's not a valid enum member.

#### Scenario 7: Empty string as config value
- **Description:** Pass an empty string for `config`.
- **Params:** `{ "config": "" }`
- **Expected result:** Zod validation should reject this — empty string is not one of `debug`, `release`, `development`. Expect an enum validation error.
- **Notes:** Edge case for empty input.

#### Scenario 8: Extra unexpected params included
- **Description:** Pass valid `config` along with extra unknown parameters.
- **Params:** `{ "config": "release", "extra_field": "should_be_ignored" }`
- **Expected result:** Should succeed with `config` set to `release`. The extra field should be stripped by Zod or ignored. Behavior depends on strict mode — if Zod strips, it works; if the bridge ignores extras, it also works.
- **Notes:** Tests tolerance for superfluous fields.

---

## Tool: set_scripting_backend

### Schema

```typescript
{
  description: 'Set the scripting backend for the project',
  inputSchema: {
    backend: z.enum(['gdscript', 'csharp']).optional().default('gdscript').describe('Scripting language backend: gdscript or csharp (default: gdscript)'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'build_config/set_scripting_backend', args as Record<string, unknown>)
```

### Tool Behavior

Sets the scripting backend used by the Godot project. Two backends are available:
- **`gdscript`**: Godot's native scripting language. The default backend.
- **`csharp`**: C# scripting via .NET/Mono. Requires Mono or .NET SDK installed.

Switching between backends may require project reconfiguration (e.g. generating `.csproj` files for C#).

### Test Scenarios

#### Scenario 1: Happy path — set backend to `gdscript` (default)
- **Description:** Call `set_scripting_backend` with no params, using the default `gdscript` value.
- **Params:** `{}`
- **Expected result:** The scripting backend is set to `gdscript`. Returns success. Verify with `get_build_settings` that the backend is `gdscript`.
- **Notes:** Should be a no-op on a project already using GDScript.

#### Scenario 2: Set backend to `csharp`
- **Description:** Set the scripting backend to C#.
- **Params:** `{ "backend": "csharp" }`
- **Expected result:** The scripting backend is set to `csharp`. Returns success. Verify with `get_build_settings` that the backend is `csharp`.
- **Notes:** This change may require a Mono/.NET SDK to be functional. The tool itself should not error — it only sets the project setting. Verify that switching back to `gdscript` still works.

#### Scenario 3: Invalid enum value — non-existent backend
- **Description:** Pass a backend value not in the enum.
- **Params:** `{ "backend": "python" }`
- **Expected result:** Zod validation should reject. Expect an error about invalid enum — "python" is not `gdscript` or `csharp`.
- **Notes:** Tests that only recognized backends are accepted.

#### Scenario 4: Invalid type — number
- **Description:** Pass a number for `backend`.
- **Params:** `{ "backend": 42 }`
- **Expected result:** Zod validation should reject. Expect a type error.
- **Notes:** Type safety test.

#### Scenario 5: Case sensitivity — uppercase vs lowercase
- **Description:** Pass `backend` in uppercase instead of lowercase.
- **Params:** `{ "backend": "GDSCRIPT" }`
- **Expected result:** Zod validation should reject — `"GDSCRIPT"` is not `"gdscript"`. Enum matching is case-sensitive. Expect an enum validation error.
- **Notes:** Zod's `z.enum()` is case-sensitive. This validates that the tool does not accidentally accept wrong casing.

#### Scenario 6: Explicit gdscript with the enum value
- **Description:** Explicitly set `backend` to `gdscript`.
- **Params:** `{ "backend": "gdscript" }`
- **Expected result:** Same as Scenario 1 — backend set to `gdscript`, returns success.
- **Notes:** Validates explicit parameter passing works as expected.

---

## Tool: set_export_filter

### Schema

```typescript
{
  description: 'Set which resources to include in exports',
  inputSchema: {
    filter: z.enum(['all_resources', 'selected_resources']).optional().default('all_resources').describe('Export filter mode (default: all_resources)'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'build_config/set_export_filter', args as Record<string, unknown>)
```

### Tool Behavior

Configures the resource export filter mode for the Godot project:
- **`all_resources`**: All project resources are included when exporting. This is the default.
- **`selected_resources`**: Only explicitly selected resources are included in exports. Resources must be individually marked for export.

### Test Scenarios

#### Scenario 1: Happy path — set filter to `all_resources` (default)
- **Description:** Call `set_export_filter` with no params, using the default `all_resources` value.
- **Params:** `{}`
- **Expected result:** The export filter is set to `all_resources`. Returns success. Verify with `get_build_settings` that the export filter reads `all_resources`.
- **Notes:** Default behavior — everything is exported.

#### Scenario 2: Set filter to `selected_resources`
- **Description:** Set the export filter to only include selected resources.
- **Params:** `{ "filter": "selected_resources" }`
- **Expected result:** The export filter is set to `selected_resources`. Returns success. Verify with `get_build_settings`.
- **Notes:** After this change, only explicitly selected resources will be included in exports. This is a project-wide setting.

#### Scenario 3: Invalid enum value
- **Description:** Pass a filter value not in the enum.
- **Params:** `{ "filter": "none" }`
- **Expected result:** Zod validation should reject. Expect an enum validation error — `"none"` is not `all_resources` or `selected_resources`.
- **Notes:** Tests enum validation.

#### Scenario 4: Invalid type — boolean
- **Description:** Pass a boolean for `filter`.
- **Params:** `{ "filter": false }`
- **Expected result:** Zod validation should reject. Expect a type error.
- **Notes:** Type coercion check.

#### Scenario 5: Explicit all_resources with the enum value
- **Description:** Explicitly set `filter` to `all_resources`.
- **Params:** `{ "filter": "all_resources" }`
- **Expected result:** Same as Scenario 1 — filter set to `all_resources`, returns success.
- **Notes:** Validates explicit parameter works identically to default.

---

## Tool: set_custom_features

### Schema

```typescript
{
  description: 'Set custom feature tags for conditional compilation and export',
  inputSchema: {
    features: z.array(z.string()).optional().default([]).describe("List of custom feature tags (e.g. ['demo', 'mobile', 'premium'])"),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'build_config/set_custom_features', args as Record<string, unknown>)
```

### Tool Behavior

Sets the custom feature tags for the project. These tags are used for conditional compilation (`OS.has_feature()`) and export configuration. Each feature tag is a string identifier. Passing an empty array `[]` clears all custom features.

### Test Scenarios

#### Scenario 1: Happy path — set a single custom feature
- **Description:** Set one custom feature tag.
- **Params:** `{ "features": ["demo"] }`
- **Expected result:** The custom features are set to `["demo"]`. Returns success. Verify with `get_build_settings` that features includes `"demo"`.
- **Notes:** Basic single-feature test.

#### Scenario 2: Set multiple custom features
- **Description:** Set several feature tags simultaneously.
- **Params:** `{ "features": ["demo", "mobile", "premium"] }`
- **Expected result:** The custom features are set to `["demo", "mobile", "premium"]`. Returns success. Verify all three features appear in `get_build_settings`.
- **Notes:** Tests array of multiple string elements.

#### Scenario 3: Clear all custom features (default empty array)
- **Description:** Call `set_custom_features` with no params, which defaults to `[]`.
- **Params:** `{}`
- **Expected result:** All custom features are cleared (set to an empty list). Returns success. Verify with `get_build_settings` that features is `[]` or absent.
- **Notes:** The default `[]` should clear any previously set features.

#### Scenario 4: Explicit empty array
- **Description:** Explicitly pass an empty features array.
- **Params:** `{ "features": [] }`
- **Expected result:** Same as Scenario 3 — all custom features cleared. Returns success.
- **Notes:** Validates explicit `[]` works identically to default.

#### Scenario 5: Single-element array with special characters
- **Description:** Set a feature tag containing special characters (hyphens, underscores).
- **Params:** `{ "features": ["my-feature_v2"] }`
- **Expected result:** The feature `"my-feature_v2"` is set. Returns success. Verify the tag appears in `get_build_settings`.
- **Notes:** Feature tags are arbitrary strings — tests that non-alphanumeric chars are passed through.

#### Scenario 6: Invalid type — string instead of array
- **Description:** Pass a plain string instead of an array of strings.
- **Params:** `{ "features": "demo" }`
- **Expected result:** Zod validation should reject. Expect a type error — `"Expected array, received string"`.
- **Notes:** `z.array(z.string())` requires an array, not a single string.

#### Scenario 7: Invalid type — array with non-string elements
- **Description:** Pass an array containing a number and a boolean.
- **Params:** `{ "features": ["demo", 123, true] }`
- **Expected result:** Zod validation should reject because not all elements are strings. Expect a type error about invalid element types.
- **Notes:** `z.array(z.string())` requires every element to be a string.

#### Scenario 8: Invalid type — null
- **Description:** Pass `null` for features.
- **Params:** `{ "features": null }`
- **Expected result:** Zod should reject or coerce to default `[]`. If Zod is strict (`z.array(z.string()).optional().default([])`), `null` should be rejected or defaulted. Expect either validation error or default `[]` behavior.
- **Notes:** Depends on Zod's null handling for optional fields. Most likely rejected.

#### Scenario 9: Large list of features
- **Description:** Pass a large array of feature tags (e.g. 50+ elements).
- **Params:** `{ "features": ["tag1", "tag2", ..., "tag50"] }` (50 distinct string tags)
- **Expected result:** All feature tags are set successfully. Returns success. Verify the full list appears in `get_build_settings`.
- **Notes:** Boundary test — validates that large arrays are handled correctly by the bridge.

---

## Tool: set_debug_options

### Schema

```typescript
{
  description: 'Configure debug and optimization options',
  inputSchema: {
    debug_build: z.boolean().optional().describe('Enable debug build (includes symbols)'),
    release_debug: z.boolean().optional().describe('Release build with debug info'),
    optimize: z.boolean().optional().describe('Enable optimizations'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'build_config/set_debug_options', args as Record<string, unknown>)
```

### Tool Behavior

Configures individual debug and optimization flags for the project build. All three parameters are optional booleans:
- **`debug_build`**: When `true`, the build includes debug symbols. When `false`, symbols are excluded.
- **`release_debug`**: When `true`, release builds include debug information (useful for profiling release builds).
- **`optimize`**: When `true`, the compiler applies optimizations. When `false`, optimizations are disabled.

Multiple options can be set simultaneously in a single call. Omitted options are left unchanged (the bridge handles partial updates).

### Test Scenarios

#### Scenario 1: Happy path — set all options to true
- **Description:** Enable all three debug/optimization options.
- **Params:** `{ "debug_build": true, "release_debug": true, "optimize": true }`
- **Expected result:** All three options are set to `true`. Returns success. Verify with `get_build_settings` that all three flags are `true`.
- **Notes:** Tests setting all available options at once.

#### Scenario 2: Set all options to false
- **Description:** Disable all three options.
- **Params:** `{ "debug_build": false, "release_debug": false, "optimize": false }`
- **Expected result:** All three options are set to `false`. Returns success. Verify with `get_build_settings` that all three flags are `false`.
- **Notes:** Tests setting all options to their negative state.

#### Scenario 3: Set only `debug_build` (partial update)
- **Description:** Set `debug_build` to `true` while omitting the other two options.
- **Params:** `{ "debug_build": true }`
- **Expected result:** `debug_build` is set to `true`. The other options (`release_debug`, `optimize`) should retain their previous values. Returns success. Verify only `debug_build` changed.
- **Notes:** Tests partial update behavior — omitted params should not be affected.

#### Scenario 4: Set only `release_debug`
- **Description:** Set `release_debug` to `true` with no other options.
- **Params:** `{ "release_debug": true }`
- **Expected result:** `release_debug` is set to `true`. Other options unchanged. Returns success.
- **Notes:** Confirms individual option independence.

#### Scenario 5: Set only `optimize`
- **Description:** Set `optimize` to `false` with no other options.
- **Params:** `{ "optimize": false }`
- **Expected result:** `optimize` is set to `false`. Other options unchanged. Returns success.
- **Notes:** Confirms individual option independence.

#### Scenario 6: Mixed values — debug true, optimize false
- **Description:** Enable debug but disable optimization (common development config).
- **Params:** `{ "debug_build": true, "optimize": false }`
- **Expected result:** `debug_build` is `true`, `optimize` is `false`. `release_debug` unchanged. Returns success.
- **Notes:** Realistic development scenario.

#### Scenario 7: Call with empty params object
- **Description:** Call with no parameters at all.
- **Params:** `{}`
- **Expected result:** Since all params are optional, this should succeed as a no-op. No options change. Returns success (possibly with a "nothing to do" or empty success response).
- **Notes:** Validates that the tool works with zero options set.

#### Scenario 8: Invalid type — string for boolean param
- **Description:** Pass a string `"yes"` for `debug_build` instead of a boolean.
- **Params:** `{ "debug_build": "yes" }`
- **Expected result:** Zod validation should reject. Expect a type error — `"Expected boolean, received string"`.
- **Notes:** Type validation test.

#### Scenario 9: Invalid type — number for boolean param
- **Description:** Pass `1` for `optimize`.
- **Params:** `{ "optimize": 1 }`
- **Expected result:** Zod validation should reject. Zod's `z.boolean()` does not coerce numbers. Expect a type error.
- **Notes:** Tests that `1` is not treated as `true`.

#### Scenario 10: Unrecognized parameter name
- **Description:** Pass a param that doesn't exist in the schema.
- **Params:** `{ "debug_build": true, "fast_mode": true }`
- **Expected result:** `debug_build` is set to `true`. The unrecognized `fast_mode` should be silently stripped by Zod. Returns success.
- **Notes:** Tests tolerance for unknown field names.

#### Scenario 11: All three options with explicit boolean false
- **Description:** After enabling all (Scenario 1), revert with explicit `false` values.
- **Params:** `{ "debug_build": false, "release_debug": false, "optimize": false }`
- **Expected result:** All options revert to `false`. Returns success. Verify all three are `false`.
- **Notes:** Tests idempotent toggling behavior.

---

## Tool: validate_build_settings

### Schema

```typescript
{
  description: 'Validate current build settings and return any errors or warnings',
  inputSchema: {},
}
```

### Handler

```typescript
async () => callGodot(bridge, 'build_config/validate')
```

### Tool Behavior

Validates the current project build configuration for correctness. Checks project settings for inconsistencies, missing required values, or incompatible combinations (e.g., trying to use C# backend without .NET SDK, or export filters with no resources selected). Returns a list of errors and warnings, or an empty/success response if everything is valid. Takes no parameters.

### Test Scenarios

#### Scenario 1: Basic happy path — validate default build settings on a fresh project
- **Description:** Call `validate_build_settings` on a project with default build configuration.
- **Params:** `{}`
- **Expected result:** Returns validation results. On a valid default project, should return either no warnings/errors or a success message. Response content should describe the validation outcome. Not an error response (`isError` should not be `true` unless actual problems exist).
- **Notes:** The exact response format depends on the Godot bridge's validation logic. A fresh project should pass validation.

#### Scenario 2: Validate after changing settings (post-mutation check)
- **Description:** First set build configuration to `release` and scripting backend to `csharp`. Then call `validate_build_settings`.
- **Setup params:**
  1. `set_build_configuration({ "config": "release" })`
  2. `set_scripting_backend({ "backend": "csharp" })`
- **Params:** `{}`
- **Expected result:** Validation runs against the modified settings. May return warnings about C# backend requiring .NET SDK or other configuration items. The validation result should reflect the current state.
- **Notes:** Tests that validation reflects the current, not cached, project state.

#### Scenario 3: Call with unexpected extra params
- **Description:** Verify the tool ignores extraneous parameters.
- **Params:** `{ "detailed": true, "format": "json" }`
- **Expected result:** Should succeed identically to Scenario 1. Extra params are stripped by Zod's empty schema.
- **Notes:** Robustness test.

#### Scenario 4: Call with no arguments
- **Description:** Call with `undefined` (no params object).
- **Params:** *(omit params)*
- **Expected result:** Should succeed. The empty schema accepts `undefined`.
- **Notes:** Edge case for missing args.

---

## Tool: get_build_command

### Schema

```typescript
{
  description: 'Get the CLI command to export/build the project for a specific platform',
  inputSchema: {
    platform: z.string().describe("Target platform (e.g. 'windows', 'linux', 'web', 'android')"),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'build_config/get_build_command', args as Record<string, unknown>)
```

### Tool Behavior

Generates and returns the command-line invocation string for building/exporting the project for a specified target platform. The returned command can be used to run automated builds from a terminal or CI pipeline. The `platform` parameter is required and accepts a string describing the target platform. Common values include `windows`, `linux`, `macos`, `web`, `android`, `ios`.

### Test Scenarios

#### Scenario 1: Happy path — get build command for `windows`
- **Description:** Request the CLI build command for the Windows platform.
- **Params:** `{ "platform": "windows" }`
- **Expected result:** Returns a string containing the Godot CLI export command for Windows (e.g. `godot --headless --export-release "Windows Desktop"`). Response should be a text string. Not an error.
- **Notes:** The exact command format depends on the project's configured export presets and Godot version.

#### Scenario 2: Get build command for `linux`
- **Description:** Request the CLI build command for Linux.
- **Params:** `{ "platform": "linux" }`
- **Expected result:** Returns a string containing the Godot CLI export command for Linux. Success response with command text.
- **Notes:** Validates that different platform strings produce valid results.

#### Scenario 3: Get build command for `web`
- **Description:** Request the CLI build command for Web (HTML5).
- **Params:** `{ "platform": "web" }`
- **Expected result:** Returns a string containing the Godot CLI export command for Web. Success response.
- **Notes:** Web exports use the HTML5 export template.

#### Scenario 4: Get build command for `android`
- **Description:** Request the CLI build command for Android.
- **Params:** `{ "platform": "android" }`
- **Expected result:** Returns a string containing the Godot CLI export command for Android. May require Android SDK/export templates installed — the tool should still return a command string even if prerequisites are missing.
- **Notes:** The command itself should be generated regardless of whether the platform is actually configured.

#### Scenario 5: Get build command for `macos`
- **Description:** Request the CLI build command for macOS.
- **Params:** `{ "platform": "macos" }`
- **Expected result:** Returns a string containing the Godot CLI export command for macOS. Success response.
- **Notes:** Validates another common platform value.

#### Scenario 6: Get build command for `ios`
- **Description:** Request the CLI build command for iOS.
- **Params:** `{ "platform": "ios" }`
- **Expected result:** Returns a string containing the Godot CLI export command for iOS. May require macOS host and Xcode — the tool should still return a command string.
- **Notes:** Tests that even unconfigured platforms return a command template.

#### Scenario 7: Missing required `platform` parameter
- **Description:** Call `get_build_command` without the required `platform` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation should reject this. Since `platform` is `z.string()` (not `.optional()`), omitting it should produce a validation error — e.g. "Required" for field `platform`.
- **Notes:** This is the only tool in this module where the main parameter is REQUIRED (not optional). Tests that Zod enforces this.

#### Scenario 8: Empty string for platform
- **Description:** Pass an empty string as the platform.
- **Params:** `{ "platform": "" }`
- **Expected result:** `z.string()` accepts empty strings — it validates that it's a string, not that it's non-empty. The tool will forward `""` to the Godot bridge, which will likely return an error or an unrecognizable command. Expect either a Godot bridge error about an unknown platform, or a command string that doesn't work.
- **Notes:** Tests boundary case. `z.string()` allows empty strings unless `.min(1)` is added.

#### Scenario 9: Invalid type — number for platform
- **Description:** Pass a number instead of a string for `platform`.
- **Params:** `{ "platform": 123 }`
- **Expected result:** Zod validation should reject. Expect a type error — `"Expected string, received number"`.
- **Notes:** Basic type validation.

#### Scenario 10: Invalid type — boolean for platform
- **Description:** Pass `true` for platform.
- **Params:** `{ "platform": true }`
- **Expected result:** Zod validation should reject. Expect a type error.
- **Notes:** Type validation.

#### Scenario 11: Unknown/unusual platform string
- **Description:** Pass a platform string that Godot may not recognize (e.g. `playstation` or an arbitrary string `xbox`).
- **Params:** `{ "platform": "freebsd" }`
- **Expected result:** The tool should forward the string to the Godot bridge. The bridge may return an error (unknown platform) or may still generate a command. Either way, the MCP tool itself should not crash — validate that it returns some response (success with command or error about unsupported platform).
- **Notes:** Tests robustness against unrecognized platform identifiers.

#### Scenario 12: Platform string with special characters
- **Description:** Pass a platform string with spaces or special characters.
- **Params:** `{ "platform": "Windows Desktop" }`
- **Expected result:** The tool forwards the exact string. The bridge may match it to an export preset named `"Windows Desktop"` or return an error. The MCP tool should not crash.
- **Notes:** In Godot, export presets have display names like "Windows Desktop", "Linux/X11", "macOS". This tests that display names work as well as short platform IDs.

#### Scenario 13: Extra params alongside required platform
- **Description:** Pass extra unrecognized parameters.
- **Params:** `{ "platform": "windows", "arch": "x86_64", "debug": false }`
- **Expected result:** `platform` is forwarded to the bridge. Extra params `arch` and `debug` are stripped by Zod (not in schema). Should behave like Scenario 1.
- **Notes:** Robustness test.

---

## Cross-Tool Integration Scenarios

These scenarios test interactions between multiple build config tools in sequence.

### Scenario CT1: Full build configuration cycle — set, read, validate, get command
- **Description:** Execute a complete workflow: set configuration, read back settings, validate, and get build command.
- **Steps:**
  1. `set_build_configuration({ "config": "release" })` → success
  2. `set_scripting_backend({ "backend": "gdscript" })` → success
  3. `set_export_filter({ "filter": "all_resources" })` → success
  4. `set_custom_features({ "features": ["production", "steam"] })` → success
  5. `set_debug_options({ "debug_build": false, "optimize": true })` → success
  6. `get_build_settings()` → should reflect all above changes
  7. `validate_build_settings()` → should validate the current state
  8. `get_build_command({ "platform": "windows" })` → should return Windows export command reflecting the release/optimized config
- **Expected result:** All steps succeed. Settings persist across calls. The final `get_build_command` reflects the configured state.
- **Notes:** End-to-end workflow validation.

### Scenario CT2: Reset features and verify
- **Description:** Set custom features, then clear them, then verify.
- **Steps:**
  1. `set_custom_features({ "features": ["tagA", "tagB"] })` → success
  2. `get_build_settings()` → features should be `["tagA", "tagB"]`
  3. `set_custom_features({})` → success (defaults to `[]`)
  4. `get_build_settings()` → features should be `[]` or absent
- **Expected result:** Features are set and then cleared. No errors.
- **Notes:** Tests mutability of custom features.

### Scenario CT3: Toggle build configuration through all three presets
- **Description:** Cycle through `debug` → `release` → `development` → `debug` and verify each.
- **Steps:**
  1. `set_build_configuration({ "config": "debug" })` → success
  2. `get_build_settings()` → confirm config is `debug`
  3. `set_build_configuration({ "config": "release" })` → success
  4. `get_build_settings()` → confirm config is `release`
  5. `set_build_configuration({ "config": "development" })` → success
  6. `get_build_settings()` → confirm config is `development`
  7. `set_build_configuration({ "config": "debug" })` → success
  8. `get_build_settings()` → confirm config is back to `debug`
- **Expected result:** All transitions succeed. Settings are correctly updated at each step.
- **Notes:** Tests state transitions and round-trip consistency.

---

## Error Handling Summary

| Error Category | Tools Affected | Expected Behavior |
|---------------|---------------|-------------------|
| Invalid enum value | `set_build_configuration`, `set_scripting_backend`, `set_export_filter` | Zod validation error before bridge call |
| Wrong parameter type | All with params | Zod validation error (e.g. "Expected string, received number") |
| Missing required parameter | `get_build_command` | Zod validation error: "Required" |
| Godot bridge failure | All | `isError: true` with "Godot request failed: ..." message |
| Godot plugin not connected | All | `isError: true` with connection error from bridge |
| Empty/unknown platform | `get_build_command` | Godot bridge may error or return unrecognizable command |

---

## Notes for Test Execution

1. **Precondition:** All tests require a running Godot editor with the MCP plugin connected. If the plugin is not connected, all tools will return a connection error.
2. **State mutation:** Tools in this module are mutating (they change project settings). Run tests sequentially to avoid conflicting concurrent modifications.
3. **Verify with `get_build_settings`:** After any mutation (`set_*` tools), use `get_build_settings` to verify the change was persisted.
4. **Validation independence:** `validate_build_settings` is read-only — it can be called at any time without side effects.
5. **Platform string values:** For `get_build_command`, valid platform strings depend on the project's export presets. If a preset doesn't exist for the requested platform, the bridge may return an error rather than a command.
6. **C# backend:** Setting the scripting backend to `csharp` may require additional project setup (Mono/.NET SDK). The MCP tool should not crash regardless, but the project may not compile with C# until properly configured.
7. **Zod validation errors:** These occur on the MCP server side (TypeScript) before any request reaches Godot. Tests for invalid params should not require Godot to be connected — they can be tested at the schema level.
