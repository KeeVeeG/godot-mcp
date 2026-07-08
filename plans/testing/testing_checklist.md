# testing — Test Execution Checklist
> See plan: [testing_test_plan.md](./testing_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `run_test_scenario`
- [ ] 1. Minimal valid scenario with wait step
- [ ] 2. Named scenario with multiple step types
- [ ] 3. Missing required steps parameter
- [ ] 4. Empty object, steps required
- [ ] 5. add_node step type
- [ ] 6. delete_node step type
- [ ] 7. set_property step type
- [ ] 8. assert_node_state step type
- [ ] 9. connect_signal step type
- [ ] 10. wait step type
- [ ] 11. Invalid step type rejected
- [ ] 12. Steps without params field
- [ ] 13. Empty steps array edge case
- [ ] 14. Extra fields passed through via catchall
- [ ] 15. Steps as string rejected
- [ ] 16. Large scenario with many steps

## Tool: `assert_node_state`
- [ ] 1. Default operator equality assertion
- [ ] 2. Not-equal operator
- [ ] 3. Greater-than operator
- [ ] 4. Less-than operator
- [ ] 5. Greater-than-or-equal operator
- [ ] 6. Less-than-or-equal operator
- [ ] 7. Contains operator for strings
- [ ] 8. Contains on non-string edge case
- [ ] 9. Missing required path parameter
- [ ] 10. Missing required property parameter
- [ ] 11. Missing required expected parameter
- [ ] 12. Non-existent node path errors
- [ ] 13. Non-existent property name errors
- [ ] 14. Invalid operator string accepted by Zod
- [ ] 15. Boolean property assertion
- [ ] 16. Array value assertion for Vector2
- [ ] 17. Nested property path assertion
- [ ] 18. Null expected value assertion
- [ ] 19. Type mismatch triggers assertion failure

## Tool: `assert_screen_text`
- [ ] 1. Text exists with default should_exist
- [ ] 2. Text exists with explicit should_exist
- [ ] 3. Text absent with should_exist=false
- [ ] 4. Text present but should_exist=false fails
- [ ] 5. Missing required text parameter
- [ ] 6. Empty object, text required
- [ ] 7. Empty string text edge case
- [ ] 8. Very long text string boundary
- [ ] 9. Special characters in text
- [ ] 10. Unicode characters in text
- [ ] 11. should_exist as string rejected

## Tool: `run_stress_test`
- [ ] 1. Default parameters spawn 100 Node2D
- [ ] 2. Custom node type Sprite2D
- [ ] 3. 3D node type MeshInstance3D
- [ ] 4. Low count of 1 entity
- [ ] 5. Medium count of 500 entities
- [ ] 6. High count of 10000 entities
- [ ] 7. Zero count edge case
- [ ] 8. Negative count accepted by Zod
- [ ] 9. Float count rejected
- [ ] 10. String count rejected
- [ ] 11. Valid parent_path spawns children
- [ ] 12. Non-existent parent_path errors
- [ ] 13. Properties applied to spawned entities
- [ ] 14. All parameters combined
- [ ] 15. properties as string rejected
- [ ] 16. Very long type string boundary
- [ ] 17. Non-existent node type errors

## Tool: `get_test_report`
- [ ] 1. Report after running tests
- [ ] 2. Report before any tests (empty)
- [ ] 3. Report after mixed pass/fail results
- [ ] 4. Report after multi-step scenario
- [ ] 5. Report after stress test
- [ ] 6. Extra params ignored with empty schema
- [ ] 7. Multiple calls, report is cumulative

