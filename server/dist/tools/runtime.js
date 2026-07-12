/**
 * Runtime tools — 23 tools for game runtime interaction
 */
import { callGodot } from '../server.js';
import { z, NodePath, ScriptPath, Position3D, PositiveNumber, NonNegativeNumber, Timeout, GDScriptCode, FilePath } from './shared-types.js';
export function registerRuntimeTools(server, bridge) {
    // 1. get_game_scene_tree — {} -> runtime hierarchy
    server.registerTool('get_game_scene_tree', {
        description: '🔴 Game must be running. Get the scene tree of the running game (runtime state)',
        inputSchema: {},
    }, async () => callGodot(bridge, 'runtime/get_scene_tree'));
    // 2. get_game_node_properties — {path: string} -> properties
    server.registerTool('get_game_node_properties', {
        description: '🔴 Game must be running. Get all properties of a node in the running game',
        inputSchema: {
            path: NodePath.describe('Node path in the game tree'),
            properties: z.array(z.string()).optional().describe('Specific property names to return (defaults to common properties)'),
        },
    }, async (args) => callGodot(bridge, 'runtime/get_node_properties', args));
    // 3. set_game_node_property — {path: string, property: string, value: any} -> success
    server.registerTool('set_game_node_property', {
        description: '🔴 Game must be running. Set a property on a node in the running game',
        inputSchema: {
            path: NodePath.describe('Node path in the game tree'),
            property: z.string().describe('Property name to set'),
            value: z.unknown().describe('New value for the property'),
        },
    }, async (args) => callGodot(bridge, 'runtime/set_node_property', args));
    // 4. execute_game_script — {code: string} -> result
    server.registerTool('execute_game_script', {
        description: '🔴 Game must be running. Execute a GDScript snippet in the running game context',
        inputSchema: {
            code: GDScriptCode,
        },
    }, async (args) => callGodot(bridge, 'runtime/execute_script', args));
    // 5. capture_frames — {count?: number, interval?: number} -> frame paths
    server.registerTool('capture_frames', {
        description: '🔴 Game must be running. Capture frames from the running game viewport as PNG files',
        inputSchema: {
            count: z.number().int().min(1).max(60).optional().default(1).describe('Number of frames to capture (default: 1)'),
            interval: NonNegativeNumber.optional().describe('Interval between captures in seconds'),
        },
    }, async (args) => callGodot(bridge, 'runtime/capture_frames', args));
    // 6. monitor_properties — {path: string, properties: string[], duration?: number} -> timeline data
    server.registerTool('monitor_properties', {
        description: '🔴 Game must be running. Monitor specific properties on a game node for changes over time',
        inputSchema: {
            path: NodePath.describe('Node path to monitor'),
            properties: z.array(z.string()).min(1).describe('Property names to monitor'),
            duration: Timeout.describe('Monitoring duration in seconds'),
        },
    }, async (args) => callGodot(bridge, 'runtime/monitor_properties', args));
    // 7. start_recording — {} -> success
    server.registerTool('start_recording', {
        description: '🔴 Game must be running. Start recording game state changes',
        inputSchema: {},
    }, async () => callGodot(bridge, 'runtime/start_recording'));
    // 8. stop_recording — {} -> recording data
    server.registerTool('stop_recording', {
        description: '🔴 Game must be running. Stop recording and return the recorded game state data',
        inputSchema: {},
    }, async () => callGodot(bridge, 'runtime/stop_recording'));
    // 9. replay_recording — {speed?: number} -> success
    server.registerTool('replay_recording', {
        description: '🔴 Game must be running. Replay a previously recorded game session',
        inputSchema: {
            speed: PositiveNumber.optional().default(1.0).describe('Playback speed multiplier (default: 1.0)'),
        },
    }, async (args) => callGodot(bridge, 'runtime/replay_recording', args));
    // 10. find_nodes_by_script — {script_path: string} -> node paths
    server.registerTool('find_nodes_by_script', {
        description: '🔴 Game must be running. Find all nodes in the game that use a specific script',
        inputSchema: {
            script_path: ScriptPath.describe("Script file path to search for (e.g. 'res://scripts/enemy.gd')"),
        },
    }, async (args) => callGodot(bridge, 'runtime/find_by_script', args));
    // 11. get_autoload — {name: string} -> autoload properties
    server.registerTool('get_autoload', {
        description: '🔴 Game must be running. Get properties of an autoload singleton from the running game',
        inputSchema: {
            name: z.string().describe('Autoload singleton name'),
        },
    }, async (args) => callGodot(bridge, 'runtime/get_autoload', args));
    // 12. batch_get_properties — {paths: string[], properties: string[]} -> batch results
    server.registerTool('batch_get_properties', {
        description: '🔴 Game must be running. Get multiple properties from multiple nodes in one call',
        inputSchema: {
            paths: z.array(z.string()).min(1).describe('List of node paths to query'),
            properties: z.array(z.string()).min(1).describe('Property names to read from each node'),
        },
    }, async (args) => callGodot(bridge, 'runtime/batch_get_properties', args));
    // 13. find_ui_elements — {filter?: {type?: string, text?: string, name?: string}} -> UI elements
    server.registerTool('find_ui_elements', {
        description: '🔴 Game must be running. Find UI elements in the running game by type, text, or name',
        inputSchema: {
            filter: z
                .object({
                type: z.string().optional().describe("Control type to filter by (e.g. 'Button', 'Label')"),
                text: z.string().optional().describe('Text content to search for'),
                name: z.string().optional().describe('Node name to search for (substring match)'),
            })
                .optional()
                .describe('Filter criteria for UI element search'),
        },
    }, async (args) => callGodot(bridge, 'runtime/find_ui_elements', args));
    // 14. click_button_by_text — {text: string, timeout?: number} -> success
    server.registerTool('click_button_by_text', {
        description: '🔴 Game must be running. Find and click a button by its text content',
        inputSchema: {
            text: z.string().describe('Button text to find and click'),
            timeout: Timeout.default(5.0).describe('Timeout in seconds (default: 5.0)'),
        },
    }, async (args) => callGodot(bridge, 'runtime/click_button', args));
    // 15. wait_for_node — {path: string, timeout?: number} -> success
    server.registerTool('wait_for_node', {
        description: '🔴 Game must be running. Wait for a node to appear in the running game tree',
        inputSchema: {
            path: NodePath.describe('Node path to wait for'),
            timeout: Timeout.default(5.0).describe('Timeout in seconds (default: 5.0)'),
        },
    }, async (args) => callGodot(bridge, 'runtime/wait_for_node', args));
    // 16. find_nearby_nodes — {position: [number,number,number], radius: number} -> nodes
    server.registerTool('find_nearby_nodes', {
        description: '🔴 Game must be running. Find nodes within a radius of a world position',
        inputSchema: {
            position: Position3D,
            radius: PositiveNumber.describe('Search radius'),
        },
    }, async (args) => callGodot(bridge, 'runtime/find_nearby', args));
    // 17. navigate_to — {path: string, target: [number,number,number]} -> success
    server.registerTool('navigate_to', {
        description: '🔴 Game must be running. Navigate a node to a target position using pathfinding',
        inputSchema: {
            path: NodePath.describe('Node path to navigate (must have NavigationAgent3D)'),
            target: Position3D.describe('Target position [x, y, z]'),
        },
    }, async (args) => callGodot(bridge, 'runtime/navigate_to', args));
    // 18. move_to — {path: string, target: [number,number,number]} -> success
    server.registerTool('move_to', {
        description: '🔴 Game must be running. Directly move a node to a target position',
        inputSchema: {
            path: NodePath.describe('Node path to move'),
            target: Position3D.describe('Target position [x, y, z]'),
        },
    }, async (args) => callGodot(bridge, 'runtime/move_to', args));
    // 19. watch_signals — {path: string, signals: string[], duration?: number} -> signal log
    server.registerTool('watch_signals', {
        description: '🔴 Game must be running. Watch for signal emissions from a game node',
        inputSchema: {
            path: NodePath.describe('Node path to watch'),
            signals: z.array(z.string()).min(1).describe('Signal names to watch for'),
            duration: Timeout.describe('How long to watch in seconds'),
        },
    }, async (args) => callGodot(bridge, 'runtime/watch_signals', args));
    // 20. unwatch_signals — {path: string, signals?: string[]} -> success
    server.registerTool('unwatch_signals', {
        description: '🔴 Game must be running. Stop watching signals on a game node that was previously being monitored',
        inputSchema: {
            path: NodePath.describe('Node path to stop watching'),
            signals: z.array(z.string()).optional().describe('Specific signal names to stop watching (omit to stop all)'),
        },
    }, async (args) => callGodot(bridge, 'runtime/unwatch_signals', args));
    // 21. delete_captured_frames — {paths?: string[]} -> success
    server.registerTool('delete_captured_frames', {
        description: '🔴 Game must be running. Delete captured frames from disk that were previously saved by capture_frames',
        inputSchema: {
            paths: z.array(FilePath).optional().describe('Specific file paths to delete (omit or pass empty array to delete all captured frames)'),
        },
    }, async (args) => callGodot(bridge, 'runtime/delete_captured_frames', args));
    // 22. stop_monitoring — {path: string} -> monitoring data
    server.registerTool('stop_monitoring', {
        description: '🔴 Game must be running. Stop an active property monitoring session that was started by monitor_properties',
        inputSchema: {
            path: NodePath.describe('Node path whose monitoring session to stop'),
        },
    }, async (args) => callGodot(bridge, 'runtime/stop_monitoring', args));
    // 23. batch_set_properties — {nodes: {path: string, properties: Record<string, unknown>}[]} -> success
    server.registerTool('batch_set_properties', {
        description: '🔴 Game must be running. Set multiple properties on multiple nodes in one call',
        inputSchema: {
            nodes: z
                .array(z.object({
                path: NodePath.describe('Node path to modify'),
                properties: z.record(z.unknown()).describe('Dictionary of property_name: value pairs to set'),
            }))
                .min(1)
                .describe('Array of node change descriptors (at least 1 required)'),
        },
    }, async (args) => callGodot(bridge, 'runtime/batch_set_properties', args));
    // 24. get_monitor_results — {monitor_id: number} -> monitor data for a completed session
    server.registerTool('get_monitor_results', {
        description: 'Get aggregated results for a completed monitor_properties session by its monitor_id',
        inputSchema: {
            monitor_id: z.number().int().describe('Monitor ID returned by monitor_properties'),
        },
    }, async (args) => callGodot(bridge, 'runtime/get_monitor_results', args));
}
//# sourceMappingURL=runtime.js.map