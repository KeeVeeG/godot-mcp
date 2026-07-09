# Master Test Plan — Optimized Execution Sequence

**Generated**: 2026-07-08 | **Total plans**: 41 | **Total tools**: ~300+

## Dependency Graph

```
[Setup]          project_creation → project
                   ↓
[Config]         project_config, editor_config, build_config, debug_config,
                 physics_config, audio_config, rendering_config
                   ↓
[Introspection]  node_config, resource_config, platform_specific
                   ↓
[Scene]          scene → scene_config → scene3d, resource, save_load
                   ↓
[Nodes]          node → batch
                   ↓
[Attachments]    script, theme, shader
                   ↓
[Specialized]    animation, physics, particles, navigation, audio, tilemap
                   ↓
[Runtime*]       input, runtime, gameplay_automation, testing,
                 visual_testing, debugging
                   ↓
[Export/Meta]    platform_export, export, profiling, memory_profiling,
                 analysis, editor, addon_management
```

*Runtime layer requires `play_scene` to be running.

---

## Execution Sequence

### Phase 1 — Setup (create project first, everything else needs it)
| # | Plan file | Priority | Depends on |
|---|-----------|----------|------------|
| 1 | `project_creation_test_plan.md` | HIGH | nothing |
| 2 | `project_test_plan.md` | HIGH | project_creation |

### Phase 2 — Config (read/write settings, autonomous)
| # | Plan file | Depends on |
|---|-----------|------------|
| 3 | `project_config_test_plan.md` | project |
| 4 | `editor_config_test_plan.md` | project |
| 5 | `build_config_test_plan.md` | project |
| 6 | `debug_config_test_plan.md` | project |
| 7 | `physics_config_test_plan.md` | project |
| 8 | `audio_config_test_plan.md` | project |
| 9 | `rendering_config_test_plan.md` | project |

### Phase 3 — Introspection (no mutations, read-only queries)
| # | Plan file | Depends on |
|---|-----------|------------|
| 10 | `node_config_test_plan.md` | project |
| 11 | `resource_config_test_plan.md` | project |
| 12 | `platform_specific_test_plan.md` | project |

### Phase 4 — Scene (create/open/manage scenes)
| # | Plan file | Depends on |
|---|-----------|------------|
| 13 | `scene_test_plan.md` | project |
| 14 | `scene_config_test_plan.md` | scene (needs loaded scene) |
| 15 | `scene3d_test_plan.md` | scene (needs 3D scene + root node) |
| 16 | `resource_test_plan.md` | scene (needs scene context for resources) |
| 17 | `save_load_test_plan.md` | scene + gameplay state |

### Phase 5 — Nodes (core scene-tree manipulation)
| # | Plan file | Depends on |
|---|-----------|------------|
| 18 | `node_test_plan.md` | scene (needs loaded scene with nodes) |
| 19 | `batch_test_plan.md` | node (batch operates on existing nodes) |

### Phase 6 — Attachments (script/theme/shader — needs nodes to attach to)
| # | Plan file | Depends on |
|---|-----------|------------|
| 20 | `script_test_plan.md` | node (needs nodes to attach scripts) |
| 21 | `theme_test_plan.md` | node (needs Control nodes for theming) |
| 22 | `shader_test_plan.md` | node (needs MeshInstance/Sprite for shader material) |

### Phase 7 — Specialized Node Types
| # | Plan file | Depends on |
|---|-----------|------------|
| 23 | `animation_test_plan.md` | node + AnimationPlayer node |
| 24 | `physics_test_plan.md` | node + physics body nodes |
| 25 | `particles_test_plan.md` | node + GPUParticles nodes |
| 26 | `navigation_test_plan.md` | node + navigation nodes |
| 27 | `audio_test_plan.md` | node + audio player nodes |
| 28 | `tilemap_test_plan.md` | node + TileMap node |

### Phase 8 — Runtime (needs game running via `play_scene`)
| # | Plan file | Depends on |
|---|-----------|------------|
| 29 | `input_test_plan.md` | running game (play_scene) |
| 30 | `runtime_test_plan.md` | running game |
| 31 | `gameplay_automation_test_plan.md` | running game + input |
| 32 | `testing_test_plan.md` | running game |
| 33 | `visual_testing_test_plan.md` | running game + screenshots |
| 34 | `debugging_test_plan.md` | running game (breakpoints, call stack) |

### Phase 9 — Export & Meta (final pass)
| # | Plan file | Depends on |
|---|-----------|------------|
| 35 | `platform_export_test_plan.md` | project + build_config |
| 36 | `export_test_plan.md` | project + platform_export |
| 37 | `profiling_test_plan.md` | running game (performance counters) |
| 38 | `memory_profiling_test_plan.md` | running game (memory diagnostics) |
| 39 | `analysis_test_plan.md` | project (reads scenes/scripts) |
| 40 | `editor_test_plan.md` | project (screenshots, errors, logs) |
| 41 | `addon_management_test_plan.md` | project (installs/uninstalls addons) |

---

## Parallelization Notes

- **Phases 2, 3, 9** — all plans within the phase can run in parallel (no inter-plan dependencies)
- **Phases 4-8** — sequential within phase, but some plans can be parallelized:
  - [scene, resource, save_load] — parallel after scene basics pass
  - [script, theme, shader] — parallel
  - [animation, physics, particles, navigation, audio, tilemap] — parallel
  - [input, runtime, gameplay_automation, testing, visual_testing, debugging] — parallel after game is running

## Quick-Start (minimal smoke test)

For quick validation, run only these 7 plans in order:
```
project_creation → project → scene → node → script → runtime → export
```

---

## Progress Checklist

- [x] 01. `project_creation_test_plan.md`
- [x] 02. `project_test_plan.md`
- [x] 03. `project_config_test_plan.md`
- [x] 04. `editor_config_test_plan.md`
- [x] 05. `build_config_test_plan.md`
- [x] 06. `debug_config_test_plan.md`
- [x] 07. `physics_config_test_plan.md`
- [ ] 08. `audio_config_test_plan.md`
- [ ] 09. `rendering_config_test_plan.md`
- [ ] 10. `node_config_test_plan.md`
- [ ] 11. `resource_config_test_plan.md`
- [ ] 12. `platform_specific_test_plan.md`
- [ ] 13. `scene_test_plan.md`
- [ ] 14. `scene_config_test_plan.md`
- [ ] 15. `scene3d_test_plan.md`
- [ ] 16. `resource_test_plan.md`
- [ ] 17. `save_load_test_plan.md`
- [ ] 18. `node_test_plan.md`
- [ ] 19. `batch_test_plan.md`
- [ ] 20. `script_test_plan.md`
- [ ] 21. `theme_test_plan.md`
- [ ] 22. `shader_test_plan.md`
- [ ] 23. `animation_test_plan.md`
- [ ] 24. `physics_test_plan.md`
- [ ] 25. `particles_test_plan.md`
- [ ] 26. `navigation_test_plan.md`
- [ ] 27. `audio_test_plan.md`
- [ ] 28. `tilemap_test_plan.md`
- [ ] 29. `input_test_plan.md`
- [ ] 30. `runtime_test_plan.md`
- [ ] 31. `gameplay_automation_test_plan.md`
- [ ] 32. `testing_test_plan.md`
- [ ] 33. `visual_testing_test_plan.md`
- [ ] 34. `debugging_test_plan.md`
- [ ] 35. `platform_export_test_plan.md`
- [ ] 36. `export_test_plan.md`
- [ ] 37. `profiling_test_plan.md`
- [ ] 38. `memory_profiling_test_plan.md`
- [ ] 39. `analysis_test_plan.md`
- [ ] 40. `editor_test_plan.md`
- [ ] 41. `addon_management_test_plan.md`
