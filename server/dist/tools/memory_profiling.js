/**
 * Memory profiling tools - 6 tools for memory analysis and leak detection
 */
import { callGodot } from '../server.js';
import { z, NodeType } from './shared-types.js';
export function registerMemoryProfilingTools(server, bridge) {
    // 1. get_memory_usage
    server.registerTool('get_memory_usage', {
        description: 'Get detailed memory usage breakdown by category (static, video, textures, buffers, objects)',
        inputSchema: {},
    }, async () => callGodot(bridge, 'get_memory_usage'));
    // 2. track_object_creation
    server.registerTool('track_object_creation', {
        description: 'Track object creation for a specific class over a duration. Records a baseline count; poll get_object_count afterward to see changes.',
        inputSchema: {
            class_name: NodeType.describe("Godot class name to track (e.g. 'Node2D', 'RigidBody3D')"),
            duration: z.number().min(1).max(60).optional().default(10).describe('Tracking duration in seconds (default: 10)'),
        },
    }, async (args) => callGodot(bridge, 'track_object_creation', args));
    // 3. stop_object_tracking
    server.registerTool('stop_object_tracking', {
        description: 'Stop object tracking and return the accumulated creation log. Must call track_object_creation first.',
        inputSchema: {},
    }, async () => callGodot(bridge, 'stop_object_tracking'));
    // 4. find_memory_leaks
    server.registerTool('find_memory_leaks', {
        description: 'Analyze the scene tree and object graph to find potential memory leaks (orphan nodes, leaked resources)',
        inputSchema: {},
    }, async () => callGodot(bridge, 'find_memory_leaks'));
    // 5. get_object_count
    server.registerTool('get_object_count', {
        description: 'Get count of live objects, optionally filtered by class name',
        inputSchema: {
            class_name: NodeType.optional().describe('Filter by class name, or omit for total count'),
        },
    }, async (args) => callGodot(bridge, 'get_object_count', args));
    // 6. force_garbage_collection
    server.registerTool('force_garbage_collection', {
        description: 'Force garbage collection and report the amount of memory freed',
        inputSchema: {},
    }, async () => callGodot(bridge, 'force_garbage_collection'));
}
//# sourceMappingURL=memory_profiling.js.map