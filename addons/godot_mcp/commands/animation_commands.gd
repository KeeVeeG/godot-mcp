## Animation commands module - 15 tools.
## Handles AnimationPlayer, AnimationTree, and state machines.
class_name MCPAnimationCommands
extends RefCounted

var _plugin: EditorPlugin
var _undo_helper: MCUndoHelper


func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin
	if _plugin.has_method("get_undo_helper"):
		_undo_helper = _plugin.get_undo_helper()


func get_commands() -> Dictionary:
	return {
		"animation/list": list_animations,
		"animation/create": create_animation,
		"animation/add_track": add_animation_track,
		"animation/remove_track": remove_animation_track,
		"animation/set_keyframe": set_animation_keyframe,
		"animation/remove_keyframe": remove_animation_keyframe,
		"animation/get_info": get_animation_info,
		"animation/remove": remove_animation,
		"animation/create_tree": create_animation_tree,
		"animation/get_tree_structure": get_animation_tree_structure,
		"animation/set_tree_parameter": set_tree_parameter,
		"animation/add_state": add_state_machine_state,
		"animation/remove_state": remove_state_machine_state,
		"animation/add_transition": add_state_machine_transition,
		"animation/remove_transition": remove_state_machine_transition,
	}


## List all animations in an AnimationPlayer.
func list_animations(params: Dictionary) -> Dictionary:
	var path: String = params.get("player_path", params.get("path", ""))
	if path.is_empty():
		return {"error": "AnimationPlayer path is required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null:
		return {"error": "Node not found: %s" % path}
	if not node is AnimationPlayer:
		return {"error": "Node is not an AnimationPlayer: %s" % path}
	var player: AnimationPlayer = node as AnimationPlayer
	var anims: PackedStringArray = player.get_animation_list()
	var result: Array = []
	for anim_name: String in anims:
		var anim: Animation = player.get_animation(anim_name)
		if anim:
			result.append({
				"name": anim_name,
				"length": anim.length,
				"loop_mode": int(anim.loop_mode),
				"track_count": anim.get_track_count(),
			})
	return {"result": {"player": path, "animations": result}}


## Create a new empty animation.
func create_animation(params: Dictionary) -> Dictionary:
	var path: String = params.get("player_path", params.get("path", ""))
	var anim_name: String = params.get("animation", params.get("name", "NewAnimation"))
	if path.is_empty():
		return {"error": "AnimationPlayer path is required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null or not node is AnimationPlayer:
		return {"error": "AnimationPlayer not found: %s" % path}
	var player: AnimationPlayer = node as AnimationPlayer
	var anim: Animation = Animation.new()
	anim.length = params.get("length", 1.0)
	var loop_mode_raw: Variant = params.get("loop_mode", 0)
	var loop_mode: int = 0
	if loop_mode_raw is String:
		match loop_mode_raw:
			"loop": loop_mode = 1
			"pingpong": loop_mode = 2
			_: loop_mode = 0
	else:
		loop_mode = int(loop_mode_raw)
	anim.loop_mode = loop_mode as Animation.LoopMode
	var library_name: String = params.get("library", "")
	if library_name.is_empty():
		if not player.has_animation_library(""):
			var lib: AnimationLibrary = AnimationLibrary.new()
			player.add_animation_library("", lib)
		player.get_animation_library("").add_animation(anim_name, anim)
	else:
		if not player.has_animation_library(library_name):
			var lib: AnimationLibrary = AnimationLibrary.new()
			player.add_animation_library(library_name, lib)
		player.get_animation_library(library_name).add_animation(anim_name, anim)
	return {"result": "Animation '%s' created in %s" % [anim_name, path]}


## Add a track to an animation.
func add_animation_track(params: Dictionary) -> Dictionary:
	var path: String = params.get("player_path", params.get("path", ""))
	var anim_name: String = params.get("anim_name", params.get("animation", ""))
	var track_type_raw: Variant = params.get("track_type", 0)
	var track_type: int = 0
	if track_type_raw is String:
		match track_type_raw:
			"value": track_type = 0
			"position_3d", "position": track_type = 1
			"rotation_3d", "rotation": track_type = 2
			"scale_3d", "scale": track_type = 3
			"blend_shape": track_type = 4
			"method": track_type = 5
			"bezier": track_type = 6
			"audio": track_type = 7
			"animation": track_type = 8
			_:
				if track_type_raw is String:
					return {"error": "Unknown track type: %s" % track_type_raw}
				track_type = int(track_type_raw)
	else:
		track_type = track_type_raw as int
	var property: String = params.get("property", params.get("track_path", ""))
	var library_name: String = params.get("library", "")
	if path.is_empty() or anim_name.is_empty():
		return {"error": "path and anim_name are required"}

	# ALL track types require a property path to resolve to a target node.
	# Without it, the AnimationMixer silently skips the track during playback (BUG-4).
	if property.is_empty():
		return {"error": "property (track path) is required for all track types. " +
			"Examples: 'NodePath:property' for value/bezier, " +
			"'NodePath' for position/rotation/scale/method/audio/animation, " +
			"'MeshInstance:blend_shape_name' for blend_shape"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null or not node is AnimationPlayer:
		return {"error": "AnimationPlayer not found: %s" % path}
	var player: AnimationPlayer = node as AnimationPlayer
	var anim: Animation = null
	if library_name.is_empty():
		anim = player.get_animation(anim_name)
	else:
		var lib: AnimationLibrary = player.get_animation_library(library_name)
		if lib == null:
			return {"error": "Animation library not found: '%s'" % library_name}
		anim = lib.get_animation(anim_name)
	if anim == null:
		return {"error": "Animation not found: %s" % anim_name}

	var track_idx: int = -1
	match track_type:
		0:  # VALUE
			track_idx = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(track_idx, NodePath(property))
		1:  # POSITION_3D
			track_idx = anim.add_track(Animation.TYPE_POSITION_3D)
			anim.track_set_path(track_idx, NodePath(property))
		2:  # ROTATION_3D
			track_idx = anim.add_track(Animation.TYPE_ROTATION_3D)
			anim.track_set_path(track_idx, NodePath(property))
		3:  # SCALE_3D
			track_idx = anim.add_track(Animation.TYPE_SCALE_3D)
			anim.track_set_path(track_idx, NodePath(property))
		4:  # BLEND_SHAPE
			track_idx = anim.add_track(Animation.TYPE_BLEND_SHAPE)
			anim.track_set_path(track_idx, NodePath(property))
		5:  # METHOD
			track_idx = anim.add_track(Animation.TYPE_METHOD)
			anim.track_set_path(track_idx, NodePath(property))
		6:  # BEZIER
			track_idx = anim.add_track(Animation.TYPE_BEZIER)
			anim.track_set_path(track_idx, NodePath(property))
		7:  # AUDIO
			track_idx = anim.add_track(Animation.TYPE_AUDIO)
			anim.track_set_path(track_idx, NodePath(property))
		8:  # ANIMATION
			track_idx = anim.add_track(Animation.TYPE_ANIMATION)
			anim.track_set_path(track_idx, NodePath(property))
		_:
			return {"error": "Unsupported track type: %d" % track_type}

	return {"result": {"track_index": track_idx, "animation": anim_name}}


## Set a keyframe value at a time position.
func set_animation_keyframe(params: Dictionary) -> Dictionary:
	var path: String = params.get("player_path", params.get("path", ""))
	var anim_name: String = params.get("anim_name", params.get("animation", ""))
	var track_idx: int = params.get("track_idx", params.get("track_index", 0))
	var time: float = params.get("time", 0.0)
	var value: Variant = params.get("value")
	var library_name: String = params.get("library", "")
	if path.is_empty() or anim_name.is_empty():
		return {"error": "path and anim_name are required"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null or not node is AnimationPlayer:
		return {"error": "AnimationPlayer not found: %s" % path}
	var player: AnimationPlayer = node as AnimationPlayer
	var anim: Animation = null
	if library_name.is_empty():
		anim = player.get_animation(anim_name)
	else:
		var lib: AnimationLibrary = player.get_animation_library(library_name)
		if lib == null:
			return {"error": "Animation library not found: '%s'" % library_name}
		anim = lib.get_animation(anim_name)
	if anim == null:
		return {"error": "Animation not found: %s" % anim_name}
	if track_idx < 0 or track_idx >= anim.get_track_count():
		return {"error": "Invalid track index: %d" % track_idx}

	# Parse value based on track type
	var track_type: int = anim.track_get_type(track_idx)
	match track_type:
		Animation.TYPE_VALUE:
			anim.track_insert_key(track_idx, time, value)
		Animation.TYPE_POSITION_3D:
			var pos: Vector3 = MCPVariantCodec._parse_vector3(value)
			anim.position_track_insert_key(track_idx, time, pos)
		Animation.TYPE_ROTATION_3D:
			var rot: Quaternion = MCPVariantCodec._parse_quaternion(value)
			anim.rotation_track_insert_key(track_idx, time, rot)
		Animation.TYPE_SCALE_3D:
			var scale: Vector3 = MCPVariantCodec._parse_vector3(value)
			anim.scale_track_insert_key(track_idx, time, scale)
		Animation.TYPE_BEZIER:
			anim.bezier_track_insert_key(track_idx, time, float(value))
		_:
			anim.track_insert_key(track_idx, time, value)

	return {"result": "Keyframe set at time %.2f on track %d" % [time, track_idx]}


## Get info about a specific animation.
func get_animation_info(params: Dictionary) -> Dictionary:
	var path: String = params.get("player_path", params.get("path", ""))
	var anim_name: String = params.get("anim_name", params.get("animation", ""))
	var library_name: String = params.get("library", "")
	if path.is_empty() or anim_name.is_empty():
		return {"error": "path and anim_name are required"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null or not node is AnimationPlayer:
		return {"error": "AnimationPlayer not found: %s" % path}
	var player: AnimationPlayer = node as AnimationPlayer
	var anim: Animation = null
	if library_name.is_empty():
		anim = player.get_animation(anim_name)
	else:
		var lib: AnimationLibrary = player.get_animation_library(library_name)
		if lib == null:
			return {"error": "Animation library not found: '%s'" % library_name}
		anim = lib.get_animation(anim_name)
	if anim == null:
		return {"error": "Animation not found: %s" % anim_name}

	var tracks: Array = []
	for i: int in range(anim.get_track_count()):
		tracks.append({
			"index": i,
			"type": int(anim.track_get_type(i)),
			"path": str(anim.track_get_path(i)),
			"key_count": anim.track_get_key_count(i),
			"enabled": anim.track_is_enabled(i),
		})
	return {"result": {
		"name": anim_name,
		"length": anim.length,
		"loop_mode": int(anim.loop_mode),
		"step": anim.step,
		"tracks": tracks,
	}}


## Remove an animation.
func remove_animation(params: Dictionary) -> Dictionary:
	var path: String = params.get("player_path", params.get("path", ""))
	var anim_name: String = params.get("anim_name", params.get("animation", ""))
	var library_name: String = params.get("library", "")
	if path.is_empty() or anim_name.is_empty():
		return {"error": "path and anim_name are required"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null or not node is AnimationPlayer:
		return {"error": "AnimationPlayer not found: %s" % path}
	var player: AnimationPlayer = node as AnimationPlayer
	var lib: AnimationLibrary = null
	if library_name.is_empty():
		lib = player.get_animation_library("")
	else:
		lib = player.get_animation_library(library_name)
	if lib == null:
		return {"error": "Animation library not found: '%s'" % library_name}
	if not lib.has_animation(anim_name):
		return {"error": "Animation not found: %s" % anim_name}
	lib.remove_animation(anim_name)
	return {"result": "Animation '%s' removed from %s" % [anim_name, path]}


## Create an AnimationTree node, or configure existing one.
func create_animation_tree(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var parent_path: String = params.get("parent_path", "")
	var player_path: String = params.get("player_path", "")
	var props: Dictionary = params.get("properties", {})
	var root_type: String = params.get("root_type", props.get("root_type", "AnimationNodeBlendTree"))

	var root: Node = MCPCommandHelpers.get_scene_root(_plugin)
	if root == null:
		return {"error": "No scene open"}

	# If path points to an existing AnimationTree, configure it
	var tree: AnimationTree = null
	if not path.is_empty():
		var existing: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
		if existing != null:
			if existing is AnimationTree:
				tree = existing as AnimationTree
			else:
				return {"error": "Node at path '%s' is not an AnimationTree (type: %s)" % [path, existing.get_class()]}

	if tree == null:
		# Create new — determine parent and node name
		var parent: Node = root
		var node_name: String = props.get("name", "AnimationTree")
		if not parent_path.is_empty():
			# Explicit parent_path provided
			parent = MCPCommandHelpers.resolve_node_path(_plugin, parent_path)
		elif path.contains("/"):
			# path like "AnimTestPlayer/AnimTree" — parent is "AnimTestPlayer", name is "AnimTree"
			var last_slash: int = path.rfind("/")
			var parent_part: String = path.substr(0, last_slash)
			node_name = path.substr(last_slash + 1)
			parent = MCPCommandHelpers.resolve_node_path(_plugin, parent_part)
		elif not path.is_empty():
			# Bare name — use as node name, parent is scene root
			node_name = path
		if parent == null:
			return {"error": "Parent not found"}
		# Check for duplicate node name (BUG-5)
		# add_child() silently renames duplicates (AnimTree@2) instead of erroring
		if parent.has_node(node_name):
			var existing_child: Node = parent.get_node(node_name)
			return {"error": "Node '%s' already exists under parent '%s' (type: %s)" % [node_name, parent.name, existing_child.get_class()]}
		tree = AnimationTree.new()
		tree.name = node_name
		if _undo_helper:
			_undo_helper.add_node_with_undo(tree, parent)
		else:
			parent.add_child(tree)
			tree.set_owner(root)

	if not player_path.is_empty():
		var player: Node = MCPCommandHelpers.resolve_node_path(_plugin, player_path)
		if player and player is AnimationPlayer:
			tree.anim_player = NodePath(player_path)

	# Create the root animation node
	var root_node: AnimationNode = null
	match root_type:
		"AnimationNodeBlendTree":
			root_node = AnimationNodeBlendTree.new()
		"AnimationNodeStateMachine":
			root_node = AnimationNodeStateMachine.new()
		"AnimationNodeBlendSpace1D":
			root_node = AnimationNodeBlendSpace1D.new()
		"AnimationNodeBlendSpace2D":
			root_node = AnimationNodeBlendSpace2D.new()
		"AnimationNodeAnimation":
			root_node = AnimationNodeAnimation.new()
		_:
			root_node = AnimationNodeBlendTree.new()

	tree.tree_root = root_node

	return {"result": {"name": str(tree.name), "path": MCPCommandHelpers.get_node_path(tree, _plugin), "root_type": root_type}}


## Get AnimationTree structure.
func get_animation_tree_structure(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", params.get("player_path", ""))
	if path.is_empty():
		return {"error": "path is required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null or not node is AnimationTree:
		return {"error": "AnimationTree not found: %s" % path}
	var tree: AnimationTree = node as AnimationTree
	var result: Dictionary = {
		"path": path,
		"active": tree.active,
		"anim_player": str(tree.anim_player),
	}
	if tree.tree_root:
		result["root_type"] = tree.tree_root.get_class()
		if tree.tree_root is AnimationNodeBlendTree:
			var btree: AnimationNodeBlendTree = tree.tree_root as AnimationNodeBlendTree
			var nodes: Dictionary = {}
			for node_name: String in btree.get_node_list():
				var an: AnimationNode = btree.get_node(node_name)
				nodes[node_name] = {"type": an.get_class()}
			result["nodes"] = nodes
			# get_connection_list not available on AnimationNodeBlendTree in Godot 4.x
			# Skip connections for blend trees
		elif tree.tree_root is AnimationNodeStateMachine:
			var sm: AnimationNodeStateMachine = tree.tree_root as AnimationNodeStateMachine
			var states: Array = []
			var state_names: PackedStringArray = sm.get_node_list()
			for state_name: String in state_names:
				states.append({
					"name": state_name,
					"position": {"x": sm.get_node_position(state_name).x, "y": sm.get_node_position(state_name).y},
				})
			result["states"] = states
			var transitions: Array = []
			for j: int in range(sm.get_transition_count()):
				transitions.append({
					"from": str(sm.get_transition_from(j)),
					"to": str(sm.get_transition_to(j)),
				})
			result["transitions"] = transitions
	return {"result": result}


## Set a parameter on an AnimationTree.
func set_tree_parameter(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", params.get("player_path", ""))
	var parameter: String = params.get("parameter", "")
	var value: Variant = params.get("value")
	if path.is_empty() or parameter.is_empty():
		return {"error": "path and parameter are required"}

	# Reject null values — AnimationTree parameters require typed values (BUG-6)
	if value == null:
		return {"error": "Parameter value cannot be null. AnimationTree parameters require typed values (float, int, bool, string, Vector2, etc.)"}

	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null or not node is AnimationTree:
		return {"error": "AnimationTree not found: %s" % path}
	var tree: AnimationTree = node as AnimationTree

	# Validate parameter exists using Godot's property list (BUG-2)
	# Object::set() silently discards r_valid=false in GDScript, so we must check manually
	var param_exists: bool = false
	for prop: Dictionary in tree.get_property_list():
		if prop.get("name", "") == parameter:
			param_exists = true
			break
	if not param_exists:
		return {"error": "Parameter '%s' does not exist on AnimationTree at '%s'. Use get_animation_tree_structure to see available parameters." % [parameter, path]}

	tree.set(parameter, value)
	return {"result": "Parameter '%s' set on %s" % [parameter, path]}


## Add a state to a state machine AnimationTree.
func add_state_machine_state(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", params.get("player_path", ""))
	var state_name: String = params.get("state_name", "")
	var animation: String = params.get("animation", "")
	var position: Dictionary = params.get("position", {})
	if path.is_empty() or state_name.is_empty():
		return {"error": "path and state_name are required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null or not node is AnimationTree:
		return {"error": "AnimationTree not found: %s" % path}
	var tree: AnimationTree = node as AnimationTree
	# Refuse auto-conversion to prevent data loss (BUG-1)
	if tree.tree_root == null:
		return {"error": "AnimationTree at '%s' has no root node. Create a root via create_animation_tree first." % path}
	if not tree.tree_root is AnimationNodeStateMachine:
		return {"error": "AnimationTree root is '%s', not AnimationNodeStateMachine. Refusing to auto-convert — would destroy existing configuration. Set root_type='AnimationNodeStateMachine' in create_animation_tree instead." % tree.tree_root.get_class()}
	var sm: AnimationNodeStateMachine = tree.tree_root as AnimationNodeStateMachine
	# Check for duplicate state (BUG-3)
	if sm.has_node(state_name):
		return {"error": "State '%s' already exists in state machine at '%s'" % [state_name, path]}
	var anim_node: AnimationNodeAnimation = AnimationNodeAnimation.new()
	if not animation.is_empty():
		anim_node.animation = animation
	var pos: Vector2 = Vector2(position.get("x", 0.0) as float, position.get("y", 0.0) as float)
	sm.add_node(state_name, anim_node, pos)
	return {"result": "State '%s' added to state machine" % state_name}


## Remove a state from a state machine AnimationTree.
func remove_state_machine_state(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", params.get("player_path", ""))
	var state_name: String = params.get("state_name", "")
	if path.is_empty() or state_name.is_empty():
		return {"error": "path and state_name are required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null or not node is AnimationTree:
		return {"error": "AnimationTree not found: %s" % path}
	var tree: AnimationTree = node as AnimationTree
	if tree.tree_root == null or not tree.tree_root is AnimationNodeStateMachine:
		return {"error": "AnimationTree root is not a StateMachine"}
	var sm: AnimationNodeStateMachine = tree.tree_root as AnimationNodeStateMachine
	if not sm.has_node(state_name):
		return {"error": "State '%s' does not exist in state machine at '%s'" % [state_name, path]}
	sm.remove_node(state_name)
	return {"result": "State '%s' removed from state machine (including all connected transitions)" % state_name}


## Add a transition between two states in a state machine.
func add_state_machine_transition(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var from_state: String = params.get("from", "")
	var to_state: String = params.get("to", "")
	if path.is_empty() or from_state.is_empty() or to_state.is_empty():
		return {"error": "path, from, and to are required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null or not node is AnimationTree:
		return {"error": "AnimationTree not found: %s" % path}
	var tree: AnimationTree = node as AnimationTree
	if tree.tree_root == null or not tree.tree_root is AnimationNodeStateMachine:
		return {"error": "AnimationTree root is not a StateMachine"}
	var sm: AnimationNodeStateMachine = tree.tree_root as AnimationNodeStateMachine
	if not sm.has_node(from_state):
		return {"error": "Source state '%s' does not exist in state machine" % from_state}
	if not sm.has_node(to_state):
		return {"error": "Target state '%s' does not exist in state machine" % to_state}
	if sm.has_transition(from_state, to_state):
		return {"error": "Transition from '%s' to '%s' already exists" % [from_state, to_state]}
	var trans: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
	# Parse advance_mode
	var advance_mode_raw: String = params.get("advance_mode", "enabled")
	match advance_mode_raw:
		"disabled": trans.set_advance_mode(AnimationNodeStateMachineTransition.ADVANCE_MODE_DISABLED)
		"enabled": trans.set_advance_mode(AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED)
		"auto": trans.set_advance_mode(AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO)
	# Parse switch_mode
	var switch_mode_raw: String = params.get("switch_mode", "immediate")
	match switch_mode_raw:
		"immediate": trans.set_switch_mode(AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE)
		"sync": trans.set_switch_mode(AnimationNodeStateMachineTransition.SWITCH_MODE_SYNC)
		"at_end": trans.set_switch_mode(AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END)
	trans.set_xfade_time(float(params.get("xfade_time", 0.0)))
	trans.set_priority(int(params.get("priority", 1)))
	trans.set_reset(bool(params.get("reset", true)))
	var advance_condition: String = params.get("advance_condition", "")
	if not advance_condition.is_empty():
		trans.set_advance_condition(advance_condition)
	sm.add_transition(from_state, to_state, trans)
	return {"result": "Transition '%s' -> '%s' added" % [from_state, to_state]}


## Remove a transition between two states in a state machine.
func remove_state_machine_transition(params: Dictionary) -> Dictionary:
	var path: String = params.get("path", "")
	var from_state: String = params.get("from", "")
	var to_state: String = params.get("to", "")
	if path.is_empty() or from_state.is_empty() or to_state.is_empty():
		return {"error": "path, from, and to are required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null or not node is AnimationTree:
		return {"error": "AnimationTree not found: %s" % path}
	var tree: AnimationTree = node as AnimationTree
	if tree.tree_root == null or not tree.tree_root is AnimationNodeStateMachine:
		return {"error": "AnimationTree root is not a StateMachine"}
	var sm: AnimationNodeStateMachine = tree.tree_root as AnimationNodeStateMachine
	if not sm.has_transition(from_state, to_state):
		return {"error": "Transition from '%s' to '%s' does not exist" % [from_state, to_state]}
	sm.remove_transition(from_state, to_state)
	return {"result": "Transition '%s' -> '%s' removed" % [from_state, to_state]}


## Remove a track from an animation.
func remove_animation_track(params: Dictionary) -> Dictionary:
	var path: String = params.get("player_path", params.get("path", ""))
	var anim_name: String = params.get("anim_name", params.get("animation", ""))
	var track_idx: int = params.get("track_idx", params.get("track_index", -1))
	var library_name: String = params.get("library", "")
	if path.is_empty() or anim_name.is_empty() or track_idx < 0:
		return {"error": "path, anim_name, and track_index (>= 0) are required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null or not node is AnimationPlayer:
		return {"error": "AnimationPlayer not found: %s" % path}
	var player: AnimationPlayer = node as AnimationPlayer
	var anim: Animation = null
	if library_name.is_empty():
		anim = player.get_animation(anim_name)
	else:
		var lib: AnimationLibrary = player.get_animation_library(library_name)
		if lib == null:
			return {"error": "Animation library not found: '%s'" % library_name}
		anim = lib.get_animation(anim_name)
	if anim == null:
		return {"error": "Animation not found: %s" % anim_name}
	if track_idx < 0 or track_idx >= anim.get_track_count():
		return {"error": "Invalid track index: %d (track count: %d)" % [track_idx, anim.get_track_count()]}
	anim.remove_track(track_idx)
	return {"result": "Track %d removed from animation '%s'" % [track_idx, anim_name]}


## Remove a keyframe from an animation track at a specific time.
func remove_animation_keyframe(params: Dictionary) -> Dictionary:
	var path: String = params.get("player_path", params.get("path", ""))
	var anim_name: String = params.get("anim_name", params.get("animation", ""))
	var track_idx: int = params.get("track_idx", params.get("track_index", -1))
	var time: float = params.get("time", -1.0)
	var library_name: String = params.get("library", "")
	if path.is_empty() or anim_name.is_empty() or track_idx < 0 or time < 0.0:
		return {"error": "path, anim_name, track_index (>= 0), and time (>= 0) are required"}
	var node: Node = MCPCommandHelpers.resolve_node_path(_plugin, path)
	if node == null or not node is AnimationPlayer:
		return {"error": "AnimationPlayer not found: %s" % path}
	var player: AnimationPlayer = node as AnimationPlayer
	var anim: Animation = null
	if library_name.is_empty():
		anim = player.get_animation(anim_name)
	else:
		var lib: AnimationLibrary = player.get_animation_library(library_name)
		if lib == null:
			return {"error": "Animation library not found: '%s'" % library_name}
		anim = lib.get_animation(anim_name)
	if anim == null:
		return {"error": "Animation not found: %s" % anim_name}
	if track_idx < 0 or track_idx >= anim.get_track_count():
		return {"error": "Invalid track index: %d (track count: %d)" % [track_idx, anim.get_track_count()]}
	anim.track_remove_key_at_time(track_idx, time)
	return {"result": "Keyframe at time %.2f removed from track %d" % [time, track_idx]}
