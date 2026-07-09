# Test Plan: Input Tools (`server/src/tools/input.ts`)

> **Module**: `input.ts` — 8 tools for input simulation  
> **Dependencies**: `shared-types.ts` (z, Position2D, Pressed)  
> **Bridge**: All tools call `callGodot(bridge, endpoint, args)` and return its result directly  
> **Prerequisite**: Godot editor must be running with MCP plugin active, a scene must be open

---

## Table of Contents

1. [simulate_key](#tool-1-simulate_key)
2. [simulate_mouse_click](#tool-2-simulate_mouse_click)
3. [simulate_mouse_move](#tool-3-simulate_mouse_move)
4. [simulate_action](#tool-4-simulate_action)
5. [simulate_sequence](#tool-5-simulate_sequence)
6. [get_input_actions](#tool-6-get_input_actions)
7. [set_input_action](#tool-7-set_input_action)
8. [remove_input_action](#tool-8-remove_input_action)

---

## Tool 1: `simulate_key`

**Description**: Simulate a keyboard key press/release in the running game  
**Endpoint**: `input/simulate_key`  
**Schema**:

| Parameter | Type | Required | Default | Constraints | Description |
|-----------|------|----------|---------|-------------|-------------|
| `keycode` | `string` | **yes** | — | Godot key code name | Key code name (e.g. 'KEY_ENTER', 'KEY_SPACE', 'KEY_A') |
| `pressed` | `boolean` | no | `true` | — | Whether pressed (default: true) |
| `echo` | `boolean` | no | — | — | Whether this is an echo/repeat event |

### Test Scenarios

#### 1.1 — Happy path: press a key with minimum required params

- **Description**: Simulate pressing the Enter key with only the required `keycode` parameter
- **Params**:
  ```json
  { "keycode": "KEY_ENTER" }
  ```
- **Expected result**: `callGodot` called with endpoint `input/simulate_key` and args `{ keycode: "KEY_ENTER" }`. Zod defaults `pressed` to `true`. Response is a success result.
- **Notes**: The `pressed` field will be injected by Zod default (`true`) even though not explicitly passed. Verify the Godot side receives `pressed: true`.

#### 1.2 — Explicit press = true

- **Description**: Explicitly set `pressed` to `true` for a space bar press
- **Params**:
  ```json
  { "keycode": "KEY_SPACE", "pressed": true }
  ```
- **Expected result**: Success. Godot receives `{ keycode: "KEY_SPACE", pressed: true }`.

#### 1.3 — Key release (pressed = false)

- **Description**: Simulate releasing the A key
- **Params**:
  ```json
  { "keycode": "KEY_A", "pressed": false }
  ```
- **Expected result**: Success. Godot receives `{ keycode: "KEY_A", pressed: false }`.

#### 1.4 — Echo/repeat event

- **Description**: Simulate an echo (key repeat) event for the Enter key
- **Params**:
  ```json
  { "keycode": "KEY_ENTER", "pressed": true, "echo": true }
  ```
- **Expected result**: Success. Godot receives all three fields. The echo flag distinguishes this from a first-press event.

#### 1.5 — Echo = false explicitly

- **Description**: Explicitly mark as non-echo press
- **Params**:
  ```json
  { "keycode": "KEY_ESCAPE", "pressed": true, "echo": false }
  ```
- **Expected result**: Success.

#### 1.6 — Missing required param: no keycode

- **Description**: Call without the required `keycode` field
- **Params**:
  ```json
  { "pressed": true }
  ```
- **Expected result**: Zod validation error. The tool should return an error indicating `keycode` is required.
- **Notes**: This tests the MCP schema validation layer, not Godot. The request should be rejected before reaching `callGodot`.

#### 1.7 — Invalid keycode type: number instead of string

- **Description**: Pass a number for keycode
- **Params**:
  ```json
  { "keycode": 65 }
  ```
- **Expected result**: Zod validation error — `keycode` must be a string.

#### 1.8 — Empty string keycode

- **Description**: Pass an empty string as keycode
- **Params**:
  ```json
  { "keycode": "" }
  ```
- **Expected result**: May pass Zod validation (empty string is a valid `z.string()`), but Godot may reject it. Document the behavior — if Godot returns an error, that is the expected result.
- **Notes**: This is a boundary test. Check whether the Godot side handles empty keycodes gracefully or returns an error.

---

## Tool 2: `simulate_mouse_click`

**Description**: Simulate a mouse click at a screen position  
**Endpoint**: `input/simulate_mouse_click`  
**Schema**:

| Parameter | Type | Required | Default | Constraints | Description |
|-----------|------|----------|---------|-------------|-------------|
| `position` | `[number, number]` | **yes** | — | Array of exactly 2 numbers | Screen position [x, y] |
| `button` | `enum` | no | `"left"` | `'left' \| 'right' \| 'middle'` | Mouse button (default: left) |
| `pressed` | `boolean` | no | `true` | — | Whether pressed (default: true) |

### Test Scenarios

#### 2.1 — Happy path: left click at position

- **Description**: Simulate a left mouse button press at coordinates (100, 200)
- **Params**:
  ```json
  { "position": [100, 200] }
  ```
- **Expected result**: Success. Godot receives `{ position: [100, 200] }`. Zod defaults: `button` = `"left"`, `pressed` = `true`.

#### 2.2 — Right click with explicit button

- **Description**: Simulate a right-click at (500, 300)
- **Params**:
  ```json
  { "position": [500, 300], "button": "right", "pressed": true }
  ```
- **Expected result**: Success.

#### 2.3 — Middle button click

- **Description**: Simulate a middle mouse button click
- **Params**:
  ```json
  { "position": [0, 0], "button": "middle" }
  ```
- **Expected result**: Success.

#### 2.4 — Mouse button release

- **Description**: Simulate releasing the left mouse button
- **Params**:
  ```json
  { "position": [250, 250], "button": "left", "pressed": false }
  ```
- **Expected result**: Success. This is a "mouse up" event.

#### 2.5 — Origin position [0, 0]

- **Description**: Click at the top-left corner
- **Params**:
  ```json
  { "position": [0, 0] }
  ```
- **Expected result**: Success. Tests boundary at zero coordinates.

#### 2.6 — Large coordinates

- **Description**: Click at a high-resolution position
- **Params**:
  ```json
  { "position": [3840, 2160] }
  ```
- **Expected result**: Success. Tests that large screen coordinates are handled.

#### 2.7 — Negative coordinates

- **Description**: Click at negative coordinates (off-screen)
- **Params**:
  ```json
  { "position": [-100, -50] }
  ```
- **Expected result**: May succeed at the Godot level (Godot may clamp or pass through). Document actual behavior.
- **Notes**: Negative positions are technically valid numbers in the schema but may represent off-screen areas.

#### 2.8 — Invalid button enum value

- **Description**: Pass an invalid button name
- **Params**:
  ```json
  { "position": [100, 100], "button": "double" }
  ```
- **Expected result**: Zod validation error — `button` must be one of `'left'`, `'right'`, `'middle'`.

#### 2.9 — Missing required position

- **Description**: Call without position
- **Params**:
  ```json
  { "button": "left" }
  ```
- **Expected result**: Zod validation error — `position` is required.

#### 2.10 — Wrong position type: 3-element array

- **Description**: Pass a 3-element array instead of 2
- **Params**:
  ```json
  { "position": [100, 200, 300] }
  ```
- **Expected result**: Zod validation error — `Position2D` requires exactly 2 elements (`.length(2)`).

#### 2.11 — Wrong position type: string instead of array

- **Description**: Pass a string for position
- **Params**:
  ```json
  { "position": "100,200" }
  ```
- **Expected result**: Zod validation error — `position` must be an array.

#### 2.12 — Float coordinates

- **Description**: Use fractional pixel positions
- **Params**:
  ```json
  { "position": [100.5, 200.75] }
  ```
- **Expected result**: Success. `Position2D` is `z.array(z.number())` — floats are valid. Godot may truncate or round.

---

## Tool 3: `simulate_mouse_move`

**Description**: Simulate mouse movement to a screen position  
**Endpoint**: `input/simulate_mouse_move`  
**Schema**:

| Parameter | Type | Required | Default | Constraints | Description |
|-----------|------|----------|---------|-------------|-------------|
| `position` | `[number, number]` | **yes** | — | Array of exactly 2 numbers | Target screen position [x, y] |
| `relative` | `boolean` | no | — | — | If true, position is relative to current mouse position |

### Test Scenarios

#### 3.1 — Happy path: absolute move

- **Description**: Move mouse to absolute position (400, 300)
- **Params**:
  ```json
  { "position": [400, 300] }
  ```
- **Expected result**: Success. Mouse moves to absolute screen coordinates (400, 300).

#### 3.2 — Relative move

- **Description**: Move mouse relative to current position by (50, -25)
- **Params**:
  ```json
  { "position": [50, -25], "relative": true }
  ```
- **Expected result**: Success. Mouse moves 50px right and 25px up from current position.

#### 3.3 — Relative = false explicitly

- **Description**: Explicitly mark as absolute move
- **Params**:
  ```json
  { "position": [0, 0], "relative": false }
  ```
- **Expected result**: Success. Mouse moves to absolute (0, 0).

#### 3.4 — Zero movement (relative)

- **Description**: Relative move by (0, 0) — no movement
- **Params**:
  ```json
  { "position": [0, 0], "relative": true }
  ```
- **Expected result**: Success. No actual mouse movement.

#### 3.5 — Missing required position

- **Description**: Call without position
- **Params**:
  ```json
  { "relative": true }
  ```
- **Expected result**: Zod validation error — `position` is required.

#### 3.6 — Large relative offset

- **Description**: Large relative movement
- **Params**:
  ```json
  { "position": [5000, -5000], "relative": true }
  ```
- **Expected result**: Success at the schema level. Godot may clamp to screen bounds.

---

## Tool 4: `simulate_action`

**Description**: Simulate an input action (from InputMap) being pressed/released  
**Endpoint**: `input/simulate_action`  
**Schema**:

| Parameter | Type | Required | Default | Constraints | Description |
|-----------|------|----------|---------|-------------|-------------|
| `action` | `string` | **yes** | — | Must match an InputMap action name | Input action name (e.g. 'ui_accept', 'move_left') |
| `pressed` | `boolean` | no | `true` | — | Whether pressed (default: true) |

### Test Scenarios

#### 4.1 — Happy path: press a built-in action

- **Description**: Simulate pressing the built-in `ui_accept` action
- **Params**:
  ```json
  { "action": "ui_accept" }
  ```
- **Expected result**: Success. Godot receives `{ action: "ui_accept" }` with `pressed` defaulting to `true`.

#### 4.2 — Release an action

- **Description**: Simulate releasing `ui_accept`
- **Params**:
  ```json
  { "action": "ui_accept", "pressed": false }
  ```
- **Expected result**: Success.

#### 4.3 — Custom action

- **Description**: Simulate a custom game action
- **Params**:
  ```json
  { "action": "move_left", "pressed": true }
  ```
- **Expected result**: Success if `move_left` is defined in the project's InputMap. If not defined, Godot may return an error — document behavior.
- **Notes**: **Depends on project configuration**. Use `get_input_actions` first to discover available action names.

#### 4.4 — Nonexistent action

- **Description**: Simulate an action that does not exist in the InputMap
- **Params**:
  ```json
  { "action": "nonexistent_action_xyz" }
  ```
- **Expected result**: Godot should return an error or warning that the action is not defined.
- **Notes**: Tests error handling for invalid action names.

#### 4.5 — Missing required action

- **Description**: Call without the action field
- **Params**:
  ```json
  { "pressed": true }
  ```
- **Expected result**: Zod validation error — `action` is required.

#### 4.6 — Empty string action

- **Description**: Pass empty string as action name
- **Params**:
  ```json
  { "action": "" }
  ```
- **Expected result**: May pass Zod validation (empty string is valid `z.string()`). Godot should reject it.
- **Notes**: Boundary test. Document Godot's response.

---

## Tool 5: `simulate_sequence`

**Description**: Simulate a sequence of input events with timing  
**Endpoint**: `input/simulate_sequence`  
**Schema**:

| Parameter | Type | Required | Default | Constraints | Description |
|-----------|------|----------|---------|-------------|-------------|
| `events` | `Array<object>` | **yes** | — | Non-empty array recommended | Sequence of input events to simulate |

Each event object:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `type` | `string` | **yes** | — | Event type (e.g. 'key', 'mouse_click', 'mouse_move', 'action') |
| `delay` | `number` | no | — | Delay before this event in milliseconds |
| *(other)* | *any* | no | — | Additional event-specific properties (passthrough) |

### Test Scenarios

#### 5.1 — Happy path: single key event

- **Description**: Simulate a single key press event
- **Params**:
  ```json
  {
    "events": [
      { "type": "key", "keycode": "KEY_SPACE", "pressed": true }
    ]
  }
  ```
- **Expected result**: Success. Godot processes one key event.

#### 5.2 — Multi-event sequence with delays

- **Description**: Simulate a sequence: press W, wait 100ms, release W
- **Params**:
  ```json
  {
    "events": [
      { "type": "key", "keycode": "KEY_W", "pressed": true, "delay": 0 },
      { "type": "key", "keycode": "KEY_W", "pressed": false, "delay": 100 }
    ]
  }
  ```
- **Expected result**: Success. Godot receives both events and waits 100ms between them.

#### 5.3 — Mixed event types: key + mouse + action

- **Description**: Sequence combining keyboard, mouse, and action events
- **Params**:
  ```json
  {
    "events": [
      { "type": "action", "action": "move_left", "pressed": true, "delay": 0 },
      { "type": "mouse_move", "position": [200, 300], "delay": 50 },
      { "type": "mouse_click", "position": [200, 300], "button": "left", "pressed": true, "delay": 50 },
      { "type": "action", "action": "move_left", "pressed": false, "delay": 100 }
    ]
  }
  ```
- **Expected result**: Success. All four events are processed in order with specified delays.

#### 5.4 — Empty events array

- **Description**: Pass an empty array
- **Params**:
  ```json
  { "events": [] }
  ```
- **Expected result**: May pass Zod validation (empty array is valid `z.array(...)`). Godot should handle gracefully — either success with no-op or an error.
- **Notes**: Boundary test. Document behavior.

#### 5.5 — Events without delay

- **Description**: Multiple events with no delay specified
- **Params**:
  ```json
  {
    "events": [
      { "type": "key", "keycode": "KEY_A", "pressed": true },
      { "type": "key", "keycode": "KEY_B", "pressed": true },
      { "type": "key", "keycode": "KEY_C", "pressed": true }
    ]
  }
  ```
- **Expected result**: Success. Events execute back-to-back without artificial delays.

#### 5.6 — Missing required events field

- **Description**: Call without events
- **Params**:
  ```json
  {}
  ```
- **Expected result**: Zod validation error — `events` is required.

#### 5.7 — Event missing required type field

- **Description**: Event object without `type`
- **Params**:
  ```json
  {
    "events": [
      { "keycode": "KEY_ENTER", "pressed": true }
    ]
  }
  ```
- **Expected result**: Zod validation error — each event must have `type`.

#### 5.8 — Passthrough: extra event properties

- **Description**: Include extra properties that are not in the schema but should pass through
- **Params**:
  ```json
  {
    "events": [
      { "type": "key", "keycode": "KEY_ENTER", "pressed": true, "custom_prop": 42 }
    ]
  }
  ```
- **Expected result**: Success. The `.passthrough()` on the event schema allows extra fields. Godot receives the full object including `custom_prop`.
- **Notes**: The `.passthrough()` is critical for flexibility — Godot event types have varying properties.

#### 5.9 — Large sequence

- **Description**: Simulate 10 rapid key presses
- **Params**:
  ```json
  {
    "events": [
      { "type": "key", "keycode": "KEY_A", "pressed": true, "delay": 10 },
      { "type": "key", "keycode": "KEY_A", "pressed": false, "delay": 10 },
      { "type": "key", "keycode": "KEY_B", "pressed": true, "delay": 10 },
      { "type": "key", "keycode": "KEY_B", "pressed": false, "delay": 10 },
      { "type": "key", "keycode": "KEY_C", "pressed": true, "delay": 10 },
      { "type": "key", "keycode": "KEY_C", "pressed": false, "delay": 10 },
      { "type": "key", "keycode": "KEY_D", "pressed": true, "delay": 10 },
      { "type": "key", "keycode": "KEY_D", "pressed": false, "delay": 10 },
      { "type": "key", "keycode": "KEY_E", "pressed": true, "delay": 10 },
      { "type": "key", "keycode": "KEY_E", "pressed": false, "delay": 10 }
    ]
  }
  ```
- **Expected result**: Success. Tests sequence handling with many events.

---

## Tool 6: `get_input_actions`

**Description**: Get all input actions defined in the InputMap  
**Endpoint**: `input/get_actions`  
**Schema**: `{}` (no parameters)

### Test Scenarios

#### 6.1 — Happy path: retrieve all actions

- **Description**: Call with no parameters to get all defined input actions
- **Params**:
  ```json
  {}
  ```
- **Expected result**: Success. Returns a list of all input actions defined in the project's InputMap. The result should include built-in `ui_*` actions (e.g. `ui_accept`, `ui_cancel`, `ui_up`, `ui_down`, `ui_left`, `ui_right`) plus any custom actions defined in the project.
- **Notes**: 
  - The exact content depends on the Godot project's `project.godot` InputMap section.
  - This tool is useful as a **prerequisite** for `simulate_action` and `set_input_action` — use it to discover valid action names.
  - Verify the response structure: likely an array of action objects with name, events, and deadzone info.

#### 6.2 — Verify response contains expected structure

- **Description**: Inspect the response format for action entries
- **Params**:
  ```json
  {}
  ```
- **Expected result**: Each action in the response should have at minimum: action name. May also include: deadzone, events array with type/key details.
- **Notes**: Document the exact response structure for downstream test planning.

---

## Tool 7: `set_input_action`

**Description**: Add or modify an input action and its event mappings  
**Endpoint**: `input/set_action`  
**Schema**:

| Parameter | Type | Required | Default | Constraints | Description |
|-----------|------|----------|---------|-------------|-------------|
| `action` | `string` | **yes** | — | — | Action name |
| `deadzone` | `number` | no | `0.5` | `min: 0`, `max: 1` | Input deadzone value (0-1, default: 0.5) |
| `events` | `Array<object>` | **yes** | — | Non-empty array recommended | List of input events to map to this action |

Each event object:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `type` | `string` | **yes** | — | Event type (e.g. 'key', 'mouse_button', 'joypad_button') |
| *(other)* | *any* | no | — | Additional event-specific properties (passthrough) |

### Test Scenarios

#### 7.1 — Happy path: create a new key-based action

- **Description**: Define a new action `jump` mapped to the space bar
- **Params**:
  ```json
  {
    "action": "jump",
    "events": [
      { "type": "key", "keycode": "KEY_SPACE" }
    ]
  }
  ```
- **Expected result**: Success. A new action `jump` is added to the InputMap with the space key binding. Verify by calling `get_input_actions` afterwards.
- **Notes**: **Post-verification**: Call `get_input_actions` to confirm the action was created with the correct mapping.

#### 7.2 — Action with custom deadzone

- **Description**: Create an action with a specific deadzone value
- **Params**:
  ```json
  {
    "action": "move_forward",
    "deadzone": 0.3,
    "events": [
      { "type": "key", "keycode": "KEY_W" }
    ]
  }
  ```
- **Expected result**: Success. The deadzone is set to 0.3 instead of the default 0.5.

#### 7.3 — Action with multiple key bindings

- **Description**: Map multiple keys to a single action
- **Params**:
  ```json
  {
    "action": "interact",
    "events": [
      { "type": "key", "keycode": "KEY_E" },
      { "type": "key", "keycode": "KEY_F" }
    ]
  }
  ```
- **Expected result**: Success. Both E and F keys trigger the `interact` action.

#### 7.4 — Modify existing action

- **Description**: Overwrite an existing action's mappings (e.g. change `ui_accept`)
- **Params**:
  ```json
  {
    "action": "ui_accept",
    "events": [
      { "type": "key", "keycode": "KEY_ENTER" },
      { "type": "key", "keycode": "KEY_SPACE" }
    ]
  }
  ```
- **Expected result**: Success. The `ui_accept` action's event list is replaced.
- **Notes**: **Pre-verification**: Call `get_input_actions` before to record original mappings. **Post-verification**: Call `get_input_actions` after to confirm changes.

#### 7.5 — Deadzone at boundary: 0

- **Description**: Set deadzone to minimum value 0
- **Params**:
  ```json
  {
    "action": "test_deadzone_min",
    "deadzone": 0,
    "events": [
      { "type": "key", "keycode": "KEY_T" }
    ]
  }
  ```
- **Expected result**: Success. Deadzone of 0 means maximum sensitivity.

#### 7.6 — Deadzone at boundary: 1

- **Description**: Set deadzone to maximum value 1
- **Params**:
  ```json
  {
    "action": "test_deadzone_max",
    "deadzone": 1,
    "events": [
      { "type": "key", "keycode": "KEY_T" }
    ]
  }
  ```
- **Expected result**: Success. Deadzone of 1 means minimum sensitivity (requires full input to trigger).

#### 7.7 — Deadzone out of range: below 0

- **Description**: Set deadzone to -0.1
- **Params**:
  ```json
  {
    "action": "test_deadzone_invalid_low",
    "deadzone": -0.1,
    "events": [
      { "type": "key", "keycode": "KEY_T" }
    ]
  }
  ```
- **Expected result**: Zod validation error — `deadzone` must be >= 0.

#### 7.8 — Deadzone out of range: above 1

- **Description**: Set deadzone to 1.5
- **Params**:
  ```json
  {
    "action": "test_deadzone_invalid_high",
    "deadzone": 1.5,
    "events": [
      { "type": "key", "keycode": "KEY_T" }
    ]
  }
  ```
- **Expected result**: Zod validation error — `deadzone` must be <= 1.

#### 7.9 — Joypad button event

- **Description**: Map a joypad button to an action
- **Params**:
  ```json
  {
    "action": "gamepad_jump",
    "events": [
      { "type": "joypad_button", "button_index": 0 }
    ]
  }
  ```
- **Expected result**: Success. The `.passthrough()` allows `button_index` through even though it is not explicitly in the schema.

#### 7.10 — Missing required action field

- **Description**: Call without `action`
- **Params**:
  ```json
  {
    "events": [
      { "type": "key", "keycode": "KEY_A" }
    ]
  }
  ```
- **Expected result**: Zod validation error — `action` is required.

#### 7.11 — Missing required events field

- **Description**: Call without `events`
- **Params**:
  ```json
  {
    "action": "test_no_events"
  }
  ```
- **Expected result**: Zod validation error — `events` is required.

#### 7.12 — Empty events array

- **Description**: Pass empty events array
- **Params**:
  ```json
  {
    "action": "test_empty_events",
    "events": []
  }
  ```
- **Expected result**: May pass Zod validation. Godot may create an action with no bindings or return an error.
- **Notes**: Boundary test. Document behavior.

---

## Tool 8: `remove_input_action`

**Description**: Remove an input action from the InputMap  
**Endpoint**: `input/remove_action`  
**Schema**:

| Parameter | Type | Required | Default | Constraints | Description |
|-----------|------|----------|---------|-------------|-------------|
| `action` | `string` | **yes** | — | Must match an existing InputMap action name | Action name to remove |

### Test Scenarios

#### 8.1 — Happy path: remove an existing custom action

- **Description**: First create a custom action `temp_action` using `set_input_action`, then remove it
- **Params**:
  ```json
  { "action": "temp_action" }
  ```
- **Expected result**: Success. The action `temp_action` is removed from InputMap. Verify by calling `get_input_actions` afterwards — the action should no longer appear.
- **Notes**: **Pre-verification**: Call `set_input_action` to create `temp_action` first, then `get_input_actions` to confirm it exists.

#### 8.2 — Remove a built-in ui_ action

- **Description**: Remove a built-in Godot action like `ui_accept`
- **Params**:
  ```json
  { "action": "ui_accept" }
  ```
- **Expected result**: Success. The built-in `ui_accept` action is removed. Verify via `get_input_actions` with `scope: "all"`.
- **Notes**: Removing built-in `ui_*` actions may affect editor navigation. Be prepared to restore via `set_input_action`.

#### 8.3 — Nonexistent action

- **Description**: Try to remove an action that does not exist
- **Params**:
  ```json
  { "action": "nonexistent_action_xyz" }
  ```
- **Expected result**: Error returned: `"Unknown input action: nonexistent_action_xyz"`. The tool validates existence before attempting removal.

#### 8.4 — Missing required action field

- **Description**: Call without the `action` field
- **Params**:
  ```json
  {}
  ```
- **Expected result**: Error returned: `"Action name is required"`. The tool validates the action name is not empty.

#### 8.5 — Empty string action name

- **Description**: Pass empty string as action name
- **Params**:
  ```json
  { "action": "" }
  ```
- **Expected result**: Error returned: `"Action name is required"`. Empty string is caught by the validation check.

#### 8.6 — Verify project settings saved after removal

- **Description**: Remove a custom action and verify `ProjectSettings.save()` was called (implicit success means save succeeded)
- **Params**:
  ```json
  { "action": "my_custom_action" }
  ```
- **Expected result**: Success. If the action existed, it is removed and the change persists across editor restarts (saved to `project.godot`).
- **Notes**: **Pre-requisite**: Create `my_custom_action` via `set_input_action` first.

---

## Cross-Tool Workflows

### Workflow A: Discover → Simulate → Verify

1. **Call `get_input_actions`** to discover available actions
2. **Call `simulate_action`** with one of the discovered action names
3. **Observe** the game's response (may need screenshot or runtime inspection tools)

### Workflow B: Create Action → Simulate It → Verify

1. **Call `set_input_action`** to create a new action `custom_action` with key mapping
2. **Call `get_input_actions`** to verify the action was created
3. **Call `simulate_action`** with `action: "custom_action"` to trigger it
4. **Observe** game behavior

### Workflow C: Full Input Sequence

1. **Call `get_input_actions`** to see what actions exist
2. **Call `simulate_sequence`** with a multi-step sequence combining:
   - Mouse moves to position
   - Mouse click at position
   - Key presses for movement
   - Action triggers
3. Verify the full sequence executed correctly

### Workflow D: Modify Built-in Action → Test → Restore

1. **Call `get_input_actions`** and record the current `ui_accept` mapping
2. **Call `set_input_action`** to remap `ui_accept` to different keys
3. **Call `simulate_action`** with `action: "ui_accept"` — verify it now responds to new keys
4. **Call `set_input_action`** again to restore original mapping

### Workflow E: Create → Test → Remove Action

1. **Call `set_input_action`** to create a new action `temp_jump` mapped to `KEY_SPACE`
2. **Call `get_input_actions`** to verify `temp_jump` was created
3. **Call `simulate_action`** with `action: "temp_jump"` to verify it works
4. **Call `remove_input_action`** with `action: "temp_jump"` to clean up
5. **Call `get_input_actions`** to verify `temp_jump` no longer exists

---

## Notes for Test Execution

1. **All tools require a running Godot editor** with the MCP plugin active and connected via WebSocket.
2. **Game must be running** (Play mode) for `simulate_*` tools to have observable effects. `set_input_action` and `get_input_actions` work at the editor level.
3. **Zod validation** happens on the MCP server side before any Godot call. Validation errors should be returned immediately without hitting the WebSocket.
4. **The `callGodot` function** is the single bridge point — all tools delegate to it with their respective endpoints. Errors from Godot propagate back as tool errors.
5. **`.passthrough()`** on event objects in `simulate_sequence` and `set_input_action` is critical — it allows arbitrary extra properties that Godot event types require (e.g. `keycode` for key events, `button_index` for joypad events, `position` for mouse events).
6. **Pressed default**: Both `simulate_key` and `simulate_action` use the `Pressed` schema which defaults to `true`. Tools that pass `pressed` through Zod will always have this field populated.
7. **Position2D validation**: `z.array(z.number()).length(2)` — strictly 2 elements, no more, no less. This catches common errors like passing `[x, y, z]` or `["100", "200"]`.
