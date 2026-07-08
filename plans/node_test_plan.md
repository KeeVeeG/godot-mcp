# Node Tools Test Plan

**Source**: `server/src/tools/node.ts`  
**Total tools**: 17  
**Test plan generated**: 2026-07-08

---

## Table of Contents

1. [Tool: add_node](#tool-add_node)
2. [Tool: delete_node](#tool-delete_node)
3. [Tool: duplicate_node](#tool-duplicate_node)
4. [Tool: move_node](#tool-move_node)
5. [Tool: update_property](#tool-update_property)
6. [Tool: get_node_properties](#tool-get_node_properties)
7. [Tool: add_resource](#tool-add_resource)
8. [Tool: set_anchor_preset](#tool-set_anchor_preset)
9. [Tool: rename_node](#tool-rename_node)
10. [Tool: connect_signal](#tool-connect_signal)
11. [Tool: disconnect_signal](#tool-disconnect_signal)
12. [Tool: get_node_groups](#tool-get_node_groups)
13. [Tool: set_node_groups](#tool-set_node_groups)
14. [Tool: find_nodes_in_group](#tool-find_nodes_in_group)
15. [Tool: get_editor_selection](#tool-get_editor_selection)
16. [Tool: select_nodes](#tool-select_nodes)
17. [Tool: clear_editor_selection](#tool-clear_editor_selection)

---

## Tool: add_node

**Tool name**: `add_node`  
**Description**: Add a new node to the scene tree  
**Backend method**: `node/add`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `parent_path` | `ParentPath` (`z.string()`) | Yes | — | Parent node path. Use `''` (empty string) for scene root, or a node name/path (e.g. `'Player'`, `'Player/Sprites'`) |
| `type` | `NodeType` (`z.string()`) | Yes | — | Node type name (e.g. `'Sprite2D'`, `'CharacterBody3D'`, `'Node2D'`) |
| `name` | `z.string()` | Yes | — | Name for the new node |
| `properties` | `OptionalProperties` (`z.record(z.unknown()).optional()`) | No | `undefined` | Optional initial property key-value pairs |

### Test Scenarios

#### Scenario 1: Happy path — add Node2D at scene root

**Description**: Add a basic Node2D node as a child of the scene root.  
**Params**:
```json
{
  "parent_path": "",
  "type": "Node2D",
  "name": "TestNode"
}
```
**Expected result**: Node `TestNode` of type `Node2D` is created as a child of the scene root. Subsequent `get_scene_tree` should show this node. The result should indicate success.  
**Notes**: Prerequisite: a scene must be open in the Godot editor.  
**Pay attention**: Verify via `get_scene_tree` that the node appeared in the tree. The name must exactly match the one passed. The node type must be `Node2D`.

---

#### Scenario 2: Happy path — add Sprite2D as child of existing node

**Description**: Add a Sprite2D node nested under an existing parent node.  
**Params**:
```json
{
  "parent_path": "Player",
  "type": "Sprite2D",
  "name": "PlayerSprite"
}
```
**Expected result**: Node `PlayerSprite` of type `Sprite2D` is created as a child of the `Player` node.  
**Notes**: Prerequisite: a node named `Player` must exist in the current scene. Use `add_node` to create it first if needed.  
**Pay attention**: Verify via `get_scene_tree` that the node `PlayerSprite` appeared under `Player`, not under the root. The path in the tree should be `Player/PlayerSprite`.

---

#### Scenario 3: Happy path — add node with initial properties

**Description**: Add a node and immediately set some properties on it.  
**Params**:
```json
{
  "parent_path": "",
  "type": "Node2D",
  "name": "PositionedNode",
  "properties": {
    "position": [100, 200],
    "visible": true,
    "rotation": 0.5
  }
}
```
**Expected result**: Node `PositionedNode` is created with the specified properties. `position` should be `[100, 200]`, `visible` should be `true`, `rotation` should be `0.5`.  
**Pay attention**: Verify via `get_node_properties` that all three properties are set correctly. Values must exactly match what was passed.

---

#### Scenario 4: Happy path — add deeply nested node

**Description**: Add a node under a deeply nested parent path.  
**Params**:
```json
{
  "parent_path": "Player/Sprites/MainSprite",
  "type": "AnimationPlayer",
  "name": "AnimPlayer"
}
```
**Expected result**: Node created at `Player/Sprites/MainSprite/AnimPlayer`.  
**Notes**: Prerequisite: the full parent path must exist.  
**Pay attention**: Verify that the node was created at the specified deep path.

---

#### Scenario 5: Happy path — add Control node type

**Description**: Add a UI Control node.  
**Params**:
```json
{
  "parent_path": "",
  "type": "Control",
  "name": "UIRoot"
}
```
**Expected result**: A `Control` node named `UIRoot` is added at the scene root.  
**Pay attention**: Verify that the node type is exactly `Control`, not `Node` or something else.

---

#### Scenario 6: Error case — nonexistent parent path

**Description**: Try to add a node under a parent that doesn't exist.  
**Params**:
```json
{
  "parent_path": "NonExistentParent/DeepPath",
  "type": "Node2D",
  "name": "OrphanNode"
}
```
**Expected result**: Error indicating that the parent node `NonExistentParent/DeepPath` was not found. The result should have `isError: true`.  
**Pay attention**: The error should be meaningful and indicate the missing parent node. Godot should not crash.

---

#### Scenario 7: Edge case — empty string name

**Description**: Add a node with an empty string as name.  
**Params**:
```json
{
  "parent_path": "",
  "type": "Node2D",
  "name": ""
}
}
```
**Expected result**: Either an error (Godot may reject empty node names) or the node is created with an auto-generated name.  
**Pay attention**: Check behavior — Godot typically does not allow empty node names. The error should be informative.

---

#### Scenario 8: Edge case — invalid node type

**Description**: Pass a nonexistent node type.  
**Params**:
```json
{
  "parent_path": "",
  "type": "NonExistentNodeType999",
  "name": "BadNode"
}
```
**Expected result**: Error from Godot indicating unknown class/type.  
**Pay attention**: Godot should return an error about an unknown node type. Verify that the error does not crash the server.

---

### Related Tools

- **Before**: `open_scene` or `create_scene` (a scene must be open). Use another `add_node` to create parent nodes if testing nested paths.
- **After**: `get_scene_tree` (to verify node was added), `get_node_properties` (to verify properties), `delete_node` (cleanup), `update_property` (to modify after creation).
- **Cleanup**: Call `delete_node` to remove test nodes after each scenario.

---

## Tool: delete_node

**Tool name**: `delete_node`  
**Description**: Delete a node from the scene tree  
**Backend method**: `node/delete`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `NodePath` (`z.string()`) | Yes | — | Node path to delete (e.g. `'Player/Sprite2D'`) |

### Test Scenarios

#### Scenario 1: Happy path — delete a leaf node

**Description**: Delete a node that has no children.  
**Params**:
```json
{
  "path": "TestNode"
}
```
**Expected result**: The node `TestNode` is removed from the scene tree. `get_scene_tree` should no longer show it.  
**Notes**: Prerequisite: node `TestNode` must exist. Use `add_node` first.  
**Pay attention**: Verify via `get_scene_tree` that the node was deleted. Also verify that deletion did not damage other nodes.

---

#### Scenario 2: Happy path — delete a node with children

**Description**: Delete a node that has child nodes (entire subtree).  
**Params**:
```json
{
  "path": "Player"
}
```
**Expected result**: The node `Player` and all its children are removed from the scene tree.  
**Notes**: Prerequisite: `Player` node must exist with at least one child. Use `add_node` to create a child first.  
**Pay attention**: Verify that ALL child nodes are also deleted. `get_scene_tree` should contain neither `Player` nor its descendants.

---

#### Scenario 3: Error case — delete nonexistent node

**Description**: Try to delete a node that doesn't exist.  
**Params**:
```json
{
  "path": "NonExistentNode"
}
```
**Expected result**: Error indicating the node was not found. `isError: true` in result.  
**Pay attention**: The error should be meaningful, not a crash. Check the error text.

---

#### Scenario 4: Edge case — deeply nested path

**Description**: Delete a deeply nested node.  
**Params**:
```json
{
  "path": "Player/Sprites/MainSprite/AnimationPlayer"
}
```
**Expected result**: The specific node at the deep path is deleted. Parent nodes remain intact.  
**Notes**: Prerequisite: the full path must exist.  
**Pay attention**: Verify that only the target node was deleted, and the parent nodes `Player/Sprites/MainSprite` remain intact.

---

#### Scenario 5: Edge case — delete scene root (empty string path)

**Description**: Try to delete the scene root by passing empty string.  
**Params**:
```json
{
  "path": ""
}
```
**Expected result**: Error — the scene root cannot be deleted (or unexpected behavior).  
**Pay attention**: Godot does not allow deleting the scene root node. Verify that a meaningful error is returned.

---

### Related Tools

- **Before**: `add_node` (to create a node to delete), `open_scene` (a scene must be open).
- **After**: `get_scene_tree` (to verify deletion).
- **Cleanup**: N/A — the tool itself is the cleanup.

---

## Tool: duplicate_node

**Tool name**: `duplicate_node`  
**Description**: Duplicate a node in the scene tree  
**Backend method**: `node/duplicate`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `NodePath` (`z.string()`) | Yes | — | Node path to duplicate |

### Test Scenarios

#### Scenario 1: Happy path — duplicate a simple node

**Description**: Duplicate a leaf node.  
**Params**:
```json
{
  "path": "TestNode"
}
```
**Expected result**: A copy of `TestNode` is created. The duplicate should have the same type and properties. `get_scene_tree` should show both the original and the copy (likely named `TestNode2` or similar).  
**Notes**: Prerequisite: `TestNode` must exist.  
**Pay attention**: Verify that the duplicate has the same type. The duplicate's name may be `TestNode2` or `TestNode_copy` — depends on Godot. Verify via `get_scene_tree`.

---

#### Scenario 2: Happy path — duplicate a node with children

**Description**: Duplicate a node that has children — entire subtree should be duplicated.  
**Params**:
```json
{
  "path": "Player"
}
```
**Expected result**: A full copy of `Player` and all its children is created. The duplicate's subtree should mirror the original.  
**Notes**: Prerequisite: `Player` must exist with children.  
**Pay attention**: Verify that the duplicate contains all child nodes with the same names and types. The tree structure should be identical to the original.

---

#### Scenario 3: Error case — duplicate nonexistent node

**Description**: Try to duplicate a node that doesn't exist.  
**Params**:
```json
{
  "path": "GhostNode"
}
```
**Expected result**: Error indicating node not found.  
**Pay attention**: The error should be informative.

---

#### Scenario 4: Edge case — duplicate the scene root

**Description**: Try to duplicate the root node by path.  
**Params**:
```json
{
  "path": ""
}
```
**Expected result**: Error — scene root typically cannot be duplicated this way (it would need a different mechanism).  
**Pay attention**: Check behavior. Godot may either reject or create a copy at the same level.

---

### Related Tools

- **Before**: `add_node` (to create a node to duplicate), `open_scene` (a scene must be open).
- **After**: `get_scene_tree` (to verify the duplicate), `get_node_properties` (to verify properties match), `delete_node` (cleanup duplicates).
- **Cleanup**: Call `delete_node` on the duplicated node after testing.

---

## Tool: move_node

**Tool name**: `move_node`  
**Description**: Move a node to a new parent in the scene tree  
**Backend method**: `node/move`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `NodePath` (`z.string()`) | Yes | — | Node path to move |
| `new_parent` | `z.string()` | Yes | — | New parent node path |
| `index` | `z.number().int().min(0).optional()` | No | (end of children) | Child index position under the new parent |

### Test Scenarios

#### Scenario 1: Happy path — move node to different parent

**Description**: Move a node from one parent to another.  
**Params**:
```json
{
  "path": "Player/Sprite2D",
  "new_parent": "Enemies"
}
}
```
**Expected result**: `Sprite2D` is moved from under `Player` to under `Enemies`. The new path should be `Enemies/Sprite2D`. `get_scene_tree` should reflect this change.  
**Notes**: Prerequisites: both `Player/Sprite2D` and `Enemies` must exist.  
**Pay attention**: Verify via `get_scene_tree` that the node was moved. The old path `Player/Sprite2D` should no longer exist. The new path `Enemies/Sprite2D` should exist.

---

#### Scenario 2: Happy path — move node to scene root

**Description**: Move a nested node to the scene root level.  
**Params**:
```json
{
  "path": "Player/Sprite2D",
  "new_parent": ""
}
```
**Expected result**: `Sprite2D` becomes a direct child of the scene root.  
**Pay attention**: Verify that the node became a direct child of the scene root.

---

#### Scenario 3: Happy path — move with specific index

**Description**: Move a node and specify its position among siblings.  
**Params**:
```json
{
  "path": "Player/Sprite2D",
  "new_parent": "Enemies",
  "index": 0
}
```
**Expected result**: `Sprite2D` is moved to `Enemies` and becomes the first child (index 0).  
**Pay attention**: Verify that the node is indeed the first in the list of `Enemies` child nodes.

---

#### Scenario 4: Edge case — move to same parent (reorder)

**Description**: Move a node within the same parent to change its order.  
**Params**:
```json
{
  "path": "Player/Sprite2D",
  "new_parent": "Player",
  "index": 0
}
}
```
**Expected result**: `Sprite2D` stays under `Player` but moves to position 0.  
**Pay attention**: Verify that the node moved to the first position among `Player` child nodes.

---

#### Scenario 5: Edge case — index out of bounds

**Description**: Specify an index larger than the number of children.  
**Params**:
```json
{
  "path": "Player/Sprite2D",
  "new_parent": "Enemies",
  "index": 999
}
}
```
**Expected result**: Either the node is placed at the end (Godot clamps the index) or an error is returned.  
**Pay attention**: Check behavior — Godot typically places the node at the end if the index exceeds the number of children.

---

#### Scenario 6: Error case — move nonexistent node

**Description**: Try to move a node that doesn't exist.  
**Params**:
```json
{
  "path": "NonExistent/Path",
  "new_parent": "SomeParent"
}
```
**Expected result**: Error indicating node not found.  
**Pay attention**: The error should be meaningful.

---

#### Scenario 7: Error case — move to nonexistent parent

**Description**: Try to move a node to a parent that doesn't exist.  
**Params**:
```json
{
  "path": "Player/Sprite2D",
  "new_parent": "NonExistentParent"
}
}
```
**Expected result**: Error indicating target parent not found.  
**Pay attention**: The error should indicate the missing target parent node.

---

### Related Tools

- **Before**: `add_node` (to create nodes to move), `open_scene` (a scene must be open).
- **After**: `get_scene_tree` (to verify move), `delete_node` (cleanup).
- **Note**: After moving, the node's path changes. Use the new path in subsequent operations.

---

## Tool: update_property

**Tool name**: `update_property`  
**Description**: Update a property value on a node  
**Backend method**: `node/update_property`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `NodePath` (`z.string()`) | Yes | — | Node path |
| `property` | `PropertyName` (`z.string()`) | Yes | — | Property name (e.g. `'position'`, `'visible'`) |
| `value` | `PropertyValue` (`z.unknown()`) | Yes | — | New value for the property |

### Test Scenarios

#### Scenario 1: Happy path — set position (Vector2)

**Description**: Update the `position` property of a Node2D.  
**Params**:
```json
{
  "path": "Player",
  "property": "position",
  "value": [150, 250]
}
```
**Expected result**: The `position` property of `Player` is set to `Vector2(150, 250)`. `get_node_properties` should reflect this.  
**Pay attention**: Verify via `get_node_properties` that `position` equals `[150, 250]` (or `Vector2(150, 250)` in Godot format).

---

#### Scenario 2: Happy path — set boolean property

**Description**: Set `visible` to false.  
**Params**:
```json
{
  "path": "Player",
  "property": "visible",
  "value": false
}
}
```
**Expected result**: The `visible` property is set to `false`.  
**Pay attention**: Verify that `visible` became `false`.

---

#### Scenario 3: Happy path — set string property

**Description**: Set the `name` property (note: this changes the node's name in the tree).  
**Params**:
```json
{
  "path": "TestNode",
  "property": "name",
  "value": "RenamedNode"
}
}
```
**Expected result**: The node is renamed to `RenamedNode`. The path changes accordingly.  
**Pay attention**: After renaming, the node's path will change. Subsequent calls should use the new name.

---

#### Scenario 4: Happy path — set numeric property

**Description**: Set `rotation` on a Node2D.  
**Params**:
```json
{
  "path": "Player",
  "property": "rotation",
  "value": 1.5708
}
}
```
**Expected result**: The `rotation` property is set to approximately `1.5708` (π/2 radians = 90 degrees).  
**Pay attention**: Verify that the rotation value is set correctly. Godot uses radians.

---

#### Scenario 5: Happy path — set complex property (Color)

**Description**: Set a color property like `modulate`.  
**Params**:
```json
{
  "path": "Player",
  "property": "modulate",
  "value": [1.0, 0.5, 0.5, 1.0]
}
}
```
**Expected result**: The `modulate` property is set to a red-tinted color.  
**Pay attention**: Godot can accept Color as an array [r, g, b, a] or as an object. Check the format.

---

#### Scenario 6: Error case — update nonexistent node

**Description**: Try to update property on a node that doesn't exist.  
**Params**:
```json
{
  "path": "GhostNode",
  "property": "visible",
  "value": false
}
}
```
**Expected result**: Error indicating node not found.  
**Pay attention**: The error should be meaningful.

---

#### Scenario 7: Error case — invalid property name

**Description**: Try to set a property that doesn't exist on the node.  
**Params**:
```json
{
  "path": "Player",
  "property": "totally_fake_property_xyz",
  "value": 42
}
}
```
**Expected result**: Error from Godot indicating the property doesn't exist on the node's class.  
**Pay attention**: Godot should return an error about an unknown property. Verify that the error does not crash the server.

---

#### Scenario 8: Edge case — set property with wrong type

**Description**: Pass a string where a number is expected.  
**Params**:
```json
{
  "path": "Player",
  "property": "rotation",
  "value": "not_a_number"
}
}
```
**Expected result**: Error — Godot cannot coerce a string to a numeric rotation value.  
**Pay attention**: Verify that the type validation error is reported correctly.

---

### Related Tools

- **Before**: `add_node` (to create a node to update), `open_scene` (a scene must be open).
- **After**: `get_node_properties` (to verify the update), `update_property` (to set more properties).
- **Note**: `PropertyValue` is `z.unknown()` — it accepts any JSON-serializable value. The validation happens on the Godot side.

---

## Tool: get_node_properties

**Tool name**: `get_node_properties`  
**Description**: Get all properties of a node  
**Backend method**: `node/get_properties`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `NodePath` (`z.string()`) | Yes | — | Node path to inspect |

### Test Scenarios

#### Scenario 1: Happy path — get properties of a Node2D

**Description**: Get all properties of an existing Node2D node.  
**Params**:
```json
{
  "path": "Player"
}
```
**Expected result**: Returns a JSON object with all properties of the `Player` node. Should include standard Node2D properties like `position`, `rotation`, `scale`, `visible`, `name`, `type`, etc.  
**Pay attention**: Verify that the returned properties contain `position`, `rotation`, `scale`, `visible`. Values should be current.

---

#### Scenario 2: Happy path — get properties of a Sprite2D

**Description**: Get properties of a Sprite2D node (includes texture-related properties).  
**Params**:
```json
{
  "path": "Player/PlayerSprite"
}
```
**Expected result**: Returns properties including Sprite2D-specific ones like `texture`, `region_enabled`, `offset`, `flip_h`, `flip_v`.  
**Pay attention**: Verify that Sprite2D-specific properties are present in the response.

---

#### Scenario 3: Happy path — verify after property update

**Description**: Get properties after calling `update_property` to verify the change.  
**Params**:
```json
{
  "path": "Player"
}
}
```
**Expected result**: The property that was updated should show the new value.  
**Notes**: Call `update_property` first to change a known property.  
**Pay attention**: The value of the updated property must exactly match what was set via `update_property`.

---

#### Scenario 4: Error case — nonexistent node

**Description**: Try to get properties of a node that doesn't exist.  
**Params**:
```json
{
  "path": "NonExistentNode"
}
}
```
**Expected result**: Error indicating node not found.  
**Pay attention**: The error should be meaningful.

---

#### Scenario 5: Edge case — get properties of scene root

**Description**: Get properties of the scene root node.  
**Params**:
```json
{
  "path": ""
}
```
**Expected result**: Returns properties of the scene's root node.  
**Pay attention**: Verify that an empty string is correctly handled as a reference to the scene root.

---

### Related Tools

- **Before**: `add_node` or `open_scene` (a node must exist).
- **After**: `update_property` (to change values seen in the result).
- **Note**: This is a read-only tool — it doesn't modify anything.

---

## Tool: add_resource

**Tool name**: `add_resource`  
**Description**: Add a resource (material, texture, etc.) to a node property  
**Backend method**: `node/add_resource`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `node_path` | `NodePath` (`z.string()`) | Yes | — | Node to add resource to (e.g. `'Player'` or `'Player/Cube'`) |
| `resource_type` | `z.string()` | Yes | — | Resource type (e.g. `'Material'`, `'Texture2D'`, `'ShaderMaterial'`) |
| `properties` | `OptionalProperties` (`z.record(z.unknown()).optional()`) | No | `undefined` | Optional resource property key-value pairs |

### Test Scenarios

#### Scenario 1: Happy path — add StandardMaterial3D to a MeshInstance3D

**Description**: Add a material resource to a 3D mesh node.  
**Params**:
```json
{
  "node_path": "Player/MeshInstance3D",
  "resource_type": "StandardMaterial3D",
  "properties": {
    "albedo_color": [1, 0, 0, 1]
  }
}
```
**Expected result**: A `StandardMaterial3D` resource is created and assigned to the node. The albedo color is set to red.  
**Notes**: Prerequisites: (1) scene must be open, (2) `Player/MeshInstance3D` must exist as a MeshInstance3D node.  
**Pay attention**: Verify via `get_node_properties` that the material is assigned. The `albedo_color` property should be red.

---

#### Scenario 2: Happy path — add resource without properties

**Description**: Add a resource with default properties.  
**Params**:
```json
{
  "node_path": "Player/PlayerSprite",
  "resource_type": "ShaderMaterial"
}
```
**Expected result**: A `ShaderMaterial` resource is created with default values and assigned to the node.  
**Pay attention**: Verify that the resource was created and assigned. Properties should have default values.

---

#### Scenario 3: Happy path — add Texture2D resource

**Description**: Add a texture to a Sprite2D node.  
**Params**:
```json
{
  "node_path": "Player/PlayerSprite",
  "resource_type": "Texture2D",
  "properties": {}
}
```
**Expected result**: A texture resource is created (likely as a placeholder) and assigned.  
**Pay attention**: Verify that the texture is assigned. Godot may create an empty texture or a placeholder.

---

#### Scenario 4: Error case — nonexistent node

**Description**: Try to add a resource to a node that doesn't exist.  
**Params**:
```json
{
  "node_path": "Ghost/Node",
  "resource_type": "StandardMaterial3D"
}
```
**Expected result**: Error indicating node not found.  
**Pay attention**: The error should be meaningful.

---

#### Scenario 5: Error case — invalid resource type

**Description**: Try to add a nonexistent resource type.  
**Params**:
```json
{
  "node_path": "Player",
  "resource_type": "FakeResourceType999"
}
```
**Expected result**: Error from Godot indicating unknown resource type.  
**Pay attention**: The error should indicate that the resource type is unknown.

---

### Related Tools

- **Before**: `add_node` (to create a node to add resource to), `open_scene` (a scene must be open).
- **After**: `get_node_properties` (to verify resource was assigned), `update_property` (to modify resource properties further).
- **Note**: The `node_path` parameter is named differently from other tools (uses `node_path` instead of `path`).

---

## Tool: set_anchor_preset

**Tool name**: `set_anchor_preset`  
**Description**: Set anchor preset on a Control node  
**Backend method**: `node/set_anchor_preset`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `NodePath` (`z.string()`) | Yes | — | Control node path |
| `preset` | `z.string()` | Yes | — | Anchor preset name (e.g. `'full_rect'`, `'center'`, `'top_left'`, `'bottom_right'`) |

### Test Scenarios

#### Scenario 1: Happy path — set full_rect preset

**Description**: Set a Control node to fill its parent completely.  
**Params**:
```json
{
  "path": "UIRoot/Panel",
  "preset": "full_rect"
}
```
**Expected result**: The Control node's anchors are set to fill the entire parent rect. `anchor_left=0, anchor_top=0, anchor_right=1, anchor_bottom=1`.  
**Notes**: Prerequisites: (1) scene must be open, (2) `UIRoot/Panel` must exist as a Control-derived node (e.g. Panel, ColorRect).  
**Pay attention**: Verify via `get_node_properties` that anchor_left=0, anchor_top=0, anchor_right=1, anchor_bottom=1.

---

#### Scenario 2: Happy path — set center preset

**Description**: Center a Control node in its parent.  
**Params**:
```json
{
  "path": "UIRoot/Label",
  "preset": "center"
}
```
**Expected result**: Anchors are set to center the node. `anchor_left=0.5, anchor_top=0.5, anchor_right=0.5, anchor_bottom=0.5`.  
**Pay attention**: Verify that anchors are set to 0.5.

---

#### Scenario 3: Happy path — set top_left preset

**Description**: Anchor a Control to the top-left corner.  
**Params**:
```json
{
  "path": "UIRoot/Button",
  "preset": "top_left"
}
```
**Expected result**: Anchors set to top-left: `anchor_left=0, anchor_top=0, anchor_right=0, anchor_bottom=0`.  
**Pay attention**: Verify that anchors are set to 0.

---

#### Scenario 4: Error case — set preset on non-Control node

**Description**: Try to set an anchor preset on a Node2D (not a Control).  
**Params**:
```json
{
  "path": "Player",
  "preset": "full_rect"
}
```
**Expected result**: Error — anchors are only valid for Control-derived nodes.  
**Pay attention**: Godot should return an error indicating that the node is not a Control.

---

#### Scenario 5: Error case — nonexistent node

**Description**: Try to set a preset on a node that doesn't exist.  
**Params**:
```json
{
  "path": "NonExistent/Control",
  "preset": "center"
}
```
**Expected result**: Error indicating node not found.  
**Pay attention**: The error should be meaningful.

---

#### Scenario 6: Edge case — invalid preset name

**Description**: Pass a preset name that doesn't exist.  
**Params**:
```json
{
  "path": "UIRoot/Panel",
  "preset": "nonexistent_preset_xyz"
}
```
**Expected result**: Error from Godot indicating unknown anchor preset.  
**Pay attention**: Verify that Godot returns an error about an unknown preset. Valid presets: full_rect, center, top_left, top_right, bottom_left, bottom_right, center_left, center_top, center_right, center_bottom, etc.

---

### Related Tools

- **Before**: `add_node` (to create a Control node), `create_scene` with `root_node_type: "Control"`, `open_scene`.
- **After**: `get_node_properties` (to verify anchor values).
- **Note**: This tool only works on Control-derived nodes (Control, Button, Label, Panel, etc.). Using it on Node2D or Node3D will fail.

---

## Tool: rename_node

**Tool name**: `rename_node`  
**Description**: Rename a node in the scene tree  
**Backend method**: `node/rename`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `NodePath` (`z.string()`) | Yes | — | Current node path |
| `new_name` | `z.string()` | Yes | — | New name for the node |

### Test Scenarios

#### Scenario 1: Happy path — rename a root-level node

**Description**: Rename a node at the root level.  
**Params**:
```json
{
  "path": "TestNode",
  "new_name": "RenamedNode"
}
```
**Expected result**: The node is renamed from `TestNode` to `RenamedNode`. `get_scene_tree` should show the new name. The old path `TestNode` should no longer work.  
**Pay attention**: Verify via `get_scene_tree` that the name changed. Attempting to access the old path `TestNode` should return an error.

---

#### Scenario 2: Happy path — rename a nested node

**Description**: Rename a node that is nested under another node.  
**Params**:
```json
{
  "path": "Player/Sprite2D",
  "new_name": "PlayerVisuals"
}
```
**Expected result**: The node is renamed to `PlayerVisuals`. The new path is `Player/PlayerVisuals`.  
**Pay attention**: Verify that the path changed to `Player/PlayerVisuals`. Child nodes (if any) are now accessible via the new path.

---

#### Scenario 3: Error case — rename nonexistent node

**Description**: Try to rename a node that doesn't exist.  
**Params**:
```json
{
  "path": "GhostNode",
  "new_name": "NewName"
}
```
**Expected result**: Error indicating node not found.  
**Pay attention**: The error should be meaningful.

---

#### Scenario 4: Edge case — rename to existing sibling name

**Description**: Try to rename a node to a name that already exists among siblings.  
**Params**:
```json
{
  "path": "Player/Sprite2D",
  "new_name": "ExistingChildName"
}
```
**Expected result**: Either Godot auto-renames (e.g. `ExistingChildName2`) or returns an error about name collision.  
**Pay attention**: Check behavior on name collision. Godot typically adds a numeric suffix.

---

#### Scenario 5: Edge case — rename to empty string

**Description**: Try to rename a node to an empty string.  
**Params**:
```json
{
  "path": "TestNode",
  "new_name": ""
}
```
**Expected result**: Error — Godot doesn't allow empty node names.  
**Pay attention**: Verify that the error is reported correctly.

---

### Related Tools

- **Before**: `add_node` (to create a node to rename), `open_scene`.
- **After**: `get_scene_tree` (to verify rename), `get_node_properties` (to verify name property).
- **⚠️ Important**: After renaming, the node's path changes. All subsequent calls must use the new path.

---

## Tool: connect_signal

**Tool name**: `connect_signal`  
**Description**: Connect a signal from one node to another node's method  
**Backend method**: `node/connect_signal`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `source` | `NodePath` (`z.string()`) | Yes | — | Node path emitting the signal |
| `signal` | `z.string()` | Yes | — | Signal name (e.g. `'body_entered'`, `'pressed'`, `'timeout'`) |
| `target` | `NodePath` (`z.string()`) | Yes | — | Node path receiving the signal |
| `method` | `z.string()` | Yes | — | Method to call on the target node (e.g. `'_on_body_entered'`) |

### Test Scenarios

#### Scenario 1: Happy path — connect button pressed signal

**Description**: Connect a Button's `pressed` signal to a handler method.  
**Params**:
```json
{
  "source": "UIRoot/StartButton",
  "signal": "pressed",
  "target": "GameManager",
  "method": "_on_start_button_pressed"
}
```
**Expected result**: The signal connection is established. When `StartButton` emits `pressed`, the `GameManager._on_start_button_pressed()` method will be called.  
**Notes**: Prerequisites: (1) `UIRoot/StartButton` must exist as a Button node, (2) `GameManager` must have a method `_on_start_button_pressed`.  
**Pay attention**: Verify that the connection was established (via `get_node_properties` or editor inspection).

---

#### Scenario 2: Happy path — connect Area2D body_entered

**Description**: Connect an Area2D's `body_entered` signal.  
**Params**:
```json
{
  "source": "Player/HurtBox",
  "signal": "body_entered",
  "target": "Player",
  "method": "_on_hurt_box_body_entered"
}
```
**Expected result**: Signal connection created between the Area2D and the Player script.  
**Notes**: `Player/HurtBox` must be an Area2D or similar.  
**Pay attention**: Verify that the connection is active.

---

#### Scenario 3: Error case — nonexistent source node

**Description**: Try to connect a signal from a node that doesn't exist.  
**Params**:
```json
{
  "source": "NonExistent/Sender",
  "signal": "pressed",
  "target": "Player",
  "method": "_on_pressed"
}
```
**Expected result**: Error indicating source node not found.  
**Pay attention**: The error should indicate the missing source node.

---

#### Scenario 4: Error case — nonexistent target node

**Description**: Try to connect to a target node that doesn't exist.  
**Params**:
```json
{
  "source": "UIRoot/Button",
  "signal": "pressed",
  "target": "NonExistent/Receiver",
  "method": "_on_pressed"
}
```
**Expected result**: Error indicating target node not found.  
**Pay attention**: The error should indicate the missing target node.

---

#### Scenario 5: Error case — invalid signal name

**Description**: Try to connect a signal that doesn't exist on the source node.  
**Params**:
```json
{
  "source": "Player",
  "signal": "totally_fake_signal",
  "target": "GameManager",
  "method": "_on_fake"
}
```
**Expected result**: Error from Godot indicating the signal doesn't exist on the source node's class.  
**Pay attention**: Godot should return an error about an unknown signal.

---

### Related Tools

- **Before**: `add_node` (to create source and target nodes), `open_scene` (a scene must be open). Nodes need scripts with the target method attached.
- **After**: `disconnect_signal` (to test disconnection), `update_property` (to trigger conditions that emit signals during gameplay).
- **Note**: The target node must have the specified method defined (usually in its attached GDScript).

---

## Tool: disconnect_signal

**Tool name**: `disconnect_signal`  
**Description**: Disconnect a signal connection  
**Backend method**: `node/disconnect_signal`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `source` | `NodePath` (`z.string()`) | Yes | — | Node path that emits the signal |
| `signal` | `z.string()` | Yes | — | Signal name |
| `target` | `NodePath` (`z.string()`) | Yes | — | Node path that receives the signal |
| `method` | `z.string()` | Yes | — | Method that was connected |

### Test Scenarios

#### Scenario 1: Happy path — disconnect an existing connection

**Description**: Disconnect a previously established signal connection.  
**Params**:
```json
{
  "source": "UIRoot/StartButton",
  "signal": "pressed",
  "target": "GameManager",
  "method": "_on_start_button_pressed"
}
```
**Expected result**: The signal connection is removed. The `pressed` signal no longer triggers `GameManager._on_start_button_pressed()`.  
**Notes**: Prerequisite: the connection must exist. Call `connect_signal` first.  
**Pay attention**: Verify that the connection is actually broken (via Godot inspection or runtime check).

---

#### Scenario 2: Error case — disconnect nonexistent connection

**Description**: Try to disconnect a signal connection that doesn't exist.  
**Params**:
```json
{
  "source": "Player",
  "signal": "nonexistent_signal",
  "target": "GameManager",
  "method": "_on_handler"
}
```
**Expected result**: Error indicating the connection doesn't exist.  
**Pay attention**: Godot should return an error about a non-existent connection.

---

#### Scenario 3: Error case — nonexistent source or target

**Description**: Try to disconnect with a nonexistent node.  
**Params**:
```json
{
  "source": "NonExistent/Node",
  "signal": "pressed",
  "target": "Player",
  "method": "_on_pressed"
}
```
**Expected result**: Error indicating node not found.  
**Pay attention**: The error should be meaningful.

---

#### Scenario 4: Error case — wrong method name

**Description**: Try to disconnect with a method name that doesn't match the connection.  
**Params**:
```json
{
  "source": "UIRoot/StartButton",
  "signal": "pressed",
  "target": "GameManager",
  "method": "_wrong_method_name"
}
```
**Expected result**: Error — the connection was made with a different method name.  
**Pay attention**: Verify that Godot accurately indicates that a connection with this method was not found.

---

### Related Tools

- **Before**: `connect_signal` (required — must have a connection to disconnect).
- **After**: Verification is difficult without runtime testing. Could verify via `get_node_properties` if Godot exposes connection info.
- **Note**: All four parameters must exactly match the original `connect_signal` call.

---

## Tool: get_node_groups

**Tool name**: `get_node_groups`  
**Description**: Get all groups a node belongs to  
**Backend method**: `node/get_groups`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `NodePath` (`z.string()`) | Yes | — | Node path to query |

### Test Scenarios

#### Scenario 1: Happy path — get groups of a node with groups

**Description**: Get groups of a node that belongs to one or more groups.  
**Params**:
```json
{
  "path": "Player"
}
```
**Expected result**: Returns a list/array of group names that the `Player` node belongs to. If the node is in groups `["enemies", "physics_entities"]`, the result should list them.  
**Notes**: Prerequisite: `Player` must exist and belong to at least one group. Use `set_node_groups` first.  
**Pay attention**: The result should be an array of strings. If the node is not in any groups — return an empty array.

---

#### Scenario 2: Happy path — get groups of a node with no groups

**Description**: Get groups of a node that doesn't belong to any group.  
**Params**:
```json
{
  "path": "TestNode"
}
```
**Expected result**: Returns an empty list/array `[]`.  
**Pay attention**: Verify that an empty array is returned, not null or undefined.

---

#### Scenario 3: Error case — nonexistent node

**Description**: Try to get groups of a node that doesn't exist.  
**Params**:
```json
{
  "path": "NonExistentNode"
}
```
**Expected result**: Error indicating node not found.  
**Pay attention**: The error should be meaningful.

---

#### Scenario 4: Verify after set_node_groups

**Description**: Get groups after setting them to verify.  
**Params**:
```json
{
  "path": "Player"
}
```
**Expected result**: Returns exactly the groups that were set via `set_node_groups`.  
**Notes**: Call `set_node_groups` first with known groups.  
**Pay attention**: The group list must exactly match what was set.

---

### Related Tools

- **Before**: `set_node_groups` (to set groups before querying), `add_node` (to create a node), `open_scene`.
- **After**: `find_nodes_in_group` (to find other nodes in the same group).
- **Note**: Read-only tool — doesn't modify anything.

---

## Tool: set_node_groups

**Tool name**: `set_node_groups`  
**Description**: Set the groups a node belongs to (replaces existing groups)  
**Backend method**: `node/set_groups`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | `NodePath` (`z.string()`) | Yes | — | Node path |
| `groups` | `z.array(z.string())` | Yes | — | List of group names (replaces ALL existing groups) |

### Test Scenarios

#### Scenario 1: Happy path — set groups on a node

**Description**: Assign groups to a node.  
**Params**:
```json
{
  "path": "Player",
  "groups": ["enemies", "physics_entities", "damageable"]
}
```
**Expected result**: The `Player` node now belongs to exactly these three groups. Any previous groups are removed. `get_node_groups` should return these three.  
**Pay attention**: Verify via `get_node_groups` that groups are set correctly. PREVIOUS groups must be REMOVED (replace, not append).

---

#### Scenario 2: Happy path — set empty groups (clear all groups)

**Description**: Clear all groups from a node.  
**Params**:
```json
{
  "path": "Player",
  "groups": []
}
```
**Expected result**: The `Player` node no longer belongs to any group. `get_node_groups` should return `[]`.  
**Pay attention**: Verify that the array is empty. All previous groups must be removed.

---

#### Scenario 3: Happy path — single group

**Description**: Set a single group.  
**Params**:
```json
{
  "path": "TestNode",
  "groups": ["test_group"]
}
```
**Expected result**: The node belongs to exactly one group: `test_group`.  
**Pay attention**: Verify that the array contains exactly one entry.

---

#### Scenario 4: Error case — nonexistent node

**Description**: Try to set groups on a nonexistent node.  
**Params**:
```json
{
  "path": "GhostNode",
  "groups": ["group1"]
}
```
**Expected result**: Error indicating node not found.  
**Pay attention**: The error should be meaningful.

---

#### Scenario 5: Edge case — group name with special characters

**Description**: Use group names with spaces or special characters.  
**Params**:
```json
{
  "path": "TestNode",
  "groups": ["my group", "group-with-dashes", "group.with.dots"]
}
```
**Expected result**: Groups are set as specified. Godot should handle these names.  
**Pay attention**: Verify that special characters in group names are handled correctly.

---

### Related Tools

- **Before**: `add_node` (to create a node), `open_scene`.
- **After**: `get_node_groups` (to verify), `find_nodes_in_group` (to find nodes by group).
- **⚠️ Important**: This tool REPLACES all existing groups. It does NOT append. If you need to add a group, you must include all existing groups plus the new one.

---

## Tool: find_nodes_in_group

**Tool name**: `find_nodes_in_group`  
**Description**: Find all nodes belonging to a specific group  
**Backend method**: `node/find_in_group`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `group` | `z.string()` | Yes | — | Group name to search for |

### Test Scenarios

#### Scenario 1: Happy path — find nodes in an existing group

**Description**: Find all nodes that belong to a specific group.  
**Params**:
```json
{
  "group": "enemies"
}
```
**Expected result**: Returns a list of node paths that belong to the `enemies` group. If `Player` and `Enemy1` are in this group, the result should list both paths.  
**Notes**: Prerequisite: at least one node must be in the `enemies` group. Use `set_node_groups` first.  
**Pay attention**: The result should contain node paths. Verify that all nodes added to the group via `set_node_groups` are present in the list.

---

#### Scenario 2: Happy path — find nodes in a group with one member

**Description**: Find nodes when only one node is in the group.  
**Params**:
```json
{
  "group": "unique_special_group"
}
```
**Expected result**: Returns a list with exactly one node path.  
**Pay attention**: Verify that the array contains exactly one element.

---

#### Scenario 3: Happy path — find nodes in empty group

**Description**: Search for a group that has no members.  
**Params**:
```json
{
  "group": "empty_group"
}
```
**Expected result**: Returns an empty list `[]`.  
**Pay attention**: Verify that an empty array is returned, not an error.

---

#### Scenario 4: Edge case — nonexistent group name

**Description**: Search for a group that was never created.  
**Params**:
```json
{
  "group": "totally_nonexistent_group_xyz"
}
```
**Expected result**: Returns an empty list `[]` (no nodes in a nonexistent group).  
**Pay attention**: Verify that this does not cause an error and simply returns an empty result.

---

### Related Tools

- **Before**: `set_node_groups` (to assign nodes to groups), `add_node` (to create nodes).
- **After**: `get_node_groups` (to verify a specific node's groups), `get_node_properties` (to inspect found nodes).
- **Note**: Read-only tool — doesn't modify anything.

---

## Tool: get_editor_selection

**Tool name**: `get_editor_selection`  
**Description**: Get the currently selected nodes in the editor  
**Backend method**: `node/get_selection`

### Parameters

None (empty schema).

### Test Scenarios

#### Scenario 1: Happy path — get current selection

**Description**: Get the list of nodes currently selected in the Godot editor.  
**Params**:
```json
{}
```
**Expected result**: Returns a list of node paths that are currently selected in the editor. If no nodes are selected, returns an empty list.  
**Notes**: No prerequisites — this is a read-only query of the editor state.  
**Pay attention**: The result depends on the current editor state. Verify that the response format is an array of node paths.

---

#### Scenario 2: Verify after select_nodes

**Description**: Get selection after programmatically selecting nodes.  
**Params**:
```json
{}
```
**Expected result**: Returns the nodes that were selected via `select_nodes`.  
**Notes**: Call `select_nodes` first with known node paths.  
**Pay attention**: The list should match what was passed to `select_nodes`.

---

#### Scenario 3: Verify after clear_editor_selection

**Description**: Get selection after clearing it.  
**Params**:
```json
{}
```
**Expected result**: Returns an empty list `[]`.  
**Notes**: Call `clear_editor_selection` first.  
**Pay attention**: Verify that the array is empty after clearing.

---

### Related Tools

- **Before**: `select_nodes` (to set selection), `clear_editor_selection` (to clear selection).
- **After**: Use the returned paths for other node operations.
- **Note**: Read-only tool — doesn't modify the selection.

---

## Tool: select_nodes

**Tool name**: `select_nodes`  
**Description**: Select nodes in the editor  
**Backend method**: `node/select`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `paths` | `z.array(z.string())` | Yes | — | List of node paths to select |

### Test Scenarios

#### Scenario 1: Happy path — select a single node

**Description**: Select one node in the editor.  
**Params**:
```json
{
  "paths": ["Player"]
}
```
**Expected result**: The `Player` node becomes selected in the Godot editor. `get_editor_selection` should return `["Player"]`.  
**Pay attention**: Verify via `get_editor_selection` that the `Player` node is selected.

---

#### Scenario 2: Happy path — select multiple nodes

**Description**: Select multiple nodes at once.  
**Params**:
```json
{
  "paths": ["Player", "Enemy1", "Enemy2"]
}
```
**Expected result**: All three nodes become selected. `get_editor_selection` should return all three paths.  
**Pay attention**: Verify that all three nodes are selected. The order may not match.

---

#### Scenario 3: Happy path — replace existing selection

**Description**: Select new nodes, replacing any previous selection.  
**Params**:
```json
{
  "paths": ["Camera2D"]
}
```
**Expected result**: Previous selection is replaced. Only `Camera2D` is now selected.  
**Notes**: Call `select_nodes` with different paths first, then call again with `["Camera2D"]`.  
**Pay attention**: Verify that the previous selection was replaced, not added to.

---

#### Scenario 4: Edge case — select with empty array

**Description**: Pass an empty array to clear selection (alternative to `clear_editor_selection`).  
**Params**:
```json
{
  "paths": []
}
```
**Expected result**: Selection is cleared (empty array).  
**Pay attention**: Check behavior — may be equivalent to `clear_editor_selection`.

---

#### Scenario 5: Error case — select nonexistent node

**Description**: Try to select a node that doesn't exist.  
**Params**:
```json
{
  "paths": ["NonExistentNode"]
}
```
**Expected result**: Error indicating node not found, or partial success (selects valid nodes, reports invalid ones).  
**Pay attention**: Check behavior — Godot may either reject the entire request or select only existing nodes.

---

#### Scenario 6: Error case — mix of valid and invalid paths

**Description**: Pass a mix of existing and nonexistent node paths.  
**Params**:
```json
{
  "paths": ["Player", "NonExistent1", "Enemy1", "NonExistent2"]
}
```
**Expected result**: Either all-or-nothing (error if any path is invalid) or partial success (selects `Player` and `Enemy1`, reports the invalid ones).  
**Pay attention**: Check behavior with partially invalid data.

---

### Related Tools

- **Before**: `add_node` (to create nodes to select), `open_scene`.
- **After**: `get_editor_selection` (to verify selection), `clear_editor_selection` (to clean up).
- **Note**: This replaces the entire selection, it doesn't add to it.

---

## Tool: clear_editor_selection

**Tool name**: `clear_editor_selection`  
**Description**: Clear the current editor selection  
**Backend method**: `node/clear_selection`

### Parameters

None (empty schema).

### Test Scenarios

#### Scenario 1: Happy path — clear existing selection

**Description**: Clear a non-empty editor selection.  
**Params**:
```json
{}
```
**Expected result**: The editor selection is cleared. `get_editor_selection` should return an empty list `[]`.  
**Notes**: Prerequisite: some nodes must be selected first. Call `select_nodes` with some paths.  
**Pay attention**: Verify via `get_editor_selection` that the selection is empty.

---

#### Scenario 2: Happy path — clear already empty selection

**Description**: Clear when nothing is selected.  
**Params**:
```json
{}
```
**Expected result**: No-op or success. The selection remains empty.  
**Pay attention**: Verify that this does not cause an error. It should be a safe no-op.

---

### Related Tools

- **Before**: `select_nodes` (to have something to clear).
- **After**: `get_editor_selection` (to verify selection is empty).
- **Note**: Read-only/no-op tool in terms of scene tree — only affects editor UI state.

---

## Integration Test Sequences

### Sequence 1: Full node lifecycle

**Description**: Create, configure, rename, move, and delete a node.

**Steps**:
1. `open_scene` → `{ "path": "res://scenes/test_scene.tscn" }` — open a scene
2. `add_node` → `{ "parent_path": "", "type": "Node2D", "name": "LifecycleTest" }` — create node
3. `get_scene_tree` → `{}` — verify node exists
4. `update_property` → `{ "path": "LifecycleTest", "property": "position", "value": [100, 200] }` — set position
5. `get_node_properties` → `{ "path": "LifecycleTest" }` — verify position
6. `rename_node` → `{ "path": "LifecycleTest", "new_name": "RenamedLifecycle" }` — rename
7. `get_scene_tree` → `{}` — verify rename
8. `add_node` → `{ "parent_path": "", "type": "Sprite2D", "name": "MoveTarget" }` — create target parent
9. `move_node` → `{ "path": "RenamedLifecycle", "new_parent": "MoveTarget" }` — move under new parent
10. `get_scene_tree` → `{}` — verify move
11. `delete_node` → `{ "path": "MoveTarget" }` — delete parent (and child)
12. `get_scene_tree` → `{}` — verify both deleted

**Expected**: All steps succeed. Node is created, configured, renamed, moved, and cleaned up.

---

### Sequence 2: Node duplication workflow

**Description**: Create a node, duplicate it, verify the duplicate, clean up.

**Steps**:
1. `add_node` → `{ "parent_path": "", "type": "Node2D", "name": "Original" }`
2. `add_node` → `{ "parent_path": "Original", "type": "Sprite2D", "name": "Child" }` — add child to original
3. `duplicate_node` → `{ "path": "Original" }` — duplicate (should duplicate subtree)
4. `get_scene_tree` → `{}` — verify both Original and duplicate exist with children
5. `get_node_properties` → `{ "path": "Original" }` — get original's properties
6. `get_node_properties` → `{ "path": "Original2" }` — get duplicate's properties (name may vary)
7. `delete_node` → `{ "path": "Original" }` — cleanup
8. `delete_node` → `{ "path": "Original2" }` — cleanup duplicate (name may vary)

**Expected**: Duplicate mirrors the original's structure and properties.

---

### Sequence 3: Signal connection lifecycle

**Description**: Create nodes, connect signals, verify, disconnect.

**Steps**:
1. `add_node` → `{ "parent_path": "", "type": "Node", "name": "SignalSender" }`
2. `add_node` → `{ "parent_path": "", "type": "Node", "name": "SignalReceiver" }`
3. `connect_signal` → `{ "source": "SignalSender", "signal": "ready", "target": "SignalReceiver", "method": "_on_ready" }`
4. `disconnect_signal` → `{ "source": "SignalSender", "signal": "ready", "target": "SignalReceiver", "method": "_on_ready" }`
5. `delete_node` → `{ "path": "SignalSender" }` — cleanup
6. `delete_node` → `{ "path": "SignalReceiver" }` — cleanup

**Note**: The `ready` signal may not be connectable this way. Use a signal that exists on the node type. For a Button: `pressed`. For an Area2D: `body_entered`.

**Expected**: Connection is created and then successfully disconnected.

---

### Sequence 4: Groups management workflow

**Description**: Create nodes, assign groups, query groups, find by group.

**Steps**:
1. `add_node` → `{ "parent_path": "", "type": "Node2D", "name": "GroupedA" }`
2. `add_node` → `{ "parent_path": "", "type": "Node2D", "name": "GroupedB" }`
3. `add_node` → `{ "parent_path": "", "type": "Node2D", "name": "GroupedC" }`
4. `set_node_groups` → `{ "path": "GroupedA", "groups": ["team_alpha", "active"] }`
5. `set_node_groups` → `{ "path": "GroupedB", "groups": ["team_alpha"] }`
6. `set_node_groups` → `{ "path": "GroupedC", "groups": ["team_beta", "active"] }`
7. `get_node_groups` → `{ "path": "GroupedA" }` — should return `["team_alpha", "active"]`
8. `find_nodes_in_group` → `{ "group": "team_alpha" }` — should return `["GroupedA", "GroupedB"]`
9. `find_nodes_in_group` → `{ "group": "active" }` — should return `["GroupedA", "GroupedC"]`
10. `find_nodes_in_group` → `{ "group": "team_beta" }` — should return `["GroupedC"]`
11. Cleanup: `delete_node` for all three

**Expected**: Groups are correctly assigned and queryable.

---

### Sequence 5: Editor selection workflow

**Description**: Select, query, and clear editor selection.

**Steps**:
1. `add_node` → `{ "parent_path": "", "type": "Node2D", "name": "SelectableA" }`
2. `add_node` → `{ "parent_path": "", "type": "Node2D", "name": "SelectableB" }`
3. `select_nodes` → `{ "paths": ["SelectableA", "SelectableB"] }`
4. `get_editor_selection` → `{}` — should return both paths
5. `clear_editor_selection` → `{}`
6. `get_editor_selection` → `{}` — should return empty list
7. `select_nodes` → `{ "paths": ["SelectableA"] }` — select single
8. `get_editor_selection` → `{}` — should return `["SelectableA"]`
9. Cleanup: `delete_node` for both

**Expected**: Selection works correctly — select, query, clear, re-select.

---

### Sequence 6: Control node anchor workflow

**Description**: Create a Control scene, add Control nodes, set anchor presets.

**Steps**:
1. `create_scene` → `{ "path": "res://scenes/anchor_test.tscn", "root_node_type": "Control" }` (from scene.ts)
2. `open_scene` → `{ "path": "res://scenes/anchor_test.tscn" }`
3. `add_node` → `{ "parent_path": "", "type": "Panel", "name": "Background" }`
4. `set_anchor_preset` → `{ "path": "Background", "preset": "full_rect" }`
5. `get_node_properties` → `{ "path": "Background" }` — verify anchors
6. `add_node` → `{ "parent_path": "", "type": "Label", "name": "CenterLabel" }`
7. `set_anchor_preset` → `{ "path": "CenterLabel", "preset": "center" }`
8. `get_node_properties` → `{ "path": "CenterLabel" }` — verify anchors
9. Cleanup: delete scene

**Expected**: Anchor presets are correctly applied to Control nodes.

---

### Sequence 7: Resource assignment workflow

**Description**: Add nodes, assign resources, verify properties.

**Steps**:
1. `add_node` → `{ "parent_path": "", "type": "MeshInstance3D", "name": "TestMesh" }` (for 3D scene)
2. `add_resource` → `{ "node_path": "TestMesh", "resource_type": "StandardMaterial3D", "properties": { "albedo_color": [0, 1, 0, 1] } }`
3. `get_node_properties` → `{ "path": "TestMesh" }` — verify material assigned
4. Cleanup: `delete_node`

**Expected**: Resource is created and assigned to the node with correct properties.

---

## Notes for Test Executor

### Prerequisites for all tests

1. **Godot editor must be running** with the MCP plugin active and connected.
2. **A valid Godot project** must be open with a scene directory.
3. **MCP server must be running** and connected to the Godot plugin.
4. **A test scene must be open** — most node tools operate on the currently open scene.

### Cleanup discipline

- Every test that creates nodes must clean up after itself using `delete_node`.
- Delete child nodes before parent nodes (or delete the parent — it removes children too).
- Restore editor selection if it was modified during tests.
- If a test creates a scene (Sequence 6), delete it after testing.

### Error handling verification

- For every error case, verify:
  1. The result has `isError: true` (or equivalent error indicator).
  2. The error message is descriptive (not a generic "tool failed").
  3. The Godot editor remains stable (no crash, no corrupted state).

### Parameter validation

- Zod schema validation happens at the MCP server level before the request reaches Godot.
- Invalid types (e.g., string where number expected) should fail at validation, not reach Godot.
- Godot-level errors (node not found, invalid property) come back as tool results with error content.

### Cross-tool dependency graph

```
open_scene ──→ add_node ──→ get_scene_tree
                 │  │
                 │  ├──→ update_property ──→ get_node_properties
                 │  │
                 │  ├──→ rename_node (path changes!)
                 │  │
                 │  ├──→ move_node (path changes!)
                 │  │
                 │  ├──→ duplicate_node ──→ delete_node (cleanup)
                 │  │
                 │  ├──→ delete_node
                 │  │
                 │  ├──→ add_resource ──→ get_node_properties
                 │  │
                 │  ├──→ set_anchor_preset ──→ get_node_properties
                 │  │
                 │  ├──→ set_node_groups ──→ get_node_groups
                 │  │                    └──→ find_nodes_in_group
                 │  │
                 │  ├──→ connect_signal ──→ disconnect_signal
                 │  │
                 │  └──→ select_nodes ──→ get_editor_selection
                 │                       └──→ clear_editor_selection
                 │
                 └──→ get_node_properties (read-only)

get_editor_selection (read-only, no dependency on nodes existing)
clear_editor_selection (no dependency on nodes existing)
find_nodes_in_group (read-only, depends on groups being set)
```

### Tools that change node paths

The following tools can change a node's path, invalidating previously known paths:
- `rename_node` — changes the node's name in the path
- `move_node` — changes the parent in the path
- `update_property` with `property: "name"` — also renames the node

After any of these, use `get_scene_tree` to discover the new paths before making further calls.
