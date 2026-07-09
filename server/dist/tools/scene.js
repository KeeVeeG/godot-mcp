/**
 * Scene tools - 13 tools for scene management
 */
import { callGodot } from '../server.js';
import { z, ScenePath } from './shared-types.js';
export function registerSceneTools(server, bridge) {
    // 1. get_scene_tree
    server.registerTool('get_scene_tree', {
        description: 'Get the node tree of the specified or currently open scene',
        inputSchema: {
            max_depth: z.number().int().positive().optional().default(15).describe('Maximum tree depth to serialize (default: 15)'),
        },
    }, async (args) => callGodot(bridge, 'scene/get_tree', args));
    // 2. get_scene_file_content
    server.registerTool('get_scene_file_content', {
        description: 'Read the raw .tscn/.scn file content of a scene',
        inputSchema: {
            path: ScenePath,
        },
    }, async (args) => callGodot(bridge, 'scene/get_file_content', args));
    // 3. create_scene
    server.registerTool('create_scene', {
        description: 'Create a new empty scene with a specified root node type',
        inputSchema: {
            path: ScenePath.describe("Path to save the scene (e.g. 'res://scenes/new.tscn')"),
            root_node_type: z.string().optional().describe("Root node type (e.g. 'Node2D', 'Control')"),
            overwrite: z.boolean().optional().describe('Allow overwriting an existing scene file'),
        },
    }, async (args) => callGodot(bridge, 'scene/create', args));
    // 4. open_scene
    server.registerTool('open_scene', {
        description: 'Open a scene file in the editor',
        inputSchema: {
            path: ScenePath.describe('Scene file path to open'),
        },
    }, async (args) => callGodot(bridge, 'scene/open', args));
    // 5. delete_scene
    server.registerTool('delete_scene', {
        description: 'Delete a scene file from the project',
        inputSchema: {
            path: ScenePath.describe('Scene file path to delete'),
            force: z.boolean().optional().describe('Force close and delete if scene is currently open'),
        },
    }, async (args) => callGodot(bridge, 'scene/delete', args));
    // 6. add_scene_instance
    server.registerTool('add_scene_instance', {
        description: 'Add an instance of a scene as a child of a node in the current scene',
        inputSchema: {
            scene_path: ScenePath.describe('Path to the scene to instantiate'),
            parent_path: z.string().optional().describe('Parent node path, defaults to scene root'),
        },
    }, async (args) => callGodot(bridge, 'scene/add_instance', args));
    // 7. play_scene
    server.registerTool('play_scene', {
        description: 'Start playing the current or specified scene. Required before using any runtime tools (get_game_*, capture_frames, etc.)',
        inputSchema: {
            mode: z.enum(['main', 'current', 'custom']).optional().describe("Play mode: 'main' (main scene), 'current' (open scene), or 'custom' (specified by scene_path)"),
            scene_path: z.string().optional().describe("Scene to play when mode is 'custom'"),
        },
    }, async (args) => callGodot(bridge, 'scene/play', args));
    // 8. stop_scene
    server.registerTool('stop_scene', {
        description: 'Stop the currently playing scene',
        inputSchema: {},
    }, async () => callGodot(bridge, 'scene/stop'));
    // 9. save_scene
    server.registerTool('save_scene', {
        description: 'Save the current scene or save it to a new path',
        inputSchema: {
            path: z.string().optional().describe('Path of the scene to save (defaults to current)'),
            save_as: z.boolean().optional().describe('Allow saving to a different path (save as copy)'),
        },
    }, async (args) => callGodot(bridge, 'scene/save', args));
    // 10. get_loaded_scenes
    server.registerTool('get_loaded_scenes', {
        description: 'Get a list of all currently loaded scenes in the editor',
        inputSchema: {},
    }, async () => callGodot(bridge, 'scene/get_loaded'));
    // 11. set_main_scene
    server.registerTool('set_main_scene', {
        description: "Set the project's main scene",
        inputSchema: {
            path: ScenePath.describe('Scene file path to set as main scene'),
        },
    }, async (args) => callGodot(bridge, 'scene/set_main', args));
    // 12. get_main_scene
    server.registerTool('get_main_scene', {
        description: 'Get the project main scene path',
        inputSchema: {},
    }, async () => callGodot(bridge, 'scene/get_main', {}));
    // 13. close_scene
    server.registerTool('close_scene', {
        description: 'Close the currently edited scene in the editor',
        inputSchema: {},
    }, async () => callGodot(bridge, 'scene/close'));
}
//# sourceMappingURL=scene.js.map