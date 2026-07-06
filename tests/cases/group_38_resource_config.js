// Group 38: Resource Config (6 tools)
module.exports = {
  name: 'ResourceConfig',
  tests: [
    {
      tool: 'get_resource_types',
      description: 'Get resource types',
      validate: (d) => {
        const types = Array.isArray(d) ? d : d?.types;
        return types && types.length > 0;
      },
    },
    {
      tool: 'get_resource_properties',
      args: { type: 'StandardMaterial3D' },
      description: 'Get resource properties',
      validate: (d) => d && d.properties !== undefined && d.properties.length > 0,
    },
    {
      tool: 'create_resource_from_template',
      args: { type: 'Resource', path: 'res://_verify_resource_template.tres' },
      description: 'Create resource from template',
      validate: (d) => d && d.path !== undefined,
    },
    {
      tool: 'get_resource_import_settings',
      args: { path: 'res://_verify_resource.tres' },
      description: 'Get resource import settings',
      validate: (d, text) => (d && d.settings !== undefined) || text.includes('No .import'),
    },
    {
      tool: 'set_resource_import_settings',
      args: { path: 'res://_verify_resource.tres', settings: {} },
      description: 'Set resource import settings',
      validate: (d, text) => (d && typeof d === 'object') || text.includes('No .import'),
    },
    {
      tool: 'import_resource',
      args: { path: 'res://_verify_resource.tres' },
      description: 'Import resource',
      validate: (d) => d && d.path !== undefined,
    },
  ],
};
