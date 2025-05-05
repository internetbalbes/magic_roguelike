extends Area3D

@export var player: CharacterBody3D

func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player.take_damage(1)  # Zadaj 5 obrażeń graczowi	
	queue_free()
