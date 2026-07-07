#!/usr/bin/env node
// Build tools catalog: tool_id → description, ts_file, gd_file, gd_function, test_file, category
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const ROOT = path.join(__dirname, '..');
const TS_DIR = path.join(ROOT, 'server', 'src', 'tools');
const GD_DIR = path.join(ROOT, 'addon', 'godot_mcp', 'commands');
const TEST_DIR = path.join(ROOT, 'tests', 'cases');

const GD_FILE_MAP = {
  project: 'project_commands.gd',
  scene: 'scene_commands.gd',
  node: 'node_commands.gd',
  script: 'script_commands.gd',
  editor: 'editor_commands.gd',
  input: 'input_commands.gd',
  runtime: 'runtime_commands.gd',
  animation: 'animation_commands.gd',
  tilemap: 'tilemap_commands.gd',
  theme: 'theme_commands.gd',
  shader: 'shader_commands.gd',
  resource: 'resource_commands.gd',
  physics: 'physics_commands.gd',
  scene3d: 'scene3d_commands.gd',
  particles: 'particles_commands.gd',
  navigation: 'navigation_commands.gd',
  audio: 'audio_commands.gd',
  batch: 'batch_commands.gd',
  analysis: 'analysis_commands.gd',
  testing: 'testing_commands.gd',
  profiling: 'profiling_commands.gd',
  export: 'export_commands.gd',
  addon_management: 'addon_management_commands.gd',
  audio_config: 'audio_config_commands.gd',
  build_config: 'build_config_commands.gd',
  debug_config: 'debug_config_commands.gd',
  debugging: 'debugging_commands.gd',
  editor_config: 'editor_config_commands.gd',
  gameplay_automation: 'gameplay_automation_commands.gd',
  memory_profiling: 'memory_profiling_commands.gd',
  node_config: 'node_config_commands.gd',
  physics_config: 'physics_config_commands.gd',
  platform_export: 'platform_export_commands.gd',
  platform_specific: 'platform_specific_commands.gd',
  project_config: 'project_config_commands.gd',
  project_creation: 'project_creation_commands.gd',
  rendering_config: 'rendering_config_commands.gd',
  resource_config: 'resource_config_commands.gd',
  save_load: 'save_load_commands.gd',
  scene_config: 'scene_config_commands.gd',
  visual_testing: 'visual_testing_commands.gd',
};

// Parse TS file: extract (tool_id, description, godot_command)
function parseTs(tsPath) {
  const content = fs.readFileSync(tsPath, 'utf-8');
  const tools = [];
  // Match each registerTool block
  const blockRe = /server\.registerTool\(\s*'([^']+)',\s*\{([\s\S]*?)\},\s*(?:async\s*)?\([^)]*\)\s*=>\s*callGodot\([^,]+,\s*'([^']+)'/g;
  let m;
  while ((m = blockRe.exec(content)) !== null) {
    const tool_id = m[1];
    const blockBody = m[2];
    const godot_command = m[3];
    const descRe = /description:\s*(?:'([^']+)'|"([^"]+)")/;
    const descMatch = descRe.exec(blockBody);
    tools.push({
      tool_id,
      description: (descMatch ? descMatch[1] || descMatch[2] : '').replace(/^🔴 Game must be running\.\s*/, ''),
      godot_command,
    });
  }
  return tools;
}

// Parse GD file: extract godot_command → gd_function mapping from get_commands()
function parseGdCommands(gdPath) {
  const content = fs.readFileSync(gdPath, 'utf-8');
  const map = {};

  // Pattern 1: direct "key": func_name,
  const directRe = /"([^"]+)":\s*(\w+)\s*,?\n/g;
  let m;
  while ((m = directRe.exec(content)) !== null) {
    if (m[2] !== 'func') map[m[1]] = m[2];
  }

  // Pattern 2: lambda dispatch "key": func(params) -> Dictionary: return execute("method", params),
  const lambdaRe = /"([^"]+)":\s*func\([^)]*\)[^{]*\{[^}]*execute\("([^"]+)"/g;
  while ((m = lambdaRe.exec(content)) !== null) {
    if (!map[m[1]]) map[m[1]] = '_' + m[2];
  }

  return map;
}

// Find test file containing a tool
function findTestFile(toolId) {
  const files = fs.readdirSync(TEST_DIR).filter((f) => f.endsWith('.js'));
  for (const f of files) {
    const content = fs.readFileSync(path.join(TEST_DIR, f), 'utf-8');
    if (content.includes(`tool: '${toolId}'`) || content.includes(`tool: "${toolId}"`)) {
      return `tests/cases/${f}`;
    }
  }
  return null;
}

function main() {
  const catalog = [];
  const tsFiles = fs.readdirSync(TS_DIR).filter((f) => f.endsWith('.ts') && f !== 'shared-types.ts' && f !== 'index.ts');

  for (const tsFile of tsFiles) {
    const category = tsFile.replace('.ts', '');
    const tsPath = path.join(TS_DIR, tsFile);
    const gdFile = GD_FILE_MAP[category];
    if (!gdFile) {
      console.error(`No GD mapping for ${category}`);
      continue;
    }

    const gdPath = path.join(GD_DIR, gdFile);
    if (!fs.existsSync(gdPath)) {
      console.error(`GD file not found: ${gdPath}`);
    }

    const tools = parseTs(tsPath);
    const gdMap = parseGdCommands(gdPath);

    for (const { tool_id, description, godot_command } of tools) {
      const gdFunction = gdMap[godot_command] || tool_id;
      const testFile = findTestFile(tool_id);
      catalog.push({
        tool_id,
        description,
        godot_command,
        gd_file: `addon/godot_mcp/commands/${gdFile}`,
        gd_function: gdFunction,
        ts_file: `server/src/tools/${tsFile}`,
        test_file: testFile,
        category,
      });
    }
  }

  const json = JSON.stringify(catalog, null, 2);
  const jsContent = 'const TOOLS_CATALOG = ' + json + ';';

  const webJsPath = path.join(ROOT, 'web', 'tools-catalog.js');

  fs.writeFileSync(webJsPath, jsContent);
  console.log(`Wrote ${catalog.length} tools to ${webJsPath}`);

  // Stats
  const withTests = catalog.filter((t) => t.test_file).length;
  const withoutTests = catalog.filter((t) => !t.test_file).length;
  const withDesc = catalog.filter((t) => t.description).length;
  console.log(`  With test: ${withTests}, without test: ${withoutTests}, with description: ${withDesc}`);

  // Per-category
  const byCat = {};
  catalog.forEach((t) => {
    byCat[t.category] = (byCat[t.category] || 0) + 1;
  });
  for (const [cat, count] of Object.entries(byCat)) {
    console.log(`  ${cat}: ${count}`);
  }
}

main();
