/**
 * Debugging tools - 8 tools for game debugging
 */
import { callGodot } from '../server.js';
import { z, ScriptPath, GDScriptCode } from './shared-types.js';
export function registerDebuggingTools(server, bridge) {
    // 1. set_breakpoint
    server.registerTool('set_breakpoint', {
        description: 'Set a breakpoint in a GDScript file at a specific line, optionally with a condition',
        inputSchema: {
            script_path: ScriptPath,
            line: z.number().int().min(1).describe('Line number to set breakpoint on'),
            condition: z.string().optional().describe('Optional condition expression - breakpoint only triggers when true'),
        },
    }, async (args) => callGodot(bridge, 'set_breakpoint', args));
    // 2. remove_breakpoint
    server.registerTool('remove_breakpoint', {
        description: 'Remove a breakpoint from a GDScript file at a specific line',
        inputSchema: {
            script_path: ScriptPath,
            line: z.number().int().min(1).describe('Line number of the breakpoint to remove'),
        },
    }, async (args) => callGodot(bridge, 'remove_breakpoint', args));
    // 3. list_breakpoints
    server.registerTool('list_breakpoints', {
        description: 'List all active breakpoints across all scripts',
        inputSchema: {},
    }, async () => callGodot(bridge, 'list_breakpoints'));
    // 4. get_call_stack
    server.registerTool('get_call_stack', {
        description: 'Get the current call stack with local variables when the game is paused at a breakpoint',
        inputSchema: {},
    }, async () => callGodot(bridge, 'get_call_stack'));
    // 5. evaluate_expression
    server.registerTool('evaluate_expression', {
        description: 'Evaluate a GDScript expression in the editor or running game context',
        inputSchema: {
            expression: GDScriptCode.describe('GDScript expression to evaluate'),
            context: z.enum(['editor', 'game']).optional().default('editor').describe('Context to evaluate in (default: editor)'),
        },
    }, async (args) => callGodot(bridge, 'evaluate_expression', args));
    // 6. step_over
    server.registerTool('step_over', {
        description: 'Step over the current line when paused at a breakpoint',
        inputSchema: {},
    }, async () => callGodot(bridge, 'step_over'));
    // 7. step_into
    server.registerTool('step_into', {
        description: 'Step into the current function call when paused at a breakpoint',
        inputSchema: {},
    }, async () => callGodot(bridge, 'step_into'));
    // 8. continue_execution
    server.registerTool('continue_execution', {
        description: 'Continue execution when paused at a breakpoint',
        inputSchema: {},
    }, async () => callGodot(bridge, 'continue_execution'));
}
//# sourceMappingURL=debugging.js.map