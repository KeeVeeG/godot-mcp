# project_creation — Test Execution Checklist
> See plan: [project_creation_test_plan.md](./project_creation_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `create_project`
- [ ] 1. Minimal params — default template
- [ ] 2. Path with res:// prefix
- [ ] 3. Path with spaces in name
- [ ] 4. template = `empty`
- [ ] 5. template = `2d`
- [ ] 6. template = `3d`
- [ ] 7. template = `ui`
- [ ] 8. template = `custom`
- [ ] 9. renderer = `forward_plus`
- [ ] 10. renderer = `mobile`
- [ ] 11. renderer = `gl_compatibility`
- [ ] 12. Explicit godot_version
- [ ] 13. Malformed godot_version
- [ ] 14. All parameters together
- [ ] 15. Missing required param: `path`
- [ ] 16. Missing required param: `name`
- [ ] 17. Invalid enum for `template`
- [ ] 18. Invalid enum for `renderer`
- [ ] 19. Empty string for `path`
- [ ] 20. Empty string for `name`
- [ ] 21. Path already exists (non-empty)
- [ ] 22. Path on non-existent drive
- [ ] 23. Extra unrecognized parameter

## Tool: `create_project_from_template`
- [ ] 1. Minimal params — no name override
- [ ] 2. All params with name override
- [ ] 3. res:// template_path
- [ ] 4. Missing required param: `path`
- [ ] 5. Missing required param: `template_path`
- [ ] 6. Missing both required params
- [ ] 7. template_path does not exist
- [ ] 8. template_path not valid Godot template
- [ ] 9. name is empty string

## Tool: `scaffold_project_structure`
- [ ] 1. Only project_path — default structure
- [ ] 2. structure = `standard`
- [ ] 3. structure = `minimal`
- [ ] 4. structure = `full`
- [ ] 5. res:// project_path
- [ ] 6. Missing required param: `project_path`
- [ ] 7. Invalid enum for `structure`
- [ ] 8. project_path does not exist
- [ ] 9. project_path not a Godot project
- [ ] 10. Scaffolding project that already has structure

## Tool: `create_project_with_assets`
- [ ] 1. Single asset — texture
- [ ] 2. Multiple assets of different types
- [ ] 3. Empty assets array
- [ ] 4. Asset with arbitrary type string
- [ ] 5. Missing required param: `path`
- [ ] 6. Missing required param: `name`
- [ ] 7. Missing required param: `assets`
- [ ] 8. Asset missing `type` field
- [ ] 9. Asset missing `source` field
- [ ] 10. Asset missing `destination` field
- [ ] 11. Source file does not exist
- [ ] 12. Invalid asset type

## Tool: `initialize_git_repository`
- [ ] 1. project_path only
- [ ] 2. include_gitignore = true
- [ ] 3. include_gitignore = false
- [ ] 4. Already a git repo (idempotent)
- [ ] 5. Missing required param: `project_path`
- [ ] 6. non-boolean for include_gitignore
- [ ] 7. include_gitignore = 0 (falsy number)
- [ ] 8. project_path does not exist
- [ ] 9. project_path not a Godot project
- [ ] 10. Extra unrecognized parameter

## Tool: `create_project_readme`
- [ ] 1. project_path only — default template
- [ ] 2. Custom content — overrides template
- [ ] 3. template = `basic`
- [ ] 4. template = `detailed`
- [ ] 5. template = `game`
- [ ] 6. Both content and template — content wins
- [ ] 7. Missing required param: `project_path`
- [ ] 8. Invalid template enum
- [ ] 9. README already exists (overwrite)
- [ ] 10. Empty content string
- [ ] 11. Very long content
- [ ] 12. project_path not a Godot project

## Tool: `create_project_license`
- [ ] 1. license = `MIT`
- [ ] 2. license = `Apache-2.0`
- [ ] 3. license = `GPL-3.0`
- [ ] 4. license = `BSD-3-Clause`
- [ ] 5. license = `custom` with custom_text
- [ ] 6. Missing required param: `project_path`
- [ ] 7. Missing required param: `license`
- [ ] 8. Invalid license enum
- [ ] 9. license = `custom` without custom_text
- [ ] 10. license = `MIT` with custom_text provided
- [ ] 11. custom_text empty string
- [ ] 12. Long custom_text

## Tool: `setup_project_dependencies`
- [ ] 1. Single addon from asset_lib
- [ ] 2. Single addon from git with URL
- [ ] 3. Single addon from local path
- [ ] 4. Multiple addons — mixed sources
- [ ] 5. Empty addons array
- [ ] 6. source = `asset_lib` without url
- [ ] 7. source = `git` with url
- [ ] 8. source = `local` with url as path
- [ ] 9. Missing required param: `project_path`
- [ ] 10. Missing required param: `addons`
- [ ] 11. Addon object missing `name`
- [ ] 12. Addon object missing `source`
- [ ] 13. Invalid source enum
- [ ] 14. git source without url
- [ ] 15. local source without url
- [ ] 16. asset_lib with unnecessary url
- [ ] 17. Invalid git URL
- [ ] 18. Non-existent local path

## Tool: `validate_project_structure`
- [ ] 1. Valid Godot project
- [ ] 2. Freshly created project
- [ ] 3. Project with custom structure
- [ ] 4. Missing required param: `project_path`
- [ ] 5. project_path does not exist
- [ ] 6. Not a Godot project — no project.godot
- [ ] 7. Missing critical directories
- [ ] 8. Circular scene references

## Tool: `get_project_templates`
- [ ] 1. Basic call — no parameters
- [ ] 2. Verify returned templates match enum values
- [ ] 3. Extra params — should ignore
- [ ] 4. No Godot project open

## Cross-Tool Workflow
- [ ] 1. Full project bootstrap: create → scaffold → git → readme → license → validate
- [ ] 2. Template discovery → creation
- [ ] 3. Error when project already exists

