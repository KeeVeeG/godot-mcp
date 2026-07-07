## Navigation commands module - 9 tools.
## Handles NavigationRegion, NavigationAgent, NavigationLink, and navmesh baking.
class_name MCPNavigationCommands
extends RefCounted

var _plugin: EditorPlugin
var _undo_helper: MCUndoHelper


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin
	if _plugin.has_method("get_undo_helper"):
		_undo_helper = _plugin.get_undo_helper()


func get_commands() -> Dictionary:
	return {
		"navigation/setup_region": setup_navigation_region,
		"navigation/setup_agent": setup_navigation_agent,
		"navigation/bake_mesh": bake_navigation_mesh,
		"navigation/set_layers": set_navigation_layers,
		"navigation/get_info": get_navigation_info,
		"navigation/setup_link": setup_navigation_link,
		"navigation/find_path": find_navigation_path,
		"navigation/remove_region": func(params: Dictionary) -> Dictionary: return execute("remove_navigation_region", params),
		"navigation/remove_agent": func(params: Dictionary) -> Dictionary: return execute("remove_navigation_agent", params),
		"navigation/remove_link": func(params: Dictionary) -> Dictionary: return execute("remove_navigation_link", params),
	}


func execute(command: String, params: Dictionary) -> Dictionary:
	match command:
		"remove_navigation_region": return _remove_navigation_node(params, "NavigationRegion")
		"remove_navigation_agent": return _remove_navigation_node(params, "NavigationAgent")
		"remove_navigation_link": return _remove_navigation_node(params, "NavigationLink")
		_: return {"error": "Unknown command: %s" % command}


## Setup a NavigationRegion2D or NavigationRegion3D. Configures an existing node
## or creates a new one when parent_path is provided.
func setup_navigation_region(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var parent_path: String = params.get("parent", params.get("parent_path", ""))
	var dimension: String = params.get("dimension", "2d")
	var properties: Dictionary = params.get("properties", {})
	var node_name: String = params.get("name", "")

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	# Try to configure an existing node first
	if not path.is_empty():
		var existing: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
		if existing != null:
			if existing is NavigationRegion2D:
				var nr: NavigationRegion2D = existing as NavigationRegion2D
				if properties.has("enabled"):
					nr.enabled = properties["enabled"] as bool
				if properties.has("navigation_polygon"):
					var navpoly: NavigationPolygon = ResourceLoader.load(properties["navigation_polygon"] as String) as NavigationPolygon
					if navpoly:
						nr.navigation_polygon = navpoly
				if properties.has("navigation_layers"):
					nr.navigation_layers = properties["navigation_layers"] as int
				return {"result": "NavigationRegion configured: %s" % path}
			elif existing is NavigationRegion3D:
				var nr3: NavigationRegion3D = existing as NavigationRegion3D
				if properties.has("enabled"):
					nr3.enabled = properties["enabled"] as bool
				if properties.has("navigation_mesh"):
					var navmesh: NavigationMesh = ResourceLoader.load(properties["navigation_mesh"] as String) as NavigationMesh
					if navmesh:
						nr3.navigation_mesh = navmesh
				if properties.has("navigation_layers"):
					nr3.navigation_layers = properties["navigation_layers"] as int
				return {"result": "NavigationRegion configured: %s" % path}
			else:
				return {"error": "Node is not a NavigationRegion: %s" % existing.get_class()}

	# Create a new node
	var parent: Node = root
	if parent_path != "":
		parent = MCPCommandHelpers.resolve_node_path(_plugin, parent_path)
	if parent == null:
		return {"error": "Parent not found"}

	var nav_node: Node = null
	match dimension:
		"2d":
			var region2d: NavigationRegion2D = NavigationRegion2D.new()
			if properties.has("enabled"):
				region2d.enabled = properties["enabled"] as bool
			if properties.has("navigation_layers"):
				region2d.navigation_layers = properties["navigation_layers"] as int
			if properties.has("navigation_polygon"):
				var navpoly2: NavigationPolygon = ResourceLoader.load(properties["navigation_polygon"] as String) as NavigationPolygon
				if navpoly2:
					region2d.navigation_polygon = navpoly2
			elif properties.has("polygon"):
				var navpoly3: NavigationPolygon = NavigationPolygon.new()
				var points: Array = properties["polygon"] as Array
				var packed: PackedVector2Array = PackedVector2Array()
				for pt: Variant in points:
					packed.append(MCPVariantCodec._parse_vector2(pt))
				navpoly3.add_outline(packed)
				navpoly3.make_polygons_from_outlines()
				region2d.navigation_polygon = navpoly3
			nav_node = region2d
		"3d":
			var region3d: NavigationRegion3D = NavigationRegion3D.new()
			if properties.has("enabled"):
				region3d.enabled = properties["enabled"] as bool
			if properties.has("navigation_layers"):
				region3d.navigation_layers = properties["navigation_layers"] as int
			if properties.has("navigation_mesh"):
				var navmesh2: NavigationMesh = ResourceLoader.load(properties["navigation_mesh"] as String) as NavigationMesh
				if navmesh2:
					region3d.navigation_mesh = navmesh2
			nav_node = region3d
		_:
			return {"error": "Invalid dimension: use '2d' or '3d'"}

	if node_name.is_empty():
		nav_node.name = "NavigationRegion" + ("2D" if dimension == "2d" else "3D")
	else:
		nav_node.name = node_name

	if _undo_helper:
		_undo_helper.add_node_with_undo(nav_node, parent)
	else:
		parent.add_child(nav_node)
		nav_node.set_owner(root)

	return {"result": {"name": str(nav_node.name), "path": str(nav_node.get_path()), "dimension": dimension}}


## Setup a NavigationAgent2D or NavigationAgent3D. Configures an existing node
## or creates a new one when parent_path is provided.
func setup_navigation_agent(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var parent_path: String = params.get("parent", params.get("parent_path", ""))
	var dimension: String = params.get("dimension", "2d")
	var properties: Dictionary = params.get("properties", {})
	var node_name: String = params.get("name", "")

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	# Try to configure an existing node
	if not path.is_empty():
		var existing: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
		if existing != null:
			if existing is NavigationAgent2D:
				var na: NavigationAgent2D = existing as NavigationAgent2D
				if properties.has("radius"):
					na.radius = properties["radius"] as float
				if properties.has("speed"):
					na.max_speed = properties["speed"] as float
				if properties.has("max_speed"):
					na.max_speed = properties["max_speed"] as float
				if properties.has("target_desired_distance"):
					na.target_desired_distance = properties["target_desired_distance"] as float
				if properties.has("path_desired_distance"):
					na.path_desired_distance = properties["path_desired_distance"] as float
				if properties.has("avoidance_enabled"):
					na.avoidance_enabled = properties["avoidance_enabled"] as bool
				if properties.has("navigation_layers"):
					na.navigation_layers = properties["navigation_layers"] as int
				return {"result": "NavigationAgent configured: %s" % path}
			elif existing is NavigationAgent3D:
				var na3: NavigationAgent3D = existing as NavigationAgent3D
				if properties.has("radius"):
					na3.radius = properties["radius"] as float
				if properties.has("speed"):
					na3.max_speed = properties["speed"] as float
				if properties.has("max_speed"):
					na3.max_speed = properties["max_speed"] as float
				if properties.has("target_desired_distance"):
					na3.target_desired_distance = properties["target_desired_distance"] as float
				if properties.has("path_desired_distance"):
					na3.path_desired_distance = properties["path_desired_distance"] as float
				if properties.has("avoidance_enabled"):
					na3.avoidance_enabled = properties["avoidance_enabled"] as bool
				if properties.has("navigation_layers"):
					na3.navigation_layers = properties["navigation_layers"] as int
				if properties.has("path_height_offset"):
					na3.path_height_offset = properties["path_height_offset"] as float
				return {"result": "NavigationAgent configured: %s" % path}
			else:
				return {"error": "Node is not a NavigationAgent: %s" % existing.get_class()}

	# Create a new node
	var parent: Node = root
	if parent_path != "":
		parent = MCPCommandHelpers.resolve_node_path(_plugin, parent_path)
	if parent == null:
		return {"error": "Parent not found"}

	var agent_node: Node = null
	match dimension:
		"2d":
			var agent2d: NavigationAgent2D = NavigationAgent2D.new()
			if properties.has("radius"):
				agent2d.radius = properties["radius"] as float
			if properties.has("speed"):
				agent2d.max_speed = properties["speed"] as float
			if properties.has("max_speed"):
				agent2d.max_speed = properties["max_speed"] as float
			if properties.has("target_desired_distance"):
				agent2d.target_desired_distance = properties["target_desired_distance"] as float
			if properties.has("path_desired_distance"):
				agent2d.path_desired_distance = properties["path_desired_distance"] as float
			if properties.has("avoidance_enabled"):
				agent2d.avoidance_enabled = properties["avoidance_enabled"] as bool
			if properties.has("navigation_layers"):
				agent2d.navigation_layers = properties["navigation_layers"] as int
			if properties.has("time_horizon"):
				agent2d.time_horizon = properties["time_horizon"] as float
			agent_node = agent2d
		"3d":
			var agent3d: NavigationAgent3D = NavigationAgent3D.new()
			if properties.has("radius"):
				agent3d.radius = properties["radius"] as float
			if properties.has("speed"):
				agent3d.max_speed = properties["speed"] as float
			if properties.has("max_speed"):
				agent3d.max_speed = properties["max_speed"] as float
			if properties.has("target_desired_distance"):
				agent3d.target_desired_distance = properties["target_desired_distance"] as float
			if properties.has("path_desired_distance"):
				agent3d.path_desired_distance = properties["path_desired_distance"] as float
			if properties.has("avoidance_enabled"):
				agent3d.avoidance_enabled = properties["avoidance_enabled"] as bool
			if properties.has("navigation_layers"):
				agent3d.navigation_layers = properties["navigation_layers"] as int
			if properties.has("path_height_offset"):
				agent3d.path_height_offset = properties["path_height_offset"] as float
			if properties.has("time_horizon"):
				agent3d.time_horizon = properties["time_horizon"] as float
			agent_node = agent3d
		_:
			return {"error": "Invalid dimension: use '2d' or '3d'"}

	if node_name.is_empty():
		agent_node.name = "NavigationAgent" + ("2D" if dimension == "2d" else "3D")
	else:
		agent_node.name = node_name

	# Apply remaining properties
	for prop: String in properties:
		if MCPCommandHelpers.has_property(agent_node, prop):
			agent_node.set(prop, properties[prop])

	if _undo_helper:
		_undo_helper.add_node_with_undo(agent_node, parent)
	else:
		parent.add_child(agent_node)
		agent_node.set_owner(root)

	return {"result": {"name": str(agent_node.name), "path": str(agent_node.get_path()), "dimension": dimension}}


## Bake a navigation mesh for a NavigationRegion. Uses NavigationServer for
## 3D regions and supports bake configuration properties.
func bake_navigation_mesh(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var properties: Dictionary = params.get("properties", {})

	if node is NavigationRegion3D:
		var nr: NavigationRegion3D = node as NavigationRegion3D
		if nr.navigation_mesh == null:
			nr.navigation_mesh = NavigationMesh.new()

		var nav_mesh: NavigationMesh = nr.navigation_mesh
		# Configure bake settings
		if properties.has("cell_size"):
			nav_mesh.cell_size = properties["cell_size"] as float
		if properties.has("cell_height"):
			nav_mesh.cell_height = properties["cell_height"] as float
		if properties.has("agent_radius"):
			nav_mesh.agent_radius = properties["agent_radius"] as float
		if properties.has("agent_height"):
			nav_mesh.agent_height = properties["agent_height"] as float
		if properties.has("agent_max_climb"):
			nav_mesh.agent_max_climb = properties["agent_max_climb"] as float
		if properties.has("agent_max_slope"):
			nav_mesh.agent_max_slope = properties["agent_max_slope"] as float

		# Use NavigationServer to bake from source geometry (async to avoid editor freeze)
		var source_geom: NavigationMeshSourceGeometryData3D = NavigationMeshSourceGeometryData3D.new()
		var root_node: Node = MCPCommandHelpers.get_scene_root(_plugin)
		if root_node:
			var bake_done: Array = [false]
			var bake_callback: Callable = func() -> void: bake_done[0] = true
			NavigationServer3D.parse_source_geometry_data(nav_mesh, source_geom, root_node)
			NavigationServer3D.bake_from_source_geometry_data_async(nav_mesh, source_geom, bake_callback)

		nr.navigation_mesh = nav_mesh
		return {"result": "Navigation mesh bake started for 3D region: %s (async — check region for completion)" % path}

	elif node is NavigationRegion2D:
		var nr2: NavigationRegion2D = node as NavigationRegion2D
		if nr2.navigation_polygon == null:
			nr2.navigation_polygon = NavigationPolygon.new()

		var nav_poly: NavigationPolygon = nr2.navigation_polygon
		if properties.has("agent_radius"):
			nav_poly.agent_radius = properties["agent_radius"] as float

		# Use NavigationServer to bake from source geometry (async to avoid editor freeze)
		var source_geom2d: NavigationMeshSourceGeometryData2D = NavigationMeshSourceGeometryData2D.new()
		var root_node2d: Node = MCPCommandHelpers.get_scene_root(_plugin)
		if root_node2d:
			var bake_done_2d: Array = [false]
			var bake_callback_2d: Callable = func() -> void: bake_done_2d[0] = true
			NavigationServer2D.parse_source_geometry_data(nav_poly, source_geom2d, root_node2d)
			NavigationServer2D.bake_from_source_geometry_data_async(nav_poly, source_geom2d, bake_callback_2d)

		nr2.navigation_polygon = nav_poly
		return {"result": "Navigation polygon bake started for 2D region: %s (async — check region for completion)" % path}

	else:
		return {"error": "Node is not a NavigationRegion: %s" % node.get_class()}


## Set navigation layers on a navigation node (region, agent, or link).
func set_navigation_layers(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var layer: int = params.get("layer", 0)
	var mask: int = params.get("mask", 0)
	if path.is_empty():
		return {"error": "Path is required"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	if node is NavigationRegion2D:
		var nr: NavigationRegion2D = node as NavigationRegion2D
		if layer > 0:
			if _undo_helper:
				_undo_helper.set_property_with_undo(nr, "navigation_layers", layer)
			else:
				nr.navigation_layers = layer
	elif node is NavigationRegion3D:
		var nr3: NavigationRegion3D = node as NavigationRegion3D
		if layer > 0:
			if _undo_helper:
				_undo_helper.set_property_with_undo(nr3, "navigation_layers", layer)
			else:
				nr3.navigation_layers = layer
	elif node is NavigationAgent2D:
		var na: NavigationAgent2D = node as NavigationAgent2D
		if layer > 0:
			if _undo_helper:
				_undo_helper.set_property_with_undo(na, "navigation_layers", layer)
			else:
				na.navigation_layers = layer
	elif node is NavigationAgent3D:
		var na3: NavigationAgent3D = node as NavigationAgent3D
		if layer > 0:
			if _undo_helper:
				_undo_helper.set_property_with_undo(na3, "navigation_layers", layer)
			else:
				na3.navigation_layers = layer
	elif node is NavigationLink2D:
		var link2d: NavigationLink2D = node as NavigationLink2D
		if layer > 0:
			if _undo_helper:
				_undo_helper.set_property_with_undo(link2d, "navigation_layers", layer)
			else:
				link2d.navigation_layers = layer
	elif node is NavigationLink3D:
		var link3d: NavigationLink3D = node as NavigationLink3D
		if layer > 0:
			if _undo_helper:
				_undo_helper.set_property_with_undo(link3d, "navigation_layers", layer)
			else:
				link3d.navigation_layers = layer
	else:
		return {"error": "Node does not support navigation layers: %s" % node.get_class()}

	return {"result": "Navigation layers set on %s (layer=%d)" % [path, layer]}


## Get navigation info from a navigation node.
func get_navigation_info(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var result: Dictionary = {"path": path, "type": node.get_class()}
	if node is NavigationRegion2D:
		var nr: NavigationRegion2D = node as NavigationRegion2D
		result["enabled"] = nr.enabled
		result["navigation_layers"] = nr.navigation_layers
		if nr.navigation_polygon:
			result["has_polygon"] = true
			result["polygon_path"] = nr.navigation_polygon.resource_path
		else:
			result["has_polygon"] = false
	elif node is NavigationRegion3D:
		var nr3: NavigationRegion3D = node as NavigationRegion3D
		result["enabled"] = nr3.enabled
		result["navigation_layers"] = nr3.navigation_layers
		if nr3.navigation_mesh:
			result["has_mesh"] = true
			result["mesh_path"] = nr3.navigation_mesh.resource_path
			var mesh: NavigationMesh = nr3.navigation_mesh
			result["vertices_count"] = mesh.get_vertices().size()
			result["polygon_count"] = mesh.get_polygon_count()
			result["cell_size"] = mesh.cell_size
			result["cell_height"] = mesh.cell_height
			result["agent_radius"] = mesh.agent_radius
			result["agent_height"] = mesh.agent_height
		else:
			result["has_mesh"] = false
	elif node is NavigationAgent2D:
		var na: NavigationAgent2D = node as NavigationAgent2D
		result["radius"] = na.radius
		result["max_speed"] = na.max_speed
		result["target_desired_distance"] = na.target_desired_distance
		result["path_desired_distance"] = na.path_desired_distance
		result["avoidance_enabled"] = na.avoidance_enabled
		result["navigation_layers"] = na.navigation_layers
		result["is_target_reached"] = na.is_target_reached()
		if na.is_navigation_finished():
			result["navigation_finished"] = true
		else:
			var next2d: Vector2 = na.get_next_path_position()
			result["next_path_position"] = {"x": next2d.x, "y": next2d.y}
			result["distance_to_target"] = na.distance_to_target()
	elif node is NavigationAgent3D:
		var na3: NavigationAgent3D = node as NavigationAgent3D
		result["radius"] = na3.radius
		result["max_speed"] = na3.max_speed
		result["target_desired_distance"] = na3.target_desired_distance
		result["path_desired_distance"] = na3.path_desired_distance
		result["avoidance_enabled"] = na3.avoidance_enabled
		result["navigation_layers"] = na3.navigation_layers
		result["is_target_reached"] = na3.is_target_reached()
		if na3.is_navigation_finished():
			result["navigation_finished"] = true
		else:
			var next3d: Vector3 = na3.get_next_path_position()
			result["next_path_position"] = {"x": next3d.x, "y": next3d.y, "z": next3d.z}
			result["distance_to_target"] = na3.distance_to_target()
		result["path_height_offset"] = na3.path_height_offset
	elif node is NavigationLink2D:
		var link2d: NavigationLink2D = node as NavigationLink2D
		result["enabled"] = link2d.enabled
		result["navigation_layers"] = link2d.navigation_layers
		var start2d: Vector2 = link2d.start_position
		var end2d: Vector2 = link2d.end_position
		result["start_position"] = {"x": start2d.x, "y": start2d.y}
		result["end_position"] = {"x": end2d.x, "y": end2d.y}
		result["bidirectional"] = link2d.bidirectional
	elif node is NavigationLink3D:
		var link3d: NavigationLink3D = node as NavigationLink3D
		result["enabled"] = link3d.enabled
		result["navigation_layers"] = link3d.navigation_layers
		var start3d: Vector3 = link3d.start_position
		var end3d: Vector3 = link3d.end_position
		result["start_position"] = {"x": start3d.x, "y": start3d.y, "z": start3d.z}
		result["end_position"] = {"x": end3d.x, "y": end3d.y, "z": end3d.z}
		result["bidirectional"] = link3d.bidirectional
	else:
		return {"error": "Node does not have navigation info: %s" % node.get_class()}

	return {"result": result}


## Setup a NavigationLink2D or NavigationLink3D for connecting navigation regions.
func setup_navigation_link(params: Dictionary) -> Dictionary:
	var parent_path: String = params.get("parent", params.get("parent_path", ""))
	var dimension: String = params.get("dimension", "2d")
	var properties: Dictionary = params.get("properties", {})
	var node_name: String = params.get("name", "")

	var parent: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if parent_path != "":
		parent = MCPCommandHelpers.resolve_node_path(_plugin, parent_path)
	if parent == null:
		return {"error": "Parent not found"}

	var link_node: Node = null
	match dimension:
		"2d":
			var link2d: NavigationLink2D = NavigationLink2D.new()
			if properties.has("start_position"):
				link2d.start_position = MCPVariantCodec._parse_vector2(properties["start_position"])
			if properties.has("end_position"):
				link2d.end_position = MCPVariantCodec._parse_vector2(properties["end_position"])
			if properties.has("bidirectional"):
				link2d.bidirectional = properties["bidirectional"] as bool
			if properties.has("enabled"):
				link2d.enabled = properties["enabled"] as bool
			if properties.has("navigation_layers"):
				link2d.navigation_layers = properties["navigation_layers"] as int
			link_node = link2d
		"3d":
			var link3d: NavigationLink3D = NavigationLink3D.new()
			if properties.has("start_position"):
				link3d.start_position = MCPVariantCodec._parse_vector3(properties["start_position"])
			if properties.has("end_position"):
				link3d.end_position = MCPVariantCodec._parse_vector3(properties["end_position"])
			if properties.has("bidirectional"):
				link3d.bidirectional = properties["bidirectional"] as bool
			if properties.has("enabled"):
				link3d.enabled = properties["enabled"] as bool
			if properties.has("navigation_layers"):
				link3d.navigation_layers = properties["navigation_layers"] as int
			link_node = link3d
		_:
			return {"error": "Invalid dimension: use '2d' or '3d'"}

	if node_name.is_empty():
		link_node.name = "NavigationLink" + ("2D" if dimension == "2d" else "3D")
	else:
		link_node.name = node_name

	# Apply remaining properties
	for prop: String in properties:
		if MCPCommandHelpers.has_property(link_node, prop):
			link_node.set(prop, properties[prop])

	if _undo_helper:
		_undo_helper.add_node_with_undo(link_node, parent)
	else:
		parent.add_child(link_node)
		link_node.set_owner(MCPCommandHelpers.get_scene_root(_plugin))

	return {"result": {"name": str(link_node.name), "path": str(link_node.get_path()), "dimension": dimension}}


## Find a navigation path between two points using NavigationServer.
## Optional "map" parameter specifies a NavigationRegion path to use its map.
func find_navigation_path(params: Dictionary) -> Dictionary:
	var start: Array = params.get("start", [])
	var end: Array = params.get("end", [])
	var dimension: String = params.get("dimension", "2d")
	var map_region_path: String = params.get("map", "")
	if start.size() < 2 or end.size() < 2:
		return {"error": "start and end must be arrays with at least 2 elements [x, y]"}
	var path: PackedVector2Array = PackedVector2Array()
	var path3d: PackedVector3Array = PackedVector3Array()
	match dimension:
		"2d":
			var start_vec: Vector2 = Vector2(start[0] as float, start[1] as float)
			var end_vec: Vector2 = Vector2(end[0] as float, end[1] as float)
			var map_rid: RID = RID()
			# Use specified region's map if provided
			if not map_region_path.is_empty():
				var region_node: Node = MCPCommandHelpers.resolve_node_path(_plugin, map_region_path)
				if region_node != null and region_node is NavigationRegion2D:
					map_rid = NavigationServer2D.region_get_map((region_node as NavigationRegion2D).get_rid())
			if map_rid == RID():
				var maps: Array = NavigationServer2D.get_maps()
				map_rid = maps[0] if maps.size() > 0 else RID()
			if map_rid == RID():
				return {"error": "No navigation map available"}
			path = NavigationServer2D.map_get_path(map_rid, start_vec, end_vec, true)
			var result: Array = []
			for pt: Vector2 in path:
				result.append({"x": pt.x, "y": pt.y})
			return {"result": {"path": result, "point_count": result.size(), "dimension": "2d"}}
		"3d":
			var start_vec3: Vector3 = Vector3(start[0] as float, start[1] as float, start[2] as float if start.size() > 2 else 0.0)
			var end_vec3: Vector3 = Vector3(end[0] as float, end[1] as float, end[2] as float if end.size() > 2 else 0.0)
			var map_rid3: RID = RID()
			# Use specified region's map if provided
			if not map_region_path.is_empty():
				var region_node3: Node = MCPCommandHelpers.resolve_node_path(_plugin, map_region_path)
				if region_node3 != null and region_node3 is NavigationRegion3D:
					map_rid3 = NavigationServer3D.region_get_map((region_node3 as NavigationRegion3D).get_rid())
			if map_rid3 == RID():
				var maps3: Array = NavigationServer3D.get_maps()
				map_rid3 = maps3[0] if maps3.size() > 0 else RID()
			if map_rid3 == RID():
				return {"error": "No navigation map available"}
			path3d = NavigationServer3D.map_get_path(map_rid3, start_vec3, end_vec3, true)
			var result3: Array = []
			for pt3: Vector3 in path3d:
				result3.append({"x": pt3.x, "y": pt3.y, "z": pt3.z})
			return {"result": {"path": result3, "point_count": result3.size(), "dimension": "3d"}}
		_:
			return {"error": "Invalid dimension: use '2d' or '3d'"}


## Remove a navigation node from the scene.
func _remove_navigation_node(params: Dictionary, expected_class: String) -> Dictionary:
	var node_path: String = params.get("node_path", params.get("path", ""))
	if node_path.is_empty():
		return {"error": "node_path is required"}
	
	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}
	
	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	
	if node == root:
		return {"error": "Cannot remove scene root"}
	
	# Use `is` operator for proper type inheritance checking.
	# Note: In Godot 4.x, there is no NavigationRegion/NavigationAgent/NavigationLink
	# base class - they are split into 2D/3D variants, so is_class() with the base name
	# would incorrectly fail.
	var is_valid_type: bool = false
	match expected_class:
		"NavigationRegion":
			is_valid_type = node is NavigationRegion2D or node is NavigationRegion3D
		"NavigationAgent":
			is_valid_type = node is NavigationAgent2D or node is NavigationAgent3D
		"NavigationLink":
			is_valid_type = node is NavigationLink2D or node is NavigationLink3D
	if not is_valid_type:
		return {"error": "Node is not a %s: %s" % [expected_class, node.get_class()]}
	
	var parent: Node = node.get_parent()
	if parent == null:
		return {"error": "Node has no parent"}
	
	if _undo_helper:
		_undo_helper.remove_node_with_undo(node)
	else:
		parent.remove_child(node)
	
	return {"result": {"removed": node_path, "type": node.get_class()}}
