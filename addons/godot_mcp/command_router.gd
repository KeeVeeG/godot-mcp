## Command router that dispatches incoming MCP tool calls to handler modules.
@tool
class_name MCPCommandRouter
extends RefCounted

## Map of method_name -> Callable
var _handlers: Dictionary = {}

## Config reference
var _config: MCPConfig

## Undo helper reference (set by plugin)
var undo_helper: RefCounted

## Editor plugin reference (set by plugin)
var plugin: EditorPlugin


func _init() -> void:
	_config = MCPConfig.get_instance()


## Register a command handler.
func register_command(method_name: String, handler: Callable) -> void:
	_handlers[method_name] = handler


## Register all commands from a module object.
## The module should provide a get_commands() -> Dictionary method.
func register_module(module: RefCounted) -> void:
	if module.has_method("get_commands"):
		var commands: Dictionary = module.get_commands()
		for method_name: String in commands:
			var handler: Callable = commands[method_name] as Callable
			register_command(method_name, handler)


## Route an incoming request to the appropriate handler.
## Expects {result:}/{error:} format from command modules.
func route_request(method_name: String, params: Dictionary) -> Dictionary:
	if not _handlers.has(method_name):
		return {
			"error": {
				"code": -32601,
				"message": "Method not found: %s" % method_name,
			}
		}

	if not _config.is_tool_enabled(method_name):
		return {
			"error": {
				"code": -32600,
				"message": "Tool disabled: %s" % method_name,
			}
		}

	var handler: Callable = _handlers[method_name] as Callable

	# Guard: check that the handler callable is still valid (object not freed)
	if not handler.is_valid():
		return {
			"error": {
				"code": -32603,
				"message": "Handler for '%s' is no longer valid (object may have been freed)" % method_name,
			}
		}

	# Async handlers (IPC-based or use await internally) — must be awaited.
	# Sync handlers are called directly. Prefix-based dispatch avoids
	# Callable opcode issues in Godot 4 GDScript VM.
	# IMPORTANT: DO NOT use slash-based prefixes for flat-named methods.
	# The actual method names sent by the MCP server are the literal
	# GDScript handler names (e.g. "record_gameplay", not "gameplay/record").
	# Prefix-based dispatch matches by .begins_with(), so "record_gameplay"
	# begins_with("record_g") is checked; "wait_for_game_event" begins_with("wait_for").
	# Using incorrect prefixes causes handlers with `await` to be called
	# synchronously via handler.call() → GDScriptFunctionState serialized as {}.
	var _async_prefixes: PackedStringArray = [
		"runtime/",
		"simulate_gameplay_scenario",
		"record_gameplay",
		"replay_gameplay",
		"wait_for_game_event",
		"record_visual_regression",       # frame interval capture uses await
		"resource/get_preview",           # async preview generation via EditorResourcePreview
		"editor/get_game_screenshot",     # delegates to runtime via async file IPC
		"evaluate_expression",            # game-context path uses await for IPC
	]
	var is_async: bool = false
	for p in _async_prefixes:
		if method_name.begins_with(p):
			is_async = true
			break

	var result: Variant
	if is_async:
		result = await handler.call(params)
	else:
		# Wrap synchronous handler in try/catch to prevent unhandled exceptions
		# from crashing the WebSocket connection (BUG-001 root cause mitigation).
		# GDScript doesn't have try/catch, so we use a pre-call validation pattern.
		# If the handler itself crashes (e.g., due to file I/O errors, encoding issues),
		# the engine will print the error to the Output panel instead of killing the plugin.
		result = handler.call(params)

	# Guard: if handler returned null, it likely hit a runtime error
	if result == null:
		return {
			"error": {
				"code": -32603,
				"message": "Handler for '%s' returned null — possible runtime error in handler" % method_name,
			}
		}

	if result is Dictionary:
		var dict: Dictionary = result as Dictionary
		# Handle {error: "string"} format WITHOUT a success key (legacy handlers).
		# Normalize to new pattern {success: false, error: "msg"} so all errors
		# flow through the same pathway in the MCP server.
		if dict.has("error") and not dict.has("result"):
			if not dict.has("success"):
				var err_val: Variant = dict["error"]
				if err_val is String:
					return {"result": {"success": false, "error": err_val}}
				return {"result": {"success": false, "error": str(err_val)}}
		# {result: ...} — pass through directly (only when there is no "success" key).
		# When a handler returns {success: true, result: X}, the dict contains BOTH
		# "success" and "result" keys.  Passing it through as-is causes the
		# _on_ws_message response sender to extract the inner "result" value (X)
		# as the JSON-RPC result — stripping the success/result envelope.
		# Wrap such responses under {"result": dict} instead.
		if dict.has("result") and not dict.has("success"):
			return dict
		# Fallback: wrap entire dict under result
		return {"result": dict}
	elif result is String:
		return {"result": result}
	else:
		return {"result": result}


## Get count of registered handlers (for startup diagnostics).
func get_handler_count() -> int:
	return _handlers.size()


## Get list of all registered method names.
func get_registered_methods() -> Array[String]:
	var methods: Array[String] = []
	for m: String in _handlers:
		methods.append(m)
	return methods


## Get list of all registered method names as a PackedStringArray.
func get_registered_methods_packed() -> PackedStringArray:
	var methods: PackedStringArray = PackedStringArray()
	for m: String in _handlers:
		methods.append(m)
	return methods
