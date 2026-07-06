/**
 * Analysis tools - 4 tools for project and scene analysis
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
export function registerAnalysisTools(server: McpServer, bridge: GodotBridge): void {
  // 1. analyze_scene_complexity
  server.registerTool(
    'analyze_scene_complexity',
    {
      description: "Analyze a scene's complexity (node count, depth, resource usage)",
      inputSchema: {},
    },
    async (args) => callGodot(bridge, 'analysis/scene_complexity', args as Record<string, unknown>),
  );

  // 2. analyze_signal_flow
  server.registerTool(
    'analyze_signal_flow',
    {
      description: 'Analyze signal flow and connections in a scene',
      inputSchema: {},
    },
    async (args) => callGodot(bridge, 'analysis/signal_flow', args as Record<string, unknown>),
  );

  // 3. find_unused_resources
  server.registerTool(
    'find_unused_resources',
    {
      description: 'Find resources in the project that are not referenced by any scene or script',
      inputSchema: {},
    },
    async (args) => callGodot(bridge, 'analysis/unused_resources', args as Record<string, unknown>),
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
