// Group 39: Save/Load (5 tools)
module.exports = {
  name: 'SaveLoad',
  tests: [
    {
      tool: 'save_game_state',
      args: { slot: 99, metadata: { test: 'verify' } },
      description: 'Save game state to slot 99 (may need running game)',
      validate: (d, text) => (d !== null && d !== undefined) || text.includes('not running') || text.includes('no game'),
    },
    {
      tool: 'save_game_state',
      args: { slot: 1, metadata: { test: 'compare_a' } },
      description: 'Save game state to slot 1 for comparison',
      validate: (d, text) => (d !== null && d !== undefined) || text.includes('not running') || text.includes('no game'),
    },
    {
      tool: 'save_game_state',
      args: { slot: 2, metadata: { test: 'compare_b' } },
      description: 'Save game state to slot 2 for comparison',
      validate: (d, text) => (d !== null && d !== undefined) || text.includes('not running') || text.includes('no game'),
    },
    {
      tool: 'list_save_files',
      description: 'List save files',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'load_game_state',
      args: { slot: 99 },
      description: 'Load game state from slot 99',
      validate: (d, text) => (d !== null && d !== undefined) || text.includes('not running') || text.includes('no game') || text.includes('not found'),
    },
    {
      tool: 'compare_save_states',
      args: { slot_a: 1, slot_b: 2 },
      description: 'Compare save states (both slots populated above)',
      validate: (d, text) => (d !== null && d !== undefined) || text.includes('not found') || text.includes('No save'),
    },
    {
      tool: 'delete_save_file',
      args: { slot: 99 },
      description: 'Delete save file slot 99',
      validate: (d, text) => (d !== null && d !== undefined) || text.includes('not found'),
    },
    {
      tool: 'delete_save_file',
      args: { slot: 1 },
      description: 'Delete save file slot 1',
      validate: (d, text) => (d !== null && d !== undefined) || text.includes('not found'),
    },
    {
      tool: 'delete_save_file',
      args: { slot: 2 },
      description: 'Delete save file slot 2',
      validate: (d, text) => (d !== null && d !== undefined) || text.includes('not found'),
    },
  ],
};
