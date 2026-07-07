# Physics Tools — Test Plan

**Source file:** `server/src/tools/physics.ts`
**Shared types:** `server/src/tools/shared-types.ts`
**Number of tools:** 8
**Generated:** 2026-07-08

---

## Type Reference

| Zod schema | Underlying type | Description |
|---|---|---|
| `NodePath` | `z.string()` | Node path in scene tree, e.g. `'Player/Sprite2D'`, `''` for root |
| `ParentPath` | `z.string()` | Parent node path, `''` for scene root, or `'Player'` for root-level child |
| `Properties` | `z.record(z.unknown())` | **Required** property key-value pairs dict |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | Optional property key-value pairs dict |

---

## Tool: `setup_physics_body`

**Description:** Add and configure a physics body on a node
**Handler:** `callGodot(bridge, 'physics/setup_body', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node to add the physics body to |
| `properties` | `Properties` (record) | **Yes** | — | Body properties (mass, gravity_scale, etc.) |

### Test Scenarios

#### Scenario 1: Happy path — add body with mass and gravity_scale
- **Description:** Add a physics body to a node with mass and gravity_scale properties
- **Params:** `{ "path": "Player", "properties": { "mass": 5.0, "gravity_scale": 1.0 } }`
- **Expected result:** Success. Physics body added to the "Player" node with configured properties.

#### Scenario 2: Happy path — add body with minimal properties
- **Description:** Add a physics body with an empty properties object
- **Params:** `{ "path": "Enemy", "properties": {} }`
- **Expected result:** Success. Physics body added with default property values.

#### Scenario 3: Happy path — add body to scene root (empty string)
- **Description:** Add a physics body to the scene root node
- **Params:** `{ "path": "", "properties": { "mass": 1.0 } }`
- **Expected result:** Success. Physics body added to scene root.

#### Scenario 4: Happy path — add body with many properties
- **Description:** Add a physics body with a full set of properties
- **Params:** `{ "path": "RigidBody", "properties": { "mass": 10.0, "gravity_scale": 0.5, "linear_damp": 0.1, "angular_damp": 0.1, "can_sleep": true, "lock_rotation": false } }`
- **Expected result:** Success. All specified properties are applied to the body.

#### Scenario 5: Happy path — add body to nested node
- **Description:** Add a physics body to a deeply nested node
- **Params:** `{ "path": "Parent/Child/Grandchild", "properties": { "mass": 2.0 } }`
- **Expected result:** Success if the node exists at that path; error otherwise.

#### Scenario 6: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{ "properties": { "mass": 1.0 } }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 7: Edge — missing `properties`
- **Description:** Call without the required `properties` parameter
- **Params:** `{ "path": "Player" }`
- **Expected result:** Zod validation error (properties is required).

#### Scenario 8: Edge — node does not exist
- **Description:** Add a physics body to a non-existent node
- **Params:** `{ "path": "NonExistentNodeXYZ", "properties": { "mass": 1.0 } }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 9: Edge — node already has a physics body
- **Description:** Call on a node that already has a physics body attached
- **Params:** `{ "path": "Player", "properties": { "mass": 3.0 } }`
- **Expected result:** Behavior depends on Godot implementation — may replace or error.
- **Notes:** Run after Scenario 1.

#### Scenario 10: Edge — invalid property name
- **Description:** Pass a property name that does not exist on the physics body
- **Params:** `{ "path": "Player", "properties": { "nonexistent_prop": 999 } }`
- **Expected result:** May succeed (property ignored) or Godot returns an error.

#### Scenario 11: Edge — negative mass
- **Description:** Set mass to a negative value
- **Params:** `{ "path": "Player", "properties": { "mass": -5.0 } }`
- **Expected result:** May be accepted by Zod (no validation on property values). Godot may clamp or error.

---

## Tool: `setup_collision`

**Description:** Add and configure a collision shape on a node
**Handler:** `callGodot(bridge, 'physics/setup_collision', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node to add collision to |
| `shape_type` | enum string | **Yes** | — | Collision shape type: `box`, `sphere`, `capsule`, `cylinder`, `convex`, `concave`, `polygon`, `circle`, `rectangle` |
| `properties` | `OptionalProperties` (record) | No | — | Shape properties (size, radius, height, etc.) |

### Test Scenarios

#### Scenario 1: Happy path — shape_type = `box`
- **Description:** Add a box collision shape to a node
- **Params:** `{ "path": "Player", "shape_type": "box" }`
- **Expected result:** Success. A box-shaped CollisionShape (or CollisionShape3D) is added.

#### Scenario 2: shape_type = `box` with size property
- **Description:** Add a box collision with explicit size
- **Params:** `{ "path": "Player", "shape_type": "box", "properties": { "size": [2.0, 1.0, 3.0] } }`
- **Expected result:** Success. Box collision created with the specified extents.

#### Scenario 3: shape_type = `sphere`
- **Description:** Add a sphere collision shape
- **Params:** `{ "path": "Player", "shape_type": "sphere", "properties": { "radius": 1.5 } }`
- **Expected result:** Success. Sphere collision created with radius 1.5.

#### Scenario 4: shape_type = `capsule`
- **Description:** Add a capsule collision shape
- **Params:** `{ "path": "Player", "shape_type": "capsule", "properties": { "radius": 0.5, "height": 2.0 } }`
- **Expected result:** Success. Capsule collision created with specified dimensions.

#### Scenario 5: shape_type = `cylinder`
- **Description:** Add a cylinder collision shape
- **Params:** `{ "path": "Player", "shape_type": "cylinder", "properties": { "radius": 1.0, "height": 3.0 } }`
- **Expected result:** Success. Cylinder collision created.

#### Scenario 6: shape_type = `convex`
- **Description:** Add a convex collision shape
- **Params:** `{ "path": "Player", "shape_type": "convex" }`
- **Expected result:** Success. Convex collision shape added (typically from mesh or auto-generated).
- **Notes:** Requires a MeshInstance child or sibling for the convex shape to reference.

#### Scenario 7: shape_type = `concave`
- **Description:** Add a concave (trimesh) collision shape
- **Params:** `{ "path": "Player", "shape_type": "concave" }`
- **Expected result:** Success. Concave collision shape created.
- **Notes:** Typically used with StaticBody for terrain/level geometry.

#### Scenario 8: shape_type = `polygon`
- **Description:** Add a polygon collision shape (2D)
- **Params:** `{ "path": "Sprite2D", "shape_type": "polygon" }`
- **Expected result:** Success. Polygon-shaped CollisionPolygon2D added.
- **Notes:** Requires a 2D node context.

#### Scenario 9: shape_type = `circle`
- **Description:** Add a circle collision shape (2D)
- **Params:** `{ "path": "Sprite2D", "shape_type": "circle", "properties": { "radius": 32.0 } }`
- **Expected result:** Success. Circle-shaped CollisionShape2D added.

#### Scenario 10: shape_type = `rectangle`
- **Description:** Add a rectangle collision shape (2D)
- **Params:** `{ "path": "Sprite2D", "shape_type": "rectangle", "properties": { "size": [64.0, 64.0] } }`
- **Expected result:** Success. Rectangle-shaped CollisionShape2D added.

#### Scenario 11: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{ "shape_type": "box" }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 12: Edge — missing `shape_type`
- **Description:** Call without the required `shape_type` parameter
- **Params:** `{ "path": "Player" }`
- **Expected result:** Zod validation error (shape_type is required).

#### Scenario 13: Edge — invalid shape_type value
- **Description:** Call with a shape type not in the enum
- **Params:** `{ "path": "Player", "shape_type": "pyramid" }`
- **Expected result:** Zod validation error (shape_type must be one of the enum values).

#### Scenario 14: Edge — node does not exist
- **Description:** Add collision to a non-existent node
- **Params:** `{ "path": "NonExistentNodeXYZ", "shape_type": "box" }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 15: Edge — node already has a collision shape
- **Description:** Call on a node that already has a collision shape
- **Params:** `{ "path": "Player", "shape_type": "sphere" }`
- **Expected result:** May add a second collision shape or replace existing. Test to verify.
- **Notes:** Run after Scenario 1.

#### Scenario 16: Edge — empty string path (scene root)
- **Description:** Add a collision shape to the scene root
- **Params:** `{ "path": "", "shape_type": "box" }`
- **Expected result:** Success if root node supports collision shapes; error otherwise.

#### Scenario 17: Edge — properties with invalid key
- **Description:** Pass properties dict with a key that is not a valid shape property
- **Params:** `{ "path": "Player", "shape_type": "box", "properties": { "banana": "yellow" } }`
- **Expected result:** May succeed with ignored property, or Godot error.

---

## Tool: `set_physics_layers`

**Description:** Set physics collision layers and masks on a node
**Handler:** `callGodot(bridge, 'physics/set_layers', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node with collision object |
| `layer` | number (int, 1–32) | No | — | Collision layer (1-32) |
| `mask` | number (int, 1–32) | No | — | Collision mask (1-32) |

### Test Scenarios

#### Scenario 1: Happy path — set both layer and mask
- **Description:** Set both collision layer and mask on a node
- **Params:** `{ "path": "Player", "layer": 1, "mask": 1 }`
- **Expected result:** Success. Node's collision layer and mask are set to 1.

#### Scenario 2: Happy path — set only layer
- **Description:** Set only the collision layer, leaving mask unchanged
- **Params:** `{ "path": "Player", "layer": 3 }`
- **Expected result:** Success. Collision layer set to 3.

#### Scenario 3: Happy path — set only mask
- **Description:** Set only the collision mask, leaving layer unchanged
- **Params:** `{ "path": "Player", "mask": 5 }`
- **Expected result:** Success. Collision mask set to 5.

#### Scenario 4: Happy path — layer = 1 (minimum)
- **Description:** Set layer to the minimum valid value
- **Params:** `{ "path": "Player", "layer": 1 }`
- **Expected result:** Success. Layer set to 1.

#### Scenario 5: Happy path — layer = 32 (maximum)
- **Description:** Set layer to the maximum valid value
- **Params:** `{ "path": "Player", "layer": 32 }`
- **Expected result:** Success. Layer set to 32.

#### Scenario 6: Happy path — mask = 1 (minimum)
- **Description:** Set mask to the minimum valid value
- **Params:** `{ "path": "Player", "mask": 1 }`
- **Expected result:** Success. Mask set to 1.

#### Scenario 7: Happy path — mask = 32 (maximum)
- **Description:** Set mask to the maximum valid value
- **Params:** `{ "path": "Player", "mask": 32 }`
- **Expected result:** Success. Mask set to 32.

#### Scenario 8: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{ "layer": 1 }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 9: Edge — layer = 0 (below minimum)
- **Description:** Set layer to 0 (invalid, below min)
- **Params:** `{ "path": "Player", "layer": 0 }`
- **Expected result:** Zod validation error (layer must be >= 1).

#### Scenario 10: Edge — layer = 33 (above maximum)
- **Description:** Set layer to 33 (invalid, above max)
- **Params:** `{ "path": "Player", "layer": 33 }`
- **Expected result:** Zod validation error (layer must be <= 32).

#### Scenario 11: Edge — layer as float (not int)
- **Description:** Set layer to a non-integer value
- **Params:** `{ "path": "Player", "layer": 1.5 }`
- **Expected result:** Zod validation error (layer must be an integer).

#### Scenario 12: Edge — mask = 0 (below minimum)
- **Description:** Set mask to 0 (invalid, below min)
- **Params:** `{ "path": "Player", "mask": 0 }`
- **Expected result:** Zod validation error (mask must be >= 1).

#### Scenario 13: Edge — mask = 33 (above maximum)
- **Description:** Set mask to 33 (invalid, above max)
- **Params:** `{ "path": "Player", "mask": 33 }`
- **Expected result:** Zod validation error (mask must be <= 32).

#### Scenario 14: Edge — layer as negative number
- **Description:** Set layer to a negative value
- **Params:** `{ "path": "Player", "layer": -1 }`
- **Expected result:** Zod validation error (layer must be >= 1).

#### Scenario 15: Edge — node does not exist
- **Description:** Set layers on a non-existent node
- **Params:** `{ "path": "NonExistentNodeXYZ", "layer": 1 }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 16: Edge — node without collision object
- **Description:** Set layers on a node that has no collision shape/body
- **Params:** `{ "path": "NodeWithoutCollision", "layer": 1 }`
- **Expected result:** May succeed (setting property on the node itself) or error. Test to verify.

#### Scenario 17: Edge — only path provided (no layer or mask)
- **Description:** Call with only path, no layer or mask
- **Params:** `{ "path": "Player" }`
- **Expected result:** Zod passes validation (both are optional). Godot may succeed as a no-op or return an error about missing parameters.

---

## Tool: `get_physics_layers`

**Description:** Get physics layer and mask information for a node
**Handler:** `callGodot(bridge, 'physics/get_layers', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node with collision object |

### Test Scenarios

#### Scenario 1: Happy path — get layers from a node with collision
- **Description:** Retrieve layer and mask info from a node that has collision configured
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success. Returns an object with `layer` and `mask` values.
- **Notes:** Run after `set_physics_layers` Scenario 1 to have known values.

#### Scenario 2: Happy path — get layers from node with only defaults
- **Description:** Get layers from a node that has collision but layers were never explicitly set
- **Params:** `{ "path": "Enemy" }`
- **Expected result:** Success. Returns default layer/mask values (typically 1/1).

#### Scenario 3: Edge — node does not exist
- **Description:** Get layers from a non-existent node
- **Params:** `{ "path": "NonExistentNodeXYZ" }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 4: Edge — node without collision object
- **Description:** Get layers from a node that has no collision shape or body
- **Params:** `{ "path": "NodeWithoutCollision" }`
- **Expected result:** May return default values or an error. Test to verify.

#### Scenario 5: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 6: Edge — empty string path (scene root)
- **Description:** Get layers from the scene root node
- **Params:** `{ "path": "" }`
- **Expected result:** Returns layer/mask info from the root node if it has collision; error otherwise.

#### Scenario 7: Scenario — verify returned values match set values
- **Description:** Set specific layer/mask values, then get them back and verify
- **Description (steps):** 1. `set_physics_layers` with `layer: 7, mask: 13`. 2. `get_physics_layers` and verify the returned `layer` is 7 and `mask` is 13.
- **Expected result:** Returned values match the values that were set.

---

## Tool: `get_collision_info`

**Description:** Get collision information for a physics body
**Handler:** `callGodot(bridge, 'physics/get_collision_info', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Physics body node path |

### Test Scenarios

#### Scenario 1: Happy path — get collision info from a node with physics body
- **Description:** Retrieve collision information from a node that has a physics body and collision shape
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success. Returns detailed collision info (body type, shapes, layers, etc.).
- **Notes:** Run after `setup_physics_body` and `setup_collision`.

#### Scenario 2: Happy path — get collision info for a static body
- **Description:** Get collision info from a StaticBody node with collision
- **Params:** `{ "path": "StaticBody" }`
- **Expected result:** Success. Returns info reflecting the StaticBody type and its shapes.

#### Scenario 3: Happy path — get collision info from scene root
- **Description:** Get collision info from the scene root node
- **Params:** `{ "path": "" }`
- **Expected result:** Returns collision info if root has a physics body; error otherwise.

#### Scenario 4: Edge — node does not exist
- **Description:** Get collision info from a non-existent node
- **Params:** `{ "path": "NonExistentNodeXYZ" }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 5: Edge — node has no physics body
- **Description:** Get collision info from a node that has no physics body (e.g., a plain Node2D)
- **Params:** `{ "path": "Node2D" }`
- **Expected result:** May return an error or an empty/partial result. Test to verify.
- **Notes:** Node2D has no physics body by default.

#### Scenario 6: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 7: Scenario — verify info after modifying collision
- **Description:** Get collision info, modify the collision shape, then get info again and compare
- **Description (steps):** 1. `get_collision_info` on Player. 2. `setup_collision` with a different shape. 3. `get_collision_info` again. Verify the info reflects the new shape.
- **Expected result:** Second call returns updated collision info matching the new shape.

---

## Tool: `add_raycast`

**Description:** Add a RayCast2D or RayCast3D node
**Handler:** `callGodot(bridge, 'physics/add_raycast', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `parent_path` | `ParentPath` (string) | **Yes** | — | Parent node — `''` for scene root |
| `properties` | `OptionalProperties` (record) | No | — | Raycast properties (target, enabled, collide_with_areas, etc.) |

### Test Scenarios

#### Scenario 1: Happy path — add raycast to scene root
- **Description:** Add a raycast as a child of the scene root (empty parent_path)
- **Params:** `{ "parent_path": "" }`
- **Expected result:** Success. A new raycast node is added as a child of the scene root.

#### Scenario 2: Happy path — add raycast to a specific node
- **Description:** Add a raycast as a child of a named node
- **Params:** `{ "parent_path": "Player" }`
- **Expected result:** Success. A new raycast node is added as a child of the "Player" node.

#### Scenario 3: Happy path — add raycast with enabled property
- **Description:** Add a raycast that is enabled by default
- **Params:** `{ "parent_path": "Player", "properties": { "enabled": true } }`
- **Expected result:** Success. Raycast node created and enabled.

#### Scenario 4: Happy path — add raycast with disabled property
- **Description:** Add a raycast that is initially disabled
- **Params:** `{ "parent_path": "Player", "properties": { "enabled": false } }`
- **Expected result:** Success. Raycast node created but disabled.

#### Scenario 5: Happy path — add raycast with target_position
- **Description:** Add a raycast with a target position (direction/length)
- **Params:** `{ "parent_path": "Player", "properties": { "target_position": [0, -100] } }`
- **Expected result:** Success. Raycast created pointing downward 100 units (2D).

#### Scenario 6: Happy path — add raycast with collide_with_areas
- **Description:** Add a raycast that collides with areas
- **Params:** `{ "parent_path": "Player", "properties": { "collide_with_areas": true } }`
- **Expected result:** Success. Raycast configured to detect areas.

#### Scenario 7: Happy path — add raycast with collide_with_bodies
- **Description:** Add a raycast that collides with bodies
- **Params:** `{ "parent_path": "Player", "properties": { "collide_with_bodies": true } }`
- **Expected result:** Success. Raycast configured to detect bodies.

#### Scenario 8: Happy path — add raycast to nested parent
- **Description:** Add a raycast to a deeply nested parent node
- **Params:** `{ "parent_path": "Parent/Child/Grandchild" }`
- **Expected result:** Success if the parent node exists at that path; error otherwise.

#### Scenario 9: Edge — missing `parent_path`
- **Description:** Call without the required `parent_path` parameter
- **Params:** `{ "properties": { "enabled": true } }`
- **Expected result:** Zod validation error (parent_path is required).

#### Scenario 10: Edge — parent_path does not exist
- **Description:** Add raycast to a non-existent parent node
- **Params:** `{ "parent_path": "NonExistentParentXYZ" }`
- **Expected result:** Error from Godot (parent node not found).

#### Scenario 11: Edge — raycast properties with invalid key
- **Description:** Pass a property that does not exist on a raycast node
- **Params:** `{ "parent_path": "Player", "properties": { "color": "red" } }`
- **Expected result:** May succeed with ignored property, or Godot error.

#### Scenario 12: Edge — no properties (empty object vs omitted)
- **Description:** Add a raycast with explicit empty properties
- **Params:** `{ "parent_path": "Player", "properties": {} }`
- **Expected result:** Same as omitting properties. Raycast created with defaults.

---

## Tool: `get_physics_material`

**Description:** Get the physics material properties of a node
**Handler:** `callGodot(bridge, 'physics/get_material', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path in the scene tree |

### Test Scenarios

#### Scenario 1: Happy path — get material from a node with a physics material
- **Description:** Retrieve physics material properties from a node that has one assigned
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success. Returns material properties (friction, bounce, rough, absorbent).
- **Notes:** Run after `set_physics_material` Scenario 1.

#### Scenario 2: Happy path — get material from a node with default material
- **Description:** Get material properties from a node that has a physics body but no custom material
- **Params:** `{ "path": "Enemy" }`
- **Expected result:** Success. Returns default physics material properties.

#### Scenario 3: Edge — node does not exist
- **Description:** Get material from a non-existent node
- **Params:** `{ "path": "NonExistentNodeXYZ" }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 4: Edge — node has no physics body / collision
- **Description:** Get material from a node without any physics body
- **Params:** `{ "path": "Sprite2D" }`
- **Expected result:** May return an error or empty result. Test to verify.
- **Notes:** Sprite2D has no physics material unless a physics body was added.

#### Scenario 5: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 6: Edge — empty string path (scene root)
- **Description:** Get material from the scene root node
- **Params:** `{ "path": "" }`
- **Expected result:** Returns material properties if root has a physics body; error otherwise.

#### Scenario 7: Scenario — verify material properties after set
- **Description:** Set a physics material, then get it back and verify values
- **Description (steps):** 1. `set_physics_material` with `friction: 0.8, bounce: 0.4, rough: true, absorbent: false`. 2. `get_physics_material` and verify all four values match.
- **Expected result:** Returned material properties match the values that were set.

---

## Tool: `set_physics_material`

**Description:** Create and set a physics material on a node
**Handler:** `callGodot(bridge, 'physics/set_material', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path in the scene tree |
| `friction` | number (>= 0) | No | — | Friction coefficient |
| `bounce` | number (0–1) | No | — | Bounce/Restitution coefficient |
| `rough` | boolean | No | — | Whether surface is rough |
| `absorbent` | boolean | No | — | Whether the surface absorbs impact energy |

### Test Scenarios

#### Scenario 1: Happy path — set all material properties
- **Description:** Set friction, bounce, rough, and absorbent on a node
- **Params:** `{ "path": "Player", "friction": 0.8, "bounce": 0.3, "rough": true, "absorbent": false }`
- **Expected result:** Success. Physics material created and assigned with all specified values.

#### Scenario 2: Happy path — set only friction
- **Description:** Set only the friction coefficient
- **Params:** `{ "path": "Player", "friction": 0.5 }`
- **Expected result:** Success. Friction is set. Other properties remain at defaults.

#### Scenario 3: Happy path — set only bounce
- **Description:** Set only the bounce/restitution coefficient
- **Params:** `{ "path": "Player", "bounce": 0.9 }`
- **Expected result:** Success. Bounce is set to 0.9.

#### Scenario 4: Happy path — set rough = true
- **Description:** Set the rough flag to true
- **Params:** `{ "path": "Player", "rough": true }`
- **Expected result:** Success. Rough flag is set.

#### Scenario 5: Happy path — set rough = false
- **Description:** Set the rough flag to false (smooth surface)
- **Params:** `{ "path": "Player", "rough": false }`
- **Expected result:** Success. Rough flag is cleared.

#### Scenario 6: Happy path — set absorbent = true
- **Description:** Set the absorbent flag to true
- **Params:** `{ "path": "Player", "absorbent": true }`
- **Expected result:** Success. Absorbent flag is set.

#### Scenario 7: Happy path — set absorbent = false
- **Description:** Set the absorbent flag to false
- **Params:** `{ "path": "Player", "absorbent": false }`
- **Expected result:** Success. Absorbent flag is cleared.

#### Scenario 8: Happy path — friction = 0 (minimum)
- **Description:** Set friction to the minimum value (perfectly slippery)
- **Params:** `{ "path": "Player", "friction": 0 }`
- **Expected result:** Success. Friction set to 0.

#### Scenario 9: Happy path — bounce = 0 (minimum)
- **Description:** Set bounce to the minimum value (no bounce)
- **Params:** `{ "path": "Player", "bounce": 0 }`
- **Expected result:** Success. Bounce set to 0 (inelastic).

#### Scenario 10: Happy path — bounce = 1 (maximum)
- **Description:** Set bounce to the maximum value (perfect bounce)
- **Params:** `{ "path": "Player", "bounce": 1 }`
- **Expected result:** Success. Bounce set to 1 (perfectly elastic).

#### Scenario 11: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{ "friction": 0.5 }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 12: Edge — negative friction
- **Description:** Set friction to a negative value
- **Params:** `{ "path": "Player", "friction": -0.5 }`
- **Expected result:** Zod validation error (friction must be >= 0).

#### Scenario 13: Edge — bounce > 1
- **Description:** Set bounce to a value above the maximum
- **Params:** `{ "path": "Player", "bounce": 1.5 }`
- **Expected result:** Zod validation error (bounce must be <= 1).

#### Scenario 14: Edge — bounce = -0.1 (negative)
- **Description:** Set bounce to a negative value
- **Params:** `{ "path": "Player", "bounce": -0.1 }`
- **Expected result:** Zod validation error (bounce must be >= 0).

#### Scenario 15: Edge — node does not exist
- **Description:** Set material on a non-existent node
- **Params:** `{ "path": "NonExistentNodeXYZ", "friction": 0.5 }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 16: Edge — node has no physics body
- **Description:** Set material on a node without a physics body
- **Params:** `{ "path": "Node2D", "friction": 0.5 }`
- **Expected result:** May error (no physics body to assign material to) or succeed by adding the material to the node regardless. Test to verify.

#### Scenario 17: Edge — no optional params (only path)
- **Description:** Call with only path, no material properties
- **Params:** `{ "path": "Player" }`
- **Expected result:** Zod passes validation (all other params are optional). Godot may create a material with all defaults or return an error about missing properties.

#### Scenario 18: Edge — rough as non-boolean value
- **Description:** Set rough to a string or number instead of boolean
- **Params:** `{ "path": "Player", "rough": "yes" }`
- **Expected result:** Zod validation error (rough must be boolean).

#### Scenario 19: Edge — absorbent as non-boolean value
- **Description:** Set absorbent to a number instead of boolean
- **Params:** `{ "path": "Player", "absorbent": 1 }`
- **Expected result:** Zod validation error (absorbent must be boolean).

#### Scenario 20: Scenario — overwrite existing material
- **Description:** Set a material, then set different values and verify the material is updated
- **Description (steps):** 1. `set_physics_material` with `friction: 0.2`. 2. `set_physics_material` with `friction: 0.9`. 3. `get_physics_material`. Verify friction is 0.9.
- **Expected result:** The second call overwrites the material. Friction reading is 0.9.

---

## Integration Test Scenarios

These scenarios chain multiple physics tools together to verify end-to-end workflows.

### Integration 1: Full physics body setup workflow
1. `setup_physics_body` on `"Player"` with `properties: { "mass": 5.0, "gravity_scale": 1.0 }`
2. `setup_collision` on `"Player"` with `shape_type: "capsule"`, `properties: { "radius": 0.5, "height": 2.0 }`
3. `set_physics_layers` on `"Player"` with `layer: 1, mask: 3`
4. `set_physics_material` on `"Player"` with `friction: 0.6, bounce: 0.2, rough: false, absorbent: false`
5. `get_physics_layers` on `"Player"` — verify `layer: 1, mask: 3`
6. `get_collision_info` on `"Player"` — verify capsule shape and body type
7. `get_physics_material` on `"Player"` — verify `friction: 0.6, bounce: 0.2, rough: false, absorbent: false`
- **Expected result:** All 7 steps succeed. Each get operation returns values matching what was set.

### Integration 2: Raycast + collision workflow
1. `add_raycast` to `"Player"` with `properties: { "enabled": true, "target_position": [0, -200], "collide_with_bodies": true }`
2. `setup_collision` on `"Enemy"` with `shape_type: "box"`
3. `set_physics_layers` on `"Enemy"` with `layer: 2`
4. `set_physics_layers` on `"Player"` with `mask: 2` (so Player's raycast can hit Enemy's layer)
5. `get_collision_info` on `"Enemy"` — verify box shape
- **Expected result:** All steps succeed. The raycast on Player is configured to detect collisions with Enemy's layer (layer 2).

### Integration 3: Multiple collision shapes on one node
1. `setup_collision` on `"Player"` with `shape_type: "capsule"`
2. `setup_collision` on `"Player"` with `shape_type: "box"` — adding a second shape
3. `get_collision_info` on `"Player"` — verify both shapes are present
- **Expected result:** Both collision shapes exist on the node. get_collision_info returns info about both.

### Integration 4: Layer boundary testing
1. `set_physics_layers` on `"Player"` with `layer: 1, mask: 1` (minimums)
2. `get_physics_layers` — verify layer: 1, mask: 1
3. `set_physics_layers` on `"Player"` with `layer: 32, mask: 32` (maximums)
4. `get_physics_layers` — verify layer: 32, mask: 32
- **Expected result:** Both boundary values are set and retrieved correctly.

### Integration 5: Material property extremes
1. `set_physics_material` on `"Player"` with `friction: 0, bounce: 0` (all minimums)
2. `get_physics_material` — verify friction: 0, bounce: 0
3. `set_physics_material` on `"Player"` with `bounce: 1` (max bounce, leave friction at previous)
4. `get_physics_material` — verify bounce: 1
- **Expected result:** Boundary values are handled correctly.

---

## Summary

| Tool | Params | Required | Optional | Enum Values / Constraints |
|---|---|---|---|---|
| `setup_physics_body` | 2 | `path`, `properties` | — | — |
| `setup_collision` | 3 | `path`, `shape_type` | `properties` | `shape_type`: box, sphere, capsule, cylinder, convex, concave, polygon, circle, rectangle |
| `set_physics_layers` | 3 | `path` | `layer` (1–32), `mask` (1–32) | `layer`/`mask`: int, 1–32 |
| `get_physics_layers` | 1 | `path` | — | — |
| `get_collision_info` | 1 | `path` | — | — |
| `add_raycast` | 2 | `parent_path` | `properties` | — |
| `get_physics_material` | 1 | `path` | — | — |
| `set_physics_material` | 5 | `path` | `friction` (≥0), `bounce` (0–1), `rough` (bool), `absorbent` (bool) | — |

**Total scenarios:** 90+ covering all 8 tools with happy paths, all enum values for `shape_type`, all boundary values for `layer`/`mask`/`bounce`/`friction`, edge cases, and 5 integration workflows.
