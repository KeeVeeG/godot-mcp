# profiling — Test Execution Checklist
> See plan: [profiling_test_plan.md](./profiling_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `get_performance_monitors`
- [ ] 1. No filter — return all monitors
- [ ] 2. Single monitor filter (time/fps)
- [ ] 3. Multiple monitor filter (time/fps, memory/static)
- [ ] 4. Process time monitor
- [ ] 5. Physics process time monitor
- [ ] 6. Static memory monitor
- [ ] 7. Static memory max monitor
- [ ] 8. Rendering frame time
- [ ] 9. Physics FPS monitor
- [ ] 10. Active physics objects count
- [ ] 11. Active navigation maps count
- [ ] 12. Empty monitors array
- [ ] 13. Unknown monitor name
- [ ] 14. Mixed valid/invalid monitor names
- [ ] 15. Case sensitivity check
- [ ] 16. Monitors as string (not array)
- [ ] 17. Monitors as number
- [ ] 18. Non-string elements in monitors array
- [ ] 19. Very large monitor name (10k chars)
- [ ] 20. Large number of monitor names (1000)
- [ ] 21. Special characters in monitor name
- [ ] 22. Extra unknown parameters
- [ ] 23. Godot editor not connected
- [ ] 24. FPS value is numeric
- [ ] 25. Memory values are non-negative

---

## Tool: `get_editor_performance`
- [ ] 1. Call with no arguments
- [ ] 2. FPS present and numeric
- [ ] 3. Object counts present
- [ ] 4. Memory fields present
- [ ] 5. Extra params discarded
- [ ] 6. Monitors array ignored
- [ ] 7. Godot editor not connected
- [ ] 8. Rapid consecutive calls
- [ ] 9. All numeric values finite

