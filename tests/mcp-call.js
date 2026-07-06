#!/usr/bin/env node
/**
 * MCP Tool Caller - Calls tools via MCP protocol
 * Usage: node mcp-call.js <tool_name> [params_json]
 */

const { spawn } = require('child_process');
const path = require('path');

const SERVER_PATH = path.join(__dirname, 'server', 'dist', 'index.js');
const TIMEOUT_MS = 15000;

class McpCaller {
  constructor() {
    this.server = null;
    this.requestId = 0;
    this.pending = new Map();
    this.buffer = '';
  }

  async start() {
    this.server = spawn('node', [SERVER_PATH], {
      stdio: ['pipe', 'pipe', 'pipe'],
      env: { ...process.env, GODOT_MCP_DEBUG: '1' },
    });

    this.server.stdout.on('data', (data) => {
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
        } catch (e) {}
      }
    });

    this.server.stderr.on('data', (data) => {
      // stderr is debug output
    });

    // Wait for server to start
    await this.sleep(1000);

    // Initialize MCP
    const init = await this.call('initialize', {
      protocolVersion: '2024-11-05',
      capabilities: {},
      clientInfo: { name: 'tool-caller', version: '1.0.0' },
    });

    if (!init || init.error) {
      throw new Error('Failed to initialize MCP: ' + JSON.stringify(init));
    }

    return this;
  }

  async call(method, params, timeout = TIMEOUT_MS) {
    return new Promise((resolve, reject) => {
      const id = ++this.requestId;
      const request = { jsonrpc: '2.0', id, method, params };
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`Timeout after ${timeout}ms for ${method}`));
      }, timeout);
      this.pending.set(id, { resolve, timer });
      this.server.stdin.write(JSON.stringify(request) + '\n');
    });
  }

  async callTool(name, args = {}) {
    const result = await this.call('tools/call', { name, arguments: args });
    return result;
  }

  cleanup() {
    if (this.server) {
      this.server.stdin.end();
      setTimeout(() => {
        try {
          this.server.kill();
        } catch {}
      }, 500);
    }
  }

  sleep(ms) {
    return new Promise((r) => setTimeout(r, ms));
  }
}

async function main() {
  const toolName = process.argv[2];
  const paramsJson = process.argv[3] || '{}';

  if (!toolName) {
    console.error('Usage: node mcp-call.js <tool_name> [params_json]');
    process.exit(1);
  }

  let params;
  try {
    params = JSON.parse(paramsJson);
  } catch (e) {
    console.error('Invalid JSON params:', e.message);
    process.exit(1);
  }

  const caller = new McpCaller();
  try {
    await caller.start();
    const result = await caller.callTool(toolName, params);
    console.log(JSON.stringify(result, null, 2));
  } catch (e) {
    console.error('Error:', e.message);
    process.exit(1);
  } finally {
    caller.cleanup();
  }
}

main();
