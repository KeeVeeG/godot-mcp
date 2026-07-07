/**
 * Animation tools — 10 tools for animation management
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';
import { callGodot } from '../server.js';
import { z, NodePath, PositiveNumber, PropertyValue } from './shared-types.js';

export function registerAnimationTools(server: McpServer, bridge: GodotBridge): void {
  // 1. list_animations — {player_path: string} -> animation names
  server.registerTool(
    'list_animations',
    {
      description: 'List all animations on an AnimationPlayer',
      inputSchema: {
        player_path: NodePath.describe('AnimationPlayer node path'),
      },
    },
    async (args) => callGodot(bridge, 'animation/list', args as Record<string, unknown>),
  );

  // 2. create_animation — {player_path: string, name: string, length?: number} -> success
  server.registerTool(
    'create_animation',
    {
      description: 'Create a new animation on an AnimationPlayer',
      inputSchema: {
        player_path: NodePath.describe('AnimationPlayer node path'),
        animation: z.string().describe('Animation name'),
        length: PositiveNumber.optional().default(1.0).describe('Animation length in seconds (default: 1.0)'),
        library: z.string().optional().describe('Animation library name (empty for default)'),
        loop_mode: z.enum(['none', 'loop', 'pingpong']).optional().default('none').describe('Animation loop mode'),
      },
    },
    async (args) => callGodot(bridge, 'animation/create', args as Record<string, unknown>),
  );

  // 3. add_animation_track — {player_path: string, animation: string, track_type: "value"|"position"|"rotation"|"scale"|"method"|"bezier", property?: string} -> track index
  server.registerTool(
    'add_animation_track',
    {
      description: 'Add a track to an animation',
      inputSchema: {
        player_path: NodePath.describe('AnimationPlayer node path'),
        animation: z.string().describe('Animation name'),
        track_type: z.enum(['value', 'position', 'rotation', 'scale', 'method', 'bezier']).describe('Type of track to add'),
        property: z.string().optional().describe("Property path for value/bezier tracks (e.g. 'position:x')"),
        library: z.string().optional().describe('Animation library name (empty for default)'),
      },
    },
    async (args) => callGodot(bridge, 'animation/add_track', args as Record<string, unknown>),
  );

  // 4. set_animation_keyframe — {player_path: string, animation: string, track_index: number, time: number, value: any, easing?: number} -> success
  server.registerTool(
    'set_animation_keyframe',
    {
      description: 'Set a keyframe in an animation track',
      inputSchema: {
        player_path: NodePath.describe('AnimationPlayer node path'),
        animation: z.string().describe('Animation name'),
        track_index: z.number().int().min(0).describe('Track index'),
        time: z.number().min(0).describe('Keyframe time in seconds'),
        value: PropertyValue.describe('Keyframe value'),
        library: z.string().optional().describe('Animation library name (empty for default)'),
      },
    },
    async (args) => callGodot(bridge, 'animation/set_keyframe', args as Record<string, unknown>),
  );

  // 5. get_animation_info — {player_path: string, animation: string} -> detailed info
  server.registerTool(
    'get_animation_info',
    {
      description: 'Get detailed information about an animation including tracks and keyframes',
      inputSchema: {
        player_path: NodePath.describe('AnimationPlayer node path'),
        animation: z.string().describe('Animation name'),
        library: z.string().optional().describe('Animation library name (empty for default)'),
      },
    },
    async (args) => callGodot(bridge, 'animation/get_info', args as Record<string, unknown>),
  );

  // 6. remove_animation — {player_path: string, animation: string} -> success
  server.registerTool(
    'remove_animation',
    {
      description: 'Remove an animation from an AnimationPlayer',
      inputSchema: {
        player_path: NodePath.describe('AnimationPlayer node path'),
        animation: z.string().describe('Animation name to remove'),
        library: z.string().optional().describe('Animation library name (empty for default)'),
      },
    },
    async (args) => callGodot(bridge, 'animation/remove', args as Record<string, unknown>),
  );

  // 7. create_animation_tree — {path: string, properties?: Record<string,any>} -> success
  server.registerTool(
    'create_animation_tree',
    {
      description: 'Create an AnimationTree node on a given path',
      inputSchema: {
        path: NodePath.describe('Node path where the AnimationTree will be added'),
        player_path: z.string().optional().describe('AnimationPlayer path'),
        root_type: z.string().optional().describe('Animation root node type (default: AnimationNodeBlendTree)'),
        properties: z.record(z.string(), z.unknown()).optional().describe('Optional properties to set on the AnimationTree'),
      },
    },
    async (args) => callGodot(bridge, 'animation/create_tree', args as Record<string, unknown>),
  );

  // 8. get_animation_tree_structure — {path: string} -> tree structure
  server.registerTool(
    'get_animation_tree_structure',
    {
      description: 'Get the structure of an AnimationTree including state machines and blend trees',
      inputSchema: {
        path: NodePath.describe('AnimationTree node path'),
      },
    },
    async (args) => callGodot(bridge, 'animation/get_tree_structure', args as Record<string, unknown>),
  );

  // 9. set_tree_parameter — {path: string, parameter: string, value: any} -> success
  server.registerTool(
    'set_tree_parameter',
    {
      description: 'Set a parameter on an AnimationTree (e.g. blend amount, state)',
      inputSchema: {
        path: NodePath.describe('AnimationTree node path'),
        parameter: z.string().describe("Parameter path (e.g. 'parameters/blend_position')"),
        value: PropertyValue.describe('Parameter value'),
      },
    },
    async (args) => callGodot(bridge, 'animation/set_tree_parameter', args as Record<string, unknown>),
  );

  // 10. add_state_machine_state — {path: string, state_name: string, animation?: string} -> success
  server.registerTool(
    'add_state_machine_state',
    {
      description: 'Add a state to an AnimationNodeStateMachine',
      inputSchema: {
        path: NodePath.describe('AnimationTree node path'),
        state_name: z.string().describe('Name for the new state'),
        animation: z.string().optional().describe('Animation name to assign to this state'),
      },
    },
    async (args) => callGodot(bridge, 'animation/add_state', args as Record<string, unknown>),
  );
}
