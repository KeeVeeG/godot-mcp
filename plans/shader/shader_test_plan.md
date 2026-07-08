# Shader Tools Test Plan

**Source file:** `server/src/tools/shader.ts`
**Godot bridge method prefix:** `shader/`
**Shared schemas used:** `NodePath`, `FilePath`, `PropertyValue`, `SearchQuery` (from `shared-types.ts`)
**Handler pattern:** All tools call `callGodot(bridge, 'shader/<action>', args)`

---

## Shared Type Definitions

| Schema | Type | Constraints |
|--------|------|-------------|
| `NodePath` | `string` | Node path in the scene tree, e.g. `"Player/Sprite2D"`, `""` for scene root |
| `FilePath` | `string` | File path, e.g. `"res://shaders/outline.gdshader"` |
| `PropertyValue` | `z.unknown()` | Any property value — string, number, boolean, array, object |
| `SearchQuery` | `string` | Search query string for filtering |

---

## Tool: `create_shader`

**Handler:** `callGodot(bridge, 'shader/create', args)`
**Description:** Create a new Shader resource

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `FilePath` (string) | **Yes** | — | File path for the shader, e.g. `"res://shaders/outline.gdshader"` |
| `type` | `enum` | No | `"canvas_item"` | Shader type: `"visual"` / `"canvas_item"` (2D), `"spatial"` (3D), `"particles"`, `"sky"`, `"fog"`, `"texture_blit"` |
| `content` | `string` | No | — | Initial shader code |

### Test Scenarios

#### Scenario 1: Happy path — create canvas_item shader (minimum params)
- **Description:** Create a shader file with only the required `path` parameter, relying on the default `type` (`"canvas_item"`)
- **Params:** `{ "path": "res://shaders/test_default.gdshader" }`
- **Expected result:** Success response. A shader file is created at `res://shaders/test_default.gdshader` with type `canvas_item` and a default template body.
- **Notes:** Verify via `read_shader` that the file exists and contains valid shader code. Validate via `get_filesystem_tree` that the file appears.

#### Scenario 2: Create shader with explicit `type` — `canvas_item`
- **Description:** Create a shader with type explicitly set to `"canvas_item"`
- **Params:** `{ "path": "res://shaders/test_canvas.gdshader", "type": "canvas_item" }`
- **Expected result:** Success response. Shader created as canvas_item type.
- **Notes:** The `"canvas_item"` and `"visual"` enum values map to the same Godot shader type.

#### Scenario 3: Create shader with `type` = `"spatial"`
- **Description:** Create a 3D spatial shader
- **Params:** `{ "path": "res://shaders/test_spatial.gdshader", "type": "spatial" }`
- **Expected result:** Success response. Shader created as spatial type (for 3D rendering).
- **Notes:** Verify the shader type is `spatial`, not `canvas_item`.

#### Scenario 4: Create shader with `type` = `"visual"`
- **Description:** Create a shader with type `"visual"` (alias for `canvas_item`)
- **Params:** `{ "path": "res://shaders/test_visual.gdshader", "type": "visual" }`
- **Expected result:** Success response. Shader created. Behavior should match `canvas_item`.
- **Notes:** `"visual"` is a valid enum value. Confirm the Godot-side handler maps it correctly.

#### Scenario 5: Create shader with `type` = `"particles"`
- **Description:** Create a particle shader
- **Params:** `{ "path": "res://shaders/test_particles.gdshader", "type": "particles" }`
- **Expected result:** Success response. Shader created as particles type.
- **Notes:** Particle shaders are used with GPUParticles materials.

#### Scenario 6: Create shader with `type` = `"sky"`
- **Description:** Create a sky shader
- **Params:** `{ "path": "res://shaders/test_sky.gdshader", "type": "sky" }`
- **Expected result:** Success response. Shader created as sky type.
- **Notes:** Sky shaders are used for rendering the sky background.

#### Scenario 7: Create shader with `type` = `"fog"`
- **Description:** Create a fog shader
- **Params:** `{ "path": "res://shaders/test_fog.gdshader", "type": "fog" }`
- **Expected result:** Success response. Shader created as fog type.
- **Notes:** Fog shaders are used for volumetric fog rendering.

#### Scenario 8: Create shader with `type` = `"texture_blit"`
- **Description:** Create a texture_blit shader
- **Params:** `{ "path": "res://shaders/test_blit.gdshader", "type": "texture_blit" }`
- **Expected result:** Success response. Shader created as texture_blit type.
- **Notes:** Texture blit shaders are used for fullscreen texture pass rendering.

#### Scenario 9: Create shader with initial `content`
- **Description:** Create a shader with custom initial code content
- **Params:** `{ "path": "res://shaders/test_with_content.gdshader", "content": "shader_type canvas_item;\n\nvoid fragment() {\n    COLOR = vec4(1.0, 0.0, 0.0, 1.0);\n}" }`
- **Expected result:** Success response. The shader file is created with the specified code content.
- **Notes:** Verify via `read_shader` that the file content matches exactly.

#### Scenario 10: Create shader with `type` and `content` together
- **Description:** Create a spatial shader with initial code
- **Params:** `{ "path": "res://shaders/test_spatial_content.gdshader", "type": "spatial", "content": "shader_type spatial;\n\nvoid fragment() {\n    ALBEDO = vec3(0.0, 0.0, 1.0);\n}" }`
- **Expected result:** Success response. Spatial shader created with the provided code.
- **Notes:** Tests combination of optional params.

#### Scenario 11: Missing required param — omit `path`
- **Description:** Call without the `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error from the MCP server. The call should not reach the Godot bridge.
- **Notes:** Tests that `path` is properly marked as required.

#### Scenario 12: Empty string `path`
- **Description:** Provide an empty string for `path`
- **Params:** `{ "path": "" }`
- **Expected result:** Error response from Godot — the path is invalid.
- **Notes:** An empty path cannot be a valid shader file path.

#### Scenario 13: Invalid path — missing `.gdshader` extension
- **Description:** Provide a path without the proper shader file extension
- **Params:** `{ "path": "res://shaders/test_noext" }`
- **Expected result:** Error response from Godot or the file is created with the wrong extension. Behavior depends on the Godot-side handler.
- **Notes:** Godot expects `.gdshader` extension. Test how the handler deals with this.

#### Scenario 14: Invalid `type` enum value
- **Description:** Provide a value not in the shader type enum
- **Params:** `{ "path": "res://shaders/test_badtype.gdshader", "type": "invalid" }`
- **Expected result:** Zod validation error — `type` must be one of `"visual"`, `"spatial"`, `"canvas_item"`, `"particles"`, `"sky"`, `"fog"`, `"texture_blit"`.
- **Notes:** Tests enum constraint enforcement.

#### Scenario 15: Create shader in a nested directory
- **Description:** Create a shader in a subdirectory that exists
- **Params:** `{ "path": "res://shaders/subfolder/test_nested.gdshader", "type": "canvas_item" }`
- **Expected result:** Success response if `res://shaders/subfolder/` exists, or error if it doesn't.
- **Notes:** The Godot handler may or may not auto-create intermediate directories.

#### Scenario 16: Create shader with very long `content`
- **Description:** Create a shader with a large code body
- **Params:** `{ "path": "res://shaders/test_long.gdshader", "content": "<500+ lines of valid shader code>" }`
- **Expected result:** Success response. The full content is stored in the file.
- **Notes:** Tests that large content strings are handled correctly.

#### Scenario 17: Overwrite existing shader
- **Description:** Call `create_shader` with a path that already exists
- **Params:** `{ "path": "res://shaders/test_default.gdshader" }` (after Scenario 1 has already created it)
- **Expected result:** Behavior depends on the Godot handler — may overwrite silently, error, or prompt. Test to document actual behavior.
- **Notes:** Run this after Scenario 1.

---

## Tool: `read_shader`

**Handler:** `callGodot(bridge, 'shader/read', args)`
**Description:** Read the contents of a shader file

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `FilePath` (string) | **Yes** | — | Shader file path |

### Test Scenarios

#### Scenario 1: Happy path — read an existing shader file
- **Description:** Read a shader file that was previously created
- **Params:** `{ "path": "res://shaders/test_with_content.gdshader" }`
- **Expected result:** Success response containing the full text content of the shader file.
- **Notes:** Prerequisite: run `create_shader` Scenario 9 first. The returned content should include `"shader_type canvas_item;"` and the custom fragment code.

#### Scenario 2: Read a shader with only default content
- **Description:** Read a shader created with no explicit content
- **Params:** `{ "path": "res://shaders/test_default.gdshader" }`
- **Expected result:** Success response containing the default template shader code (expected to start with `shader_type canvas_item;`).
- **Notes:** Prerequisite: run `create_shader` Scenario 1 first.

#### Scenario 3: Read a spatial shader
- **Description:** Read a shader of type `spatial`
- **Params:** `{ "path": "res://shaders/test_spatial.gdshader" }`
- **Expected result:** Success response. Content should start with `shader_type spatial;`.
- **Notes:** Prerequisite: run `create_shader` Scenario 3 first.

#### Scenario 4: Missing required param — omit `path`
- **Description:** Call without the `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error from the MCP server.
- **Notes:** Tests that `path` is properly marked as required.

#### Scenario 5: Read a non-existent shader file
- **Description:** Attempt to read a shader that does not exist
- **Params:** `{ "path": "res://shaders/nonexistent.gdshader" }`
- **Expected result:** Error response from Godot indicating the file was not found.
- **Notes:** Tests error handling for missing files.

#### Scenario 6: Read a non-shader file
- **Description:** Attempt to read a non-shader file (e.g., a GDScript file)
- **Params:** `{ "path": "res://scripts/some_script.gd" }`
- **Expected result:** Behavior depends on the Godot handler. May return an error or return the raw file content anyway.
- **Notes:** Tests whether the handler restricts reading to `.gdshader` files only.

#### Scenario 7: Empty string `path`
- **Description:** Provide an empty string for the path
- **Params:** `{ "path": "" }`
- **Expected result:** Error response — empty path is invalid.
- **Notes:** Tests basic input validation.

---

## Tool: `edit_shader`

**Handler:** `callGodot(bridge, 'shader/edit', args)`
**Description:** Edit a shader file by replacing `old_text` with `new_text`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `FilePath` (string) | **Yes** | — | Shader file path |
| `old_text` | `string` | **Yes** | — | Text to find and replace |
| `new_text` | `string` | **Yes** | — | Replacement text |

### Test Scenarios

#### Scenario 1: Happy path — replace a simple string
- **Description:** Replace a single occurrence of text in a shader file
- **Params:** `{ "path": "res://shaders/test_with_content.gdshader", "old_text": "COLOR = vec4(1.0, 0.0, 0.0, 1.0)", "new_text": "COLOR = vec4(0.0, 1.0, 0.0, 1.0)" }`
- **Expected result:** Success response. The shader file is updated with the replacement. Read back the file to verify the change.
- **Notes:** Prerequisite: shader at `test_with_content.gdshader` exists with the expected content. Verify final content via `read_shader`.

#### Scenario 2: Replace all occurrences (if supported) — same text appears twice
- **Description:** Replace text that appears multiple times (e.g., `vec4` in a multi-line shader)
- **Params:** `{ "path": "res://shaders/test_with_content.gdshader", "old_text": "COLOR", "new_text": "OUTPUT_COLOR" }`
- **Expected result:** Success. Behavior depends on Godot handler — may replace first occurrence only or all occurrences. Document observed behavior.
- **Notes:** Important to understand whether this is a single-replace or replace-all operation.

#### Scenario 3: Replace with empty string (delete text)
- **Description:** Replace a substring with an empty string to remove it
- **Params:** `{ "path": "res://shaders/test_with_content.gdshader", "old_text": "void fragment() {\n    ", "new_text": "" }`
- **Expected result:** Success response. The matched text is removed from the file.
- **Notes:** If multi-line matching is supported, the newline and whitespace are removed.

#### Scenario 4: Replace with multi-line `new_text`
- **Description:** Replace a short string with a multi-line block of shader code
- **Params:** `{ "path": "res://shaders/test_with_content.gdshader", "old_text": "void fragment()", "new_text": "void fragment() {\n    // Custom logic inserted via edit\n    float intensity = 1.5;" }`
- **Expected result:** Success response. The file is updated with new multi-line content.
- **Notes:** Tests that newlines in `new_text` are handled correctly.

#### Scenario 5: `old_text` not found in file
- **Description:** Attempt to replace text that does not exist in the shader
- **Params:** `{ "path": "res://shaders/test_with_content.gdshader", "old_text": "NONEXISTENT_TEXT_XYZ", "new_text": "something" }`
- **Expected result:** Error response from Godot indicating the text was not found.
- **Notes:** Tests error handling for no-match case.

#### Scenario 6: Missing required param — omit `old_text`
- **Description:** Call without the `old_text` parameter
- **Params:** `{ "path": "res://shaders/test_default.gdshader", "new_text": "COLOR = vec4(0.0, 0.0, 1.0, 1.0)" }`
- **Expected result:** Zod validation error from the MCP server.
- **Notes:** Tests that `old_text` is properly marked as required.

#### Scenario 7: Missing required param — omit `new_text`
- **Description:** Call without the `new_text` parameter
- **Params:** `{ "path": "res://shaders/test_default.gdshader", "old_text": "shader_type canvas_item" }`
- **Expected result:** Zod validation error from the MCP server.
- **Notes:** Tests that `new_text` is properly marked as required.

#### Scenario 8: Missing required param — omit `path`
- **Description:** Call without the `path` parameter
- **Params:** `{ "old_text": "foo", "new_text": "bar" }`
- **Expected result:** Zod validation error from the MCP server.
- **Notes:** Tests that `path` is properly marked as required.

#### Scenario 9: Edit a non-existent shader file
- **Description:** Attempt to edit a shader that does not exist
- **Params:** `{ "path": "res://shaders/nonexistent.gdshader", "old_text": "shader_type", "new_text": "shader_type spatial" }`
- **Expected result:** Error response from Godot indicating the file was not found.
- **Notes:** Tests error handling for missing files.

#### Scenario 10: Replace with `old_text` = entire file content
- **Description:** Replace the entire shader code at once
- **Params:** `{ "path": "res://shaders/test_default.gdshader", "old_text": "shader_type canvas_item;\n\nvoid fragment() {\n\t// Place your shader code here.\n}", "new_text": "shader_type canvas_item;\n\nvoid fragment() {\n\tCOLOR = vec4(1.0);\n}" }`
- **Expected result:** Success response. The entire file content is replaced.
- **Notes:** Prerequisite: know the exact default template content generated by Godot for canvas_item shaders.

#### Scenario 11: Multiple consecutive edits
- **Description:** Apply two sequential edits to the same shader
- **Params (edit 1):** `{ "path": "res://shaders/test_spatial.gdshader", "old_text": "shader_type spatial", "new_text": "shader_type spatial;\n\nrender_mode unshaded" }`
- **Params (edit 2):** `{ "path": "res://shaders/test_spatial.gdshader", "old_text": "void fragment()", "new_text": "void fragment() {\n\tALBEDO = vec3(1.0, 0.0, 0.0)" }`
- **Expected result:** Both edits succeed. The file reflects the cumulative changes.
- **Notes:** Tests that editing is idempotent and sequential edits accumulate correctly.

---

## Tool: `assign_shader_material`

**Handler:** `callGodot(bridge, 'shader/assign_material', args)`
**Description:** Create a ShaderMaterial and assign it to a node's material property

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `NodePath` (string) | **Yes** | — | Node path to assign the material to |
| `shader_path` | `FilePath` (string) | **Yes** | — | Shader resource path |

### Test Scenarios

#### Scenario 1: Happy path — assign shader material to a MeshInstance3D
- **Description:** Assign a spatial shader as a ShaderMaterial to a 3D mesh node
- **Params:** `{ "node_path": "Cube", "shader_path": "res://shaders/test_spatial.gdshader" }`
- **Expected result:** Success response. A ShaderMaterial is created from the shader and assigned to the node's material slot (index 0). The node should render with the shader.
- **Notes:** Prerequisites: A MeshInstance3D node named `Cube` exists in the scene, and the shader at `shaders/test_spatial.gdshader` exists. Verify via `get_node_properties` that `material_override` or `surface_material_override/0` is set.

#### Scenario 2: Assign shader material to a 2D node (Sprite2D)
- **Description:** Assign a canvas_item shader to a Sprite2D node
- **Params:** `{ "node_path": "Sprite2D", "shader_path": "res://shaders/test_canvas.gdshader" }`
- **Expected result:** Success response. A ShaderMaterial is created and assigned to the Sprite2D's material property.
- **Notes:** Prerequisites: A Sprite2D node exists, and the shader exists. Canvas_item shaders should be assigned to 2D nodes.

#### Scenario 3: Assign shader to a node with nested path
- **Description:** Assign a shader to a node located deep in the scene hierarchy
- **Params:** `{ "node_path": "Player/Model/Armor", "shader_path": "res://shaders/test_spatial.gdshader" }`
- **Expected result:** Success response if the node path exists. The ShaderMaterial is assigned to `Player/Model/Armor`.
- **Notes:** Prerequisites: The nested node path must exist and be a valid material-bearing node (e.g., MeshInstance3D, Sprite2D).

#### Scenario 4: Assign same shader to multiple nodes
- **Description:** Assign the same shader material to two different nodes (call twice)
- **Params (call 1):** `{ "node_path": "Cube", "shader_path": "res://shaders/test_spatial.gdshader" }`
- **Params (call 2):** `{ "node_path": "Sphere", "shader_path": "res://shaders/test_spatial.gdshader" }`
- **Expected result:** Both calls succeed. Each node gets a ShaderMaterial instance (may share or be unique instances — document observed behavior).
- **Notes:** Prerequisites: Both `Cube` and `Sphere` nodes exist.

#### Scenario 5: Missing required param — omit `node_path`
- **Description:** Call without the `node_path` parameter
- **Params:** `{ "shader_path": "res://shaders/test_canvas.gdshader" }`
- **Expected result:** Zod validation error from the MCP server.
- **Notes:** Tests that `node_path` is properly marked as required.

#### Scenario 6: Missing required param — omit `shader_path`
- **Description:** Call without the `shader_path` parameter
- **Params:** `{ "node_path": "Cube" }`
- **Expected result:** Zod validation error from the MCP server.
- **Notes:** Tests that `shader_path` is properly marked as required.

#### Scenario 7: Non-existent node path
- **Description:** Attempt to assign a shader to a node that does not exist
- **Params:** `{ "node_path": "NonExistentNodeXYZ", "shader_path": "res://shaders/test_canvas.gdshader" }`
- **Expected result:** Error response from Godot indicating the node was not found.
- **Notes:** Tests error handling for missing nodes.

#### Scenario 8: Non-existent shader file path
- **Description:** Attempt to assign a shader that does not exist
- **Params:** `{ "node_path": "Cube", "shader_path": "res://shaders/nonexistent.gdshader" }`
- **Expected result:** Error response from Godot indicating the shader resource was not found.
- **Notes:** Tests error handling for missing shader files.

#### Scenario 9: Assign shader to a node that does not support materials
- **Description:** Assign a shader to a non-rendering node (e.g., a plain Node or Node2D without sprite)
- **Params:** `{ "node_path": "SomePlainNode", "shader_path": "res://shaders/test_canvas.gdshader" }`
- **Expected result:** Error response from Godot — the node has no material property.
- **Notes:** Tests that the handler validates node type compatibility or passes through the Godot error.

#### Scenario 10: Assign to scene root
- **Description:** Assign a shader material to the scene root node
- **Params:** `{ "node_path": "", "shader_path": "res://shaders/test_canvas.gdshader" }`
- **Expected result:** Depends on the root node type. If root is a Control (UI), it may fail. If root is Node2D with a sprite child, the root itself may not have a material.
- **Notes:** Tests edge case of empty string NodePath.

#### Scenario 11: Re-assign shader to a node that already has one
- **Description:** Assign a new shader to a node that already has a ShaderMaterial from a previous `assign_shader_material` call, to test overwrite behavior
- **Params:** `{ "node_path": "Cube", "shader_path": "res://shaders/test_default.gdshader" }` (after Scenario 1 already set it to `test_spatial.gdshader`)
- **Expected result:** Success response. The node's material is replaced with the new shader.
- **Notes:** Tests that the tool can overwrite an existing material assignment.

---

## Tool: `set_shader_param`

**Handler:** `callGodot(bridge, 'shader/set_param', args)`
**Description:** Set a shader parameter (uniform) on a ShaderMaterial

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `NodePath` (string) | **Yes** | — | Node path with the ShaderMaterial |
| `param` | `string` | **Yes** | — | Shader uniform name |
| `value` | `PropertyValue` (unknown) | **Yes** | — | Parameter value |

### Test Scenarios

#### Scenario 1: Happy path — set a float uniform
- **Description:** Set a float-type uniform parameter on a shader material
- **Params:** `{ "node_path": "Cube", "param": "intensity", "value": 0.75 }`
- **Expected result:** Success response. The shader parameter `intensity` on the node's ShaderMaterial is set to `0.75`.
- **Notes:** Prerequisites: A node `Cube` has a ShaderMaterial assigned (from `assign_shader_material`) and the shader has a `uniform float intensity` declaration.

#### Scenario 2: Set a vec3/color uniform
- **Description:** Set a color/vec3 uniform parameter
- **Params:** `{ "node_path": "Cube", "param": "tint_color", "value": [1.0, 0.0, 0.0] }`
- **Expected result:** Success response. The parameter `tint_color` is set to the color red.
- **Notes:** Tests array-type value for vec3/color uniforms.

#### Scenario 3: Set a boolean uniform
- **Description:** Set a boolean uniform parameter
- **Params:** `{ "node_path": "Cube", "param": "use_effect", "value": true }`
- **Expected result:** Success response. The boolean uniform is set to `true`.
- **Notes:** Tests boolean value type.

#### Scenario 4: Set an integer uniform
- **Description:** Set an int uniform parameter
- **Params:** `{ "node_path": "Cube", "param": "iteration_count", "value": 5 }`
- **Expected result:** Success response. The integer uniform is set to `5`.
- **Notes:** Tests integer value type.

#### Scenario 5: Set a sampler2D/texture uniform (via resource path)
- **Description:** Set a texture uniform by passing a resource path
- **Params:** `{ "node_path": "Cube", "param": "albedo_texture", "value": "res://textures/checker.png" }`
- **Expected result:** Success response if the handler supports resolving resource paths to textures. The texture uniform is set.
- **Notes:** Behavior depends on the Godot handler — may accept paths or require pre-loaded resource references.

#### Scenario 6: Multiple params on the same node
- **Description:** Set two different uniforms sequentially on the same ShaderMaterial
- **Params (call 1):** `{ "node_path": "Cube", "param": "intensity", "value": 0.5 }`
- **Params (call 2):** `{ "node_path": "Cube", "param": "tint_color", "value": [0.0, 0.0, 1.0] }`
- **Expected result:** Both calls succeed. Both uniforms are set independently.
- **Notes:** Tests that setting one param does not reset others. Verify via `get_shader_params`.

#### Scenario 7: Missing required param — omit `param`
- **Description:** Call without the `param` parameter
- **Params:** `{ "node_path": "Cube", "value": 1.0 }`
- **Expected result:** Zod validation error from the MCP server.
- **Notes:** Tests that `param` is properly marked as required.

#### Scenario 8: Missing required param — omit `value`
- **Description:** Call without the `value` parameter
- **Params:** `{ "node_path": "Cube", "param": "intensity" }`
- **Expected result:** Zod validation error from the MCP server.
- **Notes:** Tests that `value` is properly marked as required.

#### Scenario 9: Non-existent uniform name
- **Description:** Attempt to set a uniform that does not exist in the shader
- **Params:** `{ "node_path": "Cube", "param": "nonexistent_uniform_xyz", "value": 1.0 }`
- **Expected result:** Error response from Godot — the uniform does not exist in the shader.
- **Notes:** Tests error handling for missing uniforms.

#### Scenario 10: Non-existent node path
- **Description:** Attempt to set a param on a node that does not exist
- **Params:** `{ "node_path": "GhostNode", "param": "intensity", "value": 0.5 }`
- **Expected result:** Error response from Godot indicating the node was not found.
- **Notes:** Tests error handling for missing nodes.

#### Scenario 11: Node exists but has no ShaderMaterial
- **Description:** Attempt to set a shader param on a node that has no ShaderMaterial assigned
- **Params:** `{ "node_path": "EmptyNode", "param": "intensity", "value": 1.0 }`
- **Expected result:** Error response from Godot — the node has no ShaderMaterial to set a parameter on.
- **Notes:** Prerequisite: Create a node without a ShaderMaterial. Tests that the handler validates the presence of a ShaderMaterial.

#### Scenario 12: Set param with string value
- **Description:** Set a uniform using a string value
- **Params:** `{ "node_path": "Cube", "param": "label", "value": "hello" }`
- **Expected result:** Depends on the uniform type. If `label` is a string uniform, it succeeds. If it is numeric, Godot errors.
- **Notes:** Tests type coercion or rejection by the Godot handler.

---

## Tool: `get_shader_params`

**Handler:** `callGodot(bridge, 'shader/get_params', args)`
**Description:** Get all shader parameters (uniforms) and their current values

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `NodePath` (string) | **Yes** | — | Node path with the ShaderMaterial |

### Test Scenarios

#### Scenario 1: Happy path — get params from a node with ShaderMaterial
- **Description:** Retrieve all shader parameters from a node that has a ShaderMaterial assigned
- **Params:** `{ "node_path": "Cube" }`
- **Expected result:** Success response containing a list/map of all shader uniform names and their current values. Should include `"intensity": 0.5` and `"tint_color": [0.0, 0.0, 1.0]` if previously set.
- **Notes:** Prerequisites: Run `assign_shader_material` and `set_shader_param` first. Verify the returned values match what was set.

#### Scenario 2: Get params from a node with no ShaderMaterial
- **Description:** Attempt to get shader params from a node without a ShaderMaterial
- **Params:** `{ "node_path": "EmptyNode" }`
- **Expected result:** Error response from Godot or an empty result — no ShaderMaterial found.
- **Notes:** Tests edge case handling.

#### Scenario 3: Get params from node with a freshly-assigned material (no custom params set)
- **Description:** Get shader params from a node where only `assign_shader_material` was called, with no further `set_shader_param` calls
- **Params:** `{ "node_path": "Sprite2D" }`
- **Expected result:** Success response listing all uniforms with their default values (as defined in the shader).
- **Notes:** Prerequisites: Assign a shader to `Sprite2D` without any subsequent `set_shader_param` calls.

#### Scenario 4: Missing required param — omit `node_path`
- **Description:** Call without the `node_path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error from the MCP server.
- **Notes:** Tests that `node_path` is properly marked as required.

#### Scenario 5: Non-existent node path
- **Description:** Attempt to get shader params from a non-existent node
- **Params:** `{ "node_path": "GhostNode999" }`
- **Expected result:** Error response from Godot indicating the node was not found.
- **Notes:** Tests error handling for missing nodes.

#### Scenario 6: Scene root with ShaderMaterial
- **Description:** Get shader params from the scene root node (if it supports materials)
- **Params:** `{ "node_path": "" }`
- **Expected result:** If the root node has a ShaderMaterial, returns the params. Otherwise, error or empty result.
- **Notes:** Tests empty string NodePath edge case.

---

## Tool: `list_shaders`

**Handler:** `callGodot(bridge, 'shader/list', args)`
**Description:** List all shader files in the project

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `filter` | `SearchQuery` (string) | No | — | Filter by path pattern |

### Test Scenarios

#### Scenario 1: Happy path — list all shaders (no filter)
- **Description:** List all shader files in the project without any filter
- **Params:** `{}`
- **Expected result:** Success response containing a list of all shader file paths in the project. Should include all shaders created in previous test scenarios (e.g., `res://shaders/test_default.gdshader`, `res://shaders/test_spatial.gdshader`, etc.).
- **Notes:** Run after the `create_shader` scenarios so there are shaders to list.

#### Scenario 2: List shaders with a path filter
- **Description:** List shaders filtering by a path pattern
- **Params:** `{ "filter": "test_" }`
- **Expected result:** Success response containing only shaders whose paths contain `"test_"` (e.g., `res://shaders/test_default.gdshader`).
- **Notes:** Tests the filter parameter. The exact behavior of the filter (substring match, glob, regex) depends on the Godot handler — document observed behavior.

#### Scenario 3: List shaders with filter that matches none
- **Description:** List shaders with a filter that no shader file matches
- **Params:** `{ "filter": "nonexistent_pattern_xyz" }`
- **Expected result:** Success response with an empty list or indicating no shaders matched.
- **Notes:** Tests filter behavior with no matches.

#### Scenario 4: List shaders with an empty string filter
- **Description:** List shaders with an empty string for the filter
- **Params:** `{ "filter": "" }`
- **Expected result:** Should behave the same as Scenario 1 (no filter) — returns all shaders, OR returns nothing (empty filter matches nothing). Document observed behavior.
- **Notes:** Tests edge case of empty filter string.

#### Scenario 5: List shaders in a project with zero shader files
- **Description:** List shaders in a fresh project with no `.gdshader` files
- **Params:** `{}`
- **Expected result:** Success response with an empty list.
- **Notes:** Tests behavior in a clean project. May need a separate project for this test.

#### Scenario 6: List shaders with special characters in filter
- **Description:** Use a filter with regex-special characters
- **Params:** `{ "filter": ".*" }`
- **Expected result:** Depends on whether the filter is treated as literal or regex. Document behavior. If regex, should match all shaders. If literal, may match none.
- **Notes:** Tests how the filter parameter handles special characters.

---

## Tool: `validate_shader`

**Handler:** `callGodot(bridge, 'shader/validate', args)`
**Description:** Validate a shader file for compilation errors

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `FilePath` (string) | **Yes** | — | Shader file path |

### Test Scenarios

#### Scenario 1: Happy path — validate a correct shader
- **Description:** Validate a shader file with valid syntax
- **Params:** `{ "path": "res://shaders/test_default.gdshader" }`
- **Expected result:** Success response indicating the shader compiled without errors. May report warnings if any.
- **Notes:** Prerequisites: A valid shader file exists. Success means no compilation errors.

#### Scenario 2: Validate a shader with deliberate syntax errors
- **Description:** Validate a shader file that contains invalid GLSL syntax
- **Params:** `{ "path": "res://shaders/test_broken.gdshader" }`
- **Expected result:** Error response or a validation result containing compilation errors with line numbers and error messages.
- **Notes:** Prerequisite: Create a shader file with broken code, e.g., `"shader_type canvas_item;\n\nvoid fragment() {\n    COLOR = invalid;\n}"`.

#### Scenario 3: Validate a spatial shader with valid syntax
- **Description:** Validate a spatial shader with correct 3D shader code
- **Params:** `{ "path": "res://shaders/test_spatial.gdshader" }`
- **Expected result:** Success response — no compilation errors.
- **Notes:** Prerequisites: `test_spatial.gdshader` has valid spatial shader code.

#### Scenario 4: Validate a shader with type mismatch (spatial code in canvas_item)
- **Description:** Validate a file declared as `canvas_item` but containing spatial-specific uniforms/functions
- **Params:** `{ "path": "res://shaders/test_type_mismatch.gdshader" }`
- **Expected result:** Error response with compilation errors indicating type mismatch.
- **Notes:** Prerequisite: Create a file with `shader_type canvas_item;` but using spatial-only built-ins like `ALBEDO`.

#### Scenario 5: Missing required param — omit `path`
- **Description:** Call without the `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error from the MCP server.
- **Notes:** Tests that `path` is properly marked as required.

#### Scenario 6: Non-existent shader file
- **Description:** Attempt to validate a shader that does not exist
- **Params:** `{ "path": "res://shaders/ghost_shader.gdshader" }`
- **Expected result:** Error response from Godot indicating the file was not found.
- **Notes:** Tests error handling for missing files.

#### Scenario 7: Validate a non-shader file
- **Description:** Attempt to validate a file that is not a shader (e.g., a `.gd` script)
- **Params:** `{ "path": "res://scripts/some_script.gd" }`
- **Expected result:** Error response — the file is not a shader and cannot be validated.
- **Notes:** Tests that the handler only validates `.gdshader` files.

#### Scenario 8: Validate empty shader file
- **Description:** Validate a shader file with no content or only whitespace
- **Params:** `{ "path": "res://shaders/test_empty.gdshader" }`
- **Expected result:** Error response — the shader is empty and does not compile.
- **Notes:** Prerequisite: Create an empty `.gdshader` file.

#### Scenario 9: Validate shader with missing `shader_type` declaration
- **Description:** Validate a file without the required `shader_type` preprocessor directive
- **Params:** `{ "path": "res://shaders/test_no_type.gdshader" }`
- **Expected result:** Error response — compilation fails because `shader_type` is required.
- **Notes:** Prerequisite: Create a file with fragment code but no `shader_type` line.

---

## Tool: `delete_shader`

**Handler:** `callGodot(bridge, 'shader/delete', args)`
**Description:** Delete a shader file from the project

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` | **Yes** | — | Shader file path to delete, e.g. `"res://shaders/my_shader.gdshader"` |
| `force` | `boolean` | No | `false` | Delete even if shader is referenced by nodes |

### Test Scenarios

#### Scenario 1: Happy path — delete an unreferenced shader
- **Description:** Delete a shader file that is not currently referenced by any node
- **Params:** `{ "path": "res://shaders/test_default.gdshader" }`
- **Expected result:** Success response. The shader file is removed from the project. Verify via `read_shader` that the file no longer exists.
- **Notes:** Prerequisites: The shader exists and is not assigned to any node's material. `force` defaults to `false`.

#### Scenario 2: Delete a shader that is referenced by a node (without `force`)
- **Description:** Attempt to delete a shader that is currently assigned to a node's ShaderMaterial
- **Params:** `{ "path": "res://shaders/test_spatial.gdshader" }`
- **Expected result:** Error response from Godot — the shader is in use and cannot be deleted. Or it may succeed with a warning. Document observed behavior.
- **Notes:** Prerequisites: `test_spatial.gdshader` is assigned to the `Cube` node via `assign_shader_material`. Tests that deletion protection works.

#### Scenario 3: Delete a referenced shader with `force` = `true`
- **Description:** Force delete a shader that is currently referenced by a node
- **Params:** `{ "path": "res://shaders/test_spatial.gdshader", "force": true }`
- **Expected result:** Success response. The shader file is deleted despite being referenced. The referencing node's ShaderMaterial may break (render pink/default).
- **Notes:** Prerequisites: Same as Scenario 2. Tests that `force` overrides the safety check.

#### Scenario 4: Delete a shader with `force` = `false` explicitly
- **Description:** Explicitly set force to false when deleting
- **Params:** `{ "path": "res://shaders/test_canvas.gdshader", "force": false }`
- **Expected result:** Same as Scenario 1 — deletes the file if unreferenced, blocks if referenced.
- **Notes:** Tests that explicit `false` behaves the same as omitting the default.

#### Scenario 5: Missing required param — omit `path`
- **Description:** Call without the `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error from the MCP server.
- **Notes:** Tests that `path` is properly marked as required.

#### Scenario 6: Delete a non-existent shader file
- **Description:** Attempt to delete a shader that does not exist
- **Params:** `{ "path": "res://shaders/already_deleted.gdshader" }`
- **Expected result:** Error response from Godot indicating the file was not found.
- **Notes:** Tests error handling for missing files.

#### Scenario 7: Delete a file that is not a shader
- **Description:** Attempt to delete a file with an extension other than `.gdshader`
- **Params:** `{ "path": "res://scripts/some_script.gd" }`
- **Expected result:** The tool may use a generic string type for `path` (not `FilePath` from shared-types), so it might not validate the extension. The Godot handler may or may not restrict to shader files. Document observed behavior.
- **Notes:** Note that `delete_shader` uses `z.string()` for path, not `FilePath`. This means it accepts any string. Document whether the Godot handler restricts deletion only to `.gdshader` files.

#### Scenario 8: Delete with `force` as non-boolean value
- **Description:** Pass a truthy/falsy non-boolean for `force`
- **Params:** `{ "path": "res://shaders/test_fog.gdshader", "force": "yes" }`
- **Expected result:** Zod validation error — `force` must be a boolean.
- **Notes:** Tests type validation on the boolean parameter.

#### Scenario 9: Delete a shader from a subdirectory
- **Description:** Delete a shader located in a nested directory
- **Params:** `{ "path": "res://shaders/subfolder/test_nested.gdshader" }`
- **Expected result:** Success response if the file exists. The shader is deleted from the subdirectory.
- **Notes:** Prerequisites: The file `res://shaders/subfolder/test_nested.gdshader` exists from `create_shader` Scenario 15.

#### Scenario 10: Delete with empty string path
- **Description:** Attempt to delete with an empty path string
- **Params:** `{ "path": "" }`
- **Expected result:** Error response — empty path is invalid.
- **Notes:** Tests input validation for empty string.

---

## Cross-Tool Workflow Test

### Scenario: Full shader lifecycle
- **Description:** Test the complete create → read → validate → assign → set params → get params → delete workflow
- **Steps:**
  1. `create_shader` with `{ "path": "res://shaders/lifecycle_test.gdshader", "type": "canvas_item", "content": "shader_type canvas_item;\n\nuniform float brightness = 1.0;\nuniform vec4 base_color : source_color = vec4(1.0);\n\nvoid fragment() {\n    COLOR = base_color * brightness;\n}" }` → Success
  2. `read_shader` with `{ "path": "res://shaders/lifecycle_test.gdshader" }` → Returns the content with brightness and base_color uniforms
  3. `validate_shader` with `{ "path": "res://shaders/lifecycle_test.gdshader" }` → No errors
  4. `assign_shader_material` with `{ "node_path": "Sprite2D", "shader_path": "res://shaders/lifecycle_test.gdshader" }` → Success
  5. `set_shader_param` with `{ "node_path": "Sprite2D", "param": "brightness", "value": 0.5 }` → Success
  6. `set_shader_param` with `{ "node_path": "Sprite2D", "param": "base_color", "value": [0.0, 1.0, 0.0, 1.0] }` → Success
  7. `get_shader_params` with `{ "node_path": "Sprite2D" }` → Returns `brightness: 0.5`, `base_color: [0, 1, 0, 1]`
  8. `list_shaders` with `{}` → The list includes `res://shaders/lifecycle_test.gdshader`
  9. `delete_shader` with `{ "path": "res://shaders/lifecycle_test.gdshader" }` → Error (shader is referenced by Sprite2D)
  10. `delete_shader` with `{ "path": "res://shaders/lifecycle_test.gdshader", "force": true }` → Success
  11. `read_shader` with `{ "path": "res://shaders/lifecycle_test.gdshader" }` → Error (file not found)
- **Expected result:** All steps succeed or produce expected errors as described.
- **Notes:** This is the primary integration test for all shader tools working together.

---

## Parameter Coverage Summary

| Tool | Total Scenarios | Happy Path | Per-Enum-Value | Edge/Error |
|------|-----------------|------------|----------------|------------|
| `create_shader` | 17 | 2 | 7 (all shader types) | 8 |
| `read_shader` | 7 | 1 | — | 6 |
| `edit_shader` | 11 | 1 | — | 10 |
| `assign_shader_material` | 11 | 1 | — | 10 |
| `set_shader_param` | 12 | 1 | — | 11 |
| `get_shader_params` | 6 | 1 | — | 5 |
| `list_shaders` | 6 | 1 | — | 5 |
| `validate_shader` | 9 | 1 | — | 8 |
| `delete_shader` | 10 | 1 | — | 9 |
| **Cross-tool workflow** | 1 | 1 | — | — |
| **Total** | **90** | 11 | 7 | 72 |
