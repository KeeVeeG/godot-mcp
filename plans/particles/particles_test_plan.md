# Particles Tools Test Plan

**Source file:** `server/src/tools/particles.ts`
**Godot bridge method prefix:** `particles/`
**Shared schemas used:** `NodePath`, `ParentPath`, `Dimension`, `Properties`, `OptionalProperties` (from `shared-types.ts`)
**Handler pattern:** All tools call `callGodot(bridge, 'particles/<action>', args)`

---

## Shared Type Definitions

| Schema | Type | Constraints |
|--------|------|-------------|
| `NodePath` | `string` | Path in scene tree, e.g. `"Player/Sprite2D"`, `""` for scene root |
| `ParentPath` | `string` | Parent node path — `""` for scene root, e.g. `"Player"` or `"Player/Sprites"` |
| `Dimension` | `enum` | `"2d"` or `"3d"` |
| `Properties` | `z.record(z.unknown())` | **Required** dictionary of key-value pairs |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | Optional dictionary of key-value pairs |

---

## Tool: `create_particles`

**Handler:** `callGodot(bridge, 'particles/create', args)`
**Description:** Create a GPUParticles2D or GPUParticles3D node

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `parent` | `ParentPath` (string) | **Yes** | — | Parent node path. `""` for scene root, or e.g. `"Player"` |
| `type` | `Dimension` (enum) | **Yes** | — | `"2d"` for GPUParticles2D, `"3d"` for GPUParticles3D |
| `properties` | `OptionalProperties` (record) | No | — | Optional property key-value pairs |

### Test Scenarios

#### Scenario 1: Happy path — create 2D particles at scene root
- **Description:** Create a GPUParticles2D node at the scene root with no extra properties
- **Params:** `{ "parent": "", "type": "2d" }`
- **Expected result:** Success response. A GPUParticles2D node is added as a child of the scene root. The node gets an auto-generated name.
- **Notes:** Validate via `get_scene_tree` that the new node appears.

#### Scenario 2: Happy path — create 3D particles at scene root
- **Description:** Create a GPUParticles3D node at the scene root with no extra properties
- **Params:** `{ "parent": "", "type": "3d" }`
- **Expected result:** Success response. A GPUParticles3D node is added as a child of the scene root.
- **Notes:** Ensure the scene supports 3D nodes (root is Node3D or similar).

#### Scenario 3: Create particles under a specific parent node
- **Description:** Create a GPUParticles2D node as a child of a specific parent
- **Params:** `{ "parent": "Player", "type": "2d" }`
- **Expected result:** Success response. A GPUParticles2D node is added as a child of the `Player` node.
- **Notes:** Prerequisite: `Player` node must exist in the scene.

#### Scenario 4: Create particles with properties
- **Description:** Create a GPUParticles2D node with initial properties set
- **Params:** `{ "parent": "", "type": "2d", "properties": { "amount": 100, "lifetime": 2.0, "emitting": true } }`
- **Expected result:** Success response. A GPUParticles2D node is created with `amount=100`, `lifetime=2.0`, and `emitting=true`.
- **Notes:** The Godot-side handler must apply these properties to the created node.

#### Scenario 5: Create particles with empty properties object
- **Description:** Create with an explicit empty properties object
- **Params:** `{ "parent": "", "type": "2d", "properties": {} }`
- **Expected result:** Success response. The node is created with default property values.
- **Notes:** Should behave identically to omitting `properties` entirely.

#### Scenario 6: Missing required param — omit `parent`
- **Description:** Call without the `parent` parameter
- **Params:** `{ "type": "2d" }`
- **Expected result:** Zod validation error from the MCP server. The call should not reach the Godot bridge.
- **Notes:** Tests that `parent` is properly marked as required.

#### Scenario 7: Missing required param — omit `type`
- **Description:** Call without the `type` parameter
- **Params:** `{ "parent": "" }`
- **Expected result:** Zod validation error from the MCP server. The call should not reach the Godot bridge.
- **Notes:** Tests that `type` is properly marked as required.

#### Scenario 8: Invalid enum value for `type`
- **Description:** Provide a value not in the Dimension enum
- **Params:** `{ "parent": "", "type": "4d" }`
- **Expected result:** Zod validation error — `type` must be `"2d"` or `"3d"`.
- **Notes:** Tests enum constraint enforcement.

#### Scenario 9: Non-existent parent path
- **Description:** Call with a parent path that does not exist in the current scene
- **Params:** `{ "parent": "NonExistentNode", "type": "2d" }`
- **Expected result:** Error response from Godot indicating the parent node was not found.
- **Notes:** Tests error handling at the Godot plugin level.

#### Scenario 10: Parent path with nested hierarchy
- **Description:** Create particles under a deeply nested parent path
- **Params:** `{ "parent": "Player/Effects/Explosions", "type": "3d" }`
- **Expected result:** Success response if the path exists. A GPUParticles3D is added under `Player/Effects/Explosions`.
- **Notes:** Prerequisite: The nested node path must exist in the scene.

---

## Tool: `delete_particles`

**Handler:** `callGodot(bridge, 'particles/delete', args)`
**Description:** Delete a particle system node from the scene

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `NodePath` (string) | **Yes** | — | Path to the particle node to delete |

### Test Scenarios

#### Scenario 1: Happy path — delete an existing particle node
- **Description:** Delete a GPUParticles2D node that exists in the current scene
- **Params:** `{ "node_path": "GPUParticles2D" }`
- **Expected result:** Success response. The node is removed from the scene tree.
- **Notes:** Prerequisite: A GPUParticles2D node exists at the root level. Verify via `get_scene_tree` that it is gone after the call.

#### Scenario 2: Delete a particle node at a nested path
- **Description:** Delete a particle node inside a parent hierarchy
- **Params:** `{ "node_path": "Player/ExplosionEffect" }`
- **Expected result:** Success response. The node `Player/ExplosionEffect` is removed.
- **Notes:** Prerequisite: The nested particle node must exist.

#### Scenario 3: Missing required param — omit `node_path`
- **Description:** Call without the `node_path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error from the MCP server. The call should not reach the Godot bridge.
- **Notes:** Tests that `node_path` is properly marked as required.

#### Scenario 4: Non-existent node path
- **Description:** Call with a path that does not exist in the current scene
- **Params:** `{ "node_path": "NonExistentParticles" }`
- **Expected result:** Error response from Godot indicating the node was not found.

#### Scenario 5: Path to a non-particle node
- **Description:** Try to delete a node that exists but is NOT a particle system (e.g., a Sprite2D)
- **Params:** `{ "node_path": "Sprite2D" }`
- **Expected result:** Error response from Godot or the node is deleted anyway (depends on Godot-side implementation — the tool description says "Delete a particle system node" but the handler may not enforce the type). Note behavior.
- **Notes:** If the Godot handler checks the node type, expect an error. If it blindly deletes, the node will be removed regardless.

#### Scenario 6: Delete using empty string path (scene root)
- **Description:** Call with `""` as `node_path`
- **Params:** `{ "node_path": "" }`
- **Expected result:** Likely an error — the scene root is generally not a particle node. Godot-side error response.
- **Notes:** The handler may refuse to delete the scene root.

---

## Tool: `set_particle_material`

**Handler:** `callGodot(bridge, 'particles/set_material', args)`
**Description:** Set or create a ParticleProcessMaterial for a particle system

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `NodePath` (string) | **Yes** | — | Particle node path |
| `properties` | `Properties` (record) | **Yes** | — | Process material properties (direction, spread, gravity, initial_velocity, etc.) |

### Test Scenarios

#### Scenario 1: Happy path — set basic material properties
- **Description:** Set process material properties on a GPUParticles2D node
- **Params:** `{ "path": "GPUParticles2D", "properties": { "direction": [0, -1, 0], "spread": 45, "gravity": [0, 98, 0] } }`
- **Expected result:** Success response. The ParticleProcessMaterial on the node is created/updated with the given properties.
- **Notes:** Prerequisite: A particle node exists at the given path.

#### Scenario 2: Set material with initial_velocity properties
- **Description:** Configure initial velocity range on a particle system
- **Params:** `{ "path": "GPUParticles3D", "properties": { "initial_velocity_min": 10.0, "initial_velocity_max": 50.0 } }`
- **Expected result:** Success response. The material's velocity range is configured.
- **Notes:** Prerequisite: A GPUParticles3D node exists at the given path.

#### Scenario 3: Set material with scale and color properties
- **Description:** Configure scale and color-related material properties
- **Params:** `{ "path": "GPUParticles2D", "properties": { "scale_min": 0.5, "scale_max": 2.0, "color": [1, 0, 0, 1] } }`
- **Expected result:** Success response. The material properties are applied.
- **Notes:** Properties are arbitrary — the Godot handler determines which are valid.

#### Scenario 4: Empty properties object
- **Description:** Call with an empty properties record
- **Params:** `{ "path": "GPUParticles2D", "properties": {} }`
- **Expected result:** May succeed (no changes applied) or error depending on Godot-side validation.
- **Notes:** The Zod schema allows an empty object since `z.record(z.unknown())` accepts any object.

#### Scenario 5: Missing required param — omit `path`
- **Description:** Call without the `path` parameter
- **Params:** `{ "properties": { "spread": 45 } }`
- **Expected result:** Zod validation error from the MCP server.
- **Notes:** Tests that `path` is properly marked as required.

#### Scenario 6: Missing required param — omit `properties`
- **Description:** Call without the `properties` parameter
- **Params:** `{ "path": "GPUParticles2D" }`
- **Expected result:** Zod validation error from the MCP server.
- **Notes:** Tests that `properties` is properly marked as required (unlike `OptionalProperties`, `Properties` is required).

#### Scenario 7: Non-existent particle node path
- **Description:** Call with a path that does not exist
- **Params:** `{ "path": "NonExistentParticles", "properties": { "spread": 45 } }`
- **Expected result:** Error response from Godot indicating the node was not found.

#### Scenario 8: Path to a non-particle node
- **Description:** Try to set material on a node that is not a particle system
- **Params:** `{ "path": "Sprite2D", "properties": { "spread": 45 } }`
- **Expected result:** Error response from Godot — the node does not have a particle material to configure.

---

## Tool: `set_particle_color_gradient`

**Handler:** `callGodot(bridge, 'particles/set_color_gradient', args)`
**Description:** Set a color gradient on a particle system

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `NodePath` (string) | **Yes** | — | Particle node path |
| `gradient` | `array<{offset, color}>` | **Yes** | — | Gradient color stops. Each stop: `offset` (number 0-1) and `color` (string, hex format e.g. `"#FF0000FF"`) |

### Test Scenarios

#### Scenario 1: Happy path — single color stop gradient
- **Description:** Set a gradient with a single color stop
- **Params:** `{ "path": "GPUParticles2D", "gradient": [{ "offset": 1, "color": "#FF0000FF" }] }`
- **Expected result:** Success response. The particle system's color gradient is set to solid red.
- **Notes:** Prerequisite: A particle node exists at the given path.

#### Scenario 2: Happy path — two color stop gradient (start → end)
- **Description:** Set a gradient that transitions from white at start to blue at end
- **Params:** `{ "path": "GPUParticles2D", "gradient": [{ "offset": 0, "color": "#FFFFFFFF" }, { "offset": 1, "color": "#0000FFFF" }] }`
- **Expected result:** Success response. The gradient transitions from white to blue over the particle lifetime.
- **Notes:** Common use case — lifetime color fade.

#### Scenario 3: Happy path — multi-stop gradient
- **Description:** Set a gradient with three stops — fire-like transition
- **Params:** `{ "path": "GPUParticles2D", "gradient": [{ "offset": 0, "color": "#FFFF00FF" }, { "offset": 0.5, "color": "#FF8800FF" }, { "offset": 1, "color": "#FF000000" }] }`
- **Expected result:** Success response. The gradient has 3 stops with yellow → orange → transparent red transition.
- **Notes:** Tests that multiple stops are accepted.

#### Scenario 4: All offset at boundaries — 0 and 1
- **Description:** Set gradient stops at the exact min (0) and max (1) boundaries
- **Params:** `{ "path": "GPUParticles2D", "gradient": [{ "offset": 0, "color": "#00FF00FF" }, { "offset": 1, "color": "#0000FFFF" }] }`
- **Expected result:** Success response.
- **Notes:** Boundary values should be accepted.

#### Scenario 5: Empty gradient array
- **Description:** Call with an empty gradient array
- **Params:** `{ "path": "GPUParticles2D", "gradient": [] }`
- **Expected result:** The Zod schema allows an empty array (`z.array(...)`). The Godot handler determines behavior — may clear the gradient or error.
- **Notes:** Document actual Godot behavior for reference.

#### Scenario 6: Invalid offset — below minimum
- **Description:** Provide an offset value below 0
- **Params:** `{ "path": "GPUParticles2D", "gradient": [{ "offset": -0.1, "color": "#FF0000FF" }] }`
- **Expected result:** Zod validation error — `offset` must be ≥ 0.
- **Notes:** Tests `.min(0)` constraint.

#### Scenario 7: Invalid offset — above maximum
- **Description:** Provide an offset value above 1
- **Params:** `{ "path": "GPUParticles2D", "gradient": [{ "offset": 1.5, "color": "#FF0000FF" }] }`
- **Expected result:** Zod validation error — `offset` must be ≤ 1.
- **Notes:** Tests `.max(1)` constraint.

#### Scenario 8: Invalid color format — not a hex string
- **Description:** Provide a color value that is not a hex string
- **Params:** `{ "path": "GPUParticles2D", "gradient": [{ "offset": 0.5, "color": "red" }] }`
- **Expected result:** The Zod schema accepts any string (no regex validation on `color`). May pass validation but Godot handler may reject the non-hex color string.
- **Notes:** The `color` field has type `string` with description "Color as hex" — no Zod regex constraint. Document whether Godot-side validates hex format.

#### Scenario 9: Missing required param — omit `path`
- **Description:** Call without the `path` parameter
- **Params:** `{ "gradient": [{ "offset": 1, "color": "#FF0000FF" }] }`
- **Expected result:** Zod validation error from the MCP server.

#### Scenario 10: Missing required param — omit `gradient`
- **Description:** Call without the `gradient` parameter
- **Params:** `{ "path": "GPUParticles2D" }`
- **Expected result:** Zod validation error from the MCP server.

#### Scenario 11: Missing sub-field — omit `color` in a stop
- **Description:** Provide a gradient stop without the required `color` field
- **Params:** `{ "path": "GPUParticles2D", "gradient": [{ "offset": 0.5 }] }`
- **Expected result:** Zod validation error — `color` is required in each stop object.

#### Scenario 12: Missing sub-field — omit `offset` in a stop
- **Description:** Provide a gradient stop without the required `offset` field
- **Params:** `{ "path": "GPUParticles2D", "gradient": [{ "color": "#FF0000FF" }] }`
- **Expected result:** Zod validation error — `offset` is required in each stop object.

#### Scenario 13: Non-existent particle node path
- **Description:** Call with a path that does not exist in the current scene
- **Params:** `{ "path": "NonExistentNode", "gradient": [{ "offset": 1, "color": "#FF0000FF" }] }`
- **Expected result:** Error response from Godot indicating the node was not found.

---

## Tool: `apply_particle_preset`

**Handler:** `callGodot(bridge, 'particles/apply_preset', args)`
**Description:** Apply a predefined particle effect preset

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `NodePath` (string) | **Yes** | — | Particle node path |
| `preset` | `enum` | **Yes** | — | `"fire"`, `"smoke"`, `"sparks"`, `"rain"`, or `"snow"` |

### Test Scenarios

#### Scenario 1: Happy path — apply "fire" preset
- **Description:** Apply the fire preset to a GPUParticles2D node
- **Params:** `{ "path": "GPUParticles2D", "preset": "fire" }`
- **Expected result:** Success response. The particle system is configured with fire-like properties (orange/red gradient, upward velocity, etc.).
- **Notes:** Prerequisite: A particle node exists at the given path.

#### Scenario 2: Apply "smoke" preset
- **Description:** Apply the smoke preset to a particle node
- **Params:** `{ "path": "GPUParticles2D", "preset": "smoke" }`
- **Expected result:** Success response. The particle system is configured with smoke-like properties (gray gradient, slow rising, spread, etc.).
- **Notes:** Test each enum value.

#### Scenario 3: Apply "sparks" preset
- **Description:** Apply the sparks preset to a particle node
- **Params:** `{ "path": "GPUParticles2D", "preset": "sparks" }`
- **Expected result:** Success response. The particle system is configured with spark-like properties (bright colors, high velocity, small scale, etc.).
- **Notes:** Test each enum value.

#### Scenario 4: Apply "rain" preset
- **Description:** Apply the rain preset to a particle node
- **Params:** `{ "path": "GPUParticles2D", "preset": "rain" }`
- **Expected result:** Success response. The particle system is configured with rain-like properties (blue/white, downward velocity, narrow spread).
- **Notes:** Test each enum value.

#### Scenario 5: Apply "snow" preset
- **Description:** Apply the snow preset to a particle node
- **Params:** `{ "path": "GPUParticles2D", "preset": "snow" }`
- **Expected result:** Success response. The particle system is configured with snow-like properties (white, slow falling, wide spread, gentle motion).
- **Notes:** Test each enum value.

#### Scenario 6: Apply preset to a 3D particle node
- **Description:** Apply a preset to a GPUParticles3D node
- **Params:** `{ "path": "GPUParticles3D", "preset": "fire" }`
- **Expected result:** Success or error depending on whether presets are designed for 2D only. Document actual behavior.
- **Notes:** The Dimension type is not part of this tool's schema — test whether 3D presets work.

#### Scenario 7: Invalid enum value for `preset`
- **Description:** Provide a value not in the preset enum
- **Params:** `{ "path": "GPUParticles2D", "preset": "confetti" }`
- **Expected result:** Zod validation error — `preset` must be one of `"fire"`, `"smoke"`, `"sparks"`, `"rain"`, `"snow"`.
- **Notes:** Tests enum constraint enforcement. "confetti" is not a valid preset (though mentioned in the project README).

#### Scenario 8: Missing required param — omit `path`
- **Description:** Call without the `path` parameter
- **Params:** `{ "preset": "fire" }`
- **Expected result:** Zod validation error from the MCP server.

#### Scenario 9: Missing required param — omit `preset`
- **Description:** Call without the `preset` parameter
- **Params:** `{ "path": "GPUParticles2D" }`
- **Expected result:** Zod validation error from the MCP server.

#### Scenario 10: Non-existent particle node path
- **Description:** Call with a path that does not exist in the current scene
- **Params:** `{ "path": "NonExistentParticles", "preset": "snow" }`
- **Expected result:** Error response from Godot indicating the node was not found.

#### Scenario 11: Path to a non-particle node
- **Description:** Try to apply a preset to a non-particle node
- **Params:** `{ "path": "Sprite2D", "preset": "fire" }`
- **Expected result:** Error response from Godot — the node is not a particle system.
- **Notes:** Tests Godot-side type checking.

---

## Tool: `get_particle_info`

**Handler:** `callGodot(bridge, 'particles/get_info', args)`
**Description:** Get information about a particle system's configuration

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `NodePath` (string) | **Yes** | — | Particle node path |

### Test Scenarios

#### Scenario 1: Happy path — get info for a GPUParticles2D node
- **Description:** Query configuration info for an existing particle node
- **Params:** `{ "path": "GPUParticles2D" }`
- **Expected result:** JSON response containing particle system configuration details (e.g., amount, lifetime, material settings, emission shape, etc.). No error.
- **Notes:** Prerequisite: A GPUParticles2D node exists in the scene. The exact response structure depends on the Godot handler.

#### Scenario 2: Get info for a GPUParticles3D node
- **Description:** Query configuration info for a 3D particle node
- **Params:** `{ "path": "GPUParticles3D" }`
- **Expected result:** JSON response with 3D particle system configuration details.
- **Notes:** Prerequisite: A GPUParticles3D node exists in the scene.

#### Scenario 3: Get info for a particle node at a nested path
- **Description:** Query a particle system nested inside another node
- **Params:** `{ "path": "Player/ExplosionEffect" }`
- **Expected result:** JSON response with the particle system's configuration.
- **Notes:** Prerequisite: The nested node exists and is a particle system.

#### Scenario 4: Get info for a freshly created (default) particle node
- **Description:** Query info for a particle node with no custom configuration
- **Params:** `{ "path": "GPUParticles2D" }`
- **Expected result:** JSON response showing default particle system values.
- **Notes:** Useful baseline — compare against a configured node.

#### Scenario 5: Missing required param — omit `path`
- **Description:** Call without the `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error from the MCP server.
- **Notes:** Tests that `path` is properly marked as required.

#### Scenario 6: Non-existent node path
- **Description:** Call with a path that does not exist
- **Params:** `{ "path": "NonExistentParticles" }`
- **Expected result:** Error response from Godot indicating the node was not found.

#### Scenario 7: Path to a non-particle node
- **Description:** Query info for a node that is NOT a particle system
- **Params:** `{ "path": "Sprite2D" }`
- **Expected result:** Error response from Godot — the node is not a particle system.
- **Notes:** Tests that the Godot handler validates node type.

---

## Tool: `set_particle_emission_shape`

**Handler:** `callGodot(bridge, 'particles/set_emission_shape', args)`
**Description:** Set the emission shape for a particle system

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `NodePath` (string) | **Yes** | — | Particle node path |
| `shape` | `enum` | **Yes** | — | `"point"`, `"sphere"`, `"box"`, or `"ring"` |
| `size` | `number[]` (array) | No | — | Shape size parameters |

### Test Scenarios

#### Scenario 1: Happy path — set "point" emission shape
- **Description:** Set emission shape to point with no size parameters
- **Params:** `{ "path": "GPUParticles2D", "shape": "point" }`
- **Expected result:** Success response. The particle system emits from a single point.
- **Notes:** Prerequisite: A particle node exists at the given path.

#### Scenario 2: Set "sphere" emission shape
- **Description:** Set emission shape to sphere
- **Params:** `{ "path": "GPUParticles3D", "shape": "sphere" }`
- **Expected result:** Success response. The particle system emits from a sphere shape.
- **Notes:** Test each enum value.

#### Scenario 3: Set "box" emission shape
- **Description:** Set emission shape to box
- **Params:** `{ "path": "GPUParticles3D", "shape": "box" }`
- **Expected result:** Success response. The particle system emits from a box shape.
- **Notes:** Test each enum value.

#### Scenario 4: Set "ring" emission shape
- **Description:** Set emission shape to ring
- **Params:** `{ "path": "GPUParticles2D", "shape": "ring" }`
- **Expected result:** Success response. The particle system emits from a ring shape.
- **Notes:** Test each enum value. Ring is primarily meaningful for 2D.

#### Scenario 5: Set shape with size parameters — sphere with radius
- **Description:** Set sphere shape with explicit size
- **Params:** `{ "path": "GPUParticles3D", "shape": "sphere", "size": [5.0] }`
- **Expected result:** Success response. The sphere emission shape has radius 5.0.
- **Notes:** The exact interpretation of `size` array elements depends on the shape type and the Godot handler.

#### Scenario 6: Set shape with size parameters — box with dimensions
- **Description:** Set box shape with width, height, depth
- **Params:** `{ "path": "GPUParticles3D", "shape": "box", "size": [4.0, 2.0, 3.0] }`
- **Expected result:** Success response. The box emission shape is sized to the given dimensions.
- **Notes:** Tests that size arrays with multiple elements are accepted.

#### Scenario 7: Set shape with empty size array
- **Description:** Set shape with an explicit empty size array
- **Params:** `{ "path": "GPUParticles2D", "shape": "point", "size": [] }`
- **Expected result:** The Zod schema allows an empty array. The Godot handler determines behavior — may use defaults or error.
- **Notes:** Document actual behavior.

#### Scenario 8: Invalid enum value for `shape`
- **Description:** Provide a value not in the emission shape enum
- **Params:** `{ "path": "GPUParticles2D", "shape": "cone" }`
- **Expected result:** Zod validation error — `shape` must be `"point"`, `"sphere"`, `"box"`, or `"ring"`.
- **Notes:** Tests enum constraint enforcement.

#### Scenario 9: Missing required param — omit `path`
- **Description:** Call without the `path` parameter
- **Params:** `{ "shape": "point" }`
- **Expected result:** Zod validation error from the MCP server.

#### Scenario 10: Missing required param — omit `shape`
- **Description:** Call without the `shape` parameter
- **Params:** `{ "path": "GPUParticles2D" }`
- **Expected result:** Zod validation error from the MCP server.

#### Scenario 11: Size parameter with non-numeric values
- **Description:** Provide size entries that are not numbers
- **Params:** `{ "path": "GPUParticles3D", "shape": "sphere", "size": ["large"] }`
- **Expected result:** Zod validation error — `size` is defined as `z.array(z.number())`. String not accepted.
- **Notes:** Tests numeric constraint on size array elements.

#### Scenario 12: Non-existent particle node path
- **Description:** Call with a path that does not exist
- **Params:** `{ "path": "NonExistent", "shape": "point" }`
- **Expected result:** Error response from Godot indicating the node was not found.

---

## Tool: `set_particle_velocity_curve`

**Handler:** `callGodot(bridge, 'particles/set_velocity_curve', args)`
**Description:** Set a velocity curve for a particle system

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `NodePath` (string) | **Yes** | — | Particle node path |
| `curve` | `array<{offset, value}>` | **Yes** | — | Curve points. Each point: `offset` (number 0-1), `value` (number) |

### Test Scenarios

#### Scenario 1: Happy path — single curve point
- **Description:** Set a velocity curve with a single point (constant velocity)
- **Params:** `{ "path": "GPUParticles2D", "curve": [{ "offset": 1, "value": 100 }] }`
- **Expected result:** Success response. The velocity curve is set with a constant value of 100.
- **Notes:** Prerequisite: A particle node exists at the given path.

#### Scenario 2: Happy path — two-point velocity curve
- **Description:** Set a velocity curve that goes from 0 to max
- **Params:** `{ "path": "GPUParticles2D", "curve": [{ "offset": 0, "value": 0 }, { "offset": 1, "value": 200 }] }`
- **Expected result:** Success response. Velocity ramps up from 0 to 200 over the particle lifetime.
- **Notes:** Common use case — accelerating particles.

#### Scenario 3: Happy path — multi-point curve (bell shape)
- **Description:** Set a curve with multiple points for complex velocity profile
- **Params:** `{ "path": "GPUParticles2D", "curve": [{ "offset": 0, "value": 0 }, { "offset": 0.25, "value": 150 }, { "offset": 0.5, "value": 300 }, { "offset": 0.75, "value": 150 }, { "offset": 1, "value": 0 }] }`
- **Expected result:** Success response. The velocity follows a bell-shaped curve — starts at 0, peaks at offset 0.5, returns to 0.
- **Notes:** Tests that multiple curve points are accepted.

#### Scenario 4: Negative velocity values
- **Description:** Set a curve with negative values (e.g., reverse direction)
- **Params:** `{ "path": "GPUParticles2D", "curve": [{ "offset": 0, "value": -50 }, { "offset": 1, "value": -200 }] }`
- **Expected result:** Success response. The velocity curve accepts negative values.
- **Notes:** No Zod constraint prevents negative numbers — `z.number()` allows any numeric value.

#### Scenario 5: All offset at boundaries — 0 and 1
- **Description:** Set curve points at the exact min (0) and max (1) boundaries
- **Params:** `{ "path": "GPUParticles2D", "curve": [{ "offset": 0, "value": 10 }, { "offset": 1, "value": 100 }] }`
- **Expected result:** Success response.
- **Notes:** Boundary values should be accepted.

#### Scenario 6: Zero velocity throughout
- **Description:** Set a curve with all zero values
- **Params:** `{ "path": "GPUParticles2D", "curve": [{ "offset": 0, "value": 0 }, { "offset": 1, "value": 0 }] }`
- **Expected result:** Success response. The particles have no velocity (stationary).
- **Notes:** Valid use case — particles at rest.

#### Scenario 7: Empty curve array
- **Description:** Call with an empty curve array
- **Params:** `{ "path": "GPUParticles2D", "curve": [] }`
- **Expected result:** The Zod schema allows an empty array. The Godot handler determines behavior — may clear the curve or error.
- **Notes:** Document actual Godot behavior.

#### Scenario 8: Invalid offset — below minimum
- **Description:** Provide an offset value below 0
- **Params:** `{ "path": "GPUParticles2D", "curve": [{ "offset": -0.5, "value": 100 }] }`
- **Expected result:** Zod validation error — `offset` must be ≥ 0.
- **Notes:** Tests `.min(0)` constraint.

#### Scenario 9: Invalid offset — above maximum
- **Description:** Provide an offset value above 1
- **Params:** `{ "path": "GPUParticles2D", "curve": [{ "offset": 2.0, "value": 100 }] }`
- **Expected result:** Zod validation error — `offset` must be ≤ 1.
- **Notes:** Tests `.max(1)` constraint.

#### Scenario 10: Missing required param — omit `path`
- **Description:** Call without the `path` parameter
- **Params:** `{ "curve": [{ "offset": 1, "value": 100 }] }`
- **Expected result:** Zod validation error from the MCP server.

#### Scenario 11: Missing required param — omit `curve`
- **Description:** Call without the `curve` parameter
- **Params:** `{ "path": "GPUParticles2D" }`
- **Expected result:** Zod validation error from the MCP server.

#### Scenario 12: Missing sub-field — omit `offset` in a point
- **Description:** Provide a curve point without the required `offset` field
- **Params:** `{ "path": "GPUParticles2D", "curve": [{ "value": 100 }] }`
- **Expected result:** Zod validation error — `offset` is required in each curve point object.

#### Scenario 13: Missing sub-field — omit `value` in a point
- **Description:** Provide a curve point without the required `value` field
- **Params:** `{ "path": "GPUParticles2D", "curve": [{ "offset": 0.5 }] }`
- **Expected result:** Zod validation error — `value` is required in each curve point object.

#### Scenario 14: Non-existent particle node path
- **Description:** Call with a path that does not exist
- **Params:** `{ "path": "NonExistent", "curve": [{ "offset": 1, "value": 100 }] }`
- **Expected result:** Error response from Godot indicating the node was not found.

---

## Cross-Tool Integration Tests

These scenarios test interactions between multiple particle tools to ensure consistency.

### Integration Scenario 1: Create → Configure → Query
- **Steps:**
  1. `create_particles({ "parent": "", "type": "2d" })` — creates GPUParticles2D
  2. `set_particle_material({ "path": "GPUParticles2D", "properties": { "spread": 30, "gravity": [0, 98, 0] } })` — configures material
  3. `apply_particle_preset({ "path": "GPUParticles2D", "preset": "fire" })` — applies preset (may override material settings)
  4. `get_particle_info({ "path": "GPUParticles2D" })` — reads back config
- **Expected result:** Step 4 returns configuration reflecting the applied preset (which may override the material from step 2).
- **Notes:** Validates that the full create→configure→preset→read pipeline works.

### Integration Scenario 2: Create → Gradient → Curve → Delete
- **Steps:**
  1. `create_particles({ "parent": "Player", "type": "3d" })` — creates GPUParticles3D under Player
  2. `set_particle_color_gradient({ "path": "Player/GPUParticles3D", "gradient": [{ "offset": 0, "color": "#FFFFFFFF" }, { "offset": 1, "color": "#FF0000FF" }] })` — sets white-to-red gradient
  3. `set_particle_velocity_curve({ "path": "Player/GPUParticles3D", "curve": [{ "offset": 0, "value": 0 }, { "offset": 1, "value": 300 }] })` — sets accelerating velocity
  4. `delete_particles({ "node_path": "Player/GPUParticles3D" })` — deletes the node
- **Expected result:** All steps succeed. After step 4, the node no longer exists in the scene.
- **Notes:** End-to-end lifecycle test.

### Integration Scenario 3: Emission shape with size → Query verification
- **Steps:**
  1. `create_particles({ "parent": "", "type": "3d", "properties": { "amount": 50 } })`
  2. `set_particle_emission_shape({ "path": "GPUParticles3D", "shape": "box", "size": [5, 3, 5] })`
  3. `get_particle_info({ "path": "GPUParticles3D" })`
- **Expected result:** Step 3 returns info showing amount=50 and box emission shape with the specified dimensions.
- **Notes:** Validates that properties set at creation time persist through subsequent configuration.

### Integration Scenario 4: Apply all five presets sequentially
- **Steps:**
  1. `create_particles({ "parent": "", "type": "2d" })`
  2. `apply_particle_preset({ "path": "GPUParticles2D", "preset": "fire" })`
  3. `apply_particle_preset({ "path": "GPUParticles2D", "preset": "smoke" })`
  4. `apply_particle_preset({ "path": "GPUParticles2D", "preset": "sparks" })`
  5. `apply_particle_preset({ "path": "GPUParticles2D", "preset": "rain" })`
  6. `apply_particle_preset({ "path": "GPUParticles2D", "preset": "snow" })`
  7. `get_particle_info({ "path": "GPUParticles2D" })`
- **Expected result:** All preset applications succeed. The final state reflects the last applied preset ("snow"). Each preset application overwrites previous settings.
- **Notes:** Tests that presets can be changed multiple times on the same node without errors.

---

## Summary

| Tool | Bridge Method | Required Params | Optional Params | Enum Params | Scenarios |
|------|--------------|----------------|-----------------|-------------|-----------|
| `create_particles` | `particles/create` | `parent`, `type` | `properties` | `type`: `"2d"`, `"3d"` | 10 |
| `delete_particles` | `particles/delete` | `node_path` | — | — | 6 |
| `set_particle_material` | `particles/set_material` | `path`, `properties` | — | — | 8 |
| `set_particle_color_gradient` | `particles/set_color_gradient` | `path`, `gradient` | — | — | 13 |
| `apply_particle_preset` | `particles/apply_preset` | `path`, `preset` | — | `preset`: `"fire"`, `"smoke"`, `"sparks"`, `"rain"`, `"snow"` | 11 |
| `get_particle_info` | `particles/get_info` | `path` | — | — | 7 |
| `set_particle_emission_shape` | `particles/set_emission_shape` | `path`, `shape` | `size` | `shape`: `"point"`, `"sphere"`, `"box"`, `"ring"` | 12 |
| `set_particle_velocity_curve` | `particles/set_velocity_curve` | `path`, `curve` | — | — | 14 |

**Total scenarios: 81 + 4 integration = 85**
