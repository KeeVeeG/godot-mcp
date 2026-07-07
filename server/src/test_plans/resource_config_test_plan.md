# Test Plan: `server/src/tools/resource_config.ts`

**Module**: Resource Configuration Tools  
**Source file**: `server/src/tools/resource_config.ts`  
**Command route prefix**: `resource_config/`  
**Total tools**: 6  
**Date**: 2026-07-08

---

## Tool Inventory

| # | Tool Name | Route Suffix | Params | Description |
|---|-----------|-------------|--------|-------------|
| 1 | `get_resource_types` | `get_types` | _(none)_ | Get all registered resource types in the engine |
| 2 | `get_resource_properties` | `get_properties` | `type` (string, required) | Get all serializable properties for a resource type |
| 3 | `create_resource_from_template` | `create_from_template` | `type` (string, required), `template` (string, optional), `path` (string, required) | Create a new resource file from template or defaults |
| 4 | `import_resource` | `import` | `path` (string, required), `settings` (record, optional) | Import a file as a resource |
| 5 | `get_resource_import_settings` | `get_resource_import_settings` | `path` (string, required) | Get current import settings for a resource |
| 6 | `set_resource_import_settings` | `set_resource_import_settings` | `path` (string, required), `settings` (record, required) | Update import settings and reimport |

---

## 1. `get_resource_types`

**Route**: `resource_config/get_types`  
**Parameters**: _(none)_  
**Input schema**: `{}`  
**Description**: Get all registered resource types in the engine.

### Behavior

- Queries the Godot engine for every registered `Resource` subclass.
- Returns a list of type names (e.g., `Texture2D`, `Material`, `AudioStream`, `PackedScene`, `Theme`, `StyleBoxFlat`, `Shader`, etc.).
- No parameters needed — it is a global query against the engine's type registry.
- Result is forwarded directly from `callGodot(bridge, 'resource_config/get_types')`.

### Happy Path Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| RT.01 | Call with no arguments | `{}` | Returns a JSON array or object listing all registered resource type names. Must include common types: `Texture2D`, `StandardMaterial3D`, `Theme`, `StyleBoxFlat`, `GDScript`, `PackedScene`. |
| RT.02 | Call when engine has custom resources | `{}` | Custom user-defined resource classes (via `class_name`) should appear alongside built-in types. |

### Edge Case Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| RT.03 | Call before engine is fully initialized | `{}` | Should either return empty list or an error indicating engine not ready. Must not crash or hang. |
| RT.04 | Call with unexpected extra params | `{ "foo": "bar" }` | Extra params should be ignored (Zod schema is `{}`, so they may be stripped or silently passed — verify behavior). Should still return type list. |
| RT.05 | Large result set (> 500 types) | `{}` | Response should be returned without truncation or timeout. Verify serialization handles large payloads. |

---

## 2. `get_resource_properties`

**Route**: `resource_config/get_properties`  
**Parameters**:

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `string` | **Yes** | Resource type name (e.g. `'Texture2D'`, `'AudioStream'`, `'PackedScene'`) |

**Description**: Get all serializable properties for a resource type with their types.

### Behavior

- Takes a single required `type` parameter — the class name of a Godot resource type.
- Returns the list of all serializable (exported) properties for that type, including property name, data type, default value, and any hints (enum values, ranges, etc.).
- For inherited types, should include properties from all ancestor classes (e.g., `StandardMaterial3D` should include properties from `Material` and `Resource` base classes).
- Validation: `type` is a Zod `z.string()` — any non-string input (number, object, null, undefined) should fail schema validation before reaching the bridge.

### Happy Path Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| RP.01 | Known built-in resource type | `{ "type": "StandardMaterial3D" }` | Returns properties including `albedo_color`, `metallic`, `roughness`, `emission`, etc. Each property should include its type info and default value. |
| RP.02 | Texture resource type | `{ "type": "Texture2D" }` | Returns texture-related properties. Should show properties inherited from `Texture` and `Resource`. |
| RP.03 | Audio resource type | `{ "type": "AudioStreamMP3" }` | Returns audio-specific properties. |
| RP.04 | Theme resource type | `{ "type": "Theme" }` | Returns theme properties. Should include inherited `Resource` properties. |
| RP.05 | StyleBox resource type | `{ "type": "StyleBoxFlat" }` | Returns StyleBox properties like `bg_color`, `border_width_*`, `corner_radius_*`, etc. |
| RP.06 | Custom user-defined resource type | `{ "type": "MyCustomResource" }` | Should return all `@export` annotated properties from the custom resource class. |
| RP.07 | Resource with enum properties | `{ "type": "BaseMaterial3D" }` | Properties with enum values (e.g., `transparency`) should include the list of valid enum options (hint_string). |

### Edge Case Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| RP.08 | Missing `type` parameter | `{}` | Schema validation should fail. Error message should indicate `type` is required. |
| RP.09 | `type` is empty string | `{ "type": "" }` | Should return an error from the bridge (type not found) or empty property list. Must not crash. |
| RP.10 | `type` is a number | `{ "type": 42 }` | Schema validation should fail (expected string, got number). |
| RP.11 | `type` is null | `{ "type": null }` | Schema validation should fail (expected string, got null). |
| RP.12 | Nonexistent type name | `{ "type": "NonExistentResourceXYZ" }` | Should return an error from the bridge indicating the type is not registered. Must not crash. |
| RP.13 | Type name with wrong casing | `{ "type": "standardmaterial3d" }` | Godot class names are case-sensitive. Should either return an error or not find the type. Confirm behavior. |
| RP.14 | Type name is a non-resource class (e.g., Node) | `{ "type": "Node2D" }` | Should return an error or empty list — `Node2D` is not a `Resource` subclass. |
| RP.15 | Type with very many properties (> 100) | `{ "type": "SomeComplexResource" }` | Response should include all properties without truncation. |
| RP.16 | Extra unexpected parameters | `{ "type": "Theme", "extra": true }` | Extra params should be ignored. Should still return Theme properties. |
| RP.17 | Unicode/special chars in type name | `{ "type": "Typé\nàme" }` | Should be treated as invalid type by the bridge. Must not cause injection or crash. |

---

## 3. `create_resource_from_template`

**Route**: `resource_config/create_from_template`  
**Parameters**:

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `string` | **Yes** | Resource type to create (e.g. `'StandardMaterial3D'`, `'Theme'`) |
| `template` | `string` | No | Template resource path to copy from |
| `path` | `string` (`ResourcePath`) | **Yes** | Output path (e.g. `'res://materials/my_material.tres'`) |

**Description**: Create a new resource file from a template or with default values.

### Behavior

- Creates a new resource file on disk at the specified `path`.
- The `type` determines what kind of resource is created (sets the class in the `.tres`/`.res` header).
- If `template` is provided, the new resource copies the template's property values instead of using defaults.
- If `template` is omitted, the resource is created with engine-default values for all properties.
- The file extension in `path` should match the resource type convention (`.tres` for text resources, `.res` for binary).
- `path` uses `ResourcePath` schema — validated as a string with the description "Resource file path (e.g. 'res://assets/theme.tres')".

### Happy Path Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| CT.01 | Create with type and path only (no template) | `{ "type": "StandardMaterial3D", "path": "res://materials/test_mat.tres" }` | Creates a new `StandardMaterial3D` resource at the specified path with default values (gray albedo, metallic=0, roughness=1, etc.). File exists on disk after call. |
| CT.02 | Create with type, path, and template | `{ "type": "StandardMaterial3D", "path": "res://materials/copy_mat.tres", "template": "res://materials/source_mat.tres" }` | Creates a new material that is a copy of the template material. All properties match the template. |
| CT.03 | Create a Theme resource | `{ "type": "Theme", "path": "res://themes/my_theme.tres" }` | Creates a new empty Theme resource at the specified path. |
| CT.04 | Create a StyleBoxFlat resource | `{ "type": "StyleBoxFlat", "path": "res://styles/my_style.tres" }` | Creates a StyleBoxFlat with default properties. |
| CT.05 | Create with template of a different type | `{ "type": "StandardMaterial3D", "path": "res://materials/test.tres", "template": "res://themes/source_theme.tres" }` | Should either fail with a type mismatch error or copy compatible properties only. Verify actual behavior. |
| CT.06 | Create in a nested directory that exists | `{ "type": "Theme", "path": "res://themes/sub/folder/my_theme.tres" }` | Should succeed if parent directories exist. |

### Edge Case Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| CT.07 | Missing `type` | `{ "path": "res://test.tres" }` | Schema validation error — `type` is required. |
| CT.08 | Missing `path` | `{ "type": "StandardMaterial3D" }` | Schema validation error — `path` is required. |
| CT.09 | Empty `type` string | `{ "type": "", "path": "res://test.tres" }` | Bridge should return an error (invalid type). |
| CT.10 | Empty `path` string | `{ "type": "Theme", "path": "" }` | Bridge should return an error (invalid path). |
| CT.11 | Path without `res://` prefix | `{ "type": "Theme", "path": "my_theme.tres" }` | Should fail — Godot paths require `res://` prefix. Verify error message clarity. |
| CT.12 | Path with invalid characters | `{ "type": "Theme", "path": "res://themes/my<>theme.tres" }` | Should fail with a file system error. Must not crash. |
| CT.13 | Path to existing file (overwrite) | `{ "type": "Theme", "path": "res://existing_file.tres" }` | Should either overwrite (destructive — confirm behavior) or return an error about existing file. |
| CT.14 | Path to a directory (not a file) | `{ "type": "Theme", "path": "res://themes/" }` | Should return an error — cannot create a resource at a directory path. |
| CT.15 | Path with `.gd` extension (wrong for resources) | `{ "type": "Theme", "path": "res://theme.gd" }` | Should probably fail or create a `.gd` file (unintended). Verify behavior matches expectations. |
| CT.16 | Template path does not exist | `{ "type": "StandardMaterial3D", "path": "res://test.tres", "template": "res://nonexistent.tres" }` | Should return an error indicating the template file was not found. |
| CT.17 | Template path is a scene (not a resource) | `{ "type": "StandardMaterial3D", "path": "res://test.tres", "template": "res://scenes/main.tscn" }` | Should fail or produce unexpected result. Verify behavior. |
| CT.18 | `type` is not a Resource subclass | `{ "type": "Node2D", "path": "res://test.tres" }` | Should fail — `Node2D` is not a resource type. |
| CT.19 | Nonexistent type | `{ "type": "FakeResourceType999", "path": "res://test.tres" }` | Should return an error from the bridge. |
| CT.20 | Path in a read-only directory | `{ "type": "Theme", "path": "res://readonly/test.tres" }` | Should return a file system error. Must not crash. |
| CT.21 | Special chars in `path` (spaces, unicode) | `{ "type": "Theme", "path": "res://themes/мой_тема.tres" }` | Should handle unicode paths if the file system supports them. Verify behavior. |
| CT.22 | Extra unexpected parameters | `{ "type": "Theme", "path": "res://test.tres", "extra": "ignored" }` | Extra params should be ignored. Resource should still be created. |

---

## 4. `import_resource`

**Route**: `resource_config/import`  
**Parameters**:

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `path` | `string` (`ResourcePath`) | **Yes** | File path to import (e.g. `'res://assets/model.fbx'`) |
| `settings` | `record<string, unknown>` | No | Optional import settings to apply during import |

**Description**: Import a file as a resource with optional import settings.

### Behavior

- Triggers Godot's import pipeline for the file at `path`.
- The file should exist on disk and be of a type Godot can import (images, audio, 3D models, fonts, etc.).
- If `settings` is provided, those settings override the default import configuration for that file type.
- After import, a `.import` file is generated/updated and the imported resource becomes available in the project.
- `settings` uses `OptionalProperties` schema — `z.record(z.unknown()).optional()`.

### Happy Path Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| IR.01 | Import a PNG texture with defaults | `{ "path": "res://assets/icon.png" }` | Triggers import of the PNG file. After completion, the texture is available. Generates/updates `icon.png.import`. |
| IR.02 | Import a texture with custom settings | `{ "path": "res://assets/icon.png", "settings": { "compress/mode": 2, "flags/filter": true } }` | Imports with specified settings. The `.import` file should reflect the custom settings. |
| IR.03 | Import an audio file (OGG/MP3) | `{ "path": "res://sounds/music.ogg" }` | Imports audio with default settings. Audio stream resource is created. |
| IR.04 | Import a 3D model (FBX/GLTF/OBJ) | `{ "path": "res://models/character.glb" }` | Imports the 3D model. May create multiple sub-resources (materials, meshes, animations). |
| IR.05 | Import with empty settings object | `{ "path": "res://assets/icon.png", "settings": {} }` | Should behave identically to calling without `settings` (use defaults). |
| IR.06 | Reimport a previously imported file | `{ "path": "res://assets/icon.png", "settings": { "compress/mode": 3 } }` | Updates import settings and reimports. `.import` file reflects new settings. |

### Edge Case Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| IR.07 | Missing `path` | `{}` | Schema validation error — `path` is required. |
| IR.08 | `path` is empty string | `{ "path": "" }` | Bridge should return an error (invalid path). |
| IR.09 | File does not exist at `path` | `{ "path": "res://nonexistent.png" }` | Should return an error indicating the file was not found. |
| IR.10 | File is not importable (e.g., `.txt`, `.pdf`) | `{ "path": "res://docs/readme.txt" }` | Should return an error or warning — Godot cannot import arbitrary file types. |
| IR.11 | `settings` with invalid key names | `{ "path": "res://assets/icon.png", "settings": { "invalid_key_xyz": true } }` | Should be ignored (unknown import keys are typically silently dropped by Godot) or return a warning. Must not crash. |
| IR.12 | `settings` with wrong value types | `{ "path": "res://assets/icon.png", "settings": { "compress/mode": "not_a_number" } }` | Should return an error from Godot's import system (type mismatch). |
| IR.13 | `settings` as a JSON string instead of object | `{ "path": "res://assets/icon.png", "settings": "{\"mode\": 2}" }` | Zod should reject — `settings` expects `record`, not `string`. Schema validation error. |
| IR.14 | `settings` as null | `{ "path": "res://assets/icon.png", "settings": null }` | Zod should reject — `null` is not a valid record. |
| IR.15 | Very large `settings` object (> 100 keys) | `{ "path": "res://assets/icon.png", "settings": { ...many keys... } }` | Should not hang or crash. Extra keys should be ignored. |
| IR.16 | Path with `res://` missing | `{ "path": "Assets/icon.png" }` | Should fail — paths must use `res://` prefix. |
| IR.17 | Path is a directory | `{ "path": "res://assets/" }` | Should return an error — cannot import a directory. |
| IR.18 | Path with unicode characters | `{ "path": "res://assets/иконка.png" }` | Should import normally if the file exists. |

---

## 5. `get_resource_import_settings`

**Route**: `resource_config/get_resource_import_settings`  
**Parameters**:

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `path` | `string` (`ResourcePath`) | **Yes** | Resource file path (e.g. `'res://assets/theme.tres'`) |

**Description**: Get the current import settings for a resource file.

### Behavior

- Reads the `.import` file associated with the resource at `path`.
- Returns all import settings for that resource: compression mode, filter flags, mipmap settings, etc.
- The returned structure depends on the resource type (texture settings differ from audio settings).
- Should work for any resource that was imported into the project (has a `.import` file).

### Happy Path Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| GI.01 | Get settings for an imported texture | `{ "path": "res://assets/icon.png" }` | Returns texture import settings: `compress/mode`, `flags/filter`, `flags/mipmaps`, `flags/repeat`, etc. |
| GI.02 | Get settings for an imported audio file | `{ "path": "res://sounds/music.ogg" }` | Returns audio import settings: `compress/mode`, loop settings, etc. |
| GI.03 | Get settings for an imported 3D model | `{ "path": "res://models/character.glb" }` | Returns model import settings: animation import, material generation, mesh compression, etc. |
| GI.04 | Get settings for a file with custom import settings | `{ "path": "res://assets/custom_import.png" }` | Returns the custom settings that were previously applied. Values should match what was set. |

### Edge Case Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| GI.05 | Missing `path` | `{}` | Schema validation error — `path` is required. |
| GI.06 | Empty `path` string | `{ "path": "" }` | Bridge should return an error (invalid path). |
| GI.07 | Path does not exist | `{ "path": "res://nonexistent.png" }` | Should return an error indicating the file/import settings were not found. |
| GI.08 | Path is a `.import` file directly | `{ "path": "res://assets/icon.png.import" }` | Verify behavior — should it read the raw `.import` content or fail because it expects the source file path? |
| GI.09 | Path to a `.tres` resource (not imported, native) | `{ "path": "res://themes/my_theme.tres" }` | `.tres` files are native Godot resources, not imported. Should return empty or an error. |
| GI.10 | Path to a `.gd` script file | `{ "path": "res://scripts/player.gd" }` | Scripts aren't imported resources. Should return empty or an error. |
| GI.11 | Path without `res://` prefix | `{ "path": "Assets/icon.png" }` | Should fail — missing `res://` prefix. |
| GI.12 | Path is a directory | `{ "path": "res://assets/" }` | Should return an error — cannot get import settings for a directory. |
| GI.13 | File exists but was never imported (no `.import` file) | `{ "path": "res://assets/raw_data.bin" }` | Should return an error or empty settings — no import metadata exists for this file. |
| GI.14 | Extra unexpected parameters | `{ "path": "res://assets/icon.png", "extra": "value" }` | Extra params should be ignored. Should still return import settings. |

---

## 6. `set_resource_import_settings`

**Route**: `resource_config/set_resource_import_settings`  
**Parameters**:

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `path` | `string` (`ResourcePath`) | **Yes** | Resource file path |
| `settings` | `record<string, unknown>` | **Yes** | Import settings to apply |

**Description**: Update import settings for a resource file and reimport.

### Behavior

- Writes new import settings to the `.import` file for the resource at `path`.
- Triggers a reimport of the file with the new settings.
- The `settings` parameter is required (uses `Properties` schema — `z.record(z.unknown()).describe(...)` — no `.optional()`).
- After completion, the imported resource reflects the new settings.

### Happy Path Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| SI.01 | Change texture compression mode | `{ "path": "res://assets/icon.png", "settings": { "compress/mode": 2 } }` | Updates compression mode and reimports. Subsequent `get_resource_import_settings` should return mode=2. |
| SI.02 | Change texture filter flag | `{ "path": "res://assets/icon.png", "settings": { "flags/filter": true } }` | Enables filtering and reimports. |
| SI.03 | Change multiple settings at once | `{ "path": "res://assets/icon.png", "settings": { "compress/mode": 3, "flags/filter": true, "flags/mipmaps": true } }` | All settings are applied and the file is reimported once. |
| SI.04 | Update audio loop setting | `{ "path": "res://sounds/music.ogg", "settings": { "edit/loop_mode": 1 } }` | Sets loop mode and reimports audio. |
| SI.05 | Update 3D model import settings | `{ "path": "res://models/character.glb", "settings": { "meshes/compress": true } }` | Applies mesh compression setting and reimports. |
| SI.06 | Set settings to same as current (no-op reimport) | `{ "path": "res://assets/icon.png", "settings": { "compress/mode": 0 } }` | Setting is already mode=0. Should either reimport (no change) or return a no-op success. Verify behavior. |

### Edge Case Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| SI.07 | Missing `path` | `{ "settings": { "mode": 2 } }` | Schema validation error — `path` is required. |
| SI.08 | Missing `settings` | `{ "path": "res://assets/icon.png" }` | Schema validation error — `settings` is required (uses `Properties`, not `OptionalProperties`). |
| SI.09 | Empty `settings` object | `{ "path": "res://assets/icon.png", "settings": {} }` | Should either reimport with no changes (no-op) or return success. Verify behavior. |
| SI.10 | `settings` is null | `{ "path": "res://assets/icon.png", "settings": null }` | Schema validation error — `null` is not a valid record. |
| SI.11 | `settings` is a JSON string | `{ "path": "res://assets/icon.png", "settings": "{\"mode\":2}" }` | Schema validation error — expected object, got string. |
| SI.12 | Path does not exist | `{ "path": "res://nonexistent.png", "settings": { "mode": 2 } }` | Should return an error — cannot set import settings for nonexistent file. |
| SI.13 | Path is a native resource (`.tres`) | `{ "path": "res://themes/my_theme.tres", "settings": { "mode": 2 } }` | `.tres` files aren't imported. Should return an error. |
| SI.14 | Invalid setting key for resource type | `{ "path": "res://assets/icon.png", "settings": { "audio/loop": true } }` | Texture import doesn't have audio settings. Should be ignored or return a warning. |
| SI.15 | Invalid setting value type | `{ "path": "res://assets/icon.png", "settings": { "compress/mode": "high" } }` | Expected number, got string. Godot should reject or convert. Verify behavior. |
| SI.16 | Empty `path` string | `{ "path": "", "settings": { "mode": 2 } }` | Bridge should return an error (invalid path). |
| SI.17 | Path without `res://` prefix | `{ "path": "Assets/icon.png", "settings": { "mode": 2 } }` | Should fail — missing `res://` prefix. |
| SI.18 | Very large settings object (> 200 keys) | `{ "path": "res://assets/icon.png", "settings": { ...many keys... } }` | Should not hang or crash. Extra keys should be ignored. |
| SI.19 | File is currently being imported (race condition) | `{ "path": "res://assets/icon.png", "settings": { "compress/mode": 2 } }` | Should either queue the reimport or return a busy error. Must not corrupt the `.import` file. |
| SI.20 | Settings with nested objects/arrays | `{ "path": "res://models/character.glb", "settings": { "nodes/root_type": "RigidBody3D", "nodes/root_bone": "Hips" } }` | Should handle nested/complex import settings correctly (common for 3D models). |

---

## Cross-Tool Integration Scenarios

| ID | Scenario | Steps | Expected Result |
|----|----------|-------|-----------------|
| INT.01 | Create resource then read its properties | 1. `create_resource_from_template` with type=`"StandardMaterial3D"`, path=`"res://materials/test.tres"`; 2. `get_resource_properties` with type=`"StandardMaterial3D"` | Created file exists. Properties query returns the full property list for the type. |
| INT.02 | Import then read import settings | 1. `import_resource` with path and custom settings; 2. `get_resource_import_settings` with same path | Settings returned should match what was passed to import. |
| INT.03 | Import then change import settings | 1. `import_resource` with defaults; 2. `set_resource_import_settings` with new settings; 3. `get_resource_import_settings` | Settings should reflect the latest `set_resource_import_settings` values. |
| INT.04 | Create resource from template then verify it exists | 1. `create_resource_from_template` with template; 2. `get_resource_types` — verify the created type appears | The created resource should exist on disk. The type should already exist in the type list (it was there before creation). |
| INT.05 | Round-trip: set → get → set again | 1. `set_resource_import_settings` with mode=2; 2. `get_resource_import_settings` → verify mode=2; 3. `set_resource_import_settings` with mode=3; 4. `get_resource_import_settings` → verify mode=3 | Each set/get pair should be consistent. |

---

## Schema Validation Summary

All tools use Zod schemas for input validation. The following validation rules apply:

| Tool | Required Params | Optional Params | Zod Refinement |
|------|----------------|-----------------|----------------|
| `get_resource_types` | _(none)_ | _(none)_ | `{}` — no validation needed |
| `get_resource_properties` | `type: z.string()` | _(none)_ | `type` must be a string; non-string values rejected |
| `create_resource_from_template` | `type: z.string()`, `path: ResourcePath` | `template: z.string().optional()` | `path` uses `ResourcePath` schema (string with description); `template` is optional string |
| `import_resource` | `path: ResourcePath` | `settings: OptionalProperties` | `settings` is `z.record(z.unknown()).optional()` — object if present, null rejected |
| `get_resource_import_settings` | `path: ResourcePath` | _(none)_ | `path` must be a string |
| `set_resource_import_settings` | `path: ResourcePath`, `settings: Properties` | _(none)_ | `settings` is `z.record(z.unknown()).describe(...)` — required, not optional |

### Schema Error Categories

1. **Missing required param**: Zod throws validation error before the bridge is called. Error format: "Required" or similar.
2. **Wrong type**: e.g., `type` receives a number — Zod rejects. Error format: "Expected string, received number".
3. **Null for required field**: Zod rejects `null` for non-nullable fields.
4. **Extra params**: Zod's default behavior strips unknown keys (passthrough depends on configuration). Verify that extra/unexpected params do not cause failures.

---

## GDScript Bridge Endpoints

Each tool maps to a GDScript command module route. The following endpoints are expected in the Godot plugin:

| Server Tool | GDScript Route (string literal) |
|-------------|-------------------------------|
| `get_resource_types` | `"resource_config/get_types"` |
| `get_resource_properties` | `"resource_config/get_properties"` |
| `create_resource_from_template` | `"resource_config/create_from_template"` |
| `import_resource` | `"resource_config/import"` |
| `get_resource_import_settings` | `"resource_config/get_resource_import_settings"` |
| `set_resource_import_settings` | `"resource_config/set_resource_import_settings"` |

### Bridge Error Propagation

All tools use `callGodot(bridge, route, args?)`. The bridge may return errors for:
- **Connection failure**: Godot editor not connected or bridge timeout.
- **Command not found**: The GDScript handler for the route doesn't exist in the plugin.
- **Execution error**: The GDScript handler threw an exception (e.g., invalid path, type not found, file I/O error).
- **Timeout**: The GDScript handler took too long to respond.

Test plans should verify that bridge errors are properly surfaced to the MCP client with descriptive messages.

---

## Performance & Stress Considerations

| ID | Scenario | Concern |
|----|----------|---------|
| PERF.01 | `get_resource_types` called repeatedly (100 times) | Should not degrade or leak memory. Response time should be consistent. |
| PERF.02 | `create_resource_from_template` with large template file | Template with many properties should not cause timeout. |
| PERF.03 | `import_resource` with large 3D model (> 100MB) | Import may take significant time. Verify timeout handling — the bridge may need a longer timeout for large imports. |
| PERF.04 | `set_resource_import_settings` triggering reimport of large asset | Reimport may be slow. Verify the client is informed of progress or the call handles the delay. |
| PERF.05 | Concurrent calls: `get_resource_properties` for 10 different types simultaneously | Should not cause race conditions or mixed-up responses. |

---

## Test Execution Priority

**P0 (Must pass — core functionality)**:
- RT.01, RP.01, RP.08, CT.01, CT.07, CT.08, IR.01, IR.07, GI.01, GI.05, SI.01, SI.07, SI.08

**P1 (Should pass — important edge cases)**:
- RT.03, RP.09, RP.12, CT.03, CT.09, CT.10, CT.11, CT.16, IR.03, IR.09, GI.07, GI.09, SI.09, SI.10, SI.12, SI.13

**P2 (Nice to have — completeness)**:
- All remaining scenarios

---

## Notes

1. All `path` parameters use the `ResourcePath` schema — a `z.string()` with description. There is no regex validation for the `res://` prefix at the Zod level; validation happens in the GDScript bridge.
2. `settings` in `set_resource_import_settings` uses `Properties` (required), while in `import_resource` it uses `OptionalProperties` (optional). This is intentional — you can import with defaults but setting import settings always requires explicit settings.
3. The `create_resource_from_template` tool's `template` parameter is the only optional parameter in this module that isn't a settings record.
4. Resource type names in Godot are case-sensitive (e.g., `StandardMaterial3D`, not `standardmaterial3d`).
5. Import settings keys follow Godot's import plugin conventions (e.g., `compress/mode`, `flags/filter`). The exact keys vary by resource type.
