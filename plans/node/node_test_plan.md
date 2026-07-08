# Node Tools — Comprehensive Test Plan

**Source file:** `server/src/tools/node.ts`
**Shared types:** `server/src/tools/shared-types.ts`
**Total tools:** 17

All tools delegate to `callGodot(bridge, '<endpoint>', args)`. The handler logic is identical across tools — a thin MCP registration layer. The Godot editor plugin performs the actual work. Tests must therefore run against a live Godot editor with the MCP plugin active and a scene open.

Parameters reference the following shared Zod schemas from `shared-types.ts`:
- **NodePath** — `z.string()` (e.g. `'Player/Sprite2D'`, `''` for scene root)
- **ParentPath** — `z.string()` (e.g. `''` for scene root, `'Player'` for root-level child, `'Player/Sprites'` for nested)
- **NodeType** — `z.string()` (e.g. `'Sprite2D'`, `'CharacterBody3D'`)
- **PropertyName** — `z.string()` (e.g. `'position'`, `'visible'`)
- **PropertyValue** — `z.unknown()` (any serializable value)
- **OptionalProperties** — `z.record(z.unknown()).optional()` (optional key-value map)

---

## Pre-requisites for all tests

1. Godot editor is running with the MCP plugin active.
2. A scene is open in the editor containing at least a root node (e.g. `Node2D` or `Node3D`).
3. For tools requiring specific node types, those nodes must exist in the scene before the test.

---

## Test Data Setup (before each test run)

```
Scene root: Node2D (named "Root")
├── Sprite2D (named "Player")
├── Sprite2D (named "Enemy")
└── Control (named "UI")
    ├── Button (named "StartButton")
    └── Label (named "StatusLabel")
```

Groups pre-assigned: `Player` belongs to group `"players"`, `Enemy` belongs to group `"enemies"`.

---

## Tool: `add_node`

**Description:** Add a new node to the scene tree
**MCP endpoint:** `node/add`

### Parameters

| Parameter      | Type                        | Required | Description |
|----------------|-----------------------------|----------|-------------|
| `parent_path`  | ParentPath (`z.string()`)   | Yes      | Parent node path (`''` for root, `'Player'` for root-level child) |
| `type`         | NodeType (`z.string()`)     | Yes      | Node type name (e.g. `'Sprite2D'`, `'CharacterBody3D'`) |
| `name`         | `z.string()`                | Yes      | Name for the new node |
| `properties`   | OptionalProperties          | No       | Optional key-value property pairs |

### Test Scenarios

#### Scenario 1: Add a node to scene root (happy path)
- **Description:** Add a `Sprite2D` named `"TestSprite"` to the scene root.
- **Params:** `{ parent_path: "", type: "Sprite2D", name: "TestSprite" }`
- **Expected:** Success. Scene contains a new `Sprite2D` node named `"TestSprite"` as a direct child of the root.
- **Notes:** The node name is empty string for root.

#### Scenario 2: Add a node as child of an existing node
- **Description:** Add a `Label` named `"NewLabel"` as a child of the `"UI"` Control node.
- **Params:** `{ parent_path: "UI", type: "Label", name: "NewLabel" }`
- **Expected:** Success. `UI/NewLabel` exists as a Label node.

#### Scenario 3: Add a node with properties
- **Description:** Add a `Sprite2D` with position and scale set.
- **Params:** `{ parent_path: "", type: "Sprite2D", name: "PositionedSprite", properties: { position: [100, 200], scale: [2, 2] } }`
- **Expected:** Success. New `Sprite2D` at position `(100, 200)` with scale `(2, 2)`.

#### Scenario 4: Missing required param `parent_path`
- **Description:** Omit `parent_path`.
- **Params:** `{ type: "Sprite2D", name: "BadSprite" }`
- **Expected:** Zod validation error (or MCP error). Node not created.

#### Scenario 5: Missing required param `type`
- **Description:** Omit `type`.
- **Params:** `{ parent_path: "", name: "BadSprite" }`
- **Expected:** Zod validation error.

#### Scenario 6: Missing required param `name`
- **Description:** Omit `name`.
- **Params:** `{ parent_path: "", type: "Sprite2D" }`
- **Expected:** Zod validation error.

#### Scenario 7: Invalid node type
- **Description:** Use a non-existent node type.
- **Params:** `{ parent_path: "", type: "NonExistentType", name: "BadNode" }`
- **Expected:** Godot plugin returns an error. Node not created.

#### Scenario 8: Invalid parent path
- **Description:** Use a parent path that doesn't exist.
- **Params:** `{ parent_path: "NonExistentParent", type: "Sprite2D", name: "Orphan" }`
- **Expected:** Godot plugin returns an error.

#### Scenario 9: Add various node types
- **Description:** Test with different common node types.
- **Params variants:**
  - `{ parent_path: "", type: "Node2D", name: "N2D" }`
  - `{ parent_path: "", type: "Node3D", name: "N3D" }`
  - `{ parent_path: "", type: "CharacterBody2D", name: "CB2D" }`
  - `{ parent_path: "", type: "CharacterBody3D", name: "CB3D" }`
  - `{ parent_path: "", type: "Control", name: "Ctrl" }`
  - `{ parent_path: "", type: "AnimationPlayer", name: "AnimPlayer" }`
  - `{ parent_path: "", type: "Timer", name: "TimerNode" }`
  - `{ parent_path: "", type: "Area2D", name: "Area" }`
  - `{ parent_path: "", type: "RigidBody2D", name: "RBody" }`
  - `{ parent_path: "", type: "Camera2D", name: "Cam" }`
  - `{ parent_path: "", type: "CollisionShape2D", name: "ColShape" }`
- **Expected:** Each call succeeds with the correct node type.

#### Scenario 10: Empty properties object
- **Description:** Pass an empty properties object.
- **Params:** `{ parent_path: "", type: "Sprite2D", name: "NoPropsSprite", properties: {} }`
- **Expected:** Success. Node created with default properties.

---

## Tool: `delete_node`

**Description:** Delete a node from the scene tree
**MCP endpoint:** `node/delete`

### Parameters

| Parameter | Type                    | Required | Description |
|-----------|-------------------------|----------|-------------|
| `path`    | NodePath (`z.string()`) | Yes      | Node path to delete (e.g. `'Player/Sprite2D'`) |

### Test Scenarios

#### Scenario 1: Delete an existing node (happy path)
- **Description:** Delete `"Enemy"` node from the scene.
- **Params:** `{ path: "Enemy" }`
- **Expected:** Success. `"Enemy"` node no longer exists in the scene tree.

#### Scenario 2: Delete a nested node
- **Description:** Delete `"StartButton"` which is a child of `"UI"`.
- **Params:** `{ path: "UI/StartButton" }`
- **Expected:** Success. `UI/StartButton` is removed.

#### Scenario 3: Delete scene root
- **Description:** Attempt to delete the scene root (path `""`).
- **Params:** `{ path: "" }`
- **Expected:** Godot plugin returns an error (cannot delete scene root).

#### Scenario 4: Delete non-existent node
- **Description:** Try to delete a node that doesn't exist.
- **Params:** `{ path: "NonExistentNode" }`
- **Expected:** Godot plugin returns an error.

#### Scenario 5: Missing required param `path`
- **Description:** Omit `path`.
- **Params:** `{}`
- **Expected:** Zod validation error.

---

## Tool: `duplicate_node`

**Description:** Duplicate a node in the scene tree
**MCP endpoint:** `node/duplicate`

### Parameters

| Parameter | Type                    | Required | Description |
|-----------|-------------------------|----------|-------------|
| `path`    | NodePath (`z.string()`) | Yes      | Node path to duplicate |

### Test Scenarios

#### Scenario 1: Duplicate an existing node (happy path)
- **Description:** Duplicate the `"Player"` node.
- **Params:** `{ path: "Player" }`
- **Expected:** Success. A duplicate of `"Player"` appears as a sibling (likely named `"Player2"` or `"Player (copy)"`).

#### Scenario 2: Duplicate a nested node
- **Description:** Duplicate `"UI/StatusLabel"`.
- **Params:** `{ path: "UI/StatusLabel" }`
- **Expected:** Success. A duplicate appears as a sibling under `"UI"`.

#### Scenario 3: Duplicate scene root
- **Description:** Attempt to duplicate the scene root.
- **Params:** `{ path: "" }`
- **Expected:** Likely error (root duplication may not be supported).

#### Scenario 4: Duplicate non-existent node
- **Description:** Try to duplicate a non-existent node.
- **Params:** `{ path: "NonExistentNode" }`
- **Expected:** Godot plugin returns an error.

#### Scenario 5: Missing required param `path`
- **Description:** Omit `path`.
- **Params:** `{}`
- **Expected:** Zod validation error.

---

## Tool: `move_node`

**Description:** Move a node to a new parent in the scene tree
**MCP endpoint:** `node/move`

### Parameters

| Parameter    | Type                          | Required | Description |
|--------------|-------------------------------|----------|-------------|
| `path`       | NodePath (`z.string()`)       | Yes      | Node path to move |
| `new_parent` | `z.string()`                  | Yes      | New parent node path |
| `index`      | `z.number().int().min(0)`     | No       | Child index position (optional) |

### Test Scenarios

#### Scenario 1: Move node to a different parent (happy path)
- **Description:** Move `"Enemy"` to become a child of `"UI"`.
- **Params:** `{ path: "Enemy", new_parent: "UI" }`
- **Expected:** Success. `"Enemy"` is now child of `"UI"` (`UI/Enemy` exists).

#### Scenario 2: Move node with specific index
- **Description:** Move `"Enemy"` to `"UI"` at index 0.
- **Params:** `{ path: "Enemy", new_parent: "UI", index: 0 }`
- **Expected:** Success. `"Enemy"` is first child of `"UI"`.

#### Scenario 3: Move node to scene root
- **Description:** Move `"UI/StartButton"` to scene root using empty string.
- **Params:** `{ path: "UI/StartButton", new_parent: "" }`
- **Expected:** Success. `"StartButton"` is now a direct root child.

#### Scenario 4: Missing required param `path`
- **Description:** Omit `path`.
- **Params:** `{ new_parent: "UI" }`
- **Expected:** Zod validation error.

#### Scenario 5: Missing required param `new_parent`
- **Description:** Omit `new_parent`.
- **Params:** `{ path: "Enemy" }`
- **Expected:** Zod validation error.

#### Scenario 6: Negative index
- **Description:** Pass a negative index value.
- **Params:** `{ path: "Enemy", new_parent: "UI", index: -1 }`
- **Expected:** Zod validation error (`min(0)` constraint violated).

#### Scenario 7: Non-integer index
- **Description:** Pass a float for index.
- **Params:** `{ path: "Enemy", new_parent: "UI", index: 1.5 }`
- **Expected:** Zod validation error (`.int()` constraint violated).

#### Scenario 8: Non-existent source node
- **Description:** Move a node that doesn't exist.
- **Params:** `{ path: "GhostNode", new_parent: "UI" }`
- **Expected:** Godot plugin returns an error.

#### Scenario 9: Non-existent target parent
- **Description:** Move to a parent that doesn't exist.
- **Params:** `{ path: "Enemy", new_parent: "NoSuchParent" }`
- **Expected:** Godot plugin returns an error.

#### Scenario 10: Index beyond child count
- **Description:** Use a very large index.
- **Params:** `{ path: "Enemy", new_parent: "UI", index: 9999 }`
- **Expected:** Godot likely appends at end (implementation-defined). Should not crash.

---

## Tool: `update_property`

**Description:** Update a property value on a node
**MCP endpoint:** `node/update_property`

### Parameters

| Parameter  | Type                            | Required | Description |
|------------|---------------------------------|----------|-------------|
| `path`     | NodePath (`z.string()`)         | Yes      | Node path |
| `property` | PropertyName (`z.string()`)     | Yes      | Property name (e.g. `'position'`, `'visible'`) |
| `value`    | PropertyValue (`z.unknown()`)   | Yes      | New value for the property |

### Test Scenarios

#### Scenario 1: Update a string property (happy path)
- **Description:** Change the `name` of `"Enemy"` to `"Boss"`.
- **Params:** `{ path: "Enemy", property: "name", value: "Boss" }`
- **Expected:** Success. Node renamed to `"Boss"`. Verify with `get_node_properties`.

#### Scenario 2: Update a numeric property
- **Description:** Set `scale.x` of `"Player"`.
- **Params:** `{ path: "Player", property: "scale:x", value: 2.0 }`
- **Expected:** Success. Player scale X is now 2.0.

#### Scenario 3: Update a boolean property
- **Description:** Hide `"Enemy"`.
- **Params:** `{ path: "Enemy", property: "visible", value: false }`
- **Expected:** Success. Enemy is now invisible.

#### Scenario 4: Update a Vector2 property
- **Description:** Set position of `"Player"`.
- **Params:** `{ path: "Player", property: "position", value: [50, 100] }`
- **Expected:** Success. Player position is `(50, 100)`.

#### Scenario 5: Update a Color property
- **Description:** Set modulate of `"Player"`.
- **Params:** `{ path: "Player", property: "modulate", value: "#FF0000FF" }`
- **Expected:** Success (if Godot accepts hex color string for Color property).

#### Scenario 6: Missing required param `path`
- **Description:** Omit `path`.
- **Params:** `{ property: "visible", value: false }`
- **Expected:** Zod validation error.

#### Scenario 7: Missing required param `property`
- **Description:** Omit `property`.
- **Params:** `{ path: "Player", value: false }`
- **Expected:** Zod validation error.

#### Scenario 8: Missing required param `value`
- **Description:** Omit `value`.
- **Params:** `{ path: "Player", property: "visible" }`
- **Expected:** Zod validation error (value is required, not optional).

#### Scenario 9: Non-existent property
- **Description:** Try to set a property that doesn't exist.
- **Params:** `{ path: "Player", property: "non_existent_field", value: 42 }`
- **Expected:** Godot plugin returns an error.

#### Scenario 10: Non-existent node
- **Description:** Try to update property on a non-existent node.
- **Params:** `{ path: "GhostNode", property: "visible", value: true }`
- **Expected:** Godot plugin returns an error.

#### Scenario 11: Set value to null
- **Description:** Set `modulate` to `null`.
- **Params:** `{ path: "Player", property: "modulate", value: null }`
- **Expected:** Behavior depends on property type. Should not crash.

#### Scenario 12: Set value as complex object
- **Description:** Set position via object notation.
- **Params:** `{ path: "Player", property: "position", value: { x: 10, y: 20 } }`
- **Expected:** Depends on Godot's handling of object vs array for Vector2. May fail or succeed.

---

## Tool: `get_node_properties`

**Description:** Get all properties of a node
**MCP endpoint:** `node/get_properties`

### Parameters

| Parameter | Type                    | Required | Description |
|-----------|-------------------------|----------|-------------|
| `path`    | NodePath (`z.string()`) | Yes      | Node path |

### Test Scenarios

#### Scenario 1: Get properties of an existing node (happy path)
- **Description:** Retrieve all properties of `"Player"`.
- **Params:** `{ path: "Player" }`
- **Expected:** Returns a JSON object with all serializable properties (name, position, scale, visible, modulate, etc.).

#### Scenario 2: Get properties of scene root
- **Description:** Retrieve properties of the scene root.
- **Params:** `{ path: "" }`
- **Expected:** Returns properties of the root node.

#### Scenario 3: Get properties of nested node
- **Description:** Retrieve properties of `"UI/StatusLabel"`.
- **Params:** `{ path: "UI/StatusLabel" }`
- **Expected:** Returns Label-specific properties (text, font, align, etc.).

#### Scenario 4: Non-existent node
- **Description:** Try to get properties of a non-existent node.
- **Params:** `{ path: "GhostNode" }`
- **Expected:** Godot plugin returns an error.

#### Scenario 5: Missing required param `path`
- **Description:** Omit `path`.
- **Params:** `{}`
- **Expected:** Zod validation error.

---

## Tool: `add_resource`

**Description:** Add a resource (material, texture, etc.) to a node property
**MCP endpoint:** `node/add_resource`

### Parameters

| Parameter       | Type                           | Required | Description |
|-----------------|--------------------------------|----------|-------------|
| `node_path`     | NodePath (`z.string()`)        | Yes      | Node to add resource to (e.g. `'Player'` or `'Player/Cube'`) |
| `resource_type` | `z.string()`                   | Yes      | Resource type (e.g. `'Material'`, `'Texture2D'`) |
| `properties`    | OptionalProperties             | No       | Optional property key-value pairs |

### Test Scenarios

#### Scenario 1: Add a material to a Sprite2D (happy path)
- **Description:** Add a `Material` resource to `"Player"`.
- **Params:** `{ node_path: "Player", resource_type: "Material" }`
- **Expected:** Success. `"Player"` now has a material resource assigned (visible in property `material`).

#### Scenario 2: Add a resource with properties
- **Description:** Add a `ShaderMaterial` with shader path.
- **Params:** `{ node_path: "Player", resource_type: "ShaderMaterial", properties: { shader: "res://shaders/outline.gdshader" } }`
- **Expected:** Success. Player gets a ShaderMaterial (shader path must exist or error).

#### Scenario 3: Missing required param `node_path`
- **Description:** Omit `node_path`.
- **Params:** `{ resource_type: "Material" }`
- **Expected:** Zod validation error.

#### Scenario 4: Missing required param `resource_type`
- **Description:** Omit `resource_type`.
- **Params:** `{ node_path: "Player" }`
- **Expected:** Zod validation error.

#### Scenario 5: Invalid resource type
- **Description:** Use a non-existent resource type.
- **Params:** `{ node_path: "Player", resource_type: "NonExistentResource" }`
- **Expected:** Godot plugin returns an error.

#### Scenario 6: Non-existent node path
- **Description:** Add resource to a node that doesn't exist.
- **Params:** `{ node_path: "Ghost", resource_type: "Material" }`
- **Expected:** Godot plugin returns an error.

#### Scenario 7: Empty properties
- **Description:** Pass empty properties object.
- **Params:** `{ node_path: "Player", resource_type: "Material", properties: {} }`
- **Expected:** Should behave same as without properties. Success.

---

## Tool: `set_anchor_preset`

**Description:** Set anchor preset on a Control node
**MCP endpoint:** `node/set_anchor_preset`

### Parameters

| Parameter | Type                    | Required | Description |
|-----------|-------------------------|----------|-------------|
| `path`    | NodePath (`z.string()`) | Yes      | Control node path |
| `preset`  | `z.string()`            | Yes      | Anchor preset name (e.g. `'full_rect'`, `'center'`, `'top_left'`) |

### Test Scenarios

#### Scenario 1: Set full_rect preset (happy path)
- **Description:** Set the `"UI"` Control node to full rect anchors.
- **Params:** `{ path: "UI", preset: "full_rect" }`
- **Expected:** Success. `"UI"` anchors set to cover entire parent.

#### Scenario 2: Known anchor preset values
- **Description:** Test each documented preset value.
- **Params variants:**
  - `{ path: "UI", preset: "full_rect" }` — anchors expand to fill parent
  - `{ path: "UI", preset: "center" }` — centered in parent
  - `{ path: "UI", preset: "top_left" }` — top-left corner
  - `{ path: "UI", preset: "top_right" }` — top-right
  - `{ path: "UI", preset: "bottom_left" }` — bottom-left
  - `{ path: "UI", preset: "bottom_right" }` — bottom-right
  - `{ path: "UI", preset: "center_left" }` — centered left
  - `{ path: "UI", preset: "center_right" }` — centered right
  - `{ path: "UI", preset: "center_top" }` — centered top
  - `{ path: "UI", preset: "center_bottom" }` — centered bottom
  - `{ path: "UI", preset: "left_wide" }` — left side, full height
  - `{ path: "UI", preset: "right_wide" }` — right side, full height
  - `{ path: "UI", preset: "top_wide" }` — top, full width
  - `{ path: "UI", preset: "bottom_wide" }` — bottom, full width
  - `{ path: "UI", preset: "hcenter_wide" }` — horizontally centered, full width
  - `{ path: "UI", preset: "vcenter_wide" }` — vertically centered, full height
- **Expected:** Each call succeeds and the node's anchor properties reflect the preset.

#### Scenario 3: Set preset on non-Control node
- **Description:** Try to set anchor preset on a `Sprite2D`.
- **Params:** `{ path: "Player", preset: "center" }`
- **Expected:** Godot plugin returns an error (only Control nodes have anchors).

#### Scenario 4: Unknown preset name
- **Description:** Use a preset name that doesn't exist.
- **Params:** `{ path: "UI", preset: "invalid_preset" }`
- **Expected:** Godot plugin returns an error.

#### Scenario 5: Missing required param `path`
- **Description:** Omit `path`.
- **Params:** `{ preset: "center" }`
- **Expected:** Zod validation error.

#### Scenario 6: Missing required param `preset`
- **Description:** Omit `preset`.
- **Params:** `{ path: "UI" }`
- **Expected:** Zod validation error.

#### Scenario 7: Empty string preset
- **Description:** Pass empty string as preset.
- **Params:** `{ path: "UI", preset: "" }`
- **Expected:** Godot plugin likely returns an error (invalid preset).

---

## Tool: `rename_node`

**Description:** Rename a node in the scene tree
**MCP endpoint:** `node/rename`

### Parameters

| Parameter  | Type                    | Required | Description |
|------------|-------------------------|----------|-------------|
| `path`     | NodePath (`z.string()`) | Yes      | Current node path |
| `new_name` | `z.string()`            | Yes      | New name for the node |

### Test Scenarios

#### Scenario 1: Rename a node (happy path)
- **Description:** Rename `"Enemy"` to `"Boss"`.
- **Params:** `{ path: "Enemy", new_name: "Boss" }`
- **Expected:** Success. Node now accessible at path `"Boss"`.

#### Scenario 2: Rename a nested node
- **Description:** Rename `"UI/StatusLabel"` to `"UI/ScoreLabel"`.
- **Params:** `{ path: "UI/StatusLabel", new_name: "ScoreLabel" }`
- **Expected:** Success. Node accessible at `"UI/ScoreLabel"`.

#### Scenario 3: Rename to same name
- **Description:** Rename `"Player"` to `"Player"` (no-op).
- **Params:** `{ path: "Player", new_name: "Player" }`
- **Expected:** Should succeed (no-op), or possibly error. Godot behavior TBD.

#### Scenario 4: Rename to name with special characters
- **Description:** Rename a node to a name with spaces and special chars.
- **Params:** `{ path: "Enemy", new_name: "Enemy (Clone)" }`
- **Expected:** Success. Node accessible with the new name.

#### Scenario 5: Non-existent source node
- **Description:** Try to rename a non-existent node.
- **Params:** `{ path: "Ghost", new_name: "Real" }`
- **Expected:** Godot plugin returns an error.

#### Scenario 6: Missing required param `path`
- **Description:** Omit `path`.
- **Params:** `{ new_name: "NewName" }`
- **Expected:** Zod validation error.

#### Scenario 7: Missing required param `new_name`
- **Description:** Omit `new_name`.
- **Params:** `{ path: "Player" }`
- **Expected:** Zod validation error.

#### Scenario 8: Empty new name
- **Description:** Rename to empty string.
- **Params:** `{ path: "Enemy", new_name: "" }`
- **Expected:** Godot plugin likely returns an error (empty node names not allowed).

---

## Tool: `connect_signal`

**Description:** Connect a signal from one node to another node's method
**MCP endpoint:** `node/connect_signal`

### Parameters

| Parameter | Type                    | Required | Description |
|-----------|-------------------------|----------|-------------|
| `source`  | NodePath (`z.string()`) | Yes      | Node path emitting the signal |
| `signal`  | `z.string()`            | Yes      | Signal name |
| `target`  | NodePath (`z.string()`) | Yes      | Node path receiving the signal |
| `method`  | `z.string()`            | Yes      | Method to call on the target node |

### Test Scenarios

#### Scenario 1: Connect signal between two nodes (happy path)
- **Description:** Connect `"StartButton"`'s `pressed` signal to `"UI"`'s `_on_button_pressed` method.
- **Params:** `{ source: "UI/StartButton", signal: "pressed", target: "UI", method: "_on_button_pressed" }`
- **Expected:** Success. Signal connection is established. Verify via `get_signals`.

#### Scenario 2: Connect built-in signal
- **Description:** Connect `"Player"`'s `ready` signal to itself.
- **Params:** `{ source: "Player", signal: "ready", target: "Player", method: "_on_ready" }`
- **Expected:** Success. Self-referencing signal connection works.

#### Scenario 3: Non-existent source node
- **Description:** Connect from a non-existent node.
- **Params:** `{ source: "Ghost", signal: "pressed", target: "UI", method: "handler" }`
- **Expected:** Godot plugin returns an error.

#### Scenario 4: Non-existent target node
- **Description:** Connect to a non-existent target.
- **Params:** `{ source: "UI/StartButton", signal: "pressed", target: "Ghost", method: "handler" }`
- **Expected:** Godot plugin returns an error.

#### Scenario 5: Non-existent signal
- **Description:** Connect a signal that doesn't exist on the source.
- **Params:** `{ source: "Player", signal: "non_existent_signal", target: "Player", method: "handler" }`
- **Expected:** Godot plugin returns an error.

#### Scenario 6: Missing required param `source`
- **Description:** Omit `source`.
- **Params:** `{ signal: "pressed", target: "UI", method: "handler" }`
- **Expected:** Zod validation error.

#### Scenario 7: Missing required param `signal`
- **Description:** Omit `signal`.
- **Params:** `{ source: "UI/StartButton", target: "UI", method: "handler" }`
- **Expected:** Zod validation error.

#### Scenario 8: Missing required param `target`
- **Description:** Omit `target`.
- **Params:** `{ source: "UI/StartButton", signal: "pressed", method: "handler" }`
- **Expected:** Zod validation error.

#### Scenario 9: Missing required param `method`
- **Description:** Omit `method`.
- **Params:** `{ source: "UI/StartButton", signal: "pressed", target: "UI" }`
- **Expected:** Zod validation error.

#### Scenario 10: Duplicate connection
- **Description:** Connect the same signal twice.
- **Params:** First call, then repeat: `{ source: "UI/StartButton", signal: "pressed", target: "UI", method: "_on_button_pressed" }`
- **Expected:** Second call may error (duplicate connection) or Godot may silently handle it.

---

## Tool: `disconnect_signal`

**Description:** Disconnect a signal connection
**MCP endpoint:** `node/disconnect_signal`

### Parameters

| Parameter | Type                    | Required | Description |
|-----------|-------------------------|----------|-------------|
| `source`  | NodePath (`z.string()`) | Yes      | Node path that emits the signal |
| `signal`  | `z.string()`            | Yes      | Signal name |
| `target`  | NodePath (`z.string()`) | Yes      | Node path that receives the signal |
| `method`  | `z.string()`            | Yes      | Method that was connected |

### Test Scenarios

#### Scenario 1: Disconnect an existing signal (happy path)
- **Description:** Disconnect the signal connected in `connect_signal` Scenario 1.
- **Prerequisite:** Run `connect_signal` Scenario 1 first.
- **Params:** `{ source: "UI/StartButton", signal: "pressed", target: "UI", method: "_on_button_pressed" }`
- **Expected:** Success. Signal connection removed.

#### Scenario 2: Disconnect non-existent connection
- **Description:** Try to disconnect a signal that was never connected.
- **Params:** `{ source: "Player", signal: "ready", target: "UI", method: "never_connected" }`
- **Expected:** Godot plugin returns an error (no such connection).

#### Scenario 3: Disconnect from non-existent source
- **Description:** Try to disconnect from a node that doesn't exist.
- **Params:** `{ source: "Ghost", signal: "pressed", target: "UI", method: "handler" }`
- **Expected:** Godot plugin returns an error.

#### Scenario 4: Missing required params
- **Description:** Test each required param missing individually.
- **Params variants:**
  - `{ signal: "pressed", target: "UI", method: "handler" }` — missing `source`
  - `{ source: "Btn", target: "UI", method: "handler" }` — missing `signal`
  - `{ source: "Btn", signal: "pressed", method: "handler" }` — missing `target`
  - `{ source: "Btn", signal: "pressed", target: "UI" }` — missing `method`
- **Expected:** Each returns Zod validation error.

---

## Tool: `get_node_groups`

**Description:** Get all groups a node belongs to
**MCP endpoint:** `node/get_groups`

### Parameters

| Parameter | Type                    | Required | Description |
|-----------|-------------------------|----------|-------------|
| `path`    | NodePath (`z.string()`) | Yes      | Node path |

### Test Scenarios

#### Scenario 1: Get groups of a node in groups (happy path)
- **Description:** Get groups for `"Player"` (expected to be in `"players"` group).
- **Params:** `{ path: "Player" }`
- **Expected:** Returns an array containing `"players"`.

#### Scenario 2: Get groups of a node with no groups
- **Description:** Get groups for a node freshly added to the scene (no group membership).
- **Prerequisite:** Add a new ungrouped node.
- **Params:** `{ path: "NewNode" }`
- **Expected:** Returns an empty array `[]`.

#### Scenario 3: Get groups of scene root
- **Description:** Get groups of the scene root.
- **Params:** `{ path: "" }`
- **Expected:** Returns groups array (likely empty unless explicitly set).

#### Scenario 4: Non-existent node
- **Description:** Get groups of a non-existent node.
- **Params:** `{ path: "Ghost" }`
- **Expected:** Godot plugin returns an error.

#### Scenario 5: Missing required param `path`
- **Description:** Omit `path`.
- **Params:** `{}`
- **Expected:** Zod validation error.

---

## Tool: `set_node_groups`

**Description:** Set the groups a node belongs to (replaces existing groups)
**MCP endpoint:** `node/set_groups`

### Parameters

| Parameter | Type                          | Required | Description |
|-----------|-------------------------------|----------|-------------|
| `path`    | NodePath (`z.string()`)       | Yes      | Node path |
| `groups`  | `z.array(z.string())`         | Yes      | List of group names |

### Test Scenarios

#### Scenario 1: Set groups on a node (happy path)
- **Description:** Set `"Player"` to belong to groups `["hero", "player_team"]`.
- **Params:** `{ path: "Player", groups: ["hero", "player_team"] }`
- **Expected:** Success. `get_node_groups` for `"Player"` returns `["hero", "player_team"]`.

#### Scenario 2: Set empty groups (clear all groups)
- **Description:** Remove all group memberships from `"Player"`.
- **Params:** `{ path: "Player", groups: [] }`
- **Expected:** Success. `get_node_groups` returns `[]`.

#### Scenario 3: Set single group
- **Description:** Set `"Enemy"` to a single group.
- **Params:** `{ path: "Enemy", groups: ["boss"] }`
- **Expected:** Success. Returns `["boss"]`.

#### Scenario 4: Non-existent node
- **Description:** Set groups on a non-existent node.
- **Params:** `{ path: "Ghost", groups: ["test"] }`
- **Expected:** Godot plugin returns an error.

#### Scenario 5: Missing required param `path`
- **Description:** Omit `path`.
- **Params:** `{ groups: ["test"] }`
- **Expected:** Zod validation error.

#### Scenario 6: Missing required param `groups`
- **Description:** Omit `groups`.
- **Params:** `{ path: "Player" }`
- **Expected:** Zod validation error.

#### Scenario 7: Groups with special characters
- **Description:** Set groups with names containing spaces, hyphens, underscores.
- **Params:** `{ path: "Player", groups: ["my group", "group-1", "group_2"] }`
- **Expected:** Success. Groups are set correctly.

---

## Tool: `find_nodes_in_group`

**Description:** Find all nodes belonging to a specific group
**MCP endpoint:** `node/find_in_group`

### Parameters

| Parameter | Type          | Required | Description |
|-----------|---------------|----------|-------------|
| `group`   | `z.string()`  | Yes      | Group name to search for |

### Test Scenarios

#### Scenario 1: Find nodes in an existing group (happy path)
- **Description:** Find all nodes in the `"players"` group.
- **Params:** `{ group: "players" }`
- **Expected:** Returns an array containing `"Player"` (node path or reference).

#### Scenario 2: Find nodes in an empty group
- **Description:** Find all nodes in a group that exists but has no members.
- **Params:** `{ group: "empty_group" }`
- **Expected:** Returns an empty array `[]`.

#### Scenario 3: Find nodes in a non-existent group
- **Description:** Search for a group that has never been created.
- **Params:** `{ group: "nonexistent_group" }`
- **Expected:** Returns an empty array `[]`. Should not error.

#### Scenario 4: Missing required param `group`
- **Description:** Omit `group`.
- **Params:** `{}`
- **Expected:** Zod validation error.

#### Scenario 5: Empty string group name
- **Description:** Search for group with empty string.
- **Params:** `{ group: "" }`
- **Expected:** Likely returns empty array or error (implementation-defined).

---

## Tool: `get_editor_selection`

**Description:** Get the currently selected nodes in the editor
**MCP endpoint:** `node/get_selection`

### Parameters

None. `inputSchema: {}`

### Test Scenarios

#### Scenario 1: Get selection when nodes are selected (happy path)
- **Description:** Select `"Player"` in the editor, then call `get_editor_selection`.
- **Prerequisite:** Use `select_nodes` to select `"Player"` first.
- **Params:** `{}` (no params)
- **Expected:** Returns an array containing `"Player"` (node path).

#### Scenario 2: Get selection when nothing is selected
- **Description:** Clear selection first, then call `get_editor_selection`.
- **Prerequisite:** Use `clear_editor_selection` first.
- **Params:** `{}`
- **Expected:** Returns an empty array `[]`.

#### Scenario 3: Get selection with multiple nodes selected
- **Description:** Select multiple nodes and verify all are returned.
- **Prerequisite:** Select `["Player", "Enemy"]` via `select_nodes`.
- **Params:** `{}`
- **Expected:** Returns array containing both `"Player"` and `"Enemy"`.

#### Scenario 4: Call with extra params
- **Description:** Pass unexpected parameters.
- **Params:** `{ foo: "bar" }`
- **Expected:** Extra params should be ignored or validated away. Should work normally.

---

## Tool: `select_nodes`

**Description:** Select nodes in the editor
**MCP endpoint:** `node/select`

### Parameters

| Parameter | Type                          | Required | Description |
|-----------|-------------------------------|----------|-------------|
| `paths`   | `z.array(z.string())`         | Yes      | List of node paths to select |

### Test Scenarios

#### Scenario 1: Select a single node (happy path)
- **Description:** Select `"Player"`.
- **Params:** `{ paths: ["Player"] }`
- **Expected:** Success. `get_editor_selection` returns `["Player"]`.

#### Scenario 2: Select multiple nodes
- **Description:** Select both `"Player"` and `"Enemy"`.
- **Params:** `{ paths: ["Player", "Enemy"] }`
- **Expected:** Success. `get_editor_selection` returns both nodes.

#### Scenario 3: Select nested node
- **Description:** Select `"UI/StartButton"`.
- **Params:** `{ paths: ["UI/StartButton"] }`
- **Expected:** Success. Node is selected.

#### Scenario 4: Select empty array
- **Description:** Pass an empty array.
- **Params:** `{ paths: [] }`
- **Expected:** Likely clears selection or is a no-op. Should not error.

#### Scenario 5: Select non-existent node
- **Description:** Include a non-existent node path in the array.
- **Params:** `{ paths: ["Player", "Ghost"] }`
- **Expected:** Godot plugin returns an error, or selects only the valid ones.

#### Scenario 6: Missing required param `paths`
- **Description:** Omit `paths`.
- **Params:** `{}`
- **Expected:** Zod validation error.

#### Scenario 7: Paths is not an array
- **Description:** Pass a string instead of an array.
- **Params:** `{ paths: "Player" }`
- **Expected:** Zod validation error (expected array).

---

## Tool: `clear_editor_selection`

**Description:** Clear the current editor selection
**MCP endpoint:** `node/clear_selection`

### Parameters

None. `inputSchema: {}`

### Test Scenarios

#### Scenario 1: Clear selection when nodes are selected (happy path)
- **Description:** Select nodes first, then clear.
- **Prerequisite:** Use `select_nodes` to select `["Player", "Enemy"]`.
- **Params:** `{}`
- **Expected:** Success. `get_editor_selection` returns `[]`.

#### Scenario 2: Clear selection when nothing is selected
- **Description:** Call clear when nothing is selected.
- **Params:** `{}`
- **Expected:** Success (no-op). `get_editor_selection` still returns `[]`.

#### Scenario 3: Call with extra params
- **Description:** Pass unexpected parameters.
- **Params:** `{ foo: "bar" }`
- **Expected:** Extra params ignored. Works normally.

---

## End-to-End Workflow Tests

These tests chain multiple tools to verify real-world usage patterns.

### Workflow 1: Create, configure, group, and move a node

1. `add_node` — `{ parent_path: "", type: "Sprite2D", name: "WorkflowSprite" }`
2. `update_property` — `{ path: "WorkflowSprite", property: "position", value: [300, 400] }`
3. `set_node_groups` — `{ path: "WorkflowSprite", groups: ["test_group"] }`
4. `find_nodes_in_group` — `{ group: "test_group" }` → expect `["WorkflowSprite"]`
5. `move_node` — `{ path: "WorkflowSprite", new_parent: "UI" }`
6. `get_node_properties` — `{ path: "UI/WorkflowSprite" }` → verify position is `[300, 400]`
7. `rename_node` — `{ path: "UI/WorkflowSprite", new_name: "MovedSprite" }`
8. `duplicate_node` — `{ path: "UI/MovedSprite" }` → verify duplicate exists
9. `delete_node` — `{ path: "UI/MovedSprite" }` → cleanup

### Workflow 2: Signal connect/disconnect cycle

1. `connect_signal` — `{ source: "UI/StartButton", signal: "pressed", target: "UI", method: "_on_start" }`
2. `get_node_properties` — `{ path: "UI/StartButton" }` or use signal inspection tool to verify
3. `disconnect_signal` — `{ source: "UI/StartButton", signal: "pressed", target: "UI", method: "_on_start" }`

### Workflow 3: Selection lifecycle

1. `get_editor_selection` — `{}` → note initial state
2. `select_nodes` — `{ paths: ["Player", "Enemy"] }`
3. `get_editor_selection` — `{}` → expect `["Player", "Enemy"]`
4. `select_nodes` — `{ paths: ["UI"] }` → switch selection
5. `get_editor_selection` — `{}` → expect `["UI"]`
6. `clear_editor_selection` — `{}` → clear all
7. `get_editor_selection` — `{}` → expect `[]`

---

## Parameter Validation Summary

The following table summarizes Zod validation at the MCP server level (before reaching Godot):

| Tool                  | Required Params                                    | Optional Params      | Zod Constraints                                     |
|-----------------------|---------------------------------------------------|----------------------|-----------------------------------------------------|
| `add_node`            | `parent_path`, `type`, `name`                     | `properties`         | All strings; `properties` is `z.record(z.unknown())`|
| `delete_node`         | `path`                                            | —                    | `NodePath` (string)                                 |
| `duplicate_node`      | `path`                                            | —                    | `NodePath` (string)                                 |
| `move_node`           | `path`, `new_parent`                              | `index`              | `index`: `.int().min(0)`                           |
| `update_property`     | `path`, `property`, `value`                       | —                    | `value` is `z.unknown()` (accepts anything)         |
| `get_node_properties` | `path`                                            | —                    | `NodePath` (string)                                 |
| `add_resource`        | `node_path`, `resource_type`                      | `properties`         | `properties` is optional record                     |
| `set_anchor_preset`   | `path`, `preset`                                  | —                    | Both strings; preset validated by Godot only         |
| `rename_node`         | `path`, `new_name`                                | —                    | Both strings                                        |
| `connect_signal`      | `source`, `signal`, `target`, `method`            | —                    | Four strings                                        |
| `disconnect_signal`   | `source`, `signal`, `target`, `method`            | —                    | Four strings                                        |
| `get_node_groups`     | `path`                                            | —                    | `NodePath` (string)                                 |
| `set_node_groups`     | `path`, `groups`                                  | —                    | `groups`: `z.array(z.string())`                      |
| `find_nodes_in_group` | `group`                                           | —                    | String                                              |
| `get_editor_selection`| —                                                 | —                    | Empty schema                                        |
| `select_nodes`        | `paths`                                           | —                    | `paths`: `z.array(z.string())`                       |
| `clear_editor_selection`| —                                               | —                    | Empty schema                                        |
