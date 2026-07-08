## Project creation commands module - 10 tools.
## Handles project scaffolding, templates, git init, licensing, and dependency setup.
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

	# Create project directory
	var err: Error = DirAccess.make_dir_recursive_absolute(path)
	if err != OK:
		return {"success": false, "error": "Failed to create directory: %s" % error_string(err)}

	# Create project.godot
	var config_content: String = _generate_project_godot(name, renderer, godot_version)
	var config_path: String = path.path_join("project.godot")
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

	return {
		"success": true,
		"path": path,
		"name": name,
		"template": template,
		"renderer": renderer,
		"folders_created": folders,
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

	# Copy template to new location
	var err: Error = MCPCommandHelpers.copy_directory_recursive(template_path, path)
	if err != OK:
		return {"success": false, "error": "Failed to copy template: %s" % error_string(err)}

	# Update project name if provided
	if not name.is_empty():
		var config_path: String = path.path_join("project.godot")
		if FileAccess.file_exists(config_path):
			var file: FileAccess = FileAccess.open(config_path, FileAccess.READ)
			if file:
				var content: String = file.get_as_text()
				file.close()
				content = content.replace('"application/config/name": _PLACEHOLDER_', '"application/config/name": "%s"' % name)
				var write_file: FileAccess = FileAccess.open(config_path, FileAccess.WRITE)
				if write_file:
					write_file.store_string(content)
					write_file.close()

	return {"success": true, "path": path, "template": template_path, "name": name}


## Create standard folder structure in an existing project.
func _scaffold_project_structure(params: Dictionary) -> Dictionary:
	var project_path: String = params.get("project_path", "")
	var structure: String = params.get("structure", "standard")

	if project_path.is_empty():
		return {"success": false, "error": "Project path is required"}

	if not MCPCommandHelpers.validate_path(project_path):
		return {"success": false, "error": "Invalid path"}

	if not FileAccess.file_exists(project_path.path_join("project.godot")):
		return {"success": false, "error": "Not a valid Godot project (missing project.godot)"}

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

	return {
		"success": true,
		"path": path,
		"name": name,
		"imported": imported,
		"errors": errors,
	}


## Initialize a git repository with optional .gitignore.
func _initialize_git_repository(params: Dictionary) -> Dictionary:
	var project_path: String = params.get("project_path", "")
	var include_gitignore: bool = params.get("include_gitignore", true)

	if project_path.is_empty():
		return {"success": false, "error": "Project path is required"}

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

	if content.is_empty():
		content = _generate_readme(project_name, template)

	var readme_path: String = project_path.path_join("README.md")
	var file: FileAccess = FileAccess.open(readme_path, FileAccess.WRITE)
	if file == null:
		return {"success": false, "error": "Failed to create README.md"}
	file.store_string(content)
	file.close()

	return {"success": true, "path": readme_path, "template": template}


## Create a LICENSE file.
func _create_project_license(params: Dictionary) -> Dictionary:
	var project_path: String = params.get("project_path", "")
	var license_type: String = params.get("license", "MIT")
	var custom_text: String = params.get("custom_text", "")

	if project_path.is_empty():
		return {"success": false, "error": "Project path is required"}

	var license_text: String = ""
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
			license_text = custom_text
		_:
			return {"success": false, "error": "Unknown license type: %s" % license_type}

	var license_path: String = project_path.path_join("LICENSE")
	var file: FileAccess = FileAccess.open(license_path, FileAccess.WRITE)
	if file == null:
		return {"success": false, "error": "Failed to create LICENSE file"}
	file.store_string(license_text)
	file.close()

	return {"success": true, "path": license_path, "license": license_type}


## Setup project dependencies / addons.
func _setup_project_dependencies(params: Dictionary) -> Dictionary:
	var project_path: String = params.get("project_path", "")
	var addons: Array = params.get("addons", [])

	if project_path.is_empty():
		return {"success": false, "error": "Project path is required"}

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
				# Return instruction for manual git clone
				installed.append({"name": addon_name, "instruction": "Run: git clone '%s' '%s'" % [url, dest_path]})
			"asset_lib":
				installed.append({"name": addon_name, "instruction": "Install from Godot Asset Library: %s" % addon_name})
			_:
				errors.append("Unknown addon source: %s" % source)

	return {"success": true, "installed": installed, "errors": errors}


## Validate a project's folder structure.
func _validate_project_structure(params: Dictionary) -> Dictionary:
	var project_path: String = params.get("project_path", "")

	if project_path.is_empty():
		return {"success": false, "error": "Project path is required"}

	var config_path: String = project_path.path_join("project.godot")
	if not FileAccess.file_exists(config_path):
		return {"success": false, "error": "Not a valid Godot project (missing project.godot)"}

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
		"scenes", "scripts", "assets", "resources"
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
	var renderer_setting: String = "Forward Plus"
	match renderer:
		"mobile":
			renderer_setting = "Mobile"
		"gl_compatibility":
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
		"empty":
			return PackedStringArray(["scenes", "scripts"])
		"custom":
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
