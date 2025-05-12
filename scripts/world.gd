extends Node3D

@onready var player = $player
@onready var map_generator = $map_generator

#generation count enemies on a map
var portal_create_enemy_count = 4
#count enemy increase after reload portal
var portal_reload_enemy_increase = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		map_generator.SCALE_SIZE_MAP = config.get_value("world", "scale_size_map", 50)
		portal_create_enemy_count = config.get_value("world", "portal_create_enemy_count", portal_create_enemy_count)
		portal_reload_enemy_increase = config.get_value("world", "portal_reload_enemy_increase", portal_reload_enemy_increase)			
		#config.save("res://settings.cfg")
	config = null
	map_generator.create_chunk()
	var player_coordinate = map_generator.find_block_free()
	#player_coordinate = map_generator.created_portal.global_position + Vector3(1, 0, 10)
	player.set_deferred("global_position", Vector3(player_coordinate.x, player_coordinate.y + player.collision_shape.height/2, player_coordinate.z))
	portal_update()	
	
func portal_destroyed():
	portal_create_enemy_count+=portal_reload_enemy_increase	
	map_generator.portal_destroyed()
	portal_update()

func portal_update():
	map_generator.created_portal.connect("portal_destroyed", portal_destroyed)
	map_generator.created_portal.world = self
	map_generator.created_portal.player = player
	map_generator.created_portal.call_deferred("create_enemies", portal_create_enemy_count)
	map_generator.created_portal.collision.set_deferred("disabled", false)
	map_generator.created_portal.connect("enemy_appear", player.enemy_appear)	
	player._set_enemy_appear_count(portal_create_enemy_count)
