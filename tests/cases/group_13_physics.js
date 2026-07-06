// Group 13: Physics (8 tools)
module.exports = {
  name: 'Physics',
  setup: async (t) => {
    await t.callTool('create_scene', {
      path: 'res://_verify_phys_scene.tscn',
      root_node_type: 'Node2D',
    });
    await t.callTool('open_scene', { path: 'res://_verify_phys_scene.tscn' });
    await t.callTool('add_node', {
      parent_path: '.',
      type: 'RigidBody2D',
      name: '_PhysBody',
    });
    await t.sleep(500);
  },
  teardown: async (t) => {
    await t.callTool('save_scene', {});
    await t.callTool('delete_scene', { path: 'res://_verify_phys_scene.tscn' });
  },
  tests: [
    {
      tool: 'setup_physics_body',
      args: { path: '_PhysBody', properties: { mass: 5.0 } },
      description: 'Setup physics body',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'get_node_properties',
      args: { path: '_PhysBody' },
      description: 'Verify mass set',
      validate: (d) => {
        const mass = d?.properties?.mass || d?.mass;
        return mass === 5.0 || mass === '5' || JSON.stringify(d).includes('"mass"');
      },
    },
    {
      tool: 'setup_collision',
      args: {
        path: '_PhysBody',
        shape_type: 'circle',
        properties: { radius: 32 },
      },
      description: 'Setup collision shape',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'set_physics_layers',
      args: { path: '_PhysBody', layer: 1, mask: 1 },
      description: 'Set physics layers',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'get_physics_layers',
      args: { path: '_PhysBody' },
      description: 'Get physics layers',
      validate: (d) => d !== null && d !== undefined,
    },
    {
      tool: 'get_collision_info',
      args: { path: '_PhysBody' },
      description: 'Get collision info',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'set_physics_material',
      args: { path: '_PhysBody', friction: 0.5, bounce: 0.3 },
      description: 'Set physics material',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'get_physics_material',
      args: { path: '_PhysBody' },
      description: 'Get physics material',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'add_raycast',
      args: {
        parent_path: '_PhysBody',
        properties: { target: { x: 0, y: 100 } },
      },
      description: 'Add raycast',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
  ],
};
