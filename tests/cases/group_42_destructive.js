// Group 99: Destructive tools — run LAST
// Only 3 tools are truly destructive (disconnect the MCP plugin).
module.exports = {
  name: 'Destructive',
  tests: [
    {
      tool: 'get_memory_usage',
      description: 'Get memory usage',
      validate: (d) => {
        console.log('  get_memory_usage:', JSON.stringify(d).substring(0, 200));
        return d && typeof d === 'object';
      },
    },
    {
      tool: 'get_object_count',
      description: 'Get object count',
      validate: (d) => {
        console.log('  get_object_count:', JSON.stringify(d).substring(0, 200));
        return d && typeof d === 'object';
      },
    },
    {
      tool: 'track_object_creation',
      args: { class_name: 'Node', duration: 1 },
      description: 'Track object creation',
      validate: (d) => {
        console.log('  track_object_creation:', JSON.stringify(d).substring(0, 200));
        return d && typeof d === 'object';
      },
    },
    {
      tool: 'find_memory_leaks',
      description: 'Find memory leaks',
      validate: (d) => {
        console.log('  find_memory_leaks:', JSON.stringify(d).substring(0, 200));
        return d && typeof d === 'object';
      },
    },
    {
      tool: 'force_garbage_collection',
      description: 'Force garbage collection',
      validate: (d) => {
        console.log('  force_garbage_collection:', JSON.stringify(d).substring(0, 200));
        return d && typeof d === 'object';
      },
    },
    {
      tool: 'validate_platform_build',
      args: { platform: 'windows' },
      description: 'Validate platform build',
      validate: (d) => {
        console.log('  validate_platform_build:', JSON.stringify(d).substring(0, 200));
        return d && typeof d === 'object';
      },
    },
    // Scene play/stop — can disrupt editor state but safe
    {
      tool: 'play_scene',
      args: { mode: 'current' },
      description: 'Play current scene',
      validate: (d, text) => (d && typeof d === 'object') || (typeof text === 'string' && (text.includes('Playing') || text.includes('not open'))),
    },
    {
      tool: 'stop_scene',
      description: 'Stop playing scene',
      validate: (d, text) => (d && typeof d === 'object') || (typeof text === 'string' && (text.includes('stopped') || text.includes('not playing'))),
    },
    // === TRULY DESTRUCTIVE ===
    {
      tool: 'reload_plugin',
      description: 'Reload plugin (will disconnect)',
      expectError: true,
      validate: (d, text) => true,
    },
    {
      tool: 'reload_project',
      description: 'Reload project (will disconnect)',
      expectError: true,
      validate: (d, text) => true,
    },
    {
      tool: 'uninstall_addon',
      args: { name: 'godot_mcp' },
      description: 'Uninstall addon (will disconnect)',
      expectError: true,
      validate: (d, text) => true,
    },
  ],
};
