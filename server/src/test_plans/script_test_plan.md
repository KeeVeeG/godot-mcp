# Script Tools — Test Plan

**Source file:** `server/src/tools/script.ts`
**Shared types:** `server/src/tools/shared-types.ts`
**Number of tools:** 9
**Generated:** 2026-07-08

---

## Type Reference

| Zod schema | Underlying type | Description |
|---|---|---|
| `ScriptPath` | `z.string()` | Script file path, e.g. `'res://scripts/player.gd'` |
| `NodePath` | `z.string()` | Node path in scene tree, e.g. `'Player/Sprite2D'`, `''` for root |
| `GDScriptCode` | `z.string()` | GDScript source code |
| `SearchQuery` | `z.string()` | Search query string |

---

## Tool: `list_scripts`

**Description:** List all GDScript files in the project with class info
**Handler:** `callGodot(bridge, 'script/list')` — note: no args forwarded

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `max_depth` | number (int, positive) | No | `10` | Maximum directory depth to scan |

### Test Scenarios

#### Scenario 1: Happy path — list all scripts (no params)
- **Description:** List all GDScript files with default depth
- **Params:** `{}`
- **Expected result:** Success. Returns an array of GDScript file paths/metadata from the project, scanned up to depth 10.

#### Scenario 2: Happy path — explicit max_depth
- **Description:** List scripts with explicit `max_depth = 5`
- **Params:** `{ "max_depth": 5 }`
- **Expected result:** Success. Returns scripts scanned up to depth 5 only.

#### Scenario 3: Happy path — max_depth = 1 (root only)
- **Description:** List scripts only in the project root directory
- **Params:** `{ "max_depth": 1 }`
- **Expected result:** Success. Returns only scripts at depth 1 (direct children of `res://`).

#### Scenario 4: Happy path — large max_depth
- **Description:** List scripts with very large depth to ensure full project scan
- **Params:** `{ "max_depth": 999 }`
- **Expected result:** Success. Returns all scripts in the project (full recursive scan).

#### Scenario 5: Edge — max_depth = 0
- **Description:** Call with `max_depth = 0`
- **Params:** `{ "max_depth": 0 }`
- **Expected result:** Zod validation error. `max_depth` must be a positive integer (`z.number().int().positive()`).

#### Scenario 6: Edge — max_depth negative
- **Description:** Call with negative `max_depth`
- **Params:** `{ "max_depth": -1 }`
- **Expected result:** Zod validation error (positive integer required).

#### Scenario 7: Edge — max_depth is float
- **Description:** Call with a non-integer number for max_depth
- **Params:** `{ "max_depth": 5.5 }`
- **Expected result:** Zod validation error (integer required).

#### Scenario 8: Edge — max_depth is string
- **Description:** Call with a string value for max_depth
- **Params:** `{ "max_depth": "deep" }`
- **Expected result:** Zod validation error (number required).

#### Scenario 9: Edge — empty project (no scripts)
- **Description:** List scripts in a project with no .gd files
- **Params:** `{}`
- **Expected result:** Success. Returns an empty array or empty result.

---

## Tool: `read_script`

**Description:** Read the contents of a GDScript file
**Handler:** `callGodot(bridge, 'script/read', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `ScriptPath` (string) | **Yes** | — | Script file path (e.g. `'res://scripts/player.gd'`) |

### Test Scenarios

#### Scenario 1: Happy path — read an existing script
- **Description:** Read the contents of a known script file
- **Params:** `{ "path": "res://scripts/player.gd" }`
- **Expected result:** Success. Returns the full text content of the GDScript file.
- **Notes:** Requires a script to exist at this path. Create one first if needed.

#### Scenario 2: Edge — non-existent path
- **Description:** Read a script file that does not exist
- **Params:** `{ "path": "res://scripts/nonexistent_xyz.gd" }`
- **Expected result:** Error from Godot (file not found).

#### Scenario 3: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 4: Edge — empty path string
- **Description:** Call with an empty path
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot (invalid path).

#### Scenario 5: Edge — path is a directory
- **Description:** Pass a directory path instead of a file path
- **Params:** `{ "path": "res://scripts" }`
- **Expected result:** Error from Godot (path is not a file).

#### Scenario 6: Edge — path without .gd extension
- **Description:** Read a file that is not a GDScript (e.g., a .tscn scene)
- **Params:** `{ "path": "res://scenes/main.tscn" }`
- **Expected result:** May still return file contents (the tool reads any file text). Test to verify behavior.

#### Scenario 7: Edge — path with special characters / spaces
- **Description:** Read a script whose path contains spaces or Unicode
- **Params:** `{ "path": "res://scripts/my script.gd" }`
- **Expected result:** Should succeed if the file exists. Verify path encoding is handled correctly.

#### Scenario 8: Edge — absolute filesystem path (not res://)
- **Description:** Pass an absolute OS path instead of a `res://` path
- **Params:** `{ "path": "C:/Users/some_user/script.gd" }`
- **Expected result:** Error from Godot (path must use `res://` prefix or be relative to project).

---

## Tool: `create_script`

**Description:** Create a new GDScript file
**Handler:** `callGodot(bridge, 'script/create', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `ScriptPath` (string) | **Yes** | — | Path for the new script (e.g. `'res://scripts/player.gd'`) |
| `content` | `GDScriptCode` (string) | **Yes** | — | GDScript source code |
| `base_class` | string | No | — | Base class (e.g. `'CharacterBody2D'`) |

### Test Scenarios

#### Scenario 1: Happy path — minimum required params
- **Description:** Create a script with path and content, no base_class
- **Params:** `{ "path": "res://scripts/test_minimal.gd", "content": "extends Node\n\nfunc _ready():\n    pass\n" }`
- **Expected result:** Success. Script created at `res://scripts/test_minimal.gd` with default base class (likely `Node` or `RefCounted`).

#### Scenario 2: Happy path — with base_class
- **Description:** Create a script with an explicit base class
- **Params:** `{ "path": "res://scripts/test_character.gd", "content": "extends CharacterBody2D\n\nfunc _ready():\n    pass\n", "base_class": "CharacterBody2D" }`
- **Expected result:** Success. Script created with base type `CharacterBody2D`.

#### Scenario 3: Happy path — base_class = Node2D
- **Description:** Create a 2D node script
- **Params:** `{ "path": "res://scripts/test_node2d.gd", "content": "extends Node2D\n", "base_class": "Node2D" }`
- **Expected result:** Success. Script created with base type `Node2D`.

#### Scenario 4: Happy path — base_class = Node3D
- **Description:** Create a 3D node script
- **Params:** `{ "path": "res://scripts/test_node3d.gd", "content": "extends Node3D\n", "base_class": "Node3D" }`
- **Expected result:** Success. Script created with base type `Node3D`.

#### Scenario 5: Happy path — base_class = Control
- **Description:** Create a UI control script
- **Params:** `{ "path": "res://scripts/test_ui.gd", "content": "extends Control\n", "base_class": "Control" }`
- **Expected result:** Success. Script created with base type `Control`.

#### Scenario 6: Happy path — base_class = Resource
- **Description:** Create a resource script
- **Params:** `{ "path": "res://scripts/test_resource.gd", "content": "extends Resource\n", "base_class": "Resource" }`
- **Expected result:** Success. Script created with base type `Resource`.

#### Scenario 7: Happy path — complex script content
- **Description:** Create a script with complex multi-line content including signals, variables, and functions
- **Params:** `{ "path": "res://scripts/test_complex.gd", "content": "extends Node\n\nsignal health_changed(new_health)\n\nvar health: int = 100\nvar max_health: int = 100\n\nfunc take_damage(amount: int) -> void:\n    health = max(0, health - amount)\n    health_changed.emit(health)\n\nfunc heal(amount: int) -> void:\n    health = min(max_health, health + amount)\n    health_changed.emit(health)\n" }`
- **Expected result:** Success. Full script content is preserved.

#### Scenario 8: Happy path — content with extends matching base_class
- **Description:** Content declares `extends` that matches the `base_class` parameter
- **Params:** `{ "path": "res://scripts/test_match.gd", "content": "extends CharacterBody2D\n\nfunc _ready():\n    pass\n", "base_class": "CharacterBody2D" }`
- **Expected result:** Success. Script created. The `extends` in content and `base_class` parameter are consistent.

#### Scenario 9: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{ "content": "extends Node\n" }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 10: Edge — missing `content`
- **Description:** Call without the required `content` parameter
- **Params:** `{ "path": "res://scripts/test_nocontent.gd" }`
- **Expected result:** Zod validation error (content is required).

#### Scenario 11: Edge — empty path
- **Description:** Call with empty string path
- **Params:** `{ "path": "", "content": "extends Node\n" }`
- **Expected result:** Error from Godot (invalid path).

#### Scenario 12: Edge — empty content
- **Description:** Create a script with empty content string
- **Params:** `{ "path": "res://scripts/test_empty.gd", "content": "" }`
- **Expected result:** May succeed (creates an empty .gd file) or Godot may reject. Test to verify behavior.

#### Scenario 13: Edge — invalid base_class name
- **Description:** Call with a non-existent Godot class as base_class
- **Params:** `{ "path": "res://scripts/test_badclass.gd", "content": "extends NonExistentClass\n", "base_class": "NonExistentClass" }`
- **Expected result:** Error from Godot (unknown base class).

#### Scenario 14: Edge — path without .gd extension
- **Description:** Create a script without the .gd extension
- **Params:** `{ "path": "res://scripts/test_noext", "content": "extends Node\n" }`
- **Expected result:** May succeed or fail depending on Godot. Likely error (requires .gd extension).

#### Scenario 15: Edge — overwrite existing script
- **Description:** Create a script at a path that already exists
- **Params:** `{ "path": "res://scripts/test_minimal.gd", "content": "extends Node2D\n" }`
- **Expected result:** Behavior depends on Godot implementation — may overwrite or return an error.
- **Notes:** Run after Scenario 1 which creates this file.

#### Scenario 16: Edge — path in nested directory that doesn't exist
- **Description:** Create a script in a non-existent directory
- **Params:** `{ "path": "res://scripts/nonexistent_dir/test.gd", "content": "extends Node\n" }`
- **Expected result:** Error from Godot (parent directory does not exist) or Godot may auto-create directories.

#### Scenario 17: Edge — content with syntax errors
- **Description:** Create a script with invalid GDScript syntax
- **Params:** `{ "path": "res://scripts/test_broken.gd", "content": "extends Node\n\nfunc _ready():\n    this is broken syntax!!!\n" }`
- **Expected result:** The script file may still be created (text is written), but it will have parse errors when Godot tries to compile it.

#### Scenario 18: Edge — base_class = empty string
- **Description:** Call with empty string as base_class
- **Params:** `{ "path": "res://scripts/test_empty_base.gd", "content": "extends Node\n", "base_class": "" }`
- **Expected result:** May behave like no base_class (since zod just sees it as a string), or Godot may reject. Test to verify.

---

## Tool: `delete_script`

**Description:** Delete a GDScript file from the project
**Handler:** `callGodot(bridge, 'script/delete', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `ScriptPath` (string) | **Yes** | — | Script file path to delete |

### Test Scenarios

#### Scenario 1: Happy path — delete an existing unreferenced script
- **Description:** Delete a script that exists and is not attached to any node
- **Params:** `{ "path": "res://scripts/test_minimal.gd" }`
- **Expected result:** Success. The script file is deleted from the project.
- **Notes:** Requires a script created by `create_script` first.

#### Scenario 2: Happy path — delete script with attached base_class
- **Description:** Delete a script that was created with a base_class
- **Params:** `{ "path": "res://scripts/test_character.gd" }`
- **Expected result:** Success. Script file deleted.

#### Scenario 3: Edge — file not found
- **Description:** Delete a non-existent script
- **Params:** `{ "path": "res://scripts/nonexistent_xyz.gd" }`
- **Expected result:** Error from Godot (file not found).

#### Scenario 4: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 5: Edge — empty path
- **Description:** Call with empty string path
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot (invalid path).

#### Scenario 6: Edge — path is a directory
- **Description:** Attempt to delete a directory path instead of a file
- **Params:** `{ "path": "res://scripts" }`
- **Expected result:** Error from Godot (path is not a file).

#### Scenario 7: Edge — delete a script attached to a node
- **Description:** Delete a script that is currently attached to a node in the scene
- **Params:** `{ "path": "res://scripts/player.gd" }`
- **Expected result:** May warn about references or fail, depending on Godot behavior. Test to verify.
- **Notes:** Attach the script to a node first, then attempt deletion.

#### Scenario 8: Edge — delete the currently open script in the editor
- **Description:** Delete a script that is currently open in the script editor
- **Params:** `{ "path": "res://scripts/test_complex.gd" }`
- **Expected result:** May fail while script is open, or Godot may close it then delete. Test to verify.
- **Notes:** Ensure the script is open in the editor before testing.

#### Scenario 9: Edge — delete a recently deleted script (double delete)
- **Description:** Delete the same script twice in succession
- **Params:** `{ "path": "res://scripts/test_minimal.gd" }` (after successful delete in Scenario 1)
- **Expected result:** Error from Godot (file not found).

---

## Tool: `edit_script`

**Description:** Edit an existing GDScript file by replacing a text segment
**Handler:** `callGodot(bridge, 'script/edit', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `ScriptPath` (string) | **Yes** | — | Script file path |
| `old_text` | string | **Yes** | — | Exact text to find and replace |
| `new_text` | string | **Yes** | — | Replacement text |

### Test Scenarios

#### Scenario 1: Happy path — simple text replacement
- **Description:** Replace a single line in an existing script
- **Params:** `{ "path": "res://scripts/test_complex.gd", "old_text": "var health: int = 100", "new_text": "var health: int = 200" }`
- **Expected result:** Success. The line is replaced. `health` now starts at 200.

#### Scenario 2: Happy path — replace a function body
- **Description:** Replace the implementation of a function
- **Params:** `{ "path": "res://scripts/test_complex.gd", "old_text": "func take_damage(amount: int) -> void:\n    health = max(0, health - amount)\n    health_changed.emit(health)", "new_text": "func take_damage(amount: int) -> void:\n    health = max(0, health - amount * 2)\n    health_changed.emit(health)" }`
- **Expected result:** Success. The function body is updated with doubled damage.

#### Scenario 3: Happy path — add new code (replace part of a line with more)
- **Description:** Extend a block by appending lines
- **Params:** `{ "path": "res://scripts/test_complex.gd", "old_text": "signal health_changed(new_health)", "new_text": "signal health_changed(new_health)\nsignal died\nsignal revived" }`
- **Expected result:** Success. New signals are added after the existing one.

#### Scenario 4: Happy path — remove code (replace with empty string)
- **Description:** Delete a line by replacing it with empty string
- **Params:** `{ "path": "res://scripts/test_complex.gd", "old_text": "var max_health: int = 100\n", "new_text": "" }`
- **Expected result:** Success. The line is removed from the file.

#### Scenario 5: Happy path — multi-line replacement
- **Description:** Replace a multi-line block with entirely new content
- **Params:** `{ "path": "res://scripts/test_complex.gd", "old_text": "func heal(amount: int) -> void:\n    health = min(max_health, health + amount)\n    health_changed.emit(health)", "new_text": "func heal(amount: int) -> void:\n    var overheal = health + amount\n    health = min(max_health, overheal)\n    health_changed.emit(health)\n    if overheal > max_health:\n        print(\"Overheal wasted: \", overheal - max_health)" }`
- **Expected result:** Success. The function is replaced with the extended version.

#### Scenario 6: Edge — old_text not found
- **Description:** Call with old_text that does not exist in the file
- **Params:** `{ "path": "res://scripts/test_complex.gd", "old_text": "THIS_TEXT_DOES_NOT_EXIST_ANYWHERE_XYZ", "new_text": "replacement" }`
- **Expected result:** Error from Godot (text not found in file).

#### Scenario 7: Edge — file not found
- **Description:** Edit a non-existent script
- **Params:** `{ "path": "res://scripts/nonexistent_xyz.gd", "old_text": "foo", "new_text": "bar" }`
- **Expected result:** Error from Godot (file not found).

#### Scenario 8: Edge — missing `path`
- **Description:** Call without required `path`
- **Params:** `{ "old_text": "foo", "new_text": "bar" }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 9: Edge — missing `old_text`
- **Description:** Call without required `old_text`
- **Params:** `{ "path": "res://scripts/test_complex.gd", "new_text": "bar" }`
- **Expected result:** Zod validation error (old_text is required).

#### Scenario 10: Edge — missing `new_text`
- **Description:** Call without required `new_text`
- **Params:** `{ "path": "res://scripts/test_complex.gd", "old_text": "foo" }`
- **Expected result:** Zod validation error (new_text is required).

#### Scenario 11: Edge — empty old_text
- **Description:** Call with empty old_text string
- **Params:** `{ "path": "res://scripts/test_complex.gd", "old_text": "", "new_text": "something" }`
- **Expected result:** May match at position 0 or fail. Test to verify behavior.

#### Scenario 12: Edge — empty new_text (deletion)
- **Description:** Replace text with empty string to remove it
- **Params:** `{ "path": "res://scripts/test_complex.gd", "old_text": "signal revived\n", "new_text": "" }`
- **Expected result:** Success. The matched text is removed from the file.

#### Scenario 13: Edge — path is empty string
- **Description:** Call with empty path
- **Params:** `{ "path": "", "old_text": "foo", "new_text": "bar" }`
- **Expected result:** Error from Godot (invalid path).

#### Scenario 14: Edge — old_text matches multiple occurrences
- **Description:** Call with text that appears multiple times in the file
- **Params:** `{ "path": "res://scripts/test_complex.gd", "old_text": "health", "new_text": "hp" }`
- **Expected result:** Behavior depends on Godot implementation. May replace first occurrence, all occurrences, or require a unique match. Test to verify.
- **Notes:** `health` appears multiple times in the test_complex.gd script.

#### Scenario 15: Edge — edit a .tscn scene file (not a script)
- **Description:** Use edit_script on a scene file instead of a .gd script
- **Params:** `{ "path": "res://scenes/main.tscn", "old_text": "[node", "new_text": "[node\n; Edited" }`
- **Expected result:** The tool's handler targets `script/edit`, but at the MCP level it may still process any file. Test to verify behavior.

#### Scenario 16: Edge — whitespace-only old_text or new_text
- **Description:** Replace using whitespace-only strings
- **Params:** `{ "path": "res://scripts/test_complex.gd", "old_text": "    ", "new_text": "\t" }`
- **Expected result:** May match indentation. Test to verify whitespace handling (spaces vs tabs).

---

## Tool: `attach_script`

**Description:** Attach a GDScript to a node in the scene
**Handler:** `callGodot(bridge, 'script/attach', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `script_path` | `ScriptPath` (string) | **Yes** | — | Script file path to attach |
| `node_path` | `NodePath` (string) | **Yes** | — | Node to attach script to (e.g. `'Player'` or `''` for scene root) |

### Test Scenarios

#### Scenario 1: Happy path — attach script to a named node
- **Description:** Attach a script to a child node by name
- **Params:** `{ "script_path": "res://scripts/test_character.gd", "node_path": "Player" }`
- **Expected result:** Success. The script is attached to the `Player` node.

#### Scenario 2: Happy path — attach to scene root (empty string)
- **Description:** Attach a script to the scene root using empty node_path
- **Params:** `{ "script_path": "res://scripts/test_node2d.gd", "node_path": "" }`
- **Expected result:** Success. The script is attached to the scene root node.
- **Notes:** Scene root must be of a compatible type with the script's base class.

#### Scenario 3: Happy path — attach to nested node path
- **Description:** Attach a script to a deeply nested node using full path
- **Params:** `{ "script_path": "res://scripts/test_ui.gd", "node_path": "UI/HealthBar/Progress" }`
- **Expected result:** Success if the node exists at that path.

#### Scenario 4: Edge — node_path does not exist
- **Description:** Attach to a non-existent node
- **Params:** `{ "script_path": "res://scripts/test_minimal.gd", "node_path": "NonExistentNodeXYZ" }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 5: Edge — script_path does not exist
- **Description:** Attach using a non-existent script file
- **Params:** `{ "script_path": "res://scripts/nonexistent_xyz.gd", "node_path": "Player" }`
- **Expected result:** Error from Godot (script resource not found).

#### Scenario 6: Edge — missing `script_path`
- **Description:** Call without required `script_path`
- **Params:** `{ "node_path": "Player" }`
- **Expected result:** Zod validation error (script_path is required).

#### Scenario 7: Edge — missing `node_path`
- **Description:** Call without required `node_path`
- **Params:** `{ "script_path": "res://scripts/test_minimal.gd" }`
- **Expected result:** Zod validation error (node_path is required).

#### Scenario 8: Edge — base class mismatch
- **Description:** Attach a CharacterBody2D script to a Node3D node (type mismatch)
- **Params:** `{ "script_path": "res://scripts/test_character.gd", "node_path": "MeshInstance3D" }`
- **Expected result:** Error from Godot (script base class incompatible with node type).

#### Scenario 9: Edge — empty script_path
- **Description:** Call with empty string script_path
- **Params:** `{ "script_path": "", "node_path": "Player" }`
- **Expected result:** Error from Godot (invalid script path).

#### Scenario 10: Edge — node already has a script
- **Description:** Attach a script to a node that already has a script attached
- **Params:** `{ "script_path": "res://scripts/test_ui.gd", "node_path": "Player" }`
- **Expected result:** May replace the existing script, or error. Test to verify behavior.
- **Notes:** First run Scenario 1 to attach a script, then run this to test re-attachment.

#### Scenario 11: Edge — attach script to node with inherited script
- **Description:** Attach a script to an instance of a scene that already has its root script set from the original scene
- **Params:** `{ "script_path": "res://scripts/test_resource.gd", "node_path": "InstancedScene" }`
- **Expected result:** May fail with warning about inherited script, or override. Test to verify.

#### Scenario 12: Edge — node_path with special characters
- **Description:** Attach to a node whose path contains unusual characters
- **Params:** `{ "script_path": "res://scripts/test_minimal.gd", "node_path": "My Node (Copy)" }`
- **Expected result:** Should work if the node name contains spaces and parentheses. Test path handling.

---

## Tool: `get_open_scripts`

**Description:** Get list of scripts currently open in the script editor
**Handler:** `callGodot(bridge, 'script/get_open')` — note: no args forwarded

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| *(none)* | — | — | — | No parameters |

### Test Scenarios

#### Scenario 1: Happy path — scripts are open
- **Description:** Get the list of open scripts when some are open in the editor
- **Params:** `{}`
- **Expected result:** Success. Returns an array of script paths (strings) currently open in the script editor.
- **Notes:** Open a few .gd files in the Godot editor before testing.

#### Scenario 2: Happy path — no scripts open
- **Description:** Get the list when no scripts are open
- **Params:** `{}`
- **Expected result:** Success. Returns an empty array `[]`.

#### Scenario 3: Edge — extraneous params passed
- **Description:** Call with unexpected parameters (should be ignored by the handler)
- **Params:** `{ "unexpected_param": "value" }`
- **Expected result:** Should succeed (the handler ignores args). Returns open script list.

#### Scenario 4: Scenario — verify paths are `res://` formatted
- **Description:** Open scripts from various project locations and verify returned paths use `res://` prefix
- **Expected result:** All returned paths should be in `res://...` format.
- **Notes:** Open scripts in `res://scripts/`, `res://autoload/`, and nested directories.

#### Scenario 5: Scenario — open many scripts
- **Description:** Open 10+ scripts simultaneously and verify all are listed
- **Expected result:** All open script paths are returned in the array.

---

## Tool: `validate_script`

**Description:** Validate a GDScript file for syntax errors
**Handler:** `callGodot(bridge, 'script/validate', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `ScriptPath` (string) | **Yes** | — | Script file path to validate |

### Test Scenarios

#### Scenario 1: Happy path — validate a valid script
- **Description:** Validate a syntactically correct GDScript
- **Params:** `{ "path": "res://scripts/test_complex.gd" }`
- **Expected result:** Success. Returns validation result with no errors.
- **Notes:** Requires a valid script created by `create_script`.

#### Scenario 2: Happy path — validate a script with syntax errors
- **Description:** Validate a script that has intentional syntax errors
- **Params:** `{ "path": "res://scripts/test_broken.gd" }`
- **Expected result:** Success (tool returns result). The result should list compilation errors with line numbers and error messages.
- **Notes:** Create a script with syntax errors first (e.g., `test_broken.gd` from the create_script Scenario 17).

#### Scenario 3: Happy path — validate a script with type errors
- **Description:** Validate a script that compiles syntactically but has type errors
- **Params:** `{ "path": "res://scripts/test_type_error.gd" }`
- **Expected result:** If the project uses strict typing, this should return type errors. Otherwise may pass.
- **Notes:** Create a script that assigns a string to an int variable, etc.

#### Scenario 4: Edge — file not found
- **Description:** Validate a non-existent script
- **Params:** `{ "path": "res://scripts/nonexistent_xyz.gd" }`
- **Expected result:** Error from Godot (file not found).

#### Scenario 5: Edge — missing `path`
- **Description:** Call without required `path`
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 6: Edge — empty path
- **Description:** Call with empty string path
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot (invalid path).

#### Scenario 7: Edge — validate a non-script file
- **Description:** Validate a file that is not a GDScript (e.g., a .tscn scene)
- **Params:** `{ "path": "res://scenes/main.tscn" }`
- **Expected result:** Error from Godot (not a valid GDScript file).

#### Scenario 8: Edge — validate a script with warnings only (no errors)
- **Description:** Validate a script that has unused variables or other warnings
- **Params:** `{ "path": "res://scripts/test_warnings.gd" }`
- **Expected result:** Should return success with warnings but no errors.
- **Notes:** Create a script with `var unused_var = 5` that is never used.

#### Scenario 9: Edge — validate a large script
- **Description:** Validate a script with 500+ lines
- **Expected result:** Should still complete without timeout.
- **Notes:** Create or use a large script file.

#### Scenario 10: Edge — path is a directory
- **Description:** Pass a directory path instead of a file
- **Params:** `{ "path": "res://scripts" }`
- **Expected result:** Error from Godot (path is not a file / not a script).

---

## Tool: `search_in_files`

**Description:** Search for text across project files
**Handler:** `callGodot(bridge, 'script/search_in_files', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `query` | `SearchQuery` (string) | **Yes** | — | Search query |
| `file_pattern` | string | No | — | File pattern to search in (e.g. `'*.gd'`) |

### Test Scenarios

#### Scenario 1: Happy path — search all files (no file_pattern)
- **Description:** Search across all project files for a common term
- **Params:** `{ "query": "extends" }`
- **Expected result:** Success. Returns all files containing the text "extends" with matching line numbers/excerpts.

#### Scenario 2: Happy path — search with file_pattern = `*.gd`
- **Description:** Search only GDScript files
- **Params:** `{ "query": "func _ready", "file_pattern": "*.gd" }`
- **Expected result:** Success. Returns only .gd files containing "func _ready".

#### Scenario 3: Happy path — search with file_pattern = `*.tscn`
- **Description:** Search only scene files
- **Params:** `{ "query": "CharacterBody2D", "file_pattern": "*.tscn" }`
- **Expected result:** Success. Returns only .tscn files matching the query.

#### Scenario 4: Happy path — search with file_pattern = `*.tres`
- **Description:** Search only resource files
- **Params:** `{ "query": "[resource]", "file_pattern": "*.tres" }`
- **Expected result:** Success. Returns only .tres files.

#### Scenario 5: Happy path — file_pattern with directory path
- **Description:** Search within a specific directory pattern
- **Params:** `{ "query": "signal", "file_pattern": "res://scripts/*.gd" }`
- **Expected result:** Success. Returns results only from files matching the pattern in the scripts directory.

#### Scenario 6: Happy path — case-sensitive search
- **Description:** Search for an exact case-sensitive match (Godot may be case-sensitive)
- **Params:** `{ "query": "Node" }`
- **Expected result:** Success. Returns files containing "Node" (not "node").

#### Scenario 7: Happy path — search for a rare/unique string
- **Description:** Search for a string that appears in exactly one file
- **Params:** `{ "query": "health_changed" }`
- **Expected result:** Success. Returns the single file containing this string.

#### Scenario 8: Edge — query matches nothing
- **Description:** Search for text that does not exist in any file
- **Params:** `{ "query": "ZZZ_NO_MATCH_XYZZY_12345" }`
- **Expected result:** Success. Returns an empty result set (no matches).

#### Scenario 9: Edge — missing `query`
- **Description:** Call without required `query`
- **Params:** `{ "file_pattern": "*.gd" }`
- **Expected result:** Zod validation error (query is required).

#### Scenario 10: Edge — empty query string
- **Description:** Search with empty string query
- **Params:** `{ "query": "" }`
- **Expected result:** May match everything or nothing. Test to verify behavior.
- **Notes:** An empty query might match all files or return an error.

#### Scenario 11: Edge — empty file_pattern
- **Description:** Call with empty string file_pattern
- **Params:** `{ "query": "extends", "file_pattern": "" }`
- **Expected result:** Should behave like no file_pattern (searches all files), or match nothing. Test to verify.

#### Scenario 12: Edge — file_pattern with wildcard but no matching files
- **Description:** Search with a file_pattern that matches no files
- **Params:** `{ "query": "extends", "file_pattern": "*.cs" }`
- **Expected result:** Success. Returns empty result set (no .cs files in a GDScript project).
- **Notes:** Assuming project has no C# files.

#### Scenario 13: Edge — query with special regex characters
- **Description:** Search for a string containing regex special characters
- **Params:** `{ "query": "(health)", "file_pattern": "*.gd" }`
- **Expected result:** Behavior depends on whether Godot treats query as literal or regex. May match literal `(health)` or treat as regex group.
- **Notes:** Test to determine if search is literal or regex-based.

#### Scenario 14: Edge — query with newline characters
- **Description:** Search for a string containing newlines
- **Params:** `{ "query": "func _ready():\n    pass" }`
- **Expected result:** May fail or search for the literal newline character. Test to verify.

#### Scenario 15: Edge — file_pattern with multiple extensions
- **Description:** Try a glob pattern matching multiple extensions
- **Params:** `{ "query": "extends", "file_pattern": "*.{gd,tscn}" }`
- **Expected result:** Behavior depends on Godot's glob support. May or may not support brace expansion. Test to verify.

#### Scenario 16: Edge — very long query string
- **Description:** Search with a 1000+ character query string
- **Params:** `{ "query": "<1000 chars of text>", "file_pattern": "*.gd" }`
- **Expected result:** May succeed (no match) or fail due to query length. Test to verify.

---

## Integration Test Scenarios

These scenarios chain multiple script tools together to verify end-to-end workflows.

### Integration 1: Create → Read → Edit → Read → Validate workflow
1. `create_script` — create `res://scripts/integration_test.gd` with content containing `extends Node`, a variable, and a function
2. `read_script` — verify the content matches what was created
3. `edit_script` — replace the variable value
4. `read_script` — verify the edit was applied correctly
5. `validate_script` — confirm no compilation errors
- **Expected result:** All steps succeed. Script is created, read back, modified, re-read, and validates cleanly.

### Integration 2: Create → Attach → Validate → Delete workflow
1. `create_script` — create `res://scripts/integration_attach.gd` with base_class matching an existing node type
2. `attach_script` — attach to a compatible node already in the scene
3. `validate_script` — confirm the script has no errors
4. `delete_script` — delete the script (may fail if still attached; if so, detach first or use Godot to detach)
- **Expected result:** Script is created, attached successfully, validates cleanly. Deletion behavior depends on whether script is still referenced.

### Integration 3: Create → Search → Validate All workflow
1. `create_script` — create several test scripts with unique marker strings (e.g., `# INTEGRATION_MARKER_A`, `# INTEGRATION_MARKER_B`)
2. `search_in_files` — search for the marker strings with `file_pattern: "*.gd"`
3. For each found script, call `validate_script`
- **Expected result:** Search finds all created scripts. All validate successfully.

### Integration 4: List → Read → Open workflow
1. `list_scripts` — get all scripts in the project
2. Pick a script from the list
3. `read_script` — read its contents
4. Open the script in the Godot editor (manually or via another tool)
5. `get_open_scripts` — verify the script appears in the open scripts list
- **Expected result:** List returns scripts. Read shows content. Open scripts reflects the editor state.

### Integration 5: Edit → Attach → Detach (via edit to remove script) workflow
1. `create_script` — create a reusable component script
2. `edit_script` — tweak the script content
3. `attach_script` — attach to test nodes
4. Use `edit_script` to comment out the entire script body (simulating detachment by making it a no-op)
- **Expected result:** Edits propagate to all nodes using the script. Nodes reflect updated behavior.

---

## Summary

| # | Tool | Params | Required | Optional | Enum Values |
|---|---|---|---|---|---|
| 1 | `list_scripts` | 1 | — | `max_depth` | — |
| 2 | `read_script` | 1 | `path` | — | — |
| 3 | `create_script` | 3 | `path`, `content` | `base_class` | — |
| 4 | `delete_script` | 1 | `path` | — | — |
| 5 | `edit_script` | 3 | `path`, `old_text`, `new_text` | — | — |
| 6 | `attach_script` | 2 | `script_path`, `node_path` | — | — |
| 7 | `get_open_scripts` | 0 | — | — | — |
| 8 | `validate_script` | 1 | `path` | — | — |
| 9 | `search_in_files` | 2 | `query` | `file_pattern` | — |

**Total scenarios:** 85+ covering all 9 tools with happy paths, edge cases, and integration workflows.

**Notable observations:**
- `list_scripts` handler does NOT forward `max_depth` param to Godot (`async () => callGodot(bridge, 'script/list')`). The Zod schema validates it but the handler ignores args. This may be a bug in the source.
- `get_open_scripts` handler similarly ignores all args (`async () => callGodot(bridge, 'script/get_open')`).
- No tools in this module have enum parameters — all are free-form strings or numbers.
- `ScriptPath`, `NodePath`, `GDScriptCode`, and `SearchQuery` are all plain `z.string()` wrappers with descriptions (no additional validation like regex patterns).
