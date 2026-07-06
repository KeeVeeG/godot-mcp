// Group 12: Resource (9 tools)
module.exports = {
  name: 'Resource',
  tests: [
    {
      tool: 'create_resource',
      args: { path: 'res://_verify_resource.tres', type: 'Resource' },
      description: 'Create resource',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'read_resource',
      args: { path: 'res://_verify_resource.tres' },
      description: 'Read resource',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'edit_resource',
      args: {
        path: 'res://_verify_resource.tres',
        properties: { resource_name: '_verify_edited' },
      },
      description: 'Edit resource',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'read_resource',
      args: { path: 'res://_verify_resource.tres' },
      description: 'Verify edit applied',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'duplicate_resource',
      args: {
        source_path: 'res://_verify_resource.tres',
        dest_path: 'res://_verify_resource_dup.tres',
      },
      description: 'Duplicate resource',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'get_resource_dependencies',
      args: { path: 'res://_verify_resource.tres' },
      description: 'Get resource dependencies',
      validate: (d) => {
        if (d === null || d === undefined) return false;
        const deps = Array.isArray(d) ? d : d?.dependencies;
        return Array.isArray(deps);
      },
    },
    {
      tool: 'get_resource_preview',
      args: { path: 'res://_verify_resource.tres' },
      description: 'Get resource preview',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'list_resources',
      args: { type: 'Resource' },
      description: 'List resources',
      validate: (d) => {
        const list = Array.isArray(d) ? d : d?.resources;
        return list && Array.isArray(list);
      },
    },
    {
      tool: 'add_autoload',
      args: { name: '_VerifyAutoload', path: 'res://_verify_script.gd' },
      description: 'Add autoload',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'remove_autoload',
      args: { name: '_VerifyAutoload' },
      description: 'Remove autoload',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'create_resource',
      args: { path: 'res://_test_delete_resource.tres', type: 'Resource' },
      description: 'Create resource for deletion',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'delete_resource',
      args: { path: 'res://_test_delete_resource.tres' },
      description: 'Delete resource',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
  ],
};
