/**
 * Code quality tools - 8 tools for linting, analysis, and code health
 */
import { callGodot } from '../server.js';
import { z, ScriptPath } from './shared-types.js';
export function registerCodeQualityTools(server, bridge) {
  // 1. run_linter
  server.registerTool(
    'run_linter',
    {
      description: 'Run GDScript linter on project files and return lint errors',
      inputSchema: {
        path: z.string().optional().describe('Directory or file to lint (default: entire project)'),
        fix: z.boolean().optional().describe('Attempt to auto-fix issues (default: false)'),
      },
    },
    async (args) => callGodot(bridge, 'code_quality/run_linter', args),
  );
  // 2. run_static_analysis
  server.registerTool(
    'run_static_analysis',
    {
      description: 'Run static analysis on GDScript files to find potential issues',
      inputSchema: {
        path: z.string().optional().describe('Directory or file to analyze (default: entire project)'),
      },
    },
    async (args) => callGodot(bridge, 'code_quality/run_static_analysis', args),
  );
  // 3. check_type_safety
  server.registerTool(
    'check_type_safety',
    {
      description: 'Check type safety of a GDScript file (untyped variables, missing return types)',
      inputSchema: {
        script_path: ScriptPath,
      },
    },
    async (args) => callGodot(bridge, 'code_quality/check_type_safety', args),
  );
  // 4. find_code_smells
  server.registerTool(
    'find_code_smells',
    {
      description: 'Find code smells in GDScript files (long functions, deep nesting, god classes)',
      inputSchema: {
        path: z.string().optional().describe('Directory or file to scan (default: entire project)'),
      },
    },
    async (args) => callGodot(bridge, 'code_quality/find_code_smells', args),
  );
  // 5. calculate_code_metrics
  server.registerTool(
    'calculate_code_metrics',
    {
      description: 'Calculate code metrics (cyclomatic complexity, lines of code, function count)',
      inputSchema: {
        path: z.string().optional().describe('Directory or file to measure (default: entire project)'),
      },
    },
    async (args) => callGodot(bridge, 'code_quality/calculate_code_metrics', args),
  );
  // 6. suggest_refactoring
  server.registerTool(
    'suggest_refactoring',
    {
      description: 'Analyze a GDScript file and suggest refactoring improvements',
      inputSchema: {
        script_path: ScriptPath,
      },
    },
    async (args) => callGodot(bridge, 'code_quality/suggest_refactoring', args),
  );
  // 7. validate_naming_conventions
  server.registerTool(
    'validate_naming_conventions',
    {
      description: 'Check GDScript files for naming convention violations',
      inputSchema: {
        path: z.string().optional().describe('Directory or file to check (default: entire project)'),
        style: z.enum(['snake_case', 'camelCase', 'PascalCase']).optional().describe('Expected naming style (default: snake_case per GDScript convention)'),
      },
    },
    async (args) => callGodot(bridge, 'code_quality/validate_naming_conventions', args),
  );
  // 8. generate_code_report
  server.registerTool(
    'generate_code_report',
    {
      description: 'Generate a comprehensive code quality report in the specified format',
      inputSchema: {
        format: z.enum(['json', 'html', 'markdown']).optional().describe('Report output format (default: markdown)'),
      },
    },
    async (args) => callGodot(bridge, 'code_quality/generate_code_report', args),
  );
}
//# sourceMappingURL=code_quality.js.map
