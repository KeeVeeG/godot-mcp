# Batch Tools — Test Plan

> **Source file:** `server/src/tools/batch.ts`
> **Godot bridge endpoints:** `batch/find_by_type`, `batch/find_connections`, `batch/set_property`, `batch/find_references`, `batch/get_dependencies`, `batch/cross_scene_set`, `batch/find_script_refs`, `batch/detect_circular`
> **Shared types:** `NodeType`, `PropertyName`, `PropertyValue`, `ScriptPath` from `server/src/tools/shared-types.ts`
> **Generated:** 2026-07-08

---

## Overview

All 8 tools in this module are read-only or bulk-mutation tools. Two tools (`find_signal_connections`, `detect_circular_dependencies`) have empty schemas and accept no parameters. Six tools accept one or more parameters.

| # | Tool Name | Bridge Method | Handler Pattern | Params |
|---|-----------|--------------|-----------------|--------|
| 1 | `find_nodes_by_type` | `batch/find_by_type` | `(args) => callGodot(...)` | `type_name` (required) |
| 2 | `find_signal_connections` | `batch/find_connections` | `(args) => callGodot(...)` | none |
| 3 | `batch_set_property` | `batch/set_property` | `(args) => callGodot(...)` | `type_name`, `property`, `value` (all required) |
| 4 | `find_node_references` | `batch/find_references` | `(args) => callGodot(...)` | `query` (required) |
| 5 | `get_scene_dependencies` | `batch/get_dependencies` | `(args) => callGodot(...)` | `path` (required) |
| 6 | `cross_scene_set_property` | `batch/cross_scene_set` | `(args) => callGodot(...)` | `type_name`, `property`, `value` (required), `confirm_no_undo` (optional, default `false`) |
| 7 | `find_script_references` | `batch/find_script_refs` | `(args) => callGodot(...)` | `script_path` (required) |
| 8 | `detect_circular_dependencies` | `batch/detect_circular` | `() => callGodot(...)` *(ignores args)* | none |

### Shared Type Definitions

| Schema | Zod Definition | Description |
|--------|---------------|-------------|
| `NodeType` | `z.string()` | Node type name (e.g. `"Sprite2D"`, `"CharacterBody3D"`) |
| `PropertyName` | `z.string()` | Property name (e.g. `"position"`, `"visible"`) |
| `PropertyValue` | `z.unknown()` | Any property value |
| `ScriptPath` | `z.string()` | Script file path (e.g. `"res://scripts/player.gd"`) |

---

## Tool: `find_nodes_by_type`

**Description:** Find all nodes of a specific type in the scene

**Handler:**
```typescript
async (args) => callGodot(bridge, 'batch/find_by_type', args as Record<string, unknown>)
```

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `type_name` | `string` (NodeType) | ✅ Yes | — | Node type name (e.g. `"Sprite2D"`, `"CharacterBody3D"`) |

---

### Test Scenarios

#### Scenario 1: Basic happy path — find nodes in a scene with known types
- **Description:** Call with `type_name: "Sprite2D"` on a 2D scene that contains Sprite2D nodes. Should return a list of matching nodes.
- **Params:** `{ "type_name": "Sprite2D" }`
- **Expected result:** JSON object or array listing matching node paths (e.g., `[{ "path": "Player/Sprite", ... }, ...]`). Not an error.
- **Notes:** Requires a scene with at least one `Sprite2D` node to be open.

#### Scenario 2: Node type that is the scene root
- **Description:** Call with `type_name: "Node2D"` on a scene whose root is `Node2D`. Should find at least the root node.
- **Params:** `{ "type_name": "Node2D" }`
- **Expected result:** JSON listing matching nodes. Root node should be included.
- **Notes:** Tests that the root node itself is found.

#### Scenario 3: Node type with zero matches
- **Description:** Call with a valid node type name that does not exist in the current scene (e.g., `"CharacterBody3D"` in a 2D-only scene).
- **Params:** `{ "type_name": "CharacterBody3D" }`
- **Expected result:** JSON with an empty list (e.g., `[]`). Should not error.
- **Notes:** Validates graceful handling of zero-hit queries.

#### Scenario 4: Call with an empty string for `type_name`
- **Description:** Provide an empty string `""` as the node type. Zod `z.string()` accepts empty strings.
- **Params:** `{ "type_name": "" }`
- **Expected result:** Likely returns an empty list or an error from Godot (depending on plugin behavior). Should not crash the server.
- **Notes:** Edge case — empty string passes Zod string validation but may be rejected by Godot.

#### Scenario 5: Call with a non-existent class name
- **Description:** Provide a string that looks like a class name but does not exist in Godot's class hierarchy (e.g., `"NonExistentClassXYZ"`).
- **Params:** `{ "type_name": "NonExistentClassXYZ" }`
- **Expected result:** Likely an empty result or an error string from Godot. Should not crash.
- **Notes:** Tests Godot's error handling for unknown types.

#### Scenario 6: Missing required `type_name` parameter
- **Description:** Call without the `type_name` parameter entirely.
- **Params:** `{}`
- **Expected result:** Zod validation error from the MCP server. The server should reject the call before it reaches Godot.
- **Notes:** MCP stdio layer validates `inputSchema.required` fields. `type_name` is the only field in the schema and is required (no `.optional()` on `NodeType`).

#### Scenario 7: `type_name` with non-string value
- **Description:** Pass a number or boolean as `type_name`.
- **Params:** `{ "type_name": 42 }`
- **Expected result:** Zod validation error from MCP server. Server should reject.
- **Notes:** Validates type coercion/validation.

#### Scenario 8: Godot editor not connected
- **Description:** Call when the bridge is disconnected.
- **Params:** `{ "type_name": "Node" }`
- **Expected result:** Error result with `isError: true`, containing message like `"Godot request failed: ..."`.
- **Notes:** Covered by the `callGodot` error handler.

---

## Tool: `find_signal_connections`

**Description:** Find all signal connections in the scene

**Handler:**
```typescript
async (args) => callGodot(bridge, 'batch/find_connections', args as Record<string, unknown>)
```

**Parameters:** None (empty schema `{}`). Any extra params are forwarded to Godot.

---

### Test Scenarios

#### Scenario 1: Basic happy path — scene with signal connections
- **Description:** Call on a scene that has connected signals between nodes (e.g., a Button's `pressed` signal connected to a script method).
- **Params:** `{}`
- **Expected result:** JSON listing all signal connections with source node, signal name, target node, and method. Not an error.
- **Notes:** Requires a scene with at least one signal connection. Build a test scene if needed.

#### Scenario 2: Scene with no signal connections
- **Description:** Call on an empty or newly created scene with no signal wiring.
- **Params:** `{}`
- **Expected result:** JSON with an empty connection list (e.g., `[]` or `{}`). Should not error.
- **Notes:** Validates zero-connections case.

#### Scenario 3: Call with extra params
- **Description:** Pass arbitrary extra params; handler forwards them to Godot.
- **Params:** `{ "filter": "all", "include_builtins": false }`
- **Expected result:** Should not error. Behavior depends on whether Godot plugin respects these params.
- **Notes:** The empty schema means no Zod validation, so extra fields are passed through.

#### Scenario 4: Godot editor not connected
- **Description:** Call when bridge is disconnected.
- **Params:** `{}`
- **Expected result:** Error `"Godot request failed: ..."` with `isError: true`.

---

## Tool: `batch_set_property`

**Description:** Set a property on all nodes of a given type

**Handler:**
```typescript
async (args) => callGodot(bridge, 'batch/set_property', args as Record<string, unknown>)
```

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `type_name` | `string` (NodeType) | ✅ Yes | — | Node type name (e.g. `"Sprite2D"`, `"CharacterBody3D"`) |
| `property` | `string` (PropertyName) | ✅ Yes | — | Property name (e.g. `"position"`, `"visible"`) |
| `value` | `unknown` (PropertyValue) | ✅ Yes | — | Property value |

---

### Test Scenarios

#### Scenario 1: Basic happy path — set a common property on matching nodes
- **Description:** Set `visible` to `false` on all `Sprite2D` nodes in the current scene that has multiple Sprite2D nodes.
- **Params:** `{ "type_name": "Sprite2D", "property": "visible", "value": false }`
- **Expected result:** JSON confirming the operation, e.g., number of nodes modified. All Sprite2D nodes in the open scene should have `visible` set to `false`.
- **Notes:** Mutating operation. Use on a disposable test scene. Verify via `get_node_properties` on the affected nodes afterward.

#### Scenario 2: Set a numeric property
- **Description:** Set `modulate.a` (alpha) to `0.5` on all `Label` nodes.
- **Params:** `{ "type_name": "Label", "property": "modulate:a", "value": 0.5 }`
- **Expected result:** Confirmation response. All Labels should have half opacity.
- **Notes:** Tests numeric value handling.

#### Scenario 3: Set a Vector2 property
- **Description:** Set `position` to `[100, 200]` on all `Node2D` nodes that are direct children of root.
- **Params:** `{ "type_name": "Node2D", "property": "position", "value": [100, 200] }`
- **Expected result:** Confirmation. All direct `Node2D` children should move to `(100, 200)`.
- **Notes:** Tests array/vector value serialization.

#### Scenario 4: Set a string property
- **Description:** Set `name` to `"RenamedNode"` on all `Node` type nodes. Since everything inherits from Node, this could be very destructive.
- **Params:** `{ "type_name": "Node", "property": "name", "value": "RenamedNode" }`
- **Expected result:** All nodes renamed. This is potentially destructive — use only on a test scene.
- **Notes:** Tests that the tool truly operates on all nodes matching the type, including inherited types. Godot may prevent renaming scene-root nodes or named singleton paths.

#### Scenario 5: Type with zero matching nodes
- **Description:** Set a property on a node type that doesn't exist in the scene.
- **Params:** `{ "type_name": "CharacterBody3D", "property": "visible", "value": false }`
- **Expected result:** JSON indicating zero nodes modified (e.g., `{ "modified": 0 }`). Should not error.
- **Notes:** Validates graceful handling when no nodes match.

#### Scenario 6: Invalid property name
- **Description:** Provide a property name that does not exist on the target node type.
- **Params:** `{ "type_name": "Sprite2D", "property": "non_existent_property", "value": 123 }`
- **Expected result:** Likely an error from Godot (the plugin or engine will reject unknown property). The server should relay the error, not crash.
- **Notes:** Tests Godot's property validation.

#### Scenario 7: Missing required `type_name`
- **Description:** Omit `type_name`.
- **Params:** `{ "property": "visible", "value": false }`
- **Expected result:** Zod validation error from MCP server. Rejected before reaching Godot.
- **Notes:** All three params are required (no `.optional()` on any).

#### Scenario 8: Missing required `property`
- **Description:** Omit `property`.
- **Params:** `{ "type_name": "Sprite2D", "value": false }`
- **Expected result:** Zod validation error from MCP server.
- **Notes:** `property` has no default and is not optional.

#### Scenario 9: Missing required `value`
- **Description:** Omit `value`.
- **Params:** `{ "type_name": "Sprite2D", "property": "visible" }`
- **Expected result:** Zod validation error from MCP server.
- **Notes:** Even though `value` is `z.unknown()`, it must be present in the input.

#### Scenario 10: Godot editor not connected
- **Description:** Call when bridge is disconnected.
- **Params:** `{ "type_name": "Sprite2D", "property": "visible", "value": false }`
- **Expected result:** Error `"Godot request failed: ..."` with `isError: true`.

---

## Tool: `find_node_references`

**Description:** Find all references to a node across scenes and scripts

**Handler:**
```typescript
async (args) => callGodot(bridge, 'batch/find_references', args as Record<string, unknown>)
```

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `query` | `string` | ✅ Yes | — | Node path or name to search for |

---

### Test Scenarios

#### Scenario 1: Basic happy path — search for a node by name
- **Description:** Search for references to a node named `"Player"` that exists in the current scene and is referenced by scripts.
- **Params:** `{ "query": "Player" }`
- **Expected result:** JSON listing all scenes, scripts, and resources that reference a node named `"Player"`. Not an error.
- **Notes:** Requires a project where at least one node named `"Player"` is referenced (e.g., via `$Player`, `get_node("Player")`, or scene instantiation).

#### Scenario 2: Search with a full path
- **Description:** Search using a relative path like `"Player/Camera2D"`.
- **Params:** `{ "query": "Player/Camera2D" }`
- **Expected result:** JSON with references to that specific path. May be empty if no scripts reference that exact path string.
- **Notes:** Tests that the tool searches for path strings, not just node names.

#### Scenario 3: Search with a GDScript-style unique path
- **Description:** Search for a unique-name reference like `"%Player"`.
- **Params:** `{ "query": "%Player" }`
- **Expected result:** JSON with references to the `%Player` unique node. May be empty if not used.
- **Notes:** Tests Godot's scene-unique-name (`%`) reference style.

#### Scenario 4: Query with no matches
- **Description:** Search for a node name that does not exist anywhere in the project.
- **Params:** `{ "query": "NonExistentNodeABC123" }`
- **Expected result:** JSON with an empty reference list (e.g., `[]`). Should not error.
- **Notes:** Validates zero-result case.

#### Scenario 5: Query is an empty string
- **Description:** Pass `""` as the query.
- **Params:** `{ "query": "" }`
- **Expected result:** May return everything, nothing, or an error from Godot. Server should not crash.
- **Notes:** Zod accepts empty strings. Godot's behavior is undefined — treat as exploratory.

#### Scenario 6: Query with special regex characters
- **Description:** Pass a query containing regex metacharacters: `"Player.*"`.
- **Params:** `{ "query": "Player.*" }`
- **Expected result:** Depends on whether Godot treats the query as regex or literal. Should not crash.
- **Notes:** Tests Godot's string handling — not clear if it does regex or exact match.

#### Scenario 7: Missing required `query` parameter
- **Description:** Call with empty params.
- **Params:** `{}`
- **Expected result:** Zod validation error from MCP server.
- **Notes:** `query` is required.

#### Scenario 8: Godot editor not connected
- **Description:** Call when bridge is disconnected.
- **Params:** `{ "query": "Player" }`
- **Expected result:** Error `"Godot request failed: ..."` with `isError: true`.

---

## Tool: `get_scene_dependencies`

**Description:** Get all dependencies of a scene file (scripts, resources, sub-scenes)

**Handler:**
```typescript
async (args) => callGodot(bridge, 'batch/get_dependencies', args as Record<string, unknown>)
```

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `path` | `string` | ✅ Yes | — | Scene file path |

---

### Test Scenarios

#### Scenario 1: Basic happy path — check dependencies of main scene
- **Description:** Call with `path` set to the main scene file of the project (e.g., `"res://scenes/main.tscn"`).
- **Params:** `{ "path": "res://scenes/main.tscn" }`
- **Expected result:** JSON listing all dependencies: scripts used, sub-scenes instantiated, resource files (.tres, textures, materials) referenced. Not an error.
- **Notes:** Requires a scene file that actually exists and has dependencies.

#### Scenario 2: Scene file with no external dependencies
- **Description:** Call on a minimal scene that only contains built-in nodes with no scripts, external resources, or sub-scenes.
- **Params:** `{ "path": "res://scenes/empty.tscn" }`
- **Expected result:** JSON with an empty or minimal dependency list (possibly only the `.tscn` file itself). Not an error.
- **Notes:** Validates that a self-contained scene still returns a valid result.

#### Scenario 3: Scene file with nested dependencies (sub-scene chain)
- **Description:** Call on a scene that instantiates another scene which itself has dependencies.
- **Params:** `{ "path": "res://scenes/parent.tscn" }`
- **Expected result:** JSON listing both direct and transitive dependencies (if the Godot plugin traverses the dependency graph). Not an error.
- **Notes:** Tests dependency graph traversal depth.

#### Scenario 4: Non-existent file path
- **Description:** Provide a scene path that does not exist in the project.
- **Params:** `{ "path": "res://scenes/does_not_exist.tscn" }`
- **Expected result:** Error message from Godot indicating file not found. `isError` may be `true`.
- **Notes:** Server should relay the Godot error, not crash.

#### Scenario 5: Path without `res://` prefix
- **Description:** Provide a path like `"scenes/main.tscn"` (missing `res://`).
- **Params:** `{ "path": "scenes/main.tscn" }`
- **Expected result:** May error or resolve relative to project root depending on Godot's path resolution. May work, may error.
- **Notes:** Tests path resolution behavior. Prefer `res://` paths.

#### Scenario 6: Path is a directory, not a file
- **Description:** Provide a directory path instead of a file path.
- **Params:** `{ "path": "res://scenes/" }`
- **Expected result:** Likely an error from Godot (expecting a .tscn file).
- **Notes:** Validates that directory paths are rejected or handled gracefully.

#### Scenario 7: Path is not a `.tscn` file
- **Description:** Provide path to a script or resource file instead of a scene.
- **Params:** `{ "path": "res://scripts/player.gd" }`
- **Expected result:** Likely an error from Godot (the plugin expects a scene file).
- **Notes:** Validates that non-scene files are handled appropriately.

#### Scenario 8: Missing required `path` parameter
- **Description:** Call with empty params.
- **Params:** `{}`
- **Expected result:** Zod validation error from MCP server.
- **Notes:** `path` is required.

#### Scenario 9: Godot editor not connected
- **Description:** Call when bridge is disconnected.
- **Params:** `{ "path": "res://scenes/main.tscn" }`
- **Expected result:** Error `"Godot request failed: ..."` with `isError: true`.

---

## Tool: `cross_scene_set_property`

**Description:** Set a property on nodes of a given type across multiple scenes

**Handler:**
```typescript
async (args) => callGodot(bridge, 'batch/cross_scene_set', args as Record<string, unknown>)
```

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `type_name` | `string` (NodeType) | ✅ Yes | — | Node type name (e.g. `"Sprite2D"`, `"CharacterBody3D"`) |
| `property` | `string` (PropertyName) | ✅ Yes | — | Property name (e.g. `"position"`, `"visible"`) |
| `value` | `unknown` (PropertyValue) | ✅ Yes | — | Property value |
| `confirm_no_undo` | `boolean` | ❌ No | `false` | Set to `true` to acknowledge this is destructive and cannot be undone |

---

### Test Scenarios

#### Scenario 1: Basic happy path — with confirmation
- **Description:** Call with `confirm_no_undo: true` to acknowledge the destructive nature. Set `visible` to `false` on all `"Sprite2D"` nodes across all scenes.
- **Params:** `{ "type_name": "Sprite2D", "property": "visible", "value": false, "confirm_no_undo": true }`
- **Expected result:** JSON confirming the operation across multiple scenes. Not an error.
- **Notes:** This is a cross-scene mutation — it may open, modify, and save every scene in the project. Use only on a disposable test project.

#### Scenario 2: Without confirmation — should be blocked or warned
- **Description:** Call without setting `confirm_no_undo` (defaults to `false`). The Godot plugin should reject or warn about the destructive operation.
- **Params:** `{ "type_name": "Sprite2D", "property": "visible", "value": false }`
- **Expected result:** Depending on Godot plugin implementation: either returns an error/warning requiring `confirm_no_undo` to be `true`, or still proceeds (if the plugin does not enforce it). The server should not crash.
- **Notes:** `confirm_no_undo` defaults to `false`. The Godot plugin *may* use this as a safety gate.

#### Scenario 3: `confirm_no_undo` with truthy non-boolean
- **Description:** Pass a string `"yes"` or number `1` as `confirm_no_undo`. Zod's `.boolean()` will reject unless `z.coerce.boolean()` was used.
- **Params:** `{ "type_name": "Sprite2D", "property": "visible", "value": false, "confirm_no_undo": "yes" }`
- **Expected result:** Zod validation error — `"yes"` is not a boolean.
- **Notes:** The schema uses `z.boolean()`, not `z.coerce.boolean()`, so only `true`/`false` are accepted.

#### Scenario 4: Set a numeric property cross-scene
- **Description:** Set `scale` to `[2, 2]` on all `"Sprite2D"` nodes across all scenes.
- **Params:** `{ "type_name": "Sprite2D", "property": "scale", "value": [2, 2], "confirm_no_undo": true }`
- **Expected result:** Confirmation. All Sprite2D nodes across the project should have `scale = (2, 2)`.
- **Notes:** Tests Vector2 value serialization in cross-scene context.

#### Scenario 5: Type with zero matches across all scenes
- **Description:** Set a property on a type that doesn't exist in any scene.
- **Params:** `{ "type_name": "CharacterBody3D", "property": "visible", "value": false, "confirm_no_undo": true }`
- **Expected result:** JSON indicating zero nodes/scenes modified. Should not error.
- **Notes:** Tests graceful zero-match handling in multi-scene context.

#### Scenario 6: Missing `type_name`
- **Description:** Omit `type_name`.
- **Params:** `{ "property": "visible", "value": false, "confirm_no_undo": true }`
- **Expected result:** Zod validation error from MCP server.
- **Notes:** All three required params must be present.

#### Scenario 7: Missing `property`
- **Description:** Omit `property`.
- **Params:** `{ "type_name": "Sprite2D", "value": false, "confirm_no_undo": true }`
- **Expected result:** Zod validation error.

#### Scenario 8: Missing `value`
- **Description:** Omit `value`.
- **Params:** `{ "type_name": "Sprite2D", "property": "visible", "confirm_no_undo": true }`
- **Expected result:** Zod validation error.

#### Scenario 9: Godot editor not connected
- **Description:** Call when bridge is disconnected.
- **Params:** `{ "type_name": "Sprite2D", "property": "visible", "value": false, "confirm_no_undo": true }`
- **Expected result:** Error `"Godot request failed: ..."` with `isError: true`.

---

## Tool: `find_script_references`

**Description:** Find all scenes and nodes that use a specific script

**Handler:**
```typescript
async (args) => callGodot(bridge, 'batch/find_script_refs', args as Record<string, unknown>)
```

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `script_path` | `string` (ScriptPath) | ✅ Yes | — | Script file path (e.g. `"res://scripts/player.gd"`) |

---

### Test Scenarios

#### Scenario 1: Basic happy path — script with known usage
- **Description:** Call with `script_path` pointing to a script that is attached to at least one node in a scene.
- **Params:** `{ "script_path": "res://scripts/player.gd" }`
- **Expected result:** JSON listing all scenes and nodes that use this script. Not an error.
- **Notes:** Requires a script file that is actually used/attached in the project.

#### Scenario 2: Script referenced across multiple scenes
- **Description:** Call with a common utility script (e.g., an autoload or a base class script) attached in multiple scenes.
- **Params:** `{ "script_path": "res://scripts/common.gd" }`
- **Expected result:** JSON listing all scenes and their nodes that use this script. Count should be > 1.
- **Notes:** Validates multi-scene reference discovery.

#### Scenario 3: Script with zero references
- **Description:** Call with a script that exists in the project but is not attached to any node.
- **Params:** `{ "script_path": "res://scripts/unused.gd" }`
- **Expected result:** JSON with an empty list (e.g., `[]`). Should not error.
- **Notes:** Validates zero-reference case.

#### Scenario 4: Non-existent script path
- **Description:** Provide a path to a script that does not exist.
- **Params:** `{ "script_path": "res://scripts/does_not_exist.gd" }`
- **Expected result:** Error from Godot indicating file not found. `isError` may be `true`.
- **Notes:** Server should relay the Godot error gracefully.

#### Scenario 5: Path without `res://` prefix
- **Description:** Provide a relative path like `"scripts/player.gd"`.
- **Params:** `{ "script_path": "scripts/player.gd" }`
- **Expected result:** May resolve relative to project root or error. Test both outcomes.
- **Notes:** Tests path resolution. Prefer `res://` paths.

#### Scenario 6: Built-in Godot script (engine class)
- **Description:** Provide a path to a built-in GDScript in `res://` that is part of the Godot addon itself (e.g., `"res://addons/godot_mcp/services/mcp_runtime.gd"`).
- **Params:** `{ "script_path": "res://addons/godot_mcp/services/mcp_runtime.gd" }`
- **Expected result:** JSON listing where this addon script is used. Not an error.
- **Notes:** Tests that addon scripts are also traceable.

#### Scenario 7: Missing required `script_path` parameter
- **Description:** Call with empty params.
- **Params:** `{}`
- **Expected result:** Zod validation error from MCP server.
- **Notes:** `script_path` is required.

#### Scenario 8: Godot editor not connected
- **Description:** Call when bridge is disconnected.
- **Params:** `{ "script_path": "res://scripts/player.gd" }`
- **Expected result:** Error `"Godot request failed: ..."` with `isError: true`.

---

## Tool: `detect_circular_dependencies`

**Description:** Detect circular dependencies in the project (scripts, scenes, resources)

**Handler:**
```typescript
async () => callGodot(bridge, 'batch/detect_circular')
```

**Parameters:** None (empty schema `{}`). **Important:** Unlike most other tools, this handler does NOT forward `args` — it passes an implicit empty object to `callGodot`.

---

### Test Scenarios

#### Scenario 1: Basic happy path — project with no circular dependencies
- **Description:** Call on a well-structured project with no circular references.
- **Params:** `{}`
- **Expected result:** JSON indicating no circular dependencies found (e.g., `{ "circular_dependencies": [] }` or similar). Not an error.
- **Notes:** Tests the "clean project" case.

#### Scenario 2: Project with deliberate circular dependencies
- **Description:** If possible, create a test project where Scene A preloads Scene B which preloads Scene A; or a script in a preload cycle. Then call the tool.
- **Params:** `{}`
- **Expected result:** JSON listing the specific circular dependency chains found (e.g., `A -> B -> A`). Not an error (the tool detects, not fixes).
- **Notes:** Requires a deliberately broken project to test fully. Godot's own dependency validator may catch these before the plugin does.

#### Scenario 3: Empty / minimal project
- **Description:** Call on a brand-new empty project with minimal files.
- **Params:** `{}`
- **Expected result:** JSON with an empty circular dependency list. Should not error.
- **Notes:** Edge case — validates that the scan completes on near-empty projects.

#### Scenario 4: Call with extra params — verify they are IGNORED
- **Description:** Unlike most tools in this file, this handler ignores its `args` parameter. Pass extra params and verify they do NOT affect the output.
- **Params:** `{ "verbose": true, "max_depth": 10 }`
- **Expected result:** Same as Scenario 1 (all projects have same result). Extra params are silently ignored by the handler.
- **Notes:** Handler signature is `async () => callGodot(bridge, ...)` — no `args` parameter. Key behavioral difference from other tools.

#### Scenario 5: Godot editor not connected
- **Description:** Call when bridge is disconnected.
- **Params:** `{}`
- **Expected result:** Error `"Godot request failed: ..."` with `isError: true`.

---

## Cross-Cutting Concerns

### Bridge Failure Handling

All tools go through `callGodot()` which catches `bridge.sendRequest()` errors. If the WebSocket to Godot is severed:
- The error is caught
- Returns `{ content: [{ type: 'text', text: 'Godot request failed: <msg>' }], isError: true }`

### Mutation Safety

Two tools are **destructive mutations**:

| Tool | Scope | Safety Mechanism |
|------|-------|-----------------|
| `batch_set_property` | Current scene only | No specific safety gate — directly sets properties on all matching nodes in the open scene. |
| `cross_scene_set_property` | All scenes in project | Has optional `confirm_no_undo` boolean flag to explicitly acknowledge the destructive nature. The Godot plugin may enforce this gate. |

**Testing recommendation:** Always use a disposable/copy test project for the mutation tools (Scenarios 1–4 of `batch_set_property` and all scenarios of `cross_scene_set_property`). Never run these against a production project.

### Required Scene Context

Tools that operate on the "current scene":
- `find_nodes_by_type` — requires an open scene
- `find_signal_connections` — requires an open scene
- `batch_set_property` — requires an open scene

Tools that operate project-wide:
- `find_node_references` — searches across all scenes/scripts
- `get_scene_dependencies` — operates on a specific file, not necessarily open
- `cross_scene_set_property` — opens and modifies all scenes
- `find_script_references` — searches across all scenes
- `detect_circular_dependencies` — scans the entire project

### Schema Validation

All tools use Zod schemas. The MCP framework validates inputs against `inputSchema` before the handler is invoked. Key validation behaviors:

- `NodeType`, `PropertyName`, `ScriptPath`, and inline `z.string()` fields do NOT have `.optional()` — they are all required
- `PropertyValue` (`z.unknown()`) is required but accepts any JSON value including `null`
- `confirm_no_undo` (`z.boolean().optional().default(false)`) has an explicit `.optional()` with a default — it can be omitted
- Empty schemas (`{}`) accept any params; extras are forwarded to `callGodot` (except for `detect_circular_dependencies` which ignores them)

### Handler Parameter Forwarding

| Tool | Forwards `args`? | Notes |
|------|-----------------|-------|
| `find_nodes_by_type` | ✅ Yes | Passes `args as Record<string, unknown>` |
| `find_signal_connections` | ✅ Yes | Passes `args as Record<string, unknown>` |
| `batch_set_property` | ✅ Yes | Passes `args as Record<string, unknown>` |
| `find_node_references` | ✅ Yes | Passes `args as Record<string, unknown>` |
| `get_scene_dependencies` | ✅ Yes | Passes `args as Record<string, unknown>` |
| `cross_scene_set_property` | ✅ Yes | Passes `args as Record<string, unknown>` |
| `find_script_references` | ✅ Yes | Passes `args as Record<string, unknown>` |
| `detect_circular_dependencies` | ❌ No | `async () => callGodot(...)` — `args` is not used |

### Result Format

All tools return data as JSON-stringified text via `callGodot()`:
```typescript
const text = typeof result === 'string' ? result : JSON.stringify(result, null, 2);
return { content: [{ type: 'text', text }] };
```

On error:
```typescript
return { content: [{ type: 'text', text: `Godot request failed: ${error.message}` }], isError: true };
```

### Performance Considerations

- `cross_scene_set_property` may be slow on large projects (opens, modifies, and saves every scene file).
- `detect_circular_dependencies` scans the entire project dependency graph — may be slow on large projects.
- `find_node_references` and `find_script_references` search across all scenes and scripts.
- Tools scoped to the current scene (`find_nodes_by_type`, `find_signal_connections`, `batch_set_property`) are generally fast.
