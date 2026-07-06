/**
 * Collaboration tools - 6 tools for multi-user editor collaboration
 */
import { callGodot } from '../server.js';
import { z, ScenePath, NodePath, Name, PositiveInt } from './shared-types.js';
export function registerCollaborationTools(server, bridge) {
  // 1. get_editor_users
  server.registerTool(
    'get_editor_users',
    {
      description: 'Get a list of users currently connected to the editor collaboration session',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'collaboration/get_editor_users'),
  );
  // 2. share_scene
  server.registerTool(
    'share_scene',
    {
      description: 'Share a scene file with specific users in the collaboration session',
      inputSchema: {
        scene_path: ScenePath,
        users: z.array(z.string()).describe('List of user identifiers to share with'),
      },
    },
    async (args) => callGodot(bridge, 'collaboration/share_scene', args),
  );
  // 3. lock_node
  server.registerTool(
    'lock_node',
    {
      description: 'Lock a node to prevent other users from editing it',
      inputSchema: {
        node_path: NodePath,
        duration: PositiveInt.optional().describe('Lock duration in seconds (default: 300)'),
      },
    },
    async (args) => callGodot(bridge, 'collaboration/lock_node', args),
  );
  // 4. unlock_node
  server.registerTool(
    'unlock_node',
    {
      description: 'Unlock a previously locked node',
      inputSchema: {
        node_path: NodePath,
      },
    },
    async (args) => callGodot(bridge, 'collaboration/unlock_node', args),
  );
  // 5. get_locked_nodes
  server.registerTool(
    'get_locked_nodes',
    {
      description: 'Get a list of all currently locked nodes and their owners',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'collaboration/get_locked_nodes'),
  );
  // 6. send_message
  server.registerTool(
    'send_message',
    {
      description: 'Send a message to another user in the collaboration session',
      inputSchema: {
        user: Name.describe('Target user identifier'),
        message: z.string().describe('Message content'),
      },
    },
    async (args) => callGodot(bridge, 'collaboration/send_message', args),
  );
}
//# sourceMappingURL=collaboration.js.map
