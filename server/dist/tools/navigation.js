/**
 * Navigation tools - 10 tools for navigation system
 */
import { callGodot } from '../server.js';
import { z, NodePath, OptionalProperties, OptionalDimension } from './shared-types.js';
export function registerNavigationTools(server, bridge) {
    // 1. setup_navigation_region
    server.registerTool('setup_navigation_region', {
        description: 'Add a NavigationRegion2D or NavigationRegion3D with optional configuration',
        inputSchema: {
            parent_path: z.string().optional().describe('Parent node path (omit for scene root)'),
            dimension: OptionalDimension.default('2d').describe('Navigation dimension (default: 2d)'),
            name: z.string().optional().describe('Node name'),
            path: NodePath.describe('Node path for the navigation region'),
            properties: OptionalProperties.describe('Region properties (navigation_mesh, enabled, etc.)'),
        },
    }, async (args) => callGodot(bridge, 'navigation/setup_region', args));
    // 2. setup_navigation_agent
    server.registerTool('setup_navigation_agent', {
        description: 'Add a NavigationAgent2D or NavigationAgent3D to a node',
        inputSchema: {
            parent_path: z.string().optional().describe('Parent node path (omit for scene root)'),
            dimension: OptionalDimension.default('2d').describe('Navigation dimension (default: 2d)'),
            name: z.string().optional().describe('Node name'),
            path: NodePath.describe('Node path for the navigation agent'),
            properties: OptionalProperties.describe('Agent properties (radius, speed, path_desired_distance, etc.)'),
        },
    }, async (args) => callGodot(bridge, 'navigation/setup_agent', args));
    // 3. bake_navigation_mesh
    server.registerTool('bake_navigation_mesh', {
        description: 'Bake the navigation mesh for a NavigationRegion',
        inputSchema: {
            path: NodePath.describe('NavigationRegion node path'),
            properties: OptionalProperties.describe('Bake configuration (cell_size, cell_height, agent_radius, etc.)'),
        },
    }, async (args) => callGodot(bridge, 'navigation/bake_mesh', args));
    // 4. set_navigation_layers
    server.registerTool('set_navigation_layers', {
        description: 'Set navigation layers and/or mask for pathfinding filtering',
        inputSchema: {
            path: NodePath.describe('Navigation node path'),
            layer: z.number().int().min(1).max(32).optional().describe('Navigation layer (1-32)'),
        },
    }, async (args) => callGodot(bridge, 'navigation/set_layers', args));
    // 5. get_navigation_info
    server.registerTool('get_navigation_info', {
        description: 'Get navigation map information and navigation mesh data',
        inputSchema: {
            path: NodePath.describe('NavigationRegion node path'),
        },
    }, async (args) => callGodot(bridge, 'navigation/get_info', args));
    // 6. find_navigation_path
    server.registerTool('find_navigation_path', {
        description: 'Find a navigation path between two points',
        inputSchema: {
            start: z.array(z.number()).describe('Start position [x, y] or [x, y, z]'),
            end: z.array(z.number()).describe('End position [x, y] or [x, y, z]'),
            dimension: OptionalDimension,
        },
    }, async (args) => callGodot(bridge, 'navigation/find_path', args));
    // 7. setup_navigation_link
    server.registerTool('setup_navigation_link', {
        description: 'Add a NavigationLink2D or NavigationLink3D for connecting navigation regions',
        inputSchema: {
            parent_path: z.string().optional().describe('Parent node path (omit for scene root)'),
            dimension: OptionalDimension.default('2d').describe('Navigation dimension (default: 2d)'),
            name: z.string().optional().describe('Node name'),
            properties: OptionalProperties.describe('Link properties (start_position, end_position, bidirectional, enabled, navigation_layers)'),
        },
    }, async (args) => callGodot(bridge, 'navigation/setup_link', args));
    // 8. remove_navigation_region
    server.registerTool('remove_navigation_region', {
        description: 'Remove a navigation region node from the scene',
        inputSchema: {
            node_path: NodePath.describe('Path to the navigation region node to remove'),
        },
    }, async (args) => callGodot(bridge, 'navigation/remove_region', args));
    // 9. remove_navigation_agent
    server.registerTool('remove_navigation_agent', {
        description: 'Remove a navigation agent node from the scene',
        inputSchema: {
            node_path: NodePath.describe('Path to the navigation agent node to remove'),
        },
    }, async (args) => callGodot(bridge, 'navigation/remove_agent', args));
    // 10. remove_navigation_link
    server.registerTool('remove_navigation_link', {
        description: 'Remove a navigation link node from the scene',
        inputSchema: {
            node_path: NodePath.describe('Path to the navigation link node to remove'),
        },
    }, async (args) => callGodot(bridge, 'navigation/remove_link', args));
}
//# sourceMappingURL=navigation.js.map