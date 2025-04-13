extends Area3D

@onready var collision : CollisionShape3D = $CollisionShape3D
@export var player : CharacterBody3D

var enemy_fireball_speed = 0.6
# life fireball's time
var enemy_fireball_time_life : float = 3
var enemy_fireball_time_currently : float = 0

func _ready() -> void:	
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		enemy_fireball_speed = config.get_value("enemy_fireball", "enemy_fireball_speed", enemy_fireball_speed)
		enemy_fireball_time_life = config.get_value("enemy_fireball", "enemy_fireball_time_life", enemy_fireball_time_life)
		#config.save("res://settings.cfg")
	config = null	
	
func _process(delta: float) -> void:
	if !collision.disabled:
		var direction = (transform.basis * Vector3(0, 0, -1)).normalized()
		global_transform.origin += direction * enemy_fireball_speed
		enemy_fireball_time_currently += delta
		if enemy_fireball_time_currently > enemy_fireball_time_life:
			queue_free()
	
func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player.take_damage(1)  # Zadaj 5 obrażeń graczowi	
	queue_free()

func collision_set_enabled() ->void:
	collision.disabled = false
