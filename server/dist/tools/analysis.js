/**
 * Analysis tools - 4 tools for project and scene analysis
 */
import { callGodot } from '../server.js';
export function registerAnalysisTools(server, bridge) {
  // 1. analyze_scene_complexity
  server.registerTool(
    'analyze_scene_complexity',
    {
      description: "Analyze a scene's complexity (node count, depth, resource usage)",
      inputSchema: {},
    },
    async (args) => callGodot(bridge, 'analysis/scene_complexity', args),
  );
  // 2. analyze_signal_flow
  server.registerTool(
    'analyze_signal_flow',
    {
      description: 'Analyze signal flow and connections in a scene',
      inputSchema: {},
    },
    async (args) => callGodot(bridge, 'analysis/signal_flow', args),
  );
  // 3. find_unused_resources
  server.registerTool(
    'find_unused_resources',
    {
      description: 'Find resources in the project that are not referenced by any scene or script',
      inputSchema: {},
    },
    async (args) => callGodot(bridge, 'analysis/unused_resources', args),
  );
  // 4. get_project_statistics
  server.registerTool(
    'get_project_statistics',
    {
      description: 'Get project statistics (file counts, sizes, node types, script languages, etc.)',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'analysis/statistics'),
  );
}
//# sourceMappingURL=analysis.js.map
