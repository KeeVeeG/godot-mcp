/**
 * TileMap tools - 6 tools for tilemap manipulation
 */
import { callGodot } from '../server.js';
import { z, NodePath, Coord2D, Coord3D } from './shared-types.js';
export function registerTilemapTools(server, bridge) {
    // 1. tilemap_set_cell
    server.registerTool('tilemap_set_cell', {
        description: 'Set a single cell in a TileMap',
        inputSchema: {
            path: NodePath.describe('TileMap node path'),
            coords: Coord2D,
            source_id: z.number().int().optional().describe('TileSet source ID (defaults to 0)'),
            atlas_coords: Coord2D.optional().describe('Atlas coordinates [x, y]'),
            alternative_tile: z.number().int().optional().describe('Alternative tile ID'),
        },
    }, async (args) => callGodot(bridge, 'tilemap/set_cell', args));
    // 2. tilemap_fill_rect
    server.registerTool('tilemap_fill_rect', {
        description: 'Fill a rectangular area of a TileMap with a tile',
        inputSchema: {
            path: NodePath.describe('TileMap node path'),
            rect: z
                .object({
                x: z.number().int(),
                y: z.number().int(),
                w: z.number().int().positive(),
                h: z.number().int().positive(),
            })
                .describe('Rectangle to fill'),
            source_id: z.number().int().optional().describe('TileSet source ID (defaults to 0)'),
            atlas_coords: Coord2D.optional().describe('Atlas coordinates [x, y]'),
            alternative_tile: z.number().int().optional().describe('Alternative tile ID'),
        },
    }, async (args) => callGodot(bridge, 'tilemap/fill_rect', args));
    // 3. tilemap_get_cell
    server.registerTool('tilemap_get_cell', {
        description: 'Get the tile data at a specific cell',
        inputSchema: {
            path: NodePath.describe('TileMap node path'),
            coords: Coord2D,
        },
    }, async (args) => callGodot(bridge, 'tilemap/get_cell', args));
    // 4. tilemap_clear
    server.registerTool('tilemap_clear', {
        description: 'Clear cells in a TileMap area or the entire map',
        inputSchema: {
            path: NodePath.describe('TileMap node path'),
        },
    }, async (args) => callGodot(bridge, 'tilemap/clear', args));
    // 5. tilemap_get_info
    server.registerTool('tilemap_get_info', {
        description: 'Get TileMap configuration and TileSet information',
        inputSchema: {
            path: NodePath.describe('TileMap node path'),
        },
    }, async (args) => callGodot(bridge, 'tilemap/get_info', args));
    // 6. tilemap_get_used_cells
    server.registerTool('tilemap_get_used_cells', {
        description: 'Get all used cell coordinates in a TileMap. Uses compact [[x,y],...] format. Capped at 1000 cells by default — use limit: 0 for all cells (caution: large maps may cause WebSocket crashes).',
        inputSchema: {
            path: NodePath.describe('TileMap node path'),
            limit: z.number().int().optional().describe('Maximum cells to return (default: 1000, use 0 for no limit)'),
        },
    }, async (args) => callGodot(bridge, 'tilemap/get_used_cells', args));
    // ────────────────────────────────────────────────────────────
    // GridMap tools (3D tile-based level editing)
    // ────────────────────────────────────────────────────────────
    // 7. gridmap_set_cell
    server.registerTool('gridmap_set_cell', {
        description: 'Set a mesh item in a GridMap at 3D cell coordinates',
        inputSchema: {
            path: NodePath.describe('GridMap node path'),
            coords: Coord3D,
            item: z.number().int().describe('MeshLibrary item ID (-1 to clear)'),
        },
    }, async (args) => callGodot(bridge, 'gridmap/set_cell', args));
    // 8. gridmap_get_cell
    server.registerTool('gridmap_get_cell', {
        description: 'Get the mesh item at a specific GridMap cell',
        inputSchema: {
            path: NodePath.describe('GridMap node path'),
            coords: Coord3D,
        },
    }, async (args) => callGodot(bridge, 'gridmap/get_cell', args));
    // 9. gridmap_clear
    server.registerTool('gridmap_clear', {
        description: 'Clear all cells in a GridMap',
        inputSchema: {
            path: NodePath.describe('GridMap node path'),
        },
    }, async (args) => callGodot(bridge, 'gridmap/clear', args));
    // 10. gridmap_get_used_cells
    server.registerTool('gridmap_get_used_cells', {
        description: 'Get all used cell coordinates in a GridMap. Uses compact [[x,y,z],...] format. Capped at 1000 cells by default — use limit: 0 for all cells (caution: large maps may cause WebSocket crashes).',
        inputSchema: {
            path: NodePath.describe('GridMap node path'),
            limit: z.number().int().optional().describe('Maximum cells to return (default: 1000, use 0 for no limit)'),
        },
    }, async (args) => callGodot(bridge, 'gridmap/get_used_cells', args));
    // 11. gridmap_get_info
    server.registerTool('gridmap_get_info', {
        description: 'Get GridMap configuration and MeshLibrary information',
        inputSchema: {
            path: NodePath.describe('GridMap node path'),
        },
    }, async (args) => callGodot(bridge, 'gridmap/get_info', args));
}
//# sourceMappingURL=tilemap.js.map