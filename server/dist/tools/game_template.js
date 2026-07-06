/**
 * Game template tools - 8 tools for complete game genre scaffolding
 */
import { callGodot } from '../server.js';
import { z, Name, FilePath } from './shared-types.js';
export function registerGameTemplateTools(server, bridge) {
  // 1. create_platformer_template
  server.registerTool(
    'create_platformer_template',
    {
      description: 'Create a complete 2D platformer project structure with player, enemies, levels, and UI',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        name: Name.describe('Game name'),
        features: z.array(z.string()).optional().describe("Additional features to include (e.g. 'double_jump', 'wall_slide', 'dash')"),
      },
    },
    async (args) => callGodot(bridge, 'game_template/create_platformer', args),
  );
  // 2. create_rpg_template
  server.registerTool(
    'create_rpg_template',
    {
      description: 'Create a complete RPG project structure with player, NPCs, inventory, dialog, and quests',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        name: Name.describe('Game name'),
        features: z.array(z.string()).optional().describe("Additional features (e.g. 'turn_based', 'real_time_combat', 'crafting')"),
      },
    },
    async (args) => callGodot(bridge, 'game_template/create_rpg', args),
  );
  // 3. create_fps_template
  server.registerTool(
    'create_fps_template',
    {
      description: 'Create a complete FPS project structure with player controller, weapons, enemies, and HUD',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        name: Name.describe('Game name'),
        features: z.array(z.string()).optional().describe("Additional features (e.g. 'sprint', 'crouch', 'inventory')"),
      },
    },
    async (args) => callGodot(bridge, 'game_template/create_fps', args),
  );
  // 4. create_puzzle_template
  server.registerTool(
    'create_puzzle_template',
    {
      description: 'Create a complete puzzle game project structure with grid system, piece management, and scoring',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        name: Name.describe('Game name'),
        features: z.array(z.string()).optional().describe("Additional features (e.g. 'match3', 'physics_puzzle', 'tile_swap')"),
      },
    },
    async (args) => callGodot(bridge, 'game_template/create_puzzle', args),
  );
  // 5. create_racing_template
  server.registerTool(
    'create_racing_template',
    {
      description: 'Create a complete racing game project structure with vehicle physics, track, and lap system',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        name: Name.describe('Game name'),
        features: z.array(z.string()).optional().describe("Additional features (e.g. 'drift', 'boost', 'ai_opponents')"),
      },
    },
    async (args) => callGodot(bridge, 'game_template/create_racing', args),
  );
  // 6. create_strategy_template
  server.registerTool(
    'create_strategy_template',
    {
      description: 'Create a complete strategy game project structure with grid, units, resources, and turns',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        name: Name.describe('Game name'),
        features: z.array(z.string()).optional().describe("Additional features (e.g. 'fog_of_war', 'tech_tree', 'diplomacy')"),
      },
    },
    async (args) => callGodot(bridge, 'game_template/create_strategy', args),
  );
  // 7. create_visual_novel_template
  server.registerTool(
    'create_visual_novel_template',
    {
      description: 'Create a complete visual novel project structure with dialog system, character portraits, and branching',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        name: Name.describe('Game name'),
        features: z.array(z.string()).optional().describe("Additional features (e.g. 'save_system', 'gallery', 'achievements')"),
      },
    },
    async (args) => callGodot(bridge, 'game_template/create_visual_novel', args),
  );
  // 8. create_custom_template
  server.registerTool(
    'create_custom_template',
    {
      description: 'Create a custom game project structure by selecting specific components to include',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        name: Name.describe('Game name'),
        components: z.array(z.enum(['player', 'enemies', 'ui', 'levels', 'save', 'audio', 'physics'])).describe('Components to include'),
      },
    },
    async (args) => callGodot(bridge, 'game_template/create_custom', args),
  );
}
//# sourceMappingURL=game_template.js.map
