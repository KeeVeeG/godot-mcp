/**
 * Particles tools - 8 tools for particle system management
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, NodePath, ParentPath, Dimension, Properties, OptionalProperties } from './shared-types.js';

export function registerParticlesTools(server: McpServer, bridge: GodotBridge): void {
  // 1. create_particles
  server.registerTool(
    'create_particles',
    {
      description: 'Create a GPUParticles2D or GPUParticles3D node',
      inputSchema: {
        parent: ParentPath,
        type: Dimension,
        properties: OptionalProperties,
      },
    },
    async (args) => callGodot(bridge, 'particles/create', args as Record<string, unknown>),
  );

  // 8. delete_particles
  server.registerTool(
    'delete_particles',
    {
      description: 'Delete a particle system node from the scene',
      inputSchema: {
        node_path: NodePath.describe('Path to the particle node to delete'),
      },
    },
    async (args) => callGodot(bridge, 'particles/delete', args as Record<string, unknown>),
  );

  // 2. set_particle_material
  server.registerTool(
    'set_particle_material',
    {
      description: 'Set or create a ParticleProcessMaterial for a particle system',
      inputSchema: {
        path: NodePath.describe('Particle node path'),
        properties: Properties.describe('Process material properties (direction, spread, gravity, initial_velocity, etc.)'),
      },
    },
    async (args) => callGodot(bridge, 'particles/set_material', args as Record<string, unknown>),
  );

  // 3. set_particle_color_gradient
  server.registerTool(
    'set_particle_color_gradient',
    {
      description: 'Set a color gradient on a particle system',
      inputSchema: {
        path: NodePath.describe('Particle node path'),
        gradient: z
          .array(
            z.object({
              offset: z.number().min(0).max(1).describe('Gradient position (0-1)'),
              color: z.string().describe("Color as hex (e.g. '#FF0000FF')"),
            }),
          )
          .describe('Gradient color stops'),
      },
    },
    async (args) => callGodot(bridge, 'particles/set_color_gradient', args as Record<string, unknown>),
  );

  // 4. apply_particle_preset
  server.registerTool(
    'apply_particle_preset',
    {
      description: 'Apply a predefined particle effect preset',
      inputSchema: {
        path: NodePath.describe('Particle node path'),
        preset: z.enum(['fire', 'smoke', 'sparks', 'rain', 'snow']).describe('Particle preset name'),
      },
    },
    async (args) => callGodot(bridge, 'particles/apply_preset', args as Record<string, unknown>),
  );

  // 5. get_particle_info
  server.registerTool(
    'get_particle_info',
    {
      description: "Get information about a particle system's configuration",
      inputSchema: {
        path: NodePath.describe('Particle node path'),
      },
    },
    async (args) => callGodot(bridge, 'particles/get_info', args as Record<string, unknown>),
  );

  // 6. set_particle_emission_shape
  server.registerTool(
    'set_particle_emission_shape',
    {
      description: 'Set the emission shape for a particle system',
      inputSchema: {
        path: NodePath.describe('Particle node path'),
        shape: z.enum(['point', 'sphere', 'box', 'ring']).describe('Emission shape type'),
        size: z.array(z.number()).optional().describe('Shape size parameters'),
      },
    },
    async (args) => callGodot(bridge, 'particles/set_emission_shape', args as Record<string, unknown>),
  );

  // 7. set_particle_velocity_curve
  server.registerTool(
    'set_particle_velocity_curve',
    {
      description: 'Set a velocity curve for a particle system',
      inputSchema: {
        path: NodePath.describe('Particle node path'),
        curve: z
          .array(
            z.object({
              offset: z.number().min(0).max(1).describe('Curve position (0-1)'),
              value: z.number().describe('Velocity value at this point'),
            }),
          )
          .describe('Curve points'),
      },
    },
    async (args) => callGodot(bridge, 'particles/set_velocity_curve', args as Record<string, unknown>),
  );
}
