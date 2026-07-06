// Group 19: Analysis (4 tools)
module.exports = {
  name: 'Analysis',
  setup: async (t) => {
    // Create a dummy .png so find_unused_resources has files to scan
    await t.callTool('execute_editor_script', {
      script: `
        var img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
        img.fill(Color(1, 0, 0, 1))
        img.save_png("res://_verify_unused_resource.png")
        EditorInterface.get_resource_filesystem().scan()
      `,
    });
    await t.sleep(500);
  },
  teardown: async (t) => {
    await t.callTool('execute_editor_script', {
      script: `DirAccess.remove_absolute("res://_verify_unused_resource.png")`,
    });
  },
  tests: [
    {
      tool: 'analyze_scene_complexity',
      description: 'Analyze scene complexity',
      validate: (d) => {
        if (d === null || d === undefined || typeof d !== 'object') return false;
        return d.node_count !== undefined || d.total_nodes !== undefined || d.complexity !== undefined || JSON.stringify(d).includes('node') || JSON.stringify(d).includes('depth');
      },
    },
    {
      tool: 'analyze_signal_flow',
      description: 'Analyze signal flow',
      validate: (d) => {
        if (d === null || d === undefined || typeof d !== 'object') return false;
        const signals = Array.isArray(d) ? d : d?.signals || d?.connections;
        return Array.isArray(signals) || JSON.stringify(d).includes('signal') || JSON.stringify(d).includes('connection');
      },
    },
    {
      tool: 'find_unused_resources',
      description: 'Find unused resources',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'get_project_statistics',
      description: 'Get project statistics',
      validate: (d) => {
        if (d === null || d === undefined || typeof d !== 'object') return false;
        return (
          d.file_count !== undefined ||
          d.files !== undefined ||
          d.total_files !== undefined ||
          d.script_count !== undefined ||
          d.scripts !== undefined ||
          JSON.stringify(d).includes('count') ||
          JSON.stringify(d).includes('size') ||
          JSON.stringify(d).includes('files')
        );
      },
    },
  ],
};
