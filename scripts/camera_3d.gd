extends Camera3D

# camer's sensitivity
const SENSITIVITY = 0.1
# camer's min max angle
const VERTICAL_LIMIT = 90

# camer's vertical angle
var vertical_angle = 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		vertical_angle -= event.relative.y * SENSITIVITY
		vertical_angle = clamp(vertical_angle, -VERTICAL_LIMIT, VERTICAL_LIMIT)
		rotation_degrees.x = vertical_angle
