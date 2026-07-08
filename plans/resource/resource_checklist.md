# resource — Test Execution Checklist
> See plan: [resource_test_plan.md](./resource_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: read_resource
- [ ] 1. Read an existing `.tres` resource
- [ ] 2. Read an existing `.res` resource
- [ ] 3. Read a Theme resource
- [ ] 4. Missing required param — no path
- [ ] 5. File does not exist
- [ ] 6. Wrong extension (not a resource file)
- [ ] 7. Raw filesystem path instead of `res://`
- [ ] 8. Empty path string
- [ ] 9. Path with trailing slash
- [ ] 10. Path with special characters and spaces

---

## Tool: edit_resource
- [ ] 1. Edit a single string property
- [ ] 2. Edit multiple properties at once
- [ ] 3. Edit a numeric property
- [ ] 4. Edit a boolean property
- [ ] 5. Missing required param — no path
- [ ] 6. Missing required param — no properties
- [ ] 7. Empty properties object
- [ ] 8. Nonexistent resource
- [ ] 9. Set property that doesn't exist on the type
- [ ] 10. Set property to an invalid type
- [ ] 11. Properties with null values

---

## Tool: create_resource
- [ ] 1. Create a StyleBoxFlat
- [ ] 2. Create a Gradient with properties
- [ ] 3. Create a Curve resource
- [ ] 4. Create with empty properties object
- [ ] 5. Create with `.res` extension (binary)
- [ ] 6. Missing required param — no type
- [ ] 7. Missing required param — no path
- [ ] 8. Nonexistent resource class type
- [ ] 9. Use a Node type name as resource type
- [ ] 10. Directory that doesn't exist
- [ ] 11. Overwrite existing file
- [ ] 12. Empty string type
- [ ] 13. Path without extension
- [ ] 14. Wrong extension for binary resource

---

## Tool: delete_resource
- [ ] 1. Delete a `.tres` file
- [ ] 2. Delete a `.res` file
- [ ] 3. Missing required param — no path
- [ ] 4. File does not exist
- [ ] 5. Delete a resource referenced by a scene
- [ ] 6. Delete an autoload script resource
- [ ] 7. Empty path string
- [ ] 8. Delete a directory path instead of file
- [ ] 9. Undo verification

---

## Tool: get_resource_preview
- [ ] 1. Preview a Material resource
- [ ] 2. Preview a Texture resource
- [ ] 3. Preview a StyleBox resource
- [ ] 4. Preview a script resource
- [ ] 5. Missing required param — no path
- [ ] 6. Nonexistent resource
- [ ] 7. Path to a directory
- [ ] 8. Preview a scene file
- [ ] 9. Path with uppercase extension

---

## Tool: add_autoload
- [ ] 1. Add a script autoload
- [ ] 2. Add a scene autoload
- [ ] 3. Add autoload with snake_case name
- [ ] 4. Missing required param — no name
- [ ] 5. Missing required param — no path
- [ ] 6. Script does not exist
- [ ] 7. Duplicate autoload name
- [ ] 8. Name with special characters
- [ ] 9. Empty name string
- [ ] 10. Path to a non-script, non-scene file
- [ ] 11. Name starting with a digit
- [ ] 12. Path with `res://` prefix missing

---

## Tool: remove_autoload
- [ ] 1. Remove an existing autoload
- [ ] 2. Remove another autoload
- [ ] 3. Missing required param — no name
- [ ] 4. Autoload does not exist
- [ ] 5. Empty name string
- [ ] 6. Name with special characters
- [ ] 7. Remove a built-in autoload
- [ ] 8. Double remove — same autoload twice

---

## Tool: duplicate_resource
- [ ] 1. Duplicate a `.tres` file
- [ ] 2. Duplicate a `.res` binary file
- [ ] 3. Duplicate to a different directory
- [ ] 4. Duplicate with a different name
- [ ] 5. Missing required param — no source_path
- [ ] 6. Missing required param — no dest_path
- [ ] 7. Source file does not exist
- [ ] 8. Destination parent directory doesn't exist
- [ ] 9. Dest_path already exists
- [ ] 10. Source and dest are the same path
- [ ] 11. Duplicate a script file
- [ ] 12. Duplicate a scene file
- [ ] 13. Dest_path with uppercase extension

---

## Tool: list_resources
- [ ] 1. List all resources (no filters)
- [ ] 2. List with no args (undefined)
- [ ] 3. Filter by resource type
- [ ] 4. Filter by directory
- [ ] 5. Filter by both type and directory
- [ ] 6. Filter by Material type
- [ ] 7. Filter by Theme type
- [ ] 8. Nonexistent resource type
- [ ] 9. Nonexistent directory
- [ ] 10. Empty string type
- [ ] 11. Empty string directory
- [ ] 12. Type with extra whitespace
- [ ] 13. Large result set

---

## Tool: get_resource_dependencies
- [ ] 1. Get dependencies of a scene
- [ ] 2. Get dependencies of a material
- [ ] 3. Get dependencies of standalone resource (no deps)
- [ ] 4. Get dependencies of a script
- [ ] 5. Get dependencies of a theme
- [ ] 6. Missing required param — no path
- [ ] 7. File does not exist
- [ ] 8. Path to a directory
- [ ] 9. Empty path string
- [ ] 10. Deeply nested dependencies
- [ ] 11. Circular dependencies

