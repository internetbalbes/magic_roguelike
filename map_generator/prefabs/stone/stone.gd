extends StaticBody3D

func _ready() -> void:
	rotation_degrees = Vector3(randf_range(-45,45),randf_range(0,359),randf_range(-45,45))
