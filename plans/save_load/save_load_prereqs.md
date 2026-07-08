# Prerequisites for Save/Load Test Plan

> **Source plan:** `server/src/test_plans/save_load_test_plan.md`
> **Source implementation:** `addons/godot_mcp/commands/save_load_commands.gd`
> **Generated:** 2026-07-08

---

## Required Project State

- **Godot 4.x project** with the Godot MCP plugin (`addons/godot_mcp/`) installed and **active** in Project Settings → Plugins.
- **Project root** must have `project.godot` with the runtime autoload registered in `[autoload]`:
  ```
  mcp_runtime="*res://addons/godot_mcp/services/mcp_runtime.gd"
  ```
  Note: the `*` prefix means "editor only" — the autoload loads in-editor but not in exported builds. This is correct for testing.
- **MCP bridge connection** active: the Node.js MCP server must be connected to the Godot editor plugin (check the **MCP** bottom-dock panel for "Connected" status).
- **File system sandbox**: the `user://` path must be writable. On Windows this resolves to `%APPDATA%/Godot/app_userdata/<project_name>/`. The save/load module creates files under `user://mcp_saves/` and relies on Godot's `FileAccess` API.
- **No residual save files**: for a clean test run, ensure `user://mcp_saves/` is empty or non-existent at the start. The tests assume an empty save directory for baseline scenarios. Use `delete_save_file` or manually delete the directory before running.

---

## Required Scenes

All 51 test scenarios (plus 3 cross-tool integration scenarios) require the game to be running. The scene itself does not need to be complex for most tests, but **comparison tests** (compare_states Scenarios 2, 3, 4; Cross-tool X3) require nodes whose properties can be modified between saves.

### Minimum Viable Scene (for all tests)
Create a scene at `res://test_scenes/save_load_test.tscn`:

```
Node2D (root)                           name="SaveLoadTestRoot"
├── Sprite2D                             name="PlayerSprite"
│   └── position: (100, 200)
│   └── scale: (1.0, 1.0)
│   └── visible: true
├── Label                                name="StatusLabel"
│   └── text: "Ready"
│   └── position: (50, 50)
└── Node2D                               name="GameState"
    ├── position: (0, 0)
    ├── visible: true
    └── Node2D                           name="Inventory"
        └── (empty — used to verify child-count changes)
```

**Why these nodes matter for comparison:**
| Node | Mutable Property | Used In |
|------|-----------------|---------|
| `PlayerSprite` | `position` (Vector2) | compare_save_states Scenario 2 — move sprite between saves to produce a diff |
| `StatusLabel` | `text` (String) | compare_save_states Scenario 2 — change text between saves as alternative property diff |
| `GameState` | `visible` (bool) | compare_save_states Scenario 2 — toggle visibility between saves |
| `Inventory` | (child nodes) | Cross-tool X3 — add/remove child to change node count |

### Alternative: Use Any Open Scene
For **basic save/load/list/delete** tests (validation-only scenarios, basic happy paths), **any running scene** suffices. The save system serializes whatever is open. Even an empty `Node` root works:
```
Node (root)                             name="Root"
```
*However, comparison diffs will be empty unless there are nodes with mutable properties.*

---

## Required Editor/Game State

| State | Required By | Notes |
|-------|------------|-------|
| **Game running** (via `play_scene` with `mode="current"` or `mode="custom"`) | All save/load scenarios except "runtime requirement" error-path tests | Must be started **before** any save/load tool call. The `mcp_runtime.gd` autoload activates during gameplay. |
| **Game NOT running** | save_game_state Scenario 18, load_game_state Scenario 12, list_save_files Scenario 7, delete_save_file Scenario 12, compare_save_states Scenario 15 | Needed to validate that runtime-guard errors surface correctly. |
| **Clean save state** (no prior saves) | list_save_files Scenario 1, Cross-tool X1 step 1-2 | Delete all saves or use fresh project. |
| **Specific saves pre-populated** | Most load/delete/compare scenarios | See [Save Slot Setup per Scenario Group](#save-slot-setup-per-scenario-group) below. |

### Save Slot Setup per Scenario Group

Each test group should prepare its own slots before execution to avoid cross-contamination.

| Test Group | Slots to Pre-Save | Metadata | Purpose |
|-----------|-------------------|----------|---------|
| save_game_state basic (S1-S8) | none — save during test | — | Test saving itself |
| save_game_state validation (S9-S14) | none — validation is server-side Zod | — | No game call needed |
| save_game_state metadata (S2-S6, S15-S16) | none — save during test | — | Test metadata variants |
| save_game_state overwrite (S17) | slot 5 with `{"version": "v1"}` first | `{"version": "v1"}` | Two-phase: save v1, then overwrite with v2 |
| load_game_state basic (S1-S3) | slots 0, 99 with known metadata | `{"test": "basic"}` | Load from pre-populated slots |
| load_game_state empty (S4) | **slot 77 must be empty** | — | No prior save |
| load_game_state deleted (S5) | slot 3 saved then deleted | `{"phase": "deleted_test"}` | Setup: save→delete→load attempt |
| load_game_state validation (S6-S10) | none — validation only | — | Zod rejects before Godot |
| load_game_state integrity (S11) | slot 20 with `{"test_key": "test_value"}` | `{"test_key": "test_value"}` | Save→modify→load→verify |
| load_game_state runtime guard (S12) | **game stopped** | — | Error path |
| list_save_files empty (S1) | none — start clean | — | Expect empty result |
| list_save_files single (S2) | slot 5 | `{"list_test": "single"}` | One entry |
| list_save_files multi (S3) | slots 0, 25, 50, 75, 99 | `{"slot_id": 0}`, `{"slot_id": 25}`, etc. | Five distinct entries |
| list_save_files after delete (S4) | slots 1, 2, 3 saved; slot 2 then deleted | Distinct per slot | Verify slot 2 absent |
| list_save_files after overwrite (S5) | slot 10 saved twice | v1 then v2 | One entry, latest metadata |
| delete_save_file basic (S1-S3) | slots 5, 0, 99 saved | `{"delete_test": true}` | Delete them |
| delete_save_file missing (S4) | **slot 77 empty** | — | Delete non-existent |
| delete_save_file double (S5) | slot 3 saved | `{"double": "test"}` | Delete twice |
| delete_save_file isolation (S6) | slots 1, 2, 3 saved | Distinct per slot | Delete middle, verify others |
| compare_save_states identical (S1) | slots 10, 11 with identical state | `{"comp": "identical"}` | No changes between saves |
| compare_save_states different (S2, S3) | slot 10 (initial state), slot 11 (modified state) | `{"comp": "phase1"}`, `{"comp": "phase2"}` | Move PlayerSprite or change StatusLabel.text between saves |
| compare_save_states boundaries (S4) | slots 0, 99 with different state | `{"comp": "slot0"}`, `{"comp": "slot99"}` | Same modification pattern |
| compare_save_states missing one (S5) | slot 20 saved, **slot 21 empty** | — | Error path |
| compare_save_states both missing (S6) | **slots 88, 89 empty** | — | Error path |
| compare_save_states self (S14) | slot 15 saved | `{"self": "compare"}` | Compare to itself |
| Cross-tool X1 | clean start → save/load/list/delete lifecycle | Varied per step | Full integration |
| Cross-tool X2 | slots 0, 25, 50, 75, 99 | `{"slot_marker": N}` per slot | Slot isolation |
| Cross-tool X3 | slots 1, 2, 3 with evolving metadata | `{"version":"1.0","data":{"hp":100,"score":0}}` etc. | Metadata evolution |

---

## Required Resources

No `.tres`, `.res`, textures, materials, shaders, or audio files are required by the save/load test plan. The save system serializes **scene-tree structure and properties in-memory** to JSON files on disk. It does not depend on any pre-existing project resources.

The only resources created during tests are:
- `user://mcp_saves/slot_XX.save` — JSON save file (one per populated slot)
- `user://mcp_saves/slot_XX.meta.json` — JSON metadata file (one per populated slot)

Both are auto-created by `save_game_state` and auto-cleaned by `delete_save_file`.

---

## Required Settings / Config

| Setting | Required? | Value | Why |
|---------|-----------|-------|-----|
| MCP plugin active | ✅ required | Enabled in Project Settings → Plugins | Tool registration |
| `mcp_runtime` autoload | ✅ required | `*res://addons/godot_mcp/services/mcp_runtime.gd` | Runtime tool access during gameplay |
| `user://` directory writable | ✅ required | Platform default | Save files written to `user://mcp_saves/` |
| No custom `godot_mcp_config.json` disabling save/load tools | ✅ required | Save/load tools must be enabled | Default: all tools enabled |

**Not required** (save/load tools do not depend on these):
- Specific input actions / InputMap configuration
- Custom collision layers
- Custom autoloads (beyond `mcp_runtime`)
- Specific renderer (`forward_plus`, `mobile`, `gl_compatibility` — any works)
- Specific physics engine
- Specific project settings (resolution, window size, etc.)
- Installed addons beyond the MCP plugin itself
- Git repository initialization
- Export presets
- Debug/profiler configuration

---

## Required External State

| External Dependency | Required? | Notes |
|---------------------|-----------|-------|
| Godot Editor running | ✅ required | Must have the test project open |
| MCP bridge connected | ✅ required | Server ↔ plugin WebSocket must be active |
| Node.js MCP server running | ✅ required | Handles Zod validation and bridges to Godot |
| `user://` file system access | ✅ required | Save file creation/reading/deletion |
| No other process locking `user://mcp_saves/` | ✅ required | File operations must not be blocked |

**Not required:**
- No additional addons or packages
- No network access (save operations are local)
- No specific OS — save path uses Godot's `user://` abstraction, which is cross-platform

---

## Setup Script

This GDScript creates the minimum viable scene required for all save/load tests. Run it via `godot_execute_editor_script` **before** starting tests, or create the scene manually.

```gdscript
# Save/Load Test Scene Setup Script
# Run in the Godot editor (EditorScript) via godot_execute_editor_script

@tool
extends EditorScript

func _run() -> void:
	var scene_path: String = "res://test_scenes/save_load_test.tscn"
	
	# Ensure directory exists
	DirAccess.make_dir_recursive_absolute("res://test_scenes")
	
	# Create scene
	var root: Node2D = Node2D.new()
	root.name = "SaveLoadTestRoot"
	
	# --- PlayerSprite (for position-based diff testing) ---
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = "PlayerSprite"
	sprite.position = Vector2(100, 200)
	sprite.scale = Vector2(1.0, 1.0)
	sprite.visible = true
	root.add_child(sprite)
	sprite.set_owner(root)
	
	# --- StatusLabel (for text-based diff testing) ---
	var label: Label = Label.new()
	label.name = "StatusLabel"
	label.text = "Ready"
	label.position = Vector2(50, 50)
	root.add_child(label)
	label.set_owner(root)
	
	# --- GameState container (for child-count diff testing) ---
	var game_state: Node2D = Node2D.new()
	game_state.name = "GameState"
	game_state.position = Vector2(0, 0)
	game_state.visible = true
	root.add_child(game_state)
	game_state.set_owner(root)
	
	# --- Inventory child (can be removed/added between saves for count diff) ---
	var inventory: Node2D = Node2D.new()
	inventory.name = "Inventory"
	game_state.add_child(inventory)
	inventory.set_owner(root)
	
	# Pack and save
	var packed: PackedScene = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, scene_path)
	
	root.queue_free()
	
	print("[save_load_setup] Created scene: ", scene_path)
	print("[save_load_setup] Nodes: SaveLoadTestRoot > PlayerSprite, StatusLabel, GameState > Inventory")
	print("[save_load_setup] Ready for save/load testing.")
```

### Quick Setup via Godot MCP Tools (Alternative)

If you prefer to build the scene via MCP tools (avoids EditorScript):

```
1. godot_create_scene(path="res://test_scenes/save_load_test.tscn", root_node_type="Node2D")
2. godot_add_node(parent_path="", type="Sprite2D", name="PlayerSprite",
     properties={"position": [100, 200], "scale": [1.0, 1.0], "visible": true})
3. godot_add_node(parent_path="", type="Label", name="StatusLabel",
     properties={"text": "Ready", "position": [50, 50]})
4. godot_add_node(parent_path="", type="Node2D", name="GameState",
     properties={"position": [0, 0], "visible": true})
5. godot_add_node(parent_path="GameState", type="Node2D", name="Inventory")
6. godot_save_scene()
```

---

## Test Execution Workflow Summary

```
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 0: SETUP                                                 │
├─────────────────────────────────────────────────────────────────┤
│  1. Ensure Godot project has MCP plugin active                  │
│  2. Ensure MCP server ↔ Godot bridge connected                  │
│  3. Create save_load_test.tscn (use Setup Script above)          │
│  4. Clear user://mcp_saves/ directory (if exists)               │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 1: VALIDATION TESTS (no game needed)                     │
├─────────────────────────────────────────────────────────────────┤
│  5. Run all Zod validation scenarios for each tool              │
│     (negative slots, wrong types, missing params)               │
│     These fail at the server layer — Godot is not called        │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 2: GAME-OFF TESTS (game NOT running)                     │
├─────────────────────────────────────────────────────────────────┤
│  6. Run all "runtime requirement" error-path scenarios          │
│     Verify correct error messages are returned                  │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 3: RUNTIME TESTS (game IS running)                       │
├─────────────────────────────────────────────────────────────────┤
│  7. godot_open_scene("res://test_scenes/save_load_test.tscn")   │
│  8. godot_play_scene(mode="current")                            │
│  9. Run save_game_state tests (S1-S17)                          │
│ 10. Run load_game_state tests (S1-S11)                          │
│ 11. Run list_save_files tests (S1-S6)                           │
│ 12. Run delete_save_file tests (S1-S6)                          │
│ 13. Run compare_save_states tests (S1-S6, S14)                  │
│ 14. Run Cross-tool integration scenarios (X1, X2, X3)           │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 4: TEARDOWN                                              │
├─────────────────────────────────────────────────────────────────┤
│ 15. godot_stop_scene()                                          │
│ 16. Optionally delete user://mcp_saves/ to clean up             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Comparison Test Modification Reference

For compare_save_states Scenarios 2, 3, 4 and Cross-tool X3, the test must **modify game state between saves**. Use these known-safe mutations:

| Modification | MCP Tool | Effect on Saved State |
|-------------|----------|----------------------|
| Move PlayerSprite | `godot_set_game_node_property(path="PlayerSprite", property="position", value=[300, 400])` | Changes `position` in tree → appears in scene_diff |
| Change StatusLabel text | `godot_set_game_node_property(path="StatusLabel", property="text", value="Modified")` | Changes `text` property → appears in scene_diff |
| Toggle GameState visibility | `godot_set_game_node_property(path="GameState", property="visible", value=false)` | Changes `visible` bool → appears in scene_diff |
| Add child to GameState | `godot_add_node(parent_path="GameState", type="Node2D", name="ExtraNode")` | Changes children count → children_count_changed diff |
| Remove Inventory child | `godot_delete_node(path="GameState/Inventory")` | Changes children count → children_count_changed diff |

**All modifications must be done via MCP tools while the game is running**, so the runtime autoload (`mcp_runtime.gd`) can apply them to the live scene tree.

---

## Notes

1. **Save directory**: `user://mcp_saves/` is resolved by Godot. On Windows the physical path is typically `%APPDATA%\Godot\app_userdata\<project_name>\mcp_saves\`. The MCP tools never access this path directly — they use `FileAccess` which handles the resolution.

2. **No editor-state dependency**: Although `save_game_state` is called from the editor, the actual save logic reads the **live scene tree** via `MCPCommandHelpers.get_scene_root()`. The editor does not need to be in any specific layout or mode.

3. **Slot collision avoidance**: The test plan uses slot-specific metadata patterns. When running tests sequentially, slots from earlier groups may still contain data. Either:
   - Use the slot ranges specified above as per-group exclusive ranges, OR
   - Clean up after each group with `delete_save_file`, OR
   - Start each group with `delete_save_file` on the slots that group will use.

4. **Godot JSON Limitations**: The test plan notes (Scenario 15) that `null` values in metadata may be stripped by Godot's JSON serializer. This is a known Godot behavior, not an MCP bug. Document observed behavior when running null-value tests.

5. **Diff format**: The `compare_save_states` output format is defined by `_diff_node_trees` and `_diff_dictionaries` in `save_load_commands.gd`. The format is:
   ```json
   {
     "result": {
       "slot_a": <int>, "slot_b": <int>,
       "timestamp_a": "<string>", "timestamp_b": "<string>",
       "metadata_diff": { "<key>": {"status": "added_in_b"|"removed_from_a"|"changed", ...} },
       "scene_diff": { "identical": <bool>, "differences": [ ... ] },
       "identical": <bool>
     }
   }
   ```
