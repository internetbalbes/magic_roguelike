extends Area3D

@onready var collision : CollisionShape3D = $CollisionShape3D
@onready var timer_remove_object : Timer = $timer_remove_object
@export var player : CharacterBody3D

func _ready() -> void:	
	timer_remove_object.wait_time = Globalsettings.enemy_imp_fireball["enemy_fireball_time_life"]
	
func _process(delta: float) -> void:
	if !collision.disabled:
		var direction = (transform.basis * Vector3(0, 0, -1)).normalized()
		global_transform.origin += direction * Globalsettings.enemy_imp_fireball["enemy_fireball_speed"] * delta
	
func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player.take_damage(Globalsettings.enemy_imp_fireball["enemy_fireball_damage"])
	call_deferred("queue_free")

func collision_set_enabled() ->void:
	collision.disabled = false
	timer_remove_object.start()

func _on_timer_remove_object_timeout() -> void:
	call_deferred("queue_free")
