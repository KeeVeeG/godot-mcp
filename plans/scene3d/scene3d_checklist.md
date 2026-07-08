# scene3d — Test Execution Checklist
> See plan: [scene3d_test_plan.md](./scene3d_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: add_mesh_instance
- [ ] 1.1: Add a cube at scene root with no properties
- [ ] 1.2: Add a sphere as child of existing node
- [ ] 1.3: Add a cylinder (enum variant)
- [ ] 1.4: Add a capsule (enum variant)
- [ ] 1.5: Add a plane (enum variant)
- [ ] 1.6: Add a prism (enum variant)
- [ ] 1.7: Add a torus (enum variant)
- [ ] 1.8: Add mesh with custom size and material
- [ ] 1.9: Missing required `parent` parameter
- [ ] 1.10: Missing required `mesh_type` parameter
- [ ] 1.11: Invalid `mesh_type` value
- [ ] 1.12: Empty string `parent` (valid)

## Tool: setup_camera_3d
- [ ] 2.1: Create Camera3D with minimal properties
- [ ] 2.2: Create camera with path omitted (default)
- [ ] 2.3: Configure existing camera at specific path
- [ ] 2.4: Set camera to current (make_current)
- [ ] 2.5: Configure camera with look_at target
- [ ] 2.6: Full camera configuration (all properties)
- [ ] 2.7: Missing required `properties` parameter
- [ ] 2.8: Empty `properties` object
- [ ] 2.9: Path to non-existent node

## Tool: setup_lighting
- [ ] 3.1: Add directional light at scene root
- [ ] 3.2: Add an omni light (enum variant)
- [ ] 3.3: Add a spot light (enum variant)
- [ ] 3.4: Add directional light with properties
- [ ] 3.5: Add omni light with position
- [ ] 3.6: Add spot light with angle and attenuation
- [ ] 3.7: Missing required `parent` parameter
- [ ] 3.8: Missing required `type` parameter
- [ ] 3.9: Invalid `type` value
- [ ] 3.10: Empty `properties` object

## Tool: setup_environment
- [ ] 4.1: Configure background color
- [ ] 4.2: Configure ambient light
- [ ] 4.3: Enable fog with density
- [ ] 4.4: Enable glow post-processing
- [ ] 4.5: Set background mode to sky
- [ ] 4.6: Full environment configuration
- [ ] 4.7: Missing required `path` parameter
- [ ] 4.8: Missing required `properties` parameter
- [ ] 4.9: Empty `properties` object
- [ ] 4.10: Path to non-existent WorldEnvironment node

## Tool: add_gridmap
- [ ] 5.1: Add GridMap at scene root
- [ ] 5.2: Add GridMap as child of existing node
- [ ] 5.3: Add GridMap with mesh_library_path
- [ ] 5.4: Add GridMap with custom cell_size
- [ ] 5.5: Add GridMap with multiple properties
- [ ] 5.6: Missing required `parent` parameter
- [ ] 5.7: Empty `properties` object
- [ ] 5.8: GridMap with non-existent mesh library path

## Tool: set_material_3d
- [ ] 6.1: Set albedo color on a mesh
- [ ] 6.2: Set metallic and roughness
- [ ] 6.3: Apply ShaderMaterial via shader_path
- [ ] 6.4: Set material on deeply nested mesh
- [ ] 6.5: Full StandardMaterial3D configuration
- [ ] 6.6: Missing required `path` parameter
- [ ] 6.7: Missing required `properties` parameter
- [ ] 6.8: Empty `properties` object
- [ ] 6.9: Path to a non-MeshInstance3D node
- [ ] 6.10: Path to non-existent node

