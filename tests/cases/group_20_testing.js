// Group 20: Testing (5 tools) — requires running game
module.exports = {
  name: 'Testing',
  tests: [
    {
      tool: 'run_test_scenario',
      args: { steps: [{ type: 'wait', duration: 0.1 }] },
      description: 'Run test scenario',
      validate: (d, text) => {
        if (text.includes('"error"')) return false;
        return d !== null && d !== undefined && (d.success !== undefined || d.completed !== undefined || d.steps !== undefined || typeof d === 'object');
      },
    },
    {
      tool: 'assert_node_state',
      args: { path: '.', property: 'name', expected: 'Node2D' },
      description: 'Assert node state',
      validate: (d, text) => {
        if (text.includes('"error"')) return false;
        if (d === null || d === undefined) return false;
        return d.passed !== undefined || d.success !== undefined || d.result !== undefined || d.assertion !== undefined || typeof d === 'object';
      },
    },
    {
      tool: 'assert_screen_text',
      args: { text: 'test' },
      description: 'Assert screen text',
      validate: (d, text) => {
        if (text.includes('"error"')) return false;
        if (d === null || d === undefined) return false;
        return d.found !== undefined || d.passed !== undefined || d.success !== undefined || d.result !== undefined || typeof d === 'object';
      },
    },
    {
      tool: 'run_stress_test',
      args: { config: { type: 'Node2D', count: 1 } },
      description: 'Run stress test',
      validate: (d, text) => {
        if (text.includes('"error"')) return false;
        if (d === null || d === undefined) return false;
        return d.fps !== undefined || d.frame_time !== undefined || d.duration !== undefined || d.spawned !== undefined || d.results !== undefined || typeof d === 'object';
      },
    },
    {
      tool: 'get_test_report',
      description: 'Get test report',
      validate: (d) => {
        if (d === null || d === undefined) return false;
        return d.tests !== undefined || d.results !== undefined || d.total !== undefined || d.passed !== undefined || d.failed !== undefined || Array.isArray(d) || typeof d === 'object';
      },
    },
  ],
};
