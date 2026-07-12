/**
 * Rendering configuration tools - 10 tools for rendering settings
 */
import { callGodot } from '../server.js';
import { z, Quality, Size2D } from './shared-types.js';
export function registerRenderingConfigTools(server, bridge) {
    // 1. get_rendering_settings
    server.registerTool('get_rendering_settings', {
        description: 'Get all current rendering settings (renderer, quality, viewport, etc.)',
        inputSchema: {},
    }, async () => callGodot(bridge, 'rendering_config/get_settings'));
    // 2. set_rendering_quality
    server.registerTool('set_rendering_quality', {
        description: 'Apply a rendering quality preset (sets multiple settings at once)',
        inputSchema: {
            quality: Quality,
        },
    }, async (args) => callGodot(bridge, 'rendering_config/set_quality', args));
    // 3. set_renderer
    server.registerTool('set_renderer', {
        description: 'Set the rendering method/renderer for the project',
        inputSchema: {
            renderer: z.enum(['forward_plus', 'mobile', 'gl_compatibility']).describe('Rendering backend to use'),
        },
    }, async (args) => callGodot(bridge, 'rendering_config/set_renderer', args));
    // 4. set_anti_aliasing
    server.registerTool('set_anti_aliasing', {
        description: 'Configure anti-aliasing settings (MSAA, FXAA, TAA)',
        inputSchema: {
            msaa: z.enum(['2x', '4x', '8x']).optional().describe('MSAA level (or omit to disable)'),
            fxaa: z.boolean().optional().describe('Enable/disable FXAA'),
            taa: z.boolean().optional().describe('Enable/disable TAA'),
        },
    }, async (args) => callGodot(bridge, 'rendering_config/set_anti_aliasing', args));
    // 5. set_shadow_quality
    server.registerTool('set_shadow_quality', {
        description: 'Set shadow rendering quality preset',
        inputSchema: {
            quality: Quality.describe('Shadow quality level'),
        },
    }, async (args) => callGodot(bridge, 'rendering_config/set_shadow_quality', args));
    // 6. set_gi_quality
    server.registerTool('set_gi_quality', {
        description: 'Set global illumination quality preset',
        inputSchema: {
            quality: Quality.describe('GI quality level'),
        },
    }, async (args) => callGodot(bridge, 'rendering_config/set_gi_quality', args));
    // 7.5. set_post_processing
    server.registerTool('set_post_processing', {
        description: 'Configure post-processing effects (bloom, SSAO, SSR, glow, DOF)',
        inputSchema: {
            bloom_intensity: z.number().min(0).max(2).optional().describe('Bloom intensity (0-2)'),
            ssao_enabled: z.boolean().optional().describe('Enable Screen Space Ambient Occlusion'),
            ssr_enabled: z.boolean().optional().describe('Enable Screen Space Reflections'),
            glow_enabled: z.boolean().optional().describe('Enable glow effect'),
            dof_enabled: z.boolean().optional().describe('Enable depth of field'),
            msaa: z.enum(['disabled', '2x', '4x', '8x']).optional().describe('MSAA level'),
            fxaa_enabled: z.boolean().optional().describe('Enable Fast Approximate Anti-Aliasing'),
            taa_enabled: z.boolean().optional().describe('Enable Temporal Anti-Aliasing'),
        },
    }, async (args) => callGodot(bridge, 'rendering_config/set_post_processing', args));
    // 8. set_viewport_size
    server.registerTool('set_viewport_size', {
        description: 'Set the game viewport dimensions and stretch settings',
        inputSchema: {
            width: z.number().int().positive().describe('Viewport width in pixels'),
            height: z.number().int().positive().describe('Viewport height in pixels'),
            stretch_mode: z.enum(['disabled', 'canvas_items', 'viewport']).optional().describe('Stretch mode'),
            stretch_aspect: z.enum(['ignore', 'keep', 'keep_width', 'keep_height', 'expand']).optional().describe('Stretch aspect ratio behavior'),
        },
    }, async (args) => callGodot(bridge, 'rendering_config/set_viewport_size', args));
    // 9. set_window_settings
    server.registerTool('set_window_settings', {
        description: 'Configure the application window size, mode, and vsync',
        inputSchema: {
            size: Size2D.optional().describe('Window size [width, height]'),
            mode: z.enum(['windowed', 'fullscreen', 'exclusive_fullscreen']).optional().describe('Window display mode'),
            vsync: z.boolean().optional().describe('Enable/disable vertical sync'),
        },
    }, async (args) => callGodot(bridge, 'rendering_config/set_window_settings', args));
    // 10. get_rendering_info
    server.registerTool('get_rendering_info', {
        description: 'Get GPU info, VRAM usage, draw calls, and rendering statistics',
        inputSchema: {},
    }, async () => callGodot(bridge, 'rendering_config/get_rendering_info'));
}
//# sourceMappingURL=rendering_config.js.map