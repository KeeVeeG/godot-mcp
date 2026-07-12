## Visual testing commands module - 10 tools.
## Provides screenshot capture with context, pixel-level comparison,
## visual regression recording, and baseline management.
@tool
class_name MCPVisualTestingCommands
extends RefCounted

var _plugin: EditorPlugin

## Directory for visual test artifacts
const VISUAL_DIR: String = "user://mcp_visual_tests/"
## Directory for baseline screenshots
const BASELINE_DIR: String = "user://mcp_visual_tests/baselines/"
## Directory for comparison results
const DIFFS_DIR: String = "user://mcp_visual_tests/diffs/"

## Accumulated visual test results
var _test_results: Array = []
## Visual regression recordings
var _recordings: Dictionary = {}
## Whether the report was explicitly cleared (skip disk fallback)
var _report_cleared: bool = false


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


## Get the active editor SubViewport (2D or 3D) for proper resolution screenshots.
## The scene's internal viewport returns 2?2 pixels in the editor � we must use the
## editor's rendering SubViewport instead. Returns null if neither is available.
func _get_current_editor_viewport() -> SubViewport:
	var editor_interface: EditorInterface = _plugin.get_editor_interface()
	# Try 3D viewport first (most common for visual tests)
	var vp_3d: SubViewport = editor_interface.get_editor_viewport_3d(0)
	if vp_3d != null and vp_3d.get_visible_rect().size.x > 10:
		return vp_3d
	# Fall back to 2D viewport
	var vp_2d: SubViewport = editor_interface.get_editor_viewport_2d()
	if vp_2d != null and vp_2d.get_visible_rect().size.x > 10:
		return vp_2d
	# Last resort: return whichever is non-null
	if vp_3d != null:
		return vp_3d
	return vp_2d


## Build a human-readable suffix for missing nodes in screenshot capture messages.
func _missing_nodes_suffix(context: Dictionary) -> String:
	var count: int = context.get("nodes_missing", 0)
	if count > 0:
		var missing: Array = context.get("missing_nodes", [])
		return " (%d nodes found, %d not found: %s)" % [context.get("nodes_found", 0), count, ", ".join(missing)]
	return ""


## Validate screenshot/baseline/recording names � only alphanumeric, underscores, and hyphens.
## Max length 100 chars (keeps total path well under Windows MAX_PATH ? 260).
## Returns an error string, or empty string if valid.
func _validate_name(value: String) -> String:
	if value.is_empty():
		return "name is required"
	if value.length() > 100:
		return "Name is too long (%d chars). Maximum is 100 characters." % value.length()
	var regex := RegEx.new()
	regex.compile("^[a-zA-Z0-9_\\-]+$")
	if not regex.search(value):
		return "Name '%s' contains invalid characters. Only a-z, A-Z, 0-9, '_', '-' allowed." % value
	return ""


func get_commands() -> Dictionary:
	return {
		"take_screenshot_with_context": take_screenshot_with_context,
		"compare_screenshots": compare_screenshots,
		"assert_visual_match": assert_visual_match,
		"record_visual_regression": record_visual_regression,
		"get_visual_diff_report": get_visual_diff_report,
		"set_visual_baseline": set_visual_baseline,
		"delete_screenshot": delete_screenshot,
		"delete_visual_recording": delete_visual_recording,
		"clear_visual_diff_report": clear_visual_diff_report,
		"list_visual_baselines": list_visual_baselines,
	}


## Ensure visual test directories exist.
func _ensure_dirs() -> void:
	for dir: String in [VISUAL_DIR, BASELINE_DIR, DIFFS_DIR]:
		if not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)


## Take a screenshot with scene context metadata.
func take_screenshot_with_context(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")
	var include_nodes: Array = params.get("include_nodes", [])
	var include_props: bool = params.get("include_props", false)

	if name.is_empty():
		return {"error": "name is required"}

	var name_err: String = _validate_name(name)
	if not name_err.is_empty():
		return {"error": name_err}

	_ensure_dirs()

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	# Capture viewport screenshot � use editor SubViewport (not scene's 2?2 internal viewport)
	var viewport: Viewport = _get_current_editor_viewport()
	if viewport == null:
		return {"error": "No editor viewport available � open a 2D or 3D editor tab"}
	RenderingServer.force_draw(true)
	var image: Image = viewport.get_texture().get_image()
	if image == null:
		return {"error": "Failed to capture viewport"}

	# Save screenshot � detect overwrite
	var screenshot_path: String = VISUAL_DIR + "%s.png" % name
	var overwritten: bool = FileAccess.file_exists(screenshot_path)
	image.save_png(ProjectSettings.globalize_path(screenshot_path))

	# Build context metadata
	var context: Dictionary = {
		"name": name,
		"timestamp": Time.get_unix_time_from_system(),
		"timestamp_human": Time.get_datetime_string_from_system(),
		"viewport_size": {"x": image.get_width(), "y": image.get_height()},
		"scene_path": root.scene_file_path,
		"node_count": MCPCommandHelpers.count_nodes(root),
	}

	# Include node properties if requested
	if include_props and include_nodes.size() > 0:
		var node_data: Dictionary = {}
		var missing_nodes: Array = []
		var nodes_found: int = 0
		for node_path: String in include_nodes:
			var node: Node = root.get_node_or_null(node_path)
			if node != null:
				node_data[node_path] = _get_node_snapshot(node)
				nodes_found += 1
			else:
				missing_nodes.append(node_path)
		context["node_snapshots"] = node_data
		context["nodes_found"] = nodes_found
		context["nodes_missing"] = missing_nodes.size()
		if missing_nodes.size() > 0:
			context["missing_nodes"] = missing_nodes

	# Save context alongside screenshot
	var context_path: String = VISUAL_DIR + "%s_context.json" % name
	var file: FileAccess = FileAccess.open(context_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(context, "\t"))
		file.close()

	return {"result": {
		"screenshot_path": screenshot_path,
		"context_path": context_path,
		"viewport_size": context["viewport_size"],
		"node_count": context["node_count"],
		"timestamp": context["timestamp_human"],
		"overwritten": overwritten,
		"message": "Screenshot captured: %s%s%s" % [name, " (overwritten previous)" if overwritten else "", _missing_nodes_suffix(context)],
	}}


## Compare two screenshots pixel-by-pixel.
## Returns mismatch percentage and generates a diff image.
func compare_screenshots(params: Dictionary) -> Dictionary:
	var baseline_path: String = params.get("baseline", "")
	var current_path: String = params.get("current", "")
	var threshold: float = params.get("threshold", 0.01)

	if baseline_path.is_empty() or current_path.is_empty():
		return {"error": "Both baseline and current paths are required"}

	# Resolve paths � handle both res:// and user:// virtual paths
	var baseline_global: String = baseline_path
	if baseline_path.begins_with("res://") or baseline_path.begins_with("user://"):
		baseline_global = ProjectSettings.globalize_path(baseline_path)
	var current_global: String = current_path
	if current_path.begins_with("res://") or current_path.begins_with("user://"):
		current_global = ProjectSettings.globalize_path(current_path)

	# Load images
	var img_a: Image = Image.new()
	var err_a: Error = img_a.load(baseline_global)
	if err_a != OK:
		return {"error": "Failed to load baseline image: %s" % baseline_path}

	var img_b: Image = Image.new()
	var err_b: Error = img_b.load(current_global)
	if err_b != OK:
		return {"error": "Failed to load current image: %s" % current_path}

	# Ensure same dimensions
	if img_a.get_width() != img_b.get_width() or img_a.get_height() != img_b.get_height():
		return {"error": "Image dimensions mismatch: %dx%d vs %dx%d" % [
			img_a.get_width(), img_a.get_height(), img_b.get_width(), img_b.get_height()
		]}

	# Convert to RGBA8 for consistent byte layout
	img_a.convert(Image.FORMAT_RGBA8)
	img_b.convert(Image.FORMAT_RGBA8)

	# Bulk byte comparison via get_data() instead of per-pixel get_pixel()/set_pixel()
	var width: int = img_a.get_width()
	var height: int = img_a.get_height()
	var total_pixels: int = width * height
	var different_pixels: int = 0
	var max_diff: float = 0.0

	var data_a: PackedByteArray = img_a.get_data()
	var data_b: PackedByteArray = img_b.get_data()
	var diff_data: PackedByteArray = PackedByteArray()
	diff_data.resize(data_a.size())

	for i: int in range(total_pixels):
		var offset: int = i * 4
		var r_a: int = data_a[offset]
		var g_a: int = data_a[offset + 1]
		var b_a: int = data_a[offset + 2]
		var a_a: int = data_a[offset + 3]
		var r_b: int = data_b[offset]
		var g_b: int = data_b[offset + 1]
		var b_b: int = data_b[offset + 2]
		var a_b: int = data_b[offset + 3]

		var pixel_diff: float = (absf(float(r_a - r_b)) + absf(float(g_a - g_b)) + absf(float(b_a - b_b)) + absf(float(a_a - a_b))) / (4.0 * 255.0)
		if pixel_diff > max_diff:
			max_diff = pixel_diff
		if pixel_diff > 0.0:
			different_pixels += 1
			# Highlight differences in red
			diff_data[offset] = 255
			diff_data[offset + 1] = 0
			diff_data[offset + 2] = 0
			diff_data[offset + 3] = int(min(pixel_diff * 4.0, 1.0) * 255.0)
		else:
			diff_data[offset] = r_a
			diff_data[offset + 1] = g_a
			diff_data[offset + 2] = b_a
			diff_data[offset + 3] = a_a

	var diff_image: Image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, diff_data)

	var mismatch_ratio: float = float(different_pixels) / float(total_pixels)
	var matches: bool = mismatch_ratio <= threshold
	var pixel_perfect: bool = different_pixels == 0

	# Save diff image
	_ensure_dirs()
	var diff_name: String = "%s_vs_%s" % [
		baseline_path.get_file().get_basename(),
		current_path.get_file().get_basename(),
	]
	var diff_path: String = DIFFS_DIR + "%s_diff.png" % diff_name
	diff_image.save_png(ProjectSettings.globalize_path(diff_path))

	return {"result": {
		"matches": matches,
		"pixel_perfect": pixel_perfect,
		"mismatch_ratio": mismatch_ratio,
		"mismatch_percentage": "%.4f%%" % (mismatch_ratio * 100.0),
		"different_pixels": different_pixels,
		"total_pixels": total_pixels,
		"max_pixel_diff": max_diff,
		"threshold": threshold,
		"diff_image_path": diff_path,
		"dimensions": {"width": width, "height": height},
	}}


## Assert that a screenshot matches a baseline within a threshold.
func assert_visual_match(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")
	var baseline: String = params.get("baseline", "")
	var threshold: float = params.get("threshold", 0.01)

	if name.is_empty() or baseline.is_empty():
		return {"error": "name and baseline are required"}

	# Find the current screenshot
	var current_path: String = VISUAL_DIR + "%s.png" % name
	if not FileAccess.file_exists(current_path):
		return {"error": "No screenshot found with name: %s" % name}

	# Resolve baseline path
	var baseline_path: String = baseline
	if not FileAccess.file_exists(baseline_path):
		baseline_path = BASELINE_DIR + "%s.png" % baseline
		if not FileAccess.file_exists(baseline_path):
			return {"error": "Baseline not found: %s" % baseline}

	# Run comparison
	var compare_result: Dictionary = compare_screenshots({
		"baseline": baseline_path,
		"current": current_path,
		"threshold": threshold,
	})

	if compare_result.has("error"):
		return compare_result

	var result_data: Dictionary = compare_result.get("result", {})
	var passed: bool = result_data.get("matches", false)

	var entry: Dictionary = {
		"name": name,
		"baseline": baseline_path,
		"current": current_path,
		"threshold": threshold,
		"mismatch_ratio": result_data.get("mismatch_ratio", 0.0),
		"passed": passed,
	}
	_test_results.append(entry)

	if passed:
		return {"result": {
			"passed": true,
			"message": "Visual match PASSED: %s (mismatch: %s)" % [name, result_data.get("mismatch_percentage", "?")],
			"details": result_data,
		}}
	else:
		return {"result": {
			"passed": false,
			"message": "Visual match FAILED: %s (mismatch: %s, threshold: %.4f%%)" % [
				name, result_data.get("mismatch_percentage", "?"), threshold * 100.0
			],
			"details": result_data,
		}}


## Record multiple frames over time for visual regression testing.
func record_visual_regression(params: Dictionary) -> Dictionary:
	var test_name: String = params.get("test_name", "")
	var frames: int = params.get("frames", 10)
	var interval: float = params.get("interval", 0.5)

	if test_name.is_empty():
		return {"error": "test_name is required"}

	var name_err: String = _validate_name(test_name)
	if not name_err.is_empty():
		return {"error": name_err}

	_ensure_dirs()

	var recording_dir: String = VISUAL_DIR + "recordings/%s/" % test_name
	var overwritten: bool = DirAccess.dir_exists_absolute(recording_dir)
	if overwritten:
		# Clean old frames so overwriting with fewer frames doesn't leave orphans
		var recording_global: String = ProjectSettings.globalize_path(recording_dir)
		var old_dir: DirAccess = DirAccess.open(recording_global)
		if old_dir != null:
			old_dir.list_dir_begin()
			var old_file: String = old_dir.get_next()
			while old_file != "":
				if not old_dir.current_is_dir():
					DirAccess.remove_absolute(recording_global.path_join(old_file))
				old_file = old_dir.get_next()
			old_dir.list_dir_end()
	else:
		DirAccess.make_dir_recursive_absolute(recording_dir)

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var viewport: Viewport = _get_current_editor_viewport()
	if viewport == null:
		return {"error": "No editor viewport available � open a 2D or 3D editor tab"}

	var captured_paths: Array = []
	var capture_times: Array = []
	var start_time: float = Time.get_unix_time_from_system()

	for i: int in range(frames):
		var image: Image = viewport.get_texture().get_image()
		if image != null:
			var frame_path: String = recording_dir + "frame_%04d.png" % i
			image.save_png(ProjectSettings.globalize_path(frame_path))
			captured_paths.append(frame_path)
			capture_times.append(Time.get_unix_time_from_system() - start_time)

		if i < frames - 1:
			await _plugin.get_tree().create_timer(interval).timeout

	var recording_data: Dictionary = {
		"test_name": test_name,
		"frames": captured_paths.size(),
		"interval": interval,
		"total_duration": Time.get_unix_time_from_system() - start_time,
		"paths": captured_paths,
		"timestamps": capture_times,
	}

	_recordings[test_name] = recording_data

	# New recording invalidates cleared-report state
	_report_cleared = false

	# Save recording manifest
	var manifest_path: String = recording_dir + "manifest.json"
	var file: FileAccess = FileAccess.open(manifest_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(recording_data, "\t"))
		file.close()

	return {"result": {
		"success": true,
		"test_name": test_name,
		"frames_captured": captured_paths.size(),
		"total_duration": recording_data["total_duration"],
		"recording_dir": recording_dir,
		"manifest_path": manifest_path,
		"overwritten": overwritten,
		"message": "Recorded %d frames over %.1fs%s" % [captured_paths.size(), recording_data["total_duration"], " (overwritten previous)" if overwritten else ""],
	}}


## Get the aggregated visual regression report.
func get_visual_diff_report(_params: Dictionary) -> Dictionary:
	var total: int = _test_results.size()
	var passed: int = 0
	var failed: int = 0
	var failures: Array = []

	for entry: Dictionary in _test_results:
		if entry.get("passed", false):
			passed += 1
		else:
			failed += 1
			failures.append(entry)

	# Fallback: if _recordings is empty, scan disk for recording directories.
	# In-memory state may be lost across await boundaries or plugin reloads,
	# but recordings are always persisted to user://mcp_visual_tests/recordings/.
	var recordings_count: int = _recordings.size()
	if recordings_count == 0 and not _report_cleared:
		var rec_dir: String = VISUAL_DIR + "recordings/"
		var rec_global: String = ProjectSettings.globalize_path(rec_dir)
		if DirAccess.dir_exists_absolute(rec_dir):
			var dir: DirAccess = DirAccess.open(rec_global)
			if dir != null:
				dir.list_dir_begin()
				var entry_name: String = dir.get_next()
				while entry_name != "":
					if dir.current_is_dir() and not entry_name.begins_with("."):
						var manifest: String = rec_dir + entry_name + "/manifest.json"
						if FileAccess.file_exists(manifest):
							recordings_count += 1
					entry_name = dir.get_next()
				dir.list_dir_end()

	return {"result": {
		"total_assertions": total,
		"passed": passed,
		"failed": failed,
		"pass_rate": "%.1f%%" % (100.0 if total == 0 else (float(passed) / float(total) * 100.0)),
		"recordings_count": recordings_count,
		"failures": failures,
	}}


## Set or update a visual baseline.
func set_visual_baseline(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")
	var screenshot_path: String = params.get("screenshot_path", "")

	if name.is_empty() or screenshot_path.is_empty():
		return {"error": "name and screenshot_path are required"}

	var name_err: String = _validate_name(name)
	if not name_err.is_empty():
		return {"error": name_err}

	_ensure_dirs()

	# Resolve source path
	var source_global: String = screenshot_path
	if screenshot_path.begins_with("res://") or screenshot_path.begins_with("user://"):
		source_global = ProjectSettings.globalize_path(screenshot_path)

	if not FileAccess.file_exists(source_global) and not FileAccess.file_exists(screenshot_path):
		return {"error": "Source screenshot not found: %s" % screenshot_path}

	var actual_source: String = source_global if FileAccess.file_exists(source_global) else screenshot_path

	# Copy to baseline directory
	var baseline_path: String = BASELINE_DIR + "%s.png" % name
	var baseline_global: String = ProjectSettings.globalize_path(baseline_path)
	var overwritten: bool = FileAccess.file_exists(baseline_path)

	var src_file: FileAccess = FileAccess.open(actual_source, FileAccess.READ)
	if src_file == null:
		return {"error": "Failed to read source screenshot"}
	var data: PackedByteArray = src_file.get_buffer(src_file.get_length())
	src_file.close()

	var dst_file: FileAccess = FileAccess.open(baseline_global, FileAccess.WRITE)
	if dst_file == null:
		return {"error": "Failed to write baseline file"}
	dst_file.store_buffer(data)
	dst_file.close()

	return {"result": {
		"success": true,
		"name": name,
		"baseline_path": baseline_path,
		"source": screenshot_path,
		"overwritten": overwritten,
		"message": "Visual baseline '%s' %s from %s" % [name, "updated" if overwritten else "set", screenshot_path],
	}}


## Delete a captured screenshot and its context metadata.
func delete_screenshot(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")

	if name.is_empty():
		return {"error": "name is required"}

	var name_err: String = _validate_name(name)
	if not name_err.is_empty():
		return {"error": name_err}

	var screenshot_path: String = VISUAL_DIR + "%s.png" % name
	var context_path: String = VISUAL_DIR + "%s_context.json" % name

	var screenshot_global: String = ProjectSettings.globalize_path(screenshot_path)
	var context_global: String = ProjectSettings.globalize_path(context_path)

	var deleted_files: Array = []

	if FileAccess.file_exists(screenshot_path):
		var err: Error = DirAccess.remove_absolute(screenshot_global)
		if err != OK:
			return {"error": "Failed to delete screenshot: %s" % screenshot_path}
		deleted_files.append(screenshot_path)
	else:
		return {"error": "Screenshot not found: %s" % name}

	if FileAccess.file_exists(context_path):
		DirAccess.remove_absolute(context_global)
		deleted_files.append(context_path)

	return {"result": {
		"success": true,
		"name": name,
		"deleted_files": deleted_files,
		"message": "Screenshot '%s' deleted (%d files)" % [name, deleted_files.size()],
	}}


## Delete a visual recording and all its frames.
func delete_visual_recording(params: Dictionary) -> Dictionary:
	var test_name: String = params.get("test_name", "")

	if test_name.is_empty():
		return {"error": "test_name is required"}

	var name_err: String = _validate_name(test_name)
	if not name_err.is_empty():
		return {"error": name_err}

	var recording_dir: String = VISUAL_DIR + "recordings/%s/" % test_name
	var recording_global: String = ProjectSettings.globalize_path(recording_dir)

	if not DirAccess.dir_exists_absolute(recording_dir):
		return {"error": "Recording not found: %s" % test_name}

	# Remove all files inside the recording directory
	var dir: DirAccess = DirAccess.open(recording_global)
	if dir == null:
		return {"error": "Failed to open recording directory"}

	var deleted_count: int = 0
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var file_path: String = recording_global.path_join(file_name)
			var err: Error = DirAccess.remove_absolute(file_path)
			if err == OK:
				if file_name.ends_with(".png"):
					deleted_count += 1
		file_name = dir.get_next()
	dir.list_dir_end()

	# Remove the directory itself
	var remove_err: Error = DirAccess.remove_absolute(recording_global)
	if remove_err != OK:
		return {"error": "Failed to remove recording directory"}

	# Remove from in-memory recordings
	_recordings.erase(test_name)

	return {"result": {
		"success": true,
		"test_name": test_name,
		"deleted_frames": deleted_count,
		"message": "Recording '%s' deleted (%d frames)" % [test_name, deleted_count],
	}}


## Clear all accumulated visual test results and recordings.
func clear_visual_diff_report(_params: Dictionary) -> Dictionary:
	var total_results: int = _test_results.size()
	var total_recordings: int = _recordings.size()

	_test_results.clear()
	_recordings.clear()
	_report_cleared = true

	return {"result": {
		"success": true,
		"cleared_assertions": total_results,
		"cleared_recordings": total_recordings,
		"message": "Visual diff report cleared (%d assertions, %d recordings)" % [total_results, total_recordings],
	}}


## List all saved visual baselines.
func list_visual_baselines(_params: Dictionary) -> Dictionary:
	_ensure_dirs()

	var baselines: Array = []
	var baseline_global: String = ProjectSettings.globalize_path(BASELINE_DIR)

	var dir: DirAccess = DirAccess.open(baseline_global)
	if dir == null:
		return {"error": "Failed to open baselines directory"}

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			var full_path: String = BASELINE_DIR + file_name
			var file_size: int = 0
			if FileAccess.file_exists(full_path):
				var f: FileAccess = FileAccess.open(full_path, FileAccess.READ)
				if f != null:
					file_size = f.get_length()
					f.close()
			baselines.append({
				"name": file_name.get_basename(),
				"path": full_path,
				"file_size": file_size,
			})
		file_name = dir.get_next()
	dir.list_dir_end()

	return {"result": {
		"baselines": baselines,
		"count": baselines.size(),
		"baselines_dir": BASELINE_DIR,
	}}


## Helper: Get a snapshot of a node's key properties.
func _get_node_snapshot(node: Node) -> Dictionary:
	var snapshot: Dictionary = {
		"type": node.get_class(),
		"name": node.name,
	}

	if node is Node2D:
		var n2d: Node2D = node as Node2D
		snapshot["position"] = {"x": n2d.position.x, "y": n2d.position.y}
		snapshot["rotation"] = n2d.rotation
		snapshot["scale"] = {"x": n2d.scale.x, "y": n2d.scale.y}
		snapshot["visible"] = n2d.visible
	elif node is Node3D:
		var n3d: Node3D = node as Node3D
		snapshot["position"] = {"x": n3d.position.x, "y": n3d.position.y, "z": n3d.position.z}
		snapshot["visible"] = n3d.visible
	elif node is Control:
		var ctrl: Control = node as Control
		snapshot["position"] = {"x": ctrl.position.x, "y": ctrl.position.y}
		snapshot["size"] = {"x": ctrl.size.x, "y": ctrl.size.y}
		snapshot["visible"] = ctrl.visible

	if node is CanvasItem:
		var ci: CanvasItem = node as CanvasItem
		snapshot["modulate"] = {"r": ci.modulate.r, "g": ci.modulate.g, "b": ci.modulate.b, "a": ci.modulate.a}

	return snapshot
