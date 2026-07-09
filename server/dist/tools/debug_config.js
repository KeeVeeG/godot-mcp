/**
 * Debug configuration tools - 6 tools for debug and logging settings
 */
import { callGodot } from '../server.js';
import { z } from './shared-types.js';
export function registerDebugConfigTools(server, bridge) {
    // 1. get_debug_settings
    server.registerTool('get_debug_settings', {
        description: 'Get all debug settings (remote debug, profilers, error handling, logging)',
        inputSchema: {},
    }, async () => callGodot(bridge, 'debug_config/get_settings'));
    // 2. set_remote_debug
    server.registerTool('set_remote_debug', {
        description: 'Configure remote debugging connection',
        inputSchema: {
            enabled: z.boolean().describe('Enable/disable remote debugging'),
            host: z.string().optional().default('127.0.0.1').describe("Debug host address (default: '127.0.0.1')"),
            port: z.number().int().min(1).max(65535).optional().default(6007).describe('Debug port (default: 6007)'),
        },
    }, async (args) => callGodot(bridge, 'debug_config/set_remote_debug', args));
    // 3. set_profiler_settings
    server.registerTool('set_profiler_settings', {
        description: 'Configure profiler limits. Note: profiler on/off toggles (CPU, GPU, etc.) are controlled by the editor debugger panel during gameplay and cannot be set via ProjectSettings.',
        inputSchema: {
            max_functions: z.number().int().optional().describe('Max functions tracked by script profiler (range: 16-512)'),
            max_timestamp_query_elements: z.number().int().optional().describe('Max timestamp query elements (default: 256)'),
            cpu: z.boolean().optional().describe('Not configurable here — controlled by the editor debugger panel'),
            gpu: z.boolean().optional().describe('Not configurable here — controlled by the editor debugger panel'),
            memory: z.boolean().optional().describe('Not configurable here — controlled by the editor debugger panel'),
            network: z.boolean().optional().describe('Not configurable here — controlled by the editor debugger panel'),
        },
    }, async (args) => callGodot(bridge, 'debug_config/set_profilers', args));
    // 4. set_error_handling
    server.registerTool('set_error_handling', {
        description: 'Configure how the editor handles errors during gameplay. Note: Godot 4.x has no "break on warning" mechanism — warnings are compile-time only (IGNORE/WARN/ERROR levels in ProjectSettings). To treat warnings as errors that prevent compilation, use set_project_setting on debug/gdscript/warnings/<name> keys.',
        inputSchema: {
            break_on_error: z.boolean().optional().describe('Break into debugger on runtime error'),
        },
    }, async (args) => callGodot(bridge, 'debug_config/set_error_handling', args));
    // 5. get_editor_log
    server.registerTool('get_editor_log', {
        description: 'Get entries from the editor log, optionally filtered by type',
        inputSchema: {
            filter: z.enum(['error', 'warning', 'info']).optional().describe('Filter by message type'),
            limit: z.number().int().min(1).max(500).optional().default(50).describe('Max entries to return (default 50)'),
        },
    }, async (args) => callGodot(bridge, 'debug_config/get_log', args));
    // 6. clear_editor_log
    server.registerTool('clear_editor_log', {
        description: 'Clear the editor output log',
        inputSchema: {},
    }, async () => callGodot(bridge, 'debug_config/clear_log'));
}
//# sourceMappingURL=debug_config.js.map