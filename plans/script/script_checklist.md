# script — Test Execution Checklist
> See plan: [script_test_plan.md](./script_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: list_scripts
- [ ] 1. List scripts with default depth
- [ ] 2. Custom depth — shallow scan (max_depth=1)
- [ ] 3. Custom depth — deep scan (max_depth=50)
- [ ] 4. Custom depth — minimum valid (max_depth=1)
- [ ] 5. Boundary — depth of 0 (schema error)
- [ ] 6. Boundary — negative depth (schema error)
- [ ] 7. Boundary — non-integer depth (schema error)
- [ ] 8. Invalid type — string depth (schema error)
- [ ] 9. Empty project (no scripts) — returns []
- [ ] 10. Many scripts (~100+) — no error/truncation

## Tool: read_script
- [ ] 1. Read an existing script
- [ ] 2. Read script at project root
- [ ] 3. Read deeply nested script
- [ ] 4. Non-existent script path (error)
- [ ] 5. Path to a non-script file (edge case)
- [ ] 6. Path with wrong extension (error)
- [ ] 7. Missing required `path` (schema error)
- [ ] 8. Invalid path type — number (schema error)
- [ ] 9. Invalid path type — null (schema error)
- [ ] 10. Path with backslashes (invalid path)
- [ ] 11. Path without `res://` prefix (invalid)

## Tool: create_script
- [ ] 1. Create a simple script (min params)
- [ ] 2. Create with base_class
- [ ] 3. Create with base_class = 'Node'
- [ ] 4. Create with base_class = 'Node2D'
- [ ] 5. Create with base_class = 'Control'
- [ ] 6. Create in nested subdirectory
- [ ] 7. Overwrite existing script
- [ ] 8. Missing required `path` (schema error)
- [ ] 9. Missing required `content` (schema error)
- [ ] 10. Missing both required params (schema error)
- [ ] 11. Empty content string (edge case)
- [ ] 12. Content with GDScript syntax error
- [ ] 13. Invalid path type — number (schema error)
- [ ] 14. Invalid content type — boolean (schema error)
- [ ] 15. base_class with invalid type (schema error)
- [ ] 16. Very long content (~50KB payload)
- [ ] 17. Path without `.gd` extension
- [ ] 18. Path to read-only location

## Tool: delete_script
- [ ] 1. Delete an existing script
- [ ] 2. Delete deeply nested script
- [ ] 3. Delete root-level script
- [ ] 4. Non-existent script path (error)
- [ ] 5. Already-deleted script — double delete (error)
- [ ] 6. Path to non-script file (edge case)
- [ ] 7. Delete script referenced by other nodes
- [ ] 8. Missing required `path` (schema error)
- [ ] 9. Invalid path type — array (schema error)
- [ ] 10. Path traversal attempt (security)
- [ ] 11. Delete script attached to open scene node

## Tool: edit_script
- [ ] 1. Simple text replacement
- [ ] 2. Replace single line with multiple lines
- [ ] 3. Replace multiple lines with single line
- [ ] 4. Replace with empty string (delete text)
- [ ] 5. Replace empty string with text (edge case)
- [ ] 6. old_text not found in file (error)
- [ ] 7. Multiple matches of old_text (ambiguity)
- [ ] 8. Non-existent script path (error)
- [ ] 9. Missing required `path` (schema error)
- [ ] 10. Missing required `old_text` (schema error)
- [ ] 11. Missing required `new_text` (schema error)
- [ ] 12. Invalid path type (schema error)
- [ ] 13. Invalid old_text type — null (schema error)
- [ ] 14. Invalid new_text type — number (schema error)
- [ ] 15. Very large old_text — not found
- [ ] 16. Very large new_text (~50KB payload)

## Tool: attach_script
- [ ] 1. Attach to named child node
- [ ] 2. Attach to scene root (empty string)
- [ ] 3. Attach to nested node path
- [ ] 4. Attach to node that already has a script
- [ ] 5. Non-existent script path (error)
- [ ] 6. Non-existent node path (error)
- [ ] 7. Script with wrong base class for node
- [ ] 8. Missing required `script_path` (schema error)
- [ ] 9. Missing required `node_path` (schema error)
- [ ] 10. Missing both required params (schema error)
- [ ] 11. Invalid script_path type (schema error)
- [ ] 12. Invalid node_path type — null (schema error)
- [ ] 13. No scene open (precondition violation)
- [ ] 14. Attach same script to multiple nodes

## Tool: get_open_scripts
- [ ] 1. Get open scripts with some scripts open
- [ ] 2. No scripts open — returns []
- [ ] 3. Many scripts open (~20+) — full list
- [ ] 4. Extra/unknown parameters passed

## Tool: validate_script
- [ ] 1. Validate a valid script — no errors
- [ ] 2. Validate script with syntax error
- [ ] 3. Validate script with missing `extends`
- [ ] 4. Validate script with unused variable warning
- [ ] 5. Non-existent script path (error)
- [ ] 6. Validate non-GDScript file (error)
- [ ] 7. Validate trivially empty script
- [ ] 8. Missing required `path` (schema error)
- [ ] 9. Invalid path type — boolean (schema error)
- [ ] 10. Very large script (~10K lines)

## Tool: search_in_files
- [ ] 1. Simple text search across all files
- [ ] 2. Search with file_pattern filter (*.gd)
- [ ] 3. Search with .tscn file pattern
- [ ] 4. Search with no file_pattern (all files)
- [ ] 5. Search for exact class name
- [ ] 6. Search with no matches — empty result
- [ ] 7. Search with empty query (edge case)
- [ ] 8. Missing required `query` (schema error)
- [ ] 9. Missing `query` — no params at all
- [ ] 10. Invalid query type — number (schema error)
- [ ] 11. Invalid file_pattern type (schema error)
- [ ] 12. Very long query string (~5KB)
- [ ] 13. Special regex characters in query
- [ ] 14. Complex file_pattern (brace expansion)
- [ ] 15. Search in project with many files

