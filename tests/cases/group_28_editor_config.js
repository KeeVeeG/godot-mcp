// Group 28: Editor Config (8 tools)
module.exports = {
  name: 'EditorConfig',
  tests: [
    {
      tool: 'get_editor_settings',
      description: 'Get editor settings',
      validate: (d) => d && d.settings !== undefined,
    },
    {
      tool: 'set_editor_theme',
      args: { theme: 'dark' },
      description: 'Set editor theme',
      validate: (d) => d && d.theme === 'dark',
    },
    {
      tool: 'set_editor_layout',
      args: { layout: '2d' },
      description: 'Set editor layout',
      validate: (d) => d && d.layout === '2d',
    },
    {
      tool: 'set_font_size',
      args: { size: 14 },
      description: 'Set font size',
      validate: (d) => d && d.size === 14,
    },
    {
      tool: 'set_editor_scale',
      args: { scale: 1.0 },
      description: 'Set editor scale',
      validate: (d) => d && d.scale === 1.0,
    },
    {
      tool: 'save_editor_layout',
      args: { name: '_verify_layout' },
      description: 'Save editor layout',
      validate: (d) => d && d.name === '_verify_layout',
    },
    {
      tool: 'load_editor_layout',
      args: { name: '_verify_layout' },
      description: 'Load editor layout',
      validate: (d) => d && d.name === '_verify_layout',
    },
    {
      tool: 'reset_editor_layout',
      description: 'Reset editor layout',
      validate: (d) => d && d.message !== undefined,
    },
  ],
};
