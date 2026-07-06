// Group 23: Addon Management (5 tools)
// NOTE: uninstall_addon is SKIPPED — it removes the MCP addon itself, killing the WebSocket connection
module.exports = {
  name: 'AddonMgmt',
  tests: [
    {
      tool: 'list_addons',
      description: 'List addons (godot_mcp verified)',
      validate: (d, text) => {
        if (text.includes('not connected') || text.includes('"isError":true')) return false;
        if (!d) return false;
        const s = JSON.stringify(d);
        return s.includes('godot_mcp') || s.includes('GodotMCP') || s.includes('godot-mcp');
      },
    },
    {
      tool: 'install_addon',
      args: { name: 'godot_mcp', source: 'local', url: 'res://addons/godot_mcp' },
      description: 'Install addon (already exists — expected)',
      validate: (d, text) => d !== null || text.includes('already exists'),
    },
    {
      tool: 'list_addons',
      description: 'Verify addon still listed',
      validate: (d, text) => {
        if (text.includes('not connected') || text.includes('"isError":true')) return false;
        if (!d) return false;
        const s = JSON.stringify(d);
        return s.includes('godot_mcp') || s.includes('GodotMCP') || s.includes('godot-mcp');
      },
    },
    {
      tool: 'configure_addon',
      args: { name: 'godot_mcp', settings: { test_key: 'verify_value' } },
      description: 'Configure addon settings',
      validate: (d, text) => d !== null && d !== undefined,
    },
    {
      tool: 'update_addon',
      args: { name: 'godot_mcp' },
      description: 'Update addon (local — no remote source, expected)',
      validate: (d, text) => d !== null || text.includes('Cannot determine') || text.includes('not found'),
    },
  ],
};
