# Navigation Tools — Test Plan

**Source:** `server/src/tools/navigation.ts`
**Tools count:** 10
**Shared types:** `NodePath` (required string), `OptionalDimension` (enum `'2d' | '3d'`, optional), `OptionalProperties` (`Record<string, unknown>`, optional)

---

## Dependency Graph

Before testing individual tools, understand the execution order:

```
setup_navigation_region ──┬──► bake_navigation_mesh
                          ├──► set_navigation_layers
                          ├──► get_navigation_info
                          └──► remove_navigation_region

setup_navigation_agent ───┬──► set_navigation_layers
                          └──► remove_navigation_agent

setup_navigation_region ──┐
setup_navigation_region ──┼──► setup_navigation_link ──► remove_navigation_link
                          │
                          └──► find_navigation_path (requires baked mesh)
```

**Critical prerequisite:** A scene must be open/created in Godot before any navigation tool works. Use scene-creation tools (e.g. `create_scene`) first.

---

## Tool: `setup_navigation_region`

**Description:** Add a NavigationRegion2D or NavigationRegion3D with optional configuration.

**Handler:** Calls `navigation/setup_region` on the Godot bridge.

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `string` (NodePath) | **yes** | — | Node path for the navigation region |
| `parent_path` | `string` | no | scene root | Parent node path |
| `dimension` | `'2d' \| '3d'` | no | `'2d'` | Navigation dimension |
| `name` | `string` | no | — | Node name |
| `properties` | `Record<string, unknown>` | no | — | Region properties (navigation_mesh, enabled, etc.) |

### Test Scenarios

#### 1. Happy path — minimal required params (2D region at scene root)

**Call:**
```json
{
  "path": "NavRegion2D"
}
```

**Expected result:**
- Tool call succeeds (no `isError`).
- A `NavigationRegion2D` node is created at path `NavRegion2D` under the scene root.
- Response contains confirmation text or the created node info.

**Notes:** Dimension defaults to `'2d'`. No parent specified → scene root.

**What to check:** Verify that the node was created in the scene tree with type `NavigationRegion2D`.

---

#### 2. 3D region with parent and name

**Call:**
```json
{
  "path": "Level/NavMesh",
  "dimension": "3d",
  "parent_path": "Level",
  "name": "MainNavRegion"
}
```

**Expected result:**
- A `NavigationRegion3D` node is created as a child of `Level`.
- Node name is `MainNavRegion`.
- Full path in scene tree: `Level/MainNavRegion` (or `Level/NavMesh` — depends on which field takes precedence for the scene-tree path).

**Notes:** `path` and `name` may overlap. If both are provided, verify which one determines the actual node name in the tree. This is a critical edge case.

**What to check:** Verify which parameter determines the actual node name — `path` or `name`. Verify the hierarchy is correct.

---

#### 3. Region with properties (enabled flag, navigation_mesh resource)

**Call:**
```json
{
  "path": "World/NavRegion",
  "dimension": "2d",
  "properties": {
    "enabled": true,
    "navigation_mesh": null
  }
}
```

**Expected result:**
- Region node created with `enabled = true`.
- If `navigation_mesh` is null, region has no baked mesh yet (expected before `bake_navigation_mesh`).

**Notes:** This is a setup step — the region is ready for baking.

**What to check:** Verify that `enabled` is set correctly. `navigation_mesh: null` should not cause an error.

---

#### 4. Edge case — empty path string

**Call:**
```json
{
  "path": ""
}
```

**Expected result:**
- Either: tool creates a node at the scene root (if empty string means root), or returns an error indicating path cannot be empty.

**Notes:** `NodePath` schema is `z.string()` — empty string passes validation. Behavior depends on Godot-side handler.

**What to check:** Behavior with an empty string is an edge case. Expect either a node at the scene root or an error from the Godot plugin.

---

#### 5. Edge case — missing `path` (required param omitted)

**Call:**
```json
{
  "dimension": "2d"
}
```

**Expected result:**
- Validation error. `path` is required in the schema. The MCP server should reject this before sending to Godot.

**Notes:** This tests schema enforcement.

**What to check:** This should be a Zod validation error, not a Godot error. Verify the error text.

---

## Tool: `setup_navigation_agent`

**Description:** Add a NavigationAgent2D or NavigationAgent3D to a node.

**Handler:** Calls `navigation/setup_agent` on the Godot bridge.

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `string` (NodePath) | **yes** | — | Node path for the navigation agent |
| `parent_path` | `string` | no | scene root | Parent node path |
| `dimension` | `'2d' \| '3d'` | no | `'2d'` | Navigation dimension |
| `name` | `string` | no | — | Node name |
| `properties` | `Record<string, unknown>` | no | — | Agent properties (radius, speed, path_desired_distance, etc.) |

### Test Scenarios

#### 1. Happy path — 2D agent for a character

**Call:**
```json
{
  "path": "Player/NavAgent"
}
```

**Expected result:**
- A `NavigationAgent2D` node is created under the scene root at path `Player/NavAgent`.
- Tool call succeeds.

**Notes:** No parent specified — the node is placed at scene root with path `Player/NavAgent` (assuming `Player` exists, or it creates the full path).

**What to check:** If `Player` does not exist, Godot may return an error or automatically create intermediate nodes. Verify the behavior.

---

#### 2. 3D agent with full configuration

**Call:**
```json
{
  "path": "Enemies/Enemy01/Agent3D",
  "dimension": "3d",
  "parent_path": "Enemies/Enemy01",
  "name": "Agent3D",
  "properties": {
    "radius": 0.5,
    "speed": 3.5,
    "path_desired_distance": 1.0,
    "target_desired_distance": 0.5,
    "avoidance_enabled": true
  }
}
```

**Expected result:**
- A `NavigationAgent3D` node created as child of `Enemies/Enemy01`.
- Properties are applied: `radius=0.5`, `speed=3.5`, etc.

**What to check:** Verify that all agent properties are set correctly. Check via `get_node_properties` or a similar tool.

---

#### 3. Agent with minimal radius configuration

**Call:**
```json
{
  "path": "NPC/Agent",
  "properties": {
    "radius": 2.0,
    "speed": 1.0
  }
}
```

**Expected result:**
- Agent created with custom radius and speed.
- Other properties use Godot defaults.

**What to check:** Verify that Godot's default properties are not overwritten with zeros or incorrect values.

---

#### 4. Edge case — missing required `path`

**Call:**
```json
{
  "dimension": "3d",
  "properties": { "radius": 1.0 }
}
```

**Expected result:**
- Validation error. `path` is required.

**What to check:** The schema should reject the request before it reaches Godot.

---

## Tool: `bake_navigation_mesh`

**Description:** Bake the navigation mesh for a NavigationRegion.

**Handler:** Calls `navigation/bake_mesh` on the Godot bridge.

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `string` (NodePath) | **yes** | — | NavigationRegion node path |
| `properties` | `Record<string, unknown>` | no | — | Bake configuration (cell_size, cell_height, agent_radius, etc.) |

**Prerequisites:** A `NavigationRegion2D` or `NavigationRegion3D` must exist at the given path. Create one with `setup_navigation_region` first.

### Test Scenarios

#### 1. Happy path — bake with defaults

**Precondition:** Call `setup_navigation_region` with `{"path": "NavRegion", "dimension": "2d"}` first.

**Call:**
```json
{
  "path": "NavRegion"
}
```

**Expected result:**
- Bake completes successfully.
- The region's `navigation_mesh` property is now populated.
- Response indicates success (possibly with mesh stats).

**Notes:** Baking may take time if the scene has complex geometry.

**What to check:** Verify that `navigation_mesh` is no longer `null` after baking. If there are no colliders/polygons on the scene, the mesh may be empty (this is normal for a test).

---

#### 2. Bake with custom configuration

**Precondition:** `setup_navigation_region` with `{"path": "WorldNav", "dimension": "3d"}`.

**Call:**
```json
{
  "path": "WorldNav",
  "properties": {
    "cell_size": 0.25,
    "cell_height": 0.25,
    "agent_radius": 1.0,
    "agent_height": 2.0,
    "agent_max_slope": 45.0
  }
}
```

**Expected result:**
- Bake completes with custom cell/agent parameters.
- Navigation mesh reflects the agent dimensions.

**What to check:** The `agent_radius` and `agent_height` parameters affect traversability — areas narrower than agent_radius will be excluded from the mesh.

---

#### 3. Bake 2D region with baking_resolution

**Call:**
```json
{
  "path": "NavRegion2D",
  "properties": {
    "cell_size": 1.0,
    "baking_resolution": 100
  }
}
```

**Expected result:**
- 2D bake completes. Resolution affects mesh detail.

**What to check:** For 2D regions, baking parameters differ from 3D. Verify that Godot does not reject 3D parameters for a 2D region.

---

#### 4. Edge case — bake nonexistent region

**Call:**
```json
{
  "path": "NonexistentNode"
}
```

**Expected result:**
- Error from Godot side: node not found or path invalid.

**What to check:** The error message should clearly indicate that the node was not found. Verify that `isError: true`.

---

#### 5. Edge case — bake without creating region first (no prerequisite)

**Call:**
```json
{
  "path": "NeverCreated"
}
```

**Expected result:**
- Error: node `NeverCreated` does not exist.

**What to check:** This is the same scenario as #4, but important for understanding the workflow — baking is impossible without `setup_navigation_region`.

---

## Tool: `set_navigation_layers`

**Description:** Set navigation layers and/or mask for pathfinding filtering.

**Handler:** Calls `navigation/set_layers` on the Godot bridge.

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `string` (NodePath) | **yes** | — | Navigation node path |
| `layer` | `number` (int, 1-32) | no | — | Navigation layer (1-32) |

**Note:** The description says "layers and/or mask" but the schema only has `layer`. There is no `mask` parameter. Mask may need to be set via `properties` on the creation tools, or this is a documentation inconsistency.

### Test Scenarios

#### 1. Happy path — set layer on a region

**Precondition:** `setup_navigation_region` with `{"path": "NavRegion"}`.

**Call:**
```json
{
  "path": "NavRegion",
  "layer": 1
}
```

**Expected result:**
- Navigation layer set to 1 on the region.
- Success response.

**What to check:** Verify that the `navigation_layers` property (bitmask) changed on the node.

---

#### 2. Set higher layer number

**Precondition:** Region or agent exists.

**Call:**
```json
{
  "path": "NavRegion",
  "layer": 16
}
```

**Expected result:**
- Layer set to 16.
- In Godot, `navigation_layers` is a bitmask — layer 16 means bit 16 is set.

**What to check:** Verify that the value 16 maps correctly to Godot's bitmask (2^15 = 32768). Godot uses 1-based layer indexing.

---

#### 3. Edge case — layer at boundary value 32

**Call:**
```json
{
  "path": "NavRegion",
  "layer": 32
}
```

**Expected result:**
- Layer set to 32 (maximum allowed).
- Schema validation passes (max is 32).

**What to check:** This is a boundary value. Verify that Godot correctly handles layer 32.

---

#### 4. Edge case — layer value 0 (below minimum)

**Call:**
```json
{
  "path": "NavRegion",
  "layer": 0
}
```

**Expected result:**
- Validation error. `layer` schema has `.min(1)`. Value 0 is rejected.

**What to check:** This is a Zod validation error, not a Godot error. Verify the error message.

---

#### 5. Edge case — layer value 33 (above maximum)

**Call:**
```json
{
  "path": "NavRegion",
  "layer": 33
}
```

**Expected result:**
- Validation error. `layer` schema has `.max(33)` fails.

**What to check:** Zod validation error.

---

#### 6. Edge case — non-integer layer

**Call:**
```json
{
  "path": "NavRegion",
  "layer": 2.5
}
```

**Expected result:**
- Validation error. `layer` schema has `.int()`.

**What to check:** Verify that non-integer numbers are rejected.

---

## Tool: `get_navigation_info`

**Description:** Get navigation map information and navigation mesh data.

**Handler:** Calls `navigation/get_info` on the Godot bridge.

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `string` (NodePath) | **yes** | — | NavigationRegion node path |

**Prerequisites:** A NavigationRegion must exist at the given path.

### Test Scenarios

#### 1. Happy path — get info for a region with baked mesh

**Precondition:**
1. `setup_navigation_region` → `{"path": "NavRegion"}`
2. `bake_navigation_mesh` → `{"path": "NavRegion"}`

**Call:**
```json
{
  "path": "NavRegion"
}
```

**Expected result:**
- Returns navigation map data: mesh vertices, polygons, region properties.
- Response is JSON/text with mesh statistics.

**What to check:** The response should contain navigation mesh data — vertex count, polygon count, bounding box. If the mesh is empty (no geometry on the scene), empty arrays are expected, not an error.

---

#### 2. Get info for unbaked region

**Precondition:** `setup_navigation_region` → `{"path": "EmptyRegion"}` (no bake).

**Call:**
```json
{
  "path": "EmptyRegion"
}
```

**Expected result:**
- Returns region info, but mesh data is empty/null.
- No error — unbaked region is valid state.

**What to check:** Verify that the absence of a mesh does not cause an error. The response should contain something like `mesh: null` or `polygons: []`.

---

#### 3. Edge case — nonexistent node

**Call:**
```json
{
  "path": "GhostRegion"
}
```

**Expected result:**
- Error: node not found.

**What to check:** Error from Godot, `isError: true`.

---

## Tool: `find_navigation_path`

**Description:** Find a navigation path between two points.

**Handler:** Calls `navigation/find_path` on the Godot bridge.

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `start` | `number[]` | **yes** | — | Start position `[x, y]` or `[x, y, z]` |
| `end` | `number[]` | **yes** | — | End position `[x, y]` or `[x, y, z]` |
| `dimension` | `'2d' \| '3d'` | no | auto-detected | Navigation dimension |

**Prerequisites:** A baked navigation mesh must exist in the scene. Use `setup_navigation_region` + `bake_navigation_mesh` first.

### Test Scenarios

#### 1. Happy path — 2D path between two close points

**Precondition:**
1. `setup_navigation_region` → `{"path": "NavRegion", "dimension": "2d"}`
2. `bake_navigation_mesh` → `{"path": "NavRegion"}`

**Call:**
```json
{
  "start": [0, 0],
  "end": [10, 10],
  "dimension": "2d"
}
```

**Expected result:**
- Returns an array of 2D waypoints: `[[x1, y1], [x2, y2], ...]`.
- Path starts at or near `[0, 0]` and ends at or near `[10, 10]`.
- At minimum: 2 points (start and end) if direct path exists.

**What to check:** Verify that the path is an array of number arrays. If no direct path exists (no navigation mesh covering that area), the result may be an empty array.

---

#### 2. 3D pathfinding

**Precondition:**
1. `setup_navigation_region` → `{"path": "Nav3D", "dimension": "3d"}`
2. `bake_navigation_mesh` → `{"path": "Nav3D"}`

**Call:**
```json
{
  "start": [0, 0, 0],
  "end": [50, 0, 50],
  "dimension": "3d"
}
```

**Expected result:**
- Returns array of 3D waypoints: `[[x, y, z], ...]`.
- Path navigates around obstacles if present.

**What to check:** A 3D path contains 3 components per point. Verify that the Y-coordinate is correct (Godot uses Y-up in 3D).

---

#### 3. Auto-detect dimension from array length

**Call:**
```json
{
  "start": [0, 0],
  "end": [5, 5]
}
```

**Expected result:**
- Dimension auto-detected as 2D from array length.
- Path returned in 2D format.

**What to check:** The `dimension` parameter is optional. Verify that the server correctly detects the dimension from the coordinate array length.

---

#### 4. Path with no valid route (points outside navigation mesh)

**Call:**
```json
{
  "start": [9999, 9999],
  "end": [8888, 8888],
  "dimension": "2d"
}
```

**Expected result:**
- Empty path array `[]` or closest reachable points returned.
- No crash or unhandled error.

**What to check:** Behavior when pathfinding is impossible. Verify that an empty array or nearest points are returned, not a crash.

---

#### 5. Edge case — start equals end

**Call:**
```json
{
  "start": [5, 5],
  "end": [5, 5],
  "dimension": "2d"
}
```

**Expected result:**
- Path contains just the start/end point, or is empty (no movement needed).

**What to check:** Edge case. Verify that no error is returned.

---

#### 6. Edge case — empty arrays for start/end

**Call:**
```json
{
  "start": [],
  "end": []
}
```

**Expected result:**
- Error: invalid coordinates. Arrays must have at least 2 elements.

**What to check:** The schema `z.array(z.number())` has no `.min()`, so an empty array will pass Zod validation. The error will come from the Godot plugin. This is a potential schema bug — consider adding `.min(2)`.

---

#### 7. Edge case — mixed dimension arrays

**Call:**
```json
{
  "start": [1, 2],
  "end": [3, 4, 5]
}
```

**Expected result:**
- Error or inconsistent behavior. One array is 2D, other is 3D.

**What to check:** This is another potential bug — the schema does not verify that start and end have the same dimension. The Godot plugin may handle this differently.

---

## Tool: `setup_navigation_link`

**Description:** Add a NavigationLink2D or NavigationLink3D for connecting navigation regions.

**Handler:** Calls `navigation/setup_link` on the Godot bridge.

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `parent_path` | `string` | no | scene root | Parent node path |
| `dimension` | `'2d' \| '3d'` | no | `'2d'` | Navigation dimension |
| `name` | `string` | no | — | Node name |
| `properties` | `Record<string, unknown>` | no | — | Link properties (start_position, end_position, bidirectional, enabled, navigation_layers) |

**Note:** Unlike `setup_navigation_region` and `setup_navigation_agent`, this tool does NOT have a `path` parameter. The link node is created as a child of `parent_path` (or scene root) with the given `name`. This is a design inconsistency — verify behavior.

### Test Scenarios

#### 1. Happy path — 2D link between two regions

**Precondition:** Two NavigationRegion2D nodes exist (create via `setup_navigation_region`).

**Call:**
```json
{
  "dimension": "2d",
  "name": "LinkAtoB",
  "properties": {
    "start_position": [10, 0],
    "end_position": [20, 0],
    "bidirectional": true,
    "enabled": true
  }
}
```

**Expected result:**
- A `NavigationLink2D` node named `LinkAtoB` is created at scene root.
- Link connects position `[10, 0]` to `[20, 0]`.
- Link is bidirectional and enabled.

**What to check:** Verify that the node was created without a `path` parameter. Verify `start_position` and `end_position` properties by reading the node.

---

#### 2. 3D link with parent and navigation layers

**Call:**
```json
{
  "parent_path": "Level",
  "dimension": "3d",
  "name": "TeleportLink",
  "properties": {
    "start_position": [0, 0, 0],
    "end_position": [100, 0, 100],
    "bidirectional": false,
    "enabled": true,
    "navigation_layers": 1
  }
}
```

**Expected result:**
- `NavigationLink3D` created as child of `Level`.
- One-directional link (from start to end only).
- Navigation layer set to 1.

**What to check:** `bidirectional: false` means a one-way connection. Verify that pathfinding respects the direction.

---

#### 3. Link with minimal params

**Call:**
```json
{
  "properties": {
    "start_position": [0, 0],
    "end_position": [5, 5]
  }
}
```

**Expected result:**
- `NavigationLink2D` created at scene root with default name.
- Link has start and end positions set.

**What to check:** The node name will be automatically generated by Godot (e.g., `NavigationLink2D`). Verify that `start_position` and `end_position` are correctly recognized as number arrays.

---

#### 4. Edge case — no properties provided

**Call:**
```json
{
  "name": "EmptyLink"
}
```

**Expected result:**
- Link node created with default Godot properties.
- Start and end positions default to `[0,0,0]`.

**What to check:** A connection without start/end positions is useless for navigation, but should not cause an error.

---

#### 5. Edge case — conflicting parent_path and name

**Call:**
```json
{
  "parent_path": "SomeParent",
  "name": "Link1"
}
```

**Expected result:**
- Link created as child of `SomeParent` with name `Link1`.
- Full path: `SomeParent/Link1`.

**What to check:** Since there is no `path` parameter, `name` + `parent_path` determine the location. Verify that this works correctly.

---

## Tool: `remove_navigation_region`

**Description:** Remove a navigation region node from the scene.

**Handler:** Calls `navigation/remove_region` on the Godot bridge.

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `node_path` | `string` (NodePath) | **yes** | — | Path to the navigation region node to remove |

**Note:** Parameter name is `node_path`, not `path` — inconsistent with creation tools.

### Test Scenarios

#### 1. Happy path — remove existing region

**Precondition:** `setup_navigation_region` → `{"path": "NavRegion"}`.

**Call:**
```json
{
  "node_path": "NavRegion"
}
```

**Expected result:**
- Node `NavRegion` is removed from the scene tree.
- Success response.

**What to check:** Verify that the node is actually deleted — try `get_navigation_info` on the same path, expect a "node not found" error.

---

#### 2. Remove region that has a baked mesh

**Precondition:**
1. `setup_navigation_region` → `{"path": "BakedRegion"}`
2. `bake_navigation_mesh` → `{"path": "BakedRegion"}`

**Call:**
```json
{
  "node_path": "BakedRegion"
}
```

**Expected result:**
- Region with baked mesh removed cleanly.
- No orphaned mesh data.

**What to check:** Verify that deleting a region with a baked mesh does not leave "orphaned data" in the navigation map.

---

#### 3. Edge case — remove nonexistent node

**Call:**
```json
{
  "node_path": "NonexistentRegion"
}
```

**Expected result:**
- Error: node not found.

**What to check:** Verify `isError: true` and a meaningful error message.

---

#### 4. Edge case — remove node that is not a NavigationRegion

**Precondition:** Create a non-navigation node (e.g., a Sprite2D named `MySprite`).

**Call:**
```json
{
  "node_path": "MySprite"
}
```

**Expected result:**
- Error: node is not a NavigationRegion, or silent failure.

**What to check:** The Godot plugin should verify the node type before deletion. If it deletes any node — that's a bug.

---

## Tool: `remove_navigation_agent`

**Description:** Remove a navigation agent node from the scene.

**Handler:** Calls `navigation/remove_agent` on the Godot bridge.

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `node_path` | `string` (NodePath) | **yes** | — | Path to the navigation agent node to remove |

### Test Scenarios

#### 1. Happy path — remove existing agent

**Precondition:** `setup_navigation_agent` → `{"path": "Player/NavAgent"}`.

**Call:**
```json
{
  "node_path": "Player/NavAgent"
}
```

**Expected result:**
- Agent node removed from scene tree.
- Parent node `Player` remains.

**What to check:** Verify that only the agent is deleted, not the parent node.

---

#### 2. Remove 3D agent

**Precondition:** `setup_navigation_agent` → `{"path": "EnemyAgent", "dimension": "3d"}`.

**Call:**
```json
{
  "node_path": "EnemyAgent"
}
```

**Expected result:**
- `NavigationAgent3D` removed.

**What to check:** It doesn't matter — whether 2D or 3D agent, deletion should work the same way.

---

#### 3. Edge case — remove nonexistent agent

**Call:**
```json
{
  "node_path": "GhostAgent"
}
```

**Expected result:**
- Error: node not found.

---

## Tool: `remove_navigation_link`

**Description:** Remove a navigation link node from the scene.

**Handler:** Calls `navigation/remove_link` on the Godot bridge.

**Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `node_path` | `string` (NodePath) | **yes** | — | Path to the navigation link node to remove |

### Test Scenarios

#### 1. Happy path — remove existing link

**Precondition:** `setup_navigation_link` → `{"name": "MyLink", "properties": {"start_position": [0,0], "end_position": [10,10]}}`.

**Call:**
```json
{
  "node_path": "MyLink"
}
```

**Expected result:**
- Link node removed from scene tree.
- Success response.

**What to check:** Verify that the node is deleted. If the link was the only connection between regions, pathfinding between them should become impossible.

---

#### 2. Remove link with parent

**Precondition:** `setup_navigation_link` → `{"parent_path": "Level", "name": "BridgeLink", ...}`.

**Call:**
```json
{
  "node_path": "Level/BridgeLink"
}
```

**Expected result:**
- Link removed, parent `Level` preserved.

---

#### 3. Edge case — remove nonexistent link

**Call:**
```json
{
  "node_path": "PhantomLink"
}
```

**Expected result:**
- Error: node not found.

---

## Full Workflow Test — End-to-End Navigation Setup

This sequence tests all tools together in a realistic workflow.

### Step-by-step sequence:

```
1. create_scene        → {"scene_path": "res://test_nav.tscn", "root_type": "Node2D"}
2. setup_navigation_region → {"path": "MainNav", "dimension": "2d"}
3. setup_navigation_region → {"path": "SecondaryNav", "dimension": "2d"}
4. setup_navigation_link   → {"name": "RegionLink", "properties": {"start_position": [100, 0], "end_position": [200, 0], "bidirectional": true}}
5. bake_navigation_mesh    → {"path": "MainNav"}
6. bake_navigation_mesh    → {"path": "SecondaryNav"}
7. get_navigation_info     → {"path": "MainNav"}
8. set_navigation_layers   → {"path": "MainNav", "layer": 1}
9. set_navigation_layers   → {"path": "SecondaryNav", "layer": 2}
10. find_navigation_path   → {"start": [0, 0], "end": [250, 0], "dimension": "2d"}
11. setup_navigation_agent → {"path": "Player/Agent", "dimension": "2d", "properties": {"radius": 0.5, "speed": 3.0}}
12. remove_navigation_agent → {"node_path": "Player/Agent"}
13. remove_navigation_link → {"node_path": "RegionLink"}
14. remove_navigation_region → {"node_path": "SecondaryNav"}
15. remove_navigation_region → {"node_path": "MainNav"}
```

**Expected:**
- Steps 1-9: All succeed, building up the navigation infrastructure.
- Step 10: Returns a path array (may be empty if regions don't connect properly).
- Steps 11-15: Cleanup — all removals succeed.

**What to check:**
- Deletion order: agents and links first, then regions (to avoid deleting parent nodes before child nodes).
- If `SecondaryNav` and `MainNav` are not connected by a link, `find_navigation_path` will not find a path between points in different regions.
- Step 4 (link) is executed before baking meshes — the link should persist and work after baking.

---

## Schema Observations / Potential Bugs

1. **`find_navigation_path.start` / `end` lack `.min(2)`**: The schema is `z.array(z.number())` with no minimum length. Empty arrays `[]` will pass Zod validation but fail in Godot. Recommend: `z.array(z.number()).min(2)`.

2. **`find_navigation_path` dimension mismatch**: No validation that `start` and `end` have the same array length. Passing `[x, y]` for start and `[x, y, z]` for end is allowed by the schema but may cause undefined behavior.

3. **`set_navigation_layers` description vs schema mismatch**: Description says "layers and/or mask" but schema only has `layer`. No `mask` parameter exists.

4. **`setup_navigation_link` missing `path` parameter**: Unlike `setup_navigation_region` and `setup_navigation_agent`, the link tool has no `path` field. The node path is determined implicitly by `parent_path` + `name`. This is an inconsistency in the API surface.

5. **`remove_*` tools use `node_path` while creation tools use `path`**: Parameter naming is inconsistent. `remove_navigation_region` uses `node_path`, but `setup_navigation_region` uses `path`.

6. **`setup_navigation_region` / `setup_navigation_agent` have both `path` and `name`**: If both are provided, it's unclear which determines the actual scene-tree node name. This should be documented or one should take precedence.
