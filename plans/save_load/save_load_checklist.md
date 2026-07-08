# save_load — Test Execution Checklist
> See plan: [save_load_test_plan.md](./save_load_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: save_game_state
- [ ] 1. Basic save to slot 0 with no metadata
- [ ] 2. Save with string metadata fields
- [ ] 3. Save with numeric metadata
- [ ] 4. Save with boolean metadata
- [ ] 5. Save with mixed-type metadata
- [ ] 6. Save with empty object metadata
- [ ] 7. Save to min slot (0)
- [ ] 8. Save to max slot (99)
- [ ] 9. Negative slot (-1) rejection
- [ ] 10. Slot 100 (exceeds max) rejection
- [ ] 11. Float slot (5.5) rejection
- [ ] 12. String slot rejection
- [ ] 13. Boolean slot rejection
- [ ] 14. Missing slot param rejection
- [ ] 15. Metadata with null values
- [ ] 16. Deeply nested metadata
- [ ] 17. Overwrite existing slot (save twice)
- [ ] 18. Call without running game

## Tool: load_game_state
- [ ] 1. Load from populated slot
- [ ] 2. Load from slot 99 (max boundary)
- [ ] 3. Load from slot 0 (min boundary)
- [ ] 4. Load from empty slot (no save data)
- [ ] 5. Load from deleted slot
- [ ] 6. Negative slot (-5) rejection
- [ ] 7. Slot 100 (exceeds max) rejection
- [ ] 8. Float slot (3.14) rejection
- [ ] 9. String slot rejection
- [ ] 10. Missing slot param rejection
- [ ] 11. Load state integrity verification
- [ ] 12. Call without running game

## Tool: list_save_files
- [ ] 1. List saves on empty state
- [ ] 2. List after single save
- [ ] 3. List after multiple saves to different slots
- [ ] 4. List after deleting one save
- [ ] 5. List after overwriting a slot
- [ ] 6. Call with unexpected extra params
- [ ] 7. Call without running game

## Tool: delete_save_file
- [ ] 1. Delete existing save
- [ ] 2. Delete from slot 0 (min boundary)
- [ ] 3. Delete from slot 99 (max boundary)
- [ ] 4. Delete non-existent slot
- [ ] 5. Double delete (idempotency)
- [ ] 6. Delete middle slot, verify others intact
- [ ] 7. Negative slot (-1) rejection
- [ ] 8. Slot 100 (exceeds max) rejection
- [ ] 9. Float slot (7.7) rejection
- [ ] 10. String slot rejection
- [ ] 11. Missing slot param rejection
- [ ] 12. Call without running game

## Tool: compare_save_states
- [ ] 1. Compare two identical saves
- [ ] 2. Compare two different saves
- [ ] 3. Compare with reversed slot order
- [ ] 4. Compare slot 0 and slot 99 (boundaries)
- [ ] 5. Missing save in slot_b
- [ ] 6. Both slots empty
- [ ] 7. Negative slot_a rejection
- [ ] 8. Slot_b exceeds max rejection
- [ ] 9. Float slot_a rejection
- [ ] 10. String slot_b rejection
- [ ] 11. Missing slot_b param rejection
- [ ] 12. Missing slot_a param rejection
- [ ] 13. Both params missing rejection
- [ ] 14. Compare same slot (slot_a == slot_b)
- [ ] 15. Call without running game

---

## Cross-Tool Integration Scenarios
- [ ] X1. Full save-list-load-delete lifecycle
- [ ] X2. Concurrent save slots isolation
- [ ] X3. Metadata evolution across saves

