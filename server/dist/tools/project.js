/**
 * Project tools - 8 tools for project management
 */
import { callGodot } from '../server.js';
import { z, ResourcePath, SearchQuery } from './shared-types.js';
export function registerProjectTools(server, bridge) {
    // 1. get_project_info
    server.registerTool('get_project_info', {
        description: 'Get project metadata including name, version, engine version, and main scene',
        inputSchema: {},
    }, async () => callGodot(bridge, 'project/get_info'));
    // 2. get_filesystem_tree
    server.registerTool('get_filesystem_tree', {
        description: 'Get the project filesystem tree structure',
        inputSchema: {
            path: ResourcePath.describe("Root path to list from (e.g. 'res://')"),
            filters: z.array(z.string()).optional().describe("Array of file extensions to filter (e.g. ['gd', 'tscn'])"),
            max_depth: z.number().int().min(0).optional().default(10).describe('Maximum recursion depth (default: 10)'),
        },
    }, async (args) => callGodot(bridge, 'project/get_filesystem_tree', args));
    // 3. search_files
    server.registerTool('search_files', {
        description: 'Search for files in the project by name pattern or content. Supports glob patterns (*, ?) for filename search. Set search_content=true to also search inside file contents.',
        inputSchema: {
            query: SearchQuery,
            search_content: z.boolean().optional().default(true).describe('Whether to search inside file contents (default: true). Set to false for filename-only search.'),
            max_results: z.number().int().positive().optional().default(50).describe('Maximum number of results (default: 50)'),
        },
    }, async (args) => callGodot(bridge, 'project/search_files', args));
    // 4. get_project_settings
    server.registerTool('get_project_settings', {
        description: 'Get all project settings (project.godot values)',
        inputSchema: {
            filter: z.string().optional().describe("Prefix filter for settings (e.g. 'application/')"),
            max_results: z.number().int().min(0).optional().default(0).describe('Maximum number of settings to return (default: 0 = no limit). Increase to get more, or use filter to narrow results.'),
        },
    }, async (args) => callGodot(bridge, 'project/get_settings', args));
    // 5. set_project_setting
    server.registerTool('set_project_setting', {
        description: 'Set a project setting value',
        inputSchema: {
            key: z.string().describe("Setting key (e.g. 'display/window/size/viewport_width')"),
            value: z.unknown().describe('New value for the setting (string, number, boolean, etc.)'),
        },
    }, async (args) => callGodot(bridge, 'project/set_setting', args));
    // 6. remove_project_setting
    server.registerTool('remove_project_setting', {
        description: 'Remove a project setting from project.godot. Use this instead of passing null to set_project_setting.',
        inputSchema: {
            key: z.string().describe("ProjectSettings key to remove (e.g. 'application/config/name')"),
        },
    }, async (args) => callGodot(bridge, 'project/remove_setting', args));
    // 7. uid_to_project_path
    server.registerTool('uid_to_project_path', {
        description: 'Convert a Godot UID to a project file path',
        inputSchema: {
            uid: z.string().describe("The UID to look up (e.g. 'uid://abc123')"),
        },
    }, async (args) => callGodot(bridge, 'project/uid_to_path', args));
    // 8. project_path_to_uid
    server.registerTool('project_path_to_uid', {
        description: 'Convert a project file path to its UID',
        inputSchema: {
            path: ResourcePath.describe("The project path (e.g. 'res://scenes/main.tscn')"),
        },
    }, async (args) => callGodot(bridge, 'project/path_to_uid', args));
}
//# sourceMappingURL=project.js.map