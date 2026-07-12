## Export commands module - 7 tools.
## Handles export preset listing, project export, export info, templates, preset creation, and preset deletion.
@tool
class_name MCPExportCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func get_commands() -> Dictionary:
	return {
		"export/list_presets": list_export_presets,
		"export/project": export_project,
		"export/get_info": get_export_info,
		"export/validate": validate_export,
		"export/get_templates": get_export_templates,
		"export/create_preset": create_export_preset,
		"export/delete_export_preset": delete_export_preset,
	}


## Parse export_presets.cfg and list all configured export presets.
func list_export_presets(_params: Dictionary) -> Dictionary:
	var config_path: String = "res://export_presets.cfg"
	if not FileAccess.file_exists(config_path):
		return {"result": {"preset_count": 0, "presets": []}}

	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(config_path)
	if err != OK:
		return {"error": "Failed to load export_presets.cfg: %s" % error_string(err)}

	var presets: Array = []
	var preset_index: int = 0
	while true:
		var section: String = "preset.%d" % preset_index
		if not config.has_section(section):
			break

		var preset_info: Dictionary = {
			"index": preset_index,
			"name": config.get_value(section, "name", "Unnamed"),
			"platform": config.get_value(section, "platform", "Unknown"),
			"runnable": config.get_value(section, "runnable", false),
			"export_path": config.get_value(section, "export_path", ""),
		}

		# Get custom features if any
		var features: String = config.get_value(section, "custom_features", "")
		if features != "":
			preset_info["custom_features"] = features

		# Check for options section
		var options_section: String = "preset.%d.options" % preset_index
		if config.has_section(options_section):
			var options: Dictionary = {}
			for key: String in config.get_section_keys(options_section):
				options[key] = config.get_value(options_section, key)
			preset_info["options"] = options

		presets.append(preset_info)
		preset_index += 1

	return {"result": {"preset_count": presets.size(), "presets": presets}}


## Build an export command string for use with the Godot CLI.
## Does not directly execute the export (would require headless mode)
## but returns the command that would need to be run.
func export_project(params: Dictionary) -> Dictionary:
	var preset_name: String = params.get("preset", "")
	var output_path: String = params.get("output_path", "")
	var debug: bool = params.get("debug", false)
	var pack_only: bool = params.get("pack_only", false)

	if preset_name.is_empty():
		return {"success": false, "error": "Preset name is required"}

	# Verify the preset exists
	var config_path: String = "res://export_presets.cfg"
	if not FileAccess.file_exists(config_path):
		return {"success": false, "error": "No export_presets.cfg found"}

	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(config_path)
	if err != OK:
		return {"success": false, "error": "Failed to load export_presets.cfg"}

	var found_preset: bool = false
	var platform: String = ""
	var default_export_path: String = ""
	var preset_index: int = 0
	while true:
		var section: String = "preset.%d" % preset_index
		if not config.has_section(section):
			break
		var name: String = config.get_value(section, "name", "") as String
		if name == preset_name:
			found_preset = true
			platform = config.get_value(section, "platform", "") as String
			default_export_path = config.get_value(section, "export_path", "") as String
			break
		preset_index += 1

	if not found_preset:
		return {"success": false, "error": "Preset not found: %s" % preset_name}

	if output_path.is_empty():
		output_path = default_export_path

	# Build the Godot CLI export command
	# godot --headless --export-release "Preset Name" output_path
	# or --export-debug for debug builds
	var cmd_parts: PackedStringArray = PackedStringArray()
	cmd_parts.append("godot")

	# Find the Godot executable path
	var exec_path: String = OS.get_executable_path()
	if exec_path != "":
		cmd_parts[0] = exec_path

	cmd_parts.append("--headless")
	cmd_parts.append("--path")
	cmd_parts.append(ProjectSettings.globalize_path("res://"))

	if pack_only:
		cmd_parts.append("--export-pack")
		cmd_parts.append('"%s"' % preset_name)
	elif debug:
		cmd_parts.append("--export-debug")
		cmd_parts.append('"%s"' % preset_name)
	else:
		cmd_parts.append("--export-release")
		cmd_parts.append('"%s"' % preset_name)

	if not output_path.is_empty():
		cmd_parts.append('"%s"' % output_path)

	var command_string: String = " ".join(cmd_parts)

	return {"result": {
		"preset": preset_name,
		"platform": platform,
		"output_path": output_path,
		"debug": debug,
		"pack_only": pack_only,
		"command": command_string,
		"executable": exec_path,
		"message": "Run the command in a terminal to export the project. Use --headless for CI/CD.",
	}}


## Get export-related project settings and configuration info.
func get_export_info(_params: Dictionary) -> Dictionary:
	var info: Dictionary = {}

	# Application settings
	info["application"] = {
		"name": ProjectSettings.get_setting("application/config/name", ""),
		"version": ProjectSettings.get_setting("application/config/version", ""),
		"description": ProjectSettings.get_setting("application/config/description", ""),
		"icon": ProjectSettings.get_setting("application/config/icon", ""),
		"custom_user_dir": ProjectSettings.get_setting("application/config/custom_user_dir_name", ""),
	}

	# Rendering settings relevant to export
	var renderer_method: String = ProjectSettings.get_setting("rendering/renderer/rendering_method", "")
	var renderer_display_name: String = renderer_method
	match renderer_method:
		"forward_plus":
			renderer_display_name = "Forward+"
		"mobile":
			renderer_display_name = "Mobile"
		"gl_compatibility":
			renderer_display_name = "Compatibility"
	info["rendering"] = {
		"renderer": renderer_method,
		"renderer_display_name": renderer_display_name,
		"textures/vram_compression/import_etc2_astc": ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false),
		"textures/vram_compression/import_s3tc_bptc": ProjectSettings.get_setting("rendering/textures/vram_compression/import_s3tc_bptc", false),
	}

	# Window settings
	info["window"] = {
		"size/viewport_width": ProjectSettings.get_setting("display/window/size/viewport_width", 1152),
		"size/viewport_height": ProjectSettings.get_setting("display/window/size/viewport_height", 648),
		"stretch/mode": ProjectSettings.get_setting("display/window/stretch/mode", "disabled"),
		"stretch/aspect": ProjectSettings.get_setting("display/window/stretch/aspect", "ignore"),
	}

	# Check for export_presets.cfg existence
	info["has_export_presets"] = FileAccess.file_exists("res://export_presets.cfg")

	# Count export presets if they exist
	var preset_count: int = 0
	if info["has_export_presets"]:
		var config: ConfigFile = ConfigFile.new()
		if config.load("res://export_presets.cfg") == OK:
			while true:
				var section: String = "preset.%d" % preset_count
				if not config.has_section(section):
					break
				preset_count += 1
	info["preset_count"] = preset_count

	# Check for feature tags
	info["feature_tags"] = {
		"is_debug_build": OS.has_feature("debug"),
		"is_release_build": OS.has_feature("release"),
		"is_editor": OS.has_feature("editor"),
		"platform": OS.get_name(),
	}

	return {"result": info}


## Validate the project for export - check presets, resources, scripts, and configuration.
func validate_export(_params: Dictionary) -> Dictionary:
	var issues: Array = []
	# Check export_presets.cfg
	var config_path: String = "res://export_presets.cfg"
	if not FileAccess.file_exists(config_path):
		issues.append({"severity": "warning", "message": "No export_presets.cfg found — no export presets configured"})
	else:
		var config: ConfigFile = ConfigFile.new()
		if config.load(config_path) != OK:
			issues.append({"severity": "error", "message": "Failed to load export_presets.cfg"})
		else:
			var preset_count: int = 0
			while config.has_section("preset.%d" % preset_count):
				preset_count += 1
			if preset_count == 0:
				issues.append({"severity": "warning", "message": "No export presets configured"})

	# Check main scene
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene.is_empty():
		issues.append({"severity": "warning", "message": "No main scene configured"})
	elif not FileAccess.file_exists(main_scene):
		issues.append({"severity": "error", "message": "Main scene not found: %s" % main_scene})

	# Check application name
	var app_name: String = ProjectSettings.get_setting("application/config/name", "")
	if app_name.is_empty():
		issues.append({"severity": "warning", "message": "No application name set"})

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

	# Check script errors — use load() which returns null on compile errors.
	# Skip addons/ (third-party code).
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
		"valid": error_count == 0,
		"errors": error_count,
		"warnings": warning_count,
		"issues": issues,
		"scenes_scanned": scene_files.size(),
		"scripts_scanned": script_files.size(),
		"message": "Validation: %d errors, %d warnings" % [error_count, warning_count] if issues.size() > 0 else "Export validation passed",
	}}


## List available export templates installed for the current Godot version.
## Scans the export_templates directory, NOT export_presets.cfg.
func get_export_templates(_params: Dictionary) -> Dictionary:
	var version_info: Dictionary = Engine.get_version_info()
	var version_str: String = version_info.get("string", "unknown")
	var templates_dir: String = OS.get_user_data_dir().path_join("export_templates")

	var installed: bool = DirAccess.dir_exists_absolute(templates_dir)
	var available_templates: Array = []
	var template_files: Array = []

	if installed:
		var version_dir: String = templates_dir.path_join(version_str)
		if DirAccess.dir_exists_absolute(version_dir):
			var dir: DirAccess = DirAccess.open(version_dir)
			if dir != null:
				dir.list_dir_begin()
				var file_name: String = dir.get_next()
				while file_name != "":
					if not file_name.begins_with("."):
						template_files.append(file_name)
					file_name = dir.get_next()
				dir.list_dir_end()

	# Categorize templates by platform based on filename patterns
	var detected_platforms: Array = []
	var platform_patterns: Dictionary = {
		"windows": ["windows", "win"],
		"linux": ["linux", "x11"],
		"macos": ["macos", "osx", "mac"],
		"android": ["android"],
		"ios": ["ios", "iphone"],
		"web": ["web", "html5", "javascript"],
	}
	for file_name: String in template_files:
		var fname_lower: String = file_name.to_lower()
		for platform_key: String in platform_patterns:
			var patterns: Array = platform_patterns[platform_key]
			for pattern: String in patterns:
				if pattern in fname_lower:
					if platform_key not in detected_platforms:
						detected_platforms.append(platform_key)
					break

	return {"result": {
		"godot_version": version_str,
		"templates_installed": installed,
		"templates_dir": templates_dir,
		"version_dir": templates_dir.path_join(version_str) if installed else "",
		"template_files": template_files,
		"template_count": template_files.size(),
		"detected_platforms": detected_platforms,
		"message": "Found %d export template files for Godot %s" % [template_files.size(), version_str] if installed and template_files.size() > 0 else "No export templates found for Godot %s. Download from Godot editor: Editor > Manage Export Templates." % version_str,
	}}


## Valid Godot export platform names.
const VALID_PLATFORMS: PackedStringArray = [
	"Windows Desktop",
	"Linux",
	"macOS",
	"Android",
	"iOS",
	"Web",
]

## Create a new export preset by writing to export_presets.cfg.
## Accepts: name (string), platform (string, e.g. "Windows Desktop", "Linux", "Android").
func create_export_preset(params: Dictionary) -> Dictionary:
	var preset_name: String = params.get("name", "")
	var platform_name: String = params.get("platform", "")

	if preset_name.is_empty():
		return {"success": false, "error": "Preset name is required"}
	if platform_name.is_empty():
		return {"success": false, "error": "Platform name is required (e.g. 'Windows Desktop', 'Linux', 'Android')"}

	# Validate platform name
	if platform_name not in VALID_PLATFORMS:
		return {"success": false, "error": "Unsupported platform: '%s'. Valid platforms: %s" % [platform_name, ", ".join(VALID_PLATFORMS)]}

	# Load existing config
	var config_path: String = "res://export_presets.cfg"
	var config: ConfigFile = ConfigFile.new()
	if FileAccess.file_exists(config_path):
		var err: Error = config.load(config_path)
		if err != OK:
			return {"success": false, "error": "Failed to load export_presets.cfg: %s" % error_string(err)}

	# Find the next available preset index AND check for duplicate names
	var next_index: int = 0
	var duplicate_found: bool = false
	while config.has_section("preset.%d" % next_index):
		var existing_name: String = config.get_value("preset.%d" % next_index, "name", "")
		if existing_name == preset_name:
			duplicate_found = true
		next_index += 1

	if duplicate_found:
		return {"success": false, "error": "A preset named '%s' already exists. Delete it first or use a different name." % preset_name}

	# Write the new preset
	var section: String = "preset.%d" % next_index
	config.set_value(section, "name", preset_name)
	config.set_value(section, "platform", platform_name)
	config.set_value(section, "runnable", true)
	config.set_value(section, "export_path", "")
	config.set_value(section, "custom_features", "")
	config.set_value(section, "include_filter", "")
	config.set_value(section, "exclude_filter", "")
	config.set_value(section, "export_filter", "all_resources")

	var save_err: Error = config.save(config_path)
	if save_err != OK:
		return {"success": false, "error": "Failed to save export_presets.cfg: %s" % error_string(save_err)}

	return {"success": true, "preset_index": next_index, "name": preset_name, "platform": platform_name, "message": "Export preset '%s' created. Open Project > Export to configure additional options." % preset_name}


## Delete an export preset from the project.
func delete_export_preset(params: Dictionary) -> Dictionary:
	var preset_name: String = params.get("name", "")
	if preset_name.is_empty():
		return {"success": false, "error": "Preset name is required"}

	var config_path: String = "res://export_presets.cfg"
	if not FileAccess.file_exists(config_path):
		return {"success": false, "error": "No export_presets.cfg found"}

	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(config_path)
	if err != OK:
		return {"success": false, "error": "Failed to load export_presets.cfg: %s" % error_string(err)}

	# Count total presets and find the target
	var total_presets: int = 0
	var target_idx: int = -1
	while config.has_section("preset.%d" % total_presets):
		if config.get_value("preset.%d" % total_presets, "name", "") == preset_name:
			target_idx = total_presets
		total_presets += 1

	if target_idx == -1:
		return {"success": false, "error": "Export preset not found: %s" % preset_name}

	# Read all presets into memory
	var presets: Array = []
	for idx in range(total_presets):
		var section: String = "preset.%d" % idx
		var preset_data: Dictionary = {}
		for key: String in config.get_section_keys(section):
			preset_data[key] = config.get_value(section, key)
		# Also capture options section
		var options_section: String = "preset.%d.options" % idx
		if config.has_section(options_section):
			var opts: Dictionary = {}
			for key: String in config.get_section_keys(options_section):
				opts[key] = config.get_value(options_section, key)
			preset_data["__options__"] = opts
		presets.append(preset_data)

	# Remove the target preset
	var deleted_platform: String = presets[target_idx].get("platform", "unknown")
	presets.remove_at(target_idx)

	# Clear all sections from config (up to original count)
	for idx in range(total_presets):
		var section: String = "preset.%d" % idx
		if config.has_section(section):
			for key: String in config.get_section_keys(section):
				config.erase_section_key(section, key)
			config.erase_section(section)
		var options_section: String = "preset.%d.options" % idx
		if config.has_section(options_section):
			for key: String in config.get_section_keys(options_section):
				config.erase_section_key(options_section, key)
			config.erase_section(options_section)

	# Write remaining presets with re-indexed keys
	for idx in range(presets.size()):
		var section: String = "preset.%d" % idx
		var preset_data: Dictionary = presets[idx]
		var options_data: Dictionary = preset_data.get("__options__", {})
		preset_data.erase("__options__")
		for key: String in preset_data:
			config.set_value(section, key, preset_data[key])
		if not options_data.is_empty():
			var options_section: String = "preset.%d.options" % idx
			for key: String in options_data:
				config.set_value(options_section, key, options_data[key])

	var save_err: Error = config.save(config_path)
	if save_err != OK:
		return {"success": false, "error": "Failed to save export_presets.cfg: %s" % error_string(save_err)}

	return {"success": true, "name": preset_name, "platform": deleted_platform, "remaining_presets": presets.size(), "message": "Export preset '%s' deleted successfully. %d presets remaining." % [preset_name, presets.size()]}
