# Input Tools Test Plan

**Source file:** `server/src/tools/input.ts`
**Version:** Based on commit HEAD
**Total tools:** 7

---

## Tool Index

| # | Tool Name | Godot Bridge Endpoint | Parameters |
|---|-----------|----------------------|------------|
| 1 | `simulate_key` | `input/simulate_key` | `keycode` (string, required), `pressed` (boolean, optional, default=true), `echo` (boolean, optional) |
| 2 | `simulate_mouse_click` | `input/simulate_mouse_click` | `position` ([number,number], required), `button` (enum: `left`\|`right`\|`middle`, optional, default=`left`), `pressed` (boolean, optional, default=true) |
| 3 | `simulate_mouse_move` | `input/simulate_mouse_move` | `position` ([number,number], required), `relative` (boolean, optional) |
| 4 | `simulate_action` | `input/simulate_action` | `action` (string, required), `pressed` (boolean, optional, default=true) |
| 5 | `simulate_sequence` | `input/simulate_sequence` | `events` (Array<{type: string, delay?: number, ...passthrough}>, required) |
| 6 | `get_input_actions` | `input/get_actions` | None |
| 7 | `set_input_action` | `input/set_action` | `action` (string, required), `deadzone` (number, 0–1, optional, default=0.5), `events` (Array<{type: string, ...passthrough}>, required) |

---

## 1. `simulate_key`

### Description
Simulate a keyboard key press/release in the running game.

### Parameters

| Param | Type | Required | Default | Constraints | Description |
|-------|------|----------|---------|-------------|-------------|
| `keycode` | string | **Yes** | — | Any non-empty string; typically `KEY_*` constants | Key code name (e.g. `'KEY_ENTER'`, `'KEY_SPACE'`, `'KEY_A'`) |
| `pressed` | boolean | No | `true` | — | Whether pressed (default: true) |
| `echo` | boolean | No | — (undefined) | — | Whether this is an echo/repeat event |

### Behavior
- Sends `{keycode, pressed, echo}` to `input/simulate_key` via WebSocket.
- Requires the game to be running (runtime autoload handles the input injection).
- Returns success/failure response from Godot.

### Test Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| 1.1 | **Happy path – press key** | `{keycode: "KEY_SPACE"}` | Key press simulated. Success response. `pressed` defaults to `true`, `echo` is undefined. |
| 1.2 | **Happy path – release key** | `{keycode: "KEY_SPACE", pressed: false}` | Key release simulated. Success response. |
| 1.3 | **Happy path – with echo** | `{keycode: "KEY_A", echo: true}` | Key echo/repeat simulated. Success response. |
| 1.4 | **Happy path – press and no echo** | `{keycode: "KEY_A", echo: false}` | Key press without echo. Success response. |
| 1.5 | **Press key with explicit pressed=true** | `{keycode: "KEY_ENTER", pressed: true}` | Same as default (1.1). Success. |
| 1.6 | **Common keycodes – letters** | `{keycode: "KEY_A"}`, `{keycode: "KEY_Z"}`, `{keycode: "KEY_M"}` | Each letter key press simulated successfully. |
| 1.7 | **Common keycodes – digits** | `{keycode: "KEY_0"}`, `{keycode: "KEY_5"}`, `{keycode: "KEY_9"}` | Each digit key press simulated successfully. |
| 1.8 | **Common keycodes – navigation** | `{keycode: "KEY_UP"}`, `{keycode: "KEY_DOWN"}`, `{keycode: "KEY_LEFT"}`, `{keycode: "KEY_RIGHT"}` | Arrow key presses simulated. |
| 1.9 | **Common keycodes – modifiers** | `{keycode: "KEY_SHIFT"}`, `{keycode: "KEY_CTRL"}`, `{keycode: "KEY_ALT"}` | Modifier key presses simulated. |
| 1.10 | **Common keycodes – special** | `{keycode: "KEY_ESCAPE"}`, `{keycode: "KEY_TAB"}`, `{keycode: "KEY_BACKSPACE"}`, `{keycode: "KEY_DELETE"}` | Special key presses simulated. |
| 1.11 | **Common keycodes – function keys** | `{keycode: "KEY_F1"}`, `{keycode: "KEY_F5"}`, `{keycode: "KEY_F12"}` | Function key presses simulated. |
| 1.12 | **Common keycodes – UI accept** | `{keycode: "KEY_ENTER"}` then `{keycode: "KEY_ENTER", pressed: false}` | Press-and-release cycle of Enter key. |
| 1.13 | **Edge: empty string keycode** | `{keycode: ""}` | Zod validation passes (string). Godot may return an error for unknown keycode. Test both. |
| 1.14 | **Edge: missing `keycode`** | `{pressed: false}` | Zod validation error — `keycode` is required. |
| 1.15 | **Edge: `keycode` as number** | `{keycode: 32}` | Zod validation error — expected string, got number. |
| 1.16 | **Edge: `keycode` as boolean** | `{keycode: true}` | Zod validation error — expected string. |
| 1.17 | **Edge: `keycode` as null** | `{keycode: null}` | Zod validation error — expected string. |
| 1.18 | **Edge: `keycode` as array** | `{keycode: ["KEY_SPACE"]}` | Zod validation error — expected string. |
| 1.19 | **Edge: `keycode` as object** | `{keycode: {name: "KEY_SPACE"}}` | Zod validation error — expected string. |
| 1.20 | **Edge: `pressed` as string** | `{keycode: "KEY_SPACE", pressed: "true"}` | Zod validation error — expected boolean. |
| 1.21 | **Edge: `pressed` as number** | `{keycode: "KEY_SPACE", pressed: 1}` | Zod validation error — expected boolean. |
| 1.22 | **Edge: `pressed` as null** | `{keycode: "KEY_SPACE", pressed: null}` | Zod validation error — expected boolean. |
| 1.23 | **Edge: `echo` as string** | `{keycode: "KEY_A", echo: "yes"}` | Zod validation error — expected boolean. |
| 1.24 | **Edge: `echo` as number** | `{keycode: "KEY_A", echo: 0}` | Zod validation error — expected boolean. |
| 1.25 | **Edge: `echo` as null** | `{keycode: "KEY_A", echo: null}` | Zod validation error — expected boolean. |
| 1.26 | **Edge: extra unknown properties** | `{keycode: "KEY_SPACE", duration: 500}` | Zod strips/ignores `duration`. `keycode` delivered correctly. |
| 1.27 | **Edge: very long keycode string** | `{keycode: "KEY_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA..."}` (very long string) | Zod passes (string). Godot likely rejects unknown keycode. |
| 1.28 | **Edge: invalid keycode format** | `{keycode: "NOT_A_VALID_KEYCODE"}` | Zod passes (string). Godot returns error for unknown keycode. |
| 1.29 | **Edge: call when game is NOT running** | `{keycode: "KEY_SPACE"}` with game stopped | Error returned by Godot: game must be running for input simulation. |
| 1.30 | **Edge: call when Godot disconnected** | `{keycode: "KEY_SPACE"}` with no Godot connection | Error: connection/timeout, not a crash. |
| 1.31 | **Press-release-press cycle** | Press KEY_A, release KEY_A, press KEY_A | All three succeed. Verify game observes the transitions. |
| 1.32 | **Rapid press/release** | Call press+release 10 times in quick succession for the same keycode | All 10 pairs succeed. No dropped events. |

---

## 2. `simulate_mouse_click`

### Description
Simulate a mouse click at a screen position.

### Parameters

| Param | Type | Required | Default | Constraints | Description |
|-------|------|----------|---------|-------------|-------------|
| `position` | [number, number] | **Yes** | — | Tuple of exactly 2 numbers (`z.tuple([z.number(), z.number()])`) | Screen position [x, y] |
| `button` | enum | No | `"left"` | `"left"` \| `"right"` \| `"middle"` | Mouse button (default: left) |
| `pressed` | boolean | No | `true` | — | Whether pressed (default: true) |

### Behavior
- Sends `{position, button, pressed}` to `input/simulate_mouse_click` via WebSocket.
- Requires the game to be running.
- The `position` tuple is a precise Zod tuple — exactly 2 numbers, both required.

### Test Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| 2.1 | **Happy path – left click** | `{position: [320, 240]}` | Left button press at (320, 240). Success. `button` defaults to `"left"`, `pressed` defaults to `true`. |
| 2.2 | **Happy path – left click release** | `{position: [320, 240], button: "left", pressed: false}` | Left button release at (320, 240). Success. |
| 2.3 | **Happy path – right click** | `{position: [100, 500], button: "right"}` | Right button press at (100, 500). Success. |
| 2.4 | **Happy path – middle click** | `{position: [640, 360], button: "middle"}` | Middle button press at (640, 360). Success. |
| 2.5 | **Happy path – explicit defaults** | `{position: [0, 0], button: "left", pressed: true}` | Same as default behavior. Success. |
| 2.6 | **Enum: button = "left"** | `{position: [10, 10], button: "left"}` | Left button click. Success. |
| 2.7 | **Enum: button = "right"** | `{position: [10, 10], button: "right"}` | Right button click. Success. |
| 2.8 | **Enum: button = "middle"** | `{position: [10, 10], button: "middle"}` | Middle button click. Success. |
| 2.9 | **Origin position (0,0)** | `{position: [0, 0]}` | Click at screen origin. Success. |
| 2.10 | **Large position values** | `{position: [9999, 9999]}` | Click at far-off-screen position. Godot may or may not deliver the event (test behavior). |
| 2.11 | **Negative position values** | `{position: [-100, -100]}` | Click at negative screen coordinates. Godot may handle or ignore. |
| 2.12 | **Float position values** | `{position: [320.5, 240.75]}` | Click at sub-pixel position. Success (Zod allows floats). |
| 2.13 | **Zero-width viewport corner** | `{position: [0, 600]}` (bottom-left of 800×600) | Click at edge. Success. |
| 2.14 | **Full viewport diagonal** | `{position: [800, 600]}` (bottom-right of 800×600) | Click at far corner. Success. |
| 2.15 | **Press-and-release cycle** | Press at (100,100), release at (100,100) | Press+release pair succeeds. |
| 2.16 | **All three buttons cycle** | Left click, right click, middle click at same position | All three succeed. |
| 2.17 | **Edge: position with 1 element** | `{position: [320]}` | Zod validation error — tuple expects exactly 2 numbers. |
| 2.18 | **Edge: position with 3 elements** | `{position: [320, 240, 0]}` | Zod validation error — tuple expects exactly 2 numbers. |
| 2.19 | **Edge: position as empty array** | `{position: []}` | Zod validation error — tuple expects exactly 2 numbers. |
| 2.20 | **Edge: missing `position`** | `{button: "right"}` | Zod validation error — `position` is required. |
| 2.21 | **Edge: position as object** | `{position: {x: 320, y: 240}}` | Zod validation error — expected tuple, got object. |
| 2.22 | **Edge: position as string** | `{position: "320,240"}` | Zod validation error — expected tuple. |
| 2.23 | **Edge: position as null** | `{position: null}` | Zod validation error — expected tuple. |
| 2.24 | **Edge: position elements as strings** | `{position: ["320", "240"]}` | Zod validation error — expected numbers. |
| 2.25 | **Edge: position elements as booleans** | `{position: [true, false]}` | Zod validation error — expected numbers. |
| 2.26 | **Edge: position with NaN** | `{position: [NaN, 240]}` | Zod validation error or coercion failure. |
| 2.27 | **Edge: position with Infinity** | `{position: [Infinity, 240]}` | Zod allows Infinity as a number. Godot behavior TBD. |
| 2.28 | **Edge: `button` as empty string** | `{position: [0, 0], button: ""}` | Zod validation error — not in enum. |
| 2.29 | **Edge: `button` as invalid string** | `{position: [0, 0], button: "side"}` | Zod validation error — not in enum. |
| 2.30 | **Edge: `button` as wrong case** | `{position: [0, 0], button: "Left"}` | Zod validation error — enum is case-sensitive. |
| 2.31 | **Edge: `button` as number** | `{position: [0, 0], button: 1}` | Zod validation error — expected string. |
| 2.32 | **Edge: `button` as boolean** | `{position: [0, 0], button: true}` | Zod validation error — expected string. |
| 2.33 | **Edge: `button` as null** | `{position: [0, 0], button: null}` | Zod validation error — expected string. |
| 2.34 | **Edge: `pressed` as string** | `{position: [0, 0], pressed: "true"}` | Zod validation error — expected boolean. |
| 2.35 | **Edge: `pressed` as number** | `{position: [0, 0], pressed: 1}` | Zod validation error — expected boolean. |
| 2.36 | **Edge: `pressed` as null** | `{position: [0, 0], pressed: null}` | Zod validation error — expected boolean. |
| 2.37 | **Edge: extra unknown properties** | `{position: [0, 0], clicks: 2}` | Zod strips/ignores `clicks`. Known params delivered correctly. |
| 2.38 | **Edge: game NOT running** | `{position: [100, 100]}` with game stopped | Error: game must be running. |
| 2.39 | **Edge: Godot disconnected** | `{position: [100, 100]}` with no Godot connection | Error: connection/timeout. |

---

## 3. `simulate_mouse_move`

### Description
Simulate mouse movement to a screen position.

### Parameters

| Param | Type | Required | Default | Constraints | Description |
|-------|------|----------|---------|-------------|-------------|
| `position` | [number, number] | **Yes** | — | Tuple of exactly 2 numbers (`z.tuple([z.number(), z.number()])`) | Target screen position [x, y] |
| `relative` | boolean | No | — (undefined) | — | If true, position is relative to current mouse position |

### Behavior
- Sends `{position, relative}` to `input/simulate_mouse_move` via WebSocket.
- Requires the game to be running.
- When `relative` is true/undefined, behavior differs: `relative=true` moves relative to current; `relative=false` (or undefined) moves to absolute screen position.

### Test Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| 3.1 | **Happy path – absolute move** | `{position: [400, 300]}` | Mouse moved to absolute screen position (400, 300). Success. `relative` undefined (absolute). |
| 3.2 | **Happy path – absolute move to origin** | `{position: [0, 0]}` | Mouse moved to (0, 0). Success. |
| 3.3 | **Happy path – relative move** | `{position: [10, -20], relative: true}` | Mouse moved +10 pixels right, -20 pixels up from current position. Success. |
| 3.4 | **Happy path – explicit absolute** | `{position: [500, 200], relative: false}` | Mouse moved to absolute (500, 200). Success. |
| 3.5 | **Relative move zero** | `{position: [0, 0], relative: true}` | Mouse stays at current position (zero relative delta). Success. |
| 3.6 | **Relative move negative** | `{position: [-50, -50], relative: true}` | Mouse moved left and up. Success. |
| 3.7 | **Relative move large** | `{position: [9999, 9999], relative: true}` | Mouse moved by large relative amount. Godot may clamp to screen. |
| 3.8 | **Horizontal only (relative)** | `{position: [200, 0], relative: true}` | Mouse moved right only, Y unchanged. Success. |
| 3.9 | **Vertical only (relative)** | `{position: [0, -100], relative: true}` | Mouse moved up only, X unchanged. Success. |
| 3.10 | **Absolute to every corner** | `[0,0]`, `[800,0]`, `[800,600]`, `[0,600]` | All four corner moves succeed. |
| 3.11 | **Sequential absolute moves** | Move to (100,100), then (200,200), then (300,300) | Each step succeeds. Final position should be (300,300). |
| 3.12 | **Sequential relative moves** | Start at (100,100). Move relative (+10,+10), then (+10,+10) | After two moves, position should be near (120,120). |
| 3.13 | **Edge: position with 1 element** | `{position: [320]}` | Zod validation error — tuple expects exactly 2 numbers. |
| 3.14 | **Edge: position with 3 elements** | `{position: [320, 240, 0]}` | Zod validation error — tuple expects exactly 2 numbers. |
| 3.15 | **Edge: position as empty array** | `{position: []}` | Zod validation error — tuple expects exactly 2 numbers. |
| 3.16 | **Edge: missing `position`** | `{relative: true}` | Zod validation error — `position` is required. |
| 3.17 | **Edge: position as string** | `{position: "400,300"}` | Zod validation error — expected tuple. |
| 3.18 | **Edge: position as object** | `{position: {x: 400, y: 300}}` | Zod validation error — expected tuple. |
| 3.19 | **Edge: position as null** | `{position: null}` | Zod validation error — expected tuple. |
| 3.20 | **Edge: position elements as strings** | `{position: ["400", "300"]}` | Zod validation error — expected numbers. |
| 3.21 | **Edge: position elements as booleans** | `{position: [true, false]}` | Zod validation error — expected numbers. |
| 3.22 | **Edge: position with NaN** | `{position: [NaN, 300]}` | Zod validation error or coercion failure. |
| 3.23 | **Edge: position with Infinity** | `{position: [Infinity, 300]}` | Zod allows Infinity. Godot behavior TBD. |
| 3.24 | **Edge: `relative` as string** | `{position: [0, 0], relative: "true"}` | Zod validation error — expected boolean. |
| 3.25 | **Edge: `relative` as number** | `{position: [0, 0], relative: 1}` | Zod validation error — expected boolean. |
| 3.26 | **Edge: `relative` as null** | `{position: [0, 0], relative: null}` | Zod validation error — expected boolean. |
| 3.27 | **Edge: negative absolute position** | `{position: [-100, -100]}` | Zod allows. Godot may clamp or deliver out-of-bounds event. |
| 3.28 | **Edge: extra unknown properties** | `{position: [0, 0], speed: "fast"}` | Zod strips/ignores `speed`. `position` delivered. |
| 3.29 | **Edge: game NOT running** | `{position: [400, 300]}` with game stopped | Error: game must be running. |
| 3.30 | **Edge: Godot disconnected** | `{position: [400, 300]}` with no Godot connection | Error: connection/timeout. |
| 3.31 | **Float precision movement** | `{position: [100.25, 200.75], relative: true}` | Sub-pixel relative movement. Success. |

---

## 4. `simulate_action`

### Description
Simulate an input action (from InputMap) being pressed/released.

### Parameters

| Param | Type | Required | Default | Constraints | Description |
|-------|------|----------|---------|-------------|-------------|
| `action` | string | **Yes** | — | Any non-empty string | Input action name (e.g. `'ui_accept'`, `'move_left'`) |
| `pressed` | boolean | No | `true` | — | Whether pressed (default: true) |

### Behavior
- Sends `{action, pressed}` to `input/simulate_action` via WebSocket.
- Requires the game to be running.
- The action must exist in the project's InputMap for Godot to process it meaningfully, though Zod does not validate this.

### Test Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| 4.1 | **Happy path – press built-in action** | `{action: "ui_accept"}` | `ui_accept` pressed. Success. `pressed` defaults to `true`. |
| 4.2 | **Happy path – release built-in action** | `{action: "ui_accept", pressed: false}` | `ui_accept` released. Success. |
| 4.3 | **Happy path – explicit press** | `{action: "ui_cancel", pressed: true}` | `ui_cancel` pressed. Success. |
| 4.4 | **Built-in actions – navigation** | `{action: "ui_up"}`, `{action: "ui_down"}`, `{action: "ui_left"}`, `{action: "ui_right"}` | Each navigation action press succeeds. |
| 4.5 | **Built-in actions – ui focus** | `{action: "ui_focus_next"}`, `{action: "ui_focus_prev"}` | Focus actions succeed. |
| 4.6 | **Built-in actions – ui page** | `{action: "ui_page_up"}`, `{action: "ui_page_down"}` | Page actions succeed. |
| 4.7 | **Built-in actions – ui select** | `{action: "ui_select"}`, `{action: "ui_text_add_selection_for_next_occurrence"}` | Each succeeds. |
| 4.8 | **Custom action name** | `{action: "jump"}` (if defined in InputMap) | Custom action press simulated. Success if action exists; may error if not. |
| 4.9 | **Custom action – "move_left"** | `{action: "move_left"}` (if defined) | Custom action press succeeds. |
| 4.10 | **Action press-and-release cycle** | `{action: "ui_accept"}` then `{action: "ui_accept", pressed: false}` | Full press+release cycle succeeds. |
| 4.11 | **Non-existent action** | `{action: "nonexistent_action_xyz"}` | Zod passes (string). Godot may return error or silently ignore. Test Godot behavior. |
| 4.12 | **Edge: empty string action** | `{action: ""}` | Zod passes (string). Godot may reject. Test both. |
| 4.13 | **Edge: missing `action`** | `{pressed: false}` | Zod validation error — `action` is required. |
| 4.14 | **Edge: `action` as number** | `{action: 123}` | Zod validation error — expected string. |
| 4.15 | **Edge: `action` as boolean** | `{action: true}` | Zod validation error — expected string. |
| 4.16 | **Edge: `action` as null** | `{action: null}` | Zod validation error — expected string. |
| 4.17 | **Edge: `action` as array** | `{action: ["ui_accept"]}` | Zod validation error — expected string. |
| 4.18 | **Edge: `action` as object** | `{action: {name: "ui_accept"}}` | Zod validation error — expected string. |
| 4.19 | **Edge: `pressed` as string** | `{action: "ui_accept", pressed: "true"}` | Zod validation error — expected boolean. |
| 4.20 | **Edge: `pressed` as number** | `{action: "ui_accept", pressed: 1}` | Zod validation error — expected boolean. |
| 4.21 | **Edge: `pressed` as null** | `{action: "ui_accept", pressed: null}` | Zod validation error — expected boolean. |
| 4.22 | **Edge: extra unknown properties** | `{action: "ui_accept", strength: 0.5}` | Zod strips/ignores `strength`. `action` delivered. |
| 4.23 | **Edge: very long action name** | `{action: "A" * 1000}` (very long string) | Zod passes. Godot may reject or accept. Test. |
| 4.24 | **Edge: action with special characters** | `{action: "move_right!"}` | Zod passes. Godot may accept or reject. |
| 4.25 | **Edge: action with unicode** | `{action: "動く"}` | Zod passes (string). Godot may accept or reject. |
| 4.26 | **Edge: game NOT running** | `{action: "ui_accept"}` with game stopped | Error: game must be running. |
| 4.27 | **Edge: Godot disconnected** | `{action: "ui_accept"}` with no Godot connection | Error: connection/timeout. |
| 4.28 | **Rapid action spam** | Call `{action: "ui_accept"}` 20 times rapidly | All 20 succeed. Game processes each event. |
| 4.29 | **Multiple actions simultaneously** | Press `ui_up` + `ui_accept` in sequence without release | Both actions registered as "pressed". Success. |
| 4.30 | **Press and hold simulation** | Press action, wait, press again (without release) | Multiple press events on same action without intervening release. Godot behavior TBD. |

---

## 5. `simulate_sequence`

### Description
Simulate a sequence of input events with timing.

### Parameters

| Param | Type | Required | Default | Constraints | Description |
|-------|------|----------|---------|-------------|-------------|
| `events` | Array\<object\> | **Yes** | — | Each event must have `type: string`; optional `delay: number`; passthrough allowed | Sequence of input events to simulate |

Each event object:
- `type` (string, required) — Event type: `'key'`, `'mouse_click'`, `'mouse_move'`, `'action'`
- `delay` (number, optional) — Delay before this event in milliseconds
- Additional properties are passed through via `.passthrough()`

### Behavior
- Sends `{events}` to `input/simulate_sequence` via WebSocket.
- Requires the game to be running.
- Godot processes events sequentially with the specified delays.
- Passthrough allows event-specific keys like `keycode`, `position`, `button`, `action`, `pressed`, etc.

### Test Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| 5.1 | **Happy path – single key event** | `{events: [{type: "key", keycode: "KEY_SPACE"}]}` | Key press simulated. Success. |
| 5.2 | **Happy path – key press + release** | `{events: [{type: "key", keycode: "KEY_SPACE"}, {type: "key", keycode: "KEY_SPACE", pressed: false}]}` | Press then release. Success. |
| 5.3 | **Happy path – event type "key"** | `{events: [{type: "key", keycode: "KEY_ENTER", pressed: true, echo: false}]}` | Key event with all passthrough params. Success. |
| 5.4 | **Happy path – event type "mouse_click"** | `{events: [{type: "mouse_click", position: [100, 200], button: "left"}]}` | Mouse click event. Success. |
| 5.5 | **Happy path – event type "mouse_move"** | `{events: [{type: "mouse_move", position: [400, 300]}]}` | Mouse move event. Success. |
| 5.6 | **Happy path – event type "action"** | `{events: [{type: "action", action: "ui_accept", pressed: true}]}` | Action event. Success. |
| 5.7 | **Happy path – with delays** | `{events: [{type: "key", keycode: "KEY_A", delay: 100}, {type: "key", keycode: "KEY_A", pressed: false, delay: 500}]}` | Key pressed, 100ms delay, then released, 500ms delay. Success. |
| 5.8 | **Multiple event types in sequence** | `{events: [{type: "key", keycode: "KEY_RIGHT"}, {type: "mouse_move", position: [500, 300]}, {type: "mouse_click", position: [500, 300]}]}` | Key → move mouse → click. All succeed. |
| 5.9 | **Sequence with all four event types** | `{events: [{type: "key", keycode: "KEY_ENTER"}, {type: "mouse_move", position: [200, 200]}, {type: "mouse_click", position: [200, 200]}, {type: "action", action: "ui_accept"}]}` | All four types execute. Success. |
| 5.10 | **Long sequence (50 events)** | 50 events of various types with delays | All 50 succeed. No timeout or error. |
| 5.11 | **Zero delay** | `{events: [{type: "key", keycode: "KEY_A", delay: 0}, {type: "key", keycode: "KEY_B", delay: 0}]}` | Both events with zero delay. Processed sequentially (Godot single-threaded). |
| 5.12 | **No delay (omit delay field)** | `{events: [{type: "key", keycode: "KEY_A"}, {type: "key", keycode: "KEY_B"}]}` | Events fire back-to-back with no delay. Success. |
| 5.13 | **Negative delay** | `{events: [{type: "key", keycode: "KEY_A", delay: -100}]}` | Zod passes (number). Godot may reject negative delay. Test. |
| 5.14 | **Float delay values** | `{events: [{type: "key", keycode: "KEY_A", delay: 33.33}]}` | Fractional millisecond delay. Zod passes. Godot may round or reject. |
| 5.15 | **Very large delay** | `{events: [{type: "key", keycode: "KEY_A", delay: 99999999}]}` | Very long delay. Should not crash, but may cause timeout if Godot waits before responding. |
| 5.16 | **Action press+release sequence** | `{events: [{type: "action", action: "move_left", pressed: true, delay: 200}, {type: "action", action: "move_left", pressed: false}]}` | Action pressed for 200ms then released. Success. |
| 5.17 | **Complex game input sequence** | `{events: [{type: "action", action: "jump"}, {type: "action", action: "move_right", delay: 50}, {type: "action", action: "move_right", pressed: false, delay: 500}]}` | Jump + move right briefly then stop. Simulates a short rightward jump. |
| 5.18 | **Relative mouse move sequence** | `{events: [{type: "mouse_move", position: [0, 0]}, {type: "mouse_move", position: [100, 0], relative: true, delay: 100}, {type: "mouse_move", position: [0, 100], relative: true, delay: 100}]}` | Move to origin, then relative moves. Success. |
| 5.19 | **Edge: empty events array** | `{events: []}` | Zod passes (empty array). Godot may accept or reject. Test. |
| 5.20 | **Edge: missing `events`** | `{}` | Zod validation error — `events` is required. |
| 5.21 | **Edge: `events` as string** | `{events: "not an array"}` | Zod validation error — expected array. |
| 5.22 | **Edge: `events` as object** | `{events: {type: "key"}}` | Zod validation error — expected array. |
| 5.23 | **Edge: `events` as null** | `{events: null}` | Zod validation error — expected array. |
| 5.24 | **Edge: `events` as number** | `{events: 123}` | Zod validation error — expected array. |
| 5.25 | **Edge: event missing `type`** | `{events: [{keycode: "KEY_A"}]}` | Zod validation error — `type` is required in each event object. |
| 5.26 | **Edge: event `type` as empty string** | `{events: [{type: ""}]}` | Zod passes (string). Godot may reject unknown type. |
| 5.27 | **Edge: event `type` as number** | `{events: [{type: 1}]}` | Zod validation error — expected string. |
| 5.28 | **Edge: event `type` as boolean** | `{events: [{type: true}]}` | Zod validation error — expected string. |
| 5.29 | **Edge: event `type` as null** | `{events: [{type: null}]}` | Zod validation error — expected string. |
| 5.30 | **Edge: event `type` with invalid event type** | `{events: [{type: "invalid_event_type"}]}` | Zod passes. Godot may reject unknown event type. |
| 5.31 | **Edge: event `delay` as string** | `{events: [{type: "key", keycode: "KEY_A", delay: "100"}]}` | Zod validation error — expected number. |
| 5.32 | **Edge: event `delay` as boolean** | `{events: [{type: "key", keycode: "KEY_A", delay: true}]}` | Zod validation error — expected number. |
| 5.33 | **Edge: event `delay` as null** | `{events: [{type: "key", keycode: "KEY_A", delay: null}]}` | Zod validation error — expected number. |
| 5.34 | **Edge: extra keys in event (passthrough)** | `{events: [{type: "key", keycode: "KEY_A", custom_field: "hello", meta: {a: 1}}]}` | Extra fields passed through via `.passthrough()`. Godot behavior depends on the event handler. |
| 5.35 | **Edge: game NOT running** | `{events: [{type: "key", keycode: "KEY_SPACE"}]}` with game stopped | Error: game must be running. |
| 5.36 | **Edge: Godot disconnected** | `{events: [{type: "key", keycode: "KEY_SPACE"}]}` with no Godot connection | Error: connection/timeout. |
| 5.37 | **Single large event array (500 events)** | Array with 500 simple key events | All 500 succeed. No timeout or truncation issues. |
| 5.38 | **Sequence with mixed valid/invalid events** | `{events: [{type: "key", keycode: "KEY_A"}, {type: "bad_type"}, {type: "action", action: "jump"}]}` | Zod rejects at the mismatched event (index 1). Depends on runtime validation behavior. |

---

## 6. `get_input_actions`

### Description
Get all input actions defined in the InputMap.

### Parameters
None.

### Behavior
- Makes a call to `input/get_actions` via WebSocket.
- Does NOT require the game to be running (it reads from InputMap / project settings).
- Returns a list/object of all input actions and their mapped events.

### Test Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| 6.1 | **Happy path – fresh project** | `{}` (empty) | Returns all built-in input actions (`ui_accept`, `ui_cancel`, `ui_up`, `ui_down`, `ui_left`, `ui_right`, `ui_select`, `ui_focus_next`, `ui_focus_prev`, `ui_page_up`, `ui_page_down`, etc.) with their event mappings. |
| 6.2 | **After adding custom action** | Add `"jump"` action via `set_input_action`, then call | Custom action appears in the result alongside built-in actions. |
| 6.3 | **Call twice – verify idempotency** | Call twice in succession | Both calls return identical data. No side effects from read. |
| 6.4 | **Call after removing an action** | Remove a custom action, then call | Removed action no longer appears. |
| 6.5 | **Verify action structure** | Call and inspect result | Each action should have a name and list of mapped events. Each event should have a `type` and type-specific properties. |
| 6.6 | **Verify built-in action details** | Call and inspect `ui_accept` | Should show its default mappings (e.g., Enter key, Space key, gamepad button). |
| 6.7 | **Call when no custom actions exist** | Fresh project with only built-in actions | Only built-in actions returned. |
| 6.8 | **Call after multiple `set_input_action` calls** | Set 5 custom actions, then call | All 5 custom + built-in actions returned with correct event mappings. |
| 6.9 | **Call when Godot disconnected** | Call with no Godot connection | Error: connection/timeout, not a crash. |
| 6.10 | **Call when game is running** | Start game, then call | Should still work — InputMap is accessible regardless of play state. |
| 6.11 | **Call with extra params (ignored)** | `{unused: "param"}` | Zod strips/ignores extra properties. Returns correctly. |

---

## 7. `set_input_action`

### Description
Add or modify an input action and its event mappings.

### Parameters

| Param | Type | Required | Default | Constraints | Description |
|-------|------|----------|---------|-------------|-------------|
| `action` | string | **Yes** | — | Any non-empty string | Action name |
| `deadzone` | number | No | `0.5` | `min(0)`, `max(1)` | Input deadzone value (0-1, default: 0.5) |
| `events` | Array\<object\> | **Yes** | — | Each event must have `type: string`; passthrough allowed | List of input events to map to this action |

Each event object:
- `type` (string, required) — Event type: `'key'`, `'mouse_button'`, `'joypad_button'`, etc.
- Additional properties are passed through via `.passthrough()`

### Behavior
- Sends `{action, deadzone, events}` to `input/set_action` via WebSocket.
- Modifies the InputMap in project settings.
- Creates the action if it does not exist; modifies it if it does.
- Does NOT require the game to be running.

### Test Scenarios

| ID | Scenario | Input | Expected Result |
|----|----------|-------|-----------------|
| 7.1 | **Happy path – create new action with key** | `{action: "jump", events: [{type: "key", keycode: "KEY_SPACE"}]}` | Action `"jump"` created with deadzone 0.5 (default) and KEY_SPACE mapping. Success. |
| 7.2 | **Happy path – create action with explicit deadzone** | `{action: "jump", deadzone: 0.2, events: [{type: "key", keycode: "KEY_SPACE"}]}` | Action created with deadzone 0.2. Success. |
| 7.3 | **Happy path – create action with mouse button** | `{action: "shoot", events: [{type: "mouse_button", button: "left"}]}` | Action `"shoot"` created with left mouse button. Success. |
| 7.4 | **Happy path – create action with joypad button** | `{action: "pause", events: [{type: "joypad_button", button: 7}]}` | Action `"pause"` created with joypad button 7 (Start). Success. |
| 7.5 | **Happy path – multiple event mappings** | `{action: "jump", events: [{type: "key", keycode: "KEY_SPACE"}, {type: "joypad_button", button: 0}]}` | Action `"jump"` mapped to both Space and joypad button 0. Success. |
| 7.6 | **Modify existing built-in action** | `{action: "ui_accept", events: [{type: "key", keycode: "KEY_ENTER"}]}` | Built-in `ui_accept` now mapped only to Enter (original Space mapping removed). Success. |
| 7.7 | **Modify custom action – change events** | Create `"jump"` with Space, then call again with `{action: "jump", events: [{type: "key", keycode: "KEY_W"}]}` | Action updated; now only mapped to W. |
| 7.8 | **Modify custom action – change deadzone** | Create `"jump"` with deadzone 0.5, then call with `{action: "jump", deadzone: 0.8, events: [{type: "key", keycode: "KEY_SPACE"}]}` | Deadzone updated to 0.8. Events preserved/changed. |
| 7.9 | **Set action with no events** | `{action: "empty_action", events: []}` | Action created with no mappings. Godot may accept or reject. Test. |
| 7.10 | **Deadzone enum value: 0 (min)** | `{action: "test", deadzone: 0, events: [{type: "key", keycode: "KEY_A"}]}` | Deadzone set to 0 (no deadzone). Success. |
| 7.11 | **Deadzone enum value: 0.5 (default)** | `{action: "test", deadzone: 0.5, events: [{type: "key", keycode: "KEY_A"}]}` | Deadzone 0.5. Same as default. Success. |
| 7.12 | **Deadzone enum value: 1 (max)** | `{action: "test", deadzone: 1, events: [{type: "key", keycode: "KEY_A"}]}` | Deadzone set to 1 (maximum). Success. |
| 7.13 | **Deadzone fractional value** | `{action: "test", deadzone: 0.333, events: [{type: "key", keycode: "KEY_A"}]}` | Deadzone set to 0.333. Success. |
| 7.14 | **Event type: "key"** | `{action: "test", events: [{type: "key", keycode: "KEY_Q"}]}` | Key event mapping. Success. |
| 7.15 | **Event type: "mouse_button"** | `{action: "test", events: [{type: "mouse_button", button: "right"}]}` | Mouse button event mapping. Success. |
| 7.16 | **Event type: "joypad_button"** | `{action: "test", events: [{type: "joypad_button", button: 0}]}` | Joypad button event mapping. Success. |
| 7.17 | **Event with passthrough properties** | `{action: "test", events: [{type: "key", keycode: "KEY_A", ctrl: true, shift: false}]}` | Extra properties passed through. Godot may use or ignore. |
| 7.18 | **Overwrite action events with different event types** | Create with key, then overwrite with `[{type: "mouse_button", button: "middle"}, {type: "joypad_button", button: 3}]` | Action now mapped to middle mouse and joypad 3. Key mapping removed. |
| 7.19 | **Edge: missing `action`** | `{events: [{type: "key", keycode: "KEY_SPACE"}]}` | Zod validation error — `action` is required. |
| 7.20 | **Edge: missing `events`** | `{action: "jump"}` | Zod validation error — `events` is required. |
| 7.21 | **Edge: missing both `action` and `events`** | `{}` | Zod validation error — both required. |
| 7.22 | **Edge: `action` as empty string** | `{action: "", events: [{type: "key", keycode: "KEY_A"}]}` | Zod passes (string). Godot may reject. Test. |
| 7.23 | **Edge: `action` as number** | `{action: 123, events: [{type: "key", keycode: "KEY_A"}]}` | Zod validation error — expected string. |
| 7.24 | **Edge: `action` as boolean** | `{action: true, events: [{type: "key", keycode: "KEY_A"}]}` | Zod validation error — expected string. |
| 7.25 | **Edge: `action` as null** | `{action: null, events: [{type: "key", keycode: "KEY_A"}]}` | Zod validation error — expected string. |
| 7.26 | **Edge: `deadzone` negative** | `{action: "jump", deadzone: -0.1, events: [{type: "key", keycode: "KEY_SPACE"}]}` | Zod validation error — `min(0)`. |
| 7.27 | **Edge: `deadzone` = 1.1** | `{action: "jump", deadzone: 1.1, events: [{type: "key", keycode: "KEY_SPACE"}]}` | Zod validation error — `max(1)`. |
| 7.28 | **Edge: `deadzone` = 5** | `{action: "jump", deadzone: 5, events: [{type: "key", keycode: "KEY_SPACE"}]}` | Zod validation error — `max(1)`. |
| 7.29 | **Edge: `deadzone` as string** | `{action: "jump", deadzone: "0.5", events: [{type: "key", keycode: "KEY_SPACE"}]}` | Zod validation error — expected number. |
| 7.30 | **Edge: `deadzone` as boolean** | `{action: "jump", deadzone: true, events: [{type: "key", keycode: "KEY_SPACE"}]}` | Zod validation error — expected number. |
| 7.31 | **Edge: `deadzone` as null** | `{action: "jump", deadzone: null, events: [{type: "key", keycode: "KEY_SPACE"}]}` | Zod validation error — expected number. |
| 7.32 | **Edge: `deadzone` as NaN** | `{action: "jump", deadzone: NaN, events: [{type: "key", keycode: "KEY_SPACE"}]}` | Zod validation error or coercion failure. |
| 7.33 | **Edge: `events` as string** | `{action: "jump", events: "not an array"}` | Zod validation error — expected array. |
| 7.34 | **Edge: `events` as object** | `{action: "jump", events: {type: "key"}}` | Zod validation error — expected array. |
| 7.35 | **Edge: `events` as null** | `{action: "jump", events: null}` | Zod validation error — expected array. |
| 7.36 | **Edge: `events` as number** | `{action: "jump", events: 1}` | Zod validation error — expected array. |
| 7.37 | **Edge: event missing `type`** | `{action: "jump", events: [{keycode: "KEY_SPACE"}]}` | Zod validation error — `type` is required in each event object. |
| 7.38 | **Edge: event `type` as empty string** | `{action: "jump", events: [{type: ""}]}` | Zod passes. Godot may reject. |
| 7.39 | **Edge: event `type` as number** | `{action: "jump", events: [{type: 1}]}` | Zod validation error — expected string. |
| 7.40 | **Edge: event `type` as boolean** | `{action: "jump", events: [{type: true}]}` | Zod validation error — expected string. |
| 7.41 | **Edge: event `type` as null** | `{action: "jump", events: [{type: null}]}` | Zod validation error — expected string. |
| 7.42 | **Edge: extra unknown properties at top level** | `{action: "jump", events: [{type: "key", keycode: "KEY_SPACE"}], extra: "ignored"}` | Zod strips/ignores `extra`. Known params delivered. |
| 7.43 | **Edge: extra unknown properties in event objects (passthrough)** | `{action: "jump", events: [{type: "key", keycode: "KEY_SPACE", device: 0, echo_allowed: false}]}` | Extra fields passed through via `.passthrough()`. |
| 7.44 | **Edge: very long action name** | `{action: "J" * 1000, events: [{type: "key", keycode: "KEY_A"}]}` | Zod passes. Godot may reject. Test. |
| 7.45 | **Edge: action name with special characters** | `{action: "jump!@#$%", events: [{type: "key", keycode: "KEY_SPACE"}]}` | Zod passes. Godot may accept or reject. |
| 7.46 | **Edge: action name with unicode** | `{action: "ジャンプ", events: [{type: "key", keycode: "KEY_SPACE"}]}` | Zod passes. Godot may accept or reject. |
| 7.47 | **Edge: Godot disconnected** | `{action: "jump", events: [{type: "key", keycode: "KEY_SPACE"}]}` with no Godot connection | Error: connection/timeout. |
| 7.48 | **Create and verify roundtrip** | `set_input_action` then `get_input_actions` | New action appears in get_input_actions with correct event mappings and deadzone. |
| 7.49 | **Modify and verify roundtrip** | Create action, modify deadzone, verify via `get_input_actions` | Deadzone updated correctly. |
| 7.50 | **Multiple actions roundtrip** | Create 3 custom actions, then call `get_input_actions` | All 3 appear with correct event mappings and deadzones. |

---

## Integration Scenarios

Combined workflows that exercise multiple tools in sequence.

| ID | Workflow | Steps | Expected Result |
|----|----------|-------|-----------------|
| I.1 | **Define action and simulate it** | 1. `set_input_action({action: "custom_jump", events: [{type: "key", keycode: "KEY_J"}]})`<br>2. Start game<br>3. `simulate_action({action: "custom_jump"})`<br>4. `simulate_action({action: "custom_jump", pressed: false})` | Action created, game started, action press+release simulated successfully. |
| I.2 | **Inspect, add, and verify input actions** | 1. `get_input_actions()` (capture baseline)<br>2. `set_input_action({action: "dash", events: [{type: "key", keycode: "KEY_SHIFT"}]})`<br>3. `get_input_actions()` (verify addition) | `"dash"` appears in the second call with Shift key mapping. |
| I.3 | **Full keyboard simulation workflow** | 1. Start game<br>2. `simulate_key({keycode: "KEY_W"})` (move forward)<br>3. `simulate_key({keycode: "KEY_W", pressed: false})` (stop)<br>4. `simulate_key({keycode: "KEY_SPACE"})` (jump)<br>5. `simulate_key({keycode: "KEY_SPACE", pressed: false})` (land) | All key events simulate correctly, producing the expected in-game behavior. |
| I.4 | **Mouse interaction workflow** | 1. `simulate_mouse_move({position: [400, 300]})`<br>2. `simulate_mouse_click({position: [400, 300], button: "left"})`<br>3. `simulate_mouse_click({position: [400, 300], button: "left", pressed: false})` | Mouse moves to center, clicks, releases. Full click cycle at (400,300). |
| I.5 | **Complex sequence workflow** | 1. `simulate_sequence({events: [{type: "key", keycode: "KEY_E", delay: 100}, {type: "mouse_move", position: [300, 200], delay: 200}, {type: "mouse_click", position: [300, 200], button: "right"}]})` | E pressed, mouse moved to (300,200) after 200ms, then right-clicked. All succeed. |
| I.6 | **Built-in UI navigation test** | 1. Start game with UI<br>2. `simulate_action({action: "ui_down"})`<br>3. `simulate_action({action: "ui_down"})`<br>4. `simulate_action({action: "ui_accept"})` | UI focus moves down twice, then accepts. UI element responds correctly. |
| I.7 | **Input map reconfiguration** | 1. `get_input_actions()` (capture original `ui_accept` mappings)<br>2. `set_input_action({action: "ui_accept", events: [{type: "key", keycode: "KEY_Q"}]})`<br>3. Start game<br>4. `simulate_action({action: "ui_accept"})`<br>5. Restore original `ui_accept` mappings via `set_input_action` | `ui_accept` fires from Q key. Original mappings restored. |
| I.8 | **Deadzone effect verification** | 1. `set_input_action({action: "analog_move", deadzone: 0.8, events: [{type: "joypad_button", button: 0}]})`<br>2. `get_input_actions()` | Deadzone of 0.8 is reflected in the action definition. |
| I.9 | **Multi-action simultaneous press** | 1. Start game<br>2. `simulate_action({action: "move_right"})`<br>3. `simulate_action({action: "jump"})`<br>4. `simulate_action({action: "jump", pressed: false})`<br>5. `simulate_action({action: "move_right", pressed: false})` | Both actions active simultaneously, then released. Should simulate diagonal jump. |
| I.10 | **Cursor position tracking** | 1. `simulate_mouse_move({position: [100, 100]})`<br>2. `simulate_mouse_move({position: [10, 10], relative: true})`<br>3. `simulate_mouse_move({position: [10, 10], relative: true})`<br>4. `simulate_mouse_click({position: [120, 120]})` | After two relative moves of +10,+10, cursor ends near (120,120). Click at expected position. |

---

## Edge Case Summary Table

| Tool | Empty call | Missing required | Wrong type | Out-of-range | Extra prop | NaN | null | Passthrough |
|------|-----------|-----------------|------------|-------------|------------|-----|------|-------------|
| `simulate_key` | ❌ keycode missing | ❌ Zod error | ❌ Zod error | N/A (string) | Ignored | ❌ error | ❌ error | N/A |
| `simulate_mouse_click` | ❌ position missing | ❌ Zod error | ❌ Zod error | N/A (unbounded) | Ignored | ❌ error | ❌ error | N/A |
| `simulate_mouse_move` | ❌ position missing | ❌ Zod error | ❌ Zod error | N/A (unbounded) | Ignored | ❌ error | ❌ error | N/A |
| `simulate_action` | ❌ action missing | ❌ Zod error | ❌ Zod error | N/A (string) | Ignored | ❌ error | ❌ error | N/A |
| `simulate_sequence` | ❌ events missing | ❌ Zod error | ❌ Zod error | N/A (array) | Ignored | ❌ error | ❌ error | ✅ Events: `.passthrough()` |
| `get_input_actions` | OK (no params) | N/A | N/A | N/A | Ignored | N/A | N/A | N/A |
| `set_input_action` | ❌ both missing | ❌ Zod error | ❌ Zod error | ❌ deadzone out of 0–1 | Ignored | ❌ error | ❌ error | ✅ Events: `.passthrough()` |

---

## Parameter Constraint Summary

| Tool | Param | Type | Required | Default | Min | Max | Constraints |
|------|-------|------|----------|---------|-----|-----|-------------|
| `simulate_key` | `keycode` | string | Yes | — | — | — | — |
| `simulate_key` | `pressed` | boolean | No | `true` | — | — | — |
| `simulate_key` | `echo` | boolean | No | — | — | — | optional |
| `simulate_mouse_click` | `position` | [number,number] | Yes | — | — | — | `z.tuple([z.number(), z.number()])` |
| `simulate_mouse_click` | `button` | enum | No | `"left"` | — | — | `"left"` \| `"right"` \| `"middle"` |
| `simulate_mouse_click` | `pressed` | boolean | No | `true` | — | — | — |
| `simulate_mouse_move` | `position` | [number,number] | Yes | — | — | — | `z.tuple([z.number(), z.number()])` |
| `simulate_mouse_move` | `relative` | boolean | No | — | — | — | optional |
| `simulate_action` | `action` | string | Yes | — | — | — | — |
| `simulate_action` | `pressed` | boolean | No | `true` | — | — | — |
| `simulate_sequence` | `events` | Array | Yes | — | — | — | `.passthrough()` per event; each event requires `type: string`; optional `delay: number` |
| `simulate_sequence` | `events[].type` | string | Yes (per event) | — | — | — | — |
| `simulate_sequence` | `events[].delay` | number | No (per event) | — | — | — | optional |
| `get_input_actions` | (none) | — | — | — | — | — | No params |
| `set_input_action` | `action` | string | Yes | — | — | — | — |
| `set_input_action` | `deadzone` | number | No | `0.5` | 0 | 1 | `.min(0).max(1)` |
| `set_input_action` | `events` | Array | Yes | — | — | — | `.passthrough()` per event; each event requires `type: string` |

---

## Runtime Dependency Matrix

| Tool | Requires game running | Modifies project | Modifies runtime state |
|------|----------------------|------------------|----------------------|
| `simulate_key` | ✅ Yes | No | Yes (injects input) |
| `simulate_mouse_click` | ✅ Yes | No | Yes (injects input) |
| `simulate_mouse_move` | ✅ Yes | No | Yes (injects input) |
| `simulate_action` | ✅ Yes | No | Yes (injects input) |
| `simulate_sequence` | ✅ Yes | No | Yes (injects input) |
| `get_input_actions` | No | No (read-only) | No |
| `set_input_action` | No | **Yes** (InputMap) | No |

---

## Notes

1. **Game must be running**: Tools 1–5 (`simulate_key`, `simulate_mouse_click`, `simulate_mouse_move`, `simulate_action`, `simulate_sequence`) all require the game to be actively playing. They go through the `mcp_runtime.gd` autoload. Verify the autoload is registered (`res://addons/godot_mcp/services/mcp_runtime.gd`) and logs `[MCP Runtime] Loaded and ready for IPC`.

2. **Event pass-through**: `simulate_sequence` and `set_input_action` use Zod's `.passthrough()` on event objects. This means additional properties (like `keycode`, `position`, `button`, `action`, `ctrl`, `shift`, `device`, `echo_allowed`, etc.) are forwarded to Godot without Zod validation. Godot's input handling determines whether they are accepted or ignored.

3. **Keycode format**: Godot uses the `KEY_` prefix convention (e.g., `KEY_SPACE`, `KEY_ENTER`, `KEY_A`). Non-standard keycode strings will pass Zod validation (they're just strings) but Godot will likely reject them. Full list of Godot keycodes: https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#enum-globalscope-key

4. **Built-in actions**: Godot projects come with pre-defined actions: `ui_accept`, `ui_cancel`, `ui_up`, `ui_down`, `ui_left`, `ui_right`, `ui_select`, `ui_focus_next`, `ui_focus_prev`, `ui_page_up`, `ui_page_down`, `ui_home`, `ui_end`, etc. `get_input_actions` should return all of them. `set_input_action` can modify their mappings.

5. **Position tuple validation**: Both `simulate_mouse_click` and `simulate_mouse_move` use `Position2D` which is `z.tuple([z.number(), z.number()])`. This means exactly 2 numbers are required — arrays with 1 or 3+ elements are rejected at the Zod level.

6. **Deadzone range**: `set_input_action`'s `deadzone` parameter is clamped to `[0, 1]` by Zod. Values outside this range are rejected before reaching Godot.

7. **Undo support**: `set_input_action` modifies the InputMap in project settings, which goes through Godot's undo system. Verify that Undo correctly reverts InputMap changes.

8. **Concurrency**: The MCP WebSocket bridge is sequential per design. Input simulation events during gameplay are injected into Godot's input queue and processed the next frame. Parallel tool calls from different MCP sessions would need separate testing.
