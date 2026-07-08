# Project Config Tools — Test Plan

**Source:** `server/src/tools/project_config.ts`
**Date:** 2026-07-08
**Coverage:** 12 tools (get_project_setting, set_project_setting_config, get_all_project_settings, reset_project_setting, get_input_map, set_input_map, add_input_action, remove_input_action, get_autoloads, add_autoload_config, remove_autoload_config, reorder_autoloads)

---

## Tool: `get_project_setting`

**Description:** Get a single project setting value by key (e.g. `display/window/size/viewport_width`).
**Handler:** `callGodot(bridge, 'project_config/get_setting', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `key` | string | **yes** | — | Project setting key path |

### Test Scenarios

#### 1. Happy path — read a known project setting
- **Description:** Read `application/config/name` (the project name).
- **Params:** `{ "key": "application/config/name" }`
- **Expected result:** Text response containing the project name string.
- **Notes:** Every Godot project has this setting. Value should match the project's `project.godot`.

#### 2. Read display/window size
- **Description:** Read the viewport width.
- **Params:** `{ "key": "display/window/size/viewport_width" }`
- **Expected result:** Text response containing a numeric value (e.g. `1920`).

#### 3. Read physics setting
- **Description:** Read the physics FPS.
- **Params:** `{ "key": "physics/common/physics_ticks_per_second" }`
- **Expected result:** Text response containing a numeric value (typically `60`).

#### 4. Read rendering setting
- **Description:** Read the renderer type.
- **Params:** `{ "key": "rendering/renderer/rendering_method" }`
- **Expected result:** Text response containing a string like `forward_plus`, `mobile`, or `gl_compatibility`.

#### 5. Read input setting
- **Description:** Read an input-related setting.
- **Params:** `{ "key": "input_devices/pointing/emulate_touch_from_mouse" }`
- **Expected result:** Text response containing a boolean value.

#### 6. Read a nonexistent setting
- **Description:** Request a setting key that does not exist.
- **Params:** `{ "key": "this/does/not/exist" }`
- **Expected result:** Either an error string from Godot, or a null/empty response. Server passes through Godot's response.

#### 7. Missing required param — no key
- **Description:** Call without `key`.
- **Params:** `{}`
- **Expected result:** Validation error (missing required field `key`).

#### 8. Invalid key type — number instead of string
- **Description:** Pass a number as key.
- **Params:** `{ "key": 42 }`
- **Expected result:** Validation error (expected string).

#### 9. Boolean key type
- **Description:** Pass a boolean as key.
- **Params:** `{ "key": true }`
- **Expected result:** Validation error (expected string).

#### 10. Empty key string
- **Description:** Pass an empty string.
- **Params:** `{ "key": "" }`
- **Expected result:** Request sent to Godot; Godot may reject with an error about invalid key.
- **Notes:** Server does not validate key content beyond type checking.

#### 11. Key with trailing slash
- **Description:** Read a group/section prefix (not a full key).
- **Params:** `{ "key": "display/window/" }`
- **Expected result:** Godot behavior for non-leaf keys varies; may return nothing or an error.

---

## Tool: `set_project_setting_config`

**Description:** Set a project setting value and save project.godot.
**Handler:** `callGodot(bridge, 'project_config/set_setting_config', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `key` | string | **yes** | — | Project setting key path |
| `value` | unknown | **yes** | — | Property value |

### Test Scenarios

#### 1. Happy path — set a string setting
- **Description:** Set the project name to a test value.
- **Params:** `{ "key": "application/config/name", "value": "TestProject" }`
- **Expected result:** `success`, project.godot updated. Call `get_project_setting` to verify the value was persisted.

#### 2. Set a numeric setting
- **Description:** Set the viewport width.
- **Params:** `{ "key": "display/window/size/viewport_width", "value": 1280 }`
- **Expected result:** `success`, setting updated.

#### 3. Set a boolean setting
- **Description:** Set emulated touch from mouse.
- **Params:** `{ "key": "input_devices/pointing/emulate_touch_from_mouse", "value": true }`
- **Expected result:** `success`, boolean setting updated.

#### 4. Set a float setting
- **Description:** Set the default gravity.
- **Params:** `{ "key": "physics/3d/default_gravity", "value": 9.8 }`
- **Expected result:** `success`, float setting updated.

#### 5. Set a string path setting
- **Description:** Set the main scene path.
- **Params:** `{ "key": "application/run/main_scene", "value": "res://scenes/main.tscn" }`
- **Expected result:** `success`, setting updated.

#### 6. Negative numbers
- **Description:** Set a setting with a negative value.
- **Params:** `{ "key": "display/window/size/viewport_height", "value": -1 }`
- **Expected result:** Godot may reject negative viewport size with an error. Server passes through the response.

#### 7. Very large number
- **Description:** Set with an extremely large integer.
- **Params:** `{ "key": "physics/common/physics_ticks_per_second", "value": 999999 }`
- **Expected result:** Godot may clamp or reject. Either `success` (clamped) or error.

#### 8. String for a numeric setting
- **Description:** Pass a string where a number is expected.
- **Params:** `{ "key": "display/window/size/viewport_width", "value": "one thousand" }`
- **Expected result:** Godot likely returns an error (type mismatch). Server passes through.
- **Notes:** Server schema uses `z.unknown()` for value, so no type validation at the MCP level.

#### 9. Missing required param — no key
- **Description:** Call with only `value`.
- **Params:** `{ "value": "foo" }`
- **Expected result:** Validation error (missing required field `key`).

#### 10. Missing required param — no value
- **Description:** Call with only `key`.
- **Params:** `{ "key": "application/config/name" }`
- **Expected result:** Validation error (missing required field `value`).

#### 11. Both params missing
- **Description:** Call with empty object.
- **Params:** `{}`
- **Expected result:** Validation error (missing required fields).

#### 12. Wrong key type
- **Description:** Pass a number instead of string for key.
- **Params:** `{ "key": 123, "value": "test" }`
- **Expected result:** Validation error (expected string for key).

#### 13. Complex object as value
- **Description:** Pass a nested object as value.
- **Params:** `{ "key": "application/config/name", "value": { "nested": true, "count": 5 } }`
- **Expected result:** Godot likely rejects; setting values are typically primitives. Server passes through.

#### 14. null as value
- **Description:** Pass null.
- **Params:** `{ "key": "application/config/name", "value": null }`
- **Expected result:** Godot likely rejects; server passes through.

#### 15. Array as value
- **Description:** Pass an array as value.
- **Params:** `{ "key": "application/config/name", "value": ["a", "b", "c"] }`
- **Expected result:** Godot may accept for array-typed settings, reject for scalar settings.

### Note: Side-effect verification
After each set, use `get_project_setting` to read back the same key and verify the value was persisted to `project.godot`. The `_config` suffix indicates this variant also saves `project.godot`, unlike a plain `set_project_setting`.

---

## Tool: `get_all_project_settings`

**Description:** Get all project settings, optionally filtered by prefix.
**Handler:** `callGodot(bridge, 'project_config/get_all_settings', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `filter` | string | no | — | Prefix filter (e.g. `display/`, `input/`) |

### Test Scenarios

#### 1. Happy path — get all settings (no filter)
- **Description:** Retrieve all project settings without a filter.
- **Params:** `{}`
- **Expected result:** Large text response containing all project settings. Should include `application/config/name`, `display/window/*`, `input/*`, `physics/*`, `rendering/*`, etc.
- **Notes:** Response may be very large (hundreds of settings). Verify presence of well-known keys.

#### 2. Filter by prefix — `display/`
- **Description:** Get only display-related settings.
- **Params:** `{ "filter": "display/" }`
- **Expected result:** Text response containing only settings that start with `display/`. Should NOT include `application/`, `physics/`, etc.

#### 3. Filter by prefix — `input/`
- **Description:** Get only input-related settings.
- **Params:** `{ "filter": "input/" }`
- **Expected result:** Text response containing only settings that start with `input/`.

#### 4. Filter by prefix — `application/`
- **Description:** Get application-level settings.
- **Params:** `{ "filter": "application/" }`
- **Expected result:** Text response containing `application/config/name`, `application/run/main_scene`, etc.

#### 5. Filter by prefix — `physics/`
- **Description:** Get physics-related settings.
- **Params:** `{ "filter": "physics/" }`
- **Expected result:** Text response containing only physics settings (gravity, FPS, etc.).

#### 6. Filter by prefix — `rendering/`
- **Description:** Get rendering-related settings.
- **Params:** `{ "filter": "rendering/" }`
- **Expected result:** Text response containing only rendering settings.

#### 7. Filter with no match
- **Description:** Use a prefix that matches no settings.
- **Params:** `{ "filter": "nonexistent_prefix/" }`
- **Expected result:** Empty or near-empty response.

#### 8. Filter without trailing slash
- **Description:** Use `display` instead of `display/`.
- **Params:** `{ "filter": "display" }`
- **Expected result:** Depends on Godot's prefix matching. May match `display/` prefix implicitly, or may match only exact key `display`. Test both behaviors.

#### 9. Nested filter
- **Description:** Use a deeply nested prefix.
- **Params:** `{ "filter": "display/window/size/" }`
- **Expected result:** Should return only settings like `display/window/size/viewport_width`, `display/window/size/viewport_height`, etc.

#### 10. Invalid filter type — number
- **Description:** Pass a number as filter.
- **Params:** `{ "filter": 123 }`
- **Expected result:** Validation error (expected string).

#### 11. Invalid filter type — boolean
- **Description:** Pass a boolean as filter.
- **Params:** `{ "filter": true }`
- **Expected result:** Validation error (expected string).

#### 12. Empty string filter
- **Description:** Pass an empty string filter.
- **Params:** `{ "filter": "" }`
- **Expected result:** Likely same behavior as no filter (returns all settings). Godot may treat empty prefix as match-all.

---

## Tool: `reset_project_setting`

**Description:** Reset a project setting to its default value.
**Handler:** `callGodot(bridge, 'project_config/reset_setting', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `key` | string | **yes** | — | Project setting key to reset |

### Test Scenarios

#### 1. Happy path — reset a previously modified setting
- **Description:** Set a setting, then reset it, and verify it returns to default.
- **Pre-condition:** Use `set_project_setting_config` to change `application/config/name` to `"ModifiedName"`.
- **Params:** `{ "key": "application/config/name" }`
- **Expected result:** `success`. Follow-up `get_project_setting` should show the default value (from the project template), NOT `"ModifiedName"`.
- **Notes:** This is a 3-step verification: set → reset → get.

#### 2. Reset viewport width
- **Description:** Reset the viewport width after having modified it.
- **Pre-condition:** Set `display/window/size/viewport_width` to a non-default value.
- **Params:** `{ "key": "display/window/size/viewport_width" }`
- **Expected result:** `success`. Setting returns to default (typically `1152`).

#### 3. Reset a setting that is already at default
- **Description:** Reset a setting that has never been modified.
- **Params:** `{ "key": "application/config/name" }`
- **Expected result:** `success` (no-op). Setting remains at its default value.

#### 4. Reset a nonexistent setting
- **Description:** Try to reset a key that does not exist.
- **Params:** `{ "key": "this/does/not/exist" }`
- **Expected result:** Godot may return an error or silently succeed. Server passes through.

#### 5. Reset a setting with trailing whitespace in key
- **Description:** Pass a key with trailing space.
- **Params:** `{ "key": "application/config/name " }`
- **Expected result:** Godot likely treats this as an invalid key (trailing space not trimmed). May fail with error.

#### 6. Missing required param — no key
- **Description:** Call with empty object.
- **Params:** `{}`
- **Expected result:** Validation error (missing required field `key`).

#### 7. Invalid key type — number
- **Description:** Pass a number as key.
- **Params:** `{ "key": 100 }`
- **Expected result:** Validation error (expected string).

#### 8. Empty string key
- **Description:** Pass an empty string.
- **Params:** `{ "key": "" }`
- **Expected result:** Godot likely returns an error for empty key.

---

## Tool: `get_input_map`

**Description:** Get all input actions and their mapped events from the InputMap.
**Handler:** `callGodot(bridge, 'project_config/get_input_map')`

### Parameters

*No parameters.*

### Test Scenarios

#### 1. Happy path — get the input map
- **Description:** Retrieve the current InputMap.
- **Params:** `{}`
- **Expected result:** Text response listing all input actions and their bound events. Should include default Godot actions like `ui_accept`, `ui_cancel`, `ui_up`, `ui_down`, `ui_left`, `ui_right`, etc.
- **Notes:** Default Godot project has several built-in actions. Even an empty project has these.

#### 2. Verify structure of response
- **Description:** Call and inspect the returned data structure.
- **Params:** `{}`
- **Expected result:** Response should be a mapping of action name → array of input events. Each event should have at least a `type` field.
- **Notes:** Compare structure against the return format of `add_input_action` and `set_input_map`.

#### 3. Call with unexpected params
- **Description:** Call with extra params that should be ignored.
- **Params:** `{ "extra": "garbage" }`
- **Expected result:** `success`. Extra params are ignored (no inputSchema validation to reject them, but may be silently unused).

#### 4. Call with empty params
- **Description:** Call with `{}`.
- **Params:** `{}`
- **Expected result:** `success`. Equivalent to scenario 1.

---

## Tool: `set_input_map`

**Description:** Replace the entire input map with the given actions and events.
**Handler:** `callGodot(bridge, 'project_config/set_input_map', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `actions` | record of `{type: string, ...}` arrays | **yes** | — | Map of action name to array of input events |

### Test Scenarios

#### 1. Happy path — set a minimal input map
- **Description:** Replace the input map with a single action bound to a key.
- **Params:**
  ```json
  {
    "actions": {
      "jump": [
        { "type": "key", "keycode": "KEY_SPACE" }
      ]
    }
  }
  ```
- **Expected result:** `success`. Follow-up `get_input_map` should show only the `jump` action.
- **Notes:** This is destructive — it replaces all existing actions. Consider restoring after test.

#### 2. Set map with multiple actions
- **Description:** Define multiple input actions.
- **Params:**
  ```json
  {
    "actions": {
      "move_left": [
        { "type": "key", "keycode": "KEY_A" },
        { "type": "key", "keycode": "KEY_LEFT" }
      ],
      "move_right": [
        { "type": "key", "keycode": "KEY_D" },
        { "type": "key", "keycode": "KEY_RIGHT" }
      ],
      "jump": [
        { "type": "key", "keycode": "KEY_SPACE" }
      ]
    }
  }
  ```
- **Expected result:** `success`. All three actions created with their bindings.

#### 3. Set map with joypad button events
- **Description:** Bind actions to controller buttons.
- **Params:**
  ```json
  {
    "actions": {
      "ui_accept": [
        { "type": "joypad_button", "button_index": 0 }
      ]
    }
  }
  ```
- **Expected result:** `success`. Joypad button binding created.

#### 4. Set map with mouse button events
- **Description:** Bind actions to mouse buttons.
- **Params:**
  ```json
  {
    "actions": {
      "shoot": [
        { "type": "mouse_button", "button_index": 1 }
      ]
    }
  }
  ```
- **Expected result:** `success`. Mouse button binding created.

#### 5. Set map with joypad axis events
- **Description:** Bind an action to a joystick axis.
- **Params:**
  ```json
  {
    "actions": {
      "look_horizontal": [
        { "type": "joypad_motion", "axis": 2, "axis_value": 1.0 }
      ]
    }
  }
  ```
- **Expected result:** `success`. Joypad axis event created.

#### 6. Set empty map
- **Description:** Replace input map with an empty actions object.
- **Params:** `{ "actions": {} }`
- **Expected result:** `success`. All input actions cleared. `get_input_map` should return empty.
- **Notes:** Destructive — restores to a blank input map.

#### 7. Events array without `type` field
- **Description:** Pass an event object that lacks a `type`.
- **Params:**
  ```json
  {
    "actions": {
      "jump": [
        { "keycode": "KEY_SPACE" }
      ]
    }
  }
  ```
- **Expected result:** Validation error (event object must have `type: string`).
- **Notes:** The schema uses `z.object({ type: z.string() }).passthrough()`, so `type` is required.

#### 8. Event with empty type string
- **Description:** Pass an event with `type: ""`.
- **Params:**
  ```json
  {
    "actions": {
      "jump": [
        { "type": "" }
      ]
    }
  }
  ```
- **Expected result:** Request sent to Godot; Godot likely rejects unknown event type.

#### 9. Missing required param — no actions
- **Description:** Call with empty object.
- **Params:** `{}`
- **Expected result:** Validation error (missing required field `actions`).

#### 10. Invalid actions type — string
- **Description:** Pass a string instead of an object.
- **Params:** `{ "actions": "not an object" }`
- **Expected result:** Validation error (expected object/map).

#### 11. Invalid events type — string instead of array
- **Description:** Pass a string for an action's events array.
- **Params:**
  ```json
  {
    "actions": {
      "jump": "not an array"
    }
  }
  ```
- **Expected result:** Validation error (expected array).

#### 12. Events array with non-object entries
- **Description:** Pass plain strings in the events array.
- **Params:**
  ```json
  {
    "actions": {
      "jump": ["KEY_SPACE"]
    }
  }
  ```
- **Expected result:** Validation error (expected object).

#### 13. Action name with special characters
- **Description:** Use an action name containing characters like spaces, dashes, etc.
- **Params:**
  ```json
  {
    "actions": {
      "player jump-action!": [
        { "type": "key", "keycode": "KEY_SPACE" }
      ]
    }
  }
  ```
- **Expected result:** Godot may accept or reject based on action name rules. Server passes through.

#### 14. Very large map
- **Description:** Create a map with many actions (50+).
- **Params:** Map of 50 action names, each with one key event.
- **Expected result:** `success`. Godot should handle a large input map.

---

## Tool: `add_input_action`

**Description:** Add a new input action with optional deadzone and event mappings.
**Handler:** `callGodot(bridge, 'project_config/add_input_action', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `action` | string | **yes** | — | Action name (e.g. `jump`, `move_left`) |
| `deadzone` | number (0–1) | no | `0.5` | Deadzone value (0-1, default 0.5) |
| `events` | array of `{type: string, ...}` | **yes** | — | Array of input events to map |

### Test Scenarios

#### 1. Happy path — add action with default deadzone
- **Description:** Add a new action with a key event using default deadzone.
- **Params:**
  ```json
  {
    "action": "test_jump",
    "events": [
      { "type": "key", "keycode": "KEY_SPACE" }
    ]
  }
  ```
- **Expected result:** `success`. `get_input_map` should include `test_jump` with deadzone `0.5` and the bound key event.

#### 2. Add action with explicit deadzone=0
- **Description:** Add an action with zero deadzone.
- **Params:**
  ```json
  {
    "action": "test_sprint",
    "deadzone": 0,
    "events": [
      { "type": "key", "keycode": "KEY_SHIFT" }
    ]
  }
  ```
- **Expected result:** `success`. Action created with deadzone `0`.

#### 3. Add action with deadzone=1
- **Description:** Add an action with maximum deadzone.
- **Params:**
  ```json
  {
    "action": "test_analog",
    "deadzone": 1,
    "events": [
      { "type": "joypad_motion", "axis": 0 }
    ]
  }
  ```
- **Expected result:** `success`. Action created with deadzone `1`.

#### 4. Add action with multiple events
- **Description:** Bind multiple keys to a single action.
- **Params:**
  ```json
  {
    "action": "test_move_up",
    "deadzone": 0.5,
    "events": [
      { "type": "key", "keycode": "KEY_W" },
      { "type": "key", "keycode": "KEY_UP" }
    ]
  }
  ```
- **Expected result:** `success`. Action created with both key bindings.

#### 5. Add action with joypad button
- **Description:** Bind a controller button.
- **Params:**
  ```json
  {
    "action": "test_interact",
    "events": [
      { "type": "joypad_button", "button_index": 0 }
    ]
  }
  ```
- **Expected result:** `success`. Joypad button event created.

#### 6. Add action with mouse button
- **Description:** Bind a mouse button.
- **Params:**
  ```json
  {
    "action": "test_shoot",
    "events": [
      { "type": "mouse_button", "button_index": 1 }
    ]
  }
  ```
- **Expected result:** `success`. Mouse button event created.

#### 7. Deadzone borderline — negative value
- **Description:** Pass deadzone = -0.1.
- **Params:**
  ```json
  {
    "action": "test_neg",
    "deadzone": -0.1,
    "events": [
      { "type": "key", "keycode": "KEY_A" }
    ]
  }
  ```
- **Expected result:** Validation error (deadzone must be >= 0 per `z.number().min(0)`).

#### 8. Deadzone borderline — value > 1
- **Description:** Pass deadzone = 1.1.
- **Params:**
  ```json
  {
    "action": "test_over",
    "deadzone": 1.1,
    "events": [
      { "type": "key", "keycode": "KEY_A" }
    ]
  }
  ```
- **Expected result:** Validation error (deadzone must be <= 1 per `z.number().max(1)`).

#### 9. Deadzone non-number type
- **Description:** Pass a string as deadzone.
- **Params:**
  ```json
  {
    "action": "test_str",
    "deadzone": "zero point five",
    "events": [
      { "type": "key", "keycode": "KEY_A" }
    ]
  }
  ```
- **Expected result:** Validation error (expected number).

#### 10. Missing required param — no action
- **Description:** Call without `action`.
- **Params:**
  ```json
  {
    "deadzone": 0.5,
    "events": [
      { "type": "key", "keycode": "KEY_SPACE" }
    ]
  }
  ```
- **Expected result:** Validation error (missing required field `action`).

#### 11. Missing required param — no events
- **Description:** Call without `events`.
- **Params:**
  ```json
  {
    "action": "test_no_events"
  }
  ```
- **Expected result:** Validation error (missing required field `events`).

#### 12. Empty events array
- **Description:** Pass an empty events array.
- **Params:**
  ```json
  {
    "action": "test_empty",
    "events": []
  }
  ```
- **Expected result:** `success` is sent to Godot. Godot may accept (action with no bindings) or reject.

#### 13. Duplicate action name
- **Description:** Try to add an action that already exists (e.g., `ui_accept` which is built-in).
- **Params:**
  ```json
  {
    "action": "ui_accept",
    "events": [
      { "type": "key", "keycode": "KEY_SPACE" }
    ]
  }
  ```
- **Expected result:** Godot behavior varies — may overwrite existing action or return an error about duplicate.

#### 14. Event object without `type`
- **Description:** Pass event without required `type` field.
- **Params:**
  ```json
  {
    "action": "test_no_type",
    "events": [
      { "keycode": "KEY_SPACE" }
    ]
  }
  ```
- **Expected result:** Validation error (event object must have `type: string`).

#### 15. Event with unknown type
- **Description:** Pass event with a bogus type string.
- **Params:**
  ```json
  {
    "action": "test_bogus",
    "events": [
      { "type": "imaginary_input" }
    ]
  }
  ```
- **Expected result:** Request sent to Godot; Godot likely rejects unknown event type.

#### 16. Action with numeric name
- **Description:** Pass a number as action name (zod coerces to string?).
- **Params:**
  ```json
  {
    "action": 42,
    "events": [
      { "type": "key", "keycode": "KEY_A" }
    ]
  }
  ```
- **Expected result:** Validation error (expected string for `action`).

#### 17. Events as non-array
- **Description:** Pass an object instead of array for events.
- **Params:**
  ```json
  {
    "action": "test_obj",
    "events": { "type": "key", "keycode": "KEY_A" }
  }
  ```
- **Expected result:** Validation error (expected array).

---

## Tool: `remove_input_action`

**Description:** Remove an input action from the InputMap.
**Handler:** `callGodot(bridge, 'project_config/remove_input_action', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `action` | string | **yes** | — | Action name to remove |

### Test Scenarios

#### 1. Happy path — remove a custom action
- **Description:** Add an action, then remove it.
- **Pre-condition:** Use `add_input_action` to create `test_remove_me` with a key event.
- **Params:** `{ "action": "test_remove_me" }`
- **Expected result:** `success`. Follow-up `get_input_map` should NOT include `test_remove_me`.

#### 2. Remove a built-in action
- **Description:** Remove a default Godot action.
- **Params:** `{ "action": "ui_accept" }`
- **Expected result:** `success`. `get_input_map` should not include `ui_accept`.
- **Notes:** Destructive for the built-in input map. Re-add after test.

#### 3. Remove a nonexistent action
- **Description:** Try to remove an action that was never created.
- **Params:** `{ "action": "this_action_does_not_exist" }`
- **Expected result:** Godot may return an error or silently succeed (no-op).

#### 4. Remove then add the same action
- **Description:** Remove an action, then re-add it with new bindings to confirm clean state.
- **Pre-condition:** Have `test_recreate` in the input map.
- **Params (remove):** `{ "action": "test_recreate" }`
- **Params (add):** `{ "action": "test_recreate", "events": [{ "type": "key", "keycode": "KEY_X" }] }`
- **Expected result:** Both `success`. The re-added action should have only `KEY_X`, not any previous bindings.

#### 5. Missing required param — no action
- **Description:** Call with empty object.
- **Params:** `{}`
- **Expected result:** Validation error (missing required field `action`).

#### 6. Invalid action type — number
- **Description:** Pass a number as action.
- **Params:** `{ "action": 123 }`
- **Expected result:** Validation error (expected string).

#### 7. Empty string action
- **Description:** Pass an empty action name.
- **Params:** `{ "action": "" }`
- **Expected result:** Godot likely rejects empty action name.

#### 8. Action name with whitespace only
- **Description:** Pass a whitespace string.
- **Params:** `{ "action": "   " }`
- **Expected result:** Godot likely rejects or treats as literal name. Server passes through.

---

## Tool: `get_autoloads`

**Description:** Get all autoload singletons configured in the project.
**Handler:** `callGodot(bridge, 'project_config/get_autoloads')`

### Parameters

*No parameters.*

### Test Scenarios

#### 1. Happy path — get autoloads in a project with defaults
- **Description:** Retrieve the autoload list.
- **Params:** `{}`
- **Expected result:** Text response listing autoload entries. In a default Godot project, may be empty. If the MCP plugin is installed, should include `mcp_runtime`.
- **Notes:** Each entry should have name, path, and enabled status.

#### 2. Verify response structure
- **Description:** Call and inspect that each entry includes `name`, `path`, `enabled`.
- **Params:** `{}`
- **Expected result:** Response should contain an array/list of objects, each with at minimum `name` and `path` fields.

#### 3. Get autoloads after adding one
- **Description:** Verify newly added autoload appears.
- **Pre-condition:** Use `add_autoload_config` to add an autoload.
- **Params:** `{}`
- **Expected result:** The newly added autoload should appear in the response.

#### 4. Call with unexpected params
- **Description:** Call with extra params (should be ignored).
- **Params:** `{ "extra": true }`
- **Expected result:** `success`. Extra params silently ignored.

---

## Tool: `add_autoload_config`

**Description:** Add an autoload singleton to the project.
**Handler:** `callGodot(bridge, 'project_config/add_autoload_config', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | string | **yes** | — | Autoload singleton name |
| `path` | string | **yes** | — | Script or scene path (e.g. `res://autoload/global.gd`) |
| `enabled` | boolean | no | `true` | Whether the autoload is enabled (default: true) |

### Test Scenarios

#### 1. Happy path — add enabled autoload to a script
- **Description:** Add an autoload pointing to an existing GDScript file.
- **Pre-condition:** A script file must exist at the target path (e.g. `res://autoload/test_global.gd`).
- **Params:**
  ```json
  {
    "name": "TestGlobal",
    "path": "res://autoload/test_global.gd"
  }
  ```
- **Expected result:** `success`. `get_autoloads` should include `TestGlobal` with `enabled: true`.
- **Notes:** The target `res://autoload/test_global.gd` must exist before calling this tool.

#### 2. Add disabled autoload
- **Description:** Add an autoload that is initially disabled.
- **Params:**
  ```json
  {
    "name": "DisabledGlobal",
    "path": "res://autoload/disabled_global.gd",
    "enabled": false
  }
  ```
- **Expected result:** `success`. `get_autoloads` should show `DisabledGlobal` with `enabled: false`.

#### 3. Add autoload with scene path
- **Description:** Add an autoload that points to a scene file instead of a script.
- **Pre-condition:** A scene file must exist at the target path.
- **Params:**
  ```json
  {
    "name": "SceneGlobal",
    "path": "res://scenes/ui_overlay.tscn"
  }
  ```
- **Expected result:** `success`. The autoload references the scene.

#### 4. Missing required param — no name
- **Description:** Call with only `path`.
- **Params:** `{ "path": "res://autoload/test.gd" }`
- **Expected result:** Validation error (missing required field `name`).

#### 5. Missing required param — no path
- **Description:** Call with only `name`.
- **Params:** `{ "name": "TestGlobal" }`
- **Expected result:** Validation error (missing required field `path`).

#### 6. Invalid name type — number
- **Description:** Pass a number as name.
- **Params:** `{ "name": 123, "path": "res://autoload/test.gd" }`
- **Expected result:** Validation error (expected string).

#### 7. Invalid path type — number
- **Description:** Pass a number as path.
- **Params:** `{ "name": "TestGlobal", "path": 123 }`
- **Expected result:** Validation error (expected string).

#### 8. Invalid enabled type — string
- **Description:** Pass a string for `enabled`.
- **Params:**
  ```json
  {
    "name": "TestGlobal",
    "path": "res://autoload/test.gd",
    "enabled": "yes"
  }
  ```
- **Expected result:** Validation error (expected boolean).

#### 9. Nonexistent path
- **Description:** Add an autoload pointing to a file that does not exist.
- **Params:**
  ```json
  {
    "name": "GhostGlobal",
    "path": "res://does_not_exist.gd"
  }
  ```
- **Expected result:** Godot likely returns an error (file not found). Server passes through.

#### 10. Duplicate autoload name
- **Description:** Try to add an autoload with a name that already exists.
- **Pre-condition:** An autoload with name `TestGlobal` already registered.
- **Params:**
  ```json
  {
    "name": "TestGlobal",
    "path": "res://autoload/other.gd"
  }
  ```
- **Expected result:** Godot likely returns an error (duplicate name). Server passes through.

#### 11. Empty name string
- **Description:** Pass an empty name.
- **Params:**
  ```json
  {
    "name": "",
    "path": "res://autoload/test.gd"
  }
  ```
- **Expected result:** Godot likely rejects empty name.

#### 12. Empty path string
- **Description:** Pass an empty path.
- **Params:**
  ```json
  {
    "name": "EmptyPath",
    "path": ""
  }
  ```
- **Expected result:** Godot likely rejects empty path.

#### 13. Non-res:// path
- **Description:** Use a non-standard path format.
- **Params:**
  ```json
  {
    "name": "BadPath",
    "path": "/absolute/path/on/disk.gd"
  }
  ```
- **Expected result:** Godot likely returns an error (path must be res:// or user://). Server passes through.

#### 14. Explicit enabled: true
- **Description:** Explicitly set enabled to true (same as default).
- **Params:**
  ```json
  {
    "name": "ExplicitEnabled",
    "path": "res://autoload/explicit.gd",
    "enabled": true
  }
  ```
- **Expected result:** `success`. Autoload appears enabled.

---

## Tool: `remove_autoload_config`

**Description:** Remove an autoload singleton from the project.
**Handler:** `callGodot(bridge, 'project_config/remove_autoload_config', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | string | **yes** | — | Autoload singleton name to remove |

### Test Scenarios

#### 1. Happy path — remove an autoload
- **Description:** Remove a previously added autoload.
- **Pre-condition:** Use `add_autoload_config` to add `RemoveMeGlobal`.
- **Params:** `{ "name": "RemoveMeGlobal" }`
- **Expected result:** `success`. `get_autoloads` should NOT include `RemoveMeGlobal`.

#### 2. Remove a disabled autoload
- **Description:** Remove an autoload that is disabled.
- **Pre-condition:** Add an autoload with `enabled: false`.
- **Params:** `{ "name": "DisabledGlobal" }`
- **Expected result:** `success`. Autoload removed regardless of enabled state.

#### 3. Remove a nonexistent autoload
- **Description:** Try to remove a name that is not registered.
- **Params:** `{ "name": "I_Dont_Exist" }`
- **Expected result:** Godot likely returns an error (autoload not found). Server passes through.

#### 4. Remove built-in autoload
- **Description:** Try to remove `mcp_runtime` (the MCP plugin autoload).
- **Params:** `{ "name": "mcp_runtime" }`
- **Expected result:** `success`. Autoload removed.
- **Notes:** This may break MCP runtime functionality. Re-add after test.

#### 5. Missing required param — no name
- **Description:** Call with empty object.
- **Params:** `{}`
- **Expected result:** Validation error (missing required field `name`).

#### 6. Invalid name type — number
- **Description:** Pass a number.
- **Params:** `{ "name": 42 }`
- **Expected result:** Validation error (expected string).

#### 7. Empty string name
- **Description:** Pass an empty name.
- **Params:** `{ "name": "" }`
- **Expected result:** Godot likely rejects; server passes through.

---

## Tool: `reorder_autoloads`

**Description:** Set the loading order of autoload singletons.
**Handler:** `callGodot(bridge, 'project_config/reorder_autoloads', args)`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `order` | array of strings | **yes** | — | Ordered list of autoload names (first loads first) |

### Test Scenarios

#### 1. Happy path — reorder autoloads
- **Description:** Provide a list that reorders existing autoload entries.
- **Pre-condition:** Multiple autoloads must be registered (e.g., `A`, `B`, `C`).
- **Params:** `{ "order": ["C", "A", "B"] }`
- **Expected result:** `success`. `get_autoloads` should list autoloads in the new order: C first, then A, then B.

#### 2. Reorder single autoload
- **Description:** Provide a list with one entry.
- **Pre-condition:** At least one autoload exists.
- **Params:** `{ "order": ["TestGlobal"] }`
- **Expected result:** `success` if `TestGlobal` is the only autoload or if Godot accepts a partial order list. Otherwise may error if all autoloads must be listed.

#### 3. Empty order list
- **Description:** Provide an empty array.
- **Params:** `{ "order": [] }`
- **Expected result:** Request sent to Godot. Godot may treat as clearing the order or return an error.

#### 4. Order with nonexistent entries
- **Description:** Include a name that is not registered.
- **Params:** `{ "order": ["RealAutoload", "FakeAutoload"] }`
- **Expected result:** Godot likely returns an error (unknown autoload name).

#### 5. Duplicate names in order
- **Description:** List the same name twice.
- **Params:** `{ "order": ["A", "B", "A"] }`
- **Expected result:** Godot likely returns an error (duplicate entry).

#### 6. Missing required param — no order
- **Description:** Call with empty object.
- **Params:** `{}`
- **Expected result:** Validation error (missing required field `order`).

#### 7. Invalid order type — string instead of array
- **Description:** Pass a string.
- **Params:** `{ "order": "A,B,C" }`
- **Expected result:** Validation error (expected array).

#### 8. Invalid order entries — numbers instead of strings
- **Description:** Pass numbers in the array.
- **Params:** `{ "order": [1, 2, 3] }`
- **Expected result:** Validation error (array items must be strings).

#### 9. Mixed types in order array
- **Description:** Mix strings and numbers.
- **Params:** `{ "order": ["A", 2, "C"] }`
- **Expected result:** Validation error (all items must be strings).

#### 10. Order as object
- **Description:** Pass an object instead of array.
- **Params:** `{ "order": { "0": "A", "1": "B" } }`
- **Expected result:** Validation error (expected array).

---

## Cross-Tool Integration Scenarios

### Scenario A: Full project settings lifecycle
1. `get_all_project_settings` with no filter → capture baseline.
2. `get_project_setting` for `application/config/name` → verify.
3. `set_project_setting_config` to change name → verify with `get_project_setting`.
4. `reset_project_setting` on `application/config/name` → verify restored to default.
5. `get_all_project_settings` with filter `application/` → verify only matching settings.

### Scenario B: Full input map lifecycle
1. `get_input_map` → capture original map.
2. `add_input_action` for `player_jump` with Space key and deadzone 0.3.
3. `add_input_action` for `player_shoot` with Left Mouse.
4. `get_input_map` → verify both actions present.
5. `remove_input_action` for `player_shoot`.
6. `get_input_map` → verify `player_shoot` removed, `player_jump` still present.
7. `set_input_map` to restore original map → verify restoration.

### Scenario C: Full autoload lifecycle
1. `get_autoloads` → capture baseline.
2. `add_autoload_config` for `ServiceA` (enabled) and `ServiceB` (disabled).
3. `get_autoloads` → verify both present with correct enabled flags.
4. `reorder_autoloads` to swap order: `["ServiceB", "ServiceA", ...others]`.
5. `get_autoloads` → verify new order.
6. `remove_autoload_config` for `ServiceB`.
7. `get_autoloads` → verify `ServiceB` removed, `ServiceA` remains.

---

## Validation Error Format

For all tools, when schema validation fails, expect a response in this format:
```json
{
  "content": [{"type": "text", "text": "Tool execution failed: <error message>"}],
  "isError": true
}
```

Common validation errors:
- Missing required param: `"Tool execution failed: Required"` (or similar Zod error).
- Wrong type: `"Tool execution failed: Expected string, received number"`.
- Out-of-range: `"Tool execution failed: Number must be less than or equal to 1"` (for deadzone > 1).

---

## Success Response Format

For all tools, when the handler succeeds, expect:
```json
{
  "content": [{"type": "text", "text": "<serialized result>"}]
}
```

If the WebSocket bridge to Godot fails, the response includes `isError: true` with a message starting with `"Godot request failed:"`.
