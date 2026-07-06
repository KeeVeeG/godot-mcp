/**
 * Tool module auto-registration
 *
 * Imports all tool modules and registers them with the MCP server.
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { GodotBridge } from '../godot-bridge.js';

import { registerProjectTools } from './project.js';
import { registerSceneTools } from './scene.js';
import { registerNodeTools } from './node.js';
import { registerScriptTools } from './script.js';
import { registerEditorTools } from './editor.js';
import { registerInputTools } from './input.js';
import { registerRuntimeTools } from './runtime.js';
import { registerAnimationTools } from './animation.js';
import { registerTilemapTools } from './tilemap.js';
import { registerThemeTools } from './theme.js';
import { registerShaderTools } from './shader.js';
import { registerResourceTools } from './resource.js';
import { registerPhysicsTools } from './physics.js';
import { registerScene3dTools } from './scene3d.js';
import { registerParticlesTools } from './particles.js';
import { registerNavigationTools } from './navigation.js';
import { registerAudioTools } from './audio.js';
import { registerBatchTools } from './batch.js';
import { registerAnalysisTools } from './analysis.js';
import { registerTestingTools } from './testing.js';
import { registerProfilingTools } from './profiling.js';
import { registerExportTools } from './export.js';
import { registerAddonManagementTools } from './addon_management.js';
import { registerAudioConfigTools } from './audio_config.js';
import { registerBuildConfigTools } from './build_config.js';
import { registerDebugConfigTools } from './debug_config.js';
import { registerDebuggingTools } from './debugging.js';
import { registerEditorConfigTools } from './editor_config.js';
import { registerGameplayAutomationTools } from './gameplay_automation.js';
import { registerMemoryProfilingTools } from './memory_profiling.js';
import { registerNodeConfigTools } from './node_config.js';
import { registerPhysicsConfigTools } from './physics_config.js';
import { registerPlatformExportTools } from './platform_export.js';
import { registerPlatformSpecificTools } from './platform_specific.js';
import { registerProjectConfigTools } from './project_config.js';
import { registerProjectCreationTools } from './project_creation.js';
import { registerRenderingConfigTools } from './rendering_config.js';
import { registerResourceConfigTools } from './resource_config.js';
import { registerSaveLoadTools } from './save_load.js';
import { registerSceneConfigTools } from './scene_config.js';
import { registerVisualTestingTools } from './visual_testing.js';

/**
 * Register all tool modules with the MCP server.
 */
export function registerAllTools(server: McpServer, bridge: GodotBridge): void {
  registerProjectTools(server, bridge);
  registerSceneTools(server, bridge);
  registerNodeTools(server, bridge);
  registerScriptTools(server, bridge);
  registerEditorTools(server, bridge);
  registerInputTools(server, bridge);
  registerRuntimeTools(server, bridge);
  registerAnimationTools(server, bridge);
  registerTilemapTools(server, bridge);
  registerThemeTools(server, bridge);
  registerShaderTools(server, bridge);
  registerResourceTools(server, bridge);
  registerPhysicsTools(server, bridge);
  registerScene3dTools(server, bridge);
  registerParticlesTools(server, bridge);
  registerNavigationTools(server, bridge);
  registerAudioTools(server, bridge);
  registerBatchTools(server, bridge);
  registerAnalysisTools(server, bridge);
  registerTestingTools(server, bridge);
  registerProfilingTools(server, bridge);
  registerExportTools(server, bridge);
  registerAddonManagementTools(server, bridge);
  registerAudioConfigTools(server, bridge);
  registerBuildConfigTools(server, bridge);
  registerDebugConfigTools(server, bridge);
  registerDebuggingTools(server, bridge);
  registerEditorConfigTools(server, bridge);
  registerGameplayAutomationTools(server, bridge);
  registerMemoryProfilingTools(server, bridge);
  registerNodeConfigTools(server, bridge);
  registerPhysicsConfigTools(server, bridge);
  registerPlatformExportTools(server, bridge);
  registerPlatformSpecificTools(server, bridge);
  registerProjectConfigTools(server, bridge);
  registerProjectCreationTools(server, bridge);
  registerRenderingConfigTools(server, bridge);
  registerResourceConfigTools(server, bridge);
  registerSaveLoadTools(server, bridge);
  registerSceneConfigTools(server, bridge);
  registerVisualTestingTools(server, bridge);
}
