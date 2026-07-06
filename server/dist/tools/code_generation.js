/**
 * Code generation tools - 6 tools for GDScript code generation and analysis
 */
import { callGodot } from '../server.js';
import { z, ScriptPath } from './shared-types.js';
export function registerCodeGenerationTools(server, bridge) {
  // 1. generate_gdscript
  server.registerTool(
    'generate_gdscript',
    {
      description: 'Generate a GDScript file from a natural language description',
      inputSchema: {
        description: z.string().describe('Description of what the script should do'),
        base_class: z.string().optional().describe("Base class to extend (e.g. 'CharacterBody2D', 'Node')"),
        style: z.enum(['minimal', 'documented']).optional().describe('Code style: minimal or fully documented (default: documented)'),
      },
    },
    async (args) => callGodot(bridge, 'generate_gdscript', args),
  );
  // 2. refactor_code
  server.registerTool(
    'refactor_code',
    {
      description: 'Refactor a GDScript file using a specified refactoring operation',
      inputSchema: {
        script_path: ScriptPath,
        refactoring: z.enum(['extract_method', 'rename', 'move', 'inline']).describe('Refactoring operation to perform'),
        target: z.string().optional().describe('Target for the refactoring (method name, new name, destination, etc.)'),
      },
    },
    async (args) => callGodot(bridge, 'refactor_code', args),
  );
  // 3. suggest_improvements
  server.registerTool(
    'suggest_improvements',
    {
      description: 'Analyze a GDScript file and suggest code quality improvements',
      inputSchema: {
        script_path: ScriptPath,
      },
    },
    async (args) => callGodot(bridge, 'suggest_improvements', args),
  );
  // 4. generate_unit_tests
  server.registerTool(
    'generate_unit_tests',
    {
      description: 'Generate unit test script for a GDScript file',
      inputSchema: {
        script_path: ScriptPath,
        framework: z.enum(['gut', 'custom']).optional().describe('Test framework to use (default: custom)'),
      },
    },
    async (args) => callGodot(bridge, 'generate_unit_tests', args),
  );
  // 5. generate_documentation
  server.registerTool(
    'generate_documentation',
    {
      description: 'Generate documentation comments for a GDScript file',
      inputSchema: {
        script_path: ScriptPath,
      },
    },
    async (args) => callGodot(bridge, 'generate_documentation', args),
  );
  // 6. check_code_quality
  server.registerTool(
    'check_code_quality',
    {
      description: 'Check a GDScript file for code quality issues and return a quality report',
      inputSchema: {
        script_path: ScriptPath,
      },
    },
    async (args) => callGodot(bridge, 'check_code_quality', args),
  );
}
//# sourceMappingURL=code_generation.js.map
