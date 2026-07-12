/**
 * Resource tools - 9 tools for resource management
 */
import { callGodot } from '../server.js';
import { z, ResourcePath, Properties, OptionalProperties } from './shared-types.js';
export function registerResourceTools(server, bridge) {
    // 1. read_resource
    server.registerTool('read_resource', {
        description: 'Read a Godot resource file and get its properties',
        inputSchema: {
            path: ResourcePath,
        },
    }, async (args) => callGodot(bridge, 'resource/read', args));
    // 2. edit_resource
    server.registerTool('edit_resource', {
        description: 'Edit properties of an existing resource',
        inputSchema: {
            path: ResourcePath,
            properties: Properties.describe('Properties to set'),
        },
    }, async (args) => callGodot(bridge, 'resource/edit', args));
    // 3. create_resource
    server.registerTool('create_resource', {
        description: 'Create a new Godot resource',
        inputSchema: {
            type: z.string().optional().describe("Resource type (e.g. 'StyleBoxFlat', 'Gradient', 'Curve') — primary param"),
            resource_type: z.string().optional().describe("Resource type (fallback alias for 'type')"),
            path: ResourcePath,
            properties: OptionalProperties,
        },
    }, async (args) => callGodot(bridge, 'resource/create', args));
    // 10. delete_resource
    server.registerTool('delete_resource', {
        description: 'Delete a Godot resource file from the project',
        inputSchema: {
            path: ResourcePath.describe('Resource file path to delete'),
        },
    }, async (args) => callGodot(bridge, 'resource/delete', args));
    // 4. get_resource_preview
    server.registerTool('get_resource_preview', {
        description: 'Get a preview thumbnail of a resource',
        inputSchema: {
            path: ResourcePath,
        },
    }, async (args) => callGodot(bridge, 'resource/get_preview', args));
    // 5. add_autoload
    server.registerTool('add_autoload', {
        description: 'Add an autoload singleton to the project',
        inputSchema: {
            name: z.string().describe('Autoload name (becomes a global singleton)'),
            path: ResourcePath.describe('Script or scene path'),
        },
    }, async (args) => callGodot(bridge, 'resource/add_autoload', args));
    // 6. remove_autoload
    server.registerTool('remove_autoload', {
        description: 'Remove an autoload singleton from the project',
        inputSchema: {
            name: z.string().describe('Autoload name to remove'),
        },
    }, async (args) => callGodot(bridge, 'resource/remove_autoload', args));
    // 7. duplicate_resource
    server.registerTool('duplicate_resource', {
        description: 'Duplicate a resource file',
        inputSchema: {
            source_path: ResourcePath.describe('Source resource path'),
            dest_path: z.string().describe('Destination path'),
        },
    }, async (args) => callGodot(bridge, 'resource/duplicate', args));
    // 8. list_resources
    server.registerTool('list_resources', {
        description: 'List resources of a specific type in the project',
        inputSchema: {
            type: z.string().optional().describe('Resource type to filter by'),
            directory: z.string().optional().describe('Directory to search in'),
        },
    }, async (args) => callGodot(bridge, 'resource/list', args));
    // 9. get_resource_dependencies
    server.registerTool('get_resource_dependencies', {
        description: 'Get all dependencies of a resource file',
        inputSchema: {
            path: ResourcePath,
        },
    }, async (args) => callGodot(bridge, 'resource/get_dependencies', args));
}
//# sourceMappingURL=resource.js.map