/**
 * Scene scaffolding tools - 8 tools for scene template creation
 */
import { callGodot } from '../server.js';
import { z, FilePath, Name, Dimension } from './shared-types.js';
export function registerSceneScaffoldingTools(server, bridge) {
  // 1. create_main_scene
  server.registerTool(
    'create_main_scene',
    {
      description: 'Create a main scene for the game with appropriate root node and basic setup',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        type: z.enum(['2d', '3d', 'ui']).describe('Scene dimension type'),
        name: Name.optional().describe("Scene name (defaults to 'Main')"),
      },
    },
    async (args) => callGodot(bridge, 'scene_scaffolding/create_main_scene', args),
  );
  // 2. create_player_scene
  server.registerTool(
    'create_player_scene',
    {
      description: 'Create a player character scene with physics body, collision, and controller script',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        type: Dimension,
        controller: z.enum(['platformer', 'top_down', 'fps', 'custom']).optional().describe('Movement controller style'),
      },
    },
    async (args) => callGodot(bridge, 'scene_scaffolding/create_player_scene', args),
  );
  // 3. create_enemy_scene
  server.registerTool(
    'create_enemy_scene',
    {
      description: 'Create an enemy scene with physics body, collision, and basic AI behavior',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        type: Dimension,
        ai_type: z.enum(['patrol', 'chase', 'stationary']).optional().describe('Enemy AI behavior type'),
      },
    },
    async (args) => callGodot(bridge, 'scene_scaffolding/create_enemy_scene', args),
  );
  // 4. create_level_scene
  server.registerTool(
    'create_level_scene',
    {
      description: 'Create a level/zone scene with optional template layout',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        type: Dimension,
        template: z.enum(['empty', 'platformer', 'dungeon', 'open_world']).optional().describe('Level layout template'),
      },
    },
    async (args) => callGodot(bridge, 'scene_scaffolding/create_level_scene', args),
  );
  // 5. create_ui_scene
  server.registerTool(
    'create_ui_scene',
    {
      description: 'Create a UI scene from a predefined template (main menu, HUD, pause, inventory, dialog)',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        template: z.enum(['main_menu', 'hud', 'pause_menu', 'inventory', 'dialog']).optional().describe('UI template type'),
      },
    },
    async (args) => callGodot(bridge, 'scene_scaffolding/create_ui_scene', args),
  );
  // 6. create_camera_scene
  server.registerTool(
    'create_camera_scene',
    {
      description: 'Create a reusable camera scene with configurable follow and zoom behavior',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        type: Dimension.describe('Camera dimension type'),
        follow: z.boolean().optional().describe('Enable smooth follow on a target'),
        zoom: z.boolean().optional().describe('Enable zoom controls'),
      },
    },
    async (args) => callGodot(bridge, 'scene_scaffolding/create_camera_scene', args),
  );
  // 7. create_hud_scene
  server.registerTool(
    'create_hud_scene',
    {
      description: 'Create a HUD scene with specified UI elements (health bar, score, timer, minimap, inventory)',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        elements: z.array(z.enum(['health', 'score', 'timer', 'minimap', 'inventory'])).describe('HUD elements to include'),
      },
    },
    async (args) => callGodot(bridge, 'scene_scaffolding/create_hud_scene', args),
  );
  // 8. create_dialog_scene
  server.registerTool(
    'create_dialog_scene',
    {
      description: 'Create a dialog/conversation scene with text display and choice buttons',
      inputSchema: {
        project_path: FilePath.describe('Path to the Godot project root'),
        style: z.enum(['visual_novel', 'rpg', 'modern']).optional().describe('Dialog visual style'),
      },
    },
    async (args) => callGodot(bridge, 'scene_scaffolding/create_dialog_scene', args),
  );
}
//# sourceMappingURL=scene_scaffolding.js.map
