# Animation Tools — Comprehensive Test Plan

> **Source file:** `server/src/tools/animation.ts`  
> **Shared types:** `server/src/tools/shared-types.ts`  
> **Bridge call pattern:** `callGodot(bridge, method, args)` → `ToolResult { content: [{ type: 'text', text }], isError? }`  
> **Total tools:** 12

---

## Table of Contents

1. [list_animations](#1-list_animations)
2. [create_animation](#2-create_animation)
3. [add_animation_track](#3-add_animation_track)
4. [set_animation_keyframe](#4-set_animation_keyframe)
5. [get_animation_info](#5-get_animation_info)
6. [remove_animation](#6-remove_animation)
7. [create_animation_tree](#7-create_animation_tree)
8. [get_animation_tree_structure](#8-get_animation_tree_structure)
9. [set_tree_parameter](#9-set_tree_parameter)
10. [add_state_machine_state](#10-add_state_machine_state)
11. [remove_animation_tree](#11-remove_animation_tree)
12. [get_tree_parameter](#12-get_tree_parameter)

---

## Prerequisites / Setup

Animation tools operate on `AnimationPlayer` and `AnimationTree` nodes in the scene tree. Before testing, you need:

1. **A scene with an AnimationPlayer node** — use `create_scene` to create a scene, then `add_node` to add an `AnimationPlayer` node.
2. **For AnimationTree tests** — either create one via `create_animation_tree` or add it via `add_node` with type `AnimationTree`.
3. **Animations must exist** before adding tracks or keyframes — use `create_animation` first.

### Recommended setup sequence

```
Step 1: create_scene  → { node_type: "Node2D", scene_path: "res://test_anim.tscn" }
Step 2: open_scene    → { scene_path: "res://test_anim.tscn" }
Step 3: add_node      → { parent: "", name: "AnimationPlayer", type: "AnimationPlayer" }
Step 4: add_node      → { parent: "", name: "Sprite2D", type: "Sprite2D" }
        (Sprite2D needed as a target for value/position/rotation/scale tracks)
```

---

## Shared Parameter Reference

| Parameter | Zod Type | Description |
|-----------|----------|-------------|
| `player_path` | `NodePath` = `z.string()` | Node path to AnimationPlayer, relative to current scene (e.g. `"AnimationPlayer"`) |
| `path` | `NodePath` = `z.string()` | Node path to AnimationTree |
| `animation` | `z.string()` | Animation name (must exist unless creating) |
| `library` | `z.string().optional()` | Animation library name; omit or `""` for default library |
| `length` | `PositiveNumber` = `z.number().positive()`, optional, default `1.0` | Animation length in seconds |
| `loop_mode` | `z.enum(['none', 'loop', 'pingpong'])`, optional, default `'none'` | Animation loop mode |
| `track_type` | `z.enum(['value', 'position', 'rotation', 'scale', 'method', 'bezier'])` | Type of animation track |
| `property` | `z.string().optional()` | Property path for value/bezier tracks (e.g. `"position:x"`, `"modulate:a"`) |
| `track_index` | `z.number().int().min(0)` | Zero-based track index |
| `time` | `z.number().min(0)` | Keyframe time in seconds |
| `value` | `PropertyValue` = `z.unknown()` | Any property value (number, string, Vector2, Color, etc.) |
| `parameter` | `z.string()` | AnimationTree parameter path (e.g. `"parameters/blend_position"`) |
| `state_name` | `z.string()` | Name for a new state machine state |
| `properties` | `z.record(z.string(), z.unknown()).optional()` | Key-value pairs to set on created nodes |
| `root_type` | `z.string().optional()` | Animation root node type for AnimationTree |
| `player_path` (on create_animation_tree) | `z.string().optional()` | AnimationPlayer path to link the tree to |

---

## 1. list_animations

**Tool name:** `list_animations`  
**Description:** List all animations on an AnimationPlayer  
**Godot method:** `animation/list`  
**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `player_path` | `string` (NodePath) | ✅ | AnimationPlayer node path |

**Return:** List of animation names registered on the AnimationPlayer.

### Test Scenarios

#### 1.1 Happy path — list animations on a player with animations

**Preconditions:** AnimationPlayer at `"AnimationPlayer"` has at least one animation created (e.g. via `create_animation`).

```json
{
  "player_path": "AnimationPlayer"
}
```

**Expected result:** Success. Response contains a list/array of animation name strings.  
**Notes:** The list should include any animations previously created via `create_animation`.  
**What to pay attention to:** Verify that the response is an array/list of strings, not an object. If animations were created previously, they must be present in the response.

#### 1.2 Happy path — list animations on an empty player

**Preconditions:** AnimationPlayer exists but no animations have been created.

```json
{
  "player_path": "AnimationPlayer"
}
```

**Expected result:** Success. Response contains an empty list `[]` or equivalent.  
**Notes:** Should not error — an empty AnimationPlayer is valid.  
**What to pay attention to:** Ensure that an empty list does not cause an error. The response may be `[]` or `{"animations": []}`.

#### 1.3 Error — non-existent node path

```json
{
  "player_path": "NonExistentNode"
}
```

**Expected result:** Error response (`isError: true`). Message should indicate the node was not found.  
**Notes:** The bridge should return an error when the path doesn't resolve.  
**What to pay attention to:** Verify that `isError: true` is returned and the error message contains information about the unfound node.

#### 1.4 Error — node exists but is not an AnimationPlayer

**Preconditions:** A `Sprite2D` node named `"Sprite2D"` exists in the scene.

```json
{
  "player_path": "Sprite2D"
}
```

**Expected result:** Error response. The node is not an AnimationPlayer.  
**What to pay attention to:** The error message should explicitly state that the node is not an AnimationPlayer.

---

## 2. create_animation

**Tool name:** `create_animation`  
**Description:** Create a new animation on an AnimationPlayer  
**Godot method:** `animation/create`  
**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `player_path` | `string` (NodePath) | ✅ | — | AnimationPlayer node path |
| `animation` | `string` | ✅ | — | Animation name |
| `length` | `number > 0` | ❌ | `1.0` | Animation length in seconds |
| `library` | `string` | ❌ | `""` (default library) | Animation library name |
| `loop_mode` | `"none" \| "loop" \| "pingpong"` | ❌ | `"none"` | Loop mode |

**Return:** Success confirmation.

### Test Scenarios

#### 2.1 Happy path — create animation with minimum params

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk"
}
```

**Expected result:** Success. Animation `"walk"` created with length `1.0` and loop mode `"none"`.  
**Notes:** Default values: `length=1.0`, `loop_mode="none"`, library=default.  
**What to pay attention to:** Verify that after the call, `list_animations` returns `"walk"` in the list.

#### 2.2 Happy path — create animation with all params

```json
{
  "player_path": "AnimationPlayer",
  "animation": "run_cycle",
  "length": 0.8,
  "loop_mode": "loop"
}
```

**Expected result:** Success. Animation `"run_cycle"` created with length `0.8`, loop mode `"loop"`.  
**What to pay attention to:** Verify via `get_animation_info` that length and loop_mode are set correctly.

#### 2.3 Happy path — create animation with pingpong loop

```json
{
  "player_path": "AnimationPlayer",
  "animation": "breathing",
  "length": 2.5,
  "loop_mode": "pingpong"
}
```

**Expected result:** Success.  
**What to pay attention to:** Verify that `loop_mode` is set to `pingpong`, not `loop` or `none`.

#### 2.4 Happy path — create animation in a named library

```json
{
  "player_path": "AnimationPlayer",
  "animation": "attack",
  "length": 0.5,
  "library": "combat"
}
```

**Expected result:** Success. Animation `"attack"` created in library `"combat"`.  
**Notes:** Subsequent calls to other tools referencing this animation should include `"library": "combat"`.  
**What to pay attention to:** When calling `list_animations` without specifying a library, the `"attack"` animation may not appear in the list — need to verify behavior with named libraries.

#### 2.5 Edge case — very small length

```json
{
  "player_path": "AnimationPlayer",
  "animation": "blink",
  "length": 0.01
}
```

**Expected result:** Success. Very short animation is valid.  
**What to pay attention to:** Godot allows short animations. Verify that the value is not rounded to 0.

#### 2.6 Error — duplicate animation name

**Preconditions:** Animation `"walk"` already exists.

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk"
}
```

**Expected result:** Error or overwrite behavior. Depends on Godot — it may overwrite or reject.  
**What to pay attention to:** Verify whether Godot overwrites the existing animation or returns an error. This is important for understanding idempotency.

#### 2.7 Error — invalid loop_mode (not in enum)

```json
{
  "player_path": "AnimationPlayer",
  "animation": "test",
  "loop_mode": "reverse"
}
```

**Expected result:** Zod validation error before the call reaches Godot. `"reverse"` is not in `['none', 'loop', 'pingpong']`.  
**What to pay attention to:** The error should occur at the Zod validation level, not on the Godot side.

#### 2.8 Error — negative length

```json
{
  "player_path": "AnimationPlayer",
  "animation": "test",
  "length": -1.0
}
```

**Expected result:** Zod validation error. `PositiveNumber` requires `> 0`.  
**What to pay attention to:** `z.number().positive()` rejects 0 and negative numbers.

#### 2.9 Error — zero length

```json
{
  "player_path": "AnimationPlayer",
  "animation": "test",
  "length": 0
}
```

**Expected result:** Zod validation error. `PositiveNumber` rejects `0`.  
**What to pay attention to:** Zero is not a positive number.

---

## 3. add_animation_track

**Tool name:** `add_animation_track`  
**Description:** Add a track to an animation  
**Godot method:** `animation/add_track`  
**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `player_path` | `string` (NodePath) | ✅ | AnimationPlayer node path |
| `animation` | `string` | ✅ | Animation name (must already exist) |
| `track_type` | `"value" \| "position" \| "rotation" \| "scale" \| "method" \| "bezier"` | ✅ | Type of track |
| `property` | `string` | ❌ | Property path (required for `value` and `bezier` tracks) |
| `library` | `string` | ❌ | Animation library name |

**Return:** Track index (integer ≥ 0).

### Test Scenarios

#### 3.1 Happy path — add a value track

**Preconditions:** Animation `"walk"` exists on the AnimationPlayer. A `Sprite2D` node exists in the scene.

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_type": "value",
  "property": "Sprite2D:modulate:a"
}
```

**Expected result:** Success. Returns a track index (e.g. `0`).  
**Notes:** The `property` format is `NodePath:property` or `NodePath:sub_property`.  
**What to pay attention to:** Verify that a numeric index >= 0 is returned. The property path format must match Godot's convention (using `:`, not `/`).

#### 3.2 Happy path — add a position track

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_type": "position"
}
```

**Expected result:** Success. Returns next track index.  
**Notes:** `position` track type doesn't require `property` — it implicitly tracks the `position` property.  
**What to pay attention to:** For `position`, `rotation`, `scale` track types, the `property` parameter is not required. Verify that Godot correctly creates a track without explicitly specifying a property.

#### 3.3 Happy path — add a rotation track

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_type": "rotation"
}
```

**Expected result:** Success. Track index returned.

#### 3.4 Happy path — add a scale track

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_type": "scale"
}
```

**Expected result:** Success. Track index returned.

#### 3.5 Happy path — add a method track

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_type": "method"
}
```

**Expected result:** Success. Track index returned.  
**Notes:** Method tracks call GDScript methods at specific times — no `property` needed.

#### 3.6 Happy path — add a bezier track

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_type": "bezier",
  "property": "Sprite2D:position:x"
}
```

**Expected result:** Success. Track index returned.  
**Notes:** Bezier tracks require a `property` path, same as value tracks.

#### 3.7 Happy path — multiple tracks on same animation

**Call 1:**
```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_type": "position"
}
```

**Call 2 (same animation):**
```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_type": "value",
  "property": "Sprite2D:modulate:a"
}
```

**Expected result:** Both succeed. First returns index `0`, second returns index `1`.  
**What to pay attention to:** Track indices must be sequential (0, 1, 2, ...).

#### 3.8 Happy path — track in named library

```json
{
  "player_path": "AnimationPlayer",
  "animation": "attack",
  "track_type": "value",
  "property": "Sprite2D:position:x",
  "library": "combat"
}
```

**Expected result:** Success. Track added to animation `"attack"` in library `"combat"`.  
**Notes:** The animation `"attack"` must have been previously created in library `"combat"` via `create_animation`.

#### 3.9 Error — animation does not exist

```json
{
  "player_path": "AnimationPlayer",
  "animation": "nonexistent_anim",
  "track_type": "value",
  "property": "Sprite2D:position:x"
}
```

**Expected result:** Error. Cannot add a track to an animation that doesn't exist.  
**What to pay attention to:** The error message should indicate that the animation was not found.

#### 3.10 Error — invalid track_type (not in enum)

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_type": "audio"
}
```

**Expected result:** Zod validation error. `"audio"` is not in the enum.  
**What to pay attention to:** The error occurs at the Zod validation level.

#### 3.11 Edge case — value track without property

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_type": "value"
}
```

**Expected result:** Likely an error from Godot side — `value` tracks require a `property` to know which property to animate.  
**Notes:** The `property` field is technically optional in the schema, but may be required by the Godot handler for `value`/`bezier` track types.  
**What to pay attention to:** Verify whether Godot returns an error or creates a track without a property binding. This is an edge case.

---

## 4. set_animation_keyframe

**Tool name:** `set_animation_keyframe`  
**Description:** Set a keyframe in an animation track  
**Godot method:** `animation/set_keyframe`  
**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `player_path` | `string` (NodePath) | ✅ | AnimationPlayer node path |
| `animation` | `string` | ✅ | Animation name |
| `track_index` | `integer ≥ 0` | ✅ | Zero-based track index |
| `time` | `number ≥ 0` | ✅ | Keyframe time in seconds |
| `value` | `any` (PropertyValue) | ✅ | Keyframe value |
| `library` | `string` | ❌ | Animation library name |

**Return:** Success confirmation.

### Test Scenarios

#### 4.1 Happy path — set a position keyframe

**Preconditions:** Animation `"walk"` exists with a `position` track at index `0`.

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_index": 0,
  "time": 0.0,
  "value": [0, 0]
}
```

**Expected result:** Success. Keyframe set at time `0.0` with value `Vector2(0, 0)`.  
**Notes:** For position tracks, `value` should be a 2-element array `[x, y]` representing a `Vector2`.  
**What to pay attention to:** Verify that Godot accepts the array `[0, 0]` as a Vector2. The value format depends on the track type.

#### 4.2 Happy path — set keyframe at later time

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_index": 0,
  "time": 0.5,
  "value": [100, 0]
}
```

**Expected result:** Success. Keyframe set at time `0.5`.  
**What to pay attention to:** Time `0.5` must be within the animation length (default 1.0 sec).

#### 4.3 Happy path — set value keyframe (number)

**Preconditions:** Animation `"walk"` has a `value` track at index `1` targeting `Sprite2D:modulate:a`.

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_index": 1,
  "time": 0.0,
  "value": 1.0
}
```

**Expected result:** Success. Alpha value keyframe set to `1.0` at time `0.0`.

#### 4.4 Happy path — set value keyframe (string/enum)

**Preconditions:** A `value` track targeting a string/enum property.

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_index": 1,
  "time": 0.5,
  "value": "visible"
}
```

**Expected result:** Success if the property accepts string values.  
**What to pay attention to:** The `value` type is `z.unknown()`, meaning it accepts anything. Godot will perform validation on its side.

#### 4.5 Happy path — keyframe at time 0 and at animation end

**Call 1:**
```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_index": 0,
  "time": 0,
  "value": [0, 0]
}
```

**Call 2:**
```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_index": 0,
  "time": 1.0,
  "value": [200, 0]
}
```

**Expected result:** Both succeed. Creates a basic linear animation from `[0,0]` to `[200,0]` over 1 second.  
**What to pay attention to:** Verify that both keyframes are set correctly via `get_animation_info`.

#### 4.6 Happy path — keyframe in named library

```json
{
  "player_path": "AnimationPlayer",
  "animation": "attack",
  "track_index": 0,
  "time": 0.0,
  "value": [0, 0],
  "library": "combat"
}
```

**Expected result:** Success.

#### 4.7 Error — track_index out of range

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_index": 99,
  "time": 0.0,
  "value": [0, 0]
}
```

**Expected result:** Error. Track index `99` doesn't exist.  
**What to pay attention to:** The error message should indicate that the track index is out of range.

#### 4.8 Error — negative track_index

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_index": -1,
  "time": 0.0,
  "value": [0, 0]
}
```

**Expected result:** Zod validation error. `z.number().int().min(0)` rejects `-1`.

#### 4.9 Error — negative time

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_index": 0,
  "time": -0.5,
  "value": [0, 0]
}
```

**Expected result:** Zod validation error. `z.number().min(0)` rejects `-0.5`.

#### 4.10 Error — animation does not exist

```json
{
  "player_path": "AnimationPlayer",
  "animation": "nonexistent",
  "track_index": 0,
  "time": 0.0,
  "value": [0, 0]
}
```

**Expected result:** Error from Godot — animation not found.

#### 4.11 Edge case — time beyond animation length

**Preconditions:** Animation `"walk"` has length `1.0`.

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk",
  "track_index": 0,
  "time": 5.0,
  "value": [1000, 0]
}
```

**Expected result:** Likely success — Godot may allow keyframes beyond the animation length (they just won't play in normal playback). Or error if Godot clamps.  
**What to pay attention to:** Verify Godot's behavior — whether it allows keyframes beyond the animation length. This is important for understanding boundaries.

---

## 5. get_animation_info

**Tool name:** `get_animation_info`  
**Description:** Get detailed information about an animation including tracks and keyframes  
**Godot method:** `animation/get_info`  
**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `player_path` | `string` (NodePath) | ✅ | AnimationPlayer node path |
| `animation` | `string` | ✅ | Animation name |
| `library` | `string` | ❌ | Animation library name |

**Return:** Detailed animation info — length, loop mode, tracks (type, property, keyframes).

### Test Scenarios

#### 5.1 Happy path — get info for animation with tracks and keyframes

**Preconditions:** Animation `"walk"` exists with a position track (index `0`) and two keyframes at times `0.0` and `0.5`.

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk"
}
```

**Expected result:** Success. Response contains:
- `length` (e.g. `1.0`)
- `loop_mode` (e.g. `"none"`)
- `tracks` array with at least one track, each containing `type`, `property`, and `keyframes` (time + value pairs)  
**What to pay attention to:** Verify the response structure — it must contain length, loop mode, and an array of tracks with keyframes. Ensure that keyframe values match those set earlier.

#### 5.2 Happy path — get info for empty animation

**Preconditions:** Animation `"empty_anim"` created but no tracks or keyframes added.

```json
{
  "player_path": "AnimationPlayer",
  "animation": "empty_anim"
}
```

**Expected result:** Success. Response shows animation with `length` and `loop_mode` but an empty tracks list.  
**What to pay attention to:** An empty animation is a valid state. There should be no error.

#### 5.3 Happy path — get info for animation in named library

```json
{
  "player_path": "AnimationPlayer",
  "animation": "attack",
  "library": "combat"
}
```

**Expected result:** Success. Returns info for `"attack"` in library `"combat"`.

#### 5.4 Error — animation does not exist

```json
{
  "player_path": "AnimationPlayer",
  "animation": "nonexistent"
}
```

**Expected result:** Error. Animation not found.  
**What to pay attention to:** The error message should be clear and understandable.

#### 5.5 Error — node not an AnimationPlayer

```json
{
  "player_path": "Sprite2D",
  "animation": "walk"
}
```

**Expected result:** Error. Node is not an AnimationPlayer.

---

## 6. remove_animation

**Tool name:** `remove_animation`  
**Description:** Remove an animation from an AnimationPlayer  
**Godot method:** `animation/remove`  
**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `player_path` | `string` (NodePath) | ✅ | AnimationPlayer node path |
| `animation` | `string` | ✅ | Animation name to remove |
| `library` | `string` | ❌ | Animation library name |

**Return:** Success confirmation.

### Test Scenarios

#### 6.1 Happy path — remove existing animation

**Preconditions:** Animation `"walk"` exists.

```json
{
  "player_path": "AnimationPlayer",
  "animation": "walk"
}
```

**Expected result:** Success. Animation `"walk"` removed.  
**Verification:** Call `list_animations` — `"walk"` should no longer appear.  
**What to pay attention to:** Verify via `list_animations` that the animation is actually removed. There should be no error when removing an existing animation.

#### 6.2 Happy path — remove animation from named library

```json
{
  "player_path": "AnimationPlayer",
  "animation": "attack",
  "library": "combat"
}
```

**Expected result:** Success. Animation `"attack"` removed from library `"combat"`.

#### 6.3 Error — remove non-existent animation

```json
{
  "player_path": "AnimationPlayer",
  "animation": "nonexistent"
}
```

**Expected result:** Error. Animation not found.  
**What to pay attention to:** Godot may return an error or silently ignore (depends on implementation). Verify behavior.

#### 6.4 Error — node not an AnimationPlayer

```json
{
  "player_path": "Sprite2D",
  "animation": "walk"
}
```

**Expected result:** Error.

---

## 7. create_animation_tree

**Tool name:** `create_animation_tree`  
**Description:** Create an AnimationTree node on a given path  
**Godot method:** `animation/create_tree`  
**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` (NodePath) | ✅ | Node path where the AnimationTree will be added |
| `player_path` | `string` | ❌ | AnimationPlayer path to link to |
| `root_type` | `string` | ❌ | Animation root node type (default: `AnimationNodeBlendTree`) |
| `properties` | `Record<string, unknown>` | ❌ | Properties to set on the created AnimationTree |

**Return:** Success confirmation.

### Test Scenarios

#### 7.1 Happy path — create AnimationTree with minimum params

```json
{
  "path": "AnimationTree"
}
```

**Expected result:** Success. AnimationTree node created at `"AnimationTree"` in the scene tree.  
**Notes:** Default root type is `AnimationNodeBlendTree`.  
**What to pay attention to:** Verify via `get_scene_tree` or `get_node_properties` that the AnimationTree node was created.

#### 7.2 Happy path — create AnimationTree linked to AnimationPlayer

```json
{
  "path": "AnimationTree",
  "player_path": "AnimationPlayer"
}
```

**Expected result:** Success. AnimationTree created and linked to `"AnimationPlayer"`.  
**What to pay attention to:** Check the `anim_player` property on the created AnimationTree — it should point to the AnimationPlayer path.

#### 7.3 Happy path — create AnimationTree with custom root type

```json
{
  "path": "AnimationTree",
  "player_path": "AnimationPlayer",
  "root_type": "AnimationNodeStateMachine"
}
```

**Expected result:** Success. AnimationTree created with `AnimationNodeStateMachine` as root.  
**Notes:** This is required for state machine-based animation workflows.  
**What to pay attention to:** The root node type affects the animation tree structure. `AnimationNodeStateMachine` allows creating states and transitions.

#### 7.4 Happy path — create AnimationTree with properties

```json
{
  "path": "AnimationTree",
  "player_path": "AnimationPlayer",
  "properties": {
    "active": true
  }
}
```

**Expected result:** Success. AnimationTree created with `active = true`.  
**What to pay attention to:** The `active: true` property activates the animation tree. Verify that it is set.

#### 7.5 Happy path — create under a parent node

**Preconditions:** A `Node2D` named `"Character"` exists in the scene.

```json
{
  "path": "Character/AnimationTree",
  "player_path": "AnimationPlayer"
}
```

**Expected result:** Success. AnimationTree created as a child of `"Character"`.  
**What to pay attention to:** Verify in the scene tree that the node was created in the correct place in the hierarchy.

#### 7.6 Error — duplicate node path

**Preconditions:** AnimationTree at `"AnimationTree"` already exists.

```json
{
  "path": "AnimationTree"
}
```

**Expected result:** Error or overwrite behavior. Depends on Godot's handler.  
**What to pay attention to:** Verify whether Godot creates a duplicate (with a suffix) or returns an error.

---

## 8. get_animation_tree_structure

**Tool name:** `get_animation_tree_structure`  
**Description:** Get the structure of an AnimationTree including state machines and blend trees  
**Godot method:** `animation/get_tree_structure`  
**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` (NodePath) | ✅ | AnimationTree node path |

**Return:** Tree structure — nested representation of the animation tree's nodes (blend nodes, state machines, animations).

### Test Scenarios

#### 8.1 Happy path — get structure of default blend tree

**Preconditions:** AnimationTree at `"AnimationTree"` created with default root type (`AnimationNodeBlendTree`).

```json
{
  "path": "AnimationTree"
}
```

**Expected result:** Success. Response describes the blend tree structure (likely a tree of blend/blend2/blend3 nodes).  
**What to pay attention to:** The structure must reflect the root type (`AnimationNodeBlendTree`) and contain at least the root node.

#### 8.2 Happy path — get structure of state machine

**Preconditions:** AnimationTree created with `root_type: "AnimationNodeStateMachine"`.

```json
{
  "path": "AnimationTree"
}
```

**Expected result:** Success. Response describes the state machine structure with states and transitions.  
**What to pay attention to:** For a state machine, the structure must contain a list of states and transitions between them.

#### 8.3 Error — node does not exist

```json
{
  "path": "NonExistentTree"
}
```

**Expected result:** Error. Node not found.

#### 8.4 Error — node is not an AnimationTree

```json
{
  "path": "Sprite2D"
}
```

**Expected result:** Error. Node is not an AnimationTree.

---

## 9. set_tree_parameter

**Tool name:** `set_tree_parameter`  
**Description:** Set a parameter on an AnimationTree (e.g. blend amount, state)  
**Godot method:** `animation/set_tree_parameter`  
**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` (NodePath) | ✅ | AnimationTree node path |
| `parameter` | `string` | ✅ | Parameter path (e.g. `"parameters/blend_position"`) |
| `value` | `any` (PropertyValue) | ✅ | Parameter value |

**Return:** Success confirmation.

### Test Scenarios

#### 9.1 Happy path — set blend position (float)

**Preconditions:** AnimationTree at `"AnimationTree"` with a blend tree containing a `Blend2` node.

```json
{
  "path": "AnimationTree",
  "parameter": "parameters/blend_position",
  "value": 0.5
}
```

**Expected result:** Success. Blend position set to `0.5`.  
**Notes:** The exact parameter path depends on the tree structure. `parameters/blend_position` is the most common for `Blend2`.  
**What to pay attention to:** Value `0.5` means an equal blend between two animations. `0.0` = first animation, `1.0` = second.

#### 9.2 Happy path — set blend position (Vector2 for 2D blend)

```json
{
  "path": "AnimationTree",
  "parameter": "parameters/blend_position",
  "value": [0.5, 0.3]
}
```

**Expected result:** Success. 2D blend position set.  
**Notes:** Used with `BlendSpace2D` nodes.  
**What to pay attention to:** For BlendSpace2D, the value must be a two-element array [x, y].

#### 9.3 Happy path — set state machine travel

**Preconditions:** AnimationTree with `AnimationNodeStateMachine` root.

```json
{
  "path": "AnimationTree",
  "parameter": "parameters/playback",
  "value": "walk"
}
```

**Expected result:** Success. State machine transitions to `"walk"` state.  
**Notes:** For state machines, `parameters/playback` controls which state is active.  
**What to pay attention to:** The value must match the state name added via `add_state_machine_state`.

#### 9.4 Happy path — set time scale

```json
{
  "path": "AnimationTree",
  "parameter": "parameters/time_scale",
  "value": 2.0
}
```

**Expected result:** Success. Animation plays at 2x speed.  
**What to pay attention to:** Value `2.0` speeds up the animation by 2x. `0.5` will slow it down by 2x.

#### 9.5 Error — non-existent parameter path

```json
{
  "path": "AnimationTree",
  "parameter": "parameters/nonexistent_param",
  "value": 1.0
}
```

**Expected result:** Error. Parameter doesn't exist in the tree structure.  
**What to pay attention to:** Godot will return an error if the parameter path does not exist in the tree structure.

#### 9.6 Error — AnimationTree does not exist

```json
{
  "path": "NonExistentTree",
  "parameter": "parameters/blend_position",
  "value": 0.5
}
```

**Expected result:** Error. Node not found.

#### 9.7 Error — node is not an AnimationTree

```json
{
  "path": "Sprite2D",
  "parameter": "parameters/blend_position",
  "value": 0.5
}
```

**Expected result:** Error.

---

## 10. add_state_machine_state

**Tool name:** `add_state_machine_state`  
**Description:** Add a state to an AnimationNodeStateMachine  
**Godot method:** `animation/add_state`  
**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` (NodePath) | ✅ | AnimationTree node path |
| `state_name` | `string` | ✅ | Name for the new state |
| `animation` | `string` | ❌ | Animation name to assign to this state |

**Return:** Success confirmation.

### Test Scenarios

#### 10.1 Happy path — add state without animation

**Preconditions:** AnimationTree at `"AnimationTree"` with `AnimationNodeStateMachine` root.

```json
{
  "path": "AnimationTree",
  "state_name": "idle"
}
```

**Expected result:** Success. State `"idle"` added to the state machine.  
**Notes:** Without an `animation` parameter, the state exists but has no animation assigned.  
**What to pay attention to:** Verify via `get_animation_tree_structure` that the `"idle"` state appeared in the structure.

#### 10.2 Happy path — add state with animation

**Preconditions:** Animation `"walk"` exists on the AnimationPlayer, and AnimationTree has `AnimationNodeStateMachine` root.

```json
{
  "path": "AnimationTree",
  "state_name": "walk",
  "animation": "walk"
}
```

**Expected result:** Success. State `"walk"` added and linked to animation `"walk"`.  
**What to pay attention to:** Verify via `get_animation_tree_structure` that the state is bound to the animation.

#### 10.3 Happy path — add multiple states

**Call 1:**
```json
{
  "path": "AnimationTree",
  "state_name": "idle",
  "animation": "idle"
}
```

**Call 2:**
```json
{
  "path": "AnimationTree",
  "state_name": "walk",
  "animation": "walk"
}
```

**Call 3:**
```json
{
  "path": "AnimationTree",
  "state_name": "run",
  "animation": "run"
}
```

**Expected result:** All succeed. State machine now has three states: `idle`, `walk`, `run`.  
**What to pay attention to:** Verify the structure — all three states must be present.

#### 10.4 Error — duplicate state name

**Preconditions:** State `"idle"` already exists.

```json
{
  "path": "AnimationTree",
  "state_name": "idle"
}
```

**Expected result:** Error or overwrite. Depends on Godot's implementation.  
**What to pay attention to:** Verify whether Godot allows duplicate state names or returns an error.

#### 10.5 Error — AnimationTree does not have state machine root

**Preconditions:** AnimationTree created with default root type (`AnimationNodeBlendTree`), not `AnimationNodeStateMachine`.

```json
{
  "path": "AnimationTree",
  "state_name": "idle"
}
```

**Expected result:** Error. The root is a blend tree, not a state machine — cannot add states.  
**What to pay attention to:** This is a critical edge case. Verify that the error explicitly indicates incompatibility of the root node type.

#### 10.6 Error — AnimationTree does not exist

```json
{
  "path": "NonExistentTree",
  "state_name": "idle"
}
```

**Expected result:** Error. Node not found.

#### 10.7 Error — node is not an AnimationTree

```json
{
  "path": "Sprite2D",
  "state_name": "idle"
}
```

**Expected result:** Error.

---

## 11. remove_animation_tree

**Tool name:** `remove_animation_tree`  
**Description:** Remove an AnimationTree node from the scene  
**Godot method:** `animation/remove_tree`  
**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` (NodePath) | ✅ | AnimationTree node path |

**Return:** Success confirmation.

### Test Scenarios

#### 11.1 Happy path — remove existing AnimationTree

**Preconditions:** AnimationTree at `"AnimationTree"` exists in the scene.

```json
{
  "path": "AnimationTree"
}
```

**Expected result:** Success. AnimationTree node removed from the scene.  
**Verification:** Call `get_scene_tree` — `"AnimationTree"` should no longer appear.  
**What to pay attention to:** Verify that the node is actually removed from the scene tree. The undo system should record this action so it can be undone.

#### 11.2 Happy path — remove AnimationTree that is a child of another node

**Preconditions:** AnimationTree at `"Character/AnimationTree"` exists as a child of `"Character"`.

```json
{
  "path": "Character/AnimationTree"
}
```

**Expected result:** Success. AnimationTree removed from `"Character"`.  
**What to pay attention to:** Verify that the parent node `"Character"` still exists and only the AnimationTree child was removed.

#### 11.3 Happy path — remove AnimationTree linked to AnimationPlayer

**Preconditions:** AnimationTree at `"AnimationTree"` exists and is linked to `"AnimationPlayer"` via `anim_player` property.

```json
{
  "path": "AnimationTree"
}
```

**Expected result:** Success. AnimationTree removed. The AnimationPlayer is not affected.  
**What to pay attention to:** Removing an AnimationTree should not affect the AnimationPlayer it was linked to.

#### 11.4 Error — non-existent node path

```json
{
  "path": "NonExistentTree"
}
```

**Expected result:** Error response. AnimationTree not found.  
**What to pay attention to:** Verify that `isError: true` is returned and the error message contains information about the unfound node.

#### 11.5 Error — node is not an AnimationTree

**Preconditions:** A `Sprite2D` node named `"Sprite2D"` exists in the scene.

```json
{
  "path": "Sprite2D"
}
```

**Expected result:** Error response. The node is not an AnimationTree.  
**What to pay attention to:** The error message should explicitly state that the node is not an AnimationTree.

#### 11.6 Error — empty path

```json
{
  "path": ""
}
```

**Expected result:** Error response. Path is required.  
**What to pay attention to:** Verify that an empty path returns a clear error message.

---

## 12. get_tree_parameter

**Tool name:** `get_tree_parameter`  
**Description:** Get the current value of a parameter on an AnimationTree  
**Godot method:** `animation/get_tree_parameter`  
**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `string` (NodePath) | ✅ | AnimationTree node path |
| `parameter` | `string` | ✅ | Parameter path (e.g. `"parameters/blend_position"`) |

**Return:** Object with `parameter` name and current `value`.

### Test Scenarios

#### 12.1 Happy path — get blend position (float)

**Preconditions:** AnimationTree at `"AnimationTree"` with a blend tree containing a `Blend2` node. Blend position was previously set to `0.5` via `set_tree_parameter`.

```json
{
  "path": "AnimationTree",
  "parameter": "parameters/blend_position"
}
```

**Expected result:** Success. Response contains `{"parameter": "parameters/blend_position", "value": 0.5}`.  
**What to pay attention to:** The returned value must match the value that was previously set. The value type should be preserved (float remains float).

#### 12.2 Happy path — get blend position (Vector2 for 2D blend)

**Preconditions:** AnimationTree with a BlendSpace2D. Blend position was set to `[0.5, 0.3]`.

```json
{
  "path": "AnimationTree",
  "parameter": "parameters/blend_position"
}
```

**Expected result:** Success. Response contains the Vector2 value.  
**What to pay attention to:** For BlendSpace2D, the value should be a Vector2 or its array representation.

#### 12.3 Happy path — get state machine playback

**Preconditions:** AnimationTree with `AnimationNodeStateMachine` root. Playback was set to `"walk"`.

```json
{
  "path": "AnimationTree",
  "parameter": "parameters/playback"
}
```

**Expected result:** Success. Response contains the current playback state object.  
**Notes:** State machine playback parameters return an object (AnimationNodeStateMachinePlayback), not a simple value.  
**What to pay attention to:** The value may be an object rather than a simple string. Verify that the response structure handles object types correctly.

#### 12.4 Happy path — get time scale

**Preconditions:** AnimationTree with time scale set to `2.0`.

```json
{
  "path": "AnimationTree",
  "parameter": "parameters/time_scale"
}
```

**Expected result:** Success. Response contains `{"parameter": "parameters/time_scale", "value": 2.0}`.

#### 12.5 Happy path — get parameter that was never explicitly set

**Preconditions:** AnimationTree exists but `parameters/blend_position` was never explicitly set via `set_tree_parameter`.

```json
{
  "path": "AnimationTree",
  "parameter": "parameters/blend_position"
}
```

**Expected result:** Success. Returns the default value (likely `0.0` for float parameters).  
**What to pay attention to:** Godot returns type-based defaults for unset parameters. Verify that the tool returns these defaults rather than erroring.

#### 12.6 Error — non-existent parameter path

```json
{
  "path": "AnimationTree",
  "parameter": "parameters/nonexistent_param"
}
```

**Expected result:** Error. Parameter doesn't exist in the tree structure.  
**What to pay attention to:** The error message should suggest using `get_animation_tree_structure` to see available parameters.

#### 12.7 Error — AnimationTree does not exist

```json
{
  "path": "NonExistentTree",
  "parameter": "parameters/blend_position"
}
```

**Expected result:** Error. Node not found.

#### 12.8 Error — node is not an AnimationTree

```json
{
  "path": "Sprite2D",
  "parameter": "parameters/blend_position"
}
```

**Expected result:** Error. Node is not an AnimationTree.

#### 12.9 Error — empty path

```json
{
  "path": "",
  "parameter": "parameters/blend_position"
}
```

**Expected result:** Error. Path is required.

#### 12.10 Error — empty parameter

```json
{
  "path": "AnimationTree",
  "parameter": ""
}
```

**Expected result:** Error. Parameter is required.

---

## Integration Test Sequences

These sequences test complete workflows spanning multiple tools.

### Sequence A: Full Animation Authoring Workflow

```
1. create_scene        → { node_type: "Node2D", scene_path: "res://test_anim.tscn" }
2. open_scene          → { scene_path: "res://test_anim.tscn" }
3. add_node            → { parent: "", name: "AnimPlayer", type: "AnimationPlayer" }
4. add_node            → { parent: "", name: "Sprite", type: "Sprite2D" }
5. create_animation    → { player_path: "AnimPlayer", animation: "walk", length: 1.0 }
6. add_animation_track → { player_path: "AnimPlayer", animation: "walk", track_type: "position" }
   → Expect: track_index = 0
7. set_animation_keyframe → { player_path: "AnimPlayer", animation: "walk", track_index: 0, time: 0.0, value: [0, 0] }
8. set_animation_keyframe → { player_path: "AnimPlayer", animation: "walk", track_index: 0, time: 1.0, value: [200, 0] }
9. get_animation_info  → { player_path: "AnimPlayer", animation: "walk" }
   → Expect: length=1.0, 1 track, 2 keyframes
10. list_animations    → { player_path: "AnimPlayer" }
    → Expect: ["walk"]
11. remove_animation   → { player_path: "AnimPlayer", animation: "walk" }
12. list_animations    → { player_path: "AnimPlayer" }
    → Expect: [] (empty)
```

**What to pay attention to:** Full animation creation cycle. Verify that each step correctly affects the next. It is especially important to check that keyframes (steps 7-8) are correctly reflected in `get_animation_info` (step 9).

### Sequence B: State Machine Workflow

```
1. create_scene            → { node_type: "Node2D", scene_path: "res://test_sm.tscn" }
2. open_scene              → { scene_path: "res://test_sm.tscn" }
3. add_node                → { parent: "", name: "AnimPlayer", type: "AnimationPlayer" }
4. create_animation        → { player_path: "AnimPlayer", animation: "idle", length: 1.0 }
5. create_animation        → { player_path: "AnimPlayer", animation: "walk", length: 0.8 }
6. create_animation        → { player_path: "AnimPlayer", animation: "run", length: 0.5 }
7. create_animation_tree   → { path: "AnimTree", player_path: "AnimPlayer", root_type: "AnimationNodeStateMachine" }
8. add_state_machine_state → { path: "AnimTree", state_name: "idle", animation: "idle" }
9. add_state_machine_state → { path: "AnimTree", state_name: "walk", animation: "walk" }
10. add_state_machine_state → { path: "AnimTree", state_name: "run", animation: "run" }
11. get_animation_tree_structure → { path: "AnimTree" }
    → Expect: 3 states (idle, walk, run)
12. set_tree_parameter     → { path: "AnimTree", parameter: "parameters/playback", value: "walk" }
    → Expect: success — state machine now in "walk" state
```

**What to pay attention to:** This scenario tests the full state machine workflow. It is critically important that `root_type` is `"AnimationNodeStateMachine"` when creating the tree, otherwise `add_state_machine_state` will not work.

### Sequence C: Blend Tree Workflow

```
1. create_scene            → { node_type: "Node2D", scene_path: "res://test_blend.tscn" }
2. open_scene              → { scene_path: "res://test_blend.tscn" }
3. add_node                → { parent: "", name: "AnimPlayer", type: "AnimationPlayer" }
4. create_animation        → { player_path: "AnimPlayer", animation: "idle", length: 1.0 }
5. create_animation        → { player_path: "AnimPlayer", animation: "walk", length: 1.0 }
6. create_animation_tree   → { path: "AnimTree", player_path: "AnimPlayer" }
   → Default root_type is AnimationNodeBlendTree
7. get_animation_tree_structure → { path: "AnimTree" }
   → Expect: blend tree structure
8. set_tree_parameter      → { path: "AnimTree", parameter: "parameters/blend_position", value: 0.0 }
   → Expect: full idle blend
9. set_tree_parameter      → { path: "AnimTree", parameter: "parameters/blend_position", value: 1.0 }
   → Expect: full walk blend
10. set_tree_parameter     → { path: "AnimTree", parameter: "parameters/blend_position", value: 0.5 }
    → Expect: 50/50 blend
```

**What to pay attention to:** Verify that blend position correctly affects the visual result (if possible to verify visually). Values 0.0 and 1.0 should produce pure animations, 0.5 — an equal blend.

### Sequence D: Library-based Animation Workflow

```
1. create_scene            → { node_type: "Node2D", scene_path: "res://test_lib.tscn" }
2. open_scene              → { scene_path: "res://test_lib.tscn" }
3. add_node                → { parent: "", name: "AnimPlayer", type: "AnimationPlayer" }
4. create_animation        → { player_path: "AnimPlayer", animation: "idle", length: 1.0 }
5. create_animation        → { player_path: "AnimPlayer", animation: "slash", length: 0.4, library: "combat" }
6. add_animation_track     → { player_path: "AnimPlayer", animation: "slash", track_type: "value", property: "Sprite2D:position:x", library: "combat" }
7. set_animation_keyframe  → { player_path: "AnimPlayer", animation: "slash", track_index: 0, time: 0.0, value: 0, library: "combat" }
8. set_animation_keyframe  → { player_path: "AnimPlayer", animation: "slash", track_index: 0, time: 0.4, value: 50, library: "combat" }
9. get_animation_info      → { player_path: "AnimPlayer", animation: "slash", library: "combat" }
   → Expect: length=0.4, 1 track, 2 keyframes
10. list_animations        → { player_path: "AnimPlayer" }
    → Expect: may or may not include "slash" depending on whether default library listing includes other libraries
```

**What to pay attention to:** The `library` parameter must be passed to all calls related to the `"slash"` animation. Verify that `list_animations` without specifying a library does not return animations from named libraries (or vice versa — depends on Godot implementation).

### Sequence E: AnimationTree Lifecycle with Get/Remove

```
1. create_scene            → { node_type: "Node2D", scene_path: "res://test_lifecycle.tscn" }
2. open_scene              → { scene_path: "res://test_lifecycle.tscn" }
3. add_node                → { parent: "", name: "AnimPlayer", type: "AnimationPlayer" }
4. create_animation        → { player_path: "AnimPlayer", animation: "idle", length: 1.0 }
5. create_animation        → { player_path: "AnimPlayer", animation: "walk", length: 1.0 }
6. create_animation_tree   → { path: "AnimTree", player_path: "AnimPlayer" }
   → Default root_type is AnimationNodeBlendTree
7. set_tree_parameter      → { path: "AnimTree", parameter: "parameters/blend_position", value: 0.7 }
8. get_tree_parameter      → { path: "AnimTree", parameter: "parameters/blend_position" }
   → Expect: { parameter: "parameters/blend_position", value: 0.7 }
9. get_animation_tree_structure → { path: "AnimTree" }
   → Expect: blend tree structure, still intact
10. remove_animation_tree  → { path: "AnimTree" }
    → Expect: success — AnimationTree removed
11. get_animation_tree_structure → { path: "AnimTree" }
    → Expect: error — AnimationTree not found
12. get_tree_parameter     → { path: "AnimTree", parameter: "parameters/blend_position" }
    → Expect: error — AnimationTree not found
```

**What to pay attention to:** This sequence tests the full AnimationTree lifecycle: create, set parameter, read parameter back, inspect structure, remove, then verify all read operations fail after removal. The `get_tree_parameter` at step 8 must return the exact value set at step 7. After `remove_animation_tree` at step 10, all subsequent operations on that path must fail with clear errors.

---

## Parameter Validation Summary (Zod-level)

These are errors that should be caught by Zod **before** the request reaches Godot.

| Tool | Parameter | Invalid Value | Expected Error |
|------|-----------|---------------|----------------|
| `create_animation` | `length` | `0` | `PositiveNumber` rejects 0 |
| `create_animation` | `length` | `-1.0` | `PositiveNumber` rejects negative |
| `create_animation` | `loop_mode` | `"reverse"` | Not in `enum(['none', 'loop', 'pingpong'])` |
| `create_animation` | `loop_mode` | `"PINGPONG"` | Enum is case-sensitive |
| `add_animation_track` | `track_type` | `"audio"` | Not in enum |
| `add_animation_track` | `track_type` | `"Value"` | Enum is case-sensitive |
| `set_animation_keyframe` | `track_index` | `-1` | `min(0)` rejects negative |
| `set_animation_keyframe` | `track_index` | `1.5` | `.int()` rejects non-integer |
| `set_animation_keyframe` | `time` | `-0.1` | `min(0)` rejects negative |

**What to pay attention to:** All Zod errors must be returned as validation errors with a description of the problem. Verify that `isError: true` and the error text contains information about the violated rule.

---

## Side Effects & State Dependencies

| Tool | Side Effect | Dependent Tools |
|------|-------------|-----------------|
| `create_animation` | Creates animation on AnimationPlayer | `add_animation_track`, `set_animation_keyframe`, `get_animation_info`, `remove_animation` |
| `add_animation_track` | Adds track to animation (increments track count) | `set_animation_keyframe` (needs valid `track_index`) |
| `set_animation_keyframe` | Adds/updates keyframe on a track | `get_animation_info` (can verify keyframes) |
| `remove_animation` | Deletes animation | `list_animations` (verify removal), `get_animation_info` (should fail after removal) |
| `create_animation_tree` | Creates AnimationTree node in scene | `get_animation_tree_structure`, `set_tree_parameter`, `add_state_machine_state` |
| `add_state_machine_state` | Adds state to state machine | `set_tree_parameter` (can now set `parameters/playback` to this state) |
| `set_tree_parameter` | Changes runtime parameter | Observable via game state or `get_animation_tree_structure` |
| `remove_animation_tree` | Removes AnimationTree node from scene | `get_animation_tree_structure`, `set_tree_parameter`, `add_state_machine_state` (all should fail after removal) |
| `get_tree_parameter` | Reads parameter value (no side effect) | `set_tree_parameter` (verify value matches after set) |