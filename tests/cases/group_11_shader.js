// Group 11: Shader (8 tools)
module.exports = {
  name: 'Shader',
  setup: async (t) => {
    await t.callTool('create_scene', {
      path: 'res://_verify_shader_scene.tscn',
      root_node_type: 'Node2D',
    });
    await t.callTool('open_scene', { path: 'res://_verify_shader_scene.tscn' });
    await t.sleep(500);
  },
  teardown: async (t) => {
    await t.callTool('save_scene', {});
    await t.callTool('delete_scene', {
      path: 'res://_verify_shader_scene.tscn',
    });
  },
  tests: [
    {
      tool: 'create_shader',
      args: {
        path: 'res://_verify_shader.gdshader',
        content: 'shader_type canvas_item;\nvoid fragment() { COLOR = vec4(1.0, 0.0, 0.0, 1.0); }',
      },
      description: 'Create shader',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'read_shader',
      args: { path: 'res://_verify_shader.gdshader' },
      description: 'Read shader',
      validate: (d) => {
        const c = d?.content || d?.code || d;
        return typeof c === 'string' && c.includes('shader_type');
      },
    },
    {
      tool: 'edit_shader',
      args: {
        path: 'res://_verify_shader.gdshader',
        old_text: 'vec4(1.0, 0.0, 0.0, 1.0)',
        new_text: 'vec4(0.0, 1.0, 0.0, 1.0)',
      },
      description: 'Edit shader',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'read_shader',
      args: { path: 'res://_verify_shader.gdshader' },
      description: 'Verify edit applied',
      validate: (d) => {
        const c = d?.content || d?.code || d;
        return typeof c === 'string' && c.includes('vec4(0.0, 1.0, 0.0, 1.0)');
      },
    },
    {
      tool: 'validate_shader',
      args: { path: 'res://_verify_shader.gdshader' },
      description: 'Validate shader',
      validate: (d) => d && (d.valid !== undefined || d.errors !== undefined || d.has_errors !== undefined),
    },
    {
      tool: 'list_shaders',
      description: 'List shaders',
      validate: (d) => {
        const list = Array.isArray(d) ? d : d?.shaders;
        return list && Array.isArray(list);
      },
    },
    {
      tool: 'assign_shader_material',
      args: { node_path: '.', shader_path: 'res://_verify_shader.gdshader' },
      description: 'Assign shader material',
      validate: (d, text) => {
        if (text.includes('"error"') && !text.includes('material')) return false;
        return d !== null && d !== undefined;
      },
    },
    {
      tool: 'get_shader_params',
      args: { node_path: '.' },
      description: 'Get shader params',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'set_shader_param',
      args: { node_path: '.', param: 'test_param', value: 1.0 },
      description: 'Set shader param',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'create_shader',
      args: {
        path: 'res://_test_delete_shader.gdshader',
        content: 'shader_type canvas_item;\nvoid fragment() { COLOR = vec4(1.0, 1.0, 1.0, 1.0); }',
      },
      description: 'Create shader for deletion',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'delete_shader',
      args: { path: 'res://_test_delete_shader.gdshader' },
      description: 'Delete shader',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
  ],
};
