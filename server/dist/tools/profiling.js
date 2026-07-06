/**
 * Profiling tools - 2 tools for performance profiling
 */
import { callGodot } from '../server.js';
import { z } from './shared-types.js';
export function registerProfilingTools(server, bridge) {
    // 1. get_performance_monitors
    server.registerTool('get_performance_monitors', {
        description: 'Get all performance monitor values (FPS, memory, physics, rendering, navigation)',
        inputSchema: {
            monitors: z.array(z.string()).optional().describe('Filter to specific monitor names only (e.g. ["time/fps", "memory/static"]). Returns all monitors if omitted.'),
        },
    }, async (args) => callGodot(bridge, 'profiling/monitors', args));
    // 2. get_editor_performance
    server.registerTool('get_editor_performance', {
        description: 'Get editor performance snapshot (FPS, timing, memory usage, object counts, render stats, physics activity)',
        inputSchema: {},
    }, async () => callGodot(bridge, 'profiling/editor_performance'));
}
//# sourceMappingURL=profiling.js.map