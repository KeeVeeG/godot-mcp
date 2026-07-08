# Prerequisites for Resource Tools Test Plan

> **Source plan:** `server/src/test_plans/resource_test_plan.md`
> **Generated:** 2026-07-08
> **Tools covered:** `read_resource`, `edit_resource`, `create_resource`, `delete_resource`, `get_resource_preview`, `add_autoload`, `remove_autoload`, `duplicate_resource`, `list_resources`, `get_resource_dependencies`

---

## Required Project State

- Godot 4.x project open in the editor with the Godot MCP plugin active and connected
- The MCP server must be running and the WebSocket bridge connected to the Godot editor
- The following directories must exist on disk:
  - `res://resources/`
  - `res://autoload/`
  - `res://scripts/`
  - `res://scenes/`
  - `res://themes/`
  - `res://assets/`
  - `res://materials/` (for cross-directory duplication test)

## Required Scenes

### `res://scenes/main.tscn`
- Any valid scene file. Must exist in the project.
- Used by: `read_resource` S6 (for path-to-a-script test via script ref), `get_resource_preview` S8, `duplicate_resource` S12, `get_resource_dependencies` S1
- Should reference at least one script, texture, or material so dependency queries return non-empty results.

### `res://scenes/ui_manager.tscn`
- A valid scene with a root node (any type, `Node` is fine). Must be loadable as an autoload.
- Used by: `add_autoload` S2 (scene autoload registration)

### `res://scenes/complex_level.tscn`
- A scene with nested dependencies: at least one instanced sub-scene or preloaded resource.
- The scene must reference at least one material, texture, or other resource.
- Used by: `get_resource_dependencies` S10 (nested dependency resolution)

### Scene loaded in editor referencing a test material
- A scene must be open/loaded in the editor that references `res://resources/in_use_material.tres`.
- Use `manage_scene` to load this scene, or create a simple scene with a MeshInstance3D / Sprite2D using the material.
- Used by: `delete_resource` S5 (referenced resource deletion behavior)

## Required Resources

### Core test resources (must exist before any tests run)

| Path | Type | Properties | Created by |
|------|------|------------|------------|
| `res://resources/test_stylebox.tres` | `StyleBoxFlat` | Default properties (no custom overrides needed) | `create_resource` |
| `res://resources/test_material.tres` | `StandardMaterial3D` | Default properties | `create_resource` |
| `res://resources/test_gradient.tres` | `Gradient` | Default properties | `create_resource` |
| `res://resources/test_curve.tres` | `Curve` | Default properties | `create_resource` |
| `res://resources/test_theme.tres` | `Theme` | Default properties; must have at least one theme item override to exercise nested serialization | `create_resource` |
| `res://resources/test_data.res` | `StandardMaterial3D` (or any resource type that serializes as binary `.res`) | Default properties | `create_resource` (specify `.res` extension) |
| `res://themes/default_theme.tres` | `Theme` | Must contain at least one type variation (e.g., a Button style override) with nested `StyleBox` entries — exercises deep nested serialization | `create_resource` + `edit_resource` to add overrides |
| `res://resources/in_use_material.tres` | `StandardMaterial3D` | Default properties; must be **actively referenced** by a MeshInstance3D or Sprite2D node in the currently loaded scene | `create_resource`, then assign via `manage_material` or scene setup |
| `res://resources/circular_a.tres` | `Gradient` (or any resource that can reference another resource) | Set a property that points to `circular_b.tres` | Manual or scripted creation |
| `res://resources/circular_b.tres` | `Gradient` | Set a property that points to `circular_a.tres` | Manual or scripted creation |

### Script files

| Path | Content requirement | Used by |
|------|---------------------|---------|
| `res://scripts/player.gd` | Any valid GDScript (e.g., `extends Node2D`) | `read_resource` S6 (wrong extension), `get_resource_preview` S4, `duplicate_resource` S11, `get_resource_dependencies` S4 |
| `res://autoload/test_autoload.gd` | `extends Node` (minimal valid autoload script) | Integration scenario 2 |
| `res://autoload/global_settings.gd` | `extends Node` | `add_autoload` S1 |
| `res://autoload/audio_manager.gd` | `extends Node` | `add_autoload` S3 |
| `res://autoload/global_manager.gd` | `extends Node` | `delete_resource` S6 (must also be registered as an autoload — see settings below) |

### Asset files

| Path | Type | Used by |
|------|------|---------|
| `res://assets/texture.png` | Any PNG image imported as `Texture2D` | `get_resource_preview` S2 |

### Files that must NOT exist (for negative tests)

| Path | Reason |
|------|--------|
| `res://nonexistent/fake.tres` | Tests file-not-found error handling across multiple tools |
| `res://nonexistent/fake.trash` (any path under `res://nonexistent/`) | Multiple tools test nonexistent paths |
| `res://nonexistent_dir/` (directory) | `create_resource` S10 tests missing parent directory |
| `res://nonexistent/ghost.gd` | `add_autoload` S6 tests missing script |

### Optional test file (nice to have, not critical)

| Path | Notes |
|------|-------|
| `res://resources/my test file.tres` | `read_resource` S10 — tests space-in-path handling. If missing, test expects graceful error. |

## Required Editor/Game State

### Autoload registrations
- `global_manager` must be registered as an autoload in `project.godot` pointing to `res://autoload/global_manager.gd`.
  - Used by: `delete_resource` S6 (attempting to delete a registered autoload script)
  - **Important:** This must be set BEFORE the test run, as the scenario verifies that autoload-protected scripts can't be deleted.
- No other autoloads should be pre-registered (the `add_autoload` tool will create them during tests).

### Scene state
- A scene must be open in the editor (not necessarily playing) that has a node referencing `res://resources/in_use_material.tres`. This verifies the referenced-resource deletion behavior.
- No play mode is required — all resource tools operate in edit mode.

### Editor layout
- No specific layout required. The resource tools do not depend on editor layout.

### Breakpoints
- No breakpoints required.

## Required Settings/Config

### Project settings (`project.godot`)
- No custom project settings are strictly required for the resource tools.
- The `godot_mcp_config.json` must NOT disable any of the resource tools being tested.

### Input actions
- None required.

### Collision layers
- None required.

### Required Addons/Plugins
- Only the `godot_mcp` addon itself must be active (it is, by definition, since the MCP bridge is how tests run).
- No external addons required.

### Git state
- Not required. The resource tools do not interact with git.

---

## Setup Script

Run this GDScript via `execute_editor_script` or equivalent to create all required resources and state before executing the test plan:

```gdscript
# Resource Test Plan — Prerequisites Setup Script
# Run once before executing resource_test_plan.md scenarios.
# All paths use res:// scheme.

# Step 1: Create core test resources
ResourceLoader.save("res://resources/test_stylebox.tres", StyleBoxFlat.new())
ResourceLoader.save("res://resources/test_material.tres", StandardMaterial3D.new())
ResourceLoader.save("res://resources/test_gradient.tres", Gradient.new())
ResourceLoader.save("res://resources/test_curve.tres", Curve.new())

# Step 2: Create a Theme with nested overrides (for deep serialization tests)
var theme = Theme.new()
var normal_stylebox = StyleBoxFlat.new()
normal_stylebox.bg_color = Color(0.2, 0.2, 0.2)
theme.set_stylebox("normal", "Button", normal_stylebox)
theme.set_color("font_color", "Button", Color.WHITE)
ResourceLoader.save("res://themes/default_theme.tres", theme)

# Step 3: Create a basic Theme for edit tests (used as edit_resource S3 target)
var edit_theme = Theme.new()
edit_theme.default_font_size = 14
ResourceLoader.save("res://resources/test_theme.tres", edit_theme)

# Step 4: Create binary .res file (StandardMaterial3D saved as .res)
var bin_mat = StandardMaterial3D.new()
bin_mat.albedo_color = Color.GREEN
ResourceLoader.save("res://resources/test_data.res", bin_mat)

# Step 5: Create in-use material and assign it to a node in the current scene
var in_use_mat = StandardMaterial3D.new()
in_use_mat.albedo_color = Color.BLUE
ResourceLoader.save("res://resources/in_use_material.tres", in_use_mat)
# Manual: Create a MeshInstance3D in the scene and set its material_override to this material.
var editor = EditorInterface.new()
var root = editor.get_edited_scene_root()
if root:
	var mesh = MeshInstance3D.new()
	mesh.name = "TestMeshForMaterialRef"
	mesh.mesh = BoxMesh.new()
	mesh.material_override = load("res://resources/in_use_material.tres")
	root.add_child(mesh)
	mesh.owner = root

# Step 6: Create autoload scripts
var autoload_base = "# Auto-generated test autoload script\nextends Node\n"
var fa = FileAccess.open("res://autoload/test_autoload.gd", FileAccess.WRITE)
fa.store_string(autoload_base)
fa.close()
fa = FileAccess.open("res://autoload/global_settings.gd", FileAccess.WRITE)
fa.store_string(autoload_base)
fa.close()
fa = FileAccess.open("res://autoload/audio_manager.gd", FileAccess.WRITE)
fa.store_string(autoload_base)
fa.close()
fa = FileAccess.open("res://autoload/global_manager.gd", FileAccess.WRITE)
fa.store_string(autoload_base + "\n# This script is registered as an autoload for delete_resource S6 testing\n")
fa.close()

# Step 7: Register global_manager as an autoload
ProjectSettings.set_setting("autoload/global_manager", "res://autoload/global_manager.gd")

# Step 8: Create player script
fa = FileAccess.open("res://scripts/player.gd", FileAccess.WRITE)
fa.store_string("extends Node2D\n\nfunc _ready():\n\tpass\n")
fa.close()

# Step 9: Create a texture placeholder (1x1 PNG)
var img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
img.fill(Color.RED)
img.save_png("res://assets/texture.png")

# Step 10: Create circular dependency resources (if your Godot version allows cross-resource references)
# NOTE: Most built-in resource types don't easily create circular deps.
# These may need manual .tres file editing to inject a cross-reference.
var circ_a = Gradient.new()
ResourceLoader.save("res://resources/circular_a.tres", circ_a)
var circ_b = Gradient.new()
ResourceLoader.save("res://resources/circular_b.tres", circ_b)

# Step 11: Create the complex_level scene with nested dependencies
var complex_scene = PackedScene.new()
var complex_root = Node3D.new()
complex_root.name = "ComplexLevel"
var complex_mesh = MeshInstance3D.new()
complex_mesh.name = "ComplexMesh"
complex_mesh.mesh = BoxMesh.new()
var complex_mat = StandardMaterial3D.new()
complex_mat.albedo_color = Color.RED
ResourceLoader.save("res://resources/complex_material.tres", complex_mat)
complex_mesh.material_override = load("res://resources/complex_material.tres")
complex_root.add_child(complex_mesh)
complex_mesh.owner = complex_root
complex_scene.pack(complex_root)
ResourceSaver.save(complex_scene, "res://scenes/complex_level.tscn")

# Step 12: Create the ui_manager scene (for scene autoload test)
var ui_scene = PackedScene.new()
var ui_root = Node.new()
ui_root.name = "UIManagerRoot"
ui_root.set_script(load("res://autoload/test_autoload.gd"))
ui_scene.pack(ui_root)
ResourceSaver.save(ui_scene, "res://scenes/ui_manager.tscn")

# Step 13: Refresh filesystem
EditorInterface.get_resource_filesystem().scan()

print("[SETUP COMPLETE] All resource test prerequisites created.")
```

**Notes on the setup script:**
- The script assumes the `autoload/`, `resources/`, `scripts/`, `scenes/`, `assets/`, and `themes/` directories already exist. If not, create them first.
- The `global_manager` autoload registration modifies `project.godot`. After testing, it should be removed via `remove_autoload`.
- Circular dependency resources (S11 of `get_resource_dependencies`) may require post-creation `.tres` file editing to point one resource at another. The script above creates standalone resources; manually edit `circular_a.tres` and `circular_b.tres` if the engine's resource format supports direct cross-references.
- `EditorInterface` access may not be fully available from `execute_editor_script`. As a fallback, manually assign `in_use_material.tres` to a node in the scene.
- Step 3 may require `EditorInterface.get_resource_filesystem().scan()` to detect new file writes done via `FileAccess`.

---

## Test Execution Order Recommendations

Some scenarios depend on state created by earlier scenarios. The recommended order:

1. **Setup Phase** — Run the setup script above, or execute `create_resource` calls to create all prerequisite files.
2. **`create_resource`** — Test creation first. This also populates files needed by read/edit/delete/duplicate/preview tests.
3. **`read_resource`** — Read-back tests (verifies files created in step 2 are readable).
4. **`list_resources`** — Listing tests (verifies the file count and type filtering).
5. **`get_resource_preview`** — Preview generation tests.
6. **`duplicate_resource`** — Duplication tests (source files exist from step 2).
7. **`edit_resource`** — Edit tests on existing resources.
8. **`get_resource_dependencies`** — Dependency analysis.
9. **`add_autoload`** — Registration tests.
10. **`remove_autoload`** — Removal tests (must run after add_autoload, since they remove what was added).
11. **`delete_resource`** — Deletion tests (run **last** for files created in step 2, to avoid breaking other tests).
12. **Cleanup Phase** — Remove all autoloads, delete all test resources.
