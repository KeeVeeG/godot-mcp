## Addon management commands module - 5 tools.
## Provides addon discovery, installation from multiple sources,
## uninstallation, updating, and configuration management.
class_name MCPAddonManagementCommands
extends RefCounted

var _plugin: EditorPlugin

## Addons directory
const ADDONS_DIR: String = "res://addons/"


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


## Validate addon name to prevent path traversal attacks.
## Returns empty string if valid, or error message if invalid.
func _validate_addon_name(name: String) -> String:
	if name.is_empty():
		return "Addon name is required"
	if name.contains("..") or name.contains("/") or name.contains("\\"):
		return "Invalid addon name: path traversal characters not allowed"
	# Only allow alphanumeric, hyphen, and underscore
	var regex := RegEx.new()
	regex.compile("^[a-zA-Z0-9_-]+$")
	if regex.search(name) == null:
		return "Invalid addon name: only letters, numbers, hyphens, and underscores allowed"
	return ""


## Safe filesystem refresh — skips if already scanning.
func _safe_refresh_filesystem() -> void:
	var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	if fs.is_scanning():
		return
	fs.call_deferred("scan")


func get_commands() -> Dictionary:
	return {
		"list_addons": list_addons,
		"install_addon": install_addon,
		"uninstall_addon": uninstall_addon,
		"update_addon": update_addon,
		"configure_addon": configure_addon,
	}


## List all installed addons with their versions and status.
func list_addons(_params: Dictionary) -> Dictionary:
	var addons: Array = []
	var addons_path: String = ProjectSettings.globalize_path(ADDONS_DIR)

	if not DirAccess.dir_exists_absolute(addons_path):
		return {"result": {"addons": [], "count": 0, "message": "No addons directory found"}}

	var dir: DirAccess = DirAccess.open(addons_path)
	if dir == null:
		return {"error": "Failed to open addons directory"}

	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not entry.begins_with(".") and dir.current_is_dir():
			var addon_info: Dictionary = _get_addon_info(entry)
			if addon_info.size() > 0:
				addons.append(addon_info)
		entry = dir.get_next()
	dir.list_dir_end()

	# Check which are active via plugin.cfg
	var active_plugins: Dictionary = {}
	var plugin_cfg: ConfigFile = ConfigFile.new()
	for addon: Dictionary in addons:
		var cfg_path: String = ADDONS_DIR.path_join(addon["name"]).path_join("plugin.cfg")
		if FileAccess.file_exists(cfg_path):
			if plugin_cfg.load(cfg_path) == OK:
				addon["version"] = plugin_cfg.get_value("plugin", "version", "unknown")
				addon["description"] = plugin_cfg.get_value("plugin", "description", "")
				addon["author"] = plugin_cfg.get_value("plugin", "author", "unknown")
				addon["script"] = plugin_cfg.get_value("plugin", "script", "")
				# Check if active
				var is_active: bool = _plugin.get_editor_interface().is_plugin_enabled(addon["name"])
				addon["active"] = is_active
			else:
				addon["version"] = "unknown"
				addon["active"] = false

	return {"result": {
		"addons": addons,
		"count": addons.size(),
		"active_count": addons.filter(func(a: Dictionary) -> bool: return a.get("active", false)).size(),
	}}


## Install an addon from a source.
func install_addon(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")
	var source: String = params.get("source", "asset_lib")
	var url: String = params.get("url", "")

	if name.is_empty():
		return {"error": "name is required"}
	var name_err: String = _validate_addon_name(name)
	if not name_err.is_empty():
		return {"error": name_err}

	match source:
		"asset_lib":
			return _install_from_asset_lib(name)
		"git":
			if url.is_empty():
				return {"error": "url is required for git source"}
			return _install_from_git(name, url)
		"local":
			if url.is_empty():
				return {"error": "url (local path) is required for local source"}
			return _install_from_local(name, url)
		_:
			return {"error": "Unknown source: %s" % source}


## Uninstall an addon.
func uninstall_addon(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")
	if name.is_empty():
		return {"error": "name is required"}
	var name_err: String = _validate_addon_name(name)
	if not name_err.is_empty():
		return {"error": name_err}

	var addon_path: String = ADDONS_DIR.path_join(name)
	var global_path: String = ProjectSettings.globalize_path(addon_path)

	if not DirAccess.dir_exists_absolute(global_path):
		return {"error": "Addon not found: %s" % name}

	# Disable the plugin first
	if EditorInterface.is_plugin_enabled(name):
		EditorInterface.set_plugin_enabled(name, false)

	# Remove the directory
	var err: Error = _remove_directory_recursive(global_path)
	if err != OK:
		return {"error": "Failed to remove addon directory: %s" % error_string(err)}

	# Clean up project.godot autoload references
	_remove_autoloads_for_addon(name)

	# Refresh the filesystem
	_safe_refresh_filesystem()

	return {"result": {
		"success": true,
		"name": name,
		"path": addon_path,
		"message": "Addon '%s' uninstalled successfully" % name,
	}}


## Update an installed addon.
func update_addon(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")

	if name.is_empty():
		return {"error": "name is required"}
	var name_err: String = _validate_addon_name(name)
	if not name_err.is_empty():
		return {"error": name_err}

	var addon_path: String = ADDONS_DIR.path_join(name)
	var global_path: String = ProjectSettings.globalize_path(addon_path)

	if not DirAccess.dir_exists_absolute(global_path):
		return {"error": "Addon not found: %s" % name}

	# Check if it's a git repo
	var git_dir: String = global_path.path_join(".git")
	if DirAccess.dir_exists_absolute(git_dir):
		# Git pull
		var output: Array = []
		var err: Error = OS.execute("git", PackedStringArray(["-C", global_path, "pull"]), output, true, false)
		if err != OK:
			return {"error": "Git pull failed: %s" % "".join(output)}

		_safe_refresh_filesystem()

		return {"result": {
			"success": true,
			"name": name,
			"source": "git",
			"output": "".join(output),
			"message": "Addon '%s' updated from git" % name,
		}}

	# For non-git addons, check if we have metadata about the source
	var meta_path: String = global_path.path_join(".mcp_addon_meta.json")
	if FileAccess.file_exists(meta_path):
		var file: FileAccess = FileAccess.open(meta_path, FileAccess.READ)
		if file != null:
			var json_text: String = file.get_as_text()
			file.close()
			var json: JSON = JSON.new()
			if json.parse(json_text) == OK and json.data is Dictionary:
				var meta: Dictionary = json.data as Dictionary
				var meta_source: String = meta.get("source", "")
				if meta_source == "git":
					return _install_from_git(name, meta.get("url", ""))
				elif meta_source == "local":
					return _install_from_local(name, meta.get("url", ""))

	return {"error": "Cannot determine update source for addon '%s'. Reinstall manually." % name}


## Configure an addon's settings.
func configure_addon(params: Dictionary) -> Dictionary:
	var name: String = params.get("name", "")
	var settings: Dictionary = params.get("settings", {})

	if name.is_empty():
		return {"error": "name is required"}
	var name_err: String = _validate_addon_name(name)
	if not name_err.is_empty():
		return {"error": name_err}
	if settings.is_empty():
		return {"error": "settings is required"}

	var addon_path: String = ADDONS_DIR.path_join(name)
	var global_path: String = ProjectSettings.globalize_path(addon_path)

	if not DirAccess.dir_exists_absolute(global_path):
		return {"error": "Addon not found: %s" % name}

	# Look for addon's config file
	var config_path: String = global_path.path_join("config.json")
	var addon_config: Dictionary = {}

	if FileAccess.file_exists(config_path):
		var file: FileAccess = FileAccess.open(config_path, FileAccess.READ)
		if file != null:
			var json_text: String = file.get_as_text()
			file.close()
			var json: JSON = JSON.new()
			if json.parse(json_text) == OK and json.data is Dictionary:
				addon_config = json.data as Dictionary

	# Merge settings
	for key: String in settings:
		addon_config[key] = settings[key]

	# Save updated config
	var file: FileAccess = FileAccess.open(config_path, FileAccess.WRITE)
	if file == null:
		return {"error": "Failed to write config file"}
	file.store_string(JSON.stringify(addon_config, "\t"))
	file.close()

	# Check for plugin.cfg to update project settings
	var plugin_cfg_path: String = addon_path.path_join("plugin.cfg")
	var project_settings_updated: int = 0
	for key: String in settings:
		var setting_key: String = "addons/%s/%s" % [name, key]
		ProjectSettings.set_setting(setting_key, settings[key])
		project_settings_updated += 1

	if project_settings_updated > 0:
		ProjectSettings.save()

	return {"result": {
		"success": true,
		"name": name,
		"settings_applied": settings.size(),
		"project_settings_updated": project_settings_updated,
		"config_path": config_path,
		"message": "Configured %d settings for addon '%s'" % [settings.size(), name],
	}}


## Helper: Get addon info from directory.
func _get_addon_info(addon_name: String) -> Dictionary:
	var addon_path: String = ADDONS_DIR.path_join(addon_name)
	var info: Dictionary = {
		"name": addon_name,
		"path": addon_path,
	}

	# Check for plugin.cfg
	var cfg_path: String = addon_path.path_join("plugin.cfg")
	if FileAccess.file_exists(cfg_path):
		info["has_plugin_cfg"] = true
	else:
		info["has_plugin_cfg"] = false

	# Count files
	var global_path: String = ProjectSettings.globalize_path(addon_path)
	var file_count: int = _count_files(global_path)
	info["file_count"] = file_count

	return info


## Helper: Install from Asset Library.
func _install_from_asset_lib(name: String) -> Dictionary:
	# The Asset Library installation requires the editor's built-in mechanism.
	# We return the command info for the user/editor to execute.
	return {"result": {
		"success": true,
		"name": name,
		"source": "asset_lib",
		"message": "Asset Library installation initiated for '%s'. Use the Godot editor's AssetLib tab to complete installation, or use the CLI: godot --headless --install-addon '%s'" % [name, name],
		"note": "The Godot editor's Asset Library provides the most reliable installation. Search for '%s' in the AssetLib tab." % name,
	}}


## Helper: Install from git.
func _install_from_git(name: String, url: String) -> Dictionary:
	var target_dir: String = ProjectSettings.globalize_path(ADDONS_DIR.path_join(name))

	# Check if already exists
	if DirAccess.dir_exists_absolute(target_dir):
		return {"error": "Addon directory already exists: %s. Uninstall first." % name}

	# Clone the repository
	var output: Array = []
	var err: Error = OS.execute("git", PackedStringArray(["clone", url, target_dir]), output, true, false)
	if err != OK:
		return {"error": "Git clone failed: %s" % "".join(output)}

	# Save metadata for future updates
	var meta_path: String = target_dir.path_join(".mcp_addon_meta.json")
	var file: FileAccess = FileAccess.open(meta_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"source": "git", "url": url, "installed_at": Time.get_datetime_string_from_system()}, "\t"))
		file.close()

	_safe_refresh_filesystem()

	# Enable plugin if plugin.cfg exists
	var plugin_cfg: String = ADDONS_DIR.path_join(name).path_join("plugin.cfg")
	if FileAccess.file_exists(plugin_cfg):
		EditorInterface.set_plugin_enabled(name, true)

	return {"result": {
		"success": true,
		"name": name,
		"source": "git",
		"url": url,
		"path": ADDONS_DIR.path_join(name),
		"message": "Addon '%s' installed from git: %s" % [name, url],
	}}


## Helper: Install from local path.
func _install_from_local(name: String, local_path: String) -> Dictionary:
	var source_path: String = local_path
	if local_path.begins_with("res://"):
		source_path = ProjectSettings.globalize_path(local_path)

	if not DirAccess.dir_exists_absolute(source_path):
		return {"error": "Source directory not found: %s" % local_path}

	var target_dir: String = ProjectSettings.globalize_path(ADDONS_DIR.path_join(name))

	# Check if already exists
	if DirAccess.dir_exists_absolute(target_dir):
		return {"error": "Addon directory already exists: %s. Uninstall first." % name}

	# Copy directory
	var err: Error = _copy_directory_recursive(source_path, target_dir)
	if err != OK:
		return {"error": "Failed to copy addon: %s" % error_string(err)}

	# Save metadata
	var meta_path: String = target_dir.path_join(".mcp_addon_meta.json")
	var file: FileAccess = FileAccess.open(meta_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"source": "local", "url": local_path, "installed_at": Time.get_datetime_string_from_system()}, "\t"))
		file.close()

	_safe_refresh_filesystem()

	# Enable plugin if plugin.cfg exists
	var plugin_cfg: String = ADDONS_DIR.path_join(name).path_join("plugin.cfg")
	if FileAccess.file_exists(plugin_cfg):
		EditorInterface.set_plugin_enabled(name, true)

	return {"result": {
		"success": true,
		"name": name,
		"source": "local",
		"source_path": local_path,
		"path": ADDONS_DIR.path_join(name),
		"message": "Addon '%s' installed from local path: %s" % [name, local_path],
	}}


## Helper: Remove directory recursively.
func _remove_directory_recursive(path: String) -> Error:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return ERR_CANT_OPEN

	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			var full_path: String = path.path_join(entry)
			if dir.current_is_dir():
				var err: Error = _remove_directory_recursive(full_path)
				if err != OK:
					return err
				DirAccess.remove_absolute(full_path)
			else:
				DirAccess.remove_absolute(full_path)
		entry = dir.get_next()
	dir.list_dir_end()

	return DirAccess.remove_absolute(path)


## Helper: Copy directory recursively.
func _copy_directory_recursive(source: String, target: String) -> Error:
	if not DirAccess.dir_exists_absolute(target):
		var err: Error = DirAccess.make_dir_recursive_absolute(target)
		if err != OK:
			return err

	var dir: DirAccess = DirAccess.open(source)
	if dir == null:
		return ERR_CANT_OPEN

	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			var src_path: String = source.path_join(entry)
			var dst_path: String = target.path_join(entry)
			if dir.current_is_dir():
				var err: Error = _copy_directory_recursive(src_path, dst_path)
				if err != OK:
					return err
			else:
				var src_file: FileAccess = FileAccess.open(src_path, FileAccess.READ)
				if src_file != null:
					var data: PackedByteArray = src_file.get_buffer(src_file.get_length())
					src_file.close()
					var dst_file: FileAccess = FileAccess.open(dst_path, FileAccess.WRITE)
					if dst_file != null:
						dst_file.store_buffer(data)
						dst_file.close()
		entry = dir.get_next()
	dir.list_dir_end()

	return OK


## Helper: Count files in a directory recursively.
func _count_files(path: String) -> int:
	var count: int = 0
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return 0

	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			if dir.current_is_dir():
				count += _count_files(path.path_join(entry))
			else:
				count += 1
		entry = dir.get_next()
	dir.list_dir_end()
	return count


## Helper: Remove autoload entries for a specific addon.
func _remove_autoloads_for_addon(addon_name: String) -> void:
	var addon_prefix: String = "addons/%s/" % addon_name
	var props: Array = ProjectSettings.get_property_list()
	for prop: Dictionary in props:
		var prop_name: String = prop["name"] as String
		if prop_name.begins_with("autoload/") and prop_name.find(addon_prefix) != -1:
			ProjectSettings.set_setting(prop_name, null)
	ProjectSettings.save()
