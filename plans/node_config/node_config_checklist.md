# node_config — Test Execution Checklist
> See plan: [node_config_test_plan.md](./node_config_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: get_node_default_properties
- [ ] 1. Query defaults for Sprite2D (valid 2D type)
- [ ] 2. Query defaults for CharacterBody3D (valid 3D type)
- [ ] 3. Query defaults for Button (UI node type)
- [ ] 4. Query defaults for custom script class (e.g. Player)
- [ ] 5. Query defaults for non-existent node type
- [ ] 6. Pass empty string as type
- [ ] 7. Omit required `type` parameter
- [ ] 8. Pass number instead of string for `type`
- [ ] 9. Pass special characters in type name

## Tool: set_node_preset
- [ ] 1. Apply valid preset to CharacterBody2D (platformer_body)
- [ ] 2. Apply top_down_camera preset to Camera3D
- [ ] 3. Apply unrecognized preset name
- [ ] 4. Pass empty string as preset
- [ ] 5. Pass invalid node type with valid preset
- [ ] 6. Omit required `type` parameter
- [ ] 7. Omit required `preset` parameter
- [ ] 8. Omit both parameters
- [ ] 9. Pass number instead of string for `preset`

## Tool: get_available_node_types
- [ ] 1. Get all types with no category filter
- [ ] 2. Filter by `2d` category
- [ ] 3. Filter by `3d` category
- [ ] 4. Filter by `ui` category
- [ ] 5. Filter by `audio` category
- [ ] 6. Filter by `physics` category
- [ ] 7. Filter by `navigation` category
- [ ] 8. Pass invalid category string (not in enum)
- [ ] 9. Pass empty string as category
- [ ] 10. Pass uppercase category (case-sensitive enum)
- [ ] 11. Pass number instead of string for category

## Tool: get_node_signals
- [ ] 1. Get signals by type (Button)
- [ ] 2. Get signals by type (CharacterBody3D)
- [ ] 3. Get signals by path (node in scene)
- [ ] 4. Call with neither `type` nor `path`
- [ ] 5. Provide both `type` and `path`
- [ ] 6. Pass empty string as `type`
- [ ] 7. Pass empty string as `path` (scene root)
- [ ] 8. Pass non-existent type name
- [ ] 9. Pass path to non-existent node
- [ ] 10. Pass number instead of string

## Tool: get_node_methods
- [ ] 1. Get methods for Sprite2D (2D node)
- [ ] 2. Get methods for CharacterBody3D (3D node)
- [ ] 3. Get methods for Button (UI node)
- [ ] 4. Get methods for base type Node
- [ ] 5. Query methods for non-existent type
- [ ] 6. Omit required `type` parameter
- [ ] 7. Pass number instead of string for `type`
- [ ] 8. Pass empty string as `type`

## Tool: get_node_enums
- [ ] 1. Get enums for AnimationPlayer (known enums)
- [ ] 2. Get enums for BoxContainer (alignment enum)
- [ ] 3. Get enums for type with no enums (Sprite2D)
- [ ] 4. Query enums for non-existent type
- [ ] 5. Omit required `type` parameter
- [ ] 6. Pass number instead of string for `type`

## Tool: get_node_constants
- [ ] 1. Get constants for InputEventKey (many constants)
- [ ] 2. Get constants for BaseButton (typical constants)
- [ ] 3. Get constants for type with none (Panel)
- [ ] 4. Query constants for non-existent type
- [ ] 5. Omit required `type` parameter
- [ ] 6. Pass boolean instead of string for `type`

## Tool: get_class_hierarchy
- [ ] 1. Get hierarchy for Sprite2D (deep chain)
- [ ] 2. Get hierarchy for CharacterBody3D (3D node)
- [ ] 3. Get hierarchy for Button (UI node)
- [ ] 4. Get hierarchy for base type Node
- [ ] 5. Get hierarchy for Resource (non-Node type)
- [ ] 6. Get hierarchy for Object (ultimate base)
- [ ] 7. Query hierarchy for non-existent type
- [ ] 8. Omit required `type` parameter
- [ ] 9. Pass array instead of string for `type`
- [ ] 10. Pass whitespace-only type string

