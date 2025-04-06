extends Area3D

@export var player : CharacterBody3D

const SPEED = 5

func _process(delta: float) -> void:
	rotate_y(delta * SPEED)
	
func _on_body_entered(body: Node3D) -> void:
	if body.get_groups()[0] == "enemy":
		if body.target != player:
			body.target.list_enemy.erase(body)
			body.queue_free()
		queue_free()
