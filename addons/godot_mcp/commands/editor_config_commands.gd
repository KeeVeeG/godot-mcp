## Editor configuration commands module - 9 tools.
## Handles editor theme, layout, font, scale, and workspace management.
class_name MCPEditorConfigCommands
extends RefCounted

var _plugin: EditorPlugin
var _current_tab: String = "2D"


## EditorSettings key for tracking saved layout names.
## Uses EditorSettings (not DirAccess scanning) to avoid race conditions
## when theme changes trigger cascading NOTIFICATION_EDITOR_SETTINGS_CHANGED updates.
const SAVED_LAYOUTS_KEY: String = "mcp/editor/saved_layouts"


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin
	# Migrate: if EditorSettings key is empty but files exist, populate from disk.
	var es: EditorSettings = EditorInterface.get_editor_settings()
	if es != null:
		var existing: PackedStringArray = _get_layout_names_from_settings(es)
		if existing.is_empty():
			# First load: scan disk for legacy layout files and register them.
			var from_disk: Array = _scan_layout_files()
			var names: PackedStringArray
			for name in from_disk:
				names.append(name)
			if not names.is_empty():
				es.set_setting(SAVED_LAYOUTS_KEY, names)


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
		"editor_config/delete_layout": func(params: Dictionary) -> Dictionary: return execute("delete_layout", params),
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
		"delete_layout": return _delete_layout(params)
	return {"success": false, "error": "Unknown method: " + method}


## Get all editor settings.
func _get_settings() -> Dictionary:
	var es: EditorSettings = EditorInterface.get_editor_settings()
	var color_preset: String = es.get_setting("interface/theme/color_preset") if es.has_setting("interface/theme/color_preset") else "Default"
	# Reverse mapping: Godot preset name → user-friendly name
	var theme_name: String
	match color_preset:
		"Default": theme_name = "dark"
		"Light": theme_name = "light"
		"Black (OLED)": theme_name = "amoled"
		_: theme_name = "custom"
	var settings: Dictionary = {
		"interface": {
			"theme": theme_name,
			"font_size": es.get_setting("interface/editor/fonts/main_font_size") if es.has_setting("interface/editor/fonts/main_font_size") else 14,
			"scale": es.get_setting("interface/editor/appearance/custom_display_scale") if es.has_setting("interface/editor/appearance/custom_display_scale") else 1.0,
		},
		"layout": {
			"current": _current_tab,
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
			es.set_setting("interface/theme/color_preset", "Black (OLED)")
		_:
			return {"success": false, "error": "Unknown theme: %s (use: dark, light, amoled)" % theme}
	return {"success": true, "theme": theme, "message": "Editor theme set to %s" % theme}


## Switch the active main screen tab (2D/3D/Script).
## NOTE: This switches which editor tab is visible, not a full window layout.
func _set_layout(params: Dictionary) -> Dictionary:
	var layout: String = params.get("layout", "default")
	match layout:
		"default":
			EditorInterface.set_main_screen_editor("2D")
			_current_tab = "default"
		"2d":
			EditorInterface.set_main_screen_editor("2D")
			_current_tab = "2d"
		"3d":
			EditorInterface.set_main_screen_editor("3D")
			_current_tab = "3d"
		"script":
			EditorInterface.set_main_screen_editor("Script")
			_current_tab = "script"
		_:
			return {"success": false, "error": "Unknown layout: %s (use: default, 2d, 3d, script)" % layout}
	return {"success": true, "layout": layout, "message": "Main screen tab switched to %s. NOTE: This only switches the active editor tab (2D/3D/Script), not a full window layout." % layout}


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
	if scale < 0.5 or scale > 3.0:
		return {"success": false, "error": "Scale must be between 0.5 and 3.0"}
	var es: EditorSettings = EditorInterface.get_editor_settings()
	if es == null:
		return {"success": false, "error": "Cannot access editor settings"}
	es.set_setting("interface/editor/appearance/custom_display_scale", scale)
	return {"success": true, "scale": scale, "message": "Editor scale set to %.1f%%" % (scale * 100)}


## Save the current editor configuration (theme, font, scale, tab) to a named config file.
func _save_layout(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")
	if name.is_empty():
		return {"success": false, "error": "Layout name cannot be empty"}
	var es: EditorSettings = EditorInterface.get_editor_settings()
	if es == null:
		return {"success": false, "error": "Cannot access editor settings"}
	var layout_path: String = "user://editor_layout_%s.cfg" % name
	var config: ConfigFile = ConfigFile.new()
	# Theme
	config.set_value("theme", "color_preset", es.get_setting("interface/theme/color_preset"))
	config.set_value("theme", "base_color", es.get_setting("interface/theme/base_color"))
	# Font
	config.set_value("font", "main_font_size", es.get_setting("interface/editor/fonts/main_font_size"))
	# Scale
	config.set_value("scale", "custom_display_scale", es.get_setting("interface/editor/appearance/custom_display_scale"))
	# Active tab
	config.set_value("layout", "main_screen", _current_tab)
	var err: Error = config.save(layout_path)
	if err != OK:
		return {"success": false, "error": "Failed to save layout: %s" % error_string(err)}
	# Register layout in EditorSettings (avoids DirAccess race conditions)
	_register_layout_name(es, name)
	return {"success": true, "name": name, "path": layout_path, "message": "Editor config '%s' saved (theme, font, scale, tab)" % name}


## Load a saved editor configuration.
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
	var es: EditorSettings = EditorInterface.get_editor_settings()
	if es == null:
		return {"success": false, "error": "Cannot access editor settings"}
	# Theme: set preset first; only restore base_color for custom presets
	var color_preset: String = config.get_value("theme", "color_preset", "Default") as String
	es.set_setting("interface/theme/color_preset", color_preset)
	if color_preset == "Custom":
		es.set_setting("interface/theme/base_color", config.get_value("theme", "base_color", Color(0.14, 0.14, 0.14)))
	# Font
	es.set_setting("interface/editor/fonts/main_font_size", config.get_value("font", "main_font_size", 14))
	# Scale
	es.set_setting("interface/editor/appearance/custom_display_scale", config.get_value("scale", "custom_display_scale", 1.0))
	# Active tab
	var main_screen: String = config.get_value("layout", "main_screen", "2D") as String
	EditorInterface.set_main_screen_editor(main_screen)
	_current_tab = main_screen
	return {"success": true, "name": name, "message": "Editor config '%s' loaded (theme, font, scale, tab). Scale changes require editor restart." % name}


## Reset layout to defaults.
func _reset_layout() -> Dictionary:
	var es: EditorSettings = EditorInterface.get_editor_settings()
	if es == null:
		return {"success": false, "error": "Cannot access editor settings"}
	es.set_setting("interface/theme/color_preset", "Default")
	es.set_setting("interface/editor/fonts/main_font_size", 14)
	es.set_setting("interface/editor/appearance/custom_display_scale", 1.0)
	EditorInterface.set_main_screen_editor("2D")
	_current_tab = "default"
	return {"success": true, "message": "Editor layout reset to defaults"}


## Delete a saved editor layout from user://.
func _delete_layout(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")
	if name.is_empty():
		return {"success": false, "error": "Layout name cannot be empty"}
	var layout_path: String = "user://editor_layout_%s.cfg" % name
	if not FileAccess.file_exists(layout_path):
		return {"success": false, "error": "Layout not found: %s" % name}
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return {"success": false, "error": "Cannot access user directory"}
	var err: Error = dir.remove("editor_layout_%s.cfg" % name)
	if err != OK:
		return {"success": false, "error": "Failed to delete layout: %s" % error_string(err)}
	# Unregister layout from EditorSettings
	_unregister_layout_name(EditorInterface.get_editor_settings(), name)
	return {"success": true, "name": name, "message": "Layout '%s' deleted" % name}


## Helper: get list of saved layouts from EditorSettings (avoid DirAccess race conditions).
func _get_saved_layouts() -> Array:
	var es: EditorSettings = EditorInterface.get_editor_settings()
	if es == null:
		return []
	var names: PackedStringArray = _get_layout_names_from_settings(es)
	# Validate: only return names whose config files actually exist
	var layouts: Array = []
	for name in names:
		if FileAccess.file_exists("user://editor_layout_%s.cfg" % name):
			layouts.append(name)
	return layouts


## Read layout names from EditorSettings.
func _get_layout_names_from_settings(es: EditorSettings) -> PackedStringArray:
	if es.has_setting(SAVED_LAYOUTS_KEY):
		return es.get_setting(SAVED_LAYOUTS_KEY)
	return PackedStringArray()


## Add a layout name to EditorSettings.
func _register_layout_name(es: EditorSettings, name: String) -> void:
	var names: PackedStringArray = _get_layout_names_from_settings(es)
	if not names.has(name):
		names.append(name)
		es.set_setting(SAVED_LAYOUTS_KEY, names)


## Remove a layout name from EditorSettings.
func _unregister_layout_name(es: EditorSettings, name: String) -> void:
	var names: PackedStringArray = _get_layout_names_from_settings(es)
	var idx: int = names.find(name)
	if idx >= 0:
		names.remove_at(idx)
		es.set_setting(SAVED_LAYOUTS_KEY, names)


## One-time migration: scan user:// for legacy layout files (used when EditorSettings key is empty).
func _scan_layout_files() -> Array:
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
