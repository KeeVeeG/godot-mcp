// Group 29: Gameplay Automation (7 tools) — requires open scene with nodes
module.exports = {
  name: 'GameplayAutomation',
  setup: async (t) => {
    // Create a test scene with a child Node2D for navigate/assert tests
    await t.callTool('create_scene', {
      path: 'res://_verify_gameplay_scene.tscn',
      root_node_type: 'Node2D',
    });
    await t.callTool('open_scene', { path: 'res://_verify_gameplay_scene.tscn' });
    await t.callTool('add_node', {
      parent_path: '.',
      type: 'Node2D',
      name: '_VerifyChar',
    });
    await t.callTool('save_scene', {});
    // Create a separate character scene for create_test_character
    await t.callTool('create_scene', {
      path: 'res://_verify_character.tscn',
      root_node_type: 'Node2D',
    });
    await t.callTool('save_scene', {});
    // Switch back to main scene
    await t.callTool('open_scene', { path: 'res://_verify_gameplay_scene.tscn' });
    await t.sleep(500);
  },
  teardown: async (t) => {
    await t.callTool('save_scene', {});
    await t.callTool('delete_scene', { path: 'res://_verify_gameplay_scene.tscn' });
    await t.callTool('delete_scene', { path: 'res://_verify_character.tscn' });
  },
  tests: [
    {
      tool: 'simulate_gameplay_scenario',
      args: { scenario: [{ action: 'wait', params: { seconds: 0.1 } }] },
      description: 'Simulate gameplay scenario',
      validate: (d) => d?.passed > 0 || d?.steps?.length > 0,
    },
    {
      tool: 'record_gameplay',
      args: { duration: 1, include_input: true, include_state: false },
      description: 'Record gameplay (editor mode, 0 events expected)',
      validate: (d) => d?.success === true || d?.events_recorded !== undefined,
    },
    {
      tool: 'replay_gameplay',
      args: { recording_path: 'user://mcp_recordings/nonexistent.rec' },
      description: 'Replay gameplay (no recording file — expects not found)',
      validate: (d, text) => d?.error?.includes('not found') || text.includes('not found') || text.includes('Failed to'),
    },
    {
      tool: 'create_test_character',
      args: {
        scene_path: 'res://_verify_character.tscn',
        position: [100, 100, 0],
      },
      description: 'Create test character',
      validate: (d) => d?.name !== undefined || d?.success === true,
    },
    {
      tool: 'navigate_character',
      args: { character_path: '_VerifyChar', target: [200, 200, 0] },
      description: 'Navigate character',
      validate: (d) => d?.success === true,
    },
    {
      tool: 'assert_game_state',
      args: {
        conditions: [{ path: '_VerifyChar', property: 'visible', expected: true, operator: '==' }],
      },
      description: 'Assert game state',
      validate: (d) => d?.passed === true || d?.passed_count > 0,
    },
    {
      tool: 'wait_for_game_event',
      args: { event: 'node:_VerifyChar', timeout: 200 },
      description: 'Wait for game event (node already exists)',
      validate: (d) => d?.found === true || d?.event !== undefined,
    },
  ],
};
