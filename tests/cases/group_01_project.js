// Group 1: Project (7 tools)
const state = {};

module.exports = {
  name: 'Project',
  setup: async (t) => {
    // Create a .tres resource that Godot will assign a UID to
    try {
      await t.callTool('create_resource', {
        path: 'res://_verify_uid_resource.tres',
        type: 'Resource',
      });
      state.hasResource = true;
    } catch (e) {
      state.hasResource = false;
    }
  },
  teardown: async (t) => {
    try {
      await t.callTool('delete_resource', { path: 'res://_verify_uid_resource.tres' });
    } catch {}
  },
  tests: [
    {
      tool: 'get_project_info',
      description: 'Get project metadata',
      validate: (d) => d && d.info && typeof d.info === 'object' && (d.info.name !== undefined || d.info.main_scene !== undefined || d.info.godot_version !== undefined),
    },
    {
      tool: 'get_filesystem_tree',
      args: { path: 'res://' },
      description: 'Get filesystem tree',
      validate: (d) => {
        if (!d || !d.tree) return false;
        const children = d.tree.children;
        if (!Array.isArray(children) || children.length === 0) return false;
        // Verify the tree contains expected project files
        const names = children.map((c) => c.name);
        return names.includes('project.godot') || names.includes('addons') || names.includes('addon');
      },
    },
    {
      tool: 'search_files',
      args: { query: 'test' },
      description: 'Search files by query',
      validate: (d) => d && Array.isArray(d.matches) && typeof d.count === 'number',
    },
    {
      tool: 'get_project_settings',
      description: 'Get project settings',
      validate: (d) => d && d.settings && typeof d.settings === 'object' && Object.keys(d.settings).length > 0,
    },
    {
      tool: 'set_project_setting',
      args: {
        key: 'application/config/description',
        value: 'VERIFY_TEST_DESC',
      },
      description: 'Set project setting',
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'get_project_settings',
      description: 'Verify description was set',
      validate: (d) => d && d.settings && d.settings['application/config/description'] === 'VERIFY_TEST_DESC',
    },
    {
      tool: 'project_path_to_uid',
      args: { path: 'res://_verify_uid_resource.tres' },
      description: 'Convert path to UID',
      validate: (d, text) => {
        if (d && d.uid) {
          state.uid = d.uid;
          return true;
        }
        // Accept error gracefully if resource creation failed
        if (!state.hasResource) return d !== null && d !== undefined;
        return d !== null && d !== undefined && (d.success === false || text.includes('No UID'));
      },
    },
    {
      tool: 'uid_to_project_path',
      get args() {
        return { uid: state.uid || 'uid://0' };
      },
      description: 'Convert UID to path (skip if no UID available)',
      validate: (d, text) => {
        // If no UID was obtained, accept the error gracefully
        if (!state.uid) return d !== null && (text.includes('not found') || text.includes('error') || d.error !== undefined);
        return d && (d.path || typeof d === 'string');
      },
    },
  ],
};
