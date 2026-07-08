# Test Plan: Script Tools (`server/src/tools/script.ts`)

> **Source file:** `server/src/tools/script.ts`
> **Shared types:** `server/src/tools/shared-types.ts`
> **Tools count:** 9
> **Generated:** 2026-07-08

---

## Architecture Notes

All script tools communicate with the Godot editor via WebSocket bridge (`callGodot → bridge.sendRequest`). Each tool maps to a GDScript command module in the Godot addon (`addons/godot_mcp/commands/script_*.gd`).

### Type Definitions (from `shared-types.ts`)

| Type | Schema | Description |
|------|--------|-------------|
| `ScriptPath` | `z.string()` | Script file path, e.g. `res://scripts/player.gd` |
| `NodePath` | `z.string()` | Node path in scene tree, e.g. `Player/Sprite2D`, `''` for root |
| `GDScriptCode` | `z.string()` | GDScript source code string |
| `SearchQuery` | `z.string()` | Search query string |

### Common Tool Result Format

All tools return:
```json
{
  "content": [{ "type": "text", "text": "<JSON-stringified result or error message>" }]
}
```
On error, the result includes `"isError": true`.

---

## Prerequisites & Dependencies

### Required External State

- **Godot editor** must be running with the MCP plugin active and connected
- At least one scene must be open in the editor
- Project must have a valid `project.godot` file

### Tool Dependencies

| Tool | Depends On | Reason |
|------|-----------|--------|
| `attach_script` | `add_node` (node.ts) | Needs a node in the scene to attach a script to |
| `attach_script` | `create_script` or `read_script` | Needs a `.gd` file to exist before attaching |
| `edit_script` | `create_script` | Script file must exist before editing |
| `delete_script` | `create_script` | Script file must exist before deleting |
| `read_script` | `create_script` or pre-existing scripts | Script must exist to read |
| `validate_script` | `create_script` or pre-existing scripts | Script must exist to validate |
| `search_in_files` | `create_script` | Need known content to search for |
| `get_open_scripts` | `open_scene` (scene.ts) | Need a scene with attached scripts to have open scripts |

### Recommended Test Sequence

```
1. list_scripts          (no prereqs - just lists existing)
2. create_script         (no prereqs - creates file)
3. read_script           (depends on step 2)
4. edit_script           (depends on step 2)
5. validate_script       (depends on step 4 - validates edited content)
6. search_in_files       (depends on step 2 - searches for known content)
7. add_node              (from node.ts - creates target node)
8. attach_script         (depends on steps 2 and 7)
9. get_open_scripts      (depends on step 2 - after opening script)
10. delete_script        (depends on step 2 - cleanup)
```

---

## Tool: `list_scripts`

**Description:** List all GDScript files in the project with class info

**Backend method:** `script/list`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `max_depth` | `number` (int, positive) | No | `10` | Maximum directory depth to scan |

### Test Scenarios

#### Scenario 1: Basic call with no parameters

**Description:** Call `list_scripts` with zero parameters — should use default depth 10.

**Call:**
```json
{}
```

**Expected result:**
- Status: success (no `isError`)
- Result contains a list/array of script entries
- Each entry has at minimum a `path` field (string starting with `res://`)
- The `.gd` extension appears in file paths

**Notes:**
- This is a read-only query, no side effects
- Result may be empty array `[]` if project has no scripts yet
- Pay attention: the result must contain paths in `res://` format

---

#### Scenario 2: With explicit max_depth = 1

**Description:** Limit scan depth to 1 — should return only scripts in top-level directories.

**Call:**
```json
{ "max_depth": 1 }
```

**Expected result:**
- Status: success
- Result contains scripts only from root-level subdirectories (e.g. `res://scripts/` but NOT `res://scripts/sub/deep/file.gd`)
- If project has scripts in nested dirs, this list should be shorter than Scenario 1

**Notes:**
- Pay attention: ensure that scripts from nested subfolders (depth > 1) are absent from the result
- Compare with Scenario 1 to verify depth filtering works

---

#### Scenario 3: With max_depth = 100 (large value)

**Description:** Scan with very large depth — should return all scripts regardless of nesting.

**Call:**
```json
{ "max_depth": 100 }
```

**Expected result:**
- Status: success
- Result contains all scripts in the project (same or more than Scenario 1)

**Notes:**
- Pay attention: there should be no error or timeout with a large depth value
- Should return all scripts in the project

---

#### Scenario 4: With invalid max_depth = 0 (boundary — not positive)

**Description:** Pass `max_depth = 0` — should fail validation since schema requires `int().positive()`.

**Call:**
```json
{ "max_depth": 0 }
```

**Expected result:**
- Status: error (Zod validation rejects non-positive integer)
- Error message mentions validation failure

**Notes:**
- Pay attention: Zod validation error, not a Godot runtime error
- Schema: `z.number().int().positive()` rejects 0

---

#### Scenario 5: With invalid max_depth = -1 (negative)

**Description:** Pass negative depth — should fail validation.

**Call:**
```json
{ "max_depth": -1 }
```

**Expected result:**
- Status: error (Zod validation rejects negative)
- Error message mentions validation failure

**Notes:**
- Pay attention: same type of error as in Scenario 4

---

#### Scenario 6: With invalid max_depth type (string)

**Description:** Pass string instead of number — should fail validation.

**Call:**
```json
{ "max_depth": "deep" }
```

**Expected result:**
- Status: error (Zod validation rejects non-number)

**Notes:**
- Pay attention: checking type safety of input data

---

## Tool: `read_script`

**Description:** Read the contents of a GDScript file

**Backend method:** `script/read`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` | **Yes** | — | Script file path (e.g. `res://scripts/player.gd`) |

### Test Scenarios

#### Scenario 1: Read an existing script

**Description:** Read a script file that exists in the project.

**Prerequisites:** Call `create_script` first with path `res://scripts/test_read.gd` and known content.

**Call:**
```json
{ "path": "res://scripts/test_read.gd" }
```

**Expected result:**
- Status: success
- Result contains the script source code as text
- Content matches what was created in the prerequisite

**Notes:**
- Pay attention: the script content must exactly match what was created
- The result should be the full file content, not truncated

---

#### Scenario 2: Read a non-existent script

**Description:** Attempt to read a script file that doesn't exist.

**Call:**
```json
{ "path": "res://scripts/nonexistent_file_12345.gd" }
```

**Expected result:**
- Status: error
- Error message indicates file not found or similar
- `isError: true`

**Notes:**
- Pay attention: there should be a clear error, not a crash
- Error should mention the path or "not found"

---

#### Scenario 3: Read with empty path

**Description:** Pass empty string as path — should either fail validation or produce a Godot-side error.

**Call:**
```json
{ "path": "" }
```

**Expected result:**
- Status: error
- Either Zod rejects empty string or Godot returns "file not found"

**Notes:**
- Pay attention: `ScriptPath` is `z.string()`, so an empty string will pass Zod validation, but Godot will return an error

---

#### Scenario 4: Read with path missing `res://` prefix

**Description:** Pass a path without the `res://` prefix.

**Call:**
```json
{ "path": "scripts/player.gd" }
```

**Expected result:**
- Status: error (Godot-side — invalid path format)
- Error message indicates path must use `res://` prefix

**Notes:**
- Pay attention: Godot expects the `res://` prefix for all resources

---

#### Scenario 5: Missing required `path` parameter

**Description:** Call without the required `path` field.

**Call:**
```json
{}
```

**Expected result:**
- Status: error (Zod validation — `path` is required)
- Error message mentions missing required field

**Notes:**
- Pay attention: error on the validation side, not Godot

---

## Tool: `create_script`

**Description:** Create a new GDScript file

**Backend method:** `script/create`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` | **Yes** | — | Path for the new script (e.g. `res://scripts/player.gd`) |
| `content` | `string` | **Yes** | — | GDScript source code |
| `base_class` | `string` | No | — | Base class (e.g. `CharacterBody2D`) |

### Test Scenarios

#### Scenario 1: Create a minimal script

**Description:** Create a simple script with minimal content.

**Call:**
```json
{
  "path": "res://scripts/test_minimal.gd",
  "content": "extends Node\n"
}
```

**Expected result:**
- Status: success
- File `res://scripts/test_minimal.gd` is created in the project
- Result confirms creation

**Notes:**
- Pay attention: the file must appear in the project's file system
- Cleanup: call `delete_script` after test

---

#### Scenario 2: Create script with base_class

**Description:** Create a script specifying a base class.

**Call:**
```json
{
  "path": "res://scripts/test_player.gd",
  "content": "func _ready():\n\tprint('Hello')\n",
  "base_class": "CharacterBody2D"
}
```

**Expected result:**
- Status: success
- File is created
- File content contains `extends CharacterBody2D` (auto-generated by Godot from base_class)

**Notes:**
- Pay attention: Godot automatically adds `extends <base_class>` at the beginning of the file
- Cleanup: call `delete_script` after test

---

#### Scenario 3: Create script with full content

**Description:** Create a script with multiple functions and class variables.

**Call:**
```json
{
  "path": "res://scripts/test_full.gd",
  "content": "extends Node\n\n@export var speed: float = 100.0\nvar health: int = 100\n\nfunc _ready():\n\tpress('Ready')\n\nfunc _process(delta):\n\tposition.x += speed * delta\n\nfunc take_damage(amount: int):\n\thealth -= amount\n\tif health <= 0:\n\t\tqueue_free()\n"
}
```

**Expected result:**
- Status: success
- File is created with exact content provided

**Notes:**
- Pay attention: the content must be saved exactly, without changes
- Cleanup: call `delete_script` after test

---

#### Scenario 4: Create script at existing path (overwrite behavior)

**Description:** Create a script at a path that already exists.

**Prerequisites:** Create script first via Scenario 1.

**Call:**
```json
{
  "path": "res://scripts/test_minimal.gd",
  "content": "extends Node\n# Updated\n"
}
```

**Expected result:**
- Status: either success (overwrite) or error (file exists)
- Behavior depends on Godot implementation — document which

**Notes:**
- Pay attention: check whether the file is overwritten or an error is returned
- This determines whether `create_script` is idempotent

---

#### Scenario 5: Create script with empty content

**Description:** Create a script with empty string content.

**Call:**
```json
{
  "path": "res://scripts/test_empty.gd",
  "content": ""
}
```

**Expected result:**
- Status: either success (creates empty file) or error
- If success, file exists but has no content

**Notes:**
- Pay attention: Godot may not accept an empty script — check behavior

---

#### Scenario 6: Missing required `path` parameter

**Description:** Call without `path`.

**Call:**
```json
{
  "content": "extends Node\n"
}
```

**Expected result:**
- Status: error (Zod validation — `path` required)

**Notes:**
- Pay attention: Zod validation error

---

#### Scenario 7: Missing required `content` parameter

**Description:** Call without `content`.

**Call:**
```json
{
  "path": "res://scripts/test_no_content.gd"
}
```

**Expected result:**
- Status: error (Zod validation — `content` required)

**Notes:**
- Pay attention: `content` has type `GDScriptCode` = `z.string()`, so missing the field will cause an error

---

#### Scenario 8: Create script in nested directory (auto-creation)

**Description:** Create a script in a directory that doesn't exist yet.

**Call:**
```json
{
  "path": "res://scripts/deep/nested/test_nested.gd",
  "content": "extends Node\n"
}
```

**Expected result:**
- Status: either success (directories auto-created) or error (directory not found)
- Document whether Godot auto-creates intermediate directories

**Notes:**
- Pay attention: check whether intermediate directories are created automatically

---

## Tool: `delete_script`

**Description:** Delete a GDScript file from the project

**Backend method:** `script/delete`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` | **Yes** | — | Script file path to delete |

### Test Scenarios

#### Scenario 1: Delete an existing script

**Description:** Delete a script that was previously created.

**Prerequisites:** Call `create_script` with path `res://scripts/test_delete_target.gd`.

**Call:**
```json
{ "path": "res://scripts/test_delete_target.gd" }
```

**Expected result:**
- Status: success
- File is removed from the project
- Result confirms deletion

**Notes:**
- Pay attention: the file must be physically deleted from the file system
- After deletion, `read_script` on same path should fail

---

#### Scenario 2: Delete a non-existent script

**Description:** Attempt to delete a script that doesn't exist.

**Call:**
```json
{ "path": "res://scripts/nonexistent_delete_12345.gd" }
```

**Expected result:**
- Status: error (file not found)
- `isError: true`

**Notes:**
- Pay attention: there should be a clear error

---

#### Scenario 3: Delete with empty path

**Description:** Pass empty string as path.

**Call:**
```json
{ "path": "" }
```

**Expected result:**
- Status: error
- Either Zod rejects or Godot returns error

**Notes:**
- Pay attention: `ScriptPath` = `z.string()`, empty string passes Zod, but Godot must reject

---

#### Scenario 4: Missing required `path` parameter

**Description:** Call without `path`.

**Call:**
```json
{}
```

**Expected result:**
- Status: error (Zod validation — `path` required)

**Notes:**
- Pay attention: standard required field validation

---

#### Scenario 5: Delete a script that is attached to a node

**Description:** Delete a script that is currently attached to a node in the scene.

**Prerequisites:**
1. `create_script` at `res://scripts/test_attached.gd`
2. `add_node` (from node.ts) to create a node
3. `attach_script` to attach the script to the node

**Call:**
```json
{ "path": "res://scripts/test_attached.gd" }
```

**Expected result:**
- Status: either success (script deleted, node loses script reference) or error (cannot delete attached script)
- Document the actual behavior

**Notes:**
- Pay attention: how Godot handles deleting a script attached to a node — detaches or prevents deletion

---

## Tool: `edit_script`

**Description:** Edit an existing GDScript file by replacing a text segment

**Backend method:** `script/edit`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` | **Yes** | — | Script file path |
| `old_text` | `string` | **Yes** | — | Exact text to find and replace |
| `new_text` | `string` | **Yes** | — | Replacement text |

### Test Scenarios

#### Scenario 1: Replace a line in an existing script

**Description:** Replace a specific line in a script.

**Prerequisites:** Create script at `res://scripts/test_edit.gd` with content:
```
extends Node

func _ready():
	print("Hello")

func _process(delta):
	pass
```

**Call:**
```json
{
  "path": "res://scripts/test_edit.gd",
  "old_text": "print(\"Hello\")",
  "new_text": "print(\"World\")"
}
```

**Expected result:**
- Status: success
- Script content now contains `print("World")` instead of `print("Hello")`

**Notes:**
- Pay attention: the replacement must be exact — `old_text` is searched as a substring
- Verify by calling `read_script` after edit

---

#### Scenario 2: Replace multi-line block

**Description:** Replace a multi-line block of code.

**Prerequisites:** Same as Scenario 1.

**Call:**
```json
{
  "path": "res://scripts/test_edit.gd",
  "old_text": "func _process(delta):\n\tpass",
  "new_text": "func _process(delta):\n\tposition.x += 1"
}
```

**Expected result:**
- Status: success
- Script now contains the new `_process` implementation

**Notes:**
- Pay attention: multi-line replacement must work with `\n`
- Verify via `read_script`

---

#### Scenario 3: Edit non-existent text (old_text not found)

**Description:** Try to replace text that doesn't exist in the script.

**Call:**
```json
{
  "path": "res://scripts/test_edit.gd",
  "old_text": "this_text_does_not_exist_in_the_file_12345",
  "new_text": "replacement"
}
```

**Expected result:**
- Status: error (text not found)
- Error message indicates the search text was not found

**Notes:**
- Pay attention: there should be a clear error about text not found

---

#### Scenario 4: Edit non-existent script

**Description:** Try to edit a script file that doesn't exist.

**Call:**
```json
{
  "path": "res://scripts/nonexistent_edit_12345.gd",
  "old_text": "old",
  "new_text": "new"
}
```

**Expected result:**
- Status: error (file not found)

**Notes:**
- Pay attention: the error should indicate the missing file

---

#### Scenario 5: Replace with empty new_text (deletion)

**Description:** Replace text with empty string — effectively deleting that text.

**Prerequisites:** Create script with known content.

**Call:**
```json
{
  "path": "res://scripts/test_edit.gd",
  "old_text": "extends Node\n\n",
  "new_text": ""
}
```

**Expected result:**
- Status: success
- Script no longer contains the `extends Node\n\n` prefix

**Notes:**
- Pay attention: deleting text by replacing with an empty string is a valid use case

---

#### Scenario 6: Missing `old_text` parameter

**Description:** Call without `old_text`.

**Call:**
```json
{
  "path": "res://scripts/test_edit.gd",
  "new_text": "replacement"
}
```

**Expected result:**
- Status: error (Zod validation — `old_text` required)

**Notes:**
- Pay attention: standard required field validation

---

#### Scenario 7: Missing `new_text` parameter

**Description:** Call without `new_text`.

**Call:**
```json
{
  "path": "res://scripts/test_edit.gd",
  "old_text": "some text"
}
```

**Expected result:**
- Status: error (Zod validation — `new_text` required)

**Notes:**
- Pay attention: standard required field validation

---

#### Scenario 8: Replace all occurrences vs first occurrence

**Description:** If `old_text` appears multiple times in the script, test whether all occurrences are replaced or only the first.

**Prerequisites:** Create script:
```
extends Node

func a():
	print("test")

func b():
	print("test")
```

**Call:**
```json
{
  "path": "res://scripts/test_edit_multi.gd",
  "old_text": "print(\"test\")",
  "new_text": "print(\"replaced\")"
}
```

**Expected result:**
- Status: success
- Document: are BOTH occurrences replaced, or only the first?

**Notes:**
- Pay attention: **key edge case** — determine whether all occurrences are replaced or only the first
- This is important for understanding the tool's behavior with duplicate text

---

## Tool: `attach_script`

**Description:** Attach a GDScript to a node in the scene

**Backend method:** `script/attach`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `script_path` | `string` | **Yes** | — | Script file path to attach |
| `node_path` | `string` | **Yes** | — | Node to attach script to (e.g. `Player` or `''` for scene root) |

### Test Scenarios

#### Scenario 1: Attach script to a named node

**Description:** Attach an existing script to a node in the scene.

**Prerequisites:**
1. `create_script` at `res://scripts/test_attach.gd` with content `extends Node\n`
2. `add_node` (from node.ts) — add a `Node` named `TestAttachTarget` at scene root

**Call:**
```json
{
  "script_path": "res://scripts/test_attach.gd",
  "node_path": "TestAttachTarget"
}
```

**Expected result:**
- Status: success
- Script is attached to the node
- Verify: `get_node_properties` (from node.ts) should show the script property set

**Notes:**
- Pay attention: after attachment, the node must have a reference to the script
- Cleanup: `delete_node` + `delete_script`

---

#### Scenario 2: Attach script to scene root (empty node_path)

**Description:** Attach script to the scene root using empty string.

**Prerequisites:** `create_script` at `res://scripts/test_attach_root.gd`.

**Call:**
```json
{
  "script_path": "res://scripts/test_attach_root.gd",
  "node_path": ""
}
```

**Expected result:**
- Status: success
- Scene root node now has the script attached

**Notes:**
- Pay attention: empty string `""` means the scene root — this is documented behavior

---

#### Scenario 3: Attach script to nested node path

**Description:** Attach script to a deeply nested node.

**Prerequisites:**
1. `create_script` at `res://scripts/test_attach_nested.gd`
2. `add_node` — `Node` named `Parent` at root
3. `add_node` — `Node` named `Child` as child of `Parent`

**Call:**
```json
{
  "script_path": "res://scripts/test_attach_nested.gd",
  "node_path": "Parent/Child"
}
```

**Expected result:**
- Status: success
- Script attached to `Parent/Child` node

**Notes:**
- Pay attention: node paths work like `Parent/Child` — slashes separate hierarchy levels

---

#### Scenario 4: Attach non-existent script

**Description:** Try to attach a script file that doesn't exist.

**Prerequisites:** `add_node` to create a target node.

**Call:**
```json
{
  "script_path": "res://scripts/nonexistent_attach_12345.gd",
  "node_path": "TestAttachTarget"
}
```

**Expected result:**
- Status: error (script file not found)

**Notes:**
- Pay attention: the error should indicate the missing script, not the node

---

#### Scenario 5: Attach script to non-existent node

**Description:** Try to attach script to a node that doesn't exist in the scene.

**Prerequisites:** `create_script` at `res://scripts/test_attach_no_node.gd`.

**Call:**
```json
{
  "script_path": "res://scripts/test_attach_no_node.gd",
  "node_path": "NonExistentNode_12345"
}
```

**Expected result:**
- Status: error (node not found)

**Notes:**
- Pay attention: the error should indicate the missing node

---

#### Scenario 6: Missing `script_path` parameter

**Description:** Call without `script_path`.

**Call:**
```json
{
  "node_path": "TestNode"
}
```

**Expected result:**
- Status: error (Zod validation — `script_path` required)

**Notes:**
- Pay attention: standard required field validation

---

#### Scenario 7: Missing `node_path` parameter

**Description:** Call without `node_path`.

**Call:**
```json
{
  "script_path": "res://scripts/test.gd"
}
```

**Expected result:**
- Status: error (Zod validation — `node_path` required)

**Notes:**
- Pay attention: `node_path` required, unlike in some other tools where it's optional

---

## Tool: `get_open_scripts`

**Description:** Get list of scripts currently open in the script editor

**Backend method:** `script/get_open`

### Parameters

None — the input schema is empty `{}`.

### Test Scenarios

#### Scenario 1: Get open scripts with no scripts open

**Description:** Call when no scripts are open in the editor.

**Call:**
```json
{}
```

**Expected result:**
- Status: success
- Result is an empty list/array `[]` or similar indicating no open scripts

**Notes:**
- Pay attention: even if no scripts are open, the result should be successful (empty list)

---

#### Scenario 2: Get open scripts after creating and opening a script

**Description:** After creating a script (which may auto-open it in Godot), check what's open.

**Prerequisites:** `create_script` at `res://scripts/test_open.gd` — Godot may auto-open the file in the script editor.

**Call:**
```json
{}
```

**Expected result:**
- Status: success
- Result contains at least one entry
- Entry includes the path `res://scripts/test_open.gd`

**Notes:**
- Pay attention: Godot may automatically open created scripts in the editor
- Document whether `create_script` auto-opens the file

---

#### Scenario 3: Get open scripts after opening a scene with attached scripts

**Description:** Open a scene that has nodes with scripts — those scripts may appear as open.

**Prerequisites:**
1. Create scene with `create_scene`
2. Add node and attach script
3. `open_scene` to open the scene

**Call:**
```json
{}
```

**Expected result:**
- Status: success
- Result may contain scripts attached to nodes in the opened scene

**Notes:**
- Pay attention: opening a scene may open associated scripts in the editor

---

## Tool: `validate_script`

**Description:** Validate a GDScript file for syntax errors

**Backend method:** `script/validate`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` | **Yes** | — | Script file path to validate |

### Test Scenarios

#### Scenario 1: Validate a syntactically correct script

**Description:** Validate a script with no errors.

**Prerequisites:** Create script at `res://scripts/test_valid.gd`:
```
extends Node

func _ready():
	print("Hello")
```

**Call:**
```json
{ "path": "res://scripts/test_valid.gd" }
```

**Expected result:**
- Status: success
- Result indicates no errors (empty errors list or `valid: true`)

**Notes:**
- Pay attention: the result must clearly indicate the absence of errors

---

#### Scenario 2: Validate a script with syntax errors

**Description:** Validate a script that has deliberate syntax errors.

**Prerequisites:** Create script at `res://scripts/test_invalid.gd`:
```
extends Node

func _ready():
	print("Hello"
```
(missing closing parenthesis)

**Call:**
```json
{ "path": "res://scripts/test_invalid.gd" }
```

**Expected result:**
- Status: success (validation itself succeeds, but reports errors)
- Result contains error information: line number, error message
- `isError` should be `false` (validation succeeded, found errors) — OR `true` if the tool treats validation errors as tool errors

**Notes:**
- Pay attention: **important to determine** whether a result with errors is `isError: true` or `false`
- The tool's job is to validate, so finding errors is a successful validation

---

#### Scenario 3: Validate a script with runtime errors (not syntax)

**Description:** Validate a script that has logical errors but valid syntax.

**Prerequisites:** Create script at `res://scripts/test_runtime_err.gd`:
```
extends Node

func _ready():
	var x = undefined_var
```

**Call:**
```json
{ "path": "res://scripts/test_runtime_err.gd" }
```

**Expected result:**
- Status: depends on whether validation checks semantic errors or only syntax
- Document whether the validator catches undefined variables

**Notes:**
- Pay attention: determine whether the validator checks semantic errors or only syntax

---

#### Scenario 4: Validate non-existent script

**Description:** Try to validate a script that doesn't exist.

**Call:**
```json
{ "path": "res://scripts/nonexistent_validate_12345.gd" }
```

**Expected result:**
- Status: error (file not found)

**Notes:**
- Pay attention: standard file not found error

---

#### Scenario 5: Missing required `path` parameter

**Description:** Call without `path`.

**Call:**
```json
{}
```

**Expected result:**
- Status: error (Zod validation — `path` required)

**Notes:**
- Pay attention: standard required field validation

---

## Tool: `search_in_files`

**Description:** Search for text across project files

**Backend method:** `script/search_in_files`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `query` | `string` | **Yes** | — | Search query |
| `file_pattern` | `string` | No | — | File pattern to search in (e.g. `*.gd`) |

### Test Scenarios

#### Scenario 1: Search for a known string across all files

**Description:** Search for a string that exists in a created script.

**Prerequisites:** Create script at `res://scripts/test_search.gd` with content containing `UNIQUE_MARKER_12345`.

**Call:**
```json
{ "query": "UNIQUE_MARKER_12345" }
```

**Expected result:**
- Status: success
- Result contains at least one match
- Match includes the file path `res://scripts/test_search.gd`

**Notes:**
- Pay attention: the unique string guarantees that found matches are from our test file

---

#### Scenario 2: Search with file_pattern filter (*.gd)

**Description:** Search only in `.gd` files.

**Prerequisites:** Same as Scenario 1.

**Call:**
```json
{
  "query": "UNIQUE_MARKER_12345",
  "file_pattern": "*.gd"
}
```

**Expected result:**
- Status: success
- Results only include `.gd` files

**Notes:**
- Pay attention: the `*.gd` filter should restrict search to GDScript files only

---

#### Scenario 3: Search with file_pattern filter (*.tscn)

**Description:** Search in scene files only — marker is in a `.gd` file, so should find nothing.

**Call:**
```json
{
  "query": "UNIQUE_MARKER_12345",
  "file_pattern": "*.tscn"
}
```

**Expected result:**
- Status: success
- Result is empty (no matches in `.tscn` files)

**Notes:**
- Pay attention: a non-positive result is also a valid search result

---

#### Scenario 4: Search for non-existent text

**Description:** Search for a string that doesn't exist anywhere in the project.

**Call:**
```json
{ "query": "THIS_STRING_DEFINITELY_DOES_NOT_EXIST_ANYWHERE_98765" }
```

**Expected result:**
- Status: success
- Result is empty list/array (no matches)

**Notes:**
- Pay attention: an empty result is a successful call, not an error

---

#### Scenario 5: Search with empty query

**Description:** Search with empty string query.

**Call:**
```json
{ "query": "" }
```

**Expected result:**
- Status: either success (returns everything or nothing) or error (invalid query)
- Document the behavior

**Notes:**
- Pay attention: `SearchQuery` = `z.string()`, empty string passes Zod
- Behavior with empty query may vary

---

#### Scenario 6: Missing required `query` parameter

**Description:** Call without `query`.

**Call:**
```json
{
  "file_pattern": "*.gd"
}
```

**Expected result:**
- Status: error (Zod validation — `query` required)

**Notes:**
- Pay attention: standard required field validation

---

#### Scenario 7: Search with special regex characters in query

**Description:** Search for text containing special characters.

**Prerequisites:** Create script with content containing `func [test]:` or similar.

**Call:**
```json
{ "query": "func [test]:" }
```

**Expected result:**
- Status: success
- Should find matches if the literal text exists
- Should NOT interpret `[` and `]` as regex

**Notes:**
- Pay attention: ensure that special characters do not break the search and are not interpreted as regex

---

## Integration Test Sequences

### Sequence A: Full CRUD lifecycle

**Purpose:** Verify the complete create → read → edit → validate → delete lifecycle.

```
Step 1: create_script
  → { path: "res://scripts/lifecycle_test.gd", content: "extends Node\n\nfunc _ready():\n\tprint('v1')\n" }
  → Expect: success

Step 2: read_script
  → { path: "res://scripts/lifecycle_test.gd" }
  → Expect: content matches what was created

Step 3: edit_script
  → { path: "res://scripts/lifecycle_test.gd", old_text: "print('v1')", new_text: "print('v2')" }
  → Expect: success

Step 4: read_script (verify edit)
  → { path: "res://scripts/lifecycle_test.gd" }
  → Expect: content contains "print('v2')" and NOT "print('v1')"

Step 5: validate_script
  → { path: "res://scripts/lifecycle_test.gd" }
  → Expect: no syntax errors

Step 6: delete_script
  → { path: "res://scripts/lifecycle_test.gd" }
  → Expect: success

Step 7: read_script (verify deletion)
  → { path: "res://scripts/lifecycle_test.gd" }
  → Expect: error (file not found)
```

### Sequence B: Script attachment workflow

**Purpose:** Verify creating a script, adding a node, and attaching the script.

```
Step 1: create_script
  → { path: "res://scripts/attach_test.gd", content: "extends Node\n\nfunc _ready():\n\tprint('Attached!')\n" }
  → Expect: success

Step 2: add_node (from node.ts)
  → { parent_path: "", type: "Node", name: "ScriptAttachTest" }
  → Expect: success

Step 3: attach_script
  → { script_path: "res://scripts/attach_test.gd", node_path: "ScriptAttachTest" }
  → Expect: success

Step 4: get_node_properties (from node.ts)
  → { path: "ScriptAttachTest" }
  → Expect: script property is set

Step 5: Cleanup — delete_node then delete_script
```

### Sequence C: Search + edit workflow

**Purpose:** Verify searching for content, then editing it, then searching again.

```
Step 1: create_script
  → { path: "res://scripts/search_edit_test.gd", content: "extends Node\n\nconst VALUE = 42\n" }
  → Expect: success

Step 2: search_in_files
  → { query: "VALUE = 42", file_pattern: "*.gd" }
  → Expect: found in search_edit_test.gd

Step 3: edit_script
  → { path: "res://scripts/search_edit_test.gd", old_text: "VALUE = 42", new_text: "VALUE = 100" }
  → Expect: success

Step 4: search_in_files
  → { query: "VALUE = 42" }
  → Expect: no longer found

Step 5: search_in_files
  → { query: "VALUE = 100" }
  → Expect: found in search_edit_test.gd

Step 6: Cleanup — delete_script
```

---

## Error Handling Matrix

| Scenario | Expected `isError` | Expected Message Pattern |
|----------|-------------------|------------------------|
| Missing required Zod field | `true` | Zod validation error (mentions field name) |
| Invalid Zod type (string for number) | `true` | Zod type error |
| Non-positive `max_depth` | `true` | Zod `positive()` error |
| File not found (read/edit/delete/validate/attach) | `true` | "not found" or "does not exist" |
| Node not found (attach_script) | `true` | "node not found" or similar |
| Old text not found (edit_script) | `true` | "text not found" or "no match" |
| Empty path | `true` | Godot-side error (empty string passes Zod) |
| Missing `res://` prefix | `true` | Godot-side path error |
| Godot editor disconnected | `true` | "Godot request failed" or bridge error |
| Godot request timeout | `true` | "timed out" |

---

## Cleanup Notes

**All test scenarios that create files or nodes MUST clean up after themselves.** Recommended cleanup sequence:

```
1. delete_node (if nodes were created)
2. delete_script (if scripts were created)
3. delete_scene (if scenes were created)
```

**Test isolation:** Each scenario should use unique file paths (e.g., `res://scripts/test_<tool>_<scenario>.gd`) to avoid conflicts when tests run in parallel.
