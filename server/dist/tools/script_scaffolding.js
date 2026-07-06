/**
 * Script scaffolding tools - 8 tools for common game script patterns
 */
import { callGodot } from '../server.js';
import { z, FilePath, Name, Dimension } from './shared-types.js';
export function registerScriptScaffoldingTools(server, bridge) {
  // 1. create_character_controller
  server.registerTool(
    'create_character_controller',
    {
      description: 'Create a character controller script with movement, jumping, and input handling',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        type: Dimension.describe('Controller dimension type'),
        controller: z.enum(['platformer', 'top_down', 'fps', 'vehicle']).describe('Movement controller style'),
      },
    },
    async (args) => callGodot(bridge, 'script_scaffolding/create_character_controller', args),
  );
  // 2. create_state_machine
  server.registerTool(
    'create_state_machine',
    {
      description: 'Create a generic state machine script with enter/exit/update for each state',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        states: z.array(z.string()).describe('List of state names'),
        initial_state: Name.optional().describe('Initial state (defaults to first in list)'),
      },
    },
    async (args) => callGodot(bridge, 'script_scaffolding/create_state_machine', args),
  );
  // 3. create_singleton
  server.registerTool(
    'create_singleton',
    {
      description: 'Create an autoload singleton script with optional methods',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        name: Name.describe('Singleton class name'),
        methods: z.array(z.string()).optional().describe('Method names to stub out'),
      },
    },
    async (args) => callGodot(bridge, 'script_scaffolding/create_singleton', args),
  );
  // 4. create_signal_bus
  server.registerTool(
    'create_signal_bus',
    {
      description: 'Create a signal bus autoload for decoupled event communication',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        signals: z
          .array(
            z.object({
              name: z.string().describe('Signal name'),
              params: z.array(z.string()).optional().describe('Signal parameter names'),
            }),
          )
          .describe('Signals to define on the bus'),
      },
    },
    async (args) => callGodot(bridge, 'script_scaffolding/create_signal_bus', args),
  );
  // 5. create_save_system
  server.registerTool(
    'create_save_system',
    {
      description: 'Create a save/load system script with encryption and versioning support',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        format: z.enum(['json', 'binary', 'resource']).optional().describe('Save file format'),
      },
    },
    async (args) => callGodot(bridge, 'script_scaffolding/create_save_system', args),
  );
  // 6. create_object_pool
  server.registerTool(
    'create_object_pool',
    {
      description: 'Create an object pool script for efficient reuse of frequently spawned objects',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        object_type: z.string().describe("The node type to pool (e.g. 'Bullet', 'Particle')"),
        pool_size: z.number().optional().describe('Initial pool size (defaults to 20)'),
      },
    },
    async (args) => callGodot(bridge, 'script_scaffolding/create_object_pool', args),
  );
  // 7. create_command_pattern
  server.registerTool(
    'create_command_pattern',
    {
      description: 'Create a command pattern implementation for undo/redo and input replay',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        commands: z.array(z.string()).describe('Command names to implement'),
      },
    },
    async (args) => callGodot(bridge, 'script_scaffolding/create_command_pattern', args),
  );
  // 8. create_observer_pattern
  server.registerTool(
    'create_observer_pattern',
    {
      description: 'Create an observer/event emitter pattern script for decoupled notifications',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        events: z.array(z.string()).describe('Event names the observer will emit'),
      },
    },
    async (args) => callGodot(bridge, 'script_scaffolding/create_observer_pattern', args),
  );
}
//# sourceMappingURL=script_scaffolding.js.map
