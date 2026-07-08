# Prerequisites for theme_test_plan.md

> Generated from: `server/src/test_plans/theme_test_plan.md`
> Tools covered: `create_theme`, `delete_theme`, `set_theme_color`, `set_theme_constant`, `set_theme_font_size`, `set_theme_stylebox`, `get_theme_info`

---

## Required Project State

- **Godot 4.x editor** is open with the **MCP plugin active and connected** to the bridge server.
- **Any project template** (2D, 3D, or empty) — theme tools have no template-specific dependencies.
- **MCP bridge server** is running and reachable via WebSocket (auto-port scan on 6505–6514).
- Git repo initialized is **not** required, but harmless if present.

---

## Required Directories

These must exist on disk before the first `create_theme` call:

| Directory | Purpose | Created by |
|---|---|---|
| `res://themes/` | Base directory for all test themes | Must exist before setup |
| `res://themes/ui/` | Nested path for `create_theme` Scenario 2 | Created by `create_theme` itself (tests auto-creation), but pre-creating is safer |

**How to create:** Either manually in the Godot FileSystem dock, or via `manage_asset(action="create_folder", path="res://themes/")`.

---

## Required Scenes

### `res://scenes/main.tscn` — needed for 2 scenarios

| Scenario | Why needed |
|---|---|
| `create_theme` Scenario 9 | Tries to overwrite this scene path with a `.tres` — tests resource-type collision |
| `get_theme_info` Scenario 9 | Reads this scene as a "non-theme resource" — tests type mismatch error |

The scene can be **anything** (even a minimal scene with a single `Node` root). It just needs to exist at that exact path.

**Minimal setup:**
```
Node2D (root)
```

### Scene with referenced theme — needed for 1 scenario

| Scenario | Why needed |
|---|---|
| `delete_theme` Scenario 7 | Deletes `res://themes/referenced_theme.tres` while it is applied to UI nodes in an open scene — tests graceful handling of in-use resource deletion |

**Required node hierarchy:**
```
Control (root)                          → theme = res://themes/referenced_theme.tres
  └─ Button (name: "TestButton")        → inherits theme from root
```

The `Button` node needs no other configuration. The `referenced_theme.tres` must have at least one override set on it (e.g., `Button.font_color = "#FF0000"` via `set_theme_color`) so that when deleted, the nodes fall back to the default theme.

---

## Required Resources

### Theme files created during setup phase (run before any tests)

These are **not pre-existing** on disk — they are created by the setup sequence. They are listed here so the setup script can create them reliably.

| Theme file | Purpose | Created by | Deleted by |
|---|---|---|---|
| `res://themes/test_theme.tres` | Primary test theme for all `set_theme_*` and `get_theme_info` scenarios | `create_theme` (setup step 1) | `delete_theme` Scenario 1 (teardown) |
| `res://themes/temp_delete_test.tres` | Disposable theme for double-delete idempotency test | `create_theme` (before `delete_theme` Scenario 8) | `delete_theme` Scenario 8 (first call) |
| `res://themes/referenced_theme.tres` | Theme applied to scene nodes, then deleted while in use | `create_theme` (before `delete_theme` Scenario 7) | `delete_theme` Scenario 7 |
| `res://themes/my theme (copy).tres` | Theme with special characters in filename | `create_theme` (before `get_theme_info` Scenario 13) | Clean up after test |

### Other resource files (must exist)

| File | Purpose | Why needed |
|---|---|---|
| `res://scripts/player.gd` | Non-theme file for `delete_theme` Scenario 5 | Tests that deleting a non-theme resource via `delete_theme` does not corrupt non-theme files. Must be a real `.gd` script (can be empty `extends Node`). |

---

## Required Editor/Game State

| Requirement | Details |
|---|---|
| **MCP connection active** | WebSocket bridge must be connected (Godot plugin shows "Connected" in the MCP panel) |
| **No unsaved changes** | The test scene should be saved before running destructive tests (especially `delete_theme` Scenario 7) |
| **Play mode: OFF** | All tests run in edit mode. No runtime scenarios require play mode. |
| **Console clear** | Run `clear_output` before starting to separate test logs from prior editor output. |
| **FileSystem dock visible** | Useful for manual verification (not required by automation). Use `reload_project` if files don't appear after `create_theme`. |

---

## Required Settings/Config

| Setting | Value | Purpose |
|---|---|---|
| **MCP plugin enabled** | Project → Plugins → Godot MCP = Active | Required for any tool to work |
| **Default project settings** | Unchanged from Godot defaults | No custom project settings needed |
| **Input actions** | None required | Theme tools don't interact with input |
| **Autoloads** | None required beyond `mcp_runtime.gd` (part of the MCP plugin) | Runtime autoload not used since tests are edit-mode only |
| **Collision layers** | None required | Theme tools don't interact with physics |

---

## Setup Script

Run this sequence **once** before any tests. It creates the required directories, scene, non-theme resource, and the base test theme.

### Step 1: Ensure directories exist

```
manage_asset(action="create_folder", path="res://themes/")
manage_asset(action="create_folder", path="res://scripts/")
```

### Step 2: Create the minimal main scene (for type-collision tests)

```
create_scene(path="res://scenes/main.tscn", root_node_type="Node2D")
save_scene()
```

### Step 3: Create a disposable GDScript (for non-theme deletion test)

```
create_script(path="res://scripts/player.gd", content="extends Node\n", base_class="Node")
```

### Step 4: Create the primary test theme

```
create_theme(path="res://themes/test_theme.tres")
```

### Step 5: Verify theme is empty

```
get_theme_info(path="res://themes/test_theme.tres")
# Expected: success, theme exists with no overrides
```

### Step 6: Create and populate the referenced theme + scene for delete-while-in-use test

This is a multi-step sub-setup that should run **before** `delete_theme` Scenario 7:

```
# 6a. Create disposable theme
create_theme(path="res://themes/referenced_theme.tres")

# 6b. Set a color on it so it has overrides
set_theme_color(path="res://themes/referenced_theme.tres", theme_type="Button", name="font_color", color="#FF0000")

# 6c. Create (or load) a scene with a Control root and a Button child
create_scene(path="res://scenes/theme_ref_test.tscn", root_node_type="Control")
add_node(parent_path="", type="Button", name="TestButton")

# 6d. Apply the theme to the root Control node
update_property(path="", property="theme", value="res://themes/referenced_theme.tres")

# 6e. Save the scene
save_scene()
```

### Step 7: Create theme with special-char filename (for `get_theme_info` Scenario 13)

```
create_theme(path="res://themes/my theme (copy).tres")
```

---

## Teardown Script

Run **after all tests** to remove test artifacts:

```
# Delete all test themes
delete_theme(path="res://themes/test_theme.tres")
delete_theme(path="res://themes/ui/main_menu_theme.tres")
delete_theme(path="res://themes/my_custom_theme_v2.tres")
delete_theme(path="res://themes/my theme (copy).tres")
delete_theme(path="res://themes/temp_delete_test.tres")
delete_theme(path="res://themes/referenced_theme.tres")   # may already be deleted by Scenario 7
delete_theme(path="res://themes/no_extension")
delete_theme(path="res://themes/binary_theme.res")

# Delete test scene
delete_scene(path="res://scenes/theme_ref_test.tscn", force=true)

# Optional: delete disposable script (unless useful for other tests)
# delete_script(path="res://scripts/player.gd")
```

---

## Test Order Dependencies

```
┌─────────────────────────────────────────────────────────────┐
│ SETUP (run once)                                            │
│   ├─ create_folder("res://themes/")                         │
│   ├─ create_folder("res://scripts/")                        │
│   ├─ create_scene("res://scenes/main.tscn")                 │
│   ├─ create_script("res://scripts/player.gd")               │
│   ├─ create_theme("res://themes/test_theme.tres") ◄── KEY   │
│   ├─ setup referenced_theme + scene                         │
│   └─ create_theme("res://themes/my theme (copy).tres")      │
├─────────────────────────────────────────────────────────────┤
│ create_theme scenarios (all)                                │
│   NOTE: Scenario 1 IS the setup — run last among these      │
│   so scenarios 2-3 don't depend on it being re-created      │
├─────────────────────────────────────────────────────────────┤
│ set_theme_color scenarios                                   │
│   DEPENDS ON: test_theme.tres existing                      │
├─────────────────────────────────────────────────────────────┤
│ set_theme_constant scenarios                                │
│   DEPENDS ON: test_theme.tres existing                      │
├─────────────────────────────────────────────────────────────┤
│ set_theme_font_size scenarios                               │
│   DEPENDS ON: test_theme.tres existing                      │
├─────────────────────────────────────────────────────────────┤
│ set_theme_stylebox scenarios                                │
│   DEPENDS ON: test_theme.tres existing                      │
├─────────────────────────────────────────────────────────────┤
│ get_theme_info scenarios                                    │
│   DEPENDS ON: test_theme.tres existing (with overrides set) │
├─────────────────────────────────────────────────────────────┤
│ Integration scenarios                                       │
│   DEPENDS ON: test_theme.tres existing (all tools used)     │
├─────────────────────────────────────────────────────────────┤
│ delete_theme scenarios                                      │
│   DEPENDS ON: created themes existing to delete             │
│   RUN LAST: Scenario 1 deletes test_theme.tres              │
├─────────────────────────────────────────────────────────────┤
│ TEARDOWN                                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Per-Scenario Prerequisites Quick Reference

| # | Scenario | Requires |
|---|---|---|
| **create_theme** | | |
| 1 | Happy path — `res://themes/test_theme.tres` | `res://themes/` directory exists |
| 2 | Deeper path — `res://themes/ui/main_menu_theme.tres` | `res://themes/` directory exists |
| 3 | Different name pattern — `res://themes/my_custom_theme_v2.tres` | `res://themes/` directory exists |
| 4–8 | Validation (no path, no ext, abs path, empty string) | None |
| 9 | Overwrite scene `res://scenes/main.tscn` | Scene at `res://scenes/main.tscn` |
| 10 | Trailing slash `res://themes/` | None |
| **delete_theme** | | |
| 1 | Delete `res://themes/test_theme.tres` | Theme file exists (created by `create_theme` S1) |
| 2 | Delete `res://themes/ui/main_menu_theme.tres` | Theme file exists (created by `create_theme` S2) |
| 3–4, 6 | Validation | None (S4 needs nonexistent file) |
| 5 | Delete `res://scripts/player.gd` | Script at `res://scripts/player.gd` exists |
| 7 | Delete `res://themes/referenced_theme.tres` (in use) | Scene loaded with Control+Button using this theme |
| 8 | Double delete | `res://themes/temp_delete_test.tres` created first |
| **set_theme_color** | | |
| 1–7, 12–15, 17–18 | All happy-path + boundary | `res://themes/test_theme.tres` exists |
| 8–11 | Missing params | None (Zod catches before handler) |
| 16 | Nonexistent theme | None (tests error case) |
| **set_theme_constant** | | |
| 1–7 | All happy-path | `res://themes/test_theme.tres` exists |
| 8–16 | Missing/invalid params | None (Zod validation) |
| 17 | Nonexistent theme | None |
| **set_theme_font_size** | | |
| 1–6 | All happy-path | `res://themes/test_theme.tres` exists |
| 7–15 | Missing/invalid params | None (Zod validation) |
| 16 | Nonexistent theme | None |
| **set_theme_stylebox** | | |
| 1–12 | All happy-path + boundary | `res://themes/test_theme.tres` exists |
| 13–20 | Missing/invalid params | None (Zod validation) |
| 21 | Nonexistent theme | None |
| 22–23 | Custom name / invalid property | `res://themes/test_theme.tres` exists |
| **get_theme_info** | | |
| 1–6, 12 | Happy-path, verification, idempotency | `res://themes/test_theme.tres` exists (populated) |
| 7 | Missing path | None |
| 8, 10 | Nonexistent / empty path | None |
| 9 | Non-theme resource `res://scenes/main.tscn` | Scene at `res://scenes/main.tscn` exists |
| 11 | Built-in default theme | None (optional — tests graceful handling) |
| 13 | Path with spaces/parens | `res://themes/my theme (copy).tres` exists |
| **Integration** | | |
| 1 | Full lifecycle | `res://themes/` directory exists |
| 2 | Modify existing overrides | `res://themes/test_theme.tres` exists (populated) |
| 3 | Cross-control-type isolation | `res://themes/test_theme.tres` exists |
