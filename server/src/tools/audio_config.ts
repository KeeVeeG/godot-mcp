/**
 * Audio configuration tools - 9 tools for audio bus and settings management
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, Name } from './shared-types.js';

export function registerAudioConfigTools(server: McpServer, bridge: GodotBridge): void {
  // 1. get_audio_settings
  server.registerTool(
    'get_audio_settings',
    {
      description: 'Get all audio settings including bus layout, default bus, and driver info',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'audio_config/get_settings'),
  );

  // 2. set_audio_bus_layout
  server.registerTool(
    'set_audio_bus_layout',
    {
      description: 'Replace the entire audio bus layout with the given bus definitions',
      inputSchema: {
        buses: z
          .array(
            z.object({
              name: z.string().describe('Bus name'),
              volume_db: z.number().optional().describe('Volume in dB'),
              solo: z.boolean().optional().describe('Solo this bus'),
              mute: z.boolean().optional().describe('Mute this bus'),
            }),
          )
          .describe("Ordered list of audio buses (first is always 'Master')"),
      },
    },
    async (args) => callGodot(bridge, 'audio_config/set_bus_layout', args as Record<string, unknown>),
  );

  // 3. add_audio_bus_config
  server.registerTool(
    'add_audio_bus_config',
    {
      description: 'Add a new audio bus at a specific position',
      inputSchema: {
        name: Name.describe('Bus name'),
        index: z.number().int().min(0).optional().describe('Position in bus list (omit to append)'),
      },
    },
    async (args) => callGodot(bridge, 'audio_config/add_bus_config', args as Record<string, unknown>),
  );

  // 4. remove_audio_bus
  server.registerTool(
    'remove_audio_bus',
    {
      description: 'Remove an audio bus by index (cannot remove Master at index 0)',
      inputSchema: {
        index: z.number().int().min(1).describe('Bus index to remove (1+, cannot remove Master)'),
      },
    },
    async (args) => callGodot(bridge, 'audio_config/remove_bus', args as Record<string, unknown>),
  );

  // 5. set_audio_bus_volume
  server.registerTool(
    'set_audio_bus_volume',
    {
      description: 'Set the volume of a specific audio bus',
      inputSchema: {
        bus: Name.describe("Bus name (e.g. 'Master', 'Music', 'SFX')"),
        volume_db: z.number().describe('Volume in decibels (0 = normal, negative = quieter)'),
      },
    },
    async (args) => callGodot(bridge, 'audio_config/set_bus_volume', args as Record<string, unknown>),
  );

  // 6. get_audio_bus_effects
  server.registerTool(
    'get_audio_bus_effects',
    {
      description: 'Get all effects on a specific audio bus with their properties',
      inputSchema: {
        bus: Name.describe('Bus name to inspect'),
      },
    },
    async (args) => callGodot(bridge, 'audio_config/get_bus_effects', args as Record<string, unknown>),
  );

  // 7. set_audio_driver
  server.registerTool(
    'set_audio_driver',
    {
      description: 'Set the audio driver (takes effect on next Godot restart). Valid values: WASAPI, XAudio2, PulseAudio, ALSA, CoreAudio, Android, Web, Dummy',
      inputSchema: {
        driver: z.enum(['WASAPI', 'XAudio2', 'PulseAudio', 'ALSA', 'CoreAudio', 'Android', 'AudioWorklet', 'ScriptProcessor', 'Dummy']).describe('Audio driver name (platform-dependent)'),
      },
    },
    async (args) => callGodot(bridge, 'audio_config/set_driver', args as Record<string, unknown>),
  );

  // 8. set_audio_mix_rate
  server.registerTool(
    'set_audio_mix_rate',
    {
      description: 'Set the audio mix rate in Hz (takes effect on next Godot restart). Range: 11025-192000',
      inputSchema: {
        mix_rate: z.number().int().min(11025).max(192000).describe('Mix rate in Hz (e.g. 44100, 48000)'),
      },
    },
    async (args) => callGodot(bridge, 'audio_config/set_mix_rate', args as Record<string, unknown>),
  );

  // 9. set_audio_output_latency
  server.registerTool(
    'set_audio_output_latency',
    {
      description: 'Set the audio output latency in milliseconds (takes effect on next Godot restart). Range: 1-100',
      inputSchema: {
        output_latency: z.number().int().min(1).max(100).describe('Output latency in milliseconds (e.g. 15)'),
      },
    },
    async (args) => callGodot(bridge, 'audio_config/set_output_latency', args as Record<string, unknown>),
  );
}
