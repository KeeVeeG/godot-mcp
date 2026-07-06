/**
 * Resource configuration tools - 6 tools for resource type introspection and import
 */
import { callGodot } from '../server.js';
import { z, ResourcePath, Properties, OptionalProperties } from './shared-types.js';
export function registerResourceConfigTools(server, bridge) {
    // 1. get_resource_types
    server.registerTool('get_resource_types', {
        description: 'Get all registered resource types in the engine',
        inputSchema: {},
    }, async () => callGodot(bridge, 'resource_config/get_types'));
    // 2. get_resource_properties
    server.registerTool('get_resource_properties', {
        description: 'Get all serializable properties for a resource type with their types',
        inputSchema: {
            type: z.string().describe("Resource type name (e.g. 'Texture2D', 'AudioStream', 'PackedScene')"),
        },
    }, async (args) => callGodot(bridge, 'resource_config/get_properties', args));
    // 3. create_resource_from_template
    server.registerTool('create_resource_from_template', {
        description: 'Create a new resource file from a template or with default values',
        inputSchema: {
            type: z.string().describe("Resource type to create (e.g. 'StandardMaterial3D', 'Theme')"),
            template: z.string().optional().describe('Template resource path to copy from'),
            path: ResourcePath.describe("Output path (e.g. 'res://materials/my_material.tres')"),
        },
    }, async (args) => callGodot(bridge, 'resource_config/create_from_template', args));
    // 4. import_resource
    server.registerTool('import_resource', {
        description: 'Import a file as a resource with optional import settings',
        inputSchema: {
            path: ResourcePath.describe("File path to import (e.g. 'res://assets/model.fbx')"),
            settings: OptionalProperties,
        },
    }, async (args) => callGodot(bridge, 'resource_config/import', args));
    // 5. get_resource_import_settings
    server.registerTool('get_resource_import_settings', {
        description: 'Get the current import settings for a resource file',
        inputSchema: {
            path: ResourcePath,
        },
    }, async (args) => callGodot(bridge, 'resource_config/get_resource_import_settings', args));
    // 6. set_resource_import_settings
    server.registerTool('set_resource_import_settings', {
        description: 'Update import settings for a resource file and reimport',
        inputSchema: {
            path: ResourcePath,
            settings: Properties.describe('Import settings to apply'),
        },
    }, async (args) => callGodot(bridge, 'resource_config/set_resource_import_settings', args));
}
//# sourceMappingURL=resource_config.js.map