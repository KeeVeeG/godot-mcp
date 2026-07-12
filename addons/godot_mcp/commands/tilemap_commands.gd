## TileMap and GridMap commands module - 11 tools.
@tool
class_name MCPTileMapCommands
extends RefCounted

var _plugin: EditorPlugin
var _undo_helper: MCUndoHelper


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin
	if _plugin.has_method("get_undo_helper"):
		_undo_helper = _plugin.get_undo_helper()


func get_commands() -> Dictionary:
	return {
		"tilemap/set_cell": tilemap_set_cell,
		"tilemap/fill_rect": tilemap_fill_rect,
		"tilemap/get_cell": tilemap_get_cell,
		"tilemap/clear": tilemap_clear,
		"tilemap/get_info": tilemap_get_info,
		"tilemap/get_used_cells": tilemap_get_used_cells,
		"gridmap/set_cell": gridmap_set_cell,
		"gridmap/get_cell": gridmap_get_cell,
		"gridmap/clear": gridmap_clear,
		"gridmap/get_used_cells": gridmap_get_used_cells,
		"gridmap/get_info": gridmap_get_info,
	}


## Resolve a TileMapLayer from a path. Accepts either a TileMapLayer node
## directly or a TileMap parent with an optional layer index.
func _get_tilemap_layer(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "TileMapLayer path is required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	# Direct TileMapLayer
	if node is TileMapLayer:
		var tml: TileMapLayer = node as TileMapLayer
		if tml.tile_set == null:
			return {"error": "TileMapLayer has no TileSet assigned: %s" % path}
		return {"layer": tml}

	# Legacy TileMap parent - resolve layer by index
	if node is TileMap:
		var tilemap: TileMap = node as TileMap
		var layer_idx: int = params.get("layer", 0)
		if layer_idx < 0 or layer_idx >= tilemap.get_layers_count():
			return {"error": "Invalid layer index %d (tilemap has %d layers)" % [layer_idx, tilemap.get_layers_count()]}
		# Count only TileMapLayer children (skip internal nodes like @NavigationRegion3D@)
		var tilemap_layer_idx: int = 0
		for child: Node in tilemap.get_children(true):
			if child is TileMapLayer:
				if tilemap_layer_idx == layer_idx:
					return {"layer": child as TileMapLayer}
				tilemap_layer_idx += 1
		# Fallback: return error suggesting TileMapLayer usage
		return {"error": "No TileMapLayer found at index %d. Use TileMapLayer nodes instead of legacy TileMap." % layer_idx}

	return {"error": "Node is not a TileMapLayer or TileMap: %s" % path}


## Set a single cell in the tilemap layer.
func tilemap_set_cell(params: Dictionary) -> Dictionary:
	var resolved: Dictionary = _get_tilemap_layer(params)
	if resolved.has("error"):
		return resolved
	var layer: TileMapLayer = resolved["layer"] as TileMapLayer

	var coords_raw: Variant = params.get("coords", {})
	var source_id: int = params.get("source_id", 0)
	var atlas_coords_raw: Variant = params.get("atlas_coords", {})
	var alternative: int = params.get("alternative_tile", 0)

	var cell: Vector2i = Vector2i.ZERO
	if coords_raw is Array:
		var arr: Array = coords_raw as Array
		cell = Vector2i(arr[0] as int, arr[1] as int) if arr.size() >= 2 else Vector2i.ZERO
	elif coords_raw is Dictionary:
		var d: Dictionary = coords_raw as Dictionary
		cell = Vector2i(d.get("x", 0) as int, d.get("y", 0) as int)

	var atlas: Vector2i = Vector2i(0, 0)
	if atlas_coords_raw is Array:
		var arr2: Array = atlas_coords_raw as Array
		atlas = Vector2i(arr2[0] as int, arr2[1] as int) if arr2.size() >= 2 else Vector2i(0, 0)
	elif atlas_coords_raw is Dictionary:
		var d2: Dictionary = atlas_coords_raw as Dictionary
		atlas = Vector2i(d2.get("x", 0) as int, d2.get("y", 0) as int)

	# Capture old cell state for undo
	var old_source: int = layer.get_cell_source_id(cell)
	var old_atlas: Vector2i = layer.get_cell_atlas_coords(cell)
	var old_alt: int = layer.get_cell_alternative_tile(cell)
	
	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Set tilemap cell (%d,%d)" % [cell.x, cell.y])
	ur.add_do_method(layer, "set_cell", cell, source_id, atlas, alternative)
	ur.add_undo_method(layer, "set_cell", cell, old_source, old_atlas, old_alt)
	ur.commit_action()
	
	return {"result": "Cell set at (%d, %d) source=%d atlas=(%d,%d)" % [cell.x, cell.y, source_id, atlas.x, atlas.y]}


## Fill a rectangle region with tiles.
## Uses batch apply + single undo capture to avoid undo-system overload
## and main-thread blocking on large rects.
func tilemap_fill_rect(params: Dictionary) -> Dictionary:
	var resolved: Dictionary = _get_tilemap_layer(params)
	if resolved.has("error"):
		return resolved
	var layer: TileMapLayer = resolved["layer"] as TileMapLayer

	var rect: Dictionary = params.get("rect", {})
	var source_id: int = params.get("source_id", 0)
	var atlas_coords_raw: Variant = params.get("atlas_coords", {})
	var alternative: int = params.get("alternative_tile", 0)

	var x_start: int = rect.get("x", 0) as int
	var y_start: int = rect.get("y", 0) as int
	var width: int = rect.get("width", rect.get("w", 1)) as int
	var height: int = rect.get("height", rect.get("h", 1)) as int
	var total_cells: int = width * height
	
	# Prevent editor freeze with huge rects
	if total_cells > 10000:
		return {"error": "Rect too large (%d cells). Maximum is 10,000 cells to prevent undo system overload." % total_cells}
	
	var atlas: Vector2i = Vector2i(0, 0)
	if atlas_coords_raw is Array:
		var arr: Array = atlas_coords_raw as Array
		atlas = Vector2i(arr[0] as int, arr[1] as int) if arr.size() >= 2 else Vector2i(0, 0)
	elif atlas_coords_raw is Dictionary:
		var d: Dictionary = atlas_coords_raw as Dictionary
		atlas = Vector2i(d.get("x", 0) as int, d.get("y", 0) as int)

	# Capture old state for undo � ALL cells (including empty) so undo fully restores the rect
	var old_cells: Dictionary = {}
	for x: int in range(x_start, x_start + width):
		for y: int in range(y_start, y_start + height):
			var cell_pos: Vector2i = Vector2i(x, y)
			var old_source: int = layer.get_cell_source_id(cell_pos)
			old_cells[cell_pos] = {
				"source": old_source,
				"atlas": layer.get_cell_atlas_coords(cell_pos),
				"alt": layer.get_cell_alternative_tile(cell_pos),
			}
			# Apply new cell immediately (outside undo action � one shot, not 2N entries)
			layer.set_cell(cell_pos, source_id, atlas, alternative)

	# Single undo action: restore old cells via helper
	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Fill tilemap rect (%d,%d,%d,%d)" % [x_start, y_start, width, height])
	ur.add_do_method(self, "_apply_fill_cells", layer, x_start, y_start, width, height, source_id, atlas, alternative)
	ur.add_undo_method(self, "_restore_fill_cells", layer, old_cells)
	ur.commit_action(false)
	
	return {"result": "Filled %d cells in rect (%d,%d,%d,%d)" % [total_cells, x_start, y_start, width, height]}


## Helper: re-apply fill cells (redo path for fill_rect).
func _apply_fill_cells(layer: TileMapLayer, x_start: int, y_start: int, width: int, height: int, source_id: int, atlas: Vector2i, alternative: int) -> void:
	for x: int in range(x_start, x_start + width):
		for y: int in range(y_start, y_start + height):
			layer.set_cell(Vector2i(x, y), source_id, atlas, alternative)


## Helper: restore cells captured before fill_rect (undo path).
func _restore_fill_cells(layer: TileMapLayer, old_cells: Dictionary) -> void:
	for pos: Vector2i in old_cells:
		var state: Dictionary = old_cells[pos]
		layer.set_cell(pos, state["source"], state["atlas"], state["alt"])


## Get info about a single cell.
func tilemap_get_cell(params: Dictionary) -> Dictionary:
	var resolved: Dictionary = _get_tilemap_layer(params)
	if resolved.has("error"):
		return resolved
	var layer: TileMapLayer = resolved["layer"] as TileMapLayer

	var coords_raw: Variant = params.get("coords", {})
	var cell: Vector2i = Vector2i.ZERO
	if coords_raw is Array:
		var arr: Array = coords_raw as Array
		cell = Vector2i(arr[0] as int, arr[1] as int) if arr.size() >= 2 else Vector2i.ZERO
	elif coords_raw is Dictionary:
		var d: Dictionary = coords_raw as Dictionary
		cell = Vector2i(d.get("x", 0) as int, d.get("y", 0) as int)

	var source_id: int = layer.get_cell_source_id(cell)
	if source_id == -1:
		return {"result": {
			"coords": {"x": cell.x, "y": cell.y},
			"empty": true,
		}}
	var atlas: Vector2i = layer.get_cell_atlas_coords(cell)
	var alt: int = layer.get_cell_alternative_tile(cell)

	return {"result": {
		"coords": {"x": cell.x, "y": cell.y},
		"empty": false,
		"source_id": source_id,
		"atlas_coords": {"x": atlas.x, "y": atlas.y},
		"alternative": alt,
	}}


## Clear all cells in the tilemap layer.
## Uses batched undo to prevent main-thread blocking with large tilemaps.
## Instead of one add_undo_method per cell (which can create 10k+ entries
## and cause commit_action to block for seconds), all cell state is captured
## into a single Array and restored by one undo method.
func tilemap_clear(params: Dictionary) -> Dictionary:
	var resolved: Dictionary = _get_tilemap_layer(params)
	if resolved.has("error"):
		return resolved
	var layer: TileMapLayer = resolved["layer"] as TileMapLayer

	# Capture all cells for batched undo
	var used_cells: Array[Vector2i] = layer.get_used_cells()
	var cell_count: int = used_cells.size()
	var cell_states: Array = []
	for cell_pos: Vector2i in used_cells:
		cell_states.append({
			"pos": cell_pos,
			"source_id": layer.get_cell_source_id(cell_pos),
			"atlas": layer.get_cell_atlas_coords(cell_pos),
			"alt": layer.get_cell_alternative_tile(cell_pos),
		})
	
	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Clear tilemap layer (%d cells)" % cell_count)
	ur.add_do_method(layer, "clear")
	# Batched undo � single method call restores all cells, avoiding
	# O(n) add_undo_method calls that freeze commit_action on large maps.
	ur.add_undo_method(self, "_restore_cleared_cells", layer, cell_states)
	ur.commit_action()
	return {"result": "TileMap cleared: %s (%d cells)" % [layer.name, cell_count]}


## Helper: restore cells captured before clear (batched undo path).
func _restore_cleared_cells(layer: TileMapLayer, cell_states: Array) -> void:
	for state: Dictionary in cell_states:
		layer.set_cell(state["pos"], state["source_id"], state["atlas"], state["alt"])


## Get tilemap layer and tileset info.
func tilemap_get_info(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	# TileMapLayer
	if node is TileMapLayer:
		var layer: TileMapLayer = node as TileMapLayer
		var ts: TileSet = layer.tile_set
		var tileset_info: Dictionary = {}
		if ts:
			var sources: Array = []
			for i: int in range(ts.get_source_count()):
				var source_id: int = ts.get_source_id(i)
				var source: TileSetSource = ts.get_source(source_id)
				sources.append({
					"id": source_id,
					"type": source.get_class(),
				})
			tileset_info = {
				"tile_size": {"x": ts.tile_size.x, "y": ts.tile_size.y},
				"source_count": ts.get_source_count(),
				"sources": sources,
			}
		return {"result": {
			"path": path,
			"type": "TileMapLayer",
			"tileset": tileset_info,
		}}

	# Legacy TileMap
	if node is TileMap:
		var tilemap: TileMap = node as TileMap
		var ts2: TileSet = tilemap.tile_set
		
		# Fallback: in Godot 4.3+, TileSet may be assigned to child TileMapLayer
		# nodes rather than the parent TileMap. Check children if parent has none.
		if ts2 == null:
			for child: Node in tilemap.get_children():
				if child is TileMapLayer:
					var child_layer: TileMapLayer = child as TileMapLayer
					if child_layer.tile_set != null:
						ts2 = child_layer.tile_set
						break
		
		var tileset_info2: Dictionary = {}
		if ts2:
			var sources2: Array = []
			for i2: int in range(ts2.get_source_count()):
				var sid: int = ts2.get_source_id(i2)
				var src: TileSetSource = ts2.get_source(sid)
				sources2.append({"id": sid, "type": src.get_class()})
			tileset_info2 = {
				"tile_size": {"x": ts2.tile_size.x, "y": ts2.tile_size.y},
				"source_count": ts2.get_source_count(),
				"sources": sources2,
			}
		var child_layers: Array = []
		for child: Node in tilemap.get_children():
			if child is TileMapLayer:
				child_layers.append(str(child.get_path()))
		return {"result": {
			"path": path,
			"type": "TileMap",
			"layer_count": tilemap.get_layers_count(),
			"tileset": tileset_info2,
			"tilemap_layers": child_layers,
		}}

	return {"error": "Node is not a TileMapLayer or TileMap: %s" % path}


## Get all used cells in the tilemap layer.
## Uses compact [[x,y],...] format to reduce response size by ~60% vs {x,y} objects.
## Accepts optional 'limit' param (default 1000) to cap cell count.
## A limit of 0 or negative means "no limit" (use with caution on large maps).
func tilemap_get_used_cells(params: Dictionary) -> Dictionary:
	var resolved: Dictionary = _get_tilemap_layer(params)
	if resolved.has("error"):
		return resolved
	var layer: TileMapLayer = resolved["layer"] as TileMapLayer

	var cells: Array[Vector2i] = layer.get_used_cells()
	var total_count: int = cells.size()
	
	# Optional limit param � default 1000 cells to prevent WebSocket overload
	const TILEMAP_MAX_CELL_RETURN: int = 50000
	var limit: int = params.get("limit", 1000)
	if limit <= 0 or limit > TILEMAP_MAX_CELL_RETURN:
		limit = mini(total_count, TILEMAP_MAX_CELL_RETURN)
	var capped: int = mini(total_count, limit)
	var truncated: bool = total_count > capped
	
	# Compact [[x,y],...] format � ~60% smaller than {x,y} objects
	var result: Array = []
	for i: int in range(capped):
		var cell: Vector2i = cells[i]
		result.append([cell.x, cell.y])
	
	var response: Dictionary = {
		"cells": result,
		"count": result.size(),
		"total_count": total_count,
		"truncated": truncated,
	}
	if truncated:
		response["message"] = "Truncated: showing %d of %d cells. Use 'limit' param to increase (0 = no limit)." % [capped, total_count]
	return {"result": response}


## ------------------------------------------------------------
## GridMap commands
## ------------------------------------------------------------

## Resolve a GridMap node from a path.
func _get_gridmap(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "GridMap path is required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	if not (node is GridMap):
		return {"error": "Node is not a GridMap: %s" % path}
	return {"gridmap": node as GridMap}


## Set a mesh item in the GridMap at the given 3D cell coordinates.
func gridmap_set_cell(params: Dictionary) -> Dictionary:
	var resolved: Dictionary = _get_gridmap(params)
	if resolved.has("error"):
		return resolved
	var gridmap: GridMap = resolved["gridmap"] as GridMap

	var coords_raw: Variant = params.get("coords", [])
	if not params.has("item"):
		return {"error": "item parameter is required"}
	var item: int = params.get("item", 0)

	var cell: Vector3i = Vector3i.ZERO
	if coords_raw is Array:
		var arr: Array = coords_raw as Array
		cell = Vector3i(arr[0] as int, arr[1] as int, arr[2] as int) if arr.size() >= 3 else Vector3i.ZERO
	elif coords_raw is Dictionary:
		var d: Dictionary = coords_raw as Dictionary
		cell = Vector3i(d.get("x", 0) as int, d.get("y", 0) as int, d.get("z", 0) as int)

	# Capture old state for undo
	var old_item: int = gridmap.get_cell_item(cell)

	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Set gridmap cell (%d,%d,%d)" % [cell.x, cell.y, cell.z])
	ur.add_do_method(gridmap, "set_cell_item", cell, item, 0)
	ur.add_undo_method(gridmap, "set_cell_item", cell, old_item, 0)
	ur.commit_action()

	return {"result": "GridMap cell set at (%d, %d, %d) item=%d" % [cell.x, cell.y, cell.z, item]}


## Get the mesh item at a specific GridMap cell.
func gridmap_get_cell(params: Dictionary) -> Dictionary:
	var resolved: Dictionary = _get_gridmap(params)
	if resolved.has("error"):
		return resolved
	var gridmap: GridMap = resolved["gridmap"] as GridMap

	var coords_raw: Variant = params.get("coords", [])
	var cell: Vector3i = Vector3i.ZERO
	if coords_raw is Array:
		var arr: Array = coords_raw as Array
		cell = Vector3i(arr[0] as int, arr[1] as int, arr[2] as int) if arr.size() >= 3 else Vector3i.ZERO
	elif coords_raw is Dictionary:
		var d: Dictionary = coords_raw as Dictionary
		cell = Vector3i(d.get("x", 0) as int, d.get("y", 0) as int, d.get("z", 0) as int)

	var item: int = gridmap.get_cell_item(cell)
	return {"result": {
		"coords": {"x": cell.x, "y": cell.y, "z": cell.z},
		"empty": item == -1,
		"item": item,
	}}


## Clear all cells in the GridMap.
## Uses batched undo (same pattern as tilemap_clear) to prevent
## main-thread blocking with large gridmaps.
func gridmap_clear(params: Dictionary) -> Dictionary:
	var resolved: Dictionary = _get_gridmap(params)
	if resolved.has("error"):
		return resolved
	var gridmap: GridMap = resolved["gridmap"] as GridMap

	# Capture all cells for batched undo
	var used_cells: Array = gridmap.get_used_cells()
	var cell_count: int = used_cells.size()
	var cell_states: Array = []
	for cell_pos: Variant in used_cells:
		var pos: Vector3i = cell_pos as Vector3i
		cell_states.append({"pos": pos, "item": gridmap.get_cell_item(pos)})

	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Clear gridmap (%d cells)" % cell_count)
	ur.add_do_method(gridmap, "clear")
	# Batched undo � single method call restores all cells
	ur.add_undo_method(self, "_restore_gridmap_cells", gridmap, cell_states)
	ur.commit_action()
	return {"result": "GridMap cleared: %s (%d cells)" % [gridmap.name, cell_count]}


## Helper: restore cells captured before gridmap_clear (batched undo path).
func _restore_gridmap_cells(gridmap: GridMap, cell_states: Array) -> void:
	for state: Dictionary in cell_states:
		gridmap.set_cell_item(state["pos"], state["item"], 0)


## Get all used cells in the GridMap.
## Uses compact [[x,y,z],...] format to reduce response size by ~50% vs {x,y,z} objects.
## Accepts optional 'limit' param (default 1000) to cap cell count.
## A limit of 0 or negative means "no limit" (use with caution on large maps).
func gridmap_get_used_cells(params: Dictionary) -> Dictionary:
	var resolved: Dictionary = _get_gridmap(params)
	if resolved.has("error"):
		return resolved
	var gridmap: GridMap = resolved["gridmap"] as GridMap

	var cells: Array = gridmap.get_used_cells()
	var total_count: int = cells.size()
	
	# Optional limit param � default 1000 cells to prevent WebSocket overload
	const GRIDMAP_MAX_CELL_RETURN: int = 50000
	var limit: int = params.get("limit", 1000)
	if limit <= 0 or limit > GRIDMAP_MAX_CELL_RETURN:
		limit = mini(total_count, GRIDMAP_MAX_CELL_RETURN)
	var capped: int = mini(total_count, limit)
	var truncated: bool = total_count > capped
	
	# Compact [[x,y,z],...] format � ~50% smaller than {x,y,z} objects
	var result: Array = []
	for i: int in range(capped):
		var c: Vector3i = cells[i] as Vector3i
		result.append([c.x, c.y, c.z])
	
	var response: Dictionary = {
		"cells": result,
		"count": result.size(),
		"total_count": total_count,
		"truncated": truncated,
	}
	if truncated:
		response["message"] = "Truncated: showing %d of %d cells. Use 'limit' param to increase (0 = no limit)." % [capped, total_count]
	return {"result": response}


## Get GridMap configuration info.
func gridmap_get_info(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path is required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	if not (node is GridMap):
		return {"error": "Node is not a GridMap: %s" % path}

	var gridmap: GridMap = node as GridMap
	var ml: MeshLibrary = gridmap.mesh_library
	var mesh_lib_info: Dictionary = {}
	if ml:
		var items: Array = []
		for item_id: int in ml.get_item_list():
			items.append({"id": item_id, "name": ml.get_item_name(item_id)})
		mesh_lib_info = {
			"path": str(ml.resource_path),
			"item_count": ml.get_item_list().size(),
			"items": items,
		}

	return {"result": {
		"path": path,
		"type": "GridMap",
		"cell_size": {"x": gridmap.cell_size.x, "y": gridmap.cell_size.y, "z": gridmap.cell_size.z},
		"mesh_library": mesh_lib_info,
		"used_cells": gridmap.get_used_cells().size(),
	}}
