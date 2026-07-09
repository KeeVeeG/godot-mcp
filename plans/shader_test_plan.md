# Shader Tools Test Plan

> **Source**: `server/src/tools/shader.ts` (10 tools)
> **Shared types**: `server/src/tools/shared-types.ts`
> **Bridge call**: `callGodot(bridge, 'shader/<action>', args)` — forwards to Godot via WebSocket, returns `ToolResult { content: [{ type: 'text', text }] }`

---

## Table of Contents

1. [create_shader](#tool-create_shader)
2. [read_shader](#tool-read_shader)
3. [edit_shader](#tool-edit_shader)
4. [assign_shader_material](#tool-assign_shader_material)
5. [unassign_material](#tool-unassign_material)
6. [set_shader_param](#tool-set_shader_param)
6. [get_shader_params](#tool-get_shader_params)
7. [list_shaders](#tool-list_shaders)
8. [validate_shader](#tool-validate_shader)
9. [delete_shader](#tool-delete_shader)

---

## Recommended Test Execution Order

Shader tools have dependencies. Execute in this order for a clean integration flow:

```
1. create_shader          — create a shader file
2. read_shader            — verify file was created
3. validate_shader        — check compilation
4. edit_shader            — modify shader code
5. validate_shader        — re-check after edit
6. list_shaders           — verify shader appears in listing
7. assign_shader_material — attach shader to a node (requires a scene + node to exist)
8. set_shader_param       — set a uniform on the material
9. get_shader_params      — read back uniforms
10. unassign_material     — remove material from a node
11. delete_shader         — cleanup
```

**Prerequisites for tools 7–10** (`assign_shader_material`, `set_shader_param`, `get_shader_params`, `unassign_material`):
- A scene must be open (use `create_scene` or `open_scene`)
- A node must exist in the scene (use `add_node` to create one, e.g. `Sprite2D`)
- A shader file must exist (use `create_shader` first)

---

## Tool: `create_shader`

**Description**: Create a new Shader resource
**Godot method**: `shader/create`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (FilePath) | **yes** | — | File path for the shader (e.g. `res://shaders/outline.gdshader`) |
| `type` | `enum` | no | `canvas_item` | Shader type: `visual`, `spatial`, `canvas_item`, `particles`, `sky`, `fog`, `texture_blit` |
| `content` | `string` | no | — | Initial shader code |

### Test Scenarios

#### Scenario 1: Create shader with minimum required params (happy path)

**Description**: Create a canvas_item shader with only `path` specified. All optional params use defaults.

**Call**:
```json
{
  "path": "res://shaders/test_basic.gdshader"
}
```

**Expected result**: Success. A shader file is created at `res://shaders/test_basic.gdshader` with type `canvas_item` (default) and empty/default content. Response should NOT contain `isError: true`.

**Notes**: This is the simplest valid call. Verify the file exists afterward via `read_shader`.

---

#### Scenario 2: Create spatial shader with initial content

**Description**: Create a 3D shader with custom shader code provided upfront.

**Call**:
```json
{
  "path": "res://shaders/test_spatial.gdshader",
  "type": "spatial",
  "content": "shader_type spatial;\nvoid fragment() {\n  ALBEDO = vec3(1.0, 0.0, 0.0);\n}"
}
```

**Expected result**: Success. File created with the exact content provided. Reading it back via `read_shader` should return the same code.

**Notes**: Verify the `type` field is respected — a `spatial` shader should have `shader_type spatial;` in Godot.

---

#### Scenario 3: Create each shader type variant

**Description**: Verify that all 7 shader type enum values are accepted.

**Call** (repeat for each type):
```json
{ "path": "res://shaders/test_visual.gdshader",      "type": "visual" }
{ "path": "res://shaders/test_spatial.gdshader",      "type": "spatial" }
{ "path": "res://shaders/test_canvas.gdshader",       "type": "canvas_item" }
{ "path": "res://shaders/test_particles.gdshader",    "type": "particles" }
{ "path": "res://shaders/test_sky.gdshader",          "type": "sky" }
{ "path": "res://shaders/test_fog.gdshader",          "type": "fog" }
{ "path": "res://shaders/test_tex_blit.gdshader",     "type": "texture_blit" }
```

**Expected result**: All 7 calls succeed. Each shader is created with the correct `shader_type` declaration.

**Notes**: If any type fails, it indicates an issue in the Godot-side handler or the enum validation.

---

#### Scenario 4: Missing required `path` parameter

**Description**: Call without the required `path` field.

**Call**:
```json
{
  "type": "spatial"
}
```

**Expected result**: Error. The MCP SDK should reject this at the schema validation level before reaching Godot. Response should contain `isError: true` with a message about missing `path`.

**Notes**: This tests Zod schema enforcement on the TypeScript side.

---

#### Scenario 5: Invalid `type` enum value

**Description**: Pass a shader type that doesn't exist in the enum.

**Call**:
```json
{
  "path": "res://shaders/test_invalid.gdshader",
  "type": "compute"
}
```

**Expected result**: Error. Zod should reject `"compute"` because it's not in the enum `['visual', 'spatial', 'canvas_item', 'particles', 'sky', 'fog', 'texture_blit']`.

**Notes**: Tests schema validation. The error should mention the invalid enum value.

---

#### Scenario 6: Empty string path

**Description**: Pass an empty string as the path.

**Call**:
```json
{
  "path": ""
}
```

**Expected result**: Error. Either schema validation rejects it (if FilePath has min length) or the Godot side fails because an empty path is invalid.

**Notes**: Boundary condition. Document the exact error message for reference.

---

#### Scenario 7: Path without `.gdshader` extension

**Description**: Provide a path without the standard shader extension.

**Call**:
```json
{
  "path": "res://shaders/test_no_ext",
  "type": "spatial"
}
```

**Expected result**: Likely succeeds on the TypeScript side (FilePath is just `z.string()`). The Godot side may or may not auto-append the extension. Document actual behavior.

**Notes**: This is an edge case to document — does the tool handle missing extensions gracefully?

---

## Tool: `read_shader`

**Description**: Read the contents of a shader file
**Godot method**: `shader/read`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (FilePath) | **yes** | — | Shader file path |

### Test Scenarios

#### Scenario 1: Read an existing shader (happy path)

**Description**: Read a shader file that was previously created.

**Prerequisites**: Run `create_shader` with `path: "res://shaders/read_test.gdshader"` and known content first.

**Call**:
```json
{
  "path": "res://shaders/read_test.gdshader"
}
```

**Expected result**: Returns the shader content as text. If content was provided during creation, it matches exactly.

**Notes**: The response text should be parseable as shader code.

---

#### Scenario 2: Read a non-existent shader

**Description**: Attempt to read a shader that doesn't exist.

**Call**:
```json
{
  "path": "res://shaders/does_not_exist.gdshader"
}
```

**Expected result**: Error. Response should have `isError: true` with a message indicating the file was not found.

**Notes**: Tests error handling on the Godot side.

---

#### Scenario 3: Missing required `path`

**Description**: Call without `path`.

**Call**:
```json
{}
```

**Expected result**: Schema validation error — `path` is required.

**Notes**: TypeScript-side validation.

---

## Tool: `edit_shader`

**Description**: Edit a shader file by replacing `old_text` with `new_text`
**Godot method**: `shader/edit`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (FilePath) | **yes** | — | Shader file path |
| `old_text` | `string` | **yes** | — | Text to find and replace |
| `new_text` | `string` | **yes** | — | Replacement text |

### Test Scenarios

#### Scenario 1: Simple text replacement (happy path)

**Description**: Replace a color value in an existing shader.

**Prerequisites**: Create a shader with content:
```glsl
shader_type canvas_item;
void fragment() {
  COLOR = vec4(1.0, 0.0, 0.0, 1.0);
}
```

**Call**:
```json
{
  "path": "res://shaders/edit_test.gdshader",
  "old_text": "vec4(1.0, 0.0, 0.0, 1.0)",
  "new_text": "vec4(0.0, 1.0, 0.0, 1.0)"
}
```

**Expected result**: Success. Reading the file back should show `vec4(0.0, 1.0, 0.0, 1.0)` where the red color was.

**Notes**: Verify the replacement was exact — no extra whitespace or line breaks introduced.

---

#### Scenario 2: Replace a multi-line block

**Description**: Replace an entire function body.

**Call**:
```json
{
  "path": "res://shaders/edit_test.gdshader",
  "old_text": "void fragment() {\n  COLOR = vec4(1.0, 0.0, 0.0, 1.0);\n}",
  "new_text": "void fragment() {\n  COLOR = vec4(0.0, 0.0, 1.0, 1.0);\n  ALPHA = 0.5;\n}"
}
```

**Expected result**: Success. The entire function is replaced with the new version including the added `ALPHA` line.

**Notes**: Multi-line replacements test whether the Godot side handles newline characters correctly.

---

#### Scenario 3: `old_text` not found in file

**Description**: Try to replace text that doesn't exist in the shader.

**Call**:
```json
{
  "path": "res://shaders/edit_test.gdshader",
  "old_text": "THIS_TEXT_DOES_NOT_EXIST_IN_THE_SHADER",
  "new_text": "replacement"
}
```

**Expected result**: Error. The Godot side should report that the text was not found.

**Notes**: Important edge case — the tool should not silently fail or corrupt the file.

---

#### Scenario 4: Missing one required parameter

**Description**: Call with only `path` and `old_text`, omitting `new_text`.

**Call**:
```json
{
  "path": "res://shaders/edit_test.gdshader",
  "old_text": "vec4"
}
```

**Expected result**: Schema validation error — `new_text` is required.

---

#### Scenario 5: Empty `old_text`

**Description**: Replace empty string (should this insert at the beginning?).

**Call**:
```json
{
  "path": "res://shaders/edit_test.gdshader",
  "old_text": "",
  "new_text": "// header comment\n"
}
```

**Expected result**: Depends on implementation. Either:
- Error (empty search string is invalid)
- Inserts `new_text` at the beginning of the file

**Notes**: Edge case to document actual behavior.

---

## Tool: `assign_shader_material`

**Description**: Create a ShaderMaterial and assign it to a node's material property
**Godot method**: `shader/assign_material`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `string` (NodePath) | **yes** | — | Node path to assign the material to |
| `shader_path` | `string` (FilePath) | **yes** | — | Shader resource path |

### Test Scenarios

#### Scenario 1: Assign shader to Sprite2D (happy path)

**Description**: Assign a shader to an existing Sprite2D node.

**Prerequisites** (execute in order):
1. `create_scene` → `{ "path": "res://scenes/shader_test.tscn", "root_node_type": "Node2D" }`
2. `add_node` → `{ "parent_path": "", "type": "Sprite2D", "name": "TestSprite" }`
3. `create_shader` → `{ "path": "res://shaders/material_test.gdshader", "content": "shader_type canvas_item;\nvoid fragment() { COLOR = vec4(1.0); }" }`

**Call**:
```json
{
  "node_path": "TestSprite",
  "shader_path": "res://shaders/material_test.gdshader"
}
```

**Expected result**: Success. The `TestSprite` node now has a `ShaderMaterial` assigned to its `material` property, referencing `res://shaders/material_test.gdshader`.

**Notes**: After this call, `get_shader_params` on the same node should work. Verify with `get_node_properties` (from node tools) that `material` is set.

---

#### Scenario 2: Assign shader to non-existent node

**Description**: Try to assign a shader to a node that doesn't exist.

**Call**:
```json
{
  "node_path": "NonExistentNode",
  "shader_path": "res://shaders/material_test.gdshader"
}
```

**Expected result**: Error. The Godot side should report that the node was not found.

**Notes**: Tests error handling for invalid node paths.

---

#### Scenario 3: Assign non-existent shader

**Description**: Try to assign a shader file that doesn't exist.

**Call**:
```json
{
  "node_path": "TestSprite",
  "shader_path": "res://shaders/does_not_exist.gdshader"
}
```

**Expected result**: Error. The Godot side should report that the shader resource was not found.

---

#### Scenario 4: Missing required `node_path`

**Call**:
```json
{
  "shader_path": "res://shaders/material_test.gdshader"
}
```

**Expected result**: Schema validation error.

---

#### Scenario 5: Missing required `shader_path`

**Call**:
```json
{
  "node_path": "TestSprite"
}
```

**Expected result**: Schema validation error.

---

## Tool: `unassign_material`

**Description**: Remove a shader material from a node (set material/material_override to null)
**Godot method**: `shader/unassign_material`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `string` (NodePath) | **yes** | — | Node path to remove the material from |

### Test Scenarios

#### Scenario 1: Remove shader material from Sprite2D (happy path)

**Description**: Remove a previously assigned shader from a Sprite2D node.

**Prerequisites** (execute in order):
1. `create_scene` → `{ "path": "res://scenes/unassign_test.tscn", "root_node_type": "Node2D" }`
2. `add_node` → `{ "parent_path": "", "type": "Sprite2D", "name": "TestSprite" }`
3. `create_shader` → `{ "path": "res://shaders/unassign_test.gdshader", "content": "shader_type canvas_item;\nvoid fragment() { COLOR = vec4(1.0); }" }`
4. `assign_shader_material` → `{ "node_path": "TestSprite", "shader_path": "res://shaders/unassign_test.gdshader" }`

**Call**:
```json
{
  "node_path": "TestSprite"
}
```

**Expected result**: Success. The `TestSprite` node's `material` property is now `null`. Verify via `get_node_properties` that `material` is unset.

**Notes**: After this call, `get_shader_params` on the same node should fail with "Node does not have a ShaderMaterial".

---

#### Scenario 2: Remove shader material from MeshInstance3D (3D variant)

**Description**: Remove a material_override from a 3D node.

**Prerequisites**:
1. Create a 3D scene with a MeshInstance3D node
2. Assign a shader via `assign_shader_material`

**Call**:
```json
{
  "node_path": "TestMesh"
}
```

**Expected result**: Success. The `material_override` property on the MeshInstance3D is set to `null`.

---

#### Scenario 3: Remove material from node without material

**Description**: Try to remove a material from a node that has no material assigned.

**Prerequisites**: Create a Sprite2D node without assigning any shader.

**Call**:
```json
{
  "node_path": "PlainSprite"
}
```

**Expected result**: Success (no-op). Setting `null` on an already-null property should succeed without error. The node simply has no material before and after the call.

**Notes**: Document whether this returns success or an error. The implementation sets to `null` unconditionally, so it should succeed.

---

#### Scenario 4: Remove material from non-existent node

**Call**:
```json
{
  "node_path": "NonExistentNode"
}
```

**Expected result**: Error — node not found.

---

#### Scenario 5: Missing required `node_path`

**Call**:
```json
{}
```

**Expected result**: Error — `node_path` is required.

---

#### Scenario 6: Remove material from node type that doesn't support materials

**Description**: Try to remove a material from a plain Node (not CanvasItem or Node3D).

**Call**:
```json
{
  "node_path": "PlainNode"
}
```

**Expected result**: Error — "Node does not support materials: Node".

---

## Tool: `set_shader_param`

**Description**: Set a shader parameter (uniform) on a ShaderMaterial
**Godot method**: `shader/set_param`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `string` (NodePath) | **yes** | — | Node path with the ShaderMaterial |
| `param` | `string` | **yes** | — | Shader uniform name |
| `value` | `unknown` (PropertyValue) | **yes** | — | Parameter value |

### Test Scenarios

#### Scenario 1: Set a float uniform (happy path)

**Description**: Set a `float` uniform on a shader that declares one.

**Prerequisites**: Shader with content:
```glsl
shader_type canvas_item;
uniform float brightness = 1.0;
void fragment() {
  COLOR = vec4(brightness, brightness, brightness, 1.0);
}
```
Assign this shader to a node via `assign_shader_material`.

**Call**:
```json
{
  "node_path": "TestSprite",
  "param": "brightness",
  "value": 0.75
}
```

**Expected result**: Success. The uniform `brightness` is set to `0.75` on the node's ShaderMaterial.

**Notes**: Verify via `get_shader_params` that the value persisted.

---

#### Scenario 2: Set a vec4 uniform (color)

**Description**: Set a `vec4` uniform representing a color.

**Shader uniform declaration**:
```glsl
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
```

**Call**:
```json
{
  "node_path": "TestSprite",
  "param": "tint_color",
  "value": [1.0, 0.0, 0.0, 1.0]
}
```

**Expected result**: Success. Color uniform set to red.

**Notes**: PropertyValue is `z.unknown()`, so arrays should be accepted. The Godot side must parse the array as a `Color` or `Vector4`.

---

#### Scenario 3: Set a sampler2D uniform (texture)

**Description**: Set a texture uniform.

**Shader uniform declaration**:
```glsl
uniform sampler2D main_texture;
```

**Call**:
```json
{
  "node_path": "TestSprite",
  "param": "main_texture",
  "value": "res://icon.svg"
}
```

**Expected result**: Success if the Godot side resolves the path to a texture resource. May fail if the handler expects a loaded resource reference rather than a path string.

**Notes**: This is an edge case for the `PropertyValue` type — texture parameters may need special handling. Document actual behavior.

---

#### Scenario 4: Set parameter on node without ShaderMaterial

**Description**: Try to set a shader param on a node that has no ShaderMaterial assigned.

**Prerequisites**: Create a node (e.g. `Sprite2D`) without assigning a shader.

**Call**:
```json
{
  "node_path": "PlainSprite",
  "param": "brightness",
  "value": 0.5
}
```

**Expected result**: Error. The Godot side should report that the node doesn't have a ShaderMaterial.

---

#### Scenario 5: Set non-existent uniform name

**Description**: Try to set a uniform that doesn't exist in the shader.

**Call**:
```json
{
  "node_path": "TestSprite",
  "param": "nonexistent_uniform_xyz",
  "value": 1.0
}
```

**Expected result**: Either:
- Error (uniform not found in shader)
- Silent no-op (Godot may accept it without error)

**Notes**: Document actual behavior. Godot's `ShaderMaterial.set_shader_parameter()` may silently accept unknown parameter names.

---

#### Scenario 6: Missing required parameters

**Call** (missing `value`):
```json
{
  "node_path": "TestSprite",
  "param": "brightness"
}
```

**Expected result**: Schema validation error — `value` is required.

---

## Tool: `get_shader_params`

**Description**: Get all shader parameters (uniforms) and their current values
**Godot method**: `shader/get_params`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `string` (NodePath) | **yes** | — | Node path with the ShaderMaterial |

### Test Scenarios

#### Scenario 1: Get params from node with shader (happy path)

**Description**: Read all uniforms from a node that has a ShaderMaterial with multiple uniforms set.

**Prerequisites**:
1. Create shader with uniforms: `brightness` (float, default 1.0), `tint_color` (vec4, default white)
2. Assign to a node
3. Set `brightness` to `0.75` and `tint_color` to red via `set_shader_param`

**Call**:
```json
{
  "node_path": "TestSprite"
}
```

**Expected result**: A JSON object or text listing all uniforms with their current values:
```json
{
  "brightness": 0.75,
  "tint_color": [1.0, 0.0, 0.0, 1.0]
}
```

**Notes**: Verify that the values match what was set via `set_shader_param`. Default values that were never explicitly set may or may not appear.

---

#### Scenario 2: Get params from node without ShaderMaterial

**Call**:
```json
{
  "node_path": "PlainSprite"
}
```

**Expected result**: Error — node has no ShaderMaterial.

---

#### Scenario 3: Get params from non-existent node

**Call**:
```json
{
  "node_path": "NonExistentNode"
}
```

**Expected result**: Error — node not found.

---

#### Scenario 4: Missing required `node_path`

**Call**:
```json
{}
```

**Expected result**: Schema validation error.

---

## Tool: `list_shaders`

**Description**: List all shader files in the project
**Godot method**: `shader/list`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `filter` | `string` (SearchQuery) | no | — | Filter by path pattern |

### Test Scenarios

#### Scenario 1: List all shaders (happy path, no filter)

**Description**: List every shader in the project without filtering.

**Prerequisites**: At least one shader file exists (e.g. from prior `create_shader` calls).

**Call**:
```json
{}
```

**Expected result**: A list of shader file paths, e.g.:
```json
[
  "res://shaders/test_basic.gdshader",
  "res://shaders/test_spatial.gdshader",
  "res://shaders/material_test.gdshader"
]
```

**Notes**: If no shaders exist, the result should be an empty list, not an error.

---

#### Scenario 2: List shaders with filter

**Description**: Filter shaders by a path pattern.

**Call**:
```json
{
  "filter": "res://shaders/test_*"
}
```

**Expected result**: Only shaders matching the pattern are returned. If `test_basic.gdshader`, `test_spatial.gdshader`, and `material_test.gdshader` exist, only the first two should match.

**Notes**: The exact glob/regex behavior depends on the Godot-side implementation. Document whether it supports wildcards, regex, or simple substring matching.

---

#### Scenario 3: Filter with no matches

**Call**:
```json
{
  "filter": "res://nonexistent_folder/*"
}
```

**Expected result**: Empty list, not an error.

---

#### Scenario 4: Empty filter string

**Call**:
```json
{
  "filter": ""
}
```

**Expected result**: Same as no filter — returns all shaders. Document if empty string behaves differently.

---

## Tool: `validate_shader`

**Description**: Validate a shader file for compilation errors
**Godot method**: `shader/validate`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (FilePath) | **yes** | — | Shader file path |

### Test Scenarios

#### Scenario 1: Validate a correct shader (happy path)

**Description**: Validate a shader with valid syntax.

**Prerequisites**: Create a shader with valid content:
```glsl
shader_type canvas_item;
void fragment() {
  COLOR = vec4(1.0, 1.0, 1.0, 1.0);
}
```

**Call**:
```json
{
  "path": "res://shaders/valid_shader.gdshader"
}
```

**Expected result**: Success with no errors. Response indicates the shader compiles cleanly.

**Notes**: Check what the exact success response format is — does it return `true`, `null`, an object with `valid: true`, or a text message?

---

#### Scenario 2: Validate a shader with syntax errors

**Description**: Validate a shader that has deliberate syntax errors.

**Prerequisites**: Create a shader with invalid content:
```glsl
shader_type canvas_item;
void fragment() {
  COLOR = vec4(1.0, 0.0, 0.0);  // ERROR: vec4 needs 4 components
  UNDECLARED_VAR = 1.0;           // ERROR: undeclared identifier
}
```

**Call**:
```json
{
  "path": "res://shaders/invalid_shader.gdshader"
}
```

**Expected result**: Error response with compilation error details. Should include line numbers and error descriptions.

**Notes**: The quality of error reporting is important — does it report all errors or stop at the first one?

---

#### Scenario 3: Validate a non-existent shader

**Call**:
```json
{
  "path": "res://shaders/ghost_shader.gdshader"
}
```

**Expected result**: Error — file not found.

---

#### Scenario 4: Missing required `path`

**Call**:
```json
{}
```

**Expected result**: Schema validation error.

---

## Tool: `delete_shader`

**Description**: Delete a shader file from the project
**Godot method**: `shader/delete`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` | **yes** | — | Shader file path to delete |
| `force` | `boolean` | no | `false` | Delete even if shader is referenced by nodes |

### Test Scenarios

#### Scenario 1: Delete an unreferenced shader (happy path)

**Description**: Delete a shader that is not used by any node.

**Prerequisites**: Create a shader that is NOT assigned to any node.

**Call**:
```json
{
  "path": "res://shaders/disposable.gdshader"
}
```

**Expected result**: Success. File is deleted. Subsequent `read_shader` on the same path should fail.

**Notes**: Verify with `list_shaders` that the file no longer appears.

---

#### Scenario 2: Delete a referenced shader without `force`

**Description**: Try to delete a shader that IS currently assigned to a node's ShaderMaterial.

**Prerequisites**:
1. Create shader at `res://shaders/in_use.gdshader`
2. Assign it to a node via `assign_shader_material`

**Call**:
```json
{
  "path": "res://shaders/in_use.gdshader"
}
```

**Expected result**: Error or warning. The tool should refuse to delete a shader that is in use, since `force` defaults to `false`.

**Notes**: This tests the safety mechanism. The exact error message should be documented.

---

#### Scenario 3: Force-delete a referenced shader

**Description**: Delete a shader that is in use, but with `force: true`.

**Call**:
```json
{
  "path": "res://shaders/in_use.gdshader",
  "force": true
}
```

**Expected result**: Success. The shader is deleted even though it's referenced. The node's ShaderMaterial may now reference a missing shader.

**Notes**: After this, the node's material state is undefined. Verify what happens when `get_shader_params` is called on the node afterward.

---

#### Scenario 4: Delete a non-existent shader

**Call**:
```json
{
  "path": "res://shaders/never_existed.gdshader"
}
```

**Expected result**: Error — file not found.

---

#### Scenario 5: Missing required `path`

**Call**:
```json
{
  "force": true
}
```

**Expected result**: Schema validation error — `path` is required.

---

## Full Integration Test Sequence

Execute all 10 tools in sequence to validate the complete shader workflow:

### Setup Phase

```
Step 1: create_scene
  { "path": "res://scenes/shader_integration_test.tscn", "root_node_type": "Node2D" }

Step 2: add_node
  { "parent_path": "", "type": "Sprite2D", "name": "ShaderSprite" }
```

### Shader CRUD Phase

```
Step 3: create_shader
  {
    "path": "res://shaders/integration_test.gdshader",
    "type": "canvas_item",
    "content": "shader_type canvas_item;\nuniform float brightness = 1.0;\nuniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);\nvoid fragment() {\n  COLOR = tint_color * brightness;\n}"
  }

Step 4: read_shader
  { "path": "res://shaders/integration_test.gdshader" }
  → Verify content matches Step 3

Step 5: validate_shader
  { "path": "res://shaders/integration_test.gdshader" }
  → Expect: valid, no errors

Step 6: edit_shader
  {
    "path": "res://shaders/integration_test.gdshader",
    "old_text": "uniform float brightness = 1.0;",
    "new_text": "uniform float brightness = 0.5;\nuniform float alpha_override = 1.0;"
  }

Step 7: validate_shader
  { "path": "res://shaders/integration_test.gdshader" }
  → Expect: still valid after edit

Step 8: read_shader
  { "path": "res://shaders/integration_test.gdshader" }
  → Verify edited content with new uniforms
```

### Material Assignment Phase

```
Step 9: assign_shader_material
  { "node_path": "ShaderSprite", "shader_path": "res://shaders/integration_test.gdshader" }

Step 10: set_shader_param
  { "node_path": "ShaderSprite", "param": "brightness", "value": 0.8 }

Step 11: set_shader_param
  { "node_path": "ShaderSprite", "param": "tint_color", "value": [0.2, 0.5, 1.0, 1.0] }

Step 12: set_shader_param
  { "node_path": "ShaderSprite", "param": "alpha_override", "value": 0.75 }

Step 13: get_shader_params
  { "node_path": "ShaderSprite" }
  → Verify: brightness=0.8, tint_color=[0.2,0.5,1.0,1.0], alpha_override=0.75

Step 14: unassign_material
  { "node_path": "ShaderSprite" }
  → Verify: material is now null on ShaderSprite

Step 15: assign_shader_material (re-assign for delete test)
  { "node_path": "ShaderSprite", "shader_path": "res://shaders/integration_test.gdshader" }
```

### Listing Phase

```
Step 16: list_shaders
  {}
  → Verify: "res://shaders/integration_test.gdshader" appears in the list

Step 17: list_shaders
  { "filter": "res://shaders/integration*" }
  → Verify: only integration test shader appears
```

### Cleanup Phase

```
Step 18: delete_shader
  { "path": "res://shaders/integration_test.gdshader", "force": true }
  → Should succeed (force=true even though node references it)

Step 19: list_shaders
  {}
  → Verify: "res://shaders/integration_test.gdshader" no longer appears

Step 20: delete_scene
  { "path": "res://scenes/shader_integration_test.tscn", "force": true }
```

---

## Error Response Format

All tools use `callGodot()` which wraps errors as:
```json
{
  "content": [{ "type": "text", "text": "Godot request failed: <error message>" }],
  "isError": true
}
```

Schema validation errors (TypeScript side) are handled by the MCP SDK and follow the SDK's error format.

---

## Notes for Test Implementers

1. **Isolation**: Each test scenario should ideally use unique file/node names to avoid conflicts when tests run in parallel or out of order.
2. **Cleanup**: Always delete created shaders and scenes after tests. Use `force: true` for cleanup to avoid "referenced by nodes" errors.
3. **Godot state**: These tests require a running Godot editor with the MCP plugin active and connected. The bridge must be established before any test executes.
4. **Scene context**: Tools that operate on `node_path` (assign_shader_material, set_shader_param, get_shader_params) require a scene to be open and the node to exist. Node paths are relative to the currently open scene.
5. **PropertyValue flexibility**: `set_shader_param` accepts `z.unknown()` for `value`. Test with various Godot types: `float`, `int`, `bool`, `Vector2`, `Vector3`, `Color` (as array), `string` (for texture paths).
