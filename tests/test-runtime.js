#!/usr/bin/env node
// Test Runtime tools — requires a running game
// Uses stdio MCP protocol like run-full-verification.js
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const SERVER_PATH = path.join(__dirname, '..', 'server', 'dist', 'index.js');
const GODOT_PATH = process.argv.find((a) => a.startsWith('--godot='))?.split('=')[1] || process.env.GODOT_PATH;
const TEST_PROJECT = process.argv.find((a) => a.startsWith('--project='))?.split('=')[1] || process.env.TEST_PROJECT;
const TIMEOUT = 10000;

if (!GODOT_PATH || !TEST_PROJECT) {
  console.error('Usage: node test-runtime.js --godot=/path/to/godot --project=/path/to/project');
  console.error('  Or set GODOT_PATH and TEST_PROJECT environment variables');
  process.exit(1);
}

let server, godot;
let requestId = 0;
let pending = new Map();
let buffer = '';

function log(msg) {
  console.log(`  ${msg}`);
}

function onServerData(data) {
  buffer += data.toString();
  const lines = buffer.split('\n');
  buffer = lines.pop();
  for (const line of lines) {
    if (!line.trim()) continue;
    try {
      const msg = JSON.parse(line);
      if (msg.id && pending.has(msg.id)) {
        const { resolve, timer } = pending.get(msg.id);
        clearTimeout(timer);
        pending.delete(msg.id);
        resolve(msg);
      }
    } catch {}
  }
}

function call(method, params = {}) {
  return new Promise((resolve, reject) => {
    const id = ++requestId;
    const timer = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`Timeout: ${method}`));
    }, TIMEOUT);
    pending.set(id, { resolve, reject, timer });
    server.stdin.write(JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n');
  });
}

async function callTool(name, args = {}) {
  const r = await call('tools/call', { name, arguments: args });
  const text = r.result?.content?.[0]?.text || '';
  const isError = r.result?.isError || false;
  try {
    return { data: JSON.parse(text), text, isError };
  } catch {
    return { data: null, text, isError };
  }
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  console.log('=== Runtime Tool Verification ===\n');

  // 1. Start MCP server
  log('[1/5] Starting MCP server...');
  server = spawn('node', [SERVER_PATH], { stdio: ['pipe', 'pipe', 'pipe'] });
  server.stdout.on('data', onServerData);
  server.stderr.on('data', () => {});
  await sleep(2000);

  // 2. Initialize MCP
  log('[2/5] Initializing MCP...');
  await call('initialize', {
    protocolVersion: '2024-11-05',
    capabilities: {},
    clientInfo: { name: 'runtime-test', version: '1.0.0' },
  });
  server.stdin.write(
    JSON.stringify({
      jsonrpc: '2.0',
      method: 'notifications/initialized',
      params: {},
    }) + '\n',
  );
  await sleep(500);
  log('  OK MCP initialized');

  // 3. Start Godot editor
  log('[3/5] Starting Godot editor...');
  const godotLog = path.join(__dirname, '..', 'godot-output.log');
  godot = spawn(GODOT_PATH, ['--path', TEST_PROJECT, '--editor'], {
    windowsHide: false,
  });
  const logStream = fs.createWriteStream(godotLog, { flags: 'w' });
  godot.stdout.on('data', (d) => logStream.write(d));
  godot.stderr.on('data', (d) => logStream.write(d));

  log('  Waiting for Godot to connect...');
  let connected = false;
  for (let i = 0; i < 60; i++) {
    try {
      const r = await callTool('get_project_info', {}, 5000);
      if (r.data && !r.text.includes('not connected')) {
        connected = true;
        break;
      }
    } catch {}
    await sleep(500);
    process.stdout.write('.');
  }
  if (!connected) {
    console.error('\nFAIL: Godot did not connect');
    cleanup();
    process.exit(1);
  }
  console.log('\n  OK Godot connected!');

  // 4. Create a scene with runtime autoload and play it
  log('[4/5] Starting game (play mode)...');
  // First create and open a scene so we have something to play
  await callTool('create_scene', {
    path: 'res://_runtime_test_scene.tscn',
    root_node_type: 'Node2D',
  });
  await callTool('open_scene', { path: 'res://_runtime_test_scene.tscn' });
  await sleep(500);
  // Add NavigationAgent2D child for navigate_to test
  await callTool('add_node', {
    parent_path: '.',
    type: 'NavigationAgent2D',
    name: 'NavAgent',
  });
  await sleep(200);
  // Play the current scene
  const playResult = await callTool('play_scene', { mode: 'current' });
  log(`  Play: ${playResult.text.substring(0, 100)}`);

  log('  Waiting for game runtime...');
  let runtimeReady = false;
  for (let i = 0; i < 30; i++) {
    await sleep(1000);
    try {
      const r = await callTool('get_autoload', { name: 'mcp_runtime' }, 5000);
      if (r.data && !r.isError && !r.text.includes('not running')) {
        runtimeReady = true;
        break;
      }
    } catch {}
    process.stdout.write('.');
  }
  if (!runtimeReady) {
    console.log('\n  WARNING: Runtime not connected — testing with expected errors');
  } else {
    console.log('\n  OK Game runtime connected!');
  }

  // 5. Test Runtime tools
  log('[5/5] Testing Runtime tools...\n');
  const tests = [
    { tool: 'get_game_scene_tree', args: {}, desc: 'Get game scene tree' },
    {
      tool: 'get_game_node_properties',
      args: { path: '/root/Node2D' },
      desc: 'Get game node props',
    },
    {
      tool: 'set_game_node_property',
      args: { path: '/root/Node2D', property: 'visible', value: true },
      desc: 'Set game node prop',
    },
    {
      tool: 'execute_game_script',
      args: { code: 'return 42' },
      desc: 'Execute game script',
    },
    { tool: 'capture_frames', args: { count: 1 }, desc: 'Capture frames' },
    {
      tool: 'monitor_properties',
      args: { path: 'root', properties: ['position'] },
      desc: 'Monitor properties',
    },
    { tool: 'start_recording', args: {}, desc: 'Start recording' },
    { tool: 'stop_recording', args: {}, desc: 'Stop recording' },
    {
      tool: 'find_nodes_by_script',
      args: { script_path: 'res://addons/godot_mcp/services/mcp_runtime.gd' },
      desc: 'Find nodes by script',
    },
    {
      tool: 'get_autoload',
      args: { name: 'MCPRuntime' },
      desc: 'Get autoload',
    },
    {
      tool: 'batch_get_properties',
      args: { paths: ['/root/Node2D'], properties: ['name'] },
      desc: 'Batch get properties',
    },
    {
      tool: 'find_ui_elements',
      args: { filter: {} },
      desc: 'Find UI elements',
    },
    {
      tool: 'wait_for_node',
      args: { path: '/root/Node2D', timeout: 1 },
      desc: 'Wait for node',
    },
    {
      tool: 'find_nearby_nodes',
      args: { position: [0, 0, 0], radius: 100 },
      desc: 'Find nearby nodes',
    },
    {
      tool: 'navigate_to',
      args: { path: '/root/Node2D/NavAgent', target: [0, 0, 0] },
      desc: 'Navigate to',
    },
    {
      tool: 'move_to',
      args: { path: '/root/Node2D', target: [10, 10, 0] },
      desc: 'Move to',
    },
    {
      tool: 'watch_signals',
      args: { path: '/root/Node2D', signals: ['tree_entered'] },
      desc: 'Watch signals',
    },
    // Tools moved from editor tests — require running game
    {
      tool: 'get_game_screenshot',
      args: {},
      desc: 'Get game screenshot',
    },
    {
      tool: 'simulate_key',
      args: { keycode: 'Space', pressed: true },
      desc: 'Simulate key press',
    },
    {
      tool: 'simulate_mouse_click',
      args: { position: [100, 100] },
      desc: 'Simulate mouse click',
    },
    {
      tool: 'simulate_sequence',
      args: {
        events: [
          { type: 'key', keycode: 'Space', pressed: true },
          { type: 'delay', duration: 0.1 },
        ],
      },
      desc: 'Simulate input sequence',
    },
  ];

  let pass = 0,
    fail = 0;
  for (const t of tests) {
    try {
      const r = await callTool(t.tool, t.args);
      if (r.isError) {
        log(`  FAIL ${t.tool}: ${r.text.substring(0, 100)}`);
        fail++;
      } else {
        log(`  OK   ${t.tool}: ${r.text.substring(0, 80)}`);
        pass++;
      }
    } catch (e) {
      log(`  FAIL ${t.tool}: ${e.message}`);
      fail++;
    }
  }

  // Stop game
  log('\nStopping game...');
  try {
    await callTool('stop_scene', {});
  } catch {}
  // Cleanup test scene
  try {
    await callTool('delete_scene', { path: 'res://_runtime_test_scene.tscn' });
  } catch {}

  console.log(`\n=== Runtime Results ===`);
  console.log(`Total: ${tests.length}  Pass: ${pass}  Fail: ${fail}`);
  console.log(`Note: Runtime tools require a running game with mcp_runtime autoload.`);

  cleanup();
  process.exit(fail > 0 ? 1 : 0);
}

function cleanup() {
  if (godot) {
    try {
      godot.kill();
    } catch {}
  }
  if (server) {
    try {
      server.kill();
    } catch {}
  }
}

main().catch((e) => {
  console.error(e);
  cleanup();
  process.exit(1);
});
