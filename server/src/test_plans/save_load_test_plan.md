# Save/Load Tools — Comprehensive Test Plan

**Source file:** `server/src/tools/save_load.ts`
**Module purpose:** Game state persistence testing — save, load, list, delete, and compare save files via numbered slots (0–99).
**Total tools:** 5

> **Prerequisites for all tests:**
> - Godot editor is open with the MCP plugin active and connected.
> - A basic scene is loaded and running (`play_scene`) to enable runtime save/load operations.
> - The `mcp_runtime.gd` autoload is present (registered automatically by the plugin).
> - No save files pre-exist unless a test explicitly creates them first.
> - All `slot` values must be integers between **0** and **99** inclusive.

---

## Tool 1: `save_game_state`

**Description:** Save the current game state to a numbered slot with optional metadata.

### Parameters

| Parameter  | Type              | Required | Constraints          | Description                                              |
| ---------- | ----------------- | -------- | -------------------- | -------------------------------------------------------- |
| `slot`     | `number` (int)    | **Yes**  | `0 ≤ slot ≤ 99`      | Save slot number to write into.                          |
| `metadata` | `Record<string, unknown>` | No  | Arbitrary key-value pairs (strings, numbers, booleans, nested objects) | Optional metadata stored alongside the save (e.g. `{"player_name": "Hero", "level": 5, "timestamp": "2026-07-08"}`). |

### Behavior
- Saves the current runtime game state into the specified `slot`.
- If metadata is provided, it is stored with the save file.
- Overwrites any existing save in that slot without warning.
- Returns a success confirmation with the slot number.

### Test Scenarios

#### 1.1 Happy Path — Save with basic metadata
- **Description:** Save game state to an empty slot with simple string metadata.
- **JSON params:** `{"slot": 0, "metadata": {"player_name": "TestHero"}}`
- **Expected result:** Success response. Slot 0 now contains a save with metadata `player_name: "TestHero"`.
- **Notes:** Verify via `list_save_files` afterwards.

#### 1.2 Happy Path — Save with rich nested metadata
- **Description:** Save game state with complex metadata including numbers, booleans, and nested objects.
- **JSON params:** `{"slot": 10, "metadata": {"player_name": "Mage", "level": 42, "inventory": ["sword", "shield"], "stats": {"hp": 100, "mp": 50}, "is_boss_defeated": true}}`
- **Expected result:** Success response. All metadata is stored intact.
- **Notes:** Use `list_save_files` to inspect stored metadata structure.

#### 1.3 Happy Path — Save without metadata
- **Description:** Save game state with no metadata provided.
- **JSON params:** `{"slot": 20}`
- **Expected result:** Success response. Save exists at slot 20 with no (or empty) metadata.
- **Notes:** Verify the save is listed by `list_save_files`.

#### 1.4 Happy Path — Overwrite existing save
- **Description:** Save to a slot that already has data; new save should replace old.
- **JSON params:** Step 1: `{"slot": 30, "metadata": {"version": 1}}` → Step 2: `{"slot": 30, "metadata": {"version": 2}}`
- **Expected result:** Both steps succeed. Final metadata at slot 30 shows `version: 2`.
- **Notes:** Confirm old metadata is gone via `list_save_files`.

#### 1.5 Edge Case — Slot at minimum boundary (0)
- **Description:** Use the lowest valid slot number.
- **JSON params:** `{"slot": 0}`
- **Expected result:** Success.
- **Notes:** Slot 0 is valid. No special behavior expected.

#### 1.6 Edge Case — Slot at maximum boundary (99)
- **Description:** Use the highest valid slot number.
- **JSON params:** `{"slot": 99, "metadata": {"last_slot": true}}`
- **Expected result:** Success.
- **Notes:** Slot 99 is valid.

#### 1.7 Edge Case — Metadata with empty object
- **Description:** Provide an empty metadata object.
- **JSON params:** `{"slot": 40, "metadata": {}}`
- **Expected result:** Success. Metadata stored as empty object `{}`.
- **Notes:** Should not error.

#### 1.8 Edge Case — Multiple rapid saves to same slot
- **Description:** Save 3 times consecutively to the same slot.
- **JSON params:** `{"slot": 50, "metadata": {"seq": 1}}`, then `{"slot": 50, "metadata": {"seq": 2}}`, then `{"slot": 50, "metadata": {"seq": 3}}`
- **Expected result:** All succeed. Final save at slot 50 has `seq: 3`.
- **Notes:** Tests idempotent overwrite behavior.

#### 1.9 Edge Case — Save while game is paused
- **Description:** Pause the game (`pause` via `manage_editor`), then attempt save.
- **JSON params:** `{"slot": 60}`
- **Expected result:** Should succeed or return a clear error if saving requires unpaused state.
- **Notes:** Behavior depends on engine implementation — document actual result.

#### 1.10 Invalid — Slot below minimum (-1)
- **Description:** Provide `slot: -1`.
- **JSON params:** `{"slot": -1}`
- **Expected result:** Validation error (zod). Slot must be ≥ 0.
- **Notes:** Server-side rejection before reaching Godot.

#### 1.11 Invalid — Slot above maximum (100)
- **Description:** Provide `slot: 100`.
- **JSON params:** `{"slot": 100}`
- **Expected result:** Validation error (zod). Slot must be ≤ 99.
- **Notes:** Server-side rejection before reaching Godot.

#### 1.12 Invalid — Slot is a float
- **Description:** Provide a non-integer number for slot.
- **JSON params:** `{"slot": 5.5}`
- **Expected result:** Validation error (zod). Slot must be an integer.
- **Notes:** `.int()` constraint catches this.

#### 1.13 Invalid — Slot is a string
- **Description:** Provide a string instead of a number.
- **JSON params:** `{"slot": "five"}`
- **Expected result:** Validation error (zod). Expected number, received string.
- **Notes:** Type coercion should not occur.

#### 1.14 Invalid — Slot is missing
- **Description:** Omit the required `slot` parameter entirely.
- **JSON params:** `{}`
- **Expected result:** Validation error (zod). `slot` is required.
- **Notes:** Metadata is optional but slot is not.

#### 1.15 Invalid — Slot is null
- **Description:** Provide `null` for slot.
- **JSON params:** `{"slot": null}`
- **Expected result:** Validation error (zod). Expected number, received null.
- **Notes:** Null is not coerced to 0.

#### 1.16 Edge Case — Metadata with a very large object
- **Description:** Provide metadata with many keys (~100+ key-value pairs).
- **JSON params:** `{"slot": 70, "metadata": {"k1": "v1", "k2": "v2", ...}}`
- **Expected result:** Should succeed or return a clear error if size limits exist.
- **Notes:** Tests serialization/transport robustness.

#### 1.17 Edge Case — Save to all 100 slots sequentially
- **Description:** Save to every slot from 0 to 99.
- **JSON params:** `{"slot": N}` for N in 0..99
- **Expected result:** All 100 saves succeed.
- **Notes:** Tests slot array bounds and storage capacity. May be time-consuming; use batch.

---

## Tool 2: `load_game_state`

**Description:** Load a game state from a numbered save slot.

### Parameters

| Parameter | Type           | Required | Constraints     | Description                        |
| --------- | -------------- | -------- | --------------- | ---------------------------------- |
| `slot`    | `number` (int) | **Yes**  | `0 ≤ slot ≤ 99` | Save slot number to load from.     |

### Behavior
- Loads the previously saved game state from the specified `slot`.
- Restores the runtime game to the state captured at save time.
- Returns a success confirmation with the loaded slot number.
- If the slot has no save data, returns an error.

### Test Scenarios

#### 2.1 Happy Path — Load existing save
- **Description:** Save state to a slot, then load it back.
- **JSON params:** Save: `{"slot": 0}` → Load: `{"slot": 0}`
- **Expected result:** Load succeeds. Game state is restored to what was saved.
- **Notes:** Verify via `get_game_node_properties` on a known node to confirm state restoration.

#### 2.2 Happy Path — Load save with metadata
- **Description:** Save with metadata, then load; metadata should be retrievable.
- **JSON params:** Save: `{"slot": 5, "metadata": {"scene": "Level2"}}` → Load: `{"slot": 5}`
- **Expected result:** Load succeeds. Game state from slot 5 is restored.
- **Notes:** The metadata itself may not be returned by load — verify via `list_save_files`.

#### 2.3 Happy Path — Overwrite current game state on load
- **Description:** Make runtime changes, then load a previously saved state — changes should be reverted.
- **JSON params:** Save: `{"slot": 10}` → Make changes → Load: `{"slot": 10}`
- **Expected result:** Runtime changes are discarded; state matches what was at save time.
- **Notes:** This is the core use case of save/load.

#### 2.4 Happy Path — Load from slot at max boundary (99)
- **Description:** Save to slot 99, then load from it.
- **JSON params:** Save: `{"slot": 99, "metadata": {"edge": true}}` → Load: `{"slot": 99}`
- **Expected result:** Load succeeds from slot 99.
- **Notes:** Slot 99 is valid.

#### 2.5 Happy Path — Load from slot at min boundary (0)
- **Description:** Load from slot 0 after saving to it.
- **JSON params:** Save: `{"slot": 0}` → Load: `{"slot": 0}`
- **Expected result:** Success.
- **Notes:** Slot 0 is valid.

#### 2.6 Edge Case — Load from empty slot (no prior save)
- **Description:** Attempt to load from a slot that has never been saved to.
- **JSON params:** `{"slot": 88}`
- **Expected result:** Error. No save file exists in slot 88.
- **Notes:** Error message should clearly indicate the slot is empty, not a generic failure.

#### 2.7 Edge Case — Load from slot after deletion
- **Description:** Save, delete, then attempt to load.
- **JSON params:** Save: `{"slot": 15}` → Delete: `{"slot": 15}` → Load: `{"slot": 15}`
- **Expected result:** Load fails with error indicating slot 15 has no save data.
- **Notes:** Deleted saves should not be recoverable via load.

#### 2.8 Edge Case — Load while game is not running
- **Description:** Stop the scene, then attempt to load.
- **JSON params:** `{"slot": 0}`
- **Expected result:** Error or no-op. Loading requires a running game.
- **Notes:** Runtime tools require an active game session.

#### 2.9 Edge Case — Sequential loads from different slots
- **Description:** Save two different states to slots 1 and 2, then load slot 1, then slot 2.
- **JSON params:** Save slot 1 → Save slot 2 → Load slot 1 → Load slot 2
- **Expected result:** Each load restores the correct state.
- **Notes:** Verifies state isolation between slots.

#### 2.10 Invalid — Slot below minimum (-1)
- **Description:** `{"slot": -1}`
- **Expected result:** Validation error. Slot must be ≥ 0.

#### 2.11 Invalid — Slot above maximum (100)
- **Description:** `{"slot": 100}`
- **Expected result:** Validation error. Slot must be ≤ 99.

#### 2.12 Invalid — Slot is a float
- **Description:** `{"slot": 7.3}`
- **Expected result:** Validation error. Must be integer.

#### 2.13 Invalid — Slot is a string
- **Description:** `{"slot": "one"}`
- **Expected result:** Validation error. Expected number.

#### 2.14 Invalid — Slot is missing
- **Description:** `{}`
- **Expected result:** Validation error. `slot` is required.

#### 2.15 Invalid — Slot is null
- **Description:** `{"slot": null}`
- **Expected result:** Validation error. Expected number.

---

## Tool 3: `list_save_files`

**Description:** List all save files with their metadata.

### Parameters

None. This tool takes no parameters.

### Behavior
- Returns a list of all existing save slots and their associated metadata.
- Each entry should include at minimum: `slot` number, `metadata` (if present).
- If no saves exist, returns an empty list.
- Does NOT require the game to be running (reads from persistent save storage).

### Test Scenarios

#### 3.1 Happy Path — List after saving one file
- **Description:** Save to one slot, then list — should show exactly that save.
- **JSON params:** Save: `{"slot": 0, "metadata": {"name": "QuickSave"}}` → List: `{}`
- **Expected result:** Response includes slot 0 with metadata `{"name": "QuickSave"}`.
- **Notes:** Verify the response structure (array of objects with `slot` and `metadata` keys).

#### 3.2 Happy Path — List after saving multiple files
- **Description:** Save to slots 0, 25, 50, 99, then list all.
- **JSON params:** Save to 0, 25, 50, 99 → List: `{}`
- **Expected result:** Response lists all 4 saves with correct slot numbers and metadata.
- **Notes:** Verify sorting order (should be by slot number ascending).

#### 3.3 Happy Path — List when no saves exist (empty state)
- **Description:** On a fresh session with no prior saves, call list.
- **JSON params:** `{}`
- **Expected result:** Empty array or empty list response.
- **Notes:** Should NOT error — empty state is valid.

#### 3.4 Happy Path — No parameters at all
- **Description:** Call with an empty object `{}` or no arguments.
- **JSON params:** `{}`
- **Expected result:** Success. Lists all saves.
- **Notes:** The tool has no `inputSchema` properties — passing nothing should work.

#### 3.5 Edge Case — List after deleting the only save
- **Description:** Save to slot 0, delete slot 0, then list.
- **JSON params:** Save slot 0 → Delete slot 0 → List: `{}`
- **Expected result:** Empty list (slot 0 no longer appears).
- **Notes:** Deletion should be reflected immediately.

#### 3.6 Edge Case — List after overwriting a save
- **Description:** Save to slot 5 with metadata A, overwrite with metadata B, then list.
- **JSON params:** Save `{"slot": 5, "metadata": {"a": 1}}` → Save `{"slot": 5, "metadata": {"b": 2}}` → List: `{}`
- **Expected result:** Only one entry for slot 5, with metadata `{"b": 2}`.
- **Notes:** Overwrites should not create duplicates.

#### 3.7 Edge Case — List shows all 100 slots full
- **Description:** Save to every slot 0–99, then list.
- **JSON params:** Save all slots → List: `{}`
- **Expected result:** Response contains 100 entries, one per slot.
- **Notes:** Tests response size — verify no truncation.

#### 3.8 Edge Case — Unexpected parameters provided (ignored)
- **Description:** Call list with arbitrary extra parameters.
- **JSON params:** `{"slot": 5, "extra": "ignored"}`
- **Expected result:** Success. Extra parameters are ignored (schema has no defined inputs).
- **Notes:** The tool does not validate against unknown keys since `inputSchema` is empty.

#### 3.9 Edge Case — List while game is running vs stopped
- **Description:** List saves while game is running, then stop and list again.
- **JSON params:** `{}`
- **Expected result:** Both calls succeed with identical results.
- **Notes:** Save file listing should be independent of game running state.

---

## Tool 4: `delete_save_file`

**Description:** Delete a save file from a specific slot.

### Parameters

| Parameter | Type           | Required | Constraints     | Description                         |
| --------- | -------------- | -------- | --------------- | ----------------------------------- |
| `slot`    | `number` (int) | **Yes**  | `0 ≤ slot ≤ 99` | Save slot number to delete.         |

### Behavior
- Removes the save file at the specified `slot` from persistent storage.
- Returns a success confirmation.
- If the slot has no save data, behavior may vary (error or silent no-op).

### Test Scenarios

#### 4.1 Happy Path — Delete existing save
- **Description:** Save to a slot, then delete it.
- **JSON params:** Save: `{"slot": 10}` → Delete: `{"slot": 10}`
- **Expected result:** Success. Save at slot 10 is removed.
- **Notes:** Verify via `list_save_files` that slot 10 is gone.

#### 4.2 Happy Path — Delete save with metadata
- **Description:** Save with metadata, delete, then confirm removal.
- **JSON params:** Save: `{"slot": 20, "metadata": {"type": "autosave"}}` → Delete: `{"slot": 20}` → List: `{}`
- **Expected result:** Delete succeeds. List shows no entry for slot 20.
- **Notes:** Metadata should be deleted along with the save data.

#### 4.3 Happy Path — Delete from slot at min boundary (0)
- **Description:** Save to slot 0, then delete.
- **JSON params:** Save: `{"slot": 0}` → Delete: `{"slot": 0}`
- **Expected result:** Success. Slot 0 is freed.

#### 4.4 Happy Path — Delete from slot at max boundary (99)
- **Description:** Save to slot 99, then delete.
- **JSON params:** Save: `{"slot": 99}` → Delete: `{"slot": 99}`
- **Expected result:** Success. Slot 99 is freed.

#### 4.5 Edge Case — Delete non-existent save (empty slot)
- **Description:** Attempt to delete from a slot that has never been saved to.
- **JSON params:** `{"slot": 77}`
- **Expected result:** May succeed silently (no-op) or return an error. Document actual behavior.
- **Notes:** Both behaviors are acceptable — note which one occurs for reference.

#### 4.6 Edge Case — Double delete (delete same slot twice)
- **Description:** Save, delete, then delete the same slot again.
- **JSON params:** Save slot 30 → Delete slot 30 → Delete slot 30
- **Expected result:** First delete succeeds. Second delete either succeeds silently or errors.
- **Notes:** Idempotent behavior is preferred but not guaranteed — document actual result.

#### 4.7 Edge Case — Delete and then save to same slot
- **Description:** Save, delete, then save again to the same slot.
- **JSON params:** Save `{"slot": 40, "metadata": {"old": true}}` → Delete slot 40 → Save `{"slot": 40, "metadata": {"new": true}}`
- **Expected result:** All succeed. Final state at slot 40 has `{"new": true}`.
- **Notes:** After delete, the slot should be reusable.

#### 4.8 Edge Case — Delete while game is running
- **Description:** With game running, save and then delete.
- **JSON params:** Save: `{"slot": 50}` → Delete: `{"slot": 50}`
- **Expected result:** Success.
- **Notes:** Deletion during active gameplay should work.

#### 4.9 Edge Case — Delete while game is stopped
- **Description:** Stop the scene, then attempt to delete a previously saved slot.
- **JSON params:** `{"slot": 55}`
- **Expected result:** Should succeed (save files persist regardless of game state).
- **Notes:** Save file management should not require a running game.

#### 4.10 Invalid — Slot below minimum (-1)
- **Description:** `{"slot": -1}`
- **Expected result:** Validation error. Slot must be ≥ 0.

#### 4.11 Invalid — Slot above maximum (100)
- **Description:** `{"slot": 100}`
- **Expected result:** Validation error. Slot must be ≤ 99.

#### 4.12 Invalid — Slot is a float
- **Description:** `{"slot": 12.34}`
- **Expected result:** Validation error. Must be integer.

#### 4.13 Invalid — Slot is a string
- **Description:** `{"slot": "forty-two"}`
- **Expected result:** Validation error. Expected number.

#### 4.14 Invalid — Slot is missing
- **Description:** `{}`
- **Expected result:** Validation error. `slot` is required.

#### 4.15 Invalid — Slot is null
- **Description:** `{"slot": null}`
- **Expected result:** Validation error. Expected number.

---

## Tool 5: `compare_save_states`

**Description:** Compare two save states and return a diff of their contents.

### Parameters

| Parameter | Type           | Required | Constraints     | Description                             |
| --------- | -------------- | -------- | --------------- | --------------------------------------- |
| `slot_a`  | `number` (int) | **Yes**  | `0 ≤ slot_a ≤ 99` | First save slot to compare.           |
| `slot_b`  | `number` (int) | **Yes**  | `0 ≤ slot_b ≤ 99` | Second save slot to compare.          |

### Behavior
- Loads save data from both `slot_a` and `slot_b` and computes a structural diff.
- Returns a diff report showing what differs between the two saves (added, removed, changed properties/nodes).
- If both slots have identical content, returns an empty diff (or message indicating no differences).
- If either slot is empty, returns an error.

### Test Scenarios

#### 5.1 Happy Path — Compare two different saves
- **Description:** Save two states with different metadata, then compare.
- **JSON params:** Save `{"slot": 0, "metadata": {"version": 1}}` → Save `{"slot": 1, "metadata": {"version": 2}}` → Compare: `{"slot_a": 0, "slot_b": 1}`
- **Expected result:** Diff report showing metadata differences (`version: 1` vs `version: 2`).
- **Notes:** The diff format should be readable — at minimum indicate which fields differ.

#### 5.2 Happy Path — Compare identical saves
- **Description:** Save the same state twice to different slots, then compare.
- **JSON params:** Save slot 0 → (no changes) → Save slot 1 → Compare: `{"slot_a": 0, "slot_b": 1}`
- **Expected result:** Empty diff or "no differences" message.
- **Notes:** Even if saved at different times with no intervening changes, state should be identical.

#### 5.3 Happy Path — Compare slot with itself (A == B)
- **Description:** Compare a slot against itself.
- **JSON params:** Save slot 5 → Compare: `{"slot_a": 5, "slot_b": 5}`
- **Expected result:** Empty diff — identical states.
- **Notes:** This is effectively `slot_a == slot_b`.

#### 5.4 Happy Path — Compare using slots at boundaries (0 and 99)
- **Description:** Save to slot 0 and slot 99 with different content, then compare.
- **JSON params:** Save `{"slot": 0, "metadata": {"first": true}}` → Save `{"slot": 99, "metadata": {"last": true}}` → Compare: `{"slot_a": 0, "slot_b": 99}`
- **Expected result:** Diff showing metadata is different.
- **Notes:** Boundary slots should work normally.

#### 5.5 Happy Path — Compare slots in reverse order
- **Description:** Compare slot_b first, slot_a second — diff should be symmetric.
- **JSON params:** Save slot 10 with metadata `{"x": 1}` → Save slot 20 with metadata `{"x": 2}` → Compare `{"slot_a": 10, "slot_b": 20}` vs `{"slot_a": 20, "slot_b": 10}`
- **Expected result:** Both comparisons show the same difference (just direction may be inverted). Content-wise equivalent.
- **Notes:** Verify the diff is direction-agnostic or clearly indicates which slot had which value.

#### 5.6 Edge Case — Compare when one slot is empty
- **Description:** Save to slot_a, but slot_b has no data.
- **JSON params:** Save `{"slot": 30, "metadata": {"key": "value"}}` → Compare: `{"slot_a": 30, "slot_b": 99}`
- **Expected result:** Error. Cannot compare against empty slot 99.
- **Notes:** Error message should specify which slot is empty.

#### 5.7 Edge Case — Compare when both slots are empty
- **Description:** Compare two slots that have never been saved to.
- **JSON params:** `{"slot_a": 80, "slot_b": 81}`
- **Expected result:** Error. Both slots are empty.
- **Notes:** Error message should be clear.

#### 5.8 Edge Case — Compare after one slot is deleted
- **Description:** Save both slots, delete one, then compare.
- **JSON params:** Save slot 0 and slot 1 → Delete slot 1 → Compare: `{"slot_a": 0, "slot_b": 1}`
- **Expected result:** Error. Slot 1 is empty.
- **Notes:** Deletion should be reflected immediately.

#### 5.9 Edge Case — Compare complex game states (many nodes, properties)
- **Description:** Save states that differ across multiple nodes and properties, then compare.
- **JSON params:** Save slot 0 (baseline) → Make multiple node/property changes → Save slot 1 → Compare: `{"slot_a": 0, "slot_b": 1}`
- **Expected result:** Diff report lists all changed nodes and properties.
- **Notes:** Tests the diff engine's thoroughness — should not miss any changes.

#### 5.10 Edge Case — Compare while game is not running
- **Description:** Stop the scene, then attempt to compare two existing saves.
- **JSON params:** `{"slot_a": 0, "slot_b": 1}`
- **Expected result:** Should succeed (reading save files does not require running game).
- **Notes:** Document actual behavior — some diff operations may need runtime context.

#### 5.11 Invalid — slot_a below minimum (-1)
- **Description:** `{"slot_a": -1, "slot_b": 0}`
- **Expected result:** Validation error. slot_a must be ≥ 0.

#### 5.12 Invalid — slot_a above maximum (100)
- **Description:** `{"slot_a": 100, "slot_b": 0}`
- **Expected result:** Validation error. slot_a must be ≤ 99.

#### 5.13 Invalid — slot_b below minimum (-1)
- **Description:** `{"slot_a": 0, "slot_b": -1}`
- **Expected result:** Validation error. slot_b must be ≥ 0.

#### 5.14 Invalid — slot_b above maximum (100)
- **Description:** `{"slot_a": 0, "slot_b": 100}`
- **Expected result:** Validation error. slot_b must be ≤ 99.

#### 5.15 Invalid — slot_a is a float
- **Description:** `{"slot_a": 5.5, "slot_b": 6}`
- **Expected result:** Validation error. Must be integer.

#### 5.16 Invalid — slot_b is a float
- **Description:** `{"slot_a": 5, "slot_b": 6.7}`
- **Expected result:** Validation error. Must be integer.

#### 5.17 Invalid — slot_a is missing
- **Description:** `{"slot_b": 0}`
- **Expected result:** Validation error. slot_a is required.

#### 5.18 Invalid — slot_b is missing
- **Description:** `{"slot_a": 0}`
- **Expected result:** Validation error. slot_b is required.

#### 5.19 Invalid — Both slots are strings
- **Description:** `{"slot_a": "ten", "slot_b": "twenty"}`
- **Expected result:** Validation error. Expected numbers.

#### 5.20 Invalid — Both slots missing
- **Description:** `{}`
- **Expected result:** Validation error. Both slot_a and slot_b are required.

---

## Cross-Tool Workflow Scenarios

These multi-tool scenarios test integration between save/load tools.

### WF1 — Full Save/Load/Delete/List Cycle
1. **List saves** (`list_save_files`) → empty
2. **Save** to slot 10 with metadata `{"checkpoint": "start"}`
3. **List saves** → shows slot 10
4. **Load** slot 10 → success
5. **Save** to slot 20 with metadata `{"checkpoint": "mid"}`
6. **List saves** → shows slots 10 and 20
7. **Compare** slots 10 and 20 → diff shows metadata differs
8. **Delete** slot 10 → success
9. **List saves** → only slot 20 remains
10. **Load** slot 10 → error (empty)
11. **Delete** slot 20 → success
12. **List saves** → empty
- **Expected result:** Every step succeeds or returns the expected error. No state leaks between operations.

### WF2 — Overwrite and Compare Cycle
1. **Save** slot 0 with metadata `{"iteration": 1}`
2. **Save** slot 1 with metadata `{"iteration": 1}`
3. **Compare** slots 0 and 1 → identical
4. Make some game state changes
5. **Save** slot 0 with metadata `{"iteration": 2}` (overwrite)
6. **Compare** slots 0 and 1 → diff shows differences
7. **Load** slot 1 → restores to original state
8. **Save** slot 0 (now matches slot 1 since state was restored)
9. **Compare** slots 0 and 1 → identical again
- **Expected result:** Save/Load/Compare interactions are consistent. Overwrite and load restore work correctly.

### WF3 — Boundary Stress Test
1. **Save** slot 0 and slot 99
2. **List** → shows both
3. **Compare** slot 0 vs slot 99 → diff
4. **Delete** slot 0 and slot 99
5. **List** → empty
6. **Save** slot 50
7. **List** → shows slot 50
- **Expected result:** Boundaries behave identically to interior slots.

---

## Summary Matrix

| #  | Tool                 | Params                    | Valid Range        | Happy | Edge | Invalid | Total |
| -- | -------------------- | ------------------------- | ------------------ | ----: | ---: | ------: | ----: |
| 1  | `save_game_state`    | `slot`, `metadata?`       | `slot`: 0–99       |     4 |    7 |       6 |    17 |
| 2  | `load_game_state`    | `slot`                    | `slot`: 0–99       |     5 |    4 |       6 |    15 |
| 3  | `list_save_files`    | _(none)_                  | —                  |     4 |    5 |       0 |     9 |
| 4  | `delete_save_file`   | `slot`                    | `slot`: 0–99       |     4 |    5 |       6 |    15 |
| 5  | `compare_save_states`| `slot_a`, `slot_b`        | `slot_a`, `slot_b`: 0–99 | 5  |    5 |      10 |    20 |
|     | **Cross-tool workflows** |                       |                    |     3 |    — |       — |     3 |
|     | **TOTAL**            |                           |                    |    **25** | **26** | **28** | **79** |

---

## Notes for Test Executors

1. **Pre-test cleanup:** Before each scenario, ensure no residual save files exist from prior tests. Use `list_save_files` to verify state, and `delete_save_file` as needed.

2. **Validation layer:** All `slot`, `slot_a`, `slot_b` parameters are validated by Zod on the **server side** (before reaching Godot). Tests labeled "Invalid" with zod validation errors will fail at the server, not in Godot.

3. **Game state dependency:** Tools 1 (`save_game_state`) and 2 (`load_game_state`) require the game to be running. Tools 3 (`list_save_files`), 4 (`delete_save_file`), and 5 (`compare_save_states`) may work without a running game — document actual behavior during execution.

4. **Metadata format:** The `metadata` parameter accepts any valid JSON key-value pairs (strings, numbers, booleans, arrays, nested objects). Test with diverse types to ensure proper serialization/deserialization.

5. **Slot isolation:** Each slot (0–99) should be fully independent. Saving to one slot must not affect data in any other slot.

6. **Persistence across sessions:** Save files may persist across editor sessions. Always clean up after tests to avoid stale data affecting future test runs.

7. **Async operations:** Some save/load operations may be asynchronous. Allow adequate time for completion and avoid rapid-fire calls to the same slot without waiting for prior operations to finish.
