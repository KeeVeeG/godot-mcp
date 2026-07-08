# Navigation Tools Test Plan

**Source file:** `server/src/tools/navigation.ts`
**Godot bridge method prefix:** `navigation/`
**Shared schemas used:** `NodePath`, `OptionalProperties`, `OptionalDimension` (from `shared-types.ts`)
**Handler pattern:** All tools call `callGodot(bridge, 'navigation/<action>', args)`

---

## Shared Type Definitions

| Schema | Type | Constraints |
|--------|------|-------------|
| `NodePath` | `string` | Path in scene tree, e.g. `"Player/Sprite2D"`, `""` for root |
| `OptionalProperties` | `Record<string, unknown>` (optional) | Arbitrary key-value pairs; optional |
| `OptionalDimension` | `enum: "2d" \| "3d"` (optional, default varies) | Navigation dimension; auto-detected if omitted |

---

## Tool: `setup_navigation_region`

**Handler:** `callGodot(bridge, 'navigation/setup_region', args)`
**Description:** Add a NavigationRegion2D or NavigationRegion3D with optional configuration

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `parent_path` | `string` | No | — | Parent node path (omit for scene root) |
| `dimension` | `enum: "2d" \| "3d"` | No | `"2d"` | Navigation dimension |
| `name` | `string` | No | — | Node name |
| `path` | `NodePath` (string) | **Yes** | — | Node path for the navigation region |
| `properties` | `Record<string, unknown>` | No | — | Region properties (navigation_mesh, enabled, etc.) |

### Test Scenarios

#### Scenario 1: Happy path — minimal required params with default dimension
- **Description:** Create a 2D navigation region with only the required `path` parameter
- **Params:** `{ "path": "NavRegion" }`
- **Expected result:** Success response. NavigationRegion2D node created (default dimension "2d").
- **Notes:** Prerequisite: empty/new scene open; created at scene root by default.

#### Scenario 2: Explicit dimension — "2d"
- **Description:** Create a 2D navigation region with explicit dimension
- **Params:** `{ "path": "NavRegion2D", "dimension": "2d" }`
- **Expected result:** Success response. NavigationRegion2D node created.
- **Notes:** Tests explicit "2d" enum value.

#### Scenario 3: Explicit dimension — "3d"
- **Description:** Create a 3D navigation region with explicit dimension
- **Params:** `{ "path": "NavRegion3D", "dimension": "3d" }`
- **Expected result:** Success response. NavigationRegion3D node created.
- **Notes:** Tests explicit "3d" enum value.

#### Scenario 4: With custom parent_path
- **Description:** Create the navigation region under a specific parent node
- **Params:** `{ "path": "Level/NavRegion", "parent_path": "Level" }`
- **Expected result:** Success response. NavigationRegion created as a child of "Level".
- **Notes:** Prerequisite: node "Level" must exist in the scene.

#### Scenario 5: With custom name
- **Description:** Create a navigation region with a custom display name
- **Params:** `{ "path": "MyCustomNav", "name": "MyCustomNav" }`
- **Expected result:** Success response. Node created with the specified name.

#### Scenario 6: With properties
- **Description:** Create a navigation region with additional configuration properties
- **Params:** `{ "path": "ConfiguredNav", "properties": { "enabled": true, "navigation_layers": 1 } }`
- **Expected result:** Success response. NavigationRegion created with the specified properties applied.

#### Scenario 7: Missing required parameter — no path
- **Description:** Omit the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error. `path` is required (NodePath schema, non-optional).

#### Scenario 8: Edge case — invalid dimension value
- **Description:** Pass an invalid string for dimension
- **Params:** `{ "path": "BadNav", "dimension": "4d" }`
- **Expected result:** Zod validation error. `dimension` must be `"2d"` or `"3d"`.

#### Scenario 9: Edge case — empty string path
- **Description:** Pass `""` as `path`
- **Params:** `{ "path": "" }`
- **Expected result:** Godot-side behavior. May succeed (targeting scene root) or error depending on Godot plugin logic.
- **Notes:** The NodePath schema allows empty string (scene root). Whether Godot accepts this for a navigation region depends on the plugin.

#### Scenario 10: Edge case — properties with empty object
- **Description:** Pass an empty properties object
- **Params:** `{ "path": "EmptyPropsNav", "properties": {} }`
- **Expected result:** Success response. NavigationRegion created with default properties (empty object is a no-op).

---

## Tool: `setup_navigation_agent`

**Handler:** `callGodot(bridge, 'navigation/setup_agent', args)`
**Description:** Add a NavigationAgent2D or NavigationAgent3D to a node

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `parent_path` | `string` | No | — | Parent node path (omit for scene root) |
| `dimension` | `enum: "2d" \| "3d"` | No | `"2d"` | Navigation dimension |
| `name` | `string` | No | — | Node name |
| `path` | `NodePath` (string) | **Yes** | — | Node path for the navigation agent |
| `properties` | `Record<string, unknown>` | No | — | Agent properties (radius, speed, path_desired_distance, etc.) |

### Test Scenarios

#### Scenario 1: Happy path — minimal required params
- **Description:** Create a 2D navigation agent with only the required `path` parameter
- **Params:** `{ "path": "NavAgent" }`
- **Expected result:** Success response. NavigationAgent2D node created (default dimension "2d").
- **Notes:** Prerequisite: empty/new scene open.

#### Scenario 2: Explicit dimension — "2d"
- **Description:** Create a 2D navigation agent with explicit dimension
- **Params:** `{ "path": "NavAgent2D", "dimension": "2d" }`
- **Expected result:** Success response. NavigationAgent2D node created.

#### Scenario 3: Explicit dimension — "3d"
- **Description:** Create a 3D navigation agent with explicit dimension
- **Params:** `{ "path": "NavAgent3D", "dimension": "3d" }`
- **Expected result:** Success response. NavigationAgent3D node created.

#### Scenario 4: With custom parent_path
- **Description:** Create the navigation agent under a specific parent node
- **Params:** `{ "path": "Character/NavAgent", "parent_path": "Character" }`
- **Expected result:** Success response. NavigationAgent created as a child of "Character".
- **Notes:** Prerequisite: node "Character" must exist in the scene.

#### Scenario 5: With custom name
- **Description:** Create a navigation agent with a custom display name
- **Params:** `{ "path": "CustomAgent", "name": "EnemyAgent" }`
- **Expected result:** Success response. Node created with the specified name.

#### Scenario 6: With agent-specific properties
- **Description:** Create a navigation agent with radius, speed, and path distance properties
- **Params:** `{ "path": "ConfiguredAgent", "properties": { "radius": 0.5, "speed": 100, "path_desired_distance": 5.0 } }`
- **Expected result:** Success response. NavigationAgent created with the specified agent properties.

#### Scenario 7: Missing required parameter — no path
- **Description:** Omit the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error. `path` is required.

#### Scenario 8: Edge case — invalid dimension value
- **Description:** Pass an invalid string for dimension
- **Params:** `{ "path": "BadAgent", "dimension": "1d" }`
- **Expected result:** Zod validation error. `dimension` must be `"2d"` or `"3d"`.

---

## Tool: `bake_navigation_mesh`

**Handler:** `callGodot(bridge, 'navigation/bake_mesh', args)`
**Description:** Bake the navigation mesh for a NavigationRegion

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `NodePath` (string) | **Yes** | — | NavigationRegion node path |
| `properties` | `Record<string, unknown>` | No | — | Bake configuration (cell_size, cell_height, agent_radius, etc.) |

### Test Scenarios

#### Scenario 1: Happy path — minimal required params
- **Description:** Bake the navigation mesh on an existing NavigationRegion with default bake settings
- **Params:** `{ "path": "NavRegion" }`
- **Expected result:** Success response. Navigation mesh baked with default configuration.
- **Notes:** Prerequisite: A NavigationRegion node must exist in the scene.

#### Scenario 2: With custom bake properties
- **Description:** Bake with specific configuration parameters
- **Params:** `{ "path": "NavRegion", "properties": { "cell_size": 0.5, "cell_height": 0.3, "agent_radius": 0.6 } }`
- **Expected result:** Success response. Navigation mesh baked with the specified configuration.

#### Scenario 3: With partial bake properties
- **Description:** Bake with only one custom property
- **Params:** `{ "path": "NavRegion", "properties": { "agent_radius": 1.0 } }`
- **Expected result:** Success response. Navigation mesh baked with custom agent_radius, defaults for others.

#### Scenario 4: Missing required parameter — no path
- **Description:** Omit the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error. `path` is required.

#### Scenario 5: Edge case — non-existent node
- **Description:** Bake mesh for a node path that does not exist in the scene
- **Params:** `{ "path": "NonExistentRegion" }`
- **Expected result:** Error response from Godot indicating node not found.

#### Scenario 6: Edge case — wrong node type
- **Description:** Bake mesh on a node that is NOT a NavigationRegion (e.g., a Sprite2D)
- **Params:** `{ "path": "SomeSprite" }`
- **Expected result:** Error response from Godot because the node is not a NavigationRegion.
- **Notes:** Prerequisite: A non-NavigationRegion node exists at the given path.

#### Scenario 7: Edge case — empty string path
- **Description:** Pass `""` as `path` (scene root)
- **Params:** `{ "path": "" }`
- **Expected result:** Godot-side error because scene root is not a NavigationRegion. Error response.

---

## Tool: `set_navigation_layers`

**Handler:** `callGodot(bridge, 'navigation/set_layers', args)`
**Description:** Set navigation layers and/or mask for pathfinding filtering

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `NodePath` (string) | **Yes** | — | Navigation node path |
| `layer` | `number` (int, 1-32) | No | — | Navigation layer (1-32) |

### Test Scenarios

#### Scenario 1: Happy path — set layer to valid value
- **Description:** Set a navigation layer on an existing navigation node
- **Params:** `{ "path": "NavRegion", "layer": 1 }`
- **Expected result:** Success response. Navigation layer set to 1.
- **Notes:** Prerequisite: A navigation node exists at the given path.

#### Scenario 2: Layer at minimum boundary (1)
- **Description:** Set layer to the minimum valid value
- **Params:** `{ "path": "NavRegion", "layer": 1 }`
- **Expected result:** Success response. Layer set to 1.
- **Notes:** Tests `z.number().int().min(1)` boundary.

#### Scenario 3: Layer at maximum boundary (32)
- **Description:** Set layer to the maximum valid value
- **Params:** `{ "path": "NavRegion", "layer": 32 }`
- **Expected result:** Success response. Layer set to 32.
- **Notes:** Tests `z.number().int().max(32)` boundary.

#### Scenario 4: Layer at mid-range value
- **Description:** Set layer to a mid-range value
- **Params:** `{ "path": "NavRegion", "layer": 16 }`
- **Expected result:** Success response. Layer set to 16.

#### Scenario 5: Missing required parameter — no path
- **Description:** Omit the required `path` parameter
- **Params:** `{ "layer": 5 }`
- **Expected result:** Zod validation error. `path` is required.

#### Scenario 6: Edge case — layer out of range: 0
- **Description:** Try to set layer to 0 (below minimum of 1)
- **Params:** `{ "path": "NavRegion", "layer": 0 }`
- **Expected result:** Zod validation error. `layer` must be >= 1.

#### Scenario 7: Edge case — layer out of range: 33
- **Description:** Try to set layer to 33 (above maximum of 32)
- **Params:** `{ "path": "NavRegion", "layer": 33 }`
- **Expected result:** Zod validation error. `layer` must be <= 32.

#### Scenario 8: Edge case — negative layer
- **Description:** Try to set layer to a negative number
- **Params:** `{ "path": "NavRegion", "layer": -5 }`
- **Expected result:** Zod validation error. `layer` must be >= 1.

#### Scenario 9: Edge case — non-integer layer value
- **Description:** Try to set layer to a floating-point number
- **Params:** `{ "path": "NavRegion", "layer": 3.5 }`
- **Expected result:** Zod validation error. `layer` must be an integer (`.int()` constraint).

#### Scenario 10: Edge case — layer omitted (only path)
- **Description:** Call with only the path, no layer (layer is optional)
- **Params:** `{ "path": "NavRegion" }`
- **Expected result:** Success response from Godot. Behavior depends on plugin — may read current layers or do nothing.
- **Notes:** Since `layer` is optional, this is a valid call.

---

## Tool: `get_navigation_info`

**Handler:** `callGodot(bridge, 'navigation/get_info', args)`
**Description:** Get navigation map information and navigation mesh data

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `NodePath` (string) | **Yes** | — | NavigationRegion node path |

### Test Scenarios

#### Scenario 1: Happy path — get info for a valid NavigationRegion
- **Description:** Query navigation info for an existing NavigationRegion node
- **Params:** `{ "path": "NavRegion" }`
- **Expected result:** Success response. JSON containing navigation map information and mesh data (vertices, polygons, etc.).
- **Notes:** Prerequisite: A NavigationRegion must exist in the scene, ideally with a baked navmesh.

#### Scenario 2: NavigationRegion without baked mesh
- **Description:** Query navigation info for a region that has not been baked
- **Params:** `{ "path": "UnbakedRegion" }`
- **Expected result:** Success response, but navigation data may be empty or indicate no baked mesh.
- **Notes:** Prerequisite: An unbaked NavigationRegion exists.

#### Scenario 3: Missing required parameter — no path
- **Description:** Omit the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error. `path` is required.

#### Scenario 4: Edge case — non-existent node
- **Description:** Call with a path that does not exist
- **Params:** `{ "path": "GhostNode" }`
- **Expected result:** Error response from Godot indicating node not found.

#### Scenario 5: Edge case — wrong node type
- **Description:** Call with a path to a non-NavigationRegion node
- **Params:** `{ "path": "Sprite2D" }`
- **Expected result:** Error response from Godot because the node is not a NavigationRegion.
- **Notes:** Prerequisite: A non-NavigationRegion node exists at the given path.

#### Scenario 6: Edge case — empty string path (scene root)
- **Description:** Pass `""` as `path`
- **Params:** `{ "path": "" }`
- **Expected result:** Godot-side error because scene root is not a NavigationRegion.

---

## Tool: `find_navigation_path`

**Handler:** `callGodot(bridge, 'navigation/find_path', args)`
**Description:** Find a navigation path between two points

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `start` | `number[]` | **Yes** | — | Start position [x, y] or [x, y, z] |
| `end` | `number[]` | **Yes** | — | End position [x, y] or [x, y, z] |
| `dimension` | `enum: "2d" \| "3d"` | No | — | Dimension type (auto-detected if omitted) |

### Test Scenarios

#### Scenario 1: Happy path — 2D pathfinding with start and end (3 params)
- **Description:** Find a navigation path between two 2D points with everything specified
- **Params:** `{ "start": [0, 0], "end": [100, 100], "dimension": "2d" }`
- **Expected result:** Success response. JSON containing an array of path points between start and end, or an empty array if no path exists.
- **Notes:** Prerequisite: A NavigationRegion with a baked navmesh must exist in the scene covering the area between start and end.

#### Scenario 2: 3D pathfinding
- **Description:** Find a navigation path between two 3D points
- **Params:** `{ "start": [0, 0, 0], "end": [10, 5, 10], "dimension": "3d" }`
- **Expected result:** Success response. JSON containing 3D path points.
- **Notes:** Prerequisite: A 3D NavigationRegion with a baked navmesh must exist.

#### Scenario 3: Auto-detect dimension (dimension omitted)
- **Description:** Call with only start and end, letting Godot auto-detect dimension
- **Params:** `{ "start": [0, 0], "end": [50, 50] }`
- **Expected result:** Success response. Godot auto-detects the navigation dimension from the existing navigation data.
- **Notes:** This tests the `OptionalDimension` default behavior (no default value — ends up undefined, auto-detect).

#### Scenario 4: 2D points with explicit "2d" dimension
- **Description:** Use 2D coordinates with explicit "2d" dimension
- **Params:** `{ "start": [-10, -10], "end": [10, 10], "dimension": "2d" }`
- **Expected result:** Success response. Path computed in 2D space.

#### Scenario 5: 3D points with explicit "3d" dimension
- **Description:** Use 3D coordinates with explicit "3d" dimension
- **Params:** `{ "start": [0, 0, 0], "end": [5, 5, 5], "dimension": "3d" }`
- **Expected result:** Success response. Path computed in 3D space.

#### Scenario 6: Same start and end points
- **Description:** Start and end are the same position
- **Params:** `{ "start": [10, 10], "end": [10, 10], "dimension": "2d" }`
- **Expected result:** Success response. Path should contain a single point or very short path.
- **Notes:** Edge case for pathfinding algorithm — should not error.

#### Scenario 7: Unreachable destination
- **Description:** Start and end are in disconnected navigation areas
- **Params:** `{ "start": [0, 0], "end": [9999, 9999], "dimension": "2d" }`
- **Expected result:** Success response but path array is empty (no valid path found). Not an error — this is a valid query result.

#### Scenario 8: Missing required parameter — no start
- **Description:** Omit the required `start` parameter
- **Params:** `{ "end": [50, 50] }`
- **Expected result:** Zod validation error. `start` is required.

#### Scenario 9: Missing required parameter — no end
- **Description:** Omit the required `end` parameter
- **Params:** `{ "start": [0, 0] }`
- **Expected result:** Zod validation error. `end` is required.

#### Scenario 10: Missing both required parameters
- **Description:** Omit both start and end
- **Params:** `{}`
- **Expected result:** Zod validation error. Both `start` and `end` are required.

#### Scenario 11: Edge case — start is empty array
- **Description:** Pass an empty array for start
- **Params:** `{ "start": [], "end": [50, 50] }`
- **Expected result:** Zod validation error. `start` must be a non-empty array of numbers.

#### Scenario 12: Edge case — start with non-numeric values
- **Description:** Pass an array with string values for start
- **Params:** `{ "start": ["x", "y"], "end": [50, 50] }`
- **Expected result:** Zod validation error. Array elements must be numbers.

#### Scenario 13: Edge case — invalid dimension value
- **Description:** Pass an invalid dimension string
- **Params:** `{ "start": [0, 0], "end": [10, 10], "dimension": "3d_uhd" }`
- **Expected result:** Zod validation error. `dimension` must be `"2d"` or `"3d"`.

#### Scenario 14: Edge case — single-element array for start
- **Description:** Pass `[0]` instead of a coordinate pair/triple
- **Params:** `{ "start": [0], "end": [50, 50] }`
- **Expected result:** Zod validation passes (it is `z.array(z.number())` with no min length). Godot-side behavior may vary — likely an error because a single value is not a valid position.

---

## Tool: `setup_navigation_link`

**Handler:** `callGodot(bridge, 'navigation/setup_link', args)`
**Description:** Add a NavigationLink2D or NavigationLink3D for connecting navigation regions

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `parent_path` | `string` | No | — | Parent node path (omit for scene root) |
| `dimension` | `enum: "2d" \| "3d"` | No | `"2d"` | Navigation dimension |
| `name` | `string` | No | — | Node name |
| `properties` | `Record<string, unknown>` | No | — | Link properties (start_position, end_position, bidirectional, enabled, navigation_layers) |

### Test Scenarios

#### Scenario 1: Happy path — minimal params, creates 2D link with defaults
- **Description:** Create a 2D navigation link with no optional params
- **Params:** `{}`
- **Expected result:** Success response. NavigationLink2D created at scene root with default properties.
- **Notes:** Unlike other setup tools, `path` is NOT a parameter for this tool. The link is added as a direct child.

#### Scenario 2: Explicit dimension — "2d"
- **Description:** Create a 2D navigation link with explicit dimension
- **Params:** `{ "dimension": "2d" }`
- **Expected result:** Success response. NavigationLink2D created.

#### Scenario 3: Explicit dimension — "3d"
- **Description:** Create a 3D navigation link with explicit dimension
- **Params:** `{ "dimension": "3d" }`
- **Expected result:** Success response. NavigationLink3D created.

#### Scenario 4: With custom parent_path
- **Description:** Create the navigation link under a specific parent node
- **Params:** `{ "parent_path": "Level" }`
- **Expected result:** Success response. NavigationLink created as a child of "Level".
- **Notes:** Prerequisite: node "Level" must exist.

#### Scenario 5: With custom name
- **Description:** Create a navigation link with a custom name
- **Params:** `{ "name": "JumpLink" }`
- **Expected result:** Success response. Link created with the specified name.

#### Scenario 6: With link properties
- **Description:** Create a navigation link with start/end positions, bidirectional, and navigation layers
- **Params:** `{ "properties": { "start_position": [0, 0], "end_position": [10, 0], "bidirectional": true, "enabled": true, "navigation_layers": 1 } }`
- **Expected result:** Success response. NavigationLink created with all specified properties.

#### Scenario 7: All optional params together
- **Description:** Combine all optional parameters in one call
- **Params:** `{ "parent_path": "Level", "dimension": "2d", "name": "BridgeLink", "properties": { "start_position": [0, 5], "end_position": [10, 5], "bidirectional": false } }`
- **Expected result:** Success response. NavigationLink2D created under "Level" with the custom name and properties.

#### Scenario 8: Edge case — invalid dimension value
- **Description:** Pass an invalid dimension string
- **Params:** `{ "dimension": "4d" }`
- **Expected result:** Zod validation error. `dimension` must be `"2d"` or `"3d"`.

---

## Tool: `remove_navigation_region`

**Handler:** `callGodot(bridge, 'navigation/remove_region', args)`
**Description:** Remove a navigation region node from the scene

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `NodePath` (string) | **Yes** | — | Path to the navigation region node to remove |

### Test Scenarios

#### Scenario 1: Happy path — remove an existing NavigationRegion
- **Description:** Remove a NavigationRegion that exists in the scene
- **Params:** `{ "node_path": "NavRegion" }`
- **Expected result:** Success response. NavigationRegion node removed from the scene.
- **Notes:** Prerequisite: A NavigationRegion exists at the given path.

#### Scenario 2: Remove nested NavigationRegion (path with slashes)
- **Description:** Remove a NavigationRegion that is a child of another node
- **Params:** `{ "node_path": "Level/NavRegion" }`
- **Expected result:** Success response. Child NavigationRegion node removed.
- **Notes:** Prerequisite: "Level/NavRegion" exists.

#### Scenario 3: Missing required parameter — no node_path
- **Description:** Omit the required `node_path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error. `node_path` is required.

#### Scenario 4: Edge case — non-existent node
- **Description:** Try to remove a node that doesn't exist
- **Params:** `{ "node_path": "GhostRegion" }`
- **Expected result:** Error response from Godot indicating node not found.

#### Scenario 5: Edge case — wrong node type
- **Description:** Try to remove a path to a non-NavigationRegion node
- **Params:** `{ "node_path": "Sprite2D" }`
- **Expected result:** Godot-side behavior may vary — may succeed (removing the node regardless of type) or error if the plugin validates node type.
- **Notes:** Prerequisite: A non-NavigationRegion node exists at the given path. The tool name implies specific removal but the NodePath schema does not restrict type.

#### Scenario 6: Edge case — empty string path (scene root)
- **Description:** Pass `""` as `node_path`
- **Params:** `{ "node_path": "" }`
- **Expected result:** Godot-side error. Attempting to remove the scene root should fail.

---

## Tool: `remove_navigation_agent`

**Handler:** `callGodot(bridge, 'navigation/remove_agent', args)`
**Description:** Remove a navigation agent node from the scene

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `NodePath` (string) | **Yes** | — | Path to the navigation agent node to remove |

### Test Scenarios

#### Scenario 1: Happy path — remove an existing NavigationAgent
- **Description:** Remove a NavigationAgent that exists in the scene
- **Params:** `{ "node_path": "NavAgent" }`
- **Expected result:** Success response. NavigationAgent node removed from the scene.
- **Notes:** Prerequisite: A NavigationAgent exists at the given path.

#### Scenario 2: Remove nested NavigationAgent (path with slashes)
- **Description:** Remove a NavigationAgent that is a child of another node
- **Params:** `{ "node_path": "Character/NavAgent" }`
- **Expected result:** Success response. Child NavigationAgent node removed.
- **Notes:** Prerequisite: "Character/NavAgent" exists.

#### Scenario 3: Missing required parameter — no node_path
- **Description:** Omit the required `node_path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error. `node_path` is required.

#### Scenario 4: Edge case — non-existent node
- **Description:** Try to remove a node that doesn't exist
- **Params:** `{ "node_path": "GhostAgent" }`
- **Expected result:** Error response from Godot indicating node not found.

#### Scenario 5: Edge case — wrong node type
- **Description:** Try to remove a path to a non-NavigationAgent node
- **Params:** `{ "node_path": "Sprite2D" }`
- **Expected result:** Godot-side behavior may vary — may succeed (removing the node regardless of type) or error if the plugin validates node type.

---

## Tool: `remove_navigation_link`

**Handler:** `callGodot(bridge, 'navigation/remove_link', args)`
**Description:** Remove a navigation link node from the scene

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `node_path` | `NodePath` (string) | **Yes** | — | Path to the navigation link node to remove |

### Test Scenarios

#### Scenario 1: Happy path — remove an existing NavigationLink
- **Description:** Remove a NavigationLink that exists in the scene
- **Params:** `{ "node_path": "NavLink" }`
- **Expected result:** Success response. NavigationLink node removed from the scene.
- **Notes:** Prerequisite: A NavigationLink exists at the given path.

#### Scenario 2: Remove nested NavigationLink (path with slashes)
- **Description:** Remove a NavigationLink that is a child of another node
- **Params:** `{ "node_path": "Level/NavLink" }`
- **Expected result:** Success response. Child NavigationLink node removed.
- **Notes:** Prerequisite: "Level/NavLink" exists.

#### Scenario 3: Missing required parameter — no node_path
- **Description:** Omit the required `node_path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error. `node_path` is required.

#### Scenario 4: Edge case — non-existent node
- **Description:** Try to remove a node that doesn't exist
- **Params:** `{ "node_path": "GhostLink" }`
- **Expected result:** Error response from Godot indicating node not found.

#### Scenario 5: Edge case — wrong node type
- **Description:** Try to remove a path to a non-NavigationLink node
- **Params:** `{ "node_path": "Sprite2D" }`
- **Expected result:** Godot-side behavior may vary — may succeed (removing the node regardless of type) or error if the plugin validates node type.

---

## Summary

| # | Tool | Required Params | Optional Params | Enum Params |
|---|------|----------------|-----------------|-------------|
| 1 | `setup_navigation_region` | `path` | `parent_path`, `dimension`, `name`, `properties` | `dimension`: `"2d"`, `"3d"` (default `"2d"`) |
| 2 | `setup_navigation_agent` | `path` | `parent_path`, `dimension`, `name`, `properties` | `dimension`: `"2d"`, `"3d"` (default `"2d"`) |
| 3 | `bake_navigation_mesh` | `path` | `properties` | — |
| 4 | `set_navigation_layers` | `path` | `layer` (int 1-32) | — |
| 5 | `get_navigation_info` | `path` | — | — |
| 6 | `find_navigation_path` | `start`, `end` | `dimension` | `dimension`: `"2d"`, `"3d"` (auto-detect if omitted) |
| 7 | `setup_navigation_link` | — (all params optional) | `parent_path`, `dimension`, `name`, `properties` | `dimension`: `"2d"`, `"3d"` (default `"2d"`) |
| 8 | `remove_navigation_region` | `node_path` | — | — |
| 9 | `remove_navigation_agent` | `node_path` | — | — |
| 10 | `remove_navigation_link` | `node_path` | — | — |

**Total scenarios:** 79 test scenarios across 10 tools.
