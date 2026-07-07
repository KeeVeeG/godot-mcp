// Group 2: Scene (11 tools) — play_scene/stop_scene moved to group_99_destructive.js
module.exports = {
  name: 'Scene',
  tests: [
    {
      tool: 'create_scene',
      args: { path: 'res://_verify_scene.tscn', root_node_type: 'Node2D' },
      description: 'Create new scene',
      validate: (d) => d && d.path === 'res://_verify_scene.tscn' && d.root_type === 'Node2D',
    },
    {
      tool: 'open_scene',
      args: { path: 'res://_verify_scene.tscn' },
      description: 'Open scene',
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'get_scene_tree',
      description: 'Get scene tree',
      validate: (d) => {
        if (!d || !d.tree) return false;
        // Tree root must have name and type
        return typeof d.tree.name === 'string' && typeof d.tree.type === 'string';
      },
    },
    {
      tool: 'get_scene_file_content',
      args: { path: 'res://_verify_scene.tscn' },
      description: 'Get scene file content',
      validate: (d) => {
        if (!d || typeof d.content !== 'string') return false;
        // .tscn files contain the root node type as a section header
        return d.content.includes('Node2D') || d.content.includes('[node');
      },
    },
    {
      tool: 'save_scene',
      description: 'Save scene',
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'get_loaded_scenes',
      description: 'Get loaded scenes',
      validate: (d) => d && Array.isArray(d.scenes) && typeof d.count === 'number',
    },
    {
      tool: 'set_main_scene',
      args: { path: 'res://_verify_scene.tscn' },
      description: 'Set main scene',
      validate: (d) => d && d.path === 'res://_verify_scene.tscn',
    },
    {
      tool: 'get_main_scene',
      description: 'Get main scene',
      validate: (d) => d && typeof d.path === 'string',
    },
    // play_scene and stop_scene tested in runtime group
    {
      tool: 'add_scene_instance',
      args: { scene_path: 'res://_verify_scene.tscn', parent_path: '.' },
      description: 'Add scene instance',
      validate: (d) => d && typeof d.instance_name === 'string' && typeof d.parent === 'string',
    },
    // Create a blank scene first to close the current one (can't delete an open scene)
    {
      tool: 'create_scene',
      args: { path: 'res://_temp_blank.tscn', root_node_type: 'Node' },
      description: 'Create blank scene to close current',
      validate: (d) => d && d.path === 'res://_temp_blank.tscn',
    },
    {
      tool: 'delete_scene',
      args: { path: 'res://_verify_scene.tscn', force: true },
      description: 'Delete scene',
      validate: (d) => d && typeof d === 'object',
    },
  ],
};
