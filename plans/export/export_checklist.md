# export — Test Execution Checklist
> See plan: [export_test_plan.md](./export_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: list_export_presets
- [ ] 1. List presets on fresh project
- [ ] 2. List presets after creation
- [ ] 3. Call with extra params
- [ ] 4. Call with null/undefined args

## Tool: export_project
- [ ] 1. Export with only preset name
- [ ] 2. Export with debug=true
- [ ] 3. Export with explicit debug=false
- [ ] 4. Export with pack_only=true
- [ ] 5. Export with explicit pack_only=false
- [ ] 6. Export with custom output_path
- [ ] 7. Export with all params specified
- [ ] 8. Missing preset parameter
- [ ] 9. Missing preset with other params
- [ ] 10. Non-existent preset name
- [ ] 11. Empty string for preset
- [ ] 12. Non-string type for preset
- [ ] 13. Non-boolean type for debug
- [ ] 14. Non-boolean type for pack_only
- [ ] 15. Non-string type for output_path
- [ ] 16. Empty output_path string
- [ ] 17. Special characters in output_path
- [ ] 18. Both debug and pack_only true
- [ ] 19. Extra unknown params
- [ ] 20. Very long preset name

## Tool: get_export_info
- [ ] 1. Get export info on fresh project
- [ ] 2. Get info after preset creation
- [ ] 3. Call with extra params

## Tool: validate_export
- [ ] 1. Validate clean project
- [ ] 2. Validate after resource deletion
- [ ] 3. Validate after preset creation
- [ ] 4. Call with extra params
- [ ] 5. Call with null/undefined args

## Tool: get_export_templates
- [ ] 1. List available templates
- [ ] 2. Templates on fresh install
- [ ] 3. Call with extra params

## Tool: create_export_preset
- [ ] 1. Create Windows Desktop preset
- [ ] 2. Create Linux preset
- [ ] 3. Create macOS preset
- [ ] 4. Create Android preset
- [ ] 5. Create iOS preset
- [ ] 6. Create Web preset
- [ ] 7. Create with custom name
- [ ] 8. Missing name parameter
- [ ] 9. Missing platform parameter
- [ ] 10. Both parameters missing
- [ ] 11. Unknown platform string
- [ ] 12. Empty string for name
- [ ] 13. Empty string for platform
- [ ] 14. Duplicate preset name
- [ ] 15. Non-string type for name
- [ ] 16. Non-string type for platform
- [ ] 17. Platform with extra whitespace
- [ ] 18. Name with special characters
- [ ] 19. Very long preset name
- [ ] 20. Extra unknown params

## Tool: delete_export_preset
- [ ] 1. Delete existing preset
- [ ] 2. Delete non-existent preset
- [ ] 3. Delete last remaining preset
- [ ] 4. Delete preset by custom name
- [ ] 5. Delete same preset twice
- [ ] 6. Missing name parameter
- [ ] 7. Empty string for name
- [ ] 8. Non-string type for name
- [ ] 9. Boolean type for name
- [ ] 10. Path traversal in name
- [ ] 11. SQL-like injection in name
- [ ] 12. Extra unknown params

## Cross-Tool Integration
- [ ] I. Full lifecycle: create → list → export → delete
- [ ] II. Create presets for all common platforms
- [ ] III. Validation cycle: create → validate → export → validate
- [ ] IV. Duplicate detection: same preset twice
- [ ] V. Export without templates

