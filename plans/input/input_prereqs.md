# Prerequisites for Input Tools Test Plan

**Source plan:** `server/src/test_plans/input_test_plan.md`
**Generated:** 2026-07-08
**Coverage:** 7 tools (simulate_key, simulate_mouse_click, simulate_mouse_move, simulate_action, simulate_sequence, get_input_actions, set_input_action)

---

## Required Project State

- **Godot 4.x project** (tested with 4.7) — any project type works (2D or 3D). Input simulation tools are scene-agnostic.
- **Godot MCP addon** installed and active at `addons/godot_mcp/` — required for all 7 tools.
- **`mcp_runtime.gd` autoload** registered in `project.godot` as `mcp_runtime="*res://addons/godot_mcp/services/mcp_runtime.gd"` — **critical** for `simulate_key`, `simulate_mouse_click`, `simulate_mouse_move`, `simulate_action`, and `simulate_sequence`. These tools dispatch input events into the running game and require the runtime autoload present at game start.
- **Main scene configured** — any playable `.tscn` file set as the project main scene (needed so the game can start for runtime input simulation). A minimal `Node2D` root scene is sufficient. No specific nodes are required — all input events are dispatched globally, not targeting specific scene objects.

---

## Required Scenes

### 1. Primary test scene (`res://scenes/test_input.tscn`)

A minimal playable scene used only as the game entry point. Root node type: `Node2D`. Structure:

```
test_input (Node2D root)
```

**Why so minimal:** All 87 input test scenarios test the input system directly — simulating key presses, mouse clicks/moves, and input actions. These events are dispatched at the OS/engine level and do not require any specific nodes in the scene tree. The scene just needs to exist and be playable so the game loop runs and `mcp_runtime.gd` can receive commands.

---

## Required Resources

**None.** All 7 input tools work with the engine's built-in input system (`Input`, `InputMap`). No `.tres`, textures, materials, shaders, audio files, or external assets are needed.

---

## Required Editor/Game State

| State | Required By | Notes |
|-------|-------------|-------|
| **Game running** (via `play_scene`) | `simulate_key` S1–S6, S11; `simulate_mouse_click` S1–S10; `simulate_mouse_move` S1–S8; `simulate_action` S1–S5; `simulate_sequence` S1–S6, S8–S9, S12, S15–S16; Cross-tool integration S1 (step 3), S2 | All 5 simulation tools require an active game session with `mcp_runtime.gd` loaded. The game viewport must exist (for mouse position events) but its content is irrelevant. |
| **Game NOT running** | `simulate_key` S7–S10; `simulate_mouse_click` S11–S15; `simulate_mouse_move` S9–S12; `simulate_action` S6–S9; `simulate_sequence` S7, S10–S11, S13–S14; `get_input_actions` S1–S3; `set_input_action` all | Validation-error scenarios are server-side only and never reach Godot. `get_input_actions` and `set_input_action` operate on `InputMap` which is available in editor mode. |
| **Editor open** | `get_input_actions` S1–S3; `set_input_action` S1–S10, S17–S18, S20; Cross-tool integration S1 (steps 1–2) | InputMap operations run through the editor. `set_input_action` modifies `project.godot` and needs the editor's undo system. |

---

## Required Settings/Config

### InputMap (Built-in Defaults)

These **must exist** in the project's InputMap. In a fresh Godot project, all of these are present by default. If the project has been modified, verify they still exist:

| Action Name | Used By | Purpose |
|-------------|---------|---------|
| `ui_accept` | `simulate_action` S1–S3, S5, S8–S9; `simulate_sequence` S16; `set_input_action` S9; Cross-tool S1 | Default accept/confirm action (Enter/Space) |
| `ui_cancel` | `simulate_action` S3 | Default cancel/back action (Escape) |
| `ui_up` | `simulate_action` S3 | Default up navigation |
| `ui_down` | `simulate_action` S3 | Default down navigation |
| `ui_left` | `simulate_action` S3 | Default left navigation |
| `ui_right` | `simulate_action` S3 | Default right navigation |
| `ui_select` | `simulate_action` S3 | Default select action |
| `ui_focus_next` | `simulate_action` S3 | Default focus-next UI action (Tab) |
| `ui_focus_prev` | `simulate_action` S3 | Default focus-prev UI action (Shift+Tab) |

### Other Settings

- **No custom input actions** need to exist before tests run — `set_input_action` creates its own (`jump`, `move_right`, `sprint`, `crouch`, `interact`, `shoot`, `pause`, `attack`, `movement_bundle`, `test_attack`, `empty_action`, `extended`, `test_action`, `broken`).
- **No collision layers, autoloads beyond mcp_runtime, or other project settings** are required.
- **No custom deadzone values or controller mappings** are needed.

### Addons

- **godot_mcp** addon must be enabled in Project Settings → Plugins (required by all tools).

---

## Setup Script

Run this GDScript via `execute_editor_script` to create the minimal playable scene. This script assumes a fresh Godot project with the MCP addon already active and `mcp_runtime.gd` autoload registered.

```gdscript
# === 1. Create the minimal test scene ===
var root = Node2D.new()
root.name = "test_input"

get_editor_interface().get_edited_scene_root().add_child(root)
root.owner = get_editor_interface().get_edited_scene_root()

# Save the scene
var packed = PackedScene.new()
packed.pack(root)
ResourceSaver.save(packed, "res://scenes/test_input.tscn")

# Clean up editor — remove the temporary root child
root.queue_free()

# === 2. Verify built-in InputMap actions exist ===
# These are present by default in any Godot project, but log them for confirmation:
var expected_actions = [
	"ui_accept", "ui_cancel", "ui_up", "ui_down",
	"ui_left", "ui_right", "ui_select",
	"ui_focus_next", "ui_focus_prev"
]
for action in expected_actions:
	if InputMap.has_action(action):
		print("OK: InputMap action '", action, "' exists")
	else:
		printerr("MISSING: InputMap action '", action, "' not found!")
```

**Post-setup manual steps:**

1. Set `res://scenes/test_input.tscn` as the project main scene (Project Settings → Application → Run → Main Scene)
2. Verify the `mcp_runtime.gd` autoload is present in `project.godot`:
   - Open `project.godot` and check the `[autoload]` section for `mcp_runtime="*res://addons/godot_mcp/services/mcp_runtime.gd"`
   - This is usually auto-registered when the addon is enabled
3. Verify the 9 built-in InputMap actions from the table above still exist (the setup script checks this)
4. Start the game once to confirm `mcp_runtime.gd` loads without errors (check output log for `[MCP Runtime] Loaded and ready for IPC`)

---

## Scenario-to-Prerequisite Mapping

### simulate_key

| Scenario | Prerequisites |
|----------|---------------|
| S1 — Press space (default) | Game running |
| S2 — Release space | Game running |
| S3 — Echo/repeat KEY_A | Game running |
| S4 — Press with echo=false | Game running |
| S5 — Release with echo | Game running |
| S6 — Various keycodes (11 keys) | Game running |
| S7 — Missing keycode | None (server-side validation) |
| S8 — Invalid keycode type | None (server-side validation) |
| S9 — Invalid pressed type | None (server-side validation) |
| S10 — Invalid echo type | None (server-side validation) |
| S11 — Empty keycode string | Game running (sent to Godot as-is) |

### simulate_mouse_click

| Scenario | Prerequisites |
|----------|---------------|
| S1 — Left click at [100,200] | Game running + viewport exists |
| S2 — Right button click | Game running |
| S3 — Middle button click | Game running |
| S4 — Mouse release | Game running |
| S5 — Right button release | Game running |
| S6 — Middle button release | Game running |
| S7 — All three buttons | Game running |
| S8 — Zero position [0,0] | Game running |
| S9 — Negative position | Game running |
| S10 — Large position [99999,99999] | Game running |
| S11 — Missing position | None (server-side validation) |
| S12 — Wrong array length [100] | None (server-side validation) |
| S13 — String elements | None (server-side validation) |
| S14 — Invalid button enum | None (server-side validation) |
| S15 — 3-element array | None (server-side validation) |

### simulate_mouse_move

| Scenario | Prerequisites |
|----------|---------------|
| S1 — Absolute move to [400,300] | Game running + viewport exists |
| S2 — Absolute move to [0,0] | Game running |
| S3 — Relative move [+50,-50] | Game running (needs known starting position for meaningful result) |
| S4 — Relative move negative | Game running |
| S5 — Relative zero offset | Game running |
| S6 — Explicit relative=false | Game running |
| S7 — Large position [99999,99999] | Game running |
| S8 — Negative absolute [-500,-500] | Game running |
| S9 — Missing position | None (server-side validation) |
| S10 — Wrong array length | None (server-side validation) |
| S11 — Non-number elements | None (server-side validation) |
| S12 — Invalid relative type | None (server-side validation) |

### simulate_action

| Scenario | Prerequisites |
|----------|---------------|
| S1 — Press ui_accept (default) | Game running + `ui_accept` exists in InputMap |
| S2 — Release ui_accept | Game running + `ui_accept` exists in InputMap |
| S3 — Various built-in actions (8 actions) | Game running + all 8 built-in UI actions exist in InputMap |
| S4 — Custom action "jump" | Game running (action may not be in InputMap — server passes through) |
| S5 — Explicit pressed=true | Game running + `ui_accept` exists in InputMap |
| S6 — Missing action | None (server-side validation) |
| S7 — Empty action string | Game running (sent to Godot as-is) |
| S8 — Invalid pressed type | None (server-side validation) |
| S9 — Special characters in action name | Game running (sent to Godot as-is) |

### simulate_sequence

| Scenario | Prerequisites |
|----------|---------------|
| S1 — Single key event | Game running |
| S2 — Multi-event with delays | Game running |
| S3 — No delays (4 keys) | Game running |
| S4 — Mouse clicks only | Game running |
| S5 — Action events (press+release "jump") | Game running |
| S6 — Mouse moves (absolute+relative) | Game running |
| S7 — Empty events array | Game running (or editor — server passes through, Godot dispatches nothing) |
| S8 — Zero delay | Game running |
| S9 — Negative delay | Game running |
| S10 — Missing event type | None (server-side validation) |
| S11 — Empty event type | Game running (sent to Godot as-is) |
| S12 — Passthrough properties | Game running |
| S13 — Missing events param | None (server-side validation) |
| S14 — Events not an array | None (server-side validation) |
| S15 — 100-event stress test | Game running |
| S16 — All four event types mixed | Game running |

### get_input_actions

| Scenario | Prerequisites |
|----------|---------------|
| S1 — Fetch input actions | Editor open (no game needed) |
| S2 — Extra unexpected params | Editor open (Zod strips unknown keys) |
| S3 — Verify built-in UI actions | Editor open + built-in UI actions exist in InputMap |

### set_input_action

| Scenario | Prerequisites |
|----------|---------------|
| S1 — Set "jump" action with default deadzone | Editor open (no game needed) |
| S2 — Set "move_right" with deadzone=0.2 | Editor open |
| S3 — Deadzone minimum (0) | Editor open |
| S4 — Deadzone maximum (1) | Editor open |
| S5 — Deadzone midpoint (0.5) | Editor open |
| S6 — Mouse button events | Editor open |
| S7 — Joypad button event | Editor open |
| S8 — Mixed event types | Editor open |
| S9 — Modify existing `ui_accept` | Editor open + `ui_accept` exists in InputMap |
| S10 — Multiple keys (WASD) | Editor open |
| S11 — Missing action | None (server-side validation) |
| S12 — Missing events | None (server-side validation) |
| S13 — Missing both params | None (server-side validation) |
| S14 — Deadzone below 0 (-0.1) | None (server-side validation) |
| S15 — Deadzone above 1 (1.5) | None (server-side validation) |
| S16 — Deadzone string | None (server-side validation) |
| S17 — Empty action string | Editor open (sent to Godot as-is) |
| S18 — Empty events array | Editor open (sent to Godot as-is) |
| S19 — Event missing type | None (server-side validation) |
| S20 — Passthrough properties | Editor open |
| S21 — Events not an array | None (server-side validation) |

### Cross-Tool Integration

| Scenario | Prerequisites |
|----------|---------------|
| S1 — set→get→simulate lifecycle | Editor open (steps 1–2) + Game running (step 3) |
| S2 — Complex sequence combo | Game running |

---

## Quick Pre-Check Commands

Before running the full test suite, verify these conditions with a single pre-flight check:

```gdscript
# Run via execute_editor_script before starting tests
# Returns true if all prerequisites are met, false otherwise

func preflight() -> bool:
	var ok = true

	# 1. Check main scene is set
	var main_scene = ProjectSettings.get_setting("application/run/main_scene")
	if main_scene == "":
		printerr("FAIL: No main scene configured")
		ok = false
	else:
		print("OK: Main scene = ", main_scene)

	# 2. Check mcp_runtime autoload
	var autoloads = ProjectSettings.get_setting("autoload/mcp_runtime")
	if autoloads == null or autoloads == "":
		printerr("FAIL: mcp_runtime autoload not registered")
		ok = false
	else:
		print("OK: mcp_runtime autoload registered")

	# 3. Check built-in InputMap actions
	var required_actions = [
		"ui_accept", "ui_cancel", "ui_up", "ui_down",
		"ui_left", "ui_right", "ui_select",
		"ui_focus_next", "ui_focus_prev"
	]
	for action in required_actions:
		if not InputMap.has_action(action):
			printerr("FAIL: InputMap action '", action, "' is missing")
			ok = false

	if ok:
		for action in required_actions:
			print("OK: InputMap action '", action, "' present")

	return ok

var result = preflight()
print("Preflight result: ", "PASS" if result else "FAIL")
return result
```
