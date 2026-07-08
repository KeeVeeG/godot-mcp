# Test Plan: Save/Load Tools (`save_load.ts`)

> **File**: `server/src/tools/save_load.ts`
> **GDScript handler**: `addons/godot_mcp/commands/save_load_commands.gd`
> **Tools count**: 5
> **Shared types used**: `z` (Zod), `OptionalProperties` (from `shared-types.ts`)

---

## Architecture Notes

- All tools call `callGodot(bridge, '<method>', args)` which forwards via WebSocket JSON-RPC to the Godot editor plugin.
- Save files are stored at `user://mcp_saves/slot_XX.save` with metadata at `user://mcp_saves/slot_XX.meta.json`.
- The GDScript handler creates a save directory on demand, serializes the full scene tree (node name, type, stored+editor-visible properties, recursive children), and writes JSON.
- **Prerequisite for all tools**: A Godot scene must be open in the editor. Tools that load/compare require previously-created save files.
- **Related tools** (from other modules):
  - `open_scene` (scene.ts) — open a scene before saving
  - `create_scene` (scene.ts) — create a scene if none exists
  - `add_node` (node.ts) — add nodes to a scene to have content to save
  - `set_node_property` (node.ts) — modify node properties so save/load can verify state

---

## Tool: `save_game_state`

**Description**: Save the current game state to a numbered slot with optional metadata

**Parameters**:

| Name | Type | Required | Constraints | Description |
|------|------|----------|-------------|-------------|
| `slot` | `number` | **Yes** | `int`, `min(0)`, `max(99)` | Save slot number (0-99) |
| `metadata` | `record<string, unknown>` | No | optional | Optional metadata to store with the save (e.g. player name, level, timestamp) |

**Handler logic**: Serializes the current scene tree (all nodes, their properties, children) to JSON. Creates `user://mcp_saves/slot_XX.save` and `user://mcp_saves/slot_XX.meta.json`. Returns success with slot, path, timestamp, node_count, and metadata.

**Expected return** (success):
```json
{
  "result": {
    "success": true,
    "slot": 0,
    "path": "user://mcp_saves/slot_00.save",
    "timestamp": "2026-07-08T...",
    "node_count": 5,
    "metadata": {},
    "message": "Game state saved to slot 0"
  }
}
```

**Expected return** (error — no scene open):
```json
{ "error": "No scene open to save" }
```

### Test Scenarios

#### Scenario 1 — Basic save to slot 0, no metadata

**Description**: Save the current scene to slot 0 with no metadata. Minimum required params only.

**Prerequisites**: A scene must be open in the editor (e.g. via `open_scene` or `create_scene`).

**Call**:
```json
{
  "tool": "save_game_state",
  "params": {
    "slot": 0
  }
}
```

**Expected result**:
- `result.success` === `true`
- `result.slot` === `0`
- `result.path` contains `"slot_00.save"`
- `result.timestamp` is a non-empty string (ISO datetime)
- `result.node_count` is a number ≥ 1 (at least root node)
- `result.metadata` is an empty object `{}`
- `result.message` contains "slot 0"

**Notes**: This is the minimal happy path. After this call, the save file should exist on disk at `user://mcp_saves/slot_00.save` and metadata at `user://mcp_saves/slot_00.meta.json`.

**What to pay attention to**: Verify that `node_count` reflects the actual number of nodes in the scene tree. The `timestamp` should be the current system time.

---

#### Scenario 2 — Save with metadata

**Description**: Save to slot 5 with custom metadata (player name, level, timestamp).

**Prerequisites**: A scene must be open.

**Call**:
```json
{
  "tool": "save_game_state",
  "params": {
    "slot": 5,
    "metadata": {
      "player_name": "Alice",
      "level": 3,
      "playtime_hours": 12.5,
      "difficulty": "hard"
    }
  }
}
```

**Expected result**:
- `result.success` === `true`
- `result.slot` === `5`
- `result.path` contains `"slot_05.save"`
- `result.metadata` equals `{"player_name": "Alice", "level": 3, "playtime_hours": 12.5, "difficulty": "hard"}`
- `result.message` contains "slot 5"

**Notes**: Metadata is stored both in the `.save` file (inside `save_data.metadata`) and in the `.meta.json` file. After this call, `list_save_files` should show this metadata.

**What to pay attention to**: Ensure all metadata types (string, number) are preserved correctly. Nested objects in metadata should also round-trip.

---

#### Scenario 3 — Save to slot 99 (boundary: max allowed)

**Description**: Save to the maximum allowed slot number (99).

**Call**:
```json
{
  "tool": "save_game_state",
  "params": {
    "slot": 99,
    "metadata": { "test": "boundary_max" }
  }
}
```

**Expected result**:
- `result.success` === `true`
- `result.slot` === `99`
- `result.path` contains `"slot_99.save"`

**Notes**: Tests the upper boundary of the slot range. File path should be `user://mcp_saves/slot_99.save`.

**What to pay attention to**: Ensure the zero-padded format `slot_99` is correct (2-digit format).

---

#### Scenario 4 — Save to slot 0 (boundary: min allowed)

**Description**: Save to the minimum allowed slot number (0).

**Call**:
```json
{
  "tool": "save_game_state",
  "params": {
    "slot": 0
  }
}
```

**Expected result**:
- `result.success` === `true`
- `result.slot` === `0`
- `result.path` contains `"slot_00.save"`

**Notes**: Tests the lower boundary. Slot 0 is valid.

**What to pay attention to**: Zero-padding: slot 0 should produce `slot_00`, not `slot_0`.

---

#### Scenario 5 — Error: no scene open

**Description**: Attempt to save when no scene is open in the editor.

**Prerequisites**: Close all scenes or have no scene open.

**Call**:
```json
{
  "tool": "save_game_state",
  "params": {
    "slot": 0
  }
}
```

**Expected result**:
- Response contains `error` key (not `result`)
- `error` contains `"No scene open to save"`

**Notes**: This tests the guard in the GDScript handler that checks for a null scene root.

**What to pay attention to**: The error message should be clear and actionable. The MCP result should have `isError: true`.

---

#### Scenario 6 — Overwrite existing save slot

**Description**: Save to a slot that already has a save file, verifying it gets overwritten.

**Prerequisites**: Run Scenario 2 (save to slot 5) first, then save to slot 5 again with different metadata.

**Call** (second save):
```json
{
  "tool": "save_game_state",
  "params": {
    "slot": 5,
    "metadata": {
      "player_name": "Bob",
      "level": 7,
      "overwrite_test": true
    }
  }
}
```

**Expected result**:
- `result.success` === `true`
- `result.slot` === `5`
- `result.metadata.player_name` === `"Bob"` (new value, not "Alice")

**Notes**: Overwriting should silently replace both `.save` and `.meta.json`. No error or conflict detection is expected.

**What to pay attention to**: After overwriting, `list_save_files` should show the new metadata, not the old one. `load_game_state` from slot 5 should restore the new state.

---

## Tool: `load_game_state`

**Description**: Load a game state from a numbered save slot

**Parameters**:

| Name | Type | Required | Constraints | Description |
|------|------|----------|-------------|-------------|
| `slot` | `number` | **Yes** | `int`, `min(0)`, `max(99)` | Save slot number to load (0-99) |

**Handler logic**: Reads `user://mcp_saves/slot_XX.save`, parses JSON, validates version ≥ 1, then restores node properties to the current scene tree by matching node names. Returns success with slot, timestamp, scene_path, restored_nodes count, and metadata.

**Expected return** (success):
```json
{
  "result": {
    "success": true,
    "slot": 0,
    "timestamp": "2026-07-08T...",
    "scene_path": "res://scenes/main.tscn",
    "restored_nodes": 5,
    "metadata": {},
    "message": "Game state loaded from slot 0 (5 nodes restored)"
  }
}
```

**Expected return** (error — no save file):
```json
{ "error": "No save file found in slot 42" }
```

### Test Scenarios

#### Scenario 1 — Load from a previously saved slot

**Description**: Load from slot 0 after saving to it (via `save_game_state` Scenario 1).

**Prerequisites**: Call `save_game_state` with `slot: 0` first.

**Call**:
```json
{
  "tool": "load_game_state",
  "params": {
    "slot": 0
  }
}
```

**Expected result**:
- `result.success` === `true`
- `result.slot` === `0`
- `result.timestamp` is a non-empty string
- `result.scene_path` is a string starting with `"res://"`
- `result.restored_nodes` is a number ≥ 1
- `result.message` contains "loaded from slot 0"

**Notes**: The `restored_nodes` count should match the `node_count` from the original save (or be close — nodes that don't exist in the current scene are skipped).

**What to pay attention to**: After loading, node properties in the editor should match the saved state. Verify by reading node properties with `get_node_properties` (node.ts).

---

#### Scenario 2 — Load with metadata round-trip

**Description**: Save with metadata, then load and verify metadata is returned.

**Prerequisites**: Call `save_game_state` with `slot: 5` and metadata from `save_game_state` Scenario 2.

**Call**:
```json
{
  "tool": "load_game_state",
  "params": {
    "slot": 5
  }
}
```

**Expected result**:
- `result.success` === `true`
- `result.slot` === `5`
- `result.metadata.player_name` === `"Alice"`
- `result.metadata.level` === `3`
- `result.metadata.difficulty` === `"hard"`

**Notes**: Metadata should round-trip perfectly through save → load.

**What to pay attention to**: Numeric metadata (e.g. `level: 3`) should not be coerced to string.

---

#### Scenario 3 — Error: load from empty slot

**Description**: Attempt to load from a slot that has no save file.

**Call**:
```json
{
  "tool": "load_game_state",
  "params": {
    "slot": 77
  }
}
```

**Expected result**:
- Response contains `error` key
- `error` contains `"No save file found in slot 77"`

**Notes**: Slot 77 was never saved to (unless previous tests used it). This tests the guard for non-existent save files.

**What to pay attention to**: Error should be specific about which slot was not found.

---

#### Scenario 4 — Error: load when no scene is open

**Description**: Attempt to load a save file when no scene is open in the editor.

**Prerequisites**: A save file must exist in the target slot, but no scene should be open.

**Call**:
```json
{
  "tool": "load_game_state",
  "params": {
    "slot": 0
  }
}
```

**Expected result**:
- Response contains `error` key
- `error` contains `"No scene open to load into"`

**Notes**: The handler checks for a null scene root after reading the save file.

**What to pay attention to**: The error occurs AFTER the save file is read and parsed — the handler reads the file, then checks for a scene root. This is important: the error is about the destination, not the source.

---

## Tool: `list_save_files`

**Description**: List all save files with their metadata

**Parameters**: None (empty `inputSchema: {}`)

**Handler logic**: Opens `user://mcp_saves/`, iterates all `.meta.json` files, parses each, and returns them sorted by slot number.

**Expected return** (success):
```json
{
  "result": {
    "count": 2,
    "saves": [
      {
        "slot": 0,
        "timestamp": 1720425600.0,
        "timestamp_human": "2026-07-08T...",
        "scene_path": "res://scenes/main.tscn",
        "file_size": 1234,
        "metadata": {}
      },
      {
        "slot": 5,
        "timestamp": 1720425601.0,
        "timestamp_human": "2026-07-08T...",
        "scene_path": "res://scenes/main.tscn",
        "file_size": 2345,
        "metadata": { "player_name": "Alice", "level": 3 }
      }
    ]
  }
}
```

### Test Scenarios

#### Scenario 1 — List saves after creating some

**Description**: After saving to slots 0 and 5 (from `save_game_state` scenarios), list all saves.

**Prerequisites**: Call `save_game_state` for slot 0 and slot 5.

**Call**:
```json
{
  "tool": "list_save_files",
  "params": {}
}
```

**Expected result**:
- `result.count` === `2` (or more if other tests ran)
- `result.saves` is an array
- Each save object has: `slot`, `timestamp`, `timestamp_human`, `scene_path`, `file_size`, `metadata`
- Saves are sorted by `slot` ascending
- Slot 5 entry has `metadata.player_name` === `"Alice"`

**Notes**: The `file_size` field is the byte size of the `.save` file. `timestamp` is Unix epoch (float), `timestamp_human` is ISO string.

**What to pay attention to**: The list only includes saves that have `.meta.json` files. If a `.save` file exists without a corresponding `.meta.json`, it will NOT appear in the list. Verify sorting is by slot number, not by timestamp.

---

#### Scenario 2 — List saves when no saves exist

**Description**: List saves when the save directory is empty or doesn't exist.

**Prerequisites**: Delete all save files first (via `delete_save_file` for all known slots), or use a fresh environment.

**Call**:
```json
{
  "tool": "list_save_files",
  "params": {}
}
```

**Expected result**:
- `result.count` === `0`
- `result.saves` is an empty array `[]`

**Notes**: The handler creates the save directory if it doesn't exist, then returns an empty list.

**What to pay attention to**: No error should be returned — an empty save directory is a valid state.

---

## Tool: `delete_save_file`

**Description**: Delete a save file from a specific slot

**Parameters**:

| Name | Type | Required | Constraints | Description |
|------|------|----------|-------------|-------------|
| `slot` | `number` | **Yes** | `int`, `min(0)`, `max(99)` | Save slot number to delete (0-99) |

**Handler logic**: Checks if `slot_XX.save` and `slot_XX.meta.json` exist. If neither exists, returns success with empty `deleted_files`. Otherwise, deletes existing files and returns the list of deleted paths.

**Expected return** (files deleted):
```json
{
  "result": {
    "success": true,
    "slot": 0,
    "deleted_files": [
      "user://mcp_saves/slot_00.save",
      "user://mcp_saves/slot_00.meta.json"
    ],
    "message": "Save slot 0 deleted"
  }
}
```

**Expected return** (slot already empty):
```json
{
  "result": {
    "success": true,
    "slot": 42,
    "deleted_files": [],
    "message": "Save slot 42 was already empty"
  }
}
```

### Test Scenarios

#### Scenario 1 — Delete an existing save

**Description**: Delete slot 0 after saving to it.

**Prerequisites**: Call `save_game_state` with `slot: 0` first.

**Call**:
```json
{
  "tool": "delete_save_file",
  "params": {
    "slot": 0
  }
}
```

**Expected result**:
- `result.success` === `true`
- `result.slot` === `0`
- `result.deleted_files` is an array with 2 entries (`.save` and `.meta.json`)
- `result.message` contains "deleted"

**Notes**: After deletion, `list_save_files` should not show slot 0, and `load_game_state` for slot 0 should return "No save file found".

**What to pay attention to**: Both files (`.save` and `.meta.json`) should be deleted. Verify by calling `list_save_files` afterward.

---

#### Scenario 2 — Delete an empty slot (idempotent)

**Description**: Delete a slot that was never saved to.

**Call**:
```json
{
  "tool": "delete_save_file",
  "params": {
    "slot": 88
  }
}
```

**Expected result**:
- `result.success` === `true`
- `result.slot` === `88`
- `result.deleted_files` is an empty array `[]`
- `result.message` contains "already empty"

**Notes**: This is an idempotent operation — deleting a non-existent slot is not an error.

**What to pay attention to**: The tool returns `success: true` even when there's nothing to delete. This is by design (not an error condition). Verify `result.deleted_files` is `[]`, not absent.

---

#### Scenario 3 — Delete after overwrite

**Description**: Overwrite a slot, then delete it. Verify both the original and overwritten files are cleaned up.

**Prerequisites**: Save to slot 5 twice (original + overwrite), then delete.

**Call**:
```json
{
  "tool": "delete_save_file",
  "params": {
    "slot": 5
  }
}
```

**Expected result**:
- `result.success` === `true`
- `result.deleted_files` has 2 entries

**Notes**: Overwriting replaces the file, so there's still only one `.save` and one `.meta.json` to delete.

**What to pay attention to**: Ensure the delete doesn't fail if the file was overwritten (file handle issues, etc.).

---

## Tool: `compare_save_states`

**Description**: Compare two save states and return a diff of their contents

**Parameters**:

| Name | Type | Required | Constraints | Description |
|------|------|----------|-------------|-------------|
| `slot_a` | `number` | **Yes** | `int`, `min(0)`, `max(99)` | First save slot to compare (0-99) |
| `slot_b` | `number` | **Yes** | `int`, `min(0)`, `max(99)` | Second save slot to compare (0-99) |

**Handler logic**: Loads save data from both slots. Compares metadata dictionaries and scene trees recursively. Returns a diff showing added/removed/changed metadata keys and node tree differences (name changes, type changes, property changes, children count changes).

**Expected return** (success, different saves):
```json
{
  "result": {
    "slot_a": 0,
    "slot_b": 5,
    "timestamp_a": "2026-07-08T...",
    "timestamp_b": "2026-07-08T...",
    "metadata_diff": {
      "player_name": { "status": "added_in_b", "value": "Alice" }
    },
    "scene_diff": {
      "identical": true,
      "differences": []
    },
    "identical": false
  }
}
```

**Expected return** (error — slot not found):
```json
{ "error": "No save file found in slot 77" }
```

### Test Scenarios

#### Scenario 1 — Compare identical saves

**Description**: Save the same scene state to two different slots, then compare.

**Prerequisites**: Call `save_game_state` for slot 0 and slot 1 with the same scene and no metadata (or same metadata).

**Call**:
```json
{
  "tool": "compare_save_states",
  "params": {
    "slot_a": 0,
    "slot_b": 1
  }
}
```

**Expected result**:
- `result.slot_a` === `0`
- `result.slot_b` === `1`
- `result.metadata_diff` is an empty object `{}` (no metadata differences)
- `result.scene_diff.identical` === `true`
- `result.scene_diff.differences` is an empty array `[]`
- `result.identical` === `true`

**Notes**: If the scene hasn't changed between the two saves, the comparison should show identical state. However, timestamps will differ — the diff only compares metadata and scene tree, not timestamps.

**What to pay attention to**: The `identical` field is `true` only when BOTH `metadata_diff` is empty AND `scene_diff.identical` is `true`. Timestamps are NOT part of the comparison.

---

#### Scenario 2 — Compare saves with different metadata

**Description**: Save to slot 0 with no metadata, save to slot 5 with metadata, then compare.

**Prerequisites**: `save_game_state` slot 0 (no metadata), `save_game_state` slot 5 (with metadata from Scenario 2 of save_game_state).

**Call**:
```json
{
  "tool": "compare_save_states",
  "params": {
    "slot_a": 0,
    "slot_b": 5
  }
}
```

**Expected result**:
- `result.identical` === `false`
- `result.metadata_diff` contains entries with `status: "added_in_b"` for each metadata key in slot 5
- `result.metadata_diff.player_name.status` === `"added_in_b"`
- `result.metadata_diff.player_name.value` === `"Alice"`

**Notes**: Keys present in B but not in A are marked `"added_in_b"`. Keys present in A but not in B would be `"removed_from_a"`. Keys present in both but with different values are `"changed"` with `value_a` and `value_b`.

**What to pay attention to**: The diff structure uses `status` enum: `"added_in_b"`, `"removed_from_a"`, `"changed"`. Verify the exact status strings.

---

#### Scenario 3 — Compare saves with different scene state

**Description**: Save a scene, modify a node property (e.g. change `position`), save to another slot, then compare.

**Prerequisites**:
1. Open/create a scene with a node (e.g. `Node2D` named "Player")
2. `save_game_state` slot 0
3. Modify the node's property (e.g. `set_node_property` to change `position`)
4. `save_game_state` slot 2
5. Compare slots 0 and 2

**Call**:
```json
{
  "tool": "compare_save_states",
  "params": {
    "slot_a": 0,
    "slot_b": 2
  }
}
```

**Expected result**:
- `result.identical` === `false`
- `result.scene_diff.identical` === `false`
- `result.scene_diff.differences` is a non-empty array
- At least one entry has `type: "properties_changed"` with a `diff` showing the changed property

**Notes**: The diff is recursive — it walks the entire node tree. Property diffs show `value_a` and `value_b` for changed values.

**What to pay attention to**: The `differences` array entries have a `type` field: `"name_changed"`, `"type_changed"`, `"properties_changed"`, `"children_count_changed"`. For `properties_changed`, there's a `node` field with the node name and a `diff` field with the property diff.

---

#### Scenario 4 — Compare a slot with itself

**Description**: Compare slot 0 with slot 0 (same slot).

**Prerequisites**: `save_game_state` slot 0.

**Call**:
```json
{
  "tool": "compare_save_states",
  "params": {
    "slot_a": 0,
    "slot_b": 0
  }
}
```

**Expected result**:
- `result.identical` === `true`
- `result.metadata_diff` is `{}`
- `result.scene_diff.identical` === `true`

**Notes**: A slot compared with itself should always be identical.

**What to pay attention to**: This tests that the diff algorithm handles the trivial case correctly without crashing or producing false differences.

---

#### Scenario 5 — Error: one slot doesn't exist

**Description**: Compare an existing slot with a non-existent slot.

**Prerequisites**: `save_game_state` slot 0 exists, slot 77 does not.

**Call**:
```json
{
  "tool": "compare_save_states",
  "params": {
    "slot_a": 0,
    "slot_b": 77
  }
}
```

**Expected result**:
- Response contains `error` key
- `error` contains `"No save file found in slot 77"`

**Notes**: The handler checks slot_a first, then slot_b. If slot_a doesn't exist, the error mentions slot_a.

**What to pay attention to**: The error should mention which specific slot is missing. Test both orderings: missing slot in `slot_a` vs `slot_b`.

---

#### Scenario 6 — Error: both slots don't exist

**Description**: Compare two non-existent slots.

**Call**:
```json
{
  "tool": "compare_save_states",
  "params": {
    "slot_a": 90,
    "slot_b": 91
  }
}
```

**Expected result**:
- Response contains `error` key
- `error` contains `"No save file found in slot 90"` (slot_a is checked first)

**Notes**: The handler checks slot_a before slot_b, so the error will reference slot_a.

**What to pay attention to**: Verify the order of error checking — slot_a is always checked first per the GDScript implementation.

---

## Cross-Tool Workflows

### Workflow 1 — Full Save/Load Cycle

**Description**: Verify that a save → load cycle preserves the scene state.

**Steps**:
1. `create_scene` or `open_scene` — ensure a scene is open
2. `add_node` — add a node with specific properties (e.g. `Node2D` named "Player" at position `[100, 200]`)
3. `save_game_state` slot 0
4. Modify the node (e.g. `set_node_property` to change position to `[500, 600]`)
5. `load_game_state` slot 0
6. `get_node_properties` — verify position is back to `[100, 200]`

**Expected**: The node's properties should be restored to the saved values after loading.

---

### Workflow 2 — Save → Overwrite → Load

**Description**: Verify that overwriting a save slot and then loading returns the latest state.

**Steps**:
1. `save_game_state` slot 0 with metadata `{ "version": 1 }`
2. Modify scene (add/remove nodes or change properties)
3. `save_game_state` slot 0 with metadata `{ "version": 2 }` (overwrite)
4. `load_game_state` slot 0
5. Verify `result.metadata.version` === `2`

**Expected**: The loaded state should reflect the second save, not the first.

---

### Workflow 3 — Save → Delete → Load (error path)

**Description**: Verify that loading from a deleted slot produces the expected error.

**Steps**:
1. `save_game_state` slot 3
2. `delete_save_file` slot 3
3. `load_game_state` slot 3

**Expected**: Step 3 should return `"No save file found in slot 3"`.

---

### Workflow 4 — Compare before and after modification

**Description**: Save state, modify scene, save to another slot, compare.

**Steps**:
1. `save_game_state` slot 0
2. `set_node_property` — change a visible property
3. `save_game_state` slot 1
4. `compare_save_states` slot_a=0, slot_b=1

**Expected**: `result.identical` === `false`, with `scene_diff.differences` showing the property change.

---

### Workflow 5 — List → Save → List (verify count changes)

**Description**: Verify that `list_save_files` reflects new saves.

**Steps**:
1. `delete_save_file` slot 0 and slot 5 (clean slate)
2. `list_save_files` — verify `count` is 0 (or baseline)
3. `save_game_state` slot 0
4. `list_save_files` — verify `count` increased by 1
5. `save_game_state` slot 5 with metadata
6. `list_save_files` — verify `count` increased by 1 again, and slot 5 has metadata

**Expected**: Each save should be immediately reflected in the list.

---

## Edge Cases & Boundary Conditions

### Slot number boundaries

| Slot | Valid? | Notes |
|------|--------|-------|
| 0 | ✅ | Minimum valid slot |
| 1 | ✅ | Normal |
| 50 | ✅ | Normal |
| 99 | ✅ | Maximum valid slot |
| -1 | ❌ | Should be rejected by Zod schema (`min(0)`) |
| 100 | ❌ | Should be rejected by Zod schema (`max(99)`) |
| 0.5 | ❌ | Should be rejected by Zod schema (`int()`) |
| `null` | ❌ | Should be rejected (required field) |
| `undefined` | ❌ | Should be rejected (required field) |

**Note**: Invalid slot values (-1, 100, 0.5) should be caught by the MCP server's Zod validation before reaching the GDScript handler. The MCP SDK returns a validation error, not a Godot error.

### Metadata edge cases

| Metadata value | Expected behavior |
|----------------|-------------------|
| `{}` | Stored as empty object, round-trips correctly |
| `null` / omitted | Treated as `{}` by GDScript `params.get("metadata", {})` |
| Nested objects `{ "a": { "b": 1 } }` | Should serialize/deserialize via JSON |
| Arrays `[1, 2, 3]` | Should serialize/deserialize via JSON |
| Special characters in string values | Should survive JSON round-trip |
| Empty string values `{ "key": "" }` | Should preserve empty strings |

### File system edge cases

| Condition | Expected behavior |
|-----------|-------------------|
| Save directory doesn't exist | Created automatically by `_ensure_save_dir()` |
| Save directory creation fails | Returns error with code |
| Save file write fails | Returns error with file path and error code |
| Corrupted save file (invalid JSON) | `load_game_state` returns parse error |
| Save file with version 0 | `load_game_state` returns "Unsupported save file version" |
| Save file with empty scene_tree | `load_game_state` returns "Save file contains no scene tree data" |

---

## Summary Table

| Tool | Parameters | Scenarios | Key validations |
|------|-----------|-----------|-----------------|
| `save_game_state` | `slot` (required), `metadata` (optional) | 6 | Slot range, metadata round-trip, overwrite, no-scene error |
| `load_game_state` | `slot` (required) | 4 | Load after save, metadata round-trip, empty slot error, no-scene error |
| `list_save_files` | none | 2 | Count accuracy, metadata presence, empty list |
| `delete_save_file` | `slot` (required) | 3 | File deletion, idempotent empty slot, post-delete verification |
| `compare_save_states` | `slot_a` (required), `slot_b` (required) | 6 | Identical comparison, metadata diff, scene diff, self-comparison, missing slot errors |
