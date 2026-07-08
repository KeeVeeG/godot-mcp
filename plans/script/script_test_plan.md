# Script Tools — Test Plan

**Source file:** `server/src/tools/script.ts`
**Shared types source:** `server/src/tools/shared-types.ts`
**Precondition:** A Godot project must be open with the MCP plugin active. Some tools require an open scene with at least a root node.

---

## 1. `list_scripts`

**Description:** List all GDScript files in the project with class info.
**Schema:**
- `max_depth` (optional) — `number`, integer, positive, default `10` — Maximum directory depth to scan

**Handler:** `callGodot(bridge, 'script/list')`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — list scripts with default depth** | `{}` | Returns JSON array of script file paths and class metadata (class_name, extends, etc.) | Default max_depth=10 |
| 2 | **Custom depth — shallow scan** | `{"max_depth": 1}` | Returns scripts only in root directories (e.g., `res://` level) | Tests custom depth value |
| 3 | **Custom depth — deep scan** | `{"max_depth": 50}` | Returns scripts up to 50 directory levels deep | Tests large depth value |
| 4 | **Custom depth — minimum valid** | `{"max_depth": 1}` | Returns scripts at depth ≤ 1 only | Boundary: lowest valid |
| 5 | **Boundary — depth of 0** | `{"max_depth": 0}` | Schema validation error — must be positive (> 0) | Boundary violation |
| 6 | **Boundary — negative depth** | `{"max_depth": -1}` | Schema validation error — must be positive | Boundary violation |
| 7 | **Boundary — non-integer depth** | `{"max_depth": 3.5}` | Schema validation error — must be integer | Type validation |
| 8 | **Invalid type — string depth** | `{"max_depth": "five"}` | Schema validation error — expected number | Type validation |
| 9 | **Empty project (no scripts)** | `{}` | Returns empty array `[]` | Edge case: no GDScript files exist |
| 10 | **Many scripts (~100+)** | `{}` | Returns full list; may be large but should not error or truncate | Large dataset |

---

## 2. `read_script`

**Description:** Read the contents of a GDScript file.
**Schema:**
- `path` (required) — `string` (ScriptPath) — Script file path (e.g. `'res://scripts/player.gd'`)

**Handler:** `callGodot(bridge, 'script/read', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — read an existing script** | `{"path": "res://scripts/player.gd"}` | Returns the full GDScript source code as a string | Requires a project with a script at that path |
| 2 | **Read script at project root** | `{"path": "res://main.gd"}` | Returns source code | Root-level script |
| 3 | **Read deeply nested script** | `{"path": "res://scripts/characters/enemies/boss.gd"}` | Returns source code | Nested path |
| 4 | **Non-existent script path** | `{"path": "res://scripts/does_not_exist.gd"}` | Error: file not found / path does not exist | Error handling |
| 5 | **Path to a non-script file** | `{"path": "res://scenes/main.tscn"}` | Error: not a GDScript file, or returns file contents (implementation-dependent) | Edge case |
| 6 | **Path with wrong extension** | `{"path": "res://scripts/player.txt"}` | Error: not a .gd file | Extension validation |
| 7 | **Missing required `path`** | `{}` | Schema validation error | Required param |
| 8 | **Invalid path type — number** | `{"path": 12345}` | Schema validation error — expected string | Type validation |
| 9 | **Invalid path type — null** | `{"path": null}` | Schema validation error — expected string | Type validation |
| 10 | **Path with backslashes** | `{"path": "res:\\scripts\\player.gd"}` | Error: invalid path (Godot expects forward slashes) | Path format |
| 11 | **Path without `res://` prefix** | `{"path": "scripts/player.gd"}` | Error: invalid path or resolved relative to current working directory | Path format |

---

## 3. `create_script`

**Description:** Create a new GDScript file.
**Schema:**
- `path` (required) — `string` (ScriptPath) — Path for the new script (e.g. `'res://scripts/player.gd'`)
- `content` (required) — `string` (GDScriptCode) — GDScript source code
- `base_class` (optional) — `string` — Base class (e.g. `'CharacterBody2D'`)

**Handler:** `callGodot(bridge, 'script/create', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — create a simple script** | `{"path": "res://scripts/new_script.gd", "content": "extends Node\\n\\nfunc _ready():\\n    pass"}` | Success; script file created on disk; returns success message or path | Minimum required params |
| 2 | **Happy path — create with base_class** | `{"path": "res://scripts/player.gd", "content": "extends CharacterBody2D\\n\\nfunc _ready():\\n    pass", "base_class": "CharacterBody2D"}` | Success; script inherits CharacterBody2D | Tests optional base_class |
| 3 | **Create with base_class = 'Node'** | `{"path": "res://scripts/util.gd", "content": "extends Node\\n\\nfunc my_utility():\\n    return 42", "base_class": "Node"}` | Success; script inherits Node | Common base class |
| 4 | **Create with base_class = 'Node2D'** | `{"path": "res://scripts/sprite_script.gd", "content": "extends Node2D\\n\\nfunc _ready():\\n    pass", "base_class": "Node2D"}` | Success | 2D-specific base class |
| 5 | **Create with base_class = 'Control'** | `{"path": "res://scripts/ui_script.gd", "content": "extends Control\\n\\nfunc _ready():\\n    pass", "base_class": "Control"}` | Success | UI-specific base class |
| 6 | **Create in nested subdirectory** | `{"path": "res://scripts/characters/enemies/goblin.gd", "content": "extends CharacterBody3D\\n\\nfunc _ready():\\n    pass"}` | Success; parent directories created if needed | Nested path |
| 7 | **Overwrite existing script** | `{"path": "res://scripts/existing.gd", "content": "extends Node\\n\\nfunc _ready():\\n    print('overwritten')"}` | Either error: file already exists, or success (overwrites) — implementation-dependent | Overwrite behavior |
| 8 | **Missing required `path`** | `{"content": "extends Node\\n\\nfunc _ready():\\n    pass"}` | Schema validation error | Required param |
| 9 | **Missing required `content`** | `{"path": "res://scripts/empty.gd"}` | Schema validation error | Required param |
| 10 | **Missing both required params** | `{}` | Schema validation error | Required params |
| 11 | **Empty content string** | `{"path": "res://scripts/empty.gd", "content": ""}` | Success or error (implementation-dependent); empty .gd file may be valid | Edge case |
| 12 | **Content with GDScript syntax error** | `{"path": "res://scripts/broken.gd", "content": "extends Node\\n\\nfunc _ready(var x):\\n    pass       "}` | Success (file is created); script may have parse errors but creation should not validate syntax | Syntax not validated on creation |
| 13 | **Invalid path type for 'path'** | `{"path": 999, "content": "extends Node\\n\\nfunc _ready():\\n    pass"}` | Schema validation error — expected string | Type validation |
| 14 | **Invalid content type** | `{"path": "res://scripts/bad.gd", "content": true}` | Schema validation error — expected string | Type validation |
| 15 | **base_class with invalid type** | `{"path": "res://scripts/test.gd", "content": "extends Node", "base_class": 123}` | Schema validation error — expected string | Type validation |
| 16 | **Very long content (~50KB)** | `{"path": "res://scripts/huge.gd", "content": "<large script with thousands of lines>"}` | Success or timeout | Boundary: large payload |
| 17 | **Path without `.gd` extension** | `{"path": "res://scripts/script.txt", "content": "extends Node"}` | Error or creates with wrong extension (implementation-dependent) | Path format |
| 18 | **Path to read-only location** | `{"path": "res://addons/readonly/script.gd", "content": "extends Node"}` | Error: cannot write to that path | Permission handling |

---

## 4. `delete_script`

**Description:** Delete a GDScript file from the project.
**Schema:**
- `path` (required) — `string` (ScriptPath) — Script file path to delete

**Handler:** `callGodot(bridge, 'script/delete', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — delete an existing script** | `{"path": "res://scripts/to_delete.gd"}` | Success; file removed from disk; returns success message | Requires a script to exist at that path |
| 2 | **Delete deeply nested script** | `{"path": "res://scripts/characters/enemies/temp.gd"}` | Success; file removed from nested directory | Nested path |
| 3 | **Delete root-level script** | `{"path": "res://temp.gd"}` | Success | Root-level path |
| 4 | **Non-existent script path** | `{"path": "res://scripts/does_not_exist.gd"}` | Error: file not found / path does not exist | Error handling |
| 5 | **Already-deleted script (double delete)** | `{"path": "res://scripts/already_gone.gd"}` | Error: file not found | Idempotency: second delete should error |
| 6 | **Path to non-script file** | `{"path": "res://scenes/main.tscn"}` | Error: not a .gd file, or deletes the file anyway (implementation-dependent) | Edge case |
| 7 | **Path to a file referenced by other nodes** | `{"path": "res://scripts/referenced.gd"}` | Success (deletes file); nodes referencing it will show errors next time they load | Side-effect: dangling references |
| 8 | **Missing required `path`** | `{}` | Schema validation error | Required param |
| 9 | **Invalid path type — array** | `{"path": ["res://scripts/a.gd"]}` | Schema validation error — expected string | Type validation |
| 10 | **Path with special characters** | `{"path": "res://scripts/../../dangerous.gd"}` | Error: invalid path (directory traversal attempt) | Security |
| 11 | **Delete script attached to currently open scene node** | `{"path": "res://scripts/attached.gd"}` | May error due to file being in use, or succeed (implementation-dependent) | Edge case |

---

## 5. `edit_script`

**Description:** Edit an existing GDScript file by replacing a text segment.
**Schema:**
- `path` (required) — `string` (ScriptPath) — Script file path
- `old_text` (required) — `string` — Exact text to find and replace
- `new_text` (required) — `string` — Replacement text

**Handler:** `callGodot(bridge, 'script/edit', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — simple text replacement** | `{"path": "res://scripts/player.gd", "old_text": "var speed = 100", "new_text": "var speed = 200"}` | Success; `speed` changed from 100 to 200 | Basic replacement |
| 2 | **Replace single line with multiple lines** | `{"path": "res://scripts/player.gd", "old_text": "# TODO: implement", "new_text": "func _process(delta):\\n    move_and_slide()\\n    pass"}` | Success; comment replaced with full method | Multi-line replacement |
| 3 | **Replace multiple lines with single line** | `{"path": "res://scripts/player.gd", "old_text": "func old_method():\\n    print('old')\\n    return", "new_text": "func old_method():\\n    return 42"}` | Success; method body replaced | Multi-line old → single-complex new |
| 4 | **Replace with empty string (delete text)** | `{"path": "res://scripts/player.gd", "old_text": "    print('debug')", "new_text": ""}` | Success; matching text removed from script | Delete via replacement |
| 5 | **Replace empty string with text** | `{"path": "res://scripts/player.gd", "old_text": "", "new_text": "    pass"}` | May replace first occurrence of empty string (beginning of file) or error — implementation-dependent | Edge case: empty old_text |
| 6 | **old_text not found in file** | `{"path": "res://scripts/player.gd", "old_text": "this text does not exist anywhere", "new_text": "replacement"}` | Error: text not found in script | Error handling |
| 7 | **Multiple matches of old_text** | `{"path": "res://scripts/player.gd", "old_text": "pass", "new_text": "return 0"}` | May replace first or all occurrences — implementation-dependent; document behavior | Ambiguity handling |
| 8 | **Non-existent script path** | `{"path": "res://scripts/nonexistent.gd", "old_text": "var x", "new_text": "var y"}` | Error: file not found | Error handling |
| 9 | **Missing required `path`** | `{"old_text": "var x = 1", "new_text": "var x = 2"}` | Schema validation error | Required param |
| 10 | **Missing required `old_text`** | `{"path": "res://scripts/player.gd", "new_text": "replacement"}` | Schema validation error | Required param |
| 11 | **Missing required `new_text`** | `{"path": "res://scripts/player.gd", "old_text": "var x = 1"}` | Schema validation error | Required param |
| 12 | **Invalid path type** | `{"path": 123, "old_text": "var x", "new_text": "var y"}` | Schema validation error — expected string | Type validation |
| 13 | **Invalid old_text type** | `{"path": "res://scripts/player.gd", "old_text": null, "new_text": "var y"}` | Schema validation error — expected string | Type validation |
| 14 | **Invalid new_text type** | `{"path": "res://scripts/player.gd", "old_text": "var x", "new_text": 42}` | Schema validation error — expected string | Type validation |
| 15 | **Very large old_text (not found)** | `{"path": "res://scripts/player.gd", "old_text": "<10KB of text not in file>", "new_text": "x"}` | Error: text not found (should handle large search string) | Boundary: large old_text |
| 16 | **Very large new_text** | `{"path": "res://scripts/player.gd", "old_text": "pass", "new_text": "<~50KB of replacement text>"}` | Success or timeout | Boundary: large payload |

---

## 6. `attach_script`

**Description:** Attach a GDScript to a node in the scene.
**Schema:**
- `script_path` (required) — `string` (ScriptPath) — Script file path to attach
- `node_path` (required) — `string` (NodePath) — Node to attach script to (e.g. `'Player'` or `''` for scene root)

**Handler:** `callGodot(bridge, 'script/attach', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — attach to named child node** | `{"script_path": "res://scripts/player.gd", "node_path": "Player"}` | Success; Player node now has the script attached | Basic usage |
| 2 | **Happy path — attach to scene root** | `{"script_path": "res://scripts/main.gd", "node_path": ""}` | Success; scene root node has script attached | Empty string → root |
| 3 | **Attach to nested node** | `{"script_path": "res://scripts/enemy_ai.gd", "node_path": "Enemies/Goblin"}` | Success; nested node gets the script | Multi-level path |
| 4 | **Attach script to node that already has a script** | `{"script_path": "res://scripts/new_behavior.gd", "node_path": "Player"}` | Error: node already has a script attached, or success (replaces) — implementation-dependent | Overwrite behavior |
| 5 | **Non-existent script path** | `{"script_path": "res://scripts/missing.gd", "node_path": "Player"}` | Error: script file not found | Error handling |
| 6 | **Non-existent node path** | `{"script_path": "res://scripts/player.gd", "node_path": "NonExistentNode"}` | Error: node not found in scene | Error handling |
| 7 | **Script with wrong base class for node type** | `{"script_path": "res://scripts/character_body.gd", "node_path": "Sprite2D"}` | Success or warning (Godot may allow it; base_class mismatch may cause runtime errors) | Edge case: type mismatch |
| 8 | **Missing required `script_path`** | `{"node_path": "Player"}` | Schema validation error | Required param |
| 9 | **Missing required `node_path`** | `{"script_path": "res://scripts/player.gd"}` | Schema validation error | Required param |
| 10 | **Missing both required params** | `{}` | Schema validation error | Required params |
| 11 | **Invalid script_path type** | `{"script_path": 123, "node_path": "Player"}` | Schema validation error — expected string | Type validation |
| 12 | **Invalid node_path type** | `{"script_path": "res://scripts/player.gd", "node_path": null}` | Schema validation error — expected string | Type validation |
| 13 | **No scene open** | `{"script_path": "res://scripts/player.gd", "node_path": "Player"}` | Error: no scene is open / cannot find node | Precondition violation |
| 14 | **Attach same script to multiple nodes sequentially** | First `{"script_path": "res://scripts/shared.gd", "node_path": "A"}`, then `{"script_path": "res://scripts/shared.gd", "node_path": "B"}` | Both succeed | Script reuse across nodes |

---

## 7. `get_open_scripts`

**Description:** Get list of scripts currently open in the script editor.
**Schema:** `{}` — no parameters.

**Handler:** `callGodot(bridge, 'script/get_open')`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — get open scripts with some scripts open** | `{}` | Returns JSON array of open script file paths (e.g., `["res://scripts/player.gd", "res://scripts/enemy.gd"]`) | Requires that scripts are open in the Godot script editor |
| 2 | **No scripts open** | `{}` | Returns empty array `[]` | Edge case: editor has no scripts open |
| 3 | **Many scripts open (~20+)** | `{}` | Returns full list of all open script paths | Large dataset |
| 4 | **Extra/unknown parameters passed** | `{"unexpected": true}` | Should succeed (extra params ignored by inputSchema `{}`); behavior depends on Zod strict mode | Extra params |

---

## 8. `validate_script`

**Description:** Validate a GDScript file for syntax errors.
**Schema:**
- `path` (required) — `string` (ScriptPath) — Script file path to validate

**Handler:** `callGodot(bridge, 'script/validate', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — validate a valid script** | `{"path": "res://scripts/valid.gd"}` | Returns success with no errors (e.g., `{"valid": true, "errors": []}`) | Script with no syntax errors |
| 2 | **Validate script with syntax error** | `{"path": "res://scripts/broken.gd"}` | Returns validation failure with error details (line number, message) | Script with intentional syntax error |
| 3 | **Validate script with missing `extends`** | `{"path": "res://scripts/no_extends.gd"}` | May report warning (not an error in GDScript 2.0) or pass — implementation-dependent | Editorial check |
| 4 | **Validate script with unused variable warning** | `{"path": "res://scripts/unused_var.gd"}` | May report warnings but still `valid: true` — implementation-dependent | Warnings vs errors |
| 5 | **Non-existent script path** | `{"path": "res://scripts/does_not_exist.gd"}` | Error: file not found | Error handling |
| 6 | **Validate non-GDScript file** | `{"path": "res://scenes/main.tscn"}` | Error: not a GDScript file | File type validation |
| 7 | **Validate trivially empty script** | `{"path": "res://scripts/truly_empty.gd"}` | May be valid or report error (empty file may lack `extends`); implementation-dependent | Edge case |
| 8 | **Missing required `path`** | `{}` | Schema validation error | Required param |
| 9 | **Invalid path type — boolean** | `{"path": true}` | Schema validation error — expected string | Type validation |
| 10 | **Very large script (~10K lines)** | `{"path": "res://scripts/huge.gd"}` | Returns validation result (may take longer) | Large file |

---

## 9. `search_in_files`

**Description:** Search for text across project files.
**Schema:**
- `query` (required) — `string` (SearchQuery) — Search query
- `file_pattern` (optional) — `string` — File pattern to search in (e.g. `'*.gd'`)

**Handler:** `callGodot(bridge, 'script/search_in_files', args)`

### Test Scenarios

| # | Scenario | Params | Expected Result | Notes |
|---|----------|--------|-----------------|-------|
| 1 | **Happy path — simple text search across all files** | `{"query": "extends Node"}` | Returns JSON with file paths and line matches for all files containing `extends Node` | Basic search |
| 2 | **Happy path — search with file_pattern filter** | `{"query": "func _ready", "file_pattern": "*.gd"}` | Returns matches only in `.gd` files | Pattern filter |
| 3 | **Search with `.tscn` file pattern** | `{"query": "script = ExtResource", "file_pattern": "*.tscn"}` | Returns matches only in `.tscn` scene files | Different file type |
| 4 | **Search with no file_pattern (search all)** | `{"query": "TODO"}` | Returns matches across all project file types | Default: no filter |
| 5 | **Search for exact class name** | `{"query": "CharacterBody2D"}` | Returns all files referencing CharacterBody2D | Specific query |
| 6 | **Search with no matches** | `{"query": "xyzzy_no_such_text_anywhere"}` | Returns empty result (no matches) | Zero results |
| 7 | **Search with empty query** | `{"query": ""}` | Returns all files (empty query matches everything) or error — implementation-dependent | Edge case |
| 8 | **Missing required `query`** | `{"file_pattern": "*.gd"}` | Schema validation error | Required param |
| 9 | **Missing required `query` — no params at all** | `{}` | Schema validation error | Required param |
| 10 | **Invalid query type** | `{"query": 42}` | Schema validation error — expected string | Type validation |
| 11 | **Invalid file_pattern type** | `{"query": "test", "file_pattern": 123}` | Schema validation error — expected string | Type validation |
| 12 | **Very long query string (~5KB)** | `{"query": "<very long regex pattern>"}` | Should execute (may use regex; long query is valid string input) | Boundary: large query |
| 13 | **Special regex characters in query** | `{"query": "func .*(delta):"}` | Implementation-dependent: may treat as literal or regex search | Regex handling |
| 14 | **Complex file_pattern** | `{"query": "signal", "file_pattern": "*.{gd,tscn}"}` | Implementation-dependent: brace expansion may or may not be supported | Pattern syntax |
| 15 | **Search in project with many files** | `{"query": "pass"}` | Returns potentially large result set; should not error or timeout | Large result set |

---

## Summary

| # | Tool | Required Params | Optional Params | Paramless |
|---|------|----------------|-----------------|-----------|
| 1 | `list_scripts` | — | `max_depth` | — |
| 2 | `read_script` | `path` | — | — |
| 3 | `create_script` | `path`, `content` | `base_class` | — |
| 4 | `delete_script` | `path` | — | — |
| 5 | `edit_script` | `path`, `old_text`, `new_text` | — | — |
| 6 | `attach_script` | `script_path`, `node_path` | — | — |
| 7 | `get_open_scripts` | — | — | Yes |
| 8 | `validate_script` | `path` | — | — |
| 9 | `search_in_files` | `query` | `file_pattern` | — |

Total scenarios: 10 + 11 + 18 + 11 + 16 + 14 + 4 + 10 + 15 = **109 test scenarios**
