# batch — Test Execution Checklist
> See plan: [batch_test_plan.md](./batch_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `find_nodes_by_type`
- [ ] 1. Find Sprite2D nodes in a 2D scene
- [ ] 2. Find Node2D scene root node
- [ ] 3. Node type with zero matches
- [ ] 4. Empty string for type_name
- [ ] 5. Non-existent class name
- [ ] 6. Missing type_name parameter
- [ ] 7. type_name with non-string value
- [ ] 8. Godot editor not connected

## Tool: `find_signal_connections`
- [ ] 1. Scene with signal connections
- [ ] 2. Scene with no signal connections
- [ ] 3. Call with extra params
- [ ] 4. Godot editor not connected

## Tool: `batch_set_property`
- [ ] 1. Set visible=false on all Sprite2D nodes
- [ ] 2. Set modulate:a=0.5 on all Label nodes
- [ ] 3. Set position to [100,200] on Node2D
- [ ] 4. Set name="RenamedNode" on all Node nodes
- [ ] 5. Type with zero matching nodes
- [ ] 6. Invalid property name
- [ ] 7. Missing type_name parameter
- [ ] 8. Missing property parameter
- [ ] 9. Missing value parameter
- [ ] 10. Godot editor not connected

## Tool: `find_node_references`
- [ ] 1. Search for node named "Player"
- [ ] 2. Search with full path "Player/Camera2D"
- [ ] 3. Search with unique path "%Player"
- [ ] 4. Query with no matches
- [ ] 5. Empty string query
- [ ] 6. Query with regex special characters
- [ ] 7. Missing query parameter
- [ ] 8. Godot editor not connected

## Tool: `get_scene_dependencies`
- [ ] 1. Check dependencies of main scene
- [ ] 2. Scene with no external dependencies
- [ ] 3. Scene with nested sub-scene chain
- [ ] 4. Non-existent file path
- [ ] 5. Path without res:// prefix
- [ ] 6. Path is a directory, not a file
- [ ] 7. Path is not a .tscn file
- [ ] 8. Missing path parameter
- [ ] 9. Godot editor not connected

## Tool: `cross_scene_set_property`
- [ ] 1. With confirmation (confirm_no_undo=true)
- [ ] 2. Without confirmation — should be blocked
- [ ] 3. confirm_no_undo with truthy non-boolean
- [ ] 4. Set scale=[2,2] cross-scene
- [ ] 5. Type with zero matches across scenes
- [ ] 6. Missing type_name parameter
- [ ] 7. Missing property parameter
- [ ] 8. Missing value parameter
- [ ] 9. Godot editor not connected

## Tool: `find_script_references`
- [ ] 1. Script with known usage
- [ ] 2. Script referenced across multiple scenes
- [ ] 3. Script with zero references
- [ ] 4. Non-existent script path
- [ ] 5. Path without res:// prefix
- [ ] 6. Built-in Godot addon script path
- [ ] 7. Missing script_path parameter
- [ ] 8. Godot editor not connected

## Tool: `detect_circular_dependencies`
- [ ] 1. Project with no circular dependencies
- [ ] 2. Project with deliberate circular dependencies
- [ ] 3. Empty/minimal project
- [ ] 4. Extra params ignored by handler
- [ ] 5. Godot editor not connected

