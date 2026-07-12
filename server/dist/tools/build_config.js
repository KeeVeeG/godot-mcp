/**
 * Build configuration tools - 8 tools for build/export settings
 */
import { callGodot } from '../server.js';
import { z } from './shared-types.js';
export function registerBuildConfigTools(server, bridge) {
    // 1. get_build_settings
    server.registerTool('get_build_settings', {
        description: 'Get all build configuration settings (debug/release, scripting backend, features)',
        inputSchema: {},
    }, async () => callGodot(bridge, 'build_config/get_settings'));
    // 2. set_build_configuration
    server.registerTool('set_build_configuration', {
        description: 'Set the build configuration preset',
        inputSchema: {
            config: z
                .enum(['debug', 'release', 'development'])
                .optional()
                .default('debug')
                .describe('Build configuration (debug: full symbols, release: optimized, development: release with debug) (default: debug)'),
        },
    }, async (args) => callGodot(bridge, 'build_config/set_configuration', args));
    // 3. set_scripting_backend
    server.registerTool('set_scripting_backend', {
        description: 'Set the scripting backend for the project',
        inputSchema: {
            backend: z
                .enum(['gdscript', 'csharp', 'visual_script'])
                .optional()
                .default('gdscript')
                .describe('Scripting language backend: gdscript, csharp, or visual_script (note: VisualScript was removed in Godot 4.0) (default: gdscript)'),
        },
    }, async (args) => callGodot(bridge, 'build_config/set_scripting_backend', args));
    // 4. set_export_filter
    server.registerTool('set_export_filter', {
        description: 'Set which resources to include in exports',
        inputSchema: {
            filter: z
                .enum(['all_resources', 'selected_resources', 'selected_classes'])
                .optional()
                .default('all_resources')
                .describe('Export filter mode: all_resources, selected_resources, or selected_classes (default: all_resources)'),
        },
    }, async (args) => callGodot(bridge, 'build_config/set_export_filter', args));
    // 5. set_custom_features
    server.registerTool('set_custom_features', {
        description: 'Set custom feature tags for conditional compilation and export',
        inputSchema: {
            features: z.array(z.string()).optional().default([]).describe("List of custom feature tags (e.g. ['demo', 'mobile', 'premium'])"),
        },
    }, async (args) => callGodot(bridge, 'build_config/set_custom_features', args));
    // 6. set_debug_options
    server.registerTool('set_debug_options', {
        description: 'Configure debug and optimization options',
        inputSchema: {
            debug_build: z.boolean().optional().describe('Enable debug build (includes symbols)'),
            release_debug: z.boolean().optional().describe('Release build with debug info'),
            optimize: z.boolean().optional().describe('Enable optimizations'),
        },
    }, async (args) => callGodot(bridge, 'build_config/set_debug_options', args));
    // 7. validate_build_settings
    server.registerTool('validate_build_settings', {
        description: 'Validate current build settings and return any errors or warnings',
        inputSchema: {},
    }, async () => callGodot(bridge, 'build_config/validate'));
    // 8. get_build_command
    server.registerTool('get_build_command', {
        description: 'Get the CLI command to export/build the project for a specific platform',
        inputSchema: {
            platform: z.string().min(1).describe('Target platform (e.g. windows, linux, web, android, macos, ios)'),
        },
    }, async (args) => callGodot(bridge, 'build_config/get_build_command', args));
}
//# sourceMappingURL=build_config.js.map