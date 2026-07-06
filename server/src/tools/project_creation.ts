/**
 * Project creation tools - 10 tools for project scaffolding and setup
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, Name, FilePath } from './shared-types.js';

export function registerProjectCreationTools(server: McpServer, bridge: GodotBridge): void {
  // 1. create_project
  server.registerTool(
    'create_project',
    {
      description: 'Create a complete Godot project from scratch with proper structure and configuration',
      inputSchema: {
        path: FilePath.describe('Directory path where the project will be created'),
        name: Name.describe('Project name'),
        template: z.enum(['empty', '2d', '3d', 'ui', 'custom']).optional().describe('Project template type'),
        godot_version: z.string().optional().describe("Target Godot version (e.g. '4.3')"),
        renderer: z.enum(['forward_plus', 'mobile', 'gl_compatibility']).optional().describe('Rendering engine'),
      },
    },
    async (args) => callGodot(bridge, 'project_creation/create_project', args as Record<string, unknown>),
  );

  // 2. create_project_from_template
  server.registerTool(
    'create_project_from_template',
    {
      description: 'Create a new Godot project from an existing template project',
      inputSchema: {
        path: FilePath.describe('Directory path where the project will be created'),
        template_path: FilePath.describe('Path to the template project directory'),
        name: Name.optional().describe('Override project name'),
      },
    },
    async (args) => callGodot(bridge, 'project_creation/create_from_template', args as Record<string, unknown>),
  );

  // 3. scaffold_project_structure
  server.registerTool(
    'scaffold_project_structure',
    {
      description: 'Create a standard folder structure for a Godot project',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        structure: z.enum(['standard', 'minimal', 'full']).optional().describe('Folder structure preset'),
      },
    },
    async (args) => callGodot(bridge, 'project_creation/scaffold_structure', args as Record<string, unknown>),
  );

  // 4. create_project_with_assets
  server.registerTool(
    'create_project_with_assets',
    {
      description: 'Create a new Godot project and import specified assets into it',
      inputSchema: {
        path: FilePath.describe('Directory path where the project will be created'),
        name: Name.describe('Project name'),
        assets: z
          .array(
            z.object({
              type: z.string().describe("Asset type (e.g. 'texture', 'audio', 'scene', 'script')"),
              source: z.string().describe('Source file path to import from'),
              destination: z.string().describe('Destination path within the project (res://...)'),
            }),
          )
          .describe('List of assets to import into the project'),
      },
    },
    async (args) => callGodot(bridge, 'project_creation/create_with_assets', args as Record<string, unknown>),
  );

  // 5. initialize_git_repository
  server.registerTool(
    'initialize_git_repository',
    {
      description: 'Initialize a Git repository in the project directory with a proper .gitignore',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        include_gitignore: z.boolean().optional().describe('Whether to create a Godot-specific .gitignore'),
      },
    },
    async (args) => callGodot(bridge, 'project_creation/init_git', args as Record<string, unknown>),
  );

  // 6. create_project_readme
  server.registerTool(
    'create_project_readme',
    {
      description: 'Generate a README.md file for the project',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        content: z.string().optional().describe('Custom README content (overrides template)'),
        template: z.enum(['basic', 'detailed', 'game']).optional().describe('README template style'),
      },
    },
    async (args) => callGodot(bridge, 'project_creation/create_readme', args as Record<string, unknown>),
  );

  // 7. create_project_license
  server.registerTool(
    'create_project_license',
    {
      description: 'Create a LICENSE file for the project',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        license: z.enum(['MIT', 'Apache-2.0', 'GPL-3.0', 'BSD-3-Clause', 'custom']).describe('License type'),
        custom_text: z.string().optional().describe("Custom license text (required when license is 'custom')"),
      },
    },
    async (args) => callGodot(bridge, 'project_creation/create_license', args as Record<string, unknown>),
  );

  // 8. setup_project_dependencies
  server.registerTool(
    'setup_project_dependencies',
    {
      description: 'Install and configure project addons/dependencies',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        addons: z
          .array(
            z.object({
              name: z.string().describe('Addon name'),
              source: z.enum(['asset_lib', 'git', 'local']).describe('Where to get the addon from'),
              url: z.string().optional().describe('Git URL or local path (required for git/local sources)'),
            }),
          )
          .describe('List of addons to install'),
      },
    },
    async (args) => callGodot(bridge, 'project_creation/setup_dependencies', args as Record<string, unknown>),
  );

  // 9. validate_project_structure
  server.registerTool(
    'validate_project_structure',
    {
      description: "Validate a Godot project's folder structure and configuration for correctness",
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
      },
    },
    async (args) => callGodot(bridge, 'project_creation/validate_structure', args as Record<string, unknown>),
  );

  // 10. get_project_templates
  server.registerTool(
    'get_project_templates',
    {
      description: 'List all available project templates that can be used with create_project',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'project_creation/get_templates'),
  );
}
