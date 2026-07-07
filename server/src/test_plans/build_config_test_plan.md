# Build Config Tools — Test Plan

**Source file:** `server/src/tools/build_config.ts`  
**Number of tools:** 8  
**Godot bridge commands:** `build_config/get_settings`, `build_config/set_configuration`, `build_config/set_scripting_backend`, `build_config/set_export_filter`, `build_config/set_custom_features`, `build_config/set_debug_options`, `build_config/validate`, `build_config/get_build_command`

---

## Tool 1: `get_build_settings`

**Description:** Get all build configuration settings (debug/release, scripting backend, features)  
**Parameters:** None (empty `inputSchema`)  
**Handler:** `callGodot(bridge, 'build_config/get_settings')`  
**Expected result:** Returns a JSON object containing all current build configuration settings — configuration preset, scripting backend, export filter mode, custom features, and debug/optimization options.

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 1 | Call with no arguments | `{}` | Valid JSON object with build settings keys | Simplest invocation. Should always succeed when editor is connected. |
| 2 | Call with extra ignored arg | `{"ignored": true}` | Valid JSON object (extra arg ignored) | Zod ignores unknown keys since no schema is defined. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 3 | Call when editor is disconnected | `{}` | Error: "Godot editor is not connected" or timeout | Tests bridge availability resilience. |
| 4 | Call with `null` body | `null` | Valid JSON object (body ignored, no schema) | MCP SDK may coerce null to `{}`. Either is acceptable. |
| 5 | Call twice in succession | `{}` (×2) | Same result both times (idempotent) | Read-only tool; should return consistent results. |

---

## Tool 2: `set_build_configuration`

**Description:** Set the build configuration preset  
**Handler:** `callGodot(bridge, 'build_config/set_configuration', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `config` | `enum` | No | `"debug"` | Build configuration (debug: full symbols, release: optimized, development: release with debug) |

**Enum values:** `"debug"`, `"release"`, `"development"`

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 6 | Set to `debug` (default) | `{}` | Success; config set to debug | Omitting param uses default 'debug'. |
| 7 | Set to `debug` explicitly | `{"config": "debug"}` | Success; config set to debug | Explicit debug configuration. |
| 8 | Set to `release` | `{"config": "release"}` | Success; config set to release | Release mode — optimized build. |
| 9 | Set to `development` | `{"config": "development"}` | Success; config set to development | Development mode — release with debug info. |

### Enum Value Testing — Each Enum Value

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 10 | Set `"debug"` | `{"config": "debug"}` | Success | Full symbols enabled. |
| 11 | Set `"release"` | `{"config": "release"}` | Success | Fully optimized. |
| 12 | Set `"development"` | `{"config": "development"}` | Success | Release build with debug symbols. |

### Enum Value Testing — Invalid Values

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 13 | Invalid enum: `"production"` | `{"config": "production"}` | Zod validation error | Not in enum list. |
| 14 | Invalid enum: `"Debug"` (capitalized) | `{"config": "Debug"}` | Zod validation error | Enum is case-sensitive. |
| 15 | Invalid enum: empty string | `{"config": ""}` | Zod validation error | Empty string not in enum. |
| 16 | Invalid type: number | `{"config": 0}` | Zod validation error | Number not accepted. |
| 17 | Invalid type: boolean | `{"config": true}` | Zod validation error | Boolean not accepted. |
| 18 | Invalid type: array | `{"config": ["debug"]}` | Zod validation error | Array not accepted. |
| 19 | Invalid type: object | `{"config": {}}` | Zod validation error | Object not accepted. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 20 | Call with extra unknown keys | `{"config": "release", "extra": true}` | Success (extra key ignored by Zod) | Extra params are stripped by Zod parsing. |
| 21 | Call when editor is disconnected | `{"config": "release"}` | Connection error | Standard disconnected behavior. |
| 22 | Call with `null` body | `null` | Uses default 'debug' (Zod default) | `null` body → schema default kicks in. |
| 23 | Toggle: debug → release → development → debug | Sequential calls | Each succeeds; state transitions correctly | Verify state persistence across all three modes. |
| 24 | Re-set same value (idempotent) | `{"config": "release"}` (×2) | Success both times | No error when re-setting to current value. |

---

## Tool 3: `set_scripting_backend`

**Description:** Set the scripting backend for the project  
**Handler:** `callGodot(bridge, 'build_config/set_scripting_backend', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `backend` | `enum` | No | `"gdscript"` | Scripting language backend: gdscript or csharp |

**Enum values:** `"gdscript"`, `"csharp"`

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 25 | Set to `gdscript` (default) | `{}` | Success; backend set to gdscript | Omitting param uses default 'gdscript'. |
| 26 | Set to `gdscript` explicitly | `{"backend": "gdscript"}` | Success; backend set to gdscript | Explicit gdscript backend. |
| 27 | Set to `csharp` | `{"backend": "csharp"}` | Success; backend set to csharp | Switch to C# scripting. May require .NET SDK. |

### Enum Value Testing — Each Enum Value

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 28 | Set `"gdscript"` | `{"backend": "gdscript"}` | Success | Native Godot scripting language. |
| 29 | Set `"csharp"` | `{"backend": "csharp"}` | Success | Requires .NET/Mono support. Godot may warn if .NET not installed. |

### Enum Value Testing — Invalid Values

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 30 | Invalid enum: `"python"` | `{"backend": "python"}` | Zod validation error | Not in enum list. |
| 31 | Invalid enum: `"GDScript"` (capitalized) | `{"backend": "GDScript"}` | Zod validation error | Enum is case-sensitive. |
| 32 | Invalid enum: `"CSharp"` (capitalized) | `{"backend": "CSharp"}` | Zod validation error | Enum is case-sensitive. |
| 33 | Invalid enum: empty string | `{"backend": ""}` | Zod validation error | Empty string not in enum. |
| 34 | Invalid type: number | `{"backend": 0}` | Zod validation error | Number not accepted. |
| 35 | Invalid type: boolean | `{"backend": true}` | Zod validation error | Boolean not accepted. |
| 36 | Invalid type: null | `{"backend": null}` | Zod validation error | Null not accepted by enum. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 37 | Call when editor disconnected | `{"backend": "gdscript"}` | Connection error | Standard disconnected behavior. |
| 38 | Switch to csharp without .NET SDK | `{"backend": "csharp"}` | May succeed at API level; Godot may emit warning | Godot-side validation may differ from MCP validation. |
| 39 | Switch csharp → gdscript → csharp | Sequential calls | Each succeeds; state toggles correctly | Verify toggling between backends. |
| 40 | Re-set same backend (idempotent) | `{"backend": "gdscript"}` (×2) | Success both times | No error on re-set to current value. |
| 41 | Call with `null` body | `null` | Uses default 'gdscript' (Zod default) | Null body → schema default kicks in. |

---

## Tool 4: `set_export_filter`

**Description:** Set which resources to include in exports  
**Handler:** `callGodot(bridge, 'build_config/set_export_filter', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `filter` | `enum` | No | `"all_resources"` | Export filter mode |

**Enum values:** `"all_resources"`, `"selected_resources"`

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 42 | Set to `all_resources` (default) | `{}` | Success; filter set to all_resources | Omitting param uses default. |
| 43 | Set to `all_resources` explicitly | `{"filter": "all_resources"}` | Success; all resources exported | Everything included in export. |
| 44 | Set to `selected_resources` | `{"filter": "selected_resources"}` | Success; only selected resources exported | Restrictive export mode. |

### Enum Value Testing — Each Enum Value

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 45 | Set `"all_resources"` | `{"filter": "all_resources"}` | Success | Export all project resources. |
| 46 | Set `"selected_resources"` | `{"filter": "selected_resources"}` | Success | Export only explicitly selected resources. |

### Enum Value Testing — Invalid Values

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 47 | Invalid enum: `"none"` | `{"filter": "none"}` | Zod validation error | Not in enum list. |
| 48 | Invalid enum: `"All_Resources"` (capitalized) | `{"filter": "All_Resources"}` | Zod validation error | Enum is case-sensitive. |
| 49 | Invalid enum: empty string | `{"filter": ""}` | Zod validation error | Empty string not in enum. |
| 50 | Invalid type: number | `{"filter": 1}` | Zod validation error | Number not accepted. |
| 51 | Invalid type: boolean | `{"filter": false}` | Zod validation error | Boolean not accepted. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 52 | Call when editor disconnected | `{"filter": "selected_resources"}` | Connection error | Standard disconnected behavior. |
| 53 | Toggle: all_resources → selected_resources → all_resources | Sequential calls | Each succeeds; state toggles correctly | Verify state persistence. |
| 54 | Re-set same filter (idempotent) | `{"filter": "all_resources"}` (×2) | Success both times | No error on re-set to current value. |
| 55 | Call with `null` body | `null` | Uses default 'all_resources' | Null body → schema default. |

---

## Tool 5: `set_custom_features`

**Description:** Set custom feature tags for conditional compilation and export  
**Handler:** `callGodot(bridge, 'build_config/set_custom_features', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `features` | `string[]` | No | `[]` | List of custom feature tags (e.g. `['demo', 'mobile', 'premium']`) |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 56 | Set single feature | `{"features": ["demo"]}` | Success; feature 'demo' set | Single custom feature tag. |
| 57 | Set multiple features | `{"features": ["demo", "mobile", "premium"]}` | Success; all three features set | Multiple custom feature tags. |
| 58 | Set features with special chars | `{"features": ["feature-v2", "dev_build", "stage1"]}` | Success; features with hyphens/underscores/numbers set | Features are free-form strings. |
| 59 | Set features with uppercase | `{"features": ["DEMO", "MOBILE", "Premium"]}` | Success; case is preserved | Godot feature tags may be case-sensitive. |
| 60 | Clear features (default) | `{}` | Success; features set to [] (empty) | Omitting param uses default empty array. |
| 61 | Set empty array explicitly | `{"features": []}` | Success; all features cleared | Explicitly clearing all features. |

### Edge Cases — Array Content

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 62 | Features with empty string | `{"features": [""]}` | Passes Zod; Godot may reject or store empty string | `z.string()` accepts empty strings. Godot behavior TBD. |
| 63 | Features with whitespace-only string | `{"features": ["   "]}` | Passes Zod; Godot may reject or store | No string validation beyond type check. |
| 64 | Very long feature name | `{"features": ["a".repeat(256)]}` | Passes Zod; Godot may truncate or reject | No max length constraint. |
| 65 | Many features (100+) | `{"features": [...Array(100)].map((_,i) => `feat_${i}`)}` | Passes Zod; Godot may have limits | No max array length constraint in Zod. |
| 66 | Duplicate features | `{"features": ["demo", "demo", "demo"]}` | Passes Zod; Godot may deduplicate | No uniqueness constraint. |
| 67 | Unicode/special characters in feature | `{"features": ["日本語", "français", "🎮"]}` | Passes Zod; Godot may or may not support | No character restrictions in schema. |

### Edge Cases — Invalid Types

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 68 | Features as string (not array) | `{"features": "demo"}` | Zod validation error | `z.array(z.string())` rejects plain string. |
| 69 | Features as comma-separated string | `{"features": "demo,mobile"}` | Zod validation error | Must be an actual array. |
| 70 | Features with non-string elements | `{"features": ["demo", 123, true]}` | Zod validation error | All elements must be strings. |
| 71 | Features with null element | `{"features": ["demo", null]}` | Zod validation error | Null not accepted by `z.string()`. |
| 72 | Features with object element | `{"features": [{"name": "demo"}]}` | Zod validation error | Object not accepted. |
| 73 | Features as number | `{"features": 123}` | Zod validation error | Type mismatch. |
| 74 | Features as boolean | `{"features": true}` | Zod validation error | Type mismatch. |

### Edge Cases — General

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 75 | Call when editor disconnected | `{"features": ["demo"]}` | Connection error | Standard disconnected behavior. |
| 76 | Overwrite existing features | Call 1: `{"features": ["old"]}`, Call 2: `{"features": ["new"]}` | Call 2 replaces old with new | Should fully replace, not append. |
| 77 | Set features, then clear, then re-set | Sequence: set → empty → set | Each succeeds; state follows correctly | Verify full lifecycle. |
| 78 | Call with `null` body | `null` | Uses default `[]` (Zod default) | Null body → schema default. |

---

## Tool 6: `set_debug_options`

**Description:** Configure debug and optimization options  
**Handler:** `callGodot(bridge, 'build_config/set_debug_options', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `debug_build` | `boolean` | No | — | Enable debug build (includes symbols) |
| `release_debug` | `boolean` | No | — | Release build with debug info |
| `optimize` | `boolean` | No | — | Enable optimizations |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 79 | Set `debug_build` only | `{"debug_build": true}` | Success; debug build enabled | Single boolean param. |
| 80 | Set `release_debug` only | `{"release_debug": true}` | Success; release debug enabled | Release build with debug symbols. |
| 81 | Set `optimize` only | `{"optimize": true}` | Success; optimizations enabled | Enable compiler optimizations. |
| 82 | Disable individual option | `{"debug_build": false}` | Success; debug build disabled | Toggle option off. |
| 83 | Set all three options (all true) | `{"debug_build": true, "release_debug": true, "optimize": true}` | Success; all options enabled | Full debug config. May be mutually exclusive at Godot level. |
| 84 | Set all three options (all false) | `{"debug_build": false, "release_debug": false, "optimize": false}` | Success; all options disabled | All options turned off. |
| 85 | Set mixed options | `{"debug_build": true, "release_debug": false, "optimize": true}` | Success; mixed configuration | Tests each param independently. |
| 86 | Call with no params | `{}` | Success (no-op: nothing to set) | All three params are optional; empty call should succeed without changes. |

### Boolean Parameter Testing — `debug_build`

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 87 | Set `true` | `{"debug_build": true}` | Success | Standard boolean true. |
| 88 | Set `false` | `{"debug_build": false}` | Success | Standard boolean false. |
| 89 | Set as string `"true"` | `{"debug_build": "true"}` | Zod validation error | `z.boolean()` rejects strings. |
| 90 | Set as string `"false"` | `{"debug_build": "false"}` | Zod validation error | `z.boolean()` rejects strings. |
| 91 | Set as number `1` | `{"debug_build": 1}` | Zod validation error | `z.boolean()` rejects numbers. |
| 92 | Set as number `0` | `{"debug_build": 0}` | Zod validation error | `z.boolean()` rejects numbers. |

### Boolean Parameter Testing — `release_debug`

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 93 | Set `true` | `{"release_debug": true}` | Success | Standard boolean true. |
| 94 | Set `false` | `{"release_debug": false}` | Success | Standard boolean false. |
| 95 | Set as string `"true"` | `{"release_debug": "true"}` | Zod validation error | `z.boolean()` rejects strings. |

### Boolean Parameter Testing — `optimize`

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 96 | Set `true` | `{"optimize": true}` | Success | Standard boolean true. |
| 97 | Set `false` | `{"optimize": false}` | Success | Standard boolean false. |
| 98 | Set as number `1` | `{"optimize": 1}` | Zod validation error | `z.boolean()` rejects numbers. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 99 | Extra unknown key | `{"debug_build": true, "unknown": "value"}` | Success (unknown key ignored by Zod) | Extra params stripped. |
| 100 | Call when editor disconnected | `{"debug_build": true}` | Connection error | Standard disconnected behavior. |
| 101 | Toggle: enable → disable → enable | Sequential calls to each boolean | Each toggles correctly | State persists across toggles. |
| 102 | Call with `null` body | `null` | Success (all params optional, no-op) | Null body → all params undefined. No changes. |
| 103 | debug_build and optimize both true | `{"debug_build": true, "optimize": true}` | Success; Godot may warn (debug + optimize unusual) | Semantic edge case at Godot level. |
| 104 | release_debug true, debug_build false | `{"release_debug": true, "debug_build": false}` | Success; release build with debug symbols | Common real-world configuration. |

---

## Tool 7: `validate_build_settings`

**Description:** Validate current build settings and return any errors or warnings  
**Parameters:** None (empty `inputSchema`)  
**Handler:** `callGodot(bridge, 'build_config/validate')`  
**Expected result:** Returns a JSON object with validation results — may include `valid` (boolean), `errors` (array), and `warnings` (array).

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 105 | Validate default settings | `{}` | JSON with validation results | Default project settings should validate cleanly. |
| 106 | Validate after changing config to release | Pre-set `{"config": "release"}`, then call `{}` | JSON reflecting release config validation | Validation should reflect current state. |
| 107 | Call with extra ignored arg | `{"ignored": true}` | Valid JSON (extra arg ignored) | No schema, so unknown keys are ignored. |

### Edge Cases

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 108 | Validate after setting invalid combination | Pre-set incompatible options, then call `{}` | May return errors/warnings about conflicts | Tests whether Godot catches semantic issues. |
| 109 | Call when editor disconnected | `{}` | Error: "Godot editor is not connected" or timeout | Standard disconnected behavior. |
| 110 | Call twice in succession | `{}` (×2) | Same result both times (read-only, idempotent) | No side effects from validation. |
| 111 | Validate after clearing custom features | Pre-set `{"features": []}`, then validate | Should reflect empty features list | Validation should match current state. |
| 112 | Call with `null` body | `null` | Valid JSON (body ignored, no schema) | Null body → `{}`. |

---

## Tool 8: `get_build_command`

**Description:** Get the CLI command to export/build the project for a specific platform  
**Handler:** `callGodot(bridge, 'build_config/get_build_command', args)`

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `platform` | `string` | **Yes** | — | Target platform (e.g. `'windows'`, `'linux'`, `'web'`, `'android'`) |

### Happy Path

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 113 | Get command for windows | `{"platform": "windows"}` | CLI command string for Windows export | Core platform. |
| 114 | Get command for linux | `{"platform": "linux"}` | CLI command string for Linux export | Core platform. |
| 115 | Get command for web (HTML5) | `{"platform": "web"}` | CLI command string for Web export | Web/HTML5 target. |
| 116 | Get command for android | `{"platform": "android"}` | CLI command string for Android export | Mobile platform. |

### Platform Value Testing

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 117 | Platform: `"windows"` | `{"platform": "windows"}` | Success; Windows export command | Most common desktop export. |
| 118 | Platform: `"linux"` | `{"platform": "linux"}` | Success; Linux export command | Desktop Linux export. |
| 119 | Platform: `"web"` | `{"platform": "web"}` | Success; HTML5/Web export command | Web platform. |
| 120 | Platform: `"android"` | `{"platform": "android"}` | Success; Android export command | Mobile platform. |
| 121 | Platform: `"macos"` | `{"platform": "macos"}` | Passes Zod; Godot may or may not accept | Listed as example in description. |
| 122 | Platform: `"ios"` | `{"platform": "ios"}` | Passes Zod; Godot may or may not support | Mobile platform — may need macOS host. |

### Edge Cases — Invalid Platform Values

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 123 | Missing required `platform` | `{}` | Zod validation error | `platform` is required (no `.optional()`). |
| 124 | Empty string platform | `{"platform": ""}` | Passes Zod; Godot may reject or error | `z.string()` accepts empty. Godot behavior TBD. |
| 125 | Unsupported platform: `"ps5"` | `{"platform": "ps5"}` | Passes Zod; Godot may return error | Free-form string — Godot-side validation. |
| 126 | Unsupported platform: `"xbox"` | `{"platform": "xbox"}` | Passes Zod; Godot may return error | Free-form string — Godot-side validation. |
| 127 | Platform with uppercase: `"Windows"` | `{"platform": "Windows"}` | Passes Zod; Godot may reject (case-sensitive) | No case normalization in schema. |
| 128 | Platform with whitespace: `" windows "` | `{"platform": " windows "}` | Passes Zod; Godot may reject or trim | No trimming in schema. |
| 129 | Numeric platform | `{"platform": 1}` | Zod validation error | `z.string()` rejects numbers. |
| 130 | Boolean platform | `{"platform": true}` | Zod validation error | `z.string()` rejects booleans. |
| 131 | Array platform | `{"platform": ["windows"]}` | Zod validation error | `z.string()` rejects arrays. |
| 132 | Object platform | `{"platform": {}}` | Zod validation error | `z.string()` rejects objects. |
| 133 | Null platform | `{"platform": null}` | Zod validation error | `z.string()` rejects null. |

### Edge Cases — General

| # | Scenario | JSON params | Expected result | Notes |
|---|----------|-------------|-----------------|-------|
| 134 | Call when editor disconnected | `{"platform": "windows"}` | Connection error | Standard disconnected behavior. |
| 135 | Same platform twice | `{"platform": "windows"}` (×2) | Same command both times (idempotent) | Read-only; should return identical results. |
| 136 | Call with extra key | `{"platform": "windows", "extra": 123}` | Success (extra key ignored by Zod) | Only `platform` is in schema. |
| 137 | Very long platform string | `{"platform": "w".repeat(1024)}` | Passes Zod; Godot may reject | No max length constraint in schema. |
| 138 | Platform with special characters | `{"platform": "win; rm -rf /"}` | Passes Zod; Godot should sanitize or reject | Security edge case — command injection risk. |
| 139 | Platform with slashes | `{"platform": "../../windows"}` | Passes Zod; Godot should reject or sanitize | Path traversal attempt. |

---

## Cross-Tool Integration Scenarios

These scenarios test interactions between multiple build config tools in realistic workflows.

| # | Scenario | Steps | Expected result | Notes |
|---|----------|-------|-----------------|-------|
| 140 | Full build configuration workflow | 1. `get_build_settings` (read current) 2. `set_build_configuration` → release 3. `set_scripting_backend` → gdscript 4. `set_export_filter` → all_resources 5. `set_custom_features` → ['demo'] 6. `set_debug_options` → debug_build: false, optimize: true 7. `validate_build_settings` 8. `get_build_command` → windows 9. `get_build_settings` (verify) | Each step succeeds; final read reflects all changes | End-to-end release configuration. |
| 141 | C# build pipeline setup | 1. `set_scripting_backend` → csharp 2. `set_build_configuration` → development 3. `set_debug_options` → release_debug: true 4. `validate_build_settings` 5. `get_build_command` → linux | Each step succeeds; C# development build | C# development configuration. |
| 142 | Web export setup | 1. `set_export_filter` → selected_resources 2. `set_custom_features` → ['web', 'wasm'] 3. `set_debug_options` → optimize: true 4. `get_build_command` → web | Each step succeeds; web export ready | Web-specific feature tags and export. |
| 143 | Reset to defaults workflow | 1. Set non-default values across all tools 2. Reset each to default: `set_build_configuration` (no args) 3. `set_scripting_backend` (no args) 4. `set_export_filter` (no args) 5. `set_custom_features` (no args) 6. `get_build_settings` (verify defaults) | All tools return to defaults | Default behavior verification. |
| 144 | Read-after-write consistency | 1. `get_build_settings` → save result A 2. `set_build_configuration` → release 3. `get_build_settings` → result B should differ from A 4. `set_build_configuration` → debug 5. `get_build_settings` → result C should match A | A != B; A == C | Write operations are reflected in reads. |
| 145 | Validation after each config change | 1. `validate_build_settings` → baseline 2. `set_custom_features` → ['test'] 3. `validate_build_settings` → may differ 4. `set_debug_options` → debug_build: true 5. `validate_build_settings` → may differ | Validation reflects config changes | Each mutation potentially changes validation results. |

---

## Summary

| Tool | Parameter Count | Required | Zod Types | Bridge Command |
|------|----------------|----------|-----------|----------------|
| `get_build_settings` | 0 | 0 | — | `build_config/get_settings` |
| `set_build_configuration` | 1 | 0 | `enum('debug', 'release', 'development')` | `build_config/set_configuration` |
| `set_scripting_backend` | 1 | 0 | `enum('gdscript', 'csharp')` | `build_config/set_scripting_backend` |
| `set_export_filter` | 1 | 0 | `enum('all_resources', 'selected_resources')` | `build_config/set_export_filter` |
| `set_custom_features` | 1 | 0 | `string[]` | `build_config/set_custom_features` |
| `set_debug_options` | 3 | 0 | `boolean`, `boolean`, `boolean` | `build_config/set_debug_options` |
| `validate_build_settings` | 0 | 0 | — | `build_config/validate` |
| `get_build_command` | 1 | 1 | `string` | `build_config/get_build_command` |

**Total test scenarios:** 145  
**Happy path scenarios:** 28  
**Edge case scenarios:** 52  
**Enum/invalid value scenarios:** 50  
**Integration scenarios:** 6  
**Summary rows:** 1
