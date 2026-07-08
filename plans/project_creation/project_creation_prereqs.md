# Prerequisites for Project Creation Test Plan

> Derived from: `server/src/test_plans/project_creation_test_plan.md`
> Generated: 2026-07-08
> Tool source: `server/src/tools/project_creation.ts`

---

## Required Project State

### Godot Editor

- Godot 4.x editor **must be running** with the MCP plugin active and connected
- `mcp_runtime` autoload registered: `res://addons/godot_mcp/services/mcp_runtime.gd`
- A Godot project **must be open** in the editor (for `res://` path resolution tests)
- The MCP server must be connected to the Godot editor via WebSocket (auto-scanned port 6505-6514)

### Filesystem — Directories That Must Exist (for "path exists" tests)

| Directory | Purpose | Used By |
|---|---|---|
| `C:/tmp/godot_duplicate` | Pre-existing Godot project (must contain `project.godot`) | `create_project` scenario 21 (path already exists) |
| `C:/tmp/godot_scaffold_std` | Project already-scaffolded with `structure=standard` | `scaffold_project_structure` scenario 10 (idempotency) |
| `C:/tmp/non_godot_dir` | Regular directory (no `project.godot`) | `create_project_readme` scenario 12 |
| `C:/tmp/godot_repo` | Godot project already git-initialized | `initialize_git_repository` scenario 4 |
| `C:/tmp/godot_readme` | Project with existing `README.md` | `create_project_readme` scenario 9 |

### Filesystem — Directories That Must NOT Exist (for clean creation)

All of these must be **absent or empty** before the relevant test runs:

- `C:/tmp/godot_test_project`
- `C:/tmp/godot_empty`
- `C:/tmp/godot_2d`
- `C:/tmp/godot_3d`
- `C:/tmp/godot_ui`
- `C:/tmp/godot_custom`
- `C:/tmp/godot_fplus`
- `C:/tmp/godot_mob`
- `C:/tmp/godot_gl`
- `C:/tmp/godot_v4`
- `C:/tmp/godot_badv`
- `C:/tmp/godot_full`
- `C:/tmp/godot_noname` (must already exist or not — depends on scenario; see notes)
- `C:/tmp/godot_empty_name`
- `C:/tmp/godot_extra`
- `C:/tmp/godot_from_tmpl`
- `C:/tmp/godot_from_tmpl2`
- `C:/tmp/godot_notmpl`
- `C:/tmp/godot_empty`
- `C:/tmp/godot_scaffold`
- `C:/tmp/godot_scaffold_min`
- `C:/tmp/godot_scaffold_full`
- `C:/tmp/godot_with_assets`
- `C:/tmp/godot_multi_assets`
- `C:/tmp/godot_no_assets`
- `C:/tmp/godot_custom_asset`
- `C:/tmp/godot_no_name`
- `C:/tmp/godot_bad` (used by `create_project` scenario 17, `scaffold_project_structure` scenario 7, `create_project_readme` scenario 8, `setup_project_dependencies` scenarios 11-13)
- `C:/tmp/godot_bad2` (used by `create_project` scenario 18, `create_project_from_template` scenario 8, `create_project_with_assets` scenario 9, `setup_project_dependencies` scenario 12)
- `C:/tmp/godot_bad3` (create_project_with_assets scenario 10)
- `C:/tmp/godot_missing_src`
- `C:/tmp/godot_bad_type`
- `C:/tmp/godot_repo2`
- `C:/tmp/godot_repo3`
- `C:/tmp/godot_num`
- `C:/tmp/godot_readme2` through `C:/tmp/godot_readme8`
- `C:/tmp/godot_license` through `C:/tmp/godot_license9`
- `C:/tmp/godot_deps` through `C:/tmp/godot_deps8`
- `C:/tmp/godot_bad4` through `C:/tmp/godot_bad7`
- `C:/tmp/godot_valid`
- `C:/tmp/godot_fresh`
- `C:/tmp/godot_custom_struct`
- `C:/tmp/godot_broken`
- `C:/tmp/godot_circular`
- `C:/tmp/empty_directory`

> **Note on test ordering:** Several tests share directory names (e.g., `C:/tmp/godot_bad`, `C:/tmp/godot_repo`). Tests sharing the same target directory must either be run sequentially (first test creates it, second tests the "already exists" case) or directories must be cleaned between runs.

### Filesystem — Drives

| Requirement | Used By |
|---|---|
| Drive `Z:` must **NOT exist** (or be inaccessible) | `create_project` scenario 22 |
| Drive `C:` must exist and be writable | All file-creation tests |

### Filesystem — Source Assets (for `create_project_with_assets`)

| File | Type | Used By |
|---|---|---|
| `C:/images/player.png` | Valid PNG image | `create_project_with_assets` scenario 1 |
| `C:/images/bg.png` | Valid PNG image | `create_project_with_assets` scenario 2 |
| `C:/sounds/music.ogg` | Valid OGG audio file | `create_project_with_assets` scenario 2 |
| `C:/scenes/enemy.tscn` | Valid Godot scene file | `create_project_with_assets` scenario 2 |
| `C:/scripts/utils.gd` | Valid GDScript file | `create_project_with_assets` scenario 2 |
| `C:/data/data.json` | Any valid JSON file | `create_project_with_assets` scenario 4 |
| `C:/a.png` | Valid PNG image | `create_project_with_assets` scenario 12 |

### Filesystem — Templates (for `create_project_from_template`)

| Path | Description | Used By |
|---|---|---|
| `C:/templates/my_template` | Valid Godot project template directory (must contain `project.godot`) | `create_project_from_template` scenario 1 |
| `C:/templates/base_template` | Valid Godot project template directory | `create_project_from_template` scenario 2 |
| `C:/templates/t` | Valid Godot project template directory | `create_project_from_template` scenario 9 |
| `res://templates/platformer` | Valid Godot project template within the open Godot project | `create_project_from_template` scenario 3 |

### Filesystem — Local Addons (for `setup_project_dependencies`)

| Path | Description | Used By |
|---|---|---|
| `C:/dev/my_local_addon` | Valid Godot addon directory (must contain `plugin.cfg`) | `setup_project_dependencies` scenario 3 |
| `C:/dev/c` | Valid Godot addon directory | `setup_project_dependencies` scenario 4 |
| `C:/projects/shared_addon` | Valid Godot addon directory | `setup_project_dependencies` scenario 8 |

### Filesystem — Special Directories (for "not a Godot project" tests)

| Path | Used By |
|---|---|
| `C:/Windows` | `scaffold_project_structure` scenario 9 |
| `C:/Windows/System32` | `create_project_from_template` scenario 8 |
| `C:/Users` | `initialize_git_repository` scenario 9 |

---

## Required Scenes

No specific scenes need to exist in the open Godot project. These tools operate at the project level (filesystem), not the scene level.

However, the following "broken" project states are needed for `validate_project_structure`:

### Broken Project: Missing Critical Directories
At `C:/tmp/godot_broken`: A Godot project that has `project.godot` but is missing expected directories (e.g., a default scene file deleted, or key resource directories removed).

### Broken Project: Circular Scene Dependencies
At `C:/tmp/godot_circular`: A Godot project containing two scenes where scene A inherits scene B, and scene B inherits scene A.

---

## Required Resources

### Asset Files on Disk

These must exist **outside** the Godot project, on the local filesystem:

| Resource | Path | Format | Min Size | Used By |
|---|---|---|---|---|
| Player texture | `C:/images/player.png` | PNG | 1×1 pixel minimum | `create_project_with_assets` #1 |
| Background texture | `C:/images/bg.png` | PNG | 1×1 pixel minimum | `create_project_with_assets` #2 |
| Music file | `C:/sounds/music.ogg` | OGG Vorbis | 1 second minimum | `create_project_with_assets` #2 |
| Enemy scene | `C:/scenes/enemy.tscn` | Godot .tscn | Valid scene file | `create_project_with_assets` #2 |
| Utils script | `C:/scripts/utils.gd` | GDScript | Valid .gd file | `create_project_with_assets` #2 |
| Data file | `C:/data/data.json` | JSON | Valid JSON | `create_project_with_assets` #4 |
| Generic image | `C:/a.png` | PNG | 1×1 pixel minimum | `create_project_with_assets` #12 |

### Template Projects on Disk

| Resource | Path | Requirements |
|---|---|---|
| Template project 1 | `C:/templates/my_template` | Must contain `project.godot` file and at least one scene/resource |
| Template project 2 | `C:/templates/base_template` | Must contain `project.godot` file |
| Template project 3 | `C:/templates/t` | Must contain `project.godot` file |
| In-project template | `res://templates/platformer` | Must exist within the open Godot project, contain `project.godot` |

### Local Addon Directories

| Resource | Path | Requirements |
|---|---|---|
| Local addon 1 | `C:/dev/my_local_addon` | Must contain `plugin.cfg`, typical addon structure |
| Local addon 2 | `C:/dev/c` | Must contain `plugin.cfg` |
| Shared addon | `C:/projects/shared_addon` | Must contain `plugin.cfg` |

### Pre-existing Godot Projects (for "already exists" / "already initialized" tests)

| Resource | Path | State |
|---|---|---|
| Duplicate project | `C:/tmp/godot_duplicate` | Full Godot project with `project.godot` |
| Already git-initialized | `C:/tmp/godot_repo` | Godot project + `.git` directory + `.gitignore` |
| Already scaffolded | `C:/tmp/godot_scaffold_std` | Godot project + standard scaffold folders |
| Has README | `C:/tmp/godot_readme` | Godot project + existing `README.md` |
| Valid project | `C:/tmp/godot_valid` | Valid Godot project (standard structure) |
| Fresh project | `C:/tmp/godot_fresh` | Project created via `create_project` |
| Custom structure | `C:/tmp/godot_custom_struct` | Godot project with non-standard but valid layout |
| Broken (missing dirs) | `C:/tmp/godot_broken` | `project.godot` exists but key dirs missing |
| Circular refs | `C:/tmp/godot_circular` | Scene A inherits B, B inherits A |
| Non-Godot dir | `C:/tmp/non_godot_dir` | Regular directory, NO `project.godot` |
| Empty dir | `C:/tmp/empty_directory` | Completely empty directory |

---

## Required Editor/Game State

- **Play mode**: OFF (not playing). No `create_project` or related tools require the game to be running.
- **Editor layout**: Default. No special layout required.
- **Active tool**: Not applicable (these are project-level tools).
- **Breakpoints**: None required.

---

## Required Settings/Config

### Godot Project Settings

No specific project settings required. The tools create projects with settings; they don't depend on pre-existing ones.

### Input Actions

None required.

### Autoloads

The `mcp_runtime` autoload must be registered: `res://addons/godot_mcp/services/mcp_runtime.gd`

### Collision Layers

None required.

### Editor Settings

- MCP plugin must be **Active** (Project → Project Settings → Plugins → Godot MCP)

---

## Required External State

### Git

| Requirement | Used By |
|---|---|
| `git` must be installed and available on `PATH` | `initialize_git_repository` (all scenarios) |

### Internet Connectivity

| Requirement | Used By |
|---|---|
| Internet access to Godot Asset Library | `setup_project_dependencies` scenarios 1, 4, 6, 16 |
| Internet access to `https://github.com/user/my-addon.git` (must be a valid, cloneable repo) | `setup_project_dependencies` scenario 2 |
| Internet access to `https://github.com/x/b.git` (must be a valid, cloneable repo) | `setup_project_dependencies` scenario 4 |
| Internet access to `https://gitlab.com/x/y.git` (must be a valid, cloneable repo) | `setup_project_dependencies` scenario 7 |

### Addons

| Requirement | Used By |
|---|---|
| `godot-jolt` available on Asset Library | `setup_project_dependencies` scenario 1 |
| `dialogic` available on Asset Library | `setup_project_dependencies` scenario 6 |

---

## Zod Validation Tests (No Godot State Required)

These test scenarios only validate MCP server-side Zod schema parsing. They do **not** require a running Godot editor, any project, or any filesystem state:

| Tool | Scenarios |
|---|---|
| `create_project` | #15 (missing `path`), #16 (missing `name`), #17 (invalid `template`), #18 (invalid `renderer`) |
| `create_project_from_template` | #4 (missing `path`), #5 (missing `template_path`), #6 (missing both) |
| `scaffold_project_structure` | #6 (missing `project_path`), #7 (invalid `structure`) |
| `create_project_with_assets` | #5 (missing `path`), #6 (missing `name`), #7 (missing `assets`), #8 (missing `type`), #9 (missing `source`), #10 (missing `destination`) |
| `initialize_git_repository` | #5 (missing `project_path`), #6 (non-boolean `include_gitignore`), #7 (number `include_gitignore`) |
| `create_project_readme` | #7 (missing `project_path`), #8 (invalid `template`) |
| `create_project_license` | #6 (missing `project_path`), #7 (missing `license`), #8 (invalid `license`) |
| `setup_project_dependencies` | #9 (missing `project_path`), #10 (missing `addons`), #11 (missing `name`), #12 (missing `source`), #13 (invalid `source`) |
| `validate_project_structure` | #4 (missing `project_path`) |

These tests can run in isolation before connecting to Godot — they only test the TypeScript Zod schemas.

---

## Setup Script

The following PowerShell script creates the minimum set of prerequisite files and directories on a Windows system. Run **before** executing any Godot-dependent tests.

```powershell
# ============================================================================
# Prerequisites Setup for project_creation_test_plan.md
# Run this script BEFORE executing tests against Godot
# Must be run as Administrator if writing to C:/Windows adjacent paths
# ============================================================================

$ErrorActionPreference = "Stop"

# --- Helper function to create a minimal Godot project ---
function New-MinimalGodotProject {
    param([string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    $projectGodot = @"
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.
;
; Format:
;   [section] ; section goes between []
;   param=value ; assign values to parameters

config_version=5

[application]

config/name="TestProject"
"@
    Set-Content -Path "$Path\project.godot" -Value $projectGodot
}

# --- Helper function to create a minimal Godot template ---
function New-MinimalGodotTemplate {
    param([string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    $projectGodot = @"
; Engine configuration file.
config_version=5

[application]
config/name="TemplateProject"
"@
    Set-Content -Path "$Path\project.godot" -Value $projectGodot
    # Create at least one scene file
    New-Item -ItemType Directory -Path "$Path\scenes" -Force | Out-Null
    $scene = @"
[gd_scene load_steps=1 format=3 uid="uid://dummy0001"]
[node name="Node2D" type="Node2D"]
"@
    Set-Content -Path "$Path\scenes\main.tscn" -Value $scene
}

# --- Helper function to create a minimal addon ---
function New-MinimalAddon {
    param([string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    $pluginCfg = @"
[plugin]
name="TestAddon"
description="Minimal test addon"
author="Test"
version="1.0"
script="plugin.gd"
"@
    Set-Content -Path "$Path\plugin.cfg" -Value $pluginCfg
    $pluginGd = @"
tool
extends EditorPlugin
func _enter_tree(): pass
func _exit_tree(): pass
"@
    Set-Content -Path "$Path\plugin.gd" -Value $pluginGd
}

# --- 1. Create C:/tmp base directory ---
New-Item -ItemType Directory -Path "C:\tmp" -Force | Out-Null
Write-Host "[1/9] C:/tmp directory ready"

# --- 2. Create source asset files ---
$assetDirs = @(
    "C:\images",
    "C:\sounds",
    "C:\scenes",
    "C:\scripts",
    "C:\data"
)
foreach ($dir in $assetDirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# Create minimal 1x1 PNG (smallest valid PNG possible — 67 bytes)
$pngBytes = [byte[]]@(
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  # PNG signature
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,  # IHDR chunk
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,  # 1x1
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,  # RGB, no filter
    0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,  # IDAT chunk
    0x54, 0x08, 0xD7, 0x63, 0x60, 0x60, 0x60, 0x00,  # uncompressed data
    0x00, 0x00, 0x04, 0x00, 0x01, 0x27, 0x34, 0x0A,  #
    0x18, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,  # IEND chunk
    0x44, 0xAE, 0x42, 0x60, 0x82
)
Set-Content -Path "C:\images\player.png" -Value $pngBytes -Encoding Byte
Set-Content -Path "C:\images\bg.png" -Value $pngBytes -Encoding Byte
Set-Content -Path "C:\a.png" -Value $pngBytes -Encoding Byte

# Create minimal OGG (placeholder — a valid minimal OGG Vorbis file is ~4KB;
# we create a dummy that Godot may reject, but the test for missing/invalid source
# can use this; for the success test, replace with a real OGG)
# Minimal valid OGG with silent Vorbis stream
$oggBytes = [byte[]]@(
    0x4F, 0x67, 0x67, 0x53, 0x00, 0x02, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x01, 0x1E, 0x01, 0x76, 0x6F, 0x72,
    0x62, 0x69, 0x73, 0x00, 0x00, 0x00, 0x00, 0x02,
    0x44, 0xAC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0xEE, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00,
    0xB8, 0x01, 0x4F, 0x67, 0x67, 0x53, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x4F, 0x67,
    0x67, 0x53, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
)
Set-Content -Path "C:\sounds\music.ogg" -Value $oggBytes -Encoding Byte

# Create valid .tscn file
$tscn = @"
[gd_scene load_steps=1 format=3 uid="uid://dummyasset01"]
[node name="Enemy" type="Node2D"]
"@
Set-Content -Path "C:\scenes\enemy.tscn" -Value $tscn

# Create valid .gd file
$gd = @"
extends Node
func _ready():
    pass
"@
Set-Content -Path "C:\scripts\utils.gd" -Value $gd

# Create JSON data file
$json = '{"test": true, "value": 42}'
Set-Content -Path "C:\data\data.json" -Value $json

Write-Host "[2/9] Source assets created"

# --- 3. Create template projects ---
New-MinimalGodotTemplate -Path "C:\templates\my_template"
New-MinimalGodotTemplate -Path "C:\templates\base_template"
New-MinimalGodotTemplate -Path "C:\templates\t"
Write-Host "[3/9] Template projects created"

# --- 4. Create local addons ---
New-MinimalAddon -Path "C:\dev\my_local_addon"
New-MinimalAddon -Path "C:\dev\c"
New-MinimalAddon -Path "C:\projects\shared_addon"
Write-Host "[4/9] Local addons created"

# --- 5. Create pre-existing Godot projects ---
New-MinimalGodotProject -Path "C:\tmp\godot_duplicate"

# Already git-initialized: create project, then init git
New-MinimalGodotProject -Path "C:\tmp\godot_repo"
Push-Location "C:\tmp\godot_repo"
git init
git config user.email "test@test.com"
git config user.name "Test"
$gitignore = @"
# Godot 4+ specific ignores
.godot/
*.tmp
*.import
export_presets.cfg
"@
Set-Content -Path ".gitignore" -Value $gitignore
git add -A
git commit -m "initial"
Pop-Location

# Already scaffolded (standard)
New-MinimalGodotProject -Path "C:\tmp\godot_scaffold_std"
$folders = @("scenes", "scripts", "assets")
foreach ($f in $folders) {
    New-Item -ItemType Directory -Path "C:\tmp\godot_scaffold_std\$f" -Force | Out-Null
}

# Has README
New-MinimalGodotProject -Path "C:\tmp\godot_readme"
Set-Content -Path "C:\tmp\godot_readme\README.md" -Value "# Existing README`n`nThis file already exists."

# Valid project
New-MinimalGodotProject -Path "C:\tmp\godot_valid"
New-Item -ItemType Directory -Path "C:\tmp\godot_valid\scenes" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\tmp\godot_valid\scripts" -Force | Out-Null
Set-Content -Path "C:\tmp\godot_valid\scenes\main.tscn" -Value '[gd_scene load_steps=1 format=3]'

# Fresh project (will be created by tests, but pre-create for "already exists" scenario)
New-MinimalGodotProject -Path "C:\tmp\godot_fresh"
New-Item -ItemType Directory -Path "C:\tmp\godot_fresh\scenes" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\tmp\godot_fresh\scripts" -Force | Out-Null

# Custom structure project (non-standard layout)
New-MinimalGodotProject -Path "C:\tmp\godot_custom_struct"
New-Item -ItemType Directory -Path "C:\tmp\godot_custom_struct\levels" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\tmp\godot_custom_struct\actors" -Force | Out-Null

# Broken project (project.godot exists but no scenes/scripts dirs)
New-MinimalGodotProject -Path "C:\tmp\godot_broken"

# Circular scene refs project
New-MinimalGodotProject -Path "C:\tmp\godot_circular"
New-Item -ItemType Directory -Path "C:\tmp\godot_circular\scenes" -Force | Out-Null
# Scene A inherits B
$sceneA = @"
[gd_scene load_steps=2 format=3 uid="uid://csceneA001"]
[ext_resource type="PackedScene" uid="uid://csceneB001" path="res://scenes/b.tscn" id="1_b"]
[node name="A" instance=ExtResource("1_b")]
"@
Set-Content -Path "C:\tmp\godot_circular\scenes\a.tscn" -Value $sceneA
# Scene B inherits A
$sceneB = @"
[gd_scene load_steps=2 format=3 uid="uid://csceneB001"]
[ext_resource type="PackedScene" uid="uid://csceneA001" path="res://scenes/a.tscn" id="1_a"]
[node name="B" instance=ExtResource("1_a")]
"@
Set-Content -Path "C:\tmp\godot_circular\scenes\b.tscn" -Value $sceneB

# Non-Godot directory
New-Item -ItemType Directory -Path "C:\tmp\non_godot_dir" -Force | Out-Null

# Empty directory
New-Item -ItemType Directory -Path "C:\tmp\empty_directory" -Force | Out-Null

Write-Host "[5/9] Pre-existing projects created"

# --- 6. Create the in-project template (res:// path) ---
# This must be created within the open Godot project's filesystem
# The user must adjust PROJECT_ROOT to their actual open Godot project path
$PROJECT_ROOT = "C:\path\to\your\open\godot\project"
if (Test-Path $PROJECT_ROOT) {
    New-MinimalGodotTemplate -Path "$PROJECT_ROOT\templates\platformer"
    Write-Host "[6/9] In-project template created at res://templates/platformer"
} else {
    Write-Warning "[6/9] SKIPPED: Update `$PROJECT_ROOT` in this script to your open Godot project path, then re-run."
}

# --- 7. Create remaining clean directories needed by tests ---
$testDirs = @(
    "C:\tmp\my godot projects\space game"
)
foreach ($dir in $testDirs) {
    # Parent first
    $parent = Split-Path -Path $dir -Parent
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
Write-Host "[7/9] Test directories prepared"

# --- 8. Verify git is available ---
try {
    git --version | Out-Null
    Write-Host "[8/9] Git is available on PATH"
} catch {
    Write-Error "[8/9] Git is NOT available on PATH — initialize_git_repository tests will fail"
}

# --- 9. Summary ---
Write-Host "[9/9] Setup complete."
Write-Host ""
Write-Host "NEXT STEPS:"
Write-Host "  1. Ensure Godot editor is open with the MCP plugin active"
Write-Host "  2. Ensure PROJECT_ROOT in this script points to your open Godot project and re-run step 6"
Write-Host "  3. Ensure internet connectivity for setup_project_dependencies tests"
Write-Host "  4. Delete any leftover test directories from previous runs:"
Write-Host "     Get-ChildItem C:\tmp\godot_* -Directory | Remove-Item -Recurse -Force"
Write-Host ""
Write-Host "   To verify prerequisites:"
Write-Host "     Test-Path C:\templates\my_template\project.godot"
Write-Host "     Test-Path C:\dev\my_local_addon\plugin.cfg"
Write-Host "     Test-Path C:\images\player.png"
```

---

## Cleanup Script

Run between test batches to reset state:

```powershell
# Clean all godot test directories
$testPatterns = @(
    "C:\tmp\godot_*",
    "C:\tmp\test_projects",
    "C:\tmp\my godot projects"
)
foreach ($pattern in $testPatterns) {
    Get-ChildItem $pattern -Directory -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

# DO NOT remove these — they are permanent prerequisites:
# C:\templates\*  (template projects)
# C:\dev\*        (local addons)
# C:\images\*     (source assets)
# C:\sounds\*     (source audio)
# C:\scenes\*     (source scenes)
# C:\scripts\*    (source scripts)
# C:\data\*       (source data)
# C:\projects\*   (shared addons)
```

---

## Test Execution Order Recommendations

To minimize state conflicts (shared directory names across multiple scenarios):

1. **Phase 1 — Zod validation tests** (no Godot): Run all "missing param" / "invalid enum" scenarios first. No cleanup needed.
2. **Phase 2 — `create_project` + `scaffold_project_structure`**: Create projects, then scaffold them, then validate.
3. **Phase 3 — `create_project_from_template`**: Requires template projects from setup script.
4. **Phase 4 — `create_project_with_assets`**: Requires source assets from setup script.
5. **Phase 5 — `initialize_git_repository`**: Requires git on PATH + project dirs.
6. **Phase 6 — `create_project_readme` + `create_project_license`**: Requires project dirs.
7. **Phase 7 — `setup_project_dependencies`**: Requires internet + addon sources.
8. **Phase 8 — `validate_project_structure`**: Requires pre-created projects from setup script.
9. **Phase 9 — `get_project_templates`**: No requirements.
10. **Phase 10 — Cross-tool workflow tests**: End-to-end bootstrap sequence.
11. **Cleanup**: Run cleanup script between phases 2-10 as directories fill up.

---

## Known Gaps / TODOs

- [ ] The OGG placeholder in the setup script is minimal; a proper silent OGG Vorbis file should be generated for the multi-asset test. Godot may reject the placeholder.
- [ ] The "already git-initialized" setup uses `git init` which modifies the local repo — ensure no interference with your actual working repo.
- [ ] Drive `Z:` must genuinely not exist. If the test machine has a `Z:` drive, skip scenario 22 or use a different non-existent drive letter.
- [ ] The `res://templates/platformer` in-project template requires the open Godot project path — update `$PROJECT_ROOT` in the setup script.
- [ ] `setup_project_dependencies` tests for specific Asset Library addons (`godot-jolt`, `dialogic`) depend on those addons still being available on the Asset Library at test time.
- [ ] External git URLs (`github.com/user/my-addon.git`, `github.com/x/b.git`, `gitlab.com/x/y.git`) are example URLs; replace with real, accessible repositories or mock them.
