// Group 18: Batch (8 tools)
module.exports = {
  name: 'Batch',
  setup: async (t) => {
    await t.callTool('create_scene', {
      path: 'res://_verify_batch_scene.tscn',
      root_node_type: 'Node2D',
    });
    await t.callTool('open_scene', { path: 'res://_verify_batch_scene.tscn' });
    await t.callTool('add_node', {
      parent_path: '.',
      type: 'Node2D',
      name: '_BatchNode1',
    });
    await t.callTool('add_node', {
      parent_path: '.',
      type: 'Node2D',
      name: '_BatchNode2',
    });
    // Save scene so cross_scene_set_property can read it from disk
    await t.callTool('save_scene', {});
    await t.sleep(500);
  },
  teardown: async (t) => {
    await t.callTool('save_scene', {});
    await t.callTool('delete_scene', {
      path: 'res://_verify_batch_scene.tscn',
    });
  },
  tests: [
    {
      tool: 'find_nodes_by_type',
      args: { type_name: 'Node2D' },
      description: 'Find nodes by type',
      validate: (d) => {
        const nodes = Array.isArray(d) ? d : d?.nodes;
        return nodes && nodes.length > 0;
      },
    },
    {
      tool: 'batch_set_property',
      args: { type_name: 'Node2D', property: 'visible', value: true },
      description: 'Batch set property',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'find_signal_connections',
      description: 'Find signal connections',
      validate: (d) => {
        if (d === null || d === undefined) return false;
        const conns = Array.isArray(d) ? d : d?.connections;
        return Array.isArray(conns);
      },
    },
    {
      tool: 'find_node_references',
      args: { query: '_BatchNode1' },
      description: 'Find node references',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'get_scene_dependencies',
      args: { path: 'res://_verify_batch_scene.tscn' },
      description: 'Get scene dependencies',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'cross_scene_set_property',
      args: {
        type_name: 'Node2D',
        property: 'visible',
        value: false,
        scenes: ['res://_verify_batch_scene.tscn'],
      },
      description: 'Cross scene set property',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'find_script_references',
      args: { script_path: 'res://_verify_script.gd' },
      description: 'Find script references',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'detect_circular_dependencies',
      description: 'Detect circular dependencies',
      validate: (d) => {
        if (d === null || d === undefined) return false;
        const cycles = Array.isArray(d) ? d : d?.circular || d?.cycles;
        return Array.isArray(cycles);
      },
    },
  ],
};
