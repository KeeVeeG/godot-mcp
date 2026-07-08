# Test Plan: `export.ts` — Project Export Tools

> **File**: `server/src/tools/export.ts`
> **Total tools**: 7
> **Bridge methods**: `export/list_presets`, `export/project`, `export/get_info`, `export/validate`, `export/get_templates`, `export/create_preset`, `export/delete_preset`
> **Prerequisite**: Godot editor must be running with MCP plugin active and connected to the server.

---

## Shared Types Reference

| Type | Definition | Constraint |
|---|---|---|
| `Name` | `z.string()` | Non-empty string identifier |
| `z.string()` | Zod string | Any string value |
| `z.boolean()` | Zod boolean | `true` / `false` |
| `z.string().optional()` | Optional string | May be omitted |

---

## Dependency Map

```
create_export_preset ──┐
                       ├──▶ export_project (needs a preset name)
                       ├──▶ delete_export_preset (needs a preset name)
                       └──▶ list_export_presets (verify creation/deletion)

get_export_templates   ──▶ (standalone, no prereqs)
get_export_info        ──▶ (standalone, no prereqs)
validate_export        ──▶ (standalone, no prereqs)
```

**Recommended execution order for full coverage:**

1. `list_export_presets` — baseline state
2. `get_export_info` — project info
3. `get_export_templates` — available templates
4. `validate_export` — pre-export validation
5. `create_export_preset` — create a test preset
6. `list_export_presets` — confirm creation
7. `export_project` — run export with the test preset
8. `delete_export_preset` — cleanup
9. `list_export_presets` — confirm deletion

---

## Tool: `list_export_presets`

### Schema

| Parameter | Type | Required | Description |
|---|---|---|---|
| *(none)* | — | — | No parameters |

### Godot Bridge Call

`export/list_presets` with `{}`

### Test Scenarios

#### Scenario 1: List presets when none exist

**Description**: Call on a fresh project with no export presets configured.  
**Params**: `{}`  
**Expected result**: Success response (not `isError`). Content should be an empty array `[]` or a message indicating no presets exist.  
**Notes**: This establishes the baseline. The response format is defined by the Godot plugin side.  
**What to pay attention to**: Ensure that the response is not an error — absence of presets is a normal state, not an error.

#### Scenario 2: List presets after creating one

**Description**: After calling `create_export_preset` with name `"TestPreset"` and platform `"Windows Desktop"`, verify the preset appears in the list.  
**Params**: `{}`  
**Expected result**: Success response containing at least one entry with name `"TestPreset"`.  
**Notes**: Must run `create_export_preset` first. The response should include the preset's platform info.  
**What to pay attention to**: Verify that the preset name and platform match what was specified during creation. The response structure should be consistent (same format for empty and non-empty lists).

#### Scenario 3: List presets after deleting all presets

**Description**: After creating and then deleting a preset, verify list returns to empty state.  
**Params**: `{}`  
**Expected result**: Success response, empty list equivalent (same shape as Scenario 1).  
**Notes**: Full create→delete→list cycle.  
**What to pay attention to**: The list should return to its original state. The response format should match Scenario 1.

---

## Tool: `export_project`

### Schema

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `preset` | `string` (via `Name`) | **Yes** | — | Export preset name |
| `output_path` | `string` | No | — | Output path for the export |
| `debug` | `boolean` | No | `false` | Export as debug build |
| `pack_only` | `boolean` | No | `false` | Export as pack file only |

### Godot Bridge Call

`export/project` with `{ preset, output_path?, debug?, pack_only? }`

### Test Scenarios

#### Scenario 1: Export with preset name only (happy path)

**Description**: Export using a pre-existing preset with only the required parameter.  
**Params**:
```json
{
  "preset": "Windows Desktop"
}
```
**Expected result**: Success response with export output (file path or confirmation message).  
**Notes**: Requires that an export preset named `"Windows Desktop"` already exists. If no presets exist, this should return an error. The `debug` and `pack_only` fields default to `false`.  
**What to pay attention to**: Export may take significant time. Verify that a path to the exported file or a success confirmation is returned. If the preset does not exist, there should be a clear error.

#### Scenario 2: Export with all optional parameters

**Description**: Export with debug mode and custom output path.  
**Params**:
```json
{
  "preset": "Windows Desktop",
  "output_path": "C:/exports/my_game_debug.exe",
  "debug": true,
  "pack_only": false
}
```
**Expected result**: Success response. Export produces a debug build at the specified path.  
**Notes**: The output path must be writable. On Windows, use forward slashes or escaped backslashes.  
**What to pay attention to**: Verify that the file was created at the specified path. The debug build should contain debug symbols (check file size — debug is usually larger than release).

#### Scenario 3: Export as pack file only

**Description**: Export only the .pck pack file without the executable.  
**Params**:
```json
{
  "preset": "Windows Desktop",
  "pack_only": true
}
```
**Expected result**: Success response. Output should be a `.pck` file, not a full executable.  
**Notes**: Useful for patching — only the data pack is rebuilt.  
**What to pay attention to**: The result should be a .pck file. Verify that the executable file was NOT created (or only a .pck was created alongside an existing exe).

#### Scenario 4: Export with nonexistent preset name (error case)

**Description**: Attempt to export with a preset that does not exist.  
**Params**:
```json
{
  "preset": "NonexistentPreset123"
}
```
**Expected result**: Error response (`isError: true`) with a message indicating the preset was not found.  
**Notes**: Validates error handling for invalid preset names.  
**What to pay attention to**: The response should contain `isError: true`. The error message should be meaningful and indicate the cause (preset not found). There should be no unhandled exception.

#### Scenario 5: Export with empty preset name (edge case)

**Description**: Attempt to export with an empty string as the preset name.  
**Params**:
```json
{
  "preset": ""
}
```
**Expected result**: Error response — empty string should be rejected as invalid preset name.  
**Notes**: Tests boundary validation. The `Name` schema is `z.string()` which allows empty strings at the Zod level; the Godot side should reject it.  
**What to pay attention to**: Verify that an empty string does not lead to unexpected behavior. The error should be clear.

---

## Tool: `get_export_info`

### Schema

| Parameter | Type | Required | Description |
|---|---|---|---|
| *(none)* | — | — | No parameters |

### Godot Bridge Call

`export/get_info` with `{}`

### Test Scenarios

#### Scenario 1: Get export info for a valid project

**Description**: Call on an open Godot project to retrieve export metadata.  
**Params**: `{}`  
**Expected result**: Success response containing project export information: platform type, features, resource count, or similar metadata.  
**Notes**: The exact structure depends on the Godot plugin implementation, but should include at minimum the project name and target platform info.  
**What to pay attention to**: The response should contain structured project data. Verify the presence of fields: project name, target platform, resource count. The response should not be empty.

#### Scenario 2: Get export info consistency check

**Description**: Call twice in succession and verify identical results (idempotency).  
**Params**: `{}` (called twice)  
**Expected result**: Both calls return identical data (same content, same structure).  
**Notes**: Read-only operation should be idempotent.  
**What to pay attention to**: Two consecutive calls should return identical results. This confirms that the tool is pure (read-only) and has no side effects.

---

## Tool: `validate_export`

### Schema

| Parameter | Type | Required | Description |
|---|---|---|---|
| *(none)* | — | — | No parameters |

### Godot Bridge Call

`export/validate` with `{}` (note: handler passes `args` even though schema is empty)

### Test Scenarios

#### Scenario 1: Validate a clean project

**Description**: Validate a project that has no missing resources or errors.  
**Params**: `{}`  
**Expected result**: Success response indicating the project is valid for export, with no warnings or errors reported.  
**Notes**: The project should have all referenced resources present and scripts without errors.  
**What to pay attention to**: The response should contain an explicit indication of validity (e.g., `"valid": true` or an empty error list). If there are warnings, they should be separated from errors.

#### Scenario 2: Validate a project with intentionally missing resources

**Description**: Open a scene that references a deleted texture or script, then validate.  
**Params**: `{}`  
**Expected result**: Error or warning response listing the missing resources.  
**Notes**: To set up: create a scene, add a Sprite2D with a texture, save, then delete the texture file from disk. Re-open the scene and call validate.  
**What to pay attention to**: The response should contain a list of problematic resources with their paths. There should be a way to distinguish critical errors from warnings.

#### Scenario 3: Validate consistency (idempotency)

**Description**: Call validate twice without changing the project between calls.  
**Params**: `{}` (called twice)  
**Expected result**: Identical results from both calls.  
**Notes**: Validation is read-only; repeated calls must not change the outcome.  
**What to pay attention to**: The results should be identical. If there are timestamps or unique identifiers in the response — that is acceptable, but the substantive content should match.

---

## Tool: `get_export_templates`

### Schema

| Parameter | Type | Required | Description |
|---|---|---|---|
| *(none)* | — | — | No parameters |

### Godot Bridge Call

`export/get_templates` with `{}`

### Test Scenarios

#### Scenario 1: Get export templates when templates are installed

**Description**: Retrieve available export templates for the current Godot version.  
**Params**: `{}`  
**Expected result**: Success response listing installed export templates (e.g., Windows, Linux, macOS, Android, Web).  
**Notes**: Requires that export templates are downloaded via Godot's editor (Editor → Manage Export Templates).  
**What to pay attention to**: The response should contain a list of templates with the Godot version they are installed for. If templates are not installed, the response should reflect this (not an error, but an empty list or informative message).

#### Scenario 2: Get export templates when none are installed

**Description**: On a fresh Godot installation without downloaded templates.  
**Params**: `{}`  
**Expected result**: Success response (not an error) indicating no templates are available, or an empty list.  
**Notes**: This is a valid state — templates must be downloaded separately.  
**What to pay attention to**: The response should NOT be an error (`isError` should not be `true`). Absence of templates is a normal state, not a failure. There should be a clear message.

#### Scenario 3: Verify template version matches Godot version

**Description**: Cross-reference returned template versions with the running Godot editor version.  
**Params**: `{}`  
**Expected result**: Template version strings should match the Godot editor version (e.g., `4.7`).  
**Notes**: Can verify by also calling `get_project_info` or checking Godot version independently.  
**What to pay attention to**: The template version should match the Godot version. Version mismatch may lead to export errors.

---

## Tool: `create_export_preset`

### Schema

| Parameter | Type | Required | Description |
|---|---|---|---|
| `name` | `string` (via `Name`) | **Yes** | Preset name |
| `platform` | `string` | **Yes** | Target platform (e.g. `'Windows Desktop'`, `'Linux'`, `'Android'`) |

### Godot Bridge Call

`export/create_preset` with `{ name, platform }`

### Test Scenarios

#### Scenario 1: Create a Windows Desktop preset (happy path)

**Description**: Create a new export preset for Windows.  
**Params**:
```json
{
  "name": "TestWindows",
  "platform": "Windows Desktop"
}
```
**Expected result**: Success response confirming preset creation.  
**Notes**: After creation, call `list_export_presets` to verify the preset appears. Then clean up with `delete_export_preset`.  
**What to pay attention to**: The response should confirm successful creation. Verify that the preset appears in the list (`list_export_presets`). If a preset with this name already exists — check the behavior (overwrite or error).

#### Scenario 2: Create a Linux preset

**Description**: Create a preset targeting Linux.  
**Params**:
```json
{
  "name": "TestLinux",
  "platform": "Linux"
}
```
**Expected result**: Success response. Preset should appear in `list_export_presets`.  
**Notes**: Platform string must exactly match Godot's expected values.  
**What to pay attention to**: The platform `"Linux"` is a valid value for Godot. Verify that the preset was created with the correct platform.

#### Scenario 3: Create a preset with an invalid platform (error case)

**Description**: Attempt to create a preset with a platform Godot does not recognize.  
**Params**:
```json
{
  "name": "TestInvalid",
  "platform": "Commodore 64"
}
```
**Expected result**: Error response indicating the platform is not supported.  
**Notes**: Tests validation on the Godot side. The MCP schema (`z.string()`) accepts any string — validation happens in Godot.  
**What to pay attention to**: There should be a clear error indicating that the platform is not supported. There should be no unhandled exception or crash.

#### Scenario 4: Create a preset with duplicate name

**Description**: Create a preset, then attempt to create another with the same name.  
**Params**:
```json
{
  "name": "DuplicateTest",
  "platform": "Windows Desktop"
}
```
(Call twice with identical params)  
**Expected result**: First call succeeds. Second call either succeeds (overwrites) or returns an error about duplicate name.  
**Notes**: Behavior depends on Godot plugin implementation. Document which behavior is observed.  
**What to pay attention to**: Check how the system handles duplicates. Two options are valid: (1) overwrite the existing preset, (2) error with a duplicate message. Both are correct, but document which one is actually implemented.

#### Scenario 5: Create a preset with empty name (edge case)

**Description**: Attempt to create a preset with an empty string as name.  
**Params**:
```json
{
  "name": "",
  "platform": "Windows Desktop"
}
```
**Expected result**: Error response — empty name should be rejected.  
**Notes**: `Name` schema is `z.string()` which allows empty strings. Validation must happen on the Godot side.  
**What to pay attention to**: Verify that an empty name does not create a preset with an empty name (this would cause problems during deletion). There should be a validation error.

---

## Tool: `delete_export_preset`

### Schema

| Parameter | Type | Required | Description |
|---|---|---|---|
| `name` | `string` | **Yes** | Name of the export preset to delete |

### Godot Bridge Call

`export/delete_preset` with `{ name }`

### Test Scenarios

#### Scenario 1: Delete an existing preset (happy path)

**Description**: Create a preset, then delete it.  
**Params**:
```json
{
  "name": "PresetToDelete"
}
```
**Expected result**: Success response confirming deletion.  
**Notes**: Must call `create_export_preset` first to ensure the preset exists. After deletion, call `list_export_presets` to verify it's gone.  
**What to pay attention to**: The response should confirm deletion. Verify via `list_export_presets` that the preset was actually deleted. The operation should be idempotent in terms of result (after deleting the preset, it is not in the list).

#### Scenario 2: Delete a nonexistent preset (error case)

**Description**: Attempt to delete a preset that does not exist.  
**Params**:
```json
{
  "name": "NonexistentPreset999"
}
```
**Expected result**: Error response indicating the preset was not found.  
**Notes**: Validates error handling. The response should be an error, not a silent success.  
**What to pay attention to**: The response should contain `isError: true`. The message should indicate that a preset with this name was not found. There should be no "successful" deletion of a nonexistent object.

#### Scenario 3: Delete with empty name (edge case)

**Description**: Attempt to delete a preset with an empty string name.  
**Params**:
```json
{
  "name": ""
}
```
**Expected result**: Error response — empty name is not a valid preset identifier.  
**Notes**: Tests boundary validation on the Godot side.  
**What to pay attention to**: Verify that an empty string does not lead to accidental deletion of the first preset in the list or other unexpected behavior.

#### Scenario 4: Delete the same preset twice (idempotency/consistency)

**Description**: Delete a preset, then attempt to delete it again.  
**Params**:
```json
{
  "name": "DoubleDeleteTest"
}
```
(Call twice — first after creating the preset, second after first deletion)  
**Expected result**: First call succeeds. Second call returns error (preset not found).  
**Notes**: Tests that deletion actually removes the preset and that the system handles double-delete gracefully.  
**What to pay attention to**: The second call should return an error (not silent success). This confirms that the first call actually deleted the preset.

---

## Cross-Tool Integration Scenarios

### Integration 1: Full Export Lifecycle

**Description**: Complete workflow from preset creation to export to cleanup.

**Steps**:

1. **`list_export_presets`** — `{}` — Record initial state
2. **`create_export_preset`** — `{ "name": "LifecycleTest", "platform": "Windows Desktop" }` — Create preset
3. **`list_export_presets`** — `{}` — Verify preset appears in list
4. **`export_project`** — `{ "preset": "LifecycleTest" }` — Export using the new preset
5. **`validate_export`** — `{}` — Validate after export
6. **`delete_export_preset`** — `{ "name": "LifecycleTest" }` — Cleanup
7. **`list_export_presets`** — `{}` — Verify preset removed

**Expected**: All steps succeed. The preset is created, used for export, and cleaned up.

**What to pay attention to**: Full preset lifecycle. Verify that each step correctly reflects the changes from the previous one. Export (step 4) may take time — ensure the response is received before proceeding to the next step.

### Integration 2: Export with Debug vs Release

**Description**: Compare debug and release exports of the same preset.

**Steps**:

1. **`create_export_preset`** — `{ "name": "DebugReleaseTest", "platform": "Windows Desktop" }`
2. **`export_project`** — `{ "preset": "DebugReleaseTest", "debug": true, "output_path": "C:/exports/debug_build.exe" }`
3. **`export_project`** — `{ "preset": "DebugReleaseTest", "debug": false, "output_path": "C:/exports/release_build.exe" }`
4. **`delete_export_preset`** — `{ "name": "DebugReleaseTest" }`

**Expected**: Both exports succeed. Debug build is typically larger than release build.

**What to pay attention to**: Compare file sizes — debug should be larger than release. Verify that both files exist and are not empty.

### Integration 3: Multiple Platform Presets

**Description**: Create presets for different platforms and verify independence.

**Steps**:

1. **`create_export_preset`** — `{ "name": "WinTest", "platform": "Windows Desktop" }`
2. **`create_export_preset`** — `{ "name": "LinTest", "platform": "Linux" }`
3. **`list_export_presets`** — `{}` — Both should appear
4. **`delete_export_preset`** — `{ "name": "WinTest" }`
5. **`list_export_presets`** — `{}` — Only LinTest should remain
6. **`delete_export_preset`** — `{ "name": "LinTest" }`

**Expected**: Presets are independent — deleting one does not affect the other.

**What to pay attention to**: Verify preset independence. After deleting WinTest, LinTest should remain in the list. The response format of `list_export_presets` should be consistent across all steps.

### Integration 4: Pack-Only Export Flow

**Description**: Export as pack file and verify the output.

**Steps**:

1. **`create_export_preset`** — `{ "name": "PackTest", "platform": "Windows Desktop" }`
2. **`export_project`** — `{ "preset": "PackTest", "pack_only": true }`
3. **`delete_export_preset`** — `{ "name": "PackTest" }`

**Expected**: Pack-only export produces a `.pck` file without a full executable.

**What to pay attention to**: The export result should contain a mention of a .pck file. If a path is returned, verify that it is .pck, not .exe.

---

## Error Handling Matrix

| Scenario | Tool | Expected `isError` | Expected message pattern |
|---|---|---|---|
| Nonexistent preset | `export_project` | `true` | `*not found*` or `*does not exist*` |
| Empty preset name | `export_project` | `true` | `*invalid*` or `*empty*` |
| Invalid platform | `create_export_preset` | `true` | `*platform*` + `*not supported*` or `*invalid*` |
| Delete nonexistent | `delete_export_preset` | `true` | `*not found*` or `*does not exist*` |
| Empty name delete | `delete_export_preset` | `true` | `*invalid*` or `*empty*` |
| Bridge disconnected | Any tool | `true` | `*Godot request failed*` or `*not connected*` |

---

## Notes for Test Execution Agents

1. **State dependency**: `export_project` and `delete_export_preset` require existing presets. Always `create_export_preset` before testing these tools.
2. **Cleanup**: After each test run, delete all created presets to avoid state pollution. Use `list_export_presets` to find any remaining presets.
3. **Timeout**: `export_project` may take 30+ seconds for large projects. Increase timeout or use the bridge's configured timeout.
4. **File system side effects**: `export_project` with `output_path` writes to disk. Verify file existence and clean up after tests.
5. **Bridge connectivity**: All tools require an active Godot editor connection. If the bridge is disconnected, all tools will return `isError: true` with a connection failure message.
6. **Idempotency of read tools**: `list_export_presets`, `get_export_info`, `get_export_templates`, and `validate_export` are read-only and should be idempotent. Calling them multiple times should return identical results (modulo timestamps).
7. **Related tools in other files**: For platform-specific export workflows, see also `platform_export.ts` (tools: `export_for_platform`, `validate_platform_export`, `get_platform_export_templates`, `create_platform_export_preset`, `run_exported_build`, `validate_export_for_platform`) and `build_config.ts` (tools: `get_build_settings`, `set_build_configuration`, `validate_build_settings`, `get_build_command`).