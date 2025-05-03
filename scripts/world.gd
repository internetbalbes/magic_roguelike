extends Node3D

@onready var player = $player
@onready var map_generator = $map_generator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		map_generator.scale_size_map = config.get_value("world", "scale_size_map", 50)
		#config.save("res://settings.cfg")
	config = null
	map_generator.create_chunk()
	var player_coordinate = map_generator.find_block_free()
	#player_coordinate = map_generator.created_portal.global_position + Vector3(1, 0, 3)
	player.set_deferred("global_position", Vector3(player_coordinate.x, player_coordinate.y + player.collision_shape.height/2, player_coordinate.z))
	portal_update()		
	
func portal_destroyed():
	map_generator.portal_destroyed()
	portal_update()

func portal_update():
	map_generator.created_portal.connect("portal_destroyed", portal_destroyed)
	map_generator.created_portal.world = self
	map_generator.created_portal.player = player
	map_generator.created_portal.call_deferred("create_enemies")
	map_generator.created_portal.collision.set_deferred("disabled", false)
