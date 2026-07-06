/**
 * Node introspection tools - 8 tools for querying node type metadata
 */
import { callGodot } from '../server.js';
import { z, NodeType } from './shared-types.js';
export function registerNodeConfigTools(server, bridge) {
    // 1. get_node_default_properties
    server.registerTool('get_node_default_properties', {
        description: 'Get the default property values for a node type',
        inputSchema: {
            type: NodeType,
        },
    }, async (args) => callGodot(bridge, 'node_config/get_defaults', args));
    // 2. set_node_preset
    server.registerTool('set_node_preset', {
        description: "Apply a configuration preset to a node (e.g. 'platformer_body', 'top_down_camera')",
        inputSchema: {
            type: NodeType.describe('Node type to configure'),
            preset: z.string().describe('Preset name to apply'),
        },
    }, async (args) => callGodot(bridge, 'node_config/set_preset', args));
    // 3. get_available_node_types
    server.registerTool('get_available_node_types', {
        description: 'Get all available node types, optionally filtered by category',
        inputSchema: {
            category: z.enum(['2d', '3d', 'ui', 'audio', 'physics', 'navigation']).optional().describe('Filter by category'),
        },
    }, async (args) => callGodot(bridge, 'node_config/get_types', args));
    // 4. get_node_signals
    server.registerTool('get_node_signals', {
        description: 'Get all signals defined on a node type with their argument signatures',
        inputSchema: {
            type: NodeType,
        },
    }, async (args) => callGodot(bridge, 'node_config/get_signals', args));
    // 5. get_node_methods
    server.registerTool('get_node_methods', {
        description: 'Get all public methods on a node type with their signatures',
        inputSchema: {
            type: NodeType,
        },
    }, async (args) => callGodot(bridge, 'node_config/get_methods', args));
    // 6. get_node_enums
    server.registerTool('get_node_enums', {
        description: 'Get all enumerations defined on a node type',
        inputSchema: {
            type: NodeType,
        },
    }, async (args) => callGodot(bridge, 'node_config/get_enums', args));
    // 7. get_node_constants
    server.registerTool('get_node_constants', {
        description: 'Get all constants defined on a node type',
        inputSchema: {
            type: NodeType,
        },
    }, async (args) => callGodot(bridge, 'node_config/get_constants', args));
    // 8. get_class_hierarchy
    server.registerTool('get_class_hierarchy', {
        description: 'Get the full inheritance chain for a node type',
        inputSchema: {
            type: NodeType,
        },
    }, async (args) => callGodot(bridge, 'node_config/get_hierarchy', args));
}
//# sourceMappingURL=node_config.js.map