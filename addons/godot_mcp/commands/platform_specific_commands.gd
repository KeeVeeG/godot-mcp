## Platform-specific commands module - 6 tools.
## Provides platform configuration for iOS, Android, and Web,
## platform capability queries, and platform build validation.
@tool
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
				"keystore": _read_keystore_settings(),
			}
		"web":
			current_settings = {
				"canvas_resize": ProjectSettings.get_setting("export/web/resize_canvas", defaults.get("canvas_resize", true)),
				"threading": ProjectSettings.get_setting("export/web/threads", defaults.get("threading", false)),
				"pwa": ProjectSettings.get_setting("export/web/progressive_web_app", defaults.get("pwa", false)),
				"renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method", defaults.get("renderer", "gl_compatibility")),
			}
		"windows":
			current_settings = {
				"architecture": ProjectSettings.get_setting("export/windows/architecture", defaults.get("architecture", "x86_64")),
				"console_wrapper": ProjectSettings.get_setting("export/windows/console_wrapper", defaults.get("console_wrapper", false)),
				"icon": ProjectSettings.get_setting("export/windows/icon", defaults.get("icon", "")),
			}
		"linux":
			current_settings = {
				"architecture": ProjectSettings.get_setting("export/linux/architecture", defaults.get("architecture", "x86_64")),
				"icon": ProjectSettings.get_setting("export/linux/icon", defaults.get("icon", "")),
			}
		"macos":
			current_settings = {
				"architecture": ProjectSettings.get_setting("export/macos/architecture", defaults.get("architecture", "universal")),
				"bundle_id": ProjectSettings.get_setting("application/config/bundle_identifier", defaults.get("bundle_id", "com.company.game")),
				"min_macos_version": ProjectSettings.get_setting("export/macos/min_macos_version", defaults.get("min_macos_version", "10.15")),
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
	var notes: Array = []

	if settings.has("bundle_id"):
		var bundle_id: String = settings["bundle_id"] as String
		if not _is_valid_bundle_id(bundle_id):
			return {"error": "Invalid bundle ID: '%s'. Bundle IDs must follow reverse-DNS format (e.g. 'com.company.app') with only letters, digits, hyphens, and dots." % bundle_id}
		ProjectSettings.set_setting("application/config/bundle_identifier", bundle_id)
		applied.append({"setting": "bundle_id", "value": bundle_id})

	if settings.has("team_id"):
		var team_id: String = settings["team_id"] as String
		if team_id.is_empty():
			notes.append("Empty team_id provided — this will cause signing failures in Xcode. Apple Team IDs are typically 10 alphanumeric characters.")
		ProjectSettings.set_setting("export/ios/team_id", team_id)
		applied.append({"setting": "team_id", "value": team_id})

	if settings.has("signing"):
		var signing: Dictionary = settings["signing"] as Dictionary
		if signing.is_empty():
			notes.append("Empty signing object provided — no signing configuration changes were made")
		else:
			var signing_keys: Array = []
			for key: String in signing:
				ProjectSettings.set_setting("export/ios/%s" % key, signing[key])
				signing_keys.append(key)
				applied.append({"setting": "signing/%s" % key, "value": signing[key]})
			# Track which sub-keys were written so get_platform_settings can discover them.
			# Replace existing sub-keys — clear any previously-set keys not in the new set.
			var signing_existing: Array = []
			if ProjectSettings.has_setting("export/ios/_sub_keys"):
				signing_existing = ProjectSettings.get_setting("export/ios/_sub_keys") as Array
			# Clear old sub-keys that are no longer in the new signing object
			for existing_key in signing_existing:
				if not signing_keys.has(existing_key):
					var old_key_path: String = "export/ios/%s" % existing_key
					ProjectSettings.clear(old_key_path)
			ProjectSettings.set_setting("export/ios/_sub_keys", signing_keys)

	ProjectSettings.save()

	return {"result": {
		"success": true,
		"platform": "ios",
		"applied_changes": applied,
		"change_count": applied.size(),
		"notes": notes,
		"message": "iOS configuration updated: %d setting(s) applied" % applied.size(),
	}}


## Configure Android settings.
func configure_android(params: Dictionary) -> Dictionary:
	var settings: Dictionary = params.get("settings", {})

	if settings.is_empty():
		return {"result": {"success": true, "platform": "android", "applied_changes": [], "change_count": 0, "message": "No settings to apply"}}

	var applied: Array = []
	var perm_warnings: Array = []
	var notes: Array = []

	if settings.has("package_name"):
		var package_name: String = settings["package_name"] as String
		if not _is_valid_package_name(package_name):
			return {"error": "Invalid package name: '%s'. Package names must follow reverse-DNS format (e.g. 'com.company.app') with only letters, digits, underscores, and dots." % package_name}
		ProjectSettings.set_setting("export/android/package_name", package_name)
		applied.append({"setting": "package_name", "value": package_name})

	if settings.has("keystore"):
		var keystore: Dictionary = settings["keystore"] as Dictionary
		if keystore.is_empty():
			notes.append("Empty keystore object provided — no keystore changes were made")
		else:
			var keystore_keys: Array = []
			for key: String in keystore:
				var key_value = keystore[key]
				# Warn about empty keystore values — they will cause export failures
				if key_value is String and key_value == "":
					if key == "path":
						notes.append("Empty keystore path provided — keystore file will not be found during export")
					elif key == "alias":
						notes.append("Empty keystore alias provided — key alias will not be found during signing")
					elif key in ["password", "alias_password"]:
						notes.append("Empty %s provided — signing will fail without a valid keystore password" % key)
				# Isolate keystore keys under export/android/keystore/ to prevent
				# collisions with top-level settings (package_name, permissions).
				ProjectSettings.set_setting("export/android/keystore/%s" % key, key_value)
				keystore_keys.append(key)
				var display_value = key_value
				if key == "password" or key == "alias_password":
					display_value = "[REDACTED]"
				applied.append({"setting": "keystore/%s" % key, "value": display_value})
			# Track which sub-keys were written so get_platform_settings can discover them.
			# Replace existing sub-keys — clear any previously-set keys not in the new set.
			var keystore_existing: Array = []
			if ProjectSettings.has_setting("export/android/keystore/_sub_keys"):
				keystore_existing = ProjectSettings.get_setting("export/android/keystore/_sub_keys") as Array
			# Clear old sub-keys that are no longer in the new keystore object
			for existing_key in keystore_existing:
				if not keystore_keys.has(existing_key):
					var old_key_path: String = "export/android/keystore/%s" % existing_key
					ProjectSettings.clear(old_key_path)
			ProjectSettings.set_setting("export/android/keystore/_sub_keys", keystore_keys)

	if settings.has("permissions"):
		var permissions: Array = settings["permissions"] as Array
		# Deduplicate permissions — duplicates can cause build issues
		var seen: Dictionary = {}
		var deduped: Array = []
		for perm in permissions:
			var perm_str: String = perm as String
			if seen.has(perm_str):
				continue
			seen[perm_str] = true
			deduped.append(perm_str)
			# Warn about permissions that don't follow standard Android format.
			# Valid formats: "android.permission.X" (system) or dotted namespace (e.g. "com.company.PERMISSION").
			# A proper dotted namespace must have ≥2 segments, each starting with a letter.
			var perm_regex := RegEx.new()
			perm_regex.compile("^[a-zA-Z][a-zA-Z0-9_]*(\\.[a-zA-Z][a-zA-Z0-9_]*)+$")
			if perm_regex.search(perm_str) == null:
				perm_warnings.append("Non-standard permission format: '%s'. Android permissions should use 'android.permission.PERMISSION_NAME' or a dotted custom namespace (e.g. 'com.company.PERMISSION')." % perm_str)
		if deduped.size() < permissions.size():
			notes.append("%d duplicate permission(s) removed" % (permissions.size() - deduped.size()))
		ProjectSettings.set_setting("export/android/permissions", deduped)
		applied.append({"setting": "permissions", "value": deduped})

	ProjectSettings.save()

	return {"result": {
		"success": true,
		"platform": "android",
		"applied_changes": applied,
		"change_count": applied.size(),
		"warnings": perm_warnings,
		"notes": notes,
		"message": "Android configuration updated: %d setting(s) applied" % applied.size(),
	}}


## Configure web platform settings.
func configure_web(params: Dictionary) -> Dictionary:
	var settings: Dictionary = params.get("settings", {})

	if settings.is_empty():
		return {"result": {"success": true, "platform": "web", "applied_changes": [], "change_count": 0, "message": "No settings to apply"}}

	var applied: Array = []
	var web_warnings: Array = []

	if settings.has("canvas_resize"):
		var canvas_resize: bool = settings["canvas_resize"] as bool
		ProjectSettings.set_setting("export/web/resize_canvas", canvas_resize)
		applied.append({"setting": "canvas_resize", "value": canvas_resize})

	if settings.has("threading"):
		var threading: bool = settings["threading"] as bool
		ProjectSettings.set_setting("export/web/threads", threading)
		applied.append({"setting": "threading", "value": threading})
		if threading:
			web_warnings.append("Threading requires COOP/COEP headers on your web server")

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
		"warnings": web_warnings,
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
			var min_sdk: int = ProjectSettings.get_setting("export/android/min_sdk", PLATFORM_DEFAULTS["android"]["min_sdk"])
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


## Helper: Read keystore settings from the new isolated prefix
## (export/android/keystore/), falling back to the old flat prefix
## (export/android/) for backward compatibility.
func _read_keystore_settings() -> Dictionary:
	const KNOWN_KEYS: Array = ["path", "password", "alias"]
	const SENSITIVE_KEYS: Array = ["password", "alias_password"]
	var prefix_new: String = "export/android/keystore"
	# Try the new isolated prefix first
	var result: Dictionary = _read_nested_settings(prefix_new, KNOWN_KEYS)
	# If no settings at new location, migrate from old flat format
	if result.is_empty():
		var old_result: Dictionary = _read_nested_settings("export/android", KNOWN_KEYS)
		if not old_result.is_empty():
			# Migrate old settings to new prefix to prevent future collisions
			for key: String in old_result:
				var full_key_new: String = "%s/%s" % [prefix_new, key]
				ProjectSettings.set_setting(full_key_new, old_result[key])
				# Clear old setting to avoid stale data
				var full_key_old: String = "export/android/%s" % key
				if ProjectSettings.has_setting(full_key_old):
					ProjectSettings.set_setting(full_key_old, null)
			var migrated_keys: Array = old_result.keys()
			ProjectSettings.set_setting("%s/_sub_keys" % prefix_new, migrated_keys)
			result = old_result
		else:
			return {}
	# Mask sensitive fields for security — passwords must not leak through tool output
	for key: String in SENSITIVE_KEYS:
		if result.has(key):
			result[key] = "[REDACTED]"
	return result


## Helper: Check if a platform has custom configuration.
## Compares current ProjectSettings against PLATFORM_DEFAULTS for all known settings.
func _has_platform_config(platform: String) -> bool:
	var defaults: Dictionary = PLATFORM_DEFAULTS.get(platform, {})
	if defaults.is_empty():
		return false

	match platform:
		"ios":
			var bundle_id: String = ProjectSettings.get_setting("application/config/bundle_identifier", defaults.get("bundle_id", ""))
			if bundle_id != defaults.get("bundle_id", ""):
				return true
			var team_id: String = ProjectSettings.get_setting("export/ios/team_id", defaults.get("team_id", ""))
			if team_id != defaults.get("team_id", ""):
				return true
			var signing_style: String = ProjectSettings.get_setting("export/ios/signing_style", defaults.get("signing_style", "automatic"))
			if signing_style != defaults.get("signing_style", "automatic"):
				return true
			var arch: String = ProjectSettings.get_setting("export/ios/architecture", defaults.get("architecture", "universal"))
			if arch != defaults.get("architecture", "universal"):
				return true
			# Check for any signing sub-keys
			var signing_keys: Array = ["identity", "provisioning_profile"]
			if ProjectSettings.has_setting("export/ios/_sub_keys"):
				signing_keys = ProjectSettings.get_setting("export/ios/_sub_keys") as Array
			for key: String in signing_keys:
				if ProjectSettings.has_setting("export/ios/%s" % key):
					return true
			return false

		"android":
			var package_name: String = ProjectSettings.get_setting("export/android/package_name", defaults.get("package_name", ""))
			if package_name != defaults.get("package_name", ""):
				return true
			var min_sdk: int = ProjectSettings.get_setting("export/android/min_sdk", defaults.get("min_sdk", 21))
			if min_sdk != defaults.get("min_sdk", 21):
				return true
			var target_sdk: int = ProjectSettings.get_setting("export/android/target_sdk", defaults.get("target_sdk", 34))
			if target_sdk != defaults.get("target_sdk", 34):
				return true
			var permissions: Array = ProjectSettings.get_setting("export/android/permissions", defaults.get("permissions", []))
			if str(permissions) != str(defaults.get("permissions", [])):
				return true
			# Check for any keystore sub-keys
			var keystore_keys: Array = ["path", "password", "alias"]
			if ProjectSettings.has_setting("export/android/keystore/_sub_keys"):
				keystore_keys = ProjectSettings.get_setting("export/android/keystore/_sub_keys") as Array
			for key: String in keystore_keys:
				if ProjectSettings.has_setting("export/android/keystore/%s" % key):
					return true
			return false

		"web":
			var web_defaults: Dictionary = defaults
			var actual_canvas: bool = ProjectSettings.get_setting("export/web/resize_canvas", web_defaults.get("canvas_resize", true))
			var actual_threading: bool = ProjectSettings.get_setting("export/web/threads", web_defaults.get("threading", false))
			var actual_pwa: bool = ProjectSettings.get_setting("export/web/progressive_web_app", web_defaults.get("pwa", false))
			var actual_renderer: String = ProjectSettings.get_setting("rendering/renderer/rendering_method", web_defaults.get("renderer", "gl_compatibility"))
			var default_canvas: bool = web_defaults.get("canvas_resize", true)
			var default_threading: bool = web_defaults.get("threading", false)
			var default_pwa: bool = web_defaults.get("pwa", false)
			var default_renderer: String = web_defaults.get("renderer", "gl_compatibility")
			return actual_canvas != default_canvas or actual_threading != default_threading or actual_pwa != default_pwa or actual_renderer != default_renderer

		"windows":
			var arch: String = ProjectSettings.get_setting("export/windows/architecture", defaults.get("architecture", "x86_64"))
			if arch != defaults.get("architecture", "x86_64"):
				return true
			var console_wrapper: bool = ProjectSettings.get_setting("export/windows/console_wrapper", defaults.get("console_wrapper", false))
			if console_wrapper != defaults.get("console_wrapper", false):
				return true
			var icon: String = ProjectSettings.get_setting("export/windows/icon", defaults.get("icon", ""))
			if icon != defaults.get("icon", ""):
				return true
			return false

		"linux":
			var arch: String = ProjectSettings.get_setting("export/linux/architecture", defaults.get("architecture", "x86_64"))
			if arch != defaults.get("architecture", "x86_64"):
				return true
			var icon: String = ProjectSettings.get_setting("export/linux/icon", defaults.get("icon", ""))
			if icon != defaults.get("icon", ""):
				return true
			return false

		"macos":
			var arch: String = ProjectSettings.get_setting("export/macos/architecture", defaults.get("architecture", "universal"))
			if arch != defaults.get("architecture", "universal"):
				return true
			var bundle_id: String = ProjectSettings.get_setting("application/config/bundle_identifier", defaults.get("bundle_id", ""))
			if bundle_id != defaults.get("bundle_id", ""):
				return true
			var min_macos: String = ProjectSettings.get_setting("export/macos/min_macos_version", defaults.get("min_macos_version", "10.15"))
			if min_macos != defaults.get("min_macos_version", "10.15"):
				return true
			return false

	return false


## Helper: Validate iOS bundle ID format (reverse-DNS).
func _is_valid_bundle_id(bundle_id: String) -> bool:
	if bundle_id.is_empty():
		return false
	var regex := RegEx.new()
	regex.compile("^[a-zA-Z][a-zA-Z0-9-]*(\\.[a-zA-Z][a-zA-Z0-9-]*)+$")
	return regex.search(bundle_id) != null


## Helper: Validate Android package name format (reverse-DNS).
## Same rules as iOS bundle IDs: must contain at least one dot,
## start with a letter, and use only letters, digits, underscores, and dots.
func _is_valid_package_name(package_name: String) -> bool:
	if package_name.is_empty():
		return false
	var regex := RegEx.new()
	regex.compile("^[a-zA-Z][a-zA-Z0-9_]*(\\.[a-zA-Z][a-zA-Z0-9_]*)+$")
	return regex.search(package_name) != null
