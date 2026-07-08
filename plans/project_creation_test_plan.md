# Project Creation Tools Test Plan

**Source**: `server/src/tools/project_creation.ts`  
**Total tools**: 10  
**Test plan generated**: 2026-07-08

---

## Table of Contents

1. [Tool: create_project](#tool-create_project)
2. [Tool: create_project_from_template](#tool-create_project_from_template)
3. [Tool: scaffold_project_structure](#tool-scaffold_project_structure)
4. [Tool: create_project_with_assets](#tool-create_project_with_assets)
5. [Tool: initialize_git_repository](#tool-initialize_git_repository)
6. [Tool: create_project_readme](#tool-create_project_readme)
7. [Tool: create_project_license](#tool-create_project_license)
8. [Tool: setup_project_dependencies](#tool-setup_project_dependencies)
9. [Tool: validate_project_structure](#tool-validate_project_structure)
10. [Tool: get_project_templates](#tool-get_project_templates)

---

## Sequence Notes

Most project creation tools require an existing project. Recommended testing sequence:

1. **`get_project_templates`** — standalone, does not require a project → run first
2. **`create_project`** — create a test project → run second (all subsequent tools depend on it)
3. **`scaffold_project_structure`** → after project creation
4. **`initialize_git_repository`** → after project creation
5. **`create_project_readme`** → after project creation
6. **`create_project_license`** → after project creation
7. **`setup_project_dependencies`** → after project creation (may require internet)
8. **`validate_project_structure`** → after project creation and applying other tools
9. **`create_project_from_template`** → requires an existing template project on disk
10. **`create_project_with_assets`** → requires existing asset files

**Important**: Tools 2–9 share a common `project_path` pointing to the same test project. After all tests are complete, the test project should be deleted.

---

## Tool: create_project

**Tool name**: `create_project`  
**Description**: Create a complete Godot project from scratch with proper structure and configuration  
**Backend method**: `project_creation/create_project`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `string` (FilePath) | **Yes** | — | Directory path where the project will be created |
| `name` | `string` (Name) | **Yes** | — | Project name |
| `template` | `enum('empty','2d','3d','ui','custom')` | No | — | Project template type |
| `godot_version` | `string` | No | — | Target Godot version (e.g. '4.3') |
| `renderer` | `enum('forward_plus','mobile','gl_compatibility')` | No | — | Rendering engine |

### Test Scenarios

#### Scenario 1: Happy path — create project with minimum params

**Description**: Create a project with the minimum required parameters.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_test_project",
  "name": "TestProject"
}
```
**Expected result**: Successful response. A directory `C:/tmp/godot_mcp_test_project` is created on disk with a `project.godot` file inside. In `project.godot`, the project name is set to `TestProject`.  
**Notes**: This project is used as the basis for testing tools 3–9.  
**Pay attention**: Verify that `project.godot` exists and is readable. Ensure that `application/config/name` = `"TestProject"`.

#### Scenario 2: Happy path — create 3D project with renderer

**Description**: Create a project with the `3d` template and the `forward_plus` renderer.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_test_3d",
  "name": "Test3DProject",
  "template": "3d",
  "renderer": "forward_plus"
}
```
**Expected result**: Project created. In `project.godot`, the renderer setting `rendering/renderer/rendering_method` = `"forward_plus"` is present. If the `3d` template creates additional files (e.g., a basic scene), they are also present.  
**Pay attention**: Verify that `project.godot` exists. Check the renderer setting. If the template creates a scene — verify its presence.

#### Scenario 3: Happy path — create 2D project with specific Godot version

**Description**: Create a 2D project specifying the target Godot version.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_test_2d",
  "name": "Test2D",
  "template": "2d",
  "godot_version": "4.3"
}
```
**Expected result**: Project created. In `project.godot`, the Godot version in the configuration section matches `4.3`.  
**Pay attention**: Verify that the version field in the configuration is set.

#### Scenario 4: Happy path — create UI project

**Description**: Create a project with the `ui` template.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_test_ui",
  "name": "TestUI",
  "template": "ui"
}
```
**Expected result**: Project created successfully. The `ui` template may create a basic Control scene.  
**Pay attention**: Verify the presence of a basic scene or other files specific to the UI template.

#### Scenario 5: Happy path — create project with GL compatibility renderer

**Description**: Create a project with the `gl_compatibility` renderer.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_test_gl",
  "name": "TestGLCompat",
  "renderer": "gl_compatibility"
}
```
**Expected result**: Project created. In `project.godot`, the setting `rendering/renderer/rendering_method` = `"gl_compatibility"`.  
**Pay attention**: The `gl_compatibility` renderer is compatible with older hardware — verify that the setting is actually written.

#### Scenario 6: Edge case — missing path

**Description**: Call without the required `path` parameter.  
**Params**:
```json
{
  "name": "TestProject"
}
```
**Expected result**: Zod validation error on the server side. The response contains `isError: true` or the server returns an error before calling Godot (schema validation failed).  
**Pay attention**: The error should be caught BEFORE sending the request to Godot (Zod validation). The error text should indicate the missing `path` parameter.

#### Scenario 7: Edge case — missing name

**Description**: Call without the required `name` parameter.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_test_noname"
}
```
**Expected result**: Zod validation error. The `name` parameter is required.  
**Pay attention**: Validation error, not a Godot error.

#### Scenario 8: Edge case — invalid template enum

**Description**: Pass an invalid value for `template`.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_test_bad",
  "name": "BadTemplate",
  "template": "vr"
}
```
**Expected result**: Zod validation error. The value `"vr"` is not in the enum `['empty','2d','3d','ui','custom']`.  
**Pay attention**: Zod should reject the invalid enum; the error should clearly state the allowed values.

#### Scenario 9: Edge case — invalid renderer enum

**Description**: Pass an invalid value for `renderer`.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_test_bad2",
  "name": "BadRenderer",
  "renderer": "vulkan"
}
```
**Expected result**: Zod validation error. Allowed values: `forward_plus`, `mobile`, `gl_compatibility`.  
**Pay attention**: Zod should reject `"vulkan"`.

#### Scenario 10: Edge case — path contains special characters (Windows)

**Description**: Path contains characters invalid for the file system.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_<>test",
  "name": "BadPath"
}
```
**Expected result**: Error from Godot or the file system when attempting to create the directory.  
**Pay attention**: Depending on the implementation, the error may come from Zod (if FilePath has additional validation) or from the operating system when creating the directory.

#### Scenario 11: Edge case — path already exists

**Description**: Attempt to create a project in an already existing non-empty directory.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_test_project",
  "name": "DuplicateProject"
}
```
**Expected result**: Behavior depends on the Godot plugin implementation. Possible outcomes: (a) overwriting the existing `project.godot`, (b) "directory not empty" error, (c) successful creation with a warning.  
**Notes**: Use the path from Scenario 1 (after its successful execution).  
**Pay attention**: Document the actual behavior. If overwriting occurs — this is a data loss risk.

#### Scenario 12: Variation — custom template

**Description**: Create a project with the `custom` template.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_test_custom",
  "name": "TestCustom",
  "template": "custom"
}
```
**Expected result**: Project created. The behavior of `custom` depends on the plugin implementation — it may create an empty project or request additional configuration.  
**Pay attention**: Clarify in the documentation what exactly the `custom` template does.

---

## Tool: create_project_from_template

**Tool name**: `create_project_from_template`  
**Description**: Create a new Godot project from an existing template project  
**Backend method**: `project_creation/create_from_template`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `string` (FilePath) | **Yes** | — | Directory path where the project will be created |
| `template_path` | `string` (FilePath) | **Yes** | — | Path to the template project directory |
| `name` | `string` (Name) | No | — | Override project name |

### Test Scenarios

#### Scenario 1: Happy path — create project from existing template

**Description**: Use an existing Godot project as a template.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_from_template",
  "template_path": "C:/tmp/godot_mcp_test_project",
  "name": "ClonedProject"
}
```
**Expected result**: Successful project creation. The new directory contains a copy of the template structure. `project.godot` contains the name `"ClonedProject"`.  
**Notes**: Prerequisite: `C:/tmp/godot_mcp_test_project` must exist (created via `create_project`, Scenario 1).  
**Pay attention**: Verify that all files from the template are copied. Verify that `project.godot` has the overridden name.

#### Scenario 2: Happy path — create from template without name override

**Description**: Create a project from a template without overriding the name.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_from_template2",
  "template_path": "C:/tmp/godot_mcp_test_project"
}
```
**Expected result**: Project created. The project name is either inherited from the template or extracted from the directory name.  
**Pay attention**: Check which name is used in `project.godot` when `name` is not specified.

#### Scenario 3: Edge case — template_path does not exist

**Description**: The template project does not exist on disk.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_bad_template",
  "template_path": "C:/tmp/nonexistent_template_project"
}
```
**Expected result**: Error from Godot: template path not found, directory does not exist, or similar.  
**Pay attention**: The response should be marked `isError: true`. The error text should indicate a problem with `template_path`.

#### Scenario 4: Edge case — template_path is not a Godot project

**Description**: `template_path` points to a directory without `project.godot`.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_not_project",
  "template_path": "C:/tmp"
}
```
**Expected result**: Error from Godot: "not a valid Godot project", "project.godot not found", or similar.  
**Pay attention**: The error should clearly indicate that `template_path` does not contain `project.godot`.

#### Scenario 5: Edge case — missing path

**Description**: Call without the required `path` parameter.  
**Params**:
```json
{
  "template_path": "C:/tmp/godot_mcp_test_project"
}
```
**Expected result**: Zod validation error on the `path` parameter.  
**Pay attention**: The `path` parameter is required.

#### Scenario 6: Edge case — missing template_path

**Description**: Call without the required `template_path` parameter.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_no_template"
}
```
**Expected result**: Zod validation error on the `template_path` parameter.  
**Pay attention**: The `template_path` parameter is required.

#### Scenario 7: Edge case — path matches template_path

**Description**: Attempt to create a project on top of the template (overwriting the source).  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_test_project",
  "template_path": "C:/tmp/godot_mcp_test_project"
}
```
**Expected result**: Depends on implementation. Either a "cannot copy into itself" error or overwriting (dangerous).  
**Pay attention**: Document the actual behavior — this is a critical edge case.

---

## Tool: scaffold_project_structure

**Tool name**: `scaffold_project_structure`  
**Description**: Create a standard folder structure for a Godot project  
**Backend method**: `project_creation/scaffold_structure`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `project_path` | `string` (FilePath) | **Yes** | — | Path to the Godot project root |
| `structure` | `enum('standard','minimal','full')` | No | — | Folder structure preset |

### Test Scenarios

#### Scenario 1: Happy path — scaffold standard structure

**Description**: Create a standard folder structure in an existing project.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project"
}
```
**Expected result**: Standard directories are created in the project (e.g., `scenes/`, `scripts/`, `assets/`, `addons/`).  
**Notes**: Prerequisite: project created via `create_project` (Scenario 1).  
**Pay attention**: Verify the presence of created directories. Verify that the standard structure matches the expected layout (depends on the plugin implementation).

#### Scenario 2: Happy path — scaffold minimal structure

**Description**: Create a minimal folder structure.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "structure": "minimal"
}
```
**Expected result**: A minimal structure is created (fewer folders than `standard`).  
**Pay attention**: Compare with the `standard` result — there should be fewer folders.

#### Scenario 3: Happy path — scaffold full structure

**Description**: Create a full (extended) folder structure.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "structure": "full"
}
```
**Expected result**: An extended structure with more subdirectories is created (e.g., `scenes/levels/`, `scenes/ui/`, `scripts/autoloads/`, `assets/textures/`, `assets/audio/`, etc.).  
**Pay attention**: Verify that the `full` structure contains all folders from `standard` plus additional ones.

#### Scenario 4: Edge case — invalid structure enum

**Description**: Pass an invalid value for `structure`.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "structure": "enterprise"
}
```
**Expected result**: Zod validation error. Allowed values: `standard`, `minimal`, `full`.  
**Pay attention**: Zod should reject the request before sending it to Godot.

#### Scenario 5: Edge case — project_path does not exist

**Description**: A path to a non-existent project is specified.  
**Params**:
```json
{
  "project_path": "C:/tmp/nonexistent_project"
}
```
**Expected result**: Error from Godot: "project not found", "path does not exist", or similar.  
**Pay attention**: `isError: true`, message indicates a problem with `project_path`.

#### Scenario 6: Edge case — project_path is not a Godot project

**Description**: The path points to a directory without `project.godot`.  
**Params**:
```json
{
  "project_path": "C:/tmp"
}
```
**Expected result**: Error: "not a Godot project", "project.godot not found".  
**Pay attention**: Difference from Scenario 5: the directory exists but is not a project.

#### Scenario 7: Edge case — missing project_path

**Description**: Call without the required `project_path` parameter.  
**Params**:
```json
{}
```
**Expected result**: Zod validation error on the `project_path` parameter.  
**Pay attention**: `project_path` is required.

#### Scenario 8: Variation — repeated scaffold call

**Description**: Double call to `scaffold_project_structure` with the same parameters.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "structure": "standard"
}
```
**Expected result**: Idempotent behavior: either folders are not duplicated (already exist), or a "directory already exists" error (unlikely). Preferably — a successful response without duplication.  
**Pay attention**: Verify that duplicate folders are not created. Idempotency is important for repeatable tests.

---

## Tool: create_project_with_assets

**Tool name**: `create_project_with_assets`  
**Description**: Create a new Godot project and import specified assets into it  
**Backend method**: `project_creation/create_with_assets`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `string` (FilePath) | **Yes** | — | Directory path where the project will be created |
| `name` | `string` (Name) | **Yes** | — | Project name |
| `assets` | `array<{type, source, destination}>` | **Yes** | — | List of assets to import into the project |

**Asset object schema**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `string` | **Yes** | Asset type (e.g. 'texture', 'audio', 'scene', 'script') |
| `source` | `string` | **Yes** | Source file path to import from |
| `destination` | `string` | **Yes** | Destination path within the project (res://...) |

### Test Scenarios

#### Scenario 1: Happy path — create project with single texture asset

**Description**: Create a project and import a single texture asset.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_with_assets",
  "name": "AssetProject",
  "assets": [
    {
      "type": "texture",
      "source": "C:/tmp/test_texture.png",
      "destination": "res://assets/textures/test_texture.png"
    }
  ]
}
```
**Expected result**: Project created. The file `test_texture.png` is imported into the project. In the `assets/textures/` directory (or at the specified path), the file and the corresponding `.import` file are present.  
**Notes**: Prerequisite: `C:/tmp/test_texture.png` must exist.  
**Pay attention**: Verify that the following are created: `project.godot`, the asset file, the `.import` file.

#### Scenario 2: Happy path — create project with multiple asset types

**Description**: Import several assets of different types.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_multi_assets",
  "name": "MultiAssetProject",
  "assets": [
    {
      "type": "texture",
      "source": "C:/tmp/test_texture.png",
      "destination": "res://assets/textures/test.png"
    },
    {
      "type": "audio",
      "source": "C:/tmp/test_sound.wav",
      "destination": "res://assets/audio/test.wav"
    },
    {
      "type": "script",
      "source": "C:/tmp/test_script.gd",
      "destination": "res://scripts/test.gd"
    }
  ]
}
```
**Expected result**: Project created, all three assets imported. Each file is located at the specified path. Corresponding `.import` files are created.  
**Pay attention**: Verify each asset individually. Ensure that `.import` files are correct and point to the right paths.

#### Scenario 3: Happy path — create project with scene asset

**Description**: Import a scene as an asset.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_scene_asset",
  "name": "SceneAssetProject",
  "assets": [
    {
      "type": "scene",
      "source": "C:/tmp/test_scene.tscn",
      "destination": "res://scenes/imported.tscn"
    }
  ]
}
```
**Expected result**: Scene imported. The file `imported.tscn` is present and readable by Godot.  
**Pay attention**: Verify that the scene is valid (if possible, open via API). The scene may have dependencies.

#### Scenario 4: Edge case — missing path

**Description**: Call without `path`.  
**Params**:
```json
{
  "name": "NoPath",
  "assets": []
}
```
**Expected result**: Zod validation error on the `path` parameter.  
**Pay attention**: `path` is required.

#### Scenario 5: Edge case — missing name

**Description**: Call without `name`.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_noname2",
  "assets": []
}
```
**Expected result**: Zod validation error on the `name` parameter.  
**Pay attention**: `name` is required.

#### Scenario 6: Edge case — missing assets

**Description**: Call without the `assets` parameter.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_no_assets",
  "name": "NoAssets"
}
```
**Expected result**: Zod validation error on the `assets` parameter.  
**Pay attention**: `assets` is required.

#### Scenario 7: Edge case — empty assets array

**Description**: Pass an empty assets array.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_empty_assets",
  "name": "EmptyAssets",
  "assets": []
}
```
**Expected result**: Project created but no assets imported (array is empty). The result is analogous to `create_project` without assets.  
**Pay attention**: An empty array should not cause an error. The project should be created.

#### Scenario 8: Edge case — source file does not exist

**Description**: The asset source file does not exist.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_bad_source",
  "name": "BadSourceProject",
  "assets": [
    {
      "type": "texture",
      "source": "C:/tmp/nonexistent.png",
      "destination": "res://assets/nonexistent.png"
    }
  ]
}
```
**Expected result**: Error from Godot: file not found, cannot import, or similar.  
**Pay attention**: Check whether the project is created (partial success) or the operation is fully rolled back.

#### Scenario 9: Edge case — asset object missing required fields

**Description**: The asset object does not contain the required `type` field.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_bad_asset",
  "name": "BadAsset",
  "assets": [
    {
      "source": "C:/tmp/test.png",
      "destination": "res://test.png"
    }
  ]
}
```
**Expected result**: Zod validation error: the `type` field is required in each asset object.  
**Pay attention**: Zod should validate the schema of each array element.

#### Scenario 10: Edge case — destination without res:// prefix

**Description**: `destination` does not contain `res://`.  
**Params**:
```json
{
  "path": "C:/tmp/godot_mcp_bad_dest",
  "name": "BadDest",
  "assets": [
    {
      "type": "texture",
      "source": "C:/tmp/test_texture.png",
      "destination": "assets/textures/test.png"
    }
  ]
}
```
**Expected result**: Depends on implementation. Either Zod passes it through (FilePath is just a string), or Godot rejects a path without the `res://` prefix.  
**Pay attention**: Document the actual behavior. It is recommended to always use `res://`.

---

## Tool: initialize_git_repository

**Tool name**: `initialize_git_repository`  
**Description**: Initialize a Git repository in the project directory with a proper .gitignore  
**Backend method**: `project_creation/init_git`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `project_path` | `string` (FilePath) | **Yes** | — | Path to the Godot project root |
| `include_gitignore` | `boolean` | No | — | Whether to create a Godot-specific .gitignore |

### Test Scenarios

#### Scenario 1: Happy path — init git with .gitignore

**Description**: Initialize a Git repository with `.gitignore`.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "include_gitignore": true
}
```
**Expected result**: A `.git/` directory (or `.git` file for worktree) is created in the project root. The `.gitignore` file is created and contains Godot-specific rules (`.import/`, `export/`, `*.translation`, etc.).  
**Notes**: Prerequisite: project created via `create_project`.  
**Pay attention**: Verify the presence of `.git/` and `.gitignore`. Verify that `.gitignore` contains rules for Godot.

#### Scenario 2: Happy path — init git without .gitignore

**Description**: Initialize a Git repository WITHOUT `.gitignore`.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "include_gitignore": false
}
```
**Expected result**: Git repository created (`.git/` is present). The `.gitignore` file is NOT created OR is created empty.  
**Pay attention**: Explicitly verify the absence of `.gitignore` or its emptiness. IMPORTANT: do not confuse with `.gitignore` from the previous scenario — use a separate project.

#### Scenario 3: Happy path — init git with default (omit include_gitignore)

**Description**: Call without the `include_gitignore` parameter.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project"
}
```
**Expected result**: Git repository created. The default behavior of `include_gitignore`: either `true` (create .gitignore) or `false`.  
**Pay attention**: Document the default value (depends on the Godot-side implementation).

#### Scenario 4: Edge case — project_path does not exist

**Description**: Attempt to initialize Git in a non-existent project.  
**Params**:
```json
{
  "project_path": "C:/tmp/nonexistent_project"
}
```
**Expected result**: Error: "project not found", "directory does not exist".  
**Pay attention**: `isError: true`.

#### Scenario 5: Edge case — Git already initialized

**Description**: Re-initialize Git in a project that already has `.git`.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project"
}
```
**Expected result**: Idempotent behavior. `git init` in an existing repository is a safe operation (reinitialized). There should be no error.  
**Pay attention**: Verify that `.gitignore` is not duplicated and not lost.

#### Scenario 6: Edge case — missing project_path

**Description**: Call without `project_path`.  
**Params**:
```json
{}
```
**Expected result**: Zod validation error on the `project_path` parameter.  
**Pay attention**: `project_path` is required.

---

## Tool: create_project_readme

**Tool name**: `create_project_readme`  
**Description**: Generate a README.md file for the project  
**Backend method**: `project_creation/create_readme`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `project_path` | `string` (FilePath) | **Yes** | — | Path to the Godot project root |
| `content` | `string` | No | — | Custom README content (overrides template) |
| `template` | `enum('basic','detailed','game')` | No | — | README template style |

### Test Scenarios

#### Scenario 1: Happy path — generate README with basic template

**Description**: Create README.md with a basic template.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "template": "basic"
}
```
**Expected result**: A `README.md` file is created in the project root. The content is a template with the project name and a basic structure (title, description, run instructions).  
**Notes**: Prerequisite: project created via `create_project`.  
**Pay attention**: Verify that `README.md` exists and contains something meaningful (not empty).

#### Scenario 2: Happy path — generate README with detailed template

**Description**: Create README.md with a detailed template.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "template": "detailed"
}
```
**Expected result**: `README.md` is created with more detailed content: installation sections, dependencies, project structure, development instructions.  
**Pay attention**: Compare with `basic` — there should be more sections and details.

#### Scenario 3: Happy path — generate README with game template

**Description**: Create README.md with a game template.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "template": "game"
}
```
**Expected result**: `README.md` is created with game-specific sections: gameplay, controls, screenshots, credits.  
**Pay attention**: The `game` template should contain game sections.

#### Scenario 4: Happy path — custom content overrides template

**Description**: Pass `content` along with `template`.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "template": "basic",
  "content": "# My Custom README\n\nThis is custom content."
}
```
**Expected result**: `README.md` is created with **custom content** (not template content). `content` takes priority over `template`.  
**Pay attention**: The file content should exactly match the passed `content`. The template should NOT be generated.

#### Scenario 5: Happy path — custom content without template

**Description**: Pass only `content` without `template`.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "content": "# Just Custom\n\nNo template used."
}
```
**Expected result**: `README.md` contains only the custom text.  
**Pay attention**: Without `template`, behavior should be analogous to Scenario 4.

#### Scenario 6: Happy path — no template, no content (default)

**Description**: Call with only `project_path`.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project"
}
```
**Expected result**: `README.md` is created with the default template (likely `basic`).  
**Pay attention**: Document which template is used by default.

#### Scenario 7: Edge case — missing project_path

**Description**: Call without `project_path`.  
**Params**:
```json
{}
```
**Expected result**: Zod validation error.  
**Pay attention**: `project_path` is required.

#### Scenario 8: Edge case — invalid template enum

**Description**: Pass an invalid `template` value.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "template": "marketing"
}
```
**Expected result**: Zod validation error. Allowed values: `basic`, `detailed`, `game`.  
**Pay attention**: Zod should reject before sending to Godot.

#### Scenario 9: Edge case — project_path is not a project

**Description**: Path does not contain `project.godot`.  
**Params**:
```json
{
  "project_path": "C:/tmp"
}
```
**Expected result**: Error: "not a Godot project".  
**Pay attention**: README.md file should not be created outside of a project.

---

## Tool: create_project_license

**Tool name**: `create_project_license`  
**Description**: Create a LICENSE file for the project  
**Backend method**: `project_creation/create_license`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `project_path` | `string` (FilePath) | **Yes** | — | Path to the Godot project root |
| `license` | `enum('MIT','Apache-2.0','GPL-3.0','BSD-3-Clause','custom')` | **Yes** | — | License type |
| `custom_text` | `string` | No | — | Custom license text (required when license is 'custom') |

### Test Scenarios

#### Scenario 1: Happy path — create MIT license

**Description**: Create a LICENSE file with the MIT license.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "license": "MIT"
}
```
**Expected result**: A `LICENSE` (or `LICENSE.md`) file is created in the project root. The content is the standard MIT license text.  
**Notes**: Prerequisite: project created via `create_project`.  
**Pay attention**: Verify that the file exists and contains the correct MIT text.

#### Scenario 2: Happy path — create Apache-2.0 license

**Description**: Create LICENSE with Apache 2.0.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "license": "Apache-2.0"
}
```
**Expected result**: `LICENSE` file created with the Apache License 2.0 text.  
**Pay attention**: Apache 2.0 text is significantly longer than MIT — verify that it is complete.

#### Scenario 3: Happy path — create GPL-3.0 license

**Description**: Create GPL-3.0.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "license": "GPL-3.0"
}
```
**Expected result**: `LICENSE` file created with the GPL 3.0 text.  
**Pay attention**: GPL is a copyleft license; the text is specific.

#### Scenario 4: Happy path — create BSD-3-Clause license

**Description**: Create BSD-3-Clause.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "license": "BSD-3-Clause"
}
```
**Expected result**: `LICENSE` file created with the BSD 3-Clause text.  
**Pay attention**: Verify the presence of all three clauses in the text.

#### Scenario 5: Happy path — create custom license with custom_text

**Description**: Create a custom license.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "license": "custom",
  "custom_text": "Copyright (c) 2026 Test Author. All Rights Reserved."
}
```
**Expected result**: `LICENSE` created with the custom text.  
**Pay attention**: The text should exactly match `custom_text`.

#### Scenario 6: Edge case — custom license without custom_text

**Description**: `license: "custom"` without `custom_text`.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "license": "custom"
}
```
**Expected result**: Depends on implementation: (a) Zod validation error (if there is a `.refine()` to check the condition), (b) Godot error "custom_text required for custom license", (c) an empty LICENSE is created.  
**Pay attention**: The most correct behavior is an error, since `custom_text` is required for `custom`.

#### Scenario 7: Edge case — missing license

**Description**: Call without the `license` parameter.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project"
}
```
**Expected result**: Zod validation error. `license` is required.  
**Pay attention**: `license` is a required parameter.

#### Scenario 8: Edge case — missing project_path

**Description**: Call without `project_path`.  
**Params**:
```json
{
  "license": "MIT"
}
```
**Expected result**: Zod validation error. `project_path` is required.  
**Pay attention**: Both parameters (`project_path` and `license`) are required.

#### Scenario 9: Edge case — invalid license enum

**Description**: Invalid `license` value.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "license": "WTFPL"
}
```
**Expected result**: Zod validation error. Allowed values: `MIT`, `Apache-2.0`, `GPL-3.0`, `BSD-3-Clause`, `custom`.  
**Pay attention**: Zod should reject.

#### Scenario 10: Variation — overwrite existing LICENSE

**Description**: Re-call with a different license.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "license": "GPL-3.0"
}
```
**Expected result**: The existing `LICENSE` is overwritten with the GPL-3.0 text.  
**Pay attention**: Verify that the file is overwritten, not appended to.

---

## Tool: setup_project_dependencies

**Tool name**: `setup_project_dependencies`  
**Description**: Install and configure project addons/dependencies  
**Backend method**: `project_creation/setup_dependencies`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `project_path` | `string` (FilePath) | **Yes** | — | Path to the Godot project root |
| `addons` | `array<{name, source, url?}>` | **Yes** | — | List of addons to install |

**Addon object schema**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | `string` | **Yes** | Addon name |
| `source` | `enum('asset_lib','git','local')` | **Yes** | Where to get the addon from |
| `url` | `string` | No | Git URL or local path (required for git/local sources) |

### Test Scenarios

#### Scenario 1: Happy path — install addon from asset_lib

**Description**: Install an addon from the Godot Asset Library.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "addons": [
    {
      "name": "godot-jolt",
      "source": "asset_lib"
    }
  ]
}
```
**Expected result**: Addon installed in `addons/godot-jolt/`. Addon files and `plugin.cfg` are created.  
**Notes**: Prerequisite: project created and internet access available. The Asset Library must be accessible.  
**Pay attention**: Verify that the addon directory is created. Verify that `plugin.cfg` is correct.

#### Scenario 2: Happy path — install addon from git

**Description**: Install an addon from a Git repository.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "addons": [
    {
      "name": "dialogic",
      "source": "git",
      "url": "https://github.com/coppolaemilio/dialogic.git"
    }
  ]
}
```
**Expected result**: Addon cloned from Git into `addons/dialogic/`.  
**Notes**: Internet access and installed Git are required.  
**Pay attention**: Verify that `url` is required for `source: "git"`. Verify the clone was successful.

#### Scenario 3: Happy path — install addon from local path

**Description**: Install an addon from a local directory.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "addons": [
    {
      "name": "my_local_addon",
      "source": "local",
      "url": "C:/tmp/my_local_addon"
    }
  ]
}
```
**Expected result**: Addon copied from `C:/tmp/my_local_addon` to `addons/my_local_addon/`.  
**Notes**: Prerequisite: `C:/tmp/my_local_addon` must exist and be a valid addon.  
**Pay attention**: `url` is required for `source: "local"`.

#### Scenario 4: Happy path — install multiple addons

**Description**: Install several addons in one call.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "addons": [
    {
      "name": "addon_a",
      "source": "asset_lib"
    },
    {
      "name": "addon_b",
      "source": "git",
      "url": "https://github.com/example/addon-b.git"
    }
  ]
}
```
**Expected result**: Both addons installed. Each in its own subdirectory under `addons/`.  
**Pay attention**: If one addon fails — check whether the second one is still installed (transactionality).

#### Scenario 5: Edge case — missing addons

**Description**: Call without the `addons` parameter.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project"
}
```
**Expected result**: Zod validation error. `addons` is required.  
**Pay attention**: `addons` is required.

#### Scenario 6: Edge case — empty addons array

**Description**: Empty addons array.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "addons": []
}
```
**Expected result**: Successful response (nothing installed). No errors.  
**Pay attention**: An empty array is a valid case.

#### Scenario 7: Edge case — git source without url

**Description**: `source: "git"` without the `url` parameter.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "addons": [
    {
      "name": "no_url_addon",
      "source": "git"
    }
  ]
}
```
**Expected result**: Error: either Zod validation (if there is custom validation), or Godot error "url required for git source".  
**Pay attention**: `url` should be required for `source: "git"`.

#### Scenario 8: Edge case — local source without url

**Description**: `source: "local"` without `url`.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "addons": [
    {
      "name": "no_path_addon",
      "source": "local"
    }
  ]
}
```
**Expected result**: Error: "url required for local source" or similar.  
**Pay attention**: Analogous to Scenario 7.

#### Scenario 9: Edge case — invalid source enum

**Description**: Invalid `source` value in the addon object.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "addons": [
    {
      "name": "bad_source",
      "source": "marketplace"
    }
  ]
}
```
**Expected result**: Zod validation error. Allowed values: `asset_lib`, `git`, `local`.  
**Pay attention**: Zod should reject.

#### Scenario 10: Edge case — addon object missing name

**Description**: Addon object without `name`.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project",
  "addons": [
    {
      "source": "asset_lib"
    }
  ]
}
```
**Expected result**: Zod validation error. `name` is required in each object.  
**Pay attention**: Zod should validate the nested schema.

#### Scenario 11: Edge case — missing project_path

**Description**: Call without `project_path`.  
**Params**:
```json
{
  "addons": []
}
```
**Expected result**: Zod validation error.  
**Pay attention**: `project_path` is required.

---

## Tool: validate_project_structure

**Tool name**: `validate_project_structure`  
**Description**: Validate a Godot project's folder structure and configuration for correctness  
**Backend method**: `project_creation/validate_structure`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `project_path` | `string` (FilePath) | **Yes** | — | Path to the Godot project root |

### Test Scenarios

#### Scenario 1: Happy path — validate a valid project

**Description**: Validate a correctly created project.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project"
}
```
**Expected result**: Successful response. Returns information about the structure: list of folders, presence of `project.godot`, possibly warnings or a "valid" status.  
**Notes**: Prerequisite: project created via `create_project`, structure created via `scaffold_project_structure`.  
**Pay attention**: Verify that the response contains a validation status. Ensure there are no false errors for a correct project.

#### Scenario 2: Happy path — validate empty project (bare minimum)

**Description**: Validate a minimal project (only `project.godot`, no additional folders).  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project"
}
```
**Expected result**: Successful response, but possibly with warnings about missing standard directories (`scenes/`, `scripts/`).  
**Notes**: Use before calling `scaffold_project_structure`.  
**Pay attention**: Check which specific warnings/errors are returned for a minimal project.

#### Scenario 3: Edge case — validate non-existent project

**Description**: Validate a non-existent project.  
**Params**:
```json
{
  "project_path": "C:/tmp/nonexistent_project"
}
```
**Expected result**: Error: "project not found", "path does not exist", "project.godot not found".  
**Pay attention**: `isError: true`.

#### Scenario 4: Edge case — validate directory without project.godot

**Description**: Path points to a regular directory.  
**Params**:
```json
{
  "project_path": "C:/tmp"
}
```
**Expected result**: Error: "not a Godot project", "project.godot missing".  
**Pay attention**: Difference from Scenario 3: the directory exists but is not a project.

#### Scenario 5: Edge case — missing project_path

**Description**: Call without `project_path`.  
**Params**:
```json
{}
```
**Expected result**: Zod validation error. The only parameter, but it is required.  
**Pay attention**: `project_path` is required.

#### Scenario 6: Variation — validate after structure modifications

**Description**: Validate the structure after adding folders via `scaffold_project_structure`.  
**Params**:
```json
{
  "project_path": "C:/tmp/godot_mcp_test_project"
}
```
**Expected result**: The response should reflect the created structure (folders `scenes/`, `scripts/`, `assets/` are present). Validation successful.  
**Notes**: Sequence: `create_project` → `scaffold_project_structure` (standard) → `validate_project_structure`.  
**Pay attention**: Compare the result with Scenario 2 (without structure). The response should differ.

---

## Tool: get_project_templates

**Tool name**: `get_project_templates`  
**Description**: List all available project templates that can be used with create_project  
**Backend method**: `project_creation/get_templates`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| *(none)* | — | — | — | Tool takes no parameters |

### Test Scenarios

#### Scenario 1: Happy path — list all templates

**Description**: Get a list of available project templates.  
**Params**:
```json
{}
```
**Expected result**: Returns an array/list of templates. Each template contains at least an identifier/name (e.g., `"empty"`, `"2d"`, `"3d"`, `"ui"`). Possibly with additional metadata (description, category).  
**Notes**: This tool is STANDALONE — does not require an existing project. Can be tested first.  
**Pay attention**: Verify that the list contains all values from the `template` enum of the `create_project` tool (`empty`, `2d`, `3d`, `ui`, `custom`). Verify there are no duplicates.

#### Scenario 2: Happy path — verify response structure

**Description**: Verify the MCP response structure.  
**Params**:
```json
{}
```
**Expected result**: Standard `{ content: [{ type: "text", text: "..." }] }`. The text contains a JSON-serialized list of templates.  
**Pay attention**: `isError` should be absent or `false`. `text` should be valid JSON.

#### Scenario 3: Variation — call with extraneous params

**Description**: Call with an extra parameter (which should be ignored or cause an error).  
**Params**:
```json
{
  "unexpected_param": "value"
}
```
**Expected result**: Depends on Zod behavior with an empty schema `{}`: either a validation error (strict mode) or success with the extra parameter ignored (passthrough/strip).  
**Pay attention**: Document the actual behavior of the MCP SDK regarding extra parameters.

---

## Full Integration Test Sequence

Below is the recommended sequence for full integration testing:

```
Phase 1: Setup
  Teardown: delete C:/tmp/godot_mcp_test_project and all derivatives if they exist

Phase 2: Standalone tools (do not require a project)
  [A1] get_project_templates                  → verify template list

Phase 3: Project creation
  [B1] create_project (minimal)               → TestProject
  [B2] create_project (3d + forward_plus)     → Test3DProject
  [B3] create_project (2d + 4.3)              → Test2D
  [B4] create_project (ui)                    → TestUI
  [B5] create_project (gl_compatibility)      → TestGLCompat
  [B6] create_project_with_assets             → AssetProject + MultiAssetProject
  [B7] create_project_from_template           → ClonedProject

Phase 4: Tools on TestProject (sequentially)
  [C1] scaffold_project_structure (standard)   → standard structure
  [C2] validate_project_structure              → verify after scaffold
  [C3] initialize_git_repository (with gitignore)
  [C4] create_project_readme (detailed)
  [C5] create_project_license (MIT)
  [C6] setup_project_dependencies (1+ addon)
  [C7] validate_project_structure              → final verification

Phase 5: Edge case tests on TestProject
  [D1] initialize_git_repository (repeated)    → Git idempotency
  [D2] create_project_readme (custom content)  → README overwrite
  [D3] create_project_license (GPL-3.0)        → LICENSE overwrite
  [D4] scaffold_project_structure (full)       → extended structure

Phase 6: Cleanup
  Delete all test projects: C:/tmp/godot_mcp_test_*
```

---

## Error Handling Patterns

All tools use `callGodot(bridge, method, args)`, which:

1. Sends a request to Godot via WebSocket bridge
2. On success: returns `{ content: [{ type: "text", text: ... }] }`
3. On Godot error: returns `{ content: [{ type: "text", text: "Godot request failed: ..." }], isError: true }`
4. Zod validation errors: occur BEFORE sending to Godot, on the MCP SDK side

**When testing, verify**:
- Successful responses: `isError` is absent or `false`, `content[0].type === "text"`, `text` is valid JSON (where applicable)
- Validation errors: clear message about the invalid parameter
- Godot errors: `isError: true`, message starts with `"Godot request failed:"`

---

## Shared Types Used

The following from `shared-types.ts` are used:
- **`FilePath`** (`z.string()`) — paths to files and directories, described as `"File path (e.g. 'res://path/to/file')"`
- **`Name`** (`z.string()`) — string identifier, described as `"Name identifier"`
- **`z`** — re-export of zod for local enum/schema definitions

All three are simple strings with no additional validation (besides `.describe()`). Therefore, `FilePath` validation does not check file existence or path format — Godot handles that on its side.
