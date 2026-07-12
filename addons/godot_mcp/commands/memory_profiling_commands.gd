## Memory profiling commands module - 6 tools.
## Provides memory usage breakdown, object tracking, leak detection,
## and garbage collection control.
@tool
class_name MCPMemoryProfilingCommands
extends RefCounted

var _plugin: EditorPlugin

## Object creation tracking data
var _tracking_active: bool = false
var _tracked_class: String = ""
var _creation_log: Array = []
var _tracking_start: float = 0.0

## Baseline object counts for leak detection
var _baseline_counts: Dictionary = {}


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func get_commands() -> Dictionary:
	return {
		"get_memory_usage": get_memory_usage,
		"track_object_creation": track_object_creation,
		"stop_object_tracking": stop_object_tracking,
		"find_memory_leaks": find_memory_leaks,
		"get_object_count": get_object_count,
		"force_garbage_collection": force_garbage_collection,
	}


## Get detailed memory usage breakdown by category.
func get_memory_usage(_params: Dictionary) -> Dictionary:
	var mem_static: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	var mem_static_max: float = Performance.get_monitor(Performance.MEMORY_STATIC_MAX)
	var mem_video: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	var mem_texture: float = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	var mem_buffer: float = Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)

	var object_count: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var resource_count: int = int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	var node_count: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphan_count: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))

	var total_mem: float = mem_static + mem_video

	return {"result": {
		"total_bytes": total_mem,
		"total_mb": "%.2f" % (total_mem / (1024.0 * 1024.0)),
		"categories": {
			"static": {
				"bytes": mem_static,
				"mb": "%.2f" % (mem_static / (1024.0 * 1024.0)),
				"max_bytes": mem_static_max,
				"max_mb": "%.2f" % (mem_static_max / (1024.0 * 1024.0)),
				"usage_pct": "%.1f%%" % (mem_static / max(mem_static_max, 1.0) * 100.0),
			},
			"video": {
				"bytes": mem_video,
				"mb": "%.2f" % (mem_video / (1024.0 * 1024.0)),
			},
			"textures": {
				"bytes": mem_texture,
				"mb": "%.2f" % (mem_texture / (1024.0 * 1024.0)),
			},
			"buffers": {
				"bytes": mem_buffer,
				"mb": "%.2f" % (mem_buffer / (1024.0 * 1024.0)),
			},
		},
		"objects": {
			"total": object_count,
			"resources": resource_count,
			"nodes": node_count,
			"orphan_nodes": orphan_count,
		},
		"orphan_warning": orphan_count > 0 and not Engine.is_editor_hint(),
		"orphan_message": "Found %d orphan nodes (normal in editor context)" % orphan_count if orphan_count > 0 and Engine.is_editor_hint() else ("Found %d orphan nodes - potential memory leaks" % orphan_count if orphan_count > 0 else "No orphan nodes detected"),
	}}


## Track object creation for a specific class over a duration.
func track_object_creation(params: Dictionary) -> Dictionary:
	var cls_name: String = params.get("class_name", "")
	var duration: float = params.get("duration", 10.0)

	if cls_name.is_empty():
		return {"error": "@tool
class_name is required"}

	if not ClassDB.class_exists(cls_name):
		return {"error": "Unknown class: %s" % cls_name}

	# Prevent parallel tracking sessions from overwriting each other's state.
	# Only one tracking session is supported at a time.
	if _tracking_active:
		return {"error": "Tracking already active for class '%s'. Call stop_object_tracking first." % _tracked_class}

	# Take baseline count
	var baseline: int = _count_objects_of_class(cls_name)

	_tracking_active = true
	_tracked_class = cls_name
	_creation_log.clear()
	_tracking_start = Time.get_unix_time_from_system()

	# We can't truly intercept creation in editor mode,
	# so we record the baseline and return tracking info.
	# The user should call get_object_count later to see changes.
	return {"result": {
		"success": true,
		"class_name": cls_name,
		"baseline_count": baseline,
		"duration": duration,
		"tracking_start": _tracking_start,
		"message": "Tracking %s objects for %.1fs. Current count: %d. Call get_object_count('%s') after duration to see changes." % [
			cls_name, duration, baseline, cls_name
		],
	}}


## Stop object tracking and return the accumulated creation log.
func stop_object_tracking(_params: Dictionary) -> Dictionary:
	if not _tracking_active:
		return {"error": "No active object tracking. Call track_object_creation first."}

	var stop_time: float = Time.get_unix_time_from_system()
	var elapsed: float = stop_time - _tracking_start
	var tracked_class: String = _tracked_class
	var start_time: float = _tracking_start

	# Get the current count for comparison
	var current_count: int = _count_objects_of_class(tracked_class)

	# Snapshot tracking state before resetting
	var log_data: Array = _creation_log.duplicate()

	# Reset tracking state
	_tracking_active = false
	_tracked_class = ""
	_creation_log.clear()
	_tracking_start = 0.0

	return {"result": {
		"success": true,
		"class_name": tracked_class,
		"elapsed_seconds": "%.2f" % elapsed,
		"tracking_start": start_time,
		"tracking_stop": stop_time,
		"current_count": current_count,
		"creation_log": log_data,
		"log_entries": log_data.size(),
		"message": "Stopped tracking %s after %.1fs. Current count: %d. Creation log has %d entries." % [
			tracked_class, elapsed, current_count, log_data.size()
		],
	}}


## Analyze the scene tree and object graph to find potential memory leaks.
func find_memory_leaks(_params: Dictionary) -> Dictionary:
	var issues: Array = []

	# Check for orphan nodes.
	# In editor context, orphan nodes are expected (editor internals, scene
	# transition timing, addon previews). Only flag as a real issue at runtime.
	var is_editor: bool = Engine.is_editor_hint()
	var orphan_count: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	if orphan_count > 0:
		if is_editor:
			issues.append({
				"severity": "info",
				"type": "orphan_nodes",
				"count": orphan_count,
				"message": "%d orphan nodes detected (normal in editor context)." % orphan_count,
				"suggestion": "Orphan nodes are common in the editor due to internal editor nodes, addon previews, and scene transition timing. Run this check during gameplay for accurate leak detection.",
			})
		else:
			issues.append({
				"severity": "warning",
				"type": "orphan_nodes",
				"count": orphan_count,
				"message": "%d orphan nodes detected. These are nodes not in any scene tree." % orphan_count,
				"suggestion": "Ensure all dynamically created nodes are added to the scene tree or freed with queue_free(). For nodes already removed from tree, use call_deferred('free').",
			})

	# Check for high resource count
	var resource_count: int = int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	if resource_count > 5000:
		issues.append({
			"severity": "warning",
			"type": "high_resource_count",
			"count": resource_count,
			"message": "High resource count: %d. May indicate resource leaks." % resource_count,
			"suggestion": "Check for resources loaded in loops without caching. Use ResourceLoader.has_cached() to avoid duplicates.",
		})

	# Check static memory growth
	var mem_static: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	var mem_static_max: float = Performance.get_monitor(Performance.MEMORY_STATIC_MAX)
	if mem_static > mem_static_max * 0.9:
		issues.append({
			"severity": "critical",
			"type": "static_memory_near_limit",
			"current_mb": "%.1f" % (mem_static / (1024.0 * 1024.0)),
			"max_mb": "%.1f" % (mem_static_max / (1024.0 * 1024.0)),
			"message": "Static memory usage is at %.1f%% of maximum." % (mem_static / max(mem_static_max, 1.0) * 100.0),
			"suggestion": "Check for large allocations, leaked RefCounted objects, or circular references preventing cleanup.",
		})

	# Scan scene tree for nodes with scripts that might leak
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root != null:
		var suspicious: Array = _find_suspicious_nodes(root, 0)
		for entry: Dictionary in suspicious:
			issues.append(entry)

	# Check video memory
	var mem_video: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	if mem_video > 512 * 1024 * 1024:  # > 512MB
		issues.append({
			"severity": "warning",
			"type": "high_video_memory",
			"video_mb": "%.1f" % (mem_video / (1024.0 * 1024.0)),
			"message": "Video memory usage is high at %.1f MB." % (mem_video / (1024.0 * 1024.0)),
			"suggestion": "Check for uncompressed textures, duplicate mesh data, or render targets not being freed.",
		})

	return {"result": {
		"issue_count": issues.size(),
		"issues": issues,
		"orphan_nodes": orphan_count,
		"resource_count": resource_count,
		"static_memory_mb": "%.2f" % (mem_static / (1024.0 * 1024.0)),
		"video_memory_mb": "%.2f" % (mem_video / (1024.0 * 1024.0)),
		"clean": issues.is_empty(),
		"message": "Found %d potential issues" % issues.size() if issues.size() > 0 else "No memory issues detected",
	}}


## Get count of live objects, optionally filtered by class name.
func get_object_count(params: Dictionary) -> Dictionary:
	var cls_name: String = params.get("class_name", "")

	var total_objects: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var node_count: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var resource_count: int = int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))

	if cls_name.is_empty():
		return {"result": {
			"total_objects": total_objects,
			"nodes": node_count,
			"resources": resource_count,
		}}

	if not ClassDB.class_exists(cls_name):
		return {"error": "Unknown class: %s" % cls_name}

	var class_count: int = _count_objects_of_class(cls_name)

	return {"result": {
		"class_name": cls_name,
		"count": class_count,
		"total_objects": total_objects,
		"nodes": node_count,
		"resources": resource_count,
	}}


## Force garbage collection and report freed memory.
## LIMITATION: Godot does not expose a manual GC trigger API. RefCounted objects are freed
## immediately when references drop. This function only forces a brief pause to allow
## deferred queue_free() calls to complete. Reported changes reflect natural memory
## fluctuations, not forced collection.
func force_garbage_collection(_params: Dictionary) -> Dictionary:
	var mem_before: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	var objects_before: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var orphans_before: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))

	# Godot 4.x does not expose manual GC from GDScript.
	# Flush deferred queue_free() calls by ticking the scene tree.
	for i: int in range(3):
		OS.delay_msec(16)
		var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
		if root != null and root.is_inside_tree():
			root.get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, &"", &"__dummy_gc_tick")

	var mem_after: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	var objects_after: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var orphans_after: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))

	var freed_bytes: float = mem_before - mem_after
	var freed_objects: int = objects_before - objects_after

	return {"result": {
		"memory_before_mb": "%.2f" % (mem_before / (1024.0 * 1024.0)),
		"memory_after_mb": "%.2f" % (mem_after / (1024.0 * 1024.0)),
		"freed_mb": "%.2f" % (max(freed_bytes, 0.0) / (1024.0 * 1024.0)),
		"freed_bytes": max(freed_bytes, 0.0),
		"objects_before": objects_before,
		"objects_after": objects_after,
		"objects_freed": max(freed_objects, 0),
		"orphans_before": orphans_before,
		"orphans_after": orphans_after,
	}}


## Helper: Count objects of a specific class.
## For base classes (Object, Node, Resource, RefCounted), uses Performance
## monitors for engine-wide totals. For specific Node subclasses, walks from
## the editor's base control to cover all open scenes and editor UI.
## NOTE: Engine-wide per-class counting for non-Node classes is impossible from
## GDScript — ObjectDB::debug_objects() is C++-only. Base class approximations:
##   Object:     OBJECT_COUNT
##   Node:       OBJECT_NODE_COUNT
##   Resource:   OBJECT_RESOURCE_COUNT (path-cached Resources only — a subset)
##   RefCounted: OBJECT_COUNT - OBJECT_NODE_COUNT - OBJECT_ORPHAN_NODE_COUNT
##               ≈ RefCounted + rare plain Object instances (close approximation)
func _count_objects_of_class(cls_name: String) -> int:
	# For base classes, use Performance monitors — the only engine-wide counts
	# available from GDScript. Walking the scene tree alone misses
	# editor-internal nodes, singletons, and non-tree objects.
	if cls_name == "Object":
		return int(Performance.get_monitor(Performance.OBJECT_COUNT))
	if cls_name == "Node":
		return int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	if cls_name == "Resource":
		return int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	if cls_name == "RefCounted":
		# RefCounted ≈ total objects - all nodes (in-tree + orphan).
		# In the editor (DEBUG), OBJECT_ORPHAN_NODE_COUNT is available
		# and accounts for nodes not in any scene tree.
		# Slightly overcounts due to rare plain Object instances.
		var total: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
		var nodes_in_tree: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var orphan_nodes: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		return total - nodes_in_tree - orphan_nodes

	# For specific Node subclasses, walk from the editor's base control.
	# This covers ALL loaded scenes and the editor's own UI tree,
	# unlike get_edited_scene_root() which only covers one scene.
	var root: Node = _plugin.get_editor_interface().get_base_control()
	if root != null:
		return _count_class_recursive(root, cls_name)
	return 0


## Helper: Recursively count nodes of a class.
func _count_class_recursive(node: Node, cls_name: String) -> int:
	var count: int = 0
	if node.is_class(cls_name):
		count += 1
	for child: Node in node.get_children():
		count += _count_class_recursive(child, cls_name)
	return count


## Helper: Find nodes that might indicate memory issues.
func _find_suspicious_nodes(node: Node, depth: int) -> Array:
	var issues: Array = []

	# Flag very deep trees
	if depth > 50:
		issues.append({
			"severity": "info",
			"type": "deep_nesting",
			"path": MCPCommandHelpers.get_node_path(node, _plugin),
			"depth": depth,
			"message": "Node at depth %d: %s" % [depth, str(node.get_path())],
			"suggestion": "Very deep node trees can impact performance. Consider flattening.",
		})

	# Flag nodes with many children
	var child_count: int = node.get_child_count()
	if child_count > 200:
		issues.append({
			"severity": "warning",
			"type": "high_child_count",
			"path": str(node.get_path()),
			"child_count": child_count,
			"message": "Node '%s' has %d children" % [node.name, child_count],
			"suggestion": "Consider using pooling or spatial partitioning instead of many child nodes.",
		})

	for child: Node in node.get_children():
		issues.append_array(_find_suspicious_nodes(child, depth + 1))

	return issues
