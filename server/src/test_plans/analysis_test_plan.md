# Analysis Tools — Test Plan

**Source file:** `server/src/tools/analysis.ts`
**Godot endpoint prefix:** `analysis/`
**Total tools:** 4

---

## Shared Types Reference

All four tools in this module have empty `inputSchema` (`{}`). None accept parameters.

| Tool | Handler Pattern | Args forwarded? |
|---|---|---|
| `analyze_scene_complexity` | `callGodot(bridge, 'analysis/scene_complexity', args as Record<string, unknown>)` | ✅ Yes |
| `analyze_signal_flow` | `callGodot(bridge, 'analysis/signal_flow', args as Record<string, unknown>)` | ✅ Yes |
| `find_unused_resources` | `callGodot(bridge, 'analysis/unused_resources', args as Record<string, unknown>)` | ✅ Yes |
| `get_project_statistics` | `callGodot(bridge, 'analysis/statistics')` | ❌ No — args are ignored |

**Important**: The first three tools forward all received arguments (including extraneous ones) to Godot via `args as Record<string, unknown>`. Tool 4 `get_project_statistics` uses `async ()` without `args`, so even if the caller passes arguments, they are discarded on the server side and never reach Godot.

---

## Tool 1: `analyze_scene_complexity`

**Description:** Analyze a scene's complexity (node count, depth, resource usage)
**Godot endpoint:** `analysis/scene_complexity`

### Parameters

None. `inputSchema` is `{}`.

### Behavior

Analyzes the currently open scene and returns complexity metrics including:
- Node count (total nodes in the scene tree)
- Tree depth (maximum nesting depth)
- Resource usage (counts and types of resources referenced)
- Possibly: distribution of node types, scene file size, script count

Operates on the currently open scene in the editor. If no scene is open, behavior depends on the Godot-side implementation.

### Test Scenarios

---

#### S-1.1: Happy path — simple scene

**Description:** Analyze a scene with a single root node (e.g., `Node2D`) and no children.

**Params:**
```json
{}
```

**Expected result:** JSON response with `node_count: 1`, `max_depth: 1`, minimal resource usage. All expected keys present.

**Notes:** Requires a simple scene to be open in the editor.

---

#### S-1.2: Happy path — moderately complex scene

**Description:** Analyze a scene with multiple nested nodes (3-5 levels deep), several node types, and attached resources (scripts, textures, materials).

**Params:**
```json
{}
```

**Expected result:** JSON response with `node_count` > 1, `max_depth` >= 2, resource count > 0. All metrics reflect the actual scene complexity.

**Notes:** The response should accurately reflect the scene's actual node count and depth.

---

#### S-1.3: Happy path — scene with many of the same node type

**Description:** Analyze a scene with 50+ nodes of the same type (e.g., 50 `Sprite2D` children under a single parent).

**Params:**
```json
{}
```

**Expected result:** `node_count` >= 51 (50 children + 1 parent). The distribution/key for that node type should show a count of at least 50.

**Notes:** Verifies that the tool correctly counts large numbers of nodes of a single type.

---

#### S-1.4: Happy path — 3D scene

**Description:** Analyze a 3D scene with MeshInstance3D nodes, lights, camera, and physics bodies.

**Params:**
```json
{}
```

**Expected result:** JSON response correctly identifying 3D node types and their counts. Resource usage includes 3D-specific resources (materials, meshes).

**Notes:** Verifies the tool works for both 2D and 3D scene types.

---

#### S-1.5: Happy path — UI scene

**Description:** Analyze a scene with Control-based UI nodes (buttons, labels, panels, containers).

**Params:**
```json
{}
```

**Expected result:** JSON response identifying UI node types (`Button`, `Label`, `Panel`, `VBoxContainer`, etc.) and their counts.

**Notes:** Verifies the tool covers Control/UI node types.

---

#### S-1.6: Happy path — scene with scene instances (nested scenes)

**Description:** Analyze a scene that instantiates other scenes (via `PackedScene` instances).

**Params:**
```json
{}
```

**Expected result:** The instantiated sub-scene nodes are counted in `node_count`. If the tool reports scene instances separately, they should appear as a distinct category.

**Notes:** Verifies that instantiated scene nodes are included in the complexity analysis, not skipped.

---

#### S-1.7: Happy path — scene with attached scripts

**Description:** Analyze a scene where multiple nodes have GDScripts attached.

**Params:**
```json
{}
```

**Expected result:** Script count or script references appear in the results. The total resource count should include scripts.

**Notes:** Verifies script attachment is counted as a resource.

---

#### S-1.8: Happy path — call twice, same scene, same result

**Description:** Call `analyze_scene_complexity` twice in succession without modifying the scene.

**Params (both calls):**
```json
{}
```

**Expected result:** Both responses are identical (same node count, same depth, same resource numbers).

**Notes:** Idempotency check — analysis should be deterministic.

---

#### S-1.9: Happy path — call with extra ignored argument

**Description:** Pass an extra key not defined in the schema.

**Params:**
```json
{"extra_param": "ignored_value"}
```

**Expected result:** Success — extra param is forwarded to Godot but should not affect the analysis result.

**Notes:** Since `inputSchema` is `{}` and the handler uses `args as Record<string, unknown>`, Zod does not reject extraneous keys. Godot-side may ignore them.

---

#### S-1.10: Edge case — no scene open

**Description:** Call the tool when no scene is open in the editor.

**Params:**
```json
{}
```

**Expected result:** Error response (`isError: true`) with a message like "No scene is currently open" or similar.

**Notes:** Should not crash the server. The tool depends on an open scene.

---

#### S-1.11: Edge case — empty scene (just created, never saved)

**Description:** Create a new unsaved scene with a root node, call the tool before saving.

**Params:**
```json
{}
```

**Expected result:** Should still work on the in-memory scene. Returns complexity data for the unsaved scene.

**Notes:** The tool should operate on the editor's active scene, not require a saved file on disk.

---

#### S-1.12: Edge case — deeply nested scene (100+ levels)

**Description:** Analyze a scene with extreme nesting depth (e.g., 100 nodes each as a child of the previous).

**Params:**
```json
{}
```

**Expected result:** `max_depth` >= 100. The response should not be truncated or cause a timeout.

**Notes:** Edge case for deep recursion. May hit Godot-side limits or performance issues.

---

#### S-1.13: Edge case — large scene (1000+ nodes)

**Description:** Analyze a scene with over 1000 nodes.

**Params:**
```json
{}
```

**Expected result:** Complete response showing all node type counts. No timeout or truncation.

**Notes:** Performance and payload size test. The response could be large.

---

#### S-1.14: Edge case — editor disconnected

**Description:** Call the tool when the Godot editor is not connected to the MCP server.

**Params:**
```json
{}
```

**Expected result:** Error: connection timeout or "Godot editor is not connected".

**Notes:** Standard disconnected-server behavior.

---

#### S-1.15: Edge case — call while scene is playing

**Description:** Call the tool while a scene is actively playing in the editor (play mode).

**Params:**
```json
{}
```

**Expected result:** Either returns analysis of the running scene tree or an error ("tool not available during play mode"). Behavior depends on Godot-side implementation.

**Notes:** Some tools are restricted to edit mode only. Check if this one works at runtime.

---

## Tool 2: `analyze_signal_flow`

**Description:** Analyze signal flow and connections in a scene.
**Godot endpoint:** `analysis/signal_flow`

### Parameters

None. `inputSchema` is `{}`.

### Behavior

Scans the currently open scene and maps all signal connections between nodes. Returns a graph-like structure showing which nodes emit which signals and which nodes/methods receive them. May also detect orphaned signal connections (connections to deleted nodes), signal chains, or hub nodes with many connections.

### Test Scenarios

---

#### S-2.1: Happy path — scene with signal connections

**Description:** Analyze a scene that has at least one signal connection (e.g., a Button's `pressed` signal connected to a method on a parent node).

**Params:**
```json
{}
```

**Expected result:** JSON response with a list/map of signal connections. Each connection should identify: source node, signal name, target node, and target method.

**Notes:** Requires a scene with connected signals to be open.

---

#### S-2.2: Happy path — scene with multiple signals from one node

**Description:** Analyze a scene where a single node has multiple signals connected (e.g., a Timer with `timeout` connected to method A and `tree_exiting` connected to method B).

**Params:**
```json
{}
```

**Expected result:** Both connections are listed, each with the same source node but different signals and targets.

**Notes:** Verifies that all signals from a single node are reported.

---

#### S-2.3: Happy path — scene with no signal connections

**Description:** Analyze a fresh empty scene with no signal connections.

**Params:**
```json
{}
```

**Expected result:** Empty array/list of connections. Should not error.

**Notes:** Zero connections is a valid result.

---

#### S-2.4: Happy path — scene with signal connections via code

**Description:** Analyze a scene where signals are connected in GDScript `_ready()` methods rather than via the editor's Signal dock.

**Params:**
```json
{}
```

**Expected result:** Behavior depends on Godot-side analysis depth — may or may not detect code-connected signals. If the tool only analyzes editor-level connections (`.tscn` file data), code-connected signals may not appear.

**Notes:** Important to document whether code-connected signals are detected. This affects the tool's usefulness.

---

#### S-2.5: Happy path — scene with two-way signal connections

**Description:** Analyze a scene where Node A connects a signal to Node B, and Node B connects a (different) signal back to Node A.

**Params:**
```json
{}
```

**Expected result:** Both connections appear in the results, with correct source/target directions.

**Notes:** Bidirectional signal connections should be correctly mapped.

---

#### S-2.6: Happy path — hub node (many connections)

**Description:** Analyze a scene where one node receives signals from 10+ other nodes (a "signal hub" pattern).

**Params:**
```json
{}
```

**Expected result:** All 10+ connections are listed. The hub node appears as the target in multiple entries.

**Notes:** Verifies the tool handles high fan-in to a single node.

---

#### S-2.7: Happy path — chain of signals

**Description:** Analyze a scene with a signal chain: Node A signal → Node B method, where Node B's method then emits another signal → Node C method.

**Params:**
```json
{}
```

**Expected result:** Both connections (A→B, B→C) appear in the results. If the tool identifies signal chains, they should be documented as a chain.

**Notes:** Tests for signal flow path analysis capability.

---

#### S-2.8: Happy path — call twice, same result

**Description:** Call `analyze_signal_flow` twice without modifying the scene.

**Params (both calls):**
```json
{}
```

**Expected result:** Identical responses.

**Notes:** Idempotency check.

---

#### S-2.9: Edge case — no scene open

**Description:** Call the tool when no scene is open.

**Params:**
```json
{}
```

**Expected result:** Error response (`isError: true`).

**Notes:** Should not crash the server.

---

#### S-2.10: Edge case — scene with orphaned signal connections

**Description:** Analyze a scene where a signal connection references a target node that has been deleted (orphaned connection). This can happen when editing `.tscn` files manually.

**Params:**
```json
{}
```

**Expected result:** The tool should either report the orphaned connection with a warning/marker, or skip it gracefully without error.

**Notes:** Edge case for invalid signal data in the scene file.

---

#### S-2.11: Edge case — very large signal graph (100+ connections)

**Description:** Analyze a scene with 100+ signal connections.

**Params:**
```json
{}
```

**Expected result:** Complete listing of all connections. No truncation or timeout.

**Notes:** Performance and payload size test for large signal graphs.

---

#### S-2.12: Edge case — editor disconnected

**Description:** Call the tool when the Godot editor is not connected.

**Params:**
```json
{}
```

**Expected result:** Connection timeout or "not connected" error.

**Notes:** Standard disconnected behavior.

---

#### S-2.13: Edge case — call while scene is playing

**Description:** Call during active play mode.

**Params:**
```json
{}
```

**Expected result:** May return runtime signal connections (different from editor connections) or error. Behavior depends on implementation.

**Notes:** Runtime signal connections may differ from editor-time connections (dynamic connects/disconnects).

---

## Tool 3: `find_unused_resources`

**Description:** Find resources in the project that are not referenced by any scene or script.
**Godot endpoint:** `analysis/unused_resources`

### Parameters

None. `inputSchema` is `{}`.

### Behavior

Scans the entire project directory for resource files (`.tres`, `.res`, textures, audio, materials, scripts, etc.) and cross-references them against all scene files and script files. Returns a list of resource paths that are not referenced by any scene or script — i.e., "orphan" resources that could potentially be deleted.

IMPORTANT: This tool operates on the entire project, not just the currently open scene. It may take longer to execute than other analysis tools.

### Test Scenarios

---

#### S-3.1: Happy path — project with unused resources

**Description:** Run in a project that has at least one resource file not referenced by any scene or script (e.g., a `.png` in the filesystem that is never used).

**Params:**
```json
{}
```

**Expected result:** Array of resource paths (e.g., `["res://assets/unused_texture.png", "res://materials/old_material.tres"]`). The unused file is listed.

**Notes:** Requires setting up a test project with known unused resources.

---

#### S-3.2: Happy path — project with no unused resources

**Description:** Run in a clean project where every resource is referenced by at least one scene or script.

**Params:**
```json
{}
```

**Expected result:** Empty array `[]`. Should not error.

**Notes:** Zero unused resources is a valid (and ideal) result.

---

#### S-3.3: Happy path — resources referenced only by scripts

**Description:** Create a resource that is loaded via GDScript (`load("res://...")` or `preload("res://...")`) but is never directly assigned to a node in any scene.

**Params:**
```json
{}
```

**Expected result:** The resource should NOT appear as unused (it is referenced by the script).

**Notes:** Verifies that script-level `load()`/`preload()` references are detected.

---

#### S-3.4: Happy path — resources referenced only by other resources

**Description:** Resource A (`.tres`) references Resource B (e.g., a material that references a texture). Resource A is used in a scene, but Resource B is only used through Resource A.

**Params:**
```json
{}
```

**Expected result:** Neither Resource A nor Resource B should appear as unused. Resource B is transitively referenced.

**Notes:** Verifies transitive/resource-chain reference detection.

---

#### S-3.5: Happy path — resources with circular references

**Description:** Two resources that reference each other (if Godot allows this), both used in a scene.

**Params:**
```json
{}
```

**Expected result:** Neither resource appears as unused. Circular references should not cause infinite loops or errors.

**Notes:** Tests robustness against circular reference chains.

---

#### S-3.6: Happy path — autoload scripts

**Description:** An autoload script file should not appear as unused.

**Params:**
```json
{}
```

**Expected result:** Autoload scripts are NOT listed as unused resources.

**Notes:** Autoloads are registered in `project.godot` but may not have direct scene/script references.

---

#### S-3.7: Happy path — project settings resources

**Description:** A resource registered as a project setting (e.g., the default theme or default font) should not appear as unused.

**Params:**
```json
{}
```

**Expected result:** Project-setting resources are NOT listed as unused.

**Notes:** Resources referenced in project.godot should be recognized as "used."

---

#### S-3.8: Happy path — call twice, same result

**Description:** Call `find_unused_resources` twice without modifying the project.

**Params (both calls):**
```json
{}
```

**Expected result:** Identical lists of unused resources.

**Notes:** Idempotency check — the analysis should be deterministic.

---

#### S-3.9: Edge case — empty project

**Description:** Run in a brand-new project with no scenes, scripts, or resources.

**Params:**
```json
{}
```

**Expected result:** Empty array `[]`. No errors.

**Notes:** The tool should handle a minimal project gracefully.

---

#### S-3.10: Edge case — very large project (1000+ resources)

**Description:** Run in a project with 1000+ resource files.

**Params:**
```json
{}
```

**Expected result:** Complete list of unused resources. Response should not be truncated and should not time out.

**Notes:** Performance and payload size test. May take several seconds to complete.

---

#### S-3.11: Edge case — resource with special characters in path

**Description:** Include resources with spaces, Unicode characters, or special symbols in their file names/paths.

**Params:**
```json
{}
```

**Expected result:** Resources with special-character paths are correctly processed — either listed as unused or correctly identified as used.

**Notes:** Path encoding edge case. Example paths: `res://assets/my file.png`, `res://assets/файл.png`, `res://assets/file#1.png`.

---

#### S-3.12: Edge case — editor disconnected

**Description:** Call when the Godot editor is not connected.

**Params:**
```json
{}
```

**Expected result:** Connection timeout or "not connected" error.

**Notes:** Standard disconnected behavior.

---

#### S-3.13: Edge case — project not fully imported

**Description:** Run with unimported assets (e.g., a `.blend` file that has no generated `.import` file yet).

**Params:**
```json
{}
```

**Expected result:** Unimported assets should either be listed as unused or skipped with a note. The tool should not error.

**Notes:** Godot's import pipeline may affect what counts as a "resource."

---

#### S-3.14: Edge case — call while scene is playing

**Description:** Call during active play mode.

**Params:**
```json
{}
```

**Expected result:** Should work regardless of play mode — this is a project-level analysis, not scene-dependent. Should return same results as edit mode.

**Notes:** Verify the tool is not blocked during play mode.

---

#### S-3.15: Edge case — duplicate resource paths (symlinks/copies)

**Description:** Run in a project with duplicate resource files (same name in different folders, or symlinked files).

**Params:**
```json
{}
```

**Expected result:** Each file path is treated independently. Duplicates should not cause errors or incorrect "unused" classification.

**Notes:** Path uniqueness edge case.

---

## Tool 4: `get_project_statistics`

**Description:** Get project statistics (file counts, sizes, node types, script languages, etc.)
**Godot endpoint:** `analysis/statistics`

### Parameters

None. `inputSchema` is `{}`.

**Important difference from Tools 1-3:** This tool uses `async () => callGodot(bridge, 'analysis/statistics')` WITHOUT `args`. Any arguments passed by the caller are silently discarded on the server side and never reach Godot.

### Behavior

Aggregates statistics across the entire project — totals across all scenes, scripts, and resources. Returns metrics such as:
- Total file counts (scenes, scripts, resources, textures, audio, etc.)
- Total file sizes (by category and overall)
- Node type distribution (how many of each node type across all scenes)
- Script language distribution (GDScript count, C# count if applicable)
- Possibly: project disk usage, average scene size, most common node types

### Test Scenarios

---

#### S-4.1: Happy path — typical project

**Description:** Call in a project with multiple scenes, scripts, textures, and other resources.

**Params:**
```json
{}
```

**Expected result:** JSON response with categorized statistics. Each category (scenes, scripts, resources) has a count. Total file size is reported. Node type distribution shows most common types.

**Notes:** All expected keys should be present. Counts should be accurate.

---

#### S-4.2: Happy path — project with only scripts

**Description:** Call in a project with GDScript files but no scenes.

**Params:**
```json
{}
```

**Expected result:** Scene count = 0, script count > 0. No error.

**Notes:** Tests that a scene-less project is handled gracefully.

---

#### S-4.3: Happy path — project with only scenes

**Description:** Call in a project with scene files but no standalone scripts.

**Params:**
```json
{}
```

**Expected result:** Scene count > 0, standalone script count = 0 (or scripts embedded in scenes are counted).

**Notes:** Tests that a script-less project is handled.

---

#### S-4.4: Happy path — project with mixed script languages

**Description:** Call in a project containing both GDScript (`.gd`) and C# (`.cs`) scripts.

**Params:**
```json
{}
```

**Expected result:** Both GDScript and C# counts are reported separately (e.g., `"gdscript": 5, "csharp": 3`).

**Notes:** Verifies language-level differentiation.

---

#### S-4.5: Happy path — project with audio, textures, and 3D models

**Description:** Call in a project with diverse resource types: `.ogg`/`.mp3` audio, `.png`/`.jpg` textures, `.glb`/`.fbx` 3D models, `.tres`/`.res` materials.

**Params:**
```json
{}
```

**Expected result:** All resource types are counted and categorized. Categories like "audio," "textures," "models," "materials" each have their own totals.

**Notes:** Comprehensive resource type coverage.

---

#### S-4.6: Happy path — call twice, same result (no changes)

**Description:** Call `get_project_statistics` twice without modifying the project.

**Params (both calls):**
```json
{}
```

**Expected result:** Identical responses (same counts, same totals).

**Notes:** Idempotency check.

---

#### S-4.7: Happy path — call before and after adding a scene

**Description:** Call once, create a new scene, call again.

**Steps:**
1. Call `get_project_statistics` (baseline)
2. Create a new scene via `godot_create_scene`
3. Call `get_project_statistics` again

**Expected result:** Scene count increases by 1. Other counts unchanged.

**Notes:** Verifies that the tool reflects project changes in real-time.

---

#### S-4.8: Happy path — call before and after adding a script

**Description:** Call once, create a new GDScript, call again.

**Steps:**
1. Call `get_project_statistics` (baseline)
2. Create a new script via `godot_create_script`
3. Call `get_project_statistics` again

**Expected result:** Script count increases by 1 (or the specific language count increases).

**Notes:** Verifies real-time script tracking.

---

#### S-4.9: Happy path — call before and after importing a resource

**Description:** Call once, import a texture/audio file, call again.

**Steps:**
1. Call `get_project_statistics` (baseline)
2. Import a new resource file
3. Call `get_project_statistics` again

**Expected result:** Resource count for the appropriate category increases by 1.

**Notes:** Verifies resource import tracking.

---

#### S-4.10: Happy path — call after deleting a file

**Description:** Call once, delete a scene or script, call again.

**Steps:**
1. Call `get_project_statistics` (baseline)
2. Delete a file via `godot_delete_scene` or `godot_delete_script`
3. Call `get_project_statistics` again

**Expected result:** The deleted file's count decreases by 1.

**Notes:** Verifies that deletion is reflected in statistics.

---

#### S-4.11: Happy path — verify total file size is reasonable

**Description:** Call in any project and verify the reported total file size.

**Params:**
```json
{}
```

**Expected result:** Total file size is a positive number. If the tool reports by category, the sum of category sizes should approximately equal the total.

**Notes:** Sanity check on file size aggregation.

---

#### S-4.12: Edge case — empty project (new project with only default files)

**Description:** Call in a freshly created project with no scenes or scripts added yet.

**Params:**
```json
{}
```

**Expected result:** Scene count = 0, script count = 0, resource counts minimal (possibly only `.import` and project files). No error.

**Notes:** The tool should not error on an empty project.

---

#### S-4.13: Edge case — very large project (1000+ scenes, 5000+ resources)

**Description:** Call in a very large project.

**Params:**
```json
{}
```

**Expected result:** Complete statistics without truncation, timeout, or memory issues.

**Notes:** Performance and payload size stress test. The response may be large.

---

#### S-4.14: Edge case — project with deeply nested directories

**Description:** Call in a project with files nested 20+ directory levels deep.

**Params:**
```json
{}
```

**Expected result:** All files are counted regardless of nesting depth. No errors from path length limits.

**Notes:** Recursive directory traversal edge case.

---

#### S-4.15: Edge case — editor disconnected

**Description:** Call when the Godot editor is not connected.

**Params:**
```json
{}
```

**Expected result:** Connection timeout or "not connected" error.

**Notes:** Standard disconnected behavior.

---

#### S-4.16: Edge case — call while scene is playing

**Description:** Call during active play mode.

**Params:**
```json
{}
```

**Expected result:** Should work — this is project-level statistics, not scene-dependent. Should return same results as edit mode.

**Notes:** Verify the tool is not blocked during play mode.

---

#### S-4.17: Edge case — call with extra argument (args discarded test)

**Description:** Pass an extra argument to verify it is silently discarded by `get_project_statistics` (unlike Tools 1-3 which forward args via `args as Record<string, unknown>`).

**Params:**
```json
{"extra_param": "should_be_ignored"}
```

**Expected result:** Success — same result as calling with `{}`. The extra argument is discarded on the server side.

**Notes:** This differentiates Tool 4 from Tools 1-3. Since the handler is `async () => callGodot(...)` without `args`, the extra param never reaches Godot. This is the correct behavior for this specific tool.

---

#### S-4.18: Edge case — call with null body

**Description:** Call with `null` instead of `{}`.

**Params:**
```json
null
```

**Expected result:** MCP SDK may coerce `null` to `{}`. Either result is acceptable — the important thing is that the tool does not crash.

**Notes:** Null body edge case.

---

## Integration / Cross-Tool Scenarios

---

#### S-I.1: Scene complexity → signal flow correlation

**Description:** Analyze a scene with known signals, then verify that `analyze_signal_flow` reports the same nodes that appear in `analyze_scene_complexity`.

**Steps:**
1. Open a scene with signal connections
2. Call `analyze_scene_complexity`
3. Call `analyze_signal_flow`
4. Verify that nodes listed in signal flow results exist in the scene complexity node distribution

**Expected result:** Consistency between the two tools — no node referenced in signal flow is missing from complexity analysis.

---

#### S-I.2: Find unused resources → project statistics correlation

**Description:** Run both tools and verify that the total resource count in `get_project_statistics` is >= the unused + used resources from `find_unused_resources`.

**Steps:**
1. Call `get_project_statistics`
2. Call `find_unused_resources`
3. Verify total resources >= unused count (unused is a subset of total)

**Expected result:** The unused resource count <= total resource count from project statistics.

---

#### S-I.3: Add scene → check all analysis tools

**Description:** Create a scene, then run all four analysis tools to verify none break.

**Steps:**
1. Create a new scene with several nodes and signal connections
2. Add some resources that are referenced
3. Add some orphan resources (not referenced)
4. Call all four analysis tools in sequence
5. Verify each tool returns coherent results

**Expected result:** All four tools succeed. `analyze_scene_complexity` reports the new scene's structure. `analyze_signal_flow` reports connections. `find_unused_resources` lists orphan resources. `get_project_statistics` counts the new files.

---

#### S-I.4: Delete scene → verify statistics update

**Description:** Delete a scene and verify statistics reflect the change.

**Steps:**
1. Call `get_project_statistics` (baseline)
2. Call `find_unused_resources` (baseline)
3. Delete a scene file
4. Call `get_project_statistics` again
5. Call `find_unused_resources` again

**Expected result:** Scene count decreases. Resources that were only referenced by the deleted scene may now appear as unused.

---

#### S-I.5: Open scene, analyze, switch scene, analyze again

**Description:** Verify that `analyze_scene_complexity` and `analyze_signal_flow` reflect the currently open scene.

**Steps:**
1. Open scene A (simple scene)
2. Call `analyze_scene_complexity` → note node count
3. Open scene B (complex scene)
4. Call `analyze_scene_complexity` → node count should be different (higher)
5. Call `analyze_signal_flow` on scene B

**Expected result:** Both tools operate on the currently open scene. Switching scenes changes the results.

---

#### S-I.6: Full analysis pipeline (all 4 tools)

**Description:** Run all four tools back-to-back in a single session.

**Steps:**
1. Call `analyze_scene_complexity`
2. Call `analyze_signal_flow`
3. Call `find_unused_resources`
4. Call `get_project_statistics`

**Expected result:** All four tools complete successfully without interference or timeout.

**Notes:** End-to-end stress test of the analysis module.

---

## Summary Matrix

| # | Tool | Params | Godot Endpoint | Args forwarded? | No-Param | Scope |
|---|---|---|---|---|---|---|
| 1 | `analyze_scene_complexity` | 0 | `analysis/scene_complexity` | ✅ Yes | ✅ | Current scene |
| 2 | `analyze_signal_flow` | 0 | `analysis/signal_flow` | ✅ Yes | ✅ | Current scene |
| 3 | `find_unused_resources` | 0 | `analysis/unused_resources` | ✅ Yes | ✅ | Entire project |
| 4 | `get_project_statistics` | 0 | `analysis/statistics` | ❌ No | ✅ | Entire project |

## Summary: Coverage Statistics

| Category | Count |
|---|---|
| **Total scenarios** | **61** |
| `analyze_scene_complexity` scenarios | 15 |
| `analyze_signal_flow` scenarios | 13 |
| `find_unused_resources` scenarios | 15 |
| `get_project_statistics` scenarios | 18 |
| Integration scenarios | 6 |
| Happy path scenarios | 28 |
| Edge case scenarios | 27 |
| Bridge/connectivity scenarios | 4 |
| Cross-tool integration scenarios | 6 |

**Coverage:** Every tool, every parameter (none, verified), every Godot endpoint, handler pattern differences (args forwarded vs. discarded), empty schema behavior, scene-level vs. project-level scope, idempotency, disconnected editor, play mode, scale/performance edges, and cross-tool consistency.

---

## Test Execution Notes

1. **Godot editor must be running** with the MCP plugin active and connected for all tests.
2. **A test project should be prepared** with:
   - Multiple scenes of varying complexity (simple 1-node, medium 10-node, complex 100+ node)
   - Scenes WITH signal connections (Button → method, Timer → method, custom signals)
   - Scenes WITHOUT signal connections (empty/fresh scenes)
   - Known unused resource files (placed in the project but never referenced)
   - Known used resource files (referenced by scenes and scripts)
   - Resources referenced transitively (Resource A → Resource B chain)
   - Resources referenced only by scripts via `load()`/`preload()`
   - Scripts of both GDScript and C# (if applicable)
   - Diverse resource types (textures, audio, materials, 3D models)
   - Scenes with deeply nested hierarchies
   - A "project statistics baseline" scene set to verify counts change correctly after CRUD operations
3. **For Tools 1 and 2** (scene-level), ensure a scene is open in the editor before calling. Test with no-scene-open as an edge case.
4. **For Tools 3 and 4** (project-level), these should work regardless of whether a scene is open. Verify this explicitly.
5. **The handler difference for Tool 4** (`get_project_statistics`): unlike Tools 1-3, this tool discards caller arguments. Test that passing extras does NOT affect results (S-4.17).
6. **Zod validation** is minimal for these tools (`inputSchema: {}`), so Zod will not reject extraneous keys. Error handling is primarily on the Godot side.
7. **Naming convention**: `S-{tool_number}.{scenario_number}` for tool-specific tests, `S-I.{number}` for integration tests.
8. **Undo/redo** is not applicable to analysis tools — they are read-only.
9. **Snapshot/visual tests** are not applicable — all tools return JSON data.
10. **Performance benchmarks**: Large-project tests (S-1.13, S-2.11, S-3.10, S-4.13) should be monitored for response times. Target: < 5 seconds for <1000 nodes, < 15 seconds for <5000 resources.

---

*Generated from `server/src/tools/analysis.ts` — 4 tools, 61 test scenarios.*
