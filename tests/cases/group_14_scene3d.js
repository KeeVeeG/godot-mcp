// Group 14: Scene3D (6 tools)
module.exports = {
  name: 'Scene3D',
  setup: async (t) => {
    await t.callTool('create_scene', {
      path: 'res://_verify_3d_scene.tscn',
      root_node_type: 'Node3D',
    });
    await t.callTool('open_scene', { path: 'res://_verify_3d_scene.tscn' });
    await t.sleep(500);
  },
  teardown: async (t) => {
    await t.callTool('save_scene', {});
    await t.callTool('delete_scene', { path: 'res://_verify_3d_scene.tscn' });
  },
  tests: [
    {
      tool: 'add_mesh_instance',
      args: {
        parent: '.',
        mesh_type: 'cube',
        properties: { name: '_TestMesh' },
      },
      description: 'Add mesh instance',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'setup_camera_3d',
      args: { path: '', properties: { position: [0, 5, 10], fov: 75 } },
      description: 'Setup camera 3D',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'setup_lighting',
      args: {
        parent: '.',
        type: 'directional',
        properties: { light_energy: 1.0 },
      },
      description: 'Setup lighting',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'setup_environment',
      args: { path: '', properties: {} },
      description: 'Setup environment',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'set_material_3d',
      args: { path: '_TestMesh', properties: { albedo_color: [1, 0, 0, 1] } },
      description: 'Set material 3D',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'add_gridmap',
      args: { parent: '.', properties: { name: '_TestGridMap' } },
      description: 'Add GridMap',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
  ],
};
