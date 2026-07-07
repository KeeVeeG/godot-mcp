# Animation Tools Test Plan

**Source file:** `server/src/tools/animation.ts`  
**Module purpose:** Animation authoring and management — 10 tools covering AnimationPlayer, AnimationTree, state machines, and blend tree parameters.

**Shared type definitions (from `shared-types.ts`):**

| Type | Zod schema | Notes |
|------|-----------|-------|
| `NodePath` | `z.string()` | Scene tree node path, e.g. `"Player/Sprite2D"` or `""` for root |
| `PositiveNumber` | `z.number().positive()` | Number > 0 |
| `PropertyValue` | `z.unknown()` | Any property value |

---

## Tool 1: `list_animations`

**Description:** List all animations on an AnimationPlayer.  
**Handler route:** `animation/list`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `player_path` | `NodePath` (string) | ✅ Yes | AnimationPlayer node path |

### Test Scenarios

#### 1.1 Happy path — list animations on a valid AnimationPlayer with animations
- **Params:** `{ "player_path": "AnimationPlayer" }`
- **Expected result:** Returns an array of animation names (e.g., `["idle", "walk", "run"]`)
- **Notes:** Requires a scene with an AnimationPlayer node that has at least one animation

#### 1.2 Happy path — list animations on a valid AnimationPlayer with no animations
- **Params:** `{ "player_path": "AnimationPlayer" }`
- **Expected result:** Returns an empty array `[]`
- **Notes:** Requires a scene with an AnimationPlayer node that has zero animations

#### 1.3 Edge case — missing required `player_path`
- **Params:** `{}`
- **Expected result:** Zod validation error — `player_path` is required
- **Notes:** Test input schema validation

#### 1.4 Edge case — empty string `player_path`
- **Params:** `{ "player_path": "" }`
- **Expected result:** Error from Godot (no AnimationPlayer at scene root, or scene root is not an AnimationPlayer)
- **Notes:** Validates how the system handles scene root reference

#### 1.5 Edge case — non-existent player_path
- **Params:** `{ "player_path": "NonExistentNode" }`
- **Expected result:** Error from Godot — node not found
- **Notes:** Validates error propagation

#### 1.6 Edge case — player_path points to a non-AnimationPlayer node
- **Params:** `{ "player_path": "Sprite2D" }`
- **Expected result:** Error from Godot — node is not an AnimationPlayer
- **Notes:** Validates type checking on the Godot side

#### 1.7 Edge case — nested player path
- **Params:** `{ "player_path": "Character/AnimationPlayer" }`
- **Expected result:** Returns array of animation names or empty array
- **Notes:** Validates nested path resolution

---

## Tool 2: `create_animation`

**Description:** Create a new animation on an AnimationPlayer.  
**Handler route:** `animation/create`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `player_path` | `NodePath` (string) | ✅ Yes | — | AnimationPlayer node path |
| `animation` | `string` | ✅ Yes | — | Animation name |
| `length` | `PositiveNumber` (number) | No | `1.0` | Animation length in seconds |
| `library` | `string` | No | — | Animation library name (empty for default) |
| `loop_mode` | `enum: "none" \| "loop" \| "pingpong"` | No | `"none"` | Animation loop mode |

### Test Scenarios

#### 2.1 Happy path — create animation with minimum params (defaults)
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim" }`
- **Expected result:** Success — animation created with length 1.0, loop_mode "none", default library
- **Notes:** Basic creation with all defaults

#### 2.2 Happy path — create animation with custom length
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "long_anim", "length": 5.0 }`
- **Expected result:** Success — animation created with length 5.0 seconds
- **Notes:** Validates custom positive length

#### 2.3 Happy path — create animation with loop_mode "loop"
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "loop_anim", "loop_mode": "loop" }`
- **Expected result:** Success — animation created with loop mode set to "loop"
- **Notes:** Validates "loop" enum value

#### 2.4 Happy path — create animation with loop_mode "pingpong"
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "pingpong_anim", "loop_mode": "pingpong" }`
- **Expected result:** Success — animation created with loop mode set to "pingpong"
- **Notes:** Validates "pingpong" enum value

#### 2.5 Happy path — create animation with loop_mode "none" (explicit)
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "no_loop_anim", "loop_mode": "none" }`
- **Expected result:** Success — animation created with loop mode set to "none"
- **Notes:** Validates explicit "none" enum value

#### 2.6 Happy path — create animation with library
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "lib_anim", "library": "my_library" }`
- **Expected result:** Success — animation created in the specified library
- **Notes:** Validates library parameter

#### 2.7 Happy path — create animation with all parameters
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "full_anim", "length": 3.5, "library": "test_lib", "loop_mode": "loop" }`
- **Expected result:** Success — animation created with all custom values
- **Notes:** Full parameter coverage

#### 2.8 Edge case — missing required `player_path`
- **Params:** `{ "animation": "test" }`
- **Expected result:** Zod validation error — `player_path` is required
- **Notes:**

#### 2.9 Edge case — missing required `animation`
- **Params:** `{ "player_path": "AnimationPlayer" }`
- **Expected result:** Zod validation error — `animation` is required
- **Notes:**

#### 2.10 Edge case — negative `length`
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "bad_length", "length": -1.0 }`
- **Expected result:** Zod validation error — length must be positive (> 0)
- **Notes:** PositiveNumber rejects ≤ 0

#### 2.11 Edge case — zero `length`
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "zero_length", "length": 0 }`
- **Expected result:** Zod validation error — length must be positive (> 0)
- **Notes:** Zero is not positive

#### 2.12 Edge case — invalid `loop_mode` enum value
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "bad_mode", "loop_mode": "reverse" }`
- **Expected result:** Zod validation error — invalid enum value (not "none", "loop", or "pingpong")
- **Notes:** Enum validation

#### 2.13 Edge case — non-existent player_path
- **Params:** `{ "player_path": "DoesNotExist", "animation": "test" }`
- **Expected result:** Error from Godot — node not found
- **Notes:**

#### 2.14 Edge case — duplicate animation name (create same name twice)
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "duplicate_name" }`
- **Expected result:** Error from Godot — animation already exists
- **Notes:** Run create twice with same name

---

## Tool 3: `add_animation_track`

**Description:** Add a track to an animation.  
**Handler route:** `animation/add_track`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `player_path` | `NodePath` (string) | ✅ Yes | AnimationPlayer node path |
| `animation` | `string` | ✅ Yes | Animation name |
| `track_type` | `enum: "value" \| "position" \| "rotation" \| "scale" \| "method" \| "bezier"` | ✅ Yes | Type of track to add |
| `property` | `string` | No | Property path for value/bezier tracks (e.g. `'position:x'`) |
| `library` | `string` | No | Animation library name (empty for default) |

### Test Scenarios

#### 3.1 Happy path — add "value" track with property
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_type": "value", "property": "position:x" }`
- **Expected result:** Success — returns track index (integer ≥ 0)
- **Notes:** Requires an existing animation on the AnimationPlayer

#### 3.2 Happy path — add "value" track without property (may be valid or error depending on implementation)
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_type": "value" }`
- **Expected result:** May succeed or error (property is semantically required for value tracks)
- **Notes:** Validates behavior when `property` is omitted for `value` track_type

#### 3.3 Happy path — add "position" track
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_type": "position" }`
- **Expected result:** Success — returns track index
- **Notes:** `property` may be auto-derived or optional for this track type

#### 3.4 Happy path — add "rotation" track
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_type": "rotation" }`
- **Expected result:** Success — returns track index
- **Notes:**

#### 3.5 Happy path — add "scale" track
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_type": "scale" }`
- **Expected result:** Success — returns track index
- **Notes:**

#### 3.6 Happy path — add "method" track
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_type": "method" }`
- **Expected result:** Success — returns track index
- **Notes:** Method tracks call functions at specific times

#### 3.7 Happy path — add "bezier" track with property
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_type": "bezier", "property": "position:x" }`
- **Expected result:** Success — returns track index
- **Notes:**

#### 3.8 Happy path — add track with library specified
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "lib_anim", "track_type": "position", "library": "my_library" }`
- **Expected result:** Success — track added to animation in the specified library
- **Notes:** Requires animation created with a library

#### 3.9 Edge case — missing required `player_path`
- **Params:** `{ "animation": "test_anim", "track_type": "value" }`
- **Expected result:** Zod validation error — `player_path` is required
- **Notes:**

#### 3.10 Edge case — missing required `animation`
- **Params:** `{ "player_path": "AnimationPlayer", "track_type": "value" }`
- **Expected result:** Zod validation error — `animation` is required
- **Notes:**

#### 3.11 Edge case — missing required `track_type`
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim" }`
- **Expected result:** Zod validation error — `track_type` is required
- **Notes:**

#### 3.12 Edge case — invalid `track_type` enum value
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_type": "audio" }`
- **Expected result:** Zod validation error — invalid enum value
- **Notes:** "audio" is not one of the 6 valid track types

#### 3.13 Edge case — non-existent animation name
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "no_such_anim", "track_type": "value", "property": "position:x" }`
- **Expected result:** Error from Godot — animation not found
- **Notes:**

#### 3.14 Edge case — non-existent player_path
- **Params:** `{ "player_path": "GhostPlayer", "animation": "test_anim", "track_type": "value" }`
- **Expected result:** Error from Godot — node not found
- **Notes:**

#### 3.15 Edge case — empty string property for value track
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_type": "value", "property": "" }`
- **Expected result:** Error from Godot — invalid or empty property path
- **Notes:**

#### 3.16 Edge case — add track to an animation in default library with library explicitly empty
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_type": "value", "property": "position:x", "library": "" }`
- **Expected result:** Success — default library used (empty string interpreted as default)
- **Notes:** Validates empty library string behavior

---

## Tool 4: `set_animation_keyframe`

**Description:** Set a keyframe in an animation track.  
**Handler route:** `animation/set_keyframe`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `player_path` | `NodePath` (string) | ✅ Yes | AnimationPlayer node path |
| `animation` | `string` | ✅ Yes | Animation name |
| `track_index` | `number` (int, ≥ 0) | ✅ Yes | Track index |
| `time` | `number` (≥ 0) | ✅ Yes | Keyframe time in seconds |
| `value` | `PropertyValue` (unknown) | ✅ Yes | Keyframe value |
| `library` | `string` | No | Animation library name (empty for default) |

### Test Scenarios

#### 4.1 Happy path — set keyframe on value track
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_index": 0, "time": 0.5, "value": 100.0 }`
- **Expected result:** Success — keyframe set at time 0.5 with value 100.0
- **Notes:** Requires an existing track at index 0 on the animation

#### 4.2 Happy path — set keyframe at time 0
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_index": 0, "time": 0, "value": 0.0 }`
- **Expected result:** Success — keyframe at start of animation
- **Notes:** Time 0 is valid (boundary)

#### 4.3 Happy path — set keyframe with string value
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_index": 0, "time": 1.0, "value": "hello" }`
- **Expected result:** Success — keyframe set with string value
- **Notes:** PropertyValue is z.unknown(), accepts any type

#### 4.4 Happy path — set keyframe with boolean value
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_index": 0, "time": 1.0, "value": true }`
- **Expected result:** Success — keyframe set with boolean value
- **Notes:**

#### 4.5 Happy path — set keyframe with array/object value
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_index": 0, "time": 1.0, "value": { "x": 100, "y": 200 } }`
- **Expected result:** Success — keyframe set with object value (e.g., for Vector2 properties)
- **Notes:**

#### 4.6 Happy path — set keyframe with library
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "lib_anim", "track_index": 0, "time": 0.5, "value": 50.0, "library": "my_library" }`
- **Expected result:** Success — keyframe set in library animation
- **Notes:**

#### 4.7 Edge case — missing required `player_path`
- **Params:** `{ "animation": "test", "track_index": 0, "time": 0, "value": 0 }`
- **Expected result:** Zod validation error — `player_path` is required
- **Notes:**

#### 4.8 Edge case — missing required `animation`
- **Params:** `{ "player_path": "AnimationPlayer", "track_index": 0, "time": 0, "value": 0 }`
- **Expected result:** Zod validation error — `animation` is required
- **Notes:**

#### 4.9 Edge case — missing required `track_index`
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "time": 0, "value": 0 }`
- **Expected result:** Zod validation error — `track_index` is required
- **Notes:**

#### 4.10 Edge case — missing required `time`
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_index": 0, "value": 0 }`
- **Expected result:** Zod validation error — `time` is required
- **Notes:**

#### 4.11 Edge case — missing required `value`
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_index": 0, "time": 0 }`
- **Expected result:** Zod validation error — `value` is required
- **Notes:**

#### 4.12 Edge case — negative `track_index`
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_index": -1, "time": 0, "value": 0 }`
- **Expected result:** Zod validation error — track_index must be ≥ 0 (`.int().min(0)`)
- **Notes:**

#### 4.13 Edge case — non-integer `track_index` (float)
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_index": 0.5, "time": 0, "value": 0 }`
- **Expected result:** Zod validation error — track_index must be integer (`.int()`)
- **Notes:**

#### 4.14 Edge case — negative `time`
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_index": 0, "time": -1.0, "value": 0 }`
- **Expected result:** Zod validation error — time must be ≥ 0 (`.min(0)`)
- **Notes:**

#### 4.15 Edge case — track_index out of bounds
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_index": 999, "time": 0, "value": 0 }`
- **Expected result:** Error from Godot — track index out of range
- **Notes:**

#### 4.16 Edge case — time exceeds animation length
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "track_index": 0, "time": 999.0, "value": 0 }`
- **Expected result:** May succeed (Godot may extend animation length) or error
- **Notes:** Behavior depends on Godot's implementation

#### 4.17 Edge case — set keyframe when no track exists
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "empty_anim", "track_index": 0, "time": 0, "value": 0 }`
- **Expected result:** Error from Godot — no track at index 0
- **Notes:** Requires an animation with zero tracks

---

## Tool 5: `get_animation_info`

**Description:** Get detailed information about an animation including tracks and keyframes.  
**Handler route:** `animation/get_info`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `player_path` | `NodePath` (string) | ✅ Yes | AnimationPlayer node path |
| `animation` | `string` | ✅ Yes | Animation name |
| `library` | `string` | No | Animation library name (empty for default) |

### Test Scenarios

#### 5.1 Happy path — get info on existing animation with tracks
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim" }`
- **Expected result:** Returns animation details including name, length, loop mode, tracks array with track indices/types/properties, and keyframes
- **Notes:** Requires an animation with at least one track and keyframe

#### 5.2 Happy path — get info on existing animation with no tracks
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "empty_anim" }`
- **Expected result:** Returns animation details with empty tracks array
- **Notes:** Requires an animation with zero tracks

#### 5.3 Happy path — get info with library specified
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "lib_anim", "library": "my_library" }`
- **Expected result:** Returns animation details from the specified library
- **Notes:**

#### 5.4 Happy path — get info with empty library (default)
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "test_anim", "library": "" }`
- **Expected result:** Returns animation details from default library
- **Notes:**

#### 5.5 Edge case — missing required `player_path`
- **Params:** `{ "animation": "test_anim" }`
- **Expected result:** Zod validation error — `player_path` is required
- **Notes:**

#### 5.6 Edge case — missing required `animation`
- **Params:** `{ "player_path": "AnimationPlayer" }`
- **Expected result:** Zod validation error — `animation` is required
- **Notes:**

#### 5.7 Edge case — non-existent animation name
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "no_such_anim" }`
- **Expected result:** Error from Godot — animation not found
- **Notes:**

#### 5.8 Edge case — non-existent player_path
- **Params:** `{ "player_path": "NoSuchPlayer", "animation": "test_anim" }`
- **Expected result:** Error from Godot — node not found
- **Notes:**

#### 5.9 Edge case — player_path is not an AnimationPlayer
- **Params:** `{ "player_path": "Node2D", "animation": "test" }`
- **Expected result:** Error from Godot — node is not an AnimationPlayer
- **Notes:**

---

## Tool 6: `remove_animation`

**Description:** Remove an animation from an AnimationPlayer.  
**Handler route:** `animation/remove`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `player_path` | `NodePath` (string) | ✅ Yes | AnimationPlayer node path |
| `animation` | `string` | ✅ Yes | Animation name to remove |
| `library` | `string` | No | Animation library name (empty for default) |

### Test Scenarios

#### 6.1 Happy path — remove an existing animation from default library
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "to_remove" }`
- **Expected result:** Success — animation removed
- **Notes:** Requires an animation named "to_remove" that exists before the call. Verify it's gone via `list_animations` afterward.

#### 6.2 Happy path — remove an animation from a specific library
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "lib_to_remove", "library": "my_library" }`
- **Expected result:** Success — animation removed from the specified library
- **Notes:**

#### 6.3 Edge case — missing required `player_path`
- **Params:** `{ "animation": "test" }`
- **Expected result:** Zod validation error — `player_path` is required
- **Notes:**

#### 6.4 Edge case — missing required `animation`
- **Params:** `{ "player_path": "AnimationPlayer" }`
- **Expected result:** Zod validation error — `animation` is required
- **Notes:**

#### 6.5 Edge case — non-existent animation name
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "no_such_anim" }`
- **Expected result:** Error from Godot — animation not found
- **Notes:**

#### 6.6 Edge case — remove same animation twice (idempotency)
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "already_removed" }`
- **Expected result:** First call succeeds, second call errors (animation no longer exists)
- **Notes:** Run 6.1, then run the same call again

#### 6.7 Edge case — non-existent player_path
- **Params:** `{ "player_path": "GhostNode", "animation": "test" }`
- **Expected result:** Error from Godot — node not found
- **Notes:**

---

## Tool 7: `create_animation_tree`

**Description:** Create an AnimationTree node on a given path.  
**Handler route:** `animation/create_tree`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | ✅ Yes | Node path where the AnimationTree will be added |
| `player_path` | `string` | No | AnimationPlayer path |
| `root_type` | `string` | No | Animation root node type (default: AnimationNodeBlendTree) |
| `properties` | `Record<string, unknown>` | No | Optional properties to set on the AnimationTree |

### Test Scenarios

#### 7.1 Happy path — create AnimationTree with minimum params
- **Params:** `{ "path": "" }`
- **Expected result:** Success — AnimationTree node added to scene root with default settings
- **Notes:** Empty path = scene root

#### 7.2 Happy path — create AnimationTree with explicit player_path
- **Params:** `{ "path": "", "player_path": "AnimationPlayer" }`
- **Expected result:** Success — AnimationTree created and linked to the specified AnimationPlayer
- **Notes:** Requires an AnimationPlayer node in the scene

#### 7.3 Happy path — create AnimationTree with root_type specified
- **Params:** `{ "path": "", "root_type": "AnimationNodeStateMachine" }`
- **Expected result:** Success — AnimationTree created with state machine as root node
- **Notes:**

#### 7.4 Happy path — create AnimationTree with properties
- **Params:** `{ "path": "", "properties": { "active": true } }`
- **Expected result:** Success — AnimationTree created with specified properties applied
- **Notes:**

#### 7.5 Happy path — create AnimationTree with all parameters
- **Params:** `{ "path": "Character", "player_path": "AnimationPlayer", "root_type": "AnimationNodeBlendTree", "properties": { "active": true } }`
- **Expected result:** Success — full configuration applied
- **Notes:** Requires a "Character" node as parent

#### 7.6 Edge case — missing required `path`
- **Params:** `{ "player_path": "AnimationPlayer" }`
- **Expected result:** Zod validation error — `path` is required
- **Notes:**

#### 7.7 Edge case — path points to non-existent parent
- **Params:** `{ "path": "NonExistentParent/AnimationTree" }`
- **Expected result:** Error from Godot — parent node not found
- **Notes:**

#### 7.8 Edge case — player_path points to non-existent AnimationPlayer
- **Params:** `{ "path": "", "player_path": "NoSuchPlayer" }`
- **Expected result:** Error from Godot — AnimationPlayer not found
- **Notes:**

#### 7.9 Edge case — invalid root_type
- **Params:** `{ "path": "", "root_type": "InvalidNodeType" }`
- **Expected result:** Error from Godot — invalid Animation root node type
- **Notes:** Godot validates the root type string

#### 7.10 Edge case — empty properties object
- **Params:** `{ "path": "", "properties": {} }`
- **Expected result:** Success — AnimationTree created with no additional properties
- **Notes:** Should behave same as omitting properties

---

## Tool 8: `get_animation_tree_structure`

**Description:** Get the structure of an AnimationTree including state machines and blend trees.  
**Handler route:** `animation/get_tree_structure`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | ✅ Yes | AnimationTree node path |

### Test Scenarios

#### 8.1 Happy path — get structure of existing AnimationTree
- **Params:** `{ "path": "AnimationTree" }`
- **Expected result:** Returns tree structure with root type, parameters, and child nodes/blend positions
- **Notes:** Requires an AnimationTree node in the scene

#### 8.2 Happy path — get structure of AnimationTree with state machine
- **Params:** `{ "path": "AnimTreeWithSM" }`
- **Expected result:** Returns structure showing state machine nodes and connections
- **Notes:** Requires an AnimationTree with a state machine root

#### 8.3 Happy path — get structure of AnimationTree with blend tree
- **Params:** `{ "path": "AnimTreeWithBlend" }`
- **Expected result:** Returns structure showing blend tree nodes and blend positions
- **Notes:** Requires an AnimationTree with a blend tree root

#### 8.4 Happy path — get structure of empty AnimationTree
- **Params:** `{ "path": "EmptyAnimTree" }`
- **Expected result:** Returns minimal structure — root type only, no children
- **Notes:** Requires an AnimationTree with no modifications

#### 8.5 Edge case — missing required `path`
- **Params:** `{}`
- **Expected result:** Zod validation error — `path` is required
- **Notes:**

#### 8.6 Edge case — non-existent node
- **Params:** `{ "path": "DoesNotExist" }`
- **Expected result:** Error from Godot — node not found
- **Notes:**

#### 8.7 Edge case — path points to non-AnimationTree node
- **Params:** `{ "path": "Sprite2D" }`
- **Expected result:** Error from Godot — node is not an AnimationTree
- **Notes:**

---

## Tool 9: `set_tree_parameter`

**Description:** Set a parameter on an AnimationTree (e.g. blend amount, state).  
**Handler route:** `animation/set_tree_parameter`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | ✅ Yes | AnimationTree node path |
| `parameter` | `string` | ✅ Yes | Parameter path (e.g. `'parameters/blend_position'`) |
| `value` | `PropertyValue` (unknown) | ✅ Yes | Parameter value |

### Test Scenarios

#### 9.1 Happy path — set blend position parameter (numeric)
- **Params:** `{ "path": "AnimationTree", "parameter": "parameters/blend_position", "value": 0.5 }`
- **Expected result:** Success — blend position set to 0.5
- **Notes:** Requires an AnimationTree with a blend space

#### 9.2 Happy path — set blend amount parameter
- **Params:** `{ "path": "AnimationTree", "parameter": "parameters/blend_amount", "value": 0.75 }`
- **Expected result:** Success — blend amount set to 0.75
- **Notes:**

#### 9.3 Happy path — set state transition parameter
- **Params:** `{ "path": "AnimationTree", "parameter": "parameters/conditions/idle_to_walk", "value": true }`
- **Expected result:** Success — condition set to true
- **Notes:** Requires a state machine with a transition condition

#### 9.4 Happy path — set string parameter value
- **Params:** `{ "path": "AnimationTree", "parameter": "parameters/state", "value": "walk" }`
- **Expected result:** Success — string parameter set
- **Notes:**

#### 9.5 Edge case — missing required `path`
- **Params:** `{ "parameter": "parameters/blend", "value": 0.5 }`
- **Expected result:** Zod validation error — `path` is required
- **Notes:**

#### 9.6 Edge case — missing required `parameter`
- **Params:** `{ "path": "AnimationTree", "value": 0.5 }`
- **Expected result:** Zod validation error — `parameter` is required
- **Notes:**

#### 9.7 Edge case — missing required `value`
- **Params:** `{ "path": "AnimationTree", "parameter": "parameters/blend" }`
- **Expected result:** Zod validation error — `value` is required
- **Notes:**

#### 9.8 Edge case — invalid parameter path
- **Params:** `{ "path": "AnimationTree", "parameter": "nonexistent/param", "value": 0.5 }`
- **Expected result:** Error from Godot — parameter not found
- **Notes:**

#### 9.9 Edge case — non-existent AnimationTree
- **Params:** `{ "path": "NoSuchTree", "parameter": "parameters/blend", "value": 0.5 }`
- **Expected result:** Error from Godot — node not found
- **Notes:**

#### 9.10 Edge case — value type mismatch (boolean where number expected)
- **Params:** `{ "path": "AnimationTree", "parameter": "parameters/blend_position", "value": true }`
- **Expected result:** May succeed (type coercion) or error depending on Godot's handling
- **Notes:** PropertyValue is z.unknown() — no zod-level type checking

---

## Tool 10: `add_state_machine_state`

**Description:** Add a state to an AnimationNodeStateMachine.  
**Handler route:** `animation/add_state`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | ✅ Yes | AnimationTree node path |
| `state_name` | `string` | ✅ Yes | Name for the new state |
| `animation` | `string` | No | Animation name to assign to this state |

### Test Scenarios

#### 10.1 Happy path — add state with animation assigned
- **Params:** `{ "path": "AnimationTree", "state_name": "idle", "animation": "idle_anim" }`
- **Expected result:** Success — state "idle" created and linked to animation "idle_anim"
- **Notes:** Requires an AnimationTree with a state machine root and an animation named "idle_anim" on the linked AnimationPlayer

#### 10.2 Happy path — add state without animation (no-op state)
- **Params:** `{ "path": "AnimationTree", "state_name": "empty_state" }`
- **Expected result:** Success — state created without an animation assigned
- **Notes:** Valid for states used as blend targets or intermediate states

#### 10.3 Happy path — add state with nested path
- **Params:** `{ "path": "Character/AnimationTree", "state_name": "run", "animation": "run_anim" }`
- **Expected result:** Success — state added to AnimationTree at nested path
- **Notes:** Requires the nested AnimationTree to exist

#### 10.4 Edge case — missing required `path`
- **Params:** `{ "state_name": "test" }`
- **Expected result:** Zod validation error — `path` is required
- **Notes:**

#### 10.5 Edge case — missing required `state_name`
- **Params:** `{ "path": "AnimationTree" }`
- **Expected result:** Zod validation error — `state_name` is required
- **Notes:**

#### 10.6 Edge case — empty string `state_name`
- **Params:** `{ "path": "AnimationTree", "state_name": "" }`
- **Expected result:** Error from Godot — state name cannot be empty
- **Notes:** Validation happens on Godot side (zod allows empty strings)

#### 10.7 Edge case — duplicate state name
- **Params:** `{ "path": "AnimationTree", "state_name": "duplicate_state" }`
- **Expected result:** Error from Godot — state name already exists
- **Notes:** Run twice with same `state_name`

#### 10.8 Edge case — non-existent animation reference
- **Params:** `{ "path": "AnimationTree", "state_name": "broken", "animation": "no_such_anim" }`
- **Expected result:** Error from Godot — animation not found, OR state created with broken reference
- **Notes:** Behavior depends on Godot's implementation

#### 10.9 Edge case — non-existent AnimationTree
- **Params:** `{ "path": "GhostTree", "state_name": "test" }`
- **Expected result:** Error from Godot — node not found
- **Notes:**

#### 10.10 Edge case — path points to non-AnimationTree node
- **Params:** `{ "path": "Node2D", "state_name": "test" }`
- **Expected result:** Error from Godot — node is not an AnimationTree or root is not a state machine
- **Notes:**

#### 10.11 Edge case — AnimationTree has a blend tree root (not state machine)
- **Params:** `{ "path": "BlendTree", "state_name": "test" }`
- **Expected result:** Error from Godot — root is not an AnimationNodeStateMachine
- **Notes:** Requires an AnimationTree with a blend tree root

---

## Integration Test Flow

The following end-to-end flow tests the full lifecycle of animation tools in sequence:

### Flow 1: Animation Lifecycle (Tools 1, 2, 3, 4, 5, 6)

**Prerequisites:** A scene with an AnimationPlayer node named "AnimationPlayer"

1. **List animations** (1.2) — verify initial state, expect `[]`
2. **Create animation** (2.1) — `{ "player_path": "AnimationPlayer", "animation": "lifecycle_test" }`
3. **List animations** (1.1) — verify `["lifecycle_test"]` exists
4. **Add value track** (3.1) — `{ "player_path": "AnimationPlayer", "animation": "lifecycle_test", "track_type": "value", "property": "position:x" }` → expect track index 0
5. **Add position track** (3.3) — `{ "player_path": "AnimationPlayer", "animation": "lifecycle_test", "track_type": "position" }` → expect track index 1
6. **Set keyframe** (4.1) — `{ "player_path": "AnimationPlayer", "animation": "lifecycle_test", "track_index": 0, "time": 0.5, "value": 100.0 }`
7. **Get animation info** (5.1) — verify tracks and keyframes are present
8. **Remove animation** (6.1) — `{ "player_path": "AnimationPlayer", "animation": "lifecycle_test" }`
9. **List animations** (1.2) — verify `[]` (animation removed)

### Flow 2: AnimationTree + State Machine (Tools 7, 8, 9, 10)

**Prerequisites:** A scene with an AnimationPlayer node named "AnimationPlayer" and an animation "idle_anim"

1. **Create AnimationTree** (7.2) — `{ "path": "", "player_path": "AnimationPlayer", "root_type": "AnimationNodeStateMachine" }`
2. **Get tree structure** (8.1) — verify root is state machine
3. **Add state** (10.1) — `{ "path": "AnimationTree", "state_name": "idle", "animation": "idle_anim" }`
4. **Add second state** (10.2) — `{ "path": "AnimationTree", "state_name": "walk" }`
5. **Get tree structure** (8.1) — verify two states present
6. **Set tree parameter** (9.1) — `{ "path": "AnimationTree", "parameter": "parameters/playback", "value": "idle" }`

---

## Schema Validation Summary

All tools use Zod for input validation. Key constraints:

| Constraint | Applied to | Tools affected |
|-----------|-----------|----------------|
| `NodePath` (required string) | `player_path`, `path` | All 10 tools |
| Required `string` | `animation`, `state_name`, `parameter` | #2-6, #9, #10 |
| `z.enum([...])` | `loop_mode`, `track_type` | #2 (3 values), #3 (6 values) |
| `PositiveNumber` (> 0) | `length` | #2 only |
| `z.number().int().min(0)` | `track_index` | #4 only |
| `z.number().min(0)` | `time` | #4 only |
| `z.unknown()` | `value` | #4, #9 |
| `z.record(z.string(), z.unknown())` | `properties` | #7 only |

**Resolved schema at runtime for `positive` on `length`**: `z.number().positive()` rejects 0, rejects negatives. Minimum valid value is any number > 0 (e.g., `0.001`, `Number.MIN_VALUE`).

**Resolved schema at runtime for `min(0)` on `time` and `track_index`**: 0 is valid. Negative values are rejected.
