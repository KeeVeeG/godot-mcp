# Project Creation Tools — Test Plan

**Source file:** `server/src/tools/project_creation.ts`
**Shared types:** `server/src/tools/shared-types.ts`
**Number of tools:** 10
**Generated:** 2026-07-08

---

## Type Reference

| Zod schema | Underlying type | Description |
|---|---|---|
| `FilePath` | `z.string()` | File path (e.g. `'res://path/to/file'`) |
| `Name` | `z.string()` | Name identifier |
| `z.enum(['empty', '2d', '3d', 'ui', 'custom'])` | enum string | Project template type |
| `z.enum(['forward_plus', 'mobile', 'gl_compatibility'])` | enum string | Rendering engine type |
| `z.enum(['standard', 'minimal', 'full'])` | enum string | Folder structure preset |
| `z.enum(['basic', 'detailed', 'game'])` | enum string | README template style |
| `z.enum(['MIT', 'Apache-2.0', 'GPL-3.0', 'BSD-3-Clause', 'custom'])` | enum string | License type |
| `z.enum(['asset_lib', 'git', 'local'])` | enum string | Addon source type |
| `z.string()` | string | Generic string |
| `z.boolean()` | boolean | Boolean flag |
| `z.array(z.object({...}))` | array | Array of structured objects |

---

## Error Handling Patterns

All tools route through `callGodot(bridge, 'project_creation/<method>', args)`. Two possible failure modes:

1. **Zod validation error** — Client-side schema validation rejects mismatched types, missing required fields, or out-of-range enum values. Returns before the call reaches Godot.

2. **Godot bridge error** — The bridge itself fails (Godot not connected, timeout, or backend error in Godot's command handler). Wrapped as `"Godot request failed: <message>"` with `isError: true`.

---

## Tool 1: `create_project`

**Description:** Create a complete Godot project from scratch with proper structure and configuration
**Handler:** `callGodot(bridge, 'project_creation/create_project', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | FilePath (string) | **Yes** | — | Directory path where the project will be created |
| `name` | Name (string) | **Yes** | — | Project name |
| `template` | `'empty'` \| `'2d'` \| `'3d'` \| `'ui'` \| `'custom'` | No | — | Project template type |
| `godot_version` | string | No | — | Target Godot version (e.g. `'4.3'`) |
| `renderer` | `'forward_plus'` \| `'mobile'` \| `'gl_compatibility'` | No | — | Rendering engine |

### Test Scenarios

#### Scenario 1.1: Happy path — minimal required params only
- **Description:** Create a project with only the two required parameters (`path` + `name`). All optional params omitted.
- **Params:** `{ "path": "/tmp/test_project", "name": "MyGame" }`
- **Expected result:** Success. A Godot project is created at `/tmp/test_project` with the name "MyGame". Default template (`empty`) and default renderer are used if Godot has defaults; otherwise whatever the backend defaults to.

#### Scenario 1.2: Happy path — template = `'empty'`
- **Description:** Create a project with empty template explicitly set.
- **Params:** `{ "path": "/tmp/test_project", "name": "EmptyProject", "template": "empty" }`
- **Expected result:** Success. Project created with no pre-populated nodes or assets.

#### Scenario 1.3: Happy path — template = `'2d'`
- **Description:** Create a project with the 2D template.
- **Params:** `{ "path": "/tmp/test_project", "name": "Game2D", "template": "2d" }`
- **Expected result:** Success. Project created with 2D-specific starter scene (Node2D root, likely a sprite or camera).

#### Scenario 1.4: Happy path — template = `'3d'`
- **Description:** Create a project with the 3D template.
- **Params:** `{ "path": "/tmp/test_project", "name": "Game3D", "template": "3d" }`
- **Expected result:** Success. Project created with 3D-specific starter scene (Camera3D, light, maybe mesh).

#### Scenario 1.5: Happy path — template = `'ui'`
- **Description:** Create a project with the UI template.
- **Params:** `{ "path": "/tmp/test_project", "name": "UIApp", "template": "ui" }`
- **Expected result:** Success. Project created with UI-oriented starter scene (Control root).

#### Scenario 1.6: Happy path — template = `'custom'`
- **Description:** Create a project with the custom template type.
- **Params:** `{ "path": "/tmp/test_project", "name": "CustomGame", "template": "custom" }`
- **Expected result:** Success. Project created. Behavior depends on Godot's built-in custom template support.

#### Scenario 1.7: Happy path — renderer = `'forward_plus'`
- **Description:** Create a project with Forward+ renderer explicitly set.
- **Params:** `{ "path": "/tmp/test_project", "name": "FwdPlusProject", "renderer": "forward_plus" }`
- **Expected result:** Success. Project uses the Forward+ rendering backend.

#### Scenario 1.8: Happy path — renderer = `'mobile'`
- **Description:** Create a project with the Mobile renderer.
- **Params:** `{ "path": "/tmp/test_project", "name": "MobileProject", "renderer": "mobile" }`
- **Expected result:** Success. Project uses the Mobile rendering backend.

#### Scenario 1.9: Happy path — renderer = `'gl_compatibility'`
- **Description:** Create a project with the GL Compatibility renderer.
- **Params:** `{ "path": "/tmp/test_project", "name": "CompatProject", "renderer": "gl_compatibility" }`
- **Expected result:** Success. Project uses the OpenGL compatibility rendering backend.

#### Scenario 1.10: Happy path — all parameters filled
- **Description:** Create a project with every parameter specified.
- **Params:** `{ "path": "/tmp/test_project", "name": "FullGame", "template": "3d", "godot_version": "4.3", "renderer": "forward_plus" }`
- **Expected result:** Success. Project created with 3D template, targeting Godot 4.3, using Forward+ renderer.

#### Scenario 1.11: Happy path — godot_version with patch version
- **Description:** Set a full semver-like version string including patch.
- **Params:** `{ "path": "/tmp/test_project", "name": "PinnedVersion", "godot_version": "4.2.1" }`
- **Expected result:** Success (or possibly rejected by Godot if version doesn't match — implementation-dependent).

#### Scenario 1.12: Edge — missing required param `path`
- **Description:** Call without the required `path` parameter.
- **Params:** `{ "name": "NoPath" }`
- **Expected result:** Zod validation error. `path` is required.

#### Scenario 1.13: Edge — missing required param `name`
- **Description:** Call without the required `name` parameter.
- **Params:** `{ "path": "/tmp/test_project" }`
- **Expected result:** Zod validation error. `name` is required.

#### Scenario 1.14: Edge — empty string path
- **Description:** Call with an empty `path` string.
- **Params:** `{ "path": "", "name": "EmptyPath" }`
- **Expected result:** Godot bridge error (invalid path or cannot create project there).

#### Scenario 1.15: Edge — empty string name
- **Description:** Call with an empty `name` string.
- **Params:** `{ "path": "/tmp/test_project", "name": "" }`
- **Expected result:** Possibly succeeds (z.string() allows empty by default) or Godot rejects the empty name.

#### Scenario 1.16: Edge — invalid template value
- **Description:** Call with a template string not in the enum.
- **Params:** `{ "path": "/tmp/test_project", "name": "BadTemplate", "template": "vr" }`
- **Expected result:** Zod validation error. `template` must be one of `'empty'`, `'2d'`, `'3d'`, `'ui'`, `'custom'`.

#### Scenario 1.17: Edge — invalid renderer value
- **Description:** Call with a renderer string not in the enum.
- **Params:** `{ "path": "/tmp/test_project", "name": "BadRenderer", "renderer": "vulkan" }`
- **Expected result:** Zod validation error. `renderer` must be one of `'forward_plus'`, `'mobile'`, `'gl_compatibility'`.

#### Scenario 1.18: Edge — path already exists as non-empty directory
- **Description:** Call where `path` points to an existing directory with files in it.
- **Params:** `{ "path": "/tmp/existing_dir", "name": "Overwrite" }`
- **Expected result:** Godot bridge error (directory not empty or project already exists).

#### Scenario 1.19: Edge — path with special characters
- **Description:** Call with a path containing special characters (`../`, spaces, etc.).
- **Params:** `{ "path": "/tmp/test project!@#", "name": "SpecialPath" }`
- **Expected result:** Depends on OS/filesystem. Either success or Godot/OS error for invalid characters.

#### Scenario 1.20: Edge — very long name string
- **Description:** Call with a name of 10,000 characters.
- **Params:** `{ "path": "/tmp/test_project", "name": "A".repeat(10000) }`
- **Expected result:** Likely Godot bridge error (project name too long) or success with truncated name.

#### Scenario 1.21: Edge — name with special characters
- **Description:** Call with name containing `/`, `\`, or other filesystem-special characters.
- **Params:** `{ "path": "/tmp/test_project", "name": "Game/Variant" }`
- **Expected result:** Godot bridge error (invalid project name).

#### Scenario 1.22: Edge — godot_version as number
- **Description:** Call with a numeric godot_version instead of string.
- **Params:** `{ "path": "/tmp/test_project", "name": "NumVersion", "godot_version": 4.3 }`
- **Expected result:** Zod validation error. Expected string, got number.

#### Scenario 1.23: Edge — godot_version empty string
- **Description:** Call with empty string for godot_version.
- **Params:** `{ "path": "/tmp/test_project", "name": "EmptyVer", "godot_version": "" }`
- **Expected result:** Likely Godot rejection or treated as "no version specified" (same as omitting).

#### Scenario 1.24: Edge — additional unknown property
- **Description:** Call with an extra property not in the schema.
- **Params:** `{ "path": "/tmp/test_project", "name": "ExtraProps", "foo": "bar" }`
- **Expected result:** Depends on Zod strictness. The schema does not use `.strict()`, so unknown keys are silently stripped. The project creates normally.

---

## Tool 2: `create_project_from_template`

**Description:** Create a new Godot project from an existing template project
**Handler:** `callGodot(bridge, 'project_creation/create_from_template', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | FilePath (string) | **Yes** | — | Directory path where the project will be created |
| `template_path` | FilePath (string) | **Yes** | — | Path to the template project directory |
| `name` | Name (string) | No | — | Override project name |

### Test Scenarios

#### Scenario 2.1: Happy path — minimal required params only
- **Description:** Create a project from a valid template project using only required params.
- **Params:** `{ "path": "/tmp/new_project", "template_path": "/path/to/existing/template" }`
- **Expected result:** Success. New project created at `path`, copying from `template_path`. Project name derived from template.

#### Scenario 2.2: Happy path — with explicit name override
- **Description:** Create a project from template, overriding the project name.
- **Params:** `{ "path": "/tmp/new_project", "template_path": "/path/to/existing/template", "name": "MyForkedGame" }`
- **Expected result:** Success. New project created with the overridden name "MyForkedGame".

#### Scenario 2.3: Edge — missing required param `path`
- **Description:** Call without `path`.
- **Params:** `{ "template_path": "/path/to/template" }`
- **Expected result:** Zod validation error. `path` is required.

#### Scenario 2.4: Edge — missing required param `template_path`
- **Description:** Call without `template_path`.
- **Params:** `{ "path": "/tmp/new_project" }`
- **Expected result:** Zod validation error. `template_path` is required.

#### Scenario 2.5: Edge — template_path does not exist
- **Description:** Call with a `template_path` pointing to a non-existent directory.
- **Params:** `{ "path": "/tmp/new_project", "template_path": "/nonexistent/template" }`
- **Expected result:** Godot bridge error. Template source not found.

#### Scenario 2.6: Edge — template_path is not a Godot project
- **Description:** Call with a `template_path` pointing to a directory that is NOT a valid Godot project.
- **Params:** `{ "path": "/tmp/new_project", "template_path": "/tmp/random_folder" }`
- **Expected result:** Godot bridge error. Invalid template (no project.godot found).

#### Scenario 2.7: Edge — path already exists
- **Description:** Call where the destination `path` already contains a project.
- **Params:** `{ "path": "/tmp/existing_project", "template_path": "/path/to/template" }`
- **Expected result:** Godot bridge error. Destination already exists.

#### Scenario 2.8: Edge — path same as template_path
- **Description:** Try to create a project into the same directory as the template.
- **Params:** `{ "path": "/path/to/template", "template_path": "/path/to/template" }`
- **Expected result:** Godot bridge error. Cannot copy a template into itself.

#### Scenario 2.9: Edge — name with special characters
- **Description:** Override name with filesystem-special characters.
- **Params:** `{ "path": "/tmp/new_project", "template_path": "/path/to/template", "name": "Game/Slash" }`
- **Expected result:** Godot bridge error (invalid project name).

#### Scenario 2.10: Edge — empty string name override
- **Description:** Call with empty string for the name override.
- **Params:** `{ "path": "/tmp/new_project", "template_path": "/path/to/template", "name": "" }`
- **Expected result:** Godot bridge error (empty name) or uses template's project name as fallback.

#### Scenario 2.11: Edge — relative template_path
- **Description:** Use a relative path for `template_path`.
- **Params:** `{ "path": "/tmp/new_project", "template_path": "../sibling_template" }`
- **Expected result:** Depends on implementation. Likely resolved relative to the Godot project root, or rejected.

---

## Tool 3: `scaffold_project_structure`

**Description:** Create a standard folder structure for a Godot project
**Handler:** `callGodot(bridge, 'project_creation/scaffold_structure', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `project_path` | FilePath (string) | **Yes** | — | Path to the Godot project root |
| `structure` | `'standard'` \| `'minimal'` \| `'full'` | No | — | Folder structure preset |

### Test Scenarios

#### Scenario 3.1: Happy path — required param only (no structure enum)
- **Description:** Scaffold a project folder structure with only `project_path`. The `structure` param is optional — if omitted, Godot backend picks the default.
- **Params:** `{ "project_path": "/tmp/my_project" }`
- **Expected result:** Success. Default folder structure created under `/tmp/my_project`.

#### Scenario 3.2: Happy path — structure = `'standard'`
- **Description:** Scaffold using the standard preset.
- **Params:** `{ "project_path": "/tmp/my_project", "structure": "standard" }`
- **Expected result:** Success. Standard folders (e.g. `scenes/`, `scripts/`, `assets/`) created.

#### Scenario 3.3: Happy path — structure = `'minimal'`
- **Description:** Scaffold using the minimal preset.
- **Params:** `{ "project_path": "/tmp/my_project", "structure": "minimal" }`
- **Expected result:** Success. Only essential folders created (fewer than standard).

#### Scenario 3.4: Happy path — structure = `'full'`
- **Description:** Scaffold using the full preset.
- **Params:** `{ "project_path": "/tmp/my_project", "structure": "full" }`
- **Expected result:** Success. Exhaustive folder tree created (scenes, scripts, shaders, materials, audio, etc.).

#### Scenario 3.5: Edge — missing required param `project_path`
- **Description:** Call without `project_path`.
- **Params:** `{ "structure": "standard" }`
- **Expected result:** Zod validation error. `project_path` is required.

#### Scenario 3.6: Edge — invalid structure value
- **Description:** Call with a structure string not in the enum.
- **Params:** `{ "project_path": "/tmp/my_project", "structure": "huge" }`
- **Expected result:** Zod validation error. `structure` must be one of `'standard'`, `'minimal'`, `'full'`.

#### Scenario 3.7: Edge — project_path does not exist
- **Description:** Point `project_path` to a non-existent directory.
- **Params:** `{ "project_path": "/tmp/nonexistent_project" }`
- **Expected result:** Godot bridge error. Directory does not exist or is not a Godot project.

#### Scenario 3.8: Edge — project_path is not a Godot project
- **Description:** Point `project_path` to a directory without `project.godot`.
- **Params:** `{ "project_path": "/tmp/not_a_project" }`
- **Expected result:** Godot bridge error. Not a valid Godot project root.

#### Scenario 3.9: Edge — run scaffold twice on same path
- **Description:** Call scaffold twice in a row on the same project.
- **Params:** (first call) `{ "project_path": "/tmp/my_project", "structure": "standard" }`;
  (second call) `{ "project_path": "/tmp/my_project", "structure": "full" }`
- **Expected result:** Second call may succeed (adding missing folders) or fail (folders already exist). Depends on backend implementation.

#### Scenario 3.10: Edge — empty string project_path
- **Description:** Call with an empty `project_path` string.
- **Params:** `{ "project_path": "" }`
- **Expected result:** Godot bridge error (invalid path).

---

## Tool 4: `create_project_with_assets`

**Description:** Create a new Godot project and import specified assets into it
**Handler:** `callGodot(bridge, 'project_creation/create_with_assets', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | FilePath (string) | **Yes** | — | Directory path where the project will be created |
| `name` | Name (string) | **Yes** | — | Project name |
| `assets` | `Array<{type: string, source: string, destination: string}>` | **Yes** | — | List of assets to import into the project |

### Test Scenarios

#### Scenario 4.1: Happy path — single asset (texture)
- **Description:** Create a project and import one texture asset.
- **Params:**
  ```json
  {
    "path": "/tmp/my_project",
    "name": "AssetGame",
    "assets": [
      {
        "type": "texture",
        "source": "/tmp/source/icon.png",
        "destination": "res://assets/icon.png"
      }
    ]
  }
  ```
- **Expected result:** Success. Project created with the texture imported at `res://assets/icon.png`.

#### Scenario 4.2: Happy path — single asset (audio)
- **Description:** Create a project and import one audio asset.
- **Params:**
  ```json
  {
    "path": "/tmp/my_project",
    "name": "AudioGame",
    "assets": [
      {
        "type": "audio",
        "source": "/tmp/source/bgm.ogg",
        "destination": "res://audio/bgm.ogg"
      }
    ]
  }
  ```
- **Expected result:** Success. Project created with audio file imported.

#### Scenario 4.3: Happy path — single asset (scene)
- **Description:** Create a project and import one scene asset.
- **Params:**
  ```json
  {
    "path": "/tmp/my_project",
    "name": "SceneGame",
    "assets": [
      {
        "type": "scene",
        "source": "/tmp/source/level.tscn",
        "destination": "res://scenes/level.tscn"
      }
    ]
  }
  ```
- **Expected result:** Success. Project created with scene file imported.

#### Scenario 4.4: Happy path — single asset (script)
- **Description:** Create a project and import one script asset.
- **Params:**
  ```json
  {
    "path": "/tmp/my_project",
    "name": "ScriptGame",
    "assets": [
      {
        "type": "script",
        "source": "/tmp/source/player.gd",
        "destination": "res://scripts/player.gd"
      }
    ]
  }
  ```
- **Expected result:** Success. Project created with GDScript file imported.

#### Scenario 4.5: Happy path — multiple assets of mixed types
- **Description:** Create a project and import multiple assets of different types.
- **Params:**
  ```json
  {
    "path": "/tmp/my_project",
    "name": "FullGame",
    "assets": [
      { "type": "texture", "source": "/tmp/src/sprite.png", "destination": "res://assets/sprite.png" },
      { "type": "audio", "source": "/tmp/src/music.ogg", "destination": "res://audio/music.ogg" },
      { "type": "scene", "source": "/tmp/src/main.tscn", "destination": "res://scenes/main.tscn" },
      { "type": "script", "source": "/tmp/src/main.gd", "destination": "res://scripts/main.gd" }
    ]
  }
  ```
- **Expected result:** Success. All four assets imported into their respective destinations.

#### Scenario 4.6: Happy path — assets array with one element
- **Description:** Create project with exactly one asset in the array.
- **Params:** (same as Scenario 4.1)
- **Expected result:** Success. Single asset imported.

#### Scenario 4.7: Happy path — empty assets array
- **Description:** Create project with an empty assets array.
- **Params:**
  ```json
  {
    "path": "/tmp/my_project",
    "name": "EmptyAssets",
    "assets": []
  }
  ```
- **Expected result:** Success. Project created with no additional assets imported (equivalent to `create_project`).

#### Scenario 4.8: Edge — missing required param `path`
- **Description:** Call without `path`.
- **Params:** `{ "name": "NoPath", "assets": [] }`
- **Expected result:** Zod validation error. `path` is required.

#### Scenario 4.9: Edge — missing required param `name`
- **Description:** Call without `name`.
- **Params:** `{ "path": "/tmp/my_project", "assets": [] }`
- **Expected result:** Zod validation error. `name` is required.

#### Scenario 4.10: Edge — missing required param `assets`
- **Description:** Call without `assets`.
- **Params:** `{ "path": "/tmp/my_project", "name": "NoAssets" }`
- **Expected result:** Zod validation error. `assets` is required.

#### Scenario 4.11: Edge — asset object missing `type` field
- **Description:** An asset entry without the required `type` field.
- **Params:**
  ```json
  {
    "path": "/tmp/my_project",
    "name": "BadAsset",
    "assets": [
      { "source": "/tmp/src/img.png", "destination": "res://img.png" }
    ]
  }
  ```
- **Expected result:** Zod validation error. Asset object is missing required `type`.

#### Scenario 4.12: Edge — asset object missing `source` field
- **Description:** An asset entry without the required `source` field.
- **Params:**
  ```json
  {
    "path": "/tmp/my_project",
    "name": "BadAsset",
    "assets": [
      { "type": "texture", "destination": "res://img.png" }
    ]
  }
  ```
- **Expected result:** Zod validation error. Asset object is missing required `source`.

#### Scenario 4.13: Edge — asset object missing `destination` field
- **Description:** An asset entry without the required `destination` field.
- **Params:**
  ```json
  {
    "path": "/tmp/my_project",
    "name": "BadAsset",
    "assets": [
      { "type": "texture", "source": "/tmp/src/img.png" }
    ]
  }
  ```
- **Expected result:** Zod validation error. Asset object is missing required `destination`.

#### Scenario 4.14: Edge — asset source file does not exist
- **Description:** Import an asset where `source` points to a file that doesn't exist.
- **Params:**
  ```json
  {
    "path": "/tmp/my_project",
    "name": "MissingSrc",
    "assets": [
      { "type": "texture", "source": "/tmp/src/does_not_exist.png", "destination": "res://img.png" }
    ]
  }
  ```
- **Expected result:** Godot bridge error. Source file not found.

#### Scenario 4.15: Edge — asset type is an unrecognized value
- **Description:** Use an asset `type` that Godot doesn't know how to import.
- **Params:**
  ```json
  {
    "path": "/tmp/my_project",
    "name": "BadType",
    "assets": [
      { "type": "unknown_type", "source": "/tmp/src/file.txt", "destination": "res://file.txt" }
    ]
  }
  ```
- **Expected result:** Godot bridge error. Unknown/unrecognized asset type, or possibly succeeds with generic import.

#### Scenario 4.16: Edge — destination uses non-res:// path
- **Description:** Asset destination does not use the `res://` prefix.
- **Params:**
  ```json
  {
    "path": "/tmp/my_project",
    "name": "BadDest",
    "assets": [
      { "type": "texture", "source": "/tmp/src/img.png", "destination": "/absolute/path/img.png" }
    ]
  }
  ```
- **Expected result:** Godot bridge error. Destination must be within the project (res://).

#### Scenario 4.17: Edge — assets is not an array
- **Description:** Pass a single object instead of an array for `assets`.
- **Params:**
  ```json
  {
    "path": "/tmp/my_project",
    "name": "NotArray",
    "assets": { "type": "texture", "source": "/tmp/src/img.png", "destination": "res://img.png" }
  }
  ```
- **Expected result:** Zod validation error. Expected array, got object.

---

## Tool 5: `initialize_git_repository`

**Description:** Initialize a Git repository in the project directory with a proper .gitignore
**Handler:** `callGodot(bridge, 'project_creation/init_git', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `project_path` | FilePath (string) | **Yes** | — | Path to the Godot project root |
| `include_gitignore` | boolean | No | — | Whether to create a Godot-specific .gitignore |

### Test Scenarios

#### Scenario 5.1: Happy path — required param only
- **Description:** Initialize a git repo with just `project_path`. `include_gitignore` omitted.
- **Params:** `{ "project_path": "/tmp/my_project" }`
- **Expected result:** Success. `git init` runs in the project directory. `.gitignore` behavior depends on backend default.

#### Scenario 5.2: Happy path — include_gitignore = `true`
- **Description:** Initialize git repo and explicitly request a .gitignore.
- **Params:** `{ "project_path": "/tmp/my_project", "include_gitignore": true }`
- **Expected result:** Success. Git repo initialized AND a Godot-specific .gitignore file is created.

#### Scenario 5.3: Happy path — include_gitignore = `false`
- **Description:** Initialize git repo but explicitly skip .gitignore creation.
- **Params:** `{ "project_path": "/tmp/my_project", "include_gitignore": false }`
- **Expected result:** Success. Git repo initialized but NO .gitignore file is created.

#### Scenario 5.4: Edge — missing required param `project_path`
- **Description:** Call without `project_path`.
- **Params:** `{ "include_gitignore": true }`
- **Expected result:** Zod validation error. `project_path` is required.

#### Scenario 5.5: Edge — project_path does not exist
- **Description:** Point to a non-existent directory.
- **Params:** `{ "project_path": "/tmp/nonexistent" }`
- **Expected result:** Godot bridge error. Directory does not exist.

#### Scenario 5.6: Edge — git already initialized
- **Description:** Call `init_git` on a project that already has a `.git` directory.
- **Params:** `{ "project_path": "/tmp/my_project", "include_gitignore": true }`
- **Expected result:** Godot bridge error (git already exists) or succeeds (reinit is idempotent in git).

#### Scenario 5.7: Edge — include_gitignore as string
- **Description:** Pass a string instead of boolean for `include_gitignore`.
- **Params:** `{ "project_path": "/tmp/my_project", "include_gitignore": "yes" }`
- **Expected result:** Zod validation error. Expected boolean, got string.

#### Scenario 5.8: Edge — project_path is not a Godot project
- **Description:** Initialize git in a directory that exists but has no `project.godot`.
- **Params:** `{ "project_path": "/tmp/not_a_project" }`
- **Expected result:** May succeed (git init doesn't require Godot) or Godot rejects it. Implementation-dependent.

#### Scenario 5.9: Edge — no write permissions on project_path
- **Description:** Try to init git in a read-only directory.
- **Params:** `{ "project_path": "/readonly_dir" }`
- **Expected result:** Godot bridge error. Permission denied / cannot write.

---

## Tool 6: `create_project_readme`

**Description:** Generate a README.md file for the project
**Handler:** `callGodot(bridge, 'project_creation/create_readme', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `project_path` | FilePath (string) | **Yes** | — | Path to the Godot project root |
| `content` | string | No | — | Custom README content (overrides template) |
| `template` | `'basic'` \| `'detailed'` \| `'game'` | No | — | README template style |

### Test Scenarios

#### Scenario 6.1: Happy path — required param only
- **Description:** Generate a README with only `project_path`. No template or content specified — backend uses its default.
- **Params:** `{ "project_path": "/tmp/my_project" }`
- **Expected result:** Success. A README.md file is created using the default template style.

#### Scenario 6.2: Happy path — template = `'basic'`
- **Description:** Generate a README using the basic template.
- **Params:** `{ "project_path": "/tmp/my_project", "template": "basic" }`
- **Expected result:** Success. README.md created with minimal content (project name, brief description).

#### Scenario 6.3: Happy path — template = `'detailed'`
- **Description:** Generate a README using the detailed template.
- **Params:** `{ "project_path": "/tmp/my_project", "template": "detailed" }`
- **Expected result:** Success. README.md created with comprehensive sections (install, usage, build, etc.).

#### Scenario 6.4: Happy path — template = `'game'`
- **Description:** Generate a README using the game-specific template.
- **Params:** `{ "project_path": "/tmp/my_project", "template": "game" }`
- **Expected result:** Success. README.md created with game-oriented sections (story, controls, screenshots, etc.).

#### Scenario 6.5: Happy path — custom content (overrides template)
- **Description:** Provide custom content — should override any template.
- **Params:** `{ "project_path": "/tmp/my_project", "content": "# Custom Game\nThis is my custom README." }`
- **Expected result:** Success. README.md contains exactly the provided custom content, ignoring any template.

#### Scenario 6.6: Happy path — custom content with template ignored
- **Description:** Provide both `content` and `template`. Content should take precedence.
- **Params:** `{ "project_path": "/tmp/my_project", "content": "# Custom Override", "template": "detailed" }`
- **Expected result:** Success. README.md contains "Custom Override", NOT the detailed template content.

#### Scenario 6.7: Edge — missing required param `project_path`
- **Description:** Call without `project_path`.
- **Params:** `{ "template": "basic" }`
- **Expected result:** Zod validation error. `project_path` is required.

#### Scenario 6.8: Edge — invalid template value
- **Description:** Call with a template string not in the enum.
- **Params:** `{ "project_path": "/tmp/my_project", "template": "fancy" }`
- **Expected result:** Zod validation error. `template` must be one of `'basic'`, `'detailed'`, `'game'`.

#### Scenario 6.9: Edge — project_path does not exist
- **Description:** Point to a non-existent directory.
- **Params:** `{ "project_path": "/tmp/nonexistent" }`
- **Expected result:** Godot bridge error. Directory not found.

#### Scenario 6.10: Edge — README already exists
- **Description:** Generate a README when README.md already exists in the project.
- **Params:** `{ "project_path": "/tmp/my_project", "template": "basic" }`
- **Expected result:** Godot bridge error (file already exists) or success (overwrites existing README). Implementation-dependent.

#### Scenario 6.11: Edge — empty custom content
- **Description:** Provide an empty string for `content`.
- **Params:** `{ "project_path": "/tmp/my_project", "content": "" }`
- **Expected result:** Either creates an empty README.md or falls back to default template. Implementation-dependent.

#### Scenario 6.12: Edge — very large custom content
- **Description:** Provide a 1MB string as custom content.
- **Params:** `{ "project_path": "/tmp/my_project", "content": "x".repeat(1048576) }`
- **Expected result:** Possibly succeeds (large file written) or Godot timeout / memory issue.

#### Scenario 6.13: Edge — content as number
- **Description:** Pass a number instead of string for `content`.
- **Params:** `{ "project_path": "/tmp/my_project", "content": 12345 }`
- **Expected result:** Zod validation error. Expected string, got number.

---

## Tool 7: `create_project_license`

**Description:** Create a LICENSE file for the project
**Handler:** `callGodot(bridge, 'project_creation/create_license', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `project_path` | FilePath (string) | **Yes** | — | Path to the Godot project root |
| `license` | `'MIT'` \| `'Apache-2.0'` \| `'GPL-3.0'` \| `'BSD-3-Clause'` \| `'custom'` | **Yes** | — | License type |
| `custom_text` | string | No | — | Custom license text (required when license is `'custom'`) |

### Test Scenarios

#### Scenario 7.1: Happy path — license = `'MIT'`
- **Description:** Create an MIT LICENSE file.
- **Params:** `{ "project_path": "/tmp/my_project", "license": "MIT" }`
- **Expected result:** Success. A LICENSE file containing the standard MIT license text is created.

#### Scenario 7.2: Happy path — license = `'Apache-2.0'`
- **Description:** Create an Apache 2.0 LICENSE file.
- **Params:** `{ "project_path": "/tmp/my_project", "license": "Apache-2.0" }`
- **Expected result:** Success. LICENSE file with Apache 2.0 text created.

#### Scenario 7.3: Happy path — license = `'GPL-3.0'`
- **Description:** Create a GPL 3.0 LICENSE file.
- **Params:** `{ "project_path": "/tmp/my_project", "license": "GPL-3.0" }`
- **Expected result:** Success. LICENSE file with GPL 3.0 text created.

#### Scenario 7.4: Happy path — license = `'BSD-3-Clause'`
- **Description:** Create a BSD 3-Clause LICENSE file.
- **Params:** `{ "project_path": "/tmp/my_project", "license": "BSD-3-Clause" }`
- **Expected result:** Success. LICENSE file with BSD 3-Clause text created.

#### Scenario 7.5: Happy path — license = `'custom'` with `custom_text` provided
- **Description:** Create a LICENSE file with a custom license text.
- **Params:** `{ "project_path": "/tmp/my_project", "license": "custom", "custom_text": "Copyright (c) 2026 My Company\nAll Rights Reserved." }`
- **Expected result:** Success. LICENSE file contains the exact custom text provided.

#### Scenario 7.6: Edge — missing required param `project_path`
- **Description:** Call without `project_path`.
- **Params:** `{ "license": "MIT" }`
- **Expected result:** Zod validation error. `project_path` is required.

#### Scenario 7.7: Edge — missing required param `license`
- **Description:** Call without `license`.
- **Params:** `{ "project_path": "/tmp/my_project" }`
- **Expected result:** Zod validation error. `license` is required.

#### Scenario 7.8: Edge — license = `'custom'` without `custom_text`
- **Description:** Create a custom license but omit the required `custom_text`.
- **Params:** `{ "project_path": "/tmp/my_project", "license": "custom" }`
- **Expected result:** Zod accepts it (custom_text is optional in schema) but likely Godot bridge error (custom license text is required when license is 'custom').

#### Scenario 7.9: Edge — invalid license value
- **Description:** Use a license string not in the enum.
- **Params:** `{ "project_path": "/tmp/my_project", "license": "WTFPL" }`
- **Expected result:** Zod validation error. `license` must be one of `'MIT'`, `'Apache-2.0'`, `'GPL-3.0'`, `'BSD-3-Clause'`, `'custom'`.

#### Scenario 7.10: Edge — project_path does not exist
- **Description:** Point to a non-existent project directory.
- **Params:** `{ "project_path": "/tmp/nonexistent", "license": "MIT" }`
- **Expected result:** Godot bridge error. Directory not found.

#### Scenario 7.11: Edge — LICENSE file already exists
- **Description:** Try to create a LICENSE when one already exists.
- **Params:** `{ "project_path": "/tmp/my_project", "license": "GPL-3.0" }`
- **Expected result:** Godot bridge error (file exists) or overwrites. Implementation-dependent.

#### Scenario 7.12: Edge — custom_text provided with non-custom license
- **Description:** Provide `custom_text` when license is `'MIT'`.
- **Params:** `{ "project_path": "/tmp/my_project", "license": "MIT", "custom_text": "Some custom text" }`
- **Expected result:** The `custom_text` is likely ignored (backend uses MIT template) or raises a warning. Implementation-dependent.

#### Scenario 7.13: Edge — empty custom_text with license = 'custom'
- **Description:** Use empty string for custom_text with custom license.
- **Params:** `{ "project_path": "/tmp/my_project", "license": "custom", "custom_text": "" }`
- **Expected result:** Creates an empty LICENSE file or Godot rejects empty custom text. Implementation-dependent.

#### Scenario 7.14: Edge — license as number
- **Description:** Pass a non-string value for license.
- **Params:** `{ "project_path": "/tmp/my_project", "license": 0 }`
- **Expected result:** Zod validation error. Expected enum string, got number.

---

## Tool 8: `setup_project_dependencies`

**Description:** Install and configure project addons/dependencies
**Handler:** `callGodot(bridge, 'project_creation/setup_dependencies', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `project_path` | FilePath (string) | **Yes** | — | Path to the Godot project root |
| `addons` | `Array<{name: string, source: 'asset_lib'\|'git'\|'local', url?: string}>` | **Yes** | — | List of addons to install |

### Test Scenarios

#### Scenario 8.1: Happy path — single addon from asset_lib
- **Description:** Install one addon from the Asset Library.
- **Params:**
  ```json
  {
    "project_path": "/tmp/my_project",
    "addons": [
      { "name": "godot-jolt", "source": "asset_lib" }
    ]
  }
  ```
- **Expected result:** Success. The addon is downloaded and installed from the Godot Asset Library.

#### Scenario 8.2: Happy path — single addon from git (with url)
- **Description:** Install one addon from a git repository.
- **Params:**
  ```json
  {
    "project_path": "/tmp/my_project",
    "addons": [
      { "name": "my-addon", "source": "git", "url": "https://github.com/user/repo.git" }
    ]
  }
  ```
- **Expected result:** Success. The addon is cloned/installed from the git URL.

#### Scenario 8.3: Happy path — single addon from local (with url)
- **Description:** Install one addon from a local directory path.
- **Params:**
  ```json
  {
    "project_path": "/tmp/my_project",
    "addons": [
      { "name": "local-addon", "source": "local", "url": "/path/to/local/addon" }
    ]
  }
  ```
- **Expected result:** Success. The addon is copied from the local path into the project.

#### Scenario 8.4: Happy path — multiple addons, mixed sources
- **Description:** Install several addons from various sources in one call.
- **Params:**
  ```json
  {
    "project_path": "/tmp/my_project",
    "addons": [
      { "name": "addon-a", "source": "asset_lib" },
      { "name": "addon-b", "source": "git", "url": "https://github.com/user/repo.git" },
      { "name": "addon-c", "source": "local", "url": "/path/to/local/addon" }
    ]
  }
  ```
- **Expected result:** Success. All three addons installed from their respective sources.

#### Scenario 8.5: Happy path — single addon from asset_lib with url (url should be ignored)
- **Description:** asset_lib source doesn't need a URL. If provided, it should be ignored.
- **Params:**
  ```json
  {
    "project_path": "/tmp/my_project",
    "addons": [
      { "name": "some-addon", "source": "asset_lib", "url": "https://example.com/ignored" }
    ]
  }
  ```
- **Expected result:** Success. URL is ignored; addon installed from Asset Library.

#### Scenario 8.6: Edge — missing required param `project_path`
- **Description:** Call without `project_path`.
- **Params:** `{ "addons": [] }`
- **Expected result:** Zod validation error. `project_path` is required.

#### Scenario 8.7: Edge — missing required param `addons`
- **Description:** Call without `addons`.
- **Params:** `{ "project_path": "/tmp/my_project" }`
- **Expected result:** Zod validation error. `addons` is required.

#### Scenario 8.8: Edge — addon object missing `name`
- **Description:** An addon entry missing the required `name` field.
- **Params:**
  ```json
  {
    "project_path": "/tmp/my_project",
    "addons": [
      { "source": "asset_lib" }
    ]
  }
  ```
- **Expected result:** Zod validation error. Addon object is missing required `name`.

#### Scenario 8.9: Edge — addon object missing `source`
- **Description:** An addon entry missing the required `source` field.
- **Params:**
  ```json
  {
    "project_path": "/tmp/my_project",
    "addons": [
      { "name": "my-addon" }
    ]
  }
  ```
- **Expected result:** Zod validation error. Addon object is missing required `source`.

#### Scenario 8.10: Edge — invalid source value
- **Description:** Use a source value not in the enum.
- **Params:**
  ```json
  {
    "project_path": "/tmp/my_project",
    "addons": [
      { "name": "my-addon", "source": "marketplace" }
    ]
  }
  ```
- **Expected result:** Zod validation error. `source` must be one of `'asset_lib'`, `'git'`, `'local'`.

#### Scenario 8.11: Edge — git source without url
- **Description:** Install a git addon but omit the `url` field.
- **Params:**
  ```json
  {
    "project_path": "/tmp/my_project",
    "addons": [
      { "name": "my-addon", "source": "git" }
    ]
  }
  ```
- **Expected result:** Godot bridge error. Git source requires a URL.

#### Scenario 8.12: Edge — local source without url
- **Description:** Install a local addon but omit the `url` (local path).
- **Params:**
  ```json
  {
    "project_path": "/tmp/my_project",
    "addons": [
      { "name": "my-addon", "source": "local" }
    ]
  }
  ```
- **Expected result:** Godot bridge error. Local source requires a URL (local path).

#### Scenario 8.13: Edge — empty addons array
- **Description:** Call with an empty addons list.
- **Params:**
  ```json
  {
    "project_path": "/tmp/my_project",
    "addons": []
  }
  ```
- **Expected result:** Success (no-op) or Godot error. Implementation-dependent.

#### Scenario 8.14: Edge — project_path does not exist
- **Description:** Point to a non-existent project.
- **Params:**
  ```json
  {
    "project_path": "/tmp/nonexistent",
    "addons": [
      { "name": "addon-a", "source": "asset_lib" }
    ]
  }
  ```
- **Expected result:** Godot bridge error. Project not found.

#### Scenario 8.15: Edge — git URL unreachable
- **Description:** Install from a git URL that doesn't exist or is unreachable.
- **Params:**
  ```json
  {
    "project_path": "/tmp/my_project",
    "addons": [
      { "name": "bad-addon", "source": "git", "url": "https://invalid-url-that-does-not-exist.com/repo" }
    ]
  }
  ```
- **Expected result:** Godot bridge error or timeout. Cannot reach git repository.

#### Scenario 8.16: Edge — duplicate addon names in array
- **Description:** Install the same addon name twice with different sources.
- **Params:**
  ```json
  {
    "project_path": "/tmp/my_project",
    "addons": [
      { "name": "addon-x", "source": "asset_lib" },
      { "name": "addon-x", "source": "git", "url": "https://github.com/user/repo.git" }
    ]
  }
  ```
- **Expected result:** Second install may fail with conflict or overwrite first. Implementation-dependent.

#### Scenario 8.17: Edge — addons is not an array
- **Description:** Pass a single object instead of an array for `addons`.
- **Params:**
  ```json
  {
    "project_path": "/tmp/my_project",
    "addons": { "name": "my-addon", "source": "asset_lib" }
  }
  ```
- **Expected result:** Zod validation error. Expected array, got object.

---

## Tool 9: `validate_project_structure`

**Description:** Validate a Godot project's folder structure and configuration for correctness
**Handler:** `callGodot(bridge, 'project_creation/validate_structure', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `project_path` | FilePath (string) | **Yes** | — | Path to the Godot project root |

### Test Scenarios

#### Scenario 9.1: Happy path — valid Godot project
- **Description:** Validate a properly structured Godot project.
- **Params:** `{ "project_path": "/tmp/valid_project" }`
- **Expected result:** Success. Returns validation report indicating project structure is correct (no errors).

#### Scenario 9.2: Happy path — minimal valid project (just project.godot)
- **Description:** Validate a project with only the bare minimum (project.godot file).
- **Params:** `{ "project_path": "/tmp/minimal_project" }`
- **Expected result:** Success. Validation passes (or returns warnings about missing recommended folders).

#### Scenario 9.3: Happy path — full project with all standard folders
- **Description:** Validate a project with scenes/, scripts/, assets/, etc.
- **Params:** `{ "project_path": "/tmp/full_project" }`
- **Expected result:** Success. Validation passes with no warnings.

#### Scenario 9.4: Edge — missing required param `project_path`
- **Description:** Call without `project_path`.
- **Params:** `{}`
- **Expected result:** Zod validation error. `project_path` is required.

#### Scenario 9.5: Edge — project_path does not exist
- **Description:** Validate a directory that does not exist.
- **Params:** `{ "project_path": "/tmp/nonexistent" }`
- **Expected result:** Godot bridge error. Directory not found.

#### Scenario 9.6: Edge — directory is not a Godot project (no project.godot)
- **Description:** Validate a directory that does not contain a project.godot file.
- **Params:** `{ "project_path": "/tmp/not_a_project" }`
- **Expected result:** Validation failure. Reports missing project.godot or "not a valid Godot project".

#### Scenario 9.7: Edge — project with corrupted project.godot
- **Description:** Validate a project whose project.godot file is malformed/corrupted.
- **Params:** `{ "project_path": "/tmp/corrupt_project" }`
- **Expected result:** Validation failure. Reports issues with project.godot parsing.

#### Scenario 9.8: Edge — project with missing required folders (if config expects them)
- **Description:** Validate a project that is missing folder structure expected by project settings.
- **Params:** `{ "project_path": "/tmp/missing_folders_project" }`
- **Expected result:** Validation warnings or errors about missing expected directories.

#### Scenario 9.9: Edge — project_path with trailing slash
- **Description:** Call with a trailing slash on the path.
- **Params:** `{ "project_path": "/tmp/my_project/" }`
- **Expected result:** Should succeed if the backend normalizes paths. Otherwise error.

#### Scenario 9.10: Edge — empty string project_path
- **Description:** Call with empty string for project_path.
- **Params:** `{ "project_path": "" }`
- **Expected result:** Godot bridge error or Zod validation if empty strings are rejected somehow.

#### Scenario 9.11: Edge — additional unknown properties in call
- **Description:** Send extra fields not in the schema.
- **Params:** `{ "project_path": "/tmp/my_project", "verbose": true }`
- **Expected result:** Extra field is silently stripped. Validation proceeds normally.

---

## Tool 10: `get_project_templates`

**Description:** List all available project templates that can be used with create_project
**Handler:** `callGodot(bridge, 'project_creation/get_templates')`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| *(none)* | — | — | — | No parameters |

### Test Scenarios

#### Scenario 10.1: Happy path — call with no params
- **Description:** List available project templates.
- **Params:** `{}`
- **Expected result:** Success. Returns a list of available template names (typically includes '2D', '3D', etc.). Format is likely `["empty", "2d", "3d", "ui", "custom"]` or similar.

#### Scenario 10.2: Happy path — call with extra ignored params
- **Description:** Call with extra properties (should be silently ignored since schema is empty `{}`).
- **Params:** `{ "filter": "2d" }`
- **Expected result:** Success (if Zod strips unknown keys). Returns full template list regardless.

#### Scenario 10.3: Edge — Godot editor not connected
- **Description:** Call when the Godot editor bridge is not connected.
- **Params:** `{}`
- **Expected result:** Godot bridge error. "Godot request failed: ..." or connection error.

#### Scenario 10.4: Edge — Godot version without certain templates
- **Description:** Different Godot versions may expose different templates. Verify the returned list matches expected templates for the running Godot version.
- **Params:** `{}`
- **Expected result:** Success. Returns the templates available in the connected Godot instance.

---

## Integration / Cross-Tool Scenarios

These scenarios test multiple project_creation tools in sequence to verify workflow.

### Scenario I.1: Create → Scaffold → Validate pipeline
- **Steps:**
  1. `create_project` with path, name, template="3d"
  2. `scaffold_project_structure` with structure="full"
  3. `validate_project_structure`
  4. `get_project_templates` to verify template availability
- **Expected result:** All steps succeed. Validation passes after creation and scaffolding.

### Scenario I.2: Create → Init Git → README → LICENSE
- **Steps:**
  1. `create_project` with minimal params
  2. `initialize_git_repository` with include_gitignore=true
  3. `create_project_readme` with template="game"
  4. `create_project_license` with license="MIT"
- **Expected result:** All steps succeed. Project has git repo, .gitignore, README.md, and LICENSE.

### Scenario I.3: Create with assets → Dependencies → Validate
- **Steps:**
  1. `create_project_with_assets` with assets array
  2. `setup_project_dependencies` with addons
  3. `validate_project_structure`
- **Expected result:** All steps succeed. Project has assets, addons, and passes validation.

### Scenario I.4: Create from template → Scaffold → Validate
- **Steps:**
  1. `create_project_from_template` with a known-good template
  2. `scaffold_project_structure` (optional, may duplicate template structure)
  3. `validate_project_structure`
- **Expected result:** Steps succeed or step 2 reports folders already exist. Validation passes.

### Scenario I.5: Error propagation — missing bridge
- **Steps:** Call ANY tool while the Godot editor is disconnected or not running.
- **Expected result:** Every tool returns `{"content": [{"type": "text", "text": "Godot request failed: ..."}], "isError": true}`.

### Scenario I.6: Error propagation — invalid Zod types
- **Steps:** Call each tool with deliberately wrong types (numbers for strings, strings for booleans, missing required fields).
- **Expected result:** Every call is rejected at the Zod validation layer before reaching Godot. Error messages indicate the expected vs received type.

---

## Parameter Coverage Matrix

| Tool | path / project_path | name | template | godot_version | renderer | template_path | structure | assets | include_gitignore | content | license | custom_text | addons |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `create_project` | ✅ R | ✅ R | enum(5) O | string O | enum(3) O | — | — | — | — | — | — | — | — |
| `create_project_from_template` | ✅ R | ✅ O | — | — | — | ✅ R | — | — | — | — | — | — | — |
| `scaffold_project_structure` | ✅ R | — | — | — | — | — | enum(3) O | — | — | — | — | — | — |
| `create_project_with_assets` | ✅ R | ✅ R | — | — | — | — | — | ✅ R (array) | — | — | — | — | — |
| `initialize_git_repository` | ✅ R | — | — | — | — | — | — | — | bool O | — | — | — | — |
| `create_project_readme` | ✅ R | — | enum(3) O | — | — | — | — | — | — | string O | — | — | — |
| `create_project_license` | ✅ R | — | — | — | — | — | — | — | — | — | enum(5) R | string O | — |
| `setup_project_dependencies` | ✅ R | — | — | — | — | — | — | — | — | — | — | — | ✅ R (array) |
| `validate_project_structure` | ✅ R | — | — | — | — | — | — | — | — | — | — | — | — |
| `get_project_templates` | — | — | — | — | — | — | — | — | — | — | — | — | — |

**Legend:** ✅ = present, R = Required, O = Optional, `enum(N)` = enum with N values

---

## Summary Statistics

- **Total tools:** 10
- **Total test scenarios:** 98
- **Required parameters across all tools:** 17
- **Optional parameters across all tools:** 13
- **Enum parameters with exhaustive testing:** 7 (template x2, renderer, structure, license, source, readme_template)
- **Array parameters:** 2 (assets, addons)
- **Parameter-less tools:** 1 (`get_project_templates`)
- **Integration scenarios:** 6
