# scene — Test Execution Checklist
> See plan: [scene_test_plan.md](./scene_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: get_scene_tree
- [ ] 1. Default depth — return tree at default depth 15
- [ ] 2. Explicit depth 5 — tree truncated at depth 5
- [ ] 3. Explicit depth 1 — only root node returned
- [ ] 4. Large depth — full unfiltered tree at max_depth=9999
- [ ] 5. max_depth = 0 — validation error, must be > 0
- [ ] 6. Negative max_depth — validation error, must be positive
- [ ] 7. Non-integer max_depth — float 3.5 fails .int() validation
- [ ] 8. String max_depth — "five" fails type validation
- [ ] 9. No scene open — empty/null tree or error from Godot

## Tool: get_scene_file_content
- [ ] 1. Read valid scene — returns raw .tscn text contents
- [ ] 2. Missing path — validation error, path is required
- [ ] 3. Null path — validation error, expected string
- [ ] 4. Empty string path — Godot error, invalid file path
- [ ] 5. Non-existent file — Godot error, file not found
- [ ] 6. Path without res:// — may fail, verify plugin behavior
- [ ] 7. Absolute filesystem path — may fail, res:// expected
- [ ] 8. Non-scene file (.gd) — likely error or unexpected content
- [ ] 9. .scn extension — verify binary .scn file handling

## Tool: create_scene
- [ ] 1. Path only (default root) — scene with default root type
- [ ] 2. Node2D root — new 2D scene created
- [ ] 3. Control root — new UI scene created
- [ ] 4. Node3D root — new 3D scene created
- [ ] 5. Missing path — validation error, path is required
- [ ] 6. Empty string path — Godot error, cannot create at empty path
- [ ] 7. No .tscn extension — verify auto-append or rejection
- [ ] 8. Invalid root_node_type — Godot error, unknown node type
- [ ] 9. Overwrite existing scene — verify overwrite vs reject behavior
- [ ] 10. Special characters in path — should succeed with spaces
- [ ] 11. Nested directory path — verify auto-creation of intermediate dirs

## Tool: open_scene
- [ ] 1. Open existing scene — becomes active scene in editor
- [ ] 2. Missing path — validation error, path is required
- [ ] 3. Empty string path — Godot error, cannot open empty path
- [ ] 4. Non-existent file — Godot error, file not found
- [ ] 5. Non-scene file (.gd) — Godot error, not valid scene
- [ ] 6. Path without res:// — verify if relative paths resolve

## Tool: delete_scene
- [ ] 1. Delete without force — non-open scene file removed
- [ ] 2. Delete with force=true — scene deleted even if open
- [ ] 3. Delete with force=false — scene deleted since not open
- [ ] 4. Missing path — validation error, path is required
- [ ] 5. Non-existent file — Godot error, file not found
- [ ] 6. Delete open scene without force — Godot error, requires force
- [ ] 7. Delete open scene with force=true — scene closed then deleted
- [ ] 8. Force as non-boolean — validation error, expected boolean

## Tool: add_scene_instance
- [ ] 1. Instance at root (default parent) — added to scene root
- [ ] 2. Instance under named parent — added under specific node
- [ ] 3. Instance under nested parent — added under deep path
- [ ] 4. Empty parent_path (explicit root) — same as default, root
- [ ] 5. Missing scene_path — validation error, scene_path required
- [ ] 6. Non-existent scene file — Godot error, not found
- [ ] 7. Non-existent parent node — Godot error, parent not found
- [ ] 8. Self-reference — Godot error, cyclic instantiation
- [ ] 9. Not a scene file (.gd) — Godot error, not PackedScene

## Tool: play_scene
- [ ] 1. mode='main' — plays project main scene
- [ ] 2. mode='current' — plays currently open scene
- [ ] 3. mode='custom' — plays specified scene by path
- [ ] 4. No params — uses default play mode
- [ ] 5. mode='custom' without scene_path — runtime error from Godot
- [ ] 6. scene_path without mode='custom' — ignored or error
- [ ] 7. Invalid mode value — validation error from enum
- [ ] 8. Non-existent custom scene — Godot error, not found
- [ ] 9. Play when already playing — may error or restart
- [ ] 10. No main scene set (mode='main') — Godot error

## Tool: stop_scene
- [ ] 1. Stop running scene — scene stops, returns to edit mode
- [ ] 2. Stop when not playing — no-op or harmless warning
- [ ] 3. Extraneous params ignored — silently ignored or validation warning

## Tool: save_scene
- [ ] 1. Save current scene (no params) — saves to existing path
- [ ] 2. Save as new path — saved to new file path
- [ ] 3. Save as overwriting existing — succeeds or warns
- [ ] 4. Empty string path — Godot error, cannot save to empty
- [ ] 5. Invalid path format — Godot error, invalid path
- [ ] 6. No scene open — Godot error, no scene to save

## Tool: get_loaded_scenes
- [ ] 1. Single scene loaded — returns array with one entry
- [ ] 2. Multiple scenes loaded (additive) — array with multiple entries
- [ ] 3. No scenes loaded — empty array or null

## Tool: set_main_scene
- [ ] 1. Set main scene — project main scene updated
- [ ] 2. Missing path — validation error, path is required
- [ ] 3. Non-existent scene — Godot error, file not found
- [ ] 4. Non-scene file (.gd) — Godot error, not valid scene
- [ ] 5. Empty string path — Godot error, cannot set empty path

## Tool: get_main_scene
- [ ] 1. Main scene is set — returns main scene path
- [ ] 2. No main scene set — null, empty string, or error message

