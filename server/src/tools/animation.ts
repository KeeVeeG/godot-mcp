/**
 * Animation tools — 16 tools for animation management
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

  // 3. add_animation_track — {player_path, animation, track_type, property} -> track index
  server.registerTool(
    'add_animation_track',
    {
      description: 'Add a track to an animation. property is REQUIRED for all track types — specifies NodePath to target node (+ sub-property for value/bezier/blend_shape).',
      inputSchema: {
        player_path: NodePath.describe('AnimationPlayer node path'),
        animation: z.string().describe('Animation name'),
        track_type: z.enum([
          'value', 'position', 'position_3d', 'rotation', 'rotation_3d', 'scale', 'scale_3d',
          'blend_shape', 'method', 'bezier', 'audio', 'animation',
        ]).describe('Type of track to add (position/rotation/scale are aliases for position_3d/rotation_3d/scale_3d)'),
        property: z.string().describe(
          "NodePath to target node. REQUIRED for all track types. " +
          "Format: 'NodePath:sub_property' for value/bezier/blend_shape, " +
          "or 'NodePath' for position/rotation/scale/method/audio/animation."
        ),
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
        value: PropertyValue.describe('AnimationTree parameters require typed values (float, int, bool, string, Vector2, etc.). Null rejected by GDScript — use reset_tree_parameter to reset to default.'),
      },
    },
    async (args) => callGodot(bridge, 'animation/set_tree_parameter', args as Record<string, unknown>),
  );

  // 10. reset_tree_parameter — {path, parameter} -> success
  server.registerTool(
    'reset_tree_parameter',
    {
      description: 'Reset an AnimationTree parameter to its type-based default (0.0, false, 0, "", Vector2.ZERO). NOTE: Godot does not expose per-parameter defaults to GDScript — this uses pragmatic type inference.',
      inputSchema: {
        path: NodePath.describe('AnimationTree node path'),
        parameter: z.string().describe("Parameter path (e.g. 'parameters/blend_position')"),
      },
    },
    async (args) => callGodot(bridge, 'animation/reset_tree_parameter', args as Record<string, unknown>),
  );

  // 11. add_state_machine_state — {path: string, state_name: string, animation?: string} -> success
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

  // 12. remove_state_machine_state — {path, state_name} -> success
  server.registerTool(
    'remove_state_machine_state',
    {
      description: 'Remove a state (and all its transitions) from an AnimationNodeStateMachine',
      inputSchema: {
        path: NodePath.describe('AnimationTree node path'),
        state_name: z.string().describe('Name of the state to remove'),
      },
    },
    async (args) => callGodot(bridge, 'animation/remove_state', args as Record<string, unknown>),
  );

  // 13. add_state_machine_transition — {path, from, to, advance_mode?, switch_mode?, xfade_time?} -> success
  server.registerTool(
    'add_state_machine_transition',
    {
      description: 'Add a transition between two states in an AnimationNodeStateMachine',
      inputSchema: {
        path: NodePath.describe('AnimationTree node path'),
        from: z.string().describe('Source state name'),
        to: z.string().describe('Target state name'),
        advance_mode: z.enum(['disabled', 'enabled', 'auto']).optional().default('enabled')
          .describe('When transition fires: disabled=never, enabled=when condition met, auto=automatically'),
        switch_mode: z.enum(['immediate', 'sync', 'at_end']).optional().default('immediate')
          .describe('Switch mode: immediate=now, sync=synced time, at_end=wait for animation end'),
        xfade_time: z.number().min(0).optional().default(0.0)
          .describe('Cross-fade duration in seconds'),
        advance_condition: z.string().optional().default('')
          .describe('Advance condition name (for advance_mode=enabled)'),
        priority: z.number().int().min(0).optional().default(1)
          .describe('Priority (lower = higher priority)'),
        reset: z.boolean().optional().default(true)
          .describe('Reset target animation on transition'),
      },
    },
    async (args) => callGodot(bridge, 'animation/add_transition', args as Record<string, unknown>),
  );

  // 14. remove_state_machine_transition — {path, from, to} -> success
  server.registerTool(
    'remove_state_machine_transition',
    {
      description: 'Remove a transition between two states in an AnimationNodeStateMachine',
      inputSchema: {
        path: NodePath.describe('AnimationTree node path'),
        from: z.string().describe('Source state name'),
        to: z.string().describe('Target state name'),
      },
    },
    async (args) => callGodot(bridge, 'animation/remove_transition', args as Record<string, unknown>),
  );

  // 15. remove_animation_track — {player_path, animation, track_index} -> success
  server.registerTool(
    'remove_animation_track',
    {
      description: 'Remove a track from an animation',
      inputSchema: {
        player_path: NodePath.describe('AnimationPlayer node path'),
        animation: z.string().describe('Animation name'),
        track_index: z.number().int().min(0).describe('Index of the track to remove'),
        library: z.string().optional().describe('Animation library name (empty for default)'),
      },
    },
    async (args) => callGodot(bridge, 'animation/remove_track', args as Record<string, unknown>),
  );

  // 16. remove_animation_keyframe — {player_path, animation, track_index, time} -> success
  server.registerTool(
    'remove_animation_keyframe',
    {
      description: 'Remove a keyframe from an animation track at a specific time',
      inputSchema: {
        player_path: NodePath.describe('AnimationPlayer node path'),
        animation: z.string().describe('Animation name'),
        track_index: z.number().int().min(0).describe('Track index'),
        time: z.number().min(0).describe('Keyframe time in seconds'),
        library: z.string().optional().describe('Animation library name (empty for default)'),
      },
    },
    async (args) => callGodot(bridge, 'animation/remove_keyframe', args as Record<string, unknown>),
  );
}
