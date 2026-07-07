# Node Config Tools — Test Plan

> **Source file:** `server/src/tools/node_config.ts`  
> **Module purpose:** Node introspection tools — 8 tools for querying node type metadata  
> **Shared types used:** `NodeType` (`z.string()`), `NodePath` (`z.string()`)  
> **Godot bridge method prefix:** `node_config/`  
> **Generated:** 2026-07-08

---

## Tool: `get_node_default_properties`

**Description:** Get the default property values for a node type.  
**Handler:** `callGodot(bridge, 'node_config/get_defaults', args)`

### Parameters

| Parameter | Type   | Required | Description                                |
|-----------|--------|----------|--------------------------------------------|
| `type`    | string | ✅ Yes   | Node type name (e.g. `"Sprite2D"`, `"CharacterBody3D"`) |

### Test Scenarios

#### Scenario 1: Basic happy path — known 2D node type
- **Description:** Query default properties for a common 2D node type.
- **Params:** `{ "type": "Sprite2D" }`
- **Expected Result:** JSON object containing default property values for `Sprite2D` (e.g., `position`, `scale`, `rotation`, `visible`, `modulate`, `texture`, etc.). Must NOT be an error.
- **Notes:** `Sprite2D` exists in all Godot 4.x projects.

#### Scenario 2: Basic happy path — known 3D node type
- **Description:** Query default properties for a common 3D node type.
- **Params:** `{ "type": "CharacterBody3D" }`
- **Expected Result:** JSON object containing default properties for `CharacterBody3D` (e.g., `velocity`, `motion_mode`, `up_direction`, `floor_max_angle`, etc.).
- **Notes:** Verifies the bridge handles both 2D and 3D types.

#### Scenario 3: Base class
- **Description:** Query default properties for a base class (`Node`).
- **Params:** `{ "type": "Node" }`
- **Expected Result:** JSON object with default properties for `Node` (e.g., `name`, `process_mode`, `owner`).
- **Notes:** Root of the Godot class hierarchy. Should work.

#### Scenario 4: Case sensitivity — exact match required
- **Description:** Verify that node type names are case-sensitive.
- **Params:** `{ "type": "sprite2d" }`
- **Expected Result:** Error or empty result, since `"sprite2d"` is not a valid class name (must be `"Sprite2D"`).
- **Notes:** Godot class names are PascalCase and case-sensitive.

#### Scenario 5: Missing required parameter
- **Description:** Call without the `type` parameter.
- **Params:** `{}`
- **Expected Result:** Validation error from Zod: `type` is required.
- **Notes:** The MCP framework/Zod should reject this before it reaches Godot.

#### Scenario 6: Empty string type
- **Description:** Call with an empty string for `type`.
- **Params:** `{ "type": "" }`
- **Expected Result:** Error — empty string is not a valid Godot class name.
- **Notes:** Zod accepts any string (including empty); the Godot side should reject this.

#### Scenario 7: Non-existent node type
- **Description:** Call with a type that does not exist in Godot.
- **Params:** `{ "type": "NonExistentNodeXYZ" }`
- **Expected Result:** Error — class not found.
- **Notes:** The bridge should return an error, not crash.

#### Scenario 8: UI control type
- **Description:** Query default properties for a UI control.
- **Params:** `{ "type": "Button" }`
- **Expected Result:** JSON object with Button default properties (e.g., `text`, `flat`, `alignment`, `icon`).
- **Notes:** Validates that UI class hierarchy types work.

---

## Tool: `set_node_preset`

**Description:** Apply a configuration preset to a node (e.g. `"platformer_body"`, `"top_down_camera"`).  
**Handler:** `callGodot(bridge, 'node_config/set_preset', args)`

### Parameters

| Parameter | Type   | Required | Description                          |
|-----------|--------|----------|--------------------------------------|
| `type`    | string | ✅ Yes   | Node type to configure               |
| `preset`  | string | ✅ Yes   | Preset name to apply                 |

### Test Scenarios

#### Scenario 1: Basic happy path — platformer body preset
- **Description:** Apply `"platformer_body"` preset to `CharacterBody2D`.
- **Params:** `{ "type": "CharacterBody2D", "preset": "platformer_body" }`
- **Expected Result:** Success — preset applied to the node. Should modify properties like `motion_mode`, `floor_max_angle`, or add a default collision shape.
- **Notes:** Preset names are strings; exact valid set is defined in Godot plugin.

#### Scenario 2: Another valid preset — top_down_camera
- **Description:** Apply `"top_down_camera"` preset to `Camera2D`.
- **Params:** `{ "type": "Camera2D", "preset": "top_down_camera" }`
- **Expected Result:** Success — preset applied.
- **Notes:** Mentioned in the tool description as a valid example.

#### Scenario 3: Missing required parameter — `type`
- **Description:** Call without the `type` parameter.
- **Params:** `{ "preset": "platformer_body" }`
- **Expected Result:** Zod validation error: `type` is required.
- **Notes:** Both params are required; missing either should fail at schema level.

#### Scenario 4: Missing required parameter — `preset`
- **Description:** Call without the `preset` parameter.
- **Params:** `{ "type": "CharacterBody2D" }`
- **Expected Result:** Zod validation error: `preset` is required.
- **Notes:** —

#### Scenario 5: Invalid preset name
- **Description:** Call with a preset name that does not exist.
- **Params:** `{ "type": "CharacterBody2D", "preset": "nonexistent_preset_xyz" }`
- **Expected Result:** Error from Godot — preset not found or not applicable.
- **Notes:** The Godot plugin should return a meaningful error.

#### Scenario 6: Invalid type name
- **Description:** Call with a non-existent node type.
- **Params:** `{ "type": "FakeNode123", "preset": "platformer_body" }`
- **Expected Result:** Error — class `FakeNode123` not found.
- **Notes:** —

#### Scenario 7: Preset on incompatible type
- **Description:** Apply platformer preset to a 3D node type.
- **Params:** `{ "type": "Sprite3D", "preset": "platformer_body" }`
- **Expected Result:** May succeed or error depending on preset compatibility. Document actual behavior.
- **Notes:** Presets may be type-specific; the Godot plugin determines compatibility.

---

## Tool: `get_available_node_types`

**Description:** Get all available node types, optionally filtered by category.  
**Handler:** `callGodot(bridge, 'node_config/get_types', args)`

### Parameters

| Parameter  | Type   | Required | Description                                          | Valid Values                                 |
|------------|--------|----------|------------------------------------------------------|----------------------------------------------|
| `category` | string | ❌ No    | Filter by category (omit to get all node types)      | `"2d"`, `"3d"`, `"ui"`, `"audio"`, `"physics"`, `"navigation"` |

### Test Scenarios

#### Scenario 1: No category — all types
- **Description:** Get all available node types (no filter).
- **Params:** `{}`
- **Expected Result:** JSON array or object listing all Godot node type names. Should include `Node`, `Node2D`, `Sprite2D`, `Node3D`, `Control`, `Button`, etc.
- **Notes:** This is the most common usage.

#### Scenario 2: Category — `2d`
- **Description:** Filter node types by the `"2d"` category.
- **Params:** `{ "category": "2d" }`
- **Expected Result:** List of 2D node types only (e.g., `Node2D`, `Sprite2D`, `AnimatedSprite2D`, `CharacterBody2D`, `Area2D`, etc.). Should NOT include `Node3D` or `Control`.
- **Notes:** Valid enum value.

#### Scenario 3: Category — `3d`
- **Description:** Filter node types by the `"3d"` category.
- **Params:** `{ "category": "3d" }`
- **Expected Result:** List of 3D node types only (e.g., `Node3D`, `Sprite3D`, `CharacterBody3D`, `Area3D`, `MeshInstance3D`, etc.).
- **Notes:** Valid enum value.

#### Scenario 4: Category — `ui`
- **Description:** Filter node types by the `"ui"` category.
- **Params:** `{ "category": "ui" }`
- **Expected Result:** List of UI node types only (e.g., `Control`, `Button`, `Label`, `Panel`, `HBoxContainer`, etc.).
- **Notes:** Valid enum value.

#### Scenario 5: Category — `audio`
- **Description:** Filter node types by the `"audio"` category.
- **Params:** `{ "category": "audio" }`
- **Expected Result:** List of audio node types only (e.g., `AudioStreamPlayer`, `AudioStreamPlayer2D`, `AudioStreamPlayer3D`, `AudioBusLayout`, etc.).
- **Notes:** Valid enum value.

#### Scenario 6: Category — `physics`
- **Description:** Filter node types by the `"physics"` category.
- **Params:** `{ "category": "physics" }`
- **Expected Result:** List of physics node types only (e.g., `RigidBody2D`, `CharacterBody2D`, `StaticBody3D`, `CollisionShape2D`, etc.).
- **Notes:** Valid enum value.

#### Scenario 7: Category — `navigation`
- **Description:** Filter node types by the `"navigation"` category.
- **Params:** `{ "category": "navigation" }`
- **Expected Result:** List of navigation node types only (e.g., `NavigationRegion2D`, `NavigationAgent3D`, `NavigationLink2D`, etc.).
- **Notes:** Valid enum value. Covers all 6 enum members.

#### Scenario 8: Invalid category value
- **Description:** Call with a category not in the enum.
- **Params:** `{ "category": "invalid_category" }`
- **Expected Result:** Zod validation error — `category` must be one of `"2d"`, `"3d"`, `"ui"`, `"audio"`, `"physics"`, `"navigation"`.
- **Notes:** The enum constraint is enforced by Zod before reaching Godot.

#### Scenario 9: Uppercase category
- **Description:** Call with an uppercase category value.
- **Params:** `{ "category": "2D" }`
- **Expected Result:** Zod validation error — `"2D"` is not in the enum (values are lowercase `"2d"`, `"3d"`, etc.).
- **Notes:** Zod enum matching is case-sensitive.

#### Scenario 10: Category as empty string
- **Description:** Call with an empty string for category.
- **Params:** `{ "category": "" }`
- **Expected Result:** Zod validation error — `""` is not in the enum.
- **Notes:** Empty string is not a valid enum member.

---

## Tool: `get_node_signals`

**Description:** Get all signals defined on a node type with their argument signatures. Provide either `type` (a class name like `"CharacterBody3D"`) or `path` (a node instance path like `"Player"` — the class will be resolved automatically).  
**Handler:** `callGodot(bridge, 'node_config/get_signals', args)`

### Parameters

| Parameter | Type   | Required | Description                                                                          |
|-----------|--------|----------|--------------------------------------------------------------------------------------|
| `type`    | string | ❌ No\*  | Node type name (e.g. `"CharacterBody3D"`). Provide this **OR** `path`.               |
| `path`    | string | ❌ No\*  | Node instance path in the scene (e.g. `"Player"`). The node's class type will be resolved automatically. Provide this **OR** `type`. |

> \* Either `type` or `path` must be provided. If both are omitted, the tool should return an error. Providing both is allowed but `type` likely takes precedence.

### Test Scenarios

#### Scenario 1: Happy path — by `type` (class name)
- **Description:** Query signals for `Button` by class name.
- **Params:** `{ "type": "Button" }`
- **Expected Result:** JSON object listing Button signals with argument signatures. Should include `pressed()`, `toggled(toggled_on: bool)`, `button_down()`, `button_up()`.
- **Notes:** Most common usage. Requires no open scene.

#### Scenario 2: Happy path — by `type` (3D class)
- **Description:** Query signals for `CharacterBody3D` by class name.
- **Params:** `{ "type": "CharacterBody3D" }`
- **Expected Result:** JSON object listing signals. Should include `floor_stop()`, `motion_state_changed()`, etc.
- **Notes:** 3D classes should work identically to 2D classes.

#### Scenario 3: Happy path — by `path` (scene node)
- **Description:** Query signals for a node in the current scene by its path.
- **Params:** `{ "path": "Player" }`
- **Expected Result:** JSON object listing signals for the script/class attached to the `Player` node in the current scene. If `Player` exists and has a script attached to `CharacterBody3D`, should return that class's signals.
- **Notes:** Requires an open scene with a `Player` node at the root level.

#### Scenario 4: Happy path — by `path` (nested node)
- **Description:** Query signals for a nested node using a path.
- **Params:** `{ "path": "Player/Sprite2D" }`
- **Expected Result:** JSON object listing signals for `Sprite2D` (the resolved class of the child node).
- **Notes:** Path resolution should handle `/` separators.

#### Scenario 5: Edge case — both `type` and `path` provided
- **Description:** Provide both parameters simultaneously.
- **Params:** `{ "type": "Button", "path": "Player" }`
- **Expected Result:** Should succeed; `type` likely takes precedence and returns Button signals.
- **Notes:** Behavior depends on Godot plugin implementation. Document actual result.

#### Scenario 6: Edge case — neither parameter provided
- **Description:** Call with no parameters at all.
- **Params:** `{}`
- **Expected Result:** Error — must provide either `type` or `path`.
- **Notes:** Both are optional in the schema, but the handler should reject empty calls.

#### Scenario 7: Edge case — empty string for `type`
- **Description:** Call with an empty string for `type`.
- **Params:** `{ "type": "" }`
- **Expected Result:** Error — empty string is not a valid class name.
- **Notes:** —

#### Scenario 8: Edge case — empty string for `path`
- **Description:** Call with an empty string for `path`.
- **Params:** `{ "path": "" }`
- **Expected Result:** May resolve to the scene root node (`""` is valid per `NodePath` description) and return its class signals. Document actual behavior.
- **Notes:** The `NodePath` schema says `""` means "the scene root itself."

#### Scenario 9: Edge case — non-existent node type
- **Description:** Call with a type that does not exist.
- **Params:** `{ "type": "NonExistentTypeXYZ" }`
- **Expected Result:** Error — class not found.
- **Notes:** —

#### Scenario 10: Edge case — non-existent node path
- **Description:** Call with a path to a node that does not exist.
- **Params:** `{ "path": "NonExistentNode123" }`
- **Expected Result:** Error — node not found in scene.
- **Notes:** Requires no node with that name in the current scene.

#### Scenario 11: Edge case — `type` not a string
- **Description:** Call with a non-string value for `type`.
- **Params:** `{ "type": 123 }`
- **Expected Result:** Zod validation error — expected string, received number.
- **Notes:** —

#### Scenario 12: Edge case — `path` not a string
- **Description:** Call with a non-string value for `path`.
- **Params:** `{ "path": [] }`
- **Expected Result:** Zod validation error — expected string, received array.
- **Notes:** —

---

## Tool: `get_node_methods`

**Description:** Get all public methods on a node type with their signatures.  
**Handler:** `callGodot(bridge, 'node_config/get_methods', args)`

### Parameters

| Parameter | Type   | Required | Description                                |
|-----------|--------|----------|--------------------------------------------|
| `type`    | string | ✅ Yes   | Node type name (e.g. `"Sprite2D"`, `"CharacterBody3D"`) |

### Test Scenarios

#### Scenario 1: Basic happy path — 2D node type
- **Description:** Get methods for `Sprite2D`.
- **Params:** `{ "type": "Sprite2D" }`
- **Expected Result:** JSON list of public methods with signatures. Should include `get_rect()`, `is_pixel_opaque()`, `set_texture()`, `get_texture()`, inherited methods from `Node2D`, `CanvasItem`, `Node`.
- **Notes:** —

#### Scenario 2: UI control type
- **Description:** Get methods for `Button`.
- **Params:** `{ "type": "Button" }`
- **Expected Result:** JSON list including `set_text()`, `get_text()`, `set_icon()`, `get_icon()`, etc.
- **Notes:** —

#### Scenario 3: 3D node type
- **Description:** Get methods for `MeshInstance3D`.
- **Params:** `{ "type": "MeshInstance3D" }`
- **Expected Result:** JSON list including `set_mesh()`, `get_mesh()`, `get_aabb()`, etc.
- **Notes:** —

#### Scenario 4: Missing required parameter
- **Description:** Call without `type`.
- **Params:** `{}`
- **Expected Result:** Zod validation error: `type` is required.
- **Notes:** —

#### Scenario 5: Invalid type
- **Description:** Call with a non-existent node type.
- **Params:** `{ "type": "FakeClassABC" }`
- **Expected Result:** Error — class not found.
- **Notes:** —

#### Scenario 6: Empty string type
- **Description:** Call with an empty string.
- **Params:** `{ "type": "" }`
- **Expected Result:** Error — empty string is not a valid class name.
- **Notes:** Zod accepts it; Godot should reject.

---

## Tool: `get_node_enums`

**Description:** Get all enumerations defined on a node type.  
**Handler:** `callGodot(bridge, 'node_config/get_enums', args)`

### Parameters

| Parameter | Type   | Required | Description                                |
|-----------|--------|----------|--------------------------------------------|
| `type`    | string | ✅ Yes   | Node type name (e.g. `"Sprite2D"`, `"CharacterBody3D"`) |

### Test Scenarios

#### Scenario 1: Basic happy path — type with known enums
- **Description:** Get enums for `BaseButton` (has `DrawMode` enum).
- **Params:** `{ "type": "BaseButton" }`
- **Expected Result:** JSON object listing enum names and their values. Should include `DrawMode` with values like `DRAW_NORMAL`, `DRAW_PRESSED`, `DRAW_HOVER`, etc.
- **Notes:** `BaseButton` has a well-known enum.

#### Scenario 2: Type with many enums
- **Description:** Get enums for `Node` (many global enums are inherited).
- **Params:** `{ "type": "Node" }`
- **Expected Result:** JSON object including enums like `ProcessMode` (`PROCESS_MODE_INHERIT`, `PROCESS_MODE_PAUSABLE`, etc.).
- **Notes:** —

#### Scenario 3: Type with no class-specific enums
- **Description:** Get enums for a simple type that may not define its own enums but inherits them.
- **Params:** `{ "type": "Sprite2D" }`
- **Expected Result:** JSON object that may include inherited enums. Should not error.
- **Notes:** Even if no own enums, inherited ones may still be returned or an empty list is acceptable.

#### Scenario 4: Missing required parameter
- **Description:** Call without `type`.
- **Params:** `{}`
- **Expected Result:** Zod validation error: `type` is required.
- **Notes:** —

#### Scenario 5: Invalid type
- **Description:** Non-existent node type.
- **Params:** `{ "type": "InvalidEnumType999" }`
- **Expected Result:** Error — class not found.
- **Notes:** —

---

## Tool: `get_node_constants`

**Description:** Get all constants defined on a node type.  
**Handler:** `callGodot(bridge, 'node_config/get_constants', args)`

### Parameters

| Parameter | Type   | Required | Description                                |
|-----------|--------|----------|--------------------------------------------|
| `type`    | string | ✅ Yes   | Node type name (e.g. `"Sprite2D"`, `"CharacterBody3D"`) |

### Test Scenarios

#### Scenario 1: Basic happy path — type with constants
- **Description:** Get constants for a type known to have class constants.
- **Params:** `{ "type": "Input" }`
- **Expected Result:** JSON object with constants like `MOUSE_BUTTON_LEFT`, `MOUSE_BUTTON_RIGHT`, `KEY_A`, `KEY_ENTER`, etc.
- **Notes:** `Input` has many well-known constants.

#### Scenario 2: Type with fewer constants
- **Description:** Get constants for `Button`.
- **Params:** `{ "type": "Button" }`
- **Expected Result:** JSON object with Button-specific constants (may include alignment constants, etc.). Should not error.
- **Notes:** —

#### Scenario 3: Missing required parameter
- **Description:** Call without `type`.
- **Params:** `{}`
- **Expected Result:** Zod validation error: `type` is required.
- **Notes:** —

#### Scenario 4: Invalid type
- **Description:** Non-existent node type.
- **Params:** `{ "type": "ConstFakeType000" }`
- **Expected Result:** Error — class not found.
- **Notes:** —

---

## Tool: `get_class_hierarchy`

**Description:** Get the full inheritance chain for a node type.  
**Handler:** `callGodot(bridge, 'node_config/get_hierarchy', args)`

### Parameters

| Parameter | Type   | Required | Description                                |
|-----------|--------|----------|--------------------------------------------|
| `type`    | string | ✅ Yes   | Node type name (e.g. `"Sprite2D"`, `"CharacterBody3D"`) |

### Test Scenarios

#### Scenario 1: Basic happy path — deep hierarchy
- **Description:** Get the inheritance chain for `Button`.
- **Params:** `{ "type": "Button" }`
- **Expected Result:** JSON array or ordered list showing: `Button` → `BaseButton` → `Control` → `CanvasItem` → `Node` → `Object`.
- **Notes:** The hierarchy should go from the type up to `Object`.

#### Scenario 2: Shallow hierarchy
- **Description:** Get the inheritance chain for `Node` (root of scene tree classes).
- **Params:** `{ "type": "Node" }`
- **Expected Result:** `Node` → `Object` (very short hierarchy).
- **Notes:** `Node` is just below `Object`.

#### Scenario 3: 3D type hierarchy
- **Description:** Get the inheritance chain for `CharacterBody3D`.
- **Params:** `{ "type": "CharacterBody3D" }`
- **Expected Result:** `CharacterBody3D` → `PhysicsBody3D` → `CollisionObject3D` → `Node3D` → `Node` → `Object`.
- **Notes:** Verifies 3D class hierarchy.

#### Scenario 4: Resource class (not a node)
- **Description:** Get the inheritance chain for a non-Node class like `Material`.
- **Params:** `{ "type": "Material" }`
- **Expected Result:** `Material` → `Resource` → `RefCounted` → `Object`.
- **Notes:** Should work for any Godot class, not just nodes.

#### Scenario 5: Missing required parameter
- **Description:** Call without `type`.
- **Params:** `{}`
- **Expected Result:** Zod validation error: `type` is required.
- **Notes:** —

#### Scenario 6: Invalid type
- **Description:** Non-existent class name.
- **Params:** `{ "type": "HierarchyFakeXYZ" }`
- **Expected Result:** Error — class not found.
- **Notes:** —

#### Scenario 7: Base class `Object`
- **Description:** Get the hierarchy for `Object` (root of everything).
- **Params:** `{ "type": "Object" }`
- **Expected Result:** `Object` alone (or `Object` with no parent). Should not error.
- **Notes:** `Object` has no parent class in Godot.

---

## Cross-Tool Consistency Checks

These are tests to run across tools to verify consistent behavior.

### Consistency 1: All `type`-only tools handle missing `type` identically
- **Tools:** `get_node_default_properties`, `get_node_methods`, `get_node_enums`, `get_node_constants`, `get_class_hierarchy`
- **Call each with:** `{}`
- **Expected:** All five return a Zod validation error that `type` is required. Error format should be consistent.

### Consistency 2: All `type`-only tools reject same invalid type
- **Tools:** `get_node_default_properties`, `get_node_methods`, `get_node_enums`, `get_node_constants`, `get_class_hierarchy`
- **Call each with:** `{ "type": "NonExistent12345" }`
- **Expected:** All five return an error indicating the class was not found. Error format should be consistent.

### Consistency 3: `get_node_signals` via `type` returns same data as `get_node_signals` via `path`
- **Setup:** Open a scene with a node named `"Player"` whose script extends `CharacterBody2D`.
- **Call 1:** `{ "type": "CharacterBody2D" }`
- **Call 2:** `{ "path": "Player" }`
- **Expected:** Both calls return the same signal list (assuming the `Player` node's class is `CharacterBody2D`).

### Consistency 4: `get_node_default_properties` + `get_node_methods` + `get_node_signals` + `get_node_enums` + `get_node_constants` + `get_class_hierarchy` all work for same type
- **Type:** `"Timer"`
- **Call all six tools with `{ "type": "Timer" }`**
- **Expected:** All six return valid results without errors. `Timer` has properties (`wait_time`, `one_shot`, `autostart`), methods (`start()`, `stop()`), signals (`timeout()`), and a hierarchy (`Timer` → `Node` → `Object`).

### Consistency 5: `get_available_node_types` categories return disjoint or properly scoped sets
- **Call each category** (`"2d"`, `"3d"`, `"ui"`, `"audio"`, `"physics"`, `"navigation"`) **and also no-category.**
- **Expected:** The union of all category results should be a subset of the no-category result. Categories should not overlap (or overlap minimally — some types like `Node` may appear in multiple categories).

---

## Summary Matrix

| Tool                      | `type` req | Other params                     | Godot method              |
|---------------------------|------------|----------------------------------|---------------------------|
| `get_node_default_properties` | ✅ required | —                            | `node_config/get_defaults` |
| `set_node_preset`         | ✅ required | `preset` (required)              | `node_config/set_preset`  |
| `get_available_node_types` | —          | `category` (optional, enum)      | `node_config/get_types`   |
| `get_node_signals`        | optional   | `path` (optional) — one required | `node_config/get_signals` |
| `get_node_methods`        | ✅ required | —                              | `node_config/get_methods` |
| `get_node_enums`          | ✅ required | —                              | `node_config/get_enums`   |
| `get_node_constants`      | ✅ required | —                              | `node_config/get_constants` |
| `get_class_hierarchy`     | ✅ required | —                              | `node_config/get_hierarchy` |
