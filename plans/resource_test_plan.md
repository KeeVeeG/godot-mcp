# Test Plan: Resource Tools (`server/src/tools/resource.ts`)

> **Source file**: `server/src/tools/resource.ts`
> **Shared types**: `server/src/tools/shared-types.ts`
> **Registration function**: `registerResourceTools(server, bridge)`
> **Tools count**: 10 tools

## Overview

All resource tools communicate with Godot via `callGodot(bridge, method, args)` which sends a JSON-RPC request over WebSocket to the Godot editor plugin. Each tool maps to a `resource/<action>` method on the Godot side.

**Common schema types used across tools:**

| Schema | Type | Description |
|---|---|---|
| `ResourcePath` | `z.string()` | Resource file path (e.g. `'res://assets/theme.tres'`) |
| `Properties` | `z.record(z.unknown())` | Required property key-value pairs |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | Optional property key-value pairs |

---

## Tool: `read_resource`

**Description**: Read a Godot resource file (.tres, .res) and get its properties

**Bridge method**: `resource/read`

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | `string` (`ResourcePath`) | Yes | Resource file path (e.g. `'res://assets/theme.tres'`) |

**Handler logic**: Forwards `{ path }` to Godot via `resource/read`. Returns the resource's properties as JSON.

### Test Scenarios

#### 1.1 — Happy path: read an existing .tres resource

```
Given: A Godot project with an existing resource at "res://assets/default_theme.tres"
When:  Call read_resource with path = "res://assets/default_theme.tres"
Then:  Returns a JSON object with the resource's type and all its serialized properties
```

**Call:**
```json
{ "path": "res://assets/default_theme.tres" }
```

**Expected result**: A JSON text response containing the resource class type (e.g. `"Theme"`) and its property key-value pairs. Response must not have `isError: true`.

**Notes:** The exact properties depend on the resource type. For a Theme resource, expect color/font/stylebox overrides. Verify the response is parseable JSON.

---

#### 1.2 — Happy path: read a .res binary resource

```
Given: A Godot project with a binary resource at "res://assets/icon.res"
When:  Call read_resource with path = "res://assets/icon.res"
Then:  Returns the resource properties
```

**Call:**
```json
{ "path": "res://assets/icon.res" }
```

**Expected result**: JSON text with resource properties. Binary resources may have fewer human-readable properties than .tres (text-based) resources.

**Notes:** `.res` is Godot's binary resource format. The tool should handle both formats identically from the API perspective.

---

#### 1.3 — Error: resource file does not exist

```
Given: No file at "res://nonexistent/resource.tres"
When:  Call read_resource with path = "res://nonexistent/resource.tres"
Then:  Returns an error result
```

**Call:**
```json
{ "path": "res://nonexistent/resource.tres" }
```

**Expected result**: Response with `isError: true` containing a message about the file not being found.

**Notes:** Check that the error message is descriptive (mentions the path or "not found"). The Godot side should return an error that `callGodot` catches and wraps.

---

#### 1.4 — Edge case: path with special characters

```
Given: A resource at "res://assets/my resource (copy).tres"
When:  Call read_resource with path = "res://assets/my resource (copy).tres"
Then:  Returns the resource properties successfully
```

**Call:**
```json
{ "path": "res://assets/my resource (copy).tres" }
```

**Expected result**: Successful response or a clear error if Godot doesn't support this path. Spaces and parentheses in paths are valid in Godot.

---

#### 1.5 — Edge case: path without res:// prefix

```
Given: A resource at "res://assets/theme.tres"
When:  Call read_resource with path = "assets/theme.tres" (missing res:// prefix)
Then:  Returns an error or handles gracefully
```

**Call:**
```json
{ "path": "assets/theme.tres" }
```

**Expected result**: Error result. Godot expects `res://` prefixed paths. Verify the error message indicates the path issue.

---

## Tool: `edit_resource`

**Description**: Edit properties of an existing resource

**Bridge method**: `resource/edit`

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | `string` (`ResourcePath`) | Yes | Resource file path |
| `properties` | `Record<string, unknown>` (`Properties`) | Yes | Properties to set |

**Handler logic**: Forwards `{ path, properties }` to Godot via `resource/edit`. Godot applies the property changes with undo/redo support.

### Test Scenarios

#### 2.1 — Happy path: edit a single property on a theme resource

```
Given: An existing Theme resource at "res://assets/ui_theme.tres"
When:  Call edit_resource with path = "res://assets/ui_theme.tres", properties = { "default_font_size": 18 }
Then:  Returns success, property is updated in the resource
```

**Call:**
```json
{
  "path": "res://assets/ui_theme.tres",
  "properties": { "default_font_size": 18 }
}
```

**Expected result**: Success response. After the call, reading the resource back should show `default_font_size: 18`.

**Notes:** Verify by following up with `read_resource` on the same path. Godot's undo system should record this change.

---

#### 2.2 — Happy path: edit multiple properties at once

```
Given: An existing StyleBoxFlat resource at "res://assets/button_style.tres"
When:  Call edit_resource with multiple properties
Then:  All properties are updated atomically
```

**Call:**
```json
{
  "path": "res://assets/button_style.tres",
  "properties": {
    "bg_color": "#333333",
    "border_width_left": 2,
    "border_width_right": 2,
    "border_color": "#ffffff",
    "corner_radius_top_left": 8
  }
}
```

**Expected result**: Success response. All five properties should be set. Verify with `read_resource`.

**Notes:** This tests batch property editing. In Godot, these are applied as a single undo action.

---

#### 2.3 — Error: resource does not exist

```
Given: No resource at "res://missing/resource.tres"
When:  Call edit_resource with path = "res://missing/resource.tres", properties = { "some_prop": 1 }
Then:  Returns error
```

**Call:**
```json
{
  "path": "res://missing/resource.tres",
  "properties": { "some_prop": 1 }
}
```

**Expected result**: `isError: true` with message about resource not found.

---

#### 2.4 — Edge case: set property to null/empty

```
Given: A resource with a string property set
When:  Call edit_resource to set a property to null
Then:  Property is cleared/reset to default
```

**Call:**
```json
{
  "path": "res://assets/ui_theme.tres",
  "properties": { "default_font": null }
}
```

**Expected result**: Success. The property should be cleared. Verify with `read_resource`.

**Notes:** In Godot, setting a resource property to `null` typically resets it to its default value.

---

#### 2.5 — Edge case: empty properties object

```
Given: An existing resource
When:  Call edit_resource with properties = {}
Then:  Returns success (no-op) or error
```

**Call:**
```json
{
  "path": "res://assets/ui_theme.tres",
  "properties": {}
}
```

**Expected result**: Either success (no changes made) or an error indicating empty properties. The behavior should be consistent — document which outcome occurs.

---

## Tool: `create_resource`

**Description**: Create a new Godot resource

**Bridge method**: `resource/create`

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `type` | `string` | Yes | Resource type (e.g. `'StyleBoxFlat'`, `'Gradient'`, `'Curve'`) |
| `path` | `string` (`ResourcePath`) | Yes | File path for the new resource |
| `properties` | `Record<string, unknown>` (optional, `OptionalProperties`) | No | Initial property values |

**Handler logic**: Forwards `{ type, path, properties }` to Godot via `resource/create`. Godot creates a new resource of the given type, applies optional initial properties, and saves it to disk.

### Test Scenarios

#### 3.1 — Happy path: create a StyleBoxFlat resource with no initial properties

```
Given: A Godot project, no file at "res://assets/new_style.tres"
When:  Call create_resource with type = "StyleBoxFlat", path = "res://assets/new_style.tres"
Then:  Resource file is created with default StyleBoxFlat properties
```

**Call:**
```json
{
  "type": "StyleBoxFlat",
  "path": "res://assets/new_style.tres"
}
```

**Expected result**: Success response. Verify the file exists by calling `read_resource` on the same path. The returned properties should match StyleBoxFlat defaults.

**Notes:** After this test, the file `res://assets/new_style.tres` exists on disk and can be used in subsequent tests.

---

#### 3.2 — Happy path: create a Gradient resource with initial properties

```
Given: A Godot project
When:  Call create_resource with type, path, and initial properties
Then:  Resource is created with the specified initial values
```

**Call:**
```json
{
  "type": "Gradient",
  "path": "res://assets/gradient_sunrise.tres",
  "properties": {
    "offsets": [0.0, 0.5, 1.0],
    "colors": ["#ff0000", "#ff8800", "#ffff00"]
  }
}
```

**Expected result**: Success. Verify with `read_resource` that the gradient has the specified offsets and colors.

---

#### 3.3 — Happy path: create a Curve resource

```
Given: A Godot project
When:  Call create_resource with type = "Curve", path = "res://assets/my_curve.tres"
Then:  A Curve resource is created
```

**Call:**
```json
{
  "type": "Curve",
  "path": "res://assets/my_curve.tres"
}
```

**Expected result**: Success. Verify the resource type is `Curve` via `read_resource`.

---

#### 3.4 — Error: resource type does not exist

```
Given: A Godot project
When:  Call create_resource with type = "NonExistentResourceType123"
Then:  Returns error
```

**Call:**
```json
{
  "type": "NonExistentResourceType123",
  "path": "res://assets/bad.tres"
}
```

**Expected result**: `isError: true` with message indicating the resource type is unknown.

---

#### 3.5 — Error: path already exists (overwrite behavior)

``Given: A resource already exists at "res://assets/new_style.tres" (created in scenario 3.1)
When:  Call create_resource with the same path
Then:  Returns error about file already existing, OR overwrites silently
```

**Call:**
```json
{
  "type": "StyleBoxFlat",
  "path": "res://assets/new_style.tres"
}
```

**Expected result**: Document the behavior — does it error or overwrite? Both are valid designs, but the test must capture which one occurs.

**Notes:** This is important for understanding whether callers need to check for existence first.

---

#### 3.6 — Edge case: create with invalid property names

```
Given: A Godot project
When:  Call create_resource with type = "StyleBoxFlat" and a non-existent property
Then:  Returns error about unknown property, OR ignores invalid properties
```

**Call:**
```json
{
  "type": "StyleBoxFlat",
  "path": "res://assets/bad_props.tres",
  "properties": {
    "nonexistent_property_xyz": 42
  }
}
```

**Expected result**: Document whether Godot rejects unknown properties or silently ignores them.

---

## Tool: `delete_resource`

**Description**: Delete a Godot resource file (.tres, .res) from the project

**Bridge method**: `resource/delete`

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | `string` (`ResourcePath`) | Yes | Resource file path to delete |

**Handler logic**: Forwards `{ path }` to Godot via `resource/delete`. Godot removes the file from disk and updates the project.

### Test Scenarios

#### 4.1 — Happy path: delete an existing resource

```
Given: A resource exists at "res://assets/to_delete.tres" (create it first with create_resource)
When:  Call delete_resource with path = "res://assets/to_delete.tres"
Then:  File is deleted, subsequent read_resource returns error
```

**Call:**
```json
{ "path": "res://assets/to_delete.tres" }
```

**Expected result**: Success response. Follow up with `read_resource` on the same path — it should return an error confirming the file is gone.

**Notes:** Use `create_resource` first to ensure the file exists. This tests the full create→delete lifecycle.

---

#### 4.2 — Error: resource does not exist

```
Given: No file at "res://nonexistent/fake.tres"
When:  Call delete_resource with path = "res://nonexistent/fake.tres"
Then:  Returns error
```

**Call:**
```json
{ "path": "res://nonexistent/fake.tres" }
```

**Expected result**: `isError: true` with message about file not found.

---

#### 4.3 — Edge case: delete a resource referenced by other resources

```
Given: Resource A at "res://assets/base.tres" is depended upon by Resource B
When:  Call delete_resource on Resource A
Then:  Returns error about dependencies, OR deletes and breaks references
```

**Call:**
```json
{ "path": "res://assets/base.tres" }
```

**Expected result**: Document behavior. Godot may warn or refuse to delete resources that are in use. Check if the error message mentions the dependency.

**Notes:** Use `get_resource_dependencies` to find a resource with dependents before running this test.

---

## Tool: `get_resource_preview`

**Description**: Get a preview thumbnail of a resource

**Bridge method**: `resource/get_preview`

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | `string` (`ResourcePath`) | Yes | Resource file path |

**Handler logic**: Forwards `{ path }` to Godot via `resource/get_preview`. Returns a preview image (likely base64-encoded PNG or a URL).

### Test Scenarios

#### 5.1 — Happy path: get preview of a texture resource

```
Given: A texture resource at "res://icon.svg" (Godot default project icon)
When:  Call get_resource_preview with path = "res://icon.svg"
Then:  Returns an image/thumbnail data
```

**Call:**
```json
{ "path": "res://icon.svg" }
```

**Expected result**: Response containing image data (base64 string, data URL, or binary reference). Verify it is not an error.

**Notes:** The format of the preview depends on Godot's implementation. It may be a base64-encoded PNG, a file path to a cached thumbnail, or a data URL. Document the exact format.

---

#### 5.2 — Happy path: get preview of a scene resource

```
Given: A scene file at "res://scenes/main.tscn"
When:  Call get_resource_preview with path = "res://scenes/main.tscn"
Then:  Returns a scene preview thumbnail
```

**Call:**
```json
{ "path": "res://scenes/main.tscn" }
```

**Expected result**: Preview image data. Scene previews are generated by Godot's editor thumbnail system.

---

#### 5.3 — Error: resource has no preview

```
Given: A text-based resource (e.g. a GDScript) at "res://scripts/player.gd"
When:  Call get_resource_preview with path = "res://scripts/player.gd"
Then:  Returns an error or a default/empty preview
```

**Call:**
```json
{ "path": "res://scripts/player.gd" }
```

**Expected result**: Either an error (scripts don't have visual previews) or a default icon. Document which behavior occurs.

---

#### 5.4 — Error: resource does not exist

```
Given: No file at "res://missing/texture.png"
When:  Call get_resource_preview with path = "res://missing/texture.png"
Then:  Returns error
```

**Call:**
```json
{ "path": "res://missing/texture.png" }
```

**Expected result**: `isError: true`.

---

## Tool: `add_autoload`

**Description**: Add an autoload singleton to the project

**Bridge method**: `resource/add_autoload`

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `name` | `string` | Yes | Autoload name (becomes a global singleton) |
| `path` | `string` (`ResourcePath`) | Yes | Script or scene path |

**Handler logic**: Forwards `{ name, path }` to Godot via `resource/add_autoload`. Registers a new autoload entry in `project.godot`'s `[autoload]` section.

### Test Scenarios

#### 6.1 — Happy path: add a script as autoload

```
Given: A script at "res://scripts/game_manager.gd"
When:  Call add_autoload with name = "GameManager", path = "res://scripts/game_manager.gd"
Then:  Autoload is registered, accessible as global singleton "GameManager"
```

**Call:**
```json
{
  "name": "GameManager",
  "path": "res://scripts/game_manager.gd"
}
```

**Expected result**: Success response. Verify by checking `project.godot` or by calling a project config read tool to confirm the autoload entry exists.

**Notes:** After adding, the autoload should appear in Project Settings → AutoLoad. The name becomes a global singleton accessible from any script as `GameManager`.

---

#### 6.2 — Happy path: add a scene as autoload

```
Given: A scene at "res://scenes/autoload_ui.tscn"
When:  Call add_autoload with name = "AutoloadUI", path = "res://scenes/autoload_ui.tscn"
Then:  Scene is registered as autoload singleton
```

**Call:**
```json
{
  "name": "AutoloadUI",
  "path": "res://scenes/autoload_ui.tscn"
}
```

**Expected result**: Success. Autoloads can be scenes, not just scripts.

---

#### 6.3 — Error: autoload name already exists

```
Given: An autoload named "GameManager" already exists (from scenario 6.1)
When:  Call add_autoload with name = "GameManager", path = "res://scripts/other.gd"
Then:  Returns error about duplicate name
```

**Call:**
```json
{
  "name": "GameManager",
  "path": "res://scripts/other.gd"
}
```

**Expected result**: `isError: true` with message about the autoload name already being registered.

---

#### 6.4 — Error: path does not point to a valid script or scene

```
Given: No valid script/scene at "res://nonexistent/fake.gd"
When:  Call add_autoload with name = "Fake", path = "res://nonexistent/fake.gd"
Then:  Returns error
```

**Call:**
```json
{
  "name": "Fake",
  "path": "res://nonexistent/fake.gd"
}
```

**Expected result**: `isError: true`. Godot validates that the path points to a valid script or scene.

---

#### 6.5 — Edge case: name with special characters

```
Given: A valid script
When:  Call add_autoload with name = "My-Singleton_v2"
Then:  Either accepts or rejects the name
```

**Call:**
```json
{
  "name": "My-Singleton_v2",
  "path": "res://scripts/game_manager.gd"
}
```

**Expected result**: Document whether Godot accepts non-alphanumeric autoload names. GDScript identifiers have restrictions — hyphens may be invalid.

---

## Tool: `remove_autoload`

**Description**: Remove an autoload singleton from the project

**Bridge method**: `resource/remove_autoload`

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `name` | `string` | Yes | Autoload name to remove |

**Handler logic**: Forwards `{ name }` to Godot via `resource/remove_autoload`. Removes the autoload entry from `project.godot`.

### Test Scenarios

#### 7.1 — Happy path: remove an existing autoload

```
Given: Autoload "GameManager" exists (added in scenario 6.1)
When:  Call remove_autoload with name = "GameManager"
Then:  Autoload is removed from the project
```

**Call:**
```json
{ "name": "GameManager" }
```

**Expected result**: Success response. Verify the autoload no longer appears in project settings.

**Notes:** This is the cleanup counterpart to `add_autoload`. Always pair add/remove in tests to avoid polluting the project.

---

#### 7.2 — Error: autoload name does not exist

```
Given: No autoload named "NonExistentSingleton"
When:  Call remove_autoload with name = "NonExistentSingleton"
Then:  Returns error
```

**Call:**
```json
{ "name": "NonExistentSingleton" }
```

**Expected result**: `isError: true` with message about the autoload not being found.

---

#### 7.3 — Edge case: remove autoload that was already removed (double remove)

```
Given: Autoload "GameManager" was already removed in scenario 7.1
When:  Call remove_autoload with name = "GameManager" again
Then:  Returns error (same as 7.2)
```

**Call:**
```json
{ "name": "GameManager" }
```

**Expected result**: `isError: true`. Idempotent failure — removing a non-existent autoload should fail cleanly.

---

## Tool: `duplicate_resource`

**Description**: Duplicate a resource file

**Bridge method**: `resource/duplicate`

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `source_path` | `string` (`ResourcePath`) | Yes | Source resource path |
| `dest_path` | `string` | Yes | Destination path |

**Handler logic**: Forwards `{ source_path, dest_path }` to Godot via `resource/duplicate`. Copies the resource file to the new location.

### Test Scenarios

#### 8.1 — Happy path: duplicate a .tres resource

```
Given: A resource at "res://assets/original.tres" (created via create_resource)
When:  Call duplicate_resource with source_path = "res://assets/original.tres", dest_path = "res://assets/copy.tres"
Then:  New file exists at dest_path with identical properties
```

**Call:**
```json
{
  "source_path": "res://assets/original.tres",
  "dest_path": "res://assets/copy.tres"
}
```

**Expected result**: Success response. Verify by calling `read_resource` on both paths — properties should match.

**Notes:** After test, clean up both files with `delete_resource`.

---

#### 8.2 — Happy path: duplicate to a different directory

```
Given: A resource at "res://assets/theme.tres"
When:  Call duplicate_resource with dest_path in a different folder
Then:  Resource is copied to the new location
```

**Call:**
```json
{
  "source_path": "res://assets/theme.tres",
  "dest_path": "res://ui/themes/theme_copy.tres"
}
```

**Expected result**: Success. The destination directory must exist or Godot must create it.

---

#### 8.3 — Error: source does not exist

```
Given: No file at "res://missing/source.tres"
When:  Call duplicate_resource with source_path = "res://missing/source.tres"
Then:  Returns error
```

**Call:**
```json
{
  "source_path": "res://missing/source.tres",
  "dest_path": "res://assets/copy.tres"
}
```

**Expected result**: `isError: true`.

---

#### 8.4 — Error: destination already exists (overwrite behavior)

``Given: Source exists at "res://assets/original.tres", destination already exists at "res://assets/copy.tres"
When:  Call duplicate_resource
Then:  Returns error about existing file, OR overwrites silently
```

**Call:**
```json
{
  "source_path": "res://assets/original.tres",
  "dest_path": "res://assets/copy.tres"
}
```

**Expected result**: Document whether it errors or overwrites. This is critical for callers to know.

---

#### 8.5 — Edge case: duplicate a resource that has dependencies

```
Given: A resource that references other resources (e.g. a Theme with StyleBox sub-resources)
When:  Call duplicate_resource
Then:  The duplicate is a deep copy (independent) or a shallow copy (shared references)
```

**Call:**
```json
{
  "source_path": "res://assets/complex_theme.tres",
  "dest_path": "res://assets/theme_copy.tres"
}
```

**Expected result**: Document whether the copy shares sub-resources or is fully independent. Use `get_resource_dependencies` on both to compare.

---

## Tool: `list_resources`

**Description**: List resources of a specific type in the project

**Bridge method**: `resource/list`

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `type` | `string` (optional) | No | Resource type to filter by |
| `directory` | `string` (optional) | No | Directory to search in |

**Handler logic**: Forwards `{ type?, directory? }` to Godot via `resource/list`. Returns a list of matching resource paths.

### Test Scenarios

#### 9.1 — Happy path: list all resources (no filters)

```
Given: A Godot project with various resources
When:  Call list_resources with no parameters
Then:  Returns a list of all resource files in the project
```

**Call:**
```json
{}
```

**Expected result**: JSON array or object listing all `.tres` and `.res` files in the project. Should include paths and possibly types.

---

#### 9.2 — Happy path: filter by resource type

```
Given: A project with multiple Theme and StyleBoxFlat resources
When:  Call list_resources with type = "Theme"
Then:  Returns only Theme resources
```

**Call:**
```json
{ "type": "Theme" }
```

**Expected result**: List containing only resources of type `Theme`. Verify none of the results are of a different type.

---

#### 9.3 — Happy path: filter by directory

```
Given: Resources scattered across multiple directories
When:  Call list_resources with directory = "res://assets/themes/"
Then:  Returns only resources in that directory
```

**Call:**
```json
{ "directory": "res://assets/themes/" }
```

**Expected result**: List of resources under `res://assets/themes/`. No resources from other directories.

---

#### 9.4 — Happy path: filter by both type and directory

```
Given: Multiple resource types across multiple directories
When:  Call list_resources with type = "StyleBoxFlat" and directory = "res://assets/"
Then:  Returns StyleBoxFlat resources only in res://assets/
```

**Call:**
```json
{
  "type": "StyleBoxFlat",
  "directory": "res://assets/"
}
```

**Expected result**: Intersection of both filters — only StyleBoxFlat resources in the specified directory.

---

#### 9.5 — Edge case: no resources match the filter

```
Given: A project with no Curve resources
When:  Call list_resources with type = "Curve"
Then:  Returns empty list (not an error)
```

**Call:**
```json
{ "type": "Curve" }
```

**Expected result**: Empty list/array. This should NOT be an error — empty results are valid.

---

#### 9.6 — Edge case: directory does not exist

```
Given: No directory at "res://nonexistent_folder/"
When:  Call list_resources with directory = "res://nonexistent_folder/"
Then:  Returns empty list or error
```

**Call:**
```json
{ "directory": "res://nonexistent_folder/" }
```

**Expected result**: Document behavior — empty list or error. Both are acceptable but the test must capture which.

---

## Tool: `get_resource_dependencies`

**Description**: Get all dependencies of a resource file

**Bridge method**: `resource/get_dependencies`

**Parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | `string` (`ResourcePath`) | Yes | Resource file path |

**Handler logic**: Forwards `{ path }` to Godot via `resource/get_dependencies`. Returns a list of resources that the given resource depends on.

### Test Scenarios

#### 10.1 — Happy path: get dependencies of a scene

```
Given: A scene at "res://scenes/main.tscn" that uses scripts, textures, and materials
When:  Call get_resource_dependencies with path = "res://scenes/main.tscn"
Then:  Returns a list of all resources the scene references
```

**Call:**
```json
{ "path": "res://scenes/main.tscn" }
```

**Expected result**: JSON list of dependency paths. Should include scripts, textures, materials, etc. referenced by the scene.

**Notes:** Dependencies are the resources that THIS resource uses (outgoing references). Not to be confused with "what references this resource" (reverse dependencies).

---

#### 10.2 — Happy path: get dependencies of a Theme resource

```
Given: A Theme resource with StyleBox, Font, and Texture sub-resources
When:  Call get_resource_dependencies
Then:  Returns all sub-resource paths
```

**Call:**
```json
{ "path": "res://assets/ui_theme.tres" }
```

**Expected result**: List of paths to StyleBox, Font, and other sub-resources embedded in or referenced by the theme.

---

#### 10.3 — Resource with no dependencies

```
Given: A simple standalone resource (e.g. a Curve with no external references)
When:  Call get_resource_dependencies
Then:  Returns empty list
```

**Call:**
```json
{ "path": "res://assets/my_curve.tres" }
```

**Expected result**: Empty list. Not an error — resources with no dependencies are valid.

---

#### 10.4 — Error: resource does not exist

```
Given: No file at "res://missing/resource.tres"
When:  Call get_resource_dependencies with path = "res://missing/resource.tres"
Then:  Returns error
```

**Call:**
```json
{ "path": "res://missing/resource.tres" }
```

**Expected result**: `isError: true`.

---

## Cross-Tool Workflows

These are sequences of tool calls that test realistic multi-step workflows. The order matters.

### Workflow A: Full Resource Lifecycle

```
1. create_resource   → Create "res://assets/test_style.tres" of type "StyleBoxFlat"
2. read_resource     → Verify it was created with default properties
3. edit_resource     → Change bg_color to "#ff0000"
4. read_resource     → Verify the property changed
5. duplicate_resource → Copy to "res://assets/test_style_copy.tres"
6. read_resource     → Verify the copy has the edited properties
7. delete_resource   → Delete the copy
8. read_resource     → Verify the copy is gone (error)
9. delete_resource   → Delete the original
```

### Workflow B: Autoload Management

```
1. create_resource   → Create a script resource (or use existing)
2. add_autoload      → Register it as "TestSingleton"
3. remove_autoload   → Remove "TestSingleton"
4. remove_autoload   → Verify it's gone (should error)
```

### Workflow C: Resource Discovery and Inspection

```
1. list_resources    → List all resources (no filter)
2. list_resources    → Filter by type "Theme"
3. get_resource_dependencies → Get deps of first result
4. read_resource     → Read the first result's properties
5. get_resource_preview → Get thumbnail of the first result
```

### Workflow D: Bulk Resource Creation and Cleanup

```
1. create_resource   → "res://assets/test_1.tres" (StyleBoxFlat)
2. create_resource   → "res://assets/test_2.tres" (Gradient)
3. create_resource   → "res://assets/test_3.tres" (Curve)
4. list_resources    → Filter by directory "res://assets/" — should include all 3
5. delete_resource   → Delete each one
6. list_resources    → Verify they're gone
```

---

## Test Execution Notes

### Prerequisites

- A running Godot 4.x editor with the MCP plugin active and connected
- A Godot project with at least one scene and one resource file
- The MCP server running and connected to the Godot editor

### Cleanup Strategy

Every test that creates resources should clean up after itself. Use `delete_resource` to remove any `.tres` files created during testing. For autoload tests, always `remove_autoload` after `add_autoload`.

### Error Response Format

All tools return errors via `callGodot` which wraps them as:
```json
{
  "content": [{ "type": "text", "text": "Godot request failed: <message>" }],
  "isError": true
}
```

When verifying error scenarios, check for `isError: true` in the response and that the `text` field contains a meaningful error description.

### Success Response Format

Successful responses are:
```json
{
  "content": [{ "type": "text", "text": "<JSON-stringified result>" }]
}
```

The `text` field contains JSON-stringified data from Godot. Parse it to verify specific values.
