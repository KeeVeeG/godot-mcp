# Prerequisites for Audio Configuration Test Plan

> **Source test plan:** `audio_config_test_plan.md`  
> **Source tool:** `server/src/tools/audio_config.ts`  
> **Tools covered:** `get_audio_settings`, `set_audio_bus_layout`, `add_audio_bus_config`, `remove_audio_bus`, `set_audio_bus_volume`, `get_audio_bus_effects`  
> **Generated:** 2026-07-08

---

## Required Project State

- **Godot 4.x project** exists on disk with a valid `project.godot` file. The project must be open in the Godot editor. Any project type works (2D, 3D, or empty) — audio buses are engine-level, not scene-dependent.
- **godot_mcp addon is installed and active.** The addon lives at `res://addons/godot_mcp/` and must be enabled in **Project → Project Settings → Plugins**. The plugin registers the autoload `mcp_runtime` at `res://addons/godot_mcp/services/mcp_runtime.gd` in `project.godot`'s `[autoload]` section.
- **MCP server is running** (`node server/dist/index.js` or `npx -y @keeveeg/godot-mcp`) and connected to the Godot editor via WebSocket on one of ports 6505-6514. The Godot editor's **MCP** bottom panel shows "Connected" status.
- **No specific scene is required.** The audio bus layout is managed through `AudioServer` and is project-wide, not tied to any particular scene. Any scene (or no scene) can be open — all 44 test scenarios (6 tools × n scenarios + 2 integrations) run against the project's audio bus configuration regardless of the open scene.
- **The default audio bus layout is in place.** When a Godot project is created, the audio system initializes with exactly one bus: `"Master"` at index 0 with volume 0 dB, solo = false, mute = false, and no effects. The `get_audio_settings` Scenario 1 depends on this default state (`buses` array contains at least the "Master" bus).
- **Dedicated test project recommended.** The `set_audio_bus_layout` tool replaces the ENTIRE bus layout, and `remove_audio_bus` deletes buses. Running these tests in a project with a custom audio setup will destroy that setup. Use a clean project or one where audio bus layout can be freely modified.

---

## Required Scenes

**No specific scene hierarchy is required.** All audio configuration tools operate on the engine's `AudioServer` singleton, which manages buses independently of the scene tree. The test executor can have any scene open (including no scene at all).

However, if running audio_config tests alongside tests from other test plans that DO require specific scenes (e.g., `audio_test_plan.md` which tests `add_audio_player`), you may want to open a simple scene for convenience. A minimal scene for cross-plan compatibility:

- **File path:** `res://test_scenes/audio_test_scene.tscn` (optional, only needed if combining with `audio_test_plan.md`)
- **Root node:** `Node2D` named `"AudioTestRoot"`
- **Hierarchy:** Empty root scene — no child nodes required for audio config tests.

---

## Required Pre-Created Audio Bus Layouts

The following bus layouts must be set up before specific scenarios. Use the audio config tools themselves (or reset to default) to create these states.

### Layout A: Default (Master Only)
- **Required for:** `remove_audio_bus` Scenario 9 (`set_audio_bus_volume` S8 depends on Master), `get_audio_settings` S1-S2 (read current settings), `set_audio_bus_layout` S1-S15 (these replace the layout), `add_audio_bus_config` S1-S12 (these add to existing layout), `set_audio_bus_volume` S1, S3-S8, S10-S12 (operate on Master), `get_audio_bus_effects` S1 (read Master effects)
- **How to create:** This is the default state of a fresh Godot project. Can also be reset via:
  ```
  set_audio_bus_layout({ "buses": [{ "name": "Master" }] })
  ```
- **Expected state:**
  - Index 0: `"Master"`, volume 0 dB, solo = false, mute = false, no effects

### Layout B: Master + Music (2 buses)
- **Required for:** `remove_audio_bus` Scenario 1, `set_audio_bus_volume` Scenario 2
- **How to create:**
  ```
  add_audio_bus_config({ "name": "Music" })
  ```
  (starting from Layout A)
- **Expected state:**
  - Index 0: `"Master"`
  - Index 1: `"Music"`, volume 0 dB, solo = false, mute = false, no effects

### Layout C: Master + SFX + Music (3 buses)
- **Required for:** `remove_audio_bus` Scenario 2 (needs at least 2 buses after Master at indices 1 and 2)
- **How to create:**
  ```
  add_audio_bus_config({ "name": "SFX" })     // appended at index 1
  add_audio_bus_config({ "name": "Music" })    // appended at index 2
  ```
  (starting from Layout A)
- **Expected state:**
  - Index 0: `"Master"`
  - Index 1: `"SFX"`
  - Index 2: `"Music"`

### Layout D: Master + SFX (no effects, no volume changes)
- **Required for:** `get_audio_bus_effects` Scenario 3 (empty effects on a freshly created bus)
- **How to create:**
  ```
  set_audio_bus_layout({ "buses": [{ "name": "Master" }] })
  add_audio_bus_config({ "name": "SFX" })
  ```
- **Expected state:**
  - Index 0: `"Master"`
  - Index 1: `"SFX"`, volume 0 dB, solo = false, mute = false, **zero effects**

### Layout E: Master + Music (Music has 1 effect — Reverb)
- **Required for:** `get_audio_bus_effects` Scenario 2 (bus with at least one effect)
- **How to create:**
  ```
  set_audio_bus_layout({ "buses": [{ "name": "Master" }] })
  add_audio_bus_config({ "name": "Music" })
  add_audio_bus_effect({ "bus_name": "Music", "effect_type": "reverb" })
  ```
  - **NOTE:** `add_audio_bus_effect` is from the `audio` tool module (not `audio_config`). It is used solely to set up test prerequisites. See `godot_add_audio_bus_effect` in the tools catalog.
- **Expected state:**
  - Index 1: `"Music"`, has exactly 1 effect of type `reverb`

### Layout F: Master + Music (Music has 2+ effects — Reverb + Delay)
- **Required for:** `get_audio_bus_effects` Scenario 4 (bus with 2+ effects)
- **How to create:**
  ```
  set_audio_bus_layout({ "buses": [{ "name": "Master" }] })
  add_audio_bus_config({ "name": "Music" })
  add_audio_bus_effect({ "bus_name": "Music", "effect_type": "reverb", "index": 0 })
  add_audio_bus_effect({ "bus_name": "Music", "effect_type": "delay", "index": 1 })
  ```
  - **NOTE:** `add_audio_bus_effect` is from the `audio` tool module. See `godot_add_audio_bus_effect`.
- **Expected state:**
  - Index 1: `"Music"`, has exactly 2 effects in order: `reverb` at index 0, `delay` at index 1

---

## Scenario-to-Prerequisite Mapping

The table below maps every scenario to the minimum layout required before it runs. Scenarios that are **self-contained** (they create or replace their own state, or test validation without touching state) are marked as such.

| Scenario | Layout Needed | Notes |
|----------|--------------|-------|
| **get_audio_settings S1-S2** | Layout A (default) | Read-only; just needs any valid bus layout |
| **set_audio_bus_layout S1-S15** | Layout A (default) | Each scenario REPLACES the entire layout. The starting layout is irrelevant as long as one exists. Run each scenario independently from Layout A. |
| **add_audio_bus_config S1-S5** | Layout A (default) | Each scenario ADDS to the existing layout. Reset to Layout A between scenarios to avoid name collisions (e.g., S1 adds "Music", S2 adds "SFX", S3 adds "NewMaster", S4 adds "Music"/"SFX"/"Voice", S5 adds "Ambient Sounds 2.0"). |
| **add_audio_bus_config S6-S12** | Layout A (default) | Edge cases testing validation — most should fail before reaching Godot. Run from any layout. |
| **remove_audio_bus S1** | Layout B | Needs bus at index 1 to remove. |
| **remove_audio_bus S2** | Layout C | Needs buses at indices 1 and 2. |
| **remove_audio_bus S3-S4** | Layout A (default) | Edge cases — validation rejects index 0 and negative index before Godot call. |
| **remove_audio_bus S5** | Layout A (default) | Tests index 999 (out of range) — Godot should error. |
| **remove_audio_bus S6-S8** | Layout A (default) | Zod validation edge cases — fail before reaching Godot. |
| **remove_audio_bus S9** | Layout A (default) | Explicitly requires "fresh layout with only Master" — tests that index 1 doesn't exist. |
| **set_audio_bus_volume S1** | Layout A (default) | Sets Master volume — Master always exists. |
| **set_audio_bus_volume S2** | Layout B | Needs "Music" bus to exist. |
| **set_audio_bus_volume S3-S6** | Layout A (default) | Operate on Master — always exists. |
| **set_audio_bus_volume S7-S8** | Layout A (default) | Validation edge cases — fail before reaching Godot. |
| **set_audio_bus_volume S9** | Layout A (default) | Tests non-existent bus "NonexistentBus" — Godot should error. |
| **set_audio_bus_volume S10** | Layout A (default) | Empty bus name — Godot should error. |
| **set_audio_bus_volume S11-S12** | Layout A (default) | Zod validation edge cases — fail before reaching Godot. |
| **get_audio_bus_effects S1** | Layout A (default) | Reads Master effects — Master always exists. |
| **get_audio_bus_effects S2** | Layout E | Needs "Music" bus with at least one effect. |
| **get_audio_bus_effects S3** | Layout D | Needs freshly created "SFX" bus with zero effects. |
| **get_audio_bus_effects S4** | Layout F | Needs "Music" bus with 2+ effects. |
| **get_audio_bus_effects S5-S8** | Layout A (default) | Edge cases — validation errors or non-existent bus. |
| **Integration 1** | Layout A (default) | Self-contained. The test itself resets layout in step 1, then builds everything step-by-step. No external prerequisites beyond the default state. |
| **Integration 2** | Layout A (default) | Self-contained. Operates only on Master bus. No external prerequisites. |

---

## Required Resources

**No resource files (.tres, .res, .png, .ogg, etc.) are required.** The audio configuration tools operate purely on the in-memory `AudioServer` bus layout. They do not read or write any resource files.

---

## Required Editor/Game State

- **Godot editor is in Edit mode** (not Play mode). All audio configuration tools are editor-scoped tools — they modify `AudioServer` state through the Godot editor API. Play mode is not needed for any scenario. If the editor is in Play mode, these tools may still work (audio bus changes persist during play), but the test plan assumes Edit mode.
- **No blocking dialogs** are open in the Godot editor. The plugin auto-dismisses most dialogs during WebSocket operations, but manual dialogs (e.g., "Save changes?") can block responses.
- **Godot Output log and MCP panel visible** for debugging. Check the **MCP** bottom panel for `[MCP]` connection and tool execution messages.
- **No breakpoints set** on any GDScript files. Breakpoints are not relevant to audio configuration tools, which do not execute user scripts.
- **No specific editor layout, tool selection, or viewport configuration required.** The audio bus system is independent of the editor's visual state.

---

## Required Settings/Config

- **No specific `project.godot` settings** are required beyond what the godot_mcp plugin registers automatically. The audio bus layout default is engine-initialized from `AudioServer` at project load time and does not require any `project.godot` entries.
- **No specific input actions, collision layers, or custom autoloads** are needed. The `mcp_runtime` autoload registered by the plugin is automatically present. No other autoloads are required.
- **`godot_mcp_config.json`** (optional, at project root): If present, ensure none of these audio config tools are disabled:
  ```json
  {
    "enabled_tools": {
      "get_audio_settings": true,
      "set_audio_bus_layout": true,
      "add_audio_bus_config": true,
      "remove_audio_bus": true,
      "set_audio_bus_volume": true,
      "get_audio_bus_effects": true
    }
  }
  ```
  If the file does not exist, all tools are enabled by default.

- **Cross-tool dependency:** `godot_add_audio_bus_effect` (from the `audio` tool module, NOT `audio_config`) must be enabled for test setup. It is needed to create Layouts E and F:
  ```json
  {
    "enabled_tools": {
      "add_audio_bus_effect": true
    }
  }
  ```
  This tool is only used for **prerequisite setup** — it is NOT part of the `audio_config_test_plan.md` scenarios under test. If `add_audio_bus_effect` is disabled, Layouts E and F cannot be created and `get_audio_bus_effects` Scenarios 2 and 4 must be skipped.

---

## External State / Dependencies

**No external dependencies.** The audio bus system is fully self-contained within Godot's `AudioServer`. No network access, no addons (beyond `godot_mcp` itself), no git repository, no external files.

---

## Setup Script

This GDScript (executed via `godot_execute_editor_script`) resets the audio bus layout to the clean default state (Layout A). Use it at the start of each test session or between scenario groups:

```gdscript
# Reset audio bus layout to default (Master only)
# Run via: godot_execute_editor_script
var bus_count = AudioServer.get_bus_count()

# Remove all buses except index 0 (Master), working backward
for i in range(bus_count - 1, 0, -1):
    AudioServer.remove_bus(i)

# Reset Master bus to defaults
AudioServer.set_bus_volume_db(0, 0.0)
AudioServer.set_bus_solo(0, false)
AudioServer.set_bus_mute(0, false)

# Remove all effects from Master
var effect_count = AudioServer.get_bus_effect_count(0)
for i in range(effect_count - 1, -1, -1):
    AudioServer.remove_bus_effect(0, i)

print("[SETUP] Audio bus layout reset to default (Master only)")
```

### Manual Setup Commands (via MCP tools)

If you prefer to set up layouts via the MCP tools themselves (testing the tools while setting up):

**Reset to Layout A (Master only):**
```
godot_set_audio_bus_layout({ "buses": [{ "name": "Master" }] })
```

**Create Layout B (Master + Music):**
```
godot_set_audio_bus_layout({ "buses": [{ "name": "Master" }] })
godot_add_audio_bus_config({ "name": "Music" })
```

**Create Layout C (Master + SFX + Music):**
```
godot_set_audio_bus_layout({ "buses": [{ "name": "Master" }] })
godot_add_audio_bus_config({ "name": "SFX" })
godot_add_audio_bus_config({ "name": "Music" })
```

**Create Layout D (Master + SFX, zero effects):**
```
godot_set_audio_bus_layout({ "buses": [{ "name": "Master" }] })
godot_add_audio_bus_config({ "name": "SFX" })
```

**Create Layout E (Master + Music with Reverb):**
```
godot_set_audio_bus_layout({ "buses": [{ "name": "Master" }] })
godot_add_audio_bus_config({ "name": "Music" })
godot_add_audio_bus_effect({ "bus_name": "Music", "effect_type": "reverb" })
```

**Create Layout F (Master + Music with Reverb + Delay):**
```
godot_set_audio_bus_layout({ "buses": [{ "name": "Master" }] })
godot_add_audio_bus_config({ "name": "Music" })
godot_add_audio_bus_effect({ "bus_name": "Music", "effect_type": "reverb", "index": 0 })
godot_add_audio_bus_effect({ "bus_name": "Music", "effect_type": "delay", "index": 1 })
```

---

## Test Execution Order Recommendations

To minimize setup/teardown overhead, run scenarios in the following groups:

### Group 1: Read-Only / Self-Contained (Layout A)
Run these in any order from the default Layout A. No teardown needed between them since they don't mutate state (or they replace state fully):
- `get_audio_settings` S1-S2
- `set_audio_bus_layout` S1-S15 (each replaces the layout)
- `set_audio_bus_volume` S1, S3-S12 (operate on Master or test validation)
- `get_audio_bus_effects` S1, S5-S8
- Integration 2

### Group 2: Additive Operations (Layout A → reset between)
Reset to Layout A before each scenario to avoid name collisions:
- `add_audio_bus_config` S1-S5 (each adds different-named buses; reset avoids duplicate name errors from prior scenarios)
- `add_audio_bus_config` S6-S12 (validation edge cases — can run in any order)
- `remove_audio_bus` S3-S9 (edge cases; S9 explicitly needs "only Master")

### Group 3: Operations on Pre-Created Buses
Create the required layout first, then run the scenario:
- **Step 1:** Create Layout B → `remove_audio_bus` S1
- **Step 2 (optional):** Reset to Layout A → Create Layout C → `remove_audio_bus` S2
- **Step 3:** Reset to Layout A → Create Layout B → `set_audio_bus_volume` S2

### Group 4: Effects-Dependent Scenarios
Create layouts with effects using `add_audio_bus_effect`:
- **Step 1:** Create Layout D → `get_audio_bus_effects` S3
- **Step 2:** Create Layout E → `get_audio_bus_effects` S2
- **Step 3:** Create Layout F → `get_audio_bus_effects` S4

### Group 5: Integration (Layout A)
- Integration 1 (runs its own full lifecycle from Layout A)
- Reset to Layout A after Integration 1 completes

---

## Summary

| Category | Requirement |
|----------|-------------|
| Project type | Any (2D/3D/empty) |
| Scenes needed | None |
| Resource files needed | None |
| Play mode required | No — Edit mode only |
| External dependencies | None |
| Pre-created bus layouts | 6 layouts (A–F), created via MCP tools during setup |
| Cross-tool dependency | `godot_add_audio_bus_effect` (for Layouts E, F setup only) |
| Settings/config | `godot_mcp_config.json` must not disable any of the 6 tools |
