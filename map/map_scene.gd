extends Node3D

@export var directional_light : DirectionalLight3D

func _process(delta: float) -> void:
	directional_light.rotation.x += 0.01
