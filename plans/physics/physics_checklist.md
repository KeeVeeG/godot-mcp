# physics — Test Execution Checklist
> See plan: [physics_test_plan.md](./physics_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `setup_physics_body`
- [ ] 1. Add body with mass to Player node
- [ ] 2. Add body with empty properties (defaults)
- [ ] 3. Add body to scene root (`""` path)
- [ ] 4. Add body to nested node (`Player/Sprite2D`)
- [ ] 5. Missing `path` — Zod validation error
- [ ] 6. Missing `properties` — Zod validation error
- [ ] 7. Missing both `path` and `properties`
- [ ] 8. Non-existent node path — Godot error
- [ ] 9. Properties with unexpected keys
- [ ] 10. Properties with null values

## Tool: `setup_collision`
- [ ] 1. Box shape, no properties (defaults)
- [ ] 2. Box shape with explicit size
- [ ] 3. Sphere shape with radius
- [ ] 4. Capsule shape with radius and height
- [ ] 5. Cylinder shape with radius and height
- [ ] 6. Convex shape (needs mesh)
- [ ] 7. Concave shape (needs mesh)
- [ ] 8. Polygon shape
- [ ] 9. Circle shape (2D) with radius
- [ ] 10. Rectangle shape (2D) with size
- [ ] 11. Invalid enum — `"triangle"` rejected
- [ ] 12. Invalid enum — empty string rejected
- [ ] 13. Missing `path` — Zod error
- [ ] 14. Missing `shape_type` — Zod error
- [ ] 15. Non-existent node path — Godot error
- [ ] 16. Explicit empty properties object

## Tool: `set_physics_layers`
- [ ] 1. Set only layer on valid node
- [ ] 2. Set only mask on valid node
- [ ] 3. Set both layer and mask simultaneously
- [ ] 4. Neither layer nor mask (just path)
- [ ] 5. Layer = 1 (minimum boundary)
- [ ] 6. Layer = 32 (maximum boundary)
- [ ] 7. Mask = 1 (minimum boundary)
- [ ] 8. Mask = 32 (maximum boundary)
- [ ] 9. Layer = 0 (below min) — Zod error
- [ ] 10. Layer = 33 (above max) — Zod error
- [ ] 11. Layer = -1 (negative) — Zod error
- [ ] 12. Layer = 1.5 (non-integer) — Zod error
- [ ] 13. Mask = 0 (below min) — Zod error
- [ ] 14. Mask = 33 (above max) — Zod error
- [ ] 15. Mask = 2.7 (non-integer) — Zod error
- [ ] 16. Missing `path` — Zod error
- [ ] 17. Non-existent node path — Godot error
- [ ] 18. Node without collision object — Godot error

## Tool: `get_physics_layers`
- [ ] 1. Get layers on node with collision
- [ ] 2. Query scene root
- [ ] 3. Missing `path` — Zod error
- [ ] 4. Non-existent node path — Godot error
- [ ] 5. Node without collision object — Godot error

## Tool: `get_collision_info`
- [ ] 1. Get info on valid physics body
- [ ] 2. Query nested node path
- [ ] 3. Missing `path` — Zod error
- [ ] 4. Non-existent node path — Godot error
- [ ] 5. Node without physics body — Godot error
- [ ] 6. Query scene root

## Tool: `add_raycast`
- [ ] 1. Add raycast to scene root, no props
- [ ] 2. Add raycast as child of named node
- [ ] 3. Add raycast with target position
- [ ] 4. Add raycast with enabled = true
- [ ] 5. Add raycast with collide_with_areas/bodies
- [ ] 6. Add raycast with empty properties object
- [ ] 7. Add raycast to nested parent
- [ ] 8. Missing `parent_path` — Zod error
- [ ] 9. Non-existent parent path — Godot error
- [ ] 10. Properties with invalid types — Godot error

## Tool: `get_physics_material`
- [ ] 1. Get material on node with physics body
- [ ] 2. Node with body but no material assigned
- [ ] 3. Missing `path` — Zod error
- [ ] 4. Non-existent node path — Godot error
- [ ] 5. Node without collision object — Godot error
- [ ] 6. Query scene root

## Tool: `set_physics_material`
- [ ] 1. Set friction only (0.5)
- [ ] 2. Set bounce only (0.8)
- [ ] 3. Set rough flag to true
- [ ] 4. Set absorbent flag to true
- [ ] 5. Set all four properties at once
- [ ] 6. Friction = 0 (boundary minimum)
- [ ] 7. Bounce = 0 (fully inelastic)
- [ ] 8. Bounce = 1 (perfectly elastic)
- [ ] 9. Friction < 0 (negative) — Zod error
- [ ] 10. Bounce < 0 (negative) — Zod error
- [ ] 11. Bounce > 1 — Zod error
- [ ] 12. Rough = false explicitly
- [ ] 13. Absorbent = false explicitly
- [ ] 14. Non-boolean for rough — Zod error
- [ ] 15. Non-boolean for absorbent — Zod error
- [ ] 16. Missing `path` — Zod error
- [ ] 17. Non-existent node path — Godot error
- [ ] 18. Node without collision object — Godot error
- [ ] 19. Friction as float in range (0.75)
- [ ] 20. Bounce = 0.5 (mid-range)
- [ ] 21. All optional params omitted (just path)

## Cross-Tool Workflow: Full physics pipeline
- [ ] 1. Setup body → collision → layers → material → verify
- [ ] 2. Add raycasts to empty scene

