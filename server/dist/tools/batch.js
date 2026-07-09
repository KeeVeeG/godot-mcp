/**
 * Batch tools - 8 tools for batch operations and cross-scene analysis
 */
import { callGodot } from '../server.js';
import { z, NodeType, ScriptPath, PropertyName } from './shared-types.js';
export function registerBatchTools(server, bridge) {
    // 1. find_nodes_by_type
    server.registerTool('find_nodes_by_type', {
        description: 'Find all nodes of a specific type in the scene',
        inputSchema: {
            type_name: NodeType,
        },
    }, async (args) => callGodot(bridge, 'batch/find_by_type', args));
    // 2. find_signal_connections
    server.registerTool('find_signal_connections', {
        description: 'Find all signal connections in the scene',
        inputSchema: {},
    }, async (args) => callGodot(bridge, 'batch/find_connections', args));
    // 3. batch_set_property
    server.registerTool('batch_set_property', {
        description: 'Set a property on all nodes of a given type',
        inputSchema: {
            type_name: NodeType,
            property: PropertyName,
            value: z.unknown().refine(v => v !== undefined, { message: "Value is required" }),
        },
    }, async (args) => callGodot(bridge, 'batch/set_property', args));
    // 4. find_node_references
    server.registerTool('find_node_references', {
        description: 'Find all references to a node across scenes and scripts',
        inputSchema: {
            query: z.string().describe('Node path or name to search for'),
        },
    }, async (args) => callGodot(bridge, 'batch/find_references', args));
    // 5. get_scene_dependencies
    server.registerTool('get_scene_dependencies', {
        description: 'Get all dependencies of a scene file (scripts, resources, sub-scenes)',
        inputSchema: {
            path: z.string().describe('Scene file path'),
        },
    }, async (args) => callGodot(bridge, 'batch/get_dependencies', args));
    // 6. cross_scene_set_property
    server.registerTool('cross_scene_set_property', {
        description: 'Set a property on nodes of a given type across multiple scenes',
        inputSchema: {
            type_name: NodeType,
            property: PropertyName,
            value: z.unknown().refine(v => v !== undefined, { message: "Value is required" }),
            confirm_no_undo: z.boolean().optional().default(false).describe('Set to true to acknowledge this is destructive and cannot be undone'),
        },
    }, async (args) => callGodot(bridge, 'batch/cross_scene_set', args));
    // 7. find_script_references
    server.registerTool('find_script_references', {
        description: 'Find all scenes and nodes that use a specific script',
        inputSchema: {
            script_path: ScriptPath,
        },
    }, async (args) => callGodot(bridge, 'batch/find_script_refs', args));
    // 8. detect_circular_dependencies
    server.registerTool('detect_circular_dependencies', {
        description: 'Detect circular dependencies in the project (scripts, scenes, resources)',
        inputSchema: {},
    }, async () => callGodot(bridge, 'batch/detect_circular'));
}
//# sourceMappingURL=batch.js.map