/**
 * Gameplay automation tools - 7 tools for automated gameplay testing
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, ScenePath, NodePath, Position3D, Properties } from './shared-types.js';

export function registerGameplayAutomationTools(server: McpServer, bridge: GodotBridge): void {
  // 1. simulate_gameplay_scenario
  server.registerTool(
    'simulate_gameplay_scenario',
    {
      description: 'Run a sequence of gameplay actions (input, wait, check) as an automated scenario',
      inputSchema: {
        scenario: z
          .array(
            z.object({
              action: z.string().describe("Action type: 'input', 'wait', 'move', 'click', 'assert'"),
              params: Properties.describe('Parameters for the action'),
              wait: z.number().optional().describe('Wait time in ms after this step'),
            }),
          )
          .describe('Ordered list of gameplay actions to execute'),
      },
    },
    async (args) => callGodot(bridge, 'simulate_gameplay_scenario', args as Record<string, unknown>),
  );

  // 2. record_gameplay
  server.registerTool(
    'record_gameplay',
    {
      description: 'Record gameplay for a duration, capturing input events and/or game state',
      inputSchema: {
        duration: z.number().min(1).max(300).optional().default(10).describe('Recording duration in seconds (default: 10)'),
        include_input: z.boolean().optional().default(true).describe('Record input events (default: true)'),
        include_state: z.boolean().optional().default(false).describe('Record game state snapshots (default: false)'),
      },
    },
    async (args) => callGodot(bridge, 'record_gameplay', args as Record<string, unknown>),
  );

  // 3. replay_gameplay
  server.registerTool(
    'replay_gameplay',
    {
      description: 'Replay a previously recorded gameplay session',
      inputSchema: {
        recording_path: z.string().describe('Path to the recording file'),
        speed: z.number().min(0.1).max(10).optional().default(1.0).describe('Playback speed multiplier (default: 1.0)'),
      },
    },
    async (args) => callGodot(bridge, 'replay_gameplay', args as Record<string, unknown>),
  );

  // 4. create_test_character
  server.registerTool(
    'create_test_character',
    {
      description: 'Create a test character in the scene at a specified position',
      inputSchema: {
        scene_path: ScenePath.describe('Path to the character scene to instantiate'),
        position: Position3D.optional().describe('World position [x, y, z]'),
      },
    },
    async (args) => callGodot(bridge, 'create_test_character', args as Record<string, unknown>),
  );

  // 5. navigate_character
  server.registerTool(
    'navigate_character',
    {
      description: 'Move a character to a target position using direct movement or pathfinding',
      inputSchema: {
        character_path: NodePath,
        target: Position3D.describe('Target position [x, y, z]'),
        method: z.enum(['direct', 'pathfind']).optional().default('direct').describe('Navigation method (default: direct)'),
      },
    },
    async (args) => callGodot(bridge, 'navigate_character', args as Record<string, unknown>),
  );

  // 6. assert_game_state
  server.registerTool(
    'assert_game_state',
    {
      description: 'Assert multiple game state conditions simultaneously',
      inputSchema: {
        conditions: z
          .array(
            z.object({
              path: z.string().describe('Node path'),
              property: z.string().describe('Property name to check'),
              expected: z.unknown().describe('Expected value'),
              operator: z.string().optional().describe('Comparison operator: ==, !=, >, <, >=, <=, contains'),
            }),
          )
          .describe('List of conditions that must all pass'),
      },
    },
    async (args) => callGodot(bridge, 'assert_game_state', args as Record<string, unknown>),
  );

  // 7. wait_for_game_event
  server.registerTool(
    'wait_for_game_event',
    {
      description: 'Wait for a specific game event (signal, node creation, property change) with timeout',
      inputSchema: {
        event: z.string().describe("Event to wait for. Use prefix format: 'signal:NodePath:SignalName', 'node:NodePath', or 'property:NodePath:PropName:ExpectedValue'"),
        timeout: z.number().int().min(1).max(30000).optional().default(5000).describe('Timeout in milliseconds (default: 5000)'),
      },
    },
    async (args) => callGodot(bridge, 'wait_for_game_event', args as Record<string, unknown>),
  );
}
