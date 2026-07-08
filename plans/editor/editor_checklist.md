# editor — Test Execution Checklist
> See plan: [editor_test_plan.md](./editor_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `get_editor_errors`
- [ ] 1. No errors in scene — expect empty list
- [ ] 2. Scene with syntax error — expect error reported
- [ ] 3. Call twice in succession — expect identical results
- [ ] 4. Call with empty object — no required params

---

## Tool: `get_editor_screenshot`
- [ ] 1. Capture without path — expect base64 image
- [ ] 2. Capture with custom file path
- [ ] 3. Save to nested path
- [ ] 4. Path with .jpg extension
- [ ] 5. Non-res:// path — expect error
- [ ] 6. Path with trailing slash
- [ ] 7. Very long path (>260 chars) — expect error
- [ ] 8. Empty string path

---

## Tool: `get_game_screenshot`
- [ ] 1. Capture while game running — no path
- [ ] 2. Capture with custom path while game runs
- [ ] 3. Game NOT running — expect error
- [ ] 4. Capture during scene transition
- [ ] 5. Multiple screenshots in rapid succession
- [ ] 6. Invalid path edge cases

---

## Tool: `execute_editor_script`
- [ ] 1. Simple print statement
- [ ] 2. Script that returns a value
- [ ] 3. Access EditorInterface singleton
- [ ] 4. Read current editor selection
- [ ] 5. Multi-line script with variables
- [ ] 6. Script with class definition
- [ ] 7. Empty code string
- [ ] 8. Missing required parameter — expect error
- [ ] 9. Invalid GDScript — syntax error
- [ ] 10. Invalid GDScript — runtime error
- [ ] 11. Very long script (>10K chars)
- [ ] 12. Script with special characters/Unicode
- [ ] 13. Script with infinite loop — expect timeout

---

## Tool: `clear_output`
- [ ] 1. Clear after some output
- [ ] 2. Clear when already empty
- [ ] 3. Clear multiple times in succession
- [ ] 4. Call with no arguments

---

## Tool: `get_signals`
- [ ] 1. Inspect root-level node
- [ ] 2. Inspect nested node
- [ ] 3. Inspect scene root
- [ ] 4. Node with connected signals
- [ ] 5. Missing required parameter — expect error
- [ ] 6. Non-existent node path — expect error
- [ ] 7. Path with invalid characters
- [ ] 8. Very long node path
- [ ] 9. Node with custom signals

---

## Tool: `reload_plugin`
- [ ] 1. Reload plugins without error
- [ ] 2. Call twice in succession
- [ ] 3. Call when no plugins loaded

---

## Tool: `reload_project`
- [ ] 1. Reload project without error
- [ ] 2. Call twice in succession
- [ ] 3. Reload during script editing

---

## Tool: `get_output_log`
- [ ] 1. Read output log
- [ ] 2. Read immediately after clear_output
- [ ] 3. Read after generating error output
- [ ] 4. Read after multiple log types
- [ ] 5. Call with no arguments
- [ ] 6. Very large log — performance check

---

## Cross-Tool Integration
- [ ] A. Edit → Execute → Read Log → Clear sequence
- [ ] B. Get Signals → Execute Script → Get Signals
- [ ] C. Screenshot Before/After Editor Script
- [ ] D. Get Errors → Fix Script → Reload → Get Errors

