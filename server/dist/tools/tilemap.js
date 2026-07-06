/**
 * TileMap tools - 6 tools for tilemap manipulation
 */
import { callGodot } from '../server.js';
import { z, NodePath, Coord2D } from './shared-types.js';
export function registerTilemapTools(server, bridge) {
  // 1. tilemap_set_cell
  server.registerTool(
    'tilemap_set_cell',
    {
      description: 'Set a single cell in a TileMap',
      inputSchema: {
        path: NodePath.describe('TileMap node path'),
        coords: Coord2D,
        source_id: z.number().int().optional().describe('TileSet source ID'),
        atlas_coords: Coord2D.optional().describe('Atlas coordinates [x, y]'),
        alternative_tile: z.number().int().optional().describe('Alternative tile ID'),
      },
    },
    async (args) => callGodot(bridge, 'tilemap/set_cell', args),
  );
  // 2. tilemap_fill_rect
  server.registerTool(
    'tilemap_fill_rect',
    {
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
        source_id: z.number().int().optional().describe('TileSet source ID'),
        atlas_coords: Coord2D.optional().describe('Atlas coordinates [x, y]'),
      },
    },
    async (args) => callGodot(bridge, 'tilemap/fill_rect', args),
  );
  // 3. tilemap_get_cell
  server.registerTool(
    'tilemap_get_cell',
    {
      description: 'Get the tile data at a specific cell',
      inputSchema: {
        path: NodePath.describe('TileMap node path'),
        coords: Coord2D,
      },
    },
    async (args) => callGodot(bridge, 'tilemap/get_cell', args),
  );
  // 4. tilemap_clear
  server.registerTool(
    'tilemap_clear',
    {
      description: 'Clear cells in a TileMap area or the entire map',
      inputSchema: {
        path: NodePath.describe('TileMap node path'),
      },
    },
    async (args) => callGodot(bridge, 'tilemap/clear', args),
  );
  // 5. tilemap_get_info
  server.registerTool(
    'tilemap_get_info',
    {
      description: 'Get TileMap configuration and TileSet information',
      inputSchema: {
        path: NodePath.describe('TileMap node path'),
      },
    },
    async (args) => callGodot(bridge, 'tilemap/get_info', args),
  );
  // 6. tilemap_get_used_cells
  server.registerTool(
    'tilemap_get_used_cells',
    {
      description: 'Get all used cell coordinates in a TileMap',
      inputSchema: {
        path: NodePath.describe('TileMap node path'),
      },
    },
    async (args) => callGodot(bridge, 'tilemap/get_used_cells', args),
  );
}
//# sourceMappingURL=tilemap.js.map
