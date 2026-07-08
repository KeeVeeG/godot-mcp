# Scene3D Tool Test Plan

**Source file:** `server/src/tools/scene3d.ts`  
**Module description:** 6 tools for 3D scene manipulation  
**Generated:** 2026-07-08  

---

## Shared Type Dependencies

All tools import the following from `shared-types.ts`:

| Import | Zod type | Description |
|--------|----------|-------------|
| `z` | Zod namespace | Validation library |
| `NodePath` | `z.string()` | Node path (e.g. `"Player/Sprite2D"`). `""` = scene root. |
| `ParentPath` | `z.string()` | Parent node path. `""` = scene root. |
| `Properties` | `z.record(z.unknown())` | **Required** property key-value pairs. |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | **Optional** property key-value pairs. |

---

## Tool 1: `add_mesh_instance`

**Description:** Add a MeshInstance3D with a primitive mesh type.  
**Handler:** `callGodot(bridge, 'scene3d/add_mesh', args)`  
**Expected return:** Success/error JSON with details of the created mesh node.  

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `parent` | `string` (ParentPath) | **Yes** | — | Parent node path. `""` = scene root. |
| `mesh_type` | `enum` | **Yes** | — | One of: `cube`, `sphere`, `cylinder`, `capsule`, `plane`, `prism`, `torus` |
| `properties` | `object` (OptionalProperties) | No | `undefined` | Mesh properties (size, material_path, etc.) |

### Test Scenarios

#### 1.1: Basic happy path — add a cube at scene root
- **Description:** Add a Cube MeshInstance3D at the scene root with no extra properties.  
- **Params:** `{ parent: "", mesh_type: "cube" }`  
- **Expected result:** Success. A MeshInstance3D named "MeshInstance3D" (or auto-named) with a BoxMesh is created at scene root.  
- **Notes:** Simplest valid call.

#### 1.2: Add a sphere as child of an existing node
- **Description:** Add a Sphere MeshInstance3D as a child of "Player".  
- **Params:** `{ parent: "Player", mesh_type: "sphere" }`  
- **Expected result:** Success. A MeshInstance3D with SphereMesh is created as child of "Player".  
- **Notes:** Validates non-empty parent path.

#### 1.3: Add a cylinder (enum variant)
- **Description:** Verify the `cylinder` mesh type.  
- **Params:** `{ parent: "", mesh_type: "cylinder" }`  
- **Expected result:** Success. CylinderMesh created.  
- **Notes:** Covers one enum value.

#### 1.4: Add a capsule (enum variant)
- **Description:** Verify the `capsule` mesh type.  
- **Params:** `{ parent: "", mesh_type: "capsule" }`  
- **Expected result:** Success. CapsuleMesh created.  
- **Notes:** Covers one enum value.

#### 1.5: Add a plane (enum variant)
- **Description:** Verify the `plane` mesh type.  
- **Params:** `{ parent: "", mesh_type: "plane" }`  
- **Expected result:** Success. PlaneMesh created.  
- **Notes:** Covers one enum value.

#### 1.6: Add a prism (enum variant)
- **Description:** Verify the `prism` mesh type.  
- **Params:** `{ parent: "", mesh_type: "prism" }`  
- **Expected result:** Success. PrismMesh created.  
- **Notes:** Covers one enum value.

#### 1.7: Add a torus (enum variant)
- **Description:** Verify the `torus` mesh type.  
- **Params:** `{ parent: "", mesh_type: "torus" }`  
- **Expected result:** Success. TorusMesh created.  
- **Notes:** Covers one enum value.

#### 1.8: Add mesh with custom properties
- **Description:** Add a cube with custom size and material path.  
- **Params:** `{ parent: "", mesh_type: "cube", properties: { size: [2, 2, 2], material_path: "res://materials/red.tres" } }`  
- **Expected result:** Success. Mesh is 2×2×2 with red material applied.  
- **Notes:** Validates properties passthrough.

#### 1.9: Missing required `parent` parameter
- **Description:** Omit the `parent` parameter entirely.  
- **Params:** `{ mesh_type: "cube" }`  
- **Expected result:** Error (Zod validation). `parent` is required.  
- **Notes:** Edge case — missing required param.

#### 1.10: Missing required `mesh_type` parameter
- **Description:** Omit the `mesh_type` parameter entirely.  
- **Params:** `{ parent: "" }`  
- **Expected result:** Error (Zod validation). `mesh_type` is required.  
- **Notes:** Edge case — missing required param.

#### 1.11: Invalid `mesh_type` value
- **Description:** Provide a mesh_type not in the enum.  
- **Params:** `{ parent: "", mesh_type: "pyramid" }`  
- **Expected result:** Error (Zod validation). `mesh_type` must be one of the 7 allowed values.  
- **Notes:** Edge case — invalid enum value.

#### 1.12: Empty string `parent` (valid)
- **Description:** Explicitly pass empty string for parent to target scene root.  
- **Params:** `{ parent: "", mesh_type: "sphere" }`  
- **Expected result:** Success. Mesh added at scene root.  
- **Notes:** Boundary — `""` is valid for ParentPath.

---

## Tool 2: `setup_camera_3d`

**Description:** Add and configure a Camera3D node.  
**Handler:** `callGodot(bridge, 'scene3d/setup_camera', args)`  
**Expected return:** Success/error JSON with camera configuration details.  

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `string` (NodePath) | No | `""` | Camera node path (leave empty to create a new Camera3D) |
| `properties` | `object` (Properties) | **Yes** | — | Camera properties (fov, near, far, position, look_at, make_current, etc.) |

### Test Scenarios

#### 2.1: Basic happy path — create a Camera3D with minimal properties
- **Description:** Create a new Camera3D at scene root with just a position.  
- **Params:** `{ path: "", properties: { position: [0, 0, 10] } }`  
- **Expected result:** Success. A new Camera3D is created at scene root, positioned at [0,0,10].  
- **Notes:** Uses default `path=""`.

#### 2.2: Create camera with path omitted (defaults to empty)
- **Description:** Omit `path` entirely; should default to `""` and create a new camera.  
- **Params:** `{ properties: { position: [5, 5, 5] } }`  
- **Expected result:** Success. New Camera3D created at scene root at [5,5,5].  
- **Notes:** Validates default value behavior for `path`.

#### 2.3: Configure an existing camera at a specific path
- **Description:** Configure an existing Camera3D at "Player/Camera3D".  
- **Params:** `{ path: "Player/Camera3D", properties: { fov: 90, near: 0.1, far: 1000 } }`  
- **Expected result:** Success. The existing camera's FOV is set to 90, near=0.1, far=1000.  
- **Notes:** Validates non-empty path targets an existing node.

#### 2.4: Set camera to current (make_current)
- **Description:** Create a camera and set it as the active camera.  
- **Params:** `{ path: "", properties: { position: [0, 5, 20], make_current: true } }`  
- **Expected result:** Success. Camera created, positioned, and set as current.  
- **Notes:** Validates `make_current` property.

#### 2.5: Configure camera with look_at target
- **Description:** Create a camera that looks at a specific point.  
- **Params:** `{ path: "", properties: { position: [0, 10, 20], look_at: [0, 0, 0] } }`  
- **Expected result:** Success. Camera at [0,10,20] looking at origin.  
- **Notes:** Validates `look_at` property.

#### 2.6: Full camera configuration
- **Description:** Configure all common camera properties at once.  
- **Params:** `{ path: "", properties: { position: [10, 8, 15], fov: 75, near: 0.05, far: 500, make_current: true, look_at: [0, 2, 0] } }`  
- **Expected result:** Success. All properties applied.  
- **Notes:** Validates multiple properties simultaneously.

#### 2.7: Missing required `properties` parameter
- **Description:** Omit the `properties` parameter entirely.  
- **Params:** `{ path: "" }`  
- **Expected result:** Error (Zod validation). `properties` is required.  
- **Notes:** Edge case — `Properties` is required, not optional.

#### 2.8: Empty `properties` object
- **Description:** Pass an empty properties object.  
- **Params:** `{ path: "", properties: {} }`  
- **Expected result:** Success or warning. A Camera3D is created with default values.  
- **Notes:** Boundary — empty properties object is technically valid.

#### 2.9: Path to non-existent node
- **Description:** Pass a path to a node that doesn't exist.  
- **Params:** `{ path: "NonExistent/Camera", properties: { fov: 60 } }`  
- **Expected result:** Error from Godot. Node not found.  
- **Notes:** Edge case — invalid path.

---

## Tool 3: `setup_lighting`

**Description:** Add a light node (DirectionalLight3D, OmniLight3D, SpotLight3D).  
**Handler:** `callGodot(bridge, 'scene3d/setup_lighting', args)`  
**Expected return:** Success/error JSON with light node details.  

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `parent` | `string` (ParentPath) | **Yes** | — | Parent node path. `""` = scene root. |
| `type` | `enum` | **Yes** | — | One of: `omni`, `spot`, `directional` |
| `properties` | `object` (OptionalProperties) | No | `undefined` | Light properties (color, energy, position, shadow_enabled, etc.) |

### Test Scenarios

#### 3.1: Basic happy path — add a directional light at root
- **Description:** Add a DirectionalLight3D at scene root with no properties.  
- **Params:** `{ parent: "", type: "directional" }`  
- **Expected result:** Success. A DirectionalLight3D node is created at scene root.  
- **Notes:** Simplest valid call.

#### 3.2: Add an omni light (enum variant)
- **Description:** Add an OmniLight3D as child of "Lights".  
- **Params:** `{ parent: "Lights", type: "omni" }`  
- **Expected result:** Success. OmniLight3D created under "Lights".  
- **Notes:** Covers `omni` enum value.

#### 3.3: Add a spot light (enum variant)
- **Description:** Add a SpotLight3D at scene root.  
- **Params:** `{ parent: "", type: "spot" }`  
- **Expected result:** Success. SpotLight3D created.  
- **Notes:** Covers `spot` enum value.

#### 3.4: Add directional light with properties
- **Description:** Add a DirectionalLight3D with color, energy, and shadow.  
- **Params:** `{ parent: "", type: "directional", properties: { color: [1, 0.8, 0.6], energy: 2.0, shadow_enabled: true } }`  
- **Expected result:** Success. Light with warm color, double energy, shadows enabled.  
- **Notes:** Validates properties passthrough.

#### 3.5: Add omni light with position
- **Description:** Add an OmniLight3D at a specific position.  
- **Params:** `{ parent: "", type: "omni", properties: { position: [0, 3, 0], color: [0.2, 0.2, 1], energy: 1.5 } }`  
- **Expected result:** Success. Blue omni light at [0,3,0] with 1.5 energy.  
- **Notes:** Validates position in properties.

#### 3.6: Add spot light with angle and attenuation
- **Description:** Add a SpotLight3D with custom spot properties.  
- **Params:** `{ parent: "", type: "spot", properties: { position: [0, 10, 0], spot_angle: 45, spot_attenuation: 2 } }`  
- **Expected result:** Success. Spotlight 10 units up, 45° cone, attenuation 2.  
- **Notes:** Validates spot-specific properties.

#### 3.7: Missing required `parent` parameter
- **Description:** Omit `parent`.  
- **Params:** `{ type: "directional" }`  
- **Expected result:** Error (Zod validation). `parent` is required.  
- **Notes:** Edge case — missing required param.

#### 3.8: Missing required `type` parameter
- **Description:** Omit `type`.  
- **Params:** `{ parent: "" }`  
- **Expected result:** Error (Zod validation). `type` is required.  
- **Notes:** Edge case — missing required param.

#### 3.9: Invalid `type` value
- **Description:** Pass a type not in the enum.  
- **Params:** `{ parent: "", type: "area" }`  
- **Expected result:** Error (Zod validation). `type` must be one of `omni`, `spot`, `directional`.  
- **Notes:** Edge case — invalid enum value.

#### 3.10: Empty `properties` object
- **Description:** Pass an empty properties object.  
- **Params:** `{ parent: "", type: "directional", properties: {} }`  
- **Expected result:** Success. Light created with default values.  
- **Notes:** Boundary — properties is optional, empty object should work.

---

## Tool 4: `setup_environment`

**Description:** Configure the WorldEnvironment for the 3D scene.  
**Handler:** `callGodot(bridge, 'scene3d/setup_environment', args)`  
**Expected return:** Success/error JSON with environment configuration details.  

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `string` (NodePath) | **Yes** | — | WorldEnvironment node path |
| `properties` | `object` (Properties) | **Yes** | — | Environment properties (background_mode, background_color, ambient_light_color, fog_enabled, glow_enabled, etc.) |

### Test Scenarios

#### 4.1: Basic happy path — configure background color
- **Description:** Set background color on an existing WorldEnvironment node.  
- **Params:** `{ path: "WorldEnvironment", properties: { background_color: [0.1, 0.1, 0.3] } }`  
- **Expected result:** Success. Background color updated to dark blue.  
- **Notes:** Simplest valid call assuming a WorldEnvironment node exists.

#### 4.2: Configure ambient light
- **Description:** Set ambient light color and energy.  
- **Params:** `{ path: "WorldEnvironment", properties: { ambient_light_color: [0.5, 0.5, 0.5], ambient_light_energy: 0.8 } }`  
- **Expected result:** Success. Ambient light set to gray, 0.8 energy.  
- **Notes:** Validates ambient light properties.

#### 4.3: Enable fog
- **Description:** Enable fog with density.  
- **Params:** `{ path: "WorldEnvironment", properties: { fog_enabled: true, fog_density: 0.02, fog_color: [0.8, 0.8, 0.9] } }`  
- **Expected result:** Success. Fog enabled with light blue-gray color.  
- **Notes:** Validates fog properties.

#### 4.4: Enable glow
- **Description:** Enable glow post-processing effect.  
- **Params:** `{ path: "WorldEnvironment", properties: { glow_enabled: true, glow_intensity: 0.5, glow_bloom: 0.3 } }`  
- **Expected result:** Success. Glow enabled with moderate intensity.  
- **Notes:** Validates glow properties.

#### 4.5: Set background mode to sky
- **Description:** Change background mode (e.g., to use a Sky resource).  
- **Params:** `{ path: "WorldEnvironment", properties: { background_mode: "sky" } }`  
- **Expected result:** Success. Background mode changed.  
- **Notes:** Validates `background_mode` property.

#### 4.6: Full environment configuration
- **Description:** Configure all common environment properties at once.  
- **Params:** `{ path: "WorldEnvironment", properties: { background_mode: "color", background_color: [0.05, 0.05, 0.15], ambient_light_color: [0.3, 0.3, 0.4], ambient_light_energy: 0.6, fog_enabled: true, fog_density: 0.01, fog_color: [0.6, 0.6, 0.7], glow_enabled: true, glow_intensity: 0.4 } }`  
- **Expected result:** Success. All environment settings applied.  
- **Notes:** Validates multiple properties simultaneously.

#### 4.7: Missing required `path` parameter
- **Description:** Omit `path`.  
- **Params:** `{ properties: { background_color: [0, 0, 0] } }`  
- **Expected result:** Error (Zod validation). `path` is required.  
- **Notes:** Edge case — missing required param.

#### 4.8: Missing required `properties` parameter
- **Description:** Omit `properties`.  
- **Params:** `{ path: "WorldEnvironment" }`  
- **Expected result:** Error (Zod validation). `properties` is required.  
- **Notes:** Edge case — missing required param.

#### 4.9: Empty `properties` object
- **Description:** Pass empty properties.  
- **Params:** `{ path: "WorldEnvironment", properties: {} }`  
- **Expected result:** Success (no-op) or warning. No changes applied, may succeed silently or warn.  
- **Notes:** Boundary — empty properties object is technically valid but may be a no-op.

#### 4.10: Path to non-existent WorldEnvironment node
- **Description:** Pass a path to a node that doesn't exist.  
- **Params:** `{ path: "MissingNode", properties: { background_color: [0.5, 0, 0] } }`  
- **Expected result:** Error from Godot. WorldEnvironment node not found.  
- **Notes:** Edge case — invalid path.

---

## Tool 5: `add_gridmap`

**Description:** Add a GridMap node for 3D tile-based level design.  
**Handler:** `callGodot(bridge, 'scene3d/add_gridmap', args)`  
**Expected return:** Success/error JSON with GridMap node details.  

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `parent` | `string` (ParentPath) | **Yes** | — | Parent node path. `""` = scene root. |
| `properties` | `object` (OptionalProperties) | No | `undefined` | GridMap properties (mesh_library_path, cell_size, etc.) |

### Test Scenarios

#### 5.1: Basic happy path — add GridMap at scene root
- **Description:** Add a GridMap at scene root with no properties.  
- **Params:** `{ parent: "" }`  
- **Expected result:** Success. A GridMap node is created at scene root with default settings.  
- **Notes:** Simplest valid call.

#### 5.2: Add GridMap as child of an existing node
- **Description:** Add a GridMap under "Level/Floor1".  
- **Params:** `{ parent: "Level/Floor1" }`  
- **Expected result:** Success. GridMap created as child of "Level/Floor1".  
- **Notes:** Validates nested parent path.

#### 5.3: Add GridMap with mesh_library_path
- **Description:** Add a GridMap with a MeshLibrary resource assigned.  
- **Params:** `{ parent: "", properties: { mesh_library_path: "res://assets/mesh_library.tres" } }`  
- **Expected result:** Success. GridMap created with MeshLibrary assigned.  
- **Notes:** Validates mesh_library_path property.

#### 5.4: Add GridMap with custom cell_size
- **Description:** Add a GridMap with a non-default cell size.  
- **Params:** `{ parent: "", properties: { cell_size: [2, 2, 2] } }`  
- **Expected result:** Success. GridMap with 2×2×2 cell size.  
- **Notes:** Validates cell_size property.

#### 5.5: Add GridMap with multiple properties
- **Description:** Add a GridMap with both mesh library and cell size.  
- **Params:** `{ parent: "", properties: { mesh_library_path: "res://assets/tiles.tres", cell_size: [4, 4, 4], cell_center_x: true, cell_center_y: true, cell_center_z: true, cell_octant_size: 8 } }`  
- **Expected result:** Success. GridMap fully configured.  
- **Notes:** Validates multiple properties simultaneously.

#### 5.6: Missing required `parent` parameter
- **Description:** Omit `parent`.  
- **Params:** `{ properties: { cell_size: [1, 1, 1] } }`  
- **Expected result:** Error (Zod validation). `parent` is required.  
- **Notes:** Edge case — missing required param.

#### 5.7: Empty `properties` object
- **Description:** Pass empty properties with valid parent.  
- **Params:** `{ parent: "", properties: {} }`  
- **Expected result:** Success. GridMap created with defaults.  
- **Notes:** Boundary — empty optional properties should work.

#### 5.8: GridMap with non-existent mesh library path
- **Description:** Reference a mesh library that doesn't exist.  
- **Params:** `{ parent: "", properties: { mesh_library_path: "res://nonexistent/lib.tres" } }`  
- **Expected result:** Likely success for node creation, but Godot may warn about missing resource at runtime.  
- **Notes:** Edge case — invalid resource path may not fail at creation time.

---

## Tool 6: `set_material_3d`

**Description:** Create and apply a StandardMaterial3D or ShaderMaterial to a mesh.  
**Handler:** `callGodot(bridge, 'scene3d/set_material', args)`  
**Expected return:** Success/error JSON with material application details.  

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `string` (NodePath) | **Yes** | — | MeshInstance3D node path |
| `properties` | `object` (Properties) | **Yes** | — | Material properties (albedo_color, metallic, roughness, shader_path, etc.) |

### Test Scenarios

#### 6.1: Basic happy path — set albedo color on a mesh
- **Description:** Set the albedo_color property on an existing MeshInstance3D.  
- **Params:** `{ path: "MeshInstance3D", properties: { albedo_color: [1, 0, 0] } }`  
- **Expected result:** Success. A StandardMaterial3D is created/updated with red albedo.  
- **Notes:** Simplest valid call. Creates a StandardMaterial3D by default.

#### 6.2: Set metallic and roughness
- **Description:** Configure PBR properties on a mesh.  
- **Params:** `{ path: "Player/Model", properties: { metallic: 0.8, roughness: 0.2 } }`  
- **Expected result:** Success. Material updated with high metallic, low roughness (reflective metal).  
- **Notes:** Validates PBR properties.

#### 6.3: Apply a ShaderMaterial via shader_path
- **Description:** Apply a ShaderMaterial using a shader file path.  
- **Params:** `{ path: "MeshInstance3D", properties: { shader_path: "res://shaders/toon.gdshader", albedo_color: [0.2, 0.6, 1] } }`  
- **Expected result:** Success. ShaderMaterial created from toon.gdshader and applied.  
- **Notes:** Validates shader_path triggers ShaderMaterial creation.

#### 6.4: Set material on a nested mesh path
- **Description:** Target a mesh at a deeper path.  
- **Params:** `{ path: "Level/Props/Crate/Cube", properties: { albedo_color: [0.6, 0.4, 0.2], roughness: 0.9 } }`  
- **Expected result:** Success. Material applied to the deeply nested mesh.  
- **Notes:** Validates deeply nested node paths.

#### 6.5: Full StandardMaterial3D configuration
- **Description:** Configure all common StandardMaterial3D properties.  
- **Params:** `{ path: "MeshInstance3D", properties: { albedo_color: [0.1, 0.5, 0.1], metallic: 0.3, roughness: 0.7, emission: [0, 0.3, 0], emission_energy: 0.5, transparency: 1 } }`  
- **Expected result:** Success. All StandardMaterial3D properties applied.  
- **Notes:** Validates multiple properties simultaneously.

#### 6.6: Missing required `path` parameter
- **Description:** Omit `path`.  
- **Params:** `{ properties: { albedo_color: [1, 1, 1] } }`  
- **Expected result:** Error (Zod validation). `path` is required.  
- **Notes:** Edge case — missing required param.

#### 6.7: Missing required `properties` parameter
- **Description:** Omit `properties`.  
- **Params:** `{ path: "MeshInstance3D" }`  
- **Expected result:** Error (Zod validation). `properties` is required.  
- **Notes:** Edge case — missing required param.

#### 6.8: Empty `properties` object
- **Description:** Pass empty properties.  
- **Params:** `{ path: "MeshInstance3D", properties: {} }`  
- **Expected result:** Success (no-op) or warning. No material change applied.  
- **Notes:** Boundary — empty properties is technically valid but may do nothing.

#### 6.9: Path to a non-MeshInstance3D node
- **Description:** Target a node that isn't a MeshInstance3D.  
- **Params:** `{ path: "Camera3D", properties: { albedo_color: [1, 0, 0] } }`  
- **Expected result:** Error from Godot. Node is not a MeshInstance3D.  
- **Notes:** Edge case — wrong node type.

#### 6.10: Path to non-existent node
- **Description:** Pass a path to a node that doesn't exist.  
- **Params:** `{ path: "NonExistentMesh", properties: { albedo_color: [0, 0, 1] } }`  
- **Expected result:** Error from Godot. Node not found.  
- **Notes:** Edge case — invalid path.

---

## Cross-Tool Considerations

### Prerequisites for Testing
- A Godot 3D scene must be open in the editor. Create a minimal scene (e.g., `Node3D` root) at `res://test_scenes/scene3d_test.tscn`.
- For `setup_environment`: a `WorldEnvironment` node must already exist in the scene.
- For `set_material_3d`: a `MeshInstance3D` node must already exist in the scene.
- For child-parent tests: the parent node must exist before adding children.

### Recommended Test Order
1. Open/create a 3D scene (via `open_scene` or `create_scene`)
2. Add a WorldEnvironment node (via `add_node`)
3. Add a MeshInstance3D (via `add_mesh_instance`)
4. Run all `add_mesh_instance` tests
5. Run all `setup_camera_3d` tests
6. Run all `setup_lighting` tests
7. Run all `setup_environment` tests
8. Run all `add_gridmap` tests
9. Run all `set_material_3d` tests

### Edge Case: Scene Not Open
All tools will fail if no 3D scene is currently open in the editor. Test that the error message clearly indicates this.

### Edge Case: 2D Scene Active
If a 2D scene is open (Node2D root), 3D tools may fail or produce unexpected results. Verify proper error handling.
