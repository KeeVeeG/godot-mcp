/**
 * Mod support tools - 8 tools for game modding framework management
 */
import { callGodot } from '../server.js';
import { z, Name, FilePath } from './shared-types.js';
export function registerModSupportTools(server, bridge) {
  // 1. get_mod_settings
  server.registerTool(
    'get_mod_settings',
    {
      description: 'Get the current mod framework configuration',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'get_mod_settings'),
  );
  // 2. enable_modding
  server.registerTool(
    'enable_modding',
    {
      description: 'Enable the modding framework with optional API version and sandbox settings',
      inputSchema: {
        api_version: z.string().optional().describe("Mod API version to use (default: '1.0')"),
        sandboxed: z.boolean().optional().describe('Whether mods run in a sandboxed environment (default: true)'),
      },
    },
    async (args) => callGodot(bridge, 'enable_modding', args),
  );
  // 3. load_mod
  server.registerTool(
    'load_mod',
    {
      description: 'Load a mod from the specified path',
      inputSchema: {
        mod_path: FilePath.describe('Path to the mod directory or archive (res:// or user://)'),
        enabled: z.boolean().optional().describe('Whether the mod should be enabled immediately (default: true)'),
      },
    },
    async (args) => callGodot(bridge, 'load_mod', args),
  );
  // 4. unload_mod
  server.registerTool(
    'unload_mod',
    {
      description: 'Unload a currently loaded mod by its ID',
      inputSchema: {
        mod_id: Name.describe('ID of the mod to unload'),
      },
    },
    async (args) => callGodot(bridge, 'unload_mod', args),
  );
  // 5. get_loaded_mods
  server.registerTool(
    'get_loaded_mods',
    {
      description: 'Get a list of all currently loaded mods with their status',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'get_loaded_mods'),
  );
  // 6. validate_mod
  server.registerTool(
    'validate_mod',
    {
      description: 'Validate a mod package for correctness and compatibility',
      inputSchema: {
        mod_path: FilePath.describe('Path to the mod directory or archive to validate'),
      },
    },
    async (args) => callGodot(bridge, 'validate_mod', args),
  );
  // 7. create_mod_template
  server.registerTool(
    'create_mod_template',
    {
      description: 'Create a new mod template with the specified name and type',
      inputSchema: {
        name: Name.describe('Name for the new mod'),
        type: z.enum(['content', 'gameplay', 'ui', 'total_conversion']).describe('Type of mod to create'),
      },
    },
    async (args) => callGodot(bridge, 'create_mod_template', args),
  );
  // 8. get_mod_api
  server.registerTool(
    'get_mod_api',
    {
      description: 'Get the available modding API with all functions and hooks available to modders',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'get_mod_api'),
  );
}
//# sourceMappingURL=mod_support.js.map
