/**
 * Node tools - 18 tools for node manipulation
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, NodePath, ParentPath, NodeType, PropertyName, PropertyValue, OptionalProperties } from './shared-types.js';

export function registerNodeTools(server: McpServer, bridge: GodotBridge): void {
  // 1. add_node
  server.registerTool(
    'add_node',
    {
      description: 'Add a new node to the scene tree',
      inputSchema: {
        parent_path: ParentPath.describe("Parent node path (e.g. 'Player' or '' for root)"),
        type: NodeType,
        name: z.string().describe('Name for the new node'),
        properties: OptionalProperties,
      },
    },
    async (args) => callGodot(bridge, 'node/add', args as Record<string, unknown>),
  );

  // 2. delete_node
  server.registerTool(
    'delete_node',
    {
      description: 'Delete a node from the scene tree',
      inputSchema: {
        path: NodePath.describe("Node path to delete (e.g. 'Player/Sprite2D')"),
      },
    },
    async (args) => callGodot(bridge, 'node/delete', args as Record<string, unknown>),
  );

  // 3. duplicate_node
  server.registerTool(
    'duplicate_node',
    {
      description: 'Duplicate a node in the scene tree',
      inputSchema: {
        path: NodePath.describe('Node path to duplicate'),
      },
    },
    async (args) => callGodot(bridge, 'node/duplicate', args as Record<string, unknown>),
  );

  // 4. move_node
  server.registerTool(
    'move_node',
    {
      description: 'Move a node to a new parent in the scene tree',
      inputSchema: {
        path: NodePath.describe('Node path to move'),
        new_parent: z.string().describe('New parent node path'),
        index: z.number().int().min(0).optional().describe('Child index position'),
      },
    },
    async (args) => callGodot(bridge, 'node/move', args as Record<string, unknown>),
  );

  // 5. update_property
  server.registerTool(
    'update_property',
    {
      description: 'Update a property value on a node',
      inputSchema: {
        path: NodePath,
        property: PropertyName,
        value: PropertyValue,
      },
    },
    async (args) => callGodot(bridge, 'node/update_property', args as Record<string, unknown>),
  );

  // 6. get_node_properties
  server.registerTool(
    'get_node_properties',
    {
      description: 'Get all properties of a node',
      inputSchema: {
        path: NodePath,
      },
    },
    async (args) => callGodot(bridge, 'node/get_properties', args as Record<string, unknown>),
  );

  // 7. add_resource
  server.registerTool(
    'add_resource',
    {
      description: 'Add a resource (material, texture, etc.) to a node property',
      inputSchema: {
        path: NodePath.describe("Node to add resource to (e.g. 'Player' or 'Player/Cube')"),
        resource_type: z.string().describe("Resource type (e.g. 'Material', 'Texture2D')"),
        properties: OptionalProperties,
      },
    },
    async (args) => callGodot(bridge, 'node/add_resource', args as Record<string, unknown>),
  );

  // 8. remove_resource
  server.registerTool(
    'remove_resource',
    {
      description: 'Remove a resource from a node property (sets it to null)',
      inputSchema: {
        path: NodePath.describe("Node to remove resource from (e.g. 'Player' or 'Player/Cube')"),
        property: z.string().optional().describe('Property to clear (auto-detects if omitted)'),
      },
    },
    async (args) => callGodot(bridge, 'node/remove_resource', args as Record<string, unknown>),
  );

  // 9. set_anchor_preset
  server.registerTool(
    'set_anchor_preset',
    {
      description: 'Set anchor preset on a Control node',
      inputSchema: {
        path: NodePath.describe('Control node path'),
        preset: z.string().describe("Anchor preset name (e.g. 'full_rect', 'center', 'top_left')"),
      },
    },
    async (args) => callGodot(bridge, 'node/set_anchor_preset', args as Record<string, unknown>),
  );

  // 10. rename_node
  server.registerTool(
    'rename_node',
    {
      description: 'Rename a node in the scene tree',
      inputSchema: {
        path: NodePath.describe('Current node path'),
        new_name: z.string().describe('New name for the node'),
      },
    },
    async (args) => callGodot(bridge, 'node/rename', args as Record<string, unknown>),
  );

  // 11. connect_signal
  server.registerTool(
    'connect_signal',
    {
      description: "Connect a signal from one node to another node's method",
      inputSchema: {
        source: NodePath.describe('Node path emitting the signal'),
        signal: z.string().describe('Signal name'),
        target: NodePath.describe('Node path receiving the signal'),
        method: z.string().describe('Method to call on the target node'),
      },
    },
    async (args) => callGodot(bridge, 'node/connect_signal', args as Record<string, unknown>),
  );

  // 12. disconnect_signal
  server.registerTool(
    'disconnect_signal',
    {
      description: 'Disconnect a signal connection',
      inputSchema: {
        source: NodePath.describe('Node path that emits the signal'),
        signal: z.string().describe('Signal name'),
        target: NodePath.describe('Node path that receives the signal'),
        method: z.string().describe('Method that was connected'),
      },
    },
    async (args) => callGodot(bridge, 'node/disconnect_signal', args as Record<string, unknown>),
  );

  // 13. get_node_groups
  server.registerTool(
    'get_node_groups',
    {
      description: 'Get all groups a node belongs to',
      inputSchema: {
        path: NodePath,
      },
    },
    async (args) => callGodot(bridge, 'node/get_groups', args as Record<string, unknown>),
  );

  // 14. set_node_groups
  server.registerTool(
    'set_node_groups',
    {
      description: 'Set the groups a node belongs to (replaces existing groups)',
      inputSchema: {
        path: NodePath,
        groups: z.array(z.string()).describe('List of group names'),
      },
    },
    async (args) => callGodot(bridge, 'node/set_groups', args as Record<string, unknown>),
  );

  // 15. find_nodes_in_group
  server.registerTool(
    'find_nodes_in_group',
    {
      description: 'Find all nodes belonging to a specific group',
      inputSchema: {
        group: z.string().describe('Group name to search for'),
      },
    },
    async (args) => callGodot(bridge, 'node/find_in_group', args as Record<string, unknown>),
  );

  // 16. get_editor_selection
  server.registerTool(
    'get_editor_selection',
    {
      description: 'Get the currently selected nodes in the editor',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'node/get_selection'),
  );

  // 17. select_nodes
  server.registerTool(
    'select_nodes',
    {
      description: 'Select nodes in the editor',
      inputSchema: {
        paths: z.array(z.string()).describe('List of node paths to select'),
      },
    },
    async (args) => callGodot(bridge, 'node/select', args as Record<string, unknown>),
  );

  // 18. clear_editor_selection
  server.registerTool(
    'clear_editor_selection',
    {
      description: 'Clear the current editor selection',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'node/clear_selection'),
  );
}
