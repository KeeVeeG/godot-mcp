# Audio Tools Test Plan

> File under test: `server/src/tools/audio.ts`
> Shared types: `server/src/tools/shared-types.ts`
> Total tools: 7

---

## Prerequisites

Before running any audio tool tests, ensure:

1. Godot editor is open with MCP plugin active and connected
2. A scene is currently open in the editor (required for node-based tools)
3. The scene has at least one node that can serve as a parent (e.g. the scene root)

### Recommended Setup Sequence

```
1. Create/open a test scene with a root Node2D or Node3D
2. Run tests in order: bus tests first (3→4→5→6), then player tests (1→7→2)
```

---

## Tool: `add_audio_player`

**Description:** Add an AudioStreamPlayer, AudioStreamPlayer2D, or AudioStreamPlayer3D node.

**Godot command:** `audio/add_player`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `parent` | `string` (ParentPath) | **yes** | — | Parent node path. `''` for scene root, `'Player'` for root child, `'Player/Sprites'` for nested |
| `player_type` | `enum` | no | `'AudioStreamPlayer'` | One of: `AudioStreamPlayer`, `AudioStreamPlayer2D`, `AudioStreamPlayer3D` |
| `name` | `string` | no | auto-generated | Custom node name |
| `stream_path` | `string` | no | — | Audio stream resource path, e.g. `'res://sounds/music.ogg'` |
| `properties` | `Record<string, unknown>` | no | — | Additional properties: `volume_db`, `autoplay`, `bus`, etc. |

### Test Scenarios

#### Scenario 1: Happy path — minimal required params only

**Description:** Add an AudioStreamPlayer at the scene root with only the required `parent` parameter. All optional params use defaults.

```json
{
  "parent": ""
}
```

**Expected result:** Tool call succeeds. Returns confirmation that an `AudioStreamPlayer` node was added. The node should appear in the scene tree as a child of the root node with a default auto-generated name.

**Notes:** This is the simplest valid call. Verify the node appears in the scene tree and has type `AudioStreamPlayer`.

**What to pay attention to:** Ensure that the node appeared in the scene tree, that the node type is exactly `AudioStreamPlayer` (not 2D/3D), and that the node name was auto-generated.

---

#### Scenario 2: All params specified — AudioStreamPlayer2D with custom name and stream

**Description:** Add a named AudioStreamPlayer2D under a specific parent node with a stream path and properties.

```json
{
  "parent": "",
  "player_type": "AudioStreamPlayer2D",
  "name": "BackgroundMusic",
  "stream_path": "res://audio/bgm.ogg",
  "properties": {
    "volume_db": -10,
    "autoplay": true,
    "bus": "Music"
  }
}
```

**Expected result:** Tool call succeeds. A node named `BackgroundMusic` of type `AudioStreamPlayer2D` appears as a child of the scene root. Properties `volume_db`, `autoplay`, and `bus` are set correctly.

**Notes:** Requires that `res://audio/bgm.ogg` exists in the project filesystem. If the file doesn't exist, the tool may succeed but the stream won't play. Requires that an audio bus named `Music` exists (see `add_audio_bus`).

**What to pay attention to:** Verify that the node name is exactly `BackgroundMusic`, that `volume_db` is `-10`, `autoplay` is enabled, and `bus` is set to `Music`. If the resource does not exist, ensure the error is meaningful.

---

#### Scenario 3: AudioStreamPlayer3D with nested parent

**Description:** Add a 3D audio player under a nested parent node.

```json
{
  "parent": "Player/Head",
  "player_type": "AudioStreamPlayer3D",
  "name": "FootstepSound",
  "stream_path": "res://audio/footsteps.wav",
  "properties": {
    "max_distance": 20,
    "attenuation_model": 1,
    "unit_size": 5
  }
}
```

**Expected result:** Tool call succeeds. A node named `FootstepSound` of type `AudioStreamPlayer3D` appears as a child of `Player/Head`.

**Notes:** Requires that the node `Player/Head` exists in the current scene. If the parent path is invalid, expect an error.

**What to pay attention to:** Verify that the node was created specifically in `Player/Head`, not in the root. Ensure that 3D-specific properties (`max_distance`, `attenuation_model`, `unit_size`) are set correctly.

---

#### Scenario 4: Missing required `parent` parameter

**Description:** Call without the required `parent` field.

```json
{
  "player_type": "AudioStreamPlayer"
}
```

**Expected result:** Validation error. The tool should reject the call because `parent` is required.

**Notes:** This tests schema validation. The error message should indicate that `parent` is required.

**What to pay attention to:** Ensure that the validation error was returned before sending the request to Godot. The error message should explicitly indicate the missing `parent` parameter.

---

#### Scenario 5: Invalid `player_type` enum value

**Description:** Pass a player type that is not in the allowed enum.

```json
{
  "parent": "",
  "player_type": "AudioStreamPlayer4D"
}
```

**Expected result:** Validation error. The tool should reject `AudioStreamPlayer4D` as it's not in the enum `['AudioStreamPlayer', 'AudioStreamPlayer2D', 'AudioStreamPlayer3D']`.

**Notes:** Tests enum validation. Error should list the valid options.

**What to pay attention to:** Ensure that the error contains a list of valid enum values.

---

#### Scenario 6: Invalid parent path (node doesn't exist)

**Description:** Reference a parent node that does not exist in the scene.

```json
{
  "parent": "NonExistentNode"
}
```

**Expected result:** Error from Godot indicating the parent node `NonExistentNode` was not found in the scene tree.

**Notes:** This tests runtime validation on the Godot side. The error should be descriptive.

**What to pay attention to:** The error should come from Godot (not from MCP validation). Ensure that the error text is clear and indicates the problematic path.

---

## Tool: `remove_audio_player`

**Description:** Remove an audio player node from the scene.

**Godot command:** `audio/remove_player`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `string` (NodePath) | **yes** | — | Path to the audio player node to remove |

### Test Scenarios

#### Scenario 1: Happy path — remove an existing audio player

**Description:** Remove a previously created audio player node by its path.

**Prerequisites:** Run `add_audio_player` first to create a node (e.g. `name: "TestPlayer"`).

```json
{
  "node_path": "TestPlayer"
}
```

**Expected result:** Tool call succeeds. The node `TestPlayer` is removed from the scene tree.

**Notes:** After removal, verify the node no longer exists by calling `get_audio_info` or checking the scene tree.

**What to pay attention to:** Ensure that the node was actually removed from the scene tree. Verify that attempting to get info about the removed node (`get_audio_info`) returns an error.

---

#### Scenario 2: Remove a nested audio player

**Description:** Remove an audio player that is a child of another node.

**Prerequisites:** Create a node under a parent first using `add_audio_player` with `parent: "Player"`.

```json
{
  "node_path": "Player/FootstepSound"
}
```

**Expected result:** Tool call succeeds. The node `Player/FootstepSound` is removed.

**Notes:** The parent node `Player` should remain intact — only the audio player child is removed.

**What to pay attention to:** Ensure that the parent node `Player` remains untouched and only the child node is removed.

---

#### Scenario 3: Remove non-existent node

**Description:** Attempt to remove a node that doesn't exist.

```json
{
  "node_path": "GhostPlayer"
}
```

**Expected result:** Error from Godot indicating the node `GhostPlayer` was not found.

**Notes:** Tests error handling for non-existent nodes.

**What to pay attention to:** The error should be meaningful and indicate that the node was not found. There should be no crash or unhandled exception.

---

#### Scenario 4: Missing required `node_path` parameter

**Description:** Call without the required `node_path` field.

```json
{}
```

**Expected result:** Validation error indicating `node_path` is required.

**What to pay attention to:** Validation should trigger before sending the request to Godot.

---

#### Scenario 5: `node_path` points to a non-audio node

**Description:** Attempt to remove a node that exists but is not an audio player (e.g. a Sprite2D).

```json
{
  "node_path": "Player/Sprite2D"
}
```

**Expected result:** Either an error indicating the node is not an audio player, or the node is removed (depends on Godot-side implementation). Document the actual behavior.

**Notes:** This tests whether the tool validates node type on the Godot side.

**What to pay attention to:** It's important to determine the behavior: whether the tool removes an arbitrary node or validates the type. This affects usage safety.

---

## Tool: `add_audio_bus`

**Description:** Add a new audio bus to the audio bus layout.

**Godot command:** `audio/add_bus`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | `string` (Name) | **yes** | — | Bus name |
| `index` | `number` (int) | no | — | Position in bus list (0-based) |

### Test Scenarios

#### Scenario 1: Happy path — add bus with name only

**Description:** Add a new audio bus with just a name, no index specified.

```json
{
  "name": "SFX"
}
```

**Expected result:** Tool call succeeds. A new bus named `SFX` is added to the audio bus layout (appended at the end).

**Notes:** Verify by calling `get_audio_bus_layout` afterward.

**What to pay attention to:** Verify via `get_audio_bus_layout` that the new `SFX` bus appeared in the list. Ensure it was added at the end (if index is not specified).

---

#### Scenario 2: Add bus at specific index

**Description:** Add a bus at a specific position in the bus list.

```json
{
  "name": "Music",
  "index": 1
}
```

**Expected result:** Tool call succeeds. A bus named `Music` is inserted at index 1 in the bus list.

**Notes:** Verify the bus appears at the correct position via `get_audio_bus_layout`.

**What to pay attention to:** Verify the position of the `Music` bus in the layout — it should be at position 1. Other buses should have shifted.

---

#### Scenario 3: Missing required `name` parameter

**Description:** Call without the required `name` field.

```json
{
  "index": 0
}
```

**Expected result:** Validation error indicating `name` is required.

**What to pay attention to:** Validation should trigger before sending to Godot.

---

#### Scenario 4: Duplicate bus name

**Description:** Attempt to add a bus with a name that already exists.

```json
{
  "name": "SFX"
}
```

**Expected result:** Error from Godot indicating a bus with that name already exists. (Run after Scenario 1 has added `SFX`.)

**What to pay attention to:** Verify that Godot returns a clear error about name duplication rather than silently overwriting.

---

#### Scenario 5: Negative index

**Description:** Pass a negative index value.

```json
{
  "name": "TestBus",
  "index": -1
}
```

**Expected result:** Error — either validation rejects negative int, or Godot rejects an invalid position. Document actual behavior.

**What to pay attention to:** Determine where the error comes from — from Zod validation (if there is a constraint) or from Godot.

---

## Tool: `add_audio_bus_effect`

**Description:** Add an audio effect to an audio bus.

**Godot command:** `audio/add_bus_effect`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `bus_name` | `string` (Name) | **yes** | — | Audio bus name |
| `effect_type` | `enum` | **yes** | — | Effect type (see enum values below) |
| `index` | `number` (int) | no | — | Effect insertion position on the bus |
| `properties` | `Record<string, unknown>` | no | — | Effect properties |

**`effect_type` enum values (20 total):**
`reverb`, `delay`, `chorus`, `compressor`, `distortion`, `eq`, `limiter`, `panner`, `pitchshift`, `filter`, `lowpass`, `highpass`, `bandpass`, `notch`, `spectrum`, `amplify`, `stereo`, `eq6`, `eq10`, `eq21`

### Test Scenarios

#### Scenario 1: Happy path — add reverb effect to a bus

**Description:** Add a reverb effect to an existing bus.

**Prerequisites:** Run `add_audio_bus` with `name: "SFX"` first.

```json
{
  "bus_name": "SFX",
  "effect_type": "reverb"
}
```

**Expected result:** Tool call succeeds. A reverb effect is added to the `SFX` bus.

**Notes:** Verify via `get_audio_bus_layout`.

**What to pay attention to:** Verify via `get_audio_bus_layout` that the `reverb` effect appeared in the `SFX` bus's effects list.

---

#### Scenario 2: Add effect with properties and specific index

**Description:** Add a delay effect with custom properties at a specific position.

```json
{
  "bus_name": "SFX",
  "effect_type": "delay",
  "index": 0,
  "properties": {
    "dry": 0.8,
    "tap1_active": true,
    "tap1_delay_ms": 200,
    "tap1_level_db": -6
  }
}
```

**Expected result:** Tool call succeeds. A delay effect is inserted at index 0 on the `SFX` bus with the specified properties.

**What to pay attention to:** Verify that the effect is at position 0 (before the reverb from scenario 1). The effect properties should be set correctly.

---

#### Scenario 3: Add effect to "Master" bus (built-in)

**Description:** Add an effect to the default Master bus.

```json
{
  "bus_name": "Master",
  "effect_type": "compressor",
  "properties": {
    "threshold_db": -20,
    "ratio": 4,
    "attack_us": 20,
    "release_ms": 250
  }
}
```

**Expected result:** Tool call succeeds. A compressor effect is added to the `Master` bus.

**Notes:** `Master` is a built-in bus that always exists.

**What to pay attention to:** Ensure that effects can be added to the built-in `Master` bus.

---

#### Scenario 4: Missing required `bus_name`

**Description:** Call without `bus_name`.

```json
{
  "effect_type": "reverb"
}
```

**Expected result:** Validation error indicating `bus_name` is required.

---

#### Scenario 5: Missing required `effect_type`

**Description:** Call without `effect_type`.

```json
{
  "bus_name": "SFX"
}
```

**Expected result:** Validation error indicating `effect_type` is required.

---

#### Scenario 6: Invalid `effect_type` enum value

**Description:** Pass an invalid effect type.

```json
{
  "bus_name": "SFX",
  "effect_type": "phaser"
}
```

**Expected result:** Validation error. `phaser` is not in the allowed enum. Error should list valid effect types.

**What to pay attention to:** Ensure that the error contains a list of valid values.

---

#### Scenario 7: Non-existent bus name

**Description:** Reference a bus that doesn't exist.

```json
{
  "bus_name": "NonExistentBus",
  "effect_type": "reverb"
}
```

**Expected result:** Error from Godot indicating the bus `NonExistentBus` was not found.

**What to pay attention to:** The error should come from Godot and be meaningful.

---

#### Scenario 8: Test multiple effect types (parametric)

**Description:** Verify several effect types work. Run once for each of: `chorus`, `limiter`, `lowpass`, `highpass`, `bandpass`, `notch`, `amplify`, `stereo`, `eq6`, `eq10`, `eq21`.

```json
{
  "bus_name": "SFX",
  "effect_type": "<each_effect_type>"
}
```

**Expected result:** Each call succeeds and adds the respective effect type.

**Notes:** This is a parametric test — run the same structure for each of the 20 enum values to confirm all are recognized by the Godot side.

**What to pay attention to:** Ensure that all 20 effect types are correctly recognized and added. Pay special attention to less obvious types (`eq6`, `eq10`, `eq21`, `spectrum`).

---

## Tool: `set_audio_bus`

**Description:** Configure audio bus properties (volume, mute, solo, bypass).

**Godot command:** `audio/set_bus`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `bus_name` | `string` (Name) | **yes** | — | Audio bus name |
| `properties` | `Record<string, unknown>` | **yes** | — | Bus properties: `volume_db`, `mute`, `solo`, `bypass`, etc. |
| `send` | `string` | no | — | Bus name to send output to |

### Test Scenarios

#### Scenario 1: Happy path — set volume on a bus

**Description:** Set the volume of an existing bus.

**Prerequisites:** Run `add_audio_bus` with `name: "SFX"` first.

```json
{
  "bus_name": "SFX",
  "properties": {
    "volume_db": -6
  }
}
```

**Expected result:** Tool call succeeds. The `SFX` bus volume is set to -6 dB.

**Notes:** Verify via `get_audio_bus_layout`.

**What to pay attention to:** Verify via `get_audio_bus_layout` that the `volume_db` of the `SFX` bus is `-6`.

---

#### Scenario 2: Set multiple properties at once

**Description:** Set volume, mute, and solo simultaneously.

```json
{
  "bus_name": "SFX",
  "properties": {
    "volume_db": 0,
    "mute": false,
    "solo": false,
    "bypass": false
  }
}
```

**Expected result:** Tool call succeeds. All four properties are set on the `SFX` bus.

**What to pay attention to:** Verify that all 4 properties are set correctly via `get_audio_bus_layout`.

---

#### Scenario 3: Set bus with send routing

**Description:** Route one bus's output to another bus.

```json
{
  "bus_name": "SFX",
  "properties": {
    "volume_db": -3
  },
  "send": "Master"
}
```

**Expected result:** Tool call succeeds. The `SFX` bus output is routed to `Master`.

**What to pay attention to:** Verify that in the layout the `SFX` bus now sends its output to `Master`.

---

#### Scenario 4: Mute a bus

**Description:** Mute the bus.

```json
{
  "bus_name": "Music",
  "properties": {
    "mute": true
  }
}
```

**Expected result:** Tool call succeeds. The `Music` bus is muted.

**What to pay attention to:** Verify that `mute` is set to `true`.

---

#### Scenario 5: Missing required `properties`

**Description:** Call without `properties`.

```json
{
  "bus_name": "SFX"
}
```

**Expected result:** Validation error indicating `properties` is required.

---

#### Scenario 6: Non-existent bus name

**Description:** Reference a bus that doesn't exist.

```json
{
  "bus_name": "GhostBus",
  "properties": { "volume_db": 0 }
}
```

**Expected result:** Error from Godot indicating the bus was not found.

---

#### Scenario 7: Send to non-existent bus

**Description:** Set `send` to a bus name that doesn't exist.

```json
{
  "bus_name": "SFX",
  "properties": { "volume_db": 0 },
  "send": "NonExistentBus"
}
```

**Expected result:** Error from Godot indicating the send target bus was not found.

**What to pay attention to:** Verify that the error explicitly indicates the problem with the target bus.

---

## Tool: `get_audio_bus_layout`

**Description:** Get the current audio bus layout with all buses and their effects.

**Godot command:** `audio/get_bus_layout`

### Parameters

None. This tool takes no parameters.

### Test Scenarios

#### Scenario 1: Happy path — get default layout

**Description:** Call with no setup — should return at least the default `Master` bus.

```json
{}
```

**Expected result:** Tool call succeeds. Returns the audio bus layout containing at least the `Master` bus. The layout should include bus names, properties (volume_db, mute, solo, bypass), send targets, and a list of effects per bus.

**Notes:** Every Godot project has at least a `Master` bus by default.

**What to pay attention to:** Ensure that the result contains at least the `Master` bus. Verify the response structure — there should be name, properties, and a list of effects.

---

#### Scenario 2: Get layout after adding buses and effects

**Description:** Call after setting up multiple buses with effects (run `add_audio_bus` and `add_audio_bus_effect` scenarios first).

```json
{}
```

**Expected result:** Returns layout including `Master`, `SFX` (with reverb and delay effects), and `Music` buses. Each bus shows its effects list.

**What to pay attention to:** Verify that all previously added buses and effects are displayed. Ensure that effect properties (if set) are also visible.

---

#### Scenario 3: Call multiple times — consistency check

**Description:** Call `get_audio_bus_layout` twice in a row without any mutations.

```json
{}
```

**Expected result:** Both calls return identical results.

**Notes:** Tests idempotency — read-only calls should be deterministic.

**What to pay attention to:** The results of two consecutive calls should be identical (if no changes were made between them).

---

## Tool: `get_audio_info`

**Description:** Get information about an audio node (player type, stream, playback state).

**Godot command:** `audio/get_info`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (NodePath) | **yes** | — | Audio node path |

### Test Scenarios

#### Scenario 1: Happy path — get info about an existing audio player

**Description:** Get info about a previously created audio player.

**Prerequisites:** Run `add_audio_player` with `name: "BGMPlayer"` and `stream_path: "res://audio/bgm.ogg"` first.

```json
{
  "path": "BGMPlayer"
}
```

**Expected result:** Tool call succeeds. Returns information about the node including:
- Player type (e.g. `AudioStreamPlayer`)
- Stream path (e.g. `res://audio/bgm.ogg`)
- Playback state (playing/not playing)
- Properties like `volume_db`, `autoplay`, `bus`

**What to pay attention to:** Ensure that the returned data includes: player type, audio stream path, playback state. Verify that `stream_path` matches what was specified during creation.

---

#### Scenario 2: Get info about a 2D audio player

**Description:** Get info about an AudioStreamPlayer2D node.

**Prerequisites:** Create with `add_audio_player` using `player_type: "AudioStreamPlayer2D"`.

```json
{
  "path": "BackgroundMusic"
}
```

**Expected result:** Returns info showing player type is `AudioStreamPlayer2D`, along with 2D-specific properties if exposed (e.g. `max_distance`, `attenuation`).

**What to pay attention to:** Verify that the player type is displayed as `AudioStreamPlayer2D`. If there are 2D-specific properties, they should be in the response.

---

#### Scenario 3: Get info about a 3D audio player

**Description:** Get info about an AudioStreamPlayer3D node.

**Prerequisites:** Create with `add_audio_player` using `player_type: "AudioStreamPlayer3D"`.

```json
{
  "path": "FootstepSound"
}
```

**Expected result:** Returns info showing player type is `AudioStreamPlayer3D`, along with 3D-specific properties.

---

#### Scenario 4: Non-existent node path

**Description:** Reference a node that doesn't exist.

```json
{
  "path": "NonExistentPlayer"
}
```

**Expected result:** Error from Godot indicating the node was not found.

**What to pay attention to:** The error should be meaningful and not lead to a crash.

---

#### Scenario 5: Path points to a non-audio node

**Description:** Get info about a node that exists but is not an audio player.

```json
{
  "path": "Sprite2D"
}
```

**Expected result:** Either an error indicating the node is not an audio player, or a response with limited/empty audio info. Document actual behavior.

**What to pay attention to:** It's important to determine the behavior: whether the tool returns an error for non-audio nodes or attempts to return partial information.

---

#### Scenario 6: Missing required `path` parameter

**Description:** Call without `path`.

```json
{}
```

**Expected result:** Validation error indicating `path` is required.

---

#### Scenario 7: Nested node path

**Description:** Get info about a nested audio player.

```json
{
  "path": "Player/Head/FootstepSound"
}
```

**Expected result:** Returns info about the `FootstepSound` node nested under `Player/Head`.

**What to pay attention to:** Verify that the full path is correctly handled and information is returned for the desired node.

---

## Cross-Tool Workflow: Full Audio Setup Sequence

This section describes a complete end-to-end workflow that chains multiple tools together.

### Workflow: Create an audio bus with effects, add a player, configure, and verify

**Step 1 — Create audio bus:**
```json
// add_audio_bus
{ "name": "Music" }
```

**Step 2 — Add effects to the bus:**
```json
// add_audio_bus_effect
{ "bus_name": "Music", "effect_type": "reverb", "properties": { "room_size": 0.8, "damping": 0.5 } }
```
```json
// add_audio_bus_effect
{ "bus_name": "Music", "effect_type": "chorus" }
```

**Step 3 — Configure the bus:**
```json
// set_audio_bus
{ "bus_name": "Music", "properties": { "volume_db": -6, "mute": false } }
```

**Step 4 — Add an audio player routed to the bus:**
```json
// add_audio_player
{ "parent": "", "player_type": "AudioStreamPlayer", "name": "BGM", "stream_path": "res://audio/bgm.ogg", "properties": { "bus": "Music", "autoplay": true } }
```

**Step 5 — Verify bus layout:**
```json
// get_audio_bus_layout
{}
```
Expected: `Music` bus with `reverb` and `chorus` effects, volume -6 dB, not muted.

**Step 6 — Verify player info:**
```json
// get_audio_info
{ "path": "BGM" }
```
Expected: `AudioStreamPlayer`, stream `res://audio/bgm.ogg`, bus `Music`, autoplay true.

**Step 7 — Cleanup — remove the player:**
```json
// remove_audio_player
{ "node_path": "BGM" }
```

**Notes:** This workflow tests the full lifecycle: bus creation → effect insertion → bus configuration → player creation → verification → cleanup. Run this as an integration test to validate that all tools work together correctly.

**What to pay attention to:** All steps should execute sequentially without errors. Steps 5 and 6 are key verifications confirming that the previous operations were applied correctly.

---

## Edge Cases Summary

| Scenario | Tool | Params | Expected |
|----------|------|--------|----------|
| Empty string parent (scene root) | `add_audio_player` | `{ "parent": "" }` | Success — adds to scene root |
| Very long node name | `add_audio_player` | `{ "parent": "", "name": "A".repeat(255) }` | Either success or Godot name-length error |
| Special characters in bus name | `add_audio_bus` | `{ "name": "Bus #1 (main)" }` | Document if special chars are accepted |
| Zero index for bus | `add_audio_bus` | `{ "name": "TestBus", "index": 0 }` | Success — inserts at first position |
| Effect properties with wrong types | `add_audio_bus_effect` | `{ "bus_name": "SFX", "effect_type": "reverb", "properties": { "room_size": "large" } }` | Error — `room_size` should be a number |
| Properties with unknown keys | `set_audio_bus` | `{ "bus_name": "SFX", "properties": { "nonexistent_prop": 42 } }` | Either ignored by Godot or error — document behavior |
| Double remove same node | `remove_audio_player` | Call twice on same path | Second call should error (node already gone) |
| Empty properties object | `set_audio_bus` | `{ "bus_name": "SFX", "properties": {} }` | Either success (no-op) or error — document behavior |
| Effect on "Master" bus | `add_audio_bus_effect` | `{ "bus_name": "Master", "effect_type": "limiter" }` | Success — Master bus accepts effects |
| Float index for bus | `add_audio_bus` | `{ "name": "TestBus", "index": 1.5 }` | Validation error — index must be int |