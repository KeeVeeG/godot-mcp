/**
 * Debug configuration tools - 6 tools for debug and logging settings
 */
import { callGodot } from '../server.js';
import { z, errorResult } from './shared-types.js';
function validateNoExtraKeys(args, allowedKeys, toolName) {
    const extraKeys = Object.keys(args).filter((k) => !allowedKeys.includes(k));
    if (extraKeys.length > 0) {
        return errorResult(`${toolName}: unknown parameter(s): ${extraKeys.join(', ')}. Allowed: ${allowedKeys.join(', ')}`);
    }
    return null;
}
export function registerDebugConfigTools(server, bridge) {
    // 1. get_debug_settings
    server.registerTool('get_debug_settings', {
        description: 'Get all debug settings (remote debug, profilers, error handling, logging)',
        inputSchema: {},
    }, async () => callGodot(bridge, 'debug_config/get_settings'));
    // 2. set_remote_debug
    server.registerTool('set_remote_debug', {
        description: 'Configure remote debugging connection',
        inputSchema: z
            .object({
            enabled: z.boolean().describe('Enable/disable remote debugging'),
            host: z.string().min(1, 'Host must not be empty').max(253, 'Host exceeds DNS maximum length').optional().default('127.0.0.1').describe("Debug host address (default: '127.0.0.1')"),
            port: z.number().int().min(1).max(65535).optional().default(6007).describe('Debug port (default: 6007)'),
        })
            .passthrough(),
    }, async (args) => {
        const err = validateNoExtraKeys(args, ['enabled', 'host', 'port'], 'set_remote_debug');
        if (err)
            return err;
        return callGodot(bridge, 'debug_config/set_remote_debug', args);
    });
    // 3. set_profiler_settings
    server.registerTool('set_profiler_settings', {
        description: 'Configure profiler limits. Note: profiler on/off toggles (CPU, GPU, etc.) are controlled by the editor debugger panel during gameplay and cannot be set via ProjectSettings.',
        inputSchema: z
            .object({
            max_functions: z.number().int().min(16).max(16384).optional().describe('Max functions tracked by script profiler (Godot default: 16384)'),
            max_timestamp_query_elements: z.number().int().min(1).optional().describe('Max timestamp query elements (default: 256)'),
            cpu: z.boolean().optional().describe('Not configurable here — controlled by the editor debugger panel'),
            gpu: z.boolean().optional().describe('Not configurable here — controlled by the editor debugger panel'),
            memory: z.boolean().optional().describe('Not configurable here — controlled by the editor debugger panel'),
            network: z.boolean().optional().describe('Not configurable here — controlled by the editor debugger panel'),
        })
            .passthrough(),
    }, async (args) => {
        const err = validateNoExtraKeys(args, ['max_functions', 'max_timestamp_query_elements', 'cpu', 'gpu', 'memory', 'network'], 'set_profiler_settings');
        if (err)
            return err;
        return callGodot(bridge, 'debug_config/set_profilers', args);
    });
    // 4. set_error_handling
    server.registerTool('set_error_handling', {
        description: 'Configure how the editor handles errors during gameplay. Note: Godot 4.x has no "break on warning" mechanism — warnings are compile-time only (IGNORE/WARN/ERROR levels in ProjectSettings). To treat warnings as errors that prevent compilation, use set_project_setting on debug/gdscript/warnings/<name> keys.',
        inputSchema: z
            .object({
            break_on_error: z.boolean().optional().describe('Break into debugger on runtime error'),
            break_on_warning: z.boolean().optional().describe('Break into debugger on warnings (not persistable — controlled by editor debugger)'),
        })
            .passthrough(),
    }, async (args) => {
        const err = validateNoExtraKeys(args, ['break_on_error', 'break_on_warning'], 'set_error_handling');
        if (err)
            return err;
        return callGodot(bridge, 'debug_config/set_error_handling', args);
    });
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