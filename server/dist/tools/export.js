/**
 * Export tools - 7 tools for project export
 */
import { callGodot } from '../server.js';
import { z, Name } from './shared-types.js';
export function registerExportTools(server, bridge) {
  // 1. list_export_presets
  server.registerTool(
    'list_export_presets',
    {
      description: 'List all configured export presets',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'export/list_presets'),
  );
  // 2. export_project
  server.registerTool(
    'export_project',
    {
      description: 'Export the project using a specific preset',
      inputSchema: {
        preset: Name.describe('Export preset name'),
        output_path: z.string().optional().describe('Output path for the export'),
        debug: z.boolean().optional().default(false).describe('Export as debug build (default: false = release)'),
        pack_only: z.boolean().optional().default(false).describe('Export as pack file only (default: false)'),
      },
    },
    async (args) => callGodot(bridge, 'export/project', args),
  );
  // 3. get_export_info
  server.registerTool(
    'get_export_info',
    {
      description: 'Get export project information (platform, features, resources)',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'export/get_info'),
  );
  // 4. validate_export
  server.registerTool(
    'validate_export',
    {
      description: 'Validate the project for export (check for missing resources, errors)',
      inputSchema: {},
    },
    async (args) => callGodot(bridge, 'export/validate', args),
  );
  // 5. get_export_templates
  server.registerTool(
    'get_export_templates',
    {
      description: 'Get available export templates for the current Godot version',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'export/get_templates'),
  );
  // 6. create_export_preset
  server.registerTool(
    'create_export_preset',
    {
      description: 'Create a new export preset',
      inputSchema: {
        name: Name.describe('Preset name'),
        platform: z.string().describe("Target platform (e.g. 'Windows Desktop', 'Linux', 'Android')"),
      },
    },
    async (args) => callGodot(bridge, 'export/create_preset', args),
  );
  // 7. delete_export_preset
  server.registerTool(
    'delete_export_preset',
    {
      description: 'Delete an export preset from the project',
      inputSchema: {
        name: z.string().describe('Name of the export preset to delete'),
      },
    },
    async (args) => callGodot(bridge, 'export/delete_preset', args),
  );
}
//# sourceMappingURL=export.js.map
