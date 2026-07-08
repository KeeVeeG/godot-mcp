# Test Plan: Node Configuration Tools (`node_config.ts`)

**Source**: `server/src/tools/node_config.ts`
**Tools count**: 8
**Registration function**: `registerNodeConfigTools(server, bridge)`
**Backend route prefix**: `node_config/`

---

## Shared Type Definitions (from `shared-types.ts`)

| Schema | Type | Description |
|---|---|---|
| `NodeType` | `z.string()` | Node type name, e.g. `"Sprite2D"`, `"CharacterBody3D"`, `"Node2D"` |
| `NodePath` | `z.string()` | Node instance path in scene tree, e.g. `"Player"`, `"Player/Sprite2D"` |

---

## Dependency Graph & Execution Order

All 8 tools are **read-only introspection tools** (no side effects on the scene tree). They call Godot's editor API to query class metadata.

**Prerequisites for testing:**

| Tool | Prerequisites |
|---|---|
| `get_node_default_properties` | None — works with any valid Godot class name |
| `set_node_preset` | **Mutates a node** — requires an existing node in the scene. Before calling: `create_scene` → `add_node` with known type. After calling: verify node properties changed via `get_node_properties`. |
| `get_available_node_types` | None — enumerates registered types |
| `get_node_signals` (with `type`) | None — works with any valid class name |
| `get_node_signals` (with `path`) | Requires a scene with a node at the given path. Before calling: `create_scene` → `add_node`. The node must exist in the currently open scene. |
| `get_node_methods` | None — works with any valid class name |
| `get_node_enums` | None — works with any valid class name |
| `get_node_constants` | None — works with any valid class name |
| `get_class_hierarchy` | None — works with any valid class name |

**Recommended setup sequence** (once, before all tests):

```
1. create_scene({ path: "res://test_scenes/node_config_test.tscn", root_node_type: "Node2D" })
2. add_node({ parent_path: "", type: "CharacterBody3D", name: "TestBody" })
3. add_node({ parent_path: "TestBody", type: "Sprite2D", name: "TestSprite" })
4. open_scene({ path: "res://test_scenes/node_config_test.tscn" })
```

---

## Tool: `get_node_default_properties`

**Description**: Get the default property values for a node type
**Backend route**: `node_config/get_defaults`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `type` | `string` (NodeType) | ✅ Yes | Node type name (e.g. `"Sprite2D"`, `"CharacterBody3D"`) |

### Test Scenarios

#### Scenario 1: Get defaults for a common 2D node type

- **Description**: Query default properties for `Sprite2D`, one of the most commonly used 2D nodes.
- **Params**:
  ```json
  { "type": "Sprite2D" }
  ```
- **Expected result**: Success response (not `isError`). Result content contains a JSON object with default property values for `Sprite2D`. Expected properties to appear: `position`, `rotation`, `scale`, `visible`, `modulate`, `texture` (null by default), `centered`, `flip_h`, `flip_v`, `offset`.
- **Notes**: All values should match Godot's built-in defaults (e.g. `position: [0,0]`, `visible: true`, `centered: true`).
- **What to check**: Verify that `position` is `[0, 0]` (not `null`), `visible` is `true`, `scale` is `[1, 1]`. If values differ from expected — there may be an issue on the Godot plugin side.

#### Scenario 2: Get defaults for a 3D physics body

- **Description**: Query defaults for `CharacterBody3D`, a complex node with physics properties.
- **Params**:
  ```json
  { "type": "CharacterBody3D" }
  ```
- **Expected result**: Success response. Contains properties like `transform`, `motion_mode`, `up_direction`, `floor_max_angle`, `floor_snap_length`, `max_slides`, `wall_min_slide_angle`, `velocity`. `velocity` should default to `Vector3(0, 0, 0)`.
- **Notes**: `CharacterBody3D` inherits from `PhysicsBody3D` → `CollisionObject3D` → `Node3D` → `Node`. Defaults should include inherited properties.
- **What to check**: Ensure that not only `CharacterBody3D`'s own properties are returned, but also inherited ones (e.g. `transform` from `Node3D`). Verify that `velocity` defaults to `Vector3(0, 0, 0)`.

#### Scenario 3: Get defaults for a UI node

- **Description**: Query defaults for `Button`, a Control-derived node with many styling properties.
- **Params**:
  ```json
  { "type": "Button" }
  ```
- **Expected result**: Success response. Contains Control properties (`anchor_left`, `anchor_top`, `anchor_right`, `anchor_bottom`, `grow_horizontal`, `grow_vertical`) and Button-specific properties (`text`, `flat`, `alignment`, `text_overrun_behavior`).
- **What to check**: `anchor_left/top/right/bottom` should be numeric values (default 0). `text` should be an empty string `""`.

#### Scenario 4: Invalid node type name

- **Description**: Request defaults for a non-existent class name.
- **Params**:
  ```json
  { "type": "NonExistentNodeType12345" }
  ```
- **Expected result**: Error response (`isError: true`) with a message indicating the type was not found or is not a valid Godot class.
- **Notes**: Godot should reject unknown class names. The error message should be informative.
- **What to check**: Ensure a clear error message is returned, not a crash or empty response.

#### Scenario 5: Missing required `type` parameter

- **Description**: Call without the required `type` parameter.
- **Params**:
  ```json
  {}
  ```
- **Expected result**: MCP-level validation error — the Zod schema requires `type`, so the server should reject the call before it reaches Godot.
- **Notes**: This tests MCP schema validation, not Godot behavior.
- **What to check**: The error should mention that the `type` field is required. Verify the error does not cause the server to crash.

---

## Tool: `set_node_preset`

**Description**: Apply a configuration preset to a node (e.g. `'platformer_body'`, `'top_down_camera'`)
**Backend route**: `node_config/set_preset`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `type` | `string` (NodeType) | ✅ Yes | Node type to configure |
| `preset` | `string` | ✅ Yes | Preset name to apply |

### Test Scenarios

#### Scenario 1: Apply platformer_body preset to CharacterBody3D

- **Description**: Apply a known preset to a CharacterBody3D node. This is a mutation — requires a node to exist in the scene.
- **Setup**: `create_scene` → `add_node({ parent_path: "", type: "CharacterBody3D", name: "Player" })`
- **Params**:
  ```json
  { "type": "CharacterBody3D", "preset": "platformer_body" }
  ```
- **Expected result**: Success response. The preset should modify properties on the node (e.g. set `motion_mode`, `up_direction`, `floor_max_angle` to platformer-appropriate values). Response should confirm the preset was applied, possibly listing which properties were changed.
- **Notes**: After applying, verify with `get_node_properties({ path: "Player" })` that the expected properties were actually modified.
- **What to check**: Verify that the preset actually changes node properties, not just returns success. Compare values before and after applying the preset.

#### Scenario 2: Apply top_down_camera preset to Camera3D

- **Description**: Apply a camera preset to a Camera3D node.
- **Setup**: `add_node({ parent_path: "", type: "Camera3D", name: "TopDownCam" })`
- **Params**:
  ```json
  { "type": "Camera3D", "preset": "top_down_camera" }
  ```
- **Expected result**: Success response. Camera properties should be configured for top-down view (e.g. `projection` set to orthogonal or perspective with appropriate FOV, rotation set to look downward).
- **What to check**: Verify that the camera `rotation` corresponds to a top-down view (e.g. `rotation_degrees.x = -90`). Note that `current` does not necessarily have to be `true` — it depends on the preset.

#### Scenario 3: Invalid preset name

- **Description**: Apply a non-existent preset.
- **Params**:
  ```json
  { "type": "CharacterBody3D", "preset": "nonexistent_preset_xyz" }
  ```
- **Expected result**: Error response (`isError: true`) indicating the preset was not found.
- **What to check**: The error message should indicate the preset was not found, not a generic error. Verify the node was not modified.

#### Scenario 4: Missing required `preset` parameter

- **Params**:
  ```json
  { "type": "CharacterBody3D" }
  ```
- **Expected result**: MCP validation error — `preset` is required.
- **What to check**: This should be a Zod validation error, not a request to Godot.

#### Scenario 5: Missing required `type` parameter

- **Params**:
  ```json
  { "preset": "platformer_body" }
  ```
- **Expected result**: MCP validation error — `type` is required.

---

## Tool: `get_available_node_types`

**Description**: Get all available node types, optionally filtered by category
**Backend route**: `node_config/get_types`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `category` | `string` enum | ❌ No | Filter by category. Allowed values: `"2d"`, `"3d"`, `"ui"`, `"audio"`, `"physics"`, `"navigation"` |

### Test Scenarios

#### Scenario 1: Get all node types (no filter)

- **Description**: Retrieve the full list of available node types without any category filter.
- **Params**:
  ```json
  {}
  ```
- **Expected result**: Success response. Returns a list/array of all available Godot node type names. Should include types from all categories: `Sprite2D`, `Node3D`, `Button`, `AudioStreamPlayer`, `RigidBody3D`, `NavigationRegion3D`, etc.
- **Notes**: The list should be substantial (Godot 4.x has 400+ built-in classes). Verify the list is not empty and contains well-known types.
- **What to check**: The list should be non-empty and contain at least `Node`, `Node2D`, `Node3D`, `Control`. Check the response format — it should be an array of strings or an object with a `types` field.

#### Scenario 2: Filter by "2d" category

- **Description**: Get only 2D-related node types.
- **Params**:
  ```json
  { "category": "2d" }
  ```
- **Expected result**: Success response. List should contain 2D types: `Sprite2D`, `Node2D`, `CharacterBody2D`, `RigidBody2D`, `Area2D`, `TileMap`, `Camera2D`, `AnimatedSprite2D`, `CollisionShape2D`, etc. Should NOT contain 3D-only types like `MeshInstance3D` or `DirectionalLight3D`.
- **What to check**: Ensure no 3D nodes (`Node3D`, `MeshInstance3D`) are in the list. Verify that `Node2D` and its subclasses are present.

#### Scenario 3: Filter by "physics" category

- **Params**:
  ```json
  { "category": "physics" }
  ```
- **Expected result**: Success response. Should contain physics-related types: `RigidBody2D`, `RigidBody3D`, `CharacterBody2D`, `CharacterBody3D`, `StaticBody2D`, `StaticBody3D`, `Area2D`, `Area3D`, `CollisionShape2D`, `CollisionShape3D`, `RayCast2D`, `RayCast3D`.
- **What to check**: Verify that both 2D and 3D physics types are present. `Sprite2D` should not be in this list.

#### Scenario 4: Filter by "ui" category

- **Params**:
  ```json
  { "category": "ui" }
  ```
- **Expected result**: Success response. Should contain UI types: `Control`, `Button`, `Label`, `LineEdit`, `TextEdit`, `VBoxContainer`, `HBoxContainer`, `Panel`, `TextureRect`, `RichTextLabel`, `ScrollContainer`, `TabContainer`.
- **What to check**: `Control` and its subclasses. Should not contain `Node2D` or `Sprite2D`.

#### Scenario 5: Invalid category value

- **Description**: Pass a category that is not in the allowed enum.
- **Params**:
  ```json
  { "category": "invalid_category" }
  ```
- **Expected result**: MCP validation error — Zod enum rejects the value. Error should list allowed values.
- **What to check**: The error should contain the list of allowed enum values.

#### Scenario 6: Filter by "audio" category

- **Params**:
  ```json
  { "category": "audio" }
  ```
- **Expected result**: Success response with audio types: `AudioStreamPlayer`, `AudioStreamPlayer2D`, `AudioStreamPlayer3D`.
- **What to check**: Verify that `AudioBusLayout` is not in the list (it's a resource, not a node).

#### Scenario 7: Filter by "navigation" category

- **Params**:
  ```json
  { "category": "navigation" }
  ```
- **Expected result**: Success response with navigation types: `NavigationRegion2D`, `NavigationRegion3D`, `NavigationAgent2D`, `NavigationAgent3D`, `NavigationLink2D`, `NavigationLink3D`.
- **What to check**: Both 2D and 3D navigation types should be present.

---

## Tool: `get_node_signals`

**Description**: Get all signals defined on a node type with their argument signatures. Provide either `"type"` (a class name) or `"path"` (a node instance path — the class will be resolved automatically).
**Backend route**: `node_config/get_signals`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `type` | `string` (NodeType) | ❌ No | Node type name (e.g. `"CharacterBody3D"`). Provide this OR `path`. |
| `path` | `string` (NodePath) | ❌ No | Node instance path in scene (e.g. `"Player"`). Provide this OR `type`. |

**Note**: At least one of `type` or `path` should be provided. If neither is given, the behavior depends on the Godot backend (likely an error).

### Test Scenarios

#### Scenario 1: Get signals by type name

- **Description**: Query signals for a well-known type with many signals.
- **Params**:
  ```json
  { "type": "CharacterBody3D" }
  ```
- **Expected result**: Success response. Returns signal list. `CharacterBody3D` inherits signals from `Node`: `ready`, `tree_entered`, `tree_exiting`, `child_entered_tree`, `child_exiting_tree`, `renamed`. It also has physics body signals from `PhysicsBody3D` collision events.
- **Notes**: Each signal entry should include the signal name and its argument signature (names and types).
- **What to check**: Verify that each signal contains not only the name but also the argument signature. Ensure inherited signals (from `Node`) are also present.

#### Scenario 2: Get signals by node path (instance in scene)

- **Description**: Query signals for an actual node instance in the scene tree.
- **Setup**: `create_scene` → `add_node({ parent_path: "", type: "Area2D", name: "DetectionZone" })` → `open_scene`
- **Params**:
  ```json
  { "path": "DetectionZone" }
  ```
- **Expected result**: Success response. Returns signals for `Area2D`: `body_entered`, `body_exited`, `area_entered`, `area_exited`, `input_event`, plus inherited signals from `Node`.
- **Notes**: The backend should resolve the node's class type from its path automatically.
- **What to check**: Ensure the result is identical to calling with `type: "Area2D"`. Verify that `body_entered` and `body_exited` are present with correct signatures (accept a `Node` argument).

#### Scenario 3: Get signals for a UI control node

- **Params**:
  ```json
  { "type": "Button" }
  ```
- **Expected result**: Success response. Button has signals: `pressed`, `button_up`, `button_down`, `toggled` (for CheckButton). Plus inherited from `BaseButton`: `focus_entered`, `focus_exited`, `mouse_entered`, `mouse_exited`.
- **What to check**: The `pressed` signal should have no arguments. `toggled` should accept `button_pressed: bool`.

#### Scenario 4: Get signals for a simple Node

- **Params**:
  ```json
  { "type": "Node" }
  ```
- **Expected result**: Success response with base `Node` signals: `ready`, `tree_entered`, `tree_exiting`, `tree_exited`, `child_entered_tree`, `child_exiting_tree`, `renamed`, `editor_description_changed`.
- **What to check**: These are the most basic signals. If they're missing — there's a problem with the plugin.

#### Scenario 5: Neither type nor path provided

- **Params**:
  ```json
  {}
  ```
- **Expected result**: Either an MCP validation error or a Godot backend error. Since both are optional, the tool may try to call Godot with empty params, which should return an error indicating that one of them is required.
- **Notes**: This tests the tool's resilience to missing inputs. The tool should ideally fail gracefully.
- **What to check**: Verify the response contains a meaningful error message, not a crash.

#### Scenario 6: Both type and path provided

- **Params**:
  ```json
  { "type": "Sprite2D", "path": "TestSprite" }
  ```
- **Expected result**: Should succeed — the backend likely prioritizes one over the other, or uses `type` when both are given. The result should be valid signals for `Sprite2D`.
- **Notes**: This tests precedence behavior when both params are present.
- **What to check**: Verify the result corresponds to `Sprite2D` signals (not another type). If `path` points to a node of a different type — which parameter takes priority?

#### Scenario 7: Path to non-existent node

- **Params**:
  ```json
  { "path": "NonExistentNode/Deeply/Nested" }
  ```
- **Expected result**: Error response — the node path does not exist in the current scene.
- **What to check**: The error message should indicate the node was not found at the given path.

---

## Tool: `get_node_methods`

**Description**: Get all public methods on a node type with their signatures
**Backend route**: `node_config/get_methods`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `type` | `string` (NodeType) | ✅ Yes | Node type name |

### Test Scenarios

#### Scenario 1: Get methods for CharacterBody3D

- **Description**: Query methods for a complex physics node.
- **Params**:
  ```json
  { "type": "CharacterBody3D" }
  ```
- **Expected result**: Success response. Returns method list including `move_and_slide()`, `is_on_floor()`, `is_on_wall()`, `is_on_ceiling()`, `get_slide_collision_count()`, `get_slide_collision()`. Plus inherited methods from `Node`: `get_node()`, `add_child()`, `remove_child()`, `queue_free()`, `get_tree()`, `set_process()`.
- **Notes**: Each method should include name, return type, and parameter list with types.
- **What to check**: `move_and_slide()` should not accept arguments (in Godot 4.x). `is_on_floor()` returns `bool`. Verify inherited methods are also present.

#### Scenario 2: Get methods for a base Node

- **Params**:
  ```json
  { "type": "Node" }
  ```
- **Expected result**: Success response. Core Node methods: `add_child()`, `remove_child()`, `get_node()`, `get_children()`, `queue_free()`, `get_tree()`, `set_process()`, `set_physics_process()`, `get_parent()`, `is_inside_tree()`, `get_name()`, `set_name()`.
- **What to check**: Verify that `get_node()` accepts a `path: NodePath` parameter. `set_process()` accepts `enable: bool`.

#### Scenario 3: Get methods for a UI Label

- **Params**:
  ```json
  { "type": "Label" }
  ```
- **Expected result**: Success response. Label-specific methods plus inherited Control methods: `set_text()`, `get_text()`, `set_horizontal_alignment()`, `set_vertical_alignment()`, `set_autowrap_mode()`, `set_text_overrun_behavior()`.
- **What to check**: Verify that methods for text manipulation and alignment are present.

#### Scenario 4: Invalid node type

- **Params**:
  ```json
  { "type": "FakeNodeType999" }
  ```
- **Expected result**: Error response indicating invalid type.
- **What to check**: The error should be clear, not a crash.

#### Scenario 5: Missing required `type` parameter

- **Params**:
  ```json
  {}
  ```
- **Expected result**: MCP validation error — `type` is required.

---

## Tool: `get_node_enums`

**Description**: Get all enumerations defined on a node type
**Backend route**: `node_config/get_enums`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `type` | `string` (NodeType) | ✅ Yes | Node type name |

### Test Scenarios

#### Scenario 1: Get enums for CharacterBody3D

- **Description**: Query enumerations for a type with physics-related enums.
- **Params**:
  ```json
  { "type": "CharacterBody3D" }
  ```
- **Expected result**: Success response. Should include enums like `MotionMode` (GROUNDED, FLOATING), `PlatformOnLeave` (ADD_VELOCITY, ADD_UPWARD_VELOCITY, DO_NOTHING). Plus inherited enums.
- **Notes**: Each enum entry should include enum name and its values with integer keys.
- **What to check**: Verify that each enum value contains both the string name and the numeric value. `MotionMode.GROUNDED` is usually = 0, `FLOATING` = 1.

#### Scenario 2: Get enums for a Control node

- **Params**:
  ```json
  { "type": "Control" }
  ```
- **Expected result**: Success response. Control has many enums: `GrowDirection` (BEGIN, END), `LayoutPreset`, `SizeFlags`, `AnchorLayout`, `CursorShape`, `LayoutMode`, `MouseFilter` (MOUSE_FILTER_STOP, MOUSE_FILTER_PASS, MOUSE_FILTER_IGNORE).
- **What to check**: The `MouseFilter` enum should contain three values. `LayoutPreset` should contain PRESET_FULL_RECT, PRESET_CENTER, etc.

#### Scenario 3: Get enums for a simple type (Node)

- **Params**:
  ```json
  { "type": "Node" }
  ```
- **Expected result**: Success response. `Node` has fewer enums — `ProcessMode` (INHERIT, PAUSABLE, WHEN_PAUSED, ALWAYS, DISABLED), `PhysicsInterpolationMode`.
- **What to check**: `ProcessMode` values should match Godot documentation. Verify `INHERIT = 0`.

#### Scenario 4: Get enums for RigidBody3D

- **Params**:
  ```json
  { "type": "RigidBody3D" }
  ```
- **Expected result**: Success response. Should include `Mode` (MODE_RIGID, MODE_STATIC, MODE_CHARACTER, MODE_KINEMATIC), `CenterOfMassMode`, `FreezeMode`, `CCDMode`.
- **What to check**: The `Mode` enum is key for RigidBody. Verify all 4 modes are present.

#### Scenario 5: Invalid type

- **Params**:
  ```json
  { "type": "NotARealType" }
  ```
- **Expected result**: Error response.

#### Scenario 6: Missing `type`

- **Params**:
  ```json
  {}
  ```
- **Expected result**: MCP validation error.

---

## Tool: `get_node_constants`

**Description**: Get all constants defined on a node type
**Backend route**: `node_config/get_constants`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `type` | `string` (NodeType) | ✅ Yes | Node type name |

### Test Scenarios

#### Scenario 1: Get constants for Node

- **Description**: Query constants for the base `Node` class.
- **Params**:
  ```json
  { "type": "Node" }
  ```
- **Expected result**: Success response. `Node` defines constants like `NOTIFICATION_ENTER_TREE`, `NOTIFICATION_EXIT_TREE`, `NOTIFICATION_READY`, `NOTIFICATION_PROCESS`, `NOTIFICATION_PHYSICS_PROCESS`, `NOTIFICATION_PARENTED`, `NOTIFICATION_UNPARENTED`.
- **Notes**: Constants are integer values. Each should have a name and numeric value.
- **What to check**: Notification constants usually start from 0 and go sequentially. Verify `NOTIFICATION_ENTER_TREE` is present.

#### Scenario 2: Get constants for Key (Input-related)

- **Params**:
  ```json
  { "type": "Key" }
  ```
- **Expected result**: Success response. `Key` has many constants: `KEY_SPACE`, `KEY_ESCAPE`, `KEY_ENTER`, `KEY_A` through `KEY_Z`, `KEY_0` through `KEY_9`, arrow keys, function keys, etc.
- **What to check**: `KEY_SPACE` is usually = 32. `KEY_ESCAPE` = 4194305. Verify at least 10+ keys are present.

#### Scenario 3: Get constants for a physics node

- **Params**:
  ```json
  { "type": "CollisionObject3D" }
  ```
- **Expected result**: Success response. May include constants for collision layers/masks.
- **What to check**: Verify the format — each constant should have a name and numeric value.

#### Scenario 4: Invalid type

- **Params**:
  ```json
  { "type": "ImaginaryClass" }
  ```
- **Expected result**: Error response.

#### Scenario 5: Missing `type`

- **Params**:
  ```json
  {}
  ```
- **Expected result**: MCP validation error.

---

## Tool: `get_class_hierarchy`

**Description**: Get the full inheritance chain for a node type
**Backend route**: `node_config/get_hierarchy`

### Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `type` | `string` (NodeType) | ✅ Yes | Node type name |

### Test Scenarios

#### Scenario 1: Get hierarchy for CharacterBody3D

- **Description**: Query the full inheritance chain for a deeply nested type.
- **Params**:
  ```json
  { "type": "CharacterBody3D" }
  ```
- **Expected result**: Success response. The hierarchy should be:
  ```
  CharacterBody3D → PhysicsBody3D → CollisionObject3D → Node3D → Node → Object
  ```
  (Exact list depends on Godot 4.x class structure.)
- **Notes**: The result should be an ordered list from most specific to most general (or vice versa — verify which direction is used).
- **What to check**: Verify the chain doesn't break at `Node3D` — it should reach `Object`. Ensure `PhysicsBody3D` and `CollisionObject3D` are both present.

#### Scenario 2: Get hierarchy for Button

- **Params**:
  ```json
  { "type": "Button" }
  ```
- **Expected result**: Success response. Expected hierarchy:
  ```
  Button → BaseButton → Control → CanvasItem → Node → Object
  ```
- **What to check**: `BaseButton` is a required intermediate link. `CanvasItem` is the common ancestor for all 2D and UI nodes. Verify that `Control` and `CanvasItem` are both present.

#### Scenario 3: Get hierarchy for Node (root of the hierarchy)

- **Params**:
  ```json
  { "type": "Node" }
  ```
- **Expected result**: Success response. Short hierarchy:
  ```
  Node → Object
  ```
- **What to check**: `Object` is the root of the entire Godot hierarchy. If it's missing — there's a problem.

#### Scenario 4: Get hierarchy for Object (absolute root)

- **Params**:
  ```json
  { "type": "Object" }
  ```
- **Expected result**: Success response. Hierarchy is just `Object` (no parent class).
- **What to check**: Verify the response is not empty and contains no errors. `Object` has no parent class.

#### Scenario 5: Get hierarchy for Sprite2D

- **Params**:
  ```json
  { "type": "Sprite2D" }
  ```
- **Expected result**: Success response. Expected hierarchy:
  ```
  Sprite2D → Node2D → CanvasItem → Node → Object
  ```
- **What to check**: `CanvasItem` is the common ancestor for 2D nodes and Control nodes. Verify `Node2D` is present between `Sprite2D` and `CanvasItem`.

#### Scenario 6: Get hierarchy for a 3D MeshInstance3D

- **Params**:
  ```json
  { "type": "MeshInstance3D" }
  ```
- **Expected result**: Success response. Expected hierarchy:
  ```
  MeshInstance3D → GeometryInstance3D → VisualInstance3D → Node3D → Node → Object
  ```
- **What to check**: Verify `VisualInstance3D` and `GeometryInstance3D` are both present. The chain is longer than for 2D nodes.

#### Scenario 7: Invalid type

- **Params**:
  ```json
  { "type": "GhostType" }
  ```
- **Expected result**: Error response.

#### Scenario 8: Missing `type`

- **Params**:
  ```json
  {}
  ```
- **Expected result**: MCP validation error.

---

## Cross-Tool Verification Scenarios

These scenarios test interactions between multiple tools to validate consistency.

### Scenario A: Type vs Path consistency for `get_node_signals`

1. `create_scene({ path: "res://test_scenes/signal_test.tscn", root_node_type: "Node2D" })`
2. `add_node({ parent_path: "", type: "Area2D", name: "MyArea" })`
3. `open_scene({ path: "res://test_scenes/signal_test.tscn" })`
4. Call `get_node_signals({ type: "Area2D" })` — record result
5. Call `get_node_signals({ path: "MyArea" })` — record result
6. **Assert**: Both results are identical (same set of signals with same signatures).

**What to check**: If results differ — it means `type` and `path` paths are processed differently, which may be a bug.

### Scenario B: Hierarchy includes types from other tools

1. Call `get_class_hierarchy({ type: "CharacterBody3D" })` — get chain
2. For each type in the chain, call `get_node_methods({ type: <type> })`
3. **Assert**: All calls succeed (every type in the hierarchy is a valid Godot class).
4. Call `get_node_enums({ type: <type> })` for each hierarchy type.
5. **Assert**: All calls succeed.

**What to check**: If any type from the hierarchy causes an error in `get_node_methods` — that's an inconsistency between the Godot API and the plugin.

### Scenario C: Preset applies to correct node type

1. `create_scene({ path: "res://test_scenes/preset_test.tscn", root_node_type: "Node2D" })`
2. `add_node({ parent_path: "", type: "CharacterBody3D", name: "Player" })`
3. `get_node_default_properties({ type: "CharacterBody3D" })` — record defaults
4. `set_node_preset({ type: "CharacterBody3D", preset: "platformer_body" })`
5. `get_node_properties({ path: "Player" })` — record after preset
6. **Assert**: Properties differ from defaults where the preset should modify them.

**What to check**: If properties didn't change — the preset doesn't work. If unrelated properties changed — the preset may have been applied incorrectly.

### Scenario D: Available types validation

1. Call `get_available_node_types({})` — get all types
2. Pick 10 random types from the list.
3. For each, call `get_class_hierarchy({ type: <type> })`.
4. **Assert**: All 10 calls succeed — every type in the available list is introspectable.

**What to check**: If a type from `get_available_node_types` doesn't work with other tools — there's a problem with type registration.

---

## Cleanup

After all tests:

```
delete_scene({ path: "res://test_scenes/node_config_test.tscn" })
delete_scene({ path: "res://test_scenes/signal_test.tscn" })
delete_scene({ path: "res://test_scenes/preset_test.tscn" })
```
