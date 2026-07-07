# Navigation Tools Test Plan

**Source file:** `server/src/tools/navigation.ts`  
**Module purpose:** Navigation system — 10 tools covering NavigationRegion creation/removal, NavigationAgent setup/removal, NavigationLink setup/removal, navmesh baking, layer configuration, pathfinding queries, and navigation info retrieval.

**Shared type definitions (from `shared-types.ts`):**

| Type | Zod schema | Notes |
|------|-----------|-------|
| `NodePath` | `z.string()` | Scene tree node path, e.g. `"Player/NavAgent"` or `""` for root |
| `OptionalDimension` | `z.enum(['2d', '3d']).optional()` | Navigation dimension; auto-detected if omitted |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | Optional property key-value pairs |

---

## Tool 1: `setup_navigation_region`

**Description:** Add a NavigationRegion2D or NavigationRegion3D with optional configuration.  
**Handler route:** `navigation/setup_region`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `NodePath` (string) | ✅ Yes | — | Node path for the navigation region |
| `dimension` | `enum: "2d" \| "3d"` | No | `"2d"` | Navigation dimension |
| `parent_path` | `string` | No | — | Parent node path (omit for scene root) |
| `name` | `string` | No | — | Node name |
| `properties` | `Record<string, unknown>` | No | — | Region properties (`navigation_mesh`, `enabled`, etc.) |

### Test Scenarios

#### 1.1 Happy path — add 2D navigation region at scene root (minimum params)
- **Params:** `{ "path": "NavRegion" }`
- **Expected result:** Success — a NavigationRegion2D node added to scene root named "NavRegion" (dimension defaults to "2d")
- **Notes:** `path` is the only required parameter; `dimension` defaults to "2d"

#### 1.2 Happy path — add 2D navigation region with explicit dimension
- **Params:** `{ "path": "NavRegion2D", "dimension": "2d" }`
- **Expected result:** Success — a NavigationRegion2D node added to scene root
- **Notes:** Validates explicit "2d" enum value

#### 1.3 Happy path — add 3D navigation region
- **Params:** `{ "path": "NavRegion3D", "dimension": "3d" }`
- **Expected result:** Success — a NavigationRegion3D node added to scene root
- **Notes:** Validates "3d" enum value — no default, must be explicit

#### 1.4 Happy path — add region under specific parent
- **Params:** `{ "path": "World/Zone1", "parent_path": "World" }`
- **Expected result:** Success — NavigationRegion2D added as child of "World" with name "Zone1"
- **Notes:** Validates `parent_path` with existing node

#### 1.5 Happy path — add region with custom name
- **Params:** `{ "path": "MyNavRegion", "name": "LevelNavMesh" }`
- **Expected result:** Success — NavigationRegion2D named "LevelNavMesh" at path "MyNavRegion"
- **Notes:** Validates custom `name` parameter

#### 1.6 Happy path — add region with properties
- **Params:** `{ "path": "ConfiguredRegion", "dimension": "3d", "properties": { "enabled": true, "navigation_layers": 1 } }`
- **Expected result:** Success — NavigationRegion3D created with enabled=true and navigation_layers=1
- **Notes:** Validates `properties` object with multiple key-value pairs

#### 1.7 Happy path — add region with all parameters
- **Params:** `{ "path": "FullRegion", "dimension": "3d", "parent_path": "Level", "name": "FullNav", "properties": { "enabled": true, "navigation_layers": 1, "bake_navigation_mesh": true } }`
- **Expected result:** Success — fully configured NavigationRegion3D added
- **Notes:** Full parameter coverage

#### 1.8 Edge case — missing required `path`
- **Params:** `{}`
- **Expected result:** Zod validation error — `path` is required
- **Notes:** Test input schema validation

#### 1.9 Edge case — invalid `dimension` enum value
- **Params:** `{ "path": "BadRegion", "dimension": "4d" }`
- **Expected result:** Zod validation error — invalid enum value (only "2d" and "3d" are valid)
- **Notes:** Enum validation

#### 1.10 Edge case — empty string `path`
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot — empty node path is invalid
- **Notes:** Validates behavior with empty path

#### 1.11 Edge case — parent_path to non-existent node
- **Params:** `{ "path": "OrphanRegion", "parent_path": "NonExistentParent" }`
- **Expected result:** Error from Godot — parent node not found
- **Notes:** Validates error propagation for bad parent

#### 1.12 Edge case — duplicate region path (same name as existing node)
- **Params:** `{ "path": "NavRegion" }` (run twice)
- **Expected result:** Second call may error (duplicate node name) or Godot may auto-rename
- **Notes:** Godot behavior for duplicate sibling names — may append number or reject

#### 1.13 Edge case — empty `properties` object
- **Params:** `{ "path": "EmptyPropsRegion", "properties": {} }`
- **Expected result:** Success — same as omitting properties, region created with defaults
- **Notes:** Should behave identically to 1.1

#### 1.14 Edge case — invalid property key
- **Params:** `{ "path": "BadPropsRegion", "properties": { "nonexistent_prop": 42 } }`
- **Expected result:** Error from Godot — unknown property, or silently ignored
- **Notes:** Behavior depends on Godot's property validation

---

## Tool 2: `setup_navigation_agent`

**Description:** Add a NavigationAgent2D or NavigationAgent3D to a node.  
**Handler route:** `navigation/setup_agent`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `NodePath` (string) | ✅ Yes | — | Node path for the navigation agent |
| `dimension` | `enum: "2d" \| "3d"` | No | `"2d"` | Navigation dimension |
| `parent_path` | `string` | No | — | Parent node path (omit for scene root) |
| `name` | `string` | No | — | Node name |
| `properties` | `Record<string, unknown>` | No | — | Agent properties (`radius`, `speed`, `path_desired_distance`, etc.) |

### Test Scenarios

#### 2.1 Happy path — add 2D navigation agent at scene root (minimum params)
- **Params:** `{ "path": "NavAgent" }`
- **Expected result:** Success — a NavigationAgent2D node added to scene root named "NavAgent" (dimension defaults to "2d")
- **Notes:** `path` is the only required parameter

#### 2.2 Happy path — add 2D navigation agent with explicit dimension
- **Params:** `{ "path": "NavAgent2D", "dimension": "2d" }`
- **Expected result:** Success — a NavigationAgent2D node added
- **Notes:** Validates explicit "2d" enum value

#### 2.3 Happy path — add 3D navigation agent
- **Params:** `{ "path": "NavAgent3D", "dimension": "3d" }`
- **Expected result:** Success — a NavigationAgent3D node added
- **Notes:** Validates "3d" enum value

#### 2.4 Happy path — add agent under specific parent
- **Params:** `{ "path": "Player/Navigator", "parent_path": "Player" }`
- **Expected result:** Success — NavigationAgent2D added as child of "Player"
- **Notes:** Requires an existing "Player" node in the scene

#### 2.5 Happy path — add agent with custom name
- **Params:** `{ "path": "EnemyAgent", "name": "PatrolAgent" }`
- **Expected result:** Success — NavigationAgent2D named "PatrolAgent"
- **Notes:** Validates custom `name` parameter

#### 2.6 Happy path — add agent with agent properties
- **Params:** `{ "path": "SmartAgent", "properties": { "radius": 0.5, "speed": 200, "path_desired_distance": 10, "target_desired_distance": 5 } }`
- **Expected result:** Success — NavigationAgent2D created with specified radius, speed, and distance thresholds
- **Notes:** Validates `properties` with navigation-specific agent parameters

#### 2.7 Happy path — add 3D agent with full properties
- **Params:** `{ "path": "DroneAgent", "dimension": "3d", "properties": { "radius": 1.0, "speed": 300, "path_max_distance": 500, "navigation_layers": 1 } }`
- **Expected result:** Success — NavigationAgent3D with full configuration
- **Notes:** Validates 3D agent with navigation-specific properties

#### 2.8 Happy path — add agent with all optional parameters
- **Params:** `{ "path": "FullAgent", "dimension": "3d", "parent_path": "NPC", "name": "FullNavAgent", "properties": { "radius": 0.8, "speed": 150 } }`
- **Expected result:** Success — fully configured NavigationAgent3D under "NPC" parent
- **Notes:** Full parameter coverage

#### 2.9 Edge case — missing required `path`
- **Params:** `{}`
- **Expected result:** Zod validation error — `path` is required
- **Notes:** Test input schema validation

#### 2.10 Edge case — invalid `dimension` enum value
- **Params:** `{ "path": "BadAgent", "dimension": "4d" }`
- **Expected result:** Zod validation error — invalid enum value
- **Notes:** Enum validation — only "2d" and "3d"

#### 2.11 Edge case — empty string `path`
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot — empty node path is invalid
- **Notes:** Validates behavior with empty path

#### 2.12 Edge case — parent_path to non-existent node
- **Params:** `{ "path": "OrphanAgent", "parent_path": "GhostParent" }`
- **Expected result:** Error from Godot — parent node not found
- **Notes:** Validates error propagation

#### 2.13 Edge case — invalid agent property
- **Params:** `{ "path": "BadPropAgent", "properties": { "flying_speed": 500 } }`
- **Expected result:** Error from Godot — unknown property or silently ignored
- **Notes:** "flying_speed" is not a valid NavigationAgent property

---

## Tool 3: `bake_navigation_mesh`

**Description:** Bake the navigation mesh for a NavigationRegion.  
**Handler route:** `navigation/bake_mesh`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | ✅ Yes | NavigationRegion node path |
| `properties` | `Record<string, unknown>` | No | Bake configuration (`cell_size`, `cell_height`, `agent_radius`, etc.) |

### Test Scenarios

#### 3.1 Happy path — bake navmesh on a 2D region (minimum params)
- **Params:** `{ "path": "NavRegion" }`
- **Expected result:** Success — navmesh baked on the NavigationRegion2D with default bake settings
- **Notes:** Requires NavRegion created by tool #1. No properties required.

#### 3.2 Happy path — bake navmesh on a 3D region
- **Params:** `{ "path": "NavRegion3D" }`
- **Expected result:** Success — navmesh baked on the NavigationRegion3D
- **Notes:** Requires NavRegion3D created by tool #1

#### 3.3 Happy path — bake with custom cell_size
- **Params:** `{ "path": "NavRegion", "properties": { "cell_size": 0.3 } }`
- **Expected result:** Success — navmesh baked with cell_size=0.3 (finer detail)
- **Notes:** Validates bake configuration parameter

#### 3.4 Happy path — bake with custom cell_height
- **Params:** `{ "path": "NavRegion3D", "properties": { "cell_height": 0.5 } }`
- **Expected result:** Success — 3D navmesh baked with cell_height=0.5
- **Notes:** Validates 3D-specific bake parameter

#### 3.5 Happy path — bake with custom agent_radius
- **Params:** `{ "path": "NavRegion", "properties": { "agent_radius": 20 } }`
- **Expected result:** Success — navmesh baked with agent_radius=20 (larger agents)
- **Notes:** Validates agent_radius bake config

#### 3.6 Happy path — bake with multiple bake properties
- **Params:** `{ "path": "NavRegion3D", "properties": { "cell_size": 0.25, "cell_height": 0.3, "agent_radius": 15, "agent_height": 40, "agent_max_climb": 0.5, "agent_max_slope": 45 } }`
- **Expected result:** Success — navmesh baked with comprehensive configuration
- **Notes:** Full bake property coverage

#### 3.7 Edge case — missing required `path`
- **Params:** `{}`
- **Expected result:** Zod validation error — `path` is required
- **Notes:** Test input schema validation

#### 3.8 Edge case — empty string `path`
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot — empty path or node not found
- **Notes:** Validates behavior with empty path

#### 3.9 Edge case — path to non-existent region
- **Params:** `{ "path": "GhostRegion" }`
- **Expected result:** Error from Godot — node not found
- **Notes:** Validates error propagation

#### 3.10 Edge case — path to non-Region node (e.g., a Sprite2D)
- **Params:** `{ "path": "Sprite2D" }`
- **Expected result:** Error from Godot — node is not a NavigationRegion, cannot bake navmesh
- **Notes:** Validates type checking on Godot side

#### 3.11 Edge case — bake on a region with no polygon/geometry defined
- **Params:** `{ "path": "NavRegion" }`
- **Expected result:** May succeed with empty navmesh or error from Godot — no geometry to bake
- **Notes:** Behavior depends on Godot; may produce empty navmesh

#### 3.12 Edge case — empty `properties` object
- **Params:** `{ "path": "NavRegion", "properties": {} }`
- **Expected result:** Success — same as omitting properties, baked with defaults
- **Notes:** Should behave identically to 3.1

#### 3.13 Edge case — invalid bake property
- **Params:** `{ "path": "NavRegion", "properties": { "invalid_bake_key": 123 } }`
- **Expected result:** Error from Godot — unknown property, or silently ignored
- **Notes:** Validates unknown property handling

#### 3.14 Edge case — negative cell_size
- **Params:** `{ "path": "NavRegion", "properties": { "cell_size": -1 } }`
- **Expected result:** Error from Godot — negative cell_size is invalid
- **Notes:** Zod allows negative floats (no min constraint); Godot should reject

#### 3.15 Edge case — bake twice on same region
- **Params:** `{ "path": "NavRegion" }` (run twice)
- **Expected result:** Both calls succeed — second bake overwrites first
- **Notes:** Idempotent operation — baking again is valid

---

## Tool 4: `set_navigation_layers`

**Description:** Set navigation layers and/or mask for pathfinding filtering.  
**Handler route:** `navigation/set_layers`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | ✅ Yes | Navigation node path |
| `layer` | `number` (int, min=1, max=32) | No | Navigation layer (1-32) |

### Test Scenarios

#### 4.1 Happy path — set navigation layer to 1 (minimum params)
- **Params:** `{ "path": "NavRegion" }`
- **Expected result:** Success — navigation layer set on "NavRegion" (default value applied by Godot, or no change if layer is omitted)
- **Notes:** `layer` is optional; omitting it is valid and leaves layer unchanged

#### 4.2 Happy path — set navigation layer to 1 (explicit)
- **Params:** `{ "path": "NavRegion", "layer": 1 }`
- **Expected result:** Success — navigation layer set to 1
- **Notes:** Lowest valid layer

#### 4.3 Happy path — set navigation layer to 32
- **Params:** `{ "path": "NavRegion", "layer": 32 }`
- **Expected result:** Success — navigation layer set to 32
- **Notes:** Highest valid layer (boundary test)

#### 4.4 Happy path — set navigation layer to mid-range value
- **Params:** `{ "path": "NavRegion", "layer": 16 }`
- **Expected result:** Success — navigation layer set to 16
- **Notes:** Validates mid-range layer

#### 4.5 Happy path — set layer on a NavigationRegion3D
- **Params:** `{ "path": "NavRegion3D", "layer": 5 }`
- **Expected result:** Success — navigation layer set on 3D region
- **Notes:** 3D regions also use navigation layers

#### 4.6 Happy path — set layer on a NavigationAgent
- **Params:** `{ "path": "NavAgent", "layer": 3 }`
- **Expected result:** Success — navigation layer set on agent node
- **Notes:** Agents also have navigation layers for filtering

#### 4.7 Happy path — set layer on a NavigationLink
- **Params:** `{ "path": "NavLink", "layer": 7 }`
- **Expected result:** Success — navigation layer set on link node
- **Notes:** Links also use navigation layers

#### 4.8 Happy path — omit layer entirely
- **Params:** `{ "path": "NavRegion" }`
- **Expected result:** Success — no layer change; current layer state preserved
- **Notes:** `layer` is optional; tool should succeed as a no-op or read-and-confirm

#### 4.9 Edge case — missing required `path`
- **Params:** `{ "layer": 1 }`
- **Expected result:** Zod validation error — `path` is required
- **Notes:** Test input schema validation

#### 4.10 Edge case — empty string `path`
- **Params:** `{ "path": "", "layer": 1 }`
- **Expected result:** Error from Godot — empty path or node not found
- **Notes:** Validates behavior with empty path

#### 4.11 Edge case — non-existent node path
- **Params:** `{ "path": "GhostLayer", "layer": 1 }`
- **Expected result:** Error from Godot — node not found
- **Notes:** Validates error propagation

#### 4.12 Edge case — layer = 0 (below minimum)
- **Params:** `{ "path": "NavRegion", "layer": 0 }`
- **Expected result:** Zod validation error — `layer` must be >= 1 (min(1))
- **Notes:** Zod `.min(1)` constraint

#### 4.13 Edge case — layer = 33 (above maximum)
- **Params:** `{ "path": "NavRegion", "layer": 33 }`
- **Expected result:** Zod validation error — `layer` must be <= 32 (max(32))
- **Notes:** Zod `.max(32)` constraint

#### 4.14 Edge case — negative layer
- **Params:** `{ "path": "NavRegion", "layer": -1 }`
- **Expected result:** Zod validation error — `layer` must be >= 1
- **Notes:** Zod `.min(1)` constraint catches negative values

#### 4.15 Edge case — non-integer layer (float)
- **Params:** `{ "path": "NavRegion", "layer": 1.5 }`
- **Expected result:** Zod validation error — `layer` must be integer (`.int()`)
- **Notes:** Zod integer validation

#### 4.16 Edge case — layer set on non-navigation node
- **Params:** `{ "path": "Sprite2D", "layer": 1 }`
- **Expected result:** Error from Godot — node does not have navigation layer property
- **Notes:** Validates type checking on Godot side

---

## Tool 5: `get_navigation_info`

**Description:** Get navigation map information and navigation mesh data.  
**Handler route:** `navigation/get_info`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `path` | `NodePath` (string) | ✅ Yes | NavigationRegion node path |

### Test Scenarios

#### 5.1 Happy path — get info on a 2D navigation region
- **Params:** `{ "path": "NavRegion" }`
- **Expected result:** Returns navigation info including region type, navigation map data, navigation mesh polygon data, and layer configuration
- **Notes:** Requires NavRegion created by tool #1

#### 5.2 Happy path — get info on a 3D navigation region
- **Params:** `{ "path": "NavRegion3D" }`
- **Expected result:** Returns 3D navigation map info with 3D-specific navmesh data (vertices, polygons)
- **Notes:** Requires NavRegion3D created by tool #1

#### 5.3 Happy path — get info after baking navmesh
- **Params:** `{ "path": "NavRegion" }`
- **Expected result:** Returns navigation info showing baked navmesh data (cell count, polygon count, bounds, etc.)
- **Notes:** Run after `bake_navigation_mesh` (tool #3). Verify info reflects the baked mesh.

#### 5.4 Happy path — get info before baking (unbaked region)
- **Params:** `{ "path": "NavRegion" }`
- **Expected result:** Returns navigation info showing no baked data (empty navmesh) or pending-bake status
- **Notes:** Run on a freshly created region before baking

#### 5.5 Happy path — get info on region with custom bake settings
- **Params:** `{ "path": "NavRegion" }`
- **Expected result:** Returns navigation info reflecting custom cell_size, agent_radius, etc. used during bake
- **Notes:** Run after baking with custom properties

#### 5.6 Happy path — get info on region with navigation layers set
- **Params:** `{ "path": "NavRegion" }`
- **Expected result:** Returns navigation info including the set navigation layer value
- **Notes:** Run after using `set_navigation_layers` (tool #4)

#### 5.7 Happy path — get info on region with nested path
- **Params:** `{ "path": "Level/NavZone" }`
- **Expected result:** Returns navigation info for the nested region
- **Notes:** Requires region at nested path

#### 5.8 Edge case — missing required `path`
- **Params:** `{}`
- **Expected result:** Zod validation error — `path` is required
- **Notes:** Test input schema validation

#### 5.9 Edge case — empty string `path`
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot — empty path or node not found
- **Notes:** Validates behavior with empty path

#### 5.10 Edge case — non-existent node path
- **Params:** `{ "path": "MissingRegion" }`
- **Expected result:** Error from Godot — node not found
- **Notes:** Validates error propagation

#### 5.11 Edge case — path to non-Region node (e.g., Sprite2D or NavigationAgent)
- **Params:** `{ "path": "NavAgent" }`
- **Expected result:** Error from Godot — node is not a NavigationRegion, cannot get region-specific info
- **Notes:** Validates type checking on Godot side

#### 5.12 Edge case — path to deleted region
- **Params:** `{ "path": "RemovedRegion" }`
- **Expected result:** Error from Godot — node not found (already removed)
- **Notes:** Requires the node to have been removed before calling

---

## Tool 6: `find_navigation_path`

**Description:** Find a navigation path between two points.  
**Handler route:** `navigation/find_path`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `start` | `z.array(z.number())` | ✅ Yes | Start position `[x, y]` or `[x, y, z]` |
| `end` | `z.array(z.number())` | ✅ Yes | End position `[x, y]` or `[x, y, z]` |
| `dimension` | `enum: "2d" \| "3d"` | No | Dimension type (auto-detected if omitted) |

### Test Scenarios

#### 6.1 Happy path — find 2D path (minimum params, auto-detect dimension)
- **Params:** `{ "start": [0, 0], "end": [100, 100] }`
- **Expected result:** Returns path array — a list of waypoints from start to end, or empty array if no path found
- **Notes:** Dimension auto-detected from position array length (2 elements → 2D)

#### 6.2 Happy path — find 2D path with explicit dimension
- **Params:** `{ "start": [0, 0], "end": [200, 150], "dimension": "2d" }`
- **Expected result:** Returns 2D path waypoints as array of `[x, y]` vectors
- **Notes:** Explicit "2d" dimension

#### 6.3 Happy path — find 3D path
- **Params:** `{ "start": [0, 0, 0], "end": [50, 10, 30], "dimension": "3d" }`
- **Expected result:** Returns 3D path waypoints as array of `[x, y, z]` vectors
- **Notes:** Explicit "3d" dimension with 3-element position arrays

#### 6.4 Happy path — find path on a baked navmesh
- **Params:** `{ "start": [10, 10], "end": [90, 90] }`
- **Expected result:** Returns a valid path following the navmesh geometry (points within navigable area)
- **Notes:** Run after `bake_navigation_mesh`. Start and end should be on valid navmesh.

#### 6.5 Happy path — find path with no possible route (blocked/unreachable)
- **Params:** `{ "start": [0, 0], "end": [9999, 9999] }` (or positions separated by obstacles)
- **Expected result:** Returns empty path array `[]` — no path found
- **Notes:** Validates that unreachable destinations produce empty path, not an error

#### 6.6 Happy path — find path where start and end are the same point
- **Params:** `{ "start": [50, 50], "end": [50, 50] }`
- **Expected result:** Returns a path with a single waypoint (start=end) or empty path
- **Notes:** Edge case — zero-length path

#### 6.7 Happy path — find path with start on navmesh edge
- **Params:** `{ "start": [0, 0], "end": [50, 50] }`
- **Expected result:** Returns path from edge/corner to interior point, or empty if start is off-navmesh
- **Notes:** Validates edge case for boundary positions

#### 6.8 Happy path — find 3D path with auto-detection from array length
- **Params:** `{ "start": [0, 0, 0], "end": [100, 100, 100] }`
- **Expected result:** Returns 3D path — dimension auto-detected as "3d" from 3-element arrays
- **Notes:** Omitting dimension; auto-detection from position array length

#### 6.9 Edge case — missing required `start`
- **Params:** `{ "end": [100, 100] }`
- **Expected result:** Zod validation error — `start` is required
- **Notes:** Test input schema validation

#### 6.10 Edge case — missing required `end`
- **Params:** `{ "start": [0, 0] }`
- **Expected result:** Zod validation error — `end` is required
- **Notes:** Test input schema validation

#### 6.11 Edge case — empty start array
- **Params:** `{ "start": [], "end": [100, 100] }`
- **Expected result:** Zod validation error — array must contain at least one number (2+ desired for meaningful position)
- **Notes:** `z.array(z.number())` has no `.min()` constraint; Godot may reject malformed position

#### 6.12 Edge case — single-element position arrays (invalid position)
- **Params:** `{ "start": [50], "end": [100] }`
- **Expected result:** Error from Godot — position requires at least 2 components (x, y)
- **Notes:** Single-element arrays are not valid positions

#### 6.13 Edge case — 4-element position arrays (too many components)
- **Params:** `{ "start": [0, 0, 0, 0], "end": [100, 100, 100, 100] }`
- **Expected result:** Error from Godot — unexpected extra components, or may be truncated to 3
- **Notes:** Validates handling of excess components

#### 6.14 Edge case — invalid `dimension` enum value
- **Params:** `{ "start": [0, 0], "end": [100, 100], "dimension": "4d" }`
- **Expected result:** Zod validation error — invalid enum value (only "2d" and "3d")
- **Notes:** Enum validation

#### 6.15 Edge case — dimension mismatch with position arrays
- **Params:** `{ "start": [0, 0, 0], "end": [100, 100], "dimension": "3d" }`
- **Expected result:** Error from Godot — position arrays don't match dimension (start has 3, end has 2)
- **Notes:** Mismatched array lengths with explicit 3D dimension

#### 6.16 Edge case — non-numeric values in position arrays
- **Params:** `{ "start": ["x", "y"], "end": [100, 100] }`
- **Expected result:** Zod validation error — array must contain numbers (`z.array(z.number())`)
- **Notes:** Zod type validation

#### 6.17 Edge case — extremely large position values
- **Params:** `{ "start": [1e12, 1e12], "end": [2e12, 2e12] }`
- **Expected result:** May return empty path (points far outside navmesh) or performance/timeout issue
- **Notes:** Validates large-value handling

#### 6.18 Edge case — negative position values
- **Params:** `{ "start": [-50, -50], "end": [-10, -10] }`
- **Expected result:** Returns path if within navmesh, or empty path if off-navmesh
- **Notes:** Navigation works with negative coordinates in Godot; depends on navmesh coverage

---

## Tool 7: `setup_navigation_link`

**Description:** Add a NavigationLink2D or NavigationLink3D for connecting navigation regions.  
**Handler route:** `navigation/setup_link`

### Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `dimension` | `enum: "2d" \| "3d"` | No | `"2d"` | Navigation dimension |
| `parent_path` | `string` | No | — | Parent node path (omit for scene root) |
| `name` | `string` | No | — | Node name |
| `properties` | `Record<string, unknown>` | No | Link properties (`start_position`, `end_position`, `bidirectional`, `enabled`, `navigation_layers`) |

### Test Scenarios

#### 7.1 Happy path — add 2D navigation link (minimum params)
- **Params:** `{}`
- **Expected result:** Success — a NavigationLink2D node added to scene root (dimension defaults to "2d")
- **Notes:** All params are optional; no required params!

#### 7.2 Happy path — add 2D navigation link with explicit dimension
- **Params:** `{ "dimension": "2d" }`
- **Expected result:** Success — a NavigationLink2D added
- **Notes:** Validates explicit "2d" enum value

#### 7.3 Happy path — add 3D navigation link
- **Params:** `{ "dimension": "3d" }`
- **Expected result:** Success — a NavigationLink3D added
- **Notes:** Validates "3d" enum value

#### 7.4 Happy path — add link with custom name
- **Params:** `{ "name": "JumpLink" }`
- **Expected result:** Success — NavigationLink2D named "JumpLink"
- **Notes:** Validates custom name

#### 7.5 Happy path — add link under specific parent
- **Params:** `{ "parent_path": "Level", "name": "BridgeLink" }`
- **Expected result:** Success — NavigationLink2D added as child of "Level"
- **Notes:** Requires "Level" node to exist

#### 7.6 Happy path — add link with start and end positions
- **Params:** `{ "properties": { "start_position": [0, 0], "end_position": [100, 0] } }`
- **Expected result:** Success — NavigationLink2D with start and end positions configured
- **Notes:** Validates position properties for link endpoints

#### 7.7 Happy path — add bidirectional link
- **Params:** `{ "properties": { "start_position": [0, 0], "end_position": [50, 0], "bidirectional": true } }`
- **Expected result:** Success — bidirectional link (works in both directions)
- **Notes:** Validates `bidirectional` property

#### 7.8 Happy path — add unidirectional link
- **Params:** `{ "properties": { "start_position": [0, 0], "end_position": [50, 0], "bidirectional": false } }`
- **Expected result:** Success — one-way link (start→end only)
- **Notes:** Validates disabled bidirectional

#### 7.9 Happy path — add disabled link
- **Params:** `{ "properties": { "start_position": [0, 0], "end_position": [50, 0], "enabled": false } }`
- **Expected result:** Success — link created but disabled (not active for pathfinding)
- **Notes:** Validates `enabled` property

#### 7.10 Happy path — add link with navigation layers
- **Params:** `{ "properties": { "start_position": [0, 0], "end_position": [100, 0], "navigation_layers": 2 } }`
- **Expected result:** Success — link assigned to navigation layer 2
- **Notes:** Validates `navigation_layers` property

#### 7.11 Happy path — add 3D link with 3D positions
- **Params:** `{ "dimension": "3d", "properties": { "start_position": [0, 0, 0], "end_position": [10, 5, 10], "bidirectional": true } }`
- **Expected result:** Success — NavigationLink3D with 3D start and end points
- **Notes:** Validates 3D link with 3-component position arrays

#### 7.12 Happy path — add link with all optional parameters
- **Params:** `{ "dimension": "3d", "parent_path": "Level", "name": "FullLink", "properties": { "start_position": [0, 0, 0], "end_position": [10, 10, 10], "bidirectional": true, "enabled": true, "navigation_layers": 5 } }`
- **Expected result:** Success — fully configured NavigationLink3D
- **Notes:** Full parameter coverage

#### 7.13 Edge case — invalid `dimension` enum value
- **Params:** `{ "dimension": "4d" }`
- **Expected result:** Zod validation error — invalid enum value
- **Notes:** Enum validation — only "2d" and "3d"

#### 7.14 Edge case — parent_path to non-existent node
- **Params:** `{ "parent_path": "GhostParent" }`
- **Expected result:** Error from Godot — parent node not found
- **Notes:** Validates error propagation

#### 7.15 Edge case — empty `properties` object
- **Params:** `{ "properties": {} }`
- **Expected result:** Success — same as omitting properties, link created with defaults
- **Notes:** Should behave identically to 7.1

#### 7.16 Edge case — invalid property key
- **Params:** `{ "properties": { "jump_height": 10 } }`
- **Expected result:** Error from Godot — unknown property, or silently ignored
- **Notes:** "jump_height" is not a valid NavigationLink property

#### 7.17 Edge case — link without start/end positions
- **Params:** `{ "dimension": "3d" }`
- **Expected result:** Success — link created but positions are at default (origin). May produce warnings.
- **Notes:** Creating a link with both endpoints at origin is technically valid but non-functional

---

## Tool 8: `remove_navigation_region`

**Description:** Remove a navigation region node from the scene.  
**Handler route:** `navigation/remove_region`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `node_path` | `NodePath` (string) | ✅ Yes | Path to the navigation region node to remove |

### Test Scenarios

#### 8.1 Happy path — remove a 2D navigation region
- **Params:** `{ "node_path": "NavRegion" }`
- **Expected result:** Success — NavigationRegion2D node removed from scene
- **Notes:** Requires NavRegion created by tool #1

#### 8.2 Happy path — remove a 3D navigation region
- **Params:** `{ "node_path": "NavRegion3D" }`
- **Expected result:** Success — NavigationRegion3D node removed
- **Notes:** Requires NavRegion3D created by tool #1

#### 8.3 Happy path — remove region with nested path
- **Params:** `{ "node_path": "Level/NavZone" }`
- **Expected result:** Success — nested navigation region removed
- **Notes:** Requires region at nested path

#### 8.4 Happy path — remove region with children (recursive delete)
- **Params:** `{ "node_path": "ParentRegion" }`
- **Expected result:** Success — region and all its child nodes removed
- **Notes:** Godot's node removal is recursive

#### 8.5 Edge case — missing required `node_path`
- **Params:** `{}`
- **Expected result:** Zod validation error — `node_path` is required
- **Notes:** Test input schema validation

#### 8.6 Edge case — empty string `node_path`
- **Params:** `{ "node_path": "" }`
- **Expected result:** Error from Godot — cannot delete scene root
- **Notes:** Validates behavior with empty path referencing scene root

#### 8.7 Edge case — non-existent node_path
- **Params:** `{ "node_path": "GhostRegion" }`
- **Expected result:** Error from Godot — node not found
- **Notes:** Validates error propagation

#### 8.8 Edge case — node_path to non-Region node (e.g., Sprite2D)
- **Params:** `{ "node_path": "Sprite2D" }`
- **Expected result:** May still succeed (Godot deletes any node) or may validate type
- **Notes:** Tool name implies region but implementation may allow any node deletion

#### 8.9 Edge case — remove same node twice
- **Params:** `{ "node_path": "NavRegion" }` (run twice)
- **Expected result:** First call succeeds, second call errors (node no longer exists)
- **Notes:** Validates idempotency behavior

#### 8.10 Edge case — remove node that is a parent of other active navigation nodes
- **Params:** `{ "node_path": "NavParent" }`
- **Expected result:** Success — parent and all child navigation nodes removed recursively
- **Notes:** Requires a node that has navigation children

---

## Tool 9: `remove_navigation_agent`

**Description:** Remove a navigation agent node from the scene.  
**Handler route:** `navigation/remove_agent`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `node_path` | `NodePath` (string) | ✅ Yes | Path to the navigation agent node to remove |

### Test Scenarios

#### 9.1 Happy path — remove a 2D navigation agent
- **Params:** `{ "node_path": "NavAgent" }`
- **Expected result:** Success — NavigationAgent2D node removed
- **Notes:** Requires NavAgent created by tool #2

#### 9.2 Happy path — remove a 3D navigation agent
- **Params:** `{ "node_path": "NavAgent3D" }`
- **Expected result:** Success — NavigationAgent3D node removed
- **Notes:** Requires NavAgent3D created by tool #2

#### 9.3 Happy path — remove agent with nested path
- **Params:** `{ "node_path": "Player/Navigator" }`
- **Expected result:** Success — nested navigation agent removed
- **Notes:** Requires agent at nested path

#### 9.4 Edge case — missing required `node_path`
- **Params:** `{}`
- **Expected result:** Zod validation error — `node_path` is required
- **Notes:** Test input schema validation

#### 9.5 Edge case — empty string `node_path`
- **Params:** `{ "node_path": "" }`
- **Expected result:** Error from Godot — cannot delete scene root
- **Notes:** Validates behavior with empty path

#### 9.6 Edge case — non-existent node_path
- **Params:** `{ "node_path": "GhostAgent" }`
- **Expected result:** Error from Godot — node not found
- **Notes:** Validates error propagation

#### 9.7 Edge case — node_path to non-Agent node
- **Params:** `{ "node_path": "Node2D" }`
- **Expected result:** May succeed (Godot deletes any node) or may validate type
- **Notes:** Tool name implies agent but implementation may allow any node deletion

#### 9.8 Edge case — remove same node twice
- **Params:** `{ "node_path": "NavAgent" }` (run twice)
- **Expected result:** First call succeeds, second call errors (node no longer exists)
- **Notes:** Validates idempotency behavior

---

## Tool 10: `remove_navigation_link`

**Description:** Remove a navigation link node from the scene.  
**Handler route:** `navigation/remove_link`

### Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `node_path` | `NodePath` (string) | ✅ Yes | Path to the navigation link node to remove |

### Test Scenarios

#### 10.1 Happy path — remove a 2D navigation link
- **Params:** `{ "node_path": "JumpLink" }`
- **Expected result:** Success — NavigationLink2D node removed
- **Notes:** Requires JumpLink created by tool #7

#### 10.2 Happy path — remove a 3D navigation link
- **Params:** `{ "node_path": "FullLink" }`
- **Expected result:** Success — NavigationLink3D node removed
- **Notes:** Requires FullLink created by tool #7

#### 10.3 Happy path — remove link with nested path
- **Params:** `{ "node_path": "Level/BridgeLink" }`
- **Expected result:** Success — nested link removed
- **Notes:** Requires link at nested path

#### 10.4 Edge case — missing required `node_path`
- **Params:** `{}`
- **Expected result:** Zod validation error — `node_path` is required
- **Notes:** Test input schema validation

#### 10.5 Edge case — empty string `node_path`
- **Params:** `{ "node_path": "" }`
- **Expected result:** Error from Godot — cannot delete scene root
- **Notes:** Validates behavior with empty path

#### 10.6 Edge case — non-existent node_path
- **Params:** `{ "node_path": "GhostLink" }`
- **Expected result:** Error from Godot — node not found
- **Notes:** Validates error propagation

#### 10.7 Edge case — node_path to non-Link node
- **Params:** `{ "node_path": "Node2D" }`
- **Expected result:** May succeed (Godot deletes any node) or may validate type
- **Notes:** Tool name implies link but implementation may allow any node deletion

#### 10.8 Edge case — remove same node twice
- **Params:** `{ "node_path": "JumpLink" }` (run twice)
- **Expected result:** First call succeeds, second call errors (node no longer exists)
- **Notes:** Validates idempotency behavior

---

## Integration Test Flow

The following end-to-end flows test the full lifecycle of navigation tools in sequence:

### Flow 1: Navigation Region Lifecycle (Tools 1, 3, 4, 5, 8)

**Prerequisites:** An empty or existing scene

1. **Add 2D navigation region** (1.1) — `{ "path": "TestNavRegion" }`
2. **Get navigation info** (5.1) — `{ "path": "TestNavRegion" }` → verify region exists, no navmesh baked yet
3. **Set navigation layers** (4.2) — `{ "path": "TestNavRegion", "layer": 1 }`
4. **Bake navmesh** (3.1) — `{ "path": "TestNavRegion" }` → bake with defaults
5. **Get navigation info** (5.3) — `{ "path": "TestNavRegion" }` → verify baked navmesh data present
6. **Add 3D navigation region** (1.3) — `{ "path": "TestNavRegion3D", "dimension": "3d" }`
7. **Bake 3D navmesh** (3.4) — `{ "path": "TestNavRegion3D", "properties": { "cell_height": 0.5 } }`
8. **Get navigation info** (5.2) — `{ "path": "TestNavRegion3D" }` → verify 3D navmesh baked
9. **Set layer on 3D region** (4.5) — `{ "path": "TestNavRegion3D", "layer": 5 }`
10. **Get navigation info** (5.6) — `{ "path": "TestNavRegion3D" }` → verify layer=5
11. **Remove 2D region** (8.1) — `{ "node_path": "TestNavRegion" }`
12. **Get navigation info** (5.12) — `{ "path": "TestNavRegion" }` → expect error (node removed)
13. **Remove 3D region** (8.2) — `{ "node_path": "TestNavRegion3D" }`

### Flow 2: Navigation Agent Lifecycle (Tools 2, 9)

**Prerequisites:** An empty or existing scene

1. **Add 2D navigation agent** (2.1) — `{ "path": "PatrolAgent" }`
2. **Add 3D navigation agent** (2.3) — `{ "path": "EnemyAgent3D", "dimension": "3d" }`
3. **Add agent under parent** (2.4) — `{ "path": "Player/MoveAgent", "parent_path": "Player" }`
4. **Add agent with properties** (2.6) — `{ "path": "SmartAgent", "properties": { "radius": 0.5, "speed": 200 } }`
5. **Remove 3D agent** (9.2) — `{ "node_path": "EnemyAgent3D" }`
6. **Remove nested agent** (9.3) — `{ "node_path": "Player/MoveAgent" }`
7. **Remove 2D agent** (9.1) — `{ "node_path": "PatrolAgent" }`
8. **Remove property-configured agent** (9.1) — `{ "node_path": "SmartAgent" }`

### Flow 3: Navigation Link Lifecycle (Tools 7, 10)

**Prerequisites:** An empty or existing scene

1. **Add 2D link** (7.1) — `{}`
2. **Add named 3D link** (7.3) — `{ "dimension": "3d", "name": "PlatformJump" }`
3. **Add link with positions** (7.6) — `{ "properties": { "start_position": [0, 0], "end_position": [50, 50] } }`
4. **Add bidirectional link** (7.7) — `{ "name": "BidirLink", "properties": { "start_position": [10, 0], "end_position": [100, 0], "bidirectional": true } }`
5. **Add 3D link with full properties** (7.12) — `{ "dimension": "3d", "name": "FullNavLink", "properties": { "start_position": [0, 0, 0], "end_position": [10, 10, 10], "bidirectional": true, "enabled": true, "navigation_layers": 5 } }`
6. **Remove bidirectional link** (10.7) — `{ "node_path": "BidirLink" }`
7. **Remove 3D full link** (10.2) — `{ "node_path": "FullNavLink" }`
8. **Remove default 2D link** (10.1) — `{ "node_path": "NavigationLink2D" }` (default name)
9. **Remove positioned link** (10.1) — `{ "node_path": "NavigationLink2D" }` (second default)
10. **Remove 3D named link** (10.2) — `{ "node_path": "PlatformJump" }`

### Flow 4: End-to-End Pathfinding (Tools 1, 2, 3, 6)

**Prerequisites:** An empty or existing scene with navigable geometry

1. **Add 2D navigation region** (1.1) — `{ "path": "PathNav" }`
2. **Bake navmesh** (3.1) — `{ "path": "PathNav" }`
3. **Add navigation agent to a character** (2.1) — `{ "path": "PathAgent", "properties": { "speed": 150 } }`
4. **Set navigation layers** (4.1) — `{ "path": "PathNav", "layer": 1 }`
5. **Find 2D path** (6.1) — `{ "start": [10, 10], "end": [90, 90] }` → expect waypoint array
6. **Find unreachable path** (6.5) — `{ "start": [10, 10], "end": [9999, 9999] }` → expect empty array
7. **Find zero-length path** (6.6) — `{ "start": [50, 50], "end": [50, 50] }` → expect single-point or empty
8. **Remove agent** (9.1) — `{ "node_path": "PathAgent" }`
9. **Remove region** (8.1) — `{ "node_path": "PathNav" }`

### Flow 5: All Dimension Enum Values

**Prerequisites:** None

Verify both `"2d"` and `"3d"` dimension values across all tools that accept `dimension`:

| Tool | 2D test | 3D test |
|------|---------|---------|
| `setup_navigation_region` (1.2, 1.3) | `{ "path": "R2D", "dimension": "2d" }` | `{ "path": "R3D", "dimension": "3d" }` |
| `setup_navigation_agent` (2.2, 2.3) | `{ "path": "A2D", "dimension": "2d" }` | `{ "path": "A3D", "dimension": "3d" }` |
| `find_navigation_path` (6.2, 6.3) | `{ "start": [0,0], "end": [100,100], "dimension": "2d" }` | `{ "start": [0,0,0], "end": [100,100,100], "dimension": "3d" }` |
| `setup_navigation_link` (7.2, 7.3) | `{ "dimension": "2d" }` | `{ "dimension": "3d" }` |

### Flow 6: Layer Boundary Testing (Tool 4)

**Prerequisites:** A navigation region in the scene

Test the full range of `layer` values from `set_navigation_layers`:

| Layer | Expected | Notes |
|-------|----------|-------|
| 1 | Success | Lowest valid |
| 2 | Success | — |
| 16 | Success | Mid-range |
| 31 | Success | — |
| 32 | Success | Highest valid |
| 0 | Zod error | Below min(1) |
| 33 | Zod error | Above max(32) |
| -5 | Zod error | Negative, below min(1) |
| 99 | Zod error | Above max(32) |

---

## Schema Validation Summary

All tools use Zod for input validation. Key constraints:

| Constraint | Applied to | Tools affected |
|-----------|-----------|----------------|
| `NodePath` (required string) | `path`, `node_path` | #1, #2, #3, #4, #5, #8, #9, #10 |
| `OptionalDimension` with `.default('2d')` | `dimension` | #1, #2, #7 |
| `OptionalDimension` without default | `dimension` | #6 (auto-detected) |
| `OptionalProperties` | `properties` | #1, #2, #3, #7 |
| `z.array(z.number())` (required) | `start`, `end` | #6 |
| `z.number().int().min(1).max(32).optional()` | `layer` | #4 |
| `optional string` | `parent_path`, `name` | #1, #2, #7 |
| No params at all | — | Tool #7 only (all optional) |

**Notable observations:**

- **Tool #7 (`setup_navigation_link`) has no required parameters.** All four parameters (`dimension`, `parent_path`, `name`, `properties`) are optional. This is unique — the tool can be called with `{}` and will create a default NavigationLink2D.

- **`find_navigation_path` (tool #6) has no `z.tuple()` constraints on position arrays.** `start` and `end` are `z.array(z.number())` without `.min(2)` or `.max(3)`. This means single-element arrays, 4+ element arrays, and empty arrays pass zod validation but will likely error in Godot. Test scenarios 6.11, 6.12, and 6.13 cover these gaps.

- **`set_navigation_layers` (tool #4) has rigorous numeric constraints** with `.int().min(1).max(32)` — this is the most strictly validated numeric parameter in the navigation module.

- **Dimension defaults differ:** Tools #1, #2, and #7 use `OptionalDimension.default('2d')` (default to 2D). Tool #6 uses `OptionalDimension` without default (auto-detected from position array). This is intentional — pathfinding auto-detects dimension while setup tools default to 2D.

- **All three remove tools (#8, #9, #10) have identical schemas** — each takes only a required `node_path` of type `NodePath`. They differ only in their handler routes and descriptions.

---

## Cross-Tool Dependency Diagram

```
setup_navigation_region (#1) ──► bake_navigation_mesh (#3)
                                     │
                                     ▼
                            get_navigation_info (#5)
                                     │
set_navigation_layers (#4) ─────────┘
                                     │
setup_navigation_agent (#2) ─────────┤
                                     │
setup_navigation_link (#7) ──────────┤
                                     │
                                     ▼
                            find_navigation_path (#6)

remove_navigation_region (#8)  ── cleanup
remove_navigation_agent (#9)   ── cleanup
remove_navigation_link (#10)   ── cleanup
```

**Setup tools** (#1, #2, #7) create the navigation infrastructure.  
**Configuration tools** (#3, #4) configure the infrastructure.  
**Query tools** (#5, #6) read and use the infrastructure.  
**Cleanup tools** (#8, #9, #10) tear down infrastructure.
