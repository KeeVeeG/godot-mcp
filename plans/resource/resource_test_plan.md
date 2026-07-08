# Resource Tools Test Plan

> **Source file:** `server/src/tools/resource.ts`  
> **Shared types:** `server/src/tools/shared-types.ts`  
> **Tools covered:** 10 (`read_resource`, `edit_resource`, `create_resource`, `delete_resource`, `get_resource_preview`, `add_autoload`, `remove_autoload`, `duplicate_resource`, `list_resources`, `get_resource_dependencies`)  
> **Generated:** 2026-07-08

---

## Schema Details

### Shared Imports

| Import | Zod Schema | Description |
|--------|-----------|-------------|
| `ResourcePath` | `z.string()` | Resource file path (e.g. `'res://assets/theme.tres'`) |
| `Properties` | `z.record(z.unknown())` | Required property key-value pairs |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | Optional property key-value pairs |
| `z` | Zod namespace | Used directly for `z.string()`, `z.record()`, `z.unknown()` |

### Parameter Summary

| Tool | Param | Type | Required | Default | Enum/Choices | Notes |
|------|-------|------|----------|---------|--------------|-------|
| `read_resource` | `path` | `string` | ✅ yes | — | — | Resource file path (`.tres`/`.res`) |
| `edit_resource` | `path` | `string` | ✅ yes | — | — | Resource file path |
| | `properties` | `record(unknown)` | ✅ yes | — | — | Properties to set |
| `create_resource` | `type` | `string` | ✅ yes | — | — | e.g. `'StyleBoxFlat'`, `'Gradient'` |
| | `path` | `string` | ✅ yes | — | — | Output path |
| | `properties` | `record(unknown)` | no | — | — | Initial property values |
| `delete_resource` | `path` | `string` | ✅ yes | — | — | Path to delete |
| `get_resource_preview` | `path` | `string` | ✅ yes | — | — | Path to preview |
| `add_autoload` | `name` | `string` | ✅ yes | — | — | Singleton name |
| | `path` | `string` | ✅ yes | — | — | Script/scene path |
| `remove_autoload` | `name` | `string` | ✅ yes | — | — | Autoload name to remove |
| `duplicate_resource` | `source_path` | `string` | ✅ yes | — | — | Source path |
| | `dest_path` | `string` | ✅ yes | — | — | Destination path |
| `list_resources` | `type` | `string` | no | — | — | Resource type filter |
| | `directory` | `string` | no | — | — | Directory to search |
| `get_resource_dependencies` | `path` | `string` | ✅ yes | — | — | Resource path |

---

## Tool: read_resource

### Schema

```typescript
{
  description: 'Read a Godot resource file (.tres, .res) and get its properties',
  inputSchema: {
    path: ResourcePath,
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'resource/read', args as Record<string, unknown>)
```

### Tool Behavior
Reads a `.tres` or `.res` resource file from disk and returns its serialized properties. The tool is purely read-only and does not modify the resource. Returns a JSON representation of the resource's property key-value pairs. Expects a valid `res://` path to an existing resource file.

### Test Scenarios

#### Scenario 1: Happy path — read a `.tres` resource
- **Description:** Read an existing `.tres` resource file and verify its properties are returned.
- **Params:** `{ "path": "res://resources/test_stylebox.tres" }`
- **Expected result:** Returns a JSON object with all serialized properties of the resource. Should include the resource type. Properties structure depends on the specific resource type. Response should NOT be an error.
- **Notes:** The resource file must exist at the given path. Use a pre-existing resource or create one first via `create_resource`.

#### Scenario 2: Happy path — read a `.res` resource
- **Description:** Read an existing `.res` (binary) resource file and verify its properties are returned.
- **Params:** `{ "path": "res://resources/test_data.res" }`
- **Expected result:** Returns a JSON object with the resource's serialized properties. Should succeed identically to `.tres` reads.
- **Notes:** `.res` files are binary but should deserialize the same way. Test with any existing `.res` file in the project.

#### Scenario 3: Happy path — read a theme resource
- **Description:** Read a Theme resource to verify complex nested property structures are returned.
- **Params:** `{ "path": "res://themes/default_theme.tres" }`
- **Expected result:** Returns a deeply nested structure including theme item overrides, type variations, etc. The output should be valid JSON.
- **Notes:** Theme resources have nested structures that exercise the serializer.

#### Scenario 4: Missing required param — no path
- **Description:** Call `read_resource` without the required `path` parameter.
- **Params:** `{}` (empty object)
- **Expected result:** Zod validation error. Should reject with a message indicating `path` is required.
- **Notes:** Schema has `path` as required — Zod should catch this before the handler runs.

#### Scenario 5: Invalid path — file does not exist
- **Description:** Try to read a resource at a path where no file exists.
- **Params:** `{ "path": "res://nonexistent/fake.tres" }`
- **Expected result:** Error from Godot bridge. Should return an error response indicating the file was not found.
- **Notes:** The Godot editor should reject this gracefully, not crash.

#### Scenario 6: Invalid path — wrong extension
- **Description:** Try to read a file that exists but is not a resource file (e.g. a `.gd` script).
- **Params:** `{ "path": "res://scripts/player.gd" }`
- **Expected result:** Error from Godot. The engine should report that the file is not a valid resource.
- **Notes:** Zod only validates the path is a string, not the extension. Godot-side validation should catch this.

#### Scenario 7: Invalid path — raw filesystem path
- **Description:** Try to read using an absolute OS filesystem path instead of a `res://` path.
- **Params:** `{ "path": "C:/Users/test/some_file.tres" }`
- **Expected result:** Error. Godot resources are accessed via `res://` paths. Should return an error.
- **Notes:** Tests that the Godot bridge rejects non-project paths.

#### Scenario 8: Empty path string
- **Description:** Call with an empty string as the path.
- **Params:** `{ "path": "" }`
- **Expected result:** Zod validation passes (empty string is still a string), but Godot should return an error for an invalid/incomplete path.
- **Notes:** Empty string is not a valid resource path but passes Zod validation.

#### Scenario 9: Path with trailing slash
- **Description:** Call with a path that ends with a slash (directory-style).
- **Params:** `{ "path": "res://resources/" }`
- **Expected result:** Error. A trailing slash suggests a directory, not a file. Godot should reject this.
- **Notes:** Boundary test for path format expectations.

#### Scenario 10: Path with special characters
- **Description:** Use a path containing spaces and special characters.
- **Params:** `{ "path": "res://resources/my test file.tres" }`
- **Expected result:** If the file exists, should succeed. If not, should fail with "not found". Either way, should not crash.
- **Notes:** Validates that paths with spaces are handled correctly (or at least don't crash).

---

## Tool: edit_resource

### Schema

```typescript
{
  description: 'Edit properties of an existing resource',
  inputSchema: {
    path: ResourcePath,
    properties: Properties.describe('Properties to set'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'resource/edit', args as Record<string, unknown>)
```

### Tool Behavior
Modifies properties of an existing resource file in-place. Takes a path to the resource and a dictionary of property key-value pairs to update. This is a mutating operation — it writes changes to the `.tres`/`.res` file on disk via Godot's undo system. Returns success confirmation or error details.

### Test Scenarios

#### Scenario 1: Happy path — edit a single string property
- **Description:** Update one property on an existing resource.
- **Params:** `{ "path": "res://resources/test_material.tres", "properties": { "albedo_color": "#FF0000" } }`
- **Expected result:** Success. The resource file should be updated with the new property value. Re-reading the resource should reflect the change.
- **Notes:** Use a disposable test resource. Verify the change persisted by calling `read_resource` afterward.

#### Scenario 2: Happy path — edit multiple properties at once
- **Description:** Update several properties on a resource simultaneously.
- **Params:** `{ "path": "res://resources/test_stylebox.tres", "properties": { "bg_color": "#00FF00", "border_width_left": 5, "border_width_right": 5 } }`
- **Expected result:** Success. All specified properties should be updated. Re-reading confirms all three values changed.
- **Notes:** Tests that the handler correctly passes multiple properties through the bridge.

#### Scenario 3: Happy path — edit a numeric property
- **Description:** Set a numeric property (integer) on a resource.
- **Params:** `{ "path": "res://resources/test_theme.tres", "properties": { "default_font_size": 16 } }`
- **Expected result:** Success. The numeric value should be stored correctly.
- **Notes:** Verify the type is preserved (integer stays integer, not converted to string).

#### Scenario 4: Happy path — edit a boolean property
- **Description:** Set a boolean property on a resource.
- **Params:** `{ "path": "res://resources/test_material.tres", "properties": { "transparent": true } }`
- **Expected result:** Success. The boolean should be stored as `true`, not the string `"true"`.
- **Notes:** Validates type fidelity for booleans across the bridge.

#### Scenario 5: Missing required param — no path
- **Description:** Call `edit_resource` without the required `path`.
- **Params:** `{ "properties": { "some_key": "some_value" } }`
- **Expected result:** Zod validation error. Should indicate `path` is required.
- **Notes:** Both `path` and `properties` are required in the schema.

#### Scenario 6: Missing required param — no properties
- **Description:** Call `edit_resource` without the required `properties` parameter.
- **Params:** `{ "path": "res://resources/test_material.tres" }`
- **Expected result:** Zod validation error. Should indicate `properties` is required.
- **Notes:** `Properties` is not optional — it must be provided even if empty.

#### Scenario 7: Edge case — empty properties object
- **Description:** Edit a resource with an empty properties dictionary.
- **Params:** `{ "path": "res://resources/test_material.tres", "properties": {} }`
- **Expected result:** Zod passes (empty record is valid). Behavior depends on Godot — may succeed as a no-op or may error. Should not crash.
- **Notes:** Even though it's technically valid, empty properties may cause a Godot-side warning or no-op.

#### Scenario 8: Invalid path — nonexistent resource
- **Description:** Try to edit a resource that doesn't exist.
- **Params:** `{ "path": "res://nonexistent/fake.tres", "properties": { "key": "value" } }`
- **Expected result:** Error from Godot. Should report that the resource does not exist.
- **Notes:** The tool should fail gracefully, not create a new file at the path.

#### Scenario 9: Edge case — setting a property that doesn't exist on the resource type
- **Description:** Try to set a property name that the resource type doesn't have.
- **Params:** `{ "path": "res://resources/test_material.tres", "properties": { "nonexistent_prop": "some_value" } }`
- **Expected result:** Error or warning from Godot. The engine should reject unknown property names.
- **Notes:** Tests Godot's property validation for resource types.

#### Scenario 10: Edge case — setting a property to an invalid type
- **Description:** Try to set a color property to a non-color value.
- **Params:** `{ "path": "res://resources/test_material.tres", "properties": { "albedo_color": 42 } }`
- **Expected result:** Error from Godot. Type mismatch should be reported.
- **Notes:** Validates type checking on the Godot side.

#### Scenario 11: Edge case — properties with null values
- **Description:** Try to set a property to `null`.
- **Params:** `{ "path": "res://resources/test_material.tres", "properties": { "albedo_color": null } }`
- **Expected result:** Depends on the property. If nullable, should succeed (resets to default). If not nullable, should error.
- **Notes:** Behavior may vary by resource type.

---

## Tool: create_resource

### Schema

```typescript
{
  description: 'Create a new Godot resource',
  inputSchema: {
    type: z.string().describe("Resource type (e.g. 'StyleBoxFlat', 'Gradient', 'Curve')"),
    path: ResourcePath,
    properties: OptionalProperties,
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'resource/create', args as Record<string, unknown>)
```

### Tool Behavior
Creates a new resource file at the specified path with the given Godot resource type. Optionally accepts initial property values. The file is written to disk as a `.tres` (text) or `.res` (binary) depending on the type. Returns confirmation with the created resource's properties or an error if the type is unknown or the path is invalid.

### Test Scenarios

#### Scenario 1: Happy path — create a StyleBoxFlat
- **Description:** Create a new `StyleBoxFlat` resource with default properties.
- **Params:** `{ "type": "StyleBoxFlat", "path": "res://resources/test_stylebox_new.tres" }`
- **Expected result:** Success. A new `.tres` file should be created at the path with default `StyleBoxFlat` properties. File should exist on disk.
- **Notes:** `StyleBoxFlat` is a common UI resource type. Omit `properties` to test defaults.

#### Scenario 2: Happy path — create a Gradient with properties
- **Description:** Create a `Gradient` resource with initial properties.
- **Params:** `{ "type": "Gradient", "path": "res://resources/test_gradient.tres", "properties": { "colors": { "gradient": { "points": [ { "color": "#FF0000", "offset": 0 }, { "color": "#0000FF", "offset": 1 } ] } } } }`
- **Expected result:** Success. A `Gradient` resource should be created with the specified color points.
- **Notes:** Gradient has a nested structure. Verifies complex property passing.

#### Scenario 3: Happy path — create a Curve resource
- **Description:** Create a `Curve` resource.
- **Params:** `{ "type": "Curve", "path": "res://resources/test_curve.tres" }`
- **Expected result:** Success. A `Curve` resource file is created.
- **Notes:** Tests a different resource type mentioned in the tool description.

#### Scenario 4: Happy path — create with empty properties object
- **Description:** Create a resource with an explicitly empty properties object (not omitted).
- **Params:** `{ "type": "StyleBoxFlat", "path": "res://resources/test_empty_props.tres", "properties": {} }`
- **Expected result:** Success. Same behavior as omitting `properties` — resource created with defaults.
- **Notes:** Empty record should be treated the same as no properties.

#### Scenario 5: Happy path — create with `.res` extension (binary)
- **Description:** Create a resource with a `.res` binary extension instead of `.tres`.
- **Params:** `{ "type": "StandardMaterial3D", "path": "res://resources/test_material.res" }`
- **Expected result:** Success. A binary `.res` file should be created.
- **Notes:** Some resource types default to binary format. The extension should match.

#### Scenario 6: Missing required param — no type
- **Description:** Call `create_resource` without the required `type` parameter.
- **Params:** `{ "path": "res://resources/test.tres" }`
- **Expected result:** Zod validation error. Should indicate `type` is required.
- **Notes:** `type` is a bare `z.string()` — required, no default.

#### Scenario 7: Missing required param — no path
- **Description:** Call `create_resource` without the required `path`.
- **Params:** `{ "type": "StyleBoxFlat" }`
- **Expected result:** Zod validation error. Should indicate `path` is required.
- **Notes:** Both `type` and `path` are required.

#### Scenario 8: Invalid type — nonexistent resource class
- **Description:** Try to create a resource with a type name that doesn't exist in Godot.
- **Params:** `{ "type": "FakeResourceType", "path": "res://resources/fake.tres" }`
- **Expected result:** Error from Godot. Should report that the resource type is unknown.
- **Notes:** Tests Godot's class name resolution.

#### Scenario 9: Invalid type — using a Node type name
- **Description:** Try to create a "resource" using a Node class name.
- **Params:** `{ "type": "Sprite2D", "path": "res://resources/sprite.tres" }`
- **Expected result:** Error. `Sprite2D` is a Node, not a Resource — Godot should reject it.
- **Notes:** Only classes inheriting from `Resource` should be valid.

#### Scenario 10: Invalid path — directory that doesn't exist
- **Description:** Try to create a resource in a nonexistent directory.
- **Params:** `{ "type": "StyleBoxFlat", "path": "res://nonexistent_dir/test.tres" }`
- **Expected result:** Error. Godot should report that the parent directory does not exist.
- **Notes:** The tool should not auto-create directories.

#### Scenario 11: Edge case — overwrite existing file
- **Description:** Try to create a resource at a path where a file already exists.
- **Params:** `{ "type": "StyleBoxFlat", "path": "res://resources/test_stylebox_new.tres" }` (after Scenario 1 created it)
- **Expected result:** Behavior depends on Godot — may overwrite, may error with "already exists". Either way, should not silently corrupt existing data.
- **Notes:** Document the actual behavior observed during testing.

#### Scenario 12: Edge case — empty string type
- **Description:** Call with an empty string as the resource type.
- **Params:** `{ "type": "", "path": "res://resources/empty_type.tres" }`
- **Expected result:** Error from Godot. Empty string is not a valid resource type.
- **Notes:** Zod passes; Godot-side validation should catch this.

#### Scenario 13: Edge case — path without extension
- **Description:** Create a resource at a path with no file extension.
- **Params:** `{ "type": "StyleBoxFlat", "path": "res://resources/no_extension" }`
- **Expected result:** Depends on Godot implementation. May auto-append `.tres`, or may error.
- **Notes:** Document actual behavior. Godot may implicitly add `.tres`.

#### Scenario 14: Edge case — path with wrong extension for binary resource
- **Description:** Create a binary resource type at a `.tres` path.
- **Params:** `{ "type": "StandardMaterial3D", "path": "res://resources/binary_as_tres.tres" }`
- **Expected result:** May succeed (Godot stores binary resources as `.res` regardless of extension) or may warn. Should not crash.
- **Notes:** Some resources are always binary regardless of extension.

---

## Tool: delete_resource

### Schema

```typescript
{
  description: 'Delete a Godot resource file (.tres, .res) from the project',
  inputSchema: {
    path: ResourcePath.describe('Resource file path to delete'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'resource/delete', args as Record<string, unknown>)
```

### Tool Behavior
Deletes a resource file from the project filesystem. This is a destructive operation — the file is permanently removed (or moved to trash, depending on editor settings). Uses Godot's undo system, so the delete can be undone from within the editor. Returns success or an error if the file doesn't exist or is in use.

### Test Scenarios

#### Scenario 1: Happy path — delete a `.tres` file
- **Description:** Delete an existing resource file that is not referenced by any scene.
- **Params:** `{ "path": "res://resources/test_to_delete.tres" }`
- **Expected result:** Success. The file should be removed from disk. Calling `read_resource` on the same path afterward should fail.
- **Notes:** Create a disposable resource first (via `create_resource`), then delete it. Verify file is gone.

#### Scenario 2: Happy path — delete a `.res` file
- **Description:** Delete an existing binary resource file.
- **Params:** `{ "path": "res://resources/test_binary_to_delete.res" }`
- **Expected result:** Success. Binary `.res` file should be removed.
- **Notes:** Same behavior expected for binary resources.

#### Scenario 3: Missing required param — no path
- **Description:** Call `delete_resource` without the required `path`.
- **Params:** `{}` (empty object)
- **Expected result:** Zod validation error. Should indicate `path` is required.
- **Notes:** Schema requires path.

#### Scenario 4: Invalid path — file does not exist
- **Description:** Try to delete a resource at a path that doesn't exist.
- **Params:** `{ "path": "res://nonexistent/fake.tres" }`
- **Expected result:** Error from Godot. Should report file not found.
- **Notes:** Should not crash or create unexpected side effects.

#### Scenario 5: Edge case — delete a resource referenced by a scene
- **Description:** Try to delete a resource that is actively referenced by a loaded scene.
- **Params:** `{ "path": "res://resources/in_use_material.tres" }`
- **Expected result:** Warning or error. Godot typically warns about breaking references. May still allow deletion (references become null).
- **Notes:** Document actual behavior. The tool might succeed but the scene may have broken references.

#### Scenario 6: Edge case — delete an autoload script resource
- **Description:** Try to delete a script that is registered as an autoload singleton.
- **Params:** `{ "path": "res://autoload/global_manager.gd" }` (assuming this is registered as an autoload)
- **Expected result:** Error or warning. Godot should prevent deleting an actively registered autoload.
- **Notes:** This tests safeguards against breaking autoload configuration.

#### Scenario 7: Edge case — empty path string
- **Description:** Call with an empty string path.
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot. Empty path is invalid.
- **Notes:** Zod passes an empty string.

#### Scenario 8: Edge case — delete a directory path instead of file
- **Description:** Try to delete using a directory path instead of a file path.
- **Params:** `{ "path": "res://resources" }`
- **Expected result:** Error. Godot should reject attempting to delete a directory as a resource.
- **Notes:** Resource deletion should be file-specific.

#### Scenario 9: Undo verification
- **Description:** After deleting a resource, verify that the undo system captured the operation.
- **Params:** `{ "path": "res://resources/undo_test.tres" }`
- **Expected result:** The delete should succeed and the undo stack should contain the operation. (Verification: manually check in Godot that Ctrl+Z restores the file.)
- **Notes:** All editor mutations in this toolset are wrapped in undo. Manual verification step for the tester.

---

## Tool: get_resource_preview

### Schema

```typescript
{
  description: 'Get a preview thumbnail of a resource',
  inputSchema: {
    path: ResourcePath,
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'resource/get_preview', args as Record<string, unknown>)
```

### Tool Behavior
Generates or retrieves a preview thumbnail for a resource. This is typically a small image representing the resource (e.g., a material sphere, a texture thumbnail). Returns the preview data — likely as base64-encoded image data or a reference to the preview file. Read-only operation.

### Test Scenarios

#### Scenario 1: Happy path — preview a Material resource
- **Description:** Get a preview thumbnail for a material resource.
- **Params:** `{ "path": "res://resources/test_material.tres" }`
- **Expected result:** Returns a thumbnail/preview of the material. The response should contain image data (likely base64 PNG) or a path to the generated preview.
- **Notes:** Materials typically have previews showing a sphere with the material applied.

#### Scenario 2: Happy path — preview a Texture resource
- **Description:** Get a preview thumbnail for a texture resource.
- **Params:** `{ "path": "res://assets/texture.png" }`
- **Expected result:** Returns a thumbnail of the texture. Should be a smaller/scaled version of the original.
- **Notes:** Textures should generate thumbnails easily.

#### Scenario 3: Happy path — preview a StyleBox resource
- **Description:** Get a preview thumbnail for a StyleBoxFlat resource.
- **Params:** `{ "path": "res://resources/test_stylebox.tres" }`
- **Expected result:** Returns a thumbnail showing the StyleBox appearance. May be a simple colored rectangle or the full styled box.
- **Notes:** UI resources may have simpler previews than 3D materials.

#### Scenario 4: Happy path — preview a script resource
- **Description:** Get a preview thumbnail for a GDScript file (treated as a resource).
- **Params:** `{ "path": "res://scripts/player.gd" }`
- **Expected result:** May return a generic script icon thumbnail, or an error if scripts don't support previews. Either outcome is acceptable.
- **Notes:** Not all resource types support preview generation.

#### Scenario 5: Missing required param — no path
- **Description:** Call `get_resource_preview` without the required `path`.
- **Params:** `{}`
- **Expected result:** Zod validation error. Should indicate `path` is required.
- **Notes:** Identical schema pattern to `read_resource`.

#### Scenario 6: Invalid path — nonexistent resource
- **Description:** Try to get a preview for a file that doesn't exist.
- **Params:** `{ "path": "res://nonexistent/fake.tres" }`
- **Expected result:** Error. Should report file not found.
- **Notes:** Standard missing-file error handling.

#### Scenario 7: Edge case — path to a directory
- **Description:** Try to get a preview of a directory path.
- **Params:** `{ "path": "res://resources" }`
- **Expected result:** Error. Directories don't have previews.
- **Notes:** The path should resolve to a file, not a directory.

#### Scenario 8: Edge case — preview a scene file
- **Description:** Get a preview for a `.tscn` scene file.
- **Params:** `{ "path": "res://scenes/main.tscn" }`
- **Expected result:** May return a scene thumbnail showing a mini view of the scene, or may return a generic scene icon. Should not error.
- **Notes:** Scene files are PackedScene resources; they have preview support in the Godot editor.

#### Scenario 9: Edge case — path with uppercase extension
- **Description:** Use a path with `.TRES` (uppercase) extension.
- **Params:** `{ "path": "res://resources/TEST.TRES" }`
- **Expected result:** Depends on OS. On Windows (case-insensitive), should work if the file exists. On case-sensitive filesystems, may fail if the actual file uses a different case.
- **Notes:** Cross-platform path handling test.

---

## Tool: add_autoload

### Schema

```typescript
{
  description: 'Add an autoload singleton to the project',
  inputSchema: {
    name: z.string().describe('Autoload name (becomes a global singleton)'),
    path: ResourcePath.describe('Script or scene path'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'resource/add_autoload', args as Record<string, unknown>)
```

### Tool Behavior
Registers a new autoload singleton in the project. The autoload becomes a globally accessible node in the scene tree, loaded before the main scene. Takes a name (the global identifier) and a path to a script (`.gd`) or scene (`.tscn`). This modifies `project.godot` in the `[autoload]` section. Returns success or an error if the name is already taken or the file doesn't exist.

### Test Scenarios

#### Scenario 1: Happy path — add a script autoload
- **Description:** Register a GDScript file as an autoload singleton.
- **Params:** `{ "name": "GlobalSettings", "path": "res://autoload/global_settings.gd" }`
- **Expected result:** Success. The autoload should be registered in `project.godot`. Calling `get_autoloads` (if exists) should list it. The singleton name `GlobalSettings` should be available in scripts.
- **Notes:** The script must exist at the given path and be a valid GDScript that extends Node (or a subclass).

#### Scenario 2: Happy path — add a scene autoload
- **Description:** Register a scene file as an autoload singleton.
- **Params:** `{ "name": "UIManager", "path": "res://scenes/ui_manager.tscn" }`
- **Expected result:** Success. The scene should be registered as an autoload. The root node of the scene becomes the singleton.
- **Notes:** Scene autoloads work similarly to script autoloads — the scene is instantiated at startup.

#### Scenario 3: Happy path — add autoload with snake_case name
- **Description:** Register an autoload with an underscore-separated name.
- **Params:** `{ "name": "global_audio_manager", "path": "res://autoload/audio_manager.gd" }`
- **Expected result:** Success. Underscores should be valid in autoload names.
- **Notes:** Godot autoload names should be valid identifiers (no spaces, no special chars except `_`).

#### Scenario 4: Missing required param — no name
- **Description:** Call `add_autoload` without the required `name`.
- **Params:** `{ "path": "res://autoload/test.gd" }`
- **Expected result:** Zod validation error. Should indicate `name` is required.
- **Notes:** Both name and path are required.

#### Scenario 5: Missing required param — no path
- **Description:** Call `add_autoload` without the required `path`.
- **Params:** `{ "name": "TestAutoload" }`
- **Expected result:** Zod validation error. Should indicate `path` is required.
- **Notes:** Both params are required.

#### Scenario 6: Invalid path — script does not exist
- **Description:** Try to add an autoload pointing to a script that doesn't exist.
- **Params:** `{ "name": "GhostAuto", "path": "res://nonexistent/ghost.gd" }`
- **Expected result:** Error from Godot. Should report that the script/scene file does not exist.
- **Notes:** Godot validates that the file exists before registering the autoload.

#### Scenario 7: Edge case — duplicate autoload name
- **Description:** Try to add an autoload with a name that is already registered.
- **Params:** `{ "name": "GlobalSettings", "path": "res://autoload/other_settings.gd" }` (after Scenario 1)
- **Expected result:** Error. Godot should report that an autoload with that name already exists.
- **Notes:** Autoload names must be unique within the project.

#### Scenario 8: Edge case — name with special characters
- **Description:** Try to register an autoload with a name containing spaces or special chars.
- **Params:** `{ "name": "My Autoload!", "path": "res://autoload/test.gd" }`
- **Expected result:** Error from Godot. Autoload names must be valid identifiers (alphanumeric + underscore, starting with a letter).
- **Notes:** Godot enforces identifier rules for autoload names.

#### Scenario 9: Edge case — empty name string
- **Description:** Try to register an autoload with an empty name.
- **Params:** `{ "name": "", "path": "res://autoload/test.gd" }`
- **Expected result:** Error. Empty string is not a valid autoload name. Zod passes; Godot should reject.
- **Notes:** Both Zod validation and Godot-side checks are relevant.

#### Scenario 10: Edge case — path to a non-script, non-scene file
- **Description:** Try to register a `.tres` resource file as an autoload.
- **Params:** `{ "name": "BadAuto", "path": "res://resources/test_material.tres" }`
- **Expected result:** Error from Godot. Autoloads must be scripts or scenes, not arbitrary resources.
- **Notes:** Godot validates the file type during autoload registration.

#### Scenario 11: Edge case — name starting with a digit
- **Description:** Try to register an autoload with a name that starts with a number.
- **Params:** `{ "name": "2DManager", "path": "res://autoload/manager.gd" }`
- **Expected result:** Error from Godot. Identifier names cannot start with a digit.
- **Notes:** Validates Godot's identifier naming rules.

#### Scenario 12: Edge case — path with `res://` prefix missing
- **Description:** Try to add an autoload with a path that doesn't use the `res://` scheme.
- **Params:** `{ "name": "BadPath", "path": "autoload/test.gd" }`
- **Expected result:** Error. Godot expects `res://` paths.
- **Notes:** Relative or absolute OS paths should be rejected.

---

## Tool: remove_autoload

### Schema

```typescript
{
  description: 'Remove an autoload singleton from the project',
  inputSchema: {
    name: z.string().describe('Autoload name to remove'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'resource/remove_autoload', args as Record<string, unknown>)
```

### Tool Behavior
Unregisters an autoload singleton from the project by name. Removes the entry from `project.godot`'s `[autoload]` section. The script/scene file itself is NOT deleted — only the autoload registration is removed. Returns success or an error if no autoload with that name exists.

### Test Scenarios

#### Scenario 1: Happy path — remove an existing autoload
- **Description:** Remove an autoload that was previously registered (e.g., one added in `add_autoload` Scenario 1).
- **Params:** `{ "name": "GlobalSettings" }`
- **Expected result:** Success. The autoload entry should be removed from `project.godot`. The singleton name should no longer be available.
- **Notes:** The script file should still exist on disk — only the registration is removed.

#### Scenario 2: Happy path — remove another autoload
- **Description:** Remove a different autoload to confirm the tool handles arbitrary names.
- **Params:** `{ "name": "UIManager" }` (from add_autoload Scenario 2)
- **Expected result:** Success. That autoload should be unregistered.
- **Notes:** Verify by re-registering the same name afterward — it should succeed (name is no longer taken).

#### Scenario 3: Missing required param — no name
- **Description:** Call `remove_autoload` without the required `name`.
- **Params:** `{}` (empty object)
- **Expected result:** Zod validation error. Should indicate `name` is required.
- **Notes:** Name is the only parameter, and it's required.

#### Scenario 4: Invalid name — autoload does not exist
- **Description:** Try to remove an autoload with a name that is not registered.
- **Params:** `{ "name": "NonExistentAutoload" }`
- **Expected result:** Error from Godot. Should report that no autoload with that name exists.
- **Notes:** Should not crash or modify project.godot incorrectly.

#### Scenario 5: Edge case — empty name string
- **Description:** Try to remove an autoload with an empty string name.
- **Params:** `{ "name": "" }`
- **Expected result:** Error from Godot. No autoload can have an empty name, so nothing to remove.
- **Notes:** Zod passes; Godot-side validation should handle it.

#### Scenario 6: Edge case — name with special characters
- **Description:** Try to remove an autoload with a name containing characters that can't be valid autoload identifiers.
- **Params:** `{ "name": "Not!A@Valid#Name" }`
- **Expected result:** Error. No autoload with this name exists (it couldn't have been created).
- **Notes:** Confirms that invalid names produce appropriate errors.

#### Scenario 7: Edge case — remove a built-in autoload
- **Description:** Try to remove a Godot built-in autoload (like `Input` or `OS`).
- **Params:** `{ "name": "Input" }`
- **Expected result:** Error. Built-in singletons cannot be removed via project autoload management.
- **Notes:** The tool should only affect project-level autoloads, not engine singletons.

#### Scenario 8: Double remove — remove the same autoload twice
- **Description:** Remove an autoload, then try to remove it again.
- **Params:** First call: `{ "name": "TestDoubleRemove" }` (after adding it); Second call: same params.
- **Expected result:** First call: success. Second call: error — autoload no longer exists.
- **Notes:** Tests idempotent failure behavior.

---

## Tool: duplicate_resource

### Schema

```typescript
{
  description: 'Duplicate a resource file',
  inputSchema: {
    source_path: ResourcePath.describe('Source resource path'),
    dest_path: z.string().describe('Destination path'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'resource/duplicate', args as Record<string, unknown>)
```

### Tool Behavior
Creates a copy of an existing resource file at a new path. The source file is left unchanged. The destination gets an independent copy with identical properties. Both paths use `res://` scheme. Returns success with the new resource's path or an error if the source doesn't exist or the destination is invalid.

### Test Scenarios

#### Scenario 1: Happy path — duplicate a `.tres` file
- **Description:** Copy an existing text resource to a new path.
- **Params:** `{ "source_path": "res://resources/test_stylebox.tres", "dest_path": "res://resources/test_stylebox_copy.tres" }`
- **Expected result:** Success. A new file should be created at the dest_path with identical content. Reading both resources should yield the same properties.
- **Notes:** The source must exist. Both files should be independently modifiable afterward.

#### Scenario 2: Happy path — duplicate a `.res` binary file
- **Description:** Copy an existing binary resource.
- **Params:** `{ "source_path": "res://resources/test_material.res", "dest_path": "res://resources/test_material_copy.res" }`
- **Expected result:** Success. Binary file duplicated correctly with identical properties.
- **Notes:** Binary resources should copy exactly.

#### Scenario 3: Happy path — duplicate to a different directory
- **Description:** Copy a resource to a different directory under `res://`.
- **Params:** `{ "source_path": "res://resources/test_stylebox.tres", "dest_path": "res://materials/duplicated_stylebox.tres" }`
- **Expected result:** Success. File appears in the new directory with the same content.
- **Notes:** Cross-directory duplication should work.

#### Scenario 4: Happy path — duplicate with a different name
- **Description:** Duplicate a resource changing only the filename.
- **Params:** `{ "source_path": "res://resources/test_curve.tres", "dest_path": "res://resources/test_curve_v2.tres" }`
- **Expected result:** Success. Both files exist independently in the same directory.
- **Notes:** Simple rename-on-copy scenario.

#### Scenario 5: Missing required param — no source_path
- **Description:** Call `duplicate_resource` without `source_path`.
- **Params:** `{ "dest_path": "res://resources/copy.tres" }`
- **Expected result:** Zod validation error. Should indicate `source_path` is required.
- **Notes:** Both source_path and dest_path are required.

#### Scenario 6: Missing required param — no dest_path
- **Description:** Call `duplicate_resource` without `dest_path`.
- **Params:** `{ "source_path": "res://resources/test_stylebox.tres" }`
- **Expected result:** Zod validation error. Should indicate `dest_path` is required.
- **Notes:** Both params are required; `dest_path` is `z.string()`, NOT `ResourcePath`.

#### Scenario 7: Invalid source_path — file does not exist
- **Description:** Try to duplicate a nonexistent source file.
- **Params:** `{ "source_path": "res://nonexistent/fake.tres", "dest_path": "res://resources/copy.tres" }`
- **Expected result:** Error from Godot. Should report that the source file was not found.
- **Notes:** Source must exist; the tool should not create a file from nothing.

#### Scenario 8: Invalid dest_path — parent directory doesn't exist
- **Description:** Try to duplicate to a path in a nonexistent directory.
- **Params:** `{ "source_path": "res://resources/test_stylebox.tres", "dest_path": "res://nonexistent_dir/copy.tres" }`
- **Expected result:** Error. Godot should report that the destination directory doesn't exist.
- **Notes:** The tool should not auto-create directories for the destination.

#### Scenario 9: Edge case — dest_path already exists
- **Description:** Try to duplicate to a path where a file already exists.
- **Params:** `{ "source_path": "res://resources/test_stylebox.tres", "dest_path": "res://resources/test_stylebox_copy.tres" }` (after Scenario 1)
- **Expected result:** Error. Godot should report that the destination already exists, or warn about overwriting. Should not silently overwrite.
- **Notes:** The exact behavior (error vs. confirmation) should be documented during testing.

#### Scenario 10: Edge case — source and dest are the same path
- **Description:** Try to duplicate a resource to its own path (self-copy).
- **Params:** `{ "source_path": "res://resources/test_stylebox.tres", "dest_path": "res://resources/test_stylebox.tres" }`
- **Expected result:** Error. Cannot duplicate a file onto itself.
- **Notes:** Edge case — Godot should detect and reject this.

#### Scenario 11: Edge case — duplicate a script file
- **Description:** Duplicate a GDScript file using the resource duplication tool.
- **Params:** `{ "source_path": "res://scripts/player.gd", "dest_path": "res://scripts/player_copy.gd" }`
- **Expected result:** Should succeed (scripts are resources too). The copy should be an identical script file.
- **Notes:** Tests that non-.tres/.res files also work as resources.

#### Scenario 12: Edge case — duplicate a scene file
- **Description:** Duplicate a `.tscn` scene file.
- **Params:** `{ "source_path": "res://scenes/main.tscn", "dest_path": "res://scenes/main_copy.tscn" }`
- **Expected result:** Success. Scene should be duplicated. UIDs in the new scene should be regenerated (not identical to source).
- **Notes:** Scene files are PackedScene resources. Godot may regenerate internal UIDs.

#### Scenario 13: Edge case — dest_path with uppercase extension
- **Description:** Duplicate to a path with `.TRES` (uppercase) extension.
- **Params:** `{ "source_path": "res://resources/test_stylebox.tres", "dest_path": "res://resources/UPPERCASE.TRES" }`
- **Expected result:** On case-insensitive filesystems (Windows), should work. On others, may create a file with uppercase extension.
- **Notes:** Cross-platform behavior note.

---

## Tool: list_resources

### Schema

```typescript
{
  description: 'List resources of a specific type in the project',
  inputSchema: {
    type: z.string().optional().describe('Resource type to filter by'),
    directory: z.string().optional().describe('Directory to search in'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'resource/list', args as Record<string, unknown>)
```

### Tool Behavior
Lists resources in the project, optionally filtered by resource type and/or directory. When called with no parameters, lists all resources. When `type` is specified, filters to only resources of that class. When `directory` is specified, scopes the search to that directory. Returns an array of resource entries (path, type, and optionally metadata). Read-only operation.

### Test Scenarios

#### Scenario 1: Happy path — list all resources (no filters)
- **Description:** Call `list_resources` with no parameters to list all resources in the project.
- **Params:** `{}` (empty object)
- **Expected result:** Returns an array of resource entries. Each entry should include at minimum `path` and `type` fields. The array should contain all `.tres`, `.res`, and other resource files in the project.
- **Notes:** This is the broadest query. Result size depends on the project.

#### Scenario 2: Happy path — list with no args (undefined)
- **Description:** Call `list_resources` with no arguments object at all.
- **Params:** `undefined`
- **Expected result:** Same as Scenario 1. Both `type` and `directory` are optional; omitting them entirely should work.
- **Notes:** Verifies the handler can handle missing args.

#### Scenario 3: Happy path — filter by resource type
- **Description:** List only resources of a specific type (e.g., `StyleBoxFlat`).
- **Params:** `{ "type": "StyleBoxFlat" }`
- **Expected result:** Returns only resources whose type is `StyleBoxFlat`. Other resource types should not appear in the results.
- **Notes:** The type should match exactly. Case sensitivity depends on Godot.

#### Scenario 4: Happy path — filter by directory
- **Description:** List only resources within a specific directory.
- **Params:** `{ "directory": "res://resources" }`
- **Expected result:** Returns only resources located under `res://resources/`. Resources in other directories should be excluded.
- **Notes:** Trailing slash behavior: test both `"res://resources"` and `"res://resources/"`.

#### Scenario 5: Happy path — filter by both type and directory
- **Description:** Combine type and directory filters.
- **Params:** `{ "type": "Gradient", "directory": "res://resources" }`
- **Expected result:** Returns only `Gradient` resources located under `res://resources/`. Both filters must apply.
- **Notes:** Tests combined filtering logic.

#### Scenario 6: Happy path — filter by Material type
- **Description:** List all material resources (broad type).
- **Params:** `{ "type": "Material" }`
- **Expected result:** Returns all materials (StandardMaterial3D, ShaderMaterial, etc.) if Godot supports base-class filtering. If not, returns only exact matches.
- **Notes:** Tests whether type filtering uses inheritance or exact class matching.

#### Scenario 7: Happy path — filter by Theme type
- **Description:** List all Theme resources.
- **Params:** `{ "type": "Theme" }`
- **Expected result:** Returns all `.tres` files that are Theme resources.
- **Notes:** Another common resource type.

#### Scenario 8: Edge case — nonexistent resource type
- **Description:** Filter by a type that doesn't exist in Godot.
- **Params:** `{ "type": "FakeResourceTypeXYZ" }`
- **Expected result:** Returns an empty array (no matching resources). Should NOT error — nonexistent type simply has no matches.
- **Notes:** Validates graceful handling of unknown types.

#### Scenario 9: Edge case — nonexistent directory
- **Description:** Filter by a directory that doesn't exist.
- **Params:** `{ "directory": "res://nonexistent_directory" }`
- **Expected result:** Returns an empty array. Should not error — directory has no resources.
- **Notes:** Graceful handling of missing directories.

#### Scenario 10: Edge case — empty string type
- **Description:** Filter by an empty string type.
- **Params:** `{ "type": "" }`
- **Expected result:** May return all resources (empty string treated as "no filter") or an empty array. Should not error.
- **Notes:** Document actual behavior observed.

#### Scenario 11: Edge case — empty string directory
- **Description:** Filter by an empty string directory.
- **Params:** `{ "directory": "" }`
- **Expected result:** May return all resources or an empty array. Should not error.
- **Notes:** Empty directory could mean project root or be invalid.

#### Scenario 12: Edge case — type with extra whitespace
- **Description:** Filter by a type with leading/trailing spaces.
- **Params:** `{ "type": "  StyleBoxFlat  " }`
- **Expected result:** Depends on Godot. May trim whitespace and match, or may fail to match (treated as literal). Should not crash.
- **Notes:** Tests input sanitization on the Godot side.

#### Scenario 13: Large result set
- **Description:** List all resources in a large project without filters.
- **Params:** `{}`
- **Expected result:** Returns complete results without truncation. Should not time out on a typical project.
- **Notes:** Performance test — verifies the tool can handle large result sets.

---

## Tool: get_resource_dependencies

### Schema

```typescript
{
  description: 'Get all dependencies of a resource file',
  inputSchema: {
    path: ResourcePath,
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'resource/get_dependencies', args as Record<string, unknown>)
```

### Tool Behavior
Analyzes a resource file and returns all other files/resources that it depends on. For example, a scene file depends on its scripts, textures, materials, and sub-scenes. A material depends on its shaders and textures. Returns an array of dependency paths (or a structured dependency graph). Read-only operation.

### Test Scenarios

#### Scenario 1: Happy path — get dependencies of a scene
- **Description:** Query dependencies of a `.tscn` scene file. Scenes typically have many dependencies.
- **Params:** `{ "path": "res://scenes/main.tscn" }`
- **Expected result:** Returns an array of paths that the scene depends on. Should include attached scripts, instanced scenes, textures, materials, etc. Each entry should include the dependency path and type.
- **Notes:** This is the most useful scenario — understanding what a scene references.

#### Scenario 2: Happy path — get dependencies of a material
- **Description:** Query dependencies of a material resource.
- **Params:** `{ "path": "res://resources/test_material.tres" }`
- **Expected result:** Returns dependencies — likely the shader and any textures used by the material.
- **Notes:** Material dependencies are simpler than scene dependencies.

#### Scenario 3: Happy path — get dependencies of a standalone resource (no deps)
- **Description:** Query dependencies of a resource that references nothing else.
- **Params:** `{ "path": "res://resources/test_curve.tres" }` (Curve typically has no external dependencies)
- **Expected result:** Returns an empty array or a result indicating no dependencies. Should succeed, not error.
- **Notes:** Validates that empty dependency lists are handled correctly.

#### Scenario 4: Happy path — get dependencies of a script
- **Description:** Query dependencies of a GDScript file.
- **Params:** `{ "path": "res://scripts/player.gd" }`
- **Expected result:** Returns dependencies — may include the script's base class and any preloaded resources.
- **Notes:** Scripts can `preload()` or `load()` other resources, which should show as dependencies.

#### Scenario 5: Happy path — get dependencies of a theme
- **Description:** Query dependencies of a Theme resource.
- **Params:** `{ "path": "res://themes/default_theme.tres" }`
- **Expected result:** Returns dependencies — may include font files, stylebox resources, and icon textures.
- **Notes:** Themes often reference fonts and textures.

#### Scenario 6: Missing required param — no path
- **Description:** Call `get_resource_dependencies` without the required `path`.
- **Params:** `{}`
- **Expected result:** Zod validation error. Should indicate `path` is required.
- **Notes:** Single required parameter.

#### Scenario 7: Invalid path — file does not exist
- **Description:** Try to get dependencies of a nonexistent file.
- **Params:** `{ "path": "res://nonexistent/fake.tres" }`
- **Expected result:** Error from Godot. Should report file not found.
- **Notes:** Standard error handling for missing paths.

#### Scenario 8: Edge case — path to a directory
- **Description:** Try to get dependencies of a directory path.
- **Params:** `{ "path": "res://resources" }`
- **Expected result:** Error. A directory is not a resource file with dependencies.
- **Notes:** Path should resolve to a file.

#### Scenario 9: Edge case — empty path string
- **Description:** Call with an empty string path.
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot. Empty path does not resolve to a resource.
- **Notes:** Zod passes; Godot validation rejects.

#### Scenario 10: Edge case — deeply nested dependencies
- **Description:** Get dependencies of a scene that includes multiple levels of nested instanced scenes and complex resources.
- **Params:** `{ "path": "res://scenes/complex_level.tscn" }`
- **Expected result:** Returns all direct dependencies. Should NOT include transitive dependencies (dependencies of dependencies) unless the tool specifically supports recursive resolution.
- **Notes:** Dependency resolution depth should be documented during testing. If the tool only returns direct dependencies, note that.

#### Scenario 11: Edge case — circular dependencies
- **Description:** If the project has circular references (A depends on B, B depends on A), query one of them.
- **Params:** `{ "path": "res://resources/circular_a.tres" }`
- **Expected result:** Should return dependencies without infinite recursion. Should not hang or crash.
- **Notes:** Validates that dependency resolution handles or reports circular references.

---

## Cross-Tool Integration Scenarios

These scenarios test interactions between multiple resource tools, simulating real workflows.

### Integration 1: Create → Read → Edit → Delete lifecycle
- **Steps:**
  1. `create_resource`: `{ "type": "StyleBoxFlat", "path": "res://resources/lifecycle_test.tres" }` → success
  2. `read_resource`: `{ "path": "res://resources/lifecycle_test.tres" }` → returns default StyleBoxFlat properties
  3. `edit_resource`: `{ "path": "res://resources/lifecycle_test.tres", "properties": { "bg_color": "#FF0000", "border_width_left": 5 } }` → success
  4. `read_resource`: `{ "path": "res://resources/lifecycle_test.tres" }` → returns updated properties with `bg_color` = `#FF0000`
  5. `delete_resource`: `{ "path": "res://resources/lifecycle_test.tres" }` → success
  6. `read_resource`: `{ "path": "res://resources/lifecycle_test.tres" }` → error, file not found
- **Expected result:** Full lifecycle works end-to-end without errors.

### Integration 2: Autoload add → verify → remove → verify
- **Steps:**
  1. `add_autoload`: `{ "name": "IntegrationTest", "path": "res://autoload/test_autoload.gd" }` → success
  2. `list_resources`: `{ "type": "GDScript", "directory": "res://autoload" }` → should list the script
  3. `remove_autoload`: `{ "name": "IntegrationTest" }` → success
  4. `add_autoload`: `{ "name": "IntegrationTest", "path": "res://autoload/test_autoload.gd" }` → success (name is free again)
  5. `remove_autoload`: `{ "name": "IntegrationTest" }` → success (cleanup)
- **Expected result:** Autoload lifecycle works correctly. Re-registering after removal should succeed.

### Integration 3: Duplicate → compare → modify independently
- **Steps:**
  1. `create_resource`: `{ "type": "StyleBoxFlat", "path": "res://resources/duplicate_original.tres", "properties": { "bg_color": "#0000FF" } }` → success
  2. `duplicate_resource`: `{ "source_path": "res://resources/duplicate_original.tres", "dest_path": "res://resources/duplicate_copy.tres" }` → success
  3. `read_resource`: `{ "path": "res://resources/duplicate_original.tres" }` → bg_color = `#0000FF`
  4. `read_resource`: `{ "path": "res://resources/duplicate_copy.tres" }` → bg_color = `#0000FF` (identical)
  5. `edit_resource`: `{ "path": "res://resources/duplicate_copy.tres", "properties": { "bg_color": "#00FF00" } }` → success
  6. `read_resource`: `{ "path": "res://resources/duplicate_original.tres" }` → bg_color = `#0000FF` (unchanged)
  7. `read_resource`: `{ "path": "res://resources/duplicate_copy.tres" }` → bg_color = `#00FF00` (independent copy)
  8. Cleanup: `delete_resource` both files.
- **Expected result:** Duplication creates independent copies. Modifying one does not affect the other.

### Integration 4: List → filter by type → verify completeness
- **Steps:**
  1. `list_resources`: `{}` → record total resource count and all paths
  2. `list_resources`: `{ "type": "StyleBoxFlat" }` → record StyleBoxFlat count
  3. `list_resources`: `{ "type": "Theme" }` → record Theme count
  4. Sum of all type-specific counts should be ≤ total count (may be less if some resources have types not explicitly queried).
- **Expected result:** Filtered results are subsets of the full list.

---

## Test Data Setup

Before running these tests, ensure the following test fixtures exist in the project:

| Fixture | Path | How to create |
|---------|------|---------------|
| Test StyleBox | `res://resources/test_stylebox.tres` | `create_resource` with type `StyleBoxFlat` |
| Test Material | `res://resources/test_material.tres` | `create_resource` with type `StandardMaterial3D` |
| Test Gradient | `res://resources/test_gradient.tres` | `create_resource` with type `Gradient` |
| Test Curve | `res://resources/test_curve.tres` | `create_resource` with type `Curve` |
| Test Autoload Script | `res://autoload/test_autoload.gd` | Existing script or `create_script` |
| Test Scene | `res://scenes/main.tscn` | Should already exist in any project |
| Test Theme | `res://themes/default_theme.tres` | Create a basic Theme resource |

All destructive tests should operate on copies or newly-created resources, never on project-critical files.

---

## Cleanup Guidelines

After running the test suite, clean up test artifacts:
1. Remove any autoloads added during testing via `remove_autoload`
2. Delete test resource files created in `res://resources/` via `delete_resource`
3. Verify `list_resources` shows no leftover test files

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Accidental deletion of project resources | High | Only test deletion on known test files; never use `delete_resource` on project sources without explicit backup |
| Autoload misconfiguration breaking project launch | Medium | Always remove test autoloads after testing; verify `project.godot` after test session |
| Resource file corruption from malformed properties | Low | Use disposable test resources; test property edits on copies |
| Large result sets from `list_resources` causing timeouts | Low | Validated in Scenario 13; typical projects have manageable resource counts |
