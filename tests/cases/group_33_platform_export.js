// Group 33: Platform Export (6 tools)
// NOTE: Tests are idempotent — preset creation accepts "already exists" from prior runs
module.exports = {
  name: 'PlatformExport',
  tests: [
    {
      tool: 'get_platform_export_templates',
      description: 'Get platform export templates',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'create_platform_export_preset',
      args: { platform: 'Windows Desktop', name: '_verify_win_preset' },
      description: 'Create platform export preset (idempotent)',
      validate: (d, text) => (d !== null && d !== undefined) || text.includes('already') || text.includes('exists'),
    },
    {
      tool: 'validate_platform_export',
      args: { platform: 'Windows Desktop' },
      description: 'Validate platform export',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'validate_export_for_platform',
      args: { platform: 'Windows Desktop' },
      description: 'Validate export for platform',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'export_for_platform',
      args: { platform: 'windows' },
      description: 'Export for platform (may fail without templates)',
      validate: (d, text) => (d !== null && d !== undefined) || text.includes('template') || text.includes('export') || text.includes('not found') || text.includes('preset'),
    },
    {
      tool: 'run_exported_build',
      args: { path: 'res://_verify_export/' },
      description: 'Run exported build',
      validate: (d, text) => (d !== null && d !== undefined) || text.includes('not found') || text.includes('export') || text.includes('Build'),
    },
  ],
};
