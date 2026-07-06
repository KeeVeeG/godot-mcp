/**
 * CI/CD Pipeline tools - 8 tools for automated build and deployment workflows
 */
import { callGodot } from '../server.js';
import { z, Name, FilePath } from './shared-types.js';
export function registerCicdPipelineTools(server, bridge) {
  // 1. create_github_actions_workflow
  server.registerTool(
    'create_github_actions_workflow',
    {
      description: 'Create a GitHub Actions workflow YAML file for automated CI/CD',
      inputSchema: {
        name: Name.describe('Workflow name (used as filename)'),
        triggers: z.array(z.string()).describe("Event triggers (e.g. 'push', 'pull_request', 'workflow_dispatch')"),
        jobs: z
          .array(
            z.object({
              name: z.string().describe('Job name'),
              steps: z
                .array(
                  z.object({
                    name: z.string().describe('Step name'),
                    run: z.string().optional().describe('Shell command to run'),
                    uses: z.string().optional().describe("Action to use (e.g. 'actions/checkout@v4')"),
                  }),
                )
                .describe('Job steps'),
            }),
          )
          .describe('Workflow jobs'),
      },
    },
    async (args) => callGodot(bridge, 'cicd/create_github_actions_workflow', args),
  );
  // 2. create_gitlab_ci
  server.registerTool(
    'create_gitlab_ci',
    {
      description: 'Create a GitLab CI/CD configuration file (.gitlab-ci.yml)',
      inputSchema: {
        stages: z.array(z.string()).describe("Pipeline stages (e.g. 'build', 'test', 'deploy')"),
        jobs: z
          .record(
            z.object({
              stage: z.string().describe('Which stage this job belongs to'),
              script: z.array(z.string()).describe('Commands to run in this job'),
            }),
          )
          .describe('Job definitions keyed by job name'),
      },
    },
    async (args) => callGodot(bridge, 'cicd/create_gitlab_ci', args),
  );
  // 3. setup_automated_testing
  server.registerTool(
    'setup_automated_testing',
    {
      description: 'Set up automated testing workflow for the Godot project',
      inputSchema: {
        framework: z.enum(['gut', 'custom']).describe('Test framework to use (GUT or custom)'),
        test_path: FilePath.describe("Path to test directory (e.g. 'res://tests/')"),
        on_push: z.boolean().optional().describe('Run tests on every push (default: true)'),
      },
    },
    async (args) => callGodot(bridge, 'cicd/setup_automated_testing', args),
  );
  // 4. setup_automated_export
  server.registerTool(
    'setup_automated_export',
    {
      description: 'Set up automated export workflow for building game binaries',
      inputSchema: {
        platforms: z.array(z.string()).describe("Target platforms (e.g. 'windows', 'linux', 'web', 'android')"),
        on_tag: z.boolean().optional().describe('Only export on tag push (default: false)'),
      },
    },
    async (args) => callGodot(bridge, 'cicd/setup_automated_export', args),
  );
  // 5. create_release_workflow
  server.registerTool(
    'create_release_workflow',
    {
      description: 'Create a release workflow with version tagging and multi-platform builds',
      inputSchema: {
        version_pattern: z.string().describe("Version tag pattern (e.g. 'v*', 'release-*')"),
        platforms: z.array(z.string()).describe('Target platforms for release builds'),
        auto_notes: z.boolean().optional().describe('Auto-generate release notes from commits (default: true)'),
      },
    },
    async (args) => callGodot(bridge, 'cicd/create_release_workflow', args),
  );
  // 6. validate_ci_config
  server.registerTool(
    'validate_ci_config',
    {
      description: 'Validate a CI/CD configuration file for syntax and structure errors',
      inputSchema: {
        config_path: FilePath.describe("Path to CI config file (e.g. '.github/workflows/build.yml', '.gitlab-ci.yml')"),
      },
    },
    async (args) => callGodot(bridge, 'cicd/validate_ci_config', args),
  );
  // 7. get_ci_templates
  server.registerTool(
    'get_ci_templates',
    {
      description: 'Get available CI/CD templates for Godot projects',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'cicd/get_ci_templates'),
  );
  // 8. create_docker_config
  server.registerTool(
    'create_docker_config',
    {
      description: 'Create a Dockerfile for containerized Godot builds and exports',
      inputSchema: {
        base_image: z.string().optional().describe('Base Docker image (default: Ubuntu)'),
        godot_version: z.string().optional().describe("Godot version to install (e.g. '4.3')"),
      },
    },
    async (args) => callGodot(bridge, 'cicd/create_docker_config', args),
  );
}
//# sourceMappingURL=cicd_pipeline.js.map
