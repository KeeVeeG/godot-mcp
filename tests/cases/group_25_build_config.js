// Group 25: Build Config (8 tools)
module.exports = {
  name: 'BuildConfig',
  tests: [
    {
      tool: 'get_build_settings',
      description: 'Get build settings',
      validate: (d) => d && d.settings !== undefined,
    },
    {
      tool: 'set_build_configuration',
      args: { config: 'release' },
      description: 'Set build configuration',
      validate: (d) => d && d.configuration === 'release',
    },
    {
      tool: 'set_scripting_backend',
      args: { backend: 'gdscript' },
      description: 'Set scripting backend',
      validate: (d) => d && d.backend === 'gdscript',
    },
    {
      tool: 'set_export_filter',
      args: { filter: 'all_resources' },
      description: 'Set export filter',
      validate: (d) => d && d.filter === 'all_resources',
    },
    {
      tool: 'set_custom_features',
      args: { features: ['_verify_feature'] },
      description: 'Set custom features',
      validate: (d) => d && Array.isArray(d.features),
    },
    {
      tool: 'set_debug_options',
      args: { debug_build: true },
      description: 'Set debug options',
      validate: (d) => d && d.changed !== undefined,
    },
    {
      tool: 'validate_build_settings',
      description: 'Validate build settings',
      validate: (d) => d && Array.isArray(d.errors) && Array.isArray(d.warnings),
    },
    {
      tool: 'get_build_command',
      args: { platform: 'windows' },
      description: 'Get build command',
      validate: (d) => d && d.command !== undefined,
    },
  ],
};
