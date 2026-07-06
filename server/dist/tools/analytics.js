/**
 * Analytics tools - 6 tools for player analytics and event tracking
 */
import { callGodot } from '../server.js';
import { z, Name, Properties, OptionalProperties, Timeout } from './shared-types.js';
export function registerAnalyticsTools(server, bridge) {
  // 1. track_event
  server.registerTool(
    'track_event',
    {
      description: 'Track a custom analytics event with optional properties',
      inputSchema: {
        event_name: Name.describe("Name of the event (e.g. 'level_complete', 'item_pickup')"),
        properties: OptionalProperties,
      },
    },
    async (args) => callGodot(bridge, 'analytics/track_event', args),
  );
  // 2. track_screen
  server.registerTool(
    'track_screen',
    {
      description: 'Track a screen view with optional duration',
      inputSchema: {
        screen_name: Name.describe("Name of the screen (e.g. 'MainMenu', 'Settings', 'Level_5')"),
        duration: Timeout.describe('Time spent on screen in seconds'),
      },
    },
    async (args) => callGodot(bridge, 'analytics/track_screen', args),
  );
  // 3. track_error
  server.registerTool(
    'track_error',
    {
      description: 'Track an error event with type, message, and optional stack trace',
      inputSchema: {
        error_type: z.string().describe("Error category (e.g. 'crash', 'network', 'validation')"),
        message: z.string().describe('Error message description'),
        stack: z.string().optional().describe('Stack trace or additional context'),
      },
    },
    async (args) => callGodot(bridge, 'analytics/track_error', args),
  );
  // 4. get_analytics_summary
  server.registerTool(
    'get_analytics_summary',
    {
      description: 'Get a summary of analytics data for a given time range',
      inputSchema: {
        time_range: z.enum(['hour', 'day', 'week', 'month']).optional().describe('Time range for summary (default: day)'),
      },
    },
    async (args) => callGodot(bridge, 'analytics/get_summary', args),
  );
  // 5. set_user_properties
  server.registerTool(
    'set_user_properties',
    {
      description: 'Set persistent user/player properties for analytics segmentation',
      inputSchema: {
        properties: Properties.describe("User properties as key-value pairs (e.g. {'level': 5, 'premium': true})"),
      },
    },
    async (args) => callGodot(bridge, 'analytics/set_user_properties', args),
  );
  // 6. get_player_metrics
  server.registerTool(
    'get_player_metrics',
    {
      description: 'Get player engagement metrics: session count, total playtime, and retention data',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'analytics/get_player_metrics'),
  );
}
//# sourceMappingURL=analytics.js.map
