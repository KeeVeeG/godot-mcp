// Group 10: Theme (6 tools)
module.exports = {
  name: 'Theme',
  tests: [
    {
      tool: 'create_theme',
      args: { path: 'res://_verify_theme.tres' },
      description: 'Create theme',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'set_theme_color',
      args: {
        path: 'res://_verify_theme.tres',
        theme_type: 'Button',
        name: 'font_color',
        color: '#FF0000',
      },
      description: 'Set theme color',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'set_theme_constant',
      args: {
        path: 'res://_verify_theme.tres',
        theme_type: 'Button',
        name: 'h_separation',
        value: 5,
      },
      description: 'Set theme constant',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'set_theme_font_size',
      args: {
        path: 'res://_verify_theme.tres',
        theme_type: 'Button',
        name: 'font_size',
        size: 16,
      },
      description: 'Set theme font size',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'set_theme_stylebox',
      args: {
        path: 'res://_verify_theme.tres',
        theme_type: 'Button',
        name: 'normal',
        properties: { type: 'Flat' },
      },
      description: 'Set theme stylebox',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'get_theme_info',
      args: { path: 'res://_verify_theme.tres' },
      description: 'Get theme info',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'create_theme',
      args: { path: 'res://_test_delete_theme.tres' },
      description: 'Create theme for deletion test',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'delete_theme',
      args: { path: 'res://_test_delete_theme.tres' },
      description: 'Delete theme',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
  ],
};
