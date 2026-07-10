/**
 * Theme tools - 11 tools for theme management
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, ResourcePath, Properties } from './shared-types.js';

export function registerThemeTools(server: McpServer, bridge: GodotBridge): void {
  // 1. create_theme
  server.registerTool(
    'create_theme',
    {
      description: 'Create a new Theme resource',
      inputSchema: {
        path: ResourcePath.describe("File path to save the theme (e.g. 'res://themes/dark.tres')"),
      },
    },
    async (args) => callGodot(bridge, 'theme/create', args as Record<string, unknown>),
  );

  // 2. delete_theme
  server.registerTool(
    'delete_theme',
    {
      description: 'Delete a theme resource file from the project',
      inputSchema: {
        path: z.string().describe('Theme file path to delete (e.g. res://themes/my_theme.tres)'),
      },
    },
    async (args) => callGodot(bridge, 'theme/delete', args as Record<string, unknown>),
  );

  // 3. set_theme_color
  server.registerTool(
    'set_theme_color',
    {
      description: 'Set a color in a theme for a specific control type',
      inputSchema: {
        path: ResourcePath.describe('Theme resource path'),
        theme_type: z.string().describe("Control type (e.g. 'Button', 'Label', 'Panel')"),
        name: z.string().describe("Color name (e.g. 'font_color', 'font_hover_color')"),
        color: z.string().describe("Color value as hex (e.g. '#FF0000') or named color"),
      },
    },
    async (args) => callGodot(bridge, 'theme/set_color', args as Record<string, unknown>),
  );

  // 4. set_theme_constant
  server.registerTool(
    'set_theme_constant',
    {
      description: 'Set a constant value in a theme',
      inputSchema: {
        path: ResourcePath.describe('Theme resource path'),
        theme_type: z.string().describe('Control type'),
        name: z.string().describe("Constant name (e.g. 'hseparation', 'vseparation')"),
        value: z.number().int().describe('Constant integer value'),
      },
    },
    async (args) => callGodot(bridge, 'theme/set_constant', args as Record<string, unknown>),
  );

  // 5. set_theme_font_size
  server.registerTool(
    'set_theme_font_size',
    {
      description: 'Set a font size in a theme',
      inputSchema: {
        path: ResourcePath.describe('Theme resource path'),
        theme_type: z.string().describe('Control type'),
        name: z.string().describe("Size name (e.g. 'font_size')"),
        size: z.number().int().positive().describe('Font size in pixels'),
      },
    },
    async (args) => callGodot(bridge, 'theme/set_font_size', args as Record<string, unknown>),
  );

  // 6. set_theme_stylebox
  server.registerTool(
    'set_theme_stylebox',
    {
      description: 'Set a StyleBox in a theme',
      inputSchema: {
        path: ResourcePath.describe('Theme resource path'),
        theme_type: z.string().describe('Control type'),
        name: z.string().describe("StyleBox name (e.g. 'normal', 'hover', 'pressed')"),
        properties: Properties.describe('StyleBox properties (e.g. bg_color, border_width)'),
        stylebox_type: z.enum(['Flat', 'Line', 'Empty']).optional().default('Flat').describe('StyleBox type to create (default: Flat)'),
      },
    },
    async (args) => callGodot(bridge, 'theme/set_stylebox', args as Record<string, unknown>),
  );

  // 7. get_theme_info
  server.registerTool(
    'get_theme_info',
    {
      description: 'Get information about a theme including all its overrides',
      inputSchema: {
        path: ResourcePath.describe('Theme resource path'),
      },
    },
    async (args) => callGodot(bridge, 'theme/get_info', args as Record<string, unknown>),
  );

  // 8. get_theme_color
  server.registerTool(
    'get_theme_color',
    {
      description: 'Get a specific color value from a theme',
      inputSchema: {
        path: ResourcePath.describe('Theme resource path'),
        theme_type: z.string().describe("Control type (e.g. 'Button', 'Label')"),
        name: z.string().describe("Color name (e.g. 'font_color', 'font_hover_color')"),
      },
    },
    async (args) => callGodot(bridge, 'theme/get_color', args as Record<string, unknown>),
  );

  // 9. get_theme_constant
  server.registerTool(
    'get_theme_constant',
    {
      description: 'Get a specific constant value from a theme',
      inputSchema: {
        path: ResourcePath.describe('Theme resource path'),
        theme_type: z.string().describe('Control type'),
        name: z.string().describe("Constant name (e.g. 'hseparation', 'vseparation')"),
      },
    },
    async (args) => callGodot(bridge, 'theme/get_constant', args as Record<string, unknown>),
  );

  // 10. get_theme_font_size
  server.registerTool(
    'get_theme_font_size',
    {
      description: 'Get a specific font size value from a theme',
      inputSchema: {
        path: ResourcePath.describe('Theme resource path'),
        theme_type: z.string().describe('Control type'),
        name: z.string().describe("Font size name (e.g. 'font_size')"),
      },
    },
    async (args) => callGodot(bridge, 'theme/get_font_size', args as Record<string, unknown>),
  );

  // 11. get_theme_stylebox
  server.registerTool(
    'get_theme_stylebox',
    {
      description: 'Get a specific StyleBox from a theme with its properties',
      inputSchema: {
        path: ResourcePath.describe('Theme resource path'),
        theme_type: z.string().describe('Control type'),
        name: z.string().describe("StyleBox name (e.g. 'normal', 'hover', 'pressed')"),
      },
    },
    async (args) => callGodot(bridge, 'theme/get_stylebox', args as Record<string, unknown>),
  );
}
