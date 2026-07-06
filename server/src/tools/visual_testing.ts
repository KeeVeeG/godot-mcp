/**
 * Visual testing tools - 6 tools for visual regression testing
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, Name, FilePath } from './shared-types.js';

export function registerVisualTestingTools(server: McpServer, bridge: GodotBridge): void {
  // 1. take_screenshot_with_context
  server.registerTool(
    'take_screenshot_with_context',
    {
      description: 'Take a screenshot with scene context metadata (node tree, properties of specified nodes)',
      inputSchema: {
        name: Name.describe('Name for this screenshot (used as filename, e.g. "main_menu")'),
        include_nodes: z.array(z.string()).optional().describe('Node paths to include property data for (requires include_props=true)'),
        include_props: z.boolean().optional().default(false).describe('Whether to include property snapshots for listed include_nodes (default: false)'),
      },
    },
    async (args) => callGodot(bridge, 'take_screenshot_with_context', args as Record<string, unknown>),
  );

  // 2. compare_screenshots
  server.registerTool(
    'compare_screenshots',
    {
      description: 'Compare two screenshots pixel-by-pixel and return a diff result with mismatch percentage',
      inputSchema: {
        baseline: FilePath.describe('Path to the baseline screenshot'),
        current: FilePath.describe('Path to the current screenshot'),
        threshold: z.number().min(0).max(1).optional().default(0.01).describe('Pixel difference threshold 0-1 (default: 0.01)'),
      },
    },
    async (args) => callGodot(bridge, 'compare_screenshots', args as Record<string, unknown>),
  );

  // 3. assert_visual_match
  server.registerTool(
    'assert_visual_match',
    {
      description: 'Assert that a screenshot matches a baseline within a threshold - pass/fail result',
      inputSchema: {
        name: Name.describe('Screenshot name to check — must match a name previously used with take_screenshot_with_context'),
        baseline: FilePath.describe('Path or name of the baseline screenshot (resolves against baselines directory if not a full path)'),
        threshold: z.number().min(0).max(1).optional().default(0.01).describe('Acceptable difference threshold (default: 0.01)'),
      },
    },
    async (args) => callGodot(bridge, 'assert_visual_match', args as Record<string, unknown>),
  );

  // 4. record_visual_regression
  server.registerTool(
    'record_visual_regression',
    {
      description: 'Record multiple frames over time for visual regression testing',
      inputSchema: {
        test_name: Name.describe('Name for this recording session'),
        frames: z.number().int().min(1).max(100).optional().default(10).describe('Number of frames to capture (default: 10)'),
        interval: z.number().min(0.1).max(10).optional().default(0.5).describe('Seconds between captures (default: 0.5)'),
      },
    },
    async (args) => callGodot(bridge, 'record_visual_regression', args as Record<string, unknown>),
  );

  // 5. get_visual_diff_report
  server.registerTool(
    'get_visual_diff_report',
    {
      description: 'Get the aggregated visual regression report from all assert_visual_match calls in this session',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'get_visual_diff_report'),
  );

  // 6. set_visual_baseline
  server.registerTool(
    'set_visual_baseline',
    {
      description: 'Set or update a visual baseline for future comparisons',
      inputSchema: {
        name: Name.describe('Baseline name identifier'),
        screenshot_path: FilePath.describe('Path to the screenshot to use as baseline'),
      },
    },
    async (args) => callGodot(bridge, 'set_visual_baseline', args as Record<string, unknown>),
  );
}
