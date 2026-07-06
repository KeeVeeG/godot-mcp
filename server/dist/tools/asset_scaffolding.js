/**
 * Asset scaffolding tools - 6 tools for procedural asset generation
 */
import { callGodot } from '../server.js';
import { z, Name, FilePath } from './shared-types.js';
export function registerAssetScaffoldingTools(server, bridge) {
  // 1. create_sprite_sheet
  server.registerTool(
    'create_sprite_sheet',
    {
      description: 'Create a placeholder sprite sheet texture with grid layout for animation frames',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        width: z.number().describe('Width of each frame in pixels'),
        height: z.number().describe('Height of each frame in pixels'),
        frames: z.number().describe('Number of animation frames'),
        name: Name.optional().describe('Sprite sheet file name'),
      },
    },
    async (args) => callGodot(bridge, 'asset_scaffolding/create_sprite_sheet', args),
  );
  // 2. create_tileset
  server.registerTool(
    'create_tileset',
    {
      description: 'Create a TileSet resource with defined tile types and properties',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        tile_size: z.number().describe('Size of each tile in pixels (e.g. 16, 32, 64)'),
        tiles: z
          .array(
            z.object({
              name: z.string().describe('Tile name'),
              type: z.string().describe("Tile type (e.g. 'ground', 'wall', 'water', 'hazard')"),
            }),
          )
          .describe('Tile definitions'),
      },
    },
    async (args) => callGodot(bridge, 'asset_scaffolding/create_tileset', args),
  );
  // 3. create_animation_library
  server.registerTool(
    'create_animation_library',
    {
      description: 'Create an AnimationLibrary resource with predefined animation clips',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        animations: z
          .array(
            z.object({
              name: z.string().describe('Animation name'),
              frames: z.number().describe('Number of keyframes'),
              fps: z.number().optional().describe('Frames per second (defaults to 12)'),
            }),
          )
          .describe('Animation definitions'),
      },
    },
    async (args) => callGodot(bridge, 'asset_scaffolding/create_animation_library', args),
  );
  // 4. create_audio_library
  server.registerTool(
    'create_audio_library',
    {
      description: 'Create an audio bus layout with placeholder entries for game sounds',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        sounds: z
          .array(
            z.object({
              name: z.string().describe('Sound name'),
              type: z.enum(['sfx', 'music', 'ambient']).describe('Sound category'),
            }),
          )
          .describe('Sound definitions'),
      },
    },
    async (args) => callGodot(bridge, 'asset_scaffolding/create_audio_library', args),
  );
  // 5. create_theme_preset
  server.registerTool(
    'create_theme_preset',
    {
      description: 'Create a Godot Theme resource with a predefined visual style',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        style: z.enum(['pixel', 'modern', 'minimalist', 'fantasy', 'sci-fi']).describe('Theme visual style'),
      },
    },
    async (args) => callGodot(bridge, 'asset_scaffolding/create_theme_preset', args),
  );
  // 6. create_shader_library
  server.registerTool(
    'create_shader_library',
    {
      description: 'Create a collection of shader files for common visual effects',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        shaders: z
          .array(
            z.object({
              name: z.string().describe('Shader name'),
              type: z.enum(['visual', 'particles', 'post_process']).describe('Shader category'),
            }),
          )
          .describe('Shader definitions'),
      },
    },
    async (args) => callGodot(bridge, 'asset_scaffolding/create_shader_library', args),
  );
}
//# sourceMappingURL=asset_scaffolding.js.map
