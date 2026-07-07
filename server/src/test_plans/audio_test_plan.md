# Audio Tools Test Plan

**Source file:** `server/src/tools/audio.ts`  
**Module purpose:** Audio playback and bus management — 7 tools covering AudioStreamPlayer nodes, bus layout, effects, and audio info.

**Shared type definitions (from `shared-types.ts`):**

| Type | Zod schema | Notes |
|------|-----------|-------|
| `NodePath` | `z.string()` | Scene tree node path, e.g. `"Player/AudioStreamPlayer"` or `""` for root |
| `ParentPath` | `z.string()` | Parent node path, `""` for scene root, or node name/path to add as child |
| `Name` | `z.string()` | Generic name identifier |
| `Properties` | `z.record(z.unknown())` | Required property key-value pairs |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | Optional property key-value pairs |

---

## Tool 1: `add_audio_player`

**Description:** Add an AudioStreamPlayer, AudioStreamPlayer2D, or AudioStreamPlayer3D node.  
**Handler route:** `audio/add_player`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `parent` | `ParentPath` (string) | ✅ Yes | — | Parent node — `""` for scene root |
| `player_type` | `enum: "AudioStreamPlayer" \| "AudioStreamPlayer2D" \| "AudioStreamPlayer3D"` | No | `"AudioStreamPlayer"` | Audio player type |
| `name` | `string` | No | — | Custom node name |
| `stream_path` | `string` | No | — | Audio stream resource path (e.g. `"res://sounds/music.ogg"`) |
| `properties` | `Record<string, unknown>` | No | — | Additional player properties (`volume_db`, `autoplay`, `bus`, etc.) |

### Test Scenarios

#### 1.1 Happy path — add default AudioStreamPlayer at scene root
- **Params:** `{ "parent": "" }`
- **Expected result:** Success — an AudioStreamPlayer node added to scene root with default name and type
- **Notes:** Minimum params, all optional parameters use defaults

#### 1.2 Happy path — add AudioStreamPlayer with custom name
- **Params:** `{ "parent": "", "name": "MusicPlayer" }`
- **Expected result:** Success — AudioStreamPlayer node named "MusicPlayer" added to scene root
- **Notes:** Validates custom name parameter

#### 1.3 Happy path — add AudioStreamPlayer with stream_path
- **Params:** `{ "parent": "", "stream_path": "res://sounds/bg_music.ogg" }`
- **Expected result:** Success — AudioStreamPlayer created and stream resource set to the specified path
- **Notes:** Requires the stream file to exist at the path, or validates error if missing

#### 1.4 Happy path — add AudioStreamPlayer with properties
- **Params:** `{ "parent": "", "properties": { "volume_db": -10, "autoplay": true, "bus": "Music" } }`
- **Expected result:** Success — AudioStreamPlayer created with volume set to -10 dB, autoplay enabled, assigned to "Music" bus
- **Notes:** Validates properties object with multiple key-value pairs

#### 1.5 Happy path — add AudioStreamPlayer2D as player_type
- **Params:** `{ "parent": "", "player_type": "AudioStreamPlayer2D" }`
- **Expected result:** Success — an AudioStreamPlayer2D node added to scene root
- **Notes:** Validates "AudioStreamPlayer2D" enum value

#### 1.6 Happy path — add AudioStreamPlayer3D as player_type
- **Params:** `{ "parent": "", "player_type": "AudioStreamPlayer3D" }`
- **Expected result:** Success — an AudioStreamPlayer3D node added to scene root
- **Notes:** Validates "AudioStreamPlayer3D" enum value

#### 1.7 Happy path — add AudioStreamPlayer with explicit default player_type
- **Params:** `{ "parent": "", "player_type": "AudioStreamPlayer" }`
- **Expected result:** Success — an AudioStreamPlayer node added (same as default)
- **Notes:** Validates explicit "AudioStreamPlayer" enum value

#### 1.8 Happy path — add player as child of existing node
- **Params:** `{ "parent": "Character", "player_type": "AudioStreamPlayer3D", "name": "Footsteps" }`
- **Expected result:** Success — AudioStreamPlayer3D named "Footsteps" added as child of "Character"
- **Notes:** Validates nested parent path

#### 1.9 Happy path — add player with nested parent path
- **Params:** `{ "parent": "World/Player", "player_type": "AudioStreamPlayer2D" }`
- **Expected result:** Success — AudioStreamPlayer2D added as child of "World/Player"
- **Notes:** Validates deep nested parent path

#### 1.10 Happy path — add player with all parameters
- **Params:** `{ "parent": "", "player_type": "AudioStreamPlayer3D", "name": "AmbientPlayer", "stream_path": "res://sounds/ambient.ogg", "properties": { "volume_db": -5, "autoplay": false, "bus": "SFX", "max_distance": 50 } }`
- **Expected result:** Success — fully configured AudioStreamPlayer3D added to scene root
- **Notes:** Full parameter coverage

#### 1.11 Edge case — missing required `parent`
- **Params:** `{}`
- **Expected result:** Zod validation error — `parent` is required
- **Notes:** Test input schema validation

#### 1.12 Edge case — invalid `player_type` enum value
- **Params:** `{ "parent": "", "player_type": "AudioStreamPlayer4D" }`
- **Expected result:** Zod validation error — invalid enum value (not one of the 3 valid types)
- **Notes:** Enum validation

#### 1.13 Edge case — empty string `parent`
- **Params:** `{ "parent": "" }`
- **Expected result:** Success (scene root is valid parent) — see 1.1
- **Notes:** Empty string is the valid way to specify scene root

#### 1.14 Edge case — parent path to non-existent node
- **Params:** `{ "parent": "NonExistentNode" }`
- **Expected result:** Error from Godot — parent node not found
- **Notes:** Validates error propagation for bad parent

#### 1.15 Edge case — duplicate name in same parent
- **Params:** `{ "parent": "", "name": "DupePlayer" }` (run twice)
- **Expected result:** First call succeeds, second call succeeds (Godot auto-renames or errors)
- **Notes:** Godot may append a number to the name or throw an error

---

## Tool 2: `remove_audio_player`

**Description:** Remove an audio player node from the scene.  
**Handler route:** `audio/remove_player`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `node_path` | `NodePath` (string) | ✅ Yes | Path to the audio player node to remove |

### Test Scenarios

#### 2.1 Happy path — remove an AudioStreamPlayer from scene root
- **Params:** `{ "node_path": "AudioStreamPlayer" }`
- **Expected result:** Success — AudioStreamPlayer node removed from scene
- **Notes:** Requires an AudioStreamPlayer node named "AudioStreamPlayer" in the scene

#### 2.2 Happy path — remove an AudioStreamPlayer2D from scene root
- **Params:** `{ "node_path": "AudioStreamPlayer2D" }`
- **Expected result:** Success — AudioStreamPlayer2D node removed from scene
- **Notes:** Requires an AudioStreamPlayer2D node in the scene

#### 2.3 Happy path — remove an AudioStreamPlayer3D from scene root
- **Params:** `{ "node_path": "AudioStreamPlayer3D" }`
- **Expected result:** Success — AudioStreamPlayer3D node removed from scene
- **Notes:** Requires an AudioStreamPlayer3D node in the scene

#### 2.4 Happy path — remove audio player with nested path
- **Params:** `{ "node_path": "Character/Footsteps" }`
- **Expected result:** Success — nested audio player node removed
- **Notes:** Requires "Footsteps" as child of "Character"

#### 2.5 Edge case — missing required `node_path`
- **Params:** `{}`
- **Expected result:** Zod validation error — `node_path` is required
- **Notes:** Test input schema validation

#### 2.6 Edge case — empty string `node_path`
- **Params:** `{ "node_path": "" }`
- **Expected result:** Error from Godot — scene root is not an audio player (or root cannot be deleted)
- **Notes:** Validates behavior with scene root path

#### 2.7 Edge case — non-existent node_path
- **Params:** `{ "node_path": "NonExistentPlayer" }`
- **Expected result:** Error from Godot — node not found
- **Notes:** Validates error propagation

#### 2.8 Edge case — node_path points to non-audio-player node
- **Params:** `{ "node_path": "Sprite2D" }`
- **Expected result:** Error from Godot — node is not an audio player (or may still be deleted since it's just a node delete)
- **Notes:** Depends on Godot implementation — may succeed (it's a generic node delete) or may validate type

#### 2.9 Edge case — remove same node twice
- **Params:** `{ "node_path": "ToRemove" }` (run twice)
- **Expected result:** First call succeeds, second call errors (node no longer exists)
- **Notes:** Validates idempotency behavior

---

## Tool 3: `add_audio_bus`

**Description:** Add a new audio bus to the audio bus layout.  
**Handler route:** `audio/add_bus`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | `Name` (string) | ✅ Yes | Bus name |
| `index` | `number` (int) | No | Position in bus list |

### Test Scenarios

#### 3.1 Happy path — add bus with minimum params (name only, appended)
- **Params:** `{ "name": "MyCustomBus" }`
- **Expected result:** Success — new audio bus "MyCustomBus" appended to end of bus list
- **Notes:** Omitting `index` should append to the end

#### 3.2 Happy path — add bus at specific index (beginning)
- **Params:** `{ "name": "EarlyBus", "index": 1 }`
- **Expected result:** Success — new audio bus "EarlyBus" inserted at index 1 (right after Master)
- **Notes:** Master bus is always at index 0. Index 1 is valid.

#### 3.3 Happy path — add bus at index 0
- **Params:** `{ "name": "ReplaceMaster", "index": 0 }`
- **Expected result:** Error from Godot — cannot replace Master bus at index 0, OR bus inserted at position 0 (behavior depends on Godot)
- **Notes:** Master is at index 0. Godot may reject or reorder.

#### 3.4 Happy path — add bus at a mid-range index
- **Params:** `{ "name": "MidBus", "index": 3 }`
- **Expected result:** Success — bus inserted at index 3
- **Notes:** Requires at least 3 existing buses

#### 3.5 Edge case — missing required `name`
- **Params:** `{ "index": 1 }`
- **Expected result:** Zod validation error — `name` is required
- **Notes:** Test input schema validation

#### 3.6 Edge case — empty string `name`
- **Params:** `{ "name": "" }`
- **Expected result:** Error from Godot — bus name cannot be empty
- **Notes:** Zod allows empty string; Godot validates

#### 3.7 Edge case — negative `index`
- **Params:** `{ "name": "BadBus", "index": -1 }`
- **Expected result:** Zod validation error — index must be ≥ 0 (`.int()` accepts negatives but Godot may reject; zod `z.number().int()` does NOT enforce min)
- **Notes:** `z.number().int()` only enforces integer, not non-negative. Test whether Godot rejects negative indices.

#### 3.8 Edge case — non-integer `index` (float)
- **Params:** `{ "name": "FloatBus", "index": 1.5 }`
- **Expected result:** Zod validation error — index must be integer (`.int()`)
- **Notes:** Zod integer validation

#### 3.9 Edge case — duplicate bus name
- **Params:** `{ "name": "Master" }`
- **Expected result:** Error from Godot — bus name already exists
- **Notes:** "Master" already exists as the default bus

#### 3.10 Edge case — very large `index`
- **Params:** `{ "name": "FarBus", "index": 999 }`
- **Expected result:** May succeed (appended to end) or error (index out of range)
- **Notes:** Behavior depends on Godot's handling of out-of-range indices

---

## Tool 4: `add_audio_bus_effect`

**Description:** Add an audio effect to an audio bus.  
**Handler route:** `audio/add_bus_effect`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `bus_name` | `Name` (string) | ✅ Yes | Audio bus name |
| `effect_type` | `enum: "reverb" \| "delay" \| "chorus" \| "compressor" \| "distortion" \| "eq" \| "limiter" \| "panner" \| "pitchshift" \| "filter" \| "lowpass" \| "highpass" \| "bandpass" \| "notch" \| "spectrum" \| "amplify" \| "stereo" \| "eq6" \| "eq10" \| "eq21"` | ✅ Yes | Effect type |
| `index` | `number` (int) | No | Effect insertion position on the bus |
| `properties` | `Record<string, unknown>` | No | Effect properties |

### Test Scenarios

#### 4.1 Happy path — add effect with minimum params
- **Params:** `{ "bus_name": "Master", "effect_type": "reverb" }`
- **Expected result:** Success — reverb effect added to Master bus (appended to end of effect chain)
- **Notes:** Omitting `index` and `properties` — should append

#### 4.2 Happy path — add "delay" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "delay" }`
- **Expected result:** Success — delay effect added to Master bus
- **Notes:** Validates "delay" enum value

#### 4.3 Happy path — add "chorus" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "chorus" }`
- **Expected result:** Success — chorus effect added
- **Notes:** Validates "chorus" enum value

#### 4.4 Happy path — add "compressor" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "compressor" }`
- **Expected result:** Success — compressor effect added
- **Notes:** Validates "compressor" enum value

#### 4.5 Happy path — add "distortion" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "distortion" }`
- **Expected result:** Success — distortion effect added
- **Notes:** Validates "distortion" enum value

#### 4.6 Happy path — add "eq" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "eq" }`
- **Expected result:** Success — EQ effect added
- **Notes:** Validates "eq" enum value

#### 4.7 Happy path — add "limiter" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "limiter" }`
- **Expected result:** Success — limiter effect added
- **Notes:** Validates "limiter" enum value

#### 4.8 Happy path — add "panner" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "panner" }`
- **Expected result:** Success — panner effect added
- **Notes:** Validates "panner" enum value

#### 4.9 Happy path — add "pitchshift" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "pitchshift" }`
- **Expected result:** Success — pitch shift effect added
- **Notes:** Validates "pitchshift" enum value

#### 4.10 Happy path — add "filter" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "filter" }`
- **Expected result:** Success — filter effect added
- **Notes:** Validates "filter" enum value

#### 4.11 Happy path — add "lowpass" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "lowpass" }`
- **Expected result:** Success — lowpass filter effect added
- **Notes:** Validates "lowpass" enum value

#### 4.12 Happy path — add "highpass" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "highpass" }`
- **Expected result:** Success — highpass filter effect added
- **Notes:** Validates "highpass" enum value

#### 4.13 Happy path — add "bandpass" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "bandpass" }`
- **Expected result:** Success — bandpass filter effect added
- **Notes:** Validates "bandpass" enum value

#### 4.14 Happy path — add "notch" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "notch" }`
- **Expected result:** Success — notch filter effect added
- **Notes:** Validates "notch" enum value

#### 4.15 Happy path — add "spectrum" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "spectrum" }`
- **Expected result:** Success — spectrum analyzer effect added
- **Notes:** Validates "spectrum" enum value

#### 4.16 Happy path — add "amplify" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "amplify" }`
- **Expected result:** Success — amplify effect added
- **Notes:** Validates "amplify" enum value

#### 4.17 Happy path — add "stereo" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "stereo" }`
- **Expected result:** Success — stereo enhance effect added
- **Notes:** Validates "stereo" enum value

#### 4.18 Happy path — add "eq6" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "eq6" }`
- **Expected result:** Success — 6-band EQ effect added
- **Notes:** Validates "eq6" enum value

#### 4.19 Happy path — add "eq10" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "eq10" }`
- **Expected result:** Success — 10-band EQ effect added
- **Notes:** Validates "eq10" enum value

#### 4.20 Happy path — add "eq21" effect
- **Params:** `{ "bus_name": "Master", "effect_type": "eq21" }`
- **Expected result:** Success — 21-band EQ effect added
- **Notes:** Validates "eq21" enum value

#### 4.21 Happy path — add effect with custom properties
- **Params:** `{ "bus_name": "Master", "effect_type": "reverb", "properties": { "room_size": 0.8, "damp": 0.5, "wet": 0.6 } }`
- **Expected result:** Success — reverb effect added with specified properties
- **Notes:** Validates properties object for effect configuration

#### 4.22 Happy path — add effect at specific index
- **Params:** `{ "bus_name": "Master", "effect_type": "compressor", "index": 0 }`
- **Expected result:** Success — compressor effect inserted at index 0 (first in effect chain)
- **Notes:** Validates `index` parameter

#### 4.23 Happy path — add second effect after existing one
- **Params:** `{ "bus_name": "Master", "effect_type": "delay", "index": 1 }`
- **Expected result:** Success — delay effect inserted at index 1 (after the first effect)
- **Notes:** Requires an existing effect at index 0

#### 4.24 Happy path — add effect on a custom bus (not Master)
- **Params:** `{ "bus_name": "MyCustomBus", "effect_type": "eq" }`
- **Expected result:** Success — EQ effect added to custom bus
- **Notes:** Requires "MyCustomBus" to exist (created via `add_audio_bus`)

#### 4.25 Edge case — missing required `bus_name`
- **Params:** `{ "effect_type": "reverb" }`
- **Expected result:** Zod validation error — `bus_name` is required
- **Notes:** Test input schema validation

#### 4.26 Edge case — missing required `effect_type`
- **Params:** `{ "bus_name": "Master" }`
- **Expected result:** Zod validation error — `effect_type` is required
- **Notes:** Test input schema validation

#### 4.27 Edge case — invalid `effect_type` enum value
- **Params:** `{ "bus_name": "Master", "effect_type": "phaser" }`
- **Expected result:** Zod validation error — invalid enum value (not in the 20 valid types)
- **Notes:** Enum validation — "phaser" is not a listed effect type

#### 4.28 Edge case — empty string `bus_name`
- **Params:** `{ "bus_name": "", "effect_type": "reverb" }`
- **Expected result:** Error from Godot — bus name cannot be empty or no bus with empty name
- **Notes:** Zod allows empty string; Godot validates

#### 4.29 Edge case — non-existent bus_name
- **Params:** `{ "bus_name": "NonExistentBus", "effect_type": "reverb" }`
- **Expected result:** Error from Godot — bus not found
- **Notes:** Validates error propagation for missing bus

#### 4.30 Edge case — negative `index`
- **Params:** `{ "bus_name": "Master", "effect_type": "reverb", "index": -1 }`
- **Expected result:** Zod validation error or Godot error — negative index
- **Notes:** `z.number().int()` allows negative; Godot may reject

#### 4.31 Edge case — non-integer `index` (float)
- **Params:** `{ "bus_name": "Master", "effect_type": "reverb", "index": 0.5 }`
- **Expected result:** Zod validation error — index must be integer (`.int()`)
- **Notes:** Zod integer validation

#### 4.32 Edge case — empty properties object
- **Params:** `{ "bus_name": "Master", "effect_type": "reverb", "properties": {} }`
- **Expected result:** Success — same as omitting properties, effect added with defaults
- **Notes:** Should behave identically to 4.1

---

## Tool 5: `set_audio_bus`

**Description:** Configure audio bus properties (volume, mute, solo, bypass).  
**Handler route:** `audio/set_bus`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `bus_name` | `Name` (string) | ✅ Yes | Audio bus name |
| `properties` | `Record<string, unknown>` | ✅ Yes | Bus properties (`volume_db`, `mute`, `solo`, `bypass`, etc.) |
| `send` | `string` | No | Bus name to send output to |

### Test Scenarios

#### 5.1 Happy path — set volume on Master bus
- **Params:** `{ "bus_name": "Master", "properties": { "volume_db": -6 } }`
- **Expected result:** Success — Master bus volume set to -6 dB
- **Notes:** Basic property set

#### 5.2 Happy path — mute a bus
- **Params:** `{ "bus_name": "Master", "properties": { "mute": true } }`
- **Expected result:** Success — Master bus muted
- **Notes:** Validates boolean property

#### 5.3 Happy path — unmute a bus
- **Params:** `{ "bus_name": "Master", "properties": { "mute": false } }`
- **Expected result:** Success — Master bus unmuted
- **Notes:** Validates toggling boolean back

#### 5.4 Happy path — solo a bus
- **Params:** `{ "bus_name": "Master", "properties": { "solo": true } }`
- **Expected result:** Success — Master bus soloed
- **Notes:** Validates solo property

#### 5.5 Happy path — set bypass on a bus
- **Params:** `{ "bus_name": "Master", "properties": { "bypass": true } }`
- **Expected result:** Success — Master bus effects bypassed
- **Notes:** Validates bypass property

#### 5.6 Happy path — set multiple properties at once
- **Params:** `{ "bus_name": "Master", "properties": { "volume_db": -3, "mute": false, "solo": false, "bypass": false } }`
- **Expected result:** Success — all properties applied simultaneously
- **Notes:** Validates multiple property sets in one call

#### 5.7 Happy path — set send target
- **Params:** `{ "bus_name": "SFX", "properties": { "volume_db": 0 }, "send": "Master" }`
- **Expected result:** Success — SFX bus send routed to Master
- **Notes:** Requires an "SFX" bus to exist. Validates `send` parameter.

#### 5.8 Happy path — set properties on custom bus
- **Params:** `{ "bus_name": "MyCustomBus", "properties": { "volume_db": -12, "mute": true } }`
- **Expected result:** Success — custom bus properties updated
- **Notes:** Requires "MyCustomBus" to exist (created via `add_audio_bus`)

#### 5.9 Edge case — missing required `bus_name`
- **Params:** `{ "properties": { "volume_db": 0 } }`
- **Expected result:** Zod validation error — `bus_name` is required
- **Notes:** Test input schema validation

#### 5.10 Edge case — missing required `properties`
- **Params:** `{ "bus_name": "Master" }`
- **Expected result:** Zod validation error — `properties` is required
- **Notes:** `Properties` (not `OptionalProperties`) is used, so it's required

#### 5.11 Edge case — empty `properties` object
- **Params:** `{ "bus_name": "Master", "properties": {} }`
- **Expected result:** May succeed (no-op) or error from Godot
- **Notes:** Technically valid — empty record passes zod validation

#### 5.12 Edge case — non-existent bus_name
- **Params:** `{ "bus_name": "GhostBus", "properties": { "volume_db": 0 } }`
- **Expected result:** Error from Godot — bus not found
- **Notes:** Validates error propagation for missing bus

#### 5.13 Edge case — empty string `bus_name`
- **Params:** `{ "bus_name": "", "properties": { "volume_db": 0 } }`
- **Expected result:** Error from Godot — no bus with empty name
- **Notes:** Zod allows empty string; Godot validates

#### 5.14 Edge case — invalid property key
- **Params:** `{ "bus_name": "Master", "properties": { "nonexistent_prop": 42 } }`
- **Expected result:** Error from Godot — unknown property, or silently ignored
- **Notes:** Behavior depends on Godot's property validation

#### 5.15 Edge case — send to non-existent bus
- **Params:** `{ "bus_name": "Master", "properties": { "volume_db": 0 }, "send": "NoSuchBus" }`
- **Expected result:** Error from Godot — target send bus not found
- **Notes:** Validates send validation

#### 5.16 Edge case — send to self
- **Params:** `{ "bus_name": "Master", "properties": { "volume_db": 0 }, "send": "Master" }`
- **Expected result:** Error from Godot — cannot send to self, or circular send detected
- **Notes:** Validates circular send detection

---

## Tool 6: `get_audio_bus_layout`

**Description:** Get the current audio bus layout with all buses and their effects.  
**Handler route:** `audio/get_bus_layout`

### Parameters

No parameters — this tool takes an empty input schema.

### Test Scenarios

#### 6.1 Happy path — get bus layout with default buses
- **Params:** `{}` (no params)
- **Expected result:** Returns bus layout object — at minimum includes Master bus with its properties (volume_db, mute, solo, bypass) and effects list
- **Notes:** Default Godot projects have at least the Master bus

#### 6.2 Happy path — get bus layout after adding custom buses and effects
- **Params:** `{}` (no params)
- **Expected result:** Returns bus layout including all custom buses and their effects with current property values
- **Notes:** Run after adding buses and effects. Verify layout reflects all changes.

#### 6.3 Happy path — get bus layout after modifying bus properties
- **Params:** `{}` (no params)
- **Expected result:** Returns bus layout with updated property values (e.g., volume_db changes, mute/solo state)
- **Notes:** Run after using `set_audio_bus`. Verify the layout reflects recent changes.

#### 6.4 Edge case — no scene required
- **Params:** `{}` (no params)
- **Expected result:** Success — bus layout is global project state, doesn't require a scene
- **Notes:** This tool should work regardless of scene state

---

## Tool 7: `get_audio_info`

**Description:** Get information about an audio node (player type, stream, playback state).  
**Handler route:** `audio/get_info`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | ✅ Yes | Audio node path |

### Test Scenarios

#### 7.1 Happy path — get info on an AudioStreamPlayer
- **Params:** `{ "path": "AudioStreamPlayer" }`
- **Expected result:** Returns audio info including player type ("AudioStreamPlayer"), stream resource (or null), playback state (playing/stopped), and other properties
- **Notes:** Requires an AudioStreamPlayer node in the scene

#### 7.2 Happy path — get info on an AudioStreamPlayer2D
- **Params:** `{ "path": "AudioStreamPlayer2D" }`
- **Expected result:** Returns audio info with player type "AudioStreamPlayer2D" and 2D-specific properties (e.g., max_distance)
- **Notes:** Requires an AudioStreamPlayer2D node in the scene

#### 7.3 Happy path — get info on an AudioStreamPlayer3D
- **Params:** `{ "path": "AudioStreamPlayer3D" }`
- **Expected result:** Returns audio info with player type "AudioStreamPlayer3D" and 3D-specific properties (e.g., unit_size, max_db)
- **Notes:** Requires an AudioStreamPlayer3D node in the scene

#### 7.4 Happy path — get info on audio player with stream assigned
- **Params:** `{ "path": "MusicPlayer" }`
- **Expected result:** Returns audio info showing the assigned stream resource path and its properties
- **Notes:** Requires an audio player with a stream resource assigned (created via `add_audio_player` with `stream_path`)

#### 7.5 Happy path — get info during playback
- **Params:** `{ "path": "AudioStreamPlayer" }`
- **Expected result:** Returns audio info showing `playing: true` or similar playback state
- **Notes:** Requires the game to be running and the audio player actively playing

#### 7.6 Happy path — get info when stopped
- **Params:** `{ "path": "AudioStreamPlayer" }`
- **Expected result:** Returns audio info showing `playing: false` or stopped state
- **Notes:** Requires the audio player to be stopped

#### 7.7 Happy path — get info with nested path
- **Params:** `{ "path": "Character/Footsteps" }`
- **Expected result:** Returns audio info for the nested audio player node
- **Notes:** Validates nested path resolution

#### 7.8 Edge case — missing required `path`
- **Params:** `{}`
- **Expected result:** Zod validation error — `path` is required
- **Notes:** Test input schema validation

#### 7.9 Edge case — empty string `path`
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot — scene root is not an audio player node
- **Notes:** Validates behavior with scene root reference

#### 7.10 Edge case — non-existent node path
- **Params:** `{ "path": "GhostPlayer" }`
- **Expected result:** Error from Godot — node not found
- **Notes:** Validates error propagation

#### 7.11 Edge case — path points to non-audio node
- **Params:** `{ "path": "Sprite2D" }`
- **Expected result:** Error from Godot — node is not an audio player type
- **Notes:** Validates type checking on Godot side

#### 7.12 Edge case — path points to a deleted/missing audio node
- **Params:** `{ "path": "RemovedPlayer" }`
- **Expected result:** Error from Godot — node not found
- **Notes:** Requires the node to have been removed before calling

---

## Integration Test Flow

The following end-to-end flows test the full lifecycle of audio tools in sequence:

### Flow 1: Audio Player Lifecycle (Tools 1, 2, 7)

**Prerequisites:** An empty or existing scene

1. **Add AudioStreamPlayer** (1.1) — `{ "parent": "", "name": "TestPlayer", "stream_path": "res://sounds/test.ogg", "properties": { "volume_db": -6, "autoplay": false } }`
2. **Get audio info** (7.1) — `{ "path": "TestPlayer" }` → verify player type is "AudioStreamPlayer", stream is set, volume is -6
3. **Add AudioStreamPlayer2D** (1.5) — `{ "parent": "TestPlayer", "player_type": "AudioStreamPlayer2D", "name": "Child2D" }`
4. **Get audio info** (7.2) — `{ "path": "TestPlayer/Child2D" }` → verify player type is "AudioStreamPlayer2D"
5. **Add AudioStreamPlayer3D** (1.6) — `{ "parent": "", "player_type": "AudioStreamPlayer3D", "name": "SpatialPlayer" }`
6. **Get audio info** (7.3) — `{ "path": "SpatialPlayer" }` → verify player type is "AudioStreamPlayer3D"
7. **Remove AudioStreamPlayer3D** (2.2) — `{ "node_path": "SpatialPlayer" }`
8. **Get audio info** (7.10) — `{ "path": "SpatialPlayer" }` → expect error (node removed)
9. **Remove nested player** (2.4) — `{ "node_path": "TestPlayer/Child2D" }`
10. **Get audio info** (7.11) — `{ "path": "TestPlayer/Child2D" }` → expect error (node removed)

### Flow 2: Audio Bus Management (Tools 3, 4, 5, 6)

**Prerequisites:** None (bus layout is global project state)

1. **Get bus layout** (6.1) — `{}` → capture initial state with Master bus
2. **Add custom bus** (3.1) — `{ "name": "Music" }`
3. **Add second custom bus** (3.1) — `{ "name": "SFX" }`
4. **Add bus at specific index** (3.2) — `{ "name": "Voice", "index": 1 }`
5. **Get bus layout** (6.2) — `{}` → verify Master, Voice, Music, SFX in order
6. **Add reverb effect to Master** (4.1) — `{ "bus_name": "Master", "effect_type": "reverb", "properties": { "room_size": 0.7, "wet": 0.5 } }`
7. **Add compressor to Master** (4.4) — `{ "bus_name": "Master", "effect_type": "compressor", "index": 0 }`
8. **Add EQ to Music bus** (4.18) — `{ "bus_name": "Music", "effect_type": "eq6" }`
9. **Add delay to SFX bus** (4.2) — `{ "bus_name": "SFX", "effect_type": "delay" }`
10. **Set bus properties** (5.1) — `{ "bus_name": "Music", "properties": { "volume_db": -3, "mute": false } }`
11. **Set bus send** (5.7) — `{ "bus_name": "Music", "properties": { "volume_db": -3 }, "send": "Master" }`
12. **Mute SFX bus** (5.2) — `{ "bus_name": "SFX", "properties": { "mute": true } }`
13. **Get bus layout** (6.2) — `{}` → verify all buses, effects, and property changes are reflected

### Flow 3: All Enum Values for `add_audio_bus_effect` (Tool 4)

**Prerequisites:** None

Test each of the 20 effect types on a clean bus to ensure all enum values are recognized:

| # | effect_type | Params |
|---|-------------|--------|
| 1 | `reverb` | `{ "bus_name": "Master", "effect_type": "reverb" }` |
| 2 | `delay` | `{ "bus_name": "Master", "effect_type": "delay" }` |
| 3 | `chorus` | `{ "bus_name": "Master", "effect_type": "chorus" }` |
| 4 | `compressor` | `{ "bus_name": "Master", "effect_type": "compressor" }` |
| 5 | `distortion` | `{ "bus_name": "Master", "effect_type": "distortion" }` |
| 6 | `eq` | `{ "bus_name": "Master", "effect_type": "eq" }` |
| 7 | `limiter` | `{ "bus_name": "Master", "effect_type": "limiter" }` |
| 8 | `panner` | `{ "bus_name": "Master", "effect_type": "panner" }` |
| 9 | `pitchshift` | `{ "bus_name": "Master", "effect_type": "pitchshift" }` |
| 10 | `filter` | `{ "bus_name": "Master", "effect_type": "filter" }` |
| 11 | `lowpass` | `{ "bus_name": "Master", "effect_type": "lowpass" }` |
| 12 | `highpass` | `{ "bus_name": "Master", "effect_type": "highpass" }` |
| 13 | `bandpass` | `{ "bus_name": "Master", "effect_type": "bandpass" }` |
| 14 | `notch` | `{ "bus_name": "Master", "effect_type": "notch" }` |
| 15 | `spectrum` | `{ "bus_name": "Master", "effect_type": "spectrum" }` |
| 16 | `amplify` | `{ "bus_name": "Master", "effect_type": "amplify" }` |
| 17 | `stereo` | `{ "bus_name": "Master", "effect_type": "stereo" }` |
| 18 | `eq6` | `{ "bus_name": "Master", "effect_type": "eq6" }` |
| 19 | `eq10` | `{ "bus_name": "Master", "effect_type": "eq10" }` |
| 20 | `eq21` | `{ "bus_name": "Master", "effect_type": "eq21" }` |

**Expected result for all:** Success — each effect type is added. After all 20, call `get_audio_bus_layout` to verify the effect chain on Master bus contains all 20 effects.

**Note:** Master bus will accumulate 20 effects during this flow. Run on a clean project or clean up effects between tests.

### Flow 4: All Player Types (Tool 1)

**Prerequisites:** An empty or existing scene

1. **Add AudioStreamPlayer** (1.7) — `{ "parent": "", "player_type": "AudioStreamPlayer" }`
2. **Add AudioStreamPlayer2D** (1.5) — `{ "parent": "", "player_type": "AudioStreamPlayer2D" }`
3. **Add AudioStreamPlayer3D** (1.6) — `{ "parent": "", "player_type": "AudioStreamPlayer3D" }`
4. **Get audio info on each** (7.1, 7.2, 7.3) → verify each returns the correct player type

---

## Schema Validation Summary

All tools use Zod for input validation. Key constraints:

| Constraint | Applied to | Tools affected |
|-----------|-----------|----------------|
| `ParentPath` (required string) | `parent` | #1 only |
| `NodePath` (required string) | `node_path`, `path` | #2, #7 |
| `Name` (required string) | `name`, `bus_name` | #3, #4, #5 |
| `z.enum([...])` | `player_type` (3 values), `effect_type` (20 values) | #1, #4 |
| `z.string()` (optional) | `stream_path`, `send`, optional `name` | #1, #5 |
| `z.number().int()` (optional) | `index` | #3, #4 |
| `z.record(z.unknown())` (required) | `properties` | #5 only |
| `z.record(z.unknown())` (optional) | `properties` | #1, #4 |
| No params (empty schema) | — | #6 only |

**Gap note:** `index` parameters on tools #3 and #4 use `z.number().int().optional()` — this allows negative integers through zod validation. The Godot-side handler is responsible for rejecting negative indices. Test scenarios 3.7 and 4.30 cover this.

**`NodePath` vs `ParentPath` note:** While both resolve to `z.string()` in Zod, they have different semantic meanings:
- `ParentPath` includes the description about using `""` for scene root and is used when creating new nodes
- `NodePath` is used when referencing existing nodes and includes the full scene-tree path description
