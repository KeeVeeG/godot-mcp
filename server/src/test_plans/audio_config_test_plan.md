# Audio Configuration Tools — Test Plan

**Source file:** `server/src/tools/audio_config.ts`
**Bridge route prefix:** `audio_config/`
**Number of tools:** 6

---

## Prerequisites for all tests

1. Godot editor is open with the MCP plugin active and connected.
2. At minimum, the default "Master" audio bus exists (Godot always creates Master at index 0).
3. For tests that add/remove buses, the test project should be in a clean or disposable state (no user-added buses).
4. Tests must verify LSP diagnostics pass on `audio_config.ts` (no syntax/type errors).

---

## Tool 1: `godot_get_audio_settings`

| Field          | Value |
|----------------|-------|
| **Bridge route** | `audio_config/get_settings` |
| **Params**        | **None** |
| **Returns**       | Object describing all audio settings: bus layout, default bus name, driver info, and any other global audio state. |

### Expected Response Shape
```jsonc
{
  "bus_layout": [
    { "name": "Master", "volume_db": 0, "solo": false, "mute": false, /* ... */ }
    // ...additional buses
  ],
  "default_bus": "Master",
  "driver": "..." // e.g. "Dummy" or "WASAPI" depending on platform
}
```

### Test Scenarios

#### TC-1.1: Happy path — call on default project
- **Action:** Call `godot_get_audio_settings` with no arguments.
- **Expected:** Returns an object containing at minimum:
  - `bus_layout` array with at least one entry (`{ "name": "Master" }`).
  - A `default_bus` field.
  - No error.

#### TC-1.2: Call after adding multiple buses
- **Setup:** Add buses "Music", "SFX", "Ambient" via `godot_add_audio_bus_config`.
- **Action:** Call `godot_get_audio_settings`.
- **Expected:** `bus_layout` contains 4 entries: Master, Music, SFX, Ambient (preserving insertion order). Each entry has `name` and `volume_db` fields.

#### TC-1.3: Call after modifying bus volume/mute
- **Setup:** Add bus "SFX", then call `godot_set_audio_bus_volume` with bus="SFX", volume_db=-6. Also set "Music" bus mute to true (via `godot_set_audio_bus` from audio.ts or layout).
- **Action:** Call `godot_get_audio_settings`.
- **Expected:** Returned `bus_layout` reflects the current state: SFX shows `volume_db: -6`, Music shows `mute: true` (or whatever mechanism the return shape uses).

#### TC-1.4: Edge case — call when Godot is not connected
- **Action:** Call `godot_get_audio_settings` when the Godot editor is not connected.
- **Expected:** Returns an error indicating the Godot editor is not connected.

---

## Tool 2: `godot_set_audio_bus_layout`

| Field            | Value |
|------------------|-------|
| **Bridge route**   | `audio_config/set_bus_layout` |
| **Required params** | `buses` — array of bus objects |
| **Optional params** | (per entry) `volume` (number, dB), `solo` (boolean), `mute` (boolean) |

### Parameter Details

| Param  | Type               | Zod Schema                                                                 | Notes |
|--------|--------------------|----------------------------------------------------------------------------|-------|
| `buses` | `Array<BusDef>`    | `z.array(z.object({ name: z.string(), volume: z.number().optional(), solo: z.boolean().optional(), mute: z.boolean().optional() }))` | First entry must be "Master". All buses provided replace the entire layout. |

### Expected Behavior
- **Destructive/replacement:** The entire audio bus layout is replaced with the provided array. Any existing buses not in the array are removed. Any new buses not already present are created.
- **Order matters:** The order of entries in `buses` is preserved as the bus order.
- **First bus is Master:** The first item should always be named "Master". Godot requires Master at index 0. Behavior when first item is NOT "Master" is undefined/implementation-specific — test both rejection and acceptance.
- **Optional fields:** `volume`, `solo`, `mute` default to Godot engine defaults (volume_db=0, solo=false, mute=false) when omitted.

### Test Scenarios

#### TC-2.1: Happy path — replace layout with Master + one new bus
- **Action:**
  ```json
  godot_set_audio_bus_layout({
    "buses": [
      { "name": "Master", "volume": 0, "solo": false, "mute": false },
      { "name": "Music", "volume": -3 }
    ]
  })
  ```
- **Verify:** Call `godot_get_audio_settings` — `bus_layout` contains exactly 2 entries: Master and Music. Music has volume_db ≈ -3.

#### TC-2.2: Happy path — set layout with volume on all buses
- **Action:**
  ```json
  godot_set_audio_bus_layout({
    "buses": [
      { "name": "Master", "volume": 0 },
      { "name": "SFX", "volume": -6 },
      { "name": "Ambient", "volume": -12 }
    ]
  })
  ```
- **Verify:** All three buses exist. SFX volume = -6, Ambient volume = -12.

#### TC-2.3: Set layout with minimum params (name only)
- **Action:**
  ```json
  godot_set_audio_bus_layout({
    "buses": [
      { "name": "Master" },
      { "name": "Dialogue" }
    ]
  })
  ```
- **Verify:** Both buses exist. Dialogue has Godot default volume (0). No error.

#### TC-2.4: Set layout with solo and mute flags
- **Action:**
  ```json
  godot_set_audio_bus_layout({
    "buses": [
      { "name": "Master" },
      { "name": "Music", "solo": true },
      { "name": "SFX", "mute": true }
    ]
  })
  ```
- **Verify:** Music has `solo: true`, SFX has `mute: true`.

#### TC-2.5: Replace layout (remove previously added buses)
- **Setup:** Add buses "A", "B", "C" via `godot_add_audio_bus_config`.
- **Action:** Call `godot_set_audio_bus_layout` with only `[{ "name": "Master" }]`.
- **Verify:** Only Master bus exists. A, B, C are gone.

#### TC-2.6: Edge case — empty array
- **Action:**
  ```json
  godot_set_audio_bus_layout({ "buses": [] })
  ```
- **Expected:** Either error (rejected) OR all buses removed except Master (engine may auto-preserve Master). Document actual behavior.

#### TC-2.7: Edge case — first bus not named "Master"
- **Action:**
  ```json
  godot_set_audio_bus_layout({
    "buses": [
      { "name": "NotMaster" },
      { "name": "Music" }
    ]
  })
  ```
- **Expected:** Either rejected with error message about Master requirement, OR engine auto-renames/reorders. Document actual behavior.

#### TC-2.8: Edge case — duplicate bus names
- **Action:**
  ```json
  godot_set_audio_bus_layout({
    "buses": [
      { "name": "Master" },
      { "name": "Music" },
      { "name": "Music" }
    ]
  })
  ```
- **Expected:** Should be rejected with error about duplicate bus names. Alternatively, engine may silently deduplicate (last wins). Document actual behavior.

#### TC-2.9: Edge case — invalid param types
- **Action:** Call with `{ "buses": "not_an_array" }`.
- **Expected:** Zod validation error (buses must be an array).

#### TC-2.10: Edge case — invalid bus entry (no name field)
- **Action:**
  ```json
  godot_set_audio_bus_layout({
    "buses": [
      { "volume": -3 }
    ]
  })
  ```
- **Expected:** Zod validation error (each bus must have a `name` string).

#### TC-2.11: Edge case — very large number of buses
- **Action:** Set layout with 50+ buses (e.g., generated programmatically).
- **Expected:** Layout is applied correctly (or engine caps at a maximum — document the cap).

#### TC-2.12: Edge case — extreme volume values
- **Action:**
  ```json
  godot_set_audio_bus_layout({
    "buses": [
      { "name": "Master" },
      { "name": "Loud", "volume": 24 },
      { "name": "Quiet", "volume": -79.5 }
    ]
  })
  ```
- **Expected:** Volume values are applied as-is (Godot audio bus volume has a wide range). Query with `godot_get_audio_settings` to confirm exact values were stored.

---

## Tool 3: `godot_add_audio_bus_config`

| Field              | Value |
|--------------------|-------|
| **Bridge route**     | `audio_config/add_bus_config` |
| **Required params**   | `name` (string) |
| **Optional params**   | `index` (integer, position in bus list; omit to append) |

### Parameter Details

| Param   | Type     | Zod Schema                          | Notes |
|---------|----------|--------------------------------------|-------|
| `name`  | `string` | `Name` = `z.string().describe('Name identifier')` | Bus name. Must be unique among buses. |
| `index` | `number` (integer) | `z.number().int().optional()` | 0-based? Or 1-based? (Master is typically index 0). Must be within existing bus bounds, or append. |

### Expected Behavior
- If `index` is omitted: bus is appended at the end of the bus list.
- If `index` is provided: bus is inserted at that position. All buses at that index and above shift down.
- Cannot use `index=0` if Master already occupies index 0 — the engine may reject or shift.
- Name must not duplicate an existing bus name.

### Test Scenarios

#### TC-3.1: Happy path — add bus with name only (append)
- **Action:**
  ```json
  godot_add_audio_bus_config({ "name": "Music" })
  ```
- **Verify:** `godot_get_audio_settings` shows "Music" appended at the end of `bus_layout` (after Master).

#### TC-3.2: Happy path — add bus at specific index
- **Action:**
  ```json
  godot_add_audio_bus_config({ "name": "SFX", "index": 1 })
  ```
- **Verify:** "SFX" appears at index 1 in `bus_layout`. Master remains at index 0.

#### TC-3.3: Add multiple buses sequentially (append)
- **Action:** Call `godot_add_audio_bus_config` three times with names "A", "B", "C" (no index).
- **Verify:** `bus_layout` order is Master, A, B, C.

#### TC-3.4: Add multiple buses at specific indices
- **Setup:** Clean layout (Master only).
- **Steps:**
  1. Add "B" at index 1 → layout: Master, B.
  2. Add "A" at index 1 → layout: Master, A, B.
  3. Add "C" at index 3 → layout: Master, A, B, C.
- **Verify:** Final order matches expected.

#### TC-3.5: Add bus with name containing spaces and special characters
- **Action:**
  ```json
  godot_add_audio_bus_config({ "name": "Background Music" })
  godot_add_audio_bus_config({ "name": "UI/SFX" })
  ```
- **Verify:** Both buses are created. Names are stored as-is.

#### TC-3.6: Edge case — duplicate name
- **Setup:** Bus "Music" already exists.
- **Action:**
  ```json
  godot_add_audio_bus_config({ "name": "Music" })
  ```
- **Expected:** Error — bus name already exists. No new bus created.

#### TC-3.7: Edge case — index out of range (too large)
- **Setup:** Only Master exists (1 bus, max index 0).
- **Action:**
  ```json
  godot_add_audio_bus_config({ "name": "TooFar", "index": 5 })
  ```
- **Expected:** Error (index exceeds bus list bounds). No bus created. OR: appended instead (document actual behavior).

#### TC-3.8: Edge case — index = 0
- **Setup:** Master at index 0.
- **Action:**
  ```json
  godot_add_audio_bus_config({ "name": "BeforeMaster", "index": 0 })
  ```
- **Expected:** Either error (cannot insert before Master) OR bus is inserted at index 0 and Master shifts to index 1. Document actual behavior.

#### TC-3.9: Edge case — negative index
- **Action:**
  ```json
  godot_add_audio_bus_config({ "name": "Negative", "index": -1 })
  ```
- **Expected:** Rejected (Zod `int()` allows negative integers, but the Godot engine should reject). OR: engine appends at end of list. Document actual behavior.

#### TC-3.10: Edge case — empty string name
- **Action:**
  ```json
  godot_add_audio_bus_config({ "name": "" })
  ```
- **Expected:** Should be rejected — bus name cannot be empty. Document whether Zod catches this (Name is just `z.string()`) or Godot engine rejects.

#### TC-3.11: Edge case — non-integer index
- **Action:**
  ```json
  godot_add_audio_bus_config({ "name": "FloatBus", "index": 1.5 })
  ```
- **Expected:** Zod validation error (index must be integer).

#### TC-3.12: Edge case — missing name param
- **Action:**
  ```json
  godot_add_audio_bus_config({ "index": 1 })
  ```
- **Expected:** Zod validation error (name is required).

---

## Tool 4: `godot_remove_audio_bus`

| Field              | Value |
|--------------------|-------|
| **Bridge route**     | `audio_config/remove_bus` |
| **Required params**   | `index` (integer, minimum 1) |

### Parameter Details

| Param   | Type     | Zod Schema                        | Notes |
|---------|----------|-----------------------------------|-------|
| `index` | `number` (integer) | `z.number().int().min(1)` | Bus index to remove. `min(1)` prevents removing Master at index 0. |

### Expected Behavior
- Removes the bus at the specified index from the bus layout.
- All buses after the removed bus shift up by 1.
- **Cannot remove** Master (index 0) — Zod `min(1)` already prevents this at the schema level.
- **If the bus has children** (other buses sending to it via "send" routing), behavior may vary — engine may reassign sends to Master or reject.

### Test Scenarios

#### TC-4.1: Happy path — remove bus at index 1
- **Setup:** Add bus "Music" (at index 1). Layout: Master (0), Music (1).
- **Action:**
  ```json
  godot_remove_audio_bus({ "index": 1 })
  ```
- **Verify:** `godot_get_audio_settings` shows only Master. "Music" is gone.

#### TC-4.2: Happy path — remove middle bus (shift occurs)
- **Setup:** Add "A" at 1, "B" at 2, "C" at 3. Layout: Master, A, B, C.
- **Action:**
  ```json
  godot_remove_audio_bus({ "index": 2 })
  ```
- **Verify:** "B" is removed. Layout is now: Master, A, C. Index 2 now holds "C".

#### TC-4.3: Remove last bus
- **Setup:** Add "A", "B". Layout: Master, A, B.
- **Action:**
  ```json
  godot_remove_audio_bus({ "index": 2 })
  ```
- **Verify:** "B" removed. Layout: Master, A. No crashes, no off-by-one errors.

#### TC-4.4: Remove all user buses one by one
- **Setup:** Add five buses: "B1" through "B5" (all appended).
- **Action:** Call `godot_remove_audio_bus` with index=5, 4, 3, 2, 1 sequentially (working backwards to avoid index shift issues).
- **Verify:** After all calls, only Master remains. No errors.

#### TC-4.5: Edge case — index = 0 (attempt to remove Master)
- **Action:**
  ```json
  godot_remove_audio_bus({ "index": 0 })
  ```
- **Expected:** Zod validation error ("Number must be greater than or equal to 1"). Call never reaches Godot.

#### TC-4.6: Edge case — index out of range (no bus at that index)
- **Setup:** Only Master exists (index 0).
- **Action:**
  ```json
  godot_remove_audio_bus({ "index": 5 })
  ```
- **Expected:** Error from Godot — no bus at index 5.

#### TC-4.7: Edge case — negative index
- **Action:**
  ```json
  godot_remove_audio_bus({ "index": -1 })
  ```
- **Expected:** Zod `min(1)` rejects negative values. Validation error.

#### TC-4.8: Edge case — non-integer index
- **Action:**
  ```json
  godot_remove_audio_bus({ "index": 2.5 })
  ```
- **Expected:** Zod `int()` validation error.

#### TC-4.9: Edge case — missing index param
- **Action:**
  ```json
  godot_remove_audio_bus({})
  ```
- **Expected:** Zod validation error (index is required).

---

## Tool 5: `godot_set_audio_bus_volume`

| Field              | Value |
|--------------------|-------|
| **Bridge route**     | `audio_config/set_bus_volume` |
| **Required params**   | `bus` (string), `volume_db` (number) |

### Parameter Details

| Param        | Type     | Zod Schema                   | Notes |
|--------------|----------|------------------------------|-------|
| `bus`        | `string` | `Name` = `z.string()`        | Bus name (e.g. "Master", "Music", "SFX") |
| `volume_db`  | `number` | `z.number()`                 | Volume in decibels. 0 = normal (0 dB, full volume). Negative = quieter. Positive = louder (may clip). |

### Expected Behavior
- Sets the volume of the specified bus to the given decibel value.
- Volume in Godot audio is in dB. 0 dB = full volume (no attenuation), -80 dB = near-silent.
- Bus name resolution: if bus does not exist, returns an error.
- No Zod constraints on volume range — Godot engine handles clamping.

### Test Scenarios

#### TC-5.1: Happy path — set Master volume to -6 dB
- **Action:**
  ```json
  godot_set_audio_bus_volume({ "bus": "Master", "volume_db": -6 })
  ```
- **Verify:** `godot_get_audio_settings` shows Master volume_db = -6.

#### TC-5.2: Happy path — set user bus volume to 0 dB (default)
- **Setup:** Add bus "Music".
- **Action:**
  ```json
  godot_set_audio_bus_volume({ "bus": "Music", "volume_db": 0 })
  ```
- **Verify:** Music volume_db = 0.

#### TC-5.3: Set volume to various values
- **Actions (sequentially):**
  - `volume_db: -10` → verify -10
  - `volume_db: -79.5` → verify -79.5 (near-silence)
  - `volume_db: -80` → verify -80 (Godot typically floors at -80 dB)
  - `volume_db: 6` → verify 6 (amplification)
- **Verify each:** `godot_get_audio_settings` reflects the correct volume_db for the target bus.

#### TC-5.4: Set volume and then set back to original
- **Setup:** Record Master's current volume.
- **Action:** Set Master volume to -20, then set back to original.
- **Verify:** Final volume equals original.

#### TC-5.5: Set volume on two buses independently
- **Setup:** Add "Music" and "SFX".
- **Action:**
  - Set Music volume_db = -3
  - Set SFX volume_db = -12
- **Verify:** Music = -3, SFX = -12. Master unchanged.

#### TC-5.6: Edge case — bus does not exist
- **Action:**
  ```json
  godot_set_audio_bus_volume({ "bus": "NonExistentBus", "volume_db": -6 })
  ```
- **Expected:** Error from Godot — bus "NonExistentBus" not found.

#### TC-5.7: Edge case — empty bus name
- **Action:**
  ```json
  godot_set_audio_bus_volume({ "bus": "", "volume_db": 0 })
  ```
- **Expected:** Error from Godot (cannot target bus with empty name). OR: Zod/engine rejects with "bus name is required".

#### TC-5.8: Edge case — extreme volume values
- **Action:**
  ```json
  // Very loud (potentially clipping)
  godot_set_audio_bus_volume({ "bus": "Master", "volume_db": 24 })
  // Very quiet (engine min)
  godot_set_audio_bus_volume({ "bus": "Master", "volume_db": -200 })
  ```
- **Verify (loud):** Volume is set to 24 (or clamped — document the engine ceiling).
- **Verify (quiet):** Volume is clamped to Godot's minimum (typically -80 dB).

#### TC-5.9: Edge case — missing required params
- **Actions:**
  - `{ "bus": "Master" }` (missing volume_db)
  - `{ "volume_db": -6 }` (missing bus)
  - `{}` (both missing)
- **Expected:** Each returns Zod validation error.

#### TC-5.10: Edge case — non-numeric volume_db
- **Action:**
  ```json
  godot_set_audio_bus_volume({ "bus": "Master", "volume_db": "loud" })
  ```
- **Expected:** Zod validation error (volume_db must be a number).

---

## Tool 6: `godot_get_audio_bus_effects`

| Field              | Value |
|--------------------|-------|
| **Bridge route**     | `audio_config/get_bus_effects` |
| **Required params**   | `bus` (string) |

### Parameter Details

| Param | Type     | Zod Schema            | Notes |
|-------|----------|------------------------|-------|
| `bus` | `string` | `Name` = `z.string()`  | Bus name to inspect. Must be an existing bus. |

### Expected Response Shape
```jsonc
{
  "bus": "Master",  // or whichever bus was queried
  "effects": [
    // List of effect objects, each with type and properties
    // e.g. { "type": "reverb", "properties": { "room_size": 0.8, "damp": 0.5, /* ... */ } }
  ]
}
```
- If the bus has no effects, `effects` should be an empty array `[]`.
- If the bus does not exist, returns an error.

### Test Scenarios

#### TC-6.1: Happy path — query effects on default Master bus (no effects)
- **Action:**
  ```json
  godot_get_audio_bus_effects({ "bus": "Master" })
  ```
- **Expected:** Returns `effects: []` (Master starts with no effects).

#### TC-6.2: Happy path — query effects on bus with one effect
- **Setup:** Add bus "ReverbBus". Add a reverb effect to it (via `godot_add_audio_bus_effect`).
- **Action:**
  ```json
  godot_get_audio_bus_effects({ "bus": "ReverbBus" })
  ```
- **Expected:** Returns `effects` array with at least one entry of type "reverb". The entry includes effect properties (e.g., `room_size`, `damp`, `wet`, `dry`).

#### TC-6.3: Happy path — query effects on bus with multiple effects
- **Setup:** Add bus "ProcessedBus". Add effects: reverb at index 0, delay at index 1, compressor at index 2.
- **Action:** Call `godot_get_audio_bus_effects` with bus="ProcessedBus".
- **Expected:** Returns 3 effects in order: reverb, delay, compressor. Each has its type and properties.

#### TC-6.4: Query effects after adding then removing an effect
- **Setup:** Add bus "TempBus", add compressor effect, verify it shows in `get_audio_bus_effects`, then remove the effect (via `godot_add_audio_bus_effect` with remove — if such API exists, otherwise via layout reset).
- **Action:** Call `godot_get_audio_bus_effects` again.
- **Expected:** Effects array is empty (or no longer contains the removed effect).

#### TC-6.5: Query effects on all buses in a populated layout
- **Setup:** Set up a layout with 4 buses, each with 1–2 effects of different types.
- **Action:** Call `godot_get_audio_bus_effects` for each bus.
- **Expected:** Each call returns the correct set of effects for that specific bus. No cross-contamination (effects from one bus do not appear on another).

#### TC-6.6: Edge case — bus does not exist
- **Action:**
  ```json
  godot_get_audio_bus_effects({ "bus": "GhostBus" })
  ```
- **Expected:** Error from Godot — bus "GhostBus" does not exist.

#### TC-6.7: Edge case — empty bus name
- **Action:**
  ```json
  godot_get_audio_bus_effects({ "bus": "" })
  ```
- **Expected:** Error (cannot query effects on an empty-named bus).

#### TC-6.8: Edge case — missing bus param
- **Action:**
  ```json
  godot_get_audio_bus_effects({})
  ```
- **Expected:** Zod validation error (bus is required).

#### TC-6.9: Edge case — bus with many effects (e.g., 10–20)
- **Setup:** Add 15 effects to a bus (mix of types: reverb, delay, chorus, compressor, distortion, eq, limiter, panner, pitchshift, filter, lowpass, highpass, bandpass, amplify, stereo).
- **Action:** Call `godot_get_audio_bus_effects`.
- **Expected:** All 15 effects returned in order with their properties. No truncation.

#### TC-6.10: Edge case — bus name with spaces and special characters
- **Action:**
  ```json
  godot_get_audio_bus_effects({ "bus": "Background Music" })
  ```
- **Expected:** Correctly resolves the bus if it exists. Returns effects (or empty array).

---

## Cross-Tool Integration Tests

### CT-1: Full lifecycle — add, configure, query, remove
1. Start with default layout (Master only).
2. `godot_get_audio_settings` → Master bus exists.
3. `godot_add_audio_bus_config({ "name": "Music", "index": 1 })` → Music created at index 1.
4. `godot_add_audio_bus_config({ "name": "SFX" })` → SFX appended at index 2.
5. `godot_set_audio_bus_volume({ "bus": "Music", "volume_db": -4 })` → Music volume set.
6. `godot_set_audio_bus_volume({ "bus": "SFX", "volume_db": -8 })` → SFX volume set.
7. `godot_get_audio_settings` → all 3 buses present with correct volumes.
8. `godot_get_audio_bus_effects({ "bus": "Music" })` → empty effects array.
9. Add effects to Music bus (reverb + compressor).
10. `godot_get_audio_bus_effects({ "bus": "Music" })` → 2 effects listed.
11. `godot_remove_audio_bus({ "index": 2 })` → SFX removed.
12. `godot_get_audio_settings` → Master and Music only.
13. `godot_remove_audio_bus({ "index": 1 })` → Music removed.
14. `godot_get_audio_settings` → Master only.

### CT-2: Layout replacement preserves effects
- **Setup:** Add bus "ReverbBus", add reverb effect to it.
- **Action:** Replace layout with `[{ "name": "Master" }, { "name": "ReverbBus", "volume": -3 }]`.
- **Verify:** Check if the reverb effect on ReverbBus is preserved or wiped. Document actual behavior.

### CT-3: Rapid sequential mutations
- **Action:** Call `godot_add_audio_bus_config` 10 times rapidly, each with a unique name and incrementing index.
- **Verify:** All 10 buses exist in correct order. No race conditions, no dropped mutations.

### CT-4: Set volume on Master to extremes and verify persistence
1. Set Master volume to 0, verify.
2. Set Master volume to -80, verify.
3. Set Master volume to 24, verify.
4. Set Master volume to 0, verify — returns to default.

---

## Schema Validation Table (Zod)

| Tool                        | Param         | Zod Schema                                    | Validates             |
|-----------------------------|---------------|-----------------------------------------------|-----------------------|
| `get_audio_settings`        | (none)        | `{}`                                          | N/A                   |
| `set_audio_bus_layout`      | `buses`       | `z.array(z.object({...}))`                    | Must be array of objects |
|                             | `buses[i].name` | `z.string()`                                | Must be string        |
|                             | `buses[i].volume` | `z.number().optional()`                    | Optional number       |
|                             | `buses[i].solo`   | `z.boolean().optional()`                  | Optional boolean      |
|                             | `buses[i].mute`   | `z.boolean().optional()`                  | Optional boolean      |
| `add_audio_bus_config`      | `name`        | `z.string()` (via `Name`)                     | Must be string        |
|                             | `index`       | `z.number().int().optional()`                 | Optional integer      |
| `remove_audio_bus`          | `index`       | `z.number().int().min(1)`                     | Integer ≥ 1           |
| `set_audio_bus_volume`      | `bus`         | `z.string()`                                  | Must be string        |
|                             | `volume_db`   | `z.number()`                                  | Must be number        |
| `get_audio_bus_effects`     | `bus`         | `z.string()`                                  | Must be string        |

---

## Notes / Caveats

1. **Zod `Name` = `z.string()` without min/max/pattern constraints.** This means empty strings (`""`) pass Zod validation and will cause errors at the Godot engine level. The test plan covers this (e.g., TC-3.10, TC-5.7, TC-6.7).

2. **`remove_audio_bus` index is 0-based** (Master = 0, first added bus = 1). Zod `min(1)` correctly prevents Master removal at schema level.

3. **`add_audio_bus_config` index semantics:** The Zod schema allows negative integers and non-sequential indices. The Godot engine's actual behavior for these edge cases must be verified during testing.

4. **`set_audio_bus_layout` is destructive.** It replaces the entire layout. All effects on buses that are NOT in the new layout will be lost. Testers should verify this behavior is intentional and well-documented.

5. **There exists a separate `audio.ts` module** with tools like `godot_add_audio_bus`, `godot_set_audio_bus`, `godot_add_audio_bus_effect`, `godot_add_audio_player`, `godot_get_audio_info`, `godot_remove_audio_player`. Some integration scenarios may require those tools as setup helpers. This test plan focuses exclusively on the 6 tools in `audio_config.ts`.

6. **Platform differences:** Audio driver info returned by `get_audio_settings` varies by OS (WASAPI on Windows, PulseAudio/ALSA on Linux, CoreAudio on macOS, Dummy if no audio). Tests should not assert specific driver values.
