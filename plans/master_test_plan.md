# Godot MCP — Master Test Plan

> **Generated:** 2026-07-08  
> **Total test plan files:** 41  
> **Total tools covered:** ~300+ across all modules  
> **Total approximate scenarios:** ~3,165  
> **Execution model:** **STRICTLY SEQUENTIAL — NO PARALLELISM AT ANY LEVEL**

---

## Pre-requisites

Before ANY test runs, the following must be set up:

1. **Godot Editor 4.x** running with the MCP plugin active and connected.
2. **MCP Server** (`server/dist/index.js`) running and WebSocket-connected to the Godot plugin on an auto-negotiated port (6505–6514).
3. **A clean, empty Godot project** open in the editor (created via Phase 1 tests or pre-created).
4. **The MCP runtime autoload** (`mcp_runtime.gd`) must be registered in `project.godot` (added automatically by the plugin).
5. **No other Godot instances** connected to the same MCP server — only ONE editor instance is supported.
6. **All tools must be enabled** in `godot_mcp_config.json` (no disabled tools).
7. **Test environment:** Windows (paths use `C:/` style). For cross-platform, adjust paths accordingly.
8. **Sufficient disk space** for project creation tests (at least 1 GB free).

---

## Execution Rules

1. **STRICTLY SEQUENTIAL:** Every test is numbered from 1 to N. Execute in EXACT numeric order. No exceptions.
2. **ONE TEST AT A TIME:** Wait for each test to complete (success or documented failure) before starting the next.
3. **NO SKIPPING:** Do not skip any test. If a test case is not applicable to the current environment, document it as "N/A — skipped with reason."
4. **STOP ON FIRST UNEXPECTED FAILURE:** If a test produces an unexpected error or failure, STOP. Do not continue. Document the failure and its Test #. Expected failures (e.g., Zod validation errors) that match the expected outcome are NOT stop conditions — they are PASS results.
5. **RECORD RESULT FOR EACH TEST:** For each Test #, record: PASS / FAIL / SKIP (with reason) / N/A. Maintain a running log.
6. **READ-ONLY TESTS FIRST:** Within each file, run read-only scenarios before mutating scenarios to establish baselines.
7. **RESTORE STATE:** After destructive tests, restore project state to a known-good baseline before proceeding to the next file.
8. **NO PARALLELISM AT ANY LEVEL:** Not within files, not between files, not between phases. Every single test scenario runs one at a time, in order, on a single Godot editor instance.

---

## Phase Summary

| Phase | Name | Files | Approx. Scenarios | Depends On |
|-------|------|-------|--------------------|------------|
| 1 | Project Setup & Configuration | 6 | ~490 | Nothing |
| 2 | Scene & Node Management | 5 | ~360 | Phase 1 |
| 3 | Asset & Resource Management | 5 | ~445 | Phases 1–2 |
| 4 | Specialized Systems | 8 | ~625 | Phases 1–3 |
| 5 | Editor & Build | 6 | ~495 | Phases 1–4 |
| 6 | Runtime & Testing | 7 | ~535 | Phases 1–5 |
| 7 | Analysis & Cleanup | 4 | ~214 | Phases 1–6 |
| **TOTAL** | | **41** | **~3,165** | |

---

## Phase 1: Project Setup & Configuration

**Rationale:** These tools bootstrap the Godot project environment. They have zero dependencies on any prior tool output — they can run on a bare Godot editor with no project or on a freshly opened empty project. This phase establishes the project foundation (creation, settings, build configuration, editor preferences, debug settings) that all subsequent phases rely on. The ordering within this phase follows a natural dependency chain: create the project → configure project settings → configure build pipeline → configure editor appearance → configure debug infrastructure. Each step builds on the project state established by the previous step.

### Phase 1 File Order

| Order | File | Tools | Scenarios | Summary |
|-------|------|-------|-----------|---------|
| 1.1 | `project_creation_test_plan.md` | 10 | ~90 | Project creation from scratch/templates, folder scaffolding, git init, README, LICENSE, dependencies setup, structure validation, template listing |
| 1.2 | `project_test_plan.md` | 7 | ~76 | Project metadata queries, filesystem tree browsing, file search, settings read/write, UID ↔ path conversion |
| 1.3 | `project_config_test_plan.md` | 12 | ~124 | Individual settings get/set/reset, complete input map management, autoload singleton configuration and ordering |
| 1.4 | `build_config_test_plan.md` | 8 | ~62 | Build configuration presets (debug/release/development), scripting backend selection, export filters, custom feature tags, debug/optimize options, CLI build command generation |
| 1.5 | `editor_config_test_plan.md` | 8 | ~67 | Editor color theme switching, workspace layout presets, font size adjustment, UI scale factor, layout save/load/reset lifecycle |
| 1.6 | `debug_config_test_plan.md` | 6 | ~82 | Remote debugging enable/disable, profiler settings tuning, error/warning breakpoint configuration, editor log read/clear |

---

## Phase 2: Scene & Node Management

**Rationale:** These tools operate on scenes and nodes within an open project. Phase 1 must complete first to ensure a valid project exists and is properly configured. Scene tools create and manage `.tscn` files; scene config tools manage metadata on those scenes; scene3d tools add 3D elements requiring a scene; node tools manipulate the scene tree; node config tools introspect node types. The order follows the natural workflow: create scenes → configure scene metadata → add 3D scene elements → manipulate scene tree nodes → introspect node type system. This mirrors how a developer would build a project: first create the scene container, then populate it with nodes, then introspect what's possible.

### Phase 2 File Order

| Order | File | Tools | Scenarios | Summary |
|-------|------|-------|-----------|---------|
| 2.1 | `scene_test_plan.md` | 12 | ~81 | Scene tree inspection, raw file content reading, scene CRUD (create/open/delete/save), scene instantiation, play/stop control, main scene designation, loaded scene tracking |
| 2.2 | `scene_config_test_plan.md` | 6 | ~56 | Scene inheritance chain inspection, unique name flag toggling, scene group membership management, root node metadata read/write |
| 2.3 | `scene3d_test_plan.md` | 6 | ~50 | MeshInstance3D with primitive meshes (cube/sphere/cylinder/etc.), Camera3D setup and configuration, directional/omni/spot lighting, WorldEnvironment configuration, GridMap for 3D tiles, StandardMaterial3D/ShaderMaterial assignment |
| 2.4 | `node_test_plan.md` | 17 | ~114 | Core scene-tree manipulation: add/delete/duplicate/move/rename nodes, property read/write on any node, signal connect/disconnect, group membership assignment, editor selection management, Control node anchor presets |
| 2.5 | `node_config_test_plan.md` | 8 | ~69 | Default property values for node types, configuration presets (platformer body, top-down camera, etc.), available node types by category, signal/method/enum/constant introspection, full class hierarchy chains |

---

## Phase 3: Asset & Resource Management

**Rationale:** These tools create and manage project assets (resources, scripts, shaders, themes). They depend on Phases 1–2 because resources must be placed within a valid project structure and may reference nodes or scenes (e.g., attaching scripts to nodes, assigning shader materials to meshes). The order follows from generic to specific: generic resource operations → resource type introspection → scripts (code assets) → shaders (visual assets) → themes (UI styling). Resource tools are the broadest category covering all `.tres`/`.res` file types; resource_config adds type-level metadata queries; scripts, shaders, and themes are specialized resource subtypes with their own CRUD workflows.

### Phase 3 File Order

| Order | File | Tools | Scenarios | Summary |
|-------|------|-------|-----------|---------|
| 3.1 | `resource_test_plan.md` | 10 | ~114 | Resource file read/edit/create/delete/duplicate, preview thumbnail generation, autoload management, resource listing by type, dependency graph inspection, file import with settings |
| 3.2 | `resource_config_test_plan.md` | 6 | ~79 | All registered resource type enumeration, serializable property introspection per type, resource creation from templates, import settings read/update/reimport |
| 3.3 | `script_test_plan.md` | 9 | ~58 | GDScript file listing, reading, creation, editing (text replacement), deletion, node attachment, syntax validation, project-wide text search, open script tracking |
| 3.4 | `shader_test_plan.md` | 9 | ~89 | Shader file create/read/edit/delete, ShaderMaterial creation and node assignment, shader uniform parameter get/set, shader listing, compilation validation |
| 3.5 | `theme_test_plan.md` | 7 | ~105 | Theme resource create/edit/delete, color property setting per control type, constant values, font sizes, StyleBox configurations, full theme override inspection |

---

## Phase 4: Specialized Systems

**Rationale:** These tools configure specialized Godot subsystems that operate on top of the project/scene/resource foundation from Phases 1–3. Each subsystem is largely independent of the others within this phase, but all require a valid project with scenes, nodes, and resources. The ordering groups related pairs together and progresses from temporal/audio systems through spatial/physics to level-design tools: animation (time-based data on nodes) → audio (sound playback) → audio config (audio bus architecture) → physics (collision and forces) → physics config (engine tuning) → particles (visual effects) → navigation (pathfinding) → tilemap (2D level editing). This order ensures that audio buses are configured before audio players are tested, and physics engine settings are applied before physics bodies are created.

### Phase 4 File Order

| Order | File | Tools | Scenarios | Summary |
|-------|------|-------|-----------|---------|
| 4.1 | `animation_test_plan.md` | 10 | ~96 | AnimationPlayer management (list/create/remove animations), track addition, keyframe setting, AnimationTree construction, state machine states/transitions, blend tree configuration, tree parameter control |
| 4.2 | `audio_test_plan.md` | 7 | ~65 | AudioStreamPlayer (2D/3D) node creation, stream resource assignment, playback properties (volume, autoplay, bus routing), audio node info queries, player removal |
| 4.3 | `audio_config_test_plan.md` | 6 | ~60 | Complete audio bus layout management, bus add/remove at specific positions, audio effects (reverb, delay, chorus, compressor, EQ, etc.), bus volume/mute/solo/bypass, full layout inspection |
| 4.4 | `physics_test_plan.md` | 8 | ~92 | Physics body configuration (RigidBody, CharacterBody, StaticBody), collision shape addition (box/sphere/capsule/etc.), collision layer/mask assignment, raycast node setup, physics material creation and assignment |
| 4.5 | `physics_config_test_plan.md` | 8 | ~92 | Gravity vector and magnitude setting, physics simulation tick rate, engine backend selection (default/Jolt), collision layer naming, default linear damping, full physics settings inspection |
| 4.6 | `particles_test_plan.md` | 8 | ~81 | GPUParticles2D/3D node creation, ParticleProcessMaterial property configuration, color gradient setup, visual presets (fire/smoke/sparks/rain/snow), emission shape configuration, velocity curve definition |
| 4.7 | `navigation_test_plan.md` | 10 | ~79 | NavigationRegion2D/3D creation, NavigationAgent2D/3D setup, NavigationLink2D/3D for connecting regions, navmesh baking with parameters, navigation layer/mask settings, pathfinding queries between points |
| 4.8 | `tilemap_test_plan.md` | 11 | ~18 | TileMap cell get/set operations, rectangular region fill, area clearing, TileSet configuration inspection, used cell coordinate listing, GridMap for 3D tile-based level editing |

---

## Phase 5: Editor & Build

**Rationale:** These tools interact with the Godot editor itself (not just the project) and handle build/export workflows. They depend on Phases 1–4 because a fully configured project with assets, scenes, nodes, and specialized systems is needed to meaningfully test editor operations (screenshots, GDScript execution, signal inspection), addon management, exports, and platform configurations. The ordering progresses from editor-level tools through build pipeline to rendering quality: editor operations → addon management → general export → platform-specific export → platform-specific settings → rendering configuration. This ensures the editor is in a known state before addon operations modify it, and project content is complete before export tests attempt to build it.

### Phase 5 File Order

| Order | File | Tools | Scenarios | Summary |
|-------|------|-------|-----------|---------|
| 5.1 | `editor_test_plan.md` | 9 | ~60 | Editor screenshot capture, arbitrary GDScript execution in editor context, error/warning retrieval, output log reading, plugin/project reload, signal connection inspection, node selection management |
| 5.2 | `addon_management_test_plan.md` | 5 | ~45 | Addon listing with versions/status, installation (Asset Library/git/local), uninstallation with file cleanup, version updates, addon configuration settings |
| 5.3 | `export_test_plan.md` | 7 | ~72 | Export preset listing/creation/deletion, project export for specific platforms, export validation checks, available template listing, export information queries, platform export with presets |
| 5.4 | `platform_export_test_plan.md` | 6 | ~66 | Platform-specific export operations, per-platform validation, export template availability, platform preset creation, exported build execution and output capture, detailed platform export validation |
| 5.5 | `platform_specific_test_plan.md` | 6 | ~146 | iOS configuration (bundle ID, team ID, code signing), Android configuration (package name, keystore, permissions), Web/HTML5 configuration (canvas resize, threading, PWA), platform capability queries, build validation per platform |
| 5.6 | `rendering_config_test_plan.md` | 9 | ~146 | Rendering method selection (forward_plus/mobile/gl_compatibility), quality presets, anti-aliasing (MSAA/FXAA/TAA), shadow quality, global illumination quality, viewport dimensions and stretch mode, window size and vsync, GPU statistics and rendering info |

---

## Phase 6: Runtime & Testing

**Rationale:** These tools ALL require the game to be running (`godot_play_scene`). They cannot run before Phase 5 because a fully built project with scenes, nodes, physics, navigation, animations, audio, and shaders is needed for meaningful runtime testing. The ordering within this phase is critical because later tools depend on primitives validated by earlier tools: runtime introspection (scene tree, properties, GDScript exec) → input simulation (keyboard, mouse, actions) → gameplay automation (scripted scenarios, recording) → save/load (state persistence) → debugging (breakpoints, call stack) → memory profiling (leaks, object counts) → performance profiling (FPS, monitors). Each step adds capabilities that the next step uses.

**CRITICAL — Game must be running for ALL Phase 6 tests:** Before starting Test #2435, call `godot_play_scene`. Keep the game running through Test #2970. Use `godot_stop_scene` only after all Phase 6 tests are complete.

### Phase 6 File Order

| Order | File | Tools | Scenarios | Summary |
|-------|------|-------|-----------|---------|
| 6.1 | `runtime_test_plan.md` | 19 | ~166 | Runtime scene tree queries, game node property get/set, GDScript execution in running game, viewport screenshot and frame capture, property monitoring over time, session recording, node search by script and proximity, UI element finding and clicking, signal emission watching |
| 6.2 | `input_test_plan.md` | 7 | ~87 | Keyboard key simulation (press/release/echo), mouse click at screen position, mouse movement (absolute/relative), input action simulation from InputMap, sequenced input event chains with timing, input action listing |
| 6.3 | `gameplay_automation_test_plan.md` | 7 | ~80 | Scripted gameplay scenario execution (input/wait/move/click/assert steps), recording sessions with input capture, replay at variable speed, test character creation at world positions, character navigation (direct and pathfinding), multi-condition game state assertions, event waiting with timeouts |
| 6.4 | `save_load_test_plan.md` | 5 | ~67 | Game state saving to numbered slots with metadata, state loading from save files, save file listing with metadata, save file deletion, save state comparison with diff output |
| 6.5 | `debugging_test_plan.md` | 8 | ~61 | Breakpoint placement (with optional conditions), breakpoint removal, all breakpoints listing, call stack inspection with local variables, GDScript expression evaluation in paused context, step over, step into, continue execution |
| 6.6 | `memory_profiling_test_plan.md` | 5 | ~41 | Detailed memory usage breakdown by category, object creation tracking for specific classes, potential memory leak detection in scene graph, live object count by class, forced garbage collection with freed memory report |
| 6.7 | `profiling_test_plan.md` | 2 | ~34 | Performance monitor values (FPS, memory, physics, rendering, navigation), editor performance metrics snapshot |

---

## Phase 7: Analysis & Cleanup

**Rationale:** These tools analyze the project state and run automated tests and bulk operations. They depend on ALL previous phases because they need a fully populated project with scenes, nodes, assets, and runtime test data to produce meaningful analysis results. The ordering progresses from static analysis through automated testing to cross-cutting bulk operations: project health analysis → automated test execution → visual regression testing → batch operations. Analysis tools provide a final health check; testing tools validate the system end-to-end; visual testing captures the final state; batch tools perform cross-scene operations that may be destructive.

### Phase 7 File Order

| Order | File | Tools | Scenarios | Summary |
|-------|------|-------|-----------|---------|
| 7.1 | `analysis_test_plan.md` | 4 | ~16 | Scene complexity analysis (node count, depth, resource usage), signal flow mapping across scenes, unused resource detection, project-wide statistics (file counts, sizes, types), circular dependency detection |
| 7.2 | `testing_test_plan.md` | 5 | ~70 | Multi-step test scenario execution, node property state assertions, on-screen text assertions, entity spawning stress tests with performance measurement, aggregated session test reports |
| 7.3 | `visual_testing_test_plan.md` | 6 | ~67 | Screenshots with scene context metadata, pixel-by-pixel screenshot comparison with mismatch percentage, visual baseline assertion within thresholds, multi-frame recording for regression testing, visual diff report aggregation, baseline management |
| 7.4 | `batch_test_plan.md` | 8 | ~61 | Find all nodes by type/script/group, signal connection tracing, batch property setting on all nodes of a type, cross-scene property changes (destructive, requires `confirm_no_undo`), node/script reference finding, scene dependency resolution, circular dependency detection |

---

## Global Sequential Test Numbering

The following table assigns sequential test number ranges to each test plan file. Within each file, tests are numbered according to the file's own internal ordering. The global Test # is computed as:

**Test # = (sum of all scenarios in all preceding files) + (scenario number within the current file)**

For precise per-scenario details (individual scenario names, parameters, expected results), refer to each file's individual test plan. The counts below represent the approximate number of individually numbered test scenarios in each file.

| Global Test # Range | Phase | File | Scenarios | Description |
|---------------------|-------|------|-----------|-------------|
| 1–90 | 1 | `project_creation_test_plan.md` | 90 | Project creation, templates, scaffolding, git, README, LICENSE, deps, validation, template listing |
| 91–166 | 1 | `project_test_plan.md` | 76 | Project metadata, filesystem tree, file search, settings get/set, UID conversion |
| 167–290 | 1 | `project_config_test_plan.md` | 124 | Individual settings, input map management, autoload configuration |
| 291–352 | 1 | `build_config_test_plan.md` | 62 | Build presets, scripting backend, export filter, features, debug options, build commands |
| 353–419 | 1 | `editor_config_test_plan.md` | 67 | Editor theme, layout, font size, UI scale, layout save/load/reset |
| 420–501 | 1 | `debug_config_test_plan.md` | 82 | Remote debug, profiler settings, error handling, editor log read/clear |
| 502–582 | 2 | `scene_test_plan.md` | 81 | Scene CRUD, play/stop, main scene, loaded scenes |
| 583–638 | 2 | `scene_config_test_plan.md` | 56 | Scene inheritance, unique names, groups, metadata |
| 639–688 | 2 | `scene3d_test_plan.md` | 50 | 3D meshes, cameras, lighting, environment, GridMap, materials |
| 689–802 | 2 | `node_test_plan.md` | 114 | Node CRUD, properties, signals, groups, selection, anchors |
| 803–871 | 2 | `node_config_test_plan.md` | 69 | Node type introspection, presets, class hierarchy |
| 872–985 | 3 | `resource_test_plan.md` | 114 | Resource CRUD, previews, autoloads, dependencies, import |
| 986–1064 | 3 | `resource_config_test_plan.md` | 79 | Resource types, properties, templates, import settings |
| 1065–1122 | 3 | `script_test_plan.md` | 58 | Script list/read/create/edit/delete, attach, validate, search |
| 1123–1211 | 3 | `shader_test_plan.md` | 89 | Shader CRUD, materials, uniforms, validation |
| 1212–1316 | 3 | `theme_test_plan.md` | 105 | Theme CRUD, colors, constants, fonts, StyleBoxes |
| 1317–1412 | 4 | `animation_test_plan.md` | 96 | AnimationPlayer, AnimationTree, state machines, keyframes |
| 1413–1477 | 4 | `audio_test_plan.md` | 65 | AudioStreamPlayer (2D/3D), streams, playback, bus routing |
| 1478–1537 | 4 | `audio_config_test_plan.md` | 60 | Audio buses, effects, volume, mute, solo |
| 1538–1629 | 4 | `physics_test_plan.md` | 92 | Physics bodies, collision shapes, layers, raycasts, materials |
| 1630–1721 | 4 | `physics_config_test_plan.md` | 92 | Gravity, FPS, engine, layers, damping |
| 1722–1802 | 4 | `particles_test_plan.md` | 81 | Particle creation, materials, gradients, presets, shapes, curves |
| 1803–1881 | 4 | `navigation_test_plan.md` | 79 | Nav regions, agents, links, navmesh bake, pathfinding |
| 1882–1899 | 4 | `tilemap_test_plan.md` | 18 | TileMap cells, fill, clear, TileSet, GridMap |
| 1900–1959 | 5 | `editor_test_plan.md` | 60 | Editor screenshots, GDScript exec, errors, log, signals, selection |
| 1960–2004 | 5 | `addon_management_test_plan.md` | 45 | Addon list/install/uninstall/update/configure |
| 2005–2076 | 5 | `export_test_plan.md` | 72 | Export presets, project export, validation, templates |
| 2077–2142 | 5 | `platform_export_test_plan.md` | 66 | Platform-specific export, validation, run builds |
| 2143–2288 | 5 | `platform_specific_test_plan.md` | 146 | iOS/Android/Web settings, capabilities |
| 2289–2434 | 5 | `rendering_config_test_plan.md` | 146 | Renderer, quality, AA, shadows, GI, viewport, window, GPU |
| 2435–2600 | 6 | `runtime_test_plan.md` | 166 | Scene tree, properties, execute GDScript, screenshots, frames, signals |
| 2601–2687 | 6 | `input_test_plan.md` | 87 | Keyboard, mouse, input actions, sequences |
| 2688–2767 | 6 | `gameplay_automation_test_plan.md` | 80 | Scenarios, recording, replay, characters, navigation, assertions |
| 2768–2834 | 6 | `save_load_test_plan.md` | 67 | Save/load, list/delete saves, compare states |
| 2835–2895 | 6 | `debugging_test_plan.md` | 61 | Breakpoints, call stack, expressions, stepping |
| 2896–2936 | 6 | `memory_profiling_test_plan.md` | 41 | Memory usage, object tracking, leaks, GC |
| 2937–2970 | 6 | `profiling_test_plan.md` | 34 | Performance monitors, editor performance |
| 2971–2986 | 7 | `analysis_test_plan.md` | 16 | Scene complexity, signal flow, unused resources, statistics |
| 2987–3056 | 7 | `testing_test_plan.md` | 70 | Test scenarios, assertions, stress tests, reports |
| 3057–3123 | 7 | `visual_testing_test_plan.md` | 67 | Screenshots, pixel compare, baselines, visual diff |
| 3124–3184 | 7 | `batch_test_plan.md` | 61 | Find by type/script/group, cross-scene sets, references, dependencies |

> **Note:** Scenario counts are approximate. The individual test plan files contain the authoritative per-scenario breakdowns with exact scenario names, parameters, and expected results. When executing, follow the internal ordering within each individual plan file, and apply global numbers sequentially. The counts above were extracted from file structure analysis; verify against actual file content before execution.

---

## Execution Checklist

```
[ ] Pre-requisites verified (Godot running, MCP connected, clean project open)
[ ] ===== PHASE 1: Project Setup & Configuration =====
[ ]   project_creation   (Tests 1-90)
[ ]   project            (Tests 91-166)
[ ]   project_config     (Tests 167-290)
[ ]   build_config       (Tests 291-352)
[ ]   editor_config      (Tests 353-419)
[ ]   debug_config       (Tests 420-501)
[ ] ===== PHASE 2: Scene & Node Management =====
[ ]   scene              (Tests 502-582)
[ ]   scene_config       (Tests 583-638)
[ ]   scene3d            (Tests 639-688)
[ ]   node               (Tests 689-802)
[ ]   node_config        (Tests 803-871)
[ ] ===== PHASE 3: Asset & Resource Management =====
[ ]   resource           (Tests 872-985)
[ ]   resource_config    (Tests 986-1064)
[ ]   script             (Tests 1065-1122)
[ ]   shader             (Tests 1123-1211)
[ ]   theme              (Tests 1212-1316)
[ ] ===== PHASE 4: Specialized Systems =====
[ ]   animation          (Tests 1317-1412)
[ ]   audio              (Tests 1413-1477)
[ ]   audio_config       (Tests 1478-1537)
[ ]   physics            (Tests 1538-1629)
[ ]   physics_config     (Tests 1630-1721)
[ ]   particles          (Tests 1722-1802)
[ ]   navigation         (Tests 1803-1881)
[ ]   tilemap            (Tests 1882-1899)
[ ] ===== PHASE 5: Editor & Build =====
[ ]   editor             (Tests 1900-1959)
[ ]   addon_management   (Tests 1960-2004)
[ ]   export             (Tests 2005-2076)
[ ]   platform_export    (Tests 2077-2142)
[ ]   platform_specific  (Tests 2143-2288)
[ ]   rendering_config   (Tests 2289-2434)
[ ] ===== PHASE 6: Runtime & Testing [GAME MUST BE RUNNING] =====
[ ]   >>> CALL godot_play_scene BEFORE Test 2435 <<<
[ ]   runtime            (Tests 2435-2600)
[ ]   input              (Tests 2601-2687)
[ ]   gameplay_automation(Tests 2688-2767)
[ ]   save_load          (Tests 2768-2834)
[ ]   debugging          (Tests 2835-2895)
[ ]   memory_profiling   (Tests 2896-2936)
[ ]   profiling          (Tests 2937-2970)
[ ]   >>> CALL godot_stop_scene AFTER Test 2970 <<<
[ ] ===== PHASE 7: Analysis & Cleanup =====
[ ]   analysis           (Tests 2971-2986)
[ ]   testing            (Tests 2987-3056)
[ ]   visual_testing     (Tests 3057-3123)
[ ]   batch              (Tests 3124-3184)
[ ] ===== COMPLETE =====
[ ] All ~3,165 tests executed. Final report generated.
```

---

## Notes

1. **Scenario counts are approximate** — the individual test plan files are the authoritative source for exact per-file scenario counts and details. The counts above were extracted programmatically from file structure. Verify against actual files before execution and adjust the global numbering if needed.

2. **Runtime phase (6) requires special handling** — the game must be running for ALL tests in this phase. Start the game before Test 2435 and keep it running through Test 2970. Use `godot_play_scene` to start and `godot_stop_scene` to stop. If the game crashes mid-phase, restart it and resume from the last completed test.

3. **State restoration between files** — after completing each file's tests, restore the project to a known-good state before proceeding to the next file. This is especially important for destructive tools (e.g., input map replacement, theme switching, layout reset).

4. **Cross-tool and integration scenarios** — some files contain cross-tool integration scenarios at the end. These test interactions between multiple tools within the same module. Execute these AFTER all individual tool scenarios in the file, as they depend on state established by earlier scenarios.

5. **Zod validation tests** — tests that only validate schema (invalid types, missing required params, out-of-range values) produce errors at the Zod layer before reaching Godot. These technically don't require Godot connectivity, but for consistency, run everything with Godot connected.

6. **Test result log format:**
   ```
   Test #<number> | Phase <N>/<filename> | <scenario identifier> | PASS/FAIL/SKIP/N/A | <optional notes>
   ```

7. **Expected failures are NOT stop conditions** — if a test expects a Zod validation error or a Godot-side rejection, and that error occurs as documented, the test is a PASS. Only unexpected errors should trigger the "stop on first failure" rule.

8. **Destructive tool caution** — `batch_test_plan.md` contains `cross_scene_set_property` which requires `confirm_no_undo: true` and irreversibly modifies multiple scene files. Ensure you are working on a disposable project copy before running these tests.
