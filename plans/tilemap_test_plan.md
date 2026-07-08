# TileMap Tools — Comprehensive Test Plan

> **Source file:** `server/src/tools/tilemap.ts`
> **Shared types:** `server/src/tools/shared-types.ts`
> **Bridge pattern:** Every handler calls `callGodot(bridge, 'tilemap/...' | 'gridmap/...', args)` which forwards the request over WebSocket to the Godot editor plugin and returns a `ToolResult` (`{ content: [{ type: 'text', text: string }], isError?: boolean }`).
> **Total tools:** 11 (6 TileMap + 5 GridMap)

---

## Table of Contents

1. [Prerequisites & Setup](#prerequisites--setup)
2. [Type Reference](#type-reference)
3. [Tool: tilemap_set_cell](#tool-tilemap_set_cell)
4. [Tool: tilemap_fill_rect](#tool-tilemap_fill_rect)
5. [Tool: tilemap_get_cell](#tool-tilemap_get_cell)
6. [Tool: tilemap_clear](#tool-tilemap_clear)
7. [Tool: tilemap_get_info](#tool-tilemap_get_info)
8. [Tool: tilemap_get_used_cells](#tool-tilemap_get_used_cells)
9. [Tool: gridmap_set_cell](#tool-gridmap_set_cell)
10. [Tool: gridmap_get_cell](#tool-gridmap_get_cell)
11. [Tool: gridmap_clear](#tool-gridmap_clear)
12. [Tool: gridmap_get_used_cells](#tool-gridmap_get_used_cells)
13. [Tool: gridmap_get_info](#tool-gridmap_get_info)
14. [Recommended Test Sequences](#recommended-test-sequences)

---

## Prerequisites & Setup

All TileMap tools require a **TileMap node** with a **TileSet resource** already configured in the currently open scene. All GridMap tools require a **GridMap node** with a **MeshLibrary** configured.

### Pre-test setup (execute before any test)

These steps create the nodes required by the tool tests. Use tools from other modules (`add_node` from `node.ts`, `open_scene` from `scene.ts`) to prepare the environment.

#### Step 1: Open or create a scene

```json
{
  "tool": "open_scene",
  "params": { "path": "res://scenes/test_tilemap.tscn" }
}
```

If the scene doesn't exist yet, use `create_scene` first:

```json
{
  "tool": "create_scene",
  "params": { "path": "res://scenes/test_tilemap.tscn", "root_type": "Node2D" }
}
```

#### Step 2: Create a TileMap node for 2D tests

```json
{
  "tool": "add_node",
  "params": {
    "parent_path": "",
    "type": "TileMap",
    "name": "TestTileMap",
    "properties": {}
  }
}
```

> **Note:** The TileMap must have a TileSet assigned in Godot for `set_cell` and `fill_rect` to work. If the TileSet is not set, those calls will return errors from Godot. You may need to manually assign a TileSet resource in the editor, or use `set_property`:
> ```json
> {
>   "tool": "set_property",
>   "params": { "path": "TestTileMap", "property": "tile_set", "value": "<TileSet resource path or inline>" }
> }
> ```

#### Step 3: Create a GridMap node for 3D tests (requires a 3D scene)

For GridMap tests, you need a separate 3D scene:

```json
{
  "tool": "create_scene",
  "params": { "path": "res://scenes/test_gridmap.tscn", "root_type": "Node3D" }
}
```

```json
{
  "tool": "add_node",
  "params": {
    "parent_path": "",
    "type": "GridMap",
    "name": "TestGridMap",
    "properties": {}
  }
}
```

Or use the dedicated shortcut from `scene3d.ts`:

```json
{
  "tool": "add_gridmap",
  "params": {
    "parent": "",
    "properties": { "mesh_library_path": "res://assets/mesh_library.tres" }
  }
}
```

> **Note:** The GridMap must have a MeshLibrary assigned. Use `set_property` if not automatically set.

---

## Type Reference

These Zod schemas from `shared-types.ts` define the parameter types used by tilemap tools:

| Schema | Type | Description |
|---|---|---|
| `NodePath` | `z.string()` | Node path in the scene tree. Use node name for root children (e.g. `"TestTileMap"`), `""` for scene root. Relative to currently open scene. |
| `Coord2D` | `z.array(z.number().int()).min(2).transform([a[0], a[1]])` | Integer coordinates `[x, y]`. Accepts arrays of 2+ elements (extras ignored). **Must be integers.** |
| `Coord3D` | `z.array(z.number().int()).min(3).transform([a[0], a[1], a[2]])` | Integer coordinates `[x, y, z]`. Accepts arrays of 3+ elements. **Must be integers.** |
| `rect` | `z.object({ x: int, y: int, w: positive int, h: positive int })` | Rectangle definition. `w` and `h` must be **positive** (> 0). |

---

## Tool: tilemap_set_cell

**Description:** Set a single cell in a TileMap

**Registered as:** `tilemap_set_cell`
**Bridge method:** `tilemap/set_cell`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | string (NodePath) | ✅ Yes | TileMap node path (e.g. `"TestTileMap"`) |
| `coords` | `[int, int]` (Coord2D) | ✅ Yes | Cell coordinates `[x, y]` |
| `source_id` | int (optional) | ❌ No | TileSet source ID |
| `atlas_coords` | `[int, int]` (Coord2D, optional) | ❌ No | Atlas coordinates `[x, y]` |
| `alternative_tile` | int (optional) | ❌ No | Alternative tile ID |

### Test Scenarios

#### Scenario 1: Set cell with only required params (minimal)

- **Description:** Set a single cell at coordinates `[0, 0]` using only required parameters. No source_id, atlas_coords, or alternative_tile specified.
- **Params:**
  ```json
  {
    "path": "TestTileMap",
    "coords": [0, 0]
  }
  ```
- **Expected result:** `ToolResult` with `isError` absent or `false`. Text content confirms cell was set.
- **Notes:** This is the minimal valid call. Without `source_id`, Godot may use the default source (ID 0) or may error if no TileSet source exists — verify actual behavior.
- **What to pay attention to:** If a TileSet is not assigned to the node, Godot may return an error. Verify that the return value contains a confirmation, not an error.

#### Scenario 2: Set cell with all optional params

- **Description:** Set a cell with full tile identification: source ID, atlas coordinates, and alternative tile.
- **Params:**
  ```json
  {
    "path": "TestTileMap",
    "coords": [5, -3],
    "source_id": 0,
    "atlas_coords": [1, 2],
    "alternative_tile": 0
  }
  ```
- **Expected result:** Success. Cell at `[5, -3]` is set with the specified tile.
- **Notes:** Negative coordinates are valid (tilemap cells can be anywhere in integer space). This tests that the tool handles negative coords correctly.
- **What to pay attention to:** Verify that negative coordinates are handled correctly. The value `source_id: 0` is the most common source ID.

#### Scenario 3: Set cell with alternative_tile variation

- **Description:** Set a cell using an alternative tile (flipped, rotated, etc.).
- **Params:**
  ```json
  {
    "path": "TestTileMap",
    "coords": [10, 10],
    "source_id": 0,
    "atlas_coords": [0, 0],
    "alternative_tile": 1
  }
  ```
- **Expected result:** Success if alternative tile 1 exists in the TileSet. Error from Godot if it doesn't.
- **Notes:** Alternative tile IDs are typically small non-negative integers. `alternative_tile: 0` is the base tile; `1`, `2`, etc. are variations.
- **What to pay attention to:** If `alternative_tile` does not exist in the TileSet, Godot may either ignore it or return an error — depends on the Godot version.

#### Scenario 4: Missing required `coords` — expect validation error

- **Description:** Call without the required `coords` parameter.
- **Params:**
  ```json
  {
    "path": "TestTileMap"
  }
  ```
- **Expected result:** MCP schema validation error. The request should be rejected before reaching Godot because `coords` is required.
- **Notes:** This tests the MCP framework's input validation, not Godot itself.
- **What to pay attention to:** Ensure that the error clearly indicates the missing `coords` parameter.

#### Scenario 5: Missing required `path` — expect validation error

- **Description:** Call without the required `path` parameter.
- **Params:**
  ```json
  {
    "coords": [0, 0]
  }
  ```
- **Expected result:** MCP schema validation error for missing `path`.

#### Scenario 6: Non-integer coords — expect validation error

- **Description:** Pass floating-point values in `coords`.
- **Params:**
  ```json
  {
    "path": "TestTileMap",
    "coords": [1.5, 2.7]
  }
  ```
- **Expected result:** Zod validation error — `Coord2D` requires `z.number().int()` for each element.
- **What to pay attention to:** The error should clearly indicate that coordinates must be integers.

#### Scenario 7: Non-existent TileMap path — expect Godot error

- **Description:** Reference a node that doesn't exist in the scene.
- **Params:**
  ```json
  {
    "path": "NonExistentTileMap",
    "coords": [0, 0]
  }
  ```
- **Expected result:** `ToolResult` with `isError: true`. The Godot bridge should return an error about node not found.
- **What to pay attention to:** Ensure that the error text is clear and indicates the cause — node not found.

#### Scenario 8: Extra elements in coords array (Coord2D transform)

- **Description:** Pass an array with more than 2 elements. `Coord2D` has `.min(2)` and transforms to `[a[0], a[1]]`.
- **Params:**
  ```json
  {
    "path": "TestTileMap",
    "coords": [3, 7, 99]
  }
  ```
- **Expected result:** Success — the schema accepts arrays of 2+ elements and truncates to `[3, 7]`. Third element `99` is silently ignored.
- **What to pay attention to:** Verify that the cell is placed at `[3, 7]`, not `[3, 7, 99]`. The schema transformation should discard the third element.

---

## Tool: tilemap_fill_rect

**Description:** Fill a rectangular area of a TileMap with a tile

**Registered as:** `tilemap_fill_rect`
**Bridge method:** `tilemap/fill_rect`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | string (NodePath) | ✅ Yes | TileMap node path |
| `rect` | `{ x: int, y: int, w: positive int, h: positive int }` | ✅ Yes | Rectangle to fill |
| `source_id` | int (optional) | ❌ No | TileSet source ID |
| `atlas_coords` | `[int, int]` (Coord2D, optional) | ❌ No | Atlas coordinates `[x, y]` |

### Test Scenarios

#### Scenario 1: Fill small rect with required params only

- **Description:** Fill a 3×2 rectangle starting at `[0, 0]`.
- **Params:**
  ```json
  {
    "path": "TestTileMap",
    "rect": { "x": 0, "y": 0, "w": 3, "h": 2 }
  }
  ```
- **Expected result:** Success. 6 cells (3×2) should be filled.
- **What to pay attention to:** Verify via `tilemap_get_used_cells` that exactly 6 cells were created.

#### Scenario 2: Fill rect with all optional params

- **Description:** Fill a 5×5 rect with specific source and atlas coordinates.
- **Params:**
  ```json
  {
    "path": "TestTileMap",
    "rect": { "x": 10, "y": 10, "w": 5, "h": 5 },
    "source_id": 0,
    "atlas_coords": [1, 0]
  }
  ```
- **Expected result:** Success. 25 cells filled with the specified tile.
- **What to pay attention to:** All 25 cells should have the same tile. Verify via `tilemap_get_cell` on several random coordinates.

#### Scenario 3: Fill rect with 1×1 (single cell)

- **Description:** Edge case — fill a 1×1 rect, which should behave like `set_cell`.
- **Params:**
  ```json
  {
    "path": "TestTileMap",
    "rect": { "x": -5, "y": -5, "w": 1, "h": 1 }
  }
  ```
- **Expected result:** Success. Exactly 1 cell set at `[-5, -5]`.
- **What to pay attention to:** Verify that a 1×1 rect works identically to `set_cell` for the same coordinate.

#### Scenario 4: Missing `rect` — expect validation error

- **Description:** Call without `rect`.
- **Params:**
  ```json
  {
    "path": "TestTileMap"
  }
  ```
- **Expected result:** MCP validation error for missing required field `rect`.

#### Scenario 5: `w` or `h` is zero — expect validation error

- **Description:** Width must be positive (`z.number().int().positive()`), so 0 is rejected.
- **Params:**
  ```json
  {
    "path": "TestTileMap",
    "rect": { "x": 0, "y": 0, "w": 0, "h": 5 }
  }
  ```
- **Expected result:** Zod validation error — `w` must be positive (> 0).
- **What to pay attention to:** Ensure that the error clearly points to `w: 0` as the cause.

#### Scenario 6: `w` or `h` is negative — expect validation error

- **Description:** Negative dimensions should be rejected.
- **Params:**
  ```json
  {
    "path": "TestTileMap",
    "rect": { "x": 0, "y": 0, "w": -1, "h": 5 }
  }
  ```
- **Expected result:** Zod validation error — `w` must be positive.

#### Scenario 7: Non-integer `rect` fields — expect validation error

- **Description:** Float values in rect.
- **Params:**
  ```json
  {
    "path": "TestTileMap",
    "rect": { "x": 0.5, "y": 0, "w": 3, "h": 2 }
  }
  ```
- **Expected result:** Zod validation error — `x`, `y`, `w`, `h` are all `z.number().int()`.

#### Scenario 8: Large rect fill

- **Description:** Fill a 100×100 rectangle to test performance and correctness at scale.
- **Params:**
  ```json
  {
    "path": "TestTileMap",
    "rect": { "x": 0, "y": 0, "w": 100, "h": 100 },
    "source_id": 0
  }
  ```
- **Expected result:** Success. Verify with `tilemap_get_used_cells` that 10,000 cells are now used.
- **What to pay attention to:** This may take noticeable time. Verify there is no timeout and that all cells are actually filled.

---

## Tool: tilemap_get_cell

**Description:** Get the tile data at a specific cell

**Registered as:** `tilemap_get_cell`
**Bridge method:** `tilemap/get_cell`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | string (NodePath) | ✅ Yes | TileMap node path |
| `coords` | `[int, int]` (Coord2D) | ✅ Yes | Cell coordinates `[x, y]` |

### Test Scenarios

#### Scenario 1: Get cell data at a previously set cell

- **Description:** After setting a cell with `tilemap_set_cell` (coords `[0, 0]`, source_id `0`, atlas_coords `[1, 2]`), retrieve its data.
- **Setup:** Call `tilemap_set_cell` with:
  ```json
  {
    "path": "TestTileMap",
    "coords": [0, 0],
    "source_id": 0,
    "atlas_coords": [1, 2],
    "alternative_tile": 0
  }
  ```
- **Params:**
  ```json
  {
    "path": "TestTileMap",
    "coords": [0, 0]
  }
  ```
- **Expected result:** `ToolResult` with `isError: false`. Text content should contain tile data including source_id, atlas_coords, and alternative_tile matching the values that were set.
- **What to pay attention to:** Verify that the returned values `source_id`, `atlas_coords`, `alternative_tile` match what was set via `set_cell`.

#### Scenario 2: Get cell at empty/unset coordinates

- **Description:** Query a cell that has never been set.
- **Params:**
  ```json
  {
    "path": "TestTileMap",
    "coords": [999, 999]
  }
  ```
- **Expected result:** Either an empty/null result or a result indicating no tile at this cell. Should NOT be an error — empty cells are a valid query.
- **What to pay attention to:** Verify that an empty cell does not return `isError: true`. This is a valid query, the cell simply does not contain a tile.

#### Scenario 3: Missing required `coords`

- **Params:**
  ```json
  {
    "path": "TestTileMap"
  }
  ```
- **Expected result:** MCP validation error for missing `coords`.

#### Scenario 4: Non-existent node path

- **Params:**
  ```json
  {
    "path": "GhostTileMap",
    "coords": [0, 0]
  }
  ```
- **Expected result:** `isError: true` — node not found in scene.

---

## Tool: tilemap_clear

**Description:** Clear cells in a TileMap area or the entire map

**Registered as:** `tilemap_clear`
**Bridge method:** `tilemap/clear`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | string (NodePath) | ✅ Yes | TileMap node path |

> **Note:** The schema only has `path`. The description says "area or entire map" but no area parameters are exposed in the schema — this implies it clears the **entire** map.

### Test Scenarios

#### Scenario 1: Clear a populated TileMap

- **Description:** After filling cells via `tilemap_set_cell` or `tilemap_fill_rect`, clear the entire map.
- **Setup:** Fill some cells first:
  ```json
  {
    "tool": "tilemap_fill_rect",
    "params": {
      "path": "TestTileMap",
      "rect": { "x": 0, "y": 0, "w": 5, "h": 5 }
    }
  }
  ```
- **Params:**
  ```json
  {
    "path": "TestTileMap"
  }
  ```
- **Expected result:** Success. All cells removed.
- **Verification:** Call `tilemap_get_used_cells` afterward — should return an empty list.
- **What to pay attention to:** Ensure that after clearing, `tilemap_get_used_cells` returns an empty array/list.

#### Scenario 2: Clear an already empty TileMap

- **Description:** Clear a TileMap that has no cells. Should be a no-op, not an error.
- **Params:**
  ```json
  {
    "path": "TestTileMap"
  }
  ```
- **Expected result:** Success (not an error). Clearing an empty map is idempotent.
- **What to pay attention to:** The operation should be idempotent — clearing an empty map again should not return an error.

#### Scenario 3: Missing `path`

- **Params:**
  ```json
  {}
  ```
- **Expected result:** MCP validation error for missing `path`.

#### Scenario 4: Non-existent node

- **Params:**
  ```json
  {
    "path": "NonExistent"
  }
  ```
- **Expected result:** `isError: true` from Godot.

---

## Tool: tilemap_get_info

**Description:** Get TileMap configuration and TileSet information

**Registered as:** `tilemap_get_info`
**Bridge method:** `tilemap/get_info`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | string (NodePath) | ✅ Yes | TileMap node path |

### Test Scenarios

#### Scenario 1: Get info for a configured TileMap

- **Description:** Retrieve configuration for the TestTileMap that has a TileSet assigned.
- **Params:**
  ```json
  {
    "path": "TestTileMap"
  }
  ```
- **Expected result:** `ToolResult` with `isError: false`. Response should contain TileMap configuration data including:
  - TileSet information (sources, tile size, etc.)
  - TileMap layer count
  - Rendering settings
  - Cell/quadrant size
- **What to pay attention to:** Verify that the response contains meaningful TileMap configuration information, not an empty object. Key fields: `tile_set`, `cell_size`, `rendering_quadrant_size`, layer count.

#### Scenario 2: Get info for a TileMap without TileSet

- **Description:** Create a fresh TileMap node without assigning a TileSet, then query its info.
- **Setup:** `add_node` with type `TileMap`, name `EmptyTileMap`, no TileSet assigned.
- **Params:**
  ```json
  {
    "path": "EmptyTileMap"
  }
  ```
- **Expected result:** Either success with null/empty TileSet info, or a graceful indication that no TileSet is assigned.
- **What to pay attention to:** Behavior depends on Godot — may return `null` for tile_set or an empty structure. Ensure that an unhandled error is not returned.

#### Scenario 3: Non-existent node

- **Params:**
  ```json
  {
    "path": "GhostMap"
  }
  ```
- **Expected result:** `isError: true`.

---

## Tool: tilemap_get_used_cells

**Description:** Get all used cell coordinates in a TileMap

**Registered as:** `tilemap_get_used_cells`
**Bridge method:** `tilemap/get_used_cells`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | string (NodePath) | ✅ Yes | TileMap node path |

### Test Scenarios

#### Scenario 1: Get used cells after setting a few cells

- **Description:** Set 3 individual cells, then query all used cells.
- **Setup:**
  ```json
  { "tool": "tilemap_set_cell", "params": { "path": "TestTileMap", "coords": [0, 0] } }
  { "tool": "tilemap_set_cell", "params": { "path": "TestTileMap", "coords": [1, 0] } }
  { "tool": "tilemap_set_cell", "params": { "path": "TestTileMap", "coords": [0, 1] } }
  ```
- **Params:**
  ```json
  {
    "path": "TestTileMap"
  }
  ```
- **Expected result:** List/array of 3 coordinate pairs: `[[0,0], [1,0], [0,1]]` (order may vary).
- **What to pay attention to:** Verify that all 3 coordinates are returned and that the format is an array of pairs `[x, y]`. Order may be arbitrary.

#### Scenario 2: Get used cells on empty TileMap

- **Description:** After clearing, query used cells.
- **Setup:** Call `tilemap_clear` first.
- **Params:**
  ```json
  {
    "path": "TestTileMap"
  }
  ```
- **Expected result:** Empty array/list `[]`. Not an error.
- **What to pay attention to:** An empty map is a valid state. The result should be an empty array, not an error.

#### Scenario 3: Get used cells after `fill_rect`

- **Description:** Fill a 10×10 rect, then verify 100 cells reported.
- **Setup:**
  ```json
  { "tool": "tilemap_fill_rect", "params": { "path": "TestTileMap", "rect": { "x": 0, "y": 0, "w": 10, "h": 10 } } }
  ```
- **Params:**
  ```json
  {
    "path": "TestTileMap"
  }
  ```
- **Expected result:** Array of 100 coordinate pairs.
- **What to pay attention to:** Verify the exact count — 100 cells for a 10×10 rectangle. This confirms that `fill_rect` does not duplicate or skip cells.

#### Scenario 4: Non-existent node

- **Params:**
  ```json
  { "path": "GhostMap" }
  ```
- **Expected result:** `isError: true`.

---

## Tool: gridmap_set_cell

**Description:** Set a mesh item in a GridMap at 3D cell coordinates

**Registered as:** `gridmap_set_cell`
**Bridge method:** `gridmap/set_cell`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | string (NodePath) | ✅ Yes | GridMap node path |
| `coords` | `[int, int, int]` (Coord3D) | ✅ Yes | 3D cell coordinates `[x, y, z]` |
| `item` | int | ✅ Yes | MeshLibrary item ID. Use `-1` to clear a cell. |

### Test Scenarios

#### Scenario 1: Set cell with valid item ID

- **Description:** Place a mesh item at origin coordinates.
- **Params:**
  ```json
  {
    "path": "TestGridMap",
    "coords": [0, 0, 0],
    "item": 0
  }
  ```
- **Expected result:** Success. Mesh item 0 placed at `[0, 0, 0]`.
- **What to pay attention to:** Verify via `gridmap_get_cell` that item_id is indeed 0.

#### Scenario 2: Set cell at negative coordinates

- **Description:** Place mesh at negative 3D coordinates.
- **Params:**
  ```json
  {
    "path": "TestGridMap",
    "coords": [-10, -5, -20],
    "item": 0
  }
  ```
- **Expected result:** Success. GridMap supports negative coordinates.
- **What to pay attention to:** Negative coordinates are valid for GridMap. Ensure that the tool does not filter them out.

#### Scenario 3: Clear a cell with item = -1

- **Description:** Per the description, `-1` clears a cell. Set a cell first, then clear it.
- **Setup:** Set cell at `[1, 1, 1]` with item `0`.
- **Params:**
  ```json
  {
    "path": "TestGridMap",
    "coords": [1, 1, 1],
    "item": -1
  }
  ```
- **Expected result:** Success. Cell at `[1, 1, 1]` is now empty.
- **Verification:** `gridmap_get_cell` at `[1, 1, 1]` should return empty/cleared data.
- **What to pay attention to:** This is key behavior — `-1` as a special value for clearing. Verify that the cell is indeed empty after the call.

#### Scenario 4: Missing required `item`

- **Params:**
  ```json
  {
    "path": "TestGridMap",
    "coords": [0, 0, 0]
  }
  ```
- **Expected result:** MCP validation error — `item` is required.

#### Scenario 5: Missing `coords`

- **Params:**
  ```json
  {
    "path": "TestGridMap",
    "item": 0
  }
  ```
- **Expected result:** MCP validation error — `coords` is required.

#### Scenario 6: Non-integer coords

- **Params:**
  ```json
  {
    "path": "TestGridMap",
    "coords": [1.5, 2, 3],
    "item": 0
  }
  ```
- **Expected result:** Zod validation error — `Coord3D` requires `z.number().int()`.

#### Scenario 7: Coords array too short

- **Description:** Pass only 2 elements instead of 3.
- **Params:**
  ```json
  {
    "path": "TestGridMap",
    "coords": [1, 2],
    "item": 0
  }
  ```
- **Expected result:** Zod validation error — `Coord3D` has `.min(3)`.

#### Scenario 8: Non-existent GridMap node

- **Params:**
  ```json
  {
    "path": "GhostGrid",
    "coords": [0, 0, 0],
    "item": 0
  }
  ```
- **Expected result:** `isError: true` — node not found.

---

## Tool: gridmap_get_cell

**Description:** Get the mesh item at a specific GridMap cell

**Registered as:** `gridmap_get_cell`
**Bridge method:** `gridmap/get_cell`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | string (NodePath) | ✅ Yes | GridMap node path |
| `coords` | `[int, int, int]` (Coord3D) | ✅ Yes | 3D cell coordinates `[x, y, z]` |

### Test Scenarios

#### Scenario 1: Get a cell that was set

- **Description:** After `gridmap_set_cell` at `[2, 3, 4]` with item `0`, retrieve the cell.
- **Setup:**
  ```json
  { "tool": "gridmap_set_cell", "params": { "path": "TestGridMap", "coords": [2, 3, 4], "item": 0 } }
  ```
- **Params:**
  ```json
  {
    "path": "TestGridMap",
    "coords": [2, 3, 4]
  }
  ```
- **Expected result:** Response containing item ID `0` (and possibly orientation/rotation data).
- **What to pay attention to:** Verify that the returned item_id is 0. Also check whether orientation data is present (Godot GridMap stores mesh rotation).

#### Scenario 2: Get an empty cell

- **Description:** Query a cell that was never set.
- **Params:**
  ```json
  {
    "path": "TestGridMap",
    "coords": [100, 100, 100]
  }
  ```
- **Expected result:** Empty/null result (not an error). Indicates no mesh at that cell.
- **What to pay attention to:** An empty cell is a valid query. There should be no `isError: true`.

#### Scenario 3: Non-existent node

- **Params:**
  ```json
  { "path": "GhostGrid", "coords": [0, 0, 0] }
  ```
- **Expected result:** `isError: true`.

---

## Tool: gridmap_clear

**Description:** Clear all cells in a GridMap

**Registered as:** `gridmap_clear`
**Bridge method:** `gridmap/clear`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | string (NodePath) | ✅ Yes | GridMap node path |

### Test Scenarios

#### Scenario 1: Clear a populated GridMap

- **Setup:** Set several cells:
  ```json
  { "tool": "gridmap_set_cell", "params": { "path": "TestGridMap", "coords": [0,0,0], "item": 0 } }
  { "tool": "gridmap_set_cell", "params": { "path": "TestGridMap", "coords": [1,0,0], "item": 0 } }
  { "tool": "gridmap_set_cell", "params": { "path": "TestGridMap", "coords": [0,1,0], "item": 0 } }
  ```
- **Params:**
  ```json
  { "path": "TestGridMap" }
  ```
- **Expected result:** Success.
- **Verification:** `gridmap_get_used_cells` should return empty array afterward.
- **What to pay attention to:** Verify that `gridmap_get_used_cells` returns an empty array after clearing.

#### Scenario 2: Clear an already empty GridMap

- **Params:**
  ```json
  { "path": "TestGridMap" }
  ```
- **Expected result:** Success (idempotent, no error).

#### Scenario 3: Non-existent node

- **Params:**
  ```json
  { "path": "GhostGrid" }
  ```
- **Expected result:** `isError: true`.

---

## Tool: gridmap_get_used_cells

**Description:** Get all used cell coordinates in a GridMap

**Registered as:** `gridmap_get_used_cells`
**Bridge method:** `gridmap/get_used_cells`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | string (NodePath) | ✅ Yes | GridMap node path |

### Test Scenarios

#### Scenario 1: Get used cells after placing items

- **Setup:** Set 3 cells at `[0,0,0]`, `[1,0,0]`, `[0,0,1]`.
- **Params:**
  ```json
  { "path": "TestGridMap" }
  ```
- **Expected result:** Array of 3 coordinate triples.
- **What to pay attention to:** Each coordinate is a triple `[x, y, z]`. Verify the exact count and format.

#### Scenario 2: Get used cells on empty GridMap

- **Setup:** Call `gridmap_clear` first.
- **Params:**
  ```json
  { "path": "TestGridMap" }
  ```
- **Expected result:** Empty array `[]`.

#### Scenario 3: Non-existent node

- **Params:**
  ```json
  { "path": "GhostGrid" }
  ```
- **Expected result:** `isError: true`.

---

## Tool: gridmap_get_info

**Description:** Get GridMap configuration and MeshLibrary information

**Registered as:** `gridmap_get_info`
**Bridge method:** `gridmap/get_info`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `path` | string (NodePath) | ✅ Yes | GridMap node path |

### Test Scenarios

#### Scenario 1: Get info for a configured GridMap

- **Params:**
  ```json
  { "path": "TestGridMap" }
  ```
- **Expected result:** `ToolResult` with `isError: false`. Response should include:
  - MeshLibrary information (item count, item names)
  - Cell size
  - Collision/physics settings
  - Mesh rendering settings
- **What to pay attention to:** Verify that the response contains MeshLibrary data (item count, cell dimensions). If no MeshLibrary is assigned, `mesh_library` may be `null`.

#### Scenario 2: Get info for a GridMap without MeshLibrary

- **Setup:** Create a GridMap node without assigning a MeshLibrary.
- **Params:**
  ```json
  { "path": "EmptyGridMap" }
  ```
- **Expected result:** Success with null/empty MeshLibrary info. Not an error.
- **What to pay attention to:** Verify that the absence of a MeshLibrary does not cause a crash — it should return null or an empty value.

#### Scenario 3: Non-existent node

- **Params:**
  ```json
  { "path": "GhostGrid" }
  ```
- **Expected result:** `isError: true`.

---

## Recommended Test Sequences

These are full end-to-end sequences that test tool interactions in realistic workflows.

### Sequence A: TileMap CRUD lifecycle

Tests the full create → write → read → verify → clear → verify-empty cycle for 2D tilemaps.

```
1. create_scene { path: "res://scenes/test_tilemap_e2e.tscn", root_type: "Node2D" }
2. add_node { parent_path: "", type: "TileMap", name: "E2ETileMap" }
3. tilemap_get_info { path: "E2ETileMap" }
   → Verify TileSet info returned
4. tilemap_set_cell { path: "E2ETileMap", coords: [0, 0], source_id: 0, atlas_coords: [0, 0] }
   → Verify success
5. tilemap_set_cell { path: "E2ETileMap", coords: [5, 5], source_id: 0, atlas_coords: [1, 0] }
   → Verify success
6. tilemap_fill_rect { path: "E2ETileMap", rect: { x: 10, y: 10, w: 3, h: 3 }, source_id: 0 }
   → Verify success
7. tilemap_get_cell { path: "E2ETileMap", coords: [0, 0] }
   → Verify cell data matches step 4
8. tilemap_get_cell { path: "E2ETileMap", coords: [11, 11] }
   → Verify cell exists (inside fill_rect area)
9. tilemap_get_used_cells { path: "E2ETileMap" }
   → Verify 2 (set_cell) + 9 (fill_rect) = 11 cells
10. tilemap_clear { path: "E2ETileMap" }
    → Verify success
11. tilemap_get_used_cells { path: "E2ETileMap" }
    → Verify empty array []
12. tilemap_get_cell { path: "E2ETileMap", coords: [0, 0] }
    → Verify cell is empty/cleared
```

### Sequence B: GridMap CRUD lifecycle

Tests the full create → write → read → verify → clear → verify-empty cycle for 3D gridmaps.

```
1. create_scene { path: "res://scenes/test_gridmap_e2e.tscn", root_type: "Node3D" }
2. add_gridmap { parent: "", properties: { mesh_library_path: "res://assets/mesh_library.tres" } }
   → OR: add_node { parent_path: "", type: "GridMap", name: "E2EGridMap" }
3. gridmap_get_info { path: "E2EGridMap" }
   → Verify MeshLibrary info
4. gridmap_set_cell { path: "E2EGridMap", coords: [0, 0, 0], item: 0 }
5. gridmap_set_cell { path: "E2EGridMap", coords: [5, 0, 5], item: 0 }
6. gridmap_set_cell { path: "E2EGridMap", coords: [0, 3, 0], item: 0 }
7. gridmap_get_cell { path: "E2EGridMap", coords: [0, 0, 0] }
   → Verify item = 0
8. gridmap_get_used_cells { path: "E2EGridMap" }
   → Verify 3 cells
9. gridmap_set_cell { path: "E2EGridMap", coords: [0, 0, 0], item: -1 }
   → Clear one cell
10. gridmap_get_cell { path: "E2EGridMap", coords: [0, 0, 0] }
    → Verify cell is cleared
11. gridmap_get_used_cells { path: "E2EGridMap" }
    → Verify 2 cells remaining
12. gridmap_clear { path: "E2EGridMap" }
13. gridmap_get_used_cells { path: "E2EGridMap" }
    → Verify empty
```

### Sequence C: Error resilience

Tests that tools degrade gracefully under adverse conditions.

```
1. All tools with path: "NonExistentNode"
   → Each should return isError: true
2. tilemap_set_cell with coords: [1.5, 2.5]
   → Zod validation error
3. tilemap_fill_rect with rect: { x: 0, y: 0, w: 0, h: 5 }
   → Zod validation error (w must be positive)
4. tilemap_fill_rect with rect: { x: 0, y: 0, w: -1, h: 5 }
   → Zod validation error
5. gridmap_set_cell with coords: [1, 2] (only 2 elements)
   → Zod validation error (Coord3D requires min 3)
6. gridmap_set_cell without item
   → MCP validation error (required field)
7. All tools called with empty params {}
   → MCP validation error for missing path
```

### Sequence D: Overwrite / re-set cell

Tests that setting a cell that already has a tile overwrites it correctly.

```
1. tilemap_set_cell { path: "TestTileMap", coords: [0, 0], source_id: 0, atlas_coords: [0, 0] }
2. tilemap_get_cell { path: "TestTileMap", coords: [0, 0] }
   → Note atlas_coords [0, 0]
3. tilemap_set_cell { path: "TestTileMap", coords: [0, 0], source_id: 0, atlas_coords: [3, 3] }
4. tilemap_get_cell { path: "TestTileMap", coords: [0, 0] }
   → Verify atlas_coords is now [3, 3] — the cell was overwritten, not duplicated
5. tilemap_get_used_cells { path: "TestTileMap" }
   → Verify still exactly 1 cell (no duplicate)
```

### Sequence E: Fill rect then partially overwrite

```
1. tilemap_clear { path: "TestTileMap" }
2. tilemap_fill_rect { path: "TestTileMap", rect: { x: 0, y: 0, w: 10, h: 10 } }
   → 100 cells filled
3. tilemap_set_cell { path: "TestTileMap", coords: [5, 5], source_id: 0, atlas_coords: [7, 7] }
   → Overwrite one cell in the middle
4. tilemap_get_cell { path: "TestTileMap", coords: [5, 5] }
   → Verify atlas_coords [7, 7]
5. tilemap_get_used_cells { path: "TestTileMap" }
   → Verify still 100 cells (overwrite, not add)
```