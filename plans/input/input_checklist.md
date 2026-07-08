# input — Test Execution Checklist
> See plan: [input_test_plan.md](./input_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `simulate_key`
- [ ] 1. Press space key with default pressed=true
- [ ] 2. Release space key with pressed=false
- [ ] 3. Simulate auto-repeat echo key event
- [ ] 4. Press key with explicit echo=false
- [ ] 5. Release key with echo flag
- [ ] 6. Test various keycode strings (11 keys)
- [ ] 7. Missing keycode — validation error expected
- [ ] 8. Number as keycode — validation error expected
- [ ] 9. String instead of boolean pressed — validation error
- [ ] 10. String instead of boolean echo — validation error
- [ ] 11. Empty keycode string — passes through to Godot

---

## Tool: `simulate_mouse_click`
- [ ] 1. Left click at position with defaults
- [ ] 2. Right button click
- [ ] 3. Middle button click
- [ ] 4. Mouse button release (pressed=false)
- [ ] 5. Right button release
- [ ] 6. Middle button release
- [ ] 7. Sequential left, right, middle clicks
- [ ] 8. Click at origin position (0, 0)
- [ ] 9. Click at negative screen position
- [ ] 10. Click at large position values
- [ ] 11. Missing position — validation error expected
- [ ] 12. Wrong array length — validation error expected
- [ ] 13. String elements in position — validation error
- [ ] 14. Invalid button enum — validation error expected
- [ ] 15. Three-element position array — validation error

---

## Tool: `simulate_mouse_move`
- [ ] 1. Absolute move to screen position
- [ ] 2. Absolute move to origin (0, 0)
- [ ] 3. Relative move by offset
- [ ] 4. Relative move with negative values
- [ ] 5. Relative move with zero offset
- [ ] 6. Explicit relative=false absolute move
- [ ] 7. Large absolute position
- [ ] 8. Negative absolute position
- [ ] 9. Missing position — validation error expected
- [ ] 10. Wrong array length — validation error expected
- [ ] 11. Non-number elements — validation error expected
- [ ] 12. String instead of boolean relative — validation error

---

## Tool: `simulate_action`
- [ ] 1. Press built-in action with default pressed=true
- [ ] 2. Release an action with pressed=false
- [ ] 3. Test various built-in UI actions (8 actions)
- [ ] 4. Simulate custom user-defined action name
- [ ] 5. Explicit pressed=true
- [ ] 6. Missing action — validation error expected
- [ ] 7. Empty action string — passes through to Godot
- [ ] 8. String instead of boolean pressed — validation error
- [ ] 9. Action name with special characters

---

## Tool: `simulate_sequence`
- [ ] 1. Single key event sequence
- [ ] 2. Multi-event sequence with delays
- [ ] 3. Sequence of keys with no delays
- [ ] 4. Sequence with mouse_click events only
- [ ] 5. Sequence with action events (press+release)
- [ ] 6. Sequence with absolute and relative mouse moves
- [ ] 7. Empty events array — passes through
- [ ] 8. Event with zero delay
- [ ] 9. Event with negative delay
- [ ] 10. Event missing type — validation error expected
- [ ] 11. Event with empty type string
- [ ] 12. Event with extra passthrough properties
- [ ] 13. Missing events param — validation error expected
- [ ] 14. Events as object not array — validation error
- [ ] 15. Large sequence stress test (100 events)
- [ ] 16. Sequence mixing all four event types

---

## Tool: `get_input_actions`
- [ ] 1. Fetch input actions with no arguments
- [ ] 2. Call with extra unexpected params (stripped)
- [ ] 3. Verify built-in UI actions present in list

---

## Tool: `set_input_action`
- [ ] 1. Set action with key event and default deadzone
- [ ] 2. Set action with custom deadzone and two keys
- [ ] 3. Deadzone boundary: minimum (0)
- [ ] 4. Deadzone boundary: maximum (1)
- [ ] 5. Deadzone midpoint (0.5)
- [ ] 6. Set action with mouse_button events
- [ ] 7. Set action with joypad_button event
- [ ] 8. Set action with mixed event types
- [ ] 9. Modify existing action with new mappings
- [ ] 10. Multiple events of same type (WASD)
- [ ] 11. Missing action — validation error expected
- [ ] 12. Missing events — validation error expected
- [ ] 13. Missing both params — validation error expected
- [ ] 14. Deadzone below 0 — validation error expected
- [ ] 15. Deadzone above 1 — validation error expected
- [ ] 16. Deadzone as string — validation error expected
- [ ] 17. Empty action string — passes through
- [ ] 18. Empty events array — passes through
- [ ] 19. Event missing type — validation error expected
- [ ] 20. Event with extra passthrough properties
- [ ] 21. Events as object not array — validation error

---

## Cross-Tool Integration
- [ ] 1. set_input_action → get_input_actions → simulate_action lifecycle
- [ ] 2. simulate_sequence combining key + mouse + action events

