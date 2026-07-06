/**
 * Networking tools - 8 tools for multiplayer and network management
 */
import { callGodot } from '../server.js';
import { z, NodePath } from './shared-types.js';
export function registerNetworkingTools(server, bridge) {
  // 1. get_network_settings
  server.registerTool(
    'get_network_settings',
    {
      description: 'Get current networking configuration and multiplayer settings',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'networking/get_settings'),
  );
  // 2. create_multiplayer_server
  server.registerTool(
    'create_multiplayer_server',
    {
      description: 'Create and start a multiplayer server with the specified configuration',
      inputSchema: {
        port: z.number().int().min(1).max(65535).describe('Port number to listen on'),
        max_clients: z.number().int().min(1).max(4095).optional().describe('Maximum number of connected clients (default: 32)'),
        transport: z.enum(['enet', 'websocket', 'webrtc']).optional().describe('Network transport layer (default: enet)'),
      },
    },
    async (args) => callGodot(bridge, 'networking/create_server', args),
  );
  // 3. connect_to_server
  server.registerTool(
    'connect_to_server',
    {
      description: 'Connect to a multiplayer server as a client',
      inputSchema: {
        address: z.string().describe('Server address (IP or hostname)'),
        port: z.number().int().min(1).max(65535).describe('Server port number'),
      },
    },
    async (args) => callGodot(bridge, 'networking/connect', args),
  );
  // 4. disconnect_from_server
  server.registerTool(
    'disconnect_from_server',
    {
      description: 'Disconnect from the current multiplayer session',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'networking/disconnect'),
  );
  // 5. get_connected_peers
  server.registerTool(
    'get_connected_peers',
    {
      description: 'Get a list of all connected peers with their IDs and connection info',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'networking/get_peers'),
  );
  // 6. send_rpc
  server.registerTool(
    'send_rpc',
    {
      description: 'Send a remote procedure call to a specific peer or all peers',
      inputSchema: {
        peer_id: z.number().int().describe('Target peer ID (0 = all peers)'),
        method: z.string().describe('RPC method name to call'),
        args: z.array(z.unknown()).optional().describe('Arguments to pass to the RPC method'),
      },
    },
    async (args) => callGodot(bridge, 'networking/send_rpc', args),
  );
  // 7. set_network_authority
  server.registerTool(
    'set_network_authority',
    {
      description: 'Set the network authority (owner) of a node to a specific peer',
      inputSchema: {
        node_path: NodePath.describe('Path to the node in the scene tree'),
        peer_id: z.number().int().describe('Peer ID to assign as network authority'),
      },
    },
    async (args) => callGodot(bridge, 'networking/set_authority', args),
  );
  // 8. get_network_info
  server.registerTool(
    'get_network_info',
    {
      description: 'Get network performance metrics including latency, bandwidth, and packet loss',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'networking/get_info'),
  );
}
//# sourceMappingURL=networking.js.map
