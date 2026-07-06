// Group 34: Platform Specific (6 tools)
module.exports = {
  name: 'PlatformSpecific',
  tests: [
    {
      tool: 'get_platform_settings',
      args: { platform: 'windows' },
      description: 'Get platform settings',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'get_platform_capabilities',
      args: { platform: 'windows' },
      description: 'Get platform capabilities',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'configure_android',
      args: { settings: { package_name: 'com.verify.test' } },
      description: 'Configure Android',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'configure_ios',
      args: { settings: { bundle_id: 'com.verify.test' } },
      description: 'Configure iOS',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'configure_web',
      args: { settings: { canvas_resize: true } },
      description: 'Configure Web',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'validate_platform_build',
      args: { platform: 'windows' },
      description: 'Validate platform build',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
  ],
};
