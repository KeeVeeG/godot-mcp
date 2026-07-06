#!/usr/bin/env node
/**
 * Comprehensive Godot MCP Tool Verification — All 312 tools
 * Manages server + Godot lifecycle, tests every tool via MCP protocol,
 * cross-validates results with read tools or file inspection.
 * Writes results to test-results-full.json.
 */
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const SERVER_PATH = path.join(__dirname, '..', 'server', 'dist', 'index.js');
const GODOT_PATH = process.argv.find((a) => a.startsWith('--godot='))?.split('=')[1] || process.env.GODOT_PATH;
const TEST_PROJECT = process.argv.find((a) => a.startsWith('--project='))?.split('=')[1] || process.env.TEST_PROJECT;
const TIMEOUT_MS = 10000;

if (!GODOT_PATH || !TEST_PROJECT) {
  console.error('Usage: node run-full-verification.js --godot=/path/to/godot --project=/path/to/project [--skip=7,42] [--group=1,2,3]');
  console.error('  Or set GODOT_PATH and TEST_PROJECT environment variables');
  process.exit(1);
}
const RESULTS_FILE = path.join(__dirname, '..', 'test-results-full.json');
const SKIP_GROUPS = process.argv.includes('--skip') ? process.argv[process.argv.indexOf('--skip') + 1]?.split(',').map(Number) : [];
const GROUP_ARG = process.argv.find((a) => a.startsWith('--group='));
const ONLY_GROUPS = GROUP_ARG ? GROUP_ARG.split('=')[1]?.split(',').map(Number) : null;

// Load test case groups
const groups = [
  require('./cases/group_01_project.js'),
  require('./cases/group_02_scene.js'),
  require('./cases/group_03_node.js'),
  require('./cases/group_04_script.js'),
  require('./cases/group_05_editor.js'),
  require('./cases/group_06_input.js'),
  require('./cases/group_07_runtime.js'),
  require('./cases/group_08_animation.js'),
  require('./cases/group_09_tilemap.js'),
  require('./cases/group_10_theme.js'),
  require('./cases/group_11_shader.js'),
  require('./cases/group_12_resource.js'),
  require('./cases/group_13_physics.js'),
  require('./cases/group_14_scene3d.js'),
  require('./cases/group_15_particles.js'),
  require('./cases/group_16_navigation.js'),
  require('./cases/group_17_audio.js'),
  require('./cases/group_18_batch.js'),
  require('./cases/group_19_analysis.js'),
  require('./cases/group_20_testing.js'),
  require('./cases/group_21_profiling.js'),
  require('./cases/group_22_export.js'),
  require('./cases/group_23_addon_mgmt.js'),
  require('./cases/group_24_audio_config.js'),
  require('./cases/group_25_build_config.js'),
  require('./cases/group_26_debug_config.js'),
  require('./cases/group_27_debugging.js'),
  require('./cases/group_28_editor_config.js'),
  require('./cases/group_29_gameplay_auto.js'),
  require('./cases/group_30_memory_prof.js'),
  require('./cases/group_31_node_config.js'),
  require('./cases/group_32_physics_config.js'),
  require('./cases/group_33_platform_export.js'),
  require('./cases/group_34_platform_specific.js'),
  require('./cases/group_35_project_config.js'),
  require('./cases/group_36_project_creation.js'),
  require('./cases/group_37_rendering_config.js'),
  require('./cases/group_38_resource_config.js'),
  require('./cases/group_39_save_load.js'),
  require('./cases/group_40_scene_config.js'),
  require('./cases/group_41_visual_testing.js'),
  require('./cases/group_42_destructive.js'),
];

class FullVerifier {
  constructor() {
    this.server = null;
    this.godot = null;
    this.requestId = 0;
    this.pending = new Map();
    this.buffer = '';
    this.results = [];
    this.passed = 0;
    this.failed = 0;
    this.skipped = 0;
  }

  async start() {
    console.log('=== Godot MCP Full Verification ===\n');

    // 1. Start MCP server
    console.log('[1/4] Starting MCP server...');
    this.server = spawn('node', [SERVER_PATH], {
      stdio: ['pipe', 'pipe', 'pipe'],
      env: { ...process.env, GODOT_MCP_DEBUG: '1' },
    });

    this.server.stdout.on('data', (data) => this._onServerData(data));
    this.server.stderr.on('data', () => {});
    this.server.on('error', (e) => console.error('Server spawn error:', e.message));

    await this.sleep(2000);

    // 2. Initialize MCP
    console.log('[2/4] Initializing MCP...');
    const init = await this.call('initialize', {
      protocolVersion: '2024-11-05',
      capabilities: {},
      clientInfo: { name: 'full-verifier', version: '1.0.0' },
    });
    if (!init || init.error) {
      console.error('MCP init failed:', JSON.stringify(init?.error));
      this.shutdown(1);
      return;
    }
    console.log('  OK MCP initialized\n');

    // Send required MCP notification after initialize
    this.server.stdin.write(
      JSON.stringify({
        jsonrpc: '2.0',
        method: 'notifications/initialized',
        params: {},
      }) + '\n',
    );
    await this.sleep(500);

    // 3. Start Godot
    console.log('[3/4] Starting Godot Editor...');
    const GODOT_LOG = path.join(__dirname, '..', 'godot-output.log');
    this.godot = spawn(GODOT_PATH, ['--path', TEST_PROJECT, '--editor'], {
      windowsHide: false,
    });
    const godotLogStream = fs.createWriteStream(GODOT_LOG, { flags: 'w' });
    this.godot.stdout.on('data', (data) => godotLogStream.write(data));
    this.godot.stderr.on('data', (data) => godotLogStream.write(data));
    this.godot.on('error', (e) => console.error('Godot spawn error:', e.message));
    this.godot.on('close', () => godotLogStream.end());

    // 4. Wait for Godot connection (60s — Steam Godot + plugin init)
    console.log('[4/4] Waiting for Godot to connect...');
    let connected = false;
    for (let i = 0; i < 60; i++) {
      try {
        const r = await this.callTool('get_project_info', {}, 5000);
        const text = r?.result?.content?.[0]?.text || '';
        if (!text.includes('not connected') && !text.includes('"isError":true')) {
          connected = true;
          console.log('  OK Godot connected! Response: ' + text.substring(0, 100) + '\n');
          break;
        }
      } catch {}
      await this.sleep(500);
      process.stdout.write('.');
    }
    console.log('');
    if (!connected) {
      console.error('FAIL: Godot did not connect within 90s');
      this.shutdown(1);
      return;
    }

    // Run all test groups
    await this.runAllTests();

    // Generate report
    this.generateReport();
    this.shutdown(0);
  }

  async runAllTests() {
    for (let i = 0; i < groups.length; i++) {
      const group = groups[i];
      const groupNum = i + 1;
      if (SKIP_GROUPS.includes(groupNum)) {
        console.log(`\n--- Group ${groupNum}/41: ${group.name} (SKIPPED) ---`);
        for (const tc of group.tests) {
          this.results.push({
            group: group.name,
            tool: tc.tool,
            description: tc.description || '',
            status: 'skipped',
          });
        }
        continue;
      }
      if (ONLY_GROUPS && !ONLY_GROUPS.includes(groupNum)) {
        continue;
      }
      console.log(`\n--- Group ${groupNum}/41: ${group.name} (${group.tests.length} tools) ---`);

      // Ensure connection is alive before each group (skip first — already confirmed in start())
      if (i > 0) {
        await this.ensureConnected(groupNum);
      }

      await this.runGroup(group);
    }
  }

  async runGroup(group) {
    // Group setup (optional)
    if (group.setup) {
      try {
        await group.setup(this);
      } catch (e) {
        console.log('  SETUP ERROR: ' + e.message);
      }
    }

    for (const tc of group.tests) {
      if (tc.skip) {
        this.results.push({
          group: group.name,
          tool: tc.tool,
          description: tc.description || '',
          status: 'skipped',
        });
        this.skipped++;
        console.log(`  SKIP ${tc.tool.padEnd(35)} ${tc.description || ''}`);
        continue;
      }
      await this.runTest(group.name, tc);
    }

    // Group teardown (optional)
    if (group.teardown) {
      try {
        await group.teardown(this);
      } catch (e) {
        console.log('  TEARDOWN ERROR: ' + e.message);
      }
    }
  }

  async ensureConnected(nextGroupNum) {
    await this.sleep(2000);
    try {
      const r = await this.callTool('get_project_info', {}, 5000);
      const text = r?.result?.content?.[0]?.text || '';
      if (!text.includes('not connected') && !text.includes('"isError":true')) return;
    } catch {}
    console.log(`  [reconnect] Connection lost before Group ${nextGroupNum}, waiting...`);
    for (let i = 0; i < 30; i++) {
      await this.sleep(1000);
      try {
        const r = await this.callTool('get_project_info', {}, 5000);
        const text = r?.result?.content?.[0]?.text || '';
        if (!text.includes('not connected') && !text.includes('"isError":true')) {
          console.log(`  [reconnect] OK after ${i + 1}s`);
          return;
        }
      } catch {}
    }
    console.log(`  [reconnect] WARNING: Could not reconnect, proceeding anyway`);
  }

  _isNotConnectedError(text, errorMsg) {
    const s = (text || '') + ' ' + (errorMsg || '');
    return s.includes('not connected') || s.includes('WebSocket') || s.includes('ECONNREFUSED') || s.includes('Connection closed');
  }

  async runTest(groupName, tc) {
    const entry = {
      group: groupName,
      tool: tc.tool,
      description: tc.description || '',
      status: 'pending',
    };

    const MAX_ATTEMPTS = 2;
    for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
      if (attempt > 0) {
        console.log(`  [retry] ${tc.tool} — retrying (attempt ${attempt + 1})...`);
        await this.sleep(5000);
      }

      try {
        const result = await this.callTool(tc.tool, tc.args || {}, tc.timeout || TIMEOUT_MS);
        const text = result?.result?.content?.[0]?.text || '';
        const isError = result?.result?.isError === true;

        // Validate — always run validate if present, even on errors
        let valid = false;
        let validationMsg = '';
        if (tc.validate) {
          try {
            const data = this.parseResult(result);
            valid = await tc.validate(data, text, this);
            if (valid) {
              validationMsg = 'PASS';
            } else {
              validationMsg = (isError ? 'Error + ' : '') + 'Validation failed: ' + text.substring(0, 200);
            }
          } catch (e) {
            validationMsg = 'Validator threw: ' + e.message;
          }
        } else {
          // No validator
          if (isError && !tc.expectError) {
            validationMsg = 'Tool returned error: ' + text.substring(0, 200);
          } else if (tc.expectError && !isError) {
            validationMsg = 'Expected error but tool succeeded';
          } else {
            valid = !isError;
            validationMsg = valid ? 'PASS (no error)' : 'Tool errored';
          }
        }

        // If failed with connection error and we have retries left, loop
        if (!valid && attempt < MAX_ATTEMPTS - 1 && this._isNotConnectedError(text, validationMsg)) {
          continue;
        }

        if (valid) {
          entry.status = 'pass';
          entry.result = text.substring(0, 500);
          this.passed++;
          console.log(`  OK ${tc.tool.padEnd(35)} ${tc.description || ''}`);
          // Log first 150 chars of output for verification
          if (text) console.log(`     → ${text.substring(0, 150).replace(/\n/g, ' ')}`);
        } else {
          entry.status = 'fail';
          entry.error = validationMsg;
          entry.result = text.substring(0, 500);
          this.failed++;
          console.log(`  FAIL ${tc.tool.padEnd(35)} ${validationMsg}`);
          if (text) console.log(`     → ${text.substring(0, 150).replace(/\n/g, ' ')}`);
        }
      } catch (e) {
        // If timeout/connection error and we have retries left, loop
        if (attempt < MAX_ATTEMPTS - 1 && this._isNotConnectedError('', e.message)) {
          continue;
        }

        entry.error = e.message;
        entry.result = '';
        if (tc.expectError) {
          // Timeout or exception is expected (e.g. runtime tools without running game)
          entry.status = 'pass';
          this.passed++;
          console.log(`  OK ${tc.tool.padEnd(35)} ${tc.description || ''} (expected error: ${e.message.substring(0, 60)})`);
        } else {
          entry.status = 'error';
          this.failed++;
          console.log(`  ERROR ${tc.tool.padEnd(35)} ${e.message}`);
        }
      }

      // If we got here without `continue`, we have a final result
      break;
    }

    this.results.push(entry);
  }

  _onServerData(data) {
    this.buffer += data.toString();
    const lines = this.buffer.split('\n');
    this.buffer = lines.pop() || '';
    for (const line of lines) {
      if (!line.trim()) continue;
      try {
        const msg = JSON.parse(line);
        if (msg.id && this.pending.has(msg.id)) {
          const { resolve, timer } = this.pending.get(msg.id);
          clearTimeout(timer);
          this.pending.delete(msg.id);
          resolve(msg);
        }
      } catch {}
    }
  }

  async callTool(name, args = {}, timeout = TIMEOUT_MS) {
    return this.call('tools/call', { name, arguments: args }, timeout);
  }

  call(method, params, timeout = TIMEOUT_MS) {
    return new Promise((resolve, reject) => {
      const id = ++this.requestId;
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`Timeout ${timeout}ms: ${method}`));
      }, timeout);
      this.pending.set(id, { resolve, timer });
      this.server.stdin.write(JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n');
    });
  }

  parseResult(result) {
    if (!result) return null;
    const txt = result?.result?.content?.[0]?.text;
    if (!txt) return result?.result || result;
    try {
      return JSON.parse(txt);
    } catch {
      return txt;
    }
  }

  generateReport() {
    const summary = {
      timestamp: new Date().toISOString(),
      total: this.results.length,
      passed: this.passed,
      failed: this.failed,
      groups: {},
    };
    for (const r of this.results) {
      if (!summary.groups[r.group]) {
        summary.groups[r.group] = { passed: 0, failed: 0, skipped: 0, total: 0 };
      }
      summary.groups[r.group].total++;
      if (r.status === 'pass') summary.groups[r.group].passed++;
      else if (r.status === 'skipped') summary.groups[r.group].skipped++;
      else summary.groups[r.group].failed++;
    }

    const report = { summary, results: this.results };
    fs.writeFileSync(RESULTS_FILE, JSON.stringify(report, null, 2));

    console.log('\n=== RESULTS ===');
    console.log(`Total: ${summary.total}  Pass: ${summary.passed}  Fail: ${summary.failed}  Skipped: ${this.skipped}`);
    for (const [g, s] of Object.entries(summary.groups)) {
      const status = s.failed === 0 ? 'OK' : 'FAIL';
      const skipNote = s.skipped > 0 ? ` (${s.skipped} skipped)` : '';
      console.log(`  [${status}] ${g}: ${s.passed}/${s.total}${skipNote}`);
    }
    console.log(`\nReport written to ${RESULTS_FILE}`);
  }

  shutdown(code) {
    if (this.godot) {
      try {
        this.godot.kill();
      } catch {}
    }
    if (this.server) {
      try {
        this.server.stdin.end();
      } catch {}
      setTimeout(() => {
        try {
          this.server.kill();
        } catch {}
      }, 500);
    }
    setTimeout(() => process.exit(code), 1000);
  }

  sleep(ms) {
    return new Promise((r) => setTimeout(r, ms));
  }
}

process.on('SIGINT', () => {
  console.log('\nInterrupted');
  process.exit(0);
});
new FullVerifier().start().catch((err) => {
  console.error('Fatal:', err);
  process.exit(1);
});
