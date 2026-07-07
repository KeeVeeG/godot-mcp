# Shader Tools — Test Plan

**Source file:** `server/src/tools/shader.ts`
**Shared types:** `server/src/tools/shared-types.ts`
**Number of tools:** 9
**Generated:** 2026-07-08

---

## Type Reference

| Zod schema | Underlying type | Description |
|---|---|---|
| `FilePath` | `z.string()` | Generic file path, e.g. `'res://path/to/file'` |
| `NodePath` | `z.string()` | Node path in scene tree, e.g. `'Player/Sprite2D'`, `''` for root |
| `PropertyValue` | `z.unknown()` | Any property value (number, string, boolean, array, object) |
| `SearchQuery` | `z.string()` | Search/filter query string |

---

## Tool: `create_shader`

**Description:** Create a new Shader resource
**Handler:** `callGodot(bridge, 'shader/create', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `FilePath` (string) | **Yes** | — | File path for the shader (e.g. `'res://shaders/outline.gdshader'`) |
| `type` | enum string | No | `'canvas_item'` | Shader type: `visual`, `spatial`, `canvas_item`, `particles`, `sky`, `fog`, `texture_blit` |
| `content` | string | No | — | Initial shader code |

### Test Scenarios

#### Scenario 1: Happy path — minimum required params
- **Description:** Create a canvas_item shader with only required `path`
- **Params:** `{ "path": "res://shaders/test_minimal.gdshader" }`
- **Expected result:** Success. Shader created at `res://shaders/test_minimal.gdshader` with type `canvas_item` (default).

#### Scenario 2: type = `canvas_item` (explicit)
- **Description:** Create a shader explicitly specifying type `canvas_item`
- **Params:** `{ "path": "res://shaders/test_canvas.gdshader", "type": "canvas_item" }`
- **Expected result:** Success. Shader created with type `canvas_item`.

#### Scenario 3: type = `visual`
- **Description:** Create a visual shader
- **Params:** `{ "path": "res://shaders/test_visual.gdshader", "type": "visual" }`
- **Expected result:** Success. Shader created with type `visual`.
- **Notes:** `visual` is an alias for `canvas_item` (2D shader).

#### Scenario 4: type = `spatial`
- **Description:** Create a spatial (3D) shader
- **Params:** `{ "path": "res://shaders/test_spatial.gdshader", "type": "spatial" }`
- **Expected result:** Success. Shader created with type `spatial`.

#### Scenario 5: type = `particles`
- **Description:** Create a particles shader
- **Params:** `{ "path": "res://shaders/test_particles.gdshader", "type": "particles" }`
- **Expected result:** Success. Shader created with type `particles`.

#### Scenario 6: type = `sky`
- **Description:** Create a sky shader
- **Params:** `{ "path": "res://shaders/test_sky.gdshader", "type": "sky" }`
- **Expected result:** Success. Shader created with type `sky`.

#### Scenario 7: type = `fog`
- **Description:** Create a fog shader
- **Params:** `{ "path": "res://shaders/test_fog.gdshader", "type": "fog" }`
- **Expected result:** Success. Shader created with type `fog`.

#### Scenario 8: type = `texture_blit`
- **Description:** Create a texture_blit shader
- **Params:** `{ "path": "res://shaders/test_blit.gdshader", "type": "texture_blit" }`
- **Expected result:** Success. Shader created with type `texture_blit`.

#### Scenario 9: With initial content
- **Description:** Create a shader with initial shader code content
- **Params:** `{ "path": "res://shaders/test_content.gdshader", "type": "canvas_item", "content": "shader_type canvas_item;\n\nvoid fragment() {\n    COLOR = vec4(1.0, 0.0, 0.0, 1.0);\n}" }`
- **Expected result:** Success. Shader created with the provided source code.

#### Scenario 10: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{ "type": "canvas_item" }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 11: Edge — invalid type value
- **Description:** Call with an unsupported type string
- **Params:** `{ "path": "res://shaders/test_bad.gdshader", "type": "invalid_type" }`
- **Expected result:** Zod validation error (type must be one of the enum values).

#### Scenario 12: Edge — empty path string
- **Description:** Call with an empty path
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot (invalid path).

#### Scenario 13: Edge — path without .gdshader extension
- **Description:** Call with a path lacking the .gdshader extension
- **Params:** `{ "path": "res://shaders/test_no_ext" }`
- **Expected result:** May succeed or fail depending on Godot behavior. If it fails, Godot returns an error about invalid extension.

#### Scenario 14: Edge — overwrite existing shader
- **Description:** Create a shader at a path that already exists
- **Params:** `{ "path": "res://shaders/existing.gdshader" }`
- **Expected result:** Behavior depends on Godot implementation — may overwrite or return an error.
- **Notes:** Ensure `existing.gdshader` exists before running.

---

## Tool: `read_shader`

**Description:** Read the contents of a shader file
**Handler:** `callGodot(bridge, 'shader/read', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `FilePath` (string) | **Yes** | — | Shader file path |

### Test Scenarios

#### Scenario 1: Happy path — read existing shader
- **Description:** Read the contents of an existing shader file
- **Params:** `{ "path": "res://shaders/test_canvas.gdshader" }`
- **Expected result:** Success. Returns the full text content of the shader file.
- **Notes:** Requires a shader created by `create_shader` first.

#### Scenario 2: Edge — non-existent path
- **Description:** Read a shader file that does not exist
- **Params:** `{ "path": "res://shaders/nonexistent.gdshader" }`
- **Expected result:** Error from Godot (file not found).

#### Scenario 3: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 4: Edge — path is a directory, not a file
- **Description:** Pass a directory path instead of a file path
- **Params:** `{ "path": "res://shaders" }`
- **Expected result:** Error from Godot (not a valid shader file).

#### Scenario 5: Edge — path to a non-shader file
- **Description:** Read a file that is not a shader (e.g., a .gd script)
- **Params:** `{ "path": "res://scripts/some_script.gd" }`
- **Expected result:** May still return file contents (the tool reads any file text), depending on implementation. Test to verify behavior.

#### Scenario 6: Edge — shader with special characters / Unicode
- **Description:** Read a shader file whose path contains spaces or Unicode characters
- **Params:** `{ "path": "res://shaders/my shader.gdshader" }`
- **Expected result:** Should succeed if the file exists; verify path handling works.

---

## Tool: `edit_shader`

**Description:** Edit a shader file by replacing old_text with new_text
**Handler:** `callGodot(bridge, 'shader/edit', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `FilePath` (string) | **Yes** | — | Shader file path |
| `old_text` | string | **Yes** | — | Text to find and replace |
| `new_text` | string | **Yes** | — | Replacement text |

### Test Scenarios

#### Scenario 1: Happy path — simple text replacement
- **Description:** Replace a line in an existing shader
- **Params:** `{ "path": "res://shaders/test_canvas.gdshader", "old_text": "shader_type canvas_item;", "new_text": "shader_type canvas_item;\n// Edited by test" }`
- **Expected result:** Success. The shader file is updated with the replacement.

#### Scenario 2: Happy path — replace shader content
- **Description:** Replace uniform declaration in a shader
- **Params:** `{ "path": "res://shaders/test_content.gdshader", "old_text": "COLOR = vec4(1.0, 0.0, 0.0, 1.0);", "new_text": "COLOR = vec4(0.0, 1.0, 0.0, 1.0);" }`
- **Expected result:** Success. The COLOR line is changed from red to green.

#### Scenario 3: Edge — old_text not found
- **Description:** Call with old_text that does not exist in the file
- **Params:** `{ "path": "res://shaders/test_canvas.gdshader", "old_text": "THIS_TEXT_DOES_NOT_EXIST_XYZ", "new_text": "replacement" }`
- **Expected result:** Error from Godot (text not found in file).

#### Scenario 4: Edge — file not found
- **Description:** Edit a non-existent shader
- **Params:** `{ "path": "res://shaders/nonexistent.gdshader", "old_text": "foo", "new_text": "bar" }`
- **Expected result:** Error from Godot (file not found).

#### Scenario 5: Edge — empty old_text
- **Description:** Call with empty old_text string
- **Params:** `{ "path": "res://shaders/test_canvas.gdshader", "old_text": "", "new_text": "something" }`
- **Expected result:** May match at start of file or behave unexpectedly. Test to confirm behavior.

#### Scenario 6: Edge — empty new_text (delete text)
- **Description:** Replace text with empty string (effectively deletion)
- **Params:** `{ "path": "res://shaders/test_canvas.gdshader", "old_text": "// Edited by test", "new_text": "" }`
- **Expected result:** Success. The matched text is removed from the file.

#### Scenario 7: Edge — missing required param
- **Description:** Call without `old_text`
- **Params:** `{ "path": "res://shaders/test_canvas.gdshader", "new_text": "foo" }`
- **Expected result:** Zod validation error (old_text is required).

#### Scenario 8: Edge — missing required param
- **Description:** Call without `path`
- **Params:** `{ "old_text": "foo", "new_text": "bar" }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 9: Edge — multi-line old_text
- **Description:** Replace a multi-line block in a shader
- **Params:** `{ "path": "res://shaders/test_content.gdshader", "old_text": "shader_type canvas_item;\n\nvoid fragment() {\n    COLOR = vec4(1.0, 0.0, 0.0, 1.0);\n}", "new_text": "shader_type canvas_item;\n\nvoid fragment() {\n    COLOR = vec4(0.0, 0.0, 1.0, 1.0);\n}" }`
- **Expected result:** Success. The entire shader body is replaced.

---

## Tool: `assign_shader_material`

**Description:** Create a ShaderMaterial and assign it to a node's material property
**Handler:** `callGodot(bridge, 'shader/assign_material', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `node_path` | `NodePath` (string) | **Yes** | — | Node path to assign the material to |
| `shader_path` | `FilePath` (string) | **Yes** | — | Shader resource path |

### Test Scenarios

#### Scenario 1: Happy path — assign to a MeshInstance3D
- **Description:** Assign a spatial shader material to a 3D mesh node
- **Params:** `{ "node_path": "MeshInstance3D", "shader_path": "res://shaders/test_spatial.gdshader" }`
- **Expected result:** Success. A ShaderMaterial using the shader is created and assigned to the node's `material_override` or `material` property.

#### Scenario 2: Happy path — assign to a Sprite2D
- **Description:** Assign a canvas_item shader material to a Sprite2D node
- **Params:** `{ "node_path": "Sprite2D", "shader_path": "res://shaders/test_canvas.gdshader" }`
- **Expected result:** Success. A ShaderMaterial is assigned to the Sprite2D's material.

#### Scenario 3: Happy path — assign to scene root (empty string)
- **Description:** Assign to the scene root node using empty string
- **Params:** `{ "node_path": "", "shader_path": "res://shaders/test_canvas.gdshader" }`
- **Expected result:** Success. A ShaderMaterial is assigned to the scene root node.
- **Notes:** Verify the root node type supports a material property.

#### Scenario 4: Edge — node_path does not exist
- **Description:** Assign to a non-existent node
- **Params:** `{ "node_path": "NonExistentNode", "shader_path": "res://shaders/test_canvas.gdshader" }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 5: Edge — shader_path does not exist
- **Description:** Assign using a non-existent shader file
- **Params:** `{ "node_path": "Sprite2D", "shader_path": "res://shaders/nonexistent.gdshader" }`
- **Expected result:** Error from Godot (shader resource not found).

#### Scenario 6: Edge — missing required params
- **Description:** Call without `node_path`
- **Params:** `{ "shader_path": "res://shaders/test_canvas.gdshader" }`
- **Expected result:** Zod validation error (node_path is required).

#### Scenario 7: Edge — missing required params
- **Description:** Call without `shader_path`
- **Params:** `{ "node_path": "Sprite2D" }`
- **Expected result:** Zod validation error (shader_path is required).

#### Scenario 8: Edge — assign to a node that does not support materials
- **Description:** Assign a ShaderMaterial to a node type that has no material property
- **Params:** `{ "node_path": "Node3D", "shader_path": "res://shaders/test_spatial.gdshader" }`
- **Expected result:** May succeed or fail depending on Godot behavior. If the node doesn't have a material property, Godot should return an error.

#### Scenario 9: Edge — node is a nested path
- **Description:** Assign to a deeply nested node using full path
- **Params:** `{ "node_path": "Parent/Child/Sprite2D", "shader_path": "res://shaders/test_canvas.gdshader" }`
- **Expected result:** Success if the node exists at that path; error otherwise.

#### Scenario 10: Edge — reassign to a node that already has a material
- **Description:** Call assign_shader_material on a node that already has a ShaderMaterial
- **Params:** `{ "node_path": "Sprite2D", "shader_path": "res://shaders/test_visual.gdshader" }`
- **Expected result:** New ShaderMaterial replaces the existing one.

---

## Tool: `set_shader_param`

**Description:** Set a shader parameter (uniform) on a ShaderMaterial
**Handler:** `callGodot(bridge, 'shader/set_param', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `node_path` | `NodePath` (string) | **Yes** | — | Node path with the ShaderMaterial |
| `param` | string | **Yes** | — | Shader uniform name |
| `value` | `PropertyValue` (unknown) | **Yes** | — | Parameter value |

### Test Scenarios

#### Scenario 1: Happy path — set a float uniform
- **Description:** Set a float shader parameter on a node with a ShaderMaterial
- **Params:** `{ "node_path": "Sprite2D", "param": "brightness", "value": 1.5 }`
- **Expected result:** Success. The `brightness` uniform on the ShaderMaterial is set to `1.5`.
- **Notes:** Requires a shader with a `uniform float brightness;` declared.

#### Scenario 2: Happy path — set a vec4/color uniform
- **Description:** Set a color uniform using an array
- **Params:** `{ "node_path": "Sprite2D", "param": "tint", "value": [1.0, 0.0, 0.0, 1.0] }`
- **Expected result:** Success. The `tint` uniform is set to red.
- **Notes:** Requires a shader with `uniform vec4 tint;`.

#### Scenario 3: Happy path — set a boolean uniform
- **Description:** Set a boolean uniform
- **Params:** `{ "node_path": "Sprite2D", "param": "flip_x", "value": true }`
- **Expected result:** Success. The `flip_x` uniform is set to `true`.

#### Scenario 4: Happy path — set a string uniform
- **Description:** Set a string (sampler2D path) parameter
- **Params:** `{ "node_path": "Sprite2D", "param": "custom_texture", "value": "res://assets/icon.png" }`
- **Expected result:** Success (or error if uniform type mismatch).

#### Scenario 5: Edge — param does not exist on shader
- **Description:** Set a uniform name that doesn't exist in the shader
- **Params:** `{ "node_path": "Sprite2D", "param": "nonexistent_uniform", "value": 1.0 }`
- **Expected result:** Error or warning from Godot (uniform not found).

#### Scenario 6: Edge — node has no ShaderMaterial
- **Description:** Call on a node that doesn't have a ShaderMaterial assigned
- **Params:** `{ "node_path": "NodeWithoutMaterial", "param": "brightness", "value": 1.0 }`
- **Expected result:** Error from Godot (no ShaderMaterial found on node).

#### Scenario 7: Edge — missing required params
- **Description:** Call without `param`
- **Params:** `{ "node_path": "Sprite2D", "value": 1.0 }`
- **Expected result:** Zod validation error (param is required).

#### Scenario 8: Edge — missing required params
- **Description:** Call without `value`
- **Params:** `{ "node_path": "Sprite2D", "param": "brightness" }`
- **Expected result:** Zod validation error (value is required).

#### Scenario 9: Edge — value type mismatch
- **Description:** Set a float uniform to a string value
- **Params:** `{ "node_path": "Sprite2D", "param": "brightness", "value": "not_a_number" }`
- **Expected result:** Behavior depends on Godot — may coerce or return an error.

#### Scenario 10: Edge — set value to null
- **Description:** Set a uniform to null
- **Params:** `{ "node_path": "Sprite2D", "param": "brightness", "value": null }`
- **Expected result:** Since `PropertyValue` is `z.unknown()`, null passes validation. Godot may reset the parameter to default or error.

---

## Tool: `get_shader_params`

**Description:** Get all shader parameters (uniforms) and their current values
**Handler:** `callGodot(bridge, 'shader/get_params', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `node_path` | `NodePath` (string) | **Yes** | — | Node path with the ShaderMaterial |

### Test Scenarios

#### Scenario 1: Happy path — get params from a node with ShaderMaterial
- **Description:** Retrieve all shader uniforms and their values from a node
- **Params:** `{ "node_path": "Sprite2D" }`
- **Expected result:** Success. Returns an object listing each uniform name and its current value.
- **Notes:** Requires a node with a ShaderMaterial assigned.

#### Scenario 2: Edge — node has no ShaderMaterial
- **Description:** Call on a node without a ShaderMaterial
- **Params:** `{ "node_path": "NodeWithoutMaterial" }`
- **Expected result:** Error from Godot (no ShaderMaterial found on node).

#### Scenario 3: Edge — node does not exist
- **Description:** Call with a non-existent node path
- **Params:** `{ "node_path": "NonExistentNode" }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 4: Edge — missing required param
- **Description:** Call without `node_path`
- **Params:** `{}`
- **Expected result:** Zod validation error (node_path is required).

#### Scenario 5: Edge — empty node_path
- **Description:** Call with empty string as node_path
- **Params:** `{ "node_path": "" }`
- **Expected result:** Returns params from the scene root node's ShaderMaterial (if any), or error if root has no material.

#### Scenario 6: Scenario — verify return includes all uniform types
- **Description:** Create a shader with multiple uniform types (float, vec4, texture, bool), assign it, then call get_shader_params
- **Params:** `{ "node_path": "Sprite2D" }`
- **Expected result:** Success. Returned object contains all declared uniforms with their current values and types.
- **Notes:** This is an integration test. Create the shader first with all uniform types.

---

## Tool: `list_shaders`

**Description:** List all shader files in the project
**Handler:** `callGodot(bridge, 'shader/list', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `filter` | `SearchQuery` (string) | No | — | Filter by path pattern |

### Test Scenarios

#### Scenario 1: Happy path — list all shaders (no filter)
- **Description:** List all shader files in the project
- **Params:** `{}`
- **Expected result:** Success. Returns an array of all `.gdshader` files in the project.

#### Scenario 2: Happy path — with filter
- **Description:** List shaders matching a path pattern
- **Params:** `{ "filter": "test" }`
- **Expected result:** Success. Returns only shaders whose path contains "test".

#### Scenario 3: Happy path — filter by directory
- **Description:** List shaders in a specific directory
- **Params:** `{ "filter": "res://shaders/" }`
- **Expected result:** Success. Returns shaders only within that directory.

#### Scenario 4: Edge — filter matches nothing
- **Description:** Use a filter that matches no shaders
- **Params:** `{ "filter": "zzz_nonexistent_pattern_xyz" }`
- **Expected result:** Success. Returns an empty array (not an error).

#### Scenario 5: Edge — empty filter string
- **Description:** Pass empty string as filter
- **Params:** `{ "filter": "" }`
- **Expected result:** Should behave like no filter (returns all shaders), or match nothing. Test to verify.

---

## Tool: `validate_shader`

**Description:** Validate a shader file for compilation errors
**Handler:** `callGodot(bridge, 'shader/validate', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `FilePath` (string) | **Yes** | — | Shader file path |

### Test Scenarios

#### Scenario 1: Happy path — validate a valid shader
- **Description:** Validate a syntactically correct shader
- **Params:** `{ "path": "res://shaders/test_canvas.gdshader" }`
- **Expected result:** Success. Returns validation result with no errors.

#### Scenario 2: Happy path — validate a shader with errors
- **Description:** Validate a shader that has syntax errors
- **Params:** `{ "path": "res://shaders/test_broken.gdshader" }`
- **Expected result:** Success (tool returns result). The result should list compilation errors with line numbers.
- **Notes:** Create a shader with intentional syntax errors first (e.g., missing semicolon, undeclared variable).

#### Scenario 3: Edge — file not found
- **Description:** Validate a non-existent shader
- **Params:** `{ "path": "res://shaders/nonexistent.gdshader" }`
- **Expected result:** Error from Godot (file not found).

#### Scenario 4: Edge — missing required param
- **Description:** Call without `path`
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 5: Edge — validate a non-shader file
- **Description:** Validate a file that is not a shader (e.g., a GDScript)
- **Params:** `{ "path": "res://scripts/some_script.gd" }`
- **Expected result:** Error from Godot (not a shader file type).

#### Scenario 6: Edge — validate a spatial shader intended for canvas
- **Description:** Validate a shader with type mismatch (spatial shader opened as canvas_item)
- **Params:** `{ "path": "res://shaders/test_spatial.gdshader" }`
- **Expected result:** Depends on content. If the shader uses spatial-only features (e.g., `VERTEX`, `NORMAL`), it should still validate since those are valid for spatial shaders. Test confirms shader_type header is honored.

---

## Tool: `delete_shader`

**Description:** Delete a shader file from the project
**Handler:** `callGodot(bridge, 'shader/delete', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | string | **Yes** | — | Shader file path to delete (e.g. `res://shaders/my_shader.gdshader`) |
| `force` | boolean | No | `false` | Delete even if shader is referenced by nodes |

### Test Scenarios

#### Scenario 1: Happy path — delete unreferenced shader
- **Description:** Delete a shader that is not referenced by any node
- **Params:** `{ "path": "res://shaders/test_minimal.gdshader" }`
- **Expected result:** Success. The shader file is deleted from the project.

#### Scenario 2: Happy path — force delete referenced shader
- **Description:** Force-delete a shader that is being used by nodes
- **Params:** `{ "path": "res://shaders/test_canvas.gdshader", "force": true }`
- **Expected result:** Success. Shader deleted despite references. Nodes referencing it may show errors.

#### Scenario 3: Edge — delete referenced shader without force
- **Description:** Attempt to delete a shader referenced by nodes without force flag
- **Params:** `{ "path": "res://shaders/test_canvas.gdshader", "force": false }`
- **Expected result:** Error or warning from Godot about the shader being in use.
- **Notes:** Ensure a node references this shader before testing.

#### Scenario 4: Edge — file not found
- **Description:** Delete a non-existent shader
- **Params:** `{ "path": "res://shaders/nonexistent.gdshader" }`
- **Expected result:** Error from Godot (file not found).

#### Scenario 5: Edge — missing required param
- **Description:** Call without `path`
- **Params:** `{ "force": true }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 6: Edge — empty path
- **Description:** Call with empty string path
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot (invalid path).

#### Scenario 7: Edge — path is directory
- **Description:** Attempt to delete a directory path
- **Params:** `{ "path": "res://shaders" }`
- **Expected result:** Error from Godot (path is not a file).

---

## Integration Test Scenarios

These scenarios chain multiple shader tools together to verify end-to-end workflows.

### Integration 1: Create → Read → Edit → Read → Validate workflow
1. `create_shader` with `path: "res://shaders/integration_test.gdshader"`, `type: "canvas_item"`, `content: "shader_type canvas_item;\n\nuniform float alpha = 1.0;\n\nvoid fragment() {\n    COLOR = vec4(1.0, 1.0, 1.0, alpha);\n}"`
2. `read_shader` — verify content matches
3. `edit_shader` — change `alpha = 1.0` to `alpha = 0.5`
4. `read_shader` — verify the edit was applied
5. `validate_shader` — confirm no compilation errors
- **Expected result:** All steps succeed. Shader is created, read back, modified, and validates cleanly.

### Integration 2: Create → Assign → Set Param → Get Params → Delete workflow
1. `create_shader` with `path: "res://shaders/material_test.gdshader"`, `type: "spatial"`, `content: "shader_type spatial;\n\nuniform float roughness = 0.5;\nuniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);\n\nvoid fragment() {\n    ALBEDO = albedo.rgb;\n    ROUGHNESS = roughness;\n}"`
2. `assign_shader_material` to a MeshInstance3D node
3. `set_shader_param` — set `roughness` to `0.2`
4. `set_shader_param` — set `albedo` to `[0.2, 0.5, 0.8, 1.0]`
5. `get_shader_params` — verify both uniforms reflect set values
6. `delete_shader` with `force: true` (since it's referenced)
- **Expected result:** Full round-trip succeeds. Params are set and read back correctly.

### Integration 3: List → Validate All workflow
1. `list_shaders` — get all shaders
2. For each shader in the list, call `validate_shader`
- **Expected result:** Each shader is validated. Valid shaders return no errors; broken ones return error details.

---

## Summary

| Tool | Params | Required | Optional | Enum Values |
|---|---|---|---|---|
| `create_shader` | 3 | `path` | `type`, `content` | `type`: visual, spatial, canvas_item, particles, sky, fog, texture_blit |
| `read_shader` | 1 | `path` | — | — |
| `edit_shader` | 3 | `path`, `old_text`, `new_text` | — | — |
| `assign_shader_material` | 2 | `node_path`, `shader_path` | — | — |
| `set_shader_param` | 3 | `node_path`, `param`, `value` | — | — |
| `get_shader_params` | 1 | `node_path` | — | — |
| `list_shaders` | 1 | — | `filter` | — |
| `validate_shader` | 1 | `path` | — | — |
| `delete_shader` | 2 | `path` | `force` | — |

**Total scenarios:** 60+ covering all 9 tools with happy paths, all enum values, edge cases, and integration workflows.
