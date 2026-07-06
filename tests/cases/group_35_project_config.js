// Group 35: Project Config (12 tools)
module.exports = {
  name: 'ProjectConfig',
  tests: [
    {
      tool: 'get_project_setting',
      args: { key: 'application/config/name' },
      description: 'Get project setting',
      validate: (d) => d && d.value !== undefined,
    },
    {
      tool: 'set_project_setting_config',
      args: {
        key: 'application/config/description',
        value: '_verify_config_desc',
      },
      description: 'Set project setting config',
      validate: (d) => d && d.key === 'application/config/description',
    },
    {
      tool: 'get_project_setting',
      args: { key: 'application/config/description' },
      description: 'Verify setting was set',
      validate: (d) => {
        const s = JSON.stringify(d);
        return s.includes('_verify_config_desc');
      },
    },
    {
      tool: 'get_all_project_settings',
      description: 'Get all project settings',
      validate: (d) => d && d.settings !== undefined,
    },
    {
      tool: 'reset_project_setting',
      args: { key: 'application/config/description' },
      description: 'Reset project setting',
      validate: (d) => d && d.key === 'application/config/description',
    },
    {
      tool: 'get_input_map',
      description: 'Get input map',
      validate: (d) => d && d.actions !== undefined,
    },
    {
      tool: 'add_input_action',
      args: {
        action: '_verify_action_cfg',
        deadzone: 0.5,
        events: [{ type: 'key', keycode: 32 }],
      },
      description: 'Add input action',
      validate: (d) => d && d.action === '_verify_action_cfg',
    },
    {
      tool: 'set_input_map',
      args: { actions: { _verify_action_cfg: [{ type: 'key', keycode: 32 }] } },
      description: 'Set input map',
      validate: (d) => d && d.message !== undefined,
    },
    {
      tool: 'remove_input_action',
      args: { action: '_verify_action_cfg' },
      description: 'Remove input action',
      validate: (d) => d && d.action === '_verify_action_cfg',
    },
    {
      tool: 'get_autoloads',
      description: 'Get autoloads',
      validate: (d) => d && d.autoloads !== undefined,
    },
    {
      tool: 'add_autoload_config',
      args: { name: '_VerifyAutoloadCfg', path: 'res://_verify_script.gd' },
      description: 'Add autoload config',
      validate: (d) => d && d.name === '_VerifyAutoloadCfg',
    },
    {
      tool: 'remove_autoload_config',
      args: { name: '_VerifyAutoloadCfg' },
      description: 'Remove autoload config',
      validate: (d, text) => (d && typeof d === 'object') || text.includes('not found'),
    },
    {
      tool: 'reorder_autoloads',
      args: { order: ['mcp_runtime'] },
      description: 'Reorder autoloads',
      validate: (d) => d && d.order !== undefined,
    },
  ],
};
