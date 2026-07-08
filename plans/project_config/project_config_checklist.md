# project_config — Test Execution Checklist
> See plan: [project_config_test_plan.md](./project_config_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `get_project_setting`
- [ ] 1. Read application/config/name
- [ ] 2. Read viewport width
- [ ] 3. Read physics ticks per second
- [ ] 4. Read renderer type
- [ ] 5. Read emulate touch from mouse
- [ ] 6. Request nonexistent setting key
- [ ] 7. Call without key parameter
- [ ] 8. Pass number as key
- [ ] 9. Pass boolean as key
- [ ] 10. Pass empty string key
- [ ] 11. Trailing slash in key

## Tool: `set_project_setting_config`
- [ ] 1. Set project name string
- [ ] 2. Set viewport width numeric
- [ ] 3. Set touch emulation boolean
- [ ] 4. Set default gravity float
- [ ] 5. Set main scene path string
- [ ] 6. Set negative viewport height
- [ ] 7. Set extremely large ticks per second
- [ ] 8. Pass string to numeric setting
- [ ] 9. Call without key parameter
- [ ] 10. Call without value parameter
- [ ] 11. Call with empty object
- [ ] 12. Pass number as key
- [ ] 13. Pass nested object as value
- [ ] 14. Pass null as value
- [ ] 15. Pass array as value

## Tool: `get_all_project_settings`
- [ ] 1. Get all settings unfiltered
- [ ] 2. Filter by display/ prefix
- [ ] 3. Filter by input/ prefix
- [ ] 4. Filter by application/ prefix
- [ ] 5. Filter by physics/ prefix
- [ ] 6. Filter by rendering/ prefix
- [ ] 7. Filter with nonexistent prefix
- [ ] 8. Filter display without trailing slash
- [ ] 9. Deeply nested prefix filter
- [ ] 10. Pass number as filter
- [ ] 11. Pass boolean as filter
- [ ] 12. Pass empty string filter

## Tool: `reset_project_setting`
- [ ] 1. Reset previously modified setting
- [ ] 2. Reset viewport width to default
- [ ] 3. Reset already-default setting
- [ ] 4. Reset nonexistent setting key
- [ ] 5. Key with trailing whitespace
- [ ] 6. Call without key parameter
- [ ] 7. Pass number as key
- [ ] 8. Pass empty string key

## Tool: `get_input_map`
- [ ] 1. Retrieve current InputMap
- [ ] 2. Verify response data structure
- [ ] 3. Call with extra params
- [ ] 4. Call with empty params

## Tool: `set_input_map`
- [ ] 1. Set minimal single-action map
- [ ] 2. Set map with multiple actions
- [ ] 3. Bind controller buttons
- [ ] 4. Bind mouse buttons
- [ ] 5. Bind joystick axis
- [ ] 6. Set empty actions object
- [ ] 7. Pass event without type field
- [ ] 8. Pass event with empty type string
- [ ] 9. Call without actions parameter
- [ ] 10. Pass string instead of object
- [ ] 11. Pass string for events array
- [ ] 12. Pass plain string in events
- [ ] 13. Action name with special chars
- [ ] 14. Set map with 50+ actions

## Tool: `add_input_action`
- [ ] 1. Add action with default deadzone
- [ ] 2. Add action with zero deadzone
- [ ] 3. Add action with max deadzone
- [ ] 4. Add action with multiple bindings
- [ ] 5. Bind controller button
- [ ] 6. Bind mouse button
- [ ] 7. Pass negative deadzone value
- [ ] 8. Pass deadzone above 1.0
- [ ] 9. Pass string as deadzone
- [ ] 10. Call without action parameter
- [ ] 11. Call without events parameter
- [ ] 12. Pass empty events array
- [ ] 13. Add duplicate action name
- [ ] 14. Pass event without type field
- [ ] 15. Pass event with imaginary type
- [ ] 16. Pass number as action name
- [ ] 17. Pass object for events array

## Tool: `remove_input_action`
- [ ] 1. Remove previously added action
- [ ] 2. Remove built-in ui_accept action
- [ ] 3. Remove nonexistent action name
- [ ] 4. Remove and re-add same action
- [ ] 5. Call without action parameter
- [ ] 6. Pass number as action
- [ ] 7. Pass empty string action
- [ ] 8. Pass whitespace string action

## Tool: `get_autoloads`
- [ ] 1. Retrieve autoload list
- [ ] 2. Verify entry has name/path/enabled
- [ ] 3. Verify new autoload appears after add
- [ ] 4. Call with extra params

## Tool: `add_autoload_config`
- [ ] 1. Add enabled autoload to script
- [ ] 2. Add disabled autoload
- [ ] 3. Add autoload with scene path
- [ ] 4. Call without name parameter
- [ ] 5. Call without path parameter
- [ ] 6. Pass number as name
- [ ] 7. Pass number as path
- [ ] 8. Pass string for enabled
- [ ] 9. Point to nonexistent file
- [ ] 10. Use existing autoload name
- [ ] 11. Pass empty name string
- [ ] 12. Pass empty path string
- [ ] 13. Use absolute disk path
- [ ] 14. Explicitly set enabled to true

## Tool: `remove_autoload_config`
- [ ] 1. Remove previously added autoload
- [ ] 2. Remove disabled autoload
- [ ] 3. Remove nonexistent autoload name
- [ ] 4. Remove mcp_runtime autoload
- [ ] 5. Call without name parameter
- [ ] 6. Pass number as name
- [ ] 7. Pass empty string name

## Tool: `reorder_autoloads`
- [ ] 1. Reorder existing autoloads
- [ ] 2. Reorder single autoload
- [ ] 3. Pass empty order array
- [ ] 4. Include unregistered name in order
- [ ] 5. List same name twice
- [ ] 6. Call without order parameter
- [ ] 7. Pass string instead of array
- [ ] 8. Pass numbers in order array
- [ ] 9. Mix strings and numbers in order
- [ ] 10. Pass object instead of array

