# platform_specific — Test Execution Checklist
> See plan: [platform_specific_test_plan.md](./platform_specific_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: get_platform_settings
- [ ] 1. Get settings for 'windows'
- [ ] 2. Get settings for 'linux'
- [ ] 3. Get settings for 'macos'
- [ ] 4. Get settings for 'ios'
- [ ] 5. Get settings for 'android'
- [ ] 6. Get settings for 'web'
- [ ] 7. Unknown platform string ('xbox')
- [ ] 8. Empty string for platform
- [ ] 9. Platform name with uppercase
- [ ] 10. Platform name with mixed case
- [ ] 11. Missing required parameter — platform
- [ ] 12. Invalid type for platform (number)
- [ ] 13. Invalid type for platform (boolean)
- [ ] 14. Invalid type for platform (object)
- [ ] 15. Invalid type for platform (array)
- [ ] 16. Very long platform name (5000 chars)
- [ ] 17. Platform name with special characters
- [ ] 18. Platform name with spaces
- [ ] 19. Platform name with trailing whitespace
- [ ] 20. Call with extra unknown params

---

## Tool: configure_ios
- [ ] 1. Configure bundle_id only
- [ ] 2. Configure team_id only
- [ ] 3. Configure signing only
- [ ] 4. Configure signing with various value types
- [ ] 5. Configure bundle_id and team_id together
- [ ] 6. Full configuration (all fields)
- [ ] 7. Empty settings object
- [ ] 8. Empty string for bundle_id
- [ ] 9. Empty string for team_id
- [ ] 10. Signing as empty object
- [ ] 11. Signing as null
- [ ] 12. Bundle_id with special characters
- [ ] 13. Bundle_id with path traversal characters
- [ ] 14. Missing required parameter — settings
- [ ] 15. Invalid type for settings (string)
- [ ] 16. Invalid type for settings (array)
- [ ] 17. Invalid type for settings (boolean)
- [ ] 18. Invalid type for bundle_id (number)
- [ ] 19. Invalid type for team_id (boolean)
- [ ] 20. Invalid type for signing (string)
- [ ] 21. Invalid type for signing (array)
- [ ] 22. Extra unknown params at settings level
- [ ] 23. Extra unknown params at top level
- [ ] 24. Very long string values (10k chars)
- [ ] 25. Settings is null
- [ ] 26. Configure ios, then read back via get_platform_settings

---

## Tool: configure_android
- [ ] 1. Configure package_name only
- [ ] 2. Configure permissions only (single permission)
- [ ] 3. Configure permissions only (multiple permissions)
- [ ] 4. Configure permissions with an empty array
- [ ] 5. Configure keystore only
- [ ] 6. Configure keystore with various value types
- [ ] 7. Full configuration (all fields)
- [ ] 8. Configure package_name and permissions together
- [ ] 9. Empty settings object
- [ ] 10. Empty string for package_name
- [ ] 11. Permissions with an empty string element
- [ ] 12. Permissions with invalid permission names
- [ ] 13. Keystore as empty object
- [ ] 14. Keystore as null
- [ ] 15. Missing required parameter — settings
- [ ] 16. Invalid type for settings (string)
- [ ] 17. Invalid type for settings (array)
- [ ] 18. Invalid type for settings (boolean)
- [ ] 19. Invalid type for package_name (number)
- [ ] 20. Invalid type for package_name (boolean)
- [ ] 21. Invalid type for permissions (string)
- [ ] 22. Invalid type for permissions (object)
- [ ] 23. Invalid type for permissions element (number)
- [ ] 24. Invalid type for permissions element (boolean)
- [ ] 25. Invalid type for keystore (string)
- [ ] 26. Invalid type for keystore (array)
- [ ] 27. Extra unknown params at settings level
- [ ] 28. Extra unknown params at top level
- [ ] 29. Very long string values (10k chars)
- [ ] 30. Permissions array with many elements (stress)
- [ ] 31. Configure android, then read back via get_platform_settings

---

## Tool: configure_web
- [ ] 1. Configure canvas_resize only (true)
- [ ] 2. Configure canvas_resize only (false)
- [ ] 3. Configure threading only (true)
- [ ] 4. Configure threading only (false)
- [ ] 5. Configure pwa only (true)
- [ ] 6. Configure pwa only (false)
- [ ] 7. Configure canvas_resize + threading
- [ ] 8. Configure threading + pwa
- [ ] 9. Full configuration (all three true)
- [ ] 10. Full configuration (all three false)
- [ ] 11. Mixed booleans
- [ ] 12. Empty settings object
- [ ] 13. Missing required parameter — settings
- [ ] 14. Invalid type for settings (string)
- [ ] 15. Invalid type for settings (array)
- [ ] 16. Invalid type for settings (boolean)
- [ ] 17. Invalid type for canvas_resize (string)
- [ ] 18. Invalid type for canvas_resize (number)
- [ ] 19. Invalid type for threading (string)
- [ ] 20. Invalid type for threading (array)
- [ ] 21. Invalid type for pwa (number)
- [ ] 22. Invalid type for pwa (object)
- [ ] 23. Invalid type for pwa (null)
- [ ] 24. Extra unknown params at settings level
- [ ] 25. Extra unknown params at top level
- [ ] 26. Configure web, then read back via get_platform_settings

---

## Tool: get_platform_capabilities
- [ ] 1. Query capabilities for 'windows'
- [ ] 2. Query capabilities for 'linux'
- [ ] 3. Query capabilities for 'macos'
- [ ] 4. Query capabilities for 'ios'
- [ ] 5. Query capabilities for 'android'
- [ ] 6. Query capabilities for 'web'
- [ ] 7. Unknown platform ('playstation')
- [ ] 8. Empty string for platform
- [ ] 9. Mixed case platform name
- [ ] 10. Missing required parameter — platform
- [ ] 11. Invalid type for platform (number)
- [ ] 12. Invalid type for platform (boolean)
- [ ] 13. Invalid type for platform (object)
- [ ] 14. Invalid type for platform (array)
- [ ] 15. Very long platform name (5000 chars)
- [ ] 16. Platform name with special characters
- [ ] 17. Call with extra unknown params
- [ ] 18. Query all example platforms and compare results

---

## Tool: validate_platform_build
- [ ] 1. Validate build for 'windows'
- [ ] 2. Validate build for 'linux'
- [ ] 3. Validate build for 'macos'
- [ ] 4. Validate build for 'ios'
- [ ] 5. Validate build for 'android'
- [ ] 6. Validate build for 'web'
- [ ] 7. Validate after configuring platform settings
- [ ] 8. Validate before and after android config
- [ ] 9. Validate web build after enabling threading
- [ ] 10. Unknown platform ('nintendo_switch')
- [ ] 11. Empty string for platform
- [ ] 12. Missing required parameter — platform
- [ ] 13. Invalid type for platform (number)
- [ ] 14. Invalid type for platform (boolean)
- [ ] 15. Invalid type for platform (object)
- [ ] 16. Invalid type for platform (array)
- [ ] 17. Very long platform name (5000 chars)
- [ ] 18. Call with extra unknown params
- [ ] 19. Validate all common platforms sequentially
- [ ] 20. Validate with mixed case platform name

---

## Cross-Tool Integration Scenarios
- [ ] I. Full iOS workflow — configure → get settings → validate
- [ ] II. Full Android workflow — configure → get settings → validate
- [ ] III. Full Web workflow — configure → get settings → validate
- [ ] IV. Configure all three platforms then validate all three
- [ ] V. Cross-platform capabilities comparison

