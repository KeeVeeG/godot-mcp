# Platform Specific Tools Test Plan

**Source**: `server/src/tools/platform_specific.ts`
**Total tools**: 6
**Test plan generated**: 2026-07-08

---

## Table of Contents

1. [Tool: get_platform_settings](#tool-get_platform_settings)
2. [Tool: configure_ios](#tool-configure_ios)
3. [Tool: configure_android](#tool-configure_android)
4. [Tool: configure_web](#tool-configure_web)
5. [Tool: get_platform_capabilities](#tool-get_platform_capabilities)
6. [Tool: validate_platform_build](#tool-validate_platform_build)

---

## Related Tools (Dependencies)

Some platform-specific tools work best in conjunction with tools from other modules:

| Related Tool | Module | When to use |
|---|---|---|
| `export_for_platform` | `platform_export.ts` | After configuring platform settings, export the project for that platform |
| `validate_platform_export` | `platform_export.ts` | Validate export readiness after configuring platform settings |
| `get_platform_export_templates` | `platform_export.ts` | Check available export templates before configuring platforms |
| `create_platform_export_preset` | `platform_export.ts` | Create export presets after configuring platform settings |
| `get_project_info` | `project.ts` | Verify project state before platform configuration |

### Recommended Call Order for Full Platform Setup

1. `get_platform_settings` — read current platform settings
2. `configure_ios` / `configure_android` / `configure_web` — apply platform-specific configuration
3. `get_platform_capabilities` — verify platform capabilities
4. `validate_platform_build` — check for build issues
5. `export_for_platform` (from `platform_export.ts`) — export the project

---

## Tool: get_platform_settings

**Tool name**: `get_platform_settings`
**Description**: Get platform-specific settings for a target platform
**Backend method**: `get_platform_settings`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `platform` | `z.string()` | Yes | — | Platform name (e.g. 'ios', 'android', 'web', 'windows', 'linux', 'macos') |

### Test Scenarios

#### Scenario 1: Happy path — iOS platform

**Description**: Get settings for iOS platform.
**Params**:
```json
{
  "platform": "ios"
}
```
**Expected result**: Returns iOS-specific settings as JSON. Should contain `content` array with text describing iOS configuration (bundle ID, team ID, signing settings, etc.).
**Notes**: Requires Godot editor connected with a project open.
**What to pay attention to**: Verify that all iOS-specific settings are returned. The response format must be JSON in the text field `content[0].text`.

---

#### Scenario 2: Happy path — Android platform

**Description**: Get settings for Android platform.
**Params**:
```json
{
  "platform": "android"
}
```
**Expected result**: Returns Android-specific settings (package name, keystore info, permissions, etc.).
**What to pay attention to**: Verify that Android settings contain package_name, keystore, and permissions.

---

#### Scenario 3: Happy path — Web platform

**Description**: Get settings for web/HTML5 platform.
**Params**:
```json
{
  "platform": "web"
}
```
**Expected result**: Returns web platform settings (canvas resize, threading, PWA configuration).
**What to pay attention to**: Settings must include canvas_resize, threading, and pwa flags.

---

#### Scenario 4: Happy path — Windows platform

**Description**: Get settings for Windows desktop platform.
**Params**:
```json
{
  "platform": "windows"
}
```
**Expected result**: Returns Windows-specific settings.
**What to pay attention to**: Verify that Windows-specific settings are returned correctly.

---

#### Scenario 5: Happy path — Linux platform

**Description**: Get settings for Linux platform.
**Params**:
```json
{
  "platform": "linux"
}
```
**Expected result**: Returns Linux-specific settings.
**What to pay attention to**: Verify correctness of Linux-specific settings.

---

#### Scenario 6: Happy path — macOS platform

**Description**: Get settings for macOS platform.
**Params**:
```json
{
  "platform": "macos"
}
```
**Expected result**: Returns macOS-specific settings.
**What to pay attention to**: Verify that macOS settings include appropriate signing parameters and bundle ID.

---

#### Scenario 7: Edge case — empty string platform

**Description**: Empty string as platform name.
**Params**:
```json
{
  "platform": ""
}
```
**Expected result**: Error from Godot side — empty string is not a valid platform name. The Zod schema (`z.string()`) accepts empty strings, so validation passes on the MCP side, but Godot should reject it.
**What to pay attention to**: Verify behavior — Zod does not restrict empty strings, so the error is expected from Godot, not from validation.

---

#### Scenario 8: Edge case — unknown platform name

**Description**: Platform name that doesn't exist.
**Params**:
```json
{
  "platform": "playstation"
}
```
**Expected result**: Error from Godot side indicating unsupported platform. The tool does not have an enum constraint on platform, so any string passes Zod validation.
**What to pay attention to**: Verify that Godot returns a meaningful error for an unknown platform, not a crash.

---

#### Scenario 9: Edge case — platform name with special characters

**Description**: Platform name containing special characters.
**Params**:
```json
{
  "platform": "ios; DROP TABLE users;--"
}
```
**Expected result**: Error from Godot side — invalid platform name. Should not cause any injection or unexpected behavior.
**What to pay attention to**: Verify that special characters do not cause problems. This is not SQL, but it is important to check for absence of injection-like behavior.

---

## Tool: configure_ios

**Tool name**: `configure_ios`
**Description**: Configure iOS-specific project settings including bundle ID, team ID, and code signing
**Backend method**: `configure_ios`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `settings` | `z.object({...})` | Yes | — | iOS settings to configure |
| `settings.bundle_id` | `z.string().optional()` | No | — | iOS bundle identifier (e.g. com.company.game) |
| `settings.team_id` | `z.string().optional()` | No | — | Apple Developer Team ID |
| `settings.signing` | `z.record(z.unknown()).optional()` | No | — | Code signing configuration (key-value pairs) |

### Test Scenarios

#### Scenario 1: Happy path — set bundle_id only

**Description**: Configure only the bundle ID.
**Params**:
```json
{
  "settings": {
    "bundle_id": "com.mycompany.mygame"
  }
}
```
**Expected result**: Success response. Bundle ID should be set to `com.mycompany.mygame`.
**Notes**: Minimum required — only `settings` object with one field.
**What to pay attention to**: Verify that bundle_id is saved correctly. The format must be reverse-DNS style.

---

#### Scenario 2: Happy path — set team_id only

**Description**: Configure only the Apple Team ID.
**Params**:
```json
{
  "settings": {
    "team_id": "ABCDE12345"
  }
}
```
**Expected result**: Success response. Team ID should be set.
**What to pay attention to**: Team ID typically has a 10-character format (alphanumeric). Verify that the value is accepted as-is.

---

#### Scenario 3: Happy path — set all fields

**Description**: Configure bundle ID, team ID, and signing simultaneously.
**Params**:
```json
{
  "settings": {
    "bundle_id": "com.mycompany.mygame",
    "team_id": "ABCDE12345",
    "signing": {
      "identity": "iPhone Distribution",
      "provisioning_profile": "MyGame_AdHoc"
    }
  }
}
```
**Expected result**: Success response. All three iOS settings should be applied.
**What to pay attention to**: Verify that all three fields are applied simultaneously without conflicts. The signing structure is arbitrary (record), verify that arbitrary keys are accepted.

---

#### Scenario 4: Happy path — empty settings object

**Description**: Pass empty settings object — no changes requested.
**Params**:
```json
{
  "settings": {}
}
```
**Expected result**: Success response (no-op). The settings object is required but all fields are optional, so empty object is valid.
**What to pay attention to**: Verify that an empty object does not cause an error. This is a valid call — no field is mandatory.

---

#### Scenario 5: Happy path — signing with complex nested config

**Description**: Signing configuration with multiple nested key-value pairs.
**Params**:
```json
{
  "settings": {
    "bundle_id": "com.mycompany.mygame",
    "signing": {
      "identity": "Apple Development: John Doe (XXXXXXXXXX)",
      "provisioning_profile": "MyGame_Development",
      "entitlements": {
        "aps-environment": "development",
        "com.apple.developer.networking.wifi-info": true
      }
    }
  }
}
```
**Expected result**: Success response. Complex nested signing configuration should be accepted.
**What to pay attention to**: `signing` is `z.record(z.unknown())`, so it supports arbitrary nesting. Verify that a deeply nested object is not lost.

---

#### Scenario 6: Edge case — bundle_id with invalid format

**Description**: Bundle ID with spaces and special characters.
**Params**:
```json
{
  "settings": {
    "bundle_id": "my invalid bundle id!!!"
  }
}
```
**Expected result**: May succeed (Zod accepts any string) but Godot or iOS build tools may reject it later. Verify behavior.
**What to pay attention to**: Verify whether Godot accepts invalid bundle IDs or returns an error. Bundle ID format validation may happen on the Godot side.

---

#### Scenario 7: Edge case — very long bundle_id

**Description**: Extremely long bundle identifier.
**Params**:
```json
{
  "settings": {
    "bundle_id": "com.verylongcompanyname.verylongproductname.with.many.segments.and.extremely.long.identifier.that.goes.on.and.on"
  }
}
```
**Expected result**: Should accept the value (string type), but Apple has limits (~255 chars). Verify behavior with very long strings.
**What to pay attention to**: Verify that a long string does not crash the processing. Bundle ID length limits are defined by Apple, not Godot.

---

## Tool: configure_android

**Tool name**: `configure_android`
**Description**: Configure Android-specific project settings including package name, keystore, and permissions
**Backend method**: `configure_android`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `settings` | `z.object({...})` | Yes | — | Android settings to configure |
| `settings.package_name` | `z.string().optional()` | No | — | Android package name (e.g. com.company.game) |
| `settings.keystore` | `z.record(z.unknown()).optional()` | No | — | Keystore configuration for signing |
| `settings.permissions` | `z.array(z.string()).optional()` | No | — | Android permissions to declare |

### Test Scenarios

#### Scenario 1: Happy path — set package_name only

**Description**: Configure only the Android package name.
**Params**:
```json
{
  "settings": {
    "package_name": "com.mycompany.mygame"
  }
}
```
**Expected result**: Success response. Package name should be set.
**What to pay attention to**: Verify that package_name is saved. Format — reverse-DNS.

---

#### Scenario 2: Happy path — set permissions only

**Description**: Configure Android permissions.
**Params**:
```json
{
  "settings": {
    "permissions": [
      "android.permission.INTERNET",
      "android.permission.ACCESS_NETWORK_STATE",
      "android.permission.VIBRATE"
    ]
  }
}
```
**Expected result**: Success response. Permissions should be declared in the project.
**What to pay attention to**: Verify that all three permissions are saved. The permission format must be the full Android path (android.permission.*).

---

#### Scenario 3: Happy path — set keystore only

**Description**: Configure keystore for signing.
**Params**:
```json
{
  "settings": {
    "keystore": {
      "path": "/path/to/release.keystore",
      "password": "mypassword",
      "alias": "mykey",
      "alias_password": "mypassword"
    }
  }
}
```
**Expected result**: Success response. Keystore configuration should be applied.
**What to pay attention to**: Verify that keystore accepts arbitrary keys (it is a record). Keystore path, password, and alias are standard Android signing fields.

---

#### Scenario 4: Happy path — set all fields simultaneously

**Description**: Configure package name, keystore, and permissions at once.
**Params**:
```json
{
  "settings": {
    "package_name": "com.mycompany.mygame",
    "keystore": {
      "path": "/path/to/release.keystore",
      "password": "mypassword",
      "alias": "mykey"
    },
    "permissions": [
      "android.permission.INTERNET",
      "android.permission.VIBRATE"
    ]
  }
}
```
**Expected result**: Success response. All Android settings should be applied together.
**What to pay attention to**: Verify that all fields are applied atomically. No conflicts between package_name, keystore, and permissions.

---

#### Scenario 5: Happy path — empty settings object

**Description**: Pass empty settings object.
**Params**:
```json
{
  "settings": {}
}
```
**Expected result**: Success response (no-op). All fields in settings are optional.
**What to pay attention to**: Similar to configure_ios — an empty object is valid.

---

#### Scenario 6: Happy path — empty permissions array

**Description**: Clear all permissions by passing empty array.
**Params**:
```json
{
  "settings": {
    "permissions": []
  }
}
```
**Expected result**: Success response. Empty array may clear existing permissions or be a no-op depending on Godot implementation.
**What to pay attention to**: Verify behavior — an empty array may mean "remove all permissions" or "do not change". Depends on the Godot plugin implementation.

---

#### Scenario 7: Edge case — permissions with invalid format

**Description**: Permissions with non-standard format.
**Params**:
```json
{
  "settings": {
    "permissions": ["INTERNET", "not.a.valid.permission"]
  }
}
```
**Expected result**: May succeed (Zod accepts any string in the array), but Android build tools may reject invalid permission names.
**What to pay attention to**: Verify whether Godot accepts invalid permission strings or validates their format.

---

#### Scenario 8: Edge case — keystore with empty values

**Description**: Keystore configuration with empty strings.
**Params**:
```json
{
  "settings": {
    "keystore": {
      "path": "",
      "password": "",
      "alias": ""
    }
  }
}
```
**Expected result**: May succeed (Zod accepts empty strings) but will likely cause signing failures during export.
**What to pay attention to**: Verify that empty values do not crash the processing. The error may only manifest during export.

---

## Tool: configure_web

**Tool name**: `configure_web`
**Description**: Configure web/HTML5 export settings including canvas resize, threading, and PWA support
**Backend method**: `configure_web`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `settings` | `z.object({...})` | Yes | — | Web platform settings to configure |
| `settings.canvas_resize` | `z.boolean().optional()` | No | — | Enable automatic canvas resizing |
| `settings.threading` | `z.boolean().optional()` | No | — | Enable SharedArrayBuffer threading support |
| `settings.pwa` | `z.boolean().optional()` | No | — | Enable Progressive Web App support |

### Test Scenarios

#### Scenario 1: Happy path — enable canvas_resize only

**Description**: Enable automatic canvas resizing.
**Params**:
```json
{
  "settings": {
    "canvas_resize": true
  }
}
```
**Expected result**: Success response. Canvas resize should be enabled.
**What to pay attention to**: Verify that canvas_resize is set to true. This setting affects how the HTML5 canvas adapts to the window size.

---

#### Scenario 2: Happy path — enable threading only

**Description**: Enable SharedArrayBuffer threading support.
**Params**:
```json
{
  "settings": {
    "threading": true
  }
}
```
**Expected result**: Success response. Threading support should be enabled.
**What to pay attention to**: SharedArrayBuffer requires COOP/COEP headers on the server. Verify that the setting is saved.

---

#### Scenario 3: Happy path — enable PWA only

**Description**: Enable Progressive Web App support.
**Params**:
```json
{
  "settings": {
    "pwa": true
  }
}
```
**Expected result**: Success response. PWA support should be enabled.
**What to pay attention to**: PWA enables service worker and manifest. Verify that the setting is applied.

---

#### Scenario 4: Happy path — enable all web features

**Description**: Enable all web platform features simultaneously.
**Params**:
```json
{
  "settings": {
    "canvas_resize": true,
    "threading": true,
    "pwa": true
  }
}
```
**Expected result**: Success response. All three web features should be enabled.
**What to pay attention to**: Verify that all three settings are applied simultaneously. Threading + PWA may have compatibility constraints.

---

#### Scenario 5: Happy path — disable all web features

**Description**: Explicitly disable all web features.
**Params**:
```json
{
  "settings": {
    "canvas_resize": false,
    "threading": false,
    "pwa": false
  }
}
```
**Expected result**: Success response. All three features should be disabled.
**What to pay attention to**: Verify that `false` is processed correctly — this is not deletion of the setting, but explicit disabling.

---

#### Scenario 6: Happy path — empty settings object

**Description**: Pass empty settings object.
**Params**:
```json
{
  "settings": {}
}
```
**Expected result**: Success response (no-op). All fields are optional.
**What to pay attention to**: Similar to the previous tools — an empty object is valid.

---

#### Scenario 7: Edge case — partial configuration (mix enable/disable)

**Description**: Enable some features, disable others.
**Params**:
```json
{
  "settings": {
    "canvas_resize": true,
    "threading": false,
    "pwa": true
  }
}
```
**Expected result**: Success response. canvas_resize=true, threading=false, pwa=true should all be applied.
**What to pay attention to**: Verify that each boolean flag is applied independently. Disabling threading should not affect PWA.

---

## Tool: get_platform_capabilities

**Tool name**: `get_platform_capabilities`
**Description**: Get the available features and capabilities for a specific platform
**Backend method**: `get_platform_capabilities`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `platform` | `z.string()` | Yes | — | Platform name to query capabilities for |

### Test Scenarios

#### Scenario 1: Happy path — iOS capabilities

**Description**: Query capabilities for iOS platform.
**Params**:
```json
{
  "platform": "ios"
}
```
**Expected result**: Returns iOS capabilities as JSON. Should include information about supported features (touch input, accelerometer, camera, etc.).
**What to pay attention to**: Verify that capabilities contain a list of supported iOS features. Format — JSON in the text field of content.

---

#### Scenario 2: Happy path — Android capabilities

**Description**: Query capabilities for Android platform.
**Params**:
```json
{
  "platform": "android"
}
```
**Expected result**: Returns Android capabilities (touch, sensors, intents, etc.).
**What to pay attention to**: Android capabilities should differ from iOS (e.g., intents instead of deep links).

---

#### Scenario 3: Happy path — Web capabilities

**Description**: Query capabilities for web platform.
**Params**:
```json
{
  "platform": "web"
}
```
**Expected result**: Returns web capabilities (WebGL, Web Audio, etc.).
**What to pay attention to**: Web capabilities are specific — WebGL version, Worker support, SharedArrayBuffer, etc.

---

#### Scenario 4: Happy path — Windows capabilities

**Description**: Query capabilities for Windows platform.
**Params**:
```json
{
  "platform": "windows"
}
```
**Expected result**: Returns Windows capabilities.
**What to pay attention to**: Windows capabilities may include DirectX version, .NET integration, etc.

---

#### Scenario 5: Happy path — Linux capabilities

**Description**: Query capabilities for Linux platform.
**Params**:
```json
{
  "platform": "linux"
}
```
**Expected result**: Returns Linux capabilities.
**What to pay attention to**: Verify that Linux-specific capabilities (Wayland/X11, PulseAudio/ALSA) are reflected.

---

#### Scenario 6: Happy path — macOS capabilities

**Description**: Query capabilities for macOS platform.
**Params**:
```json
{
  "platform": "macos"
}
```
**Expected result**: Returns macOS capabilities.
**What to pay attention to**: macOS capabilities may include Metal API, Gatekeeper, notarization.

---

#### Scenario 7: Edge case — unknown platform

**Description**: Query capabilities for an unsupported platform.
**Params**:
```json
{
  "platform": "switch"
}
```
**Expected result**: Error from Godot indicating unsupported platform, or empty capabilities list.
**What to pay attention to**: Verify how an unknown platform is handled — error or empty result.

---

#### Scenario 8: Edge case — empty platform string

**Description**: Empty string as platform name.
**Params**:
```json
{
  "platform": ""
}
```
**Expected result**: Error from Godot side.
**What to pay attention to**: Zod accepts an empty string, but Godot should reject it.

---

## Tool: validate_platform_build

**Tool name**: `validate_platform_build`
**Description**: Validate the project for building on a specific platform, checking for issues
**Backend method**: `validate_platform_build`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `platform` | `z.string()` | Yes | — | Platform to validate the build for |

### Test Scenarios

#### Scenario 1: Happy path — validate for iOS

**Description**: Validate the project for iOS build.
**Params**:
```json
{
  "platform": "ios"
}
```
**Expected result**: Returns validation results. Should contain list of issues/warnings if any, or success message if project is ready for iOS build.
**Notes**: Prerequisite: project should have iOS export preset configured for meaningful validation.
**What to pay attention to**: Verify that the result contains a list of issues or a readiness confirmation. Format — JSON with issues/warnings.

---

#### Scenario 2: Happy path — validate for Android

**Description**: Validate the project for Android build.
**Params**:
```json
{
  "platform": "android"
}
```
**Expected result**: Returns Android validation results. May check for keystore, SDK, permissions, etc.
**What to pay attention to**: Android validation may check for Android SDK, keystore, and package name correctness.

---

#### Scenario 3: Happy path — validate for web

**Description**: Validate the project for web/HTML5 build.
**Params**:
```json
{
  "platform": "web"
}
```
**Expected result**: Returns web validation results. May check for threading compatibility, export template availability.
**What to pay attention to**: Web validation may check WebGL compatibility and export template availability.

---

#### Scenario 4: Happy path — validate for Windows

**Description**: Validate the project for Windows build.
**Params**:
```json
{
  "platform": "windows"
}
```
**Expected result**: Returns Windows validation results.
**What to pay attention to**: Windows validation is typically simpler — checking export template and code signing (optional).

---

#### Scenario 5: Happy path — validate for Linux

**Description**: Validate the project for Linux build.
**Params**:
```json
{
  "platform": "linux"
}
```
**Expected result**: Returns Linux validation results.
**What to pay attention to**: Linux validation may be minimal — mainly checking export template.

---

#### Scenario 6: Happy path — validate for macOS

**Description**: Validate the project for macOS build.
**Params**:
```json
{
  "platform": "macos"
}
```
**Expected result**: Returns macOS validation results. May check for code signing, notarization settings.
**What to pay attention to**: macOS validation may check signing and notarization settings.

---

#### Scenario 7: Edge case — unknown platform

**Description**: Validate for an unsupported platform.
**Params**:
```json
{
  "platform": "ps5"
}
```
**Expected result**: Error from Godot indicating unsupported platform.
**What to pay attention to**: Verify that Godot returns a clear error, not a crash.

---

#### Scenario 8: Edge case — empty platform string

**Description**: Empty string as platform name.
**Params**:
```json
{
  "platform": ""
}
```
**Expected result**: Error from Godot side.
**What to pay attention to**: Zod accepts an empty string, Godot should reject it.

---

#### Scenario 9: Edge case — platform with whitespace

**Description**: Platform name with leading/trailing whitespace.
**Params**:
```json
{
  "platform": "  ios  "
}
```
**Expected result**: Likely error — Godot probably doesn't trim whitespace, so "  ios  " won't match "ios".
**What to pay attention to**: Verify whitespace sensitivity. Godot most likely does not trim whitespace.

---

## Cross-Tool Workflow Scenarios

### Workflow 1: Full iOS Platform Setup

**Description**: Complete iOS platform configuration and validation workflow.
**Steps**:

1. Call `get_platform_settings` with `{ "platform": "ios" }` to read current settings
2. Call `configure_ios` with:
   ```json
   {
     "settings": {
       "bundle_id": "com.mycompany.mygame",
       "team_id": "ABCDE12345",
       "signing": {
         "identity": "iPhone Distribution",
         "provisioning_profile": "MyGame_AdHoc"
       }
     }
   }
   ```
3. Call `get_platform_capabilities` with `{ "platform": "ios" }` to verify capabilities
4. Call `validate_platform_build` with `{ "platform": "ios" }` to check for issues

**Expected result**: All calls succeed. Validation should pass if iOS export template is installed and settings are correct.
**What to pay attention to**: Verify that settings set via configure_ios are reflected in the subsequent get_platform_settings call.

---

### Workflow 2: Full Android Platform Setup

**Description**: Complete Android platform configuration and validation.
**Steps**:

1. Call `get_platform_settings` with `{ "platform": "android" }` to read current settings
2. Call `configure_android` with:
   ```json
   {
     "settings": {
       "package_name": "com.mycompany.mygame",
       "keystore": {
         "path": "/path/to/release.keystore",
         "password": "mypassword",
         "alias": "mykey"
       },
       "permissions": [
         "android.permission.INTERNET",
         "android.permission.VIBRATE"
       ]
     }
   }
   ```
3. Call `get_platform_capabilities` with `{ "platform": "android" }` to verify capabilities
4. Call `validate_platform_build` with `{ "platform": "android" }` to check for issues

**Expected result**: All calls succeed. Validation should check keystore, package name, and permissions.
**What to pay attention to**: Verify that permissions from configure_android appear in validation.

---

### Workflow 3: Web Platform Configuration

**Description**: Configure web platform and validate.
**Steps**:

1. Call `get_platform_settings` with `{ "platform": "web" }` to read current settings
2. Call `configure_web` with:
   ```json
   {
     "settings": {
       "canvas_resize": true,
       "threading": true,
       "pwa": true
     }
   }
   ```
3. Call `get_platform_capabilities` with `{ "platform": "web" }` to verify capabilities
4. Call `validate_platform_build` with `{ "platform": "web" }` to check for issues

**Expected result**: All calls succeed. Web validation may warn about SharedArrayBuffer requirements for threading.
**What to pay attention to**: Threading + PWA may require specific server headers (COOP/COEP). Verify that validation warns about this.

---

### Workflow 4: Multi-Platform Configuration

**Description**: Configure multiple platforms in sequence.
**Steps**:

1. Call `configure_ios` with iOS settings
2. Call `configure_android` with Android settings
3. Call `configure_web` with web settings
4. Call `get_platform_settings` for each platform to verify settings persisted
5. Call `validate_platform_build` for each platform

**Expected result**: All configurations persist independently. Each platform's settings don't interfere with others.
**What to pay attention to**: Verify that different platform settings do not overwrite each other. iOS, Android, and Web must be stored independently.

---

## General Notes for Test Execution

### Prerequisites

- **Godot editor** must be running with the MCP plugin active and connected
- A **Godot project** must be open
- For meaningful validation, **export presets** should be configured for the target platforms
- For iOS testing, Apple export templates should be installed
- For Android testing, Android SDK and keystore should be available

### Common Error Patterns

| Error | Likely Cause |
|---|---|
| `"Godot request failed: ..."` | Godot editor returned an error — check the message |
| Zod validation error | Invalid parameter types passed to the tool |
| Timeout | Godot editor is busy or unresponsive |
| `"Godot editor is not connected"` | MCP plugin not active or WebSocket disconnected |

### Response Format

All tools return `ToolResult` with structure:
```json
{
  "content": [
    {
      "type": "text",
      "text": "<JSON string or plain text>"
    }
  ],
  "isError": true  // only on error
}
```

### Platform Name Reference

Standard platform names accepted by these tools:
- `ios`
- `android`
- `web`
- `windows`
- `linux`
- `macos`

Note: The tools use `z.string()` (not `z.enum()`) for platform parameters, so any string passes Zod validation. Invalid platform names are rejected by the Godot side.