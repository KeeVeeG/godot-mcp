/**
 * Audio tools - 7 tools for audio management
 */
import { callGodot } from '../server.js';
import { z, NodePath, ParentPath, Name, Properties, OptionalProperties } from './shared-types.js';
export function registerAudioTools(server, bridge) {
    // 1. add_audio_player
    server.registerTool('add_audio_player', {
        description: 'Add an AudioStreamPlayer, AudioStreamPlayer2D, or AudioStreamPlayer3D node',
        inputSchema: {
            parent: ParentPath.describe("Parent node — '' for scene root"),
            player_type: z.enum(['AudioStreamPlayer', 'AudioStreamPlayer2D', 'AudioStreamPlayer3D']).optional().default('AudioStreamPlayer').describe('Audio player type'),
            name: z.string().optional().describe('Custom node name'),
            stream_path: z.string().optional().describe("Audio stream resource path (e.g. 'res://sounds/music.ogg')"),
            properties: OptionalProperties.describe('Additional player properties (volume_db, autoplay, bus, etc.)'),
        },
    }, async (args) => callGodot(bridge, 'audio/add_player', args));
    // 2. remove_audio_player
    server.registerTool('remove_audio_player', {
        description: 'Remove an audio player node from the scene',
        inputSchema: {
            node_path: NodePath.describe('Path to the audio player node to remove'),
        },
    }, async (args) => callGodot(bridge, 'audio/remove_player', args));
    // 3. add_audio_bus
    server.registerTool('add_audio_bus', {
        description: 'Add a new audio bus to the audio bus layout',
        inputSchema: {
            name: Name.describe('Bus name'),
            index: z.number().int().optional().describe('Position in bus list'),
        },
    }, async (args) => callGodot(bridge, 'audio/add_bus', args));
    // 4. add_audio_bus_effect
    server.registerTool('add_audio_bus_effect', {
        description: 'Add an audio effect to an audio bus',
        inputSchema: {
            bus_name: Name.describe('Audio bus name'),
            effect_type: z
                .enum([
                'reverb',
                'delay',
                'chorus',
                'compressor',
                'distortion',
                'eq',
                'limiter',
                'panner',
                'pitchshift',
                'filter',
                'lowpass',
                'highpass',
                'bandpass',
                'notch',
                'spectrum',
                'amplify',
                'stereo',
                'eq6',
                'eq10',
                'eq21',
            ])
                .describe('Effect type'),
            index: z.number().int().optional().describe('Effect insertion position on the bus'),
            properties: OptionalProperties.describe('Effect properties'),
        },
    }, async (args) => callGodot(bridge, 'audio/add_bus_effect', args));
    // 5. set_audio_bus
    server.registerTool('set_audio_bus', {
        description: 'Configure audio bus properties (volume, mute, solo, bypass)',
        inputSchema: {
            bus_name: Name.describe('Audio bus name'),
            properties: Properties.describe('Bus properties (volume_db, mute, solo, bypass, etc.)'),
            send: z.string().optional().describe('Bus name to send output to'),
        },
    }, async (args) => callGodot(bridge, 'audio/set_bus', args));
    // 6. get_audio_bus_layout
    server.registerTool('get_audio_bus_layout', {
        description: 'Get the current audio bus layout with all buses and their effects',
        inputSchema: {},
    }, async () => callGodot(bridge, 'audio/get_bus_layout'));
    // 7. get_audio_info
    server.registerTool('get_audio_info', {
        description: 'Get information about an audio node (player type, stream, playback state)',
        inputSchema: {
            path: NodePath.describe('Audio node path'),
        },
    }, async (args) => callGodot(bridge, 'audio/get_info', args));
}
//# sourceMappingURL=audio.js.map