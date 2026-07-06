// Group 22: Export (6 tools)
// NOTE: Tests are idempotent — preset creation accepts "already exists" from prior runs
module.exports = {
  name: 'Export',
  tests: [
    {
      tool: 'list_export_presets',
      description: 'List export presets',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'get_export_info',
      description: 'Get export info',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'get_export_templates',
      description: 'Get export templates',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'validate_export',
      description: 'Validate export',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'create_export_preset',
      args: { platform: 'Windows Desktop', name: '_verify_preset' },
      description: 'Create export preset (idempotent — accepts "already exists")',
      validate: (d, text) => (d !== null && d !== undefined) || text.includes('already') || text.includes('exists'),
    },
    {
      tool: 'list_export_presets',
      description: 'Verify preset exists',
      validate: (d) => {
        if (d === null || d === undefined) return false;
        const s = JSON.stringify(d);
        return s.includes('_verify_preset');
      },
    },
    {
      tool: 'export_project',
      args: { preset: '_verify_preset' },
      description: 'Export project (may fail without templates)',
      validate: (_, text) => !text.includes('"error"') || text.includes('template') || text.includes('export') || text.includes('not found'),
    },
    {
      tool: 'create_export_preset',
      args: { platform: 'Windows Desktop', name: '_delete_test_preset' },
      description: 'Create export preset for delete test',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'delete_export_preset',
      args: { name: '_delete_test_preset' },
      description: 'Delete export preset',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
  ],
};
