# Physics Configuration Test Plan

> **Source file:** `server/src/tools/physics_config.ts`  
> **Shared types:** `server/src/tools/shared-types.ts` (imports `z` and `Name`)  
> **Tools covered:** 8 (`get_physics_settings`, `set_gravity`, `set_physics_fps`, `set_physics_engine`, `set_collision_layer_name`, `get_collision_layers`, `set_default_gravity`, `set_default_linear_damp`)  
> **Generated:** 2026-07-08

---

## Schema Details

### Shared Imports

| Import | Zod Schema | Description |
|--------|-----------|-------------|
| `z` | Zod namespace | Used directly for `z.number()`, `z.enum(...)` |
| `Name` | `z.string().describe('Name identifier')` | Generic name string; used for layer names |

### Parameter Summary

| Tool | Param | Type | Required | Default | Enum/Choices | Notes |
|------|-------|------|----------|---------|--------------|-------|
| `get_physics_settings` | *(none)* | — | — | — | — | Takes no input |
| `set_gravity` | `x` | `number` | ✅ yes | — | — | Gravity X component |
| | `y` | `number` | ✅ yes | — | — | Gravity Y component |
| | `z` | `number` | no | `0` | — | Gravity Z component (for 3D) |
| `set_physics_fps` | `fps` | `number` (int) | no | `60` | Min: 1, Max: 240 | Physics ticks per second |
| `set_physics_engine` | `engine` | `enum` | ✅ yes | — | `default`, `godot_physics`, `jolt` | Physics engine backend |
| `set_collision_layer_name` | `layer` | `number` (int) | ✅ yes | — | Min: 1, Max: 32 | Layer number |
| | `name` | `string` | ✅ yes | — | — | Human-readable layer name |
| `get_collision_layers` | *(none)* | — | — | — | — | Takes no input |
| `set_default_gravity` | `value` | `number` | ✅ yes | — | — | Gravity magnitude (980 or 9.8 typical) |
| `set_default_linear_damp` | `value` | `number` | no | `0.1` | Min: 0 | Linear damping value |

---

## Tool: get_physics_settings

### Schema

```typescript
{
  description: 'Get all physics engine settings (gravity, FPS, engine, layers, damping)',
  inputSchema: {},
}
```

### Handler

```typescript
async () => callGodot(bridge, 'physics_config/get_settings')
```

### Tool Behavior

Reads the current physics engine configuration from the Godot project. Returns all physics-related settings including the gravity vector, physics simulation tick rate (FPS), the active physics engine backend, collision layer definitions, and default linear damping. Takes no parameters.

### Test Scenarios

#### Scenario 1: Basic happy path — get current physics settings
- **Description:** Call `get_physics_settings` on a project with default physics settings.
- **Params:** `{}`
- **Expected result:** Returns a JSON object containing physics configuration data. Expected fields include gravity, FPS, engine backend, collision layer names, and default linear damping. Response should have `content[0].type === 'text'` with a non-empty text value. `isError` should not be set or be `false`.
- **Notes:** The exact structure depends on what Godot returns via the bridge. At minimum it should not be an error.

#### Scenario 2: Call with unexpected extra params
- **Description:** Verify the tool ignores extraneous parameters since `inputSchema` is empty `{}`.
- **Params:** `{ "unexpected_param": true, "another_field": "hello" }`
- **Expected result:** Should succeed identically to Scenario 1. Extraneous params should be stripped by Zod (empty schema accepts and discards extra fields).
- **Notes:** Tests robustness against misconfigured clients.

#### Scenario 3: Call with no arguments at all
- **Description:** Call the tool with `undefined` (no params object at all).
- **Params:** *(omit params entirely)*
- **Expected result:** Should succeed — the empty schema should accept `undefined` input.
- **Notes:** Validates the handler handles a missing args object gracefully.

---

## Tool: set_gravity

### Schema

```typescript
{
  description: 'Set the default gravity vector for the physics world',
  inputSchema: {
    x: z.number().describe('Gravity X component'),
    y: z.number().describe('Gravity Y component'),
    z: z.number().optional().default(0).describe('Gravity Z component (for 3D, default 0)'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'physics_config/set_gravity', args as Record<string, unknown>)
```

### Tool Behavior

Sets the default gravity vector applied to all physics bodies in the project. For 2D projects, only `x` and `y` are typically relevant (with `z` defaulting to `0`). Common values: `{ x: 0, y: 980 }` for 2D (pixels/s²), `{ x: 0, y: -9.8, z: 0 }` for 3D (m/s²). Both `x` and `y` are required; `z` is optional with a default of `0`.

### Test Scenarios

#### Scenario 1: Happy path — set 2D gravity (x, y only)
- **Description:** Set a typical 2D gravity vector with only required params `x` and `y`. `z` defaults to `0`.
- **Params:** `{ "x": 0, "y": 980 }`
- **Expected result:** The gravity vector is set to `(0, 980, 0)`. Returns a success response. Verify with `get_physics_settings` that the gravity reflects `x: 0, y: 980`.
- **Notes:** This is the classic Godot 2D gravity. `z` is not passed, so it defaults to `0`.

#### Scenario 2: Happy path — set 3D gravity (x, y, z)
- **Description:** Set a typical 3D gravity vector with all three components.
- **Params:** `{ "x": 0, "y": -9.8, "z": 0 }`
- **Expected result:** The gravity vector is set to `(0, -9.8, 0)`. Returns success. Verify with `get_physics_settings` that all three components are stored correctly.
- **Notes:** This is the classic Godot 3D gravity. Validates that the `z` param is passed through.

#### Scenario 3: Set zero gravity (all zeros)
- **Description:** Set gravity to zero on all axes (e.g. for a space game).
- **Params:** `{ "x": 0, "y": 0, "z": 0 }`
- **Expected result:** The gravity vector is set to `(0, 0, 0)`. Returns success.
- **Notes:** Zero gravity is valid in Godot. Tests boundary: all zero values.

#### Scenario 4: Set negative XY gravity
- **Description:** Set gravity with negative x and y values.
- **Params:** `{ "x": -500, "y": -200 }`
- **Expected result:** The gravity vector is set to `(-500, -200, 0)`. Returns success.
- **Notes:** Negative gravity values are valid (e.g. upside-down gravity or custom directions).

#### Scenario 5: Set gravity with fractional values
- **Description:** Set gravity with floating-point precision values.
- **Params:** `{ "x": 0.5, "y": 9.81, "z": -0.01 }`
- **Expected result:** The gravity vector is set to `(0.5, 9.81, -0.01)`. Returns success. All fractional values should be preserved.
- **Notes:** Validates that floating-point values are accepted and not truncated to integers.

#### Scenario 6: Set gravity with large magnitude values
- **Description:** Set gravity with very large component values.
- **Params:** `{ "x": 100000, "y": 100000 }`
- **Expected result:** The gravity vector is set to `(100000, 100000, 0)`. Returns success.
- **Notes:** Tests that arbitrarily large numeric values are accepted. Godot may clamp internally but the tool should not reject.

#### Scenario 7: Missing required param `x`
- **Description:** Call `set_gravity` without the required `x` parameter.
- **Params:** `{ "y": 980 }`
- **Expected result:** Zod validation should reject this. Expect an error about missing required parameter `x`.
- **Notes:** `x` has no default and is not optional — it must be provided.

#### Scenario 8: Missing required param `y`
- **Description:** Call `set_gravity` without the required `y` parameter.
- **Params:** `{ "x": 0, "z": 0 }`
- **Expected result:** Zod validation should reject this. Expect an error about missing required parameter `y`.
- **Notes:** `y` has no default and is not optional — it must be provided.

#### Scenario 9: Both required params missing
- **Description:** Call `set_gravity` with an empty params object.
- **Params:** `{}`
- **Expected result:** Zod validation should reject this. Expect errors about missing both `x` and `y`.
- **Notes:** Neither `x` nor `y` has a default value.

#### Scenario 10: Invalid type — string instead of number for `x`
- **Description:** Pass a string value for `x` instead of a number.
- **Params:** `{ "x": "zero", "y": 980 }`
- **Expected result:** Zod validation should reject this. Expect a type error — e.g. "Expected number, received string".
- **Notes:** Zod's `z.number()` rejects non-numeric values.

#### Scenario 11: Invalid type — boolean instead of number for `y`
- **Description:** Pass a boolean value for `y` instead of a number.
- **Params:** `{ "x": 0, "y": false }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Powershell/cmd clients sometimes coerce booleans; the Zod schema should catch this.

#### Scenario 12: Invalid type — object instead of number for `z`
- **Description:** Pass an object for the optional `z` parameter.
- **Params:** `{ "x": 0, "y": 980, "z": { "value": 5 } }`
- **Expected result:** Zod validation should reject this. Expect a type error for `z`.
- **Notes:** Even though `z` is optional, when provided it must be a number.

#### Scenario 13: Extra unexpected params
- **Description:** Pass valid gravity params along with extra unknown parameters.
- **Params:** `{ "x": 0, "y": 980, "extra_field": "should_be_ignored", "mode": "zero_g" }`
- **Expected result:** Should succeed with gravity set to `(0, 980, 0)`. Extra fields should be stripped or ignored.
- **Notes:** Tests tolerance for superfluous fields from misconfigured clients.

---

## Tool: set_physics_fps

### Schema

```typescript
{
  description: 'Set the physics simulation tick rate',
  inputSchema: {
    fps: z.number().int().min(1).max(240).optional().default(60).describe('Physics ticks per second (default 60)'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'physics_config/set_fps', args as Record<string, unknown>)
```

### Tool Behavior

Sets how many times per second the physics engine updates. Higher values provide more accurate simulation at the cost of CPU. The parameter is optional and defaults to `60`. Valid range is `1` to `240` (integer). Godot internally uses `Engine.physics_ticks_per_second` (or equivalent project setting).

### Test Scenarios

#### Scenario 1: Happy path — set FPS to 60 (default)
- **Description:** Call `set_physics_fps` with no params, using the default `60`.
- **Params:** `{}`
- **Expected result:** The physics FPS is set to `60`. Returns success. Verify with `get_physics_settings` that the FPS value is `60`.
- **Notes:** Should be a no-op on a default project. Default is triggered by omission.

#### Scenario 2: Set FPS to a low value (1)
- **Description:** Set the physics FPS to the minimum allowed value.
- **Params:** `{ "fps": 1 }`
- **Expected result:** The physics FPS is set to `1`. Returns success.
- **Notes:** Boundary test — minimum valid value. Physics updates only once per second.

#### Scenario 3: Set FPS to the maximum value (240)
- **Description:** Set the physics FPS to the maximum allowed value.
- **Params:** `{ "fps": 240 }`
- **Expected result:** The physics FPS is set to `240`. Returns success.
- **Notes:** Boundary test — maximum valid value. Very high physics tick rate.

#### Scenario 4: Set FPS to a common value (30)
- **Description:** Set the physics FPS to a commonly used value.
- **Params:** `{ "fps": 30 }`
- **Expected result:** The physics FPS is set to `30`. Returns success.
- **Notes:** Many mobile/console games use 30 FPS physics.

#### Scenario 5: Set FPS to 120
- **Description:** Set the physics FPS to a high-performance value.
- **Params:** `{ "fps": 120 }`
- **Expected result:** The physics FPS is set to `120`. Returns success.
- **Notes:** Common value for 120Hz displays.

#### Scenario 6: FPS below minimum (0)
- **Description:** Pass `fps` value of `0`, which is below the minimum of `1`.
- **Params:** `{ "fps": 0 }`
- **Expected result:** Zod validation should reject this. Expect a `too_small` error — minimum is `1`, received `0`.
- **Notes:** `z.number().min(1)` rejects values less than 1.

#### Scenario 7: FPS above maximum (241)
- **Description:** Pass `fps` value of `241`, which exceeds the maximum of `240`.
- **Params:** `{ "fps": 241 }`
- **Expected result:** Zod validation should reject this. Expect a `too_big` error — maximum is `240`, received `241`.
- **Notes:** Tests the upper boundary. `241` is just above the cap.

#### Scenario 8: FPS far above maximum (1000)
- **Description:** Pass an excessively large `fps` value.
- **Params:** `{ "fps": 1000 }`
- **Expected result:** Zod validation should reject this. Expect a `too_big` error.
- **Notes:** Validates the max constraint works for extreme values.

#### Scenario 9: Negative FPS value
- **Description:** Pass a negative `fps` value.
- **Params:** `{ "fps": -10 }`
- **Expected result:** Zod validation should reject this. Expect a `too_small` error — minimum is `1`, received `-10`.
- **Notes:** Negative FPS is nonsensical and should be caught by `.min(1)`.

#### Scenario 10: FPS as float instead of integer
- **Description:** Pass a floating-point value for `fps` instead of an integer.
- **Params:** `{ "fps": 60.5 }`
- **Expected result:** Zod validation should reject this. Expect an error like "Expected integer, received float" from `.int()`.
- **Notes:** `z.number().int()` rejects non-integer numbers.

#### Scenario 11: FPS as float that happens to be a whole number
- **Description:** Pass `fps` as `60.0` (a float that is effectively an integer).
- **Params:** `{ "fps": 60.0 }`
- **Expected result:** Zod's `.int()` checks `Number.isInteger()`, and `60.0 === 60` in JS, so `60.0` passes `Number.isInteger()`. Should succeed — zodiac treats `60.0` as the integer `60`. Physics FPS is set to `60`.
- **Notes:** In JavaScript, `Number.isInteger(60.0)` returns `true`. Most JSON parsers convert `60.0` to `60` anyway.

#### Scenario 12: Invalid type — string instead of number
- **Description:** Pass a string value for `fps`.
- **Params:** `{ "fps": "sixty" }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected number, received string".
- **Notes:** `z.number()` rejects strings.

#### Scenario 13: Invalid type — boolean instead of number
- **Description:** Pass a boolean for `fps`.
- **Params:** `{ "fps": true }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Zod does not coerce booleans to numbers.

#### Scenario 14: Invalid type — array instead of number
- **Description:** Pass an array for `fps`.
- **Params:** `{ "fps": [60] }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Array values should not be accepted for a number field.

---

## Tool: set_physics_engine

### Schema

```typescript
{
  description: 'Set which physics engine backend to use',
  inputSchema: {
    engine: z.enum(['default', 'godot_physics', 'jolt']).describe('Physics engine backend'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'physics_config/set_engine', args as Record<string, unknown>)
```

### Tool Behavior

Switches the physics engine backend used by the Godot project. Three options:
- **`default`**: Uses the engine's default physics backend (typically GodotPhysics).
- **`godot_physics`**: Godot's built-in physics engine.
- **`jolt`**: The Jolt Physics engine (a third-party alternative available as a GDExtension or module). May require installation of the Jolt plugin.

The `engine` parameter is required with no default.

### Test Scenarios

#### Scenario 1: Happy path — set engine to `default`
- **Description:** Set the physics engine backend to `default`.
- **Params:** `{ "engine": "default" }`
- **Expected result:** The physics engine is set to `default`. Returns success. Verify with `get_physics_settings` that the engine is `default`.
- **Notes:** Validates the `default` enum value is accepted.

#### Scenario 2: Set engine to `godot_physics`
- **Description:** Set the physics engine backend to Godot's built-in engine.
- **Params:** `{ "engine": "godot_physics" }`
- **Expected result:** The physics engine is set to `godot_physics`. Returns success.
- **Notes:** Validates the `godot_physics` enum value is accepted.

#### Scenario 3: Set engine to `jolt`
- **Description:** Set the physics engine backend to Jolt Physics.
- **Params:** `{ "engine": "jolt" }`
- **Expected result:** The tool forwards the request to the Godot bridge. The bridge may succeed (if Jolt is installed) or return an error (if Jolt is not available). Either way, the MCP tool itself should not reject the request — it should forward it and return whatever Godot responds.
- **Notes:** This tests that the `jolt` enum value is recognized by Zod and forwarded. The actual Godot-side behavior depends on whether the Jolt extension is installed. The test is for Zod validation, not Godot availability.

#### Scenario 4: Missing required param `engine`
- **Description:** Call `set_physics_engine` without the `engine` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation should reject this. Expect an error about missing required parameter `engine`.
- **Notes:** `engine` is a required parameter with no default.

#### Scenario 5: Invalid enum value — non-existent engine
- **Description:** Pass an engine value that is not in the enum.
- **Params:** `{ "engine": "bullet" }`
- **Expected result:** Zod validation should reject this. Expect an error about invalid enum value — e.g. "Invalid enum value. Expected 'default' | 'godot_physics' | 'jolt', received 'bullet'".
- **Notes:** Godot used to support Bullet physics in 3.x, but it is not a valid option here.

#### Scenario 6: Invalid enum value — `godot_physics_2d`
- **Description:** Pass a plausible but invalid engine name.
- **Params:** `{ "engine": "godot_physics_2d" }`
- **Expected result:** Zod validation should reject this. Expect an enum validation error.
- **Notes:** The enum is strictly `default`, `godot_physics`, `jolt`. No other values are accepted.

#### Scenario 7: Invalid enum value — empty string
- **Description:** Pass an empty string for `engine`.
- **Params:** `{ "engine": "" }`
- **Expected result:** Zod validation should reject this. Empty string is not a valid enum member. Expect an enum validation error.
- **Notes:** Edge case for empty input.

#### Scenario 8: Invalid type — number instead of string
- **Description:** Pass a numeric value for `engine`.
- **Params:** `{ "engine": 1 }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected string, received number".
- **Notes:** Zod's `z.enum()` expects strings.

#### Scenario 9: Invalid type — boolean instead of string
- **Description:** Pass a boolean for `engine`.
- **Params:** `{ "engine": false }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** `false` may be loosely falsy but is not a valid enum member.

#### Scenario 10: Invalid type — null instead of string
- **Description:** Pass `null` for `engine`.
- **Params:** `{ "engine": null }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected string, received null".
- **Notes:** `null` is not a valid value for `z.enum()`.

#### Scenario 11: Extra unexpected params
- **Description:** Pass a valid `engine` with extra unknown parameters.
- **Params:** `{ "engine": "godot_physics", "version": "latest", "debug_mode": true }`
- **Expected result:** Should succeed with engine set to `godot_physics`. Extra fields should be stripped or ignored.
- **Notes:** Tests tolerance for superfluous fields.

---

## Tool: set_collision_layer_name

### Schema

```typescript
{
  description: 'Assign a human-readable name to a collision layer (1-32)',
  inputSchema: {
    layer: z.number().int().min(1).max(32).describe('Layer number (1-32)'),
    name: Name.describe("Layer name (e.g. 'Player', 'Enemies', 'Terrain')"),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'physics_config/set_layer_name', args as Record<string, unknown>)
```

### Tool Behavior

Assigns a human-readable name to one of the 32 collision layers in Godot's physics system. This makes it easier to reference layers by name in scripts and the editor UI. Both `layer` (integer 1–32) and `name` (non-empty string) are required. The `Name` type from `shared-types.ts` is simply `z.string()` — any non-empty string is valid.

### Test Scenarios

#### Scenario 1: Happy path — name layer 1 "Player"
- **Description:** Assign the name "Player" to collision layer 1.
- **Params:** `{ "layer": 1, "name": "Player" }`
- **Expected result:** Collision layer 1 is named "Player". Returns success. Verify with `get_collision_layers` that layer 1 has the name "Player".
- **Notes:** Common use case. Tests minimum valid layer and a typical name.

#### Scenario 2: Happy path — name layer 32 "Terrain"
- **Description:** Assign the name "Terrain" to collision layer 32 (the maximum layer).
- **Params:** `{ "layer": 32, "name": "Terrain" }`
- **Expected result:** Collision layer 32 is named "Terrain". Returns success.
- **Notes:** Boundary test — maximum valid layer number.

#### Scenario 3: Happy path — name a mid-range layer
- **Description:** Assign "Enemies" to layer 16.
- **Params:** `{ "layer": 16, "name": "Enemies" }`
- **Expected result:** Collision layer 16 is named "Enemies". Returns success.
- **Notes:** Tests a typical mid-range layer assignment.

#### Scenario 4: Name with spaces and special characters
- **Description:** Assign a name containing spaces and special characters to a layer.
- **Params:** `{ "layer": 5, "name": "Projectile (Player)" }`
- **Expected result:** Collision layer 5 is named "Projectile (Player)". Returns success.
- **Notes:** Godot layer names support spaces and special characters. Tests that these are forwarded correctly.

#### Scenario 5: Name with Unicode characters
- **Description:** Assign a name containing Unicode/emoji characters (if Godot supports it).
- **Params:** `{ "layer": 10, "name": "Enemy 🔴" }`
- **Expected result:** The name is forwarded to Godot. The MCP tool should not reject it. Godot may or may not render the emoji correctly, but the tool layer should pass it through.
- **Notes:** Tests that the string schema doesn't restrict characters beyond being a valid string.

#### Scenario 6: Empty name string
- **Description:** Pass an empty string `""` for the layer name.
- **Params:** `{ "layer": 1, "name": "" }`
- **Expected result:** Zod's `z.string()` accepts empty strings by default (no `.min(1)` constraint on `Name`). The tool should forward the request to Godot. Godot may accept or reject an empty layer name — observe the bridge response.
- **Notes:** The `Name` type is `z.string()` without a `.min(1)`, so empty strings pass Zod validation. If Godot rejects empty names, the bridge should return an error.

#### Scenario 7: Very long name string
- **Description:** Pass a very long string for the layer name.
- **Params:** `{ "layer": 3, "name": "ThisIsAnExtremelyLongLayerNameThatExceedsNormalLengthsButMightBeAcceptedByTheGodotEnginePhysicsSystem" }`
- **Expected result:** Zod accepts it (no max length). The tool forwards it. Godot may truncate or reject it. Observe the behavior.
- **Notes:** Tests that Zod accepts arbitrarily long strings. Godot-side behavior may vary.

#### Scenario 8: Layer below minimum (0)
- **Description:** Pass `layer` value of `0`, which is below the minimum of `1`.
- **Params:** `{ "layer": 0, "name": "Invalid" }`
- **Expected result:** Zod validation should reject this. Expect a `too_small` error — minimum is `1`, received `0`.
- **Notes:** Godot collision layers are 1-indexed (1 through 32).

#### Scenario 9: Layer above maximum (33)
- **Description:** Pass `layer` value of `33`, which exceeds the maximum of `32`.
- **Params:** `{ "layer": 33, "name": "Invalid" }`
- **Expected result:** Zod validation should reject this. Expect a `too_big` error — maximum is `32`, received `33`.
- **Notes:** Boundary test. 33 is just above the maximum.

#### Scenario 10: Layer as float instead of integer
- **Description:** Pass a floating-point value for `layer`.
- **Params:** `{ "layer": 1.5, "name": "Half Layer" }`
- **Expected result:** Zod validation should reject this. Expect an error about expected integer from `.int()`.
- **Notes:** `z.number().int()` rejects non-integer values.

#### Scenario 11: Layer as negative number
- **Description:** Pass a negative `layer` value.
- **Params:** `{ "layer": -1, "name": "Negative" }`
- **Expected result:** Zod validation should reject this. Expect a `too_small` error — minimum is `1`.
- **Notes:** Negative layer numbers are not valid.

#### Scenario 12: Missing required param `layer`
- **Description:** Call `set_collision_layer_name` without the `layer` parameter.
- **Params:** `{ "name": "Player" }`
- **Expected result:** Zod validation should reject this. Expect an error about missing required parameter `layer`.
- **Notes:** `layer` is required with no default.

#### Scenario 13: Missing required param `name`
- **Description:** Call `set_collision_layer_name` without the `name` parameter.
- **Params:** `{ "layer": 1 }`
- **Expected result:** Zod validation should reject this. Expect an error about missing required parameter `name`.
- **Notes:** `name` is required with no default.

#### Scenario 14: Missing both required params
- **Description:** Call `set_collision_layer_name` with an empty params object.
- **Params:** `{}`
- **Expected result:** Zod validation should reject this. Expect errors about missing both `layer` and `name`.
- **Notes:** Both parameters are required.

#### Scenario 15: Invalid type — string instead of number for `layer`
- **Description:** Pass a string value for `layer`.
- **Params:** `{ "layer": "one", "name": "Player" }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected number, received string" for `layer`.
- **Notes:** The layer must be a numeric integer.

#### Scenario 16: Invalid type — number instead of string for `name`
- **Description:** Pass a number value for `name`.
- **Params:** `{ "layer": 1, "name": 123 }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected string, received number" for `name`.
- **Notes:** Layer names must be strings.

#### Scenario 17: Extra unexpected params
- **Description:** Pass valid params with extra unknown fields.
- **Params:** `{ "layer": 7, "name": "Collectibles", "color": "#FF0000", "visible": true }`
- **Expected result:** Should succeed with layer 7 named "Collectibles". Extra fields should be stripped or ignored.
- **Notes:** Tests tolerance for superfluous fields.

---

## Tool: get_collision_layers

### Schema

```typescript
{
  description: 'Get all collision layer names (1-32)',
  inputSchema: {},
}
```

### Handler

```typescript
async () => callGodot(bridge, 'physics_config/get_layers')
```

### Tool Behavior

Returns the human-readable names of all 32 collision layers configured in the project. Takes no parameters. Returns a list/map of layer numbers to their assigned names. Layers without custom names will show their default numeric or empty names.

### Test Scenarios

#### Scenario 1: Basic happy path — get all collision layers
- **Description:** Call `get_collision_layers` on a project with some named and some default collision layers.
- **Params:** `{}`
- **Expected result:** Returns a JSON object or array containing all 32 collision layer names. Any layers previously named via `set_collision_layer_name` should appear with their custom names. Response should have `content[0].type === 'text'` with a non-empty text value. `isError` should not be set or be `false`.
- **Notes:** The exact structure depends on the Godot bridge but should include entries for all 32 layers.

#### Scenario 2: Get layers after naming several layers
- **Description:** First call `set_collision_layer_name` for layers 1-3, then call `get_collision_layers` to verify the names persist.
- **Params:**
  - Step 1: `{ "layer": 1, "name": "Player" }`
  - Step 2: `{ "layer": 2, "name": "Enemies" }`
  - Step 3: `{ "layer": 3, "name": "Terrain" }`
  - Step 4: `{}` (get_collision_layers)
- **Expected result:** After step 4, the response should show layer 1 = "Player", layer 2 = "Enemies", layer 3 = "Terrain". All other layers should show their current names (default or previously set).
- **Notes:** Validates that `set_collision_layer_name` changes persist and are readable by `get_collision_layers`.

#### Scenario 3: Call with unexpected extra params
- **Description:** Verify the tool ignores extraneous parameters.
- **Params:** `{ "unexpected_param": "value", "layer_filter": 5 }`
- **Expected result:** Should succeed identically to Scenario 1. Extraneous params should be stripped by Zod.
- **Notes:** Tests robustness against misconfigured clients.

#### Scenario 4: Call with no arguments at all
- **Description:** Call the tool with `undefined` (no params object at all).
- **Params:** *(omit params entirely)*
- **Expected result:** Should succeed — the empty schema should accept `undefined` input.
- **Notes:** Validates the handler handles a missing args object gracefully.

---

## Tool: set_default_gravity

### Schema

```typescript
{
  description: 'Set the default gravity magnitude in project settings',
  inputSchema: {
    value: z.number().describe('Gravity value (980.0 for 2D, 9.8 for 3D)'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'physics_config/set_default_gravity', args as Record<string, unknown>)
```

### Tool Behavior

Sets the gravity magnitude value in the project settings. This is distinct from the gravity vector set by `set_gravity` — `set_default_gravity` sets the scalar magnitude used as the default for the physics world, while `set_gravity` sets the directional vector. Typical values: `980.0` for 2D projects, `9.8` for 3D projects. The `value` parameter is required with no default.

### Test Scenarios

#### Scenario 1: Happy path — set 2D default gravity (980)
- **Description:** Set the default gravity magnitude to the standard 2D value.
- **Params:** `{ "value": 980 }`
- **Expected result:** The default gravity is set to `980`. Returns success. Verify with `get_physics_settings` that the gravity magnitude reflects `980`.
- **Notes:** Classic 2D Godot gravity in pixels/s².

#### Scenario 2: Happy path — set 3D default gravity (9.8)
- **Description:** Set the default gravity magnitude to the standard 3D value.
- **Params:** `{ "value": 9.8 }`
- **Expected result:** The default gravity is set to `9.8`. Returns success.
- **Notes:** Classic 3D Godot gravity in m/s².

#### Scenario 3: Set gravity to zero
- **Description:** Set gravity to zero magnitude (zero-gravity environment).
- **Params:** `{ "value": 0 }`
- **Expected result:** The default gravity is set to `0`. Returns success.
- **Notes:** Boundary test. Zero gravity is valid (e.g. space games).

#### Scenario 4: Set gravity to a negative value
- **Description:** Set gravity to a negative magnitude.
- **Params:** `{ "value": -9.8 }`
- **Expected result:** The default gravity is set to `-9.8`. Returns success (or the bridge may report an issue with negative magnitude). Observe the bridge response.
- **Notes:** `z.number()` accepts negative values. Some game engines use negative to mean "upward" gravity. The tool should forward it and let Godot decide validity.

#### Scenario 5: Set gravity to a fractional value
- **Description:** Set gravity to a precise floating-point value.
- **Params:** `{ "value": 9.81 }`
- **Expected result:** The default gravity is set to `9.81`. Returns success. The fractional precision should be preserved.
- **Notes:** Many simulations use 9.81 (more precise than 9.8). Validates float preservation.

#### Scenario 6: Set gravity to a very large value
- **Description:** Set gravity to an extremely large magnitude.
- **Params:** `{ "value": 1000000 }`
- **Expected result:** The value is forwarded to Godot. The tool should not reject it. Godot may clamp or accept; observe.
- **Notes:** Tests that `z.number()` has no upper bound and passes through large numbers.

#### Scenario 7: Set gravity to a very small value
- **Description:** Set gravity to a tiny magnitude (near-microgravity).
- **Params:** `{ "value": 0.001 }`
- **Expected result:** The default gravity is set to `0.001`. Returns success.
- **Notes:** Validates that small positive numbers are accepted.

#### Scenario 8: Missing required param `value`
- **Description:** Call `set_default_gravity` without the `value` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation should reject this. Expect an error about missing required parameter `value`.
- **Notes:** `value` is required with no default.

#### Scenario 9: Invalid type — string instead of number
- **Description:** Pass a string for `value`.
- **Params:** `{ "value": "nine_point_eight" }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected number, received string".
- **Notes:** Zod's `z.number()` rejects strings. Even numeric strings like `"9.8"` should be rejected.

#### Scenario 10: Invalid type — boolean instead of number
- **Description:** Pass a boolean for `value`.
- **Params:** `{ "value": true }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Booleans are not valid numbers in Zod.

#### Scenario 11: Invalid type — object instead of number
- **Description:** Pass an object for `value`.
- **Params:** `{ "value": { "magnitude": 980 } }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Objects should not be accepted for a number parameter.

#### Scenario 12: Invalid type — array instead of number
- **Description:** Pass an array for `value`.
- **Params:** `{ "value": [980] }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Arrays should not be accepted for a number parameter.

#### Scenario 13: Extra unexpected params
- **Description:** Pass valid `value` with extra unknown parameters.
- **Params:** `{ "value": 980, "unit": "pixels_per_second_squared", "comment": "2D gravity" }`
- **Expected result:** Should succeed with gravity set to `980`. Extra fields should be stripped or ignored.
- **Notes:** Tests tolerance for superfluous fields.

---

## Tool: set_default_linear_damp

### Schema

```typescript
{
  description: 'Set the default linear damping for physics bodies',
  inputSchema: {
    value: z.number().min(0).optional().default(0.1).describe('Linear damping value (default 0.1)'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'physics_config/set_default_linear_damp', args as Record<string, unknown>)
```

### Tool Behavior

Sets the default linear damping applied to newly created physics bodies. Linear damping reduces the velocity of a body over time (like air resistance or friction). The `value` parameter is optional and defaults to `0.1`. It must be a non-negative number (`>= 0`). A value of `0` means no damping; higher values slow bodies more aggressively.

### Test Scenarios

#### Scenario 1: Happy path — set damping to default (0.1)
- **Description:** Call `set_default_linear_damp` with no params, using the default `0.1`.
- **Params:** `{}`
- **Expected result:** The default linear damping is set to `0.1`. Returns success. Verify with `get_physics_settings` that the damping value is `0.1`.
- **Notes:** Default should be triggered by omission.

#### Scenario 2: Set damping to zero (no damping)
- **Description:** Set linear damping to zero for no velocity reduction.
- **Params:** `{ "value": 0 }`
- **Expected result:** The default linear damping is set to `0`. Returns success.
- **Notes:** Boundary test — minimum valid value. Physics bodies will maintain velocity indefinitely.

#### Scenario 3: Set damping to a high value (1.0)
- **Description:** Set linear damping to `1.0` for maximum slowdown.
- **Params:** `{ "value": 1 }`
- **Expected result:** The default linear damping is set to `1`. Returns success.
- **Notes:** Godot typically uses damping values in the 0–1 range. 1.0 means maximum damping.

#### Scenario 4: Set damping to a moderate value (0.5)
- **Description:** Set linear damping to a moderate middle value.
- **Params:** `{ "value": 0.5 }`
- **Expected result:** The default linear damping is set to `0.5`. Returns success.
- **Notes:** Common value for moderate air resistance.

#### Scenario 5: Set damping to a value above 1.0
- **Description:** Set damping to a value greater than 1.0.
- **Params:** `{ "value": 2.5 }`
- **Expected result:** Zod accepts it (no `.max()` constraint, only `.min(0)`). The tool forwards it. Godot may accept or clamp internally. Observe the bridge response.
- **Notes:** Linear damping in Godot can technically exceed 1.0, though values above 1 are unusual.

#### Scenario 6: Set damping to a very small positive value
- **Description:** Set damping to a tiny non-zero value (near zero).
- **Params:** `{ "value": 0.001 }`
- **Expected result:** The default linear damping is set to `0.001`. Returns success.
- **Notes:** Validates small fractional values — nearly no damping but not quite zero.

#### Scenario 7: Damping below minimum — negative value
- **Description:** Pass a negative `value`, which is below the minimum of `0`.
- **Params:** `{ "value": -0.1 }`
- **Expected result:** Zod validation should reject this. Expect a `too_small` error — minimum is `0`, received `-0.1`.
- **Notes:** Negative damping is nonsensical (it would accelerate bodies) and should be rejected.

#### Scenario 8: Damping below minimum — large negative value
- **Description:** Pass a large negative damping value.
- **Params:** `{ "value": -10 }`
- **Expected result:** Zod validation should reject this. Expect a `too_small` error.
- **Notes:** Validates the `.min(0)` constraint on extreme values.

#### Scenario 9: Invalid type — string instead of number
- **Description:** Pass a string for `value`.
- **Params:** `{ "value": "low" }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected number, received string".
- **Notes:** `z.number()` rejects strings.

#### Scenario 10: Invalid type — boolean instead of number
- **Description:** Pass a boolean for `value`.
- **Params:** `{ "value": false }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Booleans are not valid numbers in Zod.

#### Scenario 11: Invalid type — array instead of number
- **Description:** Pass an array for `value`.
- **Params:** `{ "value": [] }`
- **Expected result:** Zod validation should reject this. Expect a type error.
- **Notes:** Arrays should not be accepted for a number parameter.

#### Scenario 12: Invalid type — null instead of number
- **Description:** Pass `null` for `value`.
- **Params:** `{ "value": null }`
- **Expected result:** Zod validation should reject this. Expect a type error — "Expected number, received null". Zod's `z.number()` does not accept `null`.
- **Notes:** Even though `value` is optional (can be omitted), explicitly passing `null` is not the same as omitting it.

#### Scenario 13: Extra unexpected params
- **Description:** Pass valid `value` with extra unknown parameters.
- **Params:** `{ "value": 0.3, "mode": "linear", "axis": "xy" }`
- **Expected result:** Should succeed with damping set to `0.3`. Extra fields should be stripped or ignored.
- **Notes:** Tests tolerance for superfluous fields.

---

## Cross-Tool Integration Scenarios

These scenarios test interactions between multiple physics config tools.

### Integration 1: Full configuration cycle
- **Description:** Set all physics parameters then read them back.
- **Steps:**
  1. `set_gravity` → `{ "x": 0, "y": 980 }`
  2. `set_physics_fps` → `{ "fps": 120 }`
  3. `set_physics_engine` → `{ "engine": "godot_physics" }`
  4. `set_collision_layer_name` → `{ "layer": 1, "name": "Player" }`
  5. `set_collision_layer_name` → `{ "layer": 2, "name": "Enemies" }`
  6. `set_default_gravity` → `{ "value": 980 }`
  7. `set_default_linear_damp` → `{ "value": 0.2 }`
  8. `get_physics_settings` → `{}`
  9. `get_collision_layers` → `{}`
- **Expected result:** Step 8 returns all physics settings reflecting the changes from steps 1–7. Step 9 shows layers 1="Player" and 2="Enemies". All calls succeed.
- **Notes:** Validates that all set operations persist and are readable by the corresponding get tools.

### Integration 2: Overwrite gravity
- **Description:** Set gravity to one value, then overwrite with another.
- **Steps:**
  1. `set_gravity` → `{ "x": 0, "y": 980 }`
  2. `get_physics_settings` → `{}`
  3. `set_gravity` → `{ "x": 0, "y": -500, "z": 0 }`
  4. `get_physics_settings` → `{}`
- **Expected result:** Step 2 shows gravity `(0, 980, 0)`. Step 4 shows gravity `(0, -500, 0)`. The second `set_gravity` overwrites the first.
- **Notes:** Validates overwrite behavior.

### Integration 3: Overwrite collision layer name
- **Description:** Name a layer, then rename it.
- **Steps:**
  1. `set_collision_layer_name` → `{ "layer": 1, "name": "Player" }`
  2. `get_collision_layers` → `{}`
  3. `set_collision_layer_name` → `{ "layer": 1, "name": "Hero" }`
  4. `get_collision_layers` → `{}`
- **Expected result:** Step 2 shows layer 1 = "Player". Step 4 shows layer 1 = "Hero". The second call overwrites the first.
- **Notes:** Validates that layer names can be changed.

### Integration 4: Tool independence — get tools unaffected by invalid set calls
- **Description:** Attempt invalid calls to set tools, then verify get tools still work.
- **Steps:**
  1. `set_physics_fps` → `{ "fps": -999 }` (invalid — expect Zod error)
  2. `set_physics_engine` → `{ "engine": "invalid_engine" }` (invalid — expect Zod error)
  3. `get_physics_settings` → `{}` (should still succeed)
  4. `get_collision_layers` → `{}` (should still succeed)
- **Expected result:** Steps 1 and 2 fail with validation errors. Steps 3 and 4 succeed normally, returning current (unchanged) settings. Invalid calls do not corrupt the read path.
- **Notes:** Validates that failed writes don't affect subsequent reads.

---

## Notes for Test Executors

1. **Godot bridge required.** All tools in this file forward requests to the Godot editor via `callGodot(bridge, ...)`. The Godot editor with the MCP plugin must be running for success-path tests.

2. **Zod validation happens before the bridge call.** Any invalid params are caught by Zod and never reach Godot. When testing invalid-param scenarios, the error will come from the MCP server's Zod layer, not from Godot.

3. **Stateful tools.** `set_gravity`, `set_physics_fps`, `set_physics_engine`, `set_default_gravity`, and `set_default_linear_damp` all modify project settings that persist across sessions. `set_collision_layer_name` modifies collision layer names that also persist. Consider resetting to defaults between test runs or documenting the initial state before each test.

4. **Parameter coercion.** Zod does NOT coerce types (e.g., `"60"` is not coerced to `60`). All numeric parameters must be actual JavaScript numbers in the JSON payload. Integer parameters (`.int()`) must be whole numbers — `60.5` fails even though it's a number.

5. **Optional vs. required.** Parameters without `.optional()` are required and will cause validation failure if missing. Parameters with `.optional().default(X)` can be omitted and will default to `X`. Parameters with only `.optional()` can be omitted and will be `undefined`.

6. **Enum validation.** `z.enum()` matches exactly — case-sensitive, no partial matches. `"Default"` will fail for the enum `['default', 'godot_physics', 'jolt']`.

7. **The `Name` type.** The `Name` type imported from `shared-types.ts` is `z.string().describe('Name identifier')`. It has no `.min(1)` constraint, so empty strings pass Zod validation. The Godot bridge may reject empty names — this is expected and should be documented in test results.

8. **Float vs. Integer.** `z.number()` accepts both integers and floats. Tools using `.int()` (`set_physics_fps`, `set_collision_layer_name` for `layer`) reject floats. The distinction is important — JavaScript's `Number.isInteger()` is used internally.
