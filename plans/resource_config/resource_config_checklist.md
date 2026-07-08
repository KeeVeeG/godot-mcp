# resource_config — Test Execution Checklist
> See plan: [resource_config_test_plan.md](./resource_config_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `get_resource_types`
- [ ] 1. Happy path — get all registered resource types
- [ ] 2. Call with unexpected extra params
- [ ] 3. Call with no arguments object at all

## Tool: `get_resource_properties`
- [ ] 1. Get properties for Texture2D
- [ ] 2. Get properties for AudioStream
- [ ] 3. Get properties for PackedScene
- [ ] 4. Get properties for Theme
- [ ] 5. Get properties for StandardMaterial3D
- [ ] 6. Missing required type parameter
- [ ] 7. Empty string for type
- [ ] 8. Non-existent resource type name
- [ ] 9. Very long type name (256 chars)
- [ ] 10. Invalid type — number instead of string
- [ ] 11. Invalid type — boolean instead of string
- [ ] 12. Invalid type — object instead of string

## Tool: `create_resource_from_template`
- [ ] 1. Create with only required params (no template)
- [ ] 2. Create with template
- [ ] 3. Create a Theme resource
- [ ] 4. Create a ShaderMaterial via template
- [ ] 5. Create with type StyleBoxFlat
- [ ] 6. Missing required type param
- [ ] 7. Missing required path param
- [ ] 8. Missing both required params
- [ ] 9. Empty string for type
- [ ] 10. Empty string for path
- [ ] 11. Non-existent template path
- [ ] 12. Template path that is not a resource file
- [ ] 13. Path outside res:// namespace
- [ ] 14. Invalid type — number
- [ ] 15. Invalid template — non-string
- [ ] 16. Template value is null
- [ ] 17. Duplicate output path (file already exists)
- [ ] 18. Very long path string

## Tool: `import_resource`
- [ ] 1. Import a file with no custom settings
- [ ] 2. Import with settings object
- [ ] 3. Import with empty settings object
- [ ] 4. Import an audio file
- [ ] 5. Import a 3D model (.fbx/.glb)
- [ ] 6. Import with settings omitted (optional behavior)
- [ ] 7. Missing required path param
- [ ] 8. Missing path param with settings present
- [ ] 9. Empty string for path
- [ ] 10. Non-existent file path
- [ ] 11. Invalid type for path — number
- [ ] 12. Invalid type for settings — string
- [ ] 13. Invalid type for settings — array
- [ ] 14. Settings with invalid import key

## Tool: `get_resource_import_settings`
- [ ] 1. Get import settings for a texture
- [ ] 2. Get import settings for an audio file
- [ ] 3. Get import settings for a 3D model
- [ ] 4. Get import settings for a .tres resource
- [ ] 5. Missing required path param
- [ ] 6. Empty string for path
- [ ] 7. Non-existent file path
- [ ] 8. Invalid type for path — number
- [ ] 9. Invalid type for path — boolean
- [ ] 10. Call with unexpected extra params

## Tool: `set_resource_import_settings`
- [ ] 1. Update a single import setting
- [ ] 2. Update multiple import settings at once
- [ ] 3. Update audio import settings
- [ ] 4. Update model import settings
- [ ] 5. Round-trip — get settings then re-apply them
- [ ] 6. Settings with empty object
- [ ] 7. Missing required path param
- [ ] 8. Missing required settings param
- [ ] 9. Missing both required params
- [ ] 10. Empty string for path
- [ ] 11. Non-existent file path
- [ ] 12. Invalid type for path — number
- [ ] 13. Invalid type for settings — string
- [ ] 14. Invalid type for settings — array
- [ ] 15. Invalid type for settings — null
- [ ] 16. Invalid type for settings — number
- [ ] 17. Settings with unrecognized keys
- [ ] 18. Settings with very large number of keys

