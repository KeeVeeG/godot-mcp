# platform_export — Test Execution Checklist
> See plan: [platform_export_test_plan.md](./platform_export_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `export_for_platform`
- [ ] 1. Export Windows release (debug default)
- [ ] 2. Export Windows debug build
- [ ] 3. Export Linux release build
- [ ] 4. Export Linux debug build
- [ ] 5. Export macOS release build
- [ ] 6. Export macOS debug build
- [ ] 7. Export Android release build
- [ ] 8. Export Android debug build
- [ ] 9. Export iOS release build
- [ ] 10. Export iOS debug build
- [ ] 11. Export Web release build
- [ ] 12. Export Web debug build
- [ ] 13. Missing required param: platform
- [ ] 14. Invalid platform enum value
- [ ] 15. Invalid platform type (non-string)
- [ ] 16. Invalid debug type (non-boolean)
- [ ] 17. debug=false explicitly (same as release)

---

## Tool: `validate_platform_export`
- [ ] 18. Validate export for Windows Desktop
- [ ] 19. Validate export for Linux
- [ ] 20. Validate export for macOS
- [ ] 21. Validate export for Android
- [ ] 22. Validate export for iOS
- [ ] 23. Validate export for Web
- [ ] 24. Missing required param: platform
- [ ] 25. Empty string platform
- [ ] 26. Non-existent platform name

---

## Tool: `get_platform_export_templates`
- [ ] 27. List available export templates
- [ ] 28. Extra params tolerated (ignored)

---

## Tool: `create_platform_export_preset`
- [ ] 29. Create preset with minimum params
- [ ] 30. Create Linux preset
- [ ] 31. Create Android preset
- [ ] 32. Create Web preset
- [ ] 33. Create preset with custom settings
- [ ] 34. Create preset with empty settings object
- [ ] 35. Create preset with numeric settings
- [ ] 36. Missing required param: platform
- [ ] 37. Missing required param: name
- [ ] 38. Empty string name
- [ ] 39. Duplicate preset name
- [ ] 40. Invalid platform string
- [ ] 41. Invalid settings type (non-object)

---

## Tool: `run_exported_build`
- [ ] 42. Run build with minimum params
- [ ] 43. Run build with command-line arguments
- [ ] 44. Run build with empty args array
- [ ] 45. Run Linux exported binary
- [ ] 46. Run macOS exported app bundle
- [ ] 47. Run build with single argument
- [ ] 48. Missing required param: path
- [ ] 49. Non-existent file path
- [ ] 50. Non-executable file path
- [ ] 51. Invalid path type (non-string)
- [ ] 52. Invalid args type (non-array)
- [ ] 53. Args with special characters
- [ ] 54. Edge case: very long path

---

## Tool: `validate_export_for_platform`
- [ ] 55. Detailed validate for Windows Desktop
- [ ] 56. Detailed validate for Linux
- [ ] 57. Detailed validate for macOS
- [ ] 58. Detailed validate for Android
- [ ] 59. Detailed validate for iOS
- [ ] 60. Detailed validate for Web
- [ ] 61. Missing required param: platform
- [ ] 62. Empty string platform
- [ ] 63. Non-existent platform name
- [ ] 64. Compare with validate_platform_export detail

---

## Cross-Tool Integration
- [ ] 65. Full workflow: validate → preset → templates → export → run
- [ ] 66. Validate all six platforms sequentially

