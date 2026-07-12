/**
 * Particles tools - 12 tools for particle system management
 */
import { callGodot } from '../server.js';
import { z, NodePath, ParentPath, Dimension, Properties, OptionalProperties } from './shared-types.js';
export function registerParticlesTools(server, bridge) {
    // 1. create_particles
    server.registerTool('create_particles', {
        description: 'Create a GPUParticles2D or GPUParticles3D node',
        inputSchema: {
            parent: ParentPath,
            type: Dimension,
            properties: OptionalProperties,
        },
    }, async (args) => callGodot(bridge, 'particles/create', args));
    // 8. delete_particles
    server.registerTool('delete_particles', {
        description: 'Delete a particle system node from the scene',
        inputSchema: {
            node_path: z
                .string()
                .min(1, 'Node path cannot be empty for delete')
                .refine((s) => !s.includes('..'), { message: 'Node path must not contain path traversal (..)' })
                .describe('Path to the particle node to delete'),
        },
    }, async (args) => callGodot(bridge, 'particles/delete', args));
    // 2. set_particle_material
    server.registerTool('set_particle_material', {
        description: 'Set or create a ParticleProcessMaterial for a particle system',
        inputSchema: {
            path: NodePath.describe('Particle node path'),
            properties: Properties.describe('Process material properties (direction, spread, gravity, initial_velocity, etc.)'),
        },
    }, async (args) => callGodot(bridge, 'particles/set_material', args));
    // 3. set_particle_color_gradient
    server.registerTool('set_particle_color_gradient', {
        description: 'Set a color gradient on a particle system',
        inputSchema: {
            path: NodePath.describe('Particle node path'),
            gradient: z
                .array(z.object({
                offset: z.number().min(0).max(1).describe('Gradient position (0-1)'),
                color: z
                    .string()
                    .regex(/^#[0-9A-Fa-f]{8}$/, "Color must be hex format #RRGGBBAA (e.g. '#FF0000FF')")
                    .describe("Color as hex (e.g. '#FF0000FF')"),
            }))
                .min(1, 'Gradient array must have at least one color stop')
                .describe('Gradient color stops'),
        },
    }, async (args) => callGodot(bridge, 'particles/set_color_gradient', args));
    // 4. apply_particle_preset
    server.registerTool('apply_particle_preset', {
        description: 'Apply a predefined particle effect preset',
        inputSchema: {
            path: NodePath.describe('Particle node path'),
            preset: z.enum(['fire', 'smoke', 'sparks', 'rain', 'snow']).describe('Particle preset name'),
        },
    }, async (args) => callGodot(bridge, 'particles/apply_preset', args));
    // 5. get_particle_info
    server.registerTool('get_particle_info', {
        description: "Get information about a particle system's configuration",
        inputSchema: {
            path: NodePath.describe('Particle node path'),
        },
    }, async (args) => callGodot(bridge, 'particles/get_info', args));
    // 6. set_particle_emission_shape
    server.registerTool('set_particle_emission_shape', {
        description: 'Set the emission shape for a particle system',
        inputSchema: {
            path: NodePath.describe('Particle node path'),
            shape: z.enum(['point', 'sphere', 'box', 'ring']).describe('Emission shape type'),
            size: z.array(z.number()).min(1).max(3).optional().describe('Shape size parameters (1-3 elements depending on shape)'),
            properties: z.record(z.unknown()).optional().describe('Shape-specific properties (radius, height, inner_radius, etc.)'),
        },
    }, async (args) => callGodot(bridge, 'particles/set_emission_shape', args));
    // 7. set_particle_velocity_curve
    server.registerTool('set_particle_velocity_curve', {
        description: 'Set a velocity curve for a particle system',
        inputSchema: {
            path: NodePath.describe('Particle node path'),
            curve: z
                .array(z.object({
                offset: z.number().min(0).max(1).describe('Curve position (0-1)'),
                value: z.number().describe('Velocity value at this point'),
            }))
                .min(1, 'Curve array must have at least one velocity point')
                .describe('Curve points'),
        },
    }, async (args) => callGodot(bridge, 'particles/set_velocity_curve', args));
    // 9. get_particle_material
    server.registerTool('get_particle_material', {
        description: 'Read ParticleProcessMaterial properties from a particle system',
        inputSchema: {
            path: NodePath.describe('Particle node path'),
        },
    }, async (args) => callGodot(bridge, 'particles/get_material', args));
    // 10. get_particle_color_gradient
    server.registerTool('get_particle_color_gradient', {
        description: 'Read the color gradient (color ramp) from a particle system',
        inputSchema: {
            path: NodePath.describe('Particle node path'),
        },
    }, async (args) => callGodot(bridge, 'particles/get_color_gradient', args));
    // 11. get_particle_emission_shape
    server.registerTool('get_particle_emission_shape', {
        description: "Read the emission shape configuration from a particle system's process material",
        inputSchema: {
            path: NodePath.describe('Particle node path'),
        },
    }, async (args) => callGodot(bridge, 'particles/get_emission_shape', args));
    // 12. get_particle_velocity_curve
    server.registerTool('get_particle_velocity_curve', {
        description: "Read the velocity limit curve from a particle system's process material",
        inputSchema: {
            path: NodePath.describe('Particle node path'),
        },
    }, async (args) => callGodot(bridge, 'particles/get_velocity_curve', args));
}
//# sourceMappingURL=particles.js.map