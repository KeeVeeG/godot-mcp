/**
 * Physics configuration tools - 8 tools for physics engine settings
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, Name } from './shared-types.js';

export function registerPhysicsConfigTools(server: McpServer, bridge: GodotBridge): void {
  // 1. get_physics_settings
  server.registerTool(
    'get_physics_settings',
    {
      description: 'Get all physics engine settings (gravity, FPS, engine, layers, damping)',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'physics_config/get_settings'),
  );

  // 2. set_gravity
  server.registerTool(
    'set_gravity',
    {
      description: 'Set the default gravity vector for the physics world',
      inputSchema: {
        x: z.number().describe('Gravity X component'),
        y: z.number().describe('Gravity Y component'),
        z: z.number().optional().default(0).describe('Gravity Z component (for 3D, default 0)'),
      },
    },
    async (args) => callGodot(bridge, 'physics_config/set_gravity', args as Record<string, unknown>),
  );

  // 3. set_physics_fps
  server.registerTool(
    'set_physics_fps',
    {
      description: 'Set the physics simulation tick rate',
      inputSchema: {
        fps: z.number().int().min(1).max(240).optional().default(60).describe('Physics ticks per second (default 60)'),
      },
    },
    async (args) => callGodot(bridge, 'physics_config/set_fps', args as Record<string, unknown>),
  );

  // 4. set_physics_engine
  server.registerTool(
    'set_physics_engine',
    {
      description: 'Set which physics engine backend to use',
      inputSchema: {
        engine: z.enum(['default', 'godot_physics', 'jolt']).describe('Physics engine backend'),
      },
    },
    async (args) => callGodot(bridge, 'physics_config/set_engine', args as Record<string, unknown>),
  );

  // 5. set_collision_layer_name
  server.registerTool(
    'set_collision_layer_name',
    {
      description: 'Assign a human-readable name to a collision layer (1-32)',
      inputSchema: {
        layer: z.number().int().min(1).max(32).describe('Layer number (1-32)'),
        name: Name.describe("Layer name (e.g. 'Player', 'Enemies', 'Terrain')"),
      },
    },
    async (args) => callGodot(bridge, 'physics_config/set_layer_name', args as Record<string, unknown>),
  );

  // 6. get_collision_layers
  server.registerTool(
    'get_collision_layers',
    {
      description: 'Get all collision layer names (1-32)',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'physics_config/get_layers'),
  );

  // 7. set_default_gravity
  server.registerTool(
    'set_default_gravity',
    {
      description: 'Set the default gravity magnitude in project settings',
      inputSchema: {
        value: z.number().describe('Gravity value (980.0 for 2D, 9.8 for 3D)'),
      },
    },
    async (args) => callGodot(bridge, 'physics_config/set_default_gravity', args as Record<string, unknown>),
  );

  // 8. set_default_linear_damp
  server.registerTool(
    'set_default_linear_damp',
    {
      description: 'Set the default linear damping for physics bodies',
      inputSchema: {
        value: z.number().min(0).optional().default(0.1).describe('Linear damping value (default 0.1)'),
      },
    },
    async (args) => callGodot(bridge, 'physics_config/set_default_linear_damp', args as Record<string, unknown>),
  );
}
