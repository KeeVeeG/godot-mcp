// Group 24: Audio Config (6 tools)
module.exports = {
  name: 'AudioConfig',
  tests: [
    {
      tool: 'get_audio_settings',
      description: 'Get audio settings',
      validate: (d) => d && d.settings !== undefined,
    },
    {
      tool: 'add_audio_bus_config',
      args: { name: '_VerifyAudioBus' },
      description: 'Add audio bus config',
      validate: (d) => d && d.name === '_VerifyAudioBus',
    },
    {
      tool: 'set_audio_bus_volume',
      args: { bus: 'Master', volume_db: -3.0 },
      description: 'Set audio bus volume',
      validate: (d) => d && d.volume_db === -3.0,
    },
    {
      tool: 'get_audio_bus_effects',
      args: { bus: 'Master' },
      description: 'Get audio bus effects',
      validate: (d) => d && Array.isArray(d.effects),
    },
    {
      tool: 'set_audio_bus_layout',
      args: {
        buses: [{ name: 'Master' }, { name: '_VerifyBus2', volume: -6 }],
      },
      description: 'Set audio bus layout',
      validate: (d) => d && typeof d.bus_count === 'number',
    },
    {
      tool: 'remove_audio_bus',
      args: { index: 1 },
      description: 'Remove audio bus',
      validate: (d) => d && d.removed !== undefined,
    },
  ],
};
