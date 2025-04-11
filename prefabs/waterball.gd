extends Area3D

const SPEED = 5.0

@export var player : CharacterBody3D

# life waterball's time
var time = 0

func _physics_process(delta: float) -> void:
	var direction = (transform.basis * Vector3(0, 0, -1)).normalized()
	global_transform.origin += direction
	time += delta
	if time > 1:
		queue_free()
	
func _on_body_entered(body: Node3D) -> void:
	if body.get_groups().size() > 0:
		if body.get_groups()[0] == "portal":
			for obj in body.list_enemy:
				obj.target = player
			body.queue_free()
		elif body.get_groups()[0] == "enemy":
			body.take_damage(1)
		queue_free()
