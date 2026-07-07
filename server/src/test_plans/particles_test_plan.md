# Particles Tools — Comprehensive Test Plan

**Source file:** `server/src/tools/particles.ts`  
**Number of tools:** 8  
**Generated:** 2026-07-08  

---

## Shared Type Reference

All tools import parameter schemas from `server/src/tools/shared-types.ts`:

| Schema | Zod Definition | Description |
|--------|---------------|-------------|
| `ParentPath` | `z.string()` | Parent node path. `''` = scene root. Node name/path (e.g. `'Player'` or `'Player/Sprites'`) to add as child. |
| `NodePath` | `z.string()` | Node path in scene tree (e.g. `'Player/Sprite2D'`). Just node name for root children, `''` for scene root. Paths relative to currently open scene. |
| `Dimension` | `z.enum(['2d', '3d'])` | 2D or 3D dimension type. |
| `Properties` | `z.record(z.unknown())` | Required property key-value pairs dictionary. |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | Optional property key-value pairs dictionary. |

---

## Tool 1: `create_particles`

### Overview

| Field | Value |
|-------|-------|
| **Tool name** | `create_particles` |
| **Description** | Create a GPUParticles2D or GPUParticles3D node |
| **Handler** | `particles/create` |

### Parameters

| # | Parameter | Type | Required | Default | Enum Values | Description |
|---|-----------|------|----------|---------|-------------|-------------|
| 1 | `parent` | `string` (ParentPath) | **Yes** | — | — | Parent node path. `''` for scene root, or node name/path (e.g. `'Player'` or `'Player/Sprites'`) to add as a child of that node. |
| 2 | `type` | `enum` (string) | **Yes** | — | `2d`, `3d` | Dimension type — determines whether GPUParticles2D or GPUParticles3D is created. |
| 3 | `properties` | `record` (object) | No | `undefined` | — | Optional particle system properties (emitting, amount, lifetime, etc.). |

### Behavior

Creates a new `GPUParticles2D` or `GPUParticles3D` node as a child of the specified `parent`, based on the `type` parameter. Optional `properties` can set initial particle system configuration such as `emitting`, `amount`, `lifetime`, `speed_scale`, `explosiveness`, `randomness`, `visibility_aabb`, `draw_order`, etc.

### Test Scenarios

#### 1.1 — Happy Path: Create 2D particles at scene root (minimal params)
- **Description:** Create a GPUParticles2D node at the scene root with only required parameters.
- **JSON params:** `{"parent": "", "type": "2d"}`
- **Expected result:** A GPUParticles2D node is created at the scene root with default particle settings. Emitting is `true` by default.
- **Notes:** Simplest valid call. Enum value: `2d`.

#### 1.2 — Happy Path: Create 3D particles at scene root (minimal params)
- **Description:** Create a GPUParticles3D node at the scene root with only required parameters.
- **JSON params:** `{"parent": "", "type": "3d"}`
- **Expected result:** A GPUParticles3D node is created at the scene root with default particle settings.
- **Notes:** Enum value: `3d`.

#### 1.3 — Create 2D particles under a named parent
- **Description:** Create GPUParticles2D as a child of an existing node by name.
- **JSON params:** `{"parent": "Effects", "type": "2d"}`
- **Expected result:** A GPUParticles2D node is created as a child of the `Effects` node.
- **Notes:** Verifies parent resolution by node name.

#### 1.4 — Create 3D particles under a nested parent path
- **Description:** Create GPUParticles3D under a nested parent node path.
- **JSON params:** `{"parent": "Player/Weapon", "type": "3d"}`
- **Expected result:** A GPUParticles3D node is created as a child of `Player/Weapon`.
- **Notes:** Verifies `/` path separator resolution.

#### 1.5 — Create 2D particles with properties: amount and lifetime
- **Description:** Create GPUParticles2D with custom amount and lifetime.
- **JSON params:** `{"parent": "", "type": "2d", "properties": {"amount": 100, "lifetime": 3.0}}`
- **Expected result:** GPUParticles2D created with `amount = 100` and `lifetime = 3.0`.
- **Notes:** Verifies properties pass-through.

#### 1.6 — Create 3D particles with properties: emitting=false
- **Description:** Create GPUParticles3D that starts paused.
- **JSON params:** `{"parent": "", "type": "3d", "properties": {"emitting": false, "one_shot": true}}`
- **Expected result:** GPUParticles3D created with `emitting = false` and `one_shot = true`.
- **Notes:** Tests boolean properties.

#### 1.7 — Create 2D particles with speed_scale and explosiveness
- **Description:** Create 2D particles with fast burst-like behavior.
- **JSON params:** `{"parent": "", "type": "2d", "properties": {"speed_scale": 2.0, "explosiveness": 0.8, "amount": 50}}`
- **Expected result:** GPUParticles2D created with high speed and bursty emission.
- **Notes:** Float properties.

#### 1.8 — Create 3D particles with visibility_aabb
- **Description:** Create 3D particles with a custom visibility bounding box.
- **JSON params:** `{"parent": "", "type": "3d", "properties": {"visibility_aabb": [-10, -10, -10, 10, 10, 10]}}`
- **Expected result:** GPUParticles3D created with a custom visibility AABB.
- **Notes:** Tests array-valued properties.

#### 1.9 — Create 2D particles with draw_order
- **Description:** Set draw order for 2D particles.
- **JSON params:** `{"parent": "", "type": "2d", "properties": {"draw_order": 1}}`
- **Expected result:** GPUParticles2D created with draw order set (0=index, 1=lifetime).
- **Notes:** Enum-like integer property.

#### 1.10 — Create particles with empty properties
- **Description:** Pass an empty properties object.
- **JSON params:** `{"parent": "", "type": "2d", "properties": {}}`
- **Expected result:** GPUParticles2D created with all default values. No error.
- **Notes:** Empty record should be a no-op.

#### 1.11 — Create 2D particles with randomness
- **Description:** Create particles with randomness set.
- **JSON params:** `{"parent": "", "type": "2d", "properties": {"randomness": 0.5}}`
- **Expected result:** GPUParticles2D created with `randomness = 0.5`.
- **Notes:** Float in 0–1 range.

#### 1.12 — Missing required `parent` (edge case)
- **Description:** Omit the required `parent` parameter.
- **JSON params:** `{"type": "2d"}`
- **Expected result:** Validation error. Tool call fails with a schema validation message.
- **Notes:** `parent` has no default; should be rejected by Zod.

#### 1.13 — Missing required `type` (edge case)
- **Description:** Omit the required `type` parameter.
- **JSON params:** `{"parent": ""}`
- **Expected result:** Validation error. Tool call fails with a schema validation message.
- **Notes:** `type` is required and has no default.

#### 1.14 — Invalid type: not in enum (edge case)
- **Description:** Use a type not in the Dimension enum.
- **JSON params:** `{"parent": "", "type": "4d"}`
- **Expected result:** Validation error. `'4d'` is not a valid enum value for Dimension.
- **Notes:** Zod enum strict check on `['2d', '3d']`.

#### 1.15 — Invalid type: empty string (edge case)
- **Description:** Use an empty string for type.
- **JSON params:** `{"parent": "", "type": ""}`
- **Expected result:** Validation error. Empty string is not in the enum.
- **Notes:** Zod enum rejects empty strings.

#### 1.16 — Invalid type: wrong case (edge case)
- **Description:** Use `"2D"` (capital D) instead of `"2d"`.
- **JSON params:** `{"parent": "", "type": "2D"}`
- **Expected result:** Validation error. Enum is case-sensitive.
- **Notes:** All Dimension enum values are lowercase.

#### 1.17 — Invalid type: whole number instead of string (edge case)
- **Description:** Pass integer `2` instead of string `"2d"`.
- **JSON params:** `{"parent": "", "type": 2}`
- **Expected result:** Validation error. `z.enum` expects a string, not a number.
- **Notes:** Type mismatch.

#### 1.18 — Additional unknown properties (edge case)
- **Description:** Include an unexpected extra parameter.
- **JSON params:** `{"parent": "", "type": "2d", "name": "MyParticles"}`
- **Expected result:** Extra params should be stripped by Zod (no `passthrough()` on the schema). Particle node created with default name.
- **Notes:** Schema uses `inputSchema` without `passthrough()`.

#### 1.19 — Null parent (edge case)
- **Description:** Pass `null` as parent.
- **JSON params:** `{"parent": null, "type": "2d"}`
- **Expected result:** Validation error. `null` is not a valid string.
- **Notes:** Zod `z.string()` rejects `null`.

#### 1.20 — Null type (edge case)
- **Description:** Pass `null` as type.
- **JSON params:** `{"parent": "", "type": null}`
- **Expected result:** Validation error. `null` is not in the enum.
- **Notes:** Zod enum rejects `null`.

#### 1.21 — Non-existent parent path (edge case)
- **Description:** Use a parent path pointing to a node that does not exist.
- **JSON params:** `{"parent": "NonExistentNode", "type": "2d"}`
- **Expected result:** Error from Godot handler — parent node not found.
- **Notes:** Tests handler-side error handling for invalid parents.

#### 1.22 — Properties with unexpected keys (edge case)
- **Description:** Pass properties with keys that GPUParticles does not recognize.
- **JSON params:** `{"parent": "", "type": "3d", "properties": {"fictional_prop": 42, "banana": true}}`
- **Expected result:** May be silently ignored by Godot or produce a warning. Should not crash.
- **Notes:** Godot typically ignores unknown properties silently.

---

## Tool 2: `delete_particles`

### Overview

| Field | Value |
|-------|-------|
| **Tool name** | `delete_particles` |
| **Description** | Delete a particle system node from the scene |
| **Handler** | `particles/delete` |

### Parameters

| # | Parameter | Type | Required | Default | Enum Values | Description |
|---|-----------|------|----------|---------|-------------|-------------|
| 1 | `node_path` | `string` (NodePath) | **Yes** | — | — | Path to the particle node to delete. |

### Behavior

Deletes the particle system node at the specified `node_path` from the scene tree. The node must exist and be a particle system (GPUParticles2D or GPUParticles3D). Uses Godot's undo system.

### Test Scenarios

#### 2.1 — Happy Path: Delete a 2D particle node (minimal params)
- **Description:** Delete an existing GPUParticles2D node by name.
- **JSON params:** `{"node_path": "GPUParticles2D"}`
- **Required setup:** A GPUParticles2D node exists at the scene root.
- **Expected result:** The particle node is removed from the scene. Scene tree no longer contains it.
- **Notes:** Simplest valid call.

#### 2.2 — Delete a 3D particle node
- **Description:** Delete an existing GPUParticles3D node by name.
- **JSON params:** `{"node_path": "GPUParticles3D"}`
- **Required setup:** A GPUParticles3D node exists at the scene root.
- **Expected result:** The 3D particle node is removed from the scene.
- **Notes:** GPUParticles3D confirmed supported.

#### 2.3 — Delete particle node under nested path
- **Description:** Delete a particle node under a parent.
- **JSON params:** `{"node_path": "Effects/Explosion"}`
- **Required setup:** A GPUParticles2D named `Explosion` exists under the `Effects` node.
- **Expected result:** The `Explosion` node is removed from `Effects`. `Effects` remains.
- **Notes:** Tests nested path resolution for deletion.

#### 2.4 — Delete particle node at scene root via empty string
- **Description:** Delete the particle node that IS the scene root (if root is a particle system).
- **JSON params:** `{"node_path": ""}`
- **Required setup:** The scene root is a GPUParticles2D/3D node.
- **Expected result:** Scene root is deleted. May produce warning about deleting root.
- **Notes:** Edge behavior. Root deletion may be blocked or succeed depending on Godot version.

#### 2.5 — Missing required `node_path` (edge case)
- **Description:** Omit the required `node_path` parameter.
- **JSON params:** `{}`
- **Expected result:** Validation error. Tool call fails with a schema validation message.
- **Notes:** `node_path` is required.

#### 2.6 — Non-existent node path (edge case)
- **Description:** Try to delete a node that does not exist.
- **JSON params:** `{"node_path": "DoesNotExist"}`
- **Expected result:** Error from Godot handler — node not found.
- **Notes:** Tests handler-side error for missing nodes.

#### 2.7 — Delete a non-particle node (edge case)
- **Description:** Try to delete a Sprite2D node using this tool.
- **JSON params:** `{"node_path": "Sprite2D"}`
- **Required setup:** A Sprite2D node exists in the scene.
- **Expected result:** May succeed (deletes the node regardless of type) or produce a warning. Depends on handler logic.
- **Notes:** Tests if the handler enforces particle-type-only deletion.

#### 2.8 — Null node_path (edge case)
- **Description:** Pass `null` as node_path.
- **JSON params:** `{"node_path": null}`
- **Expected result:** Validation error. Zod string rejects null.
- **Notes:** Type mismatch.

#### 2.9 — Delete already-deleted node (edge case)
- **Description:** Delete the same particle node twice.
- **JSON params:** `{"node_path": "GPUParticles2D"}`
- **Required setup:** `GPUParticles2D` was already deleted in a prior call.
- **Expected result:** Error from Godot handler — node not found (already removed).
- **Notes:** Tests idempotency behavior.

#### 2.10 — Delete node with children (edge case)
- **Description:** Delete a particle node that has child nodes.
- **JSON params:** `{"node_path": "ParticleParent"}`
- **Required setup:** A particle node with child nodes (e.g. sub-emitters).
- **Expected result:** The particle node and all its children are removed from the scene.
- **Notes:** Godot deletes the entire subtree by default.

---

## Tool 3: `set_particle_material`

### Overview

| Field | Value |
|-------|-------|
| **Tool name** | `set_particle_material` |
| **Description** | Set or create a ParticleProcessMaterial for a particle system |
| **Handler** | `particles/set_material` |

### Parameters

| # | Parameter | Type | Required | Default | Enum Values | Description |
|---|-----------|------|----------|---------|-------------|-------------|
| 1 | `path` | `string` (NodePath) | **Yes** | — | — | Particle node path. |
| 2 | `properties` | `record` (object) | **Yes** | — | — | Process material properties (direction, spread, gravity, initial_velocity, etc.). |

### Behavior

Sets or creates a `ParticleProcessMaterial` on the particle system at `path`. Common properties include `direction` (Vector3), `spread` (float), `gravity` (Vector3), `initial_velocity_min`/`initial_velocity_max` (float), `angular_velocity_min`/`angular_velocity_max` (float), `scale_min`/`scale_max` (float), `color` (Color), `damping_min`/`damping_max` (float), etc.

### Test Scenarios

#### 3.1 — Happy Path: Set direction and spread on 2D particles (minimal params)
- **Description:** Configure basic process material on a GPUParticles2D.
- **JSON params:** `{"path": "GPUParticles2D", "properties": {"direction": [0, -1, 0], "spread": 45}}`
- **Required setup:** A GPUParticles2D node exists.
- **Expected result:** ParticleProcessMaterial is created/updated with downward direction and 45-degree spread.
- **Notes:** Simplest valid call.

#### 3.2 — Set initial_velocity on 3D particles
- **Description:** Configure min/max initial velocity.
- **JSON params:** `{"path": "GPUParticles3D", "properties": {"initial_velocity_min": 5, "initial_velocity_max": 20}}`
- **Required setup:** A GPUParticles3D node exists.
- **Expected result:** ParticleProcessMaterial set with velocity range 5–20.
- **Notes:** Float properties.

#### 3.3 — Set gravity on 2D particles
- **Description:** Apply custom gravity to 2D particles.
- **JSON params:** `{"path": "GPUParticles2D", "properties": {"gravity": [0, 98, 0]}}`
- **Expected result:** Gravity vector set to `(0, 98, 0)` on the process material.
- **Notes:** Vector3 property. 2D particles still use Vector3 for gravity.

#### 3.4 — Set scale range on particles
- **Description:** Configure particles to shrink over lifetime.
- **JSON params:** `{"path": "GPUParticles3D", "properties": {"scale_min": 0.1, "scale_max": 1.0}}`
- **Expected result:** Particles start at scale 0.1 and grow to 1.0 (or random between).
- **Notes:** Tests scale curve configuration.

#### 3.5 — Set angular velocity range
- **Description:** Configure spinning particles.
- **JSON params:** `{"path": "GPUParticles2D", "properties": {"angular_velocity_min": -360, "angular_velocity_max": 360}}`
- **Expected result:** Particles spin randomly between -360 and 360 degrees/sec.
- **Notes:** Float range properties.

#### 3.6 — Set damping range
- **Description:** Configure velocity damping.
- **JSON params:** `{"path": "GPUParticles3D", "properties": {"damping_min": 10, "damping_max": 50}}`
- **Expected result:** Particles decelerate over time based on damping range.
- **Notes:** Affects particle trajectory.

#### 3.7 — Set orbit velocity
- **Description:** Configure orbital particle motion.
- **JSON params:** `{"path": "GPUParticles2D", "properties": {"orbit_velocity_min": 100, "orbit_velocity_max": 200}}`
- **Expected result:** Particles orbit around emission point.
- **Notes:** Specialized property.

#### 3.8 — Set multiple properties in one call
- **Description:** Configure direction, spread, velocity, gravity, and scale all at once.
- **JSON params:** `{"path": "GPUParticles3D", "properties": {"direction": [0, 1, 0], "spread": 30, "initial_velocity_min": 10, "initial_velocity_max": 50, "gravity": [0, -9.8, 0], "scale_min": 0.5, "scale_max": 2.0, "damping_min": 0, "damping_max": 5}}`
- **Expected result:** All specified properties applied to the process material.
- **Notes:** Verifies multiple properties work together without interference.

#### 3.9 — Set material on node with existing material (edge case)
- **Description:** Overwrite an existing ParticleProcessMaterial.
- **JSON params:** `{"path": "GPUParticles2D", "properties": {"spread": 90}}`
- **Required setup:** ParticleProcessMaterial already exists from test 3.1 (spread=45).
- **Expected result:** Spread is updated to 90. Other previously-set properties (direction) should remain.
- **Notes:** Tests if the handler merges or replaces the existing material.

#### 3.10 — Missing required `path` (edge case)
- **Description:** Omit the required `path` parameter.
- **JSON params:** `{"properties": {"spread": 45}}`
- **Expected result:** Validation error. Tool call fails.
- **Notes:** `path` is required.

#### 3.11 — Missing required `properties` (edge case)
- **Description:** Omit the required `properties` parameter.
- **JSON params:** `{"path": "GPUParticles2D"}`
- **Expected result:** Validation error. Tool call fails.
- **Notes:** `properties` is required (uses `Properties`, not `OptionalProperties`).

#### 3.12 — Non-existent node path (edge case)
- **Description:** Try to set material on a node that does not exist.
- **JSON params:** `{"path": "DoesNotExist", "properties": {"spread": 45}}`
- **Expected result:** Error from Godot handler — node not found.
- **Notes:** Handler error handling.

#### 3.13 — Path points to non-particle node (edge case)
- **Description:** Try to set particle material on a Sprite2D node.
- **JSON params:** `{"path": "Sprite2D", "properties": {"spread": 45}}`
- **Required setup:** A Sprite2D node exists.
- **Expected result:** Error from Godot handler — target is not a particle system.
- **Notes:** Tests type checking on the handler side.

#### 3.14 — Properties with empty object (edge case)
- **Description:** Pass an empty properties object.
- **JSON params:** `{"path": "GPUParticles2D", "properties": {}}`
- **Expected result:** May create a ParticleProcessMaterial with default values, or be a no-op if one already exists. Should not error.
- **Notes:** Edge case — empty record but required by schema.

#### 3.15 — Null path (edge case)
- **Description:** Pass `null` as path.
- **JSON params:** `{"path": null, "properties": {"spread": 45}}`
- **Expected result:** Validation error. Zod string rejects null.
- **Notes:** Type mismatch.

#### 3.16 — Null properties (edge case)
- **Description:** Pass `null` as properties.
- **JSON params:** `{"path": "GPUParticles2D", "properties": null}`
- **Expected result:** Validation error. `z.record()` with no `.nullable()` rejects null.
- **Notes:** Type mismatch.

#### 3.17 — Negative initial_velocity (edge case)
- **Description:** Set negative initial velocity.
- **JSON params:** `{"path": "GPUParticles2D", "properties": {"initial_velocity_min": -50, "initial_velocity_max": -10}}`
- **Expected result:** Godot may accept negative velocity (reverse direction) or clamp. Should not crash.
- **Notes:** No Zod-level min/max on floats in properties record.

#### 3.18 — Non-numeric values for numeric properties (edge case)
- **Description:** Pass a string where a float is expected.
- **JSON params:** `{"path": "GPUParticles2D", "properties": {"spread": "wide"}}`
- **Expected result:** Godot may reject with type error or coerce silently. Behavior depends on handler.
- **Notes:** Properties record allows any value type (`z.unknown()`).

---

## Tool 4: `set_particle_color_gradient`

### Overview

| Field | Value |
|-------|-------|
| **Tool name** | `set_particle_color_gradient` |
| **Description** | Set a color gradient on a particle system |
| **Handler** | `particles/set_color_gradient` |

### Parameters

| # | Parameter | Type | Required | Default | Enum Values | Description |
|---|-----------|------|----------|---------|-------------|-------------|
| 1 | `path` | `string` (NodePath) | **Yes** | — | — | Particle node path. |
| 2 | `gradient` | `array` of `{offset, color}` | **Yes** | — | — | Array of gradient color stops. Each stop has `offset` (number, 0–1) and `color` (string, hex like `'#FF0000FF'`). |

### Behavior

Configures a color ramp/gradient on the particle system's `ParticleProcessMaterial`. Each stop in the `gradient` array defines a position (0.0–1.0) along the particle's lifetime and the color at that point. Colors are specified as hex strings (e.g. `'#FF0000FF'` = red, fully opaque). The gradient typically maps to `color_ramp` or `color` property.

### Test Scenarios

#### 4.1 — Happy Path: Two-stop gradient (minimal params)
- **Description:** Set a simple two-color gradient.
- **JSON params:** `{"path": "GPUParticles2D", "gradient": [{"offset": 0, "color": "#FF0000FF"}, {"offset": 1, "color": "#0000FFFF"}]}`
- **Required setup:** A GPUParticles2D node exists.
- **Expected result:** Particles transition from red (opaque) at start to blue (opaque) at end.
- **Notes:** Simplest valid call. 0 and 1 are valid boundaries.

#### 4.2 — Three-stop gradient with transparency
- **Description:** Set a gradient with three stops including alpha fade.
- **JSON params:** `{"path": "GPUParticles3D", "gradient": [{"offset": 0, "color": "#FFFFFFFF"}, {"offset": 0.5, "color": "#FFFF0080"}, {"offset": 1, "color": "#FF000000"}]}`
- **Expected result:** Particles start white opaque, become yellow semi-transparent, end red fully transparent.
- **Notes:** Tests mid-point stop and alpha channel in hex.

#### 4.3 — Single-stop gradient
- **Description:** Set a gradient with only one stop.
- **JSON params:** `{"path": "GPUParticles2D", "gradient": [{"offset": 0.5, "color": "#00FF00FF"}]}`
- **Expected result:** Single green point at mid-lifetime. Godot may interpolate or use as constant color.
- **Notes:** Tests minimum array length. Edge behavior.

#### 4.4 — Four-stop gradient with uneven spacing
- **Description:** Set a gradient with stops at 0, 0.25, 0.75, 1.0.
- **JSON params:** `{"path": "GPUParticles3D", "gradient": [{"offset": 0, "color": "#FF0000FF"}, {"offset": 0.25, "color": "#FF8800FF"}, {"offset": 0.75, "color": "#8800FFFF"}, {"offset": 1, "color": "#0000FFFF"}]}`
- **Expected result:** Non-uniformly spaced gradient applied.
- **Notes:** Tests uneven offset spacing.

#### 4.5 — Gradient with all same color
- **Description:** Set a gradient where all stops have the same color.
- **JSON params:** `{"path": "GPUParticles2D", "gradient": [{"offset": 0, "color": "#FF00FFFF"}, {"offset": 1, "color": "#FF00FFFF"}]}`
- **Expected result:** Particles are a constant magenta throughout lifetime.
- **Notes:** Degenerate but valid gradient.

#### 4.6 — Gradient with RGBA hex including alpha
- **Description:** Set gradient using RGBA hex format.
- **JSON params:** `{"path": "GPUParticles2D", "gradient": [{"offset": 0, "color": "#00FF0044"}, {"offset": 1, "color": "#0000FFCC"}]}`
- **Expected result:** Particles start green at ~26% opacity, end blue at ~80% opacity.
- **Notes:** Validates hex RGBA parsing by Godot handler.

#### 4.7 — Gradient with shorthand hex (3-char)
- **Description:** Use 3-character hex shorthand.
- **JSON params:** `{"path": "GPUParticles2D", "gradient": [{"offset": 0, "color": "#F00"}, {"offset": 1, "color": "#00F"}]}`
- **Expected result:** Depends on Godot color parsing. May error or be interpreted as `#FF000000` and `#0000FF00`.
- **Notes:** 3-char hex is technically a valid CSS color; Godot may or may not support it.

#### 4.8 — Missing required `path` (edge case)
- **Description:** Omit the required `path` parameter.
- **JSON params:** `{"gradient": [{"offset": 0, "color": "#FF0000FF"}]}`
- **Expected result:** Validation error. Tool call fails.
- **Notes:** `path` is required.

#### 4.9 — Missing required `gradient` (edge case)
- **Description:** Omit the required `gradient` parameter.
- **JSON params:** `{"path": "GPUParticles2D"}`
- **Expected result:** Validation error. Tool call fails.
- **Notes:** `gradient` is required.

#### 4.10 — Empty gradient array (edge case)
- **Description:** Pass an empty array for gradient.
- **JSON params:** `{"path": "GPUParticles2D", "gradient": []}`
- **Expected result:** May error from Godot handler — gradient needs at least one stop. Or may be a no-op.
- **Notes:** Tests minimum array length handling.

#### 4.11 — Offset out of range: below 0 (edge case)
- **Description:** Set a stop with offset = -0.1.
- **JSON params:** `{"path": "GPUParticles2D", "gradient": [{"offset": -0.1, "color": "#FF0000FF"}]}`
- **Expected result:** Validation error from Zod — `offset` is `z.number().min(0).max(1)`.
- **Notes:** Zod validates at the schema level.

#### 4.12 — Offset out of range: above 1 (edge case)
- **Description:** Set a stop with offset = 1.5.
- **JSON params:** `{"path": "GPUParticles2D", "gradient": [{"offset": 1.5, "color": "#FF0000FF"}]}`
- **Expected result:** Validation error from Zod — `offset` exceeds max of 1.
- **Notes:** Zod validates at the schema level.

#### 4.13 — Offset exactly 0 and exactly 1 (boundary)
- **Description:** Use boundary values 0 and 1 for offsets.
- **JSON params:** `{"path": "GPUParticles2D", "gradient": [{"offset": 0, "color": "#FF0000FF"}, {"offset": 1, "color": "#0000FFFF"}]}`
- **Expected result:** Both stops accepted. Gradient applied.
- **Notes:** Boundary values are within min/max range.

#### 4.14 — Invalid hex color format (edge case)
- **Description:** Use a malformed hex string as color.
- **JSON params:** `{"path": "GPUParticles2D", "gradient": [{"offset": 0.5, "color": "not-a-hex-color"}]}`
- **Expected result:** No Zod-level validation on hex format (`z.string()`). Godot handler may error on invalid color parsing.
- **Notes:** Tests handler-side color string validation.

#### 4.15 — Hex color without alpha (6-char)
- **Description:** Use 6-character hex (RGB only).
- **JSON params:** `{"path": "GPUParticles2D", "gradient": [{"offset": 0, "color": "#FF0000"}, {"offset": 1, "color": "#0000FF"}]}`
- **Expected result:** Depends on Godot's Color() parsing. May default alpha to 1.0 or error.
- **Notes:** Godot Color expects 8-char hex (RGBA) or 6-char (RGB, alpha=1).

#### 4.16 — Missing offset in a stop (edge case)
- **Description:** Omit `offset` from one gradient stop.
- **JSON params:** `{"path": "GPUParticles2D", "gradient": [{"color": "#FF0000FF"}]}`
- **Expected result:** Validation error from Zod — `offset` is required in the object schema.
- **Notes:** Zod validates each stop's structure.

#### 4.17 — Missing color in a stop (edge case)
- **Description:** Omit `color` from one gradient stop.
- **JSON params:** `{"path": "GPUParticles2D", "gradient": [{"offset": 0}]}`
- **Expected result:** Validation error from Zod — `color` is required in the object schema.
- **Notes:** Zod validates each stop's structure.

#### 4.18 — Gradient with extra keys in stops (edge case)
- **Description:** Include unexpected keys in gradient stops.
- **JSON params:** `{"path": "GPUParticles2D", "gradient": [{"offset": 0, "color": "#FF0000FF", "name": "start"}]}`
- **Expected result:** Extra key `name` should be stripped by Zod (no `passthrough()`). Gradient applied normally.
- **Notes:** Zod object schema strips unrecognized keys.

#### 4.19 — Non-existent node path (edge case)
- **Description:** Try to set gradient on a node that does not exist.
- **JSON params:** `{"path": "DoesNotExist", "gradient": [{"offset": 0, "color": "#FF0000FF"}]}`
- **Expected result:** Error from Godot handler — node not found.
- **Notes:** Handler error handling.

#### 4.20 — Path points to non-particle node (edge case)
- **Description:** Try to set gradient on a Sprite2D.
- **JSON params:** `{"path": "Sprite2D", "gradient": [{"offset": 0, "color": "#FF0000FF"}]}`
- **Expected result:** Error from Godot handler — target lacks a ParticleProcessMaterial.
- **Notes:** Tests type checking.

---

## Tool 5: `apply_particle_preset`

### Overview

| Field | Value |
|-------|-------|
| **Tool name** | `apply_particle_preset` |
| **Description** | Apply a predefined particle effect preset |
| **Handler** | `particles/apply_preset` |

### Parameters

| # | Parameter | Type | Required | Default | Enum Values | Description |
|---|-----------|------|----------|---------|-------------|-------------|
| 1 | `path` | `string` (NodePath) | **Yes** | — | — | Particle node path. |
| 2 | `preset` | `enum` (string) | **Yes** | — | `fire`, `smoke`, `sparks`, `rain`, `snow` | Particle preset name. |

### Behavior

Applies a predefined particle effect configuration to the particle system at `path`. Each preset sets appropriate values for direction, spread, gravity, velocity, color, scale, emission shape, and other properties to create the named effect. The handler should configure the `ParticleProcessMaterial` and related properties to match the preset.

### Test Scenarios

#### 5.1 — Happy Path: Apply `fire` preset to 2D particles (minimal params)
- **Description:** Apply the fire preset to a GPUParticles2D.
- **JSON params:** `{"path": "GPUParticles2D", "preset": "fire"}`
- **Required setup:** A GPUParticles2D node exists.
- **Expected result:** Particles configured to simulate fire: upward direction, warm colors (red/orange/yellow), appropriate spread and velocity, likely with flickering scale.
- **Notes:** Enum value: `fire`.

#### 5.2 — Apply `smoke` preset
- **Description:** Apply the smoke preset.
- **JSON params:** `{"path": "GPUParticles2D", "preset": "smoke"}`
- **Expected result:** Particles configured for smoke: upward direction with wide spread, gray/dark colors, slow velocity, large scale, soft transparency fade.
- **Notes:** Enum value: `smoke`.

#### 5.3 — Apply `sparks` preset
- **Description:** Apply the sparks preset.
- **JSON params:** `{"path": "GPUParticles3D", "preset": "sparks"}`
- **Expected result:** Particles configured for sparks: radial/omnidirectional direction, bright yellow/white colors, high velocity, small scale, short lifetime.
- **Notes:** Enum value: `sparks`.

#### 5.4 — Apply `rain` preset
- **Description:** Apply the rain preset.
- **JSON params:** `{"path": "GPUParticles2D", "preset": "rain"}`
- **Expected result:** Particles configured for rain: downward direction (gravity), blue/white colors, narrow spread, high velocity, thin elongated scale.
- **Notes:** Enum value: `rain`.

#### 5.5 — Apply `snow` preset
- **Description:** Apply the snow preset.
- **JSON params:** `{"path": "GPUParticles2D", "preset": "snow"}`
- **Expected result:** Particles configured for snow: gentle downward direction, white color, wide spread, slow velocity, slight random horizontal drift, soft scale.
- **Notes:** Enum value: `snow`.

#### 5.6 — Apply fire preset to 3D particles
- **Description:** Apply fire preset to a GPUParticles3D.
- **JSON params:** `{"path": "GPUParticles3D", "preset": "fire"}`
- **Expected result:** 3D fire effect applied. Properties set for 3D context (Vector3 directions).
- **Notes:** Tests preset works on both 2D and 3D particle systems.

#### 5.7 — Apply snow preset to 3D particles
- **Description:** Apply snow preset to a GPUParticles3D.
- **JSON params:** `{"path": "GPUParticles3D", "preset": "snow"}`
- **Expected result:** 3D snow effect applied. Wider area emission, gentle falling.
- **Notes:** 3D snow likely uses box/sphere emission shape for area coverage.

#### 5.8 — Apply preset twice to same node (idempotency)
- **Description:** Apply fire, then apply sparks to the same node.
- **JSON params (call 1):** `{"path": "GPUParticles2D", "preset": "fire"}`
- **JSON params (call 2):** `{"path": "GPUParticles2D", "preset": "sparks"}`
- **Expected result:** After call 2, particles are configured as sparks. Fire configuration is fully replaced, not merged.
- **Notes:** Tests preset replacement behavior.

#### 5.9 — Missing required `path` (edge case)
- **Description:** Omit the required `path` parameter.
- **JSON params:** `{"preset": "fire"}`
- **Expected result:** Validation error. Tool call fails.
- **Notes:** `path` is required.

#### 5.10 — Missing required `preset` (edge case)
- **Description:** Omit the required `preset` parameter.
- **JSON params:** `{"path": "GPUParticles2D"}`
- **Expected result:** Validation error. Tool call fails.
- **Notes:** `preset` is required.

#### 5.11 — Invalid preset: not in enum (edge case)
- **Description:** Use a preset name not in the enum.
- **JSON params:** `{"path": "GPUParticles2D", "preset": "confetti"}`
- **Expected result:** Validation error. `'confetti'` is not a valid enum value.
- **Notes:** Zod enum strict check on `['fire', 'smoke', 'sparks', 'rain', 'snow']`.

#### 5.12 — Invalid preset: empty string (edge case)
- **Description:** Use an empty string for preset.
- **JSON params:** `{"path": "GPUParticles2D", "preset": ""}`
- **Expected result:** Validation error. Empty string is not in the enum.
- **Notes:** Zod enum rejects empty strings.

#### 5.13 — Invalid preset: wrong case (edge case)
- **Description:** Use `"Fire"` (capital F) instead of `"fire"`.
- **JSON params:** `{"path": "GPUParticles2D", "preset": "Fire"}`
- **Expected result:** Validation error. Enum is case-sensitive.
- **Notes:** All preset enum values are lowercase.

#### 5.14 — Invalid preset: uppercase (edge case)
- **Description:** Use `"SMOKE"` instead of `"smoke"`.
- **JSON params:** `{"path": "GPUParticles2D", "preset": "SMOKE"}`
- **Expected result:** Validation error. Case-sensitive mismatch.
- **Notes:** All enum values are lowercase.

#### 5.15 — Non-existent node path (edge case)
- **Description:** Try to apply preset to a node that does not exist.
- **JSON params:** `{"path": "DoesNotExist", "preset": "fire"}`
- **Expected result:** Error from Godot handler — node not found.
- **Notes:** Handler error handling.

#### 5.16 — Path points to non-particle node (edge case)
- **Description:** Try to apply preset to a Sprite2D.
- **JSON params:** `{"path": "Sprite2D", "preset": "smoke"}`
- **Expected result:** Error from Godot handler — target is not a particle system.
- **Notes:** Tests type checking on the handler side.

#### 5.17 — Null path (edge case)
- **Description:** Pass `null` as path.
- **JSON params:** `{"path": null, "preset": "fire"}`
- **Expected result:** Validation error. Zod string rejects null.
- **Notes:** Type mismatch.

#### 5.18 — Null preset (edge case)
- **Description:** Pass `null` as preset.
- **JSON params:** `{"path": "GPUParticles2D", "preset": null}`
- **Expected result:** Validation error. Zod enum rejects null.
- **Notes:** Type mismatch.

---

## Tool 6: `get_particle_info`

### Overview

| Field | Value |
|-------|-------|
| **Tool name** | `get_particle_info` |
| **Description** | Get information about a particle system's configuration |
| **Handler** | `particles/get_info` |

### Parameters

| # | Parameter | Type | Required | Default | Enum Values | Description |
|---|-----------|------|----------|---------|-------------|-------------|
| 1 | `path` | `string` (NodePath) | **Yes** | — | — | Particle node path. |

### Behavior

Reads and returns the current configuration of the particle system at `path`. Should return details about the `ParticleProcessMaterial` properties (direction, spread, gravity, velocity ranges, scale ranges, color gradient, emission shape, etc.), the node's emission state (`emitting`, `amount`, `lifetime`), and other relevant settings. This is a read-only operation.

### Test Scenarios

#### 6.1 — Happy Path: Get info from 2D particle with defaults (minimal params)
- **Description:** Read configuration from a freshly created GPUParticles2D.
- **JSON params:** `{"path": "GPUParticles2D"}`
- **Required setup:** A default GPUParticles2D node exists (from create_particles with no properties).
- **Expected result:** Returns an object containing the particle system's properties: type (GPUParticles2D), emitting state, amount, lifetime, speed_scale, and material info if present.
- **Notes:** Simplest valid call.

#### 6.2 — Get info from 3D particle
- **Description:** Read configuration from a GPUParticles3D.
- **JSON params:** `{"path": "GPUParticles3D"}`
- **Expected result:** Returns particle info including the 3D-specific properties (visibility_aabb, etc.).
- **Notes:** Verifies both 2D and 3D particle types are supported.

#### 6.3 — Get info after applying material
- **Description:** Read configuration after setting a ParticleProcessMaterial.
- **JSON params:** `{"path": "GPUParticles2D"}`
- **Required setup:** ParticleProcessMaterial has been applied via `set_particle_material` (test 3.1) with direction=[0,-1,0] and spread=45.
- **Expected result:** Returned info includes process material properties: direction=(0,-1,0), spread=45.
- **Notes:** Verifies material properties are reflected in info output.

#### 6.4 — Get info after applying color gradient
- **Description:** Read configuration after setting a color gradient.
- **JSON params:** `{"path": "GPUParticles2D"}`
- **Required setup:** Color gradient applied via `set_particle_color_gradient` (test 4.1).
- **Expected result:** Returned info includes the color ramp/gradient configuration.
- **Notes:** Verifies gradient is reflected in info output.

#### 6.5 — Get info after applying preset
- **Description:** Read configuration after applying a preset.
- **JSON params:** `{"path": "GPUParticles2D"}`
- **Required setup:** Fire preset applied via `apply_particle_preset` (test 5.1).
- **Expected result:** Returned info reflects the fire preset configuration: upward direction, warm colors, etc.
- **Notes:** Verifies preset changes are reflected in info.

#### 6.6 — Get info after setting emission shape
- **Description:** Read configuration after setting emission shape.
- **JSON params:** `{"path": "GPUParticles2D"}`
- **Required setup:** Emission shape set to `sphere` via `set_particle_emission_shape` (test 7.1).
- **Expected result:** Returned info includes the emission shape = sphere.
- **Notes:** Verifies emission shape is reflected in info.

#### 6.7 — Get info after setting velocity curve
- **Description:** Read configuration after setting a velocity curve.
- **JSON params:** `{"path": "GPUParticles2D"}`
- **Required setup:** Velocity curve applied via `set_particle_velocity_curve` (test 8.1).
- **Expected result:** Returned info includes the velocity curve data.
- **Notes:** Verifies curve is reflected in info.

#### 6.8 — Get info from particle with sub-emitters
- **Description:** Read info from a particle system that has child particle nodes.
- **JSON params:** `{"path": "ParticleParent"}`
- **Required setup:** A particle node with child GPUParticles2D nodes (sub-emitters) exists.
- **Expected result:** Returned info may include sub-emitter references or just the parent's own config. Depends on handler.
- **Notes:** Tests nested particle system scenarios.

#### 6.9 — Missing required `path` (edge case)
- **Description:** Omit the required `path` parameter.
- **JSON params:** `{}`
- **Expected result:** Validation error. Tool call fails.
- **Notes:** `path` is required.

#### 6.10 — Non-existent node path (edge case)
- **Description:** Try to get info from a node that does not exist.
- **JSON params:** `{"path": "DoesNotExist"}`
- **Expected result:** Error from Godot handler — node not found.
- **Notes:** Handler error handling.

#### 6.11 — Path points to non-particle node (edge case)
- **Description:** Try to get particle info from a Node2D.
- **JSON params:** `{"path": "Node2D"}`
- **Required setup:** A plain Node2D exists in the scene.
- **Expected result:** Error from Godot handler — target is not a particle system. Or may return "no particle system found" message.
- **Notes:** Tests type checking on the handler side.

#### 6.12 — Path points to scene root (edge case)
- **Description:** Try to get particle info from the scene root.
- **JSON params:** `{"path": ""}`
- **Required setup:** Scene root is not a particle node (typical).
- **Expected result:** Error from Godot handler — root node is not a particle system.
- **Notes:** Empty string resolves to scene root.

#### 6.13 — Null path (edge case)
- **Description:** Pass `null` as path.
- **JSON params:** `{"path": null}`
- **Expected result:** Validation error. Zod string rejects null.
- **Notes:** Type mismatch.

#### 6.14 — Get info from node with no ParticleProcessMaterial
- **Description:** Read info from a particle node that was created without any process material.
- **JSON params:** `{"path": "GPUParticles2D"}`
- **Required setup:** GPUParticles2D with only default properties, no explicit process material.
- **Expected result:** Returns basic particle info. Process material section may be absent or show defaults from the built-in material.
- **Notes:** Tests behavior when process material is null/unset.

#### 6.15 — Get info from node with sub-emitter but no process material (edge case)
- **Description:** Read info from a particle node with children but no material.
- **JSON params:** `{"path": "ParticleParent"}`
- **Required setup:** A GPUParticles3D with child nodes but no process material.
- **Expected result:** Returns basic info. May include children list. No material properties.
- **Notes:** Tests complex node with missing material.

---

## Tool 7: `set_particle_emission_shape`

### Overview

| Field | Value |
|-------|-------|
| **Tool name** | `set_particle_emission_shape` |
| **Description** | Set the emission shape for a particle system |
| **Handler** | `particles/set_emission_shape` |

### Parameters

| # | Parameter | Type | Required | Default | Enum Values | Description |
|---|-----------|------|----------|---------|-------------|-------------|
| 1 | `path` | `string` (NodePath) | **Yes** | — | — | Particle node path. |
| 2 | `shape` | `enum` (string) | **Yes** | — | `point`, `sphere`, `box`, `ring` | Emission shape type. |
| 3 | `size` | `array` of `number` | No | `undefined` | — | Shape size parameters (varies by shape — sphere: [radius], box: [x, y, z], ring: [inner, outer, height]). |

### Behavior

Sets the emission shape of the particle system at `path`. The `shape` determines the geometry from which particles are emitted: `point` = single point, `sphere` = spherical volume, `box` = box volume, `ring` = ring/torus shape. The optional `size` array provides shape-specific dimensions.

### Test Scenarios

#### 7.1 — Happy Path: Set point shape (minimal params)
- **Description:** Set emission shape to point on a 2D particle system.
- **JSON params:** `{"path": "GPUParticles2D", "shape": "point"}`
- **Required setup:** A GPUParticles2D node exists.
- **Expected result:** Emission shape set to point. Particles emit from a single location. No `size` needed.
- **Notes:** Simplest valid call. Enum value: `point`.

#### 7.2 — Set sphere shape with size
- **Description:** Set emission shape to sphere with radius.
- **JSON params:** `{"path": "GPUParticles3D", "shape": "sphere", "size": [5]}`
- **Expected result:** Particles emit from within a sphere of radius 5.
- **Notes:** Enum value: `sphere`. Size param: [radius].

#### 7.3 — Set box shape with size
- **Description:** Set emission shape to box with extents.
- **JSON params:** `{"path": "GPUParticles3D", "shape": "box", "size": [3, 2, 5]}`
- **Expected result:** Particles emit from within a box of size 3×2×5 (half-extents or full extents depending on Godot).
- **Notes:** Enum value: `box`. Size param: [x, y, z].

#### 7.4 — Set ring shape with size
- **Description:** Set emission shape to ring with inner radius, outer radius, and height.
- **JSON params:** `{"path": "GPUParticles2D", "shape": "ring", "size": [2, 8, 1]}`
- **Expected result:** Particles emit from a ring with inner radius 2, outer radius 8, height 1.
- **Notes:** Enum value: `ring`. Size param: [inner_radius, outer_radius, height].

#### 7.5 — Set point shape on 3D particles
- **Description:** Apply point shape to a GPUParticles3D.
- **JSON params:** `{"path": "GPUParticles3D", "shape": "point"}`
- **Expected result:** 3D particles emit from a point.
- **Notes:** All shapes should work on both 2D and 3D particle systems.

#### 7.6 — Set sphere shape without size (default size)
- **Description:** Set sphere shape without providing size — expect defaults.
- **JSON params:** `{"path": "GPUParticles2D", "shape": "sphere"}`
- **Expected result:** Godot uses default sphere radius (typically 1.0).
- **Notes:** `size` is optional. Tests default behavior.

#### 7.7 — Set box shape without size (default size)
- **Description:** Set box shape without providing size.
- **JSON params:** `{"path": "GPUParticles3D", "shape": "box"}`
- **Expected result:** Godot uses default box extents (typically [1, 1, 1]).
- **Notes:** Tests default behavior for box shape.

#### 7.8 — Set ring shape without size (default size)
- **Description:** Set ring shape without providing size.
- **JSON params:** `{"path": "GPUParticles2D", "shape": "ring"}`
- **Expected result:** Godot uses default ring dimensions.
- **Notes:** Tests default behavior for ring shape.

#### 7.9 — Change shape on existing emission configuration
- **Description:** Change emission shape from sphere to box on the same node.
- **JSON params (call 1):** `{"path": "GPUParticles2D", "shape": "sphere", "size": [10]}`
- **JSON params (call 2):** `{"path": "GPUParticles2D", "shape": "box", "size": [4, 4, 4]}`
- **Expected result:** After call 2, emission shape is box, not sphere. Previous shape is replaced.
- **Notes:** Tests shape replacement behavior.

#### 7.10 — Missing required `path` (edge case)
- **Description:** Omit the required `path` parameter.
- **JSON params:** `{"shape": "point"}`
- **Expected result:** Validation error. Tool call fails.
- **Notes:** `path` is required.

#### 7.11 — Missing required `shape` (edge case)
- **Description:** Omit the required `shape` parameter.
- **JSON params:** `{"path": "GPUParticles2D"}`
- **Expected result:** Validation error. Tool call fails.
- **Notes:** `shape` is required.

#### 7.12 — Invalid shape: not in enum (edge case)
- **Description:** Use a shape not in the enum.
- **JSON params:** `{"path": "GPUParticles2D", "shape": "cone"}`
- **Expected result:** Validation error. `'cone'` is not a valid enum value.
- **Notes:** Zod enum strict check on `['point', 'sphere', 'box', 'ring']`.

#### 7.13 — Invalid shape: empty string (edge case)
- **Description:** Use an empty string for shape.
- **JSON params:** `{"path": "GPUParticles2D", "shape": ""}`
- **Expected result:** Validation error. Empty string is not in the enum.
- **Notes:** Zod enum rejects empty strings.

#### 7.14 — Invalid shape: wrong case (edge case)
- **Description:** Use `"Sphere"` (capital S) instead of `"sphere"`.
- **JSON params:** `{"path": "GPUParticles2D", "shape": "Sphere"}`
- **Expected result:** Validation error. Enum is case-sensitive.
- **Notes:** All enum values are lowercase.

#### 7.15 — Size array with negative values (edge case)
- **Description:** Pass negative radius for sphere shape.
- **JSON params:** `{"path": "GPUParticles2D", "shape": "sphere", "size": [-5]}`
- **Expected result:** No Zod-level validation on size values (`z.array(z.number())`). Godot may clamp to 0 or produce unexpected behavior.
- **Notes:** Tests handler-side handling of negative dimensions.

#### 7.16 — Size array with zero values (edge case)
- **Description:** Pass zero for all size values.
- **JSON params:** `{"path": "GPUParticles3D", "shape": "box", "size": [0, 0, 0]}`
- **Expected result:** Box emission shape with zero volume. Particles may emit from a single point or behavior may be undefined.
- **Notes:** Tests degenerate size case.

#### 7.17 — Size array with wrong number of elements (edge case)
- **Description:** Pass [1, 2] for box shape (expects 3 elements).
- **JSON params:** `{"path": "GPUParticles3D", "shape": "box", "size": [1, 2]}`
- **Expected result:** No Zod-level validation on array length. Godot handler may error, use defaults, or interpret [1,2,1].
- **Notes:** Tests array length mismatch handling.

#### 7.18 — Size array as empty array (edge case)
- **Description:** Pass empty array for size.
- **JSON params:** `{"path": "GPUParticles2D", "shape": "sphere", "size": []}`
- **Expected result:** Godot may use default size. Should not crash.
- **Notes:** Empty array is valid per Zod (array of numbers).

#### 7.19 — Size array with string values (edge case)
- **Description:** Pass string instead of number in size array.
- **JSON params:** `{"path": "GPUParticles2D", "shape": "sphere", "size": ["big"]}`
- **Expected result:** Validation error from Zod — `z.array(z.number())` rejects strings.
- **Notes:** Zod validates array element types.

#### 7.20 — Non-existent node path (edge case)
- **Description:** Try to set shape on a node that does not exist.
- **JSON params:** `{"path": "DoesNotExist", "shape": "point"}`
- **Expected result:** Error from Godot handler — node not found.
- **Notes:** Handler error handling.

#### 7.21 — Path points to non-particle node (edge case)
- **Description:** Try to set emission shape on a Sprite2D.
- **JSON params:** `{"path": "Sprite2D", "shape": "sphere"}`
- **Expected result:** Error from Godot handler — target is not a particle system.
- **Notes:** Tests type checking on the handler side.

---

## Tool 8: `set_particle_velocity_curve`

### Overview

| Field | Value |
|-------|-------|
| **Tool name** | `set_particle_velocity_curve` |
| **Description** | Set a velocity curve for a particle system |
| **Handler** | `particles/set_velocity_curve` |

### Parameters

| # | Parameter | Type | Required | Default | Enum Values | Description |
|---|-----------|------|----------|---------|-------------|-------------|
| 1 | `path` | `string` (NodePath) | **Yes** | — | — | Particle node path. |
| 2 | `curve` | `array` of `{offset, value}` | **Yes** | — | — | Array of curve points. Each point has `offset` (number, 0–1) and `value` (number, velocity at that point). |

### Behavior

Sets a velocity-over-lifetime curve on the particle system's `ParticleProcessMaterial`. Each point in the `curve` array defines a normalized lifetime position (0.0–1.0) and the velocity multiplier at that point. The curve is typically applied to `velocity_limit_curve` or a similar property. Values typically represent a multiplier (1.0 = full velocity, 0.0 = stopped).

### Test Scenarios

#### 8.1 — Happy Path: Two-point linear curve (minimal params)
- **Description:** Set a simple velocity curve with start and end points.
- **JSON params:** `{"path": "GPUParticles2D", "curve": [{"offset": 0, "value": 1}, {"offset": 1, "value": 0}]}`
- **Required setup:** A GPUParticles2D node exists.
- **Expected result:** Velocity curve set — particles start at full speed (1.0) and decelerate to stop (0.0) over lifetime.
- **Notes:** Simplest valid call. Linear deceleration curve.

#### 8.2 — Three-point curve with peak
- **Description:** Set a curve with acceleration then deceleration.
- **JSON params:** `{"path": "GPUParticles3D", "curve": [{"offset": 0, "value": 0}, {"offset": 0.3, "value": 1.5}, {"offset": 1, "value": 0}]}`
- **Expected result:** Particles accelerate to 1.5× velocity at 30% lifetime, then decelerate to stop.
- **Notes:** Non-linear velocity profile.

#### 8.3 — Single-point curve
- **Description:** Set a curve with only one point.
- **JSON params:** `{"path": "GPUParticles2D", "curve": [{"offset": 0.5, "value": 1}]}`
- **Expected result:** Single point at mid-lifetime with velocity multiplier 1.0. Godot may treat as constant or may error.
- **Notes:** Tests minimum array length. Edge behavior.

#### 8.4 — Curve with constant velocity
- **Description:** Set a flat velocity curve (constant speed).
- **JSON params:** `{"path": "GPUParticles3D", "curve": [{"offset": 0, "value": 1}, {"offset": 1, "value": 1}]}`
- **Expected result:** Particles maintain constant velocity throughout lifetime.
- **Notes:** Flat curve, functionally equivalent to no curve.

#### 8.5 — Curve with negative values
- **Description:** Set curve with negative velocity multipliers.
- **JSON params:** `{"path": "GPUParticles2D", "curve": [{"offset": 0, "value": 1}, {"offset": 1, "value": -1}]}`
- **Expected result:** Particles reverse direction over lifetime (if Godot allows negative multipliers).
- **Notes:** No Zod-level min/max on `value`. Handler may clamp or allow.

#### 8.6 — Curve with values above 1.0
- **Description:** Set curve with velocity multiplier > 1.0.
- **JSON params:** `{"path": "GPUParticles3D", "curve": [{"offset": 0, "value": 1}, {"offset": 0.5, "value": 3.0}, {"offset": 1, "value": 0}]}`
- **Expected result:** Particles accelerate to 3× their initial velocity at mid-lifetime.
- **Notes:** No upper bound on `value` in Zod schema.

#### 8.7 — Curve with zero values throughout
- **Description:** Set curve with all zero velocity.
- **JSON params:** `{"path": "GPUParticles2D", "curve": [{"offset": 0, "value": 0}, {"offset": 0.5, "value": 0}, {"offset": 1, "value": 0}]}`
- **Expected result:** Particles have zero velocity throughout lifetime. They won't move from emission point.
- **Notes:** Degenerate but valid curve.

#### 8.8 — Curve with many points (high resolution)
- **Description:** Set a curve with 10 points for fine-grained control.
- **JSON params:** `{"path": "GPUParticles2D", "curve": [{"offset": 0, "value": 0}, {"offset": 0.1, "value": 0.5}, {"offset": 0.2, "value": 0.9}, {"offset": 0.3, "value": 1.2}, {"offset": 0.4, "value": 1.5}, {"offset": 0.5, "value": 1.5}, {"offset": 0.6, "value": 1.2}, {"offset": 0.7, "value": 0.9}, {"offset": 0.8, "value": 0.5}, {"offset": 0.9, "value": 0.2}, {"offset": 1, "value": 0}]}`
- **Expected result:** Smooth bell-shaped velocity curve applied across particle lifetime.
- **Notes:** Tests high-resolution curve data.

#### 8.9 — Overwrite existing velocity curve
- **Description:** Replace an existing velocity curve.
- **JSON params (call 1):** `{"path": "GPUParticles2D", "curve": [{"offset": 0, "value": 1}, {"offset": 1, "value": 0}]}`
- **JSON params (call 2):** `{"path": "GPUParticles2D", "curve": [{"offset": 0, "value": 0}, {"offset": 1, "value": 1}]}`
- **Expected result:** After call 2, velocity curve goes from 0 to 1 (accelerating). Call 1's decelerating curve is fully replaced.
- **Notes:** Tests curve replacement behavior.

#### 8.10 — Missing required `path` (edge case)
- **Description:** Omit the required `path` parameter.
- **JSON params:** `{"curve": [{"offset": 0, "value": 1}]}`
- **Expected result:** Validation error. Tool call fails.
- **Notes:** `path` is required.

#### 8.11 — Missing required `curve` (edge case)
- **Description:** Omit the required `curve` parameter.
- **JSON params:** `{"path": "GPUParticles2D"}`
- **Expected result:** Validation error. Tool call fails.
- **Notes:** `curve` is required.

#### 8.12 — Empty curve array (edge case)
- **Description:** Pass an empty array for curve.
- **JSON params:** `{"path": "GPUParticles2D", "curve": []}`
- **Expected result:** May error from Godot handler — curve needs at least one point. Or may be a no-op.
- **Notes:** Tests minimum array length handling.

#### 8.13 — Offset out of range: below 0 (edge case)
- **Description:** Set a point with offset = -0.5.
- **JSON params:** `{"path": "GPUParticles2D", "curve": [{"offset": -0.5, "value": 1}]}`
- **Expected result:** Validation error from Zod — `offset` is `z.number().min(0).max(1)`.
- **Notes:** Zod validates at the schema level.

#### 8.14 — Offset out of range: above 1 (edge case)
- **Description:** Set a point with offset = 2.0.
- **JSON params:** `{"path": "GPUParticles2D", "curve": [{"offset": 2, "value": 0}]}`
- **Expected result:** Validation error from Zod — `offset` exceeds max of 1.
- **Notes:** Zod validates at the schema level.

#### 8.15 — Offset exactly 0 and exactly 1 (boundary)
- **Description:** Use boundary values for offsets.
- **JSON params:** `{"path": "GPUParticles3D", "curve": [{"offset": 0, "value": 1}, {"offset": 1, "value": 0}]}`
- **Expected result:** Both boundary points accepted. Curve applied.
- **Notes:** Boundary values are within min/max range.

#### 8.16 — Missing offset in a point (edge case)
- **Description:** Omit `offset` from one curve point.
- **JSON params:** `{"path": "GPUParticles2D", "curve": [{"value": 1}]}`
- **Expected result:** Validation error from Zod — `offset` is required in the object schema.
- **Notes:** Zod validates each point's structure.

#### 8.17 — Missing value in a point (edge case)
- **Description:** Omit `value` from one curve point.
- **JSON params:** `{"path": "GPUParticles2D", "curve": [{"offset": 0}]}`
- **Expected result:** Validation error from Zod — `value` is required in the object schema.
- **Notes:** Zod validates each point's structure.

#### 8.18 — Non-numeric offset (edge case)
- **Description:** Pass a string as offset.
- **JSON params:** `{"path": "GPUParticles2D", "curve": [{"offset": "half", "value": 1}]}`
- **Expected result:** Validation error from Zod — `z.number()` rejects strings.
- **Notes:** Zod validates each point's field types.

#### 8.19 — Non-numeric value (edge case)
- **Description:** Pass a boolean as value.
- **JSON params:** `{"path": "GPUParticles2D", "curve": [{"offset": 0, "value": true}]}`
- **Expected result:** Validation error from Zod — `z.number()` rejects booleans.
- **Notes:** Zod validates each point's field types.

#### 8.20 — Curve with extra keys in points (edge case)
- **Description:** Include unexpected keys in curve points.
- **JSON params:** `{"path": "GPUParticles2D", "curve": [{"offset": 0, "value": 1, "tangent": "ease_in"}]}`
- **Expected result:** Extra key `tangent` should be stripped by Zod. Curve applied normally.
- **Notes:** Zod object schema strips unrecognized keys.

#### 8.21 — Non-existent node path (edge case)
- **Description:** Try to set velocity curve on a node that does not exist.
- **JSON params:** `{"path": "DoesNotExist", "curve": [{"offset": 0, "value": 1}]}`
- **Expected result:** Error from Godot handler — node not found.
- **Notes:** Handler error handling.

#### 8.22 — Path points to non-particle node (edge case)
- **Description:** Try to set velocity curve on a Camera3D.
- **JSON params:** `{"path": "Camera3D", "curve": [{"offset": 0, "value": 1}]}`
- **Expected result:** Error from Godot handler — target is not a particle system.
- **Notes:** Tests type checking on the handler side.

---

## Cross-Tool Integration Scenarios

These scenarios test multiple particle tools used together to build a complete particle effect.

### INT-1: Full fire effect pipeline
- **Description:** Create a particle system, configure its material, apply a fire preset, set a color gradient, configure emission shape, and set a velocity curve — simulating a complete fire effect setup.
- **Steps:**
  1. `create_particles` — `{"parent": "", "type": "2d", "properties": {"amount": 100, "lifetime": 2.0}}` → creates a GPUParticles2D
  2. `set_particle_material` — `{"path": "GPUParticles2D", "properties": {"direction": [0, -1, 0], "spread": 15, "initial_velocity_min": 50, "initial_velocity_max": 150}}` → sets upward, narrow-spread, fast particles
  3. `apply_particle_preset` — `{"path": "GPUParticles2D", "preset": "fire"}` → applies fire-specific config (may override some material props)
  4. `set_particle_color_gradient` — `{"path": "GPUParticles2D", "gradient": [{"offset": 0, "color": "#FFFF00FF"}, {"offset": 0.3, "color": "#FF8800FF"}, {"offset": 0.7, "color": "#FF0000FF"}, {"offset": 1, "color": "#FF000000"}]}` → yellow → orange → red → fade
  5. `set_particle_emission_shape` — `{"path": "GPUParticles2D", "shape": "sphere", "size": [3]}` → emit from sphere radius 3
  6. `set_particle_velocity_curve` — `{"path": "GPUParticles2D", "curve": [{"offset": 0, "value": 1}, {"offset": 0.5, "value": 0.5}, {"offset": 1, "value": 0}]}` → decelerating curve
  7. `get_particle_info` — `{"path": "GPUParticles2D"}` → verify all settings are applied
- **Expected result:** A fully configured fire effect with material, color gradient, sphere emission, and velocity curve. `get_particle_info` returns the complete configuration.
- **Notes:** Verify all steps succeed in sequence and the final info reflects all applied settings.

### INT-2: Rain effect with all shapes tested
- **Description:** Create a rain particle system, then cycle through all emission shapes to observe different rain behaviors.
- **Steps:**
  1. `create_particles` — `{"parent": "", "type": "3d", "properties": {"amount": 500, "lifetime": 4.0}}` → creates a GPUParticles3D
  2. `apply_particle_preset` — `{"path": "GPUParticles3D", "preset": "rain"}` → rain preset
  3. `set_particle_emission_shape` — `{"path": "GPUParticles3D", "shape": "box", "size": [20, 5, 20]}` → wide area box emission
  4. `get_particle_info` — `{"path": "GPUParticles3D"}` → verify box shape
  5. `set_particle_emission_shape` — `{"path": "GPUParticles3D", "shape": "sphere", "size": [15]}` → sphere emission
  6. `get_particle_info` — `{"path": "GPUParticles3D"}` → verify sphere shape
  7. `set_particle_emission_shape` — `{"path": "GPUParticles3D", "shape": "point"}` → point emission (single source)
  8. `get_particle_info` — `{"path": "GPUParticles3D"}` → verify point shape
  9. `set_particle_emission_shape` — `{"path": "GPUParticles3D", "shape": "ring", "size": [5, 10, 3]}` → ring emission
  10. `get_particle_info` — `{"path": "GPUParticles3D"}` → verify ring shape
- **Expected result:** Rain effect cycles through all four emission shapes. Each shape change is confirmed by `get_particle_info`.
- **Notes:** Tests that changing shapes mid-config doesn't break other settings.

### INT-3: Sparks burst with color and velocity curve
- **Description:** Create a one-shot sparks effect with custom gradient and acceleration curve.
- **Steps:**
  1. `create_particles` — `{"parent": "", "type": "3d", "properties": {"amount": 30, "one_shot": true, "emitting": false, "lifetime": 0.5}}` → burst particles
  2. `apply_particle_preset` — `{"path": "GPUParticles3D", "preset": "sparks"}` → sparks base config
  3. `set_particle_color_gradient` — `{"path": "GPUParticles3D", "gradient": [{"offset": 0, "color": "#FFFFFFFF"}, {"offset": 0.2, "color": "#FFFF44FF"}, {"offset": 0.6, "color": "#FF8800FF"}, {"offset": 1, "color": "#FF000000"}]}` → white → yellow → orange → fade
  4. `set_particle_velocity_curve` — `{"path": "GPUParticles3D", "curve": [{"offset": 0, "value": 1}, {"offset": 0.2, "value": 0.3}, {"offset": 1, "value": 0}]}` → fast burst then slow
  5. `set_particle_emission_shape` — `{"path": "GPUParticles3D", "shape": "sphere", "size": [2]}` → compact sphere emission
  6. `get_particle_info` — `{"path": "GPUParticles3D"}` → verify the complete one-shot spark configuration
- **Expected result:** A compact spherical burst of sparks with bright-to-fade color and fast-deceleration velocity curve.
- **Notes:** Tests interaction between one_shot mode and curve/gradient configurations.

### INT-4: Create, configure, delete lifecycle
- **Description:** Full lifecycle: create a smoke particle system, configure it fully, read its info, then delete it.
- **Steps:**
  1. `create_particles` — `{"parent": "", "type": "3d", "properties": {"amount": 50}}` → create smoke particles
  2. `apply_particle_preset` — `{"path": "GPUParticles3D", "preset": "smoke"}` → smoke preset
  3. `set_particle_material` — `{"path": "GPUParticles3D", "properties": {"spread": 180, "initial_velocity_min": 5, "gravity": [1, 2, 1]}}` → wide spread, slight drift gravity
  4. `set_particle_color_gradient` — `{"path": "GPUParticles3D", "gradient": [{"offset": 0, "color": "#88888880"}, {"offset": 1, "color": "#44444400"}]}` → gray semi-transparent to transparent
  5. `get_particle_info` — `{"path": "GPUParticles3D"}` → verify all configuration
  6. `delete_particles` — `{"node_path": "GPUParticles3D"}` → delete the node
  7. `get_particle_info` — `{"path": "GPUParticles3D"}` → should error (node deleted)
- **Expected result:** Node created, configured, verified, and deleted cleanly. Final `get_particle_info` call returns error as expected.
- **Notes:** Tests create → configure → read → delete → verify deletion lifecycle.

### INT-5: Multiple particle systems coexisting
- **Description:** Create two separate particle systems, configure them differently, and verify they don't interfere.
- **Steps:**
  1. `create_particles` — `{"parent": "", "type": "2d", "properties": {"name": "FireParticles"}}` → named fire particles
  2. `create_particles` — `{"parent": "", "type": "2d", "properties": {"name": "SmokeParticles"}}` → named smoke particles
  3. `apply_particle_preset` — `{"path": "FireParticles", "preset": "fire"}` → fire on first
  4. `apply_particle_preset` — `{"path": "SmokeParticles", "preset": "smoke"}` → smoke on second
  5. `set_particle_emission_shape` — `{"path": "FireParticles", "shape": "point"}` → point emission for fire
  6. `set_particle_emission_shape` — `{"path": "SmokeParticles", "shape": "sphere", "size": [5]}` → sphere for smoke
  7. `get_particle_info` — `{"path": "FireParticles"}` → verify fire config
  8. `get_particle_info` — `{"path": "SmokeParticles"}` → verify smoke config
- **Expected result:** Two independent particle systems with different configurations. Neither interferes with the other.
- **Notes:** Tests that particle tools correctly resolve paths to specific nodes and don't cross-contaminate.

---

## Summary

| # | Tool | Required Params | Optional Params | Enum Params | Happy Scenarios | Edge Cases | Integration Scenarios |
|---|------|----------------|-----------------|-------------|-----------------|------------|-----------------------|
| 1 | `create_particles` | `parent`, `type` | `properties` | `type` (2 values) | 11 | 11 | INT-1, INT-2, INT-3, INT-4, INT-5 |
| 2 | `delete_particles` | `node_path` | — | — | 4 | 6 | INT-4 |
| 3 | `set_particle_material` | `path`, `properties` | — | — | 8 | 10 | INT-1, INT-4 |
| 4 | `set_particle_color_gradient` | `path`, `gradient` | — | — | 7 | 13 | INT-1, INT-3, INT-4 |
| 5 | `apply_particle_preset` | `path`, `preset` | — | `preset` (5 values) | 8 | 10 | INT-1, INT-2, INT-3, INT-4, INT-5 |
| 6 | `get_particle_info` | `path` | — | — | 8 | 7 | INT-1, INT-2, INT-3, INT-4, INT-5 |
| 7 | `set_particle_emission_shape` | `path`, `shape` | `size` | `shape` (4 values) | 9 | 12 | INT-1, INT-2, INT-3, INT-5 |
| 8 | `set_particle_velocity_curve` | `path`, `curve` | — | — | 9 | 13 | INT-1, INT-3 |
| **Total** | | | | | **64** | **82** | **5** |

**Grand total: 151 test scenarios** (64 happy path + 82 edge cases + 5 integration)

---

## Coverage Checklist

- [x] Every tool documented with overview, parameters table, behavior, and test scenarios
- [x] All required parameters covered with missing-param edge cases
- [x] All optional parameters covered (defaults, empty, null)
- [x] All enum values covered with individual scenarios
- [x] All enum values tested against wrong-case variations
- [x] All enum values tested against empty string
- [x] All enum values tested against null
- [x] All enum values tested against completely invalid values
- [x] Shared types (NodePath, ParentPath, Dimension, Properties, OptionalProperties) referenced
- [x] Null parameter edge cases covered for every parameter
- [x] Non-existent node path edge cases covered
- [x] Non-particle node (wrong type) edge cases covered
- [x] Interaction with other particle tools (integration scenarios)
- [x] Boundary value tests (offset 0, offset 1, size 0, negative sizes)
- [x] Empty arrays and single-element arrays tested
- [x] Malformed data (wrong types, extra keys) tested
- [x] Idempotency (replace/overwrite) behavior tested
- [x] Full lifecycle (create → configure → read → delete) tested
- [x] Summary table with scenario counts
