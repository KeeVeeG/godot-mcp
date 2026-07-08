# Analysis Tools — Test Plan

> **Source file:** `server/src/tools/analysis.ts`
> **Godot bridge endpoints:** `analysis/scene_complexity`, `analysis/signal_flow`, `analysis/unused_resources`, `analysis/statistics`
> **Generated:** 2026-07-08

---

## Overview

All 4 tools in this module have an **empty input schema** (`inputSchema: {}`) — they accept no required or optional parameters. Each tool forwards the call to a Godot bridge endpoint and returns the raw JSON result from the Godot editor.

| # | Tool Name | Bridge Method | Handler Pattern |
|---|-----------|--------------|-----------------|
| 1 | `analyze_scene_complexity` | `analysis/scene_complexity` | `(args) => callGodot(bridge, ..., args)` |
| 2 | `analyze_signal_flow` | `analysis/signal_flow` | `(args) => callGodot(bridge, ..., args)` |
| 3 | `find_unused_resources` | `analysis/unused_resources` | `(args) => callGodot(bridge, ..., args)` |
| 4 | `get_project_statistics` | `analysis/statistics` | `() => callGodot(bridge, ...)` *(ignores args)* |

---

## Tool: `analyze_scene_complexity`

**Description:** Analyze a scene's complexity (node count, depth, resource usage)

**Handler:**
```typescript
async (args) => callGodot(bridge, 'analysis/scene_complexity', args as Record<string, unknown>)
```

**Parameters:** None (empty schema). Any extra params are forwarded to Godot.

---

### Test Scenarios

#### Scenario 1: Basic happy path — call with empty params
- **Description:** Call with no arguments on a project with an open scene. Should return scene complexity analysis data.
- **Params:** `{}`
- **Expected result:** JSON object with scene complexity metrics (node count, depth, resource usage). Not an error.
- **Notes:** Requires a scene to be open in the Godot editor for meaningful results.

#### Scenario 2: Call with extra/unexpected params — forwarded to Godot
- **Description:** Pass arbitrary extra properties. The handler forwards them to Godot, which may ignore or use them.
- **Params:** `{ "verbose": true }`
- **Expected result:** Same as Scenario 1, or possibly enriched output if Godot respects the param. Should not error.
- **Notes:** Since the schema is empty, the server does NOT validate/coerce/block extra params over the MCP stdio channel, but the stdio protocol layer may strip unknown fields.

#### Scenario 3: No scene open in Godot
- **Description:** Call when no scene is open in the editor.
- **Params:** `{}`
- **Expected result:** May return an empty/null analysis or an error message from Godot. Should be handled gracefully with a descriptive error.
- **Notes:** Depends on Godot plugin behavior.

#### Scenario 4: Godot editor not connected
- **Description:** Call when the bridge is disconnected (Godot editor not running).
- **Params:** `{}`
- **Expected result:** Error result with `isError: true`, containing a message like "Godot request failed: ...".
- **Notes:** Covered by the `callGodot` error handler in `server.ts`.

---

## Tool: `analyze_signal_flow`

**Description:** Analyze signal flow and connections in a scene

**Handler:**
```typescript
async (args) => callGodot(bridge, 'analysis/signal_flow', args as Record<string, unknown>)
```

**Parameters:** None (empty schema).

---

### Test Scenarios

#### Scenario 1: Basic happy path — call with empty params
- **Description:** Call on a scene that has signal connections between nodes.
- **Params:** `{}`
- **Expected result:** JSON describing signal connections in the current scene (source node, signal name, target node, method). Not an error.
- **Notes:** Requires the current scene to have at least one signal connection for meaningful output.

#### Scenario 2: Scene with no signal connections
- **Description:** Call on a scene with no connected signals (e.g., empty scene or scene with only static nodes).
- **Params:** `{}`
- **Expected result:** JSON with an empty connection list (e.g., `[]` or `{}`). Should not error.
- **Notes:** Validates graceful handling of zero-signal scenes.

#### Scenario 3: Call with extra params
- **Description:** Pass unexpected params to verify forwarding behavior.
- **Params:** `{ "filter": "connected" }`
- **Expected result:** Same behavior as Scenario 1. Should not cause a server-side error.
- **Notes:** Extra params forwarded via `args` cast; Godot may ignore them.

#### Scenario 4: Godot editor not connected
- **Description:** Call when bridge is disconnected.
- **Params:** `{}`
- **Expected result:** Error `"Godot request failed: ..."` with `isError: true`.

---

## Tool: `find_unused_resources`

**Description:** Find resources in the project that are not referenced by any scene or script

**Handler:**
```typescript
async (args) => callGodot(bridge, 'analysis/unused_resources', args as Record<string, unknown>)
```

**Parameters:** None (empty schema).

---

### Test Scenarios

#### Scenario 1: Basic happy path — call with empty params
- **Description:** Call on a project that has some unused resources (orphaned `.tres`, `.gd`, textures not referenced).
- **Params:** `{}`
- **Expected result:** JSON array or object listing unreferenced resource paths. Not an error.
- **Notes:** Tests the core analysis pipeline. May take longer on large projects.

#### Scenario 2: Project with no unused resources
- **Description:** Call on a clean project where every resource is referenced.
- **Params:** `{}`
- **Expected result:** JSON with an empty list (e.g., `[]`). Should not error.
- **Notes:** Validates the "nothing found" case is handled correctly.

#### Scenario 3: Call with extra params
- **Description:** Pass arbitrary extra properties.
- **Params:** `{ "include_builtins": false }`
- **Expected result:** Should not error. Either same output or filtered if Godot respects the param.
- **Notes:** Forwarded to Godot; test verifies no server-side crash.

#### Scenario 4: Godot editor not connected
- **Description:** Call when bridge is disconnected.
- **Params:** `{}`
- **Expected result:** Error `"Godot request failed: ..."` with `isError: true`.

---

## Tool: `get_project_statistics`

**Description:** Get project statistics (file counts, sizes, node types, script languages, etc.)

**Handler:**
```typescript
async () => callGodot(bridge, 'analysis/statistics')
```

**Parameters:** None (empty schema). **Important:** Unlike the other 3 tools, this handler does NOT forward `args` — it passes an implicit empty object to `callGodot` (which defaults to `{}`).

---

### Test Scenarios

#### Scenario 1: Basic happy path — call with empty params
- **Description:** Call on an existing Godot project.
- **Params:** `{}`
- **Expected result:** JSON object with project-wide statistics: file count, total sizes, breakdowns by node type and script language. Not an error.
- **Notes:** Requires a valid Godot project loaded in the editor.

#### Scenario 2: Call with extra params — verify they are IGNORED
- **Description:** Unlike the other tools, this handler ignores its `args` parameter. Verify extra params are silently dropped.
- **Params:** `{ "verbose": true, "format": "detailed" }`
- **Expected result:** Same as Scenario 1. The extra params should NOT affect the output.
- **Notes:** Key behavioral difference from other tools in this file. The handler signature is `async () => callGodot(...)` (no args parameter).

#### Scenario 3: Empty/new project
- **Description:** Call on a brand new, minimal Godot project (e.g., created via `godot_create_project` with template `"empty"`).
- **Params:** `{}`
- **Expected result:** JSON with minimal/zero counts. Should not error.
- **Notes:** Verifies edge case of near-empty project.

#### Scenario 4: Godot editor not connected
- **Description:** Call when bridge is disconnected.
- **Params:** `{}`
- **Expected result:** Error `"Godot request failed: ..."` with `isError: true`.

---

## Cross-Cutting Concerns

### Bridge Failure Handling

All tools go through `callGodot()` which catches `bridge.sendRequest()` errors. If the WebSocket to Godot is severed:
- The error is caught
- Returns `{ content: [{ type: 'text', text: 'Godot request failed: <msg>' }], isError: true }`

### Missing Scene Requirement

Tools 1 (`analyze_scene_complexity`) and 2 (`analyze_signal_flow`) operate on the **currently open scene**. If no scene is open, the Godot plugin may return an error or empty result — this behavior depends on the GDScript implementation in the Godot addon.

### Result Format

All tools return data as JSON-stringified text via `callGodot()`:
```typescript
const text = typeof result === 'string' ? result : JSON.stringify(result, null, 2);
return { content: [{ type: 'text', text }] };
```

### Performance Considerations

- `find_unused_resources` may be slow on large projects (full project scan required).
- `analyze_scene_complexity` scales with scene node count.
- All tools are read-only — no side effects on the project.
