# TileMap & GridMap Tool Test Plan

**Source file:** `server/src/tools/tilemap.ts`  
**Module description:** 11 tools for 2D TileMap manipulation and 3D GridMap tile-based level editing  
**Generated:** 2026-07-08  

---

## Shared Type Dependencies

All tools import the following from `shared-types.ts`:

| Import    | Zod type                                          | Description                                                         |
|-----------|---------------------------------------------------|---------------------------------------------------------------------|
| `z`       | Zod namespace                                     | Validation library                                                  |
| `NodePath`| `z.string()`                                      | Node path (e.g. `"TileMap"`). `""` = scene root.                    |
| `Coord2D` | `z.array(z.number().int()).min(2).transform(...)` | Integer coordinates `[x, y]`. Accepts arrays of 2+ elements.        |
| `Coord3D` | `z.array(z.number().int()).min(3).transform(...)` | Integer coordinates `[x, y, z]`. Accepts arrays of 3+ elements.     |

**Coord2D behavior:** Accepts any integer array with ≥2 elements. Only first two (`[a[0], a[1]]`) are used.  
**Coord3D behavior:** Accepts any integer array with ≥3 elements. Only first three (`[a[0], a[1], a[2]]`) are used.

---

## TileMap Tools

---

## Tool 1: `tilemap_set_cell`

**Description:** Set a single cell in a TileMap.  
**Handler:** `callGodot(bridge, 'tilemap/set_cell', args)`  
**Expected return:** Success/error JSON. On success, returns confirmation the cell was set.

### Parameters

| Parameter        | Type              | Required | Default       | Description                                  |
|------------------|-------------------|----------|---------------|----------------------------------------------|
| `path`           | `string` (NodePath) | **Yes** | —             | TileMap node path (e.g. `"TileMap"`, `""`)   |
| `coords`         | `[int, int]` (Coord2D) | **Yes** | —         | Integer coordinates `[x, y]`                 |
| `source_id`      | `number` (int)    | No       | `undefined`   | TileSet source ID                            |
| `atlas_coords`   | `[int, int]` (Coord2D) | No   | `undefined`   | Atlas coordinates `[x, y]`                   |
| `alternative_tile`| `number` (int)   | No       | `undefined`   | Alternative tile ID                          |

### Test Scenarios

#### 1.1: Basic happy path — set a cell at the origin
- **Description:** Set a tile on a TileMap at cell (0, 0).  
- **Params:** `{ path: "TileMap", coords: [0, 0] }`  
- **Expected result:** Success. Cell (0, 0) is set on the TileMap (with default source/tile values from Godot).  
- **Notes:** Simplest valid call. Minimum required params only.

#### 1.2: Set a cell with all optional parameters
- **Description:** Set a tile at (5, 3) with explicit source_id, atlas_coords, and alternative_tile.  
- **Params:** `{ path: "TileMap", coords: [5, 3], source_id: 0, atlas_coords: [2, 1], alternative_tile: 0 }`  
- **Expected result:** Success. Cell is set with the specified tile data.  
- **Notes:** Validates all optional params passed together.

#### 1.3: Set cell with only `source_id` and `atlas_coords`
- **Description:** Set a tile with source and atlas coords but no alternative_tile.  
- **Params:** `{ path: "TileMap", coords: [3, 7], source_id: 0, atlas_coords: [0, 0] }`  
- **Expected result:** Success. Cell set with specified source and atlas coordinates.  
- **Notes:** Validates optional subset.

#### 1.4: Set cell with only `alternative_tile`
- **Description:** Set a tile with alternative_tile only (no source_id or atlas_coords).  
- **Params:** `{ path: "TileMap", coords: [1, 1], alternative_tile: 2 }`  
- **Expected result:** Success or error depending on Godot behavior.  
- **Notes:** Validates optional param in isolation.

#### 1.5: Set cell with negative coordinates
- **Description:** Set a cell at negative coordinates.  
- **Params:** `{ path: "TileMap", coords: [-5, -10] }`  
- **Expected result:** Success. TileMap supports negative cell coordinates.  
- **Notes:** Boundary — negative coords.

#### 1.6: Set cell with large coordinates
- **Description:** Set a cell at large positive coordinates.  
- **Params:** `{ path: "TileMap", coords: [9999, 9999] }`  
- **Expected result:** Success. TileMap should handle large cell coordinates.  
- **Notes:** Boundary — large values.

#### 1.7: Set cell with `source_id` as zero
- **Description:** Use source_id = 0.  
- **Params:** `{ path: "TileMap", coords: [0, 0], source_id: 0 }`  
- **Expected result:** Success. Source ID 0 is valid (default source in TileSet).  
- **Notes:** Boundary — zero value for optional param.

#### 1.8: Set cell with `source_id` as negative
- **Description:** Use a negative source_id.  
- **Params:** `{ path: "TileMap", coords: [0, 0], source_id: -1 }`  
- **Expected result:** Likely error from Godot. Negative source IDs are invalid.  
- **Notes:** Edge case — negative integer for source_id.

#### 1.9: Set cell with `alternative_tile` as negative
- **Description:** Use a negative alternative_tile.  
- **Params:** `{ path: "TileMap", coords: [0, 0], alternative_tile: -1 }`  
- **Expected result:** Likely error from Godot. Negative alternative tile IDs are invalid.  
- **Notes:** Edge case — negative integer.

#### 1.10: Set cell with non-integer coordinates
- **Description:** Provide float values for coords.  
- **Params:** `{ path: "TileMap", coords: [1.5, 2.3] }`  
- **Expected result:** Error (Zod validation). Coord2D requires `.int()`.  
- **Notes:** Edge case — type violation.

#### 1.11: Missing required `path` parameter
- **Description:** Omit the `path` parameter entirely.  
- **Params:** `{ coords: [0, 0] }`  
- **Expected result:** Error (Zod validation). `path` is required.  
- **Notes:** Edge case — missing required param.

#### 1.12: Missing required `coords` parameter
- **Description:** Omit the `coords` parameter entirely.  
- **Params:** `{ path: "TileMap" }`  
- **Expected result:** Error (Zod validation). `coords` is required.  
- **Notes:** Edge case — missing required param.

#### 1.13: Coords with only 1 element
- **Description:** Provide a single-element array for coords.  
- **Params:** `{ path: "TileMap", coords: [0] }`  
- **Expected result:** Error (Zod validation). Coord2D requires `.min(2)`.  
- **Notes:** Edge case — array too short.

#### 1.14: Coords with extra elements (3+ element array)
- **Description:** Provide a 3-element array for coords (only first two used).  
- **Params:** `{ path: "TileMap", coords: [5, 3, 99] }`  
- **Expected result:** Success. Only [5, 3] is used per Coord2D transform.  
- **Notes:** Edge case — Coord2D accepts ≥2 elements and truncates.

#### 1.15: Coords as empty array
- **Description:** Provide empty array for coords.  
- **Params:** `{ path: "TileMap", coords: [] }`  
- **Expected result:** Error (Zod validation). `.min(2)` fails.  
- **Notes:** Edge case — empty array.

#### 1.16: path as empty string (scene root)
- **Description:** Use `""` as the path (scene root).  
- **Params:** `{ path: "", coords: [0, 0] }`  
- **Expected result:** Error from Godot. The scene root is not a TileMap node.  
- **Notes:** Edge case — valid NodePath but invalid target.

#### 1.17: path pointing to non-TileMap node
- **Description:** Point to a node that is not a TileMap (e.g. a Sprite2D).  
- **Params:** `{ path: "Sprite2D", coords: [0, 0] }`  
- **Expected result:** Error from Godot. Node is not a TileMap.  
- **Notes:** Edge case — wrong node type.

#### 1.18: Set cell on non-existent path
- **Description:** Point to a node that does not exist.  
- **Params:** `{ path: "NonExistentTileMap", coords: [0, 0] }`  
- **Expected result:** Error from Godot. Node not found.  
- **Notes:** Edge case — missing node.

---

## Tool 2: `tilemap_fill_rect`

**Description:** Fill a rectangular area of a TileMap with a tile.  
**Handler:** `callGodot(bridge, 'tilemap/fill_rect', args)`  
**Expected return:** Success/error JSON. On success, returns confirmation of filled area.

### Parameters

| Parameter     | Type                                                                 | Required | Default       | Description                         |
|---------------|----------------------------------------------------------------------|----------|---------------|-------------------------------------|
| `path`        | `string` (NodePath)                                                  | **Yes**  | —             | TileMap node path                   |
| `rect`        | `{ x: int, y: int, w: positive int, h: positive int }`               | **Yes**  | —             | Rectangle to fill (x,y = top-left)  |
| `source_id`   | `number` (int)                                                       | No       | `undefined`   | TileSet source ID                   |
| `atlas_coords`| `[int, int]` (Coord2D)                                               | No       | `undefined`   | Atlas coordinates `[x, y]`          |

### Test Scenarios

#### 2.1: Basic happy path — fill a 3×3 rectangle at origin
- **Description:** Fill a 3×3 area starting at (0, 0).  
- **Params:** `{ path: "TileMap", rect: { x: 0, y: 0, w: 3, h: 3 } }`  
- **Expected result:** Success. Cells (0,0) through (2,2) are filled.  
- **Notes:** Simplest valid call.

#### 2.2: Fill a 1×1 rectangle (single cell)
- **Description:** Fill a single cell using rect.  
- **Params:** `{ path: "TileMap", rect: { x: 5, y: 5, w: 1, h: 1 } }`  
- **Expected result:** Success. Exactly one cell (5, 5) is filled.  
- **Notes:** Boundary — minimum rect size.

#### 2.3: Fill with all optional parameters
- **Description:** Fill a rectangle with explicit source_id and atlas_coords.  
- **Params:** `{ path: "TileMap", rect: { x: 2, y: 2, w: 4, h: 2 }, source_id: 0, atlas_coords: [1, 0] }`  
- **Expected result:** Success. Rectangle filled with specified tile.  
- **Notes:** Validates optional params together.

#### 2.4: Fill with negative x/y offset
- **Description:** Fill a rectangle starting at negative coordinates.  
- **Params:** `{ path: "TileMap", rect: { x: -5, y: -3, w: 3, h: 3 } }`  
- **Expected result:** Success. TileMap supports filling in negative coordinate ranges.  
- **Notes:** Boundary — negative origin.

#### 2.5: Fill a large rectangle
- **Description:** Fill a 100×100 area.  
- **Params:** `{ path: "TileMap", rect: { x: 0, y: 0, w: 100, h: 100 } }`  
- **Expected result:** Success. 10,000 cells filled. May be slow but should complete.  
- **Notes:** Boundary — large operation.

#### 2.6: Fill with width = 0
- **Description:** Use width of 0.  
- **Params:** `{ path: "TileMap", rect: { x: 0, y: 0, w: 0, h: 5 } }`  
- **Expected result:** Error (Zod validation). `w` requires `.positive()` (> 0).  
- **Notes:** Edge case — zero width.

#### 2.7: Fill with height = 0
- **Description:** Use height of 0.  
- **Params:** `{ path: "TileMap", rect: { x: 0, y: 0, w: 5, h: 0 } }`  
- **Expected result:** Error (Zod validation). `h` requires `.positive()` (> 0).  
- **Notes:** Edge case — zero height.

#### 2.8: Fill with negative width
- **Description:** Use negative width.  
- **Params:** `{ path: "TileMap", rect: { x: 0, y: 0, w: -3, h: 5 } }`  
- **Expected result:** Error (Zod validation). `w` requires `.positive()`.  
- **Notes:** Edge case — negative dimension.

#### 2.9: Fill with negative height
- **Description:** Use negative height.  
- **Params:** `{ path: "TileMap", rect: { x: 0, y: 0, w: 3, h: -5 } }`  
- **Expected result:** Error (Zod validation). `h` requires `.positive()`.  
- **Notes:** Edge case — negative dimension.

#### 2.10: Fill with non-integer rect values
- **Description:** Provide float values for rect dimensions.  
- **Params:** `{ path: "TileMap", rect: { x: 1.5, y: 2.5, w: 3.7, h: 4.2 } }`  
- **Expected result:** Error (Zod validation). All rect fields require `.int()`.  
- **Notes:** Edge case — type violation.

#### 2.11: Missing required `rect` parameter
- **Description:** Omit the `rect` parameter entirely.  
- **Params:** `{ path: "TileMap" }`  
- **Expected result:** Error (Zod validation). `rect` is required.  
- **Notes:** Edge case — missing required param.

#### 2.12: Missing required `path` parameter
- **Description:** Omit the `path` parameter.  
- **Params:** `{ rect: { x: 0, y: 0, w: 3, h: 3 } }`  
- **Expected result:** Error (Zod validation). `path` is required.  
- **Notes:** Edge case — missing required param.

#### 2.13: Missing rect sub-fields (partial rect)
- **Description:** Provide rect missing one required sub-field.  
- **Params:** `{ path: "TileMap", rect: { x: 0, y: 0, w: 3 } }`  
- **Expected result:** Error (Zod validation). `h` is required in the rect object.  
- **Notes:** Edge case — incomplete rect object.

#### 2.14: Extra properties in rect object
- **Description:** Provide extra fields in the rect object.  
- **Params:** `{ path: "TileMap", rect: { x: 0, y: 0, w: 3, h: 3, extra: "ignored" } }`  
- **Expected result:** Success (extra fields ignored by Zod object stripping) or validation error depending on Zod strictness.  
- **Notes:** Edge case — unknown properties.

#### 2.15: atlas_coords with only 1 element
- **Description:** Provide a single-element array for atlas_coords.  
- **Params:** `{ path: "TileMap", rect: { x: 0, y: 0, w: 2, h: 2 }, source_id: 0, atlas_coords: [0] }`  
- **Expected result:** Error (Zod validation). Coord2D requires `.min(2)`.  
- **Notes:** Edge case — optional param validation still applies.

---

## Tool 3: `tilemap_get_cell`

**Description:** Get the tile data at a specific cell.  
**Handler:** `callGodot(bridge, 'tilemap/get_cell', args)`  
**Expected return:** JSON object with the cell's tile data (source_id, atlas_coords, alternative_tile) or indication the cell is empty.

### Parameters

| Parameter | Type              | Required | Default | Description                                  |
|-----------|-------------------|----------|---------|----------------------------------------------|
| `path`    | `string` (NodePath) | **Yes** | —       | TileMap node path                            |
| `coords`  | `[int, int]` (Coord2D) | **Yes** | —   | Integer coordinates `[x, y]` of cell to read |

### Test Scenarios

#### 3.1: Basic happy path — read a cell at origin
- **Description:** Read tile data from cell (0, 0) on a TileMap.  
- **Params:** `{ path: "TileMap", coords: [0, 0] }`  
- **Expected result:** Success. Returns tile data (source_id, atlas_coords, alternative_tile) or empty-cell indicator.  
- **Notes:** Simplest valid call.

#### 3.2: Read a cell that was previously set
- **Description:** Read back a cell that was set earlier.  
- **Params:** `{ path: "TileMap", coords: [5, 3] }`  
- **Expected result:** Success. Returns the same tile data that was written.  
- **Notes:** Validates read-after-write consistency.

#### 3.3: Read a cell at negative coordinates
- **Description:** Read cell at negative coordinates.  
- **Params:** `{ path: "TileMap", coords: [-1, -1] }`  
- **Expected result:** Success. Returns tile data or empty-cell indicator.  
- **Notes:** Boundary — negative coords.

#### 3.4: Read a cell at large coordinates
- **Description:** Read cell at large positive coordinates.  
- **Params:** `{ path: "TileMap", coords: [10000, 10000] }`  
- **Expected result:** Success. Returns tile data or empty-cell indicator.  
- **Notes:** Boundary — large values.

#### 3.5: Read a cell that has never been set (empty)
- **Description:** Read cell coordinates that are empty.  
- **Params:** `{ path: "TileMap", coords: [999, 999] }`  
- **Expected result:** Success. Returns indication that cell is empty (likely source_id = -1).  
- **Notes:** Validates empty cell behavior.

#### 3.6: Missing required `coords` parameter
- **Description:** Omit the `coords` parameter.  
- **Params:** `{ path: "TileMap" }`  
- **Expected result:** Error (Zod validation). `coords` is required.  
- **Notes:** Edge case — missing required param.

#### 3.7: Missing required `path` parameter
- **Description:** Omit the `path` parameter.  
- **Params:** `{ coords: [0, 0] }`  
- **Expected result:** Error (Zod validation). `path` is required.  
- **Notes:** Edge case — missing required param.

#### 3.8: Coords as non-integer array
- **Description:** Provide float values for coords.  
- **Params:** `{ path: "TileMap", coords: [1.5, 2.5] }`  
- **Expected result:** Error (Zod validation). Coord2D requires `.int()`.  
- **Notes:** Edge case — type violation.

#### 3.9: Path to non-TileMap node
- **Description:** Point to a node that is not a TileMap.  
- **Params:** `{ path: "Node2D", coords: [0, 0] }`  
- **Expected result:** Error from Godot. Node is not a TileMap.  
- **Notes:** Edge case — wrong node type.

---

## Tool 4: `tilemap_clear`

**Description:** Clear cells in a TileMap area or the entire map.  
**Handler:** `callGodot(bridge, 'tilemap/clear', args)`  
**Expected return:** Success/error JSON confirming the clear operation.

### Parameters

| Parameter | Type              | Required | Default | Description               |
|-----------|-------------------|----------|---------|---------------------------|
| `path`    | `string` (NodePath) | **Yes** | —       | TileMap node path         |

### Test Scenarios

#### 4.1: Basic happy path — clear entire TileMap
- **Description:** Clear all cells from a TileMap that has tiles set.  
- **Params:** `{ path: "TileMap" }`  
- **Expected result:** Success. All cells on the TileMap are cleared.  
- **Notes:** Only one parameter. Verify with `tilemap_get_used_cells` afterwards — should return empty.

#### 4.2: Clear an already-empty TileMap
- **Description:** Clear a TileMap that has no cells set.  
- **Params:** `{ path: "TileMap" }`  
- **Expected result:** Success. No-op; returns success.  
- **Notes:** Idempotency test — clearing empty map is a no-op.

#### 4.3: Clear at scene root (empty path)
- **Description:** Use `""` as the path.  
- **Params:** `{ path: "" }`  
- **Expected result:** Error from Godot. Scene root is not a TileMap.  
- **Notes:** Edge case — invalid target.

#### 4.4: Missing required `path` parameter
- **Description:** Call with empty params object.  
- **Params:** `{}`  
- **Expected result:** Error (Zod validation). `path` is required.  
- **Notes:** Edge case — missing required param.

#### 4.5: Clear a non-TileMap node
- **Description:** Point to a node that is not a TileMap.  
- **Params:** `{ path: "StaticBody2D" }`  
- **Expected result:** Error from Godot. Node is not a TileMap.  
- **Notes:** Edge case — wrong node type.

---

## Tool 5: `tilemap_get_info`

**Description:** Get TileMap configuration and TileSet information.  
**Handler:** `callGodot(bridge, 'tilemap/get_info', args)`  
**Expected return:** JSON object with TileMap configuration (tile_set path, cell size, quadrant size, layer count, tile size, rendering info) and TileSet details.

### Parameters

| Parameter | Type              | Required | Default | Description               |
|-----------|-------------------|----------|---------|---------------------------|
| `path`    | `string` (NodePath) | **Yes** | —       | TileMap node path         |

### Test Scenarios

#### 5.1: Basic happy path — get info from a configured TileMap
- **Description:** Retrieve configuration and TileSet info from a TileMap with a TileSet assigned.  
- **Params:** `{ path: "TileMap" }`  
- **Expected result:** Success. Returns JSON with tile_set path, cell_size, quadrant_size, layer_count, and TileSet details (source count, atlas info, etc.).  
- **Notes:** Simplest valid call. Verify response contains expected keys.

#### 5.2: Get info from a TileMap with no TileSet assigned
- **Description:** Query a TileMap that has no TileSet resource assigned.  
- **Params:** `{ path: "TileMap" }`  
- **Expected result:** Success. Returns configuration with null/empty tile_set.  
- **Notes:** Edge case — missing TileSet.

#### 5.3: Get info from deep nested TileMap
- **Description:** Query a TileMap nested multiple levels deep.  
- **Params:** `{ path: "Level/Layers/Ground/TileMap" }`  
- **Expected result:** Success. Returns configuration of the nested TileMap.  
- **Notes:** Validates deep path resolution.

#### 5.4: Missing required `path` parameter
- **Description:** Call with no parameters.  
- **Params:** `{}`  
- **Expected result:** Error (Zod validation). `path` is required.  
- **Notes:** Edge case — missing required param.

#### 5.5: Get info from non-TileMap node
- **Description:** Point to a node that is not a TileMap.  
- **Params:** `{ path: "Node2D" }`  
- **Expected result:** Error from Godot. Node is not a TileMap.  
- **Notes:** Edge case — wrong node type.

---

## Tool 6: `tilemap_get_used_cells`

**Description:** Get all used cell coordinates in a TileMap.  
**Handler:** `callGodot(bridge, 'tilemap/get_used_cells', args)`  
**Expected return:** JSON object with an array of used cell coordinates (e.g. `[{x: 0, y: 0}, ...]`).

### Parameters

| Parameter | Type              | Required | Default | Description               |
|-----------|-------------------|----------|---------|---------------------------|
| `path`    | `string` (NodePath) | **Yes** | —       | TileMap node path         |

### Test Scenarios

#### 6.1: Basic happy path — get used cells from a populated TileMap
- **Description:** Retrieve used cells from a TileMap that has tiles set.  
- **Params:** `{ path: "TileMap" }`  
- **Expected result:** Success. Returns array of used cell coordinates.  
- **Notes:** Simplest valid call. Verify the array contains expected cells.

#### 6.2: Get used cells from an empty TileMap
- **Description:** Retrieve used cells from a TileMap that has no tiles.  
- **Params:** `{ path: "TileMap" }`  
- **Expected result:** Success. Returns empty array.  
- **Notes:** Edge case — empty map.

#### 6.3: Get used cells after fill_rect operation
- **Description:** Fill a rectangle, then get used cells to verify.  
- **Params:** First call `tilemap_fill_rect` with `rect: { x: 0, y: 0, w: 2, h: 2 }`, then `{ path: "TileMap" }` for get_used_cells.  
- **Expected result:** Success. Returns 4 cells: (0,0), (1,0), (0,1), (1,1).  
- **Notes:** Integration scenario — verify fill_rect results.

#### 6.4: Get used cells after clear operation
- **Description:** Fill cells, clear the TileMap, then get used cells.  
- **Params:** `{ path: "TileMap" }` after clearing.  
- **Expected result:** Success. Returns empty array.  
- **Notes:** Integration scenario — verify clear results.

#### 6.5: Missing required `path` parameter
- **Description:** Call with no parameters.  
- **Params:** `{}`  
- **Expected result:** Error (Zod validation). `path` is required.  
- **Notes:** Edge case — missing required param.

#### 6.6: Get used cells from non-TileMap node
- **Description:** Point to a node that is not a TileMap.  
- **Params:** `{ path: "Area2D" }`  
- **Expected result:** Error from Godot. Node is not a TileMap.  
- **Notes:** Edge case — wrong node type.

---

## GridMap Tools (3D)

---

## Tool 7: `gridmap_set_cell`

**Description:** Set a mesh item in a GridMap at 3D cell coordinates.  
**Handler:** `callGodot(bridge, 'gridmap/set_cell', args)`  
**Expected return:** Success/error JSON confirming the cell was set.

### Parameters

| Parameter | Type                | Required | Default | Description                              |
|-----------|---------------------|----------|---------|------------------------------------------|
| `path`    | `string` (NodePath) | **Yes**  | —       | GridMap node path                        |
| `coords`  | `[int, int, int]` (Coord3D) | **Yes** | — | 3D integer coordinates `[x, y, z]`       |
| `item`    | `number` (int)      | **Yes**  | —       | MeshLibrary item ID. Use `-1` to clear.  |

### Test Scenarios

#### 7.1: Basic happy path — set a mesh item at origin
- **Description:** Set item ID 0 at cell (0, 0, 0).  
- **Params:** `{ path: "GridMap", coords: [0, 0, 0], item: 0 }`  
- **Expected result:** Success. Item 0 placed at origin.  
- **Notes:** Simplest valid call.

#### 7.2: Set item at a positive coordinate
- **Description:** Set item ID 3 at cell (5, 2, 1).  
- **Params:** `{ path: "GridMap", coords: [5, 2, 1], item: 3 }`  
- **Expected result:** Success. Item 3 placed at (5, 2, 1).  
- **Notes:** Validates non-origin coordinates.

#### 7.3: Set item with negative coordinates
- **Description:** Set item at negative cell coordinates.  
- **Params:** `{ path: "GridMap", coords: [-3, -2, -1], item: 1 }`  
- **Expected result:** Success. GridMap supports negative coordinates.  
- **Notes:** Boundary — negative coords.

#### 7.4: Clear a cell using item = -1
- **Description:** Clear a previously set cell by setting item to -1.  
- **Params:** `{ path: "GridMap", coords: [0, 0, 0], item: -1 }`  
- **Expected result:** Success. Cell (0, 0, 0) is cleared/removed.  
- **Notes:** Important semantic — item = -1 means "clear this cell".

#### 7.5: Overwrite a previously set cell
- **Description:** Set a cell, then set it again with a different item ID.  
- **Params:** `{ path: "GridMap", coords: [1, 1, 1], item: 5 }` (on a cell that already had item 2).  
- **Expected result:** Success. Cell now contains item 5.  
- **Notes:** Validates overwrite behavior.

#### 7.6: Set item with large item ID
- **Description:** Use a high item ID.  
- **Params:** `{ path: "GridMap", coords: [0, 0, 0], item: 999 }`  
- **Expected result:** Error from Godot or success depending on MeshLibrary.  
- **Notes:** Boundary — large item ID.

#### 7.7: Missing required `path` parameter
- **Description:** Omit the `path` parameter.  
- **Params:** `{ coords: [0, 0, 0], item: 0 }`  
- **Expected result:** Error (Zod validation). `path` is required.  
- **Notes:** Edge case — missing required param.

#### 7.8: Missing required `coords` parameter
- **Description:** Omit the `coords` parameter.  
- **Params:** `{ path: "GridMap", item: 0 }`  
- **Expected result:** Error (Zod validation). `coords` is required.  
- **Notes:** Edge case — missing required param.

#### 7.9: Missing required `item` parameter
- **Description:** Omit the `item` parameter.  
- **Params:** `{ path: "GridMap", coords: [0, 0, 0] }`  
- **Expected result:** Error (Zod validation). `item` is required.  
- **Notes:** Edge case — missing required param.

#### 7.10: Coords with only 2 elements
- **Description:** Provide a 2-element array for coords.  
- **Params:** `{ path: "GridMap", coords: [0, 0], item: 0 }`  
- **Expected result:** Error (Zod validation). Coord3D requires `.min(3)`.  
- **Notes:** Edge case — array too short.

#### 7.11: Coords with extra elements (4+ elements)
- **Description:** Provide a 4-element array (only first three used).  
- **Params:** `{ path: "GridMap", coords: [1, 2, 3, 99], item: 0 }`  
- **Expected result:** Success. Only [1, 2, 3] is used per Coord3D transform.  
- **Notes:** Edge case — Coord3D accepts ≥3 elements and truncates.

#### 7.12: Coords as non-integer array
- **Description:** Provide float values for coords.  
- **Params:** `{ path: "GridMap", coords: [1.5, 2.5, 3.5], item: 0 }`  
- **Expected result:** Error (Zod validation). Coord3D requires `.int()`.  
- **Notes:** Edge case — type violation.

#### 7.13: Coords as empty array
- **Description:** Provide empty array for coords.  
- **Params:** `{ path: "GridMap", coords: [], item: 0 }`  
- **Expected result:** Error (Zod validation). `.min(3)` fails.  
- **Notes:** Edge case — empty array.

#### 7.14: Set item on non-GridMap node
- **Description:** Point to a node that is not a GridMap.  
- **Params:** `{ path: "MeshInstance3D", coords: [0, 0, 0], item: 0 }`  
- **Expected result:** Error from Godot. Node is not a GridMap.  
- **Notes:** Edge case — wrong node type.

---

## Tool 8: `gridmap_get_cell`

**Description:** Get the mesh item at a specific GridMap cell.  
**Handler:** `callGodot(bridge, 'gridmap/get_cell', args)`  
**Expected return:** JSON object with the item ID at the specified cell, or -1 if empty.

### Parameters

| Parameter | Type                | Required | Default | Description                                  |
|-----------|---------------------|----------|---------|----------------------------------------------|
| `path`    | `string` (NodePath) | **Yes**  | —       | GridMap node path                            |
| `coords`  | `[int, int, int]` (Coord3D) | **Yes** | — | 3D integer coordinates `[x, y, z]` of cell to read |

### Test Scenarios

#### 8.1: Basic happy path — read a cell at origin
- **Description:** Read the item at cell (0, 0, 0).  
- **Params:** `{ path: "GridMap", coords: [0, 0, 0] }`  
- **Expected result:** Success. Returns item ID (or -1 if empty).  
- **Notes:** Simplest valid call.

#### 8.2: Read a cell that was previously set
- **Description:** Read back a cell set earlier with gridmap_set_cell.  
- **Params:** `{ path: "GridMap", coords: [5, 2, 1] }`  
- **Expected result:** Success. Returns the same item ID that was written (e.g. 3).  
- **Notes:** Validates read-after-write consistency.

#### 8.3: Read an empty/never-set cell
- **Description:** Read cell coordinates that have never been set.  
- **Params:** `{ path: "GridMap", coords: [999, 999, 999] }`  
- **Expected result:** Success. Returns -1 (empty cell).  
- **Notes:** Validates empty cell behavior.

#### 8.4: Read a cleared cell
- **Description:** Set a cell, clear it with item=-1, then read it back.  
- **Params:** `{ path: "GridMap", coords: [0, 0, 0] }`  
- **Expected result:** Success. Returns -1 (cleared).  
- **Notes:** Integration scenario — verify clear via set with item=-1.

#### 8.5: Read at negative coordinates
- **Description:** Read a cell at negative coordinates.  
- **Params:** `{ path: "GridMap", coords: [-1, -2, -3] }`  
- **Expected result:** Success. Returns item ID or -1.  
- **Notes:** Boundary — negative coords.

#### 8.6: Missing required `coords` parameter
- **Description:** Omit the `coords` parameter.  
- **Params:** `{ path: "GridMap" }`  
- **Expected result:** Error (Zod validation). `coords` is required.  
- **Notes:** Edge case — missing required param.

#### 8.7: Missing required `path` parameter
- **Description:** Omit the `path` parameter.  
- **Params:** `{ coords: [0, 0, 0] }`  
- **Expected result:** Error (Zod validation). `path` is required.  
- **Notes:** Edge case — missing required param.

#### 8.8: Read from non-GridMap node
- **Description:** Point to a node that is not a GridMap.  
- **Params:** `{ path: "Node3D", coords: [0, 0, 0] }`  
- **Expected result:** Error from Godot. Node is not a GridMap.  
- **Notes:** Edge case — wrong node type.

---

## Tool 9: `gridmap_clear`

**Description:** Clear all cells in a GridMap.  
**Handler:** `callGodot(bridge, 'gridmap/clear', args)`  
**Expected return:** Success/error JSON confirming all cells were cleared.

### Parameters

| Parameter | Type              | Required | Default | Description               |
|-----------|-------------------|----------|---------|---------------------------|
| `path`    | `string` (NodePath) | **Yes** | —       | GridMap node path         |

### Test Scenarios

#### 9.1: Basic happy path — clear a populated GridMap
- **Description:** Clear all cells from a GridMap that has items set.  
- **Params:** `{ path: "GridMap" }`  
- **Expected result:** Success. All cells are cleared. Verify with `gridmap_get_used_cells` — should return empty.  
- **Notes:** Simplest valid call.

#### 9.2: Clear an already-empty GridMap
- **Description:** Clear a GridMap that has no cells set.  
- **Params:** `{ path: "GridMap" }`  
- **Expected result:** Success. No-op; returns success.  
- **Notes:** Idempotency test.

#### 9.3: Missing required `path` parameter
- **Description:** Call with empty params.  
- **Params:** `{}`  
- **Expected result:** Error (Zod validation). `path` is required.  
- **Notes:** Edge case — missing required param.

#### 9.4: Clear a non-GridMap node
- **Description:** Point to a node that is not a GridMap.  
- **Params:** `{ path: "Camera3D" }`  
- **Expected result:** Error from Godot. Node is not a GridMap.  
- **Notes:** Edge case — wrong node type.

---

## Tool 10: `gridmap_get_used_cells`

**Description:** Get all used cell coordinates in a GridMap.  
**Handler:** `callGodot(bridge, 'gridmap/get_used_cells', args)`  
**Expected return:** JSON object with an array of used 3D cell coordinates (e.g. `[{x: 0, y: 0, z: 0}, ...]`).

### Parameters

| Parameter | Type              | Required | Default | Description               |
|-----------|-------------------|----------|---------|---------------------------|
| `path`    | `string` (NodePath) | **Yes** | —       | GridMap node path         |

### Test Scenarios

#### 10.1: Basic happy path — get used cells from populated GridMap
- **Description:** Retrieve used cells from a GridMap that has items set.  
- **Params:** `{ path: "GridMap" }`  
- **Expected result:** Success. Returns array of used cell coordinates with their item IDs.  
- **Notes:** Simplest valid call.

#### 10.2: Get used cells from an empty GridMap
- **Description:** Retrieve used cells from a GridMap with no items.  
- **Params:** `{ path: "GridMap" }`  
- **Expected result:** Success. Returns empty array.  
- **Notes:** Edge case — empty map.

#### 10.3: Get used cells after gridmap_set_cell operations
- **Description:** Set several cells, then get used cells to verify.  
- **Params:** First set cells at (0,0,0), (1,0,0), (2,0,0), then call `{ path: "GridMap" }`.  
- **Expected result:** Success. Returns exactly 3 cells.  
- **Notes:** Integration scenario.

#### 10.4: Get used cells after gridmap_clear
- **Description:** Set cells, clear, then get used cells.  
- **Params:** `{ path: "GridMap" }` after clearing.  
- **Expected result:** Success. Returns empty array.  
- **Notes:** Integration scenario — verify clear results.

#### 10.5: Missing required `path` parameter
- **Description:** Call with no parameters.  
- **Params:** `{}`  
- **Expected result:** Error (Zod validation). `path` is required.  
- **Notes:** Edge case — missing required param.

#### 10.6: Get used cells from non-GridMap node
- **Description:** Point to a node that is not a GridMap.  
- **Params:** `{ path: "CharacterBody3D" }`  
- **Expected result:** Error from Godot. Node is not a GridMap.  
- **Notes:** Edge case — wrong node type.

---

## Tool 11: `gridmap_get_info`

**Description:** Get GridMap configuration and MeshLibrary information.  
**Handler:** `callGodot(bridge, 'gridmap/get_info', args)`  
**Expected return:** JSON object with GridMap configuration (cell_size, octant_size, mesh_library path, center_x/y/z, etc.) and MeshLibrary details.

### Parameters

| Parameter | Type              | Required | Default | Description               |
|-----------|-------------------|----------|---------|---------------------------|
| `path`    | `string` (NodePath) | **Yes** | —       | GridMap node path         |

### Test Scenarios

#### 11.1: Basic happy path — get info from configured GridMap
- **Description:** Retrieve configuration and MeshLibrary info from a GridMap with a MeshLibrary assigned.  
- **Params:** `{ path: "GridMap" }`  
- **Expected result:** Success. Returns JSON with mesh_library path, cell_size, octant_size, center settings, and MeshLibrary details (item count, item list).  
- **Notes:** Simplest valid call.

#### 11.2: Get info from a GridMap with no MeshLibrary assigned
- **Description:** Query a GridMap that has no MeshLibrary resource.  
- **Params:** `{ path: "GridMap" }`  
- **Expected result:** Success. Returns configuration with null/empty mesh_library.  
- **Notes:** Edge case — missing MeshLibrary.

#### 11.3: Missing required `path` parameter
- **Description:** Call with no parameters.  
- **Params:** `{}`  
- **Expected result:** Error (Zod validation). `path` is required.  
- **Notes:** Edge case — missing required param.

#### 11.4: Get info from non-GridMap node
- **Description:** Point to a node that is not a GridMap.  
- **Params:** `{ path: "Sprite3D" }`  
- **Expected result:** Error from Godot. Node is not a GridMap.  
- **Notes:** Edge case — wrong node type.

---

## Integration Scenarios

### IS-1: Full TileMap lifecycle (set, read, fill, get used, clear, verify empty)
1. **Get info:** `{ path: "TileMap" }` — record initial state.  
2. **Set cell:** `{ path: "TileMap", coords: [0, 0], source_id: 0, atlas_coords: [0, 0] }` — set single cell.  
3. **Get cell:** `{ path: "TileMap", coords: [0, 0] }` — verify it's set.  
4. **Fill rect:** `{ path: "TileMap", rect: { x: 0, y: 0, w: 3, h: 3 } }` — fill 3×3.  
5. **Get used cells:** `{ path: "TileMap" }` — should have 9 cells.  
6. **Clear:** `{ path: "TileMap" }` — clear everything.  
7. **Get used cells:** `{ path: "TileMap" }` — should have 0 cells.  
8. **Get cell:** `{ path: "TileMap", coords: [0, 0] }` — should be empty.  

### IS-2: Full GridMap lifecycle (set, read, get used, clear, verify empty)
1. **Get info:** `{ path: "GridMap" }` — record initial state.  
2. **Set cell:** `{ path: "GridMap", coords: [0, 0, 0], item: 0 }` — set item at origin.  
3. **Set cell:** `{ path: "GridMap", coords: [1, 0, 0], item: 1 }` — set item at (1,0,0).  
4. **Set cell:** `{ path: "GridMap", coords: [0, 1, 0], item: 2 }` — set item at (0,1,0).  
5. **Get cell:** `{ path: "GridMap", coords: [1, 0, 0] }` — verify item 1.  
6. **Get used cells:** `{ path: "GridMap" }` — should have 3 cells.  
7. **Clear cell:** `{ path: "GridMap", coords: [0, 0, 0], item: -1 }` — clear origin.  
8. **Get used cells:** `{ path: "GridMap" }` — should have 2 cells.  
9. **Clear:** `{ path: "GridMap" }` — clear everything.  
10. **Get used cells:** `{ path: "GridMap" }` — should have 0 cells.  
