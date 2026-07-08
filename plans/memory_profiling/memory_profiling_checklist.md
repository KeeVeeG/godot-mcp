# memory_profiling — Test Execution Checklist
> See plan: [memory_profiling_test_plan.md](./memory_profiling_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `get_memory_usage`
- [ ] 1. Happy path — call with empty params
- [ ] 2. Memory values are non-negative
- [ ] 3. Memory values sum consistently
- [ ] 4. Call with extra params — ignored by handler
- [ ] 5. Godot editor not connected

## Tool: `track_object_creation`
- [ ] 1. Happy path — track with minimum params
- [ ] 2. Happy path — track with explicit duration
- [ ] 3. Happy path — track a different class
- [ ] 4. Happy path — track with min duration (boundary)
- [ ] 5. Happy path — track with max duration (boundary)
- [ ] 6. Schema validation — duration = 0 (below minimum)
- [ ] 7. Schema validation — duration = negative
- [ ] 8. Schema validation — duration = 61 (above maximum)
- [ ] 9. Schema validation — duration is a float
- [ ] 10. Schema validation — missing required class_name
- [ ] 11. Schema validation — class_name is empty string
- [ ] 12. Edge case — nonexistent class name
- [ ] 13. Edge case — track built-in engine class
- [ ] 14. Edge case — extra unknown params
- [ ] 15. Godot editor not connected

## Tool: `find_memory_leaks`
- [ ] 1. Happy path — call with empty params
- [ ] 2. Project with known orphan nodes
- [ ] 3. Clean project with no leaks
- [ ] 4. Call with extra params — ignored by handler
- [ ] 5. Godot editor not connected

## Tool: `get_object_count`
- [ ] 1. Happy path — get total object count (no filter)
- [ ] 2. Happy path — filter by specific class name
- [ ] 3. Happy path — filter by another class
- [ ] 4. Happy path — filter by engine base class
- [ ] 5. Comparison consistency — filtered <= unfiltered
- [ ] 6. Filter by nonexistent class name
- [ ] 7. Filter by empty string
- [ ] 8. Call with extra unknown params
- [ ] 9. Schema validation — class_name is not a string
- [ ] 10. Schema validation — class_name is boolean
- [ ] 11. Godot editor not connected

## Tool: `force_garbage_collection`
- [ ] 1. Happy path — call with empty params
- [ ] 2. GC after creating and releasing many objects
- [ ] 3. Two consecutive GC calls
- [ ] 4. Call with extra params — ignored by handler
- [ ] 5. Godot editor not connected

## Cross-Tool Integration
- [ ] 1. track → get_object_count → verify consistency
- [ ] 2. get_memory_usage → force_gc → get_memory_usage
- [ ] 3. find_memory_leaks → force_gc → find_memory_leaks
- [ ] 4. get_memory_usage response has all expected categories

