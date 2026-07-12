# Godot MCP

**AI-powered game development for Godot Engine via Model Context Protocol**

[![TypeScript](https://img.shields.io/badge/TypeScript-5.7-blue?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![GDScript](https://img.shields.io/badge/GDScript-Godot%204.x-478cbf?logo=godotengine&logoColor=white)](https://docs.godotengine.org/)
[![Godot 4.x](https://img.shields.io/badge/Godot-4.x-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![MCP](https://img.shields.io/badge/MCP-Compatible-orange)](https://modelcontextprotocol.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

🌐 **[Website](https://nikita-abaturov.ru/godot-mcp/)** · 📋 **[Tools Catalog](https://nikita-abaturov.ru/godot-mcp/tools.html)** · 💬 **[GitHub](https://github.com/KeeVeeG/godot-mcp)** · 📦 **[Releases](https://github.com/KeeVeeG/godot-mcp/releases)**

Godot MCP connects AI assistants (Claude, Cursor, VS Code Copilot, OpenCode, and any MCP-compatible client) directly to the Godot editor. It exposes 300+ tools across 40+ modules, covering everything from scene construction and node manipulation to runtime inspection, input recording, physics setup, animation authoring, project export, addon management, debugging, and platform-specific configuration.

The AI can read your scene tree, create nodes, write scripts, simulate gameplay input, capture screenshots, run assertions, and batch-modify properties across scenes, all through a single WebSocket bridge.

> This project was developed with the help of multiple AI models: MiMo-V2.5-Pro, DeepSeek V4 Pro, DeepSeek V4 Flash, and Qwen 3.7 Plus.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Installation](#installation)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

## Features

- **300+ tools** for complete Godot development workflows
- **Real-time scene manipulation** — add, delete, move, rename, and reconfigure nodes without leaving your AI chat
- **Runtime game inspection** — query the live scene tree, read/write properties during gameplay, execute GDScript in the running game
- **Input recording and replay** — record player sessions, replay at variable speed, simulate keyboard/mouse/action input
- **Visual testing with screenshots** — capture editor and game viewport screenshots for visual regression checks
- **Animation authoring** — create clips, add tracks, set keyframes, build state machines and blend trees
- **Physics setup** — add bodies, collision shapes, raycasts, physics materials; configure layers/masks
- **Audio management** — add players, configure bus layouts, insert effects (reverb, delay, chorus, etc.)
- **Navigation** — set up regions, agents, bake navmeshes, query pathfinding between points
- **TileMap editing** — set cells, fill rectangles, clear areas, read tile data
- **Theme and shader tools** — create themes, set colors/fonts/styleboxes; create, edit, and validate shaders
- **Batch operations** — find nodes by type, set properties across scenes, detect circular dependencies
- **Testing framework** — run multi-step test scenarios, assert node state, check screen text, run stress tests
- **Undo/redo support** — all editor mutations go through Godot's built-in undo system
- **Auto port scanning** — server and plugin negotiate on ports 6505-6514 automatically
- **Zero project modification** — installs as a standard Godot plugin, no engine changes required

## Architecture

```
MCP Client (Claude, Cursor, VS Code, OpenCode)
    │  stdio (JSON-RPC 2.0)
    ▼
Node.js MCP Server (TypeScript)
    │  WebSocket (JSON-RPC 2.0)
    ▼
Godot Editor Plugin (GDScript)
    ├── Command Router → 40+ command modules → 300+ tools
    ├── UndoRedo Helper
    └── Runtime Autoload (mcp_runtime.gd)
        — scene tree queries, property R/W, input simulation,
          screenshot capture, signal watching
```

**Data flow:** AI client sends a tool call over stdio → MCP server looks up the tool in the registry → forwards via WebSocket to the Godot plugin → command router dispatches to the correct module → module calls Godot Editor API (with undo/redo) → result flows back to the AI client.

See the [website](https://nikita-abaturov.ru/godot-mcp/#architecture) for a detailed architecture diagram.

## Installation

### Prerequisites

- **Godot 4.x** (tested with 4.7)
- An MCP-compatible AI client (Claude Desktop, Cursor, VS Code with Copilot, OpenCode, etc.)

### Godot Addon

**Option A — Download from Releases (recommended)**

1. Go to the [Releases page](https://github.com/KeeVeeG/godot-mcp/releases) and download the latest `addons` zip asset (e.g. `keeveeg-godot-mcp-v1.1.0-addons.zip`).
2. Extract the zip into your Godot project root — this places `addons/godot_mcp/` in the correct location.
3. Open your project in Godot.
4. Go to **Project → Project Settings → Plugins**.
5. Find **Godot MCP** in the list and set it to **Active**.

**Option B — Copy from the repository**

1. Copy the `addons/godot_mcp/` folder from this repository into your project's `addons/` directory.
2. Open your project in Godot.
3. Go to **Project → Project Settings → Plugins**.
4. Find **Godot MCP** in the list and set it to **Active**.

After enabling, the plugin scans ports 6505-6514 for a running MCP server. Once connected, the **MCP** tab appears in the bottom panel showing connection status and activity log.

## Configuration

### MCP Client

Add the following to your MCP client's configuration file:

```json
{
  "mcpServers": {
    "godot": {
      "command": "npx",
      "args": ["-y", "@keeveeg/godot-mcp"]
    }
  }
}
```

For local development, use the full path:

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["/path/to/godot-mcp/server/dist/index.js"]
    }
  }
}
```

| Client         | Config file                                                                                                            |
| -------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Claude Desktop | `~/.config/claude/claude_desktop_config.json` (Linux/macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows) |
| Cursor         | `.cursor/mcp.json` in project root                                                                                     |
| OpenCode       | `opencode.json` in project root or `~/.config/opencode/opencode.json` globally                                         |

Example `opencode.json`:

```json
{
  "mcp": {
    "godot": {
      "type": "local",
      "command": ["npx", "-y", "@keeveeg/godot-mcp"]
    }
  }
}
```

### Environment Variables

| Variable          | Default | Description                                            |
| ----------------- | ------- | ------------------------------------------------------ |
| `GODOT_MCP_DEBUG` | (unset) | Set to any value to enable debug logging in the server |

### Tool Enable/Disable

Create a `godot_mcp_config.json` file in your Godot project root to selectively disable tools:

```json
{
  "enabled_tools": {
    "delete_scene": false,
    "reload_project": false,
    "execute_editor_script": false
  }
}
```

Tools not listed in the config are enabled by default. The plugin reads this file on startup.

## Tools

All 300+ tools across 40+ modules are documented in the **[Tools Catalog](https://nikita-abaturov.ru/godot-mcp/tools.html)** with searchable descriptions and category groupings.

## Troubleshooting

### Connection Problems

**"Godot editor is not connected"**

The MCP server is running but Godot hasn't connected yet.

- Make sure the Godot editor is open with the MCP plugin active
- Check the **MCP** panel in Godot's bottom dock for connection status
- Verify no firewall is blocking localhost connections on ports 6505-6514
- Look at Godot's output log for `[MCP]` messages

**"Failed to bind to any port in range 6505-6514"**

All ports in the scanning range are occupied.

- Check if another instance of the MCP server is already running
- Kill any stale `node` processes: `pkill -f "godot-mcp"` (Linux/macOS) or use Task Manager (Windows)
- The server will automatically try the next available port

### Godot Path Not Found

- Use `res://` prefixed paths (e.g., `res://scenes/main.tscn`)
- Use `get_filesystem_tree` to verify the project structure
- Make sure the Godot project is the one you think it is (check `get_project_info`)

### WebSocket Timeout

**"Request timed out after 30000ms"**

- The editor may be busy (compiling, loading a large scene)
- Check if a dialog is blocking the editor (the plugin auto-dismisses most dialogs during gameplay)
- Try the request again — for large operations, the editor may need more time

### Plugin Not Loading

- Verify the `addons/godot_mcp/` directory is in the correct location
- Go to **Project → Project Settings → Plugins** and check if Godot MCP appears
- If it appears but is disabled, enable it
- Check for GDScript errors in the output log
- Try **Project → Reload Current Project**

### Runtime Tools Not Working

The `mcp_runtime.gd` autoload must be present for runtime tools to work. The plugin registers it automatically, but verify:

1. Open `project.godot` and check the `[autoload]` section
2. You should see: `mcp_runtime="res://addons/godot_mcp/services/mcp_runtime.gd"`
3. **Important**: Do NOT use the `*` prefix — the `*` means "editor only" and the autoload won't load in-game
4. Check Godot's output log for `[MCP Runtime] Loaded and ready for IPC`
