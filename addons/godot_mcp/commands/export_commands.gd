## Export commands module - 7 tools.
## Handles export preset listing, project export, export info, templates, preset creation, and preset deletion.
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
		"export/delete_preset": delete_export_preset,
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
		return {"error": "Preset name is required"}

	# Verify the preset exists
	var config_path: String = "res://export_presets.cfg"
	if not FileAccess.file_exists(config_path):
		return {"error": "No export_presets.cfg found"}

	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(config_path)
	if err != OK:
		return {"error": "Failed to load export_presets.cfg"}

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
		return {"error": "Preset not found: %s" % preset_name}

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
	info["rendering"] = {
		"renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method", ""),
		"renderer_name": ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", ""),
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


## Validate the project for export - check presets and resources exist.
func validate_export(_params: Dictionary) -> Dictionary:
	var issues: Array = []
	# Check export_presets.cfg
	var config_path: String = "res://export_presets.cfg"
	if not FileAccess.file_exists(config_path):
		issues.append({"severity": "error", "message": "No export_presets.cfg found"})
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
	var error_count: int = issues.filter(func(i: Dictionary) -> bool: return i["severity"] == "error").size()
	var warning_count: int = issues.filter(func(i: Dictionary) -> bool: return i["severity"] == "warning").size()
	return {"result": {
		"valid": error_count == 0,
		"errors": error_count,
		"warnings": warning_count,
		"issues": issues,
		"message": "Validation: %d errors, %d warnings" % [error_count, warning_count] if issues.size() > 0 else "Export validation passed",
	}}


## List available export templates (built-in platform presets).
## Returns info about which export platforms are available in the current Godot build.
func get_export_templates(_params: Dictionary) -> Dictionary:
	var templates: Array = []

	# Read export_presets.cfg to list configured platforms
	var config_path: String = "res://export_presets.cfg"
	if not FileAccess.file_exists(config_path):
		return {"result": {"template_count": 0, "templates": [], "message": "No export_presets.cfg found"}}

	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(config_path)
	if err != OK:
		return {"error": "Failed to load export_presets.cfg: %s" % error_string(err)}

	var preset_index: int = 0
	while config.has_section("preset.%d" % preset_index):
		var section: String = "preset.%d" % preset_index
		var template_info: Dictionary = {
			"index": preset_index,
			"name": config.get_value(section, "name", "Unnamed"),
			"platform": config.get_value(section, "platform", "Unknown"),
			"runnable": config.get_value(section, "runnable", false),
		}
		templates.append(template_info)
		preset_index += 1

	return {"result": {"template_count": templates.size(), "templates": templates}}


## Create a new export preset by writing to export_presets.cfg.
## Accepts: name (string), platform (string, e.g. "Windows Desktop", "Linux/BSD", "Android").
func create_export_preset(params: Dictionary) -> Dictionary:
	var preset_name: String = params.get("name", "")
	var platform_name: String = params.get("platform", "")

	if preset_name.is_empty():
		return {"error": "Preset name is required"}
	if platform_name.is_empty():
		return {"error": "Platform name is required (e.g. 'Windows Desktop', 'Linux/BSD', 'Android')"}

	# Load existing config
	var config_path: String = "res://export_presets.cfg"
	var config: ConfigFile = ConfigFile.new()
	if FileAccess.file_exists(config_path):
		var err: Error = config.load(config_path)
		if err != OK:
			return {"error": "Failed to load export_presets.cfg: %s" % error_string(err)}

	# Find the next available preset index
	var next_index: int = 0
	while config.has_section("preset.%d" % next_index):
		next_index += 1

	# Check for duplicate names
	for check_i in range(next_index):
		var existing_name: String = config.get_value("preset.%d" % check_i, "name", "")
		if existing_name == preset_name:
			return {"error": "A preset named '%s' already exists" % preset_name}

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

	# Find the preset to delete
	var preset_index: int = -1
	var idx: int = 0
	while true:
		var section: String = "preset.%d" % idx
		if not config.has_section(section):
			break
		var name: String = config.get_value(section, "name", "") as String
		if name == preset_name:
			preset_index = idx
			break
		idx += 1

	if preset_index == -1:
		return {"success": false, "error": "Export preset not found: %s" % preset_name}

	# Remove the preset section and its options
	config.erase_section("preset.%d" % preset_index)
	config.erase_section("preset.%d.options" % preset_index)

	# Shift all subsequent presets down by one
	var next: int = preset_index + 1
	while true:
		var src_section: String = "preset.%d" % next
		if not config.has_section(src_section):
			break
		var dst_section: String = "preset.%d" % (next - 1)
		for key: String in config.get_section_keys(src_section):
			config.set_value(dst_section, key, config.get_value(src_section, key))
		config.erase_section(src_section)

		var src_options: String = "preset.%d.options" % next
		var dst_options: String = "preset.%d.options" % (next - 1)
		if config.has_section(src_options):
			for key: String in config.get_section_keys(src_options):
				config.set_value(dst_options, key, config.get_value(src_options, key))
			config.erase_section(src_options)
		elif config.has_section(dst_options):
			config.erase_section(dst_options)
		next += 1

	var save_err: Error = config.save(config_path)
	if save_err != OK:
		return {"success": false, "error": "Failed to save export_presets.cfg: %s" % error_string(save_err)}

	return {"success": true, "name": preset_name, "message": "Export preset '%s' deleted successfully." % preset_name}
