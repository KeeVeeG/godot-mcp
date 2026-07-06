// Group 4: Script (9 tools)
module.exports = {
  name: 'Script',
  setup: async (t) => {
    // Create and open a scene so attach_script has a node to attach to
    await t.callTool('create_scene', {
      path: 'res://_verify_script_scene.tscn',
      root_node_type: 'Node',
    });
    await t.callTool('open_scene', { path: 'res://_verify_script_scene.tscn' });
    await t.sleep(500);
  },
  teardown: async (t) => {
    await t.callTool('save_scene', {});
    await t.callTool('delete_scene', {
      path: 'res://_verify_script_scene.tscn',
    });
  },
  tests: [
    {
      tool: 'create_script',
      args: {
        path: 'res://_verify_script.gd',
        content: 'extends Node\n\nfunc _ready():\n\tpass\n',
      },
      description: 'Create GDScript',
      validate: (d) => d && d.path === 'res://_verify_script.gd',
    },
    {
      tool: 'read_script',
      args: { path: 'res://_verify_script.gd' },
      description: 'Read script',
      validate: (d) => {
        if (!d || typeof d.content !== 'string') return false;
        return d.content.includes('_ready') && d.content.includes('extends Node');
      },
    },
    {
      tool: 'edit_script',
      args: {
        path: 'res://_verify_script.gd',
        old_text: 'pass',
        new_text: 'print("verified")',
      },
      description: 'Edit script',
      validate: (d) => d && typeof d.replacements === 'number' && d.replacements >= 1,
    },
    {
      tool: 'read_script',
      args: { path: 'res://_verify_script.gd' },
      description: 'Verify edit applied',
      validate: (d) => {
        if (!d || typeof d.content !== 'string') return false;
        return d.content.includes('print("verified")') && !d.content.includes('pass');
      },
    },
    {
      tool: 'list_scripts',
      description: 'List all scripts',
      validate: (d) => {
        if (!d || !Array.isArray(d.scripts)) return false;
        // The created script should appear in the list
        return d.scripts.some((s) => s.path === 'res://_verify_script.gd' || s.name === '_verify_script.gd');
      },
    },
    {
      tool: 'validate_script',
      args: { path: 'res://_verify_script.gd' },
      description: 'Validate script',
      validate: (d) => d && d.valid === true,
    },
    {
      tool: 'search_in_files',
      args: { query: 'func _ready' },
      description: 'Search in files',
      validate: (d) => {
        if (!d || !Array.isArray(d.matches)) return false;
        // The created script should contain 'func _ready'
        return d.matches.some((m) => m.path === 'res://_verify_script.gd' || (m.content && m.content.includes('func _ready')));
      },
    },
    {
      tool: 'attach_script',
      args: { script_path: 'res://_verify_script.gd', node_path: '.' },
      description: 'Attach script to node',
      validate: (d, text) => (d && typeof d === 'object') || text.includes('already'),
    },
    {
      tool: 'get_open_scripts',
      description: 'Get open scripts',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'create_script',
      args: {
        path: 'res://_test_delete_script.gd',
        content: 'extends Node\n\nfunc _ready():\n\tpass\n',
      },
      description: 'Create script for deletion test',
      validate: (d) => d && d.path === 'res://_test_delete_script.gd',
    },
    {
      tool: 'delete_script',
      args: { path: 'res://_test_delete_script.gd' },
      description: 'Delete script',
      validate: (d) => d && (d.deleted === true || d.success === true || typeof d.path === 'string'),
    },
  ],
};
