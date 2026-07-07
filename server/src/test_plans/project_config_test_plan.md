# Project Config Tools — Test Plan

> **Source file:** `server/src/tools/project_config.ts`  
> **Module purpose:** Project configuration tools — 12 tools for project settings, input map, and autoloads  
> **Shared types used:** `Name` (`z.string()`), `FilePath` (`z.string()`), `PropertyValue` (`z.unknown()`)  
> **Godot bridge method prefix:** `project_config/`  
> **Generated:** 2026-07-08

---

## Tool: `get_project_setting`

**Description:** Get a single project setting value by key (e.g. `'display/window/size/viewport_width'`).  
**Handler:** `callGodot(bridge, 'project_config/get_setting', args)`

### Parameters

| Parameter | Type   | Required | Description                                |
|-----------|--------|----------|--------------------------------------------|
| `key`     | string | ✅ Yes   | Project setting key path (e.g. `"display/window/size/viewport_width"`) |

### Test Scenarios

#### Scenario 1: Happy path — known setting key
- **Description:** Query a well-known project setting that always exists.
- **Params:** `{ "key": "application/config/name" }`
- **Expected Result:** JSON string — the project name as set in project.godot.
- **Notes:** This setting exists in every Godot project.

#### Scenario 2: Happy path — display setting
- **Description:** Query a display/window setting.
- **Params:** `{ "key": "display/window/size/viewport_width" }`
- **Expected Result:** Integer value (e.g., `1152` or whatever the project is configured to).
- **Notes:** Common display setting.

#### Scenario 3: Happy path — rendering setting
- **Description:** Query a rendering-related setting.
- **Params:** `{ "key": "rendering/renderer/rendering_method" }`
- **Expected Result:** String value (e.g., `"forward_plus"`, `"mobile"`, `"gl_compatibility"`).
- **Notes:** Validates that rendering category keys work.

#### Scenario 4: Happy path — input setting
- **Description:** Query an input category setting.
- **Params:** `{ "key": "input_devices/pointing/emulate_touch_from_mouse" }`
- **Expected Result:** Boolean value (`true` or `false`).
- **Notes:** Validates boolean return type.

#### Scenario 5: Happy path — physics setting
- **Description:** Query a physics setting.
- **Params:** `{ "key": "physics/3d/default_gravity" }`
- **Expected Result:** Number value (float, e.g., `9.8`).
- **Notes:** Default gravity. Validates numeric return type.

#### Scenario 6: Edge case — empty string key
- **Description:** Call with an empty string for `key`.
- **Params:** `{ "key": "" }`
- **Expected Result:** Error — empty string is not a valid setting key path. The Godot plugin should reject this.
- **Notes:** Zod accepts any string; the Godot side must validate.

#### Scenario 7: Edge case — key with trailing slash
- **Description:** Call with a key that ends in `/`.
- **Params:** `{ "key": "display/" }`
- **Expected Result:** May return an error or a partial result (depends on `ProjectSettings.has_setting()` behavior). Document actual result.
- **Notes:** Setting keys usually point to a specific value, not a category.

#### Scenario 8: Edge case — non-existent key
- **Description:** Call with a key that does not exist in project settings.
- **Params:** `{ "key": "completely/fake/setting/that/does/not/exist" }`
- **Expected Result:** Error — setting not found.
- **Notes:** The bridge should return a clear error, not crash.

#### Scenario 9: Edge case — key with leading slash
- **Description:** Call with a key starting with `/`.
- **Params:** `{ "key": "/application/config/name" }`
- **Expected Result:** Error or empty result — Godot setting keys do not start with `/`.
- **Notes:** Valid keys look like `"section/subsection/property"` without a leading slash.

#### Scenario 10: Edge case — missing required parameter
- **Description:** Call without the `key` parameter.
- **Params:** `{}`
- **Expected Result:** Zod validation error: `key` is required.
- **Notes:** The MCP framework/Zod should reject this before it reaches Godot.

#### Scenario 11: Edge case — key not a string
- **Description:** Call with a non-string value for `key`.
- **Params:** `{ "key": 12345 }`
- **Expected Result:** Zod validation error — expected string, received number.
- **Notes:** —

#### Scenario 12: Edge case — very long key string
- **Description:** Call with an extremely long key string.
- **Params:** `{ "key": "a".repeat(10000) }`
- **Expected Result:** Error — key too long or setting not found. Should not crash.
- **Notes:** Stress test for input handling.

---

## Tool: `set_project_setting_config`

**Description:** Set a project setting value and save project.godot.  
**Handler:** `callGodot(bridge, 'project_config/set_setting_config', args)`

### Parameters

| Parameter | Type    | Required | Description                                |
|-----------|---------|----------|--------------------------------------------|
| `key`     | string  | ✅ Yes   | Project setting key path                   |
| `value`   | unknown | ✅ Yes   | Property value (any valid JSON-serializable value) |

### Test Scenarios

#### Scenario 1: Happy path — set string value
- **Description:** Set a string project setting (e.g., project name).
- **Params:** `{ "key": "application/config/name", "value": "TestProject" }`
- **Expected Result:** Success — setting updated and saved to project.godot. Subsequent `get_project_setting` returns `"TestProject"`.
- **Notes:** After testing, restore the original project name.

#### Scenario 2: Happy path — set boolean value
- **Description:** Set a boolean project setting.
- **Params:** `{ "key": "application/config/use_hidden_project_data_directory", "value": false }`
- **Expected Result:** Success — boolean value saved.
- **Notes:** Use a less-critical boolean setting for testing.

#### Scenario 3: Happy path — set integer value
- **Description:** Set an integer project setting.
- **Params:** `{ "key": "display/window/size/viewport_width", "value": 1920 }`
- **Expected Result:** Success — integer value saved.
- **Notes:** After testing, restore the original value.

#### Scenario 4: Happy path — set float value
- **Description:** Set a float project setting.
- **Params:** `{ "key": "physics/3d/default_gravity", "value": 15.0 }`
- **Expected Result:** Success — float value saved.
- **Notes:** After testing, restore the original value (9.8).

#### Scenario 5: Edge case — set null value
- **Description:** Call with `value: null`.
- **Params:** `{ "key": "application/config/name", "value": null }`
- **Expected Result:** May succeed (setting to null could reset) or error. Document actual behavior.
- **Notes:** `PropertyValue` is `z.unknown()`, so null is accepted. The Godot plugin determines handling.

#### Scenario 6: Edge case — set value for non-existent key
- **Description:** Call with a key that does not exist.
- **Params:** `{ "key": "completely/fake/setting", "value": "test" }`
- **Expected Result:** Error — setting key does not exist. Or may create a custom setting (depends on Godot behavior). Document actual result.
- **Notes:** Godot may or may not allow creating arbitrary custom settings via `ProjectSettings.set_setting()`.

#### Scenario 7: Edge case — set value with wrong type for key
- **Description:** Call with a value type that does not match the expected type for the key.
- **Params:** `{ "key": "application/config/name", "value": 12345 }`
- **Expected Result:** May succeed (Godot may coerce types) or fail. Document actual behavior.
- **Notes:** `application/config/name` expects a string; passing a number may cause unexpected behavior.

#### Scenario 8: Edge case — empty string key
- **Description:** Call with an empty string for `key`.
- **Params:** `{ "key": "", "value": "test" }`
- **Expected Result:** Error — invalid key.
- **Notes:** —

#### Scenario 9: Edge case — missing `key` parameter
- **Description:** Call without the `key` parameter.
- **Params:** `{ "value": "test" }`
- **Expected Result:** Zod validation error: `key` is required.
- **Notes:** —

#### Scenario 10: Edge case — missing `value` parameter
- **Description:** Call without the `value` parameter.
- **Params:** `{ "key": "application/config/name" }`
- **Expected Result:** May be treated as `undefined` (depends on whether Zod allows `undefined`). The Godot plugin may reject or crash. Document actual behavior.
- **Notes:** `z.unknown()` may or may not accept `undefined`. If the MCP framework strips undefined keys, the Godot-side handler will error.

#### Scenario 11: Edge case — complex object value
- **Description:** Set a setting that expects a complex value (e.g., a Vector3 represented as a string or object).
- **Params:** `{ "key": "display/window/size/viewport_width", "value": { "nested": true, "data": [1, 2, 3] } }`
- **Expected Result:** Error or unexpected behavior — the key expects a number, not an object.
- **Notes:** Tests how the bridge handles type mismatches.

#### Scenario 12: Edge case — set value that changes editor behavior
- **Description:** Set a rendering-related setting.
- **Params:** `{ "key": "rendering/renderer/rendering_method", "value": "mobile" }`
- **Expected Result:** Success — setting updated. Editor may prompt for restart.
- **Notes:** After testing, restore to original value (`"forward_plus"` typically).

---

## Tool: `get_all_project_settings`

**Description:** Get all project settings, optionally filtered by prefix.  
**Handler:** `callGodot(bridge, 'project_config/get_all_settings', args)`

### Parameters

| Parameter | Type   | Required | Description                                |
|-----------|--------|----------|--------------------------------------------|
| `filter`  | string | ❌ No    | Prefix filter (e.g. `"display/"`, `"input/"`). Omit to get all settings. |

### Test Scenarios

#### Scenario 1: Happy path — no filter (all settings)
- **Description:** Retrieve all project settings without any filter.
- **Params:** `{}`
- **Expected Result:** JSON object containing all project settings. Should include keys from `application/`, `display/`, `rendering/`, `input/`, `physics/`, etc. The response may be large.
- **Notes:** This is the broadest query. Verify the response contains expected keys.

#### Scenario 2: Happy path — filter by `display/`
- **Description:** Filter settings by the `"display/"` prefix.
- **Params:** `{ "filter": "display/" }`
- **Expected Result:** JSON object containing only settings under the `display/` namespace (e.g., `display/window/size/viewport_width`, `display/window/size/viewport_height`, `display/window/stretch/mode`, etc.).
- **Notes:** Should NOT contain settings from `application/`, `rendering/`, etc.

#### Scenario 3: Happy path — filter by `input/`
- **Description:** Filter settings by the `"input/"` prefix.
- **Params:** `{ "filter": "input/" }`
- **Expected Result:** JSON object containing only settings under the `input/` namespace (e.g., input map actions and device settings).
- **Notes:** Input settings include user-defined input actions.

#### Scenario 4: Happy path — filter by `application/`
- **Description:** Filter settings by the `"application/"` prefix.
- **Params:** `{ "filter": "application/" }`
- **Expected Result:** JSON object containing application-level settings (name, version, icon, config, etc.).
- **Notes:** —

#### Scenario 5: Happy path — filter by `rendering/`
- **Description:** Filter settings by the `"rendering/"` prefix.
- **Params:** `{ "filter": "rendering/" }`
- **Expected Result:** JSON object containing rendering settings (renderer, quality, anti-aliasing, etc.).
- **Notes:** —

#### Scenario 6: Happy path — filter by `physics/`
- **Description:** Filter settings by the `"physics/"` prefix.
- **Params:** `{ "filter": "physics/" }`
- **Expected Result:** JSON object containing physics settings (gravity, FPS, engine, layers, etc.).
- **Notes:** —

#### Scenario 7: Edge case — narrow filter with trailing slash
- **Description:** Filter by a deeply nested prefix.
- **Params:** `{ "filter": "display/window/size/" }`
- **Expected Result:** JSON object containing only settings under `display/window/size/` (e.g., `viewport_width`, `viewport_height`, `window_width_override`, etc.).
- **Notes:** Narrow prefix should return only deeply specific keys.

#### Scenario 8: Edge case — filter that matches no settings
- **Description:** Use a filter prefix that does not match any known settings.
- **Params:** `{ "filter": "nonexistent/prefix/" }`
- **Expected Result:** Empty JSON object `{}` (or equivalent empty result). Should NOT error.
- **Notes:** No-matches should not be an error condition.

#### Scenario 9: Edge case — empty string filter
- **Description:** Call with an empty string for `filter`.
- **Params:** `{ "filter": "" }`
- **Expected Result:** May return all settings (same as no filter) or error. Document actual behavior.
- **Notes:** Empty string is not a meaningful prefix filter.

#### Scenario 10: Edge case — filter not a string
- **Description:** Call with a non-string value for `filter`.
- **Params:** `{ "filter": 123 }`
- **Expected Result:** Zod validation error — expected string, received number.
- **Notes:** —

#### Scenario 11: Edge case — filter with no trailing slash
- **Description:** Filter by a partial prefix without trailing slash.
- **Params:** `{ "filter": "display" }`
- **Expected Result:** May return settings matching `display*` (including `display/...`). Or may match nothing if exact prefix match is required. Document actual behavior.
- **Notes:** The behavior depends on whether the Godot plugin uses prefix matching or exact string matching.

#### Scenario 12: Edge case — filter with leading slash
- **Description:** Call with a filter starting with `/`.
- **Params:** `{ "filter": "/display/" }`
- **Expected Result:** Either returns empty results (no match) or handles incorrectly. Document actual behavior.
- **Notes:** Godot setting keys do not start with `/`.

---

## Tool: `reset_project_setting`

**Description:** Reset a project setting to its default value.  
**Handler:** `callGodot(bridge, 'project_config/reset_setting', args)`

### Parameters

| Parameter | Type   | Required | Description                                |
|-----------|--------|----------|--------------------------------------------|
| `key`     | string | ✅ Yes   | Project setting key to reset               |

### Test Scenarios

#### Scenario 1: Happy path — reset a previously modified setting
- **Description:** First set a setting to a non-default value, then reset it.
- **Setup:** Use `set_project_setting_config` to change `"application/config/name"` to `"TempName"`.
- **Params:** `{ "key": "application/config/name" }`
- **Expected Result:** Success — the setting reverts to its default value (the original project name). The original value should be restored.
- **Notes:** After this test, the project name should be back to its original value.

#### Scenario 2: Happy path — reset a display setting
- **Description:** Reset a display setting to default.
- **Setup:** Use `set_project_setting_config` to change `"display/window/size/viewport_width"` to a non-default value (e.g., `800`).
- **Params:** `{ "key": "display/window/size/viewport_width" }`
- **Expected Result:** Success — the setting reverts to its default value.
- **Notes:** Verify with `get_project_setting` after reset.

#### Scenario 3: Happy path — reset a physics setting
- **Description:** Reset a physics setting to default.
- **Setup:** Use `set_project_setting_config` to change `"physics/3d/default_gravity"` to `20.0`.
- **Params:** `{ "key": "physics/3d/default_gravity" }`
- **Expected Result:** Success — gravity reverts to default `9.8`.
- **Notes:** —

#### Scenario 4: Happy path — reset a setting that is already at default
- **Description:** Call reset on a setting that has never been modified.
- **Params:** `{ "key": "application/config/name" }`
- **Expected Result:** Success (idempotent) — no change occurs because the setting was already at its default. Should not error.
- **Notes:** Resetting an already-default value should be a no-op, not an error.

#### Scenario 5: Edge case — empty string key
- **Description:** Call with an empty string for `key`.
- **Params:** `{ "key": "" }`
- **Expected Result:** Error — invalid key.
- **Notes:** —

#### Scenario 6: Edge case — non-existent key
- **Description:** Call with a key that does not exist.
- **Params:** `{ "key": "completely/fake/setting_xyz" }`
- **Expected Result:** Error — setting not found. Or may succeed silently if the plugin treats it as a no-op. Document actual behavior.
- **Notes:** —

#### Scenario 7: Edge case — missing required parameter
- **Description:** Call without the `key` parameter.
- **Params:** `{}`
- **Expected Result:** Zod validation error: `key` is required.
- **Notes:** —

#### Scenario 8: Edge case — key not a string
- **Description:** Call with a non-string value for `key`.
- **Params:** `{ "key": true }`
- **Expected Result:** Zod validation error — expected string, received boolean.
- **Notes:** —

---

## Tool: `get_input_map`

**Description:** Get all input actions and their mapped events from the InputMap.  
**Handler:** `callGodot(bridge, 'project_config/get_input_map')`

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| *(none)*  | —    | —        | No parameters. |

### Test Scenarios

#### Scenario 1: Happy path — default input map
- **Description:** Retrieve the input map from a default/new project.
- **Params:** `{}`
- **Expected Result:** JSON object containing all defined input actions and their event mappings. In a default Godot project, should include built-in UI actions like `ui_accept`, `ui_cancel`, `ui_left`, `ui_right`, `ui_up`, `ui_down`, etc.
- **Notes:** —

#### Scenario 2: Happy path — after adding a custom action
- **Description:** Add a custom action via `add_input_action`, then retrieve the input map.
- **Setup:** Call `add_input_action` with a custom action (e.g., `"player_jump"` with a Space key event).
- **Params:** `{}`
- **Expected Result:** JSON object that now includes the custom `"player_jump"` action alongside the built-in actions.
- **Notes:** Verifies that the input map is mutable and changes are reflected in subsequent reads.

#### Scenario 3: Edge case — called with extraneous parameters
- **Description:** Call with an unexpected parameter.
- **Params:** `{ "extra": "value" }`
- **Expected Result:** Should succeed — extraneous parameters should be silently ignored or Zod should strip them.
- **Notes:** The schema is `{}`, so Zod may strip extra keys or reject them depending on strictness.

#### Scenario 4: Edge case — empty input map
- **Description:** Retrieve input map from a project where all actions have been removed.
- **Setup:** Use `set_input_map` with `{ "actions": {} }` to clear all actions.
- **Params:** `{}`
- **Expected Result:** Empty JSON object `{}` — no actions defined.
- **Notes:** After testing, restore built-in UI actions. An empty input map is technically valid.

---

## Tool: `set_input_map`

**Description:** Replace the entire input map with the given actions and events.  
**Handler:** `callGodot(bridge, 'project_config/set_input_map', args)`

### Parameters

| Parameter | Type                    | Required | Description                                |
|-----------|-------------------------|----------|--------------------------------------------|
| `actions` | `Record<string, Array>` | ✅ Yes   | Map of action name to array of input events. Each event is an object with at least a `type` field (e.g., `"key"`, `"mouse_button"`, `"joypad_button"`). Additional event-specific properties are passed through. |

### Test Scenarios

#### Scenario 1: Happy path — set simple input map
- **Description:** Replace the input map with a few custom actions.
- **Params:**
  ```json
  {
    "actions": {
      "move_left": [{ "type": "key", "keycode": "KEY_A" }],
      "move_right": [{ "type": "key", "keycode": "KEY_D" }],
      "jump": [{ "type": "key", "keycode": "KEY_SPACE" }]
    }
  }
  ```
- **Expected Result:** Success — input map replaced. `get_input_map` should return only these three actions.
- **Notes:** After testing, restore the default input map (or project defaults).

#### Scenario 2: Happy path — set actions with multiple events per action
- **Description:** Set an action with both keyboard and gamepad bindings.
- **Params:**
  ```json
  {
    "actions": {
      "move_left": [
        { "type": "key", "keycode": "KEY_A" },
        { "type": "key", "keycode": "KEY_LEFT" },
        { "type": "joypad_button", "button_index": 14 }
      ]
    }
  }
  ```
- **Expected Result:** Success — the action has three event mappings. `get_input_map` should show all three events for `"move_left"`.
- **Notes:** Multiple events per action is a common pattern (keyboard + controller).

#### Scenario 3: Happy path — set empty input map
- **Description:** Replace the input map with no actions.
- **Params:** `{ "actions": {} }`
- **Expected Result:** Success — input map cleared. `get_input_map` returns `{}`.
- **Notes:** After testing, restore built-in UI actions.

#### Scenario 4: Happy path — set mouse button event
- **Description:** Set an action with a mouse button event.
- **Params:**
  ```json
  {
    "actions": {
      "shoot": [{ "type": "mouse_button", "button_index": 1 }]
    }
  }
  ```
- **Expected Result:** Success — mouse button event mapped.
- **Notes:** Mouse button index 1 = left button.

#### Scenario 5: Happy path — set joypad axis event
- **Description:** Set an action with a joypad axis event.
- **Params:**
  ```json
  {
    "actions": {
      "look_horizontal": [{ "type": "joypad_motion", "axis": 2 }]
    }
  }
  ```
- **Expected Result:** Success — joypad axis event mapped.
- **Notes:** Tests joypad motion events.

#### Scenario 6: Edge case — event object missing `type` field
- **Description:** Include an event that does not have a `type` field.
- **Params:**
  ```json
  {
    "actions": {
      "bad_action": [{ "keycode": "KEY_A" }]
    }
  }
  ```
- **Expected Result:** Zod validation error — `type` is required in each event object.
- **Notes:** The schema uses `z.object({ type: z.string() }).passthrough()`, so `type` is required.

#### Scenario 7: Edge case — empty event array
- **Description:** Set an action with an empty events array.
- **Params:**
  ```json
  {
    "actions": {
      "empty_action": []
    }
  }
  ```
- **Expected Result:** May succeed (action created with no bindings) or error. Document actual behavior.
- **Notes:** An action with no events is functionally useless but may be technically valid.

#### Scenario 8: Edge case — missing `actions` parameter
- **Description:** Call without the `actions` parameter.
- **Params:** `{}`
- **Expected Result:** Zod validation error: `actions` is required.
- **Notes:** —

#### Scenario 9: Edge case — `actions` is not a record (e.g., string)
- **Description:** Call with a string for `actions` instead of an object.
- **Params:** `{ "actions": "invalid" }`
- **Expected Result:** Zod validation error — expected object, received string.
- **Notes:** `z.record(z.array(...))` enforces the shape.

#### Scenario 10: Edge case — `actions` is null
- **Description:** Call with `actions: null`.
- **Params:** `{ "actions": null }`
- **Expected Result:** Zod validation error — expected object, received null.
- **Notes:** —

#### Scenario 11: Edge case — invalid event type string
- **Description:** Use an event `type` that Godot does not recognize.
- **Params:**
  ```json
  {
    "actions": {
      "test": [{ "type": "invalid_event_type_xyz" }]
    }
  }
  ```
- **Expected Result:** Zod accepts it (any string for `type`), but the Godot plugin should reject or ignore the invalid event type. Document actual behavior.
- **Notes:** The schema does not restrict event type values.

---

## Tool: `add_input_action`

**Description:** Add a new input action with optional deadzone and event mappings.  
**Handler:** `callGodot(bridge, 'project_config/add_input_action', args)`

### Parameters

| Parameter  | Type             | Required | Description                                | Constraints              |
|------------|------------------|----------|--------------------------------------------|--------------------------|
| `action`   | string           | ✅ Yes   | Action name (e.g. `"jump"`, `"move_left"`) | —                        |
| `deadzone` | number           | ❌ No    | Deadzone value                             | `min: 0`, `max: 1`, `default: 0.5` |
| `events`   | `Array<object>`  | ✅ Yes   | Array of input events to map               | Each event must have a `type` string field |

### Test Scenarios

#### Scenario 1: Happy path — basic action with key event
- **Description:** Add a new action with a single keyboard event.
- **Params:**
  ```json
  {
    "action": "player_run",
    "events": [{ "type": "key", "keycode": "KEY_SHIFT" }]
  }
  ```
- **Expected Result:** Success — new action added. `get_input_map` should include `"player_run"` with a default deadzone of `0.5`.
- **Notes:** —

#### Scenario 2: Happy path — action with custom deadzone
- **Description:** Add an action with an explicit deadzone value.
- **Params:**
  ```json
  {
    "action": "player_look",
    "deadzone": 0.2,
    "events": [{ "type": "joypad_motion", "axis": 2 }]
  }
  ```
- **Expected Result:** Success — action added with deadzone `0.2`.
- **Notes:** Deadzone should be reflected when reading the input map.

#### Scenario 3: Happy path — action with multiple events
- **Description:** Add an action with both keyboard and controller events.
- **Params:**
  ```json
  {
    "action": "player_interact",
    "events": [
      { "type": "key", "keycode": "KEY_E" },
      { "type": "joypad_button", "button_index": 0 }
    ]
  }
  ```
- **Expected Result:** Success — action added with two event mappings.
- **Notes:** —

#### Scenario 4: Happy path — action with mouse button event
- **Description:** Add an action with a mouse event.
- **Params:**
  ```json
  {
    "action": "player_shoot",
    "events": [{ "type": "mouse_button", "button_index": 1 }]
  }
  ```
- **Expected Result:** Success — mouse event mapped.
- **Notes:** —

#### Scenario 5: Edge case — action name already exists
- **Description:** Try to add an action with a name that already exists in the input map.
- **Setup:** `"ui_accept"` is a built-in action.
- **Params:**
  ```json
  {
    "action": "ui_accept",
    "events": [{ "type": "key", "keycode": "KEY_ENTER" }]
  }
  ```
- **Expected Result:** May error (duplicate action) or overwrite the existing action. Document actual behavior.
- **Notes:** The Godot plugin determines whether to reject duplicates or overwrite.

#### Scenario 6: Edge case — empty action name
- **Description:** Call with an empty string for `action`.
- **Params:**
  ```json
  {
    "action": "",
    "events": [{ "type": "key", "keycode": "KEY_A" }]
  }
  ```
- **Expected Result:** Error — empty string is not a valid action name.
- **Notes:** —

#### Scenario 7: Edge case — empty events array
- **Description:** Call with an empty events array.
- **Params:**
  ```json
  {
    "action": "empty_binding",
    "events": []
  }
  ```
- **Expected Result:** May succeed (creates action with no bindings) or error. Document actual behavior.
- **Notes:** —

#### Scenario 8: Edge case — deadzone at minimum boundary (0)
- **Description:** Call with `deadzone: 0`.
- **Params:**
  ```json
  {
    "action": "min_deadzone",
    "deadzone": 0,
    "events": [{ "type": "joypad_motion", "axis": 0 }]
  }
  ```
- **Expected Result:** Success — deadzone set to `0` (most sensitive). No deadzone at all.
- **Notes:** Boundary test for the `min: 0` constraint.

#### Scenario 9: Edge case — deadzone at maximum boundary (1)
- **Description:** Call with `deadzone: 1`.
- **Params:**
  ```json
  {
    "action": "max_deadzone",
    "deadzone": 1,
    "events": [{ "type": "joypad_motion", "axis": 0 }]
  }
  ```
- **Expected Result:** Success — deadzone set to `1` (least sensitive, essentially disabled).
- **Notes:** Boundary test for the `max: 1` constraint.

#### Scenario 10: Edge case — deadzone below minimum (negative)
- **Description:** Call with `deadzone: -0.1`.
- **Params:**
  ```json
  {
    "action": "negative_deadzone",
    "deadzone": -0.1,
    "events": [{ "type": "joypad_motion", "axis": 0 }]
  }
  ```
- **Expected Result:** Zod validation error — deadzone must be >= 0.
- **Notes:** The `.min(0)` constraint should block this.

#### Scenario 11: Edge case — deadzone above maximum (> 1)
- **Description:** Call with `deadzone: 1.5`.
- **Params:**
  ```json
  {
    "action": "over_deadzone",
    "deadzone": 1.5,
    "events": [{ "type": "joypad_motion", "axis": 0 }]
  }
  ```
- **Expected Result:** Zod validation error — deadzone must be <= 1.
- **Notes:** The `.max(1)` constraint should block this.

#### Scenario 12: Edge case — deadzone is not a number
- **Description:** Call with `deadzone: "half"`.
- **Params:**
  ```json
  {
    "action": "string_deadzone",
    "deadzone": "half",
    "events": [{ "type": "joypad_motion", "axis": 0 }]
  }
  ```
- **Expected Result:** Zod validation error — expected number, received string.
- **Notes:** —

#### Scenario 13: Edge case — event object missing `type`
- **Description:** Include an event without a `type` field.
- **Params:**
  ```json
  {
    "action": "bad_event",
    "events": [{ "keycode": "KEY_A" }]
  }
  ```
- **Expected Result:** Zod validation error — `type` is required in each event.
- **Notes:** —

#### Scenario 14: Edge case — missing `action` parameter
- **Description:** Call without the `action` parameter.
- **Params:**
  ```json
  {
    "events": [{ "type": "key", "keycode": "KEY_A" }]
  }
  ```
- **Expected Result:** Zod validation error: `action` is required.
- **Notes:** —

#### Scenario 15: Edge case — missing `events` parameter
- **Description:** Call without the `events` parameter.
- **Params:** `{ "action": "no_events" }`
- **Expected Result:** Zod validation error: `events` is required.
- **Notes:** —

#### Scenario 16: Edge case — action name with special characters
- **Description:** Call with an action name containing spaces or special characters.
- **Params:**
  ```json
  {
    "action": "My Action! @#$",
    "events": [{ "type": "key", "keycode": "KEY_A" }]
  }
  ```
- **Expected Result:** May succeed or error depending on Godot's action name validation. Document actual behavior.
- **Notes:** Godot action names are typically `snake_case` lowercase alphanumeric with underscores.

---

## Tool: `remove_input_action`

**Description:** Remove an input action from the InputMap.  
**Handler:** `callGodot(bridge, 'project_config/remove_input_action', args)`

### Parameters

| Parameter | Type   | Required | Description                                |
|-----------|--------|----------|--------------------------------------------|
| `action`  | string | ✅ Yes   | Action name to remove                      |

### Test Scenarios

#### Scenario 1: Happy path — remove a custom action
- **Description:** Add a custom action, then remove it.
- **Setup:** Call `add_input_action` to create `"temp_action"`.
- **Params:** `{ "action": "temp_action" }`
- **Expected Result:** Success — action removed from input map. `get_input_map` should no longer include `"temp_action"`.
- **Notes:** —

#### Scenario 2: Happy path — remove a built-in action
- **Description:** Remove a built-in UI action such as `"ui_accept"`.
- **Params:** `{ "action": "ui_accept" }`
- **Expected Result:** Success — `"ui_accept"` removed. `get_input_map` should no longer include `"ui_accept"`.
- **Notes:** After testing, re-add the built-in action so the project remains functional. Removing built-in actions may break UI navigation.

#### Scenario 3: Edge case — remove non-existent action
- **Description:** Try to remove an action that does not exist.
- **Params:** `{ "action": "nonexistent_action_12345" }`
- **Expected Result:** Error — action not found. Or may succeed silently (no-op). Document actual behavior.
- **Notes:** —

#### Scenario 4: Edge case — empty string action name
- **Description:** Call with an empty string for `action`.
- **Params:** `{ "action": "" }`
- **Expected Result:** Error — empty string is not a valid action name.
- **Notes:** —

#### Scenario 5: Edge case — remove all actions sequentially
- **Description:** Retrieve the input map, then remove each action one by one.
- **Setup:** Get current actions via `get_input_map`. Iterate and call `remove_input_action` for each.
- **Params:** One call per action name.
- **Expected Result:** All actions removed successfully. Final `get_input_map` returns `{}`.
- **Notes:** After testing, restore built-in actions.

#### Scenario 6: Edge case — missing required parameter
- **Description:** Call without the `action` parameter.
- **Params:** `{}`
- **Expected Result:** Zod validation error: `action` is required.
- **Notes:** —

#### Scenario 7: Edge case — `action` not a string
- **Description:** Call with a non-string value for `action`.
- **Params:** `{ "action": false }`
- **Expected Result:** Zod validation error — expected string, received boolean.
- **Notes:** —

---

## Tool: `get_autoloads`

**Description:** Get all autoload singletons configured in the project.  
**Handler:** `callGodot(bridge, 'project_config/get_autoloads')`

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| *(none)*  | —    | —        | No parameters. |

### Test Scenarios

#### Scenario 1: Happy path — default project autoloads
- **Description:** Retrieve autoloads from a default project with the MCP plugin active.
- **Params:** `{}`
- **Expected Result:** JSON object listing all autoloads with their names, paths, and enabled status. Should include `mcp_runtime` (the MCP runtime autoload).
- **Notes:** Every project with the MCP plugin active has at least `mcp_runtime`.

#### Scenario 2: Happy path — after adding a custom autoload
- **Description:** Add a custom autoload via `add_autoload_config`, then retrieve autoloads.
- **Setup:** Call `add_autoload_config` with a custom autoload.
- **Params:** `{}`
- **Expected Result:** JSON object that now includes the custom autoload alongside existing ones.
- **Notes:** —

#### Scenario 3: Edge case — project with no autoloads
- **Description:** Remove all autoloads, then call `get_autoloads`.
- **Setup:** Call `remove_autoload_config` for every existing autoload.
- **Params:** `{}`
- **Expected Result:** Empty JSON object `{}` (or empty array). Should not error.
- **Notes:** After testing, restore the MCP runtime autoload.

#### Scenario 4: Edge case — call with extraneous parameters
- **Description:** Call with an unexpected parameter.
- **Params:** `{ "extra": "ignored" }`
- **Expected Result:** Should succeed — extraneous parameters should be silently ignored.
- **Notes:** —

---

## Tool: `add_autoload_config`

**Description:** Add an autoload singleton to the project.  
**Handler:** `callGodot(bridge, 'project_config/add_autoload_config', args)`

### Parameters

| Parameter | Type    | Required | Description                                | Default |
|-----------|---------|----------|--------------------------------------------|---------|
| `name`    | string  | ✅ Yes   | Autoload singleton name                    | —       |
| `path`    | string  | ✅ Yes   | Script or scene path (e.g. `"res://autoload/global.gd"`) | —       |
| `enabled` | boolean | ❌ No    | Whether the autoload is enabled            | `true`  |

### Test Scenarios

#### Scenario 1: Happy path — add enabled autoload (default)
- **Description:** Add an autoload with default `enabled: true`.
- **Params:**
  ```json
  {
    "name": "MyGlobal",
    "path": "res://scripts/my_global.gd"
  }
  ```
- **Expected Result:** Success — autoload `MyGlobal` added and enabled. `get_autoloads` should show it with `enabled: true`.
- **Notes:** The script at the given path must exist.

#### Scenario 2: Happy path — add disabled autoload
- **Description:** Add an autoload explicitly disabled.
- **Params:**
  ```json
  {
    "name": "DisabledGlobal",
    "path": "res://scripts/my_global.gd",
    "enabled": false
  }
  ```
- **Expected Result:** Success — autoload added but disabled. `get_autoloads` should show it with `enabled: false`.
- **Notes:** —

#### Scenario 3: Happy path — add autoload with scene path
- **Description:** Add an autoload that points to a scene file.
- **Params:**
  ```json
  {
    "name": "SceneGlobal",
    "path": "res://scenes/my_autoload_scene.tscn",
    "enabled": true
  }
  ```
- **Expected Result:** Success — scene-based autoload added.
- **Notes:** Autoloads can be either scripts (`.gd`) or scenes (`.tscn`).

#### Scenario 4: Edge case — duplicate name (already exists)
- **Description:** Try to add an autoload with a name that already exists.
- **Setup:** `"mcp_runtime"` already exists.
- **Params:**
  ```json
  {
    "name": "mcp_runtime",
    "path": "res://scripts/another.gd"
  }
  ```
- **Expected Result:** Error — autoload with this name already exists. Or may overwrite the existing one. Document actual behavior.
- **Notes:** —

#### Scenario 5: Edge case — path does not exist
- **Description:** Add an autoload pointing to a non-existent file.
- **Params:**
  ```json
  {
    "name": "MissingFile",
    "path": "res://does/not/exist.gd"
  }
  ```
- **Expected Result:** Error — file not found at the given path.
- **Notes:** The Godot plugin should validate that the file exists.

#### Scenario 6: Edge case — empty name
- **Description:** Call with an empty string for `name`.
- **Params:**
  ```json
  {
    "name": "",
    "path": "res://scripts/test.gd"
  }
  ```
- **Expected Result:** Error — empty string is not a valid autoload name.
- **Notes:** —

#### Scenario 7: Edge case — empty path
- **Description:** Call with an empty string for `path`.
- **Params:**
  ```json
  {
    "name": "EmptyPath",
    "path": ""
  }
  ```
- **Expected Result:** Error — empty path is invalid.
- **Notes:** —

#### Scenario 8: Edge case — missing `name` parameter
- **Description:** Call without the `name` parameter.
- **Params:** `{ "path": "res://scripts/test.gd" }`
- **Expected Result:** Zod validation error: `name` is required.
- **Notes:** —

#### Scenario 9: Edge case — missing `path` parameter
- **Description:** Call without the `path` parameter.
- **Params:** `{ "name": "MissingPath" }`
- **Expected Result:** Zod validation error: `path` is required.
- **Notes:** —

#### Scenario 10: Edge case — `enabled` is not a boolean
- **Description:** Call with a string for `enabled`.
- **Params:**
  ```json
  {
    "name": "BadEnabled",
    "path": "res://scripts/test.gd",
    "enabled": "yes"
  }
  ```
- **Expected Result:** Zod validation error — expected boolean, received string.
- **Notes:** —

#### Scenario 11: Edge case — path relative (not res://)
- **Description:** Call with a path that does not use the `res://` prefix.
- **Params:**
  ```json
  {
    "name": "RelativePath",
    "path": "scripts/test.gd"
  }
  ```
- **Expected Result:** May error or be resolved relative to the project root. Document actual behavior.
- **Notes:** The `FilePath` schema does not enforce `res://` prefix, but Godot may require it.

#### Scenario 12: Edge case — path with absolute filesystem path
- **Description:** Call with an absolute OS path instead of a `res://` path.
- **Params:**
  ```json
  {
    "name": "AbsolutePath",
    "path": "C:\\Users\\test\\file.gd"
  }
  ```
- **Expected Result:** Error — Godot expects `res://` paths for project resources.
- **Notes:** —

---

## Tool: `remove_autoload_config`

**Description:** Remove an autoload singleton from the project.  
**Handler:** `callGodot(bridge, 'project_config/remove_autoload_config', args)`

### Parameters

| Parameter | Type   | Required | Description                                |
|-----------|--------|----------|--------------------------------------------|
| `name`    | string | ✅ Yes   | Autoload singleton name to remove          |

### Test Scenarios

#### Scenario 1: Happy path — remove a custom autoload
- **Description:** Add a custom autoload, then remove it.
- **Setup:** Call `add_autoload_config` to add `"TempAutoload"`.
- **Params:** `{ "name": "TempAutoload" }`
- **Expected Result:** Success — autoload removed. `get_autoloads` should no longer include `"TempAutoload"`.
- **Notes:** —

#### Scenario 2: Edge case — remove non-existent autoload
- **Description:** Try to remove an autoload that does not exist.
- **Params:** `{ "name": "DoesNotExist_12345" }`
- **Expected Result:** Error — autoload not found.
- **Notes:** —

#### Scenario 3: Edge case — remove MCP runtime autoload
- **Description:** Attempt to remove the `mcp_runtime` autoload.
- **Params:** `{ "name": "mcp_runtime" }`
- **Expected Result:** May succeed but will break runtime MCP functionality. Document what happens.
- **Notes:** After testing, re-add `mcp_runtime` to restore MCP functionality.

#### Scenario 4: Edge case — empty string name
- **Description:** Call with an empty string for `name`.
- **Params:** `{ "name": "" }`
- **Expected Result:** Error — empty string is not a valid autoload name.
- **Notes:** —

#### Scenario 5: Edge case — missing required parameter
- **Description:** Call without the `name` parameter.
- **Params:** `{}`
- **Expected Result:** Zod validation error: `name` is required.
- **Notes:** —

#### Scenario 6: Edge case — `name` not a string
- **Description:** Call with a non-string value for `name`.
- **Params:** `{ "name": null }`
- **Expected Result:** Zod validation error — expected string, received null.
- **Notes:** —

---

## Tool: `reorder_autoloads`

**Description:** Set the loading order of autoload singletons.  
**Handler:** `callGodot(bridge, 'project_config/reorder_autoloads', args)`

### Parameters

| Parameter | Type           | Required | Description                                |
|-----------|----------------|----------|--------------------------------------------|
| `order`   | `Array<string>` | ✅ Yes   | Ordered list of autoload names (first loads first) |

### Test Scenarios

#### Scenario 1: Happy path — reorder existing autoloads
- **Description:** Reorder the autoloads to a specific sequence.
- **Setup:** Get current autoloads via `get_autoloads`. Suppose the current order is `["A", "B", "C"]`.
- **Params:** `{ "order": ["C", "A", "B"] }`
- **Expected Result:** Success — autoloads reordered. `get_autoloads` should list autoloads in the new order: `"C"`, then `"A"`, then `"B"`.
- **Notes:** —

#### Scenario 2: Happy path — reorder with same order (no-op)
- **Description:** Pass the current order unchanged.
- **Setup:** Get current autoload order.
- **Params:** `{ "order": ["mcp_runtime"] }` (if only one autoload exists).
- **Expected Result:** Success — no change (idempotent).
- **Notes:** Should not error even though nothing changes.

#### Scenario 3: Edge case — empty order array
- **Description:** Call with an empty order array.
- **Params:** `{ "order": [] }`
- **Expected Result:** May succeed (clears all autoloads) or error. Document actual behavior.
- **Notes:** An empty order list is ambiguous — it could mean "no autoloads" or be rejected.

#### Scenario 4: Edge case — order includes a non-existent autoload
- **Description:** Include an autoload name that does not exist.
- **Params:** `{ "order": ["mcp_runtime", "FakeAutoload_XYZ"] }`
- **Expected Result:** Error — autoload `"FakeAutoload_XYZ"` not found.
- **Notes:** —

#### Scenario 5: Edge case — order is missing an existing autoload
- **Description:** Provide an order list that omits one of the existing autoloads.
- **Setup:** Suppose the project has autoloads `["mcp_runtime", "Global"]`.
- **Params:** `{ "order": ["mcp_runtime"] }`
- **Expected Result:** May error (incomplete list) or may auto-append the missing one. Or the missing autoload may be removed. Document actual behavior.
- **Notes:** The tool description says "Set the loading order" — unclear if it replaces the entire set or just reorders.

#### Scenario 6: Edge case — duplicate autoload names in order
- **Description:** Include the same autoload name twice in the order.
- **Params:** `{ "order": ["mcp_runtime", "mcp_runtime"] }`
- **Expected Result:** Error — duplicate names in the order list.
- **Notes:** —

#### Scenario 7: Edge case — missing required parameter
- **Description:** Call without the `order` parameter.
- **Params:** `{}`
- **Expected Result:** Zod validation error: `order` is required.
- **Notes:** —

#### Scenario 8: Edge case — `order` is not an array
- **Description:** Call with a string for `order` instead of an array.
- **Params:** `{ "order": "mcp_runtime" }`
- **Expected Result:** Zod validation error — expected array, received string.
- **Notes:** —

#### Scenario 9: Edge case — `order` contains non-string elements
- **Description:** Include a non-string element in the order array.
- **Params:** `{ "order": ["mcp_runtime", 12345] }`
- **Expected Result:** Zod validation error — expected string at index 1, received number.
- **Notes:** `z.array(z.string())` enforces string-only arrays.

#### Scenario 10: Edge case — empty string in order
- **Description:** Include an empty string in the order array.
- **Params:** `{ "order": ["mcp_runtime", ""] }`
- **Expected Result:** Error — empty string is not a valid autoload name.
- **Notes:** Zod accepts empty strings; the Godot plugin should reject.

---

## Cross-Tool Consistency Checks

These are tests to run across tools to verify consistent behavior.

### Consistency 1: All key-based tools handle missing `key` identically
- **Tools:** `get_project_setting`, `set_project_setting_config` (both `key`), `reset_project_setting`
- **Call each with:** `{}`
- **Expected:** All three return a Zod validation error that `key` is required. Error format should be consistent.

### Consistency 2: Key-based tools handle empty string key identically
- **Tools:** `get_project_setting`, `set_project_setting_config`, `reset_project_setting`
- **Call each with:** `{ "key": "" }`
- **Expected:** All three reject the empty key with a consistent error. The Godot plugin should handle this gracefully.

### Consistency 3: `set_project_setting_config` + `get_project_setting` round-trip
- **Tools:** `set_project_setting_config`, `get_project_setting`
- **Test:** Set a value via `set_project_setting_config`, immediately read it via `get_project_setting`.
- **Expected:** The read returns exactly the value that was set. No data loss or type coercion.
- **Types to test:** string, number (integer), number (float), boolean.

### Consistency 4: `set_project_setting_config` + `reset_project_setting` round-trip
- **Tools:** `set_project_setting_config`, `reset_project_setting`, `get_project_setting`
- **Setup:** Read original value via `get_project_setting`. Set to a different value. Reset. Read again.
- **Expected:** The final value matches the original value. Reset restores the default.

### Consistency 5: `get_all_project_settings` with filter contains superset of `get_project_setting` for same key
- **Tools:** `get_project_setting`, `get_all_project_settings`
- **Test:** Call `get_project_setting` with `"display/window/size/viewport_width"`. Call `get_all_project_settings` with `"display/window/size/"`. Extract `viewport_width` from the all-settings result.
- **Expected:** Both values are identical.

### Consistency 6: Input map add → get → remove → get cycle
- **Tools:** `add_input_action`, `get_input_map`, `remove_input_action`
- **Test:** Add an action. Get the map (should include it). Remove it. Get the map (should NOT include it).
- **Expected:** The action appears after add and disappears after remove.

### Consistency 7: `set_input_map` fully replaces `add_input_action` result
- **Tools:** `add_input_action`, `get_input_map`, `set_input_map`
- **Test:** Add an action via `add_input_action`. Call `set_input_map` with a different set. Call `get_input_map`.
- **Expected:** The final input map contains ONLY the actions from `set_input_map`. The action added via `add_input_action` is gone.

### Consistency 8: Autoload add → get → remove → get cycle
- **Tools:** `add_autoload_config`, `get_autoloads`, `remove_autoload_config`
- **Test:** Add an autoload. Get autoloads (should include it). Remove it. Get autoloads (should NOT include it).
- **Expected:** The autoload appears after add and disappears after remove.

### Consistency 9: Autoload add → reorder → get order reflects reorder
- **Tools:** `add_autoload_config`, `reorder_autoloads`, `get_autoloads`
- **Setup:** Project has `["mcp_runtime"]`. Add `"GlobalA"`. Current order: `["mcp_runtime", "GlobalA"]`.
- **Test:** Call `reorder_autoloads` with `["GlobalA", "mcp_runtime"]`. Call `get_autoloads`.
- **Expected:** The autoloads are listed in the new order: `"GlobalA"` first, `"mcp_runtime"` second.

### Consistency 10: All 12 tools work without crashing on valid inputs
- **Tools:** All 12 tools in this module.
- **Test:** Call each tool with a minimal valid set of parameters.
- **Expected:** Every tool returns a response (success or meaningful error). No tool crashes, hangs, or returns an unhandled exception.

---

## Summary Matrix

| Tool                       | Required Params            | Optional Params           | Godot Bridge Method                  |
|----------------------------|----------------------------|---------------------------|--------------------------------------|
| `get_project_setting`      | `key` (string)             | —                         | `project_config/get_setting`         |
| `set_project_setting_config` | `key` (string), `value` (unknown) | —                   | `project_config/set_setting_config`  |
| `get_all_project_settings` | —                          | `filter` (string)         | `project_config/get_all_settings`    |
| `reset_project_setting`    | `key` (string)             | —                         | `project_config/reset_setting`       |
| `get_input_map`            | —                          | —                         | `project_config/get_input_map`       |
| `set_input_map`            | `actions` (record)         | —                         | `project_config/set_input_map`       |
| `add_input_action`         | `action` (string), `events` (array) | `deadzone` (number, 0–1, default 0.5) | `project_config/add_input_action` |
| `remove_input_action`      | `action` (string)          | —                         | `project_config/remove_input_action` |
| `get_autoloads`            | —                          | —                         | `project_config/get_autoloads`       |
| `add_autoload_config`      | `name` (string), `path` (string) | `enabled` (boolean, default true) | `project_config/add_autoload_config` |
| `remove_autoload_config`   | `name` (string)            | —                         | `project_config/remove_autoload_config` |
| `reorder_autoloads`        | `order` (string[])         | —                         | `project_config/reorder_autoloads`   |
