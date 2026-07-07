## Main EditorPlugin entry point for Godot MCP.
## Creates WebSocket client, command router, status panel,
## and auto-injects runtime autoloads when the game starts.
@tool
extends EditorPlugin

## WebSocket client node
var _ws_client: MCPWebSocketClient

## Command router
var _router: MCPCommandRouter

## Status panel
var _status_panel: MCPStatusPanel

## Undo helper
var _undo_helper: MCUndoHelper

## Config
var _config: MCPConfig

## All command modules (for cleanup)
var _command_modules: Array[RefCounted] = []

## Whether runtime autoload has been injected
var _runtime_injected: bool = false

## Timer for auto-dismissing dialogs
var _dialog_timer: Timer

## Track game start/stop
var _game_running: bool = false


func _enter_tree() -> void:
	print("[MCP] Godot MCP Plugin loading...")

	# Initialize config
	_config = MCPConfig.get_instance()

	# Create undo helper
	_undo_helper = MCUndoHelper.new(self)

	# Create command router
	_router = MCPCommandRouter.new()
	_router.undo_helper = _undo_helper
	_router.plugin = self

	# Register all command modules
	_register_all_commands()

	# Create WebSocket client (as a node so it gets _process)
	_ws_client = MCPWebSocketClient.new()
	_ws_client.name = "MCPWebSocketClient"
	add_child(_ws_client)

	# Connect signals
	_ws_client.connected.connect(_on_ws_connected)
	_ws_client.disconnected.connect(_on_ws_disconnected)
	_ws_client.message_received.connect(_on_ws_message)

	# Create status panel
	_status_panel = MCPStatusPanel.new()
	add_control_to_bottom_panel(_status_panel, "MCP")

	# Start scanning for server
	_status_panel.log_activity("Scanning for MCP server...", "info")
	_ws_client.call_deferred("scan_for_server")

	# Setup dialog auto-dismiss timer (only runs during gameplay)
	_dialog_timer = Timer.new()
	_dialog_timer.wait_time = 1.0
	_dialog_timer.timeout.connect(_check_and_dismiss_dialogs)
	add_child(_dialog_timer)
	# Timer starts in _on_game_started(), stops in _on_game_stopped()

	# Connect to scene changed signal for autoload injection
	# (Removed dead scene_changed handler — autoload injection handled in _ensure_runtime_autoload)

	# Register runtime autoload so it's available when game starts
	_ensure_runtime_autoload()

	print("[MCP] Plugin loaded. Scanning ports 6505-6514...")


func _exit_tree() -> void:
	print("[MCP] Godot MCP Plugin unloading...")

	# Stop timers
	if _dialog_timer:
		_dialog_timer.stop()
		_dialog_timer.queue_free()
		_dialog_timer = null

	# Disconnect WebSocket
	if _ws_client:
		_ws_client.disconnect_from_server()
		_ws_client.queue_free()
		_ws_client = null

	# Remove status panel
	if _status_panel:
		remove_control_from_bottom_panel(_status_panel)
		_status_panel.queue_free()
		_status_panel = null

	# Cleanup
	_command_modules.clear()
	_router = null
	_undo_helper = null
	_config = null

	# Reset static config singleton so it re-reads config on next plugin load
	MCPConfig._instance = null

	# Remove runtime autoload
	_remove_runtime_autoload()

	print("[MCP] Plugin unloaded.")


## Ensure the mcp_runtime autoload is registered in project.godot.
## Uses direct file I/O to avoid triggering ProjectSettings.save() reload.
func _ensure_runtime_autoload() -> void:
	var autoload_path: String = "res://addons/godot_mcp/services/mcp_runtime.gd"
	var autoload_entry: String = autoload_path
	var config_path: String = "res://project.godot"

	if not FileAccess.file_exists(config_path):
		push_warning("[MCP] project.godot not found, cannot register autoload")
		if _status_panel:
			_status_panel.log_activity("project.godot not found — cannot register autoload", "error")
		return

	# Check if already registered (autoloads are stored under numeric keys)
	var config := ConfigFile.new()
	var err: Error = config.load(config_path)
	if err != OK:
		push_warning("[MCP] Failed to load project.godot")
		if _status_panel:
			_status_panel.log_activity("Failed to load project.godot: %s" % error_string(err), "error")
		return

	# Scan existing autoload entries for mcp_runtime to avoid duplicates
	if config.has_section("autoload"):
		var existing_keys: PackedStringArray = config.get_section_keys("autoload")
		for key in existing_keys:
			var val: String = config.get_value("autoload", key, "")
			if val.ends_with("mcp_runtime.gd"):
				# Fix stale editor-only prefix or numeric key
				if key != "MCPRuntime" or val.begins_with("*"):
					config.erase_section_key("autoload", key)
					config.set_value("autoload", "MCPRuntime", autoload_entry)
					var fix_err: Error = config.save(config_path)
					if fix_err == OK:
						print("[MCP] Fixed autoload entry (key: %s → MCPRuntime)" % key)
				return  # Already registered

	# Add the autoload with a named key for predictable /root/MCPRuntime access
	config.set_value("autoload", "MCPRuntime", autoload_entry)
	var save_err: Error = config.save(config_path)
	if save_err != OK:
		push_warning("[MCP] Failed to save autoload to project.godot")
		if _status_panel:
			_status_panel.log_activity("Failed to save autoload to project.godot: %s" % error_string(save_err), "error")
		return
	print("[MCP] Registered runtime autoload MCPRuntime in project.godot")


## Remove the mcp_runtime autoload from project.godot on plugin unload.
func _remove_runtime_autoload() -> void:
	var config_path: String = "res://project.godot"
	if not FileAccess.file_exists(config_path):
		return

	var config := ConfigFile.new()
	var err: Error = config.load(config_path)
	if err != OK:
		return

	var autoload_path: String = "res://addons/godot_mcp/services/mcp_runtime.gd"

	# Find and remove the mcp_runtime entry — exact match only
	var keys: PackedStringArray = config.get_section_keys("autoload")
	for key: String in keys:
		var val: String = config.get_value("autoload", key, "")
		if val == autoload_path or val == "*" + autoload_path:
			config.erase_section_key("autoload", key)
			print("[MCP] Removed autoload entry '%s' from project.godot" % key)

	config.save(config_path)


## Register all command modules.
func _register_all_commands() -> void:
	var module_paths: PackedStringArray = [
		"res://addons/godot_mcp/commands/project_commands.gd",
		"res://addons/godot_mcp/commands/scene_commands.gd",
		"res://addons/godot_mcp/commands/node_commands.gd",
		"res://addons/godot_mcp/commands/script_commands.gd",
		"res://addons/godot_mcp/commands/editor_commands.gd",
		"res://addons/godot_mcp/commands/input_commands.gd",
		"res://addons/godot_mcp/commands/runtime_commands.gd",
		"res://addons/godot_mcp/commands/animation_commands.gd",
		"res://addons/godot_mcp/commands/tilemap_commands.gd",
		"res://addons/godot_mcp/commands/theme_commands.gd",
		"res://addons/godot_mcp/commands/shader_commands.gd",
		"res://addons/godot_mcp/commands/resource_commands.gd",
		"res://addons/godot_mcp/commands/physics_commands.gd",
		"res://addons/godot_mcp/commands/scene3d_commands.gd",
		"res://addons/godot_mcp/commands/particles_commands.gd",
		"res://addons/godot_mcp/commands/navigation_commands.gd",
		"res://addons/godot_mcp/commands/audio_commands.gd",
		"res://addons/godot_mcp/commands/batch_commands.gd",
		"res://addons/godot_mcp/commands/analysis_commands.gd",
		"res://addons/godot_mcp/commands/testing_commands.gd",
		"res://addons/godot_mcp/commands/profiling_commands.gd",
		"res://addons/godot_mcp/commands/export_commands.gd",
		# Extended modules (19)
		"res://addons/godot_mcp/commands/addon_management_commands.gd",
		"res://addons/godot_mcp/commands/audio_config_commands.gd",
		"res://addons/godot_mcp/commands/build_config_commands.gd",
		"res://addons/godot_mcp/commands/debug_config_commands.gd",
		"res://addons/godot_mcp/commands/debugging_commands.gd",
		"res://addons/godot_mcp/commands/editor_config_commands.gd",
		"res://addons/godot_mcp/commands/gameplay_automation_commands.gd",
		"res://addons/godot_mcp/commands/memory_profiling_commands.gd",
		"res://addons/godot_mcp/commands/node_config_commands.gd",
		"res://addons/godot_mcp/commands/physics_config_commands.gd",
		"res://addons/godot_mcp/commands/platform_export_commands.gd",
		"res://addons/godot_mcp/commands/platform_specific_commands.gd",
		"res://addons/godot_mcp/commands/project_config_commands.gd",
		"res://addons/godot_mcp/commands/project_creation_commands.gd",
		"res://addons/godot_mcp/commands/rendering_config_commands.gd",
		"res://addons/godot_mcp/commands/resource_config_commands.gd",
		"res://addons/godot_mcp/commands/save_load_commands.gd",
		"res://addons/godot_mcp/commands/scene_config_commands.gd",
		"res://addons/godot_mcp/commands/visual_testing_commands.gd",
	]

	var failed_count: int = 0
	for path: String in module_paths:
		var script: Script = load(path) as Script
		if script == null:
			push_warning("[MCP] Failed to load module: %s — skipping" % path)
			failed_count += 1
			continue
		var module: RefCounted = script.new() as RefCounted
		if module == null:
			push_warning("[MCP] Failed to instantiate module: %s — skipping" % path)
			failed_count += 1
			continue
		# Inject plugin reference
		if module.has_method("set_plugin"):
			module.set_plugin(self)
		_router.register_module(module)
		_command_modules.append(module)

	if failed_count > 0:
		push_warning("[MCP] %d module(s) failed to load" % failed_count)
	print("[MCP] Registered %d command modules with %d tools" % [_command_modules.size(), _router.get_registered_methods().size()])


## Called when WebSocket connects to a server.
func _on_ws_connected(port: int) -> void:
	var project_path: String = _ws_client.get_connected_project_path()
	var url: String = "ws://localhost:%d" % port
	print("[MCP] Connected to %s (project: %s)" % [url, project_path])
	if _status_panel:
		_status_panel.update_connection(true, port)
		_status_panel.log_activity("Connected: %s" % url, "success")
		if not project_path.is_empty():
			_status_panel.log_activity("Server project: %s" % project_path, "info")


## Called when WebSocket disconnects.
func _on_ws_disconnected() -> void:
	print("[MCP] Disconnected from server")
	if _status_panel:
		_status_panel.update_connection(false)
		_status_panel.log_activity("Disconnected from MCP server", "warning")


## Called when a JSON-RPC message is received.
func _on_ws_message(message: Dictionary) -> void:
	# Only handle requests (have "method" and "id")
	if not message.has("method"):
		return
	if not message.has("id"):
		return  # It's a notification from server, ignore for now

	var method_name: String = message["method"] as String
	var params: Dictionary = {}
	if message.has("params") and message["params"] is Dictionary:
		params = message["params"] as Dictionary
	var msg_id: Variant = message["id"]

	if _status_panel:
		_status_panel.log_activity("Tool: %s" % method_name, "info")

	# Route to handler (may be async for IPC-based runtime commands)
	var result: Dictionary = await _router.route_request(method_name, params)

	# Log result to status panel
	if result.has("error"):
		if _status_panel:
			var err_msg: String = "Unknown"
			if result["error"] is Dictionary:
				err_msg = result["error"].get("message", "Unknown")
			elif result["error"] is String:
				err_msg = result["error"]
			_status_panel.log_activity("Error in %s: %s" % [method_name, err_msg], "error")
	else:
		if _status_panel:
			_status_panel.log_activity("OK: %s" % method_name, "success")

	# Send response back as proper JSON-RPC response (with id)
	if _ws_client and _ws_client.is_server_connected():
		if result.has("error"):
			_ws_client.send_response(msg_id, null, result["error"])
		else:
			_ws_client.send_response(msg_id, result.get("result", result))


## Check for and auto-dismiss blocking dialogs.
func _check_and_dismiss_dialogs() -> void:
	if not _game_running:
		return
	# Get the editor base control and look for AcceptDialog/ConfirmationDialog
	var base: Control = get_editor_interface().get_base_control()
	_dismiss_dialogs_recursive(base)


## Recursively find and dismiss dialogs.
func _dismiss_dialogs_recursive(node: Node) -> void:
	if node is AcceptDialog:
		var dialog: AcceptDialog = node as AcceptDialog
		if dialog.visible:
			dialog.hide()
			print("[MCP] Auto-dismissed dialog: %s" % dialog.dialog_text)
	if node is ConfirmationDialog:
		var confirm: ConfirmationDialog = node as ConfirmationDialog
		if confirm.visible:
			confirm.hide()
			print("[MCP] Auto-dismissed confirmation dialog")
	if node is Popup:
		var popup: Popup = node as Popup
		if popup.visible and not (node is AcceptDialog or node is ConfirmationDialog):
			popup.hide()
			print("[MCP] Auto-dismissed popup: %s" % str(node.name))
	for child: Node in node.get_children():
		_dismiss_dialogs_recursive(child)


## Scene changed callback for autoload injection (removed — was dead code).
# func _on_scene_changed(scene_root: Node) -> void:
# 	pass


## Track game start/stop for dialog auto-dismiss.
## Safe filesystem scan that avoids reentrancy crashes.
## Use this instead of calling EditorFileSystem.scan() directly.
func safe_scan_filesystem() -> void:
	var fs: EditorFileSystem = get_editor_interface().get_resource_filesystem()
	if fs.is_scanning():
		return  # Already scanning, skip to avoid reentrancy crash
	fs.call_deferred("scan")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN:
			pass
		EditorPlugin.NOTIFICATION_WM_WINDOW_FOCUS_IN:
			pass


## Handle process frame to check for game running state.
func _process(_delta: float) -> void:
	var is_running: bool = get_editor_interface().is_playing_scene()
	if is_running and not _game_running:
		_game_running = true
		_on_game_started()
	elif not is_running and _game_running:
		_game_running = false
		_on_game_stopped()


## Called when game starts playing.
func _on_game_started() -> void:
	print("[MCP] Game started - runtime IPC active")
	_runtime_injected = true
	if _dialog_timer:
		_dialog_timer.start()
	if _status_panel:
		_status_panel.log_activity("Game started - runtime IPC active", "success")


## Called when game stops.
func _on_game_stopped() -> void:
	print("[MCP] Game stopped")
	_runtime_injected = false
	if _dialog_timer:
		_dialog_timer.stop()
	if _status_panel:
		_status_panel.log_activity("Game stopped", "info")


## Get the undo helper for command modules.
func get_undo_helper() -> MCUndoHelper:
	return _undo_helper


## Get the editor interface shortcut.
func get_editor_interface_ref() -> EditorInterface:
	return get_editor_interface()
