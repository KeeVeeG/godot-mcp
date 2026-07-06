# Godot MCP

**AI-powered game development for Godot Engine via Model Context Protocol**

[![TypeScript](https://img.shields.io/badge/TypeScript-5.7-blue?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![GDScript](https://img.shields.io/badge/GDScript-Godot%204.x-478cbf?logo=godotengine&logoColor=white)](https://docs.godotengine.org/)
[![Godot 4.x](https://img.shields.io/badge/Godot-4.x-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![MCP](https://img.shields.io/badge/MCP-Compatible-orange)](https://modelcontextprotocol.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Godot MCP connects AI assistants (Claude, Cursor, VS Code Copilot, OpenCode, and any MCP-compatible client) directly to the Godot editor. It exposes 300+ tools across 40+ modules, covering everything from scene construction and node manipulation to runtime inspection, input recording, physics setup, animation authoring, project export, addon management, debugging, and platform-specific configuration.

The AI can read your scene tree, create nodes, write scripts, simulate gameplay input, capture screenshots, run assertions, and batch-modify properties across scenes, all through a single WebSocket bridge.

📋 Browse the [full tools catalog](https://keeveeg.github.io/godot-mcp/tools.html) — searchable list of all 300+ tools with descriptions.

> This project was fully developed by **MiMo-V2.5-Pro** (Xiaomi AI).

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Installation](#installation)
- [Configuration](#configuration)
- [Tool Categories](#tool-categories)
- [Troubleshooting](#troubleshooting)

## Features

- **300+ tools** for complete Godot development workflows
- **Real-time scene manipulation**. Add, delete, move, rename, and reconfigure nodes without leaving your AI chat
- **Runtime game inspection**. Query the live scene tree, read/write properties during gameplay, and execute GDScript in the running game
- **Input recording and replay**. Record player sessions, replay them at variable speed, and simulate keyboard/mouse/action input
- **Visual testing with screenshots**. Capture editor and game viewport screenshots for visual regression checks
- **Animation authoring**. Create clips, add tracks, set keyframes, build state machines, and configure blend trees
- **Physics setup**. Add bodies, collision shapes, raycasts, physics materials, and configure layers/masks
- **Audio management**. Add players, configure bus layouts, insert effects (reverb, delay, chorus, etc.)
- **Navigation**. Set up regions, agents, bake navmeshes, and query pathfinding between points
- **TileMap editing**. Set cells, fill rectangles, clear areas, and read tile data
- **Theme and shader tools**. Create themes, set colors/fonts/styleboxes; create, edit, and validate shaders
- **Batch operations**. Find nodes by type, set properties across scenes, detect circular dependencies
- **Testing framework**. Run multi-step test scenarios, assert node state, check screen text, run stress tests
- **Undo/redo support**. All editor mutations go through Godot's built-in undo system
- **Auto port scanning**. Server and plugin negotiate on ports 6505-6514 automatically
- **Zero project modification**. The addon installs as a standard Godot plugin, no engine changes required

## Architecture

```
+-----------------------------------------------------------------------+
|                   MCP Client (Claude, Cursor, VS Code, OpenCode)      |
|                         |  stdio (JSON-RPC 2.0)                       |
+-----------------------------------------------------------------------+
                          |
                          v
+-----------------------------------------------------------------------+
|              Node.js MCP Server (TypeScript)                          |
|                    server/src/index.ts                                |
|                                                                       |
|  +----------------+  +----------------+  +-------------------------+  |
|  | Tool Registry  |  | WebSocket      |  | JSON-RPC 2.0            |  |
|  | (40+ modules)  |  | Server         |  | Bridge                  |  |
|  +-------+--------+  +-------+--------+  +-------------------------+  |
|          |                   |                                        |
|          |    +--------------+                                        |
|          |    |  :6505-6514 (auto port scan)                          |
|          v    v                                                       |
+-----------------------------------------------------------------------+
          |
          | WebSocket (JSON-RPC 2.0)
          v
+------------------------------------------------------------------------+
|           Godot Editor Plugin (GDScript)                               |
|                                                                        |
|  +------------------------------------------------------------------+  |
|  |        addons/godot_mcp/                                         |  |
|  |  +----------------+  +----------------+  +--------------------+  |  |
|  |  | WebSocket      |  | Command        |  | UndoRedo           |  |  |
|  |  | Client         |  | Router         |  | Helper             |  |  |
|  |  +----------------+  +----------------+  +--------------------+  |  |
|  |  +------------------------------------------------------------+  |  |
|  |  | Command Modules (40+ files, 300+ tools)                    |  |  |
|  |  | project | scene | node | script | editor | input | ...     |  |  |
|  |  +------------------------------------------------------------+  |  |
|  +------------------------------------------------------------------+  |
|                                                                        |
|  +------------------------------------------------------------------+  |
|  |  Runtime Autoload (mcp_runtime.gd)                               |  |
|  |  - Scene tree queries at runtime                                 |  |
|  |  - Property read/write during gameplay                           |  |
|  |  - Input simulation and recording                                |  |
|  |  - Screenshot capture                                            |  |
|  |  - Signal watching                                               |  |
|  +------------------------------------------------------------------+  |
+------------------------------------------------------------------------+
```

**Data flow:**

1. AI client sends a tool call over stdio (JSON-RPC 2.0)
2. MCP server receives it, looks up the tool in the registry
3. Server forwards the call over WebSocket to the Godot editor plugin
4. Plugin's command router dispatches to the correct command module
5. Command module calls Godot Editor API (with undo/redo wrapping for mutations)
6. Result flows back: Plugin -> WebSocket -> MCP Server -> stdio -> AI Client

## Installation

### Prerequisites

- **Godot 4.x** (tested with 4.7)
- An MCP-compatible AI client (Claude Desktop, Cursor, VS Code with Copilot, OpenCode, etc.)

### Godot Addon Installation

1. Copy `addon/godot_mcp/` into your project's `addons/` directory:

```
your-godot-project/
  addons/
    godot_mcp/
      plugin.gd
      websocket_client.gd
      command_router.gd
      config.gd
      commands/
        project_commands.gd
        scene_commands.gd
        node_commands.gd
        ... (22 command modules)
      services/
        mcp_runtime.gd
      ui/
        status_panel.gd
      utils/
        undo_helper.gd
        variant_codec.gd
```

2. Open your project in Godot.

3. Go to **Project -> Project Settings -> Plugins**.

4. Find **Godot MCP** in the list and set it to **Active**.

5. The plugin will start scanning ports 6505-6514 for a running MCP server. Once connected, the **MCP** tab appears in the bottom panel showing connection status and activity log.

## Configuration

### MCP Client

Add the following to your MCP client's configuration file:

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["/absolute/path/to/godot-mcp/server/dist/index.js"]
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
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["C:/path/to/godot-mcp/server/dist/index.js"]
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

## Tool Categories

All 300+ tools organized by category. Each tool maps to a Godot editor operation.

### Project

Query project metadata, browse the filesystem tree, search files by name or content, read and write project settings in `project.godot`, and convert between Godot UIDs and file paths.

### Scene

Full lifecycle management for scenes: create new scenes with a chosen root node type, open and save scene files, delete scenes from disk, instantiate scene references as children, play and stop scenes in the editor, and list all currently loaded scenes.

### Node

Core scene-tree manipulation: add, delete, duplicate, move, and rename nodes; read and write any property on a node; connect and disconnect signals; manage node groups and editor selection; and set anchor presets on Control nodes.

### Script

GDScript file operations: list all scripts in the project, read and create script files, edit scripts by replacing text segments, attach scripts to nodes, validate scripts for syntax errors, and search across project files.

### Editor

Interact with the Godot editor itself: capture editor and game screenshots, execute arbitrary GDScript in the editor context, read errors and the output log, reload plugins and the project, and inspect signal connections on nodes.

### Input

Simulate player input during gameplay: send keyboard key presses/releases, mouse clicks and movements, trigger input actions from the InputMap, run sequenced input chains with timing, and manage the project's input action definitions.

### Runtime

Deep runtime introspection: query the live scene tree and node properties during gameplay, execute GDScript in the running game, capture viewport frames, monitor property changes over time, record and replay sessions, find nodes by script or proximity, click UI elements by text, and watch for signal emissions.

### Animation

Animation authoring and management: list, create, and remove animations on an AnimationPlayer; add tracks and set keyframes; build and inspect AnimationTree state machines and blend trees; set tree parameters; and add states to state machines.

### TileMap

2D tile-based level editing: set individual cells, fill rectangular regions, read cell data, clear areas, query the TileSet configuration, and list all used cell coordinates.

### Theme

UI theme creation and modification: create Theme resources, set colors, constants, font sizes, and StyleBoxes for specific control types, and inspect the full override list of an existing theme.

### Shader

Shader development workflow: create and read shader files, edit shaders by replacing text, create ShaderMaterials and assign them to nodes, get and set shader uniform parameters, list all shaders in the project, and validate shaders for compilation errors.

### Resource

General resource management: read `.tres`/`.res` files, edit resource properties, create new resources, get preview thumbnails, manage autoload singletons, duplicate resources, list resources by type, and inspect resource dependency graphs.

### Physics

Physics body and collision setup: add and configure RigidBody, CharacterBody, and StaticBody nodes; add collision shapes; set collision layers and masks; add raycast nodes; and create and assign physics materials.

### Scene3D

3D scene construction: add MeshInstance3D nodes with primitive meshes, configure Camera3D nodes, set up DirectionalLight3D, OmniLight3D, and SpotLight3D, configure WorldEnvironment, add GridMap nodes for tile-based 3D levels, and apply StandardMaterial3D or ShaderMaterial.

### Particles

Particle system creation and configuration: create GPUParticles2D/3D nodes, set ParticleProcessMaterial properties, configure color gradients, apply presets (fire, smoke, sparks, rain, snow, confetti, magic), set emission shapes, and adjust velocity curves.

### Navigation

Pathfinding infrastructure: add NavigationRegion2D/3D, NavigationAgent2D/3D, and NavigationLink2D/3D nodes; bake navigation meshes; set navigation layers and masks; query navigation map data; and find paths between two points.

### Audio

Audio playback and bus management: add AudioStreamPlayer, AudioStreamPlayer2D, and AudioStreamPlayer3D nodes; create and configure audio buses; insert effects like reverb, delay, chorus, and compressor; adjust bus volume, mute, and solo; and read the current bus layout.

### Batch

Bulk operations across scenes: find all nodes of a specific type, trace signal connections, set a property on every matching node at once, find references to nodes and scripts across scenes, get scene dependencies, apply cross-scene property changes, and detect circular dependencies.

### Analysis

Project health and complexity analysis: analyze scene node count, depth, and resource usage; map signal flow and connections across a scene; find unused resources that no scene or script references; and get aggregate project statistics like file counts, sizes, node types, and script languages.

### Testing

Automated testing against the running game: run multi-step test scenarios combining input, waits, and assertions; check node property values and on-screen text; spawn entities and measure performance under stress; and get aggregated test reports for the session.

### Profiling

Performance monitoring: read FPS, memory, physics, rendering, and audio counters from Godot's built-in performance monitors, and query editor-level metrics like compile times and resource load times.

### Export

Project export management: list configured export presets, export the project for specific platforms, validate the project for export readiness, query available export templates, and create new export presets.

### Addon Management

Plugin and addon lifecycle: list all installed addons with versions and status, install addons from the Asset Library, git repositories, or local paths, uninstall addons and clean up their files, update addons to the latest version, and configure addon settings.

### Audio Configuration

Advanced audio bus layout management: read all audio settings including bus layout and driver info, replace the entire bus layout, add or remove individual buses at specific positions, set bus volume levels, and inspect all effects on a bus with their properties.

### Build Configuration

Build pipeline configuration: read and set build configuration presets, choose the scripting backend, configure export filters for resource inclusion, set custom feature tags, adjust debug and optimization options, validate build settings, and get CLI export commands for specific platforms.

### Debug Configuration

Debug and profiling settings: read and configure remote debugging connections, enable or disable built-in profilers, set error and warning handling behavior during gameplay, and read or clear the editor log.

### Debugging

Interactive debugging workflow: set and remove breakpoints (with optional conditions), list all active breakpoints, inspect the call stack with local variables when paused, evaluate GDScript expressions in context, step over, step into, and continue execution.

### Editor Configuration

Editor appearance and layout: read all editor settings, switch color themes, change workspace layouts, adjust font size and UI scale, save and load named layouts, and reset to factory defaults.

### Gameplay Automation

Automated gameplay testing: run scripted gameplay scenarios combining input, waits, and checks; record gameplay sessions capturing input events and game state; replay recordings; create test characters at specific positions; navigate characters using direct movement or pathfinding; assert multiple game state conditions at once; and wait for specific game events with timeouts.

### Memory Profiling

Memory diagnostics: get detailed memory usage breakdowns by category (static, video, textures, buffers, objects), track object creation for specific classes over time, detect potential memory leaks in the scene tree and object graph, count live objects by class, and force garbage collection with a report of freed memory.

### Node Configuration

Node type introspection and presets: get default property values for any node type, apply configuration presets (e.g., platformer body, top-down camera), browse all available node types by category, and inspect signals, methods, enumerations, constants, and the full class hierarchy for a type.

### Physics Configuration

Physics engine tuning: read and set gravity vectors and magnitudes, change the physics simulation tick rate, select the physics engine backend, assign human-readable names to collision layers, and configure default linear damping for physics bodies.

### Platform Export

Platform-specific build pipeline: export for a specific target platform, validate platform export readiness, list installed export templates, create platform-specific export presets, run exported builds and capture their output, and perform detailed platform export validation.

### Platform Specific

Platform configuration for mobile and web: read and write platform-specific settings, configure iOS bundle ID, team ID, and code signing; set up Android package names, keystores, and permissions; configure web/HTML5 canvas resize, threading, and PWA support; and query platform capabilities and build validation.

### Project Configuration

Project settings and input management: read and write individual project settings, get all settings with optional prefix filtering, reset settings to defaults, manage the entire input map (actions, deadzones, event mappings), and configure autoload singleton ordering.

### Project Creation

New project scaffolding: create complete Godot projects from scratch or from templates, scaffold standard folder structures, import assets into new projects, initialize git repositories with proper `.gitignore`, generate README and LICENSE files, install dependencies and addons, validate project structure, and list available templates.

### Rendering Configuration

Rendering pipeline settings: read all rendering settings, apply quality presets, switch the renderer, configure anti-aliasing (MSAA, FXAA, TAA), adjust shadow and global illumination quality, enable or disable post-processing, set viewport dimensions and stretch mode, configure window size and vsync, and query GPU info and rendering statistics.

### Resource Configuration

Resource type system: browse all registered resource types, inspect serializable properties for any resource type with their types, create resource files from templates or defaults, import files as resources with custom settings, and read or update resource import settings.

### Save/Load

Game state persistence testing: save the current game state to numbered slots with metadata, load states from save files, list and delete save files, and compare two save states to get a diff of their contents.

### Scene Configuration

Scene structure metadata: inspect the scene inheritance chain (instantiated and inherited scenes), toggle unique name flags on nodes, manage scene groups and which nodes belong to them, and read or set metadata on the scene's root node.

### Visual Testing

Visual regression testing: take screenshots with scene context metadata, compare screenshots pixel-by-pixel with mismatch percentages, assert that screenshots match baselines within thresholds, record multiple frames over time for regression testing, aggregate visual diff reports, and manage visual baselines for future comparisons.

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

**Tools return errors about missing files or paths**

- Use `res://` prefixed paths (e.g., `res://scenes/main.tscn`)
- Use `get_filesystem_tree` to verify the project structure
- Make sure the Godot project is the one you think it is (check `get_project_info`)

### WebSocket Timeout

**"Request timed out after 30000ms"**

The Godot editor took too long to respond.

- The editor may be busy (compiling, loading a large scene)
- Check if a dialog is blocking the editor (the plugin auto-dismisses most dialogs during gameplay)
- Try the request again
- For large operations, the editor may need more time

### Plugin Not Loading

**No `[MCP]` messages in Godot's output log**

- Verify the `addons/godot_mcp/` directory is in the correct location
- Go to **Project -> Project Settings -> Plugins** and check if Godot MCP appears
- If it appears but is disabled, enable it
- Check for GDScript errors in the output log
- Try **Project -> Reload Current Project**

### Tools Not Working During Gameplay

**Runtime tools return errors when the game is running**

The `mcp_runtime.gd` autoload must be present in your project for runtime tools to work. The plugin registers it automatically in `project.godot`, but verify it's there:

1. Open `project.godot` and check the `[autoload]` section
2. You should see: `mcp_runtime="res://addons/godot_mcp/services/mcp_runtime.gd"`
3. **Important**: Do NOT use the `*` prefix (e.g. `*res://...`) — the `*` means "editor only" and the autoload won't load in-game
4. Check Godot's output log for `[MCP Runtime] Loaded and ready for IPC`
5. If the autoload isn't showing, try stopping and restarting the game

### Port Already in Use

**Server logs show "Port 6505 is busy"**

This is normal. The server will try port 6506, then 6507, etc., until it finds an open one. The Godot plugin scans all ports in the range, so it will find the server regardless of which port it landed on.
