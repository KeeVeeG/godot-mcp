/**
 * Scene3D tools - 12 tools for 3D scene manipulation and inspection
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, NodePath, ParentPath, Properties, OptionalProperties } from './shared-types.js';

export function registerScene3dTools(server: McpServer, bridge: GodotBridge): void {
  // 1. add_mesh_instance
  server.registerTool(
    'add_mesh_instance',
    {
      description: 'Add a MeshInstance3D with a primitive mesh type',
      inputSchema: {
        parent: ParentPath,
        mesh_type: z.enum(['cube', 'sphere', 'cylinder', 'capsule', 'plane', 'prism', 'torus']).describe('Primitive mesh type'),
        properties: OptionalProperties.describe('Mesh properties (size, material_path, etc.)'),
      },
    },
    async (args) => callGodot(bridge, 'scene3d/add_mesh', args as Record<string, unknown>),
  );

  // 2. get_mesh_instance
  server.registerTool(
    'get_mesh_instance',
    {
      description: 'Get properties of a MeshInstance3D node (mesh type, size, material)',
      inputSchema: {
        path: NodePath.describe('MeshInstance3D node path'),
      },
    },
    async (args) => callGodot(bridge, 'scene3d/get_mesh', args as Record<string, unknown>),
  );

  // 3. setup_camera_3d
  server.registerTool(
    'setup_camera_3d',
    {
      description: 'Add and configure a Camera3D node',
      inputSchema: {
        path: NodePath.optional().default('').describe('Camera node path (leave empty to create a new Camera3D)'),
        properties: Properties.describe('Camera properties (fov, near, far, position, look_at, make_current, etc.)'),
      },
    },
    async (args) => callGodot(bridge, 'scene3d/setup_camera', args as Record<string, unknown>),
  );

  // 4. get_camera_3d
  server.registerTool(
    'get_camera_3d',
    {
      description: 'Get Camera3D properties (fov, near, far, current, transform)',
      inputSchema: {
        path: NodePath.describe('Camera3D node path'),
      },
    },
    async (args) => callGodot(bridge, 'scene3d/get_camera', args as Record<string, unknown>),
  );

  // 5. setup_lighting
  server.registerTool(
    'setup_lighting',
    {
      description: 'Add a light node (DirectionalLight3D, OmniLight3D, SpotLight3D)',
      inputSchema: {
        parent: ParentPath,
        type: z.enum(['omni', 'spot', 'directional']).describe('Light type'),
        properties: OptionalProperties.describe('Light properties (color, energy, position, shadow_enabled, etc.)'),
      },
    },
    async (args) => callGodot(bridge, 'scene3d/setup_lighting', args as Record<string, unknown>),
  );

  // 6. get_lighting
  server.registerTool(
    'get_lighting',
    {
      description: 'Get Light3D properties (type, color, energy, shadow_enabled, transform)',
      inputSchema: {
        path: NodePath.describe('Light3D node path'),
      },
    },
    async (args) => callGodot(bridge, 'scene3d/get_lighting', args as Record<string, unknown>),
  );

  // 7. setup_environment
  server.registerTool(
    'setup_environment',
    {
      description: 'Configure the WorldEnvironment for the 3D scene',
      inputSchema: {
        path: NodePath.optional().default('').describe('WorldEnvironment node path (leave empty for auto-create/find)'),
        properties: Properties.describe('Environment properties (background_mode, background_color, ambient_light_color, fog_enabled, glow_enabled, etc.)'),
      },
    },
    async (args) => callGodot(bridge, 'scene3d/setup_environment', args as Record<string, unknown>),
  );

  // 8. get_environment
  server.registerTool(
    'get_environment',
    {
      description: 'Get WorldEnvironment settings (background, ambient, fog, glow, SSAO, tonemap)',
      inputSchema: {
        path: NodePath.optional().default('').describe('WorldEnvironment node path (leave empty for first found)'),
      },
    },
    async (args) => callGodot(bridge, 'scene3d/get_environment', args as Record<string, unknown>),
  );

  // 9. add_gridmap
  server.registerTool(
    'add_gridmap',
    {
      description: 'Add a GridMap node for 3D tile-based level design',
      inputSchema: {
        parent: ParentPath,
        properties: OptionalProperties.describe('GridMap properties (mesh_library_path, cell_size, etc.)'),
      },
    },
    async (args) => callGodot(bridge, 'scene3d/add_gridmap', args as Record<string, unknown>),
  );

  // 10. get_gridmap
  server.registerTool(
    'get_gridmap',
    {
      description: 'Get GridMap node properties (cell_size, mesh_library)',
      inputSchema: {
        path: NodePath.describe('GridMap node path'),
      },
    },
    async (args) => callGodot(bridge, 'scene3d/get_gridmap', args as Record<string, unknown>),
  );

  // 11. set_material_3d
  server.registerTool(
    'set_material_3d',
    {
      description: 'Create and apply a StandardMaterial3D or ShaderMaterial to a mesh',
      inputSchema: {
        path: NodePath.describe('MeshInstance3D node path'),
        properties: Properties.describe('Material properties (albedo_color, metallic, roughness, shader_path, etc.)'),
      },
    },
    async (args) => callGodot(bridge, 'scene3d/set_material', args as Record<string, unknown>),
  );

  // 12. get_material_3d
  server.registerTool(
    'get_material_3d',
    {
      description: 'Get material properties from a 3D mesh node',
      inputSchema: {
        path: NodePath.describe('MeshInstance3D or VisualInstance3D node path'),
      },
    },
    async (args) => callGodot(bridge, 'scene3d/get_material', args as Record<string, unknown>),
  );
}
