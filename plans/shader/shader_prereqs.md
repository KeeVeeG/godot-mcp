# Prerequisites for shader_test_plan.md

> **Test plan source:** `server/src/test_plans/shader_test_plan.md`
> **Target file:** `server/src/tools/shader.ts`
> **Bridge methods:** `shader/create`, `shader/read`, `shader/edit`, `shader/assign_material`, `shader/set_param`, `shader/get_params`, `shader/list`, `shader/validate`, `shader/delete`
>
> Every item listed below must exist BEFORE any test scenario can execute. Items marked `[ZOD]` test server-side Zeod validation only and require no Godot state. Items marked `[CHAIN]` depend on earlier test scenarios having produced the artifact.

---

## Required Project State

- Godot 4.x project with the `godot_mcp` addon active and websocket connection established
- MCP server (`server/dist/index.js`) running and connected to the Godot editor
- Project must have a filesystem (not a fresh empty project without any directories)
- `res://shaders/` directory must exist on disk
- `res://shaders/subfolder/` directory must exist on disk (for `create_shader` Scenario 15: nested directory test, and `delete_shader` Scenario 9: subdirectory delete test)
- `res://scripts/` directory must exist on disk with at least one file: `some_script.gd` (see Resources section below)
- `res://textures/` directory must exist on disk with at least one file: `checker.png` (see Resources section below)

---

## Required Scenes

### Scene A: 3D test scene (must be the currently open scene for `assign_shader_material`, `set_shader_param`, `get_shader_params`)

**Node hierarchy:**

```
SceneRoot (Node3D, root node)
├── Cube (MeshInstance3D)
│   └── [mesh: BoxMesh — see notes]
├── Sphere (MeshInstance3D)
│   └── [mesh: SphereMesh — see notes]
├── Player (Node3D)
│   └── Model (Node3D)
│       └── Armor (MeshInstance3D)
│           └── [mesh: any primitive mesh]
├── SomePlainNode (Node — plain Node, NOT a Node3D or Control)
└── EmptyNode (Node — plain Node, no ShaderMaterial, no rendering components)
```

**Node details:**

| Node | Type | Requirements |
|------|------|-------------|
| `Cube` | `MeshInstance3D` | Must have a `mesh` property set (e.g., a `BoxMesh` resource). This gives it a `surface_material_override/0` slot that `assign_shader_material` can target. Used by: `assign_shader_material` Scenarios 1, 4, 11; `set_shader_param` Scenarios 1–6, 9, 12; `get_shader_params` Scenario 1. |
| `Sphere` | `MeshInstance3D` | Must have a `mesh` property set (e.g., a `SphereMesh` resource). Used by: `assign_shader_material` Scenario 4 (same shader on two nodes). |
| `Player/Model/Armor` | `MeshInstance3D` (nested) | Must have a mesh resource. Tests deep path resolution: `assign_shader_material` Scenario 3. |
| `SomePlainNode` | `Node` (base type) | Must NOT have a `material` property or any rendering component. Tests error handling for incompatible nodes: `assign_shader_material` Scenario 9. |
| `EmptyNode` | `Node` (base type) | Must NOT have any `ShaderMaterial` assigned. Tests error when no material exists: `set_shader_param` Scenario 11; `get_shader_params` Scenario 2. |

### Scene B: 2D test scene (must be loadable/switched to for 2D-specific tests)

**Node hierarchy:**

```
SceneRoot (Node2D, root node)
└── Sprite2D (Sprite2D)
    └── [texture: any valid Texture2D — see notes]
```

**Node details:**

| Node | Type | Requirements |
|------|------|-------------|
| `Sprite2D` | `Sprite2D` | Must have a `texture` property set (any valid 2D texture). This gives it a `material` slot. Used by: `assign_shader_material` Scenario 2; `get_shader_params` Scenario 3; cross-tool workflow test (all 11 steps). |

---

## Required Resources

### Shader files (none exist at start — these are what create_shader produces, but listed for reference)

These shaders are created BY the test, but other tools depend on them. Run `create_shader` tests first:

| File | Shader Type | Content | Created By | Used By |
|------|------------|---------|-----------|---------|
| `res://shaders/test_default.gdshader` | `canvas_item` | Default template (`shader_type canvas_item;\n\nvoid fragment() {\n\t// Place your shader code here.\n}`) | `create_shader` S1 | `read_shader` S2, S4, S6, S7; `edit_shader` S6, S7, S8, S10; `delete_shader` S1, S8; `validate_shader` S1 |
| `res://shaders/test_canvas.gdshader` | `canvas_item` | Default template | `create_shader` S2 | `assign_shader_material` S2, S5, S7, S9, S10; `delete_shader` S4 |
| `res://shaders/test_spatial.gdshader` | `spatial` | Default template (or edited with uniforms — see notes below) | `create_shader` S3 | `read_shader` S3; `edit_shader` S11; `assign_shader_material` S1, S3, S4; `delete_shader` S2, S3; `validate_shader` S3 |
| `res://shaders/test_visual.gdshader` | `visual` (→ `canvas_item`) | Default template | `create_shader` S4 | — |
| `res://shaders/test_particles.gdshader` | `particles` | Default template | `create_shader` S5 | — |
| `res://shaders/test_sky.gdshader` | `sky` | Default template | `create_shader` S6 | — |
| `res://shaders/test_fog.gdshader` | `fog` | Default template | `create_shader` S7 | `delete_shader` S8 (force param type test) |
| `res://shaders/test_blit.gdshader` | `texture_blit` | Default template | `create_shader` S8 | — |
| `res://shaders/test_with_content.gdshader` | `canvas_item` | **Exact content:** `shader_type canvas_item;\n\nvoid fragment() {\n    COLOR = vec4(1.0, 0.0, 0.0, 1.0);\n}` | `create_shader` S9 | `read_shader` S1; `edit_shader` S1, S2, S3, S4, S5 |
| `res://shaders/test_spatial_content.gdshader` | `spatial` | **Exact content:** `shader_type spatial;\n\nvoid fragment() {\n    ALBEDO = vec3(0.0, 0.0, 1.0);\n}` | `create_shader` S10 | — |
| `res://shaders/test_long.gdshader` | `canvas_item` | 500+ lines of valid shader code | `create_shader` S16 | — |
| `res://shaders/subfolder/test_nested.gdshader` | `canvas_item` | Default template | `create_shader` S15 | `delete_shader` S9 |
| `res://shaders/test_broken.gdshader` | `canvas_item` | **Content:** `shader_type canvas_item;\n\nvoid fragment() {\n    COLOR = invalid;\n}` | Must be pre-created | `validate_shader` S2 |
| `res://shaders/test_type_mismatch.gdshader` | `canvas_item` | **Content:** `shader_type canvas_item;\n\nvoid fragment() {\n    ALBEDO = vec3(1.0);\n}` (spatial built-in in canvas_item shader) | Must be pre-created | `validate_shader` S4 |
| `res://shaders/test_empty.gdshader` | — | Empty / whitespace only | Must be pre-created | `validate_shader` S8 |
| `res://shaders/test_no_type.gdshader` | — | **Content:** `void fragment() {\n    COLOR = vec4(0.5);\n}` (no `shader_type` line) | Must be pre-created | `validate_shader` S9 |
| `res://shaders/lifecycle_test.gdshader` | `canvas_item` | **Exact content:** `shader_type canvas_item;\n\nuniform float brightness = 1.0;\nuniform vec4 base_color : source_color = vec4(1.0);\n\nvoid fragment() {\n    COLOR = base_color * brightness;\n}` | `create_shader` (workflow step 1) | Cross-tool workflow test (steps 2–11) |

### Non-shader files

| File | Content | Used By |
|------|---------|---------|
| `res://scripts/some_script.gd` | Any valid GDScript file (e.g., `extends Node`) | `read_shader` S6 (read non-shader file); `validate_shader` S7 (validate non-shader file); `delete_shader` S7 (delete non-shader file) |
| `res://textures/checker.png` | Any valid PNG image (e.g., a 64x64 checkerboard pattern) | `set_shader_param` S5 (set sampler2D/texture uniform via resource path) |

### IMPORTANT: Shader uniform requirements for `set_shader_param` tests

The shader assigned to `Cube` (via `assign_shader_material` Scenario 1, which assigns `res://shaders/test_spatial.gdshader`) **must** contain these uniform declarations for `set_shader_param` Scenario 1–5 to pass:

```glsl
uniform float intensity = 1.0;
uniform vec3 tint_color = vec3(1.0);
uniform bool use_effect = false;
uniform int iteration_count = 1;
uniform sampler2D albedo_texture;
```

**Options for fulfilling this requirement:**

1. **Edit `test_spatial.gdshader` after creation.** After `create_shader` Scenario 3 creates the default spatial template, use `edit_shader` to replace the default content with a version containing the required uniforms.
2. **Pre-create `test_spatial.gdshader` with the uniform content** instead of relying on the default template from `create_shader` Scenario 3.
3. **Use `test_spatial_content.gdshader` instead.** Modify the assign step to use `test_spatial_content.gdshader` (from `create_shader` Scenario 10), and edit that file to add the required uniforms.

The simplest approach: edit `test_spatial.gdshader` right after `create_shader` S3 produces it, replacing its default content with:

```glsl
shader_type spatial;

uniform float intensity = 1.0;
uniform vec3 tint_color = vec3(1.0);
uniform bool use_effect = false;
uniform int iteration_count = 1;
uniform sampler2D albedo_texture;

void fragment() {
    // Place your shader code here.
}
```

---

## Required Editor/Game State

- **Editor state:** Editor must be in **edit mode** (not play mode). All shader tools operate on project filesystem and scene tree in edit mode.
- **No game running** is required for all shader tools — none are runtime tools.
- **Open scene:** One of the test scenes (Scene A or Scene B) must be open in the editor, depending on which tool is being tested.
  - Scene A (3D) open for `assign_shader_material` (most scenarios), `set_shader_param`, `get_shader_params`
  - Scene B (2D) open for `assign_shader_material` Scenario 2 (Sprite2D) and cross-tool workflow test
- **No breakpoints** needed (shader tools are not runtime/debug tools)
- **No specific editor layout** required
- **No specific tool selected** in the editor

---

## Required Settings/Config

- No specific project settings need to be changed from defaults
- No input actions required
- No autoloads required (beyond the `mcp_runtime.gd` autoload that the godot-mcp addon registers automatically)
- No collision layers required
- No addons required beyond `godot_mcp`
- No git repository required
- No export presets required

---

## Setup Script

This GDScript can be executed via `godot_execute_editor_script` to create ALL prerequisites in one pass. Run this before any shader test scenarios:

```gdscript
# =============================================================================
# Shader Test Plan — Prerequisites Setup Script
# Execute via: godot_execute_editor_script
# =============================================================================

@tool
extends EditorScript

func _run() -> void:
    var fs := EditorInterface.get_resource_filesystem()
    var base_dir := "res://shaders"
    var scripts_dir := "res://scripts"
    var textures_dir := "res://textures"

    # --- Create directories ---
    _ensure_dir(base_dir)
    _ensure_dir(base_dir + "/subfolder")
    _ensure_dir(scripts_dir)
    _ensure_dir(textures_dir)

    # --- Create "broken" shader (invalid syntax) ---
    _write_file(base_dir + "/test_broken.gdshader",
        "shader_type canvas_item;\n\nvoid fragment() {\n    COLOR = invalid;\n}")

    # --- Create type-mismatch shader (canvas_item with spatial built-in) ---
    _write_file(base_dir + "/test_type_mismatch.gdshader",
        "shader_type canvas_item;\n\nvoid fragment() {\n    ALBEDO = vec3(1.0);\n}")

    # --- Create empty shader ---
    _write_file(base_dir + "/test_empty.gdshader", "")

    # --- Create no-type shader (missing shader_type) ---
    _write_file(base_dir + "/test_no_type.gdshader",
        "void fragment() {\n    COLOR = vec4(0.5);\n}")

    # --- Create dummy GDScript for read/validate/delete non-shader tests ---
    _write_file(scripts_dir + "/some_script.gd",
        "extends Node\n\nfunc _ready():\n\tpass\n")

    # --- Create dummy texture for sampler2D uniform test ---
    _create_checker_texture(textures_dir + "/checker.png")

    # --- Create 3D test scene ---
    _create_3d_scene()

    # --- Create 2D test scene ---
    _create_2d_scene()

    # --- Refresh filesystem ---
    fs.scan()
    print("[Shader Prereqs] Setup complete. Run create_shader tests next.")


func _ensure_dir(path: String) -> void:
    var dir := DirAccess.open("res://")
    if not dir.dir_exists(path):
        dir.make_dir_recursive(path)
        print("[Shader Prereqs] Created directory: ", path)


func _write_file(path: String, content: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(content)
    file.close()
    print("[Shader Prereqs] Created file: ", path)


func _create_checker_texture(path: String) -> void:
    var size := 64
    var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
    for y in size:
        for x in size:
            var is_white := ((x / 8) + (y / 8)) % 2 == 0
            var color := Color.WHITE if is_white else Color.BLACK
            image.set_pixel(x, y, color)
    image.save_png(path)
    print("[Shader Prereqs] Created checker texture: ", path)


func _create_3d_scene() -> void:
    # Scene root
    var root := Node3D.new()
    root.name = "ShaderTest3D"

    # Cube (MeshInstance3D)
    var cube := MeshInstance3D.new()
    cube.name = "Cube"
    var box_mesh := BoxMesh.new()
    box_mesh.size = Vector3(1, 1, 1)
    cube.mesh = box_mesh
    root.add_child(cube)
    cube.owner = root

    # Sphere (MeshInstance3D)
    var sphere := MeshInstance3D.new()
    sphere.name = "Sphere"
    var sphere_mesh := SphereMesh.new()
    sphere_mesh.radius = 0.5
    sphere_mesh.height = 1.0
    sphere.mesh = sphere_mesh
    root.add_child(sphere)
    sphere.owner = root

    # Player -> Model -> Armor (nested hierarchy)
    var player := Node3D.new()
    player.name = "Player"
    var model := Node3D.new()
    model.name = "Model"
    var armor := MeshInstance3D.new()
    armor.name = "Armor"
    armor.mesh = BoxMesh.new()
    model.add_child(armor)
    armor.owner = root
    player.add_child(model)
    model.owner = root
    root.add_child(player)
    player.owner = root

    # SomePlainNode (plain Node — no material/rendering)
    var plain := Node.new()
    plain.name = "SomePlainNode"
    root.add_child(plain)
    plain.owner = root

    # EmptyNode (plain Node — no ShaderMaterial)
    var empty_node := Node.new()
    empty_node.name = "EmptyNode"
    root.add_child(empty_node)
    empty_node.owner = root

    # Pack and save
    var packed := PackedScene.new()
    packed.pack(root)
    ResourceSaver.save(packed, "res://scenes/shader_test_3d.tscn")
    root.queue_free()
    print("[Shader Prereqs] Created 3D test scene: res://scenes/shader_test_3d.tscn")


func _create_2d_scene() -> void:
    var root := Node2D.new()
    root.name = "ShaderTest2D"

    var sprite := Sprite2D.new()
    sprite.name = "Sprite2D"
    # Create a small white rectangle as the sprite texture
    var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
    img.fill(Color.WHITE)
    var tex := ImageTexture.create_from_image(img)
    sprite.texture = tex
    root.add_child(sprite)
    sprite.owner = root

    var packed := PackedScene.new()
    packed.pack(root)
    ResourceSaver.save(packed, "res://scenes/shader_test_2d.tscn")
    root.queue_free()
    print("[Shader Prereqs] Created 2D test scene: res://scenes/shader_test_2d.tscn")
```

---

## Execution Order Summary

Tests in `shader_test_plan.md` are designed to run in a specific order. The recommended execution sequence:

### Phase 1: Prerequisites Setup
Execute the GDScript setup script above to create directories, error-case shaders, non-shader files, the texture, and both test scenes.

### Phase 2: Create Shaders
Run `create_shader` Scenarios 1–10, 15, 16 (skip 11–14 which are Zod/invalid-input tests). This produces all the happy-path shader files needed by later tools.

### Phase 3: Edit Shader for Uniforms
After `create_shader` S3 creates `test_spatial.gdshader` with default content, run `edit_shader` to replace its content with a version containing `intensity`, `tint_color`, `use_effect`, `iteration_count`, and `albedo_texture` uniforms. This is required for `set_shader_param` tests.

### Phase 4: Run Remaining Tests
Execute all other tests (`read_shader`, `edit_shader`, `assign_shader_material`, `set_shader_param`, `get_shader_params`, `list_shaders`, `validate_shader`, `delete_shader`, cross-tool workflow) in any order.

### Phase 5: Cleanup (optional)
Delete test shader files and test scenes if needed.

---

## Summary: What Must Exist Before First Test

| Category | Count | Items |
|----------|-------|-------|
| Directories | 4 | `res://shaders/`, `res://shaders/subfolder/`, `res://scripts/`, `res://textures/` |
| Non-shader files | 1 | `res://scripts/some_script.gd` |
| Textures | 1 | `res://textures/checker.png` (64×64 checkerboard PNG) |
| Pre-created shaders | 4 | `test_broken.gdshader`, `test_type_mismatch.gdshader`, `test_empty.gdshader`, `test_no_type.gdshader` |
| 3D Scene nodes | 6 | `Cube` (MeshInstance3D), `Sphere` (MeshInstance3D), `Player/Model/Armor` (nested MeshInstance3D), `SomePlainNode` (Node), `EmptyNode` (Node) |
| 2D Scene nodes | 1 | `Sprite2D` (Sprite2D with texture) |
| Scene files | 2 | `res://scenes/shader_test_3d.tscn`, `res://scenes/shader_test_2d.tscn` |
| Godot settings | 0 | All default settings are sufficient |
