# Prerequisites for Particles Test Plan

This document lists everything the test executor must set up before running any scenario in `particles_test_plan.md`.

---

## Required Project State

- Godot 4.x editor open with a project that has the **Godot MCP plugin** active and connected
- MCP server (`npx @keeveeg/godot-mcp` or local `node dist/index.js`) running and connected to the plugin
- No errors in the Godot output log (`godot_get_editor_log` should be clean)
- Scene root must support child nodes (default: empty scene with a valid root node)

---

## Required Scenes

Two test scenes must exist in the project. All scenario references use exact node names listed below.

### Scene 1: `res://test_scenes/particles_2d_test.tscn`

**Root:** `Node2D` (named `"Particles2DTest"`)

```
Particles2DTest (Node2D)
├── GPUParticles2D [named: "GPUParticles2D"]
│   └── (must have a ParticleProcessMaterial attached, see Setup Script)
├── Sprite2D [named: "Sprite2D"]
├── Player (Node2D) [named: "Player"]
│   ├── ExplosionEffect (GPUParticles2D) [named: "ExplosionEffect"]
│   │   └── (must have a ParticleProcessMaterial attached)
│   └── Effects (Node2D) [named: "Effects"]
│       └── Explosions (Node2D) [named: "Explosions"]
```

**Why each node is needed:**

| Node Path | Needed By |
|-----------|-----------|
| `GPUParticles2D` | Most tools' happy-path and error-path scenarios that reference an existing 2D particle node |
| `GPUParticles2D` with ParticleProcessMaterial | `set_particle_color_gradient` (requires pre-existing material — Godot handler line 151-152), `set_particle_velocity_curve` (line 367) |
| `Sprite2D` | `delete_particles` S5, `set_particle_material` S8, `apply_particle_preset` S11, `get_particle_info` S7 (all test non-particle-node error handling) |
| `Player` | `create_particles` S3 (parent path target) |
| `Player/ExplosionEffect` | `delete_particles` S2, `get_particle_info` S3 (delete/query nested particle) |
| `Player/Effects/Explosions` | `create_particles` S10 (deeply nested parent path) |

### Scene 2: `res://test_scenes/particles_3d_test.tscn`

**Root:** `Node3D` (named `"Particles3DTest"`)

```
Particles3DTest (Node3D)
└── GPUParticles3D [named: "GPUParticles3D"]
    └── (must have a ParticleProcessMaterial attached, see Setup Script)
```

**Why each node is needed:**

| Node Path | Needed By |
|-----------|-----------|
| `GPUParticles3D` | Scenarios that test 3D-specific behavior: `create_particles` S2 (ensure 3D scene works), `set_particle_material` S2, `set_particle_emission_shape` S2/S3/S5/S6, `apply_particle_preset` S6, `get_particle_info` S2 |
| `GPUParticles3D` with ParticleProcessMaterial | Same as 2D — gradient/velocity curve tests need pre-existing material |
| Node3D root | `create_particles` S2 verifies that GPUParticles3D can be added to a 3D-capable scene |

---

## Required Resources

No external `.tres`/`.res` files, textures, shaders, or audio files are needed by any test scenario. All particle resources (ParticleProcessMaterial, Gradient, GradientTexture1D, Curve, CurveTexture) are created programmatically by the Godot command handlers.

---

## Required Editor/Game State

- **Active scene before each test batch**: The executor must open the correct scene before running scenarios that depend on it:
  - Open `res://test_scenes/particles_2d_test.tscn` for 2D particle scenarios
  - Open `res://test_scenes/particles_3d_test.tscn` for 3D particle scenarios
- **Play mode**: Not required. All particle tools operate in edit mode only. No runtime/gameplay tests exist in this plan.
- **Editor layout**: Default is fine. No specific layout required.
- **Tool selection**: None required.
- **Breakpoints**: None required.

---

## Required Settings/Config

No special project settings, input actions, autoloads, or collision layers are required. The default Godot project template is sufficient.

---

## Node-Particle Type Validation Behavior (Important)

From the Godot command handler (`particles_commands.gd`):

| Tool | Non-particle node behavior |
|------|---------------------------|
| `delete_particles` | **Rejects** — returns `"Node is not a particle system"` (line 404) |
| `set_particle_material` | **Rejects** — returns `"Node is not a particle emitter"` (line 102) |
| `set_particle_color_gradient` | Returns `"Set process material first before applying color gradient"` if no process_material (line 152); passes if process_material exists on the node |
| `apply_particle_preset` | Creates ParticleProcessMaterial and assigns it — may succeed on any node (handles GPUParticles2D/3D at lines 253-256, other nodes are silently ignored for material assignment) |
| `get_particle_info` | **Rejects** — returns `"Node is not a particle emitter"` (line 295) |
| `set_particle_emission_shape` | Creates ParticleProcessMaterial if missing (lines 316-321), assigns it — may succeed on any node (handles GPUParticles2D/3D at lines 318-321) |
| `set_particle_velocity_curve` | Returns `"Set process material first before applying velocity curve"` if no process_material (line 367) |

---

## Setup Script

Run the following editor script to create both test scenes with all required node hierarchies. The script also pre-applies a process material to each particle node so that tools like `set_particle_color_gradient` and `set_particle_velocity_curve` work immediately.

Execute via: `godot_execute_editor_script` with the code below, or paste into a new GDScript and attach to an EditorScript.

```gdscript
# === Create 2D test scene ===
var root_2d := Node2D.new()
root_2d.name = "Particles2DTest"

# GPUParticles2D with pre-attached ParticleProcessMaterial
var gp2d := GPUParticles2D.new()
gp2d.name = "GPUParticles2D"
gp2d.amount = 8
gp2d.lifetime = 1.0
gp2d.emitting = true
var mat_2d := ParticleProcessMaterial.new()
gp2d.process_material = mat_2d
root_2d.add_child(gp2d)
gp2d.owner = root_2d

# Sprite2D (for non-particle error tests)
var sprite := Sprite2D.new()
sprite.name = "Sprite2D"
root_2d.add_child(sprite)
sprite.owner = root_2d

# Player node with nested children
var player := Node2D.new()
player.name = "Player"
root_2d.add_child(player)
player.owner = root_2d

# Nested particle under Player (for delete/info tests)
var explosion := GPUParticles2D.new()
explosion.name = "ExplosionEffect"
explosion.amount = 8
explosion.lifetime = 1.0
explosion.emitting = true
var exp_mat := ParticleProcessMaterial.new()
explosion.process_material = exp_mat
player.add_child(explosion)
explosion.owner = root_2d

# Deep hierarchy for nested parent path test
var effects := Node2D.new()
effects.name = "Effects"
player.add_child(effects)
effects.owner = root_2d

var explosions_container := Node2D.new()
explosions_container.name = "Explosions"
effects.add_child(explosions_container)
explosions_container.owner = root_2d

# Pack and save 2D scene
var packed_2d := PackedScene.new()
packed_2d.pack(root_2d)
ResourceSaver.save(packed_2d, "res://test_scenes/particles_2d_test.tscn")
print("Created res://test_scenes/particles_2d_test.tscn")

# === Create 3D test scene ===
var root_3d := Node3D.new()
root_3d.name = "Particles3DTest"

# GPUParticles3D with pre-attached ParticleProcessMaterial
var gp3d := GPUParticles3D.new()
gp3d.name = "GPUParticles3D"
gp3d.amount = 8
gp3d.lifetime = 1.0
gp3d.emitting = true
var mat_3d := ParticleProcessMaterial.new()
gp3d.process_material = mat_3d
root_3d.add_child(gp3d)
gp3d.owner = root_3d

# Pack and save 3D scene
var packed_3d := PackedScene.new()
packed_3d.pack(root_3d)
ResourceSaver.save(packed_3d, "res://test_scenes/particles_3d_test.tscn")
print("Created res://test_scenes/particles_3d_test.tscn")

# Ensure test_scenes directory exists and remove in-memory nodes
root_2d.free()
root_3d.free()
print("Particles test prerequisites created.")
```

> **Note**: If `res://test_scenes/` does not exist, create it first via `godot_manage_asset(action="create_folder", path="res://test_scenes")`.

---

## Test Execution Order Dependency

Some scenarios depend on nodes that other scenarios create or delete. The test executor must be aware of these dependencies:

- **`delete_particles` S1** deletes `GPUParticles2D` — this node must be recreated (reopen scene or re-run setup script) before any subsequent scenario that needs it.
- **`delete_particles` S2** deletes `Player/ExplosionEffect` — same issue; re-open scene after this test.
- **`create_particles` S1** creates a new `GPUParticles2D` variant (auto-named `"Particles_2d"`) at scene root — this does NOT conflict with the pre-existing `"GPUParticles2D"` because the handler generates the name `"Particles_2d"`, not `"GPUParticles2D"`.
- **Integration scenarios** create and mutate nodes freely — always reload the clean test scene before each integration scenario.

### Recommended strategy

For each test **tool** batch, reload the clean test scene first:
1. Open `res://test_scenes/particles_2d_test.tscn` (or 3D variant as needed)
2. Run all scenarios for that tool
3. Reopen the clean scene before moving to the next tool's scenarios

This avoids cross-test contamination from `delete_particles` and `create_particles` mutating the scene tree.

---

## Quick-Check Before Running

Run these sanity checks to confirm prerequisites are met:

| Check | Godot Tool Call | Expected Result |
|-------|----------------|-----------------|
| MCP connected | Any tool call succeeds | No connection error |
| 2D scene exists | `godot_get_scene_tree` with scene open | Root is `Particles2DTest` (Node2D) |
| `GPUParticles2D` exists in 2D scene | `godot_get_node_properties(path="GPUParticles2D")` | Properties returned, no error |
| `GPUParticles2D` has process_material | `godot_get_particle_info(path="GPUParticles2D")` | Response includes `material_type: "ParticleProcessMaterial"` |
| `Sprite2D` exists in 2D scene | `godot_get_node_properties(path="Sprite2D")` | Properties returned |
| `Player/ExplosionEffect` exists | `godot_get_node_properties(path="Player/ExplosionEffect")` | Properties returned, type is GPUParticles2D |
| `Player/Effects/Explosions` exists | `godot_get_node_properties(path="Player/Effects/Explosions")` | Properties returned |
| 3D scene exists | Open and `godot_get_scene_tree` | Root is `Particles3DTest` (Node3D) |
| `GPUParticles3D` exists in 3D scene | `godot_get_node_properties(path="GPUParticles3D")` | Properties returned, no error |
