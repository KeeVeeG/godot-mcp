# debug_config — Test Execution Checklist
> See plan: [debug_config_test_plan.md](./debug_config_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `get_debug_settings`
- [ ] 1. Read current debug settings with no arguments
- [ ] 2. Call with explicit empty input object `{}`
- [ ] 3. Call with irrelevant extra keys

## Tool: `set_remote_debug`
- [ ] 1. Enable remote debug with defaults (host/port defaulted)
- [ ] 2. Enable with custom host and custom port
- [ ] 3. Enable with custom host, default port
- [ ] 4. Enable with custom port, default host
- [ ] 5. Disable remote debugging with `enabled: false`
- [ ] 6. Disable remote debug with host/port still specified
- [ ] 7. Use IPv6 loopback `::1` as host
- [ ] 8. Use FQDN hostname
- [ ] 9. Use port=1 (low boundary, privileged port)
- [ ] 10. Use port=65535 (high boundary, valid max)
- [ ] 11. Missing required `enabled` parameter
- [ ] 12. `enabled` as non-boolean string `"true"`
- [ ] 13. `enabled` as number `1`
- [ ] 14. `host` as number instead of string
- [ ] 15. `host` as empty string
- [ ] 16. `port` as float `6007.5`
- [ ] 17. `port` as string `"6007"`
- [ ] 18. `port` as negative number `-1`
- [ ] 19. `port` as zero
- [ ] 20. `port` exceeds max `65536`
- [ ] 21. `port` as huge value `999999`

## Tool: `set_profiler_settings`
- [ ] 1. Set `max_functions` only to 256
- [ ] 2. Set `max_timestamp_query_elements` only to 512
- [ ] 3. Set both fields simultaneously
- [ ] 4. `max_functions` at documented minimum (16)
- [ ] 5. `max_functions` at documented maximum (512)
- [ ] 6. Call with no parameters (empty, no-op)
- [ ] 7. `max_functions` below documented min (0)
- [ ] 8. `max_functions` above documented max (1024)
- [ ] 9. `max_functions` negative (-1)
- [ ] 10. `max_functions` as float (128.5)
- [ ] 11. `max_timestamp_query_elements` as float (256.7)
- [ ] 12. `max_functions` as string `"128"`
- [ ] 13. `max_timestamp_query_elements` as string `"256"`
- [ ] 14. `max_timestamp_query_elements` is zero
- [ ] 15. `max_timestamp_query_elements` negative (-1)
- [ ] 16. `max_timestamp_query_elements` very large (999999)
- [ ] 17. Irrelevant extra keys silently ignored

## Tool: `set_error_handling`
- [ ] 1. Set `break_on_error` only to true
- [ ] 2. Set `break_on_error` only to false
- [ ] 3. Set `break_on_warning` only to true
- [ ] 4. Set `break_on_warning` only to false
- [ ] 5. Set both flags simultaneously (both true)
- [ ] 6. Set both flags simultaneously (both false)
- [ ] 7. Set both with mixed values (error true, warning false)
- [ ] 8. Call with no parameters (empty, no-op)
- [ ] 9. `break_on_error` as string `"true"`
- [ ] 10. `break_on_error` as number `1`
- [ ] 11. `break_on_warning` as string `"false"`
- [ ] 12. `break_on_warning` as number `0`
- [ ] 13. Irrelevant extra keys silently ignored

## Tool: `get_editor_log`
- [ ] 1. Get log with no filter, default limit 50
- [ ] 2. Filter by `error` only
- [ ] 3. Filter by `warning` only
- [ ] 4. Filter by `info` only
- [ ] 5. Custom limit small (10)
- [ ] 6. Custom limit large (500, maximum)
- [ ] 7. Filter `error` + limit 5 combined
- [ ] 8. Limit=1 (minimum bound)
- [ ] 9. Empty log after calling `clear_editor_log`
- [ ] 10. Invalid filter enum value `"verbose"`
- [ ] 11. Filter as empty string
- [ ] 12. Filter as number
- [ ] 13. Limit below minimum (0)
- [ ] 14. Limit negative (-5)
- [ ] 15. Limit above maximum (501)
- [ ] 16. Limit as float (25.5)
- [ ] 17. Limit as string `"50"`
- [ ] 18. Filter valid + limit as string (both)

## Tool: `clear_editor_log`
- [ ] 1. Clear the log with no arguments
- [ ] 2. Call with explicit empty input object `{}`
- [ ] 3. Clear already-empty log (idempotent, second call)
- [ ] 4. Clear, then generate entries, then verify
- [ ] 5. Call with irrelevant extra keys

## Cross-Tool Integration
- [ ] 1. Full debug settings lifecycle (set all → verify → disable remote → verify)
- [ ] 2. Log read + clear cycle (read → clear → verify empty → generate error → verify)
- [ ] 3. Profiler settings boundary sequence (min → max → mid-range, verify each)
- [ ] 4. Error handling toggle sequence (both off → error on → warning on → no-op → verify)
- [ ] 5. Log filter enumeration (error, warning, info, unfiltered — verify types)

