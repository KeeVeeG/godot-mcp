# Project Creation Tools — Test Plan

**Source file:** `server/src/tools/project_creation.ts`
**Shared types:** `server/src/tools/shared-types.ts` (imports `z`, `Name`, `FilePath`)
**Generated:** 2026-07-08

---

## Type Definitions (from shared-types.ts)

| Symbol     | Zod schema                     | Description                              |
|------------|--------------------------------|------------------------------------------|
| `FilePath` | `z.string()`                   | File path (e.g. `res://path/to/file`)    |
| `Name`     | `z.string()`                   | Name identifier                          |

Both are plain `string` schemas; no additional validation constraints are applied at the Zod layer.

---

## Tool: `create_project`

**Description:** Create a complete Godot project from scratch with proper structure and configuration.
**Handler:** `project_creation/create_project`

### Parameters

| Param          | Type                                                 | Required | Choices                                         |
|----------------|------------------------------------------------------|----------|-------------------------------------------------|
| `path`         | FilePath (`z.string()`)                              | ✅ Yes   | —                                               |
| `name`         | Name (`z.string()`)                                  | ✅ Yes   | —                                               |
| `template`     | `z.enum(['empty', '2d', '3d', 'ui', 'custom'])`      | ❌ No     | `empty`, `2d`, `3d`, `ui`, `custom`              |
| `godot_version`| `z.string()`                                         | ❌ No     | —                                               |
| `renderer`     | `z.enum(['forward_plus', 'mobile', 'gl_compatibility'])` | ❌ No  | `forward_plus`, `mobile`, `gl_compatibility`      |

### Test Scenarios

#### Happy Path

1. **Minimal required params — default template**
   - **Params:** `{ "path": "C:/tmp/godot_test_project", "name": "TestGame" }`
   - **Expected:** Project created at `C:/tmp/godot_test_project` with name `TestGame`. Default template applied (likely `empty`). Default renderer used.
   - **Notes:** Verify `project.godot` exists, directory structure present.

2. **Path with res:// prefix**
   - **Params:** `{ "path": "res://test_projects/basic", "name": "BasicGame" }`
   - **Expected:** Project created relative to Godot project root.
   - **Notes:** `res://` paths are resolved relative to the open Godot project.

3. **Path with spaces in name**
   - **Params:** `{ "path": "C:/tmp/my godot projects/space game", "name": "Space Game" }`
   - **Expected:** Project created; spaces handled correctly in both path and name.

#### Template Enum — Each Value

4. **template = `empty`**
   - **Params:** `{ "path": "C:/tmp/godot_empty", "name": "EmptyGame", "template": "empty" }`
   - **Expected:** Bare-minimum project; no pre-configured scene or nodes.

5. **template = `2d`**
   - **Params:** `{ "path": "C:/tmp/godot_2d", "name": "2DGame", "template": "2d" }`
   - **Expected:** Project scaffolded for 2D development (Node2D root scene likely).

6. **template = `3d`**
   - **Params:** `{ "path": "C:/tmp/godot_3d", "name": "3DGame", "template": "3d" }`
   - **Expected:** Project scaffolded for 3D development (Node3D root scene likely).

7. **template = `ui`**
   - **Params:** `{ "path": "C:/tmp/godot_ui", "name": "UIGame", "template": "ui" }`
   - **Expected:** Project scaffolded with UI-focused structure (Control root scene likely).

8. **template = `custom`**
   - **Params:** `{ "path": "C:/tmp/godot_custom", "name": "CustomGame", "template": "custom" }`
   - **Expected:** Custom template applied (behavior depends on Godot-side implementation).

#### Renderer Enum — Each Value

9. **renderer = `forward_plus`**
   - **Params:** `{ "path": "C:/tmp/godot_fplus", "name": "FPGame", "renderer": "forward_plus" }`
   - **Expected:** Project created with Forward+ rendering backend configured in `project.godot`.

10. **renderer = `mobile`**
    - **Params:** `{ "path": "C:/tmp/godot_mob", "name": "MobileGame", "renderer": "mobile" }`
    - **Expected:** Project created with Mobile rendering backend.

11. **renderer = `gl_compatibility`**
    - **Params:** `{ "path": "C:/tmp/godot_gl", "name": "GLGame", "renderer": "gl_compatibility" }`
    - **Expected:** Project created with GL Compatibility rendering backend.

#### godot_version Parameter

12. **Explicit godot_version**
    - **Params:** `{ "path": "C:/tmp/godot_v4", "name": "V4Game", "godot_version": "4.3" }`
    - **Expected:** Project created with specified version string. `project.godot` reflects version.
    - **Notes:** Test with `"4.2"`, `"4.4"` variations.

13. **Malformed godot_version**
    - **Params:** `{ "path": "C:/tmp/godot_badv", "name": "BadVGame", "godot_version": "not.a.version" }`
    - **Expected:** Godot-side validation may reject or default. Response should indicate outcome clearly.
    - **Notes:** This is an edge case — behavior is Godot-side dependent.

#### Combined Parameters

14. **All parameters together**
    - **Params:** `{ "path": "C:/tmp/godot_full", "name": "FullGame", "template": "3d", "godot_version": "4.3", "renderer": "forward_plus" }`
    - **Expected:** All specified parameters honored. 3D template + Forward+ renderer + version 4.3.

#### Edge Cases

15. **Missing required param: `path`**
    - **Params:** `{ "name": "NoPath" }`
    - **Expected:** Zod validation error. Response includes message about missing required field `path`.

16. **Missing required param: `name`**
    - **Params:** `{ "path": "C:/tmp/godot_noname" }`
    - **Expected:** Zod validation error. Response includes message about missing required field `name`.

17. **Invalid enum value for `template`**
    - **Params:** `{ "path": "C:/tmp/godot_bad", "name": "BadGame", "template": "vr" }`
    - **Expected:** Zod validation error. `"vr"` is not in `['empty', '2d', '3d', 'ui', 'custom']`.

18. **Invalid enum value for `renderer`**
    - **Params:** `{ "path": "C:/tmp/godot_bad2", "name": "BadGame2", "renderer": "vulkan" }`
    - **Expected:** Zod validation error. `"vulkan"` is not in `['forward_plus', 'mobile', 'gl_compatibility']`.

19. **Empty string for `path`**
    - **Params:** `{ "path": "", "name": "EmptyPath" }`
    - **Expected:** May pass Zod (since FilePath is just `z.string()`) but Godot-side should error on empty path.

20. **Empty string for `name`**
    - **Params:** `{ "path": "C:/tmp/godot_empty_name", "name": "" }`
    - **Expected:** May pass Zod but Godot-side should reject empty project name.

21. **Path already exists (non-empty directory)**
    - **Params:** `{ "path": "C:/tmp/godot_duplicate", "name": "DupGame" }` (where directory already contains a project)
    - **Expected:** Godot should return error about existing project or overwrite warning.

22. **Path on non-existent drive (Windows)**
    - **Params:** `{ "path": "Z:/nonexistent/godot_proj", "name": "BadDrive" }`
    - **Expected:** Error from Godot about inaccessible path.

23. **Extra unrecognized parameter**
    - **Params:** `{ "path": "C:/tmp/godot_extra", "name": "ExtraGame", "foobar": 42 }`
    - **Expected:** Should succeed (unknown params are forwarded as-is via `callGodot`), possibly ignored by Godot.

---

## Tool: `create_project_from_template`

**Description:** Create a new Godot project from an existing template project.
**Handler:** `project_creation/create_from_template`

### Parameters

| Param           | Type                       | Required | Choices |
|-----------------|----------------------------|----------|---------|
| `path`          | FilePath (`z.string()`)    | ✅ Yes   | —       |
| `template_path` | FilePath (`z.string()`)    | ✅ Yes   | —       |
| `name`          | Name (`z.string()`)        | ❌ No     | —       |

### Test Scenarios

#### Happy Path

1. **Minimal required params (no name override)**
   - **Params:** `{ "path": "C:/tmp/godot_from_tmpl", "template_path": "C:/templates/my_template" }`
   - **Expected:** Project created from template. Name derived from template or directory.

2. **All params with name override**
   - **Params:** `{ "path": "C:/tmp/godot_from_tmpl2", "template_path": "C:/templates/base_template", "name": "MyDerivedGame" }`
   - **Expected:** Project created with overridden name `MyDerivedGame`.

3. **res:// template_path**
   - **Params:** `{ "path": "res://derived_project", "template_path": "res://templates/platformer" }`
   - **Expected:** Both paths resolved relative to Godot project root.

#### Edge Cases

4. **Missing required param: `path`**
   - **Params:** `{ "template_path": "C:/templates/t" }`
   - **Expected:** Zod validation error — missing `path`.

5. **Missing required param: `template_path`**
   - **Params:** `{ "path": "C:/tmp/godot_notmpl" }`
   - **Expected:** Zod validation error — missing `template_path`.

6. **Missing both required params**
   - **Params:** `{}`
   - **Expected:** Zod validation error — missing both `path` and `template_path`.

7. **template_path does not exist**
   - **Params:** `{ "path": "C:/tmp/godot_badtmpl", "template_path": "C:/nonexistent/template" }`
   - **Expected:** Godot-side error about missing template directory.

8. **template_path is not a valid Godot project template**
   - **Params:** `{ "path": "C:/tmp/godot_bad2", "template_path": "C:/Windows/System32" }`
   - **Expected:** Godot-side error about invalid template.

9. **name is empty string**
   - **Params:** `{ "path": "C:/tmp/godot_empty", "template_path": "C:/templates/t", "name": "" }`
   - **Expected:** May fall back to template-derived name, or error from Godot.

---

## Tool: `scaffold_project_structure`

**Description:** Create a standard folder structure for a Godot project.
**Handler:** `project_creation/scaffold_structure`

### Parameters

| Param          | Type                                                   | Required | Choices                          |
|----------------|--------------------------------------------------------|----------|----------------------------------|
| `project_path` | FilePath (`z.string()`)                                | ✅ Yes   | —                                |
| `structure`    | `z.enum(['standard', 'minimal', 'full'])`               | ❌ No     | `standard`, `minimal`, `full`     |

### Test Scenarios

#### Happy Path

1. **Minimal — only project_path (default structure)**
   - **Params:** `{ "project_path": "C:/tmp/godot_scaffold" }`
   - **Expected:** Standard folder structure created (defaults to likely `standard`). Verify expected directories exist.

2. **structure = `standard`**
   - **Params:** `{ "project_path": "C:/tmp/godot_scaffold_std", "structure": "standard" }`
   - **Expected:** Common Godot structure: `scenes/`, `scripts/`, `assets/`, etc.

3. **structure = `minimal`**
   - **Params:** `{ "project_path": "C:/tmp/godot_scaffold_min", "structure": "minimal" }`
   - **Expected:** Bare-minimum folder set — fewer directories than `standard`.

4. **structure = `full`**
   - **Params:** `{ "project_path": "C:/tmp/godot_scaffold_full", "structure": "full" }`
   - **Expected:** Comprehensive folder structure: `scenes/`, `scripts/`, `assets/`, `materials/`, `shaders/`, `audio/`, `fonts/`, `addons/`, etc.

5. **res:// project_path**
   - **Params:** `{ "project_path": "res://my_existing_project" }`
   - **Expected:** Folders created within the Godot project root.

#### Edge Cases

6. **Missing required param: `project_path`**
   - **Params:** `{}`
   - **Expected:** Zod validation error — missing `project_path`.

7. **Invalid enum for `structure`**
   - **Params:** `{ "project_path": "C:/tmp/godot_bad", "structure": "mega" }`
   - **Expected:** Zod validation error — `"mega"` not in `['standard', 'minimal', 'full']`.

8. **project_path does not exist**
   - **Params:** `{ "project_path": "C:/nonexistent/project" }`
   - **Expected:** Godot-side error about missing directory.

9. **project_path is not a Godot project**
   - **Params:** `{ "project_path": "C:/Windows" }`
   - **Expected:** Godot-side error about invalid project directory (no `project.godot`).

10. **Scaffolding a project that already has the structure**
    - **Params:** `{ "project_path": "C:/tmp/godot_scaffold_std", "structure": "standard" }` (run twice)
    - **Expected:** Idempotent — existing folders left as-is, missing ones created. No error.

---

## Tool: `create_project_with_assets`

**Description:** Create a new Godot project and import specified assets into it.
**Handler:** `project_creation/create_with_assets`

### Parameters

| Param    | Type                                                                    | Required | Choices |
|----------|-------------------------------------------------------------------------|----------|---------|
| `path`   | FilePath (`z.string()`)                                                 | ✅ Yes   | —       |
| `name`   | Name (`z.string()`)                                                     | ✅ Yes   | —       |
| `assets` | `z.array(z.object({ type: z.string(), source: z.string(), destination: z.string() }))` | ✅ Yes   | `type`: free string (described as `'texture', 'audio', 'scene', 'script'`) |

### Test Scenarios

#### Happy Path

1. **Single asset — texture**
   - **Params:** `{ "path": "C:/tmp/godot_with_assets", "name": "AssetGame", "assets": [{"type": "texture", "source": "C:/images/player.png", "destination": "res://assets/textures/player.png"}] }`
   - **Expected:** Project created + texture imported to specified destination.

2. **Multiple assets of different types**
   - **Params:**
     ```json
     {
       "path": "C:/tmp/godot_multi_assets",
       "name": "MultiAssetGame",
       "assets": [
         {"type": "texture", "source": "C:/images/bg.png", "destination": "res://assets/textures/bg.png"},
         {"type": "audio", "source": "C:/sounds/music.ogg", "destination": "res://assets/audio/music.ogg"},
         {"type": "scene", "source": "C:/scenes/enemy.tscn", "destination": "res://scenes/enemy.tscn"},
         {"type": "script", "source": "C:/scripts/utils.gd", "destination": "res://scripts/utils.gd"}
       ]
     }
     ```
   - **Expected:** Project created + all 4 assets imported.

3. **Empty assets array**
   - **Params:** `{ "path": "C:/tmp/godot_no_assets", "name": "NoAssetGame", "assets": [] }`
   - **Expected:** Project created with no extra assets. Behaves like `create_project` with default template.

4. **Asset with arbitrary type string**
   - **Params:** `{ "path": "C:/tmp/godot_custom_asset", "name": "CustomAssetGame", "assets": [{"type": "custom_resource", "source": "C:/data/data.json", "destination": "res://data/data.json"}] }`
   - **Expected:** Godot-side may accept or reject based on supported asset types. Observe behavior.

#### Edge Cases

5. **Missing required param: `path`**
   - **Params:** `{ "name": "NoPath", "assets": [] }`
   - **Expected:** Zod validation error — missing `path`.

6. **Missing required param: `name`**
   - **Params:** `{ "path": "C:/tmp/godot_no_name", "assets": [] }`
   - **Expected:** Zod validation error — missing `name`.

7. **Missing required param: `assets`**
   - **Params:** `{ "path": "C:/tmp/godot_no_assets", "name": "NoAssets" }`
   - **Expected:** Zod validation error — missing `assets`.

8. **asset object missing required field: `type`**
   - **Params:** `{ "path": "C:/tmp/godot_bad", "name": "BadAsset", "assets": [{"source": "C:/a.png", "destination": "res://a.png"}] }`
   - **Expected:** Zod validation error — missing `type` in asset object.

9. **asset object missing required field: `source`**
   - **Params:** `{ "path": "C:/tmp/godot_bad2", "name": "BadAsset2", "assets": [{"type": "texture", "destination": "res://a.png"}] }`
   - **Expected:** Zod validation error — missing `source` in asset object.

10. **asset object missing required field: `destination`**
    - **Params:** `{ "path": "C:/tmp/godot_bad3", "name": "BadAsset3", "assets": [{"type": "texture", "source": "C:/a.png"}] }`
    - **Expected:** Zod validation error — missing `destination` in asset object.

11. **Source file does not exist**
    - **Params:** `{ "path": "C:/tmp/godot_missing_src", "name": "BadSrc", "assets": [{"type": "texture", "source": "C:/nonexistent/img.png", "destination": "res://img.png"}] }`
    - **Expected:** Godot-side error about missing source file. Project may still be created; asset import fails.

12. **Invalid asset type**
    - **Params:** `{ "path": "C:/tmp/godot_bad_type", "name": "BadType", "assets": [{"type": "invalid_type_xyz", "source": "C:/a.png", "destination": "res://a.png"}] }`
    - **Expected:** Godot-side may error or warn. Since `type` is free-form `z.string()`, Zod won't reject it.

---

## Tool: `initialize_git_repository`

**Description:** Initialize a Git repository in the project directory with a proper `.gitignore`.
**Handler:** `project_creation/init_git`

### Parameters

| Param              | Type                       | Required | Choices |
|--------------------|----------------------------|----------|---------|
| `project_path`     | FilePath (`z.string()`)    | ✅ Yes   | —       |
| `include_gitignore`| `z.boolean()`              | ❌ No     | —       |

### Test Scenarios

#### Happy Path

1. **Minimal — project_path only**
   - **Params:** `{ "project_path": "C:/tmp/godot_repo" }`
   - **Expected:** `git init` executed. `.git` directory created. `.gitignore` behavior: defaults to omitting or creating one (Godot-side dependent).

2. **include_gitignore = true**
   - **Params:** `{ "project_path": "C:/tmp/godot_repo2", "include_gitignore": true }`
   - **Expected:** Git initialized + `.gitignore` created with Godot-specific entries (`.import/`, `*.translation`, etc.).

3. **include_gitignore = false**
   - **Params:** `{ "project_path": "C:/tmp/godot_repo3", "include_gitignore": false }`
   - **Expected:** Git initialized but NO `.gitignore` created.

4. **Already a git repo**
   - **Params:** `{ "project_path": "C:/tmp/godot_repo", "include_gitignore": true }` (run twice)
   - **Expected:** Second call should succeed (idempotent) or return a message indicating repo already exists.

#### Edge Cases

5. **Missing required param: `project_path`**
   - **Params:** `{}`
   - **Expected:** Zod validation error — missing `project_path`.

6. **non-boolean for include_gitignore**
   - **Params:** `{ "project_path": "C:/tmp/godot_bad", "include_gitignore": "yes" }`
   - **Expected:** Zod validation error — expected boolean, got string.

7. **include_gitignore = 0 (falsy number)**
   - **Params:** `{ "project_path": "C:/tmp/godot_num", "include_gitignore": 0 }`
   - **Expected:** Zod validation error — expected boolean, got number.

8. **project_path does not exist**
   - **Params:** `{ "project_path": "C:/nonexistent/proj" }`
   - **Expected:** Godot-side error about missing directory.

9. **project_path not a Godot project**
   - **Params:** `{ "project_path": "C:/Users" }`
   - **Expected:** Git init may still work (git doesn't require a Godot project), but behavior depends on Godot-side validation.

10. **Extra unrecognized parameter**
    - **Params:** `{ "project_path": "C:/tmp/godot_extra", "branch": "main" }`
    - **Expected:** Should succeed; `branch` param ignored or forwarded.

---

## Tool: `create_project_readme`

**Description:** Generate a README.md file for the project.
**Handler:** `project_creation/create_readme`

### Parameters

| Param          | Type                                             | Required | Choices                      |
|----------------|--------------------------------------------------|----------|------------------------------|
| `project_path` | FilePath (`z.string()`)                          | ✅ Yes   | —                            |
| `content`      | `z.string()`                                     | ❌ No     | —                            |
| `template`     | `z.enum(['basic', 'detailed', 'game'])`           | ❌ No     | `basic`, `detailed`, `game`   |

### Test Scenarios

#### Happy Path

1. **Minimal — project_path only (default template)**
   - **Params:** `{ "project_path": "C:/tmp/godot_readme" }`
   - **Expected:** `README.md` created using default template (likely `basic`).

2. **Custom content (overrides template)**
   - **Params:** `{ "project_path": "C:/tmp/godot_readme2", "content": "# My Game\n\nThis is a custom README." }`
   - **Expected:** `README.md` created with exact custom content provided. Template ignored.

3. **template = `basic`**
   - **Params:** `{ "project_path": "C:/tmp/godot_readme3", "template": "basic" }`
   - **Expected:** Basic `README.md` — project name, setup instructions, minimal sections.

4. **template = `detailed`**
   - **Params:** `{ "project_path": "C:/tmp/godot_readme4", "template": "detailed" }`
   - **Expected:** Elaborate `README.md` with multiple sections: features, installation, contributing, etc.

5. **template = `game`**
   - **Params:** `{ "project_path": "C:/tmp/godot_readme5", "template": "game" }`
   - **Expected:** Game-focused `README.md` — story, controls, gameplay mechanics, credits sections.

6. **Both content and template (content wins)**
   - **Params:** `{ "project_path": "C:/tmp/godot_readme6", "content": "Custom wins.", "template": "detailed" }`
   - **Expected:** `content` takes precedence. `README.md` = `"Custom wins."`.

#### Edge Cases

7. **Missing required param: `project_path`**
   - **Params:** `{}`
   - **Expected:** Zod validation error — missing `project_path`.

8. **Invalid template enum**
   - **Params:** `{ "project_path": "C:/tmp/godot_bad", "template": "fancy" }`
   - **Expected:** Zod validation error — `"fancy"` not in `['basic', 'detailed', 'game']`.

9. **README already exists**
   - **Params:** `{ "project_path": "C:/tmp/godot_readme", "template": "basic" }` (run twice)
   - **Expected:** Second call overwrites existing `README.md` or errors. Behavior is Godot-side dependent.

10. **Empty content string**
    - **Params:** `{ "project_path": "C:/tmp/godot_readme7", "content": "" }`
    - **Expected:** Empty `README.md` created. May or may not be allowed depending on Godot implementation.

11. **Very long content**
    - **Params:** `{ "project_path": "C:/tmp/godot_readme8", "content": "<10,000 characters of text>" }`
    - **Expected:** Should succeed if within Godot's string handling limits.

12. **project_path not a Godot project**
    - **Params:** `{ "project_path": "C:/tmp/non_godot_dir", "template": "basic" }`
    - **Expected:** Godot-side may still create `README.md` (filesystem operation) or error if `project.godot` validation is in place.

---

## Tool: `create_project_license`

**Description:** Create a LICENSE file for the project.
**Handler:** `project_creation/create_license`

### Parameters

| Param          | Type                                                              | Required | Choices                                          |
|----------------|-------------------------------------------------------------------|----------|--------------------------------------------------|
| `project_path` | FilePath (`z.string()`)                                           | ✅ Yes   | —                                                |
| `license`      | `z.enum(['MIT', 'Apache-2.0', 'GPL-3.0', 'BSD-3-Clause', 'custom'])` | ✅ Yes   | `MIT`, `Apache-2.0`, `GPL-3.0`, `BSD-3-Clause`, `custom` |
| `custom_text`  | `z.string()`                                                      | ❌ No     | —                                                |

### Test Scenarios

#### Happy Path

1. **license = `MIT`**
   - **Params:** `{ "project_path": "C:/tmp/godot_license", "license": "MIT" }`
   - **Expected:** `LICENSE` file created with MIT license text.

2. **license = `Apache-2.0`**
   - **Params:** `{ "project_path": "C:/tmp/godot_license2", "license": "Apache-2.0" }`
   - **Expected:** `LICENSE` file created with Apache 2.0 license text.

3. **license = `GPL-3.0`**
   - **Params:** `{ "project_path": "C:/tmp/godot_license3", "license": "GPL-3.0" }`
   - **Expected:** `LICENSE` file created with GPL 3.0 license text.

4. **license = `BSD-3-Clause`**
   - **Params:** `{ "project_path": "C:/tmp/godot_license4", "license": "BSD-3-Clause" }`
   - **Expected:** `LICENSE` file created with BSD 3-Clause license text.

5. **license = `custom` with custom_text**
   - **Params:** `{ "project_path": "C:/tmp/godot_license5", "license": "custom", "custom_text": "Copyright (c) 2026 My Company. All rights reserved." }`
   - **Expected:** `LICENSE` file created with custom text.

#### Edge Cases

6. **Missing required param: `project_path`**
   - **Params:** `{ "license": "MIT" }`
   - **Expected:** Zod validation error — missing `project_path`.

7. **Missing required param: `license`**
   - **Params:** `{ "project_path": "C:/tmp/godot_license" }`
   - **Expected:** Zod validation error — missing `license`.

8. **Invalid license enum**
   - **Params:** `{ "project_path": "C:/tmp/godot_bad", "license": "AGPL-3.0" }`
   - **Expected:** Zod validation error — `"AGPL-3.0"` not in enum.

9. **license = `custom` without custom_text**
   - **Params:** `{ "project_path": "C:/tmp/godot_license6", "license": "custom" }`
   - **Expected:** May create empty LICENSE or error. The description says `custom_text` is "required when license is 'custom'" — Godot-side may enforce this.

10. **license = `MIT` with custom_text also provided**
    - **Params:** `{ "project_path": "C:/tmp/godot_license7", "license": "MIT", "custom_text": "My custom text" }`
    - **Expected:** `LICENSE` created with MIT template; `custom_text` likely ignored (since license is not `custom`).

11. **custom_text empty string**
    - **Params:** `{ "project_path": "C:/tmp/godot_license8", "license": "custom", "custom_text": "" }`
    - **Expected:** Empty `LICENSE` file or error from Godot.

12. **Long custom_text**
    - **Params:** `{ "project_path": "C:/tmp/godot_license9", "license": "custom", "custom_text": "<full multi-paragraph license text>" }`
    - **Expected:** Multi-paragraph text preserved correctly in `LICENSE` file.

---

## Tool: `setup_project_dependencies`

**Description:** Install and configure project addons/dependencies.
**Handler:** `project_creation/setup_dependencies`

### Parameters

| Param          | Type                                                                                                                                  | Required | Choices                                          |
|----------------|---------------------------------------------------------------------------------------------------------------------------------------|----------|--------------------------------------------------|
| `project_path` | FilePath (`z.string()`)                                                                                                               | ✅ Yes   | —                                                |
| `addons`       | `z.array(z.object({ name: z.string(), source: z.enum(['asset_lib', 'git', 'local']), url: z.string().optional() }))`                  | ✅ Yes   | `source`: `asset_lib`, `git`, `local`             |

### Test Scenarios

#### Happy Path

1. **Single addon from asset_lib**
   - **Params:**
     ```json
     {
       "project_path": "C:/tmp/godot_deps",
       "addons": [{"name": "godot-jolt", "source": "asset_lib"}]
     }
     ```
   - **Expected:** Addon installed from Asset Library. No `url` needed.

2. **Single addon from git with URL**
   - **Params:**
     ```json
     {
       "project_path": "C:/tmp/godot_deps2",
       "addons": [{"name": "my-addon", "source": "git", "url": "https://github.com/user/my-addon.git"}]
     }
     ```
   - **Expected:** Addon cloned from git URL into project.

3. **Single addon from local path**
   - **Params:**
     ```json
     {
       "project_path": "C:/tmp/godot_deps3",
       "addons": [{"name": "local-addon", "source": "local", "url": "C:/dev/my_local_addon"}]
     }
     ```
   - **Expected:** Addon installed from local directory.

4. **Multiple addons — mixed sources**
   - **Params:**
     ```json
     {
       "project_path": "C:/tmp/godot_deps4",
       "addons": [
         {"name": "addon-a", "source": "asset_lib"},
         {"name": "addon-b", "source": "git", "url": "https://github.com/x/b.git"},
         {"name": "addon-c", "source": "local", "url": "C:/dev/c"}
       ]
     }
     ```
   - **Expected:** All three addons installed from respective sources.

5. **Empty addons array**
   - **Params:** `{ "project_path": "C:/tmp/godot_deps5", "addons": [] }`
   - **Expected:** No-op success. Nothing installed.

#### Source Enum — Each Value

6. **source = `asset_lib` (without url)**
   - **Params:** `{ "project_path": "C:/tmp/godot_deps6", "addons": [{"name": "dialogic", "source": "asset_lib"}] }`
   - **Expected:** Addon fetched from Asset Library by name.

7. **source = `git` (with url)**
   - **Params:** `{ "project_path": "C:/tmp/godot_deps7", "addons": [{"name": "gd-extension", "source": "git", "url": "https://gitlab.com/x/y.git"}] }`
   - **Expected:** Addon cloned from Git URL.

8. **source = `local` (with url as local path)**
   - **Params:** `{ "project_path": "C:/tmp/godot_deps8", "addons": [{"name": "my-local", "source": "local", "url": "C:/projects/shared_addon"}] }`
   - **Expected:** Addon copied from local directory.

#### Edge Cases

9. **Missing required param: `project_path`**
   - **Params:** `{ "addons": [] }`
   - **Expected:** Zod validation error — missing `project_path`.

10. **Missing required param: `addons`**
    - **Params:** `{ "project_path": "C:/tmp/godot_deps" }`
    - **Expected:** Zod validation error — missing `addons`.

11. **addon object missing `name`**
    - **Params:** `{ "project_path": "C:/tmp/godot_bad", "addons": [{"source": "asset_lib"}] }`
    - **Expected:** Zod validation error — missing `name` in addon object.

12. **addon object missing `source`**
    - **Params:** `{ "project_path": "C:/tmp/godot_bad2", "addons": [{"name": "x"}] }`
    - **Expected:** Zod validation error — missing `source` in addon object.

13. **Invalid source enum**
    - **Params:** `{ "project_path": "C:/tmp/godot_bad3", "addons": [{"name": "x", "source": "marketplace"}] }`
    - **Expected:** Zod validation error — `"marketplace"` not in `['asset_lib', 'git', 'local']`.

14. **git source without url**
    - **Params:** `{ "project_path": "C:/tmp/godot_bad4", "addons": [{"name": "x", "source": "git"}] }`
    - **Expected:** May pass Zod (url is optional) but Godot-side should error — git source needs a URL.

15. **local source without url**
    - **Params:** `{ "project_path": "C:/tmp/godot_bad5", "addons": [{"name": "x", "source": "local"}] }`
    - **Expected:** May pass Zod but Godot-side should error — local source needs a path.

16. **asset_lib with url (url should be unnecessary)**
    - **Params:** `{ "project_path": "C:/tmp/godot_extra", "addons": [{"name": "x", "source": "asset_lib", "url": "https://ignored.com"}] }`
    - **Expected:** Addon installed from Asset Library; `url` field ignored.

17. **Invalid git URL**
    - **Params:** `{ "project_path": "C:/tmp/godot_bad6", "addons": [{"name": "x", "source": "git", "url": "not-a-valid-url!!!"}] }`
    - **Expected:** Godot-side error — git clone fails.

18. **Non-existent local path**
    - **Params:** `{ "project_path": "C:/tmp/godot_bad7", "addons": [{"name": "x", "source": "local", "url": "C:/nonexistent/addon"}] }`
    - **Expected:** Godot-side error — local path not found.

---

## Tool: `validate_project_structure`

**Description:** Validate a Godot project's folder structure and configuration for correctness.
**Handler:** `project_creation/validate_structure`

### Parameters

| Param          | Type                       | Required | Choices |
|----------------|----------------------------|----------|---------|
| `project_path` | FilePath (`z.string()`)    | ✅ Yes   | —       |

### Test Scenarios

#### Happy Path

1. **Valid Godot project**
   - **Params:** `{ "project_path": "C:/tmp/godot_valid" }` (assume a valid project exists)
   - **Expected:** Validation passes. Returns success with possibly a report of found issues/warnings.

2. **Freshly created project**
   - **Params:** `{ "project_path": "C:/tmp/godot_fresh" }` (created via `create_project`)
   - **Expected:** Validation passes. Structure conforms to expected layout.

3. **Project with custom structure**
   - **Params:** `{ "project_path": "C:/tmp/godot_custom_struct" }` (project with non-standard but valid structure)
   - **Expected:** Validation should report any structural issues but not fail on custom layout.

#### Edge Cases

4. **Missing required param: `project_path`**
   - **Params:** `{}`
   - **Expected:** Zod validation error — missing `project_path`.

5. **project_path does not exist**
   - **Params:** `{ "project_path": "C:/nonexistent/project" }`
   - **Expected:** Godot-side error — directory not found.

6. **project_path is not a Godot project (no project.godot)**
   - **Params:** `{ "project_path": "C:/tmp/empty_directory" }`
   - **Expected:** Godot-side error or validation report indicating missing `project.godot`.

7. **Project with missing critical directories**
   - **Params:** `{ "project_path": "C:/tmp/godot_broken" }` (delete `project.godot` or key directories)
   - **Expected:** Validation report lists issues found. Not necessarily an error — depends on severity.

8. **Project with circular scene references**
   - **Params:** `{ "project_path": "C:/tmp/godot_circular" }` (scene A inherits B, B inherits A)
   - **Expected:** Validation should detect and report the circular dependency.

---

## Tool: `get_project_templates`

**Description:** List all available project templates that can be used with `create_project`.
**Handler:** `project_creation/get_templates`

### Parameters

| Param | Type | Required | Choices |
|-------|------|----------|---------|
| *(none)* | —   | —        | —       |

### Test Scenarios

#### Happy Path

1. **Basic call — no parameters**
   - **Params:** `{}`
   - **Expected:** Returns list of available templates as string or JSON array. Should include built-in templates (`empty`, `2d`, `3d`, `ui`).

2. **Verify returned templates match `create_project` enum values**
   - **Params:** `{}`
   - **Expected:** Returned template names should be a superset (or exact match) of `['empty', '2d', '3d', 'ui', 'custom']`. Custom/user templates may appear as additional entries.

#### Edge Cases

3. **Calling with extra params (should ignore)**
   - **Params:** `{ "foobar": 42 }`
   - **Expected:** Should still succeed and return template list. Unknown params forwarded but handler ignores them.

4. **No Godot project open**
   - **Params:** `{}`
   - **Expected:** May still return built-in templates even without an open project. Behavior depends on how templates are sourced.

---

## Cross-Tool Dependency Tests

These scenarios test interactions between multiple tools.

### Scenario: Full Project Bootstrap Workflow

1. `create_project` → create a new project
2. `scaffold_project_structure` → add standard folders
3. `initialize_git_repository` → init git with `.gitignore`
4. `create_project_readme` → generate README
5. `create_project_license` → add MIT license
6. `validate_project_structure` → verify everything is valid

- **Expected:** All steps succeed sequentially on the same project path.

### Scenario: Template Discovery → Creation

1. `get_project_templates` → list templates
2. `create_project` with one of the listed templates
3. Verify project matches template.

### Scenario: Error When Project Already Exists

1. `create_project` at path P → succeeds
2. `create_project` at same path P → should error or warn about existing project

---

## Notes

- **FilePath / Name types:** Both are `z.string()` with no additional Zod-level validation. Empty strings pass Zod but may fail at the Godot layer.
- **Handler forwarding:** All tools use `callGodot(bridge, 'project_creation/<handler>', args)`. The Zod schema validates input; the Godot plugin handles execution. Test plan scenarios cover both layers.
- **Optional parameters:** When omitted, Godot-side defaults apply. The exact defaults are implementation-defined in the Godot plugin.
- **Error format:** Errors from `callGodot` are expected to be JSON-RPC error responses or objects with `isError: true`.
- **Platform paths:** Tests use Windows-style paths (`C:/...`) as the test environment is Windows. For cross-platform testing, adjust to `/tmp/...` (Linux/macOS).

---

## Summary

| Tool # | Tool Name                      | Required Params | Optional Params | Enum Params |
|--------|--------------------------------|-----------------|-----------------|-------------|
| 1      | `create_project`               | 2               | 3               | 2           |
| 2      | `create_project_from_template` | 2               | 1               | 0           |
| 3      | `scaffold_project_structure`   | 1               | 1               | 1           |
| 4      | `create_project_with_assets`   | 3               | 0               | 0           |
| 5      | `initialize_git_repository`    | 1               | 1               | 0           |
| 6      | `create_project_readme`        | 1               | 2               | 1           |
| 7      | `create_project_license`       | 2               | 1               | 1           |
| 8      | `setup_project_dependencies`   | 2               | 0               | 1 (nested)  |
| 9      | `validate_project_structure`   | 1               | 0               | 0           |
| 10     | `get_project_templates`        | 0               | 0               | 0           |

**Total scenarios:** 87 test scenarios across 10 tools + 3 cross-tool workflow tests.
