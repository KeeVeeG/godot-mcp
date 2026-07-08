# Export Test Plan

> **Source file:** `server/src/tools/export.ts`  
> **Shared types:** `server/src/tools/shared-types.ts`  
> **Tools covered:** 7 (`list_export_presets`, `export_project`, `get_export_info`, `validate_export`, `get_export_templates`, `create_export_preset`, `delete_export_preset`)  
> **Generated:** 2026-07-08

---

## Schema Details

### Shared Imports

| Import | Zod Schema | Description |
|--------|-----------|-------------|
| `Name` | `z.string()` | Generic name identifier |
| `z` | Zod namespace | Used directly for `z.string()`, `z.boolean()`, etc. |

### Parameter Summary

| Tool | Param | Type | Required | Default | Enum/Choices | Notes |
|------|-------|------|----------|---------|--------------|-------|
| `list_export_presets` | *(none)* | — | — | — | — | Takes no input |
| `export_project` | `preset` | `string` | ✅ yes | — | — | Export preset name |
| | `output_path` | `string` | no | — | — | Custom output path for the built files |
| | `debug` | `boolean` | no | `false` | — | Export as debug build |
| | `pack_only` | `boolean` | no | `false` | — | Export as .pck pack file only |
| `get_export_info` | *(none)* | — | — | — | — | Takes no input |
| `validate_export` | *(none)* | — | — | — | — | Takes no input (args ignored) |
| `get_export_templates` | *(none)* | — | — | — | — | Takes no input |
| `create_export_preset` | `name` | `string` | ✅ yes | — | — | Preset name (identifier) |
| | `platform` | `string` | ✅ yes | — | — | Target platform (e.g. 'Windows Desktop', 'Linux', 'Android') |
| `delete_export_preset` | `name` | `string` | ✅ yes | — | — | Name of the export preset to delete |

---

## Tool: list_export_presets

### Schema

```typescript
{
  description: 'List all configured export presets',
  inputSchema: {},
}
```

### Handler

```typescript
async () => callGodot(bridge, 'export/list_presets')
```

### Tool Behavior
Lists all export presets configured in the Godot project. Each preset includes platform, name, and configuration details. Returns an array of preset objects.

### Test Scenarios

#### Scenario 1: Basic happy path — list presets on a fresh project
- **Description:** Call `list_export_presets` on a project with no manually created export presets.
- **Params:** `{}` (empty object or no params)
- **Expected result:** Returns a JSON array of preset objects. On a fresh project, this is typically empty (`[]`) or contains only the default/auto-detected platform presets. Should not error.
- **Notes:** The response structure depends on what Godot pre-configures. At minimum, it should return a valid JSON array.

#### Scenario 2: List presets after creating one
- **Description:** Create an export preset first, then list presets.
- **Params:** `{}`
- **Expected result:** The array should include the newly created preset with its name and platform.
- **Notes:** Use `create_export_preset` first, then call this tool. See cross-tool integration scenarios.

#### Scenario 3: Call with unexpected extra params
- **Description:** Verify the tool ignores extraneous parameters since `inputSchema` is empty.
- **Params:** `{ "foo": "bar", "baz": 123 }`
- **Expected result:** Should succeed identically to Scenario 1. Extraneous params are stripped by Zod on an empty schema.
- **Notes:** Tests robustness against clients that may send extra fields.

#### Scenario 4: Call with no arguments object at all
- **Description:** Call the tool with an undefined/null args value.
- **Params:** `undefined` or `null`
- **Expected result:** Should succeed — the empty schema should accept any input.
- **Notes:** Validates the handler can handle a missing args object.

---

## Tool: export_project

### Schema

```typescript
{
  description: 'Export the project using a specific preset',
  inputSchema: {
    preset: Name.describe('Export preset name'),
    output_path: z.string().optional().describe('Output path for the export'),
    debug: z.boolean().optional().default(false).describe('Export as debug build (default: false = release)'),
    pack_only: z.boolean().optional().default(false).describe('Export as pack file only (default: false)'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'export/project', args as Record<string, unknown>)
```

### Tool Behavior
Triggers a full project export using the specified export preset. By default exports a release build. Supports custom output path, debug builds, and pack-only (.pck) exports.

### Test Scenarios

#### Scenario 1: Happy path — export with only preset name (all defaults)
- **Description:** Export the project using an existing preset with all default option values.
- **Params:** `{ "preset": "Windows Desktop" }`
- **Expected result:** Project is exported as a release build for the specified platform. Returns success with output path information.
- **Notes:** Requires a configured export preset named "Windows Desktop". The export may take several seconds.

#### Scenario 2: Happy path — export with debug=true
- **Description:** Export the project using an existing preset with `debug` explicitly set to `true`.
- **Params:** `{ "preset": "Windows Desktop", "debug": true }`
- **Expected result:** Project is exported as a debug build. The resulting executable includes debug symbols.
- **Notes:** Debug exports are typically larger and include console/debugging support.

#### Scenario 3: Happy path — export with debug=false (explicit release)
- **Description:** Export with `debug` explicitly set to `false` (same as default).
- **Params:** `{ "preset": "Windows Desktop", "debug": false }`
- **Expected result:** Project is exported as a release build. Identical behavior to Scenario 1.
- **Notes:** Validates that explicit `false` behaves the same as the default.

#### Scenario 4: Happy path — export with pack_only=true
- **Description:** Export as a .pck pack file only, not a full executable.
- **Params:** `{ "preset": "Windows Desktop", "pack_only": true }`
- **Expected result:** A .pck file is generated. No executable is built.
- **Notes:** Pack files are useful for DLC, patches, or when using a shared engine binary.

#### Scenario 5: Happy path — export with pack_only=false (explicit)
- **Description:** Export with `pack_only` explicitly set to `false`.
- **Params:** `{ "preset": "Windows Desktop", "pack_only": false }`
- **Expected result:** Full build including executable. Identical to Scenario 1.
- **Notes:** Validates that explicit `false` behaves the same as the default.

#### Scenario 6: Happy path — export with custom output_path
- **Description:** Export to a specific custom output directory.
- **Params:** `{ "preset": "Windows Desktop", "output_path": "C:/Builds/MyGame/export" }`
- **Expected result:** Build output is placed in the specified directory. Returns success with the output path.
- **Notes:** The output directory must be writable. Godot may create intermediate directories.

#### Scenario 7: Happy path — export with all params specified
- **Description:** Export with all four parameters explicitly set.
- **Params:** `{ "preset": "Windows Desktop", "output_path": "C:/Builds/MyGame/debug_export", "debug": true, "pack_only": true }`
- **Expected result:** Debug .pck file is created at the specified output path.
- **Notes:** All four parameters are used in combination.

#### Scenario 8: Missing required parameter — preset
- **Description:** Call without the required `preset` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `preset` is required.
- **Notes:** `preset` is the only required field.

#### Scenario 9: Missing required parameter — preset with other params
- **Description:** Call with optional params but no `preset`.
- **Params:** `{ "output_path": "C:/Builds/test", "debug": true }`
- **Expected result:** Zod validation error — `preset` is required regardless of other params.
- **Notes:** Validates that optional params don't substitute for required ones.

#### Scenario 10: Non-existent preset name
- **Description:** Export using a preset name that does not exist in the project.
- **Params:** `{ "preset": "NonExistentPlatform" }`
- **Expected result:** Godot-side error — preset not found or not configured.
- **Notes:** Tests error handling for invalid preset references.

#### Scenario 11: Empty string for preset
- **Description:** Call with an empty string as the preset name.
- **Params:** `{ "preset": "" }`
- **Expected result:** Zod validation passes (empty string is a valid string). Godot handler should reject it.
- **Notes:** Tests boundary condition — Zod's `z.string()` accepts empty strings.

#### Scenario 12: Invalid type for preset (non-string)
- **Description:** Call with `preset` as a number.
- **Params:** `{ "preset": 42 }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** Type validation.

#### Scenario 13: Invalid type for debug (non-boolean)
- **Description:** Call with `debug` as a string instead of boolean.
- **Params:** `{ "preset": "Windows Desktop", "debug": "yes" }`
- **Expected result:** Zod validation error — expected boolean. The string `"yes"` is not coerced to boolean.
- **Notes:** Type validation for optional boolean parameter.

#### Scenario 14: Invalid type for pack_only (non-boolean)
- **Description:** Call with `pack_only` as a number.
- **Params:** `{ "preset": "Windows Desktop", "pack_only": 1 }`
- **Expected result:** Zod validation error — expected boolean.
- **Notes:** Type validation for optional boolean parameter.

#### Scenario 15: Invalid type for output_path (non-string)
- **Description:** Call with `output_path` as a boolean.
- **Params:** `{ "preset": "Windows Desktop", "output_path": false }`
- **Expected result:** Zod validation error — expected string for `output_path`.
- **Notes:** Type validation for optional string parameter.

#### Scenario 16: Export with empty output_path string
- **Description:** Call with `output_path` set to an empty string.
- **Params:** `{ "preset": "Windows Desktop", "output_path": "" }`
- **Expected result:** Zod validation passes. Godot handler may interpret empty string as "use default path" or reject it.
- **Notes:** Tests boundary condition for the optional string parameter.

#### Scenario 17: Export with output_path containing special characters
- **Description:** Call with `output_path` containing spaces, quotes, or special characters.
- **Params:** `{ "preset": "Windows Desktop", "output_path": "C:/Builds/My Game (v1.0)/export" }`
- **Expected result:** Zod validation passes (any string). The Godot handler may handle or reject paths with special characters.
- **Notes:** Tests filesystem path handling robustness.

#### Scenario 18: debug and pack_only both true
- **Description:** Export as a debug pack file.
- **Params:** `{ "preset": "Windows Desktop", "debug": true, "pack_only": true }`
- **Expected result:** A debug .pck file is created. Both flags are applied.
- **Notes:** Validates that the two boolean flags are independent and can both be true.

#### Scenario 19: Export with extra unknown params
- **Description:** Call with additional unknown parameters.
- **Params:** `{ "preset": "Windows Desktop", "extra_flag": "something", "nested": { "key": "value" } }`
- **Expected result:** Zod validation passes (extra fields ignored by default). Should export normally.
- **Notes:** Validates that unknown fields don't break the call.

#### Scenario 20: Very long preset name
- **Description:** Call with an extremely long preset name string.
- **Params:** `{ "preset": "a".repeat(5000) }`
- **Expected result:** Zod validation passes. Godot handler should reject the non-existent preset.
- **Notes:** Tests robustness against oversized input.

---

## Tool: get_export_info

### Schema

```typescript
{
  description: 'Get export project information (platform, features, resources)',
  inputSchema: {},
}
```

### Handler

```typescript
async () => callGodot(bridge, 'export/get_info')
```

### Tool Behavior
Returns information about the project's export configuration: supported platforms, available features, resource lists, and export-related project settings. Takes no parameters.

### Test Scenarios

#### Scenario 1: Basic happy path — get export info on a fresh project
- **Description:** Call `get_export_info` on a project with default export settings.
- **Params:** `{}` (empty object or no params)
- **Expected result:** Returns a JSON object containing export-related project information. Should include platform capabilities, feature flags, and resource information. Should not error.
- **Notes:** The exact structure depends on the Godot version and project configuration.

#### Scenario 2: Get export info after creating a preset
- **Description:** Create an export preset, then call `get_export_info`.
- **Params:** `{}`
- **Expected result:** The returned information should reflect the newly created preset. Platform and feature information may be updated.
- **Notes:** Use `create_export_preset` first, then call this tool.

#### Scenario 3: Call with unexpected extra params
- **Description:** Verify the tool ignores extraneous parameters.
- **Params:** `{ "platform": "Windows" }`
- **Expected result:** Should succeed identically to Scenario 1. The extraneous parameter is ignored.
- **Notes:** Tests that the empty schema properly strips/ignores extra params.

---

## Tool: validate_export

### Schema

```typescript
{
  description: 'Validate the project for export (check for missing resources, errors)',
  inputSchema: {},
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'export/validate', args as Record<string, unknown>)
```

### Tool Behavior
Validates the project for export readiness. Checks for missing resources, broken references, scripting errors, and other issues that would prevent a successful export. Note: the schema is empty, but the handler forwards the args object — though Zod strips unknown fields.

### Test Scenarios

#### Scenario 1: Basic happy path — validate a clean project
- **Description:** Call `validate_export` on a project with no export issues.
- **Params:** `{}`
- **Expected result:** Returns validation results. Should report no errors (or only warnings) for a clean project. Returns a list of issues if any exist.
- **Notes:** A fresh/generated project should pass validation or have only minor warnings.

#### Scenario 2: Validate after deleting a referenced resource
- **Description:** Intentionally break a reference (e.g., delete a scene that is referenced by the main scene), then validate.
- **Params:** `{}`
- **Expected result:** Validation should report the missing resource as an error or warning.
- **Notes:** Tests that validation catches real problems. Must be run in a test project.

#### Scenario 3: Validate after creating an export preset
- **Description:** Create a new export preset, then validate.
- **Params:** `{}`
- **Expected result:** Validation should run successfully. The new preset should not cause validation errors.
- **Notes:** Validates that preset creation doesn't break export validation.

#### Scenario 4: Call with unexpected extra params
- **Description:** Pass extra parameters to the tool.
- **Params:** `{ "platform": "Windows Desktop", "strict": true }`
- **Expected result:** Since the schema is `{}`, Zod strips the extra params and the call proceeds with an empty object. Should behave like Scenario 1.
- **Notes:** Godot handler receives `{}` regardless of what the client sends. This is a design note — the handler signature takes args, but Zod removes them.

#### Scenario 5: Call with no arguments object
- **Description:** Call with undefined/null args.
- **Params:** `undefined` or `null`
- **Expected result:** Should succeed — the empty schema accepts any input.
- **Notes:** Validates handler robustness.

---

## Tool: get_export_templates

### Schema

```typescript
{
  description: 'Get available export templates for the current Godot version',
  inputSchema: {},
}
```

### Handler

```typescript
async () => callGodot(bridge, 'export/get_templates')
```

### Tool Behavior
Lists the export templates available/installed for the current Godot Engine version. Export templates are required to export projects for specific platforms.

### Test Scenarios

#### Scenario 1: Basic happy path — list available templates
- **Description:** Call `get_export_templates` on a Godot installation with export templates installed.
- **Params:** `{}` (empty object or no params)
- **Expected result:** Returns a JSON object or array listing available templates. Each entry should include platform name and version. Should not error.
- **Notes:** The result depends on whether export templates are installed. If none are installed, it may return an empty list or a message indicating templates are missing.

#### Scenario 2: List templates on a fresh installation (possibly no templates)
- **Description:** Call on a Godot installation where export templates may not be installed.
- **Params:** `{}`
- **Expected result:** Returns available template information. If no templates are installed, should still return a valid response (empty list) rather than erroring.
- **Notes:** This is a valid state — Godot can run without export templates; it just can't export.

#### Scenario 3: Call with unexpected extra params
- **Description:** Verify the tool ignores extraneous parameters.
- **Params:** `{ "platform": "Android", "version": "4.0" }`
- **Expected result:** Should succeed identically to Scenario 1. Extraneous params are ignored.
- **Notes:** Tests empty schema robustness.

---

## Tool: create_export_preset

### Schema

```typescript
{
  description: 'Create a new export preset',
  inputSchema: {
    name: Name.describe('Preset name'),
    platform: z.string().describe("Target platform (e.g. 'Windows Desktop', 'Linux', 'Android')"),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'export/create_preset', args as Record<string, unknown>)
```

### Tool Behavior
Creates a new export preset in the project configuration. The preset is identified by `name` and targets a specific `platform`. Known Godot platform identifiers include: `Windows Desktop`, `Linux/X11`, `macOS`, `Android`, `iOS`, `Web`, `UWP`.

### Test Scenarios

#### Scenario 1: Happy path — create a Windows Desktop preset
- **Description:** Create a new export preset targeting Windows Desktop.
- **Params:** `{ "name": "Windows Desktop", "platform": "Windows Desktop" }`
- **Expected result:** A new export preset is created and configured for Windows. Returns success. The preset should appear in `list_export_presets`.
- **Notes:** `Windows Desktop` is the most common platform for development testing.

#### Scenario 2: Happy path — create a Linux preset
- **Description:** Create a new export preset targeting Linux.
- **Params:** `{ "name": "Linux", "platform": "Linux/X11" }`
- **Expected result:** A new export preset is created for Linux. Returns success.
- **Notes:** The platform string may be `Linux/X11` or just `Linux` depending on Godot version.

#### Scenario 3: Happy path — create a macOS preset
- **Description:** Create a new export preset targeting macOS.
- **Params:** `{ "name": "macOS", "platform": "macOS" }`
- **Expected result:** A new export preset is created for macOS. Returns success.
- **Notes:** Platform identifier for macOS.

#### Scenario 4: Happy path — create an Android preset
- **Description:** Create a new export preset targeting Android.
- **Params:** `{ "name": "Android", "platform": "Android" }`
- **Expected result:** A new export preset is created for Android. Returns success.
- **Notes:** Android export requires Android SDK setup in Godot settings.

#### Scenario 5: Happy path — create an iOS preset
- **Description:** Create a new export preset targeting iOS.
- **Params:** `{ "name": "iOS", "platform": "iOS" }`
- **Expected result:** A new export preset is created for iOS. Returns success.
- **Notes:** iOS export is macOS-only and requires Xcode.

#### Scenario 6: Happy path — create a Web preset
- **Description:** Create a new export preset targeting Web/HTML5.
- **Params:** `{ "name": "Web", "platform": "Web" }`
- **Expected result:** A new export preset is created for Web. Returns success.
- **Notes:** Web export uses HTML5/WebAssembly.

#### Scenario 7: Happy path — create with custom descriptive name
- **Description:** Create a preset with a name different from the platform identifier.
- **Params:** `{ "name": "My Windows Release", "platform": "Windows Desktop" }`
- **Expected result:** A new preset named "My Windows Release" is created for Windows Desktop. Returns success.
- **Notes:** The name does not need to match the platform — it's a display identifier.

#### Scenario 8: Missing required parameter — name
- **Description:** Call without the `name` parameter.
- **Params:** `{ "platform": "Windows Desktop" }`
- **Expected result:** Zod validation error — `name` is required.
- **Notes:** Both params are required.

#### Scenario 9: Missing required parameter — platform
- **Description:** Call without the `platform` parameter.
- **Params:** `{ "name": "MyPreset" }`
- **Expected result:** Zod validation error — `platform` is required.
- **Notes:** Both params are required.

#### Scenario 10: Both parameters missing
- **Description:** Call with an empty object.
- **Params:** `{}`
- **Expected result:** Zod validation error — both `name` and `platform` are required.
- **Notes:** Tests the case where neither required param is present.

#### Scenario 11: Invalid platform string (unknown platform)
- **Description:** Call with a platform string that is not a valid Godot target platform.
- **Params:** `{ "name": "BadPreset", "platform": "PlayStation 5" }`
- **Expected result:** Zod validation passes (any string). Godot handler should reject the unknown platform with an error.
- **Notes:** Platform validation happens on the Godot side, not in Zod.

#### Scenario 12: Empty string for name
- **Description:** Call with an empty string as the preset name.
- **Params:** `{ "name": "", "platform": "Windows Desktop" }`
- **Expected result:** Zod validation passes. Godot handler should reject an empty name.
- **Notes:** Boundary condition — Zod's `z.string()` accepts empty strings.

#### Scenario 13: Empty string for platform
- **Description:** Call with an empty string as the platform.
- **Params:** `{ "name": "MyPreset", "platform": "" }`
- **Expected result:** Zod validation passes. Godot handler should reject the empty platform.
- **Notes:** Boundary condition.

#### Scenario 14: Duplicate preset name
- **Description:** Create a preset with a name that already exists.
- **Params:** First call: `{ "name": "Windows Desktop", "platform": "Windows Desktop" }`, then same call again.
- **Expected result:** The second call should fail — Godot should report that a preset with that name already exists.
- **Notes:** Tests idempotency/conflict handling.

#### Scenario 15: Invalid type for name (non-string)
- **Description:** Call with `name` as a number.
- **Params:** `{ "name": 12345, "platform": "Windows Desktop" }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** Type validation.

#### Scenario 16: Invalid type for platform (non-string)
- **Description:** Call with `platform` as a boolean.
- **Params:** `{ "name": "MyPreset", "platform": true }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** Type validation.

#### Scenario 17: Platform string with extra whitespace
- **Description:** Call with platform containing leading/trailing whitespace.
- **Params:** `{ "name": "SpacedPreset", "platform": "  Windows Desktop  " }`
- **Expected result:** Zod validation passes (any string). Godot handler may trim whitespace or reject the string with extra spaces.
- **Notes:** Tests whitespace handling.

#### Scenario 18: Name with special characters
- **Description:** Call with a name containing special characters.
- **Params:** `{ "name": "Preset @#$%^&*()", "platform": "Windows Desktop" }`
- **Expected result:** Zod validation passes. Godot handler may accept or reject special characters.
- **Notes:** Tests input sanitization expectations.

#### Scenario 19: Very long preset name
- **Description:** Call with extremely long name string.
- **Params:** `{ "name": "a".repeat(5000), "platform": "Windows Desktop" }`
- **Expected result:** Zod validation passes. Godot handler may reject or truncate the long name.
- **Notes:** Tests robustness against oversized input.

#### Scenario 20: Create with extra unknown params
- **Description:** Call with additional unknown parameters.
- **Params:** `{ "name": "ExtraPreset", "platform": "Windows Desktop", "description": "My custom preset", "runnable": true, "advanced_options": {} }`
- **Expected result:** Zod validation passes (extra fields ignored). Preset should be created normally.
- **Notes:** Validates that unknown fields don't break the call.

---

## Tool: delete_export_preset

### Schema

```typescript
{
  description: 'Delete an export preset from the project',
  inputSchema: {
    name: z.string().describe('Name of the export preset to delete'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'export/delete_preset', args as Record<string, unknown>)
```

### Tool Behavior
Removes a previously created export preset from the project configuration. The preset is identified by its name.

### Test Scenarios

#### Scenario 1: Happy path — delete an existing preset
- **Description:** Delete a preset that was previously created (e.g., after `create_export_preset`).
- **Params:** `{ "name": "Windows Desktop" }`
- **Expected result:** The preset is removed from the project. Returns success. The preset should no longer appear in `list_export_presets`.
- **Notes:** Must have the preset created first. Test after Scenario 1 of `create_export_preset`.

#### Scenario 2: Delete a non-existent preset
- **Description:** Attempt to delete a preset that does not exist.
- **Params:** `{ "name": "NonExistentPreset" }`
- **Expected result:** Godot-side error. Should report that the preset was not found.
- **Notes:** Tests error handling for missing presets.

#### Scenario 3: Delete the last remaining preset
- **Description:** Delete the only export preset in the project.
- **Params:** `{ "name": "<only-preset>" }`
- **Expected result:** The preset is removed. `list_export_presets` should return an empty array or only auto-detected defaults.
- **Notes:** Validates that having zero user-created presets is a valid state.

#### Scenario 4: Delete a preset with a custom name (not matching platform)
- **Description:** Create a preset with a custom name, then delete it by that name.
- **Params:** Create: `{ "name": "My Custom Build", "platform": "Windows Desktop" }`, then delete: `{ "name": "My Custom Build" }`
- **Expected result:** The preset is successfully deleted. Preset lookup by name works for custom names.
- **Notes:** Validates that deletion uses the preset name field, not the platform identifier.

#### Scenario 5: Idempotent delete — delete twice
- **Description:** Delete the same preset twice in succession.
- **Params:** First call: `{ "name": "Windows Desktop" }`, then same call again.
- **Expected result:** First call succeeds. Second call should error — preset not found.
- **Notes:** Verifies that deletion is not idempotent and the second call detects the preset is gone.

#### Scenario 6: Missing required parameter — name
- **Description:** Call without the `name` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `name` is required.
- **Notes:** `name` is the only field and it is required.

#### Scenario 7: Empty string for name
- **Description:** Call with an empty string as the preset name.
- **Params:** `{ "name": "" }`
- **Expected result:** Zod validation passes (empty string is valid). Godot handler should reject or not find a preset with empty name.
- **Notes:** Tests boundary condition.

#### Scenario 8: Name as non-string
- **Description:** Call with `name` as a number.
- **Params:** `{ "name": 42 }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** Type validation.

#### Scenario 9: Name as boolean
- **Description:** Call with `name` as a boolean.
- **Params:** `{ "name": false }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** Type validation.

#### Scenario 10: Name with path traversal attempt
- **Description:** Call with a name containing path traversal characters.
- **Params:** `{ "name": "../../malicious/path" }`
- **Expected result:** Zod validation passes (any string). Godot handler should sanitize or not find a preset with this name.
- **Notes:** Security edge case — validates that path traversal via preset names is not exploitable.

#### Scenario 11: Name with special characters
- **Description:** Call with a name containing quotes, backslashes, or other special characters.
- **Params:** `{ "name": "Preset\"'; DROP TABLE presets;--" }`
- **Expected result:** Zod validation passes. Godot handler should safely handle the string without SQL injection or similar issues (Godot doesn't use SQL).
- **Notes:** Tests input sanitization.

#### Scenario 12: Delete with extra unknown params
- **Description:** Call with additional unknown parameters.
- **Params:** `{ "name": "Windows Desktop", "platform": "Windows Desktop", "force": true }`
- **Expected result:** Zod validation passes (extra fields ignored). Deletion should proceed normally using only the `name`.
- **Notes:** Validates that unknown fields are safely ignored.

---

## Cross-Tool Integration Scenarios

These scenarios test sequences of export operations together.

### Scenario I: Full preset lifecycle — create → list → export → delete
- **Steps:**
  1. `list_export_presets()` → note initial presets
  2. `create_export_preset({ "name": "TestPreset", "platform": "Windows Desktop" })` → success
  3. `list_export_presets()` → should include "TestPreset"
  4. `get_export_info()` → should reflect the new preset
  5. `export_project({ "preset": "TestPreset", "pack_only": true })` → success (pack export)
  6. `validate_export()` → should pass with the new preset
  7. `delete_export_preset({ "name": "TestPreset" })` → success
  8. `list_export_presets()` → "TestPreset" should be gone
- **Expected result:** Each step succeeds independently and in sequence. No state leakage between steps.

### Scenario II: Create presets for all common platforms
- **Steps:**
  1. `create_export_preset({ "name": "Win", "platform": "Windows Desktop" })` → success
  2. `create_export_preset({ "name": "Lin", "platform": "Linux/X11" })` → success
  3. `create_export_preset({ "name": "Mac", "platform": "macOS" })` → success
  4. `create_export_preset({ "name": "Droid", "platform": "Android" })` → success
  5. `create_export_preset({ "name": "Web", "platform": "Web" })` → success
  6. `list_export_presets()` → should show all five presets
  7. `get_export_info()` → should reflect all platforms
  8. `get_export_templates()` → should show templates for these platforms
- **Expected result:** All five presets are created. Each appears in the list. No conflicts between presets.

### Scenario III: Export validation cycle — create → validate → fix → validate
- **Steps:**
  1. `validate_export()` → baseline validation result
  2. `create_export_preset({ "name": "CyclePreset", "platform": "Windows Desktop" })` → success
  3. `validate_export()` → should show validation results including the new preset
  4. `export_project({ "preset": "CyclePreset", "pack_only": true })` → attempt export
  5. `validate_export()` → validate again after attempted export
  6. `delete_export_preset({ "name": "CyclePreset" })` → cleanup
- **Expected result:** Validation results are consistent across the lifecycle. No persistent errors after cleanup.

### Scenario IV: Duplicate detection — same preset twice
- **Steps:**
  1. `create_export_preset({ "name": "DuplicateTest", "platform": "Windows Desktop" })` → success
  2. `create_export_preset({ "name": "DuplicateTest", "platform": "Windows Desktop" })` → error (duplicate)
  3. `create_export_preset({ "name": "DuplicateTest", "platform": "Android" })` → error (duplicate name, even if platform differs, or success if Godot allows same name for different platforms)
  4. `delete_export_preset({ "name": "DuplicateTest" })` → cleanup
- **Expected result:** The behavior of the second and third calls depends on Godot's preset naming constraints. Document the actual behavior.
- **Notes:** Godot may use the name as a unique identifier regardless of platform, or it may allow same name for different platforms.

### Scenario V: Export without templates
- **Steps:**
  1. `get_export_templates()` → check template availability
  2. `create_export_preset({ "name": "NoTemplateTest", "platform": "Web" })` → success (creating preset doesn't require templates)
  3. `export_project({ "preset": "NoTemplateTest", "pack_only": true })` → may succeed or fail depending on template availability
  4. `delete_export_preset({ "name": "NoTemplateTest" })` → cleanup
- **Expected result:** Preset creation succeeds regardless of templates. Export may fail if templates are not installed for the platform.
- **Notes:** Templates are required for actual export but not for preset management.

---

## Notes for Test Executors

1. **Platform dependency:** The `create_export_preset` tool accepts a platform string. Valid platform identifiers depend on the Godot version and installed export templates. Common values: `Windows Desktop`, `Linux/X11`, `macOS`, `Android`, `iOS`, `Web`.

2. **Export templates required:** The `export_project` tool requires export templates to be installed for the target platform. If templates are not installed, exports will fail. The `get_export_templates` tool can check availability.

3. **Stateful tools:** `create_export_preset` and `delete_export_preset` modify the project's export configuration (`export_presets.cfg` or embedded in `project.godot`). Run tests in a dedicated test project.

4. **Long-running operations:** `export_project` can take significant time (seconds to minutes) depending on project size and platform. Set appropriate timeouts for export tests.

5. **Filesystem access:** The `output_path` parameter in `export_project` requires write access to the specified directory. Ensure the test environment has appropriate permissions.

6. **Cleanup:** After tests complete, delete any export presets created during testing to restore the project to its original state. This is especially important for the cross-tool integration scenarios.

7. **Zod validation vs Godot validation:** The MCP server validates parameters at the schema level (Zod). The Godot plugin performs additional validation (platform validity, duplicate preset names, etc.). Both layers should be tested.

8. **`validate_export` schema note:** Although the handler function signature accepts `args`, the `inputSchema` is empty (`{}`). Zod will strip any extra parameters before the handler receives them, so the handler always receives an empty object. This is a design choice — if platform-specific validation is needed, the schema should be updated.

9. **`get_export_templates` scope:** This tool lists templates installed for the current Godot version, not templates available online. A fresh Godot installation may have no templates installed.

10. **Cross-platform preset names:** Testing suggests that Godot may enforce unique preset names across all platforms. Verify the actual behavior with the `DuplicateTest` scenario (Scenario IV) and document findings.
