/**
 * Accessibility tools - 6 tools for accessibility auditing and compliance
 */
import { callGodot } from '../server.js';
import { z, ScenePath, NodePath } from './shared-types.js';
export function registerAccessibilityTools(server, bridge) {
  // 1. check_accessibility
  server.registerTool(
    'check_accessibility',
    {
      description: 'Run a comprehensive accessibility audit on a scene and return a detailed report',
      inputSchema: {
        scene_path: ScenePath.optional().describe('Scene path to audit (defaults to current scene)'),
      },
    },
    async (args) => callGodot(bridge, 'accessibility/check', args),
  );
  // 2. validate_contrast
  server.registerTool(
    'validate_contrast',
    {
      description: 'Validate color contrast ratio of a UI node against WCAG standards',
      inputSchema: {
        node_path: NodePath.describe('Path to the Control node to check'),
      },
    },
    async (args) => callGodot(bridge, 'accessibility/validate_contrast', args),
  );
  // 3. check_font_sizes
  server.registerTool(
    'check_font_sizes',
    {
      description: 'Find all UI nodes with font sizes below a minimum threshold',
      inputSchema: {
        min_size: z.number().optional().describe('Minimum acceptable font size in pixels (default: 14)'),
      },
    },
    async (args) => callGodot(bridge, 'accessibility/check_fonts', args),
  );
  // 4. validate_focus_order
  server.registerTool(
    'validate_focus_order',
    {
      description: 'Validate and return the keyboard focus navigation order for the current scene',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'accessibility/validate_focus'),
  );
  // 5. add_accessibility_labels
  server.registerTool(
    'add_accessibility_labels',
    {
      description: 'Add accessibility labels to interactive nodes in a scene',
      inputSchema: {
        scene_path: ScenePath,
        auto_generate: z.boolean().optional().describe('Auto-generate labels from node names and text (default: true)'),
      },
    },
    async (args) => callGodot(bridge, 'accessibility/add_labels', args),
  );
  // 6. get_accessibility_score
  server.registerTool(
    'get_accessibility_score',
    {
      description: 'Calculate an overall accessibility score for the project with improvement recommendations',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'accessibility/get_score'),
  );
}
//# sourceMappingURL=accessibility.js.map
