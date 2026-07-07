# Export Tools Test Plan

**Source file:** `server/src/tools/export.ts`  
**Module purpose:** Project export management — 7 tools covering export preset listing, project export, export info retrieval, export validation, template querying, and preset create/delete.

**Shared type definitions (from `shared-types.ts`):**

| Type | Zod schema | Notes |
|------|-----------|-------|
| `Name` | `z.string()` | Generic name identifier string |

---

## Tool 1: `list_export_presets`

**Description:** List all configured export presets.  
**Handler route:** `export/list_presets`  
**Input schema:** `{}` (no parameters)

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| _(none)_ | — | — | — | No parameters |

### Test Scenarios

#### 1.1 Happy path — list presets on a fresh project
- **Params:** `{}`
- **Expected result:** Success — returns an empty array `[]` (no presets configured)
- **Notes:** A new Godot project has no export presets by default

#### 1.2 Happy path — list presets after creating presets
- **Precondition:** Create 2 export presets first (e.g., "Windows Desktop" and "Android")
- **Params:** `{}`
- **Expected result:** Success — returns an array containing all 2 presets with their names, platform info, and configuration
- **Notes:** Validates that presets are visible after creation

#### 1.3 Happy path — list presets with many presets
- **Precondition:** Create presets for all common platforms (Windows, Linux, macOS, Android, Web, iOS)
- **Params:** `{}`
- **Expected result:** Success — returns array with all 6 presets
- **Notes:** Validates that the tool handles larger preset counts

#### 1.4 Edge case — list presets when some have invalid configurations
- **Precondition:** Manually corrupt a preset's export path or settings in `export_presets.cfg`
- **Params:** `{}`
- **Expected result:** Still returns the preset list; the corrupted preset may show with missing/empty fields but the listing should not error
- **Notes:** Robustness — listing should not fail due to one bad preset

#### 1.5 Edge case — call with extraneous parameters
- **Params:** `{ "foo": "bar" }`
- **Expected result:** Zod validation error or the extras are silently ignored — behavior depends on Zod strictness
- **Notes:** Input schema is `{}`, so extra keys may be stripped or rejected

---

## Tool 2: `export_project`

**Description:** Export the project using a specific preset.  
**Handler route:** `export/project`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `preset` | `Name` (string) | ✅ Yes | — | Export preset name |
| `output_path` | `string` | No | — | Output path for the export |
| `debug` | `boolean` | No | `false` | Export as debug build (default: false = release) |
| `pack_only` | `boolean` | No | `false` | Export as pack file only (default: false) |

### Test Scenarios

#### 2.1 Happy path — export with minimum params (release build)
- **Precondition:** A preset named "Windows Desktop" exists
- **Params:** `{ "preset": "Windows Desktop" }`
- **Expected result:** Success — export completes, returns the output file path. Exports a release build (debug=false default) to the default output path defined in the preset.
- **Notes:** Only `preset` is required; `debug` and `pack_only` default to `false`

#### 2.2 Happy path — export as debug build
- **Precondition:** Preset "Android" exists
- **Params:** `{ "preset": "Android", "debug": true }`
- **Expected result:** Success — exports a debug build of the Android preset with debugging symbols included
- **Notes:** `debug: true` — opposite of default (`false`)

#### 2.3 Happy path — export with explicit release build (`debug: false`)
- **Precondition:** Preset "Linux" exists
- **Params:** `{ "preset": "Linux", "debug": false }`
- **Expected result:** Success — exports a release build, same as not providing `debug` at all
- **Notes:** Explicit `false` should behave identically to omitting `debug`

#### 2.4 Happy path — export with custom output_path
- **Precondition:** Preset "macOS" exists
- **Params:** `{ "preset": "macOS", "output_path": "C:/builds/my_game.app" }`
- **Expected result:** Success — exports to the specified custom path instead of the preset's default path
- **Notes:** Validates `output_path` overrides the preset's default output location

#### 2.5 Happy path — export as pack only
- **Precondition:** Preset "Windows Desktop" exists
- **Params:** `{ "preset": "Windows Desktop", "pack_only": true }`
- **Expected result:** Success — exports as a .pck file only (no executable wrapper)
- **Notes:** `pack_only: true` — typically used for DLC or patch delivery

#### 2.6 Happy path — export as debug + pack only
- **Precondition:** Preset "Web" exists
- **Params:** `{ "preset": "Web", "debug": true, "pack_only": true }`
- **Expected result:** Success — exports a debug .pck file
- **Notes:** Combines both optional flags with non-default values

#### 2.7 Happy path — export with all parameters
- **Precondition:** Preset "Windows Desktop" exists
- **Params:** `{ "preset": "Windows Desktop", "output_path": "D:/releases/v1.0/game.exe", "debug": false, "pack_only": false }`
- **Expected result:** Success — full parameter coverage, release build at custom path
- **Notes:** All params explicitly set to their defaults except `output_path`

#### 2.8 Edge case — missing required `preset`
- **Params:** `{}`
- **Expected result:** Zod validation error — `preset` is required
- **Notes:** Test input schema validation

#### 2.9 Edge case — non-existent preset name
- **Params:** `{ "preset": "NonExistentPreset" }`
- **Expected result:** Error from Godot — preset not found / export failed
- **Notes:** Validates error propagation for missing preset

#### 2.10 Edge case — empty string `preset`
- **Params:** `{ "preset": "" }`
- **Expected result:** Error from Godot — empty preset name is invalid
- **Notes:** Empty string should be rejected or cause an error

#### 2.11 Edge case — empty string `output_path`
- **Params:** `{ "preset": "Windows Desktop", "output_path": "" }`
- **Expected result:** Error from Godot — invalid/empty output path, or falls back to preset default
- **Notes:** Behavior on empty output_path depends on Godot's handling

#### 2.12 Edge case — invalid `output_path` (non-existent directory)
- **Params:** `{ "preset": "Windows Desktop", "output_path": "Z:/nonexistent_drive/build/game.exe" }`
- **Expected result:** Error from Godot — output directory does not exist or is unwritable
- **Notes:** Validates filesystem error propagation

#### 2.13 Edge case — `debug` as wrong type (string instead of boolean)
- **Params:** `{ "preset": "Windows Desktop", "debug": "yes" }`
- **Expected result:** Zod validation error — expected boolean, got string
- **Notes:** Type validation

#### 2.14 Edge case — `pack_only` as wrong type (number instead of boolean)
- **Params:** `{ "preset": "Windows Desktop", "pack_only": 1 }`
- **Expected result:** Zod validation error — expected boolean, got number
- **Notes:** Type validation — Zod's `.boolean()` rejects truthy/falsy coercion

#### 2.15 Edge case — export with `debug: true` and `output_path` containing spaces
- **Params:** `{ "preset": "Windows Desktop", "output_path": "C:/My Games/My Project/build.exe", "debug": true }`
- **Expected result:** Success — path with spaces handled correctly
- **Notes:** Validates path escaping/handling for paths with spaces

#### 2.16 Edge case — export when no presets exist at all
- **Precondition:** Project has zero export presets
- **Params:** `{ "preset": "AnyName" }`
- **Expected result:** Error from Godot — no presets configured / preset not found
- **Notes:** Robustness for empty preset list

---

## Tool 3: `get_export_info`

**Description:** Get export project information (platform, features, resources).  
**Handler route:** `export/get_info`  
**Input schema:** `{}` (no parameters)

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| _(none)_ | — | — | — | No parameters |

### Test Scenarios

#### 3.1 Happy path — get export info on a fresh project
- **Params:** `{}`
- **Expected result:** Success — returns export info JSON containing available platforms, project features, and exportable resources. At minimum returns the list of supported export platforms.
- **Notes:** This is a read-only query tool

#### 3.2 Happy path — get export info after creating presets
- **Precondition:** Create presets for "Windows Desktop" and "Android"
- **Params:** `{}`
- **Expected result:** Success — returns export info; may include the configured presets alongside platform capabilities
- **Notes:** Validates that the info reflects the current project state

#### 3.3 Happy path — get export info after modifying project settings
- **Precondition:** Modify project to enable specific features (e.g., VR support, custom features)
- **Params:** `{}`
- **Expected result:** Success — returned info reflects the updated feature set and resource list
- **Notes:** Validates that the tool captures project configuration changes

#### 3.4 Edge case — get export info with extraneous parameters
- **Params:** `{ "platform": "windows" }`
- **Expected result:** Zod validation error or extras silently ignored — depends on Zod strictness
- **Notes:** Input schema is `{}`; any extra keys may be rejected

#### 3.5 Edge case — get export info on a heavily customized project
- **Precondition:** Project with many custom features, custom export templates, and many resources
- **Params:** `{}`
- **Expected result:** Success — returns large JSON containing all the custom data without truncation or error
- **Notes:** Validates scalability for complex projects

---

## Tool 4: `validate_export`

**Description:** Validate the project for export (check for missing resources, errors).  
**Handler route:** `export/validate`  
**Input schema:** `{}` (no parameters)

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| _(none)_ | — | — | — | No parameters |

### Test Scenarios

#### 4.1 Happy path — validate a clean project
- **Precondition:** Project with no missing resources or errors
- **Params:** `{}`
- **Expected result:** Success — returns validation result with no errors/warnings, indicating the project is export-ready
- **Notes:** Clean validation result

#### 4.2 Happy path — validate project with missing resources
- **Precondition:** Intentionally break a scene reference (delete a referenced .tscn file)
- **Params:** `{}`
- **Expected result:** Success — returns validation result listing the missing resource as an error or warning
- **Notes:** Validates that the tool catches missing dependencies

#### 4.3 Happy path — validate project with script errors
- **Precondition:** Create a GDScript with a syntax error
- **Params:** `{}`
- **Expected result:** Success — returns validation result with script errors noted
- **Notes:** Validates that script validation is included in export checks

#### 4.4 Happy path — validate project with unsupported export features
- **Precondition:** Enable a feature not supported by the target platform in project settings
- **Params:** `{}`
- **Expected result:** Success — returns validation warnings about unsupported features
- **Notes:** Validates platform compatibility checks

#### 4.5 Edge case — validate empty/fresh project
- **Precondition:** Brand new empty project with just project.godot
- **Params:** `{}`
- **Expected result:** Success — returns validation result (probably clean with no issues)
- **Notes:** An empty project should still validate successfully

#### 4.6 Edge case — validate with extraneous parameters
- **Params:** `{ "platform": "windows" }`
- **Expected result:** Zod validation error or extras silently ignored
- **Notes:** Input schema is `{}`

#### 4.7 Edge case — validate project with circular resource dependencies
- **Precondition:** Create scenes that inherit/inherit from each other in a cycle
- **Params:** `{}`
- **Expected result:** Success — returns validation warnings about circular dependencies
- **Notes:** Validates dependency cycle detection

---

## Tool 5: `get_export_templates`

**Description:** Get available export templates for the current Godot version.  
**Handler route:** `export/get_templates`  
**Input schema:** `{}` (no parameters)

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| _(none)_ | — | — | — | No parameters |

### Test Scenarios

#### 5.1 Happy path — get templates with templates installed
- **Precondition:** Export templates are installed via Godot's export template manager
- **Params:** `{}`
- **Expected result:** Success — returns list of installed export templates with version info, platform support, and status (installed/missing)
- **Notes:** Standard operation

#### 5.2 Happy path — get templates with no templates installed
- **Precondition:** Remove/uninstall all export templates
- **Params:** `{}`
- **Expected result:** Success — returns an empty result or a result indicating no templates are installed with download instructions
- **Notes:** Validates behavior when templates are absent

#### 5.3 Happy path — get templates with mixed installation (some installed, some not)
- **Precondition:** Install templates for some platforms but not others
- **Params:** `{}`
- **Expected result:** Success — returns list distinguishing installed vs. missing templates for each platform
- **Notes:** Common scenario — partial template installation

#### 5.4 Edge case — get templates with mismatched Godot version
- **Precondition:** Templates from a different Godot version (e.g., 4.2 templates with Godot 4.3 editor)
- **Params:** `{}`
- **Expected result:** Success — returns templates with version mismatch warnings
- **Notes:** Version mismatch handling

#### 5.5 Edge case — get templates with extraneous parameters
- **Params:** `{ "version": "4.3" }`
- **Expected result:** Zod validation error or extras silently ignored
- **Notes:** Input schema is `{}`

#### 5.6 Edge case — get templates after corrupting template files
- **Precondition:** Manually corrupt an installed template file (e.g., truncate the .tpz)
- **Params:** `{}`
- **Expected result:** Success — returns list; the corrupted template may show as "invalid" or "error" status
- **Notes:** Robustness against corrupted installation

---

## Tool 6: `create_export_preset`

**Description:** Create a new export preset.  
**Handler route:** `export/create_preset`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | `Name` (string) | ✅ Yes | — | Preset name |
| `platform` | `string` | ✅ Yes | — | Target platform (e.g. 'Windows Desktop', 'Linux', 'Android') |

### Test Scenarios

#### 6.1 Happy path — create a Windows Desktop preset
- **Params:** `{ "name": "Windows Desktop", "platform": "Windows Desktop" }`
- **Expected result:** Success — creates a new export preset for Windows Desktop with default export settings. Returns confirmation with preset details.
- **Notes:** Standard case — name matches platform convention

#### 6.2 Happy path — create a Linux preset
- **Params:** `{ "name": "My Linux Build", "platform": "Linux" }`
- **Expected result:** Success — creates a Linux export preset with custom name "My Linux Build"
- **Notes:** Validates that name can differ from platform string

#### 6.3 Happy path — create an Android preset
- **Params:** `{ "name": "Android", "platform": "Android" }`
- **Expected result:** Success — creates an Android export preset
- **Notes:** Mobile platform

#### 6.4 Happy path — create a Web (HTML5) preset
- **Params:** `{ "name": "Web Export", "platform": "Web" }`
- **Expected result:** Success — creates a Web/HTML5 export preset
- **Notes:** Validates web platform support

#### 6.5 Happy path — create a macOS preset
- **Params:** `{ "name": "macOS", "platform": "macOS" }`
- **Expected result:** Success — creates a macOS export preset
- **Notes:** Desktop platform

#### 6.6 Happy path — create an iOS preset
- **Params:** `{ "name": "iOS Build", "platform": "iOS" }`
- **Expected result:** Success — creates an iOS export preset
- **Notes:** Mobile platform

#### 6.7 Happy path — create preset with special characters in name
- **Params:** `{ "name": "My Game v2.0 (Release)", "platform": "Windows Desktop" }`
- **Expected result:** Success — preset created with the special-character name
- **Notes:** Validates name handling with spaces, dots, and parentheses

#### 6.8 Edge case — missing required `name`
- **Params:** `{ "platform": "Windows Desktop" }`
- **Expected result:** Zod validation error — `name` is required
- **Notes:** Test input schema validation

#### 6.9 Edge case — missing required `platform`
- **Params:** `{ "name": "My Preset" }`
- **Expected result:** Zod validation error — `platform` is required
- **Notes:** Test input schema validation

#### 6.10 Edge case — empty string `name`
- **Params:** `{ "name": "", "platform": "Windows Desktop" }`
- **Expected result:** Error from Godot — empty preset name is invalid
- **Notes:** Empty name should be rejected

#### 6.11 Edge case — empty string `platform`
- **Params:** `{ "name": "My Preset", "platform": "" }`
- **Expected result:** Error from Godot — empty/invalid platform name
- **Notes:** Empty platform string is invalid

#### 6.12 Edge case — invalid/unrecognized platform string
- **Params:** `{ "name": "Bad Platform", "platform": "Xbox 360" }`
- **Expected result:** Error from Godot — unsupported or unknown platform
- **Notes:** Godot only supports specific platform strings; "Xbox 360" is not one

#### 6.13 Edge case — duplicate preset name (same as existing)
- **Precondition:** A preset named "Windows Desktop" already exists
- **Params:** `{ "name": "Windows Desktop", "platform": "Windows Desktop" }`
- **Expected result:** Error from Godot — duplicate preset name, or auto-renames with suffix
- **Notes:** Behavior depends on Godot's internal handling

#### 6.14 Edge case — duplicate preset name with different platform
- **Precondition:** A preset named "MyPreset" for "Windows Desktop" exists
- **Params:** `{ "name": "MyPreset", "platform": "Linux" }`
- **Expected result:** Error from Godot — name collision, or auto-rename
- **Notes:** Two presets cannot share the same name regardless of platform

#### 6.15 Edge case — `name` is only whitespace
- **Params:** `{ "name": "   ", "platform": "Windows Desktop" }`
- **Expected result:** Error from Godot — whitespace-only name is invalid
- **Notes:** Edge case for blank-like strings

#### 6.16 Edge case — very long name (256+ characters)
- **Params:** `{ "name": "<256-char string>", "platform": "Linux" }`
- **Expected result:** Success or error — depends on Godot's name length limit
- **Notes:** Validates behavior with very long preset names

#### 6.17 Edge case — platform with wrong casing
- **Params:** `{ "name": "Win", "platform": "windows desktop" }`
- **Expected result:** Error from Godot — platform names may be case-sensitive
- **Notes:** Godot expects specific casing (e.g., "Windows Desktop" not "windows desktop")

---

## Tool 7: `delete_export_preset`

**Description:** Delete an export preset from the project.  
**Handler route:** `export/delete_preset`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | `string` | ✅ Yes | — | Name of the export preset to delete |

### Test Scenarios

#### 7.1 Happy path — delete an existing preset
- **Precondition:** A preset named "Windows Desktop" exists
- **Params:** `{ "name": "Windows Desktop" }`
- **Expected result:** Success — the "Windows Desktop" preset is removed from the project. Returns confirmation.
- **Notes:** Standard delete operation

#### 7.2 Happy path — delete a preset with special characters in name
- **Precondition:** Create preset "My Game v2.0 (Release)"
- **Params:** `{ "name": "My Game v2.0 (Release)" }`
- **Expected result:** Success — the specially-named preset is deleted
- **Notes:** Validates name matching with special characters

#### 7.3 Happy path — delete a preset, verify it's gone via `list_export_presets`
- **Precondition:** A preset named "Linux" exists
- **Params:** `{ "name": "Linux" }`
- **Expected result:** Success — preset deleted. Subsequent `list_export_presets` call should NOT include "Linux"
- **Notes:** End-to-end verification — create, list, delete, list again

#### 7.4 Happy path — delete last remaining preset
- **Precondition:** Exactly one preset exists
- **Params:** `{ "name": "<only_preset_name>" }`
- **Expected result:** Success — preset deleted. Project now has zero presets.
- **Notes:** Validates no issues with empty preset list after deletion

#### 7.5 Edge case — missing required `name`
- **Params:** `{}`
- **Expected result:** Zod validation error — `name` is required
- **Notes:** Test input schema validation

#### 7.6 Edge case — non-existent preset name
- **Params:** `{ "name": "NonExistentPreset" }`
- **Expected result:** Error from Godot — preset not found
- **Notes:** Validates error handling for missing preset

#### 7.7 Edge case — empty string `name`
- **Params:** `{ "name": "" }`
- **Expected result:** Error from Godot — empty name is invalid
- **Notes:** Empty string should be rejected

#### 7.8 Edge case — whitespace-only name
- **Params:** `{ "name": "   " }`
- **Expected result:** Error from Godot — no preset with whitespace-only name exists
- **Notes:** Whitespace-only name won't match any preset

#### 7.9 Edge case — delete preset that was already deleted (double delete)
- **Precondition:** Create and delete preset "TempPreset"
- **Params:** `{ "name": "TempPreset" }` (called again)
- **Expected result:** Error from Godot — preset not found (already deleted)
- **Notes:** Idempotency check — second delete should fail gracefully

#### 7.10 Edge case — case sensitivity in preset name
- **Precondition:** Preset named "Windows Desktop" exists
- **Params:** `{ "name": "windows desktop" }`
- **Expected result:** Error from Godot — name mismatch (case-sensitive), preset not found
- **Notes:** Preset names are likely case-sensitive

#### 7.11 Edge case — delete preset while export is in progress
- **Precondition:** Start an export, immediately attempt to delete the preset being used
- **Params:** `{ "name": "<exporting_preset>" }`
- **Expected result:** Error from Godot — cannot delete preset while export is active, or the export may fail
- **Notes:** Concurrency edge case

#### 7.12 Edge case — `name` with trailing/leading whitespace not matching stored name
- **Precondition:** Preset stored as "Windows Desktop" (no extra spaces)
- **Params:** `{ "name": " Windows Desktop " }`
- **Expected result:** Error from Godot — " Windows Desktop " does not match "Windows Desktop" exactly
- **Notes:** Whether Godot trims whitespace in preset name lookup is implementation-dependent

---

## Cross-Tool Integration Scenarios

### C1: Full preset lifecycle
1. **list_export_presets** — verify initial state (empty)
2. **create_export_preset** — create "Windows Desktop" preset
3. **list_export_presets** — verify "Windows Desktop" appears
4. **create_export_preset** — create "Android" preset
5. **list_export_presets** — verify both presets
6. **get_export_info** — verify info reflects 2 presets
7. **delete_export_preset** — delete "Android"
8. **list_export_presets** — verify only "Windows Desktop" remains
9. **delete_export_preset** — delete "Windows Desktop"
10. **list_export_presets** — verify empty again

### C2: Export workflow with validation
1. **create_export_preset** — create "Test Export" for "Windows Desktop"
2. **validate_export** — check project health before export
3. **get_export_info** — confirm export configuration
4. **get_export_templates** — verify templates are available
5. **export_project** — perform the actual export with `{ "preset": "Test Export", "debug": true }`
6. **validate_export** — verify project still valid after export

### C3: Error resilience across tools
1. **create_export_preset** with invalid platform → expect error
2. **list_export_presets** → returns without error (listing still works)
3. **get_export_info** → returns without error (info still works)
4. **export_project** with non-existent preset → expect error
5. **delete_export_preset** with non-existent name → expect error
6. **list_export_presets** → returns current state without errors

### C4: Debug/Release toggle verification
1. **create_export_preset** — create "Toggle Test" for "Linux"
2. **export_project** with `debug: false` → release build
3. **export_project** with `debug: true` → debug build
4. **export_project** without `debug` param → release build (default)
5. Verify that each export produces expected build type (check file sizes, symbols)
