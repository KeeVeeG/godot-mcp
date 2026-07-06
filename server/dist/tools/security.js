/**
 * Security tools - 6 tools for game security management
 */
import { callGodot } from '../server.js';
import { z, ScriptPath, FilePath } from './shared-types.js';
export function registerSecurityTools(server, bridge) {
  // 1. get_security_settings
  server.registerTool(
    'get_security_settings',
    {
      description: 'Get the current security configuration for the game project',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'get_security_settings'),
  );
  // 2. enable_anti_cheat
  server.registerTool(
    'enable_anti_cheat',
    {
      description: 'Enable anti-cheat features for the game',
      inputSchema: {
        features: z.array(z.enum(['memory_check', 'speed_hack', 'packet_validation', 'integrity_check'])).describe('Anti-cheat features to enable'),
      },
    },
    async (args) => callGodot(bridge, 'enable_anti_cheat', args),
  );
  // 3. validate_file_integrity
  server.registerTool(
    'validate_file_integrity',
    {
      description: 'Validate the integrity of a file by computing its hash and optionally comparing against an expected hash',
      inputSchema: {
        file_path: FilePath.describe('Path to the file to validate (res:// or absolute)'),
        expected_hash: z.string().optional().describe('Expected SHA-256 hash to compare against'),
      },
    },
    async (args) => callGodot(bridge, 'validate_file_integrity', args),
  );
  // 4. encrypt_save_data
  server.registerTool(
    'encrypt_save_data',
    {
      description: 'Encrypt the save data in a specific slot using the provided encryption key',
      inputSchema: {
        slot: z.number().int().min(0).max(99).describe('Save slot number to encrypt (0-99)'),
        key: z.string().min(1).describe('Encryption key (will be hashed to AES-256)'),
      },
    },
    async (args) => callGodot(bridge, 'encrypt_save_data', args),
  );
  // 5. obfuscate_variable
  server.registerTool(
    'obfuscate_variable',
    {
      description: 'Obfuscate a variable name in a GDScript file to prevent reverse engineering',
      inputSchema: {
        script_path: ScriptPath,
        variable_name: z.string().describe('Name of the variable to obfuscate'),
      },
    },
    async (args) => callGodot(bridge, 'obfuscate_variable', args),
  );
  // 6. get_security_audit
  server.registerTool(
    'get_security_audit',
    {
      description: 'Run a security audit and return a report of potential vulnerabilities in the project',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'get_security_audit'),
  );
}
//# sourceMappingURL=security.js.map
