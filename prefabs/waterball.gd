extends Area3D

@export var player : CharacterBody3D

var player_waterball_speed = 0.6
var player_waterball_time_life : float = 2
var player_waterball_time_currently : float = 0

func _ready()->void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		player_waterball_speed = config.get_value("player_waterball", "player_waterball_speed", player_waterball_speed)
		player_waterball_time_life = config.get_value("player_waterball", "player_waterball_time_life", player_waterball_time_life)
		#config.save("res://settings.cfg")
	config = null
	
func _physics_process(delta: float) -> void:
	var direction = (transform.basis * Vector3(0, 0, -1)).normalized()
	global_transform.origin += direction
	player_waterball_time_currently += player_waterball_speed * delta
	if player_waterball_time_currently > player_waterball_time_life:
		queue_free()
	
func _on_body_entered(body: Node3D) -> void:
	if body.get_groups().size() > 0:
		if body.get_groups()[0] == "portal":
			for obj in body.list_enemy:
				obj.target = player
			body.portal_free()
		elif body.get_groups()[0] == "enemy":
			body.take_damage(1)
		queue_free()
