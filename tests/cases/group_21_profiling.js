// Group 21: Profiling (2 tools)
module.exports = {
  name: 'Profiling',
  tests: [
    {
      tool: 'get_performance_monitors',
      description: 'Get performance monitors',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'get_editor_performance',
      description: 'Get editor performance',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
  ],
};
