// Group 3: Node (17 tools)
module.exports = {
  name: 'Node',
  setup: async (t) => {
    // Ensure we have a scene open
    await t.callTool('create_scene', {
      path: 'res://_verify_node_scene.tscn',
      root_node_type: 'Node2D',
    });
    await t.callTool('open_scene', { path: 'res://_verify_node_scene.tscn' });
    await t.sleep(500);
  },
  teardown: async (t) => {
    await t.callTool('save_scene', {});
    await t.callTool('delete_scene', { path: 'res://_verify_node_scene.tscn' });
  },
  tests: [
    {
      tool: 'add_node',
      args: { parent_path: '.', type: 'Node2D', name: '_VerifyNode' },
      description: 'Add Node2D child',
      validate: (d) => d && d.name === '_VerifyNode' && d.type === 'Node2D' && typeof d.path === 'string',
    },
    {
      tool: 'get_node_properties',
      args: { path: '_VerifyNode' },
      description: 'Get node properties',
      validate: (d) => d && d.properties && typeof d.properties === 'object' && d.type === 'Node2D',
    },
    {
      tool: 'update_property',
      args: { path: '_VerifyNode', property: 'position', value: [42, 99] },
      description: 'Update position property',
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'get_node_properties',
      args: { path: '_VerifyNode' },
      description: 'Verify position was updated',
      validate: (d) => {
        if (!d || !d.properties) return false;
        const pos = d.properties.position;
        if (Array.isArray(pos)) return pos[0] === 42 && pos[1] === 99;
        if (typeof pos === 'object' && pos) return pos.x === 42 && pos.y === 99;
        return false;
      },
    },
    {
      tool: 'rename_node',
      args: { path: '_VerifyNode', new_name: '_RenamedVerify' },
      description: 'Rename node',
      validate: (d) => d && d.new_name === '_RenamedVerify' && typeof d.new_path === 'string',
    },
    {
      tool: 'duplicate_node',
      args: { path: '_RenamedVerify' },
      description: 'Duplicate node',
      validate: (d) => d && typeof d.duplicate === 'string' && typeof d.name === 'string',
    },
    {
      tool: 'move_node',
      args: { path: '_RenamedVerify', new_parent: '.' },
      // "." is Godot's path convention for the scene root node.
      // The response "moved to ." is correct — it means "moved to root".
      description: 'Move node (already at root, "." means scene root — no-op is expected)',
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'set_node_groups',
      args: { path: '_RenamedVerify', groups: ['_verify_group'] },
      description: 'Set node groups',
      validate: (d) => d && Array.isArray(d.groups) && d.groups.includes('_verify_group'),
    },
    {
      tool: 'get_node_groups',
      args: { path: '_RenamedVerify' },
      description: 'Get node groups',
      validate: (d) => {
        if (!d) return false;
        const groups = Array.isArray(d.groups) ? d.groups : d?.groups;
        return groups && groups.includes('_verify_group');
      },
    },
    {
      tool: 'find_nodes_in_group',
      args: { group: '_verify_group' },
      description: 'Find nodes in group',
      validate: (d) => {
        if (!d) return false;
        const nodes = Array.isArray(d.nodes) ? d.nodes : d?.nodes;
        return nodes && nodes.length > 0;
      },
    },
    {
      tool: 'select_nodes',
      args: { paths: ['_RenamedVerify'] },
      description: 'Select nodes',
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'get_editor_selection',
      description: 'Get editor selection',
      validate: (d) => {
        if (!d) return false;
        const nodes = Array.isArray(d.nodes) ? d.nodes : [];
        // Selection should contain the node we just selected
        return nodes.some((n) => n.name === '_RenamedVerify' || n.path === '_RenamedVerify');
      },
    },
    {
      tool: 'clear_editor_selection',
      description: 'Clear selection',
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'connect_signal',
      args: {
        source: '_RenamedVerify',
        signal: 'tree_entered',
        target: '_RenamedVerify',
        method: 'get_class',
      },
      description: 'Connect signal',
      validate: (d, text) => (d && typeof d === 'object') || text.includes('already connected'),
    },
    {
      tool: 'disconnect_signal',
      args: {
        source: '_RenamedVerify',
        signal: 'tree_entered',
        target: '_RenamedVerify',
        method: 'get_class',
      },
      description: 'Disconnect signal',
      validate: (d, text) => (d && typeof d === 'object') || text.includes('not connected'),
    },
    {
      tool: 'add_resource',
      args: {
        node_path: '_RenamedVerify',
        resource_type: 'CanvasItemMaterial',
      },
      description: 'Add resource to node',
      validate: (d) => d && d.resource_type === 'CanvasItemMaterial',
    },
    {
      tool: 'add_node',
      args: { parent_path: '.', type: 'Button', name: '_VerifyControl' },
      description: 'Add Button child for anchor test',
      validate: (d) => d && d.name === '_VerifyControl' && d.type === 'Button' && typeof d.path === 'string',
    },
    {
      tool: 'set_anchor_preset',
      args: { path: '_VerifyControl', preset: 'center' },
      description: 'Set anchor preset on Control node',
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'delete_node',
      args: { path: '_VerifyControl' },
      description: 'Delete anchor test Control node',
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'delete_node',
      args: { path: '_RenamedVerify' },
      description: 'Delete node',
      validate: (d) => d && typeof d === 'object',
    },
  ],
};
