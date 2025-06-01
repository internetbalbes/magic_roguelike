extends Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var radians_per_second = deg_to_rad(Globalsettings.cold_steels["pivot_rotation_speed"])
	rotate_y(radians_per_second * delta)


func _on_body_entered(body: Node3D) -> void:
	body.in_new_loot(self)
	
func _on_body_exited(body: Node3D) -> void:
	body.out_new_loot(self)


func _on_timer_remove_timeout() -> void:
	call_deferred("queue_free") # Replace with function body.
