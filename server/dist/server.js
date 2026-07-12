/**
 * McpServer factory with tool registration
 */
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { SERVER_NAME, SERVER_VERSION } from './config.js';
import { createErrorResult } from './types.js';
/**
 * Create and configure the MCP server instance.
 */
export function createServer(_bridge) {
    const server = new McpServer({
        name: SERVER_NAME,
        version: SERVER_VERSION,
    });
    return server;
}
/**
 * Register a tool with the MCP server.
 * This wraps the handler to always receive the bridge instance.
 */
export function registerTool(server, bridge, name, description, schema, handler) {
    server.tool(name, description, schema, async (args) => {
        try {
            const result = await handler(args, bridge);
            return result;
        }
        catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            return createErrorResult(`Tool ${name} failed: ${message}`);
        }
    });
}
/**
 * Helper to call Godot via the bridge and format the result.
 */
export async function callGodot(bridge, method, params = {}) {
    try {
        const result = await bridge.sendRequest(method, params);
        // Check if GDScript command returned a structured error (success: false)
        if (result && typeof result === 'object' && result.success === false) {
            const errorData = result;
            let errorMessage;
            if (typeof errorData.error === 'string') {
                errorMessage = errorData.error;
            }
            else if (Array.isArray(errorData.errors) && errorData.errors.length > 0) {
                // Handle {success: false, errors: [...]} pattern (e.g. create_project_with_assets)
                errorMessage = errorData.errors.join('; ');
            }
            else {
                // Fallback: build message from known keys instead of JSON.stringify-ing the whole object
                const parts = [];
                if (typeof errorData.error === 'string')
                    parts.push(errorData.error);
                if (Array.isArray(errorData.errors))
                    parts.push(errorData.errors.join('; '));
                errorMessage = parts.length > 0 ? parts.join('; ') : JSON.stringify(errorData);
            }
            // Preserve the full structured error in the response for programmatic consumers
            const text = JSON.stringify({ ...errorData, error: errorMessage }, null, 2);
            return { content: [{ type: 'text', text }], isError: true };
        }
        // Safety net: also detect legacy {"error": "string"} format (without success key).
        // The command_router.gd normalizes these to {"success": false, "error": "..."},
        // but this catch-all ensures errors are never silently treated as successes.
        if (result && typeof result === 'object' && typeof result.error === 'string' && !('result' in result)) {
            const errMsg = result.error;
            return { content: [{ type: 'text', text: JSON.stringify({ success: false, error: errMsg }, null, 2) }], isError: true };
        }
        const text = typeof result === 'string' ? result : JSON.stringify(result);
        return { content: [{ type: 'text', text }] };
    }
    catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        const code = error.code;
        // Build diagnostic hints for common JSON-RPC error codes
        let hint = '';
        if (code === -32601) {
            // METHOD_NOT_FOUND — the Godot plugin's command_router has no handler for this method.
            // This typically means the plugin's command modules failed to load.
            // Check the Godot Output panel for "[MCP] Registered X command modules with Y tools"
            // — if X=0 or Y is lower than expected, modules have loading/parse errors.
            hint = ' (Hint: method not found on Godot side — verify the MCP plugin is loaded and modules registered. Check Godot Output panel for "[MCP] Registered" log.)';
        }
        else if (code) {
            hint = ` [code ${code}]`;
        }
        return createErrorResult(`Godot request failed: ${message}${hint}`);
    }
}
//# sourceMappingURL=server.js.map