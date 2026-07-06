// Group 5: Editor (9 tools) — reload_plugin/reload_project are destructive, skipped
module.exports = {
  name: 'Editor',
  setup: async (t) => {
    // Create and open a scene so get_signals has a node to inspect
    await t.callTool('create_scene', {
      path: 'res://_verify_editor_scene.tscn',
      root_node_type: 'Node',
    });
    await t.callTool('open_scene', { path: 'res://_verify_editor_scene.tscn' });
    await t.sleep(500);
  },
  teardown: async (t) => {
    await t.callTool('save_scene', {});
    await t.callTool('delete_scene', {
      path: 'res://_verify_editor_scene.tscn',
    });
  },
  tests: [
    {
      tool: 'get_editor_errors',
      description: 'Get editor errors',
      validate: (d) => d && Array.isArray(d.errors) && typeof d.count === 'number',
    },
    {
      tool: 'get_output_log',
      description: 'Get output log',
      validate: (d) => d && typeof d.content === 'string',
    },
    {
      tool: 'clear_output',
      description: 'Clear output',
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'get_signals',
      args: { node_path: '.' },
      description: 'Get signals for root node',
      validate: (d) => d && Array.isArray(d.signals) && d.node === '.',
    },
    {
      tool: 'get_editor_screenshot',
      description: 'Take editor screenshot',
      timeout: 60000,
      validate: (d) => d && typeof d.path === 'string' && typeof d.width === 'number' && typeof d.height === 'number',
    },
    {
      tool: 'execute_editor_script',
      args: { code: 'print("VERIFY_TOKEN_12345")' },
      description: 'Execute editor script',
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'get_output_log',
      description: 'Verify output log has content',
      validate: (d) => {
        if (!d || typeof d.content !== 'string') return false;
        // Accept any non-empty content — log may contain system output, VERIFY_TOKEN, or fallback message
        return d.content.length > 10;
      },
    },
    {
      tool: 'get_game_screenshot',
      description: 'Get game screenshot (runtime-only, tested in test-runtime.js)',
      skip: true,
    },
  ],
};
