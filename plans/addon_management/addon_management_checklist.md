# addon_management — Test Execution Checklist
> See plan: [addon_management_test_plan.md](./addon_management_test_plan.md)

## Prerequisites verified
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: list_addons
- [ ] 1. List addons on fresh project with MCP plugin
- [ ] 2. Call with extraneous parameters, expect ignored
- [ ] 3. Call with undefined/null args, expect success

## Tool: install_addon
- [ ] 1. Install from Asset Library with default source
- [ ] 2. Install from Asset Library with explicit source
- [ ] 3. Install addon from Git repository
- [ ] 4. Install addon from local filesystem path
- [ ] 5. Call without name parameter, expect Zod error
- [ ] 6. Call source=git without name, expect Zod error
- [ ] 7. Call source=git without url, expect Godot error
- [ ] 8. Call source=local without url, expect Godot error
- [ ] 9. Call with invalid source enum, expect Zod error
- [ ] 10. Call with numeric source, expect Zod error
- [ ] 11. Call with numeric url, expect Zod error
- [ ] 12. Call with empty name string, expect Godot reject
- [ ] 13. Call with 1000-char name, test robustness
- [ ] 14. Call with malformed URL, test input sanitization
- [ ] 15. Call with extra unknown parameters, expect ignored

## Tool: uninstall_addon
- [ ] 1. Uninstall previously installed addon
- [ ] 2. Attempt uninstall of non-existent addon
- [ ] 3. Call without name, expect Zod error
- [ ] 4. Call with path traversal name, test security
- [ ] 5. Call with numeric name, expect Zod error
- [ ] 6. Attempt uninstalling godot_mcp bridge plugin

## Tool: update_addon
- [ ] 1. Update installed addon to latest version
- [ ] 2. Attempt update of non-existent addon
- [ ] 3. Update already-current addon, expect idempotent
- [ ] 4. Call without name, expect Zod error
- [ ] 5. Call with empty name string

## Tool: configure_addon
- [ ] 1. Configure single setting on installed addon
- [ ] 2. Configure multiple settings at once
- [ ] 3. Attempt configure of non-existent addon
- [ ] 4. Call without name, expect Zod error
- [ ] 5. Call without settings, expect Zod error
- [ ] 6. Call with empty settings object
- [ ] 7. Call with string settings, expect Zod error
- [ ] 8. Call with null settings, expect Zod error
- [ ] 9. Configure with deeply nested setting values
- [ ] 10. Configure with array-type setting values
- [ ] 11. Call with boolean name, expect Zod error
- [ ] 12. Call with empty object, expect Zod error
- [ ] 13. Configure with numeric key in settings

## Cross-Tool Integration
- [ ] I. Full lifecycle: install → configure → update → uninstall
- [ ] II. Install from each source type (asset_lib, git, local)
- [ ] III. Idempotent configure → configure again (overwrite)

