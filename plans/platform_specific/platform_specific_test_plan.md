# Platform-Specific Test Plan

> **Source file:** `server/src/tools/platform_specific.ts`  
> **Shared types:** `server/src/tools/shared-types.ts`  
> **Tools covered:** 6 (`get_platform_settings`, `configure_ios`, `configure_android`, `configure_web`, `get_platform_capabilities`, `validate_platform_build`)  
> **Generated:** 2026-07-08

---

## Schema Details

### Shared Imports

| Import | Zod Schema | Description |
|--------|-----------|-------------|
| `z` | Zod namespace | Used directly for `z.string()`, `z.boolean()`, `z.object()`, `z.array()`, `z.record()` |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | Optional record of unknown key-value pairs, used for `signing` and `keystore` sub-objects |

### Parameter Summary

| Tool | Param | Type | Required | Default | Enum/Choices | Notes |
|------|-------|------|----------|---------|--------------|-------|
| `get_platform_settings` | `platform` | `string` | ✅ yes | — | — | Platform name (e.g. 'ios', 'android', 'web', 'windows', 'linux', 'macos') |
| `configure_ios` | `settings` | `object` | ✅ yes | — | — | Wrapper object containing iOS config fields |
| | `settings.bundle_id` | `string` | no | — | — | iOS bundle identifier (e.g. com.company.game) |
| | `settings.team_id` | `string` | no | — | — | Apple Developer Team ID |
| | `settings.signing` | `record(unknown)` | no | — | — | Code signing configuration (arbitrary key-value pairs) |
| `configure_android` | `settings` | `object` | ✅ yes | — | — | Wrapper object containing Android config fields |
| | `settings.package_name` | `string` | no | — | — | Android package name (e.g. com.company.game) |
| | `settings.keystore` | `record(unknown)` | no | — | — | Keystore configuration for signing (arbitrary key-value pairs) |
| | `settings.permissions` | `string[]` | no | — | — | Android permissions to declare |
| `configure_web` | `settings` | `object` | ✅ yes | — | — | Wrapper object containing Web config fields |
| | `settings.canvas_resize` | `boolean` | no | — | — | Enable automatic canvas resizing |
| | `settings.threading` | `boolean` | no | — | — | Enable SharedArrayBuffer threading support |
| | `settings.pwa` | `boolean` | no | — | — | Enable Progressive Web App support |
| `get_platform_capabilities` | `platform` | `string` | ✅ yes | — | — | Platform name to query capabilities for |
| `validate_platform_build` | `platform` | `string` | ✅ yes | — | — | Platform to validate the build for |

---

## Tool: get_platform_settings

### Schema

```typescript
{
  description: 'Get platform-specific settings for a target platform',
  inputSchema: {
    platform: z.string().describe("Platform name (e.g. 'ios', 'android', 'web', 'windows', 'linux', 'macos')"),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'get_platform_settings', args as Record<string, unknown>)
```

### Tool Behavior
Retrieves the current platform-specific project settings for a given target platform. Returns settings such as package identifiers, signing configuration, display settings, and other platform-specific options configured in the Godot project. Takes exactly one required parameter: the platform name.

### Test Scenarios

#### Scenario 1: Happy path — get settings for 'windows'
- **Description:** Retrieve platform settings for Windows Desktop.
- **Params:** `{ "platform": "windows" }`
- **Expected result:** Returns a JSON object containing current Windows platform settings (e.g., export settings, icon paths, signing options). Should not error.
- **Notes:** Windows settings are typically always available since Godot runs on desktop.

#### Scenario 2: Happy path — get settings for 'linux'
- **Description:** Retrieve platform settings for Linux/X11.
- **Params:** `{ "platform": "linux" }`
- **Expected result:** Returns a JSON object containing current Linux platform settings. Should succeed.
- **Notes:** 

#### Scenario 3: Happy path — get settings for 'macos'
- **Description:** Retrieve platform settings for macOS.
- **Params:** `{ "platform": "macos" }`
- **Expected result:** Returns a JSON object containing current macOS platform settings. Should succeed.
- **Notes:** Works even on non-macOS hosts — returns the configured settings, not system-level checks.

#### Scenario 4: Happy path — get settings for 'ios'
- **Description:** Retrieve platform settings for iOS.
- **Params:** `{ "platform": "ios" }`
- **Expected result:** Returns a JSON object containing current iOS platform settings (bundle ID, team ID, signing, etc.). Should succeed.
- **Notes:** Settings may be empty/default if not previously configured.

#### Scenario 5: Happy path — get settings for 'android'
- **Description:** Retrieve platform settings for Android.
- **Params:** `{ "platform": "android" }`
- **Expected result:** Returns a JSON object containing current Android platform settings (package name, keystore, permissions, etc.). Should succeed.
- **Notes:** 

#### Scenario 6: Happy path — get settings for 'web'
- **Description:** Retrieve platform settings for Web/HTML5.
- **Params:** `{ "platform": "web" }`
- **Expected result:** Returns a JSON object containing current Web platform settings (canvas resize, threading, PWA, etc.). Should succeed.
- **Notes:** 

#### Scenario 7: Edge case — unknown platform string
- **Description:** Query settings for a platform that doesn't exist or is not supported by Godot.
- **Params:** `{ "platform": "xbox" }`
- **Expected result:** Zod validation passes (any string). Godot handler may return an error (platform not found) or return empty/default settings.
- **Notes:** The handler behavior depends on how Godot responds to unrecognized platforms.

#### Scenario 8: Edge case — empty string for platform
- **Description:** Call with an empty string as the platform name.
- **Params:** `{ "platform": "" }`
- **Expected result:** Zod validation passes (`z.string()` accepts empty strings). Godot handler should reject or return an error for unrecognized platform.
- **Notes:** Tests boundary condition.

#### Scenario 9: Edge case — platform name with uppercase
- **Description:** Call with platform name in uppercase (different casing than examples).
- **Params:** `{ "platform": "ANDROID" }`
- **Expected result:** Zod validation passes. Behavior depends on whether the Godot handler normalizes platform names to lowercase.
- **Notes:** Tests case sensitivity of platform name resolution.

#### Scenario 10: Edge case — platform name with mixed case
- **Description:** Call with mixed-case platform name.
- **Params:** `{ "platform": "Web" }`
- **Expected result:** Zod validation passes. Godot handler behavior is platform-name-dependent.
- **Notes:** 

#### Scenario 11: Missing required parameter — platform
- **Description:** Call without the `platform` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `platform` is required.
- **Notes:** 

#### Scenario 12: Invalid type for platform (non-string)
- **Description:** Call with `platform` as a number.
- **Params:** `{ "platform": 42 }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** Type validation.

#### Scenario 13: Invalid type for platform (boolean)
- **Description:** Call with `platform` as a boolean.
- **Params:** `{ "platform": true }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** 

#### Scenario 14: Invalid type for platform (object)
- **Description:** Call with `platform` as an object.
- **Params:** `{ "platform": { "name": "android" } }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** 

#### Scenario 15: Invalid type for platform (array)
- **Description:** Call with `platform` as an array.
- **Params:** `{ "platform": ["ios", "android"] }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** 

#### Scenario 16: Edge case — very long platform name
- **Description:** Call with an extremely long platform name string.
- **Params:** `{ "platform": "a".repeat(5000) }`
- **Expected result:** Zod validation passes. Godot handler should reject the non-existent platform.
- **Notes:** Tests robustness against oversized input.

#### Scenario 17: Edge case — platform name with special characters
- **Description:** Call with a platform name containing quotes, slashes, etc.
- **Params:** `{ "platform": "inject'; DROP TABLE settings;--" }`
- **Expected result:** Zod validation passes. Godot handler should safely handle without issues (no SQL involved).
- **Notes:** Input sanitization safety test.

#### Scenario 18: Edge case — platform name with spaces
- **Description:** Call with platform name containing spaces.
- **Params:** `{ "platform": "windows desktop" }`
- **Expected result:** Zod validation passes. Godot handler behavior depends on its internal platform string matching.
- **Notes:** 

#### Scenario 19: Edge case — platform name with trailing whitespace
- **Description:** Call with platform name that has leading/trailing whitespace.
- **Params:** `{ "platform": "  ios  " }`
- **Expected result:** Zod validation passes (raw string). Godot handler may trim whitespace or reject.
- **Notes:** Tests whitespace handling.

#### Scenario 20: Edge case — call with extra unknown params
- **Description:** Pass additional unknown parameters to the tool.
- **Params:** `{ "platform": "android", "version": "4.0", "config": {} }`
- **Expected result:** Zod validation passes (extra fields ignored). Should behave identically to Scenario 5.
- **Notes:** Tests that unknown fields don't break the call.

---

## Tool: configure_ios

### Schema

```typescript
{
  description: 'Configure iOS-specific project settings including bundle ID, team ID, and code signing',
  inputSchema: {
    settings: z
      .object({
        bundle_id: z.string().optional().describe('iOS bundle identifier (e.g. com.company.game)'),
        team_id: z.string().optional().describe('Apple Developer Team ID'),
        signing: OptionalProperties.describe('Code signing configuration'),
      })
      .describe('iOS settings to configure'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'configure_ios', args as Record<string, unknown>)
```

### Tool Behavior
Configures iOS-specific project settings in the Godot project. All sub-fields within `settings` are optional, allowing partial configuration updates. The `signing` field accepts an arbitrary key-value record for code signing configuration. The tool modifies the project's export settings for the iOS platform.

### Test Scenarios

#### Scenario 1: Happy path — configure bundle_id only
- **Description:** Set only the iOS bundle identifier.
- **Params:** `{ "settings": { "bundle_id": "com.mycompany.mygame" } }`
- **Expected result:** The iOS bundle identifier is updated in the project settings. Returns success. Subsequent calls to `get_platform_settings` with `platform: "ios"` should reflect the new bundle ID.
- **Notes:** Standard reverse-domain notation for bundle IDs.

#### Scenario 2: Happy path — configure team_id only
- **Description:** Set only the Apple Developer Team ID.
- **Params:** `{ "settings": { "team_id": "ABCDEF1234" } }`
- **Expected result:** The iOS team ID is updated. Returns success.
- **Notes:** Team IDs are 10-character alphanumeric strings.

#### Scenario 3: Happy path — configure signing only
- **Description:** Set only the code signing configuration.
- **Params:** `{ "settings": { "signing": { "automatic": true, "provisioning_profile": "MyProfile" } } }`
- **Expected result:** The signing configuration is updated. Returns success.
- **Notes:** The `signing` field is `OptionalProperties` which is `z.record(z.unknown()).optional()` — accepts any key-value pairs.

#### Scenario 4: Happy path — configure signing with various value types
- **Description:** Set signing with boolean, string, and numeric values.
- **Params:** `{ "settings": { "signing": { "enabled": true, "profile_name": "release_profile", "timeout_seconds": 300, "options": { "nested": true } } } }`
- **Expected result:** Zod validation passes (record of unknown values). The Godot handler should process the signing configuration. Returns success.
- **Notes:** Tests that `OptionalProperties` (record of unknown) accepts mixed types.

#### Scenario 5: Happy path — configure bundle_id and team_id together
- **Description:** Set both bundle ID and team ID simultaneously.
- **Params:** `{ "settings": { "bundle_id": "com.mycompany.mygame", "team_id": "ABCDEF1234" } }`
- **Expected result:** Both settings are updated. Returns success.
- **Notes:** Tests multi-field configuration in one call.

#### Scenario 6: Happy path — full configuration (all fields)
- **Description:** Set all three iOS settings at once.
- **Params:** `{ "settings": { "bundle_id": "com.mycompany.mygame", "team_id": "ABCDEF1234", "signing": { "automatic": false, "certificate": "iPhone Developer", "provisioning": "MyGame_Dev" } } }`
- **Expected result:** All three settings are updated. Returns success.
- **Notes:** Tests the complete configuration path.

#### Scenario 7: Happy path — empty settings object
- **Description:** Call with an empty settings object (all fields omitted).
- **Params:** `{ "settings": {} }`
- **Expected result:** Zod validation passes — all sub-fields are optional. The Godot handler may accept a no-op call or report that nothing was configured.
- **Notes:** Since all sub-fields are optional, an empty object is valid at the Zod level.

#### Scenario 8: Edge case — empty string for bundle_id
- **Description:** Set bundle_id to an empty string.
- **Params:** `{ "settings": { "bundle_id": "" } }`
- **Expected result:** Zod validation passes (optional string accepts empty). The Godot handler should reject or warn about an empty bundle identifier.
- **Notes:** An empty bundle ID is typically invalid for iOS.

#### Scenario 9: Edge case — empty string for team_id
- **Description:** Set team_id to an empty string.
- **Params:** `{ "settings": { "team_id": "" } }`
- **Expected result:** Zod validation passes. The Godot handler may reject or warn about an invalid team ID.
- **Notes:** 

#### Scenario 10: Edge case — signing as empty object
- **Description:** Set signing to an empty object.
- **Params:** `{ "settings": { "signing": {} } }`
- **Expected result:** Zod validation passes. The Godot handler should accept an empty signing configuration or treat it as a no-op.
- **Notes:** 

#### Scenario 11: Edge case — signing as null
- **Description:** Set signing to `null`.
- **Params:** `{ "settings": { "signing": null } }`
- **Expected result:** Zod behavior: `z.record(z.unknown()).optional()` — if `null` is passed, it depends on whether Zod's optional treats `null` as "absent" or "invalid type for record". Likely a Zod validation error because `null` is not a valid record.
- **Notes:** This is a boundary condition for the `OptionalProperties` type. Document the actual Zod behavior.

#### Scenario 12: Edge case — bundle_id with special characters
- **Description:** Set bundle_id containing characters not valid in iOS bundle IDs.
- **Params:** `{ "settings": { "bundle_id": "com.company.game with spaces!" } }`
- **Expected result:** Zod validation passes (any string). The Godot handler may reject or sanitize the invalid bundle ID.
- **Notes:** iOS bundle IDs have specific format requirements (reverse-domain, alphanumeric + dots + hyphens).

#### Scenario 13: Edge case — bundle_id with path traversal characters
- **Description:** Set bundle_id with directory traversal characters.
- **Params:** `{ "settings": { "bundle_id": "../../etc/malicious" } }`
- **Expected result:** Zod validation passes. The Godot handler should sanitize the input. No filesystem access should occur.
- **Notes:** Security test — bundle IDs are not used as filesystem paths, but validate safe handling.

#### Scenario 14: Missing required parameter — settings
- **Description:** Call without the `settings` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `settings` (the outer object) is required.
- **Notes:** Even though all sub-fields are optional, the `settings` wrapper object itself is required.

#### Scenario 15: Invalid type for settings (non-object)
- **Description:** Call with `settings` as a string.
- **Params:** `{ "settings": "bundle_id=com.foo" }`
- **Expected result:** Zod validation error — expected object.
- **Notes:** Type validation.

#### Scenario 16: Invalid type for settings (array)
- **Description:** Call with `settings` as an array.
- **Params:** `{ "settings": [{ "bundle_id": "com.foo" }] }`
- **Expected result:** Zod validation error — expected object, not array.
- **Notes:** 

#### Scenario 17: Invalid type for settings (boolean)
- **Description:** Call with `settings` as a boolean.
- **Params:** `{ "settings": true }`
- **Expected result:** Zod validation error — expected object.
- **Notes:** 

#### Scenario 18: Invalid type for bundle_id (non-string)
- **Description:** Set `bundle_id` as a number.
- **Params:** `{ "settings": { "bundle_id": 12345 } }`
- **Expected result:** Zod validation error — expected string for `bundle_id`.
- **Notes:** 

#### Scenario 19: Invalid type for team_id (non-string)
- **Description:** Set `team_id` as a boolean.
- **Params:** `{ "settings": { "team_id": false } }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** 

#### Scenario 20: Invalid type for signing (non-object)
- **Description:** Set `signing` as a string.
- **Params:** `{ "settings": { "signing": "automatic" } }`
- **Expected result:** Zod validation error — `z.record()` expects an object.
- **Notes:** 

#### Scenario 21: Invalid type for signing (array)
- **Description:** Set `signing` as an array.
- **Params:** `{ "settings": { "signing": ["automatic"] } }`
- **Expected result:** Zod validation error — `z.record()` expects an object, not array.
- **Notes:** 

#### Scenario 22: Edge case — call with extra unknown params at settings level
- **Description:** Pass unknown sub-fields inside the settings object.
- **Params:** `{ "settings": { "bundle_id": "com.foo", "extra_field": "should be ignored", "nested_obj": { "key": "val" } } }`
- **Expected result:** Zod validation passes — `z.object()` with known optional fields ignores extras by default. The handler receives only `bundle_id`.
- **Notes:** Tests that unexpected fields within settings are silently dropped.

#### Scenario 23: Edge case — call with extra unknown params at top level
- **Description:** Pass additional unknown parameters alongside `settings`.
- **Params:** `{ "settings": { "bundle_id": "com.foo" }, "platform": "ios", "force": true }`
- **Expected result:** Zod validation passes. Extra top-level params are ignored. Should behave like Scenario 1.
- **Notes:** 

#### Scenario 24: Edge case — very long string values
- **Description:** Set bundle_id and team_id to extremely long strings.
- **Params:** `{ "settings": { "bundle_id": "a".repeat(10000), "team_id": "b".repeat(10000) } }`
- **Expected result:** Zod validation passes. The Godot handler should reject or truncate oversized values.
- **Notes:** Tests robustness against oversized input.

#### Scenario 25: Edge case — settings is null
- **Description:** Call with `settings` explicitly set to `null`.
- **Params:** `{ "settings": null }`
- **Expected result:** Zod validation error — `z.object()` requires an object, not null.
- **Notes:** 

#### Scenario 26: Edge case — configure ios, then read back via get_platform_settings
- **Description:** Configure iOS settings, then verify they persist by reading them back.
- **Params:** 
  1. `configure_ios({ "settings": { "bundle_id": "com.test.verify", "team_id": "TEAM123456" } })`
  2. `get_platform_settings({ "platform": "ios" })`
- **Expected result:** The returned iOS settings should include `bundle_id: "com.test.verify"` and `team_id: "TEAM123456"`.
- **Notes:** Cross-tool integration test. Verifies that configure_ios persists changes.

---

## Tool: configure_android

### Schema

```typescript
{
  description: 'Configure Android-specific project settings including package name, keystore, and permissions',
  inputSchema: {
    settings: z
      .object({
        package_name: z.string().optional().describe('Android package name (e.g. com.company.game)'),
        keystore: OptionalProperties.describe('Keystore configuration for signing'),
        permissions: z.array(z.string()).optional().describe('Android permissions to declare'),
      })
      .describe('Android settings to configure'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'configure_android', args as Record<string, unknown>)
```

### Tool Behavior
Configures Android-specific project settings in the Godot project. All sub-fields within `settings` are optional. The `permissions` field accepts a string array of Android permission names (e.g., `android.permission.INTERNET`). The `keystore` field accepts arbitrary key-value pairs for keystore/signing configuration.

### Test Scenarios

#### Scenario 1: Happy path — configure package_name only
- **Description:** Set only the Android package name.
- **Params:** `{ "settings": { "package_name": "com.mycompany.mygame" } }`
- **Expected result:** The Android package name is updated. Returns success.
- **Notes:** Standard reverse-domain package name format.

#### Scenario 2: Happy path — configure permissions only (single permission)
- **Description:** Set a single Android permission.
- **Params:** `{ "settings": { "permissions": ["android.permission.INTERNET"] } }`
- **Expected result:** The INTERNET permission is added to the Android manifest configuration. Returns success.
- **Notes:** 

#### Scenario 3: Happy path — configure permissions only (multiple permissions)
- **Description:** Set multiple Android permissions in one call.
- **Params:** `{ "settings": { "permissions": ["android.permission.INTERNET", "android.permission.ACCESS_NETWORK_STATE", "android.permission.VIBRATE", "android.permission.READ_EXTERNAL_STORAGE", "android.permission.WRITE_EXTERNAL_STORAGE"] } }`
- **Expected result:** All specified permissions are added. Returns success.
- **Notes:** Tests array handling with multiple elements.

#### Scenario 4: Happy path — configure permissions with an empty array
- **Description:** Set an empty permissions array.
- **Params:** `{ "settings": { "permissions": [] } }`
- **Expected result:** Zod validation passes. The Godot handler should clear the permission list or treat it as a no-op.
- **Notes:** An empty array is a valid `z.array(z.string())` value.

#### Scenario 5: Happy path — configure keystore only
- **Description:** Set only the keystore signing configuration.
- **Params:** `{ "settings": { "keystore": { "keystore_path": "res://android.keystore", "keystore_password": "mypassword", "keystore_alias": "mygame" } } }`
- **Expected result:** The keystore configuration is updated. Returns success.
- **Notes:** The `keystore` field is `OptionalProperties` — accepts any key-value pairs.

#### Scenario 6: Happy path — configure keystore with various value types
- **Description:** Set keystore with string, boolean, and numeric values.
- **Params:** `{ "settings": { "keystore": { "release": true, "store_password": "secure123", "key_alias": "release_key", "key_password": "keypass456", "use_custom_build": false, "min_sdk_version": 21 } } }`
- **Expected result:** Zod validation passes. The Godot handler processes the keystore configuration.
- **Notes:** Tests mixed types in OptionalProperties.

#### Scenario 7: Happy path — full configuration (all fields)
- **Description:** Set all three Android settings at once.
- **Params:** `{ "settings": { "package_name": "com.mycompany.mygame", "keystore": { "keystore_path": "res://release.keystore", "keystore_password": "pass123" }, "permissions": ["android.permission.INTERNET", "android.permission.VIBRATE"] } }`
- **Expected result:** All settings are updated. Returns success.
- **Notes:** 

#### Scenario 8: Happy path — configure package_name and permissions together
- **Description:** Set package name and permissions simultaneously.
- **Params:** `{ "settings": { "package_name": "com.mycompany.mygame", "permissions": ["android.permission.INTERNET", "android.permission.CAMERA"] } }`
- **Expected result:** Both settings are updated. Returns success.
- **Notes:** 

#### Scenario 9: Happy path — empty settings object
- **Description:** Call with an empty settings object.
- **Params:** `{ "settings": {} }`
- **Expected result:** Zod validation passes. The Godot handler may accept a no-op call or report nothing was configured.
- **Notes:** All sub-fields are optional; empty object is valid.

#### Scenario 10: Edge case — empty string for package_name
- **Description:** Set package_name to an empty string.
- **Params:** `{ "settings": { "package_name": "" } }`
- **Expected result:** Zod validation passes. The Godot handler should reject or warn about an empty package name.
- **Notes:** An empty package name is invalid for Android.

#### Scenario 11: Edge case — permissions with an empty string element
- **Description:** Include an empty string in the permissions array.
- **Params:** `{ "settings": { "permissions": ["android.permission.INTERNET", ""] } }`
- **Expected result:** Zod validation passes (empty string is a valid string). The Godot handler should reject or ignore the empty permission.
- **Notes:** 

#### Scenario 12: Edge case — permissions with invalid permission names
- **Description:** Include non-standard permission strings.
- **Params:** `{ "settings": { "permissions": ["not.a.real.permission", "fake_permission"] } }`
- **Expected result:** Zod validation passes. The Godot handler may warn about unrecognized permissions but should still add them to the manifest.
- **Notes:** Godot may not validate permission names — they are passed through to the Android build.

#### Scenario 13: Edge case — keystore as empty object
- **Description:** Set keystore to an empty object.
- **Params:** `{ "settings": { "keystore": {} } }`
- **Expected result:** Zod validation passes. The Godot handler should accept or treat as no-op.
- **Notes:** 

#### Scenario 14: Edge case — keystore as null
- **Description:** Set keystore to `null`.
- **Params:** `{ "settings": { "keystore": null } }`
- **Expected result:** Likely a Zod validation error — `z.record()` expects an object, not null.
- **Notes:** Boundary condition for `OptionalProperties`.

#### Scenario 15: Missing required parameter — settings
- **Description:** Call without the `settings` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `settings` is required.
- **Notes:** 

#### Scenario 16: Invalid type for settings (non-object)
- **Description:** Call with `settings` as a string.
- **Params:** `{ "settings": "package_name=com.foo" }`
- **Expected result:** Zod validation error — expected object.
- **Notes:** 

#### Scenario 17: Invalid type for settings (array)
- **Description:** Call with `settings` as an array.
- **Params:** `{ "settings": [{ "package_name": "com.foo" }] }`
- **Expected result:** Zod validation error — expected object, not array.
- **Notes:** 

#### Scenario 18: Invalid type for settings (boolean)
- **Description:** Call with `settings` as a boolean.
- **Params:** `{ "settings": false }`
- **Expected result:** Zod validation error — expected object.
- **Notes:** 

#### Scenario 19: Invalid type for package_name (non-string)
- **Description:** Set `package_name` as a number.
- **Params:** `{ "settings": { "package_name": 123456 } }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** 

#### Scenario 20: Invalid type for package_name (boolean)
- **Description:** Set `package_name` as a boolean.
- **Params:** `{ "settings": { "package_name": true } }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** 

#### Scenario 21: Invalid type for permissions (non-array)
- **Description:** Set `permissions` as a string instead of an array.
- **Params:** `{ "settings": { "permissions": "android.permission.INTERNET" } }`
- **Expected result:** Zod validation error — expected array.
- **Notes:** Even a single permission must be wrapped in an array.

#### Scenario 22: Invalid type for permissions (object)
- **Description:** Set `permissions` as an object.
- **Params:** `{ "settings": { "permissions": { "0": "android.permission.INTERNET" } } }`
- **Expected result:** Zod validation error — expected array.
- **Notes:** 

#### Scenario 23: Invalid type for permissions element (non-string)
- **Description:** Include a number in the permissions array.
- **Params:** `{ "settings": { "permissions": ["android.permission.INTERNET", 42] } }`
- **Expected result:** Zod validation error — expected array of strings.
- **Notes:** 

#### Scenario 24: Invalid type for permissions element (boolean)
- **Description:** Include a boolean in the permissions array.
- **Params:** `{ "settings": { "permissions": [true, false] } }`
- **Expected result:** Zod validation error — expected array of strings.
- **Notes:** 

#### Scenario 25: Invalid type for keystore (non-object)
- **Description:** Set `keystore` as a string.
- **Params:** `{ "settings": { "keystore": "path/to/keystore" } }`
- **Expected result:** Zod validation error — `z.record()` expects an object.
- **Notes:** 

#### Scenario 26: Invalid type for keystore (array)
- **Description:** Set `keystore` as an array.
- **Params:** `{ "settings": { "keystore": ["key", "value"] } }`
- **Expected result:** Zod validation error — `z.record()` expects an object, not array.
- **Notes:** 

#### Scenario 27: Edge case — call with extra unknown params at settings level
- **Description:** Pass unknown sub-fields inside settings.
- **Params:** `{ "settings": { "package_name": "com.foo", "extra_config": "should be ignored", "nested": { "key": "val" } } }`
- **Expected result:** Zod validation passes — extra fields within `z.object()` are silently dropped.
- **Notes:** 

#### Scenario 28: Edge case — call with extra unknown params at top level
- **Description:** Pass additional unknown parameters alongside `settings`.
- **Params:** `{ "settings": { "package_name": "com.foo" }, "platform": "android", "config_name": "release" }`
- **Expected result:** Zod validation passes. Extra top-level params are ignored.
- **Notes:** 

#### Scenario 29: Edge case — very long string values
- **Description:** Set package_name and permissions with extremely long strings.
- **Params:** `{ "settings": { "package_name": "a".repeat(10000), "permissions": ["b".repeat(10000)] } }`
- **Expected result:** Zod validation passes. The Godot handler should reject or truncate oversized values.
- **Notes:** 

#### Scenario 30: Edge case — permissions array with many elements (stress)
- **Description:** Set a very large permissions array.
- **Params:** `{ "settings": { "permissions": Array(500).fill("android.permission.INTERNET") } }`
- **Expected result:** Zod validation passes. The Godot handler should handle the large array or error gracefully.
- **Notes:** Tests performance/stress with large arrays.

#### Scenario 31: Edge case — configure android, then read back via get_platform_settings
- **Description:** Configure Android settings, then verify via `get_platform_settings`.
- **Params:** 
  1. `configure_android({ "settings": { "package_name": "com.test.verify", "permissions": ["android.permission.INTERNET"] } })`
  2. `get_platform_settings({ "platform": "android" })`
- **Expected result:** The returned Android settings should include the updated package name and permissions.
- **Notes:** Cross-tool integration test.

---

## Tool: configure_web

### Schema

```typescript
{
  description: 'Configure web/HTML5 export settings including canvas resize, threading, and PWA support',
  inputSchema: {
    settings: z
      .object({
        canvas_resize: z.boolean().optional().describe('Enable automatic canvas resizing'),
        threading: z.boolean().optional().describe('Enable SharedArrayBuffer threading support'),
        pwa: z.boolean().optional().describe('Enable Progressive Web App support'),
      })
      .describe('Web platform settings to configure'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'configure_web', args as Record<string, unknown>)
```

### Tool Behavior
Configures Web/HTML5 platform settings for the Godot project. All three boolean sub-fields (`canvas_resize`, `threading`, `pwa`) are optional, allowing partial configuration. Each toggle controls a specific HTML5 export feature.

### Test Scenarios

#### Scenario 1: Happy path — configure canvas_resize only (true)
- **Description:** Enable automatic canvas resizing.
- **Params:** `{ "settings": { "canvas_resize": true } }`
- **Expected result:** Canvas resize setting is enabled. Returns success.
- **Notes:** 

#### Scenario 2: Happy path — configure canvas_resize only (false)
- **Description:** Disable automatic canvas resizing.
- **Params:** `{ "settings": { "canvas_resize": false } }`
- **Expected result:** Canvas resize setting is disabled. Returns success.
- **Notes:** Tests that boolean `false` is accepted and handled correctly.

#### Scenario 3: Happy path — configure threading only (true)
- **Description:** Enable SharedArrayBuffer threading support.
- **Params:** `{ "settings": { "threading": true } }`
- **Expected result:** Threading support is enabled. Returns success.
- **Notes:** SharedArrayBuffer requires specific HTTP headers (COOP/COEP) on the web server.

#### Scenario 4: Happy path — configure threading only (false)
- **Description:** Disable SharedArrayBuffer threading.
- **Params:** `{ "settings": { "threading": false } }`
- **Expected result:** Threading support is disabled. Returns success.
- **Notes:** 

#### Scenario 5: Happy path — configure pwa only (true)
- **Description:** Enable Progressive Web App support.
- **Params:** `{ "settings": { "pwa": true } }`
- **Expected result:** PWA support is enabled. Returns success.
- **Notes:** PWA support adds a service worker and manifest to the web export.

#### Scenario 6: Happy path — configure pwa only (false)
- **Description:** Disable Progressive Web App support.
- **Params:** `{ "settings": { "pwa": false } }`
- **Expected result:** PWA support is disabled. Returns success.
- **Notes:** 

#### Scenario 7: Happy path — configure two fields (canvas_resize + threading)
- **Description:** Enable canvas resize and threading together.
- **Params:** `{ "settings": { "canvas_resize": true, "threading": true } }`
- **Expected result:** Both settings are enabled. Returns success.
- **Notes:** 

#### Scenario 8: Happy path — configure two fields (threading + pwa)
- **Description:** Enable threading and PWA together.
- **Params:** `{ "settings": { "threading": true, "pwa": true } }`
- **Expected result:** Both settings are enabled. Returns success.
- **Notes:** 

#### Scenario 9: Happy path — full configuration (all three fields)
- **Description:** Enable all three web settings.
- **Params:** `{ "settings": { "canvas_resize": true, "threading": true, "pwa": true } }`
- **Expected result:** All web platform settings are enabled. Returns success.
- **Notes:** 

#### Scenario 10: Happy path — full configuration (all false)
- **Description:** Disable all three web settings.
- **Params:** `{ "settings": { "canvas_resize": false, "threading": false, "pwa": false } }`
- **Expected result:** All web platform settings are disabled. Returns success.
- **Notes:** Tests that explicitly setting all booleans to false works.

#### Scenario 11: Happy path — mixed booleans
- **Description:** Set different boolean values for each field.
- **Params:** `{ "settings": { "canvas_resize": true, "threading": false, "pwa": true } }`
- **Expected result:** Each setting is applied with its respective boolean value. Returns success.
- **Notes:** 

#### Scenario 12: Happy path — empty settings object
- **Description:** Call with an empty settings object.
- **Params:** `{ "settings": {} }`
- **Expected result:** Zod validation passes. The Godot handler may accept a no-op call.
- **Notes:** All sub-fields are optional; empty object is valid.

#### Scenario 13: Missing required parameter — settings
- **Description:** Call without the `settings` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `settings` is required.
- **Notes:** 

#### Scenario 14: Invalid type for settings (non-object)
- **Description:** Call with `settings` as a string.
- **Params:** `{ "settings": "canvas_resize=true" }`
- **Expected result:** Zod validation error — expected object.
- **Notes:** 

#### Scenario 15: Invalid type for settings (array)
- **Description:** Call with `settings` as an array.
- **Params:** `{ "settings": [true, false, true] }`
- **Expected result:** Zod validation error — expected object.
- **Notes:** 

#### Scenario 16: Invalid type for settings (boolean)
- **Description:** Call with `settings` as a boolean.
- **Params:** `{ "settings": true }`
- **Expected result:** Zod validation error — expected object.
- **Notes:** 

#### Scenario 17: Invalid type for canvas_resize (non-boolean)
- **Description:** Set `canvas_resize` as a string.
- **Params:** `{ "settings": { "canvas_resize": "true" } }`
- **Expected result:** Zod validation error — expected boolean. The string `"true"` is not coerced to boolean.
- **Notes:** Zod's `z.boolean()` is strict; string "true"/"false" are not accepted.

#### Scenario 18: Invalid type for canvas_resize (number)
- **Description:** Set `canvas_resize` as a number.
- **Params:** `{ "settings": { "canvas_resize": 1 } }`
- **Expected result:** Zod validation error — expected boolean.
- **Notes:** Zod is strict about types; `1` is not coerced to `true`.

#### Scenario 19: Invalid type for threading (non-boolean)
- **Description:** Set `threading` as a string.
- **Params:** `{ "settings": { "threading": "yes" } }`
- **Expected result:** Zod validation error — expected boolean.
- **Notes:** 

#### Scenario 20: Invalid type for threading (array)
- **Description:** Set `threading` as an array.
- **Params:** `{ "settings": { "threading": [] } }`
- **Expected result:** Zod validation error — expected boolean.
- **Notes:** 

#### Scenario 21: Invalid type for pwa (non-boolean)
- **Description:** Set `pwa` as a number.
- **Params:** `{ "settings": { "pwa": 0 } }`
- **Expected result:** Zod validation error — expected boolean.
- **Notes:** `0` is not falsy-coerced to boolean.

#### Scenario 22: Invalid type for pwa (object)
- **Description:** Set `pwa` as an object.
- **Params:** `{ "settings": { "pwa": { "enabled": true } } }`
- **Expected result:** Zod validation error — expected boolean.
- **Notes:** 

#### Scenario 23: Invalid type for pwa (null)
- **Description:** Set `pwa` to `null`.
- **Params:** `{ "settings": { "pwa": null } }`
- **Expected result:** Zod validation error — expected boolean, not null.
- **Notes:** 

#### Scenario 24: Edge case — call with extra unknown params at settings level
- **Description:** Pass unknown sub-fields inside settings.
- **Params:** `{ "settings": { "canvas_resize": true, "extra_boolean": false, "nested_config": { "key": true } } }`
- **Expected result:** Zod validation passes — extra fields in `z.object()` are ignored. Only `canvas_resize` is processed.
- **Notes:** 

#### Scenario 25: Edge case — call with extra unknown params at top level
- **Description:** Pass additional unknown parameters alongside `settings`.
- **Params:** `{ "settings": { "pwa": true }, "platform": "web", "use_threads": true }`
- **Expected result:** Zod validation passes. Extra top-level params are ignored.
- **Notes:** 

#### Scenario 26: Edge case — configure web, then read back via get_platform_settings
- **Description:** Configure web settings, then verify via `get_platform_settings`.
- **Params:** 
  1. `configure_web({ "settings": { "canvas_resize": true, "threading": false, "pwa": true } })`
  2. `get_platform_settings({ "platform": "web" })`
- **Expected result:** The returned web settings should reflect the configured values.
- **Notes:** Cross-tool integration test.

---

## Tool: get_platform_capabilities

### Schema

```typescript
{
  description: 'Get the available features and capabilities for a specific platform',
  inputSchema: {
    platform: z.string().describe('Platform name to query capabilities for'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'get_platform_capabilities', args as Record<string, unknown>)
```

### Tool Behavior
Retrieves the available features and capabilities for a given target platform. This includes information about supported rendering backends, input methods, file system access, networking features, and other platform-specific capabilities that affect what project settings and export options are available.

### Test Scenarios

#### Scenario 1: Happy path — query capabilities for 'windows'
- **Description:** Get capabilities for Windows Desktop platform.
- **Params:** `{ "platform": "windows" }`
- **Expected result:** Returns a JSON object listing Windows platform capabilities (e.g., Direct3D support, window management, file access, etc.). Should not error.
- **Notes:** 

#### Scenario 2: Happy path — query capabilities for 'linux'
- **Description:** Get capabilities for Linux/X11 platform.
- **Params:** `{ "platform": "linux" }`
- **Expected result:** Returns a JSON object listing Linux platform capabilities. Should succeed.
- **Notes:** 

#### Scenario 3: Happy path — query capabilities for 'macos'
- **Description:** Get capabilities for macOS platform.
- **Params:** `{ "platform": "macos" }`
- **Expected result:** Returns a JSON object listing macOS platform capabilities (Metal support, sandboxing, etc.). Should succeed.
- **Notes:** 

#### Scenario 4: Happy path — query capabilities for 'ios'
- **Description:** Get capabilities for iOS platform.
- **Params:** `{ "platform": "ios" }`
- **Expected result:** Returns a JSON object listing iOS capabilities (Metal, touch input, ARKit, etc.). Should succeed.
- **Notes:** Results are informational — the tool only queries capabilities, it does not require iOS build tools to be installed.

#### Scenario 5: Happy path — query capabilities for 'android'
- **Description:** Get capabilities for Android platform.
- **Params:** `{ "platform": "android" }`
- **Expected result:** Returns a JSON object listing Android capabilities (OpenGL ES, Vulkan, touch, sensors, etc.). Should succeed.
- **Notes:** 

#### Scenario 6: Happy path — query capabilities for 'web'
- **Description:** Get capabilities for Web/HTML5 platform.
- **Params:** `{ "platform": "web" }`
- **Expected result:** Returns a JSON object listing Web platform capabilities (WebGL, WebAssembly, threading, audio, etc.). Should succeed.
- **Notes:** 

#### Scenario 7: Edge case — unknown platform
- **Description:** Query capabilities for a non-existent platform.
- **Params:** `{ "platform": "playstation" }`
- **Expected result:** Zod validation passes. The Godot handler should return an error or indicate the platform is not recognized.
- **Notes:** 

#### Scenario 8: Edge case — empty string for platform
- **Description:** Call with an empty platform string.
- **Params:** `{ "platform": "" }`
- **Expected result:** Zod validation passes. The Godot handler should reject or return an error for unrecognized platform.
- **Notes:** 

#### Scenario 9: Edge case — mixed case platform name
- **Description:** Call with uppercase platform name.
- **Params:** `{ "platform": "ANDROID" }`
- **Expected result:** Zod validation passes. Behavior depends on the Godot handler's platform name normalization.
- **Notes:** 

#### Scenario 10: Missing required parameter — platform
- **Description:** Call without the `platform` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `platform` is required.
- **Notes:** 

#### Scenario 11: Invalid type for platform (non-string)
- **Description:** Call with `platform` as a number.
- **Params:** `{ "platform": 1 }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** 

#### Scenario 12: Invalid type for platform (boolean)
- **Description:** Call with `platform` as a boolean.
- **Params:** `{ "platform": false }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** 

#### Scenario 13: Invalid type for platform (object)
- **Description:** Call with `platform` as an object.
- **Params:** `{ "platform": { "name": "web" } }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** 

#### Scenario 14: Invalid type for platform (array)
- **Description:** Call with `platform` as an array.
- **Params:** `{ "platform": ["windows", "linux"] }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** 

#### Scenario 15: Edge case — very long platform name
- **Description:** Call with an extremely long platform string.
- **Params:** `{ "platform": "a".repeat(5000) }`
- **Expected result:** Zod validation passes. The Godot handler should reject the non-existent platform.
- **Notes:** 

#### Scenario 16: Edge case — platform name with special characters
- **Description:** Call with platform name containing special characters.
- **Params:** `{ "platform": "windows<script>alert(1)</script>" }`
- **Expected result:** Zod validation passes. The Godot handler should safely handle the input.
- **Notes:** Security test for script injection.

#### Scenario 17: Edge case — call with extra unknown params
- **Description:** Pass additional unknown parameters.
- **Params:** `{ "platform": "ios", "detailed": true, "format": "json" }`
- **Expected result:** Zod validation passes. Extra params are ignored. Should behave like Scenario 4.
- **Notes:** 

#### Scenario 18: Edge case — query all example platforms and compare results
- **Description:** Call `get_platform_capabilities` for all six example platforms and compare.
- **Params:** 
  1. `{ "platform": "windows" }`
  2. `{ "platform": "linux" }`
  3. `{ "platform": "macos" }`
  4. `{ "platform": "ios" }`
  5. `{ "platform": "android" }`
  6. `{ "platform": "web" }`
- **Expected result:** Each platform returns distinct capabilities relevant to that platform. Desktop platforms share common features. Mobile platforms include touch and sensor capabilities. Web includes WebGL/WebAssembly features.
- **Notes:** Integration test — validates that different platforms return different (appropriate) capability sets.

---

## Tool: validate_platform_build

### Schema

```typescript
{
  description: 'Validate the project for building on a specific platform, checking for issues',
  inputSchema: {
    platform: z.string().describe('Platform to validate the build for'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'validate_platform_build', args as Record<string, unknown>)
```

### Tool Behavior
Validates the project configuration for building on a specific target platform. Checks for missing dependencies, incompatible settings, unsupported features, missing export templates, and other issues that would prevent a successful build for the given platform. Returns a list of issues (errors, warnings) found.

### Test Scenarios

#### Scenario 1: Happy path — validate build for 'windows'
- **Description:** Validate project build readiness for Windows Desktop.
- **Params:** `{ "platform": "windows" }`
- **Expected result:** Returns a validation report listing any issues found for Windows build. On a clean project, may return no errors but possibly warnings about missing icons or export templates.
- **Notes:** 

#### Scenario 2: Happy path — validate build for 'linux'
- **Description:** Validate project build readiness for Linux.
- **Params:** `{ "platform": "linux" }`
- **Expected result:** Returns a validation report for Linux build readiness. Should succeed even if Linux export templates are not installed (template availability is a separate concern).
- **Notes:** 

#### Scenario 3: Happy path — validate build for 'macos'
- **Description:** Validate project build readiness for macOS.
- **Params:** `{ "platform": "macos" }`
- **Expected result:** Returns a validation report for macOS build. On non-macOS hosts, may warn about cross-compilation limitations.
- **Notes:** 

#### Scenario 4: Happy path — validate build for 'ios'
- **Description:** Validate project build readiness for iOS.
- **Params:** `{ "platform": "ios" }`
- **Expected result:** Returns a validation report. May include warnings about missing bundle ID, team ID, provisioning profiles, or cross-compilation issues.
- **Notes:** iOS validation may be strict about required signing configuration.

#### Scenario 5: Happy path — validate build for 'android'
- **Description:** Validate project build readiness for Android.
- **Params:** `{ "platform": "android" }`
- **Expected result:** Returns a validation report. May warn about missing Android SDK, NDK, package name, or keystore.
- **Notes:** Android validation checks for SDK/NDK paths.

#### Scenario 6: Happy path — validate build for 'web'
- **Description:** Validate project build readiness for Web/HTML5.
- **Params:** `{ "platform": "web" }`
- **Expected result:** Returns a validation report for Web build. May warn about threading requirements (COOP/COEP headers), missing icons, or PWA configuration.
- **Notes:** 

#### Scenario 7: Edge case — validate after configuring platform settings
- **Description:** Configure iOS settings, then validate iOS build.
- **Params:** 
  1. `configure_ios({ "settings": { "bundle_id": "com.test.validate" } })`
  2. `validate_platform_build({ "platform": "ios" })`
- **Expected result:** The validation report should reflect the updated bundle ID. Previously missing bundle ID warning should be resolved.
- **Notes:** Cross-tool integration — verifies that configuration changes are picked up by validation.

#### Scenario 8: Edge case — validate before and after android config
- **Description:** Validate Android build before and after configuring package name.
- **Params:** 
  1. `validate_platform_build({ "platform": "android" })` — note initial issues
  2. `configure_android({ "settings": { "package_name": "com.test.validate" } })`
  3. `validate_platform_build({ "platform": "android" })` — check if missing package name warning is resolved
- **Expected result:** The second validation should show fewer issues (or different issues) than the first.
- **Notes:** Tests that validation state changes reflect configuration changes.

#### Scenario 9: Edge case — validate web build after enabling threading
- **Description:** Enable threading for web, then validate.
- **Params:** 
  1. `configure_web({ "settings": { "threading": true } })`
  2. `validate_platform_build({ "platform": "web" })`
- **Expected result:** Validation may include a note/warning about required COOP/COEP headers when threading is enabled.
- **Notes:** Some settings may generate validation warnings even when correctly configured (e.g., server-side requirements).

#### Scenario 10: Edge case — unknown platform
- **Description:** Validate build for a non-existent platform.
- **Params:** `{ "platform": "nintendo_switch" }`
- **Expected result:** Zod validation passes. The Godot handler should return an error (platform not recognized or not supported).
- **Notes:** 

#### Scenario 11: Edge case — empty string for platform
- **Description:** Validate with an empty platform string.
- **Params:** `{ "platform": "" }`
- **Expected result:** Zod validation passes. The Godot handler should reject or return an error.
- **Notes:** 

#### Scenario 12: Missing required parameter — platform
- **Description:** Call without the `platform` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `platform` is required.
- **Notes:** 

#### Scenario 13: Invalid type for platform (non-string)
- **Description:** Call with `platform` as a number.
- **Params:** `{ "platform": 42 }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** 

#### Scenario 14: Invalid type for platform (boolean)
- **Description:** Call with `platform` as a boolean.
- **Params:** `{ "platform": true }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** 

#### Scenario 15: Invalid type for platform (object)
- **Description:** Call with `platform` as an object.
- **Params:** `{ "platform": { "name": "windows" } }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** 

#### Scenario 16: Invalid type for platform (array)
- **Description:** Call with `platform` as an array.
- **Params:** `{ "platform": ["ios"] }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** 

#### Scenario 17: Edge case — very long platform name
- **Description:** Call with an extremely long platform string.
- **Params:** `{ "platform": "x".repeat(5000) }`
- **Expected result:** Zod validation passes. The Godot handler should reject the non-existent platform.
- **Notes:** 

#### Scenario 18: Edge case — call with extra unknown params
- **Description:** Pass additional unknown parameters.
- **Params:** `{ "platform": "android", "strict_mode": true, "output_format": "detailed" }`
- **Expected result:** Zod validation passes. Extra params are ignored. Should behave like Scenario 5.
- **Notes:** 

#### Scenario 19: Edge case — validate all common platforms sequentially
- **Description:** Call `validate_platform_build` for all six example platforms.
- **Params:** 
  1. `{ "platform": "windows" }`
  2. `{ "platform": "linux" }`
  3. `{ "platform": "macos" }`
  4. `{ "platform": "ios" }`
  5. `{ "platform": "android" }`
  6. `{ "platform": "web" }`
- **Expected result:** Each validation call succeeds. Results vary by platform. Desktop platforms typically have fewer issues. Mobile and web platforms may report more warnings (SDK/template availability).
- **Notes:** Integration test — validates different platform checks produce appropriate results.

#### Scenario 20: Edge case — validate with mixed case platform name
- **Description:** Call with mixed-case platform name.
- **Params:** `{ "platform": "Windows" }`
- **Expected result:** Zod validation passes. Behavior depends on the Godot handler's platform name normalization.
- **Notes:** 

---

## Cross-Tool Integration Scenarios

These scenarios test sequences of platform configuration and validation together.

### Scenario I: Full iOS workflow — configure → get settings → validate
- **Steps:**
  1. `get_platform_settings({ "platform": "ios" })` → note initial iOS settings
  2. `configure_ios({ "settings": { "bundle_id": "com.mycompany.integrationtest", "team_id": "TEAM000000", "signing": { "automatic": true } } })` → success
  3. `get_platform_settings({ "platform": "ios" })` → should reflect new bundle_id, team_id, and signing
  4. `validate_platform_build({ "platform": "ios" })` → should show validation results reflecting the new configuration
  5. `get_platform_capabilities({ "platform": "ios" })` → should still show iOS capabilities (unchanged by configuration)
- **Expected result:** Each step succeeds. Configuration changes are reflected in settings reads and validation results.

### Scenario II: Full Android workflow — configure → get settings → validate
- **Steps:**
  1. `get_platform_settings({ "platform": "android" })` → note initial Android settings
  2. `configure_android({ "settings": { "package_name": "com.mycompany.integrationtest", "permissions": ["android.permission.INTERNET", "android.permission.VIBRATE"], "keystore": { "debug": true } } })` → success
  3. `get_platform_settings({ "platform": "android" })` → should reflect new package_name, permissions, and keystore
  4. `validate_platform_build({ "platform": "android" })` → should show validation results
  5. `get_platform_capabilities({ "platform": "android" })` → should still show Android capabilities
- **Expected result:** Each step succeeds.

### Scenario III: Full Web workflow — configure → get settings → validate
- **Steps:**
  1. `get_platform_settings({ "platform": "web" })` → note initial web settings
  2. `configure_web({ "settings": { "canvas_resize": true, "threading": false, "pwa": true } })` → success
  3. `get_platform_settings({ "platform": "web" })` → should reflect new boolean settings
  4. `validate_platform_build({ "platform": "web" })` → should show validation results
  5. `get_platform_capabilities({ "platform": "web" })` → should still show Web capabilities
- **Expected result:** Each step succeeds.

### Scenario IV: Configure all three platforms then validate all three
- **Steps:**
  1. `configure_ios({ "settings": { "bundle_id": "com.test.allplatforms" } })` → success
  2. `configure_android({ "settings": { "package_name": "com.test.allplatforms" } })` → success
  3. `configure_web({ "settings": { "pwa": true } })` → success
  4. `validate_platform_build({ "platform": "ios" })` → report with iOS config
  5. `validate_platform_build({ "platform": "android" })` → report with Android config
  6. `validate_platform_build({ "platform": "web" })` → report with Web config
  7. `get_platform_settings({ "platform": "ios" })` → verify iOS settings preserved
  8. `get_platform_settings({ "platform": "android" })` → verify Android settings preserved
  9. `get_platform_settings({ "platform": "web" })` → verify Web settings preserved
- **Expected result:** All platform configurations coexist independently. Validation reports are platform-specific.

### Scenario V: Cross-platform capabilities comparison
- **Steps:**
  1. `get_platform_capabilities({ "platform": "windows" })`
  2. `get_platform_capabilities({ "platform": "linux" })`
  3. `get_platform_capabilities({ "platform": "macos" })`
  4. `get_platform_capabilities({ "platform": "ios" })`
  5. `get_platform_capabilities({ "platform": "android" })`
  6. `get_platform_capabilities({ "platform": "web" })`
- **Expected result:** Each platform returns a distinct capability set. Desktop platforms share many common capabilities. Mobile platforms include touch, sensor, and mobile-specific features. Web includes browser/WebAssembly-specific features.
- **Notes:** The response structure for each platform should be comparable (same JSON shape, different values).

---

## Notes for Test Executors

1. **Platform configuration is project-scoped:** All `configure_*` tools modify the project's export configuration (typically in `export_presets.cfg` or `project.godot`). Run tests in a dedicated test project to avoid polluting real project settings.

2. **Settings persistence:** Changes made via `configure_ios`, `configure_android`, and `configure_web` should persist across tool calls. Verify with `get_platform_settings` after configuration.

3. **Platform name strings:** The tool descriptions suggest platform names like `'ios'`, `'android'`, `'web'`, `'windows'`, `'linux'`, `'macos'`. These are lowercase strings. Test with exact matches to the documented examples first, then test variations (uppercase, mixed case) to determine the handler's tolerance.

4. **Zod validation vs Godot validation:** The MCP server validates parameter types at the schema level (Zod). The Godot plugin performs additional validation (platform name recognition, bundle ID format, etc.). Both layers should be tested independently.

5. **`OptionalProperties` type:** Both `signing` (in `configure_ios`) and `keystore` (in `configure_android`) use `OptionalProperties` which is `z.record(z.unknown()).optional()`. This accepts any object with arbitrary key-value pairs. Test with various value types (strings, booleans, numbers, nested objects) to verify the Godot handler processes them correctly.

6. **`configure_ios` and `configure_android` have no domain-level validation:** The Zod schemas only validate types, not domain rules (e.g., valid bundle ID format, valid Android package name format). The Godot handler is responsible for any domain-level validation. Document what the handler actually accepts/rejects.

7. **`validate_platform_build` is platform-dependent:** Validation results vary significantly by platform and by what tools/SDKs are installed. Desktop platforms typically validate cleanly. Mobile platforms (iOS, Android) often warn about missing SDK paths or signing configurations. Web may warn about missing templates.

8. **No tool modifies Godot installation files:** All tools operate on project-level settings only. They do not install export templates, SDKs, or modify Godot's installation directory.

9. **`get_platform_capabilities` is read-only:** This tool only queries and returns information. It has no side effects and can be called safely at any time.

10. **Boolean type strictness:** Zod's `z.boolean()` is strict — it does not coerce strings (`"true"`, `"false"`), numbers (`0`, `1`), or any other type. Only `true` and `false` JavaScript booleans are accepted. Test scenarios for `configure_web` explicitly verify this for all three boolean fields.

11. **Empty vs missing sub-fields:** For `configure_ios`, `configure_android`, and `configure_web`, passing an empty `{}` settings object is valid (all sub-fields are optional). The behavior when all sub-object fields are omitted should be tested (no-op, default reset, or error).

12. **Cross-tool consistency:** After configuring settings with a `configure_*` tool, `get_platform_settings` for the same platform should reflect the changes. Similarly, `validate_platform_build` should incorporate the updated configuration in its analysis.

13. **Cleanup:** After tests complete, consider resetting platform settings to their original values or using a fresh test project for each test run to avoid cross-test contamination.
