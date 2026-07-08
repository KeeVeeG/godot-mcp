# Test Plan: physics_config.ts

> **Source**: `server/src/tools/physics_config.ts`
> **Backend methods prefix**: `physics_config/`
> **Godot bridge**: `callGodot(bridge, method, params)` — sends JSON-RPC to Godot editor plugin, returns `ToolResult` with `{ content: [{ type: 'text', text }] }` or error.
>
> **Prerequisites**: Godot editor must be running with `godot_mcp` plugin active and connected via WebSocket.
> **No scene or node prerequisites** — these tools modify global project/physics settings, not scene-tree nodes.

---

## Tool: `get_physics_settings`

### Schema

| Param | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| _(none)_ | — | — | — | Takes no parameters |

- **Backend method**: `physics_config/get_settings`
- **Description**: Get all physics engine settings (gravity, FPS, engine, layers, damping)

### Test Scenarios

#### 1. Happy path — retrieve all physics settings

**Description**: Call with no arguments, expect a JSON response containing physics configuration fields.

**Params**: `{}`

**Expected result**: `content[0].text` is a JSON string. Parse it and verify it contains at least these keys: gravity-related fields (e.g. `gravity_vector`, `gravity`), FPS-related field (e.g. `physics_fps` or `fps`), engine field, damping field. The response is NOT an error (`isError` is absent or `false`).

**Notes**: This is a read-only query. It should never fail under normal conditions. The exact field names depend on the GDScript implementation — the tester should log the full response first to confirm the shape, then assert on those actual keys.

**Pay attention**: Ensure the response contains all expected fields. If the response is empty or contains an error — Godot is not connected or the plugin is not active.

---

#### 2. Call twice — verify idempotency

**Description**: Call `get_physics_settings` twice in rapid succession. Both calls should return the same data.

**Params**: `{}` (called twice)

**Expected result**: Both responses are structurally identical (same keys, same values).

**Notes**: Confirms no side effects from repeated reads.

**Pay attention**: Values must match. If they differ — there is a problem with Godot state (possibly a parallel call changing settings).

---

## Tool: `set_gravity`

### Schema

| Param | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| `x` | number | **yes** | — | Gravity X component |
| `y` | number | **yes** | — | Gravity Y component |
| `z` | number | no | `0` | Gravity Z component (for 3D) |

- **Backend method**: `physics_config/set_gravity`
- **Description**: Set the default gravity vector for the physics world

### Test Scenarios

#### 1. Happy path — set 2D gravity

**Description**: Set gravity to standard 2D downward vector.

**Params**: `{ "x": 0, "y": 980 }`

**Expected result**: Success response (no `isError`). Call `get_physics_settings` afterwards to verify gravity vector is `[0, 980, 0]` (z defaults to 0).

**Notes**: After this call, follow up with `get_physics_settings` to confirm the value was applied.

**Pay attention**: Verify that the z-component is automatically set to 0 (default). The value 980 is the standard gravity in Godot for 2D (pixels/s²).

---

#### 2. Happy path — set 3D gravity with explicit Z

**Description**: Set gravity for a 3D project with all three components.

**Params**: `{ "x": 0, "y": -9.8, "z": 0 }`

**Expected result**: Success response. Follow up with `get_physics_settings` to verify vector is `[0, -9.8, 0]`.

**Notes**: 3D gravity is typically negative Y (downward in Godot's 3D coordinate system).

**Pay attention**: Godot 3D uses the negative Y axis for "down". Ensure the value was saved correctly.

---

#### 3. Happy path — non-zero X and Z components

**Description**: Set gravity with lateral components (e.g. for a tilted world or wind effect).

**Params**: `{ "x": 50, "y": 980, "z": -10 }`

**Expected result**: Success response. Verify via `get_physics_settings`.

**Notes**: Tests that all three vector components are independently stored.

**Pay attention**: All three components must be saved. Zeroing out x or z for non-standard values is not allowed.

---

#### 4. Edge case — zero gravity

**Description**: Set gravity to zero vector (space simulation).

**Params**: `{ "x": 0, "y": 0 }`

**Expected result**: Success response. Verify vector is `[0, 0, 0]`.

**Notes**: Legitimate use case for space games.

**Pay attention**: Some implementations may reject zero gravity. Ensure the value is accepted.

---

#### 5. Edge case — negative values (upward gravity)

**Description**: Set negative Y gravity (gravity pulls upward).

**Params**: `{ "x": 0, "y": -980 }`

**Expected result**: Success response. Verify vector is `[0, -980, 0]`.

**Pay attention**: Used in games with inverted gravity. The value should be accepted without errors.

---

#### 6. Missing required params — no `x`

**Description**: Call without the required `x` parameter.

**Params**: `{ "y": 980 }`

**Expected result**: Error response (`isError: true`) — Zod schema validation should reject because `x` is required.

**Notes**: This tests the MCP server's input validation layer (Zod), not the Godot backend.

**Pay attention**: The error must be on the MCP server side (Zod validation), not reach Godot.

---

#### 7. Missing required params — no `y`

**Description**: Call without the required `y` parameter.

**Params**: `{ "x": 0 }`

**Expected result**: Error response (`isError: true`).

**Pay attention**: Same as scenario 6 — server-side validation check.

---

#### 8. Missing required params — empty object

**Description**: Call with no parameters at all.

**Params**: `{}`

**Expected result**: Error response (`isError: true`) — both `x` and `y` are required.

**Pay attention**: Both required parameters are missing. The error must contain information about missing fields.

---

#### 9. Invalid type — string instead of number

**Description**: Pass a string value for `x`.

**Params**: `{ "x": "not_a_number", "y": 980 }`

**Expected result**: Error response (`isError: true`) — Zod `z.number()` rejects non-numeric values.

**Pay attention**: Verify that Zod correctly rejects string values.

---

## Tool: `set_physics_fps`

### Schema

| Param | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| `fps` | number (int) | no | `60` | Min: 1, Max: 240 |

- **Backend method**: `physics_config/set_fps`
- **Description**: Set the physics simulation tick rate

### Test Scenarios

#### 1. Happy path — set default FPS explicitly

**Description**: Call with the default value (60).

**Params**: `{ "fps": 60 }`

**Expected result**: Success response. Follow up with `get_physics_settings` to verify FPS is 60.

**Pay attention**: Basic scenario. Ensure the value is saved.

---

#### 2. Happy path — set high FPS

**Description**: Set physics FPS to 120 for a fast-paced game.

**Params**: `{ "fps": 120 }`

**Expected result**: Success response. Verify via `get_physics_settings`.

**Pay attention**: High FPS is a valid scenario for competitive games.

---

#### 3. Happy path — omit parameter (use default)

**Description**: Call with empty object, relying on Zod default of 60.

**Params**: `{}`

**Expected result**: Success response. The Zod schema applies `.optional().default(60)`, so the default value 60 is sent to the backend.

**Pay attention**: Verify that the default value from the Zod schema is correctly substituted when the parameter is absent.

---

#### 4. Boundary — minimum value (1)

**Description**: Set FPS to the minimum allowed value.

**Params**: `{ "fps": 1 }`

**Expected result**: Success response. Extremely low FPS is valid per schema.

**Pay attention**: FPS = 1 is a boundary value. Godot must accept it without errors. Physics will update once per second.

---

#### 5. Boundary — maximum value (240)

**Description**: Set FPS to the maximum allowed value.

**Params**: `{ "fps": 240 }`

**Expected result**: Success response.

**Pay attention**: Boundary value. Verify that Godot does not reject too high an FPS.

---

#### 6. Out of range — below minimum (0)

**Description**: Set FPS below the minimum.

**Params**: `{ "fps": 0 }`

**Expected result**: Error response (`isError: true`) — Zod `.min(1)` rejects 0.

**Pay attention**: Zod validation error. Must not reach Godot.

---

#### 7. Out of range — above maximum (241)

**Description**: Set FPS above the maximum.

**Params**: `{ "fps": 241 }`

**Expected result**: Error response (`isError: true`) — Zod `.max(240)` rejects 241.

**Pay attention**: Zod validation error.

---

#### 8. Invalid type — non-integer

**Description**: Pass a float value for FPS.

**Params**: `{ "fps": 60.5 }`

**Expected result**: Error response (`isError: true`) — Zod `.int()` rejects non-integers.

**Pay attention**: Zod `.int()` does not allow decimal numbers. Godot expects an integer number of ticks.

---

#### 9. Invalid type — negative value

**Description**: Pass a negative FPS.

**Params**: `{ "fps": -10 }`

**Expected result**: Error response (`isError: true`) — fails `.min(1)`.

**Pay attention**: Negative FPS has no physical meaning. Validation error.

---

## Tool: `set_physics_engine`

### Schema

| Param | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| `engine` | string (enum) | **yes** | — | One of: `'default'`, `'godot_physics'`, `'jolt'` |

- **Backend method**: `physics_config/set_engine`
- **Description**: Set which physics engine backend to use

### Test Scenarios

#### 1. Happy path — set to `default`

**Description**: Set physics engine to Godot's default backend.

**Params**: `{ "engine": "default" }`

**Expected result**: Success response.

**Pay attention**: Basic scenario. `default` typically means Godot Physics.

---

#### 2. Happy path — set to `godot_physics`

**Description**: Explicitly select the built-in Godot Physics engine.

**Params**: `{ "engine": "godot_physics" }`

**Expected result**: Success response.

**Pay attention**: Explicit selection of Godot Physics.

---

#### 3. Happy path — set to `jolt`

**Description**: Switch to the Jolt physics engine (popular third-party alternative).

**Params**: `{ "engine": "jolt" }`

**Expected result**: Success response. Note: Jolt must be installed as a plugin in the Godot project. If not installed, the backend may return an error.

**Pay attention**: Jolt is a third-party engine. If it is not installed in the project, Godot may return an error. This is expected behavior, not a test bug.

---

#### 4. Invalid enum value

**Description**: Pass an unsupported engine name.

**Params**: `{ "engine": "bullet" }`

**Expected result**: Error response (`isError: true`) — Zod `.enum()` rejects values not in the allowed list.

**Pay attention**: Zod rejects invalid enum values. The error must contain the list of allowed values.

---

#### 5. Missing required param

**Description**: Call without `engine` parameter.

**Params**: `{}`

**Expected result**: Error response (`isError: true`) — `engine` is required.

**Pay attention**: Checking parameter requiredness.

---

#### 6. Invalid type — number instead of string

**Description**: Pass a numeric value for engine.

**Params**: `{ "engine": 1 }`

**Expected result**: Error response (`isError: true`) — Zod enum expects a string.

**Pay attention**: The type must be strictly a string.

---

## Tool: `set_collision_layer_name`

### Schema

| Param | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| `layer` | number (int) | **yes** | — | Min: 1, Max: 32 |
| `name` | string | **yes** | — | Any non-empty string (Name type) |

- **Backend method**: `physics_config/set_layer_name`
- **Description**: Assign a human-readable name to a collision layer (1-32)

### Test Scenarios

#### 1. Happy path — name layer 1 as "Player"

**Description**: Assign a name to the first collision layer.

**Params**: `{ "layer": 1, "name": "Player" }`

**Expected result**: Success response. Follow up with `get_collision_layers` to verify layer 1 is named "Player".

**Pay attention**: Basic scenario. Verify via `get_collision_layers` that the name was saved.

---

#### 2. Happy path — name layer 16 as "Enemies"

**Description**: Name a mid-range layer.

**Params**: `{ "layer": 16, "name": "Enemies" }`

**Expected result**: Success response. Verify via `get_collision_layers`.

**Pay attention**: Mid-range layer number. Should work the same as layer 1.

---

#### 3. Happy path — name layer 32 (max)

**Description**: Name the last available layer.

**Params**: `{ "layer": 32, "name": "Terrain" }`

**Expected result**: Success response. Verify via `get_collision_layers`.

**Pay attention**: Boundary value — maximum layer number.

---

#### 4. Happy path — name with special characters

**Description**: Use a layer name with spaces and special characters.

**Params**: `{ "layer": 5, "name": "Player & Allies (v2)" }`

**Expected result**: Success response.

**Pay attention**: Names with special characters must be saved correctly. Verify that the name is not truncated.

---

#### 5. Boundary — minimum layer (1)

**Description**: Set name on the minimum allowed layer number.

**Params**: `{ "layer": 1, "name": "Default" }`

**Expected result**: Success response.

**Pay attention**: Boundary value — minimum layer number.

---

#### 6. Boundary — layer 0 (below minimum)

**Description**: Try to name layer 0.

**Params**: `{ "layer": 0, "name": "Invalid" }`

**Expected result**: Error response (`isError: true`) — Zod `.min(1)` rejects 0.

**Pay attention**: Layers are numbered starting from 1 in Godot. Number 0 is not allowed.

---

#### 7. Boundary — layer 33 (above maximum)

**Description**: Try to name layer 33.

**Params**: `{ "layer": 33, "name": "TooHigh" }`

**Expected result**: Error response (`isError: true`) — Zod `.max(32)` rejects 33.

**Pay attention**: Maximum 32 layers. Checking the upper boundary.

---

#### 8. Invalid type — non-integer layer

**Description**: Pass a float for layer number.

**Params**: `{ "layer": 2.5, "name": "Test" }`

**Expected result**: Error response (`isError: true`) — Zod `.int()` rejects floats.

**Pay attention**: The layer number must be an integer.

---

#### 9. Missing required params — no `name`

**Description**: Call without the `name` parameter.

**Params**: `{ "layer": 1 }`

**Expected result**: Error response (`isError: true`) — `name` is required.

**Pay attention**: Both parameters are required.

---

#### 10. Missing required params — no `layer`

**Description**: Call without the `layer` parameter.

**Params**: `{ "name": "Player" }`

**Expected result**: Error response (`isError: true`) — `layer` is required.

**Pay attention**: Both parameters are required.

---

## Tool: `get_collision_layers`

### Schema

| Param | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| _(none)_ | — | — | — | Takes no parameters |

- **Backend method**: `physics_config/get_layers`
- **Description**: Get all collision layer names (1-32)

### Test Scenarios

#### 1. Happy path — retrieve layer names

**Description**: Call with no arguments, expect a list or map of collision layer names.

**Params**: `{}`

**Expected result**: `content[0].text` is a JSON string containing layer name data. The structure should represent 32 layers (some may be empty/null/unnamed).

**Notes**: This is a read-only query. Run this after `set_collision_layer_name` tests to verify those names are reflected.

**Pay attention**: The response must contain data for all 32 layers (or at least for named ones). If the response is empty — no layer has been named.

---

#### 2. Verify after setting a layer name

**Description**: First call `set_collision_layer_name` with `{ "layer": 1, "name": "TestLayer" }`, then call `get_collision_layers`.

**Params**: `{}`

**Expected result**: The response should include `"TestLayer"` associated with layer 1.

**Notes**: This is a **sequence test**: `set_collision_layer_name` → `get_collision_layers`. The second call validates the side effect of the first.

**Pay attention**: The name set via `set_collision_layer_name` must appear in the `get_collision_layers` response. If it does not — there is a persistence problem.

---

#### 3. Verify multiple layer names

**Description**: Call `set_collision_layer_name` for layers 1, 2, and 3 with different names, then call `get_collision_layers`.

**Params**: `{}`

**Expected result**: All three names appear in the response at the correct layer positions.

**Notes**: **Sequence**: `set_collision_layer_name` ×3 → `get_collision_layers`. Validates batch persistence.

**Pay attention**: All three names must be present. Layer order must match the numbers (1, 2, 3).

---

## Tool: `set_default_gravity`

### Schema

| Param | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| `value` | number | **yes** | — | Gravity value (980.0 for 2D, 9.8 for 3D) |

- **Backend method**: `physics_config/set_default_gravity`
- **Description**: Set the default gravity magnitude in project settings

### Test Scenarios

#### 1. Happy path — set standard 2D gravity

**Description**: Set gravity magnitude to 980 (standard 2D value in Godot, pixels/s²).

**Params**: `{ "value": 980 }`

**Expected result**: Success response. Follow up with `get_physics_settings` to verify gravity magnitude changed.

**Pay attention**: 980 is the standard value for 2D Godot. Verify via `get_physics_settings`.

---

#### 2. Happy path — set standard 3D gravity

**Description**: Set gravity magnitude to 9.8 (standard 3D value, m/s²).

**Params**: `{ "value": 9.8 }`

**Expected result**: Success response.

**Pay attention**: For 3D, the metric system is used (9.8 m/s²).

---

#### 3. Edge case — zero gravity

**Description**: Set gravity to 0 (weightlessness).

**Params**: `{ "value": 0 }`

**Expected result**: Success response.

**Pay attention**: Zero gravity is a valid scenario for space games.

---

#### 4. Edge case — negative gravity

**Description**: Set negative gravity (upward pull).

**Params**: `{ "value": -980 }`

**Expected result**: Success or error depending on Godot's validation. Document the behavior.

**Pay attention**: Negative gravity is a non-trivial case. Godot may accept or reject it. Document the actual behavior.

---

#### 5. Missing required param

**Description**: Call without `value`.

**Params**: `{}`

**Expected result**: Error response (`isError: true`) — `value` is required.

**Pay attention**: Checking parameter requiredness.

---

#### 6. Invalid type — string

**Description**: Pass a string instead of number.

**Params**: `{ "value": "heavy" }`

**Expected result**: Error response (`isError: true`) — Zod `z.number()` rejects strings.

**Pay attention**: Strictly numeric value.

---

#### 7. Large value

**Description**: Set an extremely large gravity value.

**Params**: `{ "value": 999999 }`

**Expected result**: Success response (no max constraint in schema).

**Pay attention**: There is no upper bound in the schema. Godot must accept any number. Verify that no overflow or error occurs.

---

## Tool: `set_default_linear_damp`

### Schema

| Param | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| `value` | number | no | `0.1` | Min: 0 |

- **Backend method**: `physics_config/set_default_linear_damp`
- **Description**: Set the default linear damping for physics bodies

### Test Scenarios

#### 1. Happy path — set to default value explicitly

**Description**: Set damping to the default value 0.1.

**Params**: `{ "value": 0.1 }`

**Expected result**: Success response.

**Pay attention**: Basic scenario. Verify that the value 0.1 is correctly applied.

---

#### 2. Happy path — omit parameter (use default)

**Description**: Call with empty object, relying on Zod default.

**Params**: `{}`

**Expected result**: Success response. Zod `.optional().default(0.1)` applies the default value 0.1.

**Pay attention**: The default value from the Zod schema is substituted automatically.

---

#### 3. Happy path — set high damping

**Description**: Set high damping for a slow/sticky physics environment.

**Params**: `{ "value": 10.0 }`

**Expected result**: Success response.

**Pay attention**: High damping is a valid scenario (e.g., underwater environment).

---

#### 4. Boundary — minimum value (0)

**Description**: Set damping to 0 (no damping, bodies move forever).

**Params**: `{ "value": 0 }`

**Expected result**: Success response. 0 is the minimum allowed by `.min(0)`.

**Pay attention**: Zero damping is a valid scenario (ideal conditions, no friction).

---

#### 5. Boundary — below minimum (-0.1)

**Description**: Set negative damping.

**Params**: `{ "value": -0.1 }`

**Expected result**: Error response (`isError: true`) — Zod `.min(0)` rejects negative values.

**Pay attention**: Negative damping has no physical meaning. Zod validation error.

---

#### 6. Large value

**Description**: Set extremely high damping.

**Params**: `{ "value": 1000 }`

**Expected result**: Success response (no max constraint in schema).

**Pay attention**: No upper bound in the schema. Godot must accept the value.

---

## Cross-Tool Sequences

### Sequence 1: Full physics configuration workflow

**Description**: Set up a complete 2D physics configuration from scratch.

**Steps**:
1. `set_physics_fps` → `{ "fps": 60 }`
2. `set_physics_engine` → `{ "engine": "godot_physics" }`
3. `set_gravity` → `{ "x": 0, "y": 980 }`
4. `set_default_gravity` → `{ "value": 980 }`
5. `set_default_linear_damp` → `{ "value": 0.05 }`
6. `get_physics_settings` → verify all values

**Expected**: All settings applied; `get_physics_settings` returns the configured values.

**Pay attention**: The order of calls may matter. Some Godot settings may be interdependent (e.g., engine needs to be set before gravity). Verify that the final `get_physics_settings` reflects all changes.

---

### Sequence 2: Collision layer naming workflow

**Description**: Set up named collision layers, then verify.

**Steps**:
1. `set_collision_layer_name` → `{ "layer": 1, "name": "Player" }`
2. `set_collision_layer_name` → `{ "layer": 2, "name": "Enemies" }`
3. `set_collision_layer_name` → `{ "layer": 3, "name": "Terrain" }`
4. `get_collision_layers` → verify all three names

**Expected**: All three layer names present in `get_collision_layers` response.

**Pay attention**: Sequence: first name the layers, then verify. The naming order should not affect the result.

---

### Sequence 3: Reset gravity after tests

**Description**: Restore gravity to standard values after running tests that changed it.

**Steps**:
1. `set_gravity` → `{ "x": 0, "y": 980 }`
2. `set_default_gravity` → `{ "value": 980 }`
3. `get_physics_settings` → confirm reset

**Expected**: Gravity restored to 2D defaults.

**Pay attention**: Important for cleanup tests. If tests change global settings, they must be restored to avoid breaking other tests.

---

## Notes for Test Implementers

1. **Response format**: All tools return `{ content: [{ type: 'text', text: string }], isError?: boolean }`. Success means `isError` is absent or `false`. Parse `text` as JSON when needed.

2. **Validation layer**: Zod schemas validate parameters on the MCP server side BEFORE the request reaches Godot. Tests for invalid params (wrong type, out of range, missing required) verify this server-side validation, not Godot's behavior.

3. **Godot state**: These tools modify global project settings. Tests that change settings should restore them afterwards (see Sequence 3).

4. **Engine availability**: `set_physics_engine` with `"jolt"` requires the Jolt plugin to be installed in the Godot project. If testing without Jolt, expect a backend error (not a validation error).

5. **Default value handling**: Tools with `.optional().default(...)` (fps, linear_damp) have their defaults applied by Zod before the request is sent. The backend always receives the value — it never sees `undefined`.

6. **Idempotency**: Read tools (`get_physics_settings`, `get_collision_layers`) are idempotent. Write tools may or may not be idempotent depending on Godot's undo/redo behavior — test by calling twice and checking the result is the same.
