# visual_testing — Test Execution Checklist
> See plan: [visual_testing_test_plan.md](./visual_testing_test_plan.md)

## Prerequisites verified
- [ ] All resources from prereqs.md are ready
- [ ] Godot editor connected
- [ ] MCP server running
- [ ] Clean project state (no leftover from previous tests)

---

## Tool: `take_screenshot_with_context`
- [ ] 1. Happy path: min params, screenshot with context only
- [ ] 2. include_props=true, no include_nodes, no property data
- [ ] 3. Full context: include_props=true with include_nodes
- [ ] 4. include_nodes given but include_props=false (default)
- [ ] 5. Edge case: empty string for name
- [ ] 6. Edge case: name with slashes / path-like chars
- [ ] 7. Missing required name param — Zod error
- [ ] 8. include_nodes with non-existent node path

## Tool: `compare_screenshots`
- [ ] 1. Identical screenshots: matched=true, mismatch near 0
- [ ] 2. Different screenshots: matched=false, mismatch > threshold
- [ ] 3. Default threshold (omit param) → uses 0.01
- [ ] 4. threshold=0: pixel-perfect match required
- [ ] 5. threshold=1: always matched (100% allowed)
- [ ] 6. threshold=-0.1: below min — Zod error
- [ ] 7. threshold=1.5: above max — Zod error
- [ ] 8. Missing required baseline param — Zod error
- [ ] 9. Missing required current param — Zod error
- [ ] 10. Baseline file does not exist
- [ ] 11. Current file does not exist
- [ ] 12. Different resolution screenshots

## Tool: `assert_visual_match`
- [ ] 1. Matching screenshot: passed=true, low mismatch
- [ ] 2. Non-matching screenshot: passed=false, high mismatch
- [ ] 3. Default threshold (omit param) → uses 0.01
- [ ] 4. threshold=0: strict pixel-perfect match
- [ ] 5. threshold=0.5: lenient, up to 50% allowed
- [ ] 6. threshold below 0 — Zod error
- [ ] 7. threshold above 1 — Zod error
- [ ] 8. Missing required name param — Zod error
- [ ] 9. Missing required baseline param — Zod error
- [ ] 10. Name never taken via take_screenshot_with_context
- [ ] 11. Baseline resolves against baselines directory
- [ ] 12. Baseline file does not exist

## Tool: `record_visual_regression`
- [ ] 1. Happy path: min params, default 10 frames @ 0.5s
- [ ] 2. Custom frames=5, interval=1.0
- [ ] 3. frames=1: minimum boundary
- [ ] 4. frames=100: maximum boundary
- [ ] 5. interval=0.1: minimum boundary
- [ ] 6. interval=10: maximum boundary
- [ ] 7. frames=0: below min — Zod error
- [ ] 8. frames=101: above max — Zod error
- [ ] 9. frames=5.5: float, not integer — Zod error
- [ ] 10. interval=0.05: below min — Zod error
- [ ] 11. interval=15: above max — Zod error
- [ ] 12. interval=0: below min — Zod error
- [ ] 13. Missing required test_name — Zod error
- [ ] 14. Edge case: empty test_name string
- [ ] 15. 100 frames × 10s interval (~16.7 min)

## Tool: `get_visual_diff_report`
- [ ] 1. No assertions run yet — empty report
- [ ] 2. After single passing assertion
- [ ] 3. After mixed assertions (pass + fail)
- [ ] 4. After all failing assertions
- [ ] 5. Called with extra/unexpected params (robustness)
- [ ] 6. Called twice, same session — idempotent

## Tool: `set_visual_baseline`
- [ ] 1. Set new baseline with a new name
- [ ] 2. Overwrite existing baseline with new screenshot
- [ ] 3. Baseline with full res:// path
- [ ] 4. Name with spaces, dashes, underscores
- [ ] 5. Missing required name param — Zod error
- [ ] 6. Missing required screenshot_path — Zod error
- [ ] 7. screenshot_path does not exist
- [ ] 8. Wrong extension: .gd instead of image
- [ ] 9. Edge case: empty name string
- [ ] 10. Edge case: empty screenshot_path
- [ ] 11. E2E: set 2 baselines, verify via assert_visual_match

## Cross-Tool Integration Scenarios
- [ ] 1. Full workflow: take → set baseline → take → assert → report
- [ ] 2. Record frames → set baselines → assert → report
- [ ] 3. Direct compare_screenshots without baseline registry

