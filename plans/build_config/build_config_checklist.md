# build_config — Test Execution Checklist
> See plan: [build_config_test_plan.md](./build_config_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: get_build_settings
- [ ] 1. Basic happy path — get current build settings
- [ ] 2. Call with unexpected extra params
- [ ] 3. Call with no arguments at all

## Tool: set_build_configuration
- [ ] 1. Happy path — set config to `debug` (default)
- [ ] 2. Set configuration to `release`
- [ ] 3. Set configuration to `development`
- [ ] 4. Invalid enum value — non-existent config option
- [ ] 5. Invalid type — number instead of string
- [ ] 6. Invalid type — boolean instead of string
- [ ] 7. Empty string as config value
- [ ] 8. Extra unexpected params included

## Tool: set_scripting_backend
- [ ] 1. Happy path — set backend to `gdscript` (default)
- [ ] 2. Set backend to `csharp`
- [ ] 3. Invalid enum value — non-existent backend
- [ ] 4. Invalid type — number
- [ ] 5. Case sensitivity — uppercase vs lowercase
- [ ] 6. Explicit gdscript with the enum value

## Tool: set_export_filter
- [ ] 1. Happy path — set filter to `all_resources` (default)
- [ ] 2. Set filter to `selected_resources`
- [ ] 3. Invalid enum value
- [ ] 4. Invalid type — boolean
- [ ] 5. Explicit all_resources with the enum value

## Tool: set_custom_features
- [ ] 1. Happy path — set a single custom feature
- [ ] 2. Set multiple custom features
- [ ] 3. Clear all custom features (default empty array)
- [ ] 4. Explicit empty array
- [ ] 5. Single-element array with special characters
- [ ] 6. Invalid type — string instead of array
- [ ] 7. Invalid type — array with non-string elements
- [ ] 8. Invalid type — null
- [ ] 9. Large list of features

## Tool: set_debug_options
- [ ] 1. Happy path — set all options to true
- [ ] 2. Set all options to false
- [ ] 3. Set only `debug_build` (partial update)
- [ ] 4. Set only `release_debug`
- [ ] 5. Set only `optimize`
- [ ] 6. Mixed values — debug true, optimize false
- [ ] 7. Call with empty params object
- [ ] 8. Invalid type — string for boolean param
- [ ] 9. Invalid type — number for boolean param
- [ ] 10. Unrecognized parameter name
- [ ] 11. All three options with explicit boolean false

## Tool: validate_build_settings
- [ ] 1. Basic happy path — validate default build settings
- [ ] 2. Validate after changing settings (post-mutation check)
- [ ] 3. Call with unexpected extra params
- [ ] 4. Call with no arguments

## Tool: get_build_command
- [ ] 1. Happy path — get build command for `windows`
- [ ] 2. Get build command for `linux`
- [ ] 3. Get build command for `web`
- [ ] 4. Get build command for `android`
- [ ] 5. Get build command for `macos`
- [ ] 6. Get build command for `ios`
- [ ] 7. Missing required `platform` parameter
- [ ] 8. Empty string for platform
- [ ] 9. Invalid type — number for platform
- [ ] 10. Invalid type — boolean for platform
- [ ] 11. Unknown/unusual platform string
- [ ] 12. Platform string with special characters
- [ ] 13. Extra params alongside required platform

## Cross-Tool Integration
- [ ] CT1. Full build config cycle — set, read, validate, get command
- [ ] CT2. Reset features and verify
- [ ] CT3. Toggle build configuration through all three presets

