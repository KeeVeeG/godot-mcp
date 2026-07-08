/**
 * Editor configuration tools - 8 tools for editor settings
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, Name } from './shared-types.js';

export function registerEditorConfigTools(server: McpServer, bridge: GodotBridge): void {
  // 1. get_editor_settings
  server.registerTool(
    'get_editor_settings',
    {
      description: 'Get all editor settings (theme, layout, font, scale, etc.)',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'editor_config/get_settings'),
  );

  // 2. set_editor_theme
  server.registerTool(
    'set_editor_theme',
    {
      description: 'Set the editor color theme',
      inputSchema: {
        theme: z.enum(['dark', 'light', 'amoled']).describe('Editor theme preset'),
      },
    },
    async (args) => callGodot(bridge, 'editor_config/set_theme', args as Record<string, unknown>),
  );

  // 3. set_editor_layout
  server.registerTool(
    'set_editor_layout',
    {
      description: 'Switch the editor to a specific workspace layout',
      inputSchema: {
        layout: z.enum(['default', '2d', '3d', 'script']).describe('Editor layout preset to activate'),
      },
    },
    async (args) => callGodot(bridge, 'editor_config/set_layout', args as Record<string, unknown>),
  );

  // 4. set_font_size
  server.registerTool(
    'set_font_size',
    {
      description: 'Set the editor font size in pixels',
      inputSchema: {
        size: z.number().int().min(8).max(48).describe('Font size in pixels'),
      },
    },
    async (args) => callGodot(bridge, 'editor_config/set_font_size', args as Record<string, unknown>),
  );

  // 5. set_editor_scale
  server.registerTool(
    'set_editor_scale',
    {
      description: 'Set the editor UI scale factor',
      inputSchema: {
        scale: z.number().min(0.5).max(4.0).describe('UI scale factor (1.0 = 100%)'),
      },
    },
    async (args) => callGodot(bridge, 'editor_config/set_scale', args as Record<string, unknown>),
  );

  // 6. save_editor_layout
  server.registerTool(
    'save_editor_layout',
    {
      description: 'Save the current editor layout under a name',
      inputSchema: {
        name: Name.describe('Layout name to save as'),
      },
    },
    async (args) => callGodot(bridge, 'editor_config/save_layout', args as Record<string, unknown>),
  );

  // 7. load_editor_layout
  server.registerTool(
    'load_editor_layout',
    {
      description: 'Load a previously saved editor layout',
      inputSchema: {
        name: Name.describe('Layout name to load'),
      },
    },
    async (args) => callGodot(bridge, 'editor_config/load_layout', args as Record<string, unknown>),
  );

  // 8. reset_editor_layout
  server.registerTool(
    'reset_editor_layout',
    {
      description: 'Reset the editor layout to factory defaults',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'editor_config/reset_layout'),
  );
}
