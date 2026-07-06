// Group 32: Physics Config (8 tools)
module.exports = {
  name: 'PhysicsConfig',
  tests: [
    {
      tool: 'get_physics_settings',
      description: 'Get physics settings',
      validate: (d) => d && d.settings !== undefined,
    },
    {
      tool: 'get_collision_layers',
      description: 'Get collision layers',
      validate: (d) => d && d.layers !== undefined,
    },
    {
      tool: 'set_gravity',
      args: { x: 0, y: 980, z: 0 },
      description: 'Set gravity',
      validate: (d) => d && d.gravity !== undefined,
    },
    {
      tool: 'set_default_gravity',
      args: { value: 980 },
      description: 'Set default gravity',
      validate: (d) => d && d.value === 980,
    },
    {
      tool: 'set_physics_fps',
      args: { fps: 60 },
      description: 'Set physics FPS',
      validate: (d) => d && d.fps === 60,
    },
    {
      tool: 'set_physics_engine',
      args: { engine: 'godot_physics' },
      description: 'Set physics engine',
      validate: (d) => d && d.engine === 'godot_physics',
    },
    {
      tool: 'set_default_linear_damp',
      args: { value: 0.1 },
      description: 'Set default linear damp',
      validate: (d) => d && d.value === 0.1,
    },
    {
      tool: 'set_collision_layer_name',
      args: { layer: 1, name: '_verify_layer_1' },
      description: 'Set collision layer name',
      validate: (d) => d && d.layer === 1 && d.name === '_verify_layer_1',
    },
  ],
};
