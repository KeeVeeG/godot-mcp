# Particles Tools — Test Plan

> **Source**: `server/src/tools/particles.ts` (128 lines, 8 tools)
> **Shared types**: `server/src/tools/shared-types.ts`

---

## Shared Types Reference

| Schema | Type | Description |
|--------|------|-------------|
| `NodePath` | `z.string()` | Scene tree path (e.g. `"Player/Sprite2D"`, `""` for scene root) |
| `ParentPath` | `z.string()` | Parent node path (`""` = scene root, `"Player"` = direct root child) |
| `Dimension` | `z.enum(['2d', '3d'])` | Particle dimension |
| `Properties` | `z.record(z.unknown())` | **Required** key-value property dict |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | **Optional** key-value property dict |

---

## Prerequisites

Before running any particle tool tests:

1. A Godot project must be open in the editor
2. The MCP plugin must be active and connected
3. A scene must be currently open (for node creation/manipulation)

---

## Tool: `create_particles`

**Description**: Create a GPUParticles2D or GPUParticles3D node

**Route**: `particles/create`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `parent` | `string` | Yes | Parent node path (`""` = scene root, `"Player"` = child of Player) |
| `type` | `'2d' \| '3d'` | Yes | Dimension type |
| `properties` | `Record<string, unknown>` | No | Optional initial property values (e.g. `amount`, `lifetime`, `emitting`) |

### Test Scenarios

#### Scenario 1: Create GPUParticles2D at scene root (happy path)

**Description**: Create a basic 2D particle system with no custom properties.

**Params**:
```json
{
  "parent": "",
  "type": "2d"
}
```

**Expected Result**:
- Tool returns success (no `isError: true`)
- Response contains information about the newly created `GPUParticles2D` node
- The node name should follow Godot's auto-naming (e.g. `"GPUParticles2D"` or `"GPUParticles2D1"`)

**Notes**: The parent `""` targets the scene root. This is the minimal invocation.

**What to check**: Verify the returned node name is a valid `GPUParticles2D` — the type field should confirm 2D dimensionality.

---

#### Scenario 2: Create GPUParticles3D as child of existing node

**Description**: Create a 3D particle system under a specific parent node.

**Precondition**: A node named `"Player"` (or similar) must exist in the scene. Use `create_node` from `node.ts` if needed:
```json
{ "parent": "", "name": "Player", "type": "Node3D" }
```

**Params**:
```json
{
  "parent": "Player",
  "type": "3d"
}
```

**Expected Result**:
- Tool returns success
- The particle node is created as a child of `"Player"`
- Returned path should be `"Player/GPUParticles3D"` (or similar)

**Notes**: If `"Player"` does not exist, the tool will likely return an error.

**What to check**: Verify the node appears under the correct parent in the scene tree.

---

#### Scenario 3: Create GPUParticles2D with initial properties

**Description**: Create a particle system with custom `amount` and `lifetime` properties.

**Params**:
```json
{
  "parent": "",
  "type": "2d",
  "properties": {
    "amount": 50,
    "lifetime": 2.5,
    "emitting": true
  }
}
```

**Expected Result**:
- Tool returns success
- The created node should have `amount = 50`, `lifetime = 2.5`, `emitting = true`

**Notes**: Verify with `get_node_properties` or `get_particle_info` after creation.

**What to check**: Check that non-default property values actually took effect — use `get_particle_info` to confirm `amount` is `50` and not the Godot default (`8`).

---

#### Scenario 4: Missing required param `type` (error case)

**Description**: Call without `type` to validate schema enforcement.

**Params**:
```json
{
  "parent": ""
}
```

**Expected Result**:
- Tool returns an error (schema validation failure)
- Error message should indicate `type` is required

**Notes**: This tests Zod schema enforcement — `type` is a required field with no default.

**What to check**: The error should be a validation error, not a Godot bridge error. The server should reject before reaching Godot.

---

#### Scenario 5: Invalid `type` value (error case)

**Description**: Pass an invalid dimension value.

**Params**:
```json
{
  "parent": "",
  "type": "4d"
}
```

**Expected Result**:
- Tool returns an error
- Error should indicate invalid enum value (expected `'2d'` or `'3d'`)

**What to check**: The error should mention the allowed values `['2d', '3d']`.

---

### Dependencies

- **Before**: If creating under a non-root parent, that parent must exist. Use `create_node` from `node.ts` first.
- **After**: Use `get_particle_info` to verify creation. Use `delete_particles` to clean up.

---

## Tool: `delete_particles`

**Description**: Delete a particle system node from the scene

**Route**: `particles/delete`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `node_path` | `string` | Yes | Path to the particle node to delete |

### Test Scenarios

#### Scenario 1: Delete an existing particle node (happy path)

**Description**: Create a particle node, then delete it.

**Precondition**: First create a particle node:
```json
{ "parent": "", "type": "2d" }
```

**Params** (assuming the created node is `"GPUParticles2D"`):
```json
{
  "node_path": "GPUParticles2D"
}
```

**Expected Result**:
- Tool returns success
- The node `"GPUParticles2D"` no longer exists in the scene tree

**Notes**: Verify deletion with `get_scene_tree` or by calling `get_particle_info` which should fail.

**What to check**: After deletion, `get_particle_info` on the same path should return an error — this confirms the node is truly removed.

---

#### Scenario 2: Delete non-existent node (error case)

**Description**: Attempt to delete a node that doesn't exist.

**Params**:
```json
{
  "node_path": "NonExistentParticles"
}
```

**Expected Result**:
- Tool returns an error
- Error message should indicate the node was not found

**What to check**: The error should be descriptive (e.g., "Node not found") rather than a silent success or cryptic crash.

---

#### Scenario 3: Delete with empty path (edge case)

**Description**: Attempt to delete with empty string path (scene root).

**Params**:
```json
{
  "node_path": ""
}
```

**Expected Result**:
- Tool returns an error (cannot delete scene root)
- Or: tool rejects empty path via validation

**What to check**: This is a safety check — deleting the scene root would be destructive. The tool should refuse.

---

#### Scenario 4: Delete node by deep path

**Description**: Delete a particle node nested deep in the tree.

**Precondition**: Create a chain:
1. Create node `"Container"` under root
2. Create particle under `"Container"`

**Params**:
```json
{
  "node_path": "Container/GPUParticles2D"
}
```

**Expected Result**:
- Tool returns success
- Only the particle node is deleted, `"Container"` remains

**What to check**: Verify `"Container"` still exists after deletion — only the leaf particle node should be removed.

---

### Dependencies

- **Before**: A particle node must exist. Use `create_particles` to create one.
- **After**: Verify with `get_scene_tree` or `get_particle_info` that the node is gone.

---

## Tool: `set_particle_material`

**Description**: Set or create a ParticleProcessMaterial for a particle system

**Route**: `particles/set_material`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` | Yes | Particle node path |
| `properties` | `Record<string, unknown>` | Yes | Process material properties (`direction`, `spread`, `gravity`, `initial_velocity`, etc.) |

### Test Scenarios

#### Scenario 1: Set basic material properties (happy path)

**Description**: Apply direction and gravity to a particle system.

**Precondition**: A particle node must exist:
```json
{ "parent": "", "type": "2d" }
```

**Params**:
```json
{
  "path": "GPUParticles2D",
  "properties": {
    "direction": [0, -1],
    "spread": 15.0,
    "gravity": [0, 98],
    "initial_velocity_min": 50.0,
    "initial_velocity_max": 100.0
  }
}
```

**Expected Result**:
- Tool returns success
- The particle system now has a `ParticleProcessMaterial` assigned with the specified properties

**Notes**: On 2D particles, `direction` is `[x, y]`. On 3D, it would be `[x, y, z]`.

**What to check**: Call `get_particle_info` after to verify the material was actually created and properties match.

---

#### Scenario 2: Set material with minimal properties

**Description**: Apply only one property to see if material creation works with minimal config.

**Params**:
```json
{
  "path": "GPUParticles2D",
  "properties": {
    "gravity": [0, 50]
  }
}
```

**Expected Result**:
- Tool returns success
- Material is created with default values except for `gravity`

**What to check**: Other material properties should retain Godot defaults, not be zeroed out.

---

#### Scenario 3: Overwrite existing material properties

**Description**: Set material twice with different values.

**Precondition**: First call:
```json
{
  "path": "GPUParticles2D",
  "properties": { "gravity": [0, 98] }
}
```

**Params** (second call):
```json
{
  "path": "GPUParticles2D",
  "properties": {
    "gravity": [0, 200],
    "spread": 45.0
  }
}
```

**Expected Result**:
- Tool returns success
- `gravity` is updated to `[0, 200]`
- `spread` is set to `45.0`
- Previously set properties not mentioned should be preserved

**What to check**: Verify that the second call merges with or replaces the first — the `gravity` should be `[0, 200]`, not `[0, 98]`.

---

#### Scenario 4: Empty properties object (edge case)

**Description**: Pass an empty properties dict.

**Params**:
```json
{
  "path": "GPUParticles2D",
  "properties": {}
}
```

**Expected Result**:
- Tool returns success (creates material with all defaults)
- Or: returns an error indicating properties cannot be empty

**What to check**: This is an edge case — the behavior depends on implementation. Document whether empty props create a default material or reject.

---

#### Scenario 5: Missing `properties` (error case)

**Description**: Omit the required `properties` field.

**Params**:
```json
{
  "path": "GPUParticles2D"
}
```

**Expected Result**:
- Tool returns a validation error
- Error indicates `properties` is required

**What to check**: Unlike `create_particles` which has `OptionalProperties`, this tool uses `Properties` (required). Schema should enforce this.

---

#### Scenario 6: Non-existent particle path (error case)

**Description**: Target a node that doesn't exist.

**Params**:
```json
{
  "path": "GhostParticles",
  "properties": { "gravity": [0, 98] }
}
```

**Expected Result**:
- Tool returns an error indicating the node was not found

---

### Dependencies

- **Before**: A particle node must exist. Use `create_particles` first.
- **After**: Use `get_particle_info` to verify material properties were applied.

---

## Tool: `set_particle_color_gradient`

**Description**: Set a color gradient on a particle system

**Route**: `particles/set_color_gradient`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` | Yes | Particle node path |
| `gradient` | `Array<{ offset: number, color: string }>` | Yes | Gradient color stops |

**`offset`**: `z.number().min(0).max(1)` — gradient position from 0 to 1
**`color`**: `z.string()` — hex color string (e.g. `"#FF0000FF"`)

### Test Scenarios

#### Scenario 1: Simple two-stop gradient (happy path)

**Description**: Set a red-to-transparent gradient.

**Precondition**: Particle node must exist.

**Params**:
```json
{
  "path": "GPUParticles2D",
  "gradient": [
    { "offset": 0.0, "color": "#FF0000FF" },
    { "offset": 1.0, "color": "#FF000000" }
  ]
}
```

**Expected Result**:
- Tool returns success
- Particle system has a color ramp from opaque red to transparent red

**What to check**: The gradient should go from fully opaque red at birth to fully transparent red at death.

---

#### Scenario 2: Multi-stop gradient

**Description**: Set a rainbow-like gradient with 4 stops.

**Params**:
```json
{
  "path": "GPUParticles2D",
  "gradient": [
    { "offset": 0.0, "color": "#FF0000FF" },
    { "offset": 0.33, "color": "#00FF00FF" },
    { "offset": 0.66, "color": "#0000FFFF" },
    { "offset": 1.0, "color": "#FFFFFFFF" }
  ]
}
```

**Expected Result**:
- Tool returns success
- Gradient transitions through red → green → blue → white

**What to check**: Verify all 4 stops are present in the material's color ramp.

---

#### Scenario 3: Single-stop gradient (edge case)

**Description**: Only one color stop — should create a solid color.

**Params**:
```json
{
  "path": "GPUParticles2D",
  "gradient": [
    { "offset": 0.0, "color": "#FFFF00FF" }
  ]
}
```

**Expected Result**:
- Tool returns success
- Particles are solid yellow throughout their lifetime

**What to check**: A single stop should produce a constant color, not an error.

---

#### Scenario 4: Offset out of range (error case)

**Description**: Pass an offset value outside 0-1.

**Params**:
```json
{
  "path": "GPUParticles2D",
  "gradient": [
    { "offset": -0.5, "color": "#FF0000FF" },
    { "offset": 1.5, "color": "#00FF00FF" }
  ]
}
```

**Expected Result**:
- Tool returns a validation error
- Error indicates offset must be between 0 and 1

**What to check**: This tests the `z.number().min(0).max(1)` constraint on `offset`.

---

#### Scenario 5: Empty gradient array (edge case)

**Description**: Pass an empty array.

**Params**:
```json
{
  "path": "GPUParticles2D",
  "gradient": []
}
```

**Expected Result**:
- Tool returns an error (empty gradient is invalid)
- Or: tool returns success with a default gradient

**What to check**: Document the behavior — does Godot accept an empty color ramp?

---

#### Scenario 6: Missing `gradient` (error case)

**Description**: Omit the required `gradient` field.

**Params**:
```json
{
  "path": "GPUParticles2D"
}
```

**Expected Result**:
- Validation error indicating `gradient` is required

---

#### Scenario 7: Invalid color format (edge case)

**Description**: Pass a non-hex color string.

**Params**:
```json
{
  "path": "GPUParticles2D",
  "gradient": [
    { "offset": 0.0, "color": "red" },
    { "offset": 1.0, "color": "blue" }
  ]
}
```

**Expected Result**:
- Either: tool accepts named colors and converts them
- Or: tool returns an error requiring hex format

**What to check**: The schema accepts any `z.string()` for color — the Godot side may or may not parse named colors. Document the actual behavior.

---

### Dependencies

- **Before**: A particle node must exist. Use `create_particles` first.
- **After**: Use `get_particle_info` to verify the gradient was applied.

---

## Tool: `apply_particle_preset`

**Description**: Apply a predefined particle effect preset

**Route**: `particles/apply_preset`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` | Yes | Particle node path |
| `preset` | `'fire' \| 'smoke' \| 'sparks' \| 'rain' \| 'snow'` | Yes | Particle preset name |

### Test Scenarios

#### Scenario 1: Apply fire preset (happy path)

**Description**: Apply the fire preset to a 2D particle system.

**Precondition**: Particle node must exist.

**Params**:
```json
{
  "path": "GPUParticles2D",
  "preset": "fire"
}
```

**Expected Result**:
- Tool returns success
- Particle system is configured with fire-like behavior (upward direction, orange/red gradient, short lifetime)

**What to check**: After applying, use `get_particle_info` to verify material properties match fire characteristics: upward direction, warm color gradient, moderate spread.

---

#### Scenario 2: Apply smoke preset

**Params**:
```json
{
  "path": "GPUParticles2D",
  "preset": "smoke"
}
```

**Expected Result**:
- Tool returns success
- Smoke behavior: upward drift, gray/dark colors, longer lifetime, slow velocity

---

#### Scenario 3: Apply all 5 presets sequentially

**Description**: Verify each preset applies without error.

**Params** (run 5 times, changing `preset`):
```json
{ "path": "GPUParticles2D", "preset": "fire" }
{ "path": "GPUParticles2D", "preset": "smoke" }
{ "path": "GPUParticles2D", "preset": "sparks" }
{ "path": "GPUParticles2D", "preset": "rain" }
{ "path": "GPUParticles2D", "preset": "snow" }
```

**Expected Result**:
- All 5 calls return success
- Each preset overwrites the previous configuration

**What to check**: Each preset should produce visibly different particle behavior. Verify via `get_particle_info` that properties change between presets.

---

#### Scenario 4: Invalid preset name (error case)

**Params**:
```json
{
  "path": "GPUParticles2D",
  "preset": "explosion"
}
```

**Expected Result**:
- Validation error
- Error indicates `"explosion"` is not in the allowed set `['fire', 'smoke', 'sparks', 'rain', 'snow']`

**What to check**: The `z.enum()` should catch this at the schema level before reaching Godot.

---

#### Scenario 5: Preset on 3D particles

**Description**: Apply a preset to GPUParticles3D (should also work).

**Precondition**: Create a 3D particle node.

**Params**:
```json
{
  "path": "GPUParticles3D",
  "preset": "snow"
}
```

**Expected Result**:
- Tool returns success
- Preset is applied correctly to 3D particles

**What to check**: Some presets may be 2D-specific. Document if any preset fails on 3D nodes.

---

### Dependencies

- **Before**: A particle node must exist. Use `create_particles` first.
- **After**: Use `get_particle_info` to verify preset configuration.

---

## Tool: `get_particle_info`

**Description**: Get information about a particle system's configuration

**Route**: `particles/get_info`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` | Yes | Particle node path |

### Test Scenarios

#### Scenario 1: Get info for default particle system (happy path)

**Description**: Create a fresh particle node and read its info.

**Precondition**: Create a particle node:
```json
{ "parent": "", "type": "2d" }
```

**Params**:
```json
{
  "path": "GPUParticles2D"
}
```

**Expected Result**:
- Tool returns success with particle configuration data
- Response should include: `amount`, `lifetime`, `emitting`, `material` (or null), `process_material` details

**What to check**: The response structure — what keys are present? Is it a flat dict or nested? Document the exact shape.

---

#### Scenario 2: Get info after applying preset

**Description**: Apply fire preset, then read info to verify.

**Params**:
```json
{
  "path": "GPUParticles2D"
}
```

**Expected Result**:
- Response reflects fire preset configuration
- Color gradient, direction, spread should match fire characteristics

**What to check**: Compare the returned values against what `apply_particle_preset` with `"fire"` should set.

---

#### Scenario 3: Get info for non-existent node (error case)

**Params**:
```json
{
  "path": "NonExistentNode"
}
```

**Expected Result**:
- Tool returns an error
- Error indicates node not found

---

#### Scenario 4: Get info for non-particle node (error case)

**Description**: Target a regular node (not a particle system).

**Precondition**: Create a regular node:
```json
{ "parent": "", "name": "MyNode", "type": "Node2D" }
```

**Params**:
```json
{
  "path": "MyNode"
}
```

**Expected Result**:
- Tool returns an error
- Error indicates the node is not a particle system (not `GPUParticles2D` or `GPUParticles3D`)

**What to check**: The tool should validate node type, not just path existence.

---

#### Scenario 5: Get info for 3D particle system

**Precondition**: Create 3D particles and apply a material.

**Params**:
```json
{
  "path": "GPUParticles3D"
}
```

**Expected Result**:
- Returns 3D-specific properties (3D direction vector, 3D emission shape, etc.)

---

### Dependencies

- **Before**: A particle node should exist for meaningful output.
- **After**: Info can be used to verify other tool operations.

---

## Tool: `set_particle_emission_shape`

**Description**: Set the emission shape for a particle system

**Route**: `particles/set_emission_shape`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` | Yes | Particle node path |
| `shape` | `'point' \| 'sphere' \| 'box' \| 'ring'` | Yes | Emission shape type |
| `size` | `number[]` | No | Shape size parameters |

### Test Scenarios

#### Scenario 1: Set point emission (happy path, no size needed)

**Description**: Set emission to point (default, no size required).

**Params**:
```json
{
  "path": "GPUParticles2D",
  "shape": "point"
}
```

**Expected Result**:
- Tool returns success
- Emission shape is set to point (all particles emit from a single point)

**What to check**: Point shape should not require `size`. Verify it works without it.

---

#### Scenario 2: Set sphere emission with size

**Description**: Set sphere emission with a radius.

**Params**:
```json
{
  "path": "GPUParticles3D",
  "shape": "sphere",
  "size": [10.0]
}
```

**Expected Result**:
- Tool returns success
- Emission shape is a sphere with radius 10

**What to check**: For sphere, `size` is typically `[radius]` (1 element). Verify the expected array length.

---

#### Scenario 3: Set box emission with 3D size

**Params**:
```json
{
  "path": "GPUParticles3D",
  "shape": "box",
  "size": [5.0, 10.0, 5.0]
}
```

**Expected Result**:
- Tool returns success
- Emission shape is a box with dimensions 5×10×5

**What to check**: For box shape, `size` is `[x, y, z]`. On 2D particles, it might be `[x, y]`.

---

#### Scenario 4: Set ring emission with size

**Params**:
```json
{
  "path": "GPUParticles3D",
  "shape": "ring",
  "size": [15.0, 2.0]
}
```

**Expected Result**:
- Tool returns success
- Emission shape is a ring with radius 15 and inner radius/height 2

**What to check**: Ring `size` typically means `[radius, height]` or `[outer_radius, inner_radius]`. Document the expected interpretation.

---

#### Scenario 5: Box shape on 2D particles

**Description**: Test box shape with 2D-specific size.

**Params**:
```json
{
  "path": "GPUParticles2D",
  "shape": "box",
  "size": [100.0, 50.0]
}
```

**Expected Result**:
- Tool returns success
- 2D box emission with width 100, height 50

---

#### Scenario 6: Invalid shape name (error case)

**Params**:
```json
{
  "path": "GPUParticles2D",
  "shape": "cone"
}
```

**Expected Result**:
- Validation error indicating `"cone"` is not in `['point', 'sphere', 'box', 'ring']`

---

#### Scenario 7: Shape without size for sphere (edge case)

**Description**: Set sphere shape but omit `size`.

**Params**:
```json
{
  "path": "GPUParticles3D",
  "shape": "sphere"
}
```

**Expected Result**:
- Either: tool uses a default size (e.g., radius 1)
- Or: tool returns an error requiring size for non-point shapes

**What to check**: `size` is optional in the schema. Document whether Godot uses a default when size is omitted for non-point shapes.

---

### Dependencies

- **Before**: A particle node must exist. Use `create_particles` first.
- **After**: Use `get_particle_info` to verify emission shape settings.

---

## Tool: `set_particle_velocity_curve`

**Description**: Set a velocity curve for a particle system

**Route**: `particles/set_velocity_curve`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` | Yes | Particle node path |
| `curve` | `Array<{ offset: number, value: number }>` | Yes | Curve points |

**`offset`**: `z.number().min(0).max(1)` — curve position from 0 to 1
**`value`**: `z.number()` — velocity multiplier at this point (no min/max constraint)

### Test Scenarios

#### Scenario 1: Linear velocity decay (happy path)

**Description**: Velocity starts at full and decays to zero.

**Params**:
```json
{
  "path": "GPUParticles2D",
  "curve": [
    { "offset": 0.0, "value": 1.0 },
    { "offset": 1.0, "value": 0.0 }
  ]
}
```

**Expected Result**:
- Tool returns success
- Particles start at full velocity and slow to a stop

**What to check**: This is the most common pattern — verify the curve is applied correctly.

---

#### Scenario 2: Velocity boost in the middle

**Description**: Particles speed up in the middle of their lifetime.

**Params**:
```json
{
  "path": "GPUParticles2D",
  "curve": [
    { "offset": 0.0, "value": 0.5 },
    { "offset": 0.5, "value": 2.0 },
    { "offset": 1.0, "value": 0.0 }
  ]
}
```

**Expected Result**:
- Tool returns success
- Velocity starts at 0.5×, peaks at 2× mid-life, drops to 0

---

#### Scenario 3: Constant velocity (single point)

**Description**: Single point should produce constant velocity.

**Params**:
```json
{
  "path": "GPUParticles2D",
  "curve": [
    { "offset": 0.0, "value": 1.0 }
  ]
}
```

**Expected Result**:
- Tool returns success
- Constant velocity throughout lifetime

**What to check**: A single point may be interpreted as a flat curve or may need at least 2 points. Document behavior.

---

#### Scenario 4: Negative velocity values (edge case)

**Description**: Velocity goes negative (particles reverse direction).

**Params**:
```json
{
  "path": "GPUParticles2D",
  "curve": [
    { "offset": 0.0, "value": 1.0 },
    { "offset": 0.5, "value": -0.5 },
    { "offset": 1.0, "value": 0.0 }
  ]
}
```

**Expected Result**:
- Tool returns success (Godot allows negative velocity in curves)
- Particles reverse direction mid-lifetime

**What to check**: Negative values are valid in Godot velocity curves — the schema has no `min(0)` on `value`.

---

#### Scenario 5: Offset out of range (error case)

**Params**:
```json
{
  "path": "GPUParticles2D",
  "curve": [
    { "offset": -0.1, "value": 1.0 },
    { "offset": 1.1, "value": 0.0 }
  ]
}
```

**Expected Result**:
- Validation error indicating offset must be 0-1

---

#### Scenario 6: Empty curve array (edge case)

**Params**:
```json
{
  "path": "GPUParticles2D",
  "curve": []
}
```

**Expected Result**:
- Either: error (empty curve invalid)
- Or: success with default velocity behavior

**What to check**: Document whether an empty array is accepted or rejected.

---

#### Scenario 7: Unsorted offsets (edge case)

**Description**: Pass offsets in non-ascending order.

**Params**:
```json
{
  "path": "GPUParticles2D",
  "curve": [
    { "offset": 1.0, "value": 0.0 },
    { "offset": 0.0, "value": 1.0 }
  ]
}
```

**Expected Result**:
- Either: tool sorts them automatically
- Or: tool rejects unsorted input
- Or: Godot handles the order as-is

**What to check**: This is important to document — does the tool expect sorted input?

---

### Dependencies

- **Before**: A particle node must exist. Use `create_particles` first.
- **After**: Use `get_particle_info` to verify velocity curve was applied.

---

## Full Lifecycle Test Sequence

To test all tools in a realistic workflow:

### Step 1: Create particle node
```json
{ "tool": "create_particles", "params": { "parent": "", "type": "2d" } }
```
→ Save returned node path (assume `"GPUParticles2D"`)

### Step 2: Set material
```json
{ "tool": "set_particle_material", "params": {
  "path": "GPUParticles2D",
  "properties": {
    "direction": [0, -1],
    "spread": 10.0,
    "gravity": [0, 98],
    "initial_velocity_min": 50.0,
    "initial_velocity_max": 100.0
  }
}}
```

### Step 3: Set color gradient
```json
{ "tool": "set_particle_color_gradient", "params": {
  "path": "GPUParticles2D",
  "gradient": [
    { "offset": 0.0, "color": "#FF4400FF" },
    { "offset": 0.5, "color": "#FF880088" },
    { "offset": 1.0, "color": "#FF000000" }
  ]
}}
```

### Step 4: Set emission shape
```json
{ "tool": "set_particle_emission_shape", "params": {
  "path": "GPUParticles2D",
  "shape": "sphere",
  "size": [5.0]
}}
```

### Step 5: Set velocity curve
```json
{ "tool": "set_particle_velocity_curve", "params": {
  "path": "GPUParticles2D",
  "curve": [
    { "offset": 0.0, "value": 1.0 },
    { "offset": 1.0, "value": 0.2 }
  ]
}}
```

### Step 6: Verify configuration
```json
{ "tool": "get_particle_info", "params": { "path": "GPUParticles2D" } }
```
→ Verify all properties from steps 2-5 are reflected

### Step 7: Apply preset (overwrites manual config)
```json
{ "tool": "apply_particle_preset", "params": {
  "path": "GPUParticles2D",
  "preset": "fire"
}}
```

### Step 8: Verify preset applied
```json
{ "tool": "get_particle_info", "params": { "path": "GPUParticles2D" } }
```
→ Properties should now reflect fire preset, not manual config

### Step 9: Clean up
```json
{ "tool": "delete_particles", "params": { "node_path": "GPUParticles2D" } }
```

---

## Tool Call Order Summary

| Order | Tool | Depends On |
|-------|------|------------|
| 1 | `create_particles` | None (or parent node must exist) |
| 2 | `set_particle_material` | `create_particles` |
| 3 | `set_particle_color_gradient` | `create_particles` |
| 4 | `set_particle_emission_shape` | `create_particles` |
| 5 | `set_particle_velocity_curve` | `create_particles` |
| 6 | `get_particle_info` | `create_particles` (read-only) |
| 7 | `apply_particle_preset` | `create_particles` |
| 8 | `delete_particles` | `create_particles` (last in lifecycle) |

> **Note**: Tools 2-7 are independent of each other and can be called in any order after creation. Only `delete_particles` must be last.
