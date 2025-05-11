extends StaticBody3D

@onready var collision : CollisionShape3D = $CollisionShape3D
@onready var collision_shape : Shape3D = collision.shape
#timer period generation new enemies on a map
@onready var timer_create_new_enemy : Timer = $timer_create_new_enemy
@onready var area_observe : Area3D = $area_observe
@onready var area_observe_collision : Shape3D = $area_observe/CollisionShape3D.shape
@export var player: CharacterBody3D
@export var world: Node3D

#generation list enemies on a map
var list_enemy : Array
#generation list new enemies on a map
var list_new_enemy : Array
# creating new enemy's time 
var time_create_new_enemy = 1.0
# creating new enemy's rest time 
var time_rest_create_new_enemy = time_create_new_enemy
#generation count new enemies on a map
var portal_create_new_enemy_count = 1
#groupe's size new enemies
var portal_create_new_enemy_groupe_count = 2
# modificators value's probability
var probability_modificator = 50.0
# modificators value's maximum probability
var probability_modificator_maximum=50
# modificators value's increase= probability
var probability_modificator_increase=1
# list enemy's prefab
var list_prefabenemy = [{"name": "imp", "prefab": preload("res://prefabs/enemies/imp/enemy_imp.tscn"), "spawn_rate": 0},
						{"name": "skymage", "prefab": preload("res://prefabs/enemies/skymage/enemy_skymage.tscn"), "spawn_rate": 0},
						{"name": "zombie", "prefab": preload("res://prefabs/enemies/zombie/enemy_zombie.tscn"), "spawn_rate": 0}
						]
var player_in_area: bool = false

signal portal_destroyed()
signal enemy_appear()

func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:		
		portal_create_new_enemy_count = config.get_value("portal", "portal_create_new_enemy_count", portal_create_new_enemy_count)
		time_create_new_enemy = config.get_value("portal", "portal_create_new_enemy_time", 5)
		portal_create_new_enemy_groupe_count = config.get_value("portal", "portal_create_new_enemy_groupe_count", portal_create_new_enemy_groupe_count)
		probability_modificator =  config.get_value("portal", "probability_modificator", probability_modificator)
		probability_modificator_maximum =  config.get_value("portal", "probability_modificator_maximum", probability_modificator_maximum)
		probability_modificator_increase =  config.get_value("portal", "probability_modificator_increase", probability_modificator_increase)
		area_observe_collision.radius =  config.get_value("portal", "area_observe_radius", 10.0)
		for obj in list_prefabenemy:
			obj.spawn_rate = config.get_value("enemy_spawn_rate", obj.name, obj.spawn_rate)	
		#config.save("res://settings.cfg")
	config = null
	time_rest_create_new_enemy = time_create_new_enemy

func choose_enemy():
	var total = 0
	for obj in list_prefabenemy:
		total += obj.spawn_rate
	var rand = randi() % total
	var sum = 0
	for obj in list_prefabenemy:
		sum += obj.spawn_rate
		if rand <= sum:
			return obj.prefab
			
func create_enemy(prefab_scene)->Node:
	var enemy = prefab_scene.instantiate()
	enemy.player = player
	enemy.world = world
	enemy.probability_modificator = probability_modificator		
	return enemy

func create_enemies(count) -> void:
	var angle_shift = 330.0 / count
	var angle = 0
	for i in range(0, count, 1):
		var enemy = create_enemy(choose_enemy())	
		list_enemy.append(enemy)	
		world.add_child(enemy)		
		enemy._set_portal(self, angle)
		angle += angle_shift
	timer_create_new_enemy.start()
	emit_signal("enemy_appear", time_rest_create_new_enemy)
	
func portal_free() -> void:
	collision.set_deferred("disabled", true)
	for obj in list_enemy:
		obj._set_portal(null, 0)
	for obj in list_new_enemy:
		obj._set_portal(null, 0)
	list_enemy.clear()
	list_new_enemy.clear()
	timer_create_new_enemy.stop()
	if is_instance_valid(player):
		player.portal_free()
	probability_modificator = min(probability_modificator + probability_modificator_increase, probability_modificator_maximum)
	area_observe.monitoring = false
	emit_signal("portal_destroyed")
	
func _get_object_size() -> float:
	return collision_shape.radius

func _on_timer_create_new_enemy_timeout() -> void:	
	time_rest_create_new_enemy -= timer_create_new_enemy.wait_time	
	if time_rest_create_new_enemy  < 0.1:
		var angle_shift = 330.0 / portal_create_new_enemy_count
		var angle = randi_range(0, 359)
		for i in range(0, portal_create_new_enemy_count, 1):
			var enemy = create_enemy(choose_enemy())
			world.add_child(enemy)		
			enemy._set_portal(self, angle)
			angle = fmod(angle + angle_shift, 360)
			if player_in_area && enemy.enemy_type in ["zombie"]:
				enemy._set_portal(null, 0)
			else:
				list_enemy.append(enemy)
				list_new_enemy.append(enemy)
				# grups enemy go yo player
				if list_new_enemy.size() == portal_create_new_enemy_groupe_count:
					for obj in list_new_enemy:
						list_enemy.erase(obj)
						obj._set_portal(null, 0)
					list_new_enemy.clear()	
		time_rest_create_new_enemy = time_create_new_enemy
	emit_signal("enemy_appear", time_rest_create_new_enemy)
		
func _on_area_observe_body_entered(_body: Node3D) -> void:
	player_in_area = true
	for i in range(list_enemy.size() - 1, -1, -1):
		var obj = list_enemy[i]
		if obj.enemy_type == "zombie":
			obj._set_portal(null, 0)
			list_enemy.erase(obj)
			list_new_enemy.erase(obj)

func _on_area_observe_body_exited(_body: Node3D) -> void:
	player_in_area = false
