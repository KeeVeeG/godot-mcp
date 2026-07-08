# debugging — Test Execution Checklist
> See plan: [debugging_test_plan.md](./debugging_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `set_breakpoint`
- [ ] 1. Set breakpoint with minimum params — happy path
- [ ] 2. Set conditional breakpoint with GDScript expression
- [ ] 3. Set breakpoint on line 1 (boundary)
- [ ] 4. Schema: line = 0 rejected (below min)
- [ ] 5. Schema: negative line number rejected
- [ ] 6. Schema: float line number rejected (not int)
- [ ] 7. Schema: missing script_path rejected
- [ ] 8. Schema: missing line rejected
- [ ] 9. Empty string script_path — Godot error expected
- [ ] 10. Very large line number — Godot error expected
- [ ] 11. Empty condition string — treat as no condition
- [ ] 12. Nonexistent script path — Godot error expected
- [ ] 13. Godot editor not connected — `isError: true`

## Tool: `remove_breakpoint`
- [ ] 1. Remove an existing breakpoint — happy path
- [ ] 2. Remove nonexistent breakpoint — no crash
- [ ] 3. Schema: line = 0 rejected
- [ ] 4. Schema: negative line rejected
- [ ] 5. Schema: float line rejected (not int)
- [ ] 6. Schema: missing script_path rejected
- [ ] 7. Schema: missing line rejected
- [ ] 8. Empty string script_path — Godot error expected
- [ ] 9. Godot editor not connected — `isError: true`

## Tool: `list_breakpoints`
- [ ] 1. List breakpoints after setting 2–3 — happy path
- [ ] 2. List with no breakpoints set — empty result
- [ ] 3. Extra params silently ignored by handler
- [ ] 4. Godot editor not connected — `isError: true`

## Tool: `get_call_stack`
- [ ] 1. Game paused at breakpoint — stack with locals
- [ ] 2. Game not running — descriptive error
- [ ] 3. Game running but not paused — error expected
- [ ] 4. Extra params silently ignored by handler
- [ ] 5. Godot editor not connected — `isError: true`

## Tool: `evaluate_expression`
- [ ] 1. Evaluate in editor context (default) — happy path
- [ ] 2. Evaluate in editor context (explicit) — happy path
- [ ] 3. Evaluate in game context — requires running game
- [ ] 4. Game context — read a node property
- [ ] 5. Schema: missing expression rejected
- [ ] 6. Schema: invalid context value rejected
- [ ] 7. Schema: context is wrong type (number) rejected
- [ ] 8. Empty expression string — no crash
- [ ] 9. Expression with syntax error — Godot error
- [ ] 10. Multi-line expression — evaluate or parse error
- [ ] 11. Game context with game not running — error
- [ ] 12. Godot editor not connected — `isError: true`

## Tool: `step_over`
- [ ] 1. Step over while paused — advances one line
- [ ] 2. Step over a function call — skips call entirely
- [ ] 3. Step over at last line — returns to caller
- [ ] 4. Game not running — descriptive error
- [ ] 5. Game running but not paused — error expected
- [ ] 6. Godot editor not connected — `isError: true`

## Tool: `step_into`
- [ ] 1. Step into a function call — enters function
- [ ] 2. Step into non-function line — like step_over
- [ ] 3. Step into built-in method — like step_over
- [ ] 4. Game not running — descriptive error
- [ ] 5. Game running but not paused — error expected
- [ ] 6. Godot editor not connected — `isError: true`

## Tool: `continue_execution`
- [ ] 1. Continue from breakpoint — game resumes
- [ ] 2. Continue to next breakpoint — pauses again
- [ ] 3. Game not running — error or no-op
- [ ] 4. Game running but not paused — no-op expected
- [ ] 5. Continue after last breakpoint — runs freely
- [ ] 6. Godot editor not connected — `isError: true`

