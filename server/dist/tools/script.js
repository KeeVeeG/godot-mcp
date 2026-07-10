/**
 * Script tools - 10 tools for script management
 */
import { callGodot } from '../server.js';
import { z, ScriptPath, NodePath, GDScriptCode, SearchQuery } from './shared-types.js';
export function registerScriptTools(server, bridge) {
    // 1. list_scripts
    server.registerTool('list_scripts', {
        description: 'List all GDScript files in the project with class info',
        inputSchema: {
            max_depth: z.number().int().positive().optional().default(10).describe('Maximum directory depth to scan (default: 10)'),
        },
    }, async (args) => callGodot(bridge, 'script/list', args));
    // 2. read_script
    server.registerTool('read_script', {
        description: 'Read the contents of a GDScript file',
        inputSchema: {
            path: ScriptPath,
        },
    }, async (args) => callGodot(bridge, 'script/read', args));
    // 3. create_script
    server.registerTool('create_script', {
        description: 'Create a new GDScript file',
        inputSchema: {
            path: ScriptPath.describe("Path for the new script (e.g. 'res://scripts/player.gd')"),
            content: GDScriptCode.describe('GDScript source code'),
            base_class: z.string().optional().describe("Base class (e.g. 'CharacterBody2D')"),
        },
    }, async (args) => callGodot(bridge, 'script/create', args));
    // 4. delete_script
    server.registerTool('delete_script', {
        description: 'Delete a GDScript file from the project',
        inputSchema: {
            path: ScriptPath.describe('Script file path to delete'),
            force: z.boolean().optional().describe('Force delete even if script is attached to nodes'),
        },
    }, async (args) => callGodot(bridge, 'script/delete', args));
    // 5. edit_script
    server.registerTool('edit_script', {
        description: 'Edit an existing GDScript file by replacing a text segment',
        inputSchema: {
            path: ScriptPath,
            old_text: z.string().describe('Exact text to find and replace'),
            new_text: z.string().describe('Replacement text'),
        },
    }, async (args) => callGodot(bridge, 'script/edit', args));
    // 6. attach_script
    server.registerTool('attach_script', {
        description: 'Attach a GDScript to a node in the scene',
        inputSchema: {
            script_path: ScriptPath.describe('Script file path to attach'),
            node_path: NodePath.describe("Node to attach script to (e.g. 'Player' or '' for scene root)"),
        },
    }, async (args) => callGodot(bridge, 'script/attach', args));
    // 7. detach_script
    server.registerTool('detach_script', {
        description: 'Detach a script from a node (sets script to null)',
        inputSchema: {
            node_path: NodePath.describe('Node to detach script from'),
        },
    }, async (args) => callGodot(bridge, 'script/detach', args));
    // 8. get_open_scripts
    server.registerTool('get_open_scripts', {
        description: 'Get list of scripts currently open in the script editor',
        inputSchema: {},
    }, async () => callGodot(bridge, 'script/get_open'));
    // 9. validate_script
    server.registerTool('validate_script', {
        description: 'Validate a GDScript file for syntax errors',
        inputSchema: {
            path: ScriptPath.describe('Script file path to validate'),
        },
    }, async (args) => callGodot(bridge, 'script/validate', args));
    // 10. search_in_files
    server.registerTool('search_in_files', {
        description: 'Search for text across project files',
        inputSchema: {
            query: SearchQuery,
            file_pattern: z.string().optional().describe("File pattern to search in (e.g. '*.gd')"),
        },
    }, async (args) => callGodot(bridge, 'script/search_in_files', args));
}
//# sourceMappingURL=script.js.map