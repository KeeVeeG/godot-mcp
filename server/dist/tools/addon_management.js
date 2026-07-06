/**
 * Addon management tools - 5 tools for plugin/addon lifecycle management
 */
import { callGodot } from '../server.js';
import { z, Name, Properties } from './shared-types.js';
export function registerAddonManagementTools(server, bridge) {
  // 1. list_addons
  server.registerTool(
    'list_addons',
    {
      description: 'List all installed addons/plugins with their versions and status',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'list_addons'),
  );
  // 2. install_addon
  server.registerTool(
    'install_addon',
    {
      description: 'Install an addon from the Asset Library, git repository, or local path',
      inputSchema: {
        name: Name.describe('Addon name or identifier'),
        source: z.enum(['asset_lib', 'git', 'local']).optional().default('asset_lib').describe('Installation source (default: asset_lib)'),
        url: z.string().optional().describe('Git URL or local path (required for git/local sources)'),
      },
    },
    async (args) => callGodot(bridge, 'install_addon', args),
  );
  // 3. uninstall_addon
  server.registerTool(
    'uninstall_addon',
    {
      description: 'Uninstall an addon and remove its files',
      inputSchema: {
        name: Name.describe('Addon name to uninstall'),
      },
    },
    async (args) => callGodot(bridge, 'uninstall_addon', args),
  );
  // 4. update_addon
  server.registerTool(
    'update_addon',
    {
      description: 'Update an installed addon to its latest version',
      inputSchema: {
        name: Name.describe('Addon name to update'),
      },
    },
    async (args) => callGodot(bridge, 'update_addon', args),
  );
  // 5. configure_addon
  server.registerTool(
    'configure_addon',
    {
      description: 'Update configuration settings for an installed addon',
      inputSchema: {
        name: Name.describe('Addon name to configure'),
        settings: Properties.describe('Configuration key-value pairs to set'),
      },
    },
    async (args) => callGodot(bridge, 'configure_addon', args),
  );
}
//# sourceMappingURL=addon_management.js.map
