/**
 * Physics configuration tools - 8 tools for physics engine settings
 */
import { callGodot } from '../server.js';
import { z } from './shared-types.js';
export function registerPhysicsConfigTools(server, bridge) {
    // 1. get_physics_settings
    server.registerTool('get_physics_settings', {
        description: 'Get all physics engine settings (gravity, FPS, engine, layers, damping)',
        inputSchema: {},
    }, async () => callGodot(bridge, 'physics_config/get_settings'));
    // 2. set_gravity
    server.registerTool('set_gravity', {
        description: 'Set the default gravity vector for the physics world (choose 2D or 3D dimension)',
        inputSchema: {
            dimension: z.enum(['2d', '3d']).describe('Physics dimension: "2d" or "3d" (required)'),
            x: z
                .number()
                .refine((v) => Number.isFinite(v), 'Gravity component must be a finite number')
                .describe('Gravity X component'),
            y: z
                .number()
                .refine((v) => Number.isFinite(v), 'Gravity component must be a finite number')
                .describe('Gravity Y component'),
            z: z
                .number()
                .refine((v) => Number.isFinite(v), 'Gravity component must be a finite number')
                .optional()
                .default(0)
                .describe('Gravity Z component (for 3D, default 0)'),
        },
    }, async (args) => callGodot(bridge, 'physics_config/set_gravity', args));
    // 3. set_physics_fps
    server.registerTool('set_physics_fps', {
        description: 'Set the physics simulation tick rate',
        inputSchema: {
            fps: z.number().int({ message: 'FPS must be a whole number (integer)' }).optional().default(60).describe('Physics ticks per second (default 60)'),
        },
    }, async (args) => callGodot(bridge, 'physics_config/set_fps', args));
    // 4. set_physics_engine
    server.registerTool('set_physics_engine', {
        description: 'Set which physics engine backend to use for a specific dimension (choose 2D or 3D)',
        inputSchema: {
            dimension: z.enum(['2d', '3d']).describe('Physics dimension: "2d" or "3d" (required)'),
            engine: z.enum(['default', 'godot_physics', 'jolt']).describe('Physics engine backend'),
        },
    }, async (args) => callGodot(bridge, 'physics_config/set_engine', args));
    // 5. set_collision_layer_name
    server.registerTool('set_collision_layer_name', {
        description: 'Assign a human-readable name to a collision layer (1-32)',
        inputSchema: {
            layer: z.number().int().describe('Layer number (1-32)'),
            name: z.string().min(1, 'Layer name must not be empty').describe("Layer name (e.g. 'Player', 'Enemies', 'Terrain')"),
        },
    }, async (args) => callGodot(bridge, 'physics_config/set_layer_name', args));
    // 6. get_collision_layers
    server.registerTool('get_collision_layers', {
        description: 'Get all collision layer names (1-32)',
        inputSchema: {},
    }, async () => callGodot(bridge, 'physics_config/get_layers'));
    // 7. set_default_gravity
    server.registerTool('set_default_gravity', {
        description: 'Set the default gravity magnitude for a specific dimension (choose 2D or 3D)',
        inputSchema: {
            dimension: z.enum(['2d', '3d']).describe('Physics dimension: "2d" or "3d" (required)'),
            value: z
                .number()
                .min(0, 'Gravity magnitude must be non-negative')
                .refine((v) => Number.isFinite(v), 'Gravity magnitude must be a finite number')
                .describe('Gravity value (980.0 for 2D, 9.8 for 3D)'),
        },
    }, async (args) => callGodot(bridge, 'physics_config/set_default_gravity', args));
    // 8. set_default_linear_damp
    server.registerTool('set_default_linear_damp', {
        description: 'Set the default linear damping for physics bodies in a specific dimension (choose 2D or 3D)',
        inputSchema: {
            dimension: z.enum(['2d', '3d']).describe('Physics dimension: "2d" or "3d" (required)'),
            value: z
                .number()
                .min(0)
                .refine((v) => Number.isFinite(v), 'Damping value must be a finite number')
                .optional()
                .default(0.1)
                .describe('Linear damping value (default 0.1)'),
        },
    }, async (args) => callGodot(bridge, 'physics_config/set_default_linear_damp', args));
}
//# sourceMappingURL=physics_config.js.map