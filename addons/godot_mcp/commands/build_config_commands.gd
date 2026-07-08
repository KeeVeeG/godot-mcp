## Build configuration commands module - 8 tools.
## Handles build settings, scripting backend, export filter, and debug options.
class_name MCPBuildConfigCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


## Router compatibility: returns callable map for MCPCommandRouter.
func get_commands() -> Dictionary:
	return {
		"build_config/get_settings": func(params: Dictionary) -> Dictionary: return execute("get_settings", params),
		"build_config/set_configuration": func(params: Dictionary) -> Dictionary: return execute("set_configuration", params),
		"build_config/set_scripting_backend": func(params: Dictionary) -> Dictionary: return execute("set_scripting_backend", params),
		"build_config/set_export_filter": func(params: Dictionary) -> Dictionary: return execute("set_export_filter", params),
		"build_config/set_custom_features": func(params: Dictionary) -> Dictionary: return execute("set_custom_features", params),
		"build_config/set_debug_options": func(params: Dictionary) -> Dictionary: return execute("set_debug_options", params),
		"build_config/validate": func(params: Dictionary) -> Dictionary: return execute("validate", params),
		"build_config/get_build_command": func(params: Dictionary) -> Dictionary: return execute("get_build_command", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_settings": return _get_settings()
		"set_configuration": return _set_configuration(params)
		"set_scripting_backend": return _set_scripting_backend(params)
		"set_export_filter": return _set_export_filter(params)
		"set_custom_features": return _set_custom_features(params)
		"set_debug_options": return _set_debug_options(params)
		"validate": return _validate()
		"get_build_command": return _get_build_command(params)
	return {"success": false, "error": "Unknown method: " + method}


## Get all build configuration settings.
func _get_settings() -> Dictionary:
	var is_debug: bool = OS.is_debug_build()
	var config_name: String = "release"
	if is_debug:
		config_name = "debug"
	var settings: Dictionary = {
		"configuration": config_name,
		"custom_features": ProjectSettings.get_setting("application/config/features", PackedStringArray()),
		"godot_version": Engine.get_version_info(),
		"export_filter": ProjectSettings.get_setting("export/file_export_filter", 0),
		"debug_build": is_debug,
	}
	# Determine scripting backend by checking for .NET/Mono build artifacts
	var has_csharp: bool = DirAccess.dir_exists_absolute("res://.godot/mono")
	settings["scripting_backend"] = "csharp" if has_csharp else "gdscript"
	return {"success": true, "settings": settings}


## Set build configuration.
func _set_configuration(params: Dictionary) -> Dictionary:
	var config: String = params.get("config", "debug")
	match config:
		"debug":
			ProjectSettings.set_setting("application/run/disable_stdout", false)
			ProjectSettings.set_setting("debug/settings/profiling/profiling_enabled", true)
		"release":
			ProjectSettings.set_setting("application/run/disable_stdout", true)
			ProjectSettings.set_setting("debug/settings/profiling/profiling_enabled", false)
		"development":
			ProjectSettings.set_setting("application/run/disable_stdout", false)
			ProjectSettings.set_setting("debug/settings/profiling/profiling_enabled", true)
		_:
			return {"success": false, "error": "Invalid config: %s (use: debug, release, development)" % config}
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "configuration": config, "message": "Build config set to %s" % config}


## Set scripting backend.
## Note: The scripting backend is determined at project creation and cannot be
## changed at runtime. This function validates the backend and reports availability.
func _set_scripting_backend(params: Dictionary) -> Dictionary:
	var backend: String = params.get("backend", "gdscript")
	match backend:
		"gdscript":
			return {"success": true, "backend": "gdscript", "available": true, "message": "GDScript is the default backend"}
		"csharp":
			var has_csharp: bool = DirAccess.dir_exists_absolute("res://.godot/mono")
			if has_csharp:
				return {"success": true, "backend": "csharp", "available": true, "message": "C# backend is available"}
			return {"success": false, "backend": "csharp", "available": false, "error": "C# backend not available — requires .NET build support. Create a new project with C# enabled."}
		"visual_script":
			return {"success": false, "backend": "visual_script", "available": false, "error": "VisualScript was removed in Godot 4.0"}
		_:
			return {"success": false, "error": "Unknown backend: %s (available: gdscript, csharp)" % backend}


## Set export resource filter.
func _set_export_filter(params: Dictionary) -> Dictionary:
	var filter: String = params.get("filter", "all_resources")
	var filter_val: int = 0
	match filter:
		"all_resources": filter_val = 0
		"selected_resources": filter_val = 1
		"selected_classes": filter_val = 2
		_:
			return {"success": false, "error": "Invalid filter: %s" % filter}
	ProjectSettings.set_setting("export/file_export_filter", filter_val)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "filter": filter, "message": "Export filter set to %s" % filter}


## Set custom feature tags.
func _set_custom_features(params: Dictionary) -> Dictionary:
	var features: Array = params.get("features", [])
	var packed: PackedStringArray = PackedStringArray()
	for f: Variant in features:
		packed.append(f as String)
	ProjectSettings.set_setting("application/config/features", packed)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "features": features, "message": "Custom features set"}


## Configure debug options.
func _set_debug_options(params: Dictionary) -> Dictionary:
	var changed: Dictionary = {}
	if params.has("debug_build"):
		var debug: bool = params["debug_build"] as bool
		ProjectSettings.set_setting("debug/settings/profiling/profiling_enabled", debug)
		changed["debug_build"] = debug
	if params.has("release_debug"):
		var rd: bool = params["release_debug"] as bool
		ProjectSettings.set_setting("debug/settings/profiling/profiling_enabled", rd)
		changed["release_debug"] = rd
	if params.has("optimize"):
		var opt: bool = params["optimize"] as bool
		# Optimization is typically set at export time
		changed["optimize"] = opt
		changed["note"] = "Optimization is applied at export time"
	if changed.is_empty():
		return {"success": false, "error": "No debug options provided"}
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "changed": changed}


## Validate current build settings.
func _validate() -> Dictionary:
	var errors: Array = []
	var warnings: Array = []
	# Check main scene
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "") as String
	if main_scene.is_empty():
		errors.append("No main scene configured")
	elif not FileAccess.file_exists(main_scene):
		errors.append("Main scene not found: %s" % main_scene)
	# Check viewport size
	var vw: int = ProjectSettings.get_setting("display/window/size/viewport_width", 1152)
	var vh: int = ProjectSettings.get_setting("display/window/size/viewport_height", 648)
	if vw <= 0 or vh <= 0:
		errors.append("Invalid viewport size: %dx%d" % [vw, vh])
	# Check autoloads — iterate all autoload/ entries via property list
	var props: Array = ProjectSettings.get_property_list()
	for prop: Dictionary in props:
		var prop_name: String = prop.get("name", "")
		if prop_name.begins_with("autoload/"):
			var val: String = ProjectSettings.get_setting(prop_name, "") as String
			var path: String = val.substr(1) if val.begins_with("*") else val
			if not FileAccess.file_exists(path) and not ResourceLoader.exists(path):
				warnings.append("Autoload resource not found: %s" % path)
	return {"success": true, "errors": errors, "warnings": warnings, "error_count": errors.size(), "warning_count": warnings.size()}


## Get CLI build command for a platform.
func _get_build_command(params: Dictionary) -> Dictionary:
	var platform: String = params.get("platform", "windows")
	var export_name: String = ProjectSettings.get_setting("application/config/name", "Game")
	var cmd: String = ""
	match platform:
		"windows":
			cmd = "godot --headless --export-release \"Windows Desktop\" builds/%s.exe" % export_name
		"linux":
			cmd = "godot --headless --export-release \"Linux/X11\" builds/%s.x86_64" % export_name
		"web":
			cmd = "godot --headless --export-release \"Web\" builds/%s.html" % export_name
		"android":
			cmd = "godot --headless --export-release \"Android\" builds/%s.apk" % export_name
		"macos":
			cmd = "godot --headless --export-release \"macOS\" builds/%s.zip" % export_name
		_:
			cmd = "godot --headless --export-release \"%s\" builds/%s" % [platform, export_name]
	return {"success": true, "platform": platform, "command": cmd, "export_name": export_name}
