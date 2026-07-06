// Group 9: TileMap (6 tools)
// Note: TileSet creation via execute_editor_script breaks WebSocket in batch mode.
// Tools work correctly with empty tileset (source_id: -1 = erase cell).
module.exports = {
  name: 'TileMap',
  setup: async (t) => {
    await t.callTool('create_scene', {
      path: 'res://_verify_tilemap_scene.tscn',
      root_node_type: 'Node2D',
    });
    await t.callTool('open_scene', {
      path: 'res://_verify_tilemap_scene.tscn',
    });
    await t.callTool('add_node', {
      parent_path: '.',
      type: 'TileMapLayer',
      name: '_TileMap',
    });
    await t.sleep(500);
  },
  teardown: async (t) => {
    await t.callTool('save_scene', {});
    await t.callTool('delete_scene', {
      path: 'res://_verify_tilemap_scene.tscn',
    });
  },
  tests: [
    {
      tool: 'tilemap_get_info',
      args: { path: '_TileMap' },
      description: 'Get TileMap info',
      validate: (d, text) => {
        if (text.includes('not connected') || text.includes('"isError":true')) return false;
        return d !== null && d !== undefined && typeof d === 'object';
      },
    },
    {
      tool: 'tilemap_set_cell',
      args: { path: '_TileMap', coords: [5, 5], source_id: -1 },
      description: 'Set cell (erase at 5,5)',
      validate: (d, text) => {
        if (text.includes('not connected') || text.includes('"isError":true')) return false;
        return d !== null && d !== undefined;
      },
    },
    {
      tool: 'tilemap_get_cell',
      args: { path: '_TileMap', coords: [5, 5] },
      description: 'Get cell',
      validate: (d) => {
        if (d === null || d === undefined) return false;
        const r = d?.result || d;
        return r && r.empty === true;
      },
    },
    {
      tool: 'tilemap_fill_rect',
      args: {
        path: '_TileMap',
        rect: { x: 0, y: 0, w: 2, h: 2 },
        source_id: -1,
      },
      description: 'Fill rect (erase 2x2)',
      validate: (d, text) => {
        if (text.includes('not connected') || text.includes('"isError":true')) return false;
        return d !== null && d !== undefined;
      },
    },
    {
      tool: 'tilemap_get_used_cells',
      args: { path: '_TileMap' },
      description: 'Get used cells',
      validate: (d) => {
        if (d === null || d === undefined) return false;
        const r = d?.result || d;
        const list = Array.isArray(r) ? r : r?.cells;
        return Array.isArray(list);
      },
    },
    {
      tool: 'tilemap_clear',
      args: { path: '_TileMap' },
      description: 'Clear TileMap',
      validate: (d, text) => {
        if (text.includes('not connected') || text.includes('"isError":true')) return false;
        return d !== null && d !== undefined;
      },
    },
  ],
};
