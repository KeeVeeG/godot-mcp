# Prerequisites for Script Tools Test Plan

> **Source plan:** `server/src/test_plans/script_test_plan.md`
> **Prereq extraction date:** 2026-07-08
> **Total test scenarios:** 109 across 9 tools

---

## Required Project State

- A Godot 4.x project with the MCP plugin **active** and connected to the MCP server (WebSocket bridge operational).
- Project root at `res://` with standard Godot project structure (`project.godot` exists).
- The `res://scripts/` directory tree exists with subdirectories `characters/`, `characters/enemies/`.
- Write access to `res://scripts/` and `res://` (must be able to create/delete files).
- For the "read-only location" test: `res://addons/readonly/` directory exists with restricted write permissions (simulated or real addon directory).
- For "empty project" test: a project variant with **zero** GDScript files anywhere under `res://`.
- For "many scripts" test: a project variant with **100+** GDScript files distributed across at least 2-3 directory depths.

---

## Required Scenes

### Scene A — Player + UI (for `attach_script` tests)

Open in the editor. File: `res://scenes/main.tscn`

```
Node2D (root, name: "Game")
├── Node2D (name: "Player")          ← has script res://scripts/player.gd attached BEFORE test
├── Sprite2D (name: "Sprite2D")      ← no script attached
├── Node2D (name: "A")               ← no script attached
├── Node2D (name: "B")               ← no script attached
└── Node2D (name: "Enemies")
    └── Node2D (name: "Goblin")      ← no script attached, nested 2 levels deep
```

### Scene B — Node with existing script (for overwrite/replace tests)

Open in the editor. File: `res://scenes/test_overwrite.tscn`

```
Node2D (root)
└── Node2D (name: "Player")          ← has script res://scripts/referenced.gd attached
```

### Scene C — Empty root (for root attachment test)

Open in the editor. File: `res://scenes/empty_root.tscn`

```
Node2D (root, no name set / default name)
```

---

## Required Resources

### Scripts (must exist on disk)

| # | File Path | Contents | Purpose |
|---|-----------|----------|---------|
| 1 | `res://scripts/player.gd` | `extends Node2D\n\nvar speed = 100\n\nfunc _ready():\n    print('debug')\n    pass\n\n# TODO: implement\n\nfunc old_method():\n    print('old')\n    return` | `read_script` happy path; `edit_script` scenarios 1–4; `attach_script` happy path |
| 2 | `res://main.gd` | `extends Node\n\nfunc _ready():\n    pass` | `read_script` root-level test; `attach_script` root test |
| 3 | `res://scripts/characters/enemies/boss.gd` | `extends CharacterBody2D\n\nfunc _ready():\n    pass` | `read_script` deeply nested path test |
| 4 | `res://scripts/existing.gd` | `extends Node\n\nfunc _ready():\n    pass` | `create_script` overwrite test (scenario 7) |
| 5 | `res://scripts/to_delete.gd` | `extends Node\n\nfunc _ready():\n    pass` | `delete_script` happy path |
| 6 | `res://scripts/characters/enemies/temp.gd` | `extends Node\n\nfunc _ready():\n    pass` | `delete_script` nested path test |
| 7 | `res://temp.gd` | `extends Node\n\nfunc _ready():\n    pass` | `delete_script` root-level test |
| 8 | `res://scripts/referenced.gd` | `extends Node2D\n\nfunc _ready():\n    print('referenced')\n    pass` | `delete_script` dangling-reference test; `attach_script` overwrite test — **attached to Player node in Scene B** |
| 9 | `res://scripts/valid.gd` | `extends Node\n\nfunc _ready():\n    pass\n\nfunc get_value() -> int:\n    return 42` | `validate_script` happy path (no syntax errors) |
| 10 | `res://scripts/broken.gd` | `extends Node\n\nfunc _ready(var x):\n    pass` | `validate_script` syntax error test — `_ready()` in GDScript does not accept parameters |
| 11 | `res://scripts/no_extends.gd` | `func _ready():\n    pass` | `validate_script` missing `extends` test |
| 12 | `res://scripts/unused_var.gd` | `extends Node\n\nfunc _ready():\n    var x = 10\n    pass` | `validate_script` unused variable warning test |
| 13 | `res://scripts/truly_empty.gd` | (empty file, 0 bytes) | `validate_script` edge case — completely empty |
| 14 | `res://scripts/huge.gd` | Valid GDScript ~10,000 lines of `func dummy_NNN():\n    pass\n` with `extends Node` at top | `validate_script` large file test |
| 15 | `res://scripts/character_body.gd` | `extends CharacterBody2D\n\nfunc _ready():\n    pass` | `attach_script` type mismatch test — extends CharacterBody2D, attached to Sprite2D node |
| 16 | `res://scripts/enemy_ai.gd` | `extends Node2D\n\nfunc _ready():\n    pass` | `attach_script` nested node test |
| 17 | `res://scripts/shared.gd` | `extends Node2D\n\nfunc _ready():\n    pass` | `attach_script` multi-node test — attach to nodes A and B |
| 18 | `res://scripts/new_behavior.gd` | `extends Node2D\n\nfunc _ready():\n    pass` | `attach_script` overwrite test |
| 19 | `res://scripts/main.gd` | `extends Node2D\n\nfunc _ready():\n    pass` | `attach_script` scene root test |

### Non-script files (for negative tests)

| # | File Path | Contents | Purpose |
|---|-----------|----------|---------|
| 1 | `res://scripts/player.txt` | `this is not a GDScript file` | `read_script` wrong extension test; also searchable text |
| 2 | `res://scenes/main.tscn` | Valid scene file referencing the node hierarchy from Scene A | `read_script` non-script file test; `delete_script` non-script file test; `validate_script` non-GDScript file test; `search_in_files` .tscn pattern test |

### Files that must NOT exist

| # | Path | Purpose |
|---|------|---------|
| 1 | `res://scripts/does_not_exist.gd` | `read_script` error-handling test; `validate_script` error-handling test |
| 2 | `res://scripts/already_gone.gd` | `delete_script` double-delete test |
| 3 | `res://scripts/nonexistent.gd` | `edit_script` error-handling test |
| 4 | `res://scripts/missing.gd` | `attach_script` missing script test |

---

## Required Editor/Game State

- **Play mode**: OFF (all tests operate in editor mode; no runtime tools in this plan).
- **Editor layout**: Any standard layout (not critical for these tests).
- **Open scene**: Scene A (`res://scenes/main.tscn`) must be open in the editor for `attach_script` tests.
- **Script editor state (for `get_open_scripts`)**:
  - State 1: Several scripts open — `res://scripts/player.gd`, `res://scripts/enemy_ai.gd`, `res://scripts/valid.gd` (3 open scripts).
  - State 2: No scripts open in the script editor (close all tabs).
  - State 3: 20+ scripts open in the editor for the "many open scripts" scenario.
- **Node selected in editor**: Not critical; any or none.
- **Breakpoints**: None required (no debugging tools in this plan).

---

## Required Settings/Config

### Project Settings (`project.godot`)
- Standard 2D project (at minimum).
- Default settings are acceptable — no custom overrides required for these tests.

### Input Actions
- None required (no input simulation in this plan).

### Autoloads
- Only the standard MCP plugin autoloads (`mcp_runtime.gd` at `res://addons/godot_mcp/services/mcp_runtime.gd`) — already present from plugin installation.

### Collision Layers
- None required.

### Tool Config (`godot_mcp_config.json`)
- Default (all script tools enabled). No tool disabled.

---

## Required External State

- **Godot Editor**: Open with the test project loaded.
- **MCP Plugin**: Active and connected to the MCP server.
- **MCP Server**: Running and connected to the Godot plugin via WebSocket.
- **Addons**: No custom addons required beyond the MCP plugin itself.
- **Git**: Not required.
- **Network**: Localhost WebSocket on auto-negotiated port (6505–6514), no firewall blocking.

---

## Setup Script

Run this GDScript in the Godot editor (via `execute_editor_script`) to create all required files and directories, or invoke individual operations via MCP tools.

```gdscript
# Setup script for script_test_plan.md prerequisites
# Execute in the Godot editor before running script tool tests.
# Assumes a clean 2D project with MCP plugin active.

@tool
extends EditorScript

func _run() -> void:
	# ── Directories ──────────────────────────────────────────────
	var dirs: Array[String] = [
		"res://scripts",
		"res://scripts/characters",
		"res://scripts/characters/enemies",
		"res://scenes",
		"res://addons/readonly",
	]
	for d in dirs:
		DirAccess.make_dir_recursive_absolute(d)
		print("Ensured directory: ", d)

	# ── Scripts (must exist) ─────────────────────────────────────
	var scripts: Dictionary = {
		"res://scripts/player.gd": """extends Node2D

var speed = 100

func _ready():
    print('debug')
    pass

# TODO: implement

func old_method():
    print('old')
    return""",

		"res://main.gd": """extends Node

func _ready():
    pass""",

		"res://scripts/characters/enemies/boss.gd": """extends CharacterBody2D

func _ready():
    pass""",

		"res://scripts/existing.gd": """extends Node

func _ready():
    pass""",

		"res://scripts/to_delete.gd": """extends Node

func _ready():
    pass""",

		"res://scripts/characters/enemies/temp.gd": """extends Node

func _ready():
    pass""",

		"res://temp.gd": """extends Node

func _ready():
    pass""",

		"res://scripts/referenced.gd": """extends Node2D

func _ready():
    print('referenced')
    pass""",

		"res://scripts/valid.gd": """extends Node

func _ready():
    pass

func get_value() -> int:
    return 42""",

		"res://scripts/broken.gd": """extends Node

func _ready(var x):
    pass""",

		"res://scripts/no_extends.gd": """func _ready():
    pass""",

		"res://scripts/unused_var.gd": """extends Node

func _ready():
    var x = 10
    pass""",

		"res://scripts/truly_empty.gd": "",

		"res://scripts/character_body.gd": """extends CharacterBody2D

func _ready():
    pass""",

		"res://scripts/enemy_ai.gd": """extends Node2D

func _ready():
    pass""",

		"res://scripts/shared.gd": """extends Node2D

func _ready():
    pass""",

		"res://scripts/new_behavior.gd": """extends Node2D

func _ready():
    pass""",

		"res://scripts/main.gd": """extends Node2D

func _ready():
    pass""",

		"res://scripts/attached.gd": """extends Node2D

func _ready():
    pass""",
	}

	for path in scripts:
		var f = FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string(scripts[path])
			f.close()
			print("Created: ", path)
		else:
			printerr("FAILED to create: ", path, " — error: ", FileAccess.get_open_error())

	# ── Huge script (~10K lines) ─────────────────────────────────
	var huge_f = FileAccess.open("res://scripts/huge.gd", FileAccess.WRITE)
	if huge_f:
		huge_f.store_string("extends Node\n\n")
		for i in range(10000):
			huge_f.store_string("func dummy_%d():\n    pass\n\n" % i)
		huge_f.close()
		print("Created: res://scripts/huge.gd (~10K lines)")

	# ── Non-script file ──────────────────────────────────────────
	var txt_f = FileAccess.open("res://scripts/player.txt", FileAccess.WRITE)
	if txt_f:
		txt_f.store_string("this is not a GDScript file")
		txt_f.close()
		print("Created: res://scripts/player.txt")

	# ── Read-only directory simulation ────────────────────────────
	# Note: On most OS, Godot cannot set file permissions.
	# Mark as "readonly" by creating a file that the test expects to fail on write.
	var ro_f = FileAccess.open("res://addons/readonly/script.gd", FileAccess.WRITE)
	if ro_f:
		ro_f.store_string("extends Node\n\nfunc _ready():\n    pass")
		ro_f.close()
		# On Windows, mark the directory read-only via OSFiles
		if OS.get_name() == "Windows":
			OS.execute("attrib", ["+R", ProjectSettings.globalize_path("res://addons/readonly/script.gd")])
		print("Created: res://addons/readonly/script.gd (intended read-only)")

	# ── Scenes ───────────────────────────────────────────────────
	# Scene A: Player + hierarchy
	create_scene_a()
	# Scene B: Node with existing script
	create_scene_b()
	# Scene C: Empty root
	create_scene_c()

	# ── Final refresh ────────────────────────────────────────────
	EditorInterface.get_resource_filesystem().scan()
	print("\n=== Prerequisites setup complete ===")


func create_scene_a() -> void:
	var root := Node2D.new()
	root.name = "Game"

	var player := Node2D.new()
	player.name = "Player"
	player.set_script(load("res://scripts/player.gd"))
	root.add_child(player)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	root.add_child(sprite)

	var node_a := Node2D.new()
	node_a.name = "A"
	root.add_child(node_a)

	var node_b := Node2D.new()
	node_b.name = "B"
	root.add_child(node_b)

	var enemies := Node2D.new()
	enemies.name = "Enemies"
	root.add_child(enemies)

	var goblin := Node2D.new()
	goblin.name = "Goblin"
	enemies.add_child(goblin)

	pack_and_save(root, "res://scenes/main.tscn")


func create_scene_b() -> void:
	var root := Node2D.new()
	root.name = "TestOverwrite"

	var player := Node2D.new()
	player.name = "Player"
	player.set_script(load("res://scripts/referenced.gd"))
	root.add_child(player)

	pack_and_save(root, "res://scenes/test_overwrite.tscn")


func create_scene_c() -> void:
	var root := Node2D.new()
	root.name = "EmptyRoot"
	pack_and_save(root, "res://scenes/empty_root.tscn")


func pack_and_save(node: Node, path: String) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(node)
	if err != OK:
		printerr("Failed to pack scene ", path, " — error: ", err)
		return
	err = ResourceSaver.save(packed, path)
	if err != OK:
		printerr("Failed to save scene ", path, " — error: ", err)
	else:
		print("Created scene: ", path)
```

---

## Quick Reference: What Each Test Scenario Needs

| Tool | Scenario | Key Prerequisite |
|------|----------|-----------------|
| `list_scripts` | 1-4, 10 | Project has GDScript files at various depths |
| `list_scripts` | 9 | Empty project (no .gd files) |
| `list_scripts` | 10 | 100+ scripts in project |
| `read_script` | 1 | `res://scripts/player.gd` exists |
| `read_script` | 2 | `res://main.gd` exists |
| `read_script` | 3 | `res://scripts/characters/enemies/boss.gd` exists |
| `read_script` | 5 | `res://scenes/main.tscn` exists |
| `read_script` | 6 | `res://scripts/player.txt` exists |
| `create_script` | 7 | `res://scripts/existing.gd` exists |
| `create_script` | 18 | `res://addons/readonly/` exists, write-protected |
| `delete_script` | 1 | `res://scripts/to_delete.gd` exists |
| `delete_script` | 2 | `res://scripts/characters/enemies/temp.gd` exists |
| `delete_script` | 3 | `res://temp.gd` exists |
| `delete_script` | 6 | `res://scenes/main.tscn` exists |
| `delete_script` | 7 | `res://scripts/referenced.gd` attached to a node in Scene B |
| `delete_script` | 11 | `res://scripts/attached.gd` attached to a node in currently open scene |
| `edit_script` | 1-4 | `res://scripts/player.gd` contains `var speed = 100`, `# TODO: implement`, `func old_method()`, `print('debug')` |
| `attach_script` | 1 | Scene A open; "Player" node exists; `res://scripts/player.gd` exists |
| `attach_script` | 2 | Scene C open (empty root); `res://scripts/main.gd` exists |
| `attach_script` | 3 | Scene A open; "Enemies/Goblin" node exists; `res://scripts/enemy_ai.gd` exists |
| `attach_script` | 4 | Scene B open; "Player" node already has script attached; `res://scripts/new_behavior.gd` exists |
| `attach_script` | 7 | Scene A open; "Sprite2D" node exists; `res://scripts/character_body.gd` exists |
| `attach_script` | 13 | No scene open in editor |
| `attach_script` | 14 | Scene A open; nodes "A" and "B" exist; `res://scripts/shared.gd` exists |
| `get_open_scripts` | 1 | 3+ scripts open in script editor |
| `get_open_scripts` | 2 | No scripts open in script editor |
| `get_open_scripts` | 3 | 20+ scripts open in script editor |
| `validate_script` | 1 | `res://scripts/valid.gd` has no syntax errors |
| `validate_script` | 2 | `res://scripts/broken.gd` has syntax error |
| `validate_script` | 3 | `res://scripts/no_extends.gd` exists (no `extends` line) |
| `validate_script` | 4 | `res://scripts/unused_var.gd` has unused variable |
| `validate_script` | 6 | `res://scenes/main.tscn` exists |
| `validate_script` | 7 | `res://scripts/truly_empty.gd` is 0 bytes |
| `validate_script` | 10 | `res://scripts/huge.gd` ~10K lines |
| `search_in_files` | 1 | Files containing `extends Node` exist |
| `search_in_files` | 2 | .gd files containing `func _ready` exist |
| `search_in_files` | 3 | .tscn files referencing `script = ExtResource` exist |
| `search_in_files` | 4 | Files containing `TODO` exist |
| `search_in_files` | 5 | Files referencing `CharacterBody2D` exist |
| `search_in_files` | 6 | No file contains `xyzzy_no_such_text_anywhere` |
| `search_in_files` | 15 | Project has many files; `pass` appears broadly |

---

## Notes

1. **Overwrite behavior is implementation-dependent** for `create_script` scenario 7, `delete_script` scenario 11, and `attach_script` scenario 4. The prereqs simply ensure the file/node exists so the test can be run regardless of implementation.

2. **Read-only preconditions** (scenario 18 of `create_script`): Godot's `FileAccess` does not guarantee OS-level permission enforcement. On most desktop platforms, the "read-only" test may succeed unless the test harness explicitly chmods or attribs the file.

3. **The setup script** uses `EditorScript` (`@tool`) and `FileAccess`. In Godot 4.x, `FileAccess` has replaced `File` (Godot 3.x). If running on a different version, adjust accordingly.

4. **Cleanup after tests**: The test suite should clean up scripts created during `create_script` tests (scenarios 1–6, 11–12, 16) and restore `res://scripts/existing.gd` if it was overwritten. The setup script above only creates the **pre-existing** files; test-created files must be handled per test.
