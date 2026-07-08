# physics_config — Test Execution Checklist
> See plan: [physics_config_test_plan.md](./physics_config_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: get_physics_settings
- [ ] 1. Get current physics settings on default project
- [ ] 2. Call with extraneous params should succeed
- [ ] 3. Call with undefined params should succeed

## Tool: set_gravity
- [ ] 1. Set typical 2D gravity with x, y only
- [ ] 2. Set typical 3D gravity with all components
- [ ] 3. Set zero gravity on all axes
- [ ] 4. Set negative x and y gravity values
- [ ] 5. Set gravity with floating-point precision
- [ ] 6. Set gravity with very large values
- [ ] 7. Reject missing required param x
- [ ] 8. Reject missing required param y
- [ ] 9. Reject both required params missing
- [ ] 10. Reject string for x
- [ ] 11. Reject boolean for y
- [ ] 12. Reject object for z
- [ ] 13. Succeed with extra unknown params

## Tool: set_physics_fps
- [ ] 1. Set FPS with no params, use default 60
- [ ] 2. Set FPS to minimum value 1
- [ ] 3. Set FPS to maximum value 240
- [ ] 4. Set FPS to common value 30
- [ ] 5. Set FPS to 120
- [ ] 6. Reject FPS below minimum (0)
- [ ] 7. Reject FPS above maximum (241)
- [ ] 8. Reject excessively large FPS (1000)
- [ ] 9. Reject negative FPS value
- [ ] 10. Reject float FPS (60.5)
- [ ] 11. Accept 60.0 as integer FPS
- [ ] 12. Reject string for fps
- [ ] 13. Reject boolean for fps
- [ ] 14. Reject array for fps

## Tool: set_physics_engine
- [ ] 1. Set engine to default
- [ ] 2. Set engine to godot_physics
- [ ] 3. Set engine to jolt (forward to Godot)
- [ ] 4. Reject missing required param engine
- [ ] 5. Reject invalid enum value 'bullet'
- [ ] 6. Reject invalid enum 'godot_physics_2d'
- [ ] 7. Reject empty string for engine
- [ ] 8. Reject number for engine
- [ ] 9. Reject boolean for engine
- [ ] 10. Reject null for engine
- [ ] 11. Succeed with extra unknown params

## Tool: set_collision_layer_name
- [ ] 1. Name layer 1 as Player
- [ ] 2. Name layer 32 as Terrain (max)
- [ ] 3. Name layer 16 as Enemies
- [ ] 4. Name with spaces and special chars
- [ ] 5. Name with Unicode/emoji characters
- [ ] 6. Pass empty string for layer name
- [ ] 7. Pass very long name string
- [ ] 8. Reject layer below minimum (0)
- [ ] 9. Reject layer above maximum (33)
- [ ] 10. Reject float for layer
- [ ] 11. Reject negative layer number
- [ ] 12. Reject missing param layer
- [ ] 13. Reject missing param name
- [ ] 14. Reject both required params missing
- [ ] 15. Reject string for layer
- [ ] 16. Reject number for name
- [ ] 17. Succeed with extra unknown params

## Tool: get_collision_layers
- [ ] 1. Get all collision layers
- [ ] 2. Get layers after naming layers 1-3
- [ ] 3. Call with extraneous params should succeed
- [ ] 4. Call with undefined params should succeed

## Tool: set_default_gravity
- [ ] 1. Set 2D default gravity to 980
- [ ] 2. Set 3D default gravity to 9.8
- [ ] 3. Set gravity magnitude to zero
- [ ] 4. Set gravity to negative magnitude
- [ ] 5. Set gravity to 9.81 (fractional)
- [ ] 6. Set gravity to extremely large value
- [ ] 7. Set gravity to tiny near-microgravity
- [ ] 8. Reject missing required param value
- [ ] 9. Reject string for value
- [ ] 10. Reject boolean for value
- [ ] 11. Reject object for value
- [ ] 12. Reject array for value
- [ ] 13. Succeed with extra unknown params

## Tool: set_default_linear_damp
- [ ] 1. Set damping with no params, use default 0.1
- [ ] 2. Set damping to zero (no damping)
- [ ] 3. Set damping to 1.0 (maximum)
- [ ] 4. Set damping to moderate 0.5
- [ ] 5. Set damping above 1.0 (2.5)
- [ ] 6. Set damping to tiny 0.001
- [ ] 7. Reject negative damping value
- [ ] 8. Reject large negative damping
- [ ] 9. Reject string for value
- [ ] 10. Reject boolean for value
- [ ] 11. Reject array for value
- [ ] 12. Reject null for value
- [ ] 13. Succeed with extra unknown params

## Cross-Tool Integration
- [ ] 1. Full configuration cycle: set all params then read back
- [ ] 2. Overwrite gravity: set then overwrite, verify overwrite
- [ ] 3. Overwrite collision layer name: name then rename, verify rename
- [ ] 4. Tool independence: invalid set calls don't break get tools

