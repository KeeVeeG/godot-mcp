/**
 * Scene configuration tools - 6 tools for scene metadata and properties
 */
import { callGodot } from '../server.js';
import { z, NodePath, OptionalScenePath } from './shared-types.js';
export function registerSceneConfigTools(server, bridge) {
    // 1. get_scene_inheritance
    server.registerTool('get_scene_inheritance', {
        description: 'Get the scene inheritance chain (instantiated scenes, inherited scenes)',
        inputSchema: {
            scene_path: OptionalScenePath.describe('Scene file path (empty for current scene)'),
        },
    }, async (args) => callGodot(bridge, 'scene_config/get_inheritance', args));
    // 2. set_scene_unique_name
    server.registerTool('set_scene_unique_name', {
        description: 'Toggle the unique name flag on a node (accessible as %NodeName)',
        inputSchema: {
            node_path: NodePath.describe('Node path within the scene'),
            unique: z.boolean().optional().default(true).describe('Enable (true) or disable (false) unique name (default: true)'),
        },
    }, async (args) => callGodot(bridge, 'scene_config/set_unique_name', args));
    // 3. get_scene_groups
    server.registerTool('get_scene_groups', {
        description: 'Get all groups used in a scene and which nodes belong to each',
        inputSchema: {
            scene_path: OptionalScenePath.describe('Scene file path (empty for current scene)'),
        },
    }, async (args) => callGodot(bridge, 'scene_config/get_groups', args));
    // 4. set_scene_group
    server.registerTool('set_scene_group', {
        description: 'Add or remove a node from a group',
        inputSchema: {
            node_path: NodePath.describe('Node path within the current scene'),
            group: z.string().describe('Group name'),
            add: z.boolean().optional().default(true).describe('true to add to group, false to remove (default: true)'),
        },
    }, async (args) => callGodot(bridge, 'scene_config/set_group', args));
    // 5. get_scene_meta
    server.registerTool('get_scene_meta', {
        description: "Get metadata stored on a scene's root node",
        inputSchema: {
            scene_path: OptionalScenePath.describe('Scene file path (empty for current scene)'),
        },
    }, async (args) => callGodot(bridge, 'scene_config/get_meta', args));
    // 6. set_scene_meta
    server.registerTool('set_scene_meta', {
        description: "Set metadata on the current scene's root node",
        inputSchema: {
            scene_path: z.string().optional().describe('Omit or pass empty string — only the current scene is supported'),
            key: z.string().describe('Metadata key'),
            value: z.unknown().describe('Metadata value (string, number, bool, array, or dict)'),
        },
    }, async (args) => callGodot(bridge, 'scene_config/set_meta', args));
}
//# sourceMappingURL=scene_config.js.map