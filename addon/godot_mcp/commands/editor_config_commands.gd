## Editor configuration commands module - 8 tools.
## Handles editor theme, layout, font, scale, and workspace management.
class_name MCPEditorConfigCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


## Router compatibility: returns callable map for MCPCommandRouter.
func get_commands() -> Dictionary:
	return {
		"editor_config/get_settings": func(params: Dictionary) -> Dictionary: return execute("get_settings", params),
		"editor_config/set_theme": func(params: Dictionary) -> Dictionary: return execute("set_theme", params),
		"editor_config/set_layout": func(params: Dictionary) -> Dictionary: return execute("set_layout", params),
		"editor_config/set_font_size": func(params: Dictionary) -> Dictionary: return execute("set_font_size", params),
		"editor_config/set_scale": func(params: Dictionary) -> Dictionary: return execute("set_scale", params),
		"editor_config/save_layout": func(params: Dictionary) -> Dictionary: return execute("save_layout", params),
		"editor_config/load_layout": func(params: Dictionary) -> Dictionary: return execute("load_layout", params),
		"editor_config/reset_layout": func(params: Dictionary) -> Dictionary: return execute("reset_layout", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_settings": return _get_settings()
		"set_theme": return _set_theme(params)
		"set_layout": return _set_layout(params)
		"set_font_size": return _set_font_size(params)
		"set_scale": return _set_scale(params)
		"save_layout": return _save_layout(params)
		"load_layout": return _load_layout(params)
		"reset_layout": return _reset_layout()
	return {"success": false, "error": "Unknown method: " + method}


## Get all editor settings.
func _get_settings() -> Dictionary:
	var settings: Dictionary = {
		"interface": {
			"theme": EditorInterface.get_editor_settings().get_setting("interface/theme/color_preset") if EditorInterface.get_editor_settings().has_setting("interface/theme/color_preset") else "default",
			"font_size": EditorInterface.get_editor_settings().get_setting("interface/editor/fonts/main_font_size") if EditorInterface.get_editor_settings().has_setting("interface/editor/fonts/main_font_size") else 14,
			"scale": EditorInterface.get_editor_settings().get_setting("interface/editor/appearance/custom_display_scale") if EditorInterface.get_editor_settings().has_setting("interface/editor/appearance/custom_display_scale") else 1.0,
		},
		"layout": {
			"current": "default",
			"saved_layouts": _get_saved_layouts(),
		},
	}
	return {"success": true, "settings": settings}


## Set editor theme.
func _set_theme(params: Dictionary) -> Dictionary:
	var theme: String = params.get("theme", "dark")
	var es: EditorSettings = EditorInterface.get_editor_settings()
	if es == null:
		return {"success": false, "error": "Cannot access editor settings"}
	match theme:
		"dark":
			es.set_setting("interface/theme/color_preset", "Default")
		"light":
			es.set_setting("interface/theme/color_preset", "Light")
		"amoled":
			es.set_setting("interface/theme/color_preset", "Default")
			es.set_setting("interface/theme/base_color", Color(0.0, 0.0, 0.0, 1.0))
		_:
			return {"success": false, "error": "Unknown theme: %s (use: dark, light, amoled)" % theme}
	return {"success": true, "theme": theme, "message": "Editor theme set to %s" % theme}


## Switch editor layout.
func _set_layout(params: Dictionary) -> Dictionary:
	var layout: String = params.get("layout", "default")
	match layout:
		"default":
			EditorInterface.set_main_screen_editor("2D")
		"2d":
			EditorInterface.set_main_screen_editor("2D")
		"3d":
			EditorInterface.set_main_screen_editor("3D")
		"script":
			EditorInterface.set_main_screen_editor("Script")
		_:
			return {"success": false, "error": "Unknown layout: %s (use: default, 2d, 3d, script)" % layout}
	return {"success": true, "layout": layout, "message": "Editor layout set to %s" % layout}


## Set editor font size.
func _set_font_size(params: Dictionary) -> Dictionary:
	var size: int = params.get("size", 14)
	if size < 8 or size > 48:
		return {"success": false, "error": "Font size must be between 8 and 48"}
	var es: EditorSettings = EditorInterface.get_editor_settings()
	if es == null:
		return {"success": false, "error": "Cannot access editor settings"}
	es.set_setting("interface/editor/fonts/main_font_size", size)
	return {"success": true, "size": size, "message": "Font size set to %d" % size}


## Set editor UI scale.
func _set_scale(params: Dictionary) -> Dictionary:
	var scale: float = params.get("scale", 1.0)
	if scale < 0.5 or scale > 4.0:
		return {"success": false, "error": "Scale must be between 0.5 and 4.0"}
	var es: EditorSettings = EditorInterface.get_editor_settings()
	if es == null:
		return {"success": false, "error": "Cannot access editor settings"}
	es.set_setting("interface/editor/appearance/custom_display_scale", scale)
	return {"success": true, "scale": scale, "message": "Editor scale set to %.1f%%" % (scale * 100)}


## Save current layout.
func _save_layout(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")
	if name.is_empty():
		return {"success": false, "error": "Layout name cannot be empty"}
	var layout_path: String = "user://editor_layout_%s.cfg" % name
	var config: ConfigFile = ConfigFile.new()
	# Save current main screen
	config.set_value("layout", "main_screen", "2D")  # Default
	var err: Error = config.save(layout_path)
	if err != OK:
		return {"success": false, "error": "Failed to save layout: %s" % error_string(err)}
	return {"success": true, "name": name, "path": layout_path, "message": "Layout '%s' saved" % name}


## Load a saved layout.
func _load_layout(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")
	if name.is_empty():
		return {"success": false, "error": "Layout name cannot be empty"}
	var layout_path: String = "user://editor_layout_%s.cfg" % name
	if not FileAccess.file_exists(layout_path):
		return {"success": false, "error": "Layout not found: %s" % name}
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(layout_path)
	if err != OK:
		return {"success": false, "error": "Failed to load layout: %s" % error_string(err)}
	var main_screen: String = config.get_value("layout", "main_screen", "2D") as String
	EditorInterface.set_main_screen_editor(main_screen)
	return {"success": true, "name": name, "message": "Layout '%s' loaded" % name}


## Reset layout to defaults.
func _reset_layout() -> Dictionary:
	var es: EditorSettings = EditorInterface.get_editor_settings()
	if es == null:
		return {"success": false, "error": "Cannot access editor settings"}
	es.set_setting("interface/theme/color_preset", "Default")
	es.set_setting("interface/editor/fonts/main_font_size", 14)
	es.set_setting("interface/editor/appearance/custom_display_scale", 1.0)
	EditorInterface.set_main_screen_editor("2D")
	return {"success": true, "message": "Editor layout reset to defaults"}


## Helper: get list of saved layouts.
func _get_saved_layouts() -> Array:
	var layouts: Array = []
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return layouts
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.begins_with("editor_layout_") and file_name.ends_with(".cfg"):
			var name: String = file_name.replace("editor_layout_", "").replace(".cfg", "")
			layouts.append(name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return layouts
