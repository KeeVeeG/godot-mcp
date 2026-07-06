// Group 17: Audio (6 tools)
const BUS_NAME = `_VerifyBus_${Date.now()}`;
module.exports = {
  name: 'Audio',
  setup: async (t) => {
    await t.callTool('create_scene', {
      path: 'res://_verify_audio_scene.tscn',
      root_node_type: 'Node2D',
    });
    await t.callTool('open_scene', { path: 'res://_verify_audio_scene.tscn' });
    await t.sleep(500);
  },
  teardown: async (t) => {
    await t.callTool('save_scene', {});
    await t.callTool('delete_scene', {
      path: 'res://_verify_audio_scene.tscn',
    });
  },
  tests: [
    {
      tool: 'add_audio_player',
      args: { parent: '.', properties: { name: '_TestAudio' } },
      description: 'Add audio player',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'add_audio_bus',
      args: { name: BUS_NAME },
      description: 'Add audio bus',
      validate: (d, text) => (d !== null && d !== undefined) || text.includes('already exists'),
    },
    {
      tool: 'set_audio_bus',
      args: {
        bus_name: BUS_NAME,
        properties: { volume_db: -6.0, mute: false, solo: false },
      },
      description: 'Set audio bus',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'add_audio_bus_effect',
      args: { bus_name: BUS_NAME, effect_type: 'reverb' },
      description: 'Add audio bus effect',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'get_audio_bus_layout',
      description: 'Get audio bus layout',
      validate: (d) => {
        if (d === null || d === undefined) return false;
        const buses = Array.isArray(d) ? d : d?.buses;
        return Array.isArray(buses);
      },
    },
    {
      tool: 'get_audio_info',
      args: { path: '_TestAudio' },
      description: 'Get audio info',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'add_audio_player',
      args: { parent: '.', properties: { name: '_RemoveTestAudio' } },
      description: 'Add audio player for removal test',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'remove_audio_player',
      args: { node_path: '_RemoveTestAudio' },
      description: 'Remove audio player',
      validate: (d, text) => !text.includes('"error"'),
    },
  ],
};
