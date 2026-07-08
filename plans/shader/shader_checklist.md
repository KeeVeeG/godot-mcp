# shader — Test Execution Checklist
> See plan: [shader_test_plan.md](./shader_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `create_shader`
- [ ] 1. Create canvas_item with minimum params
- [ ] 2. Create with explicit canvas_item type
- [ ] 3. Create spatial shader
- [ ] 4. Create with visual type (canvas_item alias)
- [ ] 5. Create particles shader
- [ ] 6. Create sky shader
- [ ] 7. Create fog shader
- [ ] 8. Create texture_blit shader
- [ ] 9. Create with custom code content
- [ ] 10. Create spatial with content
- [ ] 11. Omit path (validation error)
- [ ] 12. Empty string path (error)
- [ ] 13. Path missing .gdshader extension
- [ ] 14. Invalid type enum (validation error)
- [ ] 15. Create in nested directory
- [ ] 16. Create with 500+ lines of content
- [ ] 17. Overwrite existing shader

## Tool: `read_shader`
- [ ] 1. Read existing shader with custom content
- [ ] 2. Read shader with default template
- [ ] 3. Read spatial shader
- [ ] 4. Omit path (validation error)
- [ ] 5. Read non-existent file (error)
- [ ] 6. Read non-shader file (.gd script)
- [ ] 7. Empty string path (error)

## Tool: `edit_shader`
- [ ] 1. Replace single occurrence in shader
- [ ] 2. Replace text appearing multiple times
- [ ] 3. Delete text via empty replacement
- [ ] 4. Replace with multi-line code block
- [ ] 5. old_text not found (error)
- [ ] 6. Omit old_text (validation error)
- [ ] 7. Omit new_text (validation error)
- [ ] 8. Omit path (validation error)
- [ ] 9. Edit non-existent file (error)
- [ ] 10. Replace entire file content
- [ ] 11. Two sequential edits, cumulative result

## Tool: `assign_shader_material`
- [ ] 1. Assign spatial shader to 3D mesh
- [ ] 2. Assign canvas_item shader to Sprite2D
- [ ] 3. Assign to nested path node
- [ ] 4. Same shader to two nodes
- [ ] 5. Omit node_path (validation error)
- [ ] 6. Omit shader_path (validation error)
- [ ] 7. Non-existent node (error)
- [ ] 8. Non-existent shader file (error)
- [ ] 9. Node without material support (error)
- [ ] 10. Assign to scene root
- [ ] 11. Re-assign to override existing

## Tool: `set_shader_param`
- [ ] 1. Set float uniform
- [ ] 2. Set vec3/color uniform
- [ ] 3. Set boolean uniform
- [ ] 4. Set integer uniform
- [ ] 5. Set texture uniform via resource path
- [ ] 6. Set two uniforms sequentially
- [ ] 7. Omit param (validation error)
- [ ] 8. Omit value (validation error)
- [ ] 9. Non-existent uniform name (error)
- [ ] 10. Non-existent node (error)
- [ ] 11. Node without ShaderMaterial (error)
- [ ] 12. Set string value on uniform

## Tool: `get_shader_params`
- [ ] 1. Get params from node with ShaderMaterial
- [ ] 2. Node without ShaderMaterial (error/empty)
- [ ] 3. Freshly assigned, default values
- [ ] 4. Omit node_path (validation error)
- [ ] 5. Non-existent node (error)
- [ ] 6. Scene root with ShaderMaterial

## Tool: `list_shaders`
- [ ] 1. List all shaders, no filter
- [ ] 2. Filter by path pattern
- [ ] 3. Filter with no matches
- [ ] 4. Empty string filter
- [ ] 5. Project with zero shaders
- [ ] 6. Regex special chars in filter

## Tool: `validate_shader`
- [ ] 1. Validate correct shader (no errors)
- [ ] 2. Shader with syntax errors
- [ ] 3. Validate correct spatial shader
- [ ] 4. Type mismatch (spatial in canvas_item)
- [ ] 5. Omit path (validation error)
- [ ] 6. Non-existent file (error)
- [ ] 7. Non-shader file (.gd script)
- [ ] 8. Empty shader file
- [ ] 9. Missing shader_type directive

## Tool: `delete_shader`
- [ ] 1. Delete unreferenced shader
- [ ] 2. Delete referenced shader (no force)
- [ ] 3. Force delete referenced shader
- [ ] 4. Explicit force=false
- [ ] 5. Omit path (validation error)
- [ ] 6. Delete non-existent file (error)
- [ ] 7. Delete non-shader file (.gd)
- [ ] 8. Force as non-boolean value (error)
- [ ] 9. Delete from nested directory
- [ ] 10. Empty string path (error)

## Cross-Tool Workflow: Full shader lifecycle
- [ ] 1. create_shader: lifecycle shader with brightness and base_color
- [ ] 2. read_shader: verify content includes uniforms
- [ ] 3. validate_shader: no compilation errors
- [ ] 4. assign_shader_material: assign to Sprite2D
- [ ] 5. set_shader_param: set brightness to 0.5
- [ ] 6. set_shader_param: set base_color to green
- [ ] 7. get_shader_params: verify both uniforms set correctly
- [ ] 8. list_shaders: lifecycle shader in project list
- [ ] 9. delete_shader (no force): error (referenced)
- [ ] 10. delete_shader (force): success
- [ ] 11. read_shader: error (file not found)

