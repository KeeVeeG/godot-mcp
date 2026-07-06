## Visual testing commands module - 6 tools.
## Provides screenshot capture with context, pixel-level comparison,
## visual regression recording, and baseline management.
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


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func get_commands() -> Dictionary:
	return {
		"take_screenshot_with_context": take_screenshot_with_context,
		"compare_screenshots": compare_screenshots,
		"assert_visual_match": assert_visual_match,
		"record_visual_regression": record_visual_regression,
		"get_visual_diff_report": get_visual_diff_report,
		"set_visual_baseline": set_visual_baseline,
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

	_ensure_dirs()

	var root: Node = _get_scene_root()
	if root == null:
		return {"error": "No scene open"}

	# Capture viewport screenshot
	var viewport: Viewport = root.get_viewport()
	if viewport == null:
		return {"error": "No viewport available"}

	var image: Image = viewport.get_texture().get_image()
	if image == null:
		return {"error": "Failed to capture viewport"}

	# Save screenshot
	var screenshot_path: String = VISUAL_DIR + "%s.png" % name
	image.save_png(ProjectSettings.globalize_path(screenshot_path))

	# Build context metadata
	var context: Dictionary = {
		"name": name,
		"timestamp": Time.get_unix_time_from_system(),
		"timestamp_human": Time.get_datetime_string_from_system(),
		"viewport_size": {"x": viewport.get_visible_rect().size.x, "y": viewport.get_visible_rect().size.y},
		"scene_path": root.scene_file_path,
		"node_count": _count_nodes(root),
	}

	# Include node properties if requested
	if include_props and include_nodes.size() > 0:
		var node_data: Dictionary = {}
		for node_path: String in include_nodes:
			var node: Node = root.get_node_or_null(node_path)
			if node != null:
				node_data[node_path] = _get_node_snapshot(node)
		context["node_snapshots"] = node_data

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
		"message": "Screenshot captured: %s" % name,
	}}


## Compare two screenshots pixel-by-pixel.
## Returns mismatch percentage and generates a diff image.
func compare_screenshots(params: Dictionary) -> Dictionary:
	var baseline_path: String = params.get("baseline", "")
	var current_path: String = params.get("current", "")
	var threshold: float = params.get("threshold", 0.01)

	if baseline_path.is_empty() or current_path.is_empty():
		return {"error": "Both baseline and current paths are required"}

	# Resolve paths
	var baseline_global: String = ProjectSettings.globalize_path(baseline_path) if baseline_path.begins_with("res://") else baseline_path
	var current_global: String = ProjectSettings.globalize_path(current_path) if current_path.begins_with("res://") else current_path

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

	_ensure_dirs()

	var recording_dir: String = VISUAL_DIR + "recordings/%s/" % test_name
	if not DirAccess.dir_exists_absolute(recording_dir):
		DirAccess.make_dir_recursive_absolute(recording_dir)

	var root: Node = _get_scene_root()
	if root == null:
		return {"error": "No scene open"}

	var viewport: Viewport = root.get_viewport()
	if viewport == null:
		return {"error": "No viewport available"}

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
		"message": "Recorded %d frames over %.1fs" % [captured_paths.size(), recording_data["total_duration"]],
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

	return {"result": {
		"total_assertions": total,
		"passed": passed,
		"failed": failed,
		"pass_rate": "%.1f%%" % (100.0 if total == 0 else (float(passed) / float(total) * 100.0)),
		"recordings_count": _recordings.size(),
		"failures": failures,
	}}


## Set or update a visual baseline.
func set_visual_baseline(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")
	var screenshot_path: String = params.get("screenshot_path", "")

	if name.is_empty() or screenshot_path.is_empty():
		return {"error": "name and screenshot_path are required"}

	_ensure_dirs()

	# Resolve source path
	var source_global: String = screenshot_path
	if screenshot_path.begins_with("res://"):
		source_global = ProjectSettings.globalize_path(screenshot_path)

	if not FileAccess.file_exists(source_global) and not FileAccess.file_exists(screenshot_path):
		return {"error": "Source screenshot not found: %s" % screenshot_path}

	var actual_source: String = source_global if FileAccess.file_exists(source_global) else screenshot_path

	# Copy to baseline directory
	var baseline_path: String = BASELINE_DIR + "%s.png" % name
	var baseline_global: String = ProjectSettings.globalize_path(baseline_path)

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
		"message": "Visual baseline '%s' set from %s" % [name, screenshot_path],
	}}


## Helper: Get the current scene root.
func _get_scene_root() -> Node:
	if _plugin == null:
		return null
	return _plugin.get_editor_interface().get_edited_scene_root()


## Helper: Count nodes in tree.
func _count_nodes(node: Node) -> int:
	var count: int = 1
	for child: Node in node.get_children():
		count += _count_nodes(child)
	return count


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
