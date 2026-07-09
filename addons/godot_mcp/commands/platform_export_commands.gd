## Platform export commands module - 5 tools.
## Provides platform-specific export, validation, template management,
## preset creation, and exported build execution.
class_name MCPPlatformExportCommands
extends RefCounted

var _plugin: EditorPlugin

## Platform name to preset platform string mapping
const PLATFORM_MAP: Dictionary = {
	"windows": "Windows Desktop",
	"linux": "Linux",
	"macos": "macOS",
	"android": "Android",
	"ios": "iOS",
	"web": "Web",
}

## Platform-specific export extensions
const PLATFORM_EXTENSIONS: Dictionary = {
	"windows": ".exe",
	"linux": ".x86_64",
	"macos": ".zip",
	"android": ".apk",
	"ios": ".ipa",
	"web": ".html",
}


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func get_commands() -> Dictionary:
	return {
		"export_for_platform": export_for_platform,
		"validate_platform_export": validate_export_for_platform,
		"get_platform_export_templates": get_export_templates,
		"create_platform_export_preset": create_export_preset,
		"run_exported_build": run_exported_build,
		"export/validate_platform": validate_export_for_platform,
	}


## Export the project for a specific platform.
func export_for_platform(params: Dictionary) -> Dictionary:
	var platform: String = params.get("platform", "")
	var debug: bool = params.get("debug", false)

	if platform.is_empty():
		return {"error": "platform is required"}

	var platform_name: String = PLATFORM_MAP.get(platform, "")
	if platform_name.is_empty():
		return {"error": "Unknown platform: %s. Supported: %s" % [platform, ", ".join(PLATFORM_MAP.keys())]}

	# Check if preset exists, create if not
	var preset_name: String = "%s Preset" % platform_name
	var config: ConfigFile = ConfigFile.new()
	var config_path: String = "res://export_presets.cfg"
	var has_preset: bool = false

	if FileAccess.file_exists(config_path):
		config.load(config_path)
		var idx: int = 0
		while true:
			var section: String = "preset.%d" % idx
			if not config.has_section(section):
				break
			if config.get_value(section, "name", "") == preset_name:
				has_preset = true
				break
			idx += 1

	if not has_preset:
		# Auto-create the preset so export_for_platform works out of the box
		var auto_result: Dictionary = create_export_preset({"platform": platform, "name": preset_name})
		if auto_result.has("error"):
			return {"error": "Failed to auto-create export preset for %s: %s" % [platform_name, auto_result["error"]]}
		# Reload config so the rest of this function sees the new preset
		config = ConfigFile.new()
		config.load(config_path)

	# Build the export command
	var exec_path: String = OS.get_executable_path()
	var project_path: String = ProjectSettings.globalize_path("res://")
	var ext: String = PLATFORM_EXTENSIONS.get(platform, "")
	var output_name: String = ProjectSettings.get_setting("application/config/name", "game")
	var export_dir: String = project_path.path_join("exports/%s/" % platform)
	DirAccess.make_dir_recursive_absolute(export_dir)
	var output_path: String = export_dir.path_join(output_name + ext)

	var args: PackedStringArray = PackedStringArray([
		"--headless",
		"--path", project_path,
	])

	if debug:
		args.append("--export-debug")
	else:
		args.append("--export-release")

	args.append(preset_name)
	args.append(output_path)

	var output: Array = []
	var start_time: float = Time.get_ticks_msec()
	var err: Error = OS.execute(exec_path, args, output, true, false)
	var duration_ms: float = Time.get_ticks_msec() - start_time

	var success: bool = err == OK and FileAccess.file_exists(output_path)

	return {"result": {
		"success": success,
		"platform": platform,
		"platform_name": platform_name,
		"debug": debug,
		"output_path": output_path,
		"duration_ms": duration_ms,
		"exit_code": err,
		"build_output": "".join(output),
		"file_exists": FileAccess.file_exists(output_path),
		"message": "Exported for %s (%s) to %s" % [platform_name, "debug" if debug else "release", output_path] if success else "Export failed for %s" % platform_name,
	}}


## Validate the project for export on a specific platform.
func validate_export_for_platform(params: Dictionary) -> Dictionary:
	var platform: String = params.get("platform", "")

	if platform.is_empty():
		return {"error": "platform is required"}

	var issues: Array = []
	var platform_name: String = PLATFORM_MAP.get(platform, platform)

	# Check for export templates
	var templates_dir: String = OS.get_user_data_dir().path_join("export_templates")
	var version_str: String = Engine.get_version_info()["string"]
	var template_dir: String = templates_dir.path_join(version_str)

	# Check for platform-specific requirements
	match platform:
		"android":
			# Check for Android SDK
			var es: EditorSettings = EditorInterface.get_editor_settings()
			var android_sdk: String = es.get_setting("export/android/android_sdk_path") if es.has_setting("export/android/android_sdk_path") else ""
			if android_sdk.is_empty():
				issues.append({"severity": "error", "type": "missing_sdk", "message": "Android SDK path not configured"})
			# Check for keystore
			var keystore: String = ProjectSettings.get_setting("keystore/debug", "")
			if keystore.is_empty():
				issues.append({"severity": "warning", "type": "missing_keystore", "message": "No debug keystore configured"})

		"ios":
			# Check for Xcode (macOS only)
			if OS.get_name() != "macOS":
				issues.append({"severity": "error", "type": "wrong_platform", "message": "iOS export requires macOS"})

		"web":
			# Check for correct renderer
			var renderer: String = ProjectSettings.get_setting("rendering/renderer/rendering_method", "")
			if renderer != "gl_compatibility":
				issues.append({"severity": "warning", "type": "renderer", "message": "Web export works best with gl_compatibility renderer (current: %s)" % renderer})

	# Check for missing resources in all scenes
	var scene_files: Array = []
	MCPCommandHelpers.walk_directory("res://", PackedStringArray(["tscn"]), func(path, _name): scene_files.append(path))
	var missing_count: int = 0
	for scene_path: String in scene_files:
		var deps: PackedStringArray = ResourceLoader.get_dependencies(scene_path)
		for dep: String in deps:
			var dep_path: String = dep.get_slice("::", 2) if dep.find("::") != -1 else dep
			if not dep_path.is_empty() and not FileAccess.file_exists(dep_path):
				missing_count += 1
				issues.append({
					"severity": "error",
					"type": "missing_resource",
					"scene": scene_path,
					"resource": dep_path,
					"message": "Missing resource: %s (referenced by %s)" % [dep_path, scene_path],
				})

	# Check script errors — use load() which returns null on compile errors
	# and returns cached valid GDScript for already-compiled scripts.
	# Skip addons/ (third-party code) and empty files.
	var script_files: Array = []
	MCPCommandHelpers.walk_directory("res://", PackedStringArray(["gd"]), func(path, _name): script_files.append(path))
	var script_errors: int = 0
	for script_path: String in script_files:
		if script_path.begins_with("res://addons/"):
			continue
		if ResourceLoader.exists(script_path):
			var script := load(script_path)
			if script == null:
				script_errors += 1
				issues.append({
					"severity": "error",
					"type": "script_error",
					"path": script_path,
					"message": "Script has compilation errors",
				})

	var error_count: int = issues.filter(func(i: Dictionary) -> bool: return i["severity"] == "error").size()
	var warning_count: int = issues.filter(func(i: Dictionary) -> bool: return i["severity"] == "warning").size()

	return {"result": {
		"platform": platform,
		"platform_name": platform_name,
		"valid": error_count == 0,
		"errors": error_count,
		"warnings": warning_count,
		"issues": issues,
		"scenes_scanned": scene_files.size(),
		"scripts_scanned": script_files.size(),
		"message": "Validation for %s: %d errors, %d warnings" % [platform_name, error_count, warning_count] if issues.size() > 0 else "Validation passed for %s" % platform_name,
	}}


## Get available export templates.
func get_export_templates(_params: Dictionary) -> Dictionary:
	var version_info: Dictionary = Engine.get_version_info()
	var version_str: String = version_info.get("string", "unknown")
	var templates_dir: String = OS.get_user_data_dir().path_join("export_templates")

	var installed: bool = DirAccess.dir_exists_absolute(templates_dir)
	var available_templates: Array = []

	if installed:
		var version_dir: String = templates_dir.path_join(version_str)
		if DirAccess.dir_exists_absolute(version_dir):
			var dir: DirAccess = DirAccess.open(version_dir)
			if dir != null:
				dir.list_dir_begin()
				var file_name: String = dir.get_next()
				while file_name != "":
					if not file_name.begins_with("."):
						available_templates.append(file_name)
					file_name = dir.get_next()
				dir.list_dir_end()

	return {"result": {
		"godot_version": version_str,
		"templates_installed": installed,
		"templates_dir": templates_dir,
		"available_templates": available_templates,
		"template_count": available_templates.size(),
		"platforms": PLATFORM_MAP.keys(),
		"message": "Found %d export templates for Godot %s" % [available_templates.size(), version_str] if installed else "No export templates installed. Download from Godot editor: Editor > Manage Export Templates.",
	}}


## Create a new export preset.
func create_export_preset(params: Dictionary) -> Dictionary:
	var platform: String = params.get("platform", "")
	var name: String = params.get("name", "")
	var settings: Dictionary = params.get("settings", {})

	if platform.is_empty() or name.is_empty():
		return {"error": "platform and name are required"}

	# Map friendly name to Godot platform string
	var platform_str: String = PLATFORM_MAP.get(platform, platform)

	var config_path: String = "res://export_presets.cfg"
	var config: ConfigFile = ConfigFile.new()

	if FileAccess.file_exists(config_path):
		config.load(config_path)

	# Find next available preset index
	var next_idx: int = 0
	while config.has_section("preset.%d" % next_idx):
		next_idx += 1

	var section: String = "preset.%d" % next_idx
	config.set_value(section, "name", name)
	config.set_value(section, "platform", platform_str)
	config.set_value(section, "runnable", true)
	config.set_value(section, "export_path", "exports/%s/" % platform)

	# Apply custom settings
	if not settings.is_empty():
		var options_section: String = "preset.%d.options" % next_idx
		for key: String in settings:
			config.set_value(options_section, key, settings[key])

	var err: Error = config.save(config_path)
	if err != OK:
		return {"error": "Failed to save export preset: %s" % error_string(err)}

	return {"result": {
		"success": true,
		"name": name,
		"platform": platform_str,
		"preset_index": next_idx,
		"config_path": config_path,
		"message": "Created export preset '%s' for %s" % [name, platform_str],
	}}


## Run an exported build and capture output.
func run_exported_build(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var run_args: Array = params.get("args", [])

	if path.is_empty():
		return {"error": "path is required"}

	var global_path: String = path
	if path.begins_with("res://"):
		global_path = ProjectSettings.globalize_path(path)

	if not FileAccess.file_exists(global_path):
		return {"error": "Build not found: %s" % path}

	# Build command arguments
	var cmd_args: PackedStringArray = PackedStringArray()
	for arg: String in run_args:
		cmd_args.append(arg)

	var output: Array = []
	var start_time: float = Time.get_ticks_msec()
	var err: Error = OS.execute(global_path, cmd_args, output, true, false)
	var duration_ms: float = Time.get_ticks_msec() - start_time

	return {"result": {
		"exit_code": err,
		"duration_ms": duration_ms,
		"output": "".join(output),
		"path": path,
		"args": run_args,
		"success": err == OK,
		"message": "Build executed with exit code %d in %.1fms" % [err, duration_ms],
	}}


## Delete an export preset from export_presets.cfg.
func delete_export_preset(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")

	if name.is_empty():
		return {"error": "name is required"}

	var config_path: String = "res://export_presets.cfg"
	var config: ConfigFile = ConfigFile.new()

	if not FileAccess.file_exists(config_path):
		return {"error": "No export presets file found at %s" % config_path}

	var load_err: Error = config.load(config_path)
	if load_err != OK:
		return {"error": "Failed to load export presets: %s" % error_string(load_err)}

	# Find the preset with matching name
	var target_idx: int = -1
	var total_presets: int = 0
	while config.has_section("preset.%d" % total_presets):
		if config.get_value("preset.%d" % total_presets, "name", "") == name:
			target_idx = total_presets
		total_presets += 1

	if target_idx == -1:
		return {"error": "Export preset not found: %s" % name}

	# Collect the target preset info before deletion
	var target_section: String = "preset.%d" % target_idx
	var deleted_platform: String = config.get_value(target_section, "platform", "unknown")

	# Read all presets into memory
	var presets: Array = []
	for idx in range(total_presets):
		var section: String = "preset.%d" % idx
		var preset_data: Dictionary = {}
		for key in config.get_section_keys(section):
			preset_data[key] = config.get_value(section, key)
		var options_section: String = "preset.%d.options" % idx
		var options_data: Dictionary = {}
		if config.has_section(options_section):
			for key in config.get_section_keys(options_section):
				options_data[key] = config.get_value(options_section, key)
		preset_data["__options__"] = options_data
		presets.append(preset_data)

	# Remove the target preset
	presets.remove_at(target_idx)

	# Clear the entire file and rewrite
	for idx in range(total_presets):
		var section: String = "preset.%d" % idx
		if config.has_section(section):
			for key in config.get_section_keys(section):
				config.erase_section_key(section, key)
			config.erase_section(section)
		var options_section: String = "preset.%d.options" % idx
		if config.has_section(options_section):
			for key in config.get_section_keys(options_section):
				config.erase_section_key(options_section, key)
			config.erase_section(options_section)

	# Write remaining presets back with re-indexed keys
	for idx in range(presets.size()):
		var section: String = "preset.%d" % idx
		var preset_data: Dictionary = presets[idx]
		var options_data: Dictionary = preset_data.get("__options__", {})
		preset_data.erase("__options__")
		for key in preset_data:
			config.set_value(section, key, preset_data[key])
		if not options_data.is_empty():
			var options_section: String = "preset.%d.options" % idx
			for key in options_data:
				config.set_value(options_section, key, options_data[key])

	var save_err: Error = config.save(config_path)
	if save_err != OK:
		return {"error": "Failed to save export presets: %s" % error_string(save_err)}

	return {"result": {
		"success": true,
		"name": name,
		"platform": deleted_platform,
		"config_path": config_path,
		"remaining_presets": presets.size(),
		"message": "Deleted export preset '%s' (%s). %d presets remaining." % [name, deleted_platform, presets.size()],
	}}


