# scene_config — Test Execution Checklist
> See plan: [scene_config_test_plan.md](./scene_config_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `get_scene_inheritance`
- [ ] 1. Current scene (no params)
- [ ] 2. Explicit current scene (empty string)
- [ ] 3. Specific scene by path (res://)
- [ ] 4. Non-existent scene path
- [ ] 5. Non-scene file path
- [ ] 6. Invalid path format

## Tool: `set_scene_unique_name`
- [ ] 1. Enable unique name on child node
- [ ] 2. Enable unique name on scene root
- [ ] 3. Enable unique name on nested node
- [ ] 4. Explicitly disable unique name
- [ ] 5. Missing required node_path
- [ ] 6. Non-existent node path
- [ ] 7. Edge case: unique=true explicitly
- [ ] 8. Edge case: unique as string type
- [ ] 9. Re-enable after disable (toggle test)

## Tool: `get_scene_groups`
- [ ] 1. Current scene (no params)
- [ ] 2. Scene with known groups
- [ ] 3. Specific scene by path
- [ ] 4. Non-existent scene path
- [ ] 5. Non-scene file path

## Tool: `set_scene_group`
- [ ] 1. Add node to group (default add:true)
- [ ] 2. Add node to group (explicit add:true)
- [ ] 3. Remove node from group (add:false)
- [ ] 4. Add scene root to group
- [ ] 5. Add nested node to group
- [ ] 6. Add multiple nodes to same group
- [ ] 7. Missing required node_path
- [ ] 8. Missing required group
- [ ] 9. Missing both required params
- [ ] 10. Non-existent node path
- [ ] 11. Empty group name
- [ ] 12. Remove from group not joined
- [ ] 13. Idempotency: add to already-joined group
- [ ] 14. Edge case: add as string type
- [ ] 15. Edge case: very long group name

## Tool: `get_scene_meta`
- [ ] 1. Current scene, no metadata set
- [ ] 2. Current scene with metadata set
- [ ] 3. Specific scene by path
- [ ] 4. Non-existent scene path
- [ ] 5. Non-scene file path

## Tool: `set_scene_meta`
- [ ] 1. Set string metadata
- [ ] 2. Set number metadata
- [ ] 3. Set boolean metadata
- [ ] 4. Set array metadata
- [ ] 5. Set object/dict metadata
- [ ] 6. Set float metadata
- [ ] 7. Set null metadata
- [ ] 8. Overwrite existing metadata
- [ ] 9. Set metadata with empty string key
- [ ] 10. Missing required key
- [ ] 11. Missing required value
- [ ] 12. Missing both required params
- [ ] 13. Set metadata with special chars in key
- [ ] 14. Set metadata with very long key
- [ ] 15. Set metadata with very large value
- [ ] 16. Edge case: scene_path with non-current path

## Cross-Tool Integration Tests
- [ ] I. Add group, verify with get_scene_groups
- [ ] II. Set metadata, verify with get_scene_meta
- [ ] III. Unique name + group on same node
- [ ] IV. Full lifecycle: group remove then verify gone

