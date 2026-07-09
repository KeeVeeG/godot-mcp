/**
 * Audio configuration tools - 6 tools for audio bus and settings management
 */
import { callGodot } from '../server.js';
import { z, Name } from './shared-types.js';
export function registerAudioConfigTools(server, bridge) {
    // 1. get_audio_settings
    server.registerTool('get_audio_settings', {
        description: 'Get all audio settings including bus layout, default bus, and driver info',
        inputSchema: {},
    }, async () => callGodot(bridge, 'audio_config/get_settings'));
    // 2. set_audio_bus_layout
    server.registerTool('set_audio_bus_layout', {
        description: 'Replace the entire audio bus layout with the given bus definitions',
        inputSchema: {
            buses: z
                .array(z.object({
                name: z.string().describe('Bus name'),
                volume: z.number().optional().describe('Volume in dB'),
                solo: z.boolean().optional().describe('Solo this bus'),
                mute: z.boolean().optional().describe('Mute this bus'),
            }))
                .describe("Ordered list of audio buses (first is always 'Master')"),
        },
    }, async (args) => callGodot(bridge, 'audio_config/set_bus_layout', args));
    // 3. add_audio_bus_config
    server.registerTool('add_audio_bus_config', {
        description: 'Add a new audio bus at a specific position',
        inputSchema: {
            name: Name.describe('Bus name'),
            index: z.number().int().min(0).optional().describe('Position in bus list (omit to append)'),
        },
    }, async (args) => callGodot(bridge, 'audio_config/add_bus_config', args));
    // 4. remove_audio_bus
    server.registerTool('remove_audio_bus', {
        description: 'Remove an audio bus by index (cannot remove Master at index 0)',
        inputSchema: {
            index: z.number().int().min(1).describe('Bus index to remove (1+, cannot remove Master)'),
        },
    }, async (args) => callGodot(bridge, 'audio_config/remove_bus', args));
    // 5. set_audio_bus_volume
    server.registerTool('set_audio_bus_volume', {
        description: 'Set the volume of a specific audio bus',
        inputSchema: {
            bus: Name.describe("Bus name (e.g. 'Master', 'Music', 'SFX')"),
            volume_db: z.number().describe('Volume in decibels (0 = normal, negative = quieter)'),
        },
    }, async (args) => callGodot(bridge, 'audio_config/set_bus_volume', args));
    // 6. get_audio_bus_effects
    server.registerTool('get_audio_bus_effects', {
        description: 'Get all effects on a specific audio bus with their properties',
        inputSchema: {
            bus: Name.describe('Bus name to inspect'),
        },
    }, async (args) => callGodot(bridge, 'audio_config/get_bus_effects', args));
}
//# sourceMappingURL=audio_config.js.map