# Test Plan: analysis.ts

**File:** `server/src/tools/analysis.ts`
**Module:** Analysis — 4 tools for project and scene analysis
**GDScript backend:** `addons/godot_mcp/commands/analysis_commands.gd`

---

## Prerequisites

All four tools require a **running Godot editor** with the MCP plugin active and connected via WebSocket.
Before running any test scenario, ensure:

1. Godot editor is open with a project loaded
2. MCP plugin is active (Project → Project Settings → Plugins → Godot MCP: Active)
3. MCP server is running and connected (check MCP tab in Godot bottom panel)

**Scene requirements by tool:**

| Tool | Requires open scene? |
|------|---------------------|
| `analyze_scene_complexity` | **Yes** — returns `{"error": "No scene open"}` otherwise |
| `analyze_signal_flow` | **Yes** — returns `{"error": "No scene open"}` otherwise |
| `find_unused_resources` | No — scans the entire project filesystem |
| `get_project_statistics` | No — scans the entire project filesystem |

---

## Tool: `analyze_scene_complexity`

### Registration

```typescript
server.registerTool(
  'analyze_scene_complexity',
  {
    description: "Analyze a scene's complexity (node count, depth, resource usage)",
    inputSchema: {},
  },
  async (args) => callGodot(bridge, 'analysis/scene_complexity', args as Record<string, unknown>),
);
```

### Parameters

None. This tool takes no parameters (`inputSchema: {}`). The GDScript handler receives `_params: Dictionary` but ignores it entirely.

### GDScript Backend Logic

1. Gets the currently edited scene root via `MCPCommandHelpers.get_scene_root(_plugin)`
2. If no scene is open, returns `{"error": "No scene open"}`
3. Recursively walks the entire scene tree from root, counting:
   - `total_nodes` — every node in the tree
   - `max_depth` — deepest nesting level
   - `script_count` — nodes with an attached script
   - `texture_count` — Sprite2D, TextureRect, Sprite3D nodes
   - `mesh_count` — MeshInstance3D, MeshInstance2D nodes
   - `light_count` — Light3D, Light2D nodes
   - `physics_body_count` — any PhysicsBody2D/3D subclass
   - `audio_player_count` — AudioStreamPlayer, AudioStreamPlayer2D, AudioStreamPlayer3D
   - `particle_count` — GPUParticles2D/3D, CPUParticles2D/3D
   - `control_count` — any Control node
   - `type_breakdown` — dictionary mapping class name → count
4. Computes `estimated_draw_calls` = texture_count + mesh_count + light_count + particle_count
5. Returns `{"result": stats}`

### Return Structure

On success:
```json
{
  "result": {
    "total_nodes": <int>,
    "max_depth": <int>,
    "script_count": <int>,
    "texture_count": <int>,
    "mesh_count": <int>,
    "light_count": <int>,
    "physics_body_count": <int>,
    "audio_player_count": <int>,
    "particle_count": <int>,
    "control_count": <int>,
    "estimated_draw_calls": <int>,
    "type_breakdown": { "<ClassName>": <int>, ... }
  }
}
```

On error (no scene open):
```json
{
  "error": "No scene open"
}
```

### Test Scenarios

#### Scenario 1: Happy path — analyze a simple scene

**Description:** Open a scene with a few nodes (e.g., a root Node2D with 2 children: a Sprite2D and a Timer). Call `analyze_scene_complexity` with no params.

**Params:**
```json
{}
```

**Expected Result:**
- Response `content[0].text` is a JSON string containing `"result"` object (no `"error"` key)
- `result.total_nodes` ≥ 3 (root + 2 children minimum)
- `result.max_depth` ≥ 1 (children are at depth 1)
- `result.type_breakdown` is a dictionary with keys like `"Node2D"`, `"Sprite2D"`, `"Timer"`
- `result.type_breakdown["Sprite2D"]` ≥ 1
- `result.texture_count` ≥ 1 (the Sprite2D)
- `result.estimated_draw_calls` = texture_count + mesh_count + light_count + particle_count
- All numeric fields are non-negative integers

**Notes:** This is the baseline test. Requires a scene with known node composition to validate counts.

**Pay attention:**
- `total_nodes` should exactly match the number of nodes in the scene (including the root)
- `max_depth` is counted from the root (depth 0), root's children → depth 1
- `estimated_draw_calls` is a sum, not actual engine draw calls
- `type_breakdown` contains only classes actually present in the scene

---

#### Scenario 2: Empty scene (root node only)

**Description:** Open a scene that contains only a single root node with no children.

**Params:**
```json
{}
```

**Expected Result:**
- `result.total_nodes` = 1
- `result.max_depth` = 0
- `result.script_count` = 0 (unless root has a script)
- `result.type_breakdown` has exactly one entry for the root node's class
- All `*_count` fields are 0 (except those matching the root type)
- `result.estimated_draw_calls` = 0 (for a plain Node root)

**Notes:** Boundary condition — minimum scene. Validates that the recursive walk handles a leaf node correctly.

**Pay attention:**
- `max_depth` must be exactly 0, not -1 or null
- `type_breakdown` must not be empty — the root node is always present

---

#### Scenario 3: Complex scene with diverse node types

**Description:** Open a scene with a rich mix of node types: MeshInstance3D, DirectionalLight3D, RigidBody3D, AudioStreamPlayer3D, GPUParticles3D, Control nodes, and scripts.

**Params:**
```json
{}
```

**Expected Result:**
- `result.total_nodes` matches the actual node count
- `result.mesh_count` ≥ 1 (for MeshInstance3D nodes)
- `result.light_count` ≥ 1 (for DirectionalLight3D)
- `result.physics_body_count` ≥ 1 (for RigidBody3D)
- `result.audio_player_count` ≥ 1 (for AudioStreamPlayer3D)
- `result.particle_count` ≥ 1 (for GPUParticles3D)
- `result.control_count` ≥ 1 (if Control nodes exist)
- `result.script_count` matches the number of nodes with attached scripts
- `result.estimated_draw_calls` = texture_count + mesh_count + light_count + particle_count
- `result.type_breakdown` contains entries for each distinct class present

**Notes:** Validates that all category counters work correctly across 2D and 3D node types.

**Pay attention:**
- Verify that 3D types (MeshInstance3D) are counted separately from 2D (MeshInstance2D)
- `physics_body_count` must include all subclasses: StaticBody, RigidBody, CharacterBody (both 2D and 3D)
- `type_breakdown` uses `get_class()` — for inheritors, the base class will be returned (e.g. `CharacterBody3D`, not `PhysicsBody3D`)

---

#### Scenario 4: No scene open (error case)

**Description:** Close all scenes in the editor (or have no scene open), then call the tool.

**Params:**
```json
{}
```

**Expected Result:**
- Response `content[0].text` is a JSON string containing `"error": "No scene open"`
- The response does NOT have `isError: true` at the MCP level (the GDScript returns an error dict, but `callGodot` treats any successful bridge response as non-error)

**Notes:** The GDScript backend returns `{"error": "No scene open"}` when `get_scene_root()` returns null. This is NOT an MCP-level error — it's a data-level error embedded in the result.

**Pay attention:**
- The response does NOT have `isError: true` — the "No scene open" error is embedded in the JSON body, not in the MCP wrapper
- Verify that the `"error"` key is present in the response text

---

#### Scenario 5: Extra params are ignored

**Description:** Pass arbitrary extra parameters — the tool should ignore them since `inputSchema` is empty.

**Params:**
```json
{
  "scene_path": "res://scenes/main.tscn",
  "depth": 5
}
```

**Expected Result:**
- Tool still succeeds and returns the scene complexity analysis for the **currently open** scene
- The `scene_path` parameter has no effect — the tool always analyzes the currently edited scene
- Result structure is identical to Scenario 1

**Notes:** The GDScript handler signature is `analyze_scene_complexity(_params: Dictionary)` — the underscore prefix indicates params are unused. The tool always operates on the currently edited scene root.

**Pay attention:**
- The `scene_path` parameter does not affect the result — the tool always analyzes the currently open scene
- The result should be identical to a call with empty parameters

---

## Tool: `analyze_signal_flow`

### Registration

```typescript
server.registerTool(
  'analyze_signal_flow',
  {
    description: 'Analyze signal flow and connections in a scene',
    inputSchema: {},
  },
  async (args) => callGodot(bridge, 'analysis/signal_flow', args as Record<string, unknown>),
);
```

### Parameters

None. This tool takes no parameters (`inputSchema: {}`). The GDScript handler receives `_params: Dictionary` but ignores it.

### GDScript Backend Logic

1. Gets the currently edited scene root
2. If no scene is open, returns `{"error": "No scene open"}`
3. Recursively walks the scene tree, collecting:
   - **nodes** array: each entry has `path`, `name`, `type`
   - **edges** array: each entry has `from`, `signal`, `to`, `method`
4. Skips editor-internal signals (those starting with `__`)
5. Skips editor-internal methods (those starting with `__`)
6. Skips connections to editor-internal nodes (paths starting with `/root/@`)
7. **Truncation limits:**
   - Stops collecting nodes at **25 nodes**
   - Stops collecting edges at **50 edges**
   - If truncated, adds `"truncated": true` and `"warning"` message to result
8. Returns `{"result": { node_count, connection_count, nodes, connections [, truncated, warning] }}`

### Return Structure

On success:
```json
{
  "result": {
    "node_count": <int>,
    "connection_count": <int>,
    "nodes": [
      { "path": "<string>", "name": "<string>", "type": "<string>" },
      ...
    ],
    "connections": [
      { "from": "<string>", "signal": "<string>", "to": "<string>", "method": "<string>" },
      ...
    ],
    "truncated": true,
    "warning": "Results truncated at 25 nodes / 50 edges. Large scenes may have more connections."
  }
}
```

The `truncated` and `warning` fields are **only present** when truncation occurred.

### Test Scenarios

#### Scenario 1: Happy path — scene with signal connections

**Description:** Open a scene where at least one node has a signal connected to another node's method (e.g., a Button's `pressed` signal connected to a script method).

**Params:**
```json
{}
```

**Expected Result:**
- Response contains `"result"` object (no `"error"`)
- `result.node_count` ≥ 2 (source and target nodes)
- `result.connection_count` ≥ 1
- `result.nodes` is an array, each element has `path`, `name`, `type` (all strings)
- `result.connections` is an array, each element has `from`, `signal`, `to`, `method` (all strings)
- The connection's `signal` matches the actual Godot signal name (e.g., `"pressed"`)
- The connection's `method` matches the target method name

**Notes:** The scene must have at least one signal connection wired up. Use `connect_signal` from `node.ts` beforehand if needed.

**Pay attention:**
- `from` and `to` are scene-relative paths (without the `/root/@EditorNode@...` prefix)
- Root node paths are represented as `"."` (see `get_node_path` in command_helpers)
- `method` is the name of the receiving method, not the signal name

---

#### Scenario 2: Scene with no signal connections

**Description:** Open a scene with nodes but no signal connections between them.

**Params:**
```json
{}
```

**Expected Result:**
- `result.node_count` ≥ 1 (at least the root node)
- `result.connection_count` = 0
- `result.connections` is an empty array `[]`
- `result.nodes` still contains entries for all nodes in the scene
- No `truncated` or `warning` fields

**Notes:** Validates that the tool handles scenes with zero connections gracefully.

**Pay attention:**
- `connections` must be an empty array `[]`, not `null` or absent
- `nodes` still contains all scene nodes even if there are no connections

---

#### Scenario 3: Scene with multiple signal connections across nodes

**Description:** Open a scene with several interconnected nodes (e.g., 3 buttons each connected to different methods, plus cross-node signals).

**Params:**
```json
{}
```

**Expected Result:**
- `result.connection_count` matches the actual number of signal connections
- Each connection in `result.connections` has valid `from` and `to` paths
- No connections to editor-internal nodes (paths starting with `/root/@`)
- No signals starting with `__` in the connections
- No methods starting with `__` in the connections

**Notes:** Validates the filtering of editor-internal signals and methods.

**Pay attention:**
- Engine signals (starting with `__`) must be filtered out
- Connections to editor-internal nodes (`/root/@...`) must be excluded
- Each `from`/`to` path must point to an actually existing node in the `nodes` array

---

#### Scenario 4: Large scene — truncation at 25 nodes

**Description:** Open a scene with more than 25 nodes to trigger the node truncation limit.

**Params:**
```json
{}
```

**Expected Result:**
- `result.node_count` ≤ 25
- `result.truncated` = `true`
- `result.warning` is a string containing "truncated"
- `result.nodes` array length ≤ 25

**Notes:** The GDScript stops collecting nodes at 25 to avoid WebSocket buffer overflow. This is a hard limit, not configurable.

**Pay attention:**
- `truncated` only appears when the limit is reached (25 nodes or 50 connections)
- `warning` contains an informative message with specific limit numbers
- Even when truncated, the collected data must be consistent (every connection references nodes from `nodes`)

---

#### Scenario 5: Large scene — truncation at 50 edges

**Description:** Open a scene with many signal connections (>50) but fewer than 25 nodes to trigger edge truncation.

**Params:**
```json
{}
```

**Expected Result:**
- `result.connection_count` ≤ 50
- `result.truncated` = `true`
- `result.warning` is present
- `result.nodes` may have fewer than 25 entries (recursion also stops when edges hit 50)

**Notes:** The truncation check occurs at both the node level (25) and edge level (50). Hitting either limit stops further collection.

**Pay attention:**
- The edge limit (50) may be reached before the node limit (25)
- The recursive traversal also checks `nodes.size() >= 50 or edges.size() >= 100` at child call level (double check)

---

#### Scenario 6: No scene open (error case)

**Description:** Close all scenes, then call the tool.

**Params:**
```json
{}
```

**Expected Result:**
- Response contains `"error": "No scene open"` in the JSON body
- No `isError: true` at MCP level

**Notes:** Same error pattern as `analyze_scene_complexity`.

**Pay attention:**
- Behavior is identical to `analyze_scene_complexity` when no scene is open

---

#### Scenario 7: Extra params are ignored

**Description:** Pass arbitrary parameters that might seem relevant (e.g., a node filter or depth limit).

**Params:**
```json
{
  "root_path": "Player",
  "max_depth": 3,
  "include_editor_signals": true
}
```

**Expected Result:**
- Tool succeeds and returns the full signal flow for the currently open scene
- None of the extra params affect the result — the GDScript handler ignores `_params` entirely
- Result is identical to calling with `{}`

**Notes:** The tool has no parameter support. All analysis is always on the entire scene from root.

**Pay attention:**
- No passed parameters affect the result
- Analysis always covers the entire scene from root to the deepest nodes

---

## Tool: `find_unused_resources`

### Registration

```typescript
server.registerTool(
  'find_unused_resources',
  {
    description: 'Find resources in the project that are not referenced by any scene or script',
    inputSchema: {},
  },
  async (args) => callGodot(bridge, 'analysis/unused_resources', args as Record<string, unknown>),
);
```

### Parameters

None. This tool takes no parameters (`inputSchema: {}`). The GDScript handler receives `_params: Dictionary` but ignores it.

### GDScript Backend Logic

1. Walks the project directory (`res://`) collecting all resource files with these extensions:
   - Images: `png`, `jpg`, `jpeg`, `svg`, `webp`
   - Audio: `wav`, `ogg`, `mp3`
   - Fonts: `ttf`, `otf`
   - 3D models: `obj`, `fbx`, `glb`, `gltf`
   - Other: `material`, `shader`
2. Walks the project directory collecting all code files: `.tscn`, `.gd`, `.tres`
3. Single-pass regex extraction: compiles `res://[a-zA-Z0-9_/.\\-]+` and searches all code files for `res://` references
4. Builds a set of all referenced paths
5. Any resource file NOT in the reference set is considered unused
6. Returns `{"result": { total_resources, unused_count, unused_resources }}`

### Return Structure

On success:
```json
{
  "result": {
    "total_resources": <int>,
    "unused_count": <int>,
    "unused_resources": [
      "res://assets/old_sprite.png",
      "res://sounds/unused.wav",
      ...
    ]
  }
}
```

### Test Scenarios

#### Scenario 1: Happy path — project with some unused resources

**Description:** In a project that has at least one image/audio/font file not referenced by any `.tscn`, `.gd`, or `.tres` file, call the tool.

**Params:**
```json
{}
```

**Expected Result:**
- Response contains `"result"` object
- `result.total_resources` > 0
- `result.unused_count` ≥ 0
- `result.unused_resources` is an array of `res://` path strings
- Each path in `unused_resources` has one of the supported extensions (png, jpg, jpeg, svg, webp, wav, ogg, mp3, ttf, otf, obj, fbx, glb, gltf, material, shader)
- `result.unused_count` = `result.unused_resources.length`

**Notes:** Requires a project with known resource file layout. Prepare by adding an image file that is NOT referenced anywhere.

**Pay attention:**
- `unused_resources` contains only files with supported extensions (not `.gd`, not `.tscn`)
- Paths should be in `res://...` format (not absolute file paths)
- `total_resources` = count of all resource files (used + unused)

---

#### Scenario 2: Project with no unused resources

**Description:** In a project where every resource file is referenced by at least one scene or script.

**Params:**
```json
{}
```

**Expected Result:**
- `result.total_resources` > 0
- `result.unused_count` = 0
- `result.unused_resources` is an empty array `[]`

**Notes:** Achieve this by ensuring all added resources are referenced in at least one `.tscn`, `.gd`, or `.tres` file.

**Pay attention:**
- An empty array `[]` is a valid result, not an error
- `total_resources` is still > 0 (resources exist, they are just all in use)

---

#### Scenario 3: Verify specific file is detected as unused

**Description:** Add a known unused file (e.g., `res://assets/test_unused.png`) to the project, then call the tool and verify it appears in the results.

**Params:**
```json
{}
```

**Expected Result:**
- `result.unused_resources` contains `"res://assets/test_unused.png"`
- `result.unused_count` includes this file in its count

**Notes:** This is a deterministic test — add a file you control, verify it's detected. Clean up after the test.

**Pay attention:**
- The file should appear in the list only if it is NOT referenced in any `.tscn`, `.gd` or `.tres` file
- Adding a reference to `res://assets/test_unused.png` in any script/scene should exclude it from the list

---

#### Scenario 4: Verify referenced file is NOT detected as unused

**Description:** Add a resource file AND reference it in a script or scene, then verify it does NOT appear in `unused_resources`.

**Params:**
```json
{}
```

**Expected Result:**
- `result.unused_resources` does NOT contain the referenced file
- `result.total_resources` includes the file (it exists on disk)

**Notes:** The regex `res://[a-zA-Z0-9_/.\\-]+` must match the reference in the code file. Ensure the reference uses the exact `res://` path.

**Pay attention:**
- Regex searches for `res://[a-zA-Z0-9_/.\\-]+` — paths with spaces or special characters may not match
- The reference should be in `.tscn`, `.gd` or `.tres` files (not in `.md`, not in `.cfg`)

---

#### Scenario 5: Supported file extensions coverage

**Description:** Verify that only files with the supported extensions are scanned as resources.

**Params:**
```json
{}
```

**Expected Result:**
- `result.total_resources` counts only files with these extensions: `png`, `jpg`, `jpeg`, `svg`, `webp`, `wav`, `ogg`, `mp3`, `ttf`, `otf`, `obj`, `fbx`, `glb`, `gltf`, `material`, `shader`
- Files with other extensions (e.g., `.txt`, `.json`, `.cfg`, `.gd`, `.tscn`, `.tres`) are NOT counted as resources

**Notes:** The GDScript uses `PackedStringArray` with specific extensions in the `walk_directory` call. This is a whitelist, not a blacklist.

**Pay attention:**
- `.gd` and `.tscn` files are NOT counted as resources — they are considered "code files" for reference searching
- `.tres` files are also not in the resource list, but are scanned as reference sources
- Extensions are case-insensitive (GDScript calls `.to_lower()`)

---

#### Scenario 6: Extra params are ignored

**Description:** Pass parameters like `extensions` or `path` to try to filter results.

**Params:**
```json
{
  "extensions": ["png"],
  "path": "res://assets/"
}
```

**Expected Result:**
- Tool succeeds and returns ALL unused resources across the entire project
- The `extensions` and `path` params have no effect
- Result is identical to calling with `{}`

**Notes:** The tool scans the entire `res://` directory for all supported extensions. No filtering is available.

**Pay attention:**
- Filter parameters are not supported — the entire project is always scanned
- The result is identical to calling without parameters

---

## Tool: `get_project_statistics`

### Registration

```typescript
server.registerTool(
  'get_project_statistics',
  {
    description: 'Get project statistics (file counts, sizes, node types, script languages, etc.)',
    inputSchema: {},
  },
  async () => callGodot(bridge, 'analysis/statistics'),
);
```

### Parameters

None. This tool takes no parameters. Note: the handler is `async () => callGodot(bridge, 'analysis/statistics')` — it does not even forward `args` to the bridge (unlike the other three tools which pass `args as Record<string, unknown>`).

### GDScript Backend Logic

1. Initializes a stats dictionary with `files_by_extension: {}`, `total_files: 0`, `total_size_bytes: 0`, `directories: 0`
2. Recursively scans `res://` directory:
   - Skips hidden directories (starting with `.`) and `.godot` directory
   - For each file: increments `total_files`, records extension in `files_by_extension`, adds file size to `total_size_bytes`
   - For each directory: increments `directories`, recurses into it
3. File extension is normalized to lowercase; files without extension get `"(no ext)"`
4. File size is read via `FileAccess.open()` + `get_length()`
5. Returns `{"result": stats}`

### Return Structure

On success:
```json
{
  "result": {
    "files_by_extension": {
      "gd": <int>,
      "tscn": <int>,
      "tres": <int>,
      "png": <int>,
      "(no ext)": <int>,
      ...
    },
    "total_files": <int>,
    "total_size_bytes": <int>,
    "directories": <int>
  }
}
```

### Test Scenarios

#### Scenario 1: Happy path — get project statistics

**Description:** Call `get_project_statistics` with no arguments on a project with files.

**Params:**
```json
{}
```

**Expected Result:**
- Response contains `"result"` object
- `result.total_files` > 0
- `result.total_size_bytes` > 0
- `result.directories` ≥ 0
- `result.files_by_extension` is a dictionary with string keys and integer values
- At minimum, `result.files_by_extension` contains `"gd"` (for project scripts) and `"tscn"` (for scenes)
- Sum of all values in `files_by_extension` = `result.total_files`

**Notes:** This is the baseline smoke test. Any real Godot project will have at least a few `.gd` and `.tscn` files.

**Pay attention:**
- The sum of values in `files_by_extension` should exactly equal `total_files`
- `total_size_bytes` should be > 0 (at least `project.godot` exists)
- Dictionary keys are lowercase (`.to_lower()` in GDScript)

---

#### Scenario 2: Verify extension breakdown accuracy

**Description:** Cross-check that specific known file types are counted correctly.

**Params:**
```json
{}
```

**Expected Result:**
- `result.files_by_extension["gd"]` matches the actual count of `.gd` files in the project
- `result.files_by_extension["tscn"]` matches the actual count of `.tscn` files
- `result.files_by_extension["tres"]` matches the actual count of `.tres` files (if any)
- Extensions are lowercase: `"GD"` or `"Tscn"` should NOT appear as keys

**Notes:** Manually count files in the project directory to verify. Use `get_filesystem_tree` from `project.ts` as a cross-reference.

**Pay attention:**
- Extensions are always lowercase thanks to `.to_lower()`
- Files without extensions are grouped under the key `"(no ext)"`
- Hidden directories (starting with `.`) and `.godot` are skipped

---

#### Scenario 3: Verify total_size_bytes is reasonable

**Description:** Check that the total size is a reasonable value for the project.

**Params:**
```json
{}
```

**Expected Result:**
- `result.total_size_bytes` > 0
- `result.total_size_bytes` is proportional to the project size (a small project: ~100KB–10MB, a large project: ~100MB+)
- The value should be calculable by summing individual file sizes

**Notes:** The GDScript reads file sizes via `FileAccess.open()` + `get_length()`. This is an I/O-heavy operation for large projects.

**Pay attention:**
- `total_size_bytes` is the cumulative size of ALL project files (excluding the contents of `.godot` and hidden folders)
- The value should be a non-negative integer

---

#### Scenario 4: Verify directories count excludes hidden and .godot

**Description:** Confirm that `directories` does not count hidden directories (starting with `.`) or the `.godot` directory.

**Params:**
```json
{}
```

**Expected Result:**
- `result.directories` does NOT include `.godot`, `.git`, `.import`, or any directory starting with `.`
- `result.directories` counts only visible project directories

**Notes:** The GDScript explicitly checks `not file_name.begins_with(".") and file_name != ".godot"` before counting and recursing.

**Pay attention:**
- The `.godot` directory is Godot's internal directory, it should NOT be counted
- `.git` and other hidden directories are also excluded
- Files inside `.godot` are NOT counted in `total_files` and `total_size_bytes`

---

#### Scenario 5: Extra params are ignored

**Description:** Pass arbitrary parameters.

**Params:**
```json
{
  "path": "res://scripts/",
  "include_hidden": true
}
```

**Expected Result:**
- Tool succeeds and returns full project statistics
- Extra params have no effect — the handler signature is `async () => callGodot(...)` (no args forwarded)
- Result is identical to calling with `{}`

**Notes:** Unlike the other three analysis tools, this one doesn't even forward `args` to the bridge. The handler is `async () =>` (no parameters).

**Pay attention:**
- This handler function does not accept any arguments at all (`async () =>`), unlike the other three (`async (args) =>`)
- No parameters can affect the result

---

## Dependency & Sequencing Notes

### No Prerequisites Between These Tools

All four analysis tools are **independent read-only tools**. They do not require any other tools to be called first. None of them modify state.

### Scene Requirement

`analyze_scene_complexity` and `analyze_signal_flow` require a scene to be open. If testing these tools, ensure a scene is open first. Useful companion tools:

| Tool | File | When to use |
|------|------|-------------|
| `open_scene` | `scene.ts` | To open a specific scene before analyzing it |
| `create_scene` | `scene.ts` | To create a new scene with a specific root node type |
| `add_node` | `node.ts` | To add nodes to a scene before analysis |
| `connect_signal` | `node.ts` | To wire up signal connections before `analyze_signal_flow` |

### Typical Analysis Workflow

1. **Open or create a scene** via `open_scene` or `create_scene`
2. **Add nodes** via `add_node` (to build a scene with known structure)
3. **Connect signals** via `connect_signal` (for signal flow analysis)
4. **Analyze complexity** via `analyze_scene_complexity` → verify node counts
5. **Analyze signals** via `analyze_signal_flow` → verify connections
6. **Find unused resources** via `find_unused_resources` → identify cleanup candidates
7. **Get project stats** via `get_project_statistics` → overall project health

### Independent Tools

`find_unused_resources` and `get_project_statistics` are fully independent — they scan the project filesystem and do not require any scene to be open. They can be called at any time.

---

## Cross-Tool Error Scenarios

#### Scenario: Godot editor not connected

**Description:** Call any of the four tools when no Godot editor is connected to the MCP server.

**Params (for any tool):**
```json
{}
```

**Expected Result:**
- Response has `isError: true`
- Error message contains `"Godot editor is not connected"` (from `GodotBridge.sendRequest`)

**Notes:** This error comes from the TypeScript bridge layer (`godot-bridge.ts` line 239), not from GDScript.

**Pay attention:**
- The error should be clear and contain `"Godot editor is not connected"`
- There should be no unhandled exceptions or empty responses

---

#### Scenario: Request timeout

**Description:** If the Godot editor becomes unresponsive, the request should time out gracefully.

**Params (for any tool):**
```json
{}
```

**Expected Result:**
- Response has `isError: true`
- Error message contains `"timed out"` and references the timeout duration

**Notes:** Hard to trigger in a controlled test. May occur if the editor is busy compiling or loading a large project (especially `find_unused_resources` and `get_project_statistics` which scan the entire filesystem).

**Pay attention:**
- `find_unused_resources` and `get_project_statistics` scan the entire project filesystem — they may be slow for large projects
- Timeout is set in `config.ts` as `REQUEST_TIMEOUT_MS`

---

#### Scenario: `callGodot` bridge error wrapping

**Description:** When the GDScript returns an error dictionary (e.g., `{"error": "No scene open"}`), the `callGodot` function in `server.ts` wraps the entire response as a JSON string in the MCP result. It does NOT set `isError: true`.

**Params (for `analyze_scene_complexity` or `analyze_signal_flow` with no scene):**
```json
{}
```

**Expected Result:**
- MCP response `content[0].text` contains the string `"error": "No scene open"`
- MCP response does NOT have `isError: true`
- The error is embedded in the JSON body, not in the MCP error flag

**Notes:** This is an important distinction. The GDScript-level error (`{"error": "..."}`) is NOT the same as an MCP-level error (`isError: true`). The `callGodot` function treats any successful bridge response as a success — it only sets `isError` when the bridge itself throws (e.g., connection failure, timeout).

**Pay attention:**
- Distinguish between MCP-level errors (`isError: true`) and errors in the response body (`{"error": "..."}`)
- GDScript errors pass through `callGodot` as successful responses — `isError` is NOT set
- Only bridge errors (no connection, timeout) lead to `isError: true`
