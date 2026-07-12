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

## Debugger plugin (EditorDebuggerPlugin — handles breakpoints, sessions, async capture)
var _mcp_debugger_plugin: MCPDebuggerPlugin

## Config
var _config: MCPConfig

## All command modules (for cleanup)
var _command_modules: Array[RefCounted] = []

## Failed module paths from last _register_all_commands() call
var _diagnostics_failed_modules: Array[String] = []
var _diagnostics_total_modules: int = 0
var _diagnostics_load_errors: Array[Dictionary] = []

## Whether runtime autoload has been injected
var _runtime_injected: bool = false

## Timer for auto-dismissing dialogs
var _dialog_timer: Timer

## Track game start/stop
var _game_running: bool = false

## D4 workaround: Godot 4's close_scene() does NOT clear
## get_edited_scene_root(), get_open_scenes(), scene_file_path,
## or is_inside_tree().  We track the logical "scene open" state
## ourselves so that save/load tools can reliably reject requests
## after a close_scene() call.
var _scene_open: bool = true


## Called by scene_commands when close_scene() succeeds.
func notify_scene_closed() -> void:
	_scene_open = false


## Called by scene_commands when a scene is opened or created.
func notify_scene_opened() -> void:
	_scene_open = true


## Returns true when a scene is logically open in the editor
## (opened/created but not yet closed via godot_close_scene).
func is_scene_logically_open() -> bool:
	return _scene_open


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

	# Register MCP Debugger Plugin for breakpoint/stack-eval support.
	# Must be created in _enter_tree() — EditorDebuggerPlugin auto-connects
	# to EditorDebuggerNode signals during construction.
	_mcp_debugger_plugin = MCPDebuggerPlugin.new()
	add_debugger_plugin(_mcp_debugger_plugin)
	# Wire it to the debugging commands module
	for mod: RefCounted in _command_modules:
		if mod is MCPDebuggingCommands:
			(mod as MCPDebuggingCommands).set_debugger_plugin(_mcp_debugger_plugin)
			break
	print("[MCP] Debugger plugin registered")

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

	# Remove debugger plugin
	if _mcp_debugger_plugin:
		remove_debugger_plugin(_mcp_debugger_plugin)
		_mcp_debugger_plugin = null

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


## Ensure the mcp_runtime autoload is registered via EditorPlugin API.
## Using add_autoload_singleton() properly updates the in-memory ProjectSettings
## AND persists to project.godot — avoiding the race condition where raw
## FileAccess writes are overwritten by the editor's in-memory state.
##
## CRITICAL: add_autoload_singleton() updates in-memory ProjectSettings but
## does NOT force a disk save.  The editor's run-flow (editor_run_bar.cpp)
## also does NOT call ProjectSettings.save() before launching the game process.
## Without an explicit save(), the autoload entry may not reach project.godot
## on disk before the game process reads it — causing the runtime to never
## instantiate.  We call ProjectSettings.save() explicitly to guarantee the
## entry is on disk before any game run can start.
func _ensure_runtime_autoload() -> void:
	var autoload_name: String = "MCPRuntime"
	var autoload_path: String = "res://addons/godot_mcp/services/mcp_runtime.gd"

	# Check if autoload already exists via ProjectSettings (in-memory state).
	# The key format is "autoload/NAME" with value "*res://path" (singleton).
	if ProjectSettings.has_setting("autoload/" + autoload_name):
		return  # Already registered

	# Verify the script file actually exists before registering.
	if not ResourceLoader.exists(autoload_path):
		push_error("[MCP] Cannot register runtime autoload — script not found: %s" % autoload_path)
		if _status_panel:
			_status_panel.log_activity("ERROR: Runtime autoload script not found: %s" % autoload_path, "error")
		return

	# Register via EditorPlugin API — this updates in-memory state.
	add_autoload_singleton(autoload_name, autoload_path)

	# Force persist to disk immediately.  The editor's run flow
	# (try_autosave → save_all_scenes → run) does NOT save project
	# settings.  Without this, the game process reads stale project.godot
	# that is missing the autoload entry.
	var save_err: Error = ProjectSettings.save()
	if save_err != OK:
		push_warning("[MCP] ProjectSettings.save() returned error %d after registering autoload" % save_err)

	print("[MCP] Registered runtime autoload MCPRuntime via add_autoload_singleton() (save: %s)" % error_string(save_err))
	if _status_panel:
		_status_panel.log_activity("Runtime autoload MCPRuntime registered", "info")


## Remove the mcp_runtime autoload on plugin unload.
func _remove_runtime_autoload() -> void:
	remove_autoload_singleton("MCPRuntime")
	print("[MCP] Removed runtime autoload MCPRuntime")


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
	var failed_modules: Array[String] = []
	for path: String in module_paths:
		# Use CACHE_MODE_REUSE to preserve UID-based class resolution (Godot 4.4+).
		# CACHE_MODE_IGNORE loads scripts with fresh UIDs, breaking class_name dependencies
		# between modules, causing can_instantiate() to return false for all scripts.
		var script: Script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE) as Script
		if script == null:
			push_error("[MCP] Failed to load module (file not found or not a script): %s — skipping" % path)
			failed_count += 1
			failed_modules.append(path.get_file())
			continue
		# Guard: a script with parse errors loads as broken GDScript (not null).
		# can_instantiate() returns false when compilation failed.
		if not script.can_instantiate():
			push_error("[MCP] Failed to load module (parse/compile error): %s — skipping. Check script for syntax errors." % path)
			failed_count += 1
			failed_modules.append(path.get_file())
			continue
		var module: RefCounted = script.new() as RefCounted
		if module == null:
			push_error("[MCP] Failed to instantiate module: %s — skipping. script.new() returned null." % path)
			failed_count += 1
			failed_modules.append(path.get_file())
			continue
		# Inject plugin reference
		if module.has_method("set_plugin"):
			module.set_plugin(self)
		_router.register_module(module)
		_command_modules.append(module)

	# Save diagnostics for the mcp/diagnostics bridge method
	_diagnostics_failed_modules = failed_modules
	_diagnostics_total_modules = module_paths.size()
	_diagnostics_load_errors.clear()
	for fm in failed_modules:
		_diagnostics_load_errors.append({"file": fm, "reason": "failed to load — check Godot Output panel for parse errors"})

	var handler_count: int = _router.get_registered_methods().size()
	if _command_modules.size() == 0:
		push_error("[MCP] CRITICAL: ALL %d command modules failed to load! No tools available. Check for GDScript errors above." % module_paths.size())
		if _status_panel:
			_status_panel.log_activity("CRITICAL: All %d modules failed to load! No tools registered." % module_paths.size(), "error")
	elif failed_count > 0:
		push_error("[MCP] %d/%d module(s) failed to load: %s" % [failed_count, module_paths.size(), ", ".join(failed_modules)])
		if _status_panel:
			_status_panel.log_activity("WARNING: %d/%d modules failed: %s" % [failed_count, module_paths.size(), ", ".join(failed_modules)], "warning")

	print("[MCP] Registered %d command modules with %d handlers covering %d tools" % [_command_modules.size(), handler_count, handler_count])
	if _status_panel:
		_status_panel.log_activity("Registered %d modules, %d tools" % [_command_modules.size(), handler_count], "info")


## Called when WebSocket connects to a server.
func _on_ws_connected(port: int) -> void:
	var project_path: String = _ws_client.get_connected_project_path()
	var url: String = "ws://localhost:%d" % port
	print("[MCP] Connected to %s (project: %s)" % [url, project_path])
	if _status_panel:
		_status_panel.update_connection(true, port, project_path)
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

	# Drain accumulated WebSocket frames BEFORE executing the handler.
	# Pings/pongs from the Node.js server accumulate during previous
	# synchronous operations (e.g., tilemap clear on large maps).
	# Processing them now resets the heartbeat timer before we potentially
	# block the main thread again.
	if _ws_client and _ws_client.is_server_connected():
		_ws_client.poll_deferred()

	# === Diagnostic bridge — bypasses router, always available ===
	# Responds to "mcp/diagnostics" even when zero command modules loaded.
	if method_name == "mcp/diagnostics":
		var diag: Dictionary = {
			"status": "ok" if _command_modules.size() > 0 else "critical",
			"modules_loaded": _command_modules.size(),
			"modules_total": _diagnostics_total_modules,
			"tools_registered": _router.get_registered_methods().size(),
			"failed_modules": _diagnostics_failed_modules,
			"load_errors": _diagnostics_load_errors,
			"ws_connected": _ws_client != null and _ws_client.is_server_connected(),
			"ws_port": _ws_client.get_connected_port() if _ws_client else -1,
			"plugin_loaded": true,
		}
		_ws_client.send_response(msg_id, diag)
		return
	# =============================================================

	# Route to handler (may be async for IPC-based runtime commands)
	var result: Dictionary = await _router.route_request(method_name, params)

	# Drain any queued WebSocket frames that accumulated during tool execution.
	# Prevents poll() starvation that can cause heartbeat timeout disconnects
	# when the main thread is blocked by synchronous operations (TileMap, UndoRedo, etc.).
	if _ws_client and _ws_client.is_server_connected():
		_ws_client.poll_deferred()

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

	# Send response back as proper JSON-RPC response (with id).
	# Detect error responses from command handlers and send them as proper
	# JSON-RPC errors so the Node.js bridge can reject the promise and
	# callGodot() can set isError: true on the MCP ToolResult.
	if _ws_client and _ws_client.is_server_connected():
		if result.has("error") and not result.has("result"):
			# Command handler returned a structured error (from router or directly)
			var err_data: Variant = result["error"]
			if err_data is Dictionary:
				_ws_client.send_response(msg_id, null, err_data)
			else:
				_ws_client.send_response(msg_id, null, {"code": -1, "message": str(err_data)})
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
	# Safety net: ensure runtime autoload is registered before the game starts.
	# If the project was created programmatically or the plugin's _enter_tree()
	# never ran, the autoload may be missing. This guarantees it exists for the
	# NEXT game session (the current session is already launching).
	_ensure_runtime_autoload()

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
