# project — Test Execution Checklist
> See plan: [project_test_plan.md](./project_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: get_project_info
- [ ] 1. Basic happy path — get project info
- [ ] 2. Call with unexpected extra params
- [ ] 3. Call with null/undefined args
- [ ] 4. Verify returned fields are non-empty

## Tool: get_filesystem_tree
- [ ] 1. List root with defaults
- [ ] 2. List with extension filters
- [ ] 3. List with multiple extension filters
- [ ] 4. Shallow depth (max_depth=1)
- [ ] 5. Deep recursion (max_depth=50)
- [ ] 6. List a subdirectory
- [ ] 7. Filters with max_depth combination
- [ ] 8. Missing required parameter — path
- [ ] 9. Invalid type — max_depth as string
- [ ] 10. Invalid value — max_depth ≤ 0
- [ ] 11. Invalid value — max_depth negative
- [ ] 12. Invalid value — max_depth as float
- [ ] 13. Invalid path — non-res:// prefix
- [ ] 14. Invalid path — non-existent directory
- [ ] 15. Empty filters array
- [ ] 16. Filters with invalid extension format

## Tool: search_files
- [ ] 1. Search by filename
- [ ] 2. Search by file extension
- [ ] 3. Search by full filename
- [ ] 4. Search with no matches
- [ ] 5. Search with special characters
- [ ] 6. Search with empty string
- [ ] 7. Search with whitespace-only query
- [ ] 8. Missing required parameter — query
- [ ] 9. Invalid type — query as number
- [ ] 10. Invalid type — query as object

## Tool: get_project_settings
- [ ] 1. Get all settings (no filter)
- [ ] 2. Filter by application prefix
- [ ] 3. Filter by display prefix
- [ ] 4. Filter by input prefix
- [ ] 5. Filter with no trailing slash
- [ ] 6. Filter matching exactly one setting
- [ ] 7. Filter with no matches
- [ ] 8. Call with empty object (no params)
- [ ] 9. Invalid type — filter as number
- [ ] 10. Filter with uppercase characters

## Tool: set_project_setting
- [ ] 1. Set a string setting
- [ ] 2. Set a numeric setting
- [ ] 3. Set a boolean setting
- [ ] 4. Set boolean to false
- [ ] 5. Set a string number (as string)
- [ ] 6. Missing required parameter — key
- [ ] 7. Missing required parameter — value
- [ ] 8. Missing both required parameters
- [ ] 9. Invalid key — non-existent setting path
- [ ] 10. Invalid value type — wrong type for setting
- [ ] 11. Value as null
- [ ] 12. Value as complex object
- [ ] 13. Empty key string
- [ ] 14. Key with only whitespace

## Tool: uid_to_project_path
- [ ] 1. Convert a known UID to path
- [ ] 2. Convert a non-existent UID
- [ ] 3. Missing required parameter — uid
- [ ] 4. Invalid type — uid as number
- [ ] 5. Invalid format — empty UID string
- [ ] 6. Invalid format — UID without uid:// prefix
- [ ] 7. UID with special characters
- [ ] 8. Very long UID string

## Tool: project_path_to_uid
- [ ] 1. Convert a known file path to UID
- [ ] 2. Convert a scene file path to UID
- [ ] 3. Convert a script file path to UID
- [ ] 4. Round-trip UID ↔ path conversion
- [ ] 5. Missing required parameter — path
- [ ] 6. Invalid type — path as number
- [ ] 7. Non-existent file path
- [ ] 8. Invalid path — not a res:// path
- [ ] 9. Invalid path — path to a directory
- [ ] 10. Empty string path
- [ ] 11. Path with trailing slash

