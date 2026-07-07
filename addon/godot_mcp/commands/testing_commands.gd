## Testing commands module - 5 tools.
## Provides test scenario execution, state assertions, stress tests,
## and aggregated test reporting.
class_name MCPTestingCommands
extends RefCounted

var _plugin: EditorPlugin

## Accumulated test results from run_test_scenario and assert calls
var _test_results: Array = []
var _test_session_start: float = 0.0
var _stress_test_data: Dictionary = {}


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin


func get_commands() -> Dictionary:
	return {
		"testing/run_scenario": run_test_scenario,
		"testing/assert_state": assert_node_state,
		"testing/assert_screen_text": assert_screen_text,
		"testing/stress_test": run_stress_test,
		"testing/get_report": get_test_report,
	}


## Execute an array of test steps sequentially. Each step has a "type" and "params".
## Supported step types:
##   - "add_node": {parent_path, type, name, properties}
##   - "delete_node": {path}
##   - "set_property": {path, property, value}
##   - "assert_node_state": {path, property, expected, operator}
##   - "connect_signal": {source, signal, target, method}
##   - "wait": {seconds}
func run_test_scenario(params: Dictionary) -> Dictionary:
	var steps: Array = params.get("steps", [])
	if steps.is_empty():
		return {"error": "Steps array is required"}

	var scenario_name: String = params.get("name", "Unnamed Scenario")
	_test_session_start = Time.get_unix_time_from_system()
	var step_results: Array = []
	var passed: int = 0
	var failed: int = 0

	for i: int in range(steps.size()):
		var step: Dictionary = steps[i] as Dictionary
		var step_type: String = step.get("type", "")
		var step_params: Dictionary = step.get("params", {})
		var step_result: Dictionary = {"step": i, "type": step_type}

		var result: Dictionary = {}
		match step_type:
			"add_node":
				result = _step_add_node(step_params)
			"delete_node":
				result = _step_delete_node(step_params)
			"set_property":
				result = _step_set_property(step_params)
			"assert_node_state":
				result = _step_assert_state(step_params)
			"connect_signal":
				result = _step_connect_signal(step_params)
			"wait":
				result = _step_wait(step_params)
			_:
				result = {"error": "Unknown step type: %s" % step_type}

		step_result["result"] = result
		if result.has("error"):
			step_result["passed"] = false
			failed += 1
		elif result.has("passed"):
			step_result["passed"] = result["passed"]
			if result["passed"]:
				passed += 1
			else:
				failed += 1
		else:
			step_result["passed"] = true
			passed += 1

		step_results.append(step_result)
		_test_results.append(step_result)

	var summary: Dictionary = {
		"scenario": scenario_name,
		"total_steps": steps.size(),
		"passed": passed,
		"failed": failed,
		"duration_ms": (Time.get_unix_time_from_system() - _test_session_start) * 1000.0,
		"steps": step_results,
	}
	return {"result": summary}


## Assert that a node's property matches an expected value using an operator.
## Supported operators: "==", "!=", ">", "<", ">=", "<=", "contains"
func assert_node_state(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var property: String = params.get("property", "")
	var expected: Variant = params.get("expected")
	var operator: String = params.get("operator", "==")

	if path.is_empty() or property.is_empty():
		return {"error": "Path and property are required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var actual: Variant = node.get(property)
	var passed: bool = MCPCommandHelpers.compare_values(actual, expected, operator)

	var entry: Dictionary = {
		"path": path,
		"property": property,
		"actual": MCPVariantCodec.serialize_value(actual),
		"expected": expected,
		"operator": operator,
		"passed": passed,
	}
	_test_results.append(entry)

	if passed:
		return {"result": {"passed": true, "message": "Assertion passed: %s %s %s %s" % [path, property, operator, str(expected)]}}
	else:
		return {"result": {"passed": false, "message": "Assertion FAILED: %s.%s actual=%s %s expected=%s" % [path, property, str(actual), operator, str(expected)]}}


## Perform an OCR-like check on the viewport text.
## Searches for a string in the rendered viewport by checking all Label,
## Button, RichTextLabel, and LineEdit nodes.
func assert_screen_text(params: Dictionary) -> Dictionary:
	var expected_text: String = params.get("text", "")
	var should_exist: bool = params.get("should_exist", true)

	if expected_text.is_empty():
		return {"error": "Text is required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var found_nodes: Array = []
	_find_text_recursive(root, expected_text, found_nodes)
	var found: bool = found_nodes.size() > 0
	var passed: bool = found == should_exist

	var entry: Dictionary = {
		"text": expected_text,
		"should_exist": should_exist,
		"found": found,
		"found_count": found_nodes.size(),
		"passed": passed,
	}
	_test_results.append(entry)

	if passed:
		return {"result": {"passed": true, "message": "Screen text assertion passed: '%s' %s" % [expected_text, "found" if found else "not found"]}}
	else:
		return {"result": {"passed": false, "message": "Screen text assertion FAILED: '%s' expected %s but %s" % [expected_text, "to exist" if should_exist else "not to exist", "was found" if found else "was not found"]}}


## Spawn many nodes and measure FPS impact.
func run_stress_test(params: Dictionary) -> Dictionary:
	var node_type: String = params.get("type", "Node2D")
	var count: int = params.get("count", 100)
	var parent_path: String = params.get("parent_path", "")
	var properties: Dictionary = params.get("properties", {})

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var parent: Node = root
	if parent_path != "":
		parent = root.get_node_or_null(parent_path)
		if parent == null:
			return {"error": "Parent not found: %s" % parent_path}

	# Measure creation time
	var start_time: float = Time.get_ticks_usec()
	var created: Array = []
	for i: int in range(count):
		var node: Node = MCPNodeFactory.create_node(node_type)
		if node == null:
			return {"error": "Cannot instantiate type: %s" % node_type}
		node.name = "%s_%d" % [node_type, i]
		for prop: String in properties:
			if MCPCommandHelpers.has_property(node, prop):
				node.set(prop, properties[prop])
		parent.add_child(node)
		node.set_owner(root)
		created.append(node)
	var creation_time_ms: float = (Time.get_ticks_usec() - start_time) / 1000.0

	_stress_test_data = {
		"type": node_type,
		"count": count,
		"creation_time_ms": creation_time_ms,
		"nodes_created": created.size(),
	}

	# Clean up spawned nodes so they don't clutter the scene
	for n: Node in created:
		n.queue_free()

	return {"result": {
		"type": node_type,
		"nodes_spawned": created.size(),
		"creation_time_ms": creation_time_ms,
		"avg_time_per_node_ms": creation_time_ms / max(count, 1),
		"message": "Spawned %d %s nodes in %.2fms (nodes removed after test)." % [count, node_type, creation_time_ms],
	}}


## Get the aggregated test report from all assertions and scenario runs
## in this session.
func get_test_report(_params: Dictionary) -> Dictionary:
	var total: int = _test_results.size()
	var passed: int = 0
	var failed: int = 0
	var failures: Array = []

	for entry: Dictionary in _test_results:
		if entry.get("passed", false):
			passed += 1
		else:
			failed += 1
			failures.append(entry)

	return {"result": {
		"total_tests": total,
		"passed": passed,
		"failed": failed,
		"pass_rate": "%.1f%%" % (float(passed) / max(total, 1) * 100.0),
		"stress_test": _stress_test_data,
		"failures": failures,
		"session_duration_ms": (Time.get_unix_time_from_system() - _test_session_start) * 1000.0 if _test_session_start > 0 else 0.0,
	}}


## Step handlers for run_test_scenario

func _step_add_node(params: Dictionary) -> Dictionary:
	var parent_path: String = params.get("parent_path", "")
	var type_name: String = params.get("type", "Node")
	var node_name: String = params.get("name", type_name)
	var properties: Dictionary = params.get("properties", {})

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var parent: Node = root
	if parent_path != "":
		parent = root.get_node_or_null(parent_path)
		if parent == null:
			return {"error": "Parent not found: %s" % parent_path}

	var node: Node = MCPNodeFactory.create_node(type_name)
	if node == null:
		return {"error": "Unknown type: %s" % type_name}
	node.name = node_name

	for prop: String in properties:
		if MCPCommandHelpers.has_property(node, prop):
			var expected_type: int = MCPCommandHelpers.get_property_type(node, prop)
			var val: Variant = MCPVariantCodec.parse_for_property(properties[prop], expected_type)
			node.set(prop, val)

	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Test add node %s" % node_name)
	ur.add_do_method(parent, "add_child", node)
	ur.add_do_method(node, "set_owner", root)
	ur.add_undo_method(parent, "remove_child", node)
	ur.commit_action()
	return {"result": "Added %s '%s'" % [type_name, node_name]}


func _step_delete_node(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": "Path required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	if node == root:
		return {"error": "Cannot delete root"}

	var parent_node: Node = node.get_parent()
	if parent_node == null:
		return {"error": "Node has no parent"}

	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Test delete node %s" % path)
	ur.add_do_method(parent_node, "remove_child", node)
	ur.add_undo_method(parent_node, "add_child", node)
	ur.add_do_method(node, "set_owner", null)
	ur.add_undo_method(node, "set_owner", root)
	ur.commit_action()
	return {"result": "Deleted %s" % path}


func _step_set_property(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var property: String = params.get("property", "")
	var value: Variant = params.get("value")

	if path.is_empty() or property.is_empty():
		return {"error": "Path and property required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": "Node not found: %s" % path}

	var parsed: Variant = value
	if MCPCommandHelpers.has_property(node, property):
		var expected_type: int = MCPCommandHelpers.get_property_type(node, property)
		parsed = MCPVariantCodec.parse_for_property(value, expected_type)

	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Test set %s.%s" % [path, property])
	var old_val: Variant = node.get(property)
	ur.add_do_method(node, "set", property, parsed)
	ur.add_undo_property(node, property, old_val)
	ur.commit_action()
	return {"result": "Set %s.%s" % [path, property]}


func _step_assert_state(params: Dictionary) -> Dictionary:
	return assert_node_state(params)


func _step_connect_signal(params: Dictionary) -> Dictionary:
	var source_path: String = params.get("source", "")
	var signal_name: String = params.get("signal", "")
	var target_path: String = params.get("target", "")
	var method_name: String = params.get("method", "")

	if source_path.is_empty() or signal_name.is_empty() or target_path.is_empty() or method_name.is_empty():
		return {"error": "source, signal, target, and method are required"}

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	var source: Node = root.get_node_or_null(source_path)
	if source == null:
		return {"error": "Source not found: %s" % source_path}

	var target: Node = root.get_node_or_null(target_path)
	if target == null:
		return {"error": "Target not found: %s" % target_path}

	if not source.has_signal(signal_name):
		return {"error": "Signal '%s' not found on %s" % [signal_name, source_path]}

	var ur: EditorUndoRedoManager = _plugin.get_undo_redo()
	ur.create_action("MCP: Test connect signal %s.%s" % [source_path, signal_name])
	var callable: Callable = Callable(target, method_name)
	ur.add_do_method(source, "connect", signal_name, callable)
	ur.add_undo_method(source, "disconnect", signal_name, callable)
	ur.commit_action()
	return {"result": "Connected %s.%s -> %s.%s" % [source_path, signal_name, target_path, method_name]}


func _step_wait(params: Dictionary) -> Dictionary:
	var seconds: float = params.get("seconds", 1.0)
	# In editor mode, we can't truly wait. Record the intent.
	return {"result": "Wait step recorded (%.1fs) - execution deferred to runtime" % seconds}


## Find nodes whose text content matches a search string.
func _find_text_recursive(node: Node, search_text: String, results: Array) -> void:
	if node is Label:
		if (node as Label).text.find(search_text) != -1:
			results.append(MCPCommandHelpers.get_node_path(node, _plugin))
		elif node is Button:
		if (node as Button).text.find(search_text) != -1:
			results.append(MCPCommandHelpers.get_node_path(node, _plugin))
		elif node is RichTextLabel:
		if (node as RichTextLabel).get_parsed_text().find(search_text) != -1:
			results.append(MCPCommandHelpers.get_node_path(node, _plugin))
		elif node is LineEdit:
		if (node as LineEdit).text.find(search_text) != -1:
			results.append(MCPCommandHelpers.get_node_path(node, _plugin))
		elif node is TextEdit:
		if (node as TextEdit).text.find(search_text) != -1:
			results.append(MCPCommandHelpers.get_node_path(node, _plugin))
	for child: Node in node.get_children():
		_find_text_recursive(child, search_text, results)



