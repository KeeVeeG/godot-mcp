# Physics Tools Test Plan

**Source file:** `server/src/tools/physics.ts`
**Godot bridge method prefix:** `physics/`
**Shared schemas used:** `NodePath`, `ParentPath`, `Properties`, `OptionalProperties` (from `shared-types.ts`)
**Handler pattern:** All tools call `callGodot(bridge, 'physics/<action>', args)`

---

## Shared Type Definitions

| Schema | Type | Constraints |
|--------|------|-------------|
| `NodePath` | `string` | Path in scene tree, e.g. `"Player/Sprite2D"`, `""` for root |
| `ParentPath` | `string` | Parent node path. `""` for scene root, or `"Player"` / `"Player/Sprites"` for children |
| `Properties` | `Record<string, unknown>` (required) | Property key-value pairs — must be present (can be `{}`) |
| `OptionalProperties` | `Record<string, unknown>` (optional) | Property key-value pairs — may be omitted entirely |

---

## Tool: `setup_physics_body`

**Handler:** `callGodot(bridge, 'physics/setup_body', args)`
**Description:** Add and configure a physics body on a node

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | **Yes** | Node to add the physics body to |
| `properties` | `Properties` (`Record<string, unknown>`) | **Yes** | Body properties (mass, gravity_scale, etc.) |

### Test Scenarios

#### Scenario 1: Happy path — add a rigid body with mass
- **Description:** Add a physics body to a valid node with a mass property
- **Params:** `{ "path": "Player", "properties": { "mass": 2.0, "gravity_scale": 1.0 } }`
- **Expected result:** Success response. Physics body added to the node with specified properties.
- **Notes:** Prerequisite: a node named `Player` exists in the current scene.

#### Scenario 2: Happy path — minimal properties (empty object)
- **Description:** Add a physics body with an empty properties object (relying on defaults)
- **Params:** `{ "path": "Player", "properties": {} }`
- **Expected result:** Success response. Physics body added with default properties.
- **Notes:** Tests that `properties: {}` is valid (Properties schema accepts any record, including empty).

#### Scenario 3: Happy path — path to scene root
- **Description:** Add a physics body to the scene root using empty string path
- **Params:** `{ "path": "", "properties": { "mass": 5.0 } }`
- **Expected result:** Success response (if scene root node supports a physics body). May error if root node type is incompatible.
- **Notes:** Tests that `""` is a valid NodePath per the schema.

#### Scenario 4: Happy path — nested node path
- **Description:** Add a physics body to a nested node using `"Parent/Child"` syntax
- **Params:** `{ "path": "Player/Sprite2D", "properties": { "mass": 1.0 } }`
- **Expected result:** Success response (if the child node supports a physics body).
- **Notes:** Prerequisite: scene has a node at path `Player/Sprite2D`.

#### Scenario 5: Missing required parameter — `path`
- **Description:** Omit `path` entirely
- **Params:** `{ "properties": { "mass": 2.0 } }`
- **Expected result:** Zod validation error. The call does not reach the Godot bridge.
- **Notes:** Tests that `path` is required.

#### Scenario 6: Missing required parameter — `properties`
- **Description:** Omit `properties` entirely
- **Params:** `{ "path": "Player" }`
- **Expected result:** Zod validation error. The call does not reach the Godot bridge.
- **Notes:** Tests that `properties` is required.

#### Scenario 7: Missing both required parameters
- **Description:** Omit both `path` and `properties`
- **Params:** `{}`
- **Expected result:** Zod validation error for both missing fields.

#### Scenario 8: Non-existent node path
- **Description:** Call with a path that does not exist in the current scene
- **Params:** `{ "path": "NonExistentNode", "properties": { "mass": 1.0 } }`
- **Expected result:** Error response from Godot indicating node not found.

#### Scenario 9: Properties with unexpected keys
- **Description:** Send properties with keys that the body may not recognize
- **Params:** `{ "path": "Player", "properties": { "nonexistent_prop": "hello", "another_fake": 42 } }`
- **Expected result:** Either success (Godot may ignore unknown properties) or a warning. Not a Zod error.
- **Notes:** Tests server tolerance for unknown property keys — schema is `z.record(z.unknown())`, so no validation on keys.

#### Scenario 10: Properties with null values
- **Description:** Send a property value of `null`
- **Params:** `{ "path": "Player", "properties": { "mass": null } }`
- **Expected result:** Behavior depends on whether Godot handles `null` for the property. Either applies null or errors.
- **Notes:** `z.unknown()` accepts `null`.

---

## Tool: `setup_collision`

**Handler:** `callGodot(bridge, 'physics/setup_collision', args)`
**Description:** Add and configure a collision shape on a node

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | **Yes** | Node to add collision to |
| `shape_type` | `enum: "box" \| "sphere" \| "capsule" \| "cylinder" \| "convex" \| "concave" \| "polygon" \| "circle" \| "rectangle"` | **Yes** | Collision shape type |
| `properties` | `OptionalProperties` (`Record<string, unknown>`, optional) | No | Shape properties (size, radius, height, etc.) |

### Test Scenarios

#### Scenario 1: Happy path — box shape, no properties
- **Description:** Add a box collision shape with only required params
- **Params:** `{ "path": "Player", "shape_type": "box" }`
- **Expected result:** Success response. Box collision shape added with defaults.
- **Notes:** `properties` is optional and omitted here.

#### Scenario 2: Happy path — box shape with explicit size
- **Description:** Add a box collision shape with custom size properties
- **Params:** `{ "path": "Player", "shape_type": "box", "properties": { "size": [1, 2, 3] } }`
- **Expected result:** Success response. Box collision shape with specified size.

#### Scenario 3: Enum value — "sphere"
- **Description:** Add a sphere collision shape
- **Params:** `{ "path": "Player", "shape_type": "sphere", "properties": { "radius": 1.5 } }`
- **Expected result:** Success response.

#### Scenario 4: Enum value — "capsule"
- **Description:** Add a capsule collision shape
- **Params:** `{ "path": "Player", "shape_type": "capsule", "properties": { "radius": 0.5, "height": 2.0 } }`
- **Expected result:** Success response.

#### Scenario 5: Enum value — "cylinder"
- **Description:** Add a cylinder collision shape
- **Params:** `{ "path": "Player", "shape_type": "cylinder", "properties": { "radius": 0.5, "height": 2.0 } }`
- **Expected result:** Success response.

#### Scenario 6: Enum value — "convex"
- **Description:** Add a convex collision shape
- **Params:** `{ "path": "Player", "shape_type": "convex" }`
- **Expected result:** Success response. Note: convex shapes typically require a mesh.

#### Scenario 7: Enum value — "concave"
- **Description:** Add a concave collision shape
- **Params:** `{ "path": "Player", "shape_type": "concave" }`
- **Expected result:** Success response. Note: concave shapes typically require a mesh.

#### Scenario 8: Enum value — "polygon"
- **Description:** Add a polygon collision shape
- **Params:** `{ "path": "Player", "shape_type": "polygon" }`
- **Expected result:** Success response.

#### Scenario 9: Enum value — "circle"
- **Description:** Add a circle collision shape (2D)
- **Params:** `{ "path": "Player", "shape_type": "circle", "properties": { "radius": 32.0 } }`
- **Expected result:** Success response.

#### Scenario 10: Enum value — "rectangle"
- **Description:** Add a rectangle collision shape (2D)
- **Params:** `{ "path": "Player", "shape_type": "rectangle", "properties": { "size": [64, 64] } }`
- **Expected result:** Success response.

#### Scenario 11: Invalid enum value
- **Description:** Provide a shape_type that is not in the enum
- **Params:** `{ "path": "Player", "shape_type": "triangle" }`
- **Expected result:** Zod validation error. `"triangle"` is not a valid enum member.
- **Notes:** The enum is `['box', 'sphere', 'capsule', 'cylinder', 'convex', 'concave', 'polygon', 'circle', 'rectangle']`.

#### Scenario 12: Invalid enum value — empty string
- **Description:** Provide an empty string for shape_type
- **Params:** `{ "path": "Player", "shape_type": "" }`
- **Expected result:** Zod validation error. Empty string is not a valid enum member.

#### Scenario 13: Missing required parameter — `path`
- **Description:** Omit `path`
- **Params:** `{ "shape_type": "box" }`
- **Expected result:** Zod validation error.

#### Scenario 14: Missing required parameter — `shape_type`
- **Description:** Omit `shape_type`
- **Params:** `{ "path": "Player" }`
- **Expected result:** Zod validation error.

#### Scenario 15: Non-existent node path
- **Description:** Call with a path that does not exist
- **Params:** `{ "path": "GhostNode", "shape_type": "box" }`
- **Expected result:** Error response from Godot.

#### Scenario 16: Properties with empty object
- **Description:** Provide an explicit empty properties object
- **Params:** `{ "path": "Player", "shape_type": "sphere", "properties": {} }`
- **Expected result:** Success response. Same as omitting properties.

---

## Tool: `set_physics_layers`

**Handler:** `callGodot(bridge, 'physics/set_layers', args)`
**Description:** Set physics collision layers and masks on a node

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | **Yes** | Node with collision object |
| `layer` | `number` (integer, 1–32) | No | Collision layer (1-32) |
| `mask` | `number` (integer, 1–32) | No | Collision mask (1-32) |

### Test Scenarios

#### Scenario 1: Happy path — set only layer
- **Description:** Set the collision layer on a valid node
- **Params:** `{ "path": "Player", "layer": 1 }`
- **Expected result:** Success response. Collision layer set to 1.

#### Scenario 2: Happy path — set only mask
- **Description:** Set the collision mask on a valid node
- **Params:** `{ "path": "Player", "mask": 1 }`
- **Expected result:** Success response. Collision mask set to 1.

#### Scenario 3: Happy path — set both layer and mask
- **Description:** Set both collision layer and mask simultaneously
- **Params:** `{ "path": "Player", "layer": 2, "mask": 5 }`
- **Expected result:** Success response. Both layer and mask updated.

#### Scenario 4: Happy path — neither layer nor mask (just path)
- **Description:** Call with only `path` — both optional params omitted
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success response (though the Godot bridge may do nothing or return current values).
- **Notes:** Both `layer` and `mask` are optional. This is a valid call.

#### Scenario 5: Boundary — layer = 1 (minimum)
- **Description:** Set layer to the minimum valid value
- **Params:** `{ "path": "Player", "layer": 1 }`
- **Expected result:** Success response.

#### Scenario 6: Boundary — layer = 32 (maximum)
- **Description:** Set layer to the maximum valid value
- **Params:** `{ "path": "Player", "layer": 32 }`
- **Expected result:** Success response.

#### Scenario 7: Boundary — mask = 1 (minimum)
- **Description:** Set mask to the minimum valid value
- **Params:** `{ "path": "Player", "mask": 1 }`
- **Expected result:** Success response.

#### Scenario 8: Boundary — mask = 32 (maximum)
- **Description:** Set mask to the maximum valid value
- **Params:** `{ "path": "Player", "mask": 32 }`
- **Expected result:** Success response.

#### Scenario 9: Edge case — layer = 0 (below minimum)
- **Description:** Set layer to 0, which violates `min(1)`
- **Params:** `{ "path": "Player", "layer": 0 }`
- **Expected result:** Zod validation error. `z.number().min(1)` rejects 0.

#### Scenario 10: Edge case — layer = 33 (above maximum)
- **Description:** Set layer to 33, which violates `max(32)`
- **Params:** `{ "path": "Player", "layer": 33 }`
- **Expected result:** Zod validation error. `z.number().max(32)` rejects 33.

#### Scenario 11: Edge case — layer = -1 (negative)
- **Description:** Set layer to a negative number
- **Params:** `{ "path": "Player", "layer": -1 }`
- **Expected result:** Zod validation error. `z.number().min(1)` rejects negatives.

#### Scenario 12: Edge case — non-integer layer value
- **Description:** Set layer to a float (1.5)
- **Params:** `{ "path": "Player", "layer": 1.5 }`
- **Expected result:** Zod validation error. `z.number().int()` rejects non-integers.

#### Scenario 13: Edge case — mask = 0 (below minimum)
- **Description:** Set mask to 0
- **Params:** `{ "path": "Player", "mask": 0 }`
- **Expected result:** Zod validation error.

#### Scenario 14: Edge case — mask = 33 (above maximum)
- **Description:** Set mask to 33
- **Params:** `{ "path": "Player", "mask": 33 }`
- **Expected result:** Zod validation error.

#### Scenario 15: Edge case — mask as float
- **Description:** Set mask to a non-integer value
- **Params:** `{ "path": "Player", "mask": 2.7 }`
- **Expected result:** Zod validation error.

#### Scenario 16: Missing required parameter — `path`
- **Description:** Omit `path`
- **Params:** `{ "layer": 1 }`
- **Expected result:** Zod validation error.

#### Scenario 17: Non-existent node path
- **Description:** Call with a path that does not exist
- **Params:** `{ "path": "FakeNode", "layer": 1 }`
- **Expected result:** Error response from Godot.

#### Scenario 18: Path to a node without collision object
- **Description:** Call on a node that has no collision object
- **Params:** `{ "path": "Camera3D", "layer": 1 }`
- **Expected result:** Error response from Godot indicating the node has no collision object.

---

## Tool: `get_physics_layers`

**Handler:** `callGodot(bridge, 'physics/get_layers', args)`
**Description:** Get physics layer and mask information for a node

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | **Yes** | Node with collision object |

### Test Scenarios

#### Scenario 1: Happy path — get layers on a physics body node
- **Description:** Retrieve physics layer info from a node that has a collision object
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success response. JSON with `layer` and `mask` values (integers 1–32).
- **Notes:** Prerequisite: node has a physics body with collision.

#### Scenario 2: Happy path — scene root
- **Description:** Query the scene root for physics layer info
- **Params:** `{ "path": "" }`
- **Expected result:** Success (if root has a collision object) or error (if not).

#### Scenario 3: Missing required parameter — `path`
- **Description:** Omit `path`
- **Params:** `{}`
- **Expected result:** Zod validation error.

#### Scenario 4: Non-existent node path
- **Description:** Call with a path that does not exist
- **Params:** `{ "path": "MissingNode" }`
- **Expected result:** Error response from Godot.

#### Scenario 5: Node without collision object
- **Description:** Call on a node that has no collision object
- **Params:** `{ "path": "Sprite2D" }`
- **Expected result:** Error response from Godot indicating no collision object found on the node.

---

## Tool: `get_collision_info`

**Handler:** `callGodot(bridge, 'physics/get_collision_info', args)`
**Description:** Get collision information for a physics body

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | **Yes** | Physics body node path |

### Test Scenarios

#### Scenario 1: Happy path — get info on a valid physics body
- **Description:** Retrieve collision information from a node that has a physics body
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success response. JSON containing collision shape details (type, dimensions, etc.).
- **Notes:** Prerequisite: node has a physics body with a collision shape.

#### Scenario 2: Happy path — nested node path
- **Description:** Query a nested node with a physics body
- **Params:** `{ "path": "Enemies/Enemy1" }`
- **Expected result:** Success response with collision info.

#### Scenario 3: Missing required parameter — `path`
- **Description:** Omit `path`
- **Params:** `{}`
- **Expected result:** Zod validation error.

#### Scenario 4: Non-existent node path
- **Description:** Call with a non-existent path
- **Params:** `{ "path": "GhostBody" }`
- **Expected result:** Error response from Godot.

#### Scenario 5: Node without physics body
- **Description:** Call on a node that has no physics body
- **Params:** `{ "path": "Label" }`
- **Expected result:** Error response from Godot indicating no physics body found.

#### Scenario 6: Scene root as path
- **Description:** Query scene root
- **Params:** `{ "path": "" }`
- **Expected result:** Success (if root has a physics body) or error (if not).

---

## Tool: `add_raycast`

**Handler:** `callGodot(bridge, 'physics/add_raycast', args)`
**Description:** Add a RayCast2D or RayCast3D node

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `parent_path` | `ParentPath` (string) | **Yes** | Parent node — `""` for scene root |
| `properties` | `OptionalProperties` (`Record<string, unknown>`, optional) | No | Raycast properties (target, enabled, collide_with_areas, etc.) |

### Test Scenarios

#### Scenario 1: Happy path — add raycast to scene root
- **Description:** Add a raycast node at the scene root with no properties
- **Params:** `{ "parent_path": "" }`
- **Expected result:** Success response. Raycast node created as a child of the scene root.

#### Scenario 2: Happy path — add raycast to a named node
- **Description:** Add a raycast as a child of an existing node
- **Params:** `{ "parent_path": "Player" }`
- **Expected result:** Success response. Raycast node added as child of `Player`.

#### Scenario 3: Happy path — with target position property
- **Description:** Add a raycast with a target position
- **Params:** `{ "parent_path": "Player", "properties": { "target_position": [0, -100, 0] } }`
- **Expected result:** Success response. Raycast created with the specified target.

#### Scenario 4: Happy path — with enabled property
- **Description:** Add a raycast that is enabled
- **Params:** `{ "parent_path": "Player", "properties": { "enabled": true } }`
- **Expected result:** Success response. Raycast created and enabled.

#### Scenario 5: Happy path — with collide_with_areas property
- **Description:** Add a raycast with collide_with_areas enabled
- **Params:** `{ "parent_path": "Player", "properties": { "collide_with_areas": true, "collide_with_bodies": false } }`
- **Expected result:** Success response.

#### Scenario 6: Happy path — with empty properties object
- **Description:** Add a raycast with an explicit empty properties
- **Params:** `{ "parent_path": "", "properties": {} }`
- **Expected result:** Success response. Same as omitting properties.

#### Scenario 7: Happy path — nested parent path
- **Description:** Add a raycast to a nested parent
- **Params:** `{ "parent_path": "Player/Weapon", "properties": { "target_position": [0, 0, -10] } }`
- **Expected result:** Success response.

#### Scenario 8: Missing required parameter — `parent_path`
- **Description:** Omit `parent_path`
- **Params:** `{}`
- **Expected result:** Zod validation error.

#### Scenario 9: Non-existent parent path
- **Description:** Call with a parent path that does not exist
- **Params:** `{ "parent_path": "NonExistentParent" }`
- **Expected result:** Error response from Godot.

#### Scenario 10: Properties with invalid types
- **Description:** Send a property with a string where a vector is expected
- **Params:** `{ "parent_path": "Player", "properties": { "target_position": "not-a-vector" } }`
- **Expected result:** Error response from Godot (type mismatch on the Godot side). Not a Zod error since `z.record(z.unknown())` accepts strings.
- **Notes:** Tests that Godot validates property types at runtime.

---

## Tool: `get_physics_material`

**Handler:** `callGodot(bridge, 'physics/get_material', args)`
**Description:** Get the physics material properties of a node

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | **Yes** | Node path in the scene tree |

- **Note:** This tool uses the raw `NodePath` schema directly (not wrapped with `.describe()`). It is the same type (`z.string()` with the shared description text) but referenced as an object rather than inline. The schema is functionally identical.

### Test Scenarios

#### Scenario 1: Happy path — get material on a node with physics body
- **Description:** Retrieve physics material properties from a node that has a physics body with a material
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success response. JSON with material properties (friction, bounce, etc.).
- **Notes:** Prerequisite: node has a physics body with an assigned physics material.

#### Scenario 2: Happy path — node with physics body but no material assigned
- **Description:** Query a node that has a physics body without an explicit material
- **Params:** `{ "path": "Floor" }`
- **Expected result:** Either default material values or an error/empty response.
- **Notes:** Behavior depends on Godot's handling of unassigned materials.

#### Scenario 3: Missing required parameter — `path`
- **Description:** Omit `path`
- **Params:** `{}`
- **Expected result:** Zod validation error.

#### Scenario 4: Non-existent node path
- **Description:** Call with a path that does not exist
- **Params:** `{ "path": "PhantomNode" }`
- **Expected result:** Error response from Godot.

#### Scenario 5: Node without collision object
- **Description:** Call on a node that has no collision object or physics body
- **Params:** `{ "path": "UI/TitleLabel" }`
- **Expected result:** Error response from Godot.

#### Scenario 6: Scene root path
- **Description:** Query scene root for physics material
- **Params:** `{ "path": "" }`
- **Expected result:** Success (if root has a collision body with material) or error (if not).

---

## Tool: `set_physics_material`

**Handler:** `callGodot(bridge, 'physics/set_material', args)`
**Description:** Create and set a physics material on a node

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | **Yes** | Node path in the scene tree |
| `friction` | `number` (>= 0) | No | Friction coefficient |
| `bounce` | `number` (>= 0, <= 1) | No | Bounce/Restitution coefficient |
| `rough` | `boolean` | No | Whether surface is rough |
| `absorbent` | `boolean` | No | Whether the surface absorbs impact energy |

- **Note:** Like `get_physics_material`, this uses the raw `NodePath` schema directly.

### Test Scenarios

#### Scenario 1: Happy path — set friction only
- **Description:** Set only the friction coefficient on a node's physics material
- **Params:** `{ "path": "Player", "friction": 0.5 }`
- **Expected result:** Success response. Physics material created/updated with friction = 0.5.

#### Scenario 2: Happy path — set bounce only
- **Description:** Set only the bounce coefficient
- **Params:** `{ "path": "Player", "bounce": 0.8 }`
- **Expected result:** Success response. Material updated with bounce = 0.8.

#### Scenario 3: Happy path — set rough flag only
- **Description:** Set the rough flag to true
- **Params:** `{ "path": "Player", "rough": true }`
- **Expected result:** Success response. Material marked as rough.

#### Scenario 4: Happy path — set absorbent flag only
- **Description:** Set the absorbent flag to true
- **Params:** `{ "path": "Player", "absorbent": true }`
- **Expected result:** Success response. Material marked as absorbent.

#### Scenario 5: Happy path — set all four properties
- **Description:** Set friction, bounce, rough, and absorbent simultaneously
- **Params:** `{ "path": "Floor", "friction": 1.0, "bounce": 0.1, "rough": true, "absorbent": false }`
- **Expected result:** Success response. All four material properties applied.

#### Scenario 6: Happy path — friction = 0 (boundary minimum)
- **Description:** Set friction to 0 (frictionless surface)
- **Params:** `{ "path": "Ice", "friction": 0 }`
- **Expected result:** Success response. Material set with friction = 0.

#### Scenario 7: Happy path — bounce = 0 (boundary minimum, no bounce)
- **Description:** Set bounce to 0 (fully inelastic)
- **Params:** `{ "path": "Player", "bounce": 0 }`
- **Expected result:** Success response. Material set with bounce = 0.

#### Scenario 8: Happy path — bounce = 1 (boundary maximum, perfect bounce)
- **Description:** Set bounce to 1 (perfectly elastic)
- **Params:** `{ "path": "Player", "bounce": 1 }`
- **Expected result:** Success response. Material set with bounce = 1.

#### Scenario 9: Edge case — friction < 0 (negative)
- **Description:** Set friction to a negative number
- **Params:** `{ "path": "Player", "friction": -0.5 }`
- **Expected result:** Zod validation error. `z.number().min(0)` rejects negative values.

#### Scenario 10: Edge case — bounce < 0 (negative)
- **Description:** Set bounce to a negative number
- **Params:** `{ "path": "Player", "bounce": -0.1 }`
- **Expected result:** Zod validation error. `z.number().min(0)` rejects negative values.

#### Scenario 11: Edge case — bounce > 1
- **Description:** Set bounce above the maximum
- **Params:** `{ "path": "Player", "bounce": 1.5 }`
- **Expected result:** Zod validation error. `z.number().max(1)` rejects values > 1.

#### Scenario 12: Edge case — rough = false
- **Description:** Explicitly set rough to false
- **Params:** `{ "path": "Player", "rough": false }`
- **Expected result:** Success response. Material not marked as rough.

#### Scenario 13: Edge case — absorbent = false
- **Description:** Explicitly set absorbent to false
- **Params:** `{ "path": "Player", "absorbent": false }`
- **Expected result:** Success response. Material not marked as absorbent.

#### Scenario 14: Edge case — non-boolean for rough
- **Description:** Pass a string for the `rough` parameter
- **Params:** `{ "path": "Player", "rough": "yes" }`
- **Expected result:** Zod validation error. `z.boolean()` rejects strings.

#### Scenario 15: Edge case — non-boolean for absorbent
- **Description:** Pass a number for the `absorbent` parameter
- **Params:** `{ "path": "Player", "absorbent": 1 }`
- **Expected result:** Zod validation error. `z.boolean()` rejects numbers.

#### Scenario 16: Missing required parameter — `path`
- **Description:** Omit `path` entirely
- **Params:** `{ "friction": 0.5 }`
- **Expected result:** Zod validation error.

#### Scenario 17: Non-existent node path
- **Description:** Call with a path that does not exist
- **Params:** `{ "path": "NowhereNode", "friction": 0.3 }`
- **Expected result:** Error response from Godot.

#### Scenario 18: Node without collision object
- **Description:** Try to set material on a node without a collision body
- **Params:** `{ "path": "Camera3D", "friction": 0.5 }`
- **Expected result:** Error response from Godot (no collision body to assign material to).

#### Scenario 19: Friction as float within range
- **Description:** Set friction to a fractional value
- **Params:** `{ "path": "Player", "friction": 0.75 }`
- **Expected result:** Success response. `z.number()` accepts floats.

#### Scenario 20: Bounce = 0.5 (mid-range)
- **Description:** Set bounce to a mid-range value
- **Params:** `{ "path": "Player", "bounce": 0.5 }`
- **Expected result:** Success response.

#### Scenario 21: All optional params omitted
- **Description:** Call with only `path` — no material properties specified
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success response. Material created with defaults (or existing material left unchanged).
- **Notes:** All four property params are optional. This is a valid call.

---

## Cross-Tool Workflow Test Scenarios

These scenarios test multiple tools in sequence to verify the full physics setup workflow.

### Workflow 1: Full physics body → collision → layers → material pipeline

1. **Setup physics body:** `{ "path": "Player", "properties": { "mass": 2.0 } }` → success
2. **Setup collision box:** `{ "path": "Player", "shape_type": "box", "properties": { "size": [1, 2, 1] } }` → success
3. **Set physics layers:** `{ "path": "Player", "layer": 1, "mask": 2 }` → success
4. **Get physics layers:** `{ "path": "Player" }` → should return `layer: 1, mask: 2`
5. **Set physics material:** `{ "path": "Player", "friction": 0.6, "bounce": 0.3 }` → success
6. **Get physics material:** `{ "path": "Player" }` → should return `friction: 0.6, bounce: 0.3`
7. **Get collision info:** `{ "path": "Player" }` → should confirm box shape with size [1, 2, 1]

### Workflow 2: Raycast setup on empty scene
1. **Add raycast to root:** `{ "parent_path": "" }` → success
2. **Add raycast to root with properties:** `{ "parent_path": "", "properties": { "enabled": true, "target_position": [0, -10, 0] } }` → success

---

## Summary

| Tool | Required Params | Optional Params | Enum Values | Numeric Constraints |
|------|----------------|-----------------|-------------|---------------------|
| `setup_physics_body` | `path`, `properties` | — | — | — |
| `setup_collision` | `path`, `shape_type` | `properties` | 9 values (box, sphere, capsule, cylinder, convex, concave, polygon, circle, rectangle) | — |
| `set_physics_layers` | `path` | `layer`, `mask` | — | layer/mask: int, 1–32 |
| `get_physics_layers` | `path` | — | — | — |
| `get_collision_info` | `path` | — | — | — |
| `add_raycast` | `parent_path` | `properties` | — | — |
| `get_physics_material` | `path` | — | — | — |
| `set_physics_material` | `path` | `friction`, `bounce`, `rough`, `absorbent` | — | friction: >= 0, bounce: 0–1 |

**Total tools:** 8
**Total test scenarios:** 73+
