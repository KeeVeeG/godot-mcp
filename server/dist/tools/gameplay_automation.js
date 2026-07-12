/**
 * Gameplay automation tools - 8 tools for automated gameplay testing
 */
import { callGodot } from '../server.js';
import { z, ScenePath, NodePath, Position3D, FlexiblePosition, Properties } from './shared-types.js';
export function registerGameplayAutomationTools(server, bridge) {
    // 1. simulate_gameplay_scenario
    server.registerTool('simulate_gameplay_scenario', {
        description: 'Run a sequence of gameplay actions (input, wait, check) as an automated scenario',
        inputSchema: {
            scenario: z
                .array(z
                .object({
                action: z.enum(['input', 'wait', 'move', 'click', 'assert']).describe("Action type: 'input', 'wait', 'move', 'click', 'assert'"),
                params: Properties.describe('Parameters for the action'),
                wait: z
                    .number()
                    .min(0)
                    .max(60000)
                    .refine((v) => Number.isFinite(v), 'Wait time must be a finite number')
                    .optional()
                    .describe('Wait time in ms after this step (max 60000)'),
            })
                .strict())
                .describe('Ordered list of gameplay actions to execute'),
        },
    }, async (args) => callGodot(bridge, 'simulate_gameplay_scenario', args));
    // 2. record_gameplay
    server.registerTool('record_gameplay', {
        description: 'Record gameplay for a duration, capturing input events and/or game state',
        inputSchema: {
            duration: z
                .number()
                .min(1)
                .max(300)
                .refine((v) => Number.isFinite(v), 'Duration must be a finite number')
                .optional()
                .default(10)
                .describe('Recording duration in seconds (default: 10)'),
            include_input: z.boolean().optional().default(true).describe('Record input events (default: true)'),
            include_state: z.boolean().optional().default(false).describe('Record game state snapshots (default: false)'),
        },
    }, async (args) => callGodot(bridge, 'record_gameplay', args));
    // 3. replay_gameplay
    server.registerTool('replay_gameplay', {
        description: 'Replay a previously recorded gameplay session',
        inputSchema: {
            recording_path: z
                .string()
                .min(1, 'Recording path is required')
                .refine((s) => s.startsWith('res://') || s.startsWith('user://'), "Recording path must start with 'res://' or 'user://'")
                .refine((s) => !s.includes('..'), 'Recording path must not contain path traversal (..)')
                .describe('Path to the recording file (res:// or user://)'),
            speed: z
                .number()
                .min(0.1)
                .max(10)
                .refine((v) => Number.isFinite(v), 'Speed must be a finite number')
                .optional()
                .default(1.0)
                .describe('Playback speed multiplier (default: 1.0)'),
        },
    }, async (args) => callGodot(bridge, 'replay_gameplay', args));
    // 4. create_test_character
    server.registerTool('create_test_character', {
        description: 'Create a test character in the scene at a specified position',
        inputSchema: {
            scene_path: ScenePath.describe('Path to the character scene to instantiate'),
            position: FlexiblePosition.optional().describe('World position [x, y] (2D) or [x, y, z] (3D)'),
        },
    }, async (args) => callGodot(bridge, 'create_test_character', args));
    // 5. delete_test_character
    server.registerTool('delete_test_character', {
        description: 'Delete test character(s) from the scene and clean up the internal tracking array. Can target a specific character by path or delete all tracked test characters.',
        inputSchema: {
            character_path: NodePath.optional().describe('Node path to a specific test character. If omitted, all test characters are deleted.'),
        },
    }, async (args) => callGodot(bridge, 'delete_test_character', args));
    // 6. navigate_character
    server.registerTool('navigate_character', {
        description: 'Move a character to a target position using direct movement or pathfinding',
        inputSchema: {
            character_path: NodePath.describe('Node path to the character to navigate'),
            target: Position3D.describe('Target position [x, y, z]'),
            method: z
                .preprocess((v) => (typeof v === 'string' ? v.toLowerCase() : v), z.enum(['direct', 'pathfind']))
                .optional()
                .default('direct')
                .describe('Navigation method: direct or pathfind (default: direct)'),
        },
    }, async (args) => callGodot(bridge, 'navigate_character', args));
    // 7. assert_game_state
    server.registerTool('assert_game_state', {
        description: 'Assert multiple game state conditions simultaneously',
        inputSchema: {
            conditions: z
                .array(z
                .object({
                path: z.string().describe('Node path'),
                property: z.string().describe('Property name to check'),
                expected: z.unknown().describe('Expected value'),
                operator: z.enum(['==', '!=', '>', '<', '>=', '<=', 'contains']).optional().describe('Comparison operator: ==, !=, >, <, >=, <=, contains'),
            })
                .strict())
                .describe('List of conditions that must all pass'),
        },
    }, async (args) => callGodot(bridge, 'assert_game_state', args));
    // 8. wait_for_game_event
    server.registerTool('wait_for_game_event', {
        description: 'Wait for a specific game event (signal, node creation, property change) with timeout',
        inputSchema: {
            event: z
                .string()
                .regex(/^(signal|node|property):/, "Event must start with 'signal:', 'node:', or 'property:' (e.g. 'signal:Player:moved')")
                .describe("Event to wait for. Use prefix format: 'signal:NodePath:SignalName', 'node:NodePath', or 'property:NodePath:PropName:ExpectedValue'"),
            timeout: z.number().int().min(1).max(30000).optional().default(5000).describe('Timeout in milliseconds (default: 5000)'),
        },
    }, async (args) => callGodot(bridge, 'wait_for_game_event', args));
}
//# sourceMappingURL=gameplay_automation.js.map