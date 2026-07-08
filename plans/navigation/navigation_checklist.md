# navigation — Test Execution Checklist
> See plan: [navigation_test_plan.md](./navigation_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `setup_navigation_region`
- [ ] 1. Create 2D nav region with only path param
- [ ] 2. Create 2D nav region with explicit "2d" dimension
- [ ] 3. Create 3D nav region with explicit "3d" dimension
- [ ] 4. Create nav region under specific parent node
- [ ] 5. Create nav region with custom display name
- [ ] 6. Create nav region with extra config properties
- [ ] 7. Omit required path param — Zod error
- [ ] 8. Pass invalid dimension "4d" — Zod error
- [ ] 9. Edge case — empty string as path
- [ ] 10. Edge case — empty properties object

## Tool: `setup_navigation_agent`
- [ ] 1. Create 2D nav agent with only path param
- [ ] 2. Create 2D nav agent with explicit "2d" dimension
- [ ] 3. Create 3D nav agent with explicit "3d" dimension
- [ ] 4. Create nav agent under specific parent node
- [ ] 5. Create nav agent with custom display name
- [ ] 6. Create nav agent with radius, speed, distance props
- [ ] 7. Omit required path param — Zod error
- [ ] 8. Pass invalid dimension "1d" — Zod error

## Tool: `bake_navigation_mesh`
- [ ] 1. Bake navmesh on existing region with defaults
- [ ] 2. Bake with specific config properties
- [ ] 3. Bake with only one custom property
- [ ] 4. Omit required path param — Zod error
- [ ] 5. Bake on non-existent node — Godot error
- [ ] 6. Bake on wrong node type — Godot error
- [ ] 7. Edge case — empty string as path

## Tool: `set_navigation_layers`
- [ ] 1. Set nav layer to valid value on existing node
- [ ] 2. Set layer to minimum boundary (1)
- [ ] 3. Set layer to maximum boundary (32)
- [ ] 4. Set layer to mid-range value (16)
- [ ] 5. Omit required path param — Zod error
- [ ] 6. Set layer to 0 (below min) — Zod error
- [ ] 7. Set layer to 33 (above max) — Zod error
- [ ] 8. Set layer to negative number — Zod error
- [ ] 9. Set layer to float 3.5 — Zod error
- [ ] 10. Call with only path, no layer

## Tool: `get_navigation_info`
- [ ] 1. Query nav info for existing baked region
- [ ] 2. Query info for region without baked mesh
- [ ] 3. Omit required path param — Zod error
- [ ] 4. Query non-existent node — Godot error
- [ ] 5. Query wrong node type — Godot error
- [ ] 6. Edge case — empty string as path

## Tool: `find_navigation_path`
- [ ] 1. Find 2D path with start, end, and explicit dim
- [ ] 2. Find 3D path with start, end, and explicit dim
- [ ] 3. Auto-detect dimension (dimension omitted)
- [ ] 4. 2D coordinates with explicit "2d" dimension
- [ ] 5. 3D coordinates with explicit "3d" dimension
- [ ] 6. Same start and end points
- [ ] 7. Unreachable destination — empty path array
- [ ] 8. Omit start param — Zod error
- [ ] 9. Omit end param — Zod error
- [ ] 10. Omit both start and end — Zod error
- [ ] 11. Start is empty array — Zod error
- [ ] 12. Start has non-numeric values — Zod error
- [ ] 13. Invalid dimension value — Zod error
- [ ] 14. Single-element array for start position

## Tool: `setup_navigation_link`
- [ ] 1. Create 2D link with no optional params
- [ ] 2. Create 2D link with explicit "2d" dimension
- [ ] 3. Create 3D link with explicit "3d" dimension
- [ ] 4. Create link under specific parent node
- [ ] 5. Create link with custom name
- [ ] 6. Create link with positions, bidirectional, layers
- [ ] 7. All optional params combined in one call
- [ ] 8. Invalid dimension "4d" — Zod error

## Tool: `remove_navigation_region`
- [ ] 1. Remove existing NavigationRegion from scene
- [ ] 2. Remove nested region (path with slashes)
- [ ] 3. Omit required node_path param — Zod error
- [ ] 4. Remove non-existent node — Godot error
- [ ] 5. Remove wrong node type (e.g., Sprite2D)
- [ ] 6. Edge case — empty string as path

## Tool: `remove_navigation_agent`
- [ ] 1. Remove existing NavigationAgent from scene
- [ ] 2. Remove nested agent (path with slashes)
- [ ] 3. Omit required node_path param — Zod error
- [ ] 4. Remove non-existent node — Godot error
- [ ] 5. Remove wrong node type (e.g., Sprite2D)

## Tool: `remove_navigation_link`
- [ ] 1. Remove existing NavigationLink from scene
- [ ] 2. Remove nested link (path with slashes)
- [ ] 3. Omit required node_path param — Zod error
- [ ] 4. Remove non-existent node — Godot error
- [ ] 5. Remove wrong node type (e.g., Sprite2D)

