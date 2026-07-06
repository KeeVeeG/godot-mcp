// Group 30: Memory Profiling (5 tools)
// Safe read-only tools. Destructive tools (force_garbage_collection, track_object_creation)
// are tested in group_99_destructive.js to avoid breaking subsequent tests.
module.exports = {
  name: 'MemoryProfiling',
  tests: [
    {
      tool: 'get_memory_usage',
      description: 'Get memory usage breakdown',
      validate: (d) => d && typeof d === 'object' && !d.error,
    },
    {
      tool: 'get_object_count',
      description: 'Get object count',
      validate: (d) => d && typeof d === 'object' && !d.error,
    },
    {
      tool: 'find_memory_leaks',
      description: 'Find memory leaks',
      validate: (d) => d && typeof d === 'object' && !d.error,
    },
  ],
};
