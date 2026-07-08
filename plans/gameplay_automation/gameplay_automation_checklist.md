# gameplay_automation — Test Execution Checklist
> See plan: [gameplay_automation_test_plan.md](./gameplay_automation_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `godot_simulate_gameplay_scenario`
- [ ] 1. Basic single "wait" action
- [ ] 2. Basic "input" action (key press)
- [ ] 3. Basic "move" action
- [ ] 4. Basic "click" action
- [ ] 5. Basic "assert" action
- [ ] 6. Post-step delay via "wait" field
- [ ] 7. Multi-step: all five action types
- [ ] 8. Missing required `scenario` param
- [ ] 9. Invalid `action` type string
- [ ] 10. Empty scenario array
- [ ] 11. Action object without `params` field

## Tool: `godot_record_gameplay`
- [ ] 1. Default parameters (all defaults, 10s)
- [ ] 2. Minimum duration boundary (1 sec)
- [ ] 3. Max duration boundary (300 sec) [SLOW]
- [ ] 4. State snapshots enabled (input + state)
- [ ] 5. Input only, no state snapshots
- [ ] 6. State only, no input events
- [ ] 7. Both input and state disabled
- [ ] 8. Duration below minimum (0)
- [ ] 9. Duration above maximum (301)
- [ ] 10. Negative duration (-5)
- [ ] 11. Non-integer duration (3.5)

## Tool: `godot_replay_gameplay`
- [ ] 1. Default speed (1.0x)
- [ ] 2. Minimum speed boundary (0.1x)
- [ ] 3. Maximum speed boundary (10x)
- [ ] 4. Normal fast speed (2x)
- [ ] 5. Missing required `recording_path`
- [ ] 6. Non-existent recording file
- [ ] 7. Speed below minimum (0.05)
- [ ] 8. Speed above maximum (20)
- [ ] 9. Negative speed (-1)
- [ ] 10. Zero speed (0)

## Tool: `godot_create_test_character`
- [ ] 1. With explicit position
- [ ] 2. Without position (uses default)
- [ ] 3. Non-origin position [100, 5, -50]
- [ ] 4. All-negative coordinates [-10, -20, -30]
- [ ] 5. Large position values [999999, …]
- [ ] 6. Missing required `scene_path`
- [ ] 7. Non-existent scene file
- [ ] 8. Invalid scene_path format (not res://)
- [ ] 9. Position array: wrong length (2 elements)
- [ ] 10. Position array: non-number values

## Tool: `godot_navigate_character`
- [ ] 1. Direct movement (default method)
- [ ] 2. Pathfinding method (`method: "pathfind"`)
- [ ] 3. Explicit direct method
- [ ] 4. Explicit pathfind method
- [ ] 5. Missing required `character_path`
- [ ] 6. Missing required `target`
- [ ] 7. Invalid method value (`"teleport"`)
- [ ] 8. Target array: wrong length (2 elements)
- [ ] 9. Non-existent character node
- [ ] 10. Pathfind without navmesh baked
- [ ] 11. Large target coordinates
- [ ] 12. Floating-point target coordinates

## Tool: `godot_assert_game_state`
- [ ] 1. Single condition, default operator (==)
- [ ] 2. Explicit `==` operator
- [ ] 3. Not-equal `!=` operator
- [ ] 4. Greater-than `>` operator
- [ ] 5. Less-than `<` operator
- [ ] 6. Greater-or-equal `>=` operator
- [ ] 7. Less-or-equal `<=` operator
- [ ] 8. Contains `contains` operator
- [ ] 9. Multiple conditions: all pass
- [ ] 10. Multiple conditions: one fails
- [ ] 11. Missing required `conditions` param
- [ ] 12. Empty conditions array
- [ ] 13. Condition missing `expected` field
- [ ] 14. Invalid operator string (`"matches_regex"`)
- [ ] 15. Non-existent node path
- [ ] 16. Non-existent property name

## Tool: `godot_wait_for_game_event`
- [ ] 1. Signal event, default timeout (5000ms)
- [ ] 2. Node event: wait for creation
- [ ] 3. Property event: wait for value change
- [ ] 4. Custom short timeout (100ms)
- [ ] 5. Custom max timeout (30000ms) [SLOW]
- [ ] 6. Custom min timeout (1ms)
- [ ] 7. Timeout expiration (event never fires)
- [ ] 8. Missing required `event` param
- [ ] 9. Invalid format: no prefix
- [ ] 10. Invalid format: unknown prefix (`"animation:"`)
- [ ] 11. Malformed signal: too few parts
- [ ] 12. Timeout below minimum (0)
- [ ] 13. Timeout above maximum (30001)
- [ ] 14. Non-integer timeout (100.5)
- [ ] 15. Negative timeout (-500)
- [ ] 16. Property event: no expected value

