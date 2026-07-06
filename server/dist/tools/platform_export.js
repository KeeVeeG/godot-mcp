/**
 * Platform export tools - 6 tools for multi-platform export management
 */
import { callGodot } from '../server.js';
import { z, Name, FilePath, OptionalProperties } from './shared-types.js';
export function registerPlatformExportTools(server, bridge) {
  // 1. export_for_platform
  server.registerTool(
    'export_for_platform',
    {
      description: 'Export the project for a specific platform',
      inputSchema: {
        platform: z.enum(['windows', 'linux', 'macos', 'android', 'ios', 'web']).describe('Target platform'),
        debug: z.boolean().optional().default(false).describe('Export as debug build (default: false = release)'),
      },
    },
    async (args) => callGodot(bridge, 'export_for_platform', args),
  );
  // 2. validate_platform_export
  server.registerTool(
    'validate_platform_export',
    {
      description: 'Validate the project for export on a specific platform, checking for issues',
      inputSchema: {
        platform: z.string().describe('Platform to validate for'),
      },
    },
    async (args) => callGodot(bridge, 'validate_platform_export', args),
  );
  // 3. get_platform_export_templates
  server.registerTool(
    'get_platform_export_templates',
    {
      description: 'Get available export templates installed for the current Godot version',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'get_platform_export_templates'),
  );
  // 4. create_platform_export_preset
  server.registerTool(
    'create_platform_export_preset',
    {
      description: 'Create a new export preset for a specific platform with optional custom settings',
      inputSchema: {
        platform: z.string().describe("Target platform (e.g. 'Windows Desktop', 'Linux', 'Android', 'Web')"),
        name: Name.describe('Preset name'),
        settings: OptionalProperties,
      },
    },
    async (args) => callGodot(bridge, 'create_platform_export_preset', args),
  );
  // 5. run_exported_build
  server.registerTool(
    'run_exported_build',
    {
      description: 'Run an exported build and capture its output',
      inputSchema: {
        path: FilePath.describe('Path to the exported executable'),
        args: z.array(z.string()).optional().describe('Command-line arguments for the build'),
      },
    },
    async (args) => callGodot(bridge, 'run_exported_build', args),
  );
  // 6. validate_export_for_platform
  server.registerTool(
    'validate_export_for_platform',
    {
      description: 'Validate the project for export on a specific platform with detailed checks',
      inputSchema: {
        platform: z.string().describe('Platform to validate for'),
      },
    },
    async (args) => callGodot(bridge, 'export/validate_platform', args),
  );
}
//# sourceMappingURL=platform_export.js.map
