# Platform Specific Tools — Test Plan

**Source file:** `server/src/tools/platform_specific.ts`  
**Number of tools:** 6  
**Godot bridge commands:** `get_platform_settings`, `configure_ios`, `configure_android`, `configure_web`, `get_platform_capabilities`, `validate_platform_build`

---

## Tool 1: `get_platform_settings`

**Description:** Get platform-specific settings for a target platform  
**Handler:** `callGodot(bridge, 'get_platform_settings', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `platform` | `string` | **Yes** | — | Platform name (e.g. 'ios', 'android', 'web', 'windows', 'linux', 'macos') |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 1 | Get iOS settings | `{"platform": "ios"}` | Valid JSON object with iOS-specific project settings | Core use case. Settings may include bundle ID, team ID, signing info. |
| 2 | Get Android settings | `{"platform": "android"}` | Valid JSON object with Android-specific project settings | Settings may include package name, keystore, permissions. |
| 3 | Get Web/HTML5 settings | `{"platform": "web"}` | Valid JSON object with HTML5 export settings | Settings may include canvas resize, threading, PWA flags. |
| 4 | Get Windows settings | `{"platform": "windows"}` | Valid JSON object with Windows export settings | Desktop platform. |
| 5 | Get Linux settings | `{"platform": "linux"}` | Valid JSON object with Linux export settings | Desktop platform. |
| 6 | Get macOS settings | `{"platform": "macos"}` | Valid JSON object with macOS export settings | Desktop platform. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 7 | Missing required `platform` | `{}` | Zod validation error | `platform` is required. |
| 8 | Empty string platform | `{"platform": ""}` | Passes Zod; Godot may return generic settings or error | `z.string()` accepts empty string. Godot behavior TBD. |
| 9 | Unknown platform name | `{"platform": "playstation"}` | Godot may return empty object or error | Unsupported platform. |
| 10 | Case-variant platform name | `{"platform": "IOS"}` | Godot may reject (case-sensitive) | Platform names are typically lowercase. |
| 11 | Platform as number | `{"platform": 123}` | Zod validation error | `z.string()` rejects numbers. |
| 12 | Platform as boolean | `{"platform": true}` | Zod validation error | `z.string()` rejects booleans. |
| 13 | Platform as null | `{"platform": null}` | Zod validation error | `z.string()` rejects null. |
| 14 | Platform as object | `{"platform": {"name": "ios"}}` | Zod validation error | `z.string()` rejects objects. |
| 15 | Platform as array | `{"platform": ["ios"]}` | Zod validation error | `z.string()` rejects arrays. |
| 16 | Very long platform name | `{"platform": "a".repeat(1000)}` | Passes Zod; Godot may treat as unknown platform | No `.max()` on the string schema. |
| 17 | Whitespace-only platform | `{"platform": "   "}` | Passes Zod; Godot may reject or treat as unknown | Zod does not trim strings. |
| 18 | Extra unknown params | `{"platform": "ios", "extra": "value"}` | Returns iOS settings (extra ignored) | Zod allows unknown keys with no `strict()`. |
| 19 | Call when editor disconnected | `{"platform": "ios"}` | Error: "Godot editor is not connected" or timeout | Bridge availability resilience. |

---

## Tool 2: `configure_ios`

**Description:** Configure iOS-specific project settings including bundle ID, team ID, and code signing  
**Handler:** `callGodot(bridge, 'configure_ios', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `settings` | `object` | **Yes** | — | iOS settings to configure |
| `settings.bundle_id` | `string` | No | — | iOS bundle identifier (e.g. com.company.game) |
| `settings.team_id` | `string` | No | — | Apple Developer Team ID |
| `settings.signing` | `record<unknown>` (optional) | No | — | Code signing configuration (arbitrary key-value pairs) |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 20 | Set bundle_id only | `{"settings": {"bundle_id": "com.example.game"}}` | Success; iOS bundle ID updated | Most common partial config. |
| 21 | Set team_id only | `{"settings": {"team_id": "ABCDEF1234"}}` | Success; team ID updated | Apple Developer Team ID. |
| 22 | Set signing config only | `{"settings": {"signing": {"method": "automatic"}}}` | Success; signing config updated | Arbitrary signing key-value pairs. |
| 23 | Set all three params | `{"settings": {"bundle_id": "com.example.game", "team_id": "ABCDEF1234", "signing": {"method": "manual", "provisioning_profile": "profile.mobileprovision"}}}` | Success; all iOS settings updated | Full configuration. |
| 24 | Set bundle_id and team_id (no signing) | `{"settings": {"bundle_id": "com.example.game", "team_id": "ABCDEF1234"}}` | Success; bundle ID and team ID set | Two of three params. |
| 25 | Set bundle_id and signing (no team_id) | `{"settings": {"bundle_id": "com.example.game", "signing": {"method": "automatic"}}}` | Success; bundle ID and signing set | Two of three params. |
| 26 | Call with empty settings object | `{"settings": {}}` | Success (no-op: nothing to configure) | All params are optional; should succeed without changes. |
| 27 | Set signing with nested object | `{"settings": {"signing": {"certificates": ["cert1", "cert2"], "store_keystore": true}}}` | Success; complex signing config applied | `signing` is `z.record(z.unknown())` — accepts any structure. |
| 28 | Set signing with empty object | `{"settings": {"signing": {}}}` | Success (may clear signing config or no-op) | Empty signing object. Behavior depends on Godot implementation. |
| 29 | Set signing with various value types | `{"settings": {"signing": {"enabled": true, "count": 3, "label": "release", "options": null}}}` | Success; mixed-type signing config applied | `z.record(z.unknown())` accepts booleans, numbers, strings, null. |

### Bundle ID Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 30 | Standard reverse-domain bundle ID | `{"settings": {"bundle_id": "com.mycompany.mygame"}}` | Success | Standard format. |
| 31 | Short bundle ID | `{"settings": {"bundle_id": "a.b"}}` | Passes Zod; Godot may enforce minimum length | `z.string()` accepts any length. |
| 32 | Bundle ID with hyphens | `{"settings": {"bundle_id": "com.my-company.my-game"}}` | Passes Zod; Godot may reject | Apple does not allow hyphens in bundle IDs. Godot may or may not validate. |
| 33 | Bundle ID with underscores | `{"settings": {"bundle_id": "com.my_company.my_game"}}` | Passes Zod; Godot may reject | Underscores not standard for iOS bundle IDs. |
| 34 | Bundle ID with leading dot | `{"settings": {"bundle_id": ".com.example"}}` | Passes Zod; Godot may reject | Leading dot is invalid. |
| 35 | Bundle ID with trailing dot | `{"settings": {"bundle_id": "com.example."}}` | Passes Zod; Godot may reject | Trailing dot is invalid. |
| 36 | Bundle ID with special characters | `{"settings": {"bundle_id": "com.example@#$game"}}` | Passes Zod; Godot may reject | Special characters are invalid for iOS. |
| 37 | Bundle ID as empty string | `{"settings": {"bundle_id": ""}}` | Passes Zod; Godot may reject or clear | Empty may clear the setting. |
| 38 | Bundle ID as number | `{"settings": {"bundle_id": 12345}}` | Zod validation error | `z.string()` rejects numbers. |

### Team ID Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 39 | Standard 10-character team ID | `{"settings": {"team_id": "ABCDEF1234"}}` | Success | Standard Apple Team ID format. |
| 40 | Short team ID | `{"settings": {"team_id": "AB"}}` | Passes Zod; Godot may reject | Apple Team IDs are 10 alphanumeric characters. |
| 41 | Team ID with special characters | `{"settings": {"team_id": "ABC/DEF123"}}` | Passes Zod; Godot may reject | Slash is not valid for Team IDs. |
| 42 | Team ID as empty string | `{"settings": {"team_id": ""}}` | Passes Zod; Godot may reject or clear | Empty may clear the setting. |
| 43 | Team ID as number | `{"settings": {"team_id": 1234567890}}` | Zod validation error | `z.string()` rejects numbers. |

### Signing Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 44 | Signing with very deep nesting | `{"settings": {"signing": {"a": {"b": {"c": {"d": {"e": "deep"}}}}}}}` | Success; deep nested config applied | `z.record()` accepts any nesting depth. |
| 45 | Signing with array values | `{"settings": {"signing": {"profiles": ["a", "b", "c"], "cert_ids": [1, 2, 3]}}}` | Success; array values in signing config | `z.record(z.unknown())` accepts arrays. |
| 46 | Signing with very large object | `{"settings": {"signing": {"key_" + i: "val_" + i for i in range(1000)}}}` | Passes Zod; Godot may timeout on large payload | No size limit on `z.record()`. |

### Structural Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 47 | Missing required `settings` | `{}` | Zod validation error | `settings` is required at the top level. |
| 48 | `settings` as string | `{"settings": "bundle_id=com.example"}` | Zod validation error | `z.object()` rejects strings. |
| 49 | `settings` as array | `{"settings": ["com.example"]}` | Zod validation error | `z.object()` rejects arrays. |
| 50 | `settings` as null | `{"settings": null}` | Zod validation error | `z.object()` rejects null. |
| 51 | `settings` as number | `{"settings": 42}` | Zod validation error | `z.object()` rejects numbers. |
| 52 | Unknown key inside settings | `{"settings": {"unknown_key": "value"}}` | Passes Zod; Godot may ignore unknown keys | No `strict()` — extra keys pass validation. |
| 53 | Extra unknown top-level params | `{"settings": {"bundle_id": "com.example"}, "extra": true}` | Passes Zod (extra ignored) | Zod allows unknown top-level keys. |
| 54 | Call with settings containing only unknown keys | `{"settings": {"foo": "bar", "baz": 42}}` | Passes Zod; Godot may no-op | All keys are unknown to the schema but valid per Zod. |
| 55 | Call when editor disconnected | `{"settings": {"bundle_id": "com.example.game"}}` | Connection error | Bridge availability resilience. |

### Boolean Pair Testing

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 56 | Set → change → clear cycle for bundle_id | Set `"com.a.b"`, then `"com.a.c"`, then `""` | Each succeeds; value updates then clears | Verify state mutation. |
| 57 | Set → overrite signing config | Set `{"method":"auto"}`, then `{"method":"manual","cert":"x"}` | Each succeeds; signing config overwritten | Verify full replacement semantics. |

---

## Tool 3: `configure_android`

**Description:** Configure Android-specific project settings including package name, keystore, and permissions  
**Handler:** `callGodot(bridge, 'configure_android', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `settings` | `object` | **Yes** | — | Android settings to configure |
| `settings.package_name` | `string` | No | — | Android package name (e.g. com.company.game) |
| `settings.keystore` | `record<unknown>` (optional) | No | — | Keystore configuration for signing |
| `settings.permissions` | `array<string>` (optional) | No | — | Android permissions to declare |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 58 | Set package_name only | `{"settings": {"package_name": "com.example.game"}}` | Success; package name updated | Most common partial config. |
| 59 | Set keystore only | `{"settings": {"keystore": {"path": "android.keystore", "password": "secret"}}}` | Success; keystore config updated | Keystore with path and password. |
| 60 | Set permissions only | `{"settings": {"permissions": ["INTERNET", "ACCESS_NETWORK_STATE"]}}` | Success; permissions list updated | Standard Android permissions. |
| 61 | Set all three params | `{"settings": {"package_name": "com.example.game", "keystore": {"path": "release.keystore", "alias": "release"}, "permissions": ["INTERNET", "VIBRATE", "CAMERA"]}}` | Success; all Android settings updated | Full configuration. |
| 62 | Set package_name and permissions (no keystore) | `{"settings": {"package_name": "com.example.game", "permissions": ["INTERNET"]}}` | Success; two params set | Partial configuration. |
| 63 | Set package_name and keystore (no permissions) | `{"settings": {"package_name": "com.example.game", "keystore": {"path": "debug.keystore"}}}` | Success; two params set | Partial configuration. |
| 64 | Set keystore and permissions (no package_name) | `{"settings": {"keystore": {"path": "f.keystore"}, "permissions": ["CAMERA"]}}` | Success; two params set | Partial configuration. |
| 65 | Call with empty settings object | `{"settings": {}}` | Success (no-op: nothing to configure) | All params are optional; should succeed without changes. |
| 66 | Set single-element permissions array | `{"settings": {"permissions": ["INTERNET"]}}` | Success; one permission set | Minimal permissions array. |
| 67 | Set many permissions | `{"settings": {"permissions": ["INTERNET", "CAMERA", "VIBRATE", "RECORD_AUDIO", "WRITE_EXTERNAL_STORAGE", "READ_EXTERNAL_STORAGE", "ACCESS_FINE_LOCATION", "ACCESS_COARSE_LOCATION", "BLUETOOTH", "NFC"]}}` | Success; many permissions declared | Large permission set. |

### Package Name Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 68 | Standard reverse-domain package name | `{"settings": {"package_name": "com.mycompany.mygame"}}` | Success | Standard format. |
| 69 | Short package name | `{"settings": {"package_name": "a.b"}}` | Passes Zod; Godot may enforce minimum segments | Android requires at least two segments. |
| 70 | Package name with digits | `{"settings": {"package_name": "com.company.game123"}}` | Success | Digits are allowed in segments after the first character. |
| 71 | Package name with underscores | `{"settings": {"package_name": "com.my_company.my_game"}}` | Passes Zod; Godot may or may not validate | Underscores are technically allowed but discouraged on Android. |
| 72 | Package name with leading digit in segment | `{"settings": {"package_name": "com.123company.game"}}` | Passes Zod; Godot may reject | Java package segments cannot start with a digit. |
| 73 | Package name as empty string | `{"settings": {"package_name": ""}}` | Passes Zod; Godot may reject or clear | Empty may clear the setting. |
| 74 | Package name as number | `{"settings": {"package_name": 1234}}` | Zod validation error | `z.string()` rejects numbers. |

### Keystore Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 75 | Keystore with full config | `{"settings": {"keystore": {"path": "android.keystore", "password": "pwd", "alias": "release", "alias_password": "alias_pwd"}}}` | Success; full keystore config | Complete keystore parameters. |
| 76 | Keystore with empty object | `{"settings": {"keystore": {}}}` | Success (may clear keystore settings or no-op) | Empty keystore object. |
| 77 | Keystore with numeric password | `{"settings": {"keystore": {"password": 12345}}}` | Passes Zod; Godot may coerce to string | `z.record(z.unknown())` accepts any value type. |
| 78 | Keystore with boolean flags | `{"settings": {"keystore": {"debug": true, "release": false}}}` | Passes Zod; Godot behavior TBD | Non-standard keystore keys. |
| 79 | Very deeply nested keystore object | `{"settings": {"keystore": {"a": {"b": {"c": {"d": {"e": 1}}}}}}}` | Passes Zod; Godot may ignore deep nesting | `z.record()` accepts any depth. |

### Permissions Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 80 | Empty permissions array | `{"settings": {"permissions": []}}` | Success (clears all permissions) | Empty array may clear the permission list. |
| 81 | Permissions with empty strings | `{"settings": {"permissions": ["INTERNET", ""]}}` | Passes Zod; Godot may reject empty entries | Empty string in array passes `z.string()` validation. |
| 82 | Permissions with duplicate entries | `{"settings": {"permissions": ["INTERNET", "INTERNET"]}}` | Passes Zod; Godot may deduplicate or keep duplicates | Duplicate permissions. |
| 83 | Permissions as non-array | `{"settings": {"permissions": "INTERNET"}}` | Zod validation error | `z.array(z.string())` rejects plain strings. |
| 84 | Permissions as array of numbers | `{"settings": {"permissions": [1, 2, 3]}}` | Zod validation error | `z.string()` in array rejects numbers. |
| 85 | Permissions as array of booleans | `{"settings": {"permissions": [true, false]}}` | Zod validation error | `z.string()` in array rejects booleans. |
| 86 | Permissions with null elements | `{"settings": {"permissions": ["INTERNET", null]}}` | Zod validation error | `z.string()` rejects null elements. |
| 87 | Common Android permissions set | `{"settings": {"permissions": ["INTERNET", "ACCESS_NETWORK_STATE", "VIBRATE", "WAKE_LOCK", "com.google.android.c2dm.permission.RECEIVE"]}}` | Success | Realistic permission set used in Godot projects. |
| 88 | Custom/non-standard permission | `{"settings": {"permissions": ["com.mycompany.CUSTOM_PERMISSION"]}}` | Passes Zod; Godot may accept | Custom Android permissions are valid. |

### Structural Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 89 | Missing required `settings` | `{}` | Zod validation error | `settings` is required at the top level. |
| 90 | `settings` as string | `{"settings": "package=com.example"}` | Zod validation error | `z.object()` rejects strings. |
| 91 | `settings` as array | `{"settings": ["com.example"]}` | Zod validation error | `z.object()` rejects arrays. |
| 92 | `settings` as null | `{"settings": null}` | Zod validation error | `z.object()` rejects null. |
| 93 | Unknown key inside settings | `{"settings": {"unknown_key": "value"}}` | Passes Zod; Godot may ignore unknown keys | No `strict()` — extra keys pass validation. |
| 94 | Extra unknown top-level params | `{"settings": {"package_name": "com.example"}, "extra": true}` | Passes Zod (extra ignored) | Zod allows unknown top-level keys. |
| 95 | Call when editor disconnected | `{"settings": {"package_name": "com.example.game"}}` | Connection error | Bridge availability resilience. |

### Boolean Pair Testing

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 96 | Permissions: set → add → remove cycle | Set `["A"]`, then `["A","B"]`, then `["B"]` | Each succeeds; permissions list mutates | Verify list replacement semantics. |
| 97 | Package name: set → change → clear | Set `"com.a.b"`, then `"com.a.c"`, then `""` | Each succeeds; value updates then clears | Verify state mutation. |

---

## Tool 4: `configure_web`

**Description:** Configure web/HTML5 export settings including canvas resize, threading, and PWA support  
**Handler:** `callGodot(bridge, 'configure_web', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `settings` | `object` | **Yes** | — | Web platform settings to configure |
| `settings.canvas_resize` | `boolean` | No | — | Enable automatic canvas resizing |
| `settings.threading` | `boolean` | No | — | Enable SharedArrayBuffer threading support |
| `settings.pwa` | `boolean` | No | — | Enable Progressive Web App support |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 98 | Enable canvas_resize | `{"settings": {"canvas_resize": true}}` | Success; canvas resize enabled | Single boolean toggle. |
| 99 | Disable canvas_resize | `{"settings": {"canvas_resize": false}}` | Success; canvas resize disabled | Opposite toggle. |
| 100 | Enable threading | `{"settings": {"threading": true}}` | Success; threading (SharedArrayBuffer) enabled | Requires server configuration for COOP/COEP headers. |
| 101 | Disable threading | `{"settings": {"threading": false}}` | Success; threading disabled | Reverts to single-threaded export. |
| 102 | Enable PWA | `{"settings": {"pwa": true}}` | Success; PWA support enabled | Enables service worker and manifest generation. |
| 103 | Disable PWA | `{"settings": {"pwa": false}}` | Success; PWA support disabled | Disables PWA features. |
| 104 | Enable all three | `{"settings": {"canvas_resize": true, "threading": true, "pwa": true}}` | Success; all web features enabled | Full web configuration. |
| 105 | Disable all three | `{"settings": {"canvas_resize": false, "threading": false, "pwa": false}}` | Success; all web features disabled | Full disable configuration. |
| 106 | Mixed enable/disable | `{"settings": {"canvas_resize": true, "threading": false, "pwa": true}}` | Success; mixed web config | Partial enabling. |
| 107 | Call with empty settings object | `{"settings": {}}` | Success (no-op: nothing to configure) | All params are optional; should succeed without changes. |
| 108 | Set canvas_resize and threading (no pwa) | `{"settings": {"canvas_resize": true, "threading": false}}` | Success; two params set | Partial configuration. |
| 109 | Set canvas_resize and pwa (no threading) | `{"settings": {"canvas_resize": false, "pwa": true}}` | Success; two params set | Partial configuration. |
| 110 | Set threading and pwa (no canvas_resize) | `{"settings": {"threading": true, "pwa": true}}` | Success; two params set | Partial configuration. |

### Boolean Type Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 111 | canvas_resize as string "true" | `{"settings": {"canvas_resize": "true"}}` | Zod validation error | `z.boolean()` rejects strings. |
| 112 | canvas_resize as string "false" | `{"settings": {"canvas_resize": "false"}}` | Zod validation error | `z.boolean()` rejects strings. |
| 113 | canvas_resize as number 1 | `{"settings": {"canvas_resize": 1}}` | Zod validation error | `z.boolean()` rejects numbers. |
| 114 | canvas_resize as number 0 | `{"settings": {"canvas_resize": 0}}` | Zod validation error | `z.boolean()` rejects numbers. |
| 115 | canvas_resize as null | `{"settings": {"canvas_resize": null}}` | Zod validation error | `z.boolean()` rejects null (no nullable). |
| 116 | threading as string "yes" | `{"settings": {"threading": "yes"}}` | Zod validation error | `z.boolean()` rejects strings. |
| 117 | threading as number 1 | `{"settings": {"threading": 1}}` | Zod validation error | `z.boolean()` rejects numbers. |
| 118 | pwa as string "on" | `{"settings": {"pwa": "on"}}` | Zod validation error | `z.boolean()` rejects strings. |
| 119 | pwa as number 0 | `{"settings": {"pwa": 0}}` | Zod validation error | `z.boolean()` rejects numbers. |
| 120 | pwa as array [true] | `{"settings": {"pwa": [true]}}` | Zod validation error | `z.boolean()` rejects arrays. |
| 121 | canvas_resize as object {"val": true} | `{"settings": {"canvas_resize": {"val": true}}}` | Zod validation error | `z.boolean()` rejects objects. |

### Structural Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 122 | Missing required `settings` | `{}` | Zod validation error | `settings` is required at the top level. |
| 123 | `settings` as string | `{"settings": "web_config"}` | Zod validation error | `z.object()` rejects strings. |
| 124 | `settings` as array | `{"settings": [true, false, true]}` | Zod validation error | `z.object()` rejects arrays. |
| 125 | `settings` as null | `{"settings": null}` | Zod validation error | `z.object()` rejects null. |
| 126 | `settings` as boolean | `{"settings": true}` | Zod validation error | `z.object()` rejects booleans. |
| 127 | Unknown key inside settings | `{"settings": {"canvas_resize": true, "unknown": "value"}}` | Passes Zod; Godot may ignore unknown keys | No `strict()` — extra keys pass validation. |
| 128 | Extra unknown top-level params | `{"settings": {"canvas_resize": true}, "extra": true}` | Passes Zod (extra ignored) | Zod allows unknown top-level keys. |
| 129 | Call when editor disconnected | `{"settings": {"canvas_resize": true}}` | Connection error | Bridge availability resilience. |

### Boolean Pair Testing

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 130 | Toggle canvas_resize: true → false → true | Sequential calls | Each succeeds; state toggles correctly | Verify boolean state persistence. |
| 131 | Toggle threading: false → true → false | Sequential calls | Each succeeds; state toggles correctly | Verify boolean state persistence. |
| 132 | Toggle PWA: true → false → true | Sequential calls | Each succeeds; state toggles correctly | Verify boolean state persistence. |
| 133 | Toggle all simultaneously | `{"settings": {"canvas_resize": true, "threading": true, "pwa": true}}` then opposite | Each succeeds; all states toggle correctly | Verify all three boolean states persist independently. |

### Realistic Web Configurations

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 134 | Minimal web game (no special features) | `{"settings": {"canvas_resize": true, "threading": false, "pwa": false}}` | Success | Simple HTML5 export. |
| 135 | Threaded web game (no PWA) | `{"settings": {"canvas_resize": true, "threading": true, "pwa": false}}` | Success | Multi-threaded web export without PWA. |
| 136 | PWA-ready web game | `{"settings": {"canvas_resize": true, "threading": false, "pwa": true}}` | Success | Installable PWA, single-threaded. |
| 137 | Full-featured web game | `{"settings": {"canvas_resize": true, "threading": true, "pwa": true}}` | Success | All features enabled. |

---

## Tool 5: `get_platform_capabilities`

**Description:** Get the available features and capabilities for a specific platform  
**Handler:** `callGodot(bridge, 'get_platform_capabilities', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `platform` | `string` | **Yes** | — | Platform name to query capabilities for |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 138 | Query iOS capabilities | `{"platform": "ios"}` | JSON object listing iOS features/capabilities (e.g., ARKit, Metal, touch input) | Platform-specific feature enumeration. |
| 139 | Query Android capabilities | `{"platform": "android"}` | JSON object listing Android features/capabilities (e.g., Vulkan, Google Play, permissions) | Platform-specific feature enumeration. |
| 140 | Query Web capabilities | `{"platform": "web"}` | JSON object listing HTML5 features/capabilities (e.g., WebGL, WebRTC, SharedArrayBuffer) | Platform-specific feature enumeration. |
| 141 | Query Windows capabilities | `{"platform": "windows"}` | JSON object listing Windows features/capabilities | Desktop platform. |
| 142 | Query Linux capabilities | `{"platform": "linux"}` | JSON object listing Linux features/capabilities | Desktop platform. |
| 143 | Query macOS capabilities | `{"platform": "macos"}` | JSON object listing macOS features/capabilities | Desktop platform. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 144 | Missing required `platform` | `{}` | Zod validation error | `platform` is required. |
| 145 | Empty string platform | `{"platform": ""}` | Passes Zod; Godot may return generic or empty capabilities | `z.string()` accepts empty string. |
| 146 | Unknown platform name | `{"platform": "xbox"}` | Godot may return empty capabilities or error | Unsupported/unknown platform. |
| 147 | Case-variant platform name | `{"platform": "Android"}` | Godot may reject (case-sensitive) | Platform names are typically lowercase. |
| 148 | Platform as number | `{"platform": 42}` | Zod validation error | `z.string()` rejects numbers. |
| 149 | Platform as boolean | `{"platform": false}` | Zod validation error | `z.string()` rejects booleans. |
| 150 | Platform as null | `{"platform": null}` | Zod validation error | `z.string()` rejects null. |
| 151 | Platform as object | `{"platform": {"name": "ios"}}` | Zod validation error | `z.string()` rejects objects. |
| 152 | Platform as array | `{"platform": ["ios"]}` | Zod validation error | `z.string()` rejects arrays. |
| 153 | Very long platform name | `{"platform": "a".repeat(5000)}` | Passes Zod; Godot may treat as unknown platform | No `.max()` on the string schema. |
| 154 | Extra unknown params | `{"platform": "ios", "include_all": true}` | Returns iOS capabilities (extra ignored) | Zod allows unknown keys. |
| 155 | Call when editor disconnected | `{"platform": "ios"}` | Error: "Godot editor is not connected" or timeout | Bridge availability resilience. |

### Cross-Platform Consistency

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 156 | Compare all 6 platform results | Query all 6 known platforms sequentially | Each returns a valid JSON object; results differ per platform | Validate that each platform returns unique, reasonable capabilities. |
| 157 | Verify capabilities structure is consistent | Query any valid platform | Result has consistent structure (e.g., object with feature keys) | API should return similar JSON structure across platforms. |

---

## Tool 6: `validate_platform_build`

**Description:** Validate the project for building on a specific platform, checking for issues  
**Handler:** `callGodot(bridge, 'validate_platform_build', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `platform` | `string` | **Yes** | — | Platform to validate the build for |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 158 | Validate for iOS | `{"platform": "ios"}` | JSON object with validation results (errors, warnings, info) | Core validation use case. |
| 159 | Validate for Android | `{"platform": "android"}` | JSON object with validation results | Core validation use case. |
| 160 | Validate for Web | `{"platform": "web"}` | JSON object with validation results | Core validation use case. |
| 161 | Validate for Windows | `{"platform": "windows"}` | JSON object with validation results | Desktop platform validation. |
| 162 | Validate for Linux | `{"platform": "linux"}` | JSON object with validation results | Desktop platform validation. |
| 163 | Validate for macOS | `{"platform": "macos"}` | JSON object with validation results | Desktop platform validation. |
| 164 | Validate with properly configured project | `{"platform": "android"}` (project has all required settings) | Validation passes with no errors | Project is correctly set up for the platform. |
| 165 | Validate with missing settings (e.g., no bundle ID for iOS) | `{"platform": "ios"}` (project has no bundle ID) | Returns validation errors listing missing bundle ID | Shows what validation errors look like. |
| 166 | Validate with missing export templates | `{"platform": "android"}` (templates not installed) | Returns validation warning/error about missing templates | Verifies template check. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 167 | Missing required `platform` | `{}` | Zod validation error | `platform` is required. |
| 168 | Empty string platform | `{"platform": ""}` | Passes Zod; Godot may return empty or generic validation | `z.string()` accepts empty string. |
| 169 | Unknown platform name | `{"platform": "playstation"}` | Godot may return error or empty validation results | Unsupported platform. |
| 170 | Case-variant platform name | `{"platform": "ANDROID"}` | Godot may reject (case-sensitive) | Platform names are typically lowercase. |
| 171 | Platform as number | `{"platform": 1}` | Zod validation error | `z.string()` rejects numbers. |
| 172 | Platform as boolean | `{"platform": false}` | Zod validation error | `z.string()` rejects booleans. |
| 173 | Platform as null | `{"platform": null}` | Zod validation error | `z.string()` rejects null. |
| 174 | Platform as object | `{"platform": {"name": "ios"}}` | Zod validation error | `z.string()` rejects objects. |
| 175 | Platform as array | `{"platform": ["android"]}` | Zod validation error | `z.string()` rejects arrays. |
| 176 | Whitespace-only platform | `{"platform": "   "}` | Passes Zod; Godot may reject | Zod does not trim. |
| 177 | Very long platform name | `{"platform": "a".repeat(10000)}` | Passes Zod; Godot may treat as unknown platform | No `.max()` on the string schema. |
| 178 | Call validation twice for same platform | `{"platform": "android"}` called twice | Both succeed with same results (idempotent) | Validation should be repeatable and idempotent. |
| 179 | Validate all 6 platforms sequentially | Call each platform one after another | Each returns platform-specific validation results | Stress test for validation system. |
| 180 | Extra unknown params | `{"platform": "ios", "verbose": true}` | Returns validation results (extra ignored) | Zod allows unknown keys. |
| 181 | Call when editor disconnected | `{"platform": "ios"}` | Error: "Godot editor is not connected" or timeout | Bridge availability resilience. |

### Validation Result Content Checks

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 182 | Verify validation result has structured output | `{"platform": "android"}` | Result is an object with recognizable keys (e.g., `errors`, `warnings`, `valid`) | Verify result structure is consistent. |
| 183 | Validate for platform that has no export templates | `{"platform": "web"}` (no templates) | Warning about missing HTML5 export templates | Specific validation feedback. |
| 184 | Validate for platform with missing required settings | `{"platform": "ios"}` (no bundle_id) | Error about missing bundle identifier | Specific validation feedback. |
| 185 | Validate for platform with all settings correct | `{"platform": "windows"}` (fully configured) | Validation passes; no errors | Confirms validation is accurate for well-configured platforms. |

### Cross-Tool Consistency

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 186 | get_platform_settings → validate for same platform | Get settings for "ios", then validate for "ios" | Validation results should reflect the settings returned by `get_platform_settings` | Cross-tool consistency check. |
| 187 | configure_ios → validate for iOS | Set bundle_id via `configure_ios`, then validate for `ios` | Validation should pass (bundle ID set) or fail with other missing settings | End-to-end: configure then validate. |
| 188 | configure_android → get_platform_capabilities → validate | Set package_name, get capabilities, validate | Validation should reflect the configured package name | End-to-end: cross-tool workflow. |

---

## Summary

| Tool | Required Params | Optional Params | Enum Values (platform) | Enum Values (other) | Total Scenarios |
|------|----------------|-----------------|------------------------|---------------------|-----------------|
| `get_platform_settings` | `platform` (string) | — | ios, android, web, windows, linux, macos | — | 19 |
| `configure_ios` | `settings` (object) | `bundle_id` (string), `team_id` (string), `signing` (record) | — | — | 38 |
| `configure_android` | `settings` (object) | `package_name` (string), `keystore` (record), `permissions` (string[]) | — | — | 40 |
| `configure_web` | `settings` (object) | `canvas_resize` (boolean), `threading` (boolean), `pwa` (boolean) | — | true/false | 40 |
| `get_platform_capabilities` | `platform` (string) | — | ios, android, web, windows, linux, macos | — | 20 |
| `validate_platform_build` | `platform` (string) | — | ios, android, web, windows, linux, macos | — | 31 |
| **Total** | | | | | **188** |
