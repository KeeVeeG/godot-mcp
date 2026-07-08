# Test Plan: Platform Export Tools

**File:** `server/src/tools/platform_export.ts`
**Tools count:** 6
**Registration function:** `registerPlatformExportTools(server, bridge)`
**Dependencies:** `shared-types.ts` (z, Name, FilePath, OptionalProperties), `server.ts` (`callGodot`)

---

## Tool: `export_for_platform`

**Description:** Export the project for a specific platform

**Parameters:**

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `platform` | `string` | ✅ | — | enum: `windows`, `linux`, `macos`, `android`, `ios`, `web` | Target platform |
| `debug` | `boolean` | ❌ | `false` | — | Export as debug build |

**Handler:** `callGodot(bridge, 'export_for_platform', args)`
**Godot method:** `export_for_platform`

### Test Scenarios

#### Scenario 1: Happy path — export for Windows release
**Description:** Minimal required params, release build (debug defaults to false).

```json
{
  "platform": "windows"
}
```

**Expected result:**
- `callGodot` called with method `export_for_platform` and args `{ platform: "windows" }`
- `debug` defaults to `false` (Zod default)
- Returns success result with export output (file path, size, etc.)
- **Note:** `debug` is not passed in args if not specified — Zod default kicks in at the validation level, but `args as Record<string, unknown>` may not contain `debug`. Verify that Godot receives `debug: false` or that the absence of the key is handled as release.

#### Scenario 2: Export for Linux with debug=true
**Description:** Explicit debug flag set to true.

```json
{
  "platform": "linux",
  "debug": true
}
```

**Expected result:**
- `callGodot` called with `{ platform: "linux", debug: true }`
- Returns success result indicating debug export
- **Note:** the result should differ from release (different file, different size, or debug-specific inclusions).

#### Scenario 3: Export for Android
**Description:** Mobile platform export.

```json
{
  "platform": "android",
  "debug": false
}
```

**Expected result:**
- `callGodot` called with `{ platform: "android", debug: false }`
- Returns success result (APK/AAB path)
- **Note:** Android export may require an export template and settings (keystore, package name). If not configured — an error with a clear message should appear.

#### Scenario 4: Export for Web
**Description:** HTML5/Web platform export.

```json
{
  "platform": "web",
  "debug": true
}
```

**Expected result:**
- `callGodot` called with `{ platform: "web", debug: true }`
- Returns success result (HTML/JS/WASM files)
- **Note:** Web export generates multiple files (.html, .js, .wasm). Verify that the result contains all necessary files.

#### Scenario 5: Missing required `platform` param
**Description:** Call without the required `platform` field.

```json
{}
```

**Expected result:**
- Zod validation error: `platform` is required
- Error returned to client, `callGodot` NOT called
- **Note:** the error should be a validation error from Zod, not from Godot.

#### Scenario 6: Invalid platform value
**Description:** `platform` value not in the allowed enum.

```json
{
  "platform": "switch"
}
```

**Expected result:**
- Zod validation error: `platform` must be one of `windows`, `linux`, `macos`, `android`, `ios`, `web`
- Error returned to client, `callGodot` NOT called
- **Note:** Zod enum strictly validates allowed values. The error should contain the list of allowed values.

#### Scenario 7: Invalid debug type
**Description:** `debug` passed as string instead of boolean.

```json
{
  "platform": "windows",
  "debug": "yes"
}
```

**Expected result:**
- Zod validation error: `debug` expected boolean, received string
- Error returned to client, `callGodot` NOT called
- **Note:** Zod does not coerce boolean by default — the string "yes" will not be converted to `true`.

---

## Tool: `validate_platform_export`

**Description:** Validate the project for export on a specific platform, checking for issues

**Parameters:**

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `platform` | `string` | ✅ | — | — (freeform string) | Platform to validate for |

**Handler:** `callGodot(bridge, 'validate_platform_export', args)`
**Godot method:** `validate_platform_export`

> ⚠️ **Note:** This tool accepts ANY string as `platform` (z.string()), unlike `export_for_platform` which uses z.enum(). This means `platform: "nintendo_switch"` will pass Zod validation but may fail in Godot.

### Test Scenarios

#### Scenario 1: Happy path — validate for Windows
```json
{
  "platform": "windows"
}
```

**Expected result:**
- `callGodot` called with `{ platform: "windows" }`
- Returns validation result (list of warnings/errors or empty if clean)
- **Note:** the result should contain a structured list of issues or confirmation that the project is ready for export.

#### Scenario 2: Validate for Android
```json
{
  "platform": "android"
}
```

**Expected result:**
- `callGodot` called with `{ platform: "android" }`
- Returns validation result, possibly with Android-specific checks (keystore, permissions)
- **Note:** Android-specific checks should be included.

#### Scenario 3: Validate for Web
```json
{
  "platform": "web"
}
```

**Expected result:**
- `callGodot` called with `{ platform: "web" }`
- Returns validation result with web-specific checks
- **Note:** Web-specific checks (threading, PWA).

#### Scenario 4: Missing required `platform`
```json
{}
```

**Expected result:**
- Zod validation error: `platform` is required
- `callGodot` NOT called

#### Scenario 5: Unknown/unsupported platform string
```json
{
  "platform": "dreamcast"
}
```

**Expected result:**
- Zod validation passes (z.string() accepts any string)
- `callGodot` called with `{ platform: "dreamcast" }`
- Godot-side returns error (unknown platform)
- **Note:** platform validation happens on the Godot side, not in Zod. This differs from `export_for_platform`.

---

## Tool: `get_platform_export_templates`

**Description:** Get available export templates installed for the current Godot version

**Parameters:** None (empty `inputSchema`)

**Handler:** `callGodot(bridge, 'get_platform_export_templates')` — no args passed
**Godot method:** `get_platform_export_templates`

### Test Scenarios

#### Scenario 1: Happy path — get export templates
**Description:** No parameters needed. Query installed export templates.

```json
{}
```

**Expected result:**
- `callGodot` called with method `get_platform_export_templates` and no args
- Returns list of installed export templates (platform, version, path)
- **Note:** the result depends on which templates are installed in the system. Should return an array/list with information about each template. If no templates are installed — an empty list or a message about absence.

#### Scenario 2: Extra params ignored
**Description:** Call with extraneous params to verify they're ignored.

```json
{
  "unexpected": "param"
}
```

**Expected result:**
- Tool accepts call (extra params typically ignored by MCP)
- `callGodot` called normally
- **Note:** verify that the presence of extra parameters does not cause an error.

---

## Tool: `create_platform_export_preset`

**Description:** Create a new export preset for a specific platform with optional custom settings

**Parameters:**

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `platform` | `string` | ✅ | — | — (freeform) | Target platform (e.g. 'Windows Desktop', 'Linux', 'Android', 'Web') |
| `name` | `string` | ✅ | — | — | Preset name |
| `settings` | `Record<string, unknown>` | ❌ | — | — | Optional property key-value pairs |

**Handler:** `callGodot(bridge, 'create_platform_export_preset', args)`
**Godot method:** `create_platform_export_preset`

> **Note on `platform`:** The description mentions specific Godot platform strings like `'Windows Desktop'`, `'Linux'`, `'Android'`, `'Web'`. These are Godot Editor names, not the short forms used in `export_for_platform`. Tests should use the Godot-native names.

### Test Scenarios

#### Scenario 1: Happy path — create Windows Desktop preset
**Description:** Minimal required params only.

```json
{
  "platform": "Windows Desktop",
  "name": "My Windows Build"
}
```

**Expected result:**
- `callGodot` called with `{ platform: "Windows Desktop", name: "My Windows Build" }`
- `settings` omitted (optional, not passed)
- Returns success with created preset info
- **Note:** the preset should be created with default settings for the platform. Verify that the preset name appears in the preset list.

#### Scenario 2: Create preset with custom settings
**Description:** Preset with explicit custom export settings.

```json
{
  "platform": "Web",
  "name": "Production Web Build",
  "settings": {
    "html/custom_html_shell": "res://web/shell.html",
    "html/head_include": "<meta name='viewport'>",
    "vram_texture_compression/for_desktop": true
  }
}
```

**Expected result:**
- `callGodot` called with all three fields
- Returns success with preset containing custom settings
- **Note:** verify that custom settings are actually applied to the preset (can be retrieved via `get_export_presets_list` or similar).

#### Scenario 3: Create Android preset with settings
```json
{
  "platform": "Android",
  "name": "Debug Android",
  "settings": {
    "gradle_build/use_gradle_build": true,
    "gradle_build/export_format": 0
  }
}
```

**Expected result:**
- Returns success with Android-specific preset
- **Note:** Android presets have specific gradle settings. Verify that they are correctly saved.

#### Scenario 4: Missing required `platform`
```json
{
  "name": "Test"
}
```

**Expected result:**
- Zod validation error: `platform` is required
- `callGodot` NOT called

#### Scenario 5: Missing required `name`
```json
{
  "platform": "Linux"
}
```

**Expected result:**
- Zod validation error: `name` is required
- `callGodot` NOT called

#### Scenario 6: Empty name string
```json
{
  "platform": "Linux",
  "name": ""
}
```

**Expected result:**
- Zod validation passes (z.string() accepts empty string)
- `callGodot` called with empty name
- Godot-side may reject empty name or create preset with empty name
- **Note:** `Name` is `z.string().describe(...)` — has no minLength. An empty string will pass Zod validation. Godot may return an error or create a preset with an empty name.

#### Scenario 7: Invalid settings type
```json
{
  "platform": "Linux",
  "name": "Test",
  "settings": "not a record"
}
```

**Expected result:**
- Zod validation error: `settings` expected object, received string
- `callGodot` NOT called

---

## Tool: `run_exported_build`

**Description:** Run an exported build and capture its output

**Parameters:**

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `path` | `string` | ✅ | — | — | Path to the exported executable |
| `args` | `string[]` | ❌ | — | — | Command-line arguments for the build |

**Handler:** `callGodot(bridge, 'run_exported_build', args)`
**Godot method:** `run_exported_build`

### Test Scenarios

#### Scenario 1: Happy path — run build with no args
**Description:** Run an exported executable without additional arguments.

```json
{
  "path": "res://exports/windows/game.exe"
}
```

**Expected result:**
- `callGodot` called with `{ path: "res://exports/windows/game.exe" }`
- Returns execution output (stdout, stderr, exit code)
- **Note:** the result should contain the process output. If the file does not exist — an error with a clear message.

#### Scenario 2: Run build with command-line args
```json
{
  "path": "res://exports/linux/game.x86_64",
  "args": ["--fullscreen", "--resolution", "1920x1080"]
}
```

**Expected result:**
- `callGodot` called with `{ path: "res://exports/linux/game.x86_64", args: ["--fullscreen", "--resolution", "1920x1080"] }`
- Returns execution output
- **Note:** verify that arguments are passed correctly to the launched process.

#### Scenario 3: Run web build (HTML)
```json
{
  "path": "res://exports/web/index.html",
  "args": []
}
```

**Expected result:**
- `callGodot` called with path and empty args array
- Web builds may behave differently (no direct executable)
- **Note:** running a web build may require a separate HTTP server. Verify how this case is handled.

#### Scenario 4: Missing required `path`
```json
{}
```

**Expected result:**
- Zod validation error: `path` is required
- `callGodot` NOT called

#### Scenario 5: Invalid path type (number)
```json
{
  "path": 12345
}
```

**Expected result:**
- Zod validation error: `path` expected string, received number
- `callGodot` NOT called

#### Scenario 6: Invalid args type
```json
{
  "path": "res://exports/game.exe",
  "args": "--fullscreen"
}
```

**Expected result:**
- Zod validation error: `args` expected array, received string
- `callGodot` NOT called
- **Note:** `args` is `z.array(z.string())` — a single string will not pass.

#### Scenario 7: Non-existent file path
```json
{
  "path": "res://exports/nonexistent/game.exe"
}
```

**Expected result:**
- Zod validation passes (path is just a string)
- `callGodot` called, Godot returns file-not-found error
- **Note:** path validation happens on the Godot side.

---

## Tool: `validate_export_for_platform`

**Description:** Validate the project for export on a specific platform with detailed checks

**Parameters:**

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `platform` | `string` | ✅ | — | — (freeform string) | Platform to validate for |

**Handler:** `callGodot(bridge, 'export/validate_platform', args)`
**Godot method:** `export/validate_platform`

> ⚠️ **DUPLICATE NOTE:** This tool is functionally identical to `validate_platform_export` (#2) — same parameters, same purpose. The only differences:
> - Description says "with detailed checks" (vs "checking for issues")
> - Godot method is `export/validate_platform` (vs `validate_export_for_platform`)
>
> Both accept freeform `z.string()` for platform. The test scenarios are the same; the difference is in the Godot-side handler response.

### Test Scenarios

#### Scenario 1: Happy path — detailed validation for Windows
```json
{
  "platform": "windows"
}
```

**Expected result:**
- `callGodot` called with method `export/validate_platform` and `{ platform: "windows" }`
- Returns detailed validation result (more granular than `validate_platform_export`)
- **Note:** compare the result with `validate_platform_export` — this tool should return more detailed information.

#### Scenario 2: Detailed validation for Android
```json
{
  "platform": "android"
}
```

**Expected result:**
- `callGodot` called with `{ platform: "android" }`
- Returns detailed Android-specific checks
- **Note:** Android-specific checks (SDK, keystore, permissions).

#### Scenario 3: Missing required `platform`
```json
{}
```

**Expected result:**
- Zod validation error: `platform` is required
- `callGodot` NOT called

#### Scenario 4: Empty string platform
```json
{
  "platform": ""
}
```

**Expected result:**
- Zod validation passes (empty string is valid z.string())
- `callGodot` called with `{ platform: "" }`
- Godot-side returns error (empty platform)
- **Note:** empty string passes Zod. Godot should handle this correctly.

---

## Cross-Tool Dependencies and Sequences

### Prerequisites for testing

Before running platform export tools, the following setup is typically needed:

1. **Godot Editor connected** — MCP server must have an active WebSocket connection to the Godot editor
2. **Export templates installed** — Call `get_platform_export_templates` first to verify templates exist
3. **Export presets configured** — Use `create_platform_export_preset` if no presets exist for the target platform

### Recommended test execution order

```
Step 1: get_platform_export_templates()
        → Verify export templates are installed
        → If missing: user must install templates manually in Godot

Step 2: validate_platform_export(platform="windows")
        → Check project is ready for export
        → Fix any reported issues

Step 3: validate_export_for_platform(platform="windows")
        → Get detailed validation (optional deep check)

Step 4: create_platform_export_preset(platform="Windows Desktop", name="CI Build")
        → Create preset if not exists (idempotent check)

Step 5: export_for_platform(platform="windows")
        → Actually export the project

Step 6: run_exported_build(path=<path from step 5 output>)
        → Run and verify the exported build
        → The path comes from the result of step 5
```

### Tools that depend on each other

| Tool | Depends on | Why |
|------|-----------|-----|
| `run_exported_build` | `export_for_platform` | Needs the exported file path from the export result |
| `export_for_platform` | `get_platform_export_templates` | Templates must be installed before export |
| `export_for_platform` | `create_platform_export_preset` | Preset may need to exist for the platform |
| `validate_export_for_platform` | (none) | Read-only, can run standalone |
| `validate_platform_export` | (none) | Read-only, can run standalone |
| `create_platform_export_preset` | (none) | Standalone, creates configuration |
| `get_platform_export_templates` | (none) | Read-only, no dependencies |

### Tools from other files that may be needed

| External Tool | Used For | When |
|---------------|----------|------|
| `get_export_presets_list` | Verify presets exist before export | Before `export_for_platform` |
| `get_project_info` | Check project metadata | Before validation tools |
| `list_scenes` | Verify scenes exist | Before export (export requires scenes) |

---

## Edge Cases and Special Considerations

### 1. Zod coercion behavior
- `z.boolean()` does NOT coerce strings — `"true"` and `"false"` will fail validation
- `z.string()` accepts empty strings — no minLength validation on `platform` or `name`
- `z.enum()` is strict — only exact matches from the list

### 2. Duplicate tools
- `validate_platform_export` and `validate_export_for_platform` are near-duplicates
- They call different Godot methods (`validate_platform_export` vs `export/validate_platform`)
- Both accept freeform `z.string()` for platform (no enum constraint)
- **Test recommendation:** verify both return results and note any differences in detail level

### 3. Platform naming inconsistency
- `export_for_platform` uses short names: `windows`, `linux`, `macos`, `android`, `ios`, `web`
- `create_platform_export_preset` description mentions Godot names: `Windows Desktop`, `Linux`, `Android`, `Web`
- **Test recommendation:** test both naming conventions and verify which works for each tool

### 4. No output path parameter
- `export_for_platform` does NOT accept an output path parameter
- The export destination is determined by Godot's export preset configuration
- **Test recommendation:** verify where exported files end up (check Godot's default export path)

### 5. `callGodot` error propagation
- All tools delegate to `callGodot(bridge, method, args)`
- If Godot returns an error, it propagates through the MCP response
- **Test recommendation:** verify error messages from Godot are passed through to the MCP client

### 6. args spreading behavior
- All tools pass `args as Record<string, unknown>` directly to `callGodot`
- Zod defaults (like `debug: false`) are applied BEFORE the handler receives args
- **Test recommendation:** verify that Zod-default values appear in the args passed to Godot
