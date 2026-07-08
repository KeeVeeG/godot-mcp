#!/usr/bin/env node
/**
 * Godot MCP Server Entry Point
 *
 * Creates the MCP server with stdio transport and WebSocket bridge
 * for communicating with Godot EditorPlugin.
 */
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { InitializeRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import { GodotBridge } from './godot-bridge.js';
import { createServer } from './server.js';
import { registerAllTools } from './tools/index.js';
import { SERVER_NAME, SERVER_VERSION, isGodotProject } from './config.js';
async function main() {
    // Log to stderr (stdout is reserved for MCP protocol)
    console.error(`[${SERVER_NAME}] Starting v${SERVER_VERSION}...`);
    // Must run from a Godot project root directory
    if (!isGodotProject()) {
        console.error(`[${SERVER_NAME}] Not a Godot project — will reject MCP handshake with error`);
        // Create a minimal server and intercept the initialize handshake.
        // By throwing an McpError during initialization, the MCP client displays
        // a descriptive error instead of generic "Connection closed (-32000)".
        const server = createServer(null);
        server.server.removeRequestHandler('initialize');
        server.server.setRequestHandler(InitializeRequestSchema, () => {
            throw new Error('Not a Godot project directory.');
        });
        const transport = new StdioServerTransport();
        await server.connect(transport);
        // Keep process alive until stdin closes, then exit
        await new Promise((resolve) => {
            process.stdin.on('close', resolve);
        });
        await server.close();
        return;
    }
    // Create the Godot bridge (WebSocket server)
    const bridge = new GodotBridge();
    const port = await bridge.start();
    console.error(`[${SERVER_NAME}] WebSocket bridge listening on port ${port}`);
    // Create the MCP server
    const server = createServer(bridge);
    // Register all tools
    registerAllTools(server, bridge);
    console.error(`[${SERVER_NAME}] Tools registered`);
    // Connect stdio transport
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error(`[${SERVER_NAME}] MCP server connected via stdio`);
    // Graceful shutdown
    const shutdown = async (signal) => {
        console.error(`\n[${SERVER_NAME}] Received ${signal}, shutting down...`);
        try {
            await server.close();
            await bridge.shutdown();
            console.error(`[${SERVER_NAME}] Shutdown complete`);
            process.exit(0);
        }
        catch (err) {
            console.error(`[${SERVER_NAME}] Error during shutdown:`, err);
            process.exit(1);
        }
    };
    process.on('SIGINT', () => shutdown('SIGINT'));
    process.on('SIGTERM', () => shutdown('SIGTERM'));
    // Handle stdin close (MCP client disconnected)
    process.stdin.on('close', () => {
        console.error(`[${SERVER_NAME}] stdin closed, shutting down...`);
        void shutdown('stdin-close');
    });
    // Handle uncaught errors
    process.on('uncaughtException', (err) => {
        console.error(`[${SERVER_NAME}] Uncaught exception:`, err);
    });
    process.on('unhandledRejection', (reason) => {
        console.error(`[${SERVER_NAME}] Unhandled rejection:`, reason);
    });
}
main().catch((err) => {
    console.error(`[${SERVER_NAME}] Fatal error:`, err);
    process.exit(1);
});
//# sourceMappingURL=index.js.map