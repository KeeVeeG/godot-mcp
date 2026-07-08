# Physics Tools Test Plan

**Source file:** `server/src/tools/physics.ts`
**Shared types:** `server/src/tools/shared-types.ts`
**Bridge method:** All tools call `callGodot(bridge, 'physics/<method>', args)` — the result is proxied to the Godot editor via WebSocket JSON-RPC.

## Overview

8 tools registered by `registerPhysicsTools()`. Each tool forwards its arguments verbatim to a Godot-side handler via `callGodot`. The MCP server itself performs Zod validation only; all domain logic lives in the Godot plugin.

### Type Reference (from shared-types.ts)

| Type | Zod Schema | Description |
|---|---|---|
| `NodePath` | `z.string()` | Scene-relative node path, e.g. `"Player/Sprite2D"`, `""` for scene root |
| `ParentPath` | `z.string()` | Parent node path, `""` for scene root |
| `Properties` | `z.record(z.unknown())` — **required** | Key-value pairs for body/shape properties |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | Key-value pairs, may be omitted |

### Prerequisites for All Tests

Before running physics tool tests, ensure:

1. **Godot editor is open** with the MCP plugin active and connected (ports 6505-6514).
2. **A scene is open** (e.g. `res://scenes/test_physics.tscn`) with at least one node to target. Create test nodes using the `add_node` tool from `node.ts` before calling physics tools.
3. **For tools requiring a physics body on the node** (`set_physics_layers`, `get_physics_layers`, `get_collision_info`, `get_physics_material`, `set_physics_material`): the target node must already have a physics body (e.g. `RigidBody2D`, `CharacterBody3D`, `StaticBody3D`). Use `setup_physics_body` first or create nodes of the correct type.

---

## Tool: `setup_physics_body`

**Description:** Add and configure a physics body on a node.
**Bridge method:** `physics/setup_body`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | `string` (NodePath) | **yes** | Node to add the physics body to |
| `properties` | `Record<string, unknown>` (Properties) | **yes** | Body properties (mass, gravity_scale, etc.) |

### Test Scenarios

#### Scenario 1: Happy path — add RigidBody2D properties to a node

**Description:** Set up a physics body with mass and gravity_scale on an existing 2D node.

**Preconditions:** A `CharacterBody2D` node named `"Player"` exists in the current scene.

**Call:**
```json
{
  "path": "Player",
  "properties": {
    "type": "RigidBody2D",
    "mass": 5.0,
    "gravity_scale": 1.0,
    "linear_damp": 0.5
  }
}
```

**Expected result:** Success response. The node `"Player"` should now have a physics body configured with the given properties. Verify by calling `get_node_properties` or checking in the Godot editor.

**Notes:** The exact property keys (`mass`, `gravity_scale`, etc.) are interpreted by the Godot-side handler. Invalid keys may be silently ignored or produce an error depending on the plugin implementation.

**What to pay attention to:** Verify that the response contains no errors. Ensure that the properties were actually applied (by reading the node's properties).

---

#### Scenario 2: Happy path — add StaticBody3D properties

**Description:** Configure a static physics body (e.g. for a wall or floor).

**Preconditions:** A `StaticBody3D` node named `"Floor"` exists in the current scene.

**Call:**
```json
{
  "path": "Floor",
  "properties": {
    "type": "StaticBody3D",
    "constant_linear_velocity": [0, 0, 0]
  }
}
```

**Expected result:** Success response.

**Notes:** `StaticBody3D` does not have `mass` — passing `mass` here would be nonsensical. The Godot handler should ignore or error on invalid properties for the body type.

**What to pay attention to:** Verify that the response does not contain validation errors. If Godot returned an error about a non-existent property — this may be normal behavior.

---

#### Scenario 3: Minimal required params only — empty properties

**Description:** Call with only required fields and an empty properties object.

**Call:**
```json
{
  "path": "Player",
  "properties": {}
}
```

**Expected result:** Likely success (depends on Godot handler — empty properties means "add body with defaults"). If the handler requires at least a `type` key, an error is expected.

**What to pay attention to:** Determine behavior with empty `properties` — either a default body or an error. Record as acceptable behavior.

---

#### Scenario 4: Missing required `path`

**Call:**
```json
{
  "properties": { "type": "RigidBody2D" }
}
```

**Expected result:** Zod validation error before the call reaches Godot. Error message should indicate `path` is required.

**What to pay attention to:** The error should contain an indication of the missing `path` field.

---

#### Scenario 5: Missing required `properties`

**Call:**
```json
{
  "path": "Player"
}
```

**Expected result:** Zod validation error. `properties` is a required field (not `.optional()`).

**What to pay attention to:** The error should contain an indication of the missing `properties` field.

---

#### Scenario 6: Non-existent node path

**Call:**
```json
{
  "path": "NonExistentNode/DoesNotExist",
  "properties": { "type": "RigidBody2D" }
}
```

**Expected result:** Error from Godot side — node not found in the current scene tree.

**What to pay attention to:** Verify that the error is informative and points to the node path issue.

---

#### Scenario 7: Invalid property value type

**Call:**
```json
{
  "path": "Player",
  "properties": {
    "mass": "not_a_number"
  }
}
```

**Expected result:** May succeed at the MCP level (properties is `z.record(z.unknown())` so any value passes Zod), but the Godot handler should return an error about invalid property type.

**What to pay attention to:** Verify where exactly the validation happens — on the MCP side or on the Godot side.

---

#### Relationship with other tools

- **Before:** Use `add_node` (from `node.ts`) to create the target node if it doesn't exist. Use `open_scene` (from `scene.ts`) to ensure the correct scene is active.
- **After:** Use `setup_collision` to add a collision shape to the same node. Use `set_physics_layers` to configure collision layers. Use `set_physics_material` to add material.

---

## Tool: `setup_collision`

**Description:** Add and configure a collision shape on a node.
**Bridge method:** `physics/setup_collision`

### Parameters

| Name | Type | Required | Description | Values |
|---|---|---|---|---|
| `path` | `string` (NodePath) | **yes** | Node to add collision to | — |
| `shape_type` | `enum` | **yes** | Collision shape type | `"box"`, `"sphere"`, `"capsule"`, `"cylinder"`, `"convex"`, `"concave"`, `"polygon"`, `"circle"`, `"rectangle"` |
| `properties` | `Record<string, unknown>` (OptionalProperties) | no | Shape properties (size, radius, height, etc.) | — |

### Test Scenarios

#### Scenario 1: Happy path — box collision shape

**Description:** Add a box collision shape with explicit size to a physics body node.

**Preconditions:** A `StaticBody3D` node named `"Wall"` exists in the current scene.

**Call:**
```json
{
  "path": "Wall",
  "shape_type": "box",
  "properties": {
    "size": [10, 5, 2]
  }
}
```

**Expected result:** Success response. A `CollisionShape3D` child node with a `BoxShape3D` resource should be added to `"Wall"`.

**What to pay attention to:** Verify that `CollisionShape3D` was created as a child element. Check the shape dimensions.

---

#### Scenario 2: Happy path — sphere collision with radius

**Preconditions:** A `RigidBody3D` node named `"Ball"` exists.

**Call:**
```json
{
  "path": "Ball",
  "shape_type": "sphere",
  "properties": {
    "radius": 1.5
  }
}
```

**Expected result:** Success. A `CollisionShape3D` with `SphereShape3D` (radius 1.5) is added to `"Ball"`.

**What to pay attention to:** Verify the shape radius via `get_node_properties`.

---

#### Scenario 3: Happy path — 2D circle collision

**Preconditions:** A `RigidBody2D` node named `"Coin"` exists.

**Call:**
```json
{
  "path": "Coin",
  "shape_type": "circle",
  "properties": {
    "radius": 20
  }
}
```

**Expected result:** Success. A `CollisionShape2D` with `CircleShape2D` (radius 20) is added.

**What to pay attention to:** Ensure that for a 2D node, `CollisionShape2D` is created, not `CollisionShape3D`.

---

#### Scenario 4: Minimal call — no optional properties

**Call:**
```json
{
  "path": "Wall",
  "shape_type": "box"
}
```

**Expected result:** Success with default shape dimensions (depends on Godot handler — likely uses Godot's default `BoxShape3D` size of `(1,1,1)`).

**What to pay attention to:** What default shape size will be used.

---

#### Scenario 5: Capsule shape

**Call:**
```json
{
  "path": "Player",
  "shape_type": "capsule",
  "properties": {
    "radius": 0.5,
    "height": 2.0
  }
}
```

**Expected result:** Success. `CapsuleShape3D` with radius 0.5 and height 2.0.

**What to pay attention to:** Verify that both parameters (radius and height) were applied correctly.

---

#### Scenario 6: Polygon shape with vertices

**Call:**
```json
{
  "path": "Platform",
  "shape_type": "polygon",
  "properties": {
    "polygon": [[0, 0], [100, 0], [100, 20], [0, 20]]
  }
}
```

**Expected result:** Success. A `CollisionPolygon2D` or equivalent is created with the given vertices.

**What to pay attention to:** Verify that the polygon vertices are set correctly. This is a 2D-specific shape type.

---

#### Scenario 7: Invalid `shape_type` value

**Call:**
```json
{
  "path": "Wall",
  "shape_type": "invalid_shape"
}
```

**Expected result:** Zod validation error — `"invalid_shape"` is not in the enum `['box', 'sphere', 'capsule', 'cylinder', 'convex', 'concave', 'polygon', 'circle', 'rectangle']`.

**What to pay attention to:** The error message should contain the list of valid values.

---

#### Scenario 8: Missing required `shape_type`

**Call:**
```json
{
  "path": "Wall",
  "properties": { "size": [1, 1, 1] }
}
```

**Expected result:** Zod validation error — `shape_type` is required.

**What to pay attention to:** The error should clearly indicate the missing `shape_type` field.

---

#### Scenario 9: Missing required `path`

**Call:**
```json
{
  "shape_type": "box"
}
```

**Expected result:** Zod validation error — `path` is required.

**What to pay attention to:** Verify the error message.

---

#### Relationship with other tools

- **Before:** Use `setup_physics_body` to ensure the target node has a physics body. Some shape types (`circle`, `rectangle`, `polygon`) are 2D-specific; ensure you're working with 2D nodes.
- **After:** Use `set_physics_layers` to configure which layers this collision interacts with.

---

## Tool: `set_physics_layers`

**Description:** Set physics collision layers and masks on a node.
**Bridge method:** `physics/set_layers`

### Parameters

| Name | Type | Required | Description | Constraints |
|---|---|---|---|---|
| `path` | `string` (NodePath) | **yes** | Node with collision object | — |
| `layer` | `number` | no | Collision layer (1-32) | `int`, `min(1)`, `max(32)` |
| `mask` | `number` | no | Collision mask (1-32) | `int`, `min(1)`, `max(32)` |

**Note:** At least one of `layer` or `mask` should be provided for the call to be meaningful, though both are technically optional at the schema level.

### Test Scenarios

#### Scenario 1: Happy path — set both layer and mask

**Preconditions:** A `RigidBody2D` node named `"Enemy"` with a physics body exists.

**Call:**
```json
{
  "path": "Enemy",
  "layer": 2,
  "mask": 1
}
```

**Expected result:** Success. The `"Enemy"` node's collision layer is set to 2 and collision mask is set to 1.

**What to pay attention to:** Verify that layer and mask were applied. Use `get_physics_layers` for verification.

---

#### Scenario 2: Set only layer

**Call:**
```json
{
  "path": "Enemy",
  "layer": 5
}
```

**Expected result:** Success. Layer set to 5, mask unchanged.

**What to pay attention to:** Ensure that mask was not reset.

---

#### Scenario 3: Set only mask

**Call:**
```json
{
  "path": "Enemy",
  "mask": 3
}
```

**Expected result:** Success. Mask set to 3, layer unchanged.

**What to pay attention to:** Ensure that layer was not reset.

---

#### Scenario 4: Boundary — layer = 1 (minimum)

**Call:**
```json
{
  "path": "Enemy",
  "layer": 1
}
```

**Expected result:** Success.

**What to pay attention to:** Boundary value. Should pass validation.

---

#### Scenario 5: Boundary — layer = 32 (maximum)

**Call:**
```json
{
  "path": "Enemy",
  "layer": 32
}
```

**Expected result:** Success.

**What to pay attention to:** Boundary value. Should pass validation.

---

#### Scenario 6: Invalid — layer = 0 (below minimum)

**Call:**
```json
{
  "path": "Enemy",
  "layer": 0
}
```

**Expected result:** Zod validation error — `layer` must be ≥ 1.

**What to pay attention to:** Verify that Zod rejects the value 0.

---

#### Scenario 7: Invalid — layer = 33 (above maximum)

**Call:**
```json
{
  "path": "Enemy",
  "layer": 33
}
```

**Expected result:** Zod validation error — `layer` must be ≤ 32.

**What to pay attention to:** Verify that Zod rejects the value 33.

---

#### Scenario 8: Invalid — non-integer layer

**Call:**
```json
{
  "path": "Enemy",
  "layer": 2.5
}
```

**Expected result:** Zod validation error — `layer` must be an integer.

**What to pay attention to:** Verify that fractional numbers are rejected.

---

#### Scenario 9: Invalid — negative mask

**Call:**
```json
{
  "path": "Enemy",
  "mask": -1
}
```

**Expected result:** Zod validation error — `mask` must be ≥ 1.

**What to pay attention to:** Negative values should be rejected.

---

#### Scenario 10: No layer and no mask provided

**Call:**
```json
{
  "path": "Enemy"
}
```

**Expected result:** The call passes Zod validation (both are optional). The Godot handler may succeed silently (no-op) or may return an error/warning.

**What to pay attention to:** Determine how Godot handles a call without layer/mask parameters. This may be a no-op or an error.

---

#### Relationship with other tools

- **Before:** The node must have a collision object (physics body + collision shape). Use `setup_physics_body` and `setup_collision` first.
- **After:** Use `get_physics_layers` to verify the applied values. Use `get_collision_info` to check collision state.

---

## Tool: `get_physics_layers`

**Description:** Get physics layer and mask information for a node.
**Bridge method:** `physics/get_layers`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | `string` (NodePath) | **yes** | Node with collision object |

### Test Scenarios

#### Scenario 1: Happy path — read layers from a configured node

**Preconditions:** A node `"Player"` exists with collision layers previously set via `set_physics_layers`.

**Call:**
```json
{
  "path": "Player"
}
```

**Expected result:** Success response containing layer and mask information, e.g. `{"layer": 1, "mask": 2}` or similar structure.

**What to pay attention to:** Verify that the response contains both fields (layer and mask) or at least one. Check the response format.

---

#### Scenario 2: Read layers from a node with default layers

**Preconditions:** A node `"Wall"` with a physics body but layers never explicitly set (Godot defaults: layer=1, mask=1).

**Call:**
```json
{
  "path": "Wall"
}
```

**Expected result:** Success with default values returned.

**What to pay attention to:** Verify that Godot's default values (layer=1, mask=1) are returned correctly.

---

#### Scenario 3: Non-existent node

**Call:**
```json
{
  "path": "NonExistentNode"
}
```

**Expected result:** Error from Godot — node not found.

**What to pay attention to:** The error should be informative.

---

#### Scenario 4: Node without physics body

**Preconditions:** A regular `Sprite2D` node `"Decoration"` exists (no physics body).

**Call:**
```json
{
  "path": "Decoration"
}
```

**Expected result:** Error from Godot — node does not have a collision object.

**What to pay attention to:** Verify that Godot returns a meaningful error, not a crash.

---

#### Relationship with other tools

- **Before:** Use `set_physics_layers` to set known layer/mask values, then verify with this tool.
- **Verification pattern:** `set_physics_layers` → `get_physics_layers` → assert values match.

---

## Tool: `get_collision_info`

**Description:** Get collision information for a physics body.
**Bridge method:** `physics/get_collision_info`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | `string` (NodePath) | **yes** | Physics body node path |

### Test Scenarios

#### Scenario 1: Happy path — get info from a physics body

**Preconditions:** A `RigidBody2D` node named `"Player"` exists with a collision shape attached.

**Call:**
```json
{
  "path": "Player"
}
```

**Expected result:** Success response with collision information (shape count, shape types, collision layers/masks, etc.).

**What to pay attention to:** Check the response structure — what fields are returned. Ensure that collision shapes information is present.

---

#### Scenario 2: Physics body with multiple collision shapes

**Preconditions:** A node `"ComplexBody"` exists with 2+ collision shapes added via `setup_collision`.

**Call:**
```json
{
  "path": "ComplexBody"
}
```

**Expected result:** Success with info about all collision shapes.

**What to pay attention to:** Verify that all collision shapes are listed in the response, not just the first one.

---

#### Scenario 3: Non-existent node

**Call:**
```json
{
  "path": "Ghost"
}
```

**Expected result:** Error from Godot — node not found.

**What to pay attention to:** Verify the correctness of the error message.

---

#### Relationship with other tools

- **Before:** Use `setup_physics_body` and `setup_collision` to create a body with collision shapes.
- **Use case:** Call after `setup_collision` to verify the collision shapes were added correctly.

---

## Tool: `add_raycast`

**Description:** Add a RayCast2D or RayCast3D node.
**Bridge method:** `physics/add_raycast`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `parent_path` | `string` (ParentPath) | **yes** | Parent node — `""` for scene root |
| `properties` | `Record<string, unknown>` (OptionalProperties) | no | Raycast properties (target, enabled, collide_with_areas, etc.) |

**Note:** This is the only physics tool that uses `ParentPath` instead of `NodePath`. The raycast node is created as a **child** of the specified parent.

### Test Scenarios

#### Scenario 1: Happy path — add RayCast3D with target

**Preconditions:** A `CharacterBody3D` node named `"Player"` exists.

**Call:**
```json
{
  "parent_path": "Player",
  "properties": {
    "target_position": [0, -5, 0],
    "enabled": true,
    "collide_with_areas": true
  }
}
```

**Expected result:** Success. A `RayCast3D` node is created as a child of `"Player"` with the given properties.

**What to pay attention to:** Verify that `RayCast3D` appeared as a child of `"Player"`. Check `target_position` via `get_node_properties`.

---

#### Scenario 2: Happy path — add RayCast2D to scene root

**Call:**
```json
{
  "parent_path": "",
  "properties": {
    "target_position": [0, 200],
    "enabled": true
  }
}
```

**Expected result:** Success. A `RayCast2D` is created at the scene root level. The dimension (2D/3D) is likely auto-detected from the scene context.

**What to pay attention to:** Verify that the node was created at the scene root level. Determine how 2D vs 3D is chosen — automatically or by scene type.

---

#### Scenario 3: Minimal call — no properties

**Call:**
```json
{
  "parent_path": "Player"
}
```

**Expected result:** Success. RayCast node created with Godot defaults (enabled=true, target_position=(0,0,0), etc.).

**What to pay attention to:** What type of RayCast is created — 2D or 3D — when no properties are specified? Determine the auto-selection logic.

---

#### Scenario 4: Invalid parent path

**Call:**
```json
{
  "parent_path": "NonExistentParent"
}
```

**Expected result:** Error from Godot — parent node not found.

**What to pay attention to:** The error should be meaningful and indicate an issue with parent_path.

---

#### Scenario 5: Raycast with `collide_with_bodies` disabled

**Call:**
```json
{
  "parent_path": "Player",
  "properties": {
    "target_position": [10, 0, 0],
    "collide_with_bodies": false,
    "collide_with_areas": true
  }
}
```

**Expected result:** Success. Raycast only detects areas, not bodies.

**What to pay attention to:** Verify that `collide_with_bodies` and `collide_with_areas` were applied independently of each other.

---

#### Relationship with other tools

- **Before:** Use `add_node` (from `node.ts`) to create the parent node if needed. Use `open_scene` to ensure the correct scene is active.
- **After:** Use `get_node_properties` (from `node.ts`) to verify raycast properties. Use the testing tools to verify raycast behavior at runtime.
- **Sequence for full physics setup:** `add_node` → `setup_physics_body` → `setup_collision` → `add_raycast` → `set_physics_layers`.

---

## Tool: `get_physics_material`

**Description:** Get the physics material properties of a node.
**Bridge method:** `physics/get_material`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | `string` (NodePath) | **yes** | Node path (no description override — uses raw `NodePath` schema) |

### Test Scenarios

#### Scenario 1: Happy path — get material from node with material set

**Preconditions:** A node `"SlipperySurface"` exists with a physics material set via `set_physics_material`.

**Call:**
```json
{
  "path": "SlipperySurface"
}
```

**Expected result:** Success response containing physics material properties: friction, bounce, rough, absorbent.

**What to pay attention to:** Verify that all 4 properties (friction, bounce, rough, absorbent) are present in the response. Verify that the values match what was set via `set_physics_material`.

---

#### Scenario 2: Node without physics material

**Preconditions:** A physics body node `"Player"` exists but no physics material was set.

**Call:**
```json
{
  "path": "Player"
}
```

**Expected result:** Either success with null/default values, or an error indicating no material is set.

**What to pay attention to:** Determine the behavior — does Godot return a default material or a "no material" error. Record as acceptable behavior.

---

#### Scenario 3: Non-existent node

**Call:**
```json
{
  "path": "DoesNotExist"
}
```

**Expected result:** Error from Godot — node not found.

**What to pay attention to:** Verify the correctness of the error message.

---

#### Relationship with other tools

- **Before:** Use `set_physics_material` to set known material values, then read back with this tool.
- **Verification pattern:** `set_physics_material` → `get_physics_material` → assert values match.

---

## Tool: `set_physics_material`

**Description:** Create and set a physics material on a node.
**Bridge method:** `physics/set_material`

### Parameters

| Name | Type | Required | Description | Constraints |
|---|---|---|---|---|
| `path` | `string` (NodePath) | **yes** | Node path (no description override) | — |
| `friction` | `number` | no | Friction coefficient | `min(0)` |
| `bounce` | `number` | no | Bounce/Restitution coefficient | `min(0)`, `max(1)` |
| `rough` | `boolean` | no | Whether surface is rough | — |
| `absorbent` | `boolean` | no | Whether surface absorbs impact energy | — |

**Note:** All material properties are optional, but calling with no material properties is likely a no-op.

### Test Scenarios

#### Scenario 1: Happy path — set all material properties

**Preconditions:** A `StaticBody3D` node named `"IceFloor"` exists with a physics body.

**Call:**
```json
{
  "path": "IceFloor",
  "friction": 0.05,
  "bounce": 0.1,
  "rough": false,
  "absorbent": false
}
```

**Expected result:** Success. Physics material created with friction=0.05, bounce=0.1, rough=false, absorbent=false.

**What to pay attention to:** Verify all 4 properties via `get_physics_material`. Ensure that the values are exact.

---

#### Scenario 2: Set only friction and bounce (numeric properties)

**Call:**
```json
{
  "path": "BouncyBall",
  "friction": 0.5,
  "bounce": 0.9
}
```

**Expected result:** Success. Friction=0.5, bounce=0.9, rough/absorbent unchanged or default.

**What to pay attention to:** Verify that rough and absorbent were not reset (if they were previously set).

---

#### Scenario 3: Set only boolean properties

**Call:**
```json
{
  "path": "IceFloor",
  "rough": true,
  "absorbent": true
}
```

**Expected result:** Success. Rough=true, absorbent=true, friction/bounce unchanged.

**What to pay attention to:** Verify that numeric properties were not reset.

---

#### Scenario 4: Boundary — bounce = 0 (minimum)

**Call:**
```json
{
  "path": "IceFloor",
  "bounce": 0
}
```

**Expected result:** Success. No bounce at all (perfectly inelastic).

**What to pay attention to:** Boundary value. Should pass validation.

---

#### Scenario 5: Boundary — bounce = 1 (maximum)

**Call:**
```json
{
  "path": "BouncyBall",
  "bounce": 1
}
```

**Expected result:** Success. Perfectly elastic bounce.

**What to pay attention to:** Boundary value. Should pass validation.

---

#### Scenario 6: Invalid — bounce > 1

**Call:**
```json
{
  "path": "BouncyBall",
  "bounce": 1.5
}
```

**Expected result:** Zod validation error — `bounce` must be ≤ 1.

**What to pay attention to:** Verify that Zod rejects values > 1.

---

#### Scenario 7: Invalid — negative friction

**Call:**
```json
{
  "path": "IceFloor",
  "friction": -0.5
}
```

**Expected result:** Zod validation error — `friction` must be ≥ 0.

**What to pay attention to:** Verify that Zod rejects negative values.

---

#### Scenario 8: Boundary — friction = 0

**Call:**
```json
{
  "path": "IceFloor",
  "friction": 0
}
```

**Expected result:** Success. Zero friction.

**What to pay attention to:** Boundary value. Should pass validation.

---

#### Scenario 9: No material properties provided

**Call:**
```json
{
  "path": "IceFloor"
}
```

**Expected result:** Passes Zod validation (all material props are optional). Godot handler may create a default material or do nothing.

**What to pay attention to:** Determine whether a default material is created or this is a no-op.

---

#### Relationship with other tools

- **Before:** The node should have a physics body. Use `setup_physics_body` first.
- **After:** Use `get_physics_material` to verify the applied values.
- **Verification pattern:** `set_physics_material` → `get_physics_material` → assert values match.

---

## Cross-Tool Integration Sequences

### Full Physics Setup Sequence

The recommended order for setting up a complete physics object:

```
1. open_scene("res://scenes/test.tscn")           — ensure scene is active
2. add_node(parent="", name="Player", type="CharacterBody3D")  — create the node
3. setup_physics_body(path="Player", properties={...})          — configure body
4. setup_collision(path="Player", shape_type="capsule", properties={radius: 0.5, height: 2.0})  — add collision
5. set_physics_layers(path="Player", layer=1, mask=2)           — configure layers
6. set_physics_material(path="Player", friction=0.5, bounce=0.1) — add material
7. get_physics_layers(path="Player")                            — verify layers
8. get_physics_material(path="Player")                          — verify material
9. get_collision_info(path="Player")                            — verify collision setup
```

### Layer/Mask Verification Pattern

```
set_physics_layers(path="Enemy", layer=3, mask=7)
→ get_physics_layers(path="Enemy")
→ assert layer == 3 and mask == 7
```

### Material Roundtrip Pattern

```
set_physics_material(path="Ball", friction=0.2, bounce=0.8, rough=false, absorbent=false)
→ get_physics_material(path="Ball")
→ assert friction == 0.2 and bounce == 0.8 and rough == false and absorbent == false
```

### Raycast + Physics Body Combo

```
add_node(parent="", name="Turret", type="StaticBody3D")
→ setup_physics_body(path="Turret", properties={type: "StaticBody3D"})
→ setup_collision(path="Turret", shape_type="box", properties={size: [2, 2, 2]})
→ add_raycast(parent_path="Turret", properties={target_position: [0, 0, -50], enabled: true})
```

---

## Summary Table

| Tool | Required Params | Optional Params | Schema Validation | Godot Validation |
|---|---|---|---|---|
| `setup_physics_body` | `path`, `properties` | — | `path`: string, `properties`: Record | Body type, property keys/values |
| `setup_collision` | `path`, `shape_type` | `properties` | `shape_type`: enum of 9 values | Shape type vs node dimension |
| `set_physics_layers` | `path` | `layer`, `mask` | `layer`/`mask`: int 1-32 | Node must have collision object |
| `get_physics_layers` | `path` | — | `path`: string | Node must have collision object |
| `get_collision_info` | `path` | — | `path`: string | Node must be physics body |
| `add_raycast` | `parent_path` | `properties` | `parent_path`: string | Parent must exist, auto-detect 2D/3D |
| `get_physics_material` | `path` | — | `path`: string | Node must have material |
| `set_physics_material` | `path` | `friction`, `bounce`, `rough`, `absorbent` | `friction`: ≥0, `bounce`: 0-1 | Node must have physics body |
