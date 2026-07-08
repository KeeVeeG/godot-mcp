# Test Plan: Node Config Tools

**Source file:** `server/src/tools/node_config.ts`  
**Shared schemas:** `server/src/tools/shared-types.ts`  
**Tools in module:** 8  
**Date generated:** 2026-07-08

---

## Overview

All tools in this module use `callGodot(bridge, 'node_config/<endpoint>', args)` to forward requests to the Godot editor plugin. Zod validation of input schemas happens before the handler is invoked (handled by the MCP SDK). Handler errors surface via `callGodot` catch block as `{ content: [{ type: 'text', text: 'Godot request failed: <message>' }], isError: true }`.

The following Zod schemas from `shared-types.ts` are used:

- **`NodeType`**: `z.string().describe("Node type name (e.g. 'Sprite2D', 'CharacterBody3D')")` — required string
- **`NodePath`**: `z.string().describe("Node path in the scene tree...")` — required string

### Godot Bridge Endpoints

| Tool | Endpoint |
|---|---|
| `get_node_default_properties` | `node_config/get_defaults` |
| `set_node_preset` | `node_config/set_preset` |
| `get_available_node_types` | `node_config/get_types` |
| `get_node_signals` | `node_config/get_signals` |
| `get_node_methods` | `node_config/get_methods` |
| `get_node_enums` | `node_config/get_enums` |
| `get_node_constants` | `node_config/get_constants` |
| `get_class_hierarchy` | `node_config/get_hierarchy` |

### General Notes

- All tools require a running Godot editor with the MCP plugin connected. If the bridge is disconnected, every tool will fail with a connection error (`"Godot request failed: ..."`).
- Zod schema validation occurs at the MCP SDK level before reaching the handler. Malformed arguments (wrong types, missing required params) result in a client-side validation error _before_ the bridge call.
- `callGodot` wraps all responses as `{ content: [{ type: 'text', text: <json-string-or-message> }] }`.
- Godot-side errors (e.g., unknown node type, missing scene) are returned as error response objects from the Godot plugin — these are stringified JSON and passed through by `callGodot`.

---

## Tool: get_node_default_properties

**Description:** Get the default property values for a node type.  
**Godot endpoint:** `node_config/get_defaults`

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `type` | string (`NodeType`) | **Yes** | Node type name (e.g. `'Sprite2D'`, `'CharacterBody3D'`) |

### Test Scenarios

#### Scenario 1: Basic happy path — valid built-in node type
- **Description:** Query defaults for a common 2D node type.
- **Params:** `{ "type": "Sprite2D" }`
- **Expected result:** Success. Returns a JSON object with default property names and values for `Sprite2D` (e.g., `position: Vector2(0,0)`, `visible: true`, `modulate: Color(1,1,1,1)`).
- **Notes:** Total property count should be > 5.

#### Scenario 2: Basic happy path — valid 3D node type
- **Description:** Query defaults for a common 3D node type.
- **Params:** `{ "type": "CharacterBody3D" }`
- **Expected result:** Success. Returns default properties for `CharacterBody3D` (e.g., `collision_layer: 1`, `collision_mask: 1`, `motion_mode: 0`).
- **Notes:** 3D nodes should differ from 2D in property set.

#### Scenario 3: Basic happy path — UI node type
- **Description:** Query defaults for a UI control node.
- **Params:** `{ "type": "Button" }`
- **Expected result:** Success. Returns default properties for `Button`.
- **Notes:** UI nodes have `anchor_*`, `theme_*`, and `size_flags_*` properties.

#### Scenario 4: Edge case — custom script class name
- **Description:** Query defaults for a user-defined script class (if one is registered in the project).
- **Params:** `{ "type": "Player" }`
- **Expected result:** If `Player` is a registered global class in the project → success with defaults. If not → Godot-side error returned.
- **Notes:** Depends on project context. In an empty project, this will be a Godot error.

#### Scenario 5: Edge case — invalid/non-existent node type
- **Description:** Query defaults for a type that does not exist.
- **Params:** `{ "type": "NonExistentNodeXYZ" }`
- **Expected result:** Error from Godot. The response `isError` will be `true` or the Godot result will contain an error indicator.
- **Notes:** Should not silently return empty data.

#### Scenario 6: Edge case — empty string type
- **Description:** Pass an empty string as node type.
- **Params:** `{ "type": "" }`
- **Expected result:** Error. Either Godot rejects the empty type, or returns defaults for an unknown/root type.
- **Notes:** Zod passes empty strings through (non-empty string is not enforced).

#### Scenario 7: Missing required parameter — omit `type`
- **Description:** Call without the required `type` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error at MCP SDK level. Call does not reach handler.
- **Notes:** The MCP client receives a schema validation error.

#### Scenario 8: Wrong type — number instead of string
- **Description:** Pass a number as `type`.
- **Params:** `{ "type": 42 }`
- **Expected result:** Zod validation error at MCP SDK level. Call does not reach handler.
- **Notes:**

#### Scenario 9: Special characters in type name
- **Description:** Pass a type name with special characters.
- **Params:** `{ "type": "Sprite2D@#$%" }`
- **Expected result:** Godot-side error (no such type).
- **Notes:** Zod string schema doesn't restrict characters.

---

## Tool: set_node_preset

**Description:** Apply a configuration preset to a node (e.g. `'platformer_body'`, `'top_down_camera'`).  
**Godot endpoint:** `node_config/set_preset`

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `type` | string (`NodeType`) | **Yes** | Node type to configure |
| `preset` | string | **Yes** | Preset name to apply |

### Test Scenarios

#### Scenario 1: Basic happy path — valid type and known preset
- **Description:** Apply a preset to a node type known to have presets.
- **Params:** `{ "type": "CharacterBody2D", "preset": "platformer_body" }`
- **Expected result:** Success. The Godot response should indicate the preset was applied (the exact format depends on the plugin).
- **Notes:** `platformer_body` and `top_down_camera` are mentioned in the tool description.

#### Scenario 2: Preset variant — `top_down_camera`
- **Description:** Apply the `top_down_camera` preset.
- **Params:** `{ "type": "Camera3D", "preset": "top_down_camera" }`
- **Expected result:** Success or a Godot-side error if the preset is not applicable to `Camera3D`.
- **Notes:** The example in the tool description mentions `'top_down_camera'`.

#### Scenario 3: Edge case — unrecognized preset name
- **Description:** Apply a preset name that does not exist.
- **Params:** `{ "type": "CharacterBody2D", "preset": "nonexistent_preset_xyz" }`
- **Expected result:** Godot-side error indicating the preset is unknown or unsupported.
- **Notes:**

#### Scenario 4: Edge case — empty preset string
- **Description:** Pass an empty string as the preset name.
- **Params:** `{ "type": "CharacterBody2D", "preset": "" }`
- **Expected result:** Godot-side error (no preset with empty name), or error saying preset not found.
- **Notes:**

#### Scenario 5: Edge case — invalid node type
- **Description:** Pass a non-existent node type with a valid preset name.
- **Params:** `{ "type": "InvalidNodeXYZ", "preset": "platformer_body" }`
- **Expected result:** Godot-side error (invalid type).
- **Notes:**

#### Scenario 6: Missing required parameter — omit `type`
- **Description:** Call without the `type` parameter.
- **Params:** `{ "preset": "platformer_body" }`
- **Expected result:** Zod validation error at MCP SDK level.
- **Notes:**

#### Scenario 7: Missing required parameter — omit `preset`
- **Description:** Call without the `preset` parameter.
- **Params:** `{ "type": "CharacterBody2D" }`
- **Expected result:** Zod validation error at MCP SDK level.
- **Notes:**

#### Scenario 8: Both parameters missing
- **Description:** Call with no parameters.
- **Params:** `{}`
- **Expected result:** Zod validation error at MCP SDK level.
- **Notes:**

#### Scenario 9: Numeric preset
- **Description:** Pass a number as the preset name.
- **Params:** `{ "type": "CharacterBody2D", "preset": 123 }`
- **Expected result:** Zod validation error at MCP SDK level.
- **Notes:** `z.string()` rejects numbers.

---

## Tool: get_available_node_types

**Description:** Get all available node types, optionally filtered by category.  
**Godot endpoint:** `node_config/get_types`

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `category` | enum (`'2d'` \| `'3d'` \| `'ui'` \| `'audio'` \| `'physics'` \| `'navigation'`) | No (optional) | Filter by category |

### Test Scenarios

#### Scenario 1: Basic happy path — no filter (all types)
- **Description:** Get all available node types without any category filter.
- **Params:** `{}`
- **Expected result:** Success. Returns a comprehensive list of all node types available in the engine.
- **Notes:** Total count should be large (100+).

#### Scenario 2: Category filter — `'2d'`
- **Description:** Get only 2D node types.
- **Params:** `{ "category": "2d" }`
- **Expected result:** Success. Returns types like `Node2D`, `Sprite2D`, `Area2D`, `CharacterBody2D`, `TileMap`, etc.
- **Notes:** All returned types should be 2D-related. Should not include `Sprite3D` etc.

#### Scenario 3: Category filter — `'3d'`
- **Description:** Get only 3D node types.
- **Params:** `{ "category": "3d" }`
- **Expected result:** Success. Returns types like `Node3D`, `Sprite3D`, `Area3D`, `CharacterBody3D`, `MeshInstance3D`, etc.
- **Notes:**

#### Scenario 4: Category filter — `'ui'`
- **Description:** Get only UI/Control node types.
- **Params:** `{ "category": "ui" }`
- **Expected result:** Success. Returns types like `Control`, `Button`, `Label`, `Panel`, `VBoxContainer`, etc.
- **Notes:**

#### Scenario 5: Category filter — `'audio'`
- **Description:** Get only audio node types.
- **Params:** `{ "category": "audio" }`
- **Expected result:** Success. Returns types like `AudioStreamPlayer`, `AudioStreamPlayer2D`, `AudioStreamPlayer3D`, `AudioBusLayout`, etc.
- **Notes:**

#### Scenario 6: Category filter — `'physics'`
- **Description:** Get only physics node types.
- **Params:** `{ "category": "physics" }`
- **Expected result:** Success. Returns types like `RigidBody2D`, `RigidBody3D`, `StaticBody2D`, `CharacterBody2D`, `Area2D`, etc.
- **Notes:**

#### Scenario 7: Category filter — `'navigation'`
- **Description:** Get only navigation node types.
- **Params:** `{ "category": "navigation" }`
- **Expected result:** Success. Returns types like `NavigationRegion2D`, `NavigationRegion3D`, `NavigationAgent2D`, `NavigationAgent3D`, etc.
- **Notes:**

#### Scenario 8: Edge case — invalid category string
- **Description:** Pass a string that is not in the enum.
- **Params:** `{ "category": "nonexistent" }`
- **Expected result:** Zod validation error at MCP SDK level (not a valid enum value).
- **Notes:** `z.enum(['2d', '3d', 'ui', 'audio', 'physics', 'navigation'])` rejects invalid values.

#### Scenario 9: Edge case — empty string category
- **Description:** Pass empty string as category.
- **Params:** `{ "category": "" }`
- **Expected result:** Zod validation error at MCP SDK level.
- **Notes:**

#### Scenario 10: Edge case — uppercase category
- **Description:** Pass category in uppercase.
- **Params:** `{ "category": "2D" }`
- **Expected result:** Zod validation error at MCP SDK level (enum is case-sensitive; `'2D'` is not in the enum).
- **Notes:**

#### Scenario 11: Edge case — number instead of string
- **Description:** Pass a number as the category.
- **Params:** `{ "category": 2 }`
- **Expected result:** Zod validation error at MCP SDK level.
- **Notes:**

---

## Tool: get_node_signals

**Description:** Get all signals defined on a node type with their argument signatures. Provide either `"type"` or `"path"`.  
**Godot endpoint:** `node_config/get_signals`

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `type` | string (`NodeType`) | No (optional) | Node type name (e.g. `"CharacterBody3D"`). Provide this OR `"path"`. |
| `path` | string (`NodePath`) | No (optional) | Node instance path in the scene (e.g. `"Player"`). The node's class type will be resolved automatically. Provide this OR `"type"`. |

### Test Scenarios

#### Scenario 1: Basic happy path — by `type`
- **Description:** Get signals for a type by class name.
- **Params:** `{ "type": "Button" }`
- **Expected result:** Success. Returns signals like `pressed()`, `toggled(toggled_on: bool)`, `button_down()`, `button_up()`.
- **Notes:**

#### Scenario 2: Basic happy path — by `type` (3D node)
- **Description:** Get signals for a CharacterBody3D.
- **Params:** `{ "type": "CharacterBody3D" }`
- **Expected result:** Success. Returns signals like `velocity_computed(safe_velocity: Vector3)`.
- **Notes:**

#### Scenario 3: Basic happy path — by `path` (node in current scene)
- **Description:** Get signals by resolving a node path in the currently open scene.
- **Params:** `{ "path": "Player" }`
- **Expected result:** Depends on current scene. If a node named `Player` exists → success with its signals. If no node at path → Godot-side error.
- **Notes:** Requires a scene to be open with the named node.

#### Scenario 4: Edge case — neither `type` nor `path` provided
- **Description:** Call with no parameters.
- **Params:** `{}`
- **Expected result:** Since both are `.optional()`, Zod passes this through to the handler. Godot should return an error because no target was specified.
- **Notes:** The handler should validate that at least one of `type`/`path` is provided, but this validation is not in the Zod schema.

#### Scenario 5: Edge case — both `type` and `path` provided
- **Description:** Provide both parameters.
- **Params:** `{ "type": "Button", "path": "Player" }`
- **Expected result:** Godot-side behavior is undefined — may prefer one over the other, or error. Test to document actual behavior.
- **Notes:** The description says "Provide this OR 'path'" implying mutual exclusivity.

#### Scenario 6: Edge case — empty string for `type`
- **Description:** Provide empty string as `type` with no `path`.
- **Params:** `{ "type": "" }`
- **Expected result:** Godot-side error (no type with empty name).
- **Notes:**

#### Scenario 7: Edge case — empty string for `path`
- **Description:** Provide empty string as `path` with no `type`.
- **Params:** `{ "path": "" }`
- **Expected result:** Godot-side behavior: `""` represents the scene root node. Should return signals for the root node type (e.g., `Node2D`).
- **Notes:** Per the `NodePath` schema description, `""` means the scene root.

#### Scenario 8: Edge case — invalid type name
- **Description:** Provide a non-existent type name.
- **Params:** `{ "type": "FakeNodeXYZ" }`
- **Expected result:** Godot-side error.
- **Notes:**

#### Scenario 9: Edge case — path to non-existent node
- **Description:** Provide a path that does not exist in the current scene.
- **Params:** `{ "path": "NonExistentNode/Child123" }`
- **Expected result:** Godot-side error (node not found).
- **Notes:**

#### Scenario 10: Wrong type — number for `type` or `path`
- **Description:** Pass a number instead of string.
- **Params:** `{ "type": 123 }`
- **Expected result:** Zod validation error at MCP SDK level.
- **Notes:**

---

## Tool: get_node_methods

**Description:** Get all public methods on a node type with their signatures.  
**Godot endpoint:** `node_config/get_methods`

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `type` | string (`NodeType`) | **Yes** | Node type name (e.g. `'Sprite2D'`, `'CharacterBody3D'`) |

### Test Scenarios

#### Scenario 1: Basic happy path — valid 2D node type
- **Description:** Get methods for a Sprite2D.
- **Params:** `{ "type": "Sprite2D" }`
- **Expected result:** Success. Returns method signatures like `set_texture(texture: Texture2D)`, `get_rect() -> Rect2`, `is_pixel_opaque(pos: Vector2) -> bool`.
- **Notes:** Total method count should be > 10 (includes inherited methods).

#### Scenario 2: Basic happy path — valid 3D node type
- **Description:** Get methods for a CharacterBody3D.
- **Params:** `{ "type": "CharacterBody3D" }`
- **Expected result:** Success. Returns method signatures like `move_and_slide() -> bool`, `get_floor_normal() -> Vector3`.
- **Notes:**

#### Scenario 3: Basic happy path — UI node type
- **Description:** Get methods for a Button.
- **Params:** `{ "type": "Button" }`
- **Expected result:** Success. Returns method signatures including inherited Control and Object methods.
- **Notes:**

#### Scenario 4: Basic happy path — base type `Node`
- **Description:** Get methods for the most fundamental type.
- **Params:** `{ "type": "Node" }`
- **Expected result:** Success. Returns core Node methods like `add_child()`, `remove_child()`, `get_child()`, `queue_free()`, etc.
- **Notes:**

#### Scenario 5: Edge case — invalid node type
- **Description:** Query methods for a type that does not exist.
- **Params:** `{ "type": "TotallyFakeTypeXYZ" }`
- **Expected result:** Godot-side error.
- **Notes:**

#### Scenario 6: Missing required parameter — omit `type`
- **Description:** Call without the `type` parameter.
- **Params:** `{}`
- **Expected result:** Zod validation error at MCP SDK level.
- **Notes:**

#### Scenario 7: Wrong type — number
- **Description:** Pass a number as `type`.
- **Params:** `{ "type": 42 }`
- **Expected result:** Zod validation error at MCP SDK level.
- **Notes:**

#### Scenario 8: Edge case — empty string
- **Description:** Pass an empty string.
- **Params:** `{ "type": "" }`
- **Expected result:** Godot-side error (no type with empty name).
- **Notes:** Zod passes empty strings.

---

## Tool: get_node_enums

**Description:** Get all enumerations defined on a node type.  
**Godot endpoint:** `node_config/get_enums`

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `type` | string (`NodeType`) | **Yes** | Node type name (e.g. `'Sprite2D'`, `'CharacterBody3D'`) |

### Test Scenarios

#### Scenario 1: Basic happy path — type with known enums
- **Description:** Get enums for a type that typically has enums (e.g., AnimationPlayer).
- **Params:** `{ "type": "AnimationPlayer" }`
- **Expected result:** Success. Returns enums like `AnimationProcessCallback`, `AnimationMethodCallMode`, etc. with their key-value pairs.
- **Notes:**

#### Scenario 2: Basic happy path — BoxContainer (has alignment enum)
- **Description:** Get enums for BoxContainer.
- **Params:** `{ "type": "BoxContainer" }`
- **Expected result:** Success. Returns enums including `AlignmentMode` (`ALIGNMENT_BEGIN`, `ALIGNMENT_CENTER`, `ALIGNMENT_END`).
- **Notes:**

#### Scenario 3: Edge case — type with no enums
- **Description:** Query enums for a type that may have none (e.g., a leaf type without custom enums).
- **Params:** `{ "type": "Sprite2D" }`
- **Expected result:** Success. Returns empty array or object. Should not error.
- **Notes:** Returning empty is valid — this is a data query, not a mutation.

#### Scenario 4: Edge case — invalid node type
- **Description:** Query enums for a non-existent type.
- **Params:** `{ "type": "NonExistentNodeABC" }`
- **Expected result:** Godot-side error.
- **Notes:**

#### Scenario 5: Missing required parameter — omit `type`
- **Description:** Call without `type`.
- **Params:** `{}`
- **Expected result:** Zod validation error at MCP SDK level.
- **Notes:**

#### Scenario 6: Wrong type — number
- **Description:** Pass a number.
- **Params:** `{ "type": 1 }`
- **Expected result:** Zod validation error at MCP SDK level.
- **Notes:**

---

## Tool: get_node_constants

**Description:** Get all constants defined on a node type.  
**Godot endpoint:** `node_config/get_constants`

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `type` | string (`NodeType`) | **Yes** | Node type name (e.g. `'Sprite2D'`, `'CharacterBody3D'`) |

### Test Scenarios

#### Scenario 1: Basic happy path — type with many constants
- **Description:** Get constants for `Input` or `@GlobalScope`-adjacent type.
- **Params:** `{ "type": "InputEventKey" }`
- **Expected result:** Success. Returns constants like `KEY_A`, `KEY_SPACE`, `KEY_ENTER`, etc. with their integer values.
- **Notes:**

#### Scenario 2: Basic happy path — type with typical enums/constants
- **Description:** Get constants for `BaseButton`.
- **Params:** `{ "type": "BaseButton" }`
- **Expected result:** Success. Returns constants like `DRAW_NORMAL`, `DRAW_PRESSED`, `DRAW_HOVER`, `DRAW_DISABLED` with their integer values.
- **Notes:**

#### Scenario 3: Edge case — type with no constants
- **Description:** Query constants for a type that may have none.
- **Params:** `{ "type": "Panel" }`
- **Expected result:** Success. Returns empty array or object. Should not error.
- **Notes:**

#### Scenario 4: Edge case — invalid node type
- **Description:** Query constants for a non-existent type.
- **Params:** `{ "type": "FakeNodeType999" }`
- **Expected result:** Godot-side error.
- **Notes:**

#### Scenario 5: Missing required parameter — omit `type`
- **Description:** Call without `type`.
- **Params:** `{}`
- **Expected result:** Zod validation error at MCP SDK level.
- **Notes:**

#### Scenario 6: Wrong type — boolean
- **Description:** Pass a boolean.
- **Params:** `{ "type": true }`
- **Expected result:** Zod validation error at MCP SDK level.
- **Notes:**

---

## Tool: get_class_hierarchy

**Description:** Get the full inheritance chain for a node type.  
**Godot endpoint:** `node_config/get_hierarchy`

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `type` | string (`NodeType`) | **Yes** | Node type name (e.g. `'Sprite2D'`, `'CharacterBody3D'`) |

### Test Scenarios

#### Scenario 1: Basic happy path — deep inheritance chain
- **Description:** Get the hierarchy for a deeply nested type.
- **Params:** `{ "type": "Sprite2D" }`
- **Expected result:** Success. Returns chain like `["Sprite2D", "Node2D", "CanvasItem", "Node", "Object"]`.
- **Notes:** Should be ordered from most specific to most general (or vice versa — verify actual order).

#### Scenario 2: Basic happy path — 3D node
- **Description:** Get the hierarchy for CharacterBody3D.
- **Params:** `{ "type": "CharacterBody3D" }`
- **Expected result:** Success. Returns chain like `["CharacterBody3D", "PhysicsBody3D", "CollisionObject3D", "Node3D", "Node", "Object"]`.
- **Notes:**

#### Scenario 3: Basic happy path — UI node
- **Description:** Get the hierarchy for a Button.
- **Params:** `{ "type": "Button" }`
- **Expected result:** Success. Returns chain like `["Button", "BaseButton", "Control", "CanvasItem", "Node", "Object"]`.
- **Notes:**

#### Scenario 4: Basic happy path — root type
- **Description:** Get the hierarchy for the base type itself.
- **Params:** `{ "type": "Node" }`
- **Expected result:** Success. Returns `["Node", "Object"]`.
- **Notes:**

#### Scenario 5: Basic happy path — Resource type
- **Description:** Get the hierarchy for a non-Node type (Resource).
- **Params:** `{ "type": "Resource" }`
- **Expected result:** Success. Returns `["Resource", "RefCounted", "Object"]`.
- **Notes:** This tests that the tool works for non-Node Godot classes.

#### Scenario 6: Edge case — `Object` (ultimate base type)
- **Description:** Get the hierarchy for the root of all Godot classes.
- **Params:** `{ "type": "Object" }`
- **Expected result:** Success. Returns `["Object"]` (single-element chain).
- **Notes:**

#### Scenario 7: Edge case — invalid type
- **Description:** Query hierarchy for a non-existent type.
- **Params:** `{ "type": "TotallyMadeUp123" }`
- **Expected result:** Godot-side error.
- **Notes:**

#### Scenario 8: Missing required parameter — omit `type`
- **Description:** Call without `type`.
- **Params:** `{}`
- **Expected result:** Zod validation error at MCP SDK level.
- **Notes:**

#### Scenario 9: Wrong type — array
- **Description:** Pass an array.
- **Params:** `{ "type": ["Sprite2D"] }`
- **Expected result:** Zod validation error at MCP SDK level.
- **Notes:**

#### Scenario 10: Edge case — whitespace-only type
- **Description:** Pass whitespace characters.
- **Params:** `{ "type": "   " }`
- **Expected result:** Godot-side error (no type with whitespace-only name after trimming, or treated as invalid name).
- **Notes:** Zod passes this through as a valid non-empty string.

---

## Summary of All Parameters and Constraints

| Tool | Required Params | Optional Params | Enums |
|---|---|---|---|
| `get_node_default_properties` | `type` | — | — |
| `set_node_preset` | `type`, `preset` | — | — |
| `get_available_node_types` | — | `category` | `'2d'`, `'3d'`, `'ui'`, `'audio'`, `'physics'`, `'navigation'` |
| `get_node_signals` | — | `type`, `path` (at least one) | — |
| `get_node_methods` | `type` | — | — |
| `get_node_enums` | `type` | — | — |
| `get_node_constants` | `type` | — | — |
| `get_class_hierarchy` | `type` | — | — |

**Total test scenarios:** 55  
**Happy-path scenarios:** 20  
**Edge-case scenarios:** 21  
**Missing/wrong-param scenarios:** 14
