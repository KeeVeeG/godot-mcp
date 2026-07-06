/**
 * Asset pipeline tools - 8 tools for asset import, optimization, and management
 */
import { callGodot } from '../server.js';
import { z, ResourcePath, Properties, OptionalProperties } from './shared-types.js';
export function registerAssetPipelineTools(server, bridge) {
  // 1. get_import_settings
  server.registerTool(
    'get_import_settings',
    {
      description: 'Get the current import settings for a specific asset',
      inputSchema: {
        asset_path: ResourcePath.describe("Path to the asset (e.g. 'res://assets/sprite.png')"),
      },
    },
    async (args) => callGodot(bridge, 'asset_pipeline/get_import_settings', args),
  );
  // 2. set_import_settings
  server.registerTool(
    'set_import_settings',
    {
      description: 'Set import settings for a specific asset and trigger reimport',
      inputSchema: {
        asset_path: ResourcePath.describe('Path to the asset'),
        settings: Properties.describe('Import settings to apply'),
      },
    },
    async (args) => callGodot(bridge, 'asset_pipeline/set_import_settings', args),
  );
  // 3. optimize_asset_textures
  server.registerTool(
    'optimize_asset_textures',
    {
      description: 'Optimize textures in the project (resize, compress, convert format)',
      inputSchema: {
        path: z.string().optional().describe('Directory to scan (default: entire project)'),
        max_size: z.number().int().positive().optional().describe('Max texture dimension in pixels'),
        format: z.enum(['webp', 'basis', 'astc']).optional().describe('Target compression format'),
      },
    },
    async (args) => callGodot(bridge, 'asset_pipeline/optimize_asset_textures', args),
  );
  // 4. compress_audio
  server.registerTool(
    'compress_audio',
    {
      description: 'Compress audio files in the project',
      inputSchema: {
        path: z.string().optional().describe('Directory to scan (default: entire project)'),
        quality: z.enum(['low', 'medium', 'high']).optional().describe('Compression quality (default: medium)'),
      },
    },
    async (args) => callGodot(bridge, 'asset_pipeline/compress_audio', args),
  );
  // 5. batch_reimport
  server.registerTool(
    'batch_reimport',
    {
      description: 'Reimport assets in batch with optional new settings',
      inputSchema: {
        path: z.string().optional().describe('Directory to reimport (default: entire project)'),
        settings: OptionalProperties.describe('New import settings to apply during reimport'),
      },
    },
    async (args) => callGodot(bridge, 'asset_pipeline/batch_reimport', args),
  );
  // 6. create_atlas
  server.registerTool(
    'create_atlas',
    {
      description: 'Create a texture atlas from multiple texture files',
      inputSchema: {
        textures: z.array(z.string()).describe('List of texture paths to include in the atlas'),
        max_size: z.number().int().positive().optional().describe('Maximum atlas size in pixels (default: 2048)'),
      },
    },
    async (args) => callGodot(bridge, 'asset_pipeline/create_atlas', args),
  );
  // 7. validate_assets
  server.registerTool(
    'validate_assets',
    {
      description: 'Validate assets for common issues (missing files, broken references, oversized)',
      inputSchema: {
        path: z.string().optional().describe('Directory to validate (default: entire project)'),
      },
    },
    async (args) => callGodot(bridge, 'asset_pipeline/validate_assets', args),
  );
  // 8. get_asset_dependencies
  server.registerTool(
    'get_asset_dependencies',
    {
      description: 'Get the dependency tree for a specific asset',
      inputSchema: {
        asset_path: ResourcePath.describe('Path to the asset'),
      },
    },
    async (args) => callGodot(bridge, 'asset_pipeline/get_asset_dependencies', args),
  );
}
//# sourceMappingURL=asset_pipeline.js.map
