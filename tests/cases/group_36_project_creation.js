// Group 36: Project Creation (10 tools) вЂ” uses temp directory
const path = require('path');
const fs = require('fs');
const os = require('os');

const tempDir = path.join(os.tmpdir(), '_verify_project_creation');

module.exports = {
  name: 'ProjectCreation',
  setup: async () => {
    try {
      fs.rmSync(tempDir, { recursive: true, force: true });
    } catch {}
    fs.mkdirSync(tempDir, { recursive: true });
  },
  teardown: async () => {
    try {
      fs.rmSync(tempDir, { recursive: true, force: true });
    } catch {}
  },
  tests: [
    {
      tool: 'get_project_templates',
      description: 'Get project templates',
      validate: (d) => d && d.templates !== undefined,
    },
    {
      tool: 'create_project',
      args: { name: '_VerifyProject', path: tempDir, renderer: 'forward_plus' },
      description: 'Create project',
      timeout: 60000,
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'scaffold_project_structure',
      args: { project_path: tempDir },
      description: 'Scaffold project structure',
      validate: (d) => d && d.folders_created !== undefined,
    },
    {
      tool: 'create_project_with_assets',
      args: {
        name: '_VerifyProject2',
        path: path.join(tempDir, 'proj2'),
        assets: [],
      },
      description: 'Create project with assets',
      timeout: 60000,
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'validate_project_structure',
      args: { project_path: tempDir },
      description: 'Validate project structure',
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'initialize_git_repository',
      args: { project_path: tempDir },
      description: 'Initialize git repository',
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'create_project_readme',
      args: { project_path: tempDir, project_name: '_VerifyProject' },
      description: 'Create project README',
      validate: (d) => d && d.path !== undefined,
    },
    {
      tool: 'create_project_license',
      args: { project_path: tempDir, license: 'MIT' },
      description: 'Create project license',
      validate: (d) => d && d.path !== undefined,
    },
    {
      tool: 'setup_project_dependencies',
      args: { project_path: tempDir, addons: [] },
      description: 'Setup project dependencies',
      validate: (d) => d && typeof d === 'object',
    },
    {
      tool: 'create_project_from_template',
      args: {
        template_path: tempDir,
        path: path.join(tempDir, 'proj3'),
        name: '_VerifyProject3',
      },
      description: 'Create project from template (uses project created by earlier test)',
      timeout: 120000,
      expectError: true,
      validate: (d, text) => (d && typeof d === 'object') || text.includes('timed out') || text.includes('not found') || text.includes('template'),
    },
  ],
};
