# Test Plan: Audio Configuration Tools (`audio_config.ts`)

> **File under test**: `server/src/tools/audio_config.ts`  
> **Godot handler**: `addons/godot_mcp/commands/audio_config_commands.gd`  
> **Total tools**: 6  
> **Dependencies**: `shared-types.ts` (re-exports `z` from Zod, `Name = z.string().describe('Name identifier')`)

---

## Architecture Notes

- All tools call `callGodot(bridge, method, params)` which sends a JSON-RPC request over WebSocket to the Godot editor plugin.
- Each tool returns `ToolResult = { content: [{ type: 'text', text: string }], isError?: boolean }`.
- Success responses contain JSON with `"success": true` plus result data.
- Error responses contain `"success": false` plus `"error"` string.
- The `Master` bus (index 0) is always present and cannot be removed.
- Bus names are unique — duplicates are rejected by `add_bus_config`.
- `set_audio_bus_layout` is a destructive replacement — it wipes all non-Master buses first.

---

## Pre-conditions for All Tests

1. Godot editor is running with the MCP plugin active and connected.
2. A scene is open (any scene — audio bus layout is project-global, not scene-specific).
3. Audio buses start in default state: only `Master` bus exists (index 0).

---

## Tool: `get_audio_settings`

**Description**: Get all audio settings including bus layout, default bus, and driver info  
**Parameters**: None (empty `inputSchema`)  
**Backend method**: `audio_config/get_settings`  
**Returns**: `{ success: true, settings: { driver, mix_rate, output_latency, bus_count, buses, default_bus } }`

### Test Scenarios

#### Scenario 1: Basic happy path — get default audio settings

**Description**: Call with no arguments on a fresh project. Should return all audio settings with only the Master bus.  
**Params**: `{}`  
**Expected result**:
```json
{
  "success": true,
  "settings": {
    "driver": "<string, e.g. 'Dummy' or 'WASAPI'>",
    "mix_rate": "<number, e.g. 44100 or 48000>",
    "output_latency": "<number >= 0>",
    "bus_count": 1,
    "buses": [
      {
        "name": "Master",
        "volume_db": 0.0,
        "solo": false,
        "mute": false,
        "effects": []
      }
    ],
    "default_bus": "Master"
  }
}
```
**Notes**: `driver` and `mix_rate` values depend on the OS and Godot project settings.  
**What to pay attention to**: `bus_count` must equal `buses.length`. `default_bus` is read from `ProjectSettings` and defaults to `"Master"`.

#### Scenario 2: Get settings after adding custom buses

**Description**: After adding buses "Music" and "SFX" (via `add_audio_bus_config`), call `get_audio_settings` to verify they appear in the layout.  
**Prerequisites**: Call `add_audio_bus_config` with `{ "name": "Music" }` and `{ "name": "SFX" }` first.  
**Params**: `{}`  
**Expected result**:
```json
{
  "success": true,
  "settings": {
    "bus_count": 3,
    "buses": [
      { "name": "Master", ... },
      { "name": "Music", ... },
      { "name": "SFX", ... }
    ],
    ...
  }
}
```
**What to pay attention to**: Buses should appear in the order they were added. Each bus entry should contain `name`, `volume_db`, `solo`, `mute`, and `effects` fields.

---

## Tool: `set_audio_bus_layout`

**Description**: Replace the entire audio bus layout with the given bus definitions  
**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `buses` | `Array<{ name: string, volume?: number, solo?: boolean, mute?: boolean }>` | Yes | Ordered list of audio buses (first is always 'Master') |

**Backend method**: `audio_config/set_bus_layout`  
**Returns**: `{ success: true, bus_count: <int>, message: "Bus layout replaced" }`

### Test Scenarios

#### Scenario 1: Replace layout with minimal bus definitions (names only)

**Description**: Replace the layout with two buses using only required `name` fields.  
**Params**:
```json
{
  "buses": [
    { "name": "Master" },
    { "name": "Music" }
  ]
}
```
**Expected result**:
```json
{
  "success": true,
  "bus_count": 2,
  "message": "Bus layout replaced"
}
```
**Notes**: After this call, `get_audio_settings` should show exactly 2 buses. Music bus should have default volume (0 dB), no solo, no mute.  
**What to pay attention to**: The first bus entry reconfigures the existing Master bus — its `name` field sets the Master bus name. If `name` is omitted from the first entry, Master keeps its default name.

#### Scenario 2: Replace layout with full property specification

**Description**: Set up a three-bus layout with volume, solo, and mute overrides.  
**Params**:
```json
{
  "buses": [
    { "name": "Master", "volume": -3.0 },
    { "name": "Music", "volume": -6.0, "solo": false, "mute": false },
    { "name": "SFX", "volume": 0.0, "mute": true }
  ]
}
```
**Expected result**:
```json
{
  "success": true,
  "bus_count": 3,
  "message": "Bus layout replaced"
}
```
**Notes**: Verify with `get_audio_settings` that: Master volume is -3 dB, Music volume is -6 dB, SFX is muted.  
**What to pay attention to**: `volume` is in dB (0 = normal, negative = quieter). The `solo` field on a single bus with no other soloed buses may not have audible effect but should still be stored.

#### Scenario 3: Error — empty buses array

**Description**: Pass an empty array. The backend explicitly rejects this.  
**Params**:
```json
{
  "buses": []
}
```
**Expected result**:
```json
{
  "success": false,
  "error": "Buses list cannot be empty"
}
```
**What to pay attention to**: The `isError` field on the ToolResult should be `true` (since the GDScript returns an error dict, and `callGodot` does not set `isError` — the error is in the JSON text). Verify the error message matches exactly.

#### Scenario 4: Single-bus layout (only Master)

**Description**: Replace with just one bus — effectively reset to default.  
**Params**:
```json
{
  "buses": [
    { "name": "Master", "volume": 0.0, "solo": false, "mute": false }
  ]
}
```
**Expected result**:
```json
{
  "success": true,
  "bus_count": 1,
  "message": "Bus layout replaced"
}
```
**What to pay attention to**: All previously added non-Master buses should be removed. `bus_count` must be exactly 1.

#### Scenario 5: Replace layout removes all previous buses

**Description**: First add buses "Music" and "SFX", then replace layout with only "Master" and "Ambient". Verify "Music" and "SFX" are gone.  
**Prerequisites**: `add_audio_bus_config({ "name": "Music" })`, `add_audio_bus_config({ "name": "SFX" })`  
**Params**:
```json
{
  "buses": [
    { "name": "Master" },
    { "name": "Ambient" }
  ]
}
```
**Expected result**: `success: true`, `bus_count: 2`  
**Follow-up**: Call `get_audio_settings` and verify buses list contains only "Master" and "Ambient".  
**What to pay attention to**: This confirms the destructive nature of `set_audio_bus_layout` — previous buses are wiped.

---

## Tool: `add_audio_bus_config`

**Description**: Add a new audio bus at a specific position  
**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | `string` (via `Name` schema) | Yes | Bus name |
| `index` | `number` (integer) | No | Position in bus list (omit to append at end) |

**Backend method**: `audio_config/add_bus_config`  
**Returns**: `{ success: true, name: <string>, index: <int>, total: <int> }`

### Test Scenarios

#### Scenario 1: Add bus at end (no index specified)

**Description**: Add a bus without specifying index — it should be appended.  
**Params**:
```json
{ "name": "Music" }
```
**Expected result**:
```json
{
  "success": true,
  "name": "Music",
  "index": 1,
  "total": 2
}
```
**Notes**: On a fresh project with only Master, the new bus gets index 1.  
**What to pay attention to**: `index` in the result should be the actual position where the bus was inserted. `total` is the new `AudioServer.bus_count`.

#### Scenario 2: Add bus at specific index

**Description**: Insert a bus at position 1 (between Master and any existing bus).  
**Prerequisites**: Have at least one other non-Master bus already (e.g., "SFX" at index 1).  
**Params**:
```json
{ "name": "Music", "index": 1 }
```
**Expected result**:
```json
{
  "success": true,
  "name": "Music",
  "index": 1,
  "total": 3
}
```
**Notes**: The previously existing bus at index 1 should shift to index 2.  
**What to pay attention to**: The `index` parameter is `z.number().int().optional()` — the schema enforces integer. A float like `1.5` should be rejected by Zod validation before reaching Godot.

#### Scenario 3: Error — duplicate bus name

**Description**: Try to add a bus with a name that already exists.  
**Prerequisites**: A bus named "Music" already exists.  
**Params**:
```json
{ "name": "Music" }
```
**Expected result**:
```json
{
  "success": false,
  "error": "Bus already exists: Music"
}
```
**What to pay attention to**: The GDScript implementation checks all existing bus names case-sensitively.

#### Scenario 4: Error — empty bus name

**Description**: Pass an empty string as bus name.  
**Params**:
```json
{ "name": "" }
```
**Expected result**:
```json
{
  "success": false,
  "error": "Bus name is required"
}
```
**What to pay attention to**: The GDScript checks `bus_name.is_empty()`. An empty string `""` is valid Zod-wise (it's a string) but rejected by the handler.

#### Scenario 5: Add multiple buses and verify order

**Description**: Add "Music", then "SFX", then "Ambient" — verify they appear in insertion order.  
**Params** (three sequential calls):
```json
{ "name": "Music" }
{ "name": "SFX" }
{ "name": "Ambient" }
```
**Expected results**: Indices 1, 2, 3 respectively.  
**Follow-up**: Call `get_audio_settings` and verify `buses` array order: Master (0), Music (1), SFX (2), Ambient (3).  
**What to pay attention to**: Bus ordering is significant in Godot's audio system — effects and sends chain in order.

---

## Tool: `remove_audio_bus`

**Description**: Remove an audio bus by index (cannot remove Master at index 0)  
**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `index` | `number` (integer, min 1) | Yes | Bus index to remove (1+, cannot remove Master) |

**Backend method**: `audio_config/remove_bus`  
**Returns**: `{ success: true, removed: <string>, index: <int>, total: <int> }`

### Test Scenarios

#### Scenario 1: Happy path — remove a non-Master bus

**Description**: Add a bus "Music", then remove it by index.  
**Prerequisites**: `add_audio_bus_config({ "name": "Music" })` → gets index 1.  
**Params**:
```json
{ "index": 1 }
```
**Expected result**:
```json
{
  "success": true,
  "removed": "Music",
  "index": 1,
  "total": 1
}
```
**What to pay attention to**: `total` after removal should be 1 (only Master remains). `removed` should contain the name of the bus that was at that index.

#### Scenario 2: Error — try to remove Master (index 0)

**Description**: Attempt to remove the Master bus. The schema enforces `min(1)`, so Zod should reject this at validation time.  
**Params**:
```json
{ "index": 0 }
```
**Expected result**: Zod validation error — the request should not reach Godot. The MCP SDK should return a validation error before the handler is called.  
**What to pay attention to**: The Zod schema is `z.number().int().min(1)`, so `0` fails validation. If somehow it does reach GDScript, the handler also checks `at_index < 1` and returns an error.

#### Scenario 3: Error — index out of range

**Description**: Try to remove a bus at an index that doesn't exist.  
**Params** (assuming only Master exists, bus_count = 1):
```json
{ "index": 5 }
```
**Expected result**:
```json
{
  "success": false,
  "error": "Index out of range: 5 (bus count: 1)"
}
```
**What to pay attention to**: The error message includes both the requested index and current bus count. The GDScript checks `at_index >= AudioServer.bus_count`.

#### Scenario 4: Remove shifts subsequent buses

**Description**: Have buses [Master, Music, SFX, Ambient]. Remove Music (index 1). Verify SFX and Ambient shift down.  
**Prerequisites**: Set up layout via `set_audio_bus_layout` or sequential `add_audio_bus_config` calls.  
**Params**:
```json
{ "index": 1 }
```
**Expected result**: `success: true`, `removed: "Music"`, `total: 3`  
**Follow-up**: Call `get_audio_settings` and verify buses are now [Master, SFX, Ambient] at indices [0, 1, 2].  
**What to pay attention to**: Godot's `AudioServer.remove_bus()` shifts subsequent bus indices down by 1. This is critical for any workflow that removes a bus and then references others by index.

---

## Tool: `set_audio_bus_volume`

**Description**: Set the volume of a specific audio bus  
**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `bus` | `string` (via `Name` schema) | Yes | Bus name (e.g. 'Master', 'Music', 'SFX') |
| `volume_db` | `number` | Yes | Volume in decibels (0 = normal, negative = quieter) |

**Backend method**: `audio_config/set_bus_volume`  
**Returns**: `{ success: true, bus: <string>, volume_db: <number> }`

### Test Scenarios

#### Scenario 1: Set Master volume to -6 dB

**Description**: Reduce Master volume.  
**Params**:
```json
{ "bus": "Master", "volume_db": -6.0 }
```
**Expected result**:
```json
{
  "success": true,
  "bus": "Master",
  "volume_db": -6.0
}
```
**What to pay attention to**: The returned `volume_db` should match the input exactly. Verify with `get_audio_settings` that the Master bus `volume_db` is now -6.0.

#### Scenario 2: Set volume to 0 dB (default/normal)

**Description**: Reset volume to normal level.  
**Params**:
```json
{ "bus": "Master", "volume_db": 0 }
```
**Expected result**:
```json
{
  "success": true,
  "bus": "Master",
  "volume_db": 0
}
```

#### Scenario 3: Set positive volume (amplification)

**Description**: Boost volume above normal.  
**Params**:
```json
{ "bus": "Master", "volume_db": 6.0 }
```
**Expected result**:
```json
{
  "success": true,
  "bus": "Master",
  "volume_db": 6.0
}
```
**Notes**: Positive dB values amplify the signal. Godot allows this but it may cause clipping.  
**What to pay attention to**: The schema has no upper/lower bounds on `volume_db` — any `z.number()` is accepted. Extremely large values (e.g., 100.0) should still be accepted by the tool (Godot handles clamping internally).

#### Scenario 4: Error — bus name not found

**Description**: Reference a non-existent bus.  
**Params**:
```json
{ "bus": "NonExistentBus", "volume_db": -10.0 }
```
**Expected result**:
```json
{
  "success": false,
  "error": "Bus not found: NonExistentBus"
}
```
**What to pay attention to**: The GDScript uses `MCPCommandHelpers.find_bus_index()` which returns -1 for unknown names. The error is case-sensitive — "master" ≠ "Master".

#### Scenario 5: Error — empty bus name

**Description**: Pass empty string as bus name.  
**Params**:
```json
{ "bus": "", "volume_db": -6.0 }
```
**Expected result**:
```json
{
  "success": false,
  "error": "Bus name is required"
}
```
**What to pay attention to**: The GDScript checks `bus_name.is_empty()` before looking up the bus index.

#### Scenario 6: Set volume on a custom bus

**Description**: After adding "Music" bus, set its volume.  
**Prerequisites**: `add_audio_bus_config({ "name": "Music" })`  
**Params**:
```json
{ "bus": "Music", "volume_db": -12.0 }
```
**Expected result**:
```json
{
  "success": true,
  "bus": "Music",
  "volume_db": -12.0
}
```

---

## Tool: `get_audio_bus_effects`

**Description**: Get all effects on a specific audio bus with their properties  
**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `bus` | `string` (via `Name` schema) | Yes | Bus name to inspect |

**Backend method**: `audio_config/get_bus_effects`  
**Returns**: `{ success: true, bus: <string>, effects: Array<{ index, type, enabled, properties }>, count: <int> }`

### Test Scenarios

#### Scenario 1: Get effects on Master bus (default — no effects)

**Description**: On a fresh project, Master bus has no effects.  
**Params**:
```json
{ "bus": "Master" }
```
**Expected result**:
```json
{
  "success": true,
  "bus": "Master",
  "effects": [],
  "count": 0
}
```
**What to pay attention to**: `count` must equal `effects.length`. Even with no effects, the response should include all three fields.

#### Scenario 2: Get effects on a bus that has effects

**Description**: After adding effects to a bus (via `add_audio_bus_effect` from `audio.ts`), inspect the bus.  
**Prerequisites**: Call `add_audio_bus` → `add_audio_bus_effect({ "bus_name": "Music", "effect_type": "reverb" })`  
**Params**:
```json
{ "bus": "Music" }
```
**Expected result**:
```json
{
  "success": true,
  "bus": "Music",
  "effects": [
    {
      "index": 0,
      "type": "AudioEffectReverb",
      "enabled": true,
      "properties": {
        "...reverb-specific properties..."
      }
    }
  ],
  "count": 1
}
```
**Notes**: The `type` field contains the Godot class name (e.g., `AudioEffectReverb`, `AudioEffectDelay`), not the short name used in `add_audio_bus_effect`. The `properties` dict contains serializable properties filtered to exclude `resource_*` and `script*` prefixed keys.  
**What to pay attention to**: The `enabled` field reflects `AudioServer.is_bus_effect_enabled()`. Effects can be disabled but still present.

#### Scenario 3: Get effects on multiple-effects bus

**Description**: A bus with reverb + delay should list both in order.  
**Prerequisites**: Add "Music" bus, then add reverb at index 0 and delay at index 1.  
**Params**:
```json
{ "bus": "Music" }
```
**Expected result**:
```json
{
  "success": true,
  "bus": "Music",
  "effects": [
    { "index": 0, "type": "AudioEffectReverb", "enabled": true, "properties": {...} },
    { "index": 1, "type": "AudioEffectDelay", "enabled": true, "properties": {...} }
  ],
  "count": 2
}
```
**What to pay attention to**: Effect ordering matters in Godot's audio pipeline. The `index` field in each effect entry corresponds to its position on the bus.

#### Scenario 4: Error — bus not found

**Description**: Reference a non-existent bus name.  
**Params**:
```json
{ "bus": "GhostBus" }
```
**Expected result**:
```json
{
  "success": false,
  "error": "Bus not found: GhostBus. Available: Master"
}
```
**What to pay attention to**: The error message from `get_bus_effects` includes a list of available bus names — this is unique to this tool. Other tools (`set_bus_volume`) do not include available names in their error.

#### Scenario 5: Error — empty bus name

**Description**: Pass empty string.  
**Params**:
```json
{ "bus": "" }
```
**Expected result**:
```json
{
  "success": false,
  "error": "Bus name is required"
}
```

---

## Cross-Tool Workflow: Full Audio Setup

This section describes a realistic multi-step workflow that exercises all 6 tools in sequence.

### Workflow: Set up a game audio bus layout

**Step 1** — Get current state:
```
get_audio_settings → { buses: [Master], bus_count: 1 }
```

**Step 2** — Replace layout with game buses:
```
set_audio_bus_layout({
  "buses": [
    { "name": "Master", "volume": 0.0 },
    { "name": "Music", "volume": -6.0 },
    { "name": "SFX", "volume": 0.0 },
    { "name": "Voice", "volume": 3.0 }
  ]
})
→ { success: true, bus_count: 4 }
```

**Step 3** — Verify layout:
```
get_audio_settings → { bus_count: 4, buses: [Master, Music, SFX, Voice] }
```

**Step 4** — Add an ambient bus at position 2 (between Music and SFX):
```
add_audio_bus_config({ "name": "Ambient", "index": 2 })
→ { success: true, name: "Ambient", index: 2, total: 5 }
```

**Step 5** — Verify insertion shifted SFX and Voice:
```
get_audio_settings → buses: [Master(0), Music(1), Ambient(2), SFX(3), Voice(4)]
```

**Step 6** — Set Music volume to -12 dB:
```
set_audio_bus_volume({ "bus": "Music", "volume_db": -12.0 })
→ { success: true, bus: "Music", volume_db: -12.0 }
```

**Step 7** — Remove the Ambient bus:
```
remove_audio_bus({ "index": 2 })
→ { success: true, removed: "Ambient", index: 2, total: 4 }
```

**Step 8** — Verify SFX and Voice shifted back:
```
get_audio_settings → buses: [Master(0), Music(1), SFX(2), Voice(3)]
```

**Step 9** — Check effects on Master (should be empty):
```
get_audio_bus_effects({ "bus": "Master" })
→ { success: true, effects: [], count: 0 }
```

**Step 10** — Reset to single-bus layout:
```
set_audio_bus_layout({ "buses": [{ "name": "Master" }] })
→ { success: true, bus_count: 1 }
```

**What to pay attention to**: The critical thing in this workflow is index stability after insert/remove operations. After `add_audio_bus_config` at a specific index, all subsequent buses shift right. After `remove_audio_bus`, all subsequent buses shift left. Any tool that references buses by name (not index) is unaffected, but index-based tools must account for this.

---

## Schema Validation Edge Cases

These scenarios test Zod input validation on the TypeScript side, before the request reaches Godot.

### `set_audio_bus_layout`

| Input | Expected |
|-------|----------|
| `{ "buses": "not-an-array" }` | Zod error: expected array |
| `{ "buses": [{ "name": 123 }] }` | Zod error: expected string for name |
| `{ "buses": [{ "volume": "loud" }] }` | Zod error: expected number for volume (name is still required in the object) |
| `{ "buses": [{ "name": "X", "solo": "yes" }] }` | Zod error: expected boolean for solo |
| `{ "buses": [{ "name": "X", "mute": 1 }] }` | Zod error: expected boolean for mute |
| `{}` (missing buses) | Zod error: required |

### `add_audio_bus_config`

| Input | Expected |
|-------|----------|
| `{}` | Zod error: `name` is required |
| `{ "name": "X", "index": 1.5 }` | Zod error: expected integer for index |
| `{ "name": "X", "index": -1 }` | Accepted by Zod (no min constraint on index). GDScript handles: `add_bus(-1)` may behave unexpectedly — test and document the actual Godot behavior. |

### `remove_audio_bus`

| Input | Expected |
|-------|----------|
| `{}` | Zod error: `index` is required |
| `{ "index": -1 }` | Zod error: min(1) constraint |
| `{ "index": 0 }` | Zod error: min(1) constraint |
| `{ "index": "one" }` | Zod error: expected number |

### `set_audio_bus_volume`

| Input | Expected |
|-------|----------|
| `{}` | Zod error: both `bus` and `volume_db` required |
| `{ "bus": "Master" }` | Zod error: `volume_db` required |
| `{ "volume_db": -6 }` | Zod error: `bus` required |
| `{ "bus": "Master", "volume_db": "loud" }` | Zod error: expected number |

### `get_audio_bus_effects`

| Input | Expected |
|-------|----------|
| `{}` | Zod error: `bus` required |

---

## Notes on Related Tools (from `audio.ts`)

The following tools in `audio.ts` interact with the same audio bus system and are relevant as **setup/teardown helpers** for testing `audio_config.ts` tools:

| Tool | File | Relevance |
|------|------|-----------|
| `add_audio_bus` | `audio.ts` | Adds a bus (simpler than `add_audio_bus_config` — no index param). Can be used as setup. |
| `set_audio_bus` | `audio.ts` | Configures bus properties (volume, mute, solo, bypass, send). Overlaps with `set_audio_bus_volume` but more general. |
| `add_audio_bus_effect` | `audio.ts` | Adds effects to a bus — required to test `get_audio_bus_effects` with non-empty effects. |
| `get_audio_bus_layout` | `audio.ts` | Returns full bus layout with effects — similar to `get_audio_settings` but focused on layout only. |
| `add_audio_player` | `audio.ts` | Adds audio player nodes to the scene — uses bus names for playback routing. |

**Important**: `add_audio_bus` (from `audio.ts`) and `add_audio_bus_config` (from `audio_config.ts`) both add buses but `add_audio_bus_config` supports the `index` parameter for insertion position. Use the appropriate one based on whether ordering matters.
