# Input Tools — Test Plan

**Source:** `server/src/tools/input.ts`
**Date:** 2026-07-08
**Coverage:** 7 tools (simulate_key, simulate_mouse_click, simulate_mouse_move, simulate_action, simulate_sequence, get_input_actions, set_input_action)

---

## Tool: `simulate_key`

**Description:** Simulate a keyboard key press/release in the running game.
**Handler:** `callGodot(bridge, 'input/simulate_key', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `keycode` | string | **yes** | — | Key code name (e.g. `KEY_ENTER`, `KEY_SPACE`, `KEY_A`) |
| `pressed` | boolean | no | `true` | Whether pressed (default: true) |
| `echo` | boolean | no | — | Whether this is an echo/repeat event |

### Test Scenarios

#### 1. Happy path — press a key (default pressed=true)
- **Description:** Press the space key with minimal params.
- **Params:** `{ "keycode": "KEY_SPACE" }`
- **Expected result:** `success`, key press event dispatched for `KEY_SPACE` with `pressed=true`.
- **Notes:** Verifies default value of `pressed` is `true`.

#### 2. Release a key (pressed=false)
- **Description:** Release the space key.
- **Params:** `{ "keycode": "KEY_SPACE", "pressed": false }`
- **Expected result:** `success`, key release event dispatched for `KEY_SPACE` with `pressed=false`.

#### 3. Echo / repeat event
- **Description:** Simulate an auto-repeat key event.
- **Params:** `{ "keycode": "KEY_A", "echo": true }`
- **Expected result:** `success`, key event dispatched with `echo=true`.

#### 4. Press with echo=false
- **Description:** Explicitly set echo to false.
- **Params:** `{ "keycode": "KEY_ENTER", "echo": false }`
- **Expected result:** `success`, key event dispatched with `echo=false`.

#### 5. Release with echo
- **Description:** Release a key with echo flag.
- **Params:** `{ "keycode": "KEY_SHIFT", "pressed": false, "echo": true }`
- **Expected result:** `success`, key release event dispatched.

#### 6. Various keycode examples
- **Description:** Test commonly used keycode strings.
- **Params (each as separate call):**
  - `{ "keycode": "KEY_ENTER" }`
  - `{ "keycode": "KEY_ESCAPE" }`
  - `{ "keycode": "KEY_TAB" }`
  - `{ "keycode": "KEY_UP" }`
  - `{ "keycode": "KEY_DOWN" }`
  - `{ "keycode": "KEY_LEFT" }`
  - `{ "keycode": "KEY_RIGHT" }`
  - `{ "keycode": "KEY_CONTROL" }`
  - `{ "keycode": "KEY_ALT" }`
  - `{ "keycode": "KEY_W" }`
  - `{ "keycode": "KEY_F1" }`
- **Expected result:** `success` for each.
- **Notes:** Coverage of arrow keys, modifier keys, letter keys, function keys, action keys.

#### 7. Missing required param — no keycode
- **Description:** Call without `keycode`.
- **Params:** `{}`
- **Expected result:** Validation error (missing required field `keycode`).

#### 8. Invalid keycode type — number instead of string
- **Description:** Pass a number as keycode.
- **Params:** `{ "keycode": 123 }`
- **Expected result:** Validation error (expected string).

#### 9. Invalid pressed type
- **Description:** Pass a string instead of boolean.
- **Params:** `{ "keycode": "KEY_SPACE", "pressed": "true" }`
- **Expected result:** Validation error (expected boolean).

#### 10. Invalid echo type
- **Description:** Pass a string instead of boolean.
- **Params:** `{ "keycode": "KEY_A", "echo": "yes" }`
- **Expected result:** Validation error (expected boolean).

#### 11. Empty keycode string
- **Description:** Pass an empty string.
- **Params:** `{ "keycode": "" }`
- **Expected result:** Request sent to Godot; Godot may reject or ignore. Server passes it through.
- **Notes:** Server does not validate keycode format.

---

## Tool: `simulate_mouse_click`

**Description:** Simulate a mouse click at a screen position.
**Handler:** `callGodot(bridge, 'input/simulate_mouse_click', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `position` | `[number, number]` | **yes** | — | Screen position `[x, y]` |
| `button` | `"left" \| "right" \| "middle"` | no | `"left"` | Mouse button (default: left) |
| `pressed` | boolean | no | `true` | Whether pressed (default: true) |

### Test Scenarios

#### 1. Happy path — left click at position (defaults)
- **Description:** Click left mouse button at screen position [100, 200] using defaults.
- **Params:** `{ "position": [100, 200] }`
- **Expected result:** `success`, left button click event at (100, 200) with `pressed=true`.

#### 2. Right button click
- **Description:** Click the right mouse button.
- **Params:** `{ "position": [300, 400], "button": "right" }`
- **Expected result:** `success`, right mouse button click event.

#### 3. Middle button click
- **Description:** Click the middle mouse button.
- **Params:** `{ "position": [500, 600], "button": "middle" }`
- **Expected result:** `success`, middle mouse button click event.

#### 4. Mouse button release
- **Description:** Release a mouse button.
- **Params:** `{ "position": [100, 200], "pressed": false }`
- **Expected result:** `success`, button release event.

#### 5. Right button release
- **Description:** Release right mouse button.
- **Params:** `{ "position": [100, 200], "button": "right", "pressed": false }`
- **Expected result:** `success`.

#### 6. Middle button release
- **Description:** Release middle mouse button.
- **Params:** `{ "position": [100, 200], "button": "middle", "pressed": false }`
- **Expected result:** `success`.

#### 7. All three buttons pressed (left, right, middle) — sequential calls
- **Description:** Test each button enum value with pressed=true.
- **Params (each as separate call):**
  - `{ "position": [10, 10], "button": "left" }`
  - `{ "position": [10, 10], "button": "right" }`
  - `{ "position": [10, 10], "button": "middle" }`
- **Expected result:** `success` for each.

#### 8. Zero position
- **Description:** Click at origin (0, 0).
- **Params:** `{ "position": [0, 0] }`
- **Expected result:** `success`.

#### 9. Negative position
- **Description:** Click at a negative screen position.
- **Params:** `{ "position": [-50, -100] }`
- **Expected result:** `success`; Godot dispatches event. Actual screen hit depends on viewport.
- **Notes:** Server doesn't validate position range — sends as-is.

#### 10. Large position values
- **Description:** Click far outside typical screen.
- **Params:** `{ "position": [99999, 99999] }`
- **Expected result:** `success` from server; event dispatched at that coordinate.

#### 11. Missing required param — no position
- **Description:** Call without `position`.
- **Params:** `{}`
- **Expected result:** Validation error (missing required field `position`).

#### 12. Invalid position — wrong array length
- **Description:** Pass a single number instead of [x, y].
- **Params:** `{ "position": [100] }`
- **Expected result:** Validation error (expected exactly 2 elements).

#### 13. Invalid position — string elements
- **Description:** Pass string values in position array.
- **Params:** `{ "position": ["100", "200"] }`
- **Expected result:** Validation error (expected numbers).

#### 14. Invalid button enum value
- **Description:** Pass an unsupported button name.
- **Params:** `{ "position": [100, 200], "button": "extra" }`
- **Expected result:** Validation error (`button` must be `"left"`, `"right"`, or `"middle"`).

#### 15. Position with extra array elements
- **Description:** Pass a 3-element array.
- **Params:** `{ "position": [100, 200, 300] }`
- **Expected result:** Validation error (expected exactly 2 elements).

---

## Tool: `simulate_mouse_move`

**Description:** Simulate mouse movement to a screen position.
**Handler:** `callGodot(bridge, 'input/simulate_mouse_move', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `position` | `[number, number]` | **yes** | — | Target screen position `[x, y]` |
| `relative` | boolean | no | — | If true, position is relative to current mouse position |

### Test Scenarios

#### 1. Happy path — absolute move
- **Description:** Move mouse to an absolute screen position.
- **Params:** `{ "position": [400, 300] }`
- **Expected result:** `success`, mouse moved to (400, 300).

#### 2. Absolute move to origin
- **Description:** Move mouse to (0, 0).
- **Params:** `{ "position": [0, 0] }`
- **Expected result:** `success`.

#### 3. Relative move (relative=true)
- **Description:** Move mouse by a relative offset.
- **Params:** `{ "position": [50, -50], "relative": true }`
- **Expected result:** `success`, mouse moved by +50 in X and -50 in Y from current position.

#### 4. Relative move with negative values
- **Description:** Move relative by negative offset.
- **Params:** `{ "position": [-100, -200], "relative": true }`
- **Expected result:** `success`, mouse moved left and up.

#### 5. Relative move with zero offset
- **Description:** Relative move of (0, 0).
- **Params:** `{ "position": [0, 0], "relative": true }`
- **Expected result:** `success`, no movement.

#### 6. Explicit relative=false
- **Description:** Absolute move with relative explicitly set to false.
- **Params:** `{ "position": [200, 100], "relative": false }`
- **Expected result:** `success`, mouse moved to absolute (200, 100).

#### 7. Large absolute position
- **Description:** Move to a far-off coordinate.
- **Params:** `{ "position": [99999, 99999] }`
- **Expected result:** `success`, event dispatched.

#### 8. Negative absolute position
- **Description:** Move to negative screen coordinates.
- **Params:** `{ "position": [-500, -500] }`
- **Expected result:** `success`.

#### 9. Missing required param — no position
- **Description:** Call without `position`.
- **Params:** `{}`
- **Expected result:** Validation error (missing required field `position`).

#### 10. Invalid position — wrong array length
- **Description:** Single-element array.
- **Params:** `{ "position": [100] }`
- **Expected result:** Validation error.

#### 11. Invalid position — non-number elements
- **Description:** String values in position.
- **Params:** `{ "position": ["x", "y"] }`
- **Expected result:** Validation error (expected numbers).

#### 12. Invalid relative type
- **Description:** Pass a string instead of boolean.
- **Params:** `{ "position": [100, 200], "relative": "true" }`
- **Expected result:** Validation error (expected boolean).

---

## Tool: `simulate_action`

**Description:** Simulate an input action (from InputMap) being pressed/released.
**Handler:** `callGodot(bridge, 'input/simulate_action', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `action` | string | **yes** | — | Input action name (e.g. `ui_accept`, `move_left`) |
| `pressed` | boolean | no | `true` | Whether pressed (default: true) |

### Test Scenarios

#### 1. Happy path — press an action (default pressed=true)
- **Description:** Simulate pressing a built-in action.
- **Params:** `{ "action": "ui_accept" }`
- **Expected result:** `success`, action `ui_accept` dispatched with `pressed=true`.

#### 2. Release an action
- **Description:** Simulate releasing an action.
- **Params:** `{ "action": "ui_accept", "pressed": false }`
- **Expected result:** `success`, action released.

#### 3. Various common built-in actions
- **Description:** Test commonly available actions.
- **Params (each as separate call):**
  - `{ "action": "ui_cancel" }`
  - `{ "action": "ui_up" }`
  - `{ "action": "ui_down" }`
  - `{ "action": "ui_left" }`
  - `{ "action": "ui_right" }`
  - `{ "action": "ui_select" }`
  - `{ "action": "ui_focus_next" }`
  - `{ "action": "ui_focus_prev" }`
- **Expected result:** `success` for each.

#### 4. Custom / user-defined action name
- **Description:** Simulate a custom action (e.g. `move_left`, `jump`).
- **Params:** `{ "action": "jump" }`
- **Expected result:** `success` dispatched; Godot may ignore if action name is not in InputMap.
- **Notes:** Server passes any action string through without validation.

#### 5. Press and release explicitly
- **Description:** Explicit pressed=true.
- **Params:** `{ "action": "ui_accept", "pressed": true }`
- **Expected result:** `success`.

#### 6. Missing required param — no action
- **Description:** Call without `action`.
- **Params:** `{}`
- **Expected result:** Validation error (missing required field `action`).

#### 7. Empty action string
- **Description:** Pass empty action name.
- **Params:** `{ "action": "" }`
- **Expected result:** `success` from server (passes through); Godot behavior undefined.

#### 8. Invalid pressed type
- **Description:** Pass string instead of boolean.
- **Params:** `{ "action": "ui_accept", "pressed": "yes" }`
- **Expected result:** Validation error (expected boolean).

#### 9. Action with special characters
- **Description:** Action name containing spaces or special chars.
- **Params:** `{ "action": "my custom action!" }`
- **Expected result:** `success` from server; Godot may reject.

---

## Tool: `simulate_sequence`

**Description:** Simulate a sequence of input events with timing.
**Handler:** `callGodot(bridge, 'input/simulate_sequence', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `events` | array of objects | **yes** | — | Sequence of input events to simulate |

Each event object:
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `type` | string | **yes** | — | Event type (e.g. `key`, `mouse_click`, `mouse_move`, `action`) |
| `delay` | number | no | — | Delay before this event in milliseconds |
| *(any)* | any | no | — | Additional event-specific properties (passthrough) |

### Test Scenarios

#### 1. Happy path — single key event sequence
- **Description:** Sequence with one key press.
- **Params:**
  ```json
  {
    "events": [
      { "type": "key", "keycode": "KEY_ENTER" }
    ]
  }
  ```
- **Expected result:** `success`.

#### 2. Multi-event sequence with delays
- **Description:** Sequence of different event types with delays.
- **Params:**
  ```json
  {
    "events": [
      { "type": "key", "keycode": "KEY_SPACE", "delay": 100 },
      { "type": "mouse_click", "position": [200, 300], "button": "left", "delay": 500 },
      { "type": "action", "action": "ui_accept", "delay": 200 },
      { "type": "mouse_move", "position": [400, 400], "delay": 100 }
    ]
  }
  ```
- **Expected result:** `success`, all events dispatched in order.

#### 3. Sequence with no delays
- **Description:** All events fire immediately.
- **Params:**
  ```json
  {
    "events": [
      { "type": "key", "keycode": "KEY_W" },
      { "type": "key", "keycode": "KEY_A" },
      { "type": "key", "keycode": "KEY_S" },
      { "type": "key", "keycode": "KEY_D" }
    ]
  }
  ```
- **Expected result:** `success`.

#### 4. Sequence with mouse_click events
- **Description:** Sequence containing only mouse clicks at different positions and buttons.
- **Params:**
  ```json
  {
    "events": [
      { "type": "mouse_click", "position": [100, 100], "button": "left" },
      { "type": "mouse_click", "position": [200, 200], "button": "right", "delay": 300 },
      { "type": "mouse_click", "position": [300, 300], "button": "middle", "delay": 300 }
    ]
  }
  ```
- **Expected result:** `success`.

#### 5. Sequence with action events
- **Description:** Sequence of action presses and releases.
- **Params:**
  ```json
  {
    "events": [
      { "type": "action", "action": "jump", "delay": 100 },
      { "type": "action", "action": "jump", "pressed": false, "delay": 500 }
    ]
  }
  ```
- **Expected result:** `success`.

#### 6. Sequence with mouse_move events (absolute + relative)
- **Description:** Mix of absolute and relative mouse moves.
- **Params:**
  ```json
  {
    "events": [
      { "type": "mouse_move", "position": [500, 500], "delay": 100 },
      { "type": "mouse_move", "position": [50, 0], "relative": true, "delay": 200 },
      { "type": "mouse_move", "position": [0, 50], "relative": true, "delay": 200 }
    ]
  }
  ```
- **Expected result:** `success`.

#### 7. Empty events array
- **Description:** Pass an empty events array.
- **Params:** `{ "events": [] }`
- **Expected result:** `success` from server; no events dispatched.
- **Notes:** Server doesn't enforce `min(1)`.

#### 8. Event with zero delay
- **Description:** Explicit delay of 0ms.
- **Params:**
  ```json
  {
    "events": [
      { "type": "key", "keycode": "KEY_A", "delay": 0 }
    ]
  }
  ```
- **Expected result:** `success`, event dispatched immediately.

#### 9. Event with negative delay
- **Description:** Negative delay value.
- **Params:**
  ```json
  {
    "events": [
      { "type": "key", "keycode": "KEY_A", "delay": -100 }
    ]
  }
  ```
- **Expected result:** `success` from server (Zod accepts any number); Godot behavior may vary.

#### 10. Event missing type
- **Description:** Event object without `type`.
- **Params:**
  ```json
  {
    "events": [
      { "keycode": "KEY_A" }
    ]
  }
  ```
- **Expected result:** Validation error (`type` is required in each event).

#### 11. Invalid event type (empty string)
- **Description:** Event with empty type.
- **Params:**
  ```json
  {
    "events": [
      { "type": "" }
    ]
  }
  ```
- **Expected result:** `success` from server (any string accepted); Godot may reject.

#### 12. Extra passthrough properties
- **Description:** Event with additional unrecognized fields.
- **Params:**
  ```json
  {
    "events": [
      { "type": "key", "keycode": "KEY_B", "modifiers": ["shift"], "duration": 100 }
    ]
  }
  ```
- **Expected result:** `success` — passthrough fields forwarded to Godot.

#### 13. Missing required param — no events
- **Description:** Call without `events` at all.
- **Params:** `{}`
- **Expected result:** Validation error (missing required field `events`).

#### 14. Invalid events type — not an array
- **Description:** Pass a plain object instead of array.
- **Params:** `{ "events": { "type": "key", "keycode": "KEY_A" } }`
- **Expected result:** Validation error (expected array).

#### 15. Large sequence (stress test boundary)
- **Description:** Sequence with many events (e.g., 100).
- **Params:**
  ```json
  {
    "events": [
      { "type": "key", "keycode": "KEY_A", "delay": 10 },
      ... repeat 100 times with different keys ...
    ]
  }
  ```
- **Expected result:** `success`.
- **Notes:** Tests throughput and potential timeout.

#### 16. Sequence mixing all four event types
- **Description:** One sequence containing key, mouse_click, mouse_move, and action.
- **Params:**
  ```json
  {
    "events": [
      { "type": "mouse_move", "position": [100, 100] },
      { "type": "mouse_click", "position": [100, 100], "button": "left", "delay": 50 },
      { "type": "key", "keycode": "KEY_ENTER", "delay": 200 },
      { "type": "action", "action": "ui_accept", "delay": 100 }
    ]
  }
  ```
- **Expected result:** `success`.

---

## Tool: `get_input_actions`

**Description:** Get all input actions defined in the InputMap.
**Handler:** `callGodot(bridge, 'input/get_actions')`

### Parameters

*No parameters.*

### Test Scenarios

#### 1. Happy path — fetch input actions
- **Description:** Call with no arguments.
- **Params:** `{}`
- **Expected result:** `success`, returns a list of input action names defined in InputMap (may be empty if no custom actions).

#### 2. Call with extra unexpected params
- **Description:** Pass an arbitrary extra field.
- **Params:** `{ "unexpected": "value" }`
- **Expected result:** `success` (Zod strips unknown keys via `inputSchema: {}`).

#### 3. Verify built-in UI actions are present
- **Description:** Call and verify `ui_accept`, `ui_cancel`, etc. are in the returned list.
- **Params:** `{}`
- **Expected result:** Built-in actions present (e.g. `ui_accept`, `ui_cancel`, `ui_up`, `ui_down`, `ui_left`, `ui_right`).

---

## Tool: `set_input_action`

**Description:** Add or modify an input action and its event mappings.
**Handler:** `callGodot(bridge, 'input/set_action', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `action` | string | **yes** | — | Action name |
| `deadzone` | number (0–1) | no | `0.5` | Input deadzone value (0-1, default: 0.5) |
| `events` | array of objects | **yes** | — | List of input events to map to this action |

Each event object:
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `type` | string | **yes** | — | Event type (e.g. `key`, `mouse_button`, `joypad_button`) |
| *(any)* | any | no | — | Additional event-specific properties (passthrough) |

### Test Scenarios

#### 1. Happy path — set action with key event (default deadzone)
- **Description:** Register a new action mapped to a key, using default deadzone.
- **Params:**
  ```json
  {
    "action": "jump",
    "events": [
      { "type": "key", "keycode": "KEY_SPACE" }
    ]
  }
  ```
- **Expected result:** `success`, action `jump` added/modified with deadzone 0.5.

#### 2. Set action with custom deadzone
- **Description:** Register action with deadzone=0.2.
- **Params:**
  ```json
  {
    "action": "move_right",
    "deadzone": 0.2,
    "events": [
      { "type": "key", "keycode": "KEY_D" },
      { "type": "key", "keycode": "KEY_RIGHT" }
    ]
  }
  ```
- **Expected result:** `success`, action added with deadzone 0.2 and two key mappings.

#### 3. Deadzone boundary — minimum (0)
- **Description:** Set deadzone to 0.
- **Params:**
  ```json
  {
    "action": "sprint",
    "deadzone": 0,
    "events": [
      { "type": "key", "keycode": "KEY_SHIFT" }
    ]
  }
  ```
- **Expected result:** `success`.

#### 4. Deadzone boundary — maximum (1)
- **Description:** Set deadzone to 1.
- **Params:**
  ```json
  {
    "action": "crouch",
    "deadzone": 1,
    "events": [
      { "type": "key", "keycode": "KEY_CONTROL" }
    ]
  }
  ```
- **Expected result:** `success`.

#### 5. Deadzone midpoint (0.5)
- **Description:** Explicit deadzone=0.5.
- **Params:**
  ```json
  {
    "action": "interact",
    "deadzone": 0.5,
    "events": [
      { "type": "key", "keycode": "KEY_E" }
    ]
  }
  ```
- **Expected result:** `success`.

#### 6. Set action with mouse_button events
- **Description:** Map action to mouse buttons.
- **Params:**
  ```json
  {
    "action": "shoot",
    "events": [
      { "type": "mouse_button", "button_index": 1 },
      { "type": "mouse_button", "button_index": 2 }
    ]
  }
  ```
- **Expected result:** `success`.

#### 7. Set action with joypad_button event
- **Description:** Map action to a gamepad button.
- **Params:**
  ```json
  {
    "action": "pause",
    "events": [
      { "type": "joypad_button", "button_index": 7 }
    ]
  }
  ```
- **Expected result:** `success`.

#### 8. Set action with mixed event types
- **Description:** Single action mapped to keyboard, mouse, and joypad.
- **Params:**
  ```json
  {
    "action": "attack",
    "deadzone": 0.3,
    "events": [
      { "type": "key", "keycode": "KEY_J" },
      { "type": "mouse_button", "button_index": 1 },
      { "type": "joypad_button", "button_index": 0 }
    ]
  }
  ```
- **Expected result:** `success`.

#### 9. Modify existing action
- **Description:** Update `ui_accept` with a new event mapping.
- **Params:**
  ```json
  {
    "action": "ui_accept",
    "events": [
      { "type": "key", "keycode": "KEY_ENTER" },
      { "type": "key", "keycode": "KEY_SPACE" }
    ]
  }
  ```
- **Expected result:** `success`, `ui_accept` updated with new mappings.

#### 10. Multiple events of the same type
- **Description:** Map W, A, S, D keys to one action.
- **Params:**
  ```json
  {
    "action": "movement_bundle",
    "deadzone": 0.1,
    "events": [
      { "type": "key", "keycode": "KEY_W" },
      { "type": "key", "keycode": "KEY_A" },
      { "type": "key", "keycode": "KEY_S" },
      { "type": "key", "keycode": "KEY_D" }
    ]
  }
  ```
- **Expected result:** `success`.

#### 11. Missing required param — no action
- **Description:** Call without `action`.
- **Params:**
  ```json
  {
    "events": [
      { "type": "key", "keycode": "KEY_SPACE" }
    ]
  }
  ```
- **Expected result:** Validation error (missing required field `action`).

#### 12. Missing required param — no events
- **Description:** Call without `events`.
- **Params:**
  ```json
  {
    "action": "test_action"
  }
  ```
- **Expected result:** Validation error (missing required field `events`).

#### 13. Missing both required params
- **Description:** Call with empty object.
- **Params:** `{}`
- **Expected result:** Validation error (missing both `action` and `events`).

#### 14. Invalid deadzone — below 0
- **Description:** deadzone=-0.1.
- **Params:**
  ```json
  {
    "action": "bad",
    "deadzone": -0.1,
    "events": [
      { "type": "key", "keycode": "KEY_A" }
    ]
  }
  ```
- **Expected result:** Validation error (deadzone must be >= 0).

#### 15. Invalid deadzone — above 1
- **Description:** deadzone=1.5.
- **Params:**
  ```json
  {
    "action": "bad",
    "deadzone": 1.5,
    "events": [
      { "type": "key", "keycode": "KEY_A" }
    ]
  }
  ```
- **Expected result:** Validation error (deadzone must be <= 1).

#### 16. Invalid deadzone — string instead of number
- **Description:** deadzone="0.5".
- **Params:**
  ```json
  {
    "action": "bad",
    "deadzone": "0.5",
    "events": [
      { "type": "key", "keycode": "KEY_A" }
    ]
  }
  ```
- **Expected result:** Validation error (expected number).

#### 17. Empty action string
- **Description:** Action name is empty.
- **Params:**
  ```json
  {
    "action": "",
    "events": [
      { "type": "key", "keycode": "KEY_A" }
    ]
  }
  ```
- **Expected result:** `success` from server (passes through); Godot may reject.

#### 18. Empty events array
- **Description:** Events array is empty.
- **Params:**
  ```json
  {
    "action": "empty_action",
    "events": []
  }
  ```
- **Expected result:** `success` from server; Godot may retain the action with no mappings.

#### 19. Event missing type
- **Description:** Event without `type` field.
- **Params:**
  ```json
  {
    "action": "broken",
    "events": [
      { "keycode": "KEY_A" }
    ]
  }
  ```
- **Expected result:** Validation error (`type` is required in each event).

#### 20. Event with passthrough properties
- **Description:** Include extra fields in events.
- **Params:**
  ```json
  {
    "action": "extended",
    "deadzone": 0.5,
    "events": [
      { "type": "key", "keycode": "KEY_Z", "modifiers": ["ctrl"], "strength": 1.0 }
    ]
  }
  ```
- **Expected result:** `success`, extra fields passed through.

#### 21. Events array not an array
- **Description:** Pass an object for events.
- **Params:**
  ```json
  {
    "action": "bad",
    "events": { "type": "key", "keycode": "KEY_A" }
  }
  ```
- **Expected result:** Validation error (expected array).

---

## Cross-Tool Integration Scenarios

### 1. set_input_action → get_input_actions → simulate_action
- **Description:** Full lifecycle: define an action, verify it exists, simulate it.
- **Steps:**
  1. `set_input_action` with `{ "action": "test_attack", "events": [{ "type": "key", "keycode": "KEY_X" }] }` → `success`
  2. `get_input_actions` with `{}` → returned list includes `"test_attack"`
  3. `simulate_action` with `{ "action": "test_attack" }` → `success`
- **Expected result:** All pass.

### 2. simulate_sequence combining key + mouse + action
- **Description:** Use simulate_sequence to do a complex input combo.
- **Params:**
  ```json
  {
    "events": [
      { "type": "mouse_move", "position": [640, 360] },
      { "type": "mouse_click", "position": [640, 360], "delay": 100 },
      { "type": "key", "keycode": "KEY_W", "delay": 200 },
      { "type": "action", "action": "ui_accept", "delay": 300 },
      { "type": "key", "keycode": "KEY_W", "pressed": false, "delay": 500 }
    ]
  }
  ```
- **Expected result:** `success`, all events dispatched in order.

---

## Summary

| Tool | Required Params | Optional Params | Scenarios |
|------|----------------|-----------------|-----------|
| `simulate_key` | `keycode` | `pressed`, `echo` | 11 |
| `simulate_mouse_click` | `position` | `button`, `pressed` | 15 |
| `simulate_mouse_move` | `position` | `relative` | 12 |
| `simulate_action` | `action` | `pressed` | 9 |
| `simulate_sequence` | `events` | — (+passthrough) | 16 |
| `get_input_actions` | *none* | *none* | 3 |
| `set_input_action` | `action`, `events` | `deadzone` | 21 |

**Total test scenarios:** 87 + 2 cross-tool integration = **89 scenarios**
