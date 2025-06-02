extends Node3D

@onready var player = $player
@onready var map_generator = $map_generator

#generation count enemies on a map
var portal_create_enemy_count = 4
#count enemy increase after reload portal
var portal_reload_enemy_increase = 1
# list teleport enemy
var list_teleport_enemy_after_portal_destroyed = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	map_generator.SCALE_SIZE_MAP = Globalsettings.world_param["scale_size_map"]
	portal_create_enemy_count = Globalsettings.world_param["portal_create_enemy_count"]
	portal_reload_enemy_increase = Globalsettings.world_param["portal_reload_enemy_increase"]
	map_generator.create_map()
	var player_coordinate = map_generator.find_block_free()
	#player_coordinate = map_generator.created_portal.global_position + Vector3(-10, 0, -10)
	player.set_deferred("global_position", Vector3(player_coordinate.x, player_coordinate.y + player.collision_shape.height/2, player_coordinate.z))
	map_generator.set_collision_kill_zone(player.collision_layer)
	map_generator.created_portal.connect("portal_before_destroyed", portal_before_destroyed)	
	map_generator.created_portal.connect("portal_after_destroyed", portal_after_destroyed)
	map_generator.created_portal.world = self
	map_generator.created_portal.player = player
	map_generator.created_portal.connect("enemy_appear_time", player.enemy_appear_time)
	map_generator.created_portal.connect("enemy_appear_spawn", player.enemy_appear_spawn)	
	portal_update()	

func portal_before_destroyed():
	for obj in map_generator.created_portal.list_enemy:
		if obj.enemy_type == "skymage":
			list_teleport_enemy_after_portal_destroyed.append(obj)
		
func portal_after_destroyed():
	map_generator.portal_destroyed()
	portal_update()

func portal_update():	
	map_generator.created_portal.call_deferred("create_enemies", portal_create_enemy_count)
	portal_create_enemy_count +=portal_reload_enemy_increase
	player._set_enemy_appear_count(portal_create_enemy_count)
	map_generator.created_portal.append_enemies(list_teleport_enemy_after_portal_destroyed)
	list_teleport_enemy_after_portal_destroyed.clear()
