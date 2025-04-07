extends StaticBody3D

const SPEED = 5

func _process(delta: float) -> void:
	rotate_y(delta * SPEED)
