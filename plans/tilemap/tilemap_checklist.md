# tilemap — Test Execution Checklist
> See plan: [tilemap_test_plan.md](./tilemap_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `tilemap_set_cell`
- [ ] 1.1: Basic happy path — set cell at origin
- [ ] 1.2: Set cell with all optional parameters
- [ ] 1.3: Set cell with source_id and atlas_coords only
- [ ] 1.4: Set cell with alternative_tile only
- [ ] 1.5: Set cell with negative coordinates
- [ ] 1.6: Set cell with large coordinates (9999,9999)
- [ ] 1.7: Set cell with source_id as zero
- [ ] 1.8: Set cell with negative source_id
- [ ] 1.9: Set cell with negative alternative_tile
- [ ] 1.10: Set cell with non-integer (float) coordinates
- [ ] 1.11: Missing required path parameter
- [ ] 1.12: Missing required coords parameter
- [ ] 1.13: Coords with only 1 element
- [ ] 1.14: Coords with 3+ element array (extra elements)
- [ ] 1.15: Coords as empty array
- [ ] 1.16: Path as empty string (scene root)
- [ ] 1.17: Path pointing to non-TileMap node
- [ ] 1.18: Set cell on non-existent path

## Tool: `tilemap_fill_rect`
- [ ] 2.1: Basic happy path — fill 3×3 at origin
- [ ] 2.2: Fill a 1×1 rectangle (single cell)
- [ ] 2.3: Fill with all optional parameters
- [ ] 2.4: Fill with negative x/y offset
- [ ] 2.5: Fill a large 100×100 rectangle
- [ ] 2.6: Fill with width = 0 (rejected)
- [ ] 2.7: Fill with height = 0 (rejected)
- [ ] 2.8: Fill with negative width (rejected)
- [ ] 2.9: Fill with negative height (rejected)
- [ ] 2.10: Fill with non-integer rect values (rejected)
- [ ] 2.11: Missing required rect parameter
- [ ] 2.12: Missing required path parameter
- [ ] 2.13: Missing rect sub-fields (partial rect)
- [ ] 2.14: Extra properties in rect object
- [ ] 2.15: atlas_coords with only 1 element (rejected)

## Tool: `tilemap_get_cell`
- [ ] 3.1: Basic happy path — read cell at origin
- [ ] 3.2: Read a previously set cell (consistency)
- [ ] 3.3: Read cell at negative coordinates
- [ ] 3.4: Read cell at large coordinates
- [ ] 3.5: Read empty/never-set cell
- [ ] 3.6: Missing required coords parameter
- [ ] 3.7: Missing required path parameter
- [ ] 3.8: Coords as non-integer array (rejected)
- [ ] 3.9: Path to non-TileMap node

## Tool: `tilemap_clear`
- [ ] 4.1: Basic happy path — clear populated TileMap
- [ ] 4.2: Clear an already-empty TileMap (idempotent)
- [ ] 4.3: Clear at scene root (empty path, rejected)
- [ ] 4.4: Missing required path parameter
- [ ] 4.5: Clear a non-TileMap node

## Tool: `tilemap_get_info`
- [ ] 5.1: Basic happy path — get info from configured TileMap
- [ ] 5.2: Get info from TileMap with no TileSet
- [ ] 5.3: Get info from deep nested TileMap
- [ ] 5.4: Missing required path parameter
- [ ] 5.5: Get info from non-TileMap node

## Tool: `tilemap_get_used_cells`
- [ ] 6.1: Basic happy path — get used cells from populated TileMap
- [ ] 6.2: Get used cells from an empty TileMap
- [ ] 6.3: Get used cells after fill_rect operation
- [ ] 6.4: Get used cells after clear operation
- [ ] 6.5: Missing required path parameter
- [ ] 6.6: Get used cells from non-TileMap node

## Tool: `gridmap_set_cell`
- [ ] 7.1: Basic happy path — set mesh item at origin
- [ ] 7.2: Set item at a positive coordinate
- [ ] 7.3: Set item with negative coordinates
- [ ] 7.4: Clear a cell using item = -1
- [ ] 7.5: Overwrite a previously set cell
- [ ] 7.6: Set item with large item ID
- [ ] 7.7: Missing required path parameter
- [ ] 7.8: Missing required coords parameter
- [ ] 7.9: Missing required item parameter
- [ ] 7.10: Coords with only 2 elements (rejected)
- [ ] 7.11: Coords with 4+ element array (extra elements)
- [ ] 7.12: Coords as non-integer array (rejected)
- [ ] 7.13: Coords as empty array (rejected)
- [ ] 7.14: Set item on non-GridMap node

## Tool: `gridmap_get_cell`
- [ ] 8.1: Basic happy path — read cell at origin
- [ ] 8.2: Read a previously set cell (consistency)
- [ ] 8.3: Read an empty/never-set cell
- [ ] 8.4: Read a cleared cell (verify item = -1)
- [ ] 8.5: Read cell at negative coordinates
- [ ] 8.6: Missing required coords parameter
- [ ] 8.7: Missing required path parameter
- [ ] 8.8: Read from non-GridMap node

## Tool: `gridmap_clear`
- [ ] 9.1: Basic happy path — clear populated GridMap
- [ ] 9.2: Clear an already-empty GridMap (idempotent)
- [ ] 9.3: Missing required path parameter
- [ ] 9.4: Clear a non-GridMap node

## Tool: `gridmap_get_used_cells`
- [ ] 10.1: Basic happy path — get used cells from populated GridMap
- [ ] 10.2: Get used cells from an empty GridMap
- [ ] 10.3: Get used cells after gridmap_set_cell operations
- [ ] 10.4: Get used cells after gridmap_clear operation
- [ ] 10.5: Missing required path parameter
- [ ] 10.6: Get used cells from non-GridMap node

## Tool: `gridmap_get_info`
- [ ] 11.1: Basic happy path — get info from configured GridMap
- [ ] 11.2: Get info from GridMap with no MeshLibrary
- [ ] 11.3: Missing required path parameter
- [ ] 11.4: Get info from non-GridMap node

## Integration Scenarios
- [ ] IS-1: Full TileMap lifecycle (set → read → fill → used cells → clear → verify)
- [ ] IS-2: Full GridMap lifecycle (set → read → used cells → clear → verify)

