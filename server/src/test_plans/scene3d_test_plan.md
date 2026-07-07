# Scene3D Tools — Comprehensive Test Plan

**Source file:** `server/src/tools/scene3d.ts`  
**Number of tools:** 6  
**Generated:** 2026-07-08  

---

## Shared Type Reference

All tools import parameter schemas from `server/src/tools/shared-types.ts`:

| Schema | Zod Definition | Description |
|--------|---------------|-------------|
| `ParentPath` | `z.string()` | Parent node path. `''` = scene root. Node name/path (e.g. `'Player'` or `'Player/Sprites'`) to add as child. |
| `NodePath` | `z.string()` | Node path in scene tree (e.g. `'Player/Sprite2D'`). Just node name for root children, `''` for scene root. |
| `Properties` | `z.record(z.unknown())` | Required property key-value pairs dictionary. |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | Optional property key-value pairs dictionary. |

---

## Tool 1: `add_mesh_instance`

### Overview

| Field | Value |
|-------|-------|
| **Tool name** | `add_mesh_instance` |
| **Description** | Add a MeshInstance3D with a primitive mesh type |
| **Handler** | `scene3d/add_mesh` |

### Parameters

| # | Parameter | Type | Required | Default | Enum Values | Description |
|---|-----------|------|----------|---------|-------------|-------------|
| 1 | `parent` | `string` (ParentPath) | **Yes** | — | — | Parent node path. `''` for scene root, or node name/path (e.g. `'Player'` or `'Player/Sprites'`) to add as a child of that node. |
| 2 | `mesh_type` | `enum` (string) | **Yes** | — | `cube`, `sphere`, `cylinder`, `capsule`, `plane`, `prism`, `torus` | Primitive mesh type. |
| 3 | `properties` | `record` (object) | No | `undefined` | — | Mesh properties (size, material_path, etc.). |

### Behavior

Creates a new `MeshInstance3D` node as a child of the specified `parent`, configured with a primitive mesh of type `mesh_type`. Optional `properties` can set mesh-specific attributes like size or a material path.

### Test Scenarios

#### 1.1 — Happy Path: Add a cube at scene root (minimal params)
- **Description:** Add a cube MeshInstance3D as a direct child of the scene root with only required parameters.
- **JSON params:** `{"parent": "", "mesh_type": "cube"}`
- **Expected result:** A MeshInstance3D node with a BoxMesh primitive is created at the scene root. Default node name auto-generated.
- **Notes:** Simplest valid call.

#### 1.2 — Add cube with a named parent
- **Description:** Add a cube under a specific parent node by name.
- **JSON params:** `{"parent": "LevelGeometry", "mesh_type": "cube"}`
- **Expected result:** A MeshInstance3D node with a BoxMesh is created as a child of the `LevelGeometry` node.
- **Notes:** Verify parent resolution works with a node name.

#### 1.3 — Add cube under a nested parent path
- **Description:** Add a cube under a nested parent node path.
- **JSON params:** `{"parent": "Player/Weapons", "mesh_type": "cube"}`
- **Expected result:** A MeshInstance3D is created as a child of `Player/Weapons`.
- **Notes:** Verifies `/` path separator resolution.

#### 1.4 — Add sphere at scene root
- **Description:** Add a sphere mesh.
- **JSON params:** `{"parent": "", "mesh_type": "sphere"}`
- **Expected result:** MeshInstance3D with SphereMesh primitive created at root.
- **Notes:** Enum value: `sphere`.

#### 1.5 — Add cylinder at scene root
- **Description:** Add a cylinder mesh.
- **JSON params:** `{"parent": "", "mesh_type": "cylinder"}`
- **Expected result:** MeshInstance3D with CylinderMesh primitive created at root.
- **Notes:** Enum value: `cylinder`.

#### 1.6 — Add capsule at scene root
- **Description:** Add a capsule mesh.
- **JSON params:** `{"parent": "", "mesh_type": "capsule"}`
- **Expected result:** MeshInstance3D with CapsuleMesh primitive created at root.
- **Notes:** Enum value: `capsule`.

#### 1.7 — Add plane at scene root
- **Description:** Add a plane mesh.
- **JSON params:** `{"parent": "", "mesh_type": "plane"}`
- **Expected result:** MeshInstance3D with PlaneMesh primitive created at root.
- **Notes:** Enum value: `plane`.

#### 1.8 — Add prism at scene root
- **Description:** Add a prism mesh.
- **JSON params:** `{"parent": "", "mesh_type": "prism"}`
- **Expected result:** MeshInstance3D with PrismMesh primitive created at root.
- **Notes:** Enum value: `prism`.

#### 1.9 — Add torus at scene root
- **Description:** Add a torus mesh.
- **JSON params:** `{"parent": "", "mesh_type": "torus"}`
- **Expected result:** MeshInstance3D with TorusMesh primitive created at root.
- **Notes:** Enum value: `torus`.

#### 1.10 — Add mesh with custom size
- **Description:** Add a cube with explicit size via properties.
- **JSON params:** `{"parent": "", "mesh_type": "cube", "properties": {"size": [2, 2, 2]}}`
- **Expected result:** Cube with `size = Vector3(2, 2, 2)` is created.
- **Notes:** Verifies properties pass-through.

#### 1.11 — Add mesh with material_path
- **Description:** Add a sphere with a material from path.
- **JSON params:** `{"parent": "", "mesh_type": "sphere", "properties": {"material_path": "res://materials/ball.tres"}}`
- **Expected result:** Sphere created with the specified material applied.
- **Notes:** Verifies resource path resolution in properties.

#### 1.12 — Missing required `parent` (edge case)
- **Description:** Omit the required `parent` parameter.
- **JSON params:** `{"mesh_type": "cube"}`
- **Expected result:** Validation error. Tool call fails with a schema validation message.
- **Notes:** `parent` has no default; should be rejected by Zod.

#### 1.13 — Missing required `mesh_type` (edge case)
- **Description:** Omit the required `mesh_type` parameter.
- **JSON params:** `{"parent": ""}`
- **Expected result:** Validation error. Tool call fails with a schema validation message.
- **Notes:** `mesh_type` is required and has no default.

#### 1.14 — Invalid mesh_type value (edge case)
- **Description:** Use a mesh_type not in the enum.
- **JSON params:** `{"parent": "", "mesh_type": "pyramid"}`
- **Expected result:** Validation error. `'pyramid'` is not a valid enum value.
- **Notes:** Zod enum strict check.

#### 1.15 — Invalid mesh_type: empty string (edge case)
- **Description:** Use an empty string for mesh_type.
- **JSON params:** `{"parent": "", "mesh_type": ""}`
- **Expected result:** Validation error. Empty string is not in the enum.
- **Notes:** Zod enum rejects empty strings.

#### 1.16 — Invalid mesh_type: wrong case (edge case)
- **Description:** Use `"Cube"` (capital C) instead of `"cube"`.
- **JSON params:** `{"parent": "", "mesh_type": "Cube"}`
- **Expected result:** Validation error. Enum is case-sensitive.
- **Notes:** All enum values are lowercase.

#### 1.17 — Additional unknown properties (edge case)
- **Description:** Include an unexpected extra parameter.
- **JSON params:** `{"parent": "", "mesh_type": "cube", "name": "MyCube"}`
- **Expected result:** May be ignored (extra properties stripped by Zod strict or passthrough) or forwarded to handler. Depends on server config.
- **Notes:** The schema uses `inputSchema` without `passthrough()`, so extra params should be stripped.

#### 1.18 — Properties with empty object
- **Description:** Pass an empty properties object.
- **JSON params:** `{"parent": "", "mesh_type": "cube", "properties": {}}`
- **Expected result:** Cube created with default mesh properties. No error.
- **Notes:** Optional `properties` with empty record should be a no-op.

#### 1.19 — Properties with unexpected keys
- **Description:** Pass properties with keys that MeshInstance3D does not recognize.
- **JSON params:** `{"parent": "", "mesh_type": "cube", "properties": {"fictional_prop": 42}}`
- **Expected result:** May be silently ignored by Godot or produce a warning. Should not crash.
- **Notes:** Godot typically ignores unknown properties silently.

#### 1.20 — Null parent (edge case)
- **Description:** Pass `null` as parent.
- **JSON params:** `{"parent": null, "mesh_type": "cube"}`
- **Expected result:** Validation error. `null` is not a valid string.
- **Notes:** Zod `z.string()` rejects `null`.

---

## Tool 2: `setup_camera_3d`

### Overview

| Field | Value |
|-------|-------|
| **Tool name** | `setup_camera_3d` |
| **Description** | Add and configure a Camera3D node |
| **Handler** | `scene3d/setup_camera` |

### Parameters

| # | Parameter | Type | Required | Default | Enum Values | Description |
|---|-----------|------|----------|---------|-------------|-------------|
| 1 | `path` | `string` (NodePath) | No | `''` | — | Camera node path (leave empty to create a new Camera3D). |
| 2 | `properties` | `record` (object) | **Yes** | — | — | Camera properties (fov, near, far, position, look_at, make_current, etc.). |

### Behavior

Creates or configures a `Camera3D` node. If `path` is empty (default), a new `Camera3D` node is created. If `path` points to an existing `Camera3D`, it is configured with the provided `properties`. Properties must always be provided.

### Test Scenarios

#### 2.1 — Happy Path: Create new camera with minimal properties (minimal params)
- **Description:** Create a new Camera3D at scene root with only a position.
- **JSON params:** `{"properties": {"position": [0, 0, 10]}}`
- **Expected result:** A new Camera3D node is created at scene root with position `(0, 0, 10)`. Default `path` of `''` is used.
- **Notes:** `path` omitted; defaults to `''`, meaning "create new". Properties required but only position provided.

#### 2.2 — Create camera with explicit empty path
- **Description:** Create a new Camera3D with explicit empty path string.
- **JSON params:** `{"path": "", "properties": {"position": [0, 5, 15]}}`
- **Expected result:** New Camera3D created at root with position `(0, 5, 15)`.
- **Notes:** Same as default; explicit empty string.

#### 2.3 — Configure an existing camera by path
- **Description:** Update an existing camera node's properties.
- **JSON params:** `{"path": "MainCamera", "properties": {"fov": 90, "near": 0.1, "far": 1000}}`
- **Expected result:** The existing `MainCamera` node's FOV set to 90°, near clip to 0.1, far clip to 1000.
- **Notes:** Verifies configuring an existing camera (not creating new one). Requires `MainCamera` node to exist.

#### 2.4 — Configure existing camera with nested path
- **Description:** Update camera under a nested path.
- **JSON params:** `{"path": "Player/Head/Camera3D", "properties": {"fov": 60}}`
- **Expected result:** Camera under `Player/Head/Camera3D` updated with FOV 60.
- **Notes:** Verifies nested path resolution.

#### 2.5 — Set all common camera properties
- **Description:** Configure a camera with fov, near, far, position, and make_current.
- **JSON params:** `{"path": "", "properties": {"fov": 75, "near": 0.05, "far": 500, "position": [0, 2, 20], "make_current": true}}`
- **Expected result:** Camera created with all specified properties. `make_current: true` means it becomes the active camera.
- **Notes:** Verifies multiple properties in one call.

#### 2.6 — Set look_at property (target position)
- **Description:** Create a camera looking at a specific target.
- **JSON params:** `{"path": "", "properties": {"position": [10, 5, 10], "look_at": [0, 0, 0]}}`
- **Expected result:** Camera positioned at `(10, 5, 10)` and rotated to look at origin.
- **Notes:** `look_at` is a non-standard Godot property (handled by the plugin layer, not native Camera3D property).

#### 2.7 — Create camera with only fov
- **Description:** Create camera setting only the FOV.
- **JSON params:** `{"path": "", "properties": {"fov": 120}}`
- **Expected result:** Camera at origin with FOV 120°.
- **Notes:** Minimal properties case; all other settings default.

#### 2.8 — Create camera with extreme FOV values
- **Description:** Test extreme FOV values.
- **JSON params:** `{"path": "", "properties": {"fov": 1}}`
- **JSON params (second variant):** `{"path": "", "properties": {"fov": 179}}`
- **Expected result:** Camera created with FOV 1° (tunnel vision). Camera created with FOV 179° (fisheye). Both should succeed.
- **Notes:** Godot allows FOV 1-179. No explicit validation in the MCP layer.

#### 2.9 — Missing required `properties` (edge case)
- **Description:** Omit the required `properties` parameter.
- **JSON params:** `{"path": ""}`
- **Expected result:** Validation error. `properties` is required (uses `Properties`, not `OptionalProperties`).
- **Notes:** Schema-level rejection.

#### 2.10 — Properties with empty object
- **Description:** Pass empty properties to a new camera.
- **JSON params:** `{"path": "", "properties": {}}`
- **Expected result:** Camera created with all default properties at scene root.
- **Notes:** Empty `properties` still passes validation since `z.record(z.unknown())` accepts `{}`.

#### 2.11 — Invalid path type (edge case)
- **Description:** Pass a number as path.
- **JSON params:** `{"path": 123, "properties": {"fov": 60}}`
- **Expected result:** Validation error. `path` must be a string.
- **Notes:** Zod string validation.

#### 2.12 — Null properties (edge case)
- **Description:** Pass `null` as properties.
- **JSON params:** `{"path": "", "properties": null}`
- **Expected result:** Validation error. `null` is not a valid record.
- **Notes:** Zod `z.record()` rejects `null`.

---

## Tool 3: `setup_lighting`

### Overview

| Field | Value |
|-------|-------|
| **Tool name** | `setup_lighting` |
| **Description** | Add a light node (DirectionalLight3D, OmniLight3D, SpotLight3D) |
| **Handler** | `scene3d/setup_lighting` |

### Parameters

| # | Parameter | Type | Required | Default | Enum Values | Description |
|---|-----------|------|----------|---------|-------------|-------------|
| 1 | `parent` | `string` (ParentPath) | **Yes** | — | — | Parent node path. `''` for scene root, or node name/path to add as a child. |
| 2 | `type` | `enum` (string) | **Yes** | — | `omni`, `spot`, `directional` | Light type. |
| 3 | `properties` | `record` (object) | No | `undefined` | — | Light properties (color, energy, position, shadow_enabled, etc.). |

### Behavior

Adds a light node of the specified type as a child of `parent`. The `type` maps to Godot classes: `directional` → `DirectionalLight3D`, `omni` → `OmniLight3D`, `spot` → `SpotLight3D`.

### Test Scenarios

#### 3.1 — Happy Path: Directional light at root (minimal params)
- **Description:** Add a directional light at the scene root with only required parameters.
- **JSON params:** `{"parent": "", "type": "directional"}`
- **Expected result:** A DirectionalLight3D node is created at scene root with default properties.
- **Notes:** Simplest valid call.

#### 3.2 — Add omni light at root
- **Description:** Add an omni (point) light at root.
- **JSON params:** `{"parent": "", "type": "omni"}`
- **Expected result:** An OmniLight3D node is created at root.
- **Notes:** Enum value: `omni`.

#### 3.3 — Add spot light at root
- **Description:** Add a spotlight at root.
- **JSON params:** `{"parent": "", "type": "spot"}`
- **Expected result:** A SpotLight3D node is created at root.
- **Notes:** Enum value: `spot`.

#### 3.4 — Directional light under named parent
- **Description:** Add a directional light as a child of a specific node.
- **JSON params:** `{"parent": "SunHolder", "type": "directional"}`
- **Expected result:** DirectionalLight3D created under `SunHolder`.
- **Notes:** Verifies parent resolution with node name.

#### 3.5 — Directional light under nested parent
- **Description:** Add a light under a deeply nested parent path.
- **JSON params:** `{"parent": "Level/Lighting/Primary", "type": "directional"}`
- **Expected result:** DirectionalLight3D created under `Level/Lighting/Primary`.
- **Notes:** Verifies nested path resolution.

#### 3.6 — Omni light with custom color and energy
- **Description:** Add an omni light with a red color and high energy.
- **JSON params:** `{"parent": "", "type": "omni", "properties": {"color": [1, 0.2, 0.2], "energy": 5}}`
- **Expected result:** OmniLight3D with red tint and energy 5.
- **Notes:** Color as `[r, g, b]` array. May also accept `"#FF3333"` string depending on handler.

#### 3.7 — Spot light with position and shadow enabled
- **Description:** Add a spotlight at a specific position with shadows.
- **JSON params:** `{"parent": "", "type": "spot", "properties": {"position": [5, 10, 0], "shadow_enabled": true}}`
- **Expected result:** SpotLight3D at `(5, 10, 0)` with shadows enabled.
- **Notes:** Verifies position and shadow_enabled properties.

#### 3.8 — Directional light with shadow and rotation
- **Description:** Add a directional light with shadows and a specific rotation.
- **JSON params:** `{"parent": "", "type": "directional", "properties": {"shadow_enabled": true, "rotation": [-0.5, -0.3, 0]}}`
- **Expected result:** DirectionalLight3D with shadows and rotated to face a specific direction.
- **Notes:** Directional lights use rotation for direction.

#### 3.9 — Properties with empty object
- **Description:** Pass empty properties with a spot light.
- **JSON params:** `{"parent": "", "type": "spot", "properties": {}}`
- **Expected result:** SpotLight3D created with default properties.
- **Notes:** Optional properties; empty record is a no-op.

#### 3.10 — Missing required `parent` (edge case)
- **Description:** Omit the required `parent` parameter.
- **JSON params:** `{"type": "directional"}`
- **Expected result:** Validation error. `parent` is required.
- **Notes:** Schema-level rejection.

#### 3.11 — Missing required `type` (edge case)
- **Description:** Omit the required `type` parameter.
- **JSON params:** `{"parent": ""}`
- **Expected result:** Validation error. `type` is required.
- **Notes:** Schema-level rejection.

#### 3.12 — Invalid type: unrecognized value (edge case)
- **Description:** Use a light type not in the enum.
- **JSON params:** `{"parent": "", "type": "area"}`
- **Expected result:** Validation error. `'area'` is not a valid enum value.
- **Notes:** Zod enum strict check.

#### 3.13 — Invalid type: mixed case (edge case)
- **Description:** Use `"Spot"` (capitalized) instead of `"spot"`.
- **JSON params:** `{"parent": "", "type": "Spot"}`
- **Expected result:** Validation error. Enum is case-sensitive.
- **Notes:** All values are lowercase.

#### 3.14 — Invalid type: empty string (edge case)
- **Description:** Use empty string for type.
- **JSON params:** `{"parent": "", "type": ""}`
- **Expected result:** Validation error. Empty string is not in the enum.
- **Notes:** Zod enum rejects empty string.

#### 3.15 — Null parent (edge case)
- **Description:** Pass `null` as parent.
- **JSON params:** `{"parent": null, "type": "directional"}`
- **Expected result:** Validation error. Zod string rejects null.
- **Notes:** Type mismatch.

#### 3.16 — Light with color as hex string
- **Description:** Set light color using a hex string (if handler supports it).
- **JSON params:** `{"parent": "", "type": "omni", "properties": {"color": "#FF6600"}}`
- **Expected result:** OmniLight3D with orange color if the handler supports string-to-Color conversion.
- **Notes:** Depends on handler implementation; may expect `[r,g,b]` array.

---

## Tool 4: `setup_environment`

### Overview

| Field | Value |
|-------|-------|
| **Tool name** | `setup_environment` |
| **Description** | Configure the WorldEnvironment for the 3D scene |
| **Handler** | `scene3d/setup_environment` |

### Parameters

| # | Parameter | Type | Required | Default | Enum Values | Description |
|---|-----------|------|----------|---------|-------------|-------------|
| 1 | `path` | `string` (NodePath) | **Yes** | — | — | WorldEnvironment node path. |
| 2 | `properties` | `record` (object) | **Yes** | — | — | Environment properties (background_mode, background_color, ambient_light_color, fog_enabled, glow_enabled, etc.). |

### Behavior

Configures the environment of a `WorldEnvironment` node at the given `path`. If the node does not exist, the handler may create it. Applies all `properties` to the node's `Environment` resource.

### Test Scenarios

#### 4.1 — Happy Path: Set background color (minimal params)
- **Description:** Configure a WorldEnvironment node with a background color.
- **JSON params:** `{"path": "WorldEnvironment", "properties": {"background_color": [0.1, 0.2, 0.3]}}`
- **Expected result:** The `WorldEnvironment` node's environment background color is set to `(0.1, 0.2, 0.3)`.
- **Notes:** Simplest valid call. Assumes a `WorldEnvironment` node exists.

#### 4.2 — Configure root-level WorldEnvironment
- **Description:** Use empty string path to configure the root WorldEnvironment.
- **JSON params:** `{"path": "", "properties": {"background_mode": 1}}`
- **Expected result:** If a root-level WorldEnvironment node exists, background mode is changed.
- **Notes:** `path: ""` means "scene root" which may also be the WorldEnvironment itself if the scene root is WorldEnvironment.

#### 4.3 — Configure nested WorldEnvironment path
- **Description:** Configure a WorldEnvironment under a parent node.
- **JSON params:** `{"path": "Env/WorldEnvironment", "properties": {"glow_enabled": true}}`
- **Expected result:** WorldEnvironment under `Env/` has glow enabled.
- **Notes:** Nested path resolution.

#### 4.4 — Set ambient light color
- **Description:** Configure ambient light color.
- **JSON params:** `{"path": "WorldEnvironment", "properties": {"ambient_light_color": [1, 0.9, 0.8]}}`
- **Expected result:** Ambient light becomes warm white.
- **Notes:** Ambient light affects all unlit surfaces.

#### 4.5 — Enable fog with properties
- **Description:** Enable fog and configure fog parameters.
- **JSON params:** `{"path": "WorldEnvironment", "properties": {"fog_enabled": true, "fog_color": [0.5, 0.5, 0.5], "fog_density": 0.01}}`
- **Expected result:** Fog is enabled with gray color and density 0.01.
- **Notes:** Fog properties cascade to the Environment resource.

#### 4.6 — Enable glow
- **Description:** Enable glow (bloom) post-processing effect.
- **JSON params:** `{"path": "WorldEnvironment", "properties": {"glow_enabled": true}}`
- **Expected result:** Glow post-processing is enabled.
- **Notes:** Glow creates bloom around bright pixels.

#### 4.7 — Set background mode to sky
- **Description:** Change background mode to use a sky material.
- **JSON params:** `{"path": "WorldEnvironment", "properties": {"background_mode": 2}}`
- **Expected result:** Background mode set to sky (mode 2 in Godot: `Environment.BG_SKY`).
- **Notes:** Background mode is an enum int: 0=Clear Color, 1=Color, 2=Sky, 3=Canvas, 4=Keep, 5=CameraFeed.

#### 4.8 — Set multiple environment properties at once
- **Description:** Configure background, ambient, fog, and glow in one call.
- **JSON params:** `{"path": "WorldEnvironment", "properties": {"background_mode": 0, "background_color": [0, 0, 0], "ambient_light_color": [0.3, 0.3, 0.4], "fog_enabled": false, "glow_enabled": true}}`
- **Expected result:** All properties applied simultaneously.
- **Notes:** Tests batch property setting.

#### 4.9 — Missing required `path` (edge case)
- **Description:** Omit the required `path` parameter.
- **JSON params:** `{"properties": {"glow_enabled": true}}`
- **Expected result:** Validation error. `path` is required (uses `NodePath` without optional/default).
- **Notes:** Schema-level rejection.

#### 4.10 — Missing required `properties` (edge case)
- **Description:** Omit the required `properties` parameter.
- **JSON params:** `{"path": "WorldEnvironment"}`
- **Expected result:** Validation error. `properties` is required (uses `Properties`, not `OptionalProperties`).
- **Notes:** Schema-level rejection.

#### 4.11 — Properties with empty object
- **Description:** Pass empty properties.
- **JSON params:** `{"path": "WorldEnvironment", "properties": {}}`
- **Expected result:** No error (empty record passes Zod). No properties changed.
- **Notes:** Technically valid but semantically empty.

#### 4.12 — Non-existent WorldEnvironment path (edge case)
- **Description:** Configure a WorldEnvironment node that does not exist.
- **JSON params:** `{"path": "NonExistent_Env", "properties": {"glow_enabled": true}}`
- **Expected result:** Error from Godot handler. Either creates the node and configures it, or returns an error about missing node.
- **Notes:** Handler behavior determines outcome. Test both creation vs. error scenarios if possible.

#### 4.13 — Invalid path type (edge case)
- **Description:** Pass an object as path.
- **JSON params:** `{"path": {"node": "WorldEnvironment"}, "properties": {"glow_enabled": true}}`
- **Expected result:** Validation error. Path must be a string.
- **Notes:** Type mismatch.

#### 4.14 — Background color out of range (edge case)
- **Description:** Set background color with values outside [0,1] range.
- **JSON params:** `{"path": "WorldEnvironment", "properties": {"background_color": [5, -2, 10]}}`
- **Expected result:** May or may not clamp. Godot may accept any float values but display may saturate.
- **Notes:** No validation layer for color ranges in the schema; Godot may clamp.

#### 4.15 — Fog density negative (edge case)
- **Description:** Set negative fog density.
- **JSON params:** `{"path": "WorldEnvironment", "properties": {"fog_density": -0.5}}`
- **Expected result:** May produce unexpected visual results or be clamped by Godot.
- **Notes:** No validation layer; Godot handles invalid values via clamping or ignoring.

---

## Tool 5: `add_gridmap`

### Overview

| Field | Value |
|-------|-------|
| **Tool name** | `add_gridmap` |
| **Description** | Add a GridMap node for 3D tile-based level design |
| **Handler** | `scene3d/add_gridmap` |

### Parameters

| # | Parameter | Type | Required | Default | Enum Values | Description |
|---|-----------|------|----------|---------|-------------|-------------|
| 1 | `parent` | `string` (ParentPath) | **Yes** | — | — | Parent node path. `''` for scene root, or node name/path to add as a child. |
| 2 | `properties` | `record` (object) | No | `undefined` | — | GridMap properties (mesh_library_path, cell_size, etc.). |

### Behavior

Adds a `GridMap` node as a child of the specified `parent`. A GridMap is Godot's equivalent of a 3D tilemap — it maps 3D grid cells to meshes from a `MeshLibrary` resource.

### Test Scenarios

#### 5.1 — Happy Path: Add GridMap at root (minimal params)
- **Description:** Add a GridMap at the scene root with only `parent`.
- **JSON params:** `{"parent": ""}`
- **Expected result:** A GridMap node is created at scene root with default properties (cell_size default, no mesh_library).
- **Notes:** Simplest valid call.

#### 5.2 — Add GridMap under a named parent
- **Description:** Add a GridMap as a child of a specific node.
- **JSON params:** `{"parent": "LevelGeometry"}`
- **Expected result:** GridMap node created under `LevelGeometry`.
- **Notes:** Verifies parent resolution.

#### 5.3 — Add GridMap under nested parent path
- **Description:** Add a GridMap under a deeply nested parent.
- **JSON params:** `{"parent": "Level/GridLayer/Primary"}`
- **Expected result:** GridMap created under `Level/GridLayer/Primary`.
- **Notes:** Nested path resolution.

#### 5.4 — Add GridMap with cell_size
- **Description:** Add a GridMap with a custom cell size.
- **JSON params:** `{"parent": "", "properties": {"cell_size": [2, 2, 2]}}`
- **Expected result:** GridMap created with `cell_size = (2, 2, 2)`.
- **Notes:** `cell_size` is a Vector3.

#### 5.5 — Add GridMap with mesh_library_path
- **Description:** Add a GridMap with a MeshLibrary resource assigned.
- **JSON params:** `{"parent": "", "properties": {"mesh_library_path": "res://tiles/dungeon_tiles.res"}}`
- **Expected result:** GridMap created and linked to the `dungeon_tiles.res` MeshLibrary.
- **Notes:** Requires the resource to exist. Tests resource path assignment.

#### 5.6 — Add GridMap with both cell_size and mesh_library_path
- **Description:** Configure both common GridMap properties.
- **JSON params:** `{"parent": "", "properties": {"cell_size": [4, 4, 4], "mesh_library_path": "res://tiles/city_tiles.res"}}`
- **Expected result:** GridMap with cell size `(4, 4, 4)` and city tiles library.
- **Notes:** Multiple properties in one call.

#### 5.7 — Properties with empty object
- **Description:** Pass empty properties.
- **JSON params:** `{"parent": "", "properties": {}}`
- **Expected result:** GridMap created with default cell_size and no mesh library.
- **Notes:** No-op properties.

#### 5.8 — Missing required `parent` (edge case)
- **Description:** Omit the required `parent` parameter.
- **JSON params:** `{}`
- **Expected result:** Validation error. `parent` is required.
- **Notes:** Schema-level rejection.

#### 5.9 — Missing required `parent` (edge case, properties only)
- **Description:** Omit parent but provide properties.
- **JSON params:** `{"properties": {"cell_size": [2, 2, 2]}}`
- **Expected result:** Validation error. `parent` is required.
- **Notes:** Schema-level rejection.

#### 5.10 — Null parent (edge case)
- **Description:** Pass `null` as parent.
- **JSON params:** `{"parent": null}`
- **Expected result:** Validation error. Zod string rejects null.
- **Notes:** Type mismatch.

#### 5.11 — Invalid cell_size: non-numeric values (edge case)
- **Description:** Pass cell_size with string values.
- **JSON params:** `{"parent": "", "properties": {"cell_size": ["big", "big", "big"]}}`
- **Expected result:** Error or unexpected behavior from Godot handler. Godot expects Vector3 numbers.
- **Notes:** No Zod-level validation for array element types in `z.record(z.unknown())`.

#### 5.12 — Invalid mesh_library_path: non-existent resource (edge case)
- **Description:** Reference a MeshLibrary that does not exist.
- **JSON params:** `{"parent": "", "properties": {"mesh_library_path": "res://tiles/nonexistent.res"}}`
- **Expected result:** Godot handler may set the path anyway (not loaded until needed) or return a warning.
- **Notes:** Resource paths are not validated at tool-schema level.

---

## Tool 6: `set_material_3d`

### Overview

| Field | Value |
|-------|-------|
| **Tool name** | `set_material_3d` |
| **Description** | Create and apply a StandardMaterial3D or ShaderMaterial to a mesh |
| **Handler** | `scene3d/set_material` |

### Parameters

| # | Parameter | Type | Required | Default | Enum Values | Description |
|---|-----------|------|----------|---------|-------------|-------------|
| 1 | `path` | `string` (NodePath) | **Yes** | — | — | MeshInstance3D node path. |
| 2 | `properties` | `record` (object) | **Yes** | — | — | Material properties (albedo_color, metallic, roughness, shader_path, etc.). |

### Behavior

Creates and applies a material to the mesh at the specified `path`. By default, a `StandardMaterial3D` is used. If `properties` includes `shader_path`, a `ShaderMaterial` is created instead, linked to the shader at that path. Properties like `albedo_color`, `metallic`, `roughness` set the material's PBR parameters.

### Test Scenarios

#### 6.1 — Happy Path: Set StandardMaterial3D with albedo color (minimal params)
- **Description:** Apply a StandardMaterial3D with a red albedo to a mesh at root.
- **JSON params:** `{"path": "Cube", "properties": {"albedo_color": [1, 0, 0]}}`
- **Expected result:** A StandardMaterial3D is created with red albedo and applied to the `Cube` MeshInstance3D.
- **Notes:** Simplest valid call. Requires a `Cube` node to exist.

#### 6.2 — Apply material to nested mesh path
- **Description:** Apply material to a mesh under a parent node.
- **JSON params:** `{"path": "Level/Floor", "properties": {"albedo_color": [0.5, 0.3, 0.1]}}`
- **Expected result:** Material applied to `Level/Floor` MeshInstance3D with brown albedo.
- **Notes:** Nested path resolution.

#### 6.3 — Set metallic property
- **Description:** Apply a metallic material.
- **JSON params:** `{"path": "Sphere", "properties": {"metallic": 1}}`
- **Expected result:** StandardMaterial3D with `metallic = 1.0` (fully metallic) applied.
- **Notes:** Metallic range 0–1.

#### 6.4 — Set roughness property
- **Description:** Apply a rough material.
- **JSON params:** `{"path": "Sphere", "properties": {"roughness": 0.9}}`
- **Expected result:** StandardMaterial3D with `roughness = 0.9` applied.
- **Notes:** Roughness range 0–1.

#### 6.5 — Set full PBR properties (albedo + metallic + roughness)
- **Description:** Configure albedo, metallic, and roughness together.
- **JSON params:** `{"path": "Cylinder", "properties": {"albedo_color": [0.2, 0.6, 0.9], "metallic": 0.8, "roughness": 0.3}}`
- **Expected result:** StandardMaterial3D with blue albedo, high metalness, low roughness (shiny metal).
- **Notes:** Full PBR setup in one call.

#### 6.6 — Create ShaderMaterial with shader_path
- **Description:** Apply a ShaderMaterial linked to a custom shader.
- **JSON params:** `{"path": "Plane", "properties": {"shader_path": "res://shaders/toon.gdshader"}}`
- **Expected result:** A ShaderMaterial is created, linked to `toon.gdshader`, and applied to the `Plane` mesh.
- **Notes:** `shader_path` triggers ShaderMaterial creation instead of StandardMaterial3D. Requires the shader file to exist.

#### 6.7 — ShaderMaterial with shader_path and material params
- **Description:** Apply ShaderMaterial with both a shader and a uniform parameter.
- **JSON params:** `{"path": "Plane", "properties": {"shader_path": "res://shaders/toon.gdshader", "shader_param/color_ramp": [1, 0, 0]}}`
- **Expected result:** ShaderMaterial created with the toon shader applied, and the `color_ramp` uniform set.
- **Notes:** Additional properties beyond `shader_path` may be treated as shader uniforms by the handler.

#### 6.8 — Apply material with emission
- **Description:** Set emission properties on the material.
- **JSON params:** `{"path": "Cube", "properties": {"albedo_color": [0, 0, 0], "emission": [1, 0.5, 0], "emission_energy": 3}}`
- **Expected result:** StandardMaterial3D with black albedo and bright orange emission.
- **Notes:** Emission makes the material glow.

#### 6.9 — Apply transparent material
- **Description:** Create a material with transparency.
- **JSON params:** `{"path": "Cube", "properties": {"albedo_color": [1, 1, 1, 0.5], "transparency": 1}}`
- **Expected result:** StandardMaterial3D with 50% alpha transparency.
- **Notes:** Requires `transparency` flag and alpha in the color.

#### 6.10 — Missing required `path` (edge case)
- **Description:** Omit the required `path` parameter.
- **JSON params:** `{"properties": {"albedo_color": [1, 0, 0]}}`
- **Expected result:** Validation error. `path` is required.
- **Notes:** Schema-level rejection.

#### 6.11 — Missing required `properties` (edge case)
- **Description:** Omit the required `properties` parameter.
- **JSON params:** `{"path": "Cube"}`
- **Expected result:** Validation error. `properties` is required (uses `Properties`, not `OptionalProperties`).
- **Notes:** Schema-level rejection.

#### 6.12 — Properties with empty object
- **Description:** Pass empty properties.
- **JSON params:** `{"path": "Cube", "properties": {}}`
- **Expected result:** May create a default StandardMaterial3D (white albedo, no metallic, no roughness) or return an error if creating an empty material is unsupported.
- **Notes:** Valid by schema, but may produce default material.

#### 6.13 — Non-existent mesh path (edge case)
- **Description:** Apply material to a mesh node that does not exist.
- **JSON params:** `{"path": "NonExistentMesh", "properties": {"albedo_color": [0, 1, 0]}}`
- **Expected result:** Error from Godot handler — mesh node not found.
- **Notes:** Tests error handling for missing targets.

#### 6.14 — Path points to a non-mesh node (edge case)
- **Description:** Apply material to a Camera3D (not a mesh).
- **JSON params:** `{"path": "MainCamera", "properties": {"albedo_color": [1, 0, 0]}}`
- **Expected result:** Error from Godot handler — target is not a MeshInstance3D.
- **Notes:** Tests type checking on the handler side.

#### 6.15 — Apply material to a node with existing material (edge case)
- **Description:** Overwrite an existing material on a mesh.
- **JSON params:** `{"path": "Cube", "properties": {"albedo_color": [0, 1, 0]}}`
- **Required setup:** `Cube` already has a red material from test 6.1.
- **Expected result:** Material is replaced with the new green material.
- **Notes:** Tests material replacement behavior — the handler should overwrite, not merge.

#### 6.16 — Invalid shader_path (edge case)
- **Description:** Reference a non-existent shader file.
- **JSON params:** `{"path": "Cube", "properties": {"shader_path": "res://shaders/does_not_exist.gdshader"}}`
- **Expected result:** Error from Godot handler — shader resource not found.
- **Notes:** Tests resource loading error handling.

#### 6.17 — Metallic value out of range (edge case)
- **Description:** Set metallic to 5 (outside 0–1).
- **JSON params:** `{"path": "Cube", "properties": {"metallic": 5}}`
- **Expected result:** Godot may clamp to 1.0 or accept and produce unexpected visuals.
- **Notes:** No Zod-level validation; Godot handles clamping.

#### 6.18 — Roughness value out of range (edge case)
- **Description:** Set roughness to -0.5 (outside 0–1).
- **JSON params:** `{"path": "Cube", "properties": {"roughness": -0.5}}`
- **Expected result:** Godot may clamp to 0.0 or produce unexpected visuals.
- **Notes:** No Zod-level validation; Godot handles clamping.

#### 6.19 — Null path (edge case)
- **Description:** Pass `null` as path.
- **JSON params:** `{"path": null, "properties": {"albedo_color": [1, 0, 0]}}`
- **Expected result:** Validation error. Zod string rejects null.
- **Notes:** Type mismatch.

#### 6.20 — Multiple materials on the same mesh (edge case)
- **Description:** Apply material to slot 1 (if mesh supports multiple material slots).
- **JSON params:** `{"path": "Cube", "properties": {"albedo_color": [0, 0, 1], "surface_index": 1}}`
- **Expected result:** Depending on handler, may set material on surface 1 of the mesh.
- **Notes:** Tests if the handler supports multi-material meshes via `surface_index`.

---

## Cross-Tool Integration Scenarios

These scenarios test multiple scene3d tools used together to build a complete 3D scene.

### INT-1: Full scene setup — cube, camera, light, environment
- **Description:** Create a cube mesh, add a camera, directional light, configure environment, and apply material — simulating a complete minimal 3D scene.
- **Steps:**
  1. `add_mesh_instance` — `{"parent": "", "mesh_type": "cube"}` → creates a Cube node
  2. `setup_camera_3d` — `{"path": "", "properties": {"position": [0, 2, 10], "look_at": [0, 0, 0], "make_current": true}}` → creates and positions camera looking at origin
  3. `setup_lighting` — `{"parent": "", "type": "directional", "properties": {"position": [5, 10, 5], "shadow_enabled": true}}` → adds directional light with shadows
  4. `setup_environment` — `{"path": "WorldEnvironment", "properties": {"background_color": [0.1, 0.1, 0.15], "ambient_light_color": [0.3, 0.3, 0.4]}}` → sets dark blue background and ambient
  5. `set_material_3d` — `{"path": "Cube", "properties": {"albedo_color": [0.8, 0.2, 0.2], "metallic": 0, "roughness": 0.7}}` → gives the cube a red matte material
- **Expected result:** A complete 3D scene with a red cube, camera facing it, directional lighting, and a configured environment.
- **Notes:** Verify all steps succeed in sequence without interference.

### INT-2: Multiple meshes with different materials
- **Description:** Add a sphere, cylinder, and plane, each with different materials.
- **Steps:**
  1. `add_mesh_instance` — `{"parent": "", "mesh_type": "sphere"}` → Sphere node
  2. `add_mesh_instance` — `{"parent": "", "mesh_type": "cylinder"}` → Cylinder node
  3. `add_mesh_instance` — `{"parent": "", "mesh_type": "plane"}` → Plane node
  4. `set_material_3d` — `{"path": "Sphere", "properties": {"albedo_color": [1, 0, 0], "metallic": 1, "roughness": 0.1}}` → shiny red metal sphere
  5. `set_material_3d` — `{"path": "Cylinder", "properties": {"albedo_color": [0, 0.5, 0], "roughness": 0.8}}` → rough green cylinder
  6. `set_material_3d` — `{"path": "Plane", "properties": {"albedo_color": [0.7, 0.7, 0.7], "metallic": 0}}` → gray matte plane
  7. `setup_lighting` — `{"parent": "", "type": "spot", "properties": {"position": [0, 5, 5], "look_at": [0, 0, 0]}}` → adds spotlight
- **Expected result:** Three distinctly different meshes with three different materials, lit by a spotlight.

### INT-3: GridMap with environment and lighting
- **Description:** Create a GridMap level, set up lighting, and configure the environment for fog.
- **Steps:**
  1. `add_gridmap` — `{"parent": "", "properties": {"cell_size": [2, 2, 2]}}` → GridMap at root
  2. `setup_lighting` — `{"parent": "", "type": "directional"}` → directional light
  3. `setup_lighting` — `{"parent": "", "type": "omni", "properties": {"position": [0, 3, 0], "energy": 0.5}}` → dim omni light
  4. `setup_environment` — `{"path": "WorldEnvironment", "properties": {"fog_enabled": true, "fog_density": 0.02, "glow_enabled": true}}` → fog + glow
- **Expected result:** GridMap level with directional + ambient lighting, fog atmosphere.

---

## Summary

| # | Tool | Required Params | Optional Params | Enum Params | Happy Scenarios | Edge Cases | Integration Scenarios |
|---|------|----------------|-----------------|-------------|-----------------|------------|-----------------------|
| 1 | `add_mesh_instance` | `parent`, `mesh_type` | `properties` | `mesh_type` (7 values) | 11 | 9 | INT-1, INT-2 |
| 2 | `setup_camera_3d` | `properties` | `path` (default `''`) | — | 7 | 5 | INT-1 |
| 3 | `setup_lighting` | `parent`, `type` | `properties` | `type` (3 values) | 9 | 7 | INT-1, INT-2, INT-3 |
| 4 | `setup_environment` | `path`, `properties` | — | — | 8 | 7 | INT-1, INT-3 |
| 5 | `add_gridmap` | `parent` | `properties` | — | 6 | 5 | INT-3 |
| 6 | `set_material_3d` | `path`, `properties` | — | — | 9 | 11 | INT-1, INT-2 |
| **Total** | | | | | **50** | **44** | **3** |

**Grand total: 97 test scenarios** (50 happy path + 44 edge cases + 3 integration)

