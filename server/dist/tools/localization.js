/**
 * Localization tools - 8 tools for multi-language support
 */
import { callGodot } from '../server.js';
import { z, FilePath } from './shared-types.js';
export function registerLocalizationTools(server, bridge) {
  // 1. get_localization_settings
  server.registerTool(
    'get_localization_settings',
    {
      description: 'Get current localization settings including locale, fallback locale, and translation files',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'localization/get_settings'),
  );
  // 2. set_locale
  server.registerTool(
    'set_locale',
    {
      description: 'Set the active locale for the project',
      inputSchema: {
        locale: z.string().describe("Locale code to set (e.g. 'en', 'fr', 'ja', 'pt_BR')"),
      },
    },
    async (args) => callGodot(bridge, 'localization/set_locale', args),
  );
  // 3. get_translations
  server.registerTool(
    'get_translations',
    {
      description: 'Get translation keys and their values, optionally filtered by locale',
      inputSchema: {
        locale: z.string().optional().describe('Locale to get translations for (defaults to current locale)'),
      },
    },
    async (args) => callGodot(bridge, 'localization/get_translations', args),
  );
  // 4. add_translation
  server.registerTool(
    'add_translation',
    {
      description: 'Add or update a translation key for a specific locale',
      inputSchema: {
        key: z.string().describe("Translation key (e.g. 'UI.MAIN_MENU.START')"),
        locale: z.string().describe("Locale code (e.g. 'en', 'fr')"),
        value: z.string().describe('Translated text value'),
      },
    },
    async (args) => callGodot(bridge, 'localization/add_translation', args),
  );
  // 5. remove_translation
  server.registerTool(
    'remove_translation',
    {
      description: 'Remove a translation key, optionally from a specific locale only',
      inputSchema: {
        key: z.string().describe('Translation key to remove'),
        locale: z.string().optional().describe('Specific locale to remove from (removes from all if omitted)'),
      },
    },
    async (args) => callGodot(bridge, 'localization/remove_translation', args),
  );
  // 6. import_translations
  server.registerTool(
    'import_translations',
    {
      description: 'Import translations from an external file (CSV, JSON, PO, or XLIFF)',
      inputSchema: {
        file_path: FilePath.describe('Path to the translation file (res:// or absolute)'),
        format: z.enum(['csv', 'json', 'po', 'xliff']).describe('File format'),
      },
    },
    async (args) => callGodot(bridge, 'localization/import_translations', args),
  );
  // 7. export_translations
  server.registerTool(
    'export_translations',
    {
      description: 'Export translations for a locale to a file (CSV, JSON, or PO)',
      inputSchema: {
        locale: z.string().describe('Locale to export'),
        format: z.enum(['csv', 'json', 'po']).describe('Export format'),
      },
    },
    async (args) => callGodot(bridge, 'localization/export_translations', args),
  );
  // 8. validate_translations
  server.registerTool(
    'validate_translations',
    {
      description: 'Validate translations and report missing keys per locale',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'localization/validate_translations'),
  );
}
//# sourceMappingURL=localization.js.map
