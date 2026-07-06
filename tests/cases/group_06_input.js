// Group 6: Input (7 tools)
module.exports = {
  name: 'Input',
  tests: [
    {
      tool: 'get_input_actions',
      description: 'Get input actions',
      validate: (d) => {
        // Response shape: { result: { actions: {...}, count: N } }
        const actions = d?.result?.actions || (Array.isArray(d) ? d : d?.actions);
        if (Array.isArray(actions)) return actions.length > 0;
        if (actions && typeof actions === 'object') return Object.keys(actions).length > 0;
        return false;
      },
    },
    {
      tool: 'set_input_action',
      args: {
        action: '_verify_action',
        events: [{ type: 'key', keycode: 'Space' }],
      },
      description: 'Set input action',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'get_input_actions',
      description: 'Verify action was added',
      validate: (d) => {
        const actions = d?.result?.actions || (Array.isArray(d) ? d : d?.actions);
        if (Array.isArray(actions)) return actions.some((a) => (a.name || a) === '_verify_action');
        if (actions && typeof actions === 'object') return Object.prototype.hasOwnProperty.call(actions, '_verify_action');
        return false;
      },
    },
    // Simulation tools require running game — tested in test-runtime.js
    {
      tool: 'simulate_key',
      args: { keycode: 'Space', pressed: true },
      description: 'Simulate key press (runtime-only)',
      skip: true,
    },
    {
      tool: 'simulate_mouse_click',
      args: { position: [100, 100] },
      description: 'Simulate mouse click (runtime-only)',
      skip: true,
    },
    {
      tool: 'simulate_mouse_move',
      args: { position: [200, 200] },
      description: 'Simulate mouse move (runtime-only)',
      skip: true,
    },
    {
      tool: 'simulate_action',
      args: { action: '_verify_action', pressed: true },
      description: 'Simulate action (runtime-only)',
      skip: true,
    },
    {
      tool: 'simulate_sequence',
      args: { events: [{ type: 'key', keycode: 'Space', pressed: true }] },
      description: 'Simulate input sequence (runtime-only)',
      skip: true,
    },
  ],
};
