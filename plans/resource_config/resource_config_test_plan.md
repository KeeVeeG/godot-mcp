# Resource Configuration Test Plan

> **Source file:** `server/src/tools/resource_config.ts`
> **Shared types:** `server/src/tools/shared-types.ts`
> **Tools covered:** 6 (`get_resource_types`, `get_resource_properties`, `create_resource_from_template`, `import_resource`, `get_resource_import_settings`, `set_resource_import_settings`)
> **Godot bridge method prefix:** `resource_config/`
> **Handler pattern:** All tools call `callGodot(bridge, 'resource_config/<action>', args)`
> **Generated:** 2026-07-08

---

## Shared Type Definitions

| Import | Zod Schema | Constraints |
|--------|-----------|-------------|
| `ResourcePath` | `z.string()` | No structural constraints — described as "Resource file path (e.g. 'res://assets/theme.tres')" |
| `Properties` | `z.record(z.unknown())` | **Required.** Dictionary of property key-value pairs. Values can be any type. |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | **Optional.** Same as `Properties` but may be omitted. |
| `z` | Zod namespace | Used directly for `z.string()`, `z.string().optional()`, etc. |

### Parameter Summary

| Tool | Param | Type | Required | Default | Enum/Choices | Notes |
|------|-------|------|----------|---------|--------------|-------|
| `get_resource_types` | *(none)* | — | — | — | — | Takes no input |
| `get_resource_properties` | `type` | `string` | ✅ yes | — | — | Resource type name (e.g. 'Texture2D', 'AudioStream', 'PackedScene') |
| `create_resource_from_template` | `type` | `string` | ✅ yes | — | — | Resource type to create (e.g. 'StandardMaterial3D', 'Theme') |
| | `path` | `ResourcePath` (string) | ✅ yes | — | — | Output path (e.g. 'res://materials/my_material.tres') |
| | `template` | `string` | no | — | — | Template resource path to copy from |
| `import_resource` | `path` | `ResourcePath` (string) | ✅ yes | — | — | File path to import (e.g. 'res://assets/model.fbx') |
| | `settings` | `record<string, unknown>` | no | — | — | Optional import settings key-value pairs |
| `get_resource_import_settings` | `path` | `ResourcePath` (string) | ✅ yes | — | — | Resource file path |
| `set_resource_import_settings` | `path` | `ResourcePath` (string) | ✅ yes | — | — | Resource file path |
| | `settings` | `record<string, unknown>` | ✅ yes | — | — | Import settings to apply (required) |

---

## Tool: `get_resource_types`

### Schema

```typescript
{
  description: 'Get all registered resource types in the engine',
  inputSchema: {},
}
```

### Handler

```typescript
async () => callGodot(bridge, 'resource_config/get_types')
```

### Tool Behavior
Returns a list of all resource types registered in the Godot engine. No parameters are needed — this is a read-only introspection tool. The response should be a JSON array of type names (strings) like `"Texture2D"`, `"AudioStream"`, `"PackedScene"`, etc.

### Test Scenarios

#### Scenario 1: Happy path — get all registered resource types
- **Description:** Call with no arguments to retrieve the full list of resource types available in the engine.
- **Params:** `{}`
- **Expected result:** Returns a JSON array of resource type name strings. Array should be non-empty and include well-known types like `"Texture"`, `"Material"`, `"Shader"`, `"AudioStream"`, `"Font"`, etc. No error.
- **Notes:** No prerequisites — works on any Godot project with the MCP plugin active.

#### Scenario 2: Call with unexpected extra params
- **Description:** Verify the tool ignores extraneous parameters since `inputSchema` is empty.
- **Params:** `{ "foo": "bar", "baz": 123 }`
- **Expected result:** Should succeed identically to Scenario 1. Extraneous params are stripped/ignored by the empty Zod schema.
- **Notes:** Tests robustness against clients that may send extra fields.

#### Scenario 3: Call with no arguments object at all
- **Description:** Call the tool with an undefined/null args value.
- **Params:** `undefined` or `null`
- **Expected result:** Should succeed — the empty schema `{}` accepts any input and produces an empty object.
- **Notes:** Validates the handler can handle a missing args object.

---

## Tool: `get_resource_properties`

### Schema

```typescript
{
  description: 'Get all serializable properties for a resource type with their types',
  inputSchema: {
    type: z.string().describe("Resource type name (e.g. 'Texture2D', 'AudioStream', 'PackedScene')"),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'resource_config/get_properties', args as Record<string, unknown>)
```

### Tool Behavior
Given a resource type name, returns all serializable properties for that type along with their types. This is the counterpart to `get_node_properties` — it introspects the resource type system rather than nodes. Response should include an object mapping property names to type information.

### Test Scenarios

#### Scenario 1: Happy path — get properties for a well-known resource type
- **Description:** Query properties for `Texture2D`, a common resource type.
- **Params:** `{ "type": "Texture2D" }`
- **Expected result:** Returns a JSON object containing properties and their types. Should include properties like `flags`, `resource_local_to_scene`, `resource_name`, `resource_path`, etc. No error.
- **Notes:** `Texture2D` exists in every Godot project by default.

#### Scenario 2: Happy path — get properties for `AudioStream`
- **Description:** Query properties for the `AudioStream` resource type.
- **Params:** `{ "type": "AudioStream" }`
- **Expected result:** Returns property metadata for the AudioStream type. Properties may include length-related fields.
- **Notes:** Tests a different resource type category (audio).

#### Scenario 3: Happy path — get properties for `PackedScene`
- **Description:** Query properties for `PackedScene` — a reference type.
- **Params:** `{ "type": "PackedScene" }`
- **Expected result:** Returns property metadata for PackedScene resources. Should include at minimum the standard `Resource` inherited properties.
- **Notes:** Tests a core engine resource type.

#### Scenario 4: Happy path — get properties for `Theme`
- **Description:** Query properties for the `Theme` resource type.
- **Params:** `{ "type": "Theme" }`
- **Expected result:** Returns Theme-specific property metadata including font sizes, colors, styleboxes.
- **Notes:** Tests a complex composite resource type.

#### Scenario 5: Happy path — get properties for `StandardMaterial3D`
- **Description:** Query properties for a 3D material type.
- **Params:** `{ "type": "StandardMaterial3D" }`
- **Expected result:** Returns material properties including `albedo_color`, `metallic`, `roughness`, `emission`, etc.
- **Notes:** Tests a resource type with many sub-properties.

#### Scenario 6: Missing required parameter — `type`
- **Description:** Omit the required `type` parameter entirely.
- **Params:** `{}`
- **Expected result:** Zod validation error — `type` is required (z.string() without .optional()).
- **Notes:** Type required by Zod schema validation.

#### Scenario 7: Empty string for `type`
- **Description:** Call with an empty string as the type name.
- **Params:** `{ "type": "" }`
- **Expected result:** Zod validation passes (empty string is a valid string). Godot-side handler likely returns an error for unknown/empty resource type.
- **Notes:** Tests boundary condition — Zod's `z.string()` accepts empty strings.

#### Scenario 8: Non-existent resource type name
- **Description:** Query properties for a type name that doesn't correspond to any registered resource type.
- **Params:** `{ "type": "NonExistentResourceTypeXYZ" }`
- **Expected result:** Godot-side error — the resource type is not found. Should not crash.
- **Notes:** Tests error handling for invalid type names.

#### Scenario 9: Very long type name
- **Description:** Call with an excessively long string as type name.
- **Params:** `{ "type": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }` (256 chars)
- **Expected result:** Godot-side error — the type name is not found. Should handle gracefully.
- **Notes:** Tests robustness against oversized input.

#### Scenario 10: Invalid type for `type` — non-string
- **Description:** Call with `type` as a number instead of string.
- **Params:** `{ "type": 42 }`
- **Expected result:** Zod validation error — expected string, received number.
- **Notes:** Type validation.

#### Scenario 11: Invalid type for `type` — boolean
- **Description:** Call with `type` as a boolean.
- **Params:** `{ "type": true }`
- **Expected result:** Zod validation error — expected string, received boolean.
- **Notes:** Type validation.

#### Scenario 12: Invalid type for `type` — object
- **Description:** Call with `type` as an object.
- **Params:** `{ "type": { "name": "Texture2D" } }`
- **Expected result:** Zod validation error — expected string, received object.
- **Notes:** Type validation.

---

## Tool: `create_resource_from_template`

### Schema

```typescript
{
  description: 'Create a new resource file from a template or with default values',
  inputSchema: {
    type: z.string().describe("Resource type to create (e.g. 'StandardMaterial3D', 'Theme')"),
    template: z.string().optional().describe('Template resource path to copy from'),
    path: ResourcePath.describe("Output path (e.g. 'res://materials/my_material.tres')"),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'resource_config/create_from_template', args as Record<string, unknown>)
```

### Tool Behavior
Creates a new resource file at the specified `path`. When a `template` is provided, copies from that existing resource; otherwise, creates the resource with engine defaults for the given `type`. The output file is saved to disk at `path`. Returns success confirmation.

### Test Scenarios

#### Scenario 1: Happy path — create with only required params (no template)
- **Description:** Create a new `StandardMaterial3D` resource at a specific path using engine defaults.
- **Params:** `{ "type": "StandardMaterial3D", "path": "res://test_output/new_material.tres" }`
- **Expected result:** New `.tres` file created at `res://test_output/new_material.tres`. Resource has default StandardMaterial3D properties. Success response.
- **Notes:** The file path must be within the project's `res://` namespace. The directory should exist or Godot may create it.

#### Scenario 2: Happy path — create with template
- **Description:** Create a new resource by copying from an existing template resource.
- **Params:** `{ "type": "StandardMaterial3D", "path": "res://test_output/cloned_material.tres", "template": "res://assets/existing_material.tres" }`
- **Expected result:** New resource created at the output path with properties copied from the template. Success response.
- **Notes:** Requires an existing `.tres` file at the `template` path. If the template file doesn't exist, Godot should error.

#### Scenario 3: Happy path — create a Theme resource
- **Description:** Create a `Theme` resource type using defaults.
- **Params:** `{ "type": "Theme", "path": "res://test_output/new_theme.tres" }`
- **Expected result:** New Theme `.tres` file created at output path with default theme settings.
- **Notes:** Tests a different resource type — Theme handles multiple sub-resources (colors, fonts, styleboxes).

#### Scenario 4: Happy path — create a ShaderMaterial via template
- **Description:** Create a `ShaderMaterial` resource by copying from a template shader material.
- **Params:** `{ "type": "ShaderMaterial", "path": "res://test_output/my_shader_mat.tres", "template": "res://materials/some_shader_material.tres" }`
- **Expected result:** New ShaderMaterial created at output path with shader and parameter values from template.
- **Notes:** Tests ShaderMaterial creation with template inheritance.

#### Scenario 5: Happy path — create with type "StyleBoxFlat"
- **Description:** Create a `StyleBoxFlat` resource (UI styling type).
- **Params:** `{ "type": "StyleBoxFlat", "path": "res://test_output/my_stylebox.tres" }`
- **Expected result:** New StyleBoxFlat `.tres` created with default flat stylebox properties.
- **Notes:** StyleBoxFlat is commonly used for UI themes.

#### Scenario 6: Missing required `type` param
- **Description:** Omit the `type` parameter.
- **Params:** `{ "path": "res://test_output/no_type.tres" }`
- **Expected result:** Zod validation error — `type` is required.
- **Notes:** `type` is a plain `z.string()` — required.

#### Scenario 7: Missing required `path` param
- **Description:** Omit the `path` parameter.
- **Params:** `{ "type": "StandardMaterial3D" }`
- **Expected result:** Zod validation error — `path` is required.
- **Notes:** `path` is `ResourcePath` (required `z.string()`) — not optional.

#### Scenario 8: Missing both required params
- **Description:** Call with no parameters.
- **Params:** `{}`
- **Expected result:** Zod validation error for both `type` and `path`.
- **Notes:** Both are required strings.

#### Scenario 9: Empty string for `type`
- **Description:** Call with an empty string as the resource type.
- **Params:** `{ "type": "", "path": "res://test_output/empty_type.tres" }`
- **Expected result:** Zod validation passes. Godot handler should return an error for invalid/empty resource type.
- **Notes:** `z.string()` accepts empty strings.

#### Scenario 10: Empty string for `path`
- **Description:** Call with an empty string as the output path.
- **Params:** `{ "type": "StandardMaterial3D", "path": "" }`
- **Expected result:** Zod validation passes. Godot handler should return an error for invalid/empty path.
- **Notes:** Godot requires valid `res://` paths.

#### Scenario 11: Non-existent template path
- **Description:** Provide a `template` path that points to a file that does not exist.
- **Params:** `{ "type": "StandardMaterial3D", "path": "res://test_output/bad_template.tres", "template": "res://nonexistent/file.tres" }`
- **Expected result:** Godot-side error — template file not found or cannot be loaded.
- **Notes:** Tests error handling for invalid template references.

#### Scenario 12: Template path that is not a resource file
- **Description:** Provide a `template` pointing to a non-resource file (e.g., a `.gd` script).
- **Params:** `{ "type": "StandardMaterial3D", "path": "res://test_output/from_script.tres", "template": "res://scripts/some_script.gd" }`
- **Expected result:** Godot-side error — template is not a valid resource of the expected type, or type mismatch.
- **Notes:** Tests type compatibility between template and target resource type.

#### Scenario 13: Path outside `res://` namespace
- **Description:** Use an absolute filesystem path instead of `res://` path.
- **Params:** `{ "type": "StandardMaterial3D", "path": "C:\\Windows\\system32\\bad.tres" }`
- **Expected result:** Godot should reject the path — resources must be within the project's `res://` namespace.
- **Notes:** Tests path validation at the Godot level (Zod does not validate path format).

#### Scenario 14: Invalid type for `type` — number
- **Description:** Call with `type` as a number.
- **Params:** `{ "type": 10, "path": "res://test_output/bad.tres" }`
- **Expected result:** Zod validation error — expected string for `type`.
- **Notes:** Type validation.

#### Scenario 15: Invalid type for `template` — non-string
- **Description:** Call with `template` as a number instead of string.
- **Params:** `{ "type": "StandardMaterial3D", "path": "res://test_output/bad.tres", "template": 42 }`
- **Expected result:** Zod validation error — expected string for optional `template` parameter.
- **Notes:** Even though optional, the type must match when provided.

#### Scenario 16: Template value is null
- **Description:** Explicitly pass `null` for the optional `template` parameter.
- **Params:** `{ "type": "StandardMaterial3D", "path": "res://test_output/null_template.tres", "template": null }`
- **Expected result:** Depends on Zod strictness. `z.string().optional()` may reject `null` (treats as type mismatch) or strip it. Likely Zod validation error.
- **Notes:** Tests null handling for optional string.

#### Scenario 17: Duplicate output path (file already exists)
- **Description:** Try to create a resource at a path where a file already exists.
- **Params:** `{ "type": "StandardMaterial3D", "path": "res://test_output/already_exists.tres" }` (after a prior successful creation at that path)
- **Expected result:** May either overwrite (if Godot allows it) or return an error. Depends on Godot handler implementation.
- **Notes:** Test this after Scenario 1 to observe overwrite behavior.

#### Scenario 18: Very long path string
- **Description:** Use an extremely long output path.
- **Params:** `{ "type": "StandardMaterial3D", "path": "res://test_output/" + "a".repeat(200) + ".tres" }`
- **Expected result:** May succeed or error depending on filesystem limits. Godot may cap path lengths.
- **Notes:** Tests boundary condition for path length.

---

## Tool: `import_resource`

### Schema

```typescript
{
  description: 'Import a file as a resource with optional import settings',
  inputSchema: {
    path: ResourcePath.describe("File path to import (e.g. 'res://assets/model.fbx')"),
    settings: OptionalProperties,
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'resource_config/import', args as Record<string, unknown>)
```

### Tool Behavior
Imports a file into the Godot project as a resource. If the file is not yet in the project, it may be copied. Optional `settings` allows specification of import parameters (format, compression, etc.) tailored to the asset type. The tool triggers an import/re-import of the referenced file.

### Test Scenarios

#### Scenario 1: Happy path — import a file with no custom settings
- **Description:** Import a file using only the required `path` parameter.
- **Params:** `{ "path": "res://assets/textures/icon.svg" }`
- **Expected result:** File is imported/re-imported with default import settings. Returns success confirmation.
- **Notes:** Requires the referenced file to exist in the project. Use a file that ships with the default Godot project (e.g., `icon.svg`).

#### Scenario 2: Happy path — import with settings object
- **Description:** Import a file with explicit import settings.
- **Params:** `{ "path": "res://assets/textures/icon.svg", "settings": { "compress/mode": 0, "flags/repeat": false } }`
- **Expected result:** File is imported with the specified settings applied. Returns success.
- **Notes:** Settings keys should be valid Godot import settings for the file type being imported.

#### Scenario 3: Happy path — import with empty settings object
- **Description:** Import with an explicitly empty settings object.
- **Params:** `{ "path": "res://assets/textures/icon.svg", "settings": {} }`
- **Expected result:** Same as Scenario 1 — file imported with defaults. No error.
- **Notes:** Empty object is a valid `z.record(z.unknown())`.

#### Scenario 4: Happy path — import an audio file
- **Description:** Import an `.ogg` or `.wav` audio file.
- **Params:** `{ "path": "res://assets/sounds/explosion.ogg" }`
- **Expected result:** Audio file imported with default audio import settings. Returns success.
- **Notes:** Requires an audio file at the specified path.

#### Scenario 5: Happy path — import a 3D model (.fbx/.glb)
- **Description:** Import a 3D model file with optional settings.
- **Params:** `{ "path": "res://assets/models/character.fbx", "settings": { "meshes/generate_lightmap_uvs": true } }`
- **Expected result:** Model imported with mesh-specific settings applied. Returns success.
- **Notes:** Requires a 3D model file at the specified path.

#### Scenario 6: Happy path — import with settings as null/omitted
- **Description:** Call with only `path` — no `settings` field at all (testing optional behavior).
- **Params:** `{ "path": "res://assets/textures/icon.svg" }`
- **Expected result:** Success. Same as Scenario 1. The `settings` parameter is optional — `OptionalProperties` is `z.record(z.unknown()).optional()`.
- **Notes:** Explicitly verifies that `settings` can be omitted.

#### Scenario 7: Missing required `path` param
- **Description:** Omit the required `path` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `path` is required.
- **Notes:** `path` is `ResourcePath` (required `z.string()`).

#### Scenario 8: Missing required `path` param with settings present
- **Description:** Provide `settings` but omit `path`.
- **Params:** `{ "settings": { "compress/mode": 0 } }`
- **Expected result:** Zod validation error — `path` is required regardless of other params.
- **Notes:** Optional params cannot substitute for required ones.

#### Scenario 9: Empty string for `path`
- **Description:** Call with an empty string as the import file path.
- **Params:** `{ "path": "" }`
- **Expected result:** Zod validation passes. Godot handler should return an error for invalid path.
- **Notes:** `z.string()` accepts empty strings; Godot rejects them.

#### Scenario 10: Non-existent file path
- **Description:** Try to import a file that does not exist in the project.
- **Params:** `{ "path": "res://nonexistent/missing.png" }`
- **Expected result:** Godot-side error — file not found at the specified path.
- **Notes:** Tests error handling for missing source files.

#### Scenario 11: Invalid type for `path`
- **Description:** Call with `path` as a number.
- **Params:** `{ "path": 12345 }`
- **Expected result:** Zod validation error — expected string for `path`.
- **Notes:** Type validation.

#### Scenario 12: Invalid type for `settings` — non-object
- **Description:** Call with `settings` as a string instead of an object.
- **Params:** `{ "path": "res://assets/textures/icon.svg", "settings": "not_an_object" }`
- **Expected result:** Zod validation error — `z.record(z.unknown())` expects an object, not a string.
- **Notes:** Type validation for the optional settings parameter.

#### Scenario 13: Invalid type for `settings` — array
- **Description:** Call with `settings` as an array.
- **Params:** `{ "path": "res://assets/textures/icon.svg", "settings": [1, 2, 3] }`
- **Expected result:** Zod validation error — `z.record(z.unknown())` expects a plain object, not an array.
- **Notes:** Type validation — arrays are not valid records.

#### Scenario 14: Settings with invalid import key
- **Description:** Provide settings with a key that doesn't correspond to any valid import setting.
- **Params:** `{ "path": "res://assets/textures/icon.svg", "settings": { "nonexistent_setting": "value" } }`
- **Expected result:** Godot-side behavior may vary — either the invalid key is silently ignored, or an error/warning is returned.
- **Notes:** Tests robustness against invalid setting keys.

---

## Tool: `get_resource_import_settings`

### Schema

```typescript
{
  description: 'Get the current import settings for a resource file',
  inputSchema: {
    path: ResourcePath,
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'resource_config/get_resource_import_settings', args as Record<string, unknown>)
```

### Tool Behavior
Reads and returns the current import settings for a specific resource file. This is a read-only introspection tool. Response should include all import configuration parameters currently applied to that file (e.g., texture compression, audio quality, model scale, etc.).

### Test Scenarios

#### Scenario 1: Happy path — get import settings for a texture
- **Description:** Retrieve import settings for a texture file (e.g., `icon.svg`).
- **Params:** `{ "path": "res://assets/textures/icon.svg" }`
- **Expected result:** Returns a JSON object containing all import settings for the texture file. Should include properties like `compress/mode`, `flags/filter`, `flags/repeat`, `flags/mipmaps`, etc. No error.
- **Notes:** Requires the file to exist in the project. Use the default `icon.svg` that comes with new Godot projects.

#### Scenario 2: Happy path — get import settings for an audio file
- **Description:** Retrieve import settings for an audio resource.
- **Params:** `{ "path": "res://assets/sounds/music.ogg" }`
- **Expected result:** Returns audio-specific import settings like `compress/mode`, stream settings, loop settings, etc.
- **Notes:** Requires an audio file at the specified path.

#### Scenario 3: Happy path — get import settings for a 3D model
- **Description:** Retrieve import settings for a 3D model file.
- **Params:** `{ "path": "res://assets/models/character.fbx" }`
- **Expected result:** Returns model import settings including mesh compression, material import, animation import, scale factor, etc.
- **Notes:** Requires a 3D model file at the specified path.

#### Scenario 4: Happy path — get import settings for a `.tres` resource
- **Description:** Query a `.tres` resource file (which may or may not have import settings since `.tres` is a native Godot resource format).
- **Params:** `{ "path": "res://assets/some_resource.tres" }`
- **Expected result:** May return empty settings or a minimal set — native resources don't go through the import pipeline in the same way as external files. Still should not error.
- **Notes:** Tests the tool's behavior on non-imported resources.

#### Scenario 5: Missing required `path` param
- **Description:** Omit the required `path` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error — `path` is required.
- **Notes:** `path` is `ResourcePath` (required `z.string()`).

#### Scenario 6: Empty string for `path`
- **Description:** Call with an empty string as the file path.
- **Params:** `{ "path": "" }`
- **Expected result:** Zod validation passes — empty string is valid. Godot handler should return an error for invalid/empty path.
- **Notes:** Boundary condition test.

#### Scenario 7: Non-existent file path
- **Description:** Query import settings for a file that does not exist.
- **Params:** `{ "path": "res://nonexistent/file.png" }`
- **Expected result:** Godot-side error — file not found at the specified path.
- **Notes:** Tests error handling for missing files.

#### Scenario 8: Invalid type for `path` — number
- **Description:** Call with `path` as a number instead of string.
- **Params:** `{ "path": 42 }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** Type validation.

#### Scenario 9: Invalid type for `path` — boolean
- **Description:** Call with `path` as a boolean.
- **Params:** `{ "path": false }`
- **Expected result:** Zod validation error — expected string.
- **Notes:** Type validation.

#### Scenario 10: Call with unexpected extra params
- **Description:** Send additional unrecognized parameters alongside `path`.
- **Params:** `{ "path": "res://assets/textures/icon.svg", "extra_field": "unexpected" }`
- **Expected result:** Should succeed identically to Scenario 1. Extra params are stripped by Zod (strict parsing on the defined schema).
- **Notes:** Tests that unknown params don't interfere.

---

## Tool: `set_resource_import_settings`

### Schema

```typescript
{
  description: 'Update import settings for a resource file and reimport',
  inputSchema: {
    path: ResourcePath,
    settings: Properties.describe('Import settings to apply'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'resource_config/set_resource_import_settings', args as Record<string, unknown>)
```

### Tool Behavior
Updates the import settings for a resource file and triggers a re-import with the new settings. Both `path` and `settings` are **required** — unlike `import_resource` where settings are optional. This tool is specifically for modifying existing import configuration and re-importing the asset.

### Test Scenarios

#### Scenario 1: Happy path — update a single import setting
- **Description:** Change the texture compression mode for a texture file.
- **Params:** `{ "path": "res://assets/textures/icon.svg", "settings": { "compress/mode": 2 } }`
- **Expected result:** Import settings for the texture are updated. The file is re-imported with the new compression mode. Returns success confirmation.
- **Notes:** Requires the file to exist. The setting key names must match Godot's internal import setting paths.

#### Scenario 2: Happy path — update multiple import settings at once
- **Description:** Update several texture import settings simultaneously.
- **Params:** `{ "path": "res://assets/textures/icon.svg", "settings": { "compress/mode": 2, "flags/filter": true, "flags/repeat": false, "flags/mipmaps": true } }`
- **Expected result:** All specified settings are applied and the file is re-imported. Returns success.
- **Notes:** Tests batch update capability.

#### Scenario 3: Happy path — update audio import settings
- **Description:** Change audio import settings for an audio file.
- **Params:** `{ "path": "res://assets/sounds/music.ogg", "settings": { "compress/mode": 1, "loop": true } }`
- **Expected result:** Audio import settings updated. File re-imported with new settings. Returns success.
- **Notes:** Tests settings on a non-texture resource type.

#### Scenario 4: Happy path — update model import settings
- **Description:** Change mesh import parameters for a 3D model.
- **Params:** `{ "path": "res://assets/models/character.fbx", "settings": { "meshes/generate_lightmap_uvs": true, "meshes/scale_factor": 2.0 } }`
- **Expected result:** Model import settings updated. File re-imported with new mesh settings. Returns success.
- **Notes:** Tests on 3D model resources.

#### Scenario 5: Happy path — set settings back to previous values (round-trip)
- **Description:** First use `get_resource_import_settings` to read current settings, then re-apply them via `set_resource_import_settings`.
- **Params:** `{ "path": "res://assets/textures/icon.svg", "settings": <exact output from get_resource_import_settings> }`
- **Expected result:** No effective change — file is re-imported with identical settings. Should succeed without error.
- **Notes:** Cross-tool integration scenario. Verifies round-trip functionality between get and set.

#### Scenario 6: Happy path — settings with empty object
- **Description:** Call with an empty settings object.
- **Params:** `{ "path": "res://assets/textures/icon.svg", "settings": {} }`
- **Expected result:** May succeed (no settings changed, re-import with same settings) or the Godot handler may reject an empty required settings object. Behavior is Godot-side implementation dependent.
- **Notes:** Edge case — `z.record(z.unknown())` accepts `{}` as a valid object.

#### Scenario 7: Missing required `path` param
- **Description:** Omit the `path` parameter but provide `settings`.
- **Params:** `{ "settings": { "compress/mode": 2 } }`
- **Expected result:** Zod validation error — `path` is required.
- **Notes:** Both params are required.

#### Scenario 8: Missing required `settings` param
- **Description:** Omit the `settings` parameter but provide `path`.
- **Params:** `{ "path": "res://assets/textures/icon.svg" }`
- **Expected result:** Zod validation error — `settings` is required (uses `Properties`, which is `z.record(z.unknown())` — NOT optional). This distinguishes it from `import_resource` where settings are optional.
- **Notes:** Critical difference from `import_resource` — settings is required here.

#### Scenario 9: Missing both required params
- **Description:** Call with no parameters at all.
- **Params:** `{}`
- **Expected result:** Zod validation error for both `path` and `settings`.
- **Notes:** Both are required.

#### Scenario 10: Empty string for `path`
- **Description:** Call with empty string path and valid settings.
- **Params:** `{ "path": "", "settings": { "compress/mode": 2 } }`
- **Expected result:** Zod validation passes. Godot handler should return an error for invalid path.
- **Notes:** Boundary condition for path.

#### Scenario 11: Non-existent file path
- **Description:** Try to update import settings for a file that does not exist.
- **Params:** `{ "path": "res://nonexistent/missing.png", "settings": { "compress/mode": 2 } }`
- **Expected result:** Godot-side error — file not found at the specified path.
- **Notes:** Tests error handling for missing files.

#### Scenario 12: Invalid type for `path` — number
- **Description:** Call with `path` as a number.
- **Params:** `{ "path": 10, "settings": { "compress/mode": 2 } }`
- **Expected result:** Zod validation error — expected string for `path`.
- **Notes:** Type validation.

#### Scenario 13: Invalid type for `settings` — string
- **Description:** Call with `settings` as a string instead of an object.
- **Params:** `{ "path": "res://assets/textures/icon.svg", "settings": "compress_mode_2" }`
- **Expected result:** Zod validation error — `z.record(z.unknown())` expects an object.
- **Notes:** Type validation for required settings.

#### Scenario 14: Invalid type for `settings` — array
- **Description:** Call with `settings` as an array.
- **Params:** `{ "path": "res://assets/textures/icon.svg", "settings": [{"compress/mode": 2}] }`
- **Expected result:** Zod validation error — `z.record(z.unknown())` expects an object, not an array.
- **Notes:** Type validation.

#### Scenario 15: Invalid type for `settings` — null
- **Description:** Call with `settings` explicitly set to null.
- **Params:** `{ "path": "res://assets/textures/icon.svg", "settings": null }`
- **Expected result:** Zod validation error — `z.record(z.unknown())` does not accept null.
- **Notes:** Null is not a valid value for the required object type.

#### Scenario 16: Invalid type for `settings` — number
- **Description:** Call with `settings` as a number.
- **Params:** `{ "path": "res://assets/textures/icon.svg", "settings": 123 }`
- **Expected result:** Zod validation error — expected object, received number.
- **Notes:** Type validation.

#### Scenario 17: Settings with unrecognized keys
- **Description:** Provide settings with keys that do not match any valid import parameter.
- **Params:** `{ "path": "res://assets/textures/icon.svg", "settings": { "invalid_key": "invalid_value", "another_fake": 42 } }`
- **Expected result:** Godot-side behavior varies — invalid keys may be silently ignored, produce a warning, or cause an error.
- **Notes:** Tests robustness against invalid setting keys at the Godot handler level.

#### Scenario 18: Settings with very large number of keys
- **Description:** Provide a settings object with many key-value pairs (stress test).
- **Params:** `{ "path": "res://assets/textures/icon.svg", "settings": { "key_1": 1, "key_2": 2, ..., "key_100": 100 } }` (100+ keys)
- **Expected result:** Godot handler should either process only recognized keys or return an error for excessive input. Should not crash.
- **Notes:** Stress test for large input payloads.

---

## Cross-Tool Integration Scenarios

These scenarios test interactions between multiple tools in `resource_config.ts`.

### Integration 1: `get_resource_types` -> `get_resource_properties` chain
- **Description:** First list all resource types, then query properties for a few of them.
- **Steps:**
  1. Call `get_resource_types` → get a list of type names
  2. Pick 3 types from the result (e.g., `"Texture2D"`, `"AudioStream"`, `"Theme"`)
  3. Call `get_resource_properties` for each of the 3 types
- **Expected result:** All calls succeed. Properties returned for each type should be structurally consistent (objects with property names as keys).
- **Notes:** Validates the discovery → introspection workflow.

### Integration 2: `get_resource_import_settings` -> `set_resource_import_settings` round-trip
- **Description:** Read current import settings, then write them back unchanged.
- **Steps:**
  1. Call `get_resource_import_settings` for `icon.svg` → capture the settings object
  2. Call `set_resource_import_settings` with the same path and the captured settings
- **Expected result:** Both calls succeed. The re-import should produce the same result as the original.
- **Notes:** Validates get/set symmetry.

### Integration 3: Create resource -> query its properties
- **Description:** Create a resource with `create_resource_from_template`, then verify it exists and inspect its properties.
- **Steps:**
  1. Call `create_resource_from_template` to create a `StandardMaterial3D` at a known path
  2. Call `get_resource_properties` with type `"StandardMaterial3D"` to confirm the type's property schema
- **Expected result:** Resource created successfully. Properties schema matches expected StandardMaterial3D fields.
- **Notes:** Validates creation workflow end-to-end.

### Integration 4: Import -> check settings -> modify -> recheck
- **Description:** Import a file, read its settings, modify them, then read again to verify.
- **Steps:**
  1. Call `import_resource` to import a file with default settings
  2. Call `get_resource_import_settings` to read the current settings → save baseline
  3. Call `set_resource_import_settings` to change one setting
  4. Call `get_resource_import_settings` again to confirm the change took effect
- **Expected result:** Step 2 returns baseline. Step 4 returns updated settings reflecting the change made in step 3.
- **Notes:** Full import lifecycle test.

---

## Schema Validation Matrix

| Tool | `path` | `type` | `settings` | `template` | Empty Schema |
|------|--------|--------|------------|------------|--------------|
| `get_resource_types` | — | — | — | — | ✅ yes |
| `get_resource_properties` | — | required `string` | — | — | — |
| `create_resource_from_template` | required `string` | required `string` | — | optional `string` | — |
| `import_resource` | required `string` | — | optional `z.record()` | — | — |
| `get_resource_import_settings` | required `string` | — | — | — | — |
| `set_resource_import_settings` | required `string` | — | required `z.record()` | — | — |

---

## Error Handling Patterns

All tools share the same error handling path through `callGodot()`:

1. **Zod validation errors** — Caught by the MCP framework before the handler runs. Returns a validation error describing which parameter failed and why.
2. **Godot bridge errors** — Caught in `callGodot` via `try/catch`. Returns `{ content: [{ type: "text", text: "Godot request failed: <message>" }], isError: true }`.
3. **Godot-side handler errors** — Returned as the response body itself (may or may not include `isError`). The plugin handler determines the error format.
4. **Type errors (non-Zod)** — Caught by the outer `registerTool` wrapper. Returns `{ content: [{ type: "text", text: "Tool <name> failed: <message>" }], isError: true }`.

For all error scenarios above, verify that:
- The error response includes `isError: true` (or the framework marks it as an error)
- The error message is descriptive and includes actionable information
- No unhandled exceptions propagate to the client
- The server remains responsive after the error
