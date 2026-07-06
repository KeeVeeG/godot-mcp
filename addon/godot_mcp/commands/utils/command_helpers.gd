## Shared helper functions for command modules.
## Replaces duplicate implementations across 8+ modules.
class_name MCPCommandHelpers
extends RefCounted


## Check if an object has a property by name.
static func has_property(obj: Object, prop: String) -> bool:
	for p: Dictionary in obj.get_property_list():
		if p["name"] as String == prop:
			return true
	return false


## Get the Variant type of a property. Returns TYPE_NIL if not found.
static func get_property_type(obj: Object, prop: String) -> int:
	for p: Dictionary in obj.get_property_list():
		if p["name"] as String == prop:
			return p["type"] as int
	return TYPE_NIL


## Ensure a directory exists, creating it recursively if needed.
static func ensure_dir(path: String) -> void:
	if path.is_empty() or DirAccess.dir_exists_absolute(path):
		return
	DirAccess.make_dir_recursive_absolute(path)


## Get the edited scene root from the plugin's editor interface.
## Returns null if plugin is null or no scene is open.
static func get_edited_scene_root(plugin: EditorPlugin) -> Node:
	if plugin == null:
		return null
	return plugin.get_editor_interface().get_edited_scene_root()
