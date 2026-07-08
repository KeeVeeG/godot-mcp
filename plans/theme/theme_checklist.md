# theme — Test Execution Checklist
> See plan: [theme_test_plan.md](./theme_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: create_theme
- [ ] 1. Happy path — create theme in subdirectory
- [ ] 2. Happy path — create theme at deeper path
- [ ] 3. Happy path — create theme with varied filename
- [ ] 4. Missing required param — no path
- [ ] 5. Invalid path — no file extension
- [ ] 6. Invalid path — wrong extension (.res)
- [ ] 7. Invalid path — absolute OS filesystem path
- [ ] 8. Invalid path — empty string
- [ ] 9. Invalid path — overwrite existing scene path
- [ ] 10. Path with trailing slash

## Tool: delete_theme
- [ ] 1. Happy path — delete an existing theme
- [ ] 2. Happy path — delete theme in subdirectory
- [ ] 3. Missing required param — no path
- [ ] 4. Invalid path — file does not exist
- [ ] 5. Invalid path — delete a non-theme resource
- [ ] 6. Invalid path — empty string
- [ ] 7. Delete theme currently referenced by nodes
- [ ] 8. Delete the same file twice (idempotency)

## Tool: set_theme_color
- [ ] 1. Happy path — set Button font_color with hex
- [ ] 2. Happy path — set Button hover color with name
- [ ] 3. Happy path — set color with alpha hex
- [ ] 4. Happy path — set Label font_color (green)
- [ ] 5. Happy path — set Panel font_color (blue)
- [ ] 6. Happy path — set non-font color (icon)
- [ ] 7. Happy path — overwrite previously set color
- [ ] 8. Missing required param — no path
- [ ] 9. Missing required param — no theme_type
- [ ] 10. Missing required param — no name
- [ ] 11. Missing required param — no color
- [ ] 12. Invalid color — malformed hex (#FFGG00)
- [ ] 13. Invalid color — arbitrary non-color string
- [ ] 14. Invalid theme_type — empty string
- [ ] 15. Invalid theme_type — nonexistent control type
- [ ] 16. Invalid path — theme file does not exist
- [ ] 17. Set color for container control type
- [ ] 18. Set color to fully transparent

## Tool: set_theme_constant
- [ ] 1. Happy path — set hseparation for Button
- [ ] 2. Happy path — set vseparation for Button
- [ ] 3. Happy path — set large constant (99999)
- [ ] 4. Happy path — set constant to zero
- [ ] 5. Happy path — set constant to negative integer
- [ ] 6. Happy path — set constant for non-Button type
- [ ] 7. Happy path — overwrite previously set constant
- [ ] 8. Missing required param — no path
- [ ] 9. Missing required param — no theme_type
- [ ] 10. Missing required param — no name
- [ ] 11. Missing required param — no value
- [ ] 12. Invalid value — float instead of integer
- [ ] 13. Invalid value — string instead of integer
- [ ] 14. Invalid value — boolean instead of integer
- [ ] 15. Invalid value — null
- [ ] 16. Invalid value — object
- [ ] 17. Set constant on nonexistent theme

## Tool: set_theme_font_size
- [ ] 1. Happy path — set font_size for Button (14px)
- [ ] 2. Happy path — set font_size for Label (16px)
- [ ] 3. Happy path — minimum valid size (1px)
- [ ] 4. Happy path — large font size (512px)
- [ ] 5. Happy path — overwrite previously set size
- [ ] 6. Happy path — set font_size for Panel
- [ ] 7. Missing required param — no path
- [ ] 8. Missing required param — no theme_type
- [ ] 9. Missing required param — no name
- [ ] 10. Missing required param — no size
- [ ] 11. Invalid size — zero
- [ ] 12. Invalid size — negative integer
- [ ] 13. Invalid size — float (14.5)
- [ ] 14. Invalid size — string
- [ ] 15. Invalid size — boolean
- [ ] 16. Nonexistent theme

## Tool: set_theme_stylebox
- [ ] 1. Happy path — basic StyleBox with bg_color
- [ ] 2. Happy path — StyleBox with border and corners
- [ ] 3. Happy path — hover state StyleBox
- [ ] 4. Happy path — pressed state StyleBox
- [ ] 5. Happy path — focus state StyleBox
- [ ] 6. Happy path — disabled state StyleBox
- [ ] 7. Happy path — StyleBox for Panel type
- [ ] 8. Happy path — StyleBox with shadow properties
- [ ] 9. Happy path — StyleBox with content margins
- [ ] 10. Happy path — StyleBox with expand margins
- [ ] 11. Happy path — draw_center and anti_aliased flags
- [ ] 12. Happy path — empty properties object
- [ ] 13. Missing required param — no path
- [ ] 14. Missing required param — no theme_type
- [ ] 15. Missing required param — no name
- [ ] 16. Missing required param — no properties
- [ ] 17. Invalid properties — string instead of object
- [ ] 18. Invalid properties — array instead of object
- [ ] 19. Invalid properties — null
- [ ] 20. Invalid properties — number instead of object
- [ ] 21. Nonexistent theme
- [ ] 22. StyleBox with custom/non-standard state name
- [ ] 23. StyleBox with nonexistent property name

## Tool: get_theme_info
- [ ] 1. Happy path — get info on empty theme
- [ ] 2. Happy path — get info on populated theme
- [ ] 3. Happy path — validate color override values
- [ ] 4. Happy path — validate constant override values
- [ ] 5. Happy path — validate font size values
- [ ] 6. Happy path — validate StyleBox structures
- [ ] 7. Missing required param — no path
- [ ] 8. Invalid path — nonexistent theme
- [ ] 9. Invalid path — path to non-theme resource
- [ ] 10. Invalid path — empty string
- [ ] 11. Get info on default/built-in theme
- [ ] 12. Repeated calls — verify idempotency
- [ ] 13. Path with URL-encoded characters (spaces)

