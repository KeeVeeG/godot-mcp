// Group 37: Rendering Config (10 tools)
module.exports = {
  name: 'RenderingConfig',
  tests: [
    {
      tool: 'get_rendering_settings',
      description: 'Get rendering settings',
      validate: (d) => d && d.settings !== undefined,
    },
    {
      tool: 'set_rendering_quality',
      args: { quality: 'medium' },
      description: 'Set rendering quality',
      validate: (d) => d && d.quality === 'medium',
    },
    {
      tool: 'set_renderer',
      args: { renderer: 'forward_plus' },
      description: 'Set renderer',
      validate: (d) => d && d.renderer === 'forward_plus',
    },
    {
      tool: 'set_anti_aliasing',
      args: { msaa: '2x' },
      description: 'Set anti aliasing',
      validate: (d) => d && d.changed !== undefined,
    },
    {
      tool: 'set_shadow_quality',
      args: { quality: 'medium' },
      description: 'Set shadow quality',
      validate: (d) => d && d.quality === 'medium',
    },
    {
      tool: 'set_gi_quality',
      args: { quality: 'medium' },
      description: 'Set GI quality',
      validate: (d) => d && d.quality === 'medium',
    },
    {
      tool: 'set_viewport_size',
      args: { width: 1920, height: 1080 },
      description: 'Set viewport size',
      validate: (d) => d && d.width === 1920 && d.height === 1080,
    },
    {
      tool: 'set_window_settings',
      args: { size: [1280, 720], mode: 'windowed' },
      description: 'Set window settings',
      validate: (d) => d && d.changed !== undefined,
    },
    {
      tool: 'get_rendering_info',
      description: 'Get rendering info',
      validate: (d) => d && d.info !== undefined,
    },
  ],
};
