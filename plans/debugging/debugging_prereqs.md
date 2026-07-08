# Prerequisites for debugging_test_plan.md

> Extracted from `server/src/test_plans/debugging_test_plan.md` (all 8 tools + integration sequence)

---

## Required Project State

- **Godot 4.x project** with the Godot MCP addon installed and active
- **MCP bridge connected** — WebSocket between server and Godot editor must be established
- **Main scene set** in project settings — must be a playable scene to support `play_scene({ "mode": "main" })`
- **Project name set** in `project.godot` (`application/config/name`) — used by `evaluate_expression` integration step 10

---

## Required Scenes

### Main Scene (`res://` — exact path flexible, but must be the project's main scene)

The main scene must be playable and must contain at minimum:

```
Main (root node)                [Node or Node2D or Node3D]
├── Player                      [CharacterBody2D or Node2D]
│   └── (script: player.gd)
```

**Rationale by test scenario:**
- `evaluate_expression` Scenario 4 references `get_node('/root/Main/Player').position.x` — the scene must be named `Main` at the root of `/root/` and contain a child named `Player` with a `position` property (i.e., any `Node2D`, `Node3D`, or `Control` subclass).
- The integration sequence calls `play_scene({ "mode": "main" })` — the main scene must exist and be playable.
- The scene must execute the `player.gd` script so breakpoints fire when the game runs.

---

## Required Resources

### Script: `res://scripts/player.gd`

**Must exist on disk with ALL of the following characteristics:**

#### Length
- **At least 50 lines** of code (integration sequence prerequisite, also needed for line 99999 edge case to not hit the same error path as a too-short file)

#### Executable lines at specific positions
| Line | Must be | Used by |
|------|---------|---------|
| 1 | Any content (may be non-executable) | `set_breakpoint` Scenario 3 (boundary), Scenario 9 |
| 3–5 | Some variable declaration or comment | General context |
| 5 | Executable code | `set_breakpoint` Scenario 11 (empty condition) |
| 10 | Executable code | `set_breakpoint` Scenario 1, `remove_breakpoint` Scenario 1, integration steps 1, 13 |
| 25 | Executable code within a scope where `speed` variable is accessible | `set_breakpoint` Scenario 2, integration steps 2, 14, 15 |
| 42 | Executable code within a scope where `health` variable is accessible | `set_breakpoint` Scenario 2 (conditional: `health <= 0`) |

#### Variables in scope at breakpoint lines
- **`speed`** — must be a numeric variable accessible at or before line 25 (used in conditional `speed > 100` and expression evaluation `speed` in integration step 7)
- **`health`** — must be a numeric variable accessible at or before line 42 (used in conditional `health <= 0`)

#### Code structure requirements
- **A GDScript function call** at one of the breakpoint lines (e.g., `some_function()` at line 10) — required for `step_into` Scenario 1
- **An assignment statement** (non-function-call) at one of the breakpoint lines (e.g., `var x = 1`) — required for `step_into` Scenario 2
- **A call to a built-in/engine method** at one of the breakpoint lines (e.g., `print()` or `add_child()`) — required for `step_into` Scenario 3
- **A function that is called from another function** and returns — required for `step_over` Scenario 3 (last line of function)
- **At least two distinct breakpoint locations** that are reachable in sequence — required for `continue_execution` Scenario 2 (continue to next breakpoint)

#### Example structure (not prescriptive, but illustrative of what meets all requirements)
```gdscript
extends CharacterBody2D
# Line 1

var speed := 0.0          # Line 3 — speed variable
var health := 100         # Line 4 — health variable

func _ready():            # Line 6
    print("ready")        # Line 7 — built-in call (step_into Scenario 3)
    var x = 10            # Line 8 — assignment (step_into Scenario 2)
    do_work()             # Line 9 — custom call (step_into Scenario 1)
    speed = 5.0           # Line 10 — executable (set_breakpoint Scenario 1)

func do_work():           # Line 12
    update_speed()        # Line 13
    check_health()        # Line 14
    var done = true       # Line 15 — last line of function (step_over Scenario 3)

func update_speed():      # Line 17
    speed += 2            # Line 18
    # ... (more lines to reach ~25)
    if speed > 100:       # Line 25 — conditional breakpoint target
        speed = 100       # Line 26

func _process(delta):     # Line 28
    speed += delta * 10   # Line 29
    if speed > 100:       # Line 30
        speed = 100       # Line 31

func check_health():      # Line 33
    health -= 5           # Line 34
    # ... (more lines to reach ~42)
    if health <= 0:       # Line 42 — conditional breakpoint target
        health = 0        # Line 43

func die():               # Line 45
    print("dead")         # Line 46
    queue_free()          # Line 47

# Lines 48–50: filler to reach 50 lines minimum
# _process already runs continuously to trigger breakpoints
```

> **Note:** The exact content is not prescribed. The above is a template that satisfies every prerequisite. Any script matching the bullet-point structural requirements above will work.

---

## Required Editor/Game State

### Per-tool state matrix

| Tool | Scenario(s) | Prerequisite State |
|------|-------------|--------------------|
| `set_breakpoint` | 1–3, 9–12 | Editor idle (no game running). `res://scripts/player.gd` exists. |
| `set_breakpoint` | 4–8 | None (schema validation — rejected by server before reaching Godot) |
| `set_breakpoint` | 13 | MCP bridge disconnected (editor not running) |
| `remove_breakpoint` | 1 | A breakpoint previously set at `res://scripts/player.gd:10` via `set_breakpoint` |
| `remove_breakpoint` | 2 | No breakpoint at `res://scripts/player.gd:99` (clean state or ensure not set) |
| `remove_breakpoint` | 3–7 | None (schema validation) |
| `remove_breakpoint` | 8 | Editor idle |
| `remove_breakpoint` | 9 | MCP bridge disconnected |
| `list_breakpoints` | 1 | **2–3 breakpoints previously set** via `set_breakpoint` at distinct lines |
| `list_breakpoints` | 2 | **No breakpoints set** — clean state |
| `list_breakpoints` | 3 | Any state (handler ignores extra params) |
| `list_breakpoints` | 4 | MCP bridge disconnected |
| `get_call_stack` | 1 | **Game running AND paused at a breakpoint** at an executable line |
| `get_call_stack` | 2 | Game **not** running (editor idle) |
| `get_call_stack` | 3 | **Game running but NOT paused** (no breakpoint hit, or continued past breakpoint) |
| `get_call_stack` | 4 | Game paused at breakpoint (handler test) |
| `get_call_stack` | 5 | MCP bridge disconnected |
| `evaluate_expression` | 1 | Editor idle (any open project/scene). Expression: `1 + 2`. |
| `evaluate_expression` | 2 | Editor idle. Expression: `OS.get_name()`. |
| `evaluate_expression` | 3 | **Game running**. Expression: `get_tree().get_node_count()`. |
| `evaluate_expression` | 4 | **Game running** with scene at `/root/Main/Player` (a `Node2D`-like node with `.position.x`). |
| `evaluate_expression` | 5–8 | None (schema validation) |
| `evaluate_expression` | 9 | Editor idle. Expression: `foo(`. |
| `evaluate_expression` | 10 | Editor idle. Expression: multi-line GDScript. |
| `evaluate_expression` | 11 | Game **not** running (editor idle). Context: `'game'`. |
| `evaluate_expression` | 12 | MCP bridge disconnected |
| `step_over` | 1–3 | **Game running AND paused at a breakpoint** at an executable line |
| `step_over` | 4 | Game **not** running |
| `step_over` | 5 | **Game running but NOT paused** |
| `step_over` | 6 | MCP bridge disconnected |
| `step_into` | 1–3 | **Game running AND paused at a breakpoint** at an executable line (must be a function call for Scenario 1) |
| `step_into` | 4 | Game **not** running |
| `step_into` | 5 | **Game running but NOT paused** |
| `step_into` | 6 | MCP bridge disconnected |
| `continue_execution` | 1–2, 5 | **Game running AND paused at a breakpoint** |
| `continue_execution` | 3 | Game **not** running |
| `continue_execution` | 4 | **Game running but NOT paused** |
| `continue_execution` | 6 | MCP bridge disconnected |

### Integration Sequence State Requirements

| Step | Action | Prerequisite |
|------|--------|--------------|
| 1 | `set_breakpoint` at line 10 | Editor idle, `player.gd` exists |
| 2 | `set_breakpoint` at line 25 with condition | Editor idle, `player.gd` exists |
| 3 | `list_breakpoints` | 2 breakpoints set from steps 1–2 |
| 4 | `play_scene` (mode: main) | Main scene set in project settings, scene is playable |
| 5 | Wait for breakpoint hit | Game running, execution reaches line 10 or 25 |
| 6 | `get_call_stack` | **Game running AND paused at breakpoint** |
| 7 | `evaluate_expression("speed", game)` | Game paused at breakpoint where `speed` is in scope |
| 8 | `step_over` | Game paused at breakpoint |
| 9 | `step_into` | Game paused at a line with a function call |
| 10 | `evaluate_expression` (editor context) | Editor running (game may still be running or paused) |
| 11 | `continue_execution` | Game paused at breakpoint |
| 12 | `stop_scene` | Game running |
| 13 | `remove_breakpoint` at line 10 | Editor idle (game stopped), breakpoint exists at line 10 |
| 14 | `list_breakpoints` | Only line 25 breakpoint remains |
| 15 | `remove_breakpoint` at line 25 | Editor idle, breakpoint exists at line 25 |
| 16 | `list_breakpoints` | No breakpoints remain |

---

## Required Settings/Config

- **Godot MCP addon** must be enabled in `Project > Project Settings > Plugins`
- **MCP runtime autoload** must be registered: `mcp_runtime="res://addons/godot_mcp/services/mcp_runtime.gd"` in `project.godot` `[autoload]` section (no `*` prefix — must load in-game)
- **Main scene** must be set via `application/run/main_scene` in project settings
- **Project name** set via `application/config/name` (any value) for integration step 10

---

## Required External State

- **Godot editor must be running** with the project open (for all connected tests; must be **not running** for the disconnected/bridge-error tests)
- **No additional addons or packages** required beyond the Godot MCP addon itself

---

## Summary: Non-Negotiable Artifacts

These must exist on disk/file-system before ANY meaningful test scenario can execute:

1. **`res://scripts/player.gd`** — GDScript file, ≥50 lines, with:
   - Numeric variables `speed` and `health` in scope at lines ~25 and ~42
   - A custom function call on a line where a breakpoint will be set
   - An assignment (non-call) on a breakpoint line
   - A built-in method call on a breakpoint line
   - A function that returns naturally (for last-line step-over test)
   
2. **A playable main scene** (`application/run/main_scene` set) with:
   - Root named `Main` (or at minimum a scene at `/root/Main` in the runtime tree)
   - A child node named `Player` with a `position` property (`Node2D`, `Node3D`, or `Control` subclass)
   - The `player.gd` script attached to the `Player` node (or any node that gets executed on game start)

3. **Godot MCP addon** active with runtime autoload configured (no `*` prefix)

4. **MCP bridge connected** (for all scenarios except the explicit disconnection tests)
