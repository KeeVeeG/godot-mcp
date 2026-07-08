# editor_config — Test Execution Checklist
> See plan: [editor_config_test_plan.md](./editor_config_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: get_editor_settings
- [ ] 1. Basic happy path — get editor settings
- [ ] 2. Call with no arguments object at all
- [ ] 3. Call with unexpected extra params
- [ ] 4. Idempotency — call twice in succession

## Tool: set_editor_theme
- [ ] 1. Happy path — set theme to `dark`
- [ ] 2. Happy path — set theme to `light`
- [ ] 3. Happy path — set theme to `amoled`
- [ ] 4. Round-trip — cycle through all three themes
- [ ] 5. Missing required parameter — no `theme`
- [ ] 6. Invalid enum value — `theme: "blue"`
- [ ] 7. Invalid enum value — empty string
- [ ] 8. Invalid type — `theme` as number
- [ ] 9. Idempotency — set same theme twice

## Tool: set_editor_layout
- [ ] 1. Happy path — set layout to `default`
- [ ] 2. Happy path — set layout to `2d`
- [ ] 3. Happy path — set layout to `3d`
- [ ] 4. Happy path — set layout to `script`
- [ ] 5. Round-trip — cycle through all four layouts
- [ ] 6. Missing required parameter — no `layout`
- [ ] 7. Invalid enum value — `layout: "audio"`
- [ ] 8. Invalid enum value — empty string
- [ ] 9. Invalid type — `layout` as boolean

## Tool: set_font_size
- [ ] 1. Happy path — set font size to 14
- [ ] 2. Set font size to minimum boundary (8)
- [ ] 3. Set font size to maximum boundary (48)
- [ ] 4. Set font size to 24 (common large)
- [ ] 5. Font size below minimum (7)
- [ ] 6. Font size above maximum (49)
- [ ] 7. Font size of zero
- [ ] 8. Negative font size
- [ ] 9. Non-integer font size (13.5)
- [ ] 10. Missing required parameter — no `size`
- [ ] 11. Invalid type — `size` as string
- [ ] 12. Invalid type — `size` as boolean

## Tool: set_editor_scale
- [ ] 1. Happy path — set scale to 1.0
- [ ] 2. Set scale to minimum boundary (0.5)
- [ ] 3. Set scale to maximum boundary (3.0)
- [ ] 4. Set scale to 1.5 (150%)
- [ ] 5. Set scale to 0.75 (75%)
- [ ] 6. Scale below minimum (0.49)
- [ ] 7. Scale above maximum (3.01)
- [ ] 8. Scale of zero
- [ ] 9. Negative scale
- [ ] 10. Precise fractional scale (1.175)
- [ ] 11. Missing required parameter — no `scale`
- [ ] 12. Invalid type — `scale` as string
- [ ] 13. Invalid type — `scale` as boolean

## Tool: save_editor_layout
- [ ] 1. Happy path — save layout with simple name
- [ ] 2. Happy path — save layout with descriptive name
- [ ] 3. Save layout, change layout, save another
- [ ] 4. Overwrite existing layout name
- [ ] 5. Missing required parameter — no `name`
- [ ] 6. Empty string name
- [ ] 7. Very long name
- [ ] 8. Name with special characters
- [ ] 9. Invalid type — `name` as number

## Tool: load_editor_layout
- [ ] 1. Happy path — load a previously saved layout
- [ ] 2. Load layout, make changes, load again
- [ ] 3. Load non-existent layout
- [ ] 4. Missing required parameter — no `name`
- [ ] 5. Empty string name
- [ ] 6. Invalid type — `name` as boolean

## Tool: reset_editor_layout
- [ ] 1. Happy path — reset layout
- [ ] 2. Reset layout with no prior changes
- [ ] 3. Reset layout after saving a named layout
- [ ] 4. Call with no arguments
- [ ] 5. Call with unexpected extra params

## Integration / Cross-Tool Scenarios
- [ ] I. Full settings round-trip — all tools in sequence
- [ ] II. Save → reset → load cycle
- [ ] III. Multiple layout switching — rapid switches

