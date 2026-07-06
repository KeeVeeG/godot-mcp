// Group 26: Debug Config (6 tools)
module.exports = {
  name: 'DebugConfig',
  tests: [
    {
      tool: 'get_debug_settings',
      description: 'Get debug settings',
      validate: (d) => d && d.settings !== undefined,
    },
    {
      tool: 'set_remote_debug',
      args: { enabled: false, host: '127.0.0.1', port: 6007 },
      description: 'Set remote debug',
      validate: (d) => d && d.enabled === false,
    },
    {
      tool: 'set_profiler_settings',
      args: { cpu: false, gpu: false },
      description: 'Set profiler settings',
      validate: (d) => d && d.changed !== undefined,
    },
    {
      tool: 'set_error_handling',
      args: { break_on_error: false, break_on_warning: false },
      description: 'Set error handling',
      validate: (d) => d && d.changed !== undefined,
    },
    {
      tool: 'get_editor_log',
      description: 'Get editor log',
      validate: (d) => d && (Array.isArray(d.entries) || typeof d.content === 'string'),
    },
    {
      tool: 'clear_editor_log',
      description: 'Clear editor log',
      validate: (d) => d && d.message !== undefined,
    },
  ],
};
