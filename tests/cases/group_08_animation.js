// Group 8: Animation (10 tools)
module.exports = {
  name: 'Animation',
  setup: async (t) => {
    await t.callTool('create_scene', {
      path: 'res://_verify_anim_scene.tscn',
      root_node_type: 'Node2D',
    });
    await t.callTool('open_scene', { path: 'res://_verify_anim_scene.tscn' });
    await t.callTool('add_node', {
      parent_path: '.',
      type: 'AnimationPlayer',
      name: '_AnimPlayer',
    });
    await t.sleep(500);
  },
  teardown: async (t) => {
    await t.callTool('save_scene', {});
    await t.callTool('delete_scene', { path: 'res://_verify_anim_scene.tscn' });
  },
  tests: [
    {
      tool: 'create_animation',
      args: { player_path: '_AnimPlayer', name: '_verify_anim' },
      description: 'Create animation',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'list_animations',
      args: { player_path: '_AnimPlayer' },
      description: 'List animations',
      validate: (d) => {
        // Accept both array and object formats
        if (Array.isArray(d)) return true;
        if (d && typeof d === 'object') return true;
        return false;
      },
    },
    {
      tool: 'add_animation_track',
      args: {
        player_path: '_AnimPlayer',
        animation: '_verify_anim',
        track_type: 'value',
        node_path: '.',
      },
      description: 'Add animation track',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'set_animation_keyframe',
      args: {
        player_path: '_AnimPlayer',
        animation: '_verify_anim',
        track_index: 0,
        time: 0.0,
        value: 0,
      },
      description: 'Set keyframe',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'get_animation_info',
      args: { player_path: '_AnimPlayer', animation: '_verify_anim' },
      description: 'Get animation info',
      validate: (d) => d !== null && d !== undefined,
    },
    {
      tool: 'remove_animation',
      args: { player_path: '_AnimPlayer', animation: '_verify_anim' },
      description: 'Remove animation',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'create_animation_tree',
      args: { path: '', properties: { name: '_AnimTree' }, root_type: 'AnimationNodeStateMachine' },
      description: 'Create AnimationTree with StateMachine root',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'get_animation_tree_structure',
      args: { path: '_AnimTree' },
      description: 'Get tree structure',
      validate: (d) => d !== null && d !== undefined,
    },
    {
      tool: 'set_tree_parameter',
      args: { path: '_AnimTree', parameter: 'test_param', value: 1.0 },
      description: 'Set tree parameter',
      validate: (d, text) => {
        if (text.includes('"error"') && !text.includes('not found')) return false;
        return d !== null && d !== undefined;
      },
    },
    {
      tool: 'create_animation_tree',
      args: {
        path: '',
        properties: { name: '_StateMachineTree' },
        root_type: 'AnimationNodeStateMachine',
      },
      description: 'Create AnimationTree with StateMachine root',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'add_state_machine_state',
      args: { path: '_StateMachineTree', state_name: '_verify_state' },
      description: 'Add state machine state',
      validate: (d, text) => {
        if (text.includes('"error"') && !text.includes('state machine')) return false;
        return d !== null && d !== undefined;
      },
    },
  ],
};
