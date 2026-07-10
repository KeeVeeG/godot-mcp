## Platform-specific commands module - 6 tools.
## Provides platform configuration for iOS, Android, and Web,
## platform capability queries, and platform build validation.
class_name MCPPlatformSpecificCommands
extends RefCounted

var _plugin: EditorPlugin

## Platform-specific default settings
const PLATFORM_DEFAULTS: Dictionary = {
	"ios": {
		"bundle_id": "com.company.game",
		"team_id": "",
		"signing_style": "automatic",
		"architecture": "universal",
		"min_ios_version": "12.0",
	},
	"android": {
		"package_name": "com.company.game",
		"min_sdk": 21,
		"target_sdk": 34,
		"permissions": ["android.permission.INTERNET"],
	},
	"web": {
		"canvas_resize": true,
		"threading": false,
		"pwa": false,
		"renderer": "gl_compatibility",
		"html_icon": "",
	},
	"windows": {
		"architecture": "x86_64",
		"console_wrapper": false,
		"icon": "",
	},
	"linux": {
		"architecture": "x86_64",
		"icon": "",
	},
	"macos": {
		"architecture": "universal",
		"bundle_id": "com.company.game",
		"min_macos_version": "10.15",
	},
}

## Platform capabilities database
## NOTE: Settings under "export/..." (e.g. export/android/package_name,
## export/web/threads, export/ios/team_id) are export PRESET options,
## not standard ProjectSettings. ProjectSettings.get_setting() will return
## the default fallback for these keys unless they've been explicitly added
## to project.godot. These functions work correctly when the settings exist
## in project.godot, but won't read values from EditorExportPreset objects.
## A future improvement could use the EditorExportPreset API to read/write
## actual export preset configuration.
const PLATFORM_CAPABILITIES: Dictionary = {
	"ios": {
		"input": ["touch", "accelerometer", "gyroscope", "haptic_feedback", "gamecontroller"],
		"graphics": ["metal", "opengl_es3"],
		"audio": ["avAudioSession", "background_audio"],
		"network": ["wifi", "cellular", "bluetooth"],
		"features": ["in_app_purchase", "game_center", "push_notifications", "sign_in_with_apple", "ar_kit", "core_ml"],
		"storage": ["local", "icloud", "keychain"],
		"max_texture_size": 8192,
	},
	"android": {
		"input": ["touch", "accelerometer", "gyroscope", "gamecontroller", "keyboard", "mouse"],
		"graphics": ["vulkan", "opengl_es3"],
		"audio": ["audio_track", "opensl"],
		"network": ["wifi", "cellular", "bluetooth", "nfc"],
		"features": ["in_app_purchase", "play_games", "push_notifications", "google_sign_in", "ar_core", "admob"],
		"storage": ["local", "google_drive", "shared_preferences"],
		"max_texture_size": 8192,
	},
	"web": {
		"input": ["keyboard", "mouse", "touch", "gamepad"],
		"graphics": ["webgl2", "webgpu"],
		"audio": ["web_audio"],
		"network": ["http", "websocket", "webrtc"],
		"features": ["local_storage", "indexed_db", "fullscreen", "pointer_lock", "clipboard", "notifications"],
		"storage": ["local_storage", "indexed_db", "cookies"],
		"max_texture_size": 4096,
		"limitations": ["no_filesystem_access", "sandboxed", "no_native_threads"],
	},
	"windows": {
		"input": ["keyboard", "mouse", "gamecontroller", "xinput"],
		"graphics": ["vulkan", "opengl3", "direct3d12"],
		"audio": ["wasapi", "directsound"],
		"network": ["tcp", "udp", "websocket", "http"],
		"features": ["steam", "xbox_live", "file_system", "registry", "native_dialogs"],
		"storage": ["file_system", "registry"],
		"max_texture_size": 16384,
	},
	"linux": {
		"input": ["keyboard", "mouse", "gamecontroller"],
		"graphics": ["vulkan", "opengl3"],
		"audio": ["alsa", "pulseaudio", "pipewire"],
		"network": ["tcp", "udp", "websocket", "http"],
		"features": ["steam", "file_system", "native_dialogs"],
		"storage": ["file_system"],
		"max_texture_size": 16384,
	},
	"macos": {
		"input": ["keyboard", "mouse", "gamecontroller", "touchbar"],
		"graphics": ["metal", "vulkan", "opengl3"],
		"audio": ["core_audio"],
		"network": ["tcp", "udp", "websocket", "http"],
		"features": ["steam", "game_center", "file_system", "native_dialogs", "sign_in_with_apple"],
		"storage": ["file_system", "keychain"],
		"max_texture_size": 16384,
	},
}


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func get_commands() -> Dictionary:
	return {
		"get_platform_settings": get_platform_settings,
		"configure_ios": configure_ios,
		"configure_android": configure_android,
		"configure_web": configure_web,
		"get_platform_capabilities": get_platform_capabilities,
		"validate_platform_build": validate_platform_build,
	}


## Get platform-specific settings.
func get_platform_settings(params: Dictionary) -> Dictionary:
	var platform: String = params.get("platform", "").to_lower()

	if platform.is_empty():
		return {"error": "platform is required"}

	var defaults: Dictionary = PLATFORM_DEFAULTS.get(platform, {})
	if defaults.is_empty():
		return {"error": "Unknown platform: %s. Supported: %s" % [platform, ", ".join(PLATFORM_DEFAULTS.keys())]}

	# Read current project settings for this platform
	var current_settings: Dictionary = {}

	match platform:
		"ios":
			current_settings = {
				"bundle_id": ProjectSettings.get_setting("application/config/bundle_identifier", defaults.get("bundle_id", "")),
				"team_id": ProjectSettings.get_setting("export/ios/team_id", defaults.get("team_id", "")),
				"signing_style": ProjectSettings.get_setting("export/ios/signing_style", defaults.get("signing_style", "automatic")),
				"architecture": ProjectSettings.get_setting("export/ios/architecture", defaults.get("architecture", "universal")),
				"min_ios_version": defaults.get("min_ios_version", "12.0"),
				"signing": _read_nested_settings("export/ios", ["identity", "provisioning_profile"]),
			}
		"android":
			current_settings = {
				"package_name": ProjectSettings.get_setting("export/android/package_name", defaults.get("package_name", "")),
				"min_sdk": ProjectSettings.get_setting("export/android/min_sdk", defaults.get("min_sdk", 21)),
				"target_sdk": ProjectSettings.get_setting("export/android/target_sdk", defaults.get("target_sdk", 34)),
				"permissions": ProjectSettings.get_setting("export/android/permissions", defaults.get("permissions", [])),
				"keystore": _read_nested_settings("export/android", ["path", "password", "alias"]),
			}
		"web":
			current_settings = {
				"canvas_resize": ProjectSettings.get_setting("export/web/resize_canvas", defaults.get("canvas_resize", true)),
				"threading": ProjectSettings.get_setting("export/web/threads", defaults.get("threading", false)),
				"pwa": ProjectSettings.get_setting("export/web/progressive_web_app", defaults.get("pwa", false)),
				"renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method", defaults.get("renderer", "gl_compatibility")),
			}
		_:
			current_settings = defaults

	return {"result": {
		"platform": platform,
		"settings": current_settings,
		"defaults": defaults,
		"has_custom_config": _has_platform_config(platform),
	}}


## Configure iOS settings.
func configure_ios(params: Dictionary) -> Dictionary:
	var settings: Dictionary = params.get("settings", {})

	if settings.is_empty():
		return {"result": {"success": true, "platform": "ios", "applied_changes": [], "change_count": 0, "message": "No settings to apply"}}

	var applied: Array = []

	if settings.has("bundle_id"):
		var bundle_id: String = settings["bundle_id"] as String
		if not _is_valid_bundle_id(bundle_id):
			return {"error": "Invalid bundle ID: '%s'. Bundle IDs must follow reverse-DNS format (e.g. 'com.company.app') with only letters, digits, hyphens, and dots." % bundle_id}
		ProjectSettings.set_setting("application/config/bundle_identifier", bundle_id)
		applied.append({"setting": "bundle_id", "value": bundle_id})

	if settings.has("team_id"):
		var team_id: String = settings["team_id"] as String
		ProjectSettings.set_setting("export/ios/team_id", team_id)
		applied.append({"setting": "team_id", "value": team_id})

	if settings.has("signing"):
		var signing: Dictionary = settings["signing"] as Dictionary
		var signing_keys: Array = []
		for key: String in signing:
			ProjectSettings.set_setting("export/ios/%s" % key, signing[key])
			signing_keys.append(key)
			applied.append({"setting": "signing/%s" % key, "value": signing[key]})
		# Track which sub-keys were written so get_platform_settings can discover them
		ProjectSettings.set_setting("export/ios/_sub_keys", signing_keys)

	ProjectSettings.save()

	return {"result": {
		"success": true,
		"platform": "ios",
		"applied_changes": applied,
		"change_count": applied.size(),
		"message": "iOS configuration updated: %d setting(s) applied" % applied.size(),
	}}


## Configure Android settings.
func configure_android(params: Dictionary) -> Dictionary:
	var settings: Dictionary = params.get("settings", {})

	if settings.is_empty():
		return {"result": {"success": true, "platform": "android", "applied_changes": [], "change_count": 0, "message": "No settings to apply"}}

	var applied: Array = []

	if settings.has("package_name"):
		var package_name: String = settings["package_name"] as String
		ProjectSettings.set_setting("export/android/package_name", package_name)
		applied.append({"setting": "package_name", "value": package_name})

	if settings.has("keystore"):
		var keystore: Dictionary = settings["keystore"] as Dictionary
		var keystore_keys: Array = []
		for key: String in keystore:
			ProjectSettings.set_setting("export/android/%s" % key, keystore[key])
			keystore_keys.append(key)
			applied.append({"setting": "keystore/%s" % key, "value": keystore[key]})
		# Track which sub-keys were written so get_platform_settings can discover them
		ProjectSettings.set_setting("export/android/_sub_keys", keystore_keys)

	if settings.has("permissions"):
		var permissions: Array = settings["permissions"] as Array
		var warnings: Array = []
		for perm in permissions:
			var perm_str: String = perm as String
			# Warn about permissions that don't follow standard Android format
			if not "." in perm_str:
				warnings.append(perm_str)
		if not warnings.is_empty():
			applied.append({"setting": "warnings", "value": "Non-standard permission format detected: %s. Android permissions typically use 'android.permission.PERMISSION_NAME' or dotted custom format." % ", ".join(warnings)})
		ProjectSettings.set_setting("export/android/permissions", permissions)
		applied.append({"setting": "permissions", "value": permissions})

	ProjectSettings.save()

	return {"result": {
		"success": true,
		"platform": "android",
		"applied_changes": applied,
		"change_count": applied.size(),
		"message": "Android configuration updated: %d setting(s) applied" % applied.size(),
	}}


## Configure web platform settings.
func configure_web(params: Dictionary) -> Dictionary:
	var settings: Dictionary = params.get("settings", {})

	if settings.is_empty():
		return {"result": {"success": true, "platform": "web", "applied_changes": [], "change_count": 0, "message": "No settings to apply"}}

	var applied: Array = []

	if settings.has("canvas_resize"):
		var canvas_resize: bool = settings["canvas_resize"] as bool
		ProjectSettings.set_setting("export/web/resize_canvas", canvas_resize)
		applied.append({"setting": "canvas_resize", "value": canvas_resize})

	if settings.has("threading"):
		var threading: bool = settings["threading"] as bool
		ProjectSettings.set_setting("export/web/threads", threading)
		applied.append({"setting": "threading", "value": threading})
		if threading:
			applied.append({"setting": "note", "value": "Threading requires COOP/COEP headers on your web server"})

	if settings.has("pwa"):
		var pwa: bool = settings["pwa"] as bool
		ProjectSettings.set_setting("export/web/progressive_web_app", pwa)
		applied.append({"setting": "pwa", "value": pwa})

	ProjectSettings.save()

	return {"result": {
		"success": true,
		"platform": "web",
		"applied_changes": applied,
		"change_count": applied.size(),
		"message": "Web configuration updated: %d setting(s) applied" % applied.size(),
	}}


## Get platform capabilities.
func get_platform_capabilities(params: Dictionary) -> Dictionary:
	var platform: String = params.get("platform", "").to_lower()

	if platform.is_empty():
		return {"error": "platform is required"}

	var capabilities: Dictionary = PLATFORM_CAPABILITIES.get(platform, {})
	if capabilities.is_empty():
		return {"error": "Unknown platform: %s. Supported: %s" % [platform, ", ".join(PLATFORM_CAPABILITIES.keys())]}

	# Count total capabilities
	var total_features: int = 0
	for key: String in capabilities:
		if capabilities[key] is Array:
			total_features += capabilities[key].size()

	return {"result": {
		"platform": platform,
		"capabilities": capabilities,
		"total_features": total_features,
		"has_limitations": capabilities.has("limitations"),
		"limitations": capabilities.get("limitations", []),
		"max_texture_size": capabilities.get("max_texture_size", 4096),
	}}


## Validate the project for a platform build.
func validate_platform_build(params: Dictionary) -> Dictionary:
	var platform: String = params.get("platform", "").to_lower().strip_edges()

	if platform.is_empty():
		return {"error": "platform is required"}

	if not PLATFORM_DEFAULTS.has(platform):
		return {"error": "Unknown platform: %s. Supported: %s" % [platform, ", ".join(PLATFORM_DEFAULTS.keys())]}

	var issues: Array = []
	var warnings: Array = []

	# Common checks
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene.is_empty():
		issues.append({"severity": "error", "type": "no_main_scene", "message": "No main scene configured"})

	# Platform-specific checks
	match platform:
		"ios":
			# Check bundle ID
			var bundle_id: String = ProjectSettings.get_setting("application/config/bundle_identifier", "")
			if bundle_id.is_empty() or bundle_id == "com.company.game":
				issues.append({"severity": "error", "type": "default_bundle_id", "message": "Bundle ID is still the default - configure a unique identifier"})

			# Check for iOS-incompatible features
			var renderer: String = ProjectSettings.get_setting("rendering/renderer/rendering_method", "")
			if renderer == "gl_compatibility":
				warnings.append({"severity": "warning", "type": "renderer", "message": "gl_compatibility renderer has limited features on iOS - consider using 'mobile'"})

		"android":
			# Check package name
			var package_name: String = ProjectSettings.get_setting("export/android/package_name", "")
			if package_name.is_empty() or package_name == "com.company.game":
				issues.append({"severity": "error", "type": "default_package", "message": "Package name is still the default - configure a unique identifier"})

			# Check SDK versions
			var min_sdk: int = ProjectSettings.get_setting("export/android/min_sdk", 0)
			if min_sdk < 21:
				warnings.append({"severity": "warning", "type": "low_min_sdk", "message": "min_sdk below 21 may limit device compatibility"})

		"web":
			# Check renderer compatibility
			var renderer: String = ProjectSettings.get_setting("rendering/renderer/rendering_method", "")
			if renderer != "gl_compatibility":
				issues.append({"severity": "error", "type": "renderer", "message": "Web export requires gl_compatibility renderer (current: %s)" % renderer})

			# Check for threading
			var threading: bool = ProjectSettings.get_setting("export/web/threads", false)
			if threading:
				warnings.append({"severity": "warning", "type": "threading", "message": "Threading requires COOP/COEP headers - ensure your web server is configured"})

		"windows", "linux", "macos":
			# Check for export templates
			var templates_dir: String = OS.get_user_data_dir().path_join("export_templates")
			var version_str: String = Engine.get_version_info()["string"]
			if not DirAccess.dir_exists_absolute(templates_dir.path_join(version_str)):
				warnings.append({"severity": "warning", "type": "no_templates", "message": "Export templates for Godot %s may not be installed" % version_str})

	# Check for missing script dependencies
	var script_files: Array = []
	MCPCommandHelpers.walk_directory("res://", PackedStringArray(["gd"]), func(path, _name): script_files.append(path))
	var script_errors: int = 0
	for script_path: String in script_files:
		var script: GDScript = load(script_path) as GDScript
		if script == null:
			script_errors += 1
			issues.append({
				"severity": "error",
				"type": "script_error",
				"path": script_path,
				"message": "Script has compilation errors",
			})

	var error_count: int = issues.filter(func(i: Dictionary) -> bool: return i["severity"] == "error").size()
	var warning_count: int = warnings.size()

	return {"result": {
		"platform": platform,
		"valid": error_count == 0,
		"errors": issues,
		"error_count": error_count,
		"warnings": warnings,
		"warning_count": warning_count,
		"scripts_checked": script_files.size(),
		"scripts_with_errors": script_errors,
		"message": "Platform validation for %s: %d error(s), %d warning(s)" % [platform, error_count, warning_count] if error_count + warning_count > 0 else "Platform validation passed for %s" % platform,
	}}


## Helper: Read nested settings from ProjectSettings with a common prefix.
## Reads from known_keys (always checked) plus any dynamically-added keys
## tracked via the prefix/_sub_keys meta-key (set by configure_ios/configure_android).
## Returns all values, including empty strings (explicitly-set empty values are preserved).
func _read_nested_settings(prefix: String, known_keys: Array) -> Dictionary:
	var result: Dictionary = {}
	# Start with statically-known keys (backward compatible)
	var all_keys: Array = known_keys.duplicate()
	
	# Also discover dynamically-added sub-keys from the meta-key
	var meta_key: String = "%s/_sub_keys" % prefix
	if ProjectSettings.has_setting(meta_key):
		var saved_keys: Array = ProjectSettings.get_setting(meta_key) as Array
		for k in saved_keys:
			if not all_keys.has(k):
				all_keys.append(k)
	
	for key: String in all_keys:
		var full_key: String = "%s/%s" % [prefix, key]
		if ProjectSettings.has_setting(full_key):
			result[key] = ProjectSettings.get_setting(full_key)
	return result


## Helper: Check if a platform has custom configuration.
func _has_platform_config(platform: String) -> bool:
	match platform:
		"ios":
			var bundle_id: String = ProjectSettings.get_setting("application/config/bundle_identifier", "")
			return not bundle_id.is_empty() and bundle_id != "com.company.game"
		"android":
			var package_name: String = ProjectSettings.get_setting("export/android/package_name", "")
			return not package_name.is_empty() and package_name != "com.company.game"
		"web":
			return ProjectSettings.get_setting("export/web/resize_canvas", false) or \
				   ProjectSettings.get_setting("export/web/threads", false) or \
				   ProjectSettings.get_setting("export/web/progressive_web_app", false)
	return false


## Helper: Validate iOS bundle ID format (reverse-DNS).
func _is_valid_bundle_id(bundle_id: String) -> bool:
	if bundle_id.is_empty():
		return false
	var regex := RegEx.new()
	regex.compile("^[a-zA-Z][a-zA-Z0-9-]*(\\.[a-zA-Z][a-zA-Z0-9-]*)+$")
	return regex.search(bundle_id) != null
