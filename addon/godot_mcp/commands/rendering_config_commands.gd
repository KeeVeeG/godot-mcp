## Rendering configuration commands module - 10 tools.
## Handles rendering settings, quality presets, viewport, and window config.
class_name MCPRenderingConfigCommands
extends RefCounted

var _plugin: EditorPlugin


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


## Router compatibility: returns callable map for MCPCommandRouter.
func get_commands() -> Dictionary:
	return {
		"rendering_config/get_settings": func(params: Dictionary) -> Dictionary: return execute("get_settings", params),
		"rendering_config/set_quality": func(params: Dictionary) -> Dictionary: return execute("set_quality", params),
		"rendering_config/set_renderer": func(params: Dictionary) -> Dictionary: return execute("set_renderer", params),
		"rendering_config/set_anti_aliasing": func(params: Dictionary) -> Dictionary: return execute("set_anti_aliasing", params),
		"rendering_config/set_shadow_quality": func(params: Dictionary) -> Dictionary: return execute("set_shadow_quality", params),
		"rendering_config/set_gi_quality": func(params: Dictionary) -> Dictionary: return execute("set_gi_quality", params),
		"rendering_config/set_post_processing": func(params: Dictionary) -> Dictionary: return execute("set_post_processing", params),
		"rendering_config/set_viewport_size": func(params: Dictionary) -> Dictionary: return execute("set_viewport_size", params),
		"rendering_config/set_window_settings": func(params: Dictionary) -> Dictionary: return execute("set_window_settings", params),
		"rendering_config/get_rendering_info": func(params: Dictionary) -> Dictionary: return execute("get_rendering_info", params),
	}


## Main dispatcher.
func execute(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_settings": return _get_settings()
		"set_quality": return _set_quality(params)
		"set_renderer": return _set_renderer(params)
		"set_anti_aliasing": return _set_anti_aliasing(params)
		"set_shadow_quality": return _set_shadow_quality(params)
		"set_gi_quality": return _set_gi_quality(params)
		"set_post_processing": return _set_post_processing(params)
		"set_viewport_size": return _set_viewport_size(params)
		"set_window_settings": return _set_window_settings(params)
		"get_rendering_info": return _get_rendering_info()
	return {"success": false, "error": "Unknown method: " + method}


## Get all current rendering settings.
func _get_settings() -> Dictionary:
	var settings: Dictionary = {
		"renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method", "forward_plus"),
		"viewport": {
			"width": ProjectSettings.get_setting("display/window/size/viewport_width", 1152),
			"height": ProjectSettings.get_setting("display/window/size/viewport_height", 648),
		},
		"anti_aliasing": {
			"msaa": ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d", 0),
			"fxaa": ProjectSettings.get_setting("rendering/anti_aliasing/quality/screen_space_aa", 0),
			"taa": ProjectSettings.get_setting("rendering/anti_aliasing/quality/use_taa", false),
		},
		"shadows": {
			"quality": ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size", 4096),
			"positional_shadow_size": ProjectSettings.get_setting("rendering/lights_and_shadows/positional_shadow/atlas_size", 2048),
		},
		"gi": {
			"mode": ProjectSettings.get_setting("rendering/global_illumination/gi/use_half_resolution", false),
		},
		"post_processing": "Bloom, SSAO, SSR, and volumetric fog are per-Environment resource settings, not project-level. Configure them on the Environment resource in your WorldEnvironment node.",
		"window": {
			"mode": ProjectSettings.get_setting("display/window/size/mode", 0),
			"vsync": ProjectSettings.get_setting("display/window/vsync/vsync_mode", 1),
		},
	}
	return {"success": true, "settings": settings}


## Apply a rendering quality preset.
func _set_quality(params: Dictionary) -> Dictionary:
	var quality: String = params.get("quality", "medium")
	var shadow_size: int = 2048
	var gi_half_res: bool = true
	var msaa: int = 0
	var fxaa: bool = false
	match quality:
		"low":
			shadow_size = 1024
			msaa = 0
			fxaa = false
		"medium":
			shadow_size = 2048
			msaa = 0
			fxaa = true
		"high":
			shadow_size = 4096
			msaa = 2
			fxaa = true
		"ultra":
			shadow_size = 8192
			msaa = 4
			fxaa = true
			gi_half_res = false
	ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size", shadow_size)
	ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/atlas_size", shadow_size)
	ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", msaa)
	ProjectSettings.set_setting("rendering/anti_aliasing/quality/screen_space_aa", 1 if fxaa else 0)
	ProjectSettings.set_setting("rendering/global_illumination/gi/use_half_resolution", gi_half_res)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "quality": quality, "message": "Rendering quality set to %s" % quality}


## Set the rendering method/renderer.
func _set_renderer(params: Dictionary) -> Dictionary:
	var renderer: String = params.get("renderer", "forward_plus")
	var valid_renderers: Array = ["forward_plus", "mobile", "gl_compatibility"]
	if not valid_renderers.has(renderer):
		return {"success": false, "error": "Invalid renderer: %s (use: %s)" % [renderer, ", ".join(valid_renderers)]}
	ProjectSettings.set_setting("rendering/renderer/rendering_method", renderer)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "renderer": renderer, "message": "Renderer set to %s" % renderer}


## Configure anti-aliasing settings.
func _set_anti_aliasing(params: Dictionary) -> Dictionary:
	var changed: Dictionary = {}
	if params.has("msaa"):
		var msaa_str: String = params["msaa"] as String
		var msaa_val: int = 0
		match msaa_str:
			"2x": msaa_val = 1
			"4x": msaa_val = 2
			"8x": msaa_val = 3
			_:
				return {"success": false, "error": "Invalid MSAA value: %s (use: 2x, 4x, 8x)" % msaa_str}
		ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", msaa_val)
		changed["msaa"] = msaa_str
	if params.has("fxaa"):
		var fxaa: bool = params["fxaa"] as bool
		ProjectSettings.set_setting("rendering/anti_aliasing/quality/screen_space_aa", 1 if fxaa else 0)
		changed["fxaa"] = fxaa
	if params.has("taa"):
		var taa: bool = params["taa"] as bool
		ProjectSettings.set_setting("rendering/anti_aliasing/quality/use_taa", taa)
		changed["taa"] = taa
	if changed.is_empty():
		return {"success": false, "error": "No anti-aliasing settings provided"}
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "changed": changed}


## Set shadow quality preset.
func _set_shadow_quality(params: Dictionary) -> Dictionary:
	var quality: String = params.get("quality", "medium")
	var dir_shadow: int = 2048
	var pos_shadow: int = 1024
	match quality:
		"low":
			dir_shadow = 1024
			pos_shadow = 512
		"medium":
			dir_shadow = 2048
			pos_shadow = 1024
		"high":
			dir_shadow = 4096
			pos_shadow = 2048
		"ultra":
			dir_shadow = 8192
			pos_shadow = 4096
	ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size", dir_shadow)
	ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/atlas_size", pos_shadow)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "quality": quality, "message": "Shadow quality set to %s" % quality}


## Set global illumination quality preset.
func _set_gi_quality(params: Dictionary) -> Dictionary:
	var quality: String = params.get("quality", "medium")
	var half_res: bool = true
	match quality:
		"low":
			half_res = true
		"medium":
			half_res = true
		"high":
			half_res = false
		"ultra":
			half_res = false
	ProjectSettings.set_setting("rendering/global_illumination/gi/use_half_resolution", half_res)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "quality": quality, "half_resolution": half_res}


## Enable/disable post-processing effects.
func _set_post_processing(params: Dictionary) -> Dictionary:
	return {"success": false, "error": "Bloom, SSAO, SSR, and volumetric fog are per-Environment resource settings, not project-level. Configure them on the Environment resource in your WorldEnvironment node."}


## Set viewport dimensions and stretch settings.
func _set_viewport_size(params: Dictionary) -> Dictionary:
	var width: int = params.get("width", 1152)
	var height: int = params.get("height", 648)
	if width <= 0 or height <= 0:
		return {"success": false, "error": "Viewport dimensions must be positive (got %dx%d)" % [width, height]}
	ProjectSettings.set_setting("display/window/size/viewport_width", width)
	ProjectSettings.set_setting("display/window/size/viewport_height", height)
	if params.has("stretch_mode"):
		ProjectSettings.set_setting("display/window/stretch/mode", params["stretch_mode"])
	if params.has("stretch_aspect"):
		ProjectSettings.set_setting("display/window/stretch/aspect", params["stretch_aspect"])
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "width": width, "height": height, "message": "Viewport size set"}


## Configure window size, mode, and vsync.
func _set_window_settings(params: Dictionary) -> Dictionary:
	var changed: Dictionary = {}
	if params.has("size"):
		var size: Array = params["size"] as Array
		if size.size() >= 2:
			ProjectSettings.set_setting("display/window/size/window_width_override", size[0])
			ProjectSettings.set_setting("display/window/size/window_height_override", size[1])
			changed["size"] = size
	if params.has("mode"):
		var mode: String = params["mode"] as String
		var mode_val: int = 0
		match mode:
			"windowed": mode_val = 0
			"fullscreen": mode_val = 3
			"exclusive_fullscreen": mode_val = 4
		ProjectSettings.set_setting("display/window/size/mode", mode_val)
		changed["mode"] = mode
	if params.has("vsync"):
		var vsync: bool = params["vsync"] as bool
		ProjectSettings.set_setting("display/window/vsync/vsync_mode", 1 if vsync else 0)
		changed["vsync"] = vsync
	if changed.is_empty():
		return {"success": false, "error": "No window settings provided"}
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"success": false, "error": "Failed to save: %s" % error_string(err)}
	return {"success": true, "changed": changed}


## Get GPU info and rendering statistics.
func _get_rendering_info() -> Dictionary:
	var info: Dictionary = {
		"renderer_name": RenderingServer.get_video_adapter_name(),
		"renderer_api": RenderingServer.get_video_adapter_api_version(),
		"vendor": RenderingServer.get_video_adapter_vendor(),
		"rendering_method": ProjectSettings.get_setting("rendering/renderer/rendering_method", "forward_plus"),
	}
	# NOTE: Godot exposes video_adapter_name/vendor/api_version but no separate CPU name API.
	# OS.get_processor_name() returns CPU, not GPU — omitted to avoid confusion.
	return {"success": true, "info": info}
