/**
 * Save/Load tools - 5 tools for game save system testing
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, OptionalProperties } from './shared-types.js';

export function registerSaveLoadTools(server: McpServer, bridge: GodotBridge): void {
  // 1. save_game_state
  server.registerTool(
    'save_game_state',
    {
      description: 'Save the current game state to a numbered slot with optional metadata',
      inputSchema: {
        slot: z.number().int().min(0).max(99).describe('Save slot number (0-99)'),
        metadata: OptionalProperties.describe('Optional metadata to store with the save (e.g. player name, level, timestamp)'),
      },
    },
    async (args) => callGodot(bridge, 'save_game_state', args as Record<string, unknown>),
  );

  // 2. load_game_state
  server.registerTool(
    'load_game_state',
    {
      description: 'Load a game state from a numbered save slot',
      inputSchema: {
        slot: z.number().int().min(0).max(99).describe('Save slot number to load (0-99)'),
      },
    },
    async (args) => callGodot(bridge, 'load_game_state', args as Record<string, unknown>),
  );

  // 3. list_save_files
  server.registerTool(
    'list_save_files',
    {
      description: 'List all save files with their metadata',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'list_save_files'),
  );

  // 4. delete_save_file
  server.registerTool(
    'delete_save_file',
    {
      description: 'Delete a save file from a specific slot',
      inputSchema: {
        slot: z.number().int().min(0).max(99).describe('Save slot number to delete (0-99)'),
      },
    },
    async (args) => callGodot(bridge, 'delete_save_file', args as Record<string, unknown>),
  );

  // 5. compare_save_states
  server.registerTool(
    'compare_save_states',
    {
      description: 'Compare two save states and return a diff of their contents',
      inputSchema: {
        slot_a: z.number().int().min(0).max(99).describe('First save slot to compare (0-99)'),
        slot_b: z.number().int().min(0).max(99).describe('Second save slot to compare (0-99)'),
      },
    },
    async (args) => callGodot(bridge, 'compare_save_states', args as Record<string, unknown>),
  );
}
