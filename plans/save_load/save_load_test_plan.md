# Save/Load Test Plan

> **Source file:** `server/src/tools/save_load.ts`  
> **Shared types:** `server/src/tools/shared-types.ts`  
> **Tools covered:** 5 (`save_game_state`, `load_game_state`, `list_save_files`, `delete_save_file`, `compare_save_states`)  
> **Generated:** 2026-07-08

---

## Schema Details

### Shared Imports

| Import | Zod Schema | Description |
|--------|-----------|-------------|
| `z` | Zod namespace | Used directly for `z.number().int().min(0).max(99)` |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | Optional metadata key-value pairs, any values accepted |

### Parameter Summary

| Tool | Param | Type | Required | Default | Enum/Choices | Notes |
|------|-------|------|----------|---------|--------------|-------|
| `save_game_state` | `slot` | `integer` | ✅ yes | — | 0–99 inclusive | Save slot number |
| | `metadata` | `record<string, unknown>` | no | — | — | Optional key-value metadata (e.g. player name, level, timestamp) |
| `load_game_state` | `slot` | `integer` | ✅ yes | — | 0–99 inclusive | Save slot number to load from |
| `list_save_files` | *(none)* | — | — | — | — | Takes no input |
| `delete_save_file` | `slot` | `integer` | ✅ yes | — | 0–99 inclusive | Save slot number to delete |
| `compare_save_states` | `slot_a` | `integer` | ✅ yes | — | 0–99 inclusive | First save slot to compare |
| | `slot_b` | `integer` | ✅ yes | — | 0–99 inclusive | Second save slot to compare |

### Slot Constraints

All `slot` parameters share identical validation:
- **Type:** `number`
- **Integer only:** yes (`.int()`)
- **Minimum:** 0 (`.min(0)`)
- **Maximum:** 99 (`.max(99)`)

---

## Tool: save_game_state

### Schema

```typescript
{
  description: 'Save the current game state to a numbered slot with optional metadata',
  inputSchema: {
    slot: z.number().int().min(0).max(99).describe('Save slot number (0-99)'),
    metadata: OptionalProperties.describe('Optional metadata to store with the save (e.g. player name, level, timestamp)'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'save_game_state', args as Record<string, unknown>)
```

### Tool Behavior
Saves the current game state to a numbered save slot (0–99). If `metadata` is provided, it is stored alongside the save data. The game must be running for this tool to function. The Godot plugin persists the state and returns a confirmation or the saved slot information.

### ⚠️ Runtime Requirement
The game must be running (via `play_scene`) before any save/load tools work. All scenarios in this plan assume the game is running unless otherwise stated.

### Test Scenarios

#### Scenario 1: Basic happy path — save to a mid-range slot with no metadata
- **Description:** Save the current game state to slot 0 with no metadata.
- **Params:** `{ "slot": 0 }`
- **Expected result:** Success — returns a confirmation indicating the state was saved to slot 0. The save should be retrievable via `load_game_state` or `list_save_files`.
- **Notes:** Slot 0 is the lowest valid slot. Should succeed on any running game.

#### Scenario 2: Happy path — save with string metadata fields
- **Description:** Save to slot 42 with player name and level metadata.
- **Params:** `{ "slot": 42, "metadata": { "player_name": "TestPlayer", "level": "Forest", "timestamp": "2026-07-08T12:00:00Z" } }`
- **Expected result:** Success — returns confirmation with slot 42. Metadata should be persisted and retrievable via `list_save_files`.
- **Notes:** All metadata values are strings here. Tests string serialization.

#### Scenario 3: Happy path — save with numeric metadata
- **Description:** Save to slot 10 with numeric values in metadata.
- **Params:** `{ "slot": 10, "metadata": { "score": 9500, "lives": 3, "level_num": 7 } }`
- **Expected result:** Success — numeric metadata should be preserved when round-tripped.
- **Notes:** Tests that `z.record(z.unknown())` correctly passes numeric values through.

#### Scenario 4: Happy path — save with boolean metadata
- **Description:** Save to slot 25 with boolean flags in metadata.
- **Params:** `{ "slot": 25, "metadata": { "has_boss_key": true, "night_mode": false, "completed": true } }`
- **Expected result:** Success — boolean values should be preserved.
- **Notes:** Tests boolean serialization in the metadata record.

#### Scenario 5: Happy path — save with mixed-type metadata
- **Description:** Save to slot 50 with mixed string, number, and boolean metadata.
- **Params:** `{ "slot": 50, "metadata": { "player": "Hero", "hp": 100, "max_hp": 150, "is_alive": true, "inventory": ["sword", "shield"] } }`
- **Expected result:** Success — the full mixed-type metadata should round-trip.
- **Notes:** Includes an array value. Tests complex metadata structures.

#### Scenario 6: Happy path — save with empty object metadata
- **Description:** Save to slot 1 with an empty metadata object.
- **Params:** `{ "slot": 1, "metadata": {} }`
- **Expected result:** Success — saves without any custom metadata. Should behave identically to omitting metadata entirely.
- **Notes:** Edge case: empty metadata object vs no metadata key.

#### Scenario 7: Slot boundaries — minimum slot (0)
- **Description:** Save to slot 0 (the lowest valid slot).
- **Params:** `{ "slot": 0 }`
- **Expected result:** Success — slot 0 should be accepted and writable.
- **Notes:** Slot 0 inclusive per `.min(0)`.

#### Scenario 8: Slot boundaries — maximum slot (99)
- **Description:** Save to slot 99 (the highest valid slot).
- **Params:** `{ "slot": 99 }`
- **Expected result:** Success — slot 99 should be accepted and writable.
- **Notes:** Slot 99 inclusive per `.max(99)`.

#### Scenario 9: Slot boundaries — negative slot (-1)
- **Description:** Attempt to save with a negative slot value.
- **Params:** `{ "slot": -1 }`
- **Expected result:** Validation error — Zod rejects `-1` as it is below `.min(0)`. Error message should indicate the value is out of range.
- **Notes:** Tests Zod integer range validation on the lower bound.

#### Scenario 10: Slot boundaries — slot 100 (exceeds max)
- **Description:** Attempt to save with slot 100.
- **Params:** `{ "slot": 100 }`
- **Expected result:** Validation error — Zod rejects `100` as it exceeds `.max(99)`. Error message should indicate the value is out of range.
- **Notes:** Tests Zod integer range validation on the upper bound.

#### Scenario 11: Invalid slot type — float/non-integer
- **Description:** Attempt to save with a floating-point slot (e.g. 5.5).
- **Params:** `{ "slot": 5.5 }`
- **Expected result:** Validation error — Zod rejects `5.5` because `.int()` requires an integer.
- **Notes:** Tests the `.int()` constraint on the slot parameter.

#### Scenario 12: Invalid slot type — string
- **Description:** Attempt to save with a string slot value.
- **Params:** `{ "slot": "abc" }`
- **Expected result:** Validation error — Zod rejects a string where a number is expected.
- **Notes:** Tests type validation on the slot parameter.

#### Scenario 13: Invalid slot type — boolean
- **Description:** Attempt to save with a boolean slot value.
- **Params:** `{ "slot": true }`
- **Expected result:** Validation error — Zod rejects a boolean where a number is expected.
- **Notes:** Tests type validation on the slot parameter.

#### Scenario 14: Missing required parameter — no slot
- **Description:** Call `save_game_state` without the required `slot` parameter.
- **Params:** `{}`
- **Expected result:** Validation error — Zod requires `slot`. Error message should indicate a missing required field.
- **Notes:** Tests that required parameters are enforced.

#### Scenario 15: Metadata with null values
- **Description:** Save with metadata containing null values.
- **Params:** `{ "slot": 30, "metadata": { "key1": null, "key2": "valid" } }`
- **Expected result:** Should succeed — `z.unknown()` accepts null. Whether nulls persist depends on Godot's JSON serialization (may strip nulls).
- **Notes:** Tests null handling in metadata. Behavior may be Godot-version-dependent.

#### Scenario 16: Save with deeply nested metadata
- **Description:** Save with nested object metadata.
- **Params:** `{ "slot": 60, "metadata": { "stats": { "strength": 18, "agility": 12 }, "position": { "x": 100, "y": 200, "z": 0 } } }`
- **Expected result:** Success — nested objects should be serialized and preserved.
- **Notes:** Tests nested object serialization, which exercises the full `z.record(z.unknown())` flexibility.

#### Scenario 17: Overwrite existing slot — save to same slot twice
- **Description:** Save to slot 5 twice in succession, checking that the second save overwrites the first.
- **Params (step 1):** `{ "slot": 5, "metadata": { "version": "v1" } }`  
  **Params (step 2):** `{ "slot": 5, "metadata": { "version": "v2" } }`
- **Expected result:** Both calls succeed. After step 2, `list_save_files` should show slot 5 with metadata `{ "version": "v2" }`. The first save should be overwritten.
- **Notes:** Tests idempotency and overwrite behavior on save slots.

#### Scenario 18: Runtime requirement — call without running game
- **Description:** Call `save_game_state` when no game is running.
- **Params:** `{ "slot": 0 }`
- **Expected result:** Error from Godot — should return an error indicating the game is not running or the runtime autoload is unavailable.
- **Notes:** Validates that the tool correctly surfaces engine-level errors.

---

## Tool: load_game_state

### Schema

```typescript
{
  description: 'Load a game state from a numbered save slot',
  inputSchema: {
    slot: z.number().int().min(0).max(99).describe('Save slot number to load (0-99)'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'load_game_state', args as Record<string, unknown>)
```

### Tool Behavior
Loads a previously saved game state from a numbered save slot (0–99). The game must be running. After a successful load, the game's state should match what was saved. Returns confirmation or the loaded state data.

### ⚠️ Runtime Requirement
The game must be running (via `play_scene`) before this tool works.

### Test Scenarios

#### Scenario 1: Basic happy path — load from a populated slot
- **Description:** First save to slot 0 with known metadata, then load from slot 0.
- **Params:** `{ "slot": 0 }`
- **Expected result:** Success — returns the loaded save data. The game state should be restored to what was saved. Verify via `get_game_node_properties` that state matches expectations.
- **Notes:** Requires a prior `save_game_state` call to set up the save data.

#### Scenario 2: Happy path — load from slot 99 (max boundary)
- **Description:** Save to slot 99, then load from slot 99.
- **Params:** `{ "slot": 99 }`
- **Expected result:** Success — state loaded correctly from slot 99.
- **Notes:** Tests the upper boundary of valid slots for loading.

#### Scenario 3: Happy path — load from slot 0 (min boundary)
- **Description:** Save to slot 0, then load from slot 0.
- **Params:** `{ "slot": 0 }`
- **Expected result:** Success — state loaded correctly from slot 0.
- **Notes:** Tests the lower boundary of valid slots for loading.

#### Scenario 4: Empty slot — load from a slot that has no save data
- **Description:** Attempt to load from slot 77 which has never been saved to.
- **Params:** `{ "slot": 77 }`
- **Expected result:** Error — Godot should return an error indicating no save file exists in slot 77 (e.g. "Save file not found" or equivalent).
- **Notes:** Tests the error path when no data exists. Important for client-side error handling.

#### Scenario 5: Deleted slot — load from a slot that was saved to then deleted
- **Description:** Save to slot 3, delete slot 3 via `delete_save_file`, then attempt to load from slot 3.
- **Params:** `{ "slot": 3 }`
- **Expected result:** Error — should indicate the save file no longer exists. Same as Scenario 4 (empty slot).
- **Notes:** Validates that deletion actually removes save data by confirming a load fails after deletion.

#### Scenario 6: Slot validation — negative slot (-5)
- **Description:** Attempt to load with a negative slot value.
- **Params:** `{ "slot": -5 }`
- **Expected result:** Validation error — Zod rejects `-5` as it is below `.min(0)`.
- **Notes:** Tests Zod integer range validation.

#### Scenario 7: Slot validation — slot 100 (exceeds max)
- **Description:** Attempt to load with slot 100.
- **Params:** `{ "slot": 100 }`
- **Expected result:** Validation error — Zod rejects `100` as it exceeds `.max(99)`.
- **Notes:** Tests Zod integer range validation.

#### Scenario 8: Slot validation — non-integer float (3.14)
- **Description:** Attempt to load with a floating-point slot.
- **Params:** `{ "slot": 3.14 }`
- **Expected result:** Validation error — Zod rejects non-integer via `.int()`.
- **Notes:** Tests the `.int()` constraint.

#### Scenario 9: Slot validation — string "five"
- **Description:** Attempt to load with a string slot value.
- **Params:** `{ "slot": "five" }`
- **Expected result:** Validation error — Zod rejects string for number field.
- **Notes:** Tests type validation.

#### Scenario 10: Missing required parameter — no slot
- **Description:** Call `load_game_state` without the `slot` parameter.
- **Params:** `{}`
- **Expected result:** Validation error — missing required field.
- **Notes:** Tests required parameter enforcement.

#### Scenario 11: Load state integrity — verify loaded properties match saved metadata
- **Description:** Save game state with specific metadata (e.g. `{ "test_key": "test_value" }`) to slot 20, modify game state, then load slot 20 and verify metadata is restored.
- **Params (save):** `{ "slot": 20, "metadata": { "test_key": "test_value" } }`  
  **Params (load):** `{ "slot": 20 }`
- **Expected result:** After load, `list_save_files` should show slot 20 with metadata `{ "test_key": "test_value" }`.
- **Notes:** End-to-end integrity test of save → modify → load → verify cycle.

#### Scenario 12: Runtime requirement — call without running game
- **Description:** Call `load_game_state` when no game is running.
- **Params:** `{ "slot": 0 }`
- **Expected result:** Error — should indicate the game is not running.
- **Notes:** Validates the runtime guard.

---

## Tool: list_save_files

### Schema

```typescript
{
  description: 'List all save files with their metadata',
  inputSchema: {},
}
```

### Handler

```typescript
async () => callGodot(bridge, 'list_save_files')
```

### Tool Behavior
Lists all save files currently present in the save system, including their metadata (slot number, timestamp, any custom metadata). Takes no parameters. The game must be running.

### ⚠️ Runtime Requirement
The game must be running (via `play_scene`) before this tool works.

### Test Scenarios

#### Scenario 1: Basic happy path — list saves on empty save state
- **Description:** Call `list_save_files` after starting the game but before any saves have been made.
- **Params:** `{}`
- **Expected result:** Success — returns an empty array `[]` or an object indicating no saves exist. Should not error.
- **Notes:** Validates the tool works with no prior saves.

#### Scenario 2: List saves after a single save
- **Description:** Save to slot 5 with metadata, then call `list_save_files`.
- **Params:** `{}`
- **Expected result:** Returns an array/object containing exactly one entry for slot 5 with the saved metadata. The entry should include at minimum the slot number and metadata.
- **Notes:** Validates that a single save appears correctly in the listing.

#### Scenario 3: List saves after multiple saves to different slots
- **Description:** Save to slots 0, 25, 50, 75, 99 with distinct metadata, then call `list_save_files`.
- **Params:** `{}`
- **Expected result:** Returns a list containing entries for all five slots (0, 25, 50, 75, 99). Each entry should be associated with its correct slot and unique metadata.
- **Notes:** Validates multi-slot listing. Use distinct metadata per slot (e.g. `{ "slot_id": 0 }`, `{ "slot_id": 25 }`, etc.) to verify correct association.

#### Scenario 4: List saves after deleting one — remaining slots still listed
- **Description:** Save to slots 1, 2, and 3. Delete slot 2, then list saves.
- **Params:** `{}`
- **Expected result:** Returns entries for slots 1 and 3 only. Slot 2 should be absent from the listing.
- **Notes:** Validates that `list_save_files` correctly reflects deletions.

#### Scenario 5: List saves after overwriting a slot
- **Description:** Save to slot 10 with metadata `{ "version": 1 }`, then save to slot 10 again with metadata `{ "version": 2 }`, then list saves.
- **Params:** `{}`
- **Expected result:** Only one entry for slot 10 should appear, with metadata `{ "version": 2 }`. No duplicate entries for the same slot.
- **Notes:** Validates that overwrites are reflected correctly — one entry per slot.

#### Scenario 6: Call with unexpected extra params
- **Description:** Call `list_save_files` with extraneous parameters since `inputSchema` is empty.
- **Params:** `{ "foo": "bar", "unused": 42 }`
- **Expected result:** Should succeed identically to Scenario 1. Extraneous params are ignored by Zod on an empty schema.
- **Notes:** Tests robustness against clients that may send extra fields.

#### Scenario 7: Runtime requirement — call without running game
- **Description:** Call `list_save_files` when no game is running.
- **Params:** `{}`
- **Expected result:** Error — should indicate the game is not running.
- **Notes:** Validates the runtime guard.

---

## Tool: delete_save_file

### Schema

```typescript
{
  description: 'Delete a save file from a specific slot',
  inputSchema: {
    slot: z.number().int().min(0).max(99).describe('Save slot number to delete (0-99)'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'delete_save_file', args as Record<string, unknown>)
```

### Tool Behavior
Deletes the save file at the specified slot (0–99). After deletion, the slot should no longer appear in `list_save_files` and loading from that slot should fail. The game must be running.

### ⚠️ Runtime Requirement
The game must be running (via `play_scene`) before this tool works.

### Test Scenarios

#### Scenario 1: Basic happy path — delete an existing save
- **Description:** Save to slot 5, verify via `list_save_files`, then delete slot 5.
- **Params:** `{ "slot": 5 }`
- **Expected result:** Success — returns confirmation that the save was deleted. Subsequent `list_save_files` should not include slot 5. Subsequent `load_game_state` for slot 5 should fail.
- **Notes:** Standard delete flow.

#### Scenario 2: Happy path — delete from slot 0 (min boundary)
- **Description:** Save to slot 0, then delete slot 0.
- **Params:** `{ "slot": 0 }`
- **Expected result:** Success — slot 0 save is deleted.
- **Notes:** Tests the lower boundary for deletion.

#### Scenario 3: Happy path — delete from slot 99 (max boundary)
- **Description:** Save to slot 99, then delete slot 99.
- **Params:** `{ "slot": 99 }`
- **Expected result:** Success — slot 99 save is deleted.
- **Notes:** Tests the upper boundary for deletion.

#### Scenario 4: Delete non-existent slot — slot was never saved to
- **Description:** Attempt to delete slot 77 which has no save data.
- **Params:** `{ "slot": 77 }`
- **Expected result:** Depends on Godot implementation — may succeed silently (idempotent delete), return success with a note that nothing was deleted, or return an error. Document the actual behavior.
- **Notes:** Tests the tool's behavior on missing saves. Important for understanding idempotency guarantees.

#### Scenario 5: Delete already-deleted slot — double delete
- **Description:** Save to slot 3, delete slot 3, then delete slot 3 again.
- **Params (both calls):** `{ "slot": 3 }`
- **Expected result:** First call succeeds (deletion). Second call should either succeed silently (idempotent) or return a specific error. Document which behavior is observed.
- **Notes:** Tests idempotency of the delete operation.

#### Scenario 6: Delete middle slot — verify other slots unaffected
- **Description:** Save to slots 1, 2, 3 with distinct metadata. Delete slot 2, then list saves.
- **Params:** `{ "slot": 2 }`
- **Expected result:** Success (slot 2 deleted). `list_save_files` should still show slots 1 and 3 with their metadata intact.
- **Notes:** Validates that deletion is slot-specific and doesn't affect adjacent slots.

#### Scenario 7: Slot validation — negative slot (-1)
- **Description:** Attempt to delete with a negative slot value.
- **Params:** `{ "slot": -1 }`
- **Expected result:** Validation error — Zod rejects `-1` below `.min(0)`.
- **Notes:** Tests Zod integer range validation.

#### Scenario 8: Slot validation — slot 100 (exceeds max)
- **Description:** Attempt to delete with slot 100.
- **Params:** `{ "slot": 100 }`
- **Expected result:** Validation error — Zod rejects `100` above `.max(99)`.
- **Notes:** Tests Zod integer range validation.

#### Scenario 9: Slot validation — non-integer float (7.7)
- **Description:** Attempt to delete with a floating-point slot.
- **Params:** `{ "slot": 7.7 }`
- **Expected result:** Validation error — Zod rejects non-integer via `.int()`.
- **Notes:** Tests the `.int()` constraint.

#### Scenario 10: Slot validation — string type
- **Description:** Attempt to delete with a string slot value.
- **Params:** `{ "slot": "slot_5" }`
- **Expected result:** Validation error — Zod rejects string for number field.
- **Notes:** Tests type validation.

#### Scenario 11: Missing required parameter — no slot
- **Description:** Call `delete_save_file` without the `slot` parameter.
- **Params:** `{}`
- **Expected result:** Validation error — missing required field.
- **Notes:** Tests required parameter enforcement.

#### Scenario 12: Runtime requirement — call without running game
- **Description:** Call `delete_save_file` when no game is running.
- **Params:** `{ "slot": 0 }`
- **Expected result:** Error — should indicate the game is not running.
- **Notes:** Validates the runtime guard.

---

## Tool: compare_save_states

### Schema

```typescript
{
  description: 'Compare two save states and return a diff of their contents',
  inputSchema: {
    slot_a: z.number().int().min(0).max(99).describe('First save slot to compare (0-99)'),
    slot_b: z.number().int().min(0).max(99).describe('Second save slot to compare (0-99)'),
  },
}
```

### Handler

```typescript
async (args) => callGodot(bridge, 'compare_save_states', args as Record<string, unknown>)
```

### Tool Behavior
Compares the save states in two slots and returns a diff of their contents. This is useful for verifying that game state changes are properly captured across saves. The diff format depends on the Godot implementation. Both slots must contain valid save data. The game must be running.

### ⚠️ Runtime Requirement
The game must be running (via `play_scene`) before this tool works.

### Test Scenarios

#### Scenario 1: Basic happy path — compare two identical saves
- **Description:** Save the same game state to slot 10 and slot 11 without changing anything in between, then compare them.
- **Params:** `{ "slot_a": 10, "slot_b": 11 }`
- **Expected result:** Success — returns a diff indicating the two save states are identical (empty diff, or a message like "no differences found").
- **Notes:** Tests the comparison tool with identical data.

#### Scenario 2: Happy path — compare two different saves
- **Description:** Save initial state to slot 10. Modify the game state (e.g., move a node, change a property). Save the modified state to slot 11. Compare slot 10 and slot 11.
- **Params:** `{ "slot_a": 10, "slot_b": 11 }`
- **Expected result:** Success — returns a diff showing the differences between the two save states. The differences should correspond to the modifications made between saves.
- **Notes:** The diff format depends on Godot's implementation. At minimum, the tool should indicate that differences exist.

#### Scenario 3: Happy path — compare with reversed slot order
- **Description:** Same setup as Scenario 2, but swap `slot_a` and `slot_b`.
- **Params:** `{ "slot_a": 11, "slot_b": 10 }`
- **Expected result:** Success — should return the same differences as Scenario 2 (possibly with inverted direction). The tool should handle the order symmetrically.
- **Notes:** Tests that the comparison is direction-agnostic or correctly indicates direction.

#### Scenario 4: Slot boundaries — slot 0 and slot 99
- **Description:** Save to slot 0 and slot 99 with different states, then compare.
- **Params:** `{ "slot_a": 0, "slot_b": 99 }`
- **Expected result:** Success — comparison works across the full slot range.
- **Notes:** Tests boundary values for both parameters simultaneously.

#### Scenario 5: Missing save — slot_a has no save data
- **Description:** Save to slot 20, then compare slot 20 with slot 21 (which has no save).
- **Params:** `{ "slot_a": 20, "slot_b": 21 }`
- **Expected result:** Error — should indicate that no save file exists in slot 21 (or both slots must have data).
- **Notes:** Tests error handling when one side of the comparison is missing.

#### Scenario 6: Missing save — both slots empty
- **Description:** Compare two slots that have never been saved to.
- **Params:** `{ "slot_a": 88, "slot_b": 89 }`
- **Expected result:** Error — should indicate that no save files exist in either slot.
- **Notes:** Tests error handling when both sides are missing.

#### Scenario 7: Slot validation — negative slot_a
- **Description:** Attempt to compare with a negative `slot_a`.
- **Params:** `{ "slot_a": -1, "slot_b": 5 }`
- **Expected result:** Validation error — Zod rejects `-1` below `.min(0)`.
- **Notes:** Tests Zod integer range validation on `slot_a`.

#### Scenario 8: Slot validation — slot_b exceeds max
- **Description:** Attempt to compare with `slot_b` = 100.
- **Params:** `{ "slot_a": 0, "slot_b": 100 }`
- **Expected result:** Validation error — Zod rejects `100` above `.max(99)`.
- **Notes:** Tests Zod integer range validation on `slot_b`.

#### Scenario 9: Slot validation — non-integer slot_a (float)
- **Description:** Attempt to compare with a floating-point `slot_a`.
- **Params:** `{ "slot_a": 5.5, "slot_b": 10 }`
- **Expected result:** Validation error — Zod rejects non-integer via `.int()`.
- **Notes:** Tests the `.int()` constraint on `slot_a`.

#### Scenario 10: Slot validation — string slot_b
- **Description:** Attempt to compare with a string `slot_b`.
- **Params:** `{ "slot_a": 0, "slot_b": "ten" }`
- **Expected result:** Validation error — Zod rejects string for number field.
- **Notes:** Tests type validation on `slot_b`.

#### Scenario 11: Missing required parameter — only slot_a
- **Description:** Call `compare_save_states` with only `slot_a` (missing `slot_b`).
- **Params:** `{ "slot_a": 5 }`
- **Expected result:** Validation error — missing required field `slot_b`.
- **Notes:** Tests required parameter enforcement.

#### Scenario 12: Missing required parameter — only slot_b
- **Description:** Call `compare_save_states` with only `slot_b` (missing `slot_a`).
- **Params:** `{ "slot_b": 5 }`
- **Expected result:** Validation error — missing required field `slot_a`.
- **Notes:** Tests required parameter enforcement.

#### Scenario 13: Missing required parameters — empty params
- **Description:** Call `compare_save_states` with no parameters.
- **Params:** `{}`
- **Expected result:** Validation error — both required fields missing.
- **Notes:** Tests that both required parameters are enforced.

#### Scenario 14: Compare same slot — slot_a == slot_b
- **Description:** Save to slot 15, then compare slot 15 with itself.
- **Params:** `{ "slot_a": 15, "slot_b": 15 }`
- **Expected result:** Success — should return an empty/diff indicating no differences (same data).
- **Notes:** Edge case: comparing a slot to itself. Should degrade gracefully.

#### Scenario 15: Runtime requirement — call without running game
- **Description:** Call `compare_save_states` when no game is running.
- **Params:** `{ "slot_a": 0, "slot_b": 1 }`
- **Expected result:** Error — should indicate the game is not running.
- **Notes:** Validates the runtime guard.

---

## Cross-Tool Integration Scenarios

These scenarios test how multiple save/load tools interact in real workflows.

### Scenario X1: Full save-list-load-delete lifecycle
1. **Start game** — `play_scene`
2. **List saves** (`list_save_files`) → expect empty
3. **Save** (`save_game_state`) to slot 5 with `{ "phase": 1 }`
4. **List saves** → expect slot 5 with `{ "phase": 1 }`
5. **Save** (`save_game_state`) to slot 10 with `{ "phase": 2 }`
6. **List saves** → expect slots 5 and 10 with correct metadata
7. **Compare** (`compare_save_states`) slot 5 vs slot 10 → expect diff (different metadata)
8. **Load** (`load_game_state`) slot 10 → success
9. **Delete** (`delete_save_file`) slot 5 → success
10. **List saves** → expect only slot 10
11. **Load** (`load_game_state`) slot 5 → expect error (deleted)
12. **Compare** (`compare_save_states`) slot 5 vs slot 10 → expect error (slot 5 missing)
13. **Delete** (`delete_save_file`) slot 10 → success
14. **List saves** → expect empty
- **Expected result:** All steps should succeed/error as indicated, demonstrating full lifecycle integrity.

### Scenario X2: Concurrent save slots isolation
1. **Save** to slots 0, 25, 50, 75, 99 with distinct metadata `{ "slot_marker": 0 }` etc.
2. **List saves** → all 5 slots present
3. **Delete** slot 50
4. **List saves** → slots 0, 25, 75, 99 remain; slot 50 absent
5. **Load** slot 25 → verify metadata is `{ "slot_marker": 25 }`
6. **Load** slot 75 → verify metadata is `{ "slot_marker": 75 }`
7. **Compare** slot 25 vs slot 75 → expect diff
- **Expected result:** Slots are fully isolated. Deletion of one slot does not affect others.

### Scenario X3: Metadata evolution across saves
1. **Save** to slot 1 with `{ "version": "1.0", "data": { "hp": 100, "score": 0 } }`
2. **Load** slot 1, modify game (increase score, decrease HP), **Save** to slot 2 with `{ "version": "1.0", "data": { "hp": 85, "score": 150 } }`
3. **Compare** slot 1 vs slot 2 → expect diff showing changed HP and score
4. **Load** slot 2, modify game further, **Save** to slot 3 with `{ "version": "1.0", "data": { "hp": 50, "score": 300 } }`
5. **Compare** slot 1 vs slot 3 → expect larger diff than slot 1 vs slot 2
6. **Compare** slot 2 vs slot 3 → expect diff showing further HP/score changes
- **Expected result:** Each comparison correctly reflects the cumulative changes. Diffs should be consistent (slot1→slot3 diff should be the sum of slot1→slot2 + slot2→slot3 diffs).

---

## Validation Error Reference

For all tools, the following Zod validation errors should be returned for invalid inputs:

| Condition | Expected Error |
|-----------|---------------|
| Missing required `slot` (or `slot_a`/`slot_b`) | Zod validation error: "Required" |
| `slot` < 0 | Zod validation error: "Number must be greater than or equal to 0" |
| `slot` > 99 | Zod validation error: "Number must be less than or equal to 99" |
| `slot` not an integer (float) | Zod validation error: "Expected integer, received float" |
| `slot` wrong type (string/boolean/object) | Zod validation error: "Expected number, received [type]" |
| Extra params on `list_save_files` | Ignored — empty schema accepts any input |

---

## Notes for Test Executors

1. **Game must be running.** All save/load tools require the Godot game to be actively running (`play_scene`). Start the game before executing any save/load test scenarios.

2. **Isolation between tests.** Each test scenario should ideally start from a clean save state. Consider using `delete_save_file` to clean up after tests, or resetting the game between test groups.

3. **Slot collision.** When running scenarios in sequence, be mindful that saving to the same slot in different scenarios will overwrite prior data. Use distinct slot ranges per test group to avoid interference.

4. **Metadata serialization.** The `metadata` parameter accepts `z.record(z.unknown())`, meaning any serializable value can be passed. However, Godot's JSON serialization may limit what types survive a save/load round-trip. Test with primitive types first, then escalate to complex structures.

5. **Diff format.** The `compare_save_states` tool's output format is defined by the Godot plugin, not the TypeScript server. Document the actual diff format observed when running tests for the first time.

6. **Zod validation vs Godot errors.** Zod validation happens on the server side before reaching Godot (invalid types/ranges). Godot-side errors happen at runtime (missing saves, game not running, etc.). Distinguish between these two error classes in test results.

7. **Save file location.** Godot save files are typically stored in a platform-specific location (e.g., `%APPDATA%/Godot/app_userdata/<project_name>/` on Windows). These are managed by Godot's file system abstraction — the tool does not directly manipulate files on disk.
