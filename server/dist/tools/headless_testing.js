/**
 * Headless testing tools - 5 tools for CI/CD testing
 */
import { callGodot } from '../server.js';
import { z, ScenePath, ScriptPath, FilePath } from './shared-types.js';
export function registerHeadlessTestingTools(server, bridge) {
  // 1. run_headless_test
  server.registerTool(
    'run_headless_test',
    {
      description: 'Run a single test script in headless mode for CI/CD',
      inputSchema: {
        test_script: ScriptPath.describe('Path to the test script to run'),
        timeout: z.number().int().min(1).max(300).optional().describe('Timeout in seconds (default: 60)'),
      },
    },
    async (args) => callGodot(bridge, 'run_headless_test', args),
  );
  // 2. run_test_suite
  server.registerTool(
    'run_test_suite',
    {
      description: 'Run a full test suite from a directory',
      inputSchema: {
        suite_path: FilePath.describe('Path to the test suite directory'),
        parallel: z.boolean().optional().describe('Run tests in parallel (default: false)'),
      },
    },
    async (args) => callGodot(bridge, 'run_test_suite', args),
  );
  // 3. generate_test_report
  server.registerTool(
    'generate_test_report',
    {
      description: 'Generate a test report in the specified format from accumulated results',
      inputSchema: {
        format: z.enum(['json', 'html', 'junit']).optional().describe('Report format (default: json)'),
      },
    },
    async (args) => callGodot(bridge, 'generate_test_report', args),
  );
  // 4. validate_project
  server.registerTool(
    'validate_project',
    {
      description: 'Validate the project for common issues (missing resources, broken references, script errors)',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'validate_project'),
  );
  // 5. run_performance_benchmark
  server.registerTool(
    'run_performance_benchmark',
    {
      description: 'Run a performance benchmark on a scene measuring FPS, frame time, memory, and draw calls',
      inputSchema: {
        scene_path: ScenePath.describe('Path to the scene to benchmark'),
        duration: z.number().int().min(1).max(120).optional().describe('Benchmark duration in seconds (default: 10)'),
        metrics: z.array(z.string()).optional().describe('Specific metrics to collect (default: all)'),
      },
    },
    async (args) => callGodot(bridge, 'run_performance_benchmark', args),
  );
}
//# sourceMappingURL=headless_testing.js.map
