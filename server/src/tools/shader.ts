/**
 * Shader tools - 9 tools for shader management
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, NodePath, FilePath, PropertyValue, SearchQuery } from './shared-types.js';

export function registerShaderTools(server: McpServer, bridge: GodotBridge): void {
  // 1. create_shader
  server.registerTool(
    'create_shader',
    {
      description: 'Create a new Shader resource',
      inputSchema: {
        path: FilePath.describe("File path for the shader (e.g. 'res://shaders/outline.gdshader')"),
        type: z
          .enum(['visual', 'spatial', 'canvas_item', 'particles', 'sky', 'fog', 'texture_blit'])
          .optional()
          .default('canvas_item')
          .describe('Shader type: visual/canvas_item (2D), spatial (3D), particles, sky, fog, texture_blit (default: canvas_item)'),
        content: z.string().optional().describe('Initial shader code'),
      },
    },
    async (args) => callGodot(bridge, 'shader/create', args as Record<string, unknown>),
  );

  // 2. read_shader
  server.registerTool(
    'read_shader',
    {
      description: 'Read the contents of a shader file',
      inputSchema: {
        path: FilePath.describe('Shader file path'),
      },
    },
    async (args) => callGodot(bridge, 'shader/read', args as Record<string, unknown>),
  );

  // 3. edit_shader
  server.registerTool(
    'edit_shader',
    {
      description: 'Edit a shader file by replacing old_text with new_text',
      inputSchema: {
        path: FilePath.describe('Shader file path'),
        old_text: z.string().describe('Text to find and replace'),
        new_text: z.string().describe('Replacement text'),
      },
    },
    async (args) => callGodot(bridge, 'shader/edit', args as Record<string, unknown>),
  );

  // 4. assign_shader_material
  server.registerTool(
    'assign_shader_material',
    {
      description: "Create a ShaderMaterial and assign it to a node's material property",
      inputSchema: {
        node_path: NodePath.describe('Node path to assign the material to'),
        shader_path: FilePath.describe('Shader resource path'),
      },
    },
    async (args) => callGodot(bridge, 'shader/assign_material', args as Record<string, unknown>),
  );

  // 5. set_shader_param
  server.registerTool(
    'set_shader_param',
    {
      description: 'Set a shader parameter (uniform) on a ShaderMaterial',
      inputSchema: {
        node_path: NodePath.describe('Node path with the ShaderMaterial'),
        param: z.string().describe('Shader uniform name'),
        value: PropertyValue.describe('Parameter value'),
      },
    },
    async (args) => callGodot(bridge, 'shader/set_param', args as Record<string, unknown>),
  );

  // 6. get_shader_params
  server.registerTool(
    'get_shader_params',
    {
      description: 'Get all shader parameters (uniforms) and their current values',
      inputSchema: {
        node_path: NodePath.describe('Node path with the ShaderMaterial'),
      },
    },
    async (args) => callGodot(bridge, 'shader/get_params', args as Record<string, unknown>),
  );

  // 7. list_shaders
  server.registerTool(
    'list_shaders',
    {
      description: 'List all shader files in the project',
      inputSchema: {
        filter: SearchQuery.optional().describe('Filter by path pattern'),
      },
    },
    async (args) => callGodot(bridge, 'shader/list', args as Record<string, unknown>),
  );

  // 8. validate_shader
  server.registerTool(
    'validate_shader',
    {
      description: 'Validate a shader file for compilation errors',
      inputSchema: {
        path: FilePath.describe('Shader file path'),
      },
    },
    async (args) => callGodot(bridge, 'shader/validate', args as Record<string, unknown>),
  );

  // 9. delete_shader
  server.registerTool(
    'delete_shader',
    {
      description: 'Delete a shader file from the project',
      inputSchema: {
        path: z.string().describe('Shader file path to delete (e.g. res://shaders/my_shader.gdshader)'),
      },
    },
    async (args) => callGodot(bridge, 'shader/delete', args as Record<string, unknown>),
  );
}
