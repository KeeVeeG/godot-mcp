## Shared node factory for creating nodes by type name.
## Merges implementations from node_commands (38 types), scene_commands (36 types),
## and testing_commands (16 types) into a single authoritative source.
@tool
class_name MCPNodeFactory
extends RefCounted


## Create a node by type name string.
## Returns null if the type is unknown and cannot be instantiated via ClassDB.
static func create_node(type_name: String) -> Node:
	match type_name:
		"Node":
			return Node.new()
		"Node2D":
			return Node2D.new()
		"Node3D":
			return Node3D.new()
		"Control":
			return Control.new()
		"Sprite2D":
			return Sprite2D.new()
		"Sprite3D":
			return Sprite3D.new()
		"MeshInstance3D":
			return MeshInstance3D.new()
		"MeshInstance2D":
			return MeshInstance2D.new()
		"Camera2D":
			return Camera2D.new()
		"Camera3D":
			return Camera3D.new()
		"StaticBody2D":
			return StaticBody2D.new()
		"StaticBody3D":
			return StaticBody3D.new()
		"CharacterBody2D":
			return CharacterBody2D.new()
		"CharacterBody3D":
			return CharacterBody3D.new()
		"RigidBody2D":
			return RigidBody2D.new()
		"RigidBody3D":
			return RigidBody3D.new()
		"Area2D":
			return Area2D.new()
		"Area3D":
			return Area3D.new()
		"Label":
			return Label.new()
		"Button":
			return Button.new()
		"TextureRect":
			return TextureRect.new()
		"ColorRect":
			return ColorRect.new()
		"VBoxContainer":
			return VBoxContainer.new()
		"HBoxContainer":
			return HBoxContainer.new()
		"MarginContainer":
			return MarginContainer.new()
		"Panel":
			return Panel.new()
		"PanelContainer":
			return PanelContainer.new()
		"CollisionShape2D":
			return CollisionShape2D.new()
		"CollisionShape3D":
			return CollisionShape3D.new()
		"AnimationPlayer":
			return AnimationPlayer.new()
		"AnimationTree":
			return AnimationTree.new()
		"TileMap":
			return TileMap.new()
		"GPUParticles2D":
			return GPUParticles2D.new()
		"GPUParticles3D":
			return GPUParticles3D.new()
		"AudioStreamPlayer":
			return AudioStreamPlayer.new()
		"AudioStreamPlayer2D":
			return AudioStreamPlayer2D.new()
		"AudioStreamPlayer3D":
			return AudioStreamPlayer3D.new()
		"DirectionalLight3D":
			return DirectionalLight3D.new()
		"OmniLight3D":
			return OmniLight3D.new()
		"SpotLight3D":
			return SpotLight3D.new()
		"SubViewport":
			return SubViewport.new()
		"SubViewportContainer":
			return SubViewportContainer.new()
		"NavigationRegion2D":
			return NavigationRegion2D.new()
		"NavigationRegion3D":
			return NavigationRegion3D.new()
		"NavigationAgent2D":
			return NavigationAgent2D.new()
		"NavigationAgent3D":
			return NavigationAgent3D.new()
		"CSGBox3D":
			return CSGBox3D.new()
		"CSGSphere3D":
			return CSGSphere3D.new()
		"CSGCylinder3D":
			return CSGCylinder3D.new()
		_:
			# Try ClassDB instantiation for any type not explicitly listed
			if ClassDB.can_instantiate(type_name):
				var obj: Object = ClassDB.instantiate(type_name)
				if obj is Node:
					return obj as Node
			return null
