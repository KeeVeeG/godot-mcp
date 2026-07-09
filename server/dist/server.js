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
            const errorMessage = typeof errorData.error === 'string' ? errorData.error : JSON.stringify(errorData);
            // Format as JSON to match the success-result pattern: content[0].text is always parseable JSON
            const text = JSON.stringify({ success: false, error: errorMessage }, null, 2);
            return { content: [{ type: 'text', text }], isError: true };
        }
        const text = typeof result === 'string' ? result : JSON.stringify(result, null, 2);
        return { content: [{ type: 'text', text }] };
    }
    catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        return createErrorResult(`Godot request failed: ${message}`);
    }
}
//# sourceMappingURL=server.js.map