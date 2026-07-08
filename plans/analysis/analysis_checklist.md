# analysis — Test Execution Checklist
> See plan: [analysis_test_plan.md](./analysis_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `analyze_scene_complexity`
- [ ] 1. Basic happy path with empty params
- [ ] 2. Call with extra params forwarded to Godot
- [ ] 3. No scene open in Godot
- [ ] 4. Godot editor not connected

## Tool: `analyze_signal_flow`
- [ ] 1. Basic happy path with empty params
- [ ] 2. Scene with no signal connections
- [ ] 3. Call with extra params
- [ ] 4. Godot editor not connected

## Tool: `find_unused_resources`
- [ ] 1. Basic happy path with empty params
- [ ] 2. Project with no unused resources
- [ ] 3. Call with extra params
- [ ] 4. Godot editor not connected

## Tool: `get_project_statistics`
- [ ] 1. Basic happy path with empty params
- [ ] 2. Call with extra params ignored
- [ ] 3. Empty or new project
- [ ] 4. Godot editor not connected

