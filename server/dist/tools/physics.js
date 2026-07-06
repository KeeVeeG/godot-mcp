/**
 * Physics tools - 8 tools for physics setup
 */
import { callGodot } from '../server.js';
import { z, NodePath, ParentPath, Properties, OptionalProperties } from './shared-types.js';
export function registerPhysicsTools(server, bridge) {
    // 1. setup_physics_body
    server.registerTool('setup_physics_body', {
        description: 'Add and configure a physics body on a node',
        inputSchema: {
            path: NodePath.describe('Node to add the physics body to'),
            properties: Properties.describe('Body properties (mass, gravity_scale, etc.)'),
        },
    }, async (args) => callGodot(bridge, 'physics/setup_body', args));
    // 2. setup_collision
    server.registerTool('setup_collision', {
        description: 'Add and configure a collision shape on a node',
        inputSchema: {
            path: NodePath.describe('Node to add collision to'),
            shape_type: z.enum(['box', 'sphere', 'capsule', 'cylinder', 'convex', 'concave', 'polygon', 'circle', 'rectangle']).describe('Collision shape type'),
            properties: OptionalProperties.describe('Shape properties (size, radius, height, etc.)'),
        },
    }, async (args) => callGodot(bridge, 'physics/setup_collision', args));
    // 3. set_physics_layers
    server.registerTool('set_physics_layers', {
        description: 'Set physics collision layers and masks on a node',
        inputSchema: {
            path: NodePath.describe('Node with collision object'),
            layer: z.number().int().min(1).max(32).optional().describe('Collision layer (1-32)'),
            mask: z.number().int().min(1).max(32).optional().describe('Collision mask (1-32)'),
        },
    }, async (args) => callGodot(bridge, 'physics/set_layers', args));
    // 4. get_physics_layers
    server.registerTool('get_physics_layers', {
        description: 'Get physics layer and mask information for a node',
        inputSchema: {
            path: NodePath.describe('Node with collision object'),
        },
    }, async (args) => callGodot(bridge, 'physics/get_layers', args));
    // 5. get_collision_info
    server.registerTool('get_collision_info', {
        description: 'Get collision information for a physics body',
        inputSchema: {
            path: NodePath.describe('Physics body node path'),
        },
    }, async (args) => callGodot(bridge, 'physics/get_collision_info', args));
    // 6. add_raycast
    server.registerTool('add_raycast', {
        description: 'Add a RayCast2D or RayCast3D node',
        inputSchema: {
            parent_path: ParentPath.describe("Parent node — '' for scene root"),
            properties: OptionalProperties.describe('Raycast properties (target, enabled, collide_with_areas, etc.)'),
        },
    }, async (args) => callGodot(bridge, 'physics/add_raycast', args));
    // 7. get_physics_material
    server.registerTool('get_physics_material', {
        description: 'Get the physics material properties of a node',
        inputSchema: {
            path: NodePath,
        },
    }, async (args) => callGodot(bridge, 'physics/get_material', args));
    // 8. set_physics_material
    server.registerTool('set_physics_material', {
        description: 'Create and set a physics material on a node',
        inputSchema: {
            path: NodePath,
            friction: z.number().min(0).optional().describe('Friction coefficient'),
            bounce: z.number().min(0).max(1).optional().describe('Bounce/Restitution coefficient'),
            rough: z.boolean().optional().describe('Whether surface is rough'),
            absorbent: z.boolean().optional().describe('Whether the surface absorbs impact energy'),
        },
    }, async (args) => callGodot(bridge, 'physics/set_material', args));
}
//# sourceMappingURL=physics.js.map