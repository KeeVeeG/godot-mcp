# Scene3D Tools Test Plan

> **Source**: `server/src/tools/scene3d.ts` (6 tools)
> **Shared types**: `server/src/tools/shared-types.ts`
> **Bridge call**: `callGodot(bridge, 'scene3d/<action>', args)` — forwards to Godot via WebSocket, returns `ToolResult { content: [{ type: 'text', text }] }`

---

## Table of Contents

1. [add_mesh_instance](#tool-add_mesh_instance)
2. [setup_camera_3d](#tool-setup_camera_3d)
3. [setup_lighting](#tool-setup_lighting)
4. [setup_environment](#tool-setup_environment)
5. [add_gridmap](#tool-add_gridmap)
6. [get_gridmap](#tool-get_gridmap)
7. [set_material_3d](#tool-set_material_3d)

---

## Shared Type Definitions

| Type | Zod Schema | Description |
|------|-----------|-------------|
| `NodePath` | `z.string()` | Scene-tree path relative to current scene (e.g. `"Player/Sprite2D"`, `""` for root) |
| `ParentPath` | `z.string()` | Parent node path — `""` for scene root, or a name/path for children |
| `Properties` | `z.record(z.unknown())` | **Required** key-value pairs for node/resource properties |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | **Optional** key-value pairs — omit entirely to skip |

---

## Recommended Test Execution Order

Scene3D tools depend on an existing scene and scene-tree nodes. Execute in this order for a clean integration flow:

```
Setup:
  1. create_scene        — create a 3D scene (root type Node3D)
  2. open_scene          — open the scene for editing

Scene3D tools (no inter-dependencies among these):
  3. add_mesh_instance   — add a MeshInstance3D with a primitive mesh
  4. setup_camera_3d     — add/configure a Camera3D
  5. setup_lighting      — add a light node
  6. setup_environment   — configure WorldEnvironment
  7. add_gridmap         — add a GridMap node
  8. get_gridmap         — read GridMap node properties
  9. set_material_3d     — apply material to the mesh from step 3

Verification:
 10. get_scene_tree      — inspect the full node hierarchy
 11. get_node_properties — verify properties on individual nodes
 12. save_scene          — persist changes
```

**Prerequisites for all Scene3D tools**:
- A scene must be open in the editor (use `create_scene` with `root_node_type: "Node3D"`, then `open_scene`)
- For tools that take `parent` / `parent_path`: the parent node must already exist in the scene tree
- For `set_material_3d`: a MeshInstance3D node must already exist (typically created by `add_mesh_instance`)

**Related tools from other modules**:
| Tool | Module | When needed |
|------|--------|-------------|
| `create_scene` | `scene.ts` | Before any Scene3D tool — creates the 3D scene |
| `open_scene` | `scene.ts` | After `create_scene` — makes the scene active for editing |
| `add_node` | `node.ts` | To create generic parent nodes (e.g. `Node3D` containers) before adding meshes/lights as children |
| `get_scene_tree` | `scene.ts` | After Scene3D operations — verify the node hierarchy |
| `get_node_properties` | `node.ts` | After Scene3D operations — verify node properties were applied |
| `save_scene` | `scene.ts` | After all operations — persist the scene to disk |
| `delete_node` | `node.ts` | Cleanup — remove test nodes between scenarios |

---

## Tool: `add_mesh_instance`

**Description**: Add a MeshInstance3D with a primitive mesh type
**Godot method**: `scene3d/add_mesh`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `parent` | `string` (ParentPath) | **yes** | — | Parent node path. `""` for scene root, or a name/path like `"Level"` |
| `mesh_type` | `enum` | **yes** | — | Primitive mesh type: `cube`, `sphere`, `cylinder`, `capsule`, `plane`, `prism`, `torus` |
| `properties` | `Record<string, unknown>` (OptionalProperties) | no | `undefined` | Mesh properties: `size`, `material_path`, `position`, etc. |

### Test Scenarios

#### Scenario 1: Add a cube mesh at scene root (happy path, minimum params)

**Description**: Add a MeshInstance3D with a cube mesh as a direct child of the scene root. No optional properties.

**Prerequisites**:
1. `create_scene` → `{ "path": "res://scenes/test_3d.tscn", "root_node_type": "Node3D" }`
2. `open_scene` → `{ "path": "res://scenes/test_3d.tscn" }`

**Call**:
```json
{
  "parent": "",
  "mesh_type": "cube"
}
```

**Expected result**: Success. A `MeshInstance3D` node with a `BoxMesh` is added as a child of the scene root. Response does NOT contain `isError: true`. The node should appear in `get_scene_tree` output.

**Notes**: Verify the node type is `MeshInstance3D` and that it has a `BoxMesh` resource assigned to its `mesh` property via `get_node_properties`.

---

#### Scenario 2: Add a sphere mesh with properties

**Description**: Add a sphere mesh with custom size and position properties.

**Prerequisites**: Same scene setup as Scenario 1.

**Call**:
```json
{
  "parent": "",
  "mesh_type": "sphere",
  "properties": {
    "name": "TestSphere",
    "position": [2.0, 1.0, 0.0],
    "mesh": { "radius": 1.5, "height": 3.0 }
  }
}
```

**Expected result**: Success. A MeshInstance3D named "TestSphere" is created at position (2, 1, 0) with a sphere mesh of radius 1.5. Verify via `get_node_properties` that `position` matches.

**Notes**: The exact shape of the `properties` object (nested vs flat) depends on the Godot-side handler. The `mesh` sub-object may be interpreted as SphereMesh properties. Document what the handler actually accepts.

---

#### Scenario 3: Add mesh as child of an existing parent node

**Description**: Add a cylinder mesh as a child of a pre-existing `Node3D` container.

**Prerequisites**:
1. Scene setup as above
2. `add_node` → `{ "parent_path": "", "type": "Node3D", "name": "Props" }`

**Call**:
```json
{
  "parent": "Props",
  "mesh_type": "cylinder"
}
```

**Expected result**: Success. The MeshInstance3D is a child of the "Props" node, not the scene root. Verify via `get_scene_tree` that the hierarchy is `Root > Props > MeshInstance3D`.

**Notes**: Tests the `parent` parameter accepting a non-empty node path.

---

#### Scenario 4: Add each mesh type variant

**Description**: Verify that all 7 mesh_type enum values are accepted and create the correct Godot mesh resource.

**Call** (repeat for each type):
```json
{ "parent": "", "mesh_type": "cube" }
{ "parent": "", "mesh_type": "sphere" }
{ "parent": "", "mesh_type": "cylinder" }
{ "parent": "", "mesh_type": "capsule" }
{ "parent": "", "mesh_type": "plane" }
{ "parent": "", "mesh_type": "prism" }
{ "parent": "", "mesh_type": "torus" }
```

**Expected result**: All 7 calls succeed. Each creates a MeshInstance3D with the corresponding primitive mesh type:
| `mesh_type` | Expected Godot mesh resource |
|-------------|------------------------------|
| `cube` | `BoxMesh` |
| `sphere` | `SphereMesh` |
| `cylinder` | `CylinderMesh` |
| `capsule` | `CapsuleMesh` |
| `plane` | `PlaneMesh` |
| `prism` | `PrismMesh` |
| `torus` | `TorusMesh` |

**Notes**: If any type fails, it indicates an issue in the Godot-side handler or the enum validation. Use `get_node_properties` on each to verify the `mesh` property class.

---

#### Scenario 5: Missing required `parent` parameter

**Description**: Call without the `parent` field.

**Call**:
```json
{
  "mesh_type": "cube"
}
```

**Expected result**: Error. The MCP SDK should reject this at the schema validation level because `parent` (ParentPath) is required. Response should contain `isError: true`.

**Notes**: This tests Zod schema enforcement on the TypeScript side.

---

#### Scenario 6: Missing required `mesh_type` parameter

**Description**: Call without the `mesh_type` field.

**Call**:
```json
{
  "parent": ""
}
```

**Expected result**: Error. Schema validation rejects because `mesh_type` is a required enum field.

---

#### Scenario 7: Invalid `mesh_type` enum value

**Description**: Pass a mesh type that doesn't exist in the enum.

**Call**:
```json
{
  "parent": "",
  "mesh_type": "pyramid"
}
```

**Expected result**: Error. Zod should reject `"pyramid"` because it's not in the enum `['cube', 'sphere', 'cylinder', 'capsule', 'plane', 'prism', 'torus']`.

**Notes**: Tests schema validation. The error should mention the invalid enum value.

---

#### Scenario 8: Parent node does not exist

**Description**: Specify a parent path that doesn't exist in the scene tree.

**Call**:
```json
{
  "parent": "NonExistentParent",
  "mesh_type": "cube"
}
```

**Expected result**: Error. The Godot side should report that the parent node was not found.

**Notes**: Tests error handling for invalid parent paths on the Godot side.

---

#### Scenario 9: Empty `properties` object

**Description**: Pass an explicit empty object for `properties`.

**Call**:
```json
{
  "parent": "",
  "mesh_type": "torus",
  "properties": {}
}
```

**Expected result**: Success. Same as omitting `properties` — the mesh is created with defaults.

**Notes**: Edge case — confirms that an empty properties dict doesn't cause errors.

---

## Tool: `setup_camera_3d`

**Description**: Add and configure a Camera3D node
**Godot method**: `scene3d/setup_camera`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (NodePath, optional) | no | `""` | Camera node path. Leave empty / omit to create a new Camera3D. Provide a path to configure an existing one. |
| `properties` | `Record<string, unknown>` (Properties) | **yes** | — | Camera properties: `fov`, `near`, `far`, `position`, `look_at`, `make_current`, `projection`, etc. |

### Test Scenarios

#### Scenario 1: Create a new Camera3D with minimal properties (happy path)

**Description**: Create a new Camera3D by omitting `path` (defaults to `""`). Set only the position.

**Prerequisites**:
1. `create_scene` → `{ "path": "res://scenes/camera_test.tscn", "root_node_type": "Node3D" }`
2. `open_scene` → `{ "path": "res://scenes/camera_test.tscn" }`

**Call**:
```json
{
  "properties": {
    "position": [0, 5, 10]
  }
}
```

**Expected result**: Success. A new Camera3D node is created at position (0, 5, 10). Response does NOT contain `isError: true`. The node should appear in `get_scene_tree`.

**Notes**: When `path` is empty or omitted, the tool creates a new Camera3D node. Verify the node type is `Camera3D` via `get_node_properties`.

---

#### Scenario 2: Create Camera3D with full properties

**Description**: Create a Camera3D with FOV, near/far planes, position, and look_at target.

**Call**:
```json
{
  "properties": {
    "fov": 75,
    "near": 0.1,
    "far": 1000,
    "position": [0, 10, 15],
    "look_at": [0, 0, 0],
    "make_current": true
  }
}
```

**Expected result**: Success. Camera3D created with FOV 75°, near plane 0.1, far plane 1000, positioned at (0, 10, 15), looking at the origin, and set as the current camera.

**Notes**: Verify via `get_node_properties` that `fov`, `near`, `far` match. The `look_at` property may be handled specially by the Godot side — it might set the camera's rotation to face the target rather than being a stored property.

---

#### Scenario 3: Configure an existing Camera3D by path

**Description**: First create a Camera3D node, then configure it using its path.

**Prerequisites**:
1. Scene setup
2. `add_node` → `{ "parent_path": "", "type": "Camera3D", "name": "MainCamera" }`

**Call**:
```json
{
  "path": "MainCamera",
  "properties": {
    "fov": 90,
    "make_current": true
  }
}
```

**Expected result**: Success. The existing "MainCamera" node is configured with FOV 90° and set as current. No new node is created.

**Notes**: When `path` is provided and non-empty, the tool should configure the existing node rather than creating a new one. Verify that `get_scene_tree` still shows only one Camera3D node.

---

#### Scenario 4: Missing required `properties` parameter

**Description**: Call without `properties`.

**Call**:
```json
{
  "path": ""
}
```

**Expected result**: Error. Schema validation rejects because `properties` (Properties = `z.record(z.unknown())`) is required — it is NOT optional.

**Notes**: Unlike `add_mesh_instance` where properties is optional, `setup_camera_3d` requires properties. This is a key difference.

---

#### Scenario 5: Path references a non-Camera3D node

**Description**: Try to configure a non-camera node as if it were a camera.

**Prerequisites**:
1. Scene setup
2. `add_node` → `{ "parent_path": "", "type": "MeshInstance3D", "name": "NotACamera" }`

**Call**:
```json
{
  "path": "NotACamera",
  "properties": {
    "fov": 60
  }
}
```

**Expected result**: Error. The Godot side should reject configuring camera properties on a non-Camera3D node.

**Notes**: Tests type-safety on the Godot handler side.

---

#### Scenario 6: Path references a non-existent node

**Description**: Provide a path to a node that doesn't exist.

**Call**:
```json
{
  "path": "GhostCamera",
  "properties": {
    "fov": 60
  }
}
```

**Expected result**: Error. The Godot side should report that the node "GhostCamera" was not found.

---

## Tool: `setup_lighting`

**Description**: Add a light node (DirectionalLight3D, OmniLight3D, SpotLight3D)
**Godot method**: `scene3d/setup_lighting`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `parent` | `string` (ParentPath) | **yes** | — | Parent node path. `""` for scene root |
| `type` | `enum` | **yes** | — | Light type: `omni`, `spot`, `directional` |
| `properties` | `Record<string, unknown>` (OptionalProperties) | no | `undefined` | Light properties: `color`, `energy`, `position`, `shadow_enabled`, `omni_range`, `spot_angle`, etc. |

### Test Scenarios

#### Scenario 1: Add an omni light at scene root (happy path, minimum params)

**Description**: Add an OmniLight3D as a direct child of the scene root with no optional properties.

**Prerequisites**:
1. `create_scene` → `{ "path": "res://scenes/light_test.tscn", "root_node_type": "Node3D" }`
2. `open_scene` → `{ "path": "res://scenes/light_test.tscn" }`

**Call**:
```json
{
  "parent": "",
  "type": "omni"
}
```

**Expected result**: Success. An `OmniLight3D` node is added as a child of the scene root. Response does NOT contain `isError: true`.

**Notes**: Verify the node type is `OmniLight3D` via `get_node_properties`.

---

#### Scenario 2: Add a directional light with properties

**Description**: Add a DirectionalLight3D with custom color, energy, and shadow settings.

**Call**:
```json
{
  "parent": "",
  "type": "directional",
  "properties": {
    "name": "SunLight",
    "color": [1.0, 0.95, 0.8],
    "energy": 1.2,
    "shadow_enabled": true,
    "rotation": [-0.785, 0, 0]
  }
}
```

**Expected result**: Success. A DirectionalLight3D named "SunLight" is created with warm white color, energy 1.2, shadows enabled, and rotated ~45° on the X axis.

**Notes**: Verify via `get_node_properties` that `light_color`, `light_energy`, and `shadow_enabled` match. The `color` param name may map to Godot's `light_color` property.

---

#### Scenario 3: Add a spot light with spot-specific properties

**Description**: Add a SpotLight3D with angle and range properties.

**Call**:
```json
{
  "parent": "",
  "type": "spot",
  "properties": {
    "name": "Flashlight",
    "position": [0, 2, 0],
    "rotation": [-1.57, 0, 0],
    "spot_angle": 30,
    "spot_range": 15.0,
    "energy": 2.0,
    "shadow_enabled": true
  }
}
```

**Expected result**: Success. A SpotLight3D named "Flashlight" created pointing downward with a 30° cone angle, 15-unit range, energy 2.0, and shadows.

**Notes**: `spot_angle` and `spot_range` are SpotLight3D-specific. Verify these are applied correctly.

---

#### Scenario 4: Add each light type variant

**Description**: Verify all 3 light type enum values are accepted and create the correct Godot node type.

**Call** (repeat for each type):
```json
{ "parent": "", "type": "omni" }
{ "parent": "", "type": "spot" }
{ "parent": "", "type": "directional" }
```

**Expected result**: All 3 calls succeed.
| `type` | Expected Godot node type |
|--------|--------------------------|
| `omni` | `OmniLight3D` |
| `spot` | `SpotLight3D` |
| `directional` | `DirectionalLight3D` |

---

#### Scenario 5: Missing required `parent` parameter

**Call**:
```json
{
  "type": "omni"
}
```

**Expected result**: Schema validation error — `parent` is required.

---

#### Scenario 6: Missing required `type` parameter

**Call**:
```json
{
  "parent": ""
}
```

**Expected result**: Schema validation error — `type` is a required enum field.

---

#### Scenario 7: Invalid `type` enum value

**Call**:
```json
{
  "parent": "",
  "type": "point"
}
```

**Expected result**: Error. Zod rejects `"point"` — not in `['omni', 'spot', 'directional']`.

**Notes**: Common mistake — users might say "point" instead of "omni" (Godot uses OmniLight3D, but some engines call it "point light").

---

#### Scenario 8: Parent node does not exist

**Call**:
```json
{
  "parent": "NonExistentParent",
  "type": "omni"
}
```

**Expected result**: Error — parent node not found.

---

#### Scenario 9: Add light as child of a container node

**Description**: Add a spot light as a child of a pre-existing Node3D container.

**Prerequisites**:
1. Scene setup
2. `add_node` → `{ "parent_path": "", "type": "Node3D", "name": "Lights" }`

**Call**:
```json
{
  "parent": "Lights",
  "type": "spot",
  "properties": {
    "name": "Torch",
    "energy": 3.0
  }
}
```

**Expected result**: Success. The SpotLight3D "Torch" is a child of the "Lights" node. Verify via `get_scene_tree`: `Root > Lights > Torch`.

---

## Tool: `setup_environment`

**Description**: Configure the WorldEnvironment for the 3D scene
**Godot method**: `scene3d/setup_environment`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (NodePath) | **yes** | — | WorldEnvironment node path. Must point to an existing WorldEnvironment node, or the tool may create one. |
| `properties` | `Record<string, unknown>` (Properties) | **yes** | — | Environment properties: `background_mode`, `background_color`, `ambient_light_color`, `ambient_light_energy`, `fog_enabled`, `fog_color`, `glow_enabled`, `ssao_enabled`, `tonemap_mode`, etc. |

### Test Scenarios

#### Scenario 1: Configure environment with background color (happy path)

**Description**: Set up a WorldEnvironment with a sky background and ambient light.

**Prerequisites**:
1. `create_scene` → `{ "path": "res://scenes/env_test.tscn", "root_node_type": "Node3D" }`
2. `open_scene` → `{ "path": "res://scenes/env_test.tscn" }`
3. `add_node` → `{ "parent_path": "", "type": "WorldEnvironment", "name": "WorldEnvironment" }`

**Call**:
```json
{
  "path": "WorldEnvironment",
  "properties": {
    "background_mode": "sky",
    "ambient_light_color": [0.2, 0.2, 0.3],
    "ambient_light_energy": 0.5
  }
}
```

**Expected result**: Success. The WorldEnvironment node's environment resource is configured with a sky background and bluish ambient light at half energy.

**Notes**: The `path` must point to an existing WorldEnvironment node. Verify via `get_node_properties` that the environment properties match. The properties may be nested under the `environment` sub-resource.

---

#### Scenario 2: Configure fog and glow post-processing

**Description**: Enable fog and glow effects on the environment.

**Prerequisites**: Same as Scenario 1 (WorldEnvironment node must exist).

**Call**:
```json
{
  "path": "WorldEnvironment",
  "properties": {
    "fog_enabled": true,
    "fog_color": [0.5, 0.6, 0.7],
    "fog_density": 0.01,
    "glow_enabled": true,
    "glow_intensity": 0.8,
    "tonemap_mode": "aces"
  }
}
```

**Expected result**: Success. Fog and glow are enabled with the specified parameters.

**Notes**: `tonemap_mode` accepts string values like `"aces"`, `"filmic"`, `"linear"`. Verify the Godot-side handler maps these strings correctly.

---

#### Scenario 3: Missing required `path` parameter

**Call**:
```json
{
  "properties": {
    "background_mode": "color"
  }
}
```

**Expected result**: Schema validation error — `path` is required.

---

#### Scenario 4: Missing required `properties` parameter

**Call**:
```json
{
  "path": "WorldEnvironment"
}
```

**Expected result**: Schema validation error — `properties` (Properties) is required.

**Notes**: Unlike `add_mesh_instance` and `setup_lighting` where `properties` is optional, `setup_environment` requires it.

---

#### Scenario 5: Path references a non-WorldEnvironment node

**Description**: Try to configure environment properties on a non-WorldEnvironment node.

**Prerequisites**:
1. Scene setup
2. `add_node` → `{ "parent_path": "", "type": "Node3D", "name": "NotAnEnv" }`

**Call**:
```json
{
  "path": "NotAnEnv",
  "properties": {
    "background_mode": "color"
  }
}
```

**Expected result**: Error. The Godot side should reject configuring environment properties on a non-WorldEnvironment node.

---

#### Scenario 6: Path references a non-existent node

**Call**:
```json
{
  "path": "GhostEnvironment",
  "properties": {
    "background_mode": "color"
  }
}
```

**Expected result**: Error — node not found.

---

#### Scenario 7: Configure with solid color background

**Description**: Set the background to a solid color instead of sky.

**Call**:
```json
{
  "path": "WorldEnvironment",
  "properties": {
    "background_mode": "color",
    "background_color": [0.1, 0.1, 0.2],
    "ambient_light_color": [0.3, 0.3, 0.4],
    "ambient_light_energy": 1.0
  }
}
```

**Expected result**: Success. Background is set to a dark blue solid color with matching ambient light.

---

## Tool: `add_gridmap`

**Description**: Add a GridMap node for 3D tile-based level design
**Godot method**: `scene3d/add_gridmap`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `parent` | `string` (ParentPath) | **yes** | — | Parent node path. `""` for scene root |
| `properties` | `Record<string, unknown>` (OptionalProperties) | no | `undefined` | GridMap properties: `mesh_library_path`, `cell_size`, `cell_scale`, `collision_layer`, etc. |

### Test Scenarios

#### Scenario 1: Add a GridMap at scene root (happy path, minimum params)

**Description**: Add a GridMap node with no optional properties.

**Prerequisites**:
1. `create_scene` → `{ "path": "res://scenes/gridmap_test.tscn", "root_node_type": "Node3D" }`
2. `open_scene` → `{ "path": "res://scenes/gridmap_test.tscn" }`

**Call**:
```json
{
  "parent": ""
}
```

**Expected result**: Success. A `GridMap` node is added as a child of the scene root. Response does NOT contain `isError: true`.

**Notes**: Without a `mesh_library_path`, the GridMap will have no mesh library assigned. This is valid but not useful until a library is set.

---

#### Scenario 2: Add GridMap with mesh library and cell size

**Description**: Add a GridMap with a mesh library resource and custom cell size.

**Call**:
```json
{
  "parent": "",
  "properties": {
    "name": "LevelGrid",
    "mesh_library_path": "res://meshes/level_tiles.tres",
    "cell_size": [2, 2, 2],
    "cell_scale": 1.0,
    "collision_layer": 1
  }
}
```

**Expected result**: Success. A GridMap named "LevelGrid" is created with the specified mesh library and 2x2x2 cell size.

**Notes**: The `mesh_library_path` must point to a valid MeshLibrary resource. If the resource doesn't exist, the Godot side may error or silently skip it. Document actual behavior.

---

#### Scenario 3: Add GridMap as child of a container

**Description**: Add a GridMap as a child of a pre-existing Node3D.

**Prerequisites**:
1. Scene setup
2. `add_node` → `{ "parent_path": "", "type": "Node3D", "name": "Level" }`

**Call**:
```json
{
  "parent": "Level",
  "properties": {
    "name": "TerrainGrid",
    "cell_size": [1, 1, 1]
  }
}
```

**Expected result**: Success. The GridMap is a child of the "Level" node. Verify via `get_scene_tree`: `Root > Level > TerrainGrid`.

---

#### Scenario 4: Missing required `parent` parameter

**Call**:
```json
{
  "properties": {
    "cell_size": [1, 1, 1]
  }
}
```

**Expected result**: Schema validation error — `parent` is required.

---

#### Scenario 5: Parent node does not exist

**Call**:
```json
{
  "parent": "NonExistentParent"
}
```

**Expected result**: Error — parent node not found.

---

#### Scenario 6: Empty `properties` object

**Call**:
```json
{
  "parent": "",
  "properties": {}
}
```

**Expected result**: Success. Same as omitting `properties`.

---

## Tool: `get_gridmap`

**Description**: Read properties of a GridMap node (cell_size, mesh_library)
**Godot method**: `scene3d/get_gridmap`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (NodePath) | **yes** | — | GridMap node path |

### Test Scenarios

#### Scenario 1: Get properties of a GridMap (happy path)

**Description**: Read properties of a GridMap node that was created with `add_gridmap`.

**Prerequisites**:
1. `create_scene` → `{ "path": "res://scenes/get_gridmap_test.tscn", "root_node_type": "Node3D" }`
2. `open_scene` → `{ "path": "res://scenes/get_gridmap_test.tscn" }`
3. `add_gridmap` → `{ "parent": "", "properties": { "name": "TestGrid", "cell_size": [2, 2, 2] } }`

**Call**:
```json
{
  "path": "TestGrid"
}
```

**Expected result**: Success. Response contains `cell_size` as `{ "x": 2.0, "y": 2.0, "z": 2.0 }`, the node `name`, and `path`. If a mesh library was assigned, its `resource_path` is included.

**Notes**: Verify that `cell_size` values match what was set during `add_gridmap`. The `mesh_library` field is absent if no library was assigned.

---

#### Scenario 2: Get GridMap with mesh library assigned

**Description**: Read properties of a GridMap that has a mesh library resource.

**Prerequisites**:
1. Scene setup as above
2. A valid MeshLibrary resource must exist at a known path
3. `add_gridmap` → `{ "parent": "", "properties": { "name": "LibraryGrid", "mesh_library": "res://meshes/level_tiles.tres", "cell_size": [1, 1, 1] } }`

**Call**:
```json
{
  "path": "LibraryGrid"
}
```

**Expected result**: Success. Response includes `mesh_library` with the resource path string (e.g. `"res://meshes/level_tiles.tres"`).

**Notes**: The `mesh_library` field is the `resource_path` of the assigned MeshLibrary, not the node property name.

---

#### Scenario 3: Missing required `path` parameter

**Description**: Call without the `path` field.

**Call**:
```json
{}
```

**Expected result**: Error. The Godot side returns `{"error": "Path is required (node path to GridMap)"}`.

---

#### Scenario 4: Path references a non-GridMap node

**Description**: Try to read GridMap properties from a non-GridMap node.

**Prerequisites**:
1. Scene setup
2. `add_node` → `{ "parent_path": "", "type": "Node3D", "name": "NotAGridMap" }`

**Call**:
```json
{
  "path": "NotAGridMap"
}
```

**Expected result**: Error. The Godot side returns `{"error": "Node is not a GridMap: NotAGridMap"}`.

---

#### Scenario 5: Path references a non-existent node

**Description**: Provide a path to a node that doesn't exist.

**Call**:
```json
{
  "path": "GhostGridMap"
}
```

**Expected result**: Error. The Godot side returns `{"error": "Node not found: GhostGridMap"}`.

---

## Tool: `set_material_3d`

**Description**: Create and apply a StandardMaterial3D or ShaderMaterial to a mesh
**Godot method**: `scene3d/set_material`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` (NodePath) | **yes** | — | MeshInstance3D node path |
| `properties` | `Record<string, unknown>` (Properties) | **yes** | — | Material properties: `albedo_color`, `metallic`, `roughness`, `emission_enabled`, `emission_color`, `shader_path`, etc. |

### Test Scenarios

#### Scenario 1: Apply StandardMaterial3D with albedo color (happy path)

**Description**: Apply a StandardMaterial3D with a red albedo color to an existing MeshInstance3D.

**Prerequisites** (execute in order):
1. `create_scene` → `{ "path": "res://scenes/material_test.tscn", "root_node_type": "Node3D" }`
2. `open_scene` → `{ "path": "res://scenes/material_test.tscn" }`
3. `add_mesh_instance` → `{ "parent": "", "mesh_type": "cube" }` — creates a MeshInstance3D

**Call**:
```json
{
  "path": "MeshInstance3D",
  "properties": {
    "albedo_color": [1.0, 0.0, 0.0, 1.0]
  }
}
```

**Expected result**: Success. A StandardMaterial3D is created with red albedo and applied to the MeshInstance3D node's `material_override` or `material` property.

**Notes**: The node name may be auto-generated (e.g., `MeshInstance3D`, `MeshInstance3D2`, etc.). Use `get_scene_tree` after `add_mesh_instance` to discover the exact node name. Verify via `get_node_properties` that a material is assigned.

---

#### Scenario 2: Apply material with PBR properties

**Description**: Apply a StandardMaterial3D with metallic/roughness PBR properties.

**Prerequisites**: MeshInstance3D must exist (from `add_mesh_instance`).

**Call**:
```json
{
  "path": "MeshInstance3D",
  "properties": {
    "albedo_color": [0.8, 0.8, 0.8, 1.0],
    "metallic": 0.9,
    "roughness": 0.1,
    "emission_enabled": true,
    "emission_color": [0.0, 1.0, 0.0, 1.0],
    "emission_energy_multiplier": 2.0
  }
}
```

**Expected result**: Success. A shiny metallic material with green emission is applied.

**Notes**: Verify via `get_node_properties` that `metallic`, `roughness`, and emission properties are set on the material.

---

#### Scenario 3: Apply a ShaderMaterial via shader_path

**Description**: Apply a ShaderMaterial referencing an existing shader file.

**Prerequisites**:
1. MeshInstance3D must exist
2. A shader file must exist (use `create_shader` from shader tools): `{ "path": "res://shaders/custom_mat.gdshader", "type": "spatial", "content": "shader_type spatial;\nvoid fragment() { ALBEDO = vec3(0.0, 0.0, 1.0); }" }`

**Call**:
```json
{
  "path": "MeshInstance3D",
  "properties": {
    "shader_path": "res://shaders/custom_mat.gdshader"
  }
}
```

**Expected result**: Success. A ShaderMaterial is created from the shader file and applied to the mesh. The mesh should render with the shader's blue albedo.

**Notes**: When `shader_path` is present, the tool should create a ShaderMaterial instead of a StandardMaterial3D. Verify the material type via `get_node_properties`.

---

#### Scenario 4: Missing required `path` parameter

**Call**:
```json
{
  "properties": {
    "albedo_color": [1.0, 1.0, 1.0, 1.0]
  }
}
```

**Expected result**: Schema validation error — `path` is required.

---

#### Scenario 5: Missing required `properties` parameter

**Call**:
```json
{
  "path": "MeshInstance3D"
}
```

**Expected result**: Schema validation error — `properties` is required.

---

#### Scenario 6: Path references a non-MeshInstance3D node

**Description**: Try to apply a material to a non-mesh node.

**Prerequisites**:
1. Scene setup
2. `add_node` → `{ "parent_path": "", "type": "Node3D", "name": "NotAMesh" }`

**Call**:
```json
{
  "path": "NotAMesh",
  "properties": {
    "albedo_color": [1.0, 0.0, 0.0, 1.0]
  }
}
```

**Expected result**: Error. The Godot side should reject applying material properties to a non-MeshInstance3D node.

---

#### Scenario 7: Path references a non-existent node

**Call**:
```json
{
  "path": "GhostMesh",
  "properties": {
    "albedo_color": [1.0, 0.0, 0.0, 1.0]
  }
}
```

**Expected result**: Error — node not found.

---

#### Scenario 8: Non-existent shader_path

**Description**: Reference a shader file that doesn't exist.

**Call**:
```json
{
  "path": "MeshInstance3D",
  "properties": {
    "shader_path": "res://shaders/does_not_exist.gdshader"
  }
}
```

**Expected result**: Error. The Godot side should report that the shader resource was not found.

---

## Full Integration Test Sequence

Execute all 6 Scene3D tools in sequence to validate the complete 3D scene construction workflow:

### Setup Phase

```
Step 1: create_scene
  { "path": "res://scenes/scene3d_integration.tscn", "root_node_type": "Node3D" }

Step 2: open_scene
  { "path": "res://scenes/scene3d_integration.tscn" }

Step 3: add_node (create a container for organization)
  { "parent_path": "", "type": "Node3D", "name": "Environment" }
```

### Mesh Phase

```
Step 4: add_mesh_instance (ground plane)
  {
    "parent": "",
    "mesh_type": "plane",
    "properties": { "name": "Ground", "position": [0, 0, 0], "scale": [10, 1, 10] }
  }

Step 5: add_mesh_instance (center object)
  {
    "parent": "",
    "mesh_type": "sphere",
    "properties": { "name": "CenterSphere", "position": [0, 1, 0] }
  }

Step 6: add_mesh_instance (decorative torus)
  {
    "parent": "",
    "mesh_type": "torus",
    "properties": { "name": "FloatingRing", "position": [0, 3, 0] }
  }
```

### Camera Phase

```
Step 7: setup_camera_3d
  {
    "properties": {
      "name": "MainCamera",
      "position": [0, 8, 12],
      "look_at": [0, 0, 0],
      "fov": 65,
      "make_current": true
    }
  }
```

### Lighting Phase

```
Step 8: setup_lighting (sun)
  {
    "parent": "",
    "type": "directional",
    "properties": {
      "name": "Sun",
      "rotation": [-0.785, 0.4, 0],
      "energy": 1.0,
      "shadow_enabled": true
    }
  }

Step 9: setup_lighting (fill light)
  {
    "parent": "Environment",
    "type": "omni",
    "properties": {
      "name": "FillLight",
      "position": [5, 3, 5],
      "energy": 0.5,
      "color": [0.8, 0.8, 1.0]
    }
  }

Step 10: setup_lighting (spot accent)
  {
    "parent": "",
    "type": "spot",
    "properties": {
      "name": "AccentSpot",
      "position": [0, 6, 0],
      "rotation": [-1.57, 0, 0],
      "spot_angle": 25,
      "energy": 3.0,
      "shadow_enabled": true
    }
  }
```

### Environment Phase

```
Step 11: setup_environment
  {
    "path": "WorldEnvironment",
    "properties": {
      "background_mode": "sky",
      "ambient_light_color": [0.15, 0.15, 0.2],
      "ambient_light_energy": 0.3,
      "fog_enabled": true,
      "fog_color": [0.6, 0.7, 0.8],
      "fog_density": 0.005,
      "glow_enabled": true,
      "glow_intensity": 0.4
    }
  }
  NOTE: This step requires a WorldEnvironment node to already exist.
  If one wasn't created in setup, add it first:
    add_node → { "parent_path": "", "type": "WorldEnvironment", "name": "WorldEnvironment" }
```

### Material Phase

```
Step 12: set_material_3d (ground — matte gray)
  {
    "path": "Ground",
    "properties": {
      "albedo_color": [0.4, 0.4, 0.4, 1.0],
      "roughness": 0.9,
      "metallic": 0.0
    }
  }

Step 13: set_material_3d (sphere — shiny metallic)
  {
    "path": "CenterSphere",
    "properties": {
      "albedo_color": [0.9, 0.7, 0.1, 1.0],
      "metallic": 1.0,
      "roughness": 0.05
    }
  }

Step 14: set_material_3d (torus — emissive)
  {
    "path": "FloatingRing",
    "properties": {
      "albedo_color": [0.0, 0.5, 1.0, 1.0],
      "emission_enabled": true,
      "emission_color": [0.0, 0.8, 1.0, 1.0],
      "emission_energy_multiplier": 1.5
    }
  }
```

### GridMap Phase

```
Step 15: add_gridmap
  {
    "parent": "",
    "properties": {
      "name": "LevelGrid",
      "cell_size": [2, 2, 2]
    }
  }

Step 16: get_gridmap
  {
    "path": "LevelGrid"
  }
  → Verify: cell_size is {x: 2, y: 2, z: 2}, name is "LevelGrid"
```

### Verification Phase

```
Step 17: get_scene_tree
  {}
  → Verify: tree contains Ground, CenterSphere, FloatingRing, MainCamera,
    Sun, FillLight (under Environment), AccentSpot, WorldEnvironment, LevelGrid

Step 18: get_node_properties for each created node
  → Verify: position, mesh type, material, light properties all match

Step 19: save_scene
  { "path": "res://scenes/scene3d_integration.tscn" }
```

### Cleanup Phase

```
Step 20: delete_scene
  { "path": "res://scenes/scene3d_integration.tscn", "force": true }
```

---

## Error Response Format

All tools use `callGodot()` which wraps errors as:
```json
{
  "content": [{ "type": "text", "text": "Godot request failed: <error message>" }],
  "isError": true
}
```

Schema validation errors (TypeScript side) are handled by the MCP SDK and follow the SDK's error format.

---

## Notes for Test Implementers

1. **Isolation**: Each test scenario should ideally use unique node names to avoid conflicts when tests run in parallel or out of order. Prefix names with the test scenario number (e.g., `"S1_Cube"`, `"S2_Sphere"`).

2. **Cleanup**: Always delete created scenes after tests. Use `delete_scene` with `force: true` to avoid issues with open scenes.

3. **Godot state**: These tests require a running Godot editor with the MCP plugin active and connected. The WebSocket bridge must be established before any test executes.

4. **Node naming**: When `add_mesh_instance` or `setup_lighting` creates a node without a `name` property, Godot auto-generates one (e.g., `MeshInstance3D`, `MeshInstance3D2`). Always check `get_scene_tree` after creation to discover the actual node name before referencing it in subsequent tools like `set_material_3d`.

5. **Nested properties**: The `properties` object is a generic `Record<string, unknown>`. The Godot handler maps these to Godot node/resource properties. Some properties may be nested (e.g., `mesh.radius` for a SphereMesh) or flat (e.g., `albedo_color` for a material). Document what the handler actually accepts.

6. **Color format**: Colors may be specified as `[r, g, b, a]` arrays (0.0–1.0) or as Godot `Color` constructor arguments. The exact format accepted depends on the Godot-side handler.

7. **Required vs optional properties**: `setup_camera_3d`, `setup_environment`, and `set_material_3d` have **required** `properties` (Properties = `z.record(z.unknown())`). `add_mesh_instance`, `setup_lighting`, and `add_gridmap` have **optional** `properties` (OptionalProperties = `z.record(z.unknown()).optional()`). This means you MUST pass `properties: {}` (at minimum) for the first group, but can omit it entirely for the second.

8. **Material detection**: `set_material_3d` should detect whether to create a `StandardMaterial3D` or `ShaderMaterial` based on whether `shader_path` is present in properties. Test both paths.

9. **WorldEnvironment prerequisite**: The `setup_environment` tool requires a `path` to an existing `WorldEnvironment` node. If the scene doesn't have one, you must create it first via `add_node` with `type: "WorldEnvironment"`.
