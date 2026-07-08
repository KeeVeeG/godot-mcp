# animation — Test Execution Checklist
> See plan: [animation_test_plan.md](./animation_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: list_animations
- [ ] 1. List animations on valid AnimationPlayer — happy path
- [ ] 2. Empty string path (scene root) — type mismatch error
- [ ] 3. Missing required parameter — Zod validation error
- [ ] 4. Non-existent node path — node not found error
- [ ] 5. Path to non-AnimationPlayer node — wrong type error

## Tool: create_animation
- [ ] 1. Minimal required params — happy path, defaults applied
- [ ] 2. With explicit custom length (2.5s)
- [ ] 3. With loop_mode "loop" — looping animation
- [ ] 4. With loop_mode "pingpong" — ping-pong animation
- [ ] 5. With loop_mode "none" explicit default
- [ ] 6. With library parameter — named library
- [ ] 7. Edge: length = 0 — PositiveNumber violation
- [ ] 8. Edge: negative length — PositiveNumber violation
- [ ] 9. Edge: invalid loop_mode "reverse" — enum violation
- [ ] 10. Missing required `animation` param — Zod error
- [ ] 11. Missing both required params — Zod error
- [ ] 12. Duplicate animation name — Godot error
- [ ] 13. Empty animation name — Godot error likely
- [ ] 14. Very long animation name (128+ chars)

## Tool: add_animation_track
- [ ] 1. "value" track — happy path, returns track index
- [ ] 2. "position" track — returns track index
- [ ] 3. "rotation" track — returns track index
- [ ] 4. "scale" track — returns track index
- [ ] 5. "method" track — returns track index
- [ ] 6. "bezier" track with property path
- [ ] 7. "value" track with explicit property "position:x"
- [ ] 8. With library parameter on named library animation
- [ ] 9. Invalid track_type "color" — enum violation
- [ ] 10. Missing required `track_type` — Zod error
- [ ] 11. Non-existent animation name — Godot error
- [ ] 12. Property on "position" track — implementation-defined

## Tool: set_animation_keyframe
- [ ] 1. Numeric value keyframe — happy path
- [ ] 2. String value keyframe — track-dependent result
- [ ] 3. Boolean value keyframe — track-dependent result
- [ ] 4. Object/compound value (Vector2) keyframe
- [ ] 5. With library parameter on named library
- [ ] 6. Edge: time = 0 — valid boundary
- [ ] 7. Edge: negative time — Zod validation error
- [ ] 8. Edge: negative track_index — Zod validation error
- [ ] 9. Edge: non-integer track_index (0.5) — Zod error
- [ ] 10. Edge: out-of-range track_index (9999) — Godot error
- [ ] 11. Missing required `value` — Zod error
- [ ] 12. Missing required `track_index` — Zod error
- [ ] 13. Time beyond animation length (9999.0)

## Tool: get_animation_info
- [ ] 1. Get info for existing animation — happy path
- [ ] 2. With library parameter — named library
- [ ] 3. Non-existent animation — Godot error
- [ ] 4. Missing `animation` param — Zod error
- [ ] 5. Empty animation with no tracks — 0 tracks
- [ ] 6. AnimationPlayer with no animations — Godot error

## Tool: remove_animation
- [ ] 1. Remove existing animation — happy path
- [ ] 2. With library parameter — named library
- [ ] 3. Non-existent animation — Godot error
- [ ] 4. Missing `animation` param — Zod error
- [ ] 5. Remove after already removed — idempotency check
- [ ] 6. Remove from empty AnimationPlayer — Godot error

## Tool: create_animation_tree
- [ ] 1. Minimal params (path only) — happy path
- [ ] 2. With player_path linked to AnimationPlayer
- [ ] 3. With root_type "AnimationNodeStateMachine"
- [ ] 4. With properties object (active, tree_root)
- [ ] 5. All optional params specified — fully configured
- [ ] 6. Empty properties object — same as Scenario 1
- [ ] 7. Missing required `path` — Zod error
- [ ] 8. Node already exists at path — Godot error
- [ ] 9. Invalid root_type "NonExistentType" — Godot error
- [ ] 10. Properties with null value — Godot-dependent

## Tool: get_animation_tree_structure
- [ ] 1. Get structure of existing AnimationTree — happy path
- [ ] 2. Empty AnimationTree (just created, no states)
- [ ] 3. Non-existent path — Godot node-not-found error
- [ ] 4. Path to non-AnimationTree node (Sprite2D)
- [ ] 5. Empty string path (scene root) — type mismatch
- [ ] 6. Missing required `path` — Zod error

## Tool: set_tree_parameter
- [ ] 1. Set blend_position = 0.5 — happy path
- [ ] 2. Set blend_amount = 1.0
- [ ] 3. Set state transition condition (boolean)
- [ ] 4. Boolean value on "parameters/active"
- [ ] 5. String value on "parameters/name"
- [ ] 6. Null/nonexistent parameter — Godot error
- [ ] 7. Missing required `parameter` — Zod error
- [ ] 8. Missing required `value` — Zod error
- [ ] 9. Empty parameter string — Godot invalid path error
- [ ] 10. Path to non-AnimationTree node — Godot error

## Tool: add_state_machine_state
- [ ] 1. Minimal params (path + state_name) — happy path
- [ ] 2. With animation assignment linked to existing anim
- [ ] 3. Add second state (multiple states) — no conflict
- [ ] 4. Duplicate state name — Godot error
- [ ] 5. Non-existent animation reference — Godot error
- [ ] 6. Missing required `state_name` — Zod error
- [ ] 7. Empty state_name — Godot invalid name error
- [ ] 8. Missing required `path` — Zod error
- [ ] 9. Path to non-AnimationTree node — Godot error
- [ ] 10. AnimationTree without state machine root — Godot error
- [ ] 11. Very long state_name (128+ chars)
- [ ] 12. Special characters in state_name (/ \ : space)

