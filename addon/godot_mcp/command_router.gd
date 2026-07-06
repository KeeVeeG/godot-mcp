## Command router that dispatches incoming MCP tool calls to handler modules.
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

	var result: Variant = handler.call(params)

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
		# Handle {error: "string"} format (error without result)
		if dict.has("error") and not dict.has("result"):
			var err_val: Variant = dict["error"]
			if err_val is String:
				return {"error": {"code": -1, "message": err_val}}
			return {"error": err_val}
		# {result: ...} — pass through directly
		if dict.has("result"):
			return dict
		# Fallback: wrap entire dict under result
		return {"result": dict}
	elif result is String:
		return {"result": result}
	else:
		return {"result": result}


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
