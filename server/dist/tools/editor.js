/**
 * Editor tools — 9 tools for editor interaction
 */
import { callGodot } from '../server.js';
import { z, NodePath, GDScriptCode } from './shared-types.js';
export function registerEditorTools(server, bridge) {
    // 1. get_editor_errors — {} -> errors with stack traces
    server.registerTool('get_editor_errors', {
        description: 'Validate all GDScripts in the current scene tree and return compilation errors',
        inputSchema: {},
    }, async () => callGodot(bridge, 'editor/get_errors'));
    // 2. get_editor_screenshot — {path?: string} -> base64 image
    server.registerTool('get_editor_screenshot', {
        description: 'Take a screenshot of the Godot editor window',
        inputSchema: {
            path: z.string().optional().describe('Custom save path for the screenshot'),
        },
    }, async (args) => callGodot(bridge, 'editor/get_screenshot', args));
    // 3. get_game_screenshot — {path?: string} -> base64 image
    server.registerTool('get_game_screenshot', {
        description: 'Take a screenshot of the running game viewport',
        inputSchema: {
            path: z.string().optional().describe('Custom save path for the screenshot'),
        },
    }, async (args) => callGodot(bridge, 'editor/get_game_screenshot', args));
    // 4. execute_editor_script — {code: string} -> result
    server.registerTool('execute_editor_script', {
        description: 'Execute a GDScript snippet in the editor context (EditorScript)',
        inputSchema: {
            code: GDScriptCode,
        },
    }, async (args) => callGodot(bridge, 'editor/execute_script', args));
    // 5. clear_output — {} -> success
    server.registerTool('clear_output', {
        description: 'Clear the editor output log',
        inputSchema: {},
    }, async () => callGodot(bridge, 'editor/clear_output'));
    // 6. get_signals — {node_path: string} -> signals with connections
    server.registerTool('get_signals', {
        description: 'Get all signals and their connections for a node',
        inputSchema: {
            node_path: NodePath.describe('Node path to inspect'),
        },
    }, async (args) => callGodot(bridge, 'editor/get_signals', args));
    // 7. reload_plugin — {} -> success
    server.registerTool('reload_plugin', {
        description: 'Reload editor plugins (triggers plugin re-initialization)',
        inputSchema: {},
    }, async () => callGodot(bridge, 'editor/reload_plugin'));
    // 8. reload_project — {} -> success
    server.registerTool('reload_project', {
        description: 'Rescan the project filesystem for new or changed files',
        inputSchema: {},
    }, async () => callGodot(bridge, 'editor/reload_project'));
    // 9. get_output_log — {} -> log content
    server.registerTool('get_output_log', {
        description: 'Get the contents of the editor output log',
        inputSchema: {},
    }, async () => callGodot(bridge, 'editor/get_output_log'));
    // 10. get_diagnostics — {} -> plugin health report
    server.registerTool('get_diagnostics', {
        description: 'Get MCP bridge diagnostics: module load status, tool count, connection state. Works even when all tools are unavailable.',
        inputSchema: {},
    }, async () => callGodot(bridge, 'mcp/diagnostics'));
}
//# sourceMappingURL=editor.js.map