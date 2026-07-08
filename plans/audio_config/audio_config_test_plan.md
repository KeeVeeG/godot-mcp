# Audio Configuration Tools — Test Plan

**Source file:** `server/src/tools/audio_config.ts`
**Generated:** 2026-07-08

---

## Shared Types Used

| Import | Type | Notes |
|--------|------|-------|
| `Name` | `z.string().describe('Name identifier')` | Plain string, no enum constraints |
| `z` | Zod namespace | Re-exported from `shared-types.ts` |

All 6 tools call `callGodot(bridge, '<endpoint>', args)` which delegates to the Godot editor plugin via WebSocket. Tools return `ToolResult` (JSON stringified content). Error responses have `isError: true`.

---

## Tool: `get_audio_settings`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| *(none)* | — | — | No input parameters |

### Handler

Calls `callGodot(bridge, 'audio_config/get_settings')` — no args forwarded.

### Test Scenarios

#### Scenario 1: Basic happy path — read current settings
- **Description:** Call with no arguments; expect the current audio bus layout, default bus info, and driver info returned as JSON.
- **Params:** `{}`
- **Expected result:** Success. Returns a JSON object containing keys like `buses`, `default_bus`, `driver`. The `buses` array contains at least one entry (the "Master" bus).
- **Notes:** This is a read-only tool; verify it does not mutate audio state.

#### Scenario 2: Call without any argument object
- **Description:** Invoke with no argument object at all (empty input).
- **Params:** `{}`
- **Expected result:** Success (same as Scenario 1). No required params.

---

## Tool: `set_audio_bus_layout`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `buses` | `array` of objects | **Yes** | Ordered list of audio buses (first is always 'Master') |
| `buses[].name` | `string` | **Yes** | Bus name |
| `buses[].volume` | `number` | No | Volume in dB |
| `buses[].solo` | `boolean` | No | Solo this bus |
| `buses[].mute` | `boolean` | No | Mute this bus |

### Handler

Calls `callGodot(bridge, 'audio_config/set_bus_layout', args)`.

### Test Scenarios

#### Scenario 1: Happy path — replace layout with Master + one custom bus
- **Description:** Set a layout with Master and a single "Music" bus, all optional fields omitted.
- **Params:**
  ```json
  {
    "buses": [
      { "name": "Master" },
      { "name": "Music" }
    ]
  }
  ```
- **Expected result:** Success. Layout replaced; verify via `get_audio_settings` that only Master and Music exist.

#### Scenario 2: Happy path — full bus definitions with all optional fields
- **Description:** Set a layout with Master, Music (with volume/solo/mute), and SFX (with volume/solo/mute).
- **Params:**
  ```json
  {
    "buses": [
      { "name": "Master", "volume": 0, "solo": false, "mute": false },
      { "name": "Music", "volume": -6, "solo": false, "mute": true },
      { "name": "SFX", "volume": -3, "solo": true, "mute": false }
    ]
  }
  ```
- **Expected result:** Success. All three buses created with specified properties. Verify via `get_audio_settings`.

#### Scenario 3: Happy path — solo and mute both true
- **Description:** Set a bus with `solo: true` and `mute: true` simultaneously.
- **Params:**
  ```json
  {
    "buses": [
      { "name": "Master" },
      { "name": "Voice", "solo": true, "mute": true }
    ]
  }
  ```
- **Expected result:** Success. Godot handles this natively (solo typically overrides mute at the engine level).

#### Scenario 4: Happy path — positive volume_db
- **Description:** Use a positive `volume_db` value (amplification).
- **Params:**
  ```json
  {
    "buses": [
      { "name": "Master", "volume": 6 },
      { "name": "Loud", "volume": 12 }
    ]
  }
  ```
- **Expected result:** Success. Volume values accepted. Verify via `get_audio_settings`.

#### Scenario 5: Happy path — minimal layout (Master only)
- **Description:** Set layout with only the Master bus.
- **Params:**
  ```json
  {
    "buses": [
      { "name": "Master" }
    ]
  }
  ```
- **Expected result:** Success. Layout contains only Master. All other buses removed.

#### Scenario 6: Happy path — large negative volume_db
- **Description:** Use a strongly negative `volume_db` (e.g., -80 dB, near silence).
- **Params:**
  ```json
  {
    "buses": [
      { "name": "Master" },
      { "name": "Silent", "volume": -80 }
    ]
  }
  ```
- **Expected result:** Success. Godot clamps volume at -80 dB internally.

#### Scenario 7: Edge case — empty buses array
- **Description:** Pass an empty `buses` array.
- **Params:**
  ```json
  {
    "buses": []
  }
  ```
- **Expected result:** Likely errors. Godot requires at least the Master bus at index 0. Expect an error response or Godot rejecting the layout.

#### Scenario 8: Edge case — first bus is not named "Master"
- **Description:** Provide a buses array where the first entry is named "SFX" instead of "Master".
- **Params:**
  ```json
  {
    "buses": [
      { "name": "SFX" }
    ]
  }
  ```
- **Expected result:** May succeed or error depending on Godot behavior. Document whichever occurs.
- **Notes:** The schema description states "first is always 'Master'" but the server does not enforce this (no `.refine()` on the Zod schema). This is a documentation contract, not a validation constraint.

#### Scenario 9: Edge case — duplicate bus names
- **Description:** Provide two buses with the same name.
- **Params:**
  ```json
  {
    "buses": [
      { "name": "Master" },
      { "name": "Music" },
      { "name": "Music" }
    ]
  }
  ```
- **Expected result:** Error. Godot does not allow duplicate bus names.

#### Scenario 10: Edge case — empty bus name string
- **Description:** Provide a bus with an empty string name.
- **Params:**
  ```json
  {
    "buses": [
      { "name": "" }
    ]
  }
  ```
- **Expected result:** Error. Empty bus name should be rejected.

#### Scenario 11: Edge case — non-integer volume_db
- **Description:** Pass a floating-point `volume_db` value.
- **Params:**
  ```json
  {
    "buses": [
      { "name": "Master" },
      { "name": "Music", "volume": -3.5 }
    ]
  }
  ```
- **Expected result:** Success. `z.number()` accepts floats. Godot handles fractional dB values.

#### Scenario 12: Edge case — missing required `buses` field
- **Description:** Call without the `buses` parameter.
- **Params:** `{}`
- **Expected result:** Error (Zod validation failure). `buses` is required.

#### Scenario 13: Edge case — buses is not an array
- **Description:** Pass a string instead of an array for `buses`.
- **Params:**
  ```json
  {
    "buses": "not_an_array"
  }
  ```
- **Expected result:** Error (Zod validation failure).

#### Scenario 14: Edge case — bus object missing required `name`
- **Description:** Include a bus object without the `name` field.
- **Params:**
  ```json
  {
    "buses": [
      { "volume": 0 }
    ]
  }
  ```
- **Expected result:** Error (Zod validation failure within array item).

#### Scenario 15: Edge case — solo/mute passed as non-boolean
- **Description:** Pass a string or number for `solo` or `mute`.
- **Params:**
  ```json
  {
    "buses": [
      { "name": "Master" },
      { "name": "Music", "solo": "yes", "mute": 1 }
    ]
  }
  ```
- **Expected result:** Error (Zod validation failure). `z.boolean()` rejects strings/numbers.

---

## Tool: `add_audio_bus_config`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | `string` (`Name`) | **Yes** | Bus name |
| `index` | `number` (integer) | No | Position in bus list (omit to append) |

### Handler

Calls `callGodot(bridge, 'audio_config/add_bus_config', args)`.

### Test Scenarios

#### Scenario 1: Happy path — add bus with append (omit index)
- **Description:** Add a new bus named "Music" without specifying an index; should be appended to the end.
- **Params:**
  ```json
  {
    "name": "Music"
  }
  ```
- **Expected result:** Success. "Music" bus appears at the end of the bus list. Verify via `get_audio_settings`.

#### Scenario 2: Happy path — add bus at explicit index
- **Description:** Add a bus at a specific position (index 1, immediately after Master).
- **Params:**
  ```json
  {
    "name": "SFX",
    "index": 1
  }
  ```
- **Expected result:** Success. "SFX" bus inserted at index 1 (after Master). Verify bus order via `get_audio_settings`.

#### Scenario 3: Happy path — add bus at index 0
- **Description:** Attempt to add a bus at index 0 (replacing Master's position).
- **Params:**
  ```json
  {
    "name": "NewMaster",
    "index": 0
  }
  ```
- **Expected result:** May succeed or error. Godot might shift Master to index 1 or reject the operation. Document actual behavior.

#### Scenario 4: Happy path — add multiple buses sequentially
- **Description:** Add three buses one after another (append).
- **Params:** Three separate calls:
  1. `{ "name": "Music" }`
  2. `{ "name": "SFX" }`
  3. `{ "name": "Voice" }`
- **Expected result:** All three succeed. Buses appear in order: Music, SFX, Voice (after Master).

#### Scenario 5: Happy path — add bus with spaces/special characters in name
- **Description:** Add a bus with a name containing spaces and special characters.
- **Params:**
  ```json
  {
    "name": "Ambient Sounds 2.0"
  }
  ```
- **Expected result:** Success (if Godot allows it). Document whether Godot sanitizes the name.

#### Scenario 6: Edge case — missing required `name`
- **Description:** Call without the `name` parameter.
- **Params:** `{}`
- **Expected result:** Error (Zod validation failure). `name` is required.

#### Scenario 7: Edge case — empty string name
- **Description:** Pass an empty string as the bus name.
- **Params:**
  ```json
  {
    "name": ""
  }
  ```
- **Expected result:** Error. Bus name should not be empty.

#### Scenario 8: Edge case — duplicate bus name
- **Description:** Add a bus with the same name as an existing bus (e.g., add "Music" twice).
- **Params:**
  ```json
  {
    "name": "Master"
  }
  ```
- **Expected result:** Error. "Master" already exists.

#### Scenario 9: Edge case — negative index
- **Description:** Pass a negative `index` value.
- **Params:**
  ```json
  {
    "name": "NegativeBus",
    "index": -1
  }
  ```
- **Expected result:** Error (Zod validation failure). `z.number().int()` alone does not reject negatives, but Godot will likely reject an out-of-range index.

#### Scenario 10: Edge case — very large index
- **Description:** Pass an extremely large `index` (e.g., 99999).
- **Params:**
  ```json
  {
    "name": "FarBus",
    "index": 99999
  }
  ```
- **Expected result:** Likely error. Godot rejects out-of-bounds index or appends instead. Document actual behavior.

#### Scenario 11: Edge case — non-integer index
- **Description:** Pass a float for `index`.
- **Params:**
  ```json
  {
    "name": "FloatBus",
    "index": 1.5
  }
  ```
- **Expected result:** Error (Zod validation failure). `.int()` rejects floats.

#### Scenario 12: Edge case — index as string
- **Description:** Pass `index` as a string.
- **Params:**
  ```json
  {
    "name": "StrBus",
    "index": "1"
  }
  ```
- **Expected result:** Error (Zod validation failure). `z.number()` rejects strings.

---

## Tool: `remove_audio_bus`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `index` | `number` (integer, ≥ 1) | **Yes** | Bus index to remove (1+, cannot remove Master) |

### Handler

Calls `callGodot(bridge, 'audio_config/remove_bus', args)`.

### Test Scenarios

#### Scenario 1: Happy path — remove bus at index 1
- **Description:** Remove the bus at index 1 (first bus after Master). Prerequisite: at least one bus exists at index 1 (e.g., add one first).
- **Params:**
  ```json
  {
    "index": 1
  }
  ```
- **Expected result:** Success. Bus at index 1 removed. Verify via `get_audio_settings`.

#### Scenario 2: Happy path — remove bus at index 2
- **Description:** Remove the bus at index 2. Prerequisite: at least two buses after Master.
- **Params:**
  ```json
  {
    "index": 2
  }
  ```
- **Expected result:** Success. Bus at index 2 removed. Verify via `get_audio_settings`.

#### Scenario 3: Edge case — attempt to remove Master (index 0)
- **Description:** Try to remove bus at index 0, which is always the Master bus.
- **Params:**
  ```json
  {
    "index": 0
  }
  ```
- **Expected result:** Error (Zod validation failure). Schema enforces `.min(1)`, so value 0 is rejected at the MCP server level before reaching Godot.

#### Scenario 4: Edge case — negative index
- **Description:** Pass a negative index.
- **Params:**
  ```json
  {
    "index": -1
  }
  ```
- **Expected result:** Error (Zod validation failure). `.min(1)` rejects negatives.

#### Scenario 5: Edge case — index out of range (no bus at position)
- **Description:** Remove a bus at an index that does not exist (e.g., index 999 when only Master exists).
- **Params:**
  ```json
  {
    "index": 999
  }
  ```
- **Expected result:** Error from Godot. "Index out of range" or equivalent.

#### Scenario 6: Edge case — missing required `index`
- **Description:** Call without the `index` parameter.
- **Params:** `{}`
- **Expected result:** Error (Zod validation failure).

#### Scenario 7: Edge case — non-integer index
- **Description:** Pass a float for `index`.
- **Params:**
  ```json
  {
    "index": 1.5
  }
  ```
- **Expected result:** Error (Zod validation failure). `.int()` rejects floats.

#### Scenario 8: Edge case — index as string
- **Description:** Pass `index` as a string.
- **Params:**
  ```json
  {
    "index": "1"
  }
  ```
- **Expected result:** Error (Zod validation failure).

#### Scenario 9: Edge case — remove bus when only Master exists
- **Description:** After a fresh layout with only Master, attempt to remove index 1.
- **Params:**
  ```json
  {
    "index": 1
  }
  ```
- **Expected result:** Error from Godot. No bus exists at index 1.

---

## Tool: `set_audio_bus_volume`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `bus` | `string` (`Name`) | **Yes** | Bus name (e.g. 'Master', 'Music', 'SFX') |
| `volume_db` | `number` | **Yes** | Volume in decibels (0 = normal, negative = quieter) |

### Handler

Calls `callGodot(bridge, 'audio_config/set_bus_volume', args)`.

### Test Scenarios

#### Scenario 1: Happy path — set Master volume to 0 dB
- **Description:** Set the Master bus volume to 0 dB (unity gain).
- **Params:**
  ```json
  {
    "bus": "Master",
    "volume_db": 0
  }
  ```
- **Expected result:** Success. Master bus volume is 0 dB. Verify via `get_audio_settings`.

#### Scenario 2: Happy path — set custom bus to negative dB
- **Description:** Set "Music" bus volume to -6 dB (quieter). Prerequisite: "Music" bus exists.
- **Params:**
  ```json
  {
    "bus": "Music",
    "volume_db": -6
  }
  ```
- **Expected result:** Success. Music bus volume is -6 dB. Verify via `get_audio_settings`.

#### Scenario 3: Happy path — set volume to positive dB (amplification)
- **Description:** Set a bus volume to +3 dB (louder).
- **Params:**
  ```json
  {
    "bus": "Master",
    "volume_db": 3
  }
  ```
- **Expected result:** Success. Master bus volume is 3 dB.

#### Scenario 4: Happy path — set volume to minimum (-80 dB)
- **Description:** Set volume to -80 dB (near silence, Godot's internal minimum).
- **Params:**
  ```json
  {
    "bus": "Master",
    "volume_db": -80
  }
  ```
- **Expected result:** Success. Volume set to -80 dB. Godot may clamp to -80 internally.

#### Scenario 5: Happy path — set volume to a high value (+24 dB)
- **Description:** Set volume to +24 dB (strong amplification).
- **Params:**
  ```json
  {
    "bus": "Master",
    "volume_db": 24
  }
  ```
- **Expected result:** Success. Volume set to 24 dB. Godot may clamp to an internal maximum.

#### Scenario 6: Happy path — floating-point volume_db
- **Description:** Set volume to a fractional dB value.
- **Params:**
  ```json
  {
    "bus": "Master",
    "volume_db": -3.75
  }
  ```
- **Expected result:** Success. `z.number()` accepts floats.

#### Scenario 7: Edge case — missing required `bus`
- **Description:** Call without the `bus` parameter.
- **Params:**
  ```json
  {
    "volume_db": 0
  }
  ```
- **Expected result:** Error (Zod validation failure).

#### Scenario 8: Edge case — missing required `volume_db`
- **Description:** Call without the `volume_db` parameter.
- **Params:**
  ```json
  {
    "bus": "Master"
  }
  ```
- **Expected result:** Error (Zod validation failure).

#### Scenario 9: Edge case — bus does not exist
- **Description:** Set volume on a bus that does not exist.
- **Params:**
  ```json
  {
    "bus": "NonexistentBus",
    "volume_db": 0
  }
  ```
- **Expected result:** Error from Godot. "Bus not found" or equivalent.

#### Scenario 10: Edge case — empty bus name
- **Description:** Pass an empty string for `bus`.
- **Params:**
  ```json
  {
    "bus": "",
    "volume_db": 0
  }
  ```
- **Expected result:** Error from Godot (no bus with empty name).

#### Scenario 11: Edge case — volume_db as string
- **Description:** Pass `volume_db` as a string.
- **Params:**
  ```json
  {
    "bus": "Master",
    "volume_db": "-6"
  }
  ```
- **Expected result:** Error (Zod validation failure). `z.number()` rejects strings.

#### Scenario 12: Edge case — volume_db as boolean
- **Description:** Pass `volume_db` as a boolean.
- **Params:**
  ```json
  {
    "bus": "Master",
    "volume_db": true
  }
  ```
- **Expected result:** Error (Zod validation failure).

---

## Tool: `get_audio_bus_effects`

### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `bus` | `string` (`Name`) | **Yes** | Bus name to inspect |

### Handler

Calls `callGodot(bridge, 'audio_config/get_bus_effects', args)`.

### Test Scenarios

#### Scenario 1: Happy path — get effects on Master bus
- **Description:** Request effects for the Master bus.
- **Params:**
  ```json
  {
    "bus": "Master"
  }
  ```
- **Expected result:** Success. Returns an array of effects (may be empty if no effects added). Each effect includes type and properties.

#### Scenario 2: Happy path — get effects on a bus with effects
- **Description:** Add an effect to a bus first (using `add_audio_bus_effect`), then query effects. Prerequisite: "Music" bus exists with at least one effect.
- **Params:**
  ```json
  {
    "bus": "Music"
  }
  ```
- **Expected result:** Success. Returns all effects on the Music bus with their properties and configuration.

#### Scenario 3: Happy path — get effects on an empty bus
- **Description:** Get effects on a bus that has no effects (e.g., a freshly created bus).
- **Params:**
  ```json
  {
    "bus": "SFX"
  }
  ```
- **Expected result:** Success. Returns an empty effects array.

#### Scenario 4: Happy path — bus with multiple effects
- **Description:** Add multiple effects (e.g., reverb + delay) to a bus, then query. Prerequisite: bus with 2+ effects.
- **Params:**
  ```json
  {
    "bus": "Music"
  }
  ```
- **Expected result:** Success. Returns all effects in order, each with type and properties.

#### Scenario 5: Edge case — missing required `bus`
- **Description:** Call without the `bus` parameter.
- **Params:** `{}`
- **Expected result:** Error (Zod validation failure).

#### Scenario 6: Edge case — bus does not exist
- **Description:** Query effects for a non-existent bus.
- **Params:**
  ```json
  {
    "bus": "FakeBus"
  }
  ```
- **Expected result:** Error from Godot. "Bus not found" or equivalent.

#### Scenario 7: Edge case — empty string bus name
- **Description:** Pass an empty string for `bus`.
- **Params:**
  ```json
  {
    "bus": ""
  }
  ```
- **Expected result:** Error from Godot. No bus with empty name exists.

#### Scenario 8: Edge case — bus name with special characters
- **Description:** Query a bus name with Unicode or special characters (if such a bus exists).
- **Params:**
  ```json
  {
    "bus": "エフェクト"
  }
  ```
- **Expected result:** Error from Godot (bus likely does not exist). If it does exist, returns effects normally.

---

## Cross-Tool Integration Scenarios

These scenarios test interactions between multiple audio_config tools.

### Integration 1: Full layout lifecycle
1. Call `set_audio_bus_layout` with `[{ "name": "Master" }]` to reset.
2. Call `get_audio_settings` — expect only Master.
3. Call `add_audio_bus_config` with `{ "name": "Music" }` — append Music.
4. Call `add_audio_bus_config` with `{ "name": "SFX", "index": 1 }` — insert SFX before Music.
5. Call `get_audio_settings` — expect buses: Master, SFX, Music.
6. Call `set_audio_bus_volume` with `{ "bus": "SFX", "volume_db": -3 }`.
7. Call `get_audio_bus_effects` with `{ "bus": "SFX" }` — expect empty effects.
8. Call `remove_audio_bus` with `{ "index": 2 }` — removes Music.
9. Call `get_audio_settings` — expect buses: Master, SFX.
10. Call `remove_audio_bus` with `{ "index": 1 }` — removes SFX.
11. Call `get_audio_settings` — expect only Master.

### Integration 2: Volume boundary values
1. Call `set_audio_bus_volume` with `{ "bus": "Master", "volume_db": 0 }` — normal.
2. Call `set_audio_bus_volume` with `{ "bus": "Master", "volume_db": -80 }` — minimum.
3. Call `set_audio_bus_volume` with `{ "bus": "Master", "volume_db": 24 }` — maximum (Godot may clamp).
4. Call `get_audio_settings` — verify final volume value (may be clamped).

---

## Summary of All Tools

| # | Tool Name | Required Params | Optional Params | Godot Endpoint |
|---|-----------|----------------|-----------------|----------------|
| 1 | `get_audio_settings` | *(none)* | — | `audio_config/get_settings` |
| 2 | `set_audio_bus_layout` | `buses` | — | `audio_config/set_bus_layout` |
| 3 | `add_audio_bus_config` | `name` | `index` | `audio_config/add_bus_config` |
| 4 | `remove_audio_bus` | `index` (≥1) | — | `audio_config/remove_bus` |
| 5 | `set_audio_bus_volume` | `bus`, `volume_db` | — | `audio_config/set_bus_volume` |
| 6 | `get_audio_bus_effects` | `bus` | — | `audio_config/get_bus_effects` |

**Total tools:** 6
**Total test scenarios:** 44 (happy paths + edge cases + 2 integration scenarios)
