/**
 * Marketing tools - 6 tools for store assets and promotional material generation
 */
import { callGodot } from '../server.js';
import { z, PositiveNumber, Size2D, FilePath } from './shared-types.js';
export function registerMarketingTools(server, bridge) {
  // 1. take_store_screenshot
  server.registerTool(
    'take_store_screenshot',
    {
      description: 'Capture high-resolution screenshots for store listings from specified scenes',
      inputSchema: {
        resolution: Size2D.optional().describe('Screenshot resolution [width, height] (default: [1920, 1080])'),
        scenes: z.array(z.string()).optional().describe('Scene paths to capture (defaults to current scene)'),
      },
    },
    async (args) => callGodot(bridge, 'marketing/take_screenshot', args),
  );
  // 2. create_screenshot_grid
  server.registerTool(
    'create_screenshot_grid',
    {
      description: 'Combine multiple screenshots into a grid, carousel, or hero layout image',
      inputSchema: {
        screenshots: z.array(z.string()).describe('Paths to screenshot images'),
        layout: z.enum(['grid', 'carousel', 'hero']).optional().describe('Layout style (default: grid)'),
      },
    },
    async (args) => callGodot(bridge, 'marketing/create_grid', args),
  );
  // 3. generate_trailer_script
  server.registerTool(
    'generate_trailer_script',
    {
      description: 'Generate a trailer script with timed scene sequences and camera actions',
      inputSchema: {
        duration: PositiveNumber.describe('Total trailer duration in seconds'),
        scenes: z
          .array(
            z.object({
              scene: z.string().describe('Scene path'),
              duration: PositiveNumber.describe('Duration for this scene in seconds'),
              action: z.string().optional().describe("Camera action (e.g. 'pan_left', 'zoom_in', 'orbit')"),
            }),
          )
          .describe('Ordered list of scene segments'),
      },
    },
    async (args) => callGodot(bridge, 'marketing/generate_trailer', args),
  );
  // 4. create_app_icon
  server.registerTool(
    'create_app_icon',
    {
      description: 'Generate an app icon at the specified size and style from the current scene',
      inputSchema: {
        size: z.number().int().positive().describe('Icon size in pixels (e.g. 512, 1024)'),
        style: z.enum(['flat', '3d', 'pixel']).optional().describe('Icon style (default: flat)'),
      },
    },
    async (args) => callGodot(bridge, 'marketing/create_icon', args),
  );
  // 5. generate_store_description
  server.registerTool(
    'generate_store_description',
    {
      description: 'Generate a platform-optimized store description with features and metadata',
      inputSchema: {
        platform: z.enum(['steam', 'app_store', 'play_store', 'itch']).describe('Target store platform'),
        features: z.array(z.string()).optional().describe('Key features to highlight'),
      },
    },
    async (args) => callGodot(bridge, 'marketing/generate_description', args),
  );
  // 6. create_press_kit
  server.registerTool(
    'create_press_kit',
    {
      description: 'Generate a complete press kit with screenshots, description, logos, and fact sheet',
      inputSchema: {
        output_path: FilePath.describe('Directory path to save the press kit files'),
      },
    },
    async (args) => callGodot(bridge, 'marketing/create_press_kit', args),
  );
}
//# sourceMappingURL=marketing.js.map
