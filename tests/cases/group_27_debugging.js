// Group 27: Debugging (8 tools)
module.exports = {
  name: 'Debugging',
  tests: [
    {
      tool: 'set_breakpoint',
      args: { script_path: 'res://_verify_script.gd', line: 2 },
      description: 'Set breakpoint',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'list_breakpoints',
      description: 'List breakpoints',
      validate: (d) => {
        const s = JSON.stringify(d);
        return s.includes('_verify_script');
      },
    },
    {
      tool: 'remove_breakpoint',
      args: { script_path: 'res://_verify_script.gd', line: 2 },
      description: 'Remove breakpoint',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'list_breakpoints',
      description: 'Verify breakpoint removed',
      validate: (d) => {
        const s = JSON.stringify(d);
        return !s.includes('line":2') || s.includes('[]') || s.includes('empty');
      },
    },
    {
      tool: 'evaluate_expression',
      args: { expression: '1 + 1' },
      description: 'Evaluate expression',
      validate: (d) => d !== null && d !== undefined,
    },
    // These require paused state
    {
      tool: 'get_call_stack',
      expectError: true,
      description: 'Get call stack (needs pause)',
      validate: (_, text) => !text.includes('"error"') || text.includes('not paused') || text.includes('not running') || text.includes('session'),
    },
    {
      tool: 'step_over',
      expectError: true,
      description: 'Step over (needs pause)',
      validate: (_, text) => !text.includes('"error"') || text.includes('not paused') || text.includes('not running') || text.includes('session'),
    },
    {
      tool: 'step_into',
      expectError: true,
      description: 'Step into (needs pause)',
      validate: (_, text) => !text.includes('"error"') || text.includes('not paused') || text.includes('not running') || text.includes('session'),
    },
    {
      tool: 'continue_execution',
      expectError: true,
      description: 'Continue execution (needs pause)',
      validate: (_, text) => !text.includes('"error"') || text.includes('not paused') || text.includes('not running') || text.includes('session'),
    },
  ],
};
