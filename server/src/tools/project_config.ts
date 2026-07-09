/**
 * Project configuration tools - 12 tools for project settings, input map, and autoloads
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, Name, FilePath, PropertyValue } from './shared-types.js';

export function registerProjectConfigTools(server: McpServer, bridge: GodotBridge): void {
  // 1. get_project_setting
  server.registerTool(
    'get_project_setting',
    {
      description: "Get a single project setting value by key (e.g. 'display/window/size/viewport_width')",
      inputSchema: {
        key: z.string().describe('Project setting key path'),
      },
    },
    async (args) => callGodot(bridge, 'project_config/get_setting', args as Record<string, unknown>),
  );

  // 2. set_project_setting_config
  server.registerTool(
    'set_project_setting_config',
    {
      description: 'Set a project setting value and save project.godot',
      inputSchema: {
        key: z.string().describe('Project setting key path'),
        value: PropertyValue,
      },
    },
    async (args) => callGodot(bridge, 'project_config/set_setting_config', args as Record<string, unknown>),
  );

  // 3. get_all_project_settings
  server.registerTool(
    'get_all_project_settings',
    {
      description: 'Get all project settings, optionally filtered by prefix',
      inputSchema: {
        filter: z.string().optional().describe("Prefix filter (e.g. 'display/', 'input/')"),
      },
    },
    async (args) => callGodot(bridge, 'project_config/get_all_settings', args as Record<string, unknown>),
  );

  // 4. reset_project_setting
  server.registerTool(
    'reset_project_setting',
    {
      description: 'Reset a project setting to its default value',
      inputSchema: {
        key: z.string().describe('Project setting key to reset'),
      },
    },
    async (args) => callGodot(bridge, 'project_config/reset_setting', args as Record<string, unknown>),
  );

  // 5. get_input_map
  server.registerTool(
    'get_input_map',
    {
      description: 'Get all input actions and their mapped events from the InputMap',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'project_config/get_input_map'),
  );

  // 6. set_input_map — accepts both flat [events] and nested {deadzone, events} for roundtrip
  server.registerTool(
    'set_input_map',
    {
      description: 'Replace the entire input map with the given actions and events',
      inputSchema: {
        actions: z
          .record(
            z.union([
              z.array(z.object({ type: z.string() }).passthrough().describe('Input event')),
              z.object({
                deadzone: z.number().min(0).max(1).optional().describe('Deadzone value (0-1)'),
                events: z.array(z.object({ type: z.string() }).passthrough().describe('Input event')),
              }),
            ]),
          )
          .describe('Map of action name to array of input events, or {deadzone, events} object (from get_input_map)'),
      },
    },
    async (args) => callGodot(bridge, 'project_config/set_input_map', args as Record<string, unknown>),
  );

  // 7. add_input_action
  server.registerTool(
    'add_input_action',
    {
      description: 'Add a new input action with optional deadzone and event mappings',
      inputSchema: {
        action: z.string().describe("Action name (e.g. 'jump', 'move_left')"),
        deadzone: z.number().min(0).max(1).optional().default(0.5).describe('Deadzone value (0-1, default 0.5)'),
        events: z.array(z.object({ type: z.string() }).passthrough().describe('Input event definition')).describe('Array of input events to map'),
      },
    },
    async (args) => callGodot(bridge, 'project_config/add_input_action', args as Record<string, unknown>),
  );

  // 8. remove_input_action
  server.registerTool(
    'remove_input_action',
    {
      description: 'Remove an input action from the InputMap',
      inputSchema: {
        action: z.string().describe('Action name to remove'),
      },
    },
    async (args) => callGodot(bridge, 'project_config/remove_input_action', args as Record<string, unknown>),
  );

  // 9. get_autoloads
  server.registerTool(
    'get_autoloads',
    {
      description: 'Get all autoload singletons configured in the project',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'project_config/get_autoloads'),
  );

  // 10. add_autoload_config
  server.registerTool(
    'add_autoload_config',
    {
      description: 'Add an autoload singleton to the project',
      inputSchema: {
        name: Name.describe('Autoload singleton name'),
        path: FilePath.describe("Script or scene path (e.g. 'res://autoload/global.gd')"),
        enabled: z.boolean().optional().default(true).describe('Whether the autoload is enabled (default: true)'),
      },
    },
    async (args) => callGodot(bridge, 'project_config/add_autoload_config', args as Record<string, unknown>),
  );

  // 11. remove_autoload_config
  server.registerTool(
    'remove_autoload_config',
    {
      description: 'Remove an autoload singleton from the project',
      inputSchema: {
        name: Name.describe('Autoload singleton name to remove'),
      },
    },
    async (args) => callGodot(bridge, 'project_config/remove_autoload_config', args as Record<string, unknown>),
  );

  // 12. reorder_autoloads
  server.registerTool(
    'reorder_autoloads',
    {
      description: 'Set the loading order of autoload singletons',
      inputSchema: {
        order: z.array(z.string()).describe('Ordered list of autoload names (first loads first)'),
      },
    },
    async (args) => callGodot(bridge, 'project_config/reorder_autoloads', args as Record<string, unknown>),
  );

  // 13. remove_project_setting
  server.registerTool(
    'remove_project_setting',
    {
      description: 'Remove a project setting from project.godot. Use this instead of setting a value to null.',
      inputSchema: {
        key: z.string().describe('Project setting key to remove (e.g. custom/my_setting)'),
      },
    },
    async (args) => callGodot(bridge, 'project_config/remove_setting', args as Record<string, unknown>),
  );
}
