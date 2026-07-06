/**
 * Cloud services tools - 8 tools for cloud save, leaderboards, achievements, and remote config
 */
import { callGodot } from '../server.js';
import { z, Name, OptionalProperties } from './shared-types.js';
export function registerCloudServicesTools(server, bridge) {
  // 1. get_cloud_settings
  server.registerTool(
    'get_cloud_settings',
    {
      description: 'Get the current cloud service configuration',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'get_cloud_settings'),
  );
  // 2. setup_cloud_saves
  server.registerTool(
    'setup_cloud_saves',
    {
      description: 'Configure cloud save system with a provider and optional endpoint',
      inputSchema: {
        provider: z.enum(['steam', 'custom']).describe('Cloud save provider'),
        endpoint: z.string().optional().describe("Custom endpoint URL (required for 'custom' provider)"),
      },
    },
    async (args) => callGodot(bridge, 'setup_cloud_saves', args),
  );
  // 3. sync_cloud_saves
  server.registerTool(
    'sync_cloud_saves',
    {
      description: 'Synchronize local save files with the cloud in the specified direction',
      inputSchema: {
        direction: z.enum(['upload', 'download', 'both']).describe('Sync direction: upload local to cloud, download cloud to local, or both'),
      },
    },
    async (args) => callGodot(bridge, 'sync_cloud_saves', args),
  );
  // 4. get_leaderboard
  server.registerTool(
    'get_leaderboard',
    {
      description: 'Retrieve entries from a leaderboard',
      inputSchema: {
        leaderboard_id: Name.describe('Leaderboard identifier'),
        count: z.number().int().min(1).max(100).optional().describe('Number of entries to retrieve (default: 10)'),
        around_player: z.boolean().optional().describe('If true, return entries around the current player (default: false)'),
      },
    },
    async (args) => callGodot(bridge, 'get_leaderboard', args),
  );
  // 5. submit_score
  server.registerTool(
    'submit_score',
    {
      description: 'Submit a score to a leaderboard with optional metadata',
      inputSchema: {
        leaderboard_id: Name.describe('Leaderboard identifier'),
        score: z.number().describe('Score value to submit'),
        metadata: OptionalProperties,
      },
    },
    async (args) => callGodot(bridge, 'submit_score', args),
  );
  // 6. get_achievements
  server.registerTool(
    'get_achievements',
    {
      description: 'Get all achievements with their unlock status',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'get_achievements'),
  );
  // 7. unlock_achievement
  server.registerTool(
    'unlock_achievement',
    {
      description: 'Unlock a specific achievement by its ID',
      inputSchema: {
        achievement_id: Name.describe('Achievement identifier to unlock'),
      },
    },
    async (args) => callGodot(bridge, 'unlock_achievement', args),
  );
  // 8. get_cloud_config
  server.registerTool(
    'get_cloud_config',
    {
      description: 'Get a remote configuration value by key',
      inputSchema: {
        key: Name.describe('Configuration key to retrieve'),
      },
    },
    async (args) => callGodot(bridge, 'get_cloud_config', args),
  );
}
//# sourceMappingURL=cloud_services.js.map
