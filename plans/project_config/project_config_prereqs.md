# Prerequisites for project_config_test_plan.md

**Source plan:** `server/src/test_plans/project_config_test_plan.md`
**Generated:** 2026-07-08
**Scope:** 12 tools covering project settings, input map, and autoloads

---

## Required Project State

- A **Godot 4.x project** (any type — empty/default is sufficient; these tests only touch `project.godot` and InputMap).
- The **Godot MCP addon must be installed and active** (provides the `mcp_runtime` autoload referenced by `get_autoloads` and `remove_autoload_config` tests).
- The **MCP server must be running and connected** to the Godot editor via WebSocket.
- The project must have its **default built-in input actions** intact (at minimum: `ui_accept`, `ui_cancel`, `ui_up`, `ui_down`, `ui_left`, `ui_right`). These ship with every new Godot project.
- The project's `project.godot` must be in its default/sane state — no prior mutations that would interfere with `reset_project_setting` verification.

---

## Required Resources

### GDScript stub files (minimal — just need to exist for autoload registration)

The `add_autoload_config` tool requires the target script file to already exist on disk before registering it as an autoload. The following stub scripts are needed:

| File | Used By | Notes |
|------|---------|-------|
| `res://autoload/test_global.gd` | `add_autoload_config` scenarios 1, 10, 14; `reorder_autoloads` scenario 2 | Happy-path autoload target |
| `res://autoload/disabled_global.gd` | `add_autoload_config` scenario 2 (`enabled: false`) | Disabled autoload |
| `res://autoload/explicit.gd` | `add_autoload_config` scenario 14 (`enabled: true` explicit) | Explicit enabled |
| `res://autoload/other.gd` | `add_autoload_config` scenario 10 (duplicate name) | Second script for duplicate test |
| `res://autoload/test.gd` | `add_autoload_config` scenarios 8, 11 | Used with invalid param tests (script must exist even though params are invalid at MCP level) |
| `res://autoload/test_remove.gd` | `remove_autoload_config` scenario 1 | Target for `RemoveMeGlobal` removal test |
| `res://autoload/service_a.gd` | Cross-tool Scenario C | `ServiceA` autoload (enabled) |
| `res://autoload/service_b.gd` | Cross-tool Scenario C | `ServiceB` autoload (disabled) |
| `res://autoload/a.gd` | `reorder_autoloads` scenario 1 | Autoload `A` |
| `res://autoload/b.gd` | `reorder_autoloads` scenario 1 | Autoload `B` |
| `res://autoload/c.gd` | `reorder_autoloads` scenario 1 | Autoload `C` |

**Each stub needs only a bare minimum GDScript file — an empty `extends Node` is sufficient:**

```gdscript
extends Node
```

### Scene file

| File | Used By | Notes |
|------|---------|-------|
| `res://scenes/ui_overlay.tscn` | `add_autoload_config` scenario 3 | Autoload pointing to a scene (not script). Root node can be any `Control` or `Node2D`. |

**Minimal scene content:**
```
[gd_scene load_steps=0 format=3 uid="uid://..."]
[node name="UIOverlay" type="Control"]
```

---

## Required Editor/Game State

- **Editor must be in idle state** (not in play mode). All 12 tools operate on editor-side configuration (`project.godot`, InputMap, autoload registry) — none require the game to be running.
- **No specific editor layout or tool selection required** — tools are layout-agnostic.
- **No breakpoints required**.

---

## Required Settings/Config

- All tests assume a **default Godot project configuration**. No custom project settings need to be pre-applied.
- The following **default project settings must be at their factory values** before running `reset_project_setting` tests:
  - `application/config/name` — must be at default (typically the project folder name).
  - `display/window/size/viewport_width` — must be at default (typically `1152`).
- The following **autoload must already be registered** (installed by the Godot MCP plugin):
  - `mcp_runtime` → `res://addons/godot_mcp/services/mcp_runtime.gd` (used by `get_autoloads` scenario 1 and `remove_autoload_config` scenario 4)

---

## Test Execution Order Constraints

Some scenarios have **runtime pre-conditions** that must be set up by prior tool calls during the test run:

### Prerequisite chains (must execute in order)

| Test | Prerequisite | Setup Tool Call |
|------|-------------|-----------------|
| `reset_project_setting` scenario 1 | `application/config/name` = `"ModifiedName"` | `set_project_setting_config({ key: "application/config/name", value: "ModifiedName" })` |
| `reset_project_setting` scenario 2 | `display/window/size/viewport_width` ≠ default | `set_project_setting_config({ key: "display/window/size/viewport_width", value: 800 })` |
| `remove_input_action` scenario 1 | `test_remove_me` action exists | `add_input_action({ action: "test_remove_me", events: [{ type: "key", keycode: "KEY_A" }] })` |
| `remove_input_action` scenario 4 | `test_recreate` action exists | `add_input_action({ action: "test_recreate", events: [{ type: "key", keycode: "KEY_SPACE" }] })` |
| `reorder_autoloads` scenario 1 | Autoloads `A`, `B`, `C` registered | Three `add_autoload_config` calls (requires `res://autoload/a.gd`, `b.gd`, `c.gd` to exist) |
| Cross-tool Scenario C | Autoloads `ServiceA`, `ServiceB` registered | `add_autoload_config` for both (requires `res://autoload/service_a.gd`, `service_b.gd`) |

### Destructive tests (restore state after)

| Test | What It Destroys | Restore Action |
|------|-----------------|----------------|
| `set_input_map` scenario 1 | Replaces entire input map with only `jump` | `set_input_map` with saved original map |
| `set_input_map` scenario 6 | Clears all input actions (`actions: {}`) | `set_input_map` with saved original map |
| `remove_input_action` scenario 2 | Removes built-in `ui_accept` | `add_input_action` to restore `ui_accept` |
| `remove_autoload_config` scenario 4 | Removes `mcp_runtime` autoload | `add_autoload_config` to restore `mcp_runtime` |
| `set_project_setting_config` (all) | Mutates `project.godot` | `reset_project_setting` or manual restore |

---

## Test Isolation Notes

- **Validation error tests** (wrong types, missing params, out-of-range values) have **zero prerequisites** — they only test the MCP server's Zod schema validation and never reach Godot. These can run independently.
- **~45% of scenarios** are pure validation tests requiring no project state beyond an active Godot+MCP connection.
- **Autoload tests are the most prerequisite-heavy** — they need 11 stub `.gd` files and 1 stub `.tscn` file to exist before tool calls execute.
- The `mcp_runtime` autoload is a **hard prerequisite** for `get_autoloads` scenario 1 and `remove_autoload_config` scenario 4. If the MCP plugin is not installed, those tests must be skipped or adapted.

---

## Setup Script

Run this GDScript via `godot_execute_editor_script` to create all required stub files before executing the test plan:

```gdscript
@tool
extends EditorScript

func _run() -> void:
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("res://autoload"):
		dir.make_dir("res://autoload")
	if not dir.dir_exists("res://scenes"):
		dir.make_dir("res://scenes")

	var stub_scripts = [
		"res://autoload/test_global.gd",
		"res://autoload/disabled_global.gd",
		"res://autoload/explicit.gd",
		"res://autoload/other.gd",
		"res://autoload/test.gd",
		"res://autoload/test_remove.gd",
		"res://autoload/service_a.gd",
		"res://autoload/service_b.gd",
		"res://autoload/a.gd",
		"res://autoload/b.gd",
		"res://autoload/c.gd",
	]

	for path in stub_scripts:
		if not FileAccess.file_exists(path):
			var f = FileAccess.open(path, FileAccess.WRITE)
			f.store_string("extends Node\n")
			f.close()
			print("Created: ", path)
		else:
			print("Already exists: ", path)

	# Create minimal scene for ui_overlay.tscn
	var scene_path = "res://scenes/ui_overlay.tscn"
	if not FileAccess.file_exists(scene_path):
		var root = Control.new()
		root.name = "UIOverlay"
		var packed = PackedScene.new()
		packed.pack(root)
		ResourceSaver.save(packed, scene_path)
		root.free()
		print("Created: ", scene_path)
	else:
		print("Already exists: ", scene_path)

	print("=== Prerequisites setup complete ===")
```

**Alternative (MCP tool calls):**

If `godot_execute_editor_script` is unavailable, create each file individually with `godot_create_script` and `godot_create_scene`:

```
godot_create_script(path="res://autoload/test_global.gd", content="extends Node\n", base_class="Node")
godot_create_script(path="res://autoload/disabled_global.gd", content="extends Node\n", base_class="Node")
godot_create_script(path="res://autoload/explicit.gd", content="extends Node\n", base_class="Node")
godot_create_script(path="res://autoload/other.gd", content="extends Node\n", base_class="Node")
godot_create_script(path="res://autoload/test.gd", content="extends Node\n", base_class="Node")
godot_create_script(path="res://autoload/test_remove.gd", content="extends Node\n", base_class="Node")
godot_create_script(path="res://autoload/service_a.gd", content="extends Node\n", base_class="Node")
godot_create_script(path="res://autoload/service_b.gd", content="extends Node\n", base_class="Node")
godot_create_script(path="res://autoload/a.gd", content="extends Node\n", base_class="Node")
godot_create_script(path="res://autoload/b.gd", content="extends Node\n", base_class="Node")
godot_create_script(path="res://autoload/c.gd", content="extends Node\n", base_class="Node")
godot_create_scene(path="res://scenes/ui_overlay.tscn", root_node_type="Control")
```
