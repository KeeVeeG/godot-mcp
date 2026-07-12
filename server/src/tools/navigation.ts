/**
 * Navigation tools - 10 tools for navigation system
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, NodePath, OptionalProperties, OptionalDimension } from './shared-types.js';

/**
 * Sanitize boolean properties in a properties record.
 * Godot GDScript `as bool` does not convert strings to bool — it returns the string unchanged,
 * which then crashes when assigned to a boolean property.
 * This helper converts known boolean keys from string to actual boolean before sending to Godot.
 */
const NAV_BOOL_PROPS = ['enabled', 'bidirectional', 'avoidance_enabled'] as const;

function sanitizeBoolProps(properties: Record<string, unknown> | undefined): Record<string, unknown> | undefined {
  if (!properties) return properties;
  const sanitized = { ...properties };
  for (const key of NAV_BOOL_PROPS) {
    if (typeof sanitized[key] === 'string') {
      const lower = (sanitized[key] as string).toLowerCase();
      sanitized[key] = !(lower === 'false' || lower === '0' || lower === 'no' || lower === 'off');
    }
  }
  return sanitized;
}

export function registerNavigationTools(server: McpServer, bridge: GodotBridge): void {
  // 1. setup_navigation_region
  server.registerTool(
    'setup_navigation_region',
    {
      description: 'Add a NavigationRegion2D or NavigationRegion3D with optional configuration',
      inputSchema: {
        parent_path: z.string().optional().describe('Parent node path (omit for scene root)'),
        dimension: OptionalDimension.default('2d').describe('Navigation dimension (default: 2d)'),
        name: z.string().optional().describe('Node name'),
        path: NodePath.describe('Node path for the navigation region'),
        properties: OptionalProperties.describe('Region properties (navigation_mesh, enabled, etc.)'),
      },
    },
    async (args) => {
      const a = args as Record<string, unknown>;
      a.properties = sanitizeBoolProps(a.properties as Record<string, unknown> | undefined);
      return callGodot(bridge, 'navigation/setup_region', a);
    },
  );

  // 2. setup_navigation_agent
  server.registerTool(
    'setup_navigation_agent',
    {
      description: 'Add a NavigationAgent2D or NavigationAgent3D to a node',
      inputSchema: {
        parent_path: z.string().optional().describe('Parent node path (omit for scene root)'),
        dimension: OptionalDimension.default('2d').describe('Navigation dimension (default: 2d)'),
        name: z.string().optional().describe('Node name'),
        path: NodePath.describe('Node path for the navigation agent'),
        properties: OptionalProperties.describe('Agent properties (radius, speed, path_desired_distance, etc.)'),
      },
    },
    async (args) => {
      const a = args as Record<string, unknown>;
      a.properties = sanitizeBoolProps(a.properties as Record<string, unknown> | undefined);
      return callGodot(bridge, 'navigation/setup_agent', a);
    },
  );

  // 3. bake_navigation_mesh
  server.registerTool(
    'bake_navigation_mesh',
    {
      description: 'Bake the navigation mesh for a NavigationRegion',
      inputSchema: {
        path: NodePath.describe('NavigationRegion node path'),
        sync: z.boolean().optional().describe('Use synchronous bake (blocks editor briefly but guarantees mesh is immediately available for find_path). Default: async.'),
        properties: OptionalProperties.describe('Bake configuration (cell_size, cell_height, agent_radius, etc.)'),
      },
    },
    async (args) => callGodot(bridge, 'navigation/bake_mesh', args as Record<string, unknown>),
  );

  // 4. set_navigation_layers
  server.registerTool(
    'set_navigation_layers',
    {
      description: 'Set navigation layers for pathfinding filtering',
      inputSchema: {
        path: NodePath.describe('Navigation node path'),
        layer: z.number().int().min(1).max(32).describe('Navigation layer (1-32)'),
      },
    },
    async (args) => callGodot(bridge, 'navigation/set_layers', args as Record<string, unknown>),
  );

  // 5. get_navigation_info
  server.registerTool(
    'get_navigation_info',
    {
      description: 'Get navigation map information and navigation mesh data',
      inputSchema: {
        path: NodePath.describe('NavigationRegion node path'),
      },
    },
    async (args) => callGodot(bridge, 'navigation/get_info', args as Record<string, unknown>),
  );

  // 6. find_navigation_path
  server.registerTool(
    'find_navigation_path',
    {
      description: 'Find a navigation path between two points',
      inputSchema: {
        start: z.array(z.number()).min(2).max(3).describe('Start position [x, y] or [x, y, z]'),
        end: z.array(z.number()).min(2).max(3).describe('End position [x, y] or [x, y, z]'),
        dimension: OptionalDimension,
        map: NodePath.optional().describe('NavigationRegion path to use its map for pathfinding (defaults to first available map)'),
      },
    },
    async (args) => {
      const startArr = (args.start as number[]) || [];
      const endArr = (args.end as number[]) || [];
      if (startArr.length !== endArr.length) {
        return {
          content: [{ type: 'text', text: `Dimension mismatch: start has ${startArr.length} components, end has ${endArr.length} components. Both must be either 2D ([x, y]) or 3D ([x, y, z]).` }],
          isError: true,
        };
      }
      return callGodot(bridge, 'navigation/find_path', args as Record<string, unknown>);
    },
  );

  // 7. setup_navigation_link
  server.registerTool(
    'setup_navigation_link',
    {
      description: 'Add a NavigationLink2D or NavigationLink3D for connecting navigation regions',
      inputSchema: {
        parent_path: z.string().optional().describe('Parent node path (omit for scene root)'),
        dimension: OptionalDimension.describe('Navigation dimension (auto-detected from position arrays if omitted)'),
        name: z.string().optional().describe('Node name'),
        properties: OptionalProperties.describe('Link properties (start_position, end_position, bidirectional, enabled, navigation_layers)'),
      },
    },
    async (args) => {
      const a = args as Record<string, unknown>;
      a.properties = sanitizeBoolProps(a.properties as Record<string, unknown> | undefined);
      // Strip undefined dimension to let GDScript auto-detect from position array sizes
      if (a.dimension === undefined || a.dimension === null) {
        delete a.dimension;
      }
      return callGodot(bridge, 'navigation/setup_link', a);
    },
  );

  // 8. remove_navigation_region
  server.registerTool(
    'remove_navigation_region',
    {
      description: 'Remove a navigation region node from the scene',
      inputSchema: {
        node_path: NodePath.describe('Path to the navigation region node to remove'),
      },
    },
    async (args) => callGodot(bridge, 'navigation/remove_region', args as Record<string, unknown>),
  );

  // 9. remove_navigation_agent
  server.registerTool(
    'remove_navigation_agent',
    {
      description: 'Remove a navigation agent node from the scene',
      inputSchema: {
        node_path: NodePath.describe('Path to the navigation agent node to remove'),
      },
    },
    async (args) => callGodot(bridge, 'navigation/remove_agent', args as Record<string, unknown>),
  );

  // 10. remove_navigation_link
  server.registerTool(
    'remove_navigation_link',
    {
      description: 'Remove a navigation link node from the scene',
      inputSchema: {
        node_path: NodePath.describe('Path to the navigation link node to remove'),
      },
    },
    async (args) => callGodot(bridge, 'navigation/remove_link', args as Record<string, unknown>),
  );
}
