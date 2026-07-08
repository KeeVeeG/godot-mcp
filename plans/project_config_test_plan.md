# Project Configuration Tools Test Plan

**Source**: `server/src/tools/project_config.ts`  
**Total tools**: 12  
**Godot handler**: `addons/godot_mcp/commands/project_config_commands.gd`  
**Test plan generated**: 2026-07-08

---

## Overview

The `project_config.ts` file registers **12 MCP tools** across 3 sub-domains:

| # | Sub-domain | Tools |
|---|-----------|-------|
| 1–4 | Project Settings | `get_project_setting`, `set_project_setting_config`, `get_all_project_settings`, `reset_project_setting` |
| 5–8 | Input Map | `get_input_map`, `set_input_map`, `add_input_action`, `remove_input_action` |
| 9–12 | Autoloads | `get_autoloads`, `add_autoload_config`, `remove_autoload_config`, `reorder_autoloads` |

All tools call `callGodot(bridge, 'project_config/<method>', args)` which forwards via WebSocket to the Godot editor plugin.

### Tool-to-Method mapping

| MCP Tool Name | Godot RPC Method | Required Params |
|---|---|---|
| `get_project_setting` | `project_config/get_setting` | `key` |
| `set_project_setting_config` | `project_config/set_setting_config` | `key`, `value` |
| `get_all_project_settings` | `project_config/get_all_settings` | *(none)* |
| `reset_project_setting` | `project_config/reset_setting` | `key` |
| `get_input_map` | `project_config/get_input_map` | *(none)* |
| `set_input_map` | `project_config/set_input_map` | `actions` |
| `add_input_action` | `project_config/add_input_action` | `action`, `events` |
| `remove_input_action` | `project_config/remove_input_action` | `action` |
| `get_autoloads` | `project_config/get_autoloads` | *(none)* |
| `add_autoload_config` | `project_config/add_autoload_config` | `name`, `path` |
| `remove_autoload_config` | `project_config/remove_autoload_config` | `name` |
| `reorder_autoloads` | `project_config/reorder_autoloads` | `order` |

### Shared types used

| Type | Zod Schema | Usage |
|---|---|---|
| `Name` | `z.string().describe('Name identifier')` | Autoload name fields |
| `FilePath` | `z.string().describe("File path (e.g. 'res://path/to/file')")` | Autoload path field |
| `PropertyValue` | `z.unknown().describe('Property value')` | Project setting value |

### Tool dependency chains

Tools within each sub-domain form natural sequences. Test scenarios that exercise these chains use numbered steps to indicate the expected order:

**Input Map chain**: `get_input_map` → `add_input_action` → `get_input_map` (verify added) → `remove_input_action` → `get_input_map` (verify removed) → `set_input_map` (restore)

**Autoload chain**: `get_autoloads` → `add_autoload_config` → `get_autoloads` (verify added) → `reorder_autoloads` → `get_autoloads` (verify order) → `remove_autoload_config` → `get_autoloads` (verify removed)

**Project Settings chain**: `get_project_setting` → `set_project_setting_config` → `get_project_setting` (verify changed) → `reset_project_setting` → `get_project_setting` (verify default restored) → `get_all_project_settings` (broad read)

---

## Table of Contents

1. [Tool: get_project_setting](#tool-get_project_setting)
2. [Tool: set_project_setting_config](#tool-set_project_setting_config)
3. [Tool: get_all_project_settings](#tool-get_all_project_settings)
4. [Tool: reset_project_setting](#tool-reset_project_setting)
5. [Tool: get_input_map](#tool-get_input_map)
6. [Tool: set_input_map](#tool-set_input_map)
7. [Tool: add_input_action](#tool-add_input_action)
8. [Tool: remove_input_action](#tool-remove_input_action)
9. [Tool: get_autoloads](#tool-get_autoloads)
10. [Tool: add_autoload_config](#tool-add_autoload_config)
11. [Tool: remove_autoload_config](#tool-remove_autoload_config)
12. [Tool: reorder_autoloads](#tool-reorder_autoloads)
13. [End-to-End Integration Sequences](#end-to-end-integration-sequences)

---

## Tool: get_project_setting

**Tool name**: `get_project_setting`  
**Description**: Get a single project setting value by key (e.g. 'display/window/size/viewport_width')  
**Backend method**: `project_config/get_setting`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `key` | `string` | **Yes** | — | Project setting key path (e.g. `'display/window/size/viewport_width'`) |

### Test Scenarios

#### Scenario 1: Happy path — read a known string setting

**Description**: Read the application name from project settings.  
**Params**:
```json
{
  "key": "application/config/name"
}
```
**Expected result**: Returns the project name as stored in `project.godot`. For a default project this is typically the project folder name. Response has `content[0].text` containing the value (string or JSON).  
**Note**: The value should be a string matching `Project → Project Settings → Application → Config → Name`. If the project has no custom name, the folder name will be returned — this is normal.

#### Scenario 2: Happy path — read a numeric setting

**Description**: Read the viewport width.  
**Params**:
```json
{
  "key": "display/window/size/viewport_width"
}
```
**Expected result**: Returns a numeric value (default: 1152 for Godot 4.x).  
**Note**: Verify that the value is a number (not a string). Typical values: 1152, 1920, 1280.

#### Scenario 3: Happy path — read a boolean setting

**Description**: Read whether the window is resizable.  
**Params**:
```json
{
  "key": "display/window/size/resizable"
}
```
**Expected result**: Returns `true` (default).  
**Note**: Verify that the value is a boolean, not the string `"true"`.

#### Scenario 4: Happy path — read a Vector2/array setting

**Description**: Read a setting that returns an array/object type.  
**Params**:
```json
{
  "key": "display/window/size/window_width_override"
}
```
**Expected result**: Returns a numeric value (0 = auto, or specific override width).  
**Note**: If the setting is not overridden, it may return 0 or null — this is acceptable. Verify there is no error.

#### Scenario 5: Edge case — non-existent key

**Description**: Query a setting key that does not exist.  
**Params**:
```json
{
  "key": "this/setting/does/not/exist"
}
```
**Expected result**: Either an error response (`isError: true`) from Godot, or an empty/null value. Should not crash the server.  
**Note**: Verify that the response does not cause a panic on the server side. If Godot returns an error — it should be properly wrapped in `isError: true`.

#### Scenario 6: Edge case — missing required `key`

**Description**: Omit the required `key` parameter entirely.  
**Params**:
```json
{}
```
**Expected result**: MCP SDK Zod validation error — `key` is required. Response should indicate missing required field.  
**Note**: The error should be at the MCP validation level, before sending to Godot. Verify that the message mentions the `key` parameter.

#### Scenario 7: Edge case — empty key string

**Description**: Pass an empty string as the key.  
**Params**:
```json
{
  "key": ""
}
```
**Expected result**: Either a Godot-side error (invalid key) or an empty result. Should not crash.  
**Note**: An empty string is not a valid setting path. An error is expected — ensure this is handled without crashing the server.

#### Scenario 8: Edge case — key with trailing slash

**Description**: Pass a key path with a trailing slash.  
**Params**:
```json
{
  "key": "display/window/size/"
}
```
**Expected result**: Likely returns an error or empty result — this is a section path, not a specific setting.  
**Note**: Verify that the server does not crash and returns a meaningful response (error or empty result).

---

## Tool: set_project_setting_config

**Tool name**: `set_project_setting_config`  
**Description**: Set a project setting value and save project.godot  
**Backend method**: `project_config/set_setting_config`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `key` | `string` | **Yes** | — | Project setting key path |
| `value` | `PropertyValue` (`z.unknown()`) | **Yes** | — | New value for the setting |

### Test Scenarios

#### Scenario 1: Happy path — set a string value

**Description**: Change the application name to a test value, then verify with `get_project_setting`.  
**Prerequisite tools**: `get_project_setting` (for verification before and after).  
**Params**:
```json
{
  "key": "application/config/name",
  "value": "Test Project MCP"
}
```
**Expected result**: Returns success. Follow-up call to `get_project_setting` with `{"key": "application/config/name"}` should return `"Test Project MCP"`.  
**Notes**: **Restore original value after test.** Save original value before this test using `get_project_setting`, then restore it using this tool at the end.  
**Note**: Verify that `project.godot` was actually updated on disk (check the file contents). Ensure that `isError !== true`.

#### Scenario 2: Happy path — set a numeric value

**Description**: Change the viewport width override.  
**Prerequisite tools**: `get_project_setting` (verify before and after).  
**Params**:
```json
{
  "key": "display/window/size/window_width_override",
  "value": 800
}
```
**Expected result**: Returns success. Follow-up `get_project_setting` should return `800`.  
**Notes**: **Restore original value after test** (likely `0` for auto).  
**Note**: Verify that the numeric value is transmitted as a number, not as the string `"800"`.

#### Scenario 3: Happy path — set a boolean value

**Description**: Change window resizable flag.  
**Prerequisite tools**: `get_project_setting` (verify before and after).  
**Params**:
```json
{
  "key": "display/window/size/resizable",
  "value": false
}
```
**Expected result**: Returns success. Follow-up `get_project_setting` should return `false`.  
**Notes**: **Restore original value after test** (likely `true`).  
**Note**: Verify that the boolean value is transmitted as `false` (not the string `"false"`).

#### Scenario 4: Edge case — invalid key

**Description**: Try setting a non-existent setting key.  
**Params**:
```json
{
  "key": "this/setting/does/not/exist",
  "value": "garbage"
}
```
**Expected result**: Godot should return an error — the key does not exist in the project settings registry.  
**Note**: Ensure that the error is handled and `isError` = `true` in the response. The server should not crash.

#### Scenario 5: Edge case — type mismatch (string where number expected)

**Description**: Pass a string value to a setting that expects a number.  
**Params**:
```json
{
  "key": "display/window/size/viewport_width",
  "value": "not_a_number"
}
```
**Expected result**: Either Zod rejects (since z.unknown() accepts everything), or Godot rejects the type mismatch. Check which layer catches this.  
**Note**: The Zod schema uses `z.unknown()` — type validation happens on the Godot side. If Godot silently ignores an incorrect type, that is a bug. An error is expected.

#### Scenario 6: Edge case — missing `key`

**Description**: Omit the required `key` parameter.  
**Params**:
```json
{
  "value": "some_value"
}
```
**Expected result**: MCP SDK validation error — `key` is required.  
**Note**: The error should occur before sending to Godot.

#### Scenario 7: Edge case — missing `value`

**Description**: Omit the required `value` parameter.  
**Params**:
```json
{
  "key": "application/config/name"
}
```
**Expected result**: MCP SDK validation error — `value` is required.  
**Note**: The error should occur before sending to Godot.

#### Scenario 8: Edge case — null value

**Description**: Set a project setting to `null`.  
**Params**:
```json
{
  "key": "application/config/name",
  "value": null
}
```
**Expected result**: Either Godot rejects null, or it sets the value to null (likely error).  
**Note**: Check Godot's behavior with a null value. Most likely it will return an error.

---

## Tool: get_all_project_settings

**Tool name**: `get_all_project_settings`  
**Description**: Get all project settings, optionally filtered by prefix  
**Backend method**: `project_config/get_all_settings`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `filter` | `string` (optional) | No | `undefined` | Prefix filter (e.g. `'display/'`, `'input/'`) |

### Test Scenarios

#### Scenario 1: Happy path — get all settings (no filter)

**Description**: Retrieve all project settings at once.  
**Params**:
```json
{}
```
**Expected result**: Returns a large JSON object (or array of objects) containing all project settings. Should include sections like `application/`, `display/`, `input/`, `rendering/`, `physics/`, etc.  
**Note**: The response may be large — verify that it is not truncated. Main sections (`application/config/name`, `display/window/size/viewport_width`) should be present.

#### Scenario 2: Happy path — filter by `display/` prefix

**Description**: Get only display-related settings.  
**Params**:
```json
{
  "filter": "display/"
}
```
**Expected result**: Returns settings under `display/` prefix only (window size, stretch mode, vsync, etc.). Should NOT include settings from other sections like `application/` or `input/`.  
**Pay attention**: Verify that the result contains no keys starting with `application/`, `input/`, `rendering/`, etc. All keys must start with `display/`.

#### Scenario 3: Happy path — filter by `input/` prefix

**Description**: Get only input-related settings.  
**Params**:
```json
{
  "filter": "input/"
}
```
**Expected result**: Returns settings under `input/` prefix only. Should include `input/ui_accept`, `input/ui_cancel`, etc.  
**Pay attention**: Verify that InputMap settings (actions) are present. Verify that there are no settings from other sections.

#### Scenario 4: Happy path — filter by `application/config/` prefix

**Description**: Get only application config settings.  
**Params**:
```json
{
  "filter": "application/config/"
}
```
**Expected result**: Returns settings including `application/config/name`, `application/config/description`, `application/config/icon`, etc.  
**Pay attention**: Verify that `application/config/name` is present in the result.

#### Scenario 5: Edge case — filter with non-existent prefix

**Description**: Filter by a prefix that matches no settings.  
**Params**:
```json
{
  "filter": "nonexistent_section/"
}
```
**Expected result**: Returns an empty result (empty object `{}` or empty array `[]`), not an error.  
**Pay attention**: No matches is not an error. The response should be empty, but `isError !== true`.

#### Scenario 6: Edge case — filter without trailing slash

**Description**: Filter by `"display"` without trailing slash — may match `display/` or may not match at all depending on prefix-matching logic.  
**Params**:
```json
{
  "filter": "display"
}
```
**Expected result**: Depends on implementation. If Godot does prefix matching, `"display"` should match `"display/"` and `"display_name"`. If exact prefix matching, it may only match `"display"` (no results).  
**Pay attention**: Document the actual behavior — prefix matching or exact substring matching.

#### Scenario 7: Edge case — empty string filter

**Description**: Pass an empty string as filter.  
**Params**:
```json
{
  "filter": ""
}
```
**Expected result**: Likely returns ALL settings (matching everything), same as no filter.  
**Pay attention**: Verify that the behavior is identical to calling without the `filter` parameter.

---

## Tool: reset_project_setting

**Tool name**: `reset_project_setting`  
**Description**: Reset a project setting to its default value  
**Backend method**: `project_config/reset_setting`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `key` | `string` | **Yes** | — | Project setting key to reset |

### Test Scenarios

#### Scenario 1: Happy path — reset a known setting with a custom value

**Description**: Set a project setting to a non-default value, then reset it, then verify it returns to default.  
**Prerequisite sequence**:
1. `get_project_setting` → `{"key": "application/config/name"}` — save original
2. `set_project_setting_config` → `{"key": "application/config/name", "value": "TempResetTest"}` — change
3. `get_project_setting` → `{"key": "application/config/name"}` — verify changed to `"TempResetTest"`
4. `reset_project_setting` → `{"key": "application/config/name"}` — reset
5. `get_project_setting` → `{"key": "application/config/name"}` — verify **not** `"TempResetTest"` anymore

**Params** (step 4):
```json
{
  "key": "application/config/name"
}
```
**Expected result**: Returns success. After reset, the setting should return to the project folder name (Godot's default).  
**Notes**: This is a destructive test — it removes the custom value from `project.godot`. The test must restore the original value after verification.  
**Pay attention**: Verify that after reset `project.godot` does NOT contain this setting (or contains the default value). Ensure that the revert to default occurred.

#### Scenario 2: Happy path — reset a numeric setting

**Description**: Reset a numeric setting back to its default.  
**Prerequisite sequence**:
1. `set_project_setting_config` → `{"key": "display/window/size/window_width_override", "value": 9999}`
2. `get_project_setting` → `{"key": "display/window/size/window_width_override"}` — verify `9999`
3. `reset_project_setting` → `{"key": "display/window/size/window_width_override"}`
4. `get_project_setting` → `{"key": "display/window/size/window_width_override"}` — verify `0` (default)

**Params** (step 3):
```json
{
  "key": "display/window/size/window_width_override"
}
```
**Expected result**: Returns success. Setting reverts to `0` (auto).  
**Pay attention**: Ensure that the default value for this setting is 0.

#### Scenario 3: Edge case — reset a non-existent key

**Description**: Try resetting a key that doesn't exist in project settings.  
**Params**:
```json
{
  "key": "this/setting/does/not/exist"
}
```
**Expected result**: Either an error (`isError: true`) or a no-op success. Godot may simply return success since there's nothing to reset.  
**Pay attention**: Document the actual behavior — error or success. If success — ensure it did not change other settings.

#### Scenario 4: Edge case — reset a default (unchanged) setting

**Description**: Reset a setting that already has its default value (was never changed).  
**Params**:
```json
{
  "key": "application/config/description"
}
```
*(assuming this was never changed from default)*  
**Expected result**: Returns success (no-op). Should not produce an error.  
**Pay attention**: Verify that `project.godot` did not change — no extra entry should appear.

#### Scenario 5: Edge case — missing required `key`

**Description**: Omit the required `key` parameter.  
**Params**:
```json
{}
```
**Expected result**: MCP SDK validation error — `key` is required.  
**Pay attention**: Validation error before sending to Godot.

---

## Tool: get_input_map

**Tool name**: `get_input_map`  
**Description**: Get all input actions and their mapped events from the InputMap  
**Backend method**: `project_config/get_input_map`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| *(none)* | — | — | — | Tool takes no parameters |

### Test Scenarios

#### Scenario 1: Happy path — get input map

**Description**: Retrieve the full input map with all actions and their events.  
**Params**:
```json
{}
```
**Expected result**: Returns an object/dictionary where keys are action names (e.g. `"ui_accept"`, `"ui_cancel"`, `"ui_up"`, `"ui_down"`, `"move_left"`, `"move_right"`, `"jump"`) and values are arrays of input event objects. Each event has at least a `type` field (e.g. `"key"`, `"mouse_button"`, `"joypad_button"`). Default Godot actions include `ui_accept`, `ui_cancel`, `ui_up`, `ui_down`, `ui_left`, `ui_right`, `ui_select`, `ui_focus_next`, `ui_focus_prev`.  
**Pay attention**: Verify that the returned structure is an object (not an array). Each action must have an array of events. Check for standard Godot actions. Ensure that `content[0].text` is valid JSON.

#### Scenario 2: Happy path — verify event structure

**Description**: Check that each event in the input map has the expected fields.  
**Params**:
```json
{}
```
**Expected result**: For keyboard events (`"type": "key"`), expect fields like `keycode` (int), `physical_keycode` (int), `pressed` (bool), `echo` (bool). For mouse events (`"type": "mouse_button"`), expect `button_index` (int), `pressed` (bool), `double_click` (bool). For joypad events (`"type": "joypad_button"`), expect `button_index` (int), `pressed` (bool).  
**Pay attention**: Check at least one event of each type for key fields. The structure must match Godot InputEvent.

#### Scenario 3: Happy path — verify with empty params object

**Description**: Call with an explicit empty params object (should behave identically to no params).  
**Params**:
```json
{}
```
**Expected result**: Same as Scenario 1.  
**Pay attention**: Verify that an explicit `{}` and absence of parameters behave identically.

---

## Tool: set_input_map

**Tool name**: `set_input_map`  
**Description**: Replace the entire input map with the given actions and events  
**Backend method**: `project_config/set_input_map`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `actions` | `Record<string, {type: string, ...}[]>` | **Yes** | — | Map of action name → array of input events. Each event has `type` field (key, mouse_button, joypad_button, etc.) |

### Test Scenarios

#### Scenario 1: Happy path — replace with known-good input map

**Description**: Get current input map, then set it back with a small modification.  
**Prerequisite tools**: `get_input_map` (before and after).  
**Sequence**:
1. `get_input_map` → save the full map as `original_map`
2. `set_input_map` with a modified copy of `original_map`
3. `get_input_map` → verify the change took effect

**Params** (step 2 — example; use actual saved map):
```json
{
  "actions": {
    "ui_accept": [
      { "type": "key", "keycode": 32, "physical_keycode": 32, "pressed": true }
    ],
    "ui_cancel": [
      { "type": "key", "keycode": 4194305, "physical_keycode": 4194305, "pressed": true }
    ],
    "test_mcp_action": [
      { "type": "key", "keycode": 84, "physical_keycode": 84, "pressed": true }
    ]
  }
}
```
**Expected result**: Returns success. Follow-up `get_input_map` should show exactly the 3 actions with their events.  
**Notes**: **RESTORE the original map after test using `set_input_map` with `original_map`.**  
**Pay attention**: Verify that old actions (not in the new `actions`) are actually deleted. Verify that `content[0].text` contains `success: true`.

#### Scenario 2: Happy path — key event with all standard fields

**Description**: Set an input map with a fully-specified keyboard event (all common fields).  
**Params**:
```json
{
  "actions": {
    "jump": [
      {
        "type": "key",
        "keycode": 32,
        "physical_keycode": 32,
        "key_label": 32,
        "pressed": true,
        "echo": false,
        "ctrl_pressed": false,
        "alt_pressed": false,
        "shift_pressed": false,
        "meta_pressed": false
      }
    ]
  }
}
```
**Expected result**: Returns success. Action `jump` is mapped to spacebar.  
**Notes**: **Remove this action after test using `remove_input_action` or restore the original map.**  
**Pay attention**: Verify that all event fields were preserved (especially modifier flags).

#### Scenario 3: Happy path — mouse button event

**Description**: Set an action mapped to mouse buttons.  
**Params**:
```json
{
  "actions": {
    "shoot": [
      { "type": "mouse_button", "button_index": 1, "pressed": true, "double_click": false }
    ],
    "aim": [
      { "type": "mouse_button", "button_index": 2, "pressed": true, "double_click": false }
    ]
  }
}
```
**Expected result**: Returns success. `shoot` mapped to left mouse (button_index=1), `aim` to right mouse (button_index=2).  
**Notes**: **Restore original map after test.**  
**Pay attention**: Verify that `button_index` 1 = left button, 2 = right, 3 = middle.

#### Scenario 4: Happy path — joypad button event

**Description**: Set an action mapped to a gamepad button.  
**Params**:
```json
{
  "actions": {
    "gamepad_jump": [
      { "type": "joypad_button", "button_index": 0, "pressed": true, "pressure": 1.0 }
    ]
  }
}
```
**Expected result**: Returns success. `gamepad_jump` mapped to joypad button 0 (typically A/Cross).  
**Notes**: **Restore original map after test.**  
**Pay attention**: Verify that `pressure` is preserved (value from 0 to 1).

#### Scenario 5: Happy path — joypad axis/motion event

**Description**: Set an action mapped to an analog stick axis.  
**Params**:
```json
{
  "actions": {
    "move_right": [
      { "type": "joypad_motion", "axis": 0, "axis_value": 1.0 }
    ],
    "move_left": [
      { "type": "joypad_motion", "axis": 0, "axis_value": -1.0 }
    ]
  }
}
```
**Expected result**: Returns success. Axis 0 = left stick horizontal.  
**Notes**: **Restore original map after test.**  
**Pay attention**: Verify that `axis` and `axis_value` are correctly saved. Godot may use `axis_value` or a separate structure.

#### Scenario 6: Edge case — empty actions object

**Description**: Pass an empty actions map — replace input map with nothing.  
**Params**:
```json
{
  "actions": {}
}
```
**Expected result**: Returns success. All input actions should be cleared. Follow-up `get_input_map` should return `{}`.  
**Notes**: **This is destructive — RESTORE original map immediately after test.**  
**Pay attention**: Verify that `get_input_map` after this returns an empty object. It is very important to restore the original map!

#### Scenario 7: Edge case — missing `actions` parameter

**Description**: Omit the required `actions` parameter.  
**Params**:
```json
{}
```
**Expected result**: MCP SDK validation error — `actions` is required.  
**Pay attention**: Validation error.

#### Scenario 8: Edge case — event without `type` field

**Description**: Pass an event object that lacks the required `type` field.  
**Params**:
```json
{
  "actions": {
    "bad_action": [
      { "keycode": 32, "pressed": true }
    ]
  }
}
```
**Expected result**: Godot should reject this — every InputEvent needs a `type`. Expect an error from Godot.  
**Pay attention**: Verify that the error is informative and does not cause a server crash.

#### Scenario 9: Edge case — actions as array instead of object

**Description**: Pass an array instead of a record/object for `actions`.  
**Params**:
```json
{
  "actions": []
}
```
**Expected result**: Zod should reject — `z.record(...)` expects an object, not an array. MCP SDK validation error.  
**Pay attention**: Verify that Zod catches the wrong type of `actions`.

---

## Tool: add_input_action

**Tool name**: `add_input_action`  
**Description**: Add a new input action with optional deadzone and event mappings  
**Backend method**: `project_config/add_input_action`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `action` | `string` | **Yes** | — | Action name (e.g. `'jump'`, `'move_left'`) |
| `deadzone` | `number` (0–1) | No | `0.5` | Deadzone value |
| `events` | `Array<{type: string, ...}>` | **Yes** | — | Array of input event definitions |

### Test Scenarios

#### Scenario 1: Happy path — add action with keyboard event

**Description**: Add a new action mapped to the spacebar with default deadzone.  
**Prerequisite tools**: `get_input_map` (verify), `remove_input_action` (cleanup).  
**Params**:
```json
{
  "action": "test_jump_mcp",
  "events": [
    {
      "type": "key",
      "keycode": 32,
      "physical_keycode": 32,
      "pressed": true,
      "echo": false
    }
  ]
}
```
**Expected result**: Returns success. Follow-up `get_input_map` should include `test_jump_mcp` with the spacebar event and default deadzone 0.5.  
**Notes**: **Clean up after test with `remove_input_action({"action": "test_jump_mcp"})`.**  
**Pay attention**: Verify that default deadzone = 0.5 (if the field is returned in `get_input_map`). Verify that the event is correctly saved.

#### Scenario 2: Happy path — add action with custom deadzone

**Description**: Add an action with a specific deadzone value.  
**Params**:
```json
{
  "action": "test_deadzone_mcp",
  "deadzone": 0.2,
  "events": [
    {
      "type": "key",
      "keycode": 65,
      "physical_keycode": 65,
      "pressed": true
    }
  ]
}
```
**Expected result**: Returns success. Deadzone should be 0.2.  
**Notes**: **Clean up after test.**  
**Pay attention**: Verify that deadzone = 0.2, not the default 0.5.

#### Scenario 3: Happy path — add action with multiple events

**Description**: Add an action mapped to both a keyboard key AND a mouse button.  
**Params**:
```json
{
  "action": "test_multi_event_mcp",
  "events": [
    {
      "type": "key",
      "keycode": 70,
      "physical_keycode": 70,
      "pressed": true
    },
    {
      "type": "mouse_button",
      "button_index": 1,
      "pressed": true
    }
  ]
}
```
**Expected result**: Returns success. The action should have 2 events in its array.  
**Notes**: **Clean up after test.**  
**Pay attention**: Verify that both events are present in the action's event array.

#### Scenario 4: Happy path — deadzone edge values

**Description**: Test deadzone at boundary values 0 and 1.  
**Params** (sub-test A — deadzone = 0):
```json
{
  "action": "test_dz_zero_mcp",
  "deadzone": 0,
  "events": [{ "type": "key", "keycode": 81, "physical_keycode": 81, "pressed": true }]
}
```
**Params** (sub-test B — deadzone = 1):
```json
{
  "action": "test_dz_one_mcp",
  "deadzone": 1,
  "events": [{ "type": "key", "keycode": 87, "physical_keycode": 87, "pressed": true }]
}
```
**Expected result**: Both should succeed.  
**Notes**: **Clean up both after test.**  
**Pay attention**: Verify that boundary deadzone values (0 and 1) are accepted without errors.

#### Scenario 5: Edge case — deadzone out of range

**Description**: Pass deadzone values outside the 0–1 range.  
**Params** (sub-test A — negative):
```json
{
  "action": "test_dz_neg_mcp",
  "deadzone": -0.5,
  "events": [{ "type": "key", "keycode": 65, "physical_keycode": 65, "pressed": true }]
}
```
**Params** (sub-test B — > 1):
```json
{
  "action": "test_dz_high_mcp",
  "deadzone": 1.5,
  "events": [{ "type": "key", "keycode": 65, "physical_keycode": 65, "pressed": true }]
}
```
**Expected result**: Zod validation should reject — `.min(0).max(1)` constraints enforced. MCP SDK validation error.  
**Pay attention**: Verify that Zod actually rejects values outside [0, 1]. The error must be at the SDK level.

#### Scenario 6: Edge case — empty events array

**Description**: Add an action with an empty events array.  
**Params**:
```json
{
  "action": "test_empty_events_mcp",
  "events": []
}
```
**Expected result**: Likely succeeds but the action has no bindings (useless but valid). Or Godot may reject empty events array.  
**Notes**: **Clean up after test.**  
**Pay attention**: Document the actual behavior — whether Godot allows actions without events.

#### Scenario 7: Edge case — duplicate action name

**Description**: Try adding an action that already exists.  
**Prerequisite**: First call `add_input_action` to create `test_dup_mcp`, then call again with the same name.  
**Params** (second call):
```json
{
  "action": "test_dup_mcp",
  "events": [
    { "type": "key", "keycode": 66, "physical_keycode": 66, "pressed": true }
  ]
}
```
**Expected result**: Godot should return an error — action already exists.  
**Notes**: **Clean up after test.**  
**Pay attention**: Verify that the error is informative — indicates a duplicate action.

#### Scenario 8: Edge case — missing `action`

**Description**: Omit the required `action` parameter.  
**Params**:
```json
{
  "events": [{ "type": "key", "keycode": 32, "physical_keycode": 32, "pressed": true }]
}
```
**Expected result**: MCP SDK validation error — `action` is required.  
**Pay attention**: Validation error.

#### Scenario 9: Edge case — missing `events`

**Description**: Omit the required `events` parameter.  
**Params**:
```json
{
  "action": "test_no_events_mcp"
}
```
**Expected result**: MCP SDK validation error — `events` is required.  
**Pay attention**: Validation error.

---

## Tool: remove_input_action

**Tool name**: `remove_input_action`  
**Description**: Remove an input action from the InputMap  
**Backend method**: `project_config/remove_input_action`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `action` | `string` | **Yes** | — | Action name to remove |

### Test Scenarios

#### Scenario 1: Happy path — remove an existing action

**Description**: Add a test action, then remove it, then verify it's gone.  
**Prerequisite sequence**:
1. `add_input_action` → `{"action": "test_remove_mcp", "events": [{"type": "key", "keycode": 32, "physical_keycode": 32, "pressed": true}]}` — create
2. `get_input_map` → verify `test_remove_mcp` exists
3. `remove_input_action` → `{"action": "test_remove_mcp"}` — remove
4. `get_input_map` → verify `test_remove_mcp` is gone

**Params** (step 3):
```json
{
  "action": "test_remove_mcp"
}
```
**Expected result**: Returns success. The action should no longer appear in `get_input_map`.  
**Pay attention**: Verify that the action is actually deleted, not just hidden. Call `remove_input_action` again with the same name — check behavior (likely "not found" error).

#### Scenario 2: Happy path — remove a standard Godot action

**Description**: Remove a built-in action like `ui_accept`.  
**Params**:
```json
{
  "action": "ui_accept"
}
```
**Expected result**: Returns success. `ui_accept` is removed from the input map.  
**Notes**: **This is destructive — restore `ui_accept` after test using `add_input_action` with the original events (record them via `get_input_map` before this test).**  
**Pay attention**: Verify that standard actions can be deleted just like user-added ones.

#### Scenario 3: Edge case — remove non-existent action

**Description**: Try removing an action name that doesn't exist.  
**Params**:
```json
{
  "action": "this_action_does_not_exist_12345"
}
```
**Expected result**: Godot should return an error (`isError: true`) — action not found.  
**Pay attention**: Verify that the error is handled without crashing the server. The message should indicate that the action was not found.

#### Scenario 4: Edge case — remove action twice

**Description**: Remove the same action twice in a row.  
**Prerequisite sequence**:
1. `add_input_action` → create `test_double_remove_mcp`
2. `remove_input_action` → `{"action": "test_double_remove_mcp"}` — first remove (success)
3. `remove_input_action` → `{"action": "test_double_remove_mcp"}` — second remove (should fail)

**Expected result**: First call succeeds. Second call returns error — action already removed.  
**Pay attention**: Verify that the second deletion does not cause unexpected side effects.

#### Scenario 5: Edge case — missing `action`

**Description**: Omit the required `action` parameter.  
**Params**:
```json
{}
```
**Expected result**: MCP SDK validation error — `action` is required.  
**Pay attention**: Validation error.

#### Scenario 6: Edge case — empty action string

**Description**: Pass an empty string as action name.  
**Params**:
```json
{
  "action": ""
}
```
**Expected result**: Godot should reject — empty action name is invalid.  
**Pay attention**: Verify that the error is handled correctly.

---

## Tool: get_autoloads

**Tool name**: `get_autoloads`  
**Description**: Get all autoload singletons configured in the project  
**Backend method**: `project_config/get_autoloads`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| *(none)* | — | — | — | Tool takes no parameters |

### Test Scenarios

#### Scenario 1: Happy path — get autoloads list

**Description**: Retrieve all registered autoload singletons.  
**Params**:
```json
{}
```
**Expected result**: Returns an object (or array) of autoloads. Each entry should have at least: `name` (string), `path` (string, e.g. `"res://addons/godot_mcp/services/mcp_runtime.gd"`), and likely `enabled` (boolean). For projects with the MCP plugin active, `mcp_runtime` should be in the list.  
**Pay attention**: Verify that the response contains the expected structure. If the MCP plugin is active — `mcp_runtime` must be present. Verify that paths start with `res://`.

#### Scenario 2: Happy path — verify autoload entry structure

**Description**: Check each autoload entry has the expected fields.  
**Params**:
```json
{}
```
**Expected result**: Each autoload entry should be an object with fields: `name` (string), `path` (string or null for built-in singletons), `singleton` (boolean).  
**Pay attention**: Some singletons (built-in) may not have a `path` field or may have `path: null` — this is acceptable.

---

## Tool: add_autoload_config

**Tool name**: `add_autoload_config`  
**Description**: Add an autoload singleton to the project  
**Backend method**: `project_config/add_autoload_config`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | `Name` (`z.string()`) | **Yes** | — | Autoload singleton name |
| `path` | `FilePath` (`z.string()`) | **Yes** | — | Script or scene path (e.g. `'res://autoload/global.gd'`) |
| `enabled` | `boolean` (optional) | No | `true` | Whether the autoload is enabled |

### Test Scenarios

#### Scenario 1: Happy path — add autoload with default enabled

**Description**: Add a new autoload singleton pointing to an existing GDScript file.  
**Prerequisite**: Ensure `res://addons/godot_mcp/services/mcp_runtime.gd` exists (it does if the MCP plugin is installed). Or use any existing `.gd` file path.  
**Params**:
```json
{
  "name": "TestAutoloadMCP",
  "path": "res://addons/godot_mcp/services/mcp_runtime.gd"
}
```
**Expected result**: Returns success. Follow-up `get_autoloads` should include `TestAutoloadMCP` with path and `enabled: true`.  
**Notes**: **⚠️ DO NOT use `mcp_runtime.gd` as the actual autoload path — this will create a duplicate singleton that may break the MCP plugin. Instead, verify test by checking it appears in `get_autoloads`, then immediately remove it with `remove_autoload_config`.**  
**Pay attention**: Verify that the new autoload appears in `get_autoloads`. Verify that `enabled = true` by default. **Must delete after test!**

#### Scenario 2: Happy path — add autoload with `enabled: false`

**Description**: Add a disabled autoload.  
**Params**:
```json
{
  "name": "TestDisabledMCP",
  "path": "res://addons/godot_mcp/services/mcp_runtime.gd",
  "enabled": false
}
```
**Expected result**: Returns success. `get_autoloads` should show `TestDisabledMCP` with `enabled: false`.  
**Notes**: **Remove after test.**  
**Pay attention**: Verify that `enabled: false` is correctly saved. A disabled autoload is not loaded at game start.

#### Scenario 3: Happy path — add autoload with `enabled` explicitly true

**Description**: Add autoload with explicit `enabled: true`.  
**Params**:
```json
{
  "name": "TestEnabledExplicitMCP",
  "path": "res://addons/godot_mcp/services/mcp_runtime.gd",
  "enabled": true
}
```
**Expected result**: Same as Scenario 1 — `enabled: true`.  
**Notes**: **Remove after test.**  
**Pay attention**: Verify that explicit `true` and the default value produce the same result.

#### Scenario 4: Edge case — duplicate autoload name

**Description**: Try adding an autoload with a name that already exists.  
**Prerequisite**: Call `add_autoload_config` first to create `TestDupAutoloadMCP`, then call again with the same name.  
**Params** (second call):
```json
{
  "name": "TestDupAutoloadMCP",
  "path": "res://addons/godot_mcp/services/mcp_runtime.gd"
}
```
**Expected result**: Godot should return an error — autoload with this name already exists.  
**Notes**: **Remove after test.**  
**Pay attention**: Verify that the error clearly reports a name conflict.

#### Scenario 5: Edge case — non-existent file path

**Description**: Add an autoload pointing to a file that doesn't exist.  
**Params**:
```json
{
  "name": "TestMissingFileMCP",
  "path": "res://does/not/exist.gd"
}
```
**Expected result**: Godot likely returns an error — cannot find the script/scene at the given path. Or it may succeed and only fail later when trying to load the autoload. Check actual behavior.  
**Pay attention**: Document — whether Godot checks file existence when adding autoload, or only at load time.

#### Scenario 6: Edge case — missing `name`

**Description**: Omit the required `name` parameter.  
**Params**:
```json
{
  "path": "res://some/file.gd"
}
```
**Expected result**: MCP SDK validation error — `name` is required.  
**Pay attention**: Validation error.

#### Scenario 7: Edge case — missing `path`

**Description**: Omit the required `path` parameter.  
**Params**:
```json
{
  "name": "TestNoPathMCP"
}
```
**Expected result**: MCP SDK validation error — `path` is required.  
**Pay attention**: Validation error.

#### Scenario 8: Edge case — empty name

**Description**: Pass an empty string as the autoload name.  
**Params**:
```json
{
  "name": "",
  "path": "res://addons/godot_mcp/services/mcp_runtime.gd"
}
```
**Expected result**: Godot should reject — empty autoload name is invalid.  
**Pay attention**: Verify that the error is handled.

#### Scenario 9: Edge case — `enabled` as non-boolean

**Description**: Pass a string or number for the `enabled` field.  
**Params**:
```json
{
  "name": "TestBadEnabledMCP",
  "path": "res://addons/godot_mcp/services/mcp_runtime.gd",
  "enabled": "yes"
}
```
**Expected result**: Zod validation should reject — `z.boolean()` expects a boolean, not a string. MCP SDK validation error.  
**Pay attention**: Verify that Zod rejects the string `"yes"`.

---

## Tool: remove_autoload_config

**Tool name**: `remove_autoload_config`  
**Description**: Remove an autoload singleton from the project  
**Backend method**: `project_config/remove_autoload_config`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | `Name` (`z.string()`) | **Yes** | — | Autoload singleton name to remove |

### Test Scenarios

#### Scenario 1: Happy path — remove an existing autoload

**Description**: Add a test autoload, verify it exists, then remove it, verify it's gone.  
**Prerequisite sequence**:
1. `add_autoload_config` → create `TestRemoveMCP` autoload (use a safe path like `"res://addons/godot_mcp/services/mcp_runtime.gd"`)
2. `get_autoloads` → verify `TestRemoveMCP` exists
3. `remove_autoload_config` → `{"name": "TestRemoveMCP"}`
4. `get_autoloads` → verify `TestRemoveMCP` is gone

**Params** (step 3):
```json
{
  "name": "TestRemoveMCP"
}
```
**Expected result**: Returns success. The autoload is removed from `project.godot`.  
**Pay attention**: Verify that the record is actually deleted from `get_autoloads` and from `project.godot`.

#### Scenario 2: Edge case — remove non-existent autoload

**Description**: Try removing an autoload name that doesn't exist.  
**Params**:
```json
{
  "name": "ThisAutoloadDoesNotExist12345"
}
```
**Expected result**: Godot should return an error — autoload not found.  
**Pay attention**: Verify that the error is handled correctly without crashing the server.

#### Scenario 3: Edge case — remove autoload twice

**Description**: Remove the same autoload twice.  
**Prerequisite sequence**:
1. `add_autoload_config` → create `TestDoubleRemoveMCP`
2. `remove_autoload_config` → `{"name": "TestDoubleRemoveMCP"}` — success
3. `remove_autoload_config` → `{"name": "TestDoubleRemoveMCP"}` — should fail

**Expected result**: First call succeeds. Second call returns error.  
**Pay attention**: Verify that the second deletion does not cause side effects.

#### Scenario 4: Edge case — missing `name`

**Description**: Omit the required `name` parameter.  
**Params**:
```json
{}
```
**Expected result**: MCP SDK validation error — `name` is required.  
**Pay attention**: Validation error.

---

## Tool: reorder_autoloads

**Tool name**: `reorder_autoloads`  
**Description**: Set the loading order of autoload singletons  
**Backend method**: `project_config/reorder_autoloads`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `order` | `string[]` | **Yes** | — | Ordered list of autoload names (first loads first) |

### Test Scenarios

#### Scenario 1: Happy path — reorder existing autoloads

**Description**: Get current autoloads, reverse their order, set the reversed order, verify.  
**Prerequisite sequence**:
1. `get_autoloads` → extract the list of autoload names in current order (e.g. `["A", "B", "C"]`)
2. `reorder_autoloads` → `{"order": ["C", "B", "A"]}` — reversed
3. `get_autoloads` → verify order is now `["C", "B", "A"]`
4. `reorder_autoloads` → `{"order": ["A", "B", "C"]}` — restore original order

**Params** (step 2):
```json
{
  "order": ["C", "B", "A"]
}
```
**Expected result**: Returns success. The order of autoloads in `get_autoloads` should match the specified order.  
**Notes**: **Restore original order after test.**  
**Pay attention**: Verify that the order in `get_autoloads` matches the passed array. Names are case-sensitive.

#### Scenario 2: Happy path — move first autoload to last

**Description**: Reorder so the first autoload becomes the last.  
**Prerequisite**: Use `get_autoloads` to get current order.  
**Params** (example):
```json
{
  "order": ["B", "C", "A"]
}
```
*(moves "A" from first to last)*  

**Expected result**: Returns success. Order reflects the change.  
**Notes**: **Restore original order.**  
**Pay attention**: Verify that position shifting works correctly.

#### Scenario 3: Edge case — order with subset of autoloads

**Description**: Pass a list containing only some of the existing autoloads.  
**Params**:
```json
{
  "order": ["mcp_runtime"]
}
```
*(assuming other autoloads exist)*  
**Expected result**: Either Godot rejects (incomplete list) or only those listed are reordered and others keep their relative positions. Actual behavior depends on Godot's implementation.  
**Pay attention**: Document the actual behavior — whether Godot requires a FULL list of autoloads or allows a partial one.

#### Scenario 4: Edge case — order with extra names (non-existent autoloads)

**Description**: Include a name in the order that doesn't correspond to any autoload.  
**Params**:
```json
{
  "order": ["mcp_runtime", "fake_autoload_12345"]
}
```
**Expected result**: Godot should return an error — unknown autoload name.  
**Pay attention**: Verify that the error indicates a non-existent name.

#### Scenario 5: Edge case — empty order array

**Description**: Pass an empty array as the order.  
**Params**:
```json
{
  "order": []
}
```
**Expected result**: Likely succeeds as a no-op (nothing to reorder), or Godot may reject.  
**Pay attention**: Document behavior — empty array as no-op or error.

#### Scenario 6: Edge case — missing `order`

**Description**: Omit the required `order` parameter.  
**Params**:
```json
{}
```
**Expected result**: MCP SDK validation error — `order` is required.  
**Pay attention**: Validation error.

#### Scenario 7: Edge case — order as non-array

**Description**: Pass a string or object instead of an array.  
**Params**:
```json
{
  "order": "not_an_array"
}
```
**Expected result**: Zod validation should reject — `z.array(z.string())` expects an array.  
**Pay attention**: Verify that Zod catches the wrong type.

---

## End-to-End Integration Sequences

These sequences test tool dependencies and real-world workflows. They assume the Godot editor is open with the MCP plugin active and a project loaded.

### Sequence 1: Full Input Map Lifecycle

**Goal**: Add → verify → modify → remove actions, then restore the original map.

**Steps**:

1. **Save original map**: `get_input_map` → store result as `original_map`
2. **Add action**: `add_input_action` with `{"action": "e2e_jump", "deadzone": 0.3, "events": [{"type": "key", "keycode": 32, "physical_keycode": 32, "pressed": true}]}`
3. **Verify added**: `get_input_map` → assert `e2e_jump` exists with deadzone 0.3 and spacebar event
4. **Add second action**: `add_input_action` with `{"action": "e2e_dash", "deadzone": 0.2, "events": [{"type": "key", "keycode": 4194321, "physical_keycode": 4194321, "pressed": true}]}`
5. **Verify both exist**: `get_input_map` → assert both `e2e_jump` and `e2e_dash` exist
6. **Remove first action**: `remove_input_action` with `{"action": "e2e_jump"}`
7. **Verify removed**: `get_input_map` → assert `e2e_jump` is gone, `e2e_dash` still exists
8. **Remove second action**: `remove_input_action` with `{"action": "e2e_dash"}`
9. **Verify both gone**: `get_input_map` → assert neither `e2e_jump` nor `e2e_dash` exist
10. **Replace entire map**: `set_input_map` with the saved `original_map`
11. **Verify restored**: `get_input_map` → assert map matches `original_map` (same actions, same event counts)

**Pay attention**: Key check — step 11 must show that the map is fully restored. Compare the number of actions and events with the original.

### Sequence 2: Full Autoload Lifecycle

**Goal**: Add → reorder → remove autoloads, verify at each step.

**Steps**:

1. **Save original state**: `get_autoloads` → store `original_autoloads` and `original_names` (ordered list of names)
2. **Add autoload A**: `add_autoload_config` with `{"name": "E2E_A", "path": "res://addons/godot_mcp/services/mcp_runtime.gd", "enabled": true}`
3. **Add autoload B**: `add_autoload_config` with `{"name": "E2E_B", "path": "res://addons/godot_mcp/services/mcp_runtime.gd", "enabled": false}`
4. **Verify both added**: `get_autoloads` → assert `E2E_A` (enabled) and `E2E_B` (disabled) are present
5. **Reorder to put B first**: `reorder_autoloads` with a new order that has `"E2E_B"` before `"E2E_A"` (preserving other autoloads in their original order)
6. **Verify order**: `get_autoloads` → assert `E2E_B` appears before `E2E_A` in the list
7. **Remove B**: `remove_autoload_config` with `{"name": "E2E_B"}`
8. **Verify B gone**: `get_autoloads` → assert `E2E_B` is not present, `E2E_A` still exists
9. **Remove A**: `remove_autoload_config` with `{"name": "E2E_A"}`
10. **Verify both gone**: `get_autoloads` → assert neither `E2E_A` nor `E2E_B` are present
11. **Restore original order**: `reorder_autoloads` with `original_names` (restore exact order)
12. **Verify restored**: `get_autoloads` → assert list matches `original_autoloads` (same names, same order)

**⚠️ Do NOT leave test autoloads in the project** — they point to `mcp_runtime.gd` and will create duplicate singletons on next game launch. Always clean up in steps 7-9 and verify in step 10.

**Pay attention**: This is the most important integration test. Ensure that after step 12 the project has exactly returned to its original state.

### Sequence 3: Project Settings Read-Modify-Reset Cycle

**Goal**: Read → modify → verify → reset → verify a project setting.

**Steps**:

1. **Read original**: `get_project_setting` with `{"key": "application/config/description"}` → store as `original_description`
2. **Set new value**: `set_project_setting_config` with `{"key": "application/config/description", "value": "E2E MCP Test Description"}`
3. **Verify change**: `get_project_setting` with `{"key": "application/config/description"}` → assert equals `"E2E MCP Test Description"`
4. **Read all settings with filter**: `get_all_project_settings` with `{"filter": "application/config/"}` → assert `description` field is `"E2E MCP Test Description"`
5. **Reset setting**: `reset_project_setting` with `{"key": "application/config/description"}`
6. **Verify reset**: `get_project_setting` with `{"key": "application/config/description"}` → assert value is NOT `"E2E MCP Test Description"` (should be empty/default)
7. **Restore if needed**: If `original_description` was non-empty, call `set_project_setting_config` to restore it

**Pay attention**: Step 6 verifies that `reset_project_setting` actually resets the value. If the original value was non-empty, step 7 restores it.

### Sequence 4: Cross-Domain Read (No Mutations)

**Goal**: Verify read-only tools across all 3 sub-domains return consistent, valid data. This is a safe pre-flight check that can run anytime.

**Steps**:

1. `get_project_setting` → `{"key": "application/config/name"}` → expect string
2. `get_all_project_settings` → `{}` → expect large object with many keys
3. `get_all_project_settings` → `{"filter": "display/"}` → expect only `display/` keys
4. `get_input_map` → `{}` → expect object with action→events mapping
5. `get_autoloads` → `{}` → expect list of autoloads

**Pay attention**: None of these calls should change the project state. Verify that all responses contain `content[0].text` with valid JSON and `isError !== true`.

---

## Notes for Test Execution

1. **Prerequisites**: Godot editor with the MCP plugin active and a project loaded. The server must be connected to the Godot bridge.

2. **Destructive operations**: Several tools modify `project.godot` permanently. Tests involving `set_project_setting_config`, `set_input_map`, `add_input_action`, `remove_input_action`, `add_autoload_config`, `remove_autoload_config`, `reorder_autoloads`, and `reset_project_setting` **MUST restore the original state** after the test.

3. **Autoload safety**: When adding test autoloads, always use a path to an existing `.gd` file (like `mcp_runtime.gd`) to avoid Godot errors, but **never leave test autoloads in the project** — they will create duplicate singletons that can break the game or the MCP plugin itself. Always verify removal with `get_autoloads`.

4. **Input map golden copy**: Before running any input map mutation tests, capture a complete copy of the input map via `get_input_map` and store it as the "golden copy". Use this to restore the map at the end of testing.

5. **Project settings golden copy**: Before running `set_project_setting_config` or `reset_project_setting` tests, record the original values for the keys being tested and restore them after.

6. **Error expectation**: When testing edge cases (invalid keys, missing params, type mismatches), verify that errors are returned with `isError: true` and that the server does not crash or become unresponsive.

7. **Response structure**: All successful responses should follow the format `{ content: [{ type: "text", text: "..." }] }`. The `text` field for data-returning tools should be valid JSON. Error responses should have `isError: true`.
