## Project creation commands module - 12 tools.
## Handles project scaffolding, templates, git init, licensing, and dependency setup.
@tool
class_name MCPProjectCreationCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


## Router compatibility: returns callable map for MCPCommandRouter.
func get_commands() -> Dictionary:
	return {
		"project_creation/create_project": func(params: Dictionary) -> Dictionary: return execute("create_project", params),
		"project_creation/create_from_template": func(params: Dictionary) -> Dictionary: return execute("create_project_from_template", params),
		"project_creation/scaffold_structure": func(params: Dictionary) -> Dictionary: return execute("scaffold_project_structure", params),
		"project_creation/create_with_assets": func(params: Dictionary) -> Dictionary: return execute("create_project_with_assets", params),
		"project_creation/init_git": func(params: Dictionary) -> Dictionary: return execute("initialize_git_repository", params),
		"project_creation/create_readme": func(params: Dictionary) -> Dictionary: return execute("create_project_readme", params),
		"project_creation/create_license": func(params: Dictionary) -> Dictionary: return execute("create_project_license", params),
		"project_creation/setup_dependencies": func(params: Dictionary) -> Dictionary: return execute("setup_project_dependencies", params),
		"project_creation/validate_structure": func(params: Dictionary) -> Dictionary: return execute("validate_project_structure", params),
		"project_creation/delete_project": func(params: Dictionary) -> Dictionary: return execute("delete_project", params),
		"project_creation/remove_dependencies": func(params: Dictionary) -> Dictionary: return execute("remove_project_dependencies", params),
		"project_creation/get_templates": func(params: Dictionary) -> Dictionary: return execute("get_project_templates", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"create_project": return _create_project(params)
		"create_project_from_template": return _create_project_from_template(params)
		"scaffold_project_structure": return _scaffold_project_structure(params)
		"create_project_with_assets": return _create_project_with_assets(params)
		"initialize_git_repository": return _initialize_git_repository(params)
		"create_project_readme": return _create_project_readme(params)
		"create_project_license": return _create_project_license(params)
		"setup_project_dependencies": return _setup_project_dependencies(params)
		"validate_project_structure": return _validate_project_structure(params)
		"delete_project": return _delete_project(params)
		"remove_project_dependencies": return _remove_project_dependencies(params)
		"get_project_templates": return _get_project_templates()
	return {"success": false, "error": "Unknown method: " + method}


## Create a new Godot project from scratch.
func _create_project(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var name: String = params.get("name", "New Project")
	var template: String = params.get("template", "empty")
	var renderer: String = params.get("renderer", "forward_plus")
	var godot_version: String = params.get("godot_version", "")

	if path.is_empty():
		return {"success": false, "error": "Path is required"}

	if not MCPCommandHelpers.validate_path(path):
		return {"success": false, "error": "Invalid path"}

	# Detect invalid Windows filename characters before attempting directory creation
	# NOTE: / and \ are valid Windows path separators, : is valid as drive letter delimiter (C:)
	var invalid_chars: RegEx = RegEx.new()
	invalid_chars.compile("[<>\"|?*]")
	if invalid_chars.search(path):
		return {"success": false, "error": "Path contains invalid characters: %s. Windows disallows: < > \" | ? *" % path}

	# Check if project already exists at this path
	var config_path: String = path.path_join("project.godot")
	var overwrite: bool = params.get("overwrite", false)
	if FileAccess.file_exists(config_path) and not overwrite:
		return {
			"success": false,
			"error": "project.godot already exists at '%s'. Pass overwrite=true to replace it." % path,
			"existing_project": true,
		}

	# Create project directory
	var err: Error = DirAccess.make_dir_recursive_absolute(path)
	if err != OK:
		return {"success": false, "error": "Failed to create directory: %s" % error_string(err)}

	# Create project.godot
	var config_content: String = _generate_project_godot(name, renderer, godot_version)
	var file: FileAccess = FileAccess.open(config_path, FileAccess.WRITE)
	if file == null:
		return {"success": false, "error": "Failed to create project.godot"}
	file.store_string(config_content)
	file.close()

	# Create standard folder structure based on template
	var folders: PackedStringArray = _get_template_folders(template)
	for folder: String in folders:
		DirAccess.make_dir_recursive_absolute(path.path_join(folder))

	# Create default scenes based on template
	match template:
		"2d":
			_create_default_scene(path, "main", "Node2D")
		"3d":
			_create_default_scene(path, "main", "Node3D")
		"ui":
			_create_default_scene(path, "main", "Control")

	# Validate godot_version against current engine
	var warnings: Array = []
	if not godot_version.is_empty():
		var engine_major: int = Engine.get_version_info().get("major", 4)
		var engine_minor: int = Engine.get_version_info().get("minor", 0)
		var engine_version: String = "%d.%d" % [engine_major, engine_minor]
		if godot_version != engine_version:
			warnings.append(
				"godot_version '%s' does not match current Godot engine version '%s'. The project uses config_version=5 (Godot 4.x format) regardless of the version parameter."
				% [godot_version, engine_version]
			)

	return {
		"success": true,
		"path": path,
		"name": name,
		"template": template,
		"renderer": renderer,
		"folders_created": folders,
		"warnings": warnings,
	}


## Create a project by copying and renaming a template project.
func _create_project_from_template(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var template_path: String = params.get("template_path", "")
	var name: String = params.get("name", "")

	if path.is_empty() or template_path.is_empty():
		return {"success": false, "error": "Both path and template_path are required"}

	if not MCPCommandHelpers.validate_path(path):
		return {"success": false, "error": "Invalid path"}
	if not MCPCommandHelpers.validate_path(template_path):
		return {"success": false, "error": "Invalid template path"}

	if not DirAccess.dir_exists_absolute(template_path):
		return {"success": false, "error": "Template path not found: %s" % template_path}

	# Validate template is a Godot project BEFORE parent/child checks
	if not FileAccess.file_exists(template_path.path_join("project.godot")):
		return {"success": false, "error": "Template path is not a valid Godot project (missing project.godot)"}

	# Prevent self-copy: normalize paths for comparison (handle / vs \ on Windows)
	var normalized_path: String = path.replace("\\", "/").trim_suffix("/")
	var normalized_template: String = template_path.replace("\\", "/").trim_suffix("/")
	if normalized_path == normalized_template:
		return {"success": false, "error": "Cannot copy template into itself (path equals template_path)"}
	if normalized_path.begins_with(normalized_template + "/"):
		return {"success": false, "error": "Cannot copy template into a subdirectory of itself"}

	# Copy template to new location
	var err: Error = MCPCommandHelpers.copy_directory_recursive(template_path, path)
	if err != OK:
		return {"success": false, "error": "Failed to copy template: %s" % error_string(err)}

	var config_path: String = path.path_join("project.godot")

	# Update project name if provided
	if not name.is_empty():
		if FileAccess.file_exists(config_path):
			var cfg: ConfigFile = ConfigFile.new()
			var cfg_err: Error = cfg.load(config_path)
			if cfg_err == OK:
				cfg.set_value("application", "config/name", name)
				cfg.save(config_path)

	# If name was not provided, read it from the cloned project.godot for the response
	if name.is_empty() and FileAccess.file_exists(config_path):
		var read_cfg: ConfigFile = ConfigFile.new()
		if read_cfg.load(config_path) == OK:
			name = read_cfg.get_value("application", "config/name", name)

	return {"success": true, "path": path, "template": template_path, "name": name}


## Create standard folder structure in an existing project.
func _scaffold_project_structure(params: Dictionary) -> Dictionary:
	var project_path: String = params.get("project_path", "")
	var structure: String = params.get("structure", "standard")

	if project_path.is_empty():
		return {"success": false, "error": "Project path is required"}

	if not MCPCommandHelpers.validate_path(project_path):
		return {"success": false, "error": "Invalid path"}

	if not DirAccess.dir_exists_absolute(project_path):
		return {"success": false, "error": "Path does not exist: %s" % project_path}

	if not FileAccess.file_exists(project_path.path_join("project.godot")):
		return {"success": false, "error": "Not a valid Godot project: %s (missing project.godot)" % project_path}

	var folders: PackedStringArray = _get_template_folders(structure)
	var created: Array = []
	for folder: String in folders:
		var full_path: String = project_path.path_join(folder)
		if not DirAccess.dir_exists_absolute(full_path):
			var err: Error = DirAccess.make_dir_recursive_absolute(full_path)
			if err == OK:
				created.append(folder)

	return {"success": true, "structure": structure, "folders_created": created, "total": created.size()}


## Create a project and import specified assets.
func _create_project_with_assets(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var name: String = params.get("name", "New Project")
	var assets: Array = params.get("assets", [])

	if path.is_empty():
		return {"success": false, "error": "Path is required"}

	# Create the project first
	var create_result: Dictionary = _create_project({
		"path": path,
		"name": name,
		"template": "standard",
	})
	if not create_result.get("success", false):
		return create_result

	# Detect duplicate destinations before importing (prevents silent overwrites)
	var seen_destinations: Dictionary = {}
	var duplicate_destinations: Array = []
	for asset_def in assets:
		if not (asset_def is Dictionary):
			continue
		var asset: Dictionary = asset_def as Dictionary
		var dest: String = asset.get("destination", "")
		if not dest.is_empty():
			if dest in seen_destinations:
				duplicate_destinations.append(dest)
			else:
				seen_destinations[dest] = true

	if not duplicate_destinations.is_empty():
		_remove_directory_recursive(path)
		return {
			"success": false,
			"error": "Duplicate asset destinations detected: %s. Each asset must have a unique destination within the same call." % str(duplicate_destinations),
			"duplicate_destinations": duplicate_destinations,
		}

	# Import assets
	var imported: Array = []
	var errors: Array = []
	for asset_def: Variant in assets:
		if not (asset_def is Dictionary):
			continue
		var asset: Dictionary = asset_def as Dictionary
		var source: String = asset.get("source", "")
		var destination: String = asset.get("destination", "")
		var asset_type: String = asset.get("type", "")
		if source.is_empty():
			errors.append("Asset missing source: %s" % str(asset))
			continue
		# If no destination given, derive a default from the asset type
		if destination.is_empty():
			match asset_type:
				"texture":
					destination = "res://assets/textures/%s" % source.get_file()
				"audio":
					destination = "res://assets/audio/%s" % source.get_file()
				"scene":
					destination = "res://scenes/%s" % source.get_file()
				"script":
					destination = "res://scripts/%s" % source.get_file()
				_:
					destination = "res://assets/%s" % source.get_file()
		var dest_full: String = path.path_join(destination.replace("res://", ""))
		var dest_dir: String = dest_full.get_base_dir()
		if not DirAccess.dir_exists_absolute(dest_dir):
			DirAccess.make_dir_recursive_absolute(dest_dir)
		if FileAccess.file_exists(source):
			var err: Error = DirAccess.copy_absolute(source, dest_full)
			if err == OK:
				imported.append({"path": destination, "type": asset_type})
			else:
				errors.append("Failed to copy %s: %s" % [source, error_string(err)])
		else:
			errors.append("Source file not found: %s" % source)

	# Trigger Godot's import pipeline to generate .import files for copied assets
	if imported.size() > 0:
		EditorInterface.get_resource_filesystem().scan()

	var all_success: bool = not (errors.size() > 0 and imported.size() == 0)

	# Rollback project creation if all assets failed to import (no partial success)
	if not all_success:
		_remove_directory_recursive(path)

	var result: Dictionary = {
		"success": all_success,
		"name": name,
		"imported": imported,
		"errors": errors,
	}
	if all_success:
		result["path"] = path
	return result


## Initialize a git repository with optional .gitignore.
func _initialize_git_repository(params: Dictionary) -> Dictionary:
	var project_path: String = params.get("project_path", "")
	var include_gitignore: bool = params.get("include_gitignore", true)

	if project_path.is_empty():
		return {"success": false, "error": "Project path is required"}

	if not FileAccess.file_exists(project_path.path_join("project.godot")):
		return {"success": false, "error": "Not a valid Godot project (missing project.godot)"}

	# Create .gitignore if requested
	if include_gitignore:
		var gitignore_content: String = _get_godot_gitignore()
		var gitignore_path: String = project_path.path_join(".gitignore")
		var file: FileAccess = FileAccess.open(gitignore_path, FileAccess.WRITE)
		if file:
			file.store_string(gitignore_content)
			file.close()

	# Actually initialize the git repository
	var output: Array = []
	var exit_code: int = OS.execute("git", ["init", project_path], output, true)
	if exit_code != 0:
		var error_text: String = "".join(output) if output.size() > 0 else "Unknown error"
		return {
			"success": false,
			"error": "git init failed (exit code %d): %s" % [exit_code, error_text],
			"path": project_path,
			"gitignore_created": include_gitignore,
		}

	return {
		"success": true,
		"path": project_path,
		"git_initialized": true,
		"gitignore_created": include_gitignore,
	}


## Create a README.md file for the project.
func _create_project_readme(params: Dictionary) -> Dictionary:
	var project_path: String = params.get("project_path", "")
	var content: String = params.get("content", "")
	var template: String = params.get("template", "basic")

	if project_path.is_empty():
		return {"success": false, "error": "Project path is required"}

	if not FileAccess.file_exists(project_path.path_join("project.godot")):
		return {"success": false, "error": "Not a valid Godot project (missing project.godot)"}

	# Get project name for template
	var project_name: String = ProjectSettings.get_setting("application/config/name", "Godot Project")
	if project_path == ProjectSettings.globalize_path("res://"):
		pass  # Use current project name
	else:
		# Try to read from the target project.godot
		var config_path: String = project_path.path_join("project.godot")
		if FileAccess.file_exists(config_path):
			var cfg: ConfigFile = ConfigFile.new()
			if cfg.load(config_path) == OK:
				project_name = cfg.get_value("application", "config/name", project_name)

	if not params.has("content"):
		content = _generate_readme(project_name, template)
	else:
		# Unescape JSON string escape sequences that the JSON transport may have double-escaped
		content = _unescape_json_string(content)

	var readme_path: String = project_path.path_join("README.md")
	var file: FileAccess = FileAccess.open(readme_path, FileAccess.WRITE)
	if file == null:
		return {"success": false, "error": "Failed to create README.md"}
	file.store_string(content)
	file.close()

	var used_template: String = template
	if params.has("content"):
		used_template = "custom"

	return {"success": true, "path": readme_path, "template": used_template}


## Create a LICENSE file.
func _create_project_license(params: Dictionary) -> Dictionary:
	var project_path: String = params.get("project_path", "")
	var license_type: String = params.get("license", "MIT")
	var custom_text: String = params.get("custom_text", "")

	if project_path.is_empty():
		return {"success": false, "error": "Project path is required"}

	if not DirAccess.dir_exists_absolute(project_path):
		return {"success": false, "error": "Project path does not exist: %s" % project_path}

	if not FileAccess.file_exists(project_path.path_join("project.godot")):
		return {"success": false, "error": "Not a valid Godot project (missing project.godot)"}

	var warnings: Array = []
	var license_text: String = ""

	if not custom_text.is_empty() and license_type != "custom":
		warnings.append("custom_text is ignored for license type '%s' (only used with 'custom')" % license_type)

	match license_type:
		"MIT":
			license_text = _get_mit_license()
		"Apache-2.0":
			license_text = _get_apache_license()
		"GPL-3.0":
			license_text = _get_gpl3_license()
		"BSD-3-Clause":
			license_text = _get_bsd3_license()
		"custom":
			if custom_text.is_empty():
				return {"success": false, "error": "custom_text is required for custom license"}
			license_text = _unescape_json_string(custom_text)
		_:
			return {"success": false, "error": "Unknown license type: %s" % license_type}

	var license_path: String = project_path.path_join("LICENSE")
	var file: FileAccess = FileAccess.open(license_path, FileAccess.WRITE)
	if file == null:
		return {"success": false, "error": "Failed to create LICENSE file"}
	file.store_string(license_text)
	file.close()

	return {"success": true, "path": license_path, "license": license_type, "warnings": warnings}


## Setup project dependencies / addons.
func _setup_project_dependencies(params: Dictionary) -> Dictionary:
	var project_path: String = params.get("project_path", "")
	var addons: Array = params.get("addons", [])

	if project_path.is_empty():
		return {"success": false, "error": "Project path is required"}

	if not DirAccess.dir_exists_absolute(project_path):
		return {"success": false, "error": "Project path does not exist: %s" % project_path}

	if not FileAccess.file_exists(project_path.path_join("project.godot")):
		return {"success": false, "error": "Not a valid Godot project (missing project.godot)"}

	var addons_dir: String = project_path.path_join("addons")
	if not DirAccess.dir_exists_absolute(addons_dir):
		DirAccess.make_dir_recursive_absolute(addons_dir)

	var installed: Array = []
	var errors: Array = []
	for addon_def: Variant in addons:
		if not (addon_def is Dictionary):
			continue
		var addon: Dictionary = addon_def as Dictionary
		var addon_name: String = addon.get("name", "")
		var source: String = addon.get("source", "local")
		var url: String = addon.get("url", "")

		if addon_name.is_empty():
			errors.append("Addon missing name")
			continue

		var dest_path: String = addons_dir.path_join(addon_name)
		match source:
			"local":
				if url.is_empty():
					errors.append("Local addon '%s' requires url (source path)" % addon_name)
					continue
				if DirAccess.dir_exists_absolute(url):
					if not FileAccess.file_exists(url.path_join("plugin.cfg")):
						errors.append("Local addon source is not a valid Godot addon (missing plugin.cfg): %s" % url)
						continue
					var err: Error = MCPCommandHelpers.copy_directory_recursive(url, dest_path)
					if err == OK:
						installed.append(addon_name)
					else:
						errors.append("Failed to copy addon '%s': %s" % [addon_name, error_string(err)])
				else:
					errors.append("Local addon source not found: %s" % url)
			"git":
				if url.is_empty():
					errors.append("Git addon '%s' requires url" % addon_name)
					continue
				# Clone the git repository into the addon directory
				var git_output: Array = []
				var git_exit: int = OS.execute("git", ["clone", url, dest_path], git_output, true)
				if git_exit == 0:
					# Remove .git directory to avoid nesting issues
					var dot_git: String = dest_path.path_join(".git")
					if DirAccess.dir_exists_absolute(dot_git):
						_remove_directory_recursive(dot_git)
					installed.append(addon_name)
				else:
					errors.append("Git clone failed for '%s' (exit %d): %s" % [addon_name, git_exit, "\n".join(git_output)])
			"asset_lib":
				# Asset Library installation requires async HTTP + ZIP extraction
				# which is not yet implemented in this synchronous context.
				# Use the Godot editor AssetLib tab or install_from_asset_lib tool instead.
				errors.append("Asset Library installation not yet supported for '%s'. Use Godot editor AssetLib tab to install, or install from git/local source." % addon_name)
			_:
				errors.append("Unknown addon source: %s" % source)

	var all_success: bool = not (errors.size() > 0 and installed.size() == 0)
	return {"success": all_success, "installed": installed, "errors": errors}


## Validate a project's folder structure.
func _validate_project_structure(params: Dictionary) -> Dictionary:
	var project_path: String = params.get("project_path", "")

	if project_path.is_empty():
		return {"success": false, "error": "Project path is required"}

	if not DirAccess.dir_exists_absolute(project_path):
		return {"success": false, "error": "Path does not exist: %s" % project_path}

	var config_path: String = project_path.path_join("project.godot")
	if not FileAccess.file_exists(config_path):
		return {"success": false, "error": "Not a valid Godot project: %s (missing project.godot)" % project_path}

	var issues: Array = []
	var warnings: Array = []
	var info: Dictionary = {}

	# Check project.godot is readable
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(config_path)
	if err != OK:
		issues.append("Cannot parse project.godot: %s" % error_string(err))
	else:
		info["project_name"] = cfg.get_value("application", "config/name", "")
		info["main_scene"] = cfg.get_value("application", "run/main_scene", "")

	# Check for recommended directories
	var recommended_dirs: PackedStringArray = [
		"scenes", "scripts", "assets", "resources", "shaders", "tests", "addons", "themes"
	]
	var existing_dirs: Array = []
	var missing_dirs: Array = []
	for dir_name: String in recommended_dirs:
		if DirAccess.dir_exists_absolute(project_path.path_join(dir_name)):
			existing_dirs.append(dir_name)
		else:
			missing_dirs.append(dir_name)
	if missing_dirs.size() > 0:
		warnings.append("Missing recommended directories: %s" % ", ".join(missing_dirs))

	# Include list of existing top-level directories in info
	info["existing_directories"] = existing_dirs

	# Check for main scene
	if info.get("main_scene", "").is_empty():
		warnings.append("No main scene configured in project settings")

	# Check for .gitignore
	if not FileAccess.file_exists(project_path.path_join(".gitignore")):
		warnings.append("No .gitignore file found")

	# Check for README
	if not FileAccess.file_exists(project_path.path_join("README.md")):
		warnings.append("No README.md file found")

	# Count files by type
	var file_counts: Dictionary = {}
	_count_files_recursive(project_path, file_counts, 0, 6)
	info["file_counts"] = file_counts

	return {
		"success": true,
		"valid": issues.is_empty(),
		"issues": issues,
		"warnings": warnings,
		"info": info,
	}


## Delete a project and all its files from disk.
func _delete_project(params: Dictionary) -> Dictionary:
	var project_path: String = params.get("project_path", "")
	var confirm: bool = params.get("confirm", false)

	if project_path.is_empty():
		return {"success": false, "error": "Project path is required"}

	if not MCPCommandHelpers.validate_path(project_path):
		return {"success": false, "error": "Invalid path"}

	if not DirAccess.dir_exists_absolute(project_path):
		return {"success": false, "error": "Project path does not exist: %s" % project_path}

	var config_path: String = project_path.path_join("project.godot")
	if not FileAccess.file_exists(config_path):
		return {"success": false, "error": "Not a valid Godot project (missing project.godot)"}

	# Safety: require explicit confirmation
	if not confirm:
		return {
			"success": false,
			"error": "Deletion requires confirm=true to prevent accidental data loss. Path: %s" % project_path,
			"requires_confirmation": true,
		}

	# Count files before deletion for the report
	var file_count: Dictionary = {}
	_count_files_recursive(project_path, file_count, 0, 32)
	var total_files: int = 0
	for ext: String in file_count:
		total_files += file_count[ext]

	# Delete the project directory recursively
	var err: Error = _remove_directory_recursive(project_path)
	if err != OK:
		return {"success": false, "error": "Failed to delete project: %s" % error_string(err)}

	return {
		"success": true,
		"path": project_path,
		"deleted": true,
		"total_files_removed": total_files,
	}


## Remove installed dependencies / addons from a project.
func _remove_project_dependencies(params: Dictionary) -> Dictionary:
	var project_path: String = params.get("project_path", "")
	var addons: Array = params.get("addons", [])

	if project_path.is_empty():
		return {"success": false, "error": "Project path is required"}

	if not MCPCommandHelpers.validate_path(project_path):
		return {"success": false, "error": "Invalid path"}

	if not DirAccess.dir_exists_absolute(project_path):
		return {"success": false, "error": "Project path does not exist: %s" % project_path}

	if not FileAccess.file_exists(project_path.path_join("project.godot")):
		return {"success": false, "error": "Not a valid Godot project (missing project.godot)"}

	if addons.is_empty():
		return {"success": false, "error": "addons array is required and must not be empty"}

	var addons_dir: String = project_path.path_join("addons")
	var removed: Array = []
	var errors: Array = []

	for addon_def: Variant in addons:
		var addon_name: String = ""
		if addon_def is String:
			addon_name = addon_def as String
		elif addon_def is Dictionary:
			addon_name = (addon_def as Dictionary).get("name", "")
		else:
			errors.append("Invalid addon entry: %s" % str(addon_def))
			continue

		if addon_name.is_empty():
			errors.append("Addon name is empty")
			continue

		var addon_path: String = addons_dir.path_join(addon_name)
		if not DirAccess.dir_exists_absolute(addon_path):
			errors.append("Addon not found: %s (path: %s)" % [addon_name, addon_path])
			continue

		var err: Error = _remove_directory_recursive(addon_path)
		if err == OK:
			removed.append(addon_name)
		else:
			errors.append("Failed to remove addon '%s': %s" % [addon_name, error_string(err)])

	return {"success": true, "removed": removed, "errors": errors}


## Get list of available project templates.
func _get_project_templates() -> Dictionary:
	var templates: Array = [
		{
			"name": "empty",
			"description": "Empty project with minimal structure",
			"folders": ["scenes", "scripts"],
		},
		{
			"name": "2d",
			"description": "2D game project with common folders and a main Node2D scene",
			"folders": ["scenes", "scripts", "assets/sprites", "assets/audio", "assets/fonts", "resources"],
		},
		{
			"name": "3d",
			"description": "3D game project with common folders and a main Node3D scene",
			"folders": ["scenes", "scripts", "assets/models", "assets/textures", "assets/audio", "resources"],
		},
		{
			"name": "ui",
			"description": "UI application project with Control-based main scene",
			"folders": ["scenes", "scripts", "assets/fonts", "assets/icons", "themes", "resources"],
		},
		{
			"name": "custom",
			"description": "Custom project with all possible folders pre-created",
			"folders": [
				"scenes", "scripts", "assets/sprites", "assets/textures",
				"assets/models", "assets/audio/sfx", "assets/audio/music",
				"assets/fonts", "assets/icons", "resources", "themes", "shaders",
				"addons", "tests",
			],
		},
	]
	return {"success": true, "templates": templates}


# ─── Helpers ────────────────────────────────────────────────────────────────────


func _generate_project_godot(project_name: String, renderer: String, godot_version: String = "") -> String:
	# Normalize renderer: use snake_case values that Godot accepts in project.godot
	# Valid values: "forward_plus", "mobile", "gl_compatibility"
	var renderer_setting: String = renderer
	if renderer == "" or renderer == "forward_plus":
		renderer_setting = "forward_plus"
	elif renderer == "mobile":
		renderer_setting = "mobile"
	elif renderer == "gl_compatibility":
		renderer_setting = "gl_compatibility"

	var version_line: String = ""
	if not godot_version.is_empty():
		version_line = "config/features=PackedStringArray(\"%s\")\n" % godot_version

	return """[gd_resource type="ProjectSettings" format=3]

config_version=5

[application]

config/name="%s"
run/main_scene=""
%s
[rendering]

renderer/rendering_method="%s"
""" % [project_name, version_line, renderer_setting]


func _get_template_folders(template: String) -> PackedStringArray:
	match template:
		"empty", "minimal":
			return PackedStringArray(["scenes", "scripts"])
		"standard":
			return PackedStringArray(["scenes", "scripts", "assets", "resources", "shaders", "tests"])
		"custom", "full":
			return PackedStringArray([
				"scenes", "scripts", "assets/sprites", "assets/textures",
				"assets/models", "assets/audio/sfx", "assets/audio/music",
				"assets/fonts", "assets/icons", "resources", "themes", "shaders",
				"addons", "tests",
			])
		"2d":
			return PackedStringArray([
				"scenes", "scripts", "assets/sprites", "assets/audio", "assets/fonts", "resources",
			])
		"3d":
			return PackedStringArray([
				"scenes", "scripts", "assets/models", "assets/textures", "assets/audio", "resources",
			])
		"ui":
			return PackedStringArray([
				"scenes", "scripts", "assets/fonts", "assets/icons", "themes", "resources",
			])
		_:
			return PackedStringArray(["scenes", "scripts", "assets", "resources"])


func _create_default_scene(project_path: String, scene_name: String, root_type: String) -> String:
	var scene_path: String = project_path.path_join("scenes/%s.tscn" % scene_name)
	var root_node: Node = null
	match root_type:
		"Node2D":
			root_node = Node2D.new()
		"Node3D":
			root_node = Node3D.new()
		"Control":
			root_node = Control.new()
		_:
			root_node = Node.new()
	root_node.name = scene_name.capitalize().replace(" ", "")

	var scene: PackedScene = PackedScene.new()
	scene.pack(root_node)
	root_node.queue_free()
	ResourceSaver.save(scene, scene_path)
	return "res://scenes/%s.tscn" % scene_name





func _count_files_recursive(path: String, counts: Dictionary, depth: int, max_depth: int) -> void:
	if depth >= max_depth:
		return
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var full_path: String = path.path_join(file_name)
		if dir.current_is_dir():
			_count_files_recursive(full_path, counts, depth + 1, max_depth)
		else:
			var ext: String = file_name.get_extension().to_lower()
			if ext.is_empty():
				ext = "(no ext)"
			counts[ext] = counts.get(ext, 0) + 1
		file_name = dir.get_next()
	dir.list_dir_end()


## Helper: Attempt to remove read-only attributes from a file/directory (Windows only).
func _make_writable(filepath: String) -> void:
	if OS.get_name() == "Windows":
		# attrib -r removes the read-only flag
		OS.execute("attrib", ["-r", filepath], [], false)

## Helper: Remove a directory and all its contents recursively.
## Uses cmd /c rmdir /s /q on Windows for reliable deletion of read-only files (e.g. .git/objects).
## Falls back to portable DirAccess approach on non-Windows or if rmdir fails.
func _remove_directory_recursive(path: String) -> Error:
	# On Windows, use rmdir /s /q which natively handles read-only files
	if OS.get_name() == "Windows":
		var output: Array = []
		# Use the path directly with backslashes for cmd.exe compatibility.
		# ProjectSettings.globalize_path() expects res:// paths; absolute paths
		# may be returned verbatim but with forward slashes that cmd.exe rmdir rejects.
		var win_path: String = path.replace("/", "\\")
		var exit_code: int = OS.execute(
			"cmd.exe",
			["/c", "rmdir", "/s", "/q", win_path],
			output,
			true
		)
		if exit_code == 0:
			return OK
		# rmdir may report non-zero on delete-while-use or encoding issues,
		# yet the directory may still be gone. Check before falling back.
		if not DirAccess.dir_exists_absolute(path):
			return OK

	# Portable fallback: DirAccess with read-only attribute removal
	return _remove_directory_recursive_portable(path)


func _remove_directory_recursive_portable(path: String) -> Error:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		_make_writable(path)
		dir = DirAccess.open(path)
		if dir == null:
			return ERR_CANT_OPEN

	var first_error: Error = OK
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path: String = path.path_join(entry)
			if dir.current_is_dir():
				var err: Error = _remove_directory_recursive_portable(full_path)
				if err != OK and first_error == OK:
					first_error = err
				err = DirAccess.remove_absolute(full_path)
				if err != OK and first_error == OK:
					first_error = err
			else:
				_make_writable(full_path)
				var err: Error = DirAccess.remove_absolute(full_path)
				if err != OK and first_error == OK:
					first_error = err
		entry = dir.get_next()
	dir.list_dir_end()

	_make_writable(path)
	var err: Error = DirAccess.remove_absolute(path)
	if err != OK and first_error == OK:
		first_error = err
	return first_error


func _generate_readme(project_name: String, template: String) -> String:
	match template:
		"detailed":
			return """# %s

## Description

A game built with the Godot Engine.

## Requirements

- Godot 4.x

## Installation

1. Clone this repository
2. Open the project in Godot 4.x
3. Run the main scene

## Project Structure

- `scenes/` - Game scenes
- `scripts/` - GDScript files
- `assets/` - Art, audio, and other assets
- `resources/` - Godot resources (.tres)

## Controls

| Action | Key |
|--------|-----|
| Move   | WASD |
| Jump   | Space |

## Credits

- Built with [Godot Engine](https://godotengine.org)

## License

See [LICENSE](LICENSE) for details.
""" % project_name
		"game":
			return """# %s

## About

A game made with Godot 4.x.

## How to Play

1. Download and install Godot 4.x
2. Clone or download this project
3. Open `project.godot` in Godot
4. Press F5 to play

## Features

- [Feature 1]
- [Feature 2]
- [Feature 3]

## Development

### Prerequisites

- Godot 4.x

### Setup

```bash
git clone <repository-url>
cd %s
# Open in Godot
```

## License

See [LICENSE](LICENSE).
""" % [project_name, project_name.to_lower().replace(" ", "-")]
		_:
			return """# %s

A Godot 4.x project.

## Getting Started

Open the project in Godot 4.x and press F5 to run.
""" % project_name


func _get_godot_gitignore() -> String:
	return """# Godot 4.x specific ignores

# Godot-specific
.godot/
*.translation

# Imported resources
.import/

# Build exports
export/
build/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
"""


func _get_mit_license() -> String:
	return """MIT License

Copyright (c) %d

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
""" % Time.get_datetime_dict_from_system()["year"]


func _get_apache_license() -> String:
	return """Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""


func _get_gpl3_license() -> String:
	return """GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007

Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
Everyone is permitted to copy and distribute verbatim copies
of this license document, but changing it is not allowed.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""


func _get_bsd3_license() -> String:
	return """BSD 3-Clause License

Copyright (c) %d

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
""" % Time.get_datetime_dict_from_system()["year"]


## Helper — Unescape JSON string escape sequences in user-provided content.
## When content is passed through a double-JSON-serialization layer
## (e.g., MCP client → JSON → IPC file → JSON.parse → GDScript),
## escape sequences like \n, \t, \r can arrive as literal backslash-character
## pairs instead of actual control characters. This helper converts them.
func _unescape_json_string(s: String) -> String:
	return s.replace("\\n", "\n").replace("\\t", "\t").replace("\\r", "\r").replace("\\\"", "\"").replace("\\\\", "\\")
