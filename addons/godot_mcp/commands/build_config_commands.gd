## Build configuration commands module - 8 tools.
## Handles build settings, scripting backend, export filter, and debug options.
@tool
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
## Uses custom godot_mcp/build_config/* keys for reliable read-after-write round-trip,
## since Godot's build configuration state is scattered across UI toggles, export_presets.cfg,
## and engine metadata — not accessible as simple ProjectSettings reads.
func _get_settings() -> Dictionary:
	var settings: Dictionary = {
		"configuration": ProjectSettings.get_setting("godot_mcp/build_config/configuration", "debug"),
		"custom_features": ProjectSettings.get_setting("godot_mcp/build_config/custom_features", []),
		"godot_version": Engine.get_version_info(),
		"export_filter": ProjectSettings.get_setting("godot_mcp/build_config/export_filter", "all_resources"),
		"debug_options": {
			"debug_build": ProjectSettings.get_setting("godot_mcp/build_config/debug_build", true),
			"release_debug": ProjectSettings.get_setting("godot_mcp/build_config/release_debug", false),
			"optimize": ProjectSettings.get_setting("godot_mcp/build_config/optimize", false),
		},
	}
	# Determine scripting backend by checking for .NET/Mono build artifacts
	var has_csharp: bool = DirAccess.dir_exists_absolute("res://.godot/mono")
	settings["scripting_backend"] = "csharp" if has_csharp else "gdscript"
	return {"success": true, "settings": settings}


## Set build configuration.
## Each preset applies canonical debug_options defaults so that switching
## configs (e.g. release → debug) also resets debug flags to sane values.
func _set_configuration(params: Dictionary) -> Dictionary:
	var config: String = params.get("config", "debug")
	match config:
		"debug":
			ProjectSettings.set_setting("application/run/disable_stdout", false)
			ProjectSettings.set_setting("godot_mcp/build_config/debug_build", true)
			ProjectSettings.set_setting("godot_mcp/build_config/release_debug", false)
			ProjectSettings.set_setting("godot_mcp/build_config/optimize", false)
		"release":
			ProjectSettings.set_setting("application/run/disable_stdout", true)
			ProjectSettings.set_setting("godot_mcp/build_config/debug_build", false)
			ProjectSettings.set_setting("godot_mcp/build_config/release_debug", false)
			ProjectSettings.set_setting("godot_mcp/build_config/optimize", true)
		"development":
			ProjectSettings.set_setting("application/run/disable_stdout", false)
			ProjectSettings.set_setting("godot_mcp/build_config/debug_build", false)
			ProjectSettings.set_setting("godot_mcp/build_config/release_debug", true)
			ProjectSettings.set_setting("godot_mcp/build_config/optimize", true)
		_:
			return {"success": false, "error": "Invalid config: %s (use: debug, release, development)" % config}
	# Track configuration in custom key for reliable read-back
	ProjectSettings.set_setting("godot_mcp/build_config/configuration", config)
	return {"success": true, "configuration": config, "message": "Build config set to %s — debug options reset to %s defaults" % [config, config]}


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
	match filter:
		"all_resources", "selected_resources", "selected_classes":
			pass
		_:
			return {"success": false, "error": "Invalid filter: %s" % filter}
	# Track in custom key for reliable read-back
	ProjectSettings.set_setting("godot_mcp/build_config/export_filter", filter)
	return {"success": true, "filter": filter, "message": "Export filter set to %s" % filter}


## Set custom feature tags.
func _set_custom_features(params: Dictionary) -> Dictionary:
	var features: Array = params.get("features", [])
	var packed: PackedStringArray = PackedStringArray()
	for f: Variant in features:
		packed.append(f as String)
	ProjectSettings.set_setting("application/config/features", packed)
	# Track in custom key for reliable read-back (engine mixes version/renderer features into application/config/features)
	ProjectSettings.set_setting("godot_mcp/build_config/custom_features", features)
	return {"success": true, "features": features, "message": "Custom features set"}


## Configure debug options.
func _set_debug_options(params: Dictionary) -> Dictionary:
	var debug_options: Dictionary = {
		"debug_build": ProjectSettings.get_setting("godot_mcp/build_config/debug_build", true),
		"release_debug": ProjectSettings.get_setting("godot_mcp/build_config/release_debug", false),
		"optimize": ProjectSettings.get_setting("godot_mcp/build_config/optimize", false),
	}
	if params.has("debug_build") or params.has("release_debug") or params.has("optimize"):
		if params.has("debug_build"):
			debug_options["debug_build"] = params["debug_build"] as bool
			ProjectSettings.set_setting("godot_mcp/build_config/debug_build", debug_options["debug_build"])
		if params.has("release_debug"):
			debug_options["release_debug"] = params["release_debug"] as bool
			ProjectSettings.set_setting("godot_mcp/build_config/release_debug", debug_options["release_debug"])
		if params.has("optimize"):
			debug_options["optimize"] = params["optimize"] as bool
			ProjectSettings.set_setting("godot_mcp/build_config/optimize", debug_options["optimize"])
		var result: Dictionary = {"success": true, "debug_options": debug_options}
		if debug_options["debug_build"] and debug_options["release_debug"]:
			result["warnings"] = ["debug_build and release_debug are both enabled — these options are typically mutually exclusive"]
		return result
	return {"success": false, "error": "No debug options provided"}


## Validate current build settings.
## Only build-config-specific issues count as errors.
## Project-health checks (main scene, viewport, autoloads) are warnings,
## since they do not reflect build configuration correctness.
func _validate() -> Dictionary:
	var errors: Array = []
	var warnings: Array = []

	# ── Build-config-specific checks ──
	var config: String = ProjectSettings.get_setting("godot_mcp/build_config/configuration", "debug")
	var db: bool = ProjectSettings.get_setting("godot_mcp/build_config/debug_build", true)
	var rd: bool = ProjectSettings.get_setting("godot_mcp/build_config/release_debug", false)
	var opt: bool = ProjectSettings.get_setting("godot_mcp/build_config/optimize", false)

	if config == "release" and db:
		errors.append("debug_build=true conflicts with release configuration — set debug_build=false or switch to debug config")
	if config == "debug" and opt:
		warnings.append("optimize=true under debug config — consider switching to release or development for optimized builds")
	if db and rd:
		warnings.append("debug_build and release_debug are both enabled — these options are typically mutually exclusive")

	# ── Project-health checks (warnings, not build-config errors) ──
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "") as String
	if main_scene.is_empty():
		warnings.append("No main scene configured")
	elif not FileAccess.file_exists(main_scene):
		warnings.append("Main scene not found: %s" % main_scene)

	var vw: int = ProjectSettings.get_setting("display/window/size/viewport_width", 1152)
	var vh: int = ProjectSettings.get_setting("display/window/size/viewport_height", 648)
	if vw <= 0 or vh <= 0:
		warnings.append("Invalid viewport size: %dx%d" % [vw, vh])

	var prop_list: Array = ProjectSettings.get_property_list()
	for prop: Dictionary in prop_list:
		var prop_name: String = prop.get("name", "")
		if prop_name.begins_with("autoload/"):
			var val: String = ProjectSettings.get_setting(prop_name, "") as String
			var path: String = val.substr(1) if val.begins_with("*") else val
			if not FileAccess.file_exists(path) and not ResourceLoader.exists(path):
				warnings.append("Autoload resource not found: %s" % path)

	return {"success": true, "valid": errors.is_empty(), "errors": errors, "warnings": warnings, "error_count": errors.size(), "warning_count": warnings.size()}


## Get CLI build command for a platform.
## Maps shorthand platform IDs to Godot export preset names, reads stored
## configuration for --export-debug vs --export-release, and validates that
## the target preset exists in export_presets.cfg.
func _get_build_command(params: Dictionary) -> Dictionary:
	var platform: String = params.get("platform", "windows")
	var export_name: String = ProjectSettings.get_setting("application/config/name", "Game")
	
	# Map shorthand platform IDs to Godot export preset names
	const PLATFORM_MAP: Dictionary = {
		"windows": "Windows Desktop",
		"linux": "Linux",
		"web": "Web",
		"android": "Android",
		"macos": "macOS",
		"ios": "iOS",
	}
	
	var preset_name: String = PLATFORM_MAP.get(platform, "")
	if preset_name.is_empty():
		return {"success": false, "error": "Unknown platform: %s (available: windows, linux, web, android, macos, ios)" % platform}
	
	# Validate that the preset exists in export_presets.cfg
	var cfg: ConfigFile = ConfigFile.new()
	var has_preset: bool = false
	if cfg.load("res://export_presets.cfg") == OK:
		for section: String in cfg.get_sections():
			if section.begins_with("preset."):
				var name: String = cfg.get_value(section, "name", "")
				if name == preset_name:
					has_preset = true
					break
		if not has_preset:
			var available: Array = []
			for section: String in cfg.get_sections():
				if section.begins_with("preset."):
					available.append(cfg.get_value(section, "name", ""))
			return {"success": false, "error": "No export preset found for platform '%s' (preset name: '%s'). Available presets: %s" % [platform, preset_name, str(available)]}
	
	# Determine debug/release flag from stored configuration
	var config: String = ProjectSettings.get_setting("godot_mcp/build_config/configuration", "debug")
	var export_flag: String = "--export-debug" if config == "debug" else "--export-release"
	
	var ext: String = ".exe" if platform == "windows" else (".html" if platform == "web" else ".apk" if platform == "android" else "")
	var cmd: String = "godot --headless %s \"%s\" builds/%s%s" % [export_flag, preset_name, export_name, ext]
	
	return {"success": true, "platform": platform, "preset_name": preset_name, "command": cmd, "export_flag": export_flag, "export_name": export_name}
