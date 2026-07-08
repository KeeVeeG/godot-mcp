# Platform Export Tools — Test Plan

**Source file:** `server/src/tools/platform_export.ts`
**Imports:** `Name`, `FilePath`, `OptionalProperties`, `z` from `shared-types.ts`

---

## Tool: `export_for_platform`

**Description:** Export the project for a specific platform

**Parameters:**

| Parameter  | Type                                           | Required | Default | Description                                       |
| ---------- | ---------------------------------------------- | -------- | ------- | ------------------------------------------------- |
| `platform` | `z.enum(['windows','linux','macos','android','ios','web'])` | yes | — | Target platform |
| `debug`    | `z.boolean()`                                  | no       | `false` | Export as debug build (false = release)           |

**Handler:** `callGodot(bridge, 'export_for_platform', args)`

### Test Scenarios

#### 1. Happy path — export for Windows (release, debug default)
- **Description:** Export for `windows` with no explicit `debug` param — should default to `false` (release build).
- **Params:** `{ "platform": "windows" }`
- **Expected result:** Godot initiates a release export for Windows Desktop. Returns export path or success confirmation.
- **Notes:** Requires an export preset for `Windows Desktop` to exist in the project.

#### 2. Enum value: windows — debug=true
- **Description:** Export for `windows` with debug build.
- **Params:** `{ "platform": "windows", "debug": true }`
- **Expected result:** Godot initiates a debug export for Windows Desktop.

#### 3. Enum value: linux
- **Description:** Export for `linux` (release build).
- **Params:** `{ "platform": "linux" }`
- **Expected result:** Godot initiates a release export for Linux.

#### 4. Enum value: linux — debug
- **Description:** Export for `linux` with debug build.
- **Params:** `{ "platform": "linux", "debug": true }`
- **Expected result:** Godot initiates a debug export for Linux.

#### 5. Enum value: macos
- **Description:** Export for `macos` (release build).
- **Params:** `{ "platform": "macos" }`
- **Expected result:** Godot initiates a release export for macOS.

#### 6. Enum value: macos — debug
- **Description:** Export for `macos` with debug build.
- **Params:** `{ "platform": "macos", "debug": true }`
- **Expected result:** Godot initiates a debug export for macOS.

#### 7. Enum value: android
- **Description:** Export for `android` (release build).
- **Params:** `{ "platform": "android" }`
- **Expected result:** Godot initiates a release export for Android.

#### 8. Enum value: android — debug
- **Description:** Export for `android` with debug build.
- **Params:** `{ "platform": "android", "debug": true }`
- **Expected result:** Godot initiates a debug export for Android.

#### 9. Enum value: ios
- **Description:** Export for `ios` (release build).
- **Params:** `{ "platform": "ios" }`
- **Expected result:** Godot initiates a release export for iOS.

#### 10. Enum value: ios — debug
- **Description:** Export for `ios` with debug build.
- **Params:** `{ "platform": "ios", "debug": true }`
- **Expected result:** Godot initiates a debug export for iOS.

#### 11. Enum value: web
- **Description:** Export for `web` (release build).
- **Params:** `{ "platform": "web" }`
- **Expected result:** Godot initiates a release export for Web (HTML5).

#### 12. Enum value: web — debug
- **Description:** Export for `web` with debug build.
- **Params:** `{ "platform": "web", "debug": true }`
- **Expected result:** Godot initiates a debug export for Web (HTML5).

#### 13. Missing required param: platform
- **Description:** Call without the required `platform` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `platform` is required.
- **Notes:** The MCP framework should reject this before reaching the handler.

#### 14. Invalid platform enum value
- **Description:** Call with a platform not in the allowed enum.
- **Params:** `{ "platform": "playstation" }`
- **Expected result:** Zod validation error — `platform` must be one of `windows | linux | macos | android | ios | web`.

#### 15. Invalid platform type
- **Description:** Call with a non-string platform value.
- **Params:** `{ "platform": 123 }`
- **Expected result:** Zod validation error — expected string, received number.

#### 16. Invalid debug type
- **Description:** Call with a non-boolean debug value.
- **Params:** `{ "platform": "windows", "debug": "yes" }`
- **Expected result:** Zod validation error — expected boolean, received string.

#### 17. Edge case: debug=false explicitly
- **Description:** Export with `debug` explicitly set to `false`.
- **Params:** `{ "platform": "windows", "debug": false }`
- **Expected result:** Godot initiates a release export. Same behavior as omitting `debug`.

---

## Tool: `validate_platform_export`

**Description:** Validate the project for export on a specific platform, checking for issues

**Parameters:**

| Parameter  | Type        | Required | Description                  |
| ---------- | ----------- | -------- | ---------------------------- |
| `platform` | `z.string()` | yes      | Platform to validate for     |

**Handler:** `callGodot(bridge, 'validate_platform_export', args)`

### Test Scenarios

#### 18. Happy path — validate for Windows Desktop
- **Description:** Validate project export readiness for Windows Desktop.
- **Params:** `{ "platform": "Windows Desktop" }`
- **Expected result:** Returns validation results (list of issues or confirmation that export is ready).

#### 19. Happy path — validate for Linux
- **Description:** Validate project export readiness for Linux.
- **Params:** `{ "platform": "Linux" }`
- **Expected result:** Returns validation results for Linux export.

#### 20. Happy path — validate for macOS
- **Description:** Validate project export readiness for macOS.
- **Params:** `{ "platform": "macOS" }`
- **Expected result:** Returns validation results for macOS export.

#### 21. Happy path — validate for Android
- **Description:** Validate project export readiness for Android.
- **Params:** `{ "platform": "Android" }`
- **Expected result:** Returns validation results for Android export.

#### 22. Happy path — validate for iOS
- **Description:** Validate project export readiness for iOS.
- **Params:** `{ "platform": "iOS" }`
- **Expected result:** Returns validation results for iOS export.

#### 23. Happy path — validate for Web
- **Description:** Validate project export readiness for Web (HTML5).
- **Params:** `{ "platform": "Web" }`
- **Expected result:** Returns validation results for Web export.

#### 24. Missing required param: platform
- **Description:** Call without the required `platform` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `platform` is required.

#### 25. Empty string platform
- **Description:** Call with an empty string for `platform`.
- **Params:** `{ "platform": "" }`
- **Expected result:** Godot-side error or empty validation result (empty string passes Zod validation but likely fails on Godot side).

#### 26. Non-existent platform
- **Description:** Call with a platform name that doesn't exist in the project.
- **Params:** `{ "platform": "Nintendo Switch" }`
- **Expected result:** Godot returns an error about unknown/unconfigured platform.

---

## Tool: `get_platform_export_templates`

**Description:** Get available export templates installed for the current Godot version

**Parameters:** None (empty schema)

**Handler:** `callGodot(bridge, 'get_platform_export_templates')`

### Test Scenarios

#### 27. Happy path — list available templates
- **Description:** Retrieve the list of installed export templates.
- **Params:** `{}`
- **Expected result:** Returns a list/object describing available export templates (platform, version, status).
- **Notes:** Result depends on which templates are installed in the Godot editor. May be empty if none are installed.

#### 28. No extra params
- **Description:** Verify passing extra params is tolerated or ignored.
- **Params:** `{ "extra": "ignored" }`
- **Expected result:** Should succeed and return templates. Extra params are typically ignored by Zod if schema is `{}`.

---

## Tool: `create_platform_export_preset`

**Description:** Create a new export preset for a specific platform with optional custom settings

**Parameters:**

| Parameter  | Type                                                  | Required | Default | Description                                       |
| ---------- | ----------------------------------------------------- | -------- | ------- | ------------------------------------------------- |
| `platform` | `z.string()`                                          | yes      | —       | Target platform (e.g. 'Windows Desktop', 'Linux', 'Android', 'Web') |
| `name`     | `Name` (`z.string()`)                                 | yes      | —       | Preset name                                       |
| `settings` | `OptionalProperties` (`z.record(z.unknown()).optional()`) | no       | —       | Optional property key-value pairs                 |

**Handler:** `callGodot(bridge, 'create_platform_export_preset', args)`

### Test Scenarios

#### 29. Happy path — create preset with minimum params
- **Description:** Create a Windows Desktop export preset with only required params.
- **Params:** `{ "platform": "Windows Desktop", "name": "My Windows Build" }`
- **Expected result:** Godot creates a new export preset named "My Windows Build" for Windows Desktop. Returns preset details or success confirmation.

#### 30. Happy path — create Linux preset
- **Description:** Create a Linux export preset with a descriptive name.
- **Params:** `{ "platform": "Linux", "name": "Linux Release" }`
- **Expected result:** Godot creates a new export preset for Linux.

#### 31. Happy path — create Android preset
- **Description:** Create an Android export preset.
- **Params:** `{ "platform": "Android", "name": "Android APK" }`
- **Expected result:** Godot creates a new export preset for Android.

#### 32. Happy path — create Web preset
- **Description:** Create a Web (HTML5) export preset.
- **Params:** `{ "platform": "Web", "name": "HTML5 Export" }`
- **Expected result:** Godot creates a new export preset for Web.

#### 33. Happy path — create preset with settings
- **Description:** Create a preset with custom settings.
- **Params:** `{ "platform": "Windows Desktop", "name": "Custom Windows", "settings": { "export_path": "C:/builds/my_game.exe", "binary_format": "64_bits" } }`
- **Expected result:** Godot creates the preset with the specified custom settings applied.

#### 34. Happy path — create preset with empty settings object
- **Description:** Create a preset with an empty settings object.
- **Params:** `{ "platform": "Windows Desktop", "name": "Empty Settings", "settings": {} }`
- **Expected result:** Godot creates the preset with default settings (same as omitting `settings`).

#### 35. Happy path — create preset with numeric settings
- **Description:** Create a preset with numeric values in settings.
- **Params:** `{ "platform": "Android", "name": "Android Custom", "settings": { "version_code": 1, "min_sdk": 21 } }`
- **Expected result:** Godot creates the preset with numeric settings applied.

#### 36. Missing required param: platform
- **Description:** Call without the required `platform` parameter.
- **Params:** `{ "name": "No Platform" }`
- **Expected result:** Zod validation error — `platform` is required.

#### 37. Missing required param: name
- **Description:** Call without the required `name` parameter.
- **Params:** `{ "platform": "Windows Desktop" }`
- **Expected result:** Zod validation error — `name` is required.

#### 38. Empty string name
- **Description:** Call with an empty string for preset name.
- **Params:** `{ "platform": "Windows Desktop", "name": "" }`
- **Expected result:** Godot-side error (empty name is likely rejected) or a preset with empty name is created (unlikely desirable).

#### 39. Duplicate name
- **Description:** Create a preset with a name that already exists.
- **Params:** `{ "platform": "Windows Desktop", "name": "Windows Desktop" }` (assuming a preset with this default name already exists)
- **Expected result:** Godot returns an error about duplicate preset name.

#### 40. Invalid platform string
- **Description:** Call with a platform name that Godot doesn't recognize.
- **Params:** `{ "platform": "PlayStation", "name": "PS5 Build" }`
- **Expected result:** Godot returns an error about unsupported/unknown platform.

#### 41. Invalid settings type
- **Description:** Pass a non-object value for settings.
- **Params:** `{ "platform": "Windows Desktop", "name": "Bad Settings", "settings": "not_an_object" }`
- **Expected result:** Zod validation error — expected object/record, received string.

---

## Tool: `run_exported_build`

**Description:** Run an exported build and capture its output

**Parameters:**

| Parameter | Type                         | Required | Default | Description                           |
| --------- | ---------------------------- | -------- | ------- | ------------------------------------- |
| `path`    | `FilePath` (`z.string()`)    | yes      | —       | Path to the exported executable       |
| `args`    | `z.array(z.string()).optional()` | no       | —       | Command-line arguments for the build  |

**Handler:** `callGodot(bridge, 'run_exported_build', args)`

### Test Scenarios

#### 42. Happy path — run build with minimum params
- **Description:** Run an exported executable with only the required path.
- **Params:** `{ "path": "C:/builds/my_game.exe" }`
- **Expected result:** Godot launches the exported build and captures its output. Returns process output or exit code.
- **Notes:** The executable must exist at the given path. This test requires a previously exported build.

#### 43. Happy path — run build with arguments
- **Description:** Run an exported executable with command-line arguments.
- **Params:** `{ "path": "C:/builds/my_game.exe", "args": ["--fullscreen", "--resolution", "1920x1080"] }`
- **Expected result:** Godot launches the build with the specified arguments and captures output.

#### 44. Happy path — run build with empty args array
- **Description:** Run an exported executable with an explicit empty args array.
- **Params:** `{ "path": "C:/builds/my_game.exe", "args": [] }`
- **Expected result:** Same behavior as omitting `args` — build runs with no extra arguments.

#### 45. Happy path — run Linux build
- **Description:** Run a Linux exported binary.
- **Params:** `{ "path": "/home/user/builds/game.x86_64" }`
- **Expected result:** Godot launches the Linux binary and captures output.

#### 46. Happy path — run macOS build
- **Description:** Run a macOS exported application bundle.
- **Params:** `{ "path": "/Applications/MyGame.app" }`
- **Expected result:** Godot launches the macOS app and captures output.

#### 47. Happy path — run with single argument
- **Description:** Run an exported executable with a single argument.
- **Params:** `{ "path": "C:/builds/my_game.exe", "args": ["--server"] }`
- **Expected result:** Godot launches the build with the `--server` flag.

#### 48. Missing required param: path
- **Description:** Call without the required `path` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `path` is required.

#### 49. Non-existent path
- **Description:** Call with a path to a file that does not exist.
- **Params:** `{ "path": "C:/nonexistent/nothing.exe" }`
- **Expected result:** Godot returns an error — file not found or cannot execute.

#### 50. Non-executable path
- **Description:** Call with a path to a non-executable file.
- **Params:** `{ "path": "res://project.godot" }`
- **Expected result:** Godot returns an error — cannot execute the file.

#### 51. Invalid path type
- **Description:** Pass a non-string value for path.
- **Params:** `{ "path": 12345 }`
- **Expected result:** Zod validation error — expected string, received number.

#### 52. Invalid args type
- **Description:** Pass a non-array value for args.
- **Params:** `{ "path": "C:/builds/my_game.exe", "args": "--fullscreen" }`
- **Expected result:** Zod validation error — expected array, received string.

#### 53. Args with special characters
- **Description:** Pass arguments containing special characters and spaces.
- **Params:** `{ "path": "C:/builds/my_game.exe", "args": ["--name", "My Game", "--config", "path/with spaces/config.json"] }`
- **Expected result:** Godot passes the arguments correctly to the process. Output should reflect that the arguments were received.

#### 54. Edge case: very long path
- **Description:** Call with a very long path string.
- **Params:** `{ "path": "C:/very/long/path/repeated/many/times/over/and/over/until/it/exceeds/normal/limits/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/game.exe" }`
- **Expected result:** Godot returns an error (path too long) or the OS rejects it.

---

## Tool: `validate_export_for_platform`

**Description:** Validate the project for export on a specific platform with detailed checks

**Parameters:**

| Parameter  | Type        | Required | Description                  |
| ---------- | ----------- | -------- | ---------------------------- |
| `platform` | `z.string()` | yes      | Platform to validate for     |

**Handler:** `callGodot(bridge, 'export/validate_platform', args)`

### Test Scenarios

#### 55. Happy path — detailed validate for Windows Desktop
- **Description:** Perform detailed validation for Windows Desktop export.
- **Params:** `{ "platform": "Windows Desktop" }`
- **Expected result:** Returns detailed validation results including resource checks, missing dependencies, configuration issues.

#### 56. Happy path — detailed validate for Linux
- **Description:** Perform detailed validation for Linux export.
- **Params:** `{ "platform": "Linux" }`
- **Expected result:** Returns detailed validation results for Linux.

#### 57. Happy path — detailed validate for macOS
- **Description:** Perform detailed validation for macOS export.
- **Params:** `{ "platform": "macOS" }`
- **Expected result:** Returns detailed validation results for macOS.

#### 58. Happy path — detailed validate for Android
- **Description:** Perform detailed validation for Android export.
- **Params:** `{ "platform": "Android" }`
- **Expected result:** Returns detailed validation results for Android (SDK path, keystore, permissions, etc.).

#### 59. Happy path — detailed validate for iOS
- **Description:** Perform detailed validation for iOS export.
- **Params:** `{ "platform": "iOS" }`
- **Expected result:** Returns detailed validation results for iOS (team ID, bundle ID, signing, etc.).

#### 60. Happy path — detailed validate for Web
- **Description:** Perform detailed validation for Web (HTML5) export.
- **Params:** `{ "platform": "Web" }`
- **Expected result:** Returns detailed validation results for Web export.

#### 61. Missing required param: platform
- **Description:** Call without the required `platform` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `platform` is required.

#### 62. Empty string platform
- **Description:** Call with an empty string for `platform`.
- **Params:** `{ "platform": "" }`
- **Expected result:** Godot-side error — empty platform is invalid.

#### 63. Non-existent platform
- **Description:** Call with a platform name that doesn't exist in the project.
- **Params:** `{ "platform": "Dreamcast" }`
- **Expected result:** Godot returns an error about unknown platform or no matching export preset.

#### 64. Compare with `validate_platform_export`
- **Description:** Verify that `validate_export_for_platform` returns more detailed output than `validate_platform_export` for the same platform.
- **Params:** Call both `{ "platform": "Windows Desktop" }` on `validate_platform_export` and `validate_export_for_platform`.
- **Expected result:** `validate_export_for_platform` response should contain additional detail fields (resource checks, dependency analysis, etc.) that `validate_platform_export` does not include.
- **Notes:** This is a comparative test against tool #18.

---

## Cross-Tool Integration Scenarios

These scenarios test multiple tools in sequence to validate realistic workflows.

#### 65. Full export workflow: validate → create preset → export → run
- **Description:** End-to-end export workflow for Windows Desktop.
- **Steps:**
  1. `validate_export_for_platform` with `{ "platform": "Windows Desktop" }` — confirm project is ready
  2. `create_platform_export_preset` with `{ "platform": "Windows Desktop", "name": "E2E Test Preset" }` — create preset
  3. `get_platform_export_templates` with `{}` — verify template for target platform exists
  4. `export_for_platform` with `{ "platform": "windows", "debug": false }` — run the export
  5. `run_exported_build` with `{ "path": "<output_path>" }` — verify the exported build runs
- **Expected result:** Each step succeeds in sequence.

#### 66. Validate all six platforms
- **Description:** Call `validate_export_for_platform` for all six supported platform strings.
- **Params (sequential):**
  - `{ "platform": "Windows Desktop" }`
  - `{ "platform": "Linux" }`
  - `{ "platform": "macOS" }`
  - `{ "platform": "Android" }`
  - `{ "platform": "iOS" }`
  - `{ "platform": "Web" }`
- **Expected result:** Each call returns validation results. Platforms without export presets may return warnings/errors about missing configuration.
