extends Area3D

@onready var collision : CollisionShape3D = $CollisionShape3D
@onready var timer_remove_object : Timer = $timer_remove_object
@export var player : CharacterBody3D

var enemy_fireball_speed = 20.0
var enemy_fireball_damage = 1.0

func _ready() -> void:	
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		enemy_fireball_speed = config.get_value("enemy_fireball", "enemy_fireball_speed", enemy_fireball_speed)
		timer_remove_object.wait_time = config.get_value("enemy_fireball", "enemy_fireball_time_life", timer_remove_object.wait_time)
		enemy_fireball_damage = config.get_value("enemy_fireball", "enemy_fireball_damage", enemy_fireball_damage)
		#config.save("res://settings.cfg")
	config = null	
	
func _process(delta: float) -> void:
	if !collision.disabled:
		var direction = (transform.basis * Vector3(0, 0, -1)).normalized()
		global_transform.origin += direction * enemy_fireball_speed * delta
	
func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player.take_damage(enemy_fireball_damage)
	call_deferred("queue_free")

func collision_set_enabled() ->void:
	collision.disabled = false
	timer_remove_object.start()

func _on_timer_remove_object_timeout() -> void:
	call_deferred("queue_free")
