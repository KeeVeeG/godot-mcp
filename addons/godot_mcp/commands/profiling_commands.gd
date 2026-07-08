## Profiling commands module - 2 tools.
## Provides performance monitor data and editor performance summaries.
class_name MCPProfilingCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func get_commands() -> Dictionary:
	return {
		"profiling/monitors": get_performance_monitors,
		"profiling/editor_performance": get_editor_performance,
	}


## Get all Performance monitor values. If specific monitor names are provided
## in params.monitors, only those are returned. Otherwise returns all.
func get_performance_monitors(params: Dictionary) -> Dictionary:
	var requested: Array = params.get("monitors", [])

	var all_monitors: Dictionary = {
		# Time
		"time/fps": Performance.get_monitor(Performance.TIME_FPS),
		"time/physics_process_time": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
		"time/process_time": Performance.get_monitor(Performance.TIME_PROCESS),
		"time/navigation_process_time": Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS),

		# Memory
		"memory/static": Performance.get_monitor(Performance.MEMORY_STATIC),
		"memory/static_max": Performance.get_monitor(Performance.MEMORY_STATIC_MAX),

		# Objects
		"object/object_count": Performance.get_monitor(Performance.OBJECT_COUNT),
		"object/resource_count": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"object/node_count": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"object/orphan_node_count": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),

		# Render
		"render/total_objects_in_frame": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"render/total_primitives_in_frame": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"render/total_draw_calls_in_frame": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"render/video_mem_used": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"render/texture_mem_used": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"render/buffer_mem_used": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED),

		# Physics
		"physics/active_objects": Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS),
		"physics/collision_pairs": Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS),
		"physics/island_count": Performance.get_monitor(Performance.PHYSICS_2D_ISLAND_COUNT),
		"physics_3d/active_objects": Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS),
		"physics_3d/collision_pairs": Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS),
		"physics_3d/island_count": Performance.get_monitor(Performance.PHYSICS_3D_ISLAND_COUNT),

		# Navigation
		"navigation/active_maps": Performance.get_monitor(Performance.NAVIGATION_ACTIVE_MAPS),
	}

	# If specific monitors requested, filter
	if requested.size() > 0:
		var filtered: Dictionary = {}
		for name_variant: Variant in requested:
			var name: String = name_variant as String
			if all_monitors.has(name):
				filtered[name] = all_monitors[name]
			else:
				filtered[name] = {"error": "Unknown monitor: %s" % name}
		return {"result": filtered}

	return {"result": all_monitors}


## Get a summary of editor performance: FPS, memory, physics, and render stats.
## Delegates to get_performance_monitors for raw data.
func get_editor_performance(params: Dictionary) -> Dictionary:
	var raw_result: Dictionary = get_performance_monitors(params)
	var monitors: Dictionary = raw_result.get("result", {})

	var fps: float = monitors.get("time/fps", 0.0) as float
	var process_time: float = monitors.get("time/process_time", 0.0) as float
	var physics_time: float = monitors.get("time/physics_process_time", 0.0) as float
	var mem_static: float = monitors.get("memory/static", 0.0) as float
	var mem_video: float = monitors.get("render/video_mem_used", 0.0) as float
	var mem_texture: float = monitors.get("render/texture_mem_used", 0.0) as float
	var object_count: int = int(monitors.get("object/object_count", 0))
	var node_count: int = int(monitors.get("object/node_count", 0))
	var resource_count: int = int(monitors.get("object/resource_count", 0))
	var orphan_count: int = int(monitors.get("object/orphan_node_count", 0))
	var draw_calls: int = int(monitors.get("render/total_draw_calls_in_frame", 0))
	var total_objects: int = int(monitors.get("render/total_objects_in_frame", 0))
	var total_primitives: int = int(monitors.get("render/total_primitives_in_frame", 0))
	var physics_2d_active: int = int(monitors.get("physics/active_objects", 0))
	var physics_3d_active: int = int(monitors.get("physics_3d/active_objects", 0))

	# Determine performance rating with editor-aware thresholds
	var rating: String = "good"
	var is_editor: bool = not _plugin.get_editor_interface().is_playing_scene()
	if is_editor:
		if fps < 5.0:
			rating = "critical"
		elif fps < 15.0:
			rating = "warning"
	else:
		if fps < 30.0:
			rating = "critical"
		elif fps < 50.0:
			rating = "warning"

	return {"result": {
		"fps": fps,
		"rating": rating,
		"timing": {
			"process_ms": process_time,
			"physics_ms": physics_time,
		},
		"memory": {
			"static_bytes": mem_static,
			"static_mb": "%.1f" % (mem_static / (1024.0 * 1024.0)),
			"video_bytes": mem_video,
			"video_mb": "%.1f" % (mem_video / (1024.0 * 1024.0)),
			"texture_bytes": mem_texture,
			"texture_mb": "%.1f" % (mem_texture / (1024.0 * 1024.0)),
		},
		"objects": {
			"total": object_count,
			"nodes": node_count,
			"resources": resource_count,
			"orphan_nodes": orphan_count,
		},
		"render": {
			"draw_calls": draw_calls,
			"objects_in_frame": total_objects,
			"primitives_in_frame": total_primitives,
		},
		"physics": {
			"active_2d": physics_2d_active,
			"active_3d": physics_3d_active,
		},
	}}
