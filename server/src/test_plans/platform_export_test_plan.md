# Platform Export Tools — Test Plan

**Source file:** `server/src/tools/platform_export.ts`  
**Shared types:** `server/src/tools/shared-types.ts`  
**Number of tools:** 6  
**Generated:** 2026-07-08

---

## Type Reference

| Zod schema | Underlying type | Description |
|---|---|---|
| `z.enum(['windows', 'linux', 'macos', 'android', 'ios', 'web'])` | enum string | Target platform for export |
| `z.boolean().optional().default(false)` | boolean | Debug build flag (default: `false` = release) |
| `z.string()` | string | Generic string for platform name |
| `Name` | `z.string().describe('Name identifier')` | Generic name identifier |
| `FilePath` | `z.string().describe("File path (e.g. 'res://path/to/file')")` | Generic file path |
| `OptionalProperties` | `z.record(z.unknown()).optional().describe('Optional property key-value pairs')` | Optional dictionary of arbitrary property key-value pairs |
| `z.array(z.string()).optional()` | string[] (optional) | Optional array of command-line argument strings |

---

## Tool 1: `export_for_platform`

**Description:** Export the project for a specific platform.  
**Handler route:** `export_for_platform`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `platform` | `enum: 'windows' \| 'linux' \| 'macos' \| 'android' \| 'ios' \| 'web'` | ✅ Yes | — | Target platform |
| `debug` | `boolean` | No | `false` | Export as debug build (default: false = release) |

### Test Scenarios

#### 1.1 Happy path — release build for each platform enum

For each of the six platform values, test the default release export:

- **1.1a windows:** `{ "platform": "windows" }`
  - **Expected result:** Success. Project exported for Windows Desktop in release mode.

- **1.1b linux:** `{ "platform": "linux" }`
  - **Expected result:** Success. Project exported for Linux in release mode.

- **1.1c macos:** `{ "platform": "macos" }`
  - **Expected result:** Success. Project exported for macOS in release mode.

- **1.1d android:** `{ "platform": "android" }`
  - **Expected result:** Success. Project exported for Android in release mode. Requires Android SDK configured.

- **1.1e ios:** `{ "platform": "ios" }`
  - **Expected result:** Success. Project exported for iOS in release mode. May require macOS host.

- **1.1f web:** `{ "platform": "web" }`
  - **Expected result:** Success. Project exported for Web/HTML5 in release mode.

#### 1.2 Happy path — debug build for each platform enum

Each platform with `debug: true`:

- **1.2a windows debug:** `{ "platform": "windows", "debug": true }`
  - **Expected result:** Success. Windows export in debug mode (includes symbols).

- **1.2b linux debug:** `{ "platform": "linux", "debug": true }`
  - **Expected result:** Success. Linux export in debug mode.

- **1.2c macos debug:** `{ "platform": "macos", "debug": true }`
  - **Expected result:** Success. macOS export in debug mode.

- **1.2d android debug:** `{ "platform": "android", "debug": true }`
  - **Expected result:** Success. Android export in debug mode.

- **1.2e ios debug:** `{ "platform": "ios", "debug": true }`
  - **Expected result:** Success. iOS export in debug mode.

- **1.2f web debug:** `{ "platform": "web", "debug": true }`
  - **Expected result:** Success. Web export in debug mode.

#### 1.3 Happy path — explicit release build (`debug: false`)
- **Params:** `{ "platform": "windows", "debug": false }`
- **Expected result:** Success. Same behavior as omitting `debug` — release mode export.

#### 1.4 Edge case — missing required `platform`
- **Params:** `{}`
- **Expected result:** Zod validation error. `platform` is required.

#### 1.5 Edge case — invalid platform string (not in enum)
- **Params:** `{ "platform": "playstation" }`
- **Expected result:** Zod validation error. `platform` must be one of the six enum values.

#### 1.6 Edge case — invalid platform type (number, boolean, null)
- **Params:** `{ "platform": 123 }`
- **Expected result:** Zod validation error. Expected string, got number.

#### 1.7 Edge case — `debug` as a string instead of boolean
- **Params:** `{ "platform": "windows", "debug": "true" }`
- **Expected result:** Zod validation error. Expected boolean, got string.

#### 1.8 Edge case — `debug` as a number
- **Params:** `{ "platform": "windows", "debug": 1 }`
- **Expected result:** Zod validation error. Expected boolean, got number.

#### 1.9 Edge case — export without export templates installed
- **Params:** `{ "platform": "android" }`
- **Expected result:** Error from Godot. Export templates for the target platform are not installed.

#### 1.10 Edge case — export without an export preset configured
- **Params:** `{ "platform": "windows" }`
- **Expected result:** Error or uses default preset. Depending on Godot version, may auto-create or fail.

#### 1.11 Edge case — export with unconfigured export preset (missing output path)
- **Params:** `{ "platform": "windows" }`
- **Expected result:** Error from Godot. Export preset exists but is not fully configured (e.g., missing output path).

#### 1.12 Edge case — export with empty project (no main scene)
- **Params:** `{ "platform": "web" }`
- **Expected result:** Error or warning from Godot. Project has no main scene configured.

#### 1.13 Edge case — extra unknown params
- **Params:** `{ "platform": "linux", "debug": false, "extra_field": "unexpected" }`
- **Expected result:** Zod strips unknown field (due to default Zod behavior with object schemas) or passes it through to Godot (which ignores it). Verify behavior.

---

## Tool 2: `validate_platform_export`

**Description:** Validate the project for export on a specific platform, checking for issues.  
**Handler route:** `validate_platform_export`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `platform` | `string` | ✅ Yes | — | Platform to validate for |

### Test Scenarios

#### 2.1 Happy path — validate for each common platform name

- **2.1a Windows Desktop:** `{ "platform": "Windows Desktop" }`
  - **Expected result:** Success. Returns validation results — any warnings or errors for Windows export.

- **2.1b Linux/X11:** `{ "platform": "Linux" }`
  - **Expected result:** Success. Returns validation results for Linux export.

- **2.1c macOS:** `{ "platform": "macOS" }`
  - **Expected result:** Success. Returns validation results for macOS export.

- **2.1d Android:** `{ "platform": "Android" }`
  - **Expected result:** Success. Returns validation results for Android export. Checks for Android SDK.

- **2.1e iOS:** `{ "platform": "iOS" }`
  - **Expected result:** Success. Returns validation results for iOS export.

- **2.1f Web:** `{ "platform": "Web" }`
  - **Expected result:** Success. Returns validation results for Web/HTML5 export.

#### 2.2 Happy path — validate for lowercase platform name
- **Params:** `{ "platform": "windows" }`
- **Expected result:** Success or platform-specific error. Tests case sensitivity of platform name matching.

#### 2.3 Edge case — missing required `platform`
- **Params:** `{}`
- **Expected result:** Zod validation error. `platform` is required.

#### 2.4 Edge case — empty string platform
- **Params:** `{ "platform": "" }`
- **Expected result:** Error from Godot. Empty string is not a valid platform.

#### 2.5 Edge case — non-existent platform
- **Params:** `{ "platform": "Nintendo Switch" }`
- **Expected result:** Error from Godot. Platform not recognized / no export templates for this platform.

#### 2.6 Edge case — platform with special characters
- **Params:** `{ "platform": "Windows Desktop!" }`
- **Expected result:** Error from Godot. Invalid platform name.

#### 2.7 Edge case — validate without export templates installed
- **Params:** `{ "platform": "Android" }`
- **Expected result:** Warning or error. Export templates for the platform are not installed, so validation may report missing templates.

#### 2.8 Edge case — validate with unconfigured export preset
- **Params:** `{ "platform": "iOS" }`
- **Expected result:** Validation returns warnings about unconfigured settings (e.g., missing bundle ID, team ID, code signing).

#### 2.9 Edge case — validate unconfigured project (no main scene, missing settings)
- **Params:** `{ "platform": "Web" }`
- **Expected result:** Validation returns multiple warnings/errors (missing main scene, missing HTML shell, etc.).

#### 2.10 Edge case — extra unknown params
- **Params:** `{ "platform": "Windows Desktop", "extra": "value" }`
- **Expected result:** Zod strips unknown field or passes through. Verify behavior doesn't break.

---

## Tool 3: `get_platform_export_templates`

**Description:** Get available export templates installed for the current Godot version.  
**Handler route:** `get_platform_export_templates`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| *(none)* | — | — | — | No parameters — tool takes no input |

### Test Scenarios

#### 3.1 Happy path — export templates installed
- **Params:** `{}`  (no params)
- **Expected result:** Success. Returns a list/object of installed export templates with their versions and supported platforms (e.g., `{ "windows": "4.3.stable", "linux": "4.3.stable" }`).
- **Setup:** Requires Godot with export templates downloaded via the official export template manager.

#### 3.2 Happy path — no export templates installed
- **Params:** `{}`  (no params)
- **Expected result:** Success. Returns empty result or an object indicating no templates are installed.
- **Setup:** Fresh Godot installation without downloaded templates.

#### 3.3 Happy path — partial templates installed
- **Params:** `{}`  (no params)
- **Expected result:** Success. Returns only the templates that are installed (e.g., `{ "windows": "4.3.stable" }` with others missing).
- **Setup:** Only some platform templates downloaded.

#### 3.4 Edge case — passing unexpected params to a no-param tool
- **Params:** `{ "platform": "windows" }`
- **Expected result:** Zod may ignore extra params (empty schema). Verify Godot doesn't error on unexpected arguments.

#### 3.5 Edge case — Godot version mismatch
- **Params:** `{}`
- **Expected result:** If templates don't match the Godot editor version, the result may show templates for a different version or warn about version mismatch.

---

## Tool 4: `create_platform_export_preset`

**Description:** Create a new export preset for a specific platform with optional custom settings.  
**Handler route:** `create_platform_export_preset`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `platform` | `string` | ✅ Yes | — | Target platform (e.g. `'Windows Desktop'`, `'Linux'`, `'Android'`, `'Web'`) |
| `name` | `Name` (string) | ✅ Yes | — | Preset name |
| `settings` | `OptionalProperties` (record, optional) | No | — | Optional property key-value pairs |

### Test Scenarios

#### 4.1 Happy path — create preset with minimum required params

Test for each common platform string:

- **4.1a Windows Desktop:** `{ "platform": "Windows Desktop", "name": "Windows Release" }`
  - **Expected result:** Success. Creates a Windows Desktop export preset named "Windows Release" with default settings.

- **4.1b Linux:** `{ "platform": "Linux", "name": "Linux Build" }`
  - **Expected result:** Success. Creates a Linux export preset with default settings.

- **4.1c macOS:** `{ "platform": "macOS", "name": "macOS App" }`
  - **Expected result:** Success. Creates a macOS export preset.

- **4.1d Android:** `{ "platform": "Android", "name": "Android APK" }`
  - **Expected result:** Success. Creates an Android export preset.

- **4.1e iOS:** `{ "platform": "iOS", "name": "iOS IPA" }`
  - **Expected result:** Success. Creates an iOS export preset.

- **4.1f Web:** `{ "platform": "Web", "name": "HTML5 Build" }`
  - **Expected result:** Success. Creates a Web/HTML5 export preset.

#### 4.2 Happy path — create preset with custom settings

- **4.2a With output path:** `{ "platform": "Windows Desktop", "name": "Custom Windows", "settings": { "export_path": "C:/builds/game.exe" } }`
  - **Expected result:** Success. Preset created with custom export path.

- **4.2b With multiple settings:** `{ "platform": "Android", "name": "Android Debug", "settings": { "export_path": "builds/android.apk", "use_debug": true, "package/unique_name": "com.example.game" } }`
  - **Expected result:** Success. Preset created with all specified settings applied.

- **4.2c With empty settings:** `{ "platform": "Web", "name": "Web Default", "settings": {} }`
  - **Expected result:** Success. Same behavior as omitting `settings` — creates preset with default values.

#### 4.3 Happy path — create preset with special characters in name
- **Params:** `{ "platform": "Linux", "name": "Linux v2.0 (stable)" }`
- **Expected result:** Success. Preset created with the exact name including special characters.

#### 4.4 Edge case — missing required `platform`
- **Params:** `{ "name": "My Preset" }`
- **Expected result:** Zod validation error. `platform` is required.

#### 4.5 Edge case — missing required `name`
- **Params:** `{ "platform": "Windows Desktop" }`
- **Expected result:** Zod validation error. `name` is required.

#### 4.6 Edge case — empty string platform
- **Params:** `{ "platform": "", "name": "Empty Platform" }`
- **Expected result:** Error from Godot. Empty string is not a valid platform.

#### 4.7 Edge case — empty string name
- **Params:** `{ "platform": "Windows Desktop", "name": "" }`
- **Expected result:** Error from Godot. Empty string is not a valid preset name.

#### 4.8 Edge case — non-existent platform
- **Params:** `{ "platform": "PlayStation 5", "name": "PS5 Build" }`
- **Expected result:** Error from Godot. Platform not recognized / not supported.

#### 4.9 Edge case — duplicate preset name
- **Params:** `{ "platform": "Windows Desktop", "name": "Windows Release" }` (when a preset with that name already exists)
- **Expected result:** Error from Godot. A preset with this name already exists.

#### 4.10 Edge case — invalid settings value types
- **Params:** `{ "platform": "Web", "name": "Bad Web", "settings": { "export_path": 123 } }` (path as number)
- **Expected result:** Either Zod passes it through (record of unknown) and Godot rejects the invalid value, or Godot silently converts/ignores it. Verify behavior.

#### 4.11 Edge case — settings with non-serializable values
- **Params:** `{ "platform": "Windows Desktop", "name": "Bad Settings", "settings": { "callback": () => {} } }`
- **Expected result:** JSON serialization error at the transport layer. Function cannot be serialized.

#### 4.12 Edge case — name as number instead of string
- **Params:** `{ "platform": "Windows Desktop", "name": 42 }`
- **Expected result:** Zod validation error. `name` expected string, got number.

---

## Tool 5: `run_exported_build`

**Description:** Run an exported build and capture its output.  
**Handler route:** `run_exported_build`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `FilePath` (string) | ✅ Yes | — | Path to the exported executable |
| `args` | `string[]` (optional) | No | — | Command-line arguments for the build |

### Test Scenarios

#### 5.1 Happy path — run exported build with no arguments
- **Params:** `{ "path": "C:/builds/game.exe" }`
- **Expected result:** Success. Launches the exported executable and returns its console output (stdout/stderr).
- **Setup:** Requires a previously exported build at the specified path.

#### 5.2 Happy path — run exported build with single argument
- **Params:** `{ "path": "C:/builds/game.exe", "args": ["--fullscreen"] }`
- **Expected result:** Success. Launches the executable with `--fullscreen` flag. Returns output.

#### 5.3 Happy path — run exported build with multiple arguments
- **Params:** `{ "path": "C:/builds/game.exe", "args": ["--fullscreen", "--resolution", "1920x1080", "--server"] }`
- **Expected result:** Success. Launches the executable with all provided arguments. Returns output.

#### 5.4 Happy path — run exported build with empty args array
- **Params:** `{ "path": "C:/builds/game.exe", "args": [] }`
- **Expected result:** Success. Same behavior as omitting `args` — runs with no arguments.

#### 5.5 Happy path — run Linux executable
- **Params:** `{ "path": "/home/user/builds/game.x86_64", "args": ["--headless"] }`
- **Expected result:** Success. Launches the Linux executable in headless mode.

#### 5.6 Happy path — run macOS .app bundle
- **Params:** `{ "path": "/Applications/MyGame.app/Contents/MacOS/MyGame" }`
- **Expected result:** Success. Launches the macOS executable inside the .app bundle.

#### 5.7 Happy path — run Web build (local server)
- **Params:** `{ "path": "C:/builds/web/index.html" }`
- **Expected result:** May spawn a local server or fail depending on Godot behavior for web builds. Verify whether web exports are supported by this tool.

#### 5.8 Edge case — missing required `path`
- **Params:** `{}`
- **Expected result:** Zod validation error. `path` is required.

#### 5.9 Edge case — path to non-existent executable
- **Params:** `{ "path": "C:/nonexistent/game.exe" }`
- **Expected result:** Error from Godot. File not found or cannot execute.

#### 5.10 Edge case — path to a directory instead of executable
- **Params:** `{ "path": "C:/builds/" }`
- **Expected result:** Error from Godot. Path is a directory, not an executable.

#### 5.11 Edge case — path to a non-executable file
- **Params:** `{ "path": "C:/builds/readme.txt" }`
- **Expected result:** Error from Godot. File is not executable.

#### 5.12 Edge case — empty string path
- **Params:** `{ "path": "" }`
- **Expected result:** Zod validation error or Godot error. Empty path is invalid.

#### 5.13 Edge case — invalid args type (string instead of array)
- **Params:** `{ "path": "C:/builds/game.exe", "args": "--fullscreen" }`
- **Expected result:** Zod validation error. `args` expected array of strings, got string.

#### 5.14 Edge case — args containing non-string values
- **Params:** `{ "path": "C:/builds/game.exe", "args": ["--port", 8080] }`
- **Expected result:** Zod validation error. `z.array(z.string())` — array element must be string, got number.

#### 5.15 Edge case — args with spaces in values
- **Params:** `{ "path": "C:/builds/game.exe", "args": ["--server-name", "My Game Server"] }`
- **Expected result:** Success. Arguments with spaces are properly escaped/quoted when passed to the process.

#### 5.16 Edge case — path type wrong (number instead of string)
- **Params:** `{ "path": 12345 }`
- **Expected result:** Zod validation error. Expected string, got number.

---

## Tool 6: `validate_export_for_platform`

**Description:** Validate the project for export on a specific platform with detailed checks.  
**Handler route:** `export/validate_platform`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `platform` | `string` | ✅ Yes | — | Platform to validate for |

### Test Scenarios

#### 6.1 Happy path — validate for each common platform name (detailed checks)

- **6.1a Windows Desktop:** `{ "platform": "Windows Desktop" }`
  - **Expected result:** Success. Returns detailed validation results — checks export path, icon, certificate, file associations, etc.

- **6.1b Linux:** `{ "platform": "Linux" }`
  - **Expected result:** Success. Returns detailed validation for Linux.

- **6.1c macOS:** `{ "platform": "macOS" }`
  - **Expected result:** Success. Returns detailed validation for macOS including .app bundle config, code signing.

- **6.1d Android:** `{ "platform": "Android" }`
  - **Expected result:** Success. Returns detailed validation — SDK path, keystore, package name, permissions, architecture settings.

- **6.1e iOS:** `{ "platform": "iOS" }`
  - **Expected result:** Success. Returns detailed validation — bundle ID, team ID, provisioning profile, capabilities.

- **6.1f Web:** `{ "platform": "Web" }`
  - **Expected result:** Success. Returns detailed validation — HTML shell, canvas settings, PWA manifest, threading support.

#### 6.2 Happy path — validate with fully configured preset
- **Params:** `{ "platform": "Windows Desktop" }`
- **Expected result:** Success. All checks pass — no errors, possibly only informational messages.
- **Setup:** Requires a fully configured export preset for the platform.

#### 6.3 Happy path — validate with unconfigured preset (expect warnings)
- **Params:** `{ "platform": "Android" }`
- **Expected result:** Success. Validation returns detailed warnings/errors for each unconfigured setting (missing keystore, missing SDK, etc.).

#### 6.4 Edge case — missing required `platform`
- **Params:** `{}`
- **Expected result:** Zod validation error. `platform` is required.

#### 6.5 Edge case — empty string platform
- **Params:** `{ "platform": "" }`
- **Expected result:** Error from Godot. Empty string is not a valid platform.

#### 6.6 Edge case — non-existent platform
- **Params:** `{ "platform": "Xbox Series X" }`
- **Expected result:** Error from Godot. Platform not recognized.

#### 6.7 Edge case — platform with leading/trailing whitespace
- **Params:** `{ "platform": "  Android  " }`
- **Expected result:** Either Zod passes the string through (leading/trailing spaces included) and Godot fails to match the platform name, or Zod trims. Verify behavior.

#### 6.8 Edge case — no export preset exists for the platform
- **Params:** `{ "platform": "iOS" }` (with no iOS export preset configured)
- **Expected result:** Error or warning. No preset found for the specified platform.

---

## Cross-Tool Interactions and Integration Scenarios

### 7.1 Full workflow — templates → preset → validate → export → run

1. **Get templates:** `get_platform_export_templates` — verify Windows templates installed
2. **Create preset:** `create_platform_export_preset` with `{ "platform": "Windows Desktop", "name": "Integration Test" }`
3. **Detailed validate:** `validate_export_for_platform` with `{ "platform": "Windows Desktop" }` — check for issues
4. **Basic validate:** `validate_platform_export` with `{ "platform": "Windows Desktop" }` — quick check
5. **Export:** `export_for_platform` with `{ "platform": "windows", "debug": false }`
6. **Run:** `run_exported_build` with `{ "path": "path/to/exported.exe" }` — verify the build runs

### 7.2 Partial workflow — validate before export catches issues
1. `validate_export_for_platform` reports missing Android keystore
2. Fix the issue
3. Re-validate — passes
4. `export_for_platform` with `{ "platform": "android" }` — succeeds

### 7.3 Multiple platform workflow — export for web after desktop
1. `export_for_platform` with `{ "platform": "windows" }` — succeeds
2. `export_for_platform` with `{ "platform": "web" }` — succeeds independently
3. `run_exported_build` for the Windows build — verify both builds work

### 7.4 Tool discrimination — `validate_platform_export` vs `validate_export_for_platform`
- Both validate a platform, but `validate_export_for_platform` routes to `export/validate_platform` with "detailed checks"
- `validate_platform_export` routes to `validate_platform_export` — presumably a simpler/faster check
- Test both with identical params to verify they return different levels of detail
- **Params (both):** `{ "platform": "Windows Desktop" }`
- **Expected:** `validate_export_for_platform` returns more detailed output than `validate_platform_export`

---

## Parameter Validation Summary

| Tool | Required params | Optional params | No params |
|------|----------------|-----------------|-----------|
| `export_for_platform` | `platform` | `debug` | — |
| `validate_platform_export` | `platform` | — | — |
| `get_platform_export_templates` | — | — | ✅ |
| `create_platform_export_preset` | `platform`, `name` | `settings` | — |
| `run_exported_build` | `path` | `args` | — |
| `validate_export_for_platform` | `platform` | — | — |

---

## Enum Coverage

### `export_for_platform.platform` enum values

| Value | Tested in scenario |
|-------|-------------------|
| `windows` | 1.1a, 1.2a, 1.3 |
| `linux` | 1.1b, 1.2b |
| `macos` | 1.1c, 1.2c |
| `android` | 1.1d, 1.2d, 1.9 |
| `ios` | 1.1e, 1.2e |
| `web` | 1.1f, 1.2f |

### `export_for_platform.debug` boolean values

| Value | Tested in scenario |
|-------|-------------------|
| `false` (default) | 1.1a–1.1f, 1.3 |
| `true` | 1.2a–1.2f |
| `"true"` (string — invalid) | 1.7 |
| `1` (number — invalid) | 1.8 |
