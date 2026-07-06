// Group 16: Navigation (7 tools)
module.exports = {
  name: 'Navigation',
  setup: async (t) => {
    await t.callTool('create_scene', {
      path: 'res://_verify_nav_scene.tscn',
      root_node_type: 'Node2D',
    });
    await t.callTool('open_scene', { path: 'res://_verify_nav_scene.tscn' });
    await t.callTool('add_node', {
      parent_path: '.',
      type: 'Node2D',
      name: '_NavParent',
    });
    await t.sleep(500);
    // Create nodes for remove_navigation_* tests
    await t.callTool('add_node', {
      parent_path: '.',
      type: 'NavigationRegion2D',
      name: 'TestNavRegion',
    });
    await t.callTool('add_node', {
      parent_path: '.',
      type: 'NavigationAgent2D',
      name: 'TestNavAgent',
    });
    await t.callTool('add_node', {
      parent_path: '_NavParent',
      type: 'NavigationLink2D',
      name: 'TestNavLink',
    });
    await t.sleep(500);
    // Add collision geometry for navmesh to bake on
    await t.callTool('execute_editor_script', {
      script: `
        var body = StaticBody2D.new()
        body.name = "_FloorBody"
        var col = CollisionPolygon2D.new()
        col.polygon = PackedVector2Array([Vector2(-500, -500), Vector2(500, -500), Vector2(500, 500), Vector2(-500, 500)])
        body.add_child(col)
        EditorInterface.get_edited_scene_root().add_child(body)
        body.owner = EditorInterface.get_edited_scene_root()
        col.owner = EditorInterface.get_edited_scene_root()
      `,
    });
    await t.sleep(500);
  },
  teardown: async (t) => {
    await t.callTool('save_scene', {});
    await t.callTool('delete_scene', { path: 'res://_verify_nav_scene.tscn' });
  },
  tests: [
    {
      tool: 'setup_navigation_region',
      args: { path: '', properties: {} },
      description: 'Setup navigation region',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'setup_navigation_agent',
      args: { path: '', properties: {} },
      description: 'Setup navigation agent',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'setup_navigation_link',
      args: {
        parent_path: '_NavParent',
        dimension: '2d',
        properties: { start_position: [0, 0], end_position: [100, 100] },
      },
      description: 'Setup navigation link',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'set_navigation_layers',
      args: { path: 'NavigationRegion2D', layer: 1, mask: 1 },
      description: 'Set navigation layers',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'get_navigation_info',
      args: { path: 'NavigationRegion2D' },
      description: 'Get navigation info',
      validate: (d) => d !== null && d !== undefined && typeof d === 'object',
    },
    {
      tool: 'bake_navigation_mesh',
      args: { path: 'NavigationRegion2D' },
      description: 'Bake navigation mesh',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'find_navigation_path',
      args: { start: [0, 0], end: [100, 100] },
      description: 'Find navigation path',
      validate: (d) => {
        if (d === null || d === undefined) return false;
        const path = Array.isArray(d) ? d : d?.path || d?.points;
        return path !== undefined && (Array.isArray(path) || typeof path === 'object');
      },
    },
    {
      tool: 'remove_navigation_region',
      args: { node_path: 'TestNavRegion' },
      description: 'Remove navigation region',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'remove_navigation_agent',
      args: { node_path: 'TestNavAgent' },
      description: 'Remove navigation agent',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
    {
      tool: 'remove_navigation_link',
      args: { node_path: '_NavParent/TestNavLink' },
      description: 'Remove navigation link',
      validate: (d, text) => !text.includes('"error"') && d !== null && d !== undefined,
    },
  ],
};
