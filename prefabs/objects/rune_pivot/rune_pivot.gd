extends Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var radians_per_second = deg_to_rad(Globalsettings.cold_steels["pivot_rotation_speed"])
	rotate_y(radians_per_second * delta)
