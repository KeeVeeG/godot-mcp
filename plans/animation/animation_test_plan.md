# Animation Tools Test Plan

**Source file:** `server/src/tools/animation.ts`
**Godot bridge method prefix:** `animation/`
**Shared schemas used:** `NodePath`, `PositiveNumber`, `PropertyValue` (from `shared-types.ts`)
**Handler pattern:** All tools call `callGodot(bridge, 'animation/<action>', args)`

---

## Shared Type Definitions

| Schema | Type | Constraints |
|--------|------|-------------|
| `NodePath` | `string` | Path in scene tree, e.g. `"Player/Sprite2D"`, `""` for root |
| `PositiveNumber` | `number` | `> 0` |
| `PropertyValue` | `unknown` (any) | No constraints — any serializable value |

---

## Tool: `list_animations`

**Handler:** `callGodot(bridge, 'animation/list', args)`
**Description:** List all animations on an AnimationPlayer

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `player_path` | `NodePath` (string) | **Yes** | AnimationPlayer node path |

### Test Scenarios

#### Scenario 1: Happy path — list animations on a valid AnimationPlayer
- **Description:** Call with a valid AnimationPlayer node path that exists in the current scene
- **Params:** `{ "player_path": "AnimationPlayer" }`
- **Expected result:** JSON response containing an array of animation names (may be empty if none exist). No error.
- **Notes:** Prerequisite: scene must have an `AnimationPlayer` node at the given path.

#### Scenario 2: Empty string path (scene root)
- **Description:** Call with `""` as `player_path` — the scene root itself
- **Params:** `{ "player_path": "" }`
- **Expected result:** Godot-side error because scene root is not an AnimationPlayer. Error response with `isError: true`.
- **Notes:** This tests type mismatch at the Godot plugin level.

#### Scenario 3: Missing required parameter
- **Description:** Omit `player_path` entirely
- **Params:** `{}`
- **Expected result:** Zod validation error from the MCP server framework (not a Godot error). The call should not reach the Godot bridge.
- **Notes:** Tests that `player_path` is properly marked as required.

#### Scenario 4: Non-existent node path
- **Description:** Call with a path that does not exist in the current scene
- **Params:** `{ "player_path": "NonExistentNode" }`
- **Expected result:** Error response from Godot indicating node not found.

#### Scenario 5: Path to a non-AnimationPlayer node
- **Description:** Call with a path to a node that is NOT an AnimationPlayer (e.g., a Sprite2D)
- **Params:** `{ "player_path": "Sprite2D" }`
- **Expected result:** Error response from Godot indicating the node is not an AnimationPlayer.

---

## Tool: `create_animation`

**Handler:** `callGodot(bridge, 'animation/create', args)`
**Description:** Create a new animation on an AnimationPlayer

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `player_path` | `NodePath` (string) | **Yes** | — | AnimationPlayer node path |
| `animation` | `string` | **Yes** | — | Animation name |
| `length` | `PositiveNumber` (number) | No | `1.0` | Animation length in seconds |
| `library` | `string` | No | — | Animation library name (empty for default) |
| `loop_mode` | `enum: "none" \| "loop" \| "pingpong"` | No | `"none"` | Animation loop mode |

### Test Scenarios

#### Scenario 1: Happy path — minimal required params
- **Description:** Create an animation with only required parameters
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk" }`
- **Expected result:** Success response. Animation `"walk"` created with default length 1.0 and loop_mode "none".
- **Notes:** Prerequisite: An AnimationPlayer exists at the given path.

#### Scenario 2: With explicit length
- **Description:** Create an animation with a custom length
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "run", "length": 2.5 }`
- **Expected result:** Success response. Animation created with 2.5 second length.

#### Scenario 3: With loop_mode — "loop"
- **Description:** Create a looping animation
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "idle", "loop_mode": "loop" }`
- **Expected result:** Success response. Animation created with loop mode set to "loop".

#### Scenario 4: With loop_mode — "pingpong"
- **Description:** Create a ping-pong animation
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "bounce", "loop_mode": "pingpong" }`
- **Expected result:** Success response. Animation created with loop mode set to "pingpong".

#### Scenario 5: With loop_mode — "none" (explicit default)
- **Description:** Create a non-looping animation with explicit `"none"`
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "attack", "loop_mode": "none" }`
- **Expected result:** Success response. Same as Scenario 1.

#### Scenario 6: With library parameter
- **Description:** Create an animation in a specific animation library
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "jump", "library": "character_anims" }`
- **Expected result:** Success response. Animation created in the named library.

#### Scenario 7: Edge case — length = 0 (violates PositiveNumber)
- **Description:** Try to create an animation with length 0
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "bad", "length": 0 }`
- **Expected result:** Zod validation error. PositiveNumber requires `> 0`.
- **Notes:** Tests the `z.number().positive()` constraint.

#### Scenario 8: Edge case — negative length
- **Description:** Try to create an animation with negative length
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "bad", "length": -5 }`
- **Expected result:** Zod validation error. PositiveNumber requires `> 0`.

#### Scenario 9: Edge case — invalid loop_mode value
- **Description:** Try to create an animation with an invalid loop_mode
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "bad", "loop_mode": "reverse" }`
- **Expected result:** Zod validation error. Only `"none"`, `"loop"`, `"pingpong"` are allowed.

#### Scenario 10: Missing required `animation` param
- **Description:** Omit the `animation` parameter
- **Params:** `{ "player_path": "AnimationPlayer" }`
- **Expected result:** Zod validation error. `animation` is required.

#### Scenario 11: Missing both required params
- **Description:** Call with no parameters
- **Params:** `{}`
- **Expected result:** Zod validation error for both `player_path` and `animation`.

#### Scenario 12: Duplicate animation name
- **Description:** Create an animation with a name that already exists on the AnimationPlayer
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk" }` (after Scenario 1)
- **Expected result:** Error from Godot indicating animation already exists.

#### Scenario 13: Empty animation name
- **Description:** Create an animation with an empty string name
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "" }`
- **Expected result:** May pass validation (Zod allows empty strings) but likely error from Godot for invalid name.

#### Scenario 14: Very long animation name
- **Description:** Create an animation with a very long name
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }` (128+ chars)
- **Expected result:** Either success (Godot allows it) or error if Godot has length limits.

---

## Tool: `add_animation_track`

**Handler:** `callGodot(bridge, 'animation/add_track', args)`
**Description:** Add a track to an animation

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `player_path` | `NodePath` (string) | **Yes** | AnimationPlayer node path |
| `animation` | `string` | **Yes** | Animation name |
| `track_type` | `enum: "value" \| "position" \| "rotation" \| "scale" \| "method" \| "bezier"` | **Yes** | Type of track to add |
| `property` | `string` | No | Property path for value/bezier tracks (e.g. `'position:x'`) |
| `library` | `string` | No | Animation library name (empty for default) |

### Test Scenarios

#### Scenario 1: Happy path — "value" track
- **Description:** Add a value track with a property path
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_type": "value" }`
- **Expected result:** Success response returning the new track index (integer >= 0).

#### Scenario 2: Track type — "position"
- **Description:** Add a position track
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_type": "position" }`
- **Expected result:** Success response returning track index.

#### Scenario 3: Track type — "rotation"
- **Description:** Add a rotation track
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_type": "rotation" }`
- **Expected result:** Success response returning track index.

#### Scenario 4: Track type — "scale"
- **Description:** Add a scale track
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_type": "scale" }`
- **Expected result:** Success response returning track index.

#### Scenario 5: Track type — "method"
- **Description:** Add a method track
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_type": "method" }`
- **Expected result:** Success response returning track index.

#### Scenario 6: Track type — "bezier"
- **Description:** Add a bezier track with a property path
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_type": "bezier", "property": "position" }`
- **Expected result:** Success response returning track index.

#### Scenario 7: With property parameter on "value" track
- **Description:** Add a value track with an explicit property path
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_type": "value", "property": "position:x" }`
- **Expected result:** Success response. Track targets the specified property.

#### Scenario 8: With library parameter
- **Description:** Add a track to an animation in a named library
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "jump", "track_type": "value", "library": "character_anims" }`
- **Expected result:** Success response returning track index.

#### Scenario 9: Invalid track_type
- **Description:** Try to add a track with an invalid type
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_type": "color" }`
- **Expected result:** Zod validation error. Only the 6 enum values are allowed.

#### Scenario 10: Missing required `track_type`
- **Description:** Omit the `track_type` parameter
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk" }`
- **Expected result:** Zod validation error. `track_type` is required.

#### Scenario 11: Non-existent animation name
- **Description:** Try to add a track to an animation that doesn't exist
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "nonexistent", "track_type": "value" }`
- **Expected result:** Error from Godot indicating animation not found.

#### Scenario 12: Property on non-value/bezier track
- **Description:** Add a "position" track with a property (property is for value/bezier only)
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_type": "position", "property": "position:x" }`
- **Expected result:** May succeed (property ignored) or error from Godot depending on implementation.

---

## Tool: `set_animation_keyframe`

**Handler:** `callGodot(bridge, 'animation/set_keyframe', args)`
**Description:** Set a keyframe in an animation track

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `player_path` | `NodePath` (string) | **Yes** | AnimationPlayer node path |
| `animation` | `string` | **Yes** | Animation name |
| `track_index` | `number` (int, >= 0) | **Yes** | Track index |
| `time` | `number` (>= 0) | **Yes** | Keyframe time in seconds |
| `value` | `PropertyValue` (any) | **Yes** | Keyframe value |
| `library` | `string` | No | Animation library name (empty for default) |

### Test Scenarios

#### Scenario 1: Happy path — numeric value
- **Description:** Set a keyframe with a numeric value
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_index": 0, "time": 0.0, "value": 100 }`
- **Expected result:** Success response. Keyframe set at time 0.0 on track 0.

#### Scenario 2: String value
- **Description:** Set a keyframe with a string value
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_index": 0, "time": 1.0, "value": "visible" }`
- **Expected result:** Success response if the track supports string values, otherwise error.

#### Scenario 3: Boolean value
- **Description:** Set a keyframe with a boolean value
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_index": 0, "time": 0.5, "value": true }`
- **Expected result:** Success response if the track supports boolean values.

#### Scenario 4: Object/compound value
- **Description:** Set a keyframe with a complex object value (e.g., Vector2)
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_index": 0, "time": 0.0, "value": { "x": 10, "y": 20 } }`
- **Expected result:** Success response if the track supports object values.

#### Scenario 5: With library parameter
- **Description:** Set a keyframe on an animation in a named library
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "jump", "track_index": 0, "time": 0.5, "value": 50, "library": "character_anims" }`
- **Expected result:** Success response.

#### Scenario 6: Edge case — time = 0
- **Description:** Set a keyframe at exactly time 0
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_index": 0, "time": 0, "value": 0 }`
- **Expected result:** Success response. Valid boundary value for `z.number().min(0)`.

#### Scenario 7: Edge case — negative time
- **Description:** Try to set a keyframe with negative time
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_index": 0, "time": -1.0, "value": 0 }`
- **Expected result:** Zod validation error. Time must be `>= 0`.

#### Scenario 8: Edge case — negative track_index
- **Description:** Try to set a keyframe on a negative track index
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_index": -1, "time": 0.0, "value": 0 }`
- **Expected result:** Zod validation error. `track_index` must be `>= 0`.

#### Scenario 9: Edge case — non-integer track_index
- **Description:** Try to set a keyframe with a fractional track index
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_index": 0.5, "time": 0.0, "value": 0 }`
- **Expected result:** Zod validation error. `track_index` must be integer via `.int()`.

#### Scenario 10: Edge case — out-of-range track_index
- **Description:** Try to set a keyframe on a track index that doesn't exist
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_index": 9999, "time": 0.0, "value": 0 }`
- **Expected result:** Error from Godot indicating track index out of bounds.

#### Scenario 11: Missing required `value`
- **Description:** Omit the `value` parameter
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_index": 0, "time": 0.0 }`
- **Expected result:** Zod validation error. `value` is required.

#### Scenario 12: Missing required `track_index`
- **Description:** Omit the `track_index` parameter
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "time": 0.0, "value": 0 }`
- **Expected result:** Zod validation error. `track_index` is required.

#### Scenario 13: Time beyond animation length
- **Description:** Set a keyframe at a time greater than the animation length
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk", "track_index": 0, "time": 9999.0, "value": 0 }`
- **Expected result:** May succeed (Godot doesn't reject keyframes beyond length) or may error depending on implementation.

---

## Tool: `get_animation_info`

**Handler:** `callGodot(bridge, 'animation/get_info', args)`
**Description:** Get detailed information about an animation including tracks and keyframes

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `player_path` | `NodePath` (string) | **Yes** | AnimationPlayer node path |
| `animation` | `string` | **Yes** | Animation name |
| `library` | `string` | No | Animation library name (empty for default) |

### Test Scenarios

#### Scenario 1: Happy path — get info for existing animation
- **Description:** Get info about an animation that exists
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk" }`
- **Expected result:** JSON response with animation details: length, loop_mode, tracks (array with each track's type, property, keyframes), etc.

#### Scenario 2: With library parameter
- **Description:** Get info about an animation in a named library
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "jump", "library": "character_anims" }`
- **Expected result:** JSON response with animation details from the specified library.

#### Scenario 3: Non-existent animation
- **Description:** Get info for an animation that does not exist
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "nonexistent_anim" }`
- **Expected result:** Error from Godot indicating animation not found.

#### Scenario 4: Missing `animation` param
- **Description:** Omit the `animation` parameter
- **Params:** `{ "player_path": "AnimationPlayer" }`
- **Expected result:** Zod validation error. `animation` is required.

#### Scenario 5: Empty animation with no tracks
- **Description:** Get info for a freshly created animation with no tracks
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "empty_anim" }`
- **Expected result:** JSON response showing an animation with 0 tracks, default length.

#### Scenario 6: AnimationPlayer with no animations
- **Description:** Query an AnimationPlayer that exists but has no animations at all
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk" }`
- **Expected result:** Error from Godot since the animation doesn't exist.
- **Notes:** Prerequisite: AnimationPlayer exists but `"walk"` animation does not.

---

## Tool: `remove_animation`

**Handler:** `callGodot(bridge, 'animation/remove', args)`
**Description:** Remove an animation from an AnimationPlayer

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `player_path` | `NodePath` (string) | **Yes** | AnimationPlayer node path |
| `animation` | `string` | **Yes** | Animation name to remove |
| `library` | `string` | No | Animation library name (empty for default) |

### Test Scenarios

#### Scenario 1: Happy path — remove existing animation
- **Description:** Remove an animation that exists
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk" }`
- **Expected result:** Success response. Animation removed from the AnimationPlayer.

#### Scenario 2: With library parameter
- **Description:** Remove an animation from a named library
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "jump", "library": "character_anims" }`
- **Expected result:** Success response. Animation removed from the specified library.

#### Scenario 3: Non-existent animation
- **Description:** Try to remove an animation that doesn't exist
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "ghost_anim" }`
- **Expected result:** Error from Godot indicating animation not found.

#### Scenario 4: Missing `animation` param
- **Description:** Omit the `animation` parameter
- **Params:** `{ "player_path": "AnimationPlayer" }`
- **Expected result:** Zod validation error. `animation` is required.

#### Scenario 5: Remove after already removed (idempotency check)
- **Description:** Call remove twice on the same animation
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk" }` (second call)
- **Expected result:** Second call: error from Godot (animation no longer exists).

#### Scenario 6: Remove from empty AnimationPlayer
- **Description:** Try to remove an animation from a player with no animations
- **Params:** `{ "player_path": "AnimationPlayer", "animation": "walk" }`
- **Expected result:** Error from Godot since no animations exist.
- **Notes:** Prerequisite: AnimationPlayer exists with zero animations.

---

## Tool: `create_animation_tree`

**Handler:** `callGodot(bridge, 'animation/create_tree', args)`
**Description:** Create an AnimationTree node on a given path

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | **Yes** | Node path where the AnimationTree will be added |
| `player_path` | `string` | No | AnimationPlayer path |
| `root_type` | `string` | No | Animation root node type (default: AnimationNodeBlendTree) |
| `properties` | `Record<string, unknown>` | No | Optional properties to set on the AnimationTree |

### Test Scenarios

#### Scenario 1: Happy path — minimal params
- **Description:** Create an AnimationTree with only the required path
- **Params:** `{ "path": "AnimationTree" }`
- **Expected result:** Success response. AnimationTree node created at the given path in the scene.

#### Scenario 2: With player_path
- **Description:** Create an AnimationTree linked to a specific AnimationPlayer
- **Params:** `{ "path": "AnimationTree", "player_path": "AnimationPlayer" }`
- **Expected result:** Success response. AnimationTree created and linked to the specified AnimationPlayer.

#### Scenario 3: With root_type
- **Description:** Create an AnimationTree with a specific root node type
- **Params:** `{ "path": "AnimationTree", "root_type": "AnimationNodeStateMachine" }`
- **Expected result:** Success response. AnimationTree created with the specified root type.

#### Scenario 4: With properties
- **Description:** Create an AnimationTree with additional properties
- **Params:** `{ "path": "AnimationTree", "properties": { "active": true, "tree_root": { "type": "AnimationNodeBlendTree" } } }`
- **Expected result:** Success response. Properties applied to the new AnimationTree.

#### Scenario 5: With all optional params
- **Description:** Create an AnimationTree with all parameters specified
- **Params:** `{ "path": "AnimationTree", "player_path": "AnimationPlayer", "root_type": "AnimationNodeBlendTree", "properties": { "active": true } }`
- **Expected result:** Success response. Fully configured AnimationTree created.

#### Scenario 6: Empty properties object
- **Description:** Create an AnimationTree with an empty properties object
- **Params:** `{ "path": "AnimationTree", "properties": {} }`
- **Expected result:** Success response. Same as Scenario 1.

#### Scenario 7: Missing required `path`
- **Description:** Omit the `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error. `path` is required.

#### Scenario 8: Node already exists at path
- **Description:** Try to create an AnimationTree where a node already exists with that name
- **Params:** `{ "path": "AnimationTree" }` (second call)
- **Expected result:** Error from Godot (duplicate node name) or may overwrite depending on implementation.

#### Scenario 9: Invalid root_type
- **Description:** Create an AnimationTree with a non-existent root type
- **Params:** `{ "path": "AnimationTree", "root_type": "NonExistentType" }`
- **Expected result:** Error from Godot indicating unknown type.

#### Scenario 10: properties with non-serializable value
- **Description:** Create an AnimationTree with a property value that cannot be serialized
- **Params:** `{ "path": "AnimationTree", "properties": { "malformed": null } }`
- **Expected result:** May pass or error; `null` is valid JSON, but Godot may reject it depending on the property.

---

## Tool: `get_animation_tree_structure`

**Handler:** `callGodot(bridge, 'animation/get_tree_structure', args)`
**Description:** Get the structure of an AnimationTree including state machines and blend trees

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | **Yes** | AnimationTree node path |

### Test Scenarios

#### Scenario 1: Happy path — get structure of existing AnimationTree
- **Description:** Query the structure of a valid AnimationTree node
- **Params:** `{ "path": "AnimationTree" }`
- **Expected result:** JSON response describing the tree structure: root type, nodes, connections, parameters, etc.

#### Scenario 2: Empty AnimationTree (just created, no states)
- **Description:** Get structure of a freshly created AnimationTree with no customization
- **Params:** `{ "path": "EmptyTree" }`
- **Expected result:** JSON response showing default/empty structure with only the root node.

#### Scenario 3: Non-existent path
- **Description:** Query a path that doesn't exist
- **Params:** `{ "path": "NonExistentTree" }`
- **Expected result:** Error from Godot indicating node not found.

#### Scenario 4: Path to a non-AnimationTree node
- **Description:** Query a node that is not an AnimationTree (e.g., a Sprite2D)
- **Params:** `{ "path": "Sprite2D" }`
- **Expected result:** Error from Godot indicating the node is not an AnimationTree.

#### Scenario 5: Empty string path (scene root)
- **Description:** Query with `""` as the path (scene root)
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot (scene root is not an AnimationTree).

#### Scenario 6: Missing required `path`
- **Description:** Omit the `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error. `path` is required.

---

## Tool: `set_tree_parameter`

**Handler:** `callGodot(bridge, 'animation/set_tree_parameter', args)`
**Description:** Set a parameter on an AnimationTree (e.g. blend amount, state)

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | **Yes** | AnimationTree node path |
| `parameter` | `string` | **Yes** | Parameter path (e.g. `'parameters/blend_position'`) |
| `value` | `PropertyValue` (any) | **Yes** | Parameter value |

### Test Scenarios

#### Scenario 1: Happy path — set blend_position
- **Description:** Set a blend position parameter on an AnimationTree
- **Params:** `{ "path": "AnimationTree", "parameter": "parameters/blend_position", "value": 0.5 }`
- **Expected result:** Success response. Blend position updated.

#### Scenario 2: Set blend_amount
- **Description:** Set a blend amount parameter
- **Params:** `{ "path": "AnimationTree", "parameter": "parameters/blend_amount", "value": 1.0 }`
- **Expected result:** Success response. Blend amount updated.

#### Scenario 3: Set a state transition parameter
- **Description:** Set a parameter that triggers a state machine transition
- **Params:** `{ "path": "AnimationTree", "parameter": "parameters/conditions/move", "value": true }`
- **Expected result:** Success response. State transition parameter set.

#### Scenario 4: Boolean value
- **Description:** Set a parameter with a boolean value
- **Params:** `{ "path": "AnimationTree", "parameter": "parameters/active", "value": true }`
- **Expected result:** Success response if the parameter exists and accepts boolean.

#### Scenario 5: String value
- **Description:** Set a parameter with a string value
- **Params:** `{ "path": "AnimationTree", "parameter": "parameters/name", "value": "idle" }`
- **Expected result:** Success response if the parameter exists and accepts string.

#### Scenario 6: Null/nonexistent parameter
- **Description:** Set a parameter that doesn't exist
- **Params:** `{ "path": "AnimationTree", "parameter": "parameters/nonexistent", "value": 0 }`
- **Expected result:** Error from Godot indicating parameter not found.

#### Scenario 7: Missing required `parameter`
- **Description:** Omit the `parameter` field
- **Params:** `{ "path": "AnimationTree", "value": 0.5 }`
- **Expected result:** Zod validation error. `parameter` is required.

#### Scenario 8: Missing required `value`
- **Description:** Omit the `value` field
- **Params:** `{ "path": "AnimationTree", "parameter": "parameters/blend_position" }`
- **Expected result:** Zod validation error. `value` is required.

#### Scenario 9: Empty parameter string
- **Description:** Set a parameter with an empty string
- **Params:** `{ "path": "AnimationTree", "parameter": "", "value": 0 }`
- **Expected result:** Error from Godot (invalid parameter path).

#### Scenario 10: Path to non-AnimationTree node
- **Description:** Call with a non-AnimationTree node
- **Params:** `{ "path": "Sprite2D", "parameter": "parameters/test", "value": 0 }`
- **Expected result:** Error from Godot indicating the node is not an AnimationTree.

---

## Tool: `add_state_machine_state`

**Handler:** `callGodot(bridge, 'animation/add_state', args)`
**Description:** Add a state to an AnimationNodeStateMachine

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | **Yes** | AnimationTree node path |
| `state_name` | `string` | **Yes** | Name for the new state |
| `animation` | `string` | No | Animation name to assign to this state |

### Test Scenarios

#### Scenario 1: Happy path — minimal params
- **Description:** Add a state with only required parameters
- **Params:** `{ "path": "AnimationTree", "state_name": "idle" }`
- **Expected result:** Success response. State `"idle"` added to the state machine.

#### Scenario 2: With animation assignment
- **Description:** Add a state that plays a specific animation
- **Params:** `{ "path": "AnimationTree", "state_name": "walk", "animation": "walk" }`
- **Expected result:** Success response. State `"walk"` created and linked to animation `"walk"`.

#### Scenario 3: Multiple states
- **Description:** Add a second distinct state after the first
- **Params:** `{ "path": "AnimationTree", "state_name": "run" }`
- **Expected result:** Success response. Second state added without affecting the first.

#### Scenario 4: Duplicate state name
- **Description:** Try to add a state with a name that already exists in the state machine
- **Params:** `{ "path": "AnimationTree", "state_name": "idle" }` (after Scenario 1)
- **Expected result:** Error from Godot indicating duplicate state name.

#### Scenario 5: Non-existent animation reference
- **Description:** Assign a state to an animation that doesn't exist on the AnimationPlayer
- **Params:** `{ "path": "AnimationTree", "state_name": "ghost_state", "animation": "nonexistent_anim" }`
- **Expected result:** Error from Godot indicating animation not found.

#### Scenario 6: Missing required `state_name`
- **Description:** Omit the `state_name` parameter
- **Params:** `{ "path": "AnimationTree" }`
- **Expected result:** Zod validation error. `state_name` is required.

#### Scenario 7: Empty state_name
- **Description:** Add a state with an empty string name
- **Params:** `{ "path": "AnimationTree", "state_name": "" }`
- **Expected result:** Error from Godot (invalid state name).

#### Scenario 8: Missing required `path`
- **Description:** Omit the `path` parameter
- **Params:** `{ "state_name": "idle" }`
- **Expected result:** Zod validation error. `path` is required.

#### Scenario 9: Path to non-AnimationTree node
- **Description:** Call with a node that is not an AnimationTree
- **Params:** `{ "path": "Sprite2D", "state_name": "idle" }`
- **Expected result:** Error from Godot indicating the node is not an AnimationTree.

#### Scenario 10: AnimationTree without a state machine root
- **Description:** Call on an AnimationTree whose root is a BlendTree (not StateMachine)
- **Params:** `{ "path": "BlendTreeRoot", "state_name": "idle" }`
- **Expected result:** Error from Godot because the root must be a StateMachine to add states.

#### Scenario 11: Very long state_name
- **Description:** Add a state with a very long name
- **Params:** `{ "path": "AnimationTree", "state_name": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }` (128+ chars)
- **Expected result:** Either success or error depending on Godot's naming limits.

#### Scenario 12: Special characters in state_name
- **Description:** Add a state with special characters in the name (e.g., `/`, `\`, `:`, spaces)
- **Params:** `{ "path": "AnimationTree", "state_name": "state/with:special chars!" }`
- **Expected result:** May succeed or error depending on Godot's name validation rules.

---

## Cross-Tool Integration Scenarios

These scenarios test sequences of multiple animation tools to verify end-to-end workflows.

### Integration 1: Full animation creation pipeline
1. **Create animation:** `create_animation` with `{ "player_path": "AnimPlayer", "animation": "test_anim", "length": 2.0, "loop_mode": "loop" }`
2. **Add track:** `add_animation_track` with `{ "player_path": "AnimPlayer", "animation": "test_anim", "track_type": "value", "property": "position:x" }`
3. **Set keyframes:** `set_animation_keyframe` at t=0.0 value=0, t=1.0 value=100, t=2.0 value=0
4. **Get info:** `get_animation_info` with `{ "player_path": "AnimPlayer", "animation": "test_anim" }`
   - **Expected:** Returned info should show 1 track, 3 keyframes, length 2.0, loop_mode "loop"
5. **List animations:** `list_animations` with `{ "player_path": "AnimPlayer" }`
   - **Expected:** `"test_anim"` should appear in the list
6. **Remove animation:** `remove_animation` with `{ "player_path": "AnimPlayer", "animation": "test_anim" }`
7. **List again:** `list_animations` — `"test_anim"` should no longer appear

### Integration 2: AnimationTree and state machine creation
1. **Create tree:** `create_animation_tree` with `{ "path": "MyTree", "player_path": "AnimPlayer", "root_type": "AnimationNodeStateMachine" }`
2. **Add states:** `add_state_machine_state` for `"idle"`, `"walk"`, `"run"` (each with corresponding animation names)
3. **Get structure:** `get_animation_tree_structure` with `{ "path": "MyTree" }`
   - **Expected:** Structure should show the state machine root with 3 states
4. **Set parameter:** `set_tree_parameter` with `{ "path": "MyTree", "parameter": "parameters/conditions/is_moving", "value": true }`
   - **Expected:** Success

## Notes for Testers

- All tests require a Godot project with the MCP plugin active and connected.
- Some tests require pre-existing scene setup (AnimationPlayer node, animated objects, etc.).
- Tests that create resources should clean up after themselves where possible.
- Zod validation errors originate from the MCP server (TypeScript), not from Godot.
- Business logic errors (duplicate names, invalid references) originate from the Godot plugin.
- The `library` parameter is optional on all animation tools that have it; default is the built-in library (empty string).
- For `PropertyValue` (z.unknown()), any JSON-serializable value is valid at the schema level; Godot determines acceptability.
