# runtime — Test Execution Checklist
> See plan: [runtime_test_plan.md](./runtime_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: get_game_scene_tree
- [ ] 1. Get scene tree while game is running
- [ ] 2. Verify error when game not running
- [ ] 3. Verify tree with only root node

## Tool: get_game_node_properties
- [ ] 1. Get default properties of root node
- [ ] 2. Get properties of named child node
- [ ] 3. Get properties of nested node
- [ ] 4. Get only specified properties
- [ ] 5. Empty property list
- [ ] 6. Error on non-existent node
- [ ] 7. Error on missing path param
- [ ] 8. Error on invalid path type

## Tool: set_game_node_property
- [ ] 1. Set a float property
- [ ] 2. Set a string property
- [ ] 3. Set a boolean property
- [ ] 4. Set a vector property
- [ ] 5. Set property on nested node
- [ ] 6. Error on read-only property
- [ ] 7. Error on non-existent node
- [ ] 8. Error on non-existent property
- [ ] 9. Error on missing path param
- [ ] 10. Error on missing property param
- [ ] 11. Set property to null

## Tool: execute_game_script
- [ ] 1. Execute simple print expression
- [ ] 2. Return evaluated value
- [ ] 3. Access autoload/engine API
- [ ] 4. Execute multi-line script
- [ ] 5. Modify game state via script
- [ ] 6. Error on GDScript syntax error
- [ ] 7. Error on runtime null access
- [ ] 8. Error on missing code param
- [ ] 9. Empty code string
- [ ] 10. Large script payload

## Tool: capture_frames
- [ ] 1. Capture single frame (default)
- [ ] 2. Capture 5 frames
- [ ] 3. Capture with 0.5s interval
- [ ] 4. Capture max 60 frames
- [ ] 5. Capture min 1 frame
- [ ] 6. Error on count=0
- [ ] 7. Error on count=61
- [ ] 8. Error on negative count
- [ ] 9. Error on non-integer count
- [ ] 10. Negative interval
- [ ] 11. Error on string count

## Tool: monitor_properties
- [ ] 1. Monitor single property
- [ ] 2. Monitor multiple properties
- [ ] 3. Monitor with 3s duration
- [ ] 4. Zero duration
- [ ] 5. Negative duration
- [ ] 6. Empty properties array
- [ ] 7. Error on non-existent node
- [ ] 8. Error on missing path
- [ ] 9. Error on missing properties
- [ ] 10. Non-existent property name

## Tool: start_recording
- [ ] 1. Start recording successfully
- [ ] 2. Double start recording
- [ ] 3. Error when game not running
- [ ] 4. Full record cycle

## Tool: stop_recording
- [ ] 1. Stop after recording started
- [ ] 2. Stop without prior start
- [ ] 3. Double stop recording
- [ ] 4. Stop after game stopped mid-record

## Tool: replay_recording
- [ ] 1. Replay at 1x speed
- [ ] 2. Replay at 2x speed
- [ ] 3. Replay at 0.5x slow-mo
- [ ] 4. Replay at 5x speed
- [ ] 5. Replay at 0.1x crawl
- [ ] 6. Error on zero speed
- [ ] 7. Error on negative speed
- [ ] 8. Error on string speed
- [ ] 9. Error: no recording available

## Tool: find_nodes_by_script
- [ ] 1. Find nodes using a script
- [ ] 2. No matches returns empty array
- [ ] 3. Non-existent script path
- [ ] 4. Invalid absolute OS path
- [ ] 5. Error on missing script_path
- [ ] 6. Path missing res:// prefix

## Tool: get_autoload
- [ ] 1. Get mcp_runtime autoload
- [ ] 2. Get GameManager autoload
- [ ] 3. Error on non-existent autoload
- [ ] 4. Empty string name
- [ ] 5. Error on missing name
- [ ] 6. Case-sensitive name check

## Tool: batch_get_properties
- [ ] 1. Single node, single property
- [ ] 2. Multiple nodes, multiple properties
- [ ] 3. Empty paths array
- [ ] 4. Empty properties array
- [ ] 5. Non-existent node in paths
- [ ] 6. 50 nodes batch
- [ ] 7. Error on missing paths
- [ ] 8. Error on missing properties
- [ ] 9. Error on non-array paths

## Tool: find_ui_elements
- [ ] 1. Find all UI elements
- [ ] 2. Filter by Button type
- [ ] 3. Filter by Label type
- [ ] 4. Filter by text content
- [ ] 5. Combined type+text filter
- [ ] 6. Empty filter object
- [ ] 7. Non-existent control type
- [ ] 8. No text matches
- [ ] 9. Unsupported filter keys
- [ ] 10. Error on non-object filter

## Tool: click_button_by_text
- [ ] 1. Click button by text
- [ ] 2. Click with 5s timeout
- [ ] 3. Button text not found
- [ ] 4. Empty text string
- [ ] 5. Zero timeout
- [ ] 6. Negative timeout
- [ ] 7. 300s timeout
- [ ] 8. Error on missing text
- [ ] 9. Case-sensitive text match

## Tool: wait_for_node
- [ ] 1. Node already exists
- [ ] 2. Wait for spawned node
- [ ] 3. Timeout on never-appearing node
- [ ] 4. Default 5s timeout
- [ ] 5. Wait for root node
- [ ] 6. Zero timeout
- [ ] 7. Negative timeout
- [ ] 8. Error on missing path
- [ ] 9. Wait for nested path
- [ ] 10. Error on string timeout

## Tool: find_nearby_nodes
- [ ] 1. Find nodes near origin
- [ ] 2. Large radius finds all nodes
- [ ] 3. No nodes at far position
- [ ] 4. Error on zero radius
- [ ] 5. Error on negative radius
- [ ] 6. Floating-point coordinates
- [ ] 7. Error on missing position
- [ ] 8. Error on missing radius
- [ ] 9. Wrong position length (2)
- [ ] 10. Wrong position length (4)
- [ ] 11. Error on string in position

## Tool: navigate_to
- [ ] 1. Navigate agent to target
- [ ] 2. Navigate to distant target
- [ ] 3. Navigate to current position
- [ ] 4. Error: missing NavigationAgent3D
- [ ] 5. Error on non-existent node
- [ ] 6. Unreachable target
- [ ] 7. Error on missing path
- [ ] 8. Error on missing target
- [ ] 9. Wrong target length
- [ ] 10. Error on string target
- [ ] 11. Empty path (root)

## Tool: move_to
- [ ] 1. Teleport to target position
- [ ] 2. Move to current position
- [ ] 3. Negative coordinates
- [ ] 4. Large coordinate values
- [ ] 5. Floating-point precision
- [ ] 6. Error on non-existent node
- [ ] 7. Error on missing path
- [ ] 8. Error on missing target
- [ ] 9. Wrong target length (2)
- [ ] 10. Wrong target length (4)
- [ ] 11. Empty path (root)

## Tool: watch_signals
- [ ] 1. Watch single signal
- [ ] 2. Watch multiple signals
- [ ] 3. Active signal during watch
- [ ] 4. No signal emissions
- [ ] 5. Default duration
- [ ] 6. Zero duration
- [ ] 7. Negative duration
- [ ] 8. Empty signals array
- [ ] 9. Error on non-existent node
- [ ] 10. Non-existent signal name
- [ ] 11. Error on missing path
- [ ] 12. Error on missing signals
- [ ] 13. Error on non-array signals

