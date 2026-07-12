/**
 * Testing tools - 6 tools for game testing
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, NodePath, PropertyName, PropertyValue } from './shared-types.js';

export function registerTestingTools(server: McpServer, bridge: GodotBridge): void {
  // 1. run_test_scenario
  server.registerTool(
    'run_test_scenario',
    {
      description: 'Run a multi-step test scenario against the running game',
      inputSchema: {
        name: z.string().optional().default('Unnamed Scenario').describe('Scenario name (default: "Unnamed Scenario")'),
        steps: z
          .array(
            z
              .object({
                type: z.enum(['add_node', 'delete_node', 'set_property', 'assert_node_state', 'connect_signal', 'wait']).describe('Step type'),
                params: z.record(z.unknown()).optional().describe('Parameters for this step'),
              })
              .catchall(z.unknown()),
          )
          .min(1, 'Steps array must have at least one step')
          .describe('Ordered test steps'),
      },
    },
    async (args) => callGodot(bridge, 'testing/run_scenario', args as Record<string, unknown>),
  );

  // 2. assert_node_state
  server.registerTool(
    'assert_node_state',
    {
      description: 'Assert that a node property matches an expected value',
      inputSchema: {
        path: NodePath.describe('Node path in the running game'),
        property: PropertyName.describe('Property name to check'),
        expected: PropertyValue.describe('Expected value'),
        operator: z.string().optional().default('==').describe("Comparison operator: ==, !=, >, <, >=, <=, contains (default: '==')"),
      },
    },
    async (args) => callGodot(bridge, 'testing/assert_state', args as Record<string, unknown>),
  );

  // 3. assert_screen_text
  server.registerTool(
    'assert_screen_text',
    {
      description: 'Assert that specific text appears on screen (OCR or UI element check)',
      inputSchema: {
        text: z.string().describe('Text that should appear on screen'),
        should_exist: z.boolean().optional().default(true).describe('Whether text should be present (true) or absent (false) (default: true)'),
      },
    },
    async (args) => callGodot(bridge, 'testing/assert_screen_text', args as Record<string, unknown>),
  );

  // 4. run_stress_test
  server.registerTool(
    'run_stress_test',
    {
      description: 'Run a stress test on the game (spawn entities, measure performance)',
      inputSchema: {
        type: z.string().optional().default('Node2D').describe('Node type to spawn (default: Node2D)'),
        count: z.number().int().min(0, 'Count must be non-negative').optional().default(100).describe('Number of entities to spawn (default: 100)'),
        parent_path: z.string().optional().describe('Parent node path for spawned entities'),
        properties: z.record(z.unknown()).optional().describe('Properties to set on each spawned entity'),
      },
    },
    async (args) => callGodot(bridge, 'testing/stress_test', args as Record<string, unknown>),
  );

  // 5. get_test_report
  server.registerTool(
    'get_test_report',
    {
      description: 'Get aggregated results of all test runs in this session',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'testing/get_report'),
  );

  // 6. clear_test_report
  server.registerTool(
    'clear_test_report',
    {
      description: 'Clear all accumulated test results and reset session state',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'testing/clear_report'),
  );
}
