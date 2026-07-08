# node — Test Execution Checklist
> See plan: [node_test_plan.md](./node_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: add_node
- [ ] 1. Add node to scene root (happy path)
- [ ] 2. Add node as child of existing node
- [ ] 3. Add node with properties
- [ ] 4. Missing required param parent_path
- [ ] 5. Missing required param type
- [ ] 6. Missing required param name
- [ ] 7. Invalid node type
- [ ] 8. Invalid parent path
- [ ] 9. Add various node types
- [ ] 10. Empty properties object

## Tool: delete_node
- [ ] 1. Delete an existing node (happy path)
- [ ] 2. Delete a nested node
- [ ] 3. Delete scene root
- [ ] 4. Delete non-existent node
- [ ] 5. Missing required param path

## Tool: duplicate_node
- [ ] 1. Duplicate an existing node (happy path)
- [ ] 2. Duplicate a nested node
- [ ] 3. Duplicate scene root
- [ ] 4. Duplicate non-existent node
- [ ] 5. Missing required param path

## Tool: move_node
- [ ] 1. Move node to different parent (happy path)
- [ ] 2. Move node with specific index
- [ ] 3. Move node to scene root
- [ ] 4. Missing required param path
- [ ] 5. Missing required param new_parent
- [ ] 6. Negative index
- [ ] 7. Non-integer index
- [ ] 8. Non-existent source node
- [ ] 9. Non-existent target parent
- [ ] 10. Index beyond child count

## Tool: update_property
- [ ] 1. Update a string property (happy path)
- [ ] 2. Update a numeric property
- [ ] 3. Update a boolean property
- [ ] 4. Update a Vector2 property
- [ ] 5. Update a Color property
- [ ] 6. Missing required param path
- [ ] 7. Missing required param property
- [ ] 8. Missing required param value
- [ ] 9. Non-existent property
- [ ] 10. Non-existent node
- [ ] 11. Set value to null
- [ ] 12. Set value as complex object

## Tool: get_node_properties
- [ ] 1. Get properties of existing node (happy path)
- [ ] 2. Get properties of scene root
- [ ] 3. Get properties of nested node
- [ ] 4. Non-existent node
- [ ] 5. Missing required param path

## Tool: add_resource
- [ ] 1. Add material to Sprite2D (happy path)
- [ ] 2. Add resource with properties
- [ ] 3. Missing required param node_path
- [ ] 4. Missing required param resource_type
- [ ] 5. Invalid resource type
- [ ] 6. Non-existent node path
- [ ] 7. Empty properties

## Tool: set_anchor_preset
- [ ] 1. Set full_rect preset (happy path)
- [ ] 2. Known anchor preset values
- [ ] 3. Set preset on non-Control node
- [ ] 4. Unknown preset name
- [ ] 5. Missing required param path
- [ ] 6. Missing required param preset
- [ ] 7. Empty string preset

## Tool: rename_node
- [ ] 1. Rename a node (happy path)
- [ ] 2. Rename a nested node
- [ ] 3. Rename to same name
- [ ] 4. Rename to name with special characters
- [ ] 5. Non-existent source node
- [ ] 6. Missing required param path
- [ ] 7. Missing required param new_name
- [ ] 8. Empty new name

## Tool: connect_signal
- [ ] 1. Connect signal between two nodes (happy path)
- [ ] 2. Connect built-in signal
- [ ] 3. Non-existent source node
- [ ] 4. Non-existent target node
- [ ] 5. Non-existent signal
- [ ] 6. Missing required param source
- [ ] 7. Missing required param signal
- [ ] 8. Missing required param target
- [ ] 9. Missing required param method
- [ ] 10. Duplicate connection

## Tool: disconnect_signal
- [ ] 1. Disconnect an existing signal (happy path)
- [ ] 2. Disconnect non-existent connection
- [ ] 3. Disconnect from non-existent source
- [ ] 4. Missing required params

## Tool: get_node_groups
- [ ] 1. Get groups of node in groups (happy path)
- [ ] 2. Get groups of node with no groups
- [ ] 3. Get groups of scene root
- [ ] 4. Non-existent node
- [ ] 5. Missing required param path

## Tool: set_node_groups
- [ ] 1. Set groups on a node (happy path)
- [ ] 2. Set empty groups (clear all groups)
- [ ] 3. Set single group
- [ ] 4. Non-existent node
- [ ] 5. Missing required param path
- [ ] 6. Missing required param groups
- [ ] 7. Groups with special characters

## Tool: find_nodes_in_group
- [ ] 1. Find nodes in existing group (happy path)
- [ ] 2. Find nodes in empty group
- [ ] 3. Find nodes in non-existent group
- [ ] 4. Missing required param group
- [ ] 5. Empty string group name

## Tool: get_editor_selection
- [ ] 1. Get selection when nodes selected (happy path)
- [ ] 2. Get selection when nothing selected
- [ ] 3. Get selection with multiple nodes selected
- [ ] 4. Call with extra params

## Tool: select_nodes
- [ ] 1. Select a single node (happy path)
- [ ] 2. Select multiple nodes
- [ ] 3. Select nested node
- [ ] 4. Select empty array
- [ ] 5. Select non-existent node
- [ ] 6. Missing required param paths
- [ ] 7. Paths is not an array

## Tool: clear_editor_selection
- [ ] 1. Clear selection when nodes selected (happy path)
- [ ] 2. Clear selection when nothing selected
- [ ] 3. Call with extra params

