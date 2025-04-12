extends Area3D

const SPEED = 0.6

@export var player : CharacterBody3D
# life fireball's time
@export var fireball_time_life : float = 0

func _process(delta: float) -> void:
	if fireball_time_life > 0:
		var direction = (transform.basis * Vector3(0, 0, -1)).normalized()
		global_transform.origin += direction * SPEED
		fireball_time_life += delta
		if fireball_time_life > 3:
			queue_free()
	
func _on_body_entered(body: Node3D) -> void:
	if fireball_time_life > 0:
		if body == player:
			player.take_damage(1)  # Zadaj 5 obrażeń graczowi	
		queue_free()		
