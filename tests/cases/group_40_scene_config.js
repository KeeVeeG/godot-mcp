// Group 40: Scene Config (6 tools)
module.exports = {
  name: 'SceneConfig',
  setup: async (t) => {
    await t.callTool('create_scene', {
      path: 'res://_verify_scfg_scene.tscn',
      root_node_type: 'Node2D',
    });
    await t.callTool('open_scene', { path: 'res://_verify_scfg_scene.tscn' });
    await t.callTool('add_node', {
      parent_path: '.',
      type: 'Node2D',
      name: '_ScCfgNode',
    });
    await t.sleep(500);
  },
  teardown: async (t) => {
    await t.callTool('save_scene', {});
    await t.callTool('delete_scene', { path: 'res://_verify_scfg_scene.tscn' });
  },
  tests: [
    {
      tool: 'get_scene_inheritance',
      args: { scene_path: 'res://_verify_scfg_scene.tscn' },
      description: 'Get scene inheritance',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'set_scene_unique_name',
      args: { node_path: '_ScCfgNode', unique: true },
      description: 'Set scene unique name',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'get_scene_groups',
      args: { scene_path: 'res://_verify_scfg_scene.tscn' },
      description: 'Get scene groups',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'set_scene_group',
      args: { node_path: '_ScCfgNode', group: '_verify_scfg_group', add: true },
      description: 'Set scene group',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'get_scene_meta',
      args: { scene_path: 'res://_verify_scfg_scene.tscn' },
      description: 'Get scene meta',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'set_scene_meta',
      args: { key: '_verify_meta_key', value: '_verify_meta_value' },
      description: 'Set scene meta',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
  ],
};
