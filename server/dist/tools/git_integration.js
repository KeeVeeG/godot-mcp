/**
 * Git integration tools - 6 tools for version control
 */
import { callGodot } from '../server.js';
import { z, Name } from './shared-types.js';
export function registerGitIntegrationTools(server, bridge) {
  // 1. git_status
  server.registerTool(
    'git_status',
    {
      description: 'Get the current git status with changed, staged, and untracked files',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'git_status'),
  );
  // 2. git_diff
  server.registerTool(
    'git_diff',
    {
      description: 'Get the diff for a specific file or all changes',
      inputSchema: {
        file_path: z.string().optional().describe('Specific file to diff, or omit for all changes'),
      },
    },
    async (args) => callGodot(bridge, 'git_diff', args),
  );
  // 3. git_commit
  server.registerTool(
    'git_commit',
    {
      description: 'Commit staged changes with a message, optionally staging specific files first',
      inputSchema: {
        message: z.string().describe('Commit message'),
        files: z.array(z.string()).optional().describe('Files to stage before committing'),
      },
    },
    async (args) => callGodot(bridge, 'git_commit', args),
  );
  // 4. git_log
  server.registerTool(
    'git_log',
    {
      description: 'Get the git commit history',
      inputSchema: {
        limit: z.number().int().min(1).max(100).optional().describe('Number of commits to show (default: 20)'),
      },
    },
    async (args) => callGodot(bridge, 'git_log', args),
  );
  // 5. git_branch
  server.registerTool(
    'git_branch',
    {
      description: 'Manage git branches - list, create, switch, or delete',
      inputSchema: {
        action: z.enum(['list', 'create', 'switch', 'delete']).describe('Branch action to perform'),
        name: Name.optional().describe('Branch name (required for create, switch, delete)'),
      },
    },
    async (args) => callGodot(bridge, 'git_branch', args),
  );
  // 6. git_stash
  server.registerTool(
    'git_stash',
    {
      description: 'Manage git stash - save, pop, or list stashes',
      inputSchema: {
        action: z.enum(['save', 'pop', 'list']).describe('Stash action to perform'),
        message: z.string().optional().describe('Stash message (for save action)'),
      },
    },
    async (args) => callGodot(bridge, 'git_stash', args),
  );
}
//# sourceMappingURL=git_integration.js.map
