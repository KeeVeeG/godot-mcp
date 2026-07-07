# Node Tools — Test Plan

**Source file:** `server/src/tools/node.ts`
**Shared types:** `server/src/tools/shared-types.ts`
**Number of tools:** 17
**Generated:** 2026-07-08

---

## Type Reference

| Zod schema | Underlying type | Description |
|---|---|---|
| `NodePath` | `z.string()` | Node path in scene tree (e.g. `'Player/Sprite2D'`). Use just the node name for root-level children (e.g. `'Player'`), or `''` for scene root |
| `ParentPath` | `z.string()` | Parent node path. Use `''` (empty string) for scene root, or a node name/path (e.g. `'Player'` or `'Player/Sprites'`) |
| `NodeType` | `z.string()` | Node type name (e.g. `'Sprite2D'`, `'CharacterBody3D'`) |
| `PropertyName` | `z.string()` | Property name (e.g. `'position'`, `'visible'`) |
| `PropertyValue` | `z.unknown()` | Any property value (number, string, boolean, array, object) |
| `OptionalProperties` | `z.record(z.unknown()).optional()` | Optional dictionary of property key-value pairs |
| `z.array(z.string())` | `string[]` | Array of strings |
| `z.string()` | string | Generic string |
| `z.number().int().min(0)` | number (int, >=0) | Non-negative integer |

---

## Tool: `add_node`

**Description:** Add a new node to the scene tree
**Handler:** `callGodot(bridge, 'node/add', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `parent_path` | `ParentPath` (string) | **Yes** | — | Parent node path (e.g. `'Player'` or `''` for root) |
| `type` | `NodeType` (string) | **Yes** | — | Node type name (e.g. `'Sprite2D'`, `'CharacterBody3D'`) |
| `name` | `z.string()` | **Yes** | — | Name for the new node |
| `properties` | `OptionalProperties` (record) | No | `undefined` | Optional property key-value pairs |

### Test Scenarios

#### Scenario 1: Happy path — add child to named parent
- **Description:** Add a `Sprite2D` as a child of the `Player` node
- **Params:** `{ "parent_path": "Player", "type": "Sprite2D", "name": "Hat" }`
- **Expected result:** Success. A new `Sprite2D` node named `Hat` is created as a child of `Player`.

#### Scenario 2: Happy path — add to scene root (empty parent_path)
- **Description:** Add a `Node3D` to the scene root
- **Params:** `{ "parent_path": "", "type": "Node3D", "name": "World" }`
- **Expected result:** Success. A new `Node3D` named `World` is added as a top-level child of the scene root.

#### Scenario 3: Happy path — add to nested path parent
- **Description:** Add a `Label` as a child of a nested path
- **Params:** `{ "parent_path": "UI/Panel", "type": "Label", "name": "ScoreLabel" }`
- **Expected result:** Success. A new `Label` named `ScoreLabel` is created under `UI/Panel`.

#### Scenario 4: Happy path — add with initial properties
- **Description:** Add a `Sprite2D` with position and scale properties
- **Params:** `{ "parent_path": "Player", "type": "Sprite2D", "name": "Weapon", "properties": { "position": [10, 5], "scale": [0.5, 0.5], "visible": true } }`
- **Expected result:** Success. Node created with position `[10, 5]`, scale `[0.5, 0.5]`, visible `true`.

#### Scenario 5: Happy path — add with single property
- **Description:** Add a `ColorRect` with just a color property
- **Params:** `{ "parent_path": "UI", "type": "ColorRect", "name": "Overlay", "properties": { "color": [0, 0, 0, 0.5] } }`
- **Expected result:** Success. Node created with the specified color.

#### Scenario 6: Happy path — add with empty properties
- **Description:** Add a node with explicitly empty `properties` object
- **Params:** `{ "parent_path": "Player", "type": "Node", "name": "Helper", "properties": {} }`
- **Expected result:** Success. Node created with default properties.

#### Scenario 7: Edge — missing `parent_path`
- **Description:** Call without the required `parent_path` parameter
- **Params:** `{ "type": "Sprite2D", "name": "Test" }`
- **Expected result:** Zod validation error (parent_path is required).

#### Scenario 8: Edge — missing `type`
- **Description:** Call without the required `type` parameter
- **Params:** `{ "parent_path": "Player", "name": "Test" }`
- **Expected result:** Zod validation error (type is required).

#### Scenario 9: Edge — missing `name`
- **Description:** Call without the required `name` parameter
- **Params:** `{ "parent_path": "Player", "type": "Sprite2D" }`
- **Expected result:** Zod validation error (name is required).

#### Scenario 10: Edge — non-existent parent
- **Description:** Add a node to a parent that does not exist
- **Params:** `{ "parent_path": "NonExistentNode", "type": "Sprite2D", "name": "Test" }`
- **Expected result:** Error from Godot (parent not found).

#### Scenario 11: Edge — invalid node type
- **Description:** Add a node with a non-existent class name
- **Params:** `{ "parent_path": "", "type": "FakeNodeType123", "name": "Test" }`
- **Expected result:** Error from Godot (unknown node type).

#### Scenario 12: Edge — duplicate name
- **Description:** Add a node with a name that already exists under the same parent
- **Params:** `{ "parent_path": "Player", "type": "Sprite2D", "name": "Hat" }` (assuming `Hat` already exists)
- **Expected result:** Error from Godot or auto-renamed (e.g., `Hat2`). Behavior depends on Godot version.

#### Scenario 13: Edge — empty string name
- **Description:** Add a node with an empty string name
- **Params:** `{ "parent_path": "Player", "type": "Node", "name": "" }`
- **Expected result:** Error from Godot (invalid name) or auto-generated name.

#### Scenario 14: Edge — properties with invalid key
- **Description:** Add a node with a non-existent property
- **Params:** `{ "parent_path": "Player", "type": "Sprite2D", "name": "Test", "properties": { "nonexistent_prop": 42 } }`
- **Expected result:** Error from Godot (property does not exist on Sprite2D).

#### Scenario 15: Edge — properties value wrong type
- **Description:** Add a node with a property value of the wrong type
- **Params:** `{ "parent_path": "Player", "type": "Sprite2D", "name": "Test", "properties": { "visible": "not_a_boolean" } }`
- **Expected result:** Error from Godot (type mismatch for property).

#### Scenario 16: Edge — parent_path is number
- **Description:** Pass a number instead of string for parent_path
- **Params:** `{ "parent_path": 123, "type": "Sprite2D", "name": "Test" }`
- **Expected result:** Zod validation error (expected string, got number).

#### Scenario 17: Edge — type is number
- **Description:** Pass a number instead of string for type
- **Params:** `{ "parent_path": "Player", "type": 123, "name": "Test" }`
- **Expected result:** Zod validation error (expected string, got number).

#### Scenario 18: Edge — no scene open
- **Description:** Call when no scene is open in the editor
- **Params:** `{ "parent_path": "", "type": "Node", "name": "Test" }`
- **Expected result:** Error from Godot (no open scene).

---

## Tool: `delete_node`

**Description:** Delete a node from the scene tree
**Handler:** `callGodot(bridge, 'node/delete', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path to delete (e.g. `'Player/Sprite2D'`) |

### Test Scenarios

#### Scenario 1: Happy path — delete leaf node
- **Description:** Delete a leaf node (no children) by path
- **Params:** `{ "path": "Player/Hat" }`
- **Expected result:** Success. The node `Hat` is removed from the scene tree.

#### Scenario 2: Happy path — delete root-level child
- **Description:** Delete a top-level node using just its name
- **Params:** `{ "path": "World" }`
- **Expected result:** Success. The `World` node is deleted.

#### Scenario 3: Happy path — delete node with children
- **Description:** Delete a parent node that has child nodes
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success. The `Player` node and all its children are removed.

#### Scenario 4: Happy path — delete scene root
- **Description:** Delete the scene root using empty string
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot (cannot delete scene root) or succeeds if supported.

#### Scenario 5: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 6: Edge — non-existent node
- **Description:** Delete a node that does not exist in the scene
- **Params:** `{ "path": "NonExistent/FakeNode" }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 7: Edge — empty string path
- **Description:** Delete with empty string — may target root (see Scenario 4)
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot (cannot delete root) or root deletion if supported.

#### Scenario 8: Edge — path is number
- **Description:** Pass a number instead of string for path
- **Params:** `{ "path": 42 }`
- **Expected result:** Zod validation error (expected string, got number).

#### Scenario 9: Edge — path is array
- **Description:** Pass an array instead of string for path
- **Params:** `{ "path": ["Player"] }`
- **Expected result:** Zod validation error (expected string, got array).

#### Scenario 10: Edge — no scene open
- **Description:** Call when no scene is open in the editor
- **Params:** `{ "path": "SomeNode" }`
- **Expected result:** Error from Godot (no open scene).

---

## Tool: `duplicate_node`

**Description:** Duplicate a node in the scene tree
**Handler:** `callGodot(bridge, 'node/duplicate', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path to duplicate |

### Test Scenarios

#### Scenario 1: Happy path — duplicate leaf node
- **Description:** Duplicate a leaf node like a sprite
- **Params:** `{ "path": "Player/Sprite2D" }`
- **Expected result:** Success. A copy of `Sprite2D` is created as a sibling with a modified name (e.g., `Sprite2D2`).

#### Scenario 2: Happy path — duplicate node with children
- **Description:** Duplicate a node that has child nodes
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success. `Player` and all its children are duplicated. The duplicate gets a name like `Player2`.

#### Scenario 3: Happy path — duplicate root-level child
- **Description:** Duplicate a top-level child node
- **Params:** `{ "path": "World" }`
- **Expected result:** Success. A duplicate `World2` is created at root level.

#### Scenario 4: Happy path — duplicate root node
- **Description:** Attempt to duplicate the scene root
- **Params:** `{ "path": "" }`
- **Expected result:** Error from Godot (cannot duplicate scene root).

#### Scenario 5: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 6: Edge — non-existent node
- **Description:** Duplicate a node that does not exist
- **Params:** `{ "path": "FakeNode/DoesNotExist" }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 7: Edge — path is number
- **Description:** Pass a number instead of string for path
- **Params:** `{ "path": 1 }`
- **Expected result:** Zod validation error (expected string, got number).

#### Scenario 8: Edge — no scene open
- **Description:** Call when no scene is open
- **Params:** `{ "path": "SomeNode" }`
- **Expected result:** Error from Godot (no open scene).

---

## Tool: `move_node`

**Description:** Move a node to a new parent in the scene tree
**Handler:** `callGodot(bridge, 'node/move', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path to move |
| `new_parent` | `z.string()` | **Yes** | — | New parent node path |
| `index` | `z.number().int().min(0)` | No | — | Child index position |

### Test Scenarios

#### Scenario 1: Happy path — reparent to another node
- **Description:** Move a node from one parent to another
- **Params:** `{ "path": "Player/Hat", "new_parent": "World" }`
- **Expected result:** Success. `Hat` becomes a child of `World` (appended at end).

#### Scenario 2: Happy path — move with index 0
- **Description:** Move a node to be the first child of a new parent
- **Params:** `{ "path": "Player/Hat", "new_parent": "World", "index": 0 }`
- **Expected result:** Success. `Hat` becomes the first child of `World`.

#### Scenario 3: Happy path — move with index in middle
- **Description:** Move a node to a specific position among siblings
- **Params:** `{ "path": "UI/Label", "new_parent": "Player", "index": 2 }`
- **Expected result:** Success. The node is inserted at position 2 among siblings.

#### Scenario 4: Happy path — move without index (append)
- **Description:** Move without specifying index; should append at end
- **Params:** `{ "path": "Enemy/Sprite", "new_parent": "Player" }`
- **Expected result:** Success. Node appended as last child of `Player`.

#### Scenario 5: Happy path — move to root
- **Description:** Move a node to become a direct child of the scene root
- **Params:** `{ "path": "Player/Hat", "new_parent": "" }`
- **Expected result:** Success. `Hat` becomes a top-level child of the scene root.

#### Scenario 6: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{ "new_parent": "Player" }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 7: Edge — missing `new_parent`
- **Description:** Call without the required `new_parent` parameter
- **Params:** `{ "path": "Player/Hat" }`
- **Expected result:** Zod validation error (new_parent is required).

#### Scenario 8: Edge — non-existent source node
- **Description:** Move a node that does not exist
- **Params:** `{ "path": "FakeNode", "new_parent": "Player" }`
- **Expected result:** Error from Godot (source node not found).

#### Scenario 9: Edge — non-existent target parent
- **Description:** Move to a parent that does not exist
- **Params:** `{ "path": "Player/Hat", "new_parent": "DoesNotExist" }`
- **Expected result:** Error from Godot (target parent not found).

#### Scenario 10: Edge — index negative
- **Description:** Provide a negative index value
- **Params:** `{ "path": "Player/Hat", "new_parent": "World", "index": -1 }`
- **Expected result:** Zod validation error (`z.number().int().min(0)` rejects negatives).

#### Scenario 11: Edge — index as float
- **Description:** Provide a non-integer index
- **Params:** `{ "path": "Player/Hat", "new_parent": "World", "index": 1.5 }`
- **Expected result:** Zod validation error (`z.number().int()` rejects floats).

#### Scenario 12: Edge — index as string
- **Description:** Provide index as a string
- **Params:** `{ "path": "Player/Hat", "new_parent": "World", "index": "0" }`
- **Expected result:** Zod validation error or coercion (expected number, got string).

#### Scenario 13: Edge — move to self
- **Description:** Try moving a node to itself
- **Params:** `{ "path": "Player", "new_parent": "Player" }`
- **Expected result:** Error from Godot (cannot reparent a node to itself).

#### Scenario 14: Edge — move to own child (cycle)
- **Description:** Try moving a parent into one of its own children
- **Params:** `{ "path": "Player", "new_parent": "Player/Hat" }`
- **Expected result:** Error from Godot (would create cyclic dependency).

#### Scenario 15: Edge — move scene root
- **Description:** Try to reparent the scene root
- **Params:** `{ "path": "", "new_parent": "Player" }`
- **Expected result:** Error from Godot (cannot reparent scene root).

#### Scenario 16: Edge — no scene open
- **Description:** Call when no scene is open
- **Params:** `{ "path": "A", "new_parent": "B" }`
- **Expected result:** Error from Godot (no open scene).

#### Scenario 17: Edge — move to same parent (no-op)
- **Description:** Move a node to its current parent
- **Params:** `{ "path": "Player/Hat", "new_parent": "Player" }`
- **Expected result:** May succeed as no-op or return error about same parent.

---

## Tool: `update_property`

**Description:** Update a property value on a node
**Handler:** `callGodot(bridge, 'node/update_property', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path in the scene tree (e.g. `'Player/Sprite2D'`). Use just the node name for root-level children (e.g. `'Player'`), or empty string `''` for the scene root itself. |
| `property` | `PropertyName` (string) | **Yes** | — | Property name (e.g. `'position'`, `'visible'`) |
| `value` | `PropertyValue` (`z.unknown()`) | **Yes** | — | Property value |

### Test Scenarios

#### Scenario 1: Happy path — set boolean property
- **Description:** Set the `visible` property to `false`
- **Params:** `{ "path": "Player/Sprite2D", "property": "visible", "value": false }`
- **Expected result:** Success. The node becomes invisible.

#### Scenario 2: Happy path — set string property
- **Description:** Set the `name` property
- **Params:** `{ "path": "Player", "property": "name", "value": "Hero" }`
- **Expected result:** Success. The node is renamed to `Hero`.

#### Scenario 3: Happy path — set numeric property
- **Description:** Set a float property like `scale`
- **Params:** `{ "path": "Player/Sprite2D", "property": "rotation", "value": 1.57 }`
- **Expected result:** Success. Rotation set to ~PI/2 radians.

#### Scenario 4: Happy path — set Vector2 position
- **Description:** Set the position as an array
- **Params:** `{ "path": "Player", "property": "position", "value": [100, 200] }`
- **Expected result:** Success. Position set to `Vector2(100, 200)`.

#### Scenario 5: Happy path — set Color value
- **Description:** Set a color property
- **Params:** `{ "path": "UI/ColorRect", "property": "color", "value": [1, 0, 0, 1] }`
- **Expected result:** Success. Color set to red.

#### Scenario 6: Happy path — set null value
- **Description:** Set a property to null
- **Params:** `{ "path": "Player/Sprite2D", "property": "texture", "value": null }`
- **Expected result:** Success or error depending on whether the property is nullable.

#### Scenario 7: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{ "property": "visible", "value": true }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 8: Edge — missing `property`
- **Description:** Call without the required `property` parameter
- **Params:** `{ "path": "Player", "value": true }`
- **Expected result:** Zod validation error (property is required).

#### Scenario 9: Edge — missing `value`
- **Description:** Call without the required `value` parameter
- **Params:** `{ "path": "Player", "property": "visible" }`
- **Expected result:** Zod validation error (value is required).

#### Scenario 10: Edge — non-existent node
- **Description:** Update a property on a node that does not exist
- **Params:** `{ "path": "FakeNode", "property": "visible", "value": true }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 11: Edge — non-existent property
- **Description:** Set a property name that does not exist on the node type
- **Params:** `{ "path": "Player", "property": "superpower_level", "value": 9000 }`
- **Expected result:** Error from Godot (property not found on node).

#### Scenario 12: Edge — value type mismatch
- **Description:** Set a boolean property to a string value
- **Params:** `{ "path": "Player/Sprite2D", "property": "visible", "value": "yes" }`
- **Expected result:** Error from Godot (type mismatch).

#### Scenario 13: Edge — path is empty string (scene root)
- **Description:** Set a property on the scene root
- **Params:** `{ "path": "", "property": "name", "value": "NewRootName" }`
- **Expected result:** Might succeed or fail depending on Godot behavior with root node.

#### Scenario 14: Edge — value is complex object
- **Description:** Set a property to a deeply nested object
- **Params:** `{ "path": "Player", "property": "position", "value": { "x": 10, "y": 20 } }`
- **Expected result:** May succeed (Godot object deserialization) or error. Depends on Godot's JSON parsing.

#### Scenario 15: Edge — no scene open
- **Description:** Call when no scene is open
- **Params:** `{ "path": "Player", "property": "visible", "value": false }`
- **Expected result:** Error from Godot (no open scene).

---

## Tool: `get_node_properties`

**Description:** Get all properties of a node
**Handler:** `callGodot(bridge, 'node/get_properties', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path in the scene tree (e.g. `'Player/Sprite2D'`). Use just the node name for root-level children (e.g. `'Player'`), or empty string `''` for the scene root itself. |

### Test Scenarios

#### Scenario 1: Happy path — get properties of a leaf node
- **Description:** Retrieve all properties of a `Sprite2D` node
- **Params:** `{ "path": "Player/Sprite2D" }`
- **Expected result:** Success. Returns a JSON object with all serializable properties and their current values (e.g., `position`, `scale`, `rotation`, `visible`, `texture`, `modulate`, etc.).

#### Scenario 2: Happy path — get properties of a root-level node
- **Description:** Retrieve properties of a top-level child by name
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success. Returns all properties of the `Player` node.

#### Scenario 3: Happy path — get properties of scene root
- **Description:** Get properties of the scene root using empty string
- **Params:** `{ "path": "" }`
- **Expected result:** Success. Returns properties of the root node (e.g., `name`, `scene_file_path`, etc.).

#### Scenario 4: Happy path — verify a specific property value
- **Description:** Get properties and check that a known property has the expected value
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success. The returned object contains the `name` property with value `"Player"`.

#### Scenario 5: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 6: Edge — non-existent node
- **Description:** Get properties of a node that does not exist
- **Params:** `{ "path": "NonExistent/Node" }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 7: Edge — path is number
- **Description:** Pass a number instead of string for path
- **Params:** `{ "path": 42 }`
- **Expected result:** Zod validation error (expected string, got number).

#### Scenario 8: Edge — no scene open
- **Description:** Call when no scene is open
- **Params:** `{ "path": "Player" }`
- **Expected result:** Error from Godot (no open scene).

---

## Tool: `add_resource`

**Description:** Add a resource (material, texture, etc.) to a node property
**Handler:** `callGodot(bridge, 'node/add_resource', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `node_path` | `NodePath` (string) | **Yes** | — | Node to add resource to (e.g. `'Player'` or `'Player/Cube'`) |
| `resource_type` | `z.string()` | **Yes** | — | Resource type (e.g. `'Material'`, `'Texture2D'`) |
| `properties` | `OptionalProperties` (record) | No | `undefined` | Optional property key-value pairs |

### Test Scenarios

#### Scenario 1: Happy path — add a Material resource
- **Description:** Add a `StandardMaterial3D` (type `'Material'`) to a `MeshInstance3D`
- **Params:** `{ "node_path": "World/Cube", "resource_type": "Material" }`
- **Expected result:** Success. A new material is created and assigned to the mesh node.

#### Scenario 2: Happy path — add a Texture2D resource
- **Description:** Add a `Texture2D` to a node
- **Params:** `{ "node_path": "Player/Sprite2D", "resource_type": "Texture2D" }`
- **Expected result:** Success. A new texture resource is created.

#### Scenario 3: Happy path — add resource with properties
- **Description:** Add a material with specific properties (color, metallic, roughness)
- **Params:** `{ "node_path": "World/Cube", "resource_type": "Material", "properties": { "albedo_color": [0, 0, 1, 1], "metallic": 0.8, "roughness": 0.2 } }`
- **Expected result:** Success. A blue metallic material is created and assigned.

#### Scenario 4: Happy path — add resource with empty properties
- **Description:** Add a resource with explicitly empty properties
- **Params:** `{ "node_path": "Player/Sprite2D", "resource_type": "Material", "properties": {} }`
- **Expected result:** Success. Resource created with default values.

#### Scenario 5: Happy path — add to nested node path
- **Description:** Add a resource to a deeply nested node
- **Params:** `{ "node_path": "World/Enemies/Boss/Mesh", "resource_type": "Material" }`
- **Expected result:** Success. Material assigned to the nested mesh node.

#### Scenario 6: Edge — missing `node_path`
- **Description:** Call without the required `node_path` parameter
- **Params:** `{ "resource_type": "Material" }`
- **Expected result:** Zod validation error (node_path is required).

#### Scenario 7: Edge — missing `resource_type`
- **Description:** Call without the required `resource_type` parameter
- **Params:** `{ "node_path": "Player" }`
- **Expected result:** Zod validation error (resource_type is required).

#### Scenario 8: Edge — invalid resource type
- **Description:** Use a non-existent resource type string
- **Params:** `{ "node_path": "Player", "resource_type": "FakeResourceType" }`
- **Expected result:** Error from Godot (unknown resource type).

#### Scenario 9: Edge — non-existent node
- **Description:** Add resource to a node that does not exist
- **Params:** `{ "node_path": "NonExistentNode", "resource_type": "Material" }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 10: Edge — invalid property name
- **Description:** Add resource with a property that does not exist on the resource type
- **Params:** `{ "node_path": "World/Cube", "resource_type": "Material", "properties": { "fake_prop": 42 } }`
- **Expected result:** Error from Godot (property not found on resource).

#### Scenario 11: Edge — node_path is empty string
- **Description:** Try adding a resource to the scene root
- **Params:** `{ "node_path": "", "resource_type": "Material" }`
- **Expected result:** Error from Godot (invalid target for material).

#### Scenario 12: Edge — no scene open
- **Description:** Call when no scene is open
- **Params:** `{ "node_path": "Player", "resource_type": "Material" }`
- **Expected result:** Error from Godot (no open scene).

---

## Tool: `set_anchor_preset`

**Description:** Set anchor preset on a Control node
**Handler:** `callGodot(bridge, 'node/set_anchor_preset', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Control node path |
| `preset` | `z.string()` | **Yes** | — | Anchor preset name (e.g. `'full_rect'`, `'center'`, `'top_left'`) |

### Test Scenarios

#### Scenario 1: Happy path — set preset `full_rect`
- **Description:** Apply full rectangle anchor preset to a Control node
- **Params:** `{ "path": "UI/Panel", "preset": "full_rect" }`
- **Expected result:** Success. The Control node stretches to fill the entire parent.

#### Scenario 2: Happy path — set preset `center`
- **Description:** Center a Control node in its parent
- **Params:** `{ "path": "UI/Label", "preset": "center" }`
- **Expected result:** Success. The Control node is anchored to the center of its parent.

#### Scenario 3: Happy path — set preset `top_left`
- **Description:** Anchor to top-left
- **Params:** `{ "path": "UI/Button", "preset": "top_left" }`
- **Expected result:** Success. Anchored to top-left corner.

#### Scenario 4: Happy path — test additional preset values
- **Description:** Try various anchor preset names (tool does not use an enum — just a string)
- **Params (variant a):** `{ "path": "UI/Score", "preset": "top_right" }`
- **Params (variant b):** `{ "path": "UI/Score", "preset": "bottom_left" }`
- **Params (variant c):** `{ "path": "UI/Score", "preset": "bottom_right" }`
- **Params (variant d):** `{ "path": "UI/Score", "preset": "center_top" }`
- **Params (variant e):** `{ "path": "UI/Score", "preset": "center_bottom" }`
- **Params (variant f):** `{ "path": "UI/Score", "preset": "center_left" }`
- **Params (variant g):** `{ "path": "UI/Score", "preset": "center_right" }`
- **Params (variant h):** `{ "path": "UI/Score", "preset": "top_wide" }`
- **Params (variant i):** `{ "path": "UI/Score", "preset": "bottom_wide" }`
- **Params (variant j):** `{ "path": "UI/Score", "preset": "left_wide" }`
- **Params (variant k):** `{ "path": "UI/Score", "preset": "right_wide" }`
- **Params (variant l):** `{ "path": "UI/Score", "preset": "vcenter_wide" }`
- **Params (variant m):** `{ "path": "UI/Score", "preset": "hcenter_wide" }`
- **Expected result:** Each should succeed if the preset name is valid in Godot.

#### Scenario 5: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{ "preset": "full_rect" }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 6: Edge — missing `preset`
- **Description:** Call without the required `preset` parameter
- **Params:** `{ "path": "UI/Panel" }`
- **Expected result:** Zod validation error (preset is required).

#### Scenario 7: Edge — non-existent node
- **Description:** Set anchor preset on a node that does not exist
- **Params:** `{ "path": "FakeUI/Panel", "preset": "center" }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 8: Edge — invalid preset string
- **Description:** Use an unrecognized preset name
- **Params:** `{ "path": "UI/Panel", "preset": "invalid_preset_name" }`
- **Expected result:** Error from Godot (unknown preset).

#### Scenario 9: Edge — non-Control node
- **Description:** Apply anchor preset to a node that is not a Control (e.g., a Node2D)
- **Params:** `{ "path": "Player", "preset": "full_rect" }`
- **Expected result:** Error from Godot (node is not a Control-derived type).

#### Scenario 10: Edge — empty string preset
- **Description:** Use an empty string as preset
- **Params:** `{ "path": "UI/Panel", "preset": "" }`
- **Expected result:** Error from Godot (invalid preset).

#### Scenario 11: Edge — no scene open
- **Description:** Call when no scene is open
- **Params:** `{ "path": "UI/Panel", "preset": "center" }`
- **Expected result:** Error from Godot (no open scene).

---

## Tool: `rename_node`

**Description:** Rename a node in the scene tree
**Handler:** `callGodot(bridge, 'node/rename', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Current node path |
| `new_name` | `z.string()` | **Yes** | — | New name for the node |

### Test Scenarios

#### Scenario 1: Happy path — rename a simple node
- **Description:** Rename `Player` to `Hero`
- **Params:** `{ "path": "Player", "new_name": "Hero" }`
- **Expected result:** Success. The node is now named `Hero`. All existing references to "Player" name may break.

#### Scenario 2: Happy path — rename a nested node
- **Description:** Rename a deeply nested child node
- **Params:** `{ "path": "Player/Body/Head", "new_name": "Skull" }`
- **Expected result:** Success. Node renamed to `Skull` under `Player/Body/`.

#### Scenario 3: Happy path — rename to same name (no-op)
- **Description:** Rename a node to its current name
- **Params:** `{ "path": "Player", "new_name": "Player" }`
- **Expected result:** Success or no-op. Node keeps the same name.

#### Scenario 4: Happy path — rename with spaces
- **Description:** Rename to a name containing spaces
- **Params:** `{ "path": "Player", "new_name": "Player Character" }`
- **Expected result:** Success. Node name is set to include spaces.

#### Scenario 5: Happy path — rename root node
- **Description:** Rename the scene root node
- **Params:** `{ "path": "", "new_name": "MySceneRoot" }`
- **Expected result:** Success or error (may fail since root name is tied to scene).

#### Scenario 6: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{ "new_name": "Hero" }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 7: Edge — missing `new_name`
- **Description:** Call without the required `new_name` parameter
- **Params:** `{ "path": "Player" }`
- **Expected result:** Zod validation error (new_name is required).

#### Scenario 8: Edge — non-existent node
- **Description:** Rename a node that does not exist
- **Params:** `{ "path": "Ghost", "new_name": "Poltergeist" }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 9: Edge — duplicate name in same parent
- **Description:** Rename a node to a name already used by a sibling
- **Params:** `{ "path": "Player/Sprite2D", "new_name": "Hat" }` (assuming `Hat` already exists under `Player`)
- **Expected result:** Error from Godot (name conflict) or auto-renamed.

#### Scenario 10: Edge — empty string new_name
- **Description:** Rename a node to an empty string
- **Params:** `{ "path": "Player", "new_name": "" }`
- **Expected result:** Error from Godot (empty name not allowed).

#### Scenario 11: Edge — new_name is number
- **Description:** Pass a number instead of string for new_name
- **Params:** `{ "path": "Player", "new_name": 123 }`
- **Expected result:** Zod validation error (expected string, got number).

#### Scenario 12: Edge — path is number
- **Description:** Pass a number for path
- **Params:** `{ "path": 42, "new_name": "Test" }`
- **Expected result:** Zod validation error (expected string, got number).

#### Scenario 13: Edge — no scene open
- **Description:** Call when no scene is open
- **Params:** `{ "path": "Player", "new_name": "Hero" }`
- **Expected result:** Error from Godot (no open scene).

---

## Tool: `connect_signal`

**Description:** Connect a signal from one node to another node's method
**Handler:** `callGodot(bridge, 'node/connect_signal', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `source` | `NodePath` (string) | **Yes** | — | Node path emitting the signal |
| `signal` | `z.string()` | **Yes** | — | Signal name |
| `target` | `NodePath` (string) | **Yes** | — | Node path receiving the signal |
| `method` | `z.string()` | **Yes** | — | Method to call on the target node |

### Test Scenarios

#### Scenario 1: Happy path — connect `pressed` signal from Button to parent
- **Description:** Connect a Button's `pressed` signal to a method on its parent
- **Params:** `{ "source": "UI/Button", "signal": "pressed", "target": "UI", "method": "_on_button_pressed" }`
- **Expected result:** Success. When `Button` is pressed, `UI._on_button_pressed()` is called.

#### Scenario 2: Happy path — connect `body_entered` signal between siblings
- **Description:** Connect an Area2D's `body_entered` signal to a sibling node
- **Params:** `{ "source": "World/Area2D", "signal": "body_entered", "target": "World/Enemy", "method": "_on_body_entered" }`
- **Expected result:** Success. Signal connected between sibling nodes.

#### Scenario 3: Happy path — connect signal from self to self
- **Description:** Connect a signal from a node to its own method
- **Params:** `{ "source": "Player", "signal": "ready", "target": "Player", "method": "_on_ready" }`
- **Expected result:** Success. Self-referencing signal connection.

#### Scenario 4: Happy path — connect with arguments
- **Description:** Connect a `tree_entered` signal
- **Params:** `{ "source": "Player", "signal": "tree_entered", "target": "Player", "method": "_setup" }`
- **Expected result:** Success. Signal connected. When node enters tree, `_setup()` is called.

#### Scenario 5: Edge — missing `source`
- **Description:** Call without the required `source` parameter
- **Params:** `{ "signal": "pressed", "target": "UI", "method": "_on_press" }`
- **Expected result:** Zod validation error (source is required).

#### Scenario 6: Edge — missing `signal`
- **Description:** Call without the required `signal` parameter
- **Params:** `{ "source": "UI/Button", "target": "UI", "method": "_on_press" }`
- **Expected result:** Zod validation error (signal is required).

#### Scenario 7: Edge — missing `target`
- **Description:** Call without the required `target` parameter
- **Params:** `{ "source": "UI/Button", "signal": "pressed", "method": "_on_press" }`
- **Expected result:** Zod validation error (target is required).

#### Scenario 8: Edge — missing `method`
- **Description:** Call without the required `method` parameter
- **Params:** `{ "source": "UI/Button", "signal": "pressed", "target": "UI" }`
- **Expected result:** Zod validation error (method is required).

#### Scenario 9: Edge — non-existent source node
- **Description:** Connect from a non-existent source
- **Params:** `{ "source": "FakeButton", "signal": "pressed", "target": "UI", "method": "_on_press" }`
- **Expected result:** Error from Godot (source node not found).

#### Scenario 10: Edge — non-existent target node
- **Description:** Connect to a non-existent target
- **Params:** `{ "source": "UI/Button", "signal": "pressed", "target": "FakeTarget", "method": "_on_press" }`
- **Expected result:** Error from Godot (target node not found).

#### Scenario 11: Edge — non-existent signal
- **Description:** Connect a signal that does not exist on the source node
- **Params:** `{ "source": "UI/Button", "signal": "fake_signal", "target": "UI", "method": "_handler" }`
- **Expected result:** Error from Godot (signal not found on source node type).

#### Scenario 12: Edge — non-existent method on target
- **Description:** Connect to a method that does not exist on the target node
- **Params:** `{ "source": "UI/Button", "signal": "pressed", "target": "UI", "method": "_nonexistent_method" }`
- **Expected result:** Error from Godot (method not found on target) or succeeds (Godot may allow it and error at runtime).

#### Scenario 13: Edge — duplicate connection
- **Description:** Connect a signal that is already connected (same source, signal, target, method)
- **Params:** Re-run Scenario 1 with the same params.
- **Expected result:** Error from Godot (signal already connected).

#### Scenario 14: Edge — empty string params
- **Description:** Use empty strings for all params
- **Params:** `{ "source": "", "signal": "", "target": "", "method": "" }`
- **Expected result:** Error from Godot (invalid source/target or empty signal/method).

#### Scenario 15: Edge — no scene open
- **Description:** Call when no scene is open
- **Params:** `{ "source": "A", "signal": "s", "target": "B", "method": "m" }`
- **Expected result:** Error from Godot (no open scene).

---

## Tool: `disconnect_signal`

**Description:** Disconnect a signal connection
**Handler:** `callGodot(bridge, 'node/disconnect_signal', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `source` | `NodePath` (string) | **Yes** | — | Node path that emits the signal |
| `signal` | `z.string()` | **Yes** | — | Signal name |
| `target` | `NodePath` (string) | **Yes** | — | Node path that receives the signal |
| `method` | `z.string()` | **Yes** | — | Method that was connected |

### Test Scenarios

#### Scenario 1: Happy path — disconnect previously connected signal
- **Description:** Disconnect a signal that was previously connected via `connect_signal`
- **Params:** `{ "source": "UI/Button", "signal": "pressed", "target": "UI", "method": "_on_button_pressed" }`
- **Expected result:** Success. The signal connection is removed. Pressing the button no longer calls the method.
- **Notes:** Requires the connection from `connect_signal` Scenario 1 to exist first.

#### Scenario 2: Happy path — disconnect self-to-self signal
- **Description:** Disconnect a self-referencing connection
- **Params:** `{ "source": "Player", "signal": "ready", "target": "Player", "method": "_on_ready" }`
- **Expected result:** Success. Self-referencing signal disconnected.

#### Scenario 3: Edge — missing `source`
- **Description:** Call without the required `source` parameter
- **Params:** `{ "signal": "pressed", "target": "UI", "method": "_handler" }`
- **Expected result:** Zod validation error (source is required).

#### Scenario 4: Edge — missing `signal`
- **Description:** Call without the required `signal` parameter
- **Params:** `{ "source": "UI/Button", "target": "UI", "method": "_handler" }`
- **Expected result:** Zod validation error (signal is required).

#### Scenario 5: Edge — missing `target`
- **Description:** Call without the required `target` parameter
- **Params:** `{ "source": "UI/Button", "signal": "pressed", "method": "_handler" }`
- **Expected result:** Zod validation error (target is required).

#### Scenario 6: Edge — missing `method`
- **Description:** Call without the required `method` parameter
- **Params:** `{ "source": "UI/Button", "signal": "pressed", "target": "UI" }`
- **Expected result:** Zod validation error (method is required).

#### Scenario 7: Edge — non-existent connection
- **Description:** Disconnect a signal that was never connected
- **Params:** `{ "source": "UI/Button", "signal": "pressed", "target": "UI", "method": "_never_connected" }`
- **Expected result:** Error from Godot (no such connection exists).

#### Scenario 8: Edge — non-existent source node
- **Description:** Disconnect from a non-existent source
- **Params:** `{ "source": "FakeNode", "signal": "pressed", "target": "UI", "method": "_handler" }`
- **Expected result:** Error from Godot (source node not found).

#### Scenario 9: Edge — non-existent signal on source
- **Description:** Disconnect a signal name that doesn't exist on the source type
- **Params:** `{ "source": "UI/Button", "signal": "imaginary", "target": "UI", "method": "_handler" }`
- **Expected result:** Error from Godot (signal not found).

#### Scenario 10: Edge — empty strings
- **Description:** Use empty strings for all params
- **Params:** `{ "source": "", "signal": "", "target": "", "method": "" }`
- **Expected result:** Error from Godot (invalid params).

#### Scenario 11: Edge — no scene open
- **Description:** Call when no scene is open
- **Params:** `{ "source": "A", "signal": "s", "target": "B", "method": "m" }`
- **Expected result:** Error from Godot (no open scene).

---

## Tool: `get_node_groups`

**Description:** Get all groups a node belongs to
**Handler:** `callGodot(bridge, 'node/get_groups', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path in the scene tree (e.g. `'Player/Sprite2D'`). Use just the node name for root-level children (e.g. `'Player'`), or empty string `''` for the scene root itself. |

### Test Scenarios

#### Scenario 1: Happy path — node with groups
- **Description:** Get groups for a node that belongs to one or more groups
- **Params:** `{ "path": "Player" }`
- **Expected result:** Success. Returns an array of group name strings, e.g., `["players", "characters"]`.

#### Scenario 2: Happy path — node with no groups
- **Description:** Get groups for a node that is not in any group
- **Params:** `{ "path": "UI/Label" }`
- **Expected result:** Success. Returns an empty array `[]`.

#### Scenario 3: Happy path — scene root groups
- **Description:** Get groups for the scene root
- **Params:** `{ "path": "" }`
- **Expected result:** Success. Returns array of groups (likely empty unless root was added to groups).

#### Scenario 4: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (path is required).

#### Scenario 5: Edge — non-existent node
- **Description:** Get groups for a node that does not exist
- **Params:** `{ "path": "NonExistent" }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 6: Edge — path is number
- **Description:** Pass a number instead of string
- **Params:** `{ "path": 123 }`
- **Expected result:** Zod validation error (expected string, got number).

#### Scenario 7: Edge — no scene open
- **Description:** Call when no scene is open
- **Params:** `{ "path": "Player" }`
- **Expected result:** Error from Godot (no open scene).

---

## Tool: `set_node_groups`

**Description:** Set the groups a node belongs to (replaces existing groups)
**Handler:** `callGodot(bridge, 'node/set_groups', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `path` | `NodePath` (string) | **Yes** | — | Node path in the scene tree (e.g. `'Player/Sprite2D'`). Use just the node name for root-level children (e.g. `'Player'`), or empty string `''` for the scene root itself. |
| `groups` | `z.array(z.string())` | **Yes** | — | List of group names |

### Test Scenarios

#### Scenario 1: Happy path — set single group
- **Description:** Replace a node's groups with a single group
- **Params:** `{ "path": "Player", "groups": ["players"] }`
- **Expected result:** Success. Node now belongs only to the `"players"` group. Any previously assigned groups are removed.

#### Scenario 2: Happy path — set multiple groups
- **Description:** Assign a node to multiple groups
- **Params:** `{ "path": "Player", "groups": ["players", "characters", "animated"] }`
- **Expected result:** Success. Node belongs to all three groups.

#### Scenario 3: Happy path — clear all groups
- **Description:** Remove a node from all groups by passing an empty array
- **Params:** `{ "path": "Player", "groups": [] }`
- **Expected result:** Success. Node is removed from all groups.

#### Scenario 4: Happy path — set groups on scene root
- **Description:** Set groups on the scene root
- **Params:** `{ "path": "", "groups": ["root_group"] }`
- **Expected result:** Success. Root node assigned to `"root_group"`.

#### Scenario 5: Happy path — single-element array with empty string
- **Description:** Set group to an empty string (invalid group name)
- **Params:** `{ "path": "Player", "groups": [""] }`
- **Expected result:** Error from Godot or succeeds with invalid group name.

#### Scenario 6: Edge — missing `path`
- **Description:** Call without the required `path` parameter
- **Params:** `{ "groups": ["test"] }`
- **Expected result:** Zod validation error (path is required).

#### Scenario 7: Edge — missing `groups`
- **Description:** Call without the required `groups` parameter
- **Params:** `{ "path": "Player" }`
- **Expected result:** Zod validation error (groups is required).

#### Scenario 8: Edge — non-existent node
- **Description:** Set groups on a non-existent node
- **Params:** `{ "path": "Ghost", "groups": ["spooky"] }`
- **Expected result:** Error from Godot (node not found).

#### Scenario 9: Edge — groups not an array
- **Description:** Pass a string instead of an array for groups
- **Params:** `{ "path": "Player", "groups": "players" }`
- **Expected result:** Zod validation error (expected array, got string).

#### Scenario 10: Edge — groups contains non-strings
- **Description:** Pass an array with numbers instead of strings
- **Params:** `{ "path": "Player", "groups": [1, 2, 3] }`
- **Expected result:** Zod validation error (expected string[], got number[]).

#### Scenario 11: Edge — groups contains mixed types
- **Description:** Pass mixed types in the array
- **Params:** `{ "path": "Player", "groups": ["players", 42, true] }`
- **Expected result:** Zod validation error (all elements must be strings).

#### Scenario 12: Edge — path is number
- **Description:** Pass a number for path
- **Params:** `{ "path": 1, "groups": ["test"] }`
- **Expected result:** Zod validation error (expected string, got number).

#### Scenario 13: Edge — no scene open
- **Description:** Call when no scene is open
- **Params:** `{ "path": "Player", "groups": ["test"] }`
- **Expected result:** Error from Godot (no open scene).

---

## Tool: `find_nodes_in_group`

**Description:** Find all nodes belonging to a specific group
**Handler:** `callGodot(bridge, 'node/find_in_group', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `group` | `z.string()` | **Yes** | — | Group name to search for |

### Test Scenarios

#### Scenario 1: Happy path — find nodes in non-empty group
- **Description:** Find all nodes in the `"players"` group
- **Params:** `{ "group": "players" }`
- **Expected result:** Success. Returns an array of node paths that belong to `"players"`, e.g., `["Player", "Player2"]`.

#### Scenario 2: Happy path — find nodes in empty group
- **Description:** Search for a group that has no members
- **Params:** `{ "group": "unused_group" }`
- **Expected result:** Success. Returns an empty array `[]`.

#### Scenario 3: Happy path — find nodes in non-existent group
- **Description:** Search for a group name that has never been assigned
- **Params:** `{ "group": "completely_fake_group" }`
- **Expected result:** Success. Returns an empty array `[]`.

#### Scenario 4: Happy path — common group
- **Description:** Search for `"enemies"` group if any enemies exist
- **Params:** `{ "group": "enemies" }`
- **Expected result:** Success. Returns array of enemy node paths, or empty if none.

#### Scenario 5: Edge — missing `group`
- **Description:** Call without the required `group` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (group is required).

#### Scenario 6: Edge — empty string group name
- **Description:** Search for an empty string group
- **Params:** `{ "group": "" }`
- **Expected result:** May return empty array or error. Behavior depends on Godot.

#### Scenario 7: Edge — group is number
- **Description:** Pass a number instead of string
- **Params:** `{ "group": 42 }`
- **Expected result:** Zod validation error (expected string, got number).

#### Scenario 8: Edge — group with special characters
- **Description:** Search for a group name with special characters
- **Params:** `{ "group": "!@#$%^&*()" }`
- **Expected result:** Returns empty array (no nodes in such group) or error.

#### Scenario 9: Edge — no scene open
- **Description:** Call when no scene is open
- **Params:** `{ "group": "players" }`
- **Expected result:** Error from Godot (no open scene) or returns empty array.

---

## Tool: `get_editor_selection`

**Description:** Get the currently selected nodes in the editor
**Handler:** `callGodot(bridge, 'node/get_selection')`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| *(none)* | — | — | — | No parameters |

### Test Scenarios

#### Scenario 1: Happy path — one node selected
- **Description:** Get selection when one node is selected in the editor
- **Params:** `{}`
- **Expected result:** Success. Returns an array with one node path, e.g., `["Player"]`.

#### Scenario 2: Happy path — multiple nodes selected
- **Description:** Get selection when multiple nodes are selected
- **Params:** `{}`
- **Expected result:** Success. Returns an array of selected node paths, e.g., `["Player", "Enemy", "World"]`.

#### Scenario 3: Happy path — nothing selected
- **Description:** Get selection when no nodes are selected
- **Params:** `{}`
- **Expected result:** Success. Returns an empty array `[]`.

#### Scenario 4: Happy path — repeat calls
- **Description:** Call twice in a row without changing selection
- **Params:** `{}` (twice)
- **Expected result:** Both calls return the same result.

#### Scenario 5: Edge — with unexpected extra param
- **Description:** Call with a parameter that is not in the schema
- **Params:** `{ "extra": "unexpected" }`
- **Expected result:** Zod strips unknown keys and processes normally (returns current selection).

#### Scenario 6: Edge — no scene open
- **Description:** Call when no scene is open
- **Params:** `{}`
- **Expected result:** Returns empty array `[]` or error.

---

## Tool: `select_nodes`

**Description:** Select nodes in the editor
**Handler:** `callGodot(bridge, 'node/select', args)`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `paths` | `z.array(z.string())` | **Yes** | — | List of node paths to select |

### Test Scenarios

#### Scenario 1: Happy path — select single node
- **Description:** Select one node in the editor
- **Params:** `{ "paths": ["Player"] }`
- **Expected result:** Success. `Player` becomes the selected node. Previous selection is replaced.

#### Scenario 2: Happy path — select multiple nodes
- **Description:** Select multiple nodes at once
- **Params:** `{ "paths": ["Player", "Enemy", "World"] }`
- **Expected result:** Success. All three nodes are selected in the editor.

#### Scenario 3: Happy path — select nested path
- **Description:** Select a node by its full path
- **Params:** `{ "paths": ["Player/Sprite2D"] }`
- **Expected result:** Success. The nested node is selected.

#### Scenario 4: Happy path — clear selection with empty array
- **Description:** Pass an empty array to deselect everything
- **Params:** `{ "paths": [] }`
- **Expected result:** Success. All nodes are deselected. Equivalent to `clear_editor_selection`.

#### Scenario 5: Happy path — select scene root
- **Description:** Select the scene root
- **Params:** `{ "paths": [""] }`
- **Expected result:** Success or error depending on whether root is selectable.

#### Scenario 6: Edge — missing `paths`
- **Description:** Call without the required `paths` parameter
- **Params:** `{}`
- **Expected result:** Zod validation error (paths is required).

#### Scenario 7: Edge — paths is not an array
- **Description:** Pass a single string instead of an array
- **Params:** `{ "paths": "Player" }`
- **Expected result:** Zod validation error (expected array, got string).

#### Scenario 8: Edge — non-existent path
- **Description:** Include a node path that does not exist
- **Params:** `{ "paths": ["Player", "DoesNotExist"] }`
- **Expected result:** Error from Godot (node not found). May select `Player` and then fail, or fail entirely.

#### Scenario 9: Edge — paths contains non-strings
- **Description:** Pass an array with numbers
- **Params:** `{ "paths": [1, 2, 3] }`
- **Expected result:** Zod validation error (expected string[], got number[]).

#### Scenario 10: Edge — paths with empty string element
- **Description:** Include an empty string in the paths array
- **Params:** `{ "paths": ["Player", ""] }`
- **Expected result:** May select `Player` and root, or error on empty string.

#### Scenario 11: Edge — no scene open
- **Description:** Call when no scene is open
- **Params:** `{ "paths": ["Player"] }`
- **Expected result:** Error from Godot (no open scene).

---

## Tool: `clear_editor_selection`

**Description:** Clear the current editor selection
**Handler:** `callGodot(bridge, 'node/clear_selection')`

### Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| *(none)* | — | — | — | No parameters |

### Test Scenarios

#### Scenario 1: Happy path — clear with nodes selected
- **Description:** Clear editor selection when nodes are currently selected
- **Params:** `{}`
- **Expected result:** Success. All nodes are deselected. Subsequent `get_editor_selection` returns `[]`.

#### Scenario 2: Happy path — clear with nothing selected
- **Description:** Call clear when nothing is selected (idempotent)
- **Params:** `{}`
- **Expected result:** Success. No change (already nothing selected).

#### Scenario 3: Happy path — clear → select → clear roundtrip
- **Description:** Verify clear works as part of a workflow
- **Steps:**
  1. `select_nodes` with `{ "paths": ["Player"] }`
  2. `get_editor_selection` — expect `["Player"]`
  3. `clear_editor_selection` — expect success
  4. `get_editor_selection` — expect `[]`
- **Expected result:** All steps succeed.

#### Scenario 4: Edge — with unexpected extra param
- **Description:** Call with a parameter that is not in the schema
- **Params:** `{ "extra": "ignored" }`
- **Expected result:** Zod strips unknown keys and processes normally (clears selection).

#### Scenario 5: Edge — no scene open
- **Description:** Call when no scene is open
- **Params:** `{}`
- **Expected result:** No-op (nothing to clear) or error.

---

## Integration Test Scenarios

These scenarios chain multiple node tools together to verify end-to-end workflows.

### Integration 1: Create → Inspect → Modify → Delete node lifecycle
1. `add_node` — create a `Sprite2D` named `TestSprite` under `Player` with initial `position: [50, 50]`
2. `get_node_properties` on `"Player/TestSprite"` — verify `position` is `[50, 50]` and `name` is `"TestSprite"`
3. `update_property` — set `scale` to `[2, 2]` on `"Player/TestSprite"`
4. `get_node_properties` — verify `scale` is now `[2, 2]`
5. `rename_node` — rename `"Player/TestSprite"` to `"DoubleSprite"`
6. `get_node_properties` on `"Player/DoubleSprite"` — verify `name` is `"DoubleSprite"`
7. `delete_node` — delete `"Player/DoubleSprite"`
8. `get_node_properties` on `"Player/DoubleSprite"` — expect error (node not found)
- **Expected result:** Full lifecycle succeeds — node is created, inspected, modified, renamed, and deleted cleanly.

### Integration 2: Signal connect → disconnect workflow
1. `add_node` — create a `Button` named `TestButton` under `UI` with parent `"UI"`
2. `connect_signal` — connect `"UI/TestButton"` signal `"pressed"` to `"UI"` method `"_on_test_button_pressed"`
3. `disconnect_signal` — disconnect the same connection
4. `delete_node` — delete `"UI/TestButton"`
- **Expected result:** Signal connection and disconnection work correctly. No stale connections remain.

### Integration 3: Group management workflow
1. `set_node_groups` on `"Player"` with `groups: ["players", "allies"]`
2. `get_node_groups` on `"Player"` — verify returns `["players", "allies"]`
3. `find_nodes_in_group` with `"players"` — verify `"Player"` is in results
4. `set_node_groups` on `"Player"` with `groups: ["enemies"]` (replace)
5. `get_node_groups` on `"Player"` — verify returns `["enemies"]` (old groups gone)
6. `find_nodes_in_group` with `"players"` — verify `"Player"` no longer in results
7. `set_node_groups` on `"Player"` with `groups: []` (clear all)
8. `get_node_groups` on `"Player"` — verify returns `[]`
- **Expected result:** Group lifecycle works — assign, replace, clear all work as expected.

### Integration 4: Move → duplicate → delete workflow
1. `add_node` — create a `Node` named `Movable` under `Player`
2. `move_node` — move `"Player/Movable"` to `"World"` at index `0`
3. `get_node_properties` — verify `"World/Movable"` exists (node moved)
4. `duplicate_node` — duplicate `"World/Movable"` to create `"World/Movable2"`
5. `get_node_properties` — verify both `"World/Movable"` and `"World/Movable2"` exist
6. `delete_node` — delete `"World/Movable"`
7. `delete_node` — delete `"World/Movable2"`
- **Expected result:** Move, duplicate, and delete work correctly in sequence.

### Integration 5: Editor selection workflow
1. `clear_editor_selection` — ensure clean state
2. `get_editor_selection` — verify `[]`
3. `select_nodes` with `paths: ["Player"]` — select one node
4. `get_editor_selection` — verify `["Player"]`
5. `select_nodes` with `paths: ["Player", "Enemy"]` — select multiple
6. `get_editor_selection` — verify `["Player", "Enemy"]`
7. `clear_editor_selection`
8. `get_editor_selection` — verify `[]`
- **Expected result:** Editor selection operations chain correctly.

### Integration 6: Anchor preset on dynamically created Control node
1. `add_node` — create a `Panel` named `TestPanel` under `UI`
2. `set_anchor_preset` — apply `top_left` to `"UI/TestPanel"`
3. `get_node_properties` — verify anchor properties are set to top-left values
4. `set_anchor_preset` — apply `full_rect` to `"UI/TestPanel"`
5. `get_node_properties` — verify anchor properties changed to full_rect
6. `delete_node` — delete `"UI/TestPanel"`
- **Expected result:** Anchor presets apply correctly and can be changed.

### Integration 7: Add resource with properties → verify
1. `add_node` — create a `MeshInstance3D` named `TestMesh` (type: `"MeshInstance3D"`) under `"World"` with `mesh_type: "cube"` in properties
2. `add_resource` — add a `"Material"` to `"World/TestMesh"` with `properties: { "albedo_color": [1, 0, 0, 1], "metallic": 1 }`
3. `get_node_properties` on `"World/TestMesh"` — verify material was applied
4. `delete_node` — delete `"World/TestMesh"`
- **Expected result:** Resource is created and assigned to the mesh node.

---

## Summary

| # | Tool | Params | Required | Optional | Enum Values |
|---|---|---|---|---|---|
| 1 | `add_node` | 4 | `parent_path`, `type`, `name` | `properties` | — |
| 2 | `delete_node` | 1 | `path` | — | — |
| 3 | `duplicate_node` | 1 | `path` | — | — |
| 4 | `move_node` | 3 | `path`, `new_parent` | `index` | — |
| 5 | `update_property` | 3 | `path`, `property`, `value` | — | — |
| 6 | `get_node_properties` | 1 | `path` | — | — |
| 7 | `add_resource` | 3 | `node_path`, `resource_type` | `properties` | — |
| 8 | `set_anchor_preset` | 2 | `path`, `preset` | — | `preset` (free string, common Godot presets: `full_rect`, `center`, `top_left`, `top_right`, `bottom_left`, `bottom_right`, `center_top`, `center_bottom`, `center_left`, `center_right`, `top_wide`, `bottom_wide`, `left_wide`, `right_wide`, `vcenter_wide`, `hcenter_wide`) |
| 9 | `rename_node` | 2 | `path`, `new_name` | — | — |
| 10 | `connect_signal` | 4 | `source`, `signal`, `target`, `method` | — | — |
| 11 | `disconnect_signal` | 4 | `source`, `signal`, `target`, `method` | — | — |
| 12 | `get_node_groups` | 1 | `path` | — | — |
| 13 | `set_node_groups` | 2 | `path`, `groups` | — | — |
| 14 | `find_nodes_in_group` | 1 | `group` | — | — |
| 15 | `get_editor_selection` | 0 | — | — | — |
| 16 | `select_nodes` | 1 | `paths` | — | — |
| 17 | `clear_editor_selection` | 0 | — | — | — |

**Total scenarios:** 140+ covering all 17 tools with happy paths, edge cases, and 7 integration workflows.
