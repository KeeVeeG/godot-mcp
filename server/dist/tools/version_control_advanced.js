/**
 * Version control advanced tools - 8 tools for advanced git operations
 */
import { callGodot } from '../server.js';
import { z, Name, FilePath } from './shared-types.js';
export function registerVersionControlAdvancedTools(server, bridge) {
  // 1. create_branch
  server.registerTool(
    'create_branch',
    {
      description: 'Create a new git branch from the specified base branch',
      inputSchema: {
        name: Name.describe('New branch name'),
        from: z.string().optional().describe('Base branch or commit to create from (default: current HEAD)'),
      },
    },
    async (args) => callGodot(bridge, 'vcs_advanced/create_branch', args),
  );
  // 2. switch_branch
  server.registerTool(
    'switch_branch',
    {
      description: 'Switch to a different git branch',
      inputSchema: {
        name: Name.describe('Branch name to switch to'),
      },
    },
    async (args) => callGodot(bridge, 'vcs_advanced/switch_branch', args),
  );
  // 3. merge_branch
  server.registerTool(
    'merge_branch',
    {
      description: 'Merge a branch into the current branch using the specified strategy',
      inputSchema: {
        branch: Name.describe('Branch name to merge'),
        strategy: z.enum(['merge', 'squash', 'rebase']).optional().describe('Merge strategy (default: merge)'),
      },
    },
    async (args) => callGodot(bridge, 'vcs_advanced/merge_branch', args),
  );
  // 4. delete_branch
  server.registerTool(
    'delete_branch',
    {
      description: 'Delete a git branch (local only)',
      inputSchema: {
        name: Name.describe('Branch name to delete'),
      },
    },
    async (args) => callGodot(bridge, 'vcs_advanced/delete_branch', args),
  );
  // 5. create_tag
  server.registerTool(
    'create_tag',
    {
      description: 'Create a git tag at the current HEAD or specified commit',
      inputSchema: {
        name: Name.describe("Tag name (e.g. 'v1.0.0')"),
        message: z.string().optional().describe('Tag annotation message'),
      },
    },
    async (args) => callGodot(bridge, 'vcs_advanced/create_tag', args),
  );
  // 6. get_branch_diff
  server.registerTool(
    'get_branch_diff',
    {
      description: 'Get the diff between the current branch and another branch',
      inputSchema: {
        branch: Name.describe('Branch to compare against'),
      },
    },
    async (args) => callGodot(bridge, 'vcs_advanced/get_branch_diff', args),
  );
  // 7. resolve_conflicts
  server.registerTool(
    'resolve_conflicts',
    {
      description: 'Resolve merge conflicts using the specified strategy',
      inputSchema: {
        files: z.array(z.string()).describe('List of files with conflicts to resolve'),
        strategy: z.enum(['ours', 'theirs', 'manual']).optional().describe('Resolution strategy (default: manual)'),
      },
    },
    async (args) => callGodot(bridge, 'vcs_advanced/resolve_conflicts', args),
  );
  // 8. get_blame
  server.registerTool(
    'get_blame',
    {
      description: 'Get git blame information for a file (who changed each line and when)',
      inputSchema: {
        file_path: FilePath.describe('Path to the file to blame'),
      },
    },
    async (args) => callGodot(bridge, 'vcs_advanced/get_blame', args),
  );
}
//# sourceMappingURL=version_control_advanced.js.map
