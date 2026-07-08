# particles — Test Execution Checklist
> See plan: [particles_test_plan.md](./particles_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: create_particles
- [ ] 1. Create 2D particles at scene root
- [ ] 2. Create 3D particles at scene root
- [ ] 3. Create particles under specific parent
- [ ] 4. Create particles with properties
- [ ] 5. Create with empty properties object
- [ ] 6. Omit parent param
- [ ] 7. Omit type param
- [ ] 8. Invalid type enum value
- [ ] 9. Non-existent parent path
- [ ] 10. Parent path with nested hierarchy

## Tool: delete_particles
- [ ] 1. Delete existing particle node
- [ ] 2. Delete nested particle node
- [ ] 3. Omit node_path param
- [ ] 4. Non-existent node path
- [ ] 5. Delete non-particle node
- [ ] 6. Delete with empty string path

## Tool: set_particle_material
- [ ] 1. Set basic material properties
- [ ] 2. Set initial velocity properties
- [ ] 3. Set scale and color properties
- [ ] 4. Empty properties object
- [ ] 5. Omit path param
- [ ] 6. Omit properties param
- [ ] 7. Non-existent particle node path
- [ ] 8. Set material on non-particle node

## Tool: set_particle_color_gradient
- [ ] 1. Single color stop gradient
- [ ] 2. Two-color gradient
- [ ] 3. Multi-stop gradient
- [ ] 4. Boundary offset values
- [ ] 5. Empty gradient array
- [ ] 6. Offset below minimum
- [ ] 7. Offset above maximum
- [ ] 8. Invalid color format
- [ ] 9. Omit path param
- [ ] 10. Omit gradient param
- [ ] 11. Omit color in gradient stop
- [ ] 12. Omit offset in gradient stop
- [ ] 13. Non-existent particle node path

## Tool: apply_particle_preset
- [ ] 1. Apply fire preset
- [ ] 2. Apply smoke preset
- [ ] 3. Apply sparks preset
- [ ] 4. Apply rain preset
- [ ] 5. Apply snow preset
- [ ] 6. Apply preset to 3D particle
- [ ] 7. Invalid preset enum value
- [ ] 8. Omit path param
- [ ] 9. Omit preset param
- [ ] 10. Non-existent particle node path
- [ ] 11. Apply preset to non-particle node

## Tool: get_particle_info
- [ ] 1. Get info for 2D particles
- [ ] 2. Get info for 3D particles
- [ ] 3. Get info at nested path
- [ ] 4. Get info for default particles
- [ ] 5. Omit path param
- [ ] 6. Non-existent node path
- [ ] 7. Get info for non-particle node

## Tool: set_particle_emission_shape
- [ ] 1. Set point emission shape
- [ ] 2. Set sphere emission shape
- [ ] 3. Set box emission shape
- [ ] 4. Set ring emission shape
- [ ] 5. Sphere shape with size
- [ ] 6. Box shape with dimensions
- [ ] 7. Empty size array
- [ ] 8. Invalid shape enum value
- [ ] 9. Omit path param
- [ ] 10. Omit shape param
- [ ] 11. Non-numeric size values
- [ ] 12. Non-existent particle node path

## Tool: set_particle_velocity_curve
- [ ] 1. Single curve point
- [ ] 2. Two-point velocity curve
- [ ] 3. Multi-point bell curve
- [ ] 4. Negative velocity values
- [ ] 5. Boundary offset values
- [ ] 6. Zero velocity curve
- [ ] 7. Empty curve array
- [ ] 8. Offset below minimum
- [ ] 9. Offset above maximum
- [ ] 10. Omit path param
- [ ] 11. Omit curve param
- [ ] 12. Omit offset in curve point
- [ ] 13. Omit value in curve point
- [ ] 14. Non-existent particle node path

