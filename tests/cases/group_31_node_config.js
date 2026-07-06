// Group 31: Node Config (8 tools)
module.exports = {
  name: 'NodeConfig',
  tests: [
    {
      tool: 'get_available_node_types',
      description: 'Get available node types',
      validate: (d) => {
        const types = Array.isArray(d) ? d : d?.types;
        return types && types.length > 0;
      },
    },
    {
      tool: 'get_class_hierarchy',
      args: { type: 'Node2D' },
      description: 'Get class hierarchy',
      validate: (d) => d && Array.isArray(d.hierarchy),
    },
    {
      tool: 'get_node_default_properties',
      args: { type: 'Node2D' },
      description: 'Get node default properties',
      validate: (d) => d && d.defaults !== undefined,
    },
    {
      tool: 'get_node_signals',
      args: { type: 'Node2D' },
      description: 'Get node signals',
      validate: (d) => d && d.signals !== undefined && d.count > 0,
    },
    {
      tool: 'get_node_methods',
      args: { type: 'Node2D' },
      description: 'Get node methods',
      validate: (d) => d && d.methods !== undefined,
    },
    {
      tool: 'get_node_enums',
      args: { type: 'Node2D' },
      description: 'Get node enums',
      validate: (d) => d && d.enums !== undefined && d.count > 0,
    },
    {
      tool: 'get_node_constants',
      args: { type: 'Node2D' },
      description: 'Get node constants',
      validate: (d) => d && d.constants !== undefined && d.count > 0,
    },
    {
      tool: 'set_node_preset',
      args: { type: 'CharacterBody2D', preset: 'platformer_body' },
      description: 'Set node preset',
      validate: (d, text) => (d && typeof d === 'object') || text.includes('preset') || text.includes('unknown'),
    },
  ],
};
