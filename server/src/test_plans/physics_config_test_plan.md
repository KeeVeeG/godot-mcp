# Physics Configuration Test Plan

**Source file:** `server/src/tools/physics_config.ts`
**Version:** Based on commit HEAD
**Total tools:** 8

---

## Tool Index

| # | Tool Name | Godot Bridge Endpoint | Parameters |
|---|-----------|----------------------|------------|
| 1 | `get_physics_settings` | `physics_config/get_settings` | None |
| 2 | `set_gravity` | `physics_config/set_gravity` | `x` (number, required), `y` (number, required), `z` (number, optional, default=0) |
| 3 | `set_physics_fps` | `physics_config/set_fps` | `fps` (int, 1–240, optional, default=60) |
| 4 | `set_physics_engine` | `physics_config/set_engine` | `engine` (enum: `default`, `godot_physics`, `jolt`) |
| 5 | `set_collision_layer_name` | `physics_config/set_layer_name` | `layer` (int, 1–32, required), `name` (string, required) |
| 6 | `get_collision_layers` | `physics_config/get_layers` | None |
| 7 | `set_default_gravity` | `physics_config/set_default_gravity` | `value` (number, required) |
| 8 | `set_default_linear_damp` | `physics_config/set_default_linear_damp` | `value` (number, min=0, optional, default=0.1) |

---

## 1. `get_physics_settings`

### Description
Get all physics engine settings (gravity, FPS, engine, layers, damping).

### Parameters
None.

### Behavior
- Makes a call to `physics_config/get_settings` via WebSocket.
- Returns a JSON object containing the current physics configuration.

### Test Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| 1.1 | **Happy path** – call with no args | `{}` (empty) | Returns object with keys like `gravity`, `fps`, `engine`, `layers`, `default_linear_damp`, etc. All values are present and of expected types. |
| 1.2 | **Call twice** – verify idempotency | Call twice in succession | Both calls return identical data (no side effects from read). |
| 1.3 | **Call after gravity change** – verify mutation visible | `set_gravity({x:0, y:-20})` then `get_physics_settings()` | Gravity reflects the new value. |
| 1.4 | **Call when Godot disconnected** | Tool called with no active Godot connection | Error returned: connection/timeout error, not a crash. |

---

## 2. `set_gravity`

### Description
Set the default gravity vector for the physics world.

### Parameters

| Param | Type | Required | Default | Constraints | Description |
|-------|------|----------|---------|-------------|-------------|
| `x` | number | **Yes** | — | Any float | Gravity X component |
| `y` | number | **Yes** | — | Any float | Gravity Y component |
| `z` | number | No | `0` | Any float | Gravity Z component (for 3D) |

### Behavior
- Sends `{x, y, z}` to `physics_config/set_gravity`.
- Sets the project's global gravity vector.

### Test Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| 2.1 | **Happy path – standard 2D gravity** | `{x: 0, y: 980}` | Gravity set to (0, 980, 0). Success response. |
| 2.2 | **Happy path – standard 3D gravity** | `{x: 0, y: -9.8, z: 0}` | Gravity set to (0, -9.8, 0). Success response. |
| 2.3 | **Happy path – full 3D vector** | `{x: 5, y: -10, z: 2}` | Gravity set to (5, -10, 2). Success response. |
| 2.4 | **Default z – omit z** | `{x: 0, y: 980}` | Gravity set to (0, 980, 0). z defaults to 0. |
| 2.5 | **Zero gravity** | `{x: 0, y: 0}` | Gravity set to (0, 0, 0). Success. |
| 2.6 | **Negative values** | `{x: -50, y: -50}` | Gravity set to (-50, -50, 0). Success. |
| 2.7 | **Large values** | `{x: 10000, y: 10000}` | Gravity set to (10000, 10000, 0). Success (Godot accepts). |
| 2.8 | **Float precision** | `{x: 0.0001, y: 9.80665}` | Gravity set with exact float values. |
| 2.9 | **Edge: missing `x`** | `{y: 980}` | Zod validation error — `x` is required. |
| 2.10 | **Edge: missing `y`** | `{x: 0}` | Zod validation error — `y` is required. |
| 2.11 | **Edge: string values** | `{x: "0", y: "980"}` | Zod validation error — expected number, got string. |
| 2.12 | **Edge: boolean values** | `{x: true, y: false}` | Zod validation error. |
| 2.13 | **Edge: null values** | `{x: null, y: 980}` | Zod validation error. |
| 2.14 | **Edge: NaN** | `{x: NaN, y: 980}` | Zod validation error or type coercion failure. |
| 2.15 | **Edge: z as string** | `{x: 0, y: 980, z: "0"}` | Zod validation error. |
| 2.16 | **Edge: extra unknown properties** | `{x: 0, y: 980, w: 100}` | Zod strips or ignores `w`. `x`, `y`, `z` delivered correctly. |

---

## 3. `set_physics_fps`

### Description
Set the physics simulation tick rate.

### Parameters

| Param | Type | Required | Default | Constraints | Description |
|-------|------|----------|---------|-------------|-------------|
| `fps` | int | No | `60` | `min(1)`, `max(240)`, int only | Physics ticks per second |

### Behavior
- Sends `{fps}` to `physics_config/set_fps`.
- Updates the project's physics tick rate.

### Test Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| 3.1 | **Happy path – default** | `{}` (empty) | fps set to 60. Success response. |
| 3.2 | **Happy path – explicit 60** | `{fps: 60}` | fps set to 60. Success. |
| 3.3 | **Enum value: minimum (1)** | `{fps: 1}` | fps set to 1. Success. |
| 3.4 | **Enum value: maximum (240)** | `{fps: 240}` | fps set to 240. Success. |
| 3.5 | **Mid-range value** | `{fps: 120}` | fps set to 120. Success. |
| 3.6 | **Edge: fps = 0** | `{fps: 0}` | Zod validation error — `min(1)`. |
| 3.7 | **Edge: fps = 241** | `{fps: 241}` | Zod validation error — `max(240)`. |
| 3.8 | **Edge: fps = -10** | `{fps: -10}` | Zod validation error — `min(1)`. |
| 3.9 | **Edge: non-integer** | `{fps: 60.5}` | Zod `.int()` validation error. |
| 3.10 | **Edge: string** | `{fps: "60"}` | Zod validation error — expected number. |
| 3.11 | **Edge: boolean** | `{fps: true}` | Zod validation error. |
| 3.12 | **Edge: huge number** | `{fps: 999999}` | Zod validation error — `max(240)`. |

---

## 4. `set_physics_engine`

### Description
Set which physics engine backend to use.

### Parameters

| Param | Type | Required | Default | Constraints | Description |
|-------|------|----------|---------|-------------|-------------|
| `engine` | enum | **Yes** | — | `"default"` \| `"godot_physics"` \| `"jolt"` | Physics engine backend |

### Behavior
- Sends `{engine}` to `physics_config/set_engine`.
- Switches the project's physics engine.

### Test Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| 4.1 | **Enum: "default"** | `{engine: "default"}` | Success. Physics engine set to default. |
| 4.2 | **Enum: "godot_physics"** | `{engine: "godot_physics"}` | Success. Physics engine set to GodotPhysics. |
| 4.3 | **Enum: "jolt"** | `{engine: "jolt"}` | Success (if Jolt is installed). Physics engine set to Jolt. |
| 4.4 | **Edge: empty string** | `{engine: ""}` | Zod validation error — not in enum. |
| 4.5 | **Edge: invalid string** | `{engine: "bullet"}` | Zod validation error — not in enum. |
| 4.6 | **Edge: wrong case** | `{engine: "Default"}` | Zod validation error — case-sensitive enum. |
| 4.7 | **Edge: missing engine** | `{}` | Zod validation error — `engine` is required. |
| 4.8 | **Edge: number** | `{engine: 1}` | Zod validation error — expected string. |
| 4.9 | **Edge: null** | `{engine: null}` | Zod validation error. |
| 4.10 | **Cycle through all engines** | `"default"` → `"godot_physics"` → `"jolt"` → `"default"` | Each call succeeds. Final state is "default". |
| 4.11 | **Set same engine twice** | `{engine: "default"}` twice | Both calls succeed. Idempotent. |

---

## 5. `set_collision_layer_name`

### Description
Assign a human-readable name to a collision layer (1-32).

### Parameters

| Param | Type | Required | Default | Constraints | Description |
|-------|------|----------|---------|-------------|-------------|
| `layer` | int | **Yes** | — | `min(1)`, `max(32)` | Layer number (1-32) |
| `name` | string | **Yes** | — | `Name` (a descriptive string) | Layer name (e.g. 'Player', 'Enemies', 'Terrain') |

### Behavior
- Sends `{layer, name}` to `physics_config/set_layer_name`.
- Names a specific collision layer.

### Test Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| 5.1 | **Happy path – simple name** | `{layer: 1, name: "Player"}` | Layer 1 named "Player". Success. |
| 5.2 | **Happy path – multi-word name** | `{layer: 5, name: "Enemy Projectiles"}` | Layer 5 named "Enemy Projectiles". Success. |
| 5.3 | **Happy path – special characters** | `{layer: 10, name: "UI & HUD"}` | Layer 10 named "UI & HUD". Success. |
| 5.4 | **Enum boundary: layer 1 (min)** | `{layer: 1, name: "Default"}` | Layer 1 set. Success. |
| 5.5 | **Enum boundary: layer 32 (max)** | `{layer: 32, name: "Last Layer"}` | Layer 32 set. Success. |
| 5.6 | **Mid-range layer** | `{layer: 16, name: "Terrain"}` | Layer 16 set. Success. |
| 5.7 | **Empty name string** | `{layer: 2, name: ""}` | Behavior depends on Godot — may accept or reject empty string. Test both. |
| 5.8 | **Very long name** | `{layer: 3, name: "ThisIsAVeryLongLayerNameThatExceedsNormalLengthExpectationsMaybeEvenHundredsOfCharactersLong..."}` | Depends on Godot limits. May truncate or accept full string. |
| 5.9 | **Overwrite existing name** | Set layer 1 to "Player", then to "Hero" | Layer 1 renamed from "Player" to "Hero". |
| 5.10 | **Unicode name** | `{layer: 20, name: "プレイヤー"}` | Layer 20 named with Japanese characters. Success. |
| 5.11 | **Edge: layer = 0** | `{layer: 0, name: "Invalid"}` | Zod validation error — `min(1)`. |
| 5.12 | **Edge: layer = 33** | `{layer: 33, name: "Invalid"}` | Zod validation error — `max(32)`. |
| 5.13 | **Edge: layer = -1** | `{layer: -1, name: "Invalid"}` | Zod validation error — `min(1)`. |
| 5.14 | **Edge: layer as float** | `{layer: 1.5, name: "Invalid"}` | Zod `.int()` validation error. |
| 5.15 | **Edge: layer as string** | `{layer: "1", name: "Player"}` | Zod validation error — expected number. |
| 5.16 | **Edge: missing `name`** | `{layer: 1}` | Zod validation error — `name` is required. |
| 5.17 | **Edge: missing `layer`** | `{name: "Player"}` | Zod validation error — `layer` is required. |
| 5.18 | **Edge: name as number** | `{layer: 5, name: 123}` | Zod validation error — expected string. |
| 5.19 | **Edge: name as null** | `{layer: 5, name: null}` | Zod validation error. |
| 5.20 | **Set all 32 layers** | Loop layers 1–32 with distinct names | All 32 succeed. All layers have unique names. |

---

## 6. `get_collision_layers`

### Description
Get all collision layer names (1-32).

### Parameters
None.

### Behavior
- Makes a call to `physics_config/get_layers`.
- Returns the named collision layers (only layers that have been assigned names).

### Test Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| 6.1 | **Happy path – fresh project** | `{}` (empty) | Returns all 32 layers. Layers without custom names show default names (e.g., "Layer 1", "Layer 2", ...). |
| 6.2 | **After naming layers** | Call after `set_collision_layer_name` on layers 1,5,10 | Returns 32 layers. Layers 1, 5, 10 show custom names; others show defaults. |
| 6.3 | **All layers named** | Name all 32 layers, then call | Returns 32 layers, all with custom names. |
| 6.4 | **Call twice** – verify idempotency | Call twice | Both calls return identical data. No side effects. |
| 6.5 | **After renaming** | Set layer 1 to "A", then to "B", then get layers | Layer 1 shows "B" (latest). |
| 6.6 | **When Godot disconnected** | Call with no Godot connection | Error: connection/timeout, not a crash. |

---

## 7. `set_default_gravity`

### Description
Set the default gravity magnitude in project settings.

### Parameters

| Param | Type | Required | Default | Constraints | Description |
|-------|------|----------|---------|-------------|-------------|
| `value` | number | **Yes** | — | Any float | Gravity value (980.0 for 2D, 9.8 for 3D) |

### Behavior
- Sends `{value}` to `physics_config/set_default_gravity`.
- Sets the default gravity scalar.

### Test Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| 7.1 | **Happy path – 2D default** | `{value: 980}` | Gravity magnitude set to 980. Success. |
| 7.2 | **Happy path – 3D default** | `{value: 9.8}` | Gravity magnitude set to 9.8. Success. |
| 7.3 | **Zero gravity** | `{value: 0}` | Gravity magnitude set to 0. Success. |
| 7.4 | **Negative value** | `{value: -100}` | Gravity magnitude set to -100. Success (Godot may or may not accept — test). |
| 7.5 | **Float precision** | `{value: 9.80665}` | Value set with full precision. Success. |
| 7.6 | **Very large value** | `{value: 999999}` | Value set. Success (Godot accepts). |
| 7.7 | **Very small non-zero** | `{value: 0.0001}` | Value set. Success. |
| 7.8 | **Edge: missing `value`** | `{}` | Zod validation error — `value` is required. |
| 7.9 | **Edge: string** | `{value: "980"}` | Zod validation error — expected number. |
| 7.10 | **Edge: boolean** | `{value: true}` | Zod validation error. |
| 7.11 | **Edge: null** | `{value: null}` | Zod validation error. |
| 7.12 | **Edge: NaN** | `{value: NaN}` | Zod validation error or coercion failure. |
| 7.13 | **Edge: extra properties** | `{value: 980, extra: "ignored"}` | `extra` stripped/ignored. `value` delivered correctly. |
| 7.14 | **Set and verify** | Set to 500, then `get_physics_settings()` | `get_physics_settings` reflects the new gravity. |

---

## 8. `set_default_linear_damp`

### Description
Set the default linear damping for physics bodies.

### Parameters

| Param | Type | Required | Default | Constraints | Description |
|-------|------|----------|---------|-------------|-------------|
| `value` | number | No | `0.1` | `min(0)` | Linear damping value |

### Behavior
- Sends `{value}` to `physics_config/set_default_linear_damp`.
- Sets the default linear damping coefficient.

### Test Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| 8.1 | **Happy path – default** | `{}` (empty) | value set to 0.1 (default). Success. |
| 8.2 | **Happy path – explicit 0.5** | `{value: 0.5}` | value set to 0.5. Success. |
| 8.3 | **Enum boundary: 0 (min)** | `{value: 0}` | value set to 0. Success. |
| 8.4 | **High damping** | `{value: 10}` | value set to 10. Success. |
| 8.5 | **Very high value** | `{value: 100}` | value set to 100. Success. |
| 8.6 | **Float precision** | `{value: 0.12345}` | value set to 0.12345. Success. |
| 8.7 | **Edge: negative value** | `{value: -0.1}` | Zod validation error — `min(0)`. |
| 8.8 | **Edge: negative large** | `{value: -10}` | Zod validation error — `min(0)`. |
| 8.9 | **Edge: string** | `{value: "0.5"}` | Zod validation error — expected number. |
| 8.10 | **Edge: boolean** | `{value: true}` | Zod validation error. |
| 8.11 | **Edge: null** | `{value: null}` | Zod validation error. |
| 8.12 | **Edge: NaN** | `{value: NaN}` | Zod validation error or coercion failure. |
| 8.13 | **Set and verify** | Set to 0.75, then `get_physics_settings()` | `get_physics_settings` reflects damping = 0.75. |
| 8.14 | **Default value after project reload** | Set to 0.1 (or use default), call | Confirm 0.1 is the effective default. |

---

## Integration Scenarios

Combined workflows that exercise multiple tools in sequence.

| ID | Workflow | Steps | Expected Result |
|----|----------|-------|-----------------|
| I.1 | **Full 2D physics setup** | 1. `set_default_gravity({value: 980})`<br>2. `set_gravity({x: 0, y: 980})`<br>3. `set_physics_fps({fps: 60})`<br>4. `get_physics_settings()` | Settings reflect all changes in one consistent snapshot. |
| I.2 | **Full 3D physics setup** | 1. `set_default_gravity({value: 9.8})`<br>2. `set_gravity({x: 0, y: -9.8, z: 0})`<br>3. `set_physics_engine({engine: "jolt"})`<br>4. `get_physics_settings()` | 3D gravity configured, Jolt engine active. |
| I.3 | **Collision layers naming** | 1. `get_collision_layers()`<br>2. Name layers 1-5: Player, Enemies, Bullets, Terrain, Pickups<br>3. `get_collision_layers()` | Initial state captured. After naming, layers 1-5 show custom names. |
| I.4 | **Engine switch cycle** | 1. `get_physics_settings()` (capture initial engine)<br>2. `set_physics_engine({engine: "godot_physics"})`<br>3. `get_physics_settings()` (verify change)<br>4. `set_physics_engine({engine: "default"})`<br>5. `get_physics_settings()` (verify revert) | Engine correctly switches and reverts. Initial and final states match. |
| I.5 | **FPS boundary cycle** | 1. `set_physics_fps({fps: 1})` → verify<br>2. `set_physics_fps({fps: 240})` → verify<br>3. `set_physics_fps({fps: 60})` → verify | All three succeed. Final state: 60 FPS. |

---

## Edge Case Summary Table

| Tool | Empty call | Missing required | Wrong type | Out-of-range | Extra prop | NaN | null |
|------|-----------|-----------------|------------|-------------|------------|-----|------|
| `get_physics_settings` | OK (no params) | N/A | N/A | N/A | N/A | N/A | N/A |
| `set_gravity` | ❌ x,y missing | ❌ Zod error | ❌ Zod error | N/A (unbounded) | Ignored | ❌ error | ❌ error |
| `set_physics_fps` | OK (default=60) | N/A (optional) | ❌ Zod error | ❌ Zod error | Ignored | ❌ error | ❌ error |
| `set_physics_engine` | ❌ engine missing | ❌ Zod error | ❌ Zod error | N/A (enum) | Ignored | ❌ error | ❌ error |
| `set_collision_layer_name` | ❌ both missing | ❌ Zod error | ❌ Zod error | ❌ Zod error | Ignored | ❌ error | ❌ error |
| `get_collision_layers` | OK (no params) | N/A | N/A | N/A | N/A | N/A | N/A |
| `set_default_gravity` | ❌ value missing | ❌ Zod error | ❌ Zod error | N/A (unbounded) | Ignored | ❌ error | ❌ error |
| `set_default_linear_damp` | OK (default=0.1) | N/A (optional) | ❌ Zod error | ❌ Zod error (min=0) | Ignored | ❌ error | ❌ error |

---

## Parameter Constraint Summary

| Tool | Param | Type | Required | Default | Min | Max | Enum/Int |
|------|-------|------|----------|---------|-----|-----|----------|
| `set_gravity` | `x` | number | Yes | — | unbounded | unbounded | — |
| `set_gravity` | `y` | number | Yes | — | unbounded | unbounded | — |
| `set_gravity` | `z` | number | No | 0 | unbounded | unbounded | — |
| `set_physics_fps` | `fps` | number | No | 60 | 1 | 240 | `.int()` |
| `set_physics_engine` | `engine` | string | Yes | — | — | — | `"default"` \| `"godot_physics"` \| `"jolt"` |
| `set_collision_layer_name` | `layer` | number | Yes | — | 1 | 32 | `.int()` |
| `set_collision_layer_name` | `name` | string | Yes | — | — | — | — |
| `set_default_gravity` | `value` | number | Yes | — | unbounded | unbounded | — |
| `set_default_linear_damp` | `value` | number | No | 0.1 | 0 | unbounded | — |

---

## Notes

1. **Godot version dependency**: Behavior of `set_default_gravity` and `set_default_linear_damp` depends on the Godot version's `ProjectSettings` API. Test against Godot 4.x (target: 4.3+).

2. **Jolt engine**: `set_physics_engine` with `"jolt"` requires the Jolt Physics extension to be installed. If not installed, Godot may return an error — this should be documented as expected behavior.

3. **Roundtrip verification**: All "set" tools should be followed by the corresponding "get" call to verify the value was applied correctly (tested at integration level).

4. **Undo support**: These tools modify project settings. Confirm that Godot's undo system or project setting persistence works after tool calls.

5. **Concurrent calls**: The test plan does not cover concurrent tool calls — the MCP WebSocket bridge is sequential per design. Parallel calls from different sessions would need separate testing.
