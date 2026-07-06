// Group 41: Visual Testing (6 tools)
// Requires a scene open and a baseline screenshot to exist.
module.exports = {
  name: 'VisualTesting',
  setup: async (t) => {
    // Create a scene so viewport capture works
    await t.callTool('create_scene', {
      path: 'res://_verify_visual_scene.tscn',
      root_node_type: 'Node2D',
    });
    await t.callTool('open_scene', { path: 'res://_verify_visual_scene.tscn' });
    await t.sleep(500);
    // Take a baseline screenshot
    await t.callTool('take_screenshot_with_context', { name: '_verify_screenshot' });
    // Set it as the baseline for later comparison
    await t.callTool('set_visual_baseline', {
      name: '_verify_baseline',
      screenshot_path: 'user://mcp_visual_tests/_verify_screenshot.png',
    });
  },
  teardown: async (t) => {
    await t.callTool('save_scene', {});
    await t.callTool('delete_scene', { path: 'res://_verify_visual_scene.tscn' });
  },
  tests: [
    {
      tool: 'take_screenshot_with_context',
      args: { name: '_verify_screenshot_2' },
      description: 'Take screenshot with context',
      timeout: 60000,
      validate: (d) => d?.screenshot_path !== undefined,
    },
    {
      tool: 'compare_screenshots',
      args: {
        baseline: 'user://mcp_visual_tests/_verify_screenshot.png',
        current: 'user://mcp_visual_tests/_verify_screenshot.png',
      },
      description: 'Compare identical screenshots (should match)',
      validate: (d) => d?.matches === true,
    },
    {
      tool: 'assert_visual_match',
      args: {
        name: '_verify_screenshot',
        baseline: '_verify_baseline',
        threshold: 0.01,
      },
      description: 'Assert visual match against baseline',
      validate: (d) => d?.passed === true || d?.match === true || d?.success === true || d?.details?.different_pixels === 0,
    },
    {
      tool: 'record_visual_regression',
      args: { test_name: '_verify_regression', frames: 1, interval: 0.1 },
      description: 'Record visual regression',
      timeout: 60000,
      validate: (d) => d?.success === true || d?.frames_captured > 0,
    },
    {
      tool: 'get_visual_diff_report',
      description: 'Get visual diff report',
      validate: (d) => d !== undefined && d?.pass_rate !== undefined,
    },
    {
      tool: 'set_visual_baseline',
      args: {
        name: '_verify_baseline_2',
        screenshot_path: 'user://mcp_visual_tests/_verify_screenshot.png',
      },
      description: 'Set visual baseline',
      validate: (d) => d?.baseline_path !== undefined || d?.name !== undefined,
    },
  ],
};
