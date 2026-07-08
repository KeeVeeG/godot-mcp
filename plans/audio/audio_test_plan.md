# Audio Tools — Test Plan

**Source:** `server/src/tools/audio.ts`  
**Shared types:** `server/src/tools/shared-types.ts`  
**Bridge route prefix:** `audio/`

---

## Shared Type Definitions

From `shared-types.ts`, the following Zod schemas are used:

| Import | Type | Description |
|--------|------|-------------|
| `NodePath` | `z.string()` | Node path in scene tree, e.g. `'Player/Sprite2D'` |
| `ParentPath` | `z.string()` | Parent node path; `''` for scene root, or `'Player'` / `'Player/Sprites'` for children |
| `Name` | `z.string()` | Generic name identifier |
| `Properties` | `z.record(z.unknown())` | Required property key-value pairs |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | Optional property key-value pairs |

---

## Tool: `add_audio_player`

**Description:** Add an AudioStreamPlayer, AudioStreamPlayer2D, or AudioStreamPlayer3D node  
**Bridge route:** `audio/add_player`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `parent` | `string` (ParentPath) | **Yes** | — | Parent node — `''` for scene root |
| `player_type` | `enum` | No | `'AudioStreamPlayer'` | `AudioStreamPlayer`, `AudioStreamPlayer2D`, `AudioStreamPlayer3D` |
| `name` | `string` | No | — | Custom node name |
| `stream_path` | `string` | No | — | Audio stream resource path, e.g. `'res://sounds/music.ogg'` |
| `properties` | `record` | No | — | Additional player properties (volume_db, autoplay, bus, etc.) |

### Handler Logic

Calls `bridge` → `callGodot` with route `audio/add_player` and all args. The Godot plugin creates the specified audio player node as a child of `parent`, optionally named, optionally assigned a stream resource, and optionally configured with additional properties.

### Test Scenarios

#### Scenario 1: Minimum required params — add default AudioStreamPlayer to scene root
- **Description:** Add a plain AudioStreamPlayer to the scene root with only the required `parent` param.
- **Params:**
  ```json
  { "parent": "" }
  ```
- **Expected result:** An `AudioStreamPlayer` node is created at scene root. Returns success confirmation with node path/name.
- **Notes:** Defaults: `player_type` → `AudioStreamPlayer`, no stream, no custom name.

#### Scenario 2: Add AudioStreamPlayer to a named parent
- **Description:** Add an audio player as a child of a specific existing node (e.g. `'Player'`).
- **Params:**
  ```json
  { "parent": "Player" }
  ```
- **Expected result:** An `AudioStreamPlayer` node is created as a child of the `Player` node.
- **Notes:** Parent must exist in the scene.

#### Scenario 3: Add AudioStreamPlayer to a nested parent path
- **Description:** Add an audio player as a child of a deeply nested node.
- **Params:**
  ```json
  { "parent": "Player/Sprites/Effects" }
  ```
- **Expected result:** An `AudioStreamPlayer` node is created under `Player/Sprites/Effects`.
- **Notes:** Entire parent path must exist.

#### Scenario 4: Explicit player_type = `AudioStreamPlayer`
- **Description:** Explicitly request the default player type.
- **Params:**
  ```json
  { "parent": "", "player_type": "AudioStreamPlayer" }
  ```
- **Expected result:** An `AudioStreamPlayer` node is created at scene root.
- **Notes:** Verifies the enum value is accepted.

#### Scenario 5: player_type = `AudioStreamPlayer2D`
- **Description:** Add a 2D audio player.
- **Params:**
  ```json
  { "parent": "", "player_type": "AudioStreamPlayer2D" }
  ```
- **Expected result:** An `AudioStreamPlayer2D` node is created at scene root.
- **Notes:** Must create a 2D player, not 3D.

#### Scenario 6: player_type = `AudioStreamPlayer3D`
- **Description:** Add a 3D audio player.
- **Params:**
  ```json
  { "parent": "", "player_type": "AudioStreamPlayer3D" }
  ```
- **Expected result:** An `AudioStreamPlayer3D` node is created at scene root.
- **Notes:** Must create a 3D player.

#### Scenario 7: Invalid player_type
- **Description:** Pass a value not in the enum.
- **Params:**
  ```json
  { "parent": "", "player_type": "AudioStreamPlayer4D" }
  ```
- **Expected result:** Error — Zod validation fails; invalid enum value.
- **Notes:** Enum is strict; only the 3 values are accepted.

#### Scenario 8: With custom name
- **Description:** Provide a custom node name.
- **Params:**
  ```json
  { "parent": "", "name": "MyMusicPlayer" }
  ```
- **Expected result:** An `AudioStreamPlayer` named `MyMusicPlayer` is created.
- **Notes:** Name should not conflict with existing siblings.

#### Scenario 9: With stream_path
- **Description:** Provide a path to an audio resource.
- **Params:**
  ```json
  { "parent": "", "stream_path": "res://sounds/music.ogg" }
  ```
- **Expected result:** An `AudioStreamPlayer` is created with its `stream` property set to the resource at the given path.
- **Notes:** Stream path may or may not exist on disk — behavior depends on Godot plugin.

#### Scenario 10: With properties — volume_db and autoplay
- **Description:** Set multiple player properties at creation time.
- **Params:**
  ```json
  {
    "parent": "",
    "properties": {
      "volume_db": -6.0,
      "autoplay": true,
      "bus": "Music"
    }
  }
  ```
- **Expected result:** An `AudioStreamPlayer` is created with volume set to -6 dB, autoplay enabled, and routed to the `Music` bus.
- **Notes:** `bus` must be a valid bus name.

#### Scenario 11: With all optional params
- **Description:** Provide every optional parameter simultaneously.
- **Params:**
  ```json
  {
    "parent": "",
    "player_type": "AudioStreamPlayer2D",
    "name": "SFXPlayer",
    "stream_path": "res://sounds/explosion.wav",
    "properties": {
      "volume_db": 0.0,
      "autoplay": false,
      "bus": "SFX"
    }
  }
  ```
- **Expected result:** An `AudioStreamPlayer2D` named `SFXPlayer` is created with the specified stream, properties, and bus routing.
- **Notes:** Integration smoke test.

#### Scenario 12: Missing required `parent`
- **Description:** Omit the required `parent` param entirely.
- **Params:**
  ```json
  {}
  ```
- **Expected result:** Error — Zod validation fails; `parent` is required.

#### Scenario 13: Empty string for name
- **Description:** Pass an empty string as `name`.
- **Params:**
  ```json
  { "parent": "", "name": "" }
  ```
- **Expected result:** Behavior depends on Godot plugin — may create a default-named node or reject the empty name.
- **Notes:** Edge case for empty string on optional string field.

#### Scenario 14: Empty string for stream_path
- **Description:** Pass an empty string as `stream_path`.
- **Params:**
  ```json
  { "parent": "", "stream_path": "" }
  ```
- **Expected result:** Behavior depends on Godot — likely creates node without a stream assigned.
- **Notes:** Edge case for empty string on optional string field.

---

## Tool: `remove_audio_player`

**Description:** Remove an audio player node from the scene  
**Bridge route:** `audio/remove_player`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `string` (NodePath) | **Yes** | — | Path to the audio player node to remove |

### Handler Logic

Calls `bridge` → `callGodot` with route `audio/remove_player` and `{ node_path }`. The Godot plugin removes the audio player node at the given path.

### Test Scenarios

#### Scenario 1: Remove a top-level audio player
- **Description:** Remove an audio player that is a direct child of the scene root.
- **Params:**
  ```json
  { "node_path": "AudioStreamPlayer" }
  ```
- **Expected result:** The node `AudioStreamPlayer` is removed from the scene. Returns success.
- **Notes:** Node must exist.

#### Scenario 2: Remove a nested audio player
- **Description:** Remove an audio player at a nested path.
- **Params:**
  ```json
  { "node_path": "Player/AudioStreamPlayer2D" }
  ```
- **Expected result:** The nested node is removed. Returns success.
- **Notes:** Full path must be valid.

#### Scenario 3: Remove a specifically-named audio player
- **Description:** Remove an audio player with a custom name.
- **Params:**
  ```json
  { "node_path": "MyMusicPlayer" }
  ```
- **Expected result:** `MyMusicPlayer` is removed.
- **Notes:** Name must match exactly.

#### Scenario 4: Remove non-existent node
- **Description:** Try to remove a node that does not exist.
- **Params:**
  ```json
  { "node_path": "NonExistentPlayer" }
  ```
- **Expected result:** Error — node not found.
- **Notes:** Error message should indicate the node doesn't exist.

#### Scenario 5: Missing required `node_path`
- **Description:** Omit the required `node_path`.
- **Params:**
  ```json
  {}
  ```
- **Expected result:** Error — Zod validation fails; `node_path` is required.

---

## Tool: `add_audio_bus`

**Description:** Add a new audio bus to the audio bus layout  
**Bridge route:** `audio/add_bus`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | `string` (Name) | **Yes** | — | Bus name |
| `index` | `number` (int) | No | — | Position in bus list |

### Handler Logic

Calls `bridge` → `callGodot` with route `audio/add_bus`. Adds a new audio bus with the given name at the specified index (or appended if no index). The Godot plugin calls `AudioServer.add_bus(index)` or equivalent.

### Test Scenarios

#### Scenario 1: Add a bus with only name (no index)
- **Description:** Add a new bus with just a name; should append to the end.
- **Params:**
  ```json
  { "name": "Music" }
  ```
- **Expected result:** A new bus named `Music` is appended to the bus layout. Returns success with bus index.
- **Notes:** Minimal required params.

#### Scenario 2: Add a bus at a specific index
- **Description:** Insert a bus at position 1 (after Master, before existing buses).
- **Params:**
  ```json
  { "name": "SFX", "index": 1 }
  ```
- **Expected result:** A new bus named `SFX` is inserted at index 1. Existing buses shift right.
- **Notes:** Index must be valid (≥ 1, since Master is index 0).

#### Scenario 3: Add a bus at index 0
- **Description:** Attempt to insert a bus at the Master bus position.
- **Params:**
  ```json
  { "name": "Override", "index": 0 }
  ```
- **Expected result:** Likely error — cannot replace Master bus at index 0.
- **Notes:** Validate that index 0 is handled correctly.

#### Scenario 4: Add a bus at a very large index
- **Description:** Pass an index beyond the current bus count.
- **Params:**
  ```json
  { "name": "FarBus", "index": 999 }
  ```
- **Expected result:** Behavior depends on Godot — may append to end or error.
- **Notes:** Boundary condition.

#### Scenario 5: Add a bus with a negative index
- **Description:** Pass a negative index.
- **Params:**
  ```json
  { "name": "BadBus", "index": -1 }
  ```
- **Expected result:** Error — negative index is invalid.
- **Notes:** `z.number().int()` allows negative values; Godot should reject.

#### Scenario 6: Add a bus with a name that already exists
- **Description:** Try to add a bus with the same name as an existing bus.
- **Params:**
  ```json
  { "name": "Master" }
  ```
- **Expected result:** Error — duplicate bus name.
- **Notes:** Bus names must be unique.

#### Scenario 7: Missing required `name`
- **Description:** Omit the required `name` param.
- **Params:**
  ```json
  {}
  ```
- **Expected result:** Error — Zod validation fails; `name` is required.

#### Scenario 8: Non-integer index
- **Description:** Pass a floating-point number for `index`.
- **Params:**
  ```json
  { "name": "FloatBus", "index": 1.5 }
  ```
- **Expected result:** Error — Zod validation fails; `z.number().int()` rejects floats.
- **Notes:** Verify Zod integer validation.

#### Scenario 9: Special characters in bus name
- **Description:** Use a bus name with spaces and special chars.
- **Params:**
  ```json
  { "name": "My Bus & FX!" }
  ```
- **Expected result:** Bus is created with the given name (Godot allows most characters).
- **Notes:** Verify special chars are handled.

---

## Tool: `add_audio_bus_effect`

**Description:** Add an audio effect to an audio bus  
**Bridge route:** `audio/add_bus_effect`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `bus_name` | `string` (Name) | **Yes** | — | Audio bus name |
| `effect_type` | `enum` | **Yes** | — | Effect type (see enum values below) |
| `index` | `number` (int) | No | — | Effect insertion position on the bus |
| `properties` | `record` | No | — | Effect properties |

**Enum values for `effect_type` (20 total):**

`reverb`, `delay`, `chorus`, `compressor`, `distortion`, `eq`, `limiter`, `panner`, `pitchshift`, `filter`, `lowpass`, `highpass`, `bandpass`, `notch`, `spectrum`, `amplify`, `stereo`, `eq6`, `eq10`, `eq21`

### Handler Logic

Calls `bridge` → `callGodot` with route `audio/add_bus_effect`. Adds an audio effect of the specified type to the named bus, optionally at a specific position and with custom properties.

### Test Scenarios

#### Scenario 1: Add reverb to Master bus (minimum params)
- **Description:** Add a reverb effect to the Master bus with only required params.
- **Params:**
  ```json
  { "bus_name": "Master", "effect_type": "reverb" }
  ```
- **Expected result:** A reverb effect is appended to the Master bus effect chain. Returns success with effect index.
- **Notes:** Minimum required params: `bus_name` + `effect_type`.

#### Scenario 2–20: One scenario per effect_type enum value

Each of the following scenarios tests a different `effect_type` value against the Master bus with no optional params:

| # | effect_type | Params | Expected |
|---|-------------|--------|----------|
| 2 | `delay` | `{ "bus_name": "Master", "effect_type": "delay" }` | Delay effect added |
| 3 | `chorus` | `{ "bus_name": "Master", "effect_type": "chorus" }` | Chorus effect added |
| 4 | `compressor` | `{ "bus_name": "Master", "effect_type": "compressor" }` | Compressor effect added |
| 5 | `distortion` | `{ "bus_name": "Master", "effect_type": "distortion" }` | Distortion effect added |
| 6 | `eq` | `{ "bus_name": "Master", "effect_type": "eq" }` | EQ effect added |
| 7 | `limiter` | `{ "bus_name": "Master", "effect_type": "limiter" }` | Limiter effect added |
| 8 | `panner` | `{ "bus_name": "Master", "effect_type": "panner" }` | Panner effect added |
| 9 | `pitchshift` | `{ "bus_name": "Master", "effect_type": "pitchshift" }` | PitchShift effect added |
| 10 | `filter` | `{ "bus_name": "Master", "effect_type": "filter" }` | Filter effect added |
| 11 | `lowpass` | `{ "bus_name": "Master", "effect_type": "lowpass" }` | LowPass effect added |
| 12 | `highpass` | `{ "bus_name": "Master", "effect_type": "highpass" }` | HighPass effect added |
| 13 | `bandpass` | `{ "bus_name": "Master", "effect_type": "bandpass" }` | BandPass effect added |
| 14 | `notch` | `{ "bus_name": "Master", "effect_type": "notch" }` | Notch effect added |
| 15 | `spectrum` | `{ "bus_name": "Master", "effect_type": "spectrum" }` | Spectrum effect added |
| 16 | `amplify` | `{ "bus_name": "Master", "effect_type": "amplify" }` | Amplify effect added |
| 17 | `stereo` | `{ "bus_name": "Master", "effect_type": "stereo" }` | Stereo effect added |
| 18 | `eq6` | `{ "bus_name": "Master", "effect_type": "eq6" }` | EQ6 effect added |
| 19 | `eq10` | `{ "bus_name": "Master", "effect_type": "eq10" }` | EQ10 effect added |
| 20 | `eq21` | `{ "bus_name": "Master", "effect_type": "eq21" }` | EQ21 effect added |

#### Scenario 21: Invalid effect_type
- **Description:** Pass a value not in the enum.
- **Params:**
  ```json
  { "bus_name": "Master", "effect_type": "wobble" }
  ```
- **Expected result:** Error — Zod validation fails; invalid enum value.
- **Notes:** Enum is strict.

#### Scenario 22: Add effect to a custom bus
- **Description:** Add a compressor to a bus other than Master.
- **Params:**
  ```json
  { "bus_name": "Music", "effect_type": "compressor" }
  ```
- **Expected result:** Compressor effect added to the `Music` bus.
- **Notes:** Bus must exist before this call.

#### Scenario 23: Add effect at a specific index
- **Description:** Insert a delay effect at position 0 on the bus.
- **Params:**
  ```json
  { "bus_name": "Master", "effect_type": "delay", "index": 0 }
  ```
- **Expected result:** Delay effect inserted at index 0 on Master bus.
- **Notes:** Valid index: non-negative integer.

#### Scenario 24: Add effect with properties
- **Description:** Add a reverb with custom properties.
- **Params:**
  ```json
  {
    "bus_name": "Master",
    "effect_type": "reverb",
    "properties": {
      "room_size": 0.8,
      "damping": 0.5,
      "wet": 0.6,
      "dry": 0.4
    }
  }
  ```
- **Expected result:** Reverb effect added with the specified property values.
- **Notes:** Property names must match Godot's AudioEffectReverb properties.

#### Scenario 25: Add effect with all optional params
- **Description:** Provide index and properties together.
- **Params:**
  ```json
  {
    "bus_name": "SFX",
    "effect_type": "distortion",
    "index": 1,
    "properties": { "mode": 2, "pre_gain": 1.5, "post_gain": 0.8 }
  }
  ```
- **Expected result:** Distortion effect inserted at index 1 on SFX bus with custom properties.
- **Notes:** Integration smoke test.

#### Scenario 26: Missing required `bus_name`
- **Description:** Omit `bus_name`.
- **Params:**
  ```json
  { "effect_type": "reverb" }
  ```
- **Expected result:** Error — Zod validation fails; `bus_name` is required.

#### Scenario 27: Missing required `effect_type`
- **Description:** Omit `effect_type`.
- **Params:**
  ```json
  { "bus_name": "Master" }
  ```
- **Expected result:** Error — Zod validation fails; `effect_type` is required.

#### Scenario 28: Non-existent bus name
- **Description:** Add an effect to a bus that doesn't exist.
- **Params:**
  ```json
  { "bus_name": "GhostBus", "effect_type": "reverb" }
  ```
- **Expected result:** Error — bus not found.
- **Notes:** Error message should indicate the bus doesn't exist.

#### Scenario 29: Negative index
- **Description:** Pass a negative effect index.
- **Params:**
  ```json
  { "bus_name": "Master", "effect_type": "reverb", "index": -1 }
  ```
- **Expected result:** Error — negative index is invalid.
- **Notes:** `z.number().int()` allows negative; Godot should reject.

#### Scenario 30: Empty properties object
- **Description:** Pass an empty properties record.
- **Params:**
  ```json
  { "bus_name": "Master", "effect_type": "reverb", "properties": {} }
  ```
- **Expected result:** Reverb effect added with default property values.
- **Notes:** Empty record should be treated as no custom properties.

---

## Tool: `set_audio_bus`

**Description:** Configure audio bus properties (volume, mute, solo, bypass)  
**Bridge route:** `audio/set_bus`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `bus_name` | `string` (Name) | **Yes** | — | Audio bus name |
| `properties` | `record` (Properties) | **Yes** | — | Bus properties (volume_db, mute, solo, bypass, etc.) |
| `send` | `string` | No | — | Bus name to send output to |

### Handler Logic

Calls `bridge` → `callGodot` with route `audio/set_bus`. Configures the named audio bus with the given property values and optionally routes its output to another bus via `send`.

### Test Scenarios

#### Scenario 1: Set volume on Master bus (minimum params)
- **Description:** Set the volume of the Master bus.
- **Params:**
  ```json
  { "bus_name": "Master", "properties": { "volume_db": -3.0 } }
  ```
- **Expected result:** Master bus volume set to -3 dB. Returns success.
- **Notes:** Both `bus_name` and `properties` are required.

#### Scenario 2: Mute a bus
- **Description:** Mute a specific bus.
- **Params:**
  ```json
  { "bus_name": "Music", "properties": { "mute": true } }
  ```
- **Expected result:** `Music` bus is muted.
- **Notes:** `mute` is a boolean.

#### Scenario 3: Solo a bus
- **Description:** Solo a specific bus.
- **Params:**
  ```json
  { "bus_name": "SFX", "properties": { "solo": true } }
  ```
- **Expected result:** `SFX` bus is soloed.
- **Notes:** `solo` is a boolean.

#### Scenario 4: Bypass effects on a bus
- **Description:** Bypass all effects on a bus.
- **Params:**
  ```json
  { "bus_name": "Master", "properties": { "bypass": true } }
  ```
- **Expected result:** Effects on Master bus are bypassed.
- **Notes:** `bypass` is a boolean.

#### Scenario 5: Set multiple properties at once
- **Description:** Configure volume, mute, and solo simultaneously.
- **Params:**
  ```json
  {
    "bus_name": "Music",
    "properties": { "volume_db": -6.0, "mute": false, "solo": true, "bypass": false }
  }
  ```
- **Expected result:** All properties applied to the Music bus.
- **Notes:** Integration test for multiple properties.

#### Scenario 6: Set send routing
- **Description:** Route a bus output to another bus.
- **Params:**
  ```json
  { "bus_name": "SFX", "properties": { "volume_db": 0.0 }, "send": "Master" }
  ```
- **Expected result:** SFX bus output is sent to Master bus. Volume set to 0 dB.
- **Notes:** `send` is optional; target bus must exist.

#### Scenario 7: Missing required `bus_name`
- **Description:** Omit `bus_name`.
- **Params:**
  ```json
  { "properties": { "volume_db": -3.0 } }
  ```
- **Expected result:** Error — Zod validation fails; `bus_name` is required.

#### Scenario 8: Missing required `properties`
- **Description:** Omit `properties`.
- **Params:**
  ```json
  { "bus_name": "Master" }
  ```
- **Expected result:** Error — Zod validation fails; `properties` is required.

#### Scenario 9: Empty properties object
- **Description:** Pass an empty properties record.
- **Params:**
  ```json
  { "bus_name": "Master", "properties": {} }
  ```
- **Expected result:** Call succeeds but no properties are changed (no-op).
- **Notes:** Edge case — technically valid.

#### Scenario 10: Non-existent bus name
- **Description:** Try to configure a bus that doesn't exist.
- **Params:**
  ```json
  { "bus_name": "NoSuchBus", "properties": { "volume_db": 0.0 } }
  ```
- **Expected result:** Error — bus not found.
- **Notes:** Error message should indicate the bus doesn't exist.

#### Scenario 11: Invalid property name
- **Description:** Pass a property that doesn't exist on AudioBus.
- **Params:**
  ```json
  { "bus_name": "Master", "properties": { "flying_spaghetti_monster": true } }
  ```
- **Expected result:** Behavior depends on Godot — may ignore, warn, or error.
- **Notes:** Edge case for unknown property.

#### Scenario 12: Send to non-existent bus
- **Description:** Route output to a bus that doesn't exist.
- **Params:**
  ```json
  { "bus_name": "Master", "properties": { "volume_db": 0.0 }, "send": "GhostBus" }
  ```
- **Expected result:** Error — target bus not found.
- **Notes:** Sidecar target must exist.

#### Scenario 13: Extreme volume values
- **Description:** Set volume to extreme dB values.
- **Params:**
  ```json
  { "bus_name": "Master", "properties": { "volume_db": -80.0 } }
  ```
  ```json
  { "bus_name": "Master", "properties": { "volume_db": 24.0 } }
  ```
- **Expected result:** Both succeed. Godot clamps to its range (-80 to +24 dB approximately).
- **Notes:** Boundary test for volume range.

---

## Tool: `get_audio_bus_layout`

**Description:** Get the current audio bus layout with all buses and their effects  
**Bridge route:** `audio/get_bus_layout`

### Parameters

None. `inputSchema: {}`.

### Handler Logic

Calls `bridge` → `callGodot` with route `audio/get_bus_layout` and no arguments. Returns the full bus layout including bus names, indices, volume levels, mute/solo/bypass states, sends, and effects list with their types and properties.

### Test Scenarios

#### Scenario 1: Get layout in a fresh project
- **Description:** Call with no params in a project with default audio setup.
- **Params:**
  ```json
  {}
  ```
- **Expected result:** Returns layout object with at least the `Master` bus at index 0. Layout includes bus names, indices, volume, mute/solo/bypass flags.
- **Notes:** Minimal case — always works.

#### Scenario 2: Get layout after adding buses and effects
- **Description:** Add several buses with effects, then get the layout to verify they appear.
- **Prerequisites:** Run `add_audio_bus` for `"Music"` and `"SFX"`, then `add_audio_bus_effect` for `"reverb"` on `"Music"`.
- **Params:**
  ```json
  {}
  ```
- **Expected result:** Layout shows `Master` (index 0), `Music` (index 1 with reverb effect), `SFX` (index 2, no effects). Effects detail includes type and properties.
- **Notes:** End-to-end verification of bus + effect creation reflected in layout.

#### Scenario 3: Verify layout structure properties
- **Description:** Call and verify the returned JSON structure has expected keys.
- **Params:**
  ```json
  {}
  ```
- **Expected result:** Response contains an array of buses, each with `name`, `index` (int), `volume_db` (float), `mute` (bool), `solo` (bool), `bypass` (bool), `send` (string or null), and `effects` (array of effect objects with `type` and `properties`).
- **Notes:** Schema validation test.

#### Scenario 4: Extra params passed (should be ignored)
- **Description:** Pass unexpected params — should be silently ignored since schema is `{}`.
- **Params:**
  ```json
  { "foo": "bar", "extra": 123 }
  ```
- **Expected result:** Returns layout normally; extra params ignored.
- **Notes:** Zod's passthrough behavior or strictness depends on schema configuration.

---

## Tool: `get_audio_info`

**Description:** Get information about an audio node (player type, stream, playback state)  
**Bridge route:** `audio/get_info`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (NodePath) | **Yes** | — | Audio node path |

### Handler Logic

Calls `bridge` → `callGodot` with route `audio/get_info` and `{ path }`. Returns info about the audio player node: its type (AudioStreamPlayer/2D/3D), assigned stream resource, playback state (playing/stopped), and other relevant audio node properties.

### Test Scenarios

#### Scenario 1: Get info for a top-level AudioStreamPlayer
- **Description:** Query info for a simple AudioStreamPlayer at scene root.
- **Params:**
  ```json
  { "path": "AudioStreamPlayer" }
  ```
- **Expected result:** Returns object containing player type (`AudioStreamPlayer`), stream info (null or resource path), and playback state.
- **Notes:** Node must exist.

#### Scenario 2: Get info for AudioStreamPlayer2D
- **Description:** Query info for a 2D audio player.
- **Params:**
  ```json
  { "path": "SFXPlayer2D" }
  ```
- **Expected result:** Returns type `AudioStreamPlayer2D` with its stream and state.
- **Notes:** Verifies 2D player type detection.

#### Scenario 3: Get info for AudioStreamPlayer3D
- **Description:** Query info for a 3D audio player.
- **Params:**
  ```json
  { "path": "Player/Ambient3D" }
  ```
- **Expected result:** Returns type `AudioStreamPlayer3D` with its stream and state.
- **Notes:** Verifies 3D player type detection.

#### Scenario 4: Get info for a player with a stream assigned
- **Description:** Query a player that has an audio stream resource.
- **Prerequisites:** Player has `stream` set to `res://sounds/music.ogg`.
- **Params:**
  ```json
  { "path": "MusicPlayer" }
  ```
- **Expected result:** Response includes `stream: "res://sounds/music.ogg"` or resource details.
- **Notes:** Verifies stream path is returned.

#### Scenario 5: Get info during playback
- **Description:** Query an audio player while it is actively playing.
- **Prerequisites:** The audio player is `playing` (via `autoplay` or game runtime).
- **Params:**
  ```json
  { "path": "PlayingMusic" }
  ```
- **Expected result:** Response shows `playing: true` or equivalent playback state.
- **Notes:** May require the game to be running.

#### Scenario 6: Non-existent node
- **Description:** Query a node that doesn't exist.
- **Params:**
  ```json
  { "path": "GhostPlayer" }
  ```
- **Expected result:** Error — node not found.
- **Notes:** Error message should indicate the node doesn't exist.

#### Scenario 7: Non-audio node
- **Description:** Query a node that exists but is not an audio player (e.g. a Sprite2D).
- **Params:**
  ```json
  { "path": "Sprite2D" }
  ```
- **Expected result:** Error — node is not an audio player.
- **Notes:** Verifies type checking on the Godot side.

#### Scenario 8: Missing required `path`
- **Description:** Omit the required `path` param.
- **Params:**
  ```json
  {}
  ```
- **Expected result:** Error — Zod validation fails; `path` is required.

#### Scenario 9: Scene root as path
- **Description:** Pass empty string for root node.
- **Params:**
  ```json
  { "path": "" }
  ```
- **Expected result:** Error — scene root is not an audio player.
- **Notes:** Edge case — root node unlikely to be an audio player.

---

## Summary

| # | Tool | Params Required | Params Optional | Enum Values | Test Scenarios |
|---|------|-----------------|-----------------|-------------|----------------|
| 1 | `add_audio_player` | `parent` | `player_type`, `name`, `stream_path`, `properties` | 3 (`AudioStreamPlayer`, `AudioStreamPlayer2D`, `AudioStreamPlayer3D`) | 14 |
| 2 | `remove_audio_player` | `node_path` | — | — | 5 |
| 3 | `add_audio_bus` | `name` | `index` | — | 9 |
| 4 | `add_audio_bus_effect` | `bus_name`, `effect_type` | `index`, `properties` | 20 effects | 30 |
| 5 | `set_audio_bus` | `bus_name`, `properties` | `send` | — | 13 |
| 6 | `get_audio_bus_layout` | — | — | — | 4 |
| 7 | `get_audio_info` | `path` | — | — | 9 |

**Total scenarios: 84**
