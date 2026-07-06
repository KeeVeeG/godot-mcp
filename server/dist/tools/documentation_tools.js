/**
 * Documentation tools - 6 tools for project documentation generation
 */
import { callGodot } from '../server.js';
import { z, FilePath, ScenePath } from './shared-types.js';
export function registerDocumentationTools(server, bridge) {
  // 1. generate_project_documentation
  server.registerTool(
    'generate_project_documentation',
    {
      description: 'Generate comprehensive project documentation from project structure and scripts',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        format: z.enum(['markdown', 'html', 'pdf']).optional().describe('Output format'),
      },
    },
    async (args) => callGodot(bridge, 'documentation/generate_project_docs', args),
  );
  // 2. generate_api_documentation
  server.registerTool(
    'generate_api_documentation',
    {
      description: 'Generate API reference documentation from all GDScript files in the project',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        include_private: z.boolean().optional().describe('Include private methods and variables'),
      },
    },
    async (args) => callGodot(bridge, 'documentation/generate_api_docs', args),
  );
  // 3. generate_scene_diagram
  server.registerTool(
    'generate_scene_diagram',
    {
      description: "Generate a text-based diagram of a scene's node hierarchy and signal connections",
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        scene_path: ScenePath,
      },
    },
    async (args) => callGodot(bridge, 'documentation/generate_scene_diagram', args),
  );
  // 4. generate_class_diagram
  server.registerTool(
    'generate_class_diagram',
    {
      description: 'Generate a class diagram showing inheritance and composition relationships',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        classes: z.array(z.string()).optional().describe('Specific classes to include (defaults to all)'),
      },
    },
    async (args) => callGodot(bridge, 'documentation/generate_class_diagram', args),
  );
  // 5. create_changelog
  server.registerTool(
    'create_changelog',
    {
      description: 'Create or update a CHANGELOG.md file with version history entries',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        entries: z
          .array(
            z.object({
              version: z.string().describe("Version number (e.g. '1.0.0')"),
              date: z.string().describe('Release date (YYYY-MM-DD)'),
              changes: z.array(z.string()).describe('List of changes'),
            }),
          )
          .optional()
          .describe('Changelog entries to add'),
      },
    },
    async (args) => callGodot(bridge, 'documentation/create_changelog', args),
  );
  // 6. generate_user_manual
  server.registerTool(
    'generate_user_manual',
    {
      description: 'Generate a user manual with controls, gameplay, and technical sections',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        sections: z.array(z.string()).optional().describe('Specific sections to include'),
      },
    },
    async (args) => callGodot(bridge, 'documentation/generate_user_manual', args),
  );
}
//# sourceMappingURL=documentation_tools.js.map
