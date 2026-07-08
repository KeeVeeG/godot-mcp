# Prerequisites for Editor Tools Test Plan

**Source plan:** `server/src/test_plans/editor_test_plan.md`
**Generated:** 2026-07-08

---

## Required Project State

- **Godot 4.x project** (tested with 4.7) — any project type (2D is sufficient, 3D also works)
- **Godot MCP addon** installed and active at `addons/godot_mcp/` (required for all tools; `reload_plugin` Scenarios 1–3 explicitly depend on it)
- **`mcp_runtime.gd` autoload** registered in `project.godot` as `mcp_runtime="*res://addons/godot_mcp/services/mcp_runtime.gd"` — required for all `get_game_screenshot` scenarios (runtime tools need the autoload loaded at game start)
- **Main scene configured** — any playable scene set as the project main scene (needed for `play_scene` used by `get_game_screenshot` Scenario 1 and integration Scenario D with scene transitions)
- **A second scene** that can be loaded during gameplay — needed for `get_game_screenshot` Scenario 4 (scene transition test). At minimum, a second `.tscn` file at e.g. `res://scenes/second.tscn` that the test can switch to at runtime
- **`res://screenshots/` directory** — must exist on disk for all `get_editor_screenshot` and `get_game_screenshot` custom-path tests (Scenarios 2–8 for editor, Scenarios 2, 6 for game). The tool *may* autocreate it, but tests should not rely on that behavior

---

## Required Scenes

### 1. Primary test scene (`res://scenes/test_editor.tscn`)

Open in the editor. Root node type: `Node2D` (or `Node`). Contains:

```
test_editor (Node2D root)
├── Player (Node2D)                                    ← get_signals S1, S2; execute_editor_script S3
│   └── Sprite2D                                       ← get_signals S2
├── MyButton (Button)                                  ← get_signals S4 (must have pressed signal connected)
├── CustomSignalNode (Node)                            ← get_signals S9
├── BrokenScriptNode (Node)                            ← get_editor_errors S2
├── A (Node)                                           ← get_signals S8
│   └── B (Node)
│       └── C (Node)
│           └── D (Node)
│               └── E (Node)
│                   └── F (Node)
│                       └── G (Node)
│                           └── H (Node)
│                               └── I (Node)
│                                   └── J (Node)
│                                       └── K (Node)
```

**Specific node configurations:**

- **`MyButton` (type `Button`):** Its `pressed` signal must be connected to a method on another node in the scene (e.g., connect `MyButton.pressed` → `Player._on_button_pressed`). The target method must exist in an attached script.
- **`CustomSignalNode` (type `Node`):** Must have a GDScript attached at `res://scripts/custom_signal_node.gd` that declares `signal my_custom_signal(arg1, arg2)`.
- **`BrokenScriptNode` (type `Node`):** Must have a GDScript attached at `res://scripts/broken.gd` that contains a deliberate syntax error (e.g., `var x = ;`).
- **`Player` (type `Node2D`):** Should have a simple GDScript attached at `res://scripts/player.gd` with at least a `_on_button_pressed()` method (for the button signal connection).
- **`A` through `K`:** Plain `Node` instances nested 11 levels deep. No scripts needed. Used for `get_signals` Scenario 8 deep-path test.

### 2. Secondary scene (`res://scenes/second.tscn`)

A simple scene with root `Node2D` and a single `Label` child (or any minimal layout). Used for scene-transition tests in `get_game_screenshot` Scenario 4.

---

## Required Resources

### Scripts

| Path | Purpose | Contents |
|------|---------|----------|
| `res://scripts/player.gd` | Attached to `Player` node | `extends Node2D` with at least a `func _on_button_pressed(): print("button pressed")` method. Needed for `get_signals` S4 signal connection target and `execute_editor_script` S3 (root node name query). |
| `res://scripts/custom_signal_node.gd` | Attached to `CustomSignalNode` | `extends Node` with `signal my_custom_signal(arg1, arg2)` declaration. Needed for `get_signals` S9. |
| `res://scripts/broken.gd` | Attached to `BrokenScriptNode` | `extends Node` with a deliberate syntax error like `var x = ;`. Needed for `get_editor_errors` S2 and integration Scenario D. |

### Directories

| Path | Purpose |
|------|---------|
| `res://screenshots/` | Base directory for screenshot save-path tests |
| `res://screenshots/editor/` | Nested subdirectory for `get_editor_screenshot` Scenario 3 |

### Other resources

- No specific `.tres`, textures, materials, shaders, or audio files are needed for these 9 editor tools.
- All test scenarios are self-contained and use only nodes + scripts + the filesystem directories listed above.

---

## Required Editor/Game State

| State | Required By | Notes |
|-------|-------------|-------|
| **Primary test scene open in editor** | `get_editor_errors` (all), `get_signals` (all), `execute_editor_script` S3, integration Scenarios B, D | The scene must be the active/current scene for node-path lookups and script validation |
| **Game running** (via `play_scene`) | `get_game_screenshot` S1, S2, S4, S5, S6 | Runtime tools require an active game session with `mcp_runtime.gd` loaded |
| **Game NOT running** (for negative test) | `get_game_screenshot` S3 | Tests that the tool correctly errors when the game is stopped |
| **Nothing selected in editor** | `execute_editor_script` S4 (returns 0) | Tests that selection count is zero when nothing is selected; test can also select a node to verify count = 1 |
| **Unsaved script changes in editor** | `reload_project` S3 | Open a script, make an edit without saving, then reload |

---

## Required Settings/Config

### Autoloads
- `mcp_runtime.gd` registered as an autoload with the path `res://addons/godot_mcp/services/mcp_runtime.gd` (NOT the editor-only `*` prefix variant — it must load at runtime for game screenshot capture to work)

### Project Settings
- **Main scene:** Set to `res://scenes/test_editor.tscn` (or whichever scene is used for gameplay tests)
- **No special input actions, collision layers, or other custom project settings** are required for these 9 editor tools

### Addons
- **godot_mcp** addon must be enabled in Project Settings → Plugins (required by `reload_plugin` and all tools)

---

## Setup Script

Run this GDScript via `execute_editor_script` to create the test scene and all its dependencies in one shot. This script assumes a fresh Godot project with the MCP addon already active.

```gdscript
# === 1. Create directories ===
DirAccess.make_dir_recursive_absolute("res://screenshots/editor")

# === 2. Create scripts ===

# player.gd
var player_script = FileAccess.open("res://scripts/player.gd", FileAccess.WRITE)
player_script.store_string("""extends Node2D

func _on_button_pressed():
	print("button pressed")
""")
player_script.close()

# custom_signal_node.gd
var csn_script = FileAccess.open("res://scripts/custom_signal_node.gd", FileAccess.WRITE)
csn_script.store_string("""extends Node

signal my_custom_signal(arg1, arg2)
""")
csn_script.close()

# broken.gd (deliberate syntax error)
var broken_script = FileAccess.open("res://scripts/broken.gd", FileAccess.WRITE)
broken_script.store_string("""extends Node

var x = ;
""")
broken_script.close()

# === 3. Create primary test scene ===
var root = Node2D.new()
root.name = "test_editor"
get_editor_interface().get_edited_scene_root().add_child(root)
root.owner = get_editor_interface().get_edited_scene_root()

# Player node
var player = Node2D.new()
player.name = "Player"
root.add_child(player)
player.owner = get_editor_interface().get_edited_scene_root()
var player_script_res = load("res://scripts/player.gd")
player.set_script(player_script_res)

# Player/Sprite2D
var sprite = Sprite2D.new()
sprite.name = "Sprite2D"
player.add_child(sprite)
sprite.owner = get_editor_interface().get_edited_scene_root()

# MyButton with connected signal
var button = Button.new()
button.name = "MyButton"
root.add_child(button)
button.owner = get_editor_interface().get_edited_scene_root()
button.pressed.connect(player._on_button_pressed)

# CustomSignalNode
var csn = Node.new()
csn.name = "CustomSignalNode"
root.add_child(csn)
csn.owner = get_editor_interface().get_edited_scene_root()
var csn_script_res = load("res://scripts/custom_signal_node.gd")
csn.set_script(csn_script_res)

# BrokenScriptNode
var broken_node = Node.new()
broken_node.name = "BrokenScriptNode"
root.add_child(broken_node)
broken_node.owner = get_editor_interface().get_edited_scene_root()
var broken_script_res = load("res://scripts/broken.gd")
broken_node.set_script(broken_script_res)

# Deep hierarchy: A → B → C → D → E → F → G → H → I → J → K
var parent = root
for letter in ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K"]:
	var child = Node.new()
	child.name = letter
	parent.add_child(child)
	child.owner = get_editor_interface().get_edited_scene_root()
	parent = child

# Save the scene
var packed = PackedScene.new()
packed.pack(root)
ResourceSaver.save(packed, "res://scenes/test_editor.tscn")

# === 4. Create secondary scene for transition tests ===
var second_root = Node2D.new()
second_root.name = "second_scene"
var label = Label.new()
label.name = "Label"
label.text = "Second Scene"
second_root.add_child(label)
label.owner = second_root

var packed2 = PackedScene.new()
packed2.pack(second_root)
ResourceSaver.save(packed2, "res://scenes/second.tscn")
```

**Post-setup manual steps:**

1. Set `res://scenes/test_editor.tscn` as the project main scene (Project Settings → Application → Run → Main Scene)
2. Verify the `mcp_runtime.gd` autoload is present in `project.godot` (should be auto-registered by the addon)
3. Open `res://scenes/test_editor.tscn` in the editor to make it the active scene
4. Run `get_editor_errors` once to confirm the broken script is detected

---

## Scenario-to-Prerequisite Mapping

| Tool | Scenario | Prerequisites |
|------|----------|---------------|
| `get_editor_errors` | S1 | Test scene open (no errors expected on clean nodes) |
| | S2 | `BrokenScriptNode` with `broken.gd` attached |
| | S3 | Test scene open (idempotency) |
| | S4 | Test scene open |
| `get_editor_screenshot` | S1 | Editor open (any state) |
| | S2 | `res://screenshots/` directory exists |
| | S3 | `res://screenshots/editor/` directory exists |
| | S4–S8 | `res://screenshots/` directory; various path edge cases |
| `get_game_screenshot` | S1 | Game running (main scene playable), `mcp_runtime.gd` autoload |
| | S2 | Game running + `res://screenshots/` directory |
| | S3 | Game NOT running (negative test) |
| | S4 | Game running + second scene available for transition |
| | S5 | Game running |
| | S6 | Game running + `res://screenshots/` directory |
| `execute_editor_script` | S1–S2 | Any project state (print/compute only) |
| | S3 | Test scene open with root node (needs `.get_edited_scene_root()`) |
| | S4 | Editor open (reads selection) |
| | S5–S13 | Any project state |
| `clear_output` | S1 | Output must have content (run `execute_editor_script` with `print()` first) |
| | S2–S4 | Any state |
| `get_signals` | S1 | `Player` node at root level of open scene |
| | S2 | `Player/Sprite2D` path exists |
| | S3 | Test scene open (root node accessible via empty string path) |
| | S4 | `MyButton` with `pressed` signal connected to `Player._on_button_pressed` |
| | S5 | (validation — no pre-req) |
| | S6–S7 | (negative tests — no pre-req) |
| | S8 | Deep hierarchy `A/.../K` exists |
| | S9 | `CustomSignalNode` with `custom_signal_node.gd` attached |
| `reload_plugin` | S1–S3 | MCP addon installed and active |
| `reload_project` | S1–S2 | Standard project |
| | S3 | Script open in editor with unsaved changes |
| `get_output_log` | S1–S2 | Some prior output generated |
| | S3 | Run `execute_editor_script` with `printerr("test error")` first |
| | S4 | Run scripts generating `print`, `printerr`, and `push_warning` first |
| | S5 | Any state |
| | S6 | Run script generating 10,000+ lines of output first |
| Integration A | | All editor tools functional (no extra pre-reqs) |
| Integration B | | Scene with a node that has connectable signals (same as `get_signals` S4) |
| Integration C | | Editor open (visual diff test) |
| Integration D | | `BrokenScriptNode` with broken script; ability to delete/fix script externally |
