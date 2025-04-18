extends CharacterBody3D

@onready var collision_shape = $CollisionShape3D.shape
@onready var timer_remove_object = $timer_remove_object
@export var player : CharacterBody3D

var player_thunderbolt_speed = 20.0
var spell: SpellClass
var collider : Node3D
var collider_position : Vector3 = Vector3.ZERO
var min_distance_to_object = 0

func _ready()->void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		player_thunderbolt_speed = config.get_value("player_thunderbolt", "player_thunderbolt_speed", player_thunderbolt_speed)
		timer_remove_object.wait_time = config.get_value("player_thunderbolt", "player_thunderbolt_time_life", 2)
		#config.save("res://settings.cfg")
	config = null
	if collider && collider.get_groups().size() > 0:
		if collider.get_groups()[0] == "portal" || collider.get_groups()[0] == "enemy":
			min_distance_to_object = collider._get_object_size() + collision_shape.radius
	timer_remove_object.start()
	
func _physics_process(delta: float) -> void:
	if min_distance_to_object > 0 && global_position.distance_to(collider_position) < min_distance_to_object:
		if collider.get_groups().size() > 0:
			if collider.get_groups()[0] == "portal":
				for obj in collider.list_enemy:
					obj._set_target(player)
				collider.portal_free()
			elif collider.get_groups()[0] == "enemy":
				collider.take_damage(spell.damage)
		call_deferred("queue_free")
	else:		
		var direction = (transform.basis * Vector3(0, 0, -1)).normalized()
		global_position += direction * player_thunderbolt_speed *  delta

func set_collider(node: Node3D, pos: Vector3):
	collider = node
	collider_position = pos		

func _on_timer_remove_object_timeout() -> void:
	call_deferred("queue_free")
