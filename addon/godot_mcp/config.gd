## Configuration class for Godot MCP plugin.
## Reads settings from godot_mcp_config.json if it exists,
## otherwise uses defaults.
class_name MCPConfig
extends RefCounted

## Port scanning range
const PORT_RANGE_START: int = 6505
const PORT_RANGE_END: int = 6514

## Reconnect settings
const RECONNECT_INTERVAL: float = 3.0
const PING_INTERVAL: float = 5.0
const REQUEST_TIMEOUT: float = 30.0
const IDLE_TIMEOUT: float = 60.0

## File IPC paths
const IPC_REQUEST_PATH: String = "user://mcp_request.json"
const IPC_RESPONSE_PATH: String = "user://mcp_response.json"
const IPC_RUNTIME_REQUEST_PATH: String = "user://mcp_runtime_request.json"
const IPC_RUNTIME_RESPONSE_PATH: String = "user://mcp_runtime_response.json"

## Tool enable/disable map (all enabled by default)
var enabled_tools: Dictionary = {}

## Current connected port (set at runtime)
var connected_port: int = -1

## Config file path
var config_path: String = "res://godot_mcp_config.json"

static var _instance: MCPConfig


static func get_instance() -> MCPConfig:
	if _instance == null:
		_instance = MCPConfig.new()
		_instance._load_config()
	return _instance


## Force a fresh config read. Call after _instance = null reset.
static func reload() -> MCPConfig:
	_instance = null
	return get_instance()


func _load_config() -> void:
	if not FileAccess.file_exists(config_path):
		return
	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		push_warning("[MCP] Could not open config file: " + config_path)
		return
	var json_text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_warning("[MCP] Failed to parse config JSON: " + json.get_error_message())
		return
	var data: Variant = json.data
	if data is Dictionary:
		var config_dict: Dictionary = data as Dictionary
		if config_dict.has("enabled_tools") and config_dict["enabled_tools"] is Dictionary:
			enabled_tools = config_dict["enabled_tools"] as Dictionary
		if config_dict.has("port_start") and config_dict["port_start"] is int:
			# Override port range start if configured
			pass


func is_tool_enabled(tool_name: String) -> bool:
	if enabled_tools.has(tool_name):
		return enabled_tools[tool_name] as bool
	return true


func get_port_range() -> Array[int]:
	var ports: Array[int] = []
	for port in range(PORT_RANGE_START, PORT_RANGE_END + 1):
		ports.append(port)
	return ports


func save_config() -> void:
	var data: Dictionary = {
		"enabled_tools": enabled_tools,
	}
	var json_text := JSON.stringify(data, "  ")
	var file := FileAccess.open(config_path, FileAccess.WRITE)
	if file == null:
		push_warning("[MCP] Could not write config file")
		return
	file.store_string(json_text)
	file.close()
