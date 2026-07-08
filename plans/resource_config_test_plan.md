# Test Plan: Resource Configuration Tools (`resource_config.ts`)

**Source**: `server/src/tools/resource_config.ts`
**Tools count**: 6
**Registration function**: `registerResourceConfigTools(server, bridge)`
**Backend route prefix**: `resource_config/`

---

## Shared Type Definitions (from `shared-types.ts`)

| Schema | Type | Description |
|---|---|---|
| `ResourcePath` | `z.string()` | Resource file path, e.g. `"res://assets/theme.tres"`, `"res://materials/my_material.tres"` |
| `Properties` | `z.record(z.unknown())` | Required property key-value pairs dictionary |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | Optional property key-value pairs dictionary |

---

## Dependency Graph & Execution Order

Tools 1–2 are **read-only introspection** (no side effects). Tools 3–6 **create or modify resources** on disk.

| Tool | Prerequisites | Side effects |
|---|---|---|
| `get_resource_types` | None | None (read-only) |
| `get_resource_properties` | None — works with any valid Godot resource type name. Recommended: use `get_resource_types` first to discover valid names. | None (read-only) |
| `create_resource_from_template` | Requires a valid `type` and an output `path` that does not already exist (or will be overwritten). Optional: a `template` file must exist at the given path. | **Creates a `.tres` file on disk** |
| `import_resource` | Requires a valid importable file at `path` (e.g. `.png`, `.fbx`, `.wav`). | **Triggers Godot's import pipeline for the file** |
| `get_resource_import_settings` | Requires a resource file at `path` that has been imported (i.e. has a `.import` file). | None (read-only) |
| `set_resource_import_settings` | Requires a resource file at `path` and a `settings` dict. After calling, the resource is reimported with new settings. | **Modifies `.import` file and reimports the resource** |

**Recommended test execution order:**

```
1. get_resource_types                          — discover valid type names
2. get_resource_properties (with known type)   — introspect properties
3. create_resource_from_template               — create a test resource
4. get_resource_import_settings                — read import settings (needs an importable asset)
5. set_resource_import_settings                — modify import settings
6. import_resource                             — reimport with custom settings
```

**Required cross-tool setup sequence** (before tools 4–6):

```
1. get_filesystem_tree({ path: "res://" })  — verify project structure
2. Ensure an importable asset exists (e.g. a .png file in the project)
   - If no importable asset exists, create one via create_file or use an existing project asset
3. For create_resource_from_template: optionally create a template resource first
```

---

## Tool: `get_resource_types`

**Description**: Get all registered resource types in the engine
**Backend route**: `resource_config/get_types`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| _(none)_ | — | — | This tool takes no parameters |

### Test Scenarios

#### Scenario 1: Get all resource types (happy path)

- **Description**: Call with no parameters to retrieve all registered resource types in Godot.
- **Params**:
  ```json
  {}
  ```
- **Expected result**: Success response (not `isError`). Result contains a list/array of resource type name strings. Expected to include well-known types: `Texture2D`, `AudioStream`, `PackedScene`, `StandardMaterial3D`, `ShaderMaterial`, `Theme`, `Font`, `Script`, `GDScript`, `Animation`, `Mesh`, `AudioStreamSample`, `AudioStreamOggVorbis`.
- **Notes**: Godot 4.x has 200+ registered resource types. The list should be substantial.
- **What to check**: The list should be non-empty and contain `Texture2D`, `PackedScene`, `StandardMaterial3D`. Verify the format — an array of strings or an object with a `types` field. If the list is empty — there's a problem with the plugin.

#### Scenario 2: Verify common categories are represented

- **Description**: Same call, but verify specific type categories are present.
- **Params**:
  ```json
  {}
  ```
- **Expected result**: Success response. Verify the list includes types from multiple categories:
  - **2D**: `Sprite2D` is a node, not a resource. Check for `AtlasTexture`, `Curve2D`.
  - **3D**: `StandardMaterial3D`, `ShaderMaterial`, `BoxMesh`, `SphereMesh`.
  - **Audio**: `AudioStream`, `AudioStreamOggVorbis`, `AudioStreamSample`, `AudioBusLayout`.
  - **UI/Theme**: `Theme`, `StyleBoxFlat`, `StyleBoxTexture`, `Font`.
  - **Scene**: `PackedScene`.
  - **Script**: `GDScript`, `CSharpScript`.
- **What to check**: If an entire category is missing (e.g., no audio types at all) — there may be a problem with type registration in Godot.

---

## Tool: `get_resource_properties`

**Description**: Get all serializable properties for a resource type with their types
**Backend route**: `resource_config/get_properties`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `type` | `string` | ✅ Yes | Resource type name (e.g. `"Texture2D"`, `"AudioStream"`, `"PackedScene"`) |

### Test Scenarios

#### Scenario 1: Get properties for StandardMaterial3D

- **Description**: Query serializable properties for `StandardMaterial3D`, a complex resource with many material properties.
- **Params**:
  ```json
  { "type": "StandardMaterial3D" }
  ```
- **Expected result**: Success response. Returns a list/dict of properties with their types. Expected properties: `albedo_color` (Color), `metallic` (float), `roughness` (float), `emission_enabled` (bool), `emission_color` (Color), `normal_enabled` (bool), `uv1_scale` (Vector3), `transparency` (enum), `blend_mode` (enum).
- **Notes**: Each property entry should include the property name, its type, and optionally its default value.
- **What to check**: Verify that `albedo_color` has type `Color`, `metallic` and `roughness` are `float`. If properties are returned without types — this degrades usability for AI clients.

#### Scenario 2: Get properties for Theme

- **Description**: Query properties for `Theme`, a UI resource type.
- **Params**:
  ```json
  { "type": "Theme" }
  ```
- **Expected result**: Success response. Theme properties should include: `default_font`, `default_font_size`, `default_color`, `default_base_scale`. The Theme type stores overrides internally (colors, constants, fonts, styleboxes per control type).
- **What to check**: Theme is a complex resource. Verify that not only basic properties are returned, but also information about how overrides are stored.

#### Scenario 3: Get properties for a simple resource (GDScript)

- **Description**: Query properties for `GDScript`, a simple resource type.
- **Params**:
  ```json
  { "type": "GDScript" }
  ```
- **Expected result**: Success response. GDScript has few serializable properties — primarily `source_code` (string) and `script` internal properties.
- **What to check**: Verify that `source_code` is present. If there are few properties — this is normal for script resources.

#### Scenario 4: Get properties for Texture2D

- **Description**: Query properties for a base texture type.
- **Params**:
  ```json
  { "type": "Texture2D" }
  ```
- **Expected result**: Success response. Texture2D is abstract — it may have few direct serializable properties (mainly `resource_name`, `resource_path` metadata). The specific subclass (e.g. `CompressedTexture2D`) may have more.
- **What to check**: `Texture2D` is an abstract class. If Godot returns an error instead of an empty property list — verify how the plugin handles abstract types.

#### Scenario 5: Invalid resource type name

- **Description**: Request properties for a non-existent resource type.
- **Params**:
  ```json
  { "type": "NonExistentResourceType12345" }
  ```
- **Expected result**: Error response (`isError: true`) with a message indicating the type was not found or is not a valid Godot resource class.
- **What to check**: Verify that a clear error message is returned, not a crash or empty response.

#### Scenario 6: Missing required `type` parameter

- **Description**: Call without the required `type` parameter.
- **Params**:
  ```json
  {}
  ```
- **Expected result**: MCP-level validation error — the Zod schema requires `type` as `z.string()`, so the server should reject the call before it reaches Godot.
- **What to check**: The error should mention that the `type` field is required. Verify that the error does not cause the server to crash.

---

## Tool: `create_resource_from_template`

**Description**: Create a new resource file from a template or with default values
**Backend route**: `resource_config/create_from_template`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `type` | `string` | ✅ Yes | Resource type to create (e.g. `"StandardMaterial3D"`, `"Theme"`) |
| `template` | `string` | ❌ No | Template resource path to copy from |
| `path` | `string` (ResourcePath) | ✅ Yes | Output path (e.g. `"res://materials/my_material.tres"`) |

### Test Scenarios

#### Scenario 1: Create a StandardMaterial3D with defaults

- **Description**: Create a new StandardMaterial3D resource file with default values (no template).
- **Params**:
  ```json
  {
    "type": "StandardMaterial3D",
    "path": "res://test_resources/test_material.tres"
  }
  ```
- **Expected result**: Success response. A `.tres` file is created at `res://test_resources/test_material.tres`. The file should contain a valid StandardMaterial3D resource with Godot's default property values.
- **Notes**: After creation, verify the file exists via `get_filesystem_tree({ path: "res://test_resources" })` and read its properties via `read_resource({ path: "res://test_resources/test_material.tres" })`.
- **What to check**: Verify that the file was actually created on disk. Read it and confirm it is a valid StandardMaterial3D with default values (albedo_color = white, metallic = 0, roughness = 1).

#### Scenario 2: Create a Theme resource

- **Description**: Create a new Theme resource file.
- **Params**:
  ```json
  {
    "type": "Theme",
    "path": "res://test_resources/test_theme.tres"
  }
  ```
- **Expected result**: Success response. A `.tres` file is created at `res://test_resources/test_theme.tres`.
- **What to check**: Verify that Theme was created as an empty resource without overrides. Confirm the file is readable and is a valid Theme.

#### Scenario 3: Create from a template resource

- **Description**: Create a new resource by copying from an existing template.
- **Prerequisites**: First create a template resource:
  ```
  create_resource_from_template({ type: "StandardMaterial3D", path: "res://test_resources/template_material.tres" })
  ```
  Then modify it (e.g. set `albedo_color` to red via `edit_resource`).
- **Params**:
  ```json
  {
    "type": "StandardMaterial3D",
    "template": "res://test_resources/template_material.tres",
    "path": "res://test_resources/copied_material.tres"
  }
  ```
- **Expected result**: Success response. A new file is created at `res://test_resources/copied_material.tres` with properties copied from the template. If the template had `albedo_color` set to red, the copy should also have red `albedo_color`.
- **What to check**: Verify that the copied resource has the same properties as the template. If values differ — copying is not working correctly.

#### Scenario 4: Create with invalid type

- **Description**: Attempt to create a resource with a non-existent type.
- **Params**:
  ```json
  {
    "type": "FakeResourceType999",
    "path": "res://test_resources/fake.tres"
  }
  ```
- **Expected result**: Error response (`isError: true`) indicating the resource type is not valid.
- **What to check**: The file should not be created on error. Verify that `res://test_resources/fake.tres` does not appear on disk.

#### Scenario 5: Create at an already existing path (overwrite)

- **Description**: Attempt to create a resource at a path that already exists.
- **Prerequisites**: First create a resource at the target path:
  ```
  create_resource_from_template({ type: "StandardMaterial3D", path: "res://test_resources/existing.tres" })
  ```
- **Params**:
  ```json
  {
    "type": "StandardMaterial3D",
    "path": "res://test_resources/existing.tres"
  }
  ```
- **Expected result**: Either success (overwrites the existing file) or error (refuses to overwrite). The behavior depends on the Godot backend implementation. Document which behavior occurs.
- **What to check**: Determine whether the tool overwrites the existing file or returns an error. Both behaviors are acceptable, but the actual behavior should be documented.

#### Scenario 6: Missing required `type` parameter

- **Params**:
  ```json
  { "path": "res://test_resources/no_type.tres" }
  ```
- **Expected result**: MCP validation error — `type` is required.
- **What to check**: Zod validation error.

#### Scenario 7: Missing required `path` parameter

- **Params**:
  ```json
  { "type": "StandardMaterial3D" }
  ```
- **Expected result**: MCP validation error — `path` is required.
- **What to check**: Zod validation error.

#### Scenario 8: Invalid path format (no res:// prefix)

- **Params**:
  ```json
  {
    "type": "StandardMaterial3D",
    "path": "/absolute/path/material.tres"
  }
  ```
- **Expected result**: Error response — Godot requires `res://` prefixed paths. The backend should reject non-`res://` paths.
- **What to check**: Verify that the error message indicates an incorrect path format.

---

## Tool: `import_resource`

**Description**: Import a file as a resource with optional import settings
**Backend route**: `resource_config/import`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | `string` (ResourcePath) | ✅ Yes | File path to import (e.g. `"res://assets/model.fbx"`) |
| `settings` | `Record<string, unknown>` | ❌ No | Optional import settings as key-value pairs |

### Test Scenarios

#### Scenario 1: Import a PNG texture (happy path, no custom settings)

- **Description**: Import an existing PNG file using default import settings.
- **Prerequisites**: Ensure a PNG file exists at the target path (e.g. `res://test_assets/icon.png`). This may require creating the file first or using an existing project asset.
- **Params**:
  ```json
  {
    "path": "res://test_assets/icon.png"
  }
  ```
- **Expected result**: Success response. The PNG is imported via Godot's import pipeline using default settings. A `.import` sidecar file should be created alongside the PNG.
- **Notes**: After import, the file should be loadable as a `CompressedTexture2D` resource.
- **What to check**: Verify that a `.import` file was created alongside the PNG. Confirm that Godot did not produce errors during import.

#### Scenario 2: Import with custom settings

- **Description**: Import a PNG with custom texture import settings.
- **Params**:
  ```json
  {
    "path": "res://test_assets/icon.png",
    "settings": {
      "compress/mode": 0,
      "mipmaps/generate": true
    }
  }
  ```
- **Expected result**: Success response. The file is reimported with the specified settings. The `.import` file should reflect the custom settings.
- **Notes**: `compress/mode = 0` typically means "Lossless" in Godot's texture import. `mipmaps/generate = true` enables mipmap generation.
- **What to check**: Verify that the settings were actually applied — read the `.import` file and confirm that `compress/mode` and `mipmaps/generate` contain the specified values.

#### Scenario 3: Import a non-existent file

- **Description**: Attempt to import a file that does not exist.
- **Params**:
  ```json
  {
    "path": "res://nonexistent/path/missing_file.png"
  }
  ```
- **Expected result**: Error response (`isError: true`) indicating the file does not exist.
- **What to check**: The error message should indicate that the file was not found.

#### Scenario 4: Import with empty settings object

- **Description**: Import with explicitly empty settings.
- **Params**:
  ```json
  {
    "path": "res://test_assets/icon.png",
    "settings": {}
  }
  ```
- **Expected result**: Success response — empty settings should behave the same as omitting settings (use defaults).
- **What to check**: Verify that an empty settings object does not cause an error.

#### Scenario 5: Missing required `path` parameter

- **Params**:
  ```json
  {}
  ```
- **Expected result**: MCP validation error — `path` is required.
- **What to check**: Zod validation error.

#### Scenario 6: Import an FBX model

- **Description**: Import a 3D model file (if available in the project).
- **Params**:
  ```json
  {
    "path": "res://test_assets/model.fbx",
    "settings": {
      "meshes/ensure_tangents": true,
      "animation/import": true
    }
  }
  ```
- **Expected result**: Success response if the file exists. The FBX is imported with mesh and animation settings applied.
- **Notes**: This scenario is only runnable if the project contains an FBX file. Skip if unavailable.
- **What to check**: Verify that the 3D model imports without errors. If Godot does not support FBX without a plugin — skip the scenario.

---

## Tool: `get_resource_import_settings`

**Description**: Get the current import settings for a resource file
**Backend route**: `resource_config/get_resource_import_settings`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | `string` (ResourcePath) | ✅ Yes | Resource file path |

### Test Scenarios

#### Scenario 1: Get import settings for a PNG texture

- **Description**: Query current import settings for an imported PNG file.
- **Prerequisites**: The PNG must have been imported previously (it should have a `.import` sidecar file). Use `import_resource` or ensure Godot has already imported it.
- **Params**:
  ```json
  {
    "path": "res://test_assets/icon.png"
  }
  ```
- **Expected result**: Success response. Returns the current import settings as key-value pairs. For a PNG texture, expected settings include:
  - `compress/mode` — compression mode (0 = Lossless, 1 = Lossy, 2 = VRAM Compressed, etc.)
  - `compress/high_quality` — boolean
  - `compress/lossy_quality` — float (0.0–1.0)
  - `mipmaps/generate` — boolean
  - `mipmaps/limit` — integer
  - `process/fix_alpha_border` — boolean
  - `process/premult_alpha` — boolean
  - `process/size_limit` — integer
  - `detect_3d/compress_to` — enum
- **What to check**: Verify that all keys are strings. Values should have correct types (boolean for flags, numbers for quality/limit). If settings are empty — the `.import` file may not have been created.

#### Scenario 2: Get import settings for a WAV audio file

- **Description**: Query import settings for an audio resource.
- **Prerequisites**: A WAV file must exist and be imported (e.g. `res://test_assets/sound.wav`).
- **Params**:
  ```json
  {
    "path": "res://test_assets/sound.wav"
  }
  ```
- **Expected result**: Success response. Audio import settings should include: `force/8_bit`, `force/mono`, `force/max_rate`, `edit/trim`, `edit/normalize`, `compress/mode`.
- **What to check**: Verify that the settings differ from texture settings. If the same keys are returned as for PNG — the plugin may not distinguish file types.

#### Scenario 3: Get import settings for a non-imported file

- **Description**: Query import settings for a file that is not importable (e.g. a `.gd` script or a `.tscn` scene).
- **Params**:
  ```json
  {
    "path": "res://scripts/player.gd"
  }
  ```
- **Expected result**: Error response — GDScript files are not imported through Godot's import pipeline, so there are no import settings. Alternatively, an empty settings object may be returned.
- **What to check**: Determine how the plugin handles non-importable files. An error or empty result — both are acceptable, but the actual behavior should be documented.

#### Scenario 4: Get import settings for non-existent file

- **Params**:
  ```json
  {
    "path": "res://nonexistent/missing_texture.png"
  }
  ```
- **Expected result**: Error response — file does not exist.
- **What to check**: The error message should indicate that the file was not found.

#### Scenario 5: Missing required `path` parameter

- **Params**:
  ```json
  {}
  ```
- **Expected result**: MCP validation error — `path` is required.
- **What to check**: Zod validation error.

---

## Tool: `set_resource_import_settings`

**Description**: Update import settings for a resource file and reimport
**Backend route**: `resource_config/set_resource_import_settings`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | `string` (ResourcePath) | ✅ Yes | Resource file path |
| `settings` | `Record<string, unknown>` | ✅ Yes | Import settings to apply |

### Test Scenarios

#### Scenario 1: Change compression mode on a PNG texture

- **Description**: Update the compression mode of an imported PNG and reimport.
- **Prerequisites**: A PNG file must exist and be imported. Record its current settings via `get_resource_import_settings`.
- **Params**:
  ```json
  {
    "path": "res://test_assets/icon.png",
    "settings": {
      "compress/mode": 2
    }
  }
  ```
- **Expected result**: Success response. The PNG's import settings are updated (`compress/mode` set to 2 = VRAM Compressed) and the resource is reimported.
- **Notes**: After calling, verify via `get_resource_import_settings({ path: "res://test_assets/icon.png" })` that `compress/mode` is now `2`.
- **What to check**: Verify that the settings actually changed — call `get_resource_import_settings` afterward and compare. Confirm that Godot started the reimport (there may be messages in the Output log).

#### Scenario 2: Enable mipmaps generation

- **Description**: Enable mipmap generation for a texture.
- **Params**:
  ```json
  {
    "path": "res://test_assets/icon.png",
    "settings": {
      "mipmaps/generate": true
    }
  }
  ```
- **Expected result**: Success response. The texture is reimported with mipmaps enabled.
- **What to check**: Verify that `mipmaps/generate` = `true` in the settings after the call.

#### Scenario 3: Set multiple settings at once

- **Description**: Apply multiple import settings in a single call.
- **Params**:
  ```json
  {
    "path": "res://test_assets/icon.png",
    "settings": {
      "compress/mode": 1,
      "compress/lossy_quality": 0.7,
      "mipmaps/generate": false,
      "process/fix_alpha_border": true
    }
  }
  ```
- **Expected result**: Success response. All four settings are applied atomically. After reimport, verify all settings match.
- **What to check**: Verify that ALL four settings were applied, not just the first one. If some settings were not applied — there's a problem with batch update handling.

#### Scenario 4: Set settings with invalid key

- **Description**: Apply a setting with a non-existent key.
- **Params**:
  ```json
  {
    "path": "res://test_assets/icon.png",
    "settings": {
      "nonexistent_setting_key": "some_value"
    }
  }
  ```
- **Expected result**: Either success (Godot ignores unknown keys) or error (strict validation). Document which behavior occurs.
- **What to check**: Determine how Godot handles unknown keys — silently ignores them or returns an error. This is important for AI client robustness.

#### Scenario 5: Set settings with wrong value type

- **Description**: Apply a boolean setting with a string value.
- **Params**:
  ```json
  {
    "path": "res://test_assets/icon.png",
    "settings": {
      "mipmaps/generate": "not_a_boolean"
    }
  }
  ```
- **Expected result**: Error response — the value type does not match the expected type for the setting. Alternatively, Godot may coerce the value.
- **What to check**: Determine how Godot handles incorrect value types. An error is the safest behavior.

#### Scenario 6: Missing required `path` parameter

- **Params**:
  ```json
  {
    "settings": { "compress/mode": 0 }
  }
  ```
- **Expected result**: MCP validation error — `path` is required.
- **What to check**: Zod validation error.

#### Scenario 7: Missing required `settings` parameter

- **Params**:
  ```json
  {
    "path": "res://test_assets/icon.png"
  }
  ```
- **Expected result**: MCP validation error — `settings` is required (`Properties` = `z.record(z.unknown())`, not optional).
- **What to check**: Zod validation error. Verify that `settings` is indeed required (not optional).

#### Scenario 8: Set settings on non-existent file

- **Params**:
  ```json
  {
    "path": "res://nonexistent/missing.png",
    "settings": { "compress/mode": 0 }
  }
  ```
- **Expected result**: Error response — file does not exist.
- **What to check**: The error message should indicate that the file was not found.

---

## Cross-Tool Verification Scenarios

These scenarios test interactions between multiple tools to validate consistency.

### Scenario A: Full resource lifecycle

1. `get_resource_types` — get list of all types
2. `get_resource_properties({ type: "StandardMaterial3D" })` — get properties for the type
3. `create_resource_from_template({ type: "StandardMaterial3D", path: "res://test_resources/lifecycle_material.tres" })` — create resource
4. `read_resource({ path: "res://test_resources/lifecycle_material.tres" })` — verify created resource has default property values matching what `get_resource_properties` reported
5. **Assert**: Property names in the created resource match those returned by `get_resource_properties`.

**What to check**: If the properties returned by `get_resource_properties` don't match what is actually written to the resource — there's a problem with the type system.

### Scenario B: Import settings round-trip

1. `import_resource({ path: "res://test_assets/icon.png" })` — import with defaults
2. `get_resource_import_settings({ path: "res://test_assets/icon.png" })` — record current settings
3. `set_resource_import_settings({ path: "res://test_assets/icon.png", settings: { "compress/mode": 2, "mipmaps/generate": true } })` — modify settings
4. `get_resource_import_settings({ path: "res://test_assets/icon.png" })` — record new settings
5. **Assert**: Settings from step 4 reflect the changes from step 3 (`compress/mode = 2`, `mipmaps/generate = true`).

**What to check**: If settings did not change after `set_resource_import_settings` — the tool is not working. If they changed partially — there's a problem with partial updates.

### Scenario C: Template copy preserves properties

1. `create_resource_from_template({ type: "StandardMaterial3D", path: "res://test_resources/original.tres" })` — create original
2. Modify the original's `albedo_color` to red via `edit_resource`
3. `create_resource_from_template({ type: "StandardMaterial3D", template: "res://test_resources/original.tres", path: "res://test_resources/copy.tres" })` — copy from template
4. `read_resource({ path: "res://test_resources/copy.tres" })` — read the copy
5. **Assert**: The copy's `albedo_color` matches the original's (red).

**What to check**: If the copy did not preserve the modified template properties — the `template` parameter is not working.

### Scenario D: Properties consistency across types

1. `get_resource_types` — get all types
2. Pick 5 types from the list (e.g. `Theme`, `GDScript`, `AudioStreamOggVorbis`, `BoxMesh`, `Curve2D`)
3. For each, call `get_resource_properties({ type: <type> })`
4. **Assert**: All calls succeed and return non-empty property lists.

**What to check**: If a type from `get_resource_types` causes an error in `get_resource_properties` — there's an inconsistency in the plugin.

---

## Cleanup

After all tests, remove test artifacts:

```
delete_file({ path: "res://test_resources/test_material.tres" })
delete_file({ path: "res://test_resources/test_theme.tres" })
delete_file({ path: "res://test_resources/template_material.tres" })
delete_file({ path: "res://test_resources/copied_material.tres" })
delete_file({ path: "res://test_resources/existing.tres" })
delete_file({ path: "res://test_resources/fake.tres" })
delete_file({ path: "res://test_resources/lifecycle_material.tres" })
delete_file({ path: "res://test_resources/original.tres" })
delete_file({ path: "res://test_resources/copy.tres" })
delete_file({ path: "res://test_resources/no_type.tres" })
```

Note: Some files may not have been created if the corresponding test failed. Use `get_filesystem_tree` to check which files exist before cleanup, or handle `delete_file` errors gracefully.
