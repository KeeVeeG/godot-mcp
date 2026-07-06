/**
 * Performance optimization tools - 6 tools for runtime performance analysis and optimization
 */
import { callGodot } from '../server.js';
import { z, ScenePath } from './shared-types.js';
export function registerPerformanceOptimizationTools(server, bridge) {
  // 1. analyze_performance
  server.registerTool(
    'analyze_performance',
    {
      description: 'Analyze performance of the current or specified scene over a duration',
      inputSchema: {
        scene_path: ScenePath.optional().describe('Path to the scene to analyze (defaults to current scene)'),
        duration: z.number().int().min(1).max(60).optional().describe('Analysis duration in seconds (default: 5)'),
      },
    },
    async (args) => callGodot(bridge, 'analyze_performance', args),
  );
  // 2. suggest_optimizations
  server.registerTool(
    'suggest_optimizations',
    {
      description: 'Analyze a scene and suggest performance optimizations',
      inputSchema: {
        scene_path: ScenePath.optional().describe('Path to the scene to analyze (defaults to current scene)'),
      },
    },
    async (args) => callGodot(bridge, 'suggest_optimizations', args),
  );
  // 3. auto_optimize
  server.registerTool(
    'auto_optimize',
    {
      description: 'Automatically apply performance optimizations to achieve a target FPS or quality level',
      inputSchema: {
        target_fps: z.number().int().min(15).max(240).optional().describe('Target frame rate (default: 60)'),
        quality_level: z.enum(['low', 'medium', 'high']).optional().describe('Target quality level (default: medium)'),
      },
    },
    async (args) => callGodot(bridge, 'auto_optimize', args),
  );
  // 4. batch_draw_calls
  server.registerTool(
    'batch_draw_calls',
    {
      description: 'Analyze and optimize draw calls in a scene to reduce rendering overhead',
      inputSchema: {
        scene_path: ScenePath,
      },
    },
    async (args) => callGodot(bridge, 'batch_draw_calls', args),
  );
  // 5. optimize_textures
  server.registerTool(
    'optimize_textures',
    {
      description: 'Optimize textures in a directory by resizing and compressing them',
      inputSchema: {
        path: z.string().optional().describe('Directory path to scan for textures (default: res://assets/)'),
        max_size: z.number().int().min(64).max(4096).optional().describe('Maximum texture dimension in pixels (default: 2048)'),
      },
    },
    async (args) => callGodot(bridge, 'optimize_textures', args),
  );
  // 6. profile_loading_times
  server.registerTool(
    'profile_loading_times',
    {
      description: 'Profile resource loading times and identify bottlenecks',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'profile_loading_times'),
  );
}
//# sourceMappingURL=performance_optimization.js.map
