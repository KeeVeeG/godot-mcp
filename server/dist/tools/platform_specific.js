/**
 * Platform-specific tools - 6 tools for platform configuration and validation
 */
import { callGodot } from '../server.js';
import { z, OptionalProperties } from './shared-types.js';
export function registerPlatformSpecificTools(server, bridge) {
    // 1. get_platform_settings
    server.registerTool('get_platform_settings', {
        description: 'Get platform-specific settings for a target platform',
        inputSchema: {
            platform: z.string().describe("Platform name (e.g. 'ios', 'android', 'web', 'windows', 'linux', 'macos')"),
        },
    }, async (args) => callGodot(bridge, 'get_platform_settings', args));
    // 2. configure_ios
    server.registerTool('configure_ios', {
        description: 'Configure iOS-specific project settings including bundle ID, team ID, and code signing',
        inputSchema: {
            settings: z
                .object({
                bundle_id: z.string().optional().describe('iOS bundle identifier (e.g. com.company.game)'),
                team_id: z.string().optional().describe('Apple Developer Team ID'),
                signing: OptionalProperties.describe('Code signing configuration'),
            })
                .describe('iOS settings to configure'),
        },
    }, async (args) => callGodot(bridge, 'configure_ios', args));
    // 3. configure_android
    server.registerTool('configure_android', {
        description: 'Configure Android-specific project settings including package name, keystore, and permissions',
        inputSchema: {
            settings: z
                .object({
                package_name: z.string().optional().describe('Android package name (e.g. com.company.game)'),
                keystore: OptionalProperties.describe('Keystore configuration for signing'),
                permissions: z.array(z.string()).optional().describe('Android permissions to declare'),
            })
                .describe('Android settings to configure'),
        },
    }, async (args) => callGodot(bridge, 'configure_android', args));
    // 4. configure_web
    server.registerTool('configure_web', {
        description: 'Configure web/HTML5 export settings including canvas resize, threading, and PWA support',
        inputSchema: {
            settings: z
                .object({
                canvas_resize: z.boolean().optional().describe('Enable automatic canvas resizing'),
                threading: z.boolean().optional().describe('Enable SharedArrayBuffer threading support'),
                pwa: z.boolean().optional().describe('Enable Progressive Web App support'),
            })
                .describe('Web platform settings to configure'),
        },
    }, async (args) => callGodot(bridge, 'configure_web', args));
    // 5. get_platform_capabilities
    server.registerTool('get_platform_capabilities', {
        description: 'Get the available features and capabilities for a specific platform',
        inputSchema: {
            platform: z.string().describe('Platform name to query capabilities for'),
        },
    }, async (args) => callGodot(bridge, 'get_platform_capabilities', args));
    // 6. validate_platform_build
    server.registerTool('validate_platform_build', {
        description: 'Validate the project for building on a specific platform, checking for issues',
        inputSchema: {
            platform: z.string().describe('Platform to validate the build for'),
        },
    }, async (args) => callGodot(bridge, 'validate_platform_build', args));
}
//# sourceMappingURL=platform_specific.js.map