// Group 15: Particles (7 tools)
module.exports = {
  name: 'Particles',
  setup: async (t) => {
    await t.callTool('create_scene', {
      path: 'res://_verify_particles_scene.tscn',
      root_node_type: 'Node2D',
    });
    await t.callTool('open_scene', {
      path: 'res://_verify_particles_scene.tscn',
    });
    await t.sleep(500);
  },
  teardown: async (t) => {
    await t.callTool('save_scene', {});
    await t.callTool('delete_scene', {
      path: 'res://_verify_particles_scene.tscn',
    });
  },
  tests: [
    {
      tool: 'create_particles',
      args: { parent: '.', type: '2d', properties: { name: '_TestParticles' } },
      description: 'Create particles',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'set_particle_material',
      args: { path: '_TestParticles', properties: {} },
      description: 'Set particle material',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'set_particle_color_gradient',
      args: {
        path: '_TestParticles',
        gradient: [
          { offset: 0, color: '#FF0000FF' },
          { offset: 1, color: '#0000FFFF' },
        ],
      },
      description: 'Set particle color gradient',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'apply_particle_preset',
      args: { path: '_TestParticles', preset: 'fire' },
      description: 'Apply particle preset',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'set_particle_emission_shape',
      args: { path: '_TestParticles', shape: 'sphere', size: [50] },
      description: 'Set emission shape',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'set_particle_velocity_curve',
      args: {
        path: '_TestParticles',
        curve: [
          { offset: 0, value: 0 },
          { offset: 1, value: 100 },
        ],
      },
      description: 'Set velocity curve',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'get_particle_info',
      args: { path: '_TestParticles' },
      description: 'Get particle info',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'create_particles',
      args: { parent: '.', type: '2d', properties: { name: '_TestParticlesToDelete' } },
      description: 'Create particles for deletion test',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'delete_particles',
      args: { node_path: '_TestParticlesToDelete' },
      description: 'Delete particles',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
  ],
};
