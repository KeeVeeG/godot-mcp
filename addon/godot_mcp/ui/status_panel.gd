## Status panel for the Godot MCP plugin.
## Shows connection status, port, and an activity log.
class_name MCPStatusPanel
extends PanelContainer

## Status label showing connection state
var _status_label: Label

## Port label showing connected port
var _port_label: Label

## Activity log
var _log_text: RichTextLabel

## Maximum log entries
const MAX_LOG_ENTRIES: int = 200


func _init() -> void:
	_setup_ui()
	custom_minimum_size = Vector2(200, 300)
	name = "MCP Status"


func _setup_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Godot MCP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	# Connection status
	var status_hbox := HBoxContainer.new()
	vbox.add_child(status_hbox)

	var status_icon := Label.new()
	status_icon.name = "StatusIcon"
	status_icon.text = "●"
	status_icon.add_theme_color_override("font_color", Color.RED)
	status_hbox.add_child(status_icon)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.text = "Disconnected"
	status_hbox.add_child(_status_label)

	# Port info
	_port_label = Label.new()
	_port_label.name = "PortLabel"
	_port_label.text = "Port: -"
	vbox.add_child(_port_label)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Activity log title
	var log_title := Label.new()
	log_title.text = "Activity Log"
	vbox.add_child(log_title)

	# Log text area
	_log_text = RichTextLabel.new()
	_log_text.name = "LogText"
	_log_text.bbcode_enabled = true
	_log_text.scroll_following = true
	_log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_log_text)


## Update connection status display.
func update_connection(connected: bool, port: int = -1) -> void:
	var status_icon: Label = find_child("StatusIcon", true, false) as Label
	if status_icon:
		if connected:
			status_icon.add_theme_color_override("font_color", Color.GREEN)
		else:
			status_icon.add_theme_color_override("font_color", Color.RED)

	if _status_label:
		if connected:
			_status_label.text = "Connected"
		else:
			_status_label.text = "Disconnected"

	if _port_label:
		if connected and port > 0:
			_port_label.text = "Port: %d" % port
		else:
			_port_label.text = "Port: -"


## Add a log entry.
func log_activity(message: String, level: String = "info") -> void:
	if _log_text == null:
		return
	var timestamp: String = Time.get_time_string_from_system()
	var color: String = "white"
	match level:
		"error":
			color = "red"
		"warning":
			color = "yellow"
		"success":
			color = "green"
		"info":
			color = "white"

	var line: String = "[color=%s][%s] %s[/color]" % [color, timestamp, message]
	_log_text.append_text(line + "\n")

	# Trim old entries if too many
	var text_content: String = _log_text.get_parsed_text()
	var lines: PackedStringArray = text_content.split("\n")
	if lines.size() > MAX_LOG_ENTRIES:
		# Rebuild with last entries
		_log_text.clear()
		var start_idx: int = lines.size() - MAX_LOG_ENTRIES
		for i: int in range(start_idx, lines.size()):
			if lines[i].strip_edges() != "":
				_log_text.append_text(lines[i] + "\n")


## Clear the log.
func clear_log() -> void:
	if _log_text:
		_log_text.clear()
